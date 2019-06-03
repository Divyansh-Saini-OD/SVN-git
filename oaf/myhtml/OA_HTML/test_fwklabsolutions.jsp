<%@ page
  language    = "java"
  errorPage   = "OAErrorPage.jsp"
  contentType = "text/html"
  import      = "java.io.File"
  import      = "oracle.apps.fnd.framework.webui.OAJSPHelper"
  import      = "oracle.apps.fnd.framework.webui.URLMgr"  
  import      = "oracle.apps.fnd.security.HMAC"
%>

<%! public static final String RCS_ID = "$Header: test_fwklabsolutions.jsp 115.4 2003/05/05 10:19:10 gmallesh noship $"; %>

<jsp:useBean
  id          = "sessionBean"
  class       = "oracle.apps.fnd.framework.CreateIcxSession"
  scope       = "request">
</jsp:useBean>

<%
  response.setHeader("Cache-Control", "no-cache,no-store,max-age=0"); // HTTP 1.1
  response.setHeader("Pragma", "no-cache");                           // HTTP 1.0
  response.setDateHeader("Expires", -1);                              // Prevent caching at the proxy server
  if (request.getHeader("User-Agent").indexOf("MSIE") >= 0) 
  { 
    // HTTP 1.1.  Only way to force refresh in IE.
    response.setStatus(HttpServletResponse.SC_RESET_CONTENT); 
  }

  //    Obtain the Runtime Connection directly from the Project Settings.
  //    NOTE: This option will not work under Apache/JServ. In order to run under Apache/JServ
  //    you will need to hard code these values as shown in the commented alternatives
  //    below.

  String dbcFullPathName     = OAJSPHelper.getWebAppContextInitParameter(pageContext, "DBC_FULL_PATH_NAME");
  String userName            = OAJSPHelper.getWebAppContextInitParameter(pageContext, "OA_LOGIN_USERNAME");
  String userPassword        = OAJSPHelper.getWebAppContextInitParameter(pageContext, "OA_LOGIN_PASSWORD");
  String appShortName        = OAJSPHelper.getWebAppContextInitParameter(pageContext, "OA_RESPONSIBILITY_APPS_SHORT_NAME");
  String responsibilityKey   = OAJSPHelper.getWebAppContextInitParameter(pageContext, "OA_RESPONSIBILITY_KEY");

//  String userName           = "<your user name>";
//  String userPassword       = "<your password>";
//  String appShortName       = "AK";
//  String responsibilityKey  = "FWK_TOOLBOX_TUTORIAL_LABS";

  String sessionid          = sessionBean.createSession(request, response, dbcFullPathName, userName, userPassword, appShortName, responsibilityKey);
  String transactionid      = sessionBean.createTransaction(sessionBean.mRespInfo[0], sessionBean.mRespInfo[1], sessionBean.mRespInfo[2], dbcFullPathName);
  HMAC macKey = sessionBean.getMACKey(session);
%>

<HTML>
<HEAD>
<title>Framework ToolBox Tutorial Lab Solutions</title>
<SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
  document.cookie = "OADiagnostic=1";
  document.cookie = "OADeveloperMode=1";
  document.cookie = "OABackButtonTestMode=0";
  document.cookie = "OAPassivationTestMode=0";
  document.cookie = "OAConnectionTestMode=0";
  document.cookie = "OADumpUIXTree=0";
</SCRIPT>
</HEAD>

<BODY>

<a href="<%=URLMgr.processOutgoingURL("OA.jsp?OAFunc=FWK_TBX_LABS_EMPLOYEES_S&OAPB=FWK_TOOLBOX_BRAND&OAHP=FWK_TBX_TUTORIAL_LABS_APP_S&OASF=FWK_TBX_LABS_EMPLOYEES_S&transactionid=" + transactionid, macKey) %>">Employee Search</a><br>
<a href="<%=URLMgr.processOutgoingURL("OA.jsp?OAFunc=FWK_TBX_LABS_HOME_S&OAPB=FWK_TOOLBOX_BRAND&OAHP=FWK_TBX_TUTORIAL_LABS_APP_S&OASF=FWK_TBX_LABS_HOME_S&transactionid=" + transactionid, macKey) %>">Home</a><br>
<a href="<%=URLMgr.processOutgoingURL("OA.jsp?page=/oracle/apps/fnd/framework/toolbox/labsolutions/webui/DebugLabSearchPG&transactionid=" + transactionid, macKey) %>">Debug Lab</a><br>
<a href="<%=URLMgr.processOutgoingURL("OA.jsp?page=/oracle/apps/fnd/framework/toolbox/labsolutions/webui/GanttPG&transactionid=" + transactionid, macKey) %>">Gantt Chart Lab</a><br>
<a href="<%=URLMgr.processOutgoingURL("OA.jsp?page=/oracle/apps/fnd/framework/toolbox/labsolutions/webui/GraphPG&transactionid=" + transactionid, macKey) %>">Graphs Lab</a><br>
<a href="<%=URLMgr.processOutgoingURL("OA.jsp?page=/oracle/apps/fnd/framework/toolbox/labsolutions/webui/ItemSearchPG&transactionid=" + transactionid, macKey) %>">Flexfields Lab</a><br>
<a href="<%=URLMgr.processOutgoingURL("OA.jsp?page=/oracle/apps/fnd/framework/toolbox/labsolutions/webui/ConfigHomePG&transactionid=" + transactionid, macKey) %>">Configurable Home Page Lab</a><br>



</BODY>
</HTML>
