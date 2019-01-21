<!-- $Header: odbislinkhd.jsp 115.57 2006/09/11 08:09:30 sjustina noship $ -->
<%@
  page  language="java" import="oracle.apps.fnd.common.*"
  import="oracle.apps.bis.pmv.common.*"
  import="java.sql.*"
  import="oracle.jdbc.driver.OracleStatement"
  import="oracle.apps.bis.pmv.session.UserSession"
  import="oracle.apps.bis.pmv.header.HeaderBean"
  import="oracle.apps.bis.pmv.metadata.AKRegion"
  import="oracle.apps.bis.pmv.metadata.AKRegionItem"
  import="oracle.apps.bis.common.Util"
  import="oracle.apps.bis.common.ServletWrapper"
  import="oracle.apps.bis.common.UserPersonalizationUtil"
  import="od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil"
  import="od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil"
%>
<jsp:useBean id="globalMenuBean" class = "oracle.apps.bis.pmv.common.GlobalMenu" scope = "request" />
<jsp:useBean id="ODPMVUtil" class = "od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil" scope = "page" />
<%!
  //gsanap 6/25/02 comment out the duplicate declarations
  //WebAppsContext webAppsContext = null;
  //UserSession userSession;
  //Connection conn  = null;
  String mainPath = "", returnToPortalLink = "",logOutLink = "", menuLink = "";
  String defHlp = "", helpScript = "", pageTitle = "", Header = "";
  String menuText = "", returnToPortalText = "", helpText = "";
  String menuAlt = "", menuDesc = "", returnToPortalAlt = "",logOutAlt = "", returnToPortalDesc = "", logOutDesc = "", helpAlt = "", helpDesc = "";
  String showMenu = "";
  String showHelp = "";
  String browserTitle = "";
  String customHeader = "", customFooter = "";
  String header = "";
  String showHeaderLinks = "";
  String emailDesc = "";
  String emailPage = "";
  //jprabhud - 12/20/03 - Grant Delegations for Proxy User
  String delegationAlt ="", delegationDesc = "";
  //jprabhud - 07/13/04 - Bug 3763454 - Cancel button errors out
  boolean showDelegationLink = false;
  //jprabhud - 01/04/05 - Bug 4102223 - Show delegate link as appropriate if
  //profile is set to Yes (BIS_ENABLE_DELEGATE_LINK) (BIS: Enable Delegate Link)
  boolean delegateProfileEnabled = false;
  //ksadagop Export to PDF
  String exportAlt ="", exportDesc = "";
  // nbarik - 03/02/05 - Enhancement 4120795
  boolean isTab = false;
  String globalTitle = "";
  String contactAdminScript = "";

