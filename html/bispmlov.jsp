<!-- $Header: bispmlov.jsp 115.129 2007/10/04 16:54:40 asverma noship $ -->

<!-- 
 +===========================================================================+
 |      Copyright (c) 2002 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  FILENAME                                                                 |
 |      bispmlov.jsp                                                         |
 |  DESCRIPTION                                                              |
 |            This jsp handles the LOV                                       |     
 |  HISTORY                                                                  |
 |   07/21/04   nbarik   Bug Fix 3676944                                     |
 |   08/25/04   nkishore Bug Fix 3823349                                     |
 |   09/01/04   ashgarg  Bug Fix: 3855463                                    | 
 |   09/08/04   ppalpart Bug Fix: 3875740                                    | 
 |   11/30/04   ksadagop Bug Fix: 4036123                                    | 
 |   10/28/05   ugodavar Bug Fix: 4581610                                    | 
 +===========================================================================+
-->
<%@
  page language="java" import="java.sql.*"
  import="java.text.*"
  import="com.sun.java.util.collections.ArrayList"
  import="com.sun.java.util.collections.HashMap"
  import="com.sun.java.util.collections.Set"
  import="com.sun.java.util.collections.Iterator"
  import="java.util.Hashtable"
  import="oracle.jdbc.driver.OracleStatement"
  import="oracle.apps.fnd.common.*"
  import="oracle.apps.fnd.util.dateFormat.*"
  import="oracle.apps.bis.msg.MessageLog"
  import="oracle.apps.bis.common.Util"
  import="oracle.apps.bis.parameters.*"
  import="oracle.apps.bis.pmv.common.*"
  import="oracle.apps.bis.pmv.lov.*"
  import="oracle.apps.bis.pmv.session.UserSession"
  import="oracle.apps.bis.pmv.metadata.*"  
  import="oracle.apps.bis.pmv.parameters.*"
  import="oracle.apps.bis.database.JDBCUtil"
  import="oracle.apps.bis.table.LovTableHelper"
  import = "oracle.cabo.share.url.EncoderUtils"  
  import = "oracle.apps.bis.common.ServletWrapper"  
%>

<%
  UserSession userSession = (UserSession)pageContext.getSession().getValue("PMV_USER_SESSION");
  userSession.setPageContext(pageContext);

  AKRegion akRegion = userSession.getAKRegion();
  //AKRegion akRegion = (AKRegion)pageContext.getSession().getValue("PMV_AKREGION");
  String p_region_code = akRegion.getRegionCode();

  WebAppsContext webAppsContext = userSession.getWebAppsContext();
  Connection conn = userSession.getConnection();

  PMVNLSServices nlsServices = userSession.getNLSServices();
  
  String p_resp_id = userSession.getResponsibilityId();
  String txnId = userSession.getTransactionId();  
  String l_image_directory = userSession.getImageServer();

  String dbc = webAppsContext.getDatabaseId();
  String enc = webAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
  response.setContentType("text/html;charset=" + enc);
  //ksadagop BugFix#3553136
  boolean isNLSLanguage = false;
  int len = PMVUtil.getMessage("BIS_PREVIOUS", webAppsContext).length();
  //ksadagop BugFix#3553136
  String curL = webAppsContext.getCurrLangCode();
  if (!StringUtil.emptyString(curL) && (curL.equals("AR") || curL.equals("IW"))) 
    isNLSLanguage = true;  
