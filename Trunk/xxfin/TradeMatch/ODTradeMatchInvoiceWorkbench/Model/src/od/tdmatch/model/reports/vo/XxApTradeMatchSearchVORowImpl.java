package od.tdmatch.model.reports.vo;

import oracle.jbo.RowSet;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ViewRowImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Tue Nov 21 15:43:46 IST 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class XxApTradeMatchSearchVORowImpl extends ViewRowImpl {
    /**
     * AttributesEnum: generated enum for identifying attributes and accessors. DO NOT MODIFY.
     */
    protected enum AttributesEnum {
        Reportoption,
        Vendorassistant,
        Supplier,
        Suppliername,
        Suppliersiteno,
        Daterangefrom,
        Daterangeto,
        Periodrangefrom,
        Periodrangeto,
        Dropship,
        Orgid,
        OrgIdVal,
        SuppNo,
        SupSiteCode,
        VendorAssistantDLov1,
        SupplierDLovVO1,
        SupplierDLovVO2,
        SupplierSiteDLovVO1,
        PeriodFromLOV1,
        PeriodLOV1,
        OrgVO1,
        ReportOptionStaticLOV1,
        SupplierSiteDLovVO2,
        VendorAssistantDLov2,
        SupplierDLovVO3,
        OrgLovVO1;
        private static AttributesEnum[] vals = null;
        private static final int firstIndex = 0;

        protected int index() {
            return XxApTradeMatchSearchVORowImpl.AttributesEnum.firstIndex() + ordinal();
        }

        protected static final int firstIndex() {
            return firstIndex;
        }

        protected static int count() {
            return XxApTradeMatchSearchVORowImpl.AttributesEnum.firstIndex() + XxApTradeMatchSearchVORowImpl.AttributesEnum
                                                                                                            .staticValues().length;
        }

        protected static final AttributesEnum[] staticValues() {
            if (vals == null) {
                vals = XxApTradeMatchSearchVORowImpl.AttributesEnum.values();
            }
            return vals;
        }
    }


    public static final int REPORTOPTION = AttributesEnum.Reportoption.index();
    public static final int VENDORASSISTANT = AttributesEnum.Vendorassistant.index();
    public static final int SUPPLIER = AttributesEnum.Supplier.index();
    public static final int SUPPLIERNAME = AttributesEnum.Suppliername.index();
    public static final int SUPPLIERSITENO = AttributesEnum.Suppliersiteno.index();
    public static final int DATERANGEFROM = AttributesEnum.Daterangefrom.index();
    public static final int DATERANGETO = AttributesEnum.Daterangeto.index();
    public static final int PERIODRANGEFROM = AttributesEnum.Periodrangefrom.index();
    public static final int PERIODRANGETO = AttributesEnum.Periodrangeto.index();
    public static final int DROPSHIP = AttributesEnum.Dropship.index();
    public static final int ORGID = AttributesEnum.Orgid.index();
    public static final int ORGIDVAL = AttributesEnum.OrgIdVal.index();
    public static final int SUPPNO = AttributesEnum.SuppNo.index();
    public static final int SUPSITECODE = AttributesEnum.SupSiteCode.index();
    public static final int VENDORASSISTANTDLOV1 = AttributesEnum.VendorAssistantDLov1.index();
    public static final int SUPPLIERDLOVVO1 = AttributesEnum.SupplierDLovVO1.index();
    public static final int SUPPLIERDLOVVO2 = AttributesEnum.SupplierDLovVO2.index();
    public static final int SUPPLIERSITEDLOVVO1 = AttributesEnum.SupplierSiteDLovVO1.index();
    public static final int PERIODFROMLOV1 = AttributesEnum.PeriodFromLOV1.index();
    public static final int PERIODLOV1 = AttributesEnum.PeriodLOV1.index();
    public static final int ORGVO1 = AttributesEnum.OrgVO1.index();
    public static final int REPORTOPTIONSTATICLOV1 = AttributesEnum.ReportOptionStaticLOV1.index();
    public static final int SUPPLIERSITEDLOVVO2 = AttributesEnum.SupplierSiteDLovVO2.index();
    public static final int VENDORASSISTANTDLOV2 = AttributesEnum.VendorAssistantDLov2.index();
    public static final int SUPPLIERDLOVVO3 = AttributesEnum.SupplierDLovVO3.index();
    public static final int ORGLOVVO1 = AttributesEnum.OrgLovVO1.index();

    /**
     * This is the default constructor (do not remove).
     */
    public XxApTradeMatchSearchVORowImpl() {
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
     * Gets the attribute value for the calculated attribute Vendorassistant.
     * @return the Vendorassistant
     */
    public String getVendorassistant() {
        return (String) getAttributeInternal(VENDORASSISTANT);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Vendorassistant.
     * @param value value to set the  Vendorassistant
     */
    public void setVendorassistant(String value) {
        setAttributeInternal(VENDORASSISTANT, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Supplier.
     * @return the Supplier
     */
    public String getSupplier() {
        return (String) getAttributeInternal(SUPPLIER);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Supplier.
     * @param value value to set the  Supplier
     */
    public void setSupplier(String value) {
        setAttributeInternal(SUPPLIER, value);
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
     * Gets the attribute value for the calculated attribute Daterangefrom.
     * @return the Daterangefrom
     */
    public Date getDaterangefrom() {
        return (Date) getAttributeInternal(DATERANGEFROM);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Daterangefrom.
     * @param value value to set the  Daterangefrom
     */
    public void setDaterangefrom(Date value) {
        setAttributeInternal(DATERANGEFROM, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Daterangeto.
     * @return the Daterangeto
     */
    public Date getDaterangeto() {
        return (Date) getAttributeInternal(DATERANGETO);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Daterangeto.
     * @param value value to set the  Daterangeto
     */
    public void setDaterangeto(Date value) {
        setAttributeInternal(DATERANGETO, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Periodrangefrom.
     * @return the Periodrangefrom
     */
    public String getPeriodrangefrom() {
        return (String) getAttributeInternal(PERIODRANGEFROM);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Periodrangefrom.
     * @param value value to set the  Periodrangefrom
     */
    public void setPeriodrangefrom(String value) {
        setAttributeInternal(PERIODRANGEFROM, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Periodrangeto.
     * @return the Periodrangeto
     */
    public String getPeriodrangeto() {
        return (String) getAttributeInternal(PERIODRANGETO);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Periodrangeto.
     * @param value value to set the  Periodrangeto
     */
    public void setPeriodrangeto(String value) {
        setAttributeInternal(PERIODRANGETO, value);
    }

    /**
     * Gets the attribute value for the calculated attribute Dropship.
     * @return the Dropship
     */
    public String getDropship() {
        return (String) getAttributeInternal(DROPSHIP);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute Dropship.
     * @param value value to set the  Dropship
     */
    public void setDropship(String value) {
        setAttributeInternal(DROPSHIP, value);
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
     * Gets the attribute value for the calculated attribute SuppNo.
     * @return the SuppNo
     */
    public Number getSuppNo() {
        return (Number) getAttributeInternal(SUPPNO);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute SuppNo.
     * @param value value to set the  SuppNo
     */
    public void setSuppNo(Number value) {
        setAttributeInternal(SUPPNO, value);
    }

    /**
     * Gets the attribute value for the calculated attribute SupSiteCode.
     * @return the SupSiteCode
     */
    public Number getSupSiteCode() {
        return (Number) getAttributeInternal(SUPSITECODE);
    }

    /**
     * Sets <code>value</code> as the attribute value for the calculated attribute SupSiteCode.
     * @param value value to set the  SupSiteCode
     */
    public void setSupSiteCode(Number value) {
        setAttributeInternal(SUPSITECODE, value);
    }

    /**
     * Gets the view accessor <code>RowSet</code> VendorAssistantDLov1.
     */
    public RowSet getVendorAssistantDLov1() {
        return (RowSet) getAttributeInternal(VENDORASSISTANTDLOV1);
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
     * Gets the view accessor <code>RowSet</code> PeriodFromLOV1.
     */
    public RowSet getPeriodFromLOV1() {
        return (RowSet) getAttributeInternal(PERIODFROMLOV1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> PeriodLOV1.
     */
    public RowSet getPeriodLOV1() {
        return (RowSet) getAttributeInternal(PERIODLOV1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> OrgVO1.
     */
    public RowSet getOrgVO1() {
        return (RowSet) getAttributeInternal(ORGVO1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> ReportOptionStaticLOV1.
     */
    public RowSet getReportOptionStaticLOV1() {
        return (RowSet) getAttributeInternal(REPORTOPTIONSTATICLOV1);
    }

    /**
     * Gets the view accessor <code>RowSet</code> SupplierSiteDLovVO2.
     */
    public RowSet getSupplierSiteDLovVO2() {
        return (RowSet) getAttributeInternal(SUPPLIERSITEDLOVVO2);
    }

    /**
     * Gets the view accessor <code>RowSet</code> VendorAssistantDLov2.
     */
    public RowSet getVendorAssistantDLov2() {
        return (RowSet) getAttributeInternal(VENDORASSISTANTDLOV2);
    }

    /**
     * Gets the view accessor <code>RowSet</code> SupplierDLovVO3.
     */
    public RowSet getSupplierDLovVO3() {
        return (RowSet) getAttributeInternal(SUPPLIERDLOVVO3);
    }

    /**
     * Gets the view accessor <code>RowSet</code> OrgLovVO1.
     */
    public RowSet getOrgLovVO1() {
        return (RowSet) getAttributeInternal(ORGLOVVO1);
    }
}