%>
<%
  //jprabhud - 07/13/04 - Bug 3763454 - Cancel button errors out
  /*
  StringBuffer backURL=new StringBuffer();
  backURL.append("&transactionid="+request.getParameter("transactionid"));
  backURL.append("&sessionid="+request.getParameter("sessionid"));
  backURL.append("&regionCode="+request.getParameter("regionCode"));
  backURL.append("&functionName="+request.getParameter("functionName"));
  backURL.append("&forceRun="+request.getParameter("forceRun"));
  backURL.append("&pFirstTime="+request.getParameter("pFirstTime"));
  backURL.append("&pMode="+request.getParameter("pMode"));
  backURL.append("&displayParameter="+request.getParameter("displayParameter"));
  backURL.append("&languageCode="+request.getParameter("languageCode"));
  backURL.append("&pCustomView="+request.getParameter("pCustomView"));
  backURL.append("&pParameters="+request.getParameter("pParameters"));
  */
  //jprabhud - 07/13/04 - Bug 3763454 - Cancel button errors out
  //jprabhud - 07/14/04 - Bug 3763373 - Delegation Link shows up once a
  //report with Delegation link has been visited - move this out of declarations
  //showDelegationLink = false;
  //jprabhud - 01/04/05 - Bug 4102223 - Show delegate link as appropriate if
  //profile is set to Yes (BIS_ENABLE_DELEGATE_LINK) (BIS: Enable Delegate Link)
  //delegateProfileEnabled = false;
  //jprabhud - 01/04/05 - Bug 4102223 - Show delegate link as appropriate if
  //profile is set to Yes (BIS_ENABLE_DELEGATE_LINK) (BIS: Enable Delegate Link)
  /*String delegateProfileValue = webAppsContext.getProfileStore().getProfile("BIS_ENABLE_DELEGATE_LINK");
  if(!StringUtil.emptyString(delegateProfileValue) && "Y".equals(delegateProfileValue))
      delegateProfileEnabled = true;*/
  defHlp = (String) webAppsContext.getSessionAttribute("defHlp");
  pageTitle = (String) webAppsContext.getSessionAttribute("pageTitle");
  if (pageTitle.equals("pageTitle"))
  	pageTitle="";
  else
    	pageTitle = ODPMVUtil.getMessage(pageTitle,webAppsContext);
  if(request.getParameter("pFirstTime")!=null) {
    emailDesc = Util.escapeGTLTHTML(ODPMVUtil.getMessage("BIS_EMAIL_PORTAL", webAppsContext), "");

    //ksadagop BugFix 3683561
    exportAlt = globalMenuBean.getExportAlt(webAppsContext);
    exportDesc =  Util.escapeGTLTHTML(globalMenuBean.getExportDesc(webAppsContext), "");

   }
  emailPage = request.getParameter("email");
  // nbarik - 03/02/05 - Enhancement 4120795
  isTab = "Y".equals(request.getParameter(PMVConstants.TAB));
  if (defHlp == null)
    defHlp = "";
  // mdamle 07/19/2002 - For jsps that are not related to a PMV report and hence
  // do not have information regarding the userSession (i.e functionName, regionCode)
  // set the header to the page title
  if (userSession != null) {
    header = HeaderBean.renderHeader(userSession,userSession.getConnection());
    AKRegion akRegion = userSession.getAKRegion();
    //serao - 10/24/02 - this is because these are set in AKRegion userSession is not null
    if (akRegion != null) {
       if(!StringUtil.emptyString(akRegion.getGlobalTitle()))
       {
        if(StringUtil.indexOf(akRegion.getGlobalTitle(), "^^", true)!=-1)
        {
          String[] titleTokens = StringUtil.tokenize(akRegion.getGlobalTitle(), "^^");
          globalTitle = Util.getMessage(titleTokens[0], titleTokens[1], webAppsContext);
        }
       }
       else
         globalTitle="";
      helpScript = globalMenuBean.getHelpScript(conn, defHlp, akRegion.getHelpTarget(), akRegion.getRegionApplicationId(), webAppsContext );
      //tmohata enh: Custom Global Links/Title For report
      if(!StringUtil.emptyString(akRegion.getGlobalMenu()))
        contactAdminScript = globalMenuBean.getContactAdminScript(userSession, webAppsContext);

      /*
      //jprabhud - 12/20/03 - Grant Delegations for Proxy User
      delegationAlt = globalMenuBean.getDelegationAlt(webAppsContext);
      delegationDesc =  Util.escapeGTLTHTML(globalMenuBean.getDelegationDesc(webAppsContext), "");

      String delegationParameter = akRegion.getDelegationParameter();
      //jprabhud - 02/05/04 - Show delegation link only if privilege is setup for delegation parameter
      String delegationParameterDim = akRegion.getDelegationParameterDim();
      AKRegionItem regionItem = null;
      //jprabhud - 02/23/04 - Pass selected value for Proxy User, Multiple privileges
      String privilege = "-1";
      //jprabhud - 02/23/04 - Pass selected value for Proxy User - Pass privilege information, label
      String label = "";
      if(!StringUtil.emptyString(delegationParameterDim)) {
        try {
          regionItem = (AKRegionItem)akRegion.getAKRegionItems().get(delegationParameterDim);
        }
        catch(Exception e) {
        }
        if(regionItem != null){
          //jprabhud - 02/23/04 - Pass selected value for Proxy User - Pass privilege information, label
          privilege = regionItem.getPrivilege();
          label = regionItem.getAttributeNameLong();
        }
      }
      //jprabhud - 02/23/04 - Pass selected value for Proxy User, Multiple privileges
      //if(privilege != -1)
      if(!"-1".equals(privilege)) {
        //jprabhud - 02/23/04 - Pass selected value for Proxy User - Pass privilege information, label
        //jprabhud - 07/13/04 - Bug 3763454 - Cancel button errors out
        //delegationLink = globalMenuBean.getDelegationLink(webAppsContext, request.getParameter("dbc"),delegationParameter, privilege,label, backURL.toString());
        showDelegationLink = true;
      }*/
    } else {
      helpScript = globalMenuBean.getHelpScript(conn, defHlp, webAppsContext.getCurrLangCode());
    }
  } else {
    header  = pageTitle;
    helpScript = globalMenuBean.getHelpScript(conn, defHlp, webAppsContext.getCurrLangCode());
  }
  browserTitle = (String)session.getValue(PMVConstants.DYNAMIC_TITLE_ATTRIB);//Enh.4895041
  if(browserTitle == null){
  browserTitle = (String) webAppsContext.getSessionAttribute("header");
  }
  String langC = webAppsContext.getCurrLangCode();
  //tmohata enh: Custom Global Links/Title For report
  String customReportTitleWithSep = "";
  customReportTitleWithSep = globalMenuBean.getCustomReportTitleWithSep(browserTitle, webAppsContext, pageContext, request);

  //ashgarg Bug Fix: 4172347
  String url =webAppsContext.getProfileStore().getProfile("APPS_FRAMEWORK_AGENT")+"/OA_MEDIA/biscghec.gif";
  if (webAppsContext.getSessionAttribute("showMenu") != null)  {
     showMenu = (String) webAppsContext.getSessionAttribute("showMenu");
     webAppsContext.setSessionAttribute("showMenu", null);
  }
  if (webAppsContext.getSessionAttribute("showHelp") != null) {
     showHelp = (String) webAppsContext.getSessionAttribute("showHelp");
     webAppsContext.setSessionAttribute("showHelp", null);
  }
  if (webAppsContext.getSessionAttribute("showHeaderLinks") != null) {
     showHeaderLinks = (String) webAppsContext.getSessionAttribute("showHeaderLinks");
     webAppsContext.setSessionAttribute("showHeaderLinks", null);
  }
  //BugFix 3272126
  if("Y".equals(emailPage) || isTab)
   showHeaderLinks = "N";
