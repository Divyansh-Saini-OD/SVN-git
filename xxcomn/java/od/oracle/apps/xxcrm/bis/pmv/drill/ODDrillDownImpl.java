// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODDrillDownImpl.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.HashSet;
import com.sun.java.util.collections.Map;
import java.sql.Connection;
import java.util.Enumeration;
import java.util.Hashtable;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.pmv.common.PMVConstants;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.parameters.NonTimeParameterValidator;
import oracle.apps.bis.pmv.parameters.ParameterValidator;
import oracle.apps.bis.pmv.parameters.TimeParameterValidator;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.functionSecurity.Function;

// Referenced classes of package od.oracle.apps.xxcrm.bis.pmv.drill:
//            DrillImpl, DrillDownHelper, DrillHelper, DrillJDBCUtil,
//            DrillUtil

public class ODDrillDownImpl extends od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillImpl
{

    public ODDrillDownImpl(javax.servlet.http.HttpServletRequest httpservletrequest, javax.servlet.jsp.PageContext pagecontext, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection)
    {
        super(httpservletrequest, pagecontext, webappscontext, connection);
        m_RegionCode = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pRegionCode");
        m_Dimension = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pDimension");
        m_CurrAttrCode = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pCurrAttCode");
        m_CurrValueId = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pCurrValueId");
        m_CurrLevel = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pCurrLevel");
        m_CurrValue = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pCurrValue");
        m_NextAttrCode = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pNextAttCode");
        m_OrgName = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pOrgParam");
        m_OrgValue = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pOrgValue");
        m_NextExtraViewBy = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pNextExtraViewBy");
        super.m_Mode = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getMode(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pMode"));
    }

    public void redirect()
    {
        boolean flag = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.canFunctionUseRFCall(super.m_FunctionTo, super.m_WebAppsContext);
        oracle.apps.fnd.functionSecurity.Function function = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(super.m_FunctionTo, super.m_WebAppsContext);
        if(function != null && !od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.isPMVReportFunction(function.getWebHTMLCall()))
            flag = false;
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        if(flag)
        {
            java.lang.String s = null;
            if(super.m_ParamMap != null)
                s = (java.lang.String)super.m_ParamMap.get("pMode");
            if(s == null)
                s = "DRILL";
            stringbuffer.append("pMode=").append(s);
            addURLParameters(stringbuffer);
            setRedirectUrl(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getRunFunctionURL(super.m_FunctionTo, stringbuffer.toString(), super.m_WebAppsContext, super.m_RespId, super.m_RespAppId, super.m_SecGrpId));
            return;
        } else
        {
            stringbuffer.append("../XXCRM_HTML/bisviewm.jsp?").append("dbc").append("=").append(super.m_DBC);
            stringbuffer.append("&").append("transactionid").append("=").append(super.m_TxnId);
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getURLParameters(super.m_ParamMap, super.m_Enc));
            addURLParameters(stringbuffer);
            setRedirectUrl(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getEncodedUrl(stringbuffer.toString(), super.m_Enc));
            return;
        }
    }

