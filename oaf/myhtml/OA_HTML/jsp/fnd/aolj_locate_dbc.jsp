<%! public static final String RCS_ID = "$Header: aolj_locate_dbc.jsp 115.4 2003/04/17 22:25:47 rtse ship $"; %>
<%@  page import="java.net.URL"%>
<%@  page import="java.io.InputStream"%>
<%@  page import="java.io.FileReader"%>
<%@  page import="java.io.BufferedReader"%>
<%@  page import="java.io.DataInputStream"%>
<%@  page import="java.util.Properties"%>
<%@  page import="oracle.apps.fnd.common.WebRequestUtil"%>

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
<title>Locate DBC File</title>
<body>
<h1>Step 2. Locate DBC File</h1><p>

<%
	String dbid = WebRequestUtil.getDBC(request,response);
//request.getParameter("dbid");

  dbid = parseDBC(dbid);

	out.println("Trying to locate DBC file: " + dbid + ".dbc");
	  //check the existence of /OA_HTML/env.txt
	  String host = request.getServerName();
	  URL envURL = null;
	  try{
		  int port = request.getServerPort();
		  envURL = new URL("http",host, port,"/OA_HTML/env.txt");  
		}catch (NullPointerException e)
		{
		  //port is not available, default is used.
		  envURL = new URL("http",host,"/OA_HTML/env.txt");	
		}
	   Properties envs = new Properties();
	   try{

  String fndtop = System.getProperty("FND_TOP");

  if(fndtop == null)
  {
    out.println("<p><b><font color=red>ERROR FOUND: " +
      "FND_TOP not defined in Java system properties.</font></b><br>");

		   out.println("<p>==>Checking " + envURL.toString() + "...<p>");
		   InputStream fs = envURL.openStream();
		   out.println("==>Trying to read env.txt... <p>");

		   envs.load(fs);
		   fs.close();
		   fndtop = envs.getProperty("FND_TOP");
  }
  else
  {
    out.println("<p><i>FND_TOP defined in system properties.</i>");
  }

		   if (fndtop==null)
			out.println("<p><B><font color=red>ERROR FOUND: Couldn't find FND_TOP definition, either env.txt is missing or misplaced, or FND_TOP is NOT properly defined in the env.txt file. Please correct this and try again.</B><BR></font>"); 
		   else
			//FND_TOP is defined
		      {
		      //go to the defined directory to grab the dbc file
			out.println("<p><i>FND_TOP=" + fndtop + "</i>");
			String filename = new File(new File(fndtop,"secure"),dbid+ ".dbc").toString();
			out.println("<p>==>Trying to locate " + filename + " on " + host + "...<BR>");
			BufferedReader br = new BufferedReader(new FileReader(filename));
			//if no exception happens, it means the dbc file exists.

			String line = br.readLine();
			out.println("<BR><B>DBC file found, content: </b><BR><p>");
			while (line!=null)
				{
				out.println(line+"<BR>");
				line = br.readLine();
				}
			br.close();

			//out.println("<BR><i>Dbc file found.</i><p> ");
			response.addCookie(new Cookie("fndtop",fndtop));
			out.print("<h3><pre><a href=aolj_verify_dbc_content.jsp?dbcfile="+dbid+"&fndtop="+fndtop+">Next</a> (Verify settings in DBC file)");
			//out.println("     <a href=aolj_locate_dbc.jsp?dbid="+dbid+">Back</a></h3><BR></pre>");
			}	//end else
	       } //end try	
		 catch (Exception e)
		 {
		out.println("<p><B><font color=red>ERROR: "+ e.toString()+"<BR></font>"); 
		out.println("Please carefully read AOL/J's dbc setup guideline and check to see if everything is in place.<BR>");
		// out.println("<h3><a href=aolj_locate_dbc.jsp?dbid="+dbid+">Back</a></h3><BR></pre>");
		 }
//              }//end else (dbc file is correct)
//} //end else dbc file name is submitted.
%>

<%!

/**
 * Parse out the DB identifier part of a DBC file name.
 */
private String parseDBC(String dbc)
{
  if(dbc == null)
  {
    return null;
  }

  int index1 = dbc.lastIndexOf(java.io.File.separator);

  if(index1 == -1)
  {
    index1 = 0;
  }
  else
  {
    index1++;
  }

  int index2 = dbc.length();

  if(dbc.endsWith(".dbc"))
  {
    index2 = index2 - 4;
  }

  return dbc.substring(index1,index2);
}

%>

</body>
</html>
