package od.oracle.apps.xxcrm.asl.util;

import oracle.jdbc.driver.OracleCallableStatement;
import oracle.jdbc.driver.OracleConnection;
import oracle.jdbc.driver.OraclePreparedStatement;
import oracle.jdbc.driver.OracleResultSet;
import oracle.jdbc.driver.OracleStatement;
import oracle.jdbc.driver.*;
import java.sql.*;

public class ODASLLog
{
    public static String LOG_SEV_MAJOR = "MAJOR";
    public static String LOG_SEV_MEDIUM  = "MEDIUM";
    public static String LOG_SEV_MINOR = "MINOR";

    public static void logToDatabase(
        OracleConnection conn, 
        String appName,
        String progType,
        String progName,
        String moduleName,
        String errLocation,
        String errCode,
        String errMessage,
        String errSeverity)
    {
        try
        {
            PreparedStatement stmt =conn.prepareStatement("begin XX_COM_ERROR_LOG_PUB.log_error_crm(p_application_name => ?, p_program_type => ?, p_program_name => ?, p_module_name => ?, p_error_location => ?, p_error_message_code => ?, p_error_message => ?, p_error_message_severity => ?); end;");
            stmt.setString(1, appName);
            stmt.setString(2, progType);
            stmt.setString(3, progName);
            stmt.setString(4, moduleName);
            stmt.setString(5, errLocation);
            stmt.setString(6, errCode);
            stmt.setString(7, errMessage);
            stmt.setString(8, errSeverity);
            stmt.executeQuery();
            stmt.close();
            
        } catch (Exception e)
        {
            System.out.println("Exception:" + e.toString());
        }
    }
}
