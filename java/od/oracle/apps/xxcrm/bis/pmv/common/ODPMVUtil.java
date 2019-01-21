// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODPMVUtil.java

package od.oracle.apps.xxcrm.bis.pmv.common;
import oracle.apps.bis.pmv.common.*;
import com.sun.java.util.collections.AbstractList;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.Iterator;
import com.sun.java.util.collections.Map;
import com.sun.java.util.collections.Set;
import java.io.UnsupportedEncodingException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.StringTokenizer;
import java.util.Vector;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.common.Util;
import oracle.apps.bis.metadata.MetadataAttributes;
import oracle.apps.bis.metadata.MetadataNode;
import oracle.apps.bis.msg.MessageLog;
import oracle.apps.bis.pmv.PMVException;
import oracle.apps.bis.pmv.data.PMVWeightAverageManager;
import oracle.apps.bis.pmv.header.HeaderBean;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.metadata.MeasureProperties;
import oracle.apps.bis.pmv.metadata.ReportDesignerRegion;
import oracle.apps.bis.pmv.parameters.ParamAssociation;
import oracle.apps.bis.pmv.parameters.ParameterHelper;
import oracle.apps.bis.pmv.parameters.ParameterSaveBean;
import oracle.apps.bis.pmv.parameters.ParameterUtil;
import oracle.apps.bis.pmv.portlet.Portlet;
import oracle.apps.bis.pmv.query.Calculation;
import oracle.apps.bis.pmv.relatedinfo.RelatedInfo;
import oracle.apps.bis.pmv.relatedinfo.RelatedInfoHelper;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.AppsContext;
import oracle.apps.fnd.common.Context;
import oracle.apps.fnd.common.EnvironmentStore;
import oracle.apps.fnd.common.ProfileStore;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.URLMgr;
import oracle.apps.fnd.functionSecurity.Function;
import oracle.apps.fnd.functionSecurity.FunctionSecurity;
import oracle.apps.fnd.functionSecurity.Resp;
import oracle.apps.fnd.functionSecurity.SecurityGroup;
import oracle.apps.fnd.security.HMAC;
import oracle.cabo.share.url.EncoderUtils;
import oracle.cabo.ui.ServletRenderingContext;
import oracle.jbo.RowSet;
import oracle.jdbc.OracleTypes;
import oracle.jdbc.driver.OracleCallableStatement;
import oracle.jdbc.driver.OraclePreparedStatement;
import oracle.jdbc.driver.OracleStatement;
import oracle.sql.DATE;

// Referenced classes of package oracle.apps.bis.pmv.common:
//            FormulaConstants, PMVConstants, StringUtil

public class ODPMVUtil
{

    public ODPMVUtil()
    {
    }

    public static boolean isMsgLogEnabled(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String s = webappscontext.getProfileStore().getProfile("AFLOG_ENABLED");
        java.lang.String s1 = webappscontext.getProfileStore().getProfile("AFLOG_MODULE");
        java.lang.String s2 = webappscontext.getProfileStore().getProfile("BIS_PMF_DEBUG");
        return ("Y".equals(s2) || "Y".equals(s)) && "BIS%".equalsIgnoreCase(s1);
    }

    public static boolean isMsgLogEnabled(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext)
    {
        java.lang.String s = oapagecontext.getProfile("AFLOG_MODULE");
        java.lang.String s1 = oapagecontext.getProfile("AFLOG_MODULE");
        java.lang.String s2 = oapagecontext.getProfile("BIS_PMF_DEBUG");
        return ("Y".equals(s2) || "Y".equals(s)) && "BIS%".equalsIgnoreCase(s1);
    }

    public static java.lang.String getDbc(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext)
    {
        java.lang.String s = null;
        if(oapagecontext != null)
        {
            oracle.apps.fnd.framework.OAApplicationModule oaapplicationmodule = oapagecontext.getRootApplicationModule();
            if(oaapplicationmodule != null)
                s = oaapplicationmodule.getDbc();
            if(s == null)
                s = oapagecontext.getParameter("dbc");
        }
        return s;
    }

    public static java.lang.String getDimLevel(java.lang.String s)
    {
        java.lang.String s1 = "";
        if(s.indexOf("+") >= 0)
            s1 = s.substring(s.indexOf("+") + 1);
        return s1;
    }

    public static java.lang.String getDimension(java.lang.String s)
    {
        java.lang.String s1 = "";
        if(s.indexOf("+") >= 0)
            s1 = s.substring(0, s.indexOf("+", 0));
        return s1;
    }

    public static java.lang.String getImagesServer(oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection)
    {
        java.lang.String s = oracle.apps.bis.common.Util.getImagesServer(webappscontext, connection);
        return s;
    }

    public static java.lang.String trail_slash(java.lang.String s)
    {
        java.lang.String s1;
        for(s1 = s; s1.endsWith("/"); s1 = s1.substring(0, s1.length() - 1));
        return s1 + "/";
    }

    public static java.lang.String getJspAgent(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String s = null;
        s = webappscontext.getProfileStore().getProfile("APPS_SERVLET_AGENT");
        return od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspUrl(s);
    }

    public static java.lang.String getJspUrl(java.lang.String s)
    {
        int i = -1;
        int j = -1;
        s = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.trail_slash(s);
        i = s.indexOf("//") + 2;
        j = s.indexOf("/", i);
        if(i != j && i != 2 && i != -1 && j != -1)
			//QC 5426 FIX BY ANIRBAN C
            return od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.trail_slash(s.substring(0, j)) + "OA_HTML/";
        else
            return "Invalid Url";
    }

    public static java.lang.String getPlsqlAgent(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        return od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.trail_slash(webappscontext.getProfileStore().getProfile("APPS_WEB_AGENT"));
    }

    public static java.lang.String getFrameworkAgent(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        if(webappscontext != null)
            m_FrameworkAgent = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.trail_slash(webappscontext.getProfileStore().getProfile("APPS_FRAMEWORK_AGENT"));
        return m_FrameworkAgent;
    }

    public static java.lang.String getFrameworkAgent()
    {
        if(m_FrameworkAgent != null)
            return m_FrameworkAgent;
        else
            return "";
    }

    public static java.lang.String[] getTargetInfo(java.lang.String s)
    {
        java.lang.String as[] = new java.lang.String[4];
        int i = s.indexOf("*");
        int j = s.indexOf("**");
        int k = s.indexOf("***");
        as[0] = s.substring(0, i) + "&pageSource=" + oracle.apps.bis.pmv.session.UserSession.pmRegion;
        as[1] = s.substring(i + 1, j);
        as[2] = s.substring(j + 2, k);
        as[3] = s.substring(k + 3, s.length());
        return as;
    }

    public static java.lang.String getMessage(java.lang.String s, java.lang.String s1, java.lang.String s2, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        return oracle.apps.bis.common.Util.getMessage(s, s1, s2, webappscontext);
    }

    public static java.lang.String getMessage(java.lang.String s, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        return oracle.apps.bis.common.Util.getMessage(s, webappscontext);
    }

    public static boolean isDynamicLabel(java.lang.String s)
    {
        int i = s.indexOf("\"");
        int j = s.indexOf("\"", i + 1);
        return j > i;
    }