try {  

  String selectMsg = PMVUtil.getMessage("BIS_SELECT", webAppsContext);
  MessageLog PmvMsgLog = null;
  int logLevel = Integer.MAX_VALUE;     //random max number
  String viewLogLink = "";
  String viewLogLinkName = StringUtil.nonNull(PMVUtil.getMessage("PMV_VIEW_LOG_HEADING", webAppsContext)) ;
  if ("".equals(viewLogLinkName)) viewLogLinkName = "View Log" ;
   //---------------------------New Error Logging----------------------------------------//  
    boolean isLoggingEnabled = false;
    String fndLogEnabled = webAppsContext.getProfileStore().getProfile("AFLOG_ENABLED");
    String fndLogModule = webAppsContext.getProfileStore().getProfile("AFLOG_MODULE");
    String bisLogEnabled = webAppsContext.getProfileStore().getProfile("BIS_PMF_DEBUG");
    if ( ("Y".equals(bisLogEnabled) || "Y".equals(fndLogEnabled)) && ("BIS%").equalsIgnoreCase(fndLogModule))
      isLoggingEnabled = true;
    try {
      if (isLoggingEnabled) {//BugFix 3691322--View Log to be shown on log enabled       
        PmvMsgLog = MessageLog.newLog(userSession.getSessionId() + "l" + p_region_code, MessageLog.REPORT, webAppsContext);    
        if(PmvMsgLog != null) {
          logLevel = PmvMsgLog.getLevel(); 
          PmvMsgLog.newProgress(PMVConstants.PRG_TOTAL_LOV);
          if (logLevel == MessageLog.PERFORMANCE) {
            PmvMsgLog.logMessage(PMVConstants.PRG_TOTAL_LOV, "LOV Total Rendering Process", logLevel);
          }
          // nbarik - 07/21/04 - Bug Fix 3676944          
          if (logLevel == MessageLog.ERROR || logLevel == MessageLog.PERFORMANCE) {
            JDBCUtil.setSqlTrace(conn, 8);
            PmvMsgLog.logMessage(PMVConstants.PRG_TOTAL_LOV, "The trace file name is : "+ JDBCUtil.getSPID(conn), logLevel);
          }
        }  
      }
    } catch (Exception msge) {}

  // nbarik - 08/16/04 - Bug Fix 3834420
  //parameter redesign
  //UserSession userSession = new UserSession(p_region_code, p_region_code, webAppsContext, null, conn, PmvMsgLog);
  //gsanap 03/26/03 added to get stylesheetname for bidi support
  String styleSheet = HTMLUtil.getStyleSheetName(webAppsContext);
  //String langCode = webAppsContext.getCurrLangCode();
  PreparedStatement ps = null;
  ResultSet rs = null;
  int l_index1 = 0;
  int l_index2 = 0;
  int l_diff = 10;
  int l_data_count = 0;
  int l_lower_bound = 0;
  int l_upper_bound = 10;
  int l_lower_label = 0;
  int l_row_num = 1;
  boolean bSearchConducted = false; //if there was a search conducted

  String l_sql = "";
  String l_lov_sql = "";
  String l_lov_value_id = "";
  String l_lov_value = "";
  String l_param_label = "";
  String l_where_clause = "";
  String l_attribute_code = "";
  String l_attribute2 = "";
  String l_box_name = "";
  String l_box_type = "";

  PMVParameterForm pmvForm = (PMVParameterForm)pageContext.getSession().getValue("PMV_PARAM_FORM");
  String p_org_name = pmvForm.getOrgName();
  String p_org_value = pmvForm.getOrgId();
  String p_param_name = pmvForm.getParamSelected();
  String[] pParamIds = pmvForm.getParamIds();
  String[] pParamValues = pmvForm.getParamValues();
  
  String[] pAttrCode = pmvForm.getParamNames();
  String[] pAttrValue = new String[pAttrCode.length];
  String initialValue = "";
  String  initialIds = "";
  for (int i=0; i<pAttrCode.length; i++)
  {
    if (pAttrCode[i].equals(p_param_name)){
      initialValue = pParamValues[i];
      initialIds = pParamIds[i];
      }
    if(PMVConstants.ALL.equals(pParamIds[i]))
    {
      pParamIds[i] = PMVConstants.ALL_VALUE;
      }
    pAttrValue[i] = LookUpHelper.encodeIdValue(pParamIds[i], pParamValues[i]);
  }  
  
  String p_lov_type = "";
  if (p_param_name.startsWith(PMVConstants.OLTP_TIME+"+")
    ||p_param_name.startsWith(PMVConstants.EDW_TIME+"+"))
  {
    p_lov_type = "TIME";
    if (p_param_name.endsWith("_FROM"))
      p_param_name = p_param_name.substring(0, p_param_name.indexOf("_FROM"));
    else if (p_param_name.endsWith("_TO"))
      p_param_name = p_param_name.substring(0, p_param_name.indexOf("_TO"));
  }

  AKRegionItem selectedItem = (AKRegionItem)akRegion.getAKRegionItems().get(p_param_name);
  boolean perfLov = selectedItem.isLongList();
  boolean isSingleSelect = userSession.isSingleLovMode();
  l_param_label = selectedItem.getAttributeNameLong();
  l_where_clause = selectedItem.getLovWhereClause();

  String allMsg = PMVUtil.getMessage("BIS_ALL",webAppsContext);

  String p_param_description = request.getParameter("p_param_description");
  if ("^*^FIRST^*^".equals(p_param_description))
    p_param_description = initialValue;

  if(perfLov && allMsg.equalsIgnoreCase(p_param_description))//Bug.Fix.4581610, msaran:5393772 - we should check against transtaled "All"
  {
    p_param_description = "";
  }

  String p_search_mode = request.getParameter("p_search_mode");  
  p_search_mode = (p_search_mode == null) ? "SET" : p_search_mode;
  if("ALL".equals(p_search_mode) || "SET".equals(p_search_mode))
  	  pageContext.getSession().removeValue("finalReached");

  boolean finalReached = "Y".equals((String)pageContext.getSession().getValue("finalReached"))?true:false;
  String p_lower_bound = request.getParameter("p_lower_bound");
  p_lower_bound = (p_lower_bound == null) ? "0" : p_lower_bound;  
  String p_upper_bound = request.getParameter("p_upper_bound");  
  p_upper_bound = (p_upper_bound == null) ? "10" : p_upper_bound;  
  String p_last_checked_value = request.getParameter("p_last_checked_value");
  String p_last_checked_id = request.getParameter("p_last_checked_id");
  if(p_last_checked_value == null && !allMsg.equals(initialValue)) //msaran:4498744 & 5390631: condition for "All"
    p_last_checked_value = "^^"+initialValue; //msaran:4498744: Need to add "^^" before the value

  if(p_last_checked_id == null && !allMsg.equals(initialValue)) //msaran:4498744 & 5390631: condition for "All"
    p_last_checked_id = initialIds; 
  p_last_checked_value = (p_last_checked_value == null) ? "" : p_last_checked_value;  
  p_last_checked_id = (p_last_checked_id == null) ? "" : p_last_checked_id;  

  //msaran - for finding the checked values - Tracked as Bug #4231871
  // nbarik - 04/03/06 - Bug Fix 4601458
  ArrayList checkedValues = LovTableHelper.getLastCheckedValues(p_last_checked_value);

     if (isSingleSelect) {
       l_box_name = "LovRadiobox";
       l_box_type = "radio";
     } else {
       l_box_name = "LovCheckbox";
       l_box_type = "checkbox";
     }

  Lov lovObj = null;
  StringBuffer lovTableContent = new StringBuffer(4000);
  int countIndex = 0;
  //BugFix 3131287--Pass AKRegion Object
  if ( (!perfLov) || ( perfLov && LovUtil.isSearchStringValid(p_param_description) )){

    lovObj = new Lov(webAppsContext, p_param_name, p_param_description, p_region_code, p_resp_id, p_org_name, p_org_value, p_lov_type, akRegion, PmvMsgLog);
    // nbarik - 08/16/04 - Bug Fix 3834420   
    lovObj.setUserSession(userSession);
    lovObj.setLovSQL(true, l_where_clause, pAttrCode, pAttrValue);
    lovObj.isFromLovJsp(true);
    try {
      ps = lovObj.getPreparedStatement();
      OracleStatement ostmt = (OracleStatement) ps;

      if ("TIME".equals(p_lov_type))
        countIndex = 5;
      else if (lovObj.isIndentedLov())
        countIndex = 4;
      else
        countIndex = 3;

      ostmt.defineColumnType(countIndex, java.sql.Types.NUMERIC,10);

      try 
      {
          if (PmvMsgLog != null && (logLevel == MessageLog.ERROR || logLevel == MessageLog.PERFORMANCE)) {
            PmvMsgLog.newProgress(PMVConstants.PRG_LOV_RENDER);
            if (logLevel == MessageLog.PERFORMANCE) {
              PmvMsgLog.logMessage(PMVConstants.PRG_LOV_RENDER, "LOV Rendering Process", logLevel);
            }
          }
      } catch(Exception msge) {}
      rs = ps.executeQuery();
      bSearchConducted = true;
      ResultSetMetaData rsmd = rs.getMetaData();
      while (rs.next()) 
      {
        if (l_row_num == 1)
        {
          l_data_count = rs.getInt(countIndex);
         
          if (l_data_count > lovObj.getMaxFetchCount())
             l_data_count = lovObj.getMaxFetchCount();
          if ("ALL".equals(p_search_mode)) {
            l_upper_bound = l_data_count;
          } else if ("PREVIOUS".equals(p_search_mode)) {
            l_lower_bound = Integer.valueOf(p_lower_bound).intValue() - l_diff;
            l_upper_bound = Integer.valueOf(p_lower_bound).intValue();
          } else if ("NEXT".equals(p_search_mode)) {
            l_lower_bound = Integer.valueOf(p_lower_bound).intValue() + l_diff;
            l_upper_bound = Integer.valueOf(p_upper_bound).intValue() + l_diff;
          }else if ("POPLIST".equals(p_search_mode)) {
            l_lower_bound = Integer.valueOf(p_lower_bound).intValue();
            l_upper_bound = Integer.valueOf(p_upper_bound).intValue();
          }
          
          l_lower_label = l_lower_bound + 1;

          if (l_upper_bound > l_data_count) {
            l_upper_bound = l_data_count;
          }
        }

        if (l_row_num > l_lower_bound && l_row_num <= l_upper_bound) 
        {
          l_lov_value_id = rs.getString(1);

          if (rsmd.getColumnType(2) == java.sql.Types.TIMESTAMP){
            //As of Date 3094234--Use NLS Services to format date
            l_lov_value = nlsServices.dateToString(rs.getDate(2), PMVConstants.CANONICAL_JAVA_DATE_FORMAT);
            //l_lov_value = PMVUtil.formatToDatabaseDate(conn, rs.getString(2), webAppsContext); 
          }  
          else
            l_lov_value = rs.getString(2);
            //lovTableContent.append("<tr><td align=\"center\" bgcolor=\"#f7f7e7\" width=\"2%\">");
            //nkishore_lovUIChanges
            lovTableContent.append("<tr><td headers=\"SELECT\" class=\"OraPmvTableCellSelect OraPmvLovBrdr\" width=\"2%\">");
            lovTableContent.append("<LABEL id=\"").append(l_box_name).append("LABEL\" style=\"display:none\" for=\"");
            lovTableContent.append(l_box_name).append(l_row_num).append("\">").append(l_box_name).append("</LABEL>");
            lovTableContent.append("<input type=\"").append(l_box_type);
            lovTableContent.append("\" id=\"").append(l_box_name).append(l_row_num).append("\" name=\"").append(l_box_name).append("\"");

            //msaran - corrected the logic for finding the checked values - Tracked as Bug #4231871
            if((checkedValues != null) && (l_lov_value != null))
              for(int x=0; x<checkedValues.size(); x++)
                if(l_lov_value.equals(checkedValues.get(x)))
                    lovTableContent.append(" checked");

            lovTableContent.append(" value=\"").append(Util.escapeHTML(l_lov_value,"<br>")).append("\">");
            lovTableContent.append("<input type=\"hidden\" name=\"hiddenId\" value=\"").append(l_lov_value_id).append("\"></td>");
            //nkishore_lovUIChanges
            //lovTableContent.append("<td align=\"center\" bgcolor=\"#f7f7e7\" width=\"12%\">");
            lovTableContent.append("<td headers=\"QUICK_SELECT\" class=\"OraPmvTableCellSelect OraPmvLovBrdr\" width=\"15%\">");
            lovTableContent.append("<a href=\"javascript:closeWindow('").append(l_lov_value_id).append("','").append(PMVUtil.getEscapedHTML(Util.escapeHTML(l_lov_value,"<br>"))).append("')\">");
            lovTableContent.append("<img src=\"/OA_MEDIA/bisqusel.gif\"  alt=\"").append(selectMsg).append("\" border=\"0\" align=\"middle\"></a></td>");


            //lovTableContent.append("<td headers=\"VALUE\" bgcolor=\"#f7f7e7\" class=\"OraInstructionText\">");
            lovTableContent.append("<td headers=\"VALUE\" class=\"OraPmvLovText OraPmvLovBrdr\">");
            lovTableContent.append(Util.escapeHTML(l_lov_value,"<br>"));
            lovTableContent.append("</td></tr>");
          } else if (l_row_num > l_upper_bound) {
            break;
          }
          l_row_num++;
        }//end of while loop
      }//end of try
      catch (Exception e) {
        try {
            if (PmvMsgLog != null && logLevel == MessageLog.ERROR) {
            PmvMsgLog.logMessage(PMVConstants.PRG_LOV_RENDER, e.getMessage(), logLevel);
          }              
        } catch (Exception msge) {}
      }
      finally {
        if (ps != null)
          ps.close();
        if (rs != null)
          rs.close();
      } 
  }
  else{
    try {
      if (PmvMsgLog != null && logLevel == MessageLog.ERROR) {
        PmvMsgLog.logMessage(PMVConstants.PRG_TOTAL_LOV, "Perf Lov: search text entered is not valid: search text: "+ p_param_description, logLevel);
      }
    } catch(Exception msge) {}            
  }

  try {
    if (PmvMsgLog != null && logLevel == MessageLog.ERROR) {
      PmvMsgLog.logMessage(PMVConstants.PRG_TOTAL_LOV, "l_data_count: "+l_data_count+", p_search_mode: "+p_search_mode
                     +", p_lower_bound: "+p_lower_bound+", p_upper_bound: "+p_upper_bound+", l_diff: "+l_diff , logLevel);
    }
  } catch(Exception msge) {}          

 String curLovLang = webAppsContext.getCurrLangCode();
  if (l_upper_bound >= l_data_count) 
     finalReached = true; 
  int totalRows = l_upper_bound;
  if(finalReached) 
     totalRows = l_data_count;

%>

<%//@ include file="jtfincl.jsp" %>

<NOSCRIPT>
<P>This product requires use of a browser that supports JavaScript
1.2, and that you run with scripting enabled
</noscript>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html lang="<%=curLovLang%>">
<head>
<title><%=PMVUtil.getMessage("BIS_SEARCH_SELECT", webAppsContext)%> <%=PMVUtil.getMessage("BIS_LOV", webAppsContext)%></title>
<META content="MSHTML 5.00.2614.3401" name=GENERATOR>
<%=styleSheet%>
<%
out.println(JavaScriptHelper.IEorNavScript());
PMVParameters PMVParam = new PMVParameters(pageContext);
PMVParam.renderPMVScripts();
// nbarik - 04/03/06 - Bug Fix 4601458
out.println(LovTableHelper.getLovTableJavaScripts(!isSingleSelect, "searchForm", "selectForm", false));
%>
<script language="JavaScript">

<!--  ksadagop :BugFix : 3015448 -->

  function init() {
  if (!isIE) {
        document.captureEvents(Event.KEYPRESS);
        document.searchForm.p_param_description_1.onkeypress = handleEnter;
        document.selectForm.onsubmit = dummyHandleSubmit;
   }
 }
 
 function dummyHandleSubmit()
 {
  if (!isIE) {
 	return false;
  }
 }
</script>

</head>
<body onload="document.searchForm.p_param_description_1.focus();init();" bgcolor="#FFFFFF" link="#663300" vlink="#996633" alink="#FF6600" text="#000000">
<table summary="" width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr><td>
        <table summary="" width="100%" border="0" cellspacing="0" cellpadding="0">
         <tr><td class="OraPmvSearchText" colspan="2"><%=PMVUtil.getMessage("BIS_SEARCH_SELECT", webAppsContext)%>: <%=l_param_label%>
         </td></tr>
         <TR>
         <TD bgcolor="#CCCC99" height="1">
          <IMG SRC="<%=l_image_directory%>bisspace.gif" alt="" width="400" height="1"></TD>
         </TR>
        </table>
        <!--ppalpart 3356159 Lov BLAF Compliance-->
        <table summary="" border=0 cellspacing=0 cellpadding=0 WIDTH="99%">           
        <tr>
        <% if(isNLSLanguage){ %>
            <td align="left">
            <% }else{ %>
            <td align="right">
            <% } %>
			             <a href="javascript:self.close()" ; return true"">
                   <img SRC="<%=Util.generateButtonGif(PMVUtil.getMessage("BIS_CANCEL", webAppsContext), webAppsContext, application, request, pageContext, conn)%>" ALT="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_CANCEL", webAppsContext))%>" TITLE="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_CANCEL", webAppsContext))%>" border="0"></a>
                    &nbsp;&nbsp;
                   <a href="javascript:closeLovWindow()" ; return true"">
           	       <img SRC="<%=Util.generateButtonGif(selectMsg, webAppsContext, application, request, pageContext, conn)%>" ALT="<%=PMVUtil.getDoubleQuoteEscapedHTML(selectMsg)%>" TITLE="<%=PMVUtil.getDoubleQuoteEscapedHTML(selectMsg)%>" border="0"></a>
            </td>
        </tr>
        </table> 

        <table summary="" border=0 cellspacing=0 cellpadding=0 WIDTH="100%">
        <tr><td> </td></tr>
        <tr><td> </td></tr>
        <tr><td> </td></tr>
        <tr><td> </td></tr>
        <tr><td> </td></tr>
        </table>

        <table summary="" width="98%" border="0" cellspacing="0" cellpadding="0" align="right">
          <tr><td class="OraPmvSearchTxt" colspan="2"><%=PMVUtil.getMessage("BIS_SEARCH", webAppsContext)%>
          </td></tr>
          <TR>
          <TD bgcolor="#CCCC99" height="1">
            <IMG SRC="<%=l_image_directory%>bisspace.gif" alt="" width="400" height="1"></TD>
          </TR>
          <tr>
          <!-- nbarik - 09/09/03 - Enhancement 3117970 -->         
          <% if (perfLov) { %>
            <td class="OraInstructionText"><%=PMVUtil.getMessage("BIS_VALID_SEARCH_INSTR", webAppsContext)%> </td>          
          <% } else { %>          
            <td class="OraInstructionText"><%=PMVUtil.getMessage("BIS_SEARCH_INSTR", webAppsContext)%> </td>
          <% } %>                    
          </tr>
          <tr><td><br></td></tr>
          <tr>
            <td class="OraInstructionText" colspan="2" height="2">
            <form action="bispmlov.jsp" method="post" name="searchForm">
              <INPUT TYPE=hidden NAME=p_search_mode VALUE="<%=p_search_mode%>">
              <INPUT TYPE=hidden NAME=p_lower_bound VALUE="<%=l_lower_bound%>">
              <INPUT TYPE=hidden NAME=p_upper_bound VALUE="<%=l_upper_bound%>">
              <INPUT TYPE=hidden NAME=p_param_description VALUE="<%=p_param_description%>">
              <INPUT TYPE=hidden NAME=p_last_checked_value VALUE="<%=PMVUtil.getDoubleQuoteEscapedHTML(p_last_checked_value)%>">
              <INPUT TYPE=hidden NAME=p_last_checked_id VALUE="<%=p_last_checked_id%>">
              <INPUT TYPE=hidden NAME=allMsg VALUE="<%=allMsg%>">
              <!-- Fix for bug 3097587 : kiprabha : LENGTH LIMIT -->
              <INPUT TYPE=hidden NAME=bis_lov_show_err VALUE="N">

              <table summary="" border="0" cellspacing="0" cellpadding="4" width="50%">
                <tr class="OraInstructionText">
                  <td width="31%" nowrap>
                  <!--ppalpart 3356159 Lov BLAF Compliance-->
                    <div align="right"><font face="Arial, Helvetica, sans-serif" size="2"><%=PMVUtil.getMessage("BIS_SEARCH_BY", webAppsContext)%></font></div>
                  </td>
                  <td align="center" width="32%" nowrap> <font face="Arial, Helvetica, sans-serif" size="2">
                  <!--BugFix #2478129 - Changed the name of the text box. -Anoop-->
                  <!--BugFix 2632848 handle enter in search field -->                  

                  <LABEL id="p_param_description_1Label" style="display:none" for="p_param_description_1">Search Field</LABEL>
                  <%
                   
                    //bugfix 3615204
                    if (!perfLov) {
                  %>
                    <input type="text" id="p_param_description_1" name="p_param_description_1" value="<%=Util.escapeHTML(p_param_description,"<br>")%>" onKeyDown="javascript:handleEnter()" onMouseDown="javascript:handleEnter()" ></font>
                  <% }
                    else
                    {
                  %>
                        <input type="text" id="p_param_description_1" name="p_param_description_1" value="<%=Util.escapeHTML(p_param_description,"<br>")%>" onKeyDown="javascript:handleEnter()" onMouseDown="javascript:handleEnter()" ></font>
                  <%
                    }
                  %>
                  </td>
                  <!--ppalpart 3356159 Lov BLAF Compliance-->
             <td width="20%" nowrap><a href="javascript:searchFormSubmit('SET')" ; return true"">
		     <!-- Bug Fix 3015464 -->
			 <!--BugFix 3224255 escaped only double quote for alt and title-->
       <!--ppalpart 3356159 Lov BLAF Compliance-->
		     <img SRC="<%=Util.generateButtonGif(PMVUtil.getMessage("BIS_GO_REPORT", webAppsContext), webAppsContext, application, request, pageContext, conn)%>" ALT="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_GO_REPORT", webAppsContext))%>" TITLE="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_GO_REPORT", webAppsContext))%>" border="0">
                   </a></td>
                </tr>
                <!-- nbarik - 09/09/03 - Enhancement 3117970 -->   
                <% if (perfLov) { %>
                  <tr valign="baseline"> 
                    <td align="right" class="OraInstructionText">&nbsp;</td>
                    <td colspan="2" nowrap><img src="<%=l_image_directory%>bistip.gif" align="absright" alt="Filtered LOV:use one character minimum"><font size="1">&nbsp;</font><span class="OraTipLabel"><%=PMVUtil.getMessage("BIS_PMV_TIP", webAppsContext)%></span><font size="1">&nbsp;</font><span class="OraTipText" nowrap><%=PMVUtil.getMessage("BIS_PMV_LOV_TIP_DESC", webAppsContext)%></span></td>
                    <td class="OraInstructionText">&nbsp;</td>
                  </tr>               
                <% } %>                
              </table>
            </form>

             <!-- Fix for bug 3097587 : kiprabha : LENGTH LIMIT -->
            <%
              String l_show_err = request.getParameter("bis_lov_show_err") ;
              if ("Y".equals(l_show_err)) { %>
<%--            
              <table summary="" width="98%" border="0" cellspacing="0" cellpadding="0">
                <tr class="OraInstructionText">
                
                 <td class="OraInstructionText"><font color="#ff0000"><%=PMVUtil.getMessage("BIS_MULTI_LOV_ERROR", webAppsContext)%></font>
                 
                 </td>
                  
                </tr>
              </table>
              <br> 
              <br>
              <br>
--%>
							<table summary="" cellpadding="0" cellspacing="0" border="0" >
								<tr>
									<td style="background-image:url(/OA_MEDIA/biscmbts.gif);background-repeat:no-repeat" width="11" height="11">
									</td>
									<td width="100%" class="OraBGAccentDark" style="padding-right:10px">
										<table cellpadding="0" cellspacing="0" border="0" width="100%" summary="">
											<tr>
												<td rowspan="3">
													<img src="/OA_MEDIA/biserror.gif" width="18" height="18" border="0" alt=""></td><td rowspan="3" width="3">
												</td>
												<td width="100%" valign="bottom">
													<table cellpadding="0" cellspacing="0" border="0" width="100%" summary="">
														<tr>
															<td class="OraErrorHeader" style="font-size:small; margin-bottom:0px; font-weight:bold;">Error </td>
														</tr>
														<tr>
															<td class="OraBGColorDark"></td>
														</tr>
													</table>
												</td>
											</tr>
										</table>
									</td>
								</tr>
								<tr>
									<td class="OraBGAccentDark">
									</td>
									<td width="100%" class="OraBGAccentDark" style="padding:0px 10px 5px 0px">
										<div style="margin-left:21px">
											<span class="OraErrorText" style="font-size:x-small;">
											</span>
											<div style="font-family:Arial,Helvetica,Geneva,sans-serif;font-size:x-small;color:#cc0000;margin-top:5px">
												<span class="OraErrorNameText" style="font-size:x-small">
													<span class="OraErrorHeader" style="font-size:x-small; margin-bottom:0px; font-weight:bold;">Error </span>
												</span>
												<span class="OraErrorText" style="font-size:x-small;"> - <%=PMVUtil.getMessage("BIS_MULTI_LOV_ERROR", webAppsContext)%></span>
											</div>
										</div>
									</td>
								</tr>
							</table>
              <br>

            <%  }  %>
             <!-- Fix for bug 3097587 : kiprabha : LENGTH LIMIT -->

            <form name="selectForm" onsubmit="dummyHandleSubmit();">
              <table summary="" width="100%" border="0 " cellspacing="0" cellpadding="0" bordercolor="#ffffff">

               <!-- Fix for ATG Compliance bug 3299340 : gsanap : added dotted line and removed Results text -->
                <table summary="" width="98%" border="0" cellspacing="0" cellpadding="0">
                <tr><td align="left" class="OraPmvSearchTxt"><%=PMVUtil.getMessage("BIS_RESULT", webAppsContext)%></td></tr>
                <TR><td height="1" style="background-color:#cccc99" width="100%" colspan="6">
                  <img src=/OA_MEDIA/bisspace.gif alt="" height="1"></td></TR>
                   <tr><td height="2"></td></tr></table>
                
               <% if(perfLov && (!bSearchConducted)) //If this is a perf LOV and thesearch was not conducted
                  { %>
                <tr><td class="OraInstructionText"><%=PMVUtil.getMessage("BIS_NOLOV_NORESULT", webAppsContext)%>
                <br></td></tr>
          <% } %>                
                <tr><td colspan="2">
                    <table summary="" border="0" cellspacing="0" cellpadding="0" width="98%">

