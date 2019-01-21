package od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.poplist.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;

import oracle.jbo.domain.Number;
import oracle.jbo.server.AttributeDefImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class ODEBillDynSplitFieldsVORowImpl extends OAViewRowImpl {
    public static final int CODE = 0;
    public static final int MEANING = 1;
    public static final int CUSTDOCID = 2;
    public static final int TAB = 3;

    /**This is the default constructor (do not remove)
     */
    public ODEBillDynSplitFieldsVORowImpl() {
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
        case CUSTDOCID:
            return getCustDocId();
        case TAB:
            return getTab();
        default:
            return super.getAttrInvokeAccessor(index, attrDef);
        }
    }

    /**setAttrInvokeAccessor: generated method. Do not modify.
     */
    protected void setAttrInvokeAccessor(int index, Object value, 
                                         AttributeDefImpl attrDef) throws Exception {
        switch (index) {
        case CODE:
            setCode((String)value);
            return;
        case MEANING:
            setMeaning((String)value);
            return;
        case CUSTDOCID:
            setCustDocId((Number)value);
            return;
        case TAB:
            setTab((String)value);
            return;
        default:
            super.setAttrInvokeAccessor(index, value, attrDef);
            return;
        }
    }

    /**Gets the attribute value for the calculated attribute CustDocId
     */
    public Number getCustDocId() {
        return (Number) getAttributeInternal(CUSTDOCID);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute CustDocId
     */
    public void setCustDocId(Number value) {
        setAttributeInternal(CUSTDOCID, value);
    }

    /**Gets the attribute value for the calculated attribute Tab
     */
    public String getTab() {
        return (String) getAttributeInternal(TAB);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute Tab
     */
    public void setTab(String value) {
        setAttributeInternal(TAB, value);
    }
}