%>
<%
  menuAlt = globalMenuBean.getMenuAlt(conn);
  menuDesc =  Util.escapeGTLTHTML(globalMenuBean.getMenuDesc(conn), "");


  returnToPortalAlt = globalMenuBean.getReturnToPortalAlt(conn);
  returnToPortalDesc =  Util.escapeGTLTHTML(globalMenuBean.getReturnToPortalDesc(conn), "");


  //gsanap 6/19/02 for header modification
  logOutAlt = globalMenuBean.getlogOutAlt(conn);
  logOutDesc =  Util.escapeGTLTHTML(globalMenuBean.getlogOutDesc(conn), "");


  helpAlt = globalMenuBean.getHelpAlt(conn);
  helpDesc =  Util.escapeGTLTHTML(globalMenuBean.getHelpDesc(conn), "");


  // Get Links to Global icons
  returnToPortalLink = globalMenuBean.getReturnToPortalLink(webAppsContext);
  menuLink = globalMenuBean.getMenuLink(webAppsContext);
  logOutLink = globalMenuBean.getlogOutLink(webAppsContext);

  //gsanap 03/26/2002 added to get stylesheetname for bidi support
  //ashgarg Bug Fix: 4185409
  String styleSheetnme = ODHTMLUtil.getStyleSheetNameWithFullPath(webAppsContext);

  //ksadagop Enh.4240831 - SaveAs Feature
  String listOfViewsPopUp = "";
  /*if(userSession != null && userSession.isUserCustomization()
    && !userSession.getAKRegion().isEDW())
    listOfViewsPopUp = HTMLUtil.getListOfViewHtml(userSession);*/
  //ksadagop Enh.4760180 - Show view name in report title
  String viewName = "";
  String viewSessKey = "";
  if(userSession != null)
   {
  String regionCde = userSession.getRegionCode();
  String functionNme = userSession.getFunctionName();
  viewSessKey = UserPersonalizationUtil.getViewNameSessionKey(functionNme,regionCde);
  if(ServletWrapper.getSessionValue(pageContext, viewSessKey) != null)
    viewName = (String) ServletWrapper.getSessionValue(pageContext, viewSessKey);
  else if(ServletWrapper.getParameter(request, "userViewName") != null)
    viewName = (String) ServletWrapper.getParameter(request, "userViewName");//bug.fix.5031330
   }

  if(!StringUtil.emptyString(viewName))
    viewName = PMVConstants.BIS_EXTRAVIEWBY_LABEL_SEP + viewName;

%>
<SCRIPT>
<%=helpScript%>
<%=contactAdminScript%>
function addSpace(width,height){
document.write('<img src="/OA_HTML/cabo/images/t.gif"');
if (width!=void 0)document.write(' width="' + width + '"');if (height!=void 0)document.write(' height="' + height + '"');document.write('>');
}
</SCRIPT>
<HEAD>
<TITLE>Quick Links
</TITLE>
<META content="text/html; " http-equiv=Content-Type>
<META content="MSHTML 5.00.2614.3401" name=GENERATOR>
<%
    String tenc = webAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
    response.setContentType("text/html;charset=" + tenc);
%>
<LINK REL="stylesheet" HREF="/XXCRM_HTML/bismarli.css?1265693647719" type="text/css">

