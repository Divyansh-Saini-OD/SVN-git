<%--
/*===========================================================================+
 |      Copyright (c) 2002 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  FILENAME                                                                 |
 |    RF.jsp                                                                 | 
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    RF.jsp validates a session and determines whether a user has access    |
 |    to a specified function.  If the function is found to be accessible    |
 |    to the user, RF.jsp re-directs the user to the function's URL.         |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |                                                                           |
 |  HISTORY                                                                  |
 |    13-DEC-02  RTSE  Created.                                              |
 +===========================================================================*/
--%>

<%@ page import="oracle.apps.fnd.common.VersionInfo"%>
<%@ page import="oracle.apps.fnd.functionSecurity.Function"%>
<%@ page import="oracle.apps.fnd.functionSecurity.RunFunction"%>

<%! public static final String RCS_ID =
  "$Header: RF.jsp 115.4 2003/08/19 17:54:54 rtse ship $"; %>
<%! public static final boolean RCS_ID_RECORDED =
  VersionInfo.recordClassVersion(RCS_ID,"oa_html"); %>

<%

  RunFunction rf = null;
  String url = null;

  try
  {
    rf = new RunFunction(request,response,
      new PrintWriter(new BufferedWriter(out)));

    if(rf.init())
    {
      url = rf.getURL();
      String type = rf.getFunction().getType();

      if(Function.JSP.equals(type))
      {
        int index = url.indexOf("/OA_HTML/OA.jsp");

        if(index == -1)
        {
          rf.close();
          response.sendRedirect(url);
        }
        else
        {
          if("true".equalsIgnoreCase(request.getParameter("debug")))
          {
            out.println(url.substring(index + 9));
          }
          else
          {
            %><jsp:forward page="<%= url.substring(index + 9) %>" /><%
          }
        }
      }
      else
      {
        rf.close();
        response.sendRedirect(url);
      }
    }
    else
    {
      rf.close();
    }
  }
  catch(Exception e)
  {
    response.getWriter().println("<pre>" + "An exception occured." + "\n");
    response.getWriter().println("<pre>" + "URL=" + url + "\n");
    e.printStackTrace(response.getWriter());

    if(rf != null)
    {
      rf.close();
    }
  }

%>
