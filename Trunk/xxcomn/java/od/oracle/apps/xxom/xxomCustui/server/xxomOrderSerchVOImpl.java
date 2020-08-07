package od.oracle.apps.xxom.xxomCustui.server;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class xxomOrderSerchVOImpl extends OAViewObjectImpl {
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public xxomOrderSerchVOImpl()
  {
  }
  
    public void initXxomOrderSerchVO( String sOSRDocRef, String sOrderNumber) {
        OADBTransactionImpl trx = (OADBTransactionImpl)getDBTransaction();
        if ( sOSRDocRef == null || "".equals(sOSRDocRef)) {
            throw new OAException("Please fill in search criteria values in at least one of the following fields: Orig Sys Document Ref. Note that the search criteria values should not begin with a \"%\" or \"_\" for at least one of the listed fields.", OAException.ERROR); 
        } else if (sOrderNumber == null || "".equals(sOrderNumber)) {            
            setQuery(null);
            setWhereClause(null);
            setWhereClauseParams(null);
            
            String strQuery = "SELECT xxomOrderSearchEO.ORDER_NUMBER, \n" + 
            "       xxomOrderSearchEO.HEADER_ID, \n" + 
            "       xxomOrderSearchEO.ORIG_SYS_DOCUMENT_REF,\n" + 
            "       xxomOrderSearchEO.ORDER_SOURCE_ID,\n" + 
            "       xxomOeOrderSourcesEO.NAME        \n" + 
            "FROM OE_ORDER_HEADERS_ALL xxomOrderSearchEO,\n" + 
            "      OE_ORDER_SOURCES xxomOeOrderSourcesEO\n" + 
            "WHERE xxomOrderSearchEO.ORDER_SOURCE_ID = xxomOeOrderSourcesEO.ORDER_SOURCE_ID\n" + 
            "and   xxomOrderSearchEO.ORIG_SYS_DOCUMENT_REF like :1" + "|| '%'  \n" ;
            
            setQuery(strQuery);
            setWhereClauseParam(0,sOSRDocRef);
            
        } else {
            setQuery(null);
            setWhereClause(null);
            setWhereClauseParams(null);
            String strQuery = "SELECT xxomOrderSearchEO.ORDER_NUMBER, \n" + 
            "       xxomOrderSearchEO.HEADER_ID, \n" + 
            "       xxomOrderSearchEO.ORIG_SYS_DOCUMENT_REF,\n" + 
            "       xxomOrderSearchEO.ORDER_SOURCE_ID,\n" + 
            "       xxomOeOrderSourcesEO.NAME        \n" + 
            "FROM OE_ORDER_HEADERS_ALL xxomOrderSearchEO,\n" + 
            "      OE_ORDER_SOURCES xxomOeOrderSourcesEO\n" + 
            "WHERE xxomOrderSearchEO.ORDER_SOURCE_ID = xxomOeOrderSourcesEO.ORDER_SOURCE_ID\n" + 
            "and   xxomOrderSearchEO.ORIG_SYS_DOCUMENT_REF like :1" + "|| '%'  \n" + 
            "and   xxomOrderSearchEO.ORDER_NUMBER = nvl(:2,xxomOrderSearchEO.ORDER_NUMBER)" ;          // Added by shishir     as per defect #30993   
            //"and   xxomOrderSearchEO.ORDER_NUMBER = :2";				                 //  Commented by shishir as per defect #30993			
            
            setQuery(strQuery);
            setWhereClauseParam(0,sOSRDocRef);
            setWhereClauseParam(1,sOrderNumber);            
        }
        System.out.println("##### Query="+getQuery());
                if (trx.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                  trx.writeDiagnostics(this, "Query=" + getQuery(), OAFwkConstants.STATEMENT);
                }
        executeQuery();
        System.out.println("In VO rowcount="+getRowCount());
                if (trx.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                  trx.writeDiagnostics(this, "In VO rowcount="+getRowCount(), OAFwkConstants.STATEMENT);
                }

    }

}