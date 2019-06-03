<!--
 Example JSP of how to incorporate new session timeout features.
-->

<%@ page language="java" %>
<%@ page import="java.sql.*"%>
<%@ page import="oracle.apps.fnd.common.WebAppsContext" %>
<%@ page import="oracle.apps.fnd.common.WebRequestUtil" %>
<%@ page import="oracle.apps.fnd.common.ResourceStore" %>
<%@ page import="oracle.apps.fnd.common.VersionInfo" %>

<%!
  public static final String RCS_ID =
    "$Header: fndexample_long.jsp 115.1 2001/10/29 20:50:14 pkm ship   $";
  public static final boolean RCS_ID_RECORDED =
    VersionInfo.recordClassVersion(RCS_ID,"oa_html.jsp.fnd");
%>

<HTML>
<HEAD><TITLE>AOL/J ValidateSession example</TITLE></HEAD>
<BODY>

<%
  //
  // This breaks out into separate calls what the
  // WebRequestUtil.validateContext method does automatically, for
  // jsp files that may need to extend the validateContext example
  // (eg, to change the default error messages).
  //
  WebAppsContext ctx = null;

  try
  {
    //
    // initialize the WebAppsContext, and get the session cookie
    // associated with it.
    //
    ctx = WebRequestUtil.createWebAppsContext(request, response);
    String cookieVal = WebRequestUtil.getSessionCookie(request,response,ctx);
    if ( cookieVal == null ) return;

    //
    // Now validate the session cookie.  If validation fails, call
    // the (local) handleValidationFailure method to check whether
    // it failed because it was an expired or an invalid session.
    //
    boolean result = ctx.validateSession(cookieVal, true);
    if ( !result )
    {
      handleValidationFailure(request,response,ctx,cookieVal,out);
      return;
    }

    //
    // If we reach here, we've successfully authenticated the session.
    // Put your application-specific logic here.  In the simple example
    // below, we select the user name and responsibility name from dual.
    //
    out.println(new java.util.Date().toString() + "<BR>");
    out.println("<B>Successfully authenticated session!</B><BR>");
    out.println("<HR>");

    Connection conn = ctx.getJDBCConnection();
    PreparedStatement statement = null;

    try
    {
      String sql = "select fnd_global.user_name, fnd_global.resp_name " +
	           "from dual";
      statement=conn.prepareStatement(sql);
      ResultSet rs = statement.executeQuery();

      if ( rs.next() )
      {
	ResourceStore resStore = ctx.getResourceStore();
	String userLabel = resStore.getResourceText("FND", "USER");
	String respLabel = resStore.getResourceText("FND", "RESPONSIBILITY");

	out.println(userLabel+ " - " + rs.getString(1)+ "<BR>");
	out.println(respLabel+ " - " + rs.getString(2)+"<BR>");
      }
    }
    catch ( SQLException sqle )
    {
      out.println("<PRE>");
      sqle.printStackTrace(new PrintWriter(out));
      out.println("</PRE>");
    }
    finally
    {
      try { if ( statement != null ) statement.close(); }
      catch (SQLException e) {}
    }

  }
  catch ( Exception ex )
  {
    out.println("<PRE>");
    ex.printStackTrace(new PrintWriter(out));
    out.println("</PRE>");
  }
  finally
  {
    if ( ctx != null ) ctx.freeWebAppsContext();
  }

%><%!

  /*
   * Call this if a validateSession call has failed - now there are
   * two reasons this may occur.  It may fail because the session is
   * invalid, or it may fail because the session has expired.  In
   * the latter case, we want to give the user a chance to resurrect
   * that session and continue.
   *
   * In order for recreation of the session to work, the user needs to
   * be reauthenticated and the same session_id needs to be used (ie
   * the same row in icx_sessions).  The WebAppsContext.recreateURL
   * method provides the URL needed for this to work, the code below
   * will open up a separate window to relogin the user.
   *
   */
  void handleValidationFailure ( HttpServletRequest req,
				 HttpServletResponse res,
				 WebAppsContext ctx,
				 String cookieVal,
				 JspWriter o )
     throws IOException
  {

    //
    // Check whether it failed because the session status was EXPIRED
    //
    printErrorStack(o, ctx);
    String sessionStatus = ctx.checkSession(cookieVal);
    o.println("Session status: "+ sessionStatus+"<BR>");

    //
    // if validation failed because the session expired, give the
    // user a chance to revalidate.
    //
    if ( sessionStatus.equalsIgnoreCase("EXPIRED") )
    {
      //
      // call recreateURL to get the fully qualified URL used for
      // reconnecting.
      //
      ResourceStore resStore = ctx.getResourceStore();
      String expiredMsg =
	resStore.getResourceText("FND", "FND_SESSION_ICX_EXPIRED_RELOAD");
      o.println(expiredMsg);

      String recreateURL = ctx.getRecreateURL(cookieVal);
      String HTMLout = WebRequestUtil.getLaunchPage(recreateURL);
      o.println(HTMLout);
    }

    //
    // otherwise go to the login page.
    //
    else
    {
      String loginURL = ctx.getLoginURL();
      res.sendRedirect(loginURL);
    }
  }


  /*
   * Helper function for printing out an error stack.
   */
  void printErrorStack(JspWriter o, WebAppsContext ctx) throws IOException {
    o.println("<PRE>");
    o.println(ctx.getErrorStack().getAllMessages());
    o.println("</PRE>");
  }

%>
</BODY></HTML>