<% if (l_data_count > 0) { %>
                    <tr>
                        <td>
                          <table summary="" class="OraPmvTableTop" border=0 cellpadding=3 cellspacing=0 width=100%>
                            <tbody>
                            <tr valign="middle">
                   <% if ("ALL".equals(p_search_mode)) { %>
                                <td>
                                <div>
                                <a href="javascript:searchFormSubmit('SET')" ; return true"">
                                <span class="OraGlobalButtonText"><%=PMVUtil.getMessage("BIS_SHOW_SET", webAppsContext)%></span></a>
                                </div></td>
                   <% } else {
// BugFix#2595302 -remove the show all link. -ansingh
//                        if (l_data_count > l_diff) { %>
<!--                                <td>
                                <div>
                                <a href="javascript:searchFormSubmit('ALL')" ; return true"">
                                <span class="OraGlobalButtonText"><%=PMVUtil.getMessage("BIS_SHOW_ALL", webAppsContext)%></span></a>
                                </div></td>
-->
                     <% //} else { //rcmuthuk. Enh#2443853. Commented 1 line below for allowing a column for 'Select All' and 'Select None' links.
			   %>
                             <!-- <td>&nbsp;</td> -->
                     <% //}

        if (!isSingleSelect)
				{
			   %>
	
                     	 <td align="left">
	                      <div>
      	                    <span class="OraGlobalButtonText">
					   <a href="javascript:selectAll()" ; return true;"> <%=PMVUtil.getMessage("BIS_SELECT_ALL", webAppsContext)%></a>
  					   &nbsp;&nbsp|&nbsp;&nbsp
					   <a href="javascript:selectNone()" ; return true;"> <%=PMVUtil.getMessage("BIS_SELECT_NONE", webAppsContext)%></a>
					  </span>
            	          </div>
                  	 </td>
                 	   <%
                        } else {
                     %>
                          <td>&nbsp;</td>       
		         <%
                        }

                        if (l_lower_bound <= 1) { %>
                              <td align="right" width="1%"><font size=1>
                            <%  if (isNLSLanguage)
                                {    
                            %>
                                  <img align=textTop src="/OA_HTML/cabo/images/tnavnd.gif" ALT=""></font>
                           <% } else { %>                                  
                                  <img align=textTop src="/OA_HTML/cabo/images/tnavpd.gif" ALT="" ></font>                                  
                           <% } %>       
                              </td>
                              <% if(len<10){ %>
                              <td align="right" width="2%">                              
                              <% }else{%>
                              <td align="right" width="20%">
                              <% }%>
                                <div>
                                <span class="OraNavBarInactiveLink"><%=PMVUtil.getMessage("BIS_PREVIOUS", webAppsContext)%>
                                </span></div>
                              </td>
                     <% } else { %>
                              <td align="right" width="1%">
                                <a href="javascript:searchFormSubmit('PREVIOUS')" ; return true"">
                                <font size=1>
                                <!-- Bug Fix 3015464 -->
								<!--BugFix 3224255 escaped only double quote for alt and title-->
                            <%  if (isNLSLanguage)
                                {    
                            %>
                                <img align=textTop src="/OA_HTML/cabo/images/tnavn.gif" ALT="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_PREVIOUS", webAppsContext))%>" TITLE="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_PREVIOUS", webAppsContext))%>" border="0">
                            <% } else { %>
                                <img align=textTop src="/OA_HTML/cabo/images/tnavp.gif" ALT="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_PREVIOUS", webAppsContext))%>" TITLE="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_PREVIOUS", webAppsContext))%>" border="0">                                
                            <% } %>     
                                </font></a></td>
                              <% if(len<10){ %>
                              <td align="right" width="2%">                              
                              <% }else{%>
                              <td align="right" width="20%">
                              <% }%>  
                                <div>
                                <a href="javascript:searchFormSubmit('PREVIOUS')" ; return true"">
                                <span class="OraNavBarActiveLink"><%=PMVUtil.getMessage("BIS_PREVIOUS", webAppsContext)%>&nbsp;<%=l_diff%>
                                </span></a></div>
                              </td>
                     <% } %>
                              <td nowrap align="right" width="4%">
                                <div align=center>
                                <LABEL id="tablePopListUpperLabel" style="display:none" for="tablePopListUpper">Table Navigation PopList at the Top</LABEL>
                                <select id=tablePopListUpper name=tablePopListUpper class="OraPmvTblPopList" onchange="searchFormSubmit('POPLIST')">
                                <% for( int i=1;i<=totalRows;i=i+l_diff){ %>
                                <%   if(l_lower_label==i) { %>
                                  <option selected value="<%=i-1%>,<%=i+l_diff-1%>">
                                    <!-- ksadagop Bug Fix 4036123 -->
                                    <%  if (isNLSLanguage)
                                        {    
                                    %>
                                          <%= (i+l_diff-1)>l_data_count?l_data_count:(i+l_diff-1)%>-<%=i%>
                                    <% } else { %>
                                          <%=i%>-<%= (i+l_diff-1)>l_data_count?l_data_count:(i+l_diff-1)%>
                                    <% } %>       
                                  	<% if(finalReached){ %>
                                  	<%=PMVUtil.getMessage("BIS_PMV_OF", webAppsContext)%> <%=l_data_count%>
                                  	<% } %>  
                                  </option>
                                <%   }else{ %>
                                  <option value="<%=i-1%>,<%=i+l_diff-1%>">
                                    <%  if (isNLSLanguage)
                                        {    
                                    %>
                                      <%=i+l_diff-1%>-<%=i%>
                                    <% } else { %>
                                      <%=i%>-<%=i+l_diff-1%>
                                    <% } %>   
                                  	<% if(finalReached){ %>
                                  	<%=PMVUtil.getMessage("BIS_PMV_OF", webAppsContext)%> <%=l_data_count%>
                                  	<% } %>
                                  </option>
                                <% } } %>
                                  	<% if(!finalReached){ %>
                                <option value="MORE"><%= PMVUtil.getMessage("BIS_LOV_MORE", webAppsContext)%></option%>
                                  	<% } %>
                                </select>
                             <!--  <%=l_lower_label%>-<%=l_upper_bound%> <%=PMVUtil.getMessage("BIS_PMV_OF", webAppsContext)%> <%=l_data_count%> -->
                                </div>
                              </td>
                     <% if (l_upper_bound >= l_data_count) { %>
                              <% if(len<10){ %>
                              <td align="right" width="2%">                              
                              <% }else{%>
                              <td align="right" width="17%">
                              <% }%>
                                <div align=right>
                                  <% pageContext.getSession().putValue("finalReached","Y");%>
                                <span class="OraNavBarInactiveLink"><%=PMVUtil.getMessage("BIS_TABLE_NEXT", webAppsContext)%>
                                </span></div>
                              </td>
                              <td align="right" width="1%"><font size=1>
                              <%  if (isNLSLanguage)
                                {    
                              %>
                                <img align=textTop src="/OA_HTML/cabo/images/tnavpd.gif" ALT="" ></font>
                              <% } else { %>  
                                <img align=textTop src="/OA_HTML/cabo/images/tnavnd.gif" ALT="" ></font>                                
                              <% } %>  
                              </td>
                     <% } else { %>
                              <% if(len<10){ %>
                              <td align="right" width="2%">                              
                              <% }else{%>
                              <td align="right" width="17%">
                              <% }%>
                               <div align=right>
                                <a href="javascript:searchFormSubmit('NEXT')" ; return true"">
                                <span class="OraNavBarActiveLink"><%=PMVUtil.getMessage("BIS_TABLE_NEXT", webAppsContext)%>&nbsp;<%=l_diff%>
                                </span></a></div>
                              </td>
                              <td align="right" width="1%">
                                <a href="javascript:searchFormSubmit('NEXT')" ; return true"">
                                <font size=1>
                                <!-- Bug Fix 3015464 -->
								<!--BugFix 3224255 escaped only double quote for alt and title-->
                              <%  if (isNLSLanguage)
                                {    
                              %>
                                <img align=textTop src="/OA_HTML/cabo/images/tnavp.gif" ALT="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_TABLE_NEXT", webAppsContext))%>" TITLE="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_TABLE_NEXT", webAppsContext))%>" border="0">
                              <% } else { %>
                                <img align=textTop src="/OA_HTML/cabo/images/tnavn.gif" ALT="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_TABLE_NEXT", webAppsContext))%>" TITLE="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_TABLE_NEXT", webAppsContext))%>" border="0">                                
                              <% } %>  
                                </font></a>
                              </td>
                     <% }
                     } %>
                                </tr>
                            </tbody>
                          </table>
                        </td>
                      </tr>
