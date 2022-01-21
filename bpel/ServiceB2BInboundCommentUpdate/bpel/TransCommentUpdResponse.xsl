<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="APPS_XX_CS_TDS_VEN_PKG_UPDATE_COMMENTS.xsd"/>
      <rootElement name="OutputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_TDS_VEN_PKG/UPDATE_COMMENTS/"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="B2BVendorSRCommentUpdateResponse.xsd"/>
      <rootElement name="B2bVendorSRUpdateProcessResponse" namespace="http://xmlns.oracle.com/B2bVendorSRUpdate"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.3.0(build 070615.0525) AT [WED AUG 11 11:54:40 EDT 2010]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_TDS_VEN_PKG/UPDATE_COMMENTS/"
                xmlns:ns0="http://www.w3.org/2001/XMLSchema"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:ns1="http://xmlns.oracle.com/B2bVendorSRUpdate"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                exclude-result-prefixes="xsl db ns0 ns1 xref xp20 bpws ora ehdr orcl ids hwf">
  <xsl:template match="/">
    <ns1:B2bVendorSRUpdateProcessResponse>
      <ns1:ReturnCode>
        <xsl:value-of select="/db:OutputParameters/db:X_RETURN_STATUS"/>
      </ns1:ReturnCode>
      <ns1:ReturnMsg>
        <xsl:value-of select="/db:OutputParameters/db:X_MSG_DATA"/>
      </ns1:ReturnMsg>
    </ns1:B2bVendorSRUpdateProcessResponse>
  </xsl:template>
</xsl:stylesheet>
