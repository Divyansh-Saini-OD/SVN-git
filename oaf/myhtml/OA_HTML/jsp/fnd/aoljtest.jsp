<%! public static final String RCS_ID = "$Header: aoljtest.jsp 115.5 2003/04/18 17:56:29 rtse ship $"; %>
<!--
This is the starting point of the AOL/J Connection Testing Pages, the tests
will be carried out in the following order until error is found:

aoljtest.jsp	
	-- staring point, prompt user to input login information
aolj_native_conn_test.jsp	
	-- try to create a native JDBC connection 
aolj_locate_dbc.jsp
	-- prompt user to input the name of the dbc file that he is using,
	   and verify that the name is correct and the dbc file is 
	   can be found at the right place.
aolj_verify_dbc_content.jsp
	-- once found the dbc file in the previous test, verify the settings
	   in the dbc file one by one.
aolj_conn_test.jsp
	-- if no error is found in the dbc file content, go ahead to use it
	   it to create an AOL/J connection.
login.jsp
	-- test login to create an ICX session.
resp.jsp
	-- display the responsibility list of the logged-in user, user selects
	   a responsibility to continue.
func.jsp
	-- display the fully displayable menu tree of the selected 
	   responsibility, user selects a function to run.
-->
	   
<%

String jtfdbc = System.getProperty("JTFDBCFILE");
String host = "";
String twotask = "";

if(jtfdbc != null)
{
  try
  {
    String dbc = new File(jtfdbc).getName();

    int dotIndex = dbc.lastIndexOf(".dbc");

    if(dotIndex != -1)
    {
      dbc = dbc.substring(0,dotIndex);
    }

    int underscoreIndex = dbc.indexOf("_");

    if(underscoreIndex != -1)
    {
      host = dbc.substring(0,underscoreIndex);
      twotask = dbc.substring(underscoreIndex+1,dbc.length());
    }
  }
  catch(Exception e)
  {
  }
}

%>  

<html>
<title>Apps Schema Connection</title>
<body>
<form name="sel_db" action="aolj_native_conn_test.jsp" method="POST">

<h1>Step 1. Verify Login Information</h1><p>

Please provide the following information for the database that you
are trying to connect to:
<BR><BR>
<pre>
Apps Schema Name:     <input type=text name="username" size="20" value=""> e.g. apps
Apps Schema Password: <input type=password name="password" size="20" value=""> e.g. apps
Oracle SID:           <input type=text name="database" size="20" value=""> e.g. mydb
Host Name:            <input type=text name="host" size="20" value=""> e.g. myhost
Port Number:          <input type=text name="port" size="20" value=""> e.g. 1521
</pre>
<BR>

<input type="Submit" name="submit" value=" Test ">
<input type="Reset" name="clear" value="  Clear">
</form>

</body>
</html>
