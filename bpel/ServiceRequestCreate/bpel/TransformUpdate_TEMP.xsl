<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="APPS_XX_CS_TDS_SR_PKG_CREATE_SERVICEREQUEST.xsd"/>
      <rootElement name="InputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_TDS_SR_PKG/CREATE_SERVICEREQUEST/"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="APPS_XX_CS_TDS_SR_PKG_UPDATE_SERVICEREQUEST.xsd"/>
      <rootElement name="InputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_TDS_SR_PKG/UPDATE_SERVICEREQUEST/"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.3.0(build 070615.0525) AT [TUE MAY 11 08:04:08 EDT 2010]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_TDS_SR_PKG/UPDATE_SERVICEREQUEST/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:ns1="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_TDS_SR_PKG/CREATE_SERVICEREQUEST/"
                xmlns:ns0="http://www.w3.org/2001/XMLSchema"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                exclude-result-prefixes="xsl ns1 ns0 db xref xp20 bpws ora ehdr orcl ids hwf">
  <xsl:template match="/">
    <db:InputParameters>
      <db:P_SR_NUMBER>
        <xsl:value-of select="/ns1:InputParameters/ns1:P_SR_REQ_REC/ns1:REQUEST_NUMBER"/>
      </db:P_SR_NUMBER>
      <db:P_SR_STATUS_ID>
        <xsl:value-of select='xp20:upper-case("CANCELLED")'/>
      </db:P_SR_STATUS_ID>
      <db:P_CANCEL_LOG>
        <xsl:value-of select="/ns1:InputParameters/ns1:P_SR_REQ_REC/ns1:COMMENTS"/>
      </db:P_CANCEL_LOG>
      <db:P_ORDER_TBL>
        <xsl:for-each select="/ns1:InputParameters/ns1:P_ORDER_TBL/ns1:P_ORDER_TBL_ITEM">
          <db:P_ORDER_TBL_ITEM>
            <db:ORDER_NUMBER>
              <xsl:value-of select="ns1:ORDER_NUMBER"/>
            </db:ORDER_NUMBER>
            <db:ORDER_SUB>
              <xsl:value-of select="ns1:ORDER_SUB"/>
            </db:ORDER_SUB>
            <db:SKU_ID>
              <xsl:value-of select="ns1:SKU_ID"/>
            </db:SKU_ID>
            <db:SKU_DESCRIPTION>
              <xsl:value-of select="ns1:SKU_DESCRIPTION"/>
            </db:SKU_DESCRIPTION>
            <db:QUANTITY>
              <xsl:value-of select="ns1:QUANTITY"/>
            </db:QUANTITY>
            <db:MANUFACTURER_INFO>
              <xsl:value-of select="ns1:MANUFACTURER_INFO"/>
            </db:MANUFACTURER_INFO>
            <db:ORDER_LINK>
              <xsl:value-of select="ns1:ORDER_LINK"/>
            </db:ORDER_LINK>
            <db:ATTRIBUTE1>
              <xsl:value-of select="ns1:ATTRIBUTE1"/>
            </db:ATTRIBUTE1>
            <db:ATTRIBUTE2>
              <xsl:value-of select="ns1:ATTRIBUTE2"/>
            </db:ATTRIBUTE2>
            <db:ATTRIBUTE3>
              <xsl:value-of select="ns1:ATTRIBUTE3"/>
            </db:ATTRIBUTE3>
            <db:ATTRIBUTE4>
              <xsl:value-of select="ns1:ATTRIBUTE4"/>
            </db:ATTRIBUTE4>
            <db:ATTRIBUTE5>
              <xsl:value-of select="ns1:ATTRIBUTE5"/>
            </db:ATTRIBUTE5>
          </db:P_ORDER_TBL_ITEM>
        </xsl:for-each>
      </db:P_ORDER_TBL>
    </db:InputParameters>
  </xsl:template>
</xsl:stylesheet>
