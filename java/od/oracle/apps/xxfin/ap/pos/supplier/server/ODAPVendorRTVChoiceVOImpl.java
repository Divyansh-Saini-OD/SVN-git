/*===========================================================================+
 |  OFFICE DEPOT PROJECT SIMPLIFY - IT ERP - R12 UPGRADE                     |
 |  Rice ID: E3064                                                           |
 |  Rice Description: Supplier Site Additional Information                   |
 +===========================================================================+
 |  HISTORY                                                                  |
 |  09/06/2013  Sreedhar Mohan  - Created                                    |
 +===========================================================================*/
package od.oracle.apps.xxfin.ap.pos.supplier.server;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class ODAPVendorRTVChoiceVOImpl extends OAViewObjectImpl {
    /**This is the default constructor (do not remove)
     */
    public ODAPVendorRTVChoiceVOImpl() {
    }
    
    public void executeQuery() {
        OADBTransaction oadbtransaction = (OADBTransaction)getDBTransaction();
        setWhereClause(" vendor_id = "+ oadbtransaction.getValue("vendorID").toString());
        super.executeQuery();
    }    
}
