<%@ page
  language    = "java"
  import      = "java.util.*, oracle.jbo.*, javax.naming.*, oracle.jdeveloper.html.*, oracle.jbo.html.databeans.*, oracle.apps.fnd.framework.*, oracle.apps.fnd.framework.webui.*"
  contentType = "text/html"
%>
<%! public static final String RCS_ID = "$Header: OAErrorDetailPage.jsp 115.23 2005/03/17 04:52:56 atgops1 noship $"; %>
<%
  response.setHeader("Cache-Control", "no-cache,no-store,max-age=0"); // HTTP 1.1
  response.setHeader("Pragma", "no-cache");                           // HTTP 1.0
  response.setDateHeader("Expires", -1);                              // Prevent caching at the proxy server
  if (request.getHeader("User-Agent").indexOf("MSIE") >= 0) 
  { 
    // HTTP 1.1.  Only way to force refresh in IE.
    response.setStatus(HttpServletResponse.SC_RESET_CONTENT); 
  }

  String logoutUrl = OAJSPHelper.getLogoutUrl(request);
%> 
<html lang="en-US">
<head>
  <title>Error Details</title>
  <link rel="stylesheet" charset="UTF-8" type="text/css" href="/OA_HTML/cabo/styles/blaf.css">
</head>
<body>
<table width="100%" border="0" cellspacing="0"  cellpadding="0">
  <tr> <td><img src="/OA_MEDIA/FNDSSCORP.gif" alt=""> </td></tr>
  <tr> <td>&nbsp;</td> 
       <% if  (logoutUrl != null)
      {
      %>
       <td> <a href= <%=logoutUrl%>>Logout </a></td>  
      <% } %>
  </tr>
  <tr> <td width="100%" nowrap class="OraBGColorDark" >&nbsp; </td> </tr>
</table>
<br>
<div CLASS="errorText">
<%
  OAException e   = (OAException)session.getValue("OASevereException");
  session.removeValue("OASevereException");
%>
<%
   String displayErrorStack = (String)session.getValue("_displayErrorStack");
   session.removeValue("_displayErrorStack");
   if ("Y".equals(displayErrorStack))
   {
%>   
<table width="95%" border="0" cellspacing="0" class="OraBGAccentDark" cellpadding="0" align="center">
  <tr> <td> &nbsp; </td> </tr>
  <!-- <tr> <td class="OraErrorHeader"> <img src=/OA_HTML/cabo/images/errorl.gif>  Error Page </td> </tr> -->
  <tr> <td class="OraErrorHeader"> <center> Error Page </center> </td> </tr>
  <tr> <td colspan=2 class="OraBGColorDark"> </td> </tr>
  <tr> <td> &nbsp; </td> </tr>
  <tr> <td colspan=2 class="OraErrorText" >Exception Details. </td> </tr>
  <tr> <td class="OraBGAccentLight"> &nbsp; </td> </tr>
  <tr> <td colspan=2 class="OraBGAccentLight"> <xmp> <%= (e != null) ? e.getMessageStackTraces() : "" %> </xmp>

<%
   }
%>   
  </td></tr>
</table>
</div>
</body>
</html>
