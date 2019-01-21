<!-- $Header: ibuSRDetails.jsp 115.42.11510.6 2007/10/29 11:59:12 mkundali ship $  -->

<%@ include file="ibucincl.jsp" %>

<%--
+==============================================================================+
|     Copyright (c) 1999 Oracle Corporation, Redwood Shores, CA, USA           |
|                        All rights reserved.                                  |
+==============================================================================+
| FILENAME                                                                     |
|   ibuSRDetails.jsp                                                           |
| DESCRIPTION                                                                  |
|    This is the Service Request Type selection page                           |
|                                                                              |
| NOTES                                                                        |
|                                                                              |
| DEPENDENCIES                                                                 |
|                                                                              |
| HISTORY                                                                      |
|   115.0  01-SEP-2003  SPOLAMRE  Created.                                     |
|   115.1  01-OCT-2003  WMA Clean up the code and make it work as new starting |
|          version.                                                            |
|   115.4  06-OCT-2003  Modifications to get Solutions cached properly         |
|   115.5  09-OCT-2003  WMA remove the debugging message and change contact and|
|                       address as dynamical include                           |
|   115.6  09-OCT-2003  mkcyee added in changes to support attachments         |
|   115.7  13-OCT-2003  WMA change the logic, once update successfully, need to|
|                       rediect the page and refresh the content.              |
|   115.8  15-OCT-2003  WMA change the code, handle the logic for address field|
|                       and contact field correctly.                           |
|   115.9  16-OCT-2003  WMA change the codition for reopening SR.              |
|   115.10 20-OCT-2003  WMA add parameter to pass to the dynamically included  |
|                       file.                                                  |
|   115.11 21-OCT-2003  mkcyee changes to support attachment download          |
|   115.12 22-OCT-2003  WMA add the SR access checking for the SR.             |
|   115.13 23-OCT-2003  WMA avoid duplicate hidden parameter CurrentDetailsTab |
|   115.14 23-OCT-2003  mkcyee move the code that forwards to the next page    |
|                       to the bottom of the jsp so that hidden parameters     |
|                       can be renderered first; add download attachment logic |
|                       to ibuSRDetails.jsp                                    |
|   115.15 24-OCT-2003  WMA fixed the quick link problem, also add the flag    |
|                       check for those global button.                         |
|   115.16 25-OCT-2003  WMA fixed the logic so that note type, note and status |
|                       information can be carried over cross page.            |
|   115.17 27-OCT-2003  mkcyee revert the change to forward at the top of page |
|   115.18 27-OCT-2003  WMA remove the duplicate parameter IsProgressExpanded  |
|   115.19 29-OCT-2003  WMA fixed the problem that region loader does not work |
|                       for SR type and type responsibility.                   |
|                       disable the sub menu if there is only one tab          |
|   115.20 31-OCT-2003  WMA add showSolutionID field.                          |
|   115.21 31-OCT-2003  set page title to be same as window title; fix spacing |
|   115.22 05-NOV-2003  mkcyee initialize new variable fromCreateSRReview      |
|   115.23 11-NOV-2003  mkcyee call getNumber instead of getSRNumber to        |
|                       assemble page title so the number is not cached        |
|   115.24 12-NOV-2003  WMA add functions for sending Email.                   |
|   115.25 19-NOV-2003  WMA add the checking logic to ask user to confirm      |
|                       trasaction, change ibuSRResaction.jsp as dynamic includ|
|                       modify the Email to me function.                       |
|   115.26 24-NOV-2003  WMA use dynamical include for page                     |
|                       ibuSRDetailsEstCharges, ibuSRDetailsRepairs,           |
|                       ibuSRDetailsResActions, ibuSRDetailsRetShip            |
|   115.27 10-DEC-2003  WMA added the alert messages for those top buttons     |
|                       if there is pending data. add logic to handle          |
|                       confirmation message for transaction.                  |
|                       add the permission for Email  button.                  |
|   115.28 15-DEC-2003  WMA removed the comment symbol for page                |
|                       ibuSRDetailsRetShip.jsp                                |
|   115.29 16-DEC-2003  WMA fixed UI problem on Netscape, making the top button|
|                       display.                                               |
|   115.30 24-DEC-2003  MUKHAN added 2 hidden to be removed parameters         |
|                       acctnum and qPartyId reqired by Order/Return pages     |
|   115.31 08-JAN-2003  WMA change qucik link button behavor according to bug  |
|                       3358972.                                               | 
|   115.32 20-JAN-2004  WMA add the single quota check for those Javascript    |
|   115.33 26-JAN-2004  WMA add attribute IBU_CF_SR_OPEN_PAGE_INSTRUCTION.     |
|                       IBU_CF_SR_CLOSED_PAGE_INSTRUCTION.                     |
|                       change the IBU_CF_SR_DTL_CONTACT_RG to be              |
|                       IBU_CF_SR_DTL_CONTACTS_RG                              |
|   115.34 26-JAN-2004  WMA add tab bar at the bottom of SR page, fixed the    |
|                       tab bar rendering problem.                             |
|   115.35 10-FEB-2004  WMA add the single quota check for those Javascript    |
|   115.36 23-FEB-2004  WMA pass requesthandler Object to include page by using|
|                       pageContext.                                           |
|   115.37 24-FEB-2004  WMA output the region code in the html source.         |
|   115.38 12-MAR-2004  WMA change the way to construct the region key for     |
|                       sub region.                                            |
|   115.39 06-APR-2004  WMA add the iHelp.                                     |
|   115.40 04-JUN-2004  WZLI         When there is no return URL and user does |
|                                    not have access to home page, hide the    |
|                                    cancel button.                            |
|   115.41 17-JUN-2004  WMA  fixed bug 9635957, add srID in the URL to fix the |
|                       bookmark problem.                                      |
|   115.42 28-JUN-2004  WMA  added the security encrypt/decrypt functionality. |
|   115.43 04-OCT-2004  mkcyee fix bug 3851691                                 |
|   115.44 11-NOV-2004  WMA remove the 200K buffer size.                       |
|                       add close window function when user clicks on cancel   |
|                       button.                                                |
|                       add logic to handle ibuReturnURL.                      |
|   115.45 29-NOV-2004  WMA add the null checking case for getItemByCode().    |
|   115.46 30-NOV-2004  WMA add the flag check for page buttons and title.     |
|   115.42.11510.2  03-DEC-2004 WZLI This version is the copy of version 115.46|
|                                    from mainline.                            |
|   115.42.11510.3  13-MAR-2005 mkcyee fix bug 4090719                         |
|   115.42.11510.4  18-MAR-2005 mkcyee remove calls to OracleDateFormat        |
|   115.42.11510.5  1-DEC02005  WMA tune up the performance for quick link     |
|                   check.                                                     |
|   115.42.11510.6  29-OCT-2007 mkundali for bug 6493277                       |     
+==============================================================================+
--%>

