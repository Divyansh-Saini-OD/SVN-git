<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="APPS_XX_QA_SC_VEN_3PA_ADT_BPEL_PKG_VENDOR_AUDIT_RESULT.xsd"/>
      <rootElement name="OutputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_QA_SC_VEN_3PA_ADT_BPEL_PKG/VENDOR_AUDIT_RESULT/"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="ScAudirResultsResponse.xsd"/>
      <rootElement name="ScAudirResultsResponse" namespace="http://xmlns.oracle.com/ScAudirResultsResponse"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.3.0(build 070615.0525) AT [TUE MAY 31 20:44:43 EDT 2011]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:ns1="http://xmlns.oracle.com/ScAudirResultsResponse"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:ns0="http://www.w3.org/2001/XMLSchema"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_QA_SC_VEN_3PA_ADT_BPEL_PKG/VENDOR_AUDIT_RESULT/"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                exclude-result-prefixes="xsl ns0 db ns1 xref xp20 bpws ora ehdr orcl ids hwf">
  <xsl:template match="/">
    <ns1:ScAudirResultsResponse>
      <ns1:ReturnCode>
        <xsl:value-of select="/db:OutputParameters/db:X_RETURN_CD"/>
      </ns1:ReturnCode>
      <ns1:ReturnMsg>
        <xsl:value-of select="/db:OutputParameters/db:X_RETURN_MSG"/>
      </ns1:ReturnMsg>
    </ns1:ScAudirResultsResponse>
  </xsl:template>
</xsl:stylesheet>
