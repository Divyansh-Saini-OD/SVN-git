// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames 
// Source File Name:   ExportReportCO.java

package od.oracle.apps.xxcrm.bis.pmv.export.webui;

import java.io.Serializable;
import javax.servlet.http.HttpSession;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.common.UserPersonalizationUtil;
import oracle.apps.bis.pmv.common.PMVConstants;
import oracle.apps.bis.pmv.common.PMVUtil;
import oracle.apps.bis.pmv.common.PmvContext;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.header.HeaderBean;
import oracle.apps.bis.pmv.session.RequestInfo;
import oracle.apps.fnd.common.Context;
import oracle.apps.fnd.common.ProfileStore;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAUrl;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.OAWebBeanFactory;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAButtonSpacerBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean;
import oracle.cabo.ui.ServletRenderingContext;
import oracle.cabo.ui.UIConstants;
import oracle.cabo.ui.beans.ProductBrandingBean;
import oracle.cabo.ui.beans.StyledTextBean;
import oracle.cabo.ui.beans.form.OptionContainerBean;
import oracle.cabo.ui.beans.layout.PageLayoutBean;
import oracle.cabo.ui.beans.nav.LinkBean;
import oracle.jbo.ApplicationModule;
import oracle.jbo.RowSet;
import oracle.jbo.Transaction;
import oracle.jbo.domain.Number;
import oracle.jbo.server.*;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;
import oracle.apps.fnd.framework.OAException;



public class ODExportReportCO extends oracle.apps.fnd.framework.webui.OAControllerImpl
{

    public void processRequest(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
     
		 CallableStatement stmt = null;

                try {
                    OADBTransaction trx = 
                        oapagecontext.getRootApplicationModule().getOADBTransaction();
                    stmt = 
			trx.createCallableStatement("begin " + "FND_Profile.Put('VO_MAX_FETCH_SIZE',coalesce(FND_PROFILE.value('XXBI_MAX_FETCH_SIZE'),60000)); "
                        + "end; ", 1);

                    stmt.execute();

                 } catch (SQLException sqlexception) {
                    System.out.println(sqlexception);
                }


   java.lang.String s = oapagecontext.getParameter("backUrl");
        if(s != null)
            oapagecontext.putSessionValue("backUrl", s);
        java.lang.String s1 = "";
        java.lang.String s2 = "";
        java.lang.String s3 = "";
        if("PORTLET".equals(oapagecontext.getParameter("pObjectType")))
        {
            s1 = oapagecontext.getParameter("title");
        } else
        {
            s2 = oapagecontext.getParameter("custRegionCode");
            s3 = oapagecontext.getParameter("custFunctionName");
            oapagecontext.getParameter("custRegionApplId");
            oracle.apps.bis.pmv.session.RequestInfo requestinfo = new RequestInfo();
            requestinfo.setParamType("SESSION");
        }
        oracle.apps.fnd.framework.OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        oracle.apps.fnd.common.WebAppsContext webappscontext = null;
        oracle.apps.bis.pmv.common.PmvContext pmvcontext = null;
        try
        {
            pmvcontext = (oracle.apps.bis.pmv.common.PmvContext)oaapplicationmodule.invokeMethod("getPmvContext");
        }
        catch(java.lang.Exception _ex) { }
        oaapplicationmodule.invokeMethod("initializePPR");
        if(pmvcontext != null)
            webappscontext = pmvcontext.getWebAppsContext();
        if(webappscontext != null)
        {
            m_WebAppsContext = webappscontext;
        } else
        {
            java.sql.Connection connection = oaapplicationmodule.getOADBTransaction().getJdbcConnection();
            m_WebAppsContext = new WebAppsContext(connection);
        }
        Object obj = null;
        if(oaapplicationmodule != null)
        {
            oracle.apps.fnd.framework.OAViewObject oaviewobject = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("ExportVO");
            if(oaviewobject != null)
                oaviewobject.executeQuery();
        }
        oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean oapagelayoutbean = oapagecontext.getPageLayoutBean();
        oracle.apps.fnd.framework.webui.beans.layout.OAButtonSpacerBean oabuttonspacerbean = (oracle.apps.fnd.framework.webui.beans.layout.OAButtonSpacerBean)createWebBean(oapagecontext, "BUTTON_SPACER");
        oracle.apps.fnd.framework.server.OADBTransaction _tmp = (oracle.apps.fnd.framework.server.OADBTransaction)oapagecontext.getApplicationModule(oawebbean).getTransaction();
        if(!"PORTLET".equals(oapagecontext.getParameter("pObjectType")))
        {
            javax.servlet.jsp.PageContext pagecontext = oracle.cabo.ui.ServletRenderingContext.getJspPageContext(oapagecontext.getRenderingContext());
            java.lang.String s4 = (java.lang.String)pagecontext.getSession().getValue("oracle.apps.bis.pmv.dynamicTitle");
            s4 = s4 != null ? s4 : oracle.apps.bis.pmv.header.HeaderBean.getTitleHTML(m_WebAppsContext, s3)[1];
            java.lang.String s7 = oracle.apps.bis.common.UserPersonalizationUtil.getViewNameSessionKey(s3, s2);
            if(oracle.apps.bis.common.ServletWrapper.getSessionValue(pagecontext, s7) != null)
            {
                java.lang.String s5 = (java.lang.String)oracle.apps.bis.common.ServletWrapper.getSessionValue(pagecontext, s7);
                s5 = " - " + s5;
                s1 = s4 + s5;
            } else
            {
                s1 = s4;
            }
        }
        oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean oaheaderbean = (oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean)oawebbean.findIndexedChildRecursive("BisPmvExportHeader");
        if(oaheaderbean != null)
        {
            oaheaderbean.setLabel(oapagecontext.getMessage("BIS", "BIS_EXPORT_REPORT", null) + " : " + s1);
            oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean oamessagestyledtextbean = (oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean)createWebBean(oapagecontext, "MESSAGE_TEXT");
            java.lang.String s6 = oapagecontext.getMessage("BIS", "BIS_EXPORT_TEXT", null);
            oamessagestyledtextbean.setText(s6);
            oamessagestyledtextbean.setCSSClass("OraFieldText");
            oaheaderbean.addIndexedChild(0, oamessagestyledtextbean);
            oaheaderbean.addIndexedChild(1, oabuttonspacerbean);
        }
        oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean oamessagechoicebean = (oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean)oawebbean.findIndexedChildRecursive("Templates");
        oamessagechoicebean.setPickListViewUsageName("TemplatesVO");
        oamessagechoicebean.setListDisplayAttribute("Name");
        oamessagechoicebean.setListValueAttribute("Code");
        oamessagechoicebean.setPickListCacheEnabled(false);
        oamessagechoicebean.setSelectedIndex(0);
        oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean oapagebuttonbarbean = (oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean)createWebBean(oapagecontext, "PAGE_BUTTON_BAR_BEAN");
        oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean oasubmitbuttonbean = (oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean)createWebBean(oapagecontext, "BUTTON_SUBMIT");
        oasubmitbuttonbean.setName("cancelButton");
        oasubmitbuttonbean.setText(oapagecontext.getMessage("BIS", "BISPMVCANCEL", null));
        oapagebuttonbarbean.addIndexedChild(oasubmitbuttonbean);
        oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean oasubmitbuttonbean1 = (oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean)createWebBean(oapagecontext, "BUTTON_SUBMIT");
        oasubmitbuttonbean1.setName("applyButton");
        oasubmitbuttonbean1.setText(oapagecontext.getMessage("BIS", "BISPMVAPPLY", null));
        oapagebuttonbarbean.addIndexedChild(oasubmitbuttonbean1);
        oapagelayoutbean.setPageButtons(oapagebuttonbarbean);
        oracle.apps.fnd.framework.webui.beans.nav.OALinkBean oalinkbean = (oracle.apps.fnd.framework.webui.beans.nav.OALinkBean)oapagecontext.getWebBeanFactory().createWebBean(oapagecontext, "LINK_BEAN");
        oalinkbean.setText(oapagecontext.getMessage("BIS", "BIS_PMV_RET_TO", null) + " " + s1);
        java.lang.StringBuffer stringbuffer = new StringBuffer(250);
        stringbuffer.append(oracle.apps.bis.pmv.common.PMVUtil.getJspUrl(oapagecontext.getProfile("APPS_SERVLET_AGENT")));
	stringbuffer.append("../XXCRM_HTML/"); 
        stringbuffer.append(oapagecontext.getSessionValue("backUrl"));
        oracle.apps.fnd.framework.webui.OAUrl oaurl = new OAUrl(stringbuffer.toString());
        java.lang.String s8 = oaurl.createURL(oapagecontext);
        oalinkbean.setDestination(s8);
        oapagelayoutbean.setReturnNavigation(oalinkbean);
        oapagelayoutbean.setWindowTitle(oapagecontext.getMessage("BIS", "BIS_EXPORT_REPORT", null));
        oracle.cabo.ui.beans.ProductBrandingBean productbrandingbean = (oracle.cabo.ui.beans.ProductBrandingBean)oapagelayoutbean.getProductBranding();
        if(productbrandingbean != null)
            productbrandingbean.setText(oapagecontext.getMessage("BIS", "BIS_EXPORT_REPORT", null));
    }

    public void processFormRequest(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        oracle.apps.fnd.framework.OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        oracle.apps.fnd.framework.server.OADBTransaction oadbtransaction = (oracle.apps.fnd.framework.server.OADBTransaction)oaapplicationmodule.getTransaction();
        try
        {
            java.lang.String s = oapagecontext.getParameter("event");
            java.lang.String s1 = oapagecontext.getParameter("BisPmvUiExportPoplist");
            if("showTemplate".equals(s))
            {
                java.lang.String s2 = oapagecontext.getParameter("custFunctionName");
                java.io.Serializable aserializable[] = {
                    s1, s2
                };
                java.lang.Class aclass[] = {
                    java.lang.String.class, java.lang.String.class
                };
                oaapplicationmodule.invokeMethod("handleTemplates", aserializable, aclass);
            }
            if(oapagecontext.getParameter("cancelButton") != null && !"".equals(oapagecontext.getParameter("cancelButton")))
            {
                oadbtransaction.rollback();
                java.lang.String s3 = getBackUrl(oapagecontext, false, null);
                oapagecontext.sendRedirect(s3);
                return;
            }
            if(oapagecontext.getParameter("applyButton") != null && !"".equals(oapagecontext.getParameter("applyButton")))
            {
                m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
                if(s1.equals("1"))
                {
                    java.lang.String s4 = getBackUrl(oapagecontext, true, "EXPORT_TO_EXCEL");
                    oapagecontext.sendRedirect(s4);
                    return;
                }
                if(s1.equals("2"))
                {
                    java.lang.StringBuffer stringbuffer = new StringBuffer(500);
                    stringbuffer.append(getBackUrlpdf(oapagecontext, true, "EXPORT_TO_PDF"));
                    java.lang.String s5 = oapagecontext.getParameter("Templates");
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s5))
                        stringbuffer.append("&templateCode=").append(s5);
                    oapagecontext.sendRedirect(stringbuffer.toString());
                    return;
                }
            }
        }
        catch(java.lang.Exception _ex) { }
    }

    public java.lang.String getBackUrl(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, boolean flag, java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(150);
        oapagecontext.getClientIANAEncoding();
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspUrl(oapagecontext.getProfile("APPS_SERVLET_AGENT")));
 stringbuffer.append("../XXCRM_HTML/");       
 stringbuffer.append(oapagecontext.getSessionValue("backUrl"));
        if(flag)
        {
            if(!"PORTLET".equals(oapagecontext.getParameter("pObjectType")))
            {
                if(oapagecontext.getParameter("sortAttribute") != null)
                    stringbuffer.append("&sortAttribute=").append(oapagecontext.getParameter("sortAttribute"));
                if(oapagecontext.getParameter("sortDirection") != null)
                    stringbuffer.append("&sortDirection=").append(oapagecontext.getParameter("sortDirection"));
            }
            if(s.equals("EXPORT_TO_PDF"))
            {
                stringbuffer.append("&pSubmit=EXPORT");
                stringbuffer.append("&fromExport=EXPORT_TO_PDF");
            } else
            {
                stringbuffer.append("&pSubmit=EXPORT");
                stringbuffer.append("&fromExport=EXPORT_TO_EXCEL");
            }
        }
        return stringbuffer.toString();
    }
 public java.lang.String getBackUrlpdf(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, boolean flag, java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(150);
        oapagecontext.getClientIANAEncoding();
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspUrl(oapagecontext.getProfile("APPS_SERVLET_AGENT")));
  
 stringbuffer.append(oapagecontext.getSessionValue("backUrl"));
        if(flag)
        {
            if(!"PORTLET".equals(oapagecontext.getParameter("pObjectType")))
            {
                if(oapagecontext.getParameter("sortAttribute") != null)
                    stringbuffer.append("&sortAttribute=").append(oapagecontext.getParameter("sortAttribute"));
                if(oapagecontext.getParameter("sortDirection") != null)
                    stringbuffer.append("&sortDirection=").append(oapagecontext.getParameter("sortDirection"));
            }
            if(s.equals("EXPORT_TO_PDF"))
            {
                stringbuffer.append("&pSubmit=EXPORT");
                stringbuffer.append("&fromExport=EXPORT_TO_PDF");
            } else
            {
                stringbuffer.append("&pSubmit=EXPORT");
                stringbuffer.append("&fromExport=EXPORT_TO_EXCEL");
            }
        }
        return stringbuffer.toString();
    }
    public ODExportReportCO()
    {
    }

    public static final java.lang.String RCS_ID = "$Header: ExportReportCO.java 115.12 2006/01/03 03:53:14 ksadagop noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ExportReportCO.java 115.12 2006/01/03 03:53:14 ksadagop noship $", "oracle.apps.bis.pmv.export.webui");
    private oracle.apps.fnd.common.WebAppsContext m_WebAppsContext;

}
