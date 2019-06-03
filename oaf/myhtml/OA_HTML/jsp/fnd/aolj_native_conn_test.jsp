<%! public static final String RCS_ID = "$Header: aolj_native_conn_test.jsp 115.5 2003/04/17 22:26:10 rtse ship $"; %>
<%@ page import="java.io.File"%>
<%@ page import="java.sql.*"%>
<%@ page import="java.util.Enumeration"%>
<%@ page import="oracle.jdbc.driver.*"%>
<%@ page import="oracle.apps.fnd.common.Ping"%>
<title>Apps Schema Connection - Result</title>
<%
    // Load the Oracle JDBC driver
    DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());

    // Connect to the database
    // You can put a database name after the @ sign in the connection URL.

String dbname = request.getParameter("database");
String user = request.getParameter("username");
String pswd = request.getParameter("password");
String host = request.getParameter("host");
String port = request.getParameter("port");

String connStr="jdbc:oracle:thin:"+user+"/"+pswd+"@"+host+":"+port+":"+dbname;
char[] hiddenPwd = new char[pswd.length()];
for (int x=0;x<pswd.length();x++) 
	hiddenPwd[x]='*';
String showConnStr="jdbc:oracle:thin:"+user+"/"+String.valueOf(hiddenPwd)+"@"+host+":"+port+":"+dbname;
out.println("<B>Connect String: " + showConnStr+ "</b><p>");

Connection conn = null;
String wrong = "";
try{	
		conn = DriverManager.getConnection (connStr, user, pswd);

		if (conn != null)
		{
		out.println("Successfully obtained a jdbc connection: " + conn + "<BR>");
    		try
    		  {
			PreparedStatement stmt = null;
    			ResultSet rs = null;
    			String result = null;

      // Verify that APPS schema name was supplied, and not APPLSYSPUB or
      // any other schema name.
      //
      try
      {
        stmt = conn.prepareStatement("select 1 from fnd_oracle_userid " +
          "where read_only_flag = 'U' and upper(oracle_username) = :1");
        stmt.setString(1,user.toUpperCase());
        rs = stmt.executeQuery();

        if(!rs.next())
        {
          throw new Exception();
        }

        if(rs != null)
        {
          rs.close();
        }

        stmt.close();
      }
      catch(Exception ex)
      {
        out.println("<font color=red>ERROR:  " + user.toUpperCase() +
          " is an invalid APPS schema name. " + "Please log in again at " +
          "<a href=aoljtest.jsp>aoljtest.jsp</a>.</font><br>");

        if(rs != null)
        {
          rs.close();
        }

        if(stmt != null)
        {
          stmt.close();
        }

        conn.close();

        return;
      }

			String sql = "select lower(host_name) || '_' || lower(instance_name) from v$instance";
      			stmt = conn.prepareCall(sql);

      			rs = stmt.executeQuery();

            if(rs.next())
              result = rs.getString(1);

            out.println("JDBC driver version: " +
              conn.getMetaData().getDriverVersion() + "<br>");
            out.println("DATABASE_ID: " + result + "<p>");

			Cookie aCookie = new Cookie("dbc",result);
			response.addCookie(aCookie);
      request.getSession(true).putValue("aoljtest","true");
                  	rs.close();
                  	stmt.close();

out.println("<h2>Testing Result: </h2><p>");

  Properties props = System.getProperties();
  out.println("<b>Java Version Number: </b><br>" + System.getProperty("java.version") + "<p>");
  String classpath = System.getProperty("java.class.path");
  if(classpath == null) classpath = "";
  out.println("<b>Classpath: " + "</b><br>");
  StringTokenizer st = new StringTokenizer(classpath,String.valueOf(File.pathSeparatorChar));
  while(st.hasMoreTokens())
  {
    // get next element in classpath
    String classpathElement = st.nextToken();
    // open file handle to element
    File src = new File(classpathElement.trim());
    // Check if file or directory is readable
    if(src.canRead())
      out.println(classpathElement + "<br>");
    else
      out.println("<font color=red>Missing " + classpathElement + "</font><br>");
  }
  out.println("<p>");

			out.println("<b>=>Try pinging the database with the connection...</b><p>");
			out.println(new Ping().getDBInfo(conn));
			//set the cookies to remember the data that users input:
			Enumeration pnames = request.getParameterNames();
			while (pnames.hasMoreElements())
				{
				String pname = (String)pnames.nextElement();
				aCookie = new Cookie("aolj_test_input_"+pname,request.getParameter(pname));
				response.addCookie(aCookie);
				}
			out.print("<p><h3><pre><a href=aolj_setup_test.html?dbid=" + result+">Enter AOL/J Setup Test</a>");
			//out.println("     <a href=aoljtest.jsp>Back</a></h3><BR></pre>");

                  conn.close();
        	  }catch(Exception e){
			e.printStackTrace();
     			}//end catch
		}//end else
       	 }catch(SQLException e){
			out.println("<font color=red>ErrorCode: " + e.getErrorCode() + "<BR>" + e.toString()+"<BR></font>");
			if (e.getErrorCode()==1017)
				wrong = "user/password";
			else
				{
  		   		if (e.toString().toLowerCase().indexOf("network adapter")!=-1)
				  wrong = "host name/port number";

				else if (e.toString().toLowerCase().indexOf("connection r.,efused")!=-1)
				  wrong = "twotask";
				}
       		}//end catch
		  catch(Exception e){
			out.println(e.toString()+"<BR>");
       		}//end catch

        if(conn == null)
	{
             out.println("<p><b><font color=red>Error: Could not connect. Please verify connection information and make sure database is up and accessible (try SQL*Plus).</b><br>"); 
	      if (wrong.length()>0)
		out.println("</b>The exception indicates that it is likely that you've provided incorrect " + wrong + ".<p>");
		 out.println("<a href=aoljtest.jsp>Go back</a> to correct login information.<BR></font>");
		}
%>
