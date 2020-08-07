package od.tdmatch.model;

import java.math.BigDecimal;

import java.sql.ResultSet;

import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.server.ViewObjectImpl;
import oracle.jbo.server.ViewRowImpl;
import oracle.jbo.server.ViewRowSetImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Tue May 23 09:21:27 EDT 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class VAInvoiceSummaryVOImpl extends ViewObjectImpl {
    /**
     * This is the default constructor (do not remove).
     */
    public VAInvoiceSummaryVOImpl() {
    }

    //    @Override


    private BigDecimal sumInvoiceAmt;
    private BigDecimal sumInvoiceCount;
    private BigDecimal sumInvoiceLineAmt;
    private BigDecimal sumMootCount;
    private BigDecimal sumMootInvoiceAmt;
    private BigDecimal sumMootLineAmt;
    private BigDecimal sumNrfCount;
    private BigDecimal sumNrfAmt;

    public void setSumInvoiceAmt(BigDecimal sumInvoiceAmt) {
        this.sumInvoiceAmt = sumInvoiceAmt;
    }

    public BigDecimal getSumInvoiceAmt() {
        return sumInvoiceAmt;
    }

    public void setSumInvoiceCount(BigDecimal sumInvoiceCount) {
        this.sumInvoiceCount = sumInvoiceCount;
    }

    public BigDecimal getSumInvoiceCount() {
        return sumInvoiceCount;
    }

    public void setSumInvoiceLineAmt(BigDecimal sumInvoiceLineAmt) {
        this.sumInvoiceLineAmt = sumInvoiceLineAmt;
    }

    public BigDecimal getSumInvoiceLineAmt() {
        return sumInvoiceLineAmt;
    }

    public void setSumMootCount(BigDecimal sumMootCount) {
        this.sumMootCount = sumMootCount;
    }

    public BigDecimal getSumMootCount() {
        return sumMootCount;
    }

    public void setSumMootInvoiceAmt(BigDecimal sumMootInvoiceAmt) {
        this.sumMootInvoiceAmt = sumMootInvoiceAmt;
    }

    public BigDecimal getSumMootInvoiceAmt() {
        return sumMootInvoiceAmt;
    }

    public void setSumMootLineAmt(BigDecimal sumMootLineAmt) {
        this.sumMootLineAmt = sumMootLineAmt;
    }

    public BigDecimal getSumMootLineAmt() {
        return sumMootLineAmt;
    }

    public void setSumNrfCount(BigDecimal sumNrfCount) {
        this.sumNrfCount = sumNrfCount;
    }

    public BigDecimal getSumNrfCount() {
        return sumNrfCount;
    }

    public void setSumNrfAmt(BigDecimal sumNrfAmt) {
        this.sumNrfAmt = sumNrfAmt;
    }

    public BigDecimal getSumNrfAmt() {
        return sumNrfAmt;
    }

    public void executeQuery() {
        super.executeQuery();
        this.calculateFooterTotals();
    }


    public void calculateFooterTotals() {
        sumInvoiceAmt = new BigDecimal(0);
        sumInvoiceCount = new BigDecimal(0);
        sumInvoiceLineAmt = new BigDecimal(0);
        sumMootCount = new BigDecimal(0);
        sumMootInvoiceAmt = new BigDecimal(0);
        sumMootLineAmt = new BigDecimal(0);
        sumNrfCount = new BigDecimal(0);
        sumNrfAmt = new BigDecimal(0);
        RowSetIterator rsi = getViewObject().createRowSetIterator(null);
        while (rsi.hasNext()) {
            VAInvoiceSummaryVORowImpl row = (VAInvoiceSummaryVORowImpl) rsi.next();
            
            BigDecimal totalInvAmount = null;
            if (row.getTotalInvAmount() != null)
                totalInvAmount = new BigDecimal(row.getTotalInvAmount().toString());
            if (totalInvAmount != null) {
                sumInvoiceAmt = sumInvoiceAmt.add(totalInvAmount);
            }

            BigDecimal totalInvCount = null;
            if (row.getTotalInvCount() != null)
                totalInvCount = new BigDecimal(row.getTotalInvCount().toString());
                        
            if (totalInvCount != null) {
                sumInvoiceCount = sumInvoiceCount.add(totalInvCount);
            }

            BigDecimal totalLineAmount = null;
            if (row.getTotalLineAmount() != null)
                totalLineAmount = new BigDecimal(row.getTotalLineAmount().toString());
             
            if (totalLineAmount != null) {
                sumInvoiceLineAmt = sumInvoiceLineAmt.add(totalLineAmount);
            }

            BigDecimal totalMootCount = null;
            if (row.getTotalMootCount() != null)
                totalMootCount = new BigDecimal(row.getTotalMootCount().toString());
             
            if (totalMootCount != null) {
                sumMootCount = sumMootCount.add(totalMootCount);
            }


            BigDecimal totalMootInvAmount = null;
            if (row.getTotalMootInvAmount() != null)
                totalMootInvAmount = new BigDecimal(row.getTotalMootInvAmount().toString());
            if (totalMootInvAmount != null) {
                sumMootInvoiceAmt = sumMootInvoiceAmt.add(totalMootInvAmount);
            }

            BigDecimal totalMootLineAmount = null;
            if (row.getTotalMootLineAmount() != null)
                totalMootLineAmount = new BigDecimal(row.getTotalMootLineAmount().toString());

            
            if (totalMootLineAmount != null) {
                sumMootLineAmt = sumMootLineAmt.add(totalMootLineAmount);
            }

            BigDecimal totalNrfCount = null;
            if (row.getTotalNrfCount() != null)
                totalNrfCount = new BigDecimal(row.getTotalNrfCount().toString());
            
            if (totalNrfCount != null) {
                sumNrfCount = sumNrfCount.add(totalNrfCount);
            }

            
            BigDecimal totalNrfAmount = null;
            if (row.getTotalNrfAmount() != null)
                totalNrfAmount = new BigDecimal(row.getTotalNrfAmount().toString());
                        
            if (totalNrfAmount != null) {
                sumNrfAmt = sumNrfAmt.add(totalNrfAmount);
            }


        }
        rsi.reset();
        rsi.closeRowSetIterator();
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
}

