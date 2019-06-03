<%-- =========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA        |
 |                         All rights reserved.                               |
 +============================================================================+
 | FILENAME                                                                   |
 |   AoljTestRequest.jsp                                                      |
 |                                                                            |
 | DESCRIPTION                                                                |
 |   The Request UI for the AOL/J Diagnostics Framework.                      |
 |   This file dynamically generates a form for selecting available tests.    |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | The URL parameters that are used to send package, test, and parameter      |
 | names and values to the Results UI are encoded as follows, where n, m,     |
 | and l are all consecutively assigned integers starting with 0:             |
 |                                                                            |
 |   Pn: the nth package                                                      |
 |   PnTm: the mth test in the nth package                                    |
 |   PnTmPNl: the lth parameter name of the mth test in the nth package       |
 |   PnTmPVl: the lth parameter value of the mth test in the nth package      |
 |   NP: the total number of packages                                         | 
 |   NPnT: the total number of tests in the nth package                       |
 |   NPnTmP: the total number of parameters in the mth test in the nth package|
 |                                                                            |
 | A word about parameters.  This file requires that the default parameter    |
 | hashtable that it gets from the test class will be made up of string       |
 | name and value pairs.  If the hashtable key or value is not a string,      |
 | the results are not going to be nice.                                      |
 |                                                                            |
 | DEPENDENCIES                                                               |
 |                                                                            |
 | Revision  New Dependencies Since R11i                                      |
 | --------  ---------------------------                                      |
 | 115.0     AoljTestGuide.java 115.1                                         |
 |           AoljTestResult.jsp 115.0                                         |
 | 115.1     ???                                                              |
 | 115.2     ???                                                              |
 | 115.3     ???                                                              |
 | 115.4     AoljTestError.jsp 115.0                                          |
 |                                                                            |
 | This file forms part of the AOL/J Diagnostics Framework.  The files        |
 | that compose the framework are functionally interdependent.  Changes to    |
 | the component interfaces will introduce version dependencies.  These       |
 | dependencies are currently being tracked in the file AoljTestResult.jsp.   |
 | Refer to AoljTestResult.jsp for a list of the files/versions on which this |
 | file depends.                                                              |
 |                                                                            |
 | HISTORY                                                                    |
 |   05-jun-2000  kjentoft  Created.  This file replaces AoljTest.html in the |
 |                          AOL/J Diagnostics Framework.                      |
 |   13-jun-2000  kjentoft  Modified UI to display test search and selection  |
 |                          on the same page.                                 |
 |                          Added test description and test user name.        |
 |   15-jun-2000  kjentoft  Added function security to check if user/session  |
 |                          has permission to use the function.               |
 |   27-jun-2000  kjentoft  Display system classpath as options in selection  |
 |                          list for form's classpath field instead of        |
 |                          printing it out as text.                          |
 |   04-oct-2000  kjentoft  Use AoljTestError.jsp to handle uncaught          |
 |                          exceptions.                                       |
 +========================================================================= --%>
<%@ page import = "oracle.apps.fnd.common.FunctionManager" %>
<%@ page import = "oracle.apps.fnd.common.VersionInfo" %>
<%@ page import = "oracle.apps.fnd.common.WebRequestUtil" %>
<%@ page import = "oracle.apps.fnd.common.WebAppsContext" %>
<%@ page import = "java.io.File" %>
<%! public static final String RCS_ID = "$Header: AoljTestRequest.jsp 115.4 2000/10/05 13:48:39 pkm ship      $"; %>
<%! public static final boolean RCS_ID_RECORDED =
    VersionInfo.recordClassVersion(RCS_ID, "oa_html.jsp.fnd"); %>
<%@page language="java" errorPage="AoljTestError.jsp"%>
<jsp:useBean id="foo" scope="page" class="oracle.apps.fnd.test.AoljTestGuide" />

<HTML>
<BODY bgcolor="#CCCCCC">
<!--Outer table containing toolbar and logo cells-->
<TABLE width=100% Cellpadding=0 Cellspacing=0 border=0>
<tr><td align=left>
  <TABLE cellpadding="0" cellspacing="0" border="0">
  <TR><TD height="30" nowrap align="middle"><FONT style="Arial, Helvetica, Geneva, sans-serif" color="#336699" size="+2"><B><I>&nbsp;AOL/J Diagnostics&nbsp;</I></B></FONT>
  </TD></TR>
  </TABLE>
</td></tr>
</TABLE>

