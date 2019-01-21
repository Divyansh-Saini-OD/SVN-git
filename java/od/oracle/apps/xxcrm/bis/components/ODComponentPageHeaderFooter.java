/*
 +===========================================================================+
 |      Copyright (c) 2002 Oracle Corporation, Redwood Shores, CA, USA       |he
 |                         All rights reserved.                              |
 +===========================================================================+
 |  FILENAME                                                                 |
 |      ODComponentPageHeaderFooter.java                                       |
 |  DESCRIPTION                                                              |
 |  HISTORY                                                                  |
 |   07/08/04        aleung         initial creation                         |
 |   08/23/04        smargand       Bugfix #3847511                          |
 |   01/28/05        ashgarg        Bug Fix: 4146167                         |
 |   03/23/05        ashgarg        Bug Fix: 4227468                         |
 |   05/26/05        ppalpart       Enh 3801876 (3807012)                    |
 |   05/26/05        ppalpart       Enh 3982403 (3993702)                    |
 |  07/08/04         ashgarg        bugfix: 4431819,4406737                  |
 |  07/19/05         vchahal        Enh 4268626, 4399307		                 |
 |  08/03/05         ugodavar       Bug.Fix.4525881		                       |
 |  08/31/05         ashgarg        Bug Fix: 4409116,4306413                 |
 |  10/21/05         tmohata        Bug Fix: 4686990                         |
 |  10/28/05         tmohata        Bug Fix: 4701633                         |
 |  01/03/06         ugodavar       Bug.Fix.4921868 -breadcrumbs getting lost|
 +===========================================================================+
*/
package od.oracle.apps.xxcrm.bis.components;

import java.sql.Connection;
import java.io.UnsupportedEncodingException;
import java.util.Enumeration;
import java.util.Vector;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import javax.servlet.http.HttpSession;
import javax.servlet.jsp.PageContext;

import oracle.cabo.share.url.EncoderUtils;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.framework.webui.OAUrl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.OACommonUtils;
import oracle.apps.fnd.functionSecurity.DataContext;
import oracle.apps.fnd.functionSecurity.FunctionSecurity;
import oracle.apps.fnd.functionSecurity.Function;
import oracle.apps.fnd.functionSecurity.Menu;
import oracle.apps.fnd.functionSecurity.Node;
import oracle.apps.fnd.profiles.Profiles;

import oracle.apps.bis.common.Util;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.common.ViewPopUpMenu;
import oracle.apps.bis.common.UserPersonalizationUtil;

import oracle.apps.bis.common.VersionConstants;
import oracle.apps.bis.components.ComponentSession;
import oracle.apps.bis.components.ComponentCustGlobalMenu;
import oracle.apps.bis.pmv.PMVException;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil;

import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.parameters.JavaScriptHelper;
//jprabhud - 07/15/04 - Configure Link - No Navigator Link
import oracle.apps.bis.page.webui.PageUpdateRedirectCO;
import oracle.apps.bis.service.XSLTServiceManager;
import oracle.apps.bis.common.Util;
import oracle.apps.bis.msg.MessageLog;
import oracle.apps.bis.pmv.parameters.ParameterUtil;
import od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil;
import oracle.apps.bis.common.Cache;
import oracle.apps.bis.common.FunctionalUtil;
import oracle.apps.bis.common.functionarea.FunctionalArea;
import oracle.apps.bis.common.functionarea.PortletType;
import oracle.apps.bis.common.functionarea.PortletDefinition;
import oracle.apps.bis.components.*;

import oracle.apps.fnd.sso.SSOManager;

import java.sql.Connection;

public class ODComponentPageHeaderFooter {
  public static final String RCS_ID="$Header: ODComponentPageHeaderFooter.java 115.88 2006/06/29 09:32:59 nkishore noship $";
  public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.bis.components");

  private ComponentPageInfo m_PageInfo;
  private OAPageContext m_PageContext;
  private ComponentSource m_ComponentSource;
  private WebAppsContext m_WebAppsContext;
  private Connection m_Conn;

  private String m_PageTitle;

  private String m_PLSQLAgent;
  private String m_JspAgent;
  private String m_FwkAgent;
  private String m_TransactionId;
  private String m_Dbc;
  private String m_Language;

  private String m_SiteId;
  private String m_AuthToken;
  private String m_Domain;
  private String m_URI;

  private String m_ConfigureDesc;
  private String m_HomeDesc;
  private String m_LogOutDesc;
  private String m_EmailDesc;
  private String m_ExportDesc;
  private String m_DelegationDesc;
  private String m_PrevDesc;
  private String m_NextDesc;
  private static String m_DiagnosticDesc;


  private String m_ConfigureLink;
  private String m_HomeLink;
  private String m_LogOutLink;
  private String m_EmailLink;
  private String m_ExportLink;
  private String m_DelegationLink;
  private String m_PrevLink;
  private String m_NextLink;
  private static String m_DiagnosticLink;

  private String m_Logo;
  private String m_LogoDesc;
  private String m_StartPageLink;

 //msaran, ppalpart:5083937
  private String m_CustomViewCode; //current custom code
  private String m_CustomViewName; //name of the view - user view name
  private String m_UserViewBaseLink; //base link for views page
  private String m_OriginalViewLink; //link for original view
  private HashMap m_ViewData; //list of views

//vchahal ER 4268626
  private ArrayList m_OutLinkUrl;
  private ArrayList m_OutLinkDesc;
  private ArrayList m_OutLinkImg;
  private String m_XmlPageTitle;
  private String m_ImageSource;

  private String m_FndBrandingSize;

  //ppalpart - 3982403
  private String m_HelpDesc;
  private boolean m_IsPrevNextEnabled = false;
  private boolean m_IsDelegationEnabled = false;
  //jprabhud - 01/04/05 - Bug 4102223 - Show delegate link as appropriate if
  //profile is set to Yes (BIS_ENABLE_DELEGATE_LINK) (BIS: Enable Delegate Link)
  private boolean m_DelegateProfileEnabled = false;
  private boolean m_IsConfigureEnabled = false;
  private boolean m_IsEmail = false;
  private boolean m_IsExportEnabled = false;
  private boolean m_IsExport = false;
  private boolean m_IsDesigner = false;
  // nbarik - 03/02/05 - Enhancement 4120795
  private boolean m_IsTab = false;
  private String m_DiagnosticMsgLogKey ;
  private long m_PageId;
  private MessageLog m_ComponentMsgLog                = null;
  private boolean    m_IsChangeParameterValuesEnabled = false;
  private String     m_ParameterPortletFunctionId     = null;


  public ODComponentPageHeaderFooter (ComponentPageInfo pageInfo) throws PMVException
  {
    m_PageInfo = pageInfo;
    init();   //tmohata Bug 4965541: init() should also be called for custom links

    if(!StringUtil.emptyString(m_PageInfo.getGlobalMenuName()))
     initCustomizedMenu();

    /*if (StringUtil.emptyString(m_PageInfo.getGlobalMenuName()))
    {//Bug.Fix.4525881 - added check for empty string
      init();
    }else{
      initCustomizedMenu();
    }*/
  }

 //vchahal ER 4268626

  private void initCustomizedMenu()
   {
      ComponentCustGlobalMenu gm = new ComponentCustGlobalMenu(m_PageInfo);

      m_OutLinkUrl      = gm.getOutLinkUrl();
      m_OutLinkDesc  = gm.getOutLinkDesc();

      m_FndBrandingSize =  gm.getFndBrandingSize();

      if ("REG".equals(m_FndBrandingSize))
       {
         m_OutLinkImg = gm.getOutLinkImg();
       }

      setServerInfo();

      m_ComponentSource = m_PageInfo.getComponentSource();
      m_Conn = m_PageInfo.getConection();
      m_Dbc = m_PageInfo.getDBC();
      //msaran, ppalpart:5083937 - if a custom view is present, change page title
      if(StringUtil.emptyString(m_CustomViewName))
      m_PageTitle = m_PageInfo.getPageTitle();
      else
        m_PageTitle = m_PageInfo.getPageTitle() + " - " + m_CustomViewName;

      m_XmlPageTitle = m_PageInfo.getXmlPageTitle();
      m_ImageSource = m_PageInfo.getImageSource();

      m_SiteId = m_PageContext.getProfile("BIS_CONF_SITEID");
      m_AuthToken = m_PageContext.getProfile("BIS_CONF_AUTHTOKEN");
      m_Domain = m_PageContext.getProfile("BIS_CONF_DOMAIN");
      m_URI = m_PageContext.getProfile("BIS_CONF_URI");
      //nkishore_DBILogo
      m_Logo = m_PageContext.getProfile("BIS_DBI_LOGO");


      if(StringUtil.emptyString(m_Logo))
         m_Logo = "/OA_MEDIA/FNDSSCORP.gif";
      else
         m_Logo = "/OA_MEDIA/" + m_Logo;

  }

