<%! public static final String RCS_ID = "$Header: aolj_conn_test.jsp 115.2 2003/04/17 22:25:50 rtse ship $"; %>
<%@ page import="oracle.apps.fnd.common.*"%>
<%@ page import="oracle.apps.fnd.security.*"%>
<%@ page import="java.sql.Connection"%>

<%
  if(!"true".equals(request.getSession(true).getValue("aoljtest")))
  {
    out.println("<font color=red>" +
      "ERROR:  This page can only be accessed through " +
      "<a href=aoljtest.jsp>aoljtest.jsp</a>.</font><br>");

    return;
  }
%>

<title>AOL/J Guest Connection</title>
<h1>Step 4. Making AOL/J Connection</h1><p>

<%
	String host=request.getServerName();
	int port=request.getServerPort();
	String dbcfile = WebRequestUtil.getDBC(request,response);
	String guest = request.getParameter("guest");
	if (guest==null)
	  guest = WebRequestUtil.getCookieValue(request,response,"guest");
	String guestuser = guest.substring(0,guest.indexOf("/"));
	String guestpwd = guest.substring(guest.indexOf("/")+1);
//	out.println(guestuser +  "  "  + guestpwd);
	out.println("<B>=>Testing validateLogin...</b><br>");

	WebAppsContext wac = new WebAppsContext(host,new Integer(port).toString(),dbcfile);
	SessionManager sm = new SessionManager(wac);
	boolean valid = sm.validateLogin(guestuser,guestpwd);
//	boolean login = WebRequestUtil.login(request,response);
//	out.println("login result: " + login);
	if (valid)
		{
		out.println("validateLogin("+guestuser+","+guestpwd+") returned: " + valid + "<BR>");
		out.println("Successfully created WebAppsContext, login validated.<p>");
		}
	else
		{
		out.println("<B><font color=red>ERROR</font>: validateLogin("+guestuser+","+guestpwd+") returned: " + valid);
		out.println("<br>Please make sure the GUEST_USER_PWD entry in the dbc file is correct.<br></b>");
		out.println(wac.getErrorStack().getAllMessages());
		return;
		}
	
	out.println("<B>=>Trying to get a connection using getJDBCConnection...<BR></b>");
	Connection conn = wac.getJDBCConnection();
	if (conn!=null)
		out.println("Successfully obtained connection: " + conn+"<p>");
	else 
		{
		out.println("<B><font color=red>ERROR</font>: Failed to obtain connection from WebAppsContext.</B><BR>");
		return;
		}
	
	out.print("<h3><pre><a href=\"login.jsp?dbc="+dbcfile+"&debug=on\">Test Application Login</a> (User Login)");
%>
