<%! public static final String RCS_ID = "$Header: func.jsp 115.4 2003/04/18 18:18:28 rtse ship $"; %>
<%@ page import="oracle.apps.fnd.common.*"%>
<jsp:useBean id="fndlogin" class="oracle.apps.fnd.common.FNDLogin" scope="application" />
<jsp:setProperty name="fndlogin" property="*" />

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
<title>Menu Tree</title>
<BODY>
<br> 
<h3>Menu Tree for the current responsibility:</h3>
<% 
	int currlevel = 0;
	FunctionObj[] funcs = fndlogin.getFunctionList(request,response);
	String indent = "";
	int d=-1;
	String desc;
	if (funcs==null)
	{
%>
	   Null returned for function list.<BR>
	   Please try login again.<BR>
<%
	}
	else 
	   //skip the top level responsibility node(resproot)
	   for (int i=1; i<funcs.length; i++) {
		d=0;
		int thislevel = funcs[i].getLevel();
		if (thislevel>currlevel)
			indent = "<ul>";
		else if (thislevel<currlevel)
			indent = "</ul>";	
		else indent="";
		currlevel = thislevel;

    int id = -1;
    String idString;
    if (funcs[i].getFuncId()!=-1)
    {
      id = funcs[i].getFuncId();
      idString = "FUNCTION_ID=" + id;
    }
    else
    {
      id = funcs[i].getSubmenuId();
      idString = "SUB_MENU_ID=" + id;
    }

		String type = funcs[i].getType();
		boolean runnable = false;
		if (type!=null)
			runnable = 
			type.equals("WWW") || type.equals("WWK") || type.equals("JSP") || type.equals("SERVLET");
		else type="MENU";
		String url = "";	
		if (runnable)
		  {
  		  url = fndlogin.getURL(id,request,response);
		  //"http://ap583pc.us.oracle.com:8080/fnd/servlet/FNDLogin?action=runFunc&funcid="+id+"&valid=true";
		  }
%>			
<%= indent %>
<li>
<%	
		if (runnable)
		{
%>
<a href="<%= url %>">
<%	
		}
%>

<%= funcs[i].getPrompt() %> (<%= idString %>)
<%
		if (!type.equals("MENU"))
		{
%>
(<%= type %>)
<%
		}
%>
<%	
		if (runnable)
		{
%>
</a>
<%	
		}
%>
<%	
		}
%>

</ul>
<%
	for (int i=0;i<currlevel;i++)
	{
%>
</ul>
<%
	}
%>
</ul>
</ul>
</ul>
</ul>
<h3> <a href="resp.jsp">Change responsibility and application</a><BR>
<a href="showsession.jsp">Show Settings in Current Session</a></h3>

<p>

</font>


</body>
</html>


