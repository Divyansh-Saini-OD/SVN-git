// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODPMVDataProvider.java

package od.oracle.apps.xxcrm.bis.pmv.data;

import oracle.apps.bis.pmv.data.*;
import com.sun.java.util.collections.AbstractList;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.Iterator;
import com.sun.java.util.collections.Set;
import java.io.UnsupportedEncodingException;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.common.Util;
import oracle.apps.bis.data.DataObject;
import oracle.apps.bis.metadata.MetadataAttributes;
import oracle.apps.bis.msg.MessageLog;
import oracle.apps.bis.pmv.PMVException;
import oracle.apps.bis.pmv.common.PMVConstants;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil;
import oracle.apps.bis.pmv.lov.LovUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.metadata.DimLevelProperties;
import oracle.apps.bis.pmv.metadata.PMVBucketManager;
import oracle.apps.bis.pmv.metadata.PMVBucketObject;
import oracle.apps.bis.pmv.parameters.ParameterHelper;
import oracle.apps.bis.pmv.query.Calculation;
import oracle.apps.bis.pmv.session.RequestInfo;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.bis.pmv.table.DrillHelper;
import oracle.apps.fnd.common.Context;
import oracle.apps.fnd.common.ProfileStore;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.functionSecurity.FunctionSecurity;
import oracle.cabo.share.url.EncoderUtils;

// Referenced classes of package oracle.apps.bis.pmv.data:
//            PMVDataObject, PMVReportDataObject

public class ODPMVDataProvider
{

    public ODPMVDataProvider(java.util.Vector vector)
    {
        _env = "";
        _reportDataObject = new PMVReportDataObject(vector);
    }

