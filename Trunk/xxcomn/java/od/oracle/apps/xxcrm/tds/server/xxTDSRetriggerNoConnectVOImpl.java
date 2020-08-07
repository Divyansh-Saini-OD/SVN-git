package od.oracle.apps.xxcrm.tds.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class xxTDSRetriggerNoConnectVOImpl extends OAViewObjectImpl {
    /**This is the default constructor (do not remove)
     */
    public xxTDSRetriggerNoConnectVOImpl() {
    }
    
    public void executeNoConnectQuery(String dateFrom){
    
        setWhereClauseParams(null);
        setWhereClauseParam(0,dateFrom);
       
        executeQuery();
    }
}
