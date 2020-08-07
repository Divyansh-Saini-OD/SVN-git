package od.oracle.apps.xxptp.inv.setup.cp;

import oracle.jbo.server.DBTransaction;
import oracle.jdbc.driver.OracleCallableStatement;
import java.sql.SQLException;
import oracle.apps.inv.setup.utilities.MGApplicationModule;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import oracle.jbo.ApplicationModule;

public class WriteLog
{
public void writeLog 
	(
	String p_program_type, 
	String p_program_name,
	String p_module_name,
	String p_error_location,
	int p_error_message_code,
	String p_error_message,
	String p_error_message_serverity,
	String p_notify_flag,
	ApplicationModule p_mRootAM
	) 
    {	
	 OracleCallableStatement cst = null;
     ApplicationModule       v_mRootAM;
	 v_mRootAM = p_mRootAM;

     String str  = "BEGIN "+
                   " xx_com_error_log_pub.log_error ("+
                   "   p_program_type => :1  "+
                   " , p_program_name  => :2  "+
                   " , p_module_name  => :3  "+
                   " , p_error_location  => :4  "+
                   " , p_error_message_code       => :5);"+
                   " , p_error_message  => :6  "+
                   " , p_error_message_severity  => :7  "+
                   " , p_notify_flag       => :8);"+
                   "END;";

     cst =  (OracleCallableStatement) ((DBTransaction) 
          v_mRootAM.getTransaction()).createCallableStatement( str, 1 );
     try
     {
       cst.setString(1,p_program_type);
       cst.setString(2,p_program_name);		          
	   cst.setString(3,p_module_name);
	   cst.setString(4,p_error_location);
	   cst.setInt(5,p_error_message_code);
	   cst.setString(6,p_error_message);
	   cst.setString(7,p_error_message_serverity);
	   cst.setString(8,p_notify_flag);
       cst.executeUpdate(); 
     }catch(SQLException e)
     {

     }
     finally
     {
      try
      {
       if(cst != null)
         cst.close();
      }catch(SQLException e)
      {
		  
      }
     }      
}
}
