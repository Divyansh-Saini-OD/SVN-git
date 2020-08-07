<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="SrCreate.xsd"/>
      <rootElement name="Root-Element" namespace="http://TargetNamespace.com/InboundService"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="APPS_XX_CS_TDS_SR_PKG_CREATE_SERVICEREQUEST.xsd"/>
      <rootElement name="InputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_TDS_SR_PKG/CREATE_SERVICEREQUEST/"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.3.0(build 070615.0525) AT [TUE AUG 21 11:46:42 EDT 2012]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_TDS_SR_PKG/CREATE_SERVICEREQUEST/"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:extn="http://xmlns.oracle.com/pcbpel/nxsd/extensions"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:nxsd="http://xmlns.oracle.com/pcbpel/nxsd"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:tns="http://TargetNamespace.com/InboundService"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                exclude-result-prefixes="xsl extn nxsd xsd tns db xp20 bpws orcl hwf ids xref ora ehdr">
  <xsl:template match="/">
    <db:InputParameters>
      <xsl:for-each select="/tns:Root-Element/tns:SERVICE_MQ">
        <db:P_SR_REQ_REC>
          <db:REQUEST_NUMBER>
            <xsl:value-of select="tns:request_number"/>
          </db:REQUEST_NUMBER>
          <db:CUSTOMER_ID>
            <xsl:value-of select="tns:customer_ref"/>
          </db:CUSTOMER_ID>
          <db:USER_ID>
            <xsl:value-of select="tns:employee_id"/>
          </db:USER_ID>
          <db:CONTACT_ID>
            <xsl:value-of select="tns:contact_id"/>
          </db:CONTACT_ID>
          <db:CONTACT_NAME>
            <xsl:value-of select="tns:contact_name"/>
          </db:CONTACT_NAME>
          <db:CONTACT_PHONE>
            <xsl:value-of select="tns:contact_phone"/>
          </db:CONTACT_PHONE>
          <db:CONTACT_EMAIL>
            <xsl:value-of select="tns:contact_email"/>
          </db:CONTACT_EMAIL>
          <db:CONTACT_FAX>
            <xsl:value-of select="tns:contact_fax"/>
          </db:CONTACT_FAX>
          <db:COMMENTS>
            <xsl:value-of select='concat(orcl:right-trim(substring(tns:comments,"1","30")),orcl:right-trim(substring(tns:comments,"31","60")),orcl:right-trim(substring(tns:comments,"61","90")))'/>
          </db:COMMENTS>
          <db:ORDER_NUMBER>
            <xsl:value-of select="tns:order_number"/>
          </db:ORDER_NUMBER>
          <db:SHIP_TO>
            <xsl:value-of select="tns:Ship_to_ref"/>
          </db:SHIP_TO>
          <db:LOCATION_ID>
            <xsl:value-of select="tns:store_number"/>
          </db:LOCATION_ID>
          <db:DEV_QUES_ANS_ID>
            <xsl:value-of select="tns:dev_ques_ans_id"/>
          </db:DEV_QUES_ANS_ID>
          <db:ATTRIBUTE1>
            <xsl:value-of select="tns:order_date"/>
          </db:ATTRIBUTE1>
          <db:ATTRIBUTE2>
            <xsl:value-of select="tns:action_code"/>
          </db:ATTRIBUTE2>
        </db:P_SR_REQ_REC>
      </xsl:for-each>
      <db:P_ORDER_TBL>
        <xsl:for-each select="/tns:Root-Element/tns:SERVICE_MQ/tns:SKU_record">
          <xsl:choose>
            <xsl:when test="string-length(tns:Sku) > 0.0">
              <db:P_ORDER_TBL_ITEM>
                <db:ORDER_SUB>
                  <xsl:value-of select="tns:document_number"/>
                </db:ORDER_SUB>
                <db:SKU_ID>
                  <xsl:value-of select="tns:Sku"/>
                </db:SKU_ID>
                <db:QUANTITY>
                  <xsl:value-of select="tns:Sku_quantity"/>
                </db:QUANTITY>
                <db:ORDER_LINK>
                  <xsl:value-of select="tns:Sku_parent_Sku"/>
                </db:ORDER_LINK>
                <db:ATTRIBUTE1>
                  <xsl:value-of select="tns:Sku_vendor"/>
                </db:ATTRIBUTE1>
                <db:ATTRIBUTE2>
                  <xsl:value-of select="tns:Sku_catagory"/>
                </db:ATTRIBUTE2>
                <db:ATTRIBUTE3>
                  <xsl:value-of select="tns:Sku_parent_cat"/>
                </db:ATTRIBUTE3>
                <db:ATTRIBUTE4>
                  <xsl:value-of select="tns:start_date"/>
                </db:ATTRIBUTE4>
                <db:ATTRIBUTE5>
                  <xsl:value-of select="tns:end_date"/>
                </db:ATTRIBUTE5>
              </db:P_ORDER_TBL_ITEM>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </db:P_ORDER_TBL>
    </db:InputParameters>
  </xsl:template>
</xsl:stylesheet>
