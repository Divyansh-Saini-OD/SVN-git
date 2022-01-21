// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames 
// Source File Name:   ExportReportPageBean.java

package od.oracle.apps.xxcrm.bis.pmv.report;

import com.sun.java.util.collections.ArrayList;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.Writer;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.FileUtil;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.common.UserPersonalizationUtil;
import oracle.apps.bis.pmv.PMVException;
import oracle.apps.bis.pmv.common.HTMLUtil;
import oracle.apps.bis.pmv.common.PMVConstants;
import oracle.apps.bis.pmv.common.PMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.data.PMVProvider;
import oracle.apps.bis.pmv.header.HeaderBean;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.parameters.ParameterHelper;
import oracle.apps.bis.pmv.parameters.StreamParameterBean;
import oracle.apps.bis.pmv.session.RequestInfo;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.bis.renderer.Renderer;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;

// Referenced classes of package oracle.apps.bis.pmv.report:
//            ReportPageBean, ReportDataSource

public class ODExportReportPageBean extends oracle.apps.bis.pmv.report.ReportPageBean
{

    public ODExportReportPageBean(javax.servlet.jsp.PageContext pagecontext, oracle.apps.fnd.common.WebAppsContext webappscontext, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        m_InfoTipDefined = false;
        initSession(pagecontext);
        super.m_WebAppsContext = webappscontext;
        oracle.apps.bis.pmv.session.RequestInfo requestinfo = new RequestInfo();
        requestinfo.setMode("EXPORT");
        requestinfo.setParamType("EXPORT");
        requestinfo.setLowerBound("0");
        requestinfo.setNavMode("EXPORT");

        java.lang.String s = oracle.apps.bis.common.ServletWrapper.getParameter(super.m_Request, "parameterDisplayOnly");
        if("Y".equalsIgnoreCase(oracle.apps.bis.pmv.common.StringUtil.nonNull(s)))
            requestinfo.setParameterDisplayOnly("Y");
        if(oracle.apps.bis.common.ServletWrapper.getParameter(super.m_Request, "sortAttribute") != null)
            requestinfo.setSortAttribute(oracle.apps.bis.common.ServletWrapper.getParameter(super.m_Request, "sortAttribute"));
        if(oracle.apps.bis.common.ServletWrapper.getParameter(super.m_Request, "sortDirection") != null)
            requestinfo.setSortDirection(oracle.apps.bis.common.ServletWrapper.getParameter(super.m_Request, "sortDirection"));
        super.m_UserSession = usersession;
        super.m_UserSession.setApplication(super.m_Application);
        super.m_UserSession.setPageContext(pagecontext);
        super.m_UserSession.setRequestInfo(requestinfo);
        super.m_ParamHelper = new ParameterHelper(super.m_UserSession, super.m_UserSession.getConnection());
        java.lang.String s1 = oracle.apps.bis.pmv.common.PMVUtil.getCustomViewName(super.m_UserSession.getConnection(), super.m_UserSession.getFunctionName());
        if(s1 != null)
            super.m_UserSession.getRequestInfo().setCustomViewName(s1);
        super.m_UserSession.setCustomizedAKRegion(super.m_ParamHelper, null);
        m_InfoTipDefined = !super.m_UserSession.getAKRegion().getInfoTips().isEmpty();
        java.lang.String s2 = oracle.apps.bis.common.UserPersonalizationUtil.getViewNameSessionKey(super.m_UserSession.getFunctionName(), super.m_UserSession.getRegionCode());
        if(super.m_UserSession != null && super.m_UserSession.isUserCustomization() && super.m_UserSession.isViewExists() && !oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_UserSession.getCustomCode()) && oracle.apps.bis.common.ServletWrapper.getSessionValue(pagecontext, s2) != null)
        {
            m_ViewName = (java.lang.String)oracle.apps.bis.common.ServletWrapper.getSessionValue(pagecontext, s2);
            m_ViewName = " - " + m_ViewName;
        }
    }

    public void setExportHeaders()
    {
        super.m_Response.setHeader("Content-Disposition", "p; filename=" + super.m_UserSession.getFunctionName() + ".XLS");
        super.m_Response.setContentType("application/txt-file");
    }

    public void setQueryData()
        throws oracle.apps.bis.pmv.PMVException
    {
        oracle.apps.bis.pmv.report.ReportDataSource reportdatasource = new ReportDataSource(super.m_UserSession);
        super.m_UserSession.setPortletMode(false);
        od.oracle.apps.xxcrm.bis.pmv.data.ODPMVProviderExp pmvprovider = new ODPMVProviderExp(super.m_UserSession, super.m_ParamHelper, reportdatasource.getDataRows());
        oracle.apps.bis.metadata.MetadataNode metadatanode = pmvprovider.getPMVMetadata();
        super.m_rootNode = metadatanode;
        super.m_Renderer = new Renderer(pmvprovider, metadatanode, super.m_PageContext, super.m_WebAppsContext, false, super.m_UserSession.getConnection());
    }

    public void export(boolean flag, boolean flag1, boolean flag2)
        throws oracle.apps.bis.pmv.PMVException
    {
        try
        {
            java.io.BufferedWriter bufferedwriter = oracle.apps.bis.common.FileUtil.getBufferedWriter(super.m_PageContext, super.m_UserSession.getWebAppsContext());
            exportReportTitle(bufferedwriter);
            bufferedwriter.newLine();
            if(flag)
            {
                exportParameterData(bufferedwriter);
                bufferedwriter.newLine();
                if(m_InfoTipDefined)
                    exportInfoTipString(bufferedwriter);
            }
            if(flag1)
            {
                bufferedwriter.newLine();
                exportTableData(bufferedwriter);
                bufferedwriter.newLine();
            }
            exportScaleNoteData(bufferedwriter);
            bufferedwriter.newLine();
            if(!super.m_UserSession.getAKRegion().isEDW())
            {
                exportLastRefreshDateData(bufferedwriter);
                bufferedwriter.newLine();
            }
            bufferedwriter.flush();
            return;
        }
        catch(java.io.IOException ioexception)
        {
            throw new PMVException(ioexception);
        }
    }

    private void exportReportTitle(java.io.BufferedWriter bufferedwriter)
        throws java.io.IOException
    {
        oracle.apps.bis.pmv.header.HeaderBean.renderHeader(super.m_UserSession, super.m_UserSession.getConnection());
        java.lang.String s = (java.lang.String)super.m_Session.getValue("oracle.apps.bis.pmv.dynamicTitle");
        s = s != null ? s : super.m_WebAppsContext.getSessionAttribute("header");
        if(s != null)
        {
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_ViewName))
                bufferedwriter.write(s + m_ViewName);
            else
                bufferedwriter.write(s);
            bufferedwriter.newLine();
        }
    }

    private void exportTableData(java.io.BufferedWriter bufferedwriter)
        throws java.io.IOException
    {
        super.m_Renderer.streamTableData(bufferedwriter);
    }

    private void exportParameterData(java.io.BufferedWriter bufferedwriter)
        throws java.io.IOException
    {
        oracle.apps.bis.pmv.parameters.StreamParameterBean streamparameterbean = new StreamParameterBean(super.m_UserSession, super.m_ParamHelper, super.m_PageContext);
        streamparameterbean.streamParameters(bufferedwriter);
    }

    private void exportScaleNoteData(java.io.BufferedWriter bufferedwriter)
        throws java.io.IOException
    {
        java.lang.String s = getScaleInfoString();
        if(s != null)
            bufferedwriter.write(s);
    }

    private void exportLastRefreshDateData(java.io.BufferedWriter bufferedwriter)
        throws java.io.IOException
    {
        java.lang.String s = getLastRefreshDateString();
        bufferedwriter.write(s);
    }

    private java.lang.String getLastRefreshDateString()
        throws java.io.IOException
    {
        java.lang.String s = oracle.apps.bis.pmv.common.HTMLUtil.getExcelLastUpdateString(oracle.apps.bis.pmv.common.PMVUtil.getLastRefreshDate(super.m_UserSession.getFunctionName(), super.m_UserSession.getConnection(), "REPORT"), super.m_UserSession);
        return s;
    }

    private void exportInfoTipString(java.io.BufferedWriter bufferedwriter)
        throws java.io.IOException
    {
        java.lang.String s = oracle.apps.bis.pmv.common.PMVUtil.getInfoTip(super.m_UserSession, super.m_ParamHelper);
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && !"null".equals(s))
        {
            bufferedwriter.write(s);
            bufferedwriter.newLine();
        }
    }

    private java.lang.String getScaleInfoString()
    {
        java.lang.String s = "";
        if(super.m_UserSession != null && oracle.apps.bis.pmv.common.PMVUtil.isMeasureForFactoring(super.m_UserSession.getAKRegion()))
        {
            java.lang.String s1 = oracle.apps.bis.pmv.common.PMVUtil.getAutoFactorLabelValue(super.m_UserSession);
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                if("K".equals(s1))
                    s = oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_IN_THOUSANDS_REP", super.m_WebAppsContext);
                else
                if("M".equals(s1))
                    s = oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_IN_MILLIONS_REP", super.m_WebAppsContext);
                else
                if("B".equals(s1))
                    s = oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_IN_BILLIONS_REP", super.m_WebAppsContext);
        }
        return s;
    }

    public static final java.lang.String RCS_ID = "$Header: ExportReportPageBean.java 115.22 2007/04/20 06:11:47 nkishore noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ExportReportPageBean.java 115.22 2007/04/20 06:11:47 nkishore noship $", "oracle.apps.bis.pmv.report");
    private boolean m_InfoTipDefined;
    private java.lang.String m_ViewName;

}
