<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="APPS_BAP_TDS_SR_PKG_CREATE_SERVICEREQUEST.xsd"/>
      <rootElement name="OutputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/BAP_TDS_SR_PKG/CREATE_SERVICEREQUEST/"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="ebsSr_Response.xsd"/>
      <rootElement name="Root-Element" namespace="http://TargetNamespace.com/ebsSrresponseSrvc"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.3.0(build 070615.0525) AT [TUE MAY 04 18:12:01 EDT 2010]. -->
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
                xmlns:tns="http://TargetNamespace.com/ebsSrresponseSrvc"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                exclude-result-prefixes="xsl xsd db nxsd extn tns bpws ehdr hwf xp20 xref ora ids orcl">
  <xsl:template match="/">
    <tns:Root-Element>
      <tns:RESPONSE_MQ>
        <tns:request_type>
          <xsl:text disable-output-escaping="no">TDSERVICE</xsl:text>
        </tns:request_type>
        <tns:action_code>
          <xsl:text disable-output-escaping="no">NEW</xsl:text>
        </tns:action_code>
        <tns:request_number>
          <xsl:value-of select="/db:OutputParameters/db:X_REQUEST_NUM"/>
        </tns:request_number>
        <tns:order_number>
          <xsl:value-of select="/db:OutputParameters/db:X_ORDER_NUM"/>
        </tns:order_number>
      </tns:RESPONSE_MQ>
    </tns:Root-Element>
  </xsl:template>
</xsl:stylesheet>
