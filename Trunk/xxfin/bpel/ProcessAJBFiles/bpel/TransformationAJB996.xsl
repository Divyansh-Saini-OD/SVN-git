<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="AJB996_4.xsd"/>
      <rootElement name="Root-Element_AJB996" namespace="http://TargetNamespace.com/InboundService_AJB996"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="AJB996TableInsert_table.xsd"/>
      <rootElement name="XxCeAjb996Collection" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/top/AJB996TableInsert"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.1.0(build 061009.0802) AT [SAT MAY 23 15:26:22 IST 2009]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:nxsd="http://xmlns.oracle.com/pcbpel/nxsd"
                xmlns:tns="http://TargetNamespace.com/InboundService_AJB996"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ns0="http://xmlns.oracle.com/pcbpel/adapter/db/top/AJB996TableInsert"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                exclude-result-prefixes="xsl xsd nxsd tns ns0 bpws ehdr hwf xp20 ora ids orcl">
  <xsl:param name="AJB_File_Name"/>
  <xsl:template match="/">
    <ns0:XxCeAjb996Collection>
      <xsl:for-each select="/tns:Root-Element_AJB996/tns:AJB996">
        <ns0:XxCeAjb996>
          <ns0:recordType>
            <xsl:value-of select="normalize-space(tns:RecordType)"/>
          </ns0:recordType>
          <ns0:vsetFile>
            <xsl:value-of select="normalize-space(tns:VSetFile)"/>
          </ns0:vsetFile>
          <xsl:if test="string-length(normalize-space(tns:SDate)) != 0.0">
            <ns0:sdate>
              <xsl:call-template name="formatDatesdate">
                <xsl:with-param name="date"
                                select="normalize-space(tns:SDate)"/>
              </xsl:call-template>
            </ns0:sdate>
          </xsl:if>
          <ns0:actionCode>
            <xsl:value-of select="normalize-space(tns:ActionCode)"/>
          </ns0:actionCode>
          <ns0:attribute1>
            <xsl:value-of select="normalize-space(tns:Reserved1)"/>
          </ns0:attribute1>
          <ns0:providerType>
            <xsl:value-of select="normalize-space(tns:ProviderType)"/>
          </ns0:providerType>
          <ns0:attribute2>
            <xsl:value-of select="normalize-space(tns:Reserved2)"/>
          </ns0:attribute2>
          <ns0:storeNum>
            <xsl:value-of select="normalize-space(tns:StoreNumber)"/>
          </ns0:storeNum>
          <xsl:if test="string-length(normalize-space(tns:TerminalNumber)) != 0.0">
            <ns0:terminalNum>
              <xsl:value-of select="normalize-space(tns:TerminalNumber)"/>
            </ns0:terminalNum>
          </xsl:if>
          <ns0:trxType>
            <xsl:value-of select="normalize-space(tns:AdjustmentType)"/>
          </ns0:trxType>
          <ns0:attribute3>
            <xsl:value-of select="normalize-space(tns:Reserved3)"/>
          </ns0:attribute3>
          <ns0:attribute4>
            <xsl:value-of select="normalize-space(tns:Reserved4)"/>
          </ns0:attribute4>
          <ns0:cardNum>
            <xsl:value-of select="normalize-space(tns:CardNumber)"/>
          </ns0:cardNum>
          <ns0:attribute5>
            <xsl:value-of select="normalize-space(tns:Reserved5)"/>
          </ns0:attribute5>
          <ns0:attribute6>
            <xsl:value-of select="normalize-space(tns:Reserved6)"/>
          </ns0:attribute6>
          <xsl:if test='xp20:upper-case(normalize-space(tns:AdjustmentType)) = "REFUND"'>
            <xsl:if test="string-length(normalize-space(tns:TrxAmount)) != 0.0">
              <ns0:trxAmount>
                <xsl:value-of select="normalize-space(tns:TrxAmount) div 100.0 * -(1.0)"/>
              </ns0:trxAmount>
            </xsl:if>
          </xsl:if>
          
          <xsl:if test='xp20:upper-case(normalize-space(tns:AdjustmentType)) = "SALE"'>
            <xsl:if test="string-length(normalize-space(tns:TrxAmount)) != 0.0">
              <ns0:trxAmount>
                <xsl:value-of select="normalize-space(tns:TrxAmount) div 100.0"/>
              </ns0:trxAmount>
            </xsl:if>
          </xsl:if>
          <ns0:invoiceNum>
            <xsl:value-of select="normalize-space(tns:InvoiceNumber)"/>
          </ns0:invoiceNum>
          <ns0:countryCode>
            <xsl:value-of select="normalize-space(tns:CountryCode)"/>
          </ns0:countryCode>
          <ns0:currencyCode>
            <xsl:value-of select="normalize-space(tns:CurrencyCode)"/>
          </ns0:currencyCode>
          <ns0:attribute7>
            <xsl:value-of select="normalize-space(tns:Reserved7)"/>
          </ns0:attribute7>
          <ns0:attribute8>
            <xsl:value-of select="normalize-space(tns:Reserved8)"/>
          </ns0:attribute8>
          <ns0:attribute9>
            <xsl:value-of select="normalize-space(tns:Reserved9)"/>
          </ns0:attribute9>
          <ns0:attribute10>
            <xsl:value-of select="normalize-space(tns:Reserved10)"/>
          </ns0:attribute10>
          <ns0:attribute11>
            <xsl:value-of select="normalize-space(tns:Reserved11)"/>
          </ns0:attribute11>
          <ns0:attribute12>
            <xsl:value-of select="normalize-space(tns:Reserved12)"/>
          </ns0:attribute12>
          <ns0:attribute13>
            <xsl:value-of select="normalize-space(tns:Reserved13)"/>
          </ns0:attribute13>
          <ns0:attribute14>
            <xsl:value-of select="normalize-space(tns:Reserved14)"/>
          </ns0:attribute14>
          <ns0:attribute15>
            <xsl:value-of select="normalize-space(tns:Reserved15)"/>
          </ns0:attribute15>
          <ns0:attribute16>
            <xsl:value-of select="normalize-space(tns:Reserved16)"/>
          </ns0:attribute16>
          <ns0:attribute17>
            <xsl:value-of select="normalize-space(tns:Reserved17)"/>
          </ns0:attribute17>
          <ns0:attribute18>
            <xsl:value-of select="normalize-space(tns:Reserved18)"/>
          </ns0:attribute18>
          <ns0:attribute19>
            <xsl:value-of select="normalize-space(tns:Reserved19)"/>
          </ns0:attribute19>
          <ns0:attribute20>
            <xsl:value-of select="normalize-space(tns:Reserved20)"/>
          </ns0:attribute20>
          <ns0:receiptNum>
            <xsl:value-of select="normalize-space(tns:ReceiptNumber)"/>
          </ns0:receiptNum>
          <ns0:attribute21>
            <xsl:value-of select="normalize-space(tns:Reserved21)"/>
          </ns0:attribute21>
          <ns0:attribute22>
            <xsl:value-of select="normalize-space(tns:Reserved22)"/>
          </ns0:attribute22>
          <ns0:authNum>
            <xsl:value-of select="normalize-space(tns:AuthorizationNumber)"/>
          </ns0:authNum>
          <ns0:attribute23>
            <xsl:value-of select="normalize-space(tns:Reserved23)"/>
          </ns0:attribute23>
          <ns0:attribute24>
            <xsl:value-of select="normalize-space(tns:Reserved24)"/>
          </ns0:attribute24>
          <ns0:attribute25>
            <xsl:value-of select="normalize-space(tns:Reserved25)"/>
          </ns0:attribute25>
          <ns0:attribute26>
            <xsl:value-of select="normalize-space(tns:Reserved26)"/>
          </ns0:attribute26>
          <ns0:attribute27>
            <xsl:value-of select="normalize-space(tns:Reserved27)"/>
          </ns0:attribute27>
          <ns0:attribute28>
            <xsl:value-of select="normalize-space(tns:Reserved28)"/>
          </ns0:attribute28>
          <ns0:attribute29>
            <xsl:value-of select="normalize-space(tns:Reserved29)"/>
          </ns0:attribute29>
          <ns0:attribute30>
            <xsl:value-of select="normalize-space(tns:Reserved30)"/>
          </ns0:attribute30>
          <ns0:bankRecId>
            <xsl:value-of select="normalize-space(tns:BankRecId)"/>
          </ns0:bankRecId>
          <ns0:attribute31>
            <xsl:value-of select="normalize-space(tns:Reserved31)"/>
          </ns0:attribute31>
          <ns0:attribute32>
            <xsl:value-of select="normalize-space(tns:Reserved32)"/>
          </ns0:attribute32>
          <ns0:trxDate>
            <xsl:call-template name="formatDate">
              <xsl:with-param name="date"
                              select="normalize-space(tns:TrxDate)"/>
            </xsl:call-template>
          </ns0:trxDate>
          <ns0:attribute33>
            <xsl:value-of select="normalize-space(tns:Reserved33)"/>
          </ns0:attribute33>
          <ns0:attribute34>
            <xsl:value-of select="normalize-space(tns:Reserved34)"/>
          </ns0:attribute34>
          <ns0:attribute35>
            <xsl:value-of select="normalize-space(tns:Reserved35)"/>
          </ns0:attribute35>
          <ns0:processorId>
            <xsl:value-of select="normalize-space(tns:ProcessorID)"/>
          </ns0:processorId>
          <xsl:if test="string-length(normalize-space(tns:FeeAmount)) != 0.0">
            <ns0:masterNoauthFee>
              <xsl:value-of select="normalize-space(tns:FeeAmount) div 100.0"/>
            </ns0:masterNoauthFee>
          </xsl:if>
          <xsl:if test="string-length(normalize-space(tns:ChargebackRate)) != 0.0">
            <ns0:chbkRate>
              <xsl:value-of select="normalize-space(tns:ChargebackRate) div 100000.0"/>
            </ns0:chbkRate>
          </xsl:if>
          <xsl:if test="string-length(normalize-space(tns:ChargebackAmount)) != 0.0">
            <ns0:chbkAmt>
              <xsl:value-of select="normalize-space(tns:ChargebackAmount) div 100.0"/>
            </ns0:chbkAmt>
          </xsl:if>
          <ns0:chbkActionCode>
            <xsl:value-of select="normalize-space(tns:ChargebackActionCode)"/>
          </ns0:chbkActionCode>
          <ns0:chbkActionDate>
            <xsl:value-of select="normalize-space(tns:ChargebackActionCodeDate)"/>
          </ns0:chbkActionDate>
          <ns0:chbkRefNum>
            <xsl:value-of select="normalize-space(tns:ChargebackReferenceNumber)"/>
          </ns0:chbkRefNum>
          <xsl:if test="string-length(normalize-space(tns:RetrievalReferenceNumber)) != 0.0">
            <ns0:retRefNum>
              <xsl:value-of select="normalize-space(tns:RetrievalReferenceNumber)"/>
            </ns0:retRefNum>
          </xsl:if>
          <xsl:if test="string-length(normalize-space(tns:OtherRate1)) != 0.0">
            <ns0:otherRate1>
              <xsl:value-of select="normalize-space(tns:OtherRate1) div 100000.0"/>
            </ns0:otherRate1>
          </xsl:if>
          <xsl:if test="string-length(normalize-space(tns:OtherRate2)) != 0.0">
            <ns0:otherRate2>
              <xsl:value-of select="normalize-space(tns:OtherRate2) div 100000.0"/>
            </ns0:otherRate2>
          </xsl:if>
          <ns0:creationDate>
            <xsl:value-of select="xp20:current-dateTime()"/>
          </ns0:creationDate>
          <ns0:createdBy>
            <xsl:text disable-output-escaping="no">3</xsl:text>
          </ns0:createdBy>
          <ns0:lastUpdateDate>
            <xsl:value-of select="xp20:current-dateTime()"/>
          </ns0:lastUpdateDate>
          <ns0:lastUpdatedBy>
            <xsl:text disable-output-escaping="no">3</xsl:text>
          </ns0:lastUpdatedBy>
          <ns0:chbkAlphaCode>
            <xsl:value-of select="normalize-space(tns:CHBK_ALPHA_CODE)"/>
          </ns0:chbkAlphaCode>
          <xsl:if test="string-length(normalize-space(tns:CHBK_NUMERIC_CODE)) != 0.0">
            <ns0:chbkNumericCode>
              <xsl:value-of select="normalize-space(tns:CHBK_NUMERIC_CODE)"/>
            </ns0:chbkNumericCode>
          </xsl:if>
          <ns0:sequenceId996>
            <xsl:value-of select='orcl:sequence-next-val("XXFIN.xx_ce_ajb996_s","jdbc/bpel_ebs_apps_ds")'/>
          </ns0:sequenceId996>
          <ns0:ipayBatchNum>
            <xsl:value-of select="normalize-space(tns:iPayBatchNum)"/>
          </ns0:ipayBatchNum>
          <ns0:ajbFileName>
            <xsl:value-of select="$AJB_File_Name"/>
          </ns0:ajbFileName>
        </ns0:XxCeAjb996>
      </xsl:for-each>
    </ns0:XxCeAjb996Collection>
  </xsl:template>
   
  <!--  User Defined Templates  -->
   
  <xsl:template name="formatDate">
    <xsl:param name="date"/>
    <xsl:if test="normalize-space($date) > '0'">
      <xsl:variable name="MM" select="substring($date, 1, 2)"/>
      <xsl:variable name="dd" select="substring($date, 3, 2)"/>
      <xsl:variable name="yyyy" select="substring($date, 5, 4)"/>
      <xsl:variable name="newDate" select="concat($yyyy, '-', $MM, '-', $dd, 'T00:00:00.000Z')"/>
      <xsl:value-of select="$newDate"/>
    </xsl:if>
  </xsl:template>
   
  <xsl:template name="formatDatesdate">
    <xsl:param name="date"/>
    <xsl:if test="normalize-space($date) > '0'">
      <xsl:variable name="yyyy" select="substring($date, 1, 4)"/>
      <xsl:variable name="mm" select="substring($date, 5, 2)"/>
      <xsl:variable name="dd" select="substring($date, 7, 2)"/>
      <xsl:variable name="newDate" select="concat($yyyy, '-', $mm, '-', $dd, 'T00:00:00.000Z')"/>
      <xsl:value-of select="$newDate"/>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