<% } %>
                      <tr><td>
                          <table summary="LOV Table" style="border-collapse:collapse" border="0" cellpadding="1" cellspacing="0" width="100%">
                            <tr>
                              <th  id="SELECT" width="1%" nowrap class="OraPmvLovTableHdr">
                                <%=selectMsg%>
                              </th>
                              <th id="QUICK_SELECT" class="OraPmvLovTableHdr OraPmvLovBorder" width="15%"><span class="OraPmvLovSpanTextHdr">
                                <%=PMVUtil.getMessage("BIS_QUICK_SELECT", webAppsContext)%></span>
                              </th>
                              <th id="VALUE" class="OraPmvLovTabTextHdr OraPmvLovBorder"><span class="OraPmvLovSpanTextHdr">
                                <%=l_param_label%></span>
                              </th>
                            </tr>

<% if (l_data_count > 0) {%>
<%=lovTableContent.toString()%>
                    </table>
                    <input type="hidden" name="<%=l_box_name%>" value="">
                    </td>
                    </tr>

                    <tr>
                        <td>
                          <table summary="" class="OraPmvTableBottom" border=0 cellpadding=3 cellspacing=0 width=100%>
                            <tbody>
                            <tr valign="middle">
                   <% if ("ALL".equals(p_search_mode)) { %>
                              <td>
                                <div>
                                <a href="javascript:searchFormSubmit('SET')" ; return true"">
                                <span class="OraGlobalButtonText"><%=PMVUtil.getMessage("BIS_SHOW_SET", webAppsContext)%>
                                </span></a></div>
                              </td>
                   <% } else {
// BugFix#2595302 -remove the show all link. -ansingh                    
//                        if (l_data_count > l_diff) { %>
<!--                              <td>
                                <div>
                                <a href="javascript:searchFormSubmit('ALL')" ; return true"">
                                <span class="OraGlobalButtonText"><%=PMVUtil.getMessage("BIS_SHOW_ALL", webAppsContext)%>
                                </span></a></div>
                              </td>
-->
                     <% //} else { %>
                              <td>&nbsp;</td>
                     <% //}
                        if (l_lower_bound <= 1) { %>
                              <td align="right" width="1%"><font size=1>
                              <%  if (isNLSLanguage)
                                {    
                              %>
                                <img align=textTop src="/OA_HTML/cabo/images/tnavnd.gif" ALT="" ></font>
                              <% } else { %>                                
                                <img align=textTop src="/OA_HTML/cabo/images/tnavpd.gif" ALT="" ></font>                                
                              <% } %>                                                                
                              </td>
                              <% if(len<10){ %>
                              <td align="right" width="2%">                              
                              <% }else{%>
                              <td align="right" width="20%">
                              <% }%>  
                                <div>
                                <span class="OraNavBarInactiveLink"><%=PMVUtil.getMessage("BIS_PREVIOUS", webAppsContext)%>
                                </span></div>
                              </td>
                     <% } else { %>
                              <td align="right" width="1%">
                                <a href="javascript:searchFormSubmit('PREVIOUS')" ; return true"">
                                <font size=1>
                                <!-- Bug Fix 3015464 -->
								<!--BugFix 3224255 escaped only double quote for alt and title-->
                              <%  if (isNLSLanguage)
                                {    
                              %>
                                 <img align=textTop src="/OA_HTML/cabo/images/tnavn.gif" ALT="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_PREVIOUS", webAppsContext))%>" TITLE="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_PREVIOUS", webAppsContext))%>" border="0">                              
                              <% } else { %>                                 
                                 <img align=textTop src="/OA_HTML/cabo/images/tnavp.gif" ALT="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_PREVIOUS", webAppsContext))%>" TITLE="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_PREVIOUS", webAppsContext))%>" border="0">
                              <% } %>                                                                 
                                </font></a>
                              </td>
                              <% if(len<10){ %>
                              <td align="right" width="2%">                              
                              <% }else{%>
                              <td align="right" width="20%">
                              <% }%>  
                                <div>
                                <a href="javascript:searchFormSubmit('PREVIOUS')" ; return true"">
                                <span class="OraNavBarActiveLink"><%=PMVUtil.getMessage("BIS_PREVIOUS", webAppsContext)%>&nbsp;<%=l_diff%>
                                </span></a></div>
                              </td>
                     <% } %>
                              <td nowrap align="right" width="4%">
                                <div align=center>
                                <LABEL id="tablePopListLowerLabel" style="display:none" for="tablePopListLower">Table Navigation PopList at the bottom</LABEL>
                                <select id=tablePopListLower name=tablePopListLower class="OraPmvTblPopList" onchange="searchFormSubmit('POPLIST1')">
                                <% for( int i=1;i<=totalRows;i=i+l_diff){ %>
                                <%   if(l_lower_label==i) { %>
                                  <option selected value="<%=i-1%>,<%=i+l_diff-1%>">
                                  <!-- ksadagop Bug Fix 4036123 -->
                                    <%  if (isNLSLanguage)
                                      {    
                                    %>
                                      <%= (i+l_diff-1)>l_data_count?l_data_count:(i+l_diff-1)%>-<%=i%>
                                    <%   }else{ %>  
                                      <%=i%>-<%= (i+l_diff-1)>l_data_count?l_data_count:(i+l_diff-1)%>  
                                    <% } %>  
                                  	<% if(finalReached){ %>
                                  	<%=PMVUtil.getMessage("BIS_PMV_OF", webAppsContext)%> <%=l_data_count%>
                                  	<% } %>  
                                  </option>
                                <%   }else{ %>
                                  <option value="<%=i-1%>,<%=i+l_diff-1%>">
                                    <%  if (isNLSLanguage)
                                      {    
                                    %>
                                      <%=i+l_diff-1%>-<%=i%>
                                    <%   }else{ %>  
                                      <%=i%>-<%=i+l_diff-1%>  
                                    <% } %>  
                                  	<% if(finalReached){ %>
                                  	<%=PMVUtil.getMessage("BIS_PMV_OF", webAppsContext)%> <%=l_data_count%>
                                  	<% } %>
                                  </option>
                                <% } } %>
                                  	<% if(!finalReached){ %>
                                <option value="MORE"><%= PMVUtil.getMessage("BIS_LOV_MORE", webAppsContext)%></option%>
                                  	<% } %>
                                </select>


                                <!--<%=l_lower_label%>-<%=l_upper_bound%> <%=PMVUtil.getMessage("BIS_PMV_OF", webAppsContext)%> <%=l_data_count%>-->
                                </div>
                              </td>
                     <% if (l_upper_bound >= l_data_count) { %>
                              <% if(len<10){ %>
                              <td align="right" width="2%">                              
                              <% }else{%>
                              <td align="right" width="17%">
                              <% }%>  
                                <div align=right>
                                <span class="OraNavBarInactiveLink"><%=PMVUtil.getMessage("BIS_TABLE_NEXT", webAppsContext)%>
                                </span></div>
                              </td>
                              <td align="right" width="1%"><font size=1>
                              <%  if (isNLSLanguage)
                                {    
                              %>
                                <img align=textTop src="/OA_HTML/cabo/images/tnavpd.gif" ALT="" ></font>
                              <% } else { %>                                
                                <img align=textTop src="/OA_HTML/cabo/images/tnavnd.gif" ALT="" ></font>
                              <% } %>                                                                
                              </td>
                     <% } else { %>
                              <% if(len<10){ %>
                              <td align="right" width="2%">                              
                              <% }else{%>
                              <td align="right" width="17%">
                              <% }%>  
                                <div align=right>
                                <a href="javascript:searchFormSubmit('NEXT')" ; return true"">
                                <span class="OraNavBarActiveLink"><%=PMVUtil.getMessage("BIS_TABLE_NEXT", webAppsContext)%>&nbsp;<%=l_diff%>
                                </span></a></div>
                              </td>
                              <td align="right" width="1%">
                                <a href="javascript:searchFormSubmit('NEXT')" ; return true"">
                                <font size=1>
                                <!-- Bug Fix 3015464 -->
								<!--BugFix 3224255 escaped only double quote for alt and title-->
                              <%  if (isNLSLanguage)
                                {    
                              %>
                                <img align=textTop src="/OA_HTML/cabo/images/tnavp.gif" ALT="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_TABLE_NEXT", webAppsContext))%>" TITLE="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_TABLE_NEXT", webAppsContext))%>" border="0">                              
                              <% } else { %>                                
                                <img align=textTop src="/OA_HTML/cabo/images/tnavn.gif" ALT="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_TABLE_NEXT", webAppsContext))%>" TITLE="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_TABLE_NEXT", webAppsContext))%>" border="0">
                              <% } %>                                                                
                                </font></a>
                              </td>
                     <% }
                     } %>
                                </tr>
                            </tbody>
                          </table>
                        </td>
                      </tr>
