// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames 
// Source File Name:   RelatedLinksListHdrCO.java

package od.oracle.apps.xxcrm.bis.pmv.customize.webui;

import java.io.IOException;
import java.io.Serializable;
import java.io.UnsupportedEncodingException;
import oracle.apps.bis.common.CommonUtil;
import oracle.apps.bis.common.Constants;
import oracle.apps.bis.common.SessionObjectManager;
import oracle.apps.bis.common.UIUtil;
import oracle.apps.bis.common.builder.Builder;
import oracle.apps.bis.common.builder.BuilderContext;
import oracle.apps.bis.common.builder.BuilderNavigationContext;
import oracle.apps.bis.links.webui.LinksBuilder;
import oracle.apps.bis.pmv.common.PMVUtil;
import oracle.apps.bis.pmv.common.RelatedLinksUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAUrl;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAButtonSpacerBean;
import oracle.apps.fnd.framework.webui.beans.layout.OACellFormatBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.cabo.share.url.EncoderUtils;
import oracle.cabo.ui.beans.BaseWebBean;
import oracle.cabo.ui.beans.ProductBrandingBean;
import oracle.cabo.ui.beans.StyledTextBean;
import oracle.cabo.ui.beans.layout.CellFormatBean;
import oracle.cabo.ui.beans.layout.PageLayoutBean;
import oracle.cabo.ui.beans.layout.RowLayoutBean;
import oracle.cabo.ui.beans.layout.TableLayoutBean;
import oracle.cabo.ui.beans.nav.LinkContainerBean;
import oracle.cabo.ui.beans.table.TableBean;
import oracle.jbo.ApplicationModule;
import oracle.jbo.AttributeList;
import oracle.jbo.RowIterator;
import oracle.jbo.RowSet;
import oracle.jbo.Transaction;

// Referenced classes of package oracle.apps.bis.pmv.customize.webui:
//            TableCO

public class ODRelatedLinksListHdrCO extends oracle.apps.fnd.framework.webui.OAControllerImpl
{

