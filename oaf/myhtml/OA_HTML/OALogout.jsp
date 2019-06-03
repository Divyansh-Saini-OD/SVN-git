<%@ page
  language    = "java"
  contentType = "text/html"
  import      = "oracle.apps.fnd.framework.webui.OAPageBean"
  import      = "oracle.apps.fnd.sso.SSOManager"
%>

<%! public static final String RCS_ID = "$Header: OALogout.jsp 115.96 2005/03/30 04:52:23 atgops1 noship $"; %>

<%
  // 02-Jul-02 nbajpai
  // Fix to Enh No 2262230.
  String closeWindow = request.getParameter("closeWindow");
  // Comment out ... variable is not referenced anywhere.  
  // String redirectURL = request.getParameter("startOverURL");
  session.removeValue("CallFromForm"); 
  // Fix for bug 2980017, get translated message from session
  String closeGlobalButtonMsg = 
    (String)session.getValue("CloseGlobalButtonMsg"); 

  // Fix for bug 3957341 - When the user clicks on global Logout
  // button, USER-Level profile should take precedence over
  // site level profile. So, use getLogoutUrl which takes 
  // WebAppsContext as param. Since WebAppsContext handle is not 
  // available here, we get the logout url in OAPageLayoutHelper
  // and add it to session.
  String logoutUrl = (String)session.getValue("FWK_ICX_LOGOUT_URL"); 
  session.removeValue("FWK_ICX_LOGOUT_URL");
  //String logoutUrl = (String)session.getAttribute("FWK_ICX_LOGOUT_URL");  
  //session.removeAttribute("FWK_ICX_LOGOUT_URL");
%>

<html>
<%
if (closeWindow != null && closeWindow.equals("true"))
{
%>
  <head>
    <title>Logout</title>
    <script TYPE="text/javascript">
      if (navigator.userAgent.indexOf("MSIE") != -1)
      {     
         window.close();
         history.back();
      }
      else
      {
        if(confirm("<%= closeGlobalButtonMsg %>"))
          window.close();
        else
          history.back();  
      }
    </script>
    <noscript> 
    <p>This product requires use of a browser that supports JavaScript 
       1.2, and the scripting should be enabled in the browser
    </noscript> 

  </head>
  <body></body>
<%
}
else
{
    OAPageBean.disableSessionPassivation(session);
    session.invalidate();
    if(logoutUrl == null){
        oracle.apps.fnd.common.WebAppsContext ctx = new oracle.apps.fnd.common.WebAppsContext(System.getProperty("JTFDBCFILE"));
          boolean chk = ctx.validateSession(oracle.apps.fnd.framework.webui.OAJSPHelper.getIcxCookie(request, false));
          if(chk){
                logoutUrl = SSOManager.getLogoutUrl(request,ctx);
          }else{
                logoutUrl = SSOManager.getLogoutUrl(request);
          }
        ctx.freeWebAppsContext();
    }
    //String logoutUrl = SSOManager.getLogoutUrl(request);
    response.sendRedirect(logoutUrl);
}
%>
</html>
