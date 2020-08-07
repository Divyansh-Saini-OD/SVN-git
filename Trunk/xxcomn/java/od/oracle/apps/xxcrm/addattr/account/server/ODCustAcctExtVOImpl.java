package od.oracle.apps.xxcrm.addattr.account.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODCustAcctExtVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODCustAcctExtVOImpl()
  {
  }

  public void initQuery(String attrGrpId,String custAcctId)
  {
    Number aId = new Number(Integer.parseInt(attrGrpId));
    Number cId = new Number(Integer.parseInt(custAcctId));
    this.setWhereClauseParams(null);
    this.setWhereClauseParam(0,aId);
    this.setWhereClauseParam(1,cId);
    this.executeQuery();
  }
}