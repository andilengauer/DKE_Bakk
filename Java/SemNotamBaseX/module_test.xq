import module namespace dke = "at.jku.dke" at "temporal_filter_module.xq";

let $h := dke:is-holiday(xs:date("2017-01-01"),"at")

let $t := dke:get-temporal-relevant-notams("1",2)

return $h
