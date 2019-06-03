package od.oracle.apps.xxmer.wfh.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class DeletePlannerVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public DeletePlannerVOImpl()
  {
  }

  public void initQuery(String plannerId)
  {
    setWhereClauseParams(null); // clear older where clauses
    setWhereClauseParam(0, plannerId);
    System.out.println("initQuery: " + getQuery());
    executeQuery();
    System.out.println("getRowCount[" + getRowCount() + "]");
    System.out.println("getFetchedRowCount[" + getFetchedRowCount() + "]");
  }

}