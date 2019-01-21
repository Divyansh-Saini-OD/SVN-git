package od.tdmatch.model;

import oracle.jbo.RowSet;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ViewRowImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Thu Jun 29 11:48:43 EDT 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class VendorMootDShipQPanelVORowImpl extends ViewRowImpl {
    /**
     * AttributesEnum: generated enum for identifying attributes and accessors. DO NOT MODIFY.
     */
    protected enum AttributesEnum {
        InvoiceNum,
        InvoiceNumber,
        PONumber,
        InvoiceSource,
        SupplierName,
        SupplierNumber,
        SupplierSite,
        SKUNumber,
        VendorAssistant,
        OrgId,
        InvoiceFrom,
        InvoiceTo,
        DueFrom,
        DueTo,
        FrontDoor,
        NonCode,
        DropShip,
        AllExcepts,
        PricingExcepts,
        QtyExcepts,
        FrtExcepts,
        vendorId,
        vendorSiteId,
        employeeId,
        itemId,
        glDateFrom,
        glDateTo,
        OrgVO1,
        InvoiceSourceLovVO1,
        OrgLovVO1,
        InvoiceNumDLovVO1,
        PoNumberLovVO1,
        SKUDLovVO1,
        SupplierDLovVO1,
        SupplierSiteDLovVO1,
        VendorAssistantDLov1,
        VendorAssistantLOV1,
        InvoiceSourceDLovVO1;
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


    public static final int INVOICENUM = AttributesEnum.InvoiceNum.index();
    public static final int INVOICENUMBER = AttributesEnum.InvoiceNumber.index();
    public static final int PONUMBER = AttributesEnum.PONumber.index();
    public static final int INVOICESOURCE = AttributesEnum.InvoiceSource.index();
    public static final int SUPPLIERNAME = AttributesEnum.SupplierName.index();
    public static final int SUPPLIERNUMBER = AttributesEnum.SupplierNumber.index();
    public static final int SUPPLIERSITE = AttributesEnum.SupplierSite.index();
    public static final int SKUNUMBER = AttributesEnum.SKUNumber.index();
    public static final int VENDORASSISTANT = AttributesEnum.VendorAssistant.index();
    public static final int ORGID = AttributesEnum.OrgId.index();
    public static final int INVOICEFROM = AttributesEnum.InvoiceFrom.index();
    public static final int INVOICETO = AttributesEnum.InvoiceTo.index();
    public static final int DUEFROM = AttributesEnum.DueFrom.index();
    public static final int DUETO = AttributesEnum.DueTo.index();
    public static final int FRONTDOOR = AttributesEnum.FrontDoor.index();
    public static final int NONCODE = AttributesEnum.NonCode.index();
    public static final int DROPSHIP = AttributesEnum.DropShip.index();
    public static final int ALLEXCEPTS = AttributesEnum.AllExcepts.index();
    public static final int PRICINGEXCEPTS = AttributesEnum.PricingExcepts.index();
    public static final int QTYEXCEPTS = AttributesEnum.QtyExcepts.index();
    public static final int FRTEXCEPTS = AttributesEnum.FrtExcepts.index();
    public static final int VENDORID = AttributesEnum.vendorId.index();
    public static final int VENDORSITEID = AttributesEnum.vendorSiteId.index();
    public static final int EMPLOYEEID = AttributesEnum.employeeId.index();
    public static final int ITEMID = AttributesEnum.itemId.index();
    public static final int GLDATEFROM = AttributesEnum.glDateFrom.index();
    public static final int GLDATETO = AttributesEnum.glDateTo.index();
    public static final int ORGVO1 = AttributesEnum.OrgVO1.index();
    public static final int INVOICESOURCELOVVO1 = AttributesEnum.InvoiceSourceLovVO1.index();
    public static final int ORGLOVVO1 = AttributesEnum.OrgLovVO1.index();
    public static final int INVOICENUMDLOVVO1 = AttributesEnum.InvoiceNumDLovVO1.index();
    public static final int PONUMBERLOVVO1 = AttributesEnum.PoNumberLovVO1.index();
    public static final int SKUDLOVVO1 = AttributesEnum.SKUDLovVO1.index();
    public static final int SUPPLIERDLOVVO1 = AttributesEnum.SupplierDLovVO1.index();
    public static final int SUPPLIERSITEDLOVVO1 = AttributesEnum.SupplierSiteDLovVO1.index();
    public static final int VENDORASSISTANTDLOV1 = AttributesEnum.VendorAssistantDLov1.index();
    public static final int VENDORASSISTANTLOV1 = AttributesEnum.VendorAssistantLOV1.index();
    public static final int INVOICESOURCEDLOVVO1 = AttributesEnum.InvoiceSourceDLovVO1.index();

    /**
     * This is the default constructor (do not remove).
     */
    public VendorMootDShipQPanelVORowImpl() {
    }

    /**
     * Gets the attribute value for the calculated attribute InvoiceNum.
     * @return the InvoiceNum
     */
    public String getInvoiceNum() {
        return (String) getAttributeInternal(INVOICENUM);
    }

    /**
     * Gets the attribute value for the calculated attribute InvoiceNumber.
     * @return the InvoiceNumber
     */
    public String getInvoiceNumber() {
        return (String) getAttributeInternal(INVOICENUMBER);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute InvoiceNumber.
     * @param value value to set the  InvoiceNumber
     */
    public void setInvoiceNumber(String value) {
        setAttributeInternal(INVOICENUMBER, value);
    }

    /**
     * Gets the attribute value for the calculated attribute PONumber.
     * @return the PONumber
     */
    public String getPONumber() {
        return (String) getAttributeInternal(PONUMBER);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute PONumber.
     * @param value value to set the  PONumber
     */
    public void setPONumber(String value) {
        setAttributeInternal(PONUMBER, value);
    }

    /**
     * Gets the attribute value for the calculated attribute InvoiceSource.
     * @return the InvoiceSource
     */
    public String getInvoiceSource() {
        return (String) getAttributeInternal(INVOICESOURCE);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute InvoiceSource.
     * @param value value to set the  InvoiceSource
     */
    public void setInvoiceSource(String value) {
        setAttributeInternal(INVOICESOURCE, value);
    }

    /**
     * Gets the attribute value for the calculated attribute SupplierName.
     * @return the SupplierName
     */
    public String getSupplierName() {
        return (String) getAttributeInternal(SUPPLIERNAME);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute SupplierName.
     * @param value value to set the  SupplierName
     */
    public void setSupplierName(String value) {
        setAttributeInternal(SUPPLIERNAME, value);
    }

    /**
     * Gets the attribute value for the calculated attribute SupplierNumber.
     * @return the SupplierNumber
     */
    public String getSupplierNumber() {
        return (String) getAttributeInternal(SUPPLIERNUMBER);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute SupplierNumber.
     * @param value value to set the  SupplierNumber
     */
    public void setSupplierNumber(String value) {
        setAttributeInternal(SUPPLIERNUMBER, value);
    }

    /**
     * Gets the attribute value for the calculated attribute SupplierSite.
     * @return the SupplierSite
     */
    public String getSupplierSite() {
        return (String) getAttributeInternal(SUPPLIERSITE);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute SupplierSite.
     * @param value value to set the  SupplierSite
     */
    public void setSupplierSite(String value) {
        setAttributeInternal(SUPPLIERSITE, value);
    }

    /**
     * Gets the attribute value for the calculated attribute SKUNumber.
     * @return the SKUNumber
     */
    public String getSKUNumber() {
        return (String) getAttributeInternal(SKUNUMBER);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute SKUNumber.
     * @param value value to set the  SKUNumber
     */
    public void setSKUNumber(String value) {
        setAttributeInternal(SKUNUMBER, value);
    }

    /**
     * Gets the attribute value for the calculated attribute VendorAssistant.
     * @return the VendorAssistant
     */
    public String getVendorAssistant() {
        return (String) getAttributeInternal(VENDORASSISTANT);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute VendorAssistant.
     * @param value value to set the  VendorAssistant
     */
    public void setVendorAssistant(String value) {
        setAttributeInternal(VENDORASSISTANT, value);
    }

    /**
     * Gets the attribute value for the calculated attribute OrgId.
     * @return the OrgId
     */
    public Number getOrgId() {
        return (Number) getAttributeInternal(ORGID);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute OrgId.
     * @param value value to set the  OrgId
     */
    public void setOrgId(Number value) {
        setAttributeInternal(ORGID, value);
    }

    /**
     * Gets the attribute value for the calculated attribute InvoiceFrom.
     * @return the InvoiceFrom
     */
    public Date getInvoiceFrom() {
        return (Date) getAttributeInternal(INVOICEFROM);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute InvoiceFrom.
     * @param value value to set the  InvoiceFrom
     */
    public void setInvoiceFrom(Date value) {
        setAttributeInternal(INVOICEFROM, value);
    }

    /**
     * Gets the attribute value for the calculated attribute InvoiceTo.
     * @return the InvoiceTo
     */
    public Date getInvoiceTo() {
        return (Date) getAttributeInternal(INVOICETO);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute InvoiceTo.
     * @param value value to set the  InvoiceTo
     */
    public void setInvoiceTo(Date value) {
        setAttributeInternal(INVOICETO, value);
    }

    /**
     * Gets the attribute value for the calculated attribute DueFrom.
     * @return the DueFrom
     */
    public Date getDueFrom() {
        return (Date) getAttributeInternal(DUEFROM);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute DueFrom.
     * @param value value to set the  DueFrom
     */
    public void setDueFrom(Date value) {
        setAttributeInternal(DUEFROM, value);
    }

    /**
     * Gets the attribute value for the calculated attribute DueTo.
     * @return the DueTo
     */
    public Date getDueTo() {
        return (Date) getAttributeInternal(DUETO);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute DueTo.
     * @param value value to set the  DueTo
     */
    public void setDueTo(Date value) {
        setAttributeInternal(DUETO, value);
    }

    /**
     * Gets the attribute value for the calculated attribute FrontDoor.
     * @return the FrontDoor
     */
    public String getFrontDoor() {
        return (String) getAttributeInternal(FRONTDOOR);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute FrontDoor.
     * @param value value to set the  FrontDoor
     */
    public void setFrontDoor(String value) {
        setAttributeInternal(FRONTDOOR, value);
    }

    /**
     * Gets the attribute value for the calculated attribute NonCode.
     * @return the NonCode
     */
    public String getNonCode() {
        return (String) getAttributeInternal(NONCODE);
    }


    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute NonCode.
     * @param value value to set the  NonCode
     */
    public void setNonCode(String value) {
        setAttributeInternal(NONCODE, value);
    }

    /**
     * Gets the attribute value for the calculated attribute DropShip.
     * @return the DropShip
     */
    public String getDropShip() {
        return (String) getAttributeInternal(DROPSHIP);
    }


    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute DropShip.
     * @param value value to set the  DropShip
     */
    public void setDropShip(String value) {
        setAttributeInternal(DROPSHIP, value);
    }

    /**
     * Gets the attribute value for the calculated attribute AllExcepts.
     * @return the AllExcepts
     */
    public String getAllExcepts() {
        return (String) getAttributeInternal(ALLEXCEPTS);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute AllExcepts.
     * @param value value to set the  AllExcepts
     */
    public void setAllExcepts(String value) {
        setAttributeInternal(ALLEXCEPTS, value);
    }

    /**
     * Gets the attribute value for the calculated attribute PricingExcepts.
     * @return the PricingExcepts
     */
    public String getPricingExcepts() {
        return (String) getAttributeInternal(PRICINGEXCEPTS);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute PricingExcepts.
     * @param value value to set the  PricingExcepts
     */
    public void setPricingExcepts(String value) {
        setAttributeInternal(PRICINGEXCEPTS, value);
    }

    /**
     * Gets the attribute value for the calculated attribute QtyExcepts.
     * @return the QtyExcepts
     */
    public String getQtyExcepts() {
        return (String) getAttributeInternal(QTYEXCEPTS);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute QtyExcepts.
     * @param value value to set the  QtyExcepts
     */
    public void setQtyExcepts(String value) {
        setAttributeInternal(QTYEXCEPTS, value);
    }

    /**
     * Gets the attribute value for the calculated attribute FrtExcepts.
     * @return the FrtExcepts
     */
    public String getFrtExcepts() {
        return (String) getAttributeInternal(FRTEXCEPTS);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute FrtExcepts.
     * @param value value to set the  FrtExcepts
     */
    public void setFrtExcepts(String value) {
        setAttributeInternal(FRTEXCEPTS, value);
    }

    /**
     * Gets the attribute value for the calculated attribute vendorId.
     * @return the vendorId
     */
    public Number getvendorId() {
        return (Number) getAttributeInternal(VENDORID);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute vendorId.
     * @param value value to set the  vendorId
     */
    public void setvendorId(Number value) {
        setAttributeInternal(VENDORID, value);
    }

    /**
     * Gets the attribute value for the calculated attribute vendorSiteId.
     * @return the vendorSiteId
     */
    public Number getvendorSiteId() {
        return (Number) getAttributeInternal(VENDORSITEID);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute vendorSiteId.
     * @param value value to set the  vendorSiteId
     */
    public void setvendorSiteId(Number value) {
        setAttributeInternal(VENDORSITEID, value);
    }

    /**
     * Gets the attribute value for the calculated attribute employeeId.
     * @return the employeeId
     */
    public String getemployeeId() {
        return (String) getAttributeInternal(EMPLOYEEID);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute employeeId.
     * @param value value to set the  employeeId
     */
    public void setemployeeId(String value) {
        setAttributeInternal(EMPLOYEEID, value);
    }

    /**
     * Gets the attribute value for the calculated attribute itemId.
     * @return the itemId
     */
    public Number getitemId() {
        return (Number) getAttributeInternal(ITEMID);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute itemId.
     * @param value value to set the  itemId
     */
    public void setitemId(Number value) {
        setAttributeInternal(ITEMID, value);
    }

    /**
     * Gets the attribute value for the calculated attribute glDateFrom.
     * @return the glDateFrom
     */
    public Date getglDateFrom() {
        return (Date) getAttributeInternal(GLDATEFROM);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute glDateFrom.
     * @param value value to set the  glDateFrom
     */
    public void setglDateFrom(Date value) {
        setAttributeInternal(GLDATEFROM, value);
    }

    /**
     * Gets the attribute value for the calculated attribute glDateTo.
     * @return the glDateTo
     */
    public Date getglDateTo() {
        return (Date) getAttributeInternal(GLDATETO);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute glDateTo.
     * @param value value to set the  glDateTo
     */
    public void setglDateTo(Date value) {
        setAttributeInternal(GLDATETO, value);
    }

    /**
     * Gets the view accessor <code>RowSet</code> OrgVO1.
     */
    public RowSet getOrgVO1() {
        return (RowSet) getAttributeInternal(ORGVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> InvoiceSourceLovVO1.
     */
    public RowSet getInvoiceSourceLovVO1() {
        return (RowSet) getAttributeInternal(INVOICESOURCELOVVO1);
    }


    /**
     * Gets the view accessor <code>RowSet</code> OrgLovVO1.
     */
    public RowSet getOrgLovVO1() {
        return (RowSet) getAttributeInternal(ORGLOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> InvoiceNumDLovVO1.
     */
    public RowSet getInvoiceNumDLovVO1() {
        return (RowSet) getAttributeInternal(INVOICENUMDLOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> PoNumberLovVO1.
     */
    public RowSet getPoNumberLovVO1() {
        return (RowSet) getAttributeInternal(PONUMBERLOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> SKUDLovVO1.
     */
    public RowSet getSKUDLovVO1() {
        return (RowSet) getAttributeInternal(SKUDLOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> SupplierDLovVO1.
     */
    public RowSet getSupplierDLovVO1() {
        return (RowSet) getAttributeInternal(SUPPLIERDLOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> SupplierSiteDLovVO1.
     */
    public RowSet getSupplierSiteDLovVO1() {
        return (RowSet) getAttributeInternal(SUPPLIERSITEDLOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> VendorAssistantDLov1.
     */
    public RowSet getVendorAssistantDLov1() {
        return (RowSet) getAttributeInternal(VENDORASSISTANTDLOV1);
    }


    /**
     * Gets the view accessor <code>RowSet</code> VendorAssistantLOV1.
     */
    public RowSet getVendorAssistantLOV1() {
        return (RowSet) getAttributeInternal(VENDORASSISTANTLOV1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> InvoiceSourceDLovVO1.
     */
    public RowSet getInvoiceSourceDLovVO1() {
        return (RowSet) getAttributeInternal(INVOICESOURCEDLOVVO1);
    }


}

