<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="StgTableInsert_table.xsd"/>
      <rootElement name="XxApInvInterfaceStgCollection" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/top/StgTableInsert"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="APPS_XX_AP_DEL_INV_INTFC.xsd"/>
      <rootElement name="InputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_AP_DEL_INV_INTFC/"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.3.0(build 070615.0525) AT [FRI JUL 11 10:21:00 IST 2008]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_AP_DEL_INV_INTFC/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:ns0="http://xmlns.oracle.com/pcbpel/adapter/db/top/StgTableInsert"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                exclude-result-prefixes="xsl xs ns0 db xref xp20 bpws ora ehdr orcl ids hwf">
  <xsl:template match="/">
    <db:InputParameters>
      <db:P_BATCH_ID>
        <xsl:value-of select="/ns0:XxApInvInterfaceStgCollection/ns0:XxApInvInterfaceStg/ns0:batchId"/>
      </db:P_BATCH_ID>
    </db:InputParameters>
  </xsl:template>
</xsl:stylesheet>
