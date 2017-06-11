module namespace dke = "at.jku.dke";

import module namespace functx = "http://www.functx.com";
import module namespace holiday = "java:jollyday.JollydayHelper";

 

(:import module namespace jollyday = "java:de.jollyday.HolidayManager";:)

(: granularity: 
  1-filter by validTime
  2-filter by activeTime additionally
:)
declare function dke:get-temporal-relevant-notams($is_id as xs:string,$granularity as xs:integer) as element()
{
  
  let $db := db:open("Herucles")
  let $messages := $db//*:AIXMBasicMessage
  let $poi := $db//*:PeriodOfInterest
  
  let $beginTime := xs:dateTime($poi//*:beginPosition/text())
  let $endTime := xs:dateTime($poi//*:endPosition/text())
  
  let $beginTime := xs:dateTime('2017-05-22T14:04:00.000Z')
  let $endTime := xs:dateTime('2017-05-22T17:04:00.000Z')
  
  let $filtered := trace(dke:filter-with-validTime($messages,$beginTime,$endTime),'filterValid')
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
  
    let $begin := xs:date(substring-before(xs:string($beginTime),'T'))
    let $end := xs:date(substring-before(xs:string($endTime),'T'))
    
    let $starttime := xs:time(concat($t/*:startTime,':00Z'))
    let $endtime := xs:time(concat($t/*:endTime,':00Z'))
    
    let $dayoverlap := $endtime <= $starttime
    
    let $daylightsaving := 
    if($t/*:daylightSavingAdjust/text() = "YES") 
    then xs:boolean("true") 
    else xs:boolean("false")
    
    let $begin := trace(if ( $dayoverlap) then dke:add-days-to-date($begin, -1) else $begin)
    
    let $intervals := dke:resolve-timesheet($t, $beginTime, $endTime, $begin, $t/*:day)
    
    let $exclusion := not (empty($t[*:excluded = "YES"]))
    return 
      <activetimes exclusion="{$exclusion}">
        {$intervals}
      </activetimes>

};

declare function dke:resolve-timesheet($timesheet as element(), $beginTime as xs:dateTime, $endTime as xs:dateTime, $currentDay as xs:date, $searchDay) as element()*
{
  
  (:
  let $begin := xs:date(substring-before(xs:string($beginTime),'T'))
  let $end := xs:date(substring-before(xs:string($endTime),'T'))
  :)
  
  let $starttime := xs:time(concat($timesheet/*:startTime,':00Z'))
  let $endtime := xs:time(concat($timesheet/*:endTime,':00Z'))
  let $dayoverlap := $endtime <= $starttime
  
  let $daylightsaving := 
    if($timesheet/*:daylightSavingAdjust/text() = "YES") 
    then xs:boolean("true") 
    else xs:boolean("false")
(:    
  let $diff := days-from-duration($end - $begin)


  let $dates := 
  (
     add prev day to dates for day overlapping times 
    if ( $dayoverlap) then dke:add-days-to-date($begin, -1) else (),
    for $i in ( 0 to $diff)
    return dke:add-days-to-date($begin,$i)
  )
  :)
  let $d := $currentDay
  let $pbegin := 
    if($daylightsaving) 
    then (fn:dateTime($d,$starttime) + xs:dayTimeDuration("-P0DT1H"))
    else fn:dateTime($d,$starttime)
  let $pend := 
    if($dayoverlap) then (fn:dateTime(dke:add-days-to-date($d,1),$endtime)) 
    else fn:dateTime($d,$endtime)
    
  return
  
  (:--- Timesheet for ANY Day ---:)
  if ($timesheet/*:day = 'ANY')
  then (
    if($pend >= $beginTime)
    then
    (dke:format-timeinterval($pbegin,$pend),
    dke:resolve-timesheet($timesheet, $beginTime, $endTime,dke:add-days-to-date($currentDay,1) , $timesheet/*:day))
    else ()) 
  
  (:--- Timesheet for a weekday ---:)
  else if (functx:is-value-in-sequence($timesheet/*:day,dke:get-weekdays()))
  then(
    if($pend >= $beginTime and $timesheet/*:day = dke:get-weekdays()[functx:day-of-week($d)+1])
    then
     dke:format-timeinterval($pbegin,$pend)
    else ()
  )
  (:--- Timesheet for a Holiday ---:)
  else if ($timesheet/*:day = "HOL")
  then 
  (
    if($pend >= $beginTime and dke:is-holiday($d,"at"))
    then
    dke:format-timeinterval($pbegin,$pend)
    else ()
  )
  
  (:--- Timesheet for a workday ---:)
  else if($timesheet/*:day = "WORKDAY")
  then (
    if(dke:is-workday($d,"at") and $pend >= $beginTime)
    then (
      dke:format-timeinterval($pbegin,$pend)
    )
    else ()
  )
  
  (:--- Before work day ---:)
  else if($timesheet/*:day = "BEF_WORK_DAY")
  then (
    let $nextday := dke:add-days-to-date($d,1)
    return
    if(dke:is-workday($nextday,"at") and $pend >= $beginTime)
    then dke:format-timeinterval($pbegin,$pend)
    else ()
  )
  
  (:--- after work day ---:)
  else if($timesheet/*:day = "AFT_WORK_DAY")
  then (
    let $prevday := dke:add-days-to-date($d,-1)
    return
    if(dke:is-workday($prevday,"at") and $pend >= $beginTime)
    then dke:format-timeinterval($pbegin,$pend)
    else ()
  )
  
  (:--- before holiday ---:)
  else if($timesheet/*:day = "BEF_HOL")
  then (
    let $nextday := dke:add-days-to-date($d,1)
    return
    if(dke:is-holiday($nextday,"at") and $pend >= $beginTime)
    then dke:format-timeinterval($pbegin,$pend)
    else ()
  )
  
  (:--- after holiday ---:)
  else if($timesheet/*:day = "AFT_HOL")
  then (
    let $prevday := dke:add-days-to-date($d,-1)
    return
    if(dke:is-workday($prevday,"at") and $pend >= $beginTime)
    then dke:format-timeinterval($pbegin,$pend)
    else ()
  )
  (:--- busy friday (handle as normal friday) ---:)
  else if($timesheet/*:day = "BUSY_FRI")
  then (
    if(dke:weekday-from-date($d) = "FRI" and $pend >= $beginTime)
    then dke:format-timeinterval($pbegin,$pend)
    else ()
  )
  
  (:--- not implemented timesheet -> full-time of day ---:)
  else
  (
    dke:format-timeinterval(fn:dateTime($d,xs:time("00:00:00Z"))
                          ,fn:dateTime(dke:add-days-to-date($d,1),xs:time("00:00:00Z"))
                      )
)
};



declare function dke:filter-with-validTime($messages as element()*, $begin as xs:dateTime, $end as xs:dateTime) as element()* {
  let $test := trace($messages,"messages")
  for $m in $messages
  let $temp := trace(($m/*:hasMember//*:timeSlice[.//*:interpretation/text()="TEMPDELTA"])[1],"temp")
  let $vtime := trace($temp//*:validTime,"validTime")
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

