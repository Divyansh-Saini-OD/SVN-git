<%@ page
  language    = "java"
  errorPage   = "OAErrorPage.jsp"
  contentType = "text/html;charset=windows-1252" 
  import      = "oracle.apps.fnd.framework.webui.OAPageBean"
  import      = "java.io.File"
  import      = "java.io.PrintWriter"
  import      = "java.io.FileWriter"
  import      = "java.util.StringTokenizer"
  import      = "java.util.Properties"
  import      = "java.io.FileInputStream"
  import      = "oracle.apps.fnd.framework.webui.URLMgr"
  import      = "oracle.apps.fnd.security.HMAC"
%>

<jsp:useBean
  id          = "sessionBean"
  class       = "oracle.apps.fnd.framework.CreateIcxSession"
  scope       = "request">
</jsp:useBean>

<%
  long time1 = System.currentTimeMillis();

  response.setHeader("Cache-Control", "no-cache");          // HTTP 1.1
  response.setHeader("Pragma", "no-cache");                 // HTTP 1.0
  response.setDateHeader("Expires", -1);                    // Prevent caching at the proxy server
  if (request.getHeader("User-Agent").indexOf("MSIE") >= 0) { 
     // HTTP 1.1.  Only way to force refresh in IE. For Others Bypass
     response.setStatus(HttpServletResponse.SC_RESET_CONTENT); 
  }

  ServletContext sc = session.getServletContext();
  String paramFile = sc.getRealPath("/runregion_params.txt");
  Properties urlParams = new Properties();

  try 
  {
    FileInputStream inFile = new FileInputStream(paramFile);
    urlParams.load(inFile);
    inFile.close();
    
  } catch (Exception ex) 
  {
    ex.printStackTrace();
  }
  
  //    CHANGE dbcName to your specific values
  //    CHANGE userName to your specific values (Ie vision)
  //    CHANGE userPassword to your specific values (Ie vision98)
  String dbcFullPathName      = application.getInitParameter("DBC_FULL_PATH_NAME");
  String dbcName              = urlParams.getProperty("akDbcFile");
  String userName             = urlParams.getProperty("akUsername");
  String userPassword         = urlParams.getProperty("akPassword");
  String applicationShortName = urlParams.getProperty("akAppShortName");
  String responsibilityKey    = urlParams.getProperty("akRespKey");
  String runOptions1          = urlParams.getProperty("akOpts1");
  String runOptions0          = urlParams.getProperty("akOpts0");
  String urlParam             = urlParams.getProperty("akUrlParam");
  String jradRegion           = urlParams.getProperty("region");
  String jradPage             = urlParams.getProperty("page");
  String xmlFolder            = urlParams.getProperty("JRAD_XML_PATH");
  String jradStartTime        = urlParams.getProperty("JRADStartTime");

  if ( jradStartTime != null )
  {
    session.setAttribute("JRADStartTime", jradStartTime);
  }

  if (xmlFolder == null || xmlFolder.length() <= 0)
    xmlFolder = "";
  else
  {
    File runOKFile = new File(xmlFolder, "runregion_run.txt");
    try
    {
        PrintWriter pw = new PrintWriter(new FileWriter(runOKFile));
        pw.println("The runregion.jsp is running fine.");
        pw.close();
    }
    catch (Exception e)
    {
    }
    xmlFolder = "&JRAD_XML_PATH=" + xmlFolder;
  }

  System.out.println("TIME: runregion: initialization [" + 
                     (System.currentTimeMillis() - time1) + " ms] ");
  time1 = System.currentTimeMillis();

  if ( dbcName != null && dbcName.length() > 0 )
  {
    OAPageBean.clearWebBeanCache(session, request);

    time1 = System.currentTimeMillis();
    String sessionId  = sessionBean.createSession(request,
                                              response, 
                                              dbcFullPathName, 
                                              userName,
                                              userPassword,
                                              applicationShortName,
                                              responsibilityKey);
    String transactionid = sessionBean.createTransaction(sessionBean.mRespInfo[0],
                                               sessionBean.mRespInfo[1],
                                               sessionBean.mRespInfo[2],
                                               dbcFullPathName);
    HMAC hmac = sessionBean.getMACKey(session);

    System.out.println("TIME: runregion: session and transaction creation [" + 
                       (System.currentTimeMillis() - time1) + " ms] ");
    time1 = System.currentTimeMillis();

    if ( jradPage != null || jradRegion != null )
    {
      String redirectURL   = response.encodeRedirectURL("OA.jsp");

      if ( jradRegion != null )
          redirectURL += "?region=" + jradRegion;
      else if ( jradPage != null )
          redirectURL += "?page=" + jradPage;

      redirectURL += "&transactionid=" +
                      transactionid; // + xmlFolder;

      if ( urlParam != null && urlParam.length() > 0 )
          redirectURL = redirectURL + urlParam;

      // Run Options Cookies
      StringTokenizer tokens = new StringTokenizer(runOptions1, ";", false);
      String          token;
      while ( tokens.hasMoreTokens() )
      {
          token = tokens.nextToken();
          response.addCookie(new Cookie(token, "1"));
      }
      tokens = new StringTokenizer(runOptions0, ";", false);
      while ( tokens.hasMoreTokens() )
      {
          token = tokens.nextToken();
          response.addCookie(new Cookie(token, "0"));
      }
      redirectURL = URLMgr.processOutgoingURL(redirectURL, hmac);
      response.sendRedirect(redirectURL);
    }
  }
%>

<HTML>
<HEAD>
<title>Test Page</title>
</HEAD>

<P>Please wait ...</P>

</HTML>

