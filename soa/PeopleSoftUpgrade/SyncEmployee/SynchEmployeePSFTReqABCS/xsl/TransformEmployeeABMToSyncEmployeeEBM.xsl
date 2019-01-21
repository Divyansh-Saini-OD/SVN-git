<?xml version='1.0' encoding='UTF-8'?>
<xsl:stylesheet version="1.0" xmlns:sample="http://www.oracle.com/XSL/Transform/java/com.od.security.SerializedCouponConverter" xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20" xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/" xmlns:bpel="http://docs.oasis-open.org/wsbpel/2.0/process/executable" xmlns:ns1="http://xmlns.officedepot.com/EnterpriseObjects/Core/EBO/Employee/V1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:bpm="http://xmlns.oracle.com/bpmn20/extensions" xmlns:comm="http://xmlns.officedepot.com/EnterpriseObjects/Core/Common/V3" xmlns:ora="http://schemas.oracle.com/xpath/extension" xmlns:ns3="http://xmlns.officedepot.com/EnterpriseObjects/Core/Custom/Common/V3" xmlns:socket="http://www.oracle.com/XSL/Transform/java/oracle.tip.adapter.socket.ProtocolTranslator" xmlns:ns0="http://xmlns.officedepot.com/ApplicationMessage/HR/Custom/ABM/SyncEmployeeABM/V1" xmlns:ns2="http://schemas.xmlsoap.org/ws/2003/03/addressing" xmlns:mhdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.mediator.service.common.functions.MediatorExtnFunction" xmlns:oraext="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc" xmlns:dvm="http://www.oracle.com/XSL/Transform/java/oracle.tip.dvm.LookupValue" xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath" xmlns:med="http://schemas.oracle.com/mediator/xpath" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath" xmlns:ns5="urn:oasis:names:tc:xacml:2.0:policy:schema:cd:04" xmlns:xdk="http://schemas.oracle.com/bpel/extension/xpath/function/xdk" xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:bpmn="http://schemas.oracle.com/bpm/xpath" xmlns:ns4="urn:oasis:names:tc:xacml:2.0:context:schema:cd:04" xmlns:ldap="http://schemas.oracle.com/xpath/extension/ldap" exclude-result-prefixes="xsi xsl ns0 xsd ns1 comm ns3 ns2 ns5 ns4 sample xp20 bpws bpel bpm ora socket mhdr oraext dvm hwf med ids xdk xref bpmn ldap">
   <xsl:template match="/">
      <ns1:SyncEmployeeEBM>
         <comm:EBMHeader>
            <comm:EBMName>
               <xsl:text disable-output-escaping="no">SyncEmployeeEBM</xsl:text>
            </comm:EBMName>
            <comm:CreationDateTime>
               <xsl:value-of select="/ns0:SyncEmployeeABM/ns0:EmployeeHeader/ns0:CreationDateTime"/>
            </comm:CreationDateTime>
            <comm:VerbCode>
               <xsl:text disable-output-escaping="no">Sync</xsl:text>
            </comm:VerbCode>
            <comm:Sender>
               <comm:ID>
                  <xsl:text disable-output-escaping="no">PSHR</xsl:text>
               </comm:ID>
            </comm:Sender>
         </comm:EBMHeader>
         <ns1:DataArea>
            <ns1:BatchId>
               <xsl:value-of select="/ns0:SyncEmployeeABM/ns0:EmployeeHeader/ns0:BatchID"/>
            </ns1:BatchId>
            <ns1:ChunkID>
               <xsl:value-of select="/ns0:SyncEmployeeABM/ns0:EmployeeHeader/ns0:ChunkID"/>
            </ns1:ChunkID>
            <ns1:EmployeeList>
               <xsl:for-each select="/ns0:SyncEmployeeABM/ns0:EmployeeDetails">
                  <ns1:Employee>
                     <ns1:EmployeeIdentification>
                        <ns1:EmployeeID>
                           <xsl:value-of select="ns0:EmployeeID"/>
                        </ns1:EmployeeID>
                     </ns1:EmployeeIdentification>
                     <ns1:EmploymentDetails>
                        <ns1:BadgeNumber>
                           <xsl:value-of select="ns0:BadgeNumber"/>
                        </ns1:BadgeNumber>
                        <ns1:Company>
                           <xsl:value-of select="ns0:Company"/>
                        </ns1:Company>
                        <ns1:PersonRelationWithOrganisation>
                           <xsl:value-of select="ns0:PerOrg"/>
                        </ns1:PersonRelationWithOrganisation>
                        <ns1:Status>
                           <xsl:value-of select="ns0:EmployementStatus"/>
                        </ns1:Status>
                        <ns1:Action>
                           <xsl:value-of select="ns0:Action"/>
                        </ns1:Action>
                        <ns1:VendorID>
                           <xsl:value-of select="ns0:VendorID"/>
                        </ns1:VendorID>
                        <ns1:HireDate>
                           <xsl:call-template name="convertDateFormat">
                              <xsl:with-param name="indate" select="ns0:HireDate"/>
                           </xsl:call-template>
                        </ns1:HireDate>
                        <ns1:EffectiveDate>
                           <xsl:call-template name="convertDateFormat">
                              <xsl:with-param name="indate" select="ns0:ODJobEffectiveDate"/>
                           </xsl:call-template>
                        </ns1:EffectiveDate>
                        <ns1:TerminationDate>
                           <xsl:call-template name="convertDateFormat">
                              <xsl:with-param name="indate" select="ns0:TerminationDate"/>
                           </xsl:call-template>
                        </ns1:TerminationDate>
                        <ns1:LastWorkedDate>
                           <xsl:call-template name="convertDateFormat">
                              <xsl:with-param name="indate" select="ns0:LastWorkedDate"/>
                           </xsl:call-template>
                        </ns1:LastWorkedDate>
                        <ns1:RegulatoryRegion>
                           <xsl:value-of select="ns0:RegulatoryRegion"/>
                        </ns1:RegulatoryRegion>
                        <ns1:DepartmentReference>
                           <comm:Custom>
                              <ns3:DepartmentID>
                                 <xsl:value-of select="ns0:DepartmentID"/>
                              </ns3:DepartmentID>
                              <ns3:DepartmentName>
                                 <xsl:value-of select="ns0:DepartmentName"/>
                              </ns3:DepartmentName>
                              <ns3:DepartmentSetID>
                                 <xsl:value-of select="ns0:SetIDDepartment"/>
                              </ns3:DepartmentSetID>
                              <ns3:CostCenter>
                                 <xsl:value-of select="ns0:CostCenter"/>
                              </ns3:CostCenter>
                           </comm:Custom>
                        </ns1:DepartmentReference>
                        <ns1:BusinessUnitReference>
                           <comm:BusinessUnitIdentification>
                              <comm:ID>
                                 <xsl:value-of select="ns0:BusinessUnit"/>
                              </comm:ID>
                           </comm:BusinessUnitIdentification>
                        </ns1:BusinessUnitReference>
                        <ns1:LocationReference>
                           <comm:Custom>
                              <ns3:LocationID>
                                 <xsl:value-of select="ns0:Location"/>
                              </ns3:LocationID>
                              <ns3:LocationSetID>
                                 <xsl:value-of select="ns0:SetIDLocation"/>
                              </ns3:LocationSetID>
                           </comm:Custom>
                        </ns1:LocationReference>
                        <ns1:JobDetail>
                           <ns1:JobCode>
                              <xsl:value-of select="ns0:JobCode"/>
                           </ns1:JobCode>
                           <ns1:JobCodeDescription>
                              <xsl:value-of select="ns0:JobCodeDescription"/>
                           </ns1:JobCodeDescription>
                           <ns1:JobFunction>
                              <xsl:value-of select="ns0:JobFunction"/>
                           </ns1:JobFunction>
                           <ns1:JobDescription>
                              <xsl:value-of select="ns0:JobDescription"/>
                           </ns1:JobDescription>
                           <ns1:SetIDJobCode>
                              <xsl:value-of select="ns0:SetIDJobCode"/>
                           </ns1:SetIDJobCode>
                           <ns1:SalaryAdminPlan>
                              <xsl:value-of select="ns0:SalaryAdminPlan"/>
                           </ns1:SalaryAdminPlan>
                           <ns1:BonusCode>
                              <xsl:value-of select="ns0:ODBonusCode"/>
                           </ns1:BonusCode>
                           <ns1:ExtendedEEOCode>
                              <xsl:value-of select="ns0:ODExtendedOEE"/>
                           </ns1:ExtendedEEOCode>
                           <ns1:SetIDSalary>
                              <xsl:value-of select="ns0:SetIDSalary"/>
                           </ns1:SetIDSalary>
                           <ns1:JobTimePeriod>
                              <comm:StartDateTime>
                                 <xsl:call-template name="convertDateFormat">
                                    <xsl:with-param name="indate" select="ns0:JobEntryDate"/>
                                    <xsl:with-param name="inAddTime" select="'Y'"/>
                                 </xsl:call-template>
                              </comm:StartDateTime>
                           </ns1:JobTimePeriod>
                           <ns1:JobGrade>
                              <ns1:Grade>
                                 <xsl:value-of select="ns0:Grade"/>
                              </ns1:Grade>
                           </ns1:JobGrade>
                           <ns1:JobAssignmentSupervision>
                              <ns1:SupervisorID>
                                 <xsl:value-of select="ns0:SupervisorID"/>
                              </ns1:SupervisorID>
                              <ns1:ManagerLevel>
                                 <xsl:value-of select="ns0:ManagerLevel"/>
                              </ns1:ManagerLevel>
                           </ns1:JobAssignmentSupervision>
                        </ns1:JobDetail>
                     </ns1:EmploymentDetails>
                     <ns1:PersonDetails>
                        <comm:Person>
                           <comm:GenderCode>
                              <xsl:value-of select="ns0:Gender"/>
                           </comm:GenderCode>
                           <comm:PersonName>
                              <comm:FirstName>
                                 <xsl:value-of select="ns0:FirstName"/>
                              </comm:FirstName>
                              <comm:MiddleName>
                                 <xsl:value-of select="ns0:MiddleName"/>
                              </comm:MiddleName>
                              <comm:FamilyName>
                                 <xsl:value-of select="ns0:LastName"/>
                              </comm:FamilyName>
                              <comm:Prefix>
                                 <xsl:value-of select="ns0:NamePrefix"/>
                              </comm:Prefix>
                              <comm:Suffix>
                                 <xsl:value-of select="ns0:NameSuffix"/>
                              </comm:Suffix>
                              <comm:PreferredName>
                                 <xsl:value-of select="ns0:CommonName"/>
                              </comm:PreferredName>
                              <comm:Custom>
                                 <ns3:SecondLastName>
                                    <xsl:value-of select="ns0:SecondLastName"/>
                                 </ns3:SecondLastName>
                              </comm:Custom>
                           </comm:PersonName>
                           <comm:PersonNationalIdentity>
                              <comm:Identification>
                                 <comm:ID>
                                    <xsl:value-of select="ns0:NationalID"/>
                                 </comm:ID>
                              </comm:Identification>
                           </comm:PersonNationalIdentity>
                           <comm:Custom>
                              <ns3:PSHRBirthDate>
                                 <xsl:value-of select="ns0:BirthDate"/>
                              </ns3:PSHRBirthDate>
                           </comm:Custom>
                        </comm:Person>
                        <ns1:PersonCommunication>
                           <comm:AddressCommunication>
                              <comm:Address>
                                 <comm:LineOne>
                                    <xsl:value-of select="ns0:Address1"/>
                                 </comm:LineOne>
                                 <comm:LineTwo>
                                    <xsl:value-of select="ns0:Address2"/>
                                 </comm:LineTwo>
                                 <comm:LineThree>
                                    <xsl:value-of select="ns0:Address3"/>
                                 </comm:LineThree>
                                 <comm:CityName>
                                    <xsl:value-of select="ns0:City"/>
                                 </comm:CityName>
                                 <comm:StateName>
                                    <xsl:value-of select="ns0:State"/>
                                 </comm:StateName>
                                 <comm:CountyName>
                                    <xsl:value-of select="ns0:County"/>
                                 </comm:CountyName>
                                 <comm:CountryCode>
                                    <xsl:value-of select="ns0:Country"/>
                                 </comm:CountryCode>
                                 <comm:DeliveryPointCode>
                                    <xsl:value-of select="ns0:ODMailCode"/>
                                 </comm:DeliveryPointCode>
                                 <comm:PostalCode>
                                    <xsl:value-of select="ns0:PostalCode"/>
                                 </comm:PostalCode>
                              </comm:Address>
                              <comm:EffectiveTimePeriod>
                                 <comm:StartDateTime>
                                    <xsl:call-template name="convertDateFormat">
                                       <xsl:with-param name="indate" select="ns0:ODAddressEffectiveDate"/>
                                       <xsl:with-param name="inAddTime" select="'Y'"/>
                                    </xsl:call-template>
                                 </comm:StartDateTime>
                              </comm:EffectiveTimePeriod>
                           </comm:AddressCommunication>
                           <ns1:EmailCommunication>
                              <comm:URI>
                                 <xsl:value-of select="ns0:EmailID"/>
                              </comm:URI>
                           </ns1:EmailCommunication>
                           <xsl:call-template name="getFaxCommunicationDeviceDetails">
                              <xsl:with-param name="completeNumber" select="ns0:PersonalPhoneFax"/>
                              <xsl:with-param name="usage" select="&quot;Personal&quot;"/>
                              <xsl:with-param name="preferenceIndicator" select="ns0:PersonalPhoneFaxPreferenceFlag"/>
                           </xsl:call-template>
                           <xsl:call-template name="getFaxCommunicationDeviceDetails">
                              <xsl:with-param name="completeNumber" select="ns0:BusinessPhoneFax"/>
                              <xsl:with-param name="usage" select="&quot;Business&quot;"/>
                              <xsl:with-param name="preferenceIndicator" select="ns0:BusinessPhoneFaxPreferenceFlag"/>
                           </xsl:call-template>
                           <xsl:call-template name="getPhoneCommunicationDeviceDetails">
                              <xsl:with-param name="completeNumber" select="ns0:BusinessPhone"/>
                              <xsl:with-param name="usage" select="&quot;Business&quot;"/>
                              <xsl:with-param name="deviceTypeCode" select="&quot;Landline&quot;"/>
                              <xsl:with-param name="preferenceIndicator" select="ns0:BusinessPhonePreferenceFlag"/>
                           </xsl:call-template>
                           <xsl:call-template name="getPhoneCommunicationDeviceDetails">
                              <xsl:with-param name="completeNumber" select="ns0:MainPhone"/>
                              <xsl:with-param name="usage" select="&quot;Main&quot;"/>
                              <xsl:with-param name="deviceTypeCode" select="&quot;Landline&quot;"/>
                              <xsl:with-param name="preferenceIndicator" select="ns0:MainPhonePreferenceFlag"/>
                           </xsl:call-template>
                           <xsl:call-template name="getPhoneCommunicationDeviceDetails">
                              <xsl:with-param name="completeNumber" select="ns0:BusinessPhoneMobile"/>
                              <xsl:with-param name="usage" select="&quot;Business&quot;"/>
                              <xsl:with-param name="deviceTypeCode" select="&quot;Mobile&quot;"/>
                              <xsl:with-param name="preferenceIndicator" select="ns0:BusinessPhoneMobilePreferenceFlag"/>
                           </xsl:call-template>
                           <xsl:call-template name="getPhoneCommunicationDeviceDetails">
                              <xsl:with-param name="completeNumber" select="ns0:PersonalPhoneMobile"/>
                              <xsl:with-param name="usage" select="&quot;Personal&quot;"/>
                              <xsl:with-param name="deviceTypeCode" select="&quot;Mobile&quot;"/>
                              <xsl:with-param name="preferenceIndicator" select="ns0:PersonalPhoneMobilePreferenceFlag"/>
                           </xsl:call-template>
                           <xsl:call-template name="getPhoneCommunicationDeviceDetails">
                              <xsl:with-param name="completeNumber" select="ns0:PersonalPhonePager"/>
                              <xsl:with-param name="usage" select="&quot;Personal&quot;"/>
                              <xsl:with-param name="deviceTypeCode" select="&quot;Pager&quot;"/>
                              <xsl:with-param name="preferenceIndicator" select="ns0:PersonalPhonePagerPreferenceFlag"/>
                           </xsl:call-template>
                        </ns1:PersonCommunication>
                     </ns1:PersonDetails>
                  </ns1:Employee>
               </xsl:for-each>
            </ns1:EmployeeList>
         </ns1:DataArea>
      </ns1:SyncEmployeeEBM>
   </xsl:template>
   <xsl:template name="getPhoneCommunicationDeviceDetails">
      <xsl:param name="completeNumber"/>
      <xsl:param name="usage"/>
      <xsl:param name="deviceTypeCode"/>
      <xsl:param name="preferenceIndicator"/>
      <ns1:PhoneCommunication>
         <comm:CompleteNumber>
            <xsl:value-of select="$completeNumber"/>
         </comm:CompleteNumber>
         <comm:UseCode>
            <xsl:value-of select="$usage"/>
         </comm:UseCode>
         <comm:TypeCode>
            <xsl:value-of select="$deviceTypeCode"/>
         </comm:TypeCode>
         <comm:Preference>
            <comm:PreferredIndicator>
               <xsl:value-of select="$preferenceIndicator"/>
            </comm:PreferredIndicator>
         </comm:Preference>
      </ns1:PhoneCommunication>
   </xsl:template>
   <xsl:template name="getFaxCommunicationDeviceDetails">
      <xsl:param name="completeNumber"/>
      <xsl:param name="usage"/>
      <xsl:param name="preferenceIndicator"/>
      <ns1:FaxCommunication>
         <comm:CompleteNumber>
            <xsl:value-of select="$completeNumber"/>
         </comm:CompleteNumber>
         <comm:UseCode>
            <xsl:value-of select="$usage"/>
         </comm:UseCode>
         <comm:Preference>
            <comm:PreferredIndicator>
               <xsl:value-of select="$preferenceIndicator"/>
            </comm:PreferredIndicator>
         </comm:Preference>
      </ns1:FaxCommunication>
   </xsl:template>
   <xsl:template name="convertDateFormat">
      <xsl:param name="indate"/>
      <xsl:param name="inAddTime"/>
      <xsl:variable name="mm" select="substring-before($indate,'/')"/>
      <xsl:variable name="dd" select="substring-before(substring-after($indate,'/'),'/')"/>
      <xsl:variable name="yyyy" select="substring-after(substring-after($indate,'/'),'/')"/>
      <xsl:value-of select="$yyyy"/>
      <xsl:value-of select="'-'"/>
      <xsl:if test="string-length($mm) = 1">
         <xsl:value-of select="'0'"/>
      </xsl:if>
      <xsl:value-of select="$mm"/>
      <xsl:value-of select="'-'"/>
      <xsl:if test="string-length($dd) = 1">
         <xsl:value-of select="'0'"/>
      </xsl:if>
      <xsl:value-of select="$dd"/>
      <xsl:if test="$inAddTime = 'Y'">T00:00:00</xsl:if>
   </xsl:template>
</xsl:stylesheet>
