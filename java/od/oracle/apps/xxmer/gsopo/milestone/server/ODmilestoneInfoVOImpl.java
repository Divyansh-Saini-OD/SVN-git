package od.oracle.apps.xxmer.gsopo.milestone.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODmilestoneInfoVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODmilestoneInfoVOImpl()
  {
  }
  public void ODMSInfoVOExecution(String poHdrId)
  {
    setWhereClauseParams(null);
    setWhereClause("PO_HEADER_ID = :1 ");
    setWhereClauseParam(0,poHdrId);
    executeQuery();
  }
}