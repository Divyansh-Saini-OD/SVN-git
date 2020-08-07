/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |             Oracle NAIO/WIPRO/Office Depot/Consulting Organization        |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             AtpRecordType.java                                            |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This class is the object type of a single ATP record.                  |
 |    To contains within, all the variables ( Input, Output and              |
 |    Derived parameters.                                                    |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class object will be used in AtpProcessControl.java               |
 |    DateAnalysis.java, ATPMakeCall.java, InputValidation.java              |
 |    CacheManagement.java, ThreadPool.java and                              |
 |    LogATP.java                                                            |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    05/29/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp;

import java.math.BigDecimal;

import java.sql.Date;

/**
 * Object type of the ATP inquiry. Consists of all the input attibutes, derived 
 * attributes and output attributes. Provides get and set Methods for setting 
 * and retrieving the data.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 * 
 */
public class ATPRecordType {

    /**
     * Header Information
     * 
     */
    public static final String RCS_ID = 
        "$Header: AtpRecordType.java  05/29/2007 Satis-Gnanmani$";

    /*
     *  Static Variables
     */

  /*private static final int ATP_INQUIRY = 0;
    private static final int ATP_SCHEDULING = 1;
    private static final int ATP_RESOURCING = 2;
    private static final int ATP_ITEM_AVAILABLE = 0;
    private static final int ATP_ITEM_UNAVAILABLE = 1;
    private static final int ATP_ITEM_NOT_APPLICABLE = 2;*/
    
    /* The following member variables will be used in dynamic database calls and 
     * for data population and hence are Public.
     */
     
    /*
     *  Input Variables
     */

    /**
     * Item Number
     **/
    public String itemNumber = "";
    /**
     * Quantity UOM
     **/
    public String quantityUOM = "";
    /**
     * Customer Number
     * 
     **/
    public String custNumber = "";
    /**
     * Customer Shipto Location
     **/
    public String custShiptoLoc = "";
    /**
     * Ship to Location Postal Code
     **/
    public String shiptoLocPostalCode = "";
    /**
     * Request Date Type
     **/
    public String requestDateType = "";
    /**
     * ATP Call Type
     **/
    public String atpCallType = "";
    /**
     * Order Category
     **/
    public String orderCategory = "";
    /**
     * Order Type
     **/
    public String orderType = "";
    /**
     * Currency
     **/
    public String currency = "";
    /**
     * Operating UNit
     **/
    public BigDecimal operatingUnit = new BigDecimal(0);
    /**
     * Ship Method
     **/
    public String shipMethod = "";
    /**
     * Ship From Org
     **/
    public String shipFromOrg = "";
    /**
     * Order Number
     **/
    public String orderNumber = "";
    /**
     * Order Line Number
     **/
    public String orderLineNumber = "";
    /**
     * Current Date and Time
     **/
    public Date currentDate = null;
    /**
     * Requested Date and Time
     **/
    public Date requestedDate = null;
    /**
     * Unit Selling Price
     **/
    public BigDecimal unitSellingPrce = null;
    /**
     * Quantity
     **/
    public BigDecimal quantity;

    /*
     *  PL/SQL Input Variables
     */
     
     /**
      * TimeZone code
      **/
    public String timezoneCode = null;
    /**
     * Inventory Item Id
     **/
    public BigDecimal inventoryItemId = new BigDecimal(0);
    /**
     * Base Org Id
     **/
    public BigDecimal baseOrgId = new BigDecimal(0);
    /**
     * 
     **/
    public BigDecimal zoneId = new BigDecimal(0);
    /**
     * Xdock Only indicator Flag
     **/
    public String xdockOnlyFlag = null;
    /**
     * Pickup Flag
     **/
    public String pickupFlag = null;
    /**
     * Session Id of the database Session
     **/
    public BigDecimal sessionId = new BigDecimal(0);
    

    /*
     *  PL/SQL Output Variables
     */
     
     /**
      * Base Org
      **/
    public String baseOrg = null;
    /**
     * Order Flow Type
     **/
    public String orderFlowType = null;
    public String itemValOrg = null;
    public String srcItemFromXdock = null;
    public String forcedSubstitute = null;
    public String returnStatus = null;
    public String errorMessage = null;
    public String atpTypeCode[] = null;
    public BigDecimal atpSequence[] = null;
    public BigDecimal assignmentSetId = new BigDecimal(0);
    public BigDecimal categorySetId = new BigDecimal(0);
    public BigDecimal srcOrgId = new BigDecimal(0);
    public BigDecimal requestedDateQty = new BigDecimal(0);
    public BigDecimal errorCode = new BigDecimal(0);
    public BigDecimal tcscOrgId = new BigDecimal(0);
    public BigDecimal xrefItemId = new BigDecimal(0);

    public Date shipDate = null;
    public Date arrivalDate = null;

    /*
     *  Output Variables
     */

    public String itemPlanningCategory = null;
    public BigDecimal unitWeight = null;
    public String atpOrderType = null;
    public String supplierItem = null;
    public String orgName = null;
    public String srcSupplier = null;
    public String srcSupplierType = null;
    public String srcSupplierSite = null;
    public String shipMethodCode = null;
    public String atpFullfillmentType = null;
    public String facilityCode = null;
    public String supplierAccount = null;
    public String zoneName = null;

    /** Empty contructor to create on the fly ATPRecord objects
     */
    public ATPRecordType() {

    }

    /** 
     * Construcor to invoke the ATPRecord object type which represents the
     * collection of all the data required and provided by the ATP custom 
     * application when called in inquiry mode
     * 
     * @param internal_item_number
     * @param item_Quantity
     * @param Quantity_UOM
     * @param Customer_Number
     * @param Cust_Shipto_Loc
     * @param Shipto_Loc_Postal_Code
     * @param Current_Date
     * @param Req_Date
     * @param Req_Date_Type
     * @param ATP_Call_Type
     * @param Unit_Selling_Price
     * @param Currency
     * @param Operating_Unit
     * 
     */
    public ATPRecordType(String internal_item_number, BigDecimal item_Quantity, 
                         String Quantity_UOM, String Customer_Number, 
                         String Cust_Shipto_Loc, String Shipto_Loc_Postal_Code, 
                         Date Current_Date, Date Req_Date, 
                         String Req_Date_Type, String ATP_Call_Type, 
                         String timezonecode, String Order_Category, 
                         String Order_Type, BigDecimal Unit_Selling_Price, 
                         String Currency, BigDecimal Operating_Unit) {
        itemNumber = internal_item_number;
        quantity = item_Quantity;
        quantityUOM = Quantity_UOM;
        custNumber = Customer_Number;
        custShiptoLoc = Cust_Shipto_Loc;
        shiptoLocPostalCode = Shipto_Loc_Postal_Code;
        currentDate = Current_Date;
        requestedDate = Req_Date;
        requestDateType = Req_Date_Type;
        atpCallType = ATP_Call_Type;
        timezoneCode = timezonecode;
        orderCategory = Order_Category;
        orderType = Order_Type;
        unitSellingPrce = Unit_Selling_Price;
        currency = Currency;
        operatingUnit = Operating_Unit;
    }
    
    /*
     * Constructor for ReScheduling.
     */

    /** 
     * Construcor to invoke the ATPRecord object type which represents the
     * collection of all the data required and provided by the ATP custom 
     * application with the order details when not called in inquiry mode
     * 
     * @param internal_item_number
     * @param item_Quantity
     * @param Quantity_UOM
     * @param Customer_Number
     * @param Cust_Shipto_Loc
     * @param Shipto_Loc_Postal_Code
     * @param Current_Date
     * @param Req_Date
     * @param Req_Date_Type
     * @param ATP_Call_Type
     * @param Unit_Selling_Price
     * @param Currency
     * @param Operating_Unit
     * @param Ship_Method
     * @param ShipFrom_Org
     * @param Order_Number
     * @param Order_Line_Number
     * 
     */
    public ATPRecordType(String internal_item_number, BigDecimal item_Quantity, 
                         String Quantity_UOM, String Customer_Number, 
                         String Cust_Shipto_Loc, String Shipto_Loc_Postal_Code, 
                         Date Current_Date, Date Req_Date, 
                         String Req_Date_Type, String ATP_Call_Type, 
                         String timezonecode, String Order_Category, 
                         String Order_Type, BigDecimal Unit_Selling_Price, 
                         String Currency, BigDecimal Operating_Unit, 
                         String Ship_Method, String ShipFrom_Org, 
                         String Order_Number, String Order_Line_Number) {
        itemNumber = internal_item_number;
        quantity = item_Quantity;
        quantityUOM = Quantity_UOM;
        custNumber = Customer_Number;
        custShiptoLoc = Cust_Shipto_Loc;
        shiptoLocPostalCode = Shipto_Loc_Postal_Code;
        currentDate = Current_Date;
        requestedDate = Req_Date;
        requestDateType = Req_Date_Type;
        atpCallType = ATP_Call_Type;
        timezoneCode = timezonecode;
        orderCategory = Order_Category;
        orderType = Order_Type;
        unitSellingPrce = Unit_Selling_Price;
        currency = Currency;
        operatingUnit = Operating_Unit;
        shipMethod = Ship_Method;
        shipFromOrg = ShipFrom_Org;
        orderNumber = Order_Number;
        orderLineNumber = Order_Line_Number;
    }

    /** 
     * This method sets the requestedDate for the ATP Record object
     * 
     * @param requestedDate for the particular ATP Inquiry
     * 
     */
    public void setRequestedDate(Date requestedDate) {
        this.requestedDate = requestedDate;
    }

    /** 
     * This method returns the requestedDate of the ATP Record Object
     * 
     * @return requestedDate of the particular ATP Inquiry
     * 
     */
    public Date getRequestedDate() {
        return requestedDate;
    }

    /** 
     * This method sets the base org of the ATP Record object
     * 
     * @param baseOrg BaseOrg for the particular ATP Inquiry
     * 
     */
    public void setBaseOrg(String baseOrg) {
        this.baseOrg = baseOrg;
    }

    /** 
     * This method returns the baseorg of the ATP Record Object
     * 
     * @return baseOrg The Base Org of the particular ATP Inquiry
     * 
     */
    public String getBaseOrg() {
        return baseOrg;
    }

    /** 
     * This method sets the order flow type for the ATP Record object
     * 
     * @param orderFlowType Order Flow Type for the particular ATP Inquiry
     * 
     */
    public void setOrderFlowType(String orderFlowType) {
        this.orderFlowType = orderFlowType;
    }

    /** 
     * This method returns the Order Flow type of the ATP Record Object
     * 
     * @return orderFlowType of the particular ATP Inquiry
     * 
     */
    public String getOrderFlowType() {
        return orderFlowType;
    }

    /** 
     * This method sets the Return Status of the ATP Record Object
     * 
     * @param returnStatus Returns te return status of the ATP Object
     * 
     */
    public void setReturnStatus(String returnStatus) {
        this.returnStatus = returnStatus;
    }

    /** 
     * This method returns the return status value of the ATP Record Object
     * 
     * @return returnStatus of the particular ATP Inquiry
     * 
     */
    public String getReturnStatus() {
        return returnStatus;
    }

    /** 
     * This method sets the Error Message of the ATP Record Object
     * 
     * @param errorMessage Error Message value of the ATP Record Object
     * 
     */
    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    /** 
     * This method returns the Error Message of the ATP Record Object
     * 
     * @return errorMessage Error Message of the ATP Record Object
     * 
     */
    public String getErrorMessage() {
        return errorMessage;
    }

    /** 
     * This method sets the Error Code of the ATP Record Object
     * 
     * @param errorCode Error Code Value of the ATP Record Object
     * 
     */
    public void setErrorCode(BigDecimal errorCode) {
        this.errorCode = errorCode;
    }

    /** 
     * This method returns the Error code value of the ATP Record Object
     * 
     * @return errorCode Error Code value of the ATP Record Object
     * 
     */
    public BigDecimal getErrorCode() {
        return errorCode;
    }

    /** 
     * This method sets the Ship Date of the ATP Record Object
     * 
     * @param shipDate Ship Date value for the ATP Record Object
     * 
     */
    public void setShipDate(Date shipDate) {
        this.shipDate = shipDate;
    }

    /** 
     * This method returns the Ship Date value of the ATP Record Object
     * 
     * @return shipDate Ship Date value of the ATP Record Object
     * 
     */
    public Date getShipDate() {
        return shipDate;
    }

    /** 
     * This method sets the Arrival Date of the ATP Record Object
     * 
     * @param arrivalDate Arrival date value for the ATP Record Object
     * 
     */
    public void setArrivalDate(Date arrivalDate) {
        this.arrivalDate = arrivalDate;
    }

    /** 
     * This method returns the Arrival Date value of the ATP Record Object
     * 
     * @return arrivalDate, Arrival Date of the particular ATP Inquiry
     * 
     */
    public Date getArrivalDate() {
        return arrivalDate;
    }

    /** 
     * This method sets the Item Planning Category of the ATP Record Object
     * 
     * @param itemPlanningCategory, Item Planning Category 
     *                              value for the ATP Record Object
     * 
     */
    public void setItemPlanningCategory(String itemPlanningCategory) {
        this.itemPlanningCategory = itemPlanningCategory;
    }

    /** 
     * This method returns the Item Planning Category value of the ATP Record Object
     * 
     * @return itemPlanningCategory, Item Planning Category of the particular ATP Inquiry
     * 
     */
    public String getItemPlanningCategory() {
        return itemPlanningCategory;
    }

    /** 
     * This method sets the ATP Order Type of the ATP Record Object
     * 
     * @param atpOrderType, ATP Order Type value for the ATP Record Object
     * 
     */
    public void setAtpOrderType(String atpOrderType) {
        this.atpOrderType = atpOrderType;
    }

    /** 
     * This method returns the ATP Order Type value of the ATP Record Object
     * 
     * @return atpOrderType, ATP Order Type of the particular ATP Inquiry
     * 
     */
    public String getAtpOrderType() {
        return atpOrderType;
    }

    /** 
     * This method returns the return status value of the ATP Record Object
     * 
     * @return returnStatus of the particular ATP Inquiry
     * 
     */
    public String[] getAtpTypeCode() {
        return atpTypeCode;
    }

    /** 
     * This method returns the return status value of the ATP Record Object
     * 
     * @return returnStatus of the particular ATP Inquiry
     * 
     */
    public BigDecimal[] getAtpSequence() {
        return atpSequence;
    }

    /** 
     * This method sets the Item Number of the ATP Record Object
     * 
     * @param itemNumber, Item Number Arrival date value for the ATP Record Object
     * 
     */
    public void setItemNumber(String itemNumber) {
        this.itemNumber = itemNumber;
    }

    /** 
     * This method returns the Item Number value of the ATP Record Object
     * 
     * @return itemNumber, Item Number of the particular ATP Inquiry
     * 
     */
    public String getItemNumber() {
        return itemNumber;
    }

    /** 
     * This method sets the UOM of the ATP Record Object
     * 
     * @param quantityUOM, UOM value for the ATP Record Object
     * 
     */
    public void setQuantityUOM(String quantityUOM) {
        this.quantityUOM = quantityUOM;
    }

    /** 
     * This method returns the return status value of the ATP Record Object
     * 
     * @return quantityUOM, UOM of the particular ATP Inquiry
     * 
     */
    public String getQuantityUOM() {
        return quantityUOM;
    }

    /** 
     * This method sets the Customer Number of the ATP Record Object
     * 
     * @param custNumber Customer Number value for the ATP Record Object
     * 
     */
    public void setCustNumber(String custNumber) {
        this.custNumber = custNumber;
    }

    /** 
     * This method returns the return status value of the ATP Record Object
     * 
     * @return custNumber, Customer Number of the particular ATP Inquiry
     * 
     */
    public String getCustNumber() {
        return custNumber;
    }

    /** 
     * This method sets the Ship To Location of the ATP Record Object
     * 
     * @param custShiptoLoc Ship To Location value for the ATP Record Object
     * 
     */
    public void setCustShiptoLoc(String custShiptoLoc) {
        this.custShiptoLoc = custShiptoLoc;
    }

    /** 
     * This method returns the return status value of the ATP Record Object
     * 
     * @return custShiptoLoc, Ship To Location of the particular ATP Inquiry
     * 
     */
    public String getCustShiptoLoc() {
        return custShiptoLoc;
    }

    /** 
     * This method sets the Ship To Location Postal Code of the ATP Record Object
     * 
     * @param shitoLocPostalCode, Ship To Location Postal Code value for the ATP Record Object
     * 
     */
    public void setShitoLocPostalCode(String shitoLocPostalCode) {
        this.shiptoLocPostalCode = shitoLocPostalCode;
    }

    /** 
     * This method returns the Ship To Location Postal Code value of the ATP Record Object
     * 
     * @return shiptoLocPostalCode, Ship To Location Postal Code of the particular ATP Inquiry
     * 
     */
    public String getShitoLocPostalCode() {
        return shiptoLocPostalCode;
    }

    /** 
     * This method sets the Req Date Type of the ATP Record Object
     * 
     * @param requestDateType, Req Date Type value for the ATP Record Object
     * 
     */
    public void setRequestDateType(String requestDateType) {
        this.requestDateType = requestDateType;
    }

    /** 
     * This method returns the Req Date Type value of the ATP Record Object
     * 
     * @return requestDateType, Req Date Type of the particular ATP Inquiry
     * 
     */
    public String getRequestDateType() {
        return requestDateType;
    }

    /** 
     * This method sets the ATP Call Type of the ATP Record Object
     * 
     * @param atpCallType, ATP Call Type value for the ATP Record Object
     * 
     */
    public void setAtpCallType(String atpCallType) {
        this.atpCallType = atpCallType;
    }

    /** 
     * This method returns the ATP Call Type value of the ATP Record Object
     * 
     * @return atpCallType, ATP Call Type of the particular ATP Inquiry
     * 
     */
    public String getAtpCallType() {
        return atpCallType;
    }

    /** 
     * This method sets the order Category of the ATP Record Object
     * 
     * @param orderCategory, order Category value for the ATP Record Object
     * 
     */
    public void setOrderCategory(String orderCategory) {
        this.orderCategory = orderCategory;
    }

    /** 
     * This method returns the order Category value of the ATP Record Object
     * 
     * @return orderCategory, order Category of the particular ATP Inquiry
     * 
     */
    public String getOrderCategory() {
        return orderCategory;
    }

    /** 
     * This method sets the Order Type of the ATP Record Object
     * 
     * @param orderType, Order Type value for the ATP Record Object
     * 
     */
    public void setOrderType(String orderType) {
        this.orderType = orderType;
    }

    /** 
     * This method returns the Order Type value of the ATP Record Object
     * 
     * @return orderType, Order Type of the particular ATP Inquiry
     * 
     */
    public String getOrderType() {
        return orderType;
    }

    /** 
     * This method sets the currency of the ATP Record Object
     * 
     * @param currency, currency value for the ATP Record Object
     * 
     */
    public void setCurrency(String currency) {
        this.currency = currency;
    }

    /** 
     * This method returns the currency value of the ATP Record Object
     * 
     * @return currency, currency of the particular ATP Inquiry
     * 
     */
    public String getCurrency() {
        return currency;
    }

    /** 
     * This method sets the operating Unit of the ATP Record Object
     * 
     * @param operatingUnit, operating Unit value for the ATP Record Object
     * 
     */
    public void setOperatingUnit(BigDecimal operatingUnit) {
        this.operatingUnit = operatingUnit;
    }

    /** 
     * This method returns the operating Unit value of the ATP Record Object
     * 
     * @return operatingUnit, operating Unit of the particular ATP Inquiry
     * 
     */
    public BigDecimal getOperatingUnit() {
        return operatingUnit;
    }

    /** 
     * This method sets the Ship Method of the ATP Record Object
     * 
     * @param shipMethod, Ship Method value for the ATP Record Object
     * 
     */
    public void setShipMethod(String shipMethod) {
        this.shipMethod = shipMethod;
    }

    /** 
     * This method returns the Ship Method value of the ATP Record Object
     * 
     * @return shipMethod, Ship Method of the particular ATP Inquiry
     * 
     */
    public String getShipMethod() {
        return shipMethod;
    }

    /** 
     * This method sets the Ship From Org of the ATP Record Object
     * 
     * @param shipFromOrg, Ship From Org value for the ATP Record Object
     * 
     */
    public void setShipFromOrg(String shipFromOrg) {
        this.shipFromOrg = shipFromOrg;
    }

    /** 
     * This method returns the Ship From Org value of the ATP Record Object
     * 
     * @return shipFromOrg, Ship From Org of the particular ATP Inquiry
     * 
     */
    public String getShipFromOrg() {
        return shipFromOrg;
    }

    /** 
     * This method sets the Order Number of the ATP Record Object
     * 
     * @param orderNumber, Order Number value for the ATP Record Object
     * 
     */
    public void setOrderNumber(String orderNumber) {
        this.orderNumber = orderNumber;
    }

    /** 
     * This method returns the Order Number value of the ATP Record Object
     * 
     * @return orderNumber, Order Number of the particular ATP Inquiry
     * 
     */
    public String getOrderNumber() {
        return orderNumber;
    }

    /** 
     * This method sets the Order Line Number of the ATP Record Object
     * 
     * @param orderLineNumber, Order Line Number value for the ATP Record Object
     * 
     */
    public void setOrderLineNumber(String orderLineNumber) {
        this.orderLineNumber = orderLineNumber;
    }

    /** 
     * This method returns the Order Line Number value of the ATP Record Object
     * 
     * @return orderLineNumber, Order Line Number of the particular ATP Inquiry
     * 
     */
    public String getOrderLineNumber() {
        return orderLineNumber;
    }

    /** 
     * This method sets the current Date of the ATP Record Object
     * 
     * @param currentDate current Date value for the ATP Record Object
     * 
     */
    public void setCurrentDate(Date currentDate) {
        this.currentDate = currentDate;
    }

    /** 
     * This method returns the current Date value of the ATP Record Object
     * 
     * @return currentDate, current Date of the particular ATP Inquiry
     * 
     */
    public Date getCurrentDate() {
        return currentDate;
    }

    /** 
     * This method sets the  Unit Selling Price of the ATP Record Object
     * 
     * @param unitSellingPrce  Unit Selling Price value for the ATP Record Object
     * 
     */
    public void setUnitSellingPrce(BigDecimal unitSellingPrce) {
        this.unitSellingPrce = unitSellingPrce;
    }

    /** 
     * This method returns the  Unit Selling Price value of the ATP Record Object
     * 
     * @return unitSellingPrce, Unit Selling Price of the particular ATP Inquiry
     * 
     */
    public BigDecimal getUnitSellingPrce() {
        return unitSellingPrce;
    }

    /** 
     * This method sets the quantity of the ATP Record Object
     * 
     * @param quantity, quantity value for the ATP Record Object
     * 
     */
    public void setQuantity(BigDecimal quantity) {
        this.quantity = quantity;
    }

    /** 
     * This method returns the quantity value of the ATP Record Object
     * 
     * @return quantity, quantity of the particular ATP Inquiry
     * 
     */
    public BigDecimal getQuantity() {
        return quantity;
    }

    /** 
     * This method sets the Time Zone Code of the ATP Record Object
     * 
     * @param timezoneCode, Time Zone Code value for the ATP Record Object
     * 
     */
    public void setTimezoneCode(String timezoneCode) {
        this.timezoneCode = timezoneCode;
    }

    /** 
     * This method returns the Time Zone Code value of the ATP Record Object
     * 
     * @return timezoneCode, Time Zone Code of the particular ATP Inquiry
     * 
     */
    public String getTimezoneCode() {
        return timezoneCode;
    }

    /** 
     * This method sets the Inventory Item Id of the ATP Record Object
     * 
     * @param inventoryItemId, Inventory Item Id value for the ATP Record Object
     * 
     */
    public void setInventoryItemId(BigDecimal inventoryItemId) {
        this.inventoryItemId = inventoryItemId;
    }

    /** 
     * This method returns the return status value of the ATP Record Object
     * 
     * @return inventoryItemId, Inventory Item Id of the particular ATP Inquiry
     * 
     */
    public BigDecimal getInventoryItemId() {
        return inventoryItemId;
    }

    /** 
     * This method sets the Base Org Id of the ATP Record Object
     * 
     * @param baseOrgId, Base Org Id value for the ATP Record Object
     * 
     */
    public void setBaseOrgId(BigDecimal baseOrgId) {
        this.baseOrgId = baseOrgId;
    }

    /** This method returns the Base Org Id value of the ATP Record Object
     * @return baseOrgId, Base Org Id of the particular ATP Inquiry
     */
    public BigDecimal getBaseOrgId() {
        return baseOrgId;
    }

    /** This method sets the Zone ID of the ATP Record Object
     * @param zoneId, Zone ID value for the ATP Record Object
     */
    public void setZoneId(BigDecimal zoneId) {
        this.zoneId = zoneId;
    }

    /** This method returns the Zone ID value of the ATP Record Object
     * @return zoneId, Zone ID of the particular ATP Inquiry
     */
    public BigDecimal getZoneId() {
        return zoneId;
    }

    /** This method sets the Item Validation Org of the ATP Record Object
     * @param itemValOrg, Item Validation Org value for the ATP Record Object
     */
    public void setItemValOrg(String itemValOrg) {
        this.itemValOrg = itemValOrg;
    }

    /** This method returns the Item Validation Org value of the ATP Record Object
     * @return itemValOrg, Item Validation Org of the particular ATP Inquiry
     */
    public String getItemValOrg() {
        return itemValOrg;
    }

    /** This method sets the Source Item From XDock flag of the ATP Record Object
     * @param srcItemFromXdock, Source Item From XDock flag value for the ATP Record Object
     */
    public void setSrcItemFromXdock(String srcItemFromXdock) {
        this.srcItemFromXdock = srcItemFromXdock;
    }

    /** This method returns the Source Item From XDock flag value of the ATP Record Object
     * @return srcItemFromXdock, Source Item From XDock flag of the particular ATP Inquiry
     */
    public String getSrcItemFromXdock() {
        return srcItemFromXdock;
    }

    /** This method sets the Forced Substitute of the ATP Record Object
     * @param forcedSubstitute, Forced Substitute value for the ATP Record Object
     */
    public void setForcedSubstitute(String forcedSubstitute) {
        this.forcedSubstitute = forcedSubstitute;
    }

    /** This method returns the Forced Substitute value of the ATP Record Object
     * @return forcedSubstitute, Forced Substitute of the particular ATP Inquiry
     */
    public String getForcedSubstitute() {
        return forcedSubstitute;
    }

    /** This method sets the ATP Type Code of the ATP Record Object
     * @param atpTypeCode,  ATP Type Code value for the ATP Record Object
     */
    public void setAtpTypeCode(String[] atpTypeCode) {
        this.atpTypeCode = atpTypeCode;
    }

    /** This method sets the Atp Sequence of the ATP Record Object
     * @param atpSequence, Atp Sequence value for the ATP Record Object
     */
    public void setAtpSequence(BigDecimal[] atpSequence) {
        this.atpSequence = atpSequence;
    }

    /** This method sets the Assignment Set Id of the ATP Record Object
     * @param assignmentSetId, Assignment Set Id value for the ATP Record Object
     */
    public void setAssignmentSetId(BigDecimal assignmentSetId) {
        this.assignmentSetId = assignmentSetId;
    }

    /** This method returns the Assignment Set Id value of the ATP Record Object
     * @return assignmentSetId, Assignment Set Id of the particular ATP Inquiry
     */
    public BigDecimal getAssignmentSetId() {
        return assignmentSetId;
    }

    /** This method sets the Category Set Id of the ATP Record Object
     * @param categorySetId, Category Set Id value for the ATP Record Object
     */
    public void setCategorySetId(BigDecimal categorySetId) {
        this.categorySetId = categorySetId;
    }

    /** This method returns the Category Set Id value of the ATP Record Object
     * @return categorySetId, Category Set Id of the particular ATP Inquiry
     */
    public BigDecimal getCategorySetId() {
        return categorySetId;
    }

    /** This method sets the Source Org Id of the ATP Record Object
     * @param srcOrgId Source Org Id value for the ATP Record Object
     */
    public void setSrcOrgId(BigDecimal srcOrgId) {
        this.srcOrgId = srcOrgId;
    }

    /** This method returns the Source Org Id value of the ATP Record Object
     * @return srcOrgId, Source Org Id of the particular ATP Inquiry
     */
    public BigDecimal getSrcOrgId() {
        return srcOrgId;
    }

    /** This method sets the Requested Date Qty of the ATP Record Object
     * @param requestedDateQty, Requested Date Qty value for the ATP Record Object
     */
    public void setRequestedDateQty(BigDecimal requestedDateQty) {
        this.requestedDateQty = requestedDateQty;
    }

    /** This method returns the requestedDateQty  value of the ATP Record Object
     * @return requestedDateQty, Requested Date Qty of the particular ATP Inquiry
     */
    public BigDecimal getRequestedDateQty() {
        return requestedDateQty;
    }

    /** This method sets the TCSC Org Id of the ATP Record Object
     * @param tcscOrgId TCSC Org Id value for the ATP Record Object
     */
    public void setTcscOrgId(BigDecimal tcscOrgId) {
        this.tcscOrgId = tcscOrgId;
    }

    /** This method returns the TCSC Org Id value of the ATP Record Object
     * @return tcscOrgId, TCSC Org Id of the particular ATP Inquiry
     */
    public BigDecimal getTcscOrgId() {
        return tcscOrgId;
    }

    /** This method sets the Unit Weight of the ATP Record Object
     * @param unitWeight, Unit Weight value for the ATP Record Object
     */
    public void setUnitWeight(BigDecimal unitWeight) {
        this.unitWeight = unitWeight;
    }

    /** This method returns the Unit Weight value of the ATP Record Object
     * @return unitWeight, Unit Weight of the particular ATP Inquiry
     */
    public BigDecimal getUnitWeight() {
        return unitWeight;
    }

    /** This method sets the supplier Item of the ATP Record Object
     * @param supplierItem, supplier Item value for the ATP Record Object
     */
    public void setSupplierItem(String supplierItem) {
        this.supplierItem = supplierItem;
    }

    /** This method returns the supplier Item value of the ATP Record Object
     * @return supplierItem, supplier Item of the particular ATP Inquiry
     */
    public String getSupplierItem() {
        return supplierItem;
    }

    /** This method sets the Org Name of the ATP Record Object
     * @param orgName, Org Name value for the ATP Record Object
     */
    public void setOrgName(String orgName) {
        this.orgName = orgName;
    }

    /** This method returns the Org Name value of the ATP Record Object
     * @return orgName, Org Name of the particular ATP Inquiry
     */
    public String getOrgName() {
        return orgName;
    }

    /** This method sets the Source Supplier of the ATP Record Object
     * @param srcSupplier, Source Supplier value for the ATP Record Object
     */
    public void setSrcSupplier(String srcSupplier) {
        this.srcSupplier = srcSupplier;
    }

    /** This method returns the Source Supplier value of the ATP Record Object
     * @return srcSupplier, Source Supplier of the particular ATP Inquiry
     */
    public String getSrcSupplier() {
        return srcSupplier;
    }

    /** This method sets the Source Supplier Type of the ATP Record Object
     * @param srcSupplierType, Source Supplier Type value for the ATP Record Object
     */
    public void setSrcSupplierType(String srcSupplierType) {
        this.srcSupplierType = srcSupplierType;
    }

    /** This method returns the Source Supplier Type value of the ATP Record Object
     * @return srcSupplierType, Source Supplier Type of the particular ATP Inquiry
     */
    public String getSrcSupplierType() {
        return srcSupplierType;
    }

    /** This method sets the Source Supplier Site of the ATP Record Object
     * @param srcSupplierSite, Source Supplier Site value for the ATP Record Object
     */
    public void setSrcSupplierSite(String srcSupplierSite) {
        this.srcSupplierSite = srcSupplierSite;
    }

    /** This method returns the Source Supplier Site value of the ATP Record Object
     * @return srcSupplierSite, Source Supplier Site of the particular ATP Inquiry
     */
    public String getSrcSupplierSite() {
        return srcSupplierSite;
    }

    /** This method sets the Ship Method Code of the ATP Record Object
     * @param shipMethodCode, Ship Method Code value for the ATP Record Object
     */
    public void setShipMethodCode(String shipMethodCode) {
        this.shipMethodCode = shipMethodCode;
    }

    /** This method returns the Ship Method Code value of the ATP Record Object
     * @return shipMethodCode, Ship Method Code of the particular ATP Inquiry
     */
    public String getShipMethodCode() {
        return shipMethodCode;
    }

    /** This method sets the Atp Fullfillment Type of the ATP Record Object
     * @param atpFullfillmentType, Atp Fullfillment Type value for the ATP Record Object
     */
    public void setStpFullfillmentType(String atpFullfillmentType) {
        this.atpFullfillmentType = atpFullfillmentType;
    }

    /** This method returns the Atp Fullfillment Type value of the ATP Record Object
     * @return atpFullfillmentType, Atp Fullfillment Type of the particular ATP Inquiry
     */
    public String getatpFullfillmentType() {
        return atpFullfillmentType;
    }

    /** This method sets the Facility Code of the ATP Record Object
     * @param facilityCode Facility Code value for the ATP Record Object
     */
    public void setFacilityCode(String facilityCode) {
        this.facilityCode = facilityCode;
    }

    /** This method returns the Facility Code value of the ATP Record Object
     * @return facilityCode, Facility Code of the particular ATP Inquiry
     */
    public String getFacilityCode() {
        return facilityCode;
    }

    /** This method sets the Supplier Account of the ATP Record Object
     * @param supplierAccount, Supplier Account value for the ATP Record Object
     */
    public void setSupplierAccount(String supplierAccount) {
        this.supplierAccount = supplierAccount;
    }

    /** This method returns the Supplier Account value of the ATP Record Object
     * @return supplierAccount, Supplier Account of the particular ATP Inquiry
     */
    public String getSupplierAccount() {
        return supplierAccount;
    }

    /** This method sets the zone Name of the ATP Record Object
     * @param zoneName, zone Name value for the ATP Record Object
     */
    public void setZoneName(String zoneName) {
        this.zoneName = zoneName;
    }

    /** This method returns the zone Name value of the ATP Record Object
     * @return zoneName, zone Name of the particular ATP Inquiry
     */
    public String getZoneName() {
        return zoneName;
    }

    /** This method sets the shipto Location Postal Code of the ATP Record Object
     * @param shiptoLocPostalCode shipto Location Postal Code value for the ATP Record Object
     */
    public void setShiptoLocPostalCode(String shiptoLocPostalCode) {
        this.shiptoLocPostalCode = shiptoLocPostalCode;
    }

    /** This method returns the shipto Location Postal Code value of the ATP Record Object
     * @return shiptoLocPostalCode, shipto Location Postal Code of the particular ATP Inquiry
     */
    public String getShiptoLocPostalCode() {
        return shiptoLocPostalCode;
    }

    /** This method sets the XDock  of the ATP Record Object
     * @param xdockOnlyFlag, Arrival date value for the ATP Record Object
     */
    public void setXdockOnlyFlag(String xdockOnlyFlag) {
        this.xdockOnlyFlag = xdockOnlyFlag;
    }

    /** This method returns the xdock Only Flag value of the ATP Record Object
     * @return xdockOnlyFlag, xdockOnlyFlagof the particular ATP Inquiry
     */
    public String getXdockOnlyFlag() {
        return xdockOnlyFlag;
    }

    /**This method sets the pickup Flag flag of the ATP Record Object
     * @param pickupFlag, pickup flag value for the ATP Record Object
     */
    public void setPickupFlag(String pickupFlag) {
        this.pickupFlag = pickupFlag;
    }

    /** This method returns the PickUp Flag value of the ATP Record Object
     * @return pickupFlag, PickUp Flag of the particular ATP Inquiry
     */
    public String getPickupFlag() {
        return pickupFlag;
    }

    /** This method sets the session Id of the ATP Record Object
     * @param sessionId, session Id value for the ATP Record Object
     */
    public void setSessionId(BigDecimal sessionId) {
        this.sessionId = sessionId;
    }

    /** This method returns the Session Id value of the ATP Record Object
     * @return sessionId, Session Id of the particular ATP Inquiry
     */
    public BigDecimal getSessionId() {
        return sessionId;
    }

    /** This method sets the Substitute Item Id of the ATP Record Object
     * @param xrefItemId, xrefItemId value for the ATP Record Object
     */
    public void setXrefItemId(BigDecimal xrefItemId) {
        this.xrefItemId = xrefItemId;
    }

    /** This method returns the Substitute Item Id value of the ATP Record Object
     * @return xrefItemId, Substitute Item Id of the particular ATP Inquiry
     */
    public BigDecimal getXrefItemId() {
        return xrefItemId;
    }

    /** This method sets the ATP Fullfillment Type of the ATP Record Object
     * @param atpFullfillmentType, ATP Fullfillment Type value for the ATP Record Object
     */
    public void setAtpFullfillmentType(String atpFullfillmentType) {
        this.atpFullfillmentType = atpFullfillmentType;
    }

    /** This method returns the ATP Fullfillment Type value of the ATP Record Object
     * @return atpFullfillmentType, ATP Fullfillment Type of the particular ATP Inquiry
     */
    public String getAtpFullfillmentType() {
        return atpFullfillmentType;
    }
}// End ATPRecordType Class
