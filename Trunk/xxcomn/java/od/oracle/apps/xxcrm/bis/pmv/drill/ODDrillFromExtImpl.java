// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODDrillFromExtImpl.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.HashSet;
import com.sun.java.util.collections.Iterator;
import com.sun.java.util.collections.Set;
import java.sql.Connection;
import java.util.Enumeration;
import javax.servlet.ServletRequest;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.pmv.common.PMVConstants;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.fnd.common.AppsContext;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;

// Referenced classes of package od.oracle.apps.xxcrm.bis.pmv.drill:
//            DrillImpl, BisExternalParamMap, DrillUtil, ParamMapHandler

public class ODDrillFromExtImpl extends od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillImpl
{

    public ODDrillFromExtImpl(javax.servlet.http.HttpServletRequest httpservletrequest, javax.servlet.jsp.PageContext pagecontext, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection)
    {
        super(httpservletrequest, pagecontext, webappscontext, connection);
    }

    public void setParamMap(com.sun.java.util.collections.HashMap hashmap)
    {
        m_ParamMap = hashmap;
    }

    private boolean isTimeDimension(java.lang.String s)
    {
        if(s == null)
            return false;
        return s.startsWith("TIME+") || s.startsWith("EDW_TIME+");
    }

    private java.lang.String getMappedParamStr(com.sun.java.util.collections.HashMap hashmap, com.sun.java.util.collections.HashMap hashmap1)
    {
        if(hashmap == null || m_ParamMap == null)
            return null;
        com.sun.java.util.collections.Set set = m_ParamMap.keySet();
        com.sun.java.util.collections.Iterator iterator = set.iterator();
        java.lang.StringBuffer stringbuffer = new StringBuffer(2000);
        while(iterator.hasNext())
        {
            java.lang.String s = (java.lang.String)iterator.next();
            java.lang.String s1 = (java.lang.String)m_ParamMap.get(s);
            if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isOAEncryptedValue(s, hashmap1))
                s1 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.OADecrypt(super.m_WebAppsContext, s1);
            stringbuffer.append("&");
            java.lang.String s2 = (java.lang.String)hashmap.get(s);
            if(s2 != null)
            {
                if(isTimeDimension(s2))
                {
                    stringbuffer.append(s2).append("_FROM").append("=").append(s1).append("&");
                    stringbuffer.append(s2).append("_TO").append("=").append(s1);
                } else
                {
                    stringbuffer.append(s2).append("=").append(s1);
                }
            } else
            {
                stringbuffer.append(s).append("=").append(s1);
            }
        }
        return stringbuffer.toString();
    }

    public static com.sun.java.util.collections.HashMap getParameters(javax.servlet.http.HttpServletRequest httpservletrequest)
    {
        java.util.Enumeration enumeration = httpservletrequest.getParameterNames();
        Object obj = null;
        Object obj1 = null;
        com.sun.java.util.collections.HashMap hashmap = new HashMap(23);
        while(enumeration.hasMoreElements())
        {
            java.lang.String s = (java.lang.String)enumeration.nextElement();
            java.lang.String s1 = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, s);
            if(!IGNORE_PARAM_MAP.contains(s))
                hashmap.put(s, s1);
        }
        return hashmap;
    }

    private void getParameterPortletFunctionName(java.lang.String s)
    {
    }

    public void redirect()
    {
    }

    protected void setRedirectUrl(java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(300);
        stringbuffer.append("/OA_HTML/OA.jsp?page=/od/oracle/apps/xxcrm/bis/pmv/drill/webui/DrillPG&retainAM=Y&addBreadCrumb=Y&pMode=1");
        stringbuffer.append("&").append("dbc").append("=").append(super.m_DBC);
        stringbuffer.append("&").append("transactionid").append("=").append(super.m_TxnId);
        stringbuffer.append("&pUrlString=").append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.OAEncrypt(super.m_WebAppsContext, s));
        stringbuffer.append("&pUserId=").append(java.lang.Integer.toString(super.m_WebAppsContext.getUserId()));
        stringbuffer.append("&pRespId=").append(java.lang.Integer.toString(super.m_WebAppsContext.getRespId()));
        stringbuffer.append("&pPreFunction=").append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getEncodedString(super.m_FunctionFrom, super.m_Enc));
        stringbuffer.append("&pBCFromFunction=").append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getEncodedString(super.m_FunctionFrom, super.m_Enc));
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_ScheduleId))
            stringbuffer.append("&pScheduleId=").append(super.m_ScheduleId);
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_PageId))
            stringbuffer.append("&pPageId=").append(super.m_PageId);
        super.m_RedirectURL = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getOAMacUrl(stringbuffer.toString(), super.m_WebAppsContext);
    }

    public void process()
    {
        od.oracle.apps.xxcrm.bis.pmv.drill.ODBisExternalParamMap bisexternalparammap = od.oracle.apps.xxcrm.bis.pmv.drill.ODParamMapHandler.getBisExtParamMap(super.m_FunctionFrom, super.m_WebAppsContext, super.m_Connection);
        com.sun.java.util.collections.HashMap hashmap = bisexternalparammap.getParamNameMap();
        com.sun.java.util.collections.HashMap hashmap1 = bisexternalparammap.getParamOAEncryptMap();
        java.lang.String s = "pFunctionName=" + super.m_FunctionTo + "&pParamIds=Y" + getMappedParamStr(hashmap, hashmap1);
        setRedirectUrl(s);
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillFromExtImpl.java 115.10 2005/12/14 04:10:49 udua noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillFromExtImpl.java 115.10 2005/12/14 04:10:49 udua noship $", "od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillFromExtImpl");
    private com.sun.java.util.collections.HashMap m_ParamMap;
    static final com.sun.java.util.collections.HashSet IGNORE_PARAM_MAP;

    static
    {
        IGNORE_PARAM_MAP = new HashSet(13);
        IGNORE_PARAM_MAP.add("pMode");
        IGNORE_PARAM_MAP.add("dbc");
        IGNORE_PARAM_MAP.add("transactionid");
        IGNORE_PARAM_MAP.add("pPreFunction");
        IGNORE_PARAM_MAP.add("pFunction");
        IGNORE_PARAM_MAP.add("language_code");
        IGNORE_PARAM_MAP.add("sessionid");
    }
}
