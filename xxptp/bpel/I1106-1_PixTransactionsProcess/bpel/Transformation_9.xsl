<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="I1106_Dequeueing_Msg_Structure.xsd"/>
      <rootElement name="Root-Element" namespace="http://TargetNamespace.com/plDQPixTransactionProcess"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="pl1106DisabledErrorLogger_table.xsd"/>
      <rootElement name="XxGiPixtransactionsCollection" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/top/pl1106DisabledErrorLogger"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.1.0(build 061009.0802) AT [THU FEB 28 13:05:24 EST 2008]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:ns0="http://xmlns.oracle.com/pcbpel/adapter/db/top/Disabled1106ErrorLogger"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:ns1="http://xmlns.oracle.com/pcbpel/adapter/db/top/pl1106DisabledErrorLogger"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:nxsd="http://xmlns.oracle.com/pcbpel/nxsd"
                xmlns:extn="http://xmlns.oracle.com/pcbpel/nxsd/extensions"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:tns="http://TargetNamespace.com/plDQPixTransactionProcess"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                exclude-result-prefixes="xsl xsd nxsd extn tns ns1 bpws ehdr hwf xp20 ora ids orcl">
  <xsl:template match="/">
    <ns1:XxGiPixtransactionsCollection>
      <ns1:XxGiPixtransactions>
        <ns1:fromLocId>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-KEY/tns:GIMQTRN-LOC-ID"/>
        </ns1:fromLocId>
        <ns1:docNbr>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-KEY/tns:GIMQTRN-DOC-NBR"/>
        </ns1:docNbr>
        <ns1:keyrec>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-KEY/tns:GIMQTRN-KEYREC"/>
        </ns1:keyrec>
        <ns1:seq>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-KEY/tns:GIMQTRN-SEQ"/>
        </ns1:seq>
        <ns1:originCd>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ORIGIN-CD"/>
        </ns1:originCd>
        <ns1:tranCode>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-TRAN-CODE"/>
        </ns1:tranCode>
        <ns1:reasonCd>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-REASON-CD"/>
        </ns1:reasonCd>
        <ns1:subCode>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-SUB-CODE"/>
        </ns1:subCode>
        <ns1:activityDt>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ACTIVITY-DT"/>
        </ns1:activityDt>
        <ns1:activityTm>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ACTIVITY-TM"/>
        </ns1:activityTm>
        <ns1:userIdEntBy>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-USER-ID-ENT-BY"/>
        </ns1:userIdEntBy>
        <ns1:toLocId>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-TO-LOC-ID"/>
        </ns1:toLocId>
        <ns1:vendorId>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-VENDOR-ID"/>
        </ns1:vendorId>
        <ns1:targetTranTypeCd>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-TARGET-TRAN-TYPE-CD"/>
        </ns1:targetTranTypeCd>
        <ns1:sourceCd>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-SOURCE-CD"/>
        </ns1:sourceCd>
        <ns1:adjComments>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ADJ-HEADER/tns:GIMQTRN-ADJ-COMMENTS"/>
        </ns1:adjComments>
        <ns1:adjTypeCd>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ADJ-HEADER/tns:GIMQTRN-ADJ-TYPE-CD"/>
        </ns1:adjTypeCd>
        <ns1:adjStatusCd>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ADJ-HEADER/tns:GIMQTRN-ADJ-STATUS-CD"/>
        </ns1:adjStatusCd>
        <ns1:adjRefExpAdjNbr>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ADJ-HEADER/tns:GIMQTRN-ADJ-REF-EXP-ADJ-NBR"/>
        </ns1:adjRefExpAdjNbr>
        <ns1:adjGlLoc>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ADJ-HEADER/tns:GIMQTRN-ADJ-GL-LOC"/>
        </ns1:adjGlLoc>
        <ns1:adjCostCenter>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ADJ-HEADER/tns:GIMQTRN-ADJ-COST-CENTER"/>
        </ns1:adjCostCenter>
        <ns1:adjRefData>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ADJ-HEADER/tns:GIMQTRN-ADJ-REF-DATA"/>
        </ns1:adjRefData>
        <ns1:adjAdjNbr>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ADJ-HEADER/tns:GIMQTRN-ADJ-ADJ-NBR"/>
        </ns1:adjAdjNbr>
        <ns1:strComments>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-STR-HEADER/tns:GIMQTRN-STR-COMMENTS"/>
        </ns1:strComments>
        <ns1:strCartonCnt>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-STR-HEADER/tns:GIMQTRN-STR-CARTON-CNT"/>
        </ns1:strCartonCnt>
        <ns1:strStatusCd>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-STR-HEADER/tns:GIMQTRN-STR-STATUS-CD"/>
        </ns1:strStatusCd>
        <ns1:strStdPackQty>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-STR-HEADER/tns:GIMQTRN-STR-STD-PACK-QTY"/>
        </ns1:strStdPackQty>
        <ns1:strBuybackNbr>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-STR-HEADER/tns:GIMQTRN-STR-BUYBACK-NBR"/>
        </ns1:strBuybackNbr>
        <ns1:strTotalCost>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-STR-HEADER/tns:GIMQTRN-STR-TOTAL-COST"/>
        </ns1:strTotalCost>
        <ns1:strShipDate>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-STR-HEADER/tns:GIMQTRN-STR-SHIP-DATE"/>
        </ns1:strShipDate>
        <ns1:rcvDispositionCd>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RCV-HEADER/tns:GIMQTRN-RCV-DISPOSITION-CD"/>
        </ns1:rcvDispositionCd>
        <ns1:rcvCartonCnt>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RCV-HEADER/tns:GIMQTRN-RCV-CARTON-CNT"/>
        </ns1:rcvCartonCnt>
        <ns1:rcvFreightCd>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RCV-HEADER/tns:GIMQTRN-RCV-FREIGHT-CD"/>
        </ns1:rcvFreightCd>
        <ns1:rcvFobCd>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RCV-HEADER/tns:GIMQTRN-RCV-FOB-CD"/>
        </ns1:rcvFobCd>
        <ns1:rcvFreightBillNbr>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RCV-HEADER/tns:GIMQTRN-RCV-FREIGHT-BILL-NBR"/>
        </ns1:rcvFreightBillNbr>
        <ns1:rcvCarrierId>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RCV-HEADER/tns:GIMQTRN-RCV-CARRIER-ID"/>
        </ns1:rcvCarrierId>
        <ns1:rtvRgaNbr>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RTV-HEADER/tns:GIMQTRN-RTV-RGA-NBR"/>
        </ns1:rtvRgaNbr>
        <ns1:rtvBuybackNbr>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RTV-HEADER/tns:GIMQTRN-RTV-BUYBACK-NBR"/>
        </ns1:rtvBuybackNbr>
        <ns1:rtvComments>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RTV-HEADER/tns:GIMQTRN-RTV-COMMENTS"/>
        </ns1:rtvComments>
        <ns1:rtvStatusCd>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RTV-HEADER/tns:GIMQTRN-RTV-STATUS-CD"/>
        </ns1:rtvStatusCd>
        <ns1:serialNbr>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-SERIAL-NBR"/>
        </ns1:serialNbr>
        <ns1:ucc128LicPlate>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-UCC-128-LIC-PLATE"/>
        </ns1:ucc128LicPlate>
        <ns1:licensePlate>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-LICENSE-PLATE"/>
        </ns1:licensePlate>
        <ns1:currencyCd>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-CURRENCY-CD"/>
        </ns1:currencyCd>
        <ns1:convRate>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-CONV-RATE"/>
        </ns1:convRate>
        <ns1:nbrLines>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-NBR-LINES"/>
        </ns1:nbrLines>
        <ns1:filler>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-FILLER"/>
        </ns1:filler>
        <ns1:sku>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GICMQPUT-DETAIL-ARRAY/tns:GIMQTRN-SKU"/>
        </ns1:sku>
        <ns1:transactionQty>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GICMQPUT-DETAIL-ARRAY/tns:GIMQTRN-TRANSACTION-QTY"/>
        </ns1:transactionQty>
        <ns1:adjustedQty>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GICMQPUT-DETAIL-ARRAY/tns:GIMQTRN-ADJUSTED-QTY"/>
        </ns1:adjustedQty>
        <ns1:cost>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GICMQPUT-DETAIL-ARRAY/tns:GIMQTRN-COST"/>
        </ns1:cost>
        <ns1:uom>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GICMQPUT-DETAIL-ARRAY/tns:GIMQTRN-UOM"/>
        </ns1:uom>
        <ns1:actCd>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GICMQPUT-DETAIL-ARRAY/tns:GIMQTRN-ACT-CD"/>
        </ns1:actCd>
        <ns1:tblFiller>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GICMQPUT-DETAIL-ARRAY/tns:GIMQTRN-TBL-FILLER"/>
        </ns1:tblFiller>
        <ns1:errorMessage>
          <xsl:value-of select='string("Disabled Transaction Type")'/>
        </ns1:errorMessage>
        <ns1:errorCode>
          <xsl:value-of select='string("DISABLED_TRANSACTION_TYPE")'/>
        </ns1:errorCode>
        <ns1:createdBy>
          <xsl:value-of select="number(-(1.0))"/>
        </ns1:createdBy>
        <ns1:creationDate>
          <xsl:value-of select="xp20:current-dateTime()"/>
        </ns1:creationDate>
        <ns1:lastUpdatedBy>
          <xsl:value-of select="number(-(1.0))"/>
        </ns1:lastUpdatedBy>
        <ns1:lastUpdateDate>
          <xsl:value-of select="xp20:current-dateTime()"/>
        </ns1:lastUpdateDate>
        <ns1:lastUpdateLogin>
          <xsl:value-of select="number(-(1.0))"/>
        </ns1:lastUpdateLogin>
      </ns1:XxGiPixtransactions>
    </ns1:XxGiPixtransactionsCollection>
  </xsl:template>
</xsl:stylesheet>
