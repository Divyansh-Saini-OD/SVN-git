// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODPMVParameterBean.java

package od.oracle.apps.xxcrm.bis.pmv.parameters;

import oracle.apps.bis.pmv.parameters.*;
import com.sun.java.util.collections.Map;
import java.util.Hashtable;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.common.Util;
import oracle.apps.bis.common.VersionConstants;
import oracle.apps.bis.html.ColumnLayout;
import oracle.apps.bis.html.FlowLayout;
import oracle.apps.bis.html.HTMLObject;
import oracle.apps.bis.html.SectionLayout;
import oracle.apps.bis.pmv.common.DelegationHelper;
import od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil;
import oracle.apps.bis.pmv.common.PMVConstants;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.lov.LovDataHolder;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.session.RequestInfo;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.AppsContext;
import oracle.apps.fnd.common.Context;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.ProfileStore;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.cabo.share.url.EncoderUtils;

// Referenced classes of package oracle.apps.bis.pmv.parameters:
//            ComboBoxParameterSection, JavaScriptHelper, ParameterHelper, ODParameterOrganizer,
//            ParameterSection, ParameterUtil, Parameters

public class ODPMVParameterBean
    implements oracle.apps.bis.html.HTMLObject
{

    public ODPMVParameterBean(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        m_AKRegionCode = "";
        m_ParameterDisplayOnly = "N";
        m_Email = "N";
        m_Designer = "N";
        m_EditParamLinkEnable = false;
        m_IsAsOfDateHidden = false;
        m_UserSession = usersession;
        init();
    }

    private void init()
    {
        m_WebAppsContext = m_UserSession.getWebAppsContext();
        if(m_UserSession.getPageContext() != null)
        {
            m_Request = (javax.servlet.http.HttpServletRequest)m_UserSession.getPageContext().getRequest();
            m_Email = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "email");
            m_Designer = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "designer");
        }
        m_RequestInfo = m_UserSession.getRequestInfo();
        if(m_UserSession.getParameterHelper() == null)
        {
            oracle.apps.bis.pmv.parameters.ParameterHelper parameterhelper = new ParameterHelper(m_UserSession, m_UserSession.getConnection());
            m_UserSession.setParameterHelper(parameterhelper);
        }
        if(m_UserSession.isLovReport())
        {
            oracle.apps.bis.pmv.metadata.AKRegion akregion = m_UserSession.getAKRegion();
            m_UserSession.setAKRegion(m_UserSession.getLovDataHolder().getAKRegion());
            oracle.apps.bis.pmv.common.DelegationHelper.setupSelectedTopManager(m_UserSession, m_UserSession.getParameterHelper());
            m_UserSession.setAKRegion(akregion);
        } else
        {
            oracle.apps.bis.pmv.common.DelegationHelper.setupSelectedTopManager(m_UserSession, m_UserSession.getParameterHelper());
        }
        m_ParameterDisplayOnly = m_RequestInfo.getParameterDisplayOnly();
        if("Y".equals(m_Designer) || m_UserSession.isPersonalizeMode())
            m_OAFormExist = true;
        m_EDW = m_UserSession.getAKRegion().isEDW();
        m_OLTP = !m_EDW && m_UserSession.getAKRegion().hasMeasures();
        m_HasNestedRegion = !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_UserSession.getAKRegion().getPageParameterRegionName());
        m_ParamLayoutType = m_UserSession.getAKRegion().getParameterLayoutType();
        m_DBI = m_HasNestedRegion || m_UserSession.getAKRegion().hasAsOfDate() || "3".equals(m_ParamLayoutType);
        m_ParamPortlet = "P".equals(m_RequestInfo.getRequestType());
        m_IsDispRun = "Y".equals(m_RequestInfo.getDispRun());
        if(m_UserSession.getAKRegion() != null)
            m_AKRegionCode = m_UserSession.getAKRegion().getAKRegionName();
    }

    public void setEditParamLinkEnabled(java.lang.String s)
    {
        if("Y".equals(s))
            m_EditParamLinkEnable = true;
    }

    public java.lang.String toHTMLString()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(2000);
        if(m_Request != null)
        {
            java.lang.String s = null;
            if(m_UserSession.getPageContext() != null)
            {
                s = (java.lang.String)m_UserSession.getPageContext().getSession().getValue("DrillDefaultParameters");
                m_UserSession.getPageContext().getSession().removeValue("DrillDefaultParameters");
            }
            boolean flag = m_RequestInfo.isDesignerPreview();
            if((!oracle.apps.bis.pmv.common.StringUtil.emptyString(s) || flag) && !m_ParamPortlet)
                stringbuffer.append(getWarningsHtml(s, flag));
        }
        stringbuffer.append(oracle.apps.bis.pmv.parameters.ParameterUtil.getDateRelatedScripts(m_UserSession));
        stringbuffer.append(oracle.apps.bis.pmv.parameters.ParameterUtil.getScripts());
        if(!m_RequestInfo.isPrintable() && !"Y".equals(m_Email) && !m_UserSession.isScheduleMode() && m_Request != null)
        {
            stringbuffer.append("<SPAN class=\"pmvHiddenLabel\">");
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_ASOFDATE_ALT", m_WebAppsContext));
            stringbuffer.append("</SPAN>");
            stringbuffer.append(getFormString());
        }
        if(m_UserSession.isScheduleMode() || m_EDW || m_OLTP)
            stringbuffer.append("<TABLE WIDTH=100%><TR><TD WIDTH=25%>");
        if(m_RequestInfo.isLovReport() && "SWAN".equals("409"))
            stringbuffer.append("<div id=\"pmvParamSection\" style=\"background-color:#eaeff5\" >");
        else
            stringbuffer.append("<div id=\"pmvParamSection\">");
        stringbuffer.append(getDivContent());
        stringbuffer.append("</div>");
        if(m_UserSession.isScheduleMode() || m_EDW || m_OLTP)
            stringbuffer.append("</TD><TD></TD></TR></TABLE>");
        if("SWAN".equals("409") && m_ParamInfo != null && m_ParamInfo.get("AS_OF_DATE") != null && !"BIS_BIA_RSG_PSTATE_REPORT".equals(m_AKRegionCode))
            stringbuffer.append(getAsOfDateHtml((oracle.apps.bis.pmv.parameters.Parameters)m_ParamInfo.get("AS_OF_DATE")));
        if(!m_RequestInfo.isPrintable() && !"Y".equals(m_Email) && !m_UserSession.isScheduleMode() && m_Request != null && !m_OAFormExist)
            stringbuffer.append("</FORM>");
        try
        {
            if(m_EditParamLinkEnable)
            {
                m_EditParamLinkEnable = false;
                stringbuffer.append("</FORM>");
            }
        }
        catch(java.lang.Exception _ex)
        {
            m_EditParamLinkEnable = false;
        }
        stringbuffer.append("<SCRIPT>");
        stringbuffer.append("if (document.forms.length == '1') {");
        stringbuffer.append("  G_ParameterFormIndex = 0;");
        stringbuffer.append("} else {");
        stringbuffer.append("  for(var i=0; i<document.forms.length; i++)");
        stringbuffer.append("  { ");
        stringbuffer.append("    if(document.forms[i].name == 'pmvParameterForm')");
        stringbuffer.append("      break;");
        stringbuffer.append("    if(document.forms[i].pmvFormAction != null)");
        stringbuffer.append("    {");
        stringbuffer.append("      document.forms[i].method = 'POST';");
        stringbuffer.append("      break;");
        stringbuffer.append("    }");
        stringbuffer.append("  }");
        stringbuffer.append("  G_ParameterFormIndex = i;");
        stringbuffer.append("}");
        stringbuffer.append("G_ParameterForm = document.forms[G_ParameterFormIndex];");
        stringbuffer.append("</SCRIPT>");
        if(!m_UserSession.isScheduleMode() && !m_UserSession.isPersonalizeMode() && !m_UserSession.isPersonalizePortletMode() && !m_UserSession.isSONAR() && !m_UserSession.isFromConc() && !m_UserSession.isPMVPlotterMode())
            if(!"1".equals(m_RequestInfo.getFirstTime()) || m_ParamPortlet)
            {
                if(!"SWAN".equals("409"))
                    stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getDottedLine(m_UserSession));
            } else
            {
                stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getSkiImage(m_UserSession, m_WebAppsContext));
            }
        return stringbuffer.toString();
    }

    public java.lang.String getDivContent()
    {
        od.oracle.apps.xxcrm.bis.pmv.parameters.ODParameterOrganizer parameterorganizer = new ODParameterOrganizer(m_UserSession);
        com.sun.java.util.collections.List list = parameterorganizer.getParameterObjects();
        m_ParamInfo = parameterorganizer.getParamInfo();
        m_IsAsOfDateHidden = parameterorganizer.isAsOfDateHidden();
        java.lang.Object obj = null;
        java.lang.Object obj1 = null;
        if(m_ParamPortlet && ("Y".equals(m_ParameterDisplayOnly) && "1".equals(m_ParamLayoutType) || !oracle.apps.bis.pmv.parameters.ParameterUtil.hasSalesGroupParam(list) && parameterorganizer.getVisibleCount() < 6))
            obj = new FlowLayout();
        else
        if(!m_ParamPortlet && !m_DBI && (m_UserSession.isScheduleMode() || m_EDW))
            obj = new ColumnLayout(1);
        else
        if(!m_ParamPortlet && !m_DBI)
            obj = new ColumnLayout(2);
        else
            obj = new ColumnLayout(3);
        if(m_UserSession.isGoReport() && (m_UserSession.getRequestInfo() == null || !"BSC".equals(m_UserSession.getRequestInfo().getMode())))
        {
            java.lang.String s = "javascript:doSubmit('RUN');";
            java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_GO_REPORT", m_WebAppsContext);
            java.lang.String s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getButtonHTML(s, s1, s1, s1, m_WebAppsContext, m_UserSession.getApplication(), m_UserSession);
            java.lang.StringBuffer stringbuffer = new StringBuffer(100);
            stringbuffer.append("<TR><td></td><td>").append(s2).append("</td></TR>");
            ((oracle.apps.bis.html.SectionLayout) (obj)).setExtraHTML(stringbuffer.toString());
        }
        if(m_RequestInfo.isPrintable() || "Y".equals(m_ParameterDisplayOnly) && !m_EditParamLinkEnable || m_UserSession.isScheduleMode())
            obj1 = new ParameterSection(list, ((oracle.apps.bis.html.SectionLayout) (obj)));
        else
            obj1 = new ComboBoxParameterSection(list, ((oracle.apps.bis.html.SectionLayout) (obj)));
        return ((oracle.apps.bis.pmv.parameters.ParameterSection) (obj1)).toHTMLString();
    }

    private java.lang.String getWarningsHtml(java.lang.String s, boolean flag)
    {
        java.lang.String as[] = null;
        java.lang.String as1[] = null;
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
            as1 = getDrillWarningMessages(s);
        if(flag)
        {
            if(as1 == null)
                as1 = new java.lang.String[0];
            as = new java.lang.String[as1.length + 1];
            as[0] = getDesignerPreviewWarning();
            java.lang.System.arraycopy(as1, 0, as, 1, as1.length);
        } else
        {
            as = as1;
        }
        if(as == null)
            return "";
        else
            return oracle.apps.bis.common.Util.getPageMessageHTML(as, oracle.apps.bis.common.Util.getMessage("BIS_WARNING", m_WebAppsContext), "OraHeaderSubSub", m_WebAppsContext.getCurrLangCode());
    }

    private java.lang.String getDesignerPreviewWarning()
    {
        return oracle.apps.bis.common.Util.getMessage("BIS_REPORT_PREVIEW_WARNING", m_WebAppsContext);
    }

    private java.lang.String[] getDrillWarningMessages(java.lang.String s)
    {
        java.lang.String s1 = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        java.lang.String as[] = getDecodedStrings(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValues(s, "pDrillParamName"), s1);
        java.lang.String as1[] = getDecodedStrings(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValues(s, "pDrillPrevDesc"), s1);
        java.lang.String as2[] = getDecodedStrings(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValues(s, "pDrillCurrentDesc"), s1);
        java.lang.String as3[] = null;
        boolean flag = false;
        for(int i = 0; i < as.length; i++)
            if(m_UserSession != null && m_UserSession.getAKRegion() != null && m_UserSession.getAKRegion().getAKRegionItems() != null && m_UserSession.getAKRegion().getAKRegionItems().get(as[i]) != null)
            {
                flag = true;
            } else
            {
                as[i] = null;
                as1[i] = null;
                as2[i] = null;
            }

        if(!flag)
            return null;
        java.util.Hashtable hashtable = m_UserSession.getAKRegion().getAKRegionItems();
        Object obj = null;
        java.lang.String as4[] = null;
        if(as != null)
        {
            as3 = new java.lang.String[as.length];
            as4 = new java.lang.String[as.length];
            for(int j = 0; j < as.length; j++)
                if(hashtable != null && as[j] != null)
                {
                    oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)hashtable.get(as[j]);
                    if(akregionitem != null)
                        as3[j] = akregionitem.getAttributeNameLong();
                }

        }
        oracle.apps.fnd.common.MessageToken amessagetoken[] = new oracle.apps.fnd.common.MessageToken[4];
        if(as != null)
        {
            boolean flag1 = "Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "designer"));
            boolean flag2 = "Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "designerPreview"));
            java.lang.String as5[] = getDecodedStrings(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValues(s, "pIsDrillParameter"), s1);
            boolean flag3 = true;
            if(as5 != null && as5.length > 0)
                flag3 = !"N".equalsIgnoreCase(as5[0]);
            for(int k = 0; k < as.length; k++)
                if(as[k] != null)
                {
                    amessagetoken[0] = new MessageToken("PARAM_NAME", as3[k]);
                    amessagetoken[1] = new MessageToken("PARAM_VALUE", as1[k]);
                    amessagetoken[2] = new MessageToken("PAGE_REPORT", "BIS_REPORT", true);
                    amessagetoken[3] = new MessageToken("PARAM_DEF_VALUE", as2[k]);
                    if(flag1 || flag2)
                        as4[k] = oracle.apps.bis.common.Util.getMessage("BIS_PARAM_VALID_WARN_DESIGN", new oracle.apps.fnd.common.MessageToken[] {
                            amessagetoken[0], amessagetoken[1]
                        }, m_WebAppsContext);
                    else
                    if(flag3)
                        as4[k] = oracle.apps.bis.common.Util.getMessage("BIS_PARAMETER_VALIDATION_WARN", amessagetoken, m_WebAppsContext);
                    else
                    if(oracle.apps.bis.pmv.common.StringUtil.emptyString(as2[k]))
                        as4[k] = oracle.apps.bis.common.Util.getMessage("BIS_PARAM_EMPTY_VALUE_WARN", new oracle.apps.fnd.common.MessageToken[] {
                            amessagetoken[0], amessagetoken[1], amessagetoken[2]
                        }, m_WebAppsContext);
                    else
                        as4[k] = oracle.apps.bis.common.Util.getMessage("BIS_PARAM_WRONG_VALUE_WARN", amessagetoken, m_WebAppsContext);
                }

        }
        return as4;
    }

    private java.lang.String getFormString()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(400);
        java.lang.String s = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        java.lang.String s1 = "pmvParameterForm";
        if(m_UserSession.isPMVPlotterMode())
            s1 = "parameterForm";
        java.lang.String s2 = m_UserSession.getRequestInfo().getFormSubmitUrl();
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
            s2 = getActionUrl();
        if(!m_OAFormExist)
        {
            stringbuffer.append("<FORM class=DbiParameterTable style=\"DISPLAY: inline\" NAME=");
            stringbuffer.append(s1).append(" ACTION=\"");
            if(m_UserSession.isPMVPlotterMode())
                stringbuffer.append(s2);
            stringbuffer.append("\" METHOD=POST>");
        }
        stringbuffer.append("<INPUT TYPE=hidden name=pmvFormAction value=\"").append(s2).append("\">");
        if("Y".equals(m_Designer))
            stringbuffer.append("<INPUT TYPE=hidden name=designer value=").append(m_Designer).append(">");
        if(m_ParamPortlet)
            stringbuffer.append("<INPUT TYPE=hidden NAME=pSubmit VALUE=\"SAVEPAGEPARAM\">");
        else
            stringbuffer.append("<INPUT TYPE=hidden NAME=pSubmit VALUE=\"RUN\">");
        stringbuffer.append("<INPUT TYPE=hidden NAME=pRegionCode VALUE=").append(od.oracle.apps.xxcrm.bis.pmv.parameters.ODPMVParameterBean.getEncodeString(m_UserSession.getRegionCode(), s)).append(">");
        stringbuffer.append("<INPUT TYPE=hidden name=pUserId value=").append(m_UserSession.getUserId()).append(">");
        stringbuffer.append("<INPUT TYPE=hidden name=pFirstTime value=\"");
        if(m_RequestInfo.getFirstTime() != null)
            stringbuffer.append(m_RequestInfo.getFirstTime());
        else
            stringbuffer.append("1");
        stringbuffer.append("\">");
        stringbuffer.append("<INPUT TYPE=hidden name=showSchedule value=");
        stringbuffer.append(m_RequestInfo.getShowSchedule()).append(">");
        stringbuffer.append("<INPUT TYPE=hidden name=parameterDisplayOnly value=");
        stringbuffer.append(m_ParameterDisplayOnly).append(">");
        stringbuffer.append("<INPUT TYPE=hidden name=displayParameters value=");
        stringbuffer.append(m_RequestInfo.getDisplayParameters()).append(">");
        java.lang.String s3 = m_RequestInfo.getCSVFileName();
        if(s3 != null && s3.length() > 0)
            stringbuffer.append("<INPUT TYPE=hidden name=pCSVFileName value=").append(s3).append(">");
        if(m_RequestInfo.isForecastGraphEnabled())
            stringbuffer.append("<INPUT TYPE=hidden NAME=pEnableForecastGraph VALUE=Y>");
        stringbuffer.append("<INPUT TYPE=hidden NAME=").append("pParamSelected").append(" VALUE=\"");
        java.lang.String s4 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pParamSelected");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s4))
            stringbuffer.append(s4);
        stringbuffer.append("\">");
        stringbuffer.append("<INPUT TYPE=hidden name=pSubmitField value=\"\">");
        stringbuffer.append("<INPUT TYPE=hidden name=pSubmitMode value=\"\">");
        stringbuffer.append("<INPUT TYPE=hidden name=pButtonClicked value=\"\">");
        stringbuffer.append("<INPUT TYPE=hidden name=pPersReturnUrl value=\"\">");
        stringbuffer.append("<INPUT TYPE=hidden NAME=pCustomView VALUE=\"");
        if(m_RequestInfo.getCustomViewName() != null)
            stringbuffer.append(m_RequestInfo.getCustomViewName());
        stringbuffer.append("\">");
        java.lang.String s5 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pBCFromFunctionName");
        boolean flag = m_UserSession.getFunctionName().equals(s5);
        if(m_UserSession.isDrillMode() || m_UserSession.isResetParamDefault() || !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_UserSession.getDrillResetParams()))
        {
            Object obj = null;
            if(!flag || !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_UserSession.getDrillResetParams()))
            {
                java.lang.String s6;
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_UserSession.getDrillResetParams()))
                    s6 = m_UserSession.getDrillResetParams();
                else
                    s6 = oracle.apps.bis.pmv.parameters.ParameterUtil.getDrillResetParams(m_UserSession);
                if(s6 != null && s6.length() > 0)
                    stringbuffer.append("<INPUT TYPE=hidden NAME=drillResetParams VALUE=\"").append(od.oracle.apps.xxcrm.bis.pmv.parameters.ODPMVParameterBean.getEncodeString(s6, s)).append("\">");
            }
        }
        stringbuffer.append("<INPUT TYPE=hidden NAME=pDispRun VALUE=\"");
        if(m_RequestInfo.getDispRun() != null)
            stringbuffer.append(m_RequestInfo.getDispRun());
        stringbuffer.append("\">");
        stringbuffer.append("<INPUT TYPE=hidden NAME=pResponsibilityId VALUE=").append(m_WebAppsContext.getRespId()).append(">");
        stringbuffer.append("<INPUT TYPE=hidden NAME=_pageid VALUE=").append(m_RequestInfo.getPageId()).append(">");
        stringbuffer.append("<INPUT TYPE=hidden NAME=_page_url VALUE=").append(m_RequestInfo.getPageURL()).append(">");
        if(m_UserSession.isPersonalizePortletMode())
            addPersonalizeFormString(stringbuffer, s);
        java.lang.String s7 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "displayOnlyParameters");
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s7))
            s7 = m_UserSession.getDisplayOnlyParameters();
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s7))
            stringbuffer.append("<INPUT TYPE=hidden NAME=displayOnlyParameters VALUE=\"").append(od.oracle.apps.xxcrm.bis.pmv.parameters.ODPMVParameterBean.getEncodeString(s7, s)).append("\">");
        java.lang.String s8 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "displayOnlyNoViewByParams");
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s8))
            s8 = m_UserSession.getDisplayOnlyNoViewByParams();
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s8))
            stringbuffer.append("<INPUT TYPE=hidden NAME=displayOnlyNoViewByParams VALUE=\"").append(od.oracle.apps.xxcrm.bis.pmv.parameters.ODPMVParameterBean.getEncodeString(s8, s)).append("\">");
        stringbuffer.append("<INPUT TYPE=hidden NAME=").append("persNoOfRows");
        stringbuffer.append(" VALUE=>");
        stringbuffer.append("<INPUT TYPE=hidden NAME=").append("viewAction").append(" VALUE=\"");
        java.lang.String s9 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "viewAction");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s9))
            stringbuffer.append(s9);
        stringbuffer.append("\">");
        if("0".equals(m_RequestInfo.getFirstTime()))
        {
            int i = m_RequestInfo.getLowerBound();
            int j = m_RequestInfo.getUpperBound();
            oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "cached");
            java.lang.String s11 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "nextset");
            java.lang.String s12 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "prevset");
            java.lang.String s13 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "setstart");
            java.lang.String s14 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "startrow");
            java.lang.String s15 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "tablePopListUpper");
            java.lang.String s16 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "tablePopListLower");
            if(s12 == null)
                s12 = "false";
            if(s11 == null)
                s11 = "false";
            if(s13 == null)
                s13 = "";
            if(s14 == null)
                s14 = "";
            if(s15 == null)
                s15 = "";
            if(s16 == null)
                s16 = "";
            java.lang.String s17 = m_RequestInfo.getNavMode();
            java.lang.String s18 = m_RequestInfo.getSortAttribute();
            java.lang.String s19 = m_RequestInfo.getSortDirection();
            new JavaScriptHelper(s18, s19);
            stringbuffer.append("<INPUT TYPE=hidden NAME=navMode VALUE=\"").append(s17).append("\">");
            stringbuffer.append("<INPUT TYPE=hidden NAME=lowerBound VALUE=\"").append(i).append("\">");
            stringbuffer.append("<INPUT TYPE=hidden NAME=upperBound VALUE=\"").append(j).append("\">");
            stringbuffer.append("<INPUT TYPE=hidden NAME=tablePopListUpper VALUE=\"").append(s15).append("\">");
            stringbuffer.append("<INPUT TYPE=hidden NAME=tablePopListLower VALUE=\"").append(s16).append("\">");
            stringbuffer.append("<INPUT TYPE=hidden NAME=startrow VALUE=\"").append(s14).append("\">");
            stringbuffer.append("<INPUT TYPE=hidden NAME=nextset VALUE=\"").append(s11).append("\">");
            stringbuffer.append("<INPUT TYPE=hidden NAME=prevset VALUE=\"").append(s12).append("\">");
            stringbuffer.append("<INPUT TYPE=hidden NAME=setstart VALUE=\"").append(s13).append("\">");
            stringbuffer.append("<INPUT TYPE=hidden NAME=sortAttribute VALUE=\"").append(s18).append("\">");
            stringbuffer.append("<INPUT TYPE=hidden NAME=sortDirection VALUE=\"").append(s19).append("\">");
            if("PORTLET".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pObjectType")))
                stringbuffer.append("<INPUT TYPE=hidden NAME=pObjectType VALUE=\"PORTLET\">");
        }
        if("Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "hideNav")))
            stringbuffer.append("<INPUT TYPE=hidden NAME=").append("hideNav").append(" VALUE=\"Y\">");
        if("Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "tab")))
            stringbuffer.append("<INPUT TYPE=hidden NAME=").append("tab").append(" VALUE=\"Y\">");
        if(m_RequestInfo.isLovReport())
        {
            stringbuffer.append("<INPUT TYPE=hidden NAME=pReportType VALUE=\"").append("LOV").append("\">");
            java.lang.String s10 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pLovAttribute");
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s10))
                s10 = m_UserSession.getLovDataHolder().getLovAttribute();
            stringbuffer.append("<INPUT TYPE=hidden NAME=pLovAttribute VALUE=\"").append(s10).append("\">");
        }
        stringbuffer.append("<INPUT TYPE=hidden name=designerPreview value=\"");
        stringbuffer.append(m_RequestInfo.getDesignerPreview());
        stringbuffer.append("\">");
        stringbuffer.append(getParamScript());
        return stringbuffer.toString();
    }

    private java.lang.String getActionUrl()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        java.lang.String s = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        if(m_ParamPortlet)
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.trail_slash(m_WebAppsContext.getProfileStore().getProfile("APPS_FRAMEWORK_AGENT")));
        else
            stringbuffer.append("/");
        stringbuffer.append("XXCRM_HTML/bisviewm.jsp?dbc=").append(m_RequestInfo.getDBC());
        stringbuffer.append("&transactionid=").append(m_RequestInfo.getTxId());
        stringbuffer.append("&sessionid=").append(m_WebAppsContext.getCurrentSessionId());
        stringbuffer.append("&regionCode=").append(od.oracle.apps.xxcrm.bis.pmv.parameters.ODPMVParameterBean.getEncodeString(m_UserSession.getRegionCode(), s));
        stringbuffer.append("&functionName=").append(od.oracle.apps.xxcrm.bis.pmv.parameters.ODPMVParameterBean.getEncodeString(m_UserSession.getFunctionName(), s));
        if(m_UserSession.getXmlReport() != null)
            stringbuffer.append("&reportName=").append(od.oracle.apps.xxcrm.bis.pmv.parameters.ODPMVParameterBean.getEncodeString(m_UserSession.getXmlReport(), s));
        if(m_UserSession.getMaxResultSetSize() > -1)
            stringbuffer.append("&pMaxResultSetSize=").append(m_UserSession.getMaxResultSetSize());
        stringbuffer.append("&").append("bk").append("=1");
        java.lang.String s1 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "autoRefresh");
        if("Y".equals(s1))
            stringbuffer.append("&autoRefresh=Y&pFirstTime=0");
        if("Y".equals(m_Designer))
            stringbuffer.append("&designer=Y");
        return stringbuffer.toString();
    }

    private static java.lang.String getEncodeString(java.lang.String s, java.lang.String s1)
    {
        try
        {
            return oracle.cabo.share.url.EncoderUtils.encodeString(s, s1);
        }
        catch(java.lang.Exception _ex)
        {
            return s;
        }
    }

    private java.lang.String[] getDecodedStrings(java.lang.String as[], java.lang.String s)
    {
        if(as == null)
            return as;
        java.lang.String as1[] = new java.lang.String[as.length];
        for(int i = 0; i < as.length; i++)
            try
            {
                as1[i] = oracle.cabo.share.url.EncoderUtils.decodeString(as[i], s);
            }
            catch(java.lang.Exception _ex)
            {
                as1[i] = as[i];
            }

        return as1;
    }

    public void addPersonalizeFormString(java.lang.StringBuffer stringbuffer, java.lang.String s)
    {
        java.lang.String s1 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pTrendType");
        stringbuffer.append("<INPUT TYPE=hidden NAME=pTrendType VALUE=\"").append(s1).append("\">");
        java.lang.String s2 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pPlugId");
        stringbuffer.append("<INPUT TYPE=hidden NAME=pPlugId VALUE=\"").append(s2).append("\">");
        java.lang.String s3 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pScheduleId");
        stringbuffer.append("<INPUT TYPE=hidden NAME=pScheduleId VALUE=\"").append(s3).append("\">");
        java.lang.String s4 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pFileId");
        if(s4 != null)
            stringbuffer.append("<INPUT TYPE=hidden NAME=pFileId VALUE=\"").append(s4).append("\">");
        java.lang.String s5 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pGraphNumber");
        if(s5 == null)
            s5 = "";
        stringbuffer.append("<INPUT TYPE=hidden NAME=pGraphNumber VALUE=\"").append(s5).append("\">");
        java.lang.String s6 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pReportTitle");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s6))
            s6 = od.oracle.apps.xxcrm.bis.pmv.parameters.ODPMVParameterBean.getEncodeString(s6, s);
        stringbuffer.append("<INPUT TYPE=hidden NAME=pReportTitle VALUE=\"").append(s6).append("\">");
        java.lang.String s7 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pParameterDisplayOnly");
        stringbuffer.append("<INPUT TYPE=hidden NAME=pParameterDisplayOnly VALUE=\"").append(s7).append("\">");
        java.lang.String s8 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pReturnURL");
        stringbuffer.append("<INPUT TYPE=hidden NAME=pReturnURL VALUE=\"").append(s8).append("\">");
        if(m_EditParamLinkEnable)
            stringbuffer.append("<INPUT TYPE=hidden NAME=pEditParamLinkEnable VALUE=\"Y\" >");
        java.lang.String s9 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pComponentType");
        stringbuffer.append("<INPUT TYPE=hidden NAME=pComponentType VALUE=\"").append(s9).append("\">");
        if("KPI_PORTLET".equals(s9))
        {
            java.lang.String s10 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pMsrId");
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s10))
            {
                java.lang.String s11 = oracle.apps.bis.common.Util.getRegionCodeForKPI(s10, m_UserSession.getConnection());
                java.lang.String s12 = oracle.apps.bis.common.Util.getFxnNameForKPI(s11, m_UserSession.getConnection());
                stringbuffer.append("<INPUT TYPE=hidden NAME=pRegionCodeForKPI VALUE=\"").append(s11).append("\">");
                stringbuffer.append("<INPUT TYPE=hidden NAME=pFxnNameForKPI VALUE=\"").append(s12).append("\">");
            }
        }
    }

    private java.lang.String getParamScript()
    {
        boolean flag = false;
        if("0".equals(m_RequestInfo.getFirstTime()) && !m_RequestInfo.isPrintable() && ("R".equals(m_RequestInfo.getRequestType()) || "".equals(m_RequestInfo.getRequestType())))
            flag = true;
        boolean flag1 = m_UserSession.getParameterHelper().isAsOfDateHidden();
        boolean flag2 = m_UserSession.getParameterHelper().hasAsOfDate() && !flag1;
        boolean flag3 = false;
        if("OAF".equals(m_UserSession.getAKRegion().getRenderType()))
            flag3 = true;
        return oracle.apps.bis.pmv.parameters.JavaScriptHelper.getParamScript(flag3, flag, flag2, "");
    }

    public java.lang.String getAsOfDateHtml(oracle.apps.bis.pmv.parameters.Parameters parameters)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(150);
        if(parameters != null && parameters.getPeriod() != null && !m_IsAsOfDateHidden)
        {
            if(m_UserSession.getRequestInfo() != null && !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_UserSession.getRequestInfo().getPageId()))
                stringbuffer.append("<TABLE summary=\"\" cellpadding=0 cellspacing=0 border=0><TR>");
            else
                stringbuffer.append("<TABLE summary=\"\" cellpadding=2 cellspacing=2 border=0><TR>");
            stringbuffer.append("<TD class=pmvDateLabel align=left style=\"padding-left: 25px;\" nowrap>");
            stringbuffer.append(oracle.apps.bis.pmv.parameters.ParameterUtil.getAsOfDateLabel(m_UserSession.getConnection(), parameters.getPeriod()));
            stringbuffer.append(" </TD></TR></TABLE>");
        }
        return stringbuffer.toString();
    }

    public static final java.lang.String RCS_ID = "$Header: PMVParameterBean.java 115.71 2007/05/02 11:56:45 asverma noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: PMVParameterBean.java 115.71 2007/05/02 11:56:45 asverma noship $", "oracle.apps.bis.pmv.parameters");
    private oracle.apps.bis.pmv.session.UserSession m_UserSession;
    private oracle.apps.fnd.common.WebAppsContext m_WebAppsContext;
    private java.lang.String m_AKRegionCode;
    private javax.servlet.http.HttpServletRequest m_Request;
    private oracle.apps.bis.pmv.session.RequestInfo m_RequestInfo;
    private java.lang.String m_ParameterDisplayOnly;
    private java.lang.String m_Email;
    private java.lang.String m_Designer;
    private boolean m_EDW;
    private boolean m_OLTP;
    private boolean m_DBI;
    private boolean m_IsDispRun;
    private boolean m_HasNestedRegion;
    private java.lang.String m_ParamLayoutType;
    private boolean m_ParamPortlet;
    private boolean m_OAFormExist;
    private boolean m_EditParamLinkEnable;
    private com.sun.java.util.collections.Map m_ParamInfo;
    private boolean m_IsAsOfDateHidden;

}
