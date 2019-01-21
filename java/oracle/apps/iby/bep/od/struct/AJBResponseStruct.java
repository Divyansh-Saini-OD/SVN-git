package oracle.apps.iby.bep.od.struct;


 /**
  * This AJBResponseStruct java class contains all the AJB response parameters and 
  * it's set and get methods  
  * @author     
  * @version     1.0
  * @date        14-Sep-2007
  **/
  
public class AJBResponseStruct {

    // output fields from AJB
    
    private String IxTransactionType;
    private String IxActionCode;
    private String IxTimeOut;
    private String IxDebitCredit; // Credit card No
    private String IxStoreNumber;
    private String IxTerminalNumber;
    private String IxTranType;
    private String IxAccount;
    private String IxExpDate;
    private String IxSwipe;
    private String IxAmount;
    private String IxInvoice;
    private String IxOptions;
    private String IxIssueNumber;
    private String IxMailOrderAVSData;
    private String IxPosEchoField;
    private String IxAuthCode;
    private String IxReceiptDisplay;
    private String IxCrMerchant;
    private String IxDbMerchant;
    private String IxDefaultTimeout;
    private String IxRetCode;
    private String IxPS2000;
    private String IxRefNumber;
    private String IxDate;
    private String IxTime;
    private String IxDepositData;
    private String IxIsoResp;
    private String IxBankNodeID;
    private String IxAuthResponseTime;
// Added below line for Defect 2549
    private String IxCardType;

    /**
     * Defalut Constructor
    **/
     
    public AJBResponseStruct() {
        IxAuthCode = null;
        IxTransactionType = null;
        IxActionCode = null;
        IxTimeOut = null;
        IxDebitCredit = null;
        IxStoreNumber = null;
        IxTerminalNumber = null;
        IxTranType = null;
        IxAccount = null;
        IxExpDate = null;
        IxSwipe = null;
        IxAmount = null;
        IxInvoice = null;
        IxOptions = null;
        IxIssueNumber = null;
        IxMailOrderAVSData = null;
        IxPosEchoField = null;
        IxReceiptDisplay = null;
        IxCrMerchant = null;
        IxDbMerchant = null;
        IxDefaultTimeout = null;
        IxRetCode = null;
        IxPS2000 = null;
        IxRefNumber = null;
        IxDate = null;
        IxTime = null;
        IxDepositData = null;
        IxIsoResp = null;
        IxBankNodeID = null;
        IxAuthResponseTime = null;
// Added below line for Defect 2549
        IxCardType = null;
    }

    // Generate Accessors for the AJB Response fields

    public void setIxTransactionType(String ixTransactionType) {
        this.IxTransactionType = ixTransactionType;
    }

    public String getIxTransactionType() {
        return IxTransactionType;
    }

    public void setIxActionCode(String ixActionCode) {
        this.IxActionCode = ixActionCode;
    }

    public String getIxActionCode() {
        return IxActionCode;
    }

    public void setIxDebitCredit(String ixDebitCredit) {
        this.IxDebitCredit = ixDebitCredit;
    }

    public String getIxDebitCredit() {
        return IxDebitCredit;
    }

    public void setIxStoreNumber(String ixStoreNumber) {
        this.IxStoreNumber = ixStoreNumber;
    }

    public String getIxStoreNumber() {
        return IxStoreNumber;
    }

    public void setIxTerminalNumber(String ixTerminalNumber) {
        this.IxTerminalNumber = ixTerminalNumber;
    }

    public String getIxTerminalNumber() {
        return IxTerminalNumber;
    }

    public void setIxTranType(String ixTranType) {
        this.IxTranType = ixTranType;
    }

    public String getIxTranType() {
        return IxTranType;
    }

    public void setIxAccount(String ixAccount) {
        this.IxAccount = ixAccount;
    }

    public String getIxAccount() {
        return IxAccount;
    }

    public void setIxExpDate(String ixExpDate) {
        this.IxExpDate = ixExpDate;
    }

    public String getIxExpDate() {
        return IxExpDate;
    }

    public void setIxSwipe(String ixSwipe) {
        this.IxSwipe = ixSwipe;
    }

    public String getIxSwipe() {
        return IxSwipe;
    }

    public void setIxAmount(String ixAmount) {
        this.IxAmount = ixAmount;
    }

    public String getIxAmount() {
        return IxAmount;
    }

    public void setIxInvoice(String ixInvoice) {
        this.IxInvoice = ixInvoice;
    }

    public String getIxInvoice() {
        return IxInvoice;
    }

    public void setIxOptions(String ixOptions) {
        this.IxOptions = ixOptions;
    }

    public String getIxOptions() {
        return IxOptions;
    }

