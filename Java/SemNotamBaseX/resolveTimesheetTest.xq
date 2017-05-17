declare namespace functx = "http://www.functx.com";

declare namespace holiday = "java:jollyday.JollydayHelper";

declare function functx:day-of-week
 ($date as xs:anyAtomicType?) as xs:integer? {
 if (empty($date))
 then ()
 else
  xs:integer((xs:date($date) - xs:date('1901-01-06')) div xs:dayTimeDuration('P1D')) mod 7
};

declare function functx:next-day
  ( $date as xs:anyAtomicType? )  as xs:date? {

   xs:date($date) + xs:dayTimeDuration('P1D')
 } ;

let $beginTime := xs:dateTime('2014-06-15T14:00:00.000Z')
let $endTime := xs:dateTime('2014-07-20T16:04:00.000Z')

let $begin := xs:date(substring-before(xs:string($beginTime),'T'))
let $end := xs:date(substring-before(xs:string($endTime),'T'))


let $x := db:open("Herucles")
let $poi := $x//*:PeriodOfInterest
let $timesheet := $x//*:Timesheet
let $diff := days-from-duration($end - $begin)

let $dates := 
for $i in ( 0 to $diff)
return $begin + xs:dayTimeDuration(concat('P',$i,'D'))

let $starttime := xs:time(concat($timesheet/*:startTime,':00Z'))
let $endtime := xs:time(concat($timesheet/*:endTime,':00Z'))

for $d in $dates
where ('MON','TUE','WED')[functx:day-of-week($d)+1] = $timesheet/*:day
let $a := fn:dateTime($d,$starttime)
let $b := fn:dateTime($d,$endtime)
return 
if($b >= $beginTime)
then
<timeperiod>
<begin>
{$a}
</begin>
<end>
{$b}
</end>
</timeperiod>
else ()