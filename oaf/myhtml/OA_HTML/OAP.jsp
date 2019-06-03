<%@ page
  language    = "java"
  contentType = "text/html"
  errorPage   = "OAErrorPage.jsp"
  import      = "oracle.apps.fnd.framework.webui.OAJSPHelper"
%>

<%! public static final String RCS_ID = "$Header: OAP.jsp 115.14 2004/10/18 03:47:33 atgops1 noship $"; %>

<jsp:useBean
  id          = "pageBean"
  class       = "oracle.apps.fnd.framework.webui.OAPageBean"
  scope       = "request">
</jsp:useBean>

<%
  // Bug 3184117: Non-ASCII parameters are turned into garbage even if it 
  // encoded correctly.
  OAJSPHelper.setRequestCharacterEncoding(pageContext);

  String redirectURL = null;
  try
  {
    redirectURL = pageBean.preparePage(pageContext, true);

    if (redirectURL != null)
    {
%>
      <jsp:forward page="<%= redirectURL %>" />
<%
    }
    pageBean.renderDocument();
  }
  catch (Exception e) 
  {
    pageBean.registerSevereException(e); 
  }
  finally
  {
    pageBean.finalizeRequest(request, redirectURL);
  }
%>
