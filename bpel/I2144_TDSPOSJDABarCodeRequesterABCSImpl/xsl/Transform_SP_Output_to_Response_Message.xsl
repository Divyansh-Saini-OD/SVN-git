<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="../xsd/APPS_XX_CS_TDS_PARTS_JDA_BPEL_PKG_XX_CS_TDS_PARTS_JDA_PKG-24MAIN__1311176168562.xsd"/>
      <rootElement name="OutputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_TDS_PARTS_JDA_BPEL_PKG/XX_CS_TDS_PARTS_JDA_PKG-24MAIN_/"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="../xsd/POSJDABarCodeResponseEBM.xsd"/>
      <rootElement name="TDSPOSJDABarCodeResponseEBM" namespace="http://www.OfficeDepot.com/TDS/TDSPOSJDABarCodeRequesterABCSImpl/TDSPOSJDABarCodeResponseEBM"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 11.1.1.4.0(build 110106.1932.5682) AT [WED JUL 20 21:17:55 IST 2011]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:mhdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.mediator.service.common.functions.MediatorExtnFunction"
                xmlns:bpel="http://docs.oasis-open.org/wsbpel/2.0/process/executable"
                xmlns:oraext="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:dvm="http://www.oracle.com/XSL/Transform/java/oracle.tip.dvm.LookupValue"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:ns0="http://www.OfficeDepot.com/TDS/TDSPOSJDABarCodeRequesterABCSImpl/TDSPOSJDABarCodeResponseEBM"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_TDS_PARTS_JDA_BPEL_PKG/XX_CS_TDS_PARTS_JDA_PKG-24MAIN_/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:med="http://schemas.oracle.com/mediator/xpath"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:bpm="http://xmlns.oracle.com/bpmn20/extensions"
                xmlns:xdk="http://schemas.oracle.com/bpel/extension/xpath/function/xdk"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:socket="http://www.oracle.com/XSL/Transform/java/oracle.tip.adapter.socket.ProtocolTranslator"
                xmlns:ldap="http://schemas.oracle.com/xpath/extension/ldap"
                exclude-result-prefixes="xsi xsl db xsd ns0 bpws xp20 mhdr bpel oraext dvm hwf med ids bpm xdk xref ora socket ldap">
  <xsl:template match="/">
    <ns0:TDSPOSJDABarCodeResponseEBM>
      <xsl:for-each select="/db:OutputParameters/db:P_PARTS_TBL/db:P_PARTS_TBL_ITEM">
        <ns0:TDSPOSJDABarCodeResponseEBO>
          <ns0:rmsSku>
            <xsl:value-of select="db:RMS_SKU"/>
          </ns0:rmsSku>
          <ns0:itemDescription>
            <xsl:value-of select="db:ITEM_DESCRIPTION"/>
          </ns0:itemDescription>
          <ns0:quantity>
            <xsl:value-of select="db:QUANTITY"/>
          </ns0:quantity>
          <ns0:purchasePrice>
            <xsl:value-of select="db:PURCHASE_PRICE"/>
          </ns0:purchasePrice>
          <ns0:sellingPrice>
            <xsl:value-of select="db:SELLING_PRICE"/>
          </ns0:sellingPrice>
          <ns0:uom>
            <xsl:value-of select="db:UOM"/>
          </ns0:uom>
        </ns0:TDSPOSJDABarCodeResponseEBO>
      </xsl:for-each>
    </ns0:TDSPOSJDABarCodeResponseEBM>
  </xsl:template>
</xsl:stylesheet>
