<%--
 /*===========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  FILENAME                                                                 |
 |      fndhelputil.jsp                                                      | 
 |                                                                           |
 |  DESCRIPTION                                                              |
 |      JSP for the Oracle Applications Help System Utility.                 |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |  HISTORY                                                                  |
 |       08-MAY-00  R Tse Created.                                           |
 +===========================================================================*/
--%>

<%@ page import = "oracle.apps.fnd.common.VersionInfo" %>
<%@ page import = "oracle.apps.fnd.common.WebAppsContext" %>
<%@ page import = "oracle.apps.fnd.common.WebRequestUtil" %>

<%! public static final String RCS_ID =
  "$Header: fndhelputil.jsp 115.9 2001/12/12 12:09:34 pkm ship  $"; %>
<%! public static final boolean RCS_ID_RECORDED =
  VersionInfo.recordClassVersion(RCS_ID,"oa_html.jsp.fnd"); %>

<jsp:useBean
  id="helputilbean"
  scope="session"
  class="oracle.apps.fnd.help.util.HelpUtilBean"
/>

<%

  String mode = request.getParameter("mode");
  String dbc = request.getParameter("dbc");
  String sessionID = request.getParameter("sessionid");

  if(mode == null)
  {
    if(dbc == null)
    {
      try
      {
        dbc = WebRequestUtil.getDBC(request,response);
      }
      catch(IOException e)
      {
      }
    }

    if(sessionID == null)
    {
      try
      {
        sessionID = getSessionID(request,response,dbc);
      }
      catch(IOException e)
      {
      }
    }

    // We can't proceed without a DBC file name.
    //
    if(dbc == null)
    {
      out.println("Must supply a DBC file name.");
    }
    else
    {
      if(helputilbean.init
        (dbc,sessionID,request.getServerName(),request.getServerPort(),out))
      {
        String clientEncoding = helputilbean.getClientEncoding();

        if(clientEncoding != null)
        {
          response.setContentType("text/html; charset=" + clientEncoding);
        }

        helputilbean.getMainHTML(out);
      }
      else
      {
        helputilbean.getErrorHTML(out);
      }
    }
  }
  else if(mode.compareTo("submit") == 0)
  {
    if(helputilbean.getInitSucceededFlag())
    {
      String action = request.getParameter("action");
      String report = request.getParameter("report");
      String customLevel = request.getParameter("custom_level");
      String language = request.getParameter("language");
      String product = request.getParameter("product");

      String clientEncoding = helputilbean.getClientEncoding();

      if(clientEncoding != null)
      {
        response.setContentType("text/html; charset=" + clientEncoding);
      }

      helputilbean.getActionHTML
        (action,report,customLevel,language,product,out);
    }
    else
    {
      out.println("Bean not initialized.");
    }
  }

  helputilbean.cleanup();
%>


<%!

  private String getSessionID(HttpServletRequest request,
    HttpServletResponse response, String dbc) throws IOException
  {
    String sessionID = WebRequestUtil.getCookieValue(request,response,dbc);

    if(sessionID != null)
    {
      return sessionID;
    }

    String host = request.getServerName();
    String port = new Integer(request.getServerPort()).toString();
    WebAppsContext ctx;

    if(dbc.indexOf(File.separator) == -1)
    {
      ctx = new WebAppsContext(host,port,dbc);
    }
    else
    {
      ctx = new WebAppsContext(dbc);
    }

    String cookieName = ctx.getSessionCookieName();

    ctx.freeWebAppsContext();

    sessionID = WebRequestUtil.getCookieValue(request,response,cookieName);

    return sessionID;
  }

%>
