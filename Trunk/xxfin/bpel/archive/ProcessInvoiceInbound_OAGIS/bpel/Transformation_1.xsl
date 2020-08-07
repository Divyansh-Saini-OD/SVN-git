<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="http://chilsoa01d.na.odcorp.net:7778/orabpel/xmllib/eaixml/oagis/v9/message/bod/ProcessInvoice.xsd"/>
      <rootElement name="ProcessInvoice" namespace="http://www.openapplications.org/oagis/9"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="../../../Office%20Depot/BPEL_Projects/bpel/ServiceSTGInsert_table.xsd"/>
      <rootElement name="XxApInvInterfaceStgCollection" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/top/ServiceSTGInsert"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.1.0(build 061009.0802) AT [WED JUN 13 10:07:41 EDT 2007]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                exclude-result-prefixes="xsl xp20 bpws ora ehdr orcl ids hwf">
  <xsl:template match="/">
  </xsl:template>
</xsl:stylesheet>