    public ODPMVDataProvider(oracle.apps.bis.pmv.session.UserSession usersession, oracle.apps.bis.pmv.parameters.ParameterHelper parameterhelper, java.util.Vector vector)
        throws oracle.apps.bis.pmv.PMVException
    {
        _env = "";
        oracle.apps.bis.msg.MessageLog messagelog = null;
        int i = 0x7fffffff;
        try
        {
            messagelog = usersession.getPmvMsgLog();
            if(messagelog != null)
                i = messagelog.getLevel();
        }
        catch(java.lang.Exception _ex) { }
        boolean flag = usersession.isPortletMode();
        oracle.apps.bis.pmv.metadata.AKRegion akregion = usersession.getAKRegion();
        oracle.apps.bis.pmv.session.RequestInfo requestinfo = usersession.getRequestInfo();
        int j = requestinfo.getLowerBound();
        int k = requestinfo.getUpperBound();
        java.lang.String s = requestinfo.getNavMode();
        java.lang.String s1 = requestinfo.getScheduleId();
        boolean flag1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.isAutoGenFromDesigner(usersession.getAKRegion());
        try
        {
            if(messagelog != null && i == 5)
            {
                messagelog.newProgress("PMV Data Provider");
                if(i == 5)
                    messagelog.logMessage("PMV Data Provider", "ODPMVDataProvider: - (RequestInfo) lowerBound->" + j + "upperBound->" + k + ", navMode->" + s + ", scheduleId->" + s1, 5);
            }
        }
        catch(java.lang.Exception _ex) { }
        java.util.Vector vector1 = new Vector(vector.size());
        try
        {
            _env = usersession.getWebAppsContext().getProfileStore().getProfile("BIS_ENVIRONMENT");
            if(_env == null)
                _env = "";
            _propertiesDataObject = new PMVDataObject();
            boolean flag2 = false;
            int l;
            if(flag)
            {
                l = akregion.getPortletRows();
                flag2 = akregion.isPortletInWindowedMode();
            } else
            {
                l = akregion.getNumberOfRows();
                flag2 = akregion.isReportInWindowedMode();
            }
            int i1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMaxFetchRows(usersession.getWebAppsContext());
            int ai[] = getLowerUpperBound(j, k, s, l, vector.size(), flag2, i1);
            j = ai[0];
            k = ai[1];
            try
            {
                if(messagelog != null && i == 5)
                    messagelog.logMessage("PMV Data Provider", " ODPMVDataProvider lowerBound->" + j + ", upperBound->" + k + ", displayNumRows->" + l + ", isWindowedMode->" + flag2, i);
            }
            catch(java.lang.Exception _ex) { }
            com.sun.java.util.collections.HashMap hashmap = akregion.getSubMeasureMappings();
            for(int j1 = j; j1 < k; j1++)
            {
                java.util.Hashtable hashtable = new Hashtable(23);
                if(!_env.equals("TEST"))
                {
                    hashtable = (java.util.Hashtable)vector.elementAt(j1);
                } else
                {
                    java.util.Hashtable hashtable1 = (java.util.Hashtable)vector.elementAt(j1);
                    java.lang.String s4;
                    java.lang.String s7;
                    for(java.util.Enumeration enumeration = hashtable1.keys(); enumeration.hasMoreElements(); hashtable.put(s4, s7))
                    {
                        s4 = (java.lang.String)enumeration.nextElement();
                        s7 = (java.lang.String)hashtable1.get(s4);
                    }

                }
                com.sun.java.util.collections.Set set = hashmap.keySet();
                for(com.sun.java.util.collections.Iterator iterator = set.iterator(); iterator.hasNext();)
                {
                    java.lang.String s5 = (java.lang.String)iterator.next();
                    com.sun.java.util.collections.ArrayList arraylist1 = (com.sun.java.util.collections.ArrayList)hashmap.get(s5);
                    for(com.sun.java.util.collections.Iterator iterator1 = arraylist1.iterator(); iterator1.hasNext();)
                    {
                        java.lang.String s10 = (java.lang.String)iterator1.next();
                        java.lang.String s12 = (java.lang.String)hashtable.get(s10);
                        if(s12 != null && !s12.equals(""))
                        {
                            hashtable.put(s5, s12);
                            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)akregion.getAKRegionItems().get(s10);
                            java.lang.String s15 = akregionitem.getDataFormat();
                            java.lang.String s18 = akregionitem.getDataType();
                            int k1 = akregionitem.getCellLength();
                            java.lang.String s23 = "";
                            hashtable.put(s5 + "_" + "rowFormat", s15 != null ? ((java.lang.Object) (s15)) : "");
                            if(flag && usersession.getRequestInfo().getRequestType().equals("T") && k1 > 0 && "C".equals(s18))
                                hashtable.put(s5 + "_" + "rowCellLength", java.lang.String.valueOf(k1));
                            else
                                hashtable.put(s5 + "_" + "rowCellLength", "");
                            if(akregionitem.isAutoScaleItem())
                            {
                                s18 = akregion.getAutoScaleFactor(s18);
                                hashtable.put(s5 + "_" + "rowHideScaleSymbol", "true");
                            } else
                            {
                                hashtable.put(s5 + "_" + "rowHideScaleSymbol", "false");
                            }
                            hashtable.put(s5 + "_" + "rowDataType", s18 != null ? ((java.lang.Object) (s18)) : "");
                            java.util.Hashtable hashtable2 = akregion.getBaseColumns();
                            if(akregionitem.isCalculation())
                            {
                                s23 = akregionitem.getBaseColumn();
                                s23 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getSubstitutedFormula(s23, akregionitem, akregion.getCompareToMeasureMappings());
                                s23 = s23.substring(1, s23.length() - 1);
                                s23 = oracle.apps.bis.pmv.query.Calculation.substitute(hashtable2, s23, true);
                                try
                                {
                                    if(messagelog != null && i == 5)
                                        messagelog.logMessage("PMV Data Provider", " ODPMVDataProvider attrCode->" + s10 + ", value->" + s12 + ", format->" + s15 + ", formula->" + s23 + ", dataType->" + s18, i);
                                }
                                catch(java.lang.Exception _ex) { }
                            } else
                            {
                                s23 = "";
                            }
                            hashtable.put(s5 + "_" + "rowFormula", s23);
                            break;
                        }
                    }

                }

                vector1.addElement(hashtable);
            }

            java.lang.String s2 = parameterhelper.getNextViewByLevel();
            com.sun.java.util.collections.ArrayList arraylist = null;
            java.lang.String s3 = null;
            arraylist = oracle.apps.bis.pmv.parameters.ParameterHelper.getExtraViewByInfo(s2, akregion, akregion.getAKRegionItems());
            if(arraylist != null && arraylist.size() > 0)
                s3 = (java.lang.String)arraylist.get(1);
            parameterhelper.getViewbyAttributeCode();
            java.lang.String s6 = parameterhelper.getViewbyValue();
            java.lang.String s8 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getDimension(s6);
            java.lang.String s9 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getDimLevel(s6);
            java.lang.String s11 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getDimLevel(s2);
            java.lang.String s13 = parameterhelper.getOrgParamName();
            java.lang.String s14 = parameterhelper.getOrgParamValue();
            java.lang.String s16 = "";
            java.lang.String s19 = "";
            java.lang.String s20 = "";
            com.sun.java.util.collections.HashMap hashmap1 = akregion.getDrillAcrossURLMappings();
            com.sun.java.util.collections.HashMap hashmap2 = akregion.getSubtotalDrillURLMappings();
            java.util.Hashtable hashtable3 = akregion.getAKRegionItems();
            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem1 = (oracle.apps.bis.pmv.metadata.AKRegionItem)hashtable3.get(parameterhelper.getViewbyValue());
            boolean flag3 = false;
            if(akregionitem1 != null)
            {
                s19 = akregionitem1.getUrl();
                if(akregionitem1.getDimLevelProperties() != null && akregionitem1.getDimLevelProperties().isParent())
                    flag3 = true;
            }
            java.lang.String s24 = "";
            java.lang.String s25 = "";
            java.lang.String s28 = null;
            boolean flag4 = false;
            boolean flag5 = false;
            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem2 = null;
            if(akregionitem1 != null && (parameterhelper.getHasExtraViewBy() || !oracle.apps.bis.pmv.common.StringUtil.emptyString(akregionitem1.getExtraViewBy())))
            {
                flag5 = true;
                if(parameterhelper.getHasExtraViewBy())
                {
                    akregionitem2 = (oracle.apps.bis.pmv.metadata.AKRegionItem)hashtable3.get(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getAttr2FromAttrCode(akregion, parameterhelper.getExtraViewByValue()));
                    s28 = parameterhelper.getExtraViewByValue();
                } else
                {
                    akregionitem2 = (oracle.apps.bis.pmv.metadata.AKRegionItem)hashtable3.get(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getAttr2FromAttrCode(akregion, akregionitem1.getExtraViewBy()));
                    s28 = akregionitem1.getExtraViewBy();
                }
                if(akregionitem2 != null)
                {
                    s24 = akregionitem2.getUrl();
                    if(akregionitem2.getDimLevelProperties() != null && akregionitem2.getDimLevelProperties().isParent())
                        flag4 = true;
                }
            }
            com.sun.java.util.collections.ArrayList arraylist2 = null;
            if(usersession.getPageContext() != null)
                arraylist2 = (com.sun.java.util.collections.ArrayList)oracle.apps.bis.common.ServletWrapper.getSessionValue(usersession.getPageContext(), "SHOW_HIDE_CACHE_KEY" + usersession.getFunctionName());
            for(int l1 = 0; l1 < vector1.size(); l1++)
            {
                java.util.Hashtable hashtable4 = (java.util.Hashtable)vector1.elementAt(l1);
                com.sun.java.util.collections.ArrayList arraylist3 = akregion.getDisplayColumns();
                java.util.Hashtable hashtable5 = new Hashtable(11);
                for(int i2 = 0; i2 < arraylist3.size(); i2++)
                {
                    oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem3 = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist3.get(i2);
                    java.lang.String s30 = akregionitem3.getDimension();
                    java.lang.String s31 = akregionitem3.getDimensionLevel();
                    java.lang.String s33 = akregionitem3.getUrl();
                    java.lang.String s40 = null;
                    java.lang.String s42 = "";
                    java.lang.String s46 = "";
                    boolean flag8 = false;
                    java.lang.String s49 = (java.lang.String)hashmap1.get(akregionitem3.getAttributeCode());
                    java.lang.String s50 = (java.lang.String)hashmap2.get(akregionitem3.getAttributeCode());
                    java.lang.String s21 = (java.lang.String)hashtable4.get("VIEWBYID");
                    if(s33 != null && !s33.equals(""))
                    {
                        s33 = getAutoViewByPassingURL(s33, akregion.isViewBy(), s21);
                        s42 = getDrillAcrossURL(hashtable4, s33, s1, parameterhelper, usersession);
                        if(parameterhelper.getHasExtraViewBy())
                            s46 = getDrillAcrossURL(hashtable4, getSubtotalURL(s33), s1, parameterhelper, usersession);
                        if(s42 == null)
                            s42 = "";
                        s40 = s42;
                    } else
                    if(s49 != null && !s49.equals(""))
                    {
                        flag8 = true;
                        java.lang.String s34 = (java.lang.String)hashtable4.get(s49);
                        if(s34 != null && !s34.equals(""))
                        {
                            s34 = getAutoViewByPassingURL(s34, akregion.isViewBy(), s21);
                            s42 = getDrillAcrossURL(hashtable4, s34, s1, parameterhelper, usersession);
                            if(parameterhelper.getHasExtraViewBy())
                                s46 = getDrillAcrossURL(hashtable4, getSubtotalURL(s34), s1, parameterhelper, usersession);
                        }
                    } else
                    if(oracle.apps.bis.pmv.lov.LovUtil.isAutoDrillAcrossEnabled(s30, s31))
                    {
                        java.lang.String s51 = akregionitem3.getAttributeCode();
                        s42 = getAutoDrillAcrossURL(hashtable4, getAutoDrillParameterAttributeCodes(s30, s51, akregion.isViewBy()), s1, parameterhelper, usersession);
                    }
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s50))
                    {
                        java.lang.String s35 = (java.lang.String)hashtable4.get(s50);
                        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s35))
                            s46 = getDrillAcrossURL(hashtable4, s35, s1, parameterhelper, usersession);
                    }
                    if(s42 == null)
                        s42 = "";
                    if(s46 == null)
                        s46 = "";
                    if(hashtable5.get(akregionitem3.getAttributeCode() + "_" + "url") == null)
                    {
                        oracle.apps.bis.pmv.metadata.PMVBucketObject pmvbucketobject = oracle.apps.bis.pmv.metadata.PMVBucketManager.getBucketObject(akregionitem3, parameterhelper);
                        if(pmvbucketobject != null)
                        {
                            com.sun.java.util.collections.ArrayList arraylist5 = pmvbucketobject.getLeafNodes();
                            int j2 = arraylist5.size();
                            if(j2 > 0)
                            {
                                for(int k2 = 0; k2 < j2; k2++)
                                {
                                    oracle.apps.bis.pmv.metadata.PMVBucketObject pmvbucketobject1 = (oracle.apps.bis.pmv.metadata.PMVBucketObject)arraylist5.get(k2);
                                    java.lang.String s60 = pmvbucketobject1.getId();
                                    java.lang.String s62 = (java.lang.String)pmvbucketobject1.getAttribute("DU");
                                    java.lang.String s63 = akregionitem3.getUrl();
                                    if(s63 != null && s63.length() > 0)
                                        hashtable5.put(s60 + "_" + "url", s40);
                                    else
                                    if(flag8)
                                    {
                                        java.lang.String s64 = (java.lang.String)hashtable4.get(s62);
                                        if(s64 != null && !s64.equals(""))
                                        {
                                            s42 = getDrillAcrossURL(hashtable4, s64, s1, parameterhelper, usersession);
                                            if(flag1)
                                                s42 = getDesignerWarningUrl(s42);
                                            hashtable5.put(s60 + "_" + "url", s42);
                                        }
                                    }
                                }

                            }
                        } else
                        {
                            if(flag1)
                                s42 = getDesignerWarningUrl(s42);
                            hashtable5.put(akregionitem3.getAttributeCode() + "_" + "url", s42);
                            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s46))
                                hashtable5.put(akregionitem3.getAttributeCode() + "_" + "subTotalUrl", s46);
                        }
                    }
                    com.sun.java.util.collections.ArrayList arraylist4 = (com.sun.java.util.collections.ArrayList)hashmap.get(akregionitem3.getAttributeCode());
                    if(arraylist4 != null)
                    {
                        java.lang.String s53;
                        for(com.sun.java.util.collections.Iterator iterator2 = arraylist4.iterator(); iterator2.hasNext(); hashtable5.put(s53 + "_" + "url", s42))
                        {
                            s53 = (java.lang.String)iterator2.next();
                            if(flag1)
                                s42 = getDesignerWarningUrl(s42);
                        }

                    }
                    if(flag8)
                    {
                        java.lang.String s36 = "";
                        java.lang.String s43 = "";
                        java.lang.String s47 = "";
                    }
                    java.lang.String s52 = akregionitem3.getAttributeCode() + "_TARGET";
                    if(hashtable4.get(s52) != null)
                    {
                        java.lang.String s54 = (java.lang.String)hashtable4.get(s52);
                        java.lang.String as[] = new java.lang.String[4];
                        as = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getTargetInfo(s54);
                        if(!as[1].equals("NONE"))
                            s54 = as[1];
                        else
                            s54 = "";
                        hashtable4.put(s52, s54);
                        hashtable5.put(s52 + "_" + "url", as[0]);
                        if(!s54.equals("NONE") && !as[2].equals("NONE") && !as[3].equals("NONE"))
                        {
                            java.lang.String s59 = (java.lang.String)hashtable4.get(akregionitem3.getAttributeCode());
                            java.lang.String s61 = toleranceTest(usersession, s59, s54, as[2], as[3]);
                            if(!s61.equals(""))
                                hashtable5.put(akregionitem3.getAttributeCode() + "_" + "ciStatus", s61);
                        }
                    }
                    if(akregionitem3.isErrorMessage() && (hashtable4 != null) & (akregionitem3.getAttributeCode() != null))
                    {
                        java.lang.String s55 = (java.lang.String)hashtable4.get(akregionitem3.getAttributeCode());
                        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s55))
                        {
                            if(!"Y".equals(akregionitem3.getDisplayFlag()))
                            {
                                if(usersession.getPageContext() != null)
                                    oracle.apps.bis.common.ServletWrapper.putSessionValue(usersession.getPageContext(), "BIS_ERROR_MESSAGE", "Y");
                                throw new PMVException(s55);
                            }
                            java.lang.String s57 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getErrorMessage(s55, usersession.getWebAppsContext());
                            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s57))
                                hashtable4.put(akregionitem3.getAttributeCode(), s57);
                        }
                    }
                    try
                    {
                        if(akregionitem3.isCalculation())
                        {
                            java.lang.String s56 = akregionitem3.getBaseColumn();
                            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s56))
                            {
                                s56 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getSubstitutedFormula(s56, akregionitem3, akregion.getCompareToMeasureMappings());
                                s56 = s56.substring(1, s56.length() - 1);
                                java.lang.String s58 = oracle.apps.bis.common.Util.substituteFormulaWithValues(s56, hashtable4, akregion, akregionitem3, true, usersession.getConnection(), usersession.getWebAppsContext(), parameterhelper, usersession);
                                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s58))
                                    hashtable4.put(akregionitem3.getAttributeCode() + "_PMV_CST", s58);
                            }
                        }
                    }
                    catch(java.lang.Exception _ex) { }
                }

                java.lang.String s29 = (java.lang.String)hashtable4.get("EXTRADRILLPIVOTURL");
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s29))
                {
                    s29 = oracle.apps.bis.pmv.table.DrillHelper.replaceUrl(parameterhelper, hashtable4, s29, usersession);
                    hashtable4.put("EXTRADRILLPIVOTURL", s29);
                }
                java.lang.String s32;
                java.lang.String s37;
                for(java.util.Enumeration enumeration1 = hashtable5.keys(); enumeration1.hasMoreElements(); hashtable4.put(s32, s37))
                {
                    s32 = (java.lang.String)enumeration1.nextElement();
                    s37 = (java.lang.String)hashtable5.get(s32);
                }

                if(akregion.isViewBy())
                {
                    boolean flag6 = false;
                    java.lang.String s38 = null;
                    java.lang.String s41 = null;
                    if(akregionitem1 != null)
                    {
                        s38 = (java.lang.String)hashmap1.get(akregionitem1.getAttributeCode());
                        s41 = (java.lang.String)hashmap2.get(akregionitem1.getAttributeCode());
                    }
                    java.lang.String s17 = (java.lang.String)hashtable4.get("VIEWBY");
                    java.lang.String s22 = (java.lang.String)hashtable4.get("VIEWBYID");
                    java.lang.String s44 = "";
                    java.lang.String s48 = "";
                    if(s19 != null && !s19.equals(""))
                    {
                        s19 = getAutoViewByPassingURL(s19, akregion.isViewBy(), s22);
                        s19 = oracle.apps.bis.pmv.common.StringUtil.replaceAll(s19, "&EXTRAVIEW_BY_NAME=EXTRAVIEW_BY_ID", "");
                        s44 = getDrillAcrossURL(hashtable4, s19, s1, parameterhelper, usersession);
                    } else
                    if(s38 != null && !s38.equals(""))
                    {
                        flag6 = true;
                        s19 = (java.lang.String)hashtable4.get(s38);
                        if(s19 != null && !s19.equals(""))
                        {
                            s19 = getAutoViewByPassingURL(s19, akregion.isViewBy(), s22);
                            s44 = getDrillAcrossURL(hashtable4, s19, s1, parameterhelper, usersession);
                        }
                    } else
                    if(oracle.apps.bis.pmv.lov.LovUtil.isAutoDrillAcrossEnabled(s8, s9) || flag4 || flag3)
                        s44 = getExtraViewByDrillAcrossURL(hashtable4, s1, parameterhelper, usersession, s28, true);
                    else
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s41))
                    {
                        s19 = (java.lang.String)hashtable4.get(s41);
                        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s19))
                            s48 = getDrillAcrossURL(hashtable4, s19, s1, parameterhelper, usersession);
                    } else
                    if(!s2.equals("") && (!akregion.isPlSqlFunctionSet() && !akregion.isMultipleSource() || !"TIME".equals(s8) && !"EDW_TIME_M".equals(s8) && (s8 == null || !s8.equals(akregion.getBscTimeDimension()))) && arraylist2 != null && !arraylist2.contains(s2))
                        s44 = getDrillDownURL(s17, s22, s9, s6, s11, s2, s3, s8, s13, s14, s1, usersession);
                    if(flag1)
                        s44 = getDesignerWarningUrl(s44);
                    if(s44 == null)
                        s44 = "";
                    hashtable4.put("viewbyUrl", s44);
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s48))
                        hashtable4.put(akregionitem1.getAttributeCode() + "_" + "subTotalUrl", s48);
                    if(flag6)
                    {
                        s19 = "";
                        java.lang.String s45 = "";
                    }
                    if(flag5)
                    {
                        boolean flag7 = false;
                        java.lang.String s39 = null;
                        if(akregionitem2 != null)
                            s39 = (java.lang.String)hashmap1.get(akregionitem2.getAttributeCode());
                        java.lang.String s26 = null;
                        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s24))
                            s26 = getDrillAcrossURL(hashtable4, s24, s1, parameterhelper, usersession);
                        else
                        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s39))
                        {
                            flag7 = true;
                            s24 = (java.lang.String)hashtable4.get(s39);
                            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s24))
                                s26 = getDrillAcrossURL(hashtable4, s24, s1, parameterhelper, usersession);
                        } else
                        if(flag4)
                            s26 = getExtraViewByDrillAcrossURL(hashtable4, s1, parameterhelper, usersession, s28, false);
                        if(s26 != null)
                        {
                            if(flag1)
                                s26 = getDesignerWarningUrl(s26);
                            hashtable4.put("extraViewbyUrl", s26);
                        }
                        if(flag7)
                        {
                            s24 = "";
                            java.lang.String s27 = "";
                        }
                    }
                }
            }

        }
        catch(java.lang.Exception exception1)
        {
            try
            {
                if(messagelog != null && i == 5)
                    messagelog.logMessage("PMV Data Provider", " ODPMVDataProvider Error ->" + exception1.getMessage(), i);
            }
            catch(java.lang.Exception _ex) { }
            if(exception1 instanceof oracle.apps.bis.pmv.PMVException)
                throw new PMVException(exception1);
        }
        finally
        {
            try
            {
                if(messagelog != null && i == 5)
                    messagelog.closeProgress("PMV Data Provider");
            }
            catch(java.lang.Exception _ex) { }
        }
        _reportDataObject = new PMVReportDataObject(vector1);
    }

    public oracle.apps.bis.data.DataObject getDataObject(java.lang.Object obj)
    {
        if(obj.equals("reportDO"))
            return _reportDataObject;
        else
            return _propertiesDataObject;
    }

    private com.sun.java.util.collections.ArrayList getAutoDrillParameterAttributeCodes(java.lang.String s, java.lang.String s1, boolean flag)
    {
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(3);
        if(s != null && ("TIME".equals(s) || "EDW_TIME_M".equals(s)))
        {
            arraylist.add(s1 + "_FROM");
            arraylist.add(s1 + "_TO");
        } else
        {
            arraylist.add(s1);
        }
        if(flag)
            arraylist.add("VIEW_BY");
        return arraylist;
    }

    private java.lang.String getAutoDrillAcrossURL(java.util.Hashtable hashtable, com.sun.java.util.collections.ArrayList arraylist, java.lang.String s, oracle.apps.bis.pmv.parameters.ParameterHelper parameterhelper, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        stringbuffer.append("pFunctionName=").append(usersession.getFunctionName());
        if(arraylist != null)
        {
            for(int i = 0; i < arraylist.size(); i++)
            {
                java.lang.String s1 = (java.lang.String)arraylist.get(i);
                stringbuffer.append("&").append(s1).append("=").append(s1);
            }

        }
        return getDrillAcrossURL(hashtable, stringbuffer.toString(), s, parameterhelper, usersession);
    }

    private java.lang.String getExtraViewByDrillAcrossURL(java.util.Hashtable hashtable, java.lang.String s, oracle.apps.bis.pmv.parameters.ParameterHelper parameterhelper, oracle.apps.bis.pmv.session.UserSession usersession, java.lang.String s1, boolean flag)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        stringbuffer.append("pFunctionName=").append(usersession.getFunctionName());
        stringbuffer.append("&").append("VIEW_BY").append("=");
        if(parameterhelper.getHasExtraViewBy())
            stringbuffer.append(parameterhelper.getViewbyValue()).append("-").append(s1);
        else
            stringbuffer.append(parameterhelper.getViewbyValue());
        java.lang.String s2 = (java.lang.String)hashtable.get("VIEWBYID");
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
            stringbuffer.append("&").append(parameterhelper.getViewbyValue()).append("=").append(hashtable.get("VIEWBY"));
        else
            stringbuffer.append("&").append(parameterhelper.getViewbyValue()).append("=").append(hashtable.get("VIEWBYID"));
        if(!flag)
        {
            java.lang.String s3 = (java.lang.String)hashtable.get("EXTRAVIEWBYID");
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s3))
                stringbuffer.append("&").append(s1).append("=").append(hashtable.get("EXTRAVIEWBY"));
            else
                stringbuffer.append("&").append(s1).append("=").append(hashtable.get("EXTRAVIEWBYID"));
        }
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
            stringbuffer.append("&").append("pParamIds=Y");
        return getDrillAcrossURL(hashtable, stringbuffer.toString(), s, parameterhelper, usersession);
    }

    private java.lang.String getDrillAcrossURL(java.util.Hashtable hashtable, java.lang.String s, java.lang.String s1, oracle.apps.bis.pmv.parameters.ParameterHelper parameterhelper, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(600);
        java.lang.String s2 = oracle.apps.bis.pmv.table.DrillHelper.replaceUrl(parameterhelper, hashtable, s, usersession);
        if(s2 != null && s2.toUpperCase().startsWith("HTTP"))
            return s2;
        java.lang.String s3 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s2, "pFunctionName");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s3) && (usersession.isPMVPlotterMode() && s2 != null && !isFunctionValid(s2, usersession) || s3.equals((java.lang.String)oracle.apps.bis.common.ServletWrapper.getSessionValue(usersession.getPageContext(), "bisdf"))))
        {
            oracle.apps.bis.common.ServletWrapper.putSessionValue(usersession.getPageContext(), "bisdf", s3);
            s2 = s2 + "&pRegionCode=" + usersession.getRegionCode();
        }
        java.lang.String s4 = usersession.getWebAppsContext().getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        java.lang.String s5 = null;
        if(usersession.getRequestInfo() != null)
            s5 = usersession.getRequestInfo().getPageId();
        if(s5 != null && s5.length() > 0 && (s5.indexOf(",") > 0 || java.lang.Integer.parseInt(s5) > 0))
            stringbuffer.append(usersession.getWebAppsContext().getProfileStore().getProfile("APPS_FRAMEWORK_AGENT"));
        stringbuffer.append("/OA_HTML/OA.jsp?page=/od/oracle/apps/xxcrm/bis/pmv/drill/webui/DrillPG&retainAM=Y&addBreadCrumb=Y&pMode=1&pSessionId=").append(usersession.getSessionId());
        if(usersession.getRequestInfo() != null)
        {
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(usersession.getRequestInfo().getDBC()))
                stringbuffer.append("&").append("dbc").append("=").append(usersession.getRequestInfo().getDBC());
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(usersession.getRequestInfo().getTxId()))
                stringbuffer.append("&").append("transactionid").append("=").append(usersession.getRequestInfo().getTxId());
        }
        stringbuffer.append("&pUserId=").append(usersession.getUserId());
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDrillSecurityInfo(usersession));
        try
        {
            java.lang.String s6 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getPageFunctionName(s5, usersession.getWebAppsContext());
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s6))
                s6 = usersession.getFunctionName();
            stringbuffer.append("&pBCFromFunction=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s6, s4));
            stringbuffer.append("&pPreFunction=").append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getFunctionName(), s4));
            if(s5 != null && s5.length() > 0 && (s5.indexOf(",") > 0 || java.lang.Integer.parseInt(s5) > 0))
            {
                stringbuffer.append("&pUrlString=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s2, s4));
            } else
            {
                java.lang.String s7 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.OAEncrypt(usersession.getWebAppsContext(), s2);
                stringbuffer.append("&pUrlString=").append(s7);
                Object obj = null;
                int i = 0x7fffffff;
                try
                {
                    oracle.apps.bis.msg.MessageLog messagelog = usersession.getPmvMsgLog();
                    if(messagelog != null)
                    {
                        int j = messagelog.getLevel();
                        if(j == 5)
                            messagelog.logMessage("PMV Data Provider", " ODPMVDataProvider Drill URL ->" + s2 + ", ENCRYPTED: " + s7, j);
                    }
                }
                catch(java.lang.Exception _ex) { }
            }
        }
        catch(java.lang.Exception _ex) { }
        if(s1 != null)
            stringbuffer.append("&pScheduleId=").append(s1);
        if(s5 != null && s5.length() > 0)
            stringbuffer.append("&pPageId=").append(s5);
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameter(usersession.getPageContext(), usersession.getRequest(), "hideNav")))
            stringbuffer.append("&").append("hideNav").append("=").append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameter(usersession.getPageContext(), usersession.getRequest(), "hideNav"));
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameter(usersession.getPageContext(), usersession.getRequest(), "tab")))
            stringbuffer.append("&").append("tab").append("=").append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameter(usersession.getPageContext(), usersession.getRequest(), "tab"));
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameter(usersession.getPageContext(), usersession.getRequest(), "designer")))
            stringbuffer.append("&").append("designer").append("=").append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameter(usersession.getPageContext(), usersession.getRequest(), "designer"));
        return od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getOAMacUrl(stringbuffer.toString(), usersession.getWebAppsContext());
    }

    private java.lang.String getDrillDownURL(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5, java.lang.String s6,
            java.lang.String s7, java.lang.String s8, java.lang.String s9, java.lang.String s10, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(600);
        java.lang.String s11 = usersession.getWebAppsContext().getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        try
        {
            stringbuffer.append("/OA_HTML/OA.jsp?page=/od/oracle/apps/xxcrm/bis/pmv/drill/webui/DrillPG&retainAM=Y&addBreadCrumb=Y&pMode=2&pRegionCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getRegionCode(), s11));
            if(usersession.getRequestInfo() != null)
            {
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(usersession.getRequestInfo().getDBC()))
                    stringbuffer.append("&").append("dbc").append("=").append(usersession.getRequestInfo().getDBC());
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(usersession.getRequestInfo().getTxId()))
                    stringbuffer.append("&").append("transactionid").append("=").append(usersession.getRequestInfo().getTxId());
            }
            stringbuffer.append("&pFunction=").append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getFunctionName(), s11));
            stringbuffer.append("&pSessionId=").append(usersession.getSessionId());
            stringbuffer.append("&pUserId=").append(usersession.getUserId());
            stringbuffer.append("&pRespId=").append(usersession.getResponsibilityId());
            stringbuffer.append("&pRespAppId=").append(usersession.getRespApplId());
            stringbuffer.append("&pSecGrpId=").append(usersession.getSecurityGroupId());
            stringbuffer.append("&pCurrValue=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s, s11));
            stringbuffer.append("&pCurrLevel=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s2, s11));
            stringbuffer.append("&pCurrAttCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s3, s11));
            stringbuffer.append("&pNextLevel=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s4, s11));
            stringbuffer.append("&pNextAttCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s5, s11));
            if(s6 != null)
                stringbuffer.append("&pNextExtraViewBy=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s6, s11));
            stringbuffer.append("&pDimension=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s7, s11));
            stringbuffer.append("&pOrgParam=");
            if(s8 != null)
                stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString(s8, s11));
            stringbuffer.append("&pOrgValue=");
            if(s9 != null)
                stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString(s9, s11));
            if(s10 != null)
                stringbuffer.append("&pScheduleId=").append(s10);
            if(s1 != null)
                stringbuffer.append("&pCurrValueId=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s1, s11));
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameter(usersession.getPageContext(), usersession.getRequest(), "hideNav")))
                stringbuffer.append("&").append("hideNav").append("=").append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameter(usersession.getPageContext(), usersession.getRequest(), "hideNav"));
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameter(usersession.getPageContext(), usersession.getRequest(), "tab")))
                stringbuffer.append("&").append("tab").append("=").append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameter(usersession.getPageContext(), usersession.getRequest(), "tab"));
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        java.lang.String s12 = usersession.getRequestInfo().getPageId();
        if(s12 != null && s12.length() > 0)
            stringbuffer.append("&pPageId=").append(s12);
        return od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getOAMacUrl(stringbuffer.toString(), usersession.getWebAppsContext());
    }

    private java.lang.String toleranceTest(oracle.apps.bis.pmv.session.UserSession usersession, java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3)
    {
        java.lang.String s4 = "";
        java.lang.String s5 = oracle.apps.bis.pmv.query.Calculation.toleranceTest(s2, s3, s1, s, usersession.getConnection());
        if(!s5.equals("ON"))
            s4 = "outOfTolerance";
        return s4;
    }

    private int[] getLowerUpperBound(int i, int j, java.lang.String s, int k, int l, boolean flag, int i1)
    {
        int ai[] = new int[2];
        if("EXPORT".equals(s))
        {
            i = 0;
            j = l;
        } else
        if(flag)
        {
            if(!s.equals("PREVIOUS") && !s.equals("NEXT"))
            {
                if(k < l)
                    _propertiesDataObject.setValue("next", "true");
            } else
            if(s.equals("NEXT"))
            {
                _propertiesDataObject.setValue("prev", "true");
                if(k < l && j + k < i1)
                    _propertiesDataObject.setValue("next", "true");
            } else
            {
                if(i > k)
                    _propertiesDataObject.setValue("prev", "true");
                if(k < l && j <= i1)
                    _propertiesDataObject.setValue("next", "true");
            }
            i = 0;
            j = k;
        } else
        if("ALL".equals(s) || !_env.equals("TEST"))
        {
            i = 0;
            j = l;
        } else
        if("PREVIOUS".equals(s))
        {
            j = i;
            i -= k;
        } else
        if("NEXT".equals(s))
        {
            i += k;
            j += k;
        } else
        {
            i = 0;
            j = k;
        }
        if(j > l)
            j = l;
        ai[0] = i;
        ai[1] = j;
        return ai;
    }

    protected java.lang.String getDesignerWarningUrl(java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            stringbuffer.append("javascript:doWarnForDsg('");
            stringbuffer.append(s);
            stringbuffer.append("');");
        }
        return stringbuffer.toString();
    }

    private java.lang.String getSubtotalURL(java.lang.String s)
    {
        if(s != null)
        {
            if(s.indexOf("pParamIds=Y") >= 0)
                return oracle.apps.bis.pmv.common.StringUtil.replaceFirst(s, "=EXTRAVIEWBY", "=VIEWBY");
            else
                return oracle.apps.bis.pmv.common.StringUtil.replaceFirst(s, "=EXTRAVIEWBYID", "=VIEWBYID");
        } else
        {
            return null;
        }
    }

    private java.lang.String getAutoViewByPassingURL(java.lang.String s, boolean flag, java.lang.String s1)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        if(s != null && s.startsWith("pFunctionName=") && s.lastIndexOf('=') == 13 && flag)
        {
            stringbuffer.append(s).append("&VIEW_BY_NAME=");
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                stringbuffer.append("VIEW_BY_VALUE");
            else
                stringbuffer.append("VIEW_BY_ID&pParamIds=Y");
            return stringbuffer.toString();
        } else
        {
            return s;
        }
    }

    private boolean isFunctionValid(java.lang.String s, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        if(usersession == null)
            return false;
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s, "pFunctionName");
        oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(usersession.getWebAppsContext());
        if(functionsecurity != null)
        {
            oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(s1);
            if(function != null)
                return true;
        }
        return false;
    }

    public static final java.lang.String RCS_ID = "$Header: ODPMVDataProvider.java 115.74 2006/09/11 12:33:17 nbarik noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODPMVDataProvider.java 115.74 2006/09/11 12:33:17 nbarik noship $", "oracle.apps.bis.pmv.data");
    oracle.apps.bis.pmv.data.PMVReportDataObject _reportDataObject;
    oracle.apps.bis.pmv.data.PMVDataObject _propertiesDataObject;
    java.lang.String _env;

}
