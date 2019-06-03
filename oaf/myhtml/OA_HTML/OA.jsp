<%@ page
  language    = "java"
  contentType = "text/html"
  errorPage   = "OAErrorPage.jsp"
  import      = "oracle.apps.fnd.framework.webui.OAJSPHelper"
  import      = "oracle.apps.fnd.framework.webui.OAPageBean"
  import      = "oracle.apps.fnd.framework.webui.OAGenericDispatcher"  
  import      = "oracle.cabo.ui.jsps.GenericEntry"
%>

<%! public static final String RCS_ID = "$Header: OA.jsp 115.56 2004/07/16 04:02:21 atgops1 noship $"; %>

<jsp:useBean
  id          = "pageBean"
  class       = "oracle.apps.fnd.framework.webui.OAPageBean"
  scope       = "request">
</jsp:useBean>

<%
  if (!((GenericEntry.getGenericDispatcher(pageContext)) instanceof OAGenericDispatcher))
    GenericEntry.setGenericDispatcher (pageContext, new OAGenericDispatcher());    

  OAJSPHelper.setRequestCharacterEncoding(pageContext);

  // Bug 2577443 - clear cache only after a hot-redeploy
  OAPageBean.clearWebBeanCache(session, request);

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
  } // end - synchronized (sessionLock)
%>
