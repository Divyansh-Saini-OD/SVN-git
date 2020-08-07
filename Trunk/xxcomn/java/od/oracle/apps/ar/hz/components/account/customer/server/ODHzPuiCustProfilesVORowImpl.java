package od.oracle.apps.ar.hz.components.account.customer.server;

import oracle.apps.ar.hz.components.account.customer.server.HzPuiCustProfileEOImpl;
import oracle.apps.ar.hz.components.account.customer.server.HzPuiCustProfilesVORowImpl;

import oracle.jbo.server.AttributeDefImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class ODHzPuiCustProfilesVORowImpl extends HzPuiCustProfilesVORowImpl {

    public static final int MAXATTRCONST = oracle.jbo.server.ViewDefImpl.getMaxAttrConst("oracle.apps.ar.hz.components.account.customer.server.HzPuiCustProfilesVO");
    public static final int DNBRATING = MAXATTRCONST;

    /**This is the default constructor (do not remove)
     */
    public ODHzPuiCustProfilesVORowImpl() {
    }

    /**Gets HzPuiCustProfileEO entity object.
     */
    public HzPuiCustProfileEOImpl getHzPuiCustProfileEO() {
        return (HzPuiCustProfileEOImpl)getEntity(0);
    }

    /**Gets the attribute value for the calculated attribute StmtCycleName
     */
    public String getStmtCycleName() {
        return (String) getAttributeInternal("StmtCycleName");
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute StmtCycleName
     */
    public void setStmtCycleName(String value) {
        setAttributeInternal("StmtCycleName", value);
    }

    /**Gets the attribute value for the calculated attribute DunLetterSetName
     */
    public String getDunLetterSetName() {
        return (String) getAttributeInternal("DunLetterSetName");
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute DunLetterSetName
     */
    public void setDunLetterSetName(String value) {
        setAttributeInternal("DunLetterSetName", value);
    }

    /**Gets the attribute value for the calculated attribute GroupRuleName
     */
    public String getGroupRuleName() {
        return (String) getAttributeInternal("GroupRuleName");
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute GroupRuleName
     */
    public void setGroupRuleName(String value) {
        setAttributeInternal("GroupRuleName", value);
    }

    /**Gets the attribute value for the calculated attribute RenderFlex
     */
    public Boolean getRenderFlex() {
        return (Boolean) getAttributeInternal("RenderFlex");
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute RenderFlex
     */
    public void setRenderFlex(Boolean value) {
        setAttributeInternal("RenderFlex", value);
    }

    /**Gets the attribute value for the calculated attribute DisplayBillLevel
     */
    public String getDisplayBillLevel() {
        return (String) getAttributeInternal("DisplayBillLevel");
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute DisplayBillLevel
     */
    public void setDisplayBillLevel(String value) {
        setAttributeInternal("DisplayBillLevel", value);
    }

    /**Gets the attribute value for the calculated attribute ActBfbFlag
     */
    public String getActBfbFlag() {
        return (String) getAttributeInternal("ActBfbFlag");
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute ActBfbFlag
     */
    public void setActBfbFlag(String value) {
        setAttributeInternal("ActBfbFlag", value);
    }

    /**Gets the attribute value for the calculated attribute AutomatchSetName
     */
    public String getAutomatchSetName() {
        return (String) getAttributeInternal("AutomatchSetName");
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute AutomatchSetName
     */
    public void setAutomatchSetName(String value) {
        setAttributeInternal("AutomatchSetName", value);
    }


    /**getAttrInvokeAccessor: generated method. Do not modify.
     */
    protected Object getAttrInvokeAccessor(int index, 
                                           AttributeDefImpl attrDef) throws Exception {
        if (index == DNBRATING) {
            return getDnbRating();
        }
        return super.getAttrInvokeAccessor(index, attrDef);
    }

    /**setAttrInvokeAccessor: generated method. Do not modify.
     */
    protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception {
        if (index == DNBRATING) {
            setDnbRating((String)value);
            return;
        }
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
    }

    /**Gets the attribute value for the calculated attribute DnbRating
     */
    public String getDnbRating() {
        return (String) getAttributeInternal(DNBRATING);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute DnbRating
     */
    public void setDnbRating(String value) {
        setAttributeInternal(DNBRATING, value);
    }

    /**Gets the attribute value for the calculated attribute ProfileClassName
     */
    public String getProfileClassName() {
        return super.getProfileClassName();
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute ProfileClassName
     */
    public void setProfileClassName(String value) {
        super.setProfileClassName(value);
    }

    /**Gets the attribute value for the calculated attribute CreditRatingMeaning
     */
    public String getCreditRatingMeaning() {
        return super.getCreditRatingMeaning();
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute CreditRatingMeaning
     */
    public void setCreditRatingMeaning(String value) {
        super.setCreditRatingMeaning(value);
    }

    /**Gets the attribute value for the calculated attribute CreditClassMeaning
     */
    public String getCreditClassMeaning() {
        return super.getCreditClassMeaning();
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute CreditClassMeaning
     */
    public void setCreditClassMeaning(String value) {
        super.setCreditClassMeaning(value);
    }

    /**Gets the attribute value for the calculated attribute ReviewCycleMeaning
     */
    public String getReviewCycleMeaning() {
        return super.getReviewCycleMeaning();
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute ReviewCycleMeaning
     */
    public void setReviewCycleMeaning(String value) {
        super.setReviewCycleMeaning(value);
    }

    /**Gets the attribute value for the calculated attribute ActStatusMeaning
     */
    public String getActStatusMeaning() {
        return super.getActStatusMeaning();
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute ActStatusMeaning
     */
    public void setActStatusMeaning(String value) {
        super.setActStatusMeaning(value);
    }

    /**Gets the attribute value for the calculated attribute RiskCodeMeaning
     */
    public String getRiskCodeMeaning() {
        return super.getRiskCodeMeaning();
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute RiskCodeMeaning
     */
    public void setRiskCodeMeaning(String value) {
        super.setRiskCodeMeaning(value);
    }

    /**Gets the attribute value for the calculated attribute CreditAnylstName
     */
    public String getCreditAnylstName() {
        return super.getCreditAnylstName();
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute CreditAnylstName
     */
    public void setCreditAnylstName(String value) {
        super.setCreditAnylstName(value);
    }

    /**Gets the attribute value for the calculated attribute CollectorName
     */
    public String getCollectorName() {
        return super.getCollectorName();
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute CollectorName
     */
    public void setCollectorName(String value) {
        super.setCollectorName(value);
    }

    /**Gets the attribute value for the calculated attribute PaymentTermName
     */
    public String getPaymentTermName() {
        return super.getPaymentTermName();
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute PaymentTermName
     */
    public void setPaymentTermName(String value) {
        super.setPaymentTermName(value);
    }

    /**Gets the attribute value for the calculated attribute CashRulesetName
     */
    public String getCashRulesetName() {
        return super.getCashRulesetName();
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute CashRulesetName
     */
    public void setCashRulesetName(String value) {
        super.setCashRulesetName(value);
    }

    /**Gets the attribute value for the calculated attribute ReminderRulesetName
     */
    public String getReminderRulesetName() {
        return super.getReminderRulesetName();
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute ReminderRulesetName
     */
    public void setReminderRulesetName(String value) {
        super.setReminderRulesetName(value);
    }
}
