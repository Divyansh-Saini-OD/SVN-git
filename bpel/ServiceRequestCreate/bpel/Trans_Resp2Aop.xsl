<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="APPS_XX_CS_TDS_SR_PKG_CREATE_SERVICEREQUEST.xsd"/>
      <rootElement name="OutputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_TDS_SR_PKG/CREATE_SERVICEREQUEST/"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="ebsSrResponse.xsd"/>
      <rootElement name="Root-Element" namespace="http://TargetNamespace.com/SRresponse2Aops"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.3.0(build 070615.0525) AT [TUE MAY 04 14:09:57 EDT 2010]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:ns0="http://www.w3.org/2001/XMLSchema"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_TDS_SR_PKG/CREATE_SERVICEREQUEST/"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:nxsd="http://xmlns.oracle.com/pcbpel/nxsd"
                xmlns:extn="http://xmlns.oracle.com/pcbpel/nxsd/extensions"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:tns="http://TargetNamespace.com/SRresponse2Aops"
                exclude-result-prefixes="xsl ns0 db nxsd extn tns bpws ehdr hwf xp20 xref ora ids orcl">
  <xsl:template match="/">
    <tns:Root-Element>
      <xsl:for-each select="/db:OutputParameters/db:P_SR_REQ_REC">
        <tns:RESPONSE_MQ>
          <tns:request_type>
            <xsl:text disable-output-escaping="no">TDSERVICE</xsl:text>
          </tns:request_type>
          <tns:action_code>
            <xsl:text disable-output-escaping="no">ERR</xsl:text>
          </tns:action_code>
          <xsl:for-each select="../db:P_ORDER_TBL/db:P_ORDER_TBL_ITEM">
            <tns:SKU_record>
              <tns:Sku>
                <xsl:value-of select="db:SKU_ID"/>
              </tns:Sku>
              <tns:Sku_quantity>
                <xsl:value-of select="db:QUANTITY"/>
              </tns:Sku_quantity>
            </tns:SKU_record>
          </xsl:for-each>
        </tns:RESPONSE_MQ>
      </xsl:for-each>
    </tns:Root-Element>
  </xsl:template>
</xsl:stylesheet>
