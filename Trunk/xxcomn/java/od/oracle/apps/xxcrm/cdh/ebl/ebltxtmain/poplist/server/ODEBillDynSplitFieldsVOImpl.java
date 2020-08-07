package od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.poplist.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class ODEBillDynSplitFieldsVOImpl extends OAViewObjectImpl {
    /**This is the default constructor (do not remove)
     */
    public ODEBillDynSplitFieldsVOImpl() {
    }
    
    public void initQuery(String custDocId)
          {
              this.clearCache();
           Number xcustDocId = new Number(Integer.parseInt(custDocId));
           
              
             this.setWhereClauseParams(null);
          
            this.setWhereClauseParam(0,custDocId);
            this.setMaxFetchSize(-1);
            this.executeQuery();
          }
}
