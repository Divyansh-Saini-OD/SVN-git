<%@ include file="ODasljtfsctp.jsp"  %>
<%  //$Header: ODasljtfincl.jsp 115.28 2005/08/31 07:21:35 applrt ship $ %>
<%@  page language="java" import="java.lang.*"%>
<%@  page language="java" import="java.util.*" %>
<%@  page language="java" import="oracle.jdbc.driver.*" %>
<%@  page language="java" import="oracle.apps.jtf.aom.*" %>
<%@  page language="java" import="oracle.apps.jtf.servicemanager.*" %>
<%@  page language="java" import="oracle.apps.jtf.base.resources.*" %>
<%@  page language="java" import="oracle.apps.jtf.base.syslog.*" %>
<%@  page language="java" import="oracle.apps.jtf.base.session.*" %>
<%@  page language="java" import="oracle.apps.jtf.profile.*" %>
<%@  page language="java" import="oracle.apps.fnd.common.*" %>
<%@  page language="java" import="oracle.apps.jtf.aom.transaction.*" %>
<%@  page language="java" import="oracle.apps.jtf.coreservices.interfaces.*" %>
<%@  page language="java" import="oracle.apps.jtf.base.SystemLogger" %>
<%@  page language="java" import="oracle.apps.jtf.region.*" %>
<%@  page language="java" import="java.sql.*" %>
<%@  page language="java" import="oracle.apps.jtf.admin.adminconsole.*" %>
<%@  page language="java" import="oracle.apps.jtf.base.propmanager.*" %>

<%@ page language="java" errorPage="jtfacerr.jsp" %>

<%@  page language="java" import="oracle.apps.jtf.activity.PageObject" %>
<%@  page language="java" import="oracle.apps.jtf.activity.EventDispatcher" %>
<%@  page language="java" import="oracle.apps.jtf.activity.PageLogManager" %>
<%@  page language="java" import="oracle.apps.jtf.base.Logger" %>
<%@  page language="java" import="oracle.apps.fnd.common.Message" %> 
<%
  PageObject pageObject = null;
  try
  {
    pageObject = PageObject.startNewIfStarted();
    if (pageObject != null)
    {
      pageObject.setContext(request, response);
%>

<jsp:useBean id = "pageDispatcher" class = "oracle.apps.jtf.activity.EventDispatcher" scope = "page" >
    <jsp:setProperty name = "pageDispatcher" property = "pageObject" value = "<%= pageObject %>" />
</jsp:useBean>

<jsp:useBean id = "requestDispatcher" class = "oracle.apps.jtf.activity.EventDispatcher" scope = "request" >
</jsp:useBean>

<%
    }
  }
  catch (Exception e)
  {
    Logger.out(e, this);
  }
%>

<%
	FWSession _fwSession = null;

	MenuRenderer.JtfJspContext _jtfPageContext = new MenuRenderer.JtfJspContext(request, response);
	// deprecated
	int     appID;
	int     respID;
	String  langCode;
   
        oracle.apps.jtf.util.Utils.setCurrJspPageContext(pageContext);

	////StickySession Begin
	if(ServletSessionManager.stickyFlag) {
		request.getSession(true);
	}
	////StickySession End	

	String jtt_browserCache = "NO";
	try{
		jtt_browserCache = oracle.apps.jtf.base.propmanager.PropMgrDB.getDefaultValue("browser_cache");
	}catch(Exception e){}

	// Anything other than YES for the property turns the cache off.
	if(!(jtt_browserCache != null && jtt_browserCache.equalsIgnoreCase("YES"))){
		response.setHeader("Cache-Control","no-cache"); //HTTP 1.1
		response.setHeader("Pragma","no-cache"); //HTTP 1.0
		response.setDateHeader ("Expires", 0); //prevents caching at the proxy server
		response.setHeader("Cache-Control","no-store"); 
	}		
%>
<jsp:useBean  id  = "_jtfOAPageBean2"
              class  = "oracle.apps.fnd.framework.webui.OAPageBean"
              scope   = "request">
</jsp:useBean>
