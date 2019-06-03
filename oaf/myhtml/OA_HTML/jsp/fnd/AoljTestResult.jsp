<%-- =========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA        |
 |                         All rights reserved.                               |
 +============================================================================+
 | FILENAME                                                                   |
 |   AoljTestResult.jsp                                                       |
 |                                                                            |
 | DESCRIPTION                                                                |
 |   The Results UI of the AOL/J Diagnostics Framework.  This file            |
 |   presents results of AOL/J Tests.  The requested test names and           |
 |   parameters are found by parsing the URL request.                         |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | This file requires that the URL parameters used to convey information about|
 | the requested tests follow these very precise naming conventions, where    |
 | n, m, and l are integers:                                                  |
 |                                                                            |
 |   Pn: the nth package                                                      |
 |   PnTm: the mth test in the nth package                                    | 
 |   PnTmPNl: the lth parameter name of the mth test in the nth package       |
 |   PnTmPVl: the lth parameter value of the mth test in the nth package      |
 |   NP: the total number of packages                                         | 
 |   NPnT: the total number of tests in the nth package                       |
 |   NPnTmP: the total number of parameters in the mth test in the nth package|
 |                                                                            |
 | For example, to request the test oracle.apps.fnd.test.AoljTestable_Test,   |
 | which has three test parameters (COLOR, SIZE, and SHAPE), the following URL|
 | parameters would be required in the URL request for this page:             |
 |                                                                            |
 |   "GET AoljTestResult.jsp?                                                 |
 |    P0=oracle.apps.fnd.test&      // name of first package                  |
 |    P0T0=AoljTestable_Test&       // name of first test                     |
 |    P0T0PN0=COLOR&                // name of first parameter                |
 |    P0T0PV0=yellow&               // value of first parameter               |
 |    P0T0PN1=SIZE&                 // name of second parameter               |
 |    P0T0PV1=small&                // value of second parameter              |
 |    P0T0PN2=SHAPE&                // name of third parameter                |
 |    P0T0PV2=circle&               // value of third parameter               |
 |    NP0T0P=3&                  // total number of parameters in first test  |
 |    NP0T=1&                    // total number of tests in first package    |
 |    NP=1&                      // total number of packages                  |
 |    submit=Submit HTTP/1.0"                                                 |
 |                                                                            |
 | DEPENDENCIES                                                               |
 |                                                                            |
 | This file forms part of the AOL/J Diagnostics Framework.  The files        |
 | that compose the framework are functionally interdependent.  Changes to    |
 | the component interfaces will introduce version dependencies.  These will  |
 | be tracked here.                                                           |
 |                                                                            |
 | In addition to the files that make up the framework itself, the tests      |
 | that are run within the framework are also dependent on the interfaces.    |
 | For example, changes to the interface AoljTestable will introduce version  |
 | dependencies with the actual tests that implement the interface.           |
 | Therefore, revisions of the tests will also be tracked here.               |
 |                                                                            |
 | AOL/J Diagnostics Framework                                                |
 | ---------------------------                                                |
 | AoljTest.html              115.0   xxxxx   xxxxx  xxxxx  xxxxx             |
 | AoljTestRequest.jsp        xxxxx   115.0  *115.0  115.1  115.4             |
 | AoljTestResult.jsp         115.0   115.1  *115.0  115.1  115.4             |
 | AoljTestError.jsp          xxxxx   xxxxx   xxxxx  xxxxx  115.0             |
 | AoljTestGuide.java         xxxxx   115.0   115.1  115.2  115.2             |
 | AoljTestBean.java          115.0   115.1   115.1  115.1  115.1             |
 | AoljTestable.java          115.0   115.1   115.1  115.2  115.2             |
 | AoljTestTemplate.java      xxxxx   xxxxx   115.0  115.1  115.2             |
 |                                                                            |
 | * AoljTestRequest.jsp and AoljTestResult.jsp were moved from               |
 |   /fnddev/fnd/11.5/html/ to /fnddev/fnd/11.5/html/fnd/.                    |
 |                                                                            |
 | Tests                                                                      |
 | ---------------------------                                                |
 | oracle.apps.fnd.test:                                                      |
 | AoljTestable_Test.java     115.0   115.1   115.1  115.2                    |
 | MaxDBConnObj_Test.java     115.0   115.1   115.1  115.2                    |
 | oracle.apps.fnd.security:                                                  |
 | DBConnObjPool_Test.java    xxxxx   xxxxx   115.0  115.1                    |
 | DBConnObj_Test.java        xxxxx   xxxxx   115.0  115.1                    |
 | SessionManager_Test.java   115.0   115.1   115.1  115.2                    |
 | oracle.apps.fnd.common                                                     |
 | MultiThreadPool_Test.java  xxxxx   xxxxx   115.0  115.1                    |
 | PoolConc_Test.java         xxxxx   xxxxx   115.0  115.1                    |
 | PoolExample_Test.java      xxxxx   xxxxx   115.0  115.1                    |
 | PoolSeq_Test.java          xxxxx   xxxxx   115.0  115.1                    |
 | PoolableExample_Test.java  xxxxx   xxxxx   115.0  115.1                    |
 |                                                                            |
 | HISTORY                                                                    |
 |   21-mar-2000  kjentoft  Created.                                          |
 |   26-apr-2000  kjentoft  Changed parsing of URL request parameters in order|
 |                          to integrate with AoljTestRequest.jsp instead of  |
 |                          AoljTest.html.                                    |
 |   02-jun-2000  kjentoft  Added session validation.                         |
 |   05-jun-2000  kjentoft  Moved from $fnd/html/ to $fnd/html/fnd/.          |
 |   13-jun-2000  kjentoft  UI improvements.                                  |
 |   15-jun-2000  kjentoft  Added function security.                          |
 |   04-oct-2000  kjentoft  Use AoljTestError.jsp to handle uncaught          |
 |                          exceptions.                                       |
 |   06-oct-2000  kjentoft  Formatting changes.                               |
 |   14-nov-2000  kjentoft  Added timestamp to top of results page.           |
 +========================================================================= --%>
