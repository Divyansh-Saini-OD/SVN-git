<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="RMS10_OD_BPEL_FND_SQL_GETORGHIERMESSAGE.xsd"/>
      <rootElement name="OutputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/RMS10/OD_BPEL_FND_SQL/GETORGHIERMESSAGE/"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="http://chilsoa01d.na.odcorp.net:7778/orabpel/xmllib/merchFndXml/officedepot/merchandising/foundation/v1/message/bod/OrganizationHierarchy.xsd"/>
      <rootElement name="OrganizationHierarchy" namespace="http://www.openapplications.org/officedepot/merchandising/foundation/1"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.1.0(build 061009.0802) AT [MON JUN 25 16:40:47 EDT 2007]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:ns0="http://www.w3.org/2001/XMLSchema"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:ns1="http://www.openapplications.org/officedepot/merchandising/foundation/1"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/RMS10/OD_BPEL_FND_SQL/GETORGHIERMESSAGE/"
                exclude-result-prefixes="xsl ns0 db ns1 xp20 bpws ora ehdr orcl ids hwf">
  <xsl:template match="/">
    <ns1:OrganizationHierarchy>
          <ns1:ApplicationArea>
        <ns1:MessageType>
          <xsl:value-of select="concat('OrgHier','_rms_outb')"/>
        </ns1:MessageType>
        <ns1:Sender>
          <xsl:value-of select="concat('BPEL-','ProcessManager')"/>
        </ns1:Sender>
        <ns1:CreationDateTime>
          <xsl:value-of select="xp20:current-dateTime()"/>
        </ns1:CreationDateTime>
      </ns1:ApplicationArea>
      <ns1:DataArea>
        <ns1:HierarchyLevel>
          <xsl:value-of select="/db:OutputParameters/O_HIERARCHY"/>
        </ns1:HierarchyLevel>
        <ns1:HierarchyID>
          <xsl:value-of select="/db:OutputParameters/O_HIER_ID"/>
        </ns1:HierarchyID>
        <ns1:HierarchyName>
          <xsl:value-of select="/db:OutputParameters/O_HIER_NAME"/>
        </ns1:HierarchyName>
        <ns1:ActionCriteria>
          <xsl:value-of select="/db:OutputParameters/O_CHANGE_CD"/>
        </ns1:ActionCriteria>
        <ns1:ChaninAttributes>
          <ns1:ManagerName>
            <xsl:value-of select="/db:OutputParameters/O_CHAIN_MGR"/>
          </ns1:ManagerName>
        </ns1:ChaninAttributes>
      </ns1:DataArea>
    </ns1:OrganizationHierarchy>
  </xsl:template>
</xsl:stylesheet>
