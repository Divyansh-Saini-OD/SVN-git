package od.oracle.apps.xxom.xxTDSrexceptions.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.jbo.server.ApplicationModuleImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class xxTDSrexceptionsAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public xxTDSrexceptionsAMImpl()
  {
  }

  /**
   * 
   * Container's getter for xxTDSrexceptionsVO1
   */
  public xxTDSrexceptionsVOImpl getxxTDSrexceptionsVO1()
  {
    return (xxTDSrexceptionsVOImpl)findViewObject("xxTDSrexceptionsVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxom.xxTDSrexceptions.server", "xxTDSrexceptionsAMLocal");
  }
}