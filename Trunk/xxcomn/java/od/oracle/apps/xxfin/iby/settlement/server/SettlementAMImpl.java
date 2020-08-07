package od.oracle.apps.xxfin.iby.settlement.server;


import od.oracle.apps.xxfin.iby.settlement.lov.XxIbyOrderTypeLovVOImpl;
import od.oracle.apps.xxfin.iby.settlement.lov.XxIbyTransTypeLovVOImpl;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;


// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class SettlementAMImpl extends OAApplicationModuleImpl {
    /**This is the default constructor (do not remove)
     */
    public SettlementAMImpl() {
    }

    /**Sample main for debugging Business Components code using the tester.
     */
    public static void main(String[] args) {
        launchTester("od.oracle.apps.xxfin.iby.settlement.server", /* package name */
      "SettlementAMLocal" /* Configuration Name */);
    }
    
    public void initIbyBatchTrxnsHistory( String lsLowDate, String lsHighDate, 
                                    String lsRecptNum, String lsStoreNum, 
                                    String lsRegNum, String lsTrxNum,
                                    String lsBatchNum, String lsDollarAmt, 
                                    String lsTrxType, String lsOrdType){
                                    
            System.out.println("--In AMimpl--");                                    
            System.out.println("lsLowDate: " + lsLowDate);                                    
                                        System.out.println("lsHighDate: " + lsHighDate);                                    
                                        System.out.println("lsRecptNum: " + lsRecptNum);                                    
                                        System.out.println("lsStoreNum: " + lsStoreNum);                                    
                                        System.out.println("lsRegNum: " + lsRegNum);                                    
                                        System.out.println("lsTrxNum: " + lsTrxNum);                                    
                                        System.out.println("lsBatchNum: " + lsBatchNum);                                    
                                        System.out.println("lsDollarAmt: " + lsDollarAmt);                                    
                                        System.out.println("lsTrxType: " + lsTrxType);                                    
                                        System.out.println("lsOrdType: " + lsOrdType);                                    
                                    
                            XxIbyBatchTrxnsHistoryVOImpl vo=        getXxIbyBatchTrxnsHistoryVO1();
                                  vo.initIbyBatchTrxnsHistory(  lsLowDate,  lsHighDate, 
                                     lsRecptNum,  lsStoreNum, 
                                     lsRegNum,  lsTrxNum,
                                     lsBatchNum,  lsDollarAmt, 
                                     lsTrxType, lsOrdType);
                                    }


    /**Container's getter for XxIbyBatchTrxns201HistoryVO1
     */
    public XxIbyBatchTrxns201HistoryVOImpl getXxIbyBatchTrxns201HistoryVO1() {
        return (XxIbyBatchTrxns201HistoryVOImpl)findViewObject("XxIbyBatchTrxns201HistoryVO1");
    }


    /**Container's getter for XxIbyOrderTypeLovVO1
     */
    public XxIbyOrderTypeLovVOImpl getXxIbyOrderTypeLovVO1() {
        return (XxIbyOrderTypeLovVOImpl)findViewObject("XxIbyOrderTypeLovVO1");
    }


    /**Container's getter for XxIbyBatchTrxnsHistoryVO1
     */
    public XxIbyBatchTrxnsHistoryVOImpl getXxIbyBatchTrxnsHistoryVO1() {
        return (XxIbyBatchTrxnsHistoryVOImpl)findViewObject("XxIbyBatchTrxnsHistoryVO1");
    }

    /**Container's getter for XxIbyTransTypeLovVO1
     */
    public XxIbyTransTypeLovVOImpl getXxIbyTransTypeLovVO1() {
        return (XxIbyTransTypeLovVOImpl)findViewObject("XxIbyTransTypeLovVO1");
    }

    /**Container's getter for XxIbyBatchTrxHistDetailsVO1
     */
    public XxIbyBatchTrxHistDetailsVOImpl getXxIbyBatchTrxHistDetailsVO1() {
        return (XxIbyBatchTrxHistDetailsVOImpl)findViewObject("XxIbyBatchTrxHistDetailsVO1");
    }
}
