(:: pragma bea:global-element-parameter parameter="$serializedCouponMQResponseABM1" element="ns3:SerializedCouponMQResponseABM" location="../schema/SerializedCouponMQResponseABM.xsd" ::)
(:: pragma bea:global-element-return element="ns2:SerializedCouponResponseEBM" location="../schema/SerializedCouponResponseEBM.xsd" ::)

declare namespace ns2 = "http://xmlns.officedepot.com/EnterpriseMessage/POS/Custom/EBM/SerializedCouponResponseEBM/V1";
declare namespace ns1 = "http://xmlns.officedepot.com/EnterpriseObjects/POS/Custom/Common/SerializedCouponCommon/V1";
declare namespace ns3 = "http://xmlns.officedepot.com/ApplicationMessage/POS/Custom/ABM/SerializedCouponMQResponseABM/V1";
declare namespace ns0 = "http://xmlns.officedepot.com/EnterpriseObjects/POS/Custom/EBO/SerializedCouponResponseEBO/V1";
declare namespace xf = "http://tempuri.org/SerializeCouponService/transformation/MQRespToprocessSerializedCoupon/";
declare namespace ns4 = "http://www.bea.com/wli/sb/context";

declare function xf:MQRespToprocessSerializedCoupon($serializedCouponMQResponseABM1 as element(ns3:SerializedCouponMQResponseABM))
    as element(ns2:SerializedCouponResponseEBM) {
        <ns2:SerializedCouponResponseEBM>
            <ns2:SerializedCouponHeader>
                <ns1:SourceID>{ fn-bea:trim(data($serializedCouponMQResponseABM1/ns3:OriginalPOSTransaction)) }</ns1:SourceID>
            </ns2:SerializedCouponHeader>
            <ns2:SerializedCouponData>
                <ns0:Identification>
                    <ns1:CouponCode>{ fn-bea:trim(data($serializedCouponMQResponseABM1/ns3:CouponId)) }</ns1:CouponCode>
                    <ns1:AgentID>{ fn-bea:trim(data($serializedCouponMQResponseABM1/ns3:AgentId)) }</ns1:AgentID>
                </ns0:Identification>
                {
                if($serializedCouponMQResponseABM1/ns3:POSReturnCode/text() = '0') then
                (
                	<ns0:UsedCouponIndicator>N</ns0:UsedCouponIndicator>
                )
                else if($serializedCouponMQResponseABM1/ns3:POSReturnCode/text() = '1') then
                (
                	<ns0:UsedCouponIndicator>Y</ns0:UsedCouponIndicator>
                )
                else
                	""
                }
                <ns0:UsageAccrual>
                	<ns1:NumberOfUses>{xs:integer($serializedCouponMQResponseABM1/ns3:NumberOfTimesUsed/text())}</ns1:NumberOfUses>
                	<ns1:NumberOfUsesLeft>{xs:integer($serializedCouponMQResponseABM1/ns3:NumberOfUsesRemaining/text())}</ns1:NumberOfUsesLeft>
                </ns0:UsageAccrual>
                {
                if(fn-bea:trim($serializedCouponMQResponseABM1/ns3:LastPOSTransaction/text()) = 'WEB0') then
                <ns0:ConsumptionActivity>
                	<ns1:UsedDate>{$serializedCouponMQResponseABM1/ns3:DateOfTransaction/text()}</ns1:UsedDate>
                	<ns1:SourceID>{fn-bea:trim($serializedCouponMQResponseABM1/ns3:LastPOSTransaction/text())}</ns1:SourceID>
                	<ns1:Channel>WEB</ns1:Channel>
                </ns0:ConsumptionActivity>
                else
                <ns0:ConsumptionActivity>
                	<ns1:UsedDate>{$serializedCouponMQResponseABM1/ns3:DateOfTransaction/text()}</ns1:UsedDate>
                	<ns1:SourceID>{fn-bea:trim($serializedCouponMQResponseABM1/ns3:LastPOSTransaction/text())}</ns1:SourceID>
                	<ns1:Channel>POS</ns1:Channel>
                </ns0:ConsumptionActivity>
                }
            </ns2:SerializedCouponData>
        </ns2:SerializedCouponResponseEBM>
};

declare variable $serializedCouponMQResponseABM1 as element(ns3:SerializedCouponMQResponseABM) external;

xf:MQRespToprocessSerializedCoupon($serializedCouponMQResponseABM1)