<% } else { 
      try {
        if (PmvMsgLog != null && (logLevel == MessageLog.ERROR || logLevel == MessageLog.PERFORMANCE)) {    
          PmvMsgLog.closeProgress(PMVConstants.PRG_LOV_QRY);
          PmvMsgLog.newProgress(PMVConstants.PRG_LOV_RENDER);
        }
      } catch(Exception msge) {}
%>
                      <tr>
                        <td headers="SELECT" class="OraPmvTableCellSelect OraPmvLovBrdr" width="2%"><input type="hidden" name="<%=l_box_name%>" value=""> </td>
            <!--BugFix 3615204 replaced no items found with no search conducted -->
            <% if (!perfLov)
               {
            %>
                <td headers="QUICK_SELECT" class="OraPmvTableCellSelect OraPmvLovBrdr" width="30%"><%=PMVUtil.getMessage("BIS_NO_ITEMS", webAppsContext)%></td>
                <td headers="VALUE" class="OraPmvTableCellSelect OraPmvLovBrdr"> </td>
            <% }
               else
               {
                   if(bSearchConducted)
                   {%>
                <td headers="QUICK_SELECT" class="OraPmvTableCellSelect OraPmvLovBrdr" width="30%"><%=PMVUtil.getMessage("BIS_NO_ITEMS", webAppsContext)%></td>
                <td headers="VALUE" class="OraPmvTableCellSelect OraPmvLovBrdr"> </td>                   
                   <%}
                   else
                   {%>
                <td headers="QUICK_SELECT" class="OraPmvTableCellSelect OraPmvLovBrdr" width="30%"><%=PMVUtil.getMessage("BIS_NORESULTS_NOSEARCH", webAppsContext)%></td>
                <td headers="VALUE" class="OraPmvTableCellSelect OraPmvLovBrdr"> </td>
                 <%} 
               }%>
                      </tr></table></td></tr>
<% } 
      try {
        if (PmvMsgLog != null && (logLevel == MessageLog.ERROR || logLevel == MessageLog.PERFORMANCE)) {
          PmvMsgLog.closeProgress(PMVConstants.PRG_LOV_RENDER);
          PmvMsgLog.closeProgress(PMVConstants.PRG_TOTAL_LOV);
          PmvMsgLog.closeLog();
        }
      } catch(Exception msge) {}
    
