<!-- $Header: ibuSRCRConfirmation.jsp 115.9.11510.4 2005/03/14 18:36:43 mkcyee ship $ -->

<%@ include file="ibucincl.jsp" %>
<%--
+==============================================================================+
|     Copyright (c) 2003 Oracle Corporation, Redwood Shores, CA, USA           |
|                        All rights reserved.                                  |
+==============================================================================+
|  FILENAME                                                                    |
|    ibuSRCRConfirmation.jsp                                                   |
|  DESCRIPTION                                                                 |
|    This is the Create Service Request confirmation page                      |
|  NOTES                                                                       |
|                                                                              |
|  DEPENDENCIES                                                                |
|                                                                              |
|  HISTORY                                                                     |
|  115.0     21-JUL-2003  wzli       Created.                                  |
|  115.1     14-OCT-2003  wzli       Used getURL() api to get the URL for      |
|                                    action.                                   |  
|  115.2     15-OCT-2003  WZLI       Pass SR number to SR detail page instead  |
|                                    of SR id.                                 |  
|  115.3     27-OCT-2003  wzli       Changed the function name for the template|
|                                    page.                                     |  
|  115.4     30-OCT-2003  WZLI       Fixed problem: button is still shown when |
|                                    the display flag is set to false.         |   
|  115.5     30-OCT-2003  wzli       Redirect to detail page instead of        |
|                                    submitting to detail page.                | 
|  115.6     18-NOV-2003  WZLI       Integrated the email to me functionally.  |
|  115.7     04-MAR-2004  WZLI       Output region code to html source.        |
|  115.8     15-MAR-2004  WZLI       Change the way to construct the region key|
|                                    for fetching subregion.                   |  
|  115.9     05-APR-2004  WZLI       Implement iHelp                           | 
|  115.10    18-NOV-2004  WZLI       Fixed problem: type id is not passed when |
|                                    creating config context info.             |  
|  115.10    19-NOV-2004  WZLI       Fixed problem:when rendering item, the    |
|                                    show flags of some items are not checked. |
|  115.9.11510.2  03-DEC-2004 WZLI   This version is the copy of version 115.10|
|                                    from mainline.                            |
|  115.9.11510.3  28-DEC-2004 WZLI   Fixed problem: parameter ibuCloseWindow is|
|                                    not passed to detail page.                |
|  115.9.11510.4  11-MAR-2005 mkcyee fix bug 4090791        
|   26-MAY-2010  Custom code added for bottom of page 
+==============================================================================+
--%>

<%@ page import="oracle.apps.ibu.common.RendererUtil" %>
<%@ page import="oracle.apps.ibu.config.ConfigContextValuesInfo" %>
<%@ page import="oracle.apps.ibu.config.ConfigDataLoader" %>
<%@ page import="oracle.apps.ibu.config.ConfigFlowPageInfo" %>
<%@ page import="oracle.apps.ibu.config.ConfigItemInfo" %>
<%@ page import="oracle.apps.ibu.config.ConfigPageFlow" %>
<%@ page import="oracle.apps.ibu.config.ConfigRegionItems" %>
<%@ page import="oracle.apps.ibu.config.ConfigRegionKey" %>
<%@ page import="oracle.apps.ibu.requests.ServiceRequestEmailHandler" %>
<%@ page import="oracle.apps.jtf.util.GeneralPreference" %>
<%@ page import="oracle.apps.jtf.base.interfaces.MessageManagerInter" %>
<%@ page import="oracle.apps.jtf.base.resources.AOLMessageManager" %>
<%@ page import="java.sql.*" %>
<%@ page import="oracle.jdbc.driver.*" %>
<%@ page import="oracle.jdbc.OracleTypes" %>
<%@ page import="oracle.apps.jtf.aom.transaction.TransactionScope" %>


<%
  ibuPermissionName  = "IBU_Request_Create";
%>

<%@ include file="ibucinit.jsp" %>

