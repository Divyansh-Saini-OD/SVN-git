<%! public static final String RCS_ID = "$Header: resp.jsp 115.6 2003/04/17 22:26:02 rtse ship $"; %>
<%@ page import="oracle.apps.fnd.common.*" %>
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

<!--
Login
-->

<%!

  // Sort an array of RespInfo objects by responsibility name.
  //
  void sort(RespInfo[] respInfoArray)
  {
    if(respInfoArray == null)
    {
      return;
    }

    String respName1;
    String respName2;
    RespInfo temp;

    // OK, this isn't exactly the fastest sorting algorithm known to man . . .
    //
    for(int i = 0; i < respInfoArray.length; i++)
    {
      for(int j = i+1; j < respInfoArray.length; j++)
      {
        respName1 = respInfoArray[i].getResponsibilityName().toUpperCase();
        respName2 = respInfoArray[j].getResponsibilityName().toUpperCase();

        if(respName1.compareTo(respName2) > 0)
        {
          temp = respInfoArray[i];
          respInfoArray[i] = respInfoArray[j];
          respInfoArray[j] = temp;
        }
      }
    }
  }

%>

<%
if (request.getParameter("respid") != null && 
    request.getParameter("appid") != null )
{
  boolean res = fndlogin.assignContext(request, response);
  if (!res)
%>
	<br> Invalid Session, please login again.<br>
<%
	;;}
%>

<HTML>
<title>Responsibilities</title>
<BODY>

<br> <h2>Responsibility List</h2>
<ol>
<% 
	RespInfo[] resps = fndlogin.getResponsibilities(request,response);
  sort(resps);
	if (resps==null)
	{
%>
	   Null returned for responsibility list.
<%
	}
	else 
	   for (int i=0; i<resps.length; i++) {
		if (resps[i]!=null)
		{
      String respName = resps[i].getResponsibilityName();
      String version = resps[i].getVersion();
      String type = null;

      if(version.equals("4"))
      {
        type = "Forms";
      }
      else if(version.equals("W"))
      {
        type = "SSWA";
      }
      else if(version.equals("M"))
      {
        type = "Mobile";
      }
%>		
<li> 	<a href="resp.jsp?appid=
		<%= resps[i].getAppId() %>
	&respid=
		<%= resps[i].getRespId() %>
	&secgpid=
		<%= resps[i].getSecgpId() %>
	&nextpage=func.jsp"
	>
    <%= respName + " (" + type + ")" %>
	</a>

<% 		}
%>

<%
	}
%>
</ol>

<h3> <a href="showsession.jsp">Show Settings in Current Session</a></h3>



<!--h2> Assign Responsibility:</h2-->
<p>
  <form method=get>
  <!--Responsibility: --><input type=hidden name=respid><br>  
  <!--Application: --><input type=hidden name=appid><br><p>
  <input type=hidden name=nextpage value=func.jsp><br><p>
  <input type=hidden name=dbc value=\ap111sun_atg115.dbc><br><p>
  <!--Debug: --><input type=hidden name=debug value=on><br><p>
  <!--input type=submit value="Submit"-->
  </form>

<!--  -->

<hr>
<!--pre>
Test case responsibilities that I've used:
  //test cases: user  resp  app   func
  //            1195  21243 178   2621
  //            1195  20873 178   2594
  //            1195  20873 178   2633
  //            1195  20873 178   7011 (Servlet Type)
  //            ..    21522 191   5502
  //            ..    21522 191   5359
  //            ..    21522 191   4092
  //            1006  20872 178   2602


</pre-->



</font>
</body>
</html>
