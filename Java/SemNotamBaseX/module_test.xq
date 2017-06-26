import module namespace dke = "at.jku.dke" at "temporal_filter_module_v2.xq";
  
let $sun := dke:get-sunrise(xs:date("2017-06-15"),"48.239","14.192")

let $t := dke:get-temporal-relevant-notams("1",2)


return $t
