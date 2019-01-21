package od.oracle.apps.icx.por.reqmgmt.server;

import oracle.apps.icx.por.reqmgmt.server.ReqDetailsVORowImpl;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.AttributeDefImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class OD_ReqDetailsVORowImpl extends ReqDetailsVORowImpl {
    public static final int MAXATTRCONST = oracle.jbo.server.ViewDefImpl.getMaxAttrConst("oracle.apps.icx.por.reqmgmt.server.ReqDetailsVO");
    public static final int ITEMNAME = MAXATTRCONST;

    /**This is the default constructor (do not remove)
     */
    public OD_ReqDetailsVORowImpl() {
    }

    /**Gets the attribute value for the calculated attribute ItemName
     */
    public String getItemName() {
        return (String) getAttributeInternal(ITEMNAME);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute ItemName
     */
    public void setItemName(String value) {
        setAttributeInternal(ITEMNAME, value);
    }

    /**getAttrInvokeAccessor: generated method. Do not modify.
     */
    protected Object getAttrInvokeAccessor(int index, 
                                           AttributeDefImpl attrDef) throws Exception {
        if (index == ITEMNAME) {
            return getItemName();
        }
        return super.getAttrInvokeAccessor(index, attrDef);
    }

    /**setAttrInvokeAccessor: generated method. Do not modify.
     */
    protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception {super.setAttrInvokeAccessor(index, value, attrDef);
        return;
    }
}
