// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODDrillUtil.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.HashSet;
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
import java.util.Hashtable;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.BISEncryption;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.common.VersionConstants;
import oracle.apps.bis.pmv.breadcrumb.BreadCrumbHelper;
import oracle.apps.bis.pmv.common.PMVConstants;
import oracle.apps.bis.pmv.common.PMVNLSServices;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.bis.pmv.common.RelatedLinksUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.parameters.ParameterUtil;
import oracle.apps.bis.pmv.parameters.Parameters;
import oracle.apps.bis.pmv.session.RequestInfo;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.AppsContext;
import oracle.apps.fnd.common.Context;
import oracle.apps.fnd.common.ProfileStore;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.apps.fnd.functionSecurity.Function;
import oracle.apps.fnd.functionSecurity.FunctionSecurity;
import oracle.apps.fnd.functionSecurity.Resp;
import oracle.apps.fnd.functionSecurity.SecurityGroup;
import oracle.cabo.share.url.EncoderUtils;
import oracle.cabo.ui.beans.nav.LinkBean;
import oracle.cabo.ui.beans.nav.LinkContainerBean;
import oracle.jdbc.driver.OracleStatement;
import oracle.sql.DATE;

// Referenced classes of package od.oracle.apps.xxcrm.bis.pmv.drill:
//            DrillFactory

public class ODDrillUtil
{

    public ODDrillUtil()
    {
    }

    public static int getMode(java.lang.String s)
    {
        int i = 0;
        try
        {
            i = java.lang.Integer.parseInt(s);
        }
        catch(java.lang.Exception _ex) { }
        return i;
    }

    public static long getLong(java.lang.String s)
    {
        long l = 0x8000000000000000L;
        try
        {
            l = java.lang.Long.parseLong(s);
        }
        catch(java.lang.Exception _ex) { }
        return l;
    }

