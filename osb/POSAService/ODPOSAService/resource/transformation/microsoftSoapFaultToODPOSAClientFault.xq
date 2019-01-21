xquery version "1.0" encoding "Cp1252";
(:: pragma  parameter="$faultMapping" type="xs:anyType" ::)
(:: pragma  parameter="$soapFault" type="xs:anyType" ::)
(:: pragma bea:global-element-return element="ns0:PartnerServiceFault" location="../schema/POSAExceptions.xsd" ::)

declare namespace xf = "http://tempuri.org/ODPOSAPrl/ODPOSAService/resource/transformation/soapFaultToODPOSAClientFault/";
declare namespace ns0 = "http://www.officedepot.com/officedepot/V1/POSAExceptions";

declare function xf:soapFaultToODPOSAClientFault($faultMapping as element(*),
    $soapFault as element(*))
    as element(ns0:PartnerServiceFault) {
     

        <ns0:PartnerServiceFault>
        {let $temp:=
        
         if($faultMapping/errorMap[sourceErrorCodes/code=$soapFault//*:ErrorCode/text()]) then
          <temp>
           <ns0:ErrorCode>{ $faultMapping/errorMap[sourceErrorCodes/code=$soapFault//*:ErrorCode/text()]/destErrorCode/code/text() }</ns0:ErrorCode>
            <ns0:Message>{ $faultMapping/errorMap[sourceErrorCodes/code=$soapFault//*:ErrorCode/text()]/destErrorCode/description/text() }</ns0:Message>
          </temp>

         else
         
         <temp>
            <ns0:ErrorCode>{ $faultMapping/unknownError/destErrorCode/code/text() }</ns0:ErrorCode>
            <ns0:Message>{ $faultMapping/unknownError/destErrorCode/description/text() }</ns0:Message>
         </temp>
         
         return $temp/*}
        </ns0:PartnerServiceFault>
	
	

	

};

declare variable $faultMapping as element(*) external;
declare variable $soapFault as element(*) external;

xf:soapFaultToODPOSAClientFault($faultMapping,
    $soapFault)