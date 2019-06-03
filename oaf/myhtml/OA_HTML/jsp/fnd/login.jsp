<%! public static final String RCS_ID = "$Header: login.jsp 115.3 2003/04/18 17:45:30 rtse ship $"; %>
<%@ page import="oracle.apps.fnd.common.*" %>
<jsp:useBean id="wru" class="oracle.apps.fnd.common.WebRequestUtil" scope="application" />
<jsp:setProperty name="wru" property="*" />

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
<title>User Login</title>
<BODY>
<%
if (request.getParameter("user") == null ||
    request.getParameter("password") == null ||
    request.getParameter("dbc") == null)
{

%>

<h2> Login:</h2>
<form method=post>
<pre>
  User Name:    <input type=text name=user> 
  Password:     <input type=password name=password>
  DBC FileName: <input type=text name=dbc 
<%
    if (WebRequestUtil.getDBC(request,response)!= null)
	{
	String dbcParam = WebRequestUtil.getDBC(request,response);	
%>
	  value=<%=dbcParam%> 
<%
	}
%>
	>.dbc
</pre>
<%
	String debug = request.getParameter("debug");
	if (debug==null) debug="off";       
	String nextpage = "resp.jsp";
	//if (debug.equalsIgnoreCase("on"))
	//	nextpage = "loginresult.jsp";
%>

  <input type=hidden name=nextpage value=<%=nextpage%>>
  <input type=hidden name=debug value=<%=debug%>>
  <BR><input type=submit value="Submit"><br>
  </form>

<%
}
else 
{
  boolean loginres = wru.login(request, response);
  String dbg = request.getParameter("debug");
  if (dbg==null) dbg="off";
  if (loginres)
  {
  out.println("<p><h3><a href=resp.jsp?debug="+dbg+">Show Responsibilities</a>");
  out.println("<BR><a href=showsession.jsp>Show Current Session Settings</a>");
  }
}

%>

</font>
</body>
</html>
