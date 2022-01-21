<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="../xsd/PartsOrderEBM.xsd"/>
      <rootElement name="PartsOrderEBM" namespace="http://www.officedepot.com/TDS/GetPartsOrderProvABCSImpl/PartsOrderEBM"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="../xsd/APPS_XX_CS_TDS_PARTS_JDA_PKG_MAIN_PROC.xsd"/>
      <rootElement name="InputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_TDS_PARTS_JDA_PKG/MAIN_PROC/"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 11.1.1.4.0(build 110106.1932.5682) AT [WED AUG 03 14:18:30 IST 2011]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:mhdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.mediator.service.common.functions.MediatorExtnFunction"
                xmlns:bpel="http://docs.oasis-open.org/wsbpel/2.0/process/executable"
                xmlns:oraext="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_CS_TDS_PARTS_JDA_PKG/MAIN_PROC/"
                xmlns:dvm="http://www.oracle.com/XSL/Transform/java/oracle.tip.dvm.LookupValue"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:med="http://schemas.oracle.com/mediator/xpath"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:bpm="http://xmlns.oracle.com/bpmn20/extensions"
                xmlns:xdk="http://schemas.oracle.com/bpel/extension/xpath/function/xdk"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:socket="http://www.oracle.com/XSL/Transform/java/oracle.tip.adapter.socket.ProtocolTranslator"
                xmlns:od="http://www.officedepot.com/TDS/MessageHeader"
                xmlns:ns0="http://www.officedepot.com/TDS/GetPartsOrderProvABCSImpl/PartsOrderEBM"
                xmlns:ldap="http://schemas.oracle.com/xpath/extension/ldap"
                exclude-result-prefixes="xsi xsl xsd od ns0 db bpws xp20 mhdr bpel oraext dvm hwf med ids bpm xdk xref ora socket ldap">
  <xsl:template match="/">
    <db:InputParameters>
      <db:P_SR_NUMBER>
        <xsl:value-of select="/ns0:PartsOrderEBM/ns0:PartsOrderEBM/ns0:ServiceRequestNumber"/>
      </db:P_SR_NUMBER>
    </db:InputParameters>
  </xsl:template>
</xsl:stylesheet>
