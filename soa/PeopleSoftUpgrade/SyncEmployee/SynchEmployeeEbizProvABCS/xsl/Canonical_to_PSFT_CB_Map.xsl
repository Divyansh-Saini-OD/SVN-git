<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="../../../Designs/Employee%20Data%20Synch/Cannonical/schema/EBO/Employee/V1/EmployeeEBM.xsd"/>
      <rootElement name="SyncEmployeeEBM" namespace="http://xmlns.officedepot.com/EnterpriseObjects/Core/EBO/Employee/V1"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="http://velambil-lap.in.oracle.com:7001/soa-infra/services/default/UpdateEmployeeErrorCallBackPSFTProvABCS/xsd/UpdateEmployeeErrorToPeopleSoftEBM.xsd"/>
      <rootElement name="UpdateEmployeeErrorToPSFTEBM" namespace="http://xmlns.officedepot.com/PeopleSoftMigration/UpdateEmployeeErrorCallBackPSFTProvABCS/UpdateEmployeeErrorToPSFTEBM"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 11.1.1.4.0(build 110106.1932.5682) AT [WED JUN 13 18:03:51 IST 2012]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:comm="http://xmlns.officedepot.com/EnterpriseObjects/Core/Common/V1"
                xmlns:mhdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.mediator.service.common.functions.MediatorExtnFunction"
                xmlns:bpel="http://docs.oasis-open.org/wsbpel/2.0/process/executable"
                xmlns:ns0="http://xmlns.officedepot.com/EnterpriseObjects/Core/EBO/Employee/V1"
                xmlns:oraext="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:dvm="http://www.oracle.com/XSL/Transform/java/oracle.tip.dvm.LookupValue"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:med="http://schemas.oracle.com/mediator/xpath"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:bpm="http://xmlns.oracle.com/bpmn20/extensions"
                xmlns:xdk="http://schemas.oracle.com/bpel/extension/xpath/function/xdk"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:ns1="http://xmlns.officedepot.com/PeopleSoftMigration/UpdateEmployeeErrorCallBackPSFTProvABCS/UpdateEmployeeErrorToPSFTEBM"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:socket="http://www.oracle.com/XSL/Transform/java/oracle.tip.adapter.socket.ProtocolTranslator"
                xmlns:ldap="http://schemas.oracle.com/xpath/extension/ldap"
                exclude-result-prefixes="xsi xsl comm ns0 xsd ns1 bpws xp20 mhdr bpel oraext dvm hwf med ids bpm xdk xref ora socket ldap">
  <xsl:template match="/">
    <ns1:UpdateEmployeeErrorToPSFTEBM>
      <xsl:for-each select="/ns0:SyncEmployeeEBM/ns0:DataArea/ns0:EmployeeList/ns0:Employee">
        <ns1:EmployeeIDList>
          <ns1:EmployeeID>
            <xsl:value-of select="ns0:EmployeeIdentification/ns0:EmployeeID"/>
          </ns1:EmployeeID>
        </ns1:EmployeeIDList>
      </xsl:for-each>
      <ns1:ProcessFlag>
        <xsl:text disable-output-escaping="no">N</xsl:text>
      </ns1:ProcessFlag>
      <ns1:ProcessDateTime>
        <xsl:value-of select="/ns0:SyncEmployeeEBM/ns0:DataArea/ns0:DateTimeCreated"/>
      </ns1:ProcessDateTime>
    </ns1:UpdateEmployeeErrorToPSFTEBM>
  </xsl:template>
</xsl:stylesheet>
