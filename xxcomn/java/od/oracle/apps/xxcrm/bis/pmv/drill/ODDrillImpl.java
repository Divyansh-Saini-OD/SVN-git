// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODDrillImpl.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.HashSet;
import com.sun.java.util.collections.Iterator;
import com.sun.java.util.collections.Map;
import com.sun.java.util.collections.Set;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Enumeration;
import java.util.Hashtable;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.common.SimpleDateUtil;
import oracle.apps.bis.common.Util;
import oracle.apps.bis.database.JDBCUtil;
import oracle.apps.bis.msg.MessageLog;
import oracle.apps.bis.parameters.Parameter;
import oracle.apps.bis.parameters.ParameterSet;
import oracle.apps.bis.parameters.ParameterSetManager;
import oracle.apps.bis.parameters.ServletParameterSetManager;
import oracle.apps.bis.pmv.breadcrumb.BreadCrumb;
import oracle.apps.bis.pmv.common.PMVConstants;
import oracle.apps.bis.pmv.common.PMVNLSServices;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.parameters.ComputedDateHelper;
import oracle.apps.bis.pmv.parameters.NonTimeParameterValidator;
import oracle.apps.bis.pmv.parameters.ParameterValidator;
import oracle.apps.bis.pmv.parameters.Parameters;
import oracle.apps.bis.pmv.parameters.TimeParamMapHandler;
import oracle.apps.bis.pmv.parameters.TimeParameter;
import oracle.apps.bis.pmv.parameters.TimeParameterValidator;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.AppsContext;
import oracle.apps.fnd.common.Context;
import oracle.apps.fnd.common.ProfileStore;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.functionSecurity.Function;
import oracle.sql.DATE;

// Referenced classes of package od.oracle.apps.xxcrm.bis.pmv.drill:
//            DrillFactory, DrillHelper, DrillJDBCUtil, DrillParameterValidator,
//            DrillSaveParameterHandler, DrillUtil, ParameterGroups

public abstract class ODDrillImpl
{

