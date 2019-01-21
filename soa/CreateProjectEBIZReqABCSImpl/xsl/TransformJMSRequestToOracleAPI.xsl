<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="../xsd/ProjectEBO.xsd"/>
      <rootElement name="Project" namespace="http://xmlns.oracle.com/EnterpriseObjects/Core/EBO/Project/V1"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="../xsd/APPS_XX_PA_CREATE_PKG_SERVICE_EJM_QUEUE.xsd"/>
      <rootElement name="InputParameters" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_PA_CREATE_PKG/SERVICE_EJM_QUEUE/"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 11.1.1.4.0(build 110106.1932.5682) AT [FRI MAR 16 15:30:31 EDT 2012]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:svcdoc="http://xmlns.oracle.com/Services/Documentation/V1"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:bpel="http://docs.oasis-open.org/wsbpel/2.0/process/executable"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:coreprojectcust="http://xmlns.oracle.com/EnterpriseObjects/Core/Custom/EBO/Project/V1"
                xmlns:corecomEBO="http://xmlns.oracle.com/EnterpriseObjects/Core/CommonEBO/V1"
                xmlns:bpm="http://xmlns.oracle.com/bpmn20/extensions"
                xmlns:db="http://xmlns.oracle.com/pcbpel/adapter/db/APPS/XX_PA_CREATE_PKG/SERVICE_EJM_QUEUE/"
                xmlns:corecomcust="http://xmlns.oracle.com/EnterpriseObjects/Core/Custom/Common/V2"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:socket="http://www.oracle.com/XSL/Transform/java/oracle.tip.adapter.socket.ProtocolTranslator"
                xmlns:ns1="http://schemas.xmlsoap.org/ws/2003/03/addressing"
                xmlns:mhdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.mediator.service.common.functions.MediatorExtnFunction"
                xmlns:oraext="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:dvm="http://www.oracle.com/XSL/Transform/java/oracle.tip.dvm.LookupValue"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:med="http://schemas.oracle.com/mediator/xpath"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:ns3="urn:oasis:names:tc:xacml:2.0:policy:schema:cd:04"
                xmlns:xdk="http://schemas.oracle.com/bpel/extension/xpath/function/xdk"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:ns0="http://xmlns.oracle.com/EnterpriseObjects/Core/EBO/Project/V1"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:corecom="http://xmlns.oracle.com/EnterpriseObjects/Core/Common/V2"
                xmlns:ns2="urn:oasis:names:tc:xacml:2.0:context:schema:cd:04"
                xmlns:ldap="http://schemas.oracle.com/xpath/extension/ldap"
                exclude-result-prefixes="xsi xsl svcdoc coreprojectcust corecomEBO corecomcust ns1 ns3 ns0 xsd corecom ns2 db xp20 bpws bpel bpm ora socket mhdr oraext dvm hwf med ids xdk xref ldap">
  <xsl:template match="/">
    <db:InputParameters>
      <db:P_PROJ_REC>
        <xsl:for-each select="/ns0:Project/ns0:ProjectEBO">
          <db:P_PROJ_REC_ITEM>
            <db:PANEX>
              <xsl:attribute name="xsi:nil">
                <xsl:value-of select="corecom:Identification/corecom:BusinessComponentID"/>
              </xsl:attribute>
              <xsl:value-of select="corecom:Identification/corecom:BusinessComponentID"/>
            </db:PANEX>
            <db:PROJECTID>
              <xsl:value-of select="corecom:Identification/corecom:ID"/>
            </db:PROJECTID>
            <db:PROJMAN>
              <xsl:attribute name="xsi:nil">
                <xsl:value-of select="ns0:ProjectStructure/ns0:ProjectTask/corecom:ManagerProjectSchedulableResourceReference/corecom:ProjectSchedulableResourceIdentification/corecom:BusinessComponentID"/>
              </xsl:attribute>
              <xsl:value-of select="ns0:ProjectStructure/ns0:ProjectTask/corecom:ManagerProjectSchedulableResourceReference/corecom:ProjectSchedulableResourceIdentification/corecom:BusinessComponentID"/>
            </db:PROJMAN>
            <db:TEMPLATE>
              <xsl:attribute name="xsi:nil">
                <xsl:value-of select="corecom:SourceProjectReference/corecom:ProjectIdentfication/corecom:BusinessComponentID"/>
              </xsl:attribute>
              <xsl:value-of select="corecom:SourceProjectReference/corecom:ProjectIdentfication/corecom:BusinessComponentID"/>
            </db:TEMPLATE>
            <db:PROJORG>
              <xsl:attribute name="xsi:nil">
                <xsl:value-of select="corecom:BusinessUnitReference/corecom:BusinessUnitIdentification/corecom:BusinessComponentID"/>
              </xsl:attribute>
              <xsl:value-of select="corecom:BusinessUnitReference/corecom:BusinessUnitIdentification/corecom:BusinessComponentID"/>
            </db:PROJORG>
            <db:PROJNAME>
              <xsl:value-of select="ns0:Name"/>
            </db:PROJNAME>
            <db:PROJLONGNAME>
              <xsl:value-of select="ns0:Custom/ns0:CustomProjectLongName"/>
            </db:PROJLONGNAME>
            <db:PROJDESC>
              <xsl:value-of select="ns0:Description"/>
            </db:PROJDESC>
            <db:STARTDATE>
              <xsl:value-of select="ns0:PlannedStartDate"/>
            </db:STARTDATE>
            <db:COMPLETIONDATE>
              <xsl:value-of select="ns0:PlannedCompletionDate"/>
            </db:COMPLETIONDATE>
            <db:COUNTRYID>
              <xsl:value-of select="ns0:Custom/ns0:CustomCountryCode"/>
            </db:COUNTRYID>
            <db:EXPENSE>
              <xsl:value-of select="ns0:ProjectStructure/ns0:ProjectTask/ns0:ProjectTaskPlannedCharacteristics/ns0:PlannedExpenseCostAmount"/>
            </db:EXPENSE>
            <db:CAPITAL>
              <xsl:value-of select="ns0:ProjectStructure/ns0:ProjectTask/ns0:ProjectTaskPlannedCharacteristics/ns0:PlannedMaterialCostAmount"/>
            </db:CAPITAL>
            <xsl:for-each select="ns0:ProjectStructure/ns0:ProjectTask/ns0:ProjectResourceAssignment/ns0:Custom">
              <db:MEMBER_REC>
                <db:MEMBER_REC_ITEM>
                  <db:ROLE>
                    <xsl:value-of select="ns0:RoleIndicator"/>
                  </db:ROLE>
                  <db:EMPLOYEEID>
                    <xsl:attribute name="xsi:nil">
                      <xsl:value-of select="corecom:Identification/corecom:BusinessComponentID"/>
                    </xsl:attribute>
                    <xsl:value-of select="corecom:Identification/corecom:BusinessComponentID"/>
                  </db:EMPLOYEEID>
                </db:MEMBER_REC_ITEM>
              </db:MEMBER_REC>
            </xsl:for-each>
          </db:P_PROJ_REC_ITEM>
        </xsl:for-each>
      </db:P_PROJ_REC>
    </db:InputParameters>
  </xsl:template>
</xsl:stylesheet>
