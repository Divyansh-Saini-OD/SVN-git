package od.oracle.apps.xxmer.schema.wfh.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class VendorExistenceVVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public VendorExistenceVVOImpl()
  {
  }
  public void initQuery(Number vendorSiteId) 
  {
    setWhereClauseParams(null);
    setWhereClauseParam(0, vendorSiteId);
    executeQuery();
  }
}