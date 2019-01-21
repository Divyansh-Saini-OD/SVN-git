package od.tdmatch.model.reports.vo;

import oracle.jbo.RowSet;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ViewRowImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Tue Jul 17 06:14:53 EDT 2018
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class XxApDropDeducNonDedInqSearchVORowImpl extends ViewRowImpl {
    /**
     * AttributesEnum: generated enum for identifying attributes and accessors. DO NOT MODIFY.
     */
    protected enum AttributesEnum {
        Reportoption,
        Suppliername,
        Suppliernum,
        Suppliersiteno,
        Invoicenum,
        Reasoncode,
        Invdaterangfrom,
        Invdaterangto,
        Gldaterangfrom,
        Gldaterangto,
        Orgid,
        SupplierId,
        SupplierSiteId,
        OrgIdVal,
        DateType,
        InvoiceId,
        SupplierDLovVO1,
        SupplierDLovVO2,
        SupplierSiteDLovVO1,
        ReasonCodeRCLovVO1,
        DateTypeLOV1,
        ReportOptionSumDtlLOV1,
        InvoiceNumberLOV1,
        NonDropReasonCodeLOV1,
        OrgLovVO1;
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


    public static final int REPORTOPTION = AttributesEnum.Reportoption.index();
    public static final int SUPPLIERNAME = AttributesEnum.Suppliername.index();
    public static final int SUPPLIERNUM = AttributesEnum.Suppliernum.index();
    public static final int SUPPLIERSITENO = AttributesEnum.Suppliersiteno.index();
    public static final int INVOICENUM = AttributesEnum.Invoicenum.index();
    public static final int REASONCODE = AttributesEnum.Reasoncode.index();
    public static final int INVDATERANGFROM = AttributesEnum.Invdaterangfrom.index();
    public static final int INVDATERANGTO = AttributesEnum.Invdaterangto.index();
    public static final int GLDATERANGFROM = AttributesEnum.Gldaterangfrom.index();
    public static final int GLDATERANGTO = AttributesEnum.Gldaterangto.index();
    public static final int ORGID = AttributesEnum.Orgid.index();
    public static final int SUPPLIERID = AttributesEnum.SupplierId.index();
    public static final int SUPPLIERSITEID = AttributesEnum.SupplierSiteId.index();
    public static final int ORGIDVAL = AttributesEnum.OrgIdVal.index();
    public static final int DATETYPE = AttributesEnum.DateType.index();
    public static final int INVOICEID = AttributesEnum.InvoiceId.index();
    public static final int SUPPLIERDLOVVO1 = AttributesEnum.SupplierDLovVO1.index();
    public static final int SUPPLIERDLOVVO2 = AttributesEnum.SupplierDLovVO2.index();
    public static final int SUPPLIERSITEDLOVVO1 = AttributesEnum.SupplierSiteDLovVO1.index();
    public static final int REASONCODERCLOVVO1 = AttributesEnum.ReasonCodeRCLovVO1.index();
    public static final int DATETYPELOV1 = AttributesEnum.DateTypeLOV1.index();
    public static final int REPORTOPTIONSUMDTLLOV1 = AttributesEnum.ReportOptionSumDtlLOV1.index();
    public static final int INVOICENUMBERLOV1 = AttributesEnum.InvoiceNumberLOV1.index();
    public static final int NONDROPREASONCODELOV1 = AttributesEnum.NonDropReasonCodeLOV1.index();
    public static final int ORGLOVVO1 = AttributesEnum.OrgLovVO1.index();

    /**
     * This is the default constructor (do not remove).
     */
    public XxApDropDeducNonDedInqSearchVORowImpl() {
    }

    /**
     * Gets the attribute value for the calculated attribute Reportoption.
     * @return the Reportoption
     */
    public String getReportoption() {
        return (String) getAttributeInternal(REPORTOPTION);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Reportoption.
     * @param value value to set the  Reportoption
     */
    public void setReportoption(String value) {
        setAttributeInternal(REPORTOPTION, value);
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
     * Gets the attribute value for the calculated attribute Suppliernum.
     * @return the Suppliernum
     */
    public String getSuppliernum() {
        return (String) getAttributeInternal(SUPPLIERNUM);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Suppliernum.
     * @param value value to set the  Suppliernum
     */
    public void setSuppliernum(String value) {
        setAttributeInternal(SUPPLIERNUM, value);
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
     * Gets the attribute value for the calculated attribute Invoicenum.
     * @return the Invoicenum
     */
    public String getInvoicenum() {
        return (String) getAttributeInternal(INVOICENUM);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Invoicenum.
     * @param value value to set the  Invoicenum
     */
    public void setInvoicenum(String value) {
        setAttributeInternal(INVOICENUM, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Reasoncode.
     * @return the Reasoncode
     */
    public String getReasoncode() {
        return (String) getAttributeInternal(REASONCODE);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Reasoncode.
     * @param value value to set the  Reasoncode
     */
    public void setReasoncode(String value) {
        setAttributeInternal(REASONCODE, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Invdaterangfrom.
     * @return the Invdaterangfrom
     */
    public Date getInvdaterangfrom() {
        return (Date) getAttributeInternal(INVDATERANGFROM);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Invdaterangfrom.
     * @param value value to set the  Invdaterangfrom
     */
    public void setInvdaterangfrom(Date value) {
        setAttributeInternal(INVDATERANGFROM, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Invdaterangto.
     * @return the Invdaterangto
     */
    public Date getInvdaterangto() {
        return (Date) getAttributeInternal(INVDATERANGTO);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Invdaterangto.
     * @param value value to set the  Invdaterangto
     */
    public void setInvdaterangto(Date value) {
        setAttributeInternal(INVDATERANGTO, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Gldaterangfrom.
     * @return the Gldaterangfrom
     */
    public Date getGldaterangfrom() {
        return (Date) getAttributeInternal(GLDATERANGFROM);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Gldaterangfrom.
     * @param value value to set the  Gldaterangfrom
     */
    public void setGldaterangfrom(Date value) {
        setAttributeInternal(GLDATERANGFROM, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Gldaterangto.
     * @return the Gldaterangto
     */
    public Date getGldaterangto() {
        return (Date) getAttributeInternal(GLDATERANGTO);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Gldaterangto.
     * @param value value to set the  Gldaterangto
     */
    public void setGldaterangto(Date value) {
        setAttributeInternal(GLDATERANGTO, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Orgid.
     * @return the Orgid
     */
    public String getOrgid() {
       
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
     * Gets the attribute value for the calculated attribute SupplierId.
     * @return the SupplierId
     */
    public Number getSupplierId() {
        return (Number) getAttributeInternal(SUPPLIERID);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute SupplierId.
     * @param value value to set the  SupplierId
     */
    public void setSupplierId(Number value) {
        setAttributeInternal(SUPPLIERID, value);
    }

    /**
     * Gets the attribute value for the calculated attribute SupplierSiteId.
     * @return the SupplierSiteId
     */
    public Number getSupplierSiteId() {
        return (Number) getAttributeInternal(SUPPLIERSITEID);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute SupplierSiteId.
     * @param value value to set the  SupplierSiteId
     */
    public void setSupplierSiteId(Number value) {
        setAttributeInternal(SUPPLIERSITEID, value);
    }

    /**
     * Gets the attribute value for the calculated attribute OrgIdVal.
     * @return the OrgIdVal
     */
    public Number getOrgIdVal() {
        return (Number) getAttributeInternal(ORGIDVAL);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute OrgIdVal.
     * @param value value to set the  OrgIdVal
     */
    public void setOrgIdVal(Number value) {
        setAttributeInternal(ORGIDVAL, value);
    }

    /**
     * Gets the attribute value for the calculated attribute DateType.
     * @return the DateType
     */
    public String getDateType() {
        return (String) getAttributeInternal(DATETYPE);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute DateType.
     * @param value value to set the  DateType
     */
    public void setDateType(String value) {
        setAttributeInternal(DATETYPE, value);
    }


    /**
     * Gets the attribute value for the calculated attribute InvoiceId.
     * @return the InvoiceId
     */
    public Number getInvoiceId() {
        return (Number) getAttributeInternal(INVOICEID);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute InvoiceId.
     * @param value value to set the  InvoiceId
     */
    public void setInvoiceId(Number value) {
        setAttributeInternal(INVOICEID, value);
    }

    /**
     * Gets the view accessor <code>RowSet</code> SupplierDLovVO1.
     */
    public RowSet getSupplierDLovVO1() {
        return (RowSet) getAttributeInternal(SUPPLIERDLOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> SupplierDLovVO2.
     */
    public RowSet getSupplierDLovVO2() {
        return (RowSet) getAttributeInternal(SUPPLIERDLOVVO2);
    }

    /**
     * Gets the view accessor <code>RowSet</code> SupplierSiteDLovVO1.
     */
    public RowSet getSupplierSiteDLovVO1() {
        return (RowSet) getAttributeInternal(SUPPLIERSITEDLOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> ReasonCodeRCLovVO1.
     */
    public RowSet getReasonCodeRCLovVO1() {
        return (RowSet) getAttributeInternal(REASONCODERCLOVVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> DateTypeLOV1.
     */
    public RowSet getDateTypeLOV1() {
        return (RowSet) getAttributeInternal(DATETYPELOV1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> ReportOptionSumDtlLOV1.
     */
    public RowSet getReportOptionSumDtlLOV1() {
        return (RowSet) getAttributeInternal(REPORTOPTIONSUMDTLLOV1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> InvoiceNumberLOV1.
     */
    public RowSet getInvoiceNumberLOV1() {
        return (RowSet) getAttributeInternal(INVOICENUMBERLOV1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> NonDropReasonCodeLOV1.
     */
    public RowSet getNonDropReasonCodeLOV1() {
        return (RowSet) getAttributeInternal(NONDROPREASONCODELOV1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> OrgLovVO1.
     */
    public RowSet getOrgLovVO1() {
        return (RowSet) getAttributeInternal(ORGLOVVO1);
    }
}

