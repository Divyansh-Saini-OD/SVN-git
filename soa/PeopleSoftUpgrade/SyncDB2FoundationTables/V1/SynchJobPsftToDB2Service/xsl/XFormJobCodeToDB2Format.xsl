<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="WSDL">
      <schema location="../SynchJobPsftToDB2Service.wsdl"/>
      <rootElement name="SyncJobEBM" namespace="http://xmlns.officedepot.com/EnterpriseObjectLibrary/EBO/Job/V1"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="WSDL">
      <schema location="../InsertUpdateJobDB2Data.wsdl"/>
      <rootElement name="PsJobcodeTblCollection" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/top/InsertUpdateJobDB2Data"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 11.1.1.6.0(build 111214.0600.1553) AT [TUE JUN 26 15:16:59 IST 2012]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:bpel="http://docs.oasis-open.org/wsbpel/2.0/process/executable"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:client="http://xmlns.oracle.com/OfficeDepotSOAApps/SynchJobPsftToDB2Service/SynchJobPsftToDB2Service"
                xmlns:bpm="http://xmlns.oracle.com/bpmn20/extensions"
                xmlns:job="http://xmlns.officedepot.com/EnterpriseObjectLibrary/EBO/Job/V1"
                xmlns:plnk="http://schemas.xmlsoap.org/ws/2003/05/partner-link/"
                xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:socket="http://www.oracle.com/XSL/Transform/java/oracle.tip.adapter.socket.ProtocolTranslator"
                xmlns:mhdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.mediator.service.common.functions.MediatorExtnFunction"
                xmlns:ns0="http://xmlns.officedepot.com/EnterpriseObjectLibrary/Common/V1"
                xmlns:oraext="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:dvm="http://www.oracle.com/XSL/Transform/java/oracle.tip.dvm.LookupValue"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:med="http://schemas.oracle.com/mediator/xpath"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:top="http://xmlns.oracle.com/pcbpel/adapter/db/top/InsertUpdateJobDB2Data"
                xmlns:xdk="http://schemas.oracle.com/bpel/extension/xpath/function/xdk"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:tns="http://xmlns.oracle.com/pcbpel/adapter/db/Application1/DB2FoundationTbls/InsertUpdateJobDB2Data"
                xmlns:ldap="http://schemas.oracle.com/xpath/extension/ldap"
                exclude-result-prefixes="xsi xsl client job plnk wsdl ns0 xsd top tns xp20 bpws bpel bpm ora socket mhdr oraext dvm hwf med ids xdk xref ldap">
  <xsl:template match="/">
    <top:PsJobcodeTblCollection>
     <xsl:for-each select="/job:SyncJobEBM/job:DataArea/job:JobList">
      <top:PsJobcodeTbl>
        <top:setid>
          <xsl:value-of select="job:Job/job:JobIdentification/job:JobCodeSetId"/>
        </top:setid>
        <top:jobcode>
          <xsl:value-of select="job:Job/job:JobIdentification/job:JobCode"/>
        </top:jobcode>
        <top:effdt>
          <xsl:value-of select="job:Job/job:JobEffectivity/job:EffectiveDate"/>
        </top:effdt>
        <top:descr>
          <xsl:value-of select="job:Job/job:JobIdentification/job:Description"/>
        </top:descr>
        <top:jobFunction>
          <xsl:value-of select="job:Job/job:JobIdentification/job:JobFunction"/>
        </top:jobFunction>
      </top:PsJobcodeTbl>
      </xsl:for-each>
    </top:PsJobcodeTblCollection>
  </xsl:template>
</xsl:stylesheet>
