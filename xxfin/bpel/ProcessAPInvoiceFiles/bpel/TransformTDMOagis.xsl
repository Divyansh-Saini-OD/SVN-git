<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="TDM.xsd"/>
      <rootElement name="container" namespace="http://TargetNamespace.com/ProcessInvoiceInbound_TDM"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="http://esbdev01.na.odcorp.net/orabpel/xmllib/eaixml/oagis/v91/message/bod/ProcessInvoice.xsd"/>
      <rootElement name="ProcessInvoice" namespace="http://www.openapplications.org/oagis/9"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.3.0(build 070615.0525) AT [WED JUN 11 14:43:59 IST 2008]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:ns5="http://www.openapplications.org/oagis/9/unqualifieddatatypes/1.1"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:ns8="http://www.openapplications.org/oagis/9/currencycode/54217:2001"
                xmlns:ns4="http://www.openapplications.org/oagis/9/qualifieddatatypes/1.1"
                xmlns:ns1="http://www.openapplications.org/oagis/9/officedepot/1/codelists"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:ns2="http://www.openapplications.org/oagis/9/IANAMIMEMediaTypes:2003"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:tns="http://TargetNamespace.com/ProcessInvoiceInbound_TDM"
                xmlns:ns3="http://www.openapplications.org/oagis/9/codelists"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:nxsd="http://xmlns.oracle.com/pcbpel/nxsd"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:ns7="http://www.openapplications.org/oagis/9/officedepot/1"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ns0="http://www.openapplications.org/oagis/9"
                xmlns:ns6="http://www.openapplications.org/oagis/9/unitcode/66411:2001"
                xmlns:ns9="http://www.openapplications.org/oagis/9/languagecode/5639:1988"
                exclude-result-prefixes="xsl xsd tns nxsd ns5 ns8 ns4 ns1 ns2 ns3 ns7 ns0 ns6 ns9 bpws ehdr hwf xp20 xref ora ids orcl">
 <xsl:param name="Batch_Id"/>
  <xsl:template match="/">
    <ns0:ProcessInvoice>
   <ns0:DataArea>
   <xsl:if test = "not(/tns:container/tns:InvoiceHeader)">
     <ns0:Invoice>
      <ns0:InvoiceHeader>
              <ns0:DocumentReference>
                <ns0:DocumentID>
                  <ns0:ID>
                    <xsl:text disable-output-escaping="no">NULL</xsl:text>
                  </ns0:ID>
                </ns0:DocumentID>
                </ns0:DocumentReference>
           <ns7:Batch>
                 <ns7:FileName>
                    <xsl:value-of select="normalize-space(/tns:container/tns:Trailer/tns:FileName)"/>
                  </ns7:FileName>
                    <ns7:Name>
                     <xsl:value-of select="$Batch_Id"/>
                  </ns7:Name>
                    <ns0:CreationDateTime>                   
                      <xsl:call-template name="formatDateTime">
                        <xsl:with-param name="datetime"
                        select="concat(normalize-space(/tns:container/tns:Trailer/tns:CreationDate),normalize-space(/tns:container/tns:Trailer/tns:CreationTime))"/>
                    </xsl:call-template>                       
                    </ns0:CreationDateTime>
               <ns7:NumberOfRecords>
                  <xsl:value-of select="/tns:container/tns:Trailer/tns:TotalRecords"/>
                </ns7:NumberOfRecords>
                <ns0:TotalAmount>
                  <xsl:value-of select="/tns:container/tns:Trailer/tns:TotalAmount"/>
                </ns0:TotalAmount>
                <ns7:Communication>
                  <ns7:URI>
                    <xsl:value-of select="/tns:container/tns:Trailer/tns:Email_Address"/>
                  </ns7:URI>
                </ns7:Communication>
             </ns7:Batch>
      </ns0:InvoiceHeader>                
     </ns0:Invoice>
    </xsl:if>
    <xsl:for-each select="/tns:container/tns:InvoiceHeader">
        <ns0:Invoice>
             <ns0:InvoiceHeader>
              <ns0:Description>
                <xsl:value-of select="normalize-space(tns:CheckDescription)"/>
              </ns0:Description>
              <ns0:DocumentReference>
                <ns0:DocumentID>
                  <ns0:ID>
                    <xsl:value-of select="normalize-space(tns:InvoiceNumber)"/>
                  </ns0:ID>
                </ns0:DocumentID>
                <ns0:DocumentDateTime>
                 <xsl:call-template name="formatDate">
                   <xsl:with-param name="date" select="normalize-space(tns:InvoiceDate)"/>
                 </xsl:call-template>
              </ns0:DocumentDateTime>
              </ns0:DocumentReference>
              <ns0:TotalAmount>
                <xsl:value-of select="normalize-space(tns:GrossAmount)"/>
              </ns0:TotalAmount>
              <ns0:SupplierParty>
                <ns0:PartyIDs>
                  <ns0:ID>
                    <xsl:value-of select="normalize-space(tns:ODGlobalVendorID)"/>
                  </ns0:ID>
                </ns0:PartyIDs>
              </ns0:SupplierParty>
              <ns0:PurchaseOrderReference>
                <ns0:DocumentID>
                  <ns0:ID>
                    <xsl:value-of select="normalize-space(tns:DefaultPO)"/>
                  </ns0:ID>
                </ns0:DocumentID>
                <ns0:ReleaseNumber>
                  <xsl:value-of select="normalize-space(tns:Release_Number)"/>
                 </ns0:ReleaseNumber>
              </ns0:PurchaseOrderReference>
              <ns7:PayGroupID>
                <xsl:value-of select="normalize-space(tns:Paygroup)"/>
              </ns7:PayGroupID>
              <ns7:InvoiceGroupID>
                <xsl:value-of select="normalize-space(tns:GroupID)"/>
              </ns7:InvoiceGroupID>
              <ns7:DocumentControlNumber>
                <xsl:value-of select="normalize-space(tns:DCN)"/>
              </ns7:DocumentControlNumber>
          <xsl:choose>
          <xsl:when test="contains(tns:Paygroup,'CLEARING') and (tns:VendorSource = 'US_OD_TDM')">
              <ns0:PaymentTerm>
                <ns0:Note>
                  <xsl:text disable-output-escaping="no">CLEARING</xsl:text>
                </ns0:Note>                
                <ns0:Term>
                  <ns0:Description>
                    <xsl:text disable-output-escaping="no">00</xsl:text>
                  </ns0:Description>
                  <ns0:PaymentBasisCode>
                    <xsl:text disable-output-escaping="no">Y</xsl:text>
                  </ns0:PaymentBasisCode>
                   <ns0:EffectiveDateTime>
                     <xsl:call-template name="formatDate">
                       <xsl:with-param name="date" select="(tns:DueDate)"/>
                     </xsl:call-template>
                  </ns0:EffectiveDateTime>
                </ns0:Term>
              </ns0:PaymentTerm>
          </xsl:when>
          <xsl:otherwise>
              <ns0:PaymentTerm>
                <ns0:Term>
                  <ns0:Description>
                    <xsl:value-of select="normalize-space(tns:TermsName)"/>
                  </ns0:Description>
                  <ns0:PaymentBasisCode>
                    <xsl:value-of select="normalize-space(tns:PayAloneFlag)"/>
                  </ns0:PaymentBasisCode>
                   <ns0:EffectiveDateTime>
                     <xsl:call-template name="formatDate">
                       <xsl:with-param name="date" select="(tns:DueDate)"/>
                     </xsl:call-template>
                  </ns0:EffectiveDateTime>
                </ns0:Term>
              </ns0:PaymentTerm>
          </xsl:otherwise>
          </xsl:choose>
              <ns7:SourceSystemCode>
                <xsl:value-of select="normalize-space(tns:VendorSource)"/>
              </ns7:SourceSystemCode>
              <ns7:Batch>
                 <ns7:FileName>
                    <xsl:value-of select="normalize-space(../tns:Trailer/tns:FileName)"/>
                  </ns7:FileName>
                    <ns7:Name>
                      <xsl:value-of select="$Batch_Id"/>
                  </ns7:Name>
                <ns0:CreationDateTime>                   
                      <xsl:call-template name="formatDateTime">
                        <xsl:with-param name="datetime"
                        select="concat(normalize-space(../tns:Trailer/tns:CreationDate),normalize-space(../tns:Trailer/tns:CreationTime))"/>
                    </xsl:call-template>                       
                </ns0:CreationDateTime>
               <ns7:NumberOfRecords>
                  <xsl:value-of select="../tns:Trailer/tns:TotalRecords"/>
                </ns7:NumberOfRecords>
                <ns0:TotalAmount>
                  <xsl:value-of select="../tns:Trailer/tns:TotalAmount"/>
                </ns0:TotalAmount>
                <ns7:Communication>
                  <ns7:URI>
                    <xsl:value-of select="../tns:Trailer/tns:Email_Address"/>
                  </ns7:URI>
                </ns7:Communication>
              </ns7:Batch>
              <ns0:InvoiceGroupID>
                    <xsl:value-of select="tns:GroupID"/>
              </ns0:InvoiceGroupID>
              <ns0:PurchaseOrderReference>
                  <ns0:AlternateDocumentID>
                        <xsl:attribute name="agencyRole">
                             <xsl:text disable-output-escaping="no">LegacyPONumber</xsl:text>
                          </xsl:attribute>
                          <ns0:ID>
                           <xsl:value-of select="tns:LegacyPONumber"/>
                         </ns0:ID>
                  </ns0:AlternateDocumentID>
              </ns0:PurchaseOrderReference>
            </ns0:InvoiceHeader>
          <xsl:for-each select="tns:Lines/tns:Line-Invoice">
            <ns0:InvoiceLine>
              <ns0:Description>
                <xsl:value-of select="normalize-space(tns:LineDescription)"/>
              </ns0:Description>
              <ns0:LineNumber>
                <xsl:value-of select="normalize-space(tns:InvoiceDistributionLineNumber)"/>
              </ns0:LineNumber>
              <ns0:Tax>
                 <ns0:TaxJurisdicationCodes>
                    <ns0:Code>
                      <xsl:value-of select="normalize-space(tns:TaxCode)"/>
                    </ns0:Code>
                 </ns0:TaxJurisdicationCodes>
               </ns0:Tax>
              <ns0:DocumentReference>
              <ns0:DocumentID>
                <xsl:value-of select="normalize-space(tns:InvoiceDistributionLineType)"/>
              </ns0:DocumentID>
              </ns0:DocumentReference>
               <ns0:PurchaseOrderReference>
                <ns0:ReleaseNumber>
                  <xsl:value-of select="/tns:container/tns:InvoiceHeader/tns:Release_Number"/>
                 </ns0:ReleaseNumber>
              </ns0:PurchaseOrderReference>
              <xsl:choose>
                  <xsl:when test='normalize-space(tns:InvoiceDistributionLineType) = "ITEM"'>
                    <ns0:TotalAmount>
                      <xsl:value-of select="normalize-space(tns:MDSEAmount)"/>
                    </ns0:TotalAmount>
                  </xsl:when>
                  <xsl:when test='normalize-space(tns:InvoiceDistributionLineType) = "TAX"'>
                    <ns0:TotalAmount>
                      <xsl:value-of select="normalize-space(tns:TaxAmount)"/>
                    </ns0:TotalAmount>
                  </xsl:when>
                 <xsl:when test='normalize-space(tns:InvoiceDistributionLineType) = "FREIGHT"'>
                    <ns0:TotalAmount>
                      <xsl:value-of select="normalize-space(tns:FreightAmount)"/>
                    </ns0:TotalAmount>
                  </xsl:when>
             </xsl:choose>
             <ns0:Distribution>
                <ns0:GLNominalAccount>
                  <xsl:value-of 
