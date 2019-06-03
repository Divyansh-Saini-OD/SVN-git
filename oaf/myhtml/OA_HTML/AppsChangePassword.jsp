<%
/*============================================================================+
 |               Copyright (c) 2003 Oracle Corporation                        |
 |                  Redwood Shores, California, USA                           |
 |                       All rights reserved                                  |
 +============================================================================|

History
13-OCT-2003 kkho   Use AOL/J underline error messages
21-MAR-2003 kkho   change code to work with prompts
20-MAR-2003 dehu   added prompts
20-MAR-2003 kkho   Look up minimum password length from SIGNON_PASSWORD_LENGTH profile
                   Pick up error messages from aol/j for valiate login
                   and changePassword
20-MAR-2003 kkho   Added logic, both client and server side, to check for
                     required fields
                   Removed tip
                   Hide the whole page if password is not changeable
                     or session is invalid
18-MAR-2003 kkho   Check isPasswordChangeable before displaying the page
                   Change jsp forward to redirect
17-MAR-2003 kkho   Validate session before displaying the page
                   Set type to password for all password input fields
*/

%>
<!-- $Header: AppsChangePassword.jsp 115.26 2004/12/02 22:50:08 scheruku noship $ -->
<%@ page import='javax.servlet.http.Cookie'%>
<%@ page import='oracle.apps.fnd.common.Message'%>
<%@ page import='oracle.apps.fnd.common.WebAppsContext'%>
<%@ page import='oracle.apps.fnd.common.ResourceStore'%>
<%@ page import='oracle.apps.fnd.security.SessionManager'%>
<%@ page import='oracle.apps.fnd.sso.SessionMgr'%>
<%@ page import='oracle.apps.fnd.sso.SSOManager'%>
<%@ page import='oracle.apps.fnd.sso.Utils'%>
<%!
    private String getImageDir(String dir, String imageName) {
        String myImageName = imageName;

        if (dir != null && !dir.trim().equals("")) {
            myImageName = myImageName.substring(0, myImageName.indexOf(".gif")) + "_rtl.gif";
        }
        return myImageName;
    }

    private String getImageSize(String imageSize, String imageName) {
        String myImageName = imageName;

        if (imageSize != null && !imageSize.equals("Regular")) {
            myImageName = myImageName.substring(0, myImageName.indexOf(".gif")) + "_MED.gif";
        }
        return myImageName;
    }