%>
                    </table>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </td>
  </tr>
</table>

<!-- nbarik - 09/09/03 - Enhancement 3117970 -->   
<!--
<table summary="" width="100%" border="0" cellspacing="0" cellpadding="13">
  <tr>
    <td height="84">
-->
      <table summary="" width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td width="604">&nbsp;</td>
          <td rowspan="2" valign="bottom" width="12">
            <img src="<%=l_image_directory%>bisslghr.gif" alt="" width="12" height="14"></td></tr>                  
        <TR><TD bgcolor="#CCCC99" height="1">
          <IMG SRC="<%=l_image_directory%>bisspace.gif" alt=""  height="1" width="1"></TD></TR></table>      
      <!-- nbarik - 09/09/03 - Enhancement 3117970 -->           
      <table summary="" border=0 cellspacing=0 cellpadding=0 WIDTH="99%">           
        <tr>
          <td height="5"><img src="<%=l_image_directory%>bisspace.gif" alt="" width="1" height="1"></td>
        </tr>
        <tr>
        <% if (isNLSLanguage) { %>
          <td align="left">     
        <% }else { %>
          <td align="right">
        <% } %>
              <a href="javascript:self.close()" ; return true""><img SRC="<%=Util.generateButtonGif(PMVUtil.getMessage("BIS_CANCEL", webAppsContext), webAppsContext, application, request, pageContext, conn)%>" ALT="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_CANCEL", webAppsContext))%>" TITLE="<%=PMVUtil.getDoubleQuoteEscapedHTML(PMVUtil.getMessage("BIS_CANCEL", webAppsContext))%>" border="0"></a>
               &nbsp;&nbsp;
              <a href="javascript:closeLovWindow()" ; return true"">
      	       <img SRC="<%=Util.generateButtonGif(selectMsg, webAppsContext, application, request, pageContext, conn)%>" ALT="<%=PMVUtil.getDoubleQuoteEscapedHTML(selectMsg)%>" TITLE="<%=PMVUtil.getDoubleQuoteEscapedHTML(selectMsg)%>" border="0">
              </a></td>
        </tr>
      </table>
