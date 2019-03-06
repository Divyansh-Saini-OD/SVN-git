<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="APPS_XX_CS_SERVICEREQUEST_PKG_CREATE_SERVICEREQUEST.xsd"/>
      <rootElement name="OutputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_SERVICEREQUEST_PKG/CREATE_SERVICEREQUEST/"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="OMServiceOrder2AOPS.xsd"/>
      <rootElement name="Root-Element" namespace="http://TargetNamespace.com/OMServiceOrderEvent"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.3.0(build 070615.0525) AT [SAT APR 24 22:34:07 EDT 2010]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:tns="http://TargetNamespace.com/OMServiceOrderEvent"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:ns0="http://www.w3.org/2001/XMLSchema"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:nxsd="http://xmlns.oracle.com/pcbpel/nxsd"
                xmlns:extn="http://xmlns.oracle.com/pcbpel/nxsd/extensions"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_SERVICEREQUEST_PKG/CREATE_SERVICEREQUEST/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                exclude-result-prefixes="xsl ns0 db tns nxsd extn bpws ehdr hwf xp20 xref ora ids orcl">
  <xsl:template match="/">
    <tns:Root-Element>
      <xsl:for-each select="/db:OutputParameters/db:P_SR_REQ_REC">
        <tns:FIELD_SERVICE_ORDER_HEADER>
          <tns:action_code>
            <xsl:value-of select='xp20:upper-case("NEW")'/>
          </tns:action_code>
          <tns:request_number>
            <xsl:value-of select="db:REQUEST_NUMBER"/>
          </tns:request_number>
        </tns:FIELD_SERVICE_ORDER_HEADER>
      </xsl:for-each>
      <xsl:for-each select="/db:OutputParameters/db:P_ORDER_TBL">
        <tns:SKU_RECORD>
          <tns:sku>
            <xsl:value-of select="db:P_ORDER_TBL_ITEM/db:SKU_ID"/>
          </tns:sku>
          <tns:sku_quantity>
            <xsl:value-of select="db:P_ORDER_TBL_ITEM/db:QUANTITY"/>
          </tns:sku_quantity>
        </tns:SKU_RECORD>
      </xsl:for-each>
    </tns:Root-Element>
  </xsl:template>
</xsl:stylesheet>