    public void process()
    {
        oracle.apps.fnd.functionSecurity.Function function = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(super.m_FunctionTo, super.m_WebAppsContext);
        java.lang.String s = null;
        java.lang.String s1 = null;
        if(function != null)
        {
            s = function.getParameters();
            if(s != null)
                s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s, "pReportFunctionName");
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
            {
                super.m_FunctionTo = s1;
                function = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(super.m_FunctionTo, super.m_WebAppsContext);
            }
        }
        try
        {
            super.m_UserSession = new UserSession(super.m_FunctionTo, m_RegionCode, super.m_WebAppsContext, null, super.m_Connection, super.m_PmvMsgLog);
            super.m_UserSession.setPageContext(super.m_PageContext);
            com.sun.java.util.collections.ArrayList arraylist = getParameterGroups(super.m_UserSession.getAKRegion());
            super.m_InsertParams = new HashMap(13);
            super.m_DeleteParams = new HashSet(13);
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_ScheduleId))
            {
                super.m_IsDeleteAllParams = true;
                com.sun.java.util.collections.ArrayList arraylist1 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getScheduleParameters(super.m_ScheduleId, super.m_Connection);
                processParameters(arraylist1);
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_PageId))
                {
                    com.sun.java.util.collections.ArrayList arraylist2 = getPageParameters(super.m_UserSession.getAKRegion());
                    processGroupedParameters(arraylist2, arraylist, false, false, true);
                }
            }
            if(super.m_UserSession.getAKRegion().hasShowHideParams())
            {
                processGroupedParameters(null, super.m_PageId, super.m_UserSession.getAKRegion(), arraylist, function.getParameters());
                processNonTimeFormFunctionParameters();
                validateParameters();
                super.m_InsertParams.remove(m_CurrAttrCode);
            }
            Object obj = null;
            if(!od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isTimeParameter(m_CurrAttrCode, super.m_UserSession.getAKRegion()))
            {
                com.sun.java.util.collections.ArrayList arraylist3 = new ArrayList(5);
                arraylist3 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillHelper.getAttrNamesInSameGroup(m_CurrAttrCode, m_Dimension, arraylist, super.m_UserSession.getAKRegion());
                deleteSameGroupParameters(m_Dimension, arraylist3, m_CurrAttrCode, super.m_UserSession.getAKRegion());
                oracle.apps.bis.pmv.parameters.NonTimeParameterValidator nontimeparametervalidator = new NonTimeParameterValidator();
                oracle.apps.bis.pmv.parameters.Parameters parameters = null;
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_CurrValueId))
                {
                    nontimeparametervalidator.getNonTimeValidatedValue(m_CurrAttrCode, m_CurrValueId, null, super.m_UserSession.getRegionCode(), super.m_UserSession.getResponsibilityId(), super.m_Connection, "Y", super.m_UserSession.getAKRegion(), null, null, super.m_WebAppsContext, super.m_UserSession);
                    java.lang.String s2 = nontimeparametervalidator.getValue();
                    parameters = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter(m_CurrAttrCode, s2, od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getSingleQuotedParamValue(m_CurrValueId), m_Dimension, null);
                } else
                {
                    java.lang.String s3 = nontimeparametervalidator.getNonTimeValidatedValue(m_CurrAttrCode, m_CurrValue, null, super.m_UserSession.getRegionCode(), super.m_UserSession.getResponsibilityId(), super.m_Connection, "N", super.m_UserSession.getAKRegion(), null, null, super.m_WebAppsContext, super.m_UserSession);
                    parameters = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter(m_CurrAttrCode, m_CurrValue, s3, m_Dimension, null);
                }
                super.m_InsertParams.put(m_CurrAttrCode, parameters);
            } else
            {
                od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillDownHelper drilldownhelper = new ODDrillDownHelper();
                if(!"EDW_TIME_A".equals(m_CurrLevel))
                {
                    java.lang.String s4 = m_CurrValue;
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_CurrValueId))
                    {
                        oracle.apps.bis.pmv.parameters.TimeParameterValidator timeparametervalidator = new TimeParameterValidator();
                        timeparametervalidator.getTimeValidatedValue(m_CurrAttrCode, m_CurrValueId, null, super.m_UserSession.getRegionCode(), super.m_UserSession.getResponsibilityId(), super.m_Connection, null, m_OrgName, m_OrgValue, "Y", super.m_UserSession.getAKRegion(), super.m_UserSession.getWebAppsContext());
                        s4 = timeparametervalidator.getValue();
                    }
                    drilldownhelper.processNextLevelTimeValues(super.m_UserSession.getAKRegion(), m_CurrAttrCode, s4, m_NextAttrCode, m_OrgName, m_OrgValue, super.m_Connection);
                }
                deleteTimeParameters();
                super.m_InsertParams.put(m_NextAttrCode + "_FROM", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter(m_NextAttrCode + "_FROM", drilldownhelper.getFromDateValue(), drilldownhelper.getFromDateId(), m_Dimension, drilldownhelper.getFromDate()));
                super.m_InsertParams.put(m_NextAttrCode + "_TO", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter(m_NextAttrCode + "_TO", drilldownhelper.getToDateValue(), drilldownhelper.getToDateId(), m_Dimension, drilldownhelper.getToDate()));
            }
            processViewByParameter();
            createParameters();
            super.m_ParamMap = new HashMap(7);
            populateCommonReportParams();
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
            {
                super.m_ParamMap.put("pDispRun", od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s, "pDispRun"));
                super.m_ParamMap.put("pEnableForecastGraph", od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s, "pEnableForecastGraph"));
                java.lang.String s5 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s, "pTitleCustomView");
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s5))
                {
                    super.m_ParamMap.put("pCustomView", s5);
                    return;
                } else
                {
                    super.m_ParamMap.put("pCustomView", od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s, "pCustomView"));
                    return;
                }
            }
        }
        catch(java.lang.Exception _ex) { }
    }

    private void deleteTimeParameters()
    {
        java.util.Hashtable hashtable = super.m_UserSession.getAKRegion().getAKRegionItems();
        if(hashtable != null)
        {
            java.util.Enumeration enumeration = hashtable.keys();
            Object obj = null;
            Object obj1 = null;
            while(enumeration.hasMoreElements())
            {
                oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)hashtable.get(enumeration.nextElement());
                java.lang.String s = akregionitem.getAttribute2();
                if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDimension(s).equals(m_Dimension))
                {
                    super.m_DeleteParams.add(oracle.apps.bis.pmv.common.StringUtil.evl(s, akregionitem.getAttributeCode()) + "_FROM");
                    super.m_DeleteParams.add(oracle.apps.bis.pmv.common.StringUtil.evl(s, akregionitem.getAttributeCode()) + "_TO");
                }
            }
            super.m_DeleteParams.add(m_CurrAttrCode + "_FROM");
            super.m_DeleteParams.add(m_CurrAttrCode + "_TO");
        }
    }

    private void processViewByParameter()
    {
        super.m_DeleteParams.add("VIEW_BY");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_NextExtraViewBy))
        {
            super.m_InsertParams.put("VIEW_BY", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter("VIEW_BY", m_NextAttrCode + "-" + m_NextExtraViewBy, m_NextAttrCode + "-" + m_NextExtraViewBy, null, null));
            return;
        } else
        {
            super.m_InsertParams.put("VIEW_BY", od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParameter("VIEW_BY", m_NextAttrCode, m_NextAttrCode, null, null));
            return;
        }
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillDownImpl.java 115.16 2006/01/29 23:23:41 nbarik noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillDownImpl.java 115.16 2006/01/29 23:23:41 nbarik noship $", "od.oracle.apps.xxcrm.bis.pmv.drill");
    private java.lang.String m_RegionCode;
    private java.lang.String m_Dimension;
    private java.lang.String m_CurrAttrCode;
    private java.lang.String m_NextAttrCode;
    private java.lang.String m_CurrValueId;
    private java.lang.String m_CurrLevel;
    private java.lang.String m_CurrValue;
    private java.lang.String m_OrgName;
    private java.lang.String m_OrgValue;
    private java.lang.String m_NextExtraViewBy;

}
