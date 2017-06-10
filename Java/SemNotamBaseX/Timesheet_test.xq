import module namespace functx = "http://www.functx.com";
import module namespace dke = "at.jku.dke" at "temporal_filter_module_v2.xq";

let $begin := xs:date("2017-05-21")
let $end := xs:date("2017-01-03")



let $timesheet := (<Timesheet id="TS_1_36119438">
                          <!-- SCHEDULE -->
                          <timeReference>UTC</timeReference>
                          <startDate>31-03</startDate>
                          <endDate>05-01</endDate>
                          <day>MON</day>
                          <dayTil>FRI</dayTil>
                          <startTime>00:30</startTime>
                          <endTime>14:00</endTime>
                          <daylightSavingAdjust>YES</daylightSavingAdjust>
                          <excluded>NO</excluded>
                        </Timesheet>,
                        <Timesheet id="TS_1_36119438">
                          <!-- SCHEDULE -->
                          <timeReference>UTC</timeReference>
                          <startDate>31-03</startDate>
                          <endDate>05-01</endDate>
                          <day>MON</day>
                          <dayTil>FRI</dayTil>
                          <startTime>00:30</startTime>
                          <endTime>14:00</endTime>
                          <daylightSavingAdjust>YES</daylightSavingAdjust>
                          <excluded>YES</excluded>
                        </Timesheet>)
let $beginTime := xs:dateTime('2017-05-22T03:04:00.000Z')
  let $endTime := xs:dateTime('2017-05-23T12:04:00.000Z')
  
let $h := dke:is-holiday(xs:date("2017-01-02"),"at")

let $t := dke:get-temporal-relevant-notams("1",2)

let $ht := dke:handle-timesheets($timesheet,$beginTime,$endTime)

return $ht[@exclusion="true"]
