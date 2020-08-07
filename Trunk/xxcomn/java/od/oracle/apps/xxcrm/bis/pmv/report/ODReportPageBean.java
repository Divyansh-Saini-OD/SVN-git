// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODReportPageBean.java

package od.oracle.apps.xxcrm.bis.pmv.report;
import oracle.apps.bis.pmv.report.*;
import com.sun.java.util.collections.AbstractList;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.Iterator;
import com.sun.java.util.collections.Set;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.Hashtable;
import java.util.Locale;
import java.util.Vector;
import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.jsp.JspWriter;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.common.Util;
import oracle.apps.bis.common.VersionConstants;
import oracle.apps.bis.database.JDBCUtil;
import oracle.apps.bis.metadata.MetadataAttributes;
import oracle.apps.bis.metadata.MetadataDistributor;
import oracle.apps.bis.metadata.MetadataNode;
import oracle.apps.bis.msg.MessageLog;
import oracle.apps.bis.parameters.DefaultParameters;
import oracle.apps.bis.parameters.Parameter;
import oracle.apps.bis.parameters.ParametersUtil;
import oracle.apps.bis.pmv.PMVException;
import oracle.apps.bis.pmv.breadcrumb.BreadCrumbHelper;
import oracle.apps.bis.pmv.breadcrumb.BreadCrumbRenderer;
import oracle.apps.bis.pmv.common.ExportUtil;
import oracle.apps.bis.pmv.common.FndLobsHelper;
import oracle.apps.bis.pmv.common.GenericUtil;
import od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil;
import oracle.apps.bis.pmv.common.Logger;
import oracle.apps.bis.pmv.common.PMVConstants;
import oracle.apps.bis.pmv.common.PMVNLSServices;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import od.oracle.apps.xxcrm.bis.pmv.data.ODPMVProvider;
import oracle.apps.bis.pmv.header.HeaderBean;
import oracle.apps.bis.pmv.lov.LovDataHolder;
import oracle.apps.bis.pmv.lov.LovHelper;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import od.oracle.apps.xxcrm.bis.pmv.parameters.ODPMVParameterBean;
import oracle.apps.bis.pmv.parameters.PMVParameterForm;
import oracle.apps.bis.pmv.parameters.PMVParameters;
import oracle.apps.bis.pmv.parameters.ParameterHelper;
import oracle.apps.bis.pmv.parameters.ParameterSaveBean;
import oracle.apps.bis.pmv.parameters.ParameterUtil;
import oracle.apps.bis.pmv.parameters.StreamPDFParameterBean;
import oracle.apps.bis.pmv.query.Calculation;
import od.oracle.apps.xxcrm.bis.pmv.relatedinfo.ODRelatedInfoBean;
import oracle.apps.bis.pmv.session.RequestInfo;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.bis.renderer.Renderer;
import oracle.apps.fnd.common.AppsContext;
import oracle.apps.fnd.common.Context;
import oracle.apps.fnd.common.ProfileStore;
import oracle.apps.fnd.common.URLTools;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.framework.webui.URLMgr;
import oracle.apps.fnd.functionSecurity.Function;
import oracle.apps.fnd.functionSecurity.FunctionSecurity;
import oracle.apps.fnd.security.HMAC;
import oracle.cabo.share.url.EncoderUtils;
import oracle.jdbc.driver.OracleCallableStatement;
import oracle.jdbc.driver.OraclePreparedStatement;
import oracle.jdbc.driver.OracleStatement;
import oracle.apps.bis.pmv.report.ReportDataSource;
import oracle.apps.bis.pmv.report.ReportBean;
import oracle.apps.bis.common.UserPersonalizationUtil;


// Referenced classes of package oracle.apps.bis.pmv.report:
//            ReportBean, ReportDataSource

public class ODReportPageBean
    implements oracle.apps.bis.pmv.common.PMVConstants
{

    public ODReportPageBean()
    {
        m_PlugId = "";
        m_Env = "";
        m_Content = new StringBuffer(2500);
    }

    public ODReportPageBean(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        m_PlugId = "";
        m_Env = "";
        m_Content = new StringBuffer(2500);
        m_UserSession = usersession;
        initSession(usersession.getPageContext());
        init(usersession.getWebAppsContext(), usersession);
    }

    public void RenderPageBean(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.sql.Connection connection)
    {
        initSchedule(s, s1, s2, s3, s4, connection, false);
    }

    public void RenderPageBean(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.sql.Connection connection, boolean flag)
    {
        initSchedule(s, s1, s2, s3, s4, connection, flag);
    }

    public void RenderPageBean(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.sql.Connection connection, boolean flag,
            java.util.Locale locale)
    {
        m_Locale = locale;
        initSchedule(s, s1, s2, s3, s4, connection, flag);
    }

    private void initSchedule(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.sql.Connection connection, boolean flag)
    {
        oracle.apps.bis.pmv.session.RequestInfo requestinfo = new RequestInfo();
        m_WebAppsContext = new WebAppsContext(connection);
        m_Env = m_WebAppsContext.getProfileStore().getProfile("BIS_ENVIRONMENT");
        if(m_Env == null)
            m_Env = "";
        requestinfo.setScheduleId(s);
        requestinfo.setMode("SCHEDULE");
        requestinfo.setParamType("SCHEDULE");
        requestinfo.setIsPrintable(false);
        requestinfo.setRequestType(s1);
        requestinfo.setFileId(s4);
        requestinfo.setRerunLink(false);
        requestinfo.setRenderStyleSheet(true);
        java.lang.String s5 = "";
        java.sql.ResultSet resultset = null;
        java.sql.PreparedStatement preparedstatement = null;
        if("R".equals(s1))
            requestinfo.setIsEmail(true);
        try
        {
            if("G".equals(s1) || "T".equals(s1))
            {
                preparedstatement = connection.prepareStatement("Select plug_id from bis_schedule_preferences where schedule_id =f :1 and nvl(file_id,0)=nvl(:2,0)");
                preparedstatement.setString(1, s);
                preparedstatement.setString(2, s4);
                oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
                oraclestatement.defineColumnType(1, 12, 80);
                for(resultset = preparedstatement.executeQuery(); resultset.next();)
                    s5 = resultset.getString(1);

            }
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(preparedstatement != null)
                    preparedstatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        java.lang.String s6 = "";
        java.lang.String s7 = "";
        java.lang.String s8 = " SELECT user_id, responsibility_id FROM bis_scheduler WHERE schedule_id = :1";
        try
        {
            preparedstatement = connection.prepareStatement(s8);
            oracle.jdbc.driver.OracleStatement oraclestatement1 = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            oraclestatement1.defineColumnType(1, 12, 80);
            oraclestatement1.defineColumnType(2, 12, 20);
            preparedstatement.setString(1, s);
            for(resultset = preparedstatement.executeQuery(); resultset.next();)
            {
                s6 = resultset.getString(1);
                s7 = resultset.getString(2);
            }

        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(resultset != null)
                    resultset.close();
                if(preparedstatement != null)
                    preparedstatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        try
        {
            oracle.apps.bis.msg.MessageLog messagelog = null;
            m_UserSession = new UserSession(s2, s3, m_WebAppsContext, messagelog);
            m_UserSession.setUserId(s6);
            m_UserSession.setResponsibilityId(s7);
            m_PlugId = s5;
            m_UserSession.setRequestInfo(requestinfo);
            renderSchedule(connection);
            return;
        }
        catch(java.io.IOException _ex)
        {
            return;
        }
        catch(oracle.apps.bis.pmv.PMVException _ex)
        {
            return;
        }
    }

    public java.lang.String renderPage()
        throws oracle.apps.bis.pmv.PMVException
    {
        m_PageHTML = new StringBuffer(5000);
        oracle.apps.bis.pmv.session.RequestInfo requestinfo = null;
        if(m_UserSession != null)
            requestinfo = m_UserSession.getRequestInfo();
        /*if(requestinfo != null && !requestinfo.isDesignerPreview() && !requestinfo.isLovReport())
            processForBreadCrumb();
        */
        m_Session.removeValue("oracle.apps.bis.pmv.dynamicTitle");
        render();
        return m_PageHTML.toString();
    }

    public void initSession(javax.servlet.jsp.PageContext pagecontext)
    {
        m_Application = pagecontext.getServletContext();
        m_Session = pagecontext.getSession();
        m_Request = (javax.servlet.http.HttpServletRequest)pagecontext.getRequest();
        m_Response = (javax.servlet.http.HttpServletResponse)pagecontext.getResponse();
        m_PageContext = pagecontext;
        m_Out = pagecontext.getOut();
    }

    private void init(oracle.apps.fnd.common.WebAppsContext webappscontext, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        if(m_PlugId == null || m_PlugId.equals(""))
            oracle.apps.bis.pmv.session.UserSession.pmRegion = "Report";
        else
            oracle.apps.bis.pmv.session.UserSession.pmRegion = "PMRegion";
        m_WebAppsContext = webappscontext;
        m_UserSession = usersession;
        m_UserSession.setApplication(m_Application);
        m_UserSession.setPageContext(m_PageContext);
        java.lang.String s = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pMode");
        if("DRILL".equalsIgnoreCase(s) || "DRILLDOWN".equalsIgnoreCase(s))
        {
            java.lang.String s1 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pResponsibilityId");
            if(s1 != null && s1.length() > 0 && !s1.equalsIgnoreCase(m_UserSession.getResponsibilityId()))
            {
                m_UserSession.setResponsibilityId(s1);
                oracle.apps.bis.pmv.common.GenericUtil.setAppsContext(m_WebAppsContext, s1, java.lang.String.valueOf(m_WebAppsContext.getUserId()), m_WebAppsContext.getJDBCConnection());
            }
        }
        m_Env = webappscontext.getProfileStore().getProfile("BIS_ENVIRONMENT");
        if(m_Env == null)
            m_Env = "";
        initObjects();
    }

    private void initObjects()
    {
        m_UserSession.setRequestInfo(getRequestInfo());
        if(m_ParamHelper == null)
            m_ParamHelper = new ParameterHelper(m_UserSession, m_UserSession.getConnection());
        java.util.Hashtable hashtable = null;
        if("1".equals(m_UserSession.getRequestInfo().getFirstTime()) && m_UserSession.getParameters() != null)
            hashtable = m_UserSession.getParameterHashTable(m_UserSession.getParameters(), m_UserSession.getRegionCode());
        m_UserSession.setCustomizedAKRegion(m_ParamHelper, hashtable);
        setLowerUpperPrevNextProperties(m_UserSession.getRequestInfo());
    }

    private void render()
        throws oracle.apps.bis.pmv.PMVException
    {
        oracle.apps.bis.pmv.session.RequestInfo requestinfo = m_UserSession.getRequestInfo();
        oracle.apps.bis.msg.MessageLog messagelog = null;
        if(m_UserSession != null)
            messagelog = m_UserSession.getPmvMsgLog();
        int i = 0x7fffffff;
        if(messagelog != null)
            i = messagelog.getLevel();
        try
        {
            if(messagelog != null && i == 5 && i != 1000)
                messagelog.logMessage("Report Generation", "ODReportPageBean::render() - MODE: " + requestinfo.getMode(), 5);
        }
        catch(java.lang.Exception _ex) { }
        java.lang.String s = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "email");
        if("Y".equals(s) || "PRINTABLE".equals(requestinfo.getMode()))
        {
            requestinfo.setIsPrintable(true);
            if("Y".equals(s))
                requestinfo.setIsEmail(true);
        } else
        {
            requestinfo.setIsPrintable(false);
        }
        boolean flag = requestinfo.isLovReport();
        if(flag)
        {
            m_UserSession.getLovDataHolder().getPMVParameters().renderPMVScripts();
            if(m_UserSession.getLovDataHolder().getSelectedParameter().isLongListLevel())
            {
                java.lang.String s1 = m_UserSession.getLovDataHolder().getLovAttribute();
                if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                    s1 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pLovAttribute");
                m_UserSession.setIsQueryAllowed(oracle.apps.bis.pmv.lov.LovHelper.isQueryAllowed(m_ParamHelper, s1));
            }
        }
        java.lang.String s2 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "refreshParameters");
        if("Y".equals(s2))
        {
            m_ParamSection = new StringBuffer(3000);
            m_ParamSection.append(getParameterBeanString());
            return;
        }
        m_PageHTML.append(renderParameterSection());
        if("0".equals(requestinfo.getFirstTime()))
        {
            java.lang.String s3 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "cached");
            if(s3 == null)
                s3 = "false";
            if("false".equals(s3) || "".equals(s3) || "TEST".equals(m_Env))
            {
                oracle.apps.bis.common.ServletWrapper.putSessionValue(m_PageContext, "EMAIL" + m_UserSession.getFunctionName(), "Y");
                if(messagelog != null && i == 5)
                    messagelog.logMessage("Report Rendering", "Create PMV Provider  - Start", i);
                m_UserSession.setPortletMode(false);
                Object obj = null;
                od.oracle.apps.xxcrm.bis.pmv.data.ODPMVProvider pmvprovider = null;
                try
                {
                    java.util.Vector vector1 = m_UserSession.getPrototypeDataRows();
                    java.util.Vector vector;
                    if(m_UserSession.getRequestInfo().isDesignerPreview() && vector1 != null && vector1.size() > 0)
                    {
                        vector = vector1;
                    } else
                    {
                        oracle.apps.bis.pmv.report.ReportDataSource reportdatasource = new ReportDataSource(m_UserSession);
                        vector = reportdatasource.getDataRows();
                    }
                    pmvprovider = new ODPMVProvider(m_UserSession, m_ParamHelper, vector);
                }
                catch(oracle.apps.bis.pmv.PMVException pmvexception)
                {
                    if(messagelog != null && i == 5)
                        messagelog.logMessage("Report Generation", "ODReportPageBean::render() - " + pmvexception.fillInStackTrace().toString(), i);
                    throw pmvexception;
                }
                m_rootNode = pmvprovider.getPMVMetadata();
                if(requestinfo.isPrintable())
                    m_Renderer = new Renderer(pmvprovider, m_rootNode, m_PageContext, m_WebAppsContext, m_UserSession.getConnection(), true);
                else
                    m_Renderer = new Renderer(pmvprovider, m_rootNode, m_PageContext, m_WebAppsContext, m_UserSession.getConnection());
                if(messagelog != null && i == 5)
                    messagelog.logMessage("Report Rendering", "Create PMV Provider  - Finish", i);
            } else
            {
                m_Renderer = new Renderer(m_PageContext, m_WebAppsContext, m_UserSession.getConnection(), true);
            }
            if(messagelog != null)
            {
                m_Renderer.setPmvMsgLog(messagelog);
                m_Renderer.setProgName("Report Rendering");
            }
            if(messagelog != null && i == 5)
                messagelog.logMessage("Report Rendering", "Render Graphs - Start", i);
            if(!flag)
                m_PageHTML.append(getGraphs(m_UserSession.getConnection(), false));
            if(!od.oracle.apps.xxcrm.bis.pmv.report.ODReportPageBean.isSWAN())
                m_PageHTML.append("<br>");
            if(messagelog != null && i == 5)
            {
                messagelog.logMessage("Report Rendering", "Render Graphs - Finish", i);
                messagelog.logMessage("Report Rendering", "Render Table - Start", i);
            }
            m_PageHTML.append(m_Renderer.getTableHTML());
            if(messagelog != null && i == 5)
                messagelog.logMessage("Report Rendering", "Render Table - Finish", i);
            renderAutoScaleFooter(m_PageHTML);
            if(!od.oracle.apps.xxcrm.bis.pmv.report.ODReportPageBean.isSWAN() && requestinfo != null && requestinfo.isPrintable())
                m_PageHTML.append("<br>");
            if(!flag)
            {
                if(!m_UserSession.getAKRegion().isEDW())
                    m_PageHTML.append(renderLastUpdateDate());
                if(!od.oracle.apps.xxcrm.bis.pmv.report.ODReportPageBean.isSWAN())
                    m_PageHTML.append("<br>");
                if(!"Y".equals(s))
                    m_PageHTML.append(getRelatedLinks());
            }
            if(!"Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "tab")))
            {
                m_PageHTML.append(renderReportFooter());
                return;
            }
        } else
        {
            oracle.apps.bis.common.ServletWrapper.removeSessionAttribute(m_PageContext, "EMAIL" + m_UserSession.getFunctionName());
        }
    }

    private void renderAutoScaleFooter(java.lang.StringBuffer stringbuffer)
    {
        if(m_UserSession != null && od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.isMeasureForFactoring(m_UserSession.getAKRegion()))
        {
            java.lang.String s = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getAutoFactorLabelValue(m_UserSession);
            java.lang.String s1 = "";
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
                if("K".equals(s))
                    s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_IN_THOUSANDS_REP", m_WebAppsContext);
                else
                if("M".equals(s))
                    s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_IN_MILLIONS_REP", m_WebAppsContext);
                else
                if("B".equals(s))
                    s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_IN_BILLIONS_REP", m_WebAppsContext);
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                stringbuffer.append(renderAutoLabel(s1));
        }
    }

    private java.lang.String renderParameterSection()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(2000);
        oracle.apps.bis.pmv.session.RequestInfo requestinfo = null;
        if(m_UserSession != null)
            requestinfo = m_UserSession.getRequestInfo();
        if(requestinfo != null && !requestinfo.isLovReport() && !requestinfo.isPrintable())
            stringbuffer.append(renderBreadCrumbs());
        java.lang.String s = "Y";
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "displayParameters")))
            s = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "displayParameters").toUpperCase();
        if("Y".equals(s))
        {
            if(m_UserSession.getRequestInfo().isLovReport())
                stringbuffer.append(oracle.apps.bis.pmv.lov.LovHelper.getSearchHeader(m_UserSession.getLovDataHolder(), m_WebAppsContext, m_UserSession.getImageServer()));
            stringbuffer.append(getParameterBeanString());
        } else
        {
            stringbuffer.append(oracle.apps.bis.pmv.parameters.ParameterUtil.getScripts());
        }
        if(m_UserSession.getRequestInfo().isLovReport())
            stringbuffer.append(oracle.apps.bis.pmv.lov.LovHelper.getResultHeader(m_UserSession));
        boolean flag = false;
        flag = !m_UserSession.getAKRegion().getInfoTips().isEmpty();
        if(flag)
        {
            java.lang.String s1 = getInfoTipString();
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                stringbuffer.append(s1);
        }
 stringbuffer.append("<link rel=\"stylesheet\" charset=\"UTF-8\" type=\"text/css\" href=\"OracleEBS.css\">");
        return stringbuffer.toString();
    }

    private java.lang.String getInfoTipString()
    {
        java.lang.String s = new String();
        java.lang.String s2 = new String();
        java.lang.StringBuffer stringbuffer = new StringBuffer(50);
        java.lang.String s4 = new String();
        oracle.apps.bis.msg.MessageLog messagelog = null;
        if(m_UserSession != null)
            messagelog = m_UserSession.getPmvMsgLog();
        int i = 0x7fffffff;
        if(messagelog != null)
            i = messagelog.getLevel();
        try
        {
            com.sun.java.util.collections.ArrayList arraylist = m_UserSession.getAKRegion().getInfoTips();
            java.lang.String s3;
            for(com.sun.java.util.collections.Iterator iterator = arraylist.iterator(); iterator.hasNext(); stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getLastUpdateString(s3, m_UserSession)))
            {
                oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)iterator.next();
                java.lang.String s1 = akregionitem.getAttributeNameLong();
                s3 = oracle.apps.bis.pmv.query.Calculation.getDynamicLabel(m_ParamHelper, s1, m_UserSession, m_UserSession.getConnection());
            }

            s4 = stringbuffer.toString();
        }
        catch(java.lang.Exception exception)
        {
            if(messagelog != null && i == 5)
                messagelog.logMessage("Report Rendering", "PMV-ERROR: ODReportPageBean::getInfoTip() - " + exception.getMessage(), i);
        }
        return s4;
    }

    private java.lang.String renderLastUpdateDate()
    {
        java.lang.String s = "REPORT";
        if("PORTLET".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pObjectType")))
            s = "PORTLET";
        if(m_UserSession.isEmailContent() || m_UserSession.isPrintableMode())
            return od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getLastUpdateString(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getLastRefreshDate(m_UserSession.getFunctionName(), m_UserSession.getConnection(), s), m_UserSession);
        else
            return od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getLastUpdateString(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getLastRefreshDateString(m_UserSession.getFunctionName(), m_UserSession.getConnection(), s), m_UserSession);
    }

    private java.lang.String renderAutoLabel(java.lang.String s)
    {
        return od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getAutoFactorHTMLString(s);
    }

    public java.lang.String getParameterSection()
    {
        return m_ParamSection.toString();
    }

    public boolean isOATable()
    {
        return "OAF".equals(m_UserSession.getAKRegion().getRenderType());
    }

    private java.lang.String getRelatedLinks()
    {
        java.lang.String s = "";
        try
        {
            od.oracle.apps.xxcrm.bis.pmv.relatedinfo.ODRelatedInfoBean relatedinfobean = new ODRelatedInfoBean(m_UserSession);
            s = relatedinfobean.getRelatedLinksHTML();
        }
        catch(java.io.IOException _ex) { }
        finally
        {
            return s;
        }
    }

    private java.lang.String getGraphsAndRelatedLinks(java.sql.Connection connection, boolean flag)
    {
        oracle.apps.bis.metadata.MetadataDistributor metadatadistributor = null;
        Object obj = null;
        java.lang.StringBuffer stringbuffer = new StringBuffer(3000);
        if(m_rootNode == null)
        {
            oracle.apps.bis.metadata.MetadataNode metadatanode = (oracle.apps.bis.metadata.MetadataNode)m_PageContext.getSession().getValue("metadataProvider");
            if(metadatanode != null)
                metadatadistributor = new MetadataDistributor(metadatanode);
        } else
        {
            metadatadistributor = new MetadataDistributor(m_rootNode);
        }
        com.sun.java.util.collections.ArrayList arraylist = metadatadistributor.getGraphNodes();
        int i = arraylist.size();
        if(i > 0)
        {
            stringbuffer.append("<table width=100% summary=\"\" cellSpacing=0 cellPadding=0>");
            for(int j = 1; j <= i; j++)
            {
                java.lang.String s = "&nbsp;";
                oracle.apps.bis.metadata.MetadataNode metadatanode1 = (oracle.apps.bis.metadata.MetadataNode)arraylist.get(j - 1);
                oracle.apps.bis.metadata.MetadataNode metadatanode2 = metadatanode1.findChild("Title");
                if(metadatanode2 != null)
                    s = (java.lang.String)metadatanode2.getAttribute("text");
                if(s == null || s.equals(""))
                    s = "&nbsp;";
                if(j % 2 == 0)
                {
                    stringbuffer.append("<td valign=top width=\"30%\">");
                } else
                {
                    stringbuffer.append("<tr></tr>");
                    stringbuffer.append("<tr><td valign=top");
                    if(i == 1)
                        stringbuffer.append(" width=\"60%\">");
                    else
                        stringbuffer.append(" width=\"30%\">");
                }
                stringbuffer.append("<TABLE cellSpacing=0 cellPadding=0 summary=\"\" width=\"100%\">");
                stringbuffer.append("<tr><td class=OraHeaderSubSub>");
                stringbuffer.append(oracle.apps.bis.common.Util.escapeGTLTHTML(s, ""));
                stringbuffer.append(" </td>");
                stringbuffer.append("</tr></TABLE>");
                stringbuffer.append("<TABLE cellSpacing=0 cellPadding=0 summary=\"\" width=\"100%\">");
                stringbuffer.append("<tr><td");
                stringbuffer.append(" style=\"");
                stringbuffer.append("border: #808080 solid 1px;\" class=OraInstructionText>");
                if(flag)
                {
                    java.lang.String s1 = getGraphFileId(m_UserSession.getRequestInfo().getScheduleId(), "GRAPH_FILE_ID_" + j, connection);
                    if(m_PageContext == null)
                    {
                        java.lang.String s2 = getContextValues(m_UserSession.getRequestInfo().getScheduleId(), "RENDERING_CONTEXT_VALUES", connection);
                        java.lang.String s3 = m_UserSession.getRequestInfo().getRequestType();
                        stringbuffer.append(m_Renderer.getDBGraphHTML(j, s1, s2, s3));
                    } else
                    {
                        stringbuffer.append(m_Renderer.getDBGraphHTML(j, s1));
                    }
                } else
                {
                    stringbuffer.append(m_Renderer.getGraphHTML(j));
                }
                stringbuffer.append("</td>");
                stringbuffer.append("</tr></TABLE>");
                if(i > 1 && j == 2 || i == 1 && j == 1)
                {
                    stringbuffer.append("</td><td width=\"5%\">&nbsp;</td><td align=right valign=top width=\"30%\">");
                    stringbuffer.append(getRelatedLinks());
                    stringbuffer.append("</td></tr>");
                } else
                if(j % 2 == 0)
                    stringbuffer.append("</td></tr>");
                else
                    stringbuffer.append("</td><td width=\"5%\">&nbsp;</td>");
            }

        } else
        if(i == 0)
        {
            stringbuffer.append("<table width=33% summary=\"\" >");
            stringbuffer.append("<tr><td valign=top width=\"33%\">");
            stringbuffer.append(getRelatedLinks());
            stringbuffer.append("</td></tr>");
        }
        stringbuffer.append("</table>");
        stringbuffer.append("<br>");
        return stringbuffer.toString();
    }

    private java.lang.String getGraphs(java.sql.Connection connection, boolean flag)
    {
        oracle.apps.bis.metadata.MetadataDistributor metadatadistributor = null;
        Object obj = null;
        java.lang.StringBuffer stringbuffer = new StringBuffer(3000);
        if(m_rootNode == null)
        {
            oracle.apps.bis.metadata.MetadataNode metadatanode = (oracle.apps.bis.metadata.MetadataNode)m_PageContext.getSession().getValue("metadataProvider");
            if(metadatanode != null)
                metadatadistributor = new MetadataDistributor(metadatanode);
        } else
        {
            metadatadistributor = new MetadataDistributor(m_rootNode);
        }
        com.sun.java.util.collections.ArrayList arraylist = metadatadistributor.getGraphNodes();
        if(od.oracle.apps.xxcrm.bis.pmv.report.ODReportPageBean.isSWAN())
            stringbuffer.append("<TABLE summary=\"\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" style=\"padding-left: 10px\" width=\"100%\"><TR><TD>");
        int i = arraylist.size();
        if(i > 0)
        {
            java.lang.String s = "";
            if(od.oracle.apps.xxcrm.bis.pmv.report.ODReportPageBean.isSWAN())
                s = " style=\"padding-left: 10px\" bgcolor=\"#eaeff5\"";
            stringbuffer.append("<table width=100% cellSpacing=0 cellPadding=0 summary=\"\"").append(s).append(" >");
            for(int j = 1; j <= i; j++)
            {
                java.lang.String s1 = "&nbsp;";
                oracle.apps.bis.metadata.MetadataNode metadatanode1 = (oracle.apps.bis.metadata.MetadataNode)arraylist.get(j - 1);
                oracle.apps.bis.metadata.MetadataNode metadatanode2 = metadatanode1.findChild("Title");
                if(metadatanode2 != null)
                    s1 = (java.lang.String)metadatanode2.getAttribute("text");
                if(s1 == null || s1.equals(""))
                    s1 = "&nbsp;";
                if(j == 2 || j == 3 || j == 5 || j == 6)
                {
                    if(i == 2)
                        stringbuffer.append("<td valign=top width=\"47%\">");
                    else
                        stringbuffer.append("<td valign=top width=\"30%\">");
                } else
                {
                    stringbuffer.append("<tr></tr>");
                    stringbuffer.append("<tr><td valign=top");
                    if(i == 1)
                        stringbuffer.append(" width=\"60%\">");
                    else
                    if(i == 2)
                        stringbuffer.append(" width=\"47%\">");
                    else
                        stringbuffer.append(" width=\"30%\">");
                }
                stringbuffer.append("<TABLE cellSpacing=0 cellPadding=0 summary=\"\" width=\"100%\">");
                stringbuffer.append("<tr><td class=OraHeaderSubSub>");
                stringbuffer.append(oracle.apps.bis.common.Util.escapeGTLTHTML(s1, ""));
                stringbuffer.append("</td>");
                stringbuffer.append("</tr></TABLE>");
                stringbuffer.append("<TABLE cellSpacing=0 cellPadding=0 summary=\"\" width=\"100%\">");
                stringbuffer.append("<tr><td");
                stringbuffer.append(" style=\"");
                stringbuffer.append("border: #808080 solid 1px;\" class=OraInstructionText>");
                if(flag)
                {
                    java.lang.String s2 = getGraphFileId(m_UserSession.getRequestInfo().getScheduleId(), "GRAPH_FILE_ID_" + j, connection);
                    if(m_PageContext == null)
                    {
                        java.lang.String s4 = getContextValues(m_UserSession.getRequestInfo().getScheduleId(), "RENDERING_CONTEXT_VALUES", connection);
                        java.lang.String s6 = m_UserSession.getRequestInfo().getRequestType();
                        stringbuffer.append(m_Renderer.getDBGraphHTML(j, s2, s4, s6, m_Locale));
                    } else
                    {
                        stringbuffer.append(m_Renderer.getDBGraphHTML(j, s2));
                    }
                } else
                if(m_Request != null && "Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "email")))
                {
                    java.lang.String s3 = m_UserSession.getFunctionName() + m_UserSession.getSessionId() + j + java.lang.System.currentTimeMillis() + ".png";
                    java.lang.String s5 = m_Application.getRealPath("/fwk/t/");
                    java.lang.String s7 = s5 + s3;
                    java.lang.String s8 = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
                    try
                    {
                        java.lang.String s9 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspUrl(m_UserSession.getWebAppsContext().getProfileStore().getProfile("APPS_SERVLET_AGENT")) + "bispgraph.jsp?dbc=" + m_UserSession.getRequestInfo().getDBC() + "&userId=" + m_UserSession.getUserId() + "&ifn=" + s3 + "&ifl=" + oracle.cabo.share.url.EncoderUtils.encodeString(s5, s8);
                        stringbuffer.append(m_Renderer.getGIFGraphHTML(j, s7, s9));
                    }
                    catch(java.io.UnsupportedEncodingException _ex) { }
                } else
                {
                    stringbuffer.append(m_Renderer.getGraphHTML(j, m_UserSession.getNLSServices().getUserLocaleContext()));
                }
                stringbuffer.append("</td>");
                stringbuffer.append("</tr></TABLE>");
                if(i == 1 && j == 1)
                {
                    stringbuffer.append("</td><td width=\"5%\">&nbsp;</td><td width=\"30%\">&nbsp;");
                    stringbuffer.append("</td></tr>");
                } else
                if(i == 2 && j == 2 || i == 4 && j == 4 || i == 5 && j == 5)
                {
                    stringbuffer.append("</td>");
                    stringbuffer.append("</tr>");
                } else
                if(j == 3 || j == 6)
                    stringbuffer.append("</td></tr>");
                else
                    stringbuffer.append("</td><td width=\"5%\">&nbsp;</td>");
            }

        } else
        if(i == 0)
        {
            stringbuffer.append("<table width=33% summary=\"\" >");
            stringbuffer.append("<tr><td valign=top width=\"33%\">");
            stringbuffer.append("</td></tr>");
        }
        stringbuffer.append("</table>");
        if(!od.oracle.apps.xxcrm.bis.pmv.report.ODReportPageBean.isSWAN() && m_UserSession.getRequestInfo() != null && m_UserSession.getRequestInfo().isDesignerPreview())
            stringbuffer.append("<br>");
        else
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getFooterSpaceHTML(m_UserSession, "15", "#eaeff5"));
        return stringbuffer.toString();
    }

    private java.lang.String renderReportFooter()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(2000);
        oracle.apps.bis.msg.MessageLog messagelog = m_UserSession.getPmvMsgLog();
        int i = 0x7fffffff;
        if(messagelog != null)
            i = messagelog.getLevel();
        if(messagelog != null && i == 5)
            messagelog.logMessage("Report Rendering", "Render Printable Button Area - Start", i);
        try
        {
            if(!m_UserSession.getRequestInfo().isPrintable())
            {
                if(!od.oracle.apps.xxcrm.bis.pmv.report.ODReportPageBean.isSWAN())
                    stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getSkiImage(m_UserSession, m_WebAppsContext));
                if(!m_UserSession.getRequestInfo().isLovReport())
                {
                    if(od.oracle.apps.xxcrm.bis.pmv.report.ODReportPageBean.isSWAN())
                    {
                        if(!m_UserSession.isPrintableMode() && !m_UserSession.isEmailContent())
                            stringbuffer.append("</FORM></TABLE></TD></TR></TABLE>");
                        else
                            stringbuffer.append("</TD></TR></TABLE>");
                        stringbuffer.append("<input TYPE=hidden name=printable value=>");
                    }
                    stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getReportFooter(m_WebAppsContext, m_Application, m_UserSession));
                } else
                {
                    stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getLovReportFooter(m_WebAppsContext, m_Application, m_UserSession));
                }
                if(!m_UserSession.useOldQueryBuilder() && messagelog != null && (i == 5 || i == 1000))
                {
                    java.lang.String s = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
                    java.lang.String as[] = oracle.apps.bis.pmv.header.HeaderBean.getTitleHTML(m_UserSession, m_UserSession.getConnection());
                    java.lang.String s1 = oracle.apps.bis.pmv.common.StringUtil.nonNull(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("PMV_VIEW_LOG_HEADING", m_WebAppsContext));
                    if("".equals(s1))
                        s1 = "View Log";
                    java.lang.StringBuffer stringbuffer1 = new StringBuffer(200);
                    stringbuffer1.append("OA.jsp?akRegionCode=BISMSGLOGPAGE&akRegionApplicationId=191&dbc=");
                    stringbuffer1.append(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "dbc"));
                    stringbuffer1.append("&transactionid=").append(m_UserSession.getTransactionId());
                    stringbuffer1.append("&LogicalName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(as[1], s));
                    stringbuffer1.append("&ObjectKey=").append(oracle.cabo.share.url.EncoderUtils.encodeString(messagelog.getKey(), s));
                    oracle.apps.fnd.security.HMAC hmac1 = getMACKey();
                    if(od.oracle.apps.xxcrm.bis.pmv.report.ODReportPageBean.isSWAN())
                        stringbuffer.append("<A style=\"font-size:9pt;color:#2b7c92;font-family:Tahoma\" HREF=").append(oracle.cabo.share.url.EncoderUtils.encodeURL(oracle.apps.fnd.framework.webui.URLMgr.processOutgoingURL(stringbuffer1.toString(), hmac1), oracle.apps.bis.common.ServletWrapper.getCharacterEncoding(m_Response), true));
                    else
                        stringbuffer.append("<A HREF=").append(oracle.cabo.share.url.EncoderUtils.encodeURL(oracle.apps.fnd.framework.webui.URLMgr.processOutgoingURL(stringbuffer1.toString(), hmac1), oracle.apps.bis.common.ServletWrapper.getCharacterEncoding(m_Response), true));
                    stringbuffer.append(">").append(s1).append(" </A>");
                }
            } else
            {
                stringbuffer.append("</TD></TR></TABLE>");
            }
        }
        catch(java.io.IOException ioexception)
        {
            if(messagelog != null && i == 5)
                messagelog.logMessage("Report Rendering", "PMV-ERROR: ODReportPageBean::renderPrintableTable() - " + ioexception.getMessage(), i);
        }
        try
        {
            if(messagelog != null && (i == 5 || i == 1000))
            {
                if(i == 5)
                    messagelog.logMessage("Report Rendering", "Render Printable Button Area - Finish", i);
                oracle.apps.bis.database.JDBCUtil.setSqlTrace(m_UserSession.getConnection(), 0);
                messagelog.closeProgress("Report Rendering");
                messagelog.closeProgress("Report Generation");
                messagelog.closeLog();
            }
        }
        catch(java.lang.Exception _ex) { }
        return stringbuffer.toString();
    }

    private java.lang.String getHeaderHtml()
    {
        java.lang.String s = oracle.apps.bis.pmv.header.HeaderBean.renderHeader(m_UserSession, m_UserSession.getConnection());
        return s;
    }

    private oracle.apps.bis.pmv.session.RequestInfo getRequestInfo()
    {
        oracle.apps.bis.pmv.session.RequestInfo requestinfo = new RequestInfo();
        java.lang.String s = "1";
        requestinfo.setDBC(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "dbc"));
        java.lang.String s3 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "transactionid");
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s3))
            s3 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "_ti");
        requestinfo.setTxId(s3);
        requestinfo.setMode("PARAMETERS");
        requestinfo.setFirstTime("1");
        requestinfo.setIsPrintable(false);
        java.lang.String s4 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "parameterDisplayOnly");
        if(s4 != null)
            requestinfo.setParameterDisplayOnly(s4);
        if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pFirstTime") != null)
        {
            java.lang.String s1 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pFirstTime");
            requestinfo.setFirstTime(s1);
        }
        java.lang.String s5 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "refreshParameters");
        if("1".equals(requestinfo.getFirstTime()) && !"Y".equals(s5))
            requestinfo.setParamType("DEFAULT");
        else
            requestinfo.setParamType("SESSION");
        java.lang.String s6 = "";
        java.lang.String s7 = "";
        if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "fromPersonalize") != null)
            s6 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "fromPersonalize");
        if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "cancelButton") != null)
            s7 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "cancelButton");
        if("Y".equals(s6))
            m_UserSession.setFromPersonalize(true);
        java.lang.String s8 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pMode");
        java.lang.String s9 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "forceRun");
        java.lang.String s10 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "designerPreview");
        requestinfo.setDesignerPreview(s10);
        if(s9 != null && !"RELATED".equals(s8) && !"DRILL".equals(s8) && !"BCRUMB".equalsIgnoreCase(s8))
        {
            java.lang.String s2 = s9;
            if("Y".equals(s2) || !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_UserSession.getParameters()))
            {
                if(!"Y".equals(s7) && !requestinfo.isDesignerPreview())
                    oracle.apps.bis.pmv.parameters.ParameterSaveBean.copyDefParameters(m_UserSession);
                requestinfo.setParamType("SESSION");
            }
            if("Y".equals(s2))
                requestinfo.setFirstTime("0");
        }
        if(!"Y".equals(s5) && isReportRunningFromBkMark())
        {
            processBookMark();
            requestinfo.setFirstTime("0");
            requestinfo.setParamType("SESSION");
        }
        if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pSubmit") != null)
        {
            java.lang.String s11 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pSubmit");
            requestinfo.setMode(s11);
        }
        if(s8 != null)
        {
            requestinfo.setMode(s8);
            if("DRILL".equalsIgnoreCase(s8) || "DRILLDOWN".equalsIgnoreCase(s8) || "BCRUMB".equalsIgnoreCase(s8))
            {
                requestinfo.setFirstTime("0");
                requestinfo.setParamType("SESSION");
                requestinfo.setRerunLink("N".equals(s4));
            } else
            if("RELATED".equals(s8))
            {
                java.lang.String s12 = m_UserSession.getAKRegion().getPageParameterRegionName();
                boolean flag1 = s12 != null && s12.length() > 0;
                if("Y".equals(s9) || flag1)
                    requestinfo.setFirstTime("0");
                else
                    requestinfo.setFirstTime("1");
                requestinfo.setParamType("SESSION");
            } else
            if("SONAR".equals(s8))
            {
                requestinfo.setIsPrintable(true);
                requestinfo.setFirstTime("0");
                requestinfo.setParamType("SESSION");
                requestinfo.setRerunLink(false);
                requestinfo.setRequestType("R");
                requestinfo.setFileId(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "fileId"));
            }
        }
        boolean flag = "Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pResetDefault"));
        if(!flag && oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "sortAttribute") != null)
            requestinfo.setSortAttribute(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "sortAttribute"));
        if(!flag && oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "sortDirection") != null)
            requestinfo.setSortDirection(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "sortDirection"));
        if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "showSchedule") != null)
            requestinfo.setShowSchedule(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "showSchedule"));
        if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "displayParameters") != null)
            requestinfo.setDisplayParameters(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "displayParameters"));
        java.lang.String s13 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pCSVFileName");
        if(s13 != null && s13.length() > 0)
            requestinfo.setCSVFileName(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pCSVFileName"));
        java.lang.String s14 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "_pageid");
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s14))
        {
            s14 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "_pageid");
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s14) && m_UserSession.getPageContext() != null)
                s14 = oracle.apps.bis.common.ServletWrapper.getHeaderAttribute(m_UserSession.getPageContext(), "x-oracle-portal-page-id");
            if(s14 != null && m_UserSession.getWebAppsContext() != null)
                s14 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getPageId(s14, m_UserSession.getWebAppsContext());
        }
        if(s14 != null && s14.length() > 0)
            requestinfo.setPageId(s14);
        java.lang.String s15 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pEnableForecastGraph");
        if(s15 != null && s15.equals("Y"))
            requestinfo.setEnableForecastGraph(true);
        java.lang.String s16 = m_UserSession.getUserId() + m_UserSession.getFunctionName() + m_UserSession.getSessionId();
        java.lang.String s17 = (java.lang.String)oracle.apps.bis.common.ServletWrapper.getSessionValue(m_PageContext, s16);
        if(s17 == null || "".equals(s17))
            s17 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pCustomView");
        if(s17 != null)
        {
            requestinfo.setCustomViewName(s17);
            oracle.apps.bis.common.ServletWrapper.putSessionValue(m_PageContext, s16, s17);
        }
        java.lang.String s18 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pReportType");
        if("LOV".equals(s18))
            requestinfo.setIsLovReport(true);
        java.lang.String s19 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pDispRun");
        if(s19 != null)
            requestinfo.setDispRun(s19);
        if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "persNoOfRows") != null)
        {
            java.lang.String s20 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "persNoOfRows");
            requestinfo.setPersNoOfRows(s20);
        }
        if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pResetDefault") != null)
        {
            java.lang.String s21 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pResetDefault");
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s21))
                requestinfo.setResetToDefault("N");
            else
                requestinfo.setResetToDefault(s21);
        }
        if("Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pResetView")))
            requestinfo.setResetToDefault(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pResetView"));
        return requestinfo;
    }

    private java.lang.String getParameterBeanString()
    {
        java.lang.String s = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "refreshParameters");
        java.lang.String s1 = "";
        if(m_UserSession.getPageContext() == null && m_PageContext != null)
            m_UserSession.setPageContext(m_PageContext);
        od.oracle.apps.xxcrm.bis.pmv.parameters.ODPMVParameterBean pmvparameterbean = new ODPMVParameterBean(m_UserSession);
        if("Y".equals(s))
            s1 = pmvparameterbean.getDivContent();
        else
            s1 = pmvparameterbean.toHTMLString();
        return s1;
    }

    public void renderSchedule(java.sql.Connection connection)
        throws java.io.IOException, oracle.apps.bis.pmv.PMVException
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(5000);
        boolean flag = false;
        boolean flag2 = "SONAR".equals(m_UserSession.getRequestInfo().getMode());
        if(flag2)
        {
            java.lang.String s = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "nlsLangCode");
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
                m_WebAppsContext.setCurrLang(s);
        } else
        {
            od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.populateNLSInfo(m_WebAppsContext);
        }
        oracle.apps.bis.pmv.session.RequestInfo requestinfo = m_UserSession.getRequestInfo();
        java.lang.String s1 = requestinfo.getRequestType();
        java.lang.String s2 = "";
        java.lang.String s4 = "";
        java.lang.String s5 = "";
        java.lang.String s8 = requestinfo.getFileId();
        boolean flag3 = "G".equals(s1) || "T".equals(s1);
        if(m_PlugId == null || m_PlugId.equals(""))
            oracle.apps.bis.pmv.session.UserSession.pmRegion = "Report";
        else
            oracle.apps.bis.pmv.session.UserSession.pmRegion = "PMRegion";
        boolean flag4 = false;
        boolean flag5 = false;
        boolean flag6 = false;
        boolean flag7 = false;
        boolean flag8 = false;
        if("R".equals(s1) || "G".equals(s1))
            flag4 = true;
        if("R".equals(s1) || "T".equals(s1))
            flag5 = true;
        if("G".equals(s1))
            flag8 = true;
        if("T".equals(s1))
            flag7 = true;
        if("R".equals(s1))
        {
            flag6 = true;
            flag8 = false;
            flag7 = false;
        }
        Object obj = null;
        if(m_ParamHelper == null)
            m_ParamHelper = new ParameterHelper(m_UserSession, connection);
        java.lang.String s9 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getCustomViewName(connection, m_UserSession.getFunctionName());
        if(s9 != null)
            m_UserSession.getRequestInfo().setCustomViewName(s9);
        m_UserSession.setCustomizedAKRegion(m_ParamHelper, null);
        od.oracle.apps.xxcrm.bis.pmv.parameters.ODPMVParameterBean pmvparameterbean = new ODPMVParameterBean(m_UserSession);
        if("R".equals(s1))
        {
            java.lang.String s10 = oracle.apps.bis.pmv.header.HeaderBean.renderHeader(m_UserSession, connection);
            m_Content.append(s10);
            if(flag2 || flag3)
                saveReportToDb(s8, flag6, s10, connection);
            flag6 = false;
            s10 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getStyleSheetNameWithFullPath(m_WebAppsContext);
            m_Content.append(s10);
            if(flag2 || flag3)
                saveReportToDb(s8, flag6, s10, connection);
            java.lang.String s3;
            if(!flag2)
            {
                m_UserSession.setFromConc(true);
                m_UserSession.getRequestInfo().setIsPrintable(true);
                s3 = pmvparameterbean.toHTMLString();
                boolean flag1 = !m_UserSession.getAKRegion().getInfoTips().isEmpty();
                if(flag1)
                    s3 = s3.concat(getInfoTipString());
            } else
            {
                s3 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getDottedLine(m_UserSession);
                saveReportToDb(s8, flag6, s3, connection);
            }
            m_Content.append(s3);
        }
        if(flag4 || flag5)
        {
            oracle.apps.bis.pmv.report.ReportDataSource reportdatasource = new ReportDataSource(m_UserSession);
            java.util.Vector vector = reportdatasource.getDataRows();
            m_UserSession.setPortletMode(flag3);
            od.oracle.apps.xxcrm.bis.pmv.data.ODPMVProvider pmvprovider = new ODPMVProvider(m_UserSession, m_ParamHelper, vector);
            m_rootNode = pmvprovider.getPMVMetadata();
            m_Renderer = new Renderer(pmvprovider, m_rootNode, m_PageContext, m_WebAppsContext, connection);
        }
        if(flag4)
            if("G".equals(s1))
            {
                int i = java.lang.Integer.parseInt(getGraphNumber(requestinfo.getScheduleId(), s8, connection));
                java.lang.String s13 = getGraphFileId(requestinfo.getScheduleId(), "GRAPH_FILE_ID", connection);
                java.lang.String s6;
                if(m_PageContext == null)
                {
                    java.lang.String s14 = getContextValues(requestinfo.getScheduleId(), "RENDERING_CONTEXT_VALUES", connection);
                    s6 = m_Renderer.getDBGraphHTML(i, s13, s14, null, m_Locale);
                } else
                {
                    s6 = m_Renderer.getDBGraphHTML(i, s13);
                }
                if(!"".equals(s8))
                {
                    m_Content.append(s6);
                    if(flag2 || flag3)
                        saveReportToDb(requestinfo.getFileId(), flag8, s6, connection);
                    updateFileType(s8, connection);
                } else
                {
                    stringbuffer.append(s6);
                }
            } else
            if("R".equals(s1))
            {
                java.lang.String s7 = getGraphs(connection, true);
                m_Content.append(s7);
                if(flag2)
                    saveReportToDb(requestinfo.getFileId(), flag8, s7, connection);
            }
        if(flag5)
        {
            if(!"TEST".equals(m_Env))
                s4 = m_Renderer.getTableHTML();
            if(!"".equals(s8))
            {
                m_Content.append(s4);
                if(flag2 || flag3)
                    saveReportToDb(requestinfo.getFileId(), flag7, s4, connection);
            } else
            {
                stringbuffer.append(s4);
            }
        }
        if("R".equals(s1))
        {
            try
            {
                java.lang.String s12 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getLastUpdateString(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getLastRefreshDateString(m_UserSession.getFunctionName(), m_UserSession.getConnection(), "REPORT"), m_UserSession);
                m_Content.append(s12);
                if(s12 != null && !"".equals(s12) && flag2)
                    saveReportToDb(s8, false, s12, connection);
            }
            catch(java.lang.Exception _ex) { }
            if(!flag2)
            {
                java.lang.String s11 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getSkiImage(m_UserSession, m_WebAppsContext);
                m_Content.append(s11);
                s11 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getCopyRight(m_WebAppsContext);
                m_Content.append(s11);
            }
            requestinfo.getFileId();
        }
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(stringbuffer.toString()))
            m_Out.println(stringbuffer.toString());
    }

    private boolean roleExists(java.lang.String s, java.sql.Connection connection)
    {
        int i = 0;
        java.lang.String s1 = " select count(1) from wf_local_roles where name = :1";
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        try
        {
            preparedstatement = connection.prepareStatement(s1);
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            oraclestatement.defineColumnType(1, 2);
            preparedstatement.setString(1, s);
            for(resultset = preparedstatement.executeQuery(); resultset.next();)
                i = resultset.getInt(1);

        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(preparedstatement != null)
                    preparedstatement.close();
                if(resultset != null)
                    resultset.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        return i > 0;
    }

    protected void saveReportToDb(java.lang.String s, boolean flag, java.lang.String s1, java.sql.Connection connection)
    {
        int i = s1.length();
        boolean flag1 = false;
        java.lang.String s2 = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        java.lang.String s3 = "";
        if(i < 32000)
        {
            byte abyte0[] = null;
            try
            {
                abyte0 = s1.getBytes(s2);
            }
            catch(java.io.UnsupportedEncodingException _ex)
            {
                abyte0 = s1.getBytes();
            }
            int j = abyte0.length;
            if(flag)
            {
                saveReport(abyte0, java.lang.String.valueOf(j), connection, s);
                return;
            } else
            {
                appendReport(abyte0, java.lang.String.valueOf(j), connection, s);
                return;
            }
        }
        int l = i / 32000;
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(11);
        int i1 = 32000;
        int j1 = 0;
        for(int k1 = 0; k1 < l; k1++)
        {
            java.lang.String s4 = s1.substring(j1, i1);
            j1 += 32000;
            i1 += 32000;
            arraylist.add(s4);
        }

        if(i1 - 32000 < i)
            arraylist.add(s1.substring(i1 - 32000, i));
        for(int l1 = 0; l1 < arraylist.size(); l1++)
        {
            java.lang.String s5 = (java.lang.String)arraylist.get(l1);
            byte abyte1[] = null;
            try
            {
                abyte1 = s5.getBytes(s2);
            }
            catch(java.io.UnsupportedEncodingException _ex)
            {
                abyte1 = s5.getBytes();
            }
            int k = abyte1.length;
            if(l1 == 0)
            {
                if(flag)
                    saveReport(abyte1, java.lang.String.valueOf(k), connection, s);
                else
                    appendReport(abyte1, java.lang.String.valueOf(k), connection, s);
            } else
            {
                appendReport(abyte1, java.lang.String.valueOf(k), connection, s);
            }
        }

    }

    protected void saveReport(byte abyte0[], java.lang.String s, java.sql.Connection connection, java.lang.String s1)
    {
        java.lang.String s2 = "BEGIN BIS_SAVE_REPORT.INITWRITE(:1,:2,:3); END;";
        java.sql.CallableStatement callablestatement = null;
        try
        {
            callablestatement = connection.prepareCall(s2);
            callablestatement.setString(1, s1);
            callablestatement.setString(2, s);
            callablestatement.setBytes(3, abyte0);
            callablestatement.execute();
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(callablestatement != null)
                    callablestatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
    }

    protected void appendReport(byte abyte0[], java.lang.String s, java.sql.Connection connection, java.lang.String s1)
    {
        java.lang.String s2 = "BEGIN BIS_SAVE_REPORT.APPENDWRITE(:1,:2,:3); END;";
        java.sql.CallableStatement callablestatement = null;
        try
        {
            callablestatement = connection.prepareCall(s2);
            callablestatement.setString(1, s1);
            callablestatement.setString(2, s);
            callablestatement.setBytes(3, abyte0);
            callablestatement.execute();
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(callablestatement != null)
                    callablestatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
    }

    public java.lang.String getScheduleURL()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(2000);
        java.lang.String s = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getPlsqlAgent(m_WebAppsContext));
        stringbuffer.append("BIS_RG_SCHEDULES_PVT.SHOWDEFAULTSCHEDULEPAGE?");
        try
        {
            stringbuffer.append("pRegionCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getRegionCode(), s));
            stringbuffer.append("&pFunctionName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getFunctionName(), s));
            stringbuffer.append("&pApplicationId=").append(java.lang.String.valueOf(m_WebAppsContext.getAppId("BIS")));
            stringbuffer.append("&pSessionId=").append(m_UserSession.getSessionId());
            stringbuffer.append("&pUserId=").append(m_UserSession.getUserId());
            stringbuffer.append("&pResponsibilityId=").append(m_UserSession.getResponsibilityId());
            stringbuffer.append("&pViewBy=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_ParamHelper.getViewbyValue(), s));
            java.lang.String s1 = "R";
            java.lang.String s2 = "";
            java.lang.String s3 = "";
            java.lang.String s4 = "";
            if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pTrendType") != null)
                s1 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pTrendType");
            if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pPlugId") != null)
                s2 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pPlugId");
            if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pGraphNumber") != null)
                s3 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pGraphNumber");
            if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pReportTitle") != null)
                s4 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pReportTitle");
            stringbuffer.append("&pRequestType=").append(s1);
            stringbuffer.append("&pPlugId=").append(s2);
            stringbuffer.append("&pGraphType=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s3, s));
            stringbuffer.append("&pReportTitle=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s4, s));
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        return stringbuffer.toString();
    }

    public java.lang.String renderPortlet(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5, java.lang.String s6,
            java.lang.String s7, java.lang.String s8, java.sql.Connection connection, oracle.apps.fnd.common.WebAppsContext webappscontext, oracle.apps.bis.pmv.session.UserSession usersession, javax.servlet.jsp.PageContext pagecontext, java.lang.String s9)
        throws oracle.apps.bis.pmv.PMVException
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(20000);
        usersession.getPlugId();
        oracle.apps.bis.msg.MessageLog messagelog = usersession.getPmvMsgLog();
        int i = 0x7fffffff;
        if(messagelog != null)
            i = messagelog.getLevel();
        m_Request = (javax.servlet.http.HttpServletRequest)pagecontext.getRequest();
        java.lang.String s10 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "email");
        java.lang.String s11 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "designer");
        usersession.getRequestInfo().setIsPageDesigner("Y".equals(s11));
        java.lang.String s12 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "fromExport");
        boolean flag = "EXPORT_TO_PDF".equals(s12);
        if("Y".equals(s10))
            usersession.getRequestInfo().setIsEmail(true);
        else
            usersession.getRequestInfo().setIsEmail(false);
        if("P".equals(s4) && messagelog != null && (i == 5 || i == 1000))
            try
            {
                messagelog.closeProgress("PMV Report Setup");
                messagelog.newProgress("Query Generation");
            }
            catch(java.lang.Exception _ex) { }
        initPortletSchedule(s, s1, s2, s3, s4, s5, s6, s7, s8, connection, webappscontext, usersession, pagecontext);
        if(m_ParamHelper == null)
            m_ParamHelper = new ParameterHelper(m_UserSession, connection);
        if("P".equals(s4) && messagelog != null && (i == 5 || i == 1000))
            try
            {
                messagelog.closeProgress("Query Generation");
            }
            catch(java.lang.Exception _ex) { }
        if("P".equals(s4))
        {
            if(messagelog != null && (i == 5 || i == 1000))
                try
                {
                    messagelog.newProgress("PMV Query Execution");
                }
                catch(java.lang.Exception _ex) { }
            java.lang.StringBuffer stringbuffer1 = new StringBuffer(2000);
            java.lang.String s13 = m_UserSession.getRequestInfo().getParameterDisplayOnly();
            if(!flag)
            {
                if(m_UserSession.getRequestInfo() != null && ("Y".equals(s10) || "Y".equals(s13)))
                    m_UserSession.getRequestInfo().setIsPrintable(true);
                else
                    m_UserSession.getRequestInfo().setIsPrintable(false);
                stringbuffer1.append(getParameterBeanString());
                if(messagelog != null && (i == 5 || i == 1000))
                {
                    if(i == 5)
                        messagelog.logMessage("PMV Query Execution", "For the page level parameter portlet, the time taken for the execution of the query is really the time taken to initialize the parameter section of the portlet", i);
                    try
                    {
                        messagelog.closeProgress("PMV Query Execution");
                        messagelog.newProgress("Portlet Rendering");
                        if(i == 1000)
                            messagelog.logMessage("Report Rendering", "Entire Portlet Rendering Process", i);
                    }
                    catch(java.lang.Exception _ex) { }
                }
            } else
            {
                oracle.apps.bis.pmv.parameters.StreamPDFParameterBean streampdfparameterbean = new StreamPDFParameterBean(m_UserSession, m_ParamHelper, m_PageContext);
                stringbuffer1.append(streampdfparameterbean.streamParameterPortlet());
            }
            stringbuffer.append(stringbuffer1.toString());
        } else
        {
            usersession.setCustomizedAKRegion(m_ParamHelper, null);
            oracle.apps.bis.pmv.report.ReportDataSource reportdatasource = new ReportDataSource(m_UserSession);
            java.util.Vector vector = reportdatasource.getDataRows();
            m_UserSession.setPortletMode(true);
            if(flag)
                m_UserSession.getRequestInfo().setMode("EXPORT_PAGE_TO_PDF");
            od.oracle.apps.xxcrm.bis.pmv.data.ODPMVProvider pmvprovider = new ODPMVProvider(m_UserSession, m_ParamHelper, vector);
            m_rootNode = pmvprovider.getPMVMetadata();
            oracle.apps.bis.renderer.Renderer renderer = new Renderer(pmvprovider, m_rootNode, m_PageContext, m_WebAppsContext, connection);
            renderer.setPmvMsgLog(messagelog);
            renderer.setProgName("Portlet Rendering");
            if("G".equals(s4))
            {
                int j = 1;
                if(s9 != null && s9.length() > 0)
                    j = java.lang.Integer.parseInt(s9);
                java.lang.String s15 = null;
                if(m_PageContext != null && !"Y".equals(s10) && !flag && "online".equals((java.lang.String)m_PageContext.getSession().getValue("grphrender")))
                {
                    s15 = renderer.getGraphHTML(j, m_UserSession.getNLSServices().getUserLocaleContext());
                } else
                {
                    java.lang.String s16 = m_UserSession.getRequestInfo().getGraphGIFFileName();
                    java.lang.String s17 = m_UserSession.getRequestInfo().getGraphGIFSrcPath();
                    s15 = renderer.getGIFGraphHTML(j, s16, s17, m_UserSession.getNLSServices().getUserLocaleContext());
                    if(flag)
                    {
                        java.lang.String s18 = (java.lang.String)m_PageContext.getAttribute("GIF_FILE_NAME", 3);
                        java.lang.String s19 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(m_WebAppsContext) + "fwk/t/";
                        java.lang.String s20 = s19 + s18;
                        if(s15 != null)
                        {
                            java.lang.StringBuffer stringbuffer2 = new StringBuffer(400);
                            stringbuffer2.append("<GRAPH>");
                            stringbuffer2.append(oracle.apps.bis.pmv.common.ExportUtil.getTagWithData(s20, "<GRAPHURL>", "</GRAPHURL>"));
                            stringbuffer2.append("</GRAPH>");
                            s15 = stringbuffer2.toString();
                        } else
                        {
                            s15 = "";
                        }
                    }
                }
                stringbuffer.append(s15);
            } else
            {
                java.lang.String s14 = "";
                if(!"TEST".equals(m_Env))
                    if(flag)
                        try
                        {
                            s14 = renderer.streamPdfTableData(false);
                        }
                        catch(java.io.IOException _ex) { }
                    else
                        s14 = renderer.getTableHTML();
                stringbuffer.append(s14);
            }
        }
        return stringbuffer.toString();
    }

    private boolean isOAPage(java.lang.String s)
    {
        return s != null && s.startsWith("-");
    }

    private void initPortletSchedule(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5, java.lang.String s6,
            java.lang.String s7, java.lang.String s8, java.sql.Connection connection, oracle.apps.fnd.common.WebAppsContext webappscontext, oracle.apps.bis.pmv.session.UserSession usersession, javax.servlet.jsp.PageContext pagecontext)
    {
        oracle.apps.bis.pmv.session.RequestInfo requestinfo = usersession.getRequestInfo();
        if(requestinfo == null)
            requestinfo = new RequestInfo();
        m_WebAppsContext = webappscontext;
        java.lang.String s9 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getPageId(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getUrlParamValue(s2, "_pageid"), webappscontext);
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s9))
        {
            s9 = oracle.apps.bis.common.ServletWrapper.getParameter(pagecontext, "_pageid");
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s9))
                s9 = oracle.apps.bis.common.ServletWrapper.getHeaderAttribute(pagecontext, "x-oracle-portal-page-id");
            if(s9 != null)
                s9 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getPageId(s9, webappscontext);
        }
        requestinfo.setPageURL(s2);
        requestinfo.setPageId(s9);
        requestinfo.setDBC(s1);
        requestinfo.setTxId(s);
        requestinfo.setScheduleId(s3);
        requestinfo.setMode("SCHEDULE");
        requestinfo.setParamType("SCHEDULE");
        requestinfo.setIsPrintable(true);
        requestinfo.setRequestType(s4);
        requestinfo.setFileId(s7);
        requestinfo.setRerunLink(false);
        if(s8 != null && s8.length() > 0)
            requestinfo.setCSVFileName(s8);
        m_Env = webappscontext.getProfileStore().getProfile("BIS_ENVIRONMENT");
        if(m_Env == null)
            m_Env = "";
        m_UserSession = usersession;
        if(isOAPage(s9))
        {
            m_UserSession.setUserId(java.lang.Integer.toString(webappscontext.getUserId()));
            m_UserSession.setResponsibilityId(java.lang.Integer.toString(webappscontext.getRespId()));
        } else
        {
            java.lang.String s10 = " SELECT user_id, responsibility_id FROM bis_scheduler WHERE schedule_id = :1";
            java.sql.PreparedStatement preparedstatement = null;
            java.sql.ResultSet resultset = null;
            try
            {
                preparedstatement = connection.prepareStatement(s10);
                oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
                oraclestatement.defineColumnType(1, 12, 80);
                oraclestatement.defineColumnType(2, 12, 10);
                preparedstatement.setString(1, s3);
                for(resultset = preparedstatement.executeQuery(); resultset.next(); m_UserSession.setResponsibilityId(resultset.getString(2)))
                    m_UserSession.setUserId(resultset.getString(1));

            }
            catch(java.sql.SQLException _ex) { }
            finally
            {
                try
                {
                    if(resultset != null)
                        resultset.close();
                    if(preparedstatement != null)
                        preparedstatement.close();
                }
                catch(java.lang.Exception _ex) { }
            }
        }
        m_UserSession.setRequestInfo(requestinfo);
        m_PageContext = pagecontext;
    }

    public void download(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.sql.Connection connection, oracle.apps.fnd.common.WebAppsContext webappscontext, oracle.apps.bis.pmv.session.UserSession usersession)
        throws oracle.apps.bis.pmv.PMVException
    {
        initDownloadSchedule(s, s1, s2, s3, connection, webappscontext, usersession);
        java.lang.String s4 = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        if(m_ParamHelper == null)
            m_ParamHelper = new ParameterHelper(m_UserSession, connection);
        oracle.apps.bis.pmv.report.ReportBean reportbean = new ReportBean(m_UserSession);
        reportbean.executeQuery();
        try
        {
            oracle.apps.bis.common.ServletWrapper.sendRedirect(m_Response, oracle.cabo.share.url.EncoderUtils.encodeURL(reportbean.getCsvDownloadFileName(), s4, true));
            return;
        }
        catch(java.io.IOException _ex)
        {
            return;
        }
    }

    private void initDownloadSchedule(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.sql.Connection connection, oracle.apps.fnd.common.WebAppsContext webappscontext, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        oracle.apps.bis.pmv.session.RequestInfo requestinfo = new RequestInfo();
        m_WebAppsContext = webappscontext;
        requestinfo.setScheduleId(s);
        requestinfo.setFileId(s1);
        requestinfo.setMode("SCHEDULE");
        requestinfo.setParamType("SCHEDULE");
        requestinfo.setCsvDownloadMode(true);
        m_UserSession = usersession;
        java.lang.String s4 = " SELECT user_id, responsibility_id FROM bis_scheduler WHERE schedule_id = :1";
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        try
        {
            preparedstatement = connection.prepareStatement(s4);
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            oraclestatement.defineColumnType(1, 12, 80);
            oraclestatement.defineColumnType(2, 12, 10);
            preparedstatement.setString(1, s);
            for(resultset = preparedstatement.executeQuery(); resultset.next(); m_UserSession.setResponsibilityId(resultset.getString(2)))
                m_UserSession.setUserId(resultset.getString(1));

        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(resultset != null)
                    resultset.close();
                if(preparedstatement != null)
                    preparedstatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        m_UserSession.setApplication(m_Application);
        m_UserSession.setPageContext(m_PageContext);
        m_UserSession.setRequestInfo(requestinfo);
    }

    private java.lang.String getGraphNumber(java.lang.String s, java.lang.String s1, java.sql.Connection connection)
    {
        java.lang.String s2 = "";
        java.lang.String s3 = "SELECT distinct graph_type  FROM bis_schedule_preferences  where schedule_id=:1 and nvl(file_id, 0)=nvl(:2, 0)";
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        try
        {
            preparedstatement = connection.prepareStatement(s3);
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            oraclestatement.defineColumnType(1, 12, 20);
            preparedstatement.setString(1, s);
            preparedstatement.setString(2, s1);
            for(resultset = preparedstatement.executeQuery(); resultset.next();)
                s2 = resultset.getString(1);

        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(resultset != null)
                    resultset.close();
                if(preparedstatement != null)
                    preparedstatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        if(s2 != null && !s2.equals(""))
            return s2;
        else
            return "1";
    }

    private void updateFileType(java.lang.String s, java.sql.Connection connection)
    {
        java.lang.String s1 = " UPDATE fnd_lobs set file_content_Type='TEXT/HTML' where file_id= :1 ";
        java.sql.PreparedStatement preparedstatement = null;
        try
        {
            preparedstatement = connection.prepareStatement(s1);
            preparedstatement.setString(1, s);
            preparedstatement.executeUpdate();
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(preparedstatement != null)
                    preparedstatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
    }

    private java.lang.String getGraphFileId(java.lang.String s, java.lang.String s1, java.sql.Connection connection)
    {
        java.lang.String s2 = getSavedGraphFileId(s, s1, connection);
        boolean flag = false;
        if(!"-1".equals(s2))
            flag = isLobSavedFileId(s2, connection);
        if(!flag)
        {
            s2 = oracle.apps.bis.pmv.common.FndLobsHelper.getNewFileId(connection, "image/gif");
            saveGraphFileId(s, s1, java.lang.String.valueOf(s2), connection);
        }
        return s2;
    }

    private java.lang.String getSavedGraphFileId(java.lang.String s, java.lang.String s1, java.sql.Connection connection)
    {
        java.lang.String s2 = "";
        java.lang.String s3 = "BEGIN BIS_PMV_PARAMETERS_PVT.RETRIEVE_GRAPH_FILEID(:1,:2,:3,:4,:5); END;";
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        try
        {
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s3);
            oraclecallablestatement.setString(1, m_UserSession.getUserId());
            oraclecallablestatement.setString(2, s);
            oraclecallablestatement.setString(3, s1);
            oraclecallablestatement.setString(4, m_UserSession.getFunctionName());
            oraclecallablestatement.registerOutParameter(5, 12, 0, 20);
            oraclecallablestatement.execute();
            s2 = oraclecallablestatement.getString(5);
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(oraclecallablestatement != null)
                    oraclecallablestatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        if(oracle.apps.bis.pmv.common.Logger.isLogEnabled(m_WebAppsContext))
        {
            oracle.apps.bis.pmv.common.Logger.Log("RETRIEVE FUNCTIONAME : " + m_UserSession.getFunctionName(), m_WebAppsContext);
            oracle.apps.bis.pmv.common.Logger.Log("RETRIEVE GRAPHFILEID : " + s2, m_WebAppsContext);
            oracle.apps.bis.pmv.common.Logger.Log("RETRIEVE SCHEDULEID : " + s, m_WebAppsContext);
            oracle.apps.bis.pmv.common.Logger.Log("RETRIEVE ATTRIBUTENAME : " + s1, m_WebAppsContext);
        }
        if(s2 != null && !s2.trim().equals(""))
            return s2;
        else
            return "-1";
    }

    private void saveGraphFileId(java.lang.String s, java.lang.String s1, java.lang.String s2, java.sql.Connection connection)
    {
        java.lang.String s3 = "BEGIN BIS_PMV_PARAMETERS_PVT.SAVE_GRAPH_FILEID(:1,:2,:3,:4,:5); END;";
        java.sql.CallableStatement callablestatement = null;
        try
        {
            callablestatement = connection.prepareCall(s3);
            callablestatement.setString(1, m_UserSession.getUserId());
            callablestatement.setString(2, s);
            callablestatement.setString(3, s1);
            callablestatement.setString(4, m_UserSession.getFunctionName());
            callablestatement.setString(5, s2);
            callablestatement.execute();
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(callablestatement != null)
                    callablestatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        if(oracle.apps.bis.pmv.common.Logger.isLogEnabled(m_WebAppsContext))
        {
            oracle.apps.bis.pmv.common.Logger.Log("SAVE FUNCTIONAME : " + m_UserSession.getFunctionName(), m_WebAppsContext);
            oracle.apps.bis.pmv.common.Logger.Log("SAVE GRAPHFILEID : " + s2, m_WebAppsContext);
            oracle.apps.bis.pmv.common.Logger.Log("SAVE SCHEDULEID : " + s, m_WebAppsContext);
            oracle.apps.bis.pmv.common.Logger.Log("SAVE ATTRIBUTENAME : " + s1, m_WebAppsContext);
        }
    }

    private boolean isLobSavedFileId(java.lang.String s, java.sql.Connection connection)
    {
        java.lang.String s1 = "";
        java.lang.String s2 = " SELECT file_id  FROM fnd_lobs  where file_id=:1";
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        try
        {
            preparedstatement = connection.prepareStatement(s2);
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            oraclestatement.defineColumnType(1, 12, 20);
            preparedstatement.setString(1, s);
            for(resultset = preparedstatement.executeQuery(); resultset.next();)
                s1 = resultset.getString(1);

        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(resultset != null)
                    resultset.close();
                if(preparedstatement != null)
                    preparedstatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        return s1 != null && !s1.trim().equals("");
    }

    private java.lang.String getContextValues(java.lang.String s, java.lang.String s1, java.sql.Connection connection)
    {
        java.lang.String s2 = "";
        java.lang.String s3 = "BEGIN BIS_PMV_PARAMETERS_PVT.RETRIEVE_CONTEXT_VALUES(:1,:2,:3,:4,:5); END;";
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        try
        {
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s3);
            oraclecallablestatement.setString(1, m_UserSession.getUserId());
            oraclecallablestatement.setString(2, s);
            oraclecallablestatement.setString(3, s1);
            oraclecallablestatement.setString(4, m_UserSession.getFunctionName());
            oraclecallablestatement.registerOutParameter(5, 12, 0, 300);
            oraclecallablestatement.execute();
            s2 = oraclecallablestatement.getString(5);
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(oraclecallablestatement != null)
                    oraclecallablestatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        if(oracle.apps.bis.pmv.common.Logger.isLogEnabled(m_WebAppsContext))
        {
            oracle.apps.bis.pmv.common.Logger.Log("RETRIEVE FUNCTIONNAME : " + m_UserSession.getFunctionName(), m_WebAppsContext);
            oracle.apps.bis.pmv.common.Logger.Log("RETRIEVE CONTEXT VALUES : " + s2, m_WebAppsContext);
            oracle.apps.bis.pmv.common.Logger.Log("RETRIEVE SCHEDULEID : " + s, m_WebAppsContext);
            oracle.apps.bis.pmv.common.Logger.Log("RETRIEVE ATTRIBUTENAME : " + s1, m_WebAppsContext);
        }
        if(s2 == null)
            s2 = "";
        return s2;
    }

    private boolean showGraphFootnote(int i)
    {
        boolean flag = false;
        oracle.apps.bis.metadata.MetadataDistributor metadatadistributor = new MetadataDistributor(m_rootNode);
        com.sun.java.util.collections.ArrayList arraylist = metadatadistributor.getGraphNodes();
        oracle.apps.bis.metadata.MetadataNode metadatanode = (oracle.apps.bis.metadata.MetadataNode)arraylist.get(i - 1);
        oracle.apps.bis.metadata.MetadataNode metadatanode1 = metadatanode.findChild("Y1Axis");
        oracle.apps.bis.metadata.MetadataNode metadatanode2 = metadatanode.findChild("Y2Axis");
        java.lang.String s = "";
        try
        {
            if(metadatanode1 != null)
                s = (java.lang.String)metadatanode1.getAttribute("applyScaleFactor");
        }
        catch(java.lang.Exception _ex) { }
        try
        {
            if((s == null || s.equals("")) && metadatanode2 != null)
                s = (java.lang.String)metadatanode2.getAttribute("applyScaleFactor");
        }
        catch(java.lang.Exception _ex) { }
        if(s != null && s.equals("true"))
            flag = true;
        return flag;
    }

    protected boolean showTableFootnote()
    {
        boolean flag = false;
        oracle.apps.bis.metadata.MetadataDistributor metadatadistributor = new MetadataDistributor(m_rootNode);
        com.sun.java.util.collections.ArrayList arraylist = metadatadistributor.getDataSetNodes();
        for(int i = 0; i < arraylist.size();)
        {
            oracle.apps.bis.metadata.MetadataNode metadatanode = (oracle.apps.bis.metadata.MetadataNode)arraylist.get(i);
            try
            {
                java.lang.String s = (java.lang.String)metadatanode.getAttribute("hideScaleSymbol");
                if(s == null || !s.equals("true"))
                    continue;
                flag = true;
                break;
            }
            catch(java.lang.Exception _ex)
            {
                i++;
            }
        }

        return flag;
    }

    public void invokeEmailPage()
        throws java.io.IOException
    {
        java.lang.String s = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "dbc");
        if("Y".equals(oracle.apps.bis.common.ServletWrapper.getSessionValue(m_PageContext, "EMAIL" + m_UserSession.getFunctionName())))
        {
            java.lang.StringBuffer stringbuffer = new StringBuffer(500);
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(m_WebAppsContext));
            java.lang.String s2 = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
            stringbuffer.append("OA.jsp?akRegionCode=BISPMVEMAILINGPAGE").append("&akRegionApplicationId=191");
            try
            {
                stringbuffer.append("&dbc=").append(s);
                stringbuffer.append("&language=").append(m_WebAppsContext.getCurrLangCode());
                stringbuffer.append("&transactionid=").append(m_UserSession.getTransactionId());
                stringbuffer.append("&sessionid=").append(m_UserSession.getSessionId());
                stringbuffer.append("&regionCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getRegionCode(), s2));
                stringbuffer.append("&functionName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getFunctionName(), s2));
                stringbuffer.append("&pObjectType=REPORT");
                if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pReportTitle") != null)
                    stringbuffer.append("&pReportTitle=").append(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pReportTitle"));
                boolean flag = m_UserSession.getRequestInfo().isForecastGraphEnabled();
                if(flag)
                    stringbuffer.append("&pEnableForecastGraph=Y");
                stringbuffer.append(getBackUrl());
                if(m_UserSession.isUserCustomization() && m_UserSession.isViewExists() && !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_UserSession.getCustomCode()) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_UserSession.getUserViewName()))
                    stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&userViewName=", s2)).append(oracle.cabo.share.url.EncoderUtils.encodeString(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getUserViewName(), s2), s2));
            }
            catch(java.io.UnsupportedEncodingException _ex) { }
            oracle.apps.fnd.security.HMAC hmac1 = getMACKey();
            oracle.apps.bis.common.ServletWrapper.sendRedirect(m_Response, oracle.cabo.share.url.EncoderUtils.encodeURL(oracle.apps.fnd.framework.webui.URLMgr.processOutgoingURL(stringbuffer.toString(), hmac1), oracle.apps.bis.common.ServletWrapper.getCharacterEncoding(m_Response), true));
            return;
        } else
        {
            java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_NEED_TO_RUN", m_WebAppsContext);
            oracle.apps.bis.common.ServletWrapper.sendRedirect(m_Response, oracle.cabo.share.url.EncoderUtils.encodeURL(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getErrorUrl(m_UserSession, s1, m_Request, m_PageContext), oracle.apps.bis.common.ServletWrapper.getCharacterEncoding(m_Response), true));
            return;
        }
    }

    public void invokePersonalizePage()
    {
        java.lang.String s = "";
        oracle.apps.fnd.security.HMAC hmac1 = getMACKey();
        try
        {
            s = oracle.cabo.share.url.EncoderUtils.encodeURL(oracle.apps.fnd.framework.webui.URLMgr.processOutgoingURL(getPersonalizeButtonUrl(true), hmac1), oracle.apps.bis.common.ServletWrapper.getCharacterEncoding(m_Response), true);
        }
        catch(java.io.IOException _ex) { }
        oracle.apps.bis.common.ServletWrapper.sendRedirect(m_Response, s);
    }

    public void invokePersonalizeViewPage()
    {
        java.lang.String s = "";
        oracle.apps.fnd.security.HMAC hmac1 = getMACKey();
        try
        {
            s = oracle.cabo.share.url.EncoderUtils.encodeURL(oracle.apps.fnd.framework.webui.URLMgr.processOutgoingURL(getPersonalizeButtonUrl(false), hmac1), oracle.apps.bis.common.ServletWrapper.getCharacterEncoding(m_Response), true);
        }
        catch(java.io.IOException _ex) { }
        oracle.apps.bis.common.ServletWrapper.sendRedirect(m_Response, s);
    }

    private java.lang.String getPersonalizeButtonUrl(boolean flag)
    {
        java.lang.String s = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "dbc");
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append(oracle.apps.bis.pmv.common.PMVUtil.getJspAgent(m_WebAppsContext));
        java.lang.String s1 = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        if(flag)
            stringbuffer.append("OA.jsp?akRegionCode=BISPMVRLLISTPAGE");
        else
            stringbuffer.append("OA.jsp?akRegionCode=BIS_PMV_UI_LIST_CUSTOM_VIEW");
        stringbuffer.append("&akRegionApplicationId=191");
        stringbuffer.append("&retainAM=Y");
        try
        {
            stringbuffer.append("&custRegionCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getRegionCode(), s1));
            stringbuffer.append("&custRegionApplId=").append(m_UserSession.getAKRegion().getRegionApplicationId());
            stringbuffer.append("&custFunctionName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getFunctionName(), s1));
            stringbuffer.append("&pViewBy=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_ParamHelper.getViewbyValue(), s1));
            stringbuffer.append("&dbc=").append(s);
            stringbuffer.append("&language=").append(m_WebAppsContext.getCurrLangCode());
            stringbuffer.append("&transactionid=").append(m_UserSession.getTransactionId());
            stringbuffer.append("&sessionid=").append(m_UserSession.getSessionId());
            if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pReportTitle") != null)
                stringbuffer.append("&pReportTitle=").append(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pReportTitle"));
            stringbuffer.append("&pCustomView=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getAKRegion().getCustomViewName(), s1));
            stringbuffer.append(getExpBackUrl());
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        return stringbuffer.toString();
    }

    public void invokePersonalizePortletPage()
    {
        java.lang.String s = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "dbc");
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(m_WebAppsContext));
        java.lang.String s1 = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        stringbuffer.append("bispcust.jsp?dbc=").append(s);
        try
        {
            stringbuffer.append("&regionCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getRegionCode(), s1));
            stringbuffer.append("&functionName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getFunctionName(), s1));
            stringbuffer.append("&pResponsibilityId=").append(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pResponsibilityId"));
            stringbuffer.append("&pSessionId=").append(m_UserSession.getSessionId());
            stringbuffer.append("&pUserId=").append(m_WebAppsContext.getUserId());
            stringbuffer.append("&pPlugId=").append(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pPlugId"));
            stringbuffer.append("&pScheduleId=").append(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pScheduleId"));
            stringbuffer.append("&pFileId=").append(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pFileId"));
            stringbuffer.append("&pScheduleOverride=Y");
            stringbuffer.append("&afterLovClick=Y");
            stringbuffer.append("&language_code=").append(m_WebAppsContext.getCurrLangCode());
            stringbuffer.append("&transactionid=").append(m_UserSession.getTransactionId());
            stringbuffer.append("&sessionid=").append(m_UserSession.getSessionId());
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        oracle.apps.bis.common.ServletWrapper.sendRedirect(m_Response, stringbuffer.toString());
    }

    public void invokeExportPage()
        throws java.io.IOException
    {
        if("Y".equals(oracle.apps.bis.common.ServletWrapper.getSessionValue(m_PageContext, "EMAIL" + m_UserSession.getFunctionName())))
        {
            java.lang.String s = "";
            oracle.apps.fnd.security.HMAC hmac1 = getMACKey();
            try
            {
                s = oracle.cabo.share.url.EncoderUtils.encodeURL(oracle.apps.fnd.framework.webui.URLMgr.processOutgoingURL(getExportButtonUrl(), hmac1), oracle.apps.bis.common.ServletWrapper.getCharacterEncoding(m_Response), true);
            }
            catch(java.io.IOException _ex) { }
            oracle.apps.bis.common.ServletWrapper.sendRedirect(m_Response, s);
            return;
        } else
        {
            java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_NEED_TO_EXPORT", m_WebAppsContext);
            oracle.apps.bis.common.ServletWrapper.sendRedirect(m_Response, oracle.cabo.share.url.EncoderUtils.encodeURL(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getErrorUrl(m_UserSession, s1, m_Request, m_PageContext), oracle.apps.bis.common.ServletWrapper.getCharacterEncoding(m_Response), true));
            return;
        }
    }

    public void invokePersonalizeParametersPage()
        throws java.io.IOException
    {
        java.lang.String s = "";
        oracle.apps.fnd.security.HMAC hmac1 = getMACKey();
        try
        {
            s = oracle.cabo.share.url.EncoderUtils.encodeURL(oracle.apps.fnd.framework.webui.URLMgr.processOutgoingURL(getPersonalizeParametersURL(), hmac1), oracle.apps.bis.common.ServletWrapper.getCharacterEncoding(m_Response), true);
        }
        catch(java.io.IOException _ex) { }
        oracle.apps.bis.common.ServletWrapper.sendRedirect(m_Response, s);
    }

    private java.lang.String getPersonalizeParametersURL()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        try
        {
            java.lang.String s = getParamBookMarkUrl();
            java.lang.String s1 = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
            stringbuffer.append("/OA_HTML/OA.jsp?page=/oracle/apps/bis/pmv/pages/BIS_EDIT_PARAMS_PAGE");
            stringbuffer.append("&custRegionCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getRegionCode(), s1));
            stringbuffer.append("&custRegionApplId=").append(m_UserSession.getAKRegion().getRegionApplicationId());
            stringbuffer.append("&custFunctionName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getFunctionName(), s1));
            if(m_UserSession.getCustomCode() != null)
                stringbuffer.append("&pCustomCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getCustomCode(), s1));
            oracle.apps.bis.common.ServletWrapper.putSessionValue(m_UserSession.getPageContext(), "pBookMarkUrl", s);
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        return stringbuffer.toString();
    }

    private java.lang.String getExportButtonUrl()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append(oracle.apps.bis.pmv.common.PMVUtil.getJspAgent(m_WebAppsContext));
        java.lang.String s = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        stringbuffer.append("OA.jsp?akRegionCode=BIS_PMV_UI_EXPORT_REGION");
        stringbuffer.append("&akRegionApplicationId=191");
        try
        {
            stringbuffer.append("&custRegionCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getRegionCode(), s));
            stringbuffer.append("&custRegionApplId=").append(m_UserSession.getAKRegion().getRegionApplicationId());
            stringbuffer.append("&custFunctionName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getFunctionName(), s));
            stringbuffer.append("&dbc=").append(m_UserSession.getRequestInfo().getDBC());
            stringbuffer.append("&language=").append(m_WebAppsContext.getCurrLangCode());
            stringbuffer.append("&transactionid=").append(m_UserSession.getTransactionId());
            stringbuffer.append("&sessionid=").append(m_UserSession.getSessionId());
            if(m_UserSession.getRequestInfo() != null && m_UserSession.getRequestInfo().getSortAttribute() != null)
                stringbuffer.append("&sortAttribute=").append(m_UserSession.getRequestInfo().getSortAttribute());
            if(m_UserSession.getRequestInfo() != null && m_UserSession.getRequestInfo().getSortDirection() != null)
                stringbuffer.append("&sortDirection=").append(m_UserSession.getRequestInfo().getSortDirection());
            if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pReportTitle") != null)
                stringbuffer.append("&pReportTitle=").append(oracle.cabo.share.url.EncoderUtils.encodeString(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pReportTitle"), s));
            boolean flag = m_UserSession.getRequestInfo().isForecastGraphEnabled();
            if(flag)
                stringbuffer.append("&pEnableForecastGraph=Y");
            stringbuffer.append("&firstTime=Y");
            stringbuffer.append(getExpBackUrl());
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        return stringbuffer.toString();
    }

    public void invokeDelegationPage()
        throws java.io.IOException
    {
        java.lang.String s = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "dbc");
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        try
        {
            oracle.apps.bis.pmv.metadata.AKRegion akregion = m_UserSession.getAKRegion();
            java.lang.String s1 = akregion.getDelegationParameter();
            java.lang.String s2 = akregion.getDelegationParameterDim();
            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = null;
            java.lang.String s3 = "-1";
            java.lang.String s4 = "";
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
            {
                try
                {
                    akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)akregion.getAKRegionItems().get(s2);
                }
                catch(java.lang.Exception _ex) { }
                if(akregionitem != null)
                {
                    s3 = akregionitem.getPrivilege();
                    s4 = akregionitem.getAttributeNameLong();
                }
            }
            java.lang.String s5 = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(m_WebAppsContext));
            stringbuffer.append("OA.jsp?page=/oracle/apps/bis/delegations/webui/BIS_DELEGATION_LIST_PGE&dbc=");
            stringbuffer.append(s);
            stringbuffer.append("&language=").append(m_WebAppsContext.getCurrLangCode());
            stringbuffer.append("&transactionid=").append(m_UserSession.getTransactionId());
            stringbuffer.append("&sessionid=").append(m_UserSession.getSessionId());
            stringbuffer.append("&delegationParameter=");
            stringbuffer.append(s1);
            stringbuffer.append("&privilege=");
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s5) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s3))
                stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString(s3, s5));
            stringbuffer.append("&label=");
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s5) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s4))
                stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString(s4, s5));
            stringbuffer.append("&pAdmin=N");
            if("Y".equals(oracle.apps.bis.common.ServletWrapper.getSessionValue(m_PageContext, "EMAIL" + m_UserSession.getFunctionName())))
            {
                stringbuffer.append(getBackUrl());
            } else
            {
                oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(m_WebAppsContext);
                oracle.apps.fnd.functionSecurity.SecurityGroup securitygroup = functionsecurity.getSecurityGroup();
                oracle.apps.fnd.functionSecurity.Resp resp = functionsecurity.getResp();
                oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(m_UserSession.getFunctionName());
                java.lang.String s6 = functionsecurity.getRunFunctionURL(function, resp, securitygroup, "");
                stringbuffer.append("&backUrl=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s6, s5));
            }
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        oracle.apps.fnd.security.HMAC hmac1 = getMACKey();
        oracle.apps.bis.common.ServletWrapper.sendRedirect(m_Response, oracle.cabo.share.url.EncoderUtils.encodeURL(oracle.apps.fnd.framework.webui.URLMgr.processOutgoingURL(stringbuffer.toString(), hmac1), oracle.apps.bis.common.ServletWrapper.getCharacterEncoding(m_Response), true));
    }

    public void invokeUserPersonalizePage()
        throws java.io.IOException
    {
        java.lang.String s = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "dbc");
        java.lang.String s1 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "viewAction");
        if(!"Y".equals(oracle.apps.bis.common.ServletWrapper.getSessionValue(m_PageContext, "EMAIL" + m_UserSession.getFunctionName())))
        {
            java.lang.String s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_NEED_TO_RUN_COMMON", m_WebAppsContext);
            oracle.apps.bis.common.ServletWrapper.sendRedirect(m_Response, oracle.cabo.share.url.EncoderUtils.encodeURL(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getErrorUrl(m_UserSession, s2, m_Request, m_PageContext), oracle.apps.bis.common.ServletWrapper.getCharacterEncoding(m_Response), true));
            return;
        }
        java.lang.String s3 = "";
        s3 = getParamBookMarkUrl();
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        try
        {
            java.lang.String s4 = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
            stringbuffer.append("/OA_HTML/OA.jsp?page=/od/oracle/apps/xxcrm/bis/pmv/customize/webui/ODBISPMVUSERVIEWPAGE&dbc=");
            stringbuffer.append(s);
            stringbuffer.append("&custRegionCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getRegionCode(), s4));
            stringbuffer.append("&custRegionApplId=").append(m_UserSession.getAKRegion().getRegionApplicationId());
            stringbuffer.append("&custFunctionName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getFunctionName(), s4));
            stringbuffer.append("&transactionid=").append(m_UserSession.getTransactionId());
            stringbuffer.append("&sessionid=").append(m_UserSession.getSessionId());
            stringbuffer.append("&viewMode=");
            stringbuffer.append(s1);
            if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pReportTitle") != null)
                stringbuffer.append("&pReportTitle=").append(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pReportTitle"));
            if(m_UserSession.getCustomCode() != null)
                stringbuffer.append("&pCustomCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getCustomCode(), s4));
            oracle.apps.bis.common.ServletWrapper.putSessionValue(m_UserSession.getPageContext(), "pBookMarkUrl", s3);
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_ParamHelper.getViewbyValue()))
                stringbuffer.append("&pViewBy=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_ParamHelper.getViewbyValue(), s4));
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        oracle.apps.fnd.security.HMAC hmac1 = getMACKey();
        oracle.apps.bis.common.ServletWrapper.sendRedirect(m_Response, oracle.cabo.share.url.EncoderUtils.encodeURL(oracle.apps.fnd.framework.webui.URLMgr.processOutgoingURL(stringbuffer.toString(), hmac1), oracle.apps.bis.common.ServletWrapper.getCharacterEncoding(m_Response), true));
    }

    private void initPreview(java.lang.String s, java.lang.String s1, java.lang.String s2, java.sql.Connection connection, oracle.apps.fnd.common.WebAppsContext webappscontext, oracle.apps.bis.pmv.session.UserSession usersession, javax.servlet.jsp.PageContext pagecontext)
    {
        oracle.apps.bis.pmv.session.RequestInfo requestinfo = usersession.getRequestInfo();
        m_WebAppsContext = webappscontext;
        requestinfo.setMode("SESSION");
        requestinfo.setParamType("SESSION");
        requestinfo.setIsPrintable(true);
        requestinfo.setParameterDisplayOnly("Y");
        requestinfo.setIsReportDefiner(true);
        if("P".equals(s))
        {
            requestinfo.setRequestType("R");
            requestinfo.setParameterDisplayOnly("N");
            requestinfo.setIsPrintable(false);
        } else
        {
            requestinfo.setRequestType(s);
        }
        m_Env = webappscontext.getProfileStore().getProfile("BIS_ENVIRONMENT");
        if(m_Env == null)
            m_Env = "";
        usersession.setRequestInfo(requestinfo);
        m_PageContext = pagecontext;
        m_UserSession = usersession;
    }

    public java.lang.String getPreviewHTML(java.lang.String s, int i, java.lang.String s1, java.lang.String s2, java.util.Vector vector, java.sql.Connection connection, oracle.apps.fnd.common.WebAppsContext webappscontext,
            oracle.apps.bis.pmv.session.UserSession usersession, javax.servlet.jsp.PageContext pagecontext)
        throws oracle.apps.bis.pmv.PMVException
    {
        initSession(pagecontext);
        initPreview(s, s1, s2, connection, webappscontext, usersession, pagecontext);
        if(m_ParamHelper == null)
            m_ParamHelper = new ParameterHelper(usersession, usersession.getConnection());
        initFormFunctionParameters(usersession);
        if(m_ParamHelper.getParameterValues() == null || m_ParamHelper.getParameterValues().isEmpty())
            initDesigner(usersession);
        if(usersession.getPageContext() == null)
            usersession.setPageContext(pagecontext);
        java.lang.StringBuffer stringbuffer = new StringBuffer(32000);
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getCustomStyles());
        if("P".equals(s))
        {
            if(m_ParamHelper.getParameterValues().isEmpty())
                m_ParamHelper = new ParameterHelper(usersession, usersession.getConnection());
            stringbuffer.append(getParameterBeanString());
        } else
        if(s.equals("L"))
        {
            stringbuffer.append(getRelatedLinks());
        } else
        {
            usersession.getRequestInfo().setCustomViewName(usersession.getAKRegion().getCustomViewName());
            od.oracle.apps.xxcrm.bis.pmv.data.ODPMVProvider pmvprovider = null;
            m_UserSession.setPortletMode(false);
            if(!od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.isAutoGenFromDesigner(usersession.getAKRegion()))
            {
                pmvprovider = new ODPMVProvider(usersession, usersession.getParameterHelper(), vector, true);
            } else
            {
                oracle.apps.bis.pmv.report.ReportDataSource reportdatasource = new ReportDataSource(usersession);
                java.util.Vector vector1 = reportdatasource.getDataRows();
                pmvprovider = new ODPMVProvider(usersession, usersession.getParameterHelper(), vector1);
            }
            m_rootNode = pmvprovider.getPMVMetadata();
            oracle.apps.bis.renderer.Renderer renderer = new Renderer(pmvprovider, m_rootNode, m_PageContext, m_WebAppsContext, connection);
            if("G".equals(s))
            {
                stringbuffer.append(renderer.getGraphHTML(i));
            } else
            {
                stringbuffer.append(renderer.getTableHTML());
                renderAutoScaleFooter(stringbuffer);
            }
        }
        return stringbuffer.toString();
    }

    private boolean doesReportHaveParams(java.lang.String s)
    {
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
            return false;
        oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(m_WebAppsContext);
        oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(s);
        if(function == null)
            return false;
        return function.getParameters() != null;
    }

    private java.lang.String renderBreadCrumbs()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(1000);
        oracle.apps.bis.pmv.breadcrumb.BreadCrumbRenderer breadcrumbrenderer = new BreadCrumbRenderer(m_PageContext, m_WebAppsContext);
        java.lang.String s = "";
        if(m_UserSession.getRequestInfo() != null && m_UserSession.getRequestInfo().isDesignerPreview())
            s = "";
        else
            s = breadcrumbrenderer.renderBreadCrumbs(m_UserSession.getFunctionName());
        java.lang.String s1 = "";
        if(od.oracle.apps.xxcrm.bis.pmv.report.ODReportPageBean.isSWAN())
            s1 = "bgcolor=\"#eaeff5\"";

	  stringbuffer.append("<link rel=\"stylesheet\" charset=\"UTF-8\" type=\"text/css\" href=\"OracleEBS.css\">");
      stringbuffer.append("<SCRIPT LANGUAGE=\"Javascript\">");
      stringbuffer.append("function setSubTabBold(id) { document.smjForm.smjSelectedTab.value = id;/*var m= 0; var n;while(m < 7) {n = 'subTabId'+m;document.getElementById(n).style.fontWeight='normal';m++;} document.getElementById(id).style.fontWeight='bold';*/};");
      stringbuffer.append("function makeSubTabBold(id,prompt) { if(String(id)==String(document.smjForm.smjSelectedTab.value)) return prompt.bold(); else return prompt;} ");
    stringbuffer.append("function dtl_window(myURL)  {   w = window.open(myURL,\"crm_detail_wnd\",\"scrollbars,resizable,toolbar,status\");   w.focus(); } ");
 stringbuffer.append("function GoToLink() {");
stringbuffer.append("var RecNovar = document.getElementById('txtName').value; ");
 // stringbuffer.append("var StartDateVar = document.getElementById('txtName').value ");
stringbuffer.append("window.location('http://gsidev02.na.odcorp.net/XXCRM_HTML/bisviewm.jsp?dbc=gsidev02&transactionid=&regionCode=XXBI_REP_POTENTIAL_DTL_RPT&functionName=XXBI_REP_POTENTIAL_DTL_RPT&pFirstTime=0&pParamSelected=XXBI_CS_POT_CUST_SITE_DIM%2BXXBI_CS_POT_CUST_SITE_DO&pmvN=XXBI_CUST_REVENUE_BAND_DIM%2BXXBI_CUST_REVENUE_BAND_DO&pmvI=All&pmvV=All&pmvN=XXBI_CS_POT_CITY_DIM%2BXXBI_CS_POT_CITY_DO&pmvI=All&pmvV=All&pmvN=XXBI_CS_POT_STATE_PROV_DIM%2BXXBI_CS_POT_STATE_PROV_DO&pmvI=All&pmvV=All&pmvN=XXBI_CS_POT_PCODE_DIM%2BXXBI_CS_POT_PCODE_DO&pmvI=All&pmvV=All&pmvN=XXBI_CS_POT_MODEL_DIM%2BXXBI_CS_POT_MODEL_DO&pmvI=All&pmvV=All&pmvN=XXBI_CS_POT_CUST_DIM%2BXXBI_CS_POT_CUST_DO&pmvI=All&pmvV=All&pmvN=XXBI_CS_POT_CUST_SITE_DIM%2BXXBI_CS_POT_CUST_SITE_DO&pmvI='+RecNovar+'&pmvV=ss&pMode=BKMARK&respId=52483&respApplId=20044&pDispRun=N'); "); 
stringbuffer.append("}");  
stringbuffer.append("</SCRIPT>");
  stringbuffer.append("<table cellpadding=\"0\" cellspacing=\"0\" border=\"0\" width=\"100%\">");
        stringbuffer.append("<tr>");
        stringbuffer.append("<td colspan=\"4\" width=\"14\" height=\"4\"><img src=\"cghts.gif\" alt=\"\" width=\"14\" height=\"4\"></td>");
        stringbuffer.append("<td style=\"background-image:url(cghtt.gif);\"></td>");
        stringbuffer.append("<td colspan=\"4\" width=\"14\" height=\"4\"><img src=\"cghte.gif\" alt=\"\" width=\"14\" height=\"4\"></td>");

        stringbuffer.append("</tr>");
        stringbuffer.append("<tr>");
       stringbuffer.append("<td width=\"1\" class=\'x2g\'></td>");
        stringbuffer.append("<td width=\"1\" class=\'x2f\'></td>");
        stringbuffer.append("<td width=\"1\" class=\'x2e\'></td>");
        stringbuffer.append("<td width=\"11\" class=\'x2a\'></td>");
        stringbuffer.append("<td width=\'100%\' nowrap class=\'x2a\'>");
        /*
        stringbuffer.append("<span class=\'x5l\'><a href=\"bisviewm.jsp?dbc=gsidev02&regionCode=XXBI_REP_POTENTIAL_DTL_RPT&functionName=XXBI_REP_POTENTIAL_DTL_RPT&pFirstTime=0&pParamSelected=XXBI_CUST_REVENUE_BAND_DIM%2BXXBI_CUST_REVENUE_BAND_DO&pmvN=XXBI_CUST_REVENUE_BAND_DIM%2BXXBI_CUST_REVENUE_BAND_DO&pmvI=All&pmvV=All&pmvN=XXBI_CS_POT_CITY_DIM%2BXXBI_CS_POT_CITY_DO&pmvI=All&pmvV=All&pmvN=XXBI_CS_POT_STATE_PROV_DIM%2BXXBI_CS_POT_STATE_PROV_DO&pmvI=All&pmvV=All&pmvN=XXBI_CS_POT_PCODE_DIM%2BXXBI_CS_POT_PCODE_DO&pmvI=All&pmvV=All&pmvN=XXBI_CS_POT_MODEL_DIM%2BXXBI_CS_POT_MODEL_DO&pmvI=All&pmvV=All&pmvN=XXBI_CS_POT_CUST_DIM%2BXXBI_CS_POT_CUST_DO&pmvI=All&pmvV=All&pmvN=XXBI_CS_POT_CUST_SITE_DIM%2BXXBI_CS_POT_CUST_SITE_DO&pmvI=All&pmvV=All&pMode=BKMARK&pDispRun=N\">Customers</a></span>");
        stringbuffer.append("<span class=\"x14\">|</span>");
        stringbuffer.append("<span class=\"x5l\"><a href=\"bisviewm.jsp?dbc=gsidev02&regionCode=XXBI_REP_ICUST_PROSP_DTL_RPT&functionName=XXBI_REP_ICUST_PROSP_DTL_RPT&pFirstTime=0&pParamSelected=VIEW_BY&pmvN=XXBI_CUST_AGE_BUCKET_DIM%2BXXBI_CUST_AGE_BUCKET_DO&pmvI=All&pmvV=All&pmvN=XXBI_CUST_CITY_DIM%2BXXBI_CUST_CITY_DO&pmvI=All&pmvV=All&pmvN=XXBI_CUST_ST_PROV_DIM%2BXXBI_CUST_ST_PROV_DO&pmvI=All&pmvV=All&pmvN=XXBI_CUST_ZIP_DIM%2BXXBI_CUST_ZIP_DO&pmvI=All&pmvV=All&pmvN=XXBI_CUST_ID_DIM%2BXXBI_CUST_ID_DO&pmvI=All&pmvV=All&pmvN=XXBI_CUST_SIC_CODE_DO%2BXXBI_CUST_SIC_CODE_DO&pmvI=All&pmvV=All&pmvN=XXBI_CUST_REVENUE_BAND_DIM%2BXXBI_CUST_REVENUE_BAND_DO&pmvI=All&pmvV=All&pmvN=VIEW_BY&pmvI=XXBI_CUST_AGE_BUCKET_DIM%2BXXBI_CUST_AGE_BUCKET_DO&pmvV=Age&pMode=BKMARK&pDispRun=N\">Prospects</a></span>");
        stringbuffer.append("<span class=\"x14\">|</span>");
        stringbuffer.append("<span class=\"x5l\"><a href=\"bisviewm.jsp?dbc=gsidev02&regionCode=XXBI_REP_LEAD_DTL_RPT&functionName=XXBI_REP_LEAD_DTL_RPT&pFirstTime=0&pParamSelected=XXBI_LEAD_STATUS_DIM%2BXXBI_LEAD_STATUS_DO&pmvN=XXBI_LEAD_STATUS_DIM%2BXXBI_LEAD_STATUS_DO&pmvI=All&pmvV=All&pmvN=XXBI_LEAD_RANK_DIM%2BXXBI_LEAD_RANK_DO&pmvI=All&pmvV=All&pmvN=XXBI_LEAD_CLOSE_REASON_DIM%2BXXBI_LEAD_CLOSE_REASON_DO&pmvI=All&pmvV=All&pmvN=XXBI_LEAD_AGE_BUCKET_DIM%2BXXBI_LEAD_AGE_BUCKET_DO&pmvI=All&pmvV=All&pmvN=XXBI_SOURCE_PROMOTIONS_DIM%2BXXBI_SOURCE_PROMOTIONS_DO&pmvI=All&pmvV=All&pmvN=VIEW_BY&pmvI=XXBI_LEAD_STATUS_DIM%2BXXBI_LEAD_STATUS_DO&pmvV=Status&pMode=BKMARK&pDispRun=N\">Leads</a></span>");
        stringbuffer.append("<span class=\"x14\">|</span>");
        stringbuffer.append("<span class=\"x5k\"><a href=\"bisviewm.jsp?dbc=gsidev02&transactionid=&regionCode=XXBI_REP_OPPTY_DTL_RPT&functionName=XXBI_REP_OPPTY_DTL_RPT&pFirstTime=0&pParamSelected=XXBI_SOURCE_PROMOTIONS_DIM%2BXXBI_SOURCE_PROMOTIONS_DO&pmvN=XXBI_SOURCE_PROMOTIONS_DIM%2BXXBI_SOURCE_PROMOTIONS_DO&pmvI=All&pmvV=All&pmvN=XXBI_OPPTY_CLOSE_REASON_DIM%2BXXBI_OPPTY_CLOSE_REASON_DO&pmvI=All&pmvV=All&pmvN=XXBI_OPPTY_STATUS_DIM%2BXXBI_OPPTY_STATUS_DO&pmvI=All&pmvV=All&pmvN=XXBI_OPPTY_AGE_BUCKETS_DIM%2BXXBI_OPPTY_AGE_BUCKETS_DO&pmvI=All&pmvV=All&pMode=BKMARK&pDispRun=N\">Opportunities</a></span>");
        stringbuffer.append("<span class=\"x14\">|</span>");
        stringbuffer.append("<span  class=\"x5l\"><a href=\"../OA_HTML/OA.jsp?page=/oracle/apps/jtf/cac/task/webui/CacTaskPerzSumPG&cacTaskPerzSource=%27TASK%27%2C%27PARTY%27%2C%27OPPORTUNITY%27%2C%27LEAD%27&cacTaskAutoSave=Y&cacTaskNoDelDlg=Y&retainAM=N&addBreadCrumb=Y\" target=\"_blank\">Tasks</a></span>");
        */
                 Vector objVect = getFunctionList(m_UserSession.getConnection());
		         for(int i=0;i<objVect.size();i++){
					 HashMap objHash = (HashMap)objVect.get(i);
					 String funcName = objHash.get("functionName").toString();
					 String parameters = null;
					 if(objHash.get("parameters")!=null)
					    parameters = objHash.get("parameters").toString();
					 String prompt = objHash.get("prompt").toString();
					 String url = null;
					 String objType1 = "";
					 if(objHash.get("objType")!=null)
					    objType1 = objHash.get("objType").toString();
					 String webUrl1 = objHash.get("webUrl").toString();

					 if("BIS_RPT".equals(objType1)){
					   url = getSubtabUrl(funcName,parameters,m_UserSession.getConnection(),"subTabId"+i);
					   /**   **/
					   stringbuffer.append("<span class=\"x5l\" id=\"subTabId"+i+"\" onClick=\"setSubTabBold('subTabId"+i+"')\"><a href="+url+"><font color=\"#FFFFFF\"><script type=\"text/javascript\">document.write(makeSubTabBold('subTabId"+i+"','"+prompt+"'));</script></font></a></span>");
				     }
					 if("OA_PAGE".equals(objType1)){
					   url = "../OA_HTML/"+webUrl1;
					   stringbuffer.append("<span class=\"x5l\" id=\"subTabId"+i+"\" onClick=\"setSubTabBold('subTabId"+i+"')\"><a href="+url+" target=\"crm_detail_wnd\" onClick=dtl_window(\"\")><font color=\"#FFFFFF\"><script type=\"text/javascript\">document.write(makeSubTabBold('subTabId"+i+"','"+prompt+"'));</script></font></a></span>");
				     }
					 if("JSP_PAGE".equals(objType1)){
					   url =webUrl1+"&smjSelectedTab=subTabId"+i;
					   stringbuffer.append("<span class=\"x5l\" id=\"subTabId"+i+"\" onClick=\"setSubTabBold('subTabId"+i+"')\"><a href="+url+"><font color=\"#FFFFFF\"><script type=\"text/javascript\">document.write(makeSubTabBold('subTabId"+i+"','"+prompt+"'));</script></font></a></span>");
				     }
				     if("".equals(objType1)){
					   stringbuffer.append("<span class=\"x5l\" id=\"subTabId"+i+"\" onClick=\"setSubTabBold('subTabId"+i+"')\"><font color=\"#FFFFFF\"><script type=\"text/javascript\">document.write(makeSubTabBold('subTabId"+i+"','"+prompt+"'));</script></font></span>");
					 }
					 stringbuffer.append("<span class=\"x14\"><font color=\"#FFFFFF\">&nbsp;|&nbsp;</font></span>");
	 	}
        stringbuffer.append("</td>");


//alert(document.getElementById('txtName').value)




        stringbuffer.append("<td width=\"11\" class=\'x2a\'></td>");
       stringbuffer.append("<td width=\"1\" class=\'x2e\'></td>");
        stringbuffer.append("<td width=\"1\" class=\'x2f\'></td>");
        stringbuffer.append("<td width=\"1\" class=\'x2g\'></td>");
        stringbuffer.append("</tr>");
        stringbuffer.append("<tr>");
        stringbuffer.append("<td colspan=\"4\" width=\"14\" height=\"4\"><img src=\"cghbs.gif\" alt=\"\" width=\"14\" height=\"4\"></td>");
        stringbuffer.append("<td style=\"background-image:url(cghb.gif);\"></td>");
        stringbuffer.append("<td colspan=\"4\" width=\"14\" height=\"4\"><img src=\"cghbe.gif\" alt=\"\" width=\"14\" height=\"4\"></td>");
        stringbuffer.append("</tr>");
        stringbuffer.append("</table>");
        stringbuffer.append("<TABLE width=100% cellpadding=0 cellspacing=0 border=0 summary=\"\" ").append(s1).append(" ><TR>");


        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s) || m_UserSession.getAKRegion().hasRequiredItem())
        {
            stringbuffer.append("<TD width=85%>");
            if(s == null)
                s = "";

            stringbuffer.append("<TABLE summary=\"\" width=100%><TR><TD>").append(s).append("</TD></TR>");

            if(m_UserSession.getAKRegion().hasRequiredItem())
            {
                stringbuffer.append("<TR>");
                if("AR".equals(m_WebAppsContext.getCurrLangCode()) || "IW".equals(m_WebAppsContext.getCurrLangCode()))
                    stringbuffer.append("<td align=\"right\" valign=\"middle\">");
                else
                    stringbuffer.append("<td align=\"left\" valign=\"middle\">");
                stringbuffer.append("<SPAN class=\"OraTipText\">");
                stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_REQUIRED_FIELD", m_WebAppsContext));
                stringbuffer.append("</SPAN>");
                stringbuffer.append("</td>");
                stringbuffer.append("</TR>");
            }
            stringbuffer.append("</TABLE>");
            stringbuffer.append("</TD>");
        } else
        {
            stringbuffer.append("<TD width=85%>");
            stringbuffer.append("<TABLE width=100% cellpadding=0 cellspacing=0 border=0 summary=\"\">");
            stringbuffer.append("<TR>");
            stringbuffer.append("<TD>");
            if(m_UserSession.getAKRegion().isBscPrototypeMode())
                stringbuffer.append(getPrototypeIconAndMessage());
            stringbuffer.append("</TR>");
            stringbuffer.append("</TD>");
            stringbuffer.append("</TABLE>");
            stringbuffer.append("</TD>");
        }
        /*if(m_UserSession.isUserCustomization() || m_UserSession.isOriginalView())
        {
		*/

/*     Go Button 
         stringbuffer.append("<TD>");
        stringbuffer.append("<span><select id=\"cboType\">");
        stringbuffer.append("<option></option><option>Customers-ID</option><option>Customers-Name</option>");
        stringbuffer.append("<option>Leads-Cust Id</option><option>Leads-Cust Name</option><option>Opportunities- Cust ID</option></select></span>");
        stringbuffer.append("<span><input id=\"txtName\" class=\"x14\" size=\"10\" type=\"text\"></span>");
        stringbuffer.append("&nbsp;&nbsp; <a href=\"javascript:onclick=GoToLink()\"><img SRC=\"en/bGoM-cX.gif\" border=0></a>");
         stringbuffer.append("</td>");
  
*/
          stringbuffer.append("<TD width=5%>&nbsp;</TD>");
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getActionButtonHtml(m_WebAppsContext, m_UserSession));
        /*
        }
        */
        stringbuffer.append("</TR></TABLE>");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && m_UserSession.getAKRegion().isBscPrototypeMode())
            stringbuffer.append(getPrototypeIconAndMessage());
        return stringbuffer.toString();
    }

    private void processForBreadCrumb()
    {
        java.lang.String s = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pMode");
        java.lang.String s1 = null;
        if(m_UserSession != null)
            s1 = m_UserSession.getFunctionName();
        boolean flag = "DRILL".equalsIgnoreCase(s) || "RELATED".equalsIgnoreCase(s) || "BCRUMB".equalsIgnoreCase(s) || "DRILLDOWN".equalsIgnoreCase(s) || "BKMARK".equals(s) || "BIS_BIA_RSG_PSTATE_REPORT".equals(s1);
        java.lang.String s2 = (java.lang.String)oracle.apps.bis.common.ServletWrapper.getSessionValue(m_PageContext, "fromPage");
        boolean flag1 = "REPORTLISTINGPAGE".equals(s2);
        if(flag && doesReportHaveParams(s1) || flag1)
        {
            java.lang.String s3 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pBCFromFunctionName");
            java.lang.String s5 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pPrevBCInfo");
            if(doesReportHaveParams(s3))
                oracle.apps.bis.pmv.breadcrumb.BreadCrumbHelper.addPrevPageBC(m_PageContext, m_WebAppsContext, s3, s5);
            oracle.apps.bis.pmv.breadcrumb.BreadCrumbHelper.addBreadCrumb(m_PageContext, m_WebAppsContext, m_UserSession.getFunctionName());
            if(flag1)
            {
                oracle.apps.bis.common.ServletWrapper.removeSessionAttribute(m_PageContext, "fromPage");
                return;
            }
        } else
        {
            java.lang.String s4 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pFirstTime");
            if(s4 == null)
                s4 = "1";
            boolean flag2 = "Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "fromPersonalize"));
            if("1".equals(s4) && !flag2)
            {
                if(doesReportHaveParams(s1))
                {
                    oracle.apps.bis.pmv.breadcrumb.BreadCrumbHelper.resetWithBreadCrumb(m_PageContext, m_WebAppsContext, m_UserSession.getFunctionName());
                    return;
                }
                oracle.apps.bis.pmv.breadcrumb.BreadCrumbHelper.clearBreadCrumbs(m_PageContext, m_WebAppsContext);
            }
        }
    }

    private void setLowerUpperPrevNextProperties(oracle.apps.bis.pmv.session.RequestInfo requestinfo)
    {
        java.lang.String s = "N";
        if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pResetDefault") != null)
            s = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pResetDefault");
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(requestinfo.getPersNoOfRows()) && !"Y".equals(s))
        {
            if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "upperBound") != null && !oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "upperBound").equals(""))
                requestinfo.setUpperBound(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "upperBound"));
            else
                requestinfo.setUpperBound(java.lang.String.valueOf(m_UserSession.getAKRegion().getNumberOfRows()));
            if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "lowerBound") != null && !oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "lowerBound").equals(""))
                requestinfo.setLowerBound(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "lowerBound"));
            else
                requestinfo.setLowerBound("0");
            java.lang.String s1 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "setstart");
            java.lang.String s2 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "prevset");
            java.lang.String s3 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "nextset");
            if(s1 != null && !s1.equals(""))
            {
                int i;
                int j;
                if(s2 != null && s2.equals("true"))
                {
                    i = java.lang.Integer.parseInt(s1) + m_UserSession.getAKRegion().getNumberOfRows();
                    j = i + m_UserSession.getAKRegion().getNumberOfRows();
                } else
                {
                    i = java.lang.Integer.parseInt(s1) - m_UserSession.getAKRegion().getNumberOfRows();
                    j = i + m_UserSession.getAKRegion().getNumberOfRows();
                }
                requestinfo.setLowerBound(java.lang.String.valueOf(i));
                requestinfo.setUpperBound(java.lang.String.valueOf(j));
            }
            if(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "navMode") != null)
                requestinfo.setNavMode(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "navMode"));
            if(s2 != null && s2.equals("true"))
                requestinfo.setNavMode("PREVIOUS");
            if(s3 != null && s3.equals("true"))
            {
                requestinfo.setNavMode("NEXT");
                return;
            }
        } else
        {
            requestinfo.setLowerBound("0");
            requestinfo.setUpperBound(java.lang.String.valueOf(m_UserSession.getAKRegion().getNumberOfRows()));
            requestinfo.setNavMode("SET");
        }
    }

    private boolean isReportRunningFromBkMark()
    {
        boolean flag = "1".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "bk"));
        boolean flag1 = "0".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pFirstTime"));
        boolean flag2 = flag && !flag1;
        return flag2;
    }

    private void processBookMark()
    {
        try
        {
            oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(m_WebAppsContext);
            java.lang.String s = functionsecurity.getFunction(m_UserSession.getFunctionName()).getParameters();
            if(s != null)
            {
                java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getUrlParamValue(s, "pParameters");
                if(s1 != null)
                {
                    m_UserSession.setParameters(s1);
                    java.lang.String s2 = m_UserSession.getParameters();
                    java.util.Hashtable hashtable = m_UserSession.getParameterHashTable(s2, m_UserSession.getRegionCode());
                    oracle.apps.bis.pmv.parameters.ParameterSaveBean parametersavebean = new ParameterSaveBean();
                    parametersavebean.init(m_UserSession);
                    java.lang.String s3 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getUrlParamValue(s2, "pParamIds");
                    parametersavebean.setpSaveByIds(s3);
                    parametersavebean.saveParameters(hashtable, m_UserSession, 0);
                }
            }
            oracle.apps.bis.pmv.parameters.ParameterSaveBean.copyDefParameters(m_UserSession);
            return;
        }
        catch(oracle.apps.bis.pmv.PMVException _ex)
        {
            return;
        }
    }

    private oracle.apps.fnd.security.HMAC getMACKey()
    {
        if(m_WebAppsContext != null)
            hmac = oracle.apps.fnd.common.URLTools.getHMAC(m_WebAppsContext);
        if(hmac != null)
            return hmac;
        else
            return null;
    }

    protected void initDesigner(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        try
        {
            oracle.apps.bis.pmv.parameters.ParameterSaveBean parametersavebean = new ParameterSaveBean();
            java.util.Hashtable hashtable = new Hashtable(10);
            oracle.apps.bis.pmv.metadata.AKRegion akregion = (oracle.apps.bis.pmv.metadata.AKRegion)m_PageContext.getSession().getValue("BIS_PMV_DSGN_AK_REGION");
            oracle.apps.bis.parameters.DefaultParameters defaultparameters = new DefaultParameters("", usersession.getConnection(), akregion, usersession.getWebAppsContext());
            hashtable = defaultparameters.getDefaultValuesFromPMF();
            if(hashtable == null && hashtable.isEmpty() && usersession.getParameterHelper().getParameterValues().isEmpty())
            {
                com.sun.java.util.collections.HashMap hashmap = oracle.apps.bis.parameters.ParametersUtil.getParameterValues(usersession.getWebAppsContext(), usersession);
                Object obj = null;
                Object obj1 = null;
                if(hashmap != null)
                {
                    java.lang.String s1;
                    oracle.apps.bis.parameters.Parameter parameter;
                    for(com.sun.java.util.collections.Iterator iterator = hashmap.keySet().iterator(); iterator.hasNext(); hashtable.put(s1, parameter.getValueId()))
                    {
                        s1 = (java.lang.String)iterator.next();
                        parameter = (oracle.apps.bis.parameters.Parameter)hashmap.get(s1);
                    }

                }
            }
            java.lang.String s = oracle.apps.bis.pmv.common.StringUtil.nonNull(akregion.getDefaultValue());
            java.lang.String s2 = "";
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
            {
                com.sun.java.util.collections.HashMap hashmap1 = (com.sun.java.util.collections.HashMap)od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameters(s);
                s2 = (java.lang.String)hashmap1.get("pParameters");
            }
            s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.processpParameters(s2);
            com.sun.java.util.collections.HashMap hashmap2 = new HashMap(5);
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
                hashmap2 = (com.sun.java.util.collections.HashMap)od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameters(s2);
            if(!hashmap2.isEmpty() && hashmap2.get("pParamIds") != null)
            {
                if("Y".equals(hashmap2.get("pParamIds")))
                    usersession.setParamIds(true);
                else
                    usersession.setParamIds(false);
                parametersavebean.setpSaveByIds((java.lang.String)hashmap2.get("pParamIds"));
            } else
            {
                usersession.setParamIds(true);
                parametersavebean.setpSaveByIds("Y");
            }
            usersession.setParameters("");
            parametersavebean.init(m_UserSession);
            parametersavebean.saveParameters(hashtable, usersession, 0);
            return;
        }
        catch(oracle.apps.bis.pmv.PMVException _ex)
        {
            return;
        }
        catch(java.lang.Exception _ex)
        {
            return;
        }
    }

    private void initFormFunctionParameters(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        oracle.apps.bis.pmv.session.RequestInfo requestinfo = usersession.getRequestInfo();
        oracle.apps.bis.pmv.metadata.AKRegion akregion = (oracle.apps.bis.pmv.metadata.AKRegion)m_PageContext.getSession().getValue("BIS_PMV_DSGN_AK_REGION");
        java.lang.String s = oracle.apps.bis.pmv.common.StringUtil.nonNull(akregion.getDefaultValue());
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            com.sun.java.util.collections.HashMap hashmap = (com.sun.java.util.collections.HashMap)od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameters(s);
            java.lang.String s1 = (java.lang.String)hashmap.get("parameterDisplayOnly");
            if("Y".equalsIgnoreCase(oracle.apps.bis.pmv.common.StringUtil.nonNull(s1)))
                requestinfo.setParameterDisplayOnly("Y");
        }
    }

    private java.lang.String getParamBookMarkUrl()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(1000);
        stringbuffer.append("../XXCRM_HTML/bisviewm.jsp");
        java.lang.String s = "";
        java.lang.String s1 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "parameterDisplayOnly");
        if(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.isParamBookMarked())
            s = oracle.apps.bis.pmv.parameters.PMVParameterForm.getBookMarkParameters(m_UserSession, true);
        if("Y".equals(s1))
            s = oracle.apps.bis.pmv.parameters.PMVParameterForm.getDisplayOnlyBookMarkParameters(m_UserSession);
        stringbuffer.append("?dbc=").append(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "dbc"));
        stringbuffer.append("&transactionid=").append(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "transactionid"));
        stringbuffer.append("&regionCode=").append(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "regionCode"));
        stringbuffer.append("&functionName=").append(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "functionName"));
        if(m_UserSession.getXmlReport() != null)
            stringbuffer.append("&reportName=").append(m_UserSession.getXmlReport());
        stringbuffer.append("&pFirstTime=0");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
            stringbuffer.append(s);
        stringbuffer.append("&pMode=BKMARK");
        stringbuffer.append("&respId=").append(m_WebAppsContext.getRespId());
        stringbuffer.append("&respApplId=").append(m_WebAppsContext.getRespApplId());
        if(s1 != null && s1.length() > 0)
            stringbuffer.append("&parameterDisplayOnly=").append(s1);
        java.lang.String s2 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "displayParameters");
        if(s2 != null && s2.length() > 0)
            stringbuffer.append("&displayParameters=").append(s2);
        java.lang.String s3 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pEnableForecastGraph");
        if(s3 != null && s3.length() > 0)
            stringbuffer.append("&pEnableForecastGraph=").append(s3);
        java.lang.String s4 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pDispRun");
        if(s4 != null && s4.length() > 0)
            stringbuffer.append("&pDispRun=").append(s4);
        java.lang.String s5 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pCustomView");
        if(s5 != null && s5.length() > 0)
            stringbuffer.append("&pCustomView=").append(s5);
        java.lang.String s6 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pReportType");
        if(s6 != null && s6.length() > 0)
            stringbuffer.append("&pReportType=").append(s6);
        java.lang.String s7 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pCSVFileName");
        if(s7 != null && s7.length() > 0)
            stringbuffer.append("&pCSVFileName=").append(s7);
        int i = m_UserSession.getMaxResultSetSize();
        if(i > -1)
            stringbuffer.append("&pMaxResultSetSize=").append(i);
        if("Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "designer")))
            stringbuffer.append("&designer=Y");
        boolean flag = "Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "refreshParameters"));
        if(flag)
            stringbuffer.append("&refreshParameters=Y");
        if("Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "hideNav")))
            stringbuffer.append("&").append("hideNav").append("=Y");
        if("Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "tab")))
            stringbuffer.append("&").append("tab").append("=Y");
        java.lang.String s8 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "displayOnlyParameters");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s8))
            stringbuffer.append("&displayOnlyParameters=").append(s8);
        java.lang.String s9 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "displayOnlyNoViewByParams");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s9))
            stringbuffer.append("&displayOnlyNoViewByParams=").append(s9);
        java.lang.String s10 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "persNoOfRows");
        if(s10 != null && s10.length() > 0)
            stringbuffer.append("&").append("persNoOfRows").append("=").append(s10);
        return stringbuffer.toString();
    }

    public java.lang.String getContent()
    {
        return m_Content.toString();
    }

    protected java.lang.String getPrototypeIconAndMessage()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append("<TABLE width=100% cellpadding=0 cellspacing=0 border=0 summary=\"\"><TR>");
        stringbuffer.append("<TR>");
        if("AR".equals(m_WebAppsContext.getCurrLangCode()) || "IW".equals(m_WebAppsContext.getCurrLangCode()))
            stringbuffer.append("<td class=\"OraTipText\" align=\"right\" valign=\"middle\">");
        else
            stringbuffer.append("<td class=\"OraTipText\" align=\"left\" valign=\"middle\">");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getBscPrototypeIcon(m_WebAppsContext, null));
        stringbuffer.append("&nbsp;");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_BSC_PROTOTYPE_DATA", m_WebAppsContext));
        stringbuffer.append("</td>");
        stringbuffer.append("</TR>");
        stringbuffer.append("</TABLE>");
        return stringbuffer.toString();
    }

    private static boolean isSWAN()
    {
        return "SWAN".equals("409");
    }
 private java.lang.String getExpBackUrl()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        java.lang.String s = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        try
        {
            stringbuffer.append("&backUrl=bisviewm.jsp");
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("?dbc=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getRequestInfo().getDBC(), s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&transactionid=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getTransactionId(), s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&sessionid=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getSessionId(), s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&regionCode=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getRegionCode(), s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&functionName=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getFunctionName(), s));
            if(m_UserSession.getMaxResultSetSize() > -1)
                stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pMaxResultSetSize=", s)).append(m_UserSession.getMaxResultSetSize());
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pFirstTime=", s)).append("0");
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&language_code=", s)).append(m_WebAppsContext.getCurrLangCode());
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pMode=SHOW", s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pCustomView=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getAKRegion().getCustomViewName(), s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&parameterDisplayOnly=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getRequestInfo().getParameterDisplayOnly(), s));
            java.lang.String s1 = oracle.apps.bis.pmv.common.StringUtil.nonNull(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "autoRefresh"));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&autoRefresh=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(s1, s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pSessionId=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getSessionId(), s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pUserId=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getUserId(), s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pResponsibilityId=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getResponsibilityId(), s));
            boolean flag = m_UserSession.getRequestInfo().isForecastGraphEnabled();
            if(flag)
                stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pEnableForecastGraph=Y", s));
            java.lang.String s2 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pDispRun");
            if(s2 != null && s2.length() > 0)
                stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pDispRun=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(s2, s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&fromPersonalize=Y", s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&forceRun=Y", s));
            java.lang.String s3 = oracle.apps.bis.pmv.common.StringUtil.nonNull(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "displayParameters"));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&displayParameters=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(s3, s));
            java.lang.String s4 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "displayOnlyParameters");
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s4))
                stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&displayOnlyParameters=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(s4, s));
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        return stringbuffer.toString();
    }

    private java.lang.String getBackUrl()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        java.lang.String s = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        try
        {
            stringbuffer.append("&backUrl=../XXCRM_HTML/bisviewm.jsp");
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("?dbc=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getRequestInfo().getDBC(), s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&transactionid=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getTransactionId(), s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&sessionid=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getSessionId(), s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&regionCode=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getRegionCode(), s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&functionName=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getFunctionName(), s));
            if(m_UserSession.getMaxResultSetSize() > -1)
                stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pMaxResultSetSize=", s)).append(m_UserSession.getMaxResultSetSize());
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pFirstTime=", s)).append("0");
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&language_code=", s)).append(m_WebAppsContext.getCurrLangCode());
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pMode=SHOW", s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pCustomView=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getAKRegion().getCustomViewName(), s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&parameterDisplayOnly=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getRequestInfo().getParameterDisplayOnly(), s));
            java.lang.String s1 = oracle.apps.bis.pmv.common.StringUtil.nonNull(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "autoRefresh"));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&autoRefresh=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(s1, s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pSessionId=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getSessionId(), s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pUserId=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getUserId(), s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pResponsibilityId=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(m_UserSession.getResponsibilityId(), s));
            boolean flag = m_UserSession.getRequestInfo().isForecastGraphEnabled();
            if(flag)
                stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pEnableForecastGraph=Y", s));
            java.lang.String s2 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "pDispRun");
            if(s2 != null && s2.length() > 0)
                stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pDispRun=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(s2, s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&fromPersonalize=Y", s));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&forceRun=Y", s));
            java.lang.String s3 = oracle.apps.bis.pmv.common.StringUtil.nonNull(oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "displayParameters"));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&displayParameters=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(s3, s));
            java.lang.String s4 = oracle.apps.bis.common.ServletWrapper.getParameter(m_Request, "displayOnlyParameters");
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s4))
                stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&displayOnlyParameters=", s)).append(oracle.cabo.share.url.EncoderUtils.encodeString(s4, s));
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        return stringbuffer.toString();
    }

        private Vector getFunctionList(Connection conn)

	    {
		  StringBuffer sqlString = new StringBuffer();
		  sqlString.append(" SELECT f.function_name, f.parameters,  me.prompt, me.description, f.web_html_call ");
		  sqlString.append(" FROM fnd_compiled_menu_functions mf,fnd_form_functions_vl f ,fnd_menu_entries_vl me ");
		  sqlString.append(" WHERE me.menu_id = (SELECT menu_id FROM fnd_menus_vl WHERE menu_name=:1) ");
		  sqlString.append(" AND mf.function_id = f.function_id AND me.menu_id = mf.menu_id AND me.function_id = mf.function_id ");
		  sqlString.append(" AND me.function_id = f.function_id ORDER BY me.entry_sequence ");

		  String sql = sqlString.toString();

	      PreparedStatement pstmt = null;

	      ResultSet rs  = null;

	      Vector objVect = new Vector();

	      try

	      {

	        pstmt = conn.prepareStatement(sql);
	        oracle.jdbc.driver.OracleStatement ostmt = (oracle.jdbc.driver.OracleStatement) pstmt;
	        ostmt.defineColumnType(1,java.sql.Types.VARCHAR,480);
			ostmt.defineColumnType(2,java.sql.Types.VARCHAR,2000);
			ostmt.defineColumnType(3,java.sql.Types.VARCHAR,60);
			ostmt.defineColumnType(4,java.sql.Types.VARCHAR,240);
            ostmt.defineColumnType(5,java.sql.Types.VARCHAR,240);

            String repManager= repManagerMenu(conn);
           
      repManager= repManager.trim();
          
                  pstmt.setString(1,repManager);

 
	        rs = pstmt.executeQuery();

	        while (rs.next())      {
				HashMap objHash = new HashMap();
				objHash.put("functionName",rs.getString(1));
				objHash.put("parameters",rs.getString(2));
	            objHash.put("prompt",rs.getString(3));
                objHash.put("objType",rs.getString(4));
                objHash.put("webUrl",rs.getString(5));
	            objVect.add(objHash);

	        }

	      }

	      catch (SQLException e)   {

	        //e.printStackTrace();

	      }

	      finally    {

	        try      {

	          if (rs != null)

	             rs.close();

	          if (pstmt != null)

	             pstmt.close();

	        }

	        catch (Exception e)      {

	          //e.printStackTrace();

	        }

	      }
	      return objVect;
	  }

        private String repManager(Connection conn)

	    {
		  StringBuffer sqlString = new StringBuffer();
		  sqlString.append(" select rep_mgr from  XXBI_REP_MGR_RESP_MAPPINGS where resp_key in ( ");
		  sqlString.append(" select responsibility_key from fnd_responsibility_vl where responsibility_id=:1) ");
		  String sql = sqlString.toString();

	      PreparedStatement pstmt = null;

	      ResultSet rs  = null;

          String repMgr = "";
          String respId = m_UserSession.getResponsibilityId();
	      try
	      {
	        pstmt = conn.prepareStatement(sql);
	        oracle.jdbc.driver.OracleStatement ostmt = (oracle.jdbc.driver.OracleStatement) pstmt;
	        ostmt.defineColumnType(1,java.sql.Types.VARCHAR,1);

	        pstmt.setString(1, respId);
	        rs = pstmt.executeQuery();

	        while (rs.next())      {
				    repMgr = rs.getString(1);

	        }

	      }

	      catch (SQLException e)   {

	        //e.printStackTrace();

	      }

	      finally    {

	        try      {

	          if (rs != null)

	             rs.close();

	          if (pstmt != null)

	             pstmt.close();

	        }

	        catch (Exception e)      {

	          //e.printStackTrace();

	        }

	      }
	      return repMgr;
	  }
   private String repManagerMenu(Connection conn)

	    {
		  StringBuffer sqlString = new StringBuffer();
		  sqlString.append(" select dashboard_menu from  XXBI_REP_MGR_RESP_MAPPINGS where resp_key in ( ");
		  sqlString.append(" select responsibility_key from fnd_responsibility_vl where responsibility_id=:1) ");
		  String sql = sqlString.toString();

	      PreparedStatement pstmt = null;

	      ResultSet rs  = null;

          String repMgr = "";
          String respId = m_UserSession.getResponsibilityId();
	      try
	      {
	        pstmt = conn.prepareStatement(sql);
	        oracle.jdbc.driver.OracleStatement ostmt = (oracle.jdbc.driver.OracleStatement) pstmt;
	        ostmt.defineColumnType(1,java.sql.Types.VARCHAR,250);

	        pstmt.setString(1, respId);
	        rs = pstmt.executeQuery();

	        while (rs.next())      {
				    repMgr = rs.getString(1);

	        }

	      }

	      catch (SQLException e)   {

	        //e.printStackTrace();

	      }

	      finally    {

	        try      {

	          if (rs != null)

	             rs.close();

	          if (pstmt != null)

	             pstmt.close();

	        }

	        catch (Exception e)      {

	          //e.printStackTrace();

	        }

	      }
	      return repMgr;
	  }
	  private String getSubtabUrl(String functionName,String parameters,Connection conn,String selectedIndex)

	  {
	     StringBuffer Url = new StringBuffer();

	     String enc = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");

	     HttpSession  smjSession = (HttpSession)m_PageContext.getSession();

	     String dbcName = m_UserSession.getRequestInfo().getDBC();
	     if("".equals(dbcName))
	        dbcName = (String)smjSession.getValue("dbcName");


	     smjSession.putValue("dbcName",dbcName);

	     HashMap viewList = UserPersonalizationUtil.getUserLevelCustomizationData(String.valueOf(m_WebAppsContext.getUserId()),functionName,conn);
         if(viewList != null && viewList.size() > 0){
            String defViewName = isDefaultViewExists(viewList,conn);
            if(!"NO_DEFAULT".equals(defViewName)){
				try{
				Url.append(getDefViewURL(viewList,m_WebAppsContext,defViewName));
	            Url.append("&smjSelectedTab=").append(EncoderUtils.encodeString(selectedIndex,enc));
			    }catch(UnsupportedEncodingException uoe){}
                return Url.toString();
			}
         }

	     try

	     {

	        Url.append("bisviewm.jsp");

	        Url.append("?dbc=").append(EncoderUtils.encodeString(dbcName,enc));

	        Url.append("&smjSelectedTab=").append(EncoderUtils.encodeString(selectedIndex,enc));

	        Url.append("&regionCode=").append(functionName);

	        Url.append("&functionName=").append(functionName);

	        Url.append("&").append(parameters);

	    /*    Vector objVect = getReportParams(m_UserSession.getConnection(),functionName);

	        for(int i=0;i<objVect.size();i++){
				HashMap objHash = (HashMap)objVect.get(i);
				String searchName = objHash.get("searchName").toString();
				String idString = objHash.get("idString").toString();
				String valString = objHash.get("valString").toString();

				Url.append("&pmvN=").append(EncoderUtils.encodeString(searchName,enc));
				Url.append("&pmvI=").append(EncoderUtils.encodeString(idString,enc));
				Url.append("&pmvV=").append(EncoderUtils.encodeString(valString,enc));

			}
*/

	        Url.append("&forceRun=Y");

	        Url.append("&pFirstTime=0");

	        Url.append("&transactionid=").append(EncoderUtils.encodeString(m_UserSession.getTransactionId(),enc));

	        Url.append("&sessionid=").append(EncoderUtils.encodeString(m_UserSession.getSessionId(),enc));

	        Url.append("&language_code=").append(m_WebAppsContext.getCurrLangCode());

	        Url.append("&pMode=SHOW");

	        Url.append("&pCustomView=").append(EncoderUtils.encodeString(m_UserSession.getAKRegion().getCustomViewName(),enc));

	        Url.append("&parameterDisplayOnly=").append(EncoderUtils.encodeString(m_UserSession.getRequestInfo().getParameterDisplayOnly(),enc));

	        Url.append("&pSessionId=").append(EncoderUtils.encodeString(m_UserSession.getSessionId(),enc));

	        Url.append("&pUserId=").append(EncoderUtils.encodeString(m_UserSession.getUserId(),enc));

	        Url.append("&pResponsibilityId=").append(EncoderUtils.encodeString(m_UserSession.getResponsibilityId(),enc));

	      }catch(UnsupportedEncodingException uoe){}

	      return Url.toString();

  }


        private Vector getReportParams(Connection conn,String repShortName)

	    {
		  StringBuffer sqlString = new StringBuffer();
		  sqlString.append(" SELECT distinct d.do_short_name, d.dim_short_name||'+'||d.do_short_name as searchName,d.view_by, ");
		  sqlString.append(" 'select * from (select to_char(id) as id, value from '|| l.level_values_view_name || ') q where q.id in' as val_sql ");
		  sqlString.append(" FROM xxbi_dashboard_defaults d, bis_levels l WHERE d.report_short_name = :1 AND l.short_name = d.do_short_name ");
		  sqlString.append(" and d.role_value=:2 and d.rep_mgr = :3 ");

		  String sql = sqlString.toString();

	      PreparedStatement pstmt = null;

	      ResultSet rs  = null;

          Vector objVect = new Vector();
          HashMap objIDValHash = new HashMap();
	      try{

	        pstmt = conn.prepareStatement(sql);
	        oracle.jdbc.driver.OracleStatement ostmt = (oracle.jdbc.driver.OracleStatement) pstmt;
	        ostmt.defineColumnType(1,java.sql.Types.VARCHAR,30);
	        ostmt.defineColumnType(2,java.sql.Types.VARCHAR,70);
	        ostmt.defineColumnType(3,java.sql.Types.VARCHAR,1);
	        ostmt.defineColumnType(4,java.sql.Types.VARCHAR,100);


	        String repManager = repManager(conn);
	        String roleCode = getDefaultRole(conn,repManager);
			if("".equals(repManager)){
	        	 repManager = "DEFAULT";
	        	 roleCode = "DEFAULT";
			 }
			if("DEFAULT".equals(roleCode)){
	        	 repManager = "DEFAULT";
			 }

	        pstmt.setString(1, repShortName);
	        pstmt.setString(2, roleCode);
	        pstmt.setString(3, repManager);
	        rs = pstmt.executeQuery();

	        while (rs.next())      {
				String doShortName = rs.getString(1);
				String searchName = rs.getString(2);
				String viewBy = rs.getString(3);
				String sqlPart = rs.getString(4);
				objIDValHash = getDefaultValues(conn,sqlPart,repShortName,doShortName,repManager,roleCode);
				String idString = "";
				String valString = "";
				if(objIDValHash!=null){
					if(objIDValHash.get("idString")!=null)
				    	idString = objIDValHash.get("idString").toString();
				    if(objIDValHash.get("valString")!=null)
				    	valString = objIDValHash.get("valString").toString();
			    }
				HashMap objHash = new HashMap();
				objHash.put("searchName",searchName);
				objHash.put("idString",idString);
				objHash.put("valString",valString);
				objVect.add(objHash);
				if("Y".equals(viewBy)){
					String dispName = getDisplayName(conn,repShortName,searchName);
					HashMap objViewHash = new HashMap();
					objViewHash.put("searchName","VIEW_BY");
					objViewHash.put("idString",searchName);
				    objViewHash.put("valString",dispName);
				    objVect.add(objViewHash);
				}
	        }

	      }

	      catch (SQLException e)   {

	        //e.printStackTrace();

	      }

	      finally    {

	        try      {

	          if (rs != null)

	             rs.close();

	          if (pstmt != null)

	             pstmt.close();

	        }

	        catch (Exception e)      {

	          //e.printStackTrace();

	        }

	      }
	      return objVect;
	  }

        private Vector getDefaults(Connection conn,String repShortName, String doShortName, String repMgr, String roleValue)

	    {
		  StringBuffer sqlString = new StringBuffer();
		  sqlString.append(" select default_id_val as id_val from xxbi_dashboard_defaults d where ");
		  sqlString.append("  d.report_short_name = :1 and d.do_short_name = :2 and rep_mgr=:3 and ROLE_VALUE=:4");

		  String sql = sqlString.toString();

	      PreparedStatement pstmt = null;

	      ResultSet rs  = null;

          Vector objVect = new Vector();
	      try{

	        pstmt = conn.prepareStatement(sql);
	        oracle.jdbc.driver.OracleStatement ostmt = (oracle.jdbc.driver.OracleStatement) pstmt;
	        ostmt.defineColumnType(1,java.sql.Types.VARCHAR,4000);

	        pstmt.setString(1, repShortName);
	        pstmt.setString(2, doShortName);
	        pstmt.setString(3, repMgr);
	        pstmt.setString(4, roleValue);
	        rs = pstmt.executeQuery();

	        while (rs.next())      {
				String idStr = rs.getString(1);
				objVect.add(idStr);

	        }

	      }
	      catch (SQLException e)   {

	        //e.printStackTrace();

	      }

	      finally    {

	        try      {

	          if (rs != null)

	             rs.close();

	          if (pstmt != null)

	             pstmt.close();

	        }

	        catch (Exception e)      {

	          //e.printStackTrace();

	        }

	      }
	      return objVect;
	  }

	  private HashMap getDefaultValues(Connection conn,String sqlPartString,String repShortName, String doShortName,String repMgr,String roleValue)

	  	    {
			  StringBuffer idString  = new StringBuffer();
			  StringBuffer valString = new StringBuffer();
	  		  StringBuffer sqlString = new StringBuffer();
	  		  HashMap objHash = new HashMap();
	  		  Vector objIDVect = new Vector();
	  		  objIDVect = getDefaults(conn,repShortName,doShortName,repMgr,roleValue);
	  		  if(objIDVect!=null && objIDVect.size()>0){
	  		  sqlString.append(sqlPartString);
	  		  sqlString.append("( ");
	  		  for(int i=1;i<=objIDVect.size();i++){
				  sqlString.append(":"+i);
				  if(i<objIDVect.size())
				     sqlString.append(",");
				  if(i==objIDVect.size())
				     sqlString.append(")");
			  }
	  		  String sql = sqlString.toString();

	  	      PreparedStatement pstmt = null;

	  	      ResultSet rs  = null;

	          Vector objValueVect = new Vector();
	  	      try{

	  	        pstmt = conn.prepareStatement(sql);
	  	        oracle.jdbc.driver.OracleStatement ostmt = (oracle.jdbc.driver.OracleStatement) pstmt;
	  	        ostmt.defineColumnType(1,java.sql.Types.VARCHAR,4000);
	  	        ostmt.defineColumnType(2,java.sql.Types.VARCHAR,4000);

	  		  for(int i=1;i<=objIDVect.size();i++){
				  pstmt.setString(i, objIDVect.get(i-1).toString());
			  }

	  	        rs = pstmt.executeQuery();

	  	        while (rs.next())      {
	  				String idValStr = rs.getString(2);
	  				objValueVect.add(idValStr);

	  	        }
	  	        for(int i=1;i<=objIDVect.size();i++){
				  idString.append("'");
				  idString.append(objIDVect.get(i-1).toString());
				  idString.append("'");
				  if(i<objIDVect.size())
				     idString.append(",");
			    }

			    if(objValueVect!=null && objValueVect.size()>0){
			    for(int i=1;i<=objValueVect.size();i++){
				  valString.append(objValueVect.get(i-1).toString());
				  if(i<objValueVect.size())
				     valString.append("^^");
			    }
			    }
			    else
			    {
					valString.append("All");
				}
			    objHash.put("idString",idString);
			    objHash.put("valString",valString);
			  }
	  	      catch (SQLException e)   {

	  	        //e.printStackTrace();

	  	      }

	  	      finally    {

	  	        try      {

	  	          if (rs != null)

	  	             rs.close();

	  	          if (pstmt != null)

	  	             pstmt.close();

	  	        }

	  	        catch (Exception e)      {

	  	          //e.printStackTrace();

	  	        }

	  	      }
	  	      }
	  	      return objHash;
	  }

	  private String getDefaultRole(Connection conn,String repManager)
     {
			  StringBuffer sqlString = new StringBuffer();
			  sqlString.append(" select * from ( select role_value as role_value,count(do_short_name) as count_default from xxbi_dashboard_defaults where rep_mgr=:1 and role_value in (");

              String sqlTrailString = " ) group by role_value order by count(do_short_name) desc) where rownum=1";
              PreparedStatement pstmt = null;
	  	      ResultSet rs  = null;
	  	      String sql = null;
	  	      String userRole = "";
              HashMap objRoles = getUserRoles(conn,repManager);
              if(objRoles!=null){
              Vector mgrRoles = (Vector)objRoles.get("managerRoles");
              Vector memberRoles = (Vector)objRoles.get("memberRoles");
              Vector admRoles = (Vector)objRoles.get("adminRoles");
              if("R".equals(repManager)){
				  if(memberRoles!=null && memberRoles.size()>0){
					  for(int i=1;i<=memberRoles.size();i++){
					  	 sqlString.append(":"+i+1);
					  	 if(i<memberRoles.size())
					  		sqlString.append(",");
			  		  }
			  	   sqlString.append(sqlTrailString);
			  	   sql = sqlString.toString();
				   try{
                       pstmt = conn.prepareStatement(sql);
	  	               oracle.jdbc.driver.OracleStatement ostmt = (oracle.jdbc.driver.OracleStatement) pstmt;
	  	               ostmt.defineColumnType(1,java.sql.Types.VARCHAR,150);
	  	               ostmt.defineColumnType(2,java.sql.Types.NUMERIC,15);
	  	               pstmt.setString(1, repManager);
	  	               for(int i=1;i<=memberRoles.size();i++){
					   		pstmt.setString(i+1, memberRoles.get(i-1).toString());
			  			}
					   rs = pstmt.executeQuery();
					   while(rs.next()){
						   userRole = rs.getString(1);
					   }
				   }
				   catch (SQLException e){
				       //e.printStackTrace();
				   }
				   finally{
				      try{
				         if (rs != null)
				              rs.close();
				         if (pstmt != null)
				              pstmt.close();
				      }
				      catch (Exception e){
				         //e.printStackTrace();
				      }
                  }
				  }
				  else{
					 userRole = "DEFAULT";
				  }
			  }
			  if("M".equals(repManager)){
				  if(mgrRoles!=null && mgrRoles.size()>0){
					  for(int i=1;i<=mgrRoles.size();i++){
					  	 sqlString.append(":"+i+1);
					  	 if(i<mgrRoles.size())
					  		sqlString.append(",");
			  		  }
			  	   sqlString.append(sqlTrailString);
			  	   sql = sqlString.toString();
				   try{
                       pstmt = conn.prepareStatement(sql);
	  	               oracle.jdbc.driver.OracleStatement ostmt = (oracle.jdbc.driver.OracleStatement) pstmt;
	  	               ostmt.defineColumnType(1,java.sql.Types.VARCHAR,150);
	  	               ostmt.defineColumnType(2,java.sql.Types.NUMERIC,15);
	  	               pstmt.setString(1, repManager);
	  	               for(int i=1;i<=mgrRoles.size();i++){
					   		pstmt.setString(i+1, mgrRoles.get(i-1).toString());
			  			}
					   rs = pstmt.executeQuery();
					   while(rs.next()){
						   userRole = rs.getString(1);
					   }
				   }
				   catch (SQLException e){
				       //e.printStackTrace();
				   }
				   finally{
				      try{
				         if (rs != null)
				              rs.close();
				         if (pstmt != null)
				              pstmt.close();
				      }
				      catch (Exception e){
				         //e.printStackTrace();
				      }
                  }
				  }
				  else{
					  if(admRoles!=null && admRoles.size()>0){
					  	  for(int i=1;i<=admRoles.size();i++){
					  	  	 sqlString.append(":"+i+1);
					  	  	 if(i<admRoles.size())
					  	  		sqlString.append(",");
					  	  }
					  	sqlString.append(sqlTrailString);
					  	sql = sqlString.toString();
					  	try{
					          pstmt = conn.prepareStatement(sql);
					  	    oracle.jdbc.driver.OracleStatement ostmt = (oracle.jdbc.driver.OracleStatement) pstmt;
					  	    ostmt.defineColumnType(1,java.sql.Types.VARCHAR,150);
					  	    ostmt.defineColumnType(2,java.sql.Types.NUMERIC,15);
					  	    pstmt.setString(1, repManager);
					  	    for(int i=1;i<=admRoles.size();i++){
					  	   		pstmt.setString(i+1, admRoles.get(i-1).toString());
					  		}
					  	   rs = pstmt.executeQuery();
					  	   while(rs.next()){
					  		   userRole = rs.getString(1);
					  	   }
					  	}
					  	catch (SQLException e){
					  	    //e.printStackTrace();
					  	}
					  	finally{
					  	   try{
					  	      if (rs != null)
					  	           rs.close();
					  	      if (pstmt != null)
					  	           pstmt.close();
					  	   }
					  	   catch (Exception e){
					  	      //e.printStackTrace();
					  	   }
					     }
				      }
				      else{
						  userRole = "DEFAULT";
					  }
				  }
			  }
			  if("".equals(userRole)){
				  userRole = "DEFAULT";
			  }
		  }
		  return userRole;
	  }

        private String getDisplayName(Connection conn,String repShortName, String searchName)

	    {
		  StringBuffer sqlString = new StringBuffer();
		  sqlString.append(" select attribute_label_long from ak_region_items_vl where region_code = :1 and attribute2=:2 ");

		  String sql = sqlString.toString();

	      PreparedStatement pstmt = null;

	      ResultSet rs  = null;

          String dispName = null;
	      try

	      {

	        pstmt = conn.prepareStatement(sql);
	        oracle.jdbc.driver.OracleStatement ostmt = (oracle.jdbc.driver.OracleStatement) pstmt;
	        ostmt.defineColumnType(1,java.sql.Types.VARCHAR,80);

	        pstmt.setString(1, repShortName);
	        pstmt.setString(2, searchName);
	        rs = pstmt.executeQuery();

	        while (rs.next())      {
				dispName = rs.getString(1);

	        }

	      }

	      catch (SQLException e)   {

	        //e.printStackTrace();

	      }

	      finally    {

	        try      {

	          if (rs != null)

	             rs.close();

	          if (pstmt != null)

	             pstmt.close();

	        }

	        catch (Exception e)      {

	          //e.printStackTrace();

	        }

	      }
	      return dispName;
	  }


/*	private void testUpdate(java.lang.String s, java.sql.Connection connection)
	    {
	        java.lang.String s1 = " insert into smj_test values(:1,smj_test_id.nextval) ";
	        java.sql.PreparedStatement preparedstatement = null;
	        try
	        {
	            preparedstatement = connection.prepareStatement(s1);
	            preparedstatement.setString(1, s);
	            preparedstatement.executeUpdate();
	            connection.commit();
	        }
	        catch(java.sql.SQLException _ex) { }
	        finally
	        {
	            try
	            {
	                if(preparedstatement != null)
	                    preparedstatement.close();
	            }
	            catch(java.lang.Exception _ex) { }
	        }
    }
*/

        private HashMap getUserRoles(Connection conn, String repMgr)
	    {
		  StringBuffer sqlString = new StringBuffer();
		  sqlString.append(" SELECT ro.manager_flag, ro.admin_flag, ro.member_flag, ro.attribute14 ");
		  sqlString.append(" FROM jtf_rs_role_relations rr,jtf_rs_roles_b ro,jtf_rs_resource_extns r, ");
		  sqlString.append(" jtf_rs_group_mbr_role_vl gr,jtf_rs_group_usages u,jtf_rs_group_members jgm ");
		  sqlString.append(" WHERE r.user_id = :1 AND rr.role_resource_type = 'RS_GROUP_MEMBER' ");
		  sqlString.append(" AND rr.start_date_active <= SYSDATE AND (rr.end_date_active >= SYSDATE OR rr.end_date_active IS NULL) ");
		  sqlString.append(" AND rr.role_id = ro.role_id AND ro.role_type_code = 'SALES' AND gr.resource_id = r.resource_id ");
		  sqlString.append(" AND gr.role_id = ro.role_id AND u.GROUP_ID = gr.GROUP_ID AND u.USAGE = 'SALES' AND rr.delete_flag = 'N' ");
		  sqlString.append(" AND rr.role_resource_id = jgm.group_member_id AND r.resource_id = jgm.resource_id AND jgm.delete_flag = 'N' ");

		  String sql = sqlString.toString();

	      PreparedStatement pstmt = null;

	      ResultSet rs  = null;

          String userId = m_UserSession.getUserId();
          HashMap objHash = new HashMap();
	      try
	      {
	        pstmt = conn.prepareStatement(sql);
	        oracle.jdbc.driver.OracleStatement ostmt = (oracle.jdbc.driver.OracleStatement) pstmt;
	        ostmt.defineColumnType(1,java.sql.Types.VARCHAR,1);
	        ostmt.defineColumnType(2,java.sql.Types.VARCHAR,1);
	        ostmt.defineColumnType(3,java.sql.Types.VARCHAR,1);
	        ostmt.defineColumnType(4,java.sql.Types.VARCHAR,150);

	        pstmt.setString(1, userId);
	        rs = pstmt.executeQuery();

	        String mgrFlag = "";
	        String memberFlag = "";
	        String admFlag = "";
	        String roleCode = "";

	        Vector mgrRoles = new Vector();
	        Vector memberRoles = new Vector();
	        Vector admRoles = new Vector();

	        while (rs.next()){
				mgrFlag = rs.getString(1);
				admFlag = rs.getString(2);
				memberFlag = rs.getString(3);
				roleCode = rs.getString(4);
				if("M".equals(repMgr) && "Y".equals(mgrFlag))
					mgrRoles.add(roleCode);
				if("R".equals(repMgr) && "Y".equals(memberFlag))
					memberRoles.add(roleCode);
				if("M".equals(repMgr) && "Y".equals(admFlag))
					admRoles.add(roleCode);
	        }
	        objHash.put("managerRoles",mgrRoles);
	        objHash.put("memberRoles",memberRoles);
	        objHash.put("adminRoles",admRoles);
	      }

	      catch (SQLException e)   {

	        //e.printStackTrace();

	      }

	      finally    {

	        try      {

	          if (rs != null)

	             rs.close();

	          if (pstmt != null)

	             pstmt.close();

	        }

	        catch (Exception e)      {

	          //e.printStackTrace();

	        }

	      }
	      return objHash;
	  }


   private String isDefaultViewExists(HashMap viewList,Connection conn)
   {
      if(viewList == null || viewList.size() == 0){
        return "NO_DEFAULT";
	  }
      Set attrKeys = viewList.keySet();
      Iterator it = attrKeys.iterator();
      while(it.hasNext()){
        String key = (String)it.next();
        HashMap viewData = (HashMap) viewList.get(key);
        String defaultFlag = (String) viewData.get(PMVConstants.DEFAULT_CUSTOM_FLAG);
        if("Y".equals(defaultFlag)) return key;
      }
      return "NO_DEFAULT";
   }

   private String getDefViewURL(HashMap viewList, WebAppsContext webAppsContext,String key)
   {
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
	  paramRedirectUrl.append(decodedUrl);
	  paramRedirectUrl.append("&changeView=Y");
	}
	catch(UnsupportedEncodingException e) {}
      return paramRedirectUrl.toString();
   }

    public static final java.lang.String RCS_ID = "$Header: ODReportPageBean.java 115.380 2006/08/17 06:09:06 nkishore noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODReportPageBean.java 115.380 2006/08/17 06:09:06 nkishore noship $", "oracle.apps.bis.pmv.report");
    protected javax.servlet.ServletContext m_Application;
    protected javax.servlet.http.HttpSession m_Session;
    protected javax.servlet.http.HttpServletRequest m_Request;
    protected javax.servlet.http.HttpServletResponse m_Response;
    protected javax.servlet.jsp.JspWriter m_Out;
    protected oracle.apps.fnd.common.WebAppsContext m_WebAppsContext;
    protected oracle.apps.bis.pmv.session.UserSession m_UserSession;
    protected oracle.apps.bis.pmv.parameters.ParameterHelper m_ParamHelper;
    static final int CHUNK_SIZE = 32000;
    private final java.lang.String plugIdSQL = "Select plug_id from bis_schedule_preferences where schedule_id = :1 and nvl(file_id,0)=nvl(:2,0)";
    protected java.lang.String m_PlugId;
    protected javax.servlet.jsp.PageContext m_PageContext;
    protected oracle.apps.bis.renderer.Renderer m_Renderer;
    protected java.lang.String m_Env;
    protected oracle.apps.bis.metadata.MetadataNode m_rootNode;
    protected java.util.Locale m_Locale;
    protected java.lang.StringBuffer m_Content;
    protected java.lang.StringBuffer m_ParamSection;
    protected java.lang.StringBuffer m_PageHTML;
    static final java.lang.String SESSION_MAC_KEY = "SESSION_MAC_KEY";
    static final java.lang.String CANNOT_GET_MAC_KEY = "Session MAC Key cannot be retrieved";
    static final java.lang.String DBCONNECT_ERROR_MSG = "Cannot get Connection to the database";
    private oracle.apps.fnd.security.HMAC hmac;

}
