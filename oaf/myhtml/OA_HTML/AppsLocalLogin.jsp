<!-- $Header: AppsLocalLogin.jsp 115.77 2004/12/02 22:46:36 scheruku noship $ -->

<%@ page import="oracle.cabo.share.config.ConfigurationImpl" %>
<%@ page import='oracle.cabo.ui.ServletRenderingContext'%>
<%@ page import='oracle.cabo.ui.UIConstants'%>
<%@ page import='oracle.cabo.ui.beans.BodyBean'%>
<%@ page import='oracle.cabo.ui.beans.TipBean'%>
<%@ page import='oracle.cabo.ui.beans.StyleSheetBean'%>
<%@ page import='oracle.cabo.ui.beans.form.SubmitButtonBean'%>
<%@ page import='oracle.cabo.ui.beans.form.FormBean'%>
<%@ page import='oracle.cabo.ui.beans.RawTextBean'%>
<%@ page import='oracle.cabo.ui.beans.FormattedTextBean'%>
<%@ page import='oracle.cabo.ui.beans.message.MessageTextInputBean'%>
<%@ page import='oracle.cabo.ui.beans.message.MessageBoxBean'%>
<%@ page import='oracle.cabo.ui.beans.layout.PageLayoutBean'%>
<%@ page import='oracle.cabo.ui.beans.layout.LabeledFieldLayoutBean'%>
<%@ page import='oracle.cabo.ui.beans.layout.FlowLayoutBean'%>
<%@ page import='oracle.cabo.ui.beans.layout.TableLayoutBean'%>
<%@ page import='oracle.cabo.ui.beans.layout.RowLayoutBean'%>
<%@ page import='oracle.cabo.ui.beans.layout.CellFormatBean'%>
<%@ page import='oracle.cabo.ui.beans.ImageBean'%>
<%@ page import='oracle.cabo.ui.beans.layout.SpacerBean'%>
<%@ page import='oracle.cabo.ui.beans.StyledTextBean'%>
<%@ page import='oracle.cabo.ui.beans.message.MessageStyledTextBean'%>
<%@ page import='oracle.cabo.ui.beans.nav.LinkBean'%>
<%@ page import='oracle.cabo.ui.beans.nav.ButtonBean'%>
<%@ page import='oracle.cabo.ui.beans.layout.StackLayoutBean'%>
<%@ page import='oracle.cabo.ui.beans.form.FormValueBean'%>
<%@ page import='oracle.cabo.share.agent.Agent'%>
<%@ page import='oracle.cabo.share.nls.LocaleContext'%>
<%@ page import='oracle.apps.fnd.common.Message'%>
<%@ page import='oracle.apps.fnd.common.WebAppsContext'%>
<%@ page import='oracle.apps.fnd.common.ResourceStore'%>
<%@ page import='oracle.apps.fnd.common.AppsProfileStore'%>
<%@ page import='oracle.apps.fnd.sso.SessionMgr'%>
<%@ page import='oracle.apps.fnd.sso.SSOManager'%>
<%@ page import='oracle.apps.fnd.sso.SSOUtil'%>
<%@ page import='oracle.apps.fnd.sso.Utils'%>
<%@ page import='oracle.apps.fnd.sso.Authenticator'%>
<%@ page import='oracle.apps.fnd.i18n.util.SSOMapper'%>
<%@ page import='oracle.apps.fnd.i18n.util.NLSMapper'%>
<%@ page import='oracle.apps.fnd.sso.HttpLanguageMap'%>
<%@ page import="java.util.Vector" %>
<%@ page import="java.util.StringTokenizer" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.sql.Connection" %>
<%@page import="oracle.apps.fnd.umx.password.PasswordUtil" %>
<%@page import="oracle.apps.fnd.oam.sdk.launchMode.restricted.WarningInfo" %>
<%@page import="oracle.apps.fnd.oam.sdk.launchMode.restricted.OAMRestrictedModeUtil" %>

<%@ page session="false" %>

<%
  response.setHeader("Cache-Control", "no-cache");
  response.setHeader("Pragma", "no-cache");
  response.setDateHeader("Expires", 0);
%>

<%!
  private String getImageSize(String imageSize, String imageName) {
    String myImageName = imageName;
    if (imageSize != null && !imageSize.equals("Regular")) {
      myImageName = myImageName.substring(0, myImageName.indexOf(".gif"))
        + "_MED.gif";
    }

    return myImageName;
  }
