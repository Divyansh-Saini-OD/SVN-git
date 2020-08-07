/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |              Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             AtpProcessControl.java                                        |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This class is the main control class for the ATP application           |
 |    The Source should invoke this class through remote call or             |
 |    object Invocation.                                                     |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class will be invoked from the front end interfaces.              |
 |                                                                           |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    05/25/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp;

import java.math.BigDecimal;

import java.sql.Date;

import od.oracle.apps.xxom.atp.pool.ConnectionPoolMgr;
import od.oracle.apps.xxom.atp.thread.ThreadBarrier;
import od.oracle.apps.xxom.atp.thread.ThreadPool;

/**
 * This is the standard API to be used to call the Custom ATP with the required 
 * parameters. Calling Application would invoke the object of this class to 
 * get the necessary ATP details.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 * 
 **/
public class ATPProcessControl {

    /** 
     * Header information
     **/
    public static final String RCS_ID = 
        "$Header: AtpProcessControl.java  05/16/2007 Satis-Gnanmani$";

    private ATPRecordType atprec;
    private ATPRecordType[] atprecarr;
    private ATPResultSetType[] resultset;
    private ConnectionPoolMgr cpoolmgr;
    private ThreadPool tpool;
    private PreProcess prep;
    private InputValidation validateInput;
    private DateAnalysis analyzeDates;
    private ThreadBarrier barrier;


    /** 
     * Constructor to be invoked with arrays of parameter values. In case the 
     * inquiry is for a multiple items  eg: during a search or for rescheduling 
     * an entire order this Constructor can be Invoked for. This invokes the
     * process control and spawns individual threads for each order line.
     * Currently not implemented - waiting on business decision on how Ship Sets 
     * would be handled.
     * 
     * @param internal_item_number  Array of Item Number of the product being inquired
     * @param item_Quantity Array of Quantity requested in the inquiry
     * @param Quantity_UOM Array of Quantity UOM of the item
     * @param Customer_Number Array of Customer Number of the customer requesting the item
     * @param Cust_Shipto_Loc Array of Customer Ship to Location if specified
     * @param Shipto_Loc_Postal_Code Array of Customer zip code specified
     * @param Current_Date Array of Current Date and Time
     * @param Req_Date Array of Requested date and time
     * @param Req_Date_Type Array of Request date type
     * @param ATP_Call_Type Array of ATP call type
     * @param timezone_code Array of Customer time zone code
     * @param Order_Cateory Array of Order category
     * @param Order_type Array of Order Type
     * @param Unit_Selling_Price Array of Unit selling price of the item
     * @param Currency Array of Currency of the customer
     * @param Operating_Unit Array of Operating Unit of this Call
     * @param Ship_Method Array of Ship Method desired
     * @param ShipFrom_Org Array of Ship from org if specified
     * @param Order_Number Array of Order Number if for ReScheduling
     * @param Order_Line_Number Array of Order Line Number if for ReScheduling
     * 
     **/
    public ATPProcessControl(String[] internal_item_number, 
                             BigDecimal[] item_Quantity, String[] Quantity_UOM, 
                             String[] Customer_Number, 
                             String[] Cust_Shipto_Loc, String[] Shipto_Loc_Postal_Code, 
                             Date Current_Date, Date[] Req_Date, 
                             String[] Req_Date_Type, String[] ATP_Call_Type, 
                             String[] timezone_code, String[] Order_Cateory, 
                             String[] Order_type, 
                             BigDecimal[] Unit_Selling_Price, 
                             String[] Currency, BigDecimal[] Operating_Unit, 
                             String[] Ship_Method, String[] ShipFrom_Org, 
                             String[] Order_Number, 
                             String[] Order_Line_Number) {
        atprecarr = new ATPRecordType[internal_item_number.length];
        for (int i = 0; i < internal_item_number.length; i++) {
            atprecarr[i] = 
                    new ATPRecordType(internal_item_number[i], item_Quantity[i], 
                                      Quantity_UOM[i], Customer_Number[i], 
                                      Cust_Shipto_Loc[i], Shipto_Loc_Postal_Code[i], 
                                      Current_Date, Req_Date[i], 
                                      Req_Date_Type[i], ATP_Call_Type[i], 
                                      timezone_code[i], Order_Cateory[i], 
                                      Order_type[i], Unit_Selling_Price[i], 
                                      Currency[i], Operating_Unit[i], 
                                      Ship_Method[i], ShipFrom_Org[i], 
                                      Order_Number[i], Order_Line_Number[i]);
        }
    }