    public static boolean isDimensionInParamGroup(java.lang.String s, com.sun.java.util.collections.ArrayList arraylist)
    {
        if(arraylist != null)
        {
            Object obj = null;
            for(int i = 0; i < arraylist.size(); i++)
            {
                oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)arraylist.get(i);
                if(s.equals(parameters.getDimension()))
                    return true;
            }

        }
        return false;
    }

    public static boolean isDimensionsInParamGroup(com.sun.java.util.collections.HashSet hashset, com.sun.java.util.collections.ArrayList arraylist)
    {
        if(hashset != null)
        {
            for(com.sun.java.util.collections.Iterator iterator = hashset.iterator(); iterator.hasNext();)
            {
                java.lang.String s = (java.lang.String)iterator.next();
                java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDimension(s);
                boolean flag = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isDimensionInParamGroup(s1, arraylist);
                if(flag)
                    return true;
            }

        }
        return false;
    }

    public static java.lang.String getDimension(java.lang.String s)
    {
        java.lang.String s1 = "";
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            int i = s.indexOf('+');
            if(i > 0 && i < s.length())
                s1 = s.substring(0, i);
        }
        return s1;
    }

    public static java.lang.String getDimensionLevel(java.lang.String s)
    {
        java.lang.String s1 = "";
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            int i = s.indexOf('+');
            if(i > 0 && i + 1 < s.length())
                s1 = s.substring(i + 1, s.length());
        }
        return s1;
    }

    public static boolean isTimeDimension(java.lang.String s, oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        return oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeDimension(s, akregion);
    }

    public static boolean isTimeParameter(java.lang.String s, oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        return oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeParameter(s, akregion);
    }

    public static boolean isTimeLevelStarts(java.lang.String s, oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        return oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeLevelStarts(s, akregion);
    }

    public static boolean isTimeParameter(oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem)
    {
        return oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeParameter(akregionitem);
    }

    public static boolean isBSCTimeLevel(java.lang.String s, oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        return oracle.apps.bis.pmv.parameters.ParameterUtil.isBSCTimeLevel(s, akregion);
    }

    public static java.lang.String getSingleQuotedParamValue(java.lang.String s)
    {
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && !s.startsWith("'"))
            return "'" + s + "'";
        else
            return s;
    }

    public static oracle.apps.bis.pmv.parameters.Parameters getParameter(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, oracle.sql.DATE date)
    {
        oracle.apps.bis.pmv.parameters.Parameters parameters = new Parameters();
        parameters.setParameterName(s);
        parameters.setParameterDescription(s1);
        parameters.setParameterValue(s2);
        parameters.setDimension(s3);
        parameters.setPeriod(date);
        return parameters;
    }

    public static oracle.apps.bis.pmv.parameters.Parameters getParameter(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5, java.lang.String s6, oracle.sql.DATE date)
    {
        oracle.apps.bis.pmv.parameters.Parameters parameters = new Parameters();
        parameters.setParameterName(s);
        parameters.setParameterDescription(s1);
        parameters.setParameterValue(s2);
        parameters.setDimension(s3);
        parameters.setLovWhere(s4);
        parameters.setIdFlag(s5);
        parameters.setHierarchyFlag(s6);
        parameters.setPeriod(date);
        return parameters;
    }

    public static oracle.apps.bis.pmv.parameters.Parameters getComputedDateParameter(java.lang.String s, oracle.sql.DATE date, oracle.apps.bis.pmv.common.PMVNLSServices pmvnlsservices)
    {
        java.lang.String s1 = null;
        if(date != null && pmvnlsservices != null)
            s1 = pmvnlsservices.dateToString(date.dateValue(), "dd/MM/yyyy");
        oracle.apps.bis.pmv.parameters.Parameters parameters = new Parameters();
        parameters.setParameterName(s);
        parameters.setParameterDescription(s1);
        parameters.setParameterValue(s1);
        parameters.setPeriod(date);
        return parameters;
    }

    public static com.sun.java.util.collections.ArrayList getDeleteAttrNames(java.lang.String s, com.sun.java.util.collections.ArrayList arraylist, java.lang.String s1, oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        com.sun.java.util.collections.ArrayList arraylist1 = null;
        if(arraylist != null)
        {
            arraylist1 = new ArrayList(5);
            Object obj = null;
            for(int i = 0; i < arraylist.size(); i++)
            {
                java.lang.String s2 = (java.lang.String)arraylist.get(i);
                arraylist1.add(s2);
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
                {
                    arraylist1.add(s + "_HIERARCHY");
                    if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isTimeParameter(s1, akregion))
                    {
                        arraylist1.add(s2 + "_TO");
                        arraylist1.add(s2 + "_FROM");
                    }
                }
            }

        }
        return arraylist1;
    }

    public static java.lang.String getURLParameters(com.sun.java.util.collections.Map map, java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        if(map != null)
        {
            com.sun.java.util.collections.Set set = map.keySet();
            com.sun.java.util.collections.Iterator iterator = set.iterator();
            Object obj = null;
            Object obj1 = null;
            while(iterator.hasNext())
            {
                java.lang.String s1 = (java.lang.String)iterator.next();
                java.lang.String s2 = (java.lang.String)map.get(s1);
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                    stringbuffer.append("&").append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getEncodedString(s1, s)).append("=");
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
                    stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getEncodedString(s2, s));
            }
        }
        return stringbuffer.toString();
    }

    public static java.lang.String getURLParameters(com.sun.java.util.collections.Map map)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        if(map != null)
        {
            com.sun.java.util.collections.Set set = map.keySet();
            com.sun.java.util.collections.Iterator iterator = set.iterator();
            Object obj = null;
            Object obj1 = null;
            while(iterator.hasNext())
            {
                java.lang.String s = (java.lang.String)iterator.next();
                java.lang.String s1 = (java.lang.String)map.get(s);
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
                    stringbuffer.append("&").append(s).append("=");
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                    stringbuffer.append(s1);
            }
        }
        return stringbuffer.toString();
    }

    public static java.lang.String removeFirstAmpersand(java.lang.String s)
    {
        if(s != null && s.startsWith("&"))
            return s.substring(1);
        else
            return s;
    }

    public static java.lang.String getPageId(java.lang.String s)
    {
        if(s == null)
            return null;
        int i = s.indexOf(",");
        if(i > 0)
            return s.substring(0, i);
        else
            return s;
    }

    public static java.lang.String getEncodedString(java.lang.String s, java.lang.String s1)
    {
        java.lang.String s2 = s;
        try
        {
            s2 = oracle.cabo.share.url.EncoderUtils.encodeString(s, s1);
        }
        catch(java.lang.Exception _ex) { }
        return s2;
    }

    public static java.lang.String getEncodedUrl(java.lang.String s, java.lang.String s1)
    {
        java.lang.String s2 = s;
        try
        {
            s2 = oracle.cabo.share.url.EncoderUtils.encodeURL(s, s1, true);
        }
        catch(java.lang.Exception _ex) { }
        return s2;
    }

    public static java.lang.String getRunFunctionURL(java.lang.String s, java.lang.String s1, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(webappscontext);
        oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(s);
        oracle.apps.fnd.functionSecurity.SecurityGroup securitygroup = functionsecurity.getSecurityGroup();
        oracle.apps.fnd.functionSecurity.Resp resp = functionsecurity.getResp();
        long l = -1L;
        long l1 = -1L;
        long l2 = 0L;
        if(resp != null)
        {
            l = resp.getRespID();
            l1 = resp.getRespApplID();
            if(securitygroup != null)
                l2 = securitygroup.getSecurityGroupID();
            else
                securitygroup = functionsecurity.getSecurityGroup(l2);
        }
        try
        {
            long al[] = oracle.apps.bis.pmv.common.RelatedLinksUtil.getRespSecurityInfo(functionsecurity, function.getFunctionID(), l, l1, l2);
            if(al[0] != -2L)
            {
                resp = functionsecurity.getResp(al[0], al[1]);
                securitygroup = functionsecurity.getSecurityGroup(al[2]);
            }
        }
        catch(java.lang.Exception _ex) { }
        java.lang.String s2 = functionsecurity.getRunFunctionURL(function, resp, securitygroup, od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.removeFirstAmpersand(s1));
        return s2;
    }

    public static java.lang.String getRunFunctionURL(java.lang.String s, java.lang.String s1, oracle.apps.fnd.common.WebAppsContext webappscontext, long l, long l1, long l2)
    {
        oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(webappscontext);
        oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(s);
        l2 = l2 >= 0L ? l2 : 0L;
        oracle.apps.fnd.functionSecurity.SecurityGroup securitygroup = functionsecurity.getSecurityGroup(l2);
        oracle.apps.fnd.functionSecurity.Resp resp = functionsecurity.getResp(l, l1);
        try
        {
            long al[] = oracle.apps.bis.pmv.common.RelatedLinksUtil.getRespSecurityInfo(functionsecurity, function.getFunctionID(), l, l1, l2);
            if(al[0] != -2L)
            {
                resp = functionsecurity.getResp(al[0], al[1]);
                securitygroup = functionsecurity.getSecurityGroup(al[2]);
            }
        }
        catch(java.lang.Exception _ex) { }
        if(l == 0x8000000000000000L || l1 == 0x8000000000000000L || l2 == 0x8000000000000000L)
            return od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getRunFunctionURL(s, s1, webappscontext);
        else
            return functionsecurity.getRunFunctionURL(function, resp, securitygroup, od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.removeFirstAmpersand(s1));
    }

    public static void removeDateParams(com.sun.java.util.collections.ArrayList arraylist)
    {
        Object obj = null;
        java.lang.String s = "";
        for(int i = 0; arraylist != null && i < arraylist.size(); i++)
        {
            oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)arraylist.get(i);
            if(parameters != null)
            {
                java.lang.String s1 = parameters.getParameterName();
                if("AS_OF_DATE".equals(s1) || "BIS_P_ASOF_DATE".equals(s1) || "BIS_CUR_REPORT_START_DATE".equals(s1) || "BIS_PREV_REPORT_START_DATE".equals(s1) || "BIS_PREVIOUS_EFFECTIVE_START_DATE".equals(s1) || "BIS_PREVIOUS_EFFECTIVE_END_DATE".equals(s1))
                    arraylist.remove(i);
            }
        }

    }

    public static boolean isOAEncryptedValue(java.lang.String s, com.sun.java.util.collections.HashMap hashmap)
    {
        if(hashmap == null || s == null)
            return false;
        else
            return "1".equals(hashmap.get(s));
    }

    public static java.lang.String OAEncrypt(oracle.apps.fnd.common.WebAppsContext webappscontext, java.lang.String s)
    {
        if(webappscontext == null || s == null)
            return null;
        if("SWAN".equals("409"))
            return "{!!" + oracle.apps.bis.common.BISEncryption.HTTPDataEncrypt(webappscontext.getSessionEncKey(), s);
        else
            return "{!!" + oracle.apps.bis.common.BISEncryption.AOLEncrypt(webappscontext.getSessionId(), s);
    }

    public static java.lang.String OADecrypt(oracle.apps.fnd.common.WebAppsContext webappscontext, java.lang.String s)
    {
        if(webappscontext == null || s == null)
            return null;
        if("SWAN".equals("409"))
            return oracle.apps.bis.common.BISEncryption.HTTPDataDecrypt(webappscontext.getSessionEncKey(), s);
        else
            return oracle.apps.bis.common.BISEncryption.AOLDecrypt(webappscontext.getSessionId(), s);
    }

    public static boolean isPMVTablePortletFunction(java.lang.String s, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        if(s == null || webappscontext == null)
            return false;
        oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(webappscontext);
        try
        {
            oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(s);
            boolean flag = "WEBPORTLET".equals(function.getType());
            if(flag)
            {
                java.lang.String s1 = function.getWebHTMLCall();
                return s1 != null && s1.indexOf("OA.jsp?akRegionCode=BIS_PM_PORTLET_TABLE_LAYOUT&akRegionApplicationId=191") >= 0;
            }
        }
        catch(java.lang.Exception _ex) { }
        return false;
    }

    public static boolean canFunctionUseRFCall(java.lang.String s, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        if(s == null || webappscontext == null)
            return false;
        if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isPMVTablePortletFunction(s, webappscontext))
            return false;
        oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(webappscontext);
        java.lang.String s1 = null;
        boolean flag = false;
        boolean flag1 = true;
        try
        {
            oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(s);
            s1 = function.getParameters();
            flag = oracle.apps.fnd.functionSecurity.Function.WWK.equals(function.getType());
            java.lang.String s2 = function.getWebHTMLCall();
            boolean flag2 = s2 != null && oracle.apps.bis.pmv.common.StringUtil.indexOf(s2, "bisviewer.showReport", true) >= 0;
            if(flag2)
                if(oracle.apps.bis.pmv.common.StringUtil.indexOf(s2, ")", true) > 0)
                    flag1 = false;
                else
                    flag1 = s1 != null && oracle.apps.bis.pmv.common.StringUtil.indexOf(s1, "pFunctionName=", true) >= 0;
        }
        catch(java.lang.Exception _ex) { }
        return s1 != null && (s1 == null || s1.indexOf("pMode") == -1) && !flag && flag1;
    }

    public static oracle.apps.bis.pmv.parameters.Parameters getTimeComparisionParam(com.sun.java.util.collections.HashMap hashmap)
    {
        oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get("TIME_COMPARISON_TYPE+YEARLY");
        if(parameters == null)
            parameters = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get("TIME_COMPARISON_TYPE+SEQUENTIAL");
        if(parameters == null)
            parameters = (oracle.apps.bis.pmv.parameters.Parameters)hashmap.get("TIME_COMPARISON_TYPE+BUDGET");
        return parameters;
    }

    public static boolean isValidViewBy(oracle.apps.bis.pmv.metadata.AKRegion akregion, java.lang.String s)
    {
        if(akregion == null || !akregion.isViewBy() || s == null)
            return false;
        boolean flag = true;
        try
        {
            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)akregion.getAKRegionItems().get(s);
            if(akregionitem != null)
            {
                if(oracle.apps.bis.pmv.common.StringUtil.in(akregionitem.getRegionItemType(), oracle.apps.bis.pmv.common.PMVConstants.BIS_NON_VIEWBY_TYPES))
                    flag = false;
            } else
            if(s.indexOf("-") > 0)
            {
                flag = false;
                int i = s.indexOf("-");
                java.lang.String s1 = s.substring(0, i);
                java.lang.String s2 = s.substring(i + 1);
                oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem1 = (oracle.apps.bis.pmv.metadata.AKRegionItem)akregion.getAKRegionItems().get(s1);
                if(akregionitem1 != null)
                {
                    java.lang.String s3 = akregionitem1.getExtraViewBy();
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s3))
                    {
                        oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem2 = (oracle.apps.bis.pmv.metadata.AKRegionItem)akregion.getAKRegionItems().get(s2);
                        if(akregionitem2 != null && s3.indexOf(akregionitem2.getAttributeCode()) >= 0 || s3.equals(akregionitem2.getAttributeCode()))
                            flag = true;
                    }
                }
            } else
            {
                flag = false;
            }
        }
        catch(java.lang.Exception _ex) { }
        return flag;
    }

    public static com.sun.java.util.collections.HashMap getSelectNavigationValues(com.sun.java.util.collections.HashMap hashmap, javax.servlet.http.HttpServletRequest httpservletrequest, java.lang.String s)
    {
        java.lang.String as[] = new java.lang.String[hashmap.size()];
        java.lang.String as1[] = new java.lang.String[hashmap.size()];
        Object obj = null;
        Object obj1 = null;
        int i = 0;
        com.sun.java.util.collections.HashMap hashmap1 = new HashMap(9);
        for(com.sun.java.util.collections.Iterator iterator = hashmap.keySet().iterator(); iterator.hasNext();)
        {
            java.lang.String s1 = (java.lang.String)iterator.next();
            as[i] = (java.lang.String)hashmap.get(s1);
            as1[i] = s1;
            i++;
        }

        if(hashmap != null && httpservletrequest != null)
        {
            for(int j = 0; j < as.length; j++)
            {
                com.sun.java.util.collections.ArrayList arraylist = new ArrayList(3);
                java.lang.String as2[] = oracle.apps.bis.common.ServletWrapper.getParameterValues(httpservletrequest, as[j]);
                if(as2 != null)
                    if(!"N".equals(s))
                    {
                        java.lang.String as3[] = oracle.apps.bis.common.ServletWrapper.getParameterValues(httpservletrequest, "SelectCheckbox");
                        if(as2 != null && as3 != null)
                        {
                            for(int l = 0; l < as3.length; l++)
                            {
                                for(int i1 = 0; i1 < as2.length; i1++)
                                    if(i1 == (new Integer(as3[l])).intValue())
                                    {
                                        java.lang.String s2 = as2[i1];
                                        if(oracle.apps.bis.pmv.common.StringUtil.containLetters(s2))
                                        {
                                            arraylist.add(s2);
                                        } else
                                        {
                                            if(s2.indexOf(".") > -1)
                                                s2 = oracle.apps.bis.pmv.common.StringUtil.removeNonAlphaNumerics(s2.substring(0, s2.indexOf(".")));
                                            else
                                                s2 = oracle.apps.bis.pmv.common.StringUtil.removeNonAlphaNumerics(s2);
                                            arraylist.add(s2);
                                        }
                                    }

                            }

                            hashmap1.put(as1[j], arraylist);
                        }
                    } else
                    {
                        for(int k = 0; k < as2.length; k++)
                        {
                            java.lang.String s3 = as2[k];
                            if(oracle.apps.bis.pmv.common.StringUtil.containLetters(s3))
                            {
                                arraylist.add(s3);
                            } else
                            {
                                if(s3.indexOf(".") > -1)
                                    s3 = oracle.apps.bis.pmv.common.StringUtil.removeNonAlphaNumerics(s3.substring(0, as2[k].indexOf(".")));
                                else
                                    s3 = oracle.apps.bis.pmv.common.StringUtil.removeNonAlphaNumerics(s3);
                                arraylist.add(s3);
                            }
                        }

                        hashmap1.put(as1[j], arraylist);
                    }
            }

        }
        return hashmap1;
    }

    public static java.lang.String getPrintablePageURL(java.lang.String s, com.sun.java.util.collections.HashMap hashmap, javax.servlet.http.HttpServletRequest httpservletrequest, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(600);
        java.lang.String s1 = usersession.getWebAppsContext().getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        stringbuffer.append("/OA_HTML/OA.jsp?page=/od/oracle/apps/xxcrm/bis/pmv/drill/webui/DrillPG&retainAM=Y&addBreadCrumb=Y&pMode=5&pSessionId=").append(usersession.getSessionId());
        stringbuffer.append("&").append("dbc").append("=").append(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "dbc"));
        stringbuffer.append("&").append("transactionid").append("=").append(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "transactionid"));
        stringbuffer.append("&pUserId=").append(usersession.getUserId());
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDrillSecurityInfo(usersession));
        try
        {
            stringbuffer.append("&pPreFunction=").append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getFunctionName(), s1));
            stringbuffer.append("&pBCFromFunction=").append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getFunctionName(), s1));
            stringbuffer.append("&pUrlString=").append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.OAEncrypt(usersession.getWebAppsContext(), s));
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        return od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getOAMacUrl(stringbuffer.toString(), usersession.getWebAppsContext());
    }

    public static java.lang.String getDrillSecurityInfo(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        try
        {
            stringbuffer.append("&pRespId=").append(usersession.getResponsibilityId());
            stringbuffer.append("&pRespAppId=").append(usersession.getRespApplId());
            stringbuffer.append("&pSecGrpId=").append(usersession.getSecurityGroupId());
        }
        catch(java.lang.Exception _ex) { }
        return stringbuffer.toString();
    }

    public static oracle.apps.bis.pmv.parameters.Parameters getBusinessPlanParameter(java.sql.Connection connection)
    {
        java.lang.String s = "SELECT plan_id, name FROM bisbv_business_plans where current_plan_flag=:1";
        oracle.apps.bis.pmv.parameters.Parameters parameters = null;
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        try
        {
            preparedstatement = connection.prepareStatement(s);
            preparedstatement.setString(1, "Y");
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            oraclestatement.defineColumnType(1, 12, 2);
            oraclestatement.defineColumnType(2, 12, 80);
            resultset = preparedstatement.executeQuery();
            if(resultset.next())
            {
                java.lang.String s1 = resultset.getString(1);
                java.lang.String s2 = resultset.getString(2);
                parameters = new Parameters();
                parameters.setParameterName("BUSINESS_PLAN");
                parameters.setParameterValue(s1);
                parameters.setParameterDescription(s2);
            }
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
        return parameters;
    }

    public static void addOABCToPmv(oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean oabreadcrumbsbean, javax.servlet.jsp.PageContext pagecontext, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        if(oabreadcrumbsbean == null || oabreadcrumbsbean.getLinkCount() == 0 || pagecontext == null || webappscontext == null)
            return;
        int i = oabreadcrumbsbean.getLinkCount();
        Object obj = null;
        Object obj1 = null;
        long l = 0x8000000000000000L;
        oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(webappscontext);
        oracle.apps.fnd.functionSecurity.Function function = null;
        oracle.apps.bis.pmv.breadcrumb.BreadCrumbHelper.clearBreadCrumbs(pagecontext, webappscontext);
        for(int j = 0; j < i; j++)
        {
            oracle.apps.fnd.framework.webui.beans.nav.OALinkBean oalinkbean = (oracle.apps.fnd.framework.webui.beans.nav.OALinkBean)oabreadcrumbsbean.getLink(j);
            java.lang.StringBuffer stringbuffer = new StringBuffer(200);
            java.lang.String s = oalinkbean.getDestination();
            stringbuffer.append(s);
            if(s.indexOf(RF_URL) > -1)
            {
                try
                {
                    l = java.lang.Long.parseLong(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getUrlParamValue(s, "function_id"));
                }
                catch(java.lang.NumberFormatException _ex) { }
                function = functionsecurity.getFunction(l);
            }
            if(j == i - 1)
                stringbuffer.append("&pMode=").append("BCRUMB");
            if(function != null && od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.isPMVPageFunction(function.getWebHTMLCall()))
                oracle.apps.bis.pmv.breadcrumb.BreadCrumbHelper.addBreadCrumb(pagecontext, webappscontext, function.getFunctionName());
            else
                oracle.apps.bis.pmv.breadcrumb.BreadCrumbHelper.addBreadCrumb(pagecontext, webappscontext, oalinkbean.getText(), od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getOAMacUrl(stringbuffer.toString(), webappscontext));
            s = null;
            l = 0x8000000000000000L;
            function = null;
        }

    }

    public static java.lang.String getReportURL(oracle.apps.bis.pmv.session.UserSession usersession, java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        java.lang.String s1 = usersession.getWebAppsContext().getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(usersession.getWebAppsContext()));
        stringbuffer.append("../XXCRM_HTML/bisviewm.jsp?dbc=").append(usersession.getRequestInfo().getDBC());
        stringbuffer.append("&transactionid=").append(usersession.getTransactionId());
        stringbuffer.append("&regionCode=").append(usersession.getRegionCode());
        stringbuffer.append("&functionName=").append(usersession.getFunctionName());
        stringbuffer.append("&pFirstTime=0").append("&sessionid=").append(usersession.getSessionId());
        stringbuffer.append("&pMode=BKMARK&respId=").append(usersession.getResponsibilityId());
        stringbuffer.append("&respApplId=").append(usersession.getWebAppsContext().getRespApplId());
        stringbuffer.append("&resetParamDefault=Y");
        try
        {
            if(s != null && s.indexOf("&pmvN") >= 0)
                stringbuffer.append(s);
            else
            if(s != null)
                stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getParamDecodedString(s, s1));
        }
        catch(java.lang.Exception _ex) { }
        return stringbuffer.toString();
    }

    public static java.lang.String getParamDecodedString(java.lang.String s, java.lang.String s1)
    {
        try
        {
            java.lang.String s2 = oracle.cabo.share.url.EncoderUtils.decodeString(s, s1);
            for(int i = 0; s2.indexOf("&pmvN") < 0; i++)
            {
                s2 = oracle.cabo.share.url.EncoderUtils.decodeString(s2, s1);
                if(i >= 50)
                    break;
            }

            return s2;
        }
        catch(java.lang.Exception _ex)
        {
            return "";
        }
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillUtil.java 115.49 2007/01/30 11:45:49 nkishore noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillUtil.java 115.49 2007/01/30 11:45:49 nkishore noship $", "od.oracle.apps.xxcrm.bis.pmv.drill");
    public static java.lang.String RF_URL = "RF.jsp";

}