%>
<%
        String stackTrace = "";
        // change password
        Utils.setRequestCharacterEncoding(request);
        String Apply = request.getParameter("Apply");
        String password = request.getParameter("password");
        String newPassword = request.getParameter("newPassword");
        String newPassword2 = request.getParameter("newPassword2");
        String errCode = request.getParameter("errCode");
        String Cancel = request.getParameter("Cancel");
        String returnUrl = request.getParameter("returnUrl");
        String changePwdError = null;
        String invalidLoginError = null;

        //String pwdTooShort = "The new password is too short.";

        // translate errCode to error message
        String errMsg = null;
        String confirmMsg = null;
        boolean alreadySet = false;
        String userName = null;
        boolean isValidSession = false;
        boolean isValidLogin = false;
        boolean isPwdChanged = false;
        int passwordLength = -1;
        String passwordLengthStr = null;
        Message msg;
        String changePwdStr;
        String FND_SSO_REQUIRED;
        String FND_REQUIRED;
        String cPwdStr;
        String nPwdStr;
        String rPwdStr;
        String cancelStr;
        String applyStr;
        String errorStr;
        String confirmStr;
        String tipStr;
        String requiredMsg;
        String FND_NOJAVASCRIPT;
        String FND_ORACLE_LOGO;
        String FND_EBIZ_SUITE;

        WebAppsContext wctx = null;
        SessionManager mSessionManager = null;
        ResourceStore rStore = null;

        // BiDi
        String dir = "";
        String end = "right";
        String langCode;
        String imageSize = "";

        try {
            if (Utils.isAppsContextAvailable()) {
                wctx = Utils.getAppsContext();
                alreadySet = true;
            } else {
                wctx = Utils.getAppsContext();
            }
            rStore = wctx.getResourceStore();
            imageSize = wctx.getProfileStore().getProfile("FND_BRANDING_SIZE");

            passwordLengthStr = wctx.getProfileStore().getProfile("SIGNON_PASSWORD_LENGTH");			

            if (passwordLengthStr != null) {
                passwordLength = Integer.parseInt(passwordLengthStr);
            }
            else if (passwordLengthStr == null) {
                passwordLength = 5;
            }

            mSessionManager = wctx.getSessionManager();
            // get cookie value: SessionMgr.getAppsCookie(request);
            Cookie[] cookies = request.getCookies();
            String cval = null;
            String cname = wctx.getSessionCookieName();

            for (int i = 0; cookies != null && i < cookies.length; i++) {
                if (cookies[i].getName().equals(cname)) {
                    cval = cookies[i].getValue();
                    break;
                }
            }
            isValidSession = wctx.validateSession(cval);
            response.setContentType("text/html; charset=" + oracle.apps.fnd.sso.SessionMgr.getCharSet());

            if (!isValidSession) {
                // out.println("Session Validation Failed."  + wctx.getErrorStack().getAllMessages());
                throw new RuntimeException("FND_SESSION_DOESNT_EXIST");
            }

            //BiDi
            langCode = wctx.getCurrLangCode();

            //if (langCode != null && (langCode.equals("IW") || langCode.equals("AR"))) {
            if (SessionMgr.isRtl(langCode)) {
                dir = " dir=rtl";
                end = "left";
            }

            userName = wctx.getID(99); // constant returns userName for the session.
            if (!SSOManager.isPasswordChangeable(userName)) {
                throw new RuntimeException("FND_PASSWORD_NOT_CHANGEABLE");
            }
        } catch (Exception e) {
            stackTrace = oracle.apps.fnd.sso.Utils.getExceptionStackTrace(e);
            errCode = e.getMessage();
            // translate the message
            msg = new Message("FND", errCode);
            errMsg = msg.getMessageText(rStore);
        } finally {
            msg = new Message("FND", "FND_SSO_CHANGE_PWD");
            changePwdStr = msg.getMessageText(rStore);
            msg = new Message("FND", "FND_SSO_REQUIRED");
            FND_SSO_REQUIRED = msg.getMessageText(rStore);
            msg = new Message("FND", "FND_REQUIRED");
            FND_REQUIRED = msg.getMessageText(rStore);
            msg = new Message("FND", "FND_SSO_CURRENT_PWD");
            cPwdStr = msg.getMessageText(rStore);
            msg = new Message("FND", "FND_SSO_NEW_PWD");
            nPwdStr = msg.getMessageText(rStore);
            msg = new Message("FND", "FND_SSO_REENTER_PWD");
            rPwdStr = msg.getMessageText(rStore);
            msg = new Message("FND", "FND_SSO_CANCEL");
            cancelStr = msg.getMessageText(rStore);
            msg = new Message("FND", "FND_SSO_APPLY");
            applyStr = msg.getMessageText(rStore);
            msg = new Message("FND", "FND_SSO_ERROR");
            errorStr = msg.getMessageText(rStore);
            msg = new Message("FND", "FND_SSO_CONFIRM");
            confirmStr = msg.getMessageText(rStore);

            msg = new Message("FND", "FND_NOJAVASCRIPT");
            FND_NOJAVASCRIPT = msg.getMessageText(rStore);

            msg = new Message("FND", "FND_ORACLE_LOGO");
            FND_ORACLE_LOGO = msg.getMessageText(rStore);

            msg = new Message("FND", "FND_EBIZ_SUITE");
            FND_EBIZ_SUITE = msg.getMessageText(rStore);

            /*
             //FND_SSO_PWD_TIP1=Password must be at least &LENGTH characters long.
             msg = new Message("FND", "FND_SSO_PWD_TIP1");
             msg.setToken("LENGTH", passwordLengthStr, true);
             tipStr = msg.getMessageText(rStore);
             */
            //FND_SSO_PWD_TIP1=Password must be at least
            //FND_SSO_PWD_TIP2= characters long.
            msg = new Message("FND", "FND_SSO_PWD_TIP1");
            tipStr = msg.getMessageText(rStore) + " " + passwordLength;
            msg = new Message("FND", "FND_SSO_PWD_TIP2");
            tipStr += msg.getMessageText(rStore);

            msg = new Message("FND", "FND_SSO_PASSWORD_REQUIRED");
            requiredMsg = msg.getMessageText(rStore);
        }

        // if ("Apply".equals(Apply) &&
        //if (applyStr.equals(Apply) &&
        if (Apply != null &&
            password != null && !password.trim().equals("") &&
            newPassword != null && !newPassword.trim().equals("") &&
            newPassword2 != null && !newPassword2.trim().equals("")
        ) { // clicked Apply button
            try { // throw RuntimeException to exit
                if (!newPassword.equals(newPassword2)) {
                    throw new RuntimeException("FND_USERADMIN_PASSWORD_DIFFER");
                }

                if (newPassword.length() < passwordLength) {
                    throw new RuntimeException("FND_SSO_PASSWORD_TOO_SHORT");
                }

                // do the real work here
                if (errCode != null && !errCode.trim().equals("")) { // has error
                    // translate the message
                    Message message = new Message("FND", errCode);

                    errMsg = message.getMessageText(rStore);
                    throw new RuntimeException(errMsg);
                }

                isValidLogin = mSessionManager.validateLogin(userName, password);
                if (isValidLogin) {
//                    isPwdChanged = mSessionManager.changePassword(userName, newPassword);
                    isPwdChanged = mSessionManager.changePassword(userName, password, newPassword, newPassword2);
                    if (isPwdChanged) {
                        Message message = new Message("FND", "FND_UPDATE_SUCCESS");

                        confirmMsg = message.getMessageText(rStore);
                    } else {

                        /* Log the error stack. */
                        changePwdError = "";
                        for (int i = 0; i < wctx.getErrorStack().getMessageCount(); i++) {
                            changePwdError += wctx.getErrorStack().nextMessage();
                        }
                        // throw new RuntimeException("FND_UPDATE_FAIL");
                        throw new RuntimeException(changePwdError);
                    }
                } else {

                    /* Log the error stack. */
                    invalidLoginError = "";
                    for (int i = 0; i < wctx.getErrorStack().getMessageCount(); i++) {
                        invalidLoginError += wctx.getErrorStack().nextMessage();
                    }
                    throw new RuntimeException("FND-9920");
                }

            } catch (Exception e) {
                stackTrace = oracle.apps.fnd.sso.Utils.getExceptionStackTrace(e);
                errCode = e.getMessage();
                if (errCode.equals("FND_UPDATE_FAIL")) {
                    stackTrace = changePwdError;
                } else if (errCode.equals("FND-9920")) {
                    stackTrace = invalidLoginError;
                }
                msg = new Message("FND", errCode);
                if (msg != null && !msg.equals("")) {
                  errMsg = msg.getMessageText(rStore);
                } else {
                  errMsg = e.getMessage();
                }
            } finally {
            }
        } else if (applyStr.equals(Apply)) {
            // errCode = "FND_SSO_PASSWORD_REQUIRED";
            errMsg = requiredMsg;
        }

            if (alreadySet == false) {
                Utils.releaseAppsContext();
            }
        // If the password change successful, redirect back to the returnUrl;
        // else if the password change fails, redirect to the cancelUrl.
        if (Apply != null && returnUrl != null && isPwdChanged) {
            response.sendRedirect(returnUrl);
        }

        String cancelUrl = request.getParameter("cancelUrl");

        /*
         if (Cancel != null && cancelUrl != null) {
         response.sendRedirect(cancelUrl);
         }
         -----*/
