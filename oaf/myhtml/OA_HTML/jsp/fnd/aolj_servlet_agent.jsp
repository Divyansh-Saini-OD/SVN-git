<%! public static final String RCS_ID = "$Header: aolj_servlet_agent.jsp 115.6 2003/04/17 22:25:55 rtse ship $"; %>
<%@ page import="oracle.apps.fnd.common.WebRequestUtil"%>
<%@  page import="java.net.HttpURLConnection"%>
<%@  page import="java.net.URL"%>
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
<title>APPS_SERVLET_AGENT</title>
<body>
<%!
String getValue(HttpServletRequest request, HttpServletResponse response) 
		throws java.io.IOException
	{
		String host = request.getServerName();
                int port = request.getServerPort();
          	//String dbcfile = request.getParameter("dbcfile");
          	//String dbcfile = "ap505dbs_dom1151.dbc";
            String dbcfile = WebRequestUtil.getDBC(request,response);
            PrintWriter out = response.getWriter();

		WebAppsContext wac = new WebAppsContext(host,new Integer(port).toString(),dbcfile);
		 String servletagent = wac.getProfileStore().getProfile("APPS_SERVLET_AGENT");
		 out.println("APPS_SERVLET_AGENT = " + servletagent + "<BR>");
		 return servletagent;
	}

