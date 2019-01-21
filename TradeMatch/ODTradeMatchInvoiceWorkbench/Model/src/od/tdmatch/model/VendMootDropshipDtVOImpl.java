package od.tdmatch.model;

import java.math.BigDecimal;

import java.sql.ResultSet;

import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.NClobDomain;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ViewObjectImpl;
import oracle.jbo.server.ViewRowImpl;
import oracle.jbo.server.ViewRowSetImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Sun Jun 04 16:12:13 EDT 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class VendMootDropshipDtVOImpl extends ViewObjectImpl {
    /**
     * This is the default constructor (do not remove).
     */
    public VendMootDropshipDtVOImpl() {
    }

    /**
     * Returns the variable value for OperatingUnit.
     * @return variable value for OperatingUnit
     */
    public Number getOperatingUnit() {
        return (Number) ensureVariableManager().getVariableValue("OperatingUnit");
    }

    /**
     * Sets <code>value</code> for variable OperatingUnit.
     * @param value value to bind as OperatingUnit
     */
    public void setOperatingUnit(Number value) {
        ensureVariableManager().setVariableValue("OperatingUnit", value);
    }

    /**
     * Returns the bind variable value for p_item.
     * @return bind variable value for p_item
     */
    public String getp_item() {
        return (String) getNamedWhereClauseParam("p_item");
    }

    /**
     * Sets <code>value</code> for bind variable p_item.
     * @param value value to bind as p_item
     */
    public void setp_item(String value) {
        setNamedWhereClauseParam("p_item", value);
    }

    /**
     * Returns the bind variable value for p_frt_expt.
     * @return bind variable value for p_frt_expt
     */
    public String getp_frt_expt() {
        return (String) getNamedWhereClauseParam("p_frt_expt");
    }

    /**
     * Sets <code>value</code> for bind variable p_frt_expt.
     * @param value value to bind as p_frt_expt
     */
    public void setp_frt_expt(String value) {
        setNamedWhereClauseParam("p_frt_expt", value);
    }

    /**
     * executeQueryForCollection - for custom java data source support.
     */
    @Override
    protected void executeQueryForCollection(Object qc, Object[] params, int noUserParams) {
        super.executeQueryForCollection(qc, params, noUserParams);
        this.calculateFooterTotals();
    }

    /**
     * hasNextForCollection - for custom java data source support.
     */
    @Override
    protected boolean hasNextForCollection(Object qc) {
        boolean bRet = super.hasNextForCollection(qc);
        return bRet;
    }

    /**
     * createRowFromResultSet - for custom java data source support.
     */
    @Override
    protected ViewRowImpl createRowFromResultSet(Object qc, ResultSet resultSet) {
        ViewRowImpl value = super.createRowFromResultSet(qc, resultSet);
        return value;
    }

    /**
     * getQueryHitCount - for custom java data source support.
     */
    @Override
    public long getQueryHitCount(ViewRowSetImpl viewRowSet) {
        long value = super.getQueryHitCount(viewRowSet);
        return value;
    }

    /**
     * getCappedQueryHitCount - for custom java data source support.
     */
    @Override
    public long getCappedQueryHitCount(ViewRowSetImpl viewRowSet, Row[] masterRows, long oldCap, long cap) {
        long value = super.getCappedQueryHitCount(viewRowSet, masterRows, oldCap, cap);
        return value;
    }
    
    private BigDecimal sumInvoiceAmt;
    private BigDecimal sumQtyHoldAmt;
    private BigDecimal sumPriceHoldAmt;
    
    public void setSumInvoiceAmt(BigDecimal sumInvoiceAmt){
            this.sumInvoiceAmt = sumInvoiceAmt;
    }

    public BigDecimal getSumInvoiceAmt(){
     return sumInvoiceAmt;
    }
    public void setSumQtyHoldAmt(BigDecimal sumQtyHoldAmt){
            this.sumQtyHoldAmt = sumQtyHoldAmt;
    }
    
    public BigDecimal getSumQtyHoldAmt(){
     return sumQtyHoldAmt;
    }
    
    public void setSumPriceHoldAmt(BigDecimal sumPriceHoldAmt){
            this.sumPriceHoldAmt = sumPriceHoldAmt;
    }
    
    public BigDecimal getSumPriceHoldAmt(){
     return sumPriceHoldAmt;
    }
    
    public void calculateFooterTotals(){
            sumInvoiceAmt = new BigDecimal(0);
        sumQtyHoldAmt = new BigDecimal(0);
        sumPriceHoldAmt = new BigDecimal(0);
        
        
            RowSetIterator rsi = getViewObject().createRowSetIterator(null);
    while(rsi.hasNext()){
     VendMootDropshipDtVORowImpl  row = (VendMootDropshipDtVORowImpl)rsi.next();
    
    BigDecimal totalInvAmount = null;
    if (row.getInvoiceAmount() != null)
        totalInvAmount = new BigDecimal(row.getInvoiceAmount().toString());                
     
    if (totalInvAmount != null){
        sumInvoiceAmt = sumInvoiceAmt.add(totalInvAmount);
    }
    
    BigDecimal totalQtyHoldAmt = null;
    if (row.getQtyHoldAmt() != null)
        totalQtyHoldAmt = new BigDecimal(row.getQtyHoldAmt().toString());    
     
    if (totalQtyHoldAmt != null){
        sumQtyHoldAmt = sumQtyHoldAmt.add(totalQtyHoldAmt);
    }   

    BigDecimal totalPriceHoldAmt = null;
    if (row.getPriceHoldAmt() != null)
        totalPriceHoldAmt = new BigDecimal(row.getPriceHoldAmt().toString());    

    if (totalPriceHoldAmt != null){
        sumPriceHoldAmt = sumPriceHoldAmt.add(totalPriceHoldAmt);
    } 
    
   

        
    }
    rsi.reset();
    rsi.closeRowSetIterator();
    }

    /**
     * Returns the bind variable value for p_front_door.
     * @return bind variable value for p_front_door
     */
    public String getp_front_door() {
        return (String) getNamedWhereClauseParam("p_front_door");
    }

    /**
     * Sets <code>value</code> for bind variable p_front_door.
     * @param value value to bind as p_front_door
     */
    public void setp_front_door(String value) {
        setNamedWhereClauseParam("p_front_door", value);
    }

    /**
     * Returns the bind variable value for p_non_code.
     * @return bind variable value for p_non_code
     */
    public String getp_non_code() {
        return (String) getNamedWhereClauseParam("p_non_code");
    }

    /**
     * Sets <code>value</code> for bind variable p_non_code.
     * @param value value to bind as p_non_code
     */
    public void setp_non_code(String value) {
        setNamedWhereClauseParam("p_non_code", value);
    }

    /**
     * Returns the bind variable value for p_drop_ship.
     * @return bind variable value for p_drop_ship
     */
    public String getp_drop_ship() {
        return (String) getNamedWhereClauseParam("p_drop_ship");
    }

    /**
     * Sets <code>value</code> for bind variable p_drop_ship.
     * @param value value to bind as p_drop_ship
     */
    public void setp_drop_ship(String value) {
        setNamedWhereClauseParam("p_drop_ship", value);
    }

    /**
     * Returns the bind variable value for p_all_excpt.
     * @return bind variable value for p_all_excpt
     */
    public String getp_all_excpt() {
        return (String) getNamedWhereClauseParam("p_all_excpt");
    }

    /**
     * Sets <code>value</code> for bind variable p_all_excpt.
     * @param value value to bind as p_all_excpt
     */
    public void setp_all_excpt(String value) {
        setNamedWhereClauseParam("p_all_excpt", value);
    }

    /**
     * Returns the bind variable value for p_org_id.
     * @return bind variable value for p_org_id
     */
    public Number getp_org_id() {
        return (Number) getNamedWhereClauseParam("p_org_id");
    }

    /**
     * Sets <code>value</code> for bind variable p_org_id.
     * @param value value to bind as p_org_id
     */
    public void setp_org_id(Number value) {
        setNamedWhereClauseParam("p_org_id", value);
    }

    /**
     * Returns the bind variable value for p_invoice_num.
     * @return bind variable value for p_invoice_num
     */
    public String getp_invoice_num() {
        return (String) getNamedWhereClauseParam("p_invoice_num");
    }

    /**
     * Sets <code>value</code> for bind variable p_invoice_num.
     * @param value value to bind as p_invoice_num
     */
    public void setp_invoice_num(String value) {
        setNamedWhereClauseParam("p_invoice_num", value);
    }

    /**
     * Returns the bind variable value for p_ponum.
     * @return bind variable value for p_ponum
     */
    public String getp_ponum() {
        return (String) getNamedWhereClauseParam("p_ponum");
    }

    /**
     * Sets <code>value</code> for bind variable p_ponum.
     * @param value value to bind as p_ponum
     */
    public void setp_ponum(String value) {
        setNamedWhereClauseParam("p_ponum", value);
    }

    /**
     * Returns the bind variable value for p_fr_invdate.
     * @return bind variable value for p_fr_invdate
     */
    public Date getp_fr_invdate() {
        return (Date) getNamedWhereClauseParam("p_fr_invdate");
    }

    /**
     * Sets <code>value</code> for bind variable p_fr_invdate.
     * @param value value to bind as p_fr_invdate
     */
    public void setp_fr_invdate(Date value) {
        setNamedWhereClauseParam("p_fr_invdate", value);
    }

    /**
     * Returns the bind variable value for p_to_invdate.
     * @return bind variable value for p_to_invdate
     */
    public Date getp_to_invdate() {
        return (Date) getNamedWhereClauseParam("p_to_invdate");
    }

    /**
     * Sets <code>value</code> for bind variable p_to_invdate.
     * @param value value to bind as p_to_invdate
     */
    public void setp_to_invdate(Date value) {
        setNamedWhereClauseParam("p_to_invdate", value);
    }

    /**
     * Returns the bind variable value for p_vend_name.
     * @return bind variable value for p_vend_name
     */
    public String getp_vend_name() {
        return (String) getNamedWhereClauseParam("p_vend_name");
    }

    /**
     * Sets <code>value</code> for bind variable p_vend_name.
     * @param value value to bind as p_vend_name
     */
    public void setp_vend_name(String value) {
        setNamedWhereClauseParam("p_vend_name", value);
    }

    /**
     * Returns the bind variable value for p_vend_no.
     * @return bind variable value for p_vend_no
     */
    public String getp_vend_no() {
        return (String) getNamedWhereClauseParam("p_vend_no");
    }

    /**
     * Sets <code>value</code> for bind variable p_vend_no.
     * @param value value to bind as p_vend_no
     */
    public void setp_vend_no(String value) {
        setNamedWhereClauseParam("p_vend_no", value);
    }

    /**
     * Returns the bind variable value for p_vend_site.
     * @return bind variable value for p_vend_site
     */
    public String getp_vend_site() {
        return (String) getNamedWhereClauseParam("p_vend_site");
    }

    /**
     * Sets <code>value</code> for bind variable p_vend_site.
     * @param value value to bind as p_vend_site
     */
    public void setp_vend_site(String value) {
        setNamedWhereClauseParam("p_vend_site", value);
    }

    /**
     * Returns the bind variable value for p_vend_ast.
     * @return bind variable value for p_vend_ast
     */
    public String getp_vend_ast() {
        return (String) getNamedWhereClauseParam("p_vend_ast");
    }

    /**
     * Sets <code>value</code> for bind variable p_vend_ast.
     * @param value value to bind as p_vend_ast
     */
    public void setp_vend_ast(String value) {
        setNamedWhereClauseParam("p_vend_ast", value);
    }

    /**
     * Returns the bind variable value for p_source.
     * @return bind variable value for p_source
     */
    public String getp_source() {
        return (String) getNamedWhereClauseParam("p_source");
    }

    /**
     * Sets <code>value</code> for bind variable p_source.
     * @param value value to bind as p_source
     */
    public void setp_source(String value) {
        setNamedWhereClauseParam("p_source", value);
    }

    /**
     * Returns the bind variable value for p_due_fdate.
     * @return bind variable value for p_due_fdate
     */
    public Date getp_due_fdate() {
        return (Date) getNamedWhereClauseParam("p_due_fdate");
    }

    /**
     * Sets <code>value</code> for bind variable p_due_fdate.
     * @param value value to bind as p_due_fdate
     */
    public void setp_due_fdate(Date value) {
        setNamedWhereClauseParam("p_due_fdate", value);
    }

    /**
     * Returns the bind variable value for p_due_tdate.
     * @return bind variable value for p_due_tdate
     */
    public Date getp_due_tdate() {
        return (Date) getNamedWhereClauseParam("p_due_tdate");
    }

    /**
     * Sets <code>value</code> for bind variable p_due_tdate.
     * @param value value to bind as p_due_tdate
     */
    public void setp_due_tdate(Date value) {
        setNamedWhereClauseParam("p_due_tdate", value);
    }


    /**
     * Returns the bind variable value for p_moot.
     * @return bind variable value for p_moot
     */
    public String getp_moot() {
        return (String) getNamedWhereClauseParam("p_moot");
    }

    /**
     * Sets <code>value</code> for bind variable p_moot.
     * @param value value to bind as p_moot
     */
    public void setp_moot(String value) {
        setNamedWhereClauseParam("p_moot", value);
    }

    /**
     * Returns the bind variable value for p_nrf.
     * @return bind variable value for p_nrf
     */
    public String getp_nrf() {
        return (String) getNamedWhereClauseParam("p_nrf");
    }

    /**
     * Sets <code>value</code> for bind variable p_nrf.
     * @param value value to bind as p_nrf
     */
    public void setp_nrf(String value) {
        setNamedWhereClauseParam("p_nrf", value);
    }

    /**
     * Returns the bind variable value for p_qty_expt.
     * @return bind variable value for p_qty_expt
     */
    public String getp_qty_expt() {
        return (String) getNamedWhereClauseParam("p_qty_expt");
    }

    /**
     * Sets <code>value</code> for bind variable p_qty_expt.
     * @param value value to bind as p_qty_expt
     */
    public void setp_qty_expt(String value) {
        setNamedWhereClauseParam("p_qty_expt", value);
    }

    /**
     * Returns the bind variable value for p_price_expt.
     * @return bind variable value for p_price_expt
     */
    public String getp_price_expt() {
        return (String) getNamedWhereClauseParam("p_price_expt");
    }

    /**
     * Sets <code>value</code> for bind variable p_price_expt.
     * @param value value to bind as p_price_expt
     */
    public void setp_price_expt(String value) {
        setNamedWhereClauseParam("p_price_expt", value);
    }
}

