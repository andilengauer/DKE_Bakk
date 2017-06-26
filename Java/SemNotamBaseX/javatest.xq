import module namespace functx = "http://www.functx.com";

let $db := db:open("Herucles")
let $weekdays := ('SUN','MON','TUE','WED','THU','FRI','SAT')
let $til := 'SUN'
let $current := 'SUN'

let $start := functx:day-of-week(xs:date("2017-06-19"))+1
let $end := index-of($weekdays,$til)
let $mid := index-of($weekdays,$current)

let $end := if ($end < $start) then $end + 10 else $end
let $mid := if($mid < $start) then $mid + 10 else $mid

return
( $start
, $end
, $mid
,$mid > $start and $mid <= $end
)


(:
return ( $start
, $end
, $mid
, ($start < $end and $mid > $start and $mid <= $end)
    or($end < $start and (($mid < $start and $mid < $end)or($mid > $start and $mid > $end)))
)
:)