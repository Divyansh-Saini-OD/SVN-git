package od.oracle.apps.xxcrm.cdh.ebl.exec.server;
/* Subversion Info:
 * $HeadURL: http://svn.na.odcorp.net/svn/od/common/trunk/xxcomn/java/od/oracle/apps/xxcrm/cdh/ebl/exec/server/ODEBillDocExceptionAMImpl.java $
 * $Rev: 266069 $
 * $Date: 2017-02-17 18:32:08 -0500 (Fri, 17 Feb 2017) $
*/
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.jbo.server.ApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
//Added by Mangala
import oracle.apps.fnd.framework.OAViewObject;
import oracle.jbo.Row;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OARow;
import oracle.jbo.domain.Number;
import od.oracle.apps.xxcrm.cdh.ebl.server.ODUtil;
import java.sql.ResultSet;
import java.sql.SQLException;
import oracle.jdbc.OracleCallableStatement;
import od.oracle.apps.xxcrm.cdh.ebl.server.ODUtil;
import java.io.Serializable;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODEBillDocExceptionAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODEBillDocExceptionAMImpl()
  {
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxcrm.cdh.ebl.exec.server", "ODEBillDocExceptionAMLocal");
  }
  //Added by Mangala
  public void createTable(String CustAccountId)
  {
    OAViewObject vo = (OAViewObject)this.getODEBillDocExceptionVO();
      
    if (!vo.isPreparedForExecution())
    {
      vo.setWhereClause(null);
      vo.setWhereClause("cust_account_id = " + CustAccountId );
      vo.executeQuery();
    }
  
  OADBTransaction transaction = this.getOADBTransaction();
  Number extnId = transaction.getSequenceValue("EGO_EXTFWK_S");
                String lqry="SELECT attr_group_id "  
                 +" FROM   ego_attr_groups_v"
                 +" WHERE  attr_group_type = 'XX_CDH_CUST_ACCT_SITE'"
                 +" AND    attr_group_name = 'BILLDOCS'";
        Serializable inputParams[] = { lqry };
        Object retval= this.invokeMethod("execQuery",inputParams);
        Number attrGrpID = (Number)retval;

 if (vo.getRowCount()==0)
 {
    if (vo!=null)
        {
          OARow cdRow = (OARow)vo.createRow();
          cdRow.setAttribute("ExtensionId", extnId);
          cdRow.setAttribute("AttrGroupId",attrGrpID);
          cdRow.setAttribute("CustAccountId",CustAccountId);
       //   vo.insertRow(cdRow);
          cdRow.setNewRowState(Row.STATUS_INITIALIZED);
        }
    
  } //End of If vo.getRowCount()==0
  vo.first();
   } //end of createTable 
   
 //For Pay Doc 
 public void createPayDoc(String CustAccountId)
 {
     ODUtil utl = new ODUtil(this);
     OAViewObject vo1 = (OAViewObject)this.getODEBillPayDocVO(); 
     utl.log("Before Execute Query");
      vo1.setWhereClause(null);
      vo1.setWhereClause("cust_account_id = " + CustAccountId );
      utl.log ("cust_account_id:" + CustAccountId);
      vo1.executeQuery();
       utl.log( "Rowcount:" + vo1.getRowCount());
       utl.log("End of Pay Doc method");
   } //end of Pay Doc
  
  // Method for the button "Save"
  public void save()
  {
     getTransaction().setClearCacheOnCommit(true);
    getTransaction().commit();
  } // end of save()

// Method for Execute Query
 public Number execQuery(String pQuery)
  {
     // ODUtil utl = new ODUtil(this);
      //utl.log("ODEBillDocExceptionVO :Begin execQuery");
      OracleCallableStatement ocs=null;
      ResultSet rs=null;
      OADBTransaction db=this.getOADBTransaction();
      String stmt = pQuery;
      Object obj = (Object)new String("NODATA");
      Number val=new Number(0);
     ocs = (OracleCallableStatement)db.createCallableStatement(stmt,1);

      try
      {
        rs = ocs.executeQuery();
        if (rs.next())
        {
          val = new Number(rs.getLong(1));
         
        }
        rs.close();
        ocs.close();
      }
      catch(SQLException e)
      {
       
      }
      finally
        {
           try{
                if(rs != null)
                   rs.close();
                if(ocs != null)
                   ocs.close();
              }
		   catch(Exception e){}
        }
      return val;
	  
  }// end of Execute Query

  /**
   * 
   * Container's getter for ODEBillDocExceptionVO
   */
  public OAViewObjectImpl getODEBillDocExceptionVO()
  {
    return (OAViewObjectImpl)findViewObject("ODEBillDocExceptionVO");
  }

  /**
   * 
   * Container's getter for ODEBillPayDocVO
   */
  public OAViewObjectImpl getODEBillPayDocVO()
  {
    return (OAViewObjectImpl)findViewObject("ODEBillPayDocVO");
  }

  /**
   * 
   * Container's getter for ODEBillDocExcepHRVO
   */
  public OAViewObjectImpl getODEBillDocExcepHRVO()
  {
    return (OAViewObjectImpl)findViewObject("ODEBillDocExcepHRVO");
  }




}