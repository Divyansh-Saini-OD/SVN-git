<%! public static final String RCS_ID = "$Header: aolj_framework_agent.jsp 115.3 2003/04/17 22:25:57 rtse ship $"; %>
<%@ page import="oracle.apps.fnd.common.WebRequestUtil"%>
<%@  page import="java.net.HttpURLConnection"%>
<%@  page import="java.net.URL"%>
<%@  page import="java.net.MalformedURLException"%>
<%@  page import="java.net.URLConnection"%>
<%@ page import="oracle.apps.fnd.common.WebAppsContext"%>
<%@ page import="oracle.apps.fnd.common.AppsContext"%>
<%@ page import="oracle.cabo.style.util.GraphicsUtils"%>
<%@ page import="oracle.cabo.share.error.ErrorLog"%>

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
<title>APPS_FRAMEWORK_AGENT</title>
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
		 String frameworkAgent = wac.getProfileStore().getProfile("APPS_FRAMEWORK_AGENT");
		 out.println("APPS_FRAMEWORK_AGENT = " + frameworkAgent + "<BR>");
		 return frameworkAgent;
	}

void servletPing(HttpServletRequest request, HttpServletResponse response, 
		String frameworkAgent) 
		throws java.io.IOException
{
  PrintWriter out = response.getWriter();

  if(frameworkAgent != null && !frameworkAgent.endsWith("/"))
  {
    frameworkAgent += "/";
  }

  String pingURL = frameworkAgent + "oa_servlets/oracle.apps.fnd.test.HelloWorldServlet";

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

}

	void jspPing(HttpServletRequest request, HttpServletResponse response, JspWriter out,
			String frameworkAgent) 
			throws java.io.IOException
	{
	   String appsFrameworkAgent = frameworkAgent;
	   if ((appsFrameworkAgent != null) && !appsFrameworkAgent.trim().endsWith("/"))
	   {
             appsFrameworkAgent = appsFrameworkAgent.trim().concat("/");
	   }

	   String dbc=WebRequestUtil.getDBC(request,response);
	   String pingURL = appsFrameworkAgent + "OA_HTML/jsp/fnd/fndping.jsp?dbc=" + dbc;

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

		 //verifying frameworkAgent profile 
		 int Agentlabel_start = rest.indexOf("APPS_FRAMEWORK_AGENT");
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

		   out.println("- Verifying APPS_FRAMEWORK_AGENT (" + ping_agent+ ")...");
		   if (ping_agent.equalsIgnoreCase(frameworkAgent))
		     out.println("Verified.<BR>");
		   else
		     out.println("<font color=red>Error</font>: Different than profile value retrieved earlier.<BR>");
		 }

	       }
      	       catch(Exception e)
               {
                 out.println("<b><font color=red>" + e.toString() + "</font></b>");
               }

           } //else
           
        } //jspPing

	void caboSetup(HttpServletRequest request, HttpServletResponse response, JspWriter out,
			PageContext pageContext) 
			throws java.io.IOException
	{	
            ServletContext servctx = pageContext.getServletContext();
            String oahtmlRealPath = servctx.getRealPath("/");

	    if(oahtmlRealPath == null)
	    {
	      out.println("<p><font color=red>Error: Unable to determine the real path for OA_HTML. </font> <br>");
	    }
            else
            {
              String caboDirName = oahtmlRealPath + "cabo";
              String caboImageDirName = caboDirName + "/images";
              String caboStyleDirName = caboDirName + "/styles";

              File caboDir = new File(caboDirName);
              File caboImageDir = new File(caboImageDirName);
              File caboStyleDir = new File(caboStyleDirName);

              out.println("<p><b> Dynamic Images Directory </b><BR>");
	      if (caboImageDir.exists())
		  if (caboImageDir.canWrite())
		  {
	           out.println("<font color=green>" + caboImageDirName + " exists and is writeable. </font><BR>");
		  }
		  else
		  {
		    out.println("<font color=red>Error: " + caboImageDirName + " is not writeable. </font><BR>");
                    out.println("<p> " + caboImageDirName + " must be writeable by the http server. <br>");
		  }
	      else
	      {
		    out.println("<font color=red>Error: " + caboImageDirName + " does not exist.</font><BR>");
	      }

              
              out.println("<p><b> StyleSheets Directory </b><BR>");
	      if (caboStyleDir.exists())
		  if (caboStyleDir.canWrite())
		  {
	           out.println("<font color=green>" + caboStyleDirName + " exists and is writeable. </font><BR>");
		  }
		  else
		  {
		    out.println("<font color=red>Error: " + caboStyleDirName + " is not writeable. </font><BR>");
                    out.println("<p> " + caboStyleDirName + " must be writeable by the http server. <br>");
		  }
	      else
	      {
		    out.println("<font color=red>Error: " + caboStyleDirName + " does not exist. </font><BR>");
	      }

              out.println("<h2> Cabo directory listing </h2>");
              listFiles(caboDirName, out);

            }

        } //caboSetup


       void listFiles(String dirName, JspWriter out)
           throws java.io.IOException   
       {
         //System.err.println("incoming dirName = " + dirName);
	 File fileEntry = new File(dirName);         

         if (fileEntry.isFile())
         {
           out.println(dirName + "<br>");
           //System.err.println("    +" + dirName);     
         }
         else if (fileEntry.isDirectory())
         {
           //System.err.println("*" + dirName);     
           out.println("<p><b><font size=4> " + dirName + "</font> </b><br>");
           String[] filenames;
           filenames = fileEntry.list();
           for (int i=0; i<filenames.length; i++)
           {
               File tempFile = new File(filenames[i]);
	       listFiles(dirName + "/" + filenames[i], out);
           }
         }

       } //listFiles       

       	void XServerAccessibility(HttpServletRequest request, HttpServletResponse response, JspWriter out,
			String frameworkAgent) 
			throws java.io.IOException
	{

          ErrorLog errorLog = null;

	  if (GraphicsUtils.isGraphicalEnvironment(errorLog))
          {
    	    out.println("<p> <b> <font size=4> X Server is accessible. </font> </b><br>");
          }
	  else 
          {
	    out.println("<p> <b> <font color=red size=4>Error: X server is not accessible. </font> </b> <BR>");
            out.println("<p> For details on the X Server configuration please refer to the MetaLink note 139863.1 : " +
                              " <b> Configuring and Troubleshooting Oracle HTTP Server with Oracle Applications </b> <br>");
          }

        } //listFiles
%>

<%

	String frameworkAgent =null;
	int t = new Integer(request.getParameter("t")).intValue();
	switch (t)
	{
	case 1: frameworkAgent = getValue(request,response);
		break;
	case 2: 
		if (frameworkAgent==null)
		  frameworkAgent = getValue(request,response);
		servletPing(request,response,frameworkAgent);
		break;
	case 3: 
                System.err.println("case 3");
		if (frameworkAgent==null)
		  frameworkAgent = getValue(request,response);
                System.err.println("case 3 a");
		jspPing(request,response,out,frameworkAgent);
		break;
	case 4: 
		if (frameworkAgent==null)
		  frameworkAgent = getValue(request,response);
		caboSetup(request,response,out,pageContext);
		break;
	case 5: 
		if (frameworkAgent==null)
		  frameworkAgent = getValue(request,response);
		XServerAccessibility(request,response,out,frameworkAgent);
		break;
	}
%>


</body>
</html>





