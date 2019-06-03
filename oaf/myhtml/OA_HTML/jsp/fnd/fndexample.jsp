<!--
 Example of how to incorporate new session timeout features into jsp files.
-->

<%@ page language="java" %>
<%@ page import="java.io.*"%>
<%@ page import="java.sql.*"%>
<%@ page import="javax.servlet.http.*"%>
<%@ page import="oracle.apps.fnd.common.WebAppsContext" %>
<%@ page import="oracle.apps.fnd.common.WebRequestUtil" %>
<%@ page import="oracle.apps.fnd.common.ResourceStore" %>
<%@ page import="oracle.apps.fnd.common.VersionInfo" %>
<%@ page import="oracle.apps.fnd.functionSecurity.Function" %>
<%@ page import="oracle.apps.fnd.functionSecurity.FunctionSecurity" %>
<%@ page import="oracle.apps.fnd.functionSecurity.Resp" %>
<%@ page import="oracle.apps.fnd.functionSecurity.SecurityGroup" %>
<%@ page import="oracle.apps.fnd.functionSecurity.User" %>

<%!
  public static final String RCS_ID =
    "$Header: fndexample.jsp 115.1 2001/10/30 04:47:37 rou noship $";
  public static final boolean RCS_ID_RECORDED =
    VersionInfo.recordClassVersion(RCS_ID,"oa_html.jsp.fnd");
%>

<HTML>
<HEAD>
<TITLE>
 AOL/J ValidateSession example using WebRequestUtil.validateContext
</TITLE>
</HEAD>
<BODY>

<%
  WebAppsContext ctx = null;

  try
  {
    //
    // initialize the WebAppsContext, and get the session cookie
    // associated with it.
    //
/*
    ctx = WebRequestUtil.createWebAppsContext(request, response);
    String cookieVal = WebRequestUtil.getSessionCookie(request,response,ctx);
    if ( cookieVal == null ) out.println("cookieVal is null?");
    else
    {
    //
    // Now validate the session cookie.  If validation fails, call
    // the (local) handleValidationFailure method to check whether
    // it failed because it was an expired or an invalid session.
    //
    String encrypted_tranxid = request.getParameter("transactionid");

    if ( encrypted_tranxid == null )
    {
      boolean result = ctx.validateSession(cookieVal);
      if ( !result )
      {
	out.println("validateSession(" +cookieVal+ ") failed.");
	return;
      }
    }
    else
    {
      boolean result = ctx.validateSession(cookieVal, encrypted_tranxid);
      if ( !result )
      {
	out.println("validateSession(" +cookieVal+ ", tranxid " +
		    encrypted_tranxid+ ") failed.");
	return;
      }
    }
  }
*/
//  try
//  {
    //
    // Call validateContext at the start of each page to make sure the
    // session is still valid.  If it is not, then return an error.
    //
    showCookies(request, out);
    out.println("<hr>");
//    showParameters(request, out);
//    out.println("<hr>");

    ctx = WebRequestUtil.validateContext(request, response);
//    ctx = WebRequestUtil.validateSecurity(request, response);

/*
    ctx = WebRequestUtil.createWebAppsContext(request, response);
    String status = WebRequestUtil.validateContext(request, response, ctx);
//    String status = WebRequestUtil.checkContext(request, response, ctx);
    System.out.println("validateContext status = " +status);
*/
//    if ( status == null || status.equals("INVALID") )
    if (ctx == null)
    {
      msg(out, WebRequestUtil.getErrors(ctx));
      msg(out,"Failed to authenticate session");
      return;
    }


    //
    // If validation succeeds, first set the client encoding in order
    // to ensure translateability.  After that, get the database
    // connection to use from the WebAppsContext.
    //
    WebRequestUtil.setClientEncoding(response, ctx);
    Connection conn = ctx.getJDBCConnection();
    PreparedStatement statement = null;
    ResultSet rs = null;

    if ( conn == null )
    {
      msg(out,"Failed to get JDBC connection");
      return;
    }

    //
    // Your application-specific code goes here.
    //
    try
    {
      //
      // A simple example - just select the user and responsibility
      // from dual.
      //
      String sql = "select fnd_global.user_name, fnd_global.resp_name " +
	           "from dual";
      statement = conn.prepareStatement(sql);
      rs = statement.executeQuery();

      if ( rs.next() )
      {
	ResourceStore resStore = ctx.getResourceStore();
	String userLabel = resStore.getResourceText("FND", "USER");
	String respLabel = resStore.getResourceText("FND", "RESPONSIBILITY");

	msg(out,"Successfully authenticated session!");
	msg(out, "<HR>");
	msg(out, userLabel+ " - " + rs.getString(1));
	msg(out, respLabel+ " - " + rs.getString(2));
      }

      out.println("<HR>");

      //
      // Use FunctionSecurity to generate RF link to test JSP
      //
      FunctionSecurity fs = new FunctionSecurity(ctx);

//      out.println(fs.getRunFunctionFormsLauncherSetup(false));
      out.println(fs.getRunFunctionFormsLauncherSetup());

      Resp appdevResp = fs.getResp("APPLICATION_DEVELOPER", "FND");
      Resp sysadminResp = fs.getResp("SYSTEM_ADMINISTRATOR", "SYSADMIN");
      Resp selfServSysadminResp = fs.getResp("SYSTEM_ADMINISTRATION", "ICX");
      Resp hrResp = fs.getResp("US_HRMS_MANAGER","PER");

//      SecurityGroup stdSecgrp = fs.getSecurityGroup("STANDARD");
      SecurityGroup stdSecgrp = fs.getSecurityGroup();

      //
      // simple JSP Ping links
      //
      Function pingFunc = fs.getFunction("FND_JSP_PING");
      String ping_url
	= fs.getRunFunctionURL(pingFunc,
			       selfServSysadminResp,
			       stdSecgrp,
			       null);
      String ping_link
	= fs.getRunFunctionLink(ping_url,
				null,
				pingFunc,
				selfServSysadminResp,
				stdSecgrp,
				null);
//      out.println(ping_link+ " - Ping JSP, sysadmin resp<BR>");
      printLink(out, ping_link, "Ping JSP, sysadmin resp");

      String ping_url_nrsp
	= fs.getRunFunctionURL(pingFunc,
			       null,
			       stdSecgrp,
			       null);
      String ping_link_nrsp
	= fs.getRunFunctionLink(ping_url_nrsp,
				null,
				pingFunc,
				null,
				stdSecgrp,
				null);
      printLink(out, ping_link_nrsp, "Ping JSP, no resp");
//      out.println(ping_link_nrsp+ " - Ping JSP, no resp<BR>");


      //
      // Variations of the menu and profile functions (often global)
      //
      out.println("<P><I>Variations of the menu and profile forms.  On some ");
      out.println("databases, FND_FNDMNMNU is a global function</I><P>");
      Function menuFunc = fs.getFunction("FND_FNDMNMNU");

      Resp spacesResp = fs.getResp("MRC RECEIVABLES MANAGER", "AR");

      String spaces_url
	= fs.getRunFunctionURL(menuFunc,
			       spacesResp,
			       stdSecgrp,
                               null);
//      out.println("<a href=\""+menu_url_nrsp+"\">" +menu_url_nrsp+ "</a> - " +
//		  "Menu form w/o resp URL<BR>");
      printLink(out, "<a href=\""+spaces_url+"\">" +spaces_url+ "</a>",
		"Menu form w/responsibility with spaces URL");


      String menu_url_qo
	= fs.getRunFunctionURL(menuFunc,
			       sysadminResp,
			       stdSecgrp,
			       "query_only=\"YES\"");
      String menu_link_qo
	= fs.getRunFunctionLink(menu_url_qo,
				null,
				menuFunc,
				sysadminResp,
				stdSecgrp,
				"query_only=\"YES\"");
      printLink(out, menu_link_qo, "menu form, query only=\"YES\"");
//      out.println(menu_link_qo+ " - menu form, query only=\"YES\"<BR>");


      String menu_url_nrsp
	= fs.getRunFunctionURL(menuFunc,
			       null,
			       stdSecgrp,
                               null);
//      out.println("<a href=\""+menu_url_nrsp+"\">" +menu_url_nrsp+ "</a> - " +
//		  "Menu form w/o resp URL<BR>");
      printLink(out, "<a href=\""+menu_url_nrsp+"\">" +menu_url_nrsp+ "</a>",
		"Menu form w/o resp URL");

      String menu_link_nrsp
	= fs.getRunFunctionLink("javascript:launchForm('" +menu_url_nrsp+"')",
				null,
				menuFunc,
				null,
				stdSecgrp,
				null);
      printLink(out, menu_link_nrsp, "menu form w/o resp link");
//      out.println(menu_link_nrsp+ " - Menu form w/o resp link<BR>");

      Function profFunc = fs.getFunction("FND_FNDPOMPV");
      String prof_url
	= fs.getRunFunctionURL(profFunc,
			       sysadminResp,
			       stdSecgrp,
			       null);
      String prof_link
	= fs.getRunFunctionLink(prof_url,
				null,
				profFunc,
				sysadminResp,
				stdSecgrp,
				null);
      printLink(out, prof_link, "profile form");

      String prof_url_nrsp
	= fs.getRunFunctionURL(profFunc,
			       null,
			       stdSecgrp,
			       null);
      String prof_link_nrsp
	= fs.getRunFunctionLink(prof_url_nrsp,
				null,
				profFunc,
				null,
				stdSecgrp,
				null);
      printLink(out, prof_link_nrsp, "profile form w/o resp link");

      String prof_url_error
	= fs.getRunFunctionURL(profFunc,
			       hrResp,
			       stdSecgrp,
			       null);
      String prof_link_error
	= fs.getRunFunctionLink(prof_url_error,
				null,
				profFunc,
				hrResp,
				stdSecgrp,
				null);
      printLink(out, prof_link_error, "profile form in wrong resp");
//      out.println(prof_link_error+ " - profile form in wrong resp<BR>");


      out.println("<P><I>Other FORM's link examples</I><P>");

      Function cpFunc = fs.getFunction("FND_FNDCPQCR_SYS");
      String cp_url
	= fs.getRunFunctionURL(cpFunc,
			       sysadminResp,
			       stdSecgrp,
			       null);
      String cp_link
	= fs.getRunFunctionLink(cp_url,
				null,
				cpFunc,
				sysadminResp,
				stdSecgrp,
				null);
      printLink(out, cp_link, "FNDCPQCR_SYS, seeded parameters mode=\"SYS\"");

//      out.println(cp_link+
//		  " - FNDCPQCR_SYS, seeded parameters mode=\"SYS\"<BR>");

      Function ffFunc = fs.getFunction("FND_FNDFFMSV");
      String ff_url_params
	= fs.getRunFunctionURL(ffFunc,
			       sysadminResp,
			       stdSecgrp,
			       "launch_mode=\"KEY\" query_only=\"YES\"");
      String ff_link_params
	= fs.getRunFunctionLink(ff_url_params,
				null,
				ffFunc,
				sysadminResp,
				stdSecgrp,
				"launch_mode=\"KEY\" query_only=\"YES\"");

      printLink(out, ff_link_params, "FND_FNDFFMSV launch_mode=\"KEY\" "+
		"query_only=\"YES\"");
//      out.println(ff_link_params + " - FND_FNDFFMSV " +
//		  "launch_mode=\"KEY\" query_only=\"YES\"");


      out.println("<P><I>HR responsibility</I><P>");

      Function cpdiaFunc = fs.getFunction("FNDCPDIA-85");

      String cpdia_url
	= fs.getRunFunctionURL(cpdiaFunc,
			       hrResp,
			       stdSecgrp,
			       null);
      String cpdia_link
	= fs.getRunFunctionLink(cpdia_url,
				null,
				cpdiaFunc,
				hrResp,
				stdSecgrp,
				null);

      printLink(out, cpdia_link, "FNDCPDIA-85, US_HRMS_MANAGER/PER resp - "+
		  " user func name has quotes");
//      out.println(cpdia_link + " - FNDCPDIA-85, US_HRMS_MANAGER/PER resp - "+
//		  " user func name has quotes<BR>");

      String cpdia_url_nrsp
	= fs.getRunFunctionURL(cpdiaFunc,
			       null,
			       stdSecgrp,
			       null);
     String cp_link_nrsp
	= fs.getRunFunctionLink(cpdia_url_nrsp,
				null,
				cpdiaFunc,
				null,
				stdSecgrp,
				null);

      printLink(out, cp_link_nrsp, "FNDCPDIA-85 in null resp");
//      out.println(cp_link_nrsp + " - FNDCPDIA-85 in null resp<BR>");

/*
      Function perFunc = fs.getFunction("PERWSHRG-403-EI");
      String per_link
	= fs.getRunFunctionLink("PERWSHRG-403-EI",
				null,
				perFunc,
				hrResp,
				stdSecgrp,
				null);
      out.println(per_link + "<BR>");

      String per_link2
	= fs.getRunFunctionLink("PERWSHRG-403-EI, null resp",
				null,
				perFunc,
				null,
				stdSecgrp,
				null);
      out.println(per_link2 + "<BR>");


      String per_url
	= fs.getRunFunctionURL(perFunc,
			       null,
			       stdSecgrp,
			       null);
      out.println("<a href=\""+per_url+"\">" +per_url+ "</a> - " +
		  "- PERWSHRG-403-EI, null resp<BR>");

      String err_url
	= fs.getRunFunctionURL(cpFunc2,
			       sysadminResp,
			       stdSecgrp,
			       null);
      out.println("<a href=\""+err_url+"\">" +err_url+ "</a> - " +
		  "FNDCPDIA in wrong resp<BR>");

*/
      out.println("<hr>");
      Function icxFunc = fs.getFunction("ICX_USER_PREFERENCES");
      Resp icxResp = fs.getResp("PREFERENCES", "ICX");
      String icx_link
	= fs.getRunFunctionLink("ICX user preferences",
				null,
				icxFunc,
				icxResp,
				stdSecgrp,
				null);
      out.println(icx_link+ "<BR>");

      Resp bisResp = fs.getResp("BIS_OPER-19121524","BIS");
      Function bisFunc = fs.getFunction("BIS_WIPBIUZ");

      String bis_link
	= fs.getRunFunctionLink("BIS link, accessible from MFG",
				null,
				bisFunc,
				bisResp,
				stdSecgrp,
				null);
      out.println(bis_link+ "<BR>");

      String err_link2
	= fs.getRunFunctionLink("FND_FNDMNMNU under BIS resp",
				null,
				menuFunc,
				bisResp,
				stdSecgrp,
				null);
      out.println(err_link2 + "<BR>");

%>
      <HR>
      Testing displayLogin with POST. <P>

<!--FORM ACTION="http://qapache.us.oracle.com:8584/OA_HTML/RF.jsp?dbc=ap112fam_atgcore&function_id=93&resp_id=20420&resp_appl_id=1&security_group_id=0" method=post target=formsLauncher>
      <!--FORM ACTION="jsp/fnd/fndexample.jsp" method=post>
      <FORM method=post>

      Text <INPUT TYPE=text name=text value="hello world"> <BR>
      expired <SELECT name=expired>
      <OPTION> yes
      <OPTION selected > no
      </SELECT> <BR>

      debug <SELECT name=debug>
      <OPTION> yes
      <OPTION selected> no
      </SELECT> <BR>
      <INPUT TYPE="submit" VALUE="Send">

      </FORM>
      <HR>

<%


    }
    catch ( SQLException sqle )
    {
      msgException(out, sqle);
    }
    finally
    {
      try { if ( statement != null ) statement.close(); }
      catch (SQLException e) {}
    }
  }

  catch ( Exception e )
  {
    //
    // Print out any unhandled exceptions here.
    //
    msgException(out, e);
  }
  finally
  {
    //
    // Make sure to always free the WebAppsContext in the finally
    // block at the end of the page.
    //
    if ( ctx != null ) ctx.freeWebAppsContext();
  }

%>

<%!

  /*
   * Show all the cookies
   */
  void showCookies ( HttpServletRequest req, JspWriter out )
     throws IOException
  {
    Cookie[] cookies = req.getCookies();

    if (cookies.length <= 0)
    {
      out.println("No cookie found in current browser.<Br>");
    }

    for ( int i=0; i<cookies.length; i++ )
    {
      Cookie cookie = cookies[i];

      out.println("Cookie: " + cookie.getName() + " = " +
		   cookie.getValue() + "; domain " +
		   cookie.getDomain() + "; path " +
		   cookie.getPath() + "; age " +
		   cookie.getMaxAge() + "<BR>");
    }
  }

  void showParameters ( HttpServletRequest req, JspWriter out )
     throws IOException
  {
    java.util.Enumeration params = req.getHeaderNames();
    while ( params.hasMoreElements() )
    {
      String headerName = (String) params.nextElement();
      String headerValue = req.getHeader(headerName);
      out.println("Header: " +headerName+ " = " +headerValue+ "<BR>");
    }
  }

  /*
   * Helper function to print out messages.
   */
  void msg ( JspWriter o, String message ) throws IOException
  {
    o.println(message + "<BR>");
  }

  /*
   * Helper function to print out exceptions.
   */
  void msgException ( JspWriter o, Exception e ) throws IOException
  {
    o.println("<PRE>");
    e.printStackTrace(new PrintWriter(o));
    o.println("</PRE>");
  }

  void printLink ( JspWriter out, String link, String msg )
     throws IOException
  {
/*
    if ( 1 == 1 )
    {
      out.println(link+ " - " + msg + "<BR>");
      return;
    }
*/
    // can replace port here if necessary
    int index1 = link.indexOf("8502");
    int index2 = link.indexOf("8503");
//    index2 = -1;
    String updatedLink = link;
//    System.out.println("index1 = "+index1+", index2 = " +index2);
    if ( index1 != -1 )
    {
      updatedLink = link.substring(0, index1) + "8584" +
                    link.substring(index1+4);
    }
    else if ( index2 != -1 )
    {
      updatedLink = link.substring(0, index2) + "8585" +
                    link.substring(index2+4);
    }

    // repeat!
    index1 = updatedLink.indexOf("8502");
    index2 = updatedLink.indexOf("8503");
    index2 = -1;

    if ( index1 != -1 )
    {
      updatedLink = updatedLink.substring(0, index1) + "8584" +
                    updatedLink.substring(index1+4);
    }
    else if ( index2 != -1 )
    {
      updatedLink = updatedLink.substring(0, index2) + "8585" +
                    updatedLink.substring(index2+4);
    }
//    System.out.println("updatedLink is " +updatedLink);
    out.println(updatedLink+ " - " + msg + "<BR>");
  }

%>
</BODY></HTML>
