<%! public static final String RCS_ID = "$Header: aolj_icx_profiles.jsp 115.2 2003/04/17 22:25:59 rtse ship $"; %>
<%@ page import="oracle.apps.fnd.common.WebRequestUtil"%>
<%@  page import="java.net.HttpURLConnection"%>
<%@  page import="java.net.URL"%>
<%@  page import="java.io.*"%>
<%@  page import="java.net.MalformedURLException"%>
<%@  page import="java.net.URLConnection"%>
<%@ page import="oracle.apps.fnd.common.WebAppsContext"%>
<%@ page import="oracle.apps.fnd.common.AppsContext"%>

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
<title>Apps Web Agent</title>
<body>
<%!
String getProfileValue(HttpServletRequest request,
      HttpServletResponse response,
			String whichlauncher) 
		throws java.io.IOException
	{
		String host = request.getServerName();
                int port = request.getServerPort();
          	//String dbcfile = request.getParameter("dbcfile");
          	//String dbcfile = "ap505dbs_dom1151.dbc";
            String dbcfile = WebRequestUtil.getDBC(request,response);
            PrintWriter out = response.getWriter();

		WebAppsContext wac = new WebAppsContext(host,new Integer(port).toString(),dbcfile);
		 String thelauncher = wac.getProfileStore().getProfile(whichlauncher);
		 out.println(whichlauncher  + " = <a href=" + thelauncher + ">" + thelauncher + "</a><p>");
		 out.println("Click on the link to test launching.<BR>");
		 return thelauncher; 
	}

%>

<%
	int t = new Integer(request.getParameter("t")).intValue();
	String launcher = null;
	switch (t)
	{
	case 1: launcher = getProfileValue(request,response,"ICX_FORMS_LAUNCHER");
		break;
	case 2: launcher = getProfileValue(request,response,"ICX_REPORT_LAUNCHER");
		break;
	case 3: launcher = getProfileValue(request,response,"ICX_DISCOVERER_LAUNCHER");
		break;
	}
%>


</body>
</html>
