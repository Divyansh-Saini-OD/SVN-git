<%! public static final String RCS_ID = "$Header: aolj_virtual_dir.jsp 115.6 2003/04/17 22:25:51 rtse ship $"; %>
<%@  page import="oracle.apps.fnd.common.WebRequestUtil"%>
<%@  page import="oracle.apps.fnd.common.WebAppsContext"%>
<%@  page import="java.net.URL"%>
<%@  page import="java.net.HttpURLConnection"%>
<%@  page import="java.net.URLConnection"%>
<%@  page import="java.io.InputStream"%>
<%@  page import="java.net.MalformedURLException"%>
<%@  page import="java.io.FileReader"%>
<%@  page import="java.io.BufferedReader"%>
<%@  page import="java.io.DataInputStream"%>
<%@  page import="java.util.Properties"%>

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
<title>Virtual Directories</title>
<body>
<!--
        http://<hostname>:<port>/OA_HTML/env.txt  (OBSOLETE)
        http://<hostname>:<port>/OA_MEDIA/FNDLOGOL.gif
        http://<hostname>:<port>/OA_JAVA/oracle/apps/fnd/jar/fndaol.jar
        http://<hostname>:<port>/OA_CGI/FNDWRR.exe
        http://<hostname>:<port>/images/home.gif
-->
<%!
  void checkURL(String scheme, String host, String portString, String url,
    String virtualDir, String description, String contentType, JspWriter out)
  throws java.io.IOException
   {
    int port = Integer.parseInt(portString);
    String all_url = scheme + "://" + host+":" + port + url;
    out.println("<b><a href=" + all_url + ">" + all_url + "</a></b><br>" );
    out.println("<i>[" + description + "]</i><p>");

    if(!scheme.equals("http"))
    {
      return;
    }

    out.println("<b>=>Testing virtual directory \"" + virtualDir + "\".</b><br>");

	  URL envURL = null;
	  try{
	  envURL = new URL("http",host, port,url);  
	  URLConnection urlConn = envURL.openConnection();
	  HttpURLConnection httpConn= (HttpURLConnection)urlConn;
	  	httpConn.connect();
		String respMsg = httpConn.getResponseMessage();
		if (!respMsg.equals("OK")) out.println("<b><font color=red>");
		out.println("    HTTP Response: "+respMsg+";");
		if (!respMsg.equals("OK")) out.println("</b></font>");

		if (respMsg.equals("OK")) 
		{
		String type = httpConn.getContentType();
		out.println("    Content Type: "+type+"<BR>");

      if(type == null || !type.equals(contentType))
      {
        out.println("<p><b><font color=red>WARNING:  Expected content type \"" + contentType + "\".</font></b>");
      }
		}
		
		//int len = httpConn.getContentLength();
		//out.println("length="+len);
		//int respCode= httpConn.getResponseCode();
		//out.println("<BR>    respCode="+respCode);
	  	}
	   catch (MalformedURLException mue)
		{
		out.println("<b><font color=red>"+mue.toString()+"</b></font>");
		}
	   catch (IOException ioe)
		{
		out.println("<b><font color=red>"+ioe.toString()+"</b></font>");
		}
	out.println("<p><hr>");
	}

  // Given the string representation of a URL, parse out its scheme, host,
  // and port information, and store them in a 3-entry array.
  //
  private String[] parseSchemeHostPort(String url)
  {
    String[] schemeHostPort = new String[3];

    try
    {
      // Make sure URL has a trailing slash.

      if(!url.endsWith("/"))
      {
        url += "/";
      }

      // Determine the scheme (e.g., "http", "https", etc.) of the URL.

      int index1 = url.indexOf("://");

      if(index1 == -1)
      {
        return null;
      }

      String scheme = url.substring(0,index1);

      // Determine the host and port of the URL.

      int index2 = url.indexOf(":",index1+3);

      int index3 = url.indexOf("/",index1+3);

      String host;
      String port;

      if(index2 == -1)
      {
        host = url.substring(index1+3,index3);
        port = "80";
      }
      else
      {
        host = url.substring(index1+3,index2);
        port = url.substring(index2+1,index3);
      }

      schemeHostPort[0] = scheme;
      schemeHostPort[1] = host;
      schemeHostPort[2] = port;
    }
    catch(Exception e)
    {
      return null;
    }

    return schemeHostPort;
  }

