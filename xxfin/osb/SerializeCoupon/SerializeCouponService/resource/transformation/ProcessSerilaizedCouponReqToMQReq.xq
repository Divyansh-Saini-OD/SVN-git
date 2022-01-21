(:: pragma bea:global-element-parameter parameter="$serializedCouponRequestEBM1" element="ns1:SerializedCouponRequestEBM" location="../schema/SerializedCouponRequestEBM.xsd" ::)
(:: pragma bea:global-element-return element="ns2:SerializedCouponMQRequestABM" location="../schema/SerializedCouponMQRequestABM.xsd" ::)

declare namespace ns2 = "http://xmlns.officedepot.com/ApplicationMessage/POS/Custom/ABM/SerializedCouponMQRequestABM/V1";
declare namespace ns1 = "http://xmlns.officedepot.com/EnterpriseMessage/POS/Custom/EBM/SerializedCouponRequestEBM/V1";
declare namespace ns3 = "http://xmlns.officedepot.com/EnterpriseObjects/POS/Custom/Common/SerializedCouponCommon/V1";
declare namespace ns0 = "http://xmlns.officedepot.com/EnterpriseObjects/POS/Custom/EBO/SerializedCouponRequestEBO/V1";
declare namespace xf = "http://tempuri.org/SerializeCouponService/transformations/processSerilaizedCouponReqToMQReq/";
declare namespace functx = "http://www.functx.com";

declare function xf:processSerilaizedCouponReqToMQReq($serializedCouponRequestEBM1 as element(ns1:SerializedCouponRequestEBM))
    as element(ns2:SerializedCouponMQRequestABM) {
        <ns2:SerializedCouponMQRequestABM>
            <ns2:CouponId>{ functx:pad-string-to-length(data($serializedCouponRequestEBM1/SerializedCouponData/Identification/ns3:CouponCode), ' ', 9) }</ns2:CouponId>
            <ns2:AgentId>{ functx:pad-string-to-length(data($serializedCouponRequestEBM1/SerializedCouponData/Identification/ns3:AgentID), ' ', 10) }</ns2:AgentId>
            <ns2:OriginalPOSTransaction>{ functx:pad-string-to-length(data($serializedCouponRequestEBM1/SerializedCouponHeader/ns3:SourceID), ' ', 20) }</ns2:OriginalPOSTransaction>
            {
            if (upper-case(data($serializedCouponRequestEBM1/SerializedCouponData/MarkAsUsedIndicator)) = 'Y') then
            <ns2:ActionFlag>U</ns2:ActionFlag>
            else
            <ns2:ActionFlag>D</ns2:ActionFlag>
            }
        </ns2:SerializedCouponMQRequestABM>
};

declare function functx:pad-string-to-length 
  ( $stringToPad as xs:string? ,
    $padChar as xs:string ,
    $length as xs:integer )  as xs:string {
       
   substring(
     string-join (
       ($stringToPad, for $i in (1 to $length) return $padChar)
       ,'')
    ,1,$length)
 } ;

declare variable $serializedCouponRequestEBM1 as element(ns1:SerializedCouponRequestEBM) external;

xf:processSerilaizedCouponReqToMQReq($serializedCouponRequestEBM1)