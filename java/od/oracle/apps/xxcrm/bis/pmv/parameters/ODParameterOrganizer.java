// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODParameterOrganizer.java

package od.oracle.apps.xxcrm.bis.pmv.parameters;
import oracle.apps.bis.pmv.parameters.ParameterObject;
import oracle.apps.bis.pmv.parameters.*;
import com.sun.java.util.collections.AbstractCollection;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.Iterator;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.Map;
import com.sun.java.util.collections.Set;
import java.io.UnsupportedEncodingException;
import java.sql.Connection;
import java.util.StringTokenizer;
import javax.servlet.http.HttpSession;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.pmv.common.LookUpHelper;
import oracle.apps.bis.pmv.common.PMVConstants;
import oracle.apps.bis.pmv.common.PMVUtil;
import oracle.apps.bis.pmv.common.RTCUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.metadata.DimLevelProperties;
import oracle.apps.bis.pmv.query.Calculation;
import oracle.apps.bis.pmv.session.RequestInfo;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.AppsContext;
import oracle.apps.fnd.common.Context;
import oracle.apps.fnd.common.ProfileStore;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.cabo.share.url.EncoderUtils;

// Referenced classes of package oracle.apps.bis.pmv.parameters:
//            AsOfDateParameter, BusinessPlanParameter, DateParameter, DimensionParameter,
//            HierarchyHelper, HierarchyParameter, MultiLevelParameter, MultiValueParameter,
//            ParameterHelper, ParameterObject, ParameterUtil, Parameters,
//            TimeComparisonTypeParameter, TimeDimensionParameter, ViewByParameter

public class ODParameterOrganizer
{

    public ODParameterOrganizer(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        m_ShowBP = false;
        m_ShowViewBy = false;
        m_HasExtraViewBy = false;
        m_CurrentSelectedTimeParamName = "";
        m_PeriodFromValueAdded = false;
        m_PortletMode = false;
        m_EmailMode = false;
        m_DispRun = false;
        m_DBI = false;
        m_BaseDrillLink = "";
        m_DateParamAdded = false;
        m_AsOfDateHidden = false;
        m_UserSession = usersession;
        init();
        constructParameterObjects();
    }

    private void init()
    {
        m_PortletMode = "P".equals(m_UserSession.getRequestInfo().getRequestType());
        m_EmailMode = m_UserSession.getPageContext() != null && "Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_UserSession.getPageContext(), "email"));
        m_DispRun = "Y".equals(m_UserSession.getRequestInfo().getDispRun());
        m_AKRegion = m_UserSession.getAKRegion();
        m_DBI = !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_UserSession.getAKRegion().getPageParameterRegionName()) || m_UserSession.getAKRegion().hasAsOfDate() || "3".equals(m_UserSession.getAKRegion().getParameterLayoutType());
        m_ShowBP = m_UserSession.getAKRegion().hasMeasures() && !m_PortletMode;
        m_ShowViewBy = m_UserSession.getAKRegion().isViewBy() && m_UserSession.showViewBy();
        m_ParamItems = m_UserSession.getAKRegion().getSortedItems();
        m_ParamHelper = m_UserSession.getParameterHelper();
        m_ParamInfo = m_ParamHelper.getParameterValues();
        if(m_ParamInfo == null)
            m_ParamInfo = new HashMap(1);
        m_HasExtraViewBy = m_ParamHelper.getHasExtraViewBy();
        m_HierarchyValues = m_ParamHelper.getHierarchyValue();
        m_Conn = m_UserSession.getConnection();
        m_FilterLevels = m_UserSession.getFilterLevels();
        m_ParameterObjects = new ArrayList(20);
        m_CurrentParamCount = 0;
        m_CurrentSelectedItem = null;
        m_CurrentParams = new ArrayList(5);
        if(m_UserSession.getPageContext() != null && ("Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_UserSession.getPageContext(), "pEditParamLinkEnable")) || m_UserSession.isPersonalizePortletMode() && !"Y".equals(oracle.apps.bis.common.ServletWrapper.getParameter(m_UserSession.getPageContext(), "pEditParamLinkEnable"))))
            m_EditParameter = true;
        if(m_ShowViewBy)
            m_ViewByParam = new ViewByParameter();
        m_BaseDrillLink = createBaseDrillLink();
        oracle.apps.bis.pmv.common.RTCUtil.setRTCProfiles(m_UserSession.getWebAppsContext());
        m_FrameworkAgent = oracle.apps.bis.pmv.common.PMVUtil.getFrameworkAgent(m_UserSession.getWebAppsContext());
    }

    public com.sun.java.util.collections.List getParameterObjects()
    {
        return m_ParameterObjects;
    }

    private void processShowHideParameters()
    {
        com.sun.java.util.collections.HashMap hashmap = oracle.apps.bis.pmv.parameters.ParameterUtil.createMultiLevelParamsMap(m_UserSession);
        int i = m_ParamItems.size();
        for(int j = 0; j < i; j++)
        {
            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)m_ParamItems.get(j);
            if(akregionitem != null && !oracle.apps.bis.pmv.common.StringUtil.emptyString(akregionitem.getShowHideFunction()) && (hashmap == null || hashmap.get(akregionitem.getDimension()) == null))
            {
                boolean flag = oracle.apps.bis.pmv.parameters.ParameterUtil.hideParameter(akregionitem.getShowHideFunction(), akregionitem.getParamName(), m_ParamInfo, m_UserSession.getConnection());
                if(flag)
                    m_ShowHideParamNames.add(akregionitem.getParamName());
            }
        }

        if(hashmap != null)
        {
            for(com.sun.java.util.collections.Iterator iterator = hashmap.keySet().iterator(); iterator.hasNext();)
            {
                java.lang.String s = (java.lang.String)iterator.next();
                com.sun.java.util.collections.ArrayList arraylist = (com.sun.java.util.collections.ArrayList)hashmap.get(s);
                if(arraylist != null)
                {
                    for(int k = 0; k < arraylist.size(); k++)
                    {
                        oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem1 = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist.get(k);
                        if(akregionitem1 != null && !oracle.apps.bis.pmv.common.StringUtil.emptyString(akregionitem1.getShowHideFunction()))
                        {
                            boolean flag1 = oracle.apps.bis.pmv.parameters.ParameterUtil.hideParameter(akregionitem1.getShowHideFunction(), akregionitem1.getParamName(), m_ParamInfo, m_UserSession.getConnection());
                            if(flag1)
                                m_ShowHideParamNames.add(akregionitem1.getParamName());
                        }
                    }

                }
            }

        }
        if(m_UserSession.getPageContext() != null && m_UserSession.getPageContext().getSession() != null)
            m_UserSession.getPageContext().getSession().putValue("SHOW_HIDE_CACHE_KEY" + m_UserSession.getFunctionName(), m_ShowHideParamNames);
    }

    private void constructParameterObjects()
    {
        java.lang.String s = "";
        int i = 0;
        int j = m_ParamItems.size();
        boolean flag = false;
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(m_ParamInfo.size());
        for(com.sun.java.util.collections.Iterator iterator = m_ParamInfo.keySet().iterator(); iterator.hasNext();)
        {
            oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)m_ParamInfo.get(iterator.next());
            if(parameters != null && parameters.getParameterName() != null)
            {
                java.lang.String s1 = parameters.getParameterName();
                boolean flag1 = true;
                if(s1.endsWith("_FROM") || s1.endsWith("_TO"))
                {
                    if(s1.endsWith("_FROM"))
                        m_SavedTimeParamName = s1.substring(0, s1.indexOf("_FROM"));
                    else
                        m_SavedTimeParamName = s1.substring(0, s1.indexOf("_TO"));
                } else
                {
                    for(int j1 = 0; j1 < oracle.apps.bis.pmv.common.PMVConstants.DATE_IGNORE_ARRAY.length; j1++)
                        if(oracle.apps.bis.pmv.common.PMVConstants.DATE_IGNORE_ARRAY[j1].equals(s1))
                            flag1 = false;

                    if(flag1)
                        arraylist.add(s1);
                }
            }
        }

        if(m_UserSession.getPageContext() != null && m_UserSession.getPageContext().getSession() != null)
            m_ShowHideParamNames = (com.sun.java.util.collections.ArrayList)m_UserSession.getPageContext().getSession().getValue("SHOW_HIDE_CACHE_KEY" + m_UserSession.getFunctionName());
        if(m_ShowHideParamNames == null)
            m_ShowHideParamNames = new ArrayList(5);
        if(m_EmailMode || m_PortletMode)
            processShowHideParameters();
        int k = 0;
        if(m_ShowHideParamNames != null)
            k = m_ShowHideParamNames.size();
        for(int l = 0; l < j; l++)
        {
            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)m_ParamItems.get(l);
            java.lang.String s2 = "DATE PARAMETER".equals(akregionitem.getRegionItemType()) ? akregionitem.getAttributeCode() : akregionitem.getAttribute2();
            boolean flag2 = false;
            for(int l1 = 0; l1 < k; l1++)
            {
                java.lang.String s4 = (java.lang.String)m_ShowHideParamNames.get(l1);
                if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s4) || !s4.equals(s2))
                    continue;
                flag2 = true;
                break;
            }

            if(!flag2 && m_ParamInfo.get(s2) == null && !oracle.apps.bis.pmv.common.StringUtil.emptyString(akregionitem.getShowHideFunction()) && oracle.apps.bis.pmv.parameters.ParameterUtil.hideParameter(akregionitem.getShowHideFunction(), s2, m_ParamInfo, m_UserSession.getConnection()))
                m_ShowHideParamNames.add(s2);
        }

        if(m_ShowHideParamNames != null)
            k = m_ShowHideParamNames.size();
        for(int i1 = 0; i1 < j; i1++)
        {
            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem1 = (oracle.apps.bis.pmv.metadata.AKRegionItem)m_ParamItems.get(i1);
            java.lang.String s3 = "DATE PARAMETER".equals(akregionitem1.getRegionItemType()) ? akregionitem1.getAttributeCode() : akregionitem1.getAttribute2();
            boolean flag3 = false;
            for(int i2 = 0; i2 < k; i2++)
            {
                java.lang.String s5 = (java.lang.String)m_ShowHideParamNames.get(i2);
                if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s5) || !s5.equals(s3))
                    continue;
                flag3 = true;
                if(!oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeParameter(akregionitem1.getParamName(), m_AKRegion) && !m_EmailMode)
                    addShowHideParameter(s3);
                break;
            }

            if(!flag3)
                if(m_FilterLevels == null && !akregionitem1.isHideDimension() || m_FilterLevels != null && m_FilterLevels.contains(akregionitem1.getAttribute2()))
                {
                    overrideItemAttributes(akregionitem1);
                    java.lang.String s6 = akregionitem1.getParamName();
                    java.lang.String s8 = akregionitem1.getDimension();
                    akregionitem1.getAttributeNameLong();
                    int j2 = 0;
                    arraylist.remove(s6);
                    try
                    {
                        j2 = java.lang.Integer.parseInt(akregionitem1.getDisplaySequence());
                    }
                    catch(java.lang.Exception _ex)
                    {
                        j2 = 0;
                    }
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
                        if(!s.equals(s8))
                            addDimensionParam();
                        else
                        if(akregionitem1.isDuplicate() || j2 > 10000 && j2 - i > 1)
                            addDimensionParam();
                    if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s8))
                    {
                        m_CurrentSelectedItem = akregionitem1;
                        addNonDimensionParam();
                    } else
                    {
                        m_CurrentParams.add(akregionitem1);
                        if(oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeParameter(s6, m_AKRegion))
                        {
                            if(m_ParamInfo.get(s6 + "_FROM") != null || m_ParamInfo.get(s6 + "_TO") != null)
                                m_CurrentSelectedItem = akregionitem1;
                        } else
                        if(m_ParamInfo.get(s6) != null)
                            m_CurrentSelectedItem = akregionitem1;
                        if(m_CurrentSelectedItem == null)
                            m_CurrentSelectedItem = akregionitem1;
                    }
                    if(i1 == j - 1 && !oracle.apps.bis.pmv.common.StringUtil.emptyString(s8))
                    {
                        flag = true;
                        addDimensionParam();
                    } else
                    if(i1 == j - 1)
                        flag = true;
                    s = s8;
                    i = j2;
                } else
                if(akregionitem1.isHideDimension())
                {
                    java.lang.String s7 = akregionitem1.getDimension();
                    if(!akregionitem1.isHideViewBy() && !oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeComparisonDimension(s7) && !oracle.apps.bis.pmv.parameters.ParameterUtil.isDateTimeParameter(akregionitem1.getParamName(), m_AKRegion) && m_ShowViewBy && akregionitem1.isDefaultRegionItem())
                    {
                        m_ViewByParam.addViewBy(akregionitem1.getParamName(), akregionitem1.getAttributeNameLong());
                        addExtraViewByInfo(akregionitem1);
                    }
                }
        }

        if(!flag && j > 0)
            addDimensionParam();
        if(m_ShowBP)
        {
            arraylist.remove("BUSINESS_PLAN");
            addBusinessPlanParam();
        }
        if(m_ShowViewBy)
        {
            arraylist.remove("VIEW_BY");
            addViewByParam();
        }
        for(int k1 = 0; k1 < arraylist.size(); k1++)
        {
            oracle.apps.bis.pmv.parameters.Parameters parameters1 = (oracle.apps.bis.pmv.parameters.Parameters)m_ParamInfo.get(arraylist.get(k1));
            addHiddenParameter(parameters1.getParameterName(), parameters1.getParameterValue(), parameters1.getParameterDescription());
        }

    }

    private void overrideItemAttributes(oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem)
    {
        if("TIME_COMPARISON_TYPE+SEQUENTIAL".equals(akregionitem.getAttribute2()))
        {
            akregionitem.setAttributeNameLong(oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_SEQUENTIAL", m_UserSession.getWebAppsContext()));
            return;
        }
        if("TIME_COMPARISON_TYPE+YEARLY".equals(akregionitem.getAttribute2()))
            akregionitem.setAttributeNameLong(oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_COMPARISON_YEAR", m_UserSession.getWebAppsContext()));
    }

    private void addParameterObject(oracle.apps.bis.pmv.parameters.ParameterObject parameterobject)
    {
        setParameterObjectProperties(parameterobject);
        addParamObjectToArray(parameterobject);
    }

    private void addParamObjectToArray(oracle.apps.bis.pmv.parameters.ParameterObject parameterobject)
    {
        m_ParameterObjects.add(parameterobject);
        if(!m_CurrentSelectedItem.isHideParameter())
            m_VisibleCount++;
        m_CurrentSelectedItem = null;
    }

    private void setParameterObjectProperties(oracle.apps.bis.pmv.parameters.ParameterObject parameterobject)
    {
        parameterobject.setCount(++m_CurrentParamCount);
        parameterobject.setUserSession(m_UserSession);
        java.lang.String s = m_CurrentSelectedItem.getAttributeCode();
        if(m_EditParameter)
            parameterobject.setEditParameter(m_EditParameter);
        if(oracle.apps.bis.pmv.parameters.ParameterUtil.hasDependencies(m_ParamItems, s))
            parameterobject.setHasDependency(true);
        if(m_UserSession.isPersonalizeMode() || m_UserSession.isPersonalizePortletMode())
            parameterobject.setPersonalizeMode(true);
        if(m_UserSession.isScheduleMode())
            parameterobject.setScheduleMode(true);
        if(m_PortletMode)
            parameterobject.setPortletMode(true);
        if(m_UserSession.isPrintableMode() || m_UserSession.isEmailContent() || m_UserSession.isFromConc())
            parameterobject.setPrintableMode(true);
        if(m_UserSession.getDisplayOnlyParameters() != null && !m_EditParameter && m_UserSession.getDisplayOnlyParameters().indexOf(m_CurrentSelectedItem.getParamName()) > -1)
            parameterobject.setDisplayOnly(true);
        if(m_UserSession.getDisplayOnlyNoViewByParams() != null && !m_EditParameter && m_UserSession.getDisplayOnlyNoViewByParams().indexOf(m_CurrentSelectedItem.getParamName()) > -1)
            parameterobject.setDisplayOnly(true);
        if(m_UserSession.isPersonalizePortletPrintableMode() && !m_EditParameter && (m_UserSession.isKpiMode() || m_CurrentSelectedItem.isNestedRegionItem()))
            parameterobject.setDisplayOnly(true);
        if(m_UserSession.isGoReport() && (m_UserSession.getRequestInfo() == null || !"BSC".equals(m_UserSession.getRequestInfo().getMode())))
            parameterobject.setPPRMode(true);
        if(m_CurrentParams != null)
        {
            for(int i = 0; i < m_CurrentParams.size(); i++)
            {
                oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)m_CurrentParams.get(i);
                boolean flag = akregionitem.isHideParameter();
                if(!flag)
                    continue;
                parameterobject.setHidden(true);
                break;
            }

        }
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(m_CurrentSelectedItem.getOperator()))
        {
            parameterobject.setHasOperator(true);
            oracle.apps.bis.pmv.common.LookUpHelper lookuphelper = new LookUpHelper(m_UserSession.getConnection(), m_CurrentSelectedItem.getOperator());
            parameterobject.setOperatorLookUps(lookuphelper.getLookUpValues());
        }
        parameterobject.setAttributes(m_CurrentSelectedItem, m_ParamInfo);
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(parameterobject.getLabel()) && parameterobject.getLabel().equals(m_CurrentSelectedItem.getAttributeNameLong()))
            parameterobject.setLabel(getDynamicParamLabel(m_CurrentSelectedItem.getAttributeNameLong()));
    }

    private void addNonDimensionParam()
    {
        if("DIMENSION VALUE".equals(m_CurrentSelectedItem.getRegionItemType()) && "TIME".equals(m_CurrentSelectedItem.getAttribute2()))
        {
            addPeriodValueParam();
            return;
        }
        java.lang.Object obj = null;
        boolean flag = false;
        if("AS_OF_DATE".equals(m_CurrentSelectedItem.getParamName()))
        {
            flag = true;
            obj = new AsOfDateParameter(m_UserSession);
            if(!m_DateParamAdded)
            {
                ((oracle.apps.bis.pmv.parameters.AsOfDateParameter)obj).setFirstDateParam(true);
                m_DateParamAdded = true;
            }
            if(m_SavedTimeParamName != null && !m_SavedTimeParamName.startsWith("EDW_TIME_M+") && !m_SavedTimeParamName.startsWith("TIME+"))
                ((oracle.apps.bis.pmv.parameters.AsOfDateParameter)obj).setTimeParamName(m_SavedTimeParamName);
        } else
        if("DATE PARAMETER".equals(m_CurrentSelectedItem.getRegionItemType()))
        {
            obj = new DateParameter(m_UserSession);
            if(!m_DateParamAdded)
            {
                ((oracle.apps.bis.pmv.parameters.DateParameter)obj).setFirstDateParam(true);
                m_DateParamAdded = true;
            }
        } else
        {
            obj = new ParameterObject();
        }
        addParameterObject(((oracle.apps.bis.pmv.parameters.ParameterObject) (obj)));
        if(flag && obj != null && ((oracle.apps.bis.pmv.parameters.ParameterObject) (obj)).isHidden())
            m_AsOfDateHidden = true;
    }

    private void addPeriodValueParam()
    {
        java.lang.String s = m_CurrentSelectedItem.getAttributeNameLong();
        java.lang.Object obj = null;
        boolean flag = false;
        if("TIME+FII_TIME_DAY".equals(m_CurrentSelectedTimeParamName))
        {
            flag = true;
            obj = new DateParameter(m_UserSession);
            if(!m_DateParamAdded)
            {
                ((oracle.apps.bis.pmv.parameters.DateParameter)obj).setFirstDateParam(true);
                m_DateParamAdded = true;
            }
        } else
        {
            obj = new DimensionParameter();
            ((oracle.apps.bis.pmv.parameters.DimensionParameter)obj).setExceptionForNeedAll(true);
            m_CurrentSelectedItem.setParamName(m_CurrentSelectedTimeParamName);
            com.sun.java.util.collections.ArrayList arraylist = oracle.apps.bis.pmv.parameters.ParameterUtil.getLookUpValues(m_UserSession, m_CurrentSelectedItem);
            ((oracle.apps.bis.pmv.parameters.MultiValueParameter) (obj)).setLookUpValues(arraylist);
        }
        java.lang.String s1 = "";
        if(m_PeriodFromValueAdded)
        {
            s1 = m_CurrentSelectedTimeParamName + "_TO";
        } else
        {
            m_PeriodFromValueAdded = true;
            s1 = m_CurrentSelectedTimeParamName + "_FROM";
            if(!flag && m_AKRegion.getDimValueToItem() != null)
                ((oracle.apps.bis.pmv.parameters.ParameterObject) (obj)).setHasDependency(true);
        }
        m_CurrentSelectedItem = m_CurrentSelectedTimeItem;
        m_CurrentSelectedItem.setParamName(s1);
        setParameterObjectProperties(((oracle.apps.bis.pmv.parameters.ParameterObject) (obj)));
        m_CurrentSelectedItem.setParamName(m_CurrentSelectedTimeParamName);
        addParamObjectToArray(((oracle.apps.bis.pmv.parameters.ParameterObject) (obj)));
        ((oracle.apps.bis.pmv.parameters.ParameterObject) (obj)).setLabel(s);
    }

    private void addDimensionParam()
    {
        if(m_CurrentSelectedItem == null)
            return;
        java.lang.String s = m_CurrentSelectedItem.getDimension();
        java.lang.String s1 = m_CurrentSelectedItem.getParamName();
        boolean flag = oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeParameter(s1, m_AKRegion);
        if(m_ShowViewBy)
            if(!m_CurrentSelectedItem.isHideViewBy() && !oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeComparisonDimension(s) && flag && (m_CurrentSelectedItem.isNestedRegionItem() || m_AKRegion.hasAsOfDate()) && (m_UserSession.getDisplayOnlyNoViewByParams() == null || m_UserSession.getDisplayOnlyNoViewByParams().indexOf(m_CurrentSelectedItem.getParamName()) <= -1))
            {
                if("VIEWBY PARAMETER".equals(m_CurrentSelectedItem.getRegionItemType()))
                    m_ViewByParam.addViewBy(m_CurrentSelectedItem.getParamName(), m_CurrentSelectedItem.getAttributeNameLong());
                else
                    m_ViewByParam.addViewByNestedTime("NESTEDTIMEVIEWBY", oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_TIME", m_UserSession.getWebAppsContext()), m_AKRegion.getBscTimeLevels());
                addExtraViewByInfo(m_CurrentSelectedItem);
            } else
            {
                for(int i = 0; i < m_CurrentParams.size(); i++)
                {
                    oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)m_CurrentParams.get(i);
                    s = akregionitem.getDimension();
                    if(!akregionitem.isHideViewBy() && !oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeComparisonDimension(s) && (m_UserSession.getDisplayOnlyNoViewByParams() == null || m_UserSession.getDisplayOnlyNoViewByParams().indexOf(akregionitem.getParamName()) <= -1))
                    {
                        boolean flag2 = true;
                        if(m_AKRegion.isBscSQL())
                            try
                            {
                                int j = java.lang.Integer.parseInt(m_CurrentSelectedItem.getDisplaySequence());
                                int k = java.lang.Integer.parseInt(akregionitem.getDisplaySequence());
                                if(k < j)
                                    flag2 = false;
                            }
                            catch(java.lang.Exception _ex) { }
                        if(flag2)
                        {
                            m_ViewByParam.addViewBy(akregionitem.getParamName(), akregionitem.getAttributeNameLong());
                            addExtraViewByInfo(akregionitem);
                        }
                    }
                }

            }
        boolean flag1 = m_CurrentSelectedItem.isDisplayOnlyParameter() || "Y".equals(m_UserSession.getRequestInfo().getParameterDisplayOnly());
        if(!"VIEWBY PARAMETER".equals(m_CurrentSelectedItem.getRegionItemType()) && !flag1)
        {
            Object obj = null;
            if(m_CurrentParams.size() == 1 && !oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeComparisonDimension(s) && !oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeParameter(s1, m_AKRegion))
            {
                oracle.apps.bis.pmv.parameters.DimensionParameter dimensionparameter = new DimensionParameter();
                if(m_PortletMode && !m_CurrentSelectedItem.isLongList() && !"L".equals(m_CurrentSelectedItem.getParameterRenderType()) || m_CurrentSelectedItem.showLovValues() || !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_CurrentSelectedItem.getRollingDimension()))
                    setLookUpValuesAndRTCCache(dimensionparameter);
                if(m_CurrentSelectedItem.getDimLevelProperties() != null && !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_CurrentSelectedItem.getDimLevelProperties().getDrillToFormFunction()))
                    setDrillTo(dimensionparameter);
                addParameterObject(dimensionparameter);
            } else
            if(m_AKRegion.isEDW())
                addHierarchyParam();
            else
                addMultiLevelParam();
        } else
        if(flag1)
            if(flag || oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeComparisonDimension(s))
            {
                addMultiLevelParam();
            } else
            {
                oracle.apps.bis.pmv.parameters.DimensionParameter dimensionparameter1 = new DimensionParameter();
                oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)m_ParamInfo.get(s1);
                boolean flag3 = false;
                if(parameters != null)
                    flag3 = !oracle.apps.bis.pmv.common.StringUtil.emptyString(parameters.getParameterValue());
                if(m_CurrentSelectedItem.getDimLevelProperties() != null && !m_CurrentSelectedItem.getDimLevelProperties().isAll() && !flag3)
                    setLookUpValuesAndRTCCache(dimensionparameter1);
                addParameterObject(dimensionparameter1);
            }
        m_CurrentParams = new ArrayList(5);
        m_CurrentSelectedItem = null;
    }

    private void addHierarchyParam()
    {
        com.sun.java.util.collections.HashMap hashmap = new HashMap(m_CurrentParams.size());
        for(int i = 0; i < m_CurrentParams.size(); i++)
            hashmap.put(((oracle.apps.bis.pmv.metadata.AKRegionItem)m_CurrentParams.get(i)).getParamName(), ((oracle.apps.bis.pmv.metadata.AKRegionItem)m_CurrentParams.get(i)).getAttributeNameLong());

        java.lang.String s = "";
        if(m_HierarchyValues != null && !m_HierarchyValues.isEmpty())
            s = (java.lang.String)m_HierarchyValues.get(m_CurrentSelectedItem.getDimension() + "_HIERARCHY");
        java.lang.String s1 = "";
        oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)m_ParamInfo.get("VIEW_BY");
        if(parameters != null)
            s1 = parameters.getParameterValue();
        oracle.apps.bis.pmv.parameters.HierarchyHelper hierarchyhelper = null;
        if(hashmap.size() > 1)
            hierarchyhelper = new HierarchyHelper(m_UserSession, m_CurrentSelectedItem.getDimension(), hashmap, s, s1, m_CurrentSelectedItem.getOverRideHierarchy(), "Parameter Association");
        if(hierarchyhelper != null && hierarchyhelper.getNumHierarchies() > 1)
        {
            oracle.apps.bis.pmv.parameters.HierarchyParameter hierarchyparameter = new HierarchyParameter();
            hierarchyparameter.setCurrentHierarchyId(s);
            hierarchyparameter.setHierarchyInfo(hierarchyhelper.getHierarchies());
            com.sun.java.util.collections.List list = hierarchyparameter.getDimLevels();
            if(list != null && !list.isEmpty() && !list.contains(m_CurrentSelectedItem.getAttribute2()))
            {
                java.lang.String s2 = (java.lang.String)list.get(0);
                m_CurrentSelectedItem = m_AKRegion.getAKRegionItem(s2);
            }
            if(m_CurrentSelectedItem.showLovValues())
            {
                com.sun.java.util.collections.ArrayList arraylist = oracle.apps.bis.pmv.parameters.ParameterUtil.getLookUpValues(m_UserSession, m_CurrentSelectedItem);
                hierarchyparameter.setLookUpValues(arraylist);
            }
            if(m_CurrentSelectedItem.getDimLevelProperties() != null && !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_CurrentSelectedItem.getDimLevelProperties().getDrillToFormFunction()))
                setDrillTo(hierarchyparameter);
            addParameterObject(hierarchyparameter);
            return;
        } else
        {
            addMultiLevelParam();
            return;
        }
    }

    private void addMultiLevelParam()
    {
        java.lang.Object obj = null;
        java.lang.String s = m_CurrentSelectedItem.getDimension();
        java.lang.String s1 = m_CurrentSelectedItem.getParamName();
        if(oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeComparisonDimension(s))
            obj = new TimeComparisonTypeParameter();
        else
        if(oracle.apps.bis.pmv.parameters.ParameterUtil.isTimeParameter(s1, m_AKRegion))
        {
            m_CurrentSelectedTimeItem = m_CurrentSelectedItem;
            m_CurrentSelectedTimeParamName = m_CurrentSelectedTimeItem.getParamName();
            obj = new TimeDimensionParameter();
            if(m_AKRegion.getDimValueItem() != null)
                ((oracle.apps.bis.pmv.parameters.ParameterObject) (obj)).setHasDependency(true);
            if((!m_AKRegion.isEDW() || "P".equals(m_UserSession.getRequestInfo().getRequestType())) && (m_AKRegion.hasAsOfDate() || m_CurrentSelectedItem.isNestedRegionItem() || m_AKRegion.isDimValuePresent()))
                ((oracle.apps.bis.pmv.parameters.MultiLevelParameter) (obj)).setDisplayLevelsOnly(true);
        } else
        {
            obj = new MultiLevelParameter();
            if(m_CurrentSelectedItem.getDimLevelProperties() != null && !oracle.apps.bis.pmv.common.StringUtil.emptyString(m_CurrentSelectedItem.getDimLevelProperties().getDrillToFormFunction()))
                setDrillTo(((oracle.apps.bis.pmv.parameters.ParameterObject) (obj)));
        }
        if(!((oracle.apps.bis.pmv.parameters.MultiLevelParameter) (obj)).isDisplayLevelsOnly() && m_CurrentSelectedItem.showLovValues())
        {
            com.sun.java.util.collections.ArrayList arraylist = oracle.apps.bis.pmv.parameters.ParameterUtil.getLookUpValues(m_UserSession, m_CurrentSelectedItem);
            ((oracle.apps.bis.pmv.parameters.MultiValueParameter) (obj)).setLookUpValues(arraylist);
        }
        com.sun.java.util.collections.ArrayList arraylist1 = new ArrayList(5);
        com.sun.java.util.collections.ArrayList arraylist2 = new ArrayList(5);
        for(int i = 0; i < m_CurrentParams.size(); i++)
        {
            oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)m_CurrentParams.get(i);
            arraylist1.add(akregionitem.getParamName());
            arraylist2.add(getDynamicParamLabel(akregionitem.getAttributeNameLong()));
        }

        ((oracle.apps.bis.pmv.parameters.MultiLevelParameter) (obj)).setDimLevelsInfo(arraylist1, arraylist2);
        addParameterObject(((oracle.apps.bis.pmv.parameters.ParameterObject) (obj)));
    }

    private void addBusinessPlanParam()
    {
        oracle.apps.bis.pmv.parameters.BusinessPlanParameter businessplanparameter = new BusinessPlanParameter(m_Conn);
        m_CurrentSelectedItem = new AKRegionItem();
        m_CurrentSelectedItem.setAttributeCode("BUSINESS_PLAN");
        m_CurrentSelectedItem.setParamName("BUSINESS_PLAN");
        m_CurrentSelectedItem.setAttributeNameLong(oracle.apps.bis.pmv.common.PMVUtil.getMessage("BUSINESS_PLAN", m_UserSession.getWebAppsContext()));
        addParameterObject(businessplanparameter);
    }

    private void addViewByParam()
    {
        m_CurrentSelectedItem = new AKRegionItem();
        m_CurrentSelectedItem.setAttributeCode("VIEW_BY");
        m_CurrentSelectedItem.setParamName("VIEW_BY");
        m_CurrentSelectedItem.setAttributeNameLong(oracle.apps.bis.pmv.common.PMVUtil.getMessage("VIEW_BY", m_UserSession.getWebAppsContext()));
        addParameterObject(m_ViewByParam);
        if(m_HasExtraViewBy)
        {
            m_ViewByParam.setId(m_ViewByParam.getId() + "-" + m_ParamHelper.getExtraViewByValue());
            m_ViewByParam.setValue(m_ViewByParam.getValue() + " -" + m_ParamHelper.getExtraViewByDesc());
        }
    }

    private void addExtraViewByInfo(oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem)
    {
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(11);
        try
        {
            java.lang.String s = akregionitem.getExtraViewBy().trim();
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
                if(s.indexOf(",") > 0)
                {
                    for(java.util.StringTokenizer stringtokenizer = new StringTokenizer(s, ","); stringtokenizer.hasMoreElements(); loadExtraViewbyData(((java.lang.String)stringtokenizer.nextElement()).trim(), arraylist));
                } else
                {
                    loadExtraViewbyData(s.trim(), arraylist);
                }
        }
        catch(java.lang.Exception _ex) { }
        for(int i = 0; i < arraylist.size() - 1; i += 2)
        {
            java.lang.String s1 = akregionitem.getParamName() + "-" + arraylist.get(i);
            java.lang.String s2 = akregionitem.getAttributeNameLong() + " -" + arraylist.get(i + 1);
            m_ViewByParam.addViewBy(s1, s2);
        }

    }

    private void loadExtraViewbyData(java.lang.String s, com.sun.java.util.collections.ArrayList arraylist)
    {
        java.lang.String s1 = null;
        Object obj = null;
        oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = null;
        s1 = oracle.apps.bis.pmv.common.PMVUtil.getAttr2FromAttrCode(m_AKRegion, s);
        for(int i = 0; i < m_ParamItems.size(); i++)
        {
            java.lang.String s3 = ((oracle.apps.bis.pmv.metadata.AKRegionItem)m_ParamItems.get(i)).getAttribute2();
            if(!s1.equals(s3) || m_ShowHideParamNames == null || m_ShowHideParamNames.contains(s3))
                continue;
            akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)m_ParamItems.get(i);
            break;
        }

        if(akregionitem != null)
        {
            java.lang.String s2 = akregionitem.getAttributeNameLong();
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
            {
                arraylist.add(s1);
                arraylist.add(s2);
            }
        }
    }

    public int getVisibleCount()
    {
        return m_VisibleCount;
    }

    private java.lang.String createBaseDrillLink()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer();
        try
        {
            java.lang.String s = null;
            java.lang.String s1 = null;
            if(m_UserSession.getPageContext() != null)
            {
                s = oracle.apps.bis.common.ServletWrapper.getParameter(m_UserSession.getPageContext(), "dbc");
                if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
                    s = (java.lang.String)oracle.apps.bis.common.ServletWrapper.getAttribute(m_UserSession.getPageContext(), "dbc");
                s1 = oracle.apps.bis.common.ServletWrapper.getParameter(m_UserSession.getPageContext(), "transactionid");
            }
            java.lang.String s2 = m_UserSession.getWebAppsContext().getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
            stringbuffer.append("/OA_HTML_HTML/").append("OA.jsp?page=/od/oracle/apps/xxcrm/bis/pmv/drill/webui/DrillPG&retainAM=Y&addBreadCrumb=Y&pMode=1&");
            stringbuffer.append("pSessionId=").append(m_UserSession.getWebAppsContext().getSessionId());
            stringbuffer.append("&").append("dbc").append("=").append(s);
            stringbuffer.append("&").append("transactionid").append("=").append(s1);
            stringbuffer.append("&pUserId=").append(m_UserSession.getWebAppsContext().getUserId());
            stringbuffer.append("&pRespId=").append(m_UserSession.getWebAppsContext().getRespId());
            stringbuffer.append("&pPreFunction=").append(oracle.cabo.share.url.EncoderUtils.encodeString(oracle.apps.bis.pmv.common.StringUtil.nonNull(m_UserSession.getFunctionName()), s2));
            stringbuffer.append("&pBCFromFunction=").append(oracle.cabo.share.url.EncoderUtils.encodeString(oracle.apps.bis.pmv.common.StringUtil.nonNull(m_UserSession.getFunctionName()), s2));
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        return stringbuffer.toString();
    }

    private void setDrillTo(oracle.apps.bis.pmv.parameters.ParameterObject parameterobject)
    {
        try
        {
            java.lang.String s = m_UserSession.getWebAppsContext().getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
            java.lang.String s1 = m_CurrentSelectedItem.getDimLevelProperties().getDrillToFormFunction();
            s1 = oracle.cabo.share.url.EncoderUtils.encodeString("pFunctionName=" + s1, s);
            parameterobject.setDrillToFormFunction(m_BaseDrillLink + "&pUrlString=" + s1, s);
            parameterobject.setPropsLabel(oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_DRILL_TO_PROPERTIES_LABEL", m_UserSession.getWebAppsContext()));
            return;
        }
        catch(java.io.UnsupportedEncodingException _ex)
        {
            return;
        }
    }

    private void setLookUpValuesAndRTCCache(oracle.apps.bis.pmv.parameters.DimensionParameter dimensionparameter)
    {
        oracle.apps.bis.pmv.common.LookUpHelper lookuphelper = oracle.apps.bis.pmv.parameters.ParameterUtil.getLookUpHelper(m_UserSession, m_CurrentSelectedItem);
        com.sun.java.util.collections.ArrayList arraylist = oracle.apps.bis.pmv.parameters.ParameterUtil.getLookUpValues(lookuphelper, m_UserSession, m_CurrentSelectedItem);
        dimensionparameter.setLookUpValues(arraylist);
        dimensionparameter.setDelegationLookUpValues(lookuphelper.getDelegationLookUpValues());
        dimensionparameter.setChatLabel(oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_INITIATE_CHAT_LABEL", m_UserSession.getWebAppsContext()));
        if(oracle.apps.bis.pmv.common.RTCUtil.isManagerDimension(m_CurrentSelectedItem.getParamName()) && !oracle.apps.bis.pmv.common.RTCUtil.cached() && oracle.apps.bis.pmv.common.RTCUtil.isRTCEnabled())
            oracle.apps.bis.pmv.parameters.ParameterUtil.setRTCEmailCache(m_UserSession, lookuphelper.getLookUpValues());
    }

    private void addShowHideParameter(java.lang.String s)
    {
        addHiddenParameter(s, s, s);
    }

    private void addHiddenParameter(java.lang.String s, java.lang.String s1, java.lang.String s2)
    {
        oracle.apps.bis.pmv.parameters.ParameterObject parameterobject = new ParameterObject();
        parameterobject.setCount(++m_CurrentParamCount);
        parameterobject.setName(s);
        parameterobject.setId(s1);
        parameterobject.setValue(s2);
        parameterobject.setHidden(true);
        parameterobject.setUserSession(m_UserSession);
        m_ParameterObjects.add(parameterobject);
    }

    private java.lang.String getDynamicParamLabel(java.lang.String s)
    {
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && oracle.apps.bis.pmv.common.PMVUtil.isDynamicLabel(s))
        {
            java.lang.String s1 = oracle.apps.bis.pmv.query.Calculation.getDynamicLabel(m_ParamHelper, s, m_UserSession, m_UserSession.getConnection());
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                return s1;
        }
        return s;
    }

    protected com.sun.java.util.collections.Map getParamInfo()
    {
        return m_ParamInfo;
    }

    protected boolean isAsOfDateHidden()
    {
        return m_AsOfDateHidden;
    }

    public static final java.lang.String RCS_ID = "$Header: ODParameterOrganizer.java 115.104 2007/01/30 09:19:28 ashgarg noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODParameterOrganizer.java 115.104 2007/01/30 09:19:28 ashgarg noship $", "oracle.apps.bis.pmv.parameters");
    private oracle.apps.bis.pmv.session.UserSession m_UserSession;
    private oracle.apps.bis.pmv.parameters.ParameterHelper m_ParamHelper;
    private com.sun.java.util.collections.List m_ParamItems;
    private com.sun.java.util.collections.Map m_ParamInfo;
    private com.sun.java.util.collections.Map m_HierarchyValues;
    private java.sql.Connection m_Conn;
    private boolean m_ShowBP;
    private boolean m_ShowViewBy;
    private boolean m_HasExtraViewBy;
    private com.sun.java.util.collections.List m_FilterLevels;
    private com.sun.java.util.collections.ArrayList m_ParameterObjects;
    private oracle.apps.bis.pmv.parameters.ViewByParameter m_ViewByParam;
    private int m_CurrentParamCount;
    private oracle.apps.bis.pmv.metadata.AKRegion m_AKRegion;
    private oracle.apps.bis.pmv.metadata.AKRegionItem m_CurrentSelectedItem;
    private oracle.apps.bis.pmv.metadata.AKRegionItem m_CurrentSelectedTimeItem;
    private java.lang.String m_CurrentSelectedTimeParamName;
    private com.sun.java.util.collections.ArrayList m_CurrentParams;
    private boolean m_PeriodFromValueAdded;
    private boolean m_PortletMode;
    private boolean m_EmailMode;
    private boolean m_DispRun;
    private boolean m_DBI;
    private int m_VisibleCount;
    private java.lang.String m_BaseDrillLink;
    private boolean m_DateParamAdded;
    private com.sun.java.util.collections.ArrayList m_ShowHideParamNames;
    private boolean m_EditParameter;
    private java.lang.String m_FrameworkAgent;
    private boolean m_AsOfDateHidden;
    private java.lang.String m_SavedTimeParamName;

}