<% 
pageBody:
{
  WebAppsContext currentWAC = null;
  FunctionManager currentFM = null;
  boolean isValidFunction = false;
  String sessionid = request.getParameter("sessionid");
  String dbc = request.getParameter("dbc");
  try{
    currentWAC = WebRequestUtil.validateContext(request,response);
  }catch(IOException ioe){
    throw ioe;
  }
  if(currentWAC == null)  // Session is not valid
  {
    %><p><b>ERROR:</b> Session is not valid!<% 
    break pageBody;
  }
  currentFM = new FunctionManager(currentWAC);
  isValidFunction = currentFM.testFunc("FND_AOLJ_TEST");
  if(!isValidFunction)  // Function is not valid
  {
    %><p><b>ERROR:</b> Current user/responsibility does not have permission 
      to run this function.<%  
    currentWAC.freeWebAppsContext();
    currentWAC = null;
    break pageBody;
  }
  String classPath = request.getParameter("CLASSPATH");
  String packageTop = request.getParameter("PACKAGETOP"); 
  String submit = request.getParameter("submit"); 
  String dbcFilePathName = null;
  if(classPath == null || classPath.equals(""))
  {
    classPath = "";
    String tSystemClassPath = System.getProperty("java.class.path");
    StringTokenizer tPath =
        new StringTokenizer(tSystemClassPath, File.pathSeparator, false);
    String tClassPath = null;
    try{
      findAppsDotZip: while(tPath.hasMoreTokens())
      {
        tClassPath = tPath.nextToken();
        if(tClassPath.endsWith("apps.zip"))
        {
          classPath = tClassPath;
          break findAppsDotZip;
        }  
      }
    }catch(NoSuchElementException nsee){
    }
  }
  else
  {
    classPath = classPath.trim();
  }
  if(packageTop == null || packageTop.equals(""))
  {
    packageTop = "oracle.apps.fnd";
  }
  else
  {
    packageTop = packageTop.trim();
  }
  if(currentWAC != null)
  {
    dbcFilePathName = currentWAC.generateDBCPath(request.getServerName(),
                  String.valueOf(request.getServerPort()), dbc);
    currentWAC.freeWebAppsContext();
    currentWAC = null;
  }
  else
  {
    dbcFilePathName = "."+File.separator;
  }
  String dbcFilePath = null;
  try{
    dbcFilePath = dbcFilePathName.substring(0, 
        dbcFilePathName.lastIndexOf(File.separator+dbc));
  }catch(IndexOutOfBoundsException ioobe){
    dbcFilePath = null;
  }catch(NullPointerException npe){
    dbcFilePath = null;
  }
  //
  // Form used to search for tests.
  // Select whether to look in apps.zip only for classes, or elsewhere.
  //
  %>
  <FORM TYPE=POST ACTION=AoljTestRequest.jsp>
  <input TYPE=hidden name=dbc VALUE=<%=dbc%>>
  <input TYPE=hidden name=sessionid VALUE=<%=sessionid%>>
  <font color="black">
  <h4>Search For Tests</h4>
  <dl><dd>
  <table>
  <tr>
  <td align=right>Classpath</td>
  <td align=left><select name=CLASSPATH>
                 <option selected><%=classPath%>
  <%
      StringTokenizer tPath =
        new StringTokenizer(System.getProperty("java.class.path"),
                            File.pathSeparator, false);
      try{
        while(tPath.hasMoreTokens())
        {
  %>
                 <option><%=tPath.nextToken()%>
  <%
        }
      }catch(NoSuchElementException nsee){
      }
  %>
                 </select>
  </td>
  </tr>
  <tr>
  <td align=right>Package</td>
  <td align=left><input TYPE="Text" size=60 name=PACKAGETOP
                  value=<%=packageTop%>></td>
  </td>
  </tr>
  <tr>
  <td rowspan=2 align=right valign=top>Search Subpackages</td>
  <td align=left>
      <input type="radio" name="subpackage" value="y" checked>Yes</td>
  </tr>
  <tr>
  <td align=left><input type="radio" name="subpackage" value="n">No</td>
  </tr>
  <tr>
  <td> </td>
  <td align=left><INPUT TYPE=submit name=submit Value="Search"></td>
  </tr>
  </tr>
  </table>
  </tr>
  </dd></dl>
  </font>
  </FORM>
  <%
  //
  // Form used to select tests and enter parameters.
  //
  %>
  <FORM TYPE=POST ACTION=AoljTestResult.jsp>
  <input TYPE=hidden name=dbc VALUE=<%=dbc%>>
  <input TYPE=hidden name=sessionid VALUE=<%=sessionid%>>
  <font color="black">
  <h4>Select Tests</h4>
  <%
  String parameterName;
  String parameterValue;
  String className;
  String classPackageName;
  String fullClassName;
  String testDescription = null;
  String userTestName = null;
  String displayTestName = null;
  Hashtable testParameters;
  Hashtable testName;
  Hashtable packageName;
  int packageNumber;
  int testNumber;
  int parameterNumber;
  foo.findTests(classPath,packageTop);
  testName = foo.getTestName();
  packageName = foo.getPackageName();
  for (packageNumber = 0;
       (classPackageName = (String)packageName.get("P"+packageNumber)) != null;
       packageNumber++)
  {
    %>
    <dl><dd>
    <table width=90%>
      <tr><td colspan=3 align=left>
        <h4><input TYPE=hidden name=<%= "P"+packageNumber %> 
                   VALUE=<%=classPackageName%>>
        <%=classPackageName%></h4>
      </td></tr>
    <%
    for (testNumber = 0;
         (className = (String)testName.get("P"+packageNumber+"T"+testNumber)) 
           != null;
         testNumber++)
    {
      fullClassName = classPackageName + "." + className;
      try{
        userTestName = 
          ((oracle.apps.fnd.test.AoljTestable)Class.forName(
              fullClassName).newInstance()).getUserTestName();
      }catch(IncompatibleClassChangeError icce){
      }
      if(userTestName != null)
      {
        displayTestName = userTestName+" ("+className+")";
      }
      else
      {
        displayTestName = className;
      }
      %>
      <tr><td colspan=3 align=left>
          <input TYPE=checkbox name=<%="P"+packageNumber+"T"+testNumber%> 
                 VALUE=<%=className%> >
          <%=displayTestName%> 
      </td></tr>
      <%
      try{
        testDescription = 
          ((oracle.apps.fnd.test.AoljTestable)Class.forName(
              fullClassName).newInstance()).getTestDescription();
      }catch(IncompatibleClassChangeError icce){
      }
      if(testDescription != null)
      { %>
        <tr>
          <td></td>
          <td colspan=2 align=left><%=testDescription%></td>
        </tr> <%
      }
      testParameters = 
        ((oracle.apps.fnd.test.AoljTestable)Class.forName(
            fullClassName).newInstance()).getDefaultParameters();
      parameterNumber = 0;
      if(testParameters != null)
      { 
        for (Enumeration e = testParameters.keys();
             e.hasMoreElements(); 
             parameterNumber++)
        {
          parameterName = (String)e.nextElement();
          if(parameterName.equals("DBC_FILE_PATH"))
          {
            parameterValue = dbcFilePath;
          }
          else if(parameterName.equals("DBC_FILE_NAME"))
          {
            if(dbc==null || dbc.trim().equals(""))
            {
              parameterValue = ".dbc";
            }
            else if(!dbc.endsWith(".dbc"))
            {
              parameterValue = dbc+".dbc";
            }
            else
            {
              parameterValue = dbc;
            }
          }
          else
          {
            parameterValue = (String)testParameters.get(parameterName);
          }
          if(parameterValue == null || parameterValue.trim().equals(""))
          {
             parameterValue = ".";
          }
          %>
          <tr><td ></td>          
              <td align=right width=25%>
              <%=parameterName%> 
              <input TYPE=hidden value=<%= parameterName %> 
              name=<%= "P"+packageNumber+"T"+testNumber+"PN"+parameterNumber %>>
              </td> 
              <td align=left>
              <input TYPE="Text" value=<%= parameterValue %> 
              name=<%= "P"+packageNumber+"T"+testNumber+"PV"+parameterNumber %>>
              </td>
          </tr>
          <% 
        }
      } %>
      <input TYPE=hidden name=<%= "NP"+packageNumber+"T"+testNumber+"P" %> 
             VALUE= <%= parameterNumber %> >
      <% 
    } %>
    <input TYPE=hidden name=<%= "NP"+packageNumber+"T" %> 
           VALUE=<%= testNumber %> >
    <tr><td align=left><INPUT TYPE=submit name=submit Value="Run"></td>
        <td></td>
        <td></td>
    </tr>
    </table>
    </dl></dd>
    <% 
  } %>
  <input TYPE=hidden name=<%="NP"%> VALUE=<%=packageNumber%> >
  <% if(packageNumber == 0)
  { %>
  No tests were found for the specified classpath and package.
  <% } %>
  </font>
  </FORM>
  <% 
} // end pageBody
%>
</BODY>
</HTML>