    public static java.lang.String getErrorUrl(oracle.apps.bis.pmv.session.UserSession usersession, java.lang.String s, javax.servlet.http.HttpServletRequest httpservletrequest)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        java.lang.String s1 = usersession.getWebAppsContext().getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(usersession.getWebAppsContext())).append("bispmver.jsp?");
        try
        {
            stringbuffer.append("regionCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getRegionCode(), s1));
            stringbuffer.append("&functionName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getFunctionName(), s1));
            stringbuffer.append("&msgName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s, s1));
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        stringbuffer.append("&dbc=").append(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "dbc"));
        stringbuffer.append("&transactionid=").append(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "transactionid"));
        return stringbuffer.toString();
    }

    public static java.lang.String getErrorUrl(oracle.apps.fnd.common.WebAppsContext webappscontext, java.lang.String s, javax.servlet.http.HttpServletRequest httpservletrequest, java.lang.String s1, java.lang.String s2)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        java.lang.String s3 = webappscontext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(webappscontext)).append("bispmver.jsp?");
        try
        {
            if(s2 != null)
                stringbuffer.append("regionCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s2, s3));
            if(s1 != null)
                stringbuffer.append("&functionName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s1, s3));
            if(s != null)
                stringbuffer.append("&msgName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s, s3));
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        stringbuffer.append("&dbc=").append(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "dbc"));
        stringbuffer.append("&transactionid=").append(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "transactionid"));
        return stringbuffer.toString();
    }

    public static java.lang.String getErrorUrl(oracle.apps.bis.pmv.session.UserSession usersession, java.lang.String s, javax.servlet.http.HttpServletRequest httpservletrequest, javax.servlet.jsp.PageContext pagecontext)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        java.lang.String s1 = usersession.getWebAppsContext().getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(usersession.getWebAppsContext())).append("bispmver.jsp?");
        try
        {
            stringbuffer.append("regionCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getRegionCode(), s1));
            stringbuffer.append("&functionName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getFunctionName(), s1));
            pagecontext.getSession().putValue("msgName", s);
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        stringbuffer.append("&dbc=").append(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "dbc"));
        stringbuffer.append("&transactionid=").append(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "transactionid"));
        return stringbuffer.toString();
    }

    public static java.lang.String getRegionCodeFromFunctionName(java.lang.String s, java.sql.Connection connection)
    {
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        java.lang.String s1 = null;
        try
        {
            java.lang.String s2 = "BEGIN :1 := BIS_PMV_UTIL.getReportRegion(:2); END;";
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s2);
            oraclecallablestatement.registerOutParameter(1, 12, 0, 30);
            oraclecallablestatement.setString(2, s);
            oraclecallablestatement.execute();
            s1 = oraclecallablestatement.getString(1);
        }
        catch(java.lang.Exception _ex)
        {
            s1 = null;
        }
        finally
        {
            if(oraclecallablestatement != null)
                try
                {
                    oraclecallablestatement.close();
                }
                catch(java.lang.Exception _ex)
                {
                    oraclecallablestatement = null;
                }
        }
        return s1;
    }

    public static java.lang.String getTimeDescription(java.sql.Connection connection, java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4)
    {
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        java.lang.String s5 = "All";
        try
        {
            java.lang.String s6 = "begin BIS_PMV_PARAMETERS_PVT.GET_TIME_INFO(:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12); end;";
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s6);
            oraclecallablestatement.setString(1, s);
            oraclecallablestatement.setString(2, s1);
            oraclecallablestatement.setString(3, s2);
            oraclecallablestatement.setString(4, s3);
            oraclecallablestatement.setString(5, s4);
            oraclecallablestatement.registerOutParameter(6, 12, 0, 240);
            oraclecallablestatement.registerOutParameter(7, 12, 0, 80);
            oraclecallablestatement.registerOutParameter(8, 12, 0, 240);
            oraclecallablestatement.registerOutParameter(9, 12, 0, 240);
            oraclecallablestatement.registerOutParameter(10, 12, 0, 1);
            oraclecallablestatement.registerOutParameter(11, 4, 2);
            oraclecallablestatement.registerOutParameter(12, 12, 0, 300);
            oraclecallablestatement.execute();
            s5 = oraclecallablestatement.getString(6);
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
        return s5;
    }

    public static java.lang.String getParamValue(java.lang.String s, java.lang.String s1, java.lang.String s2)
    {
        java.lang.String s3 = "";
        if(s != null && s1 != null)
        {
            int i = s.indexOf(s1);
            if(i >= 0)
            {
                int j = s.indexOf(s2, i);
                if(j < 0)
                    j = s.length();
                i = i + s1.length() + 1;
                s3 = s.substring(i, j);
            }
        }
        return s3;
    }

    public static java.lang.String getUrlParamValue(java.lang.String s, java.lang.String s1)
    {
        return od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParamValue(s, s1, "&");
    }

    public static java.lang.String removeUrlParam(java.lang.String s, java.lang.String s1)
    {
        return od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.removeParam(s, s1, "&");
    }

    public static java.lang.String removeParam(java.lang.String s, java.lang.String s1, java.lang.String s2)
    {
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
        {
            int i = s.indexOf(s1);
            if(i >= 0)
            {
                int j = s.indexOf(s2, i);
                if(j < 0)
                    j = s.length();
                if(i != 0)
                    i--;
                s = s.substring(0, i) + s.substring(j, s.length());
            }
        }
        return s;
    }

    public static void refreshPage(java.lang.String s, java.sql.Connection connection)
    {
        java.lang.String s1 = "BEGIN BIS_PMV_UTIL.update_portlets_bypage(:1); end;";
        java.sql.CallableStatement callablestatement = null;
        try
        {
            callablestatement = connection.prepareCall(s1);
            callablestatement.setString(1, s);
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

    public static java.lang.String getCustomDateLabel(java.sql.Connection connection, java.lang.String s, java.lang.String s1)
    {
        java.lang.String s2 = "";
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        try
        {
            java.lang.String s3 = "begin :1 := bsc_periods_utility_pkg.get_quarter_date_label(:2, :3); end;";
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s3);
            oraclecallablestatement.registerOutParameter(1, 12, 0, 200);
            oraclecallablestatement.setString(2, s);
            oraclecallablestatement.setString(3, s1);
            oraclecallablestatement.execute();
            s2 = oraclecallablestatement.getString(1);
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
        return s2;
    }

    public static java.lang.String getDateLabel(java.sql.Connection connection, oracle.sql.DATE date)
    {
        java.lang.String s = "";
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        try
        {
            java.lang.String s1 = "begin :1 := FII_TIME_API.day_left_in_qtr(:2); end;";
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s1);
            oraclecallablestatement.registerOutParameter(1, 12, 0, 200);
            oraclecallablestatement.setDATE(2, date);
            oraclecallablestatement.execute();
            s = oraclecallablestatement.getString(1);
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
        return s;
    }

    public static java.lang.String getPortalAgent(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String s = webappscontext.getProfileStore().getProfile("APPS_PORTAL");
        return od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getPortalUrl(s);
    }

    public static java.lang.String getPortalUrl(java.lang.String s)
    {
        byte byte0 = -1;
        if(s != null)
        {
            int i = s.lastIndexOf("/");
            if(i != -1)
                return s.substring(0, i + 1);
        }
        return "Invalid Url";
    }

    /**
     * @deprecated Method getAttr2FromAttrCode is deprecated
     */

    public static java.lang.String getAttr2FromAttrCode(java.lang.String s, java.lang.String s1, java.sql.Connection connection)
    {
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        java.lang.String s2 = null;
        java.lang.String s3 = "BEGIN :1 := BIS_PMV_UTIL.getDimensionForAttribute(:2,:3); END;";
        try
        {
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s1) && connection != null)
            {
                oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s3);
                oraclecallablestatement.setString(2, s1.trim());
                oraclecallablestatement.setString(3, s);
                oraclecallablestatement.registerOutParameter(1, 12, 0, 1000);
                oraclecallablestatement.execute();
                s2 = oraclecallablestatement.getString(1);
            }
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            if(oraclecallablestatement != null)
                try
                {
                    oraclecallablestatement.close();
                }
                catch(java.sql.SQLException _ex) { }
        }
        return s2;
    }

    public static java.lang.String getDefaultRespId(java.lang.String s, java.lang.String s1, java.sql.Connection connection)
    {
        java.lang.String s2 = " select bis_pmv_util.getdefaultresponsibility(:1, :2) from dual";
        java.lang.String s3 = "";
        java.sql.CallableStatement callablestatement = null;
        java.sql.ResultSet resultset = null;
        try
        {
            callablestatement = connection.prepareCall(s2);
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)callablestatement;
            oraclestatement.defineColumnType(1, 12, 20);
            callablestatement.setString(1, s);
            callablestatement.setString(2, s1);
            resultset = callablestatement.executeQuery();
            if(resultset.next())
                s3 = resultset.getString(1);
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(callablestatement != null)
                    callablestatement.close();
                if(resultset != null)
                    resultset.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        return s3;
    }

    public static java.lang.String[] getBindVariablesFromBindString(java.lang.String s, java.lang.String s1)
    {
        java.util.StringTokenizer stringtokenizer = new StringTokenizer(s, s1, true);
        java.lang.String s2 = "";
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(11);
        while(stringtokenizer.hasMoreTokens())
        {
            java.lang.String s3 = stringtokenizer.nextToken();
            if(!s3.equals(s1))
                arraylist.add(s3);
            else
            if(s3.equals(s2))
                arraylist.add(null);
            s2 = s3;
        }
        if(s2.equals(s1))
            arraylist.add(null);
        java.lang.String as[] = (java.lang.String[])arraylist.toArray(new java.lang.String[arraylist.size()]);
        return as;
    }

    public static int[] stringArrayToIntArray(java.lang.String as[])
    {
        int ai[] = new int[as.length];
        for(int i = 0; i < as.length; i++)
            ai[i] = java.lang.Integer.parseInt(as[i]);

        return ai;
    }

    public static void quickSort(int ai[], java.lang.String as[], int ai1[], int i, int j)
    {
        int i1 = i;
        int j1 = j;
        int k1 = ai[(i + j) / 2];
        do
        {
            while(ai[i1] < k1)
                i1++;
            for(; ai[j1] > k1; j1--);
            if(i1 <= j1)
            {
                int k = ai[i1];
                ai[i1] = ai[j1];
                ai[j1] = k;
                if(as != null)
                {
                    java.lang.String s = as[i1];
                    as[i1] = as[j1];
                    as[j1] = s;
                }
                if(ai1 != null)
                {
                    int l = ai1[i1];
                    ai1[i1] = ai1[j1];
                    ai1[j1] = l;
                }
                i1++;
                j1--;
            }
        } while(i1 <= j1);
        if(i < j1)
            od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.quickSort(ai, as, ai1, i, j1);
        if(i1 < j)
            od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.quickSort(ai, as, ai1, i1, j);
    }

    public static java.lang.String getParamString(java.sql.Connection connection, java.lang.String s, java.lang.String s1)
    {
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        java.lang.String s2 = "";
        java.lang.String s3 = "BEGIN BIS_PMV_PAGE_PARAMS_PUB.RETRIEVE_PARAMSTR_BYUSERID(:1, :2,:3,:4,:5,:6); END;";
        try
        {
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s3);
            oraclecallablestatement.setString(1, s);
            oraclecallablestatement.setString(2, s1);
            oraclecallablestatement.registerOutParameter(3, 12, 0, 3000);
            oraclecallablestatement.registerOutParameter(4, 12, 0, 1);
            oraclecallablestatement.registerOutParameter(5, 2);
            oraclecallablestatement.registerOutParameter(6, 12, 0, 2000);
            oraclecallablestatement.execute();
            s2 = oraclecallablestatement.getString(3);
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
        return s2;
    }

    public static java.lang.String getICXDateFormat(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String s = null;
        s = webappscontext.getNLSDateFormat();
        if(s == null || "".equals(s))
            s = "DD-MON-RRRR";
        return s;
    }

    public static java.lang.String oracleToJavaDateFormat(java.lang.String s)
    {
        return od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.oracleToJavaDateFormat(s, false);
    }

    public static java.lang.String oracleToJavaDateFormat(java.lang.String s, boolean flag)
    {
        java.lang.String s1 = null;
        if("DD-MM-RRRR".equals(s))
            s1 = "dd-MM-yyyy";
        else
        if("DD-MON-RRRR".equals(s))
            s1 = "dd-MMM-yyyy";
        else
        if("DD.MM.RRRR".equals(s))
            s1 = "dd.MM.yyyy";
        else
        if("DD.MON.RRRR".equals(s))
            s1 = "dd.MMM.yyyy";
        else
        if("DD/MM/RRRR".equals(s))
            s1 = "dd/MM/yyyy";
        else
        if("DD/MON/RRRR".equals(s))
            s1 = "dd/MMM/yyyy";
        else
        if("MM-DD-RRRR".equals(s))
            s1 = "MM-dd-yyyy";
        else
        if("MM.DD.RRRR".equals(s))
            s1 = "MM.dd.yyyy";
        else
        if("MM/DD/RRRR".equals(s))
            s1 = "MM/dd/yyyy";
        else
        if("RRRR-MM-DD".equals(s))
            s1 = "yyyy-MM-dd";
        else
        if("RRRR-MON-DD".equals(s))
            s1 = "yyyy-MMM-dd";
        else
        if("RRRR.MM.DD".equals(s))
            s1 = "yyyy.MM.dd";
        else
        if("RRRR.MON.DD".equals(s))
            s1 = "yyyy.MMM.dd";
        else
        if("RRRR/MM/DD".equals(s))
            s1 = "yyyy/MM/dd";
        else
        if("RRRR/MON/DD".equals(s))
            s1 = "yyyy/MMM/dd";
        else
            s1 = "MM/dd/yyyy";
        if(!flag)
            return s1;
        else
            return oracle.apps.bis.pmv.common.StringUtil.replaceAll(s1, "MMM", "MM");
    }

    public static java.lang.String getNLSNumericCharacters(java.sql.Connection connection)
    {
        return oracle.apps.bis.common.Util.getNLSNumericCharacters(connection);
    }

    public static java.lang.String getHelpTarget(java.sql.Connection connection, java.lang.String s)
    {
        java.lang.String s1 = null;
        java.lang.String s2 = "select target_name from fnd_help_targets where target_name = :1";
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        try
        {
            preparedstatement = connection.prepareStatement(s2);
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            oraclestatement.defineColumnType(1, 12, 256);
            preparedstatement.setString(1, s);
            resultset = preparedstatement.executeQuery();
            if(resultset.next())
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
        return s1;
    }

    public static int getMaxFetchRows(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        int i = 100;
        if(webappscontext != null)
        {
            java.lang.String s = webappscontext.getProfileStore().getProfile("VO_MAX_FETCH_SIZE");
            if(s != null)
                try
                {
                    i = java.lang.Integer.parseInt(s);
                }
                catch(java.lang.NumberFormatException _ex) { }
        }
        return i;
    }

    public static void setFndGlobalAppsContext(java.sql.Connection connection, java.lang.String s, java.lang.String s1, java.lang.String s2)
    {
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        java.lang.String s3 = "BEGIN fnd_global.apps_initialize(:1,:2,:3); END;";
        try
        {
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s3);
            oraclecallablestatement.setString(1, s);
            oraclecallablestatement.setString(2, s1);
            oraclecallablestatement.setString(3, s2);
            oraclecallablestatement.execute();
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
    }

    public static java.lang.String getAutoScalingProfile(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String s = webappscontext.getProfileStore().getProfile("BIS_AUTO_FACTOR");
        if(s == null || s.equals(""))
            s = "Y";
        return s;
    }

    public static void QuickSortColumns(com.sun.java.util.collections.ArrayList arraylist, int i, int j)
    {
        int k = i;
        int l = j;
        if(j > i)
        {
            int i1 = (i + j) / 2;
            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist.get(i1);
            int j1 = java.lang.Integer.parseInt(akregionitem.getDisplaySequence());
            while(k <= l)
            {
                oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem1 = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist.get(k);
                for(int k1 = java.lang.Integer.parseInt(akregionitem1.getDisplaySequence()); k < j && k1 < j1; k1 = java.lang.Integer.parseInt(akregionitem1.getDisplaySequence()))
                {
                    k++;
                    akregionitem1 = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist.get(k);
                }

                oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem2 = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist.get(l);
                for(int l1 = java.lang.Integer.parseInt(akregionitem2.getDisplaySequence()); l > i && l1 > j1; l1 = java.lang.Integer.parseInt(akregionitem2.getDisplaySequence()))
                {
                    l--;
                    akregionitem2 = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist.get(l);
                }

                if(k <= l)
                {
                    oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem3 = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist.get(k);
                    oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem4 = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist.get(l);
                    od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.swap(arraylist, akregionitem3, akregionitem4, k, l);
                    k++;
                    l--;
                }
            }
            if(i < l)
                od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.QuickSortColumns(arraylist, i, l);
            if(k < j)
                od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.QuickSortColumns(arraylist, k, j);
        }
    }

    public static void QuickSortNodes(com.sun.java.util.collections.ArrayList arraylist, int i, int j)
    {
        int k = i;
        int l = j;
        if(j > i)
        {
            int i1 = (i + j) / 2;
            oracle.apps.bis.metadata.MetadataNode metadatanode = (oracle.apps.bis.metadata.MetadataNode)arraylist.get(i1);
            int j1 = java.lang.Integer.parseInt((java.lang.String)metadatanode.getAttribute("dataSetDisplaySeq"));
            while(k <= l)
            {
                oracle.apps.bis.metadata.MetadataNode metadatanode1 = (oracle.apps.bis.metadata.MetadataNode)arraylist.get(k);
                int k1;
                for(k1 = java.lang.Integer.parseInt((java.lang.String)metadatanode1.getAttribute("dataSetDisplaySeq")); k < j && k1 < j1; k1 = java.lang.Integer.parseInt((java.lang.String)metadatanode1.getAttribute("dataSetDisplaySeq")))
                {
                    k++;
                    metadatanode1 = (oracle.apps.bis.metadata.MetadataNode)arraylist.get(k);
                }

                oracle.apps.bis.metadata.MetadataNode metadatanode2 = (oracle.apps.bis.metadata.MetadataNode)arraylist.get(l);
                int l1;
                for(l1 = java.lang.Integer.parseInt((java.lang.String)metadatanode2.getAttribute("dataSetDisplaySeq")); l > i && l1 > j1; l1 = java.lang.Integer.parseInt((java.lang.String)metadatanode2.getAttribute("dataSetDisplaySeq")))
                {
                    l--;
                    metadatanode2 = (oracle.apps.bis.metadata.MetadataNode)arraylist.get(l);
                }

                if(k <= l)
                {
                    if(l1 != k1)
                    {
                        oracle.apps.bis.metadata.MetadataNode metadatanode3 = (oracle.apps.bis.metadata.MetadataNode)arraylist.get(k);
                        oracle.apps.bis.metadata.MetadataNode metadatanode4 = (oracle.apps.bis.metadata.MetadataNode)arraylist.get(l);
                        od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.swapNodes(arraylist, metadatanode3, metadatanode4, k, l);
                    }
                    k++;
                    l--;
                }
            }
            if(i < l)
                od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.QuickSortNodes(arraylist, i, l);
            if(k < j)
                od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.QuickSortNodes(arraylist, k, j);
        }
    }

    private static void swap(com.sun.java.util.collections.ArrayList arraylist, oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem, oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem1, int i, int j)
    {
        arraylist.set(j, akregionitem);
        arraylist.set(i, akregionitem1);
        akregionitem = akregionitem1;
    }

    private static void swapNodes(com.sun.java.util.collections.ArrayList arraylist, oracle.apps.bis.metadata.MetadataNode metadatanode, oracle.apps.bis.metadata.MetadataNode metadatanode1, int i, int j)
    {
        arraylist.set(j, metadatanode);
        arraylist.set(i, metadatanode1);
        metadatanode = metadatanode1;
    }

    public static java.lang.String getLastRefreshDate(java.lang.String s, java.sql.Connection connection, java.lang.String s1)
    {
        java.lang.String s2 = "";
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        java.lang.String s3 = "BEGIN :1 := BIS_PMV_UTIL.GET_LAST_REFRESH_DATE(:2,:3); END;";
        try
        {
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s3);
            oraclecallablestatement.registerOutParameter(1, 12, 0, 200);
            oraclecallablestatement.setString(2, s1);
            oraclecallablestatement.setString(3, s);
            oraclecallablestatement.execute();
            java.lang.String s4 = oraclecallablestatement.getString(1);
            s2 = s4 != null ? s4 : "";
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
        return s2.toString();
    }

    public static java.lang.String getCustomViewName(java.sql.Connection connection, java.lang.String s)
    {
        java.lang.String s1 = null;
        java.lang.String s2 = "";
        java.lang.String s3 = "select parameters from fnd_form_functions  where function_name = :1";
        java.sql.CallableStatement callablestatement = null;
        java.sql.ResultSet resultset = null;
        try
        {
            callablestatement = connection.prepareCall(s3);
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)callablestatement;
            oraclestatement.defineColumnType(1, 12, 2000);
            callablestatement.setString(1, s);
            resultset = callablestatement.executeQuery();
            if(resultset.next())
                s1 = resultset.getString(1);
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(callablestatement != null)
                    callablestatement.close();
                if(resultset != null)
                    resultset.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        if(s1 != null)
            s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s1, "pCustomView");
        return s2;
    }

    public static java.lang.String getParameterValue(java.lang.String s, java.lang.String s1)
    {
        java.lang.String s2 = "";
        int i = 0;
        boolean flag = false;
        boolean flag1 = false;
        i = s.indexOf(s1 + "=");
        if(i >= 0)
        {
            int j = i + s1.length() + 1;
            int k = s.indexOf("&", j);
            if(k > 0)
                s2 = s.substring(j, k);
            else
                s2 = s.substring(j);
        }
        return s2;
    }

    public static boolean isNumericDateLanguage(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        boolean flag = false;
        if(webappscontext != null)
        {
            java.lang.String s = null;
            java.lang.String s1 = webappscontext.getEnvStore().getEnv("NLS_LANG");
            java.lang.String s2 = webappscontext.getEnvStore().getEnv("NLS_DATE_LANGUAGE");
            if(s1 == null)
            {
                s = webappscontext.getEnvStore().getEnv("NLS_LANGUAGE");
            } else
            {
                int i = s1.indexOf('_');
                s = s1.substring(0, i);
            }
            if(s == null)
                s = "AMERICAN";
            else
                s = s.trim().toUpperCase();
            if("ARABIC".equals(s) || "NUMERIC DATE LANGUAGE".equals(s) || "NUMERIC DATE LANGUAGE".equals(s2))
                flag = true;
        }
        return flag;
    }

    public static java.lang.String getEscapedHTML(java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("");
        java.lang.String s1 = "";
        java.lang.String s2 = "";
        if(s != null)
            s1 = oracle.apps.bis.pmv.common.StringUtil.replaceAll(s, "\"", "&quot;");
        if(s1 != null)
            s2 = oracle.apps.bis.pmv.common.StringUtil.replaceAll(s1, "\\", "\\\\");
        stringbuffer.append(oracle.apps.bis.pmv.common.StringUtil.replaceAll(s2, "'", "\\'"));
        return stringbuffer.toString();
    }

    public static java.lang.String getPageId(java.lang.String s, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String s1 = webappscontext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        java.lang.String s2 = "";
        try
        {
            s2 = oracle.cabo.share.url.EncoderUtils.decodeString(s, s1);
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        for(; s2.indexOf(",") >= 0; s2 = s2.substring(0, s2.indexOf(",")) + s2.substring(s2.indexOf(",") + 1));
        for(; s2.indexOf("_") >= 0; s2 = s2.substring(0, s2.indexOf("_")) + s2.substring(s2.indexOf("_") + 1));
        if(s2 != null && s2.length() > 0)
            return s2;
        else
            return s;
    }

    public static java.lang.String getEscapePlsqlString(java.lang.String s)
    {
        if(s != null)
        {
            int i = s.length();
            java.lang.StringBuffer stringbuffer = new StringBuffer(250);
            if(!s.startsWith("'"))
                stringbuffer.append("'");
            for(int j = 0; j < i; j++)
            {
                char c = s.charAt(j);
                switch(c)
                {
                case 39: // '\''
                    if(j == 0 || j == i - 1)
                        stringbuffer.append(c);
                    else
                        stringbuffer.append("''");
                    break;

                default:
                    stringbuffer.append(c);
                    break;
                }
            }

            if(!s.endsWith("'"))
                stringbuffer.append("'");
            return stringbuffer.toString();
        } else
        {
            return "";
        }
    }

    public static void logMessage(java.lang.String s, boolean flag, java.lang.String s1, int i, oracle.apps.bis.msg.MessageLog messagelog)
    {
        try
        {
            if(messagelog != null)
            {
                if(i == 5 || i == 1000)
                {
                    if(flag)
                        messagelog.newProgress(s);
                    if(i == 5)
                        messagelog.logMessage(s, s1, i);
                }
                return;
            }
        }
        catch(java.lang.Exception _ex) { }
    }

    public static void closeProgress(java.lang.String s, oracle.apps.bis.msg.MessageLog messagelog)
    {
        try
        {
            messagelog.closeProgress(s);
            return;
        }
        catch(java.lang.Exception _ex)
        {
            return;
        }
    }

    public static void stalePortlet(java.sql.Connection connection, java.lang.String s, oracle.apps.bis.msg.MessageLog messagelog)
    {
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        java.lang.String s1 = "BEGIN BIS_PMV_UTIL.STALE_PORTLET_BY_PLUGID(:1); END;";
        try
        {
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s1);
            oraclecallablestatement.setString(1, s);
            oraclecallablestatement.execute();
        }
        catch(java.lang.Exception _ex) { }
        finally
        {
            try
            {
                if(oraclecallablestatement != null)
                    oraclecallablestatement.close();
            }
            catch(java.lang.Exception _ex)
            {
                oraclecallablestatement = null;
            }
        }
    }

    public static java.lang.String getSubstitutedFormula(java.lang.String s, oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem, com.sun.java.util.collections.HashMap hashmap)
    {
        if(s != null && akregionitem != null && hashmap != null && ("CHANGE_MEASURE".equals(akregionitem.getRegionItemType()) || "CHANGE_MEASURE_NO_TARGET".equals(akregionitem.getRegionItemType())) && oracle.apps.bis.pmv.common.FormulaConstants.isFormulaConstant(s))
        {
            s = oracle.apps.bis.pmv.common.FormulaConstants.getPredefinedFormula(s);
            java.lang.String s1 = akregionitem.getAttribute2();
            if(s1 != null)
            {
                java.lang.String s2 = (java.lang.String)hashmap.get(s1);
                if(s2 != null)
                {
                    s = oracle.apps.bis.pmv.common.StringUtil.replaceAll(s, oracle.apps.bis.pmv.common.FormulaConstants.getActualConstant(), s1);
                    s = oracle.apps.bis.pmv.common.StringUtil.replaceAll(s, oracle.apps.bis.pmv.common.FormulaConstants.getCompareToConstant(), s2);
                }
            }
        }
        return s;
    }

    public static java.lang.String getSubstitutedFormulaWithBinds(java.lang.String s)
    {
        if(s != null && oracle.apps.bis.pmv.common.FormulaConstants.isFormulaConstant(s))
        {
            s = oracle.apps.bis.pmv.common.FormulaConstants.getPredefinedFormula(s);
            s = oracle.apps.bis.pmv.common.StringUtil.replaceAll(s, oracle.apps.bis.pmv.common.FormulaConstants.getActualConstant(), ":1");
            s = oracle.apps.bis.pmv.common.StringUtil.replaceAll(s, oracle.apps.bis.pmv.common.FormulaConstants.getCompareToConstant(), ":2");
            s = s.substring(1, s.length() - 1);
        }
        return s;
    }

    public static java.lang.String getFrmFxnParameters(java.sql.Connection connection, java.lang.String s)
    {
        java.lang.String s1 = "SELECT PARAMETERS FROM FND_FORM_FUNCTIONS_VL WHERE FUNCTION_NAME = :1";
        java.sql.CallableStatement callablestatement = null;
        java.sql.ResultSet resultset = null;
        java.lang.String s2 = "";
        try
        {
            callablestatement = connection.prepareCall(s1);
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)callablestatement;
            oraclestatement.defineColumnType(1, 12, 4000);
            callablestatement.setString(1, s);
            resultset = callablestatement.executeQuery();
            if(resultset.next())
                s2 = resultset.getString(1);
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(callablestatement != null)
                    callablestatement.close();
                if(resultset != null)
                    resultset.close();
            }
            catch(java.lang.Exception _ex)
            {
                Object obj = null;
                Object obj1 = null;
            }
        }
        return s2;
    }

    public static void saveParametersFromFrmFxn(oracle.apps.bis.pmv.session.UserSession usersession, java.lang.String s, java.lang.String s1)
        throws oracle.apps.bis.pmv.PMVException
    {
        java.util.Hashtable hashtable = oracle.apps.bis.pmv.portlet.Portlet.getParameterHashTable(s, usersession.getRegionCode(), usersession.getConnection(), usersession.getAKRegion(), usersession.getWebAppsContext());
        oracle.apps.bis.pmv.parameters.ParameterSaveBean parametersavebean = new ParameterSaveBean();
        parametersavebean.init(usersession);
        parametersavebean.setpSaveByIds(s1);
        parametersavebean.saveParameters(hashtable, usersession);
    }

    public static void saveParametersFromFrmFxn(oracle.apps.bis.pmv.session.UserSession usersession, java.lang.String s)
        throws oracle.apps.bis.pmv.PMVException
    {
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s, "pParamIds");
        s1 = s1 != null ? s1 : "N";
        od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.saveParametersFromFrmFxn(usersession, s, s1);
    }

    public static java.lang.String processFrmFxnParameters(java.sql.Connection connection, java.lang.String s)
    {
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFrmFxnParameters(connection, s);
        return od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.buildFrmFxnParameters(s1, connection);
    }

    public static java.lang.String buildFrmFxnParameters(java.lang.String s, java.sql.Connection connection)
    {
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s, "pPLSQLFunction");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
        {
            java.lang.String s2 = oracle.apps.bis.pmv.portlet.Portlet.getResultFromPLSQLFunction(s1, connection);
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
                if(s2.startsWith("&"))
                    s = s + s2;
                else
                    s = s + "&" + s2;
        }
        java.lang.String s3 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s, "pAsOfDate");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s3))
        {
            java.lang.String s4 = oracle.apps.bis.pmv.portlet.Portlet.getDateFromPLSQLFunction(s3, connection);
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s4))
                s = s + "&AS_OF_DATE=" + s4;
        }
        return s;
    }

    public static java.lang.String hasFunctionAccess(java.lang.String s, java.lang.String s1, java.lang.String s2, java.sql.Connection connection)
    {
        java.lang.String s3 = "N";
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        java.lang.String s4 = "BEGIN :1 := BIS_PMV_UTIL.hasFunctionAccess(:2, :3, :4); END;";
        try
        {
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s4);
            oraclecallablestatement.registerOutParameter(1, 12, 0, 1);
            oraclecallablestatement.setString(2, s);
            oraclecallablestatement.setString(3, s1);
            oraclecallablestatement.setString(4, s2);
            oraclecallablestatement.execute();
            s3 = oraclecallablestatement.getString(1);
        }
        catch(java.lang.Exception _ex) { }
        finally
        {
            try
            {
                if(oraclecallablestatement != null)
                    oraclecallablestatement.close();
            }
            catch(java.lang.Exception _ex)
            {
                oraclecallablestatement = null;
            }
        }
        return s3;
    }

    public static int getFunctionId(java.lang.String s, java.sql.Connection connection)
    {
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        int i = 0x80000000;
        java.lang.String s1 = "SELECT FUNCTION_ID FROM FND_FORM_FUNCTIONS_VL WHERE FUNCTION_NAME=:1";
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
            catch(java.sql.SQLException _ex) { }
        }
        return i;
    }

    public static java.lang.String getDimName(java.lang.String s, java.sql.Connection connection)
    {
        java.lang.String s1 = " SELECT name FROM bis_dimensions_vl WHERE short_name = :1";
        java.lang.String s2 = "";
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        try
        {
            preparedstatement = connection.prepareStatement(s1);
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            oraclestatement.defineColumnType(1, 12, 80);
            preparedstatement.setString(1, s);
            resultset = preparedstatement.executeQuery();
            if(resultset.next())
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
        return s2;
    }

    public static com.sun.java.util.collections.ArrayList getFunctionInfo(java.lang.String s, java.lang.String s1, java.sql.Connection connection, oracle.apps.fnd.common.WebAppsContext webappscontext, oracle.apps.bis.msg.MessageLog messagelog, java.lang.String s2, java.lang.String s3)
    {
        oracle.apps.bis.pmv.relatedinfo.RelatedInfoHelper relatedinfohelper = new RelatedInfoHelper(s, s1, connection, webappscontext, messagelog, s2, s3);
        java.util.Vector vector = relatedinfohelper.getReportURLs();
        com.sun.java.util.collections.ArrayList arraylist = null;
        if(vector != null)
        {
            arraylist = new ArrayList(7);
            for(int i = 0; i < vector.size(); i++)
            {
                oracle.apps.bis.pmv.relatedinfo.RelatedInfo relatedinfo = (oracle.apps.bis.pmv.relatedinfo.RelatedInfo)vector.elementAt(i);
                oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(webappscontext);
                oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(relatedinfo.getLinkedFunctionId());
                arraylist.add(function.getFunctionName());
                arraylist.add(function.getUserFunctionName());
                arraylist.add(function.getParameters());
                arraylist.add(function.getWebHTMLCall());
            }

        }
        return arraylist;
    }

    public static com.sun.java.util.collections.ArrayList getFunctionInfo(int i, int j, java.sql.Connection connection)
    {
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        java.sql.ResultSet resultset1 = null;
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(7);
        java.lang.String s = "SELECT A.FUNCTION_NAME, A.USER_FUNCTION_NAME, A.PARAMETERS, A.WEB_HTML_CALL FROM FND_FORM_FUNCTIONS_VL A, BIS_RELATED_LINKS B WHERE A.FUNCTION_ID = B.LINKED_FUNCTION_ID AND B.FUNCTION_ID = :1 AND B.USER_ID = :2 AND B.LINK_TYPE = 'WWW' ORDER BY B.DISPLAY_SEQUENCE";
        try
        {
            preparedstatement = connection.prepareStatement(s);
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            oraclestatement.defineColumnType(1, 12, 480);
            oraclestatement.defineColumnType(2, 12, 80);
            oraclestatement.defineColumnType(3, 12, 2000);
            oraclestatement.defineColumnType(4, 12, 240);
            preparedstatement.setInt(1, i);
            preparedstatement.setInt(2, j);
            for(resultset = preparedstatement.executeQuery(); resultset.next(); arraylist.add(resultset.getString(4)))
            {
                arraylist.add(resultset.getString(1));
                arraylist.add(resultset.getString(2));
                arraylist.add(resultset.getString(3));
            }

            if(arraylist.size() == 0)
            {
                preparedstatement.setInt(1, i);
                preparedstatement.setInt(2, -1);
                for(resultset1 = preparedstatement.executeQuery(); resultset1.next(); arraylist.add(resultset1.getString(4)))
                {
                    arraylist.add(resultset1.getString(1));
                    arraylist.add(resultset1.getString(2));
                    arraylist.add(resultset1.getString(3));
                }

            }
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
                if(resultset1 != null)
                    resultset1.close();
            }
            catch(java.sql.SQLException _ex) { }
        }
        return arraylist;
    }

    public static oracle.apps.fnd.functionSecurity.Function getFunction(java.lang.String s, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        oracle.apps.fnd.functionSecurity.Function function = null;
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(webappscontext);
            function = functionsecurity.getFunction(s);
        }
        return function;
    }

    public static java.lang.String getPageFunctionName(java.lang.String s, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String s1 = "";
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && s.length() > 1)
        {
            long l = java.lang.Long.parseLong(s.substring(1));
            if(l > 0L)
            {
                oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(webappscontext);
                oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(l);
                if(function != null)
                    s1 = function.getFunctionName();
            }
        }
        return s1;
    }

    public static boolean isPMVReportFunction(java.lang.String s)
    {
        boolean flag = false;
        if(s != null && (s.trim().toLowerCase().startsWith("bisviewer.showreport") || s.trim().startsWith("OA.jsp?page=/oracle/apps/bis/report/webui/BISReportPG")))
            flag = true;
        return flag;
    }

    public static boolean isPMVPageFunction(java.lang.String s)
    {
        boolean flag = false;
        if(s != null && s.trim().startsWith("OA.jsp?akRegionCode=BIS_COMPONENT_PAGE"))
            flag = true;
        return flag;
    }

    public static java.lang.String getSessionId(java.sql.Connection connection, java.lang.String s)
        throws oracle.apps.bis.pmv.PMVException
    {
        java.lang.String s1 = null;
        java.lang.String s2 = "select bis_notification_id_s.nextval from dual";
        java.sql.CallableStatement callablestatement = null;
        java.sql.ResultSet resultset = null;
        try
        {
            callablestatement = connection.prepareCall(s2);
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)callablestatement;
            oraclestatement.defineColumnType(1, 12, 30);
            resultset = callablestatement.executeQuery();
            if(resultset.next())
                s1 = s + "_" + resultset.getString(1);
        }
        catch(java.sql.SQLException sqlexception)
        {
            throw new PMVException(sqlexception.getMessage());
        }
        finally
        {
            try
            {
                if(callablestatement != null)
                    callablestatement.close();
                if(resultset != null)
                    resultset.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        return s1;
    }

    public static java.lang.String getLastRefreshDateString(java.lang.String s, java.sql.Connection connection, java.lang.String s1)
    {
        java.lang.String s2 = "";
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        java.lang.String s3 = "BEGIN :1 := BIS_PMV_UTIL.GET_LAST_REFRESH_DATE_URL(:2,:3); END;";
        try
        {
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s3);
            oraclecallablestatement.registerOutParameter(1, 12, 0, 1000);
            oraclecallablestatement.setString(2, s1);
            oraclecallablestatement.setString(3, s);
            oraclecallablestatement.execute();
            java.lang.String s4 = oraclecallablestatement.getString(1);
            s2 = s4 != null ? s4 : "";
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
        return s2.toString();
    }

    public static void saveDefaultParameters(java.sql.Connection connection, java.lang.String s, java.lang.String s1, java.lang.String s2)
    {
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        java.lang.String s3 = "  BEGIN BIS_PMV_PARAMETERS_PVT.COPY_SES_TO_DEF_PARAMETERS(:1,:2,:3,:4,:5,:6); END; ";
        try
        {
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s3);
            oraclecallablestatement.setString(1, s);
            oraclecallablestatement.setString(2, s1);
            oraclecallablestatement.setString(3, s2);
            oraclecallablestatement.registerOutParameter(4, 12, 0, 1);
            oraclecallablestatement.registerOutParameter(5, 4, 0, 2);
            oraclecallablestatement.registerOutParameter(6, 12, 0, 300);
            oraclecallablestatement.execute();
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(oraclecallablestatement != null)
                    oraclecallablestatement.close();
            }
            catch(java.sql.SQLException _ex)
            {
                oraclecallablestatement = null;
            }
        }
    }

    public static java.lang.String getReportRegion(java.lang.String s, java.lang.String s1)
    {
        java.lang.String s2 = "";
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            int i = s.indexOf("'");
            if(i > 0)
            {
                int j = s.indexOf("'", i + 1);
                s2 = s.substring(i + 1, j);
            }
        }
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
            s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s1, "pRegionCode");
        return s2;
    }

    public static boolean isRLPortletCustomized(int i, java.lang.String s, java.sql.Connection connection)
    {
        java.lang.String s1 = "SELECT USER_ID FROM BIS_SCHEDULE_PREFERENCES WHERE PLUG_ID=:1 AND USER_ID=:2";
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        boolean flag = false;
        try
        {
            preparedstatement = connection.prepareStatement(s1);
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            oraclestatement.defineColumnType(1, 4);
            preparedstatement.setString(1, s);
            preparedstatement.setInt(2, i);
            resultset = preparedstatement.executeQuery();
            if(resultset.next())
            {
                java.lang.String s2 = resultset.getString(1);
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
                    flag = true;
            }
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
            catch(java.lang.Exception _ex)
            {
                Object obj = null;
                Object obj1 = null;
            }
        }
        return flag;
    }

    public static boolean chkForDependencies(java.lang.String s, oracle.apps.bis.pmv.parameters.ParamAssociation paramassociation, com.sun.java.util.collections.ArrayList arraylist)
    {
        boolean flag = false;
        if("Y".equals(s))
        {
            if(paramassociation != null && arraylist != null)
            {
                java.lang.StringBuffer stringbuffer = new StringBuffer(100);
                stringbuffer.append("{");
                stringbuffer.append(paramassociation.getSelectedAttrCode());
                stringbuffer.append("}");
                Object obj = null;
                for(int i = 0; i < arraylist.size(); i++)
                {
                    oracle.apps.bis.pmv.parameters.ParamAssociation paramassociation1 = (oracle.apps.bis.pmv.parameters.ParamAssociation)arraylist.get(i);
                    java.lang.String s1 = paramassociation1.getLovWhere();
                    if(s1 != null && stringbuffer != null)
                    {
                        if(s1.indexOf(stringbuffer.toString()) > 0)
                            flag = true;
                    } else
                    {
                        flag = false;
                    }
                }

            }
        } else
        {
            flag = false;
        }
        return flag;
    }

    public static boolean chkForDependencies(oracle.apps.bis.pmv.metadata.AKRegion akregion, java.lang.String s)
    {
        boolean flag = false;
        try
        {
            if(s != null)
            {
                java.util.Hashtable hashtable = akregion.getAKRegionItems();
                java.util.Enumeration enumeration = hashtable.keys();
                Object obj = null;
                com.sun.java.util.collections.HashMap hashmap = new HashMap();
                java.lang.StringBuffer stringbuffer = new StringBuffer(20);
                Object obj1 = null;
                while(enumeration.hasMoreElements())
                {
                    java.lang.String s1 = (java.lang.String)enumeration.nextElement();
                    oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)hashtable.get(s1);
                    hashmap.put(akregionitem.getAttributeCode(), akregionitem.getLovWhereClause());
                    if(s.equals(s1))
                    {
                        stringbuffer.append("{");
                        stringbuffer.append(akregionitem.getAttributeCode());
                        stringbuffer.append("}");
                    }
                }
                if(hashmap != null && !"".equals(stringbuffer.toString()))
                {
                    com.sun.java.util.collections.Set set = hashmap.keySet();
                    com.sun.java.util.collections.Iterator iterator = set.iterator();
                    Object obj2 = null;
                    Object obj3 = null;
                    while(iterator.hasNext())
                    {
                        java.lang.String s3 = (java.lang.String)iterator.next();
                        java.lang.String s2 = (java.lang.String)hashmap.get(s3);
                        if(s2 != null && s2.indexOf(stringbuffer.toString()) > 0)
                            flag = true;
                    }
                }
            }
        }
        catch(java.lang.Exception _ex)
        {
            flag = false;
        }
        return flag;
    }

    public static java.lang.String getDoubleQuoteEscapedHTML(java.lang.String s)
    {
        java.lang.String s1 = "";
        if(s != null)
            s1 = oracle.apps.bis.pmv.common.StringUtil.replaceAll(s, "\"", "&quot;");
        return s1;
    }

    public static void populateNLSInfo(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String s = webappscontext.getNLSLanguage();
        java.lang.String s1 = webappscontext.getLangCode(s);
        webappscontext.setCurrLang(s1);
        webappscontext.setDateFormat(webappscontext.getProfileStore().getProfile("ICX_DATE_FORMAT_MASK"));
    }

    public static java.lang.String getParameterPortletFunctionName(java.lang.String s, java.sql.Connection connection)
    {
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        java.lang.String s1 = null;
        try
        {
            java.lang.String s2 = "BEGIN :1 := BIS_PMV_UTIL.getParamPortletFuncName(:2); END;";
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s2);
            oraclecallablestatement.registerOutParameter(1, 12, 0, 480);
            oraclecallablestatement.setString(2, s);
            oraclecallablestatement.execute();
            s1 = oraclecallablestatement.getString(1);
        }
        catch(java.lang.Exception _ex)
        {
            s1 = null;
        }
        finally
        {
            if(oraclecallablestatement != null)
                try
                {
                    oraclecallablestatement.close();
                }
                catch(java.lang.Exception _ex)
                {
                    oraclecallablestatement = null;
                }
        }
        return s1;
    }

    public static void saveHTML(java.lang.String s, java.sql.Connection connection, java.lang.String s1)
    {
        byte abyte0[] = new byte[0xf423f];
        int i = 0;
        for(int j = 0; j < s.length(); j++)
        {
            abyte0[i] = (byte)s.charAt(j);
            i++;
        }

        od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFileId(connection, s1);
        i++;
        byte abyte1[] = new byte[i];
        for(int k = 0; k < i; k++)
            abyte1[k] = abyte0[k];

    }

    public static void saveReportToDb(java.lang.String s, boolean flag, java.lang.String s1, java.sql.Connection connection, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        int i = s1.length();
        boolean flag1 = false;
        char c = '\u7D00';
        java.lang.String s2 = webappscontext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        java.lang.String s3 = "";
        if(i < c)
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
                od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.saveReport(abyte0, java.lang.String.valueOf(j), connection, s);
                return;
            } else
            {
                od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.appendReport(abyte0, java.lang.String.valueOf(j), connection, s);
                return;
            }
        }
        int l = i / c;
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(11);
        int i1 = c;
        int j1 = 0;
        for(int k1 = 0; k1 < l; k1++)
        {
            java.lang.String s4 = s1.substring(j1, i1);
            j1 += c;
            i1 += c;
            arraylist.add(s4);
        }

        if(i1 - c < i)
            arraylist.add(s1.substring(i1 - c, i));
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
                    od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.saveReport(abyte1, java.lang.String.valueOf(k), connection, s);
                else
                    od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.appendReport(abyte1, java.lang.String.valueOf(k), connection, s);
            } else
            {
                od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.appendReport(abyte1, java.lang.String.valueOf(k), connection, s);
            }
        }

    }

    public static void saveReport(byte abyte0[], java.lang.String s, java.sql.Connection connection, java.lang.String s1)
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

    public static void appendReport(byte abyte0[], java.lang.String s, java.sql.Connection connection, java.lang.String s1)
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

    public static java.lang.String getFileId(java.sql.Connection connection, java.lang.String s)
    {
        java.lang.String s1 = "BEGIN :1 := BIS_RG_SCHEDULES_PVT.GET_FILE_ID(:2); END;";
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        java.lang.String s2 = null;
        try
        {
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s1);
            oraclecallablestatement.registerOutParameter(1, 12, 0, 300);
            if("PDF".equals(s))
                oraclecallablestatement.setString(2, "PDF");
            else
                oraclecallablestatement.setString(2, "R");
            oraclecallablestatement.execute();
            s2 = oraclecallablestatement.getString(1);
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(oraclecallablestatement != null)
                    oraclecallablestatement.close();
            }
            catch(java.sql.SQLException _ex) { }
        }
        return s2;
    }

    public static void sendToMultipleRecipients(java.sql.Connection connection, java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, com.sun.java.util.collections.ArrayList arraylist)
    {
        for(int i = 0; i < arraylist.size(); i++)
            if(arraylist.get(i) != null && !"".equals(arraylist.get(i)))
            {
                java.lang.String s4 = arraylist.get(i).toString();
                od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.sendNotifications(connection, s, s1, s2, s4, s3);
            }

    }

    public static void sendNotifications(java.sql.Connection connection, java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4)
    {
        java.lang.String s5 = "BEGIN BIS_RG_SEND_NOTIFICATIONS_PVT.SEND_NOTIFICATION(:1,:2,:3, :4, :5); END;";
        java.sql.CallableStatement callablestatement = null;
        try
        {
            callablestatement = connection.prepareCall(s5);
            callablestatement.setString(1, s);
            callablestatement.setString(2, s1);
            callablestatement.setNull(3, 12);
            if(s3 != null && s3.length() > 0)
                callablestatement.setString(4, s3);
            else
                callablestatement.setNull(4, 12);
            if(s4 != null)
                callablestatement.setString(5, s4);
            else
                callablestatement.setNull(5, 12);
            callablestatement.execute();
            connection.commit();
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

    public static java.lang.String getAttr2FromAttrCode(oracle.apps.bis.pmv.metadata.AKRegion akregion, java.lang.String s)
    {
        java.lang.String s1 = null;
        if(akregion != null)
        {
            java.util.Hashtable hashtable = akregion.getAKRegionItems();
            if(hashtable != null)
            {
                java.util.Enumeration enumeration = hashtable.keys();
                Object obj = null;
                while(enumeration.hasMoreElements())
                {
                    oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)hashtable.get(enumeration.nextElement());
                    if(akregionitem != null && s != null && s.equals(akregionitem.getAttributeCode()))
                    {
                        s1 = akregionitem.getAttribute2();
                        break;
                    }
                }
            }
        }
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
            s1 = s;
        return s1;
    }

    public static java.lang.String getAttr2FromAttrCode(oracle.apps.bis.pmv.metadata.AKRegion akregion, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection, java.lang.String s, java.lang.String s1)
    {
        java.lang.String s2 = null;
        if(akregion != null)
            s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getAttr2FromAttrCode(akregion, s1);
        else
            try
            {
                oracle.apps.bis.pmv.metadata.AKRegion akregion1 = oracle.apps.bis.common.Util.getAKRegion(s, webappscontext, connection);
                s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getAttr2FromAttrCode(akregion1, s1);
            }
            catch(java.lang.Exception _ex) { }
        return s2;
    }

    public static java.lang.String getEncryptedString(java.sql.Connection connection, java.lang.String s)
    {
        java.lang.String s1 = "BEGIN :1 := icx_call.encrypt(:2); END; ";
        oracle.jdbc.driver.OracleCallableStatement oraclecallablestatement = null;
        java.lang.String s2 = null;
        try
        {
            oraclecallablestatement = (oracle.jdbc.driver.OracleCallableStatement)connection.prepareCall(s1);
            oraclecallablestatement.setString(2, s);
            oraclecallablestatement.registerOutParameter(1, 12, 0, 2000);
            oraclecallablestatement.execute();
            s2 = oraclecallablestatement.getString(1);
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(oraclecallablestatement != null)
                    oraclecallablestatement.close();
            }
            catch(java.sql.SQLException _ex) { }
        }
        return s2;
    }

    public static int getReadingDirectionForLocale(java.lang.String s)
    {
        return "AR".equals(s) || "HE".equals(s) || "IW".equals(s) ? 2 : 1;
    }

    public static boolean isParamBookMarked()
    {
        return true;
    }

    public static java.lang.String getAttrCodeFromAttr2(oracle.apps.bis.pmv.metadata.AKRegion akregion, java.lang.String s)
    {
        java.lang.String s1 = null;
        if(akregion != null && s != null)
        {
            java.util.Hashtable hashtable = akregion.getAKRegionItems();
            if(hashtable != null)
            {
                java.util.Enumeration enumeration = hashtable.keys();
                Object obj = null;
                while(enumeration.hasMoreElements())
                {
                    oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)hashtable.get(enumeration.nextElement());
                    if(akregionitem != null && s.equals(akregionitem.getAttribute2()))
                    {
                        s1 = akregionitem.getAttributeCode();
                        break;
                    }
                }
            }
        }
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
            s1 = s;
        return s1;
    }

    public static java.lang.String removeSpaces(java.lang.String s)
    {
        java.util.StringTokenizer stringtokenizer = new StringTokenizer(s, " ", false);
        java.lang.String s1;
        for(s1 = ""; stringtokenizer.hasMoreElements(); s1 = s1 + stringtokenizer.nextElement());
        return s1;
    }

    public static java.lang.String getUserId(java.lang.String s, java.sql.Connection connection)
    {
        java.lang.String s1 = "SELECT USER_ID FROM FND_USER WHERE USER_NAME=:1";
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        int i = -1;
        try
        {
            preparedstatement = connection.prepareStatement(s1);
            preparedstatement.setString(1, s);
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            oraclestatement.defineColumnType(1, 2);
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
            catch(java.lang.Exception _ex)
            {
                Object obj = null;
                Object obj1 = null;
            }
        }
        return java.lang.String.valueOf(i);
    }

    public static java.lang.String getResponsibilityId(java.lang.String s, java.sql.Connection connection)
    {
        java.lang.String s1 = "SELECT RESPONSIBILITY_ID FROM FND_RESPONSIBILITY WHERE RESPONSIBILITY_KEY=:1";
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        int i = -1;
        try
        {
            preparedstatement = connection.prepareStatement(s1);
            preparedstatement.setString(1, s);
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            oraclestatement.defineColumnType(1, 2);
            resultset = preparedstatement.executeQuery();
            if(resultset.next())
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
            catch(java.lang.Exception _ex)
            {
                Object obj = null;
                Object obj1 = null;
            }
        }
        return java.lang.String.valueOf(i);
    }

    public static com.sun.java.util.collections.Map getParameters(java.lang.String s)
    {
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
            return null;
        com.sun.java.util.collections.HashMap hashmap = new HashMap(7);
        java.util.StringTokenizer stringtokenizer = new StringTokenizer(s, "&");
        Object obj = null;
        Object obj1 = null;
        while(stringtokenizer.hasMoreTokens())
        {
            java.lang.String s3 = stringtokenizer.nextToken();
            int i = s3.indexOf('=');
            s3.length();
            if(i >= 0)
            {
                java.lang.String s1 = s3.substring(0, i);
                java.lang.String s2 = s3.substring(i + 1);
                hashmap.put(s1, s2);
            }
        }
        return hashmap;
    }

    public static java.lang.String[] getParamValuesFromSession(oracle.apps.bis.pmv.session.UserSession usersession, int i)
    {
        java.lang.String s = (java.lang.String)oracle.apps.bis.common.ServletWrapper.getSessionValue(usersession.getPageContext(), "pmvV" + usersession.getFunctionName());
        java.lang.String as[] = new java.lang.String[i];
        java.lang.String s1 = usersession.getWebAppsContext().getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        java.util.StringTokenizer stringtokenizer = new StringTokenizer(s, "&");
        Object obj = null;
        int j = 0;
        while(stringtokenizer.hasMoreTokens())
        {
            java.lang.String s3 = stringtokenizer.nextToken();
            if(s3 != null && s3.startsWith("pmvV="))
            {
                int k = s3.indexOf('=');
                s3.length();
                if(k >= 0)
                {
                    java.lang.String s2 = s3.substring(0, k);
                    if("pmvV".equals(s2))
                        try
                        {
                            as[j] = oracle.cabo.share.url.EncoderUtils.decodeString(s3.substring(k + 1), s1);
                            j++;
                        }
                        catch(java.lang.Exception _ex) { }
                }
            }
        }
        return as;
    }

    public static java.lang.String processpParameters(java.lang.String s)
    {
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
            return "";
        s = s.replace('~', '&');
        s = s.replace('@', '=');
        s = s.replace('^', '+');
        char ac[] = s.toCharArray();
        for(int j = 0; j < s.length(); j++)
        {
            int i = s.indexOf("\"", j);
            if(i >= 0)
                ac[i] = '\'';
        }

        java.lang.String s1 = new String(ac);
        return s1;
    }

    public static com.sun.java.util.collections.Map getURLParameters(java.lang.String s)
    {
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
            return null;
        com.sun.java.util.collections.HashMap hashmap = new HashMap(7);
        int i = 0;
        int i1 = s.length();
        Object obj = null;
        Object obj1 = null;
        try
        {
            for(int j1 = 0; j1 < 100; j1++)
            {
                if(s.indexOf('&', i) < 0 || s.indexOf('=', i) < 0)
                    break;
                if(i != 0)
                    i++;
                int j = s.indexOf('=', i);
                int l = s.indexOf('=', j + 1);
                int k;
                if(l > 0)
                    k = s.lastIndexOf('&', l);
                else
                    k = i1;
                java.lang.String s1 = s.substring(i, j);
                java.lang.String s2 = s.substring(j + 1, k);
                if(s1 != null && s2 != null)
                    hashmap.put(s1, s2);
                if(k >= i1)
                    break;
                i = k;
            }

        }
        catch(java.lang.Exception _ex) { }
        return hashmap;
    }

    public static java.lang.String getParameter(javax.servlet.jsp.PageContext pagecontext, javax.servlet.http.HttpServletRequest httpservletrequest, java.lang.String s)
    {
        java.lang.String s1 = null;
        if(pagecontext != null)
            s1 = oracle.apps.bis.common.ServletWrapper.getParameter(pagecontext, s);
        else
        if(httpservletrequest != null)
            s1 = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, s);
        return s1;
    }

    public static java.lang.String getDynamicParamLabel(java.lang.String s, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        if(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.isDynamicLabel(s))
        {
            java.lang.String s1 = oracle.apps.bis.pmv.query.Calculation.getDynamicLabel(null, s, usersession, usersession.getConnection());
            if(s1 != null && s1.length() > 0)
                return s1;
        }
        return s;
    }

    public static java.lang.String getScheduleId(java.sql.Connection connection, java.lang.String s, java.lang.String s1)
    {
        java.lang.String s2 = "select s.schedule_id from bis_scheduler s , bis_Schedule_preferences sp where sp.user_id=:1 and sp.plug_id = :2 and sp.schedule_id = s.schedule_id";
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        java.lang.String s3 = "";
        try
        {
            preparedstatement = connection.prepareStatement(s2);
            preparedstatement.setString(1, s);
            preparedstatement.setString(2, s1);
            resultset = preparedstatement.executeQuery();
            if(resultset.next())
                s3 = resultset.getString(1);
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
        return s3;
    }

    public static boolean isPieGraph(java.lang.String s)
    {
        boolean flag = false;
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && java.lang.Integer.parseInt(s) >= 55 && java.lang.Integer.parseInt(s) <= 60)
            flag = true;
        return flag;
    }

    public static java.util.Hashtable getFormFxnDefParams(java.lang.String s, oracle.apps.bis.pmv.metadata.AKRegion akregion, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection)
    {
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(webappscontext);
            java.lang.String s1 = null;
            oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(s);
            if(function != null)
                s1 = function.getParameters();
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
            {
                java.lang.String s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getUrlParamValue(s1, "pParameters");
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
                {
                    java.lang.String s3 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.processpParameters(s2);
                    java.util.Hashtable hashtable = oracle.apps.bis.pmv.portlet.Portlet.getParameterHashTable(s3, akregion.getRegionCode(), connection, akregion, webappscontext);
                    java.lang.String s4 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getUrlParamValue(s3, "pParamIds");
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s4) && hashtable != null)
                        hashtable.put("pParamIds", s4);
                    return hashtable;
                }
            }
        }
        return null;
    }

    public static java.util.Hashtable getPortletFormFxnDefParams(java.lang.String s, oracle.apps.bis.pmv.metadata.AKRegion akregion, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection)
    {
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(webappscontext);
            java.lang.String s1 = null;
            oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(s);
            if(function != null)
                s1 = function.getParameters();
            s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.buildFrmFxnParameters(s1, connection);
            java.util.Hashtable hashtable = oracle.apps.bis.pmv.portlet.Portlet.getParameterHashTable(s1, akregion.getRegionCode(), connection, akregion, webappscontext);
            java.lang.String s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getUrlParamValue(s1, "pParamIds");
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2) && hashtable != null)
                hashtable.put("pParamIds", s2);
            return hashtable;
        } else
        {
            return null;
        }
    }

    public static boolean isDropDownParameter(oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem, java.lang.String s)
    {
        boolean flag = true;
        if(akregionitem != null)
            if("L".equals(akregionitem.getParameterRenderType()))
                flag = false;
            else
            if("D".equals(akregionitem.getParameterRenderType()) || "M".equals(akregionitem.getParameterRenderType()))
                flag = true;
            else
            if(akregionitem.isNestedRegionItem() || "P".equals(s))
                flag = true;
            else
                flag = false;
        return flag;
    }

    public static java.lang.String getUserName(java.lang.String s, java.sql.Connection connection)
    {
        java.lang.String s1 = "SELECT USER_NAME FROM FND_USER WHERE USER_ID=:1";
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        java.lang.String s2 = "";
        try
        {
            preparedstatement = connection.prepareStatement(s1);
            preparedstatement.setString(1, s);
            oracle.jdbc.driver.OracleStatement _tmp = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            for(resultset = preparedstatement.executeQuery(); resultset.next();)
                s2 = resultset.getString(1);

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
            catch(java.lang.Exception _ex)
            {
                Object obj = null;
                Object obj1 = null;
            }
        }
        return s2;
    }

    public static boolean isAutoGenFromDesigner(oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        boolean flag = false;
        if(akregion != null && (akregion instanceof oracle.apps.bis.pmv.metadata.ReportDesignerRegion) && "BSC_DATA_SOURCE".equals(akregion.getDataSource()))
            flag = true;
        return flag;
    }

    public static com.sun.java.util.collections.Map getThemeMap(java.lang.String s)
    {
        com.sun.java.util.collections.HashMap hashmap = new HashMap(1);
        if(s != null)
        {
            java.util.StringTokenizer stringtokenizer = new StringTokenizer(s, "&");
            Object obj = null;
            Object obj1 = null;
            while(stringtokenizer.hasMoreTokens())
            {
                java.lang.String s3 = stringtokenizer.nextToken();
                int i = s3.indexOf('=');
                s3.length();
                if(i >= 0)
                {
                    java.lang.String s1 = s3.substring(0, i);
                    java.lang.String s2 = s3.substring(i + 1);
                    hashmap.put(s1, s2);
                }
            }
        }
        return hashmap;
    }

    public static java.lang.String[] getFirstRespForFunc(java.lang.String s, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String as[] = null;
        long l = -1L;
        long l1 = -1L;
        long l2 = 0L;
        oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(webappscontext);
        oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(s);
        oracle.apps.fnd.functionSecurity.User user = functionsecurity.getUser(webappscontext.getUserId());
        oracle.apps.fnd.functionSecurity.Resp aresp[] = functionsecurity.getUserResps(user);
        boolean flag = false;
        for(int i = 0; i < aresp.length && !flag; i++)
        {
            oracle.apps.fnd.functionSecurity.SecurityGroup securitygroup = aresp[i].getSecurityGroup();
            if(functionsecurity.testFunction(function, user, aresp[i], securitygroup))
            {
                l = aresp[i].getRespID();
                l1 = aresp[i].getRespApplID();
                if(securitygroup != null)
                    l2 = securitygroup.getSecurityGroupID();
                flag = true;
            }
        }

        if(flag)
        {
            as = new java.lang.String[3];
            as[0] = java.lang.String.valueOf(l);
            as[1] = java.lang.String.valueOf(l1);
            as[2] = java.lang.String.valueOf(l2);
        }
        return as;
    }

    public static java.lang.String getErrorMessage(java.lang.String s, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String s1 = "";
        java.lang.String as[] = oracle.apps.bis.pmv.common.StringUtil.tokenize(s, ";");
        for(int i = 0; i < as.length; i++)
            s1 = s1 + oracle.apps.bis.common.Util.getErrorMessage(as[i], webappscontext);

        return s1;
    }

    public static java.lang.String getOAMacUrl(java.lang.String s, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        if(webappscontext == null)
            return s;
        byte abyte0[] = webappscontext.getMacKey();
        if(abyte0 == null || abyte0.length < 16)
        {
            return s;
        } else
        {
            oracle.apps.fnd.security.HMAC hmac = new HMAC(0);
            hmac.setKey(abyte0);
            return oracle.apps.fnd.framework.webui.URLMgr.processOutgoingURL(s.toString(), hmac);
        }
    }

    public static java.lang.String constructReportURL(java.lang.String s)
    {
        com.sun.java.util.collections.Map map = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameters(s);
        java.lang.StringBuffer stringbuffer = new StringBuffer("");
        if(map != null && map.size() > 0)
        {
            java.lang.String s1;
            java.lang.String s2;
            for(com.sun.java.util.collections.Iterator iterator = map.keySet().iterator(); iterator.hasNext(); stringbuffer.append("&").append(s2).append("=").append(map.get(s1)))
            {
                s1 = (java.lang.String)iterator.next();
                s2 = (java.lang.String)_reportURLParamMapping.get(s1);
                if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
                    s2 = s1;
            }

        }
        return stringbuffer.toString();
    }

    public static boolean checkIfExtraViewByExists(java.lang.String s, oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        boolean flag = false;
        try
        {
            java.lang.String s1 = s.substring(0, s.indexOf("-"));
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
            {
                java.lang.String s2 = s.substring(s.indexOf("-") + 1);
                if(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.checkIfViewByExists(s1, akregion) && od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.checkIfViewByExists(s2, akregion))
                    flag = true;
            }
        }
        catch(java.lang.Exception _ex)
        {
            flag = false;
        }
        return flag;
    }

    public static boolean checkIfViewByExists(java.lang.String s, oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        boolean flag = false;
        try
        {
            com.sun.java.util.collections.HashMap hashmap = akregion.getViewBys();
            if(hashmap != null && !hashmap.isEmpty() && hashmap.containsKey(s))
                flag = true;
        }
        catch(java.lang.Exception _ex)
        {
            flag = false;
        }
        return flag;
    }

    public static java.lang.String getRegionCodeFromFunctionName(java.lang.String s, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String s1 = null;
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(webappscontext);
            java.lang.String s2 = null;
            java.lang.String s3 = null;
            oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(s);
            if(function != null)
            {
                s2 = function.getParameters();
                s3 = function.getWebHTMLCall();
            }
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
                s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getUrlParamValue(s2, "pRegionCode");
            else
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s3) || oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
            {
                java.lang.String s4 = s3.substring(s3.indexOf("'") + 1);
                s1 = s4.substring(0, s4.indexOf("'"));
            }
        }
        return s1;
    }

    public static int getRegionApplId(java.lang.String s, java.sql.Connection connection)
    {
        int i = -1;
        oracle.jdbc.driver.OraclePreparedStatement oraclepreparedstatement = null;
        java.sql.ResultSet resultset = null;
        if(s != null)
            try
            {
                oraclepreparedstatement = (oracle.jdbc.driver.OraclePreparedStatement)connection.prepareStatement(" SELECT region_application_id FROM ak_regions WHERE region_code = :1 ");
                oraclepreparedstatement.defineColumnType(1, 2, 10);
                oraclepreparedstatement.setString(1, s);
                resultset = oraclepreparedstatement.executeQuery();
                if(resultset.next())
                    i = resultset.getInt(1);
            }
            catch(java.lang.Exception _ex)
            {
                i = -1;
            }
            finally
            {
                try
                {
                    if(resultset != null)
                        resultset.close();
                    if(oraclepreparedstatement != null)
                        oraclepreparedstatement.close();
                }
                catch(java.lang.Exception _ex) { }
            }
        return i;
    }

    public static java.lang.String removeUrlParameter(java.lang.String s, java.lang.String s1)
    {
        if(s.indexOf(s1) > 0)
        {
            java.lang.String s2 = s.substring(0, s.indexOf(s1));
            java.lang.String s3 = s.substring(s.indexOf(s1) + 1);
            java.lang.String s4 = s3.substring(s3.indexOf("&"));
            java.lang.String s5 = s2 + s4;
            return s5;
        } else
        {
            return s;
        }
    }

    public static java.lang.String getLabelFromAttrCode(oracle.apps.bis.pmv.metadata.AKRegion akregion, java.lang.String s)
    {
        java.lang.String s1 = null;
        if(akregion != null && s != null)
        {
            java.util.Hashtable hashtable = akregion.getAKRegionItems();
            if(hashtable != null)
            {
                java.util.Enumeration enumeration = hashtable.keys();
                Object obj = null;
                while(enumeration.hasMoreElements())
                {
                    oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)hashtable.get(enumeration.nextElement());
                    if(akregionitem != null && s.equals(akregionitem.getAttributeCode()))
                    {
                        s1 = akregionitem.getAttributeNameLong();
                        break;
                    }
                }
            }
        }
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
            s1 = s;
        return s1;
    }

    public static boolean isAKRegionOracleDelivered(java.sql.Connection connection, java.lang.String s)
    {
        boolean flag = false;
        oracle.jdbc.driver.OraclePreparedStatement oraclepreparedstatement = null;
        java.sql.ResultSet resultset = null;
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
            try
            {
                oraclepreparedstatement = (oracle.jdbc.driver.OraclePreparedStatement)connection.prepareStatement("Select created_by from ak_regions where region_code = :1");
                oraclepreparedstatement.defineColumnType(1, 2);
                oraclepreparedstatement.setString(1, s);
                resultset = oraclepreparedstatement.executeQuery();
                if(resultset.next())
                {
                    long l = resultset.getLong(1);
                    flag = l == 1L || l == 2L;
                }
            }
            catch(java.lang.Exception _ex)
            {
                flag = false;
            }
            finally
            {
                try
                {
                    if(resultset != null)
                        resultset.close();
                    if(oraclepreparedstatement != null)
                        oraclepreparedstatement.close();
                }
                catch(java.lang.Exception _ex) { }
            }
        return flag;
    }

    public static java.lang.String getpParameters(oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity, java.lang.String s)
    {
        if(functionsecurity == null || oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
            return "";
        java.lang.String s1 = "";
        oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(s);
        if(function == null)
            return "";
        java.lang.String s2 = oracle.apps.bis.pmv.common.StringUtil.nonNull(function.getParameters());
        int i = s2.indexOf("pParameters");
        if(i >= 0)
        {
            int j = s2.indexOf("&", i);
            if(j < i)
                j = s2.length();
            s1 = s2.substring(i, j);
        }
        return s1;
    }

    public static java.lang.String getDisplayFlag(oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem, java.lang.String s)
    {
        if(akregionitem.getMeasureProperties() != null && akregionitem.getMeasureProperties().isWeightedAverage())
        {
            if("Y".equals(akregionitem.getDisplayFlag()) && oracle.apps.bis.pmv.data.PMVWeightAverageManager.isScoreByMatched(akregionitem, s))
                return "Y";
            else
                return "N";
        } else
        {
            return akregionitem.getDisplayFlag();
        }
    }

    public static java.lang.String[] getDefaultSortInfo(oracle.apps.bis.pmv.metadata.AKRegion akregion, oracle.apps.bis.pmv.parameters.ParameterHelper parameterhelper)
    {
        if(akregion == null || parameterhelper == null)
            return (new java.lang.String[] {
                "", ""
            });
        java.lang.String s = "";
        java.lang.String s1 = "";
        java.lang.String s2 = "";
        java.lang.String s3 = "";
        java.lang.String s4 = "";
        boolean flag = false;
        java.lang.String as[] = new java.lang.String[3];
        com.sun.java.util.collections.ArrayList arraylist = akregion.getDisplayColumns();
        boolean flag1 = false;
        java.lang.String s5 = parameterhelper.getViewbyValue();
        com.sun.java.util.collections.ArrayList arraylist1 = new ArrayList(3);
        for(int i = 0; i < arraylist.size(); i++)
        {
            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist.get(i);
            java.lang.String s6 = akregionitem.getOrderSequence();
            if(i == 0)
            {
                s2 = akregionitem.getAttributeCode();
                s3 = akregionitem.getOrderDirection();
                s4 = s6;
                flag = akregionitem.isCalculation();
            }
            if(s6 != null && !s6.equals("") && java.lang.Integer.parseInt(s6) == 1)
            {
                flag1 = true;
                s = akregionitem.getAttributeCode();
                s1 = akregionitem.getOrderDirection();
            }
            try
            {
                if(!"Y".equals(akregionitem.getNodeQueryFlag()) && !akregionitem.isNestedRegionItem() && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s6))
                {
                    int j = java.lang.Integer.parseInt(s6);
                    if(j < 100)
                        arraylist1.add(akregionitem.getAttributeCode());
                }
            }
            catch(java.lang.Exception _ex) { }
            if(flag1 && arraylist1.size() > 1)
                break;
        }

        if(!flag1 || oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeParameter(s5, akregion))
            if(akregion.getDisableViewBy().equals("Y"))
            {
                if(s4 != null && (s4.equals("") || java.lang.Integer.parseInt(s4) < 100) && !flag)
                {
                    s = s2;
                    s1 = s3;
                }
            } else
            {
                s = "VIEWBY";
                oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem1 = null;
                if(akregion.getAKRegionItems() != null)
                    akregionitem1 = (oracle.apps.bis.pmv.metadata.AKRegionItem)akregion.getAKRegionItems().get(s5);
                if(akregionitem1 != null && !oracle.apps.bis.pmv.common.StringUtil.emptyString(akregionitem1.getOrderDirection()))
                    s1 = akregionitem1.getOrderDirection();
                else
                if(akregion.isBscSQL())
                    s1 = "ASC";
                else
                if(oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeParameter(s5, akregion))
                    s1 = "DESC";
                else
                    s1 = "ASC";
            }
        as[0] = s;
        as[1] = s1;
        if(arraylist1 != null && arraylist1.size() > 1)
            as[2] = "true";
        else
            as[2] = "false";
        return as;
    }

    public static java.lang.String getInfoTip(oracle.apps.bis.pmv.session.UserSession usersession, oracle.apps.bis.pmv.parameters.ParameterHelper parameterhelper)
    {
        java.lang.String s = new String();
        java.lang.String s2 = new String();
        java.lang.StringBuffer stringbuffer = new StringBuffer(50);
        java.lang.String s4 = new String();
        try
        {
            com.sun.java.util.collections.ArrayList arraylist = usersession.getAKRegion().getInfoTips();
            java.lang.String s3;
            for(com.sun.java.util.collections.Iterator iterator = arraylist.iterator(); iterator.hasNext(); stringbuffer.append(s3))
            {
                oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)iterator.next();
                java.lang.String s1 = akregionitem.getAttributeNameLong();
                s3 = oracle.apps.bis.pmv.query.Calculation.getDynamicLabel(parameterhelper, s1, usersession, usersession.getConnection());
            }

            s4 = stringbuffer.toString();
        }
        catch(java.lang.Exception _ex) { }
        return s4;
    }

    public static java.lang.String getTranslatedPeriodType(java.lang.String s)
    {
        if("FII_ROLLING_QTR".equals(s))
            return "FII_TIME_ENT_QTR";
        if("FII_ROLLING_WEEK".equals(s))
            return "FII_TIME_WEEK";
        if("FII_ROLLING_MONTH".equals(s))
            return "FII_TIME_ENT_PERIOD";
        if("FII_ROLLING_YEAR".equals(s))
            return "FII_TIME_ENT_YEAR";
        else
            return s;
    }

    public static java.lang.String getAutoFactorLabelValue(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.String as[] = null;
        java.lang.String as1[] = null;
        com.sun.java.util.collections.ArrayList arraylist = null;
        java.lang.String s = "";
        java.lang.String s1 = "";
        java.lang.String s2 = "";
        if(usersession != null)
        {
            as = usersession.getAKRegion().getAutoScaleFactor();
            arraylist = usersession.getAKRegion().getDisplayTypeColumns();
        }
        java.lang.String as2[] = new java.lang.String[1];
        if(arraylist != null && arraylist.size() > 0)
            as1 = (java.lang.String[])arraylist.toArray(as2);
        if(as != null)
            s = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getArrayScaleValue(as);
        if(arraylist != null && arraylist.size() > 0)
            s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getArrayScaleValue(as1);
        if(s.equals(s1))
            s2 = s;
        else
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
            s2 = s;
        return s2;
    }

    public static java.lang.String getArrayScaleValue(java.lang.String as[])
    {
        int i = 0;
        int j = 0;
        int k = 0;
        int l = 0;
        for(int i1 = 0; i1 < as.length; i1++)
            if("K".equals(as[i1]))
                i++;
            else
            if("M".equals(as[i1]))
                j++;
            else
            if("B".equals(as[i1]))
                k++;
            else
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(as[i1]))
                l++;

        java.lang.String s = "";
        if(l > 0)
            s = "";
        else
        if(i > 0 && j == 0 && k == 0 && l == 0)
            s = "K";
        else
        if(j > 0 && i == 0 && k == 0 && l == 0)
            s = "M";
        else
        if(k > 0 && i == 0 && j == 0 && l == 0)
            s = "B";
        else
            s = "";
        return s;
    }

    public static boolean isRollingPeriod(java.lang.String s)
    {
        boolean flag = false;
        if("FII_ROLLING_WEEK".equals(s) || "FII_ROLLING_MONTH".equals(s) || "FII_ROLLING_QTR".equals(s) || "FII_ROLLING_YEAR".equals(s))
            flag = true;
        return flag;
    }

    public static boolean isMeasureForFactoring(oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        com.sun.java.util.collections.ArrayList arraylist = akregion.getDisplayColumns();
        new ArrayList(4);
        boolean flag = true;
        for(int i = 0; i < arraylist.size(); i++)
        {
            java.lang.String s = "";
            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist.get(i);
            java.lang.String s1 = akregionitem.getRegionItemType();
            java.lang.String s2 = akregionitem.getDisplayFlag();
            java.lang.String s3 = akregionitem.getTableDisplayFlag();
            akregionitem.getNodeQueryFlag();
            if(akregionitem.isParentLabel())
                continue;
            if(s1.equals("MEASURE") || s1.equals("MEASURE_NOTARGET") || s1.equals("") && (s2.equals("Y") || "Y".equals(s3)) || s1.equals("BUCKET_MEASURE"))
                s = akregionitem.getDataType();
            if("D".equals(s))
            {
                flag = false;
                break;
            }
            if("I".equals(s))
            {
                flag = false;
                break;
            }
            if(!"F".equals(s))
                continue;
            flag = false;
            break;
        }

        return flag;
    }

    public static java.lang.String replaceSpaceForHeader(java.lang.String s)
    {
        if(s == null)
            return "";
        else
            return s.replace(' ', '_');
    }

    public static java.lang.String replaceSpacesForCol(java.lang.String s)
    {
        if(s == null)
            return "";
        else
            return oracle.apps.bis.pmv.common.StringUtil.replaceAll(s, " ", "&nbsp;");
    }

    public static java.lang.String[] getParameterValues(java.lang.String s, java.lang.String s1)
    {
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s) || oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
            return new java.lang.String[0];
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(3);
        boolean flag = false;
        boolean flag1 = false;
        boolean flag2 = false;
        for(int i = s.indexOf(s1 + "="); i >= 0; i = s.indexOf(s1 + "=", i + 1))
        {
            int j = i + s1.length() + 1;
            int k = s.indexOf("&", j);
            if(k > 0)
                arraylist.add(s.substring(j, k));
            else
                arraylist.add(s.substring(j));
        }

        return (java.lang.String[])arraylist.toArray(new java.lang.String[arraylist.size()]);
    }

    public static void bindVOWhereClauseParams(oracle.apps.fnd.framework.OAViewObject oaviewobject, java.lang.String s)
    {
        if(oaviewobject == null || oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
            return;
        int i = 0;
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            for(; s.indexOf(",") > 0; s = s.substring(s.indexOf(",") + 1))
            {
                java.lang.String s1 = s.substring(0, s.indexOf(","));
                oaviewobject.setWhereClauseParam(i++, s1);
            }

            oaviewobject.setWhereClauseParam(i, s);
        }
    }

    public static boolean isPortal(java.lang.String s)
    {
        return !oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && (s.indexOf(",") > 0 || s.indexOf("_") > 0 || !"-".equals(java.lang.String.valueOf(s.charAt(0))));
    }

    public static java.lang.String getReportTitle(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.common.WebAppsContext webappscontext, java.lang.String s)
    {
        javax.servlet.jsp.PageContext pagecontext = oapagecontext.getRenderingContext().getJspPageContext();
        java.lang.String s1 = (java.lang.String)pagecontext.getSession().getValue("oracle.apps.bis.pmv.dynamicTitle");
        s1 = s1 != null ? s1 : oapagecontext.getParameter("reportTitle");
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1) && oapagecontext.getSessionValue("reportTitle") != null)
            s1 = oapagecontext.getSessionValue("reportTitle").toString();
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
        {
            java.lang.String as[] = oracle.apps.bis.pmv.header.HeaderBean.getTitleHTML(webappscontext, s);
            if(as[0] != null)
            {
                oapagecontext.putSessionValue("reportTitle", as[0]);
                s1 = as[0];
            }
        } else
        {
            oapagecontext.putSessionValue("reportTitle", s1);
        }
        return s1;
    }

    public static java.lang.String getFirstViewBy(oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        if(akregion == null)
            return "";
        com.sun.java.util.collections.ArrayList arraylist = akregion.getSortedItems();
        java.lang.String s = "";
        if(arraylist != null)
        {
            Object obj = null;
            for(int i = 0; i < arraylist.size(); i++)
            {
                oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist.get(i);
                if(akregionitem == null || !akregionitem.isDimension() || oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeComparisonDimension(akregionitem.getDimension()) || oracle.apps.bis.pmv.common.StringUtil.emptyString(akregionitem.getRegionItemType()) || oracle.apps.bis.pmv.common.StringUtil.in(akregionitem.getRegionItemType(), oracle.apps.bis.pmv.common.PMVConstants.BIS_NON_VIEWBY_TYPES))
                    continue;
                if(akregionitem.isDuplicate())
                    s = akregionitem.getParamName();
                else
                    s = akregionitem.getAttribute2();
                break;
            }

        }
        return s;
    }

    public static java.lang.String getDashboardCustomViewCode(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, java.lang.String s)
    {
        javax.servlet.jsp.PageContext pagecontext = oapagecontext.getRenderingContext().getJspPageContext();
        javax.servlet.http.HttpSession httpsession = pagecontext.getSession();
        java.lang.String s1 = oapagecontext.getParameter("pCustomCode");
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
        {
            s1 = oapagecontext.getParameter("pCustomView");
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
            {
                java.lang.String s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.generateDashboardCustomViewCodeSessionKey(s);
                s1 = (java.lang.String)httpsession.getValue(s2);
            }
        }
        return s1;
    }

    public static java.lang.String getPageFunctionName(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, java.lang.String s)
    {
        java.lang.String s1 = oapagecontext.getParameter("pageFunctionName");
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
        {
            java.lang.String s2 = oapagecontext.getParameter("function_id");
            oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = oapagecontext.getFunctionSecurity();
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2) && functionsecurity != null)
                try
                {
                    oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(java.lang.Integer.parseInt(s2));
                    s1 = function.getFunctionName();
                }
                catch(java.lang.NumberFormatException _ex) { }
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && functionsecurity.getFunction(s) != null)
                s1 = s;
        }
        return s1;
    }

    public static void clearCustomViewCodeInSession(java.lang.String s, javax.servlet.http.HttpSession httpsession)
    {
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.generateDashboardCustomViewCodeSessionKey(s);
        httpsession.removeValue(s1);
    }

    public static java.lang.String generateDashboardCustomViewCodeSessionKey(java.lang.String s)
    {
        return s + "_CustCode";
    }

    public static boolean isInPortal(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        return "115X".equals(webappscontext.getID(30));
    }

    public static boolean isCalculationRequired(oracle.apps.bis.pmv.metadata.AKRegion akregion, oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem)
    {
        if(akregion == null || akregionitem == null || akregionitem.getBaseColumn() == null || !akregionitem.getBaseColumn().startsWith("\"") || "CHANGE_MEASURE".equals(akregionitem.getRegionItemType()) || "CHANGE_MEASURE_NO_TARGET".equals(akregionitem.getRegionItemType()))
            return true;
        boolean flag = false;
        java.util.Enumeration enumeration = akregion.getAKRegionItems().keys();
        Object obj = null;
        while(enumeration.hasMoreElements())
        {
            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem1 = (oracle.apps.bis.pmv.metadata.AKRegionItem)akregion.getAKRegionItems().get(enumeration.nextElement());
            if(akregionitem1 != null && akregionitem.getBaseColumn().indexOf(akregionitem1.getAttributeCode()) >= 0)
            {
                flag = true;
                break;
            }
        }
        return flag;
    }

    public static Vector getListofShortcuts(Connection conn,oracle.apps.bis.pmv.session.UserSession usersession)
	{
	 StringBuffer sqlString = new StringBuffer();
	 sqlString.append(" SELECT xval.source_value1 label,xval.source_value3 full_path ");
	 sqlString.append("  FROM  xx_fin_translatedefinition xdef, xx_fin_translatevalues xval,fnd_responsibility resp ");
	 sqlString.append("  WHERE  xdef.translation_name = 'XXBI_DASHBOARD_SHORTCUTS' AND  xdef.translate_id = xval.translate_id ");
	 sqlString.append("  AND  TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,SYSDATE - 1)) AND TRUNC (NVL (xval.end_date_active, SYSDATE + 1)) ");
	 sqlString.append("  AND xval.source_value4= resp.responsibility_key(+) AND resp.responsibility_id = :1 order by xval.source_value2 ");

	 String sql = sqlString.toString();

	 PreparedStatement pstmt = null;

	 ResultSet rs  = null;

	 Vector objVect = new Vector();
	 String respId = usersession.getResponsibilityId();
	 try{

	   pstmt = conn.prepareStatement(sql);
	   oracle.jdbc.driver.OracleStatement ostmt = (oracle.jdbc.driver.OracleStatement) pstmt;
	   ostmt.defineColumnType(1,java.sql.Types.VARCHAR,240);
	   ostmt.defineColumnType(2,java.sql.Types.VARCHAR,240);

	   pstmt.setString(1, respId);
	   rs = pstmt.executeQuery();

	   while (rs.next())      {
			String label = rs.getString(1);
			String path =  rs.getString(2);
			HashMap objHash = new HashMap();
			objHash.put("label",label);
			objHash.put("path",path);
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


	public static void testUpdate(java.lang.String s, java.sql.Connection connection)
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

    public static final java.lang.String RCS_ID = "$Header: PMVUtil.java 115.203 2007/01/30 09:43:30 nkishore noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: PMVUtil.java 115.203 2007/01/30 09:43:30 nkishore noship $", "oracle.apps.bis.pmv.common");
    private static final java.lang.String SQL_REGION_APP_ID = " SELECT region_application_id FROM ak_regions WHERE region_code = :1 ";
    public static final int SEC_INFO_LEN = 3;
    public static final int RESP_ID_INDEX = 0;
    public static final int RESP_APP_ID_INDEX = 1;
    public static final int SEC_GRP_ID_INDEX = 2;
    public static java.lang.String m_FrameworkAgent;
    private static com.sun.java.util.collections.Map _reportURLParamMapping;
    private static final int HASH_LENGTH = 16;

    static
    {
        _reportURLParamMapping = new HashMap();
        _reportURLParamMapping.put("pRegionCode", "regionCode");
        _reportURLParamMapping.put("pFunctionName", "functionName");
        _reportURLParamMapping.put("pForceRun", "forceRun");
        _reportURLParamMapping.put("pParameterDisplayOnly", "parameterDisplayOnly");
        _reportURLParamMapping.put("pDisplayParameters", "displayParameters");
        _reportURLParamMapping.put("pReportSchedule", "showSchedule");
        _reportURLParamMapping.put("pScheduleId", "scheduleId");
        _reportURLParamMapping.put("pRequestType", "requestType");
        _reportURLParamMapping.put("pFileId", "fileId");
        _reportURLParamMapping.put("vPageId", "_pageid");
        _reportURLParamMapping.put("pautorefresh", "autoRefresh");
    }
}