void servletPing(HttpServletRequest request, HttpServletResponse response, 
		String servletagent) 
		throws java.io.IOException
{
  PrintWriter out = response.getWriter();

  if(servletagent != null && !servletagent.endsWith("/"))
  {
    servletagent += "/";
  }

  String pingURL = servletagent + "oracle.apps.fnd.test.HelloWorldServlet";

  if(pingURL.startsWith("https"))
  {
  	response.sendRedirect(pingURL);
  }
  else
  {
    try
    {
      out.println("<p>Testing " + pingURL + " . . . <p>");

      BufferedReader br = new
        BufferedReader(new InputStreamReader(new URL(pingURL).openStream()));

      String line;
      String html = "";

      boolean successFlag = false;

      for(int i = 0; i < 30; i++)
      {
        if(!br.ready())
        {
          try
          {
            Thread.sleep(1000);
          }
          catch(Exception e)
          {
          }
        }
      }

      while(br.ready())
      {
        line = br.readLine();

        if(line != null && line.indexOf("Hello") != -1)
        {
          successFlag = true;
        }

        html += line + "\n";
      }

      if(successFlag)
      {
        out.println("Servlet ping succeeded.<p>");
      }
      else
      {
        out.println("<b><font color=red>Servlet ping failed.</font></b><p>");
      }

      out.println(html);
    }
    catch(Exception e)
    {
      out.println("<b><font color=red>" + e.toString() + "</font></b>");
    }
  }

/*
	out.println("Testing " + servletagent + "/oracle.apps.fnd.test.HelloWorldServlet...<BR>");
	URL pingURL=null;
	try{
	pingURL = new URL(servletagent+"FND_WEB.PING");
	out.println("Accessing " + pingURL + "...<BR>");
	}catch (MalformedURLException e)
	{
	   out.println(e.toString());
	}
	try{
	HttpURLConnection pingConn = (HttpURLConnection)pingURL.openConnection();
	DataInputStream is = new DataInputStream(pingConn.getInputStream());
	while (true){
	        char c=is.readChar();
		out.println(c);
		}
	}
	catch (EOFException eof){}
	catch (IOException ioe){
	   out.println(ioe.toString());
		}
*/

}

	void jspPing(HttpServletRequest request, HttpServletResponse response, JspWriter out,
			String servletagent) 
			throws java.io.IOException
	{
		int slash1 = servletagent.indexOf("//");
    int slash2 = servletagent.indexOf("/",slash1+2);
		String base = servletagent.substring(0,slash2);
		//out.println("Testing " + base + "/OA_HTML/jsp/fnd/fndping.jsp...");
		String dbc=WebRequestUtil.getDBC(request,response);
		String pingURL = base + "/OA_HTML/jsp/fnd/fndping.jsp?dbc=" + dbc;

    if(pingURL.startsWith("https"))
    {
      response.sendRedirect(pingURL);
    }
    else
    {
      try
      {
        out.println("<p>Testing " + pingURL + " . . . <p>");

        BufferedReader br = new
          BufferedReader(new InputStreamReader(new URL(pingURL).openStream()));

        String line;
        String ping_str = "";

        for(int i = 0; i < 30; i++)
        {
          if(!br.ready())
          {
            try
            {
              Thread.sleep(1000);
            }
            catch(Exception e)
            {
            }
          }
        }

        while(br.ready())
        {
          line = br.readLine();

          ping_str += line + "\n";
        }

        out.println(ping_str + "<p>");

  // The code below was basically ripped from aolj_web_agent.jsp.

	//verifying database_id
	int DBlabel_start = ping_str.indexOf("DATABASE_ID");
	//out.println(" DBlabel_start: " +  DBlabel_start);
	String rest = ping_str.substring(DBlabel_start);
	int DBvalue_start = rest.indexOf("left>")+5;
	//out.println(" DBvalue_start: " +  DBvalue_start);
	rest = rest.substring(DBvalue_start);
	int DBvalue_end = rest.indexOf("</td>");
	//out.println(" DBvalue_end: " +  DBvalue_end);
	String ping_dbid = rest.substring(0,DBvalue_end);
	//out.println("ping_dbid:"+ping_dbid);

	if (ping_dbid!=null )
		{
		out.println("- Verifying DATABASE_ID ("+ping_dbid+")...");
		if (ping_dbid.equals(WebRequestUtil.getDBC(request,response)))
		  out.println("Same as dbc file name.<BR>");
		else
		    out.println("<font color=red>Error</font>: Different than dbc file name provided earlier("+WebRequestUtil.getDBC(request,response)+").<BR>");
		}

  rest = ping_str;

	//verifying fndname
	int Schemalabel_start = rest.indexOf("SCHEMA_NAME");
	rest = rest.substring(Schemalabel_start);
	int Schemavalue_start = rest.indexOf("left>")+5;
	//out.println(" Schemavalue_start: " +  Schemavalue_start);
	rest = rest.substring(Schemavalue_start);
	int Schemavalue_end = rest.indexOf("</td>");
	//out.println(" Schemavalue_end: " +  Schemavalue_end);
	String ping_schema = rest.substring(0,Schemavalue_end);
	//out.println("ping_schema:"+ping_schema);

	if (ping_schema!=null )
		{
		String fndnam = WebRequestUtil.getCookieValue(request,response,"aolj_test_input_username");
		//out.println("fndnam="+fndnam+"<BR>");
		//out.println("ping_schema="+ping_schema+"<BR>");
		//out.println("ping_schema.length="+ping_schema.length()+"<BR>");
		
		out.println("- Verifying SCHEMA_NAME (" + ping_schema+ ")...");
		if (ping_schema.equalsIgnoreCase(fndnam))
		  out.println("Same as FNDNAM.<BR>");
		else
		  out.println("<font color=red>Error</font>: Different than FNDNAM provided earlier.<BR>");
		}

  rest = ping_str;

	//verifying servletagent profile 
	int Agentlabel_start = rest.indexOf("APPS_SERVLET_AGENT");
	rest = rest.substring(Agentlabel_start);
	int Agentvalue_start = rest.indexOf("left>")+5;
	//out.println(" Agentvalue_start: " +  Agentvalue_start);
	rest = rest.substring(Agentvalue_start);
	int Agentvalue_end = rest.indexOf("</td>");
	//out.println(" Agentvalue_end: " +  Agentvalue_end);
	String ping_agent = rest.substring(0,Agentvalue_end);
	//out.println("ping_agent:"+ping_agent);

	if (ping_agent!=null )
		{
		//out.println("ping_agent="+ping_agent+"<BR>");
		//out.println("ping_agent.length="+ping_agent.length()+"<BR>");

		out.println("- Verifying APPS_SERVLET_AGENT (" + ping_agent+ ")...");
		if (ping_agent.equalsIgnoreCase(servletagent))
		  out.println("Verified.<BR>");
		else
		  out.println("<font color=red>Error</font>: Different than profile value retrieved earlier.<BR>");
		}

      }
      catch(Exception e)
      {
        out.println("<b><font color=red>" + e.toString() + "</font></b>");
      }
    }

/*
	out.println("Testing " + servletagent + "/OA_HTML/jsp/fnd/fndping.jsp...");
	URL pingURL=null;
	try{
	pingURL = new URL(servletagent+"FND_WEB.PING");
	out.println("Accessing " + pingURL + "...<BR>");
	}catch (MalformedURLException e)
	{
	   out.println(e.toString());
	}
	try{
	HttpURLConnection pingConn = (HttpURLConnection)pingURL.openConnection();
	DataInputStream is = new DataInputStream(pingConn.getInputStream());
	while (true){
	        char c=is.readChar();
		out.println(c);
		}
	}
	catch (EOFException eof){}
	catch (IOException ioe){
	   out.println(ioe.toString());
		}
*/
}

%>

<%

	String servletagent =null;
	int t = new Integer(request.getParameter("t")).intValue();
	switch (t)
	{
	case 1: servletagent = getValue(request,response);
		break;
	case 2: 
		if (servletagent==null)
		  servletagent = getValue(request,response);
		servletPing(request,response,servletagent);
		break;
	case 3: 
		if (servletagent==null)
		  servletagent = getValue(request,response);
		jspPing(request,response,out,servletagent);
		break;
	}
%>


</body>
</html>