%>
<html<%=dir%>>
<head>
<title>Change Password</title>
<style type="text/css">
.x1 {BACKGROUND-COLOR: #336699}
.x9 {background-color: #cccc99}
.x10 {FONT-SIZE: 83%; font-family:Arial,Helvetica,Geneva,sans-serif;color:#cc0000}
.x14 {FONT-SIZE: 133%; COLOR: #336699; FONT-FAMILY: Arial,Helvetica,Geneva,sans-serif}
.x1i {FONT-SIZE: 108%; FONT-WEIGHT: bold; COLOR: #ffffff; FONT-FAMILY: Arial,Helvetica,Geneva,sans-serif}
.x3s {FONT-SIZE: 83%; COLOR: #3366cc; FONT-FAMILY: Courier,sans-serif}
.xd {FONT-SIZE: 83%; COLOR: #000000; FONT-FAMILY: Arial,Helvetica,Geneva,sans-serif}
.xh {FONT-SIZE: 83%; COLOR: #000000; FONT-FAMILY: Arial,Helvetica,Geneva,sans-serif}
.xl {FONT-SIZE: 83%; COLOR: #000000; FONT-FAMILY: Arial,Helvetica,Geneva,sans-serif}
.xw {FONT-SIZE: 83%; FONT-WEIGHT: bold; COLOR: #336699; FONT-FAMILY: Arial,Helvetica,Geneva,sans-serif}
.xx {FONT-SIZE: 83%; COLOR: #336699; FONT-FAMILY: Arial,Helvetica,Geneva,sans-serif}
.xy {FONT-SIZE: 67%; COLOR: #336699; FONT-FAMILY: Arial,Helvetica,Geneva,sans-serif}
.OraErrorHeader {FONT-SIZE: 92%; font-family: Arial, Helvetica, Geneva, sans-serif; color: #CC0000; font-weight: bold}
.confirmHeader {FONT-SIZE: 92%; font-family: Arial, Helvetica, Geneva, sans-serif; color: #808000; font-weight: bold}
.confirmText {FONT-SIZE: 83%; COLOR: #808000; FONT-FAMILY: Arial,Helvetica,Geneva,sans-serif}
</style>
<SCRIPT>
function redirect(loc)
{
  window.location = loc;
}

function validate(msg) {
  password=myForm.password.value;
  newPassword=myForm.newPassword.value;
  newPassword2=myForm.newPassword2.value;
  apply=myForm.Apply.value;
  if (apply!='' && (password=='' || newPassword=='' || newPassword2=='')) {
    alert(msg);
    event.returnValue=false;
  }
}

function t(width,height) {
document.write('<img alt="" src="/OA_MEDIA/fnd_t.gif"');if (width!=void 0)document.write(' width="' + width + '"');if (height!=void 0)document.write(' height="' + height + '"');document.write('>');
}
</SCRIPT>
<NOSCRIPT><P><%=FND_NOJAVASCRIPT%></NOSCRIPT>
</head>
<body bgcolor="#ffffff"  link='#663300' alink='FF6600' vlink='#996633' onload="document.myForm.password.focus();">
<!--<%=stackTrace%> -->
<form id="myForm" style="MARGIN: 0px" name="myForm" method="post" onsubmit="validate('<%=requiredMsg%>');">
  <!-- Post to the supplied URL. -->
  <input type="hidden" name="requestUrl" value="<%=returnUrl%>">
  <input type="hidden" name="cancelUrl" value="<%=cancelUrl%>">
  <table cellspacing="0" cellpadding="0" width="100%" summary="" border="0">
    <tr>
      <td>
        <table cellspacing="2" cellpadding="0" width="100%" summary="" border="0">
          <tr>
            <td valign="top"><img alt="<%=FND_ORACLE_LOGO%>" src=
"/OA_MEDIA/FNDSSCORP.gif" border="0"></td>
          </tr>
          <tr>
            <td valign="bottom"><img alt="<%=FND_EBIZ_SUITE%>" src=<%=getImageSize(imageSize, "/OA_MEDIA/FNDOAPPBRAND.gif")%> border="0"></td>
          </tr>
        </table>
      </td>
      <td>
        <table cellspacing="0" cellpadding="0" summary="" border="0">
          <tr>
            <td valign="bottom"><!-- Start:globalButton -->
            </td>
          </tr>
        </table>
      </td>
    </tr>
    <tr>
      <td width="100%" colspan="2">
        <!-- globalHeader-->
        <table summary="" cellspacing="0" cellpadding="0" width="100%" border="0">
          <tr>
            <td>
              <table summary="" cellspacing="0" cellpadding="0" width="100%" border="0">
                <tr>
                  <td class="x1" colspan="3"><img src="/OA_MEDIA/fnd_t.gif" alt=""
width="1" height="4"></td>
                </tr>
                <tr>
                  <td class="x1" width="40">&nbsp;</td>
                  <td class="x1" width="90%"><span class="x1i"><%=changePwdStr%></span></td>
                  <td class="x1">&nbsp;</td>
                </tr>
                <tr>
                  <td class="x1" colspan="3"><img src="/OA_MEDIA/fnd_t.gif" alt=""
width="1" height="4"></td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td>
              <table summary="" cellspacing="0" cellpadding="0" width="100%" border="0">
                <tr>
                  <td valign="top" rowspan="2">
                    <table summary="" cellspacing="0" cellpadding="0" border="0">
                      <tr>
                        <td class="x1" valign="top"><img alt="" src=<%=getImageDir(dir, "/OA_MEDIA/fndsl.gif")%>
     border="0" valign="top"></td>
                      </tr>
                    </table>
                  </td>
                  <td valign="top" rowspan="2">&nbsp;</td>
                  <td valign="top" width="100%">
                    <table summary="" cellspacing="4" cellpadding="1" border="0">
                      <tr>
                        <td> </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
  <!-- confirm/error message -->
  <% if (errMsg!=null && !errMsg.trim().equals("")) { %>
  <TABLE summary="" BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">
    <TR>
      <TD WIDTH="6%">&nbsp;</TD>
      <TD><SPAN CLASS="OraErrorHeader"><%=errorStr%> </SPAN> <SPAN CLASS="x10"><%=errMsg%><BR>
        </SPAN ></TD>
    </TR>
    <TR>
      <td colspan="3"><script type="text/javascript">t('12')</script>
      </td>
    </TR>
  </TABLE>
  <% } else if (confirmMsg!=null && !confirmMsg.trim().equals("")) { %>
  <TABLE summary="" BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%" >
    <TR>
      <TD WIDTH="6%">&nbsp;</TD>
      <TD><SPAN CLASS="confirmHeader"><%=confirmStr%></font> : </SPAN> <SPAN CLASS="confirmText"><%=confirmMsg%><BR>
        </SPAN ></TD>
    </TR>
    <TR>
      <td colspan="3"><script type="text/javascript">t('12')</script>
      </td>
    </TR>
  </TABLE>
  <% }
     // out.println("errCode : " + errCode);
     if (!"FND_PASSWORD_NOT_CHANGEABLE".equals(errCode)  &&
         !"FND_SESSION_DOESNT_EXIST".equals(errCode)) {
  %>
  <!-- Start:Content -->
  <table summary="" cellspacing="0" cellpadding="0" width="100%" border="0">
    <tr>
      <td class="x14" width="100%"><%=changePwdStr%></td>
    </tr>
    <tr>
      <td class="x9"></td>
    </tr>
  </table>
  <table summary="" cellspacing="0" cellpadding="0" summary="" border="0">
  <tr>
    <td nowrap align=<%=end%>><!-- Start:messagePrompt -->
      <span class="x3s" title="<%=FND_REQUIRED%>">*</span></td>
    <td></td>
    <td nowrap><span class="xx"><%=FND_SSO_REQUIRED%></span></td>
  </tr>
  </table>
  <table summary="" cellspacing="0" cellpadding="0" width="100%" border="0">
    <tr>
      <td width="100%"></td>
      <td nowrap></td>
    </tr>
  </table>
  <table summary="" cellspacing="0" cellpadding="0" border="0">
    <tr>
      <td width="5%"><script>t('12')</script>
      </td>
      <td valign="top">
        <table summary="" cellspacing="0" cellpadding="0" border="0">
          <tr>
            <td nowrap align=<%=end%>><span class="xd"><span class="x3s"
      title="<%=FND_REQUIRED%>">*</span><label for="password"><%=cPwdStr%></label></span></td>
            <td width="12"><script type="text/javascript">t('12')</script>
            </td>
            <td nowrap>
              <input type="password" class="xh" id="password" onchange="" size="20" name="password">
            </td>
          </tr>
          <tr>
            <td height="3"></td>
            <td></td>
            <td></td>
          </tr>
          <tr>
            <td nowrap align=<%=end%>><span class="xd"><span class="x3s"
      title="<%=FND_REQUIRED%>">*</span><label for="newPassword"><%=nPwdStr%></label></span></td>
            <td width="12"><script type="text/javascript">t('12')</script>
            </td>
            <td nowrap>
              <input type="password" class="xh" id="newPassword" onchange="" size="20" name="newPassword">
            </td>
          </tr>
          <tr>
            <td height="3"></td>
            <td></td>
            <td></td>
          </tr>
          <tr>
            <td nowrap align=<%=end%>><span class="xd"><span class="x3s"
      title="<%=FND_REQUIRED%>">*</span><label for="newPassword2"><%=rPwdStr%></label></span></td>
            <td width="12"><script type="text/javascript">t('12')</script>
            </td>
            <td nowrap>
              <input type="password" class="xh" id="newPassword2" onchange="" size="20" name="newPassword2">
            </td>
          </tr>
          <tr>
            <td></td>
            <td width="12"><script type="text/javascript">t('12')</script>
            </td>
            <td nowrap>
              <!-- tip -->
              <% if (true) { %>
              <table cellspacing="0" cellpadding="0" width="100%" summary="" border="0">
                <tr>
                  <td valign="top"><img alt="" src="/OA_MEDIA/tipicon_status.gif"></td>
                  <td class="xw" valign="top" nowrap>TIP&nbsp;</td>
                  <td class="xy" valign="top" width="100%"><%=tipStr%></td>
                </tr>
              </table>
              <% } %>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
  <!-- contentFooter -->
  <table cellpadding="0" cellspacing="0" border="0" width="100%" summary="">
    <tr>
      <td colspan="2"><img src="/OA_MEDIA/fnd_t.gif" alt="" width="1" height="14"></td>
      <td rowspan="2"><img src=<%=getImageDir(dir, "/OA_MEDIA/fndc-skir.gif")%> alt="" width="14" height="15"></td>
    </tr>
    <tr>
      <td width="100%" colspan="2" class="x9"><img src="/OA_MEDIA/fnd_t.gif" alt=""></td>
    </tr>
    <tr>
      <td colspan="3"><img src="/OA_MEDIA/fnd_t.gif" alt="" width="1" height="5"></td>
    </tr>
    <tr>
      <td nowrap><img src="/OA_MEDIA/fnd_t.gif" alt=""></td>
      <td width="100%" align=<%=end%>>
        <!-- pageButtonBar -->
        <table cellspacing="0" cellpadding="0" summary="" border="0">
          <tr>
            <td nowrap></td>
            <td align=<%=end%> width="100%">
              <%            if (cancelUrl != null) { %>
              <input type="button" name="Cancel" title="<%=cancelStr%>" value="<%=cancelStr%>" onclick="redirect('<%=cancelUrl%>')">
              <%}else {%>
              <input type="button" name="Cancel" title="<%=cancelStr%>" value="<%=cancelStr%>">
              <%}%>
              <script>t(void 0,'5')</script>
              <input type="submit" name="Apply" title="<%=applyStr%>" value="<%=applyStr%>">
            </td>
            <td></td>
          </tr>
        </table>
      </td>
      <td></td>
    </tr>
    <tr>
      <td></td>
    </tr>
  </table>
  <% } %>
</form>
</body>
</html>
