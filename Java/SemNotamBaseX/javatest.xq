import module namespace functx = "http://www.functx.com";

let $db := db:open("Herucles")
let $weekdays := ('SUN','MON','TUE','WED','THU','FRI','SAT')
let $til := 'FRI'
let $current := 'SAT'

let $start := functx:day-of-week(xs:date("2017-06-20"))+1
let $end := index-of($weekdays,$til)
let $mid := index-of($weekdays,$current)
return ( $start
, $end
, $mid
, ($mid > $start and $mid <= $end)
)