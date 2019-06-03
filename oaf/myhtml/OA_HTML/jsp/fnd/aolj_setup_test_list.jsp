<!-- public static final String RCS_ID = "$Header: aolj_setup_test_list.jsp 115.6 2003/04/17 22:25:46 rtse ship $"; -->

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
<head>
   <title>AOLJ SETUP TEST LIST</title>
</head>
<body>
<br>
<h2>AOL/J Setup Tests</h2>
<hr>
<%@include file="aolj_current_session.jsp" %>
<hr>

<ul>

<li>
Connection Test</li>

<ul>
<li>
<a href="aolj_locate_dbc.jsp" target=test>Locate DBC File</a></li>

<li>
<a href="aolj_verify_dbc_content.jsp" target=test>Verify DBC Settings</a></li>

<li>
<a href="aolj_conn_test.jsp" target=test>AOL/J Connection Test</a></li>
</ul>
<li>
<a href="aolj_virtual_dir.jsp" target="test">Virtual
Directory settings</a></li>

<li>
<a href="aolj_web_agent.jsp?t=1" target=test>APPS_WEB_AGENT</a></li>

<ul>
<li>
<a href="aolj_virtual_dir.jsp?type=webagent" target="test">Virtual Directory Settings</a></li>
<li>
<a href="aolj_web_agent.jsp?t=2" target=test>FND_WEB.PING</a></li>

<li>
<a href="aolj_web_agent.jsp?t=3" target=test>Custom Authentication</a></li>

<li>
<a href="aolj_web_agent.jsp?t=4" target=test>GFM</a></li>
</ul>

<li>
<a href="aolj_servlet_agent.jsp?t=1" target=test>APPS_SERVLET_AGENT
</a></li>

<ul>
<li>
<a href="aolj_virtual_dir.jsp?type=servletagent" target="test">Virtual Directory Settings</a></li>
<li>
<a href="aolj_servlet_agent.jsp?t=2" target=test>Servlet Ping</a>
<!--(<APPS_SERVLET_AGENT>/oracle.apps.fnd.test.HelloWorldServlet-->
</li>

<li>
<a href="aolj_servlet_agent.jsp?t=3" target=test>Jsp Ping</a>
</li>
<!--
JSP Ping(/OA_HTML/jsp/fnd/fndping.jsp)-->
</ul>

<li>
<a href="aolj_framework_agent.jsp?t=1" target=test>APPS_FRAMEWORK_AGENT
</a></li>

<ul>
<li>
<a href="aolj_virtual_dir.jsp?type=frameworkagent" target="test">Virtual Directory Settings</a></li>
<li>
<a href="aolj_framework_agent.jsp?t=2" target=test>Servlet Ping</a>
<!--(<APPS_FRAMEWORK_AGENT>/oracle.apps.fnd.test.HelloWorldServlet-->
</li>

<li>
<a href="aolj_framework_agent.jsp?t=3" target=test>Jsp Ping</a>
</li>
<!--
JSP Ping(/OA_HTML/jsp/fnd/fndping.jsp)-->

<li>
<a href="aolj_framework_agent.jsp?t=4" target=test>Cabo Setup Tests</a>
</li>
<!--
Cabo Setup Test(/OA_HTML/aolj_fwkcabo_test.jsp)-->

<li>
<a href="aolj_framework_agent.jsp?t=5" target=test>X Server Accessibility</a>
</li>
<!--
X Server Accessibility(/OA_HTML/aolj_framework_agent.jsp)-->

<li>
<a href="aolj_fwk_exists.jsp?" target=test>OA Framework System Info</a>
</li>

<li>
<a href="aolj_fwkclass_info.jsp?displayType=index" target=test>Versions for Loaded Classes</a>
</li>
</ul>

<li>
<a href=aolj_help_agent.jsp?t=1 target=test>Online Help</a></li>
<!--
<br>(
<br>if null
<br><APPS_SERVLET_AGENT host and port>/OA_HTML/jsp/fnd/fndhelp.jsp?dbc=...&amp;...
<p>path = US/FND/@SEARCH
<br>lang = US
<br>root = FND:CONTENTS
<br>)
-->

<li>
TCF</li>
<ul>
<li><a href=aolj_tcf_test.jsp?t=1 target=test>Test Connection</a></li>
</ul>

<li>
Tool Launcher Profile Settings</li>

<ul>
<li>
<a href=aolj_icx_profiles.jsp?t=1 target=test>ICX_FORMS_LAUNCHER</a></li>

<li>
<a href=aolj_icx_profiles.jsp?t=2 target=test>ICX_REPORT_LAUNCHER</a></li>

<li>
<a href=aolj_icx_profiles.jsp?t=3 target=test>ICX_DISCOVERER_LAUNCHER</a></li>
</ul>

<li>
Application Login
</li>

<ul>
<li>
<a href=login.jsp target=test>Login Page</a></li>

<li>
<a href=resp.jsp target=test>Show Responsibilities</a>(Must <a href=login.jsp target=test>login</a> first)</li>

<li>
<a href=showsession.jsp target=test>Show Session Properties</a>(Must <a href=login.jsp target=test>login</a> first)</li>



</body>
</html>
