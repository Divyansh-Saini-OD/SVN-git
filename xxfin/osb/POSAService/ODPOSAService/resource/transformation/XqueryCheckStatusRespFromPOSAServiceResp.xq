(:: pragma bea:global-element-parameter parameter="$checkStatusResponse1" element="ns0:CheckStatusResponse" location="../schema/XMLSchema_-1628437961.xsd" ::)
(:: pragma bea:global-element-return element="ns1:checkStatusResponse" location="../schema/ODPOSAService.xsd" ::)

declare namespace ns1 = "http://www.officedepot.com/officedepot/V1/ODPOSAServiceSchema";
declare namespace ns0 = "http://Microsoft.com/mscis/";
declare namespace xf = "http://tempuri.org/ODPOSAPrl/ODPOSAService/resource/transformation/XqueryCheckStatusRespFromPOSAServiceResp/";

declare function xf:XqueryCheckStatusRespFromPOSAServiceResp($checkStatusResponse1 as element(ns0:CheckStatusResponse))
    as element(ns1:checkStatusResponse) {
        let $CheckStatusResponse := $checkStatusResponse1
        return
            <ns1:checkStatusResponse>
                {
                    for $CheckStatusResult in $CheckStatusResponse/ns0:CheckStatusResult
                    return
                        <ns1:checkStatusResult>
                            {
                                for $TokenStatusCode in $CheckStatusResult/ns0:TokenStatusCode
                                return
                                    <ns1:tokenStatusCode>{ data($TokenStatusCode) }</ns1:tokenStatusCode>
                            }
                            {
                                for $TokenStatusDescription in $CheckStatusResult/ns0:TokenStatusDescription
                                return
                                    <ns1:tokenStatusDescription>{ data($TokenStatusDescription) }</ns1:tokenStatusDescription>
                            }
                        </ns1:checkStatusResult>
                }
            </ns1:checkStatusResponse>
};

declare variable $checkStatusResponse1 as element(ns0:CheckStatusResponse) external;

xf:XqueryCheckStatusRespFromPOSAServiceResp($checkStatusResponse1)