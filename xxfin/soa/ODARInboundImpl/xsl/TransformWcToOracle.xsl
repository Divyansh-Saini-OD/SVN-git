<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="WSDL">
      <schema location="../arInboundWS.wsdl"/>
      <rootElement name="ar_inbound_request" namespace="http://www.officedepot.com/officedepot/ARInbound"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="../xsd/APPS_XX_AR_WC_INBOUND_PKG_INSERT_STG.xsd"/>
      <rootElement name="InputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_AR_WC_INBOUND_PKG/INSERT_STG/"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 11.1.1.4.0(build 110106.1932.5682) AT [WED JUN 06 16:49:22 EDT 2012]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:mhdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.mediator.service.common.functions.MediatorExtnFunction"
                xmlns:bpel="http://docs.oasis-open.org/wsbpel/2.0/process/executable"
                xmlns:oraext="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:dvm="http://www.oracle.com/XSL/Transform/java/oracle.tip.dvm.LookupValue"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:tns="http://oracle.com/sca/soapservice/officedepot/ODARInboundImpl/arInboundWS"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:med="http://schemas.oracle.com/mediator/xpath"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:bpm="http://xmlns.oracle.com/bpmn20/extensions"
                xmlns:xdk="http://schemas.oracle.com/bpel/extension/xpath/function/xdk"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_AR_WC_INBOUND_PKG/INSERT_STG/"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:socket="http://www.oracle.com/XSL/Transform/java/oracle.tip.adapter.socket.ProtocolTranslator"
                xmlns:inp1="http://www.officedepot.com/officedepot/ARInbound"
                xmlns:ldap="http://schemas.oracle.com/xpath/extension/ldap"
                exclude-result-prefixes="xsi xsl tns xsd wsdl inp1 db bpws xp20 mhdr bpel oraext dvm hwf med ids bpm xdk xref ora socket ldap">
  <xsl:template match="/">
    <db:InputParameters>
      <db:P_TRX_CATEGORY>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:CATEGORY"/>
      </db:P_TRX_CATEGORY>
      <db:P_WC_ID>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:WC_ID"/>
      </db:P_WC_ID>
      <db:P_CUSTOMER_TRX_ID>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:CUSTOMER_TRX_ID"/>
      </db:P_CUSTOMER_TRX_ID>
      <db:P_TRANSACTION_NUMBER>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:TRANSACTION_NUMBER"/>
      </db:P_TRANSACTION_NUMBER>
      <db:P_DISPUTE_NUMBER>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:DISPUTE_NUMBER"/>
      </db:P_DISPUTE_NUMBER>
      <db:P_CUST_ACCOUNT_ID>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:CUST_ACCOUNT_ID"/>
      </db:P_CUST_ACCOUNT_ID>
      <db:P_CUST_ACCT_NUMBER>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:CUST_ACCT_NUMBER"/>
      </db:P_CUST_ACCT_NUMBER>
      <db:P_BILL_TO_SITE_ID>
        <xsl:text disable-output-escaping="no"></xsl:text>
      </db:P_BILL_TO_SITE_ID>
      <db:P_AMOUNT>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:AMOUNT"/>
      </db:P_AMOUNT>
      <db:P_CURRENCY_CODE>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:CURRENCY_CODE"/>
      </db:P_CURRENCY_CODE>
      <db:P_REASON_CODE>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:REASON_CODE"/>
      </db:P_REASON_CODE>
      <db:P_COMMENTS>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:COMMENTS"/>
      </db:P_COMMENTS>
      <db:P_REQUEST_DATE>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:REQUEST_DATE"/>
      </db:P_REQUEST_DATE>
      <db:P_REQUESTED_BY>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:REQUESTED_BY"/>
      </db:P_REQUESTED_BY>
      <db:P_SEND_REFUND>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:SEND_REFUND"/>
      </db:P_SEND_REFUND>
      <db:P_TRANSACTION_TYPE>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:TRANSACTION_TYPE"/>
      </db:P_TRANSACTION_TYPE>
      <db:P_DISPUTE_STATUS>
        <xsl:value-of select="/inp1:ar_inbound_request/inp1:P_DISPUTE_STATUS"/>
      </db:P_DISPUTE_STATUS>
    </db:InputParameters>
  </xsl:template>
</xsl:stylesheet>