    public void setIxIssueNumber(String ixIssueNumber) {
        this.IxIssueNumber = ixIssueNumber;
    }

    public String getIxIssueNumber() {
        return IxIssueNumber;
    }

    public void setIxMailOrderAVSData(String ixMailOrderAVSData) {
        this.IxMailOrderAVSData = ixMailOrderAVSData;
    }

    public String getIxMailOrderAVSData() {
        return IxMailOrderAVSData;
    }

    public void setIxPosEchoField(String ixPosEchoField) {
        this.IxPosEchoField = ixPosEchoField;
    }

    public String getIxPosEchoField() {
        return IxPosEchoField;
    }

    public void setIxReceiptDisplay(String ixReceiptDisplay) {
        this.IxReceiptDisplay = ixReceiptDisplay;
    }

    public String getIxReceiptDisplay() {
        return IxReceiptDisplay;
    }

    public void setIxCrMerchant(String ixCrMerchant) {
        this.IxCrMerchant = ixCrMerchant;
    }

    public String getIxCrMerchant() {
        return IxCrMerchant;
    }

    public void setIxDbMerchant(String ixDbMerchant) {
        this.IxDbMerchant = ixDbMerchant;
    }

    public String getIxDbMerchant() {
        return IxDbMerchant;
    }

    public void setIxDefaultTimeout(String ixDefaultTimeout) {
        this.IxDefaultTimeout = ixDefaultTimeout;
    }

    public String getIxDefaultTimeout() {
        return IxDefaultTimeout;
    }

    public void setIxRetCode(String ixRetCode) {
        this.IxRetCode = ixRetCode;
    }

    public String getIxRetCode() {
        return IxRetCode;
    }

    public void setIxPS2000(String ixPS2000) {
        this.IxPS2000 = ixPS2000;
    }

    public String getIxPS2000() {
        return IxPS2000;
    }

    public void setIxRefNumber(String ixRefNumber) {
        this.IxRefNumber = ixRefNumber;
    }

    public String getIxRefNumber() {
        return IxRefNumber;
    }

    public void setIxDate(String ixDate) {
        this.IxDate = ixDate;
    }

    public String getIxDate() {
        return IxDate;
    }

    public void setIxTime(String ixTime) {
        this.IxTime = ixTime;
    }

    public String getIxTime() {
        return IxTime;
    }

    public void setIxDepositData(String ixDepositData) {
        this.IxDepositData = ixDepositData;
    }

    public String getIxDepositData() {
        return IxDepositData;
    }

    public void setIxIsoResp(String ixIsoResp) {
        this.IxIsoResp = ixIsoResp;
    }

    public String getIxIsoResp() {
        return IxIsoResp;
    }

    public void setIxBankNodeID(String ixBankNodeID) {
        this.IxBankNodeID = ixBankNodeID;
    }

    public String getIxBankNodeID() {
        return IxBankNodeID;
    }

    public void setIxAuthResponseTime(String ixAuthResponseTime) {
        this.IxAuthResponseTime = ixAuthResponseTime;
    }

    public String getIxAuthResponseTime() {
        return IxAuthResponseTime;
    }

    public void setIxTimeOut(String ixTimeOut) {
        this.IxTimeOut = ixTimeOut;
    }

    public String getIxTimeOut() {
        return IxTimeOut;
    }

    public void setIxAuthCode(String ixAuthCode) {
        this.IxAuthCode = ixAuthCode;
    }

    public String getIxAuthCode() {
        return IxAuthCode;
    }

// Added below set and get method for Card Type for Defect 2549
    public void setIxCardType(String ixCardType) {
        this.IxCardType = ixCardType;
    }

    public String getIxCardType() {
        return IxCardType;
    }

    // Forming the AJBResponse string as a Single string

    public String toAJBResponseString() {
        StringBuffer sAJBRespVal = new StringBuffer();

        sAJBRespVal.append(getIxTransactionType());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxActionCode());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxTimeOut());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxDebitCredit());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxStoreNumber());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxTerminalNumber());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxTranType());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxAccount());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxExpDate());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxSwipe());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxAmount());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxInvoice());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxOptions());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxIssueNumber());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxMailOrderAVSData());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxPosEchoField());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxAuthCode());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxReceiptDisplay());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxCrMerchant());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxDbMerchant());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxDefaultTimeout());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxRetCode());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxPS2000());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxRefNumber());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxDate());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxTime());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxDepositData());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxIsoResp());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxBankNodeID());
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxAuthResponseTime());
        // 2549 
        sAJBRespVal.append("_");
        sAJBRespVal.append(getIxCardType());

        return sAJBRespVal.toString();
    }

}