<%@ page
  language    = "java"
  errorPage   = "OAErrorPage.jsp"
  contentType = "text/html"
  import      = "java.io.File"
  import      = "java.util.Properties"
  import      = "java.io.FileInputStream"  
  import      = "oracle.apps.fnd.framework.webui.OAJSPHelper"
  import      = "oracle.apps.fnd.framework.webui.URLMgr"  
  import      = "oracle.apps.fnd.security.HMAC"
%>

<%! public static final String RCS_ID = "$Header: OASvcTester.jsp 115.0 2003/05/05 10:19:10 vapuri noship $"; %>

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

  // Read the runtime params from OASvcTesterParams.txt
  
  ServletContext sc = session.getServletContext();
  String paramFile = sc.getRealPath("/OASvcTesterParams.txt");
  Properties svcTestParams = new Properties();

  try 
  {
    FileInputStream inFile = new FileInputStream(paramFile);
    svcTestParams.load(inFile);
    inFile.close();
    
  } catch (Exception ex) 
  {
    ex.printStackTrace();
  }  

  String testFileName         = svcTestParams.getProperty("testFileName");
  String serviceBeanName      = svcTestParams.getProperty("serviceBeanName");
  String action               = svcTestParams.getProperty("action");

/*
  Here are the valid values for action (Bug 4128841): 
    AddTstScrptJprCmd 
    AddTstScrptSvcCmd 
    EdtTstScrptXmlCmd 
    RunTstScrptXmlCmd 
    DbgTstScrptXmlCmd 

    From the point of view of the Testing Framework UI, it needs to distinguish
    between the three types of actions: 
    1. Edit action (Since Create, Delete always happens from the IDE)
    2. Run action
    3. Debug action
*/
  String testAction = "Edit"; // This is the default

  action = action.substring(0,3);
  if (action.equals("Run"))
    testAction = "Run";
  else if (action.equals("Dbg"))
    testAction = "Debug";

  //    Obtain the Runtime Connection directly from the Project Settings.
  //    NOTE: This option will not work under Apache/JServ. In order to run under Apache/JServ
  //    you will need to hard code these values as shown in the commented alternatives
  //    below.

  String dbcFullPathName     = OAJSPHelper.getWebAppContextInitParameter(pageContext, "DBC_FULL_PATH_NAME");
  String userName            = OAJSPHelper.getWebAppContextInitParameter(pageContext, "OA_LOGIN_USERNAME");
  String userPassword        = OAJSPHelper.getWebAppContextInitParameter(pageContext, "OA_LOGIN_PASSWORD");
  String appShortName        = OAJSPHelper.getWebAppContextInitParameter(pageContext, "OA_RESPONSIBILITY_APPS_SHORT_NAME");
  String responsibilityKey   = OAJSPHelper.getWebAppContextInitParameter(pageContext, "OA_RESPONSIBILITY_KEY");

  String sessionid          = sessionBean.createSession(request, response, dbcFullPathName, userName, userPassword, appShortName, responsibilityKey);
  String transactionid      = sessionBean.createTransaction(sessionBean.mRespInfo[0], sessionBean.mRespInfo[1], sessionBean.mRespInfo[2], dbcFullPathName);
  HMAC macKey = sessionBean.getMACKey(session);

  String redirectURL   = response.encodeRedirectURL("OA.jsp");
  String jradPage      = "/oracle/apps/fnd/framework/svctester/webui/TesterSummaryPG";
  redirectURL += "?page=" + jradPage;
  redirectURL += "&transactionid=" + transactionid; // + xmlFolder;
  redirectURL += "&fileName=" + testFileName;  
  redirectURL += "&testAction=" + testAction;    
  if (serviceBeanName!=null)
    redirectURL += "&serviceBeanName=" + serviceBeanName;
  if ("Edit".equals(testAction))
    redirectURL += "&addBreadCrumb=Y";
  
  redirectURL = URLMgr.processOutgoingURL(redirectURL, macKey);
  response.sendRedirect(redirectURL);
  
%>

<HTML>
<HEAD>
<title>Service Bean Testing Framework</title>
</HEAD>

<BODY>
<P>Launching Service Bean Testing Framework ...</P>
</BODY>
</HTML>

