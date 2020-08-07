package od.oracle.apps.xxcrm.addattr.tempcl.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class ODTempCreditLimitVOImpl extends OAViewObjectImpl {
    /**This is the default constructor (do not remove)
     */
    public ODTempCreditLimitVOImpl() {
    }
    
    public void initQuery(String acctId, String acctProfileId,String acctProfileAmtId)
          {
              this.clearCache();
           Number xAcctId = new Number(Integer.parseInt(acctId));
           
              
            Number xAcctProfileId = new Number(Integer.parseInt(acctProfileId));
              Number xAcctProfileAmtId = new Number(Integer.parseInt(acctProfileAmtId));
              
            this.setWhereClauseParams(null);
          
            this.setWhereClauseParam(0,xAcctId);
            this.setWhereClauseParam(1,xAcctProfileId);
            this.setWhereClauseParam(2,xAcctProfileAmtId);
            this.executeQuery();
          }
}
