package od.oracle.apps.xxmer.newstoresetup.server;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;

//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class NewStoreSetupAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public NewStoreSetupAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxmer.newstoresetup.server", "NewStoreSetupAMLocal");
  }


  public void initStoreSetupList()
  {
    NewStoreSetupVOImpl vo = getNewStoreSetupVO1();
    if (vo==null)
    {
      MessageToken[] errTokens = {new MessageToken("OBJECT_NAME","NewStoreSetupVO1")};
      throw new OAException("XXMER","XXMER_VC_OBJECT_NOT_FOUND",errTokens);
    }
    vo.initQuery();
  }

  /**
   * 
   * Container's getter for NewStoreSetupVO1
   */
  public NewStoreSetupVOImpl getNewStoreSetupVO1()
  {
    return (NewStoreSetupVOImpl)findViewObject("NewStoreSetupVO1");
  }
















}