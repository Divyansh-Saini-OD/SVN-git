// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames 
// Source File Name:   ODDrillDownHelper.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.ArrayList;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.Hashtable;
import oracle.apps.bis.pmv.common.PMVConstants;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.metadata.DimLevelProperties;
import oracle.apps.fnd.common.VersionInfo;
import oracle.jdbc.driver.OraclePreparedStatement;
import oracle.jdbc.driver.OracleResultSet;
import oracle.jdbc.driver.OracleStatement;
import oracle.sql.DATE;

// Referenced classes of package od.oracle.apps.xxcrm.bis.pmv.drill:
//            DrillUtil

public class ODDrillDownHelper
{

    public ODDrillDownHelper()
    {
    }

    public void processNextLevelTimeValues(oracle.apps.bis.pmv.metadata.AKRegion akregion, java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.sql.Connection connection)
    {
        java.lang.String s5 = akregion.getRegionObjectType();
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s5))
            s5 = "OLTP";
        java.lang.String s6 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDimensionLevel(s2);
        java.util.Hashtable hashtable = akregion.getAKRegionItems();
        java.lang.String s7 = null;
        java.lang.String s8 = "ID";
        java.lang.String s9 = "VALUE";
        java.lang.String s10 = null;
        java.lang.String s11 = "ID";
        java.lang.String s12 = "VALUE";
        Object obj = null;
        oracle.apps.bis.pmv.metadata.AKRegionItem akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)hashtable.get(s);
        if(akregionitem != null)
        {
            s7 = akregionitem.getViewByTable();
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s7))
            {
                oracle.apps.bis.pmv.metadata.DimLevelProperties dimlevelproperties = akregionitem.getDimLevelProperties();
                s7 = dimlevelproperties.getDataSource();
                s8 = dimlevelproperties.getIdName();
                s9 = dimlevelproperties.getValueName();
            }
        }
        akregionitem = (oracle.apps.bis.pmv.metadata.AKRegionItem)hashtable.get(s2);
        if(akregionitem != null)
        {
            s10 = akregionitem.getViewByTable();
            if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s10))
            {
                oracle.apps.bis.pmv.metadata.DimLevelProperties dimlevelproperties1 = akregionitem.getDimLevelProperties();
                s10 = dimlevelproperties1.getDataSource();
                s11 = dimlevelproperties1.getIdName();
                s12 = dimlevelproperties1.getValueName();
            }
        }
        java.lang.StringBuffer stringbuffer = new StringBuffer(250);
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(3);
        stringbuffer.append("SELECT ").append(s8).append(", ").append(s9).append(" , start_date, end_date FROM ").append(s7).append(" WHERE ").append(s9).append(" = :1 ");
        arraylist.add(s1);
        java.lang.String s13 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getDimensionLevel(s3);
        java.lang.String s14 = null;
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(akregion.getRegionObjectType()) && !s6.startsWith("HR") && (oracle.apps.bis.pmv.common.StringUtil.emptyString(s13) || !s13.startsWith("HR")))
        {
            if("All".equals(s4) || oracle.apps.bis.pmv.common.StringUtil.emptyString(s4))
            {
                s14 = "-1";
                s13 = "TOTAL_ORGANIZATIONS";
            } else
            {
                s14 = s4;
            }
            stringbuffer.append(" AND organization_id = :2 AND organization_type = :3 ");
            arraylist.add(s14);
            arraylist.add(s13);
        }
        executeBindSql(stringbuffer.toString(), arraylist, connection);
        oracle.sql.DATE date = m_StartDate;
        oracle.sql.DATE date1 = m_EndDate;
        java.lang.String s15 = null;
        if(s1 != null && s1.indexOf('(') >= 0 && s1.indexOf(')') < s1.length())
            s15 = s1.substring(s1.indexOf('('), s1.indexOf(')') + 1);
        java.lang.StringBuffer stringbuffer1 = new StringBuffer(100);
        com.sun.java.util.collections.ArrayList arraylist1 = new ArrayList(5);
        stringbuffer1.append("SELECT ").append(s11).append(", ").append(s12).append(" , start_date, end_date FROM ").append(s10);
        stringbuffer1.append(" WHERE ").append(s12).append(" LIKE :1 ");
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s15))
            arraylist1.add("%");
        else
            arraylist1.add("%" + s15 + "%");
        int i = 1;
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(akregion.getRegionObjectType()) && !s6.startsWith("HR") && (oracle.apps.bis.pmv.common.StringUtil.emptyString(s13) || !s13.startsWith("HR")))
        {
            i++;
            stringbuffer1.append(" AND organization_id = :").append(i);
            arraylist1.add(s14);
            i++;
            stringbuffer1.append(" AND organization_type = :").append(i);
            arraylist1.add(s13);
        }
        i++;
        java.lang.StringBuffer stringbuffer2 = new StringBuffer(200);
        com.sun.java.util.collections.ArrayList arraylist2 = new ArrayList(arraylist1);
        stringbuffer2.append(stringbuffer1);
        stringbuffer2.append(" AND start_date = :").append(i);
        arraylist2.add(date);
        java.lang.StringBuffer stringbuffer3 = new StringBuffer(200);
        com.sun.java.util.collections.ArrayList arraylist3 = new ArrayList(arraylist1);
        stringbuffer3.append(stringbuffer1);
        stringbuffer3.append(" AND end_date = :").append(i);
        arraylist3.add(date1);
        resetValues();
        executeBindSql(stringbuffer2.toString(), arraylist2, connection);
        m_FromDateId = m_Id;
        m_FromDateValue = m_Value;
        m_FromDate = m_StartDate;
        resetValues();
        executeBindSql(stringbuffer3.toString(), arraylist3, connection);
        m_ToDateId = m_Id;
        m_ToDateValue = m_Value;
        m_ToDate = m_EndDate;
    }

    private void executeBindSql(java.lang.String s, com.sun.java.util.collections.ArrayList arraylist, java.sql.Connection connection)
    {
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        try
        {
            preparedstatement = connection.prepareStatement(s);
            oracle.jdbc.driver.OraclePreparedStatement oraclepreparedstatement = (oracle.jdbc.driver.OraclePreparedStatement)preparedstatement;
            oraclepreparedstatement.defineColumnType(1, 12, 80);
            oraclepreparedstatement.defineColumnType(2, 12, 240);
            oraclepreparedstatement.defineColumnType(3, 91);
            oraclepreparedstatement.defineColumnType(4, 91);
            if(arraylist != null)
            {
                Object obj = null;
                for(int i = 0; i < arraylist.size(); i++)
                {
                    java.lang.Object obj1 = arraylist.get(i);
                    if(obj1 instanceof oracle.sql.DATE)
                        oraclepreparedstatement.setDATE(i + 1, (oracle.sql.DATE)obj1);
                    else
                        oraclepreparedstatement.setString(i + 1, (java.lang.String)obj1);
                }

            }
            resultset = preparedstatement.executeQuery();
            if(resultset.next())
            {
                m_Id = resultset.getString(1);
                m_Value = resultset.getString(2);
                m_StartDate = ((oracle.jdbc.driver.OracleResultSet)resultset).getDATE(3);
                m_EndDate = ((oracle.jdbc.driver.OracleResultSet)resultset).getDATE(4);
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
    }

    private void resetValues()
    {
        m_Id = null;
        m_Value = null;
        m_StartDate = null;
        m_EndDate = null;
    }

    public java.lang.String getFromDateId()
    {
        return m_FromDateId;
    }

    public java.lang.String getFromDateValue()
    {
        return m_FromDateValue;
    }

    public java.lang.String getToDateId()
    {
        return m_ToDateId;
    }

    public java.lang.String getToDateValue()
    {
        return m_ToDateValue;
    }

    public oracle.sql.DATE getFromDate()
    {
        return m_FromDate;
    }

    public oracle.sql.DATE getToDate()
    {
        return m_ToDate;
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillDownHelper.java 115.2 2004/11/23 02:18:12 nbarik noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillDownHelper.java 115.2 2004/11/23 02:18:12 nbarik noship $", "od.oracle.apps.xxcrm.bis.pmv.drill");
    private java.lang.String m_Id;
    private java.lang.String m_Value;
    private oracle.sql.DATE m_StartDate;
    private oracle.sql.DATE m_EndDate;
    private java.lang.String m_FromDateId;
    private java.lang.String m_FromDateValue;
    private java.lang.String m_ToDateId;
    private java.lang.String m_ToDateValue;
    private oracle.sql.DATE m_FromDate;
    private oracle.sql.DATE m_ToDate;

}
