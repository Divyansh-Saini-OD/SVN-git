package od.oracle.apps.xxcrm.mps.reports.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class XXCSMPSCustomersListAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XXCSMPSCustomersListAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XXCSMPSCustomersListVO1
   */
  public XXCSMPSCustomersListVOImpl getXXCSMPSCustomersListVO1()
  {
    return (XXCSMPSCustomersListVOImpl)findViewObject("XXCSMPSCustomersListVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxcrm.mps.reports.server", "XXCSMPSCustomersListAMLocal");
  }
  public void initCustList()
  {
    XXCSMPSCustomersListVOImpl mpsCustListVO = getXXCSMPSCustomersListVO1();
     mpsCustListVO.initCustList();
  } 
  
}