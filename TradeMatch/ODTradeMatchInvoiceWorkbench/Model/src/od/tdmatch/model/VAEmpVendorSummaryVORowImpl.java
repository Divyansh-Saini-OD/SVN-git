package od.tdmatch.model;

import java.math.BigDecimal;

import oracle.jbo.RowSet;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ViewRowImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Wed May 24 07:08:11 EDT 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class VAEmpVendorSummaryVORowImpl extends ViewRowImpl {
    /**
     * AttributesEnum: generated enum for identifying attributes and accessors. DO NOT MODIFY.
     */
    protected enum AttributesEnum {
        OrgId,
        VendorAssistant,
        EmployeeId,
        VendorName,
        Supplier,
        VendorSiteCode,
        Disc,
        TotalInvCount,
        TotalInvAmount,
        TotalLineAmount,
        TotalMootCount,
        TotalMootInvAmount,
        TotalMootLineAmount,
        TotalNrfCount,
        TotalNrfAmount,
        SumInvCount,
        SumInvAmount,
        SumLineAmount,
        SumMootCount,
        SumMootInvAmount,
        SumMootLineAmount,
        SumNrfCount,
        SumNrfAmount,
        VAEmpVendSumTotalVO,
        VAEmpVendorSummaryVO1,
        OrgVO1,
        SupplierLOV1,
        SupplierLOV2,
        SupplierSiteLOV1,
        VendorAssistantLOV1,
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


    public static final int ORGID = AttributesEnum.OrgId.index();
    public static final int VENDORASSISTANT = AttributesEnum.VendorAssistant.index();
    public static final int EMPLOYEEID = AttributesEnum.EmployeeId.index();
    public static final int VENDORNAME = AttributesEnum.VendorName.index();
    public static final int SUPPLIER = AttributesEnum.Supplier.index();
    public static final int VENDORSITECODE = AttributesEnum.VendorSiteCode.index();
    public static final int DISC = AttributesEnum.Disc.index();
    public static final int TOTALINVCOUNT = AttributesEnum.TotalInvCount.index();
    public static final int TOTALINVAMOUNT = AttributesEnum.TotalInvAmount.index();
    public static final int TOTALLINEAMOUNT = AttributesEnum.TotalLineAmount.index();
    public static final int TOTALMOOTCOUNT = AttributesEnum.TotalMootCount.index();
    public static final int TOTALMOOTINVAMOUNT = AttributesEnum.TotalMootInvAmount.index();
    public static final int TOTALMOOTLINEAMOUNT = AttributesEnum.TotalMootLineAmount.index();
    public static final int TOTALNRFCOUNT = AttributesEnum.TotalNrfCount.index();
    public static final int TOTALNRFAMOUNT = AttributesEnum.TotalNrfAmount.index();
    public static final int SUMINVCOUNT = AttributesEnum.SumInvCount.index();
    public static final int SUMINVAMOUNT = AttributesEnum.SumInvAmount.index();
    public static final int SUMLINEAMOUNT = AttributesEnum.SumLineAmount.index();
    public static final int SUMMOOTCOUNT = AttributesEnum.SumMootCount.index();
    public static final int SUMMOOTINVAMOUNT = AttributesEnum.SumMootInvAmount.index();
    public static final int SUMMOOTLINEAMOUNT = AttributesEnum.SumMootLineAmount.index();
    public static final int SUMNRFCOUNT = AttributesEnum.SumNrfCount.index();
    public static final int SUMNRFAMOUNT = AttributesEnum.SumNrfAmount.index();
    public static final int VAEMPVENDSUMTOTALVO = AttributesEnum.VAEmpVendSumTotalVO.index();
    public static final int VAEMPVENDORSUMMARYVO1 = AttributesEnum.VAEmpVendorSummaryVO1.index();
    public static final int ORGVO1 = AttributesEnum.OrgVO1.index();
    public static final int SUPPLIERLOV1 = AttributesEnum.SupplierLOV1.index();
    public static final int SUPPLIERLOV2 = AttributesEnum.SupplierLOV2.index();
    public static final int SUPPLIERSITELOV1 = AttributesEnum.SupplierSiteLOV1.index();
    public static final int VENDORASSISTANTLOV1 = AttributesEnum.VendorAssistantLOV1.index();
    public static final int ORGLOVVO1 = AttributesEnum.OrgLovVO1.index();

    /**
     * This is the default constructor (do not remove).
     */
    public VAEmpVendorSummaryVORowImpl() {
    }

    /**
     * Gets the attribute value for the calculated attribute OrgId.
     * @return the OrgId
     */
    public Number getOrgId() {
        return (Number) getAttributeInternal(ORGID);
    }

    /**
     * Gets the attribute value for the calculated attribute VendorAssistant.
     * @return the VendorAssistant
     */
    public String getVendorAssistant() {
        return (String) getAttributeInternal(VENDORASSISTANT);
    }

    /**
     * Gets the attribute value for the calculated attribute EmployeeId.
     * @return the EmployeeId
     */
    public String getEmployeeId() {
        return (String) getAttributeInternal(EMPLOYEEID);
    }

    /**
     * Gets the attribute value for the calculated attribute VendorName.
     * @return the VendorName
     */
    public String getVendorName() {
        return (String) getAttributeInternal(VENDORNAME);
    }

    /**
     * Gets the attribute value for the calculated attribute Supplier.
     * @return the Supplier
     */
    public String getSupplier() {
        return (String) getAttributeInternal(SUPPLIER);
    }

    /**
     * Gets the attribute value for the calculated attribute VendorSiteCode.
     * @return the VendorSiteCode
     */
    public String getVendorSiteCode() {
        return (String) getAttributeInternal(VENDORSITECODE);
    }

    /**
     * Gets the attribute value for the calculated attribute Disc.
     * @return the Disc
     */
    public String getDisc() {
        return (String) getAttributeInternal(DISC);
    }

    /**
     * Gets the attribute value for the calculated attribute TotalInvCount.
     * @return the TotalInvCount
     */
    public Number getTotalInvCount() {
        return (Number) getAttributeInternal(TOTALINVCOUNT);
    }

    /**
     * Gets the attribute value for the calculated attribute TotalInvAmount.
     * @return the TotalInvAmount
     */
    public Number getTotalInvAmount() {
        return (Number) getAttributeInternal(TOTALINVAMOUNT);
    }

    /**
     * Gets the attribute value for the calculated attribute TotalLineAmount.
     * @return the TotalLineAmount
     */
    public Number getTotalLineAmount() {
        return (Number) getAttributeInternal(TOTALLINEAMOUNT);
    }

    /**
     * Gets the attribute value for the calculated attribute TotalMootCount.
     * @return the TotalMootCount
     */
    public Number getTotalMootCount() {
        return (Number) getAttributeInternal(TOTALMOOTCOUNT);
    }

    /**
     * Gets the attribute value for the calculated attribute TotalMootInvAmount.
     * @return the TotalMootInvAmount
     */
    public Number getTotalMootInvAmount() {
        return (Number) getAttributeInternal(TOTALMOOTINVAMOUNT);
    }

    /**
     * Gets the attribute value for the calculated attribute TotalMootLineAmount.
     * @return the TotalMootLineAmount
     */
    public Number getTotalMootLineAmount() {
        return (Number) getAttributeInternal(TOTALMOOTLINEAMOUNT);
    }

    /**
     * Gets the attribute value for the calculated attribute TotalNrfCount.
     * @return the TotalNrfCount
     */
    public Number getTotalNrfCount() {
        return (Number) getAttributeInternal(TOTALNRFCOUNT);
    }

    /**
     * Gets the attribute value for the calculated attribute TotalNrfAmount.
     * @return the TotalNrfAmount
     */
    public Number getTotalNrfAmount() {
        return (Number) getAttributeInternal(TOTALNRFAMOUNT);
    }

    /**
     * Gets the attribute value for the calculated attribute SumInvCount.
     * @return the SumInvCount
     */
    public BigDecimal getSumInvCount() {
//        return (BigDecimal) getAttributeInternal(SUMINVCOUNT);
        return ((VAEmpVendorSummaryVOImpl)getViewObject()).getSumInvoiceCount();
    }

    /**
     * Gets the attribute value for the calculated attribute SumInvAmount.
     * @return the SumInvAmount
     */
    public BigDecimal getSumInvAmount() {
//        return (BigDecimal) getAttributeInternal(SUMINVAMOUNT);
    return ((VAEmpVendorSummaryVOImpl)getViewObject()).getSumInvoiceAmt();
    }

    /**
     * Gets the attribute value for the calculated attribute SumLineAmount.
     * @return the SumLineAmount
     */
    public BigDecimal getSumLineAmount() {
//        return (BigDecimal) getAttributeInternal(SUMLINEAMOUNT);
        return ((VAEmpVendorSummaryVOImpl)getViewObject()).getSumInvoiceLineAmt();
    }

    /**
     * Gets the attribute value for the calculated attribute SumMootCount.
     * @return the SumMootCount
     */
    public BigDecimal getSumMootCount() {
//        return (BigDecimal) getAttributeInternal(SUMMOOTCOUNT);
        return ((VAEmpVendorSummaryVOImpl)getViewObject()).getSumMootCount();
    }

    /**
     * Gets the attribute value for the calculated attribute SumMootInvAmount.
     * @return the SumMootInvAmount
     */
    public BigDecimal getSumMootInvAmount() {
//        return (BigDecimal) getAttributeInternal(SUMMOOTINVAMOUNT);
    return ((VAEmpVendorSummaryVOImpl)getViewObject()).getSumMootInvoiceAmt();
    }

    /**
     * Gets the attribute value for the calculated attribute SumMootLineAmount.
     * @return the SumMootLineAmount
     */
    public BigDecimal getSumMootLineAmount() {
//        return (BigDecimal) getAttributeInternal(SUMMOOTLINEAMOUNT);
        return ((VAEmpVendorSummaryVOImpl)getViewObject()).getSumMootLineAmt();
    }

    /**
     * Gets the attribute value for the calculated attribute SumNrfCount.
     * @return the SumNrfCount
     */
    public BigDecimal getSumNrfCount() {
//        return (BigDecimal) getAttributeInternal(SUMNRFCOUNT);
        return ((VAEmpVendorSummaryVOImpl)getViewObject()).getSumNrfCount();
    }

    /**
     * Gets the attribute value for the calculated attribute SumNrfAmount.
     * @return the SumNrfAmount
     */
    public BigDecimal getSumNrfAmount() {
//        return (BigDecimal) getAttributeInternal(SUMNRFAMOUNT);
        return ((VAEmpVendorSummaryVOImpl)getViewObject()).getSumNrfAmt();
    }

    /**
     * Gets the associated <code>VAEmpVendSumTotalVORowImpl</code> using master-detail link VAEmpVendSumTotalVO.
     */
    public VAEmpVendSumTotalVORowImpl getVAEmpVendSumTotalVO() {
        return (VAEmpVendSumTotalVORowImpl) getAttributeInternal(VAEMPVENDSUMTOTALVO);
    }

    /**
     * Sets the master-detail link VAEmpVendSumTotalVO between this object and <code>value</code>.
     */
    public void setVAEmpVendSumTotalVO(VAEmpVendSumTotalVORowImpl value) {
        setAttributeInternal(VAEMPVENDSUMTOTALVO, value);
    }

    /**
     * Gets the view accessor <code>RowSet</code> VAEmpVendorSummaryVO1.
     */
    public RowSet getVAEmpVendorSummaryVO1() {
        return (RowSet) getAttributeInternal(VAEMPVENDORSUMMARYVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> OrgVO1.
     */
    public RowSet getOrgVO1() {
        return (RowSet) getAttributeInternal(ORGVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> SupplierLOV1.
     */
    public RowSet getSupplierLOV1() {
        return (RowSet) getAttributeInternal(SUPPLIERLOV1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> SupplierLOV2.
     */
    public RowSet getSupplierLOV2() {
        return (RowSet) getAttributeInternal(SUPPLIERLOV2);
    }

    /**
     * Gets the view accessor <code>RowSet</code> SupplierSiteLOV1.
     */
    public RowSet getSupplierSiteLOV1() {
        return (RowSet) getAttributeInternal(SUPPLIERSITELOV1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> VendorAssistantLOV1.
     */
    public RowSet getVendorAssistantLOV1() {
        return (RowSet) getAttributeInternal(VENDORASSISTANTLOV1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> OrgLovVO1.
     */
    public RowSet getOrgLovVO1() {
        return (RowSet) getAttributeInternal(ORGLOVVO1);
    }
}

