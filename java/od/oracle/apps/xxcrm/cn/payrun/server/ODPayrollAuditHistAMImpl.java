package od.oracle.apps.xxcrm.cn.payrun.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import od.oracle.apps.xxcrm.cn.payrun.lov.server.*;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODPayrollAuditHistAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODPayrollAuditHistAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxcrm.cn.payrun.server", "ODPayrollAuditHistAMLocal");
  }

  /**
   * 
   * Container's getter for ODPayrollAuditHistVO1
   */
  public ODPayrollAuditHistVOImpl getODPayrollAuditHistVO1()
  {
    return (ODPayrollAuditHistVOImpl)findViewObject("ODPayrollAuditHistVO1");
  }

  /**
   * 
   * Container's getter for ODPayrollAuditTransStatusLOVVO1
   */
  public ODPayrollAuditTransStatusLOVVOImpl getODPayrollAuditTransStatusLOVVO1()
  {
    return (ODPayrollAuditTransStatusLOVVOImpl)findViewObject("ODPayrollAuditTransStatusLOVVO1");
  }

  /**
   * 
   * Container's getter for ODPayrollAuditPayrunLOVVO1
   */
  public ODPayrollAuditPayrunLOVVOImpl getODPayrollAuditPayrunLOVVO1()
  {
    return (ODPayrollAuditPayrunLOVVOImpl)findViewObject("ODPayrollAuditPayrunLOVVO1");
  }


}
