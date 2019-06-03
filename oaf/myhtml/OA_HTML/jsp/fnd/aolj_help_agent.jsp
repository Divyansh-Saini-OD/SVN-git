<%--
 /*===========================================================================+
 |      Copyright (c) 2002 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  FILENAME                                                                 |
 |      aolj_help_agent.jsp                                                  | 
 |                                                                           |
 |  DESCRIPTION                                                              |
 |      Setup test for iHelp.                                                |
 +===========================================================================*/
--%>

<%@ page import = "oracle.apps.fnd.common.WebAppsContext" %>
<%@ page import = "oracle.apps.fnd.common.WebRequestUtil" %>

<%! public static final String RCS_ID =
  "$Header: aolj_help_agent.jsp 115.4 2003/04/17 22:25:54 rtse ship $"; %>

<%
  if(!"true".equals(request.getSession(true).getValue("aoljtest")))
  {
    out.println("<font color=red>" +
      "ERROR:  This page can only be accessed through " +
      "<a href=aoljtest.jsp>aoljtest.jsp</a>.</font><br>");

    return;
  }
%>

<html>
<title>Oracle Applications Online Help Setup Test</title>
<body>

<%

  WebAppsContext ctx = WebRequestUtil.createWebAppsContext(request,response);
  String servletAgent = ctx.getProfileStore().getProfile("APPS_SERVLET_AGENT");
  String helpAgent = ctx.getProfileStore().getProfile("HELP_WEB_AGENT");
  String helpURL = ctx.getURLUtils().getURL("FND","O_HELP");

  if(helpAgent == null)
  {
    %>
      Based on the value of the APPS_SERVLET_AGENT profile
      (<i><%=servletAgent%></i>),
      the URL to launch Online Help is <a href=<%=helpURL%>><%=helpURL%></a>.
      You may click on this link to launch Online Help.
    <%
  }
  else
  {
    %>
      <font color=red><b>Warning</b></font>:
      The HELP_WEB_AGENT profile option on this instance is set to
      <i><%=helpAgent%></i>.
      Unless Online Help is configured to run on a remote server,
      the HELP_WEB_AGENT profile should be cleared.
      Because Online Help normally runs on the same server as the rest of
      Oracle Applications, it is strongly recommended that you clear
      the HELP_WEB_AGENT profile.
      <p>
      Based on the value of the HELP_WEB_AGENT profile,
      the URL for launching Online Help is
      <a href=<%=helpURL%>><%=helpURL%></a>.
      You may click on this link to launch Online Help.
    <%
  }

%>


</body>
</html>