<!--      
    </td>
  </tr>
</table>
-->
<% 
   if (PmvMsgLog != null && (logLevel == MessageLog.ERROR || logLevel == MessageLog.PERFORMANCE)) {
      // nbarik - 07/21/04 - Bug Fix 3676944
      JDBCUtil.setSqlTrace(conn, 0);
      viewLogLink = "OA.jsp?akRegionCode=BISMSGLOGPAGE&akRegionApplicationId=191"
                      + "&dbc=" + dbc 
                      + "&transactionid=" + txnId
                      + "&LogicalName=LOV&ObjectKey=" + PmvMsgLog.getKey();
     try {
       viewLogLink = EncoderUtils.encodeURL(PMVUtil.getOAMacUrl(viewLogLink, webAppsContext), ServletWrapper.getCharacterEncoding(response), true);
     }
     catch(Exception ee) {
     }                      

%>
<table summary="" width="100%" border="0" cellspacing="0" cellpadding="13">
  <tr>
    <td>
      <a href="<%=viewLogLink%>"><%=viewLogLinkName%></a>      
    </td>  
  </tr>
</table>
<%}%>
</form>
<% } catch (Exception e) {}
finally {
  if (webAppsContext != null)
    webAppsContext.freeWebAppsContext(); 
}
%>
</body>
</html>
