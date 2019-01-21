package od.tdmatch.model.reports.am.common;

import java.util.HashMap;

import oracle.jbo.ApplicationModule;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Mon Dec 11 15:44:56 IST 2017
// ---------------------------------------------------------------------
public interface ODTradeMatchReportsAM extends ApplicationModule {
    String searchDrillDownChargebk(HashMap trMaCashBkSearchMap);

    String searchTraMatChargebk(HashMap trMaCashBkSearchMap);

    String searchDtlChargebk(HashMap trMaCashBkSearchMap);

    String searchRTVRecon();

    String searchInvoicePaymentInq(HashMap trMaInvoicePaymentMap);

    String searchInvoicePaymentInqItem(HashMap trMaInvoicePaymentMap);

    String searchMatchAnalysis(HashMap trMaMatchAnalysisMap);

    String searchMatchAnalysisEmp(HashMap trMaMatchAnalysisMap);

    String searchMatchAnalysisVendAss(HashMap trMaMatchAnalysisMap);


    void clearPoDetails();

    String getInvPopUp(oracle.jbo.domain.Number poHdrId, oracle.jbo.domain.Number poLineId);


    String getRecPopUp(oracle.jbo.domain.Number poLineId);

    String getWriteoffPopUp(oracle.jbo.domain.Number poHdrId, oracle.jbo.domain.Number poLineId);

    String searchInvoiceNum(HashMap invNumMap);


    String searchMatchRateData(HashMap matchRateMap);

    String searchReceiptDetailInquiry(int userId);


    String searchReasonCodeDtl(String sku);

    String searchReasonCodeSumm(String sku);

    String searchPoInquiry(String poNum, int orgId, HashMap poTypeMap);

    String getPoLines(oracle.jbo.domain.Number poHdrId, String poNum);

    String searchConsignRTV(String sku);

    String searchReceiptDetInqConReq(int userId);

    String searchTraMatDedInq(HashMap trMaDedInqSearchMap);

    String searchTraMatDedDtlInq(HashMap trMaDedInqSearchMap);

    String searchTraMatNonDedInq(HashMap trMaNonDedInqSearchMap);
}

