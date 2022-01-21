<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="http://chilsoa01d.na.odcorp.net:7778/orabpel/default/ODTransactionLogger/TransactionData.xsd"/>
      <rootElement name="TransactionData" namespace="http://xmlns.oracle.com/TransactionData"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="http://chilsoa01d.na.odcorp.net:7778/orabpel/default/ODTransactionLogger/TransactionData.xsd"/>
      <rootElement name="TransactionData" namespace="http://xmlns.oracle.com/TransactionData"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.1.0(build 061009.0802) AT [THU JUL 10 16:59:11 IST 2008]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:ns0="http://xmlns.oracle.com/TransactionData"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                exclude-result-prefixes="xsl ns0 xsd xp20 bpws ora ehdr orcl ids hwf">
  <xsl:param name="FileSize"/>
  <xsl:template match="/">
    <ns0:TransactionData>
      <ns0:ProcessInfo>
        <ns0:Domain>
          <xsl:value-of select="/ns0:TransactionData/ns0:ProcessInfo/ns0:Domain"/>
        </ns0:Domain>
        <ns0:ProcessName>
          <xsl:value-of select="/ns0:TransactionData/ns0:ProcessInfo/ns0:ProcessName"/>
        </ns0:ProcessName>
        <ns0:InstanceId>
          <xsl:value-of select="/ns0:TransactionData/ns0:ProcessInfo/ns0:InstanceId"/>
        </ns0:InstanceId>
        <ns0:SystemName>
          <xsl:value-of select="/ns0:TransactionData/ns0:ProcessInfo/ns0:SystemName"/>
        </ns0:SystemName>
        <ns0:TradingPartnerDetails>
          <ns0:TPFrom>
            <xsl:value-of select="/ns0:TransactionData/ns0:ProcessInfo/ns0:TradingPartnerDetails/ns0:TPFrom"/>
          </ns0:TPFrom>
          <ns0:TPTo>
            <xsl:value-of select="/ns0:TransactionData/ns0:ProcessInfo/ns0:TradingPartnerDetails/ns0:TPTo"/>
          </ns0:TPTo>
          <ns0:TPDocTypeName>
            <xsl:value-of select="/ns0:TransactionData/ns0:ProcessInfo/ns0:TradingPartnerDetails/ns0:TPDocTypeName"/>
          </ns0:TPDocTypeName>
          <ns0:TPDocTypeRevision>
            <xsl:value-of select="/ns0:TransactionData/ns0:ProcessInfo/ns0:TradingPartnerDetails/ns0:TPDocTypeRevision"/>
          </ns0:TPDocTypeRevision>
        </ns0:TradingPartnerDetails>
        <ns0:ProcessStatus>
          <xsl:value-of select="/ns0:TransactionData/ns0:ProcessInfo/ns0:ProcessStatus"/>
        </ns0:ProcessStatus>
      </ns0:ProcessInfo>
      <ns0:EntiltyList>
        <xsl:for-each select="/ns0:TransactionData/ns0:EntiltyList/ns0:EntityID">
	  <xsl:if test='(@EntityType= "File")'>
          <ns0:EntityID>
            <xsl:attribute name="EntityType">
		<xsl:text disable-output-escaping="no">File</xsl:text>
            </xsl:attribute>
                    <xsl:value-of select="."/>
          </ns0:EntityID>
        </xsl:if>
        <xsl:if test='(@EntityType= "Batch")'>
          <ns0:EntityID>
            <xsl:attribute name="EntityType">
		<xsl:text disable-output-escaping="no">Batch</xsl:text>
            </xsl:attribute>
                    <xsl:value-of select="."/>
          </ns0:EntityID>
        </xsl:if>
        </xsl:for-each>
          <ns0:EntityID>
            <xsl:attribute name="EntityType">
		<xsl:text disable-output-escaping="no">FileSize</xsl:text>
            </xsl:attribute>
             <xsl:value-of select="$FileSize"/>
          </ns0:EntityID>
      </ns0:EntiltyList>
      <ns0:AttributeList>
        <xsl:for-each select="/ns0:TransactionData/ns0:AttributeList/ns0:AttributeValue">
          <ns0:AttributeValue>
            <xsl:attribute name="AttributeName">
              <xsl:value-of select="@AttributeName"/>
            </xsl:attribute>
            <xsl:value-of select="."/>
          </ns0:AttributeValue>
        </xsl:for-each>
      </ns0:AttributeList>
      <ns0:MessageDetails>
        <ns0:MessageId>
          <xsl:value-of select="/ns0:TransactionData/ns0:MessageDetails/ns0:MessageId"/>
        </ns0:MessageId>
        <ns0:MessageDateTime>
          <xsl:value-of select="/ns0:TransactionData/ns0:MessageDetails/ns0:MessageDateTime"/>
        </ns0:MessageDateTime>
        <ns0:MessageType>
          <xsl:value-of select="/ns0:TransactionData/ns0:MessageDetails/ns0:MessageType"/>
        </ns0:MessageType>
        <ns0:MessageVersion>
          <xsl:value-of select="/ns0:TransactionData/ns0:MessageDetails/ns0:MessageVersion"/>
        </ns0:MessageVersion>
        <ns0:MessageOperation>
          <xsl:value-of select="/ns0:TransactionData/ns0:MessageDetails/ns0:MessageOperation"/>
        </ns0:MessageOperation>
        <ns0:MessageSourceSystem>
          <xsl:value-of select="/ns0:TransactionData/ns0:MessageDetails/ns0:MessageSourceSystem"/>
        </ns0:MessageSourceSystem>
        <ns0:MessageSourceSystemComponent>
          <xsl:value-of select="/ns0:TransactionData/ns0:MessageDetails/ns0:MessageSourceSystemComponent"/>
        </ns0:MessageSourceSystemComponent>
        <ns0:MessageData>
          <xsl:value-of select="/ns0:TransactionData/ns0:MessageDetails/ns0:MessageData"/>
        </ns0:MessageData>
      </ns0:MessageDetails>
    </ns0:TransactionData>
  </xsl:template>
</xsl:stylesheet>