    /** 
     * Constructor to be invoked with element parameter values 
     * and not Arrays. The constructor invokes the process control for handling 
     * one line inquiry ONLY. Necessary objects such as the validation object,
     * Connetion Pool manager object and PreProcess objects are invoked.
     * 
     * @param internal_item_number  Item Number of the product being inquired
     * @param item_Quantity Quantity requested in the inquiry
     * @param Quantity_UOM Quantity UOM of the item
     * @param Customer_Number Customer Number of the customer requesting the item
     * @param Cust_Shipto_Loc Customer Ship to Location if specified
     * @param Shipto_Loc_Postal_Code Customer zip code specified
     * @param Current_Date Current Date and Time
     * @param Req_Date Requested date and time
     * @param Req_Date_Type Request date type
     * @param ATP_Call_Type ATP call type
     * @param timezone_code Customer time zone code
     * @param Unit_Selling_Price Unit selling price of the item
     * @param Currency Currency of the customer
     * @param Operating_Unit Operating Unit of this Call
     * @param Ship_Method Ship Method desired
     * @param ShipFrom_Org Ship from org if specified
     * @param Order_Number Order Number if for ReScheduling
     * @param Order_Line_Number Order Line Number if for ReScheduling
     * 
     **/
    public ATPProcessControl(String internal_item_number, 
                             BigDecimal item_Quantity, String Quantity_UOM, 
                             String Customer_Number, String Cust_Shipto_Loc, 
                             String Shipto_Loc_Postal_Code, Date Current_Date, 
                             Date Req_Date, String Req_Date_Type, 
                             String ATP_Call_Type, String timezone_code, 
                             String Order_Category, String Order_Type, 
                             BigDecimal Unit_Selling_Price, String Currency, 
                             BigDecimal Operating_Unit, String Ship_Method, 
                             String ShipFrom_Org, String Order_Number, 
                             String Order_Line_Number) {
        if ("INQUIRY".equals(ATP_Call_Type)) {
            this.atprec = 
                    new ATPRecordType(internal_item_number, item_Quantity, 
                                      Quantity_UOM, Customer_Number, 
                                      Cust_Shipto_Loc, Shipto_Loc_Postal_Code, 
                                      Current_Date, Req_Date, Req_Date_Type, 
                                      ATP_Call_Type, timezone_code, 
                                      Order_Category, Order_Type, 
                                      Unit_Selling_Price, Currency, 
                                      Operating_Unit);
        } else {
            this.atprec = 
                    new ATPRecordType(internal_item_number, item_Quantity, 
                                      Quantity_UOM, Customer_Number, 
                                      Cust_Shipto_Loc, Shipto_Loc_Postal_Code, 
                                      Current_Date, Req_Date, Req_Date_Type, 
                                      ATP_Call_Type, timezone_code, 
                                      Order_Category, Order_Type, 
                                      Unit_Selling_Price, Currency, 
                                      Operating_Unit, Ship_Method, 
                                      ShipFrom_Org, Order_Number, 
                                      Order_Line_Number);
        }

        this.cpoolmgr = cpoolmgr.getInstance();
        this.prep = new PreProcess(atprec, cpoolmgr);
        this.validateInput = new InputValidation();
    }

