package od.oracle.apps.xxcrm.mps.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class OD_MPSPartyDevicesColorTonerVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public OD_MPSPartyDevicesColorTonerVOImpl()
  {
  }
  public void initColorTonerCount(String serialNo)
  {
    setWhereClause("SERIAL_NO= '"+serialNo+"'");
    executeQuery();
    System.out.println("##### rowcount="+getRowCount());
  }  
}