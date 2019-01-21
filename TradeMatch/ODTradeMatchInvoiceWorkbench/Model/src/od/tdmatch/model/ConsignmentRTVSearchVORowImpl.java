package od.tdmatch.model;

import oracle.jbo.RowSet;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ViewRowImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Mon Oct 30 23:03:33 IST 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class ConsignmentRTVSearchVORowImpl extends ViewRowImpl {
    /**
     * AttributesEnum: generated enum for identifying attributes and accessors. DO NOT MODIFY.
     */
    protected enum AttributesEnum {
        Suppliername,
        Suppliersiteno,
        Sku,
        Rtvno,
        Transactiondatefrom,
        Transactiondateto,
        Transactionperiodfrom,
        Transactionperiodto,
        Rgano,
        Location,
        Orgid,
        OrgIdValue,
        VendorIdValue,
        VendorSiteIdValue,
        ItemIdValue,
        LocationIdValue,
        ConsignmentSupLovVO1,
        ConsignmentSupSiteLovVO1,
        ConsignmentSKULovVO1,
        ConsignmentRTVLovVO1,
        ConsignmentRGALovVO1,
        ConsignmentLocLovVO1,
        OrgVO1,
        PeriodFromLOV1,
        PeriodToLOV1;
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


    public static final int SUPPLIERNAME = AttributesEnum.Suppliername.index();
    public static final int SUPPLIERSITENO = AttributesEnum.Suppliersiteno.index();
    public static final int SKU = AttributesEnum.Sku.index();
    public static final int RTVNO = AttributesEnum.Rtvno.index();
    public static final int TRANSACTIONDATEFROM = AttributesEnum.Transactiondatefrom.index();
    public static final int TRANSACTIONDATETO = AttributesEnum.Transactiondateto.index();
    public static final int TRANSACTIONPERIODFROM = AttributesEnum.Transactionperiodfrom.index();
    public static final int TRANSACTIONPERIODTO = AttributesEnum.Transactionperiodto.index();
    public static final int RGANO = AttributesEnum.Rgano.index();
    public static final int LOCATION = AttributesEnum.Location.index();
    public static final int ORGID = AttributesEnum.Orgid.index();
    public static final int ORGIDVALUE = AttributesEnum.OrgIdValue.index();
    public static final int VENDORIDVALUE = AttributesEnum.VendorIdValue.index();
    public static final int VENDORSITEIDVALUE = AttributesEnum.VendorSiteIdValue.index();
    public static final int ITEMIDVALUE = AttributesEnum.ItemIdValue.index();
    public static final int LOCATIONIDVALUE = AttributesEnum.LocationIdValue.index();
    public static final int CONSIGNMENTSUPLOVVO1 = AttributesEnum.ConsignmentSupLovVO1.index();
    public static final int CONSIGNMENTSUPSITELOVVO1 = AttributesEnum.ConsignmentSupSiteLovVO1.index();
    public static final int CONSIGNMENTSKULOVVO1 = AttributesEnum.ConsignmentSKULovVO1.index();
    public static final int CONSIGNMENTRTVLOVVO1 = AttributesEnum.ConsignmentRTVLovVO1.index();
    public static final int CONSIGNMENTRGALOVVO1 = AttributesEnum.ConsignmentRGALovVO1.index();
    public static final int CONSIGNMENTLOCLOVVO1 = AttributesEnum.ConsignmentLocLovVO1.index();
    public static final int ORGVO1 = AttributesEnum.OrgVO1.index();
    public static final int PERIODFROMLOV1 = AttributesEnum.PeriodFromLOV1.index();
    public static final int PERIODTOLOV1 = AttributesEnum.PeriodToLOV1.index();

    /**
     * This is the default constructor (do not remove).
     */
    public ConsignmentRTVSearchVORowImpl() {
    }

    /**
     * Gets the attribute value for the calculated attribute Suppliername.
     * @return the Suppliername
     */
    public String getSuppliername() {
        return (String) getAttributeInternal(SUPPLIERNAME);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Suppliername.
     * @param value value to set the  Suppliername
     */
    public void setSuppliername(String value) {
        setAttributeInternal(SUPPLIERNAME, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Suppliersiteno.
     * @return the Suppliersiteno
     */
    public String getSuppliersiteno() {
        return (String) getAttributeInternal(SUPPLIERSITENO);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Suppliersiteno.
     * @param value value to set the  Suppliersiteno
     */
    public void setSuppliersiteno(String value) {
        setAttributeInternal(SUPPLIERSITENO, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Sku.
     * @return the Sku
     */
    public String getSku() {
        return (String) getAttributeInternal(SKU);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Sku.
     * @param value value to set the  Sku
     */
    public void setSku(String value) {
        setAttributeInternal(SKU, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Rtvno.
     * @return the Rtvno
     */
    public String getRtvno() {
        return (String) getAttributeInternal(RTVNO);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Rtvno.
     * @param value value to set the  Rtvno
     */
    public void setRtvno(String value) {
        setAttributeInternal(RTVNO, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Transactiondatefrom.
     * @return the Transactiondatefrom
     */
    public Date getTransactiondatefrom() {
        return (Date) getAttributeInternal(TRANSACTIONDATEFROM);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Transactiondatefrom.
     * @param value value to set the  Transactiondatefrom
     */
    public void setTransactiondatefrom(Date value) {
        setAttributeInternal(TRANSACTIONDATEFROM, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Transactiondateto.
     * @return the Transactiondateto
     */
    public Date getTransactiondateto() {
        return (Date) getAttributeInternal(TRANSACTIONDATETO);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Transactiondateto.
     * @param value value to set the  Transactiondateto
     */
    public void setTransactiondateto(Date value) {
        setAttributeInternal(TRANSACTIONDATETO, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Transactionperiodfrom.
     * @return the Transactionperiodfrom
     */
    public String getTransactionperiodfrom() {
        return (String) getAttributeInternal(TRANSACTIONPERIODFROM);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Transactionperiodfrom.
     * @param value value to set the  Transactionperiodfrom
     */
    public void setTransactionperiodfrom(String value) {
        setAttributeInternal(TRANSACTIONPERIODFROM, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Transactionperiodto.
     * @return the Transactionperiodto
     */
    public String getTransactionperiodto() {
        return (String) getAttributeInternal(TRANSACTIONPERIODTO);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Transactionperiodto.
     * @param value value to set the  Transactionperiodto
     */
    public void setTransactionperiodto(String value) {
        setAttributeInternal(TRANSACTIONPERIODTO, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Rgano.
     * @return the Rgano
     */
    public String getRgano() {
        return (String) getAttributeInternal(RGANO);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Rgano.
     * @param value value to set the  Rgano
     */
    public void setRgano(String value) {
        setAttributeInternal(RGANO, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Location.
     * @return the Location
     */
    public String getLocation() {
        return (String) getAttributeInternal(LOCATION);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Location.
     * @param value value to set the  Location
     */
    public void setLocation(String value) {
        setAttributeInternal(LOCATION, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Orgid.
     * @return the Orgid
     */
    public String getOrgid() {
        /*return (String) getAttributeInternal(ORGID);*/
        if( getAttributeInternal(ORGID)==null){
            return"OU_US";
        
        }else{
                return (String) getAttributeInternal(ORGID);
            }
    }
    
    
    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Orgid.
     * @param value value to set the  Orgid
     */
    public void setOrgid(String value) {
        setAttributeInternal(ORGID, value);
    }

    /**
     * Gets the attribute value for the calculated attribute OrgIdValue.
     * @return the OrgIdValue
     */
    public Number getOrgIdValue() {
        return (Number) getAttributeInternal(ORGIDVALUE);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute OrgIdValue.
     * @param value value to set the  OrgIdValue
     */
    public void setOrgIdValue(Number value) {
        setAttributeInternal(ORGIDVALUE, value);
    }

    /**
     * Gets the attribute value for the calculated attribute VendorIdValue.
     * @return the VendorIdValue
     */
    public Number getVendorIdValue() {
        return (Number) getAttributeInternal(VENDORIDVALUE);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute VendorIdValue.
     * @param value value to set the  VendorIdValue
     */
    public void setVendorIdValue(Number value) {
        setAttributeInternal(VENDORIDVALUE, value);
    }

    /**
     * Gets the attribute value for the calculated attribute VendorSiteIdValue.
     * @return the VendorSiteIdValue
     */
    public Number getVendorSiteIdValue() {
        return (Number) getAttributeInternal(VENDORSITEIDVALUE);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute VendorSiteIdValue.
     * @param value value to set the  VendorSiteIdValue
     */
    public void setVendorSiteIdValue(Number value) {
        setAttributeInternal(VENDORSITEIDVALUE, value);
    }

    /**
     * Gets the attribute value for the calculated attribute ItemIdValue.
     * @return the ItemIdValue
     */
    public Number getItemIdValue() {
        return (Number) getAttributeInternal(ITEMIDVALUE);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute ItemIdValue.
     * @param value value to set the  ItemIdValue
     */
    public void setItemIdValue(Number value) {
        setAttributeInternal(ITEMIDVALUE, value);
    }

    /**
     * Gets the attribute value for the calculated attribute LocationIdValue.
     * @return the LocationIdValue
     */
    public Number getLocationIdValue() {
        return (Number) getAttributeInternal(LOCATIONIDVALUE);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute LocationIdValue.
     * @param value value to set the  LocationIdValue
     */
    public void setLocationIdValue(Number value) {
        setAttributeInternal(LOCATIONIDVALUE, value);
    }

    /**
     * Gets the view accessor <code>RowSet</code> ConsignmentSupLovVO1.
     */
    public RowSet getConsignmentSupLovVO1() {
        return (RowSet) getAttributeInternal(CONSIGNMENTSUPLOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> ConsignmentSupSiteLovVO1.
     */
    public RowSet getConsignmentSupSiteLovVO1() {
        return (RowSet) getAttributeInternal(CONSIGNMENTSUPSITELOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> ConsignmentSKULovVO1.
     */
    public RowSet getConsignmentSKULovVO1() {
        return (RowSet) getAttributeInternal(CONSIGNMENTSKULOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> ConsignmentRTVLovVO1.
     */
    public RowSet getConsignmentRTVLovVO1() {
        return (RowSet) getAttributeInternal(CONSIGNMENTRTVLOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> ConsignmentRGALovVO1.
     */
    public RowSet getConsignmentRGALovVO1() {
        return (RowSet) getAttributeInternal(CONSIGNMENTRGALOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> ConsignmentLocLovVO1.
     */
    public RowSet getConsignmentLocLovVO1() {
        return (RowSet) getAttributeInternal(CONSIGNMENTLOCLOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> OrgVO1.
     */
    public RowSet getOrgVO1() {
        return (RowSet) getAttributeInternal(ORGVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> PeriodFromLOV1.
     */
    public RowSet getPeriodFromLOV1() {
        return (RowSet) getAttributeInternal(PERIODFROMLOV1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> PeriodToLOV1.
     */
    public RowSet getPeriodToLOV1() {
        return (RowSet) getAttributeInternal(PERIODTOLOV1);
    }
}

