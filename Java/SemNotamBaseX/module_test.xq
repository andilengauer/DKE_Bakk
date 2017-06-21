import module namespace dke = "at.jku.dke" at "temporal_filter_module_v2.xq";

let $timesheet := <Timesheet id="TS_1_36119438">
                          <!-- SCHEDULE -->
                          <timeReference>UTC</timeReference>
                          <startDate>31-03</startDate>
                          <endDate>05-01</endDate>
                          <day>MON</day>
                          <startTime>07:00</startTime>
                          <endTime>14:00</endTime>
                          <daylightSavingAdjust>YES</daylightSavingAdjust>
                        </Timesheet>
let $beginTime := xs:dateTime('2017-05-21T03:04:00.000Z')
  let $endTime := xs:dateTime('2017-05-23T12:04:00.000Z')
  
let $sun := dke:get-sunrise(xs:date("2017-06-15"),"48.239","14.192")

let $t := dke:get-temporal-relevant-notams("1",2)


return $t//hasNotamId
