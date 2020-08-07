// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODUserViewCO.java

package od.oracle.apps.xxcrm.bis.pmv.customize.webui;

import oracle.apps.bis.pmv.customize.webui.*;
import com.sun.java.util.collections.ArrayList;
import java.io.IOException;
import java.io.Serializable;
import java.io.UnsupportedEncodingException;
import java.sql.Connection;
import java.sql.SQLException;
import javax.servlet.http.HttpSession;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.common.UserPersonalizationUtil;
import oracle.apps.bis.common.Util;
import oracle.apps.bis.pmv.PMVException;
import oracle.apps.bis.pmv.common.PMVConstants;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.customize.common.CustomViewHelper;
import oracle.apps.bis.pmv.customize.common.CustomViewUtil;
import od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.session.RequestInfo;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.AppsContext;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.custom.CustomizationConstants;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.webui.AttributeSet;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAUrl;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.cabo.share.url.EncoderUtils;
import oracle.cabo.ui.ServletRenderingContext;
import oracle.cabo.ui.beans.BaseWebBean;
import oracle.cabo.ui.beans.ProductBrandingBean;
import oracle.cabo.ui.beans.form.CheckBoxBean;
import oracle.cabo.ui.beans.form.FormElementBean;
import oracle.cabo.ui.beans.form.TextInputBean;
import oracle.cabo.ui.beans.layout.PageLayoutBean;
import oracle.jbo.ApplicationModule;
import oracle.jbo.AttributeList;
import oracle.jbo.RowIterator;
import oracle.jbo.RowSet;
import oracle.jbo.Transaction;
import oracle.jbo.domain.Number;

