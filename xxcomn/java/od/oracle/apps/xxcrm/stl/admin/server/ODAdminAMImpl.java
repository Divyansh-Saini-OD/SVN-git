package od.oracle.apps.xxcrm.stl.admin.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.jbo.Row;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODAdminAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODAdminAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxcrm.stl.admin.server", "ODAdminAMLocal");
  }

  /**
   * 
   * Container's getter for ODRepStoreMapVO1
   */
  public ODRepStoreMapVOImpl getODRepStoreMapVO1()
  {
    return (ODRepStoreMapVOImpl)findViewObject("ODRepStoreMapVO1");
  }
  
  // method to Commit Transactions to Database
   public void apply()
 {
    getOADBTransaction().commit();
 }

  // method to rollback Transactions to Database
  public void cancel()
 {
    getOADBTransaction().rollback();
 }

 //Method Create row for ODRepStoreMapVO1
   public void createMapping()
  {
    ODRepStoreMapVOImpl vo = getODRepStoreMapVO1();

     if (!vo.isPreparedForExecution())     
     {    
        vo.executeQuery();   
     } 
 
    Row row = vo.createRow();   
    vo.insertRow(row);
    row.setNewRowState(Row.STATUS_INITIALIZED);

  } // end createMapping


 public void initDetails(String id)
  {
    ODRepStoreMapVOImpl vo = getODRepStoreMapVO1();
 
    vo.initQuery(id);
   
  } // end initDetails()
  /**
   * 
   * Container's getter for ODRepStoreSrchVO1
   */
  public ODRepStoreSrchVOImpl getODRepStoreSrchVO1()
  {
    return (ODRepStoreSrchVOImpl)findViewObject("ODRepStoreSrchVO1");
  }
}