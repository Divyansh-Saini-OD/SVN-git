<%! public static final String RCS_ID = "$Header: showsession.jsp 115.2 2003/04/17 22:26:03 rtse ship $"; %>
<%@ page import="oracle.apps.fnd.common.*"%>
<jsp:useBean id="showsession" class="oracle.apps.fnd.common.ShowSession" scope="application" />
<jsp:setProperty name="showsession" property="*" />

<%
  if(!"true".equals(request.getSession(true).getValue("aoljtest")))
  {
    out.println("<font color=red>" +
      "ERROR:  This page can only be accessed through " +
      "<a href=aoljtest.jsp>aoljtest.jsp</a>.</font><br>");

    return;
  }
%>

<HTML>
<BODY>
<BR>

<%
	showsession.show(request,response);
%>
</BODY>
</HTML>

