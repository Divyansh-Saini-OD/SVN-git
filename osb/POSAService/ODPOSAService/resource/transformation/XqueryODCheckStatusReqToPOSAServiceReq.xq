(:: pragma bea:global-element-parameter parameter="$checkStatus1" element="ns1:checkStatus" location="../schema/ODPOSAService.xsd" ::)
(:: pragma bea:global-element-return element="ns0:CheckStatus" location="../schema/XMLSchema_-1628437961.xsd" ::)

declare namespace ns1 = "http://www.officedepot.com/officedepot/V1/ODPOSAServiceSchema";
declare namespace ns0 = "http://Microsoft.com/mscis/";
declare namespace xf = "http://tempuri.org/POSAProject/Resources/Xquery/XqueryODCheckStatusReqToPOSAServiceReq/";

declare function xf:XqueryODCheckStatusReqToPOSAServiceReq($checkStatus1 as element(ns1:checkStatus))
    as element(ns0:CheckStatus) {
        <ns0:CheckStatus>
            {
                for $serialNumber in $checkStatus1/ns1:serialNumber
                return
                    <ns0:vendorSerialNumber>{ data($serialNumber) }</ns0:vendorSerialNumber>
            }
        </ns0:CheckStatus>
};

declare variable $checkStatus1 as element(ns1:checkStatus) external;

xf:XqueryODCheckStatusReqToPOSAServiceReq($checkStatus1)