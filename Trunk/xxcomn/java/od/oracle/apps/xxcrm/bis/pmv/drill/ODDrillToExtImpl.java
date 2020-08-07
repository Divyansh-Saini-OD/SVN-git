// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODDrillToExtImpl.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.Iterator;
import com.sun.java.util.collections.Map;
import com.sun.java.util.collections.Set;
import java.sql.Connection;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.database.JDBCUtil;
import oracle.apps.bis.pmv.PMVException;
import oracle.apps.bis.pmv.common.PMVConstants;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.parameters.Parameters;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.AppsContext;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.functionSecurity.Function;

// Referenced classes of package od.oracle.apps.xxcrm.bis.pmv.drill:
//            DrillImpl, BisExternalParamMap, DrillJDBCUtil, DrillUtil,
//            ParamMapHandler

public class ODDrillToExtImpl extends od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillImpl
{

    public ODDrillToExtImpl(javax.servlet.http.HttpServletRequest httpservletrequest, javax.servlet.jsp.PageContext pagecontext, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection, java.lang.String s)
    {
        super(httpservletrequest, pagecontext, webappscontext, connection);
        super.m_FunctionTo = s;
    }

    public void process()
    {
        od.oracle.apps.xxcrm.bis.pmv.drill.ODBisExternalParamMap bisexternalparammap = od.oracle.apps.xxcrm.bis.pmv.drill.ODParamMapHandler.getBisExtParamMap(super.m_FunctionTo, super.m_WebAppsContext, super.m_Connection);
        com.sun.java.util.collections.HashMap hashmap = bisexternalparammap.getDimLevelMap();
        com.sun.java.util.collections.HashMap hashmap1 = bisexternalparammap.getParamOAEncryptMap();
        try
        {
            processBUASavedParams(hashmap, hashmap1);
            processDrillUrlParams(hashmap, hashmap1);
            return;
        }
        catch(oracle.apps.bis.pmv.PMVException _ex)
        {
            return;
        }
    }

    public void redirect()
    {
        java.lang.String s = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getURLParameters(m_ParamMap, super.m_Enc);
        setRedirectUrl(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getRunFunctionURL(super.m_FunctionTo, s, super.m_WebAppsContext));
        checkForOAPage(super.m_Mode, s);
    }

    private oracle.apps.bis.pmv.session.UserSession getUserSessionFrom(java.lang.String s)
        throws oracle.apps.bis.pmv.PMVException
    {
        oracle.apps.fnd.functionSecurity.Function function = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(s, super.m_WebAppsContext);
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getReportRegion(function.getWebHTMLCall(), function.getParameters());
        return new UserSession(s, s1, super.m_WebAppsContext, null, super.m_Connection, super.m_PmvMsgLog);
    }

    private oracle.apps.bis.pmv.metadata.AKRegion getAKRegionFrom(java.lang.String s)
        throws oracle.apps.bis.pmv.PMVException
    {
        oracle.apps.bis.pmv.session.UserSession usersession = getUserSessionFrom(s);
        if(usersession != null)
            return usersession.getAKRegion();
        else
            return null;
    }

    private void processDrillUrlParams(com.sun.java.util.collections.HashMap hashmap, com.sun.java.util.collections.HashMap hashmap1)
        throws oracle.apps.bis.pmv.PMVException
    {
        java.lang.String s = oracle.apps.bis.common.ServletWrapper.getParameter(super.m_Request, "pUrlString");
        if(s == null)
            return;
        if(s.startsWith("{!!"))
            s = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.OADecrypt(super.m_WebAppsContext, s);
        com.sun.java.util.collections.Map map = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameters(s);
        if(map == null || map.size() == 0)
            return;
        com.sun.java.util.collections.Set set = map.keySet();
        com.sun.java.util.collections.Iterator iterator = set.iterator();
        if(m_ParamMap == null)
            m_ParamMap = new HashMap(23);
        oracle.apps.bis.pmv.metadata.AKRegion akregion = getAKRegionFrom(super.m_FunctionFrom);
        while(iterator.hasNext())
        {
            java.lang.String s1 = (java.lang.String)iterator.next();
            java.lang.String s2 = (java.lang.String)map.get(s1);
            java.lang.String s3 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getAttr2FromAttrCode(akregion, s1);
            java.lang.String s4 = null;
            if(hashmap != null)
                s4 = (java.lang.String)hashmap.get(s3);
            if(s4 != null)
                populateParamMap(s4, s2, hashmap1);
            else
                populateParamMap(s1, s2, hashmap1);
        }
    }

    private com.sun.java.util.collections.ArrayList getBUAParams()
        throws oracle.apps.bis.pmv.PMVException
    {
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_PageId))
        {
            java.lang.String s = oracle.apps.bis.database.JDBCUtil.getParameterPortletFunctionName(super.m_PageId, super.m_UserId, super.m_Connection);
            oracle.apps.bis.pmv.metadata.AKRegion akregion = getAKRegionFrom(s);
            return getPageParameters(akregion);
        } else
        {
            return od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getSessionParameters(super.m_FunctionFrom, java.lang.Integer.toString(super.m_WebAppsContext.getUserId()), super.m_WebAppsContext.getSessionId(), super.m_Connection);
        }
    }

    private void processBUASavedParams(com.sun.java.util.collections.HashMap hashmap, com.sun.java.util.collections.HashMap hashmap1)
        throws oracle.apps.bis.pmv.PMVException
    {
        com.sun.java.util.collections.ArrayList arraylist = getBUAParams();
        if(arraylist != null)
        {
            if(m_ParamMap == null)
                m_ParamMap = new HashMap(13);
            Object obj = null;
            for(int i = 0; i < arraylist.size(); i++)
            {
                oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)arraylist.get(i);
                java.lang.String s = parameters.getParameterName();
                java.lang.String s1 = null;
                if(hashmap != null)
                    s1 = (java.lang.String)hashmap.get(s);
                if(s1 != null)
                    populateParamMap(s1, parameters.getParameterValue(), hashmap1);
            }

        }
    }

    private void populateParamMap(java.lang.String s, java.lang.String s1, com.sun.java.util.collections.HashMap hashmap)
    {
        int i = s1.length();
        if(s1.startsWith("'") && s1.endsWith("'") && i > 2)
            s1 = s1.substring(1, s1.length() - 1);
        if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isOAEncryptedValue(s, hashmap))
        {
            m_ParamMap.put(s, od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.OAEncrypt(super.m_WebAppsContext, s1));
            return;
        } else
        {
            m_ParamMap.put(s, s1);
            return;
        }
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillToExtImpl.java 115.6 2006/02/14 11:13:51 serao noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillToExtImpl.java 115.6 2006/02/14 11:13:51 serao noship $", "od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillToExtImpl");
    private com.sun.java.util.collections.HashMap m_ParamMap;

}
