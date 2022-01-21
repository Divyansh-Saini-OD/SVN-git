// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames 
// Source File Name:   ODDrillHelper.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.ArrayList;
import oracle.apps.bis.pmv.common.PMVConstants;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.parameters.Parameters;
import oracle.apps.fnd.common.VersionInfo;

// Referenced classes of package od.oracle.apps.xxcrm.bis.pmv.drill:
//            DrillUtil

public class ODDrillHelper
{

    public ODDrillHelper()
    {
    }

    public static com.sun.java.util.collections.ArrayList getAttrNamesInSameGroup(java.lang.String s, java.lang.String s1, com.sun.java.util.collections.ArrayList arraylist, oracle.apps.bis.pmv.metadata.AKRegion akregion)
    {
        java.lang.String s2 = s;
        com.sun.java.util.collections.ArrayList arraylist1 = new ArrayList(3);
        if(arraylist != null)
        {
            for(int i = 0; i < arraylist.size(); i++)
            {
                oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)arraylist.get(i);
                if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                {
                    if(od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.isTimeLevelStarts(s, akregion))
                    {
                        if(s2.endsWith("_FROM") && s2.indexOf('+') > 0)
                            s2 = s2.substring(0, s2.length() - 5);
                        if(s2.endsWith("_TO") && s2.indexOf('+') > 0)
                            s2 = s2.substring(0, s2.length() - 3);
                    }
                    if(!s1.equals(parameters.getDimension()) || !parameters.getParameterName().equals(s2) && (s2.indexOf('+') <= 0 || !parameters.getParameterName().equals(s2.substring(0, s2.lastIndexOf('+')))) && (!"TIME".equals(s1) || !od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillHelper.isTimeMappingRequired(parameters.getParameterName(), s2)))
                        continue;
                    od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillHelper.getPrevParams(parameters.getParamNumber(), i, arraylist, arraylist1);
                    od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillHelper.getLaterParams(parameters.getParamNumber(), i + 1, arraylist, arraylist1);
                    break;
                }
                if(!parameters.getParameterName().equals(s2))
                    continue;
                arraylist1.add(parameters.getParameterName());
                break;
            }

        }
        return arraylist1;
    }

    private static void getPrevParams(int i, int j, com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1)
    {
        if(arraylist != null)
        {
            Object obj = null;
            for(int k = j; k >= 0; k--)
            {
                oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)arraylist.get(k);
                if(parameters.getParamNumber() != i)
                    break;
                arraylist1.add(parameters.getParameterName());
            }

        }
    }

    private static void getLaterParams(int i, int j, com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1)
    {
        if(arraylist != null)
        {
            Object obj = null;
            for(int k = j; k < arraylist.size(); k++)
            {
                oracle.apps.bis.pmv.parameters.Parameters parameters = (oracle.apps.bis.pmv.parameters.Parameters)arraylist.get(k);
                if(parameters.getParamNumber() != i)
                    break;
                arraylist1.add(parameters.getParameterName());
            }

        }
    }

    private static boolean isTimeMappingRequired(java.lang.String s, java.lang.String s1)
    {
        boolean flag = false;
        java.lang.String s2 = null;
        if(s1 != null && s != null)
        {
            if((s.indexOf("ENT") > 0 || "TIME+FII_TIME_WEEK".equals(s)) && s1.indexOf("ROLL") > 0 || (s1.indexOf("ENT") > 0 || "TIME+FII_TIME_WEEK".equals(s1)) && s.indexOf("ROLL") > 0)
                if(oracle.apps.bis.pmv.common.StringUtil.in(s1, oracle.apps.bis.pmv.common.PMVConstants.BIS_ENTERPRISE_TIME_LEVELS))
                {
                    for(int i = 0; i < oracle.apps.bis.pmv.common.PMVConstants.BIS_ENTERPRISE_TIME_LEVELS.length; i++)
                    {
                        if(!s1.equals(oracle.apps.bis.pmv.common.PMVConstants.BIS_ENTERPRISE_TIME_LEVELS[i]))
                            continue;
                        s2 = oracle.apps.bis.pmv.common.PMVConstants.BIS_ROLLING_TIME_LEVELS[i];
                        break;
                    }

                } else
                if(oracle.apps.bis.pmv.common.StringUtil.in(s1, oracle.apps.bis.pmv.common.PMVConstants.BIS_ROLLING_TIME_LEVELS))
                {
                    for(int j = 0; j < oracle.apps.bis.pmv.common.PMVConstants.BIS_ROLLING_TIME_LEVELS.length; j++)
                    {
                        if(!s1.equals(oracle.apps.bis.pmv.common.PMVConstants.BIS_ROLLING_TIME_LEVELS[j]))
                            continue;
                        s2 = oracle.apps.bis.pmv.common.PMVConstants.BIS_ENTERPRISE_TIME_LEVELS[j];
                        break;
                    }

                }
            if(s.equals(s2))
                flag = true;
        }
        return flag;
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillHelper.java 115.6 2005/09/28 02:03:13 nkishore noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillHelper.java 115.6 2005/09/28 02:03:13 nkishore noship $", "od.oracle.apps.xxcrm.bis.pmv.drill");

}
