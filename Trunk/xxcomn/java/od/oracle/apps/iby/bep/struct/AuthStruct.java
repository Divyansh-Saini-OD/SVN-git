package od.oracle.apps.iby.bep.struct;

import java.math.BigDecimal;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * This AuthStruct java class contains all the request parameters from 
 * ipayment and it's accessor methods
 * @author     
 * @version     1.0
 * @date        14-Sep-2007     Creation Date
 *              29-May-2008     Defect 6635
 **/
public class

AuthStruct {

    // Input values from the IPayment

    private String Action;
    private String OrderId;
    private String Price;
    private String Curr;
    private String AuthType;
    private String PmtInstrID;
    private String PmtInstrExp;
    private String StoreId;
    private String CustName;
    private String Addr1;
    private String Addr2;
    private String Addr3;
    private String City;
    private String State;
    private String Country;
    private String PostalCode;
    private String Phone;
    private String Email;
    private String Retry;
    private String NlsLang;
    private String VpsBatchId;

    // output values to iPayment

    private String TrxnType;
    private String Status;
    private String Authcode;
    private String TrxnDate;
    private String PmtInstrType;
    private String ErrLocation;
    private String VendErrCode;
    private String VendErrmsg;
    private String Acquirer;
    private String Refcode;
    private String AVScode;
    private String AuxMsg;

    // Generate Accessor for the above fields

    public void setAction(String action) {
        this.Action = action;
    }

    public String getAction() {
        return Action;
    }

    public void setOrderId(String orderId) {
        this.OrderId = orderId;
    }

    public String getOrderId() {
        return OrderId;
    }

    public void setPrice(String price) {
        this.Price = price;
    }

    public String getPrice() {
        return Price;
    }

    public void setCurrency(String curr) {
        this.Curr = curr;
    }

    public String getCurrency() {
        return Curr;
    }

    public void setAuthType(String authType) {
        this.AuthType = authType;
    }

    public String getAuthType() {
        return AuthType;
    }

    public void setPmtInstrID(String pmtInstrID) {
        this.PmtInstrID = pmtInstrID;
    }

    public String getPmtInstrID() {
        return PmtInstrID;
    }

    public void setPmtInstrExp(String pmtInstrExp) {
        this.PmtInstrExp = pmtInstrExp;
    }

    public String getPmtInstrExp() {
        return PmtInstrExp;
    }

    public void setStoreId(String storeId) {
        this.StoreId = storeId;
    }

    public String getStoreId() {
        return StoreId;
    }

    public void setCustName(String custName) {
        this.CustName = custName;
    }

    public String getCustName() {
        return CustName;
    }

    public void setAddr1(String addr1) {
        this.Addr1 = addr1;
    }

    public String getAddr1() {
        return Addr1;
    }

    public void setAddr2(String addr2) {
        this.Addr2 = addr2;
    }

    public String getAddr2() {
        return Addr2;
    }

    public void setAddr3(String addr3) {
        this.Addr3 = addr3;
    }

    public String getAddr3() {
        return Addr3;
    }

    public void setCity(String city) {
        this.City = city;
    }

    public String getCity() {
        return City;
    }

    public void setState(String state) {
        this.State = state;
    }

    public String getState() {
        return State;
    }

    public void setCountry(String country) {
        this.Country = country;
    }

    public String getCountry() {
        return Country;
    }

    public void setPostalCode(String postalCode) {
        this.PostalCode = postalCode;
    }

    public String getPostalCode() {
        return PostalCode;
    }

    public void setPhone(String phone) {
        this.Phone = phone;
    }

    public String getPhone() {
        return Phone;
    }

    public void setEmail(String email) {
        this.Email = email;
    }

    public String getEmail() {
        return Email;
    }

    public String setRetry(String retry) {
        this.Retry = retry;
        return Retry;
    }

    public String getRetry() {
        return Retry;
    }

    public void setNlsLang(String nlsLang) {
        this.NlsLang = nlsLang;
    }

    public String getNlsLang() {
        return NlsLang;
    }

    public void setTrxnType(String trxnType) {
        this.TrxnType = trxnType;
    }

    public String getTrxnType() {
        return TrxnType;
    }

    public void setStatus(String status) {
        this.Status = status;
    }

    public String getStatus() {
        return Status;
    }

    public void setAuthcode(String authcode) {
        this.Authcode = authcode;
    }

    public String getAuthcode() {
        return Authcode;
    }

    public void setTrxnDate(String trxnDate) {
        this.TrxnDate = trxnDate;
    }

    public String getTrxnDate() {
        return TrxnDate;
    }

    public void setPmtInstrType(String pmtInstrType) {
        this.PmtInstrType = pmtInstrType;
    }

    public String getPmtInstrType() {
        return PmtInstrType;
    }

    public void setErrLocation(String errLocation) {
        this.ErrLocation = errLocation;
    }

    public String getErrLocation() {
        return ErrLocation;
    }

    public void setVendErrCode(String vendErrCode) {
        this.VendErrCode = vendErrCode;
    }

    public String getVendErrCode() {
        return VendErrCode;
    }

    public void setVendErrmsg(String vendErrmsg) {
        this.VendErrmsg = vendErrmsg;
    }

    public String getVendErrmsg() {
        return VendErrmsg;
    }

    public void setAcquirer(String acquirer) {
        this.Acquirer = acquirer;
    }

    public String getAcquirer() {
        return Acquirer;
    }

    public void setRefcode(String refcode) {
        this.Refcode = refcode;
    }

    public String getRefcode() {
        return Refcode;
    }

    public void setAVScode(String aVScode) {
        this.AVScode = aVScode;
    }

    public String getAVScode() {
        return AVScode;
    }

    public void setAuxMsg(String auxMsg) {
        this.AuxMsg = auxMsg;
    }

    public String getAuxMsg() {
        return AuxMsg;
    }

    public void setVpsBatchId(String vpsBatchId) {
        this.VpsBatchId = vpsBatchId;
    }

    public String getVpsBatchId() {
        return VpsBatchId;
    }

    // Get the Terminalvalue from the ipayment

    public String getTerminalValue() {

        Pattern sTerValue1= Pattern.compile("ARI");
        Pattern sTerValue2 = Pattern.compile("IEX");

        Matcher sMatValue1 = sTerValue1.matcher(getOrderId());
        Matcher sMatValue2 = sTerValue2.matcher(getOrderId());

        String value = "";

        if (sMatValue1.find()) {
           // value="IR_55";
            value = "55";
        } else if (sMatValue2.find()) {
           //value="AC_56";
            value = "56";
        }
        return value;
    }

        
    // Get the price value

    public String getPriceValue() {

        String sPrice = getPrice();
        String sVal = null;
        String sConvPrice = null;

        try {

            // Defect 6635
            BigDecimal oPrice = new BigDecimal(sPrice);
            BigDecimal oMul = new BigDecimal("100.00");
            BigDecimal oPriceValue = oPrice.multiply(oMul);
      
            sConvPrice = oPriceValue.toString();
            sVal = splitPrice(sConvPrice);

        } catch (NumberFormatException nfe) {
            System.out.println("NumberFormatException: " + nfe.getMessage());
        }
        return sVal;
    }

    // Spliting the price value

    public String splitPrice(String sPrice) {
        String sPriceValue = sPrice;
     
        String[] sSplitVal = null;
        sSplitVal = sPriceValue.split("\\."); // \\.");

        String sPriceVal = getSplitedPrice(sSplitVal);
        return sPriceVal;
    }

    // Getting the splited value from the string array.

    public String getSplitedPrice(String[] sPriceVal) {
       
        String sValue = null;
        String v1 = null;
        for (int iCrn = 0; iCrn < sPriceVal.length; ) {
            sValue = sPriceVal[iCrn];  // getting the first value from the array
            iCrn++;
            v1 = sPriceVal[iCrn++];  // getting the second value from the array
       }
        
       return sValue;
    }


    // Formatting the Date

       public String formatDate() {
           String sPmtInstrDate = getPmtInstrExp();
          
           String[] sSplitValue = null;
           sSplitValue = sPmtInstrDate.split("/"); //  12/14 \\.");
         
           String sDateValue = splitDate(sSplitValue);
           return sDateValue;
       }

       // Spliting the given Date and returning in 'YYMM' format

       public String splitDate(String[] sDateVal) {
          
           String sFirstDate = null;
           String sSecondDate = null;
           for (int iCnr = 0; iCnr < sDateVal.length; ) {
               System.out.println(sDateVal[iCnr]);
               sFirstDate = sDateVal[iCnr];  // getting the first value from the array
               iCnr++;
               sSecondDate = sDateVal[iCnr++];  // getting the second value from the array
           }
           return sSecondDate + sFirstDate;
       }

}