<%

  pageContext.setAttribute("ibuCHeaderFunc", "IBU_SR_CNFG_CREATE_CNFM_TOP");
  pageContext.setAttribute("ibuCLeftFunc", "IBU_SR_CNFG_CREATE_CNFM_LEFT");
  pageContext.setAttribute("ibuCRightFunc", "IBU_SR_CNFG_CREATE_CNFM_RIGHT");
  pageContext.setAttribute("ibuCBottomFunc", "IBU_SR_CNFG_CREATE_CNFM_BOTTOM");
  pageContext.setAttribute("ibuConfigOn", "y");

  String formName="confirmation";
  
  String opcode = request.getParameter("IBU_CF_SR_OPCODE");        
  if (opcode == null) opcode = ""; 
  String originalURL = request.getParameter("IBU_CF_SR_ORIGINAL_URL");
  String fReturnURL = request.getParameter("ibuReturnURL"); 
  if (fReturnURL == null) fReturnURL = ""; 
  String ibuRedirectURL = fReturnURL;
  
  ibuRedirectURL = IBUUtil.replaceStringForAll(fReturnURL, "&", "%26");

  
  String srRequestNumber = (String)request.getAttribute("IBU_CF_SR_REQUEST_NUMBER");
  String srRequestID = (String)request.getAttribute("IBU_CF_SR_REQUEST_ID");
  if (srRequestNumber == null) srRequestNumber = "";
  String srSummar = request.getParameter("IBU_CF_SR_PROB_SUM_INPUT");
  if (srSummar == null) srSummar = "";

  boolean  emailSent = false;
  String emailStatus = (String)request.getAttribute("sendEmailReturnMsg");
  if (emailStatus != null && "success".equals(emailStatus)) emailSent = true;

  if ("".equals(srRequestNumber)) {
    srRequestNumber = request.getParameter("srID");
    if (srRequestNumber == null) srRequestNumber = "";
  }
  
  if (opcode.equals("SENDEMAIL")) {
    IBUParameters ibuParam = new IBUParameters(_connection);
    ibuParam.context   = _context;
    ServiceRequestEmailHandler srEmailHandler = new ServiceRequestEmailHandler(srRequestNumber,ibuParam);
    boolean hasEmail = srEmailHandler.hasEmailAddress();
    long userID = _context.getUserID();
    long employeeID = _context.fetchEmployeeID(_connection, userID);
    if (!hasEmail && employeeID<=0) {  
       TransactionScope.releaseConnection(_connection);
%>
        <jsp:forward page="IbuSREmail.jsp?srID=<%=srRequestNumber%>" />
<%  
    }
    else {
       String[] cSREmail = srEmailHandler.consructSREmail();
       emailSent = srEmailHandler.sendSREmail(cSREmail[0], cSREmail[1]);
    }

  }  
  if (opcode.equals("SAVEASTEMPLATE")) {
    String forwardFun= "IBU_SR_TEMP_CREATE_TEMPLATE";
    TransactionScope.releaseConnection(_connection);
%>
        <jsp:forward page="<%=IBUUtil.getURL(forwardFun)%>" />
<%  
  }
  else if (opcode.equals("GOTODETAIL")) {
    String pIBUCloseWindow = request.getParameter("ibuCloseWindow"); 
    if (pIBUCloseWindow == null || "".equals(pIBUCloseWindow)) pIBUCloseWindow = "N";
    
    String srNum = request.getParameter("srID");  
    if (srNum == null) srNum =""; 
    String detailURL = IBUUtil.getURL("IBU_SR_DETAILS") + "&srID="+ srNum + "&ibuCloseWindow="+ pIBUCloseWindow + "&ibuReturnURL=" + ibuRedirectURL;  
    TransactionScope.releaseConnection(_connection);
    response.sendRedirect(detailURL);
  }
  else if (opcode.equals("RETFROMCON")) {
    boolean[] redirectPage = new boolean[1];    
    String cmFReturnURL = IBUUtil.getReturnURL(fReturnURL, _context, redirectPage);    
    if (cmFReturnURL != null && !"".equals(cmFReturnURL)) {
      if (redirectPage != null && redirectPage[0]) {
        TransactionScope.releaseConnection(_connection);
        response.sendRedirect(cmFReturnURL);      
      }
      else {
        TransactionScope.releaseConnection(_connection); 
%>    
   <jsp:forward page="<%=cmFReturnURL%>" />
<%    
      }
    }
  }
  

  //initiate the configuration variables
  long responsiblityID = (long)_context.getRespID();
  long respAppID = (long)_context.getRespAppID();
  long applicationID = (long)_context.getApplicationID(); 
  ConfigDataLoader configMgr = new ConfigDataLoader();
  ConfigRegionKey regionKey = new ConfigRegionKey();
  ConfigItemInfo itemInfo = null;
  ConfigItemInfo subItemInfo = null;
  ConfigItemInfo subItemInfo2 = null;  
  ConfigRegionItems configItemMgr = new ConfigRegionItems();
  ConfigRegionItems buttonItems = null;  
  ConfigRegionItems subConfigItems = null; 
  ConfigRegionItems subConfigItems2 = null;         
                                                                                                                   
  String fRequestTypeID = request.getParameter("IBU_CF_SR_REQUEST_TYPE_ID");
  if (fRequestTypeID == null || "-1".equals(fRequestTypeID)) {
    fRequestTypeID = "-1";
  }
  else {
    fRequestTypeID = IBUUtil.decrypt(fRequestTypeID);
  }  

  ConfigContextValuesInfo configContextValuesInfo = new ConfigContextValuesInfo(Long.parseLong(fRequestTypeID),
                                                                                responsiblityID,
                                                                                respAppID,
                                                                                applicationID);
       
  configItemMgr = ConfigDataLoader.fetchPageItems(_connection, 
                                                  "IBU_SR_CR_CONFIRMATION", 
                                                  configContextValuesInfo);

  if (configItemMgr != null)
  { 
    String topRegionCode = configItemMgr.getRegionKey().getRegionCode();
    out.println("<!-- Top Region Code: " + topRegionCode + " -->");
  }

  if (configItemMgr != null)
  {
    itemInfo = configItemMgr.getItembyCode("IBU_CF_PAGE_HDR", true);
  } 

  if (itemInfo == null)
  {
    ibuPageTitle = "";
  } else {
    ibuPageTitle = itemInfo.getPrompt() + " " + srRequestNumber + "-" + srSummar;
  }

  String srLink = "<a href=\"javascript:goDetail()\">" + srRequestNumber + "</a>";

  String confirmationMsg =  AOLMessageManager.getMessageSt("IBU_SR_CR_SR_CONFIRMATION", "SRNUMBER", srLink);
  if (confirmationMsg == null) confirmationMsg = "";

  String saveAsTemplate = AOLMessageManager.getMessageSt("IBU_SR_SAVE_AS_TEMPLATE");
  if (saveAsTemplate == null) saveAsTemplate = "";
  
  boolean showSaveTempBTN = false;
  
  ibuHelpTarget = "IbuSRCRConfirmation"; 