</HEAD>
<body bgcolor="#FFFFFF" link="#663300" vlink="#996633" alink="#FF6600" text="#000000">
  <!-- HEADER  SECTION ----------------------------------------------------->
<table cellpadding="0" cellspacing="0" border="0" width="100%" summary="">
  <tr>
  <td nowrap valign="top">
  <table cellpadding="0" cellspacing="2" border="0" width="1%" summary="">
  <tr>
  <%
      //nkishore_DBILogo
      String logo = webAppsContext.getProfileStore().getProfile("BIS_DBI_LOGO");

      String logoImage = "/OA_MEDIA/FNDSSCORP.gif";

      if(logo!=null && logo.length()>0)

        logoImage = "/OA_MEDIA/"+logo;

  %>
  <% if (!isTab) { //ashgarg
  %>
  <td nowrap width="1%"><img src="<%=logoImage%>" alt="<%=ODPMVUtil.getMessage("BIS_PMV_ORACLE",webAppsContext)%>" title="<%=ODPMVUtil.getMessage("BIS_PMV_ORACLE",webAppsContext)%>" width="134" height="23" border="0" id="logoimage"></td>
  <% } %>
  <td nowrap width="2%">
    <SCRIPT LANGUAGE="JavaScript">
	if (navigator.appName == "Netscape") {
		document.write('<span>');
	}
    else {
		document.write('<span style=\"position:absolute\">');
	}
  </SCRIPT>

  <%--//msaran - 12/17/04 - Bug #4057163 --%>
  <!-- tmohata enh: Custom Title for Report -->
  <span class="OraPmvHeader">
  Quick Links
  </span>
  <!--sjustina must insert the code here-->
  <!--ksadagop Enh.4240831 - SaveAs Feature-->
  <% if(!StringUtil.emptyString(listOfViewsPopUp))
  { %>
  <%=listOfViewsPopUp%>
  <% } %>
 <% if (!isTab) { %>
    <img src="/OA_HTML/cabo/images/pbs.gif" alt=""></span>
  <% } %>
  <script>addSpace('0','14')</script></td>

  </tr>
  <tr><td valign="top" nowrap colspan="2" height="17"></td></tr>
  </table>
  </td>

<%
if (!showHeaderLinks.equals("N")) {
%>

    <SCRIPT LANGUAGE="JavaScript">
    var alignAtt;
    if ("<%=langC%>" == "AR" || "<%=langC%>" == "IW")
      alignAtt = "LEFT";
    else
      alignAtt = "RIGHT";

    if (navigator.appName == "Netscape") {
      document.write('<td align=\"' + alignAtt + '\" valign=\"bottom\" style=\"padding-bottom:8px\">');
    }
    else {
      document.write('<td align=\"' + alignAtt + '\" valign=\"bottom\" style=\"position:relative;z-index:10;padding-bottom:8px\">');
    }
    </SCRIPT>


      <!-- global buttons -->



      <% globalMenuBean.initialize(webAppsContext, conn, userSession); %>
      <% globalMenuBean.setGlobalMenuHtml(showMenu, showHelp, false, showHeaderLinks); %>
      <%=globalMenuBean.getGlobalMenuHtml()%>

<!--tmohata enh: Custom Global Links for Report
     Commented this out as Button HTML is obtained from GlobalMenuBean now
      <table cellpadding="0" cellspacing="0" border="0" summary="">
        <tr>


<%
if (!showMenu.equals("N")) {
%>
          <td valign="bottom"><a href="<%=menuLink%>" id="OraPmvGlobalButtonText"><%=menuDesc%></a></td>
          <td valign="bottom"><script>addSpace('10','1')</script></td>
<%
}
%>
          <td valign="bottom"><a href="<%=returnToPortalLink%>" id="OraPmvGlobalButtonText"><%=returnToPortalDesc%></a></td>
          <td valign="bottom"><script>addSpace('10','1')</script></td>
          <td valign="bottom"><a href="<%=logOutLink%>" id="OraPmvGlobalButtonText"><%=logOutDesc%></a></td>
          <td valign="bottom"><script>addSpace('10','1')</script></td>
<%
if (!showHelp.equals("N")) {
%>
          <td valign="bottom"><a href=javascript:help_window(); id="OraPmvGlobalButtonText"><%=helpDesc%></a></td>
          <td valign="bottom"><script>addSpace('10','1')</script></td>
<%
}
%>
        </tr>
      </table>
      end commenting out -->
      <!-- end of global buttons table --> </td>
<%
}
%>
  </tr>
</table>

<% if(!StringUtil.emptyString(globalTitle)) {%>
<%=customReportTitleWithSep%>
<% } %>
</BODY>
