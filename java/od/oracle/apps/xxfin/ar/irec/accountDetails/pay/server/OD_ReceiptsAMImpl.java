package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

// Referenced classes of package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server:
//            OD_ReceiptsVOImpl

public class OD_ReceiptsAMImpl extends OAApplicationModuleImpl
{

    public OD_ReceiptsAMImpl()
    {
    }

    public static void main(String args[])
    {
        OAApplicationModuleImpl.launchTester("od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server", "OD_ReceiptsAMLocal");
    }

    public OD_ReceiptsVOImpl getOD_ReceiptsVO()
    {
        return (OD_ReceiptsVOImpl)findViewObject("OD_ReceiptsVO");
    }

  /**
   * 
   * Container's getter for OD_PaymentPDFDirectoryVO
   */
  public OD_PaymentPDFDirectoryVOImpl getOD_PaymentPDFDirectoryVO()
  {
    return (OD_PaymentPDFDirectoryVOImpl)findViewObject("OD_PaymentPDFDirectoryVO");
  }

  /**
   * 
   * Container's getter for OD_InstanceVO
   */
  public OD_InstanceVOImpl getOD_InstanceVO()
  {
    return (OD_InstanceVOImpl)findViewObject("OD_InstanceVO");
  }

  /**
   * 
   * Container's getter for OD_CustomerNumberVO
   */
  public OD_CustomerNumberVOImpl getOD_CustomerNumberVO()
  {
    return (OD_CustomerNumberVOImpl)findViewObject("OD_CustomerNumberVO");
  }


}
