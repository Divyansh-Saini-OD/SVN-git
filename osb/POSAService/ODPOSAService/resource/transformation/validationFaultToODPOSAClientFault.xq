xquery version "1.0" encoding "Cp1252";
(:: pragma  parameter="$soapFault" type="xs:anyType" ::)
(:: pragma bea:global-element-return element="ns0:PartnerServiceFault" location="../schema/POSAExceptions.xsd" ::)

declare namespace xf = "http://tempuri.org/ODPOSAPrl/ODPOSAService/resource/transformation/validationFaultToODPOSAClientFault/";
declare namespace ns0 = "http://www.officedepot.com/officedepot/V1/POSAExceptions";

declare function xf:validationFaultToODPOSAClientFault($soapFault as element(*))
    as element(ns0:PartnerServiceFault) {
      <ns0:PartnerServiceFault>
        {
        let $temp:=
          <temp>
           <ns0:ErrorCode>{ $soapFault//*:errorCode/text() }</ns0:ErrorCode>
            <ns0:Message>{ $soapFault//*:details/*:ValidationFailureDetail/*:message/text() }</ns0:Message>
	  </temp>
        return $temp/*
        }
       </ns0:PartnerServiceFault>


};


declare variable $soapFault as element(*) external;

xf:validationFaultToODPOSAClientFault($soapFault)