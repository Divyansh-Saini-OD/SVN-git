<%! public static final String RCS_ID = "$Header: aolj_current_session.jsp 115.1 2003/04/17 22:26:05 rtse ship $"; %>
<%@  page import="java.sql.*"%>
<%@ page import="java.util.Enumeration"%>
<%@  page import="oracle.jdbc.driver.*"%>
<%@ page import="oracle.apps.fnd.common.WebRequestUtil"%>

<%
  if(!"true".equals(request.getSession(true).getValue("aoljtest")))
  {
    out.println("<font color=red>" +
      "ERROR:  This page can only be accessed through " +
      "<a href=aoljtest.jsp>aoljtest.jsp</a>.</font><br>");

    return;
  }
%>

<title>Current Session Status</title>

<!--of Current Session:<p>-->
<b>DBC File Name</b>: <%= WebRequestUtil.getDBC(request,response) %><BR>
<b>Apps Schema Name</b>: <%= WebRequestUtil.getCookieValue(request,response,"aolj_test_input_username") %><BR>
<b>Database</b>: <%= WebRequestUtil.getCookieValue(request,response,"aolj_test_input_database") %><BR>

</html>
