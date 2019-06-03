<!-- $Header: AppsLocalLogout.jsp 115.9 2004/12/02 22:49:06 scheruku noship $ -->
<%@  page language="java" import="oracle.security.sso.enabler.*" %>
<%@  page import="oracle.apps.fnd.sso.*" %>
<%@  page import="java.math.*" %>
<%@  page import="java.net.*" %>
<%@  page import="java.util.Hashtable"%>
<%@ page session="false" %>
<%
        response.setHeader("Cache-Control", "no-cache");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);
%>
<%
  Utils.setRequestCharacterEncoding(request);
	String returnUrl=  request.getParameter("returnUrl");

	Utils.getAppsContext();
	Hashtable tmp = SessionMgr.getICXSessionInfo(SessionMgr.getAppsCookie(request));
	String homeUrl = null;
	if(tmp != null)
		homeUrl = (String)tmp.get("HOME_URL");

	if(returnUrl == null && tmp == null){
                returnUrl = SSOUtil.getLocalLoginUrl();
	}else if(returnUrl == null){
		if(homeUrl != null && !homeUrl.equals("NULL")){
			returnUrl = homeUrl;
		}else{
                	returnUrl = SSOUtil.getLocalLoginUrl();
		}
	}

	if(tmp != null && (homeUrl == null || homeUrl.equals("NULL"))){
		if(returnUrl.indexOf("?") != -1){
			String langCode = (String)tmp.get("LANGUAGE_CODE");
			if(langCode != null){
				returnUrl += "&langCode="+langCode;
			}
			String username = (String)tmp.get("USER_NAME");
			if(username != null){
				returnUrl += "&username="+oracle.apps.fnd.util.URLEncoder.encode(username, SessionMgr.getCharSet());
			}
		}else{
			String langCode = (String)tmp.get("LANGUAGE_CODE");
			boolean qmark = false;
			if(langCode != null){
				returnUrl += "?langCode="+langCode;
				qmark = true;
			}
			String username = (String)tmp.get("USER_NAME");
			if(username != null){
				if(qmark == true)
					returnUrl += "&username="+oracle.apps.fnd.util.URLEncoder.encode(username, SessionMgr.getCharSet());
				else
					returnUrl += "?username="+oracle.apps.fnd.util.URLEncoder.encode(username, SessionMgr.getCharSet());
		
			}
		}
	}

	SessionMgr.logoutUser(request, response);
	HttpSession ses = request.getSession(false);
	if(ses != null)
		ses.invalidate();
	Utils.releaseAppsContext();
	response.sendRedirect(returnUrl);

%>
