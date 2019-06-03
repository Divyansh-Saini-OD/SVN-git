<%! public static final String RCS_ID = "$Header: aolj_tcf_test.jsp 115.3 2003/04/17 22:25:58 rtse ship $"; %>
<%@ page import="oracle.apps.fnd.common.WebRequestUtil"%>
<%@  page import="java.net.HttpURLConnection"%>
<%@  page import="java.net.URL"%>
<%@  page import="java.io.*"%>
<%@  page import="java.net.MalformedURLException"%>
<%@  page import="java.net.URLConnection"%>
<%@ page import="oracle.apps.fnd.common.WebAppsContext"%>
<%@ page import="oracle.apps.fnd.common.AppsContext"%>
<%@ page import="oracle.apps.fnd.tcf.*"%>

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
<title>TCF Test</title>
<body>

<%
	String tcfsrv = null;

                String host = request.getServerName();
                int port = request.getServerPort();
                //String dbcfile = request.getParameter("dbcfile");
                //String dbcfile = "ap505dbs_dom1151.dbc";
                String dbcfile = WebRequestUtil.getDBC(request,response);

                WebAppsContext wac = new WebAppsContext(host,
			new Integer(port).toString(),dbcfile);
                 String tcfhost = wac.getProfileStore().getProfile("TCF:HOST");
                 String tcfport= wac.getProfileStore().getProfile("TCF:PORT");
                 out.println("TCF:HOST = " + tcfhost+ "<p>");
                 out.println("TCF:PORT = " + tcfport+ "<p>");

	int t = new Integer(request.getParameter("t")).intValue();

  switch (t)
  {
    case 1:

      out.println("Trying to connect to TCF server..." + "<p>");

      try
      {
        if(tcfhost!=null && tcfport!=null )
        {
          ClientDispatcher clnt =
            new ClientDispatcher(tcfhost,tcfport,"sendme",null);
          boolean conn = clnt.isConnected();
          if(conn) 
            out.println("connected.");
          else out.println("<font color=red>Error:</font> Connection failed.");
        }
        else
        {
          out.println("<font color=red>Error:</font> " +
            "TCF:HOST and TCF:PORT must not be null.");
        }
      }
      catch(Exception e)
      {
        out.println("<font color=red>Error:</font> " +
          e.toString());
      }
	}
%>


</body>
</html>
