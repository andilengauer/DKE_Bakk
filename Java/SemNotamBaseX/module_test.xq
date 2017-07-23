import module namespace dke = "at.jku.dke" at "temporal_filter_module_v2.xq";

(:  
let $sun := dke:get-sunrise(xs:date("2017-06-15"),"48.239","14.192")
:)

let $t := dke:get-temporal-relevant-notams("Herucles","1",2)


(:
 return dke:resolve-preemptive("Herucles",xs:dateTime("2017-06-17T00:00:00Z"),xs:dateTime("2017-06-22T00:00:00Z"))
:)

return $t


