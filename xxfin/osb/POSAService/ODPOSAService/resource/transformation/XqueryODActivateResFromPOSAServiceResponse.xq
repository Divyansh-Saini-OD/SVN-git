(:: pragma bea:global-element-parameter parameter="$activateTokenResponse1" element="ns0:ActivateTokenResponse" location="../schema/XMLSchema_-1628437961.xsd" ::)
(:: pragma bea:global-element-return element="ns1:activateTokenResponse" location="../schema/ODPOSAService.xsd" ::)

declare namespace ns1 = "http://www.officedepot.com/officedepot/V1/ODPOSAServiceSchema";
declare namespace ns0 = "http://Microsoft.com/mscis/";
declare namespace xf = "http://tempuri.org/POSAProject/Resources/Xquery/XqueryODActivateResFromPOSAServiceResponse/";

declare function xf:XqueryODActivateResFromPOSAServiceResponse($activateTokenResponse1 as element(ns0:ActivateTokenResponse))
    as element(ns1:activateTokenResponse) {
        let $ActivateTokenResponse := $activateTokenResponse1
        return
            <ns1:activateTokenResponse>
                {
                    for $ActivateTokenResult in $ActivateTokenResponse/ns0:ActivateTokenResult
                    return
                        <ns1:activateTokenResult>{ data($ActivateTokenResult) }</ns1:activateTokenResult>
                }
            </ns1:activateTokenResponse>
};

declare variable $activateTokenResponse1 as element(ns0:ActivateTokenResponse) external;

xf:XqueryODActivateResFromPOSAServiceResponse($activateTokenResponse1)