<%@ page
  language    = "java"
  contentType = "text/html"
  import      = "java.lang.*, java.io.*, java.util.*"
%>

<%! public static final String RCS_ID = "$Header: aolj_fwk_exists.jsp 115.2 2003/04/17 22:26:06 rtse ship $"; %>

<%-- Turn off caching of contents in this page --%>
<%
  response.setHeader("Cache-Control", "no-cache");
  response.setHeader("Pragma", "no-cache");
  response.setDateHeader("Expires", -1);
  response.setStatus(HttpServletResponse.SC_RESET_CONTENT);
%>

<%
  if(!"true".equals(request.getSession(true).getValue("aoljtest")))
  {
    out.println("<font color=red>" +
      "ERROR:  This page can only be accessed through " +
      "<a href=aoljtest.jsp>aoljtest.jsp</a>.</font><br>");

    return;
  }
%>

<%
  String className = "oracle.apps.fnd.framework.webui.OAWebBeanConstants";

  try 
  { 
    Class oracleClass = Class.forName(className); 
    response.sendRedirect("/OA_HTML/jsp/fnd/aolj_fwksys_info.jsp");
  }
  catch (Exception e) 
  { 
%>
    Self-Service Framework is not installed.
<%
  }
%>