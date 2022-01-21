(:: pragma bea:global-element-return element="ns0:sendEmail" location="../schema/SendNotificationService.xsd" ::)

declare namespace ns0 = "http://officedepot.com/SendNotificationService";
declare namespace xf = "http://tempuri.org/SerializeCouponService/resource/transformation/SOAPFaultToEmailNotification/";

declare function xf:SOAPFaultToEmailNotification($fromEmailID as xs:string,
    $toEmailID as xs:string,
    $subject as xs:string,
    $format as xs:string,
    $emailMessage as xs:string)
    as element(ns0:sendEmail) {
        <ns0:sendEmail>
            <ns0:senderAddress>
                <ns0:emailAddress>{ $fromEmailID }</ns0:emailAddress>
            </ns0:senderAddress>
            <ns0:toAddress>
                <ns0:emailAddress>{ $toEmailID }</ns0:emailAddress>
            </ns0:toAddress>
            <ns0:subject>{ $subject }</ns0:subject>
            <ns0:format>{ $format }</ns0:format>
            <ns0:message> {fn:concat("<![CDATA[",$emailMessage,"]]>") }</ns0:message>
        </ns0:sendEmail>
};

declare variable $fromEmailID as xs:string external;
declare variable $toEmailID as xs:string external;
declare variable $subject as xs:string external;
declare variable $format as xs:string external;
declare variable $emailMessage as xs:string external;

xf:SOAPFaultToEmailNotification($fromEmailID,
    $toEmailID,
    $subject,
    $format,
    $emailMessage)