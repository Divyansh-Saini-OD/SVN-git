package od.oracle.apps.xxcrm.mps.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class OD_MPSPartyDevicesUpdateVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public OD_MPSPartyDevicesUpdateVOImpl()
  {
  }

  public void initFetchSerialNo(String serialNo)
  {
    setWhereClause("SERIAL_NO = '"+serialNo+"'");
    executeQuery();
  } 
  
}