// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames 
// Source File Name:   ODDrillJDBCUtil.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.ArrayList;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import oracle.apps.bis.pmv.parameters.Parameters;
import oracle.apps.fnd.common.VersionInfo;
import oracle.jdbc.driver.OracleResultSet;
import oracle.jdbc.driver.OracleStatement;

public class ODDrillJDBCUtil
{

    public ODDrillJDBCUtil()
    {
    }

    public static com.sun.java.util.collections.ArrayList getScheduleParameters(java.lang.String s, java.sql.Connection connection)
    {
        com.sun.java.util.collections.ArrayList arraylist = null;
        java.sql.PreparedStatement preparedstatement = null;
        try
        {
            preparedstatement = connection.prepareStatement("SELECT attribute_name, dimension, session_value, session_description, period_date, operator FROM bis_user_attributes WHERE schedule_id = :1");
            preparedstatement.setInt(1, java.lang.Integer.parseInt(s));
            arraylist = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getParameters(preparedstatement);
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(preparedstatement != null)
                    preparedstatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        return arraylist;
    }

    public static com.sun.java.util.collections.ArrayList getSavedDefaultParameters(java.lang.String s, java.lang.String s1, java.sql.Connection connection)
    {
        com.sun.java.util.collections.ArrayList arraylist = null;
        java.sql.PreparedStatement preparedstatement = null;
        try
        {
            preparedstatement = connection.prepareStatement("SELECT attribute_name, dimension, default_value, default_description, period_date, operator FROM bis_user_attributes WHERE function_name=:1 AND user_id = :2 AND session_id IS NULL AND session_description = 'NULL'");
            preparedstatement.setString(1, s);
            preparedstatement.setInt(2, java.lang.Integer.parseInt(s1));
            arraylist = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getParameters(preparedstatement);
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(preparedstatement != null)
                    preparedstatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        return arraylist;
    }

    public static com.sun.java.util.collections.ArrayList getSessionParameters(java.lang.String s, java.lang.String s1, java.lang.String s2, java.sql.Connection connection)
    {
        com.sun.java.util.collections.ArrayList arraylist = null;
        java.sql.PreparedStatement preparedstatement = null;
        try
        {
            preparedstatement = connection.prepareStatement("SELECT attribute_name, dimension, session_value, session_description, period_date, operator FROM bis_user_attributes WHERE function_name=:1 AND user_id = :2 AND session_id=:3");
            preparedstatement.setString(1, s);
            preparedstatement.setInt(2, java.lang.Integer.parseInt(s1));
            preparedstatement.setString(3, s2);
            arraylist = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getParameters(preparedstatement);
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(preparedstatement != null)
                    preparedstatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        return arraylist;
    }

    private static com.sun.java.util.collections.ArrayList getParameters(java.sql.PreparedStatement preparedstatement)
    {
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(11);
        java.sql.ResultSet resultset = null;
        Object obj = null;
        try
        {
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            oraclestatement.defineColumnType(1, 12, 80);
            oraclestatement.defineColumnType(2, 12, 80);
            oraclestatement.defineColumnType(3, 12, 2000);
            oraclestatement.defineColumnType(4, 12, 2000);
            oraclestatement.defineColumnType(5, 91);
            oraclestatement.defineColumnType(6, 12, 2000);
            oracle.apps.bis.pmv.parameters.Parameters parameters;
            for(resultset = preparedstatement.executeQuery(); resultset.next(); arraylist.add(parameters))
            {
                parameters = new Parameters();
                parameters.setParameterName(resultset.getString(1));
                parameters.setDimension(resultset.getString(2));
                parameters.setParameterValue(resultset.getString(3));
                parameters.setParameterDescription(resultset.getString(4));
                parameters.setPeriod(((oracle.jdbc.driver.OracleResultSet)resultset).getDATE(5));
                parameters.setOperator(resultset.getString(6));
                parameters.setIdFlag("Y");
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
        return arraylist;
    }

    public static java.lang.String getRespId(java.lang.String s, java.sql.Connection connection)
    {
        java.lang.String s1 = null;
        java.sql.PreparedStatement preparedstatement = null;
        java.sql.ResultSet resultset = null;
        try
        {
            preparedstatement = connection.prepareStatement("SELECT responsibility_id FROM bis_scheduler WHERE schedule_id = :1");
            oracle.jdbc.driver.OracleStatement oraclestatement = (oracle.jdbc.driver.OracleStatement)preparedstatement;
            oraclestatement.defineColumnType(1, 12, 80);
            preparedstatement.setInt(1, java.lang.Integer.parseInt(s));
            resultset = preparedstatement.executeQuery();
            if(resultset.next())
                s1 = resultset.getString(1);
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
        return s1;
    }

    public static com.sun.java.util.collections.ArrayList getScheduleNonPageParameters(java.lang.String s, com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1, java.sql.Connection connection)
    {
        com.sun.java.util.collections.ArrayList arraylist2 = null;
        com.sun.java.util.collections.ArrayList arraylist3 = new ArrayList(13);
        java.sql.PreparedStatement preparedstatement = null;
        java.lang.StringBuffer stringbuffer = new StringBuffer(300);
        stringbuffer.append("SELECT attribute_name, dimension, session_value, session_description, period_date, operator FROM bis_user_attributes WHERE schedule_id = :1");
        stringbuffer.append(" AND ((dimension IS NULL AND attribute_name NOT IN ( ");
        int i = 2;
        if(arraylist != null)
        {
            for(int j = 0; j < arraylist.size(); j++)
            {
                stringbuffer.append(":").append(i);
                arraylist3.add((java.lang.String)arraylist.get(j));
                i++;
                if(j != arraylist.size() - 1)
                    stringbuffer.append(", ");
            }

        }
        stringbuffer.append(" )) OR (dimension IS NOT NULL AND dimension NOT IN ( ");
        if(arraylist1 != null)
        {
            for(int k = 0; k < arraylist1.size(); k++)
            {
                stringbuffer.append(":").append(i);
                arraylist3.add((java.lang.String)arraylist1.get(k));
                i++;
                if(k != arraylist1.size() - 1)
                    stringbuffer.append(", ");
            }

        }
        stringbuffer.append(" ))) ");
        try
        {
            preparedstatement = connection.prepareStatement(stringbuffer.toString());
            preparedstatement.setInt(1, java.lang.Integer.parseInt(s));
            if(arraylist3 != null)
            {
                for(int l = 0; l < arraylist3.size(); l++)
                    preparedstatement.setString(l + 2, (java.lang.String)arraylist3.get(l));

            }
            arraylist2 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillJDBCUtil.getParameters(preparedstatement);
        }
        catch(java.sql.SQLException _ex) { }
        finally
        {
            try
            {
                if(preparedstatement != null)
                    preparedstatement.close();
            }
            catch(java.lang.Exception _ex) { }
        }
        return arraylist2;
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillJDBCUtil.java 115.2 2006/01/05 15:10:42 serao noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillJDBCUtil.java 115.2 2006/01/05 15:10:42 serao noship $", "od.oracle.apps.xxcrm.bis.pmv.drill");
    public static final java.lang.String SCHEDULE_PARAMETERS_SQL = "SELECT attribute_name, dimension, session_value, session_description, period_date, operator FROM bis_user_attributes WHERE schedule_id = :1";
    public static final java.lang.String SAVED_DEFAULT_PARAMETERS_SQL = "SELECT attribute_name, dimension, default_value, default_description, period_date, operator FROM bis_user_attributes WHERE function_name=:1 AND user_id = :2 AND session_id IS NULL AND session_description = 'NULL'";
    public static final java.lang.String SESSION_PARAMETERS_SQL = "SELECT attribute_name, dimension, session_value, session_description, period_date, operator FROM bis_user_attributes WHERE function_name=:1 AND user_id = :2 AND session_id=:3";
    public static final java.lang.String RESP_ID_SQL = "SELECT responsibility_id FROM bis_scheduler WHERE schedule_id = :1";

}