    /** 
     * This method returns the ATPRecordType object that consists of all the 
     * inquiry details
     * 
     * @return atprec The processes record with all the results.
     * @throws InterruptedException Occurs when thread is being interrupted.
     * 
     **/
    public ATPRecordType getATPRecord() {
        atprec = validateInput.validateInput(atprec);
        atprec = prep.callPreProcess();
        atprec = validateInput.checkPreprocessData(atprec);
        if (atprec.getReturnStatus().equals("E")){
            return atprec;
        }
        this.barrier = new ThreadBarrier(atprec.atpTypeCode.length);
        if (atprec.getReturnStatus().equals("S")) {
            resultset = new ATPResultSetType[atprec.getAtpSequence().length];
            tpool = new ThreadPool(this.atprec.getAtpSequence().length);
            for (int i = 0; i < this.atprec.getAtpSequence().length; i++) {
                resultset[i] = new ATPResultSetType();
                resultset[i].setCallName(this.atprec.getAtpTypeCode()[i]);
                resultset[i].setCallPriority(this.atprec.getAtpSequence()[i]);
                resultset[i].setItemNumber(this.atprec.getItemNumber());
                resultset[i].setCustNumber(this.atprec.getCustNumber());
                resultset[i].setQuantity(this.atprec.getQuantity());
                resultset[i].setOperatingUnit(this.atprec.getOperatingUnit());
                resultset[i].setSubItemNumber(this.atprec.getForcedSubstitute());
                try {
                    makecall(resultset[i]);
                } catch (InterruptedException e) {
                     LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
                }
            }
        } else {
            System.out.println("Preprocess Errored, Please check the error Message.");
            return atprec;
        }
        tpool.synchronizeThreads();
        for (int i = 0; i < resultset.length; i++) {
            LogATP.printThreadResults(resultset[i]);
        }
        try {
            atprec = analyzeDates(atprec);
        } catch (InterruptedException e) {
             LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (NullPointerException e){
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (Exception e){
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        }
        LogATP.printAtpRecord(atprec, "Final Results");
        return atprec;
    }

    /*
     * Makecall method to invoke the ATPMake call object.
     */
    private void makecall(ATPResultSetType resultset) throws InterruptedException {
        ATPMakeCall call = 
            new ATPMakeCall(this.atprec, resultset, this.cpoolmgr, 
                            this.barrier);
        tpool.execute(call, resultset.getCallPriority().intValue());
    }

    /*
     * To implement Caching and make use of it.
     */
  /*private void checkCache() {
        // To implement Caching and make use of it.
    } */

    /*
     * This method calls the AnalyzeDates class to do the date analysis.
     */
    private ATPRecordType analyzeDates(ATPRecordType atprecin) throws InterruptedException {
        analyzeDates = new DateAnalysis(resultset, atprec);
        atprecin = analyzeDates.analyzeDates();
        return atprecin;
    }

    /*
     * Main executable class for debugging and testing purposes only.
     */
    public static void main(String[] args){
        long startTime = System.currentTimeMillis();
        ATPProcessControl atpctrl = 
        new ATPProcessControl("RG-100",                         // Item Number
                              new BigDecimal(5),                // Item Quantity
                              "EA",                             // Quantity UOM
                              "1381",                           // Customer Number
                              "RG",                             // Ship to Location
                              "32702",                          // Customer PostalCode
                              Date.valueOf("2007-08-01"),       // Current Date
                              Date.valueOf("2007-08-30"),       // Request Date
                              null,                             // Request Date Type
                              "INQUIRY",                        // ATP Call Type
                              "America/Denver",                 // TimeZone
                              null,                             // Order Category
                              null,                             // Order Type
                              null,                             // Unit Selling Price
                              null,                             // Currency
                              new BigDecimal(141),              // Operating Unit
                              null,                             // Ship Method
                              null,                             // Ship From Org
                              null,                             // Order Number
                              null);                            // Order Line Number

        System.out.println("*************************************************************");
        System.out.println("                    Input Parameters                         ");
        System.out.println("*************************************************************");
        System.out.println(" Item Number      : " + 
                           atpctrl.atprec.getItemNumber());
        System.out.println(" Item Quantity    : " + 
                           atpctrl.atprec.getQuantity());
        System.out.println(" Quantity UOM     : " + 
                           atpctrl.atprec.getQuantityUOM());
        System.out.println(" Customer Number  : " + 
                           atpctrl.atprec.getCustNumber());
        System.out.println(" Ship To Location : " + 
                           atpctrl.atprec.getCustShiptoLoc());
        System.out.println(" Current Date     : " + 
                           atpctrl.atprec.getCurrentDate());
        System.out.println(" Operating Unit     : " + 
                           atpctrl.atprec.getOperatingUnit());
        System.out.println(" Requested Date   : " + 
                           atpctrl.atprec.getRequestedDate());
        System.out.println(" Timezone         : " + 
                           atpctrl.atprec.getTimezoneCode());
        System.out.println("*************************************************************");
        ATPRecordType atprecd = new ATPRecordType();
        atprecd = atpctrl.getATPRecord();
        long stopTime = System.currentTimeMillis();
        System.out.println("Execution time for this Call is : " + 
                           Math.round((stopTime - startTime) * 0.001) + 
                           " Seconds");
    }
}
