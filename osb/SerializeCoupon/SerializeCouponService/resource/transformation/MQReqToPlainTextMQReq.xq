(:: pragma bea:global-element-parameter parameter="$serializedCouponMQRequestABM1" element="ns0:SerializedCouponMQRequestABM" location="../schema/SerializedCouponMQRequestABM.xsd" ::)

declare namespace ns0 = "http://xmlns.officedepot.com/ApplicationMessage/POS/Custom/ABM/SerializedCouponMQRequestABM/V1";
declare namespace xf = "http://tempuri.org/SerializeCouponService/transformation/MQReqToPlainTextMQReq/";

declare function xf:MQReqToPlainTextMQReq($serializedCouponMQRequestABM1 as element(ns0:SerializedCouponMQRequestABM))
    as xs:string {
        fn:concat($serializedCouponMQRequestABM1/ns0:CouponId/text(),$serializedCouponMQRequestABM1/ns0:AgentId,$serializedCouponMQRequestABM1/ns0:OriginalPOSTransaction,$serializedCouponMQRequestABM1/ns0:ActionFlag)
};

declare variable $serializedCouponMQRequestABM1 as element(ns0:SerializedCouponMQRequestABM) external;

xf:MQReqToPlainTextMQReq($serializedCouponMQRequestABM1)