<%@ page import="oracle.apps.ibu.common.RendererUtil" %>
<%@ page import="oracle.apps.ibu.common.IBUParameters" %>
<%@ page import="oracle.apps.ibu.common.IBUDateUtil" %>
<%@ page import="oracle.apps.ibu.config.ConfigItemInfo" %>
<%@ page import="oracle.apps.ibu.config.ConfigRegionKey" %>
<%@ page import="oracle.apps.ibu.config.ConfigDataLoader" %>
<%@ page import="oracle.apps.ibu.config.ConfigRegionItems" %>
<%@ page import="oracle.apps.ibu.config.ConfigPageFlow" %>
<%@ page import="oracle.apps.ibu.config.ConfigContextValuesInfo" %>
<%@ page import="oracle.apps.ibu.requests.ServiceRequestInfo" %>
<%@ page import="oracle.apps.ibu.requests.UpdateSRRequestHandler" %>
<%@ page import="oracle.apps.ibu.requests.ProgressOptions" %>
<%@ page import="oracle.apps.fnd.common.ProfileStore" %>
<%@ page import="oracle.apps.jtf.base.interfaces.MessageManagerInter" %>
<%@ page import="oracle.apps.ibu.requests.flex.IbuSRDff" %>
<%@ page import="oracle.apps.ibu.requests.flex.IbuSRFlexUtil" %>
<%@ page import="oracle.apps.jtf.jflex.FlexfieldContext"%>
<%@ page import="oracle.apps.jtf.jflex.FlexUtil"%>
<%@ page import="oracle.apps.jtf.jflex.JFlexException"%>
<%@ page import="oracle.apps.jtf.infrastructure.SecurityUtil" %>
<%@ page import="oracle.cabo.ui.beans.nav.SubTabBarBean" %>
<%@ page import="oracle.cabo.ui.beans.nav.LinkContainerBean" %>
<%@ page import="oracle.cabo.ui.beans.nav.LinkBean" %>
<%@ page import="oracle.apps.ibu.requests.Solution" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="oracle.apps.ibu.requests.StatusInfo" %>
<%@ page import="oracle.apps.ibu.requests.ServiceRequestUtilImpl" %>
<%@ page import="oracle.apps.ibu.requests.ServiceRequestImpl" %>
<%@ page import="oracle.apps.ibu.requests.Attachment" %>
<%@ page import="oracle.apps.ibu.homepage.FilterManager" %>
<%@ page import="oracle.apps.ibu.requests.ServiceRequestEmailHandler" %>
<%@ page import="java.sql.*" %>
<%@ page import="oracle.jdbc.driver.*" %>
<%@ page import="oracle.jdbc.OracleTypes" %>
<%@ page import="oracle.apps.jtf.aom.transaction.TransactionScope" %>

<%
    ibuPermissionName  = "IBU_Request_View";
%>

<%--@ page buffer="200kb" --%> 
<%@ include file = "ibucinit.jsp" %>
<%@ include file = "jtfFlexRedir.jsp" %>

<%
    pageContext.setAttribute ("ibuCHeaderFunc", "IBU_SR_CNFG_DETAILS_TOP");
    pageContext.setAttribute ("ibuCLeftFunc", "IBU_SR_CNFG_DETAILS_LEFT");
    pageContext.setAttribute ("ibuCRightFunc", "IBU_SR_CNFG_DETAILS_RIGHT");
    pageContext.setAttribute ("ibuCBottomFunc", "IBU_SR_CNFG_DETAILS_BOTTOM");
    pageContext.setAttribute ("ibuConfigOn", "y");
%>


<%
    IbuSRDff ibuSRDff;

    // mkcyee - 10/09/2003 - added to support attachments
    String nextAttachmentIndex = request.getParameter("nextAttachmentIndex");
    String numNewAttachments = request.getParameter("numNewAttachments");

    int nextAttachmentIdx = 0;
    int numNewAttach = 0;
    int iAttachmentsCount = 0;
    boolean fromCreateSR = false;
    boolean fromCreateSRReview = false;
    String formName = "SRDetails";

    ServiceRequestUtilImpl tempUtil = new ServiceRequestUtilImpl();
    ServiceRequestImpl     tempSRUtil = new ServiceRequestImpl();
    String requestNumber = request.getParameter("srID");
    long configSRTypeID =   tempUtil.fetchSRTypeID(_connection, requestNumber); 

    try
    {
        ibuSRDff = new IbuSRDff(IbuSRDff.DISPLAY_AS_TEXT);
    }
    catch(JFlexException e)
    {
        ibuSRDff = null;
    }


    String                      sLabelWidth                 = "";
    String                      sValueWidth                 = "";
    String                      sColumn1Width               = "20%";
    String                      sColumn2Width               = "25%";
    String                      sColumn3Width               = "15%";
    String                      sColumn4Width               = "40%";
    String                      sSingleColumnLabelWidth     = "20%";
    String                      sSingleColumnValueWidth     = "80%";
    int                         iCurrentColumn              = 1;
    long                        lAppID                      = (long) _context.getApplicationID();
    long                        lRespID                     = (long) _context.getRespID() ;
    long                        lRespAppID                  = (long) _context.getRespAppID();
    ConfigContextValuesInfo     configContextValuesInfo     = new ConfigContextValuesInfo(configSRTypeID, lRespID, lRespAppID, lAppID);
    ConfigRegionItems           regionItems                 = ConfigDataLoader.fetchPageItems(_connection, "IBU_SR_DETAILS", configContextValuesInfo); 
     String topRegionCode = regionItems.getRegionKey().getRegionCode();
    out.println("<!-- Detail Page Top Region Code: "+topRegionCode + "-->"); 
    long topRegionAppID = regionItems.getRegionKey().getApplicationID();

    ConfigItemInfo              itemInfo                    = null;
    ConfigRegionItems           nestedRegionItems           = null;
    ConfigRegionItems           nestedRegionItems2          = null;
    ConfigRegionKey             regionKey                   = null;
    IBUParameters               ibuParameters               = new IBUParameters(_connection);
    UpdateSRRequestHandler      requestHandler              = null;
    ServiceRequestInfo          srData                      = null;
    MessageManagerInter         msgManager                  = Architecture.getMessageManagerInstance();
    String                      sItemHelpJavascript         = "";
    boolean                     bItemRendererd              = true;
    boolean                     sectionTabRendered          = true; 
    SubTabBarBean   subTabBarBean = null;  
    int overviewtabPosition = -1; 
    int contacttabPosition = -1; 
    int attachtabPosition = -1; 
    int solutiontabPosition = -1; 
    int chargetabPosition = -1; 
    int highlightTabPosition = -1; 

    ibuParameters.context   = _context;
    requestHandler          = new UpdateSRRequestHandler(request, "IBU_SR_DETAILS", ibuParameters);

    if(request.getParameter("ibuSRDebugEmail") != null) {
     ServiceRequestEmailHandler myEmailHandler = 
     new ServiceRequestEmailHandler(request.getParameter("srID"), ibuParameters, regionItems.getRegionKey());
    String[] eMailBody =  myEmailHandler.consructSREmail(); 
    out.println(RendererUtil.hiddenField("Email Subject", eMailBody[0]));
    out.println(RendererUtil.hiddenField("Email Boddy", eMailBody[1])); 
    regionItems = ConfigDataLoader.fetchPageItems(_connection, "IBU_SR_DETAILS", configContextValuesInfo);  
    }

    // mkcyee 10/24/2003 - this is a hack put in to download
    // attachments. When embedded inside the java class, any .txt file
    // will download with a slew of trailing garbage. Talked to JTT
    // and their recommendation is to use their jtfDownload.jsp
    // instead.

    String uAction = request.getParameter("UserAction");
    if (uAction != null && uAction.equals("IBU_CF_SR_ATTACHMENT_VIEW"))
    {
      String tempDownloadFileID = request.getParameter("DownloadFileID");
      tempDownloadFileID = IBUUtil.decrypt(tempDownloadFileID);
      tempDownloadFileID = SecurityUtil.encrypt(tempDownloadFileID);
      String forwardUrl = ServletSessionManager.getURL("jtfDownload.jsp?fileid=" + tempDownloadFileID);

	 TransactionScope.releaseConnection(_connection);
%>
      <jsp:forward page="<%=forwardUrl%>" />
<%
    }


    int iRequestHandlerStatus = requestHandler.handlePageRequest();

    String actionMessage = requestHandler.getActionMessages();
    if(actionMessage!= null && !"".equals(actionMessage)){
       caboMgr.setMessage(actionMessage, CaboUtil.CONFIRMATION_MESSAGE);
    }
   
    if (iRequestHandlerStatus > 0)
    {
        String[] sMsgs = requestHandler.getMessages();

        if (iRequestHandlerStatus == 1)
        {
            for (int iIndex = 0; iIndex < sMsgs.length; iIndex++)
                caboMgr.setMessage(sMsgs[iIndex], CaboUtil.ERROR_MESSAGE); 
            //This might show only one message. Kevin might have to provide one more method.
        }
        else if (iRequestHandlerStatus == 2)
            caboMgr.setMessage(sMsgs[0], CaboUtil.WARNING_MESSAGE);
        else if (iRequestHandlerStatus == 3)
            caboMgr.setMessage(sMsgs[0], CaboUtil.CONFIRMATION_MESSAGE);
        else if (iRequestHandlerStatus >= 4 && iRequestHandlerStatus < 10){ //update success
             String newIBUReturnURL = request.getParameter("ibuReturnURL");
             String newSRID         = request.getParameter("srID");
             String newURL          = IBUUtil.getURL("IBU_SR_DETAILS") + "&srID=" + newSRID;
             String actionConfirmMessage = "";
             if(iRequestHandlerStatus == 4)
               actionConfirmMessage = "UPDATESUCCESS"; 
             if(iRequestHandlerStatus == 8 || iRequestHandlerStatus == 9) 
               actionConfirmMessage = iRequestHandlerStatus == 8 ?
                 "ADDLINKSUCCESS":"REMOVELINKSUCCESS"; 
             newURL = newURL + "&actionConfirmMessage="+actionConfirmMessage;
             if(newIBUReturnURL != null && !"".equals(newIBUReturnURL)){
                newURL = newURL+"&ibuReturnURL=" + 
                   IBUUtil.replaceStringForAll(newIBUReturnURL, "&", "%26");
             }
             response.sendRedirect(newURL);
             return; //need to do the return
        }else if(iRequestHandlerStatus == 10){
           if(_context.fetchEmployeeID(_connection, _context.getUserID())<=0){ 
            String emailsendingURL = ServletSessionManager.getURL("IbuSREmail.jsp");   
      
            TransactionScope.releaseConnection(_connection);           
%>
            <jsp:forward page="<%=emailsendingURL%>"/>
<%
         }
        }else if(iRequestHandlerStatus == 11){ //email is sent 
             String newSRID         = request.getParameter("srID");
             String newIBUReturnURL = request.getParameter("ibuReturnURL");
             String newURL = IBUUtil.getURL("IBU_SR_DETAILS") + "&srID=" + newSRID +
                "&sendEmailReturnMsg="+"success";
             if(newIBUReturnURL != null && !"".equals(newIBUReturnURL)){
                newURL = newURL+"&ibuReturnURL=" + 
                   IBUUtil.replaceStringForAll(newIBUReturnURL, "&", "%26");
             }
             response.sendRedirect(newURL);
             return; //need to do the return
        }else if(iRequestHandlerStatus == 12){ //email is failure 
            String failMessage = 
              Architecture.getMessageManagerInstance().getMessage("IBU_R_EMAIL_FAIL");
            caboMgr.setMessage(failMessage, CaboUtil.ERROR_MESSAGE);
        }
        
    }


    if (requestHandler.isRequestFromCurrentPage())
    {
        String sNextPage = requestHandler.getNextPage();
        if (sNextPage != null && sNextPage != "" )
        {
          if(sNextPage.indexOf("OA.jsp") >= 0){
             response.sendRedirect(sNextPage);
             return; 
          }
          TransactionScope.releaseConnection(_connection);
%>
            <jsp:forward page="<%=sNextPage%>"/>
<%
        }
    }

    srData          = requestHandler.getSRData();

    //here we need to add the access checking
    boolean hasAccess = requestHandler.hasAccess();
  
    ConfigItemInfo tempItemInfo1=regionItems.getItembyCode("IBU_CF_PAGE_HDR", true);
    if(tempItemInfo1 != null && tempItemInfo1.getShowFlag()) 
      ibuPageTitle    = tempItemInfo1.getPrompt() + ": " + srData.getNumber() + " - " + srData.getShortDesc();
    else
      ibuPageTitle = ""; 
%>
<% ibuHelpTarget = "IbuSRDetails";  %>
<%@ include file = "ibuchst2.jsp" %>
<%@ include file = "ibuchend.jsp" %>
<%@ include file = "ibucbst.jsp" %>
<%@ include file = "jtfFlexIncl.jsp" %>

<% //if(hasAccess){ %>
<SCRIPT language="javascript">
<% String encryptedOrgStatusID =  IBUUtil.encrypt(srData.getSRStatusID()); %> 
var isDataNotSaved = '<%=requestHandler.isDataNotSaved()?"Y":"N"%>';
<% KeyDescPair[] nextStatuses = requestHandler.getNextStatuses(); %>
var statusVar = new Array(<%=nextStatuses==null?0:nextStatuses.length+1%>);
<% int offset = 0; %>
statusVar[<%=offset++%>] = '<%=encryptedOrgStatusID%>';
<%if(nextStatuses != null){ 
   for(int i= 0; i<nextStatuses.length; i++) {
%>
statusVar[<%=offset++%>] = 
'<%=nextStatuses[i].key.equals(srData.getSRStatusID())?encryptedOrgStatusID:IBUUtil.encrypt(nextStatuses[i].key)%>';
<%}}%>

<% String pendingDataAlert = 
     Architecture.getMessageManagerInstance().getMessage("IBU_SR_DTL_PENDING_DATA_ALERT");
%>

var buttonClickCount = 0;
function buttonClicked(actionCode)
{
    if(buttonClickCount > 0)
      return; 
   <% if("Y".equals(request.getParameter("ibuCloseWindow"))) { %>
    if(actionCode == "IBU_CF_CANCEL"){
       setTimeout('window.close()', 100);
       return;
    }
   <% } %>
    with (document.SRDetails)
    {
        UserAction.value = actionCode;

        if (actionCode == 'IBU_CF_SR_REQ_ESCALATION'){
           if(isDataNotSaved == 'Y'){
              if (!confirm('<%=IBUUtil.escapeSingleQuote(pendingDataAlert)%>'))
                   return;
           }else{
              if(IBU_CF_SR_NOTE_EXISTS.value == 'Y'){
                 if(IBU_CF_SR_NOTE.value != ''){
                   if (!confirm('<%=IBUUtil.escapeSingleQuote(pendingDataAlert)%>'))
                   return;
                 }
              }
              if(IBU_CF_SR_STATUS_LIST_EXISTS.value == 'Y'){
                 if(IBU_CF_SR_STATUS_LIST.selectedIndex > 0 && 
                    statusVar[IBU_CF_SR_STATUS_LIST.selectedIndex]!=
                     statusVar[0]){
                  if (!confirm('<%=IBUUtil.escapeSingleQuote(pendingDataAlert)%>'))
                   return;
                 }
              }
           }
            
            NextPageCode.value = "IBU_SR_REQUEST_ESCALATION";
        }
        else if (actionCode == 'IBU_CF_SR_REOPEN_REQUEST'){
            if(isDataNotSaved == 'Y'){
              if (!confirm('<%=IBUUtil.escapeSingleQuote(pendingDataAlert)%>'))
                   return;
           }
            NextPageCode.value = "IBU_SR_REOPEN";
        }
        else if (actionCode == 'IBU_CF_SR_CLOSE_REQUEST'){
            if(isDataNotSaved == 'Y'){
              if (!confirm('<%=IBUUtil.escapeSingleQuote(pendingDataAlert)%>'))
                   return;
           }else{
              if(IBU_CF_SR_NOTE_EXISTS.value == 'Y'){
                 if(IBU_CF_SR_NOTE.value != ''){
                   if (!confirm('<%=IBUUtil.escapeSingleQuote(pendingDataAlert)%>'))
                   return;
                 }
              }
              if(IBU_CF_SR_STATUS_LIST_EXISTS.value == 'Y'){
                 if(IBU_CF_SR_STATUS_LIST.selectedIndex > 0 && 
                    statusVar[IBU_CF_SR_STATUS_LIST.selectedIndex]!=
                   statusVar[0]){
                  if (!confirm('<%=IBUUtil.escapeSingleQuote(pendingDataAlert)%>'))
                   return;
                 }
              }
           }
            NextPageCode.value = "IBU_SR_CLOSE";
        }
        else if (actionCode == 'IBU_CF_SR_DTL_PROGRESS_DATE')
        {
           if(FETCH_SR_PROGRESS_ORDER_DESC.value == 'true')
              FETCH_SR_PROGRESS_ORDER_DESC.value = 'false';
           else
             FETCH_SR_PROGRESS_ORDER_DESC.value = 'true';
        }else if(actionCode == 'IBU_CF_SR_EMAIL_TO_ME' ||
                 actionCode == 'IBU_CF_SR_ADD_TO_QLINK' ||
                 actionCode == 'IBU_CF_SR_REMOVE_FROM_QLINK'){
              if(isDataNotSaved == 'Y'){
              if (!confirm('<%=IBUUtil.escapeSingleQuote(pendingDataAlert)%>'))
                   return;
           }else{
              if(IBU_CF_SR_NOTE_EXISTS.value == 'Y'){
                 if(IBU_CF_SR_NOTE.value != ''){
                   if (!confirm('<%=IBUUtil.escapeSingleQuote(pendingDataAlert)%>'))
                   return;
                 }
              }
                 if(IBU_CF_SR_STATUS_LIST_EXISTS.value == 'Y'){
                  if(IBU_CF_SR_STATUS_LIST.selectedIndex > 0 && 
                    statusVar[IBU_CF_SR_STATUS_LIST.selectedIndex]!=
                    statusVar[0]){
                  if (!confirm('<%=IBUUtil.escapeSingleQuote(pendingDataAlert)%>'))
                   return;
                 }
              }
           }
        }

        if(actionCode == 'IBU_CF_SR_DTL_OVERVIEW_TAB_RG' ||
           actionCode == 'IBU_CF_SR_DTL_CONTACTS_TAB_RG' ||
           actionCode == 'IBU_CF_SR_DTL_ATTACH_TAB_RG' ||
           actionCode == 'IBU_CF_SR_DTL_RESOLN_TAB_RG' ||
           actionCode == 'IBU_CF_SR_DTL_CHARGES_TAB_RG' ||
           actionCode == 'IBU_CF_SR_DTL_OVERVIEW_TAB_RG'){
       
           elements['CurrentDetailsTab'].value = actionCode;
        }

        buttonClickCount++; 
        submit()
    }
}

</SCRIPT>
<SCRIPT language="javascript" src="ibuSRDetails.js"></SCRIPT>
<SCRIPT language="javascript" src="ibuSRDetailsAttachment.js"></SCRIPT>

<NOSCRIPT>
<P>
<%
    out.println(oracle.apps.jtf.base.resources.AOLMessageManager.getMessageSt("JTF_CAL_NO_JAVASCRIPT"));
%>
</P>
</NOSCRIPT>


<FORM name="SRDetails" action="<%=IBUUtil.getURL("IBU_SR_DETAILS")+"&srID="+requestNumber%>" method="post">
    <%out.println(FlexUtil.begin(JTFffContext));%>
<%
    pageContext.setAttribute("IncludeSRDataObjHandler", requestHandler, PageContext.REQUEST_SCOPE);
    // mkcyee - added for attachments
    iAttachmentsCount = srData.getAttachmentCount();

    //added by wei for bug fix
    if(!"true".equals(request.getParameter("AttachmentsDataCachedInPage"))){
        if(iAttachmentsCount == 0){
           Attachment[] tempAttahList = Attachment.fetchAttachments(_connection, Long.parseLong(srData.getSRID()));
           if(tempAttahList!=null && tempAttahList.length>0)
              iAttachmentsCount = tempAttahList.length;
        }
    }

    nextAttachmentIdx = Attachment.getNextAttachmentIdx(nextAttachmentIndex, numNewAttachments, iAttachmentsCount);

    out.println(Attachment.getNewAttachmentParameters(nextAttachmentIndex, numNewAttachments, iAttachmentsCount));

    try
    {
        itemInfo            = regionItems.getItembyCode("IBU_CF_PAGE_HDR", true);
	   // mkcyee 10/31/2003 - set page title to be same as window title
        caboMgr.setTitle(ibuPageTitle);

        //caboMgr.setTitle(itemInfo.getPrompt()); //set page title
        if(requestHandler.canUpdateSR()){
           itemInfo   = regionItems.getItembyCode("IBU_CF_SR_OPEN_PAGE_INSTRUCT",true);
        }
        if(requestHandler.canReopenSR()){
           itemInfo = regionItems.getItembyCode("IBU_CF_SR_CLOSED_PAGE_INSTRUCT",true);
        }
        
        if(itemInfo != null && itemInfo.getHintMessageCode()!= null && itemInfo.getShowFlag()){
         caboMgr.setInstruction(Architecture.getMessageManagerInstance().getMessage(itemInfo.getHintMessageCode()));  //set page level instructions text
        }

        itemInfo            = regionItems.getItembyCode("IBU_CF_PAGE_BUTTON_RG", true); //get page level buttons
        if(itemInfo != null && itemInfo.getShowFlag()){
            regionKey = new ConfigRegionKey(itemInfo.getSubRegionCode(), itemInfo.getSubRegionAppID());   }else{
            regionKey = new ConfigRegionKey("", -1);
       }
        out.println("<!-- IBU_CF_PAGE_BUTTON_RG : " + (itemInfo==null?"":itemInfo.getSubRegionCode()) + "-->");
        nestedRegionItems   = ConfigDataLoader.fetchRegionItemsByRegion(_connection, regionKey);

        out.println(RendererUtil.startTableRow()); 
        //check the quick information first
        FilterManager filterManager = new FilterManager();
        long srBinID = filterManager.getServiceRequestBinID(_connection,  _context.getUserID(), _context.getUserName(), 
                  _context.fetchEmployeeID(_connection, _context.getUserID()),lRespID, lAppID, null);
        boolean SRLinked = filterManager.isServiceRequestLinked(_connection, _context.getUserID(), requestNumber);

        while (nestedRegionItems.hasMoreItem()) // loop through & render all page level buttons
        {
            itemInfo = nestedRegionItems.getNextItem();
            if (!itemInfo.getShowFlag())
                 continue; 
            String sJavaScript  = "javascript:buttonClicked('" + itemInfo.getAttrCode() + "')";

            boolean renderCancelButton = true;           
            boolean hasAccessToHomePage = IBUUtil.hasAccessToFunction(_fwSession.getFWAppsContext(), "IBU_HOM_HOME");
            String  fTempReturnURL = request.getParameter("ibuReturnURL");
            if (fTempReturnURL == null) fTempReturnURL = "";
            if ("".equals(fTempReturnURL) && !hasAccessToHomePage) renderCancelButton = false;
            
            if ("IBU_CF_CANCEL".equals(itemInfo.getAttrCode()) && renderCancelButton)
            {
                caboMgr.addButton(new CaboUtil.Button(itemInfo.getAttrCode(), itemInfo.getAttrCode(), itemInfo.getPrompt(), sJavaScript, CaboUtil.CUSTOM_BUTTON));
            }
			//for bug 6493277
            if ("IBU_CF_SR_REQ_ESCALATION".equals(itemInfo.getAttrCode()) && requestHandler.canUpdateSR() && requestHandler.canEscalateRequest())
            {
                caboMgr.addButton(new CaboUtil.Button(itemInfo.getAttrCode(), itemInfo.getAttrCode(), itemInfo.getPrompt(), sJavaScript, CaboUtil.CUSTOM_BUTTON));
            }
            else if ("IBU_CF_SR_ADD_TO_QLINK".equals(itemInfo.getAttrCode()))
            {
               if(srBinID > 0 && !SRLinked)
                  caboMgr.addButton(new CaboUtil.Button(itemInfo.getAttrCode(), itemInfo.getAttrCode(), itemInfo.getPrompt(), sJavaScript, CaboUtil.CUSTOM_BUTTON));
            }
            else if ("IBU_CF_SR_REMOVE_FROM_QLINK".equals(itemInfo.getAttrCode()))
            {
                if(srBinID > 0 && SRLinked)
                  caboMgr.addButton(new CaboUtil.Button(itemInfo.getAttrCode(), itemInfo.getAttrCode(), itemInfo.getPrompt(), sJavaScript, CaboUtil.CUSTOM_BUTTON));
            }
            else if ("IBU_CF_SR_EMAIL_TO_ME".equals(itemInfo.getAttrCode()) && 
                requestHandler.canSendEmailToMe())
            {
                caboMgr.addButton(new CaboUtil.Button(itemInfo.getAttrCode(), itemInfo.getAttrCode(), itemInfo.getPrompt(), sJavaScript, CaboUtil.CUSTOM_BUTTON));
            }
            else if ("IBU_CF_SR_CLOSE_REQUEST".equals(itemInfo.getAttrCode())  && requestHandler.canUpdateSR() && requestHandler.canCloseSR() && requestHandler.getCloseFlag().equals("Y"))
            {
                caboMgr.addButton(new CaboUtil.Button(itemInfo.getAttrCode(), itemInfo.getAttrCode(), itemInfo.getPrompt(), sJavaScript, CaboUtil.CUSTOM_BUTTON));
            }
            else if ("IBU_CF_SR_UPDATE".equals(itemInfo.getAttrCode()) && requestHandler.canUpdateSR() && requestHandler.canUpdateSR())
            {
                caboMgr.addButton(new CaboUtil.Button(itemInfo.getAttrCode(), itemInfo.getAttrCode(), itemInfo.getPrompt(), sJavaScript, CaboUtil.CUSTOM_BUTTON));
            }
            else if ("IBU_CF_SR_REOPEN_REQUEST".equals(itemInfo.getAttrCode()) &&  requestHandler.canReopenSR() && requestHandler.getNextStatusFlag().equals("Y"))
            {
                caboMgr.addButton(new CaboUtil.Button(itemInfo.getAttrCode(), itemInfo.getAttrCode(), itemInfo.getPrompt(), sJavaScript, CaboUtil.CUSTOM_BUTTON));
            }
        }

        caboMgr.getHeader().render(_renderingContext);  //render page header, buttons & page level instructions
        out.println(RendererUtil.endTableRow());
        out.println(RendererUtil.endTable());
    }
    catch (Exception e)
    {
        throw e;
    }

%>

<!-- Customization Begin Added Custom Button it open new window-->
   <%

out.println(oracle.apps.jtf.base.resources.AOLMessageManager.getMessageSt("IBU_SR_STORE_PORTAL_FORM"));
%>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
 
 <table>
 <tr>
 <td>
<a href ="<%=IBUUtil.getURL("IBU_SR_DETAILS_NEW")+"&srID="+requestNumber%> ">
<img src="../XXCRM_HTML/images/bRequnkdE_Store.gif" border="0" align="absmiddle" width="116" height="18"></a>
</td>
</tr>
</html>

<!-- Customization End-->


<TABLE width="100%" border="0" cellpadding="0" cellspacing="0" summary="">
<%
    try
    {
        String sCurrentTab  = requestHandler.getCurrentDetailsTab();

        while (regionItems.hasMoreItem())
        {
            itemInfo = regionItems.getNextItem();

            //START - Include JSP to Render SR Details Common UI.
            if (itemInfo.getAttrCode().equals("IBU_CF_SR_DTL_COMMON_RG"))
            {
                if (!itemInfo.getShowFlag()) continue;

                regionKey           = new ConfigRegionKey(itemInfo.getSubRegionCode(), itemInfo.getSubRegionAppID());
                nestedRegionItems   = ConfigDataLoader.fetchRegionItemsByRegion(_connection, regionKey);
                out.println("<!--IBU_CF_SR_DTL_COMMON_RG:"+itemInfo.getSubRegionCode()+"-->");
              
                out.println(RendererUtil.startTableRow());
                out.println(RendererUtil.blankCell(4, null));
                out.println(RendererUtil.endTableRow());

%>
                <%@ include file="ibuSRDetailsCommon.jsp"%>
<%
            }
            //END   - Include JSP to Render SR Details Common UI.
            //START - Render Tabs with appropriate tab selected.
            else if (itemInfo.getAttrCode().equals("IBU_CF_SR_DTL_TABS_RG"))
            {
                regionKey           = new ConfigRegionKey(itemInfo.getSubRegionCode(), itemInfo.getSubRegionAppID());
                nestedRegionItems   = ConfigDataLoader.fetchRegionItemsByRegion(_connection, regionKey);
                out.println("<!--IBU_CF_SR_DTL_TABS_RG:"+ itemInfo.getSubRegionCode()+"-->");
                subTabBarBean   = new SubTabBarBean();
                int subTabCounter = 0; 
                while (nestedRegionItems.hasMoreItem())
                { itemInfo = nestedRegionItems.getNextItem();
                    if (!itemInfo.getShowFlag()) continue;
                    String      temptabAttrCode =  itemInfo.getAttrCode();
                    String      sJavascript     = "javascript:buttonClicked(\"" +  temptabAttrCode + "\")";
                    LinkBean    linkBean        = new LinkBean(itemInfo.getPrompt(), sJavascript);
                    subTabBarBean.addLink(linkBean);
             
                    if (sCurrentTab.equals(temptabAttrCode) && highlightTabPosition < 0)
                        highlightTabPosition = subTabCounter; 
                    subTabCounter++; 
                }

                if(subTabCounter > 1){
                  out.println(RendererUtil.blankCell(4, null));
                  out.println(RendererUtil.startTableRow());
                  out.println(RendererUtil.startCell("left", 4));
                  subTabBarBean.setSelectedIndex(highlightTabPosition); 

                  subTabBarBean.render(_renderingContext);
                  out.println(RendererUtil.endCell());
                  out.println(RendererUtil.endTableRow());
                }else{
                   sectionTabRendered = false;
                }
            }
            //END   - Render Tabs with appropriate tab selected.
        }

        itemInfo            = regionItems.getItembyCode("IBU_CF_SR_DTL_TABS_RG", false);
        if(itemInfo != null){
            regionKey = 
            new ConfigRegionKey(itemInfo.getSubRegionCode(), itemInfo.getSubRegionAppID()); 
        }else{
           regionKey = new ConfigRegionKey("", -1);
        }

        nestedRegionItems   = ConfigDataLoader.fetchRegionItemsByRegion(_connection, regionKey);

        if ("IBU_CF_SR_DTL_OVERVIEW_TAB_RG".equals(sCurrentTab))
        {
          
        }
        else if ("IBU_CF_SR_DTL_CONTACTS_TAB_RG".equals(sCurrentTab))
        {
            
        }

        else if ("IBU_CF_SR_DTL_ATTACH_TAB_RG".equals(sCurrentTab))
        {
            itemInfo = nestedRegionItems.getItembyCode("IBU_CF_SR_DTL_ATTACH_TAB_RG", true);
            if(itemInfo != null){
              regionKey 
               = new ConfigRegionKey(itemInfo.getSubRegionCode(), itemInfo.getSubRegionAppID());
            }else{
              regionKey = new ConfigRegionKey("", -1);
            }
            nestedRegionItems2  = ConfigDataLoader.fetchRegionItemsByRegion(_connection, regionKey);
            out.println("<!--IBU_CF_SR_DTL_ATTACH_TAB_RG:" + (itemInfo==null?"":itemInfo.getSubRegionCode())+"-->");
            out.println(RendererUtil.blankCell(4, null));
%>
            <%@ include file="ibuSRAttachments.jsp" %>
<%
        }
        else if ("IBU_CF_SR_DTL_RESOLN_TAB_RG".equals(sCurrentTab))
        {
            
        }
        else if ("IBU_CF_SR_DTL_CHARGES_TAB_RG".equals(sCurrentTab))
        {
          
       }
%>
<%     if(sectionTabRendered){
          out.println(RendererUtil.blankCell(4, null));
          out.println(RendererUtil.startTableRow());
          out.println(RendererUtil.startCell("left", 4));
          subTabBarBean.setSelectedIndex(highlightTabPosition);  

          subTabBarBean.render(_renderingContext);
          out.println(RendererUtil.endCell());
          out.println(RendererUtil.endTableRow());
       }
%> 

</TABLE>
<%
        caboMgr.getFooter().render(_renderingContext);  //render the page footer, page level buttons
        out.println(RendererUtil.hiddenField("UserAction", ""));
        out.println(RendererUtil.hiddenField("NextPageCode", ""));

        if(request.getParameter("CurrentDetailsTab") == null)  //do one more checking to avoid duplicate.
           out.println(RendererUtil.hiddenField("CurrentDetailsTab", requestHandler.getCurrentDetailsTab()));

        out.println(RendererUtil.hiddenField("PageCode", "IBU_SR_DETAILS"));
        out.println(RendererUtil.hiddenField("ShowContractID", ""));

        if (!srData.isSRMainDataCachedInPage())
            out.println(srData.getSRMainDataPageCache());

        out.println(RendererUtil.hiddenField("DownloadFileID", request.getParameter("DownloadFileID")));
        out.println(RendererUtil.hiddenField("IsProgressDescending", ""));
        out.println(RendererUtil.hiddenField("OldIsProgressDescending", (requestHandler.isProgressSortOrderDescending() ? "true" : "false")));
   
       if(request.getParameter("IsProgressExpanded") != null)
           out.println(RendererUtil.hiddenField("IsProgressExpanded", ""));
        out.println(RendererUtil.hiddenField("OldIsProgressExpanded", (requestHandler.isProgressExpanded() ? "true" : "false")));

        //START - Data status flags. Flags to show if data is cached in HTML page or not.
	   // mkcyee 10/09/2003 - remove for attachments
        //out.println(RendererUtil.hiddenField("AttachmentsDataCachedInPage", (srData.isAttachmentsDataCachedInPage() ? "true" : "false")));
       //removed by wei to clean up the cache.
       // out.println(RendererUtil.hiddenField("ContactsDataCachedInPage", (srData.isContactsDataCachedInPage() ? "true" : "false")));
	   // mkcyee 10/06/2003 - removed the parameter SolutionsDataCachedInPage
	   // to get Solutions cached properly
        //out.println(RendererUtil.hiddenField("SolutionsDataCachedInPage", (srData.isSolutionsDataCachedInPage() ? "true" : "false")));
         // wma remove this parameter to get cached value properly.
       // out.println(RendererUtil.hiddenField("AddressDataCachedInPage", (srData.isAddressDataCachedInPage() ? "true" : "false")));
        //END - Data status flags.

        out.println(RendererUtil.hiddenField("acctnum", ""));
        out.println(RendererUtil.hiddenField("qPartyId", ""));
%>
<!-- retain hidden parameters -->
<%
        //the following logic to added so that hidden parameter for note, note type and status 
        // can only be generated once. 
         //the following is used for Email region information
       if(request.getParameter("IBU_SR_CF_DETAIL_TOP_REGION_CODE") == null){
         out.println(RendererUtil.hiddenField("IBU_SR_CF_DETAIL_TOP_REGION_CODE",topRegionCode));
         out.println(RendererUtil.hiddenField("IBU_SR_CF_DETAIL_TOP_REGION_APPID", topRegionAppID + ""));
      }

        if(request.getParameter("ibuEmailReturnURL")== null){
          out.println(RendererUtil.hiddenField("ibuEmailReturnURL",
            "ibuSRDetails.jsp"));
        }

        out.println(RendererUtil.hiddenField("ShowSolutionID", ""));
        if ("IBU_CF_SR_DTL_OVERVIEW_TAB_RG".equals(sCurrentTab)){
          String[] toBeRemovedParameters = requestHandler.getPageParametersToBeRemoved();
          String[]  newToBeRemovedParameters = null; 
          if(toBeRemovedParameters != null && toBeRemovedParameters.length > 0){
              newToBeRemovedParameters  = new String[toBeRemovedParameters.length+8];
              for(int counter = 0; counter< toBeRemovedParameters.length; counter++){
               newToBeRemovedParameters[counter] = toBeRemovedParameters[counter];
          }
           newToBeRemovedParameters[toBeRemovedParameters.length] = "IBU_CF_SR_STATUS_LIST";
           newToBeRemovedParameters[toBeRemovedParameters.length + 1] ="IBU_CF_SR_NOTE_TYPE";
           newToBeRemovedParameters[toBeRemovedParameters.length + 2] = "IBU_CF_SR_NOTE";
           newToBeRemovedParameters[toBeRemovedParameters.length + 3] = "emailOpcode";
           newToBeRemovedParameters[toBeRemovedParameters.length + 4] = "sendEmailReturnMsg";
           newToBeRemovedParameters[toBeRemovedParameters.length + 5] = "actionConfirmMessage";
           newToBeRemovedParameters[toBeRemovedParameters.length + 6] = "acctnum";
           newToBeRemovedParameters[toBeRemovedParameters.length + 7] = "qPartyId";
          }else{
            newToBeRemovedParameters = new String[8];
            newToBeRemovedParameters[0] = "IBU_CF_SR_STATUS_LIST";
            newToBeRemovedParameters[1] = "IBU_CF_SR_NOTE_TYPE";
            newToBeRemovedParameters[2] = "IBU_CF_SR_NOTE";
            newToBeRemovedParameters[3] = "emailOpcode";   
            newToBeRemovedParameters[4] = "sendEmailReturnMsg";
            newToBeRemovedParameters[5] = "actionConfirmMessag";
            newToBeRemovedParameters[6] = "acctnum";
            newToBeRemovedParameters[7] = "qPartyId";
         }
         out.println(RendererUtil.retainRequestParameters(request,newToBeRemovedParameters ));
       }else{     
         String[] toBeRemovedParameters = requestHandler.getPageParametersToBeRemoved();
         String[]  newToBeRemovedParameters = null; 
         if(toBeRemovedParameters != null && toBeRemovedParameters.length > 0){
              newToBeRemovedParameters  = new String[toBeRemovedParameters.length+5];
              for(int counter = 0; counter< toBeRemovedParameters.length; counter++){
               newToBeRemovedParameters[counter] = toBeRemovedParameters[counter];
          }
         newToBeRemovedParameters[toBeRemovedParameters.length] = "emailOpcode";
         newToBeRemovedParameters[toBeRemovedParameters.length+1] = "sendEmailReturnMsg";
         newToBeRemovedParameters[toBeRemovedParameters.length+2] = "actionConfirmMessag";
         newToBeRemovedParameters[toBeRemovedParameters.length+3] = "acctnum";
         newToBeRemovedParameters[toBeRemovedParameters.length+4] = "qPartyId";
       }else{
         newToBeRemovedParameters = new String[5];
         newToBeRemovedParameters[0] = "emailOpcode";
         newToBeRemovedParameters[1] = "sendEmailReturnMsg";
         newToBeRemovedParameters[2] = "actionConfirmMessag";
         newToBeRemovedParameters[3] = "acctnum";
         newToBeRemovedParameters[4] = "qPartyId";
       }
        out.println(RendererUtil.retainRequestParameters(request,newToBeRemovedParameters));
    }}
    catch (Exception e)
    {
        throw e;
    }

%>
</FORM>
<% //}else{ %>
<% //} %>
<%@ include file="ibucbend.jsp" %>
