<!--
 Generic error page.  Takes parameters via the URL to display in the
 page ('text' for untranslated text, and 'msg_app/msg_name' for text
 that should be translated).
-->

<%@ page language="java" %>
<%@ page import="oracle.apps.fnd.common.WebAppsContext" %>
<%@ page import="oracle.apps.fnd.common.WebRequestUtil" %>
<%@ page import="oracle.apps.fnd.common.ResourceStore" %>
<%@ page import="oracle.apps.fnd.common.Message" %>
<%@ page import="oracle.apps.fnd.common.VersionInfo" %>

<%!
  public static final String RCS_ID =
    "$Header: fnderror.jsp 115.0 2002/05/24 16:47:42 pkm ship   $";
  public static final boolean RCS_ID_RECORDED =
    VersionInfo.recordClassVersion(RCS_ID,"oa_html.jsp.fnd");
%>

<HTML>
<head>
<TITLE>Error Page</TITLE>
</head>
<BODY>

<%
  WebAppsContext ctx = null;
  response.setContentType("text/html");

  String text = request.getParameter("text");
  String messageApp = request.getParameter("msg_app");
  String messageName = request.getParameter("msg_name");

  try
  {
    //
    // Try to create a WebAppsContext to perform message lookups
    // and set the client encoding.  Depending on why we're arriving
    // at this page in the first place this may not be possible, if
    // this fails for any reason we'll just print out an untranslated
    // message.
    //
    ctx = WebRequestUtil.createWebAppsContext(request, response);

    //
    // If a 'text' argument is passed in, just print that directly.
    //
    if ( text != null )
    {
      out.println(text);
    }

    //
    // Otherwise try to look up the 'msg_app' and 'msg_name' arguments.
    //
    else
    {
      if ( messageApp == null || messageName == null )
      {
	messageApp = "FND";
	messageName = "FND_ERROR_JSP";
      }

      ResourceStore res = ctx.getResourceStore();
      Message msg = new Message(messageApp, messageName);

      boolean translated = false;
      String tokenName, tokenValue, tokenTrans;

      //
      // Include support for message tokens, though for the
      // most part we expect to only display very simple error
      // messages - the URL can get cluttered up quickly if this
      // is abused.
      //
      // Format of message token passing is to pass the triple
      //
      //   token_name#=..&token_value#=..&token_trans#=..
      //
      // where the # should match (of course) for corresponding
      // values, and must start with 1 and increase sequentially
      // if there are multiple tokens.
      //
      // the value of 'token_trans' is expected to be "TRUE"
      // (case insensitive) if the token should be translated, it
      // defaults to FALSE otherwise.
      //
      for ( int i=1; ; i++ )
      {
	tokenName = request.getParameter("token_name" +i);
	tokenValue = request.getParameter("token_value" +i);
	tokenTrans = request.getParameter("token_trans" +i);
	if ( "TRUE".equalsIgnoreCase(tokenTrans) ) translated = true;
	else translated = false;

	if ( tokenName != null && tokenValue != null )
        {
	  msg.setToken(tokenName, tokenValue, translated);
	}
	else
	{
	  break;
	}
      }

      String messageText = msg.getMessageText(res);
      out.println(messageText + "<BR>");
    }
  }
  finally
  {
    if ( ctx != null ) ctx.freeWebAppsContext();
  }

%>
</BODY></HTML>