<%@ page import = "java.text.DateFormat" %>
<%@ page import = "oracle.apps.fnd.common.FunctionManager" %>
<%@ page import = "oracle.apps.fnd.common.VersionInfo" %>
<%@ page import = "oracle.apps.fnd.common.WebRequestUtil" %>
<%@ page import = "oracle.apps.fnd.common.WebAppsContext" %>
<%@ page import="oracle.apps.fnd.test.*" %>
<%! public static final String RCS_ID = 
    "$Header: AoljTestResult.jsp 115.5 2001/03/06 14:39:01 pkm ship      $"; %>
<%! public static final boolean RCS_ID_RECORDED =
    VersionInfo.recordClassVersion(RCS_ID, "oa_html.jsp.fnd"); %>
<%@page language="java" errorPage="AoljTestError.jsp"%>
<jsp:useBean id="foo" scope="page" class="oracle.apps.fnd.test.AoljTestBean" />

<HTML>
<BODY bgcolor="#CCCCCC">
<!--Outer table containing toolbar and logo cells-->
<TABLE width=100% Cellpadding=0 Cellspacing=0 border=0>
  <TR>
  <TD height="30" nowrap align="left">
  <FONT style="Arial, Helvetica, Geneva, sans-serif" color="#336699" size="+2"><B><I>
  AOL/J Diagnostics
  </I></B></FONT>
  </TD>
  <TD height="30" nowrap align="right">
  <FONT style="Arial, Helvetica, Geneva, sans-serif" color="#336699" size="+2"><B><I>
  <%=DateFormat.getDateTimeInstance(DateFormat.LONG, DateFormat.LONG).format(new Date(System.currentTimeMillis())).toString()%>
  </I></B></FONT>
  </TD>
  </TR>
</TABLE>

