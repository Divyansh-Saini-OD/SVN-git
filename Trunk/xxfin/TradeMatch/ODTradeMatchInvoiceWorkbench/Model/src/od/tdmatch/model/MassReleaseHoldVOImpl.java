package od.tdmatch.model;

import java.math.BigDecimal;

import oracle.jbo.RowSetIterator;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ViewObjectImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Thu Jun 22 09:58:38 EDT 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class MassReleaseHoldVOImpl extends ViewObjectImpl {
    /**
     * This is the default constructor (do not remove).
     */
    public MassReleaseHoldVOImpl() {
    }
    private BigDecimal sumInvoiceAmount=null;
    private BigDecimal sumQtyHoldAmount=null;
    private BigDecimal sumPriceHoldAmount=null;

    @Override
    protected void executeQueryForCollection(Object object, Object[] object2, int i) {
        // TODO Implement this method
        super.executeQueryForCollection(object, object2, i);
        calculateSumTaotals();
    }

    public void setSumInvoiceAmount(BigDecimal sumInvoiceAmount) {
        this.sumInvoiceAmount = sumInvoiceAmount;
    }

    public BigDecimal getSumInvoiceAmount() {
        return sumInvoiceAmount;
    }

    public void setSumQtyHoldAmount(BigDecimal sumQtyHoldAmount) {
        this.sumQtyHoldAmount = sumQtyHoldAmount;
    }

    public BigDecimal getSumQtyHoldAmount() {
        return sumQtyHoldAmount;
    }

    public void setSumPriceHoldAmount(BigDecimal sumPriceHoldAmount) {
        this.sumPriceHoldAmount = sumPriceHoldAmount;
    }

    public BigDecimal getSumPriceHoldAmount() {
        return sumPriceHoldAmount;
    }
    
    public void calculateSumTaotals(){
             sumInvoiceAmount=new BigDecimal(0);
             sumQtyHoldAmount=new BigDecimal(0);
             sumPriceHoldAmount=new BigDecimal(0);
        RowSetIterator rsIter=this.getViewObject().createRowSetIterator(null);
        while(rsIter.hasNext()){
            MassReleaseHoldVORowImpl row=(MassReleaseHoldVORowImpl)rsIter.next();
            if(row.getInvoiceAmount()!=null){
            BigDecimal totalInvAmount=new BigDecimal(row.getInvoiceAmount().toString());
            if(totalInvAmount!=null){
                sumInvoiceAmount=sumInvoiceAmount.add(totalInvAmount);
            }
            BigDecimal qtyHoldAmount=new BigDecimal(row.getQtyHoldAmt().toString());
            if(qtyHoldAmount!=null){
                sumQtyHoldAmount=sumQtyHoldAmount.add(qtyHoldAmount);
            }
            BigDecimal priceHoldAmount=new BigDecimal(row.getPriceHoldAmt().toString());
            if(priceHoldAmount!=null){
                sumPriceHoldAmount=sumPriceHoldAmount.add(priceHoldAmount);
            }
            }
            
        }
        rsIter.reset();
        rsIter.closeRowSetIterator();
            
        }
    
}

