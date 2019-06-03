<%@ page
  language    = "java"
  isErrorPage = "true"
  import      = "java.util.*, oracle.jbo.*, javax.naming.*, oracle.jdeveloper.html.*, oracle.jbo.html.databeans.*, oracle.apps.fnd.framework.*, oracle.apps.fnd.framework.webui.*"
  contentType = "text/html"
%>
<%! public static final String RCS_ID = "$Header: OAErrorPage.jsp 115.80 2005/03/15 04:45:44 atgops1 noship $"; %>

<div CLASS="errorText">
<%
  OAAboutUtils.setPageInError(session);
  String logoutUrl = OAJSPHelper.getLogoutUrl(request);
   
  // if _render_mode = 1, it means the request is for rendering a portlet.
  // (portlet render mode =  MODE_SHOW).
  boolean portletMode = ("1".equals(request.getParameter("_render_mode"))) ||
                        ("1".equals(request.getParameter("_mode")));

  if( portletMode )
  {
    OAJSPHelper.incrementPortletCachingKey(request, session);
  }
  
  OAException e = null;
  try
  {
    if (exception == null)
    {
      e = OAException.wrapperException((Throwable)OAPageBean.getPPRException(session));
      if (e != null) 
        OAPageBean.removePPRException(session);
    }
    else
    {
      e = OAException.wrapperException((Throwable)exception);
    }
    OAApplicationModuleCache amCache = OAPageBean.getApplicationModuleCache(session);
    Hashtable amEntries = null;
    if (amCache != null)
      amEntries = amCache.getApplicationModuleEntries(session, request, response);  
    if (amEntries != null)
    {
      Enumeration amList       = amEntries.elements();
      OAApplicationModule am  = null;
      while (amList.hasMoreElements())
      {
        OASessionCookie sessionCookie = (OASessionCookie)amList.nextElement();
        if (sessionCookie != null)
          am = (OAApplicationModule)sessionCookie.useApplicationModule(false);
        if (am != null)
        {
          e.setApplicationModule(am);
          break;
        }
      }
    }
  }
  catch (Exception ex)
  {
    // If an exception is thrown here, just swallow it.  We don't want the 
    // original exception to get lost because of this side effect exception.
  }

  if (e != null)
    session.putValue("OASevereException", e);

  OAException ex   = (OAException)session.getValue("OASevereException");
  String displayErrorStack = (String)session.getValue("_displayErrorStack");
  if (displayErrorStack == null)
  {
   OAJSPHelper.handleErrorStackDisplay(null,null,request,session,ex);   
   displayErrorStack = (String)session.getValue("_displayErrorStack");  
  }    
%>

<html lang="en-US">
<head>
<script>
function ignoreWarnAboutChanges(url)
{
  document.location.href = url;
}
</script>  
  <title>Error Page</title>
  <link rel="stylesheet" charset="UTF-8" type="text/css" href="/OA_HTML/cabo/styles/blaf.css">
  <META name="fwk-error" content="Error occured while processing the request">

<%
   if ("Y".equals(displayErrorStack))
   {
%>
  <META name="fwk-error-detail" content="<%= (e != null) ? e.getMessageStackTraces() : "" %>">
<%
   }   
%>

</head>
<body>

<% String severeErrorDuringRender = (String)session.getValue("severeErrorDuringRender");
   session.removeValue("severeErrorDuringRender");
   if (!"Y".equals(severeErrorDuringRender))
   {
%>  

<table width="100%" border="0" cellspacing="0"  cellpadding="0">
  <tr> <td><img src="/OA_MEDIA/FNDSSCORP.gif" alt=""> </td></tr>
  <tr> <td>&nbsp;</td> 
      <% if  (logoutUrl != null)
      {
      %>
       <td> <a href= <%=logoutUrl%>>Logout </a></td>  
      <% } %>
  </tr>
  <tr> <td width="100%" nowrap class="OraBGColorDark" >&nbsp; </td> </tr>
</table>
<p>
<%      
   }
%>



<center>
      <table width="95%" border="0" cellspacing="0" class="OraBGAccentDark" cellpadding="0">
<%  
   if (!"Y".equals(severeErrorDuringRender))
   {
%> 
      <tr> <td> &nbsp; </td> </tr>
      <!-- <tr> <td class="OraErrorHeader"> <img src=/OA_HTML/cabo/images/errorl.gif>  Error Page </td> </tr> -->
      <tr> <td class="OraErrorHeader"> <center> Error Page </center> </td> </tr>
      <tr> <td colspan=2 class="OraBGColorDark"> </td> </tr>
      <tr> <td> &nbsp; </td> </tr>   
      <tr> <td colspan=2 class="OraErrorText" >You have encountered an unexpected error.  Please
      contact the System Administrator for assistance. </td> </tr>      
<%
   }
   else
   {
%>
      <tr> <td class="OraErrorHeader"> Error </td> </tr>      
      <tr> <td colspan=2 class="OraErrorText"> &nbsp; </td> </tr>
      <tr> <td colspan=2 class="OraErrorText"> You have encountered an unexpected error. Please contact the System Administrator for assistance. </td> </tr> 
<%  
   }
   if ("Y".equals(displayErrorStack))
   {
     //fix for bug 4115406 -- mbuk
     if (MobileUtils.getMobileUtils().isAgentPDA(pageContext))
     {
%>
      <tr> <td colspan=2 class="OraErrorText"> Click <a href="/OA_HTML/OAErrorDetailPage.jsp"> here </a> for exception details. 
      </td>  </tr>
<%
     }
     else 
     {
%>   
      <tr> <td colspan=2 class="OraErrorText"> Click <a href=javascript:ignoreWarnAboutChanges("/OA_HTML/OAErrorDetailPage.jsp")> here </a> for exception details. 
      </td>  </tr>
<%
      }
      if(OAAboutUtils.isAboutDataCollected(session)) 
      {
%>
      <tr> <td colspan=2 class="OraErrorText"> &nbsp; </td> </tr>
      <tr> <td colspan=2><div class="xv"><a href="/OA_HTML/OA.jsp?page=/oracle/apps/fnd/framework/about/webui/OAAboutPG&OAMC=N">About previous Page</a></div>
      </td>  </tr>
<%
      }   
   }
%>   
</table>
</center>

    

</div>
</body>
</html>