%>

<%
    String[] schemeHostPort;
    String scheme;
    String host;
    String port;
	  String thisScheme = request.getScheme();
	  String thisHost = request.getServerName();
	  String thisPort = String.valueOf(request.getServerPort());
    String dbcfile = WebRequestUtil.getDBC(request,response);
    String type = request.getParameter("type");
    WebAppsContext wac =
      new WebAppsContext(thisHost,new Integer(thisPort).toString(),dbcfile);
    String appsWebAgent =
      wac.getProfileStore().getProfile("APPS_WEB_AGENT");
    String appsServletAgent =
      wac.getProfileStore().getProfile("APPS_SERVLET_AGENT");
    String appsFrameworkAgent =
      wac.getProfileStore().getProfile("APPS_FRAMEWORK_AGENT");

    if(type != null && type.equals("webagent"))
    {
      if(appsWebAgent == null)
      {
        out.println("APPS_WEB_AGENT has not been set.");

        return;
      }

      schemeHostPort = parseSchemeHostPort(appsWebAgent);

      if(schemeHostPort == null || schemeHostPort.length != 3)
      {
        out.println("APPS_WEB_AGENT is invalid.");

        return;
      }
      else
      {
        scheme = schemeHostPort[0];
        host = schemeHostPort[1];
        port = schemeHostPort[2];
      }
    }
    else if(type != null && type.equals("servletagent"))
    {
      if(appsServletAgent == null)
      {
        out.println("APPS_SERVLET_AGENT has not been set.");

        return;
      }

      schemeHostPort = parseSchemeHostPort(appsServletAgent);

      if(schemeHostPort == null || schemeHostPort.length != 3)
      {
        out.println("APPS_SERVLET_AGENT is invalid.");

        return;
      }
      else
      {
        scheme = schemeHostPort[0];
        host = schemeHostPort[1];
        port = schemeHostPort[2];
      }
    }
    else if(type != null && type.equals("frameworkagent"))
    {
      if(appsFrameworkAgent == null)
      {
        out.println("APPS_FRAMEWORK_AGENT has not been set.");

        return;
      }

      schemeHostPort = parseSchemeHostPort(appsFrameworkAgent);

      if(schemeHostPort == null || schemeHostPort.length != 3)
      {
        out.println("APPS_FRAMEWORK_AGENT is invalid.");

        return;
      }
      else
      {
        scheme = schemeHostPort[0];
        host = schemeHostPort[1];
        port = schemeHostPort[2];
      }
    }
    else
    {
      scheme = thisScheme;
      host = thisHost;
      port = thisPort;
    }

	  //out.println("<UL>");

    String url;
    String virtualDir;
    String description;
    String contentType;

    /*
    url = "/OA_HTML/env.txt";
    virtualDir = "OA_HTML";
    description = "Open the env.txt environment file.";
    contentType = "text/plain";
    checkURL(scheme,host,port,url,virtualDir,description,contentType,out);
    */

    url = "/OA_MEDIA/FNDLOGOL.gif";
    virtualDir = "OA_MEDIA";
    description = "View the FNDLOGOL.gif image file.";
    contentType = "image/gif";
    checkURL(scheme,host,port,url,virtualDir,description,contentType,out);

    url = "/OA_JAVA/oracle/apps/fnd/jar/fndaol.jar";
    virtualDir = "OA_JAVA";
    description = "Download the fndaol.jar Java JAR file.";
    contentType = "application/octet-stream";
    checkURL(scheme,host,port,url,virtualDir,description,contentType,out);

    url = "/OA_CGI/FNDWRR.exe";
    virtualDir = "OA_CGI";
    description = "View the output of the FNDWRR.exe CGI program.";
    contentType = "text/plain";
    checkURL(scheme,host,port,url,virtualDir,description,contentType,out);

    url = "/images/home.gif";
    virtualDir = "images";
    description = "View the home.gif image file.";
    contentType = "image/gif";
    checkURL(scheme,host,port,url,virtualDir,description,contentType,out);

	  //out.println("</UL>");
%>

</body>
</html>
