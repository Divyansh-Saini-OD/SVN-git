package od.tdmatch.model;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.EntityImpl;
import oracle.jbo.server.ViewRowImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Mon Aug 14 10:18:16 EDT 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class XXApInvoiceHeaderVORowImpl extends ViewRowImpl {


    public static final int ENTITY_XXAPINVOICEHEADEREO = 0;

    /**
     * AttributesEnum: generated enum for identifying attributes and accessors. DO NOT MODIFY.
     */
    protected enum AttributesEnum {
        ChbkCreatedFlag,
        CreatedBy,
        CreatedByName,
        CreationDate,
        ErrorMessage,
        InvoiceId,
        InvoiceNum,
        LastUpdatedBy,
        LastUpdatedDate,
        PoHeaderId,
        ProcessFlag,
        RelHoldFlag,
        OrgId,
        RequestId;
        private static AttributesEnum[] vals = null;
        ;
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


    public static final int CHBKCREATEDFLAG = AttributesEnum.ChbkCreatedFlag.index();
    public static final int CREATEDBY = AttributesEnum.CreatedBy.index();
    public static final int CREATEDBYNAME = AttributesEnum.CreatedByName.index();
    public static final int CREATIONDATE = AttributesEnum.CreationDate.index();
    public static final int ERRORMESSAGE = AttributesEnum.ErrorMessage.index();
    public static final int INVOICEID = AttributesEnum.InvoiceId.index();
    public static final int INVOICENUM = AttributesEnum.InvoiceNum.index();
    public static final int LASTUPDATEDBY = AttributesEnum.LastUpdatedBy.index();
    public static final int LASTUPDATEDDATE = AttributesEnum.LastUpdatedDate.index();
    public static final int POHEADERID = AttributesEnum.PoHeaderId.index();
    public static final int PROCESSFLAG = AttributesEnum.ProcessFlag.index();
    public static final int RELHOLDFLAG = AttributesEnum.RelHoldFlag.index();
    public static final int ORGID = AttributesEnum.OrgId.index();
    public static final int REQUESTID = AttributesEnum.RequestId.index();

    /**
     * This is the default constructor (do not remove).
     */
    public XXApInvoiceHeaderVORowImpl() {
    }

    /**
     * Gets XXApInvoiceHeaderEO entity object.
     * @return the XXApInvoiceHeaderEO
     */
    public EntityImpl getXXApInvoiceHeaderEO() {
        return (EntityImpl) getEntity(ENTITY_XXAPINVOICEHEADEREO);
    }

    /**
     * Gets the attribute value for CHBK_CREATED_FLAG using the alias name ChbkCreatedFlag.
     * @return the CHBK_CREATED_FLAG
     */
    public String getChbkCreatedFlag() {
        return (String) getAttributeInternal(CHBKCREATEDFLAG);
    }

    /**
     * Sets <code>value</code> as attribute value for CHBK_CREATED_FLAG using the alias name ChbkCreatedFlag.
     * @param value value to set the CHBK_CREATED_FLAG
     */
    public void setChbkCreatedFlag(String value) {
        setAttributeInternal(CHBKCREATEDFLAG, value);
    }

    /**
     * Gets the attribute value for CREATED_BY using the alias name CreatedBy.
     * @return the CREATED_BY
     */
    public Number getCreatedBy() {
        return (Number) getAttributeInternal(CREATEDBY);
    }

    /**
     * Sets <code>value</code> as attribute value for CREATED_BY using the alias name CreatedBy.
     * @param value value to set the CREATED_BY
     */
    public void setCreatedBy(Number value) {
        setAttributeInternal(CREATEDBY, value);
    }

    /**
     * Gets the attribute value for CREATED_BY_NAME using the alias name CreatedByName.
     * @return the CREATED_BY_NAME
     */
    public String getCreatedByName() {
        return (String) getAttributeInternal(CREATEDBYNAME);
    }

    /**
     * Sets <code>value</code> as attribute value for CREATED_BY_NAME using the alias name CreatedByName.
     * @param value value to set the CREATED_BY_NAME
     */
    public void setCreatedByName(String value) {
        setAttributeInternal(CREATEDBYNAME, value);
    }

    /**
     * Gets the attribute value for CREATION_DATE using the alias name CreationDate.
     * @return the CREATION_DATE
     */
    public Date getCreationDate() {
        return (Date) getAttributeInternal(CREATIONDATE);
    }

    /**
     * Sets <code>value</code> as attribute value for CREATION_DATE using the alias name CreationDate.
     * @param value value to set the CREATION_DATE
     */
    public void setCreationDate(Date value) {
        setAttributeInternal(CREATIONDATE, value);
    }

    /**
     * Gets the attribute value for ERROR_MESSAGE using the alias name ErrorMessage.
     * @return the ERROR_MESSAGE
     */
    public String getErrorMessage() {
        return (String) getAttributeInternal(ERRORMESSAGE);
    }

    /**
     * Sets <code>value</code> as attribute value for ERROR_MESSAGE using the alias name ErrorMessage.
     * @param value value to set the ERROR_MESSAGE
     */
    public void setErrorMessage(String value) {
        setAttributeInternal(ERRORMESSAGE, value);
    }

    /**
     * Gets the attribute value for INVOICE_ID using the alias name InvoiceId.
     * @return the INVOICE_ID
     */
    public Number getInvoiceId() {
        return (Number) getAttributeInternal(INVOICEID);
    }

    /**
     * Sets <code>value</code> as attribute value for INVOICE_ID using the alias name InvoiceId.
     * @param value value to set the INVOICE_ID
     */
    public void setInvoiceId(Number value) {
        setAttributeInternal(INVOICEID, value);
    }

    /**
     * Gets the attribute value for INVOICE_NUM using the alias name InvoiceNum.
     * @return the INVOICE_NUM
     */
    public String getInvoiceNum() {
        return (String) getAttributeInternal(INVOICENUM);
    }

    /**
     * Sets <code>value</code> as attribute value for INVOICE_NUM using the alias name InvoiceNum.
     * @param value value to set the INVOICE_NUM
     */
    public void setInvoiceNum(String value) {
        setAttributeInternal(INVOICENUM, value);
    }

    /**
     * Gets the attribute value for LAST_UPDATED_BY using the alias name LastUpdatedBy.
     * @return the LAST_UPDATED_BY
     */
    public Number getLastUpdatedBy() {
        return (Number) getAttributeInternal(LASTUPDATEDBY);
    }

    /**
     * Sets <code>value</code> as attribute value for LAST_UPDATED_BY using the alias name LastUpdatedBy.
     * @param value value to set the LAST_UPDATED_BY
     */
    public void setLastUpdatedBy(Number value) {
        setAttributeInternal(LASTUPDATEDBY, value);
    }

    /**
     * Gets the attribute value for LAST_UPDATED_DATE using the alias name LastUpdatedDate.
     * @return the LAST_UPDATED_DATE
     */
    public Date getLastUpdatedDate() {
        return (Date) getAttributeInternal(LASTUPDATEDDATE);
    }

    /**
     * Sets <code>value</code> as attribute value for LAST_UPDATED_DATE using the alias name LastUpdatedDate.
     * @param value value to set the LAST_UPDATED_DATE
     */
    public void setLastUpdatedDate(Date value) {
        setAttributeInternal(LASTUPDATEDDATE, value);
    }

    /**
     * Gets the attribute value for PO_HEADER_ID using the alias name PoHeaderId.
     * @return the PO_HEADER_ID
     */
    public Number getPoHeaderId() {
        return (Number) getAttributeInternal(POHEADERID);
    }

    /**
     * Sets <code>value</code> as attribute value for PO_HEADER_ID using the alias name PoHeaderId.
     * @param value value to set the PO_HEADER_ID
     */
    public void setPoHeaderId(Number value) {
        setAttributeInternal(POHEADERID, value);
    }

    /**
     * Gets the attribute value for PROCESS_FLAG using the alias name ProcessFlag.
     * @return the PROCESS_FLAG
     */
    public String getProcessFlag() {
        return (String) getAttributeInternal(PROCESSFLAG);
    }

    /**
     * Sets <code>value</code> as attribute value for PROCESS_FLAG using the alias name ProcessFlag.
     * @param value value to set the PROCESS_FLAG
     */
    public void setProcessFlag(String value) {
        setAttributeInternal(PROCESSFLAG, value);
    }

    /**
     * Gets the attribute value for REL_HOLD_FLAG using the alias name RelHoldFlag.
     * @return the REL_HOLD_FLAG
     */
    public String getRelHoldFlag() {
        return (String) getAttributeInternal(RELHOLDFLAG);
    }

    /**
     * Sets <code>value</code> as attribute value for REL_HOLD_FLAG using the alias name RelHoldFlag.
     * @param value value to set the REL_HOLD_FLAG
     */
    public void setRelHoldFlag(String value) {
        setAttributeInternal(RELHOLDFLAG, value);
    }

    /**
     * Gets the attribute value for ORG_ID using the alias name OrgId.
     * @return the ORG_ID
     */
    public Number getOrgId() {
        return (Number) getAttributeInternal(ORGID);
    }

    /**
     * Sets <code>value</code> as attribute value for ORG_ID using the alias name OrgId.
     * @param value value to set the ORG_ID
     */
    public void setOrgId(Number value) {
        setAttributeInternal(ORGID, value);
    }

    /**
     * Gets the attribute value for REQUEST_ID using the alias name RequestId.
     * @return the REQUEST_ID
     */
    public Number getRequestId() {
        return (Number) getAttributeInternal(REQUESTID);
    }

    /**
     * Sets <code>value</code> as attribute value for REQUEST_ID using the alias name RequestId.
     * @param value value to set the REQUEST_ID
     */
    public void setRequestId(Number value) {
        setAttributeInternal(REQUESTID, value);
    }
}

