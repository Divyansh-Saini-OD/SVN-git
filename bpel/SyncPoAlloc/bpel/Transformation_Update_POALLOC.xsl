<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="APPS_XX_PO_ALLOCATION_T.xsd"/>
      <rootElement name="XX_PO_ALLOCATION_T" namespace="http://xmlns.oracle.com/xdb/APPS"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="POALLOC_table.xsd"/>
      <rootElement name="PoallocCollection" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/top/POALLOC"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.1.0(build 061009.0802) AT [THU JUN 21 13:07:01 EDT 2007]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:APPS="http://xmlns.oracle.com/xdb/APPS"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:ns0="http://www.w3.org/2001/XMLSchema"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:ns1="http://xmlns.oracle.com/pcbpel/adapter/db/top/POALLOC"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                exclude-result-prefixes="xsl APPS ns0 ns1 xp20 bpws ora ehdr orcl ids hwf">
  <xsl:template match="/">
    <ns1:PoallocCollection>
      <ns1:Poalloc>
        <ns1:poNbr>
          <xsl:value-of select="/APPS:XX_PO_ALLOCATION_T/PO"/>
        </ns1:poNbr>
        <ns1:locId>
          <xsl:value-of select="/APPS:XX_PO_ALLOCATION_T/SHIP_TO"/>
        </ns1:locId>
        <ns1:sku>
          <xsl:value-of select="/APPS:XX_PO_ALLOCATION_T/SKU"/>
        </ns1:sku>
        <ns1:allocLocId>
          <xsl:value-of select="/APPS:XX_PO_ALLOCATION_T/ALLOC_LOC"/>
        </ns1:allocLocId>
        <ns1:unitsAlloc>
          <xsl:value-of select="/APPS:XX_PO_ALLOCATION_T/QTY"/>
        </ns1:unitsAlloc>
        <ns1:manOverrideFlg>
          <xsl:value-of select="/APPS:XX_PO_ALLOCATION_T/LOCKED_ID"/>
        </ns1:manOverrideFlg>
        <ns1:userIdChgBy>
          <xsl:text disable-output-escaping="no">BPEL</xsl:text>
        </ns1:userIdChgBy>
        <ns1:dtChg>
          <xsl:value-of select="xp20:current-date()"/>
        </ns1:dtChg>
        <ns1:tmChg>
          <xsl:value-of select="xp20:current-dateTime()"/>
        </ns1:tmChg>
        <ns1:pgmChg>
          <xsl:text disable-output-escaping="no">BPEL</xsl:text>
        </ns1:pgmChg>
      </ns1:Poalloc>
    </ns1:PoallocCollection>
  </xsl:template>
</xsl:stylesheet>
