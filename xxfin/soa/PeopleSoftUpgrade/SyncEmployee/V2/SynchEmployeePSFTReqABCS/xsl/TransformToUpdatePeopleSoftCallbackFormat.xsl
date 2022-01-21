<?xml version='1.0' encoding='UTF-8'?>
<xsl:stylesheet version="1.0" xmlns:sample="http://www.oracle.com/XSL/Transform/java/com.od.security.SerializedCouponConverter" xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/" xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20" xmlns:mhdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.mediator.service.common.functions.MediatorExtnFunction" xmlns:bpel="http://docs.oasis-open.org/wsbpel/2.0/process/executable" xmlns:oraext="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dvm="http://www.oracle.com/XSL/Transform/java/oracle.tip.dvm.LookupValue" xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:med="http://schemas.oracle.com/mediator/xpath" xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath" xmlns:bpm="http://xmlns.oracle.com/bpmn20/extensions" xmlns:xdk="http://schemas.oracle.com/bpel/extension/xpath/function/xdk" xmlns:ns0="http://xmlns.oracle.com/Enterprise/Tools/services" xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions" xmlns:ns1="http://xmlns.officedepot.com/PeopleSoftMigration/UpdateEmployeeErrorCallBackPSFTProvABCS/UpdateEmployeeErrorToPSFTEBM" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:bpmn="http://schemas.oracle.com/bpm/xpath" xmlns:ora="http://schemas.oracle.com/xpath/extension" xmlns:socket="http://www.oracle.com/XSL/Transform/java/oracle.tip.adapter.socket.ProtocolTranslator" xmlns:ldap="http://schemas.oracle.com/xpath/extension/ldap" exclude-result-prefixes="xsi xsl ns0 xsd ns1 sample bpws xp20 mhdr bpel oraext dvm hwf med ids bpm xdk xref bpmn ora socket ldap">
   <xsl:template match="/">
      <ns1:UpdateEmployeeErrorToPSFTEBM>
         <xsl:for-each select="/ns0:OD_EMPDATA_ASYNC_PUB/ns0:MsgData/ns0:Transaction/ns0:OD_I0140_MSG0/ns0:OD_I0140_MSG1/ns0:OD_FIN_CONV_PUB">
            <ns1:EmployeeErrorDetails>
               <ns1:EmployeeID>
                  <xsl:value-of select="ns0:EMPLID"/>
               </ns1:EmployeeID>
               <ns1:ProcessFlag>
                  <xsl:text disable-output-escaping="no">N</xsl:text>
               </ns1:ProcessFlag>
               <ns1:ProcessDateTime>
                  <xsl:value-of select="xp20:current-dateTime()"/>
               </ns1:ProcessDateTime>
            </ns1:EmployeeErrorDetails>
         </xsl:for-each>
      </ns1:UpdateEmployeeErrorToPSFTEBM>
   </xsl:template>
</xsl:stylesheet>
