
<%! public static final String RCS_ID = "$Header: OAEmbeddedRegion.jsp 115.45 2004/07/22 03:45:24 atgops1 noship $"; %>

<%@ page
  import      = "oracle.apps.fnd.framework.webui.OAGenericDispatcher"  
  import      = "oracle.cabo.ui.jsps.GenericEntry"
%>

<jsp:useBean
  id          = "pageBean"
  class       = "oracle.apps.fnd.framework.webui.OAPageBean"
  scope       = "request">
</jsp:useBean>

<%

  if (!((GenericEntry.getGenericDispatcher(pageContext)) instanceof OAGenericDispatcher))
    GenericEntry.setGenericDispatcher (pageContext, new OAGenericDispatcher()); 
    
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
