(:: pragma bea:global-element-return element="ns0:SerializedCouponMQResponseABM" location="../schema/SerializedCouponMQResponseABM.xsd" ::)

declare namespace ns0 = "http://xmlns.officedepot.com/ApplicationMessage/POS/Custom/ABM/SerializedCouponMQResponseABM/V1";
declare namespace xf = "http://officedepot.com/SerializeCouponService/transformation/PlainTextMQRespToXMLMQResp/";

declare function xf:PlainTextMQRespToXMLMQResp($MQResp as xs:string)
    as element(ns0:SerializedCouponMQResponseABM) {
     <ns0:SerializedCouponMQResponseABM>
            <ns0:CouponId>{ fn:substring($MQResp,1,9) }</ns0:CouponId>
            <ns0:AgentId>{ fn:substring($MQResp,10,10) }</ns0:AgentId>
            <ns0:POSReturnCode>{fn:substring($MQResp,20,1)}</ns0:POSReturnCode>
            <ns0:NumberOfTimesUsed>{fn:substring($MQResp,21,5)}</ns0:NumberOfTimesUsed>
            <ns0:NumberOfUsesRemaining>{fn:substring($MQResp,26,5)}</ns0:NumberOfUsesRemaining>
            <ns0:LastPOSTransaction>{fn:substring($MQResp,31,20)}</ns0:LastPOSTransaction>
            <ns0:OriginalPOSTransaction>{fn:substring($MQResp,51,20)}</ns0:OriginalPOSTransaction>
            <ns0:DateOfTransaction>{fn:substring($MQResp,71,10)}</ns0:DateOfTransaction>
        </ns0:SerializedCouponMQResponseABM>
};

declare variable $MQResp as xs:string external;

xf:PlainTextMQRespToXMLMQResp($MQResp)