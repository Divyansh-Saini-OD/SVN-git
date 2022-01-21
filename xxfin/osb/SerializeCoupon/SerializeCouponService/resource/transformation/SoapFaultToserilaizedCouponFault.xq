(:: pragma  parameter="$faultMapping" type="anyType" ::)
(:: pragma  parameter="$soapFault" type="anyType" ::)
(:: pragma bea:global-element-return element="ns0:SerializedCouponFaultMessage" location="../schema/SerializedCouponFaultMessage.xsd" ::)

declare namespace ns0 = "http://xmlns.officedepot.com/EnterpriseMessage/POS/Custom/Common/SerializedCouponFaultMessage/V1";
declare namespace xf = "http://tempuri.org/SerializeCouponService/resource/transformation/soapFaultToserilaizedCouponFault/";

declare function xf:soapFaultToserilaizedCouponFault($faultMapping as element(*),
    $soapFault as element(*))
    as element(ns0:SerializedCouponFaultMessage) {

        <ns0:SerializedCouponFaultMessage>
        {let $temp:=
        
         if($faultMapping/errorMap[sourceErrorCodes/code=$soapFault//*:errorCode/text()]) then
          <temp>
            <ns0:ErrorCode>{ $faultMapping/errorMap[sourceErrorCodes/code=$soapFault//*:errorCode/text()]/destErrorCode/code/text() }</ns0:ErrorCode>
            <ns0:ErrorMessage>{ $faultMapping/errorMap[sourceErrorCodes/code=$soapFault//*:errorCode/text()]/destErrorCode/description/text() }</ns0:ErrorMessage>
          </temp>

         else
         
         <temp>
            <ns0:ErrorCode>{ $faultMapping/unknownError/destErrorCode/code/text() }</ns0:ErrorCode>
            <ns0:ErrorMessage>{ $faultMapping/unknownError/destErrorCode/description/text() }</ns0:ErrorMessage>
         </temp>
         
         return $temp/*}
        </ns0:SerializedCouponFaultMessage>

};

declare variable $faultMapping as element(*) external;
declare variable $soapFault as element(*) external;

xf:soapFaultToserilaizedCouponFault($faultMapping,
    $soapFault)
