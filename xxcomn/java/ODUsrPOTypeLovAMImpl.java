package od.oracle.apps.xxptp.pos.changeorder.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import od.oracle.apps.xxptp.pos.changeorder.server.ODPOTypesVOImpl;
import od.oracle.apps.xxptp.pos.changeorder.server.ODUsersVOImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODUsrPOTypeLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODUsrPOTypeLovAMImpl()
  {
  }



  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.pos.isp.server", "UsrPOTypeLovAMLocal");
  }

  /**
   * 
   * Container's getter for ODPOTypesVO
   */
  public ODPOTypesVOImpl getODPOTypesVO()
  {
    return (ODPOTypesVOImpl)findViewObject("ODPOTypesVO");
  }

  /**
   * 
   * Container's getter for ODUsersVO
   */
  public ODUsersVOImpl getODUsersVO()
  {
    return (ODUsersVOImpl)findViewObject("ODUsersVO");
  }





}