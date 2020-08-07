// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODDrillAcrossImpl.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.HashSet;
import com.sun.java.util.collections.Iterator;
import com.sun.java.util.collections.Map;
import com.sun.java.util.collections.Set;
import java.sql.Connection;
import java.util.Hashtable;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.common.SimpleDateUtil;
import oracle.apps.bis.database.JDBCUtil;
import oracle.apps.bis.pmv.PMVException;
import oracle.apps.bis.pmv.common.PMVConstants;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.parameters.ComputedDateHelper;
import oracle.apps.bis.pmv.parameters.NonTimeParameterValidator;
import oracle.apps.bis.pmv.parameters.Parameters;
import oracle.apps.bis.pmv.parameters.SaveParameterUtil;
import oracle.apps.bis.pmv.portlet.Portlet;
import oracle.apps.bis.pmv.session.RequestInfo;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.functionSecurity.Function;

// Referenced classes of package od.oracle.apps.xxcrm.bis.pmv.drill:
//            DrillImpl, DrillHelper, DrillUtil

public class ODDrillAcrossImpl extends od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillImpl
{

    public ODDrillAcrossImpl(javax.servlet.http.HttpServletRequest httpservletrequest, javax.servlet.jsp.PageContext pagecontext, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection)
    {
        super(httpservletrequest, pagecontext, webappscontext, connection);
        m_IsToPMVPage = false;
        m_IsToPMVReport = false;
        m_IsDrillAndPivot = false;
        m_HasAccess = true;
        m_Designer = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "designer");
        super.m_Mode = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getMode(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pMode"));
    }

