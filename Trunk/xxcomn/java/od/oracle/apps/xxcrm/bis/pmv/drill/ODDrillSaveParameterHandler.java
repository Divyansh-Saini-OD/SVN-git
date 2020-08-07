// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames 
// Source File Name:   ODDrillSaveParameterHandler.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.HashSet;
import com.sun.java.util.collections.Iterator;
import com.sun.java.util.collections.Set;
import oracle.apps.bis.pmv.common.PMVConstants;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.parameters.ParameterUtil;
import oracle.apps.bis.pmv.parameters.Parameters;
import oracle.apps.bis.pmv.parameters.SaveParameterHandler;
import oracle.apps.bis.pmv.parameters.TimeParameter;
import oracle.apps.bis.pmv.parameters.UserAttribute;
import oracle.apps.bis.pmv.parameters.UserAttributeHandler;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.VersionInfo;

public class ODDrillSaveParameterHandler extends oracle.apps.bis.pmv.parameters.SaveParameterHandler
{

    public ODDrillSaveParameterHandler(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        super(usersession);
    }

    public void deleteParameters(com.sun.java.util.collections.HashSet hashset, boolean flag)
    {
        try
        {
            oracle.apps.bis.pmv.parameters.UserAttributeHandler userattributehandler = new UserAttributeHandler();
            if(flag)
            {
                if(super.m_PageId != null && super.m_PageId.length() > 0)
                {
                    userattributehandler.deletePageParameters(super.m_UserSession.getUserId(), super.m_PageId, super.m_UserSession.getConnection(), null);
                    return;
                } else
                {
                    userattributehandler.deleteSessionParams(super.m_UserSession.getUserId(), super.m_UserSession.getSessionId(), super.m_UserSession.getFunctionName(), "NULL", super.m_UserSession.getConnection(), null);
                    return;
                }
            } else
            {
                com.sun.java.util.collections.ArrayList arraylist = getDeleteParamNames(hashset);
                userattributehandler.deleteSelectedParams(super.m_UserSession.getUserId(), super.m_UserSession.getSessionId(), super.m_PageId, super.m_UserSession.getFunctionName(), arraylist, super.m_UserSession.getConnection());
                return;
            }
        }
        catch(java.lang.Exception _ex)
        {
            return;
        }
    }

    public void saveParameters(com.sun.java.util.collections.HashMap hashmap)
    {
        populateNonTimeUserAttributes(hashmap);
        populateComputedParameters(hashmap);
        try
        {
            createParameters();
            return;
        }
        catch(java.lang.Exception _ex)
        {
            return;
        }
    }