%>
  
<%@ include file="ibuchst2.jsp" %>
<%@ include file="ibuchend.jsp" %>
<%@ include file="ibucbst.jsp" %>

<jsp:useBean id="profileMgr" class = "oracle.apps.ibu.requests.SRProfileMgr" 
  scope = "page" />

<script language="javascript" src="ibuSRCommon.js"></script>
<script language="javascript" src="ibuSRCreateServiceRequest.js"></script>
<script language="javascript">
function emailToMe() {
  document.confirmation.IBU_CF_SR_OPCODE.value = 'SENDEMAIL'
  document.confirmation.submit();;
}
function goDetail() {
  document.confirmation.IBU_CF_SR_OPCODE.value = 'GOTODETAIL'
  document.confirmation.submit();
}

function ibuReturn() {

<%
  if ("Y".equals(request.getParameter("ibuCloseWindow"))) {
%>
   window.close();
<%
  }
%>
  document.confirmation.IBU_CF_SR_OPCODE.value = 'RETFROMCON'
  document.confirmation.submit();
}


</script>
<NOSCRIPT>
<p>
<%
  out.println(AOLMessageManager.getMessageSt("JTF_CAL_NO_JAVASCRIPT"));
%>
</p>
</NOSCRIPT>
<%
  String currentURL = IBUUtil.getURL("IBU_SR_CR_CONFIRMATION");    
%>
<form name="confirmation" method="post" action="<%=currentURL%>">