select="concat(normalize-space(tns:GLCompany),'.',
               normalize-space(tns:GLCostCenter),'.',
               normalize-space(tns:GLAccount),'.',
               normalize-space(tns:GLLocation),'.',
               '0000','.',
               normalize-space(tns:GLLineofBusiness),'.',
               '000000')"/>
                </ns0:GLNominalAccount>
                <ns7:ExpenditureTypeCode>
                  <xsl:value-of select="normalize-space(tns:ExpenditureType)"/>
                </ns7:ExpenditureTypeCode>
                <ns7:ExpenditureOrganizationCode>
                  <xsl:value-of select="normalize-space(tns:ExpenditureORGID)"/>
                </ns7:ExpenditureOrganizationCode>
                 <ns0:ProjectReference>
                  <ns0:ID>
                    <xsl:value-of select="normalize-space(tns:OracleProjectNumber)"/>
                  </ns0:ID>
                  <ns0:ActivityID>
                    <xsl:value-of select="normalize-space(tns:TaskNumber)"/>
                  </ns0:ActivityID>
                </ns0:ProjectReference>
                <ns0:GLAccount>
                      <ns0:GLElement>
                        <ns0:Element>
                          <xsl:attribute name="sequenceName">
                             <xsl:text disable-output-escaping="no">Company</xsl:text>
                          </xsl:attribute>
                          <xsl:value-of select="normalize-space(tns:GLCompany)"/>
                        </ns0:Element>
                        <ns0:Element>
                          <xsl:attribute name="sequenceName">
                            <xsl:text disable-output-escaping="no">CostCenter</xsl:text>
                          </xsl:attribute>
                          <xsl:value-of select="normalize-space(tns:GLCostCenter)"/>
                        </ns0:Element>
                        <ns0:Element>
                          <xsl:attribute name="sequenceName">
                             <xsl:text disable-output-escaping="no">Location</xsl:text>
                          </xsl:attribute>
                          <xsl:value-of select="normalize-space(tns:GLLocation)"/>
                        </ns0:Element>
                        <ns0:Element>
                          <xsl:attribute name="sequenceName">
                             <xsl:text disable-output-escaping="no">Account</xsl:text>
                          </xsl:attribute>
                          <xsl:value-of select="normalize-space(tns:GLAccount)"/>
                        </ns0:Element>
                      <ns0:Element>
                          <xsl:attribute name="sequenceName">
                             <xsl:text disable-output-escaping="no">LineOfBusiness</xsl:text>
                          </xsl:attribute>
                          <xsl:value-of select="normalize-space(tns:GLLineofBusiness)"/>
                        </ns0:Element>
                         </ns0:GLElement>
                     </ns0:GLAccount>
                 </ns0:Distribution>
            </ns0:InvoiceLine>
          </xsl:for-each>
        </ns0:Invoice>
      </xsl:for-each>
      </ns0:DataArea>
    </ns0:ProcessInvoice>
  </xsl:template>
    <!--  User Defined Templates  -->
   
  <xsl:template name="formatDate">
    <xsl:param name="date"/>
    <xsl:if test="normalize-space($date) > '0'">
      <xsl:variable name="yy" select="substring($date, 1, 2)"/>
      <xsl:variable name="mm" select="substring($date, 3, 2)"/>
      <xsl:variable name="dd" select="substring($date, 5, 2)"/>
      <xsl:variable name="newDate" select="concat('20',$yy,'-', $mm, '-', $dd  )"/>
      <xsl:value-of select="$newDate"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="formatDateTime">
    <xsl:param name="datetime"/>
    <xsl:if test="normalize-space($datetime) > '0'">
      <xsl:variable name="yy" select="substring($datetime, 1, 2)"/>
      <xsl:variable name="mm" select="substring($datetime, 3, 2)"/>
      <xsl:variable name="dd" select="substring($datetime, 5, 2)"/>
      <xsl:variable name="hh" select="substring($datetime, 7, 2)"/>
      <xsl:variable name="mi" select="substring($datetime, 10, 2)"/>
      <xsl:variable name="ss" select="substring($datetime, 13, 2)"/>
      <xsl:variable name="newDateTime" select="concat('20', $yy, '-', $mm, '-', $dd,$hh,':',$mi,':',$ss )"/>
      <xsl:value-of select="$newDateTime"/>
    </xsl:if>
  </xsl:template>  
</xsl:stylesheet>
