(:: pragma bea:global-element-parameter parameter="$activateToken1" element="ns1:activateToken" location="../schema/ODPOSAService.xsd" ::)
(:: pragma bea:global-element-return element="ns0:ActivateToken" location="../schema/XMLSchema_-1628437961.xsd" ::)

declare namespace ns2 = "http://schemas.microsoft.com/2003/10/Serialization/Arrays";
declare namespace ns1 = "http://www.officedepot.com/officedepot/V1/ODPOSAServiceSchema";
declare namespace ns3 = "http://www.officedepot.com/officedepot/V1/Serialization/Arrays";
declare namespace ns0 = "http://Microsoft.com/mscis/";
declare namespace xf = "http://tempuri.org/POSAProject/Resources/Xquery/XqueryODActivateReqToPOSAServiceReq/";

declare function xf:XqueryODActivateReqToPOSAServiceReq($activateToken1 as element(ns1:activateToken))
    as element(ns0:ActivateToken) {
        let $ODActivateToken := $activateToken1
        return
            <ns0:ActivateToken>
                {
                    for $serialNumber in $ODActivateToken/ns1:serialNumber
                    return
                        <ns0:vendorSerialNumber>{ data($serialNumber) }</ns0:vendorSerialNumber>
                }
                {
                    for $storeId in $ODActivateToken/ns1:storeId
                    return
                        <ns0:storeId>{ data($storeId) }</ns0:storeId>
                }
                <ns0:clientTransactionId>{ fn-bea:uuid() }</ns0:clientTransactionId>
                {
                    for $attributes in $ODActivateToken/ns1:attributes
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
            </ns0:ActivateToken>
};

declare variable $activateToken1 as element(ns1:activateToken) external;

xf:XqueryODActivateReqToPOSAServiceReq($activateToken1)