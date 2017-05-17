module namespace dke = "at.jku.dke";

import module namespace functx = "http://www.functx.com";
import module namespace holiday = "java:jollyday.JollydayHelper";

(:import module namespace jollyday = "java:de.jollyday.HolidayManager";:)

(: granularity: 
  1-filter by validTime
  2-filter by activeTime additionally
:)
declare function dke:get-temporal-relevant-notams($is_id as xs:string,$granularity as xs:integer) as element()*
{
  
  let $db := db:open("Herucles")
  let $messages := $db//*:AIXMBasicMessage
  let $poi := $db//*:PeriodOfInterest
  
  let $beginTime := xs:dateTime($poi//*:beginPosition/text())
  let $endTime := xs:dateTime($poi//*:endPosition/text())
  
  let $beginTime := xs:dateTime('2014-06-15T13:04:00.000Z')
  let $endTime := xs:dateTime('2014-07-23T16:04:00.000Z')
  
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
      if(empty($activetimes)) then $m/@*:id
      else
        for $activetime in $activetimes
        where $activetime/begin <= $endTime and $activetime/end >= $beginTime
        return $m/@*:id
  
  
  for $id at $pos in distinct-values($ids)
  return $messages[@*:id = $id]
};

declare function dke:resolve-timesheet($timesheet as element(), $beginTime as xs:dateTime, $endTime as xs:dateTime)
as element()*
{
  let $weekdays := ('MON','TUE','WED','THU','FRI','SAT','SUN')
  
  let $begin := xs:date(substring-before(xs:string($beginTime),'T'))
  let $end := xs:date(substring-before(xs:string($endTime),'T'))
  
  let $diff := days-from-duration($end - $begin)

  let $dates := 
    for $i in ( 0 to $diff)
    return $begin + xs:dayTimeDuration(concat('P',$i,'D'))
  
  let $starttime := xs:time(concat($timesheet/*:startTime,':00'))
  let $endtime := xs:time(concat($timesheet/*:endTime,':00'))
  
  for $d in $dates
  return 
  if ($timesheet/*:day = 'ANY' or $weekdays[functx:day-of-week($d)+1] = $timesheet/*:day)
  then(
    let $pbegin := fn:dateTime($d,$starttime)
    let $pend := fn:dateTime($d,$endtime)
    return 
    if($pend >= $beginTime)
    then
    <timeperiod>
      <begin>
      {$pbegin}
      </begin>
      <end>
      {$pend}
      </end>
    </timeperiod>
    else ()
)
else if ($timesheet/*:day = "HOL")
then ()
else ()
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

declare function dke:is-holiday($date as xs:date) as xs:boolean
{
  holiday:isHoliday("2017-01-01","at")
};

