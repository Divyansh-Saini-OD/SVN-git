<%--
 /*===========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  FILENAME                                                                 |
 |      fndping.jsp                                                          | 
 |                                                                           |
 |  DESCRIPTION                                                              |
 |      JSP to ping the Web server that's supposed to be running the JSP.    |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |  HISTORY                                                                  |
 |       09-JUN-00  R Tse Created.                                           |
 |       02-AUG-00  R Tse Used static version of Ping.jspPing().             |
 +===========================================================================*/
--%>

<%@ page import="oracle.apps.fnd.common.*"%>

<%! public static final String RCS_ID =
  "$Header: fndping.jsp 115.6 2000/10/17 14:49:22 pkm ship  $"; %>
<%! public static final boolean RCS_ID_RECORDED =
  VersionInfo.recordClassVersion(RCS_ID,"oa_html.jsp.fnd"); %>

<%

  String dbc = request.getParameter("dbc");

  if(dbc == null)
  {
    out.println("Must supply a DBC file name.");
  }
  else
  {
    out.println(Ping.jspPing(request.getServerName(),
      request.getServerPort(),dbc));
  }
%>
