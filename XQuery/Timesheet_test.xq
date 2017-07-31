import module namespace functx = "http://www.functx.com";
import module namespace dke = "at.jku.dke";



let $beginTime := xs:dateTime('2017-06-12T03:04:00.000Z')
let $endTime := xs:dateTime('2017-06-24T12:04:00.000Z')

let $messages := db:open("Herucles")//*:AIXMBasicMessage
  

(: enter ID of message here :)
let $ht := dke:handle-timesheets($messages[@id = "ID_1"]//*:Timesheet,$beginTime,$endTime)


return $ht