<%
  if (emailSent) {
    caboMgr.addMessage(AOLMessageManager.getMessageSt("IBU", "IBU_SR_EMAIL_SENT_SUCCESSFULLY"));
    caboMgr.setMessage("",CaboUtil.CONFIRMATION_MESSAGE); 
  }

  out.println(RendererUtil.hiddenField("srID", srRequestNumber));  
  out.println(RendererUtil.hiddenField("IBU_CF_SR_OPCODE", opcode));
  out.println(RendererUtil.hiddenField("ibuEmailReturnURL", currentURL));
  
  if (itemInfo != null && itemInfo.getShowFlag()) {  
    //set title
    caboMgr.setTitle(ibuPageTitle);
  
    // Set instruction text
    if (itemInfo.getHintMessageCode() != null) {
      caboMgr.setInstruction(AOLMessageManager.getMessageSt(itemInfo.getHintMessageCode()));  
    }
  }  
  
  // Get the page button(s)
  if (configItemMgr != null)
  {
    itemInfo = configItemMgr.getItembyCode("IBU_CF_PAGE_BUTTON_RG", true);
    if (itemInfo != null && itemInfo.getShowFlag())
    {  
      out.println("<!-- IBU_CF_PAGE_BUTTON_RG: " + itemInfo.getSubRegionCode() + " -->");
      int navPosition = 0;
      regionKey = new ConfigRegionKey(itemInfo.getSubRegionCode(), itemInfo.getSubRegionAppID());
      buttonItems = configMgr.fetchRegionItemsByRegion(_connection, regionKey);  
      String promptStr = "";    
      subItemInfo = buttonItems.getItembyCode("IBU_CF_RETURN", true);
      if (subItemInfo != null && subItemInfo.getShowFlag()) {
        promptStr = subItemInfo.getPrompt();
        if (promptStr == null) promptStr = ""; 
        caboMgr.addButton(new CaboUtil.Button(formName, "RETURN", promptStr, "javascript:ibuReturn()", CaboUtil.CUSTOM_BUTTON));
      }

      boolean checkEmailPerm = oracle.apps.jtf.security.base.SecurityManager.check("IBU_Request_Email_To_Me");
      subItemInfo = buttonItems.getItembyCode("IBU_CF_SR_EMAIL_TO_ME", true);
      if (subItemInfo != null && checkEmailPerm && subItemInfo.getShowFlag()) {
        promptStr = subItemInfo.getPrompt();
        if (promptStr == null) promptStr = ""; 
        caboMgr.addButton(new CaboUtil.Button(formName, "EMAILTOME", promptStr, "javascript:emailToMe()", CaboUtil.CUSTOM_BUTTON));
      }
      subItemInfo = buttonItems.getItembyCode("IBU_CF_SR_SAVE_AS_TEMPLATE", true);
      boolean chechTempPerm = oracle.apps.jtf.security.base.SecurityManager.check("IBU_Request_Manage_Templates");
      if (subItemInfo != null && chechTempPerm && subItemInfo.getShowFlag()) {
        showSaveTempBTN = true;
        promptStr = subItemInfo.getPrompt();
        if (promptStr == null) promptStr = ""; 
        caboMgr.addButton(new CaboUtil.Button(formName, "SAVEASTEMPLATE", promptStr, "javascript:saveAs('"+formName+"', 'SAVEASTEMPLATE')", CaboUtil.CUSTOM_BUTTON));
      }
    }
  }  
  
  // Render the page title buttons, and instructions text
  caboMgr.getHeader().render(_renderingContext);  
%>
<!-- Customization Begin Added the Redirect to SR Update Page-->


 <%
   
 OracleConnection oracleconnection = null;
 oracleconnection = (OracleConnection)TransactionScope.getConnection();
String s1="select responsibility_id from FND_RESPONSIBILITY_VL where responsibility_name='OD Store Submission User'";
 PreparedStatement  preStatement= oracleconnection.prepareStatement(s1);
 ResultSet resultset = preStatement.executeQuery();
  while(resultset.next()) {

String Responbilty = resultset.getString(1); 
long  lRespID1  = (long) _context.getRespID() ;
String lRespID2 = Long.toString(lRespID1);  
if (lRespID2.equals(Responbilty)) 
   	{
    // String redirectURL = "ibuSRDetails.jsp?srID="+srRequestNumber;
	 String redirectURL = IBUUtil.getURL("IBU_SR_DETAILS_NEW") + "&srID="+srRequestNumber;
	  response.sendRedirect(redirectURL);
}
  }
%>



<!-- Customization End -->

<TABLE width="100%" border="0" cellpadding="0" cellspacing="0" summary="">

<%

   out.println("<tr>");
   out.println(RendererUtil.blankCell(4, null));
   out.println("</tr>");

   out.println("<tr><td colspan=\"4\" wrap class=\"prompt\">");
   out.println(confirmationMsg);
   out.println("</td></tr>");
   
   if (showSaveTempBTN) {
     out.println("<tr>");
     out.println(RendererUtil.blankCell(4, null));
     out.println("</tr>");

     out.println("<tr><td colspan=\"4\" wrap class=\"prompt\">");
     out.println(saveAsTemplate);
     out.println("</td></tr>");   
   }
%>

</TABLE>

<%    
  String[] avoidParams = new String[4];
  avoidParams[0] = "IBU_CF_SR_OPCODE";
  avoidParams[1] = "ibuEmailReturnURL";  
  avoidParams[2] = "emailOpcode"; 
  avoidParams[3] = "EmailAddress";   
  out.println(RendererUtil.retainRequestParameters(request, avoidParams));
  // render the page footer with buttons and instruction text
  caboMgr.getFooter().render(_renderingContext);  
%>

</FORM>

<%@ include file="ibucbend.jsp" %>
