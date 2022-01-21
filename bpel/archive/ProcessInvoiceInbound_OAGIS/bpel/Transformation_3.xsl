<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="http://chilsoa01d.na.odcorp.net:7778/orabpel/xmllib/eaixml/oagis/v91/message/bod/ProcessInvoice.xsd"/>
      <rootElement name="ProcessInvoice" namespace="http://www.openapplications.org/oagis/9"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="../../../../Office%20Depot/BPEL_Projects/ProcessInvoiceInbound_Oagis/bpel/ServiceStgTableInsert_table.xsd"/>
      <rootElement name="XxApInvBatchInterfaceStg2Collection" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/top/ServiceStgTableInsert"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.3.0(build 070615.0525) AT [TUE SEP 25 13:54:49 EDT 2007]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:ns6="http://www.openapplications.org/oagis/9/unqualifieddatatypes/1.1"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:ns9="http://www.openapplications.org/oagis/9/currencycode/54217:2001"
                xmlns:ns5="http://www.openapplications.org/oagis/9/qualifieddatatypes/1.1"
                xmlns:ns2="http://www.openapplications.org/oagis/9/officedepot/1/codelists"
                xmlns:ns3="http://www.openapplications.org/oagis/9/IANAMIMEMediaTypes:2003"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:ns0="http://xmlns.oracle.com/pcbpel/adapter/db/top/ServiceStgTableInsert"
                xmlns:ns4="http://www.openapplications.org/oagis/9/codelists"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:ns8="http://www.openapplications.org/oagis/9/officedepot/1"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ns1="http://www.openapplications.org/oagis/9"
                xmlns:ns7="http://www.openapplications.org/oagis/9/unitcode/66411:2001"
                xmlns:ns10="http://www.openapplications.org/oagis/9/languagecode/5639:1988"
                exclude-result-prefixes="xsl ns6 ns9 ns5 ns2 ns3 xs ns4 ns8 ns1 ns7 ns10 ns0 bpws ehdr hwf xp20 xref ora ids orcl">
  <xsl:template match="/">
    <ns0:XxApInvBatchInterfaceStg2Collection>
      <ns0:XxApInvBatchInterfaceStg2>
        <ns0:batchId>
          <xsl:value-of select='orcl:sequence-next-val("XXFIN.XX_AP_INV_BATCH_INTFC_STG_S","jdbc/bpel_ebs_apps_ds")'/>
        </ns0:batchId>
        <ns0:fileName>
          <xsl:value-of select="normalize-space(/ns1:ProcessInvoice/ns1:DataArea/ns1:Invoice/ns1:InvoiceHeader/ns8:Batch/ns1:FileName)"/>
        </ns0:fileName>
        <ns0:creationDate>
          <xsl:value-of select="normalize-space(/ns1:ProcessInvoice/ns1:DataArea/ns1:Invoice/ns1:InvoiceHeader/ns8:Batch/ns1:CreationDateTime)"/>
        </ns0:creationDate>
        <ns0:creationTime>
          <xsl:value-of select="normalize-space(substring(/ns1:ProcessInvoice/ns1:DataArea/ns1:Invoice/ns1:InvoiceHeader/ns8:Batch/ns1:CreationDateTime,11.0,8.0))"/>
        </ns0:creationTime>
        <ns0:invoiceCount>
          <xsl:value-of select="normalize-space(/ns1:ProcessInvoice/ns1:DataArea/ns1:Invoice/ns1:InvoiceHeader/ns8:Batch/ns8:NumberOfRecords)"/>
        </ns0:invoiceCount>
        <ns0:totalBatchAmount>
          <xsl:value-of select="orcl:right-trim(orcl:left-trim(/ns1:ProcessInvoice/ns1:DataArea/ns1:Invoice/ns1:InvoiceHeader/ns8:Batch/ns1:TotalAmount))"/>
        </ns0:totalBatchAmount>
        <ns0:vendorEmailAddress>
          <xsl:value-of select="normalize-space(/ns1:ProcessInvoice/ns1:DataArea/ns1:Invoice/ns1:InvoiceHeader/ns8:Batch/ns1:Communication/ns1:URI)"/>
        </ns0:vendorEmailAddress>
    <xsl:if test = "(/ns1:ProcessInvoice/ns1:DataArea/ns1:Invoice/ns1:InvoiceHeader/ns1:DocumentReference)">
        <ns0:xxApInvInterfaceStgCollection>
          <xsl:for-each select="/ns1:ProcessInvoice/ns1:DataArea/ns1:Invoice">
            <ns0:XxApInvInterfaceStg2>
              <ns0:invoiceId>
                <xsl:value-of select='orcl:sequence-next-val("AP_INVOICES_INTERFACE_S","jdbc/bpel_ebs_apps_ds")'/>
              </ns0:invoiceId>
              <ns0:invoiceNum>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns1:DocumentReference/ns1:DocumentID/ns1:ID)"/>
              </ns0:invoiceNum>
              <xsl:choose>
                <xsl:when test='substring(ns1:InvoiceHeader/ns1:TotalAmount,1.0,1.0) = "-"'>
                  <ns0:invoiceTypeLookupCode>
                    <xsl:text disable-output-escaping="no">CREDIT</xsl:text>
                  </ns0:invoiceTypeLookupCode>
                </xsl:when>
                <xsl:when test='substring(ns1:InvoiceHeader/ns1:TotalAmount,1.0,1.0) != "-"'>
                  <ns0:invoiceTypeLookupCode>
                    <xsl:text disable-output-escaping="no">STANDARD</xsl:text>
                  </ns0:invoiceTypeLookupCode>
                </xsl:when>
              </xsl:choose>
              <ns0:invoiceDate>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns1:DocumentReference/ns1:DocumentDateTime)"/>
              </ns0:invoiceDate>
              <ns0:poNumber>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns1:PurchaseOrderReference/ns1:DocumentID/ns1:ID)"/>
              </ns0:poNumber>
              <ns0:vendorName>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns1:Party/ns1:Name)"/>
              </ns0:vendorName>
              <ns0:vendorSiteId>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns1:SupplierParty/ns1:Location/ns1:ID)"/>
              </ns0:vendorSiteId>
              <ns0:vendorSiteCode>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns1:SupplierParty/ns1:Location/ns1:Name)"/>
              </ns0:vendorSiteCode>
              <ns0:invoiceAmount>
                <xsl:value-of select="orcl:left-trim(orcl:right-trim(ns1:InvoiceHeader/ns1:TotalAmount))"/>
              </ns0:invoiceAmount>
              <ns0:termsId>
                <xsl:value-of select="orcl:left-trim(orcl:right-trim(ns1:InvoiceHeader/ns1:PaymentTerm/ns1:Term/ns1:ID))"/>
              </ns0:termsId>
              <ns0:termsName>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns1:PaymentTerm/ns1:Term/ns1:Description)"/>
              </ns0:termsName>
              <ns0:description>
                <xsl:value-of select="orcl:left-trim(orcl:right-trim(ns1:InvoiceHeader/ns1:Description))"/>
              </ns0:description>
              <ns0:creationDate>
                <xsl:value-of select="xp20:current-dateTime()"/>
              </ns0:creationDate>
              <ns0:attribute9>
                <xsl:value-of select="orcl:left-trim(orcl:right-trim(ns1:InvoiceHeader/ns8:DocumentControlNumber))"/>
              </ns0:attribute9>
              <ns0:attribute10>
                <xsl:value-of select="orcl:left-trim(orcl:right-trim(ns1:InvoiceHeader/ns1:SupplierParty/ns1:PartyIDs/ns1:ID))"/>
              </ns0:attribute10>
              <ns0:attribute11>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns1:PurchaseOrderReference/ns1:AlternateDocumentID/ns1:ID)"/>
              </ns0:attribute11>
              <ns0:attribute13>
                <xsl:value-of select="ns1:InvoiceHeader/ns8:VoucherReference/ns8:VoucherTypeCode"/>
              </ns0:attribute13>
		  <ns0:attribute15>
			<xsl:value-of select="ns1:InvoiceHeader/ns1:PurchaseOrderReference/ns1:ReleaseNumber"/>
		  </ns0:attribute15>
              <ns0:globalAttribute1>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns8:Settlement/ns1:CreditCard/ns1:Number)"/>
              </ns0:globalAttribute1>
              <xsl:choose>
                <xsl:when test='ns1:InvoiceHeader/ns1:Tax/@type = "NGST"'>
                  <ns0:globalAttribute5>
                    <xsl:text disable-output-escaping="no">N</xsl:text>
                  </ns0:globalAttribute5>
                </xsl:when>
                <xsl:when test='ns1:InvoiceHeader/ns1:Tax/@type = "GST"'>
                  <ns0:globalAttribute5>
                    <xsl:text disable-output-escaping="no">Y</xsl:text>
                  </ns0:globalAttribute5>
                </xsl:when>
              </xsl:choose>
              <ns0:globalAttribute6>
                <xsl:value-of select="orcl:left-trim(orcl:right-trim(ns1:InvoiceHeader/ns8:SpecialProcessingPayCode))"/>
              </ns0:globalAttribute6>
              <ns0:globalAttribute7>
                <xsl:value-of select="orcl:left-trim(orcl:right-trim(ns1:InvoiceHeader/ns8:PaymentPriorityCode))"/>
              </ns0:globalAttribute7>
              <ns0:globalAttribute8>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns1:ReasonCode)"/>
              </ns0:globalAttribute8>
              <ns0:source>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns8:SourceSystemCode)"/>
              </ns0:source>
              <ns0:groupId>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns8:InvoiceGroupID)"/>
              </ns0:groupId>
              <ns0:voucherNum>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns8:VoucherReference/ns1:DocumentID/ns1:ID)"/>
              </ns0:voucherNum>
               <ns0:paymentMethodLookupCode>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns1:PaymentTerm/ns1:Note)"/>
              </ns0:paymentMethodLookupCode>
              <ns0:payGroupLookupCode>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns8:PayGroupID)"/>
              </ns0:payGroupLookupCode>
              <ns0:acctsPayCodeCombinationId>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns1:Facility/ns1:IDs/ns1:ID)"/>
              </ns0:acctsPayCodeCombinationId>
               <ns0:exclusivePaymentFlag>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns1:PaymentTerm/ns1:Term/ns1:PaymentBasisCode)"/>
              </ns0:exclusivePaymentFlag>
             <ns0:termsDate>
                <xsl:value-of select="normalize-space(ns1:InvoiceHeader/ns1:PaymentTerm/ns1:Term/ns1:EffectiveDateTime)"/>
              </ns0:termsDate>
              <ns0:xxApInvLinesInterfaceStgCollection>
                <xsl:for-each select="ns1:InvoiceLine">
                  <ns0:XxApInvLinesInterfaceStg2>
                    <ns0:invoiceLineId>
                      <xsl:value-of select='orcl:sequence-next-val("AP_INVOICE_LINES_INTERFACE_S","jdbc/bpel_ebs_apps_ds")'/>
                    </ns0:invoiceLineId>
                    <ns0:lineNumber>
                      <xsl:value-of select="normalize-space(ns1:LineNumber)"/>
                    </ns0:lineNumber>
                    <ns0:lineTypeLookupCode>
                      <xsl:value-of select="normalize-space(ns1:DocumentReference/ns1:DocumentID)"/>
                    </ns0:lineTypeLookupCode>
                    <ns0:amount>
                      <xsl:value-of select="orcl:left-trim(orcl:right-trim(ns1:TotalAmount))"/>
                    </ns0:amount>
                    <ns0:description>
                      <xsl:value-of select="normalize-space(ns1:Description)"/>
                    </ns0:description>
                    <ns0:taxCode>
                      <xsl:value-of select="normalize-space(ns1:Tax/ns1:TaxJurisdicationCodes/ns1:Code)"/>
                    </ns0:taxCode>
                    <ns0:poNumber>
                      <xsl:value-of select="normalize-space(ns1:PurchaseOrderReference/ns1:DocumentID/ns1:ID)"/>
                    </ns0:poNumber>
                    <ns0:poUnitOfMeasure>
                      <xsl:value-of select="normalize-space(ns1:UnitPrice/ns1:Code)"/>
                    </ns0:poUnitOfMeasure>
                    <ns0:itemDescription>
                      <xsl:value-of select="normalize-space(ns1:Item/ns1:Description)"/>
                    </ns0:itemDescription>
                    <ns0:quantityInvoiced>
                      <xsl:value-of select="normalize-space(ns1:Quantity)"/>
                    </ns0:quantityInvoiced>
                    <ns0:unitPrice>
                      <xsl:value-of select="normalize-space(ns1:UnitPrice/ns1:Amount)"/>
                    </ns0:unitPrice>
                    <ns0:distCodeConcatenated>
                      <xsl:value-of select="ns1:Distribution/ns1:GLNominalAccount"/>
                    </ns0:distCodeConcatenated>
                    <ns0:creationDate>
                      <xsl:value-of select="xp20:current-dateTime()"/>
                    </ns0:creationDate>
                    <ns0:attribute15>
                      <xsl:value-of select="normalize-space(ns8:PANID)"/>
                    </ns0:attribute15>
                    <ns0:globalAttribute1>
                      <xsl:value-of select="normalize-space(ns8:Garnishment/ns8:CaseID)"/>
                    </ns0:globalAttribute1>
                    <ns0:globalAttribute2>
                      <xsl:value-of select="normalize-space(ns8:Garnishment/ns8:NonCustodialParentSSN)"/>
                    </ns0:globalAttribute2>
                    <ns0:globalAttribute3>
                      <xsl:value-of select="normalize-space(ns8:Garnishment/ns8:State)"/>
                    </ns0:globalAttribute3>
                    <ns0:globalAttribute4>
                      <xsl:value-of select="orcl:right-trim(orcl:left-trim(ns8:Garnishment/ns8:MedicalSupportIndicator))"/>
                    </ns0:globalAttribute4>
                    <ns0:globalAttribute5>
                      <xsl:value-of select="orcl:right-trim(orcl:left-trim(ns8:Garnishment/ns8:NonCustodialParentName))"/>
                    </ns0:globalAttribute5>
                    <ns0:globalAttribute6>
                      <xsl:value-of select="orcl:right-trim(orcl:left-trim(ns8:Garnishment/ns8:FIPSCode))"/>
                    </ns0:globalAttribute6>
                    <ns0:globalAttribute7>
                      <xsl:value-of select="orcl:right-trim(orcl:left-trim(ns8:Garnishment/ns8:EmploymentTerminationIndicator))"/>
                    </ns0:globalAttribute7>
                    <ns0:globalAttribute8>
                      <xsl:value-of select="orcl:right-trim(orcl:left-trim(ns8:Garnishment/ns8:TypeCode))"/>
                    </ns0:globalAttribute8>
                    <ns0:globalAttribute13>
                      <xsl:value-of select="ns1:Tax/ns1:Amount"/>
                    </ns0:globalAttribute13>
                    <ns0:globalAttribute18>
                      <xsl:value-of select="orcl:right-trim(orcl:left-trim(ns1:Distribution/ns8:ExpenditureOrganizationCode))"/>
                    </ns0:globalAttribute18>
                    <ns0:globalAttribute19>
                      <xsl:value-of select="orcl:right-trim(orcl:left-trim(ns1:Distribution/ns1:ProjectReference/ns1:ID))"/>
                    </ns0:globalAttribute19>
                    <ns0:globalAttribute20>
                      <xsl:value-of select="orcl:right-trim(orcl:left-trim(ns1:Distribution/ns1:ProjectReference/ns1:ActivityID))"/>
                    </ns0:globalAttribute20>
                    <ns0:releaseNum>
                      <xsl:value-of select="orcl:right-trim(orcl:left-trim(ns1:PurchaseOrderReference/ns1:ReleaseNumber))"/>
                    </ns0:releaseNum>
                    <ns0:expenditureType>
                      <xsl:value-of select="orcl:right-trim(orcl:left-trim(ns1:Distribution/ns8:ExpenditureTypeCode))"/>
                    </ns0:expenditureType>
                    <ns0:invoiceNum>
                      <xsl:value-of select="orcl:right-trim(orcl:left-trim(ns1:DocumentReference/ns1:DocumentID/ns1:ID))"/>
                    </ns0:invoiceNum>
                    <ns0:legacySegment1>
                      <xsl:value-of select='orcl:right-trim(orcl:left-trim(ns1:Distribution/ns1:EnterpriseUnit/ns1:GLAccount/ns1:GLElement/ns1:Element[@sequenceName = "Company"]))'/>
                    </ns0:legacySegment1>
                    <ns0:legacySegment2>
                      <xsl:value-of select='orcl:right-trim(orcl:left-trim(ns1:Distribution/ns1:EnterpriseUnit/ns1:GLAccount/ns1:GLElement/ns1:Element[@sequenceName = "Location"]))'/>
                    </ns0:legacySegment2>
                    <ns0:legacySegment3>
                      <xsl:value-of select='orcl:right-trim(orcl:left-trim(ns1:Distribution/ns1:EnterpriseUnit/ns1:GLAccount/ns1:GLElement/ns1:Element[@sequenceName = "Department"]))'/>
                    </ns0:legacySegment3>
                    <ns0:legacySegment4>
                      <xsl:value-of select='orcl:right-trim(orcl:left-trim(ns1:Distribution/ns1:EnterpriseUnit/ns1:GLAccount/ns1:GLElement/ns1:Element[@sequenceName = "BusinessUnit"]))'/>
                    </ns0:legacySegment4>
                    <ns0:legacySegment5>
                      <xsl:value-of select='orcl:right-trim(orcl:left-trim(ns1:Distribution/ns1:EnterpriseUnit/ns1:GLAccount/ns1:GLElement/ns1:Element[@sequenceName = "Account"]))'/>
                    </ns0:legacySegment5>
                    <ns0:reasonCode>
                      <xsl:value-of select="normalize-space(ns8:InvoiceCharge/ns1:ReasonCode)"/>
                    </ns0:reasonCode>
                    <ns0:oracleGlCompany>
                      <xsl:value-of select='orcl:right-trim(orcl:left-trim(ns1:Distribution/ns1:GLAccount/ns1:GLElement/ns1:Element[@sequenceName = "Company"]))'/>
                    </ns0:oracleGlCompany>
                    <ns0:oracleGlCostCenter>
                      <xsl:value-of select='orcl:right-trim(orcl:left-trim(ns1:Distribution/ns1:GLAccount/ns1:GLElement/ns1:Element[@sequenceName = "CostCenter"]))'/>
                    </ns0:oracleGlCostCenter>
                    <ns0:oracleGlLocation>
                      <xsl:value-of select='orcl:right-trim(orcl:left-trim(ns1:Distribution/ns1:GLAccount/ns1:GLElement/ns1:Element[@sequenceName = "Location"]))'/>
                    </ns0:oracleGlLocation>
                    <ns0:oracleGlAccount>
                      <xsl:value-of select='orcl:right-trim(orcl:left-trim(ns1:Distribution/ns1:GLAccount/ns1:GLElement/ns1:Element[@sequenceName = "Account"]))'/>
                    </ns0:oracleGlAccount>
                    <ns0:oracleGlIntercompany>
                      <xsl:text disable-output-escaping="no">0000</xsl:text>
                    </ns0:oracleGlIntercompany>
                    <ns0:oracleGlLob>
                      <xsl:value-of select='orcl:right-trim(orcl:left-trim(ns1:Distribution/ns1:GLAccount/ns1:GLElement/ns1:Element[@sequenceName = "LineOfBusiness"]))'/>
                    </ns0:oracleGlLob>
                    <ns0:oracleGlFuture1>
                      <xsl:text disable-output-escaping="no">000000</xsl:text>
                    </ns0:oracleGlFuture1>
                  </ns0:XxApInvLinesInterfaceStg2>
                </xsl:for-each>
              </ns0:xxApInvLinesInterfaceStgCollection>
            </ns0:XxApInvInterfaceStg2>
          </xsl:for-each>
        </ns0:xxApInvInterfaceStgCollection>
       </xsl:if >
      </ns0:XxApInvBatchInterfaceStg2>
    </ns0:XxApInvBatchInterfaceStg2Collection>
  </xsl:template>
</xsl:stylesheet>
