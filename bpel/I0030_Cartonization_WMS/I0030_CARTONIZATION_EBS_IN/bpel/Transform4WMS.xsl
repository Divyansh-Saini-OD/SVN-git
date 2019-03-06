<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="APPS_BPEL_SHIPMENTUNITDETAILS4WMS_XX_OM_CARTON_GETSHPMT_PKG-24GET.xsd"/>
      <rootElement name="OutputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/BPEL_SHIPMENTUNITDETAILS4WMS/XX_OM_CARTON_GETSHPMT_PKG-24GET/"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="CA06_INBOUND.xsd"/>
      <rootElement name="Root-Element" namespace="http://TargetNamespace.com/CA06MQIN1"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.1.0(build 061009.0802) AT [THU JUL 26 15:52:33 IST 2007]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:ns0="http://www.w3.org/2001/XMLSchema"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:nxsd="http://xmlns.oracle.com/pcbpel/nxsd"
                xmlns:extn="http://xmlns.oracle.com/pcbpel/nxsd/extensions"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tns="http://TargetNamespace.com/CA06MQIN1"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/BPEL_SHIPMENTUNITDETAILS4WMS/XX_OM_CARTON_GETSHPMT_PKG-24GET/"
                exclude-result-prefixes="xsl ns0 db nxsd extn tns bpws ehdr hwf xp20 ora ids orcl">
  <xsl:template match="/">
    <tns:Root-Element>
      <tns:INPUT-MESSAGE>
        <tns:WS-OTMC-DELIV-NBR>
          <xsl:value-of select="/db:OutputParameters/X_GETSHIPMENTUNIT_TBL/X_GETSHIPMENTUNIT_TBL_ITEM/DELIVERY_NUMBER"/>
        </tns:WS-OTMC-DELIV-NBR>
        <tns:WS-OTMC-WHS-NBR>
          <xsl:value-of select="/db:OutputParameters/X_GETSHIPMENTUNIT_TBL/X_GETSHIPMENTUNIT_TBL_ITEM/WHSE"/>
        </tns:WS-OTMC-WHS-NBR>
        <tns:WS-OTMC-SKU>
          <tns:WS-OTMC-DELIV-LINE-NBR>
            <xsl:value-of select="/db:OutputParameters/X_GETSHIPMENTUNIT_TBL/X_GETSHIPMENTUNIT_TBL_ITEM/DELIVERY_LINE_NUMBER"/>
          </tns:WS-OTMC-DELIV-LINE-NBR>
          <tns:WS-OTMC-SKU-ID>
            <xsl:value-of select="/db:OutputParameters/X_GETSHIPMENTUNIT_TBL/X_GETSHIPMENTUNIT_TBL_ITEM/SKU"/>
          </tns:WS-OTMC-SKU-ID>
          <tns:WS-OTMC-SKU-QTY>
            <xsl:value-of select="/db:OutputParameters/X_GETSHIPMENTUNIT_TBL/X_GETSHIPMENTUNIT_TBL_ITEM/SKU_QTY"/>
          </tns:WS-OTMC-SKU-QTY>
        </tns:WS-OTMC-SKU>
      </tns:INPUT-MESSAGE>
    </tns:Root-Element>
  </xsl:template>
</xsl:stylesheet>
