<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="SrCreate.xsd"/>
      <rootElement name="Root-Element" namespace="http://TargetNamespace.com/InboundService"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="APPS_BAP_TDS_SR_PKG_CREATE_SERVICEREQUEST.xsd"/>
      <rootElement name="InputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/BAP_TDS_SR_PKG/CREATE_SERVICEREQUEST/"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.3.0(build 070615.0525) AT [TUE MAY 04 22:05:19 EDT 2010]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:nxsd="http://xmlns.oracle.com/pcbpel/nxsd"
                xmlns:extn="http://xmlns.oracle.com/pcbpel/nxsd/extensions"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/BAP_TDS_SR_PKG/CREATE_SERVICEREQUEST/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:tns="http://TargetNamespace.com/InboundService"
                exclude-result-prefixes="xsl xsd nxsd extn tns db bpws ehdr hwf xp20 xref ora ids orcl">
  <xsl:template match="/">
    <db:InputParameters>
      <xsl:for-each select="/tns:Root-Element/tns:SERVICE_MQ">
        <db:P_SR_REQ_REC>
          <db:CUSTOMER_ID>
            <xsl:value-of select="tns:customer_ref"/>
          </db:CUSTOMER_ID>
          <db:ORDER_NUMBER>
            <xsl:value-of select="tns:order_number"/>
          </db:ORDER_NUMBER>
          <db:LOCATION_ID>
            <xsl:value-of select="tns:store_number"/>
          </db:LOCATION_ID>
        </db:P_SR_REQ_REC>
      </xsl:for-each>
      <xsl:for-each select="/tns:Root-Element/tns:SERVICE_MQ/tns:SKU_record">
        <db:P_ORDER_TBL>
          <db:P_ORDER_TBL_ITEM>
            <db:SKU_ID>
              <xsl:value-of select="tns:Sku"/>
            </db:SKU_ID>
            <db:QUANTITY>
              <xsl:value-of select="tns:Sku_quantity"/>
            </db:QUANTITY>
            <db:ATTRIBUTE1>
              <xsl:value-of select="tns:Sku_vendor"/>
            </db:ATTRIBUTE1>
            <db:ATTRIBUTE2>
              <xsl:value-of select="tns:Sku_catagory"/>
            </db:ATTRIBUTE2>
            <db:ATTRIBUTE3>
              <xsl:value-of select="tns:Sku_parent_cat"/>
            </db:ATTRIBUTE3>
          </db:P_ORDER_TBL_ITEM>
        </db:P_ORDER_TBL>
      </xsl:for-each>
    </db:InputParameters>
  </xsl:template>
</xsl:stylesheet>
