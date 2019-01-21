<!-- $Header: bispmvft.jsp 115.22 2006/01/03 05:58:18 tmohata noship $ -->
<!--  Added +" " to handle pseudo translation of  strings bug 2569310 -->
<%@
  page  language="java" import="oracle.apps.fnd.common.*"
  import="oracle.apps.bis.pmv.session.UserSession"
  import="oracle.apps.bis.pmv.metadata.AKRegion"
 %>
<jsp:useBean id="globalMenuBeanFooter" class = "oracle.apps.bis.pmv.common.GlobalMenu" scope = "request" />
<%
 String currftLang = webAppsContext.getCurrLangCode();
 //ksadagop BugFix#3713252 Added the check for Printable Page.
 String submitFtMode = "";
//tmohata Bug: 4907117 Get userSession from JSPPageContext
 Object userSessionObj = pageContext.getAttribute("oracle.apps.bis.pmv.session.UserSession");
 UserSession us = null;
 if(userSessionObj != null)
  {
   us = (UserSession)userSessionObj;
  }

 if (request.getParameter("pSubmit") != null)  submitFtMode = request.getParameter("pSubmit");
 if (!"PRINTABLE".equals(submitFtMode)) {
if (customFooter.equals("")) { %>
<BODY>
  <div>
    <table width="100%" border="0" cellspacing="0" cellpadding="10">
      <tr>
        <td>
   <!--  tmohata enh: Custom Global Links For report -->

  <% globalMenuBeanFooter.initialize(webAppsContext, conn, us); %>
  <% globalMenuBeanFooter.setGlobalMenuHtml(showMenu, showHelp, true, showHeaderLinks); %>
  <%=globalMenuBeanFooter.getGlobalMenuHtml()%>
        <!--  tmohata Commented the following as global links HTML is obtained from GlobalMenuBean
          <table width="100%" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td  align=center  colspan=2 class="OraInstructionText">

              nbarik - 01/12/04 - Bug Fix 3267597

              <%
              if (!showHeaderLinks.equals("N")) {
                //jprabhud - 12/02/04 - Bug 4045191 - Do not show delegate and email links
                /*if (!StringUtil.emptyString(emailDesc) && !StringUtil.emptyString(webAppsContext.getProfileStore().getProfile("BIS_PMV_MAIL_LDAP_SERVER")) &&
 !StringUtil.emptyString(webAppsContext.getProfileStore().getProfile("BIS_PMV_MAIL_SMTP_SERVER")) &&
 !StringUtil.emptyString(webAppsContext.getProfileStore().getProfile("BIS_PMV_MAIL_BASE_DN"))) {
                */
                //if (false) {
              %>
              <!-----
                <a href="javascript:doSubmit('EMAIL');"  return true"><%=emailDesc%></a>&nbsp; |&nbsp;

              <%
                //}
              %>
              <%
                //if (!StringUtil.emptyString(exportDesc)) {
              %>
              <!-- ksadagop BugFix 3683561 Export Link added
              <a href="javascript:doSubmit('EXPORT');" return true"><%=exportDesc%></a>&nbsp; |&nbsp;

              <%
                //}
              %>
              <%
              //jprabhud - 12/02/04 - Bug 4045191 - Do not show delegate and email links
              //jprabhud - 01/04/05 - Bug 4102223 - Show delegate link as appropriate if
              //profile is set to Yes (BIS_ENABLE_DELEGATE_LINK) (BIS: Enable Delegate Link)
                //if(showDelegationLink && delegateProfileEnabled) {
              %>
              <!--
                <a href="javascript:doSubmit('DELEGATION');"  return true"><%=delegationDesc%></a>&nbsp; |&nbsp;

              <%
              //}
              %>
              <%
              if (!showMenu.equals("N")) {
              %>
                <a href="<%=menuLink%>"  return true"><%=menuDesc%></a>&nbsp;  |&nbsp;
              <%
              }
              %>

              <!--BugFix 3127915 Escape Html
                    <a href="<%=returnToPortalLink%>"  return true"><%=returnToPortalDesc%></a>&nbsp; |&nbsp;
                <a href="<%=logOutLink%>"  return true"><%=logOutDesc%></a>
                <!--
                    <a href="<%=menuLink%>"  return true"><%=menuDesc%></a>&nbsp;  |&nbsp;

              <%
                if (!showHelp.equals("N")) {
              %>
                <!--
                    <a href="<%=helpScript%>"  return true"><%=helpDesc%></a>

                &nbsp; |&nbsp;<a href="javascript:help_window();"  return true"><%=helpDesc%></a>
              <%
                }
              }
              %>
              </td>
            </tr>
            <tr>
              <td  align=center  colspan=2 class="OraInstructionText">&nbsp;</td>
            </tr>
            <!-- nbarik - 01/12/04 - Bug Fix 3267597 -->
            <!--
            <tr>
              <td  class="OraCopyright" colspan="2"><%=ODPMVUtil.getMessage("BISCPYRT",webAppsContext)+" "%></td>
            </tr>

          </table>



         end commenting out -->
        </td>
      </tr>
    </table>
    <!-- nbarik - 01/12/04 - Bug Fix 3267597 -->
    <TABLE width="100%" border="0" cellspacing="0" cellpadding="0">
      <tr>
        <td  class="OraCopyright" colspan="2"><%=Util.escapeGTLTHTML(ODPMVUtil.getMessage("BISCPYRT",webAppsContext), "")+" "%></td>
      </tr>
    </TABLE>
  </div>
</BODY>
<% } else {  %>
<%=customFooter%>
<% } %>
<% } else {  %>
<BODY>
  <div>
    <TABLE width="100%" border="0" cellspacing="0" cellpadding="0">
      <tr>
        <td  align=center  colspan=2 class="OraInstructionText">&nbsp;</td>
      </tr>
      <tr>
        <td  class="OraCopyright" colspan="2"><%=Util.escapeGTLTHTML(ODPMVUtil.getMessage("BISCPYRT",webAppsContext), "")+" "%></td>
      </tr>
    </TABLE>
  </div>
</BODY>
<% } %>