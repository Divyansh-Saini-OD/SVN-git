// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODDrillRelatedImpl.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.HashSet;
import com.sun.java.util.collections.Map;
import java.sql.Connection;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.database.JDBCUtil;
import oracle.apps.bis.pmv.common.PMVConstants;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.session.RequestInfo;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.functionSecurity.Function;

// Referenced classes of package od.oracle.apps.xxcrm.bis.pmv.drill:
//            DrillImpl, DrillFactory, DrillUtil

public class ODDrillRelatedImpl extends od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillImpl
{

    public ODDrillRelatedImpl(javax.servlet.http.HttpServletRequest httpservletrequest, javax.servlet.jsp.PageContext pagecontext, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection)
    {
        super(httpservletrequest, pagecontext, webappscontext, connection);
        m_RegionCode = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pRegionCode");
        m_Mode = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getMode(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pMode"));
        m_UrlString = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pUrlString");
        if(m_UrlString != null && m_UrlString.startsWith("{!!"))
            m_UrlString = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.OADecrypt(webappscontext, m_UrlString);
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_FunctionTo))
        {
            com.sun.java.util.collections.HashMap hashmap = (com.sun.java.util.collections.HashMap)od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameters(m_UrlString);
            super.m_FunctionTo = (java.lang.String)hashmap.get("pFunctionName");
            m_DisplayMode = (java.lang.String)hashmap.get("pDisplayMode");
            m_ParamName = (java.lang.String)hashmap.get("paramName");
        }
    }

    public void redirect()
    {
        if(m_UrlString != null && m_UrlString.toUpperCase().startsWith("HTTP"))
        {
            setRedirectUrl(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getEncodedUrl(m_UrlString, super.m_Enc));
            return;
        }
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        boolean flag = m_Mode == 4 && od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.canFunctionUseRFCall(super.m_FunctionTo, super.m_WebAppsContext);
        if(flag)
        {
            stringbuffer.append("pMode=RELATED");
        } else
        {
            if(m_Mode == 4)
            {
                stringbuffer.append("../XXCRM_HTML/bisviewm.jsp?").append("dbc").append("=").append(super.m_DBC);
                stringbuffer.append("&").append("transactionid").append("=").append(super.m_TxnId);
            }
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getURLParameters(super.m_ParamMap, super.m_Enc));
        }
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_DrillDefaultParameters))
            super.m_Session.putValue("DrillDefaultParameters", super.m_DrillDefaultParameters);
        addURLParameters(stringbuffer);
        addPrintableParams(stringbuffer);
        if(super.m_UserSession != null && super.m_UserSession.getLookUpHelperHashMap() != null)
            super.m_Session.putValue("PMV_LOOKUPHELPER_OBJECTS", super.m_UserSession.getLookUpHelperHashMap());
        if(m_Mode == 5 || m_Mode == 6 || flag)
            setRedirectUrl(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getRunFunctionURL(super.m_FunctionTo, stringbuffer.toString(), super.m_WebAppsContext, super.m_RespId, super.m_RespAppId, super.m_SecGrpId));
        else
        if(m_Mode == 0)
            setRedirectUrl(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getRunFunctionURL(super.m_FunctionTo, null, super.m_WebAppsContext, super.m_RespId, super.m_RespAppId, super.m_SecGrpId));
        else
            setRedirectUrl(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getEncodedUrl(stringbuffer.toString(), super.m_Enc));
        checkForOAPage(m_Mode, stringbuffer.toString());
    }

    public void process()
    {
        if(m_Mode == 0 || m_UrlString != null && m_UrlString.toUpperCase().startsWith("HTTP"))
            return;
        oracle.apps.fnd.functionSecurity.Function function = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(super.m_FunctionTo, super.m_WebAppsContext);
        try
        {
            super.m_InsertParams = new HashMap(13);
            super.m_DeleteParams = new HashSet(13);
            if(m_Mode == 4)
                super.m_UserSession = new UserSession(super.m_FunctionTo, m_RegionCode, super.m_WebAppsContext, null, super.m_Connection, super.m_PmvMsgLog);
            else
            if(m_Mode == 5 || m_Mode == 6)
            {
                super.m_PageIdTo = java.lang.String.valueOf(-function.getFunctionID());
                java.lang.String s = oracle.apps.bis.database.JDBCUtil.getParameterPortletFunctionName(super.m_PageIdTo, super.m_UserId, super.m_Connection);
                if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
                    s = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterPortletFunctionName(super.m_FunctionTo, super.m_Connection);
                oracle.apps.fnd.functionSecurity.Function function1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(s, super.m_WebAppsContext);
                java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getReportRegion(function1.getWebHTMLCall(), function1.getParameters());
                super.m_UserSession = new UserSession(s, s1, super.m_WebAppsContext, null, super.m_Connection, super.m_PmvMsgLog);
                oracle.apps.bis.pmv.session.RequestInfo requestinfo = new RequestInfo();
                requestinfo.setPageId(super.m_PageIdTo);
                requestinfo.setRequestType("P");
                super.m_UserSession.setRequestInfo(requestinfo);
            }
            super.m_UserSession.setPageContext(super.m_PageContext);
            com.sun.java.util.collections.ArrayList arraylist = getParameterGroups(super.m_UserSession.getAKRegion());
            if(m_Mode == 4)
                processGroupedParameters(null, super.m_PageId, super.m_UserSession.getAKRegion(), arraylist, function.getParameters());
            else
            if(m_Mode == 5)
                processPageFromReport(arraylist);
            else
            if(m_Mode == 6)
                processPageFromPage(arraylist);
            processNonTimeFormFunctionParameters();
            validateParameters();
            createParameters();
            super.m_ParamMap = new HashMap(13);
            if(m_Mode == 4)
            {
                populateCommonReportParams();
                super.m_ParamMap.put("pMode", "RELATED");
                super.m_ParamMap.put("pPreFunctionName", super.m_FunctionFrom);
                super.m_ParamMap.put("pBCFromFunctionName", super.m_BCFromFunction);
                super.m_ParamMap.put("forceRun", oracle.apps.bis.common.ServletWrapper.getParameter(super.m_Request, "pForceRun"));
                super.m_ParamMap.put("parameterDisplayOnly", oracle.apps.bis.common.ServletWrapper.getParameter(super.m_Request, "pParameterDisplayOnly"));
                super.m_ParamMap.put("displayParameters", oracle.apps.bis.common.ServletWrapper.getParameter(super.m_Request, "pDisplayParameters"));
                super.m_ParamMap.put("pEnableForecastGraph", oracle.apps.bis.common.ServletWrapper.getParameter(super.m_Request, "pEnableForecastGraph"));
                super.m_ParamMap.put("pDispRun", oracle.apps.bis.common.ServletWrapper.getParameter(super.m_Request, "pDispRun"));
                super.m_ParamMap.put("pCustomView", oracle.apps.bis.common.ServletWrapper.getParameter(super.m_Request, "pCustomView"));
                super.m_ParamMap.put("pMaxResultSetSize", oracle.apps.bis.common.ServletWrapper.getParameter(super.m_Request, "pMaxResultSetSize"));
                super.m_ParamMap.put("pOutputFormat", oracle.apps.bis.common.ServletWrapper.getParameter(super.m_Request, "pOutputFormat"));
                return;
            }
        }
        catch(java.lang.Exception _ex) { }
    }

    public void addPrintableParams(java.lang.StringBuffer stringbuffer)
    {
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_DisplayMode))
        {
            stringbuffer.append("&pDisplayMode=").append(m_DisplayMode);
            stringbuffer.append("&paramName=").append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getEncodedString(m_ParamName, super.m_Enc));
            if("PRINT".equals(m_DisplayMode))
            {
                stringbuffer.append("&email=Y");
                return;
            }
            if("EXPORT".equals(m_DisplayMode))
                stringbuffer.append("&fromExport=EXPORT_TO_PDF");
        }
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillRelatedImpl.java 115.20 2006/07/17 06:42:48 nbarik noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillRelatedImpl.java 115.20 2006/07/17 06:42:48 nbarik noship $", "od.oracle.apps.xxcrm.bis.pmv.drill");
    private java.lang.String m_RegionCode;
    private int m_Mode;
    private java.lang.String m_UrlString;
    private java.lang.String m_DisplayMode;
    private java.lang.String m_ParamName;

}