    public void processRequest(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        java.lang.String s = oapagecontext.getParameter("designer");
        oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean oapagelayoutbean = oapagecontext.getPageLayoutBean();
        oracle.apps.fnd.framework.OAApplicationModule oaapplicationmodule = getApplicationModule(oapagecontext, oawebbean);
        oracle.apps.fnd.common.WebAppsContext webappscontext = (oracle.apps.fnd.common.WebAppsContext)((oracle.apps.fnd.framework.server.OADBTransactionImpl)oaapplicationmodule.getOADBTransaction()).getAppsContext();
        oracle.cabo.ui.beans.ProductBrandingBean productbrandingbean = (oracle.cabo.ui.beans.ProductBrandingBean)oapagelayoutbean.getProductBranding();
        if("Y".equals(s))
            oracle.apps.bis.common.UIUtil.setProductBrandingImage(oapagecontext, this);
        oapagecontext.activateWarnAboutChanges();
        java.lang.String s1 = oapagecontext.getParameter("builderKey");
        oracle.apps.bis.links.webui.LinksBuilder linksbuilder = null;
        if(s1 != null && !s1.equals(""))
            linksbuilder = (oracle.apps.bis.links.webui.LinksBuilder)oracle.apps.bis.common.CommonUtil.getBuilderObject(oapagecontext);
        java.lang.String s2 = "";
        java.lang.String s3 = "";
        s2 = oapagecontext.getParameter("custFunctionName");
        s3 = oapagecontext.getParameter("custRegionCode");
        oracle.apps.fnd.framework.server.OADBTransaction _tmp = (oracle.apps.fnd.framework.server.OADBTransaction)oapagecontext.getApplicationModule(oawebbean).getTransaction();
        oracle.apps.bis.pmv.common.PMVUtil.getReportTitle(oapagecontext, webappscontext, s2);
        java.lang.String s4 = oapagecontext.getParameter("custRegionApplId");
        if(s4 != null)
            oapagecontext.putSessionValue("custRegionApplId", s4);
        java.lang.String s5 = oapagecontext.getParameter("pViewBy");
        if(s5 != null)
            oapagecontext.putSessionValue("pViewBy", s5);
        java.lang.String s6 = oapagecontext.getParameter("backUrl");
        if(s6 != null)
            oapagecontext.putSessionValue("backUrl", s6);
        boolean flag = false;
        java.lang.String s9 = null;
        s9 = (java.lang.String)oapagecontext.getSessionValue("fromPreseed");
        if(s9 == null || s9.length() == 0)
            s9 = oapagecontext.getParameter("fromPreseed");
        flag = s9 != null ? "Y".equalsIgnoreCase(s9) : false;
        if(flag)
        {
            oapagecontext.putSessionValue("fromPreseed", "Y");
            oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean oapagebuttonbarbean = (oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean)oawebbean.findChildRecursive("PageButtonBar");
            oapagebuttonbarbean.setRendered("Y".equals(s));
        }
        java.lang.String s10 = oapagecontext.getParameter("customLevel");
        if(s10 == null)
            s10 = "";
        java.lang.String s11 = oapagecontext.getParameter("customLevelValue");
        if(s11 == null)
            s11 = "";
        if(!flag)
        {
            s10 = "USER";
            s11 = java.lang.String.valueOf(oapagecontext.getUserId());
        }
        oapagecontext.putParameter("customLevel", s10);
        oapagecontext.putParameter("customLevelValue", s11);
        oapagecontext.putSessionValue("customLevel", s10);
        oapagecontext.putSessionValue("customLevelValue", s11);
        boolean flag1 = false;
        flag1 = "Y".equals(oapagecontext.getParameter("fromRelated"));
        boolean flag2 = false;
        java.lang.String s12 = null;
        s12 = (java.lang.String)oapagecontext.getSessionValue("fromPortal");
        if(s12 == null || s12.length() == 0)
        {
            s12 = oapagecontext.getParameter("fromPortal");
            if("Y".equals(s12))
                oapagecontext.putSessionValue("fromPortal", "Y");
        }
        flag2 = s12 != null ? "Y".equals(s12) : false;
        if(flag2)
        {
            java.lang.String s13 = oapagecontext.getParameter("portletTitle");
            if(s13 != null)
                oapagecontext.putSessionValue("reportTitle", s13);
            java.lang.String s15 = oapagecontext.getParameter("plugId");
            if(s15 != null && s15.length() > 0)
                oapagecontext.putSessionValue("functionID", s15);
            java.lang.String s7 = oapagecontext.getParameter("backUrl");
            if(s7 != null)
                oapagecontext.putSessionValue("backUrl", s7);
            java.lang.String s17 = oapagecontext.getParameter("portletFunctionId");
            if(s17 != null)
                oapagecontext.putSessionValue("portletFunctionId", s17);
        }
        if(flag1)
        {
            oapagecontext.putSessionValue("fromRelated", "Y");
            java.lang.String s8 = oapagecontext.getParameter("backUrl");
            if(s8 != null)
                oapagecontext.putSessionValue("backUrl", s8);
        }
        flag1 = "Y".equals(oapagecontext.getSessionValue("fromRelated"));
        if(oapagelayoutbean != null && !flag && !flag1 && !flag2)
            oapagelayoutbean.prepareForRendering(oapagecontext);
        if((oapagelayoutbean != null) & (!"Y".equals(s)))
            productbrandingbean.setText(oapagecontext.getMessage("BIS", "BIS_PERSONALIZE_LINKS", null));
        java.lang.String s14 = oapagecontext.getParameter("firstTime");
        java.lang.String s16 = "";
        java.lang.String s18 = "";
        if(s14 != null && s14.length() > 0)
        {
            s16 = oapagecontext.getParameter("functionID");
            oapagecontext.putSessionValue("functionID", s16);
            s18 = oapagecontext.getParameter("reportTitle");
            oapagecontext.putSessionValue("reportTitle", s18);
        } else
        {
            s16 = (java.lang.String)oapagecontext.getSessionValue("functionID");
            s18 = (java.lang.String)oapagecontext.getSessionValue("reportTitle");
        }
        oapagelayoutbean.setTitle(oapagecontext.getMessage("BIS", "BIS_PRESEED_EDIT_MSG", null) + ": " + s18);
        if(s16 == null && s2 != null && !s2.equals(""))
        {
            oracle.apps.fnd.framework.OAViewObject oaviewobject = (oracle.apps.fnd.framework.OAViewObject)oaapplicationmodule.findViewObject("FunctionIdVO");
            if(oaviewobject != null)
            {
                oaviewobject.setWhereClauseParam(0, s2);
                oaviewobject.executeQuery();
                if(oaviewobject.hasNext())
                {
                    oaviewobject.next();
                    oracle.jbo.Row row = oaviewobject.getCurrentRow();
                    s16 = row.getAttribute("FunctionId").toString();
                    oapagecontext.putSessionValue("functionID", s16);
                }
            }
        }
        if(oapagecontext.getParameter("DeleteFlag") != null && oapagecontext.getParameter("DeleteFlag").equals("Y"))
        {
            java.lang.String s19 = "";
            if(oapagecontext.getParameter("RelatedLinkId") != null)
            {
                java.lang.String s20 = oapagecontext.getParameter("RelatedLinkId");
                oapagecontext.getParameter("linkType");
                java.io.Serializable aserializable[] = {
                    s20, s10
                };
                java.lang.Class aclass[] = {
                    java.lang.String.class, java.lang.String.class
                };
                try
                {
                    oaapplicationmodule.invokeMethod("deleteRelatedLink", aserializable, aclass);
                    if(flag && !"Y".equals(s))
                        oaapplicationmodule.getOADBTransaction().commit();
                }
                catch(oracle.apps.fnd.framework.OAException _ex) { }
            }
        }
        java.lang.String s21 = "";
        java.lang.String s22 = "";
        java.lang.String s23 = "";
        java.lang.String s24 = "";
        java.lang.String s25 = "";
        if(oapagecontext.getParameter("RelatedLinkId") != null)
            s24 = oapagecontext.getParameter("RelatedLinkId");
        if(oapagecontext.getParameter("UpdateFlag") != null && oapagecontext.getParameter("UpdateFlag").equals("Y"))
        {
            if(oapagecontext.getParameter("linkType") != null)
                s21 = oapagecontext.getParameter("linkType");
            if(oapagecontext.getParameter("relatedLinkName") != null)
                s22 = oapagecontext.getParameter("relatedLinkName");
            if(oapagecontext.getParameter("relatedLinkDescription") != null)
                s23 = oapagecontext.getParameter("relatedLinkDescription");
            if(oapagecontext.getParameter("linkUserId") != null)
                s25 = oapagecontext.getParameter("linkUserId");
            java.lang.StringBuffer stringbuffer = new StringBuffer(500);
            stringbuffer.append("&custRegionCode=").append(oapagecontext.getParameter("custRegionCode"));
            stringbuffer.append("&custFunctionName=").append(oapagecontext.getParameter("custFunctionName"));
            stringbuffer.append("&custRegionApplId=").append(oapagecontext.getParameter("custRegionApplId"));
            stringbuffer.append("&customLevel=").append(s10);
            stringbuffer.append("&customLevelValue=").append(s11);
            stringbuffer.append("&").append("builderKey").append("=").append(s1);
            java.lang.String s26 = oapagecontext.getProfile("ICX_CLIENT_IANA_ENCODING");
            stringbuffer.append("&pCustomView=");
            try
            {
                if(oapagecontext.getParameter("pCustomView") != null)
                    stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString(oapagecontext.getParameter("pCustomView"), s26));
            }
            catch(java.io.UnsupportedEncodingException _ex) { }
            if("USER_URL".equals(s21))
            {
                java.lang.String s27 = "&functionID=" + s16 + "&linkType=" + s21 + "&relatedLinkName=" + oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, s22) + "&relatedLinkDescription=" + oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, s23) + "&RelatedLinkId=" + s24 + "&linkUserId=" + s25;
                if(flag)
                    s27 = s27 + "&fromPreseed=Y&reportTitle=" + oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, s18);
                if(s != null)
                    s27 = s27 + "&designer=" + s;
                s27 = s27 + "&builderKey=" + oapagecontext.getParameter("builderKey");
                oapagecontext.setRedirectURL("OA.jsp?akRegionCode=BISPMVRLUPDATEURLPAGE&akRegionApplicationId=191" + s27 + stringbuffer.toString(), true);
            } else
            {
                java.lang.String s28 = "&functionID=" + s16 + "&linkType=" + s21 + "&relatedLinkName=" + oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, s22) + "&relatedLinkDescription=" + oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, s23) + "&RelatedLinkId=" + s24;
                if(flag)
                    s28 = s28 + "&fromPreseed=Y&reportTitle=" + oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, s18);
                if(s != null)
                    s28 = s28 + "&designer=" + s;
                s28 = s28 + "&builderKey=" + oapagecontext.getParameter("builderKey");
                oapagecontext.setRedirectURL("OA.jsp?akRegionCode=BISPMVRLUPDATELINKPAGE&akRegionApplicationId=191" + s28 + stringbuffer.toString(), true);
            }
        }
        if("Y".equals(oapagecontext.getParameter("MoveUpFlag")) || "Y".equals(oapagecontext.getParameter("MoveDownFlag")))
        {
            java.lang.Integer integer = new Integer(0);
            if("Y".equals(oapagecontext.getParameter("MoveDownFlag")))
            {
                integer = new Integer(1);
                oapagecontext.removeParameter("MoveDownFlag");
            } else
            {
                oapagecontext.removeParameter("MoveUpFlag");
            }
            java.io.Serializable aserializable1[] = {
                s24, integer, s10
            };
            java.lang.Class aclass1[] = {
                java.lang.String.class, java.lang.Integer.class, java.lang.String.class
            };
            getApplicationModule(oapagecontext, oawebbean).invokeMethod("moveLinks", aserializable1, aclass1);
            if(flag && !"Y".equals(s))
                getApplicationModule(oapagecontext, oawebbean).getOADBTransaction().commit();
        }
        oapagelayoutbean.setTitle(oapagecontext.getMessage("BIS", "BIS_PRESEED_EDIT_MSG", null) + ": " + s18);
        oracle.apps.fnd.framework.webui.beans.layout.OAButtonSpacerBean _tmp1 = (oracle.apps.fnd.framework.webui.beans.layout.OAButtonSpacerBean)createWebBean(oapagecontext, "BUTTON_SPACER");
        if(!flag)
        {
            oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean oatablelayoutbean = (oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean)createWebBean(oapagecontext, "TABLE_LAYOUT");
            oawebbean.addIndexedChild(oatablelayoutbean);
            oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean oarowlayoutbean = (oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT");
            oatablelayoutbean.addRowLayout(oarowlayoutbean);
            oatablelayoutbean.setWidth("100%");
            oarowlayoutbean.setWidth("100%");
            if(!flag && !flag2)
                oarowlayoutbean.setHAlign("right");
            oracle.apps.fnd.framework.webui.beans.layout.OACellFormatBean oacellformatbean = (oracle.apps.fnd.framework.webui.beans.layout.OACellFormatBean)createWebBean(oapagecontext, "CELL_FORMAT");
            oarowlayoutbean.addIndexedChild(oacellformatbean);
            oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean oamessagestyledtextbean = (oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean)createWebBean(oapagecontext, "MESSAGE_TEXT");
            if(!flag2)
                oamessagestyledtextbean.setText("");
            else
                oamessagestyledtextbean.setText(oapagecontext.getMessage("BIS", "BIS_PERS_LINK_PORTLET_HELP", null));
            oamessagestyledtextbean.setStyleClass("OraInstructionText");
            oacellformatbean.addIndexedChild(oamessagestyledtextbean);
            if(flag1)
                oacellformatbean.setWidth("85%");
            if(flag2)
                oacellformatbean.setWidth("100%");
            else
                oacellformatbean.setWidth("88%");
        }
        oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean oatablelayoutbean1 = (oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean)createWebBean(oapagecontext, "TABLE_LAYOUT");
        if(flag)
            oatablelayoutbean1.setWidth("100%");
        oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean oarowlayoutbean1 = (oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT");
        oarowlayoutbean1.setHAlign("right");
        oatablelayoutbean1.addRowLayout(oarowlayoutbean1);
        oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean oatablelayoutbean2 = (oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean)createWebBean(oapagecontext, "TABLE_LAYOUT");
        oarowlayoutbean1.addIndexedChild(oatablelayoutbean2);
        java.lang.StringBuffer stringbuffer1 = new StringBuffer(500);
        stringbuffer1.append("&custRegionCode=").append(oapagecontext.getParameter("custRegionCode"));
        stringbuffer1.append("&custFunctionName=").append(oapagecontext.getParameter("custFunctionName"));
        stringbuffer1.append("&custRegionApplId=").append(oapagecontext.getParameter("custRegionApplId"));
        oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean oarowlayoutbean2 = (oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT");
        oatablelayoutbean1.addRowLayout(oarowlayoutbean2);
        if(flag)
            oarowlayoutbean2.setWidth("100%");
        oracle.apps.fnd.framework.webui.beans.table.OATableBean oatablebean = (oracle.apps.fnd.framework.webui.beans.table.OATableBean)createWebBean(oapagecontext, oawebbean, "BisPmvRLListTable");
        oarowlayoutbean2.addIndexedChild(oatablebean);
        if(!flag2)
            oatablebean.setAlternateText(oapagecontext.getMessage("BIS", "BISNORELATEDLINKS", null));
        else
            oatablebean.setAlternateText(oapagecontext.getMessage("BIS", "BISNOITEMS", null));
        if(flag && linksbuilder == null)
        {
            oatablebean.setWidth("100%");
            oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean oabreadcrumbsbean = new OABreadCrumbsBean();
            oracle.apps.fnd.framework.webui.OAUrl oaurl = new OAUrl("/OA_HTML/OA.jsp?akRegionCode=BIS_PRESEEDED_RL_MAIN&akRegionApplicationId=191&customLevel=" + s10 + "&customLevelValue=" + s11);
            if(s10 != null && !s10.equals(""))
                oabreadcrumbsbean.addLink(oapagecontext.getMessage("BIS", "BIS_CUSTOMIZE_LINKS", null), oaurl.createURL(oapagecontext), false);
            else
                oabreadcrumbsbean.addLink(oapagecontext.getMessage("BIS", "BIS_PRESEED_BC_LINK", null), oaurl.createURL(oapagecontext), false);
            oabreadcrumbsbean.addLink(oapagecontext.getMessage("BIS", "BIS_PRESEED_UPDATE_MSG", null), null, true);
            oapagelayoutbean.setLocation(oabreadcrumbsbean);
        }
        if(linksbuilder != null)
        {
            oapagelayoutbean.prepareForRendering(oapagecontext);
            linksbuilder.renderBreadCrumb(oapagecontext);
        }
    }

    public void processFormRequest(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        java.lang.String s = "";
        java.lang.String s3 = oapagecontext.getParameter("event");
        boolean flag = false;
        java.lang.String s4 = null;
        s4 = (java.lang.String)oapagecontext.getSessionValue("fromPreseed");
        if(s4 == null || s4.length() == 0)
            s4 = oapagecontext.getParameter("fromPreseed");
        flag = s4 != null ? "Y".equalsIgnoreCase(s4) : false;
        if(flag)
            oapagecontext.putSessionValue("fromPreseed", "Y");
        java.lang.String s5 = oapagecontext.getParameter("builderKey");
        oracle.apps.bis.links.webui.LinksBuilder linksbuilder = null;
        if(s5 != null && !s5.equals(""))
        {
            linksbuilder = (oracle.apps.bis.links.webui.LinksBuilder)oapagecontext.getTransactionTransientValue(s5);
            if(linksbuilder != null)
                linksbuilder.handleBreadCrumbEvent(oapagecontext);
        }
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append("&custRegionCode=").append(oapagecontext.getParameter("custRegionCode"));
        stringbuffer.append("&custFunctionName=").append(oapagecontext.getParameter("custFunctionName"));
        stringbuffer.append("&custRegionApplId=").append(oapagecontext.getParameter("custRegionApplId"));
        if(!flag || linksbuilder != null)
        {
            java.lang.String s6 = oapagecontext.getProfile("ICX_CLIENT_IANA_ENCODING");
            stringbuffer.append("&pCustomView=");
            try
            {
                if(oapagecontext.getParameter("pCustomView") != null)
                    stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString(oapagecontext.getParameter("pCustomView"), s6));
            }
            catch(java.io.UnsupportedEncodingException _ex) { }
            if("MoveUp".equals(s3) || "MoveDown".equals(s3))
            {
                java.io.Serializable aserializable[] = {
                    oapagecontext.getParameter("related_link_id"), s3
                };
                java.lang.Class aclass[] = {
                    java.lang.String.class, java.lang.String.class
                };
                oapagecontext.getApplicationModule(oawebbean).invokeMethod("moveRow", aserializable, aclass);
            }
            if("goto".equals(oapagecontext.getParameter("event")) && "CustomizeNavBar".equals(oapagecontext.getParameter("source")))
            {
                if("2".equals(oapagecontext.getParameter("value")))
                    oapagecontext.setRedirectURL("OA.jsp?akRegionCode=BIS_PMV_UI_PARAMETERS_REGION&akRegionApplicationId=191" + stringbuffer.toString(), true);
                if("1".equals(oapagecontext.getParameter("value")))
                {
                    oapagecontext.setRedirectURL("OA.jsp?akRegionCode=BIS_PMV_UI_PARAMETERS_REGION&akRegionApplicationId=191" + stringbuffer.toString(), true);
                    return;
                }
            } else
            {
                java.lang.String s7 = oapagecontext.getParameter("_FORM_SUBMIT_BUTTON");
                if("cancelButton".equals(s7))
                {
                    getApplicationModule(oapagecontext, oawebbean).getOADBTransaction().rollback();
                    oracle.apps.bis.pmv.customize.webui.TableCO.removeAdvancedSettingsSessionValues(oapagecontext);
                    oapagecontext.removeSessionValue("functionID");
                    if(linksbuilder != null)
                    {
                        linksbuilder.getBuilderContext().getNavigationContext().setCancel(true);
                        oracle.apps.bis.common.SessionObjectManager sessionobjectmanager = new SessionObjectManager(oapagecontext);
                        sessionobjectmanager.removeValue(s5);
                        linksbuilder.returnToCaller(oapagecontext, false);
                    } else
                    {
                        java.lang.String s1;
                        if("Y".equals(oapagecontext.getSessionValue("fromPortal")))
                        {
                            s1 = (java.lang.String)oapagecontext.getSessionValue("backUrl");
                        } else
                        {
                            if("Y".equals(oapagecontext.getSessionValue("fromRelated")))
                                s1 = oapagecontext.getProfile("APPS_FRAMEWORK_AGENT");
                            else
				{
                                s1 = oracle.apps.bis.pmv.common.PMVUtil.getJspUrl(oapagecontext.getProfile("APPS_SERVLET_AGENT"));
 				s1 = s1 +"../XXCRM_HTML/"; 
				}

                            s1 = s1 + oapagecontext.getSessionValue("backUrl");
                        }
                        try
                        {
                            oapagecontext.sendRedirect(s1);
                        }
                        catch(java.io.IOException _ex) { }
                    }
                }
                if("finishButton".equals(s7))
                {
                    java.lang.String s8 = (java.lang.String)oapagecontext.getSessionValue("functionID");
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s8))
                    {
                        java.lang.String s9 = (java.lang.String)oapagecontext.getSessionValue("reportTitle");
                        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s9))
                        {
                            java.io.Serializable aserializable1[] = {
                                s8, s9
                            };
                            java.lang.Class aclass1[] = {
                                java.lang.String.class, java.lang.String.class
                            };
                            try
                            {
                                getApplicationModule(oapagecontext, oawebbean).invokeMethod("updatePortletTitle", aserializable1, aclass1);
                            }
                            catch(oracle.apps.fnd.framework.OAException _ex) { }
                        }
                        java.io.Serializable aserializable2[] = {
                            s8
                        };
                        java.lang.Class aclass2[] = {
                            java.lang.String.class
                        };
                        try
                        {
                            getApplicationModule(oapagecontext, oawebbean).invokeMethod("stalePortlet", aserializable2, aclass2);
                        }
                        catch(oracle.apps.fnd.framework.OAException _ex) { }
                    }
                    getApplicationModule(oapagecontext, oawebbean).getOADBTransaction().commit();
                    oracle.apps.bis.pmv.customize.webui.TableCO.removeAdvancedSettingsSessionValues(oapagecontext);
                    oapagecontext.removeSessionValue("functionID");
                    if(linksbuilder != null)
                    {
                        linksbuilder.getBuilderContext().getNavigationContext().setFinish(true);
                        oracle.apps.bis.common.SessionObjectManager sessionobjectmanager1 = new SessionObjectManager(oapagecontext);
                        sessionobjectmanager1.removeValue(s5);
                        linksbuilder.returnToCaller(oapagecontext, false);
                        return;
                    }
                    try
                    {
                        java.lang.String s2;
                        if("Y".equals(oapagecontext.getSessionValue("fromPortal")))
                        {
                            s2 = (java.lang.String)oapagecontext.getSessionValue("backUrl");
                        } else
                        {
                            if("Y".equals(oapagecontext.getSessionValue("fromRelated")))
                                s2 = oapagecontext.getProfile("APPS_FRAMEWORK_AGENT");
                            else
				{
                                s2 = oracle.apps.bis.pmv.common.PMVUtil.getJspUrl(oapagecontext.getProfile("APPS_SERVLET_AGENT"));
 				s2 = s2 +"../XXCRM_HTML/"; 
				}

                            s2 = s2 + oapagecontext.getSessionValue("backUrl");
                        }
                        if("Y".equals(oapagecontext.getParameter("designer")))
                            s2 = s2 + "&designer=Y";
                        oapagecontext.sendRedirect(s2);
                        return;
                    }
                    catch(java.io.IOException _ex)
                    {
                        return;
                    }
                }
                if(oapagecontext.getParameter("NAVIGATE") != null && !"".equals(oapagecontext.getParameter("NAVIGATE")))
                    try
                    {
                        oapagecontext.sendRedirect(oapagecontext.getParameter("NAVIGATE"));
                        return;
                    }
                    catch(java.io.IOException _ex)
                    {
                        return;
                    }
                processSubmitButtons(oapagecontext, stringbuffer.toString());
            }
            return;
        }
        if(flag || "Y".equals(oapagecontext.getParameter("designer")))
            processSubmitButtons(oapagecontext, stringbuffer.toString());
    }

    private void processSubmitButtons(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        java.lang.String s1 = (java.lang.String)oapagecontext.getSessionValue("functionID");
        stringbuffer.append("&akRegionApplicationId=191&retainAM=Y&functionID=").append(s1);
        java.lang.String s2 = (java.lang.String)oapagecontext.getSessionValue("customLevel");
        s2 = s2 != null ? s2 : "";
        java.lang.String s3 = (java.lang.String)oapagecontext.getSessionValue("customLevelValue");
        s3 = s3 != null ? s3 : "";
        stringbuffer.append("&customLevel=").append(s2);
        stringbuffer.append("&customLevelValue=").append(s3);
        java.lang.String s4 = oapagecontext.getParameter("builderKey");
        stringbuffer.append("&").append("builderKey").append("=").append(s4);
        java.lang.String s5 = oapagecontext.getParameter("designer");
        if("Y".equals(s5))
            stringbuffer.append("&designer=Y");
        boolean flag = false;
        java.lang.String s6 = (java.lang.String)oapagecontext.getSessionValue("fromPreseed");
        if(s6 == null || s6.length() == 0)
            s6 = oapagecontext.getParameter("fromPreseed");
        flag = s6 != null ? "Y".equalsIgnoreCase(s6) : false;
        if(flag)
        {
            java.lang.String s7 = oapagecontext.getParameter("reportTitle");
            s7 = s7 != null ? s7 : (java.lang.String)oapagecontext.getSessionValue("reportTitle");
            s7 = s7 != null ? s7 : "";
            stringbuffer.append("&fromPreseed=Y&reportTitle=").append(oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, s7));
        }
        stringbuffer.append(s.toString());
        if(oapagecontext.getParameter("addUrlButton") != null)
        {
            java.lang.StringBuffer stringbuffer1 = new StringBuffer(500);
            stringbuffer1.append("OA.jsp?akRegionCode=BISPMVRLADDURLPAGE");
            stringbuffer1.append(stringbuffer.toString());
            oapagecontext.setRedirectURL(stringbuffer1.toString(), true);
            return;
        }
        if(oapagecontext.getParameter("addRptsWkbksButton") != null)
        {
            java.lang.StringBuffer stringbuffer2 = new StringBuffer(500);
            stringbuffer2.append("OA.jsp?akRegionCode=BISPMVRLREPORTSWORKBOOKSPAGE");
            stringbuffer2.append(stringbuffer.toString());
            oapagecontext.setRedirectURL(stringbuffer2.toString(), true);
            return;
        }
        if(oapagecontext.getParameter("changeOrderButton") != null)
        {
            java.lang.StringBuffer stringbuffer3 = new StringBuffer(500);
            stringbuffer3.append("OA.jsp?akRegionCode=BISPMVRLCHANGEORDERPAGE");
            stringbuffer3.append(stringbuffer.toString());
            oapagecontext.setRedirectURL(stringbuffer3.toString(), true);
        }
    }

    public ODRelatedLinksListHdrCO()
    {
    }

    public static final java.lang.String RCS_ID = "$Header: RelatedLinksListHdrCO.java 115.55 2006/08/10 11:17:31 visuri noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: RelatedLinksListHdrCO.java 115.55 2006/08/10 11:17:31 visuri noship $", "oracle.apps.bis.pmv.customize.webui");

}