    public void redirect()
    {
        if(super.m_UrlString != null && super.m_UrlString.toUpperCase().startsWith("HTTP"))
        {
            setRedirectUrl(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getEncodedUrl(super.m_UrlString, super.m_Enc));
            return;
        }
        if(!m_HasAccess)
            return;
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        boolean flag = true;
        boolean flag1 = true;
        if(m_IsDrillAndPivot)
            flag1 = !od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isPMVTablePortletFunction(super.m_FunctionTo, super.m_WebAppsContext);
        boolean flag2 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.canFunctionUseRFCall(super.m_FunctionTo, super.m_WebAppsContext) && flag1 && m_IsToPMVReport;
        java.lang.String s = (java.lang.String)oracle.apps.bis.common.ServletWrapper.getSessionValue(super.m_PageContext, "bisdf");
        if(flag2)
        {
            java.lang.String s1 = null;
            if(super.m_ParamMap != null)
                s1 = (java.lang.String)super.m_ParamMap.get("pMode");
            if(s1 == null)
                s1 = "DRILL";
            stringbuffer.append("pMode=" + s1);
        } else
        if(m_IsToPMVReport || m_IsDrillAndPivot || super.m_FunctionTo.equals(s))
        {
            flag = false;
            stringbuffer.append("../XXCRM_HTML/bisviewm.jsp?").append("dbc").append("=").append(super.m_DBC);
            if(m_Designer != null && "Y".equals(m_Designer))
                stringbuffer.append("&designer=Y&pMode=DRILL");
            stringbuffer.append("&").append("transactionid").append("=").append(super.m_TxnId);
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getURLParameters(super.m_ParamMap, super.m_Enc));
        } else
        {
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getURLParameters(super.m_ParamMap));
        }
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_DrillDefaultParameters))
            super.m_Session.putValue("DrillDefaultParameters", super.m_DrillDefaultParameters);
        addURLParameters(stringbuffer);
        if(super.m_UserSession != null && super.m_UserSession.getLookUpHelperHashMap() != null)
            super.m_Session.putValue("PMV_LOOKUPHELPER_OBJECTS", super.m_UserSession.getLookUpHelperHashMap());
        if(!m_IsToPMVReport && !m_IsDrillAndPivot && !super.m_FunctionTo.equals(s))
            setRedirectUrl(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getRunFunctionURL(super.m_FunctionTo, stringbuffer.toString(), super.m_WebAppsContext, super.m_RespId, super.m_RespAppId, super.m_SecGrpId));
        else
        if(flag2)
            setRedirectUrl(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getRunFunctionURL(super.m_FunctionTo, stringbuffer.toString(), super.m_WebAppsContext, super.m_RespId, super.m_RespAppId, super.m_SecGrpId));
        else
            setRedirectUrl(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getEncodedUrl(stringbuffer.toString(), super.m_Enc));
        if(flag)
            checkForOAPage(super.m_Mode, stringbuffer.toString());
    }

    public void process()
    {
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_UrlString))
            return;
        if(super.m_UrlString.toUpperCase().startsWith("HTTP"))
            return;
        super.m_InsertParams = new HashMap(13);
        super.m_DeleteParams = new HashSet(13);
        com.sun.java.util.collections.Map map = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getURLParameters(super.m_UrlString);
        boolean flag = false;
        java.lang.String s = null;
        java.lang.String s1 = (java.lang.String)oracle.apps.bis.common.ServletWrapper.getSessionValue(super.m_PageContext, "bisdf");
        if(map != null)
        {
            super.m_FunctionTo = (java.lang.String)map.get("pFunctionName");
            map.remove("pFunctionName");
            flag = "Y".equals(map.get("pParamIds"));
            m_IsDrillAndPivot = "Y".equals(map.get("pDrillPivot"));
            s = (java.lang.String)map.get("pCustomView");
            if(map != null && !oracle.apps.bis.pmv.common.StringUtil.emptyString((java.lang.String)map.get("displayOnlyParameters")))
                addDisplayOnlyParameters((java.lang.String)map.get("displayOnlyParameters"));
            if(map != null && !oracle.apps.bis.pmv.common.StringUtil.emptyString((java.lang.String)map.get("displayOnlyNoViewByParams")))
                addDisplayOnlyNoViewByParams((java.lang.String)map.get("displayOnlyNoViewByParams"));
        }
        if(super.m_FunctionTo == null && super.m_UrlString.indexOf("pFunctionName") >= 0)
        {
            int i = super.m_UrlString.indexOf("&");
            int j = super.m_UrlString.indexOf("pFunctionName");
            if(i == 0)
            {
                super.m_UrlString = super.m_UrlString.substring(1, super.m_UrlString.length());
                i = super.m_UrlString.indexOf("&");
                j = super.m_UrlString.indexOf("pFunctionName");
            }
            if(i < 0)
                super.m_FunctionTo = super.m_UrlString.substring(14, super.m_UrlString.length());
            else
            if(j >= 0 && i > j)
                super.m_FunctionTo = super.m_UrlString.substring(14, i);
        }
        oracle.apps.fnd.functionSecurity.Function function = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(super.m_FunctionTo, super.m_WebAppsContext);
        boolean flag1 = super.m_FunctionTo.equals(s1) && function == null;
        java.lang.String s2 = null;
        java.lang.String s3 = null;
        if(function != null)
        {
            s2 = function.getWebHTMLCall();
            s3 = function.getParameters();
        }
        m_IsToPMVReport = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.isPMVReportFunction(s2) || od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isPMVTablePortletFunction(super.m_FunctionTo, super.m_WebAppsContext);
        java.lang.String s4 = null;
        try
        {
            if(!m_IsToPMVReport && !m_IsDrillAndPivot && !flag1)
            {
                java.lang.String s6 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.hasFunctionAccess(super.m_UserId, super.m_FunctionTo, "N", super.m_Connection);
                if("N".equals(s6) && !"FND_WFNTF_DETAILS".equals(super.m_FunctionTo))
                {
                    java.lang.String s7 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_REPORT_NO_ACCESS", super.m_WebAppsContext);
                    setRedirectUrl(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getErrorUrl(super.m_WebAppsContext, s7, super.m_Request, super.m_FunctionTo, null));
                    m_HasAccess = false;
                    return;
                }
                m_IsToPMVPage = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.isPMVPageFunction(s2);
                if(m_IsToPMVPage)
                {
                    super.m_PageIdTo = java.lang.String.valueOf(-function.getFunctionID());
                    java.lang.String s8 = oracle.apps.bis.database.JDBCUtil.getParameterPortletFunctionName(super.m_PageIdTo, super.m_UserId, super.m_Connection);
                    if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s8))
                        s8 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterPortletFunctionName(super.m_FunctionTo, super.m_Connection);
                    oracle.apps.fnd.functionSecurity.Function function2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(s8, super.m_WebAppsContext);
                    s4 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getReportRegion(function2.getWebHTMLCall(), function2.getParameters());
                    super.m_UserSession = new UserSession(s8, s4, super.m_WebAppsContext, null, super.m_Connection, super.m_PmvMsgLog);
                    oracle.apps.bis.pmv.session.RequestInfo requestinfo = new RequestInfo();
                    requestinfo.setPageId(super.m_PageIdTo);
                    requestinfo.setRequestType("P");
                    super.m_UserSession.setRequestInfo(requestinfo);
                }
            } else
            if(m_Designer != null && "Y".equals(m_Designer))
            {
                oracle.apps.bis.pmv.metadata.AKRegion akregion = (oracle.apps.bis.pmv.metadata.AKRegion)super.m_PageContext.getSession().getValue("BIS_PMV_DSGN_AK_REGION");
                if(akregion != null)
                    s4 = akregion.getRegionCode();
                super.m_UserSession = new UserSession(super.m_FunctionTo, s4, super.m_WebAppsContext, akregion);
            } else
            {
                java.lang.String s5;
                if(flag1)
                    s5 = (java.lang.String)map.get("pRegionCode");
                else
                    s5 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getReportRegion(s2, s3);
                super.m_UserSession = new UserSession(super.m_FunctionTo, s5, super.m_WebAppsContext, null, super.m_Connection, super.m_PmvMsgLog);
            }
            if(m_IsToPMVPage && !oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_UserSession.getRegionCode()) || m_IsToPMVReport || m_IsDrillAndPivot || flag1)
            {
                super.m_UserSession.setPageContext(super.m_PageContext);
                com.sun.java.util.collections.ArrayList arraylist = getParameterGroups(super.m_UserSession.getAKRegion());
                if(m_IsToPMVPage)
                {
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_PageId))
                    {
                        processPageFromPage(arraylist);
                    } else
                    {
                        oracle.apps.fnd.functionSecurity.Function function1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(super.m_FunctionFrom, super.m_WebAppsContext);
                        if(function1 != null && od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.isPMVReportFunction(function1.getWebHTMLCall()))
                            processPageFromReport(arraylist);
                        else
                            processPageFormFunctionParameters();
                    }
                } else
                if(m_IsToPMVReport || m_IsDrillAndPivot || flag1)
                    processGroupedParameters(super.m_ScheduleId, super.m_PageId, super.m_UserSession.getAKRegion(), arraylist, s3);
                processSpecialParameters(map, super.m_UserSession.getAKRegion(), arraylist, flag, m_IsToPMVReport, m_IsDrillAndPivot);
                if(m_IsToPMVReport || m_IsDrillAndPivot || flag1)
                {
                    super.m_ParamMap = new HashMap(11);
                    populateCommonReportParams();
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s3))
                    {
                        super.m_ParamMap.put("pDispRun", od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s3, "pDispRun"));
                        super.m_ParamMap.put("pEnableForecastGraph", od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s3, "pEnableForecastGraph"));
                        super.m_ParamMap.put("parameterDisplayOnly", oracle.apps.bis.pmv.common.StringUtil.evl(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s3, "pParameterDisplayOnly"), "N"));
                        super.m_ParamMap.put("displayParameters", oracle.apps.bis.pmv.common.StringUtil.evl(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s3, "pDisplayParameters"), "Y"));
                        super.m_ParamMap.put("requestType", oracle.apps.bis.pmv.common.StringUtil.evl(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s3, "pRequestType"), "R"));
                        super.m_ParamMap.put("showSchedule", oracle.apps.bis.pmv.common.StringUtil.evl(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s3, "pReportSchedule"), "Y"));
                    }
                    if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s3))
                        super.m_ParamMap.put("pCustomView", od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s3, "pCustomView"));
                    else
                        super.m_ParamMap.put("pCustomView", s);
                    super.m_ParamMap.put("pPreFunctionName", super.m_FunctionFrom);
                    super.m_ParamMap.put("pBCFromFunctionName", super.m_BCFromFunction);
                }
                processNonTimeFormFunctionParameters();
                if(m_Designer == null || !"Y".equals(m_Designer))
                    validateParameters();
                try
                {
                    createParameters();
                    return;
                }
                catch(java.lang.Exception _ex)
                {
                    return;
                }
            } else
            {
                super.m_ParamMap = map;
                return;
            }
        }
        catch(java.lang.Exception _ex)
        {
            return;
        }
    }

    private void processSpecialParameters(com.sun.java.util.collections.Map map, oracle.apps.bis.pmv.metadata.AKRegion akregion, com.sun.java.util.collections.ArrayList arraylist, boolean flag, boolean flag1, boolean flag2)
        throws oracle.apps.bis.pmv.PMVException
    {
        if(map != null && map.size() > 0)
        {
            com.sun.java.util.collections.Set set = map.keySet();
            com.sun.java.util.collections.Iterator iterator = set.iterator();
            Object obj = null;
            Object obj1 = null;
            Object obj2 = null;
            Object obj3 = null;
            Object obj4 = null;
            boolean flag3 = false;
            com.sun.java.util.collections.ArrayList arraylist1 = new ArrayList(5);
            Object obj5 = null;
            oracle.apps.bis.pmv.parameters.NonTimeParameterValidator nontimeparametervalidator = new NonTimeParameterValidator();
            boolean flag4 = false;
            boolean flag5 = false;
            java.lang.String s5 = null;
            java.lang.String s6 = null;
            java.lang.String s7 = null;
            boolean flag6 = false;
            boolean flag7 = false;
            java.lang.String s8 = null;
            java.lang.String s9 = null;
            Object obj6 = null;
            if(flag)
                populateAttrCodeAndAttrValue();
            while(iterator.hasNext())
            {
                java.lang.String s = (java.lang.String)iterator.next();
                if(!"pParamIds".equals(s) && !"pDrillPivot".equals(s) && !"pCustomView".equals(s))
                {
                    java.lang.String s1 = (java.lang.String)map.get(s);
                    java.lang.String s3 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getAttr2FromAttrCode(akregion, s);
                    java.lang.String s4 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDimension(s3);
                    if("TIME".equals(s3) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_TimeAttribute))
                    {
                        s4 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDimension(super.m_TimeAttribute);
                        flag3 = true;
                        if(super.m_TimeAttribute.endsWith("_FROM"))
                            s3 = super.m_TimeAttribute.substring(0, super.m_TimeAttribute.lastIndexOf("_FROM"));
                        else
                        if(super.m_TimeAttribute.endsWith("_TO"))
                            s3 = super.m_TimeAttribute.substring(0, super.m_TimeAttribute.lastIndexOf("_TO"));
                    }
                    if("VIEW_BY".equals(s3))
                    {
                        arraylist1.clear();
                        arraylist1.add("VIEW_BY");
                    } else
                    {
                        arraylist1 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillHelper.getAttrNamesInSameGroup(s3, s4, arraylist, akregion);
                    }
                    deleteSameGroupParameters(s4, arraylist1, s3, akregion);
                    if(s.endsWith("_HIERARCHY"))
                    {
                        java.lang.String s10 = oracle.apps.bis.pmv.portlet.Portlet.getHierarchyElementId(s1, s4, super.m_Connection);
                        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s10) && java.lang.Integer.parseInt(s10) > 0)
                        {
                            oracle.apps.bis.pmv.parameters.Parameters parameters = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter(s3, null, s10, null, null, null, "Y", null);
                            java.lang.String as1[] = null;
                            try
                            {
                                as1 = nontimeparametervalidator.isValidParameter(parameters, super.m_UserSession, null, null, null);
                            }
                            catch(java.lang.Exception _ex) { }
                            if(as1 != null)
                            {
                                boolean flag8 = (new Boolean(as1[0])).booleanValue();
                                if(flag8)
                                    super.m_InsertParams.put(parameters.getParameterName(), parameters);
                            }
                        }
                    } else
                    if(s.endsWith("_FROM"))
                    {
                        flag4 = true;
                        if(s3.indexOf("_FROM") > 0 && s3.indexOf('+') > 0)
                            s5 = s.substring(0, s3.indexOf("_FROM"));
                        else
                            s5 = s3;
                        s6 = oracle.apps.bis.pmv.common.StringUtil.evl(s1, "All");
                    } else
                    if(s.endsWith("_TO"))
                    {
                        flag4 = true;
                        if(s3.indexOf("_TO") > 0 && s3.indexOf('+') > 0)
                            s5 = s.substring(0, s3.indexOf("_TO"));
                        else
                            s5 = s3;
                        s7 = oracle.apps.bis.pmv.common.StringUtil.evl(s1, "All");
                    } else
                    if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isTimeParameter(s3, akregion))
                    {
                        flag4 = true;
                        s5 = s3;
                        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_TimeAttribute) && flag3)
                            if(flag6)
                            {
                                s7 = oracle.apps.bis.pmv.common.StringUtil.evl(s1, "All");
                                flag6 = false;
                            } else
                            {
                                s6 = oracle.apps.bis.pmv.common.StringUtil.evl(s1, "All");
                                s7 = oracle.apps.bis.pmv.common.StringUtil.evl(s1, "All");
                                flag6 = true;
                            }
                    } else
                    if("AS_OF_DATE".equals(s))
                    {
                        flag4 = true;
                        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                            s8 = oracle.apps.bis.common.SimpleDateUtil.getSYSDATEString(oracle.apps.bis.common.SimpleDateUtil.getDefaultPMVDateFormat());
                        else
                            s8 = s1;
                        processAsOfDateParameter(s8);
                    } else
                    if(s.startsWith("TIME_COMPARISON_TYPE"))
                    {
                        s9 = s1;
                        super.m_InsertParams.put("TIME_COMPARISON_TYPE", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter("TIME_COMPARISON_TYPE", s9, s9, "TIME_COMPARISON_TYPE", null));
                    } else
                    {
                        java.lang.String s11 = null;
                        java.lang.String s13 = "N";
                        if(flag)
                        {
                            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                                s11 = oracle.apps.bis.pmv.common.StringUtil.evl(s1, "All");
                            s13 = "Y";
                            addToAttrCodeAndAttrValue(s3, s11);
                        }
                        if("VIEW_BY".equals(s))
                            if(!s1.startsWith("EDW_TIME_M+") && od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isTimeLevelStarts(s1, akregion) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_TimeAttribute))
                            {
                                if(super.m_TimeAttribute.endsWith("_FROM"))
                                    s11 = super.m_TimeAttribute.substring(0, super.m_TimeAttribute.lastIndexOf("_FROM"));
                                else
                                if(super.m_TimeAttribute.endsWith("_TO"))
                                    s11 = super.m_TimeAttribute.substring(0, super.m_TimeAttribute.lastIndexOf("_TO"));
                                else
                                    s11 = super.m_TimeAttribute;
                            } else
                            {
                                s11 = s1;
                            }
                        oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)akregion.getAKRegionItems().get(oracle.apps.bis.pmv.common.StringUtil.evl(s3, s));
                        java.lang.String s2 = null;
                        if(akregionitem != null && flag)
                            s2 = akregionitem.getLovWhereClause();
                        oracle.apps.bis.pmv.parameters.Parameters parameters1 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter(oracle.apps.bis.pmv.common.StringUtil.evl(s3, s), oracle.apps.bis.pmv.common.StringUtil.evl(s1, "All"), s11, s4, s2, s13, "N", null);
                        if("VIEW_BY".equals(s))
                        {
                            if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isValidViewBy(akregion, parameters1.getParameterValue()))
                            {
                                oracle.apps.bis.pmv.parameters.Parameters parameters5 = (oracle.apps.bis.pmv.parameters.Parameters)super.m_InsertParams.get("VIEW_BY");
                                if(parameters5 != null && "KPI".equals(super.m_DrillType))
                                {
                                    if(!od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.checkIfViewByExists(parameters5.getParameterValue(), akregion))
                                        super.m_InsertParams.put(parameters1.getParameterName(), parameters1);
                                } else
                                {
                                    super.m_InsertParams.put(parameters1.getParameterName(), parameters1);
                                }
                            }
                        } else
                        {
                            super.m_InsertParams.put(parameters1.getParameterName(), parameters1);
                        }
                    }
                    if("VIEW_BY".equals(s))
                        flag5 = true;
                }
            }
            if(flag4 && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s5) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_UserSession.getRegionCode()))
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s8))
                {
                    if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s9))
                    {
                        oracle.apps.bis.pmv.parameters.Parameters parameters2 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getTimeComparisionParam(super.m_InsertParams);
                        if(parameters2 != null)
                            s9 = parameters2.getParameterValue();
                    }
                    oracle.apps.bis.pmv.parameters.ComputedDateHelper computeddatehelper = new ComputedDateHelper(super.m_UserSession, super.m_UserSession.getRegionCode(), super.m_UserSession.getResponsibilityId(), s9, s8, s5, super.m_UserSession.getConnection(), null, null);
                    oracle.apps.bis.pmv.parameters.Parameters parameters3 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter(s5 + "_FROM", computeddatehelper.getTimeLevelValue(), computeddatehelper.getTimeLevelId(), od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDimension(s5), computeddatehelper.getCurrEffectiveStartDate());
                    insertParam(super.m_InsertParams, parameters3);
                    parameters3 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter(s5 + "_TO", computeddatehelper.getTimeLevelValue(), computeddatehelper.getTimeLevelId(), od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDimension(s5), computeddatehelper.getCurrEffectiveEndDate());
                    insertParam(super.m_InsertParams, parameters3);
                    super.m_InsertParams.put("BIS_P_ASOF_DATE", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getComputedDateParameter("BIS_P_ASOF_DATE", computeddatehelper.getBisPAsOfDate(), super.m_UserSession.getNLSServices()));
                    super.m_InsertParams.put("BIS_CUR_REPORT_START_DATE", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getComputedDateParameter("BIS_CUR_REPORT_START_DATE", computeddatehelper.getBisCurReportStartDate(), super.m_UserSession.getNLSServices()));
                    super.m_InsertParams.put("BIS_PREV_REPORT_START_DATE", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getComputedDateParameter("BIS_PREV_REPORT_START_DATE", computeddatehelper.getBisPrevReportStartDate(), super.m_UserSession.getNLSServices()));
                    super.m_InsertParams.put("BIS_PREVIOUS_EFFECTIVE_START_DATE", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter("BIS_PREVIOUS_EFFECTIVE_START_DATE", computeddatehelper.getPrevTimeLevelValue(), computeddatehelper.getPrevTimeLevelId(), null, computeddatehelper.getPrevEffectiveStartDATE()));
                    super.m_InsertParams.put("BIS_PREVIOUS_EFFECTIVE_END_DATE", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter("BIS_PREVIOUS_EFFECTIVE_END_DATE", computeddatehelper.getPrevTimeLevelValue(), computeddatehelper.getPrevTimeLevelId(), null, computeddatehelper.getPrevEffectiveEndDATE()));
                } else
                {
                    java.lang.String s12 = "N";
                    if(flag)
                        s12 = "Y";
                    populateTimeParameters(s5, s6, s7, s12);
                }
            if((flag1 || flag2) && !flag5 && akregion.isViewBy())
            {
                oracle.apps.bis.pmv.parameters.Parameters parameters4 = (oracle.apps.bis.pmv.parameters.Parameters)super.m_InsertParams.get("VIEW_BY");
                if(parameters4 == null)
                {
                    java.lang.String as[] = new java.lang.String[2];
                    as[0] = null;
                    as[1] = "INVALID_VIEWBY";
                    throw new PMVException(oracle.apps.bis.pmv.parameters.SaveParameterUtil.getErrorMessage(as, super.m_WebAppsContext));
                }
                if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isTimeParameter(parameters4.getParameterValue(), akregion))
                {
                    com.sun.java.util.collections.HashMap hashmap = new HashMap(super.m_InsertParams);
                    com.sun.java.util.collections.Set set1 = hashmap.keySet();
                    for(com.sun.java.util.collections.Iterator iterator1 = set1.iterator(); iterator1.hasNext();)
                    {
                        java.lang.String s14 = (java.lang.String)iterator1.next();
                        if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isTimeParameter(s14, akregion))
                        {
                            if(s14.endsWith("_FROM"))
                                s14 = s14.substring(0, s14.indexOf("_FROM"));
                            else
                            if(s14.endsWith("_TO"))
                                s14 = s14.substring(0, s14.indexOf("_TO"));
                            java.lang.String s15;
                            if(s14.startsWith("EDW_TIME_M+"))
                                s15 = "EDW_TIME_M";
                            else
                            if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isBSCTimeLevel(s14, akregion))
                                s15 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDimension(s14);
                            else
                                s15 = "TIME";
                            super.m_DeleteParams.add("VIEW_BY");
                            super.m_InsertParams.put("VIEW_BY", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter("VIEW_BY", s14, s14, s15, null));
                            return;
                        }
                    }

                }
            }
        }
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillAcrossImpl.java 115.52 2006/09/13 11:20:03 nbarik noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillAcrossImpl.java 115.52 2006/09/13 11:20:03 nbarik noship $", "od.oracle.apps.xxcrm.bis.pmv.drill");
    private boolean m_IsToPMVPage;
    private boolean m_IsToPMVReport;
    private boolean m_IsDrillAndPivot;
    private java.lang.String m_Designer;
    private boolean m_HasAccess;

}
