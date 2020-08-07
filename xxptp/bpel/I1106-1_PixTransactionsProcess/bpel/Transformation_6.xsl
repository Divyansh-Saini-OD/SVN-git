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
      <schema location="APPS_BPEL_PLINVENTORYTRANSFERPROCES_XX_GI_TRANSFER_PKG-24CREATE_MAI_1203967289093.xsd"/>
      <rootElement name="InputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/BPEL_PLINVENTORYTRANSFERPROCES/XX_GI_TRANSFER_PKG-24CREATE_MAI/"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.1.0(build 061009.0802) AT [MON FEB 25 17:35:07 EST 2008]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:nxsd="http://xmlns.oracle.com/pcbpel/nxsd"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/BPEL_PLINVENTORYTRANSFERPROCES/XX_GI_TRANSFER_PKG-24CREATE_MAI/"
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
      <P_IN_HDR_REC>
        <SOURCE_SYSTEM>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-SOURCE-CD"/>
        </SOURCE_SYSTEM>
        <TRANSFER_NUMBER>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-KEY/tns:GIMQTRN-DOC-NBR"/>
        </TRANSFER_NUMBER>
        <FROM_LOC_NBR>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-KEY/tns:GIMQTRN-LOC-ID"/>
        </FROM_LOC_NBR>
        <TO_LOC_NBR>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-TO-LOC-ID"/>
        </TO_LOC_NBR>
        <TRANS_TYPE_CD>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-TRAN-CODE"/>
        </TRANS_TYPE_CD>
        <DOC_TYPE_CD>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ORIGIN-CD"/>
        </DOC_TYPE_CD>
        <SOURCE_CREATION_DATE>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-ACTIVITY-DT"/>
        </SOURCE_CREATION_DATE>
        <SOURCE_CREATED_BY>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-USER-ID-ENT-BY"/>
        </SOURCE_CREATED_BY>
        <BUYBACK_NUMBER>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-STR-HEADER/tns:GIMQTRN-STR-BUYBACK-NBR"/>
        </BUYBACK_NUMBER>
        <CARTON_COUNT>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-STR-HEADER/tns:GIMQTRN-STR-CARTON-CNT"/>
        </CARTON_COUNT>
        <TRANSFER_COST>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-STR-HEADER/tns:GIMQTRN-STR-TOTAL-COST"/>
        </TRANSFER_COST>
        <SHIP_DATE>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-STR-HEADER/tns:GIMQTRN-STR-SHIP-DATE"/>
        </SHIP_DATE>
        <COMMENTS>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-STR-HEADER/tns:GIMQTRN-STR-COMMENTS"/>
        </COMMENTS>
        <SOURCE_SUBINV_CD>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-TARGET-TRAN-TYPE-CD"/>
        </SOURCE_SUBINV_CD>
        <SOURCE_VENDOR_ID>
          <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GIMQTRN-FILE-HEADER/tns:GIMQTRN-VENDOR-ID"/>
        </SOURCE_VENDOR_ID>
      </P_IN_HDR_REC>
      <P_IN_LINE_TBL>
        <P_IN_LINE_TBL_ITEM>
          <ITEM>
            <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GICMQPUT-DETAIL-ARRAY/tns:GIMQTRN-SKU"/>
          </ITEM>
          <SHIPPED_QTY>
            <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GICMQPUT-DETAIL-ARRAY/tns:GIMQTRN-TRANSACTION-QTY"/>
          </SHIPPED_QTY>
          <REQUESTED_QTY>
            <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GICMQPUT-DETAIL-ARRAY/tns:GIMQTRN-ADJUSTED-QTY"/>
          </REQUESTED_QTY>
          <FROM_LOC_UOM>
            <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GICMQPUT-DETAIL-ARRAY/tns:GIMQTRN-UOM"/>
          </FROM_LOC_UOM>
          <FROM_LOC_UNIT_COST>
            <xsl:value-of select="/tns:Root-Element/tns:GIMQTRN-RECORD/tns:GICMQPUT-DETAIL-ARRAY/tns:GIMQTRN-COST"/>
          </FROM_LOC_UNIT_COST>
        </P_IN_LINE_TBL_ITEM>
      </P_IN_LINE_TBL>
    </db:InputParameters>
  </xsl:template>
</xsl:stylesheet>
