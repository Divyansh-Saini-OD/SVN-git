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
 |    29-MAY-02  RTSE  Created.                                              |
 +===========================================================================*/
--%>

<%@ page import="oracle.apps.fnd.common.VersionInfo"%>
<%@ page import="oracle.apps.fnd.functionSecurity.Function"%>
<%@ page import="oracle.apps.fnd.functionSecurity.RunFunction"%>

<%! public static final String RCS_ID =
  "$Header: RF.jsp 115.4 2003/02/20 19:28:01 rtse ship $"; %>
<%! public static final boolean RCS_ID_RECORDED =
  VersionInfo.recordClassVersion(RCS_ID,"oa_html.jsp.fnd"); %>

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
      rf.close();
      response.sendRedirect(url + getPassedParameters(request));
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

<%!

  /**
   * Return a string containing the original parameters passed into the
   * HTTP request.  We need these original parameters when we forward
   * to another URL because OA Framework relies on them.
   */
  private String getPassedParameters(HttpServletRequest request)
  {
    StringBuffer passedParameters = new StringBuffer();
    Enumeration parameterNames = request.getParameterNames();

    while(parameterNames.hasMoreElements())
    {
      String parameterName = (String) parameterNames.nextElement();

      if(!parameterName.equals("dbc") &&
        !parameterName.equals("function_id") &&
        !parameterName.equals("resp_id") &&
        !parameterName.equals("resp_appl_id") &&
        !parameterName.equals("security_group_id") &&
        !parameterName.equals("params"))
      {
        String[] parameterValues = request.getParameterValues(parameterName);

        if(parameterValues != null)
        {
          for(int i = 0; i < parameterValues.length; i++)
          {
            passedParameters.append("&" + parameterName + "=" +
              parameterValues[i]);
          }
        }
      }
    }

    return passedParameters.toString();
  }

%>
