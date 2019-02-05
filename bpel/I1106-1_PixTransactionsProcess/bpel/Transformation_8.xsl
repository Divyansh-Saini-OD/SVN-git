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
      <schema location="APPS_BPEL_PLPOPULATERCVXFRSTAGEPROC_XX_GI_RECEIVING_PKG-24POPULATE__1204048940062.xsd"/>
      <rootElement name="InputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/BPEL_PLPOPULATERCVXFRSTAGEPROC/XX_GI_RECEIVING_PKG-24POPULATE_/"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.1.0(build 061009.0802) AT [THU FEB 28 14:51:18 EST 2008]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/BPEL_PLPOPULATERCVXFRSTAGEPROC/XX_GI_RECEIVING_PKG-24POPULATE_/"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:nxsd="http://xmlns.oracle.com/pcbpel/nxsd"
                xmlns:extn="http://xmlns.oracle.com/pcbpel/nxsd/extensions"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:tns="http://TargetNamespace.com/plDQPixTransactionProcess"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                exclude-result-prefixes="xsl xsd nxsd extn tns db bpws ehdr hwf xp20 ora ids orcl">
  <xsl:template match="/">
    <db:InputParameters>
      <X_KEYREC_REC>
        <KEYREC_NBR>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-KEY/tns:GIMQTRN-KEYREC"/>
        </KEYREC_NBR>
        <LOC_NBR>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-KEY/tns:GIMQTRN-LOC-ID"/>
        </LOC_NBR>
        <TYPE_CD>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ORIGIN-CD"/>
        </TYPE_CD>
        <CARTON_CNT>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RCV-HEADER/tns:GIMQTRN-RCV-CARTON-CNT"/>
        </CARTON_CNT>
        <COMMENTS>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ADJ-HEADER/tns:GIMQTRN-ADJ-COMMENTS"/>
        </COMMENTS>
        <FREIGHT_CD>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RCV-HEADER/tns:GIMQTRN-RCV-FREIGHT-CD"/>
        </FREIGHT_CD>
        <FOB_CD>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RCV-HEADER/tns:GIMQTRN-RCV-FOB-CD"/>
        </FOB_CD>
        <FREIGHT_BILL_NBR>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RCV-HEADER/tns:GIMQTRN-RCV-FREIGHT-BILL-NBR"/>
        </FREIGHT_BILL_NBR>
        <CARRIER_NBR>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-RCV-HEADER/tns:GIMQTRN-RCV-CARRIER-ID"/>
        </CARRIER_NBR>
      </X_KEYREC_REC>
      <X_HEADER_REC>
        <EXPECTED_RECEIPT_DATE>
          <xsl:value-of select="xp20:current-dateTime()"/>
        </EXPECTED_RECEIPT_DATE>
        <CURRENCY_CODE>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-CURRENCY-CD"/>
        </CURRENCY_CODE>
        <CONVERSION_RATE>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-CONV-RATE"/>
        </CONVERSION_RATE>
        <ATTRIBUTE1>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-KEY/tns:GIMQTRN-LOC-ID"/>
        </ATTRIBUTE1>
        <ATTRIBUTE2>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-TO-LOC-ID"/>
        </ATTRIBUTE2>
        <ATTRIBUTE4>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-TARGET-TRAN-TYPE-CD"/>
        </ATTRIBUTE4>
        <ATTRIBUTE5>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-KEY/tns:GIMQTRN-DOC-NBR"/>
        </ATTRIBUTE5>
        <ATTRIBUTE6>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-USER-ID-ENT-BY"/>
        </ATTRIBUTE6>
        <ATTRIBUTE7>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ACTIVITY-DT"/>
        </ATTRIBUTE7>
      </X_HEADER_REC>
      <X_DETAIL_TBL>
        <xsl:for-each select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GICMQPUT-DETAIL-ARRAY">
          <X_DETAIL_TBL_ITEM>
            <TRANSACTION_DATE>
              <xsl:value-of select="../tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ACTIVITY-DT"/>
            </TRANSACTION_DATE>
            <QUANTITY>
              <xsl:value-of select="tns:GIMQTRN-ADJUSTED-QTY"/>
            </QUANTITY>
            <EXPECTED_RECEIPT_DATE>
              <xsl:value-of select="xp20:current-dateTime()"/>
            </EXPECTED_RECEIPT_DATE>
            <ATTRIBUTE4>
              <xsl:value-of select="../tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-TARGET-TRAN-TYPE-CD"/>
            </ATTRIBUTE4>
            <ATTRIBUTE6>
              <xsl:value-of select="../tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-USER-ID-ENT-BY"/>
            </ATTRIBUTE6>
            <ITEM_NUM>
              <xsl:value-of select="tns:GIMQTRN-SKU + 0.0"/>
            </ITEM_NUM>
            <DOCUMENT_NUM>
              <xsl:value-of select="../tns:GIMQTRN-FILE-KEY/tns:GIMQTRN-DOC-NBR"/>
            </DOCUMENT_NUM>
          </X_DETAIL_TBL_ITEM>
        </xsl:for-each>
      </X_DETAIL_TBL>
    </db:InputParameters>
  </xsl:template>
</xsl:stylesheet>
