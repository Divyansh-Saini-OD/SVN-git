/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |        Oracle NAIO/WIPRO/Office Depot/Consulting Organization             |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             DateAnalysis.java                                             |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This Class analyses all the ATP result sets and passes to the          |
 |    Source the best Ship date, Arrival date and the Base Org               |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class object will be used in AtpProcessControl.java               |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    06/25/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp;

import java.math.BigDecimal;

import java.util.Arrays;
import java.util.HashMap;

/**
 * This class analyses all the results to find the best date available for the
 * particular item inquiry.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 * 
 **/
public class DateAnalysis {

    /**
     * Header Information.
     * 
     **/
    public static final String RCS_ID = 
        "$Header: DateAnalysis.java  06/25/2007 Satis-Gnanmani$";

    private ATPResultSetType[] resultset;
    private ATPRecordType atprec;
    private HashMap<BigDecimal, ATPResultSetType> availableMap;
    private HashMap<BigDecimal, ATPResultSetType> futureMap;
    private ATPResultSetType finalResult;
    private boolean hasErr = false;
    private boolean foundDates = false;
    private boolean foundFuture = false;

    /**
     * Constructor to invoke the Analysis with the given set of results resulset
     * 
     * @param resultset Array of resultset date
     * @param atprec ATP inquiry data object type
     * 
     **/
    public DateAnalysis(ATPResultSetType[] resultset, ATPRecordType atprec) {
        this.resultset = new ATPResultSetType[resultset.length];
        this.resultset = resultset;
        this.atprec = atprec;
        this.availableMap = new HashMap<BigDecimal, ATPResultSetType>();
        this.futureMap = new HashMap<BigDecimal, ATPResultSetType>();
        this.finalResult = new ATPResultSetType();
    }

    /**
     * Method which analyses the date and provides the best effective dates.
     * 1) If the resultset array has any Errors then the Error will be forwarded to 
     *    the calling source.
     * 2) If the item is Available in the first Order flow, based on the 
     *    priority set on them, and the dates can meet the request then results
     *    are returned to the calling source.
     * 3) If the item is Not Available the item availability is checked in the 
     *    next priority flow type, if available and the dates meet the request 
     *    then the results are returned to the calling source.
     * 4) If none of the flow types have the item available, then if the
     *    item request can be met in the future then highest priority order flow
     *    with future arrival and ship dates will be sent to the calling source.
     *    
     * @return atprec ATP inquiry data with the analyzed results.
     * @throws InterruptedException When current thread is interrupted
     * 
     **/
    public ATPRecordType analyzeDates() throws InterruptedException {
        ATPResultSetType atpresult = new ATPResultSetType();
        atpresult = this.calcBestDates();
        this.atprec.setArrivalDate(atpresult.getArrivalDate());
        this.atprec.setShipDate(atpresult.getShipDate());
        this.atprec.setErrorMessage(atpresult.getErrorMessage());
        this.atprec.setReturnStatus(atpresult.getReturnStatus());
        this.atprec.setSrcOrgId(atpresult.getSrcOrgId());
        this.atprec.setItemPlanningCategory(atpresult.getItemPlanningCategory());
        this.atprec.setShipMethodCode(atpresult.getShipMethodCode());
        this.atprec.setShipFromOrg(atpresult.getShipFromOrg());
        this.atprec.setRequestedDateQty(atpresult.getRequestedDateQty());
        return this.atprec;
    }

    /*
     * The Analysis is being done here.
     *
     */
    private ATPResultSetType calcBestDates() throws InterruptedException {
        int[] newarr = new int[resultset.length];
        try {
            // Loop through the resultset array.
            for (int i = 0; i < resultset.length; i++) {
                // Determine any have Errors.
                if (!resultset[i].getReturnStatus().equals("E")) {
                    newarr[i] = resultset[i].getCallPriority().intValue();
                    // Determine if Item Available and can Meet Request
                    if (resultset[i].getErrorCode().equals(new BigDecimal(0))) {
                        availableMap.put(resultset[i].getCallPriority(), 
                                         resultset[i]);
                        // Determine if item Available for future.
                    } else if (resultset[i].getErrorCode().equals(new BigDecimal(53))) {
                        futureMap.put(resultset[i].getCallPriority(), 
                                      resultset[i]);
                    } else {
                     // Return the Error Messages.
                     // hasErr = true;
                        finalResult = resultset[i];
                     // foundDates = true;
                    }
                } else {
                    hasErr = true;
                    finalResult = resultset[i];
                    foundDates = true;
                }
            }
            Arrays.sort(newarr);
            if (!hasErr) {
                for (int i = newarr.length - 1; i >= 0; i--) {
                    // Get the ResultSet if available by flow sequence
                    if (availableMap.containsKey(new BigDecimal(newarr[i]))) {
                        ATPResultSetType availableSet = new ATPResultSetType();
                        availableSet = 
                                availableMap.get(new BigDecimal(newarr[i]));
                        if (availableSet.getArrivalDate() != null && 
                            availableSet.getShipDate() != null && 
                            !foundDates) {
                            finalResult = availableSet;
                            // Set flag so Low Priority Results are not picked up
                            foundDates = true;
                        }
                        // Get the future ResultSet if available by flow sequence
                    } else if (futureMap.containsKey(new BigDecimal(newarr[i])) && 
                               !foundDates) {
                        ATPResultSetType futureSet = new ATPResultSetType();
                        futureSet = futureMap.get(new BigDecimal(newarr[i]));
                        if (futureSet.getArrivalDate() != null && 
                            futureSet.getShipDate() != null && !foundFuture) {
                            finalResult = futureSet;
                            // Set flag so Low Priority Results are not picked up
                            foundFuture = true;
                        }
                    }
                }
            }
            System.out.println("Final Source Flow Type : " + 
                               finalResult.getCallName());
        } catch (NullPointerException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (Exception e){
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        }
        return finalResult;
    }

    /*  private HashMap loadHashMap(){
      for (int i = 0; i < resultset.length ; i++){
        this.hashmap.put(resultset[i].callPriority.intValue(),resultset[i]);
      }
      return hashmap;
    }*/

    /*  private int getNextMinPriority(int maxPriority){
      if ( maxPriority == null){
         for (int j = 0; j < resultset.length ; j++){
             if (resultset[j].callPriority.intValue() < maxPriority)
                maxPriority = resultset[j].callPriority.intValue();
         }
      } else {
         for (int j = 0; j < resultset.length ; j++){
             if (resultset[j].callPriority.intValue() < maxPriority && resultset[j].callPriority.intValue() != maxPriority)
                maxPriority = resultset[j].callPriority.intValue();
         }
      }
      return maxPriority;
    }*/
}
