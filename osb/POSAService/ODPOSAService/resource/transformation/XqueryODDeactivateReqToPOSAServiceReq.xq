(:: pragma bea:global-element-parameter parameter="$deactivateToken1" element="ns1:deactivateToken" location="../schema/ODPOSAService.xsd" ::)
(:: pragma bea:global-element-return element="ns0:DeactivateToken" location="../schema/XMLSchema_-1628437961.xsd" ::)

declare namespace ns2 = "http://schemas.microsoft.com/2003/10/Serialization/Arrays";
declare namespace ns1 = "http://www.officedepot.com/officedepot/V1/ODPOSAServiceSchema";
declare namespace ns3 = "http://www.officedepot.com/officedepot/V1/Serialization/Arrays";
declare namespace ns0 = "http://Microsoft.com/mscis/";
declare namespace xf = "http://tempuri.org/POSAProject/Resources/Xquery/XqueryODDeactivateReqToPOSAServiceReq/";

declare function xf:XqueryODDeactivateReqToPOSAServiceReq($deactivateToken1 as element(ns1:deactivateToken))
    as element(ns0:DeactivateToken) {
        <ns0:DeactivateToken>
            {
                for $serialNumber in $deactivateToken1/ns1:serialNumber
                return
                    <ns0:vendorSerialNumber>{ data($serialNumber) }</ns0:vendorSerialNumber>
            }
            {
                for $storeId in $deactivateToken1/ns1:storeId
                return
                    <ns0:storeId>{ data($storeId) }</ns0:storeId>
            }
            <ns0:clientTransactionId>{ fn-bea:uuid() }</ns0:clientTransactionId>
            {
                for $attributes in $deactivateToken1/ns1:attributes
                return
                    <ns0:attributes>
                        {
                            for $KeyValueOfstringstring in $attributes/ns3:KeyValueOfstringstring
                            return
                                <ns2:KeyValueOfstringstring>
                                    <ns2:Key>{ data($KeyValueOfstringstring/ns3:Key) }</ns2:Key>
                                    <ns2:Value>{ data($KeyValueOfstringstring/ns3:Value) }</ns2:Value>
                                </ns2:KeyValueOfstringstring>
                        }
                    </ns0:attributes>
            }
        </ns0:DeactivateToken>
};

declare variable $deactivateToken1 as element(ns1:deactivateToken) external;

xf:XqueryODDeactivateReqToPOSAServiceReq($deactivateToken1)