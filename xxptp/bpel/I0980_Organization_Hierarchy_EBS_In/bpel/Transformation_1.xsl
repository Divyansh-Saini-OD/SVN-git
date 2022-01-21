<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="http://chilsoa01d.na.odcorp.net:7778/orabpel/xmllib/merchFndXml/officedepot/merchandising/foundation/v1/message/bod/OrganizationHierarchy.xsd"/>
      <rootElement name="OrganizationHierarchy" namespace="http://www.openapplications.org/officedepot/merchandising/foundation/1"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="APPS_XX_INV_ORG_HIERARCHY_PKG_PROCESS_ORG_HIERARCHY.xsd"/>
      <rootElement name="InputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_INV_ORG_HIERARCHY_PKG/PROCESS_ORG_HIERARCHY/"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.1.0(build 061009.0802) AT [FRI JUN 22 16:12:50 IST 2007]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_INV_ORG_HIERARCHY_PKG/PROCESS_ORG_HIERARCHY/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:ns0="http://www.w3.org/2001/XMLSchema"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:ns1="http://www.openapplications.org/officedepot/merchandising/foundation/1"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                exclude-result-prefixes="xsl ns0 ns1 db xp20 bpws ora ehdr orcl ids hwf">
  <xsl:template match="/">
    <db:InputParameters>
      <P_HIERARCHY_LEVEL>
        <xsl:value-of select="/ns1:OrganizationHierarchy/ns1:DataArea/ns1:HierarchyLevel"/>
      </P_HIERARCHY_LEVEL>
      <P_VALUE>
        <xsl:value-of select="/ns1:OrganizationHierarchy/ns1:DataArea/ns1:HierarchyID"/>
      </P_VALUE>
      <P_DESCRIPTION>
        <xsl:value-of select="/ns1:OrganizationHierarchy/ns1:DataArea/ns1:HierarchyName"/>
      </P_DESCRIPTION>
      <P_ACTION>
        <xsl:value-of select="/ns1:OrganizationHierarchy/ns1:DataArea/ns1:ActionCriteria"/>
      </P_ACTION>
      <P_CHAIN_NUMBER>
        <xsl:value-of select="/ns1:OrganizationHierarchy/ns1:DataArea/ns1:AreaAttributes/ns1:ChainNo"/>
      </P_CHAIN_NUMBER>
      <P_AREA_NUMBER>
        <xsl:value-of select="/ns1:OrganizationHierarchy/ns1:DataArea/ns1:RegionAttributes/ns1:AreaNo"/>
      </P_AREA_NUMBER>
      <P_REGION_NUMBER>
        <xsl:value-of select="/ns1:OrganizationHierarchy/ns1:DataArea/ns1:DistrictAttributes/ns1:RegionNo"/>
      </P_REGION_NUMBER>
    </db:InputParameters>
  </xsl:template>
</xsl:stylesheet>