    private void populateComputedParameters(com.sun.java.util.collections.HashMap hashmap)
    {
        if(hashmap != null)
        {
            com.sun.java.util.collections.Set set = hashmap.keySet();
            com.sun.java.util.collections.Iterator iterator = set.iterator();
            oracle.apps.bis.pmv.parameters.Parameters parameters = null;
            Object obj = null;
            java.lang.String s1 = null;
            while(iterator.hasNext()) 
            {
                java.lang.String s = (java.lang.String)iterator.next();
                if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1) && s.endsWith("_FROM"))
                    s1 = s.substring(0, s.indexOf("_FROM"));
                else
                if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1) && s.endsWith("_TO"))
                    s1 = s.substring(0, s.indexOf("_TO"));
                else
                if(s.equals("AS_OF_DATE"))
                    parameters = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get(s);
            }
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
            {
                oracle.apps.bis.pmv.parameters.TimeParameter timeparameter = new TimeParameter();
                timeparameter.setParameterName(s1);
                timeparameter.setFromDescription("DBC_TIME");
                timeparameter.setToDescription("DBC_TIME");
                super.m_MultiLevelParams = oracle.apps.bis.pmv.parameters.ParameterUtil.createMultiLevelParamsMap(super.m_UserSession);
                processTimeLevels(timeparameter);
                if(!s1.equals(timeparameter.getParameterName()))
                {
                    try
                    {
                        populateTimeSessionUserAttributes(timeparameter, parameters);
                        return;
                    }
                    catch(java.lang.Exception _ex)
                    {
                        return;
                    }
                } else
                {
                    populateTimeUserAttributes(hashmap, s1);
                    return;
                }
            }
            if(parameters != null)
                super.m_UserAttr.add(getUserAttribute(parameters));
        }
    }

    private void populateNonTimeUserAttributes(com.sun.java.util.collections.HashMap hashmap)
    {
        if(hashmap != null)
        {
            com.sun.java.util.collections.Set set = hashmap.keySet();
            com.sun.java.util.collections.Iterator iterator = set.iterator();
            Object obj = null;
            Object obj1 = null;
            while(iterator.hasNext()) 
            {
                java.lang.String s = (java.lang.String)iterator.next();
                if(!s.endsWith("_FROM") && !s.endsWith("_TO") && !s.equals("AS_OF_DATE") && !s.equals("BIS_P_ASOF_DATE") && !s.equals("BIS_PREV_REPORT_START_DATE") && !s.equals("BIS_CUR_REPORT_START_DATE") && !s.equals("BIS_PREVIOUS_EFFECTIVE_START_DATE") && !s.equals("BIS_PREVIOUS_EFFECTIVE_END_DATE"))
                {
                    oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get(s);
                    if(parameters != null)
                        super.m_UserAttr.add(getUserAttribute(parameters));
                }
            }
        }
    }

    private void populateTimeUserAttributes(com.sun.java.util.collections.HashMap hashmap, java.lang.String s)
    {
        Object obj = null;
        if(hashmap != null)
        {
            oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get(s + "_FROM");
            if(parameters != null)
                super.m_UserAttr.add(getUserAttribute(parameters));
            parameters = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get(s + "_TO");
            if(parameters != null)
                super.m_UserAttr.add(getUserAttribute(parameters));
            parameters = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get("AS_OF_DATE");
            if(parameters != null)
                super.m_UserAttr.add(getUserAttribute(parameters));
            parameters = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get("BIS_P_ASOF_DATE");
            if(parameters != null)
                super.m_UserAttr.add(getUserAttribute(parameters));
            parameters = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get("BIS_PREV_REPORT_START_DATE");
            if(parameters != null)
                super.m_UserAttr.add(getUserAttribute(parameters));
            parameters = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get("BIS_CUR_REPORT_START_DATE");
            if(parameters != null)
                super.m_UserAttr.add(getUserAttribute(parameters));
            parameters = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get("BIS_PREVIOUS_EFFECTIVE_START_DATE");
            if(parameters != null)
                super.m_UserAttr.add(getUserAttribute(parameters));
            parameters = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get("BIS_PREVIOUS_EFFECTIVE_END_DATE");
            if(parameters != null)
                super.m_UserAttr.add(getUserAttribute(parameters));
        }
    }

    public oracle.apps.bis.pmv.parameters.UserAttribute getUserAttribute(oracle.apps.bis.pmv.parameters.Parameters parameters)
    {
        oracle.apps.bis.pmv.parameters.UserAttribute userattribute = new UserAttribute();
        userattribute.setUserId(super.m_UserSession.getUserId());
        userattribute.setSessionId(super.m_UserSession.getSessionId());
        userattribute.setFunctionName(super.m_UserSession.getFunctionName());
        userattribute.setAttributeName(parameters.getParameterName());
        userattribute.setSessionValue(parameters.getParameterValue());
        userattribute.setSessionDesc(parameters.getParameterDescription());
        userattribute.setDimension(parameters.getDimension());
        userattribute.setPeriodDate(parameters.getPeriod());
        userattribute.setOperator(parameters.getOperator());
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(super.m_PageId))
            userattribute.setPageId(super.m_PageId);
        return userattribute;
    }

    private com.sun.java.util.collections.ArrayList getDeleteParamNames(com.sun.java.util.collections.HashSet hashset)
    {
        com.sun.java.util.collections.ArrayList arraylist = null;
        if(hashset != null)
        {
            com.sun.java.util.collections.Iterator iterator = hashset.iterator();
            arraylist = new ArrayList(7);
            for(; iterator.hasNext(); arraylist.add(iterator.next()));
        }
        return arraylist;
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillSaveParameterHandler.java 115.5 2005/12/02 00:54:41 ppalpart noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillSaveParameterHandler.java 115.5 2005/12/02 00:54:41 ppalpart noship $", "od.oracle.apps.xxcrm.bis.pmv.drill");

}
