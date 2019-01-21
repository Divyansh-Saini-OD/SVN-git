package od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;

import oracle.jbo.server.AttributeDefImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class ODEBillSwitcherVORowImpl extends OAViewRowImpl {
    public static final int CODE = 0;
    public static final int MEANING = 1;

    /**This is the default constructor (do not remove)
     */
    public ODEBillSwitcherVORowImpl() {
    }

    /**Gets the attribute value for the calculated attribute Code
     */
    public String getCode() {
        return (String) getAttributeInternal(CODE);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute Code
     */
    public void setCode(String value) {
        setAttributeInternal(CODE, value);
    }

    /**Gets the attribute value for the calculated attribute Meaning
     */
    public String getMeaning() {
        return (String) getAttributeInternal(MEANING);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute Meaning
     */
    public void setMeaning(String value) {
        setAttributeInternal(MEANING, value);
    }

    /**getAttrInvokeAccessor: generated method. Do not modify.
     */
    protected Object getAttrInvokeAccessor(int index, 
                                           AttributeDefImpl attrDef) throws Exception {
        switch (index) {
        case CODE:
            return getCode();
        case MEANING:
            return getMeaning();
        default:
            return super.getAttrInvokeAccessor(index, attrDef);
        }
    }

    /**setAttrInvokeAccessor: generated method. Do not modify.
     */
    protected void setAttrInvokeAccessor(int index, Object value, 
                                         AttributeDefImpl attrDef) throws Exception {
        switch (index) {
        default:
            super.setAttrInvokeAccessor(index, value, attrDef);
            return;
        }
    }
}
