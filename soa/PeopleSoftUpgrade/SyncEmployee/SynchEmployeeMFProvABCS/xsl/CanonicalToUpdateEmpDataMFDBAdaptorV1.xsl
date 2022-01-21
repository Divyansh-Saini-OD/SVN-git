<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="oramds:/apps/ODCommon/EnterpriseObjects/Core/EBO/Employee/V1/EmployeeEBM.xsd"/>
      <rootElement name="Employee" namespace="http://xmlns.officedepot.com/EnterpriseObjects/Core/EBO/Employee/V1"/>
    </source>
    <source type="XSD">
      <schema location="../xsd/UpdateEmpDataMFDBAdaptorV1.xsd"/>
      <rootElement name="EmpdataCollection" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/top/PSHREmployeeDb2Tbl"/>
      <param name="InvokeUpdateEmpDataSelect_UpdateEmpDataMFDBAdaptorV1Select_OutputVariable.EmpdataCollection" />
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="../xsd/UpdateEmpDataMFDBAdaptorV1.xsd"/>
      <rootElement name="EmpdataCollection" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/top/PSHREmployeeDb2Tbl"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 11.1.1.5.0(build 110418.1550.0174) AT [WED AUG 01 14:21:48 IST 2012]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:aia="http://www.oracle.com/XSL/Transform/java/oracle.apps.aia.core.xpath.AIAFunctions"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:ns0="http://xmlns.officedepot.com/EnterpriseObjects/Core/EBO/Employee/V1"
                xmlns:bpel="http://docs.oasis-open.org/wsbpel/2.0/process/executable"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:bpm="http://xmlns.oracle.com/bpmn20/extensions"
                xmlns:comm="http://xmlns.officedepot.com/EnterpriseObjects/Core/Common/V3"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ns2="http://xmlns.officedepot.com/EnterpriseObjects/Core/Custom/Common/V3"
                xmlns:socket="http://www.oracle.com/XSL/Transform/java/oracle.tip.adapter.socket.ProtocolTranslator"
                xmlns:ns1="http://schemas.xmlsoap.org/ws/2003/03/addressing"
                xmlns:mhdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.mediator.service.common.functions.MediatorExtnFunction"
                xmlns:oraext="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:dvm="http://www.oracle.com/XSL/Transform/java/oracle.tip.dvm.LookupValue"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:med="http://schemas.oracle.com/mediator/xpath"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:ns4="urn:oasis:names:tc:xacml:2.0:policy:schema:cd:04"
                xmlns:xdk="http://schemas.oracle.com/bpel/extension/xpath/function/xdk"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:ns5="http://xmlns.oracle.com/pcbpel/adapter/db/top/PSHREmployeeDb2Tbl"
                xmlns:ns3="urn:oasis:names:tc:xacml:2.0:context:schema:cd:04"
                xmlns:ldap="http://schemas.oracle.com/xpath/extension/ldap"
                exclude-result-prefixes="xsi xsl ns0 comm ns2 ns1 ns4 xsd ns5 ns3 aia bpws xp20 bpel bpm ora socket mhdr oraext dvm hwf med ids xdk xref ldap">
  <xsl:param name="InvokeUpdateEmpDataSelect_UpdateEmpDataMFDBAdaptorV1Select_OutputVariable.EmpdataCollection"/>
  <xsl:template match="/">
    <ns5:EmpdataCollection>
      <ns5:Empdata>
        <ns5:employeeNbr>
          <xsl:value-of select="number(/ns0:Employee/ns0:EmployeeIdentification/ns0:EmployeeID)"/>
        </ns5:employeeNbr>
        <ns5:fName>
          <xsl:value-of select="substring(/ns0:Employee/ns0:PersonDetails/comm:Person/comm:PersonName/comm:FirstName,1,18)"/>
        </ns5:fName>
        <ns5:lName>
          <xsl:value-of select="substring(/ns0:Employee/ns0:PersonDetails/comm:Person/comm:PersonName/comm:FamilyName,1,18)"/>
        </ns5:lName>
        <xsl:choose>
          <xsl:when test='/ns0:Employee/ns0:PersonDetails/comm:Person/comm:PersonName/comm:MiddleName != ""'>
            <ns5:mInit>
              <xsl:value-of select="substring(/ns0:Employee/ns0:PersonDetails/comm:Person/comm:PersonName/comm:MiddleName,1.0,1.0)"/>
            </ns5:mInit>
          </xsl:when>
          <xsl:when test='not(/ns0:Employee/ns0:PersonDetails/comm:Person/comm:PersonName/comm:MiddleName) or (/ns0:Employee/ns0:PersonDetails/comm:Person/comm:PersonName/comm:MiddleName = "")'>
            <ns5:mInit>
              <!--&#160; represents a blank space as the field is not nullable -->
              <xsl:text disable-output-escaping="no"> </xsl:text>
            </ns5:mInit>
          </xsl:when>
        </xsl:choose>
        <ns5:positionCd>
          <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:JobCode,1,6)"/>
        </ns5:positionCd>
        <ns5:locId>
          <xsl:value-of select="number(substring(/ns0:Employee/ns0:EmploymentDetails/ns0:LocationReference/comm:Custom/ns2:LocationID,2,6))"/>
        </ns5:locId>
        <xsl:choose>
          <xsl:when test='not(/ns0:Employee/ns0:EmploymentDetails/ns0:TerminationDate) or (/ns0:Employee/ns0:EmploymentDetails/ns0:TerminationDate = "")'>
            <ns5:termDt>
              <xsl:text disable-output-escaping="no"></xsl:text>
            </ns5:termDt>
          </xsl:when>
          <xsl:otherwise>
            <ns5:termDt>
              <xsl:value-of select="/ns0:Employee/ns0:EmploymentDetails/ns0:TerminationDate"/>
            </ns5:termDt>
          </xsl:otherwise>
        </xsl:choose>
        <!--&#160; represents a blank space as the field is not nullable -->
        <ns5:leaveCd>
          <xsl:text disable-output-escaping="no"> </xsl:text>
        </ns5:leaveCd>
        <ns5:severanceFlg>
          <xsl:text disable-output-escaping="no"> </xsl:text>
        </ns5:severanceFlg>
        <ns5:jobTitle>
          <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:JobCodeDescription,1,30)"/>
        </ns5:jobTitle>
        <xsl:choose>
          <xsl:when test='/ns0:Employee/ns0:PersonDetails/ns0:PersonCommunication/comm:AddressCommunication/comm:Address/comm:DeliveryPointCode != ""'>
            <ns5:mailCd>
              <xsl:value-of select="substring(/ns0:Employee/ns0:PersonDetails/ns0:PersonCommunication/comm:AddressCommunication/comm:Address/comm:DeliveryPointCode,1,10)"/>
            </ns5:mailCd>
          </xsl:when>
          <xsl:when test='not(/ns0:Employee/ns0:PersonDetails/ns0:PersonCommunication/comm:AddressCommunication/comm:Address/comm:DeliveryPointCode) or (/ns0:Employee/ns0:PersonDetails/ns0:PersonCommunication/comm:AddressCommunication/comm:Address/comm:DeliveryPointCode = "")'>
            <ns5:mailCd>
              <xsl:text disable-output-escaping="no"> </xsl:text>
            </ns5:mailCd>
          </xsl:when>
        </xsl:choose>
        <xsl:for-each select="/ns0:Employee/ns0:PersonDetails/ns0:PersonCommunication/ns0:PhoneCommunication">
          <xsl:if test='(comm:UseCode = "Business") and (comm:TypeCode = "Landline")'>
            <xsl:choose>
              <xsl:when test='comm:CompleteNumber != ""'>
                <ns5:phoneNbr>
                  <xsl:value-of select="normalize-space(substring(comm:CompleteNumber,1,12))"/>
                </ns5:phoneNbr>
              </xsl:when>
              <xsl:when test='not(comm:CompleteNumber) or (comm:CompleteNumber = "")'>
                <ns5:phoneNbr>
                  <xsl:text disable-output-escaping="no"> </xsl:text>
                </ns5:phoneNbr>
              </xsl:when>
            </xsl:choose>
          </xsl:if>
        </xsl:for-each>
        <ns5:bldgCd>
          <xsl:text disable-output-escaping="no"> </xsl:text>
        </ns5:bldgCd>
        <ns5:divisionName>
          <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:JobDescription,1,30)"/>
        </ns5:divisionName>
        <ns5:deptName>
          <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:DepartmentReference/comm:Custom/ns2:DepartmentName,1,30)"/>
        </ns5:deptName>
        <xsl:choose>
          <xsl:when test='/ns0:Employee/ns0:PersonDetails/comm:Person/comm:PersonName/comm:PreferredName != ""'>
            <ns5:commonName>
              <xsl:value-of select="substring(/ns0:Employee/ns0:PersonDetails/comm:Person/comm:PersonName/comm:PreferredName,1,20)"/>
            </ns5:commonName>
          </xsl:when>
          <xsl:when test='not(/ns0:Employee/ns0:PersonDetails/comm:Person/comm:PersonName/comm:PreferredName) or (/ns0:Employee/ns0:PersonDetails/comm:Person/comm:PersonName/comm:PreferredName = "")'>
            <ns5:commonName>
              <xsl:text disable-output-escaping="no"> </xsl:text>
            </ns5:commonName>
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test='not(/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:ExtendedEEOCode) or (/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:ExtendedEEOCode = "")'>
            <ns5:eeoCat>
              <xsl:text disable-output-escaping="no"> </xsl:text>
            </ns5:eeoCat>
          </xsl:when>
          <xsl:otherwise>
            <ns5:eeoCat>
              <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:ExtendedEEOCode,1,5)"/>
            </ns5:eeoCat>
          </xsl:otherwise>
        </xsl:choose>
        <ns5:chargingLevel1>
          <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:BusinessUnitReference/comm:BusinessUnitIdentification/comm:ID,1,5)"/>
        </ns5:chargingLevel1>
        <ns5:chargingLevel2>
          <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:LocationReference/comm:Custom/ns2:LocationID,2,6)"/>
        </ns5:chargingLevel2>
        <ns5:chargingLevel3>
          <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:DepartmentReference/comm:Custom/ns2:DepartmentID,1,5)"/>
        </ns5:chargingLevel3>
        <!--&#160; represents a blank space as the field is not nullable -->
        <ns5:chargingLevel4>
          <xsl:text disable-output-escaping="no"> </xsl:text>
        </ns5:chargingLevel4>
        <ns5:last4_Ssn>
          <xsl:value-of select="/ns0:Employee/ns0:PersonDetails/comm:Person/comm:PersonNationalIdentity/comm:Identification/comm:ID"/>
        </ns5:last4_Ssn>
        <!--&#160; represents a blank space as the field is not nullable -->
        <ns5:floorNbr>
          <xsl:text disable-output-escaping="no"> </xsl:text>
        </ns5:floorNbr>
        <ns5:reportsToId>
          <xsl:value-of select="number(/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:JobAssignmentSupervision/ns0:SupervisorID)"/>
        </ns5:reportsToId>
        <ns5:hireDt>
          <xsl:value-of select="/ns0:Employee/ns0:EmploymentDetails/ns0:HireDate"/>
        </ns5:hireDt>
        <!--&#160; represents a blank space as the field is not nullable -->
        <ns5:desktopFlg>
          <xsl:text disable-output-escaping="no"> </xsl:text>
        </ns5:desktopFlg>
        <xsl:choose>
          <xsl:when test='not(/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:BonusCode) or (/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:BonusCode = "")'>
            <ns5:bonusType>
              <xsl:text disable-output-escaping="no"> </xsl:text>
            </ns5:bonusType>
          </xsl:when>
          <xsl:otherwise>
            <ns5:bonusType>
              <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:BonusCode,1,3)"/>
            </ns5:bonusType>
          </xsl:otherwise>
        </xsl:choose>
        <ns5:birthMmdd>
          <xsl:value-of select="/ns0:Employee/ns0:PersonDetails/comm:Person/comm:Custom/ns2:PSHRBirthDate"/>
        </ns5:birthMmdd>
        <ns5:costCenter>
          <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:DepartmentReference/comm:Custom/ns2:CostCenter,1,20)"/>
        </ns5:costCenter>
        <xsl:if test="($InvokeUpdateEmpDataSelect_UpdateEmpDataMFDBAdaptorV1Select_OutputVariable.EmpdataCollection/ns5:EmpdataCollection/ns5:Empdata/ns5:reportsToId != number(/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:JobAssignmentSupervision/ns0:SupervisorID)) or not($InvokeUpdateEmpDataSelect_UpdateEmpDataMFDBAdaptorV1Select_OutputVariable.EmpdataCollection/ns3:EmpdataCollection/ns3:Empdata/ns3:reportsToId)">
          <ns5:rptsToChgDt>
            <xsl:value-of select="/ns0:Employee/ns0:EmploymentDetails/ns0:EffectiveDate"/>
          </ns5:rptsToChgDt>
        </xsl:if>
        <ns5:dtChg>
          <xsl:call-template name="convertDateFormat">
            <xsl:with-param name="indate"
                            select="/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:JobTimePeriod/comm:StartDateTime"/>
          </xsl:call-template>
          <!--xsl:value-of select="xp20:format-dateTime(/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:JobTimePeriod/comm:StartDateTime,'[Y0001]-[M01]-[D01]')"/>-->
        </ns5:dtChg>
        <!--&#160; represents a blank space as the field is not nullable -->
        <ns5:userIdChgBy>
          <xsl:text disable-output-escaping="no">PHRSOAP</xsl:text>
        </ns5:userIdChgBy>
        <ns5:companyCd>
          <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:Company,1,3)"/>
        </ns5:companyCd>
        <ns5:jobcodeSetid>
          <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:SetIDJobCode,1,5)"/>
        </ns5:jobcodeSetid>
        <ns5:locationSetid>
          <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:LocationReference/comm:Custom/ns2:LocationSetID,1,5)"/>
        </ns5:locationSetid>
        <ns5:deptSetid>
          <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:DepartmentReference/comm:Custom/ns2:DepartmentSetID,1,5)"/>
        </ns5:deptSetid>
        <ns5:salarySetid>
          <xsl:value-of select="substring(/ns0:Employee/ns0:EmploymentDetails/ns0:JobDetail/ns0:SetIDSalary,1,5)"/>
        </ns5:salarySetid>
      </ns5:Empdata>
    </ns5:EmpdataCollection>
  </xsl:template>
  <!--  User Defined Templates  -->
  <xsl:template name="convertDateFormat">
    <xsl:param name="indate"/>
    <xsl:variable name="outDate"
                  select="xp20:format-dateTime($indate,'[Y0001]-[M01]-[D01]')"/>
    <xsl:value-of select="$outDate"/>
  </xsl:template>
</xsl:stylesheet>