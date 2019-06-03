<%--
 /*===========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  FILENAME                                                                 |
 |      fndhelp.jsp                                                          | 
 |                                                                           |
 |  DESCRIPTION                                                              |
 |      JSP for the Oracle Applications Help System (a.k.a. iHelp).          |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |  HISTORY                                                                  |
 |       20-APR-00  R Tse Created.                                           |
 +===========================================================================*/
--%>

<%@ page import = "oracle.apps.fnd.common.VersionInfo" %>
<%@ page import = "oracle.apps.fnd.common.WebAppsContext" %>
<%@ page import = "oracle.apps.fnd.common.WebRequestUtil" %>

<%! public static final String RCS_ID =
  "$Header: fndhelp.jsp 115.19 2002/07/29 20:01:10 rtse ship $"; %>
<%! public static final boolean RCS_ID_RECORDED =
  VersionInfo.recordClassVersion(RCS_ID,"oa_html.jsp.fnd"); %>

<jsp:useBean
  id="helpbean"
  scope="session"
  class="oracle.apps.fnd.help.viewer.HelpBean"
/>

<%

  String mode = getParameter(request,"mode");
  String dbc = getParameter(request,"dbc");

  if(mode == null || mode.equals("debug"))
  {
    // We can't proceed without a DBC file name.
    //
    if(dbc == null)
    {
      displayInvalidDBCInfo(out);
    }
    else
    {
      String language = getParameter(request,"language");

      if(language == null)
      {
        language = getParameter(request,"lang");
      }

      String rootParent = getParameter(request,"root_parent");

      if(rootParent == null)
      {
        rootParent = getParameter(request,"par_root");
      }

      WebAppsContext ctx = validateContext(request);

      if(ctx == null)
      {
        displayInvalidDBCInfo(out);
      }
      else
      {
        String helpTreeRoot =
          ctx.getProfileStore().getProfile("HELP_TREE_ROOT");

        if(helpTreeRoot == null || helpTreeRoot.equalsIgnoreCase("null"))
        {
          documentMode(request,out);
        }
        else
        {
          if(helpbean.init(language,getParameter(request,"root"),rootParent,
            ctx))
          {
            String clientEncoding = helpbean.getClientEncoding();

            if(clientEncoding != null)
            {
              response.setContentType("text/html; charset=" + clientEncoding);
            }

            out.println(helpbean.getFrameHTML(getParameter(request,"path")));
          }
          else
          {
            out.println(helpbean.getErrorHTML());
          }
        }
      }
    }
  }
  else if(mode.equals("search"))
  {
    String clientEncoding = helpbean.getClientEncoding();

    if(clientEncoding != null)
    {
      response.setContentType("text/html; charset=" + clientEncoding);
    }

    if(helpbean.getInitSucceededFlag())
    {
      out.println(helpbean.getSearchHTML(getParameter(request,"language"),
        getParameter(request,"search_string")));
    }
    else
    {
      displayBeanNotInitializedInfo(out);
    }
  }
  else if(mode.equals("tree"))
  {
    if(helpbean.getInitSucceededFlag())
    {
      String clientEncoding = helpbean.getClientEncoding();

      if(clientEncoding != null)
      {
        response.setContentType("text/html; charset=" + clientEncoding);
      }

      out.println(helpbean.getTreeHTML(getParameter(request,"pad"),
        getParameter(request,"l"),
        getParameter(request,"pa"),
        getParameter(request,"pk"),
        getParameter(request,"na"),
        getParameter(request,"nk")));
    }
    else
    {
      displayBeanNotInitializedInfo(out);
    }
  }
  else if(mode.equals("document"))
  {
    documentMode(request,out);
  }
  else
  {
    // Should never get here.
  }

  helpbean.cleanup();

%>

<%!

  /*
   * Instead of displaying the 3-frame iHelp page, display just the document.
   */
  private void documentMode(HttpServletRequest request, JspWriter out)
    throws IOException
  {
    String dbc = getParameter(request,"dbc");
    String path = getParameter(request,"path");

    // We can't proceed without a DBC file name.
    //
    if(dbc == null)
    {
      displayInvalidDBCInfo(out);
    }
    else
    {
      if(path == null)
      {
        path = "US/FND/@O_HELP";
      }

      WebAppsContext context;

      if(dbc.indexOf(File.separator) == -1)
      {
        context = new WebAppsContext(request.getServerName(),
          Integer.toString(request.getServerPort()),dbc);
      }
      else
      {
        context = new WebAppsContext(dbc);
      }

      java.sql.Connection conn = context.getJDBCConnection();

      String plsqlAgent = context.getURLUtils().plsqlAgent("HELP");

      context.freeWebAppsContext();

      if(conn == null)
      {
        displayInvalidDBCInfo(out);
      }
      else if(plsqlAgent == null)
      {
        out.println("APPS_WEB_AGENT profile option must not be NULL.<p>");

        displayMetaLinkInfo(out);
      }
      else
      {
        String documentLocation = plsqlAgent + "fndgfm/fnd_help.get/" + path;

        String html =
          "<script language=\"javascript\">" + "\n" +
          "location.replace(\"" + documentLocation + "\");" + "\n" +
          "</script>" + "\n";

        out.println(html);
      }
    }
  }

  /*
   * If the parameter contains an HTML tag, then it could be dangerous
   * so return null instead of the actual value.  This pre-caution
   * is needed due to bug 2261580.
   */
  private String getParameter(HttpServletRequest request, String name)
  {
    String value = request.getParameter(name);

    if(value != null && value.indexOf("<") != -1)
    {
      value = null;
    }

    return value;
  }

  /*
   * Return a WebAppsContext after calling validateSession() on it.
   */
  private WebAppsContext validateContext(HttpServletRequest request)
  {
    String host = request.getServerName();
    String port = new Integer(request.getServerPort()).toString();
    String dbc = getParameter(request,"dbc");
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
    String sessionID = null;
    Cookie[] cookies = request.getCookies();

    for(int i = 0; i < cookies.length; i++)
    {
      Cookie cookie = cookies[i];

      if(cookie.getName().equals(cookieName))
      {
        sessionID = cookie.getValue();
        break;
      }
    }

    if(sessionID != null)
    {
      ctx.validateSession(sessionID);
    }

    ctx.getEnvStore().setEnv("HELP_DBC",dbc);
    ctx.getEnvStore().setEnv("HELP_SESSION_ID",sessionID);

    if(ctx.getJDBCConnection() == null)
    {
      return null;
    }

    return ctx;
  }

  /*
   * Display information about why the DBC file may be invalid.
   */
  private void displayInvalidDBCInfo(JspWriter out) throws IOException
  {
    out.println("Must supply a valid DBC file name.<p>");
    out.println("The DBC file must be located in the directory $FND_TOP" +
      File.separator + "secure.<p>");

    displayMetaLinkInfo(out);
  }

  /*
   * Display information about why a JSP bean may not have been initialized.
   */
  private void displayBeanNotInitializedInfo(JspWriter out) throws IOException
  {
    out.println("Bean not initialized.<p>");
    out.println("Please verify that your browser accepts session cookies, " +
      "and then click on your browser's Reload/Refresh button " +
      "to reload this Web page.<p>");

    displayMetaLinkInfo(out);
  }

  /*
   * Display information about a MetaLink trouble-shooting guide.
   */
  private void displayMetaLinkInfo(JspWriter out) throws IOException
  {
    /* Not display anything for now. */

    /*

    out.println("System administrators may refer to MetaLink note 134378.1 " +
      "for trouble-shooting information regarding the " +
      "Oracle Applications Help System.<p>");

    */
  }

%>
