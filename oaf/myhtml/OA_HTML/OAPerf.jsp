<%@ page
  language    = "java"
  contentType = "text/html"
  errorPage   = "OAErrorPage.jsp"
  import      = "oracle.apps.fnd.framework.webui.OAJSPHelper"
%>

<%
  // Session values in this jsp need not be passivated, and hence values can
  // be put directly into session.
  String isRedirect = (String)session.getValue("redirect") == null ? "no" : (String)session.getValue("redirect");
  session.putValue("redirect", isRedirect);
  if (isRedirect.equals("no"))
  {
    System.gc();
    session.putValue("start",     new Long(System.currentTimeMillis()));
    session.putValue("totalmem1", new Long(Runtime.getRuntime().totalMemory()));
    session.putValue("freemem1",  new Long(Runtime.getRuntime().freeMemory()));
  }
%>

<%! public static final String RCS_ID = "$Header: OAPerf.jsp 115.7 2003/12/07 04:02:19 nigoel noship $"; %>

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
      redirectURL  = pageBean.preparePage(pageContext);

      if(redirectURL != null)
      {
        session.putValue("redirect", "yes");
%>
        <jsp:forward page="<%= redirectURL %>"/>
<%
      }
      else
      {
        session.putValue("redirect", "no");
      }
      pageBean.renderDocument();
%>

<html>
<%
      long end = System.currentTimeMillis();
      long start_long = ((Long)session.getValue("start")).longValue();
      out.println("<BR><BR>Time Elapsed = " + (end - start_long));
      out.println("<BR>");

      long totalMem1 = ((Long)session.getValue("totalmem1")).longValue();
      long freeMem1  = ((Long)session.getValue("freemem1")).longValue();
      long totalMem2 = Runtime.getRuntime().totalMemory();
      long freeMem2  = Runtime.getRuntime().freeMemory();

      out.println("<BR>Total Mem1 = " + totalMem1);
      out.println("<BR>Total Mem2 = " + totalMem2);
      out.println("<BR>Total MemDiff = " + (totalMem1 - totalMem2));
      out.println("<BR><BR>Free Mem1 = " + freeMem1);
      out.println("<BR>Free Mem2 = " + freeMem2);
      out.println("<BR>Free MemDiff = " + (freeMem2 - freeMem1));

      out.println("<BR>");
      out.println("<BR>");
%>

</html>

<%
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
