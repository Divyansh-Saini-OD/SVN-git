<%! public static final String RCS_ID = "$Header: aolj_web_agent.jsp 115.5 2003/04/17 22:25:53 rtse ship $"; %>
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
		 String webagent = wac.getProfileStore().getProfile("APPS_WEB_AGENT");
		 out.println("APPS_WEB_AGENT = " + webagent + "<p>");
		 return webagent;
	}

//start ping
void ping(HttpServletRequest request, HttpServletResponse response, JspWriter out, 
		String webagent) 
		throws java.io.IOException
{
	URL pingURL=null;
	if (!webagent.endsWith("/")) webagent+="/";
	try{
		pingURL = new URL(webagent+"FND_WEB.PING");
		out.println("Testing " + pingURL + "...<p>");
	    }catch (MalformedURLException e)
	        {
	   	out.println(e.toString());
		}

    	String ping_str="";
	try{
    	HttpURLConnection pingConn = (HttpURLConnection)pingURL.openConnection();
    	DataInputStream is = new DataInputStream(pingConn.getInputStream());
    	BufferedReader in = new BufferedReader(new InputStreamReader(pingConn.getInputStream()));
    	int line=0;
    	while (true)
    		{
    		//count the line number
    	        String c=in.readLine();
    		if (c==null) break;
    		ping_str +=c;
    	   	}//end while
    
    	out.println(ping_str+"<p>");

	//verifying database_id
	int DBlabel_start = ping_str.indexOf("DATABASE_ID");
	//out.println(" DBlabel_start: " +  DBlabel_start);
	String rest = ping_str.substring(DBlabel_start);
	int DBvalue_start = rest.indexOf("\">")+2;
	//out.println(" DBvalue_start: " +  DBvalue_start);
	rest = rest.substring(DBvalue_start);
	int DBvalue_end = rest.indexOf("</TD");
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

	//verifying fndname
	int Schemalabel_start = rest.indexOf("SCHEMA_NAME");
	rest = rest.substring(Schemalabel_start);
	int Schemavalue_start = rest.indexOf("\">")+2;
	//out.println(" Schemavalue_start: " +  Schemavalue_start);
	rest = rest.substring(Schemavalue_start);
	int Schemavalue_end = rest.indexOf("</TD>");
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


	//verifying webagent profile 
	int Agentlabel_start = rest.indexOf("APPS_WEB_AGENT");
	rest = rest.substring(Agentlabel_start);
	int Agentvalue_start = rest.indexOf("\">")+2;
	//out.println(" Agentvalue_start: " +  Agentvalue_start);
	rest = rest.substring(Agentvalue_start);
	int Agentvalue_end = rest.indexOf("</TD>");
	//out.println(" Agentvalue_end: " +  Agentvalue_end);
	String ping_agent = rest.substring(0,Agentvalue_end);
	//out.println("ping_agent:"+ping_agent);

	if (ping_agent!=null )
		{
		//out.println("ping_agent="+ping_agent+"<BR>");
		//out.println("ping_agent.length="+ping_agent.length()+"<BR>");

		out.println("- Verifying APPS_WEB_AGENT (" + ping_agent+ ")...");
		if (ping_agent.equalsIgnoreCase(webagent))
		  out.println("Verified.<BR>");
		else
		  out.println("<font color=red>Error</font>: Different than profile value retrieved earlier.<BR>");
		}

	}//end try
	catch (EOFException eof){
	//	out.println(eof.toString());
		throw (eof);	//if not throwing this exception, page won't show.
		}
	catch (IOException ioe){
	   	//out.println(ioe.toString());
		throw (ioe);	//if not throwing this exception, page won't show.
		}
}//end ping

void custom(HttpServletRequest request, JspWriter out,
		String webagent) throws IOException 
	{
	out.println("Testing " + webagent + "HTP.HR...<p>");
	URL pingURL = null;
	HttpURLConnection pingConn = null;
	try{
		pingURL = new URL(webagent+"HTP.HR");
		pingConn = (HttpURLConnection)pingURL.openConnection();
	  	} catch (MalformedURLException mue)
		{
	   try{
	   	out.println(mue.toString());
		}catch (IOException ioe){}
	} catch (IOException e)
	  {
	   try{
		out.println(e.toString());
		}catch (IOException ioe){}
	  }

  String respMsg = "";

  try
  {
    respMsg = pingConn.getResponseMessage();
  }
  catch(Exception e)
  {
    out.println("<p><font color=red>" + e.toString() + "<p>" +
      "Error:</font> Unable to get response " +
      "message from URL " + pingURL.toString() + "<br>");

    return;
  }

	if (respMsg.equals("OK")) {
		DataInputStream is = new DataInputStream(pingConn.getInputStream());
		BufferedReader in = new BufferedReader
			(new InputStreamReader(pingConn.getInputStream()));
		while (true){
		        String c=in.readLine();
			if (c==null) break;
			out.println(c);
			}
	        out.println("<p><font color=red>Error:</font> Error in access control, failed to verify CUSTOM authentication. To correct this problem, set the \"Custom Authentication\" field to \"CUSTOM\"<BR>");
//	       out.println("</b>");
		}
	else 
	  {
          int respCode= pingConn.getResponseCode();
          out.println("<BR>    respCode="+respCode);
       	  out.println("    respMsg="+respMsg+"<BR>");
       	  out.println("    Custom authentication verified.<BR>");
	  }

	}

void gfm(HttpServletRequest request, HttpServletResponse response, JspWriter out,
	 String webagent) throws java.io.IOException
	{
	String gfmURL = webagent + "fndgfm/fnd_help.get/US/fnd/@search";

    out.println("Open a sample GFM document: " + "<a href=" + gfmURL + ">" +
      gfmURL + "</a>");

	// response.sendRedirect(gfmURL);
	}
%>

<%

	String webagent =null;
	int t = new Integer(request.getParameter("t")).intValue();
	switch (t)
	{
	case 1: webagent = getValue(request,response);
		break;
	case 2: 
		if (webagent==null)
		  webagent = getValue(request,response);
		ping(request,response,out,webagent);
		break;
	case 3: 
		if (webagent==null)
		  webagent = getValue(request,response);
		custom(request,out,webagent);
		break;
	case 4: 
		if (webagent==null)
		  webagent = getValue(request,response);
		gfm(request,response, out,webagent);
		break;
	}

/* Need to at run time test some of the values returned back by the ping, this would completely depend on the format of the html file that fnd_web.ping generated.This is how the html source looks currently:

<TABLE  border=1 cellpadding=3>				-- line 1
<TR>
<TD ALIGN="Left">SYSDATE</TD>
<TD ALIGN="Left">15-JAN-2002 16:10:14</TD>
</TR>
<TR>
<TD ALIGN="Left">DATABASE_VERSION</TD>
<TD ALIGN="Left">Oracle8i Enterprise Edition Release 8.1.6.2.0 - Production</TD>
</TR>
<TR>
<TD ALIGN="Left">DATABASE_ID</TD>
<TD ALIGN="Left">ap505dbs_dom1151</TD>			-- line 12
</TR>
<TR>
<TD ALIGN="Left">SCHEMA_NAME</TD>
<TD ALIGN="Left">APPS</TD>
</TR>
<TR>
<TD ALIGN="Left">AOL_VERSION</TD>
<TD ALIGN="Left">11.5.0</TD>
</TR>
<TR>
<TD ALIGN="Left">APPS_WEB_AGENT</TD>
<TD ALIGN="Left">http://ap804sun.us.oracle.com:878/pls/dom1151/</TD>
</TR>
</TABLE>
</BODY>
</HTML>
*/

%>


</body>
</html>
