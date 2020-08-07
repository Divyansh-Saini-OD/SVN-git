/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |             Oracle NAIO/WIPRO/Office Depot/Consulting Organization        |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             LogATP.java                                             |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This Class validates the input parameters received from the Source     |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |                                                                           |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    07/02/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp;

import java.lang.reflect.Field;

/**
 * Class to log the data manipulated in this application.Temporary use as 
 * for debugging. Log to be included in later release.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 * 
 **/
public class LogATP {

    public static final String RCS_ID = 
        "$Header: PrintResults.java  07/02/2007 Satis-Gnanmani$";

    /**
     * This method prints all the member variable names of an object with their 
     * field values.
     * 
     * @param obj java.lang.object to be printed
     * @throws IllegalAccessException When an Illegal field is accessed 
     * i.e one not in the object type
     * 
     **/
    public static synchronized void printObject(Object obj) throws IllegalAccessException {
        Field[] fields = obj.getClass().getFields();
        for (int i = 0; i < fields.length; i++) {
            System.out.println(fields[i].getName() + "   : " + 
                               fields[i].get(obj));
        }
    }

    /**
     * Prints the details of an Exception
     * 
     * @param classname Object when the Exception Occured
     * @param cause Cause of the Exception if available
     * @param message Error Message generated
     * @param trace StackTrace of the Exception
     * 
     **/
    public static synchronized void printException(String classname, Throwable cause, String message, StackTraceElement[] trace) {
        System.out.println("Exception Name : " + classname.toString());
        //System.out.println("Exception Cause : " + cause.toString());
        System.out.println("Error Message : " + message);
        System.out.println("Stacktrace : ");
        System.out.println(trace.toString());
    }

    /**
     * Prints the results of a Particualar ATP execution of a thread / work
     * 
     * @param resultset The Object type record with all resultset data
     * 
     **/
    public static synchronized void printThreadResults(ATPResultSetType resultset) {
        System.out.println("**********************************************************************************");
        System.out.println("                Results - " + 
                           resultset.getCallName() + " Process Thread   ");
        System.out.println("**********************************************************************************");
        System.out.println("Ordered Item : " + resultset.getItemNumber());
        System.out.println("Substitute Item : " + 
                           resultset.getSubItemNumber());
        System.out.println("Customer : " + resultset.getCustNumber());
        System.out.println("Operating Unit : " + resultset.getOperatingUnit());
        System.out.println("Ordered qty : " + resultset.getQuantity());
        System.out.println("Requested Date Qty : " + 
                           resultset.getRequestedDateQty());
        System.out.println("Arrival Date : " + resultset.getArrivalDate());
        System.out.println("Ship Date : " + resultset.getShipDate());
        System.out.println("Source Org Id : " + resultset.getSrcOrgId());
        System.out.println("Error Code : " + resultset.getErrorCode());
        System.out.println("Return Status : " + resultset.getReturnStatus());
        System.out.println("Error Message : " + resultset.getErrorMessage());
        System.out.println("**********************************************************************************");
    }

    /**
     * Prints the ATP Object with all the necessary data
     * 
     * @param atprec The Object type record with all necessary data
     * @param name ATP type code executed
     * 
     **/
    public static synchronized void printAtpRecord(ATPRecordType atprec, 
                                                   String name) {
        if (atprec != null) {
            System.out.println("-----------------------------------------------------");
            System.out.println("        Atp Record Details : " + name + 
                               "            ");
            System.out.println("-----------------------------------------------------");
            System.out.println("Base Org : " + atprec.getBaseOrg());
            System.out.println("Order Flow Type : " + 
                               atprec.getOrderFlowType());
            System.out.println("Customer Number : " + atprec.getCustNumber());
            System.out.println("Operating Unit : " + 
                               atprec.getOperatingUnit());
            System.out.println("Substitute Item : " + 
                               atprec.getForcedSubstitute());
            System.out.println("Return Status : " + atprec.getReturnStatus());
            System.out.println("Error Message : " + atprec.getErrorMessage());
            System.out.println("Arrival Date : " + atprec.getArrivalDate());
            System.out.println("Ship Date : " + atprec.getShipDate());
            System.out.println("Requested Date Qty : " + 
                               atprec.getRequestedDateQty());
            System.out.println("-----------------------------------------------------");
        }
    }

    /**
     * Prints the PreProcess data collected after PreProcess Execution
     * 
     * @param atprec The Object type record with all necessary PreProcess data
     * 
     **/
    public static synchronized void printPreProcessResults(ATPRecordType atprec) {
        System.out.println("************************************************************");
        System.out.println("                 Results - Pre Process                      ");
        System.out.println("************************************************************");
        System.out.println("Base Org : " + atprec.getBaseOrg());
        System.out.println("Order Flow Type : " + atprec.getOrderFlowType());
        System.out.println("Operating Unit : " + atprec.getOperatingUnit());
        System.out.println("Order Flow Sequence : ");
        if (atprec.getAtpTypeCode().length != 0) {
            for (int i = 0; i < atprec.getAtpTypeCode().length; i++) {
                System.out.println("Sequence Code: " + 
                                   atprec.getAtpTypeCode()[i] + 
                                   ", Sequence Number : " + 
                                   atprec.getAtpSequence()[i]);
            }
        }
        System.out.println("Substitute Item : " + 
                           atprec.getForcedSubstitute());
        System.out.println("Return Status : " + atprec.getReturnStatus());
        System.out.println("Error Message : " + atprec.getErrorMessage());
        System.out.println("************************************************************");
    }

    /**
     * Prints Worning Messages
     * 
     * @param msg Warning Message to be printed
     * @param errorCode Warning code to be printed
     * 
     **/
    public static synchronized void printWarning(String msg, int errorCode){
        System.out.println("WARNING : " + errorCode + " :- " + msg);
    }
    /**
     * Prints Debug Messages
     * 
     * @param msg Debug Message to be printed
     * @param errorCode Debug code to be printed
     * 
     **/
    public static synchronized void printDebug(String msg, int errorCode){
        System.out.println("DEBUG : " + errorCode + " :- " + msg);
    }

    /**
     * Prints Error Messages
     * 
     * @param msg Error Message to be printed
     * @param errorCode Error code to be printed
     * 
     **/
    public static synchronized void printError(String msg, int errorCode){
        System.out.println("ERROR : " + errorCode + " :- " + msg);
    }
}
