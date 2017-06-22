module namespace dke = "at.jku.dke";

import module namespace functx = "http://www.functx.com";
import module namespace holiday = "java:jollyday.JollydayHelper";
import module namespace sunstate = "java:sunstate.SunState";

 
(: ----------------------------------------------------------------------------
Main function as an interface to Java which returns temporal relevant notams

Parameter:
- $is_id: Id of InterestSpecification
- granularity: 
  1-filter by validTime
  2-filter by activeTime additionally
:)
declare function dke:get-temporal-relevant-notams($is_id as xs:string,$granularity as xs:integer) as element()
{
  
  let $db := db:open("Herucles")
  let $messages := $db//*:AIXMBasicMessage
  
  let $interest := dke:load-interestspecification($is_id, $db)
  let $beginTime := xs:dateTime($interest//begin)
  let $endTime := xs:dateTime($interest//end)
  
  let $beginTime := xs:dateTime('2017-06-15T04:04:00.000Z')
  let $endTime := xs:dateTime('2017-06-15T12:10:00.000Z')
  
  
  let $filtered := dke:filter-with-validTime($messages,$beginTime,$endTime)
  let $result :=
  if ($granularity = 2)  then
    dke:filter-by-activeTime($filtered,$beginTime,$endTime)
  else
    $filtered
  
  return 
  
  <EvaluatedInterestSpecification><hasResult>
    {for $r in $result
    return (<Result>
    <hasNotam>{$r}</hasNotam>
    <hasNotamId>{$r/@*:id/data()}</hasNotamId>
    </Result>)
  }
  </hasResult></EvaluatedInterestSpecification>
};

(: -------------------------------------------------------------------------
This function loads relevant information from the given InterestSpecification
parameter:
- $is_id --> Id of InterestSpecification
- §db --> Content of XML-Database

returnvalue:
<interest>
<begin>2010-01-01T00:00:00</begin>
<end>2010-01-02T00:00:00</end>
</interest>
:)
declare function dke:load-interestspecification($is_id as xs:string, $db as element())
as element()
{
  let $is := $db//*:InterestSpecification[@*:id = $is_id]
  let $poi := $is//*:PeriodOfInterest[1]
  let $timeinterval := $poi/*:occTime/*:TimeInterval
  
  
  let $temporalBuffer := $poi//*:TemporalBuffer
  let $before_buffer := 
    if(exists($temporalBuffer/*:before)) 
      then xs:dayTimeDuration(concat("-" ,$temporalBuffer/*:before/text()))
    else xs:dayTimeDuration("-PT1H")
  
  let $after_buffer := 
    if(exists($temporalBuffer/*:after)) 
      then xs:dayTimeDuration($temporalBuffer/*:after/text())
    else xs:dayTimeDuration("PT1H")
  
  let $begin := xs:dateTime($timeinterval/*:beginPosition/text()) + $before_buffer
  let $end := xs:dateTime($timeinterval/*:endPosition/text()) + $after_buffer
  return 
  <interest>
  <begin>$begin</begin>
  <end>$end</end>
  </interest>
};

declare function dke:filter-by-activeTime($messages as element()*,$beginTime as xs:dateTime,$endTime as xs:dateTime)
as element()* {
  let $ids := 
  for $m in $messages
  return 
  if( not(exists($m//*:timeInterval)))
    then $m/@*:id
  else
    let $tdMessage := ($m/*:hasMember//*:timeSlice[.//*:interpretation/text()="TEMPDELTA"])[1]
    for $t in $tdMessage//*:timeInterval
    let $activetimes := dke:handle-timesheets($t//*:Timesheet, $beginTime, $endTime)
    return if(dke:exist-intersection($activetimes,$beginTime,$endTime))
      then $m/@*:id
      else ()
      
  
  
  for $id at $pos in distinct-values($ids)
  return $messages[@*:id = $id]
};

declare function dke:exist-intersection($activetimes as element()*,$beginTime as xs:dateTime,$endTime as xs:dateTime) as xs:boolean
{
  let $intersection := 
  for $activetime in $activetimes[@exclusion = "false"]/timeperiod
  where ($activetime/begin <= $endTime and $activetime/end >= $beginTime )
  return <x></x>
  
  let $exclusion := if(empty($intersection)) then ()
  else 
  for $excluded in $activetimes[@exclusion = "true"]/timeperiod
  where $excluded/begin <= $beginTime and $excluded/end >= $endTime
  return <x></x>
  
  return if(not(empty($intersection)) and empty($exclusion))
  then xs:boolean("true")
  else xs:boolean("false")
    
  
};

declare function dke:handle-timesheets($timesheets as element()*, $beginTime as xs:dateTime, $endTime as xs:dateTime) as element()*
{
  for $t in $timesheets
    
    let $tempBeginTime := if(exists($t/*:dayTil)) then $beginTime + xs:dayTimeDuration("-P0D") else $beginTime
    let $begin := xs:date(substring-before(xs:string($tempBeginTime),'T'))
    let $end := xs:date(substring-before(xs:string($endTime),'T'))
    
    let $starttime := if(not(empty($t/*:startTime))) then xs:time(concat($t/*:startTime,':00Z')) else ()
    let $endtime := if(not(empty($t/*:endTime))) then xs:time(concat($t/*:endTime,':00Z')) else ()
    
    let $dayoverlap := not(empty($starttime)) and not(empty($endtime)) and $endtime <= $starttime
    
    let $daylightsaving := 
    if($t/*:daylightSavingAdjust/text() = "YES") 
    then xs:boolean("true") 
    else xs:boolean("false")
    
    let $begin := trace(if ( $dayoverlap) then dke:add-days-to-date($begin, -1) else $begin)
    let $dayTil := $t/*:dayTil
    (:dke:get-weekdays()[functx:day-of-week($date)+1]:)
    let $dayIndex := 
      if(index-of(dke:get-weekdays(),$t/*:day) != ()) then index-of(dke:get-weekdays(),$t/*:day)
      else ()
       
    let $activeDayTil := 
      if(exists($dayTil) and index-of(dke:get-weekdays(),$t/*:day) >= 0)
      then (
        let $startIndex := index-of(dke:get-weekdays(),$t/*:day)
        let $midIndex := functx:day-of-week($begin) + 1
        let $endIndex := index-of(dke:get-weekdays(),$dayTil)
        
        let $endIndex := if ($endIndex < $startIndex) then $endIndex + 10 else $endIndex
        let $midIndex := if($midIndex < $startIndex) then $midIndex + 10 else $midIndex
        
        return $midIndex > $startIndex and $midIndex <= $endIndex
      )
      else xs:boolean("false")
      
      let $searchDay := if(trace($activeDayTil,"activeDayTil :")) then $dayTil else $t/*:day
    
    let $intervals := trace(dke:resolve-timesheet($t, $tempBeginTime, $endTime, $begin, $searchDay,$activeDayTil),"resolved intervals: ")
    
    let $exclusion := not (empty($t[*:excluded = "YES"]))
    return 
      <activetimes exclusion="{$exclusion}">
        {$intervals}
      </activetimes>

};

declare function dke:resolve-timesheet($timesheet as element(), $beginTime as xs:dateTime, $endTime as xs:dateTime, $currentDay as xs:date, $searchDay as xs:string, $activeDayTil as xs:boolean) as element()*
{
  
  (:
  let $begin := xs:date(substring-before(xs:string($beginTime),'T'))
  let $end := xs:date(substring-before(xs:string($endTime),'T'))
  :)
  
  let $starttime := 
    if(not(empty($timesheet/*:startTime))) then xs:time(concat($timesheet/*:startTime,':00Z')) else ()
  let $endtime := 
    if(not(empty($timesheet/*:endTime))) then xs:time(concat($timesheet/*:endTime,':00Z')) else ()
    
  let $dayoverlap := not(empty($starttime)) and not(empty($endtime)) and $endtime <= $starttime
    
  let $startevent := $timesheet/*:startEvent
  let $endevent := $timesheet/*:endEvent
  
  let $dayTil := $timesheet/*:dayTil/text()
  
  let $nextDay := dke:add-days-to-date($currentDay,1)
  
  let $daylightsaving := 
    if($timesheet/*:daylightSavingAdjust/text() = "YES") 
    then xs:boolean("true") 
    else xs:boolean("false")
    
  let $arp := trace($timesheet/ancestor::*:hasMember//*:ARP//*:pos/text(),"ARP ")
  
  let $arp_lat := trace(substring-before($arp," "),"lat: ")
  let $arp_lng := trace(substring-after($arp," "),"lng: ")
  
  let $debug1 := trace($currentDay,"current day ")
  let $debug := trace($searchDay,"search day is ")
  
  let $pbegin := 
    if (not(empty($timesheet/*:startTime))) then fn:dateTime($currentDay,$starttime)
    else if(not(empty($startevent))) 
      then if($startevent = "SR") then dke:get-sunrise($currentDay, $arp_lat,$arp_lng)
           else if($startevent = "SS") then dke:get-sunset($currentDay, $arp_lat,$arp_lng)
           else fn:dateTime($currentDay,xs:time("00:00:00Z"))
    else fn:dateTime($currentDay,xs:time("00:00:00Z"))
    
  let $pbegin := trace(if($daylightsaving) 
                  then ($pbegin + xs:dayTimeDuration("-P0DT1H"))
                  else $pbegin,"Intervall Anfang: ")
  let $pend := 
    if(not(empty($endtime))) then fn:dateTime($currentDay,$endtime)
    else if(not(empty($endevent))) 
      then if($endevent = "SR") then dke:get-sunrise($currentDay,$arp_lat,$arp_lng)
           else if($endevent = "SS") then dke:get-sunset($currentDay,$arp_lat,$arp_lng)
           else fn:dateTime($nextDay,xs:time("00:00:00Z"))
    else fn:dateTime($nextDay,xs:time("00:00:00Z"))
    
  let $dayoverlap := $pend < $pbegin
    
  let $pend := if($dayoverlap) then $pend + xs:dayTimeDuration("P1D") else $pend
  
  
  
  return
  
  (:--- terminate recursive function if outside of interval range  --:)
  if($endTime < fn:dateTime($currentDay,xs:time("00:00:00Z")))
  then ()
  
  (:--- Timesheet for ANY Day ---:)
  else if ($searchDay = 'ANY')
  then (
    if($pend >= $beginTime)
    then
    (
      dke:format-timeinterval($pbegin,$pend)
    )
    else ()
    ,dke:resolve-timesheet($timesheet, $beginTime, $endTime,$nextDay, $searchDay,$activeDayTil)
  ) 
  
  (:--- Timesheet for a weekday (MON,TUE,WED,...) ---:)
  else if (functx:is-value-in-sequence($searchDay,dke:get-weekdays()))
  then(
    if($pend >= $beginTime and $searchDay = dke:get-weekdays()[functx:day-of-week($currentDay)+1])
    then
    (
     let $searchDay := trace(
       if ($activeDayTil) then $timesheet/*:day/text()
       else if(not( empty($dayTil))) 
       then xs:string($dayTil) else $searchDay,
       "new search day ")
     let $pend := if(not($activeDayTil) and not(empty($dayTil))) 
     then fn:dateTime(dke:add-days-to-date($currentDay,1),xs:time("00:00:00Z"))
     else $pend
     
     let $pbegin := if($activeDayTil) 
     then fn:dateTime($currentDay,xs:time("00:00:00Z"))
     else $pbegin
     
     let $activeDayTil := 
       if(not($activeDayTil) and not(empty($dayTil))) 
         then xs:boolean("true")
       else xs:boolean("false")
     
     return
     (
     dke:format-timeinterval($pbegin,$pend),
     trace(dke:resolve-timesheet($timesheet, $beginTime, $endTime,$nextDay , $searchDay,
     trace($activeDayTil)))
     )
    )
    else if(trace($activeDayTil,"open dayTil: "))
    then
    (
      let $debug := trace(<dayTilIsOpen></dayTilIsOpen>)
      return(
      dke:format-timeinterval(fn:dateTime($currentDay,xs:time("00:00:00Z"))
                          ,fn:dateTime(dke:add-days-to-date($currentDay,1),xs:time("00:00:00Z"))
                      )
    ,
    dke:resolve-timesheet($timesheet, $beginTime, $endTime,$nextDay , $searchDay, $activeDayTil)
  )
  )
    else (
      dke:resolve-timesheet($timesheet, $beginTime, $endTime,$nextDay , trace($searchDay),$activeDayTil)
    )
  )
  (:--- Timesheet for a Holiday ---:)
  else if ($searchDay = "HOL")
  then 
  (
    (
    if(trace($pend >= $beginTime,"TEST:") and trace(dke:is-holiday($currentDay,"at"),"is Holiday: "))
    then
    (
    trace(dke:format-timeinterval($pbegin,$pend),"format interval: ")
    )
    else ()
    )
    ,(dke:resolve-timesheet($timesheet, $beginTime, $endTime,$nextDay , trace($searchDay),$activeDayTil))
  )
  
  (:--- Timesheet for a workday ---:)
  else if($searchDay = "WORK_DAY")
  then (
    if(dke:is-workday($currentDay,"at") and $pend >= $beginTime)
    then (
      dke:format-timeinterval($pbegin,$pend)
    )
    else ()
    ,(dke:resolve-timesheet($timesheet, $beginTime, $endTime,$nextDay , $searchDay,$activeDayTil))
  )
  
  (:--- Before work day ---:)
  else if($searchDay = "BEF_WORK_DAY")
  then (
    let $nextday := dke:add-days-to-date($currentDay,1)
    return
    if(dke:is-workday($nextday,"at") and $pend >= $beginTime)
    then dke:format-timeinterval($pbegin,$pend)
    else ()
    ,(dke:resolve-timesheet($timesheet, $beginTime, $endTime,$nextDay , $searchDay,$activeDayTil))
  )
  
  (:--- after work day ---:)
  else if($searchDay = "AFT_WORK_DAY")
  then (
    let $prevday := dke:add-days-to-date($currentDay,-1)
    return
    if(dke:is-workday($prevday,"at") and $pend >= $beginTime)
    then dke:format-timeinterval($pbegin,$pend)
    else ()
    ,(dke:resolve-timesheet($timesheet, $beginTime, $endTime,$nextDay , $searchDay,$activeDayTil))
  )
  
  (:--- before holiday ---:)
  else if($searchDay = "BEF_HOL")
  then (
    if(dke:is-holiday($nextDay,"at") and $pend >= $beginTime)
    then dke:format-timeinterval($pbegin,$pend)
    else ()
    ,(dke:resolve-timesheet($timesheet, $beginTime, $endTime,$nextDay , $searchDay,$activeDayTil))
  )
  
  (:--- after holiday ---:)
  else if($searchDay = "AFT_HOL")
  then (
    let $prevday := dke:add-days-to-date($currentDay,-1)
    return
    if(dke:is-holiday($prevday,"at") and $pend >= $beginTime)
    then dke:format-timeinterval($pbegin,$pend)
    else ()
    ,(dke:resolve-timesheet($timesheet, $beginTime, $endTime,$nextDay , $searchDay,$activeDayTil))
  )
  (:--- busy friday (handle as normal friday) ---:)
  else if($searchDay = "BUSY_FRI")
  then (
    if(dke:weekday-from-date($currentDay) = "FRI" and $pend >= $beginTime)
    then dke:format-timeinterval($pbegin,$pend)
    else ()
    ,(dke:resolve-timesheet($timesheet, $beginTime, $endTime,$nextDay , $searchDay,$activeDayTil))
  )
  
  
  (:--- not implemented timesheet -> full-time of day ---:)
  else
  (
    dke:format-timeinterval(fn:dateTime($currentDay,xs:time("00:00:00Z"))
                          ,fn:dateTime($nextDay,xs:time("00:00:00Z"))
                      )
    ,(dke:resolve-timesheet($timesheet, $beginTime, $endTime,$nextDay , $searchDay,$activeDayTil))
)
};



declare function dke:filter-with-validTime($messages as element()*, $begin as xs:dateTime, $end as xs:dateTime) as element()* {
  let $test := $messages
  for $m in $messages
  let $temp := ($m/*:hasMember//*:timeSlice[.//*:interpretation/text()="TEMPDELTA"])[1]
  let $vtime := $temp//*:validTime
  return 
  if(xs:dateTime($vtime/*:TimePeriod/*:beginPosition) <= $end 
    and 
    (
    empty($vtime/*:TimePeriod/*:endPosition/text()) 
    or xs:dateTime($vtime/*:TimePeriod/*:endPosition) >= $begin
    )
  ) then $m
  else ()  
};

declare function dke:weekday-from-date($date as xs:date) as xs:string
{
  
  dke:get-weekdays()[functx:day-of-week($date)+1]
  
};

declare function dke:is-holiday($date as xs:date,$country as xs:string) as xs:boolean
{
  holiday:isHoliday(xs:string($date),$country)
};

declare function dke:add-days-to-date($date as xs:date, $days as xs:integer)
as xs:date
{
  if($days < 0) 
  then $date + xs:dayTimeDuration(concat('-P',fn:abs($days),'D')) 
  else $date + xs:dayTimeDuration(concat('P',$days,'D'))
};

(: returns formatted active time interval :)
declare function dke:format-timeinterval($begin as xs:dateTime, $end as xs:dateTime) as element()
{
  <timeperiod>
      <begin>
      {$begin}
      </begin>
      <end>
      {$end}
      </end>
    </timeperiod>
};

declare function dke:is-workday($date as xs:date,$country as xs:string) as xs:boolean
{
  let $weekday := dke:weekday-from-date($date)
  return (not(dke:is-holiday($date,$country)) and $weekday != 'SUN' and $weekday != 'SAT')
};

declare function dke:get-weekdays() as xs:string*
{
  let $weekdays := ('SUN','MON','TUE','WED','THU','FRI','SAT')
  return $weekdays
};

declare function dke:get-sunrise($date as xs:date,$lat as xs:string,$lng as xs:string) as xs:dateTime
{
  let $sunrise := xs:dateTime(trace(sunstate:getSunrise(xs:string(trace($date,"sr date")),trace($lat),trace($lng)),"sunrise "))
  
  return adjust-dateTime-to-timezone($sunrise,xs:dayTimeDuration("PT0H"))
};

declare function dke:get-sunset($date as xs:date,$lat as xs:string,$lng as xs:string) as xs:dateTime
{
  let $sunset := xs:dateTime(sunstate:getSunset(xs:string($date),$lat,$lng))
  return adjust-dateTime-to-timezone($sunset,xs:dayTimeDuration("PT0H"))
};


