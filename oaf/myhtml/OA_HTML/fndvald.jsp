<!-- $Header: fndvald.jsp 115.26 2004/12/02 22:47:45 scheruku noship $ -->

<%@ page language="java" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="oracle.apps.fnd.common.WebAppsContext" %>
<%@ page import="oracle.apps.fnd.common.Message" %>
<%@ page import="oracle.apps.fnd.common.AppsLog" %>
<%@ page import="oracle.apps.fnd.common.Log" %>
<%@ page import="oracle.apps.fnd.sso.AuthenticationException" %>
<%@ page import="oracle.apps.fnd.sso.SessionMgr" %>
<%@ page import="oracle.apps.fnd.sso.SSOUtil" %>
<%@ page import="oracle.apps.fnd.sso.Utils" %>
<%@ page import="oracle.apps.fnd.sso.AppsAgent" %>
<%@ page import="oracle.apps.fnd.security.CSS" %>
<%@ page import="oracle.apps.fnd.security.HTMLProcessor" %>
<%@ page import='oracle.apps.fnd.common.Message'%>
<%@ page import='oracle.apps.fnd.common.ResourceStore'%>

<%
boolean alreadySet = false;
  WebAppsContext wctx = null;
  if(Utils.isAppsContextAvailable()){
       wctx = Utils.getAppsContext();      
       alreadySet = true;
  }
  else{
       wctx = Utils.getAppsContext();
  }
   Utils.setRequestCharacterEncoding(request);
   int requestUrlResult = -1;
   int cancelUrlResult = -1;
   int usernameResult = -1;
   int passwordResult = -1;
   int home_urlResult = -1;
   int langCodeResult = -1;
   boolean cssFailure = false;
   
  String requestUrl = request.getParameter("requestUrl");
  if (requestUrl == null) {
    requestUrl =  "APPSHOMEPAGE";
  }

  String cancelUrl = request.getParameter("cancelUrl");
  if (cancelUrl == null) {
     String tmp = AppsAgent.getServer();
     cancelUrl = tmp.substring(0, tmp.length() -1) + SSOUtil.getLocalLoginUrl(); 
  }
  String username = request.getParameter("username").trim();
  String password = request.getParameter("password");
  Connection conn = null;
  String home_url = request.getParameter("home_url");
  String langCode = request.getParameter("langCode");

  if(langCode != null) wctx.setCurrLang(langCode);
