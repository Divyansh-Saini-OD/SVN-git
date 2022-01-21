xquery version "1.0" encoding "Cp1252";
(:: pragma bea:global-element-parameter parameter="$errorNotificationFields1" element="ns0:ErrorNotification" location="../schema/EmailFaultMessage.xsd" ::)

declare namespace xf = "http://tempuri.org/SendNotificationService/resource/transformation/CreateFaultMessage2/";
declare namespace ns0 = "http://officedepot.com/EmailFaultMessage";

declare function xf:CreateFaultMessage2($errorNotificationFields1 as element(ns0:ErrorNotification))
    as xs:string {
        concat('<html>
<head title="Error Notification"/>
<center>
<h3>
<font face="Verdana">Error Notification</font>
</h3>
</center>
<body>
<table align="center" bordercolor="black" border="2" border-collapse="collapse" width="100%">
<tbody>
<tr>
<td align="center" colspan="2" valign="center" bgcolor="#cccc99" nowrap="nowrap">
<font color="#336899" size="+1" face="Verdana">
<b>Process Information</b>
</font>
</td>
</tr>
<tr>
<td bgcolor="#f7f7e7" nowrap="nowrap">
<font color="#336899">
<span style="font-weight:bold; ">Domain</span>
</font>
</td>
<td bgcolor="#f7f7e7">',
$errorNotificationFields1/*:domain/text(),
'</td>
</tr>
<tr>
<td bgcolor="#f7f7e7" nowrap="nowrap">
<font color="#336899">
<span style="font-weight:bold; ">Service Name</span>
</font>
</td>
<td bgcolor="#f7f7e7">',
$errorNotificationFields1/*:serviceName/text(),
'</td>
</tr>
<tr>
<td bgcolor="#f7f7e7" nowrap="nowrap">
<font color="#336899">
<span style="font-weight:bold; ">Transaction Id</span>
</font>
</td>
<td bgcolor="#f7f7e7">',
$errorNotificationFields1/*:transactionId/text(),
'</td>
</tr>
<tr>
<td bgcolor="#f7f7e7" nowrap="nowrap">
<font color="#336899">
<span style="font-weight:bold; ">System</span>
</font>
</td>
<td bgcolor="#f7f7e7">',
$errorNotificationFields1/*:systemName/text(),
'</td>
</tr>
<tr>
<td align="center" colspan="2" valign="center" bgcolor="#cccc99" nowrap="nowrap">
<font color="#336899" size="+1" face="Verdana">
<b>Error Details</b>
</font>
</td>
</tr>
<tr>
<td bgcolor="#f7f7e7" nowrap="nowrap">
<font color="#336899">
<span style="font-weight:bold; ">Error Severity</span>
</font>
</td>
<td bgcolor="#f7f7e7">',
$errorNotificationFields1/*:errorSeverity/text(),
'</td>
</tr>
<tr>
<td bgcolor="#f7f7e7" nowrap="nowrap">
<font color="#336899">
<span style="font-weight:bold; ">Error Type</span>
</font>
</td>
<td bgcolor="#f7f7e7">',
$errorNotificationFields1/*:errorType/text(),
'</td>
</tr>
<tr>
<td bgcolor="#f7f7e7" nowrap="nowrap">
<font color="#336899">
<span style="font-weight:bold; ">Error Code</span>
</font>
</td>
<td bgcolor="#f7f7e7">',
$errorNotificationFields1/*:errorCode/text(),
'</td>
</tr>
<tr>
<td bgcolor="#f7f7e7" nowrap="nowrap">
<font color="#336899">
<span style="font-weight:bold; ">Date</span>
</font>
</td>
<td bgcolor="#f7f7e7">',
fn:current-dateTime(),
'</td>
</tr>
<tr>
<td bgcolor="#f7f7e7" nowrap="nowrap">
<font color="#336899">
<span style="font-weight:bold; ">Error Text</span>
</font>
</td>
<td bgcolor="#f7f7e7">',
"",
'</td>
</tr>
<tr>
<td bgcolor="#f7f7e7" nowrap="nowrap">
<font color="#336899">
<span style="font-weight:bold; ">Error Description</span>
</font>
</td>
<td bgcolor="#f7f7e7">',
$errorNotificationFields1/*:errorDescription/text(),
'</td></tr>',
for $i in $errorNotificationFields1/*:FlexFields/*:FlexField
	return concat('<tr>
<td bgcolor="#f7f7e7" nowrap="nowrap">
<font color="#336899">
<span style="font-weight:bold; ">',$i/*:FlexFieldName/text(),'</span>
</font>
</td>
<td bgcolor="#f7f7e7">',
$i/*:FlexFieldValue/text(),'
</td>
</tr>'),
'</tbody>
</table>
</body>
</html>')
};
    
declare variable $errorNotificationFields1 as element(ns0:ErrorNotification) external;

xf:CreateFaultMessage2($errorNotificationFields1)
