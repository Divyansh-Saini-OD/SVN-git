// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODDrillFromPortletTitleImpl.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.HashSet;
import com.sun.java.util.collections.Map;
import java.sql.Connection;
import java.util.Hashtable;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.common.SimpleDateUtil;
import oracle.apps.bis.pmv.common.PMVConstants;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.parameters.Parameters;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.Context;
import oracle.apps.fnd.common.ProfileStore;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.functionSecurity.Function;

// Referenced classes of package od.oracle.apps.xxcrm.bis.pmv.drill:
//            DrillImpl, DrillFactory, DrillJDBCUtil, DrillUtil

public class ODDrillFromPortletTitleImpl extends od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillImpl
{

    public ODDrillFromPortletTitleImpl(javax.servlet.http.HttpServletRequest httpservletrequest, javax.servlet.jsp.PageContext pagecontext, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection)
    {
        super(httpservletrequest, pagecontext, webappscontext, connection);
        m_RegionCode = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pRegionCode");
        m_RespId = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pResponsibilityId");
        m_ObjectType = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pObjectType");
        m_Mode = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getMode(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pMode"));
        m_Designer = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "designer");
    }

    public void redirect()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append("../XXCRM_HTML/bisviewm.jsp?").append("dbc").append("=").append(super.m_DBC);
        stringbuffer.append("&").append("transactionid").append("=").append(super.m_TxnId);
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getURLParameters(super.m_ParamMap, super.m_Enc));
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_DrillDefaultParameters))
            super.m_Session.putValue("DrillDefaultParameters", super.m_DrillDefaultParameters);
        addURLParameters(stringbuffer);
        setRedirectUrl(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getEncodedUrl(stringbuffer.toString(), super.m_Enc));
    }

    public void process()
    {
        try
        {
            oracle.apps.fnd.functionSecurity.Function function = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(super.m_FunctionTo, super.m_WebAppsContext);
            super.m_InsertParams = new HashMap(13);
            super.m_DeleteParams = new HashSet(13);
            java.lang.String s = null;
            java.lang.String s1 = null;
            java.lang.String s2 = null;
            java.lang.String s3 = null;
            java.lang.String s4 = null;
            java.lang.String s5 = null;
            Object obj = null;
            java.lang.String s7 = null;
            java.lang.String s8 = null;
            if(function != null)
            {
                java.lang.String s6 = function.getParameters();
                if(s6 != null)
                {
                    s = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s6, "pEnableForecastGraph");
                    s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s6, "pTitleCustomView");
                    s5 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s6, "pReportFunctionName");
                }
            }
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s5))
            {
                oracle.apps.fnd.functionSecurity.Function function1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(s5, super.m_WebAppsContext);
                if(function1 != null)
                {
                    s7 = function1.getParameters();
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s7))
                    {
                        s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s7, "pCustomView");
                        s3 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s7, "pRegionCode");
                    }
                }
            }
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s3))
                s3 = m_RegionCode;
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s5))
                s4 = s5;
            else
                s4 = super.m_FunctionTo;
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                s2 = s1;
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_RespId))
                s8 = m_RespId;
            else
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_ScheduleId))
                s8 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getRespId(super.m_ScheduleId, super.m_Connection);
            super.m_UserSession = new UserSession(s4, s3, super.m_WebAppsContext, null, super.m_Connection, super.m_PmvMsgLog);
            super.m_UserSession.setPageContext(super.m_PageContext);
            if(m_Mode != 8)
            {
                super.m_IsDeleteAllParams = true;
                Object obj1 = null;
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_PageId))
                {
                    super.m_FunctionTo = s4;
                    com.sun.java.util.collections.ArrayList arraylist1 = getParameterGroups(super.m_UserSession.getAKRegion());
                    processGroupedParameters(super.m_ScheduleId, super.m_PageId, super.m_UserSession.getAKRegion(), arraylist1, s7);
                    if(super.m_PageId.indexOf("-") < 0 || super.m_PageId.indexOf(",") > 0 || super.m_PageId.indexOf("_") > 0)
                        defaultAsOfDateProfileValue();
                } else
                {
                    com.sun.java.util.collections.ArrayList arraylist = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getScheduleParameters(super.m_ScheduleId, super.m_Connection);
                    processParameters(arraylist);
                }
                processNonTimeFormFunctionParameters();
                if(m_Designer == null || !"Y".equals(m_Designer))
                    validateParameters();
                createParameters();
            }
            super.m_ParamMap = new HashMap(11);
            populateCommonReportParams();
            if(m_Mode == 8)
                super.m_ParamMap.put("pMode", "BCRUMB");
            else
                super.m_ParamMap.put("pMode", "DrillDown");
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
                super.m_ParamMap.put("pEnableForecastGraph", s);
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
                super.m_ParamMap.put("pCustomView", s2);
            super.m_ParamMap.put("pResponsibilityId", s8);
            super.m_ParamMap.put("pObjectType", m_ObjectType);
            return;
        }
        catch(java.lang.Exception _ex)
        {
            return;
        }
    }

    private void processScheduleNonPageParams(com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1)
    {
        if(arraylist != null)
        {
            Object obj = null;
            Object obj1 = null;
            Object obj2 = null;
            Object obj3 = null;
            Object obj4 = null;
            int i = -999;
            for(int j = 0; j < arraylist.size(); j++)
            {
                oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)arraylist.get(j);
                if(parameters != null)
                {
                    java.lang.String s = parameters.getParameterDescription();
                    java.lang.String s1 = parameters.getParameterValue();
                    if("VIEW_BY".equals(parameters.getParameterName()))
                    {
                        java.lang.String s2 = getNonViewByAttr2(s);
                        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
                        {
                            if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isTimeParameter(s1, super.m_UserSession.getAKRegion()))
                            {
                                oracle.apps.bis.pmv.parameters.Parameters parameters1 = getPageTimeParameter(arraylist1);
                                if(parameters1 != null && !oracle.apps.bis.pmv.common.StringUtil.emptyString(parameters1.getParameterValue()))
                                {
                                    parameters.setParameterDescription(parameters1.getParameterValue());
                                    parameters.setParameterValue(parameters1.getParameterValue());
                                }
                            }
                        } else
                        {
                            i = j;
                        }
                    }
                }
            }

            if(i != -999 && i >= 0 && i < arraylist.size())
                arraylist.remove(i);
            processParameters(arraylist);
        }
    }

    private java.lang.String getNonViewByAttr2(java.lang.String s)
    {
        java.lang.String s1 = null;
        oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)super.m_UserSession.getAKRegion().getAKRegionItems().get(s);
        if(akregionitem != null && !oracle.apps.bis.pmv.common.StringUtil.in(akregionitem.getRegionItemType(), oracle.apps.bis.pmv.common.PMVConstants.DRILL_NON_VIEWBY_LEVELS))
            s1 = akregionitem.getAttribute2();
        return s1;
    }

    private oracle.apps.bis.pmv.parameters.Parameters getPageTimeParameter(com.sun.java.util.collections.ArrayList arraylist)
    {
        Object obj = null;
        if(arraylist != null)
        {
            for(int i = 0; i < arraylist.size(); i++)
            {
                oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)arraylist.get(i);
                if(parameters != null && od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isTimeParameter(parameters.getParameterName(), super.m_UserSession.getAKRegion()) && parameters.getParameterName().endsWith("_FROM"))
                    return parameters;
            }

        }
        return null;
    }

    private com.sun.java.util.collections.ArrayList getScheduleNonPageParams(com.sun.java.util.collections.ArrayList arraylist)
    {
        com.sun.java.util.collections.ArrayList arraylist1 = null;
        com.sun.java.util.collections.ArrayList arraylist2 = new ArrayList(11);
        com.sun.java.util.collections.ArrayList arraylist3 = new ArrayList(5);
        Object obj = null;
        if(arraylist != null)
        {
            for(int i = 0; i < arraylist.size(); i++)
            {
                oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)arraylist.get(i);
                if(parameters != null)
                {
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(parameters.getParameterName()))
                        arraylist2.add(parameters.getParameterName());
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(parameters.getDimension()))
                        arraylist3.add(parameters.getDimension());
                }
            }

        }
        arraylist1 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getScheduleNonPageParameters(super.m_ScheduleId, arraylist2, arraylist3, super.m_Connection);
        return arraylist1;
    }

    private void defaultAsOfDateProfileValue()
    {
        java.lang.String s = super.m_UserSession.getWebAppsContext().getProfileStore().getProfile("BIS_AS_OF_DATE");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            java.text.SimpleDateFormat simpledateformat = oracle.apps.bis.common.SimpleDateUtil.getDefaultPMVDateFormat();
            try
            {
                oracle.sql.DATE date = oracle.apps.bis.common.SimpleDateUtil.getOracleDATE(s, simpledateformat);
                if(date != null)
                {
                    oracle.apps.bis.pmv.parameters.Parameters parameters = new Parameters();
                    parameters.setParameterName("AS_OF_DATE");
                    parameters.setParameterValue(s);
                    parameters.setParameterDescription(s);
                    parameters.setPeriodDate(s);
                    parameters.setPeriod(date);
                    com.sun.java.util.collections.ArrayList arraylist = new ArrayList(1);
                    arraylist.add(parameters);
                    processParameters(arraylist);
                    return;
                }
            }
            catch(java.lang.Exception _ex)
            {
                return;
            }
        }
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillFromPortletTitleImpl.java 115.14 2006/01/09 22:02:57 nkishore noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillFromPortletTitleImpl.java 115.14 2006/01/09 22:02:57 nkishore noship $", "od.oracle.apps.xxcrm.bis.pmv.drill");
    private java.lang.String m_RegionCode;
    private java.lang.String m_RespId;
    private java.lang.String m_ObjectType;
    private int m_Mode;
    private java.lang.String m_Designer;

}
