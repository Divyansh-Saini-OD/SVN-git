// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODDrillParameterValidator.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.Iterator;
import com.sun.java.util.collections.Map;
import com.sun.java.util.collections.Set;
import java.util.Enumeration;
import java.util.Hashtable;
import oracle.apps.bis.common.Util;
import oracle.apps.bis.parameters.ParametersUtil;
import oracle.apps.bis.pmv.common.LookUpHelper;
import oracle.apps.bis.pmv.common.PMVConstants;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.metadata.DimLevelProperties;
import oracle.apps.bis.pmv.parameters.NonTimeParameterValidator;
import oracle.apps.bis.pmv.parameters.ParameterHelper;
import oracle.apps.bis.pmv.parameters.Parameters;
import oracle.apps.bis.pmv.session.RequestInfo;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.Context;
import oracle.apps.fnd.common.ProfileStore;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.functionSecurity.Function;
import oracle.cabo.share.url.EncoderUtils;

// Referenced classes of package od.oracle.apps.xxcrm.bis.pmv.drill:
//            DrillUtil

public class ODDrillParameterValidator extends oracle.apps.bis.pmv.parameters.NonTimeParameterValidator
{

    public ODDrillParameterValidator()
    {
    }

    public java.lang.String getValidatedParameters(com.sun.java.util.collections.HashMap hashmap, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        if(usersession.getRequestInfo() != null && !oracle.apps.bis.pmv.common.StringUtil.emptyString(usersession.getRequestInfo().getPageId()))
            return getValidatedPageParameters(hashmap, usersession);
        else
            return getValidatedReportParameters(hashmap, usersession);
    }

    private java.lang.String getValidatedPageParameters(com.sun.java.util.collections.HashMap hashmap, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        oracle.apps.fnd.functionSecurity.Function function = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(usersession.getFunctionName(), usersession.getWebAppsContext());
        java.lang.String s = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.buildFrmFxnParameters(function.getParameters(), usersession.getConnection());
        com.sun.java.util.collections.Map map = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameters(s);
        java.lang.String s1 = null;
        if(map != null)
            s1 = (java.lang.String)map.get("pParamIds");
        if(!"Y".equals(s1))
            s1 = "N";
        return getValidatedParameters(hashmap, usersession, map, false, s1);
    }

    private java.lang.String getValidatedReportParameters(com.sun.java.util.collections.HashMap hashmap, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        oracle.apps.fnd.functionSecurity.Function function = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(usersession.getFunctionName(), usersession.getWebAppsContext());
        com.sun.java.util.collections.Map map = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameters(function.getParameters());
        java.lang.String s = null;
        if(map != null)
        {
            s = (java.lang.String)map.get("pParameters");
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
            {
                java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getUrlParamValue(s, "pPLSQLFunction");
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                    s = oracle.apps.bis.common.Util.getPLSQLFunctionParameters(s1, s, usersession.getConnection());
            }
        }
        com.sun.java.util.collections.HashMap hashmap1 = null;
        Object obj = null;
        java.lang.String s2 = null;
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            usersession.setParameters(s);
            s = usersession.getParameters();
            s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s, "pParamIds");
            if(!"Y".equals(s2))
                s2 = "N";
            java.util.Hashtable hashtable = usersession.getParameterHashTable(s, usersession.getRegionCode());
            java.util.Enumeration enumeration = hashtable.keys();
            hashmap1 = new HashMap(7);
            Object obj1 = null;
            Object obj2 = null;
            java.lang.String s3;
            java.lang.String s4;
            for(; enumeration.hasMoreElements(); hashmap1.put(s3, s4))
            {
                s3 = (java.lang.String)enumeration.nextElement();
                s4 = (java.lang.String)hashtable.get(s3);
            }

        } else
        if(map != null)
            s2 = (java.lang.String)map.get("pParamIds");
        return getValidatedParameters(hashmap, usersession, hashmap1, true, s2);
    }

    private java.lang.String getValidatedParameters(com.sun.java.util.collections.HashMap hashmap, oracle.apps.bis.pmv.session.UserSession usersession, com.sun.java.util.collections.Map map, boolean flag, java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        try
        {
            if(hashmap != null)
            {
                com.sun.java.util.collections.Set set = hashmap.keySet();
                com.sun.java.util.collections.Iterator iterator = set.iterator();
                oracle.apps.bis.pmv.parameters.Parameters parameters = null;
                m_AttrCode = new java.lang.String[set.size()];
                m_AttrValue = new java.lang.String[set.size()];
                int i = 0;
                Object obj = null;
                Object obj1 = null;
                java.lang.String s3 = null;
                if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
                    s3 = "Y";
                else
                    s3 = s;
                Object obj2 = null;
                Object obj3 = null;
                while(iterator.hasNext())
                {
                    java.lang.String s1 = (java.lang.String)iterator.next();
                    oracle.apps.bis.pmv.parameters.Parameters parameters1 = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get(s1);
                    if(parameters1 != null)
                    {
                        m_AttrCode[i] = s1;
                        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(parameters1.getParameterValue()))
                        {
                            java.lang.String s5 = parameters1.getParameterValue() != null ? parameters1.getParameterValue() : "";
                            java.lang.String s6 = parameters1.getParameterDescription() != null ? parameters1.getParameterDescription() : "";
                            m_AttrValue[i] = oracle.apps.bis.pmv.common.LookUpHelper.encodeIdValue(s5, s6);
                        } else
                        if("Y".equals(s3) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(parameters1.getParameterValue()))
                            m_AttrValue[i] = parameters1.getParameterValue();
                        else
                            m_AttrValue[i] = parameters1.getParameterDescription();
                        i++;
                        if("AS_OF_DATE".equals(s1))
                        {
                            parameters = new Parameters();
                            parameters.setParameterName(s1);
                            parameters.setParameterDescription(parameters1.getParameterDescription());
                            parameters.setParameterValue(parameters1.getParameterValue());
                            parameters.setPeriod(parameters1.getPeriod());
                        }
                    }
                }
                iterator = set.iterator();
                Object obj4 = null;
                java.util.Hashtable hashtable = usersession.getAKRegion().getAKRegionItems();
                com.sun.java.util.collections.HashMap hashmap1 = new HashMap(1);
                hashmap1.put("AS_OF_DATE", parameters);
                Object obj5 = null;
                java.lang.String s7 = usersession.getWebAppsContext().getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
                usersession.getParameterHelper().setParameterValues(hashmap);
                boolean flag1 = true;
                Object obj6 = null;
                Object obj7 = null;
                com.sun.java.util.collections.ArrayList arraylist = new ArrayList(5);
                while(iterator.hasNext())
                {
                    java.lang.String s2 = (java.lang.String)iterator.next();
                    oracle.apps.bis.pmv.parameters.Parameters parameters2 = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get(s2);
                    oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)hashtable.get(s2);
                    boolean flag4 = true;
                    if(akregionitem != null && akregionitem.isDimension() && !od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isTimeParameter(akregionitem) && !oracle.apps.bis.parameters.ParametersUtil.isTimeComparisonType(akregionitem.getDimension()))
                    {
                        if(parameters2 != null)
                        {
                            if(akregionitem.getDimLevelProperties() != null)
                                flag4 = akregionitem.getDimLevelProperties().isAll();
                            boolean flag5 = (oracle.apps.bis.pmv.common.StringUtil.emptyString(parameters2.getParameterDescription()) || "All".equals(parameters2.getParameterDescription())) && !akregionitem.isRollingDimension();
                            if((!flag4 || !flag5) && !"~ROLLING_DIMENSION".equals(parameters2.getParameterDescription()))
                                if(akregionitem.isRollingDimension())
                                {
                                    if(oracle.apps.bis.pmv.common.StringUtil.emptyString(parameters2.getParameterValue()))
                                        parameters2.setParameterValue(parameters2.getParameterDescription());
                                    parameters2.setParameterDescription("~ROLLING_DIMENSION");
                                } else
                                {
                                    oracle.apps.bis.pmv.parameters.Parameters parameters3 = new Parameters();
                                    parameters3.setParameterName(s2);
                                    java.lang.String s4;
                                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(parameters2.getIdFlag()))
                                        s4 = parameters2.getIdFlag();
                                    else
                                        s4 = s;
                                    if("Y".equals(s4) && !oracle.apps.bis.pmv.common.StringUtil.emptyString(parameters2.getParameterValue()))
                                        parameters3.setParameterDescription(parameters2.getParameterValue());
                                    else
                                        parameters3.setParameterDescription(parameters2.getParameterDescription());
                                    parameters3.setDimension(parameters2.getDimension());
                                    parameters3.setIdFlag(s4);
                                    parameters3.setLovWhere(akregionitem.getLovWhereClause());
                                    try
                                    {
                                        java.lang.String as[] = isValidParameter(parameters3, usersession, hashmap1, m_AttrCode, m_AttrValue);
                                        if(as != null)
                                        {
                                            boolean flag2 = (new Boolean(as[0])).booleanValue();
                                            boolean flag6 = isDefaultValueSet();
                                            if(!flag2 || flag6)
                                            {
                                                if(map == null)
                                                {
                                                    arraylist.add(s2);
                                                } else
                                                {
                                                    java.lang.String s8 = parameters2.getParameterDescription();
                                                    java.lang.String s10 = null;
                                                    if(flag)
                                                    {
                                                        s10 = (java.lang.String)map.get(s2);
                                                    } else
                                                    {
                                                        java.lang.String s11 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getAttrCodeFromAttr2(usersession.getAKRegion(), s2);
                                                        s10 = (java.lang.String)map.get(s11);
                                                    }
                                                    java.lang.String s12 = null;
                                                    populateDefaultAttrValue(s2, s10);
                                                    parameters3.setParameterDescription(s10);
                                                    java.lang.String as1[] = isValidParameter(parameters3, usersession, hashmap1, m_AttrCode, m_AttrValue);
                                                    if(as1 != null)
                                                    {
                                                        boolean flag3 = (new Boolean(as1[0])).booleanValue();
                                                        if(flag3)
                                                        {
                                                            s12 = parameters3.getParameterDescription();
                                                            s10 = parameters3.getParameterValue();
                                                        }
                                                    }
                                                    s10 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getSingleQuotedParamValue(s10);
                                                    if(oracle.apps.bis.pmv.common.StringUtil.emptyString(stringbuffer.toString()))
                                                        stringbuffer.append("pDrillParamRegion=").append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getRegionCode(), s7));
                                                    stringbuffer.append("&pDrillParamName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s2, s7));
                                                    stringbuffer.append("&pDrillPrevDesc=");
                                                    if(s8 != null)
                                                        stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString(s8, s7));
                                                    stringbuffer.append("&pDrillCurrentDesc=");
                                                    if(s12 != null)
                                                        stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString(s12, s7));
                                                    parameters2.setParameterValue(s10);
                                                    parameters2.setParameterDescription(s12);
                                                }
                                            } else
                                            if(parameters2.getParameterValue() != null && parameters2.getParameterDescription() != null && parameters2.getParameterValue().indexOf(",") > 0 && parameters2.getParameterDescription().indexOf("^^") > 0)
                                            {
                                                parameters2.setParameterValue(parameters2.getParameterValue());
                                                parameters2.setParameterDescription(parameters2.getParameterDescription());
                                            } else
                                            {
                                                parameters2.setParameterValue(parameters3.getParameterValue());
                                                parameters2.setParameterDescription(parameters3.getParameterDescription());
                                            }
                                        }
                                    }
                                    catch(java.lang.Exception _ex) { }
                                }
                        }
                    } else
                    if(oracle.apps.bis.pmv.common.StringUtil.emptyString(parameters2.getParameterValue()) && !"All".equals(parameters2.getParameterDescription()))
                        parameters2.setParameterValue(parameters2.getParameterDescription());
                }
                if(arraylist != null)
                {
                    for(int j = 0; j < arraylist.size(); j++)
                    {
                        java.lang.String s9 = (java.lang.String)arraylist.get(j);
                        hashmap.remove(s9);
                    }

                }
            }
        }
        catch(java.lang.Exception _ex) { }
        return stringbuffer.toString();
    }

    private void populateDefaultAttrValue(java.lang.String s, java.lang.String s1)
    {
        if(m_AttrCode != null && m_AttrValue != null && s != null)
        {
            for(int i = 0; i < m_AttrCode.length; i++)
                if(s.equals(m_AttrCode[i]))
                    m_AttrValue[i] = s1;

        }
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillParameterValidator.java 115.28 2006/06/26 12:07:03 msaran noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillParameterValidator.java 115.28 2006/06/26 12:07:03 msaran noship $", "od.oracle.apps.xxcrm.bis.pmv.drill");
    private java.lang.String m_AttrCode[];
    private java.lang.String m_AttrValue[];

}
