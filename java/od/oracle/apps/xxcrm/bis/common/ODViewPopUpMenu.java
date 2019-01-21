/**
+==================================================================================+
 |      Copyright (c) 2002 Oracle Corporation, Redwood Shores, CA, USA             |
 |                         All rights reserved.                                    |
 +=================================================================================+
 |  FILENAME                                                                       |
 |      ODViewPopUpMenu.java                                                         |
 |                                                                                 |
 |  DESCRIPTION                                                                    |
 |      This file encapsulates the report views popup menu   				               |
 |  HISTORY                                                                        |
 |      February 24, 2005   ksadagop   Initial Creation                            |
 |      January 02, 2007    nkishore   BugFix 5708097                              |

 +=================================================================================+
**/

package od.oracle.apps.xxcrm.bis.common;

import oracle.apps.bis.common.*;
import oracle.apps.bis.pmv.common.PMVConstants;
import oracle.apps.bis.pmv.session.UserSession;

import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.common.VersionInfo;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.Set;
import com.sun.java.util.collections.Iterator;
import oracle.cabo.share.url.EncoderUtils;
import java.io.UnsupportedEncodingException;
import oracle.apps.bis.pmv.common.StringUtil;
import od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.parameters.ParameterUtil;
import oracle.apps.bis.pmv.PMVException;
import od.oracle.apps.xxcrm.bis.components.ODComponentPageHeaderFooter;
import od.oracle.apps.xxcrm.bis.common.ODContentPopUpMenu;
import oracle.apps.bis.components.ComponentLayout;
import oracle.apps.bis.common.functionarea.PortletDefinition;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.profiles.Profiles;
import oracle.jdbc.driver.OracleStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class ODViewPopUpMenu  {

  public static final String RCS_ID="$Header: ODViewPopUpMenu.java 115.44 2007/01/30 13:34:31 nkishore noship $";
  public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.bis.common");



  // this builds the display columns array
  public static String getActionButtonHtml(UserSession userSession) {

    StringBuffer popUpMenuBuffer = new StringBuffer(500);
    WebAppsContext webAppsContext = userSession.getWebAppsContext();
    popUpMenuBuffer.append("<div id=\"VMenu1\"");
    popUpMenuBuffer.append(" class=\"viewPopUpMenu\" >");

    //Email Page
    String message = Util.escapeGTLTHTML(Util.getMessage("BIS_SEND_MAIL", webAppsContext), "");
    String jsFunc = null;
    if(!StringUtil.emptyString(webAppsContext.getProfileStore().getProfile("BIS_PMV_MAIL_LDAP_SERVER")) &&
       !StringUtil.emptyString(webAppsContext.getProfileStore().getProfile("BIS_PMV_MAIL_SMTP_SERVER")) &&
       !StringUtil.emptyString(webAppsContext.getProfileStore().getProfile("BIS_PMV_MAIL_BASE_DN")))
    {
      jsFunc = "javascript:doSubmit('EMAIL');";
      popUpMenuBuffer.append(addActionButtonView(jsFunc, message, true, null, "VMenu1", false));
    }else
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu1", false));

    //Initiate Conference
    String conferenceLink = getConferenceLink(userSession.getWebAppsContext(), null);
    message = Util.escapeGTLTHTML(Util.getMessage("BIS_INIT_CONF", webAppsContext), "");
    if(!StringUtil.emptyString(conferenceLink))
      popUpMenuBuffer.append(addActionButtonView(null, message, true, conferenceLink, "VMenu1", false));
    else
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu1", false));

    //Printable Page
    message = Util.escapeGTLTHTML(Util.getMessage("BIS_PRINTABLE_PAGE", webAppsContext), "");
    jsFunc = "javascript:doSubmit('PRINTABLE');";
    popUpMenuBuffer.append(addActionButtonView(jsFunc, message, true, null, "VMenu1", false));

    //Export Page
    message = Util.escapeGTLTHTML(Util.getMessage("BIS_EXPORT_FILE", webAppsContext), "");
    jsFunc = "javascript:doSubmit('EXPORT');";
    popUpMenuBuffer.append(addActionButtonView(jsFunc, message, true,null, "VMenu1", false));

    //Delegate
    message = Util.escapeGTLTHTML(Util.getMessage("BIS_DELEGATE", webAppsContext), "");
    boolean isDelegateEnabled = isDelegateEnabled(userSession);
    if(isDelegateEnabled)
    {
      jsFunc = "javascript:doSubmit('DELEGATION');";
      popUpMenuBuffer.append(addActionButtonView(jsFunc, message, true, null, "VMenu1", false));
    }else
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu1", false));

    popUpMenuBuffer.append(addSeparatorLine());

    // nbarik - 12/13/05 - Enhancement 4240842 - Parameter Personalization
    message = Util.escapeGTLTHTML(Util.getMessage("BIS_PERSONALIZE_PARAMETERS", webAppsContext), "");
    jsFunc = "javascript:doSubmit('PERSONALIZEPARAMETERS');";
    popUpMenuBuffer.append(addActionButtonView(jsFunc, message, true, null, "VMenu1", false));

    //Personalize Links
    message = Util.escapeGTLTHTML(Util.getMessage("BIS_PERSONALIZE_LINKS", webAppsContext), "");
    jsFunc = "javascript:doSubmit('PERSONALIZE');";
    popUpMenuBuffer.append(addActionButtonView(jsFunc, message, true, null, "VMenu1", false));

    //Reset Parameter Default Values
    message = Util.escapeGTLTHTML(Util.getMessage("BIS_RESET_PARAMS", webAppsContext), "");
    String params = "&pFirstTime=0";
    String parameters = "";
    //BugFix 5708097
    String bcFuncName = ServletWrapper.getParameter(userSession.getRequest(), "pBCFromFunctionName");
    boolean isSameReport = userSession.getFunctionName().equals(bcFuncName);

    if(!(isSameReport && StringUtil.emptyString(userSession.getDrillResetParams()))){
     // Bug 4732625--Drill Reset Parameters flow is different, get params from session
      if(!StringUtil.emptyString(userSession.getDrillResetParams())){
        parameters += userSession.getDrillResetParams();
      }else if(userSession.isDrillMode() || userSession.isResetParamDefault()){
        parameters += ParameterUtil.getDrillResetParams(userSession);
      }
    }

    String resetParamUrl = "";
    // nbarik - Bug Fix 5259409
    if(!StringUtil.emptyString(parameters) || !ODDrillUtil.canFunctionUseRFCall(userSession.getFunctionName(), webAppsContext))
      resetParamUrl = ODDrillUtil.getReportURL(userSession, parameters);
    else
      resetParamUrl = ODDrillUtil.getRunFunctionURL(userSession.getFunctionName(),params,userSession.getWebAppsContext());
    boolean isReportRun = "Y".equals(userSession.getRequestInfo().getParameterDisplayOnly());
    boolean isMessageLogReport = "BIS_BIA_MESSAGE_LOG_REPORT".equals(userSession.getFunctionName());
    if(!isReportRun) isReportRun = (userSession.getRequestInfo()!=null) && ("0".equals(userSession.getRequestInfo().getFirstTime()));
    if( (!isReportRun)
      || ( userSession.getRequestInfo()!=null && "Y".equals(userSession.getRequestInfo().getParameterDisplayOnly()))
      || isMessageLogReport)    //tmohata Bug: 4604509 Disable Reset Parameter Default Values for Debug Message Log
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu1", false));
    else{
      jsFunc = "PopUpResetItemClick('Reset', 'VMenu1','"+ resetParamUrl+ "')";
      popUpMenuBuffer.append(addActionButtonView(jsFunc, message, false, null, "VMenu1", false));
    }

    popUpMenuBuffer.append(addSeparatorLine());

    //Set As Start Page
    message = Util.escapeGTLTHTML(Util.getMessage("BIS_SET_START_PAGE", webAppsContext), "");
    Profiles prof = new Profiles(webAppsContext);
    boolean isProfile = prof.isProfileDefined("APPLICATIONS_START_PAGE");
    if(isProfile)
    {
      String resetParams = ParameterUtil.getDrillResetParams(userSession);
      String startPageUrl = ODDrillUtil.getReportURL(userSession, resetParams+"&setStartPage=Y");
      jsFunc = "PopUpResetItemClick('Reset', 'VMenu1','"+ startPageUrl+ "')";
      popUpMenuBuffer.append(addActionButtonView(jsFunc, message, false, null, "VMenu1", false));
    }else
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu1", false));

    if("Y".equals(ServletWrapper.getParameter(userSession.getPageContext(), "setStartPage")))
      saveStartPageProfileValue(userSession.getFunctionName(), webAppsContext);

    //Custom View
    String env = webAppsContext.getProfileStore().getProfile("BIS_ENVIRONMENT");
    String userType = webAppsContext.getProfileStore().getProfile("PMV_USER_TYPE");
    if("A".equals(userType) && !"PRODUCTION".equals(env))
    {
      message = Util.escapeGTLTHTML(Util.getMessage("BIS_CUST_VIEW", webAppsContext), "");
      jsFunc = "javascript:doSubmit('PERSONALIZEVIEW');";
      popUpMenuBuffer.append(addActionButtonView(jsFunc, message, true, null, "VMenu1", false));
    }

    popUpMenuBuffer.append("</div>");

    if(!StringUtil.emptyString(conferenceLink))
      popUpMenuBuffer.append(getCollabJavaScript());


    return popUpMenuBuffer.toString();
  }
  /** Add Content Enhancement
   * Form Used for submitting the DBI Page after selecting some check boxes in a functional area
   * Once mouse is clicked outside pop up bisfnare will be invoked and redirected to pRedirectUrl
   * passing selected check box values
   */
  public static String getPMVAddContentFormString(ODComponentPageHeaderFooter pageHeaderFooter, OAPageContext pageContext)
  {
    StringBuffer html = new StringBuffer(500);
    html.append("<FORM NAME=pmvAddContentForm ACTION=\"").append("/OA_HTML/bisfnare.jsp?dbc=").append(pageHeaderFooter.getDBC());
    html.append("&transactionid=").append(pageContext.getTransactionId()).append("&sessionid=").append(pageContext.getSessionId());
    html.append("\" METHOD=POST>");
    html.append("<INPUT TYPE=hidden NAME=pSubmit VALUE=\"REDIRECTPAGE\">");
    String pageURL = pageContext.getParameter("_page_url");
    if (StringUtil.emptyString(pageURL))
      pageURL = pageContext.getCurrentUrl();
    if (pageURL.indexOf("_pageid") < 0)
      pageURL = pageURL + "&_pageid=" + pageHeaderFooter.getPageId();
    html.append("<INPUT TYPE=hidden NAME=pRedirectUrl VALUE=\"").append(pageURL).append("\">");
    html.append("</FORM>");
    return html.toString();
  }

  /** Show/Hide Content Enhancement
   * Form Used for submitting the DBI Page after selecting some check boxes for some portlets
   * Once mouse is clicked outside pop up page is redirected to pRedirectUrl
   * passing selected check box values
   */
  public static String getPMVShowHideFormString(ODComponentPageHeaderFooter pageHeaderFooter, OAPageContext pageContext)
  {
    StringBuffer html = new StringBuffer(500);
    html.append("<FORM NAME=pmvShowHideForm ACTION=\"").append("/OA_HTML/bisfnare.jsp?dbc=").append(pageHeaderFooter.getDBC());
    html.append("&transactionid=").append(pageContext.getTransactionId()).append("&sessionid=").append(pageContext.getSessionId());
    html.append("\" METHOD=POST>");
    html.append("<INPUT TYPE=hidden NAME=pSubmit VALUE=\"REDIRECTPAGE\">");
    String pageURL = pageContext.getParameter("_page_url");
    if (StringUtil.emptyString(pageURL))
      pageURL = pageContext.getCurrentUrl();
    if (pageURL.indexOf("_pageid") < 0)
      pageURL = pageURL + "&_pageid=" + pageHeaderFooter.getPageId();
    html.append("<INPUT TYPE=hidden NAME=pRedirectUrl VALUE=\"").append(pageURL).append("\">");
    html.append("</FORM>");
    return html.toString();
  }


  //Actions Enhancement
  public static String getDashboardActionsHtml(ODComponentPageHeaderFooter pageHeaderFooter, OAPageContext pageContext) {

    StringBuffer popUpMenuBuffer = new StringBuffer(500);

   /** Add Content, Show Hide Content Enhancement
     * Include FORM tag for bisfnare to redirect after clicking outside Pop Up
     * passing selected check box values. PortletDisplayCols contain all selected check box values
     * HidePortletIds - portlet ids to be hidden
     */
    popUpMenuBuffer.append(getPMVAddContentFormString(pageHeaderFooter, pageContext));
    popUpMenuBuffer.append("<input type=hidden id=\"PortletDisplayCols\" name=\"PortletCols\" value=\"\">");

    popUpMenuBuffer.append(getPMVShowHideFormString(pageHeaderFooter, pageContext));
    buildShowHideInputParams(popUpMenuBuffer, pageContext, pageHeaderFooter);

    popUpMenuBuffer.append("<div id=\"VMenu1\"");
    popUpMenuBuffer.append(" class=\"viewPopUpMenu\" >");

    //Send an Email
    String message = Util.escapeGTLTHTML(pageContext.getMessage("BIS", "BIS_SEND_MAIL", null), "");
    String url = pageHeaderFooter.getEmailLink();
    if(!StringUtil.emptyString(url))
      popUpMenuBuffer.append(addActionButtonView(null, message, true, url, "VMenu1", false));
    else
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu1", false));

    //Initiate Conference
    message = Util.escapeGTLTHTML(pageContext.getMessage("BIS", "BIS_INIT_CONF", null), "");
    String conferenceLink = getConferenceLink(null, pageContext);
    if(!StringUtil.emptyString(conferenceLink))
      popUpMenuBuffer.append(addActionButtonView(null, message, true, conferenceLink, "VMenu1", false));
    else
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu1", false));

    //Export to a File
    message = Util.escapeGTLTHTML(pageContext.getMessage("BIS","BIS_EXPORT_FILE", null), "");
    url = pageHeaderFooter.getExportLink();
    popUpMenuBuffer.append(addActionButtonView(null, message, true, url, "VMenu1", false));

    //Delegate
    message = Util.escapeGTLTHTML(pageContext.getMessage("BIS", "BIS_DELEGATE", null), "");
    url = pageHeaderFooter.getDelegationLink();
    if(!StringUtil.emptyString(url))
      popUpMenuBuffer.append(addActionButtonView(null, message, true, url, "VMenu1", false));
    else
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu1", false));

    popUpMenuBuffer.append(addSeparatorLine());

    //Change Parameter Values
    message = Util.escapeGTLTHTML(pageContext.getMessage("BIS", "BIS_CHANGEPARAMETERS", null), "");
    boolean isChangeParameters = pageHeaderFooter.isChangeParameterValuesEnabled();
    String jsFunc = "javascript:redirectToChangeParameterValues()";
    if(isChangeParameters)
      popUpMenuBuffer.append(addActionButtonView(jsFunc, message, true, null, "VMenu1", false));
    else
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu1", false));


    //Add Content Enhancement
    message = Util.escapeGTLTHTML(pageContext.getMessage("BIS", "BIS_ADDCONTENT", null), "");
    jsFunc = "javascript:openFuncAreaMenu()";//"javascript:openAddContentMenu();";
    if(!StringUtil.emptyString(jsFunc)) {
      popUpMenuBuffer.append(addActionButtonView(jsFunc, message, true, null, "VMenu1", false));
    } else {
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu1", false));

    }
    //Show Hide Content
    message = Util.escapeGTLTHTML(pageContext.getMessage("BIS", "BIS_SHOWHIDE", null), "");
    jsFunc = "javascript:openShowHideMenu()";
    if(!StringUtil.emptyString(jsFunc))
      popUpMenuBuffer.append(addActionButtonView(jsFunc, message, true, null, "VMenu1", false));
    else
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu1", false));

    //Configure
    message = Util.escapeGTLTHTML(pageContext.getMessage("BIS", "BIS_CONFIGURE", null), "");
    url = pageHeaderFooter.getConfigureLink();
    if(!StringUtil.emptyString(url))
      popUpMenuBuffer.append(addActionButtonView(null, message, true, url, "VMenu1", false));
    else
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu1", false));

    popUpMenuBuffer.append(addSeparatorLine());

    //Set As Start Page
    message = Util.escapeGTLTHTML(pageContext.getMessage("BIS", "BIS_SET_START_PAGE", null), "");
    url = pageHeaderFooter.getStartPageLink();
    if(!StringUtil.emptyString(url))
      popUpMenuBuffer.append(addActionButtonView(null, message, true, url, "VMenu1", false));
    else
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu1", false));

    popUpMenuBuffer.append("</div>");
    /** Add Content Enhancement
     * Include Frame containing PopUpMenu for showing Portlets in Functional Area
     * This is enclosed inside div tag so that is a pop up menu and will refresh on click
     */
    popUpMenuBuffer.append("<div id=\"addContentMenu\" class=\"viewPopUpMenu\" style=\"z-index:2;overflow-y:auto;\">");
    popUpMenuBuffer.append("<iframe id=\"addContent\" name=\"addContent\" longdesc=\"#\" title=\"\" ");
    popUpMenuBuffer.append(" src=\"/OA_HTML/bisfnare.jsp?dbc=").append(pageHeaderFooter.getDBC());
    popUpMenuBuffer.append("&transactionid=").append(pageContext.getTransactionId()).append("&sessionid=").append(pageContext.getSessionId());
    popUpMenuBuffer.append("&pageId=").append(pageHeaderFooter.getPageId());
    popUpMenuBuffer.append("&ppFnId=").append(pageHeaderFooter.getParameterPortletFunctionId());
    popUpMenuBuffer.append("&AllPortletIds=").append(getAllPortletIds(pageHeaderFooter));
    popUpMenuBuffer.append("&firstTime=1");
    popUpMenuBuffer.append("\" scrolling=yes frameborder=no></iframe></div>");

    // Append Show/Hide popup menu html
    ODContentPopUpMenu.buildShowHidePopUpMenu(popUpMenuBuffer, pageContext, pageHeaderFooter);

    if(!StringUtil.emptyString(conferenceLink))
      popUpMenuBuffer.append(getCollabJavaScript());

    return popUpMenuBuffer.toString();
  }

  //This builds the list of views html
  public static String getListOfViewHtml(HashMap viewList, String selectedCode, WebAppsContext webAppsContext) {

    StringBuffer popUpMenuBuffer = new StringBuffer(500);
    String title = (String) webAppsContext.getSessionAttribute("header");
    int len = 0;
    if (title!=null)
      len = title.length();
    popUpMenuBuffer.append("<div id=\"VMenu0\"");
    popUpMenuBuffer.append(" class=\"viewPopUpMenu\" >");
    popUpMenuBuffer.append("<a class=\"viewPopUpMenuHeader\"  id=\"VMenu0Hdr\" HREF=\"#\" onClick=\"return;\"");
    popUpMenuBuffer.append(" onMouseOver=\"defaultCursor(this)\"");
    popUpMenuBuffer.append(" onMouseDown=\"window.location = &quot;#&quot;;\"");
    popUpMenuBuffer.append(" onKeyDown=\"window.location = &quot;#&quot;;\"");
    popUpMenuBuffer.append(" >");
    popUpMenuBuffer.append("<span class=\"viewPopUpMenuHeader\" id=\"\"");
    popUpMenuBuffer.append(" >");
    String reportViewsMsg = Util.getMessage("BIS_REPORT_VIEWS", webAppsContext);
    popUpMenuBuffer.append(reportViewsMsg).append(" ");
    len = len - reportViewsMsg.length() + 1;//Include diff len and arrow len
    if(len<0) len = 0;
    else if(len<5) len = len;
    else if(len<10) len = len - 2;
    else if(len<18) len = len - 1;
    else if(len>36) len = len + 2;
    popUpMenuBuffer.append(addSpaces(2*len));
    popUpMenuBuffer.append("</span></a>");
    if(viewList != null && viewList.size() > 0)
      popUpMenuBuffer.append(getViewListData(viewList, webAppsContext, false));
    popUpMenuBuffer.append("</div>");

    return popUpMenuBuffer.toString();

  }


  private static String addSpaces(int len)
  {
    StringBuffer spaces = new StringBuffer(250);
    for(int i=0;i<len;i++)
    {
      spaces.append("&nbsp;");
    }
    return spaces.toString();
  }
  private static String addSeparatorLine()
  {
     return " <div class=\"viewMnuItemSep\"></div> ";
     //return " <span><hr noshade color=\"lightgrey\" size=1></hr></span> ";
  }

  private static String addActionButtonView(String javaScriptFunc, String message, boolean isWindow, String url, String menu, boolean addSpace)
  {
    StringBuffer popUpMenuBuffer = new StringBuffer(500);
    String className = "viewPopUpMenuItem";
    if(addSpace) className = "viewPopUpMnuItem";
    if(!StringUtil.emptyString(javaScriptFunc)){
      //popUpMenuBuffer.append("<a class=\"").append(className).append("\" title=\"").append(message).append("\" HREF=\"#\" onClick=\"").append(javaScriptFunc).append(";\"");
      popUpMenuBuffer.append("<a class=\"").append(className).append("\" title=\"").append(message).append("\" onClick=\"").append(javaScriptFunc).append(";\"");
      if(isWindow){
        popUpMenuBuffer.append(" onMouseDown=\"window.location =&quot;").append(javaScriptFunc).append("&quot;;\"");
        popUpMenuBuffer.append(" onKeyDown=\"window.location =&quot;").append(javaScriptFunc).append("&quot;;\"");
      }else
      {
        popUpMenuBuffer.append(" onMouseDown=\"").append(javaScriptFunc).append(";\"");
        popUpMenuBuffer.append(" onKeyDown=\"").append(javaScriptFunc).append(";\"");
      }
    }else if(!StringUtil.emptyString(url)){
       popUpMenuBuffer.append("<a class=\"").append(className).append("\" title=\"").append(message).append("\" ");
       if(url.indexOf("javascript:")>=0)
         popUpMenuBuffer.append("onClick=\"").append(url).append("\"");
       else
         popUpMenuBuffer.append("onClick=\"redirectTo('").append(url).append("')\"");
       popUpMenuBuffer.append(" onMouseDown=\"return;\"");
       popUpMenuBuffer.append(" onKeyDown=\"return;\"");
    }else{
      String disableClassName = "viewPopUpMenuItemDisabled";
      if(addSpace) disableClassName = "viewPopUpMnuItemDisabled";
      popUpMenuBuffer.append("<a class=\"").append(disableClassName).append("\" title=\"").append(message).append("\" onClick=\"return;\"");
      popUpMenuBuffer.append(" onMouseDown=\"return;\"");
      popUpMenuBuffer.append(" onKeyDown=\"return;\"");
    }
    popUpMenuBuffer.append(" onMouseOver=\"viewPopupMenuItemMouseover('").append(menu).append("', this);\"");
    popUpMenuBuffer.append(" onMouseOut=\"viewPopupMenuItemMouseout('").append(menu).append("', this);\">");
    if(StringUtil.emptyString(javaScriptFunc) && StringUtil.emptyString(url))
      popUpMenuBuffer.append("<span style=\"color:#cccccc\">");
    else
      popUpMenuBuffer.append("<span>");
    if(addSpace)
      popUpMenuBuffer.append("&nbsp;&nbsp;");
    if(!StringUtil.emptyString(message) && message.length()>40)
         message = message.substring(0, 37) + "...";
    popUpMenuBuffer.append(message).append(" </span></a>");
    return popUpMenuBuffer.toString();
  }

  private static boolean isDelegateEnabled(UserSession userSession)
  {
    WebAppsContext webAppsContext = userSession.getWebAppsContext();
    String delegateProfileValue = webAppsContext.getProfileStore().getProfile("BIS_ENABLE_DELEGATE_LINK");
    if(!StringUtil.emptyString(delegateProfileValue) && "Y".equals(delegateProfileValue))
    {
      AKRegion akRegion = userSession.getAKRegion();
      String delegationParameter = akRegion.getDelegationParameter();
      String delegationParameterDim = akRegion.getDelegationParameterDim();
      AKRegionItem regionItem = null;
      String privilege = "-1";
      if(!StringUtil.emptyString(delegationParameterDim)) {
        try {
          regionItem = (AKRegionItem)akRegion.getAKRegionItems().get(delegationParameterDim);
        }
        catch(Exception e) {}
        if(regionItem != null)
          privilege = regionItem.getPrivilege();
      }
      if(!"-1".equals(privilege))
        return true;
    }
    return false;

  }

  //Actions Enhancement
  public static String getListOfViewHtml(HashMap viewList, String selectedCode, UserSession userSession) {

    StringBuffer popUpMenuBuffer = new StringBuffer(500);
    WebAppsContext webAppsContext = userSession.getWebAppsContext();
    String title = (String) webAppsContext.getSessionAttribute("header");
    boolean addSpace = false;
    int len = 0;
    if (title!=null)
      len = title.length();
    popUpMenuBuffer.append("<div id=\"VMenu0\"");
    popUpMenuBuffer.append(" class=\"viewPopUpMenu\" >");

    if(viewList != null && viewList.size() > 0){
      addSpace = isDefaultViewExists(viewList);
      popUpMenuBuffer.append(getViewListData(viewList, userSession.getWebAppsContext(), addSpace));
      popUpMenuBuffer.append(addSeparatorLine());
    }
    //Save View
    String message = Util.escapeGTLTHTML(Util.getMessage("BIS_SAVE_VIEW", webAppsContext), "");
    String jsFunc = "";
    String viewSessKey = UserPersonalizationUtil.getViewNameSessionKey(userSession.getFunctionName(),userSession.getRegionCode());

    if(userSession.getAKRegion().isEDW() || (ServletWrapper.getSessionValue(userSession.getPageContext(), viewSessKey) == null) )
    {
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu0", addSpace));
    }else{
      jsFunc = "javascript:PopUpMenuItemClick('Save', 'VMenu0');";
      popUpMenuBuffer.append(addActionButtonView(jsFunc, message, true, null, "VMenu0", addSpace));
    }

    //Save View As
    message = Util.escapeGTLTHTML(Util.getMessage("BIS_SAVE_VIEW_AS", webAppsContext), "");
    if(userSession.getAKRegion().isEDW())
    {
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu0", addSpace));
    }else{
      jsFunc = "javascript:PopUpMenuItemClick('SaveAs', 'VMenu0');";
      popUpMenuBuffer.append(addActionButtonView(jsFunc, message, true, null, "VMenu0", addSpace));
    }
    //Edit View
    message = Util.escapeGTLTHTML(Util.getMessage("BIS_EDIT_VIEW", webAppsContext), "");
    if(userSession.getAKRegion().isEDW() || (ServletWrapper.getSessionValue(userSession.getPageContext(), viewSessKey) == null) )
    {
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu0", addSpace));
    }else{
      jsFunc = "javascript:PopUpMenuItemClick('Edit', 'VMenu0');";
      popUpMenuBuffer.append(addActionButtonView(jsFunc, message, true, null, "VMenu0", addSpace));
    }
    //Delete View
    message = Util.escapeGTLTHTML(Util.getMessage("BIS_DELETE_VIEW", webAppsContext), "");
    if(userSession.isUserCustomization() && userSession.isViewExists() && !userSession.getAKRegion().isEDW()
    && (ServletWrapper.getSessionValue(userSession.getPageContext(), viewSessKey) != null))
    {
      jsFunc = "javascript:PopUpMenuItemClick('Delete', 'VMenu0');";
      popUpMenuBuffer.append(addActionButtonView(jsFunc, message, true, null, "VMenu0", addSpace));
    }else
    {
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu0", addSpace));
    }
    //Original View
    message = Util.escapeGTLTHTML(Util.getMessage("BIS_ORIGINAL_VIEW", webAppsContext), "");
    String params = "&pFirstTime=0&pResetView=Y";
    String parameters = "";

    String bcFuncName = ServletWrapper.getParameter(userSession.getRequest(), "pBCFromFunctionName");
    boolean isSameReport = userSession.getFunctionName().equals(bcFuncName);

    if(!(isSameReport && StringUtil.emptyString(userSession.getDrillResetParams()))){
      if(!StringUtil.emptyString(userSession.getDrillResetParams())){
        parameters += userSession.getDrillResetParams();
      }else if(userSession.isDrillMode() || userSession.isResetParamDefault()){
        parameters += ParameterUtil.getDrillResetParams(userSession);
      }
    }

    String resetParamUrl = "";
    if(!StringUtil.emptyString(parameters)){
      resetParamUrl = ODDrillUtil.getReportURL(userSession, parameters) + "&pResetView=Y";
    }else{
      resetParamUrl = ODDrillUtil.getRunFunctionURL(userSession.getFunctionName(),params,userSession.getWebAppsContext());
    }

    boolean isReportRun = "Y".equals(userSession.getRequestInfo().getParameterDisplayOnly());
    boolean isMessageLogReport = "BIS_BIA_MESSAGE_LOG_REPORT".equals(userSession.getFunctionName());
    if(!isReportRun) isReportRun = (userSession.getRequestInfo()!=null) && ("0".equals(userSession.getRequestInfo().getFirstTime()));
    if(userSession.getAKRegion().isEDW() || (!isReportRun)
      || ( userSession.getRequestInfo()!=null && "Y".equals(userSession.getRequestInfo().getParameterDisplayOnly()))
      || isMessageLogReport)
      popUpMenuBuffer.append(addActionButtonView(null, message, true, null, "VMenu0", false));
    else{
      jsFunc = "PopUpResetItemClick('Reset', 'VMenu0','"+ resetParamUrl+ "')";
      popUpMenuBuffer.append(addActionButtonView(jsFunc, message, false, null, "VMenu0", false));
    }


    popUpMenuBuffer.append("</div>");

    return popUpMenuBuffer.toString();

  }

   //msaran, ppalpart:5083937 - overload this method to include the condition for dashboards
   private static String getViewListData(HashMap viewList, WebAppsContext webAppsContext, boolean addSpace)
   {
     return getViewListData(viewList, webAppsContext, addSpace, false);
   }

   //msaran, ppalpart:5083937 - overridden method with the condition for dashboards
   private static String getViewListData(HashMap viewList, WebAppsContext webAppsContext,
                                         boolean addSpace, boolean isDashBoard)
   {
      StringBuffer popUpMenuBuffer = new StringBuffer(500);
      //swan project
      //if("SWAN".equals(VersionConstants.VERSION))
      //  popUpMenuBuffer.append(addSeparatorLine());
      Set attrKeys = viewList.keySet();
      Iterator it = attrKeys.iterator();
      while(it.hasNext()){
	String key = (String)it.next();
	HashMap viewData = (HashMap) viewList.get(key);
	String customViewName = (String) viewData.get(PMVConstants.CUSTOMIZATION_NAME);
	String customCode = (String) viewData.get(PMVConstants.CUSTOMIZATION_CODE);
	String defaultFlag = (String) viewData.get(PMVConstants.DEFAULT_CUSTOM_FLAG);
	String bookmarkUrl = (String) viewData.get(PMVConstants.BOOKMARK_URL);
	String decodedUrl = "";
	StringBuffer paramRedirectUrl = new StringBuffer(400);
	try {
	  String enc = webAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
	  if(!StringUtil.emptyString(bookmarkUrl))
	    decodedUrl = EncoderUtils.decodeString(bookmarkUrl,enc);
	  //msaran, ppalpart:5083937 - handle dashboard URLs differently
	  if(!isDashBoard) //need to do this append for reports only
	    paramRedirectUrl.append("/XXCRM_HTML/");
	  paramRedirectUrl.append(decodedUrl);
	  if(!isDashBoard) //need to do this append for reports only
	    paramRedirectUrl.append("&changeView=Y");
	}
	catch(UnsupportedEncodingException e) {}
	String className = "viewPopUpMenuItem";
	if(addSpace) className = "viewPopUpMnuItem";
	popUpMenuBuffer.append("<a class=\"").append(className).append("\" title=\"").append(customViewName).append("\"  href=\"#\"");
	popUpMenuBuffer.append(" onMouseOver=\"viewPopupMenuItemMouseover('VMenu0', this);\"");
	popUpMenuBuffer.append(" onMouseOut=\"viewPopupMenuItemMouseout('VMenu0', this);\"");
	popUpMenuBuffer.append(" onClick=\"redirectTo('").append(paramRedirectUrl.toString()).append("');\"");
	//popUpMenuBuffer.append(" href=\"").append(paramRedirectUrl).append("\"");
	popUpMenuBuffer.append(" id=\"").append(customCode).append("\">");
	if("Y".equals(defaultFlag))
	  popUpMenuBuffer.append("&#8226;&nbsp;");
	popUpMenuBuffer.append("<span>");
	if(addSpace && (!"Y".equals(defaultFlag)))
	  popUpMenuBuffer.append("&nbsp;&nbsp;");
	popUpMenuBuffer.append(customViewName).append("</span></a>");
      }
      return popUpMenuBuffer.toString();
   }

   private static boolean isDefaultViewExists(HashMap viewList)
   {
      if(viewList == null || viewList.size() > 0)
        return false;
      Set attrKeys = viewList.keySet();
      Iterator it = attrKeys.iterator();
      while(it.hasNext()){
        String key = (String)it.next();
        HashMap viewData = (HashMap) viewList.get(key);
        String defaultFlag = (String) viewData.get(PMVConstants.DEFAULT_CUSTOM_FLAG);
        if("Y".equals(defaultFlag)) return true;
      }
      return false;
   }

 public static String getDashboardViewsHtml(ODComponentPageHeaderFooter headerFooter, OAPageContext pageContext) {

    //msaran, ppalpart:5083937 - changed the links to show parameter view links
    StringBuffer popUpMenuBuffer = new StringBuffer(500);
    popUpMenuBuffer.append("<div id=\"VMenu0\"");
    popUpMenuBuffer.append(" class=\"viewPopUpMenu\" >");
    HashMap viewList = headerFooter.getViewData();
    if(viewList != null && viewList.size() > 0){
      boolean addSpace = isDefaultViewExists(viewList); //msaran:5482987 - add space only when default view is there
      popUpMenuBuffer.append(getViewListData(viewList, headerFooter.getWebAppsContext(), addSpace, true));
      popUpMenuBuffer.append(addSeparatorLine());
    }
    //save
    String message = Util.escapeGTLTHTML(pageContext.getMessage("BIS", "BIS_SAVE_VIEW", null), "");
    String url = headerFooter.getViewLink("Save");
    popUpMenuBuffer.append(addActionButtonView(null, message, true, url, "VMenu0", false));

    //save as
    message = Util.escapeGTLTHTML(pageContext.getMessage("BIS", "BIS_SAVE_VIEW_AS", null), "");
    url = headerFooter.getViewLink("SaveAs");
    popUpMenuBuffer.append(addActionButtonView(null, message, true, url, "VMenu0", false));

    //edit
    message = Util.escapeGTLTHTML(pageContext.getMessage("BIS", "BIS_EDIT_VIEW", null), "");
    url = headerFooter.getViewLink("Edit");
    popUpMenuBuffer.append(addActionButtonView(null, message, true, url, "VMenu0", false));

    //delete
    message = Util.escapeGTLTHTML(pageContext.getMessage("BIS", "BIS_DELETE_VIEW", null), "");
    url = headerFooter.getViewLink("Delete");
    popUpMenuBuffer.append(addActionButtonView(null, message, true, url, "VMenu0", false));

    //original
    message = Util.escapeGTLTHTML(pageContext.getMessage("BIS", "BIS_ORIGINAL_VIEW", null), "");
    url = headerFooter.getOriginalViewLink();
    popUpMenuBuffer.append(addActionButtonView(null, message, true, url, "VMenu0", false));

    popUpMenuBuffer.append("</div>");
    return popUpMenuBuffer.toString();
  }

  //End of Views Code
  public static void saveStartPageProfileValue(String functionName, WebAppsContext webAppsContext)
  {
    String respId = String.valueOf(webAppsContext.getRespId());
    String sql = " SELECT a.responsibility_key, b.application_short_name FROM fnd_responsibility a, fnd_application b WHERE a.responsibility_id=:1 AND a.application_id=b.application_id ";
    PreparedStatement ps=null;
    ResultSet rs = null;
    String respKey=null, appShortName = null;
    try{
      ps = webAppsContext.getJDBCConnection().prepareStatement(sql);
      ps.setString(1,respId);
      OracleStatement ostmt = (OracleStatement) ps;
      ostmt.defineColumnType(1, java.sql.Types.VARCHAR, 30);
      ostmt.defineColumnType(2, java.sql.Types.VARCHAR, 50);
      rs = ps.executeQuery();
      if (rs.next())
      {
        respKey = rs.getString(1);
        appShortName = rs.getString(2);
      }
    }catch(SQLException se){}
    finally
    { try{
      if(ps!=null) ps.close();
      if(rs!=null) rs.close();}catch(SQLException se){}
    }
    if(!StringUtil.emptyString(respKey) && !StringUtil.emptyString(appShortName))
    {
      String value = functionName+"$$$"+appShortName+"$$$"+respKey;
      webAppsContext.getProfileStore().saveSpecificProfile("APPLICATIONS_START_PAGE", value
                                         , "USER", String.valueOf(webAppsContext.getUserId()), null);
    }
  }

  /** Show/Hide Content--Get all portlet ids for showing up in the pop up menu
   *
   */
   public static void buildShowHideInputParams(StringBuffer popUpMenuBuffer,
                                               OAPageContext pageContext,
                                               ODComponentPageHeaderFooter pageHeaderFooter)

   {
     StringBuffer allPortlets    = new StringBuffer(200);
     StringBuffer hiddenPortlets = new StringBuffer(200);
     hiddenPortlets.append("<input type=\"hidden\" id=\"HidePortletIds\" name=\"HidePortletIds\" value=\"");
     allPortlets.append("<input type=\"hidden\" id=\"AllPortletIds\" name=\"AllPortletIds\" value=\"");

     boolean hasParameterPortlet = !StringUtil.emptyString(pageHeaderFooter.getParameterPortletFunctionId());
     //ArrayList portlets = ComponentLayout.getAllPortletNamesInPositionOrder(pageContext,      //                                                                       pageHeaderFooter);
     ArrayList portlets = pageHeaderFooter.getPortletDefinitionsInPage();
     int start = (hasParameterPortlet)?1:0;  // Do not show parameter portlet in show/hide popup

     for (int i=start; i<portlets.size(); i++)
     {
        PortletDefinition portlet = (PortletDefinition)portlets.get(i);
        String id = portlet.getId();
        String label = portlet.getLabel();
        id = (StringUtil.emptyString(id))?label:id;
        if(!StringUtil.emptyString(label))
        {
          allPortlets.append(id).append("~");
          if("N".equals(portlet.getDisplayFlag()))
            hiddenPortlets.append(id).append("~");
        }
      }
     hiddenPortlets.append("\">");
     allPortlets.append("\">");
     popUpMenuBuffer.append(hiddenPortlets.toString());
     popUpMenuBuffer.append(allPortlets.toString());

   }

   public static String getAllPortletIds(ODComponentPageHeaderFooter pageHeaderFooter)
   {
     boolean hasParameterPortlet = !StringUtil.emptyString(pageHeaderFooter.getParameterPortletFunctionId());
     int start = (hasParameterPortlet)?1:0;

     ArrayList portlets = pageHeaderFooter.getPortletDefinitionsInPage();
     StringBuffer allPortlets = new StringBuffer(150);
     for (int i=start; i<portlets.size(); i++)
     {
        PortletDefinition portlet = (PortletDefinition)portlets.get(i);
        String id = portlet.getId();
        String label = portlet.getLabel();
        id = (StringUtil.emptyString(id))?label:id;
        if(!StringUtil.emptyString(label))
        {
          allPortlets.append(id).append("~");
        }
      }
      return allPortlets.toString();
   }

   //Instant Conference--DBI Collaboration
   private static String getConferenceLink(WebAppsContext wac, OAPageContext pageContext)
   {
     String siteId    = (wac!=null)?wac.getProfileStore().getProfile("BIS_CONF_SITEID"):pageContext.getProfile("BIS_CONF_SITEID");
     String authToken = (wac!=null)?wac.getProfileStore().getProfile("BIS_CONF_AUTHTOKEN"):pageContext.getProfile("BIS_CONF_AUTHTOKEN");
     String domain    = (wac!=null)?wac.getProfileStore().getProfile("BIS_CONF_DOMAIN"):pageContext.getProfile("BIS_CONF_DOMAIN");
     String uri       = (wac!=null)?wac.getProfileStore().getProfile("BIS_CONF_URI"):pageContext.getProfile("BIS_CONF_URI");
     if(!StringUtil.emptyString(siteId) && !StringUtil.emptyString(authToken)
       && !StringUtil.emptyString(domain) && !StringUtil.emptyString(uri))
     {
       StringBuffer conferenceLink = new StringBuffer(100);
       conferenceLink.append("javascript:imtcreatemeetingex('', 'Instant Conference', '', '', '','");
       conferenceLink.append(siteId).append("','").append(authToken);
       conferenceLink.append("','").append(domain).append("','").append(uri).append("')");
       return conferenceLink.toString();
     }else
       return null;
   }
   private static String getCollabJavaScript()
   {
      StringBuffer html = new StringBuffer(100);
      html.append("<script language=\"javascript\" src=\"/OA_HTML/biscollab.js?");
      html.append(System.currentTimeMillis()).append("\"></script>");
      return html.toString();
   }

}

