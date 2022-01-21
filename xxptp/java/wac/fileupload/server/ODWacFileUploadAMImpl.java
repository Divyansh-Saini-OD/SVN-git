/*===========================================================================+
 |                             Office Depot - Project Simplify               |
 |                 Oracle NAIO                                               |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODWacFileUploadAMImpl.java                                    |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Class to implement AM to access all the VO's                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    None                                                                   |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    31-JUL-07 Mithun D S   Created                                         |
 |                                                                           |
 +===========================================================================*/

package od.oracle.apps.xxptp.wac.fileupload.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.server.FndLobsVOImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODWacFileUploadAMImpl extends OAApplicationModuleImpl
{

  /**
   *
   * This is the default constructor (do not remove)
   */
  public ODWacFileUploadAMImpl()
  {
  }

  /**
   *
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxptp.wac.fileupload.server", "ODWacFileUploadAMLocal");
  }


  /**
   *
   * Container's getter for FndLobsVO
   */
  public FndLobsVOImpl getFndLobsVO()
  {
    return (FndLobsVOImpl)findViewObject("FndLobsVO");
  }









  /**
   *
   * Container's getter for ODInvAverageCostStgVO
   */
  public ODInvAverageCostStgVOImpl getODInvAverageCostStgVO()
  {
    return (ODInvAverageCostStgVOImpl)findViewObject("ODInvAverageCostStgVO");
  }


}