public class ODUserViewCO extends oracle.apps.fnd.framework.webui.OAControllerImpl
    implements oracle.apps.fnd.framework.custom.CustomizationConstants
{

    public void processRequest(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        oapagecontext.activateWarnAboutChanges();
        java.lang.String s = oapagecontext.getParameter("custRegionCode");
        java.lang.String s1 = oapagecontext.getParameter("custFunctionName");
        viewMode = oapagecontext.getParameter("viewMode");
        m_IsPageView = "Y".equals(oapagecontext.getParameter("pageView"));
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(viewMode))
            viewMode = (java.lang.String)oapagecontext.getSessionValue("viewMode");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(viewMode))
            oapagecontext.putSessionValue("viewMode", viewMode);
        setBookmarkUrl(oapagecontext);
        customizationCode = oapagecontext.getParameter("pCustomCode");
        m_ViewByAttrValue = oapagecontext.getParameter("pViewBy");
        setWebAppsContext(oapagecontext, oawebbean);
        setPageTitle(oapagecontext, s1);
        java.lang.String as[] = getCutomizationData(oapagecontext, oawebbean, s1);
        handleParameters(oapagecontext, oawebbean, s1, s, as);
    }

    private void setWebAppsContext(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean)
    {
        oracle.apps.fnd.framework.server.OADBTransaction oadbtransaction = oapagecontext.getApplicationModule(oawebbean).getOADBTransaction();
        m_WebAppsContext = (oracle.apps.fnd.common.WebAppsContext)((oracle.apps.fnd.framework.server.OADBTransactionImpl)oadbtransaction).getAppsContext();
        if(m_WebAppsContext == null)
        {
            oracle.apps.fnd.framework.server.OADBTransactionImpl oadbtransactionimpl = (oracle.apps.fnd.framework.server.OADBTransactionImpl)oapagecontext.getApplicationModule(oawebbean).getTransaction();
            java.sql.Connection connection = oadbtransactionimpl.getJdbcConnection();
            m_WebAppsContext = new WebAppsContext(connection);
            m_WebAppsContext.setCurrLang(oapagecontext.getCurrentLanguage());
        }
    }

    private void handleParameters(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean, java.lang.String s, java.lang.String s1, java.lang.String as[])
    {
        java.lang.String s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getDbc(oapagecontext);
        javax.servlet.jsp.PageContext pagecontext = oracle.cabo.ui.ServletRenderingContext.getJspPageContext(oapagecontext.getRenderingContext());
        java.lang.String s3 = java.lang.String.valueOf(oapagecontext.getUserId()) + s + java.lang.String.valueOf(oapagecontext.getSessionId());
        java.lang.String s4 = (java.lang.String)oracle.apps.bis.common.ServletWrapper.getSessionValue(pagecontext, s3);
        oracle.apps.fnd.framework.server.OADBTransaction oadbtransaction = oapagecontext.getApplicationModule(oawebbean).getOADBTransaction();
        java.sql.Connection connection = getApplicationModule(oapagecontext, oawebbean).getOADBTransaction().getJdbcConnection();
        oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean oapagelayoutbean = oapagecontext.getPageLayoutBean();
        if(oapagecontext.getParameter("DeleteViewOK") != null)
            try
            {
                if(m_IsPageView)
                {
                    javax.servlet.http.HttpSession httpsession = pagecontext.getSession();
                    od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.clearCustomViewCodeInSession(s, httpsession);
                    if(m_AKRegion == null)
                        initAKRegion(customizationCode, s4, s1, s, connection, s2, pagecontext);
                }
                insertCustomizations(oapagecontext, oawebbean);
                oadbtransaction.commit();
                java.lang.String s5 = getBookMarkUrl(bookmarkUrl, oapagecontext, s, "apply", s1, oapagecontext.getApplicationModule(oawebbean), connection);
                oapagecontext.sendRedirect(s5);
            }
            catch(java.io.IOException _ex) { }
        if(oapagecontext.getParameter("DeleteViewCancel") != null)
            try
            {
                oadbtransaction.rollback();
                java.lang.String s6 = getBookMarkUrl(bookmarkUrl, oapagecontext, s, "cancel", s1, oapagecontext.getApplicationModule(oawebbean), null);
                oapagecontext.sendRedirect(s6.toString());
            }
            catch(java.io.IOException _ex) { }
        if("Delete".equals(viewMode))
        {
            oracle.apps.bis.pmv.customize.common.CustomViewHelper.goToDialogPage(oapagecontext, oawebbean, m_WebAppsContext, connection, as[0], "USERVIEWPAGE");
            return;
        }
        oracle.apps.bis.pmv.session.RequestInfo requestinfo = new RequestInfo();
        requestinfo.setIsPrintable(false);
        requestinfo.setFirstTime("0");
        requestinfo.setRerunLink(false);
        requestinfo.setDBC(s2);
        requestinfo.setParamType("SESSION");
        javax.servlet.ServletContext servletcontext = pagecontext.getServletContext();
        try
        {
            m_UserSession = new UserSession(s, s1, m_WebAppsContext, requestinfo, servletcontext, pagecontext);
            java.lang.String s7 = null;
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(customizationCode))
                s7 = customizationCode;
            else
                s7 = oracle.apps.bis.pmv.customize.common.CustomViewUtil.getSiteLevelCustomizationCode(s1, s, "", 0, connection);
            if(s7 != null)
            {
                m_UserSession.setCustomizedAKRegion(null, s7);
            } else
            {
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s4))
                    s7 = oracle.apps.bis.pmv.customize.common.CustomViewUtil.getFunctionLevelCustomizationCode(s1, s, s4, connection, m_WebAppsContext);
                if(s7 != null)
                    m_UserSession.setCustomizedAKRegion(s4, s7);
            }
            m_AKRegion = m_UserSession.getAKRegion();
        }
        catch(oracle.apps.bis.pmv.PMVException _ex) { }
        oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean oamessagetextinputbean = (oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean)oawebbean.findIndexedChildRecursive("viewName");
        oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean oamessagetextinputbean1 = (oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean)oawebbean.findIndexedChildRecursive("viewDesc");
        oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean oamessagecheckboxbean = (oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean)oawebbean.findIndexedChildRecursive("defaultView");
        if(customizationCode != null && !"SaveAs".equals(viewMode) && as != null && as.length > 0)
        {
            oamessagetextinputbean.setText(as[0]);
            oamessagetextinputbean1.setText(as[1]);
            if("Y".equals(as[2]))
                oamessagecheckboxbean.setChecked(true);
            else
                oamessagecheckboxbean.setChecked(false);
        }
        if("SaveAs".equals(viewMode))
        {
            oamessagetextinputbean.setText("");
            oamessagetextinputbean1.setText("");
            oamessagecheckboxbean.setChecked(false);
            return;
        }
        if("Save".equals(viewMode))
        {
            oamessagetextinputbean.setReadOnly(true);
            oamessagetextinputbean1.setReadOnly(true);
            oamessagecheckboxbean.setReadOnly(true);
            oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean1 = oapagelayoutbean.findChildRecursive("region2");
            oawebbean1.setRendered(false);
            oamessagetextinputbean.setCSSClass("OraDataText");
            oamessagetextinputbean1.setCSSClass("OraDataText");
            m_ViewName = as[0];
            m_ViewDesc = as[1];
            if("Y".equals(as[2]))
            {
                m_DefaultView = "on";
                return;
            }
            m_DefaultView = "off";
        }
    }

    private java.lang.String[] getCutomizationData(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean, java.lang.String s)
    {
        java.lang.String as[] = new java.lang.String[3];
        oracle.apps.fnd.framework.OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        if(customizationCode != null && !"SaveAs".equals(viewMode))
        {
            java.io.Serializable aserializable[] = {
                customizationCode, s, java.lang.String.valueOf(oapagecontext.getUserId()), null, viewMode
            };
            java.lang.Class aclass[] = {
                java.lang.String.class, java.lang.String.class, java.lang.String.class, java.lang.String.class, java.lang.String.class
            };
            as = (java.lang.String[])oaapplicationmodule.invokeMethod("getCustomViewData", aserializable, aclass);
        }
        return as;
    }

    private void setBookmarkUrl(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext)
    {
        if(m_IsPageView)
        {
            bookmarkUrl = (java.lang.String)oapagecontext.getSessionValue("_page_rf_params");
            return;
        }
        javax.servlet.jsp.PageContext pagecontext = oracle.cabo.ui.ServletRenderingContext.getJspPageContext(oapagecontext.getRenderingContext());
        bookmarkUrl = (java.lang.String)pagecontext.getSession().getValue("pBookMarkUrl");
        bookmarkUrl ="../XXCRM_HTML/"+   bookmarkUrl;
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(bookmarkUrl))
            bookmarkUrl = "../XXCRM_HTML/"+    (java.lang.String)oapagecontext.getSessionValue("bookmarkUrl");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(bookmarkUrl))
        {
            java.lang.String s = oapagecontext.getParameter("sortAttribute");
            java.lang.String s1 = oapagecontext.getParameter("sortDirection");
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                bookmarkUrl += "&sortAttribute=" + s + "&sortDirection=" + s1;

            oapagecontext.putSessionValue("bookmarkUrl", "../XXCRM_HTML/"+bookmarkUrl);
        }
    }

    private void setPageTitle(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, java.lang.String s)
    {
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getReportTitle(oapagecontext, m_WebAppsContext, s);
        oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean oapagelayoutbean = oapagecontext.getPageLayoutBean();
        java.lang.String s2 = "";
        if("Delete".equals(viewMode))
            s2 = oapagecontext.getMessage("BIS", "BIS_DELETE_VIEW", null);
        else
        if("Edit".equals(viewMode))
            s2 = oapagecontext.getMessage("BIS", "BIS_EDIT_VIEW", null);
        else
        if("Save".equals(viewMode))
            s2 = oapagecontext.getMessage("BIS", "BIS_SAVE_VIEW", null);
        else
        if("SaveAs".equals(viewMode))
            s2 = oapagecontext.getMessage("BIS", "BIS_SAVE_VIEW_AS", null);
        oracle.cabo.ui.beans.ProductBrandingBean productbrandingbean = (oracle.cabo.ui.beans.ProductBrandingBean)oapagelayoutbean.getProductBranding();
        if(productbrandingbean != null)
        {
            productbrandingbean.setText(s2);
            productbrandingbean.setShortDesc(s2);
        }
        oapagelayoutbean.setTitle(s2 + " : " + s1);
        oapagelayoutbean.setWindowTitle(s2);
    }

    public void processFormRequest(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        oracle.apps.fnd.framework.server.OADBTransaction oadbtransaction = (oracle.apps.fnd.framework.server.OADBTransaction)oapagecontext.getApplicationModule(oawebbean).getTransaction();
        javax.servlet.jsp.PageContext pagecontext = oracle.cabo.ui.ServletRenderingContext.getJspPageContext(oapagecontext.getRenderingContext());
        java.lang.String s = oapagecontext.getParameter("custFunctionName");
        java.lang.String s1 = oapagecontext.getParameter("custRegionCode");
        try
        {
            if(oapagecontext.getParameter("cancelButton") != null)
            {
                pagecontext.getSession().removeValue("pBookMarkUrl");
                oadbtransaction.rollback();
                java.lang.String s2 = getBookMarkUrl(bookmarkUrl, oapagecontext, s, "cancel", s1, oapagecontext.getApplicationModule(oawebbean), null);
                oapagecontext.sendRedirect(s2.toString());
                return;
            }
            if(oapagecontext.getParameter("applyButton") != null)
            {
                pagecontext.getSession().removeValue("pBookMarkUrl");
                java.lang.String s3 = oapagecontext.getParameter("viewName");
                if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s3))
                    s3 = m_ViewName;
                if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s3))
                {
                    java.lang.String s4 = oapagecontext.getMessage("BIS", "BIS_PMV_NO_VIEW_ERROR", null);
                    oracle.apps.fnd.framework.OAException oaexception = new OAException(s4, (byte)0);
                    throw oaexception;
                } else
                {
                    insertCustomizations(oapagecontext, oawebbean);
                    java.lang.String s5 = getBookMarkUrl(bookmarkUrl, oapagecontext, s, "apply", s1, oapagecontext.getApplicationModule(oawebbean), null);
                    oapagecontext.sendRedirect(s5.toString());
                    return;
                }
            }
        }
        catch(java.io.IOException _ex) { }
    }

    public void insertCustomizations(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean)
    {
        java.lang.String s = oapagecontext.getParameter("custRegionCode");
        java.lang.String s1 = oapagecontext.getParameter("custRegionApplId");
        int i = java.lang.Integer.parseInt(s1);
        oracle.apps.fnd.framework.OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        oracle.apps.fnd.framework.server.OADBTransaction oadbtransaction = (oracle.apps.fnd.framework.server.OADBTransaction)oaapplicationmodule.getTransaction();
        oracle.apps.fnd.framework.OAViewObject oaviewobject = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("LanguagesVO");
        oaviewobject.reset();
        oracle.jbo.domain.Number number = new Number(i);
        oracle.jbo.domain.Number number1 = new Number(i);
        if(m_IsPageView && m_AKRegion != null)
            try
            {
                number1 = new Number(m_AKRegion.getRegionApplicationId());
            }
            catch(java.lang.NumberFormatException _ex) { }
            catch(java.sql.SQLException _ex) { }
        java.lang.String s2 = oapagecontext.getParameter("custFunctionName");
        java.lang.String s3 = oapagecontext.getParameter("viewName");
        s3 = s3 != null ? s3 : "";
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s3))
            s3 = m_ViewName;
        java.lang.String s4 = oapagecontext.getParameter("viewDesc");
        s4 = s4 != null ? s4 : "";
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s4))
            s4 = m_ViewDesc;
        java.lang.String s5 = oapagecontext.getParameter("defaultView");
        s5 = s5 != null ? s5 : "";
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s5))
            s5 = m_DefaultView;
        if("on".equals(s5))
            s5 = "Y";
        else
            s5 = "N";
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s3) && ("SaveAs".equals(viewMode) || "Save".equals(viewMode) || "Edit".equals(viewMode)))
        {
            java.io.Serializable aserializable[] = {
                customizationCode, s2, java.lang.String.valueOf(oapagecontext.getUserId()), s3, viewMode
            };
            java.lang.Class aclass[] = {
                java.lang.String.class, java.lang.String.class, java.lang.String.class, java.lang.String.class, java.lang.String.class
            };
            java.lang.String as[] = (java.lang.String[])oaapplicationmodule.invokeMethod("getCustomViewData", aserializable, aclass);
            if(as != null && as.length > 0 && "Y".equals(as[0]))
            {
                java.lang.String s8 = oapagecontext.getMessage("BIS", "BIS_PMV_DUPLICATE_CV_ERROR", null);
                oracle.apps.fnd.framework.OAException oaexception = new OAException(s8, (byte)0);
                throw oaexception;
            }
        }
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(11);
        java.lang.String s6;
        for(; oaviewobject.hasNext(); arraylist.add(s6))
            s6 = (java.lang.String)oaviewobject.next().getAttribute("LanguageCode");

        if(!"SaveAs".equals(viewMode) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(customizationCode))
            deleteRows(oaapplicationmodule, oapagecontext, number, number1, s, arraylist);
        oracle.cabo.ui.ServletRenderingContext.getJspPageContext(oapagecontext.getRenderingContext());
        oracle.apps.bis.common.Util.invalidateTablePersValues(s, oapagecontext);
        oracle.apps.bis.common.Util.invalidateParameterPersValues(s, oapagecontext);
        if("Edit".equals(viewMode) || "SaveAs".equals(viewMode) || "Save".equals(viewMode))
        {
            java.lang.String s7 = java.lang.String.valueOf(m_AKRegion.getNumberOfRows());
            oracle.jbo.domain.Number number2 = null;
            try
            {
                number2 = new Number(s7);
            }
            catch(java.lang.Exception _ex) { }
            insertRows(oaapplicationmodule, oapagecontext, number, number1, s, arraylist, s2, s5, s3, s4, number2);
            if(!m_IsPageView)
                insertCustomRegionItems(oapagecontext, oawebbean, customizationCode, s, i, arraylist);
            oadbtransaction.commit();
            if("Y".equals(s5))
            {
                java.io.Serializable aserializable1[] = {
                    s2, java.lang.String.valueOf(oapagecontext.getUserId()), customizationCode
                };
                java.lang.Class aclass1[] = {
                    java.lang.String.class, java.lang.String.class, java.lang.String.class
                };
                oaapplicationmodule.invokeMethod("updateCustomViewData", aserializable1, aclass1);
            }
        }
    }

    private void insertRows(oracle.apps.fnd.framework.OAApplicationModule oaapplicationmodule, oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.jbo.domain.Number number, oracle.jbo.domain.Number number1, java.lang.String s, com.sun.java.util.collections.ArrayList arraylist, java.lang.String s1,
            java.lang.String s2, java.lang.String s3, java.lang.String s4, oracle.jbo.domain.Number number2)
    {
        oracle.apps.fnd.framework.OAViewObject oaviewobject = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("AkCustomizationsVO");
        oracle.apps.fnd.framework.OAViewObject oaviewobject1 = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("AkCustomizationsTlVO");
        oracle.apps.fnd.framework.OAViewObject oaviewobject2 = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("AkCustomRegionsVO");
        oracle.apps.fnd.framework.OAViewObject oaviewobject3 = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("AkCustomRegionsTlVO");
        oracle.apps.fnd.framework.OAViewObject oaviewobject4 = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("BisAkCustomRegionsVO");
        oracle.apps.fnd.framework.OARow oarow = (oracle.apps.fnd.framework.OARow)oaviewobject.createRow();
        oracle.jbo.domain.Number number3 = new Number(oapagecontext.getUserId());
        customizationCode = java.lang.System.currentTimeMillis() + s;
        if(customizationCode.length() > 30)
            customizationCode = customizationCode.substring(0, 29);
        oarow.setAttribute("CustomizationApplicationId", number);
        oarow.setAttribute("CustomizationCode", customizationCode);
        oarow.setAttribute("RegionApplicationId", number1);
        oarow.setAttribute("RegionCode", s);
        oarow.setAttribute("DefaultCustomizationFlag", s2);
        oarow.setAttribute("CustomizationLevelId", new Number(30));
        oarow.setAttribute("FunctionName", s1);
        oarow.setAttribute("WebUserId", number3);
        oaviewobject.insertRow(oarow);
        for(int i = 0; i < arraylist.size(); i++)
        {
            oracle.apps.fnd.framework.OARow oarow1 = (oracle.apps.fnd.framework.OARow)oaviewobject1.createRow();
            oarow1.setAttribute("Language", arraylist.get(i));
            oarow1.setAttribute("CustomizationApplicationId", number);
            oarow1.setAttribute("CustomizationCode", customizationCode);
            oarow1.setAttribute("RegionApplicationId", number1);
            oarow1.setAttribute("RegionCode", s);
            oarow1.setAttribute("Name", s3);
            oarow1.setAttribute("Description", s4);
            oaviewobject1.insertRow(oarow1);
        }

        oracle.apps.bis.pmv.customize.common.CustomViewHelper.insertCustomRegionRow(oaviewobject2, customizationCode, number, s, number1, "NUM_ROWS_DISPLAY", number2, "");
        oracle.apps.bis.pmv.customize.common.CustomViewHelper.insertCustomRegionTlRows(oaviewobject3, customizationCode, number, s, number1, "NUM_ROWS_DISPLAY", null, arraylist);
        java.lang.String s5 = oapagecontext.getProfile("ICX_CLIENT_IANA_ENCODING");
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        java.lang.String s6 = null;
        if(bookmarkUrl != null)
            s6 = oracle.apps.bis.common.UserPersonalizationUtil.removeOldCustomCode(bookmarkUrl, "&pCustomCode=");
        try
        {
            if(m_IsPageView)
            {
                s6 = s6 + "&pFirstTime=0&pCustomCode=" + oracle.cabo.share.url.EncoderUtils.encodeString(customizationCode, s5);
                s6 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getRunFunctionURL(s1, s6, m_WebAppsContext);
                stringbuffer.append(s6);
            } else
            {
                stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString(s6, s5));
                stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pCustomCode=", s5)).append(oracle.cabo.share.url.EncoderUtils.encodeString(customizationCode, s5));
            }
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        oracle.apps.bis.pmv.customize.common.CustomViewHelper.insertBisCustomRegionRow(oaviewobject4, customizationCode, number, s, number1, "BOOKMARK_URL", stringbuffer.toString(), "");
    }

    private void deleteRows(oracle.apps.fnd.framework.OAApplicationModule oaapplicationmodule, oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.jbo.domain.Number number, oracle.jbo.domain.Number number1, java.lang.String s, com.sun.java.util.collections.ArrayList arraylist)
    {
        oracle.apps.fnd.framework.OAViewObject oaviewobject = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("AkCustomizationsVO");
        oracle.apps.fnd.framework.OAViewObject oaviewobject1 = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("AkCustomizationsTlVO");
        oracle.apps.fnd.framework.OAViewObject oaviewobject2 = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("AkCustomRegionsVO");
        oracle.apps.fnd.framework.OAViewObject oaviewobject3 = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("AkCustomRegionsTlVO");
        oracle.apps.fnd.framework.OAViewObject oaviewobject4 = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("BisAkCustomRegionsVO");
        oaviewobject.setWhereClauseParam(0, number);
        oaviewobject.setWhereClauseParam(1, customizationCode);
        oaviewobject.setWhereClauseParam(2, number1);
        oaviewobject.setWhereClauseParam(3, s);
        oracle.apps.bis.pmv.customize.common.CustomViewHelper.deleteAllQueriedRows(oaviewobject, "", oapagecontext, true);
        for(int i = 0; i < arraylist.size(); i++)
        {
            oaviewobject1.setWhereClauseParam(0, number);
            oaviewobject1.setWhereClauseParam(1, customizationCode);
            oaviewobject1.setWhereClauseParam(2, number1);
            oaviewobject1.setWhereClauseParam(3, s);
            oaviewobject1.setWhereClauseParam(4, arraylist.get(i));
            oracle.apps.bis.pmv.customize.common.CustomViewHelper.deleteAllQueriedRows(oaviewobject1, "", oapagecontext, true);
        }

        oaviewobject2.setWhereClauseParam(0, number);
        oaviewobject2.setWhereClauseParam(1, customizationCode);
        oaviewobject2.setWhereClauseParam(2, number1);
        oaviewobject2.setWhereClauseParam(3, s);
        oracle.apps.bis.pmv.customize.common.CustomViewHelper.deleteAllQueriedRows(oaviewobject2, "", oapagecontext, true);
        oaviewobject3.setWhereClauseParam(0, number);
        oaviewobject3.setWhereClauseParam(1, customizationCode);
        oaviewobject3.setWhereClauseParam(2, number1);
        oaviewobject3.setWhereClauseParam(3, s);
        oracle.apps.bis.pmv.customize.common.CustomViewHelper.deleteAllQueriedRows(oaviewobject3, "", oapagecontext, true);
        oaviewobject4.setWhereClauseParam(0, number);
        oaviewobject4.setWhereClauseParam(1, customizationCode);
        oaviewobject4.setWhereClauseParam(2, number1);
        oaviewobject4.setWhereClauseParam(3, s);
        oaviewobject4.setWhereClauseParam(4, "BOOKMARK_URL");
        oracle.apps.bis.pmv.customize.common.CustomViewHelper.deleteAllQueriedRows(oaviewobject4, "", oapagecontext, true);
    }

    private void insertCustomRegionItems(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean, java.lang.String s, java.lang.String s1, int i, com.sun.java.util.collections.ArrayList arraylist)
    {
        oracle.apps.fnd.framework.OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        oracle.apps.fnd.framework.OAViewObject oaviewobject = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("AkCustomRegionItemsVO");
        oracle.apps.fnd.framework.OAViewObject oaviewobject1 = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("AkCustomRegionItemsTlVO");
        oracle.apps.fnd.framework.server.OADBTransaction _tmp = (oracle.apps.fnd.framework.server.OADBTransaction)oaapplicationmodule.getTransaction();
        try
        {
            oracle.jbo.domain.Number number = new Number(i);
            oracle.jbo.domain.Number number1 = new Number(i);
            oaviewobject.setWhereClauseParam(0, number);
            oaviewobject.setWhereClauseParam(1, s);
            oaviewobject.setWhereClauseParam(2, number1);
            oaviewobject.setWhereClauseParam(3, s1);
            oracle.apps.bis.pmv.customize.common.CustomViewHelper.deleteAllQueriedRows(oaviewobject, "", oapagecontext, true);
            oaviewobject1.setWhereClauseParam(0, number);
            oaviewobject1.setWhereClauseParam(1, s);
            oaviewobject1.setWhereClauseParam(2, number1);
            oaviewobject1.setWhereClauseParam(3, s1);
            oracle.apps.bis.pmv.customize.common.CustomViewHelper.deleteAllQueriedRows(oaviewobject1, "", oapagecontext, true);
            com.sun.java.util.collections.ArrayList arraylist1 = new ArrayList(m_AKRegion.getDisplayColumns());
            arraylist1.addAll(m_AKRegion.getSortedItems());
            Object obj = null;
            for(int k = 0; k < arraylist1.size(); k++)
            {
                oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist1.get(k);
                java.lang.String s2 = akregionitem.getDisplayFlag();
                java.lang.String s3 = akregionitem.getDisplaySequence();
                java.lang.String s4 = akregionitem.getAttributeCode();
                int j = akregionitem.getAttributeApplicationId();
                oracle.apps.bis.pmv.customize.common.CustomViewHelper.insertCustomRegionItemsRow(oaviewobject, s, number, s1, number1, s4, new Number(j), "DISPLAY_SEQUENCE", new Number(s3));
                oracle.apps.bis.pmv.customize.common.CustomViewHelper.insertCustomRegionItemsTlRows(oaviewobject1, s, number, s1, number1, s4, new Number(j), "DISPLAY_SEQUENCE", null, arraylist);
                oracle.apps.bis.pmv.customize.common.CustomViewHelper.insertCustomRegionItemsRow(oaviewobject, s, number, s1, number1, s4, new Number(j), "NODE_DISPLAY_FLAG", s2);
                oracle.apps.bis.pmv.customize.common.CustomViewHelper.insertCustomRegionItemsTlRows(oaviewobject1, s, number, s1, number1, s4, new Number(j), "NODE_DISPLAY_FLAG", null, arraylist);
            }

            return;
        }
        catch(java.lang.Exception _ex)
        {
            return;
        }
    }

    private void goToDialogPage(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection, java.lang.String as[])
    {
        oracle.apps.fnd.framework.OAException oaexception = null;
        java.lang.String s = "";
        if(as != null && as.length > 0)
            s = as[0];
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            oracle.apps.fnd.common.MessageToken messagetoken = new MessageToken("VIEWNAME", s, false);
            oracle.apps.fnd.common.MessageToken amessagetoken[] = new oracle.apps.fnd.common.MessageToken[1];
            amessagetoken[0] = messagetoken;
            oaexception = new OAException("BIS", "BIS_DELETE_VIEW_TITLE", amessagetoken);
        } else
        {
            oaexception = new OAException("BIS", "BIS_DELETE_VIEW_TITL");
        }
        oracle.apps.fnd.framework.OAException oaexception1 = new OAException("BIS", "BIS_PROCEED");
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
		stringbuffer.append("/OA_HTML/OA.jsp?page=/od/oracle/apps/xxcrm/bis/pmv/customize/webui/ODBISPMVUSERVIEWPAGE&retainAM=Y&custRegionCode=" + oapagecontext.getParameter("custRegionCode") + "&custRegionApplId=" + oapagecontext.getParameter("custRegionApplId") + "&custFunctionName=" + oapagecontext.getParameter("custFunctionName") + "&language=" + oapagecontext.getParameter("language") + "&transactionid=" + oapagecontext.getParameter("transactionid") + "&sessionid=" + oapagecontext.getParameter("sessionid") + "&viewMode=" + oapagecontext.getParameter("viewMode"));
        if(oapagecontext.getParameter("pReportTitle") != null)
            stringbuffer.append("&pReportTitle=").append(oapagecontext.getParameter("pReportTitle"));
        if(oapagecontext.getParameter("pCustomCode") != null)
            stringbuffer.append("&pCustomCode=").append(oapagecontext.getParameter("pCustomCode"));
        java.lang.String s1 = stringbuffer.append("&cancelClicked=Y").toString();
        java.lang.String s2 = stringbuffer.append("&okClicked=Y").toString();
        oracle.apps.fnd.framework.webui.OADialogPage oadialogpage = new OADialogPage((byte)1, oaexception, oaexception1, s2, s1);
        oadialogpage.setRetainAMValue(true);
        new AttributeSet(oapagecontext, "/oracle/apps/fnd/attributesets/Buttons/Cancel");
        oadialogpage.setOkButtonLabel("&" + oapagecontext.getMessage("BIS", "BIS_YES", null));
        oadialogpage.setNoButtonLabel("&" + oapagecontext.getMessage("BIS", "BIS_NO", null));
        oapagecontext.redirectToDialogPage(oadialogpage);
    }

    private java.lang.String getBookMarkUrl(java.lang.String s, oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, java.lang.String s1, java.lang.String s2, java.lang.String s3, oracle.apps.fnd.framework.OAApplicationModule oaapplicationmodule, java.sql.Connection connection)
    {
        java.lang.String s4 = s1 + "paramBookMarkUrl" + oapagecontext.getSessionId();
        java.lang.String s5 = oapagecontext.getProfile("ICX_CLIENT_IANA_ENCODING");
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        if(oapagecontext.getSessionValue("reportTitle") != null)
            oapagecontext.removeSessionValue("reportTitle");
        if("cancel".equals(s2))
        {
            if(m_IsPageView)
                bookmarkUrl = getDashboardBookMarkUrlForRendering(oapagecontext, s5, bookmarkUrl, s1, s2, null);
            stringbuffer.append(bookmarkUrl);
            return stringbuffer.toString();
        }
        javax.servlet.jsp.PageContext pagecontext = oracle.cabo.ui.ServletRenderingContext.getJspPageContext(oapagecontext.getRenderingContext());
        java.lang.String s6 = null;
        if(connection != null)
        {
            com.sun.java.util.collections.HashMap hashmap = oracle.apps.bis.common.UserPersonalizationUtil.getUserLevelCustomizationData(java.lang.String.valueOf(oapagecontext.getUserId()), s1, connection);
            if(hashmap != null)
            {
                s6 = oracle.apps.bis.common.UserPersonalizationUtil.getDefaultBookMarkUrl(hashmap);
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s6))
                    s6 = oracle.apps.fnd.framework.webui.OAUrl.decode(oapagecontext, s6);
            }
        }
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s6))
        {
            s6 = oracle.apps.bis.common.UserPersonalizationUtil.removeOldCustomCode(bookmarkUrl, "&pCustomCode=");
            if(m_IsPageView && "Delete".equals(viewMode))
                s6 = getDashboardBookMarkUrlForRendering(oapagecontext, s5, bookmarkUrl, s1, s2, viewMode);
        }
        stringbuffer.append(s6);
        oracle.apps.bis.pmv.customize.common.CustomViewHelper.invalidateAKCache(s3, oapagecontext, oaapplicationmodule);
        if("Delete".equals(viewMode))
        {
            if(oracle.apps.bis.common.ServletWrapper.getSessionValue(pagecontext, s4) != null)
                oracle.apps.bis.common.ServletWrapper.removeSessionAttribute(pagecontext, s4);
            if(!m_IsPageView)
                stringbuffer.append("&deleteView=Y");
            return stringbuffer.toString();
        }
        if("Edit".equals(viewMode) || "SaveAs".equals(viewMode) || "Save".equals(viewMode))
        {
            stringbuffer.append("&pCustomCode=").append(customizationCode);
            oracle.apps.bis.common.ServletWrapper.putSessionValue(pagecontext, s4, stringbuffer.toString());
            java.lang.String s7 = oracle.apps.bis.common.UserPersonalizationUtil.getTablePersSessionKey(s1, java.lang.Integer.parseInt(oapagecontext.getSessionId()), true, true, customizationCode, s3);
            oracle.apps.bis.common.ServletWrapper.putSessionValue(pagecontext, s7, m_AKRegion);
            if(m_IsPageView)
            {
                java.lang.String s8 = getDashboardBookMarkUrlForRendering(oapagecontext, s5, bookmarkUrl, s1, s2, viewMode);
                return s8;
            } else
            {
                return stringbuffer.toString();
            }
        } else
        {
            return null;
        }
    }

    private java.lang.String getDashboardBookMarkUrlForRendering(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4)
    {
        java.lang.String s5 = (java.lang.String)oapagecontext.getSessionValue("_page_all_params");
        java.lang.String s6 = null;
        try
        {
            s6 = oracle.cabo.share.url.EncoderUtils.encodeString(customizationCode, s);
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        if(s5 == null)
            s5 = s1;
        java.lang.String s7 = null;
        if("cancel".equals(s3))
            s7 = s5 + "&pFirstTime=0&pCustomCode=" + s6;
        else
        if("Delete".equals(s4))
            s7 = s5 + "&pFirstTime=0&pUserVLayout=DELETE";
        else
        if("Edit".equals(s4) || "SaveAs".equals(s4) || "Save".equals(s4))
            s7 = s5 + "&pCustomCode=" + s6 + "&pFirstTime=0&pUserVLayout=SAVE";
        s7 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getRunFunctionURL(s2, s7, m_WebAppsContext);
        return s7;
    }

    private void initAKRegion(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.sql.Connection connection, java.lang.String s4, javax.servlet.jsp.PageContext pagecontext)
    {
        oracle.apps.bis.pmv.session.RequestInfo requestinfo = new RequestInfo();
        requestinfo.setIsPrintable(false);
        requestinfo.setFirstTime("0");
        requestinfo.setRerunLink(false);
        requestinfo.setDBC(s4);
        requestinfo.setParamType("SESSION");
        javax.servlet.ServletContext servletcontext = pagecontext.getServletContext();
        try
        {
            m_UserSession = new UserSession(s3, s2, m_WebAppsContext, requestinfo, servletcontext, pagecontext);
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
                s = oracle.apps.bis.pmv.customize.common.CustomViewUtil.getSiteLevelCustomizationCode(s2, s3, "", 0, connection);
            if(s != null)
            {
                m_UserSession.setCustomizedAKRegion(null, s);
            } else
            {
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                    s = oracle.apps.bis.pmv.customize.common.CustomViewUtil.getFunctionLevelCustomizationCode(s2, s3, s1, connection, m_WebAppsContext);
                if(s != null)
                    m_UserSession.setCustomizedAKRegion(s1, s);
            }
        }
        catch(oracle.apps.bis.pmv.PMVException _ex) { }
        m_AKRegion = m_UserSession.getAKRegion();
    }

    public ODUserViewCO()
    {
        customizationCode = "";
        viewMode = "";
        bookmarkUrl = "";
        m_ViewByAttrValue = "";
    }

    public static final java.lang.String RCS_ID = "$Header: ODUserViewCO.java 115.25 2007/05/07 08:41:22 nkishore noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODUserViewCO.java 115.25 2007/05/07 08:41:22 nkishore noship $", "oracle.apps.bis.pmv.customize.webui");
    public static final java.lang.String P_BOOKMARK_URL = "BOOKMARK_URL";
    protected oracle.apps.fnd.common.WebAppsContext m_WebAppsContext;
    private oracle.apps.bis.pmv.session.UserSession m_UserSession;
    private oracle.apps.bis.pmv.metadata.AKRegion m_AKRegion;
    private java.lang.String customizationCode;
    private java.lang.String viewMode;
    private java.lang.String bookmarkUrl;
    private java.lang.String m_ViewByAttrValue;
    private java.lang.String m_ViewName;
    private java.lang.String m_ViewDesc;
    private java.lang.String m_DefaultView;
    private boolean m_IsPageView;

}
