package od.tdmatch.model;

import java.util.HashMap;

import oracle.jbo.RowSet;
import oracle.jbo.server.ProgrammaticViewRowImpl;
import oracle.jbo.server.ViewAttributeDefImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Thu May 25 14:27:31 EDT 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class GeneralInquiryUpdateVORowImpl extends ProgrammaticViewRowImpl {
    /**
     * createRowData - for custom java data source support.
     * Overridden to initialize the dataProvier for newly created row.
     * Used for updateable View Objects.
     */
    public Object createRowData(HashMap attrNameValueMap) {
       // Object value = super.createRowData(attrNameValueMap);
        attrNameValueMap.put("fromVA", null);   
             attrNameValueMap.put("toVA", null);   
             attrNameValueMap.put("vendorid", "ABC");   
             return attrNameValueMap;   
       // return value;
    }

    /**
     * convertToSourceType - for custom java data source support.
     * Overridden to provide custom implementation for conversions of a value
     * from attribute java type to datasource column/field type.
     * Not required in most cases.
     */
    public Object convertToSourceType(ViewAttributeDefImpl attrDef, String sourceType, Object val) {
        Object value = super.convertToSourceType(attrDef, sourceType, val);
        return value;
    }

    /**
     * convertToAttributeType - for custom java data source support.
     * Overridden to provide custom implementation for conversions of a value
     *  from datasource/column field type to attribute java type.
     * Not required in most cases.
     */
    public Object convertToAttributeType(ViewAttributeDefImpl attrDef, Class javaTypeClass, Object val) {
        Object value = super.convertToAttributeType(attrDef, javaTypeClass, val);
        return value;
    }

    /**
     * AttributesEnum: generated enum for identifying attributes and accessors. DO NOT MODIFY.
     */
    protected enum AttributesEnum {
        fromVA,
        toVA,
        vendorid,
        VendorAssistantLOV1;
        private static AttributesEnum[] vals = null;
        private static final int firstIndex = 0;

        protected int index() {
            return AttributesEnum.firstIndex() + ordinal();
        }

        protected static final int firstIndex() {
            return firstIndex;
        }

        protected static int count() {
            return AttributesEnum.firstIndex() + AttributesEnum.staticValues().length;
        }

        protected static final AttributesEnum[] staticValues() {
            if (vals == null) {
                vals = AttributesEnum.values();
            }
            return vals;
        }
    }


    public static final int FROMVA = AttributesEnum.fromVA.index();
    public static final int TOVA = AttributesEnum.toVA.index();
    public static final int VENDORID = AttributesEnum.vendorid.index();
    public static final int VENDORASSISTANTLOV1 = AttributesEnum.VendorAssistantLOV1.index();

    /**
     * This is the default constructor (do not remove).
     */
    public GeneralInquiryUpdateVORowImpl() {
    }

    /**
     * Gets the attribute value for the calculated attribute fromVA.
     * @return the fromVA
     */
    public String getfromVA() {
        return (String) getAttributeInternal(FROMVA);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute fromVA.
     * @param value value to set the  fromVA
     */
    public void setfromVA(String value) {
        setAttributeInternal(FROMVA, value);
    }

    /**
     * Gets the attribute value for the calculated attribute toVA.
     * @return the toVA
     */
    public String gettoVA() {
        return (String) getAttributeInternal(TOVA);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute toVA.
     * @param value value to set the  toVA
     */
    public void settoVA(String value) {
        setAttributeInternal(TOVA, value);
    }

    /**
     * Gets the attribute value for the calculated attribute vendorid.
     * @return the vendorid
     */
    public String getvendorid() {
        return (String) getAttributeInternal(VENDORID);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute vendorid.
     * @param value value to set the  vendorid
     */
    public void setvendorid(String value) {
        setAttributeInternal(VENDORID, value);
    }

    /**
     * Gets the view accessor <code>RowSet</code> VendorAssistantLOV1.
     */
    public RowSet getVendorAssistantLOV1() {
        return (RowSet) getAttributeInternal(VENDORASSISTANTLOV1);
    }


}

