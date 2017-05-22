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
    let $temp := ($m/*:hasMember//*:timeSlice[.//*:interpretation/text()="TEMPDELTA"])[1]
    for $t in $temp//*:timeInterval
    let $activetimes := dke:resolve-timesheet($t//*:Timesheet, $beginTime, $endTime)
    return 
      for $activetime in $activetimes
      where $activetime/begin <= $endTime and $activetime/end >= $beginTime
      return $m/@*:id
  
  
  for $id at $pos in distinct-values($ids)
  return $messages[@*:id = $id]
};

declare function dke:resolve-timesheet($timesheet as element(), $beginTime as xs:dateTime, $endTime as xs:dateTime) as element()*
{
  let $weekdays := ('SUN','MON','TUE','WED','THU','FRI','SAT')
  
  let $begin := xs:date(substring-before(xs:string($beginTime),'T'))
  let $end := xs:date(substring-before(xs:string($endTime),'T'))

  let $starttime := xs:time(concat($timesheet/*:startTime,':00Z'))
  let $endtime := xs:time(concat($timesheet/*:endTime,':00Z'))
  let $dayoverlap := $endtime <= $starttime
    
  let $diff := days-from-duration($end - $begin)

  let $dates := 
  (
    (: add prev day to dates for day overlapping times :)
    if ( $dayoverlap) then dke:add-days-to-date($begin, -1) else (),
    for $i in ( 0 to $diff)
    return dke:add-days-to-date($begin,$i)
  )
  

  
  for $d in $dates
  let $pbegin := fn:dateTime($d,$starttime)
  let $pend := 
    if($dayoverlap) then (fn:dateTime(dke:add-days-to-date($d,1),$endtime)) 
    else fn:dateTime($d,$endtime)
    
  return
  if ($timesheet/*:day = 'ANY')
  then (
    if($pend >= $beginTime)
    then
    dke:format-active-time($pbegin,$pend)
    else ()) 
  (: Timesheet for a weekday :)
  else if (functx:is-value-in-sequence($timesheet/*:day,$weekdays))
  then(
    if($pend >= $beginTime and $timesheet/*:day = $weekdays[functx:day-of-week($d)+1])
    then
     dke:format-active-time($pbegin,$pend)
    else ()
  )
  (: Timesheet for a Holiday :)
  else if ($timesheet/*:day = "HOL")
  then 
  (
    if($pend >= $beginTime and dke:is-holiday($d,"at"))
    then
    dke:format-active-time($pbegin,$pend)
    else ()
  )
  else if($timesheet/*:day = "WORKDAY")
  then ()
  else if($timesheet/*:day = "BEF_WORK_DAY")
  then ()
  else if($timesheet/*:day = "AFT_WORK_DAY")
  then ()
  else if($timesheet/*:day = "BEF_HOL")
  then ()
  else if($timesheet/*:day = "AFT_HOL")
  then ()
  else if($timesheet/*:day = "BUSY_FRI")
  then ()
  
  else
  (
    dke:format-active-time(fn:dateTime($d,xs:time("00:00:00Z"))
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

declare function dke:weekday-from-datetime($datetime as xs:dateTime) as xs:string
{
  
  ('MON','TUE','WED','THU','FRI','SAT','SUN')[functx:day-of-week(xs:date(substring-before(xs:string($datetime),'T')))+1]
  
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
declare function dke:format-active-time($begin as xs:dateTime, $end as xs:dateTime) as element()
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

