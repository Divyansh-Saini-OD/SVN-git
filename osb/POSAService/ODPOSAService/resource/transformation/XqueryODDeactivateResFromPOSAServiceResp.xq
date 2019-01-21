(:: pragma bea:global-element-parameter parameter="$deactivateTokenResponse1" element="ns0:DeactivateTokenResponse" location="../schema/XMLSchema_-1628437961.xsd" ::)
(:: pragma bea:global-element-return element="ns1:deactivateTokenResponse" location="../schema/ODPOSAService.xsd" ::)

declare namespace ns1 = "http://www.officedepot.com/officedepot/V1/ODPOSAServiceSchema";
declare namespace ns0 = "http://Microsoft.com/mscis/";
declare namespace xf = "http://tempuri.org/POSAProject/Resources/Xquery/XqueryODDeactivateResFromPOSAServiceResp/";

declare function xf:XqueryODDeactivateResFromPOSAServiceResp($deactivateTokenResponse1 as element(ns0:DeactivateTokenResponse))
    as element(ns1:deactivateTokenResponse) {
        let $DeactivateTokenResponse := $deactivateTokenResponse1
        return
            <ns1:deactivateTokenResponse>
                {
                    for $DeactivateTokenResult in $DeactivateTokenResponse/ns0:DeactivateTokenResult
                    return
                        <ns1:deactivateTokenResult>{ data($DeactivateTokenResult) }</ns1:deactivateTokenResult>
                }
            </ns1:deactivateTokenResponse>
};

declare variable $deactivateTokenResponse1 as element(ns0:DeactivateTokenResponse) external;

xf:XqueryODDeactivateResFromPOSAServiceResp($deactivateTokenResponse1)