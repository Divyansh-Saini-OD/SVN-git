<%--=========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |       27-Oct-00  aviswana  Created.                                       |
 |       11-Nov-02  akviswan  Fix for bug 2084707 (provided by 'skaneko')    |
 |       27-Oct-00  kkho  	  Added for SSO                                  |
 |       06-May-03  mmnakamu  Fix for bug 2825869                            |
 |                                                                           |
 | NOTE: For internal OA Framework team development use only.                |
 |       No other use is supported.                                          |
 +=========================================================================--%>

<%@ page
  language    = "java"
  contentType = "text/html"
  import      = "oracle.apps.fnd.sso.SSOManager"
%>

<%! public static final String RCS_ID = "$Header: OALogin.jsp 115.19 2004/08/02 05:15:47 atgops1 noship $"; %>
<%
  String pageEncoding = request.getParameter("IANA_ENCODING");
  if ((pageEncoding==null) || ("".equals(pageEncoding)))   pageEncoding = "iso-8859-1";
  response.setContentType("text/html;charset=" + pageEncoding);

  String redirectURL  = decodeString(request.getParameter("goToURL"), pageEncoding);
  String errorMessage = decodeString(request.getParameter("msg"),     pageEncoding);
  String redirectPHP  = request.getParameter("goToPHP");
  String cancelURL    = SSOManager.getLoginUrl();

  String loginUrl = ((redirectPHP == null || "".equals(redirectPHP.trim())) ? SSOManager.getLoginUrlWithErrText(redirectURL, cancelURL, null, errorMessage) : 
     // Once the SSO bug 3174633 is fixed, replace "APPSHOMEPAGE" with a null value.
     // Instead of hardcoding the login URL, we should have SSO resolve the login URL
     // for us from the profile options.  If we pass in "APPSHOMEPAGE", SSO resolves
     // the login URL for us.
     SSOManager.getLoginUrlWithErrText("APPSHOMEPAGE", cancelURL, null, errorMessage));
     //SSOManager.getLoginUrlWithErrText(request.getScheme() + "://" + request.getHeader("Host") + "/OA_HTML/OA.jsp?OAFunc=OAHOMEPAGE", cancelURL, null, errorMessage));

  response.sendRedirect(loginUrl);
%>
<%!
  private String decodeString(String inData, String encoding)
  {
    String returnStr = inData;

    if ((inData != null) && (!("".equals(inData))))
    {
      try
      {
        returnStr = new String(inData.getBytes("8859_1"), encoding);
      }
      catch(Exception e)
      {
        returnStr = inData;
      }
    }
    return returnStr;
  }
%>
