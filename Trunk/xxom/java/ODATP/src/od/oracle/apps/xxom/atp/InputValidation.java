/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |             Oracle NAIO/WIPRO/Office Depot/Consulting Organization        |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             InputValidation.java                                          |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This Class validates the input parameters received from the Source     |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class object will be used in AtpProcessControl.java               |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    06/19/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp;

import java.math.BigDecimal;

/**
 * Validation class performs necessary validation of the data.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 * 
 */
public class InputValidation {

    public static final String RCS_ID = 
        "$Header: InputValidation.java  06/19/2007 Satis-Gnanmani$";

    /**
     * Provides a default constructor
     * 
     */
    public InputValidation() {
    }

    private boolean isValid = true;
    private String errorMessage = "";
    private int errorCode = 0;
    private String returnStatus = "S";

    /**
     * Checks for valid output data from the input parameters.
     * 
     * @param atprec Object Type record of all necessary data
     * @return atprec Object Type record with validation results
     * 
     */
    public ATPRecordType validateInput(ATPRecordType atprec) {
        long start = System.currentTimeMillis();
        checkCustomerAttributes(atprec);
        checkDateAttributes(atprec);
        checkItemAttributes(atprec);
        checkOrgAttributes(atprec);
        setError(atprec);
        long stop = System.currentTimeMillis();
        System.out.println("Time for validate Input Procedure : " + 
                           Math.round((stop - start) * 0.001) + 
                           " Seconds");
        return atprec;
    }
    /**
     * Checks for valid output data from the preprocess execution.
     * 
     * @param atprec Object Type record of all necessary data
     * @return atprec Object Type record with validation results
     * 
     */
    public ATPRecordType checkPreprocessData(ATPRecordType atprec) {
        long start = System.currentTimeMillis();
        boolean remBaseOrgATP = false;
        boolean remAltOrgATP = false;
        boolean remXdockATP = false;
        boolean remForsubATP = false;
        int newarrLength = atprec.atpTypeCode.length;
        if (atprec.baseOrgId.equals(null)) {
            remBaseOrgATP = true;
        }
        if (atprec.xrefItemId == null) {
            remForsubATP = true;
        }
        for (int i = 0; i < atprec.atpTypeCode.length; i++) {
            if ((atprec.atpTypeCode[i].equals(ATPConstants.BASE_VALUE) && 
                 remBaseOrgATP) || 
                (atprec.atpTypeCode[i].equals(ATPConstants.ALT_VALUE) && 
                 remAltOrgATP) || 
                (atprec.atpTypeCode[i].equals(ATPConstants.XDOCK_VALUE) && 
                 remXdockATP) || 
                (atprec.atpTypeCode[i].equals(ATPConstants.SUB_VALUE) && 
                 remForsubATP)) {
                atprec.atpTypeCode[i] = null;
                atprec.atpSequence[i] = null;
                newarrLength--;
            }
        }
        removeFlow(atprec,newarrLength);
        if (atprec.atpTypeCode.length == 0){
            errorCode = 69;
            errorMessage = "InputValidation : No Available Flow Type, Please Validate Inputs";
            returnStatus = "E";
        }
        setError(atprec);
        long stop = System.currentTimeMillis();
        System.out.println("Time for Check PreProcess Data : " + 
                           Math.round((stop - start) * 0.001) + 
                           " Seconds");
        return atprec;
    }

    /**
     * Returns if validation result.
     * 
     * @return isValid Boolean specifies if the validation is success or not
     * 
     */
    public boolean isIsValid() {
        return isValid;
    }

    /**
     * Returns any Error Messages.
     * 
     * @return errorMessage Validation Error Message
     * 
     */
    public String getErrorMessage() {
        return errorMessage;
    }

    /**
     * Returns any Error Code.
     * 
     * @return errorCode Validation result error code
     * 
     */
    public int getErrorCode() {
        return errorCode;
    }

   /* private void checkOrderType(ATPRecordType atprec){
        if (atprec.orderType == null || atprec.orderType == "") {
            isValid = false;
            errorCode = 61;
            errorMessage = "InputValidation : Invalid Order Type";
            returnStatus = "E";
        }
    } */

    private void checkItemAttributes(ATPRecordType atprec){
        if (atprec.itemNumber == null || atprec.itemNumber == "") {
            isValid = false;
            errorCode = 62;
            errorMessage = "InputValidation : Invalid Item Number";
            returnStatus = "E";
        }
    }

    private void checkCustomerAttributes(ATPRecordType atprec) {
        if (atprec.custNumber == null || atprec.custNumber == "") {
            isValid = false;
            errorCode = 63;
            errorMessage = "InputValidation : Invalid Customer Numer";
            returnStatus = "E";
        }
        if (atprec.custShiptoLoc.equals("") || 
            atprec.shiptoLocPostalCode.equals("")) {
            isValid = false;
            errorCode = 64;
            errorMessage = 
                    "InputValidation : Invalid Ship to Location or ZipCode";
            returnStatus = "E";
        }
    }

    private void checkOrgAttributes(ATPRecordType atprec) {
        if (atprec.operatingUnit == null || atprec.operatingUnit.equals(0)) {
            isValid = false;
            errorCode = 65;
            errorMessage = "InpuValidation : InvalidOperating Unit";
            returnStatus = "E";
        }
    }

    private void checkDateAttributes(ATPRecordType atprec) {
        if (atprec.currentDate == null || atprec.currentDate.equals(0)) {
            isValid = false;
            errorCode = 66;
            errorMessage = "InputValidation : Invalid Current Date";
            returnStatus = "E";
        }
        if (atprec.requestedDate == null || atprec.requestedDate.equals(0)) {
            isValid = false;
            errorCode = 67;
            errorMessage = "InputValidation : Invalid Requested Date";
            returnStatus = "E";
        }
    }
    
    private ATPRecordType removeFlow(ATPRecordType atprec, int x) {
        String newTypeCode[] = new String[x];
        BigDecimal newSeq[] = new BigDecimal[x];
        int i = 0;
        for (int j = 0; j < atprec.atpTypeCode.length; j++) {
            if (atprec.atpTypeCode[j] != null && 
                atprec.atpSequence[j]!= null &&
                i <= j) {
                newTypeCode[i] = atprec.atpTypeCode[j];
                newSeq[i] = atprec.atpSequence[j];
                i++;
            }
        }
        atprec.atpTypeCode = newTypeCode;
        atprec.atpSequence = newSeq;
        return atprec;
    }
    
    private ATPRecordType setError(ATPRecordType atprec){
        atprec.errorCode = new BigDecimal(this.errorCode);
        atprec.errorMessage = this.errorMessage;
        atprec.returnStatus = this.returnStatus;
        return atprec;
    }
}// End InputValidation Class