<font size=4 color="black">

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
  currentWAC.freeWebAppsContext();
  currentWAC = null;
  String[] testNames;
  Hashtable allTestParameters;
  Hashtable[] testParameters;
  boolean[] testSuccessful;
  Vector[] testMessages;
  int numberOfPackages;
  int numberOfTests;
  int numberOfParameters;
  int testNumber;
  String packageName;
  String testName;
  String parameterName;
  String parameterValue;
  Vector testNameVector;
  //
  // Parse the URL parameters.
  //
  testNumber = 0;
  allTestParameters = new Hashtable();
  testNameVector = new Vector(); 
  try{ 
    numberOfPackages = Integer.parseInt(request.getParameter("NP"));
  }catch(NumberFormatException nfe){
    %>Could not run tests: URL parameter NP is not an integer.<BR><%
    %><%=nfe.toString()%><BR><%
    numberOfPackages = 0;
  }
  for(int i = 0; i < numberOfPackages; i++)
  {
    packageName = request.getParameter("P"+i); 
    if(packageName != null)
    {
      try{ 
        numberOfTests = Integer.parseInt(request.getParameter("NP"+i+"T"));
      }catch(NumberFormatException nfe){
        %>Could not run tests in package <%=packageName%>: <%
        %>URL parameter NP<%=i%>T is not an integer.<BR><%
        %><%=nfe.toString()%><BR><%
        numberOfTests = 0;
      }
      for(int j = 0; j < numberOfTests; j++)
      {
        testName = request.getParameter("P"+i+"T"+j);
        if(testName != null)
        {
          testNameVector.addElement(packageName+"."+testName);
          try{ 
            numberOfParameters = 
              Integer.parseInt(request.getParameter("NP"+i+"T"+j+"P"));
          }catch(NumberFormatException nfe){
            %>Could not run test <%=testName%>: <%
            %>URL parameter NP<%=i%>T<%=j%>P is not an integer.<BR><%
            %><%=nfe.toString()%><BR><%
            numberOfParameters = 0;
          }
          for(int k = 0; k < numberOfParameters; k++)
          {
            parameterName = request.getParameter("P"+i+"T"+j+"PN"+k);
            parameterValue = request.getParameter("P"+i+"T"+j+"PV"+k);
            if(parameterName!=null && parameterValue!=null)
            {
              allTestParameters.put(testNumber+":"+parameterName, 
                                    parameterValue);
            }
          }
          testNumber++;
        }
      }
    }
  }
  if(testNumber != testNameVector.size()) 
  { 
    %>Warning: something is wrong with the test name vector.  May not be
      able to run tests.<BR><%
  }
  //
  // Copy test names from testNameVector into testNames String array.
  //
  testNames = new String[testNumber];  
  for(int i = 0; i < testNumber; i++)
  {
    try{
      testNames[i] = (String)testNameVector.elementAt(i);
    }catch(ArrayIndexOutOfBoundsException aioobe){
      %>Problem with testNameVector, element number <%=i%>.<BR><%
      %><%=aioobe.toString()%><BR><%
      i = testNumber;
    }
  }
  //
  // Copy test parameters from allTestParameters Hashtable into
  // testParameters Hashtable array.
  //
  testParameters = new Hashtable[testNumber];
  for(int i = 0; i < testNumber; i++)
  {
    testParameters[i] = new Hashtable();
  }
  for (Enumeration e = allTestParameters.keys();
       e.hasMoreElements();)
  {
    int i = -1;
    int j = -1;
    parameterName = (String)e.nextElement();
    parameterValue = (String)allTestParameters.get(parameterName);
    i = parameterName.indexOf(":");
    try{ 
      j = Integer.parseInt(parameterName.substring(0,i));
    }catch(NumberFormatException nfe){
      %>Error in converting hashtable.<BR><%
      %><%=nfe.toString()%><BR><%
      j = -2;
    }
    parameterName = parameterName.substring(i+1);
    if(parameterName!=null && parameterValue!=null)
    {
      testParameters[j].put(parameterName,parameterValue);
    }
  }
  %>
  <h4>Requested Tests</h4>
  <ul>
  <%
  if (testNames != null && testNames.length > 0) 
  {
    for (int i = 0; i < testNames.length; i++) 
    {
      %>
      <li>
      <%
      out.println (testNames[i]);
    }
  } else out.println ("No tests selected.");
  %>
  </ul>
  <%
  if (testNames != null && testNames.length > 0) 
  { %>
    <h4>Test Results</h4>
    <hr>
    <%
    foo.setTestNames(testNames);
    foo.setTestParameters(testParameters);
    foo.runTests();
    testSuccessful = foo.getTestSuccessful();
    testMessages = foo.getTestMessages();
    for (int i = 0; i < testNames.length; i++) 
    {
      out.println ("Test results for " + testNames[i]);
      %>
     <br>
     <%      
     if (testSuccessful[i]){  %>
            <font color="green">Test succeeded!</font><br>
  <%      } else {  %>
            <font color="red">Test failed!</font><br>
  <%      }  %>
  <%      for (int j = 0 ; j < testMessages[i].size() ; j++) 
          { 
            if (testMessages[i].elementAt(j).toString().startsWith("Error:")) 
            { %>
            <font color="red">
            <%= testMessages[i].elementAt(j).toString() %></font><br>
  <%        } else { %>
            <font color="blue">
            <%= testMessages[i].elementAt(j).toString() %></font><br>
  <%        }
          }  %>
  <hr>
  <%
        }
  }
  %>
  </font>
  <%
} // end pageBody
%>
</body>
</html>
