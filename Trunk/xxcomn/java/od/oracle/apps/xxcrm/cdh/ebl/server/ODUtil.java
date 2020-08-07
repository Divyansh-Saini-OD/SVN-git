package od.oracle.apps.xxcrm.cdh.ebl.server;



import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import java.sql.SQLException;
import oracle.jdbc.OracleCallableStatement;
import oracle.jbo.domain.Date;
import java.sql.Types;


public class ODUtil 
{
  public OADBTransaction db;

  public ODUtil(OADBTransaction p_dbTrans)
  {
    db = p_dbTrans;
  }

  public ODUtil(OAApplicationModule p_am)
  {
    db = p_am.getOADBTransaction();
  }

  public void log(String p_msg)
  {
    //try
    //{
      OracleCallableStatement ocs = null;
      //String stmt="BEGIN XX_CDH_EBL_UTIL_PKG.log_error('"+p_msg+"'); END;";
      String stmt="XX_CDH_EBL_UTIL_PKG.log_error('"+p_msg+"')";
      executeProc(stmt);
      /*try
      {
        ocs = (OracleCallableStatement)db.createCallableStatement(stmt, 1);
        ocs.execute();      
      }
      catch(SQLException sqlexception)
      {
          throw sqlexception;
      }
      finally
      {
          if(ocs != null)
              ocs.close();
      }
    }
    catch(Exception e)
    {
      throw new OAException(e.toString()+" ODUtil.java ");
    }*/
  }
    
  /*
   * method : executeProc
   * used to execute database procedure.
   * Parameter: pass DB procedure along with parameter as String
   * Example ODUtilobj.executeProc("XX_CDH_EBL_UTIL_PKG.log_error("Test")")
   * No semicolon(;) to be suffixed with procedure
   * Used only for Asynchronious procedure like error log.
   */
  public void executeProc(String p_procedure)
  {
    try
    {
      OracleCallableStatement ocs = null;
      String stmt="BEGIN "+p_procedure+"; END;";
      try
      {
        ocs = (OracleCallableStatement)db.createCallableStatement(stmt, 1);
        ocs.execute();
        ocs.close();
      }
      catch(SQLException sqlexception)
      {
          throw sqlexception;
      }
      finally
      {
          if(ocs != null)
              ocs.close();
      }
    }
    catch(Exception e)
    {
      throw new OAException(e.toString()+" ODUtil.java ");
    }
   }

  public Date calculateEffDate(String payTerm,Date invDate)
  {
      //OAApplicationModule am=(OAApplicationModule)getApplicationModule();
      //ODUtil utl= new ODUtil(am);
      //Date effDate;
      String effDate=null;
      log("ODEBillCustDocVO :Begin calculateEffDate");
      OracleCallableStatement ocs=null;
      //OADBTransaction db=am.getOADBTransaction();
      String stmt = "BEGIN :1 := XX_AR_INV_FREQ_PKG.COMPUTE_EFFECTIVE_DATE(:2,:3); END;";
      log("calculateEffDate:"+ stmt);
      ocs = (OracleCallableStatement)db.createCallableStatement(stmt,1);

      try
      {
        ocs.registerOutParameter(1,Types.DATE);
        ocs.setString(2,payTerm);
        ocs.setDATE(3,invDate);        
        ocs.execute();
        effDate = ocs.getDate(1).toString();
        ocs.close();
      }
      catch(SQLException e)
      {
        log("calculateEffDate:Error:"+ e.toString());
      }
	  finally
        {
           try{
                if(ocs != null)
                   ocs.close();
              }
		   catch(Exception e){}
        }
      log("calculateEffDate:"+ effDate);
      log("ODEBillCustDocVO :End calculateEffDate");
      Date d=new Date(effDate);
      return d;
  }


}