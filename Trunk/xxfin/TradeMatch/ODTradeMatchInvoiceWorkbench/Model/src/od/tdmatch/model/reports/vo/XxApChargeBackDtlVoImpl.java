package od.tdmatch.model.reports.vo;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ViewObjectImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Wed Oct 18 17:52:48 IST 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class XxApChargeBackDtlVoImpl extends ViewObjectImpl {
    /**
     * This is the default constructor (do not remove).
     */
    public XxApChargeBackDtlVoImpl() {
    }

    /**
     * Returns the bind variable value for bindFromDate.
     * @return bind variable value for bindFromDate
     */
    public Date getbindFromDate() {
        
       
        
      
        return (Date) getNamedWhereClauseParam("bindFromDate");
        
    }

    /**
     * Sets <code>value</code> for bind variable bindFromDate.
     * @param value value to bind as bindFromDate
     */
    public void setbindFromDate(Date value) {
        setNamedWhereClauseParam("bindFromDate", value);
    }

    /**
     * Returns the bind variable value for bindToDate.
     * @return bind variable value for bindToDate
     */
    public Date getbindToDate() {
        return (Date) getNamedWhereClauseParam("bindToDate");
    }

    /**
     * Sets <code>value</code> for bind variable bindToDate.
     * @param value value to bind as bindToDate
     */
    public void setbindToDate(Date value) {
        setNamedWhereClauseParam("bindToDate", value);
    }

    /**
     * Returns the bind variable value for bindOrgId.
     * @return bind variable value for bindOrgId
     */
    public Number getbindOrgId() {
        return (Number) getNamedWhereClauseParam("bindOrgId");
    }

    /**
     * Sets <code>value</code> for bind variable bindOrgId.
     * @param value value to bind as bindOrgId
     */
    public void setbindOrgId(Number value) {
        setNamedWhereClauseParam("bindOrgId", value);
    }


    /**
     * Returns the bind variable value for bindAssistCode.
     * @return bind variable value for bindAssistCode
     */
    public String getbindAssistCode() {
        return (String) getNamedWhereClauseParam("bindAssistCode");
    }

    /**
     * Sets <code>value</code> for bind variable bindAssistCode.
     * @param value value to bind as bindAssistCode
     */
    public void setbindAssistCode(String value) {
        setNamedWhereClauseParam("bindAssistCode", value);
    }


    /**
     * Returns the bind variable value for bindSupId.
     * @return bind variable value for bindSupId
     */
    public Number getbindSupId() {
        return (Number) getNamedWhereClauseParam("bindSupId");
    }

    /**
     * Sets <code>value</code> for bind variable bindSupId.
     * @param value value to bind as bindSupId
     */
    public void setbindSupId(Number value) {
        setNamedWhereClauseParam("bindSupId", value);
    }

    /**
     * Returns the bind variable value for bindSupSiteId.
     * @return bind variable value for bindSupSiteId
     */
    public Number getbindSupSiteId() {
        return (Number) getNamedWhereClauseParam("bindSupSiteId");
    }

    /**
     * Sets <code>value</code> for bind variable bindSupSiteId.
     * @param value value to bind as bindSupSiteId
     */
    public void setbindSupSiteId(Number value) {
        setNamedWhereClauseParam("bindSupSiteId", value);
    }

    /**
     * Returns the bind variable value for bindInvItemId.
     * @return bind variable value for bindInvItemId
     */
    public String getbindInvItemId() {
        return (String) getNamedWhereClauseParam("bindInvItemId");
    }

    /**
     * Sets <code>value</code> for bind variable bindInvItemId.
     * @param value value to bind as bindInvItemId
     */
    public void setbindInvItemId(String value) {
        setNamedWhereClauseParam("bindInvItemId", value);
    }

    /**
     * Returns the bind variable value for bindReportOption.
     * @return bind variable value for bindReportOption
     */
    public String getbindReportOption() {
        return (String) getNamedWhereClauseParam("bindReportOption");
    }

    /**
     * Sets <code>value</code> for bind variable bindReportOption.
     * @param value value to bind as bindReportOption
     */
    public void setbindReportOption(String value) {
        setNamedWhereClauseParam("bindReportOption", value);
    }

    /**
     * Returns the bind variable value for bindDisOption.
     * @return bind variable value for bindDisOption
     */
    public String getbindDisOption() {
        return (String) getNamedWhereClauseParam("bindDisOption");
    }

    /**
     * Sets <code>value</code> for bind variable bindDisOption.
     * @param value value to bind as bindDisOption
     */
    public void setbindDisOption(String value) {
        setNamedWhereClauseParam("bindDisOption", value);
    }

    /**
     * Returns the bind variable value for bindPrcExcep.
     * @return bind variable value for bindPrcExcep
     */
    public String getbindPrcExcep() {
        return (String) getNamedWhereClauseParam("bindPrcExcep");
    }

    /**
     * Sets <code>value</code> for bind variable bindPrcExcep.
     * @param value value to bind as bindPrcExcep
     */
    public void setbindPrcExcep(String value) {
        setNamedWhereClauseParam("bindPrcExcep", value);
    }

    /**
     * Returns the bind variable value for bindQtyExcep.
     * @return bind variable value for bindQtyExcep
     */
    public String getbindQtyExcep() {
        return (String) getNamedWhereClauseParam("bindQtyExcep");
    }

    /**
     * Sets <code>value</code> for bind variable bindQtyExcep.
     * @param value value to bind as bindQtyExcep
     */
    public void setbindQtyExcep(String value) {
        setNamedWhereClauseParam("bindQtyExcep", value);
    }

    /**
     * Returns the bind variable value for bindOthExcep.
     * @return bind variable value for bindOthExcep
     */
    public String getbindOthExcep() {
        return (String) getNamedWhereClauseParam("bindOthExcep");
    }

    /**
     * Sets <code>value</code> for bind variable bindOthExcep.
     * @param value value to bind as bindOthExcep
     */
    public void setbindOthExcep(String value) {
        setNamedWhereClauseParam("bindOthExcep", value);
    }
}

