<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="Retailease.xsd"/>
      <rootElement name="RetailLeases" namespace="http://TargetNamespace.com/FTPRetailLease"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="http://chilsoa01d.na.odcorp.net:7778/orabpel/xmllib/eaixml/oagis/v91/message/bod/ProcessInvoice.xsd"/>
      <rootElement name="ProcessInvoice" namespace="http://www.openapplications.org/oagis/9"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.1.0(build 061009.0802) AT [WED JUL 18 09:54:31 EDT 2007]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:ns5="http://www.openapplications.org/oagis/9/unqualifieddatatypes/1.1"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:ns8="http://www.openapplications.org/oagis/9/currencycode/54217:2001"
                xmlns:ns4="http://www.openapplications.org/oagis/9/qualifieddatatypes/1.1"
                xmlns:ns1="http://www.openapplications.org/oagis/9/officedepot/1/codelists"
                xmlns:ns2="http://www.openapplications.org/oagis/9/IANAMIMEMediaTypes:2003"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:ns3="http://www.openapplications.org/oagis/9/codelists"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:nxsd="http://xmlns.oracle.com/pcbpel/nxsd"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bt="http://www.oracle.com/XSL/Transform/java/oracle.bt.CustomExtensionFunctions"
                xmlns:ns7="http://www.openapplications.org/oagis/9/officedepot/1"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ns0="http://www.openapplications.org/oagis/9"
                xmlns:ns6="http://www.openapplications.org/oagis/9/unitcode/66411:2001"
                xmlns:ns9="http://www.openapplications.org/oagis/9/languagecode/5639:1988"
                xmlns:tns="http://TargetNamespace.com/FTPRetailLease"
                exclude-result-prefixes="xsl xsd nxsd tns ns5 ns8 ns4 ns1 ns2 ns3 ns7 ns0 ns6 ns9 bpws ehdr hwf xp20 bt ora ids orcl">
  <xsl:template match="/">
    <ns0:ProcessInvoice>
      <xsl:attribute name="releaseID">
        <xsl:text disable-output-escaping="no">1.0</xsl:text>
      </xsl:attribute>
      <ns0:DataArea>
        <xsl:for-each select="normalize-space(/tns:RetailLeases/tns:Retailease)">
          <ns0:Invoice>
            <ns0:InvoiceHeader>
              <ns0:Description>
                <xsl:value-of select="normalize-space(tns:ReferenceNo)"/>
              </ns0:Description>
              <ns0:DocumentReference>
                <ns0:DocumentID>
                  <ns0:ID>
                    <xsl:value-of select="normalize-space(tns:PaymentID)"/>
                  </ns0:ID>
                </ns0:DocumentID>
                <ns0:DocumentDateTime>
                    <xsl:call-template name="formatDate">
                        <xsl:with-param name="date" select="normalize-space(tns:PostDate)"/>
                    </xsl:call-template>                  
                </ns0:DocumentDateTime>
              </ns0:DocumentReference>
              <xsl:comment/>
              <ns0:SupplierParty>
                <ns0:PartyIDs>
                  <ns0:ID>
                    <xsl:value-of select="normalize-space(tns:VendorNo)"/>
                  </ns0:ID>
                </ns0:PartyIDs>              
                <ns0:Location>
                  <ns0:Name>
                    <xsl:value-of select="normalize-space(tns:Lease)"/>
                  </ns0:Name>
                </ns0:Location>
              </ns0:SupplierParty>
              <ns7:SourceSystemCode>
                 <xsl:value-of select="'US_OD_RENT'"/>
              </ns7:SourceSystemCode>               
              <ns0:PaymentTerm>
                <ns0:Term>
                  <ns0:Description>
                    <xsl:text disable-output-escaping="no">00</xsl:text>
                  </ns0:Description>
                </ns0:Term>
              </ns0:PaymentTerm>
              <ns7:Batch>
                 <ns0:FileName>
                    <xsl:value-of select="AP_EXPENSE_NA_RETAILEASE"/>
                  </ns0:FileName>
                <ns0:CreationDateTime>
                  <xsl:value-of select="xp20:current-date()"/>
                </ns0:CreationDateTime>
                  <ns0:Communication>
                    <ns0:URI>
                    <xsl:value-of select="support@accruent.com"/>
                  </ns0:URI>
                </ns0:Communication>
              </ns7:Batch>
           </ns0:InvoiceHeader>
            <ns0:InvoiceLine>
              <ns0:Item>
                <ns0:Description>
                  <xsl:value-of select="normalize-space(tns:ReferenceNo)"/>
                </ns0:Description>
              </ns0:Item>
              <ns0:Tax>
                <ns0:TaxJurisdicationCodes>
                  <ns0:Code>
                    <xsl:value-of select="normalize-space(tns:Tax1)"/>
                  </ns0:Code>
                </ns0:TaxJurisdicationCodes>
                <ns0:Amount>
                  <xsl:value-of select="normalize-space(tns:Tax1Amount)"/>
                </ns0:Amount>
              </ns0:Tax>
             <ns0:Distribution>
              </ns0:Distribution>
            </ns0:InvoiceLine>
          </ns0:Invoice>
        </xsl:for-each>
      </ns0:DataArea>
    </ns0:ProcessInvoice>
  </xsl:template>
   
  <!--  User Defined Templates  -->
   
    <xsl:template name="formatDate">
        <xsl:param name="date"/>
        <xsl:variable name="currDateTime" select="xp20:current-dateTime()"/>
        <xsl:if test="normalize-space($date) &gt; '0'">
            <xsl:variable name="mm" select="substring($date, 1, 2)"/>
            <xsl:variable name="dd" select="substring($date, 4, 2)"/>
            <xsl:variable name="yyyy" select="substring($date, 7, 4)"/>
            <xsl:variable name="newDate" select="concat($yyyy,'-', $mm, '-', $dd)"/>
            <xsl:value-of select="concat($newDate, substring($currDateTime, 11))"/>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>
