// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames 
// Source File Name:   ODParameterGroups.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.ArrayList;
import oracle.apps.bis.pmv.common.PMVConstants;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.parameters.Parameters;
import oracle.apps.fnd.common.VersionInfo;

public class ODParameterGroups
{

    public ODParameterGroups(oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        m_TCTExists = false;
        m_AsOfDateExists = false;
        init(akregion);
    }

    protected void init(oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        m_ParamGroups = new ArrayList(11);
        java.lang.String s = null;
        Object obj = null;
        int j = -999;
        Object obj1 = null;
        int k = 1;
        com.sun.java.util.collections.ArrayList arraylist = getParameterListFromSortedList(akregion.getSortedItems());
        if(arraylist != null)
        {
            com.sun.java.util.collections.ArrayList arraylist1 = new ArrayList(5);
            for(int l = 0; l < arraylist.size(); l++)
            {
                oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist.get(l);
                java.lang.String s1 = akregionitem.getDimension();
                int i = java.lang.Integer.parseInt(akregionitem.getDisplaySequence());
                if("TIME_COMPARISON_TYPE".equals(s1))
                    m_TCTExists = true;
                if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                {
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
                    {
                        addToGroups(s, arraylist1, k);
                        k++;
                    }
                    arraylist1.clear();
                    arraylist1.add(akregionitem.getAttributeCode());
                    addToGroups(akregionitem.getAttributeCode(), arraylist1, k);
                    k++;
                    if("AS_OF_DATE".equals(akregionitem.getAttributeCode()))
                        m_AsOfDateExists = true;
                    arraylist1.clear();
                    s = s1;
                    j = i;
                } else
                if(i < 10000)
                {
                    j = i;
                    if(!s1.equals(s) || akregionitem.isDuplicate())
                    {
                        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
                        {
                            addToGroups(s, arraylist1, k);
                            k++;
                        }
                        arraylist1.clear();
                        if(akregionitem.isDuplicate())
                            arraylist1.add(akregionitem.getParamName());
                        else
                            arraylist1.add(akregionitem.getAttribute2());
                        s = s1;
                    } else
                    {
                        if(akregionitem.isDuplicate())
                            arraylist1.add(akregionitem.getParamName());
                        else
                            arraylist1.add(akregionitem.getAttribute2());
                        s = s1;
                    }
                } else
                if(j < 10000 || i - j > 1 || !s1.equals(s) || j == -999)
                {
                    addToGroups(s, arraylist1, k);
                    k++;
                    arraylist1.clear();
                    if(akregionitem.isDuplicate())
                        arraylist1.add(akregionitem.getParamName());
                    else
                        arraylist1.add(akregionitem.getAttribute2());
                    s = s1;
                    j = i;
                } else
                if(i - j == 1 && s1.equals(s))
                {
                    arraylist1.add(akregionitem.getAttribute2());
                    s = s1;
                    j = i;
                }
                if(l == arraylist.size() - 1)
                    addToGroups(s, arraylist1, k);
            }

            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(akregion.getPageParameterRegionName()) && !m_AsOfDateExists)
            {
                arraylist1.clear();
                arraylist1.add("AS_OF_DATE");
                k++;
                addToGroups("AS_OF_DATE", arraylist1, k);
                m_AsOfDateExists = true;
            }
        }
    }

    private void addToGroups(java.lang.String s, com.sun.java.util.collections.ArrayList arraylist, int i)
    {
        Object obj = null;
        if(m_ParamGroups != null)
        {
            if(arraylist != null && arraylist.size() > 0)
            {
                for(int j = 0; j < arraylist.size(); j++)
                {
                    oracle.apps.bis.pmv.parameters.Parameters parameters = new Parameters();
                    parameters.setDimension(s);
                    parameters.setParameterName((java.lang.String)arraylist.get(j));
                    parameters.setParamNumber(i);
                    m_ParamGroups.add(parameters);
                }

                return;
            }
            oracle.apps.bis.pmv.parameters.Parameters parameters1 = new Parameters();
            parameters1.setParameterName(s);
            parameters1.setParamNumber(i);
            m_ParamGroups.add(parameters1);
        }
    }

    private com.sun.java.util.collections.ArrayList getParameterListFromSortedList(com.sun.java.util.collections.ArrayList arraylist)
    {
        com.sun.java.util.collections.ArrayList arraylist1 = null;
        if(arraylist != null)
        {
            arraylist1 = new ArrayList(11);
            Object obj = null;
            for(int i = 0; i < arraylist.size(); i++)
            {
                oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist.get(i);
                java.lang.String s = akregionitem.getRegionItemType();
                if(akregionitem != null && "Y".equals(akregionitem.getNodeQueryFlag()) && !"VIEWBY PARAMETER".equals(s) && !"HIDE DIMENSION LEVEL".equals(s))
                    arraylist1.add(akregionitem);
            }

        }
        return arraylist1;
    }

    public com.sun.java.util.collections.ArrayList getParameterGroups()
    {
        return m_ParamGroups;
    }

    public boolean isTCTExists()
    {
        return m_TCTExists;
    }

    public boolean isAsOfDateExists()
    {
        return m_AsOfDateExists;
    }

    public static final java.lang.String RCS_ID = "$Header: ODParameterGroups.java 115.3 2005/08/04 13:57:18 serao noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODParameterGroups.java 115.3 2005/08/04 13:57:18 serao noship $", "od.oracle.apps.xxcrm.bis.pmv.drill");
    private com.sun.java.util.collections.ArrayList m_ParamGroups;
    private boolean m_TCTExists;
    private boolean m_AsOfDateExists;

}
