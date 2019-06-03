<%@ page
  language    = "java"
  contentType = "text/html"
  errorPage   = "OAErrorPage.jsp"
  import      = "oracle.apps.fnd.framework.webui.OAJSPHelper"
%>

<%! public static final String RCS_ID = "$Header: OARegion.jsp 115.3 2003/12/07 04:01:24 nigoel noship $"; %>

<jsp:useBean
  id          = "pageBean"
  class       = "oracle.apps.fnd.framework.webui.OAPageBean"
  scope       = "request">
</jsp:useBean>

<%

  // Bug 3184117: Non-ASCII parameters are turned into garbage even if it 
  // encoded correctly.
  OAJSPHelper.setRequestCharacterEncoding(pageContext);

  // Synchronize threads within one session -- fix for bug 1911272
  Object sessionLock = null;
  synchronized (session)
  {
    sessionLock = pageBean.getSessionLock(session);
  }
  
  synchronized (sessionLock)
  {
    String redirectURL = null;
    try
    {
      redirectURL = pageBean.preparePage(pageContext);

      if (redirectURL != null)
      {
%>
        <jsp:forward page="<%= redirectURL %>" />
<%
      }
      pageBean.renderBody();
    }
    catch (Exception e) 
    { 
      pageBean.registerSevereException(e); 
    }
    finally
    {
      pageBean.finalizeRequest(request, redirectURL);
    }
  } // end - synchronized (sessionLock)
%>
