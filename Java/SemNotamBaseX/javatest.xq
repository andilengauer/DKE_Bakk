
import module namespace holiday = "java:jollyday.JollydayHelper";
declare namespace cal = "java:java.util.Calendar";
let $y := cal:getInstance()
(:let $x := holiday:isHoliday("2017-01-01","at"):)
let $x := holiday:isTest(xs:int("2016"),xs:int("1"),xs:int("1"))
return $x
