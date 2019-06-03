<%-- =========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA        |
 |                         All rights reserved.                               |
 +============================================================================+
 | FILENAME                                                                   |
 |                                                                            |
 |   AoljTestError.jsp                                                        |
 |                                                                            |
 | DESCRIPTION                                                                |
 |                                                                            |
 |   The error page for the AOL/J Diagnostics Framework.                      |
 |   This page handles any exceptions thrown by AoljTestRequest.jsp and       |
 |   AoljTestResult.jsp.                                                      |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | DEPENDENCIES                                                               |
 |                                                                            |
 |   Revision  New Dependencies Since R11i                                    |
 |   --------  ---------------------------                                    |
 |   115.0     None                                                           |
 |                                                                            |
 | HISTORY                                                                    |
 |                                                                            |
 |   04-oct-2000  kjentoft  Created.                                          |
 +========================================================================= --%>
<%@ page import = "oracle.apps.fnd.common.VersionInfo" %>
<%! public static final String RCS_ID = 
    "$Header: AoljTestError.jsp 115.0 2000/10/05 13:48:33 pkm ship        $"; %>
<%! public static final boolean RCS_ID_RECORDED = 
    VersionInfo.recordClassVersion(RCS_ID, "oa_html.jsp.fnd"); %>
<%@ page language="java" isErrorPage="true" %>

<HTML>
<TITLE>
AOL/J Diagnostics Error Page
</TITLE>
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

<p>
<b>ERROR:</b> Please contact your system administrator.
<%
if(exception != null)
{ 
  %>
  <p>
  Error: <%= exception.toString() %>
  <p>
  Message: <%= exception.getMessage() %>
  <p>
  Stack Trace:
  <blockquote>
  <% 
  PrintWriter outPrintWriter = null;
  try{
    outPrintWriter = new PrintWriter(out);
    exception.printStackTrace(outPrintWriter);
  }catch(Throwable t){
    exception.printStackTrace();
    t.printStackTrace();
    %>Not able to print stack trace to page.<br>  
      See standard error stream for details.<%
  }finally{
    if(outPrintWriter != null) outPrintWriter.flush();
    if(outPrintWriter != null) outPrintWriter.close();
  }
  %>
  </blockquote>
  <%
}
%>
</BODY>
</HTML>
