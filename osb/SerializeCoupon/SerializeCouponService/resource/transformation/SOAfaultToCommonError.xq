(:: pragma  parameter="$soafault" type="anyType" ::)
(:: pragma  parameter="$inputRequest" type="anyType" ::)
(:: pragma bea:global-element-return element="ns0:ODComnErrorStructure" location="../../../CommonErrorHandler/resource/schema/ODComnErrorStructure.xsd" ::)

declare namespace ns0 = "http://www.officedepot.com/officedepot/ODComnErrorStructure/1.0";
declare namespace xf = "http://tempuri.org/SerializeCouponService/transformation/SOAfaultToCommonError/";

declare function xf:SOAfaultToCommonError($soafault as element(*),
    $inputRequest as element(*),
    $systemName as xs:string,
    $messageSourceSystem as xs:string,
    $messageOperation as xs:string,
    $messageVersion as xs:string,
    $messageType as xs:string,
    $messageID as xs:string,
    $domain as xs:string,
    $processStep as xs:string,
    $errorSeverity as xs:string,
    $errorType as xs:string,
    $processName as xs:string)
    as element(ns0:ODComnErrorStructure) {
        <ns0:ODComnErrorStructure>
            <ns0:ODComnErrorStructureList>
                <ns0:ProcessInfo>
                    <ns0:Domain>{ $domain }</ns0:Domain>
                    <ns0:ProcessName>{ $processName }</ns0:ProcessName>
                    <ns0:SystemName>{ $systemName }</ns0:SystemName>
                </ns0:ProcessInfo>
                <ns0:ErrorDetails>
                    <ns0:ProcessStep>{ $processStep }</ns0:ProcessStep>
                    <ns0:ErrorCode>{$soafault/*:errorCode/text()}</ns0:ErrorCode>
                    <ns0:ErrorDescription>{$soafault/*:reason/text()}</ns0:ErrorDescription>
                    <ns0:ErrorText>{$soafault/*:reason/text()}</ns0:ErrorText>
                    <ns0:ErrorType>{ $errorType }</ns0:ErrorType>
                    <ns0:ErrorSeverity>{ xs:integer($errorSeverity) }</ns0:ErrorSeverity>
                    <ns0:ErrorDateTime>{fn:current-dateTime()}</ns0:ErrorDateTime>
                </ns0:ErrorDetails>
                <ns0:MessageDetails>
                    <ns0:MessageID>{ xs:integer($messageID) }</ns0:MessageID>
                    <ns0:MessageDateTime>{fn:current-dateTime()}</ns0:MessageDateTime>
                    <ns0:MessageType>{ $messageType }</ns0:MessageType>
                    <ns0:MessageVersion>{ $messageVersion }</ns0:MessageVersion>
                    <ns0:MessageOperation>{ $messageOperation }</ns0:MessageOperation>
                    <ns0:MessageSourceSystem>{ $messageSourceSystem }</ns0:MessageSourceSystem>
                    <ns0:MessagePayload>{ $inputRequest/@* , $inputRequest/node() }</ns0:MessagePayload>
                </ns0:MessageDetails>
            </ns0:ODComnErrorStructureList>
        </ns0:ODComnErrorStructure>
};

declare variable $soafault as element(*) external;
declare variable $inputRequest as element(*) external;
declare variable $systemName as xs:string external;
declare variable $messageSourceSystem as xs:string external;
declare variable $messageOperation as xs:string external;
declare variable $messageVersion as xs:string external;
declare variable $messageType as xs:string external;
declare variable $messageID as xs:string external;
declare variable $domain as xs:string external;
declare variable $processStep as xs:string external;
declare variable $errorSeverity as xs:string external;
declare variable $errorType as xs:string external;
declare variable $processName as xs:string external;

xf:SOAfaultToCommonError($soafault,
    $inputRequest,
    $systemName,
    $messageSourceSystem,
    $messageOperation,
    $messageVersion,
    $messageType,
    $messageID,
    $domain,
    $processStep,
    $errorSeverity,
    $errorType,
    $processName)