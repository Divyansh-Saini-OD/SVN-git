<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="I1186SupplierInvFeed.xsd"/>
      <rootElement name="I1186SupplierInvFeed" namespace="http://xmlns.oracle.com/CustPO"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="http://chilsoa02d.na.odcorp.net:7777/orabpel/xmllib/eaixml/oagis/v91/message/bod/ProcessInventoryBalance.xsd"/>
      <rootElement name="ProcessInventoryBalance" namespace="http://www.openapplications.org/oagis/9"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.1.0(build 061009.0802) AT [TUE JUL 24 23:02:23 EDT 2007]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:ns5="http://www.openapplications.org/oagis/9/unqualifieddatatypes/1.1"
                xmlns:plnk="http://schemas.xmlsoap.org/ws/2003/05/partner-link/"
                xmlns:ns9="http://www.openapplications.org/oagis/9/officedepot/1/codelists"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:ns7="http://www.openapplications.org/oagis/9/currencycode/54217:2001"
                xmlns:ns4="http://www.openapplications.org/oagis/9/qualifieddatatypes/1.1"
                xmlns:ns2="http://www.openapplications.org/oagis/9/IANAMIMEMediaTypes:2003"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:ns0="http://xmlns.oracle.com/CustPO"
                xmlns:ns3="http://www.openapplications.org/oagis/9/codelists"
                xmlns:wsa="http://schemas.xmlsoap.org/ws/2003/03/addressing"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:tns="http://xmlns.oracle.com/SupplierInvFeedProcess"
                xmlns:ns10="http://www.openapplications.org/oagis/9/officedepot/1"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ns1="http://www.openapplications.org/oagis/9"
                xmlns:ns6="http://www.openapplications.org/oagis/9/unitcode/66411:2001"
                xmlns:ns8="http://www.openapplications.org/oagis/9/languagecode/5639:1988"
                exclude-result-prefixes="xsl xs ns0 ns5 ns9 ns7 ns4 ns2 ns3 ns10 ns1 ns6 ns8 bpws ehdr hwf xp20 ora ids orcl">
  <xsl:template match="/">
    <ns1:ProcessInventoryBalance>
      <ns1:DataArea>
        <xsl:for-each select="/ns0:I1186SupplierInvFeed/ns0:SupplierInvFeed/ns0:FeedLines">
          <ns1:InventoryBalance>
            <ns1:Item>
              <ns1:SupplierItemID>
                <ns1:ID>
                  <xsl:value-of select="ns0:VPC_CODE"/>
                </ns1:ID>
              </ns1:SupplierItemID>
            </ns1:Item>
            <ns1:AvailableQuantity>
              <xsl:value-of select="ns0:ON_HAND_QTY"/>
            </ns1:AvailableQuantity>
            <ns1:StorageUOMCode>
              <xsl:value-of select="ns0:UOM"/>
            </ns1:StorageUOMCode>
            <ns1:SupplierParty>
              <ns1:PartyIDs>
                <ns1:ID>
                  <xsl:value-of select="ns0:SUPPLIER_NUMBER"/>
                </ns1:ID>
              </ns1:PartyIDs>
            </ns1:SupplierParty>
          </ns1:InventoryBalance>
        </xsl:for-each>
      </ns1:DataArea>
    </ns1:ProcessInventoryBalance>
  </xsl:template>
</xsl:stylesheet>