//  Checking XSS problem for 
//        1. requestUrl
//        2. cancelUrl
//        3. username
//        4. password
//        5. home_url
//        6. langCode
  StringBuffer problemBuff = new StringBuffer();
  HTMLProcessor p = new HTMLProcessor(HTMLProcessor.INSPECT);
   if(requestUrl!= null && !requestUrl.equals("")) {
      requestUrlResult = p.processInput(requestUrl);
      if(requestUrlResult > -1) {
                cssFailure = true;
                problemBuff.append(requestUrl+"\t");
      }
   }
   if(cancelUrl!= null && !cancelUrl.equals(""))   {
      cancelUrlResult = p.processInput(cancelUrl);
      if(cancelUrlResult > -1) {
                cssFailure = true;
                problemBuff.append(cancelUrl+"\t");
      }
   }
   if(username!= null && !username.equals(""))     {
      usernameResult = p.processInput(username);
      if(usernameResult > -1) {
                cssFailure = true;
                problemBuff.append(username+"\t");
      }
   }
   if(password!= null && !password.equals(""))     {
      passwordResult = p.processInput(password);
      if(passwordResult > -1) {
                cssFailure = true;
                problemBuff.append(password+"\t");
      }    
   }
   if(home_url!= null && !home_url.equals(""))     {
      home_urlResult = p.processInput(home_url);
      if(home_urlResult > -1) {
                cssFailure = true;
                problemBuff.append(home_url+"\t");
      }
   }
   if(langCode!= null && !langCode.equals(""))     {
      langCodeResult = p.processInput(langCode);
      if(langCodeResult > -1)  {
                cssFailure = true;
                problemBuff.append(langCode+"\t");
      }
   }

  try {
    if(cssFailure){
     if (((AppsLog) wctx.getLog()).isEnabled(Log.UNEXPECTED)) {
               ((AppsLog) wctx.getLog()).write(
                  "html/fndvald.jsp",
                  "Url Parameter validation Failed! for "+problemBuff.toString(), Log.UNEXPECTED);
         }
//      char[] chars = (problemBuff.toString()).toCharArray();
//      char[] displaychars = new char[2*chars.length];
//       for (int j=0; j<chars.length; j++)
//       {
//          displaychars[2*j] = chars[j];
//          displaychars[2*j+1] = ' ';
//       }
//      String problemStr = new String(displaychars);
//      Message msg = new Message("FND","FND_PARAMVAL_SCAN_FAILED");
//      msg.setToken("VAL",problemStr,true);
      //ErrorStack es = wctx.getErrorStack();
      //es.addMessage(msg);
//      ResourceStore rStore = wctx.getResourceStore();
  //    String errText = msg.getMessageText(rStore);
            
      String linkXSS = Utils.getFwkServerWithoutTS(wctx) 
                + SSOUtil.getLocalLoginUrl() 
                + "?requestUrl=" + oracle.apps.fnd.util.URLEncoder.encode(
                      requestUrl, SessionMgr.getCharSet())
                + "&cancelUrl=" + oracle.apps.fnd.util.URLEncoder.encode(
                    cancelUrl, SessionMgr.getCharSet())
                    +"&errCode=FND_SSO_PARAMVAL_SCAN_FAILED";
                   //  +"&errText="+errText;
        if (langCode != null) {
             linkXSS += "&langCode=" + langCode;
        }
       if (request.getParameter("home_url") != null) {
             linkXSS += "&home_url=" + oracle.apps.fnd.util.URLEncoder.encode(
                home_url, SessionMgr.getCharSet());
       }
      response.sendRedirect(linkXSS);
    }
    conn = Utils.getConnection();
    SessionMgr.createAppsSession(username, password, request, response);
    conn.commit();

   // SessionMgr.setUserLanguage(request, wctx);
    //conn.commit();

    if (requestUrl.equals("APPSHOMEPAGE")) {
      requestUrl = SSOUtil.getHomePage(wctx, conn, request, response);
    
      if (home_url != null) {

        if (requestUrl.indexOf("OracleMyPage.home") != -1) {

          if(requestUrl.indexOf("?") != -1) {
            requestUrl += "&home_url=" 
              + oracle.apps.fnd.util.URLEncoder.encode(
                home_url, SessionMgr.getCharSet());
          } else {
            requestUrl += "?home_url=" 
              + oracle.apps.fnd.util.URLEncoder.encode(
                home_url, SessionMgr.getCharSet());
          }
        }
      }
    }

    // check if password needs to be changed.
    boolean pwdCheck = wctx.getSessionManager().passwordExpired();

    if (pwdCheck == true) {
      String tmp = requestUrl;
      requestUrl = SSOUtil.getLocalPwdChangeUrl();
      requestUrl += "?returnUrl=" 
        + oracle.apps.fnd.util.URLEncoder.encode(
          tmp, SessionMgr.getCharSet())+ "&cancelUrl="
        + oracle.apps.fnd.util.URLEncoder.encode(
          Utils.getFwkServerWithoutTS(wctx)
            + SSOUtil.getLocalLoginUrl(), SessionMgr.getCharSet());
    }

  } catch(AuthenticationException e) {
    conn.rollback();
  
    /*
      Bug 3577716, check to see if failure attempts exceeded the 
      SIGNON_PASSWORD_FAILURE_LIMIT profile option value. If yes,
      redirect to another page showing the error "account expired".
    */

        Message msg = wctx.getErrorStack().nextMessageObject();
        String msgName = null;
        String msgText = "";
        String errString = "&errCode=";
        if(msg != null){
             msgName = msg.getName();
             msgText = msg.getMessageText(wctx.getResourceStore());
             errString += oracle.apps.fnd.util.URLEncoder.encode(msgName, SessionMgr.getCharSet());
        }
        //out.println(msgName);
        String link = Utils.getFwkServerWithoutTS(wctx) 
      + SSOUtil.getLocalLoginUrl() 
      + "?requestUrl=" + oracle.apps.fnd.util.URLEncoder.encode(
        requestUrl, SessionMgr.getCharSet())
      + "&cancelUrl=" + oracle.apps.fnd.util.URLEncoder.encode(
        cancelUrl, SessionMgr.getCharSet());

    //link += "&errCode=" + oracle.apps.fnd.util.URLEncoder.encode(
    //  "FND-9920", SessionMgr.getCharSet());

     link+=errString;
     
    if (langCode != null) {
      link += "&langCode=" + langCode;
    }

    if (request.getParameter("home_url") != null) {
      link += "&home_url=" + oracle.apps.fnd.util.URLEncoder.encode(
        home_url, SessionMgr.getCharSet());
    }

    if (username != null) {
      link += "&username=" + oracle.apps.fnd.util.URLEncoder.encode(
        username, SessionMgr.getCharSet());
    }

     response.sendRedirect(link);
 
  } catch(Exception e) {
    conn.rollback();
    // show some nice error message.
    throw e;

  } finally {
    if (conn != null) { Utils.releaseConnection(); }
    if(alreadySet == false) Utils.releaseAppsContext();
  } 

  response.sendRedirect(requestUrl);
%>