    public ODDrillImpl(javax.servlet.http.HttpServletRequest httpservletrequest, javax.servlet.jsp.PageContext pagecontext, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection)
    {
        m_IsDeleteAllParams = false;
        m_TCTExists = false;
        m_IsAsOfDateExists = false;
        m_IsPrevFuncTCTExist = false;
        m_IsPrevFuncCalcDatesExist = false;
        m_DisplayOnlyParameters = "";
        m_DisplayOnlyNoViewByParams = "";
        m_InsertedParamChkMap = new HashMap(3);
        m_Request = httpservletrequest;
        m_WebAppsContext = webappscontext;
        m_Connection = connection;
        m_PageContext = pagecontext;
        m_Session = pagecontext.getSession();
        m_UserId = java.lang.String.valueOf(webappscontext.getUserId());
        m_SessionId = webappscontext.getSessionId();
        java.lang.String s = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pRespId");
        if(s != null)
        {
            m_RespId = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getLong(s);
            m_RespAppId = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getLong(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pRespAppId"));
            m_SecGrpId = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getLong(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pSecGrpId"));
            if((long)m_WebAppsContext.getRespId() != m_RespId)
                m_WebAppsContext.updateSessionContext((new Long(m_RespAppId)).intValue(), (new Long(m_RespId)).intValue(), m_SecGrpId >= 0L ? (new Long(m_SecGrpId)).intValue() : 0);
        } else
        {
            m_RespId = m_WebAppsContext.getRespId();
            m_RespAppId = m_WebAppsContext.getRespApplId();
            m_SecGrpId = m_WebAppsContext.getSecurityGroupID();
        }
        if(m_SecGrpId < 0L)
            m_SecGrpId = 0L;
        m_UrlString = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pUrlString");
        if(m_UrlString != null && m_UrlString.startsWith("{!!"))
            m_UrlString = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.OADecrypt(webappscontext, m_UrlString);
        m_FunctionFrom = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pPreFunction");
        m_BCFromFunction = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pBCFromFunction");
        m_FunctionTo = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pFunction");
        m_PageId = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getPageId(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pPageId"));
        m_PageId = getPageId(m_PageId);
        m_ScheduleId = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pScheduleId");
        m_DBC = (java.lang.String)pagecontext.getAttribute("dbc");
        if(m_DBC == null)
            m_DBC = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "dbc");
        m_TxnId = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "transactionid");
        m_Enc = webappscontext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        m_DrillType = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pDrillType");
        m_HideNav = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "hideNav");
        m_Tab = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "tab");
    }

    public abstract void process();

    public abstract void redirect();

    protected void setRedirectUrl(java.lang.String s)
    {
        m_RedirectURL = s;
    }

    public java.lang.String getRedirectURL()
    {
        return m_RedirectURL;
    }

    protected com.sun.java.util.collections.ArrayList getParameterGroups(oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        od.oracle.apps.xxcrm.bis.pmv.drill.ODParameterGroups parametergroups = new ODParameterGroups(akregion);
        m_TCTExists = parametergroups.isTCTExists();
        m_IsAsOfDateExists = parametergroups.isAsOfDateExists();
        return parametergroups.getParameterGroups();
    }

    protected void insertParam(com.sun.java.util.collections.HashMap hashmap, oracle.apps.bis.pmv.parameters.Parameters parameters)
    {
        if(hashmap != null && parameters != null)
        {
            com.sun.java.util.collections.Set set = hashmap.keySet();
            com.sun.java.util.collections.Iterator iterator = set.iterator();
            Object obj = null;
            java.lang.String s1 = null;
            boolean flag = false;
            boolean flag1 = false;
            if(parameters.getParameterName().endsWith("_FROM"))
                flag = true;
            if(parameters.getParameterName().endsWith("_TO"))
                flag1 = true;
            while(iterator.hasNext())
            {
                java.lang.String s = (java.lang.String)iterator.next();
                if(flag && s.endsWith("_FROM"))
                    s1 = s;
                else
                if(flag1 && s.endsWith("_TO"))
                    s1 = s;
            }
            hashmap.remove(s1);
            hashmap.put(parameters.getParameterName(), parameters);
        }
    }

    protected void insertTCTParam(com.sun.java.util.collections.HashMap hashmap, java.lang.String s)
    {
        if(hashmap != null && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            com.sun.java.util.collections.Set set = hashmap.keySet();
            com.sun.java.util.collections.Iterator iterator = set.iterator();
            Object obj = null;
            java.lang.String s2 = null;
            while(iterator.hasNext())
            {
                java.lang.String s1 = (java.lang.String)iterator.next();
                if(s1.startsWith("TIME_COMPARISON_TYPE+"))
                    s2 = s1;
            }
            if(s2 != null)
                hashmap.remove(s2);
            hashmap.put(s, od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter(s, s, s, "TIME_COMPARISON_TYPE", null));
        }
    }

    protected void processParameters(com.sun.java.util.collections.ArrayList arraylist)
    {
        if(arraylist != null)
        {
            Object obj = null;
            for(int i = 0; i < arraylist.size(); i++)
            {
                oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)arraylist.get(i);
                if(parameters != null)
                    m_InsertParams.put(parameters.getParameterName(), parameters);
            }

        }
    }

    protected boolean hasPageDateParameters()
    {
        java.lang.String s = "SELECT attribute_name FROM bis_user_attributes WHERE user_id = :1 AND page_id = :2 AND attribute_name=:3";
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        try
        {
            preparedstatement = m_Connection.prepareStatement(s);
            preparedstatement.setString(1, m_UserId);
            preparedstatement.setString(2, m_PageId);
            preparedstatement.setString(3, "AS_OF_DATE");
            resultset = preparedstatement.executeQuery();
            if(resultset.next())
            {
                if(preparedstatement != null)
                    preparedstatement.close();
                if(resultset != null)
                    resultset.close();
                boolean flag = true;
                return flag;
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
            catch(java.sql.SQLException _ex) { }
        }
        return false;
    }

    protected com.sun.java.util.collections.ArrayList getPageParameters(oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        oracle.apps.bis.parameters.ServletParameterSetManager servletparametersetmanager = oracle.apps.bis.parameters.ServletParameterSetManager.getInstance(m_Session, m_WebAppsContext, m_Connection);
        oracle.apps.bis.parameters.ParameterSet parameterset = servletparametersetmanager.getParameterSet(m_PageId);
        com.sun.java.util.collections.Set set = parameterset.getParameterNames();
        com.sun.java.util.collections.Iterator iterator = set.iterator();
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(13);
        java.util.Hashtable hashtable = akregion.getAKRegionItems();
        Object obj = null;
        Object obj1 = null;
        oracle.apps.bis.pmv.parameters.Parameters parameters;
        for(; iterator.hasNext(); arraylist.add(parameters))
        {
            java.lang.String s = (java.lang.String)iterator.next();
            oracle.apps.bis.parameters.Parameter parameter = parameterset.getParameter(s);
            parameters = new Parameters();
            parameters.setParameterName(s);
            parameters.setParameterValue(parameter.getValueId());
            parameters.setParameterDescription(parameter.getValueName());
            parameters.setPeriod(parameter.getPeriod());
            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)hashtable.get(s);
            if(akregionitem != null)
                parameters.setDimension(akregionitem.getDimension());
        }

        return arraylist;
    }

    protected void processGroupedParameters(com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1, boolean flag, boolean flag1, boolean flag2)
    {
        resetInsertChkMap();
        if(arraylist != null)
        {
            Object obj = null;
            Object obj1 = null;
            Object obj2 = null;
            Object obj3 = null;
            for(int i = 0; i < arraylist.size(); i++)
            {
                oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)arraylist.get(i);
                java.lang.String s1 = parameters.getParameterName();
                com.sun.java.util.collections.ArrayList arraylist2 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillHelper.getAttrNamesInSameGroup(s1, parameters.getDimension(), arraylist1, m_UserSession.getAKRegion());
                boolean flag3 = arraylist2 != null && arraylist2.size() > 0;
                if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isTimeParameter(s1, m_UserSession.getAKRegion()))
                    m_InsertedParamChkMap.put("TIME", new Boolean(flag3));
                else
                if(s1 != null && s1.indexOf("TIME_COMPARISON_TYPE") != -1)
                    m_InsertedParamChkMap.put("TIME_COMPARISON_TYPE", new Boolean(flag3));
                if(flag3)
                {
                    java.lang.String s2 = null;
                    for(int j = 0; j < arraylist2.size(); j++)
                    {
                        java.lang.String s = (java.lang.String)arraylist2.get(j);
                        if(s1.lastIndexOf('+') > 0)
                            s2 = s1.substring(0, s1.lastIndexOf('+'));
                        if(s.equals(s2))
                        {
                            m_DeleteParams.add(s1);
                        } else
                        {
                            m_DeleteParams.add(s);
                            if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isTimeParameter(s, m_UserSession.getAKRegion()))
                            {
                                m_DeleteParams.add(s + "_TO");
                                m_DeleteParams.add(s + "_FROM");
                            }
                        }
                    }

                    if("TIME_COMPARISON_TYPE".equals(s2))
                        insertTCTParam(m_InsertParams, s1);
                    else
                        insertParam(m_InsertParams, parameters);
                } else
                if("VIEW_BY".equals(s1) && flag)
                {
                    if(m_UserSession.getAKRegion().isViewBy() && od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isValidViewBy(m_UserSession.getAKRegion(), parameters.getParameterValue()))
                    {
                        m_DeleteParams.add(s1);
                        m_InsertParams.put(s1, parameters);
                    }
                } else
                if("BUSINESS_PLAN".equals(s1) && (flag1 || m_InsertParams.containsKey(s1)) || "BIS_P_ASOF_DATE".equals(s1) && flag2 || "BIS_CUR_REPORT_START_DATE".equals(s1) && flag2 || "BIS_PREV_REPORT_START_DATE".equals(s1) && flag2 || "BIS_PREVIOUS_EFFECTIVE_START_DATE".equals(s1) && flag2 || "BIS_PREVIOUS_EFFECTIVE_END_DATE".equals(s1) && flag2)
                {
                    m_DeleteParams.add(s1);
                    m_InsertParams.put(s1, parameters);
                } else
                if(s1.endsWith("_HIERARCHY") && od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isDimensionInParamGroup(parameters.getDimension(), arraylist1))
                {
                    m_DeleteParams.add(s1);
                    m_InsertParams.put(s1, parameters);
                }
            }

        }
    }

    protected void deleteSameGroupParameters(java.lang.String s, com.sun.java.util.collections.ArrayList arraylist, java.lang.String s1, oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        com.sun.java.util.collections.ArrayList arraylist1 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDeleteAttrNames(s, arraylist, s1, akregion);
        if(arraylist1 != null)
        {
            for(int i = 0; i < arraylist1.size(); i++)
            {
                m_DeleteParams.add(arraylist1.get(i));
                m_InsertParams.remove(arraylist1.get(i));
            }

        }
    }

    protected void processGroupedParameters(java.lang.String s, java.lang.String s1, oracle.apps.bis.pmv.metadata.AKRegion akregion, com.sun.java.util.collections.ArrayList arraylist, java.lang.String s2)
    {
        com.sun.java.util.collections.ArrayList arraylist1 = null;
        if(m_UserSession.getPageContext() != null && m_UserSession.getPageContext().getSession() != null)
            arraylist1 = (com.sun.java.util.collections.ArrayList)m_UserSession.getPageContext().getSession().getValue("SHOW_HIDE_CACHE_KEY" + m_UserSession.getFunctionName());
        boolean flag = arraylist1 != null && arraylist1.size() > 0;
        if(m_FunctionTo.equals(m_FunctionFrom) && !flag && m_Mode != 2)
        {
            processSameFunctionParameters(s, s1, akregion, arraylist);
            return;
        }
        Object obj = null;
        m_IsDeleteAllParams = true;
        processReportFormFunctionParameters(s2);
        if(!"KPI".equals(m_DrillType))
            processFromSavedDefault(arraylist);
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            com.sun.java.util.collections.ArrayList arraylist2 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getScheduleParameters(s, m_Connection);
            if(hasPageDateParameters())
                od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.removeDateParams(arraylist2);
            processGroupedParameters(arraylist2, arraylist, true, false, true);
        } else
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_FunctionFrom) || m_Mode == 2)
        {
            java.lang.String s3 = m_Mode != 2 ? m_FunctionFrom : m_FunctionTo;
            com.sun.java.util.collections.ArrayList arraylist3 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getSessionParameters(s3, m_UserSession.getUserId(), m_UserSession.getSessionId(), m_Connection);
            if(arraylist3 != null)
            {
                Object obj1 = null;
                for(int i = 0; i < arraylist3.size(); i++)
                {
                    oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)arraylist3.get(i);
                    if(parameters.getParameterName() != null && parameters.getParameterName().startsWith("TIME_COMPARISON_TYPE+"))
                        m_IsPrevFuncTCTExist = true;
                    if("BIS_P_ASOF_DATE".equals(parameters.getParameterName()))
                        m_IsPrevFuncCalcDatesExist = true;
                }

            }
            processGroupedParameters(arraylist3, arraylist, true, true, true);
        }
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_PageId))
        {
            com.sun.java.util.collections.ArrayList arraylist4 = getPageParameters(akregion);
            processGroupedParameters(arraylist4, arraylist, true, false, true);
        }
        processTimeParameters(arraylist);
        processViewByParameter();
    }

    private void processViewByParameter()
    {
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_TimeAttribute))
        {
            oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)m_InsertParams.get("VIEW_BY");
            if(parameters != null)
            {
                java.lang.String s = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDimension(parameters.getParameterValue());
                if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isTimeParameter(parameters.getParameterValue(), m_UserSession.getAKRegion()))
                {
                    java.lang.String s1 = null;
                    if(m_TimeAttribute.endsWith("_FROM"))
                        s1 = m_TimeAttribute.substring(0, m_TimeAttribute.lastIndexOf("_FROM"));
                    else
                    if(m_TimeAttribute.endsWith("_TO"))
                        s1 = m_TimeAttribute.substring(0, m_TimeAttribute.lastIndexOf("_TO"));
                    m_InsertParams.put("VIEW_BY", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter("VIEW_BY", s1, s1, s, null));
                }
            }
        }
    }

    private void processSameFunctionParameters(java.lang.String s, java.lang.String s1, oracle.apps.bis.pmv.metadata.AKRegion akregion, com.sun.java.util.collections.ArrayList arraylist)
    {
        Object obj = null;
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            com.sun.java.util.collections.ArrayList arraylist1 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getScheduleParameters(s, m_Connection);
            processGroupedParameters(arraylist1, arraylist, false, false, true);
        }
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
        {
            com.sun.java.util.collections.ArrayList arraylist2 = getPageParameters(akregion);
            processGroupedParameters(arraylist2, arraylist, false, false, true);
        }
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1) && oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            com.sun.java.util.collections.ArrayList arraylist3 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getSessionParameters(m_FunctionTo, m_UserId, m_SessionId, m_Connection);
            processGroupedParameters(arraylist3, arraylist, true, false, true);
        }
    }

    private void processReportFormFunctionParameters(java.lang.String s)
    {
        com.sun.java.util.collections.Map map = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameters(s);
        java.lang.String s1 = null;
        if(map != null)
        {
            s1 = (java.lang.String)map.get("pParameters");
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString((java.lang.String)map.get("displayOnlyParameters")))
                addDisplayOnlyParameters((java.lang.String)map.get("displayOnlyParameters"));
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString((java.lang.String)map.get("displayOnlyNoViewByParams")))
                addDisplayOnlyNoViewByParams((java.lang.String)map.get("displayOnlyNoViewByParams"));
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
            {
                java.lang.String s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getUrlParamValue(s1, "pPLSQLFunction");
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
                    s1 = oracle.apps.bis.common.Util.getPLSQLFunctionParameters(s2, s1, m_UserSession.getConnection());
            }
        }
        processFormFunctionParameters(s1);
    }

    private void processFormFunctionParameters(java.lang.String s)
    {
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            m_UserSession.setParameters(s);
            s = m_UserSession.getParameters();
            java.lang.String s1 = "N";
            java.util.Hashtable hashtable = m_UserSession.getParameterHashTable(s, m_UserSession.getRegionCode());
            if("Y".equals(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s, "pParamIds")))
                s1 = "Y";
            Object obj = null;
            java.util.Enumeration enumeration = hashtable.keys();
            Object obj1 = null;
            Object obj2 = null;
            Object obj3 = null;
            java.lang.String s4 = null;
            boolean flag = false;
            java.lang.String s5 = null;
            java.lang.String s6 = "All";
            java.lang.String s7 = "All";
            java.lang.String s8 = null;
            java.lang.String s9 = null;
            oracle.apps.bis.pmv.parameters.NonTimeParameterValidator nontimeparametervalidator = new NonTimeParameterValidator();
            boolean flag1 = false;
            nonTimeFFParams = new HashMap(5);
            try
            {
                while(enumeration.hasMoreElements())
                {
                    java.lang.String s2 = (java.lang.String)enumeration.nextElement();
                    java.lang.String s3 = (java.lang.String)hashtable.get(s2);
                    oracle.apps.bis.pmv.parameters.Parameters parameters1 = new Parameters();
                    parameters1.setParameterName(s2);
                    parameters1.setParameterDescription(s3);
                    parameters1.setIdFlag(s1);
                    int i = s2.indexOf("+");
                    if(i > 0 && i < s2.length())
                        parameters1.setDimension(s2.substring(0, i));
                    if("VIEW_BY".equals(s2))
                    {
                        parameters1.setParameterValue(s3);
                        m_InsertParams.put(parameters1.getParameterName(), parameters1);
                    } else
                    if(s2.endsWith("_HIERARCHY"))
                    {
                        nontimeparametervalidator.getNonTimeValidatedValue(s2, s3, null, m_UserSession.getRegionCode(), m_UserSession.getResponsibilityId(), m_Connection, "Y", m_UserSession.getAKRegion(), null, null, m_WebAppsContext, m_UserSession);
                        parameters1.setParameterDescription(nontimeparametervalidator.getValue());
                        parameters1.setParameterValue(s3);
                        m_InsertParams.put(parameters1.getParameterName(), parameters1);
                    } else
                    if(s2.endsWith("_FROM"))
                    {
                        flag = true;
                        s5 = s2.substring(0, s2.indexOf("_FROM"));
                        if(s5 != null && s5.indexOf('+') < 0)
                            s5 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getAttr2FromAttrCode(m_UserSession.getAKRegion(), s5);
                        s6 = s3;
                    } else
                    if(s2.endsWith("_TO"))
                    {
                        flag = true;
                        s5 = s2.substring(0, s2.indexOf("_TO"));
                        if(s5 != null && s5.indexOf('+') < 0)
                            s5 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getAttr2FromAttrCode(m_UserSession.getAKRegion(), s5);
                        s7 = s3;
                    } else
                    if(s2.startsWith("TIME+"))
                    {
                        flag = true;
                        s5 = s2;
                    } else
                    if("AS_OF_DATE".equals(s2))
                    {
                        s8 = s3;
                    } else
                    {
                        if(s2.startsWith("TIME_COMPARISON_TYPE+"))
                            s9 = s2;
                        if("Y".equals(s1))
                        {
                            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)m_UserSession.getAKRegion().getAKRegionItems().get(s2);
                            if(akregionitem != null)
                                s4 = akregionitem.getLovWhereClause();
                            parameters1.setLovWhere(s4);
                        }
                        nonTimeFFParams.put(s2, parameters1);
                    }
                }
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_UserSession.getAKRegion().getPageParameterRegionName()))
                {
                    if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s8))
                    {
                        oracle.sql.DATE date = new DATE(new Date((new java.util.Date()).getTime()));
                        s8 = m_UserSession.getNLSServices().dateToString(date.dateValue(), "dd/MM/yyyy");
                    }
                    if(m_IsAsOfDateExists && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s5))
                    {
                        insertTCTParam(m_InsertParams, s9);
                        populateComputedDateParameters(s5, s9, s8);
                    }
                }
                if(flag && (oracle.apps.bis.pmv.common.StringUtil.emptyString(m_UserSession.getAKRegion().getPageParameterRegionName()) || !m_IsAsOfDateExists || oracle.apps.bis.pmv.common.StringUtil.emptyString(s5)))
                {
                    if("All".equals(s6) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_UserSession.getAKRegion().getPageParameterRegionName()) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s8))
                        if("Y".equals(s1))
                            s6 = m_TimeLevelId;
                        else
                            s6 = m_TimeLevelValue;
                    if("All".equals(s7) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_UserSession.getAKRegion().getPageParameterRegionName()) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s8))
                        if("Y".equals(s1))
                            s7 = m_TimeLevelId;
                        else
                            s7 = m_TimeLevelValue;
                    populateTimeParameters(s5, s6, s7, s1);
                }
            }
            catch(java.lang.Exception _ex) { }
        }
        if(m_UserSession.getAKRegion().hasMeasures() && m_InsertParams.get("BUSINESS_PLAN") == null)
        {
            oracle.apps.bis.pmv.parameters.Parameters parameters = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getBusinessPlanParameter(m_UserSession.getConnection());
            m_InsertParams.put("BUSINESS_PLAN", parameters);
        }
    }

    private void processFromSavedDefault(com.sun.java.util.collections.ArrayList arraylist)
    {
        com.sun.java.util.collections.ArrayList arraylist1 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getSavedDefaultParameters(m_FunctionTo, m_UserSession.getUserId(), m_Connection);
        processGroupedParameters(arraylist1, arraylist, true, true, false);
    }

    private void populateComputedDateParameters(java.lang.String s, java.lang.String s1, java.lang.String s2)
    {
        oracle.apps.bis.pmv.parameters.ComputedDateHelper computeddatehelper = new ComputedDateHelper(m_UserSession, m_UserSession.getRegionCode(), m_UserSession.getResponsibilityId(), s1, s2, s, m_UserSession.getConnection(), null, null);
        m_TimeLevelId = computeddatehelper.getTimeLevelId();
        m_TimeLevelValue = computeddatehelper.getTimeLevelValue();
        processAsOfDateParameter(s2);
        m_InsertParams.put("BIS_P_ASOF_DATE", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getComputedDateParameter("BIS_P_ASOF_DATE", computeddatehelper.getBisPAsOfDate(), m_UserSession.getNLSServices()));
        m_InsertParams.put("BIS_CUR_REPORT_START_DATE", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getComputedDateParameter("BIS_CUR_REPORT_START_DATE", computeddatehelper.getBisCurReportStartDate(), m_UserSession.getNLSServices()));
        m_InsertParams.put("BIS_PREV_REPORT_START_DATE", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getComputedDateParameter("BIS_PREV_REPORT_START_DATE", computeddatehelper.getBisPrevReportStartDate(), m_UserSession.getNLSServices()));
        m_InsertParams.put("BIS_PREVIOUS_EFFECTIVE_START_DATE", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter("BIS_PREVIOUS_EFFECTIVE_START_DATE", computeddatehelper.getPrevTimeLevelValue(), computeddatehelper.getPrevTimeLevelId(), null, computeddatehelper.getPrevEffectiveStartDATE()));
        m_InsertParams.put("BIS_PREVIOUS_EFFECTIVE_END_DATE", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter("BIS_PREVIOUS_EFFECTIVE_END_DATE", computeddatehelper.getPrevTimeLevelValue(), computeddatehelper.getPrevTimeLevelId(), null, computeddatehelper.getPrevEffectiveEndDATE()));
        java.lang.String s3 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDimension(s);
        insertParam(m_InsertParams, od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter(s + "_FROM", computeddatehelper.getTimeLevelValue(), computeddatehelper.getTimeLevelId(), s3, computeddatehelper.getCurrEffectiveStartDate()));
        insertParam(m_InsertParams, od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter(s + "_TO", computeddatehelper.getTimeLevelValue(), computeddatehelper.getTimeLevelId(), s3, computeddatehelper.getCurrEffectiveEndDate()));
        m_PeriodFrom = computeddatehelper.getCurrEffectiveStartDate();
        m_PeriodTo = computeddatehelper.getCurrEffectiveEndDate();
    }

    protected void processAsOfDateParameter(java.lang.String s)
    {
        oracle.sql.DATE date = null;
        try
        {
            date = oracle.apps.bis.common.SimpleDateUtil.getOracleDATE(s, oracle.apps.bis.common.SimpleDateUtil.getDefaultPMVDateFormat());
        }
        catch(java.lang.Exception _ex) { }
        m_InsertParams.put("AS_OF_DATE", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter("AS_OF_DATE", s, s, null, date));
    }

    protected void populateTimeParameters(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3)
    {
        java.lang.String s4 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDimension(s);
        oracle.apps.bis.pmv.parameters.TimeParameter timeparameter = new TimeParameter();
        timeparameter.setParameterName(s);
        timeparameter.setFromDescription(s1);
        timeparameter.setToDescription(s2);
        if(m_PeriodFrom != null)
            timeparameter.setPeriodFrom(m_PeriodFrom);
        if(m_PeriodTo != null)
            timeparameter.setPeriodTo(m_PeriodTo);
        timeparameter.setDimension(s4);
        timeparameter.setIdFlag(s3);
        Object obj = null;
        try
        {
            oracle.apps.bis.pmv.parameters.TimeParameterValidator timeparametervalidator = new TimeParameterValidator();
            java.lang.String as[] = timeparametervalidator.isValidParameter(timeparameter, m_UserSession);
            boolean flag = false;
            if(as != null)
            {
                boolean flag1 = (new Boolean(as[0])).booleanValue();
                if(flag1)
                {
                    oracle.apps.bis.pmv.parameters.Parameters parameters = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter(timeparameter.getParameterName() + "_FROM", timeparameter.getFromDescription(), timeparameter.getFromValue(), s4, timeparameter.getPeriodFrom());
                    insertParam(m_InsertParams, parameters);
                    parameters = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter(timeparameter.getParameterName() + "_TO", timeparameter.getToDescription(), timeparameter.getToValue(), s4, timeparameter.getPeriodTo());
                    insertParam(m_InsertParams, parameters);
                    return;
                }
            }
        }
        catch(java.lang.Exception _ex) { }
    }

    protected void validateParameters()
    {
        od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillParameterValidator drillparametervalidator = new ODDrillParameterValidator();
        m_DrillDefaultParameters = drillparametervalidator.getValidatedParameters(m_InsertParams, m_UserSession);
        oracle.apps.bis.pmv.parameters.TimeParamMapHandler timeparammaphandler = new TimeParamMapHandler(m_InsertParams, m_UserSession);
        timeparammaphandler.processParameters();
    }

    private void processTimeParameters(com.sun.java.util.collections.ArrayList arraylist)
    {
        com.sun.java.util.collections.ArrayList arraylist1 = getTimeFunctionParameters();
        if(!m_TCTExists && (od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isDimensionInParamGroup("TIME", arraylist) || od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isDimensionsInParamGroup(m_UserSession.getAKRegion().getBscTimeLevels(), arraylist)))
        {
            java.lang.String s = null;
            java.lang.String s2 = null;
            if(arraylist1 != null)
            {
                Object obj = null;
                for(int i = 0; i < arraylist1.size(); i++)
                {
                    oracle.apps.bis.pmv.parameters.Parameters parameters1 = (oracle.apps.bis.pmv.parameters.Parameters)arraylist1.get(i);
                    if("AS_OF_DATE".equals(parameters1.getParameterName()))
                        s = parameters1.getParameterValue();
                    else
                    if(parameters1.getParameterName().endsWith("_FROM"))
                        s2 = parameters1.getParameterName().substring(0, parameters1.getParameterName().indexOf("_FROM"));
                }

            }
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
                populateComputedDateParameters(s2, "TIME_COMPARISON_TYPE+SEQUENTIAL", s);
        } else
        if(m_TCTExists && !m_IsPrevFuncTCTExist && m_IsPrevFuncCalcDatesExist)
        {
            oracle.apps.bis.pmv.parameters.Parameters parameters = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getTimeComparisionParam(m_InsertParams);
            if(parameters == null)
                insertTCTParam(m_InsertParams, "TIME_COMPARISON_TYPE+SEQUENTIAL");
        } else
        if(!isTimeAndTCTPassed())
        {
            java.lang.String s1 = null;
            java.lang.String s3 = null;
            java.lang.String s4 = null;
            java.lang.String s5 = "N";
            oracle.apps.bis.pmv.parameters.Parameters parameters2 = null;
            oracle.apps.bis.pmv.parameters.Parameters parameters3 = null;
            if(arraylist1 != null)
            {
                Object obj1 = null;
                for(int j = 0; j < arraylist1.size(); j++)
                {
                    oracle.apps.bis.pmv.parameters.Parameters parameters4 = (oracle.apps.bis.pmv.parameters.Parameters)arraylist1.get(j);
                    if("AS_OF_DATE".equals(parameters4.getParameterName()))
                        s1 = parameters4.getParameterValue();
                    else
                    if(parameters4.getParameterName().endsWith("_FROM"))
                    {
                        s3 = parameters4.getParameterName().substring(0, parameters4.getParameterName().indexOf("_FROM"));
                        s5 = parameters4.getIdFlag();
                        parameters2 = parameters4;
                    } else
                    if(parameters4.getParameterName().endsWith("_TO"))
                        parameters3 = parameters4;
                }

            }
            oracle.apps.bis.pmv.parameters.Parameters parameters5 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getTimeComparisionParam(m_InsertParams);
            if(parameters5 != null)
                s4 = parameters5.getParameterDescription();
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s3) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s4))
            {
                populateComputedDateParameters(s3, s4, s1);
                if(parameters2 != null && "All".equals(parameters2.getParameterDescription()))
                {
                    if("Y".equals(s5))
                        parameters2.setParameterDescription(m_TimeLevelId);
                    else
                        parameters2.setParameterDescription(m_TimeLevelValue);
                    parameters2.setParameterValue(m_TimeLevelId);
                    parameters2.setPeriod(m_PeriodFrom);
                }
                if(parameters3 != null && "All".equals(parameters3.getParameterDescription()))
                {
                    if("Y".equals(s5))
                        parameters3.setParameterDescription(m_TimeLevelId);
                    else
                        parameters3.setParameterDescription(m_TimeLevelValue);
                    parameters3.setParameterValue(m_TimeLevelId);
                    parameters3.setPeriod(m_PeriodTo);
                }
            }
        }
        processGroupedParameters(arraylist1, arraylist, false, false, true);
    }

    private com.sun.java.util.collections.ArrayList getTimeFunctionParameters()
    {
        com.sun.java.util.collections.ArrayList arraylist = null;
        if(m_InsertParams != null)
        {
            com.sun.java.util.collections.Set set = m_InsertParams.keySet();
            com.sun.java.util.collections.Iterator iterator = set.iterator();
            Object obj = null;
            Object obj1 = null;
            arraylist = new ArrayList(3);
            while(iterator.hasNext())
            {
                java.lang.String s = (java.lang.String)iterator.next();
                oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)m_InsertParams.get(s);
                if("TIME".equals(parameters.getDimension()) || od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isBSCTimeLevel(parameters.getParameterName(), m_UserSession.getAKRegion()))
                {
                    m_TimeAttribute = parameters.getParameterName();
                    arraylist.add(parameters);
                } else
                if("AS_OF_DATE".equals(parameters.getParameterName()))
                    arraylist.add(parameters);
            }
        }
        return arraylist;
    }

    protected void processPageFormFunctionParameters()
    {
        java.lang.String s = oracle.apps.bis.database.JDBCUtil.getParameterPortletFunctionName(m_PageIdTo, m_UserId, m_Connection);
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
            s = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterPortletFunctionName(m_FunctionTo, m_Connection);
        oracle.apps.fnd.functionSecurity.Function function = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(s, m_WebAppsContext);
        if(function != null)
            processFormFunctionParameters(function.getParameters());
    }

    protected void processPageFromReport(com.sun.java.util.collections.ArrayList arraylist)
    {
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_PageIdTo))
        {
            com.sun.java.util.collections.ArrayList arraylist1 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getSessionParameters(m_FunctionFrom, m_UserId, m_SessionId, m_Connection);
            processGroupedParameters(arraylist1, arraylist, true, false, true);
        }
    }

    protected void processPageFromPage(com.sun.java.util.collections.ArrayList arraylist)
    {
        if(m_PageId.indexOf(",") <= 0 && !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_PageIdTo))
        {
            com.sun.java.util.collections.ArrayList arraylist1 = getPageParameters(m_UserSession.getAKRegion());
            processGroupedParameters(arraylist1, arraylist, true, false, true);
        }
    }

    protected void createParameters()
    {
        od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillSaveParameterHandler drillsaveparameterhandler = new ODDrillSaveParameterHandler(m_UserSession);
        drillsaveparameterhandler.deleteParameters(m_DeleteParams, m_IsDeleteAllParams);
        drillsaveparameterhandler.saveParameters(m_InsertParams);
    }

    protected void populateCommonReportParams()
    {
        m_ParamMap.put("regionCode", m_UserSession.getRegionCode());
        m_ParamMap.put("functionName", m_UserSession.getFunctionName());
        m_ParamMap.put("pSessionId", m_UserSession.getSessionId());
        m_ParamMap.put("pUserId", m_UserSession.getUserId());
        m_ParamMap.put("pResponsibilityId", m_UserSession.getResponsibilityId());
        m_ParamMap.put("pFirstTime", "0");
        m_ParamMap.put("pMode", "DRILL");
    }

    protected void processNonTimeFormFunctionParameters()
    {
        if(nonTimeFFParams != null && !nonTimeFFParams.isEmpty())
        {
            processContextParameters();
            populateAttrCodeAndAttrValue();
            com.sun.java.util.collections.Set set = nonTimeFFParams.keySet();
            com.sun.java.util.collections.Iterator iterator = set.iterator();
            Object obj = null;
            Object obj1 = null;
            new NonTimeParameterValidator();
            while(iterator.hasNext())
            {
                java.lang.String s = (java.lang.String)iterator.next();
                if(s.startsWith("TIME_COMPARISON_TYPE+"))
                {
                    oracle.apps.bis.pmv.parameters.Parameters parameters = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getTimeComparisionParam(m_InsertParams);
                    if(parameters == null)
                    {
                        oracle.apps.bis.pmv.parameters.Parameters parameters1 = (oracle.apps.bis.pmv.parameters.Parameters)nonTimeFFParams.get(s);
                        m_InsertParams.put(parameters1.getParameterName(), parameters1);
                    }
                } else
                if(!m_InsertParams.containsKey(s))
                {
                    oracle.apps.bis.pmv.parameters.Parameters parameters2 = (oracle.apps.bis.pmv.parameters.Parameters)nonTimeFFParams.get(s);
                    m_InsertParams.put(parameters2.getParameterName(), parameters2);
                }
            }
        }
    }

    private void processContextParameters()
    {
        if(!isSameContext() && nonTimeFFParams != null && !nonTimeFFParams.isEmpty())
        {
            com.sun.java.util.collections.Set set = nonTimeFFParams.keySet();
            com.sun.java.util.collections.Iterator iterator = set.iterator();
            Object obj = null;
            Object obj1 = null;
            while(iterator.hasNext())
            {
                java.lang.String s = (java.lang.String)iterator.next();
                oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = m_UserSession.getAKRegion().getAKRegionItem(s);
                if(akregionitem != null && "CONTEXT PARAMETER".equals(akregionitem.getRegionItemType()))
                    m_InsertParams.remove(s);
            }
        }
    }

    private boolean isSameContext()
    {
        return m_RespId == (long)m_WebAppsContext.getRespId() && m_RespAppId == (long)m_WebAppsContext.getRespApplId() && m_SecGrpId == (long)m_WebAppsContext.getSecurityGroupID();
    }

    protected void populateAttrCodeAndAttrValue()
    {
        if(m_InsertParams != null)
        {
            int i = m_InsertParams.size();
            m_AttrCode = new java.lang.String[i];
            m_AttrValue = new java.lang.String[i];
            Object obj = null;
            com.sun.java.util.collections.Set set = m_InsertParams.keySet();
            com.sun.java.util.collections.Iterator iterator = set.iterator();
            Object obj1 = null;
            for(int j = 0; iterator.hasNext(); j++)
            {
                java.lang.String s = (java.lang.String)iterator.next();
                oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)m_InsertParams.get(s);
                m_AttrCode[j] = s;
                if(parameters != null)
                    m_AttrValue[j] = parameters.getParameterValue();
            }

        }
    }

    protected void addToAttrCodeAndAttrValue(java.lang.String s, java.lang.String s1)
    {
        boolean flag = false;
        if(m_AttrCode != null && m_AttrValue != null && s != null)
        {
            for(int i = 0; i < m_AttrCode.length; i++)
            {
                if(!s.equals(m_AttrCode[i]))
                    continue;
                m_AttrValue[i] = s1;
                flag = true;
                break;
            }

            if(!flag)
                try
                {
                    java.lang.String as[] = new java.lang.String[m_AttrCode.length];
                    java.lang.String as1[] = new java.lang.String[m_AttrValue.length];
                    java.lang.System.arraycopy(m_AttrCode, 0, as, 0, m_AttrCode.length);
                    java.lang.System.arraycopy(m_AttrValue, 0, as1, 0, m_AttrValue.length);
                    m_AttrCode = new java.lang.String[m_AttrCode.length + 1];
                    m_AttrValue = new java.lang.String[m_AttrValue.length + 1];
                    java.lang.System.arraycopy(as, 0, m_AttrCode, 0, as.length);
                    java.lang.System.arraycopy(as1, 0, m_AttrValue, 0, as1.length);
                    m_AttrCode[as.length] = s;
                    m_AttrValue[as1.length] = s1;
                    return;
                }
                catch(java.lang.Exception _ex)
                {
                    return;
                }
        }
    }

    private java.lang.String getPageId(java.lang.String s)
    {
        if(s == null)
            return "";
        java.lang.String s1 = s;
        int i = s.indexOf(',');
        if(i > 0)
            s1 = s.substring(0, i);
        return s1;
    }

    protected void checkForOAPage(int i, java.lang.String s)
    {
        oracle.apps.fnd.functionSecurity.Function function = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(m_FunctionTo, m_WebAppsContext);
        if(function != null)
        {
            java.lang.String s1 = function.getWebHTMLCall();
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1) && !od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.isPMVReportFunction(s1) && s1.indexOf("OA.jsp") >= 0)
            {
                java.lang.StringBuffer stringbuffer = new StringBuffer(100);
                if(!od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.isPMVPageFunction(s1))
                {
                    stringbuffer.append(s1);
                    if(function.getParameters() != null)
                        stringbuffer.append("&").append(function.getParameters());
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
                        stringbuffer.append(s);
                } else
                {
                    stringbuffer.append(getRedirectURL());
                }
                if(stringbuffer.toString().indexOf("pMode") < 0 && od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillFactory.isValidMode(i))
                    stringbuffer.append("&pMode=").append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillFactory.drillModes[i]);
                stringbuffer.append("&pageFunctionName=").append(function.getFunctionName());
                if(stringbuffer.toString().indexOf("addBreadCrumb") < 0)
                    stringbuffer.append("&addBreadCrumb=Y");
                setRedirectUrl(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getOAMacUrl(stringbuffer.toString(), m_WebAppsContext));
            }
        }
    }

    protected void addURLParameters(java.lang.StringBuffer stringbuffer)
    {
        if(stringbuffer != null)
        {
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_HideNav))
                stringbuffer.append("&").append("hideNav").append("=").append(m_HideNav);
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_Tab))
                stringbuffer.append("&").append("tab").append("=").append(m_Tab);
            addBCParams(stringbuffer);
        }
    }

    private void addBCParams(java.lang.StringBuffer stringbuffer)
    {
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_BCFromFunction))
            stringbuffer.append("&pBCFromFunctionName=").append(m_BCFromFunction);
        if(_prevBreadCrumb != null)
        {
            stringbuffer.append("&pPrevBCInfo=").append(_prevBreadCrumb.getRespId());
            stringbuffer.append("^").append(_prevBreadCrumb.getRespAppId());
            stringbuffer.append("^").append(_prevBreadCrumb.getSecGrpId());
        }
    }

    public void setPrevBreadCrumb(oracle.apps.bis.pmv.breadcrumb.BreadCrumb breadcrumb)
    {
        _prevBreadCrumb = breadcrumb;
    }

    protected void addDisplayOnlyParameters(java.lang.String s)
    {
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(m_DisplayOnlyParameters))
        {
            m_DisplayOnlyParameters = s;
            return;
        }
        if(s.startsWith("&"))
        {
            m_DisplayOnlyParameters += s;
            return;
        } else
        {
            m_DisplayOnlyParameters += "&" + s;
            return;
        }
    }

    protected void addDisplayOnlyNoViewByParams(java.lang.String s)
    {
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(m_DisplayOnlyNoViewByParams))
        {
            m_DisplayOnlyNoViewByParams = s;
            return;
        }
        if(s.startsWith("&"))
        {
            m_DisplayOnlyNoViewByParams += s;
            return;
        } else
        {
            m_DisplayOnlyNoViewByParams += "&" + s;
            return;
        }
    }

    private void resetInsertChkMap()
    {
        if(m_InsertedParamChkMap != null)
            m_InsertedParamChkMap.clear();
    }

    private boolean isTimeAndTCTPassed()
    {
        if(m_InsertedParamChkMap != null)
        {
            boolean flag = false;
            boolean flag1 = false;
            java.lang.Boolean boolean1 = (java.lang.Boolean)m_InsertedParamChkMap.get("TIME");
            if(boolean1 != null)
                flag = boolean1.booleanValue();
            java.lang.Boolean boolean2 = (java.lang.Boolean)m_InsertedParamChkMap.get("TIME_COMPARISON_TYPE");
            if(boolean2 != null)
                flag1 = boolean2.booleanValue();
            return flag && flag1;
        } else
        {
            return false;
        }
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillImpl.java 115.64 2006/09/13 11:16:55 nbarik noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillImpl.java 115.64 2006/09/13 11:16:55 nbarik noship $", "od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillImpl");
    protected java.lang.String m_RedirectURL;
    protected oracle.apps.fnd.common.WebAppsContext m_WebAppsContext;
    protected java.sql.Connection m_Connection;
    protected javax.servlet.http.HttpServletRequest m_Request;
    protected javax.servlet.jsp.PageContext m_PageContext;
    protected javax.servlet.http.HttpSession m_Session;
    protected java.lang.String m_UserId;
    protected java.lang.String m_SessionId;
    protected java.lang.String m_FunctionFrom;
    protected java.lang.String m_BCFromFunction;
    protected java.lang.String m_FunctionTo;
    protected java.lang.String m_PageId;
    protected java.lang.String m_PageIdTo;
    protected java.lang.String m_ScheduleId;
    protected java.lang.String m_TxnId;
    protected java.lang.String m_DBC;
    protected oracle.apps.bis.msg.MessageLog m_PmvMsgLog;
    protected boolean m_IsDeleteAllParams;
    protected com.sun.java.util.collections.HashMap m_InsertParams;
    protected com.sun.java.util.collections.HashSet m_DeleteParams;
    protected com.sun.java.util.collections.Map m_ParamMap;
    protected oracle.apps.bis.pmv.session.UserSession m_UserSession;
    protected boolean m_TCTExists;
    protected boolean m_IsAsOfDateExists;
    protected boolean m_IsPrevFuncTCTExist;
    protected boolean m_IsPrevFuncCalcDatesExist;
    protected java.lang.String m_TimeLevelId;
    protected java.lang.String m_TimeLevelValue;
    protected java.lang.String m_TimeAttribute;
    protected java.lang.String m_DrillDefaultParameters;
    protected java.lang.String m_Enc;
    protected java.lang.String m_AttrCode[];
    protected java.lang.String m_AttrValue[];
    protected oracle.sql.DATE m_PeriodFrom;
    protected oracle.sql.DATE m_PeriodTo;
    protected int m_Mode;
    private com.sun.java.util.collections.HashMap nonTimeFFParams;
    protected java.lang.String m_DrillType;
    protected java.lang.String m_HideNav;
    protected java.lang.String m_Tab;
    protected java.lang.String m_DisplayOnlyParameters;
    protected java.lang.String m_DisplayOnlyNoViewByParams;
    private com.sun.java.util.collections.HashMap m_InsertedParamChkMap;
    protected java.lang.String m_UrlString;
    protected long m_RespId;
    protected long m_RespAppId;
    protected long m_SecGrpId;
    private oracle.apps.bis.pmv.breadcrumb.BreadCrumb _prevBreadCrumb;

}