  private void init()
  {
    setServerInfo();
    m_IsDesigner = m_PageInfo.isDesigner();
    m_IsExportEnabled = m_PageInfo.isExportEnabled();
    // nbarik - 03/02/05 - Enhancement 4120795
    m_IsTab = m_PageInfo.isTabEnabled();
    //jprabhud - 01/04/05 - Bug 4102223 - Show delegate link as appropriate if
    //profile is set to Yes (BIS_ENABLE_DELEGATE_LINK) (BIS: Enable Delegate Link)
    String delegateProfileValue = m_PageContext.getProfile("BIS_ENABLE_DELEGATE_LINK");
    if(!StringUtil.emptyString(delegateProfileValue) && "Y".equals(delegateProfileValue))
      m_DelegateProfileEnabled = true;

    //nkishore_DBILogo
    m_Logo = m_PageContext.getProfile("BIS_DBI_LOGO");
    if(StringUtil.emptyString(m_Logo))
      m_Logo = "/OA_MEDIA/FNDSSCORP.gif";
    else
      m_Logo = "/OA_MEDIA/" + m_Logo;

    if (!m_IsDesigner)
    {
      m_ComponentSource = m_PageInfo.getComponentSource();
      m_Conn = m_PageInfo.getConection();
      m_Dbc = m_PageInfo.getDBC();
      setCustomViewInfo();
      /*
     //msaran, ppalpart:5083937 - get the pCustomCode and chage the title appropriately
      m_CustomViewCode = m_PageContext.getParameter("pCustomCode"); //coming from saved view links
      if(StringUtil.emptyString(m_CustomViewCode))
        m_CustomViewCode = m_PageContext.getParameter("pCustomView"); //coming from hidden input
      if(!StringUtil.emptyString(m_CustomViewCode))
      {
        HashMap viewData = UserPersonalizationUtil.getUserLevelCustomizationData(String.valueOf(m_PageContext.getUserId()),
                                                                                 m_ComponentSource.getPageFunctionName(),
                                                                                 m_PageInfo.getConection());
        if(viewData != null)
          m_CustomViewName = UserPersonalizationUtil.getCustomViewName(viewData, m_CustomViewCode);
      }
      */
      if(StringUtil.emptyString(m_CustomViewName))
      m_PageTitle = m_PageInfo.getPageTitle();
      else
        m_PageTitle = m_PageInfo.getPageTitle() + " - " + m_CustomViewName;

      m_XmlPageTitle = m_PageInfo.getXmlPageTitle(); //vchahal
      m_FndBrandingSize = m_PageContext.getProfile("FND_BRANDING_SIZE");
      m_ImageSource = m_PageInfo.getImageSource();
      m_IsEmail = m_PageInfo.isEmail();
      m_IsExport = m_PageInfo.isExport();
      if (!(m_IsEmail || m_IsExport))
      {
        setBasicLinks();
        if (m_IsExportEnabled)
          setExportLink();

        m_IsDelegationEnabled = m_PageInfo.isDelegationEnabled();
        //BugFix 5361710
        if (m_IsDelegationEnabled && m_DelegateProfileEnabled)
          setDelegationLink();

        setDiagnosticMsgLink();
        setIsChangeParameterValuesEnabled();
      }
    }

    if(!m_IsEmail)
      setLinksDesc();
  }

  private void setCustomViewInfo() {
    String functionName = m_ComponentSource.getPageFunctionName();
    PageContext jspPageContext = m_PageContext.getRenderingContext().getJspPageContext();
    HttpSession httpSession = jspPageContext.getSession();

    m_CustomViewCode = ODPMVUtil.getDashboardCustomViewCode(m_PageContext,functionName);

    if(StringUtil.emptyString(m_CustomViewCode))  {
      return;
    }

    HashMap viewData = UserPersonalizationUtil.getUserLevelCustomizationData(
                       String.valueOf(m_PageContext.getUserId()),
		       functionName,
		       m_PageInfo.getConection());
    if(viewData != null) {
      m_CustomViewName = UserPersonalizationUtil.getCustomViewName(viewData, m_CustomViewCode);
    }

  }

  private void setServerInfo()
  {
    m_PageContext = m_PageInfo.getOAPageContext();
    m_TransactionId = m_PageContext.getTransactionId();

    m_WebAppsContext = m_PageInfo.getWebAppsContext();
    m_Language = m_WebAppsContext.getCurrLangCode();

    m_PLSQLAgent = m_PageInfo.getPLSQLAgent();
    m_JspAgent = m_PageInfo.getJspAgent();
    m_FwkAgent = m_PageInfo.getFwkAgent();
    //BugFix 5357753
    if(m_FwkAgent!=null && m_FwkAgent.endsWith("/"))
      m_FwkAgent = m_FwkAgent.substring(0,m_FwkAgent.length()-1);
  }

  private void setLinksDesc()
  {
    m_HomeDesc = Util.escapeHTML(m_PageContext.getMessage("BIS", "BIS_HOME", null), "");
    m_LogOutDesc = Util.escapeHTML(m_PageContext.getMessage("BIS", "BIS_LOGOUT", null), "");
    m_EmailDesc = Util.escapeHTML(m_PageContext.getMessage("BIS", "BIS_EMAIL_PORTAL", null), "");
    m_LogoDesc = Util.escapeHTML(m_PageContext.getMessage("BIS", "BIS_PMV_ORACLE", null), "");
    m_HelpDesc = Util.escapeHTML(m_PageContext.getMessage("BIS", "BIS_HELP", null), "");

    if (m_DiagnosticMsgLogKey != null)
      m_DiagnosticDesc = Util.escapeHTML(m_PageContext.getMessage("BIS", "BIS_DIAGNOSTIC", null), "");

    if (m_IsExportEnabled)
      m_ExportDesc = Util.escapeHTML(m_PageContext.getMessage("BIS", "BIS_EXPORT_PORTAL", null), "");

    if (m_IsDelegationEnabled)
      m_DelegationDesc = Util.escapeHTML(m_PageContext.getMessage("BIS", "BIS_DELEGATE", null), "");

    if (m_IsPrevNextEnabled)
    {
      m_PrevDesc = Util.escapeHTML(m_PageContext.getMessage("BIS", "BIS_PREVIOUS", null), "");
      m_NextDesc = Util.escapeHTML(m_PageContext.getMessage("BIS", "BIS_NEXT", null), "");
    }

    if (m_IsConfigureEnabled)
      m_ConfigureDesc = Util.escapeHTML(m_PageContext.getMessage("BIS","BIS_CONFIGURE",null), "");

  }

  private void setBasicLinks()
  {
//tmohata Bug: 4701633
    setHomeLink();
    setLogoutLink();


    if (!StringUtil.emptyString(m_PrevLink) || !StringUtil.emptyString(m_NextLink))
      m_IsPrevNextEnabled = true;
    if(!StringUtil.emptyString(m_PageContext.getProfile("BIS_PMV_MAIL_LDAP_SERVER")) &&

       !StringUtil.emptyString(m_PageContext.getProfile("BIS_PMV_MAIL_SMTP_SERVER")) &&

       !StringUtil.emptyString(m_PageContext.getProfile("BIS_PMV_MAIL_BASE_DN")))

    setEmailLink();
    setConfigureLink();
    Profiles prof = new Profiles(m_WebAppsContext);
    boolean isProfile = prof.isProfileDefined("APPLICATIONS_START_PAGE");
    if(isProfile)
      setStartPageLink();

    //msaran, ppalpart:5083937 - set the view links
    setUserViewBaseLink();
    setOriginalViewLink();
    setViewData();

  }

  private void setHomeLink()    //tmohata Bug:4701633
   {
     PageContext jspPageContext = m_PageContext.getRenderingContext().getJspPageContext();
     //Fix for Bug 5046263
     boolean isPortal = false;
     if("true".equals(ServletWrapper.getSessionValue(jspPageContext, "PMV_PORTAL_HOME")))
       isPortal = true;

     StringBuffer homeLink = new StringBuffer(100);
     String portalUrl = SSOManager.getHomePageURL(m_WebAppsContext);
     if(isPortal)
       homeLink.append(m_PageContext.getProfile("APPS_PORTAL"));
     else if(!StringUtil.emptyString(portalUrl))
      homeLink.append(portalUrl);

     if(!isPortal){
       m_HomeLink = homeLink.toString();
       m_HomeLink = new OAUrl(m_HomeLink).createURL(m_PageContext);
     }else
       m_HomeLink = homeLink.toString();
   }

  private void setLogoutLink()  //tmohata Bug:4701633
   {
     StringBuffer logoutLink = new StringBuffer(100);

     FunctionSecurity fs = m_PageContext.getFunctionSecurity();
     Function func = fs.getFunction("ICX_LOGOUT");
     String webHtmlCall = func.getWebHTMLCall();

     logoutLink.append(m_JspAgent).append(webHtmlCall);
     m_LogOutLink = logoutLink.toString();

     if (m_LogOutLink.indexOf("?") >= 0)
          logoutLink.append("&menu=Y");
        else
          logoutLink.append("?menu=Y");

     m_LogOutLink = logoutLink.toString();
     m_LogOutLink = new OAUrl(m_LogOutLink).createURL(m_PageContext);
   }

  //-------------------------------------------------------
  //When passing page source name, we should always pass the base source name
  private String getPageSourceName() {
    if ( m_ComponentSource instanceof ComponentSourceUserCustomizations ) {
      return ((ComponentSourceUserCustomizations)m_ComponentSource).getBaseSourceName();
    }
    return m_ComponentSource.getSourceName();
  }


  private void setEmailLink()
  {
    StringBuffer emailLink = new StringBuffer(350);
    //BugFix 3547028 Pass function name
    emailLink.append(m_JspAgent).append("OA.jsp?akRegionCode=BISPMVEMAILINGPAGE&akRegionApplicationId=191&dbc=");
    emailLink.append(m_Dbc).append("&pageName=").append(getPageSourceName());
   // emailLink.append("&functionName=").append(m_ComponentSource.getPageFunctionName());
   //ashgarg BugFix: 4146167
   emailLink.append("&functionName=");
    try{
      emailLink.append(EncoderUtils.encodeString(m_ComponentSource.getPageFunctionName(),m_PageContext.getClientIANAEncoding()));
    } catch(UnsupportedEncodingException ue){
      emailLink.append(m_ComponentSource.getPageFunctionName());
    }
    catch(Exception ex) {
       emailLink.append(m_ComponentSource.getPageFunctionName());
    }
    emailLink.append("&sourceType=").append(m_ComponentSource.getSourceType()).append("&title=");
    try{
      emailLink.append(EncoderUtils.encodeString(m_PageTitle,m_PageContext.getClientIANAEncoding()));
    } catch(UnsupportedEncodingException ue){
      emailLink.append(m_PageTitle);
    }
    //msaran, ppalpart:5083937 - append custom code in the email link
    if(!StringUtil.emptyString(m_CustomViewCode))
      emailLink.append("&pCustomCode=").append(m_CustomViewCode);
    //ashgarg BugFix 3620033
    OAUrl urlObject = new OAUrl(emailLink.toString());
    m_EmailLink = urlObject.createURL(m_PageContext);
  }
  public String getEmailLink()

  {

    return m_EmailLink;

  }


  private void setDelegationLink()
  {
    String delegationParameter = m_ComponentSource.getDelegationParameter();
    String privilege = m_ComponentSource.getPrivilege();
    String label = m_ComponentSource.getLabel();

    StringBuffer delegationLink = new StringBuffer(350);
    delegationLink.append(m_JspAgent);
    delegationLink.append("OA.jsp?page=/oracle/apps/bis/delegations/webui/BIS_DELEGATION_LIST_PGE&dbc=");
    delegationLink.append(m_Dbc).append("&delegationParameter=");
    delegationLink.append(delegationParameter);
    //jprabhud - 02/23/04 - Pass selected value for Proxy User - Pass privilege
    delegationLink.append("&privilege=");
    try {
      delegationLink.append(EncoderUtils.encodeString(privilege,m_PageContext.getClientIANAEncoding()));
    }catch(UnsupportedEncodingException ue){
      delegationLink.append(privilege);
    }
    delegationLink.append("&label=");
    try {
      delegationLink.append(EncoderUtils.encodeString(label,m_PageContext.getClientIANAEncoding()));
    }catch(UnsupportedEncodingException ue){
      delegationLink.append(label);
    }
    delegationLink.append("&pAdmin=N");
    //ppalpart-10.Feb.2004-Added pageName and sourceType to form the URL for the Cancel button
    delegationLink.append("&pageName=").append(getPageSourceName());
    delegationLink.append("&sourceType=").append(m_ComponentSource.getSourceType()).append("&title=");
    try{
      delegationLink.append(EncoderUtils.encodeString(m_PageTitle,m_PageContext.getClientIANAEncoding()));
    }catch(UnsupportedEncodingException ue){
      delegationLink.append(m_PageTitle);
    }
    //msaran, ppalpart:5083937 - append custom code in the delegation link
    if(!StringUtil.emptyString(m_CustomViewCode))
      delegationLink.append("&pCustomCode=").append(m_CustomViewCode);

    //ashgarg BugFix 3620033
    OAUrl urlObject1 = new OAUrl(delegationLink.toString());
    m_DelegationLink = urlObject1.createURL(m_PageContext);
  }
  //Actions Enhancement

  public String getDelegationLink()

  {

    return m_DelegationLink;

  }


  private void setExportLink()
  {
    StringBuffer exportLink = new StringBuffer(350);
    //ksadagop BugFix#4432214
    /*exportLink.append(m_JspAgent).append("OA.jsp");
    //ksadagop BugFix 3678670
    exportLink.append("?file=.&dbc=").append(m_Dbc);
    exportLink.append("&transactionid=").append(m_TransactionId);
    exportLink.append("&sessionid=").append(m_WebAppsContext.getSessionId());
    exportLink.append("&akRegionCode=").append("BIS_COMPONENT_PAGE");
    exportLink.append("&akRegionApplicationId=").append("191");
    exportLink.append("&language_code=").append(m_PageContext.getParameter("language_code"));
    exportLink.append("&pageName=").append(getPageSourceName());
    exportLink.append("&sourceType=").append(m_ComponentSource.getSourceType());
    if(m_PageContext.getParameter("portalPageName") !=null)
    exportLink.append("&portalPageName=").append(m_PageContext.getParameter("portalPageName"));
    if(m_PageContext.getParameter("migratedMenu") !=null)
    exportLink.append("&migratedMenu=").append(m_PageContext.getParameter("migratedMenu"));*/
    exportLink.append(m_PageContext.getParameter("_page_url"));
    exportLink.append("&pSubmit=EXPORT");
    exportLink.append("&fromExport=EXPORT_TO_PDF");
    exportLink.append("&file=.");
    //ksadagop BugFix#4557701
    String newExportUrl = ODPMVUtil.getOAMacUrl(exportLink.toString(), m_WebAppsContext);
     //ashgarg BugFix 3620033
    OAUrl urlObject = new OAUrl(newExportUrl);
    m_ExportLink = urlObject.createURL(m_PageContext);
  }
  //Actions Enhancement

  public String getExportLink()

  {

    return m_ExportLink;

  }


  //jprabhud - 07/15/04 - Configure Link - No Navigator Link
  private void setConfigureLink() {
  //ashgarg Bug Fix: 4431819
     m_ConfigureLink = PageUpdateRedirectCO.getPageUpdateUrl(m_PageContext,m_ComponentSource.getPageFunctionName(),true,m_PageContext.getParameter("_page_url")+"&fromConfigure=Y");
    if(!StringUtil.emptyString(m_ConfigureLink))
    {
      m_IsConfigureEnabled = true;
      //ppalpart - Added the configure=Y
      //m_ConfigureLink = m_JspAgent +m_ConfigureLink+"&configure=Y";
      //remove configure=Y because of mac key issue bug 4458404
      m_ConfigureLink = m_JspAgent + m_ConfigureLink;
    }
  }
  //Actions Enhancement

  public String getConfigureLink()

  {

    return m_ConfigureLink;

  }

  //msaran, ppalpart:5083937 - if a parameter portlet is found on the page, use it's AKRegionCode and create
  //the base URL for the BISPMVUSERVIEWPAGE. The parameter portlet is always the first item of the first rack.
  private void setUserViewBaseLink()
  {
    String functionName = m_ComponentSource.getPageFunctionName();
    ArrayList rows = m_ComponentSource.getComponentRows();
    if((rows == null) || (rows.isEmpty()))
      return;
    ComponentRow row = (ComponentRow) rows.get(0);
    if(row == null)
      return;
    ComponentItem item = (ComponentItem) row.getItem(0);
    if(item == null)
      return;
    try
    {
      if("PARAMETER_PORTLET".equals(item.getItemType()))
      {
        m_UserViewBaseLink = "/OA_HTML/OA.jsp?page=/oracle/apps/bis/pmv/customize/webui/BISPMVUSERVIEWPAGE&dbc="+m_PageInfo.getDBC();
        m_UserViewBaseLink += ("&custRegionCode="+item.getReportRegionCode());
        m_UserViewBaseLink += ("&custRegionApplId="+m_ComponentSource.getAppId());
        m_UserViewBaseLink += ("&custFunctionName="+functionName);
        m_UserViewBaseLink += ("&transactionid="+m_TransactionId);
        m_UserViewBaseLink += ("&sessionid="+m_PageContext.getSessionId());
        m_UserViewBaseLink += "&pCustomCode=";
        if(!StringUtil.emptyString(m_CustomViewCode))
          m_UserViewBaseLink += m_CustomViewCode;
        m_UserViewBaseLink += ("&pageView=Y");
      }
    }
    catch(Exception e)
    {
    }
  }

  //msaran, ppalpart:5083937 - create the "Original View" link
  private void setOriginalViewLink()
  {
    String parameters = "&pOriginalView=Y";
    String functionName = m_ComponentSource.getPageFunctionName();

    m_OriginalViewLink = ODDrillUtil.getRunFunctionURL(functionName, parameters,m_WebAppsContext);
  }

  //msaran, ppalpart:5083937 - list of views
  private void setViewData()
  {
    if(m_ViewData == null)
      m_ViewData = UserPersonalizationUtil.getUserLevelCustomizationData(String.valueOf(m_WebAppsContext.getUserId()),
                                                                         m_ComponentSource.getPageFunctionName(), m_Conn);
  }

  //msaran, ppalpart:5083937 - get the viewlinks according to the viewMode passed
  public String getViewLink(String viewMode)
  {
    if(StringUtil.emptyString(m_UserViewBaseLink)) {
        return null;
    }
    // always enable save as link since we allow save view always even if
    // there is no paramters
    //Save, Edit, Delete are disabled when there is no custom code
    if(!("SaveAs".equals(viewMode)) && StringUtil.emptyString(m_CustomViewCode)) {
      return null;
    }
    return ODPMVUtil.getOAMacUrl(m_UserViewBaseLink + "&viewMode=" + viewMode, m_WebAppsContext);
  }

  //msaran, ppalpart:5083937
  public String getOriginalViewLink()
  {
    return m_OriginalViewLink;
  }

  //msaran, ppalpart:5083937
  public HashMap getViewData()
  {
    return m_ViewData;
  }

  private void setStartPageLink()

  {

    String parameters = "&setStartPage=Y";

    String functionName = m_ComponentSource.getPageFunctionName();

    if("Y".equals(m_PageContext.getParameter("setStartPage")))

      ViewPopUpMenu.saveStartPageProfileValue(functionName, m_WebAppsContext);

    m_StartPageLink = ODDrillUtil.getRunFunctionURL(functionName, parameters,m_WebAppsContext,

                                m_WebAppsContext.getRespId(), m_WebAppsContext.getRespApplId(),

                                m_WebAppsContext.getSecurityGroupID());

  }

  public String getStartPageLink()

  {

    return m_StartPageLink;

  }


  public String getHtmlHeader() throws PMVException {
    StringBuffer header = new StringBuffer(200);
    long time = System.currentTimeMillis();
    if(m_IsEmail) {
      header.append("<link rel=\"stylesheet\" href=\"").append(m_JspAgent).append("biscusto.css?").append(time).append("\" type=\"text/css\">");
      if ("AR".equals(m_Language) || "IW".equals(m_Language))
        header.append("<link rel=\"stylesheet\" href=\"").append(m_JspAgent).append("bismarlibidi.css?").append(time).append("\" type=\"text/css\">");
      else
        header.append("<link rel=\"stylesheet\" href=\"").append(m_JspAgent).append("bismarli.css?").append(time).append("\" type=\"text/css\">");
    }

    //help script
    header.append("<SCRIPT LANGUAGE=\"JavaScript\">");
    header.append("function show_context_help(h) {");
    header.append("  newWindow = window.open(h,\"ContextHelp\", \"menubar=1,scrollbars=1,resizable=1,width=600, height=400\");");
    header.append("}\n");
    header.append("</SCRIPT>");

    header.append("<script language=\"javascript\" src=\"/OA_HTML/bismvcol.js?").append(time).append("\">").append("</script>");
    //refresh tag
    if ("Y".equals(m_PageContext.getParameter("autoRefresh")))
      header.append("<meta http-equiv=\"refresh\" content=\"").append(Util.getRefreshTime(m_WebAppsContext)).append("\">");

    //BugFix 3328682: Move static js calls to a js file -ansingh
    header.append("<script language=\"javascript\" src=\"/OA_HTML/bispmvjs.js?").append(time).append("\">").append("</script>");

    return header.toString();
  }//end of getHtmlHeader

  public String getPageHeaderXml(String pageTitle,String themes) throws PMVException {
    StringBuffer headerXml = new StringBuffer(1000);
        String output = null ;
    //ashgarg Bug Fix: 4409116
    StringBuffer header = new StringBuffer(2000);
    String baseref = null;
    String enc = m_PageContext.getClientIANAEncoding();
    long time = System.currentTimeMillis();
    //ashgarg Bug Fix: 4306413
    if(m_IsEmail)
    {
     header.append("<link rel=\"stylesheet\" href=\"").append(m_JspAgent).append("biscusto.css?").append(time).append("\" type=\"text/css\">");
     if ("AR".equals(m_Language) || "IW".equals(m_Language))
       header.append("<link rel=\"stylesheet\" href=\"").append(m_JspAgent).append("bismarlibidi.css?").append(time).append("\" type=\"text/css\">");
     else
       header.append("<link rel=\"stylesheet\" href=\"").append(m_JspAgent).append("bismarli.css?").append(time).append("\" type=\"text/css\">");
     header.append("<base href=\""+m_FwkAgent+"\" >");
    }
    //header script
    headerXml.append("<Page><PageHeader><PageTitle><Text>");
    headerXml.append(pageTitle);
    headerXml.append("</Text></PageTitle>");
    //ashgarg Bug Fix: 4306413
    if(!m_IsEmail && !m_IsTab)
    {
    headerXml.append("<PageLinks>");
//vchahal ER 4399307
    addNavigationLinks(headerXml,false,true,true);
    headerXml.append("</PageLinks>");
    }
    headerXml.append("</PageHeader></Page>");

    try {
      output = XSLTServiceManager.getInstance().getOutput(headerXml.toString(),m_PageContext.getPath()+themes+".xsl","HTML",enc);
    }
    catch(Exception ex) {
//      ex.printStackTrace();
    }
    if(m_IsEmail)
    {
      header.append(output);
      return header.toString();
    }
    else
      return output;

  }
  //ppalpart - Enh - 3982403
  //Added this new method, that would be called from ReportDesigner
  //to add the inactive links to the report Designer
  public String getReportHeaderHTML(String pageTitle) throws PMVException
  {
    StringBuffer header = new StringBuffer(1000);
    header.append(pageHeaderScript(pageTitle));
    // nbarik - 03/02/05 - Enhancement 4120795
    if(!m_IsEmail && !m_IsTab)
    {
      header.append("<SCRIPT LANGUAGE=\"JavaScript\">");
      header.append("var alignAtt;");
      header.append("if (\"" + m_Language + "\" == \"AR\" || \"" + m_Language + "\" == \"IW\") ");
      header.append("alignAtt = \"LEFT\";");
      header.append("else ");
      header.append("alignAtt = \"RIGHT\";");
      header.append("if(isNav){");
      header.append("document.write('<td align=\"' + alignAtt + '\" valign=\"bottom\" style=\"padding-bottom:8px\">');}\n");
      header.append("else {");
      header.append("document.write('<td align=\"' + alignAtt + '\" valign=\"bottom\" style=\"position:relative;z-index:10;padding-bottom:8px\">');}\n");
      header.append("</SCRIPT>");
      header.append("<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"> ");
      header.append("<tr>");
      addLinksToReportDesigner(header,false,false);
      header.append("</tr></table></td></tr>");
    }
    header.append(pageHeaderScriptTable(pageTitle));

    return header.toString();
  }
  //ppalpart - Enh - 3982403
  //Changed the method by breaking it down into two more method, as it is required to be used in
  //the getReportHeaderHTML. This method would be called for Dashboard Designer as well
  //as the normal page. The getReportHeaderHTML would be aclled only for the report Designer
  //The two new method that have been written to modularize the code are
  //1. pageHeaderScript  2. pageHeaderScriptTable
  public String getPageHeaderHtml(String pageTitle) throws PMVException
  {
    StringBuffer header = new StringBuffer(1000);
    header.append(pageHeaderScript(pageTitle));
    // nbarik - 03/02/05 - Enhancement 4120795
    if(!m_IsEmail && !m_IsTab)
    {
      header.append("<SCRIPT LANGUAGE=\"JavaScript\">");
      header.append("var alignAtt;");
      header.append("if (\"" + m_Language + "\" == \"AR\" || \"" + m_Language + "\" == \"IW\") ");
      header.append("alignAtt = \"LEFT\";");
      header.append("else ");
      header.append("alignAtt = \"RIGHT\";");
      header.append("if(isNav){");
      header.append("document.write('<td align=\"' + alignAtt + '\" valign=\"bottom\" style=\"padding-bottom:8px\">');}\n");
      header.append("else {");
      header.append("document.write('<td align=\"' + alignAtt + '\" valign=\"bottom\" style=\"position:relative;z-index:10;padding-bottom:8px\">');}\n");
      header.append("</SCRIPT>");
      header.append("<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"> ");
      header.append("<tr>");
      addNavigationLinks(header,false,false,true);
      header.append("</tr></table></td></tr>");
    }
    header.append(pageHeaderScriptTable(pageTitle));
    header.append(ParameterUtil.getScripts());
    if(isSWAN())
    {
      //use class=x5o while arcs in instead of style
      header.append(" <table style=\"background-image:url(/OA_HTML/cabo/images/swan/navBarUnderTopTabsBg.gif);background-repeat:repeat-x;height:5px\"");
      header.append(" cellpadding=\"0\" cellspacing=\"0\" border=\"0\" summary=\"\" width=\"100%\">");
      header.append("<tr><td></td></tr></table> </td></tr>");
    }

    return header.toString();
  }
  //ppalpart - Enh - 3982403
  //the first part of the getPageHeaderHTML method
  private String pageHeaderScript(String pageTitle)
  {
    StringBuffer script = new StringBuffer(1000);
    //header script
    script.append("<SCRIPT LANGUAGE=\"JavaScript\">");
    script.append("function addSpace(width,height){");
    if(isSWAN())
      script.append("document.write('<img alt=\"\" src=\"/OA_HTML/cabo/images/swan/t.gif\"');");
    else
      script.append("document.write('<img alt=\"\" src=\"/OA_HTML/cabo/images/t.gif\"');");
    script.append("if (width!=void 0)document.write(' width=\"' + width + '\"');if (height!=void 0)document.write(' height=\"' + height + '\"');");
    script.append("document.write('>');}\n");
    script.append("</SCRIPT>");
    script.append("<STYLE>body {margin-top:8px;}</STYLE>");

    //browser script
    script.append(JavaScriptHelper.IEorNavScript());

	  script.append("<tr><td>");
    String style = "";
    if(isSWAN())
      style = "style=\"background-image:url("+m_FwkAgent+"/OA_HTML/cabo/images/swan/headerBg.jpg)\"";
    script.append("<table summary=\"\" cellspacing=\"0\" cellpadding=\"0\" width=\"100%\" border=\"0\" ").append(style).append(">");

	  if ("AR".equals(m_Language) || "IW".equals(m_Language))
     script.append("<tr><td align=\"RIGHT\" nowrap valign=\"top\">");
    else
     script.append("<tr><td align=\"LEFT\" nowrap valign=\"top\">");
    //SWAN Project cellspacing-5 for bigger background image
    String cellspacing = "2";
    if(isSWAN())
      cellspacing = "4";
  	script.append("<table cellspacing=\"").append(cellspacing).append("\" cellpadding=\"0\" border=\"0\" width=\"1%\">");
    script.append("<tr>");
    if(isSWAN())
      script.append("<td></td></tr><tr><td></td></tr><tr>");

	  if (!m_IsTab) {
     //ashgarg Bug Fix: 4406737
     //swan - 134 x 23, width=\"161\" height=\"21\"
     String widthHeight = "";
     if(!isSWAN())
       widthHeight = "width=\"134\" height=\"23\"";
     else //msaran: getting report and page header in sync
       widthHeight = "width=\"155\" height=\"20\"";
      script.append("<td");
      if(isSWAN())
        script.append("></td><td nowrap vAlign=\"bottom\">");
      else
        script.append(" nowrap width=\"1%\">");
      script.append("<img src=\"").append(m_FwkAgent).append(m_Logo).append("\" alt=\"").append(m_LogoDesc).append("\" title=\"").append(m_LogoDesc).append("\" ").append(widthHeight).append(" border=\"0\">");
      if(!isSWAN())
        script.append("</td>");
    }
    if(!isSWAN())
    {
    	script.append("<td nowrap width=\"2%\">");
      script.append("<SCRIPT LANGUAGE=\"JavaScript\">");
      script.append("if(isNav){");
      script.append("document.write('<span>');}\n");
      script.append("else {");
      script.append("document.write('<span style=\"position:absolute\">');}\n");
      script.append("</SCRIPT>");
    }

    //vchahal ER 4399307 branding size if changed to Regular/Medium.

     script.append(pageHeaderBranding(pageTitle));

	  return script.toString();
  }

//vchahal ER 4399307 checks for branding size and accordingly displays the product logo

  private String pageHeaderBranding(String pageTitle)
  {
     StringBuffer brand = new StringBuffer(1000);

   if (("REG".equals(m_FndBrandingSize) || "MED".equals(m_FndBrandingSize)) && !StringUtil.emptyString(m_ImageSource))
   {
	     brand.append("<tr><td valign=\"top\" nowrap>");
	     brand.append("<img alt=\"\" src=\"").append(m_FwkAgent).append("/OA_MEDIA/");
	     if ("REG".equals(m_FndBrandingSize))
	     brand.append(m_ImageSource);
	     else
	     brand.append(m_ImageSource.substring(0, m_ImageSource.indexOf(".gif")) + "_MED.gif");
	     brand.append("\"></span>");
	     brand.append("</td></tr>");
	     brand.append("</table></td>");
    }
   else
   {
     //SWAN Add &nbsp;'s to provide space between logo and title
     if(isSWAN())
       brand.append("<span class=\"x48\">&nbsp;");
     else
       brand.append("<span style=\"COLOR: #336699; FONT-FAMILY: Arial, Helvetica, Geneva, sans-serif; FONT-SIZE:13pt; margin-bottom:0px;font-weight:bold\">");

    //vchahal ER 4393307

    //msaran:4632610 - check for emptyString instead of null
    if (!StringUtil.emptyString(m_XmlPageTitle))
	    brand.append(Util.escapeHTML(m_XmlPageTitle, "")).append("</span>");
	  else
      brand.append(Util.escapeHTML(pageTitle, "")).append("</span>");
    //SWAN
   	if (!m_IsTab && !isSWAN())
      brand.append("<img alt=\"\" src=\"").append(m_FwkAgent).append("/OA_HTML/cabo/images/pbs.gif\"></span>");

    brand.append("<script>addSpace('0','14')</script>");
    brand.append("</td></tr>");
    brand.append("<tr><td valign=\"top\" nowrap colspan=\"2\" height=\"17\"></td></tr>");
    brand.append("</table></td>");
   }

     return brand.toString();
  }
  //ppalpart - Enh - 3982403
  //the second part of the getPageHeaderHTML method
  private String pageHeaderScriptTable(String pageTitle)
  {
	   StringBuffer table = new StringBuffer(1000);

	   table.append("<tr><td colspan=\"2\" width=\"100%\"><table cellpadding=\"0\" cellspacing=\"0\" border=\"0\" width=\"100%\">");
     table.append("<tr>");
     //ksadagop BugFix 4022923

     //SWAN
     if(!isSWAN())
     {
       table.append("<SCRIPT LANGUAGE=\"JavaScript\">");
       table.append("if (\"" + m_Language + "\" == \"AR\" || \"" + m_Language + "\" == \"IW\") ");
       table.append("document.write('<td><img src=\"").append(m_FwkAgent).append("/OA_MEDIA/biscghsr.gif\" alt=\"\" width=\"34\" height=\"8\"></td>');");
       table.append("else ");
       table.append("document.write('<td><img src=\"").append(m_FwkAgent).append("/OA_MEDIA/biscghes.gif\" alt=\"\" width=\"34\" height=\"8\"></td>');");
       table.append("document.write('<td width=\"100%\" style=\"background-image:url(").append(m_FwkAgent).append("/OA_MEDIA/biscghec.gif)\"></td>');");
       table.append("if (\"" + m_Language + "\" == \"AR\" || \"" + m_Language + "\" == \"IW\") ");
       table.append("document.write('<td><img src=\"").append(m_FwkAgent).append("/OA_MEDIA/biscgher.gif\" alt=\"\" width=\"5\" height=\"8\"></td>');");
       table.append("else ");
       table.append("document.write('<td><img src=\"").append(m_FwkAgent).append("/OA_MEDIA/biscghee.gif\" alt=\"\" width=\"5\" height=\"8\"></td>');");
       table.append("</SCRIPT>");
     }

     table.append("</tr></table></td></tr>");
     table.append("</table>");
     //by vchahal ER 4399307 to set Page Title below the blue color line
     //msaran:4632610 - check for emptyString instead of null
     if (!StringUtil.emptyString(m_XmlPageTitle))
  	 {
	     table.append("<span style=\"COLOR: #336699; FONT-FAMILY: Arial, Helvetica, Geneva, sans-serif; FONT-SIZE:13pt; margin-bottom:0px;font-weight:bold\">");
	     table.append(Util.escapeHTML(pageTitle, "")).append("</span>"); //by vchahal
  	   table.append("<tr><td class=\"OraBGAccentDark\"><img border=\"0\" width=\"100%\" height=\"1\" src=\"/OA_MEDIA/FNDINVDT.gif\" alt=\"\" title=\"\"></td></tr>\n");
     }
     table.append("</td></tr>");
     if(isSWAN())
       table.append("<tr><td>");
     long time = System.currentTimeMillis();
     if(m_IsEmail)
      table.append("<base href=\"").append(m_FwkAgent).append("\"> ");
     // nbarik - 10/07/04 - Bug Fix 3313618
     table.append("<link rel=\"stylesheet\" charset=\"UTF-8\" type=\"text/css\" href=\"/OA_HTML/");
     if ("AR".equals(m_Language) || "IW".equals(m_Language))
      table.append("bisportlbidi.css?").append(time).append("\">");
     else
      table.append("bisportl.css?").append(time).append("\">");

	   return table.toString();
  }

  public String getPageFooterHtml() throws PMVException
  {
    StringBuffer footer = new StringBuffer(1000);
    //4913539 - do not allow moving of portlets in some conditions
    String emailMode =  m_PageContext.getParameter("email");
    boolean isPortletsMovingDisabled = "Y".equals(emailMode);
    if (! isPortletsMovingDisabled ) {
      footer.append("<script>PortletRegDragEvents(\""+m_ComponentSource.getPageFunctionName()+"\")</script>");
    }

    enableProcessUserCustomizationsRequest();

    //bug:5048329
/*    if(isSWAN())
        {
        if(!m_IsEmail)
          footer.append(ODHTMLUtil.getDashboardFooter(m_PageContext));
        //tmohata bug:4768387 Show data last updated here for R12/SWAN
        footer.append("<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" bgcolor=\"#eaeff5\"><tr><td height=\"35\">&nbsp;<span class=\"OraTipText\">");
        if(m_IsEmail)
          footer.append(getPrintableLastRefreshDate(ODPMVUtil.getLastRefreshDate(m_ComponentSource.getPageFunctionName(), m_Conn, "PAGE")));
        else
          footer.append(ODPMVUtil.getLastRefreshDateString(m_ComponentSource.getPageFunctionName(), m_Conn, "PAGE"));
        footer.append("</span></td></tr></table>");
        }
*/
    // Show Views and Actions here for SWAN (non-email)
    if(!m_IsEmail && isSWAN())
      {
        footer.append(ODHTMLUtil.getDashboardFooter(m_PageContext));
      }

    // Data Last Updated date HTML
    String lastUpdateHtml = "";
    if(m_IsEmail)
      lastUpdateHtml = getPrintableLastRefreshDate(ODPMVUtil.getLastRefreshDate(m_ComponentSource.getPageFunctionName(), m_Conn, "PAGE"));
    else
      lastUpdateHtml = ODPMVUtil.getLastRefreshDateString(m_ComponentSource.getPageFunctionName(), m_Conn, "PAGE");

    // Show data last updated date
    if(isSWAN())
      {
        //tmohata bug:4768387 Show data last updated here for R12/SWAN
        footer.append("<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" bgcolor=\"#eaeff5\"><tr><td height=\"35\">&nbsp;<span class=\"OraTipText\">");
        footer.append(lastUpdateHtml);
        footer.append("</span></td></tr></table>");
      }
    else
      {
        footer.append("<br><tr><td>").append(lastUpdateHtml).append("</td></tr>");
      }

    footer.append("<table cellspacing=\"0\" cellpadding=\"0\" width=\"100%\" border=\"0\"");
    //SWAN Project add footer background
    if(isSWAN())
      footer.append(" style=\"background-image:url(").append(m_FwkAgent).append("/OA_HTML/cabo/images/swan/footerBg.gif)\"");
    footer.append(" >\n");
    footer.append("<tbody>");
    if(!isSWAN())
    {
      footer.append("<tr><td>&nbsp;</td></tr>\n");
      footer.append("<tr><td class=\"OraBGAccentDark\"><img border=\"0\" width=\"100%\" height=\"1\" src=\"/OA_MEDIA/FNDINVDT.gif\" alt=\"\" title=\"\"></td></tr>\n");
    }
    if(!m_IsEmail)
    {
      if(!isSWAN())
        footer.append(ODHTMLUtil.getDashboardFooter(m_PageContext));

      footer.append("<tr><td align=\"middle\"><table><tr>");
      //vchahal ER 4268626
      addNavigationLinks(footer, true,false,false);
      footer.append("</tr></table></td></tr>");

      footer.append("<tr><td class=\"OraInstructionText\" align=\"middle\" colspan=\"2\">");
      footer.append("<div align=\"RIGHT\"></div>");
      footer.append("</td></tr>");
    }
    else
      footer.append("<tr><td><table><tr><td>");//Bug Fix 3338265--align not middle for Emailing page

/* bug:5048329 changed position of data lst updated date for Non SWAN
    if (!m_IsDesigner)
    { //Comment this out for time being for SWAN, changes need to be from BIA End
      if(!isSWAN())
      {
        String lastUpdateHtml = "";
        if(m_IsEmail)
          lastUpdateHtml = getPrintableLastRefreshDate(ODPMVUtil.getLastRefreshDate(m_ComponentSource.getPageFunctionName(), m_Conn, "PAGE"));
        else
         lastUpdateHtml = ODPMVUtil.getLastRefreshDateString(m_ComponentSource.getPageFunctionName(), m_Conn, "PAGE");
        footer.append("<tr><td>").append(lastUpdateHtml).append("</td></tr>");
      }
    }
*/
    //ksadagop BugFix#4543515
    String copyRightDesc = Util.escapeGTLTHTML(m_PageContext.getMessage("BIS", "BISCPYRT", null), "");
    if(isSWAN())
      footer.append("<tr> <td align=\"right\" style=\"white-space:nowrap;font-family:Arial;font-size:7.5pt;color:#ffffff;text-decoration:none\">").append(copyRightDesc).append("</td></tr>");
    else
      footer.append("<tr> <td class=\"OraCopyright\">").append(copyRightDesc).append("</td></tr>");
    footer.append(" </tbody></table>");


    return footer.toString();
  }//end of getPageFooterHtml

  private void enableProcessUserCustomizationsRequest() {
    UserCustomizationsHandler handler = new UserCustomizationsHandler();

    PageContext jspPCtx = m_PageContext.getRenderingContext().getJspPageContext();
    HttpSession session = jspPCtx.getSession();

    handler.enableProcessRequest(session);
  }


  //Printable Page Enh
  public String getPageBreakHtml()
  {
    StringBuffer pageBreak = new StringBuffer(500);
    pageBreak.append("<table cellspacing=\"0\" cellpadding=\"0\" width=\"100%\" border=\"0\">\n");
    pageBreak.append("<tbody><tr><td>&nbsp;</td></tr>\n");
    pageBreak.append("<tr><td class=\"OraBGAccentDark\"><img border=\"0\" width=\"100%\" height=\"1\" src=\"/OA_MEDIA/FNDINVDT.gif\" alt=\"\" title=\"\"></td></tr>\n");
    pageBreak.append(" </tbody></table>");
    return pageBreak.toString();
  }
  private void addPrevNextLinksToHeader(StringBuffer header)
  {

    header.append("<td class=\"OraInstructionText\"> ");
    if (!StringUtil.emptyString(m_PrevLink))
    {
      header.append("<a href=\"").append(m_PrevLink).append("\" class=\"OraLinkText\" target=_top>");
      header.append("<img src=\"/OA_MEDIA/bisaprev.gif\" border=0></a>&nbsp;");
      header.append("<a href=\"").append(m_PrevLink).append("\" class=\"OraLinkText\" target=_top>");
      header.append(m_PrevDesc).append("</a>");
    }
    else
      header.append("<img src=\"/OA_MEDIA/bisdprev.gif\">&nbsp;").append(m_PrevDesc);

    header.append("</td>");
    header.append("<td>|</td><td class=\"OraInstructionText\"> ");

    if (!StringUtil.emptyString(m_NextLink))
    {
      header.append("<a href=\"").append(m_NextLink).append("\" class=\"OraLinkText\" target=_top>");
      header.append(m_NextDesc).append("</a>&nbsp;");
      header.append("<a href=\"").append(m_NextLink).append("\" class=\"OraLinkText\" target=_top>");
      header.append("<img src=\"/OA_MEDIA/bisanext.gif\" border=0>").append("</a>");
    }
    else
      header.append(m_NextDesc).append("&nbsp;<img src=\"/OA_MEDIA/bisdnext.gif\">");

    header.append("</td><td>&nbsp;</td>");
  }

  private void addNavigationLinks(StringBuffer htmlBuffer, boolean appendBar,boolean themes, boolean header)
  {
    if (m_IsDesigner)  {
            addLinksToDesigner(htmlBuffer, appendBar,themes);
    }
    else
     {
        if (StringUtil.emptyString(m_PageInfo.getGlobalMenuName()))
      addLinksToNormalPage(htmlBuffer, appendBar,themes);
	    else
	        addCustLinksToNormalPage(htmlBuffer, appendBar,themes,header);    //vchahal ER 4268626 to add customize link
    }
    //BugFix 4906649
    if(!header)
    {
      m_DiagnosticDesc =null;
      m_DiagnosticLink = null;
    }
  }


  private void addLinksToNormalPage(StringBuffer htmlBuffer, boolean appendBar,boolean themes)
  {
    if (m_IsPrevNextEnabled && !appendBar) {
      addPrevNextLinksToHeader(htmlBuffer);
    }
    /* Remove Configure, Email, Conference, Delegate, Export Links from header/footer--Actions Enhancement

    if(m_IsConfigureEnabled) {
      addActiveLink(htmlBuffer, m_ConfigureLink, m_ConfigureDesc, appendBar,themes);
    }

    //jprabhud - 12/02/04 - Bug 4045191 - Do not show delegate and email links
    //ashgarg -Enh#4128080
    if(!StringUtil.emptyString(m_PageContext.getProfile("BIS_PMV_MAIL_SMTP_SERVER")) &&
     	!StringUtil.emptyString(m_PageContext.getProfile("BIS_PMV_MAIL_LDAP_SERVER")) &&
    	!StringUtil.emptyString(m_PageContext.getProfile("BIS_PMV_MAIL_BASE_DN")))
        	addActiveLink(htmlBuffer, m_EmailLink, m_EmailDesc, appendBar,themes);

    if (m_IsConferenceEnabled) {
      addActiveLink(htmlBuffer, m_ConferenceLink, m_ConferenceDesc, appendBar,themes);
    }*/

    if (!StringUtil.emptyString(m_DiagnosticDesc)) {

      addActiveLink(htmlBuffer, m_DiagnosticLink, m_DiagnosticDesc, appendBar,themes);
    }
    /*  Remove Configure, Email, Conference, Delegate, Export Links from header/footer--Actions Enhancement

    if (m_IsExportEnabled) {
      addActiveLink(htmlBuffer, m_ExportLink, m_ExportDesc, appendBar,themes);
    }

    //jprabhud - 12/02/04 - Bug 4045191 - Do not show delegate and email links
    //jprabhud - 01/04/05 - Bug 4102223 - Show delegate link as appropriate if
    //profile is set to Yes (BIS_ENABLE_DELEGATE_LINK) (BIS: Enable Delegate Link)
    if (m_IsDelegationEnabled && m_DelegateProfileEnabled) {
      addActiveLink(htmlBuffer, m_DelegationLink, m_DelegationDesc, appendBar,themes);
    }*/



    addActiveLink(htmlBuffer, m_HomeLink, m_HomeDesc, appendBar,themes);

    addActiveLink(htmlBuffer, m_LogOutLink, m_LogOutDesc, false,themes);
  }

  private void addLinksToDesigner(StringBuffer htmlBuffer, boolean appendBar,boolean themes)
  {
    //if(!StringUtil.emptyString(m_ConfigureLink)) {
        //ppalpart - Bug Fix : 4445698
    /*

    String configureDesc = m_PageContext.getMessage("BIS","BIS_CONFIGURE",null);
    addInactiveLink(htmlBuffer, configureDesc, appendBar,themes);
    //}

    //jprabhud - 12/02/04 - Bug 4045191 - Do not show delegate and email links
    //ashgarg enh#4128080
    if(!StringUtil.emptyString(m_PageContext.getProfile("BIS_PMV_MAIL_SMTP_SERVER")) &&
    	!StringUtil.emptyString(m_PageContext.getProfile("BIS_PMV_MAIL_LDAP_SERVER")) &&
    	!StringUtil.emptyString(m_PageContext.getProfile("BIS_PMV_MAIL_BASE_DN")))
     addInactiveLink(htmlBuffer, m_EmailDesc, appendBar,themes);

    if (m_IsConferenceEnabled) {
     addInactiveLink(htmlBuffer, m_ConferenceDesc, appendBar,themes);
    }*/

    //ppalpart - Enh - 3982403
    String fndLogEnabled = m_PageContext.getProfile("AFLOG_ENABLED");
    String fndLogModule = m_PageContext.getProfile("AFLOG_MODULE");
    String bisLogEnabled = m_PageContext.getProfile("BIS_PMF_DEBUG");
    if (("Y".equals(bisLogEnabled) || "Y".equals(fndLogEnabled)) && ("BIS%").equalsIgnoreCase(fndLogModule))
    {
     String diagnosticDesc = m_PageContext.getMessage("BIS", "BIS_DIAGNOSTIC", null);
     addInactiveLink(htmlBuffer, diagnosticDesc, appendBar,themes);
    }
    /*

    if(m_IsExportEnabled) {
     addInactiveLink(htmlBuffer, m_ExportDesc, appendBar,themes);
    }*/


    addInactiveLink(htmlBuffer, m_HomeDesc, appendBar,themes);

    addInactiveLink(htmlBuffer, m_LogOutDesc, false,themes);
  }
//ppalpart - Enh - 3982403
  private void addLinksToReportDesigner(StringBuffer htmlBuffer, boolean appendBar,boolean themes)
  {
    addInactiveLink(htmlBuffer, m_HomeDesc, appendBar,themes);

    addInactiveLink(htmlBuffer, m_LogOutDesc, false,themes);

    addInactiveLink(htmlBuffer, m_HelpDesc, false,themes);
  }


  private static void addActiveLink(StringBuffer htmlBuffer, String linkURL, String linkDesc, boolean appendBar,boolean themes)
  {
    if(themes)
    {
      htmlBuffer.append("<PageLink>");
      htmlBuffer.append("<Text>").append(linkDesc).append("</Text>");
      htmlBuffer.append("<Url><![CDATA[").append(linkURL).append("]]></Url>");
      htmlBuffer.append("</PageLink>");
    }
    else {
      String className = "";
      if(isSWAN())
       className = "class=\"xy\"";
      htmlBuffer.append("<td valign=\"bottom\"><a ").append(className).append(" href=\"");
      htmlBuffer.append(linkURL);
      if(!isSWAN())
        htmlBuffer.append("\" style=\"color:#663300;font-family:Arial,Helvetica,Geneva,sans-serif;font-size:67%");
      htmlBuffer.append("\">");
      htmlBuffer.append(linkDesc).append("</a></td>");
      if (appendBar){
        if(!isSWAN())
          addVerticalBar(htmlBuffer);
      }else
        htmlBuffer.append("<td valign=\"bottom\"><script>addSpace('10','1')</script></td>");
    }

  }

    //vchahal ER 4268626 to show icons along with link

    private static void addActiveCustLink(StringBuffer htmlBuffer, String linkURL, String linkDesc, String linkImage, boolean appendBar,boolean themes)
    {

       if(themes)
    {
      htmlBuffer.append("<PageLink>");
      htmlBuffer.append("<Text>").append(linkDesc).append("</Text>");
      htmlBuffer.append("<Url><![CDATA[").append(linkURL).append("]]></Url>");
      htmlBuffer.append("</PageLink>");
    }
    else
     {
      htmlBuffer.append("<td valign=\"bottom\"><table cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr><td align=\"center\"><a href=\"");
      htmlBuffer.append(linkURL).append("\" class=\"xy\">").append("<img src = \"");
      htmlBuffer.append(linkImage).append("\" alt=").append("\"");
      htmlBuffer.append(linkDesc).append("\"").append("border=\"0\" width=\"32\" height=\"32\"></a></td></tr><tr><td align=\"center\"><a href=\"");
      htmlBuffer.append(linkURL).append("\" class=\"xy\">");
      htmlBuffer.append(linkDesc).append("</a></td></tr></table></td>");
      htmlBuffer.append("<td valign=\"bottom\"><script>addSpace('10','1')</script></td>");
     }
    }


  private static void addInactiveLink(StringBuffer htmlBuffer, String linkDesc, boolean appendBar,boolean themes)
  {
    if(themes)
    {
      htmlBuffer.append("<PageLink>");
      htmlBuffer.append("<Text>").append(linkDesc).append("</Text>");
      htmlBuffer.append("<Url>").append("").append("</Url>");
      htmlBuffer.append("</PageLink>");
    }
    else {
      if(!isSWAN())
        htmlBuffer.append("<td valign=\"bottom\" style=\"color:#663300;font-family:Arial,Helvetica,Geneva,sans-serif;font-size:67%;text-decoration:underline\">");
      else
        htmlBuffer.append("<td valign=\"bottom\" class=\"xy\">");
      htmlBuffer.append(linkDesc);
      htmlBuffer.append("</td>");
      if (appendBar){
        if(!isSWAN())
          addVerticalBar(htmlBuffer);
      }else
        htmlBuffer.append("<td valign=\"bottom\"><script>addSpace('10','1')</script></td>");
    }

  }
//tmohata Bug: 4637447
  private static void addInactiveCustLink(StringBuffer htmlBuffer, String linkDesc, boolean appendBar,boolean themes)
    {
  if(themes)
    {
      htmlBuffer.append("<PageLink>");
      htmlBuffer.append("<Text>").append(linkDesc).append("</Text>");
      htmlBuffer.append("<Url>").append("").append("</Url>");
      htmlBuffer.append("</PageLink>");
    }
    else {
      htmlBuffer.append("<td valign=\"bottom\"><span class=\"xz\">");
      htmlBuffer.append(linkDesc);
      htmlBuffer.append("</td>");
      if (appendBar){
        if(!isSWAN())
          addVerticalBar(htmlBuffer);
      }else
        htmlBuffer.append("<td valign=\"bottom\"><script>addSpace('10','1')</script></td>");
       }
    }

  private static void addVerticalBar(StringBuffer htmlBuffer)
  {
    htmlBuffer.append("<td>&nbsp;|&nbsp;</td>");
  }

  public void setPrevLink(String link) { m_PrevLink = link; }
  public void setNextLink(String link) { m_NextLink = link; }

  public void setDiagnosticLogKey  (String diagMsgLogKey) {
    if (diagMsgLogKey != null) {
      m_DiagnosticMsgLogKey = diagMsgLogKey;
      m_DiagnosticDesc = m_PageContext.getMessage("BIS", "BIS_DIAGNOSTIC", null);
      setDiagnosticMsgLink();
    }
  }

  private void setDiagnosticMsgLink(){
     if (m_DiagnosticMsgLogKey != null) {
       StringBuffer htmlBuffer = new StringBuffer(80);
       htmlBuffer.append(m_JspAgent)
                      .append("OA.jsp?akRegionCode=BISMSGLOGPAGE&akRegionApplicationId=191&dbc=")
                      .append (m_Dbc)
                      .append("&transactionid=").append(m_TransactionId)
                      .append("&LogicalName=Diag")
                      .append("&ObjectKey=" + m_DiagnosticMsgLogKey) ;
      m_DiagnosticLink = htmlBuffer.toString();
    }
  }
  //BugFix 4159963
  private String getPrintableLastRefreshDate(String date)
  {

      //htmlBuffer.append("<span class=\"OraTipText\">");
      //ashish Bug Fix: 5020363
      if(!StringUtil.emptyString(date)){
         StringBuffer htmlBuffer = new StringBuffer(350);
        htmlBuffer.append("<span class=\"OraTipText\">");
        htmlBuffer.append(Util.escapeHTML(date, ""));
        htmlBuffer.append("</span>");
        return htmlBuffer.toString();
      }
      else
      {
        return "";
      }

    /* if(StringUtil.emptyString(date)){
        htmlBuffer.append(Util.escapeHTML(m_PageContext.getMessage("BIS", "BIS_PMV_LAST_UPDATE_ERR", null), ""));
      }else
      {
      //ashgarg BugFix: 4227468
        //htmlBuffer.append(m_PageContext.getMessage("BIS", "BIS_BIA_PMV_RFH_DATE_API_MSG", null));
        htmlBuffer.append(Util.escapeHTML(date, ""));
      }*/


  }

  //vchahal ER 4268626

    private void addCustLinksToNormalPage(StringBuffer htmlBuffer, boolean appendBar,boolean themes, boolean header)
     {
             Object m_OutLinkArray[] = m_OutLinkUrl.toArray();
             Object m_OutDescArray[] = m_OutLinkDesc.toArray();

             for (int i=0; i<m_OutLinkArray.length; i++)
              {
               String m_OutLinkString = (String)m_OutLinkArray[i];
               String m_OutDescString   = (String)m_OutDescArray[i];

               if ("REG".equals(m_FndBrandingSize))
                {
                      Object m_OutImgArray[] = m_OutLinkImg.toArray();
                      String m_OutImageString = (String)m_OutImgArray[i];

                    if (header)  //tmohata Bug: 4686990
                     {
                      if(!StringUtil.emptyString(m_OutLinkString) && !StringUtil.emptyString(m_OutImageString))    //Case 1: Render enabled global link if image exists
                         { addActiveCustLink(htmlBuffer, m_OutLinkString, m_OutDescString, m_OutImageString, appendBar,themes); }
                      else if(!StringUtil.emptyString(m_OutLinkString) && StringUtil.emptyString(m_OutImageString)) //Case 2: Render enabled global link without image
                         { addActiveLink(htmlBuffer, m_OutLinkString, m_OutDescString, appendBar,themes); }
                      else if(StringUtil.emptyString(m_OutLinkString) && !StringUtil.emptyString(m_OutDescString))  //Case 3: Render disabled global link (eg. Pointing to the same page) without image
                         { addInactiveCustLink(htmlBuffer, m_OutDescString, appendBar, themes); }
                     }
                    else
                     {
                      if(StringUtil.emptyString(m_OutLinkString) && !StringUtil.emptyString(m_OutDescString))
                        addInactiveCustLink(htmlBuffer,m_OutDescString,appendBar,themes);
                      else
                        addActiveLink(htmlBuffer, m_OutLinkString, m_OutDescString, appendBar,themes);
                     }
                }
               else
                 {
                   //tmohata Bug: 4637447
                  if(StringUtil.emptyString(m_OutLinkString) && !StringUtil.emptyString(m_OutDescString))
                    addInactiveCustLink(htmlBuffer,m_OutDescString,appendBar,themes);
                  else
                    addActiveLink(htmlBuffer, m_OutLinkString, m_OutDescString, appendBar,themes);
               }

              }
     }

     public static boolean isSWAN()
     {
       return "SWAN".equals(VersionConstants.VERSION);
     }
     public void setIsChangeParameterValuesEnabled()
     {
       try{
         ArrayList rows =  m_PageInfo.getComponentSource().getComponentRows();
         if(rows.size()>0)
         {
           ComponentRow row = (ComponentRow)rows.get(0);
           if(row!=null)
           {
             ArrayList items = row.getComponentItems();
             for(int i=0;i<items.size();i++)
             {
               ComponentItem item = (ComponentItem)items.get(i);
               if(item!=null && ComponentConstants.PARAMETER_PORTLET.equals(item.getItemType()))
                 m_ParameterPortletFunctionId = item.getFunctionId();
               if(item!=null &&  ComponentConstants.PARAMETER_PORTLET.equals(item.getItemType()) &&
                  !("".equals(item.getCustomizeRegionCode()) || item.getCustomizeRegionCode()==null) &&
                  !("".equals(item.getCustomizeApplicationId()) || item.getCustomizeApplicationId() == null))
               {
                  m_IsChangeParameterValuesEnabled = true;
                  return;
               }
             }
           }
         }
       }catch(Exception e){}
       m_IsChangeParameterValuesEnabled = false;
     }

     public boolean isChangeParameterValuesEnabled()
     {
       return m_IsChangeParameterValuesEnabled;
     }

      /**Add Content Enhancement--Include dbc, webAppsContext, MessageLog, pageId
      * to pass it to Actions Pop Up Menu, for building Functional Area Pop Up
      */
     public String getDBC()
     {
       return m_Dbc;
     }
     public WebAppsContext getWebAppsContext()
     {
       return m_WebAppsContext;
     }
     public long getPageId()
     {
       return m_PageInfo.getComponentSource().getPageId();
     }
     public MessageLog getMessageLog()
     {
       return m_ComponentMsgLog;
     }
     public String getParameterPortletFunctionId()
     {
       return m_ParameterPortletFunctionId;
     }
     //Show Hide Content Enhancement
     public ComponentSource getComponentSource()
     {
       return m_ComponentSource;
     }

    //----------------------------------------------------------------------------
    //This method returns list of PortletDefinition objects based on all
    //ComponentItems in the page, the order in the list is:
    //from top to bottom rack, for each rack, from left to right.
    public ArrayList getPortletDefinitionsInPage() {

      ArrayList portletDefinitions = new ArrayList(19);
      ComponentSource cs = getComponentSource();
      ArrayList items = cs.getAllComponentItems();
      for (int i = 0; i < items.size(); i++) {
        ComponentItem item = (ComponentItem)items.get(i);
        String dispFlag = (item.isVisible())?"Y":"N";
        PortletDefinition portlet = new PortletDefinition(item.getFunctionId(),
							  item.getTitle(),
    						  	  dispFlag);
        portletDefinitions.add(portlet);
      }
      return portletDefinitions;
    }
}