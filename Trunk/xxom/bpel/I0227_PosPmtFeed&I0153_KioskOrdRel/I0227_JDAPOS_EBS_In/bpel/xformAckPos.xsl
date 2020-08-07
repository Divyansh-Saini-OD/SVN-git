<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="APPS_XX_BPEL_SVCJDAPOSREAD_XX_OM_POS_SHIP_CONF_PKG-24OD_PO.xsd"/>
      <rootElement name="OutputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_BPEL_SVCJDAPOSREAD/XX_OM_POS_SHIP_CONF_PKG-24OD_PO/"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="AcknowledgePOS.xsd"/>
      <rootElement name="POSACK" namespace="http://www.thiscompany.com/ns/sales"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.1.0(build 061009.0802) AT [MON JUN 25 14:41:04 IST 2007]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_BPEL_SVCJDAPOSREAD/XX_OM_POS_SHIP_CONF_PKG-24OD_PO/"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:pa="http://www.thiscompany.com/ns/sales"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:ns0="http://www.w3.org/2001/XMLSchema"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                exclude-result-prefixes="xsl db ns0 pa xp20 bpws ora ehdr orcl ids hwf">
  <xsl:template match="/">
    <pa:POSACK>
      <OrderNumber>
        <xsl:value-of select="/db:OutputParameters/P_ORDER_NUMBER"/>
      </OrderNumber>
      <xsl:for-each select="/db:OutputParameters/X_ORDER_LINES_TBL_OUT/X_ORDER_LINES_TBL_OUT_ITEM">
        <Detail>
          <LineNumber>
            <xsl:value-of select="LINE_NUMBER"/>
          </LineNumber>
        </Detail>
      </xsl:for-each>
      <Status>
        <xsl:value-of select="/db:OutputParameters/X_STATUS"/>
      </Status>
      <TransactionDatetime>
        <xsl:value-of select="/db:OutputParameters/X_TRANSACTION_DATE"/>
      </TransactionDatetime>
      <Failuremessage>
        <xsl:value-of select="/db:OutputParameters/X_ORDER_LINES_TBL_OUT/X_ORDER_LINES_TBL_OUT_ITEM/ERROR_MESSAGE"/>
      </Failuremessage>
    </pa:POSACK>
  </xsl:template>
</xsl:stylesheet>
