package od.oracle.apps.xxcrm.asl.util;

import oracle.jdbc.driver.OracleCallableStatement;
import oracle.jdbc.driver.OracleConnection;
import oracle.jdbc.driver.OraclePreparedStatement;
import oracle.jdbc.driver.OracleResultSet;
import oracle.jdbc.driver.OracleStatement;
import oracle.jdbc.driver.*;
import java.sql.*;

public class ODASLUtil
{
    public static void appsInit(OracleConnection conn, String userId, String respId, String appId) throws Exception
    {
        PreparedStatement statement = conn.prepareStatement("begin fnd_global.apps_initialize(?, ?, ?); end; ");
        statement.setString(1, userId);
        statement.setString(2, respId);
        statement.setString(3, appId);
        ResultSet r = statement.executeQuery();
        statement.close();
    }

    public static void enableSQLTrace(OracleConnection conn)
    {
        try 
        {
            PreparedStatement statement = conn.prepareStatement("alter session set sql_trace=true");
            ResultSet r = statement.executeQuery();
            statement.close();
        }catch (Exception e)
        {
            System.out.println("Exception:" + e.toString());
        }
    }
    public static void disableSQLTrace(OracleConnection conn)
    {
        try 
        {
            PreparedStatement statement = conn.prepareStatement("alter session set sql_trace=false");
            ResultSet r = statement.executeQuery();
            statement.close();
        }catch (Exception e)
        {
            System.out.println("Exception:" + e.toString());
        }
    }

    public static boolean isOfflineSQLTraceEnabled(OracleConnection conn)
    {
        boolean retVal = false;
        String profileValue = "N";
        try
        {
            PreparedStatement stmt =conn.prepareStatement("select fnd_profile.value(?) from sys.dual");
            stmt.setString(1, "XX_ASL_ENABLE_SQL_TRACE");
            ResultSet r = stmt.executeQuery();
            while (r.next())
            {
                profileValue = r.getString(1);
            }
            stmt.close();
            if ("Y".equals(profileValue))
            {
                retVal = true;
            }
            else
            {
                retVal = false;
            }
        }catch (Exception e)
        {
            System.out.println("Exception:" + e.toString());
            retVal = false;
        }
        return retVal;
    }

    public static String getUserId(OracleConnection conn, String userName) throws Exception
    {
        String userId = "";
        PreparedStatement stmt = conn.prepareStatement("select user_id from fnd_user where upper(user_name)=upper(?)");
        stmt.setString(1, userName);
        ResultSet r = stmt.executeQuery();
        r.next();
        userId = new Integer(r.getInt(1)).toString();
        stmt.close();
        return userId;
    }

    public static int getApplicationId(OracleConnection conn, String responsibilityKey)
    {
        int appId = 0;
        try 
        {
            PreparedStatement stmt = conn.prepareStatement("select application_id from fnd_responsibility_vl where responsibility_key = ?");
            stmt.setString(1, responsibilityKey);
            ResultSet r = stmt.executeQuery();
            r.next();
            appId = r.getInt(1);
            stmt.close();
        } catch (Exception e)
        {
            appId = 0;
            System.out.println("Exception:" + e.toString());
        }
        return appId;
    }

    public static int getResponsibilityId(OracleConnection conn, String responsibilityKey)
    {
        int respId = 0;
        try 
        {
            PreparedStatement stmt = conn.prepareStatement("select responsibility_id from fnd_responsibility_vl where responsibility_key = ?");
            stmt.setString(1, responsibilityKey);
            ResultSet r = stmt.executeQuery();
            r.next();
            respId = r.getInt(1);
            stmt.close();
        } catch (Exception e)
        {
            respId = 0;
            System.out.println("Exception:" + e.toString());
        }
        return respId;
    }

    public static boolean isOfflineLogEnabled(OracleConnection conn)
    {
        boolean retVal = false;
        String profileValue = "N";
        try
        {
            PreparedStatement stmt =conn.prepareStatement("select fnd_profile.value(?) from sys.dual");
            stmt.setString(1, "XX_ASL_ENABLE_LOG");
            ResultSet r = stmt.executeQuery();
            while (r.next())
            {
                profileValue = r.getString(1);
            }
            stmt.close();
            if ("Y".equals(profileValue))
            {
                retVal = true;
            }
            else
            {
                retVal = false;
            }
        }catch (Exception e)
        {
            System.out.println("Exception:" + e.toString());
            retVal = false;
        }
        return retVal;
    }

    public static String decryptPassword(String password)
    {
        char[] passenc = password.toCharArray();
        char[] passdec = password.toCharArray();
        for (int i=0;i<password.length();i++)
        { 
            switch (passenc[i])
            {
                case '0': passdec[i]='X'; break;
                case '1': passdec[i]='I'; break;
                case '2': passdec[i]='6'; break;
                case '3': passdec[i]='S'; break;
                case '4': passdec[i]='N'; break;
                case '5': passdec[i]='Y'; break;
                case '6': passdec[i]='K'; break;
                case '7': passdec[i]='W'; break;
                case '8': passdec[i]='1'; break;
                case '9': passdec[i]='C'; break;
                case 'A': passdec[i]='Q'; break;
                case 'B': passdec[i]='G'; break;
                case 'C': passdec[i]='T'; break;
                case 'D': passdec[i]='Z'; break;
                case 'E': passdec[i]='5'; break;
                case 'F': passdec[i]='J'; break;
                case 'G': passdec[i]='O'; break;
                case 'H': passdec[i]='7'; break;
                case 'I': passdec[i]='P'; break;
                case 'J': passdec[i]='A'; break;
                case 'K': passdec[i]='F'; break;
                case 'L': passdec[i]='0'; break;
                case 'M': passdec[i]='3'; break;
                case 'N': passdec[i]='R'; break;
                case 'O': passdec[i]='D'; break;
                case 'P': passdec[i]='U'; break;
                case 'Q': passdec[i]='H'; break;
                case 'R': passdec[i]='8'; break;
                case 'S': passdec[i]='4'; break;
                case 'T': passdec[i]='L'; break;
                case 'U': passdec[i]='V'; break;
                case 'V': passdec[i]='B'; break;
                case 'W': passdec[i]='9'; break;
                case 'X': passdec[i]='E'; break;
                case 'Y': passdec[i]='2'; break;
                case 'Z': passdec[i]='M'; break;
                default: passdec[i]=passenc[i]; break;
            }
        }
        return new String(passdec);
    }
}
