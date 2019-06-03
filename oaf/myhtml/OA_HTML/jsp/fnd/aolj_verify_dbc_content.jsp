<%! public static final String RCS_ID = "$Header: aolj_verify_dbc_content.jsp 115.9 2003/04/17 22:25:49 rtse ship $"; %>
<%@  page import="java.net.URL"%>
<%@  page import="java.io.InputStream"%>
<%@  page import="java.io.FileReader"%>
<%@  page import="java.io.BufferedReader"%>
<%@  page import="java.io.DataInputStream"%>
<%@  page import="java.util.Properties"%>
<%@ page import="java.sql.*"%>
<%@ page import="oracle.jdbc.driver.*"%>
<%@ page import="oracle.apps.fnd.common.WebRequestUtil"%>
<%@ page import="oracle.apps.fnd.security.AolSecurity"%>
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
<title>DBC File Contents</title>
<body>

<h1>Step 3. Verify DBC Settings</h1><p>
<%
	String dbcfile = WebRequestUtil.getDBC(request, response);
	String fndtop = request.getParameter("fndtop");
	if (fndtop==null)
	  fndtop = WebRequestUtil.getCookieValue(request,response,"fndtop");
	if (dbcfile == null || fndtop==null)
	  {
	   out.println("Dbc file name or fndtop is not available, please start from aoljtest.jsp and follow through the insturction to perform the tests in the correct order.<BR>");
	  }
	//if (dbcfile != null && fndtop!=null)
	else
	   {
	   try{
	   //out.println("Dbc file name and fndtop are available.<BR>");
	   out.println("dbcfile="+dbcfile+"<BR>");
	   out.println("fndtop="+fndtop+"<BR>");
	  	String host = request.getServerName();
	  	int port = request.getServerPort();
	   out.println("host="+host+"<BR>");
		if (!fndtop.endsWith("/")) fndtop = fndtop+"/";
	   //out.println("fndtop="+fndtop+"<BR>");
		String filename = fndtop + "secure/" + dbcfile + ".dbc";
	   out.println("file path ="+filename+"<BR>");

		out.println("<p>==>Reading " + filename + " on " + host + "...<BR>");
		BufferedReader br = new BufferedReader(new FileReader(filename));
		String aLine = br.readLine();
		out.println("<BR><b>DBC file found, content: <BR></b><p>");
		Properties dbcenvs=new Properties();
		while (aLine!=null)
               {
			out.println(aLine+"<BR>");
	            if(!aLine.startsWith("#"))
      	        {
            	  int equalPos=aLine.indexOf("=");
                    if(equalPos!=-1)
   	               {
                     String key=aLine.substring(0,equalPos).toUpperCase();
                     String value=aLine.substring(equalPos+1);
                     if(key!=null)
                         key=key.trim();
                     if(value!=null)
                         value=value.trim();
                     dbcenvs.put(key,value);
			   }
                    }
			aLine = br.readLine();
		    }
		br.close();
		out.println("</i><p><b>Please examine the setting above carefully to see if anything is incorrect.</b><p>");

		String dbhost="",dbport="",twotask="";
		
		//check each entry in the dbc file:
		out.println("<b>Checking FNDNAM...</b>");
            String schemaname = dbcenvs.getProperty("FNDNAM");
		String user_input_schemaname = WebRequestUtil.getCookieValue(request,response,"aolj_test_input_username");
		if (schemaname != null && schemaname.equalsIgnoreCase(user_input_schemaname))
			out.println("<i>verified:</i>"+schemaname+"<p>");
		else
			{
			out.println("<Br><b><font color=red>ERROR:</b>Schema name set in dbc file is: " + schemaname+"</font></b><BR>");
			out.println("the schema name you input in Step 1 was: " + user_input_schemaname+"<BR>");
			out.println("Please correct the dbc file or <a href=\"aoljtest.jsp\">restart the test</a> with the correct schema name.<p>");
			}		

		out.println("<b>Checking TWOTASK...</b>");
            twotask = dbcenvs.getProperty("TWO_TASK");
		String user_input_twotask = WebRequestUtil.getCookieValue(request,response,"aolj_test_input_database");
		if (twotask != null && twotask.equalsIgnoreCase(user_input_twotask))
			out.println("<i>verified:</i>"+twotask+"<p>");
		else
			{
			out.println("<Br><b><font color=red>ERROR:</b>twotask value set in dbc file is: " + twotask+"</font><BR>");
			out.println("the twotask you input in Step 1 was: " + user_input_twotask+"<BR>");
			out.println("Please correct the dbc file or <a href=\"aoljtest.jsp\">restart the test</a> with the correct two task value.<p>");
			}		

		out.println("<b>Checking DB_HOST...</b>");
            dbhost = dbcenvs.getProperty("DB_HOST");
		String user_input_dbhost = WebRequestUtil.getCookieValue(request,response,"aolj_test_input_host");
		if (dbhost != null && dbhost.equalsIgnoreCase(user_input_dbhost))
			out.println("<i>verified:</i>"+dbhost+"<p>");
		else
			{
			out.println("<Br><b><font color=red>ERROR:</b>DB_HOST value set in dbc file is: " + dbhost+"</font><BR>");
			out.println("the host value you input in Step 1 was: " + user_input_dbhost+"<BR>");
			out.println("Please correct the dbc file or <a href=\"aoljtest.jsp\">restart the test</a> with the correct host value.<p>");
			}		

		out.println("<b>Checking DB_PORT...</b>");
            dbport = dbcenvs.getProperty("DB_PORT");
		String user_input_dbport = WebRequestUtil.getCookieValue(request,response,"aolj_test_input_port");
		if (dbport != null && dbport.equalsIgnoreCase(user_input_dbport))
			out.println("<i>verified:</i>"+dbport+"<p>");
		else
			{
			out.println("<Br><b><font color=red>ERROR:</b>DB_PORT value set in dbc file is: " + dbport+"</font><BR>");
			out.println("the port value you input in Step 1 was: " + user_input_dbport+"<BR>");
			out.println("Please correct the dbc file or <a href=\"aoljtest.jsp\">restart the test</a> with the correct port number.<p>");
			}		

		out.println("<b>Checking APPS_JDBC_DRIVER_TYPE...</b>");
            String drivertype = dbcenvs.getProperty("APPS_JDBC_DRIVER_TYPE");
		if (drivertype != null && drivertype.toUpperCase().equalsIgnoreCase("THIN"))
			out.println("<i>verified:</i>"+drivertype+"<p>");
		else
			{
			out.println("<Br><b><font color=red>ERROR:</b>APPS_JDBC_DRIVER_TYPE value set in dbc file is: " + drivertype+"</font><BR>");
			out.println("Driver type should be set to be THIN, please correct the dbc file.<p>");
			}


    out.println("<b>Checking GWYUID...</b>");
    String gwyuid = dbcenvs.getProperty("GWYUID");
    String gwyuser = null;
    String gwypwd = null;
    int index = gwyuid.indexOf("/");
    if(index != -1)
    {
      gwyuser = gwyuid.substring(0,index);
      gwypwd = gwyuid.substring(index+1);
    }
    out.println("<br>Trying to make a connection with "+gwyuser+"/"+gwypwd+"...");
		DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
		String connStr = "jdbc:oracle:thin:@"+dbhost+":"+dbport+":"+twotask;
		Connection conn = null;		
		try{
		  conn = DriverManager.getConnection(connStr,gwyuser,gwypwd);
		  if (conn==null)
			out.println("<br><B><font color=red>ERROR:</b>Failed to make connection using the given gwyuid: " + gwyuid+"</font></font><p>");
		  else
			out.println("succeed.<p>");
		  }catch (Exception e)
			{
			out.println(e.toString());
			out.println("<br><B><font color=red>ERROR:</b>Failed to make connection using the given gwyuid: " + gwyuid+", please make sure GWYUID is set correctly.</font>");
			}


		out.println("<b>Checking APPL_SERVER_ID...</b><BR>");

		//should not use the gateway connection to query for checking APPL_SERVER_ID
		String user = WebRequestUtil.getCookieValue(request,response,"aolj_test_input_username");
		String pwd = WebRequestUtil.getCookieValue(request,response,"aolj_test_input_password");

		DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
		String realConn = "jdbc:oracle:thin:@"+dbhost+":"+dbport+":"+twotask;
		Connection realconn = null;		
		try{
		  realconn = DriverManager.getConnection(realConn,user,pwd);
		  if (realconn==null)
			out.println("<br><B><font color=red>ERROR:</b>Failed to make connection using : " + user + "/" + pwd + ".</font><p>");
		  }catch (Exception e)
			{
			out.println("<br><B><font color=red>ERROR:</b>Exception when making connection using : " + user + "/" + pwd + ".</font><p>");		
			out.println(e.toString());
			}

		 if (realconn!=null)
		   {
      	      String appl_server_id = dbcenvs.getProperty("APPL_SERVER_ID");
		    try{	
			String sql = "select server_id from FND_APPLICATION_SERVERS " +
					 "where server_address = '*' ";
			//out.println("sql: " + sql);
			Statement stmt = realconn.createStatement();
			ResultSet rs1 = stmt.executeQuery(sql);
			String security_on="OFF";
			if (rs1.next())
			  {
				security_on = rs1.getString(1);
				if (!security_on.equalsIgnoreCase("ON")) out.println("<B><font color=red>WARNING: </B></font>");
				out.println("Security in database turned " + security_on + ".<br>");
                    }
			else
				out.println("Security not defined, SQL executed: <br>"+ sql);

			stmt.close();

			out.println("Verifying SERVER_ID ...<BR>");
			String sql2 = "select server_id from fnd_nodes " +
					 " where server_id = ? ";
			PreparedStatement pStmt = realconn.prepareStatement(sql2);
			pStmt.setString(1,appl_server_id);
			ResultSet rs2 = pStmt.executeQuery();
			boolean id_found = rs2.next();

			if (id_found)
				out.println("APPL_SERVER_ID verified. <br>");
			else
			  {
 				if (security_on.equalsIgnoreCase("OFF"))
    			 	  out.println("<B><font color=red>WARNING: </b></font>APPL_SERVER_ID specified in the dbc file not registered in db, if security is turned on, login will not succeed.</font><p>"); 
  				else 
    			 	  out.println("<B><font color=red>WARNING: </b></font>Security turned on in DB and the APPL_SERVER_ID specified in the dbc file is incorrect, login will not succeed.</font><p>"); 
  			  }
                 }//end try
			catch (SQLException e)
			{
			out.println("<font color=red>Exception happened while trying to verify APPL_SERVER_ID: <BR>");
			out.println("Error Code: " + e.getErrorCode() + "," + e.toString() + "<BR></font>");
			}
			catch (Exception e)
			{
			out.println("<font color=red>Exception happened while trying to verify APPL_SERVER_ID: " + e.toString() + "<BR></font>");
			}

		out.println("<B>Checking guest user/password...</b>");

    String guest = dbcenvs.getProperty("GUEST_USER_PWD");
    String guser = null;
    String gpwd = null;
    index = guest.indexOf("/");
    if(index != -1)
    {
	    	guser = guest.substring(0,index);
	    	//out.println("<BR>guest user="+guser+"<BR>");
	    	gpwd = guest.substring(index+1);
	    	//out.println("guest pwd="+gpwd+"<BR>");
    }

		String sql2 = "select encrypted_user_password from fnd_user " +
				  " where user_name = ? ";
		String encryptedPwd="";
		PreparedStatement pStmt2 = realconn.prepareStatement(sql2);
		pStmt2.setString(1, guser.toUpperCase());
		//out.println("guser=" + guser);
		ResultSet rs = pStmt2.executeQuery();
		if (rs.next())
		  {
		   encryptedPwd = rs.getString(1);
		  }		
		//out.println("get encryptedPwd from database: " + encryptedPwd + "<BR>");

	AppsContext ctx = new AppsContext(realconn);
	String[] encApplsysPwdArray = ctx.getSessionManager().getEncApplsysPwd(guser.toUpperCase(),realconn);
	if (encApplsysPwdArray==null)
	  out.println("<BR><b><font color=red>ERROR:</b>Failed to get encrypted applsys's password, can't continue to verify guest password.</font></b><BR>");
	else 
	{
	String encApplsysPwd = encApplsysPwdArray[1];
	//out.println("encApplsysPwd = " + encApplsysPwd);
	if (encApplsysPwd==null)
	  out.println("<BR><b><font color=red><b>ERROR:</b>Failed to get encrypted applsys's password, can't continue to verify guest password.</font></b><BR>");
	else
	  {
	   AolSecurity as = new AolSecurity();
	   String applsysPwd = as.decrypt(guest.toUpperCase(),encApplsysPwd);
	   //String applsysPwd = as.decrypt("GUEST/GUEST",encApplsysPwd);
	   //String applsysPwd = as.decrypt(gpwd,encApplsysPwd);
	   if (applsysPwd==null)
	     out.println("<BR><b><font color=red>ERROR:</b>Failed to decrypt applsys's password, can't continue to verify guest password.</font></b><BR>");
	   else 
	     {
             //out.println("applsysPwd= " + applsysPwd);
	     String correctGuestPwd = as.decrypt(applsysPwd, encryptedPwd);
	     //out.println("correctGuestPwd = " + correctGuestPwd);
	     if (correctGuestPwd==null)
	       out.println("<BR><font color=red><b>ERROR:</b>Failed to decrypt guest password. </font></b><BR>");
	     else 
	       {
	       if (correctGuestPwd.equalsIgnoreCase(gpwd))
		 {
		 out.println("...<i>verified:" + guest + "</i><BR>");
		 //compare it with profile settings
		 //the guestUserPwd has been verified to a valid one, this is
		 //the last dbc setting being verified,so by now we know it is
		 //a good dbc file, using it to make a AppsContext to get profile.

		 //String host=request.getServerName();
        	 //int port=request.getServerPort();

		 WebAppsContext wac = new WebAppsContext(host,new Integer(port).toString(),dbcfile);
		 String p_guest = wac.getProfileStore().getProfile("GUEST_USER_PWD");
		 if (!guest.toUpperCase().equals(p_guest.toUpperCase()))
		 	out.println("<B><font color=red>WARNING:</font></B> GUEST_USER_PWD specified differently in profile store (" + p_guest + ").<BR>"); 
		 }
	       else
		 out.println("<BR><B><font color=red>ERROR: The GUEST_USER_PWD entry is incorrect, the password should be " + correctGuestPwd + ". Please correct the dbc file and try again.</font></b><BR>");
	       } //else correctGuestPwd==null)
             } //else applsysPwd==null)
           } //else encApplsysPwd==null)
         } //else encApplsysPwdArray==null)

	out.println(ctx.getErrorStack().getAllMessages());
	}//end if realconn!=null

	out.println("<p>Continue to next step only if you see no errors in this page. <BR>");
	response.addCookie(new Cookie("guest",dbcenvs.getProperty("GUEST_USER_PWD")));
	out.print("<h3><pre><a href=\"aolj_conn_test.jsp?dbc="+dbcfile+"&guest="+dbcenvs.getProperty("GUEST_USER_PWD")+"\"+>Next</a> (Make an AOL/J Connection)");
	//out.println("     <a href=aolj_locate_dbc.jsp?dbid="+dbcfile+">Back</a></h3><BR></pre>");

	} //end try
	catch (Exception e)
	{
	out.println("<p><B>" + e.toString() + "</b>");
	}
    }//end else



%>


</body>
</html>