%>
<%!
boolean isAgentPDA(PageContext jspPageContext) {
  ServletRenderingContext context =
  new ServletRenderingContext(jspPageContext);
  Agent agent = context.getAgent();

  if ((agent != null) && (agent.getAgentType() == Agent.TYPE_PDA)) {
        return true;
  } else {
    return false;
  }
}
%>
<%
  WebAppsContext wctx = null;
  boolean alreadySet = false;
  Connection conn = null;

    if (Utils.isAppsContextAvailable()) {
       wctx = Utils.getAppsContext();
       alreadySet = true;
    } else {
       wctx = Utils.getAppsContext();
    }

  try {
    
      Utils.setRequestCharacterEncoding(request);
      boolean isPDA = isAgentPDA(pageContext);
      boolean displayUsernameHint =
        "Y".equalsIgnoreCase(request.getParameter("displayUsernameHint"));
      boolean displayPasswordHint =
        "Y".equalsIgnoreCase(request.getParameter("displayPasswordHint"));

      String requestUrl = request.getParameter("requestUrl");
      String cancelUrl = request.getParameter("cancelUrl");
      String registerUrl = request.getParameter("registerUrl");
      String FND_SSO_LOGIN = null;
      String FND_SSO_CANCEL = null;
      String FND_SSO_REGISTER_HERE = null;
      String FND_SSO_ERROR = null;
      String FND_SSO_WELCOME = null;
      String FND_SSO_ENTER_USER_NAME = null;
      String FND_SSO_REQUIRED = null;
      String FND_REQUIRED = null;
      String FND_SSO_USER_NAME = null;
      String FND_SSO_PASSWORD = null;
      String FND_SSO_SYSTEM_NOT_AVAIL = null;
      String FND_NOJAVASCRIPT = null;
      String FND_ORACLE_LOGO = null;
      String FND_EBIZ_SUITE = null;

      String FND_SSO_HINT_USERNAME = null;
      String FND_SSO_HINT_PASSWORD = null;
      String FND_SSO_SARBANES_OXLEY_TEXT = null;
      String FND_SSO_COPYRIGHT_TEXT = null;
      String FND_SSO_FORGOT_PASSWORD = null;
      String FND_SSO_LOGIN_MESSAGE = null;
      String FND_SSO_EBIZ_SUITE = null;

      String errCode = request.getParameter("errCode");
      String errText = request.getParameter("errText");
      String errMsg = null;
      String stackTrace = "";
      Message msg = null;
      String usernameHint = "&nbsp;";
      String passwordHint = "&nbsp;";
      String langCode = request.getParameter("langCode");
      String home_url = request.getParameter("home_url");
      String hLang = "";
      String dir = "";
      String end = "right";
      String imageSize = null;
      Vector myImages = null;
      int myImageSize = 0;
      String cancelProfile = null;
      String sOriginatingPage = "AppsLocalLogin.jsp";
      String sTargetPage = "AppsLocalLogin.jsp";
  
      ResourceStore rStore = null;
      HttpLanguageMap httpLangMap = null;

      /*
        Bitmap values for optional Login Page attributes
        To show these attributes, just add the numeric values of all desired
        attributes. So, for example to show PASSWORD_HINT and FORGOT_PASSWORD_URL
        set the profile option, FND_SSO_LOGIN_MASK to 18 (2 + 16)

        Converting decimal 512 to hexadecimal
          512 / 16 = 32, 0 (remainder in hex)
          32 / 16 = 2, 0
          2 / 16 = 0, 2
          So decimal 512 is 0X200 in hexadecimal
          128 = 0X80, 256 = 0X100
      */
      final int USERNAME_HINT       = 0x01; // 1
      final int PASSWORD_HINT       = 0x02; // 2
      final int CANCEL_BUTTON       = 0x04; // 4
      final int FORGOT_PASSWORD_URL = 0x08; // 08
      final int REGISTER_URL        = 0x10; // 16
      final int LANGUAGE_IMAGES     = 0x20; // 32
      final int SARBANES_OXLEY_TEXT = 0x40; // 64

      conn = Utils.getConnection();
      String mask = wctx.getProfileStore().getProfile("FND_SSO_LOCAL_LOGIN_MASK");
      if (mask == null || mask.equals("")) {
          mask = "0";
      }
      
      int displayMask = 0;
      try {
        displayMask = Integer.parseInt(mask);

      } catch (NumberFormatException nfe) {
        displayMask = 0;
      }
      rStore = wctx.getResourceStore();
      httpLangMap = new HttpLanguageMap();
  
      if(langCode == null){
        String langs = request.getHeader("Accept-Language");
        if(langs != null){
          if(langs.indexOf(",") == -1){
            langCode = httpLangMap.getOracleFromHttp(langs.trim());
          }else{
            StringTokenizer st = new StringTokenizer(langs, ",");
            while(st.hasMoreTokens()){
              String tmpLang = st.nextToken();
              int ind = tmpLang.indexOf(";");
              if(ind != -1)
                tmpLang = tmpLang.substring(0,ind);
                langCode = httpLangMap.getOracleFromHttp(tmpLang.trim());
                langCode = langCode.toUpperCase();
                if(SessionMgr.isInstalledLanguage(langCode)){
                     break;
                }
            }
          }
        }
      } 

      if (registerUrl == null || "".equals(registerUrl)) {
         registerUrl =
            oracle.apps.fnd.umx.util.regURL.RegURLGenerator.generateDefaultURL(
               wctx, SSOManager.getLoginUrl());
      }

  try {
      if (requestUrl == null || requestUrl.equals("APPSHOMEPAGE")) {
        if (isPDA) {
          String dbc = oracle.apps.fnd.common.WebRequestUtil.getDBC(
            request, response);
          requestUrl = Utils.getFwkServerWithoutTS(wctx) +
            "/OA_HTML/OA.jsp?page=/oracle/apps/fnd/framework/navigate/webui/" +
            "AppsNavigateMobilePG&dbc="+dbc;
        } else {
          requestUrl = "APPSHOMEPAGE";
        } 
      }

      imageSize = wctx.getProfileStore().getProfile("FND_BRANDING_SIZE");

      String pNlsLanguage = null;

      if (!SessionMgr.isInstalledLanguage(langCode)) {
        pNlsLanguage = wctx.getProfileStore().getProfile("ICX_LANGUAGE");
        langCode = wctx.getLangCode(pNlsLanguage);
        wctx.setNLSContext(pNlsLanguage, null, null, null, null, null);
        wctx.setCurrLang(langCode);
      } else {
        langCode = langCode.toUpperCase();
        oracle.apps.fnd.common.LangInfo info =
          wctx.getLangInfo(langCode , null, conn);
        pNlsLanguage = info.getNLSLanguage();
        wctx.setNLSContext(pNlsLanguage, null, null, null, null, null);
        wctx.setCurrLang(langCode);
      }
    // BiDi
      if (SessionMgr.isRtl(langCode)) {
        dir = " dir=rtl";
        end = "left";
      }

      response.setContentType("text/html; charset=" +
        oracle.apps.fnd.sso.SessionMgr.getCharSet());

      if (errCode != null && !errCode.trim().equals("")) {
        msg = new Message("FND", errCode);
        errMsg = msg.getMessageText(wctx.getResourceStore());
      }

      if (errCode == null && errText != null && !errText.trim().equals("")) {
        errMsg = errText;
      }

      msg = new Message("FND", "FND_SSO_LOGIN");
      FND_SSO_LOGIN = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_SSO_CANCEL");
      FND_SSO_CANCEL = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_SSO_REGISTER_HERE");
      FND_SSO_REGISTER_HERE = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_SSO_ERROR");
      FND_SSO_ERROR = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_SSO_WELCOME");
      FND_SSO_WELCOME = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_SSO_ENTER_USER_NAME");
      FND_SSO_ENTER_USER_NAME = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_SSO_REQUIRED");
      FND_SSO_REQUIRED = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_REQUIRED");
      FND_REQUIRED = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_SSO_USER_NAME");
      FND_SSO_USER_NAME = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_SSO_PASSWORD");
      FND_SSO_PASSWORD = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_SSO_SYSTEM_NOT_AVAIL");
      FND_SSO_SYSTEM_NOT_AVAIL = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_NOJAVASCRIPT");
      FND_NOJAVASCRIPT = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_ORACLE_LOGO");
      FND_ORACLE_LOGO = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_EBIZ_SUITE");
      FND_EBIZ_SUITE = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_SSO_HINT_USERNAME");
      FND_SSO_HINT_USERNAME = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_SSO_HINT_PASSWORD");
      FND_SSO_HINT_PASSWORD = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_SSO_SARBANES_OXLEY_TEXT");
      FND_SSO_SARBANES_OXLEY_TEXT = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_SSO_COPYRIGHT_TEXT");
      FND_SSO_COPYRIGHT_TEXT = msg.getMessageText(rStore);

      msg = new Message("FND", "FND_SSO_FORGOT_PASSWORD");
      FND_SSO_FORGOT_PASSWORD = msg.getMessageText(rStore);
    
      msg = new Message("FND", "FND_SSO_EBIZ_SUITE");
      FND_SSO_EBIZ_SUITE = msg.getMessageText(rStore);
    

      msg = new Message( "FND", "UMX_FORGOT_PWD_LOGIN_DISP_NAME" );
      FND_SSO_LOGIN_MESSAGE = msg.getMessageText(rStore);


      if (displayUsernameHint) {
        msg = new Message("FND", "FND_SSO_USER_NAME_EX");
        usernameHint = msg.getMessageText(rStore);
      } 

      if (displayPasswordHint) {
        msg = new Message("FND", "FND_SSO_PASSWORD_EX");
        passwordHint = msg.getMessageText(rStore);
      }

      if(!isPDA){
        myImages = SessionMgr.getInstalledLanguageImgInfo(request, wctx);
        myImageSize = myImages.size();
      }
     } catch (Exception e) {
      stackTrace = oracle.apps.fnd.sso.Utils.getExceptionStackTrace(e);
      errCode = e.getMessage();
      msg = new Message("FND", errCode);
      errMsg = msg.getMessageText(rStore);

      if (errCode == null) {
        msg = new Message("FND", "FND-9914");
        errMsg = msg.getMessageText(rStore);
      }
    }
      if (langCode == null) {
          langCode = "US";
      }
      hLang ="lang=\""+httpLangMap.getHttpFromOracle(langCode)+"\"";
%>
<html <%=dir%> <%=hLang%>>
<head>
<title><%=FND_SSO_LOGIN %></title>
<%
  // Rendering part
      ServletRenderingContext rContext = new ServletRenderingContext(pageContext);
      ConfigurationImpl cimpl = new ConfigurationImpl("myConfig");
      cimpl.putFullURIAndPath(cimpl.BASE_DIRECTORY, "/OA_HTML/cabo/",
      pageContext.getServletContext().getRealPath("/")+"/cabo/");
      cimpl.register();
      rContext.setConfiguration("myConfig");
      SSOMapper ssoMapper = Authenticator.lmap;

      java.util.Locale myLocale =
        new Locale(ssoMapper.getHttpLangFromOracle(langCode),
                 ssoMapper.getTerritoryCode(langCode));

      rContext.setLocaleContext(new LocaleContext(myLocale));
      StyleSheetBean.sharedInstance().render(rContext);
%>
<noscript><%=FND_NOJAVASCRIPT%></noscript>
</head>

<%
/*
 The following is the bean hierarchy:
 pageLayout
|_ stackLayout
   |_TableLayout
     |_rowLayout1
       |_cellFormat
         |_LabelledFeildLayout
         | |_username
         | |_password
         | |_spacerBean
         |_flowLayout1
         | |_submitButton(login)
         | |_cancelButton(Cancel)
         |_Spacer
         |_FlowLayout2
         | |_RowLayout2
         |   |_cellFormat
         |   | |_tip      (Text:Did you)
         |   |_cellFormat
         |   | |_spacer
         |   |_cellFormat
         |     |_link      (forgot your password ?)
         |__RawText(Empty)
         |_FlowLayout3
   | |_RowLayout3
   |   |_cellFormat
   |   | |_tip
   |   |_cellFormat
   |   | |_spacer
   |   |_cellFormat
         |     |_link     (register here)

*/
      BodyBean body = new BodyBean();
      String ssoScript = "document.myForm.username.focus();"+
                     " document.myForm.password.onkeypress = keyhandler;"+
                     " function keyhandler(e){ "+
                     "var kc; "+
                     "if(window.event) kc=window.event.keyCode; "+
                     "else if(e)  kc=e.which; "+
                     "if (kc == 13) {  submitForm('myForm'); }}";
                     
      body.setOnLoad(ssoScript);
  
        PageLayoutBean pageLayout = new PageLayoutBean();
          TableLayoutBean brandingFlbean1 = new TableLayoutBean();
            RowLayoutBean rowLay1 = new RowLayoutBean();
              CellFormatBean cbean1 = new CellFormatBean();
      
     if(isPDA)//bug 3624006 
      { 
                FormattedTextBean formattedText = new FormattedTextBean("ORACLE "); 
                  formattedText.setStyleClass("OraInlineErrorText"); // OraHeaderSub
               cbean1.addIndexedChild(formattedText);
               cbean1.setWrappingDisabled(true);
                FormattedTextBean formattedText1 = new FormattedTextBean(FND_SSO_EBIZ_SUITE); 
                  formattedText1.setStyleClass("OraInlineErrorText"); // OraHeaderSub 
               cbean1.addIndexedChild(formattedText1);
             rowLay1.addIndexedChild(cbean1);
        brandingFlbean1.addIndexedChild(rowLay1);
      } 
      else 
      { 
               cbean1.setVAlign(UIConstants.V_ALIGN_TOP);
                 ImageBean imgBean1 = new ImageBean("/OA_MEDIA/FNDSSCORP.gif", FND_ORACLE_LOGO);
               cbean1.addIndexedChild(imgBean1);
             rowLay1.addIndexedChild(cbean1);
         
              CellFormatBean cbean2 = new CellFormatBean();
                cbean2.setVAlign(UIConstants.V_ALIGN_BOTTOM);
                cbean2.setWrappingDisabled(true);
                  FormattedTextBean formattedText = new FormattedTextBean(FND_SSO_EBIZ_SUITE);
                   formattedText.setStyleClass("OraHeaderSub"); // OraHeaderSub
                cbean2.addIndexedChild(formattedText); 
             rowLay1.addIndexedChild(cbean2);
           

              StackLayoutBean stb = new StackLayoutBean();
                stb.addIndexedChild(new SpacerBean(4,4));
                  ImageBean imgBean2 = new ImageBean("/OA_MEDIA/fndpbs.gif");
                stb.addIndexedChild(imgBean2);
             rowLay1.addIndexedChild(stb);
        brandingFlbean1.addIndexedChild(rowLay1);

          RowLayoutBean rowLay2 = new RowLayoutBean();
            rowLay2.addIndexedChild(new SpacerBean(1,30));
            rowLay2.addIndexedChild(new SpacerBean(1,30));
            rowLay2.addIndexedChild(new SpacerBean(1,30));
        brandingFlbean1.addIndexedChild(rowLay2);      
      }
         pageLayout.setCorporateBranding(brandingFlbean1);
         pageLayout.setTitle(FND_SSO_LOGIN);
      

      if (errMsg!=null && !errMsg.trim().equals("")) {
           MessageBoxBean msgBoxBean =
            new MessageBoxBean(UIConstants.MESSAGE_TYPE_ERROR, errMsg);
         pageLayout.addIndexedChild(msgBoxBean);
      }

      String restrictedModeMsg = "";
      WarningInfo wi = OAMRestrictedModeUtil.getWarningMessage(wctx);
      if (wi != null) {
          restrictedModeMsg = wi.getCommentsText();
      }

      if (restrictedModeMsg!=null && !restrictedModeMsg.trim().equals("") 
        && (errMsg == null || "".equals(errMsg)) ) {

        MessageBoxBean msgBoxBean =
          new MessageBoxBean(UIConstants.MESSAGE_TYPE_WARNING, restrictedModeMsg);
         pageLayout.addIndexedChild(msgBoxBean);
      }

          StackLayoutBean stackLayout = new StackLayoutBean();
            FormBean form = new FormBean("myForm");
              form.setMethod("POST");
              form.setDestination("fndvald.jsp");

      if (!isPDA) {
          StackLayoutBean stackLayoutForCopyright = new StackLayoutBean();
            StyledTextBean copyRight = new StyledTextBean();
              copyRight.setText(FND_SSO_COPYRIGHT_TEXT);

          if ((displayMask & SARBANES_OXLEY_TEXT) != 0) {
              StyledTextBean legalMessage = new StyledTextBean();
                legalMessage.setText(FND_SSO_SARBANES_OXLEY_TEXT);
           stackLayoutForCopyright.addIndexedChild(legalMessage);
          }
           stackLayoutForCopyright.addIndexedChild(copyRight);
         pageLayout.setCopyright(stackLayoutForCopyright);
      }

      if (FND_SSO_USER_NAME == null || FND_SSO_PASSWORD == null) { //bug 3210032
           MessageBoxBean msgBoxBean =
            new MessageBoxBean(UIConstants.MESSAGE_TYPE_ERROR, FND_SSO_SYSTEM_NOT_AVAIL);
         pageLayout.addIndexedChild(msgBoxBean);
        body.render(rContext);
      }
      else
      {
                TableLayoutBean tlayout = new TableLayoutBean();
                  tlayout.setWidth("100%");
                    RowLayoutBean rl1 = new RowLayoutBean();
                      cbean1 = new CellFormatBean();
                      cbean1.setHAlign(UIConstants.H_ALIGN_CENTER);
                        LabeledFieldLayoutBean layout = new LabeledFieldLayoutBean();
                          MessageTextInputBean username = null;
                            username = new MessageTextInputBean("username");
                          if(request.getParameter("username") != null){
                            username.setText(request.getParameter("username").trim());
                          }
                            username.setPrompt(FND_SSO_USER_NAME);

                          if (((displayMask & USERNAME_HINT) != 0) && !isPDA) {
                            username.setTip(FND_SSO_HINT_USERNAME);
                          }
                         layout.addIndexedChild(username);
                          MessageTextInputBean password = new MessageTextInputBean("password");
                          if (((displayMask & PASSWORD_HINT) != 0) && !isPDA) {
                            password.setTip(FND_SSO_HINT_PASSWORD);
                          }
                            password.setPrompt(FND_SSO_PASSWORD);
                            password.setSecret(true);
                         layout.addIndexedChild(password);
                         layout.addIndexedChild(new  SpacerBean(1,30));
                          SubmitButtonBean button = new SubmitButtonBean(FND_SSO_LOGIN);
                        if (cancelUrl != null && !cancelUrl.equals("") &&
                            (displayMask & CANCEL_BUTTON) != 0) {

                         FlowLayoutBean flbean = new FlowLayoutBean();
                          flbean.addIndexedChild(button);
                           ButtonBean cbutton = new ButtonBean(FND_SSO_CANCEL);
                            cbutton.setDestination(cancelUrl);
                          flbean.addIndexedChild(cbutton);
                         layout.addIndexedChild(flbean);
                        } else {
                         layout.addIndexedChild(button);
                        }

                        String forgotPwdUrl = null;
                        try
                        {
                          if(!isPDA) forgotPwdUrl = PasswordUtil.generateForgotPwdUrl(wctx
                               , SSOManager.getLoginUrl(), SSOManager.getLoginUrl(), FND_SSO_LOGIN);
                        }catch (Exception e) {
                          stackTrace = oracle.apps.fnd.sso.Utils.getExceptionStackTrace(e);
                          errCode = e.getMessage();
                          msg = new Message("FND", errCode);
                          errMsg = msg.getMessageText(rStore);

                          if (errCode == null) {
                            msg = new Message("FND", "FND-9914");
                            errMsg = msg.getMessageText(rStore);
                          }
                        } 

                           if (((displayMask & FORGOT_PASSWORD_URL) != 0) && !isPDA &&
                              (forgotPwdUrl != null && !("".equals(forgotPwdUrl)))) {

                          FlowLayoutBean flbean_tip1 = new FlowLayoutBean();
                              RowLayoutBean tip_row1 = new RowLayoutBean();
                              if (dir!=null && !dir.equals(""))
                                tip_row1.setHAlign(UIConstants.H_ALIGN_RIGHT);
                              else
                                tip_row1.setHAlign(UIConstants.H_ALIGN_LEFT);

                                 CellFormatBean cf11 = new CellFormatBean();
                                   TipBean tip1 = new TipBean("");
                                  cf11.addIndexedChild(tip1);
                                tip_row1.addIndexedChild(cf11);


                                 CellFormatBean cf12 = new CellFormatBean();
                                   SpacerBean spacer1 = new  SpacerBean(5,1);
                                  cf12.addIndexedChild(spacer1);
                                tip_row1.addIndexedChild(cf12);

                                 CellFormatBean cf13 = new CellFormatBean();
                                  cf13.setHAlign(UIConstants.H_ALIGN_LEFT);
                                   LinkBean forgotPasswordLink = new LinkBean(FND_SSO_FORGOT_PASSWORD
                                      , forgotPwdUrl);
                                  cf13.addIndexedChild(forgotPasswordLink);
                                tip_row1.addIndexedChild(cf13);
                           flbean_tip1.addIndexedChild(tip_row1);
                         layout.addIndexedChild(new SpacerBean(1,20));
                         layout.addIndexedChild(flbean_tip1);
                        }
                         layout.addIndexedChild(new RawTextBean());
                      if (((displayMask & REGISTER_URL) != 0) && !isPDA
                        && (registerUrl != null && !("".equals(registerUrl)))) {

                          FlowLayoutBean flbean_tip2 = new FlowLayoutBean();
                            RowLayoutBean tip_row2 = new RowLayoutBean();

                              CellFormatBean cf21 = new CellFormatBean();
                                TipBean tip2 = new TipBean();
                               cf21.addIndexedChild(tip2);
                             tip_row2.addIndexedChild(cf21);
                             
                              CellFormatBean cf22 = new CellFormatBean();
                                SpacerBean spacer2 = new SpacerBean(5,1);
                               cf22.addIndexedChild(spacer2);
                             tip_row2.addIndexedChild(cf22);
                            
                              CellFormatBean cf23 = new CellFormatBean();
                                LinkBean registerLink = new LinkBean(FND_SSO_REGISTER_HERE, registerUrl);
                               cf23.addIndexedChild(registerLink);
                             tip_row2.addIndexedChild(cf23);

                           flbean_tip2.addIndexedChild(tip_row2);
                         layout.addIndexedChild(flbean_tip2);
                      }

                         layout.addIndexedChild(new RawTextBean());
                       if (displayMask == 127 ) {
                         layout.addIndexedChild(new SpacerBean(1, 20));
                       } else {
                         layout.addIndexedChild(new SpacerBean(1, 5));
                       }
                         layout.addIndexedChild(new RawTextBean());
                      cbean1.addIndexedChild(layout);
                     rl1.addIndexedChild(cbean1);
                  tlayout.addIndexedChild(rl1);

                  if (myImageSize > 1 && ((displayMask & LANGUAGE_IMAGES) != 0) && !isPDA) {
                   RowLayoutBean rl2 = new RowLayoutBean();
                     rl2.setWidth("100%");
                     CellFormatBean cbean2 = new CellFormatBean();
                       cbean2.setWidth("100%");
                       cbean2.setHAlign("center");
                         FlowLayoutBean langSwitcher = new FlowLayoutBean();
                          Vector tmpVec = (Vector)myImages.elementAt(0);
                           langSwitcher.addIndexedChild(new ImageBean((String)tmpVec.elementAt(1),
                            (String)tmpVec.elementAt(2), (String)tmpVec.elementAt(3)));

                         for ( int i=1; i<myImageSize;i++) {
                           tmpVec = (Vector)myImages.elementAt(i);
                           langSwitcher.addIndexedChild(new ImageBean("/OA_MEDIA/lang_bullet.gif"));
                           langSwitcher.addIndexedChild(new ImageBean((String)tmpVec.elementAt(1),
                              (String)tmpVec.elementAt(2), (String)tmpVec.elementAt(3)));
                         } 
                        cbean2.addIndexedChild(langSwitcher);
                     rl2.addIndexedChild(cbean2);
                  tlayout.addIndexedChild(rl2);
              }
              form.addIndexedChild(tlayout);
            if (langCode != null) {
              form.addIndexedChild(new FormValueBean("langCode", langCode));
            } 

            if (home_url != null) {
              form.addIndexedChild(new FormValueBean("home_url",home_url ));
            }

            if (cancelUrl != null){
              form.addIndexedChild(new FormValueBean("cancelUrl",cancelUrl ));
            }

              form.addIndexedChild(new FormValueBean("requestUrl", requestUrl ));
           stackLayout.addIndexedChild(form);
         pageLayout.addIndexedChild(stackLayout);
        body.addIndexedChild(pageLayout);
        body.render(rContext);
      }
      } catch(Exception e){}
       finally{
         if(conn!=null) Utils.releaseConnection();
         if(alreadySet == false) Utils.releaseAppsContext();
      }
%>
</html>
