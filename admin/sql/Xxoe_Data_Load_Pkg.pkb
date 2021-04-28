create or replace PACKAGE Body Xxoe_Data_Load_Pkg
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Optimize                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name      :  XX_OE_DATA_LOAD_PKG                                                          |
  -- |  RICE ID   :                                              |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  ---| Rice 1272
    -- | 1.0      28-Apr-2021      Shreyas Thorat            Initial draft version  |
  -- +============================================================================================+
FUNCTION Getdata(
    P_Req NUMBER)
  RETURN VARCHAR2
IS
BEGIN
  NULL;
END Getdata;


  /*********************************************************************
  * Procedure used to log based on gb_debug value or if p_force is TRUE.
  * Will log to dbms_output if request id is not set,
  * else will log to concurrent program log file.  Will prepend
  * timestamp to each message logged.  This is useful for determining
  * elapse times.
  *********************************************************************/

  PROCEDURE logit(p_message  IN  VARCHAR2)
  IS
  lc_message VARCHAR2(32000);
  BEGIN
   lc_message := p_message;
      IF (fnd_global.conc_request_id > 0)
      THEN
        fnd_file.put_line(fnd_file.LOG, lc_message);
      ELSE
         DBMS_OUTPUT.put_line(lc_message);
      END IF;
  EXCEPTION
      WHEN OTHERS
      THEN
          NULL;
  END logit;


/* ===========================================================================*
 |  PUBLIC PROCEDURE Xxoe_Populate_Columns                                    |
 |                                                                            |
 |  DESCRIPTION                                                               |
 |  This procedure is used to load data into xxom interface table.            |
 |  After this it will cal validation procedure to load data in xxoe tables   |
 |                                                                            |
 |  This procedure will be called directly by Concurrent Program              |
 |                                                                            |
 * ===========================================================================*/

PROCEDURE Xxoe_Populate_Columns(
    Errbuf OUT VARCHAR2,
    Retcode OUT VARCHAR2)
IS
  L_Header_Id NUMBER;
  lc_order NUMBER;
  lc_seq_num NUMBER;
  lc_level VARCHAR2(50);
BEGIN
  FOR I IN
  (SELECT Order_Number ,
    Sub_Order_Number ,
    Process_Flag ,
    Status ,
	Sequence_Num,
    Json_Ord_Data
  FROM Xxom_Import_Int
  WHERE Process_Flag = 'I' AND status = 'New'
  )
  LOOP
    
	lc_order := i.Order_Number;
	lc_seq_num := i.Sequence_Num;
	lc_level := 'Order Header';
	--logit ('Processing Order :'||lc_order);
    BEGIN 
	
	INSERT
    INTO Xxom_Order_Headers_Int
      (
        Salesperson ,
        Shipping_Shiptoid ,
        Shipping_Shiptoname ,
        Shipping_Addressseq ,
        Shipping_City ,
        Shipping_Cost ,
        Shipping_Country ,
        Shipping_County ,
        Shipping_Line1 ,
        Shipping_Line2 ,
        Shiptolastupdatedate ,
        State ,
        Zip ,
        Accountid ,
        Actioncode ,
        Accertsyn ,
        Botaxpercent ,
        Bototal ,
        Ccalias ,
        Siteid ,
        Wname ,
        Alternateshipper ,
        Billcompleteflag ,
        Billing_Billtoname ,
        Billing_Addressseq ,
        Billing_Billtolastupdatedate ,
        Billing_City ,
        Billing_Country ,
        Billing_County ,
        Billing_Line1 ,
        Billing_Line2 ,
        Billing_State ,
        Billing_Zip ,
        Businessunit ,
        Cancelreason ,
        Commisionflag ,
        Costcentersplitflag ,
        Createbyid ,
        Custcustomertype ,
        Custponumber ,
        Customertaxexmptid ,
        Customertype ,
        Deliverymethod ,
        Depositamount ,
        Depositamountiflag ,
        Deptdescription ,
        Dropshipflag ,
        Extordnumber ,
        Freighttaxamt ,
        Freighttaxpercent ,
        Geolocation ,
        Giftflag ,
        Invlocid ,
        Invloctimezone ,
        Isdropship ,
        Iswholesale ,
        Kitoverrideflag ,
        Kittype ,
        Locationtype ,
        Loyaltyid ,
        Ordercategory ,
        Ordercomment1 ,
        Ordercomment2 ,
        Ordercomment3 ,
        Ordercreatetime ,
        Ordercurrency ,
        Orderdate ,
        Orderdatetimestamp ,
        Orderdelcode ,
        Orderdeloverridecode ,
        Orderdepartment ,
        Orderdesktop ,
        Orderendtime ,
        Ordergsttax ,
        Orderlobid ,
        Orderlastupdatedate ,
        Ordernumber ,
        Orderpsttax ,
        Orderrelease ,
        Ordersource ,
        Orderstatus ,
        Orderstatusdescription ,
        Ordersubtotal ,
        Ordertotal ,
        Ordertype ,
        Ordertype2 ,
        Ordertypedescription ,
        Orderustax ,
        Orderwebstatusdescription ,
        Ordersubnumber ,
        Originallocationid ,
        Originalordernumber ,
        Originalordersubnumber ,
        Originalsaledate ,
        Parentorder ,
        Pickupordeliverydate ,
        Pricecode ,
        Promiseddate ,
        Relatedorderscount_Long ,
        Returnactioncode ,
        Returncategorycode ,
        Returnreasoncode ,
        Routenumber ,
        Sectornumber ,
        Saledate ,
        Salelocid ,
        Saleschannel ,
        Salespersonloc ,
        Shipdate ,
        Soldto_Contactemailaddr ,
        Soldto_Contactfirstname ,
        Soldto_Contactlastname ,
        Soldto_Contactphone ,
        Soldto_Contactphoneext ,
        Soldto_Soldtocontact ,
        Spcacctnumber ,
        Splitorderflag ,
        Store_City ,
        Store_Country ,
        Store_Description ,
        Store_Line1 ,
        Store_Line2 ,
        Store_Phone ,
        Store_Receiptnumber ,
        Store_State ,
        Storenumber ,
        Store_Zipcode ,
        Taxpercent ,
        Taxableflag ,
        Totaladjustmentamount ,
        Totalsaleamount ,
        Totaltax ,
        Updatedby ,
        Clientip ,
        Lastuserid ,
        Originaluserid ,
        Header_Id ,
        Status
      )
    SELECT Salesperson ,
      Shipping_Shiptoid ,
      Shipping_Shiptoname ,
      Shipping_Addressseq ,
      Shipping_City ,
      Shipping_Cost ,
      Shipping_Country ,
      Shipping_County ,
      Shipping_Line1 ,
      Shipping_Line2 ,
      Shiptolastupdatedate ,
      State ,
      Zip ,
      Accountid ,
      Actioncode ,
      Accertsyn ,
      Botaxpercent ,
      Bototal ,
      Ccalias ,
      Siteid ,
      Wname ,
      Alternateshipper ,
      Billcompleteflag ,
      Billing_Billtoname ,
      Billing_Addressseq ,
      Billing_Billtolastupdatedate ,
      Billing_City ,
      Billing_Country ,
      Billing_County ,
      Billing_Line1 ,
      Billing_Line2 ,
      Billing_State ,
      Billing_Zip ,
      Businessunit ,
      Cancelreason ,
      Commisionflag ,
      Costcentersplitflag ,
      Createbyid ,
      Custcustomertype ,
      Custponumber ,
      Customertaxexmptid ,
      Customertype ,
      Deliverymethod ,
      Depositamount ,
      Depositamountiflag ,
      Deptdescription ,
      Dropshipflag ,
      Extordnumber ,
      Freighttaxamt ,
      Freighttaxpercent ,
      Geolocation ,
      Giftflag ,
      Invlocid ,
      Invloctimezone ,
      Isdropship ,
      Iswholesale ,
      Kitoverrideflag ,
      Kittype ,
      Locationtype ,
      Loyaltyid ,
      Ordercategory ,
      Ordercomment1 ,
      Ordercomment2 ,
      Ordercomment3 ,
      Ordercreatetime ,
      Ordercurrency ,
      Orderdate ,
      Orderdatetimestamp ,
      Orderdelcode ,
      Orderdeloverridecode ,
      Orderdepartment ,
      Orderdesktop ,
      Orderendtime ,
      Ordergsttax ,
      Orderlobid ,
      Orderlastupdatedate ,
      Ordernumber ,
      Orderpsttax ,
      Orderrelease ,
      Ordersource ,
      Orderstatus ,
      Orderstatusdescription ,
      Ordersubtotal ,
      Ordertotal ,
      Ordertype ,
      Ordertype2 ,
      Ordertypedescription ,
      Orderustax ,
      Orderwebstatusdescription ,
      Ordersubnumber ,
      Originallocationid ,
      Originalordernumber ,
      Originalordersubnumber ,
      Originalsaledate ,
      Parentorder ,
      Pickupordeliverydate ,
      Pricecode ,
      Promiseddate ,
      Relatedorderscount_Long ,
      Returnactioncode ,
      Returncategorycode ,
      Returnreasoncode ,
      Routenumber ,
      Sectornumber ,
      Saledate ,
      Salelocid ,
      Saleschannel ,
      Salespersonloc ,
      Shipdate ,
      Soldto_Contactemailaddr ,
      Soldto_Contactfirstname ,
      Soldto_Contactlastname ,
      Soldto_Contactphone ,
      Soldto_Contactphoneext ,
      Soldto_Soldtocontact ,
      Spcacctnumber ,
      Splitorderflag ,
      Store_City ,
      Store_Country ,
      Store_Description ,
      Store_Line1 ,
      Store_Line2 ,
      Store_Phone ,
      Store_Receiptnumber ,
      Store_State ,
      Storenumber ,
      Store_Zipcode ,
      Taxpercent ,
      Taxableflag ,
      Totaladjustmentamount ,
      Totalsaleamount ,
      Totaltax ,
      Updatedby ,
      Clientip ,
      Lastuserid ,
      Originaluserid ,
      Xxom_Header_Data_Seq.Nextval ,
      'New'
    FROM Dual,
      Json_Table (I.Json_Ord_Data, '$.orderHeader[*]' Columns ( Salesperson VARCHAR2(30) Path '$.SalesPerson' ,
      --Shipping
      Shipping_Shiptoid VARCHAR2(30) Path '$.Shipping.ShipToID', Shipping_Shiptoname VARCHAR2(50) Path '$.Shipping.ShipToName', Shipping_Addressseq VARCHAR2(50) Path '$.Shipping.addressseq', Shipping_City VARCHAR2(30) Path '$.Shipping.city', Shipping_Cost VARCHAR2(30) Path '$.Shipping.cost', Shipping_Country VARCHAR2(30) Path '$.Shipping.country', Shipping_County VARCHAR2(30) Path '$.Shipping.county', Shipping_Line1 VARCHAR2(50) Path '$.Shipping.line1', Shipping_Line2 VARCHAR2(50) Path '$.Shipping.line2', Shiptolastupdatedate VARCHAR2(30) Path '$.Shipping.shipToLastUpdateDate', State VARCHAR2(30) Path '$.Shipping.state', Zip VARCHAR2(30) Path '$.Shipping.zip',
      /*
      NESTED PATH '$.Shipping'
      COLUMNS (ShipToID VARCHAR2(30) PATH '$.ShipToID',
      ShipToName VARCHAR2(50) PATH '$.ShipToName',
      addressseq VARCHAR2(50) PATH '$.addressseq',
      city VARCHAR2(30) PATH '$.city',
      cost VARCHAR2(30) PATH '$.cost',
      country VARCHAR2(30) PATH '$.country',
      county VARCHAR2(30) PATH '$.county',
      line1 VARCHAR2(50) PATH '$.line1',
      line2 VARCHAR2(50) PATH '$.line2',
      shipToLastUpdateDate VARCHAR2(30) PATH '$.shipToLastUpdateDate',
      state VARCHAR2(30) PATH '$.state',
      zip VARCHAR2(30) PATH '$.zip')  , -- Need to Check
      */
      Accountid NUMBER Path '$.accountId' , Actioncode VARCHAR2(10) Path '$.actionCode' , Accertsyn VARCHAR2(150) Path '$.addValues.AccertSyn' , Botaxpercent VARCHAR2(150) Path '$.addValues.BOTaxPercent' , Bototal VARCHAR2(150) Path '$.addValues.BOTotal' , Ccalias VARCHAR2(150) Path '$.addValues.CCALIAS' ,
      --COF_COF_RECUR VARCHAR2(150) PATH '$.addValues.COF-COF-RECUR' ,
      --Mobile_App_Id VARCHAR2(150) PATH '$.addValues.Mobile-App-Id' ,
      Siteid VARCHAR2(150) Path '$.addValues.SITEID' ,
      --SOURCE_APP VARCHAR2(150) PATH '$.addValues.SOURCE-APP' ,
      Wname VARCHAR2(150) Path '$.addValues.WNAME' , Alternateshipper VARCHAR2(10) Path '$.alternateShipper' , Billcompleteflag VARCHAR2(1) Path '$.billCompleteFlag' ,
      --billing
      Billing_Billtoname VARCHAR2(50) Path '$.billing.BillToName', Billing_Addressseq VARCHAR2(100) Path '$.billing.addressseq', Billing_Billtolastupdatedate VARCHAR2(30) Path '$.billing.billToLastUpdateDate', Billing_City VARCHAR2(30) Path '$.billing.city', Billing_Country VARCHAR2(30) Path '$.billing.country', Billing_County VARCHAR2(30) Path '$.billing.county', Billing_Line1 VARCHAR2(50) Path '$.billing.line1', Billing_Line2 VARCHAR2(50) Path '$.billing.line2', Billing_State VARCHAR2(30) Path '$.billing.state', Billing_Zip VARCHAR2(30) Path '$.billing.zip',
      /*
      NESTED PATH '$.billing'
      COLUMNS (BillToName VARCHAR2(50) PATH '$.BillToName',
      addressseq VARCHAR2(100) PATH '$.addressseq',
      billToLastUpdateDate VARCHAR2(30) PATH '$.billToLastUpdateDate',
      city VARCHAR2(30) PATH '$.city',
      country VARCHAR2(30) PATH '$.country',
      county VARCHAR2(30) PATH '$.county',
      line1 VARCHAR2(50) PATH '$.line1',
      line2 VARCHAR2(50) PATH '$.line2',
      state VARCHAR2(30) PATH '$.state',
      zip VARCHAR2(30) PATH '$.zip')  , -- Need to Check
      */
      Businessunit                    VARCHAR2(10) Path '$.businessUnit' , Cancelreason VARCHAR2(30) Path '$.cancelReason' , Commisionflag VARCHAR2(1) Path '$.commisionFlag' , Costcentersplitflag VARCHAR2(1) Path '$.costCenterSplitFlag' , Createbyid VARCHAR2(30) Path '$.createById' , Custcustomertype VARCHAR2(1) Path '$.custCustomerType' , Custponumber VARCHAR2(30) Path '$.custPONumber' , Customertaxexmptid VARCHAR2(30) Path '$.customerTaxExmptId' , Customertype VARCHAR2(1) Path '$.customerType' , Deliverymethod VARCHAR2(30) Path '$.deliveryMethod' , Depositamount NUMBER Path '$.depositAmount' , Depositamountiflag VARCHAR2(1) Path '$.depositAmountIFlag' , Deptdescription VARCHAR2(30) Path '$.deptDescription' , Dropshipflag VARCHAR2(1) Path '$.dropShipFlag' , Extordnumber VARCHAR2(30) Path '$.extOrdNumber' , Freighttaxamt NUMBER Path '$.freightTaxAmt' , Freighttaxpercent NUMBER Path '$.freightTaxPercent' , Geolocation VARCHAR2(30) Path '$.geoLocation' , Giftflag VARCHAR2(1) Path '$.giftFlag' , Invlocid
                                      NUMBER Path '$.invLocId' , Invloctimezone VARCHAR2(5) Path '$.invLocTimeZone' , Isdropship VARCHAR2(5) Path '$.isDropShip' , Iswholesale VARCHAR2(5) Path '$.isWholeSale' , Kitoverrideflag VARCHAR2(1) Path '$.kitOverrideFlag' , Kittype VARCHAR2(20) Path '$.kitType' , Locationtype VARCHAR2(10) Path '$.locationType' , Loyaltyid NUMBER Path '$.loyaltyId' , Ordercategory VARCHAR2(1) Path '$.orderCategory' , Ordercomment1 VARCHAR2(200) Path '$.orderComment1' , Ordercomment2 VARCHAR2(200) Path '$.orderComment2' , Ordercomment3 VARCHAR2(200) Path '$.orderComment3' , Ordercreatetime NUMBER Path '$.orderCreateTime' , Ordercurrency VARCHAR2(3) Path '$.orderCurrency' , Orderdate VARCHAR2(15) Path '$.orderDate' , Orderdatetimestamp VARCHAR2(40) Path '$.orderDateTimestamp' , Orderdelcode VARCHAR2(1) Path '$.orderDelCode' , Orderdeloverridecode VARCHAR2(15) Path '$.orderDelOverrideCode' , Orderdepartment VARCHAR2(10) Path '$.orderDepartment' , Orderdesktop VARCHAR2(10) Path
      '$.orderDesktop' , Orderendtime NUMBER Path '$.orderEndTime' , Ordergsttax NUMBER Path '$.orderGSTTax' , Orderlobid VARCHAR2(10) Path '$.orderLOBId' , Orderlastupdatedate VARCHAR2(15) Path '$.orderLastUpdateDate' , Ordernumber VARCHAR2(30) Path '$.orderNumber' , Orderpsttax NUMBER Path '$.orderPSTTax' , Orderrelease VARCHAR2(50) Path '$.orderRelease' , Ordersource VARCHAR2(25) Path '$.orderSource' , Orderstatus VARCHAR2(25) Path '$.orderStatus' , Orderstatusdescription VARCHAR2(150) Path '$.orderStatusDescription' , Ordersubtotal NUMBER Path '$.orderSubTotal' , Ordertotal NUMBER Path '$.orderTotal' , Ordertype VARCHAR2(20) Path '$.orderType' , Ordertype2 VARCHAR2(15) Path '$.orderType2' , Ordertypedescription VARCHAR2(40) Path '$.orderTypeDescription' , Orderustax NUMBER Path '$.orderUSTax' , Orderwebstatusdescription VARCHAR2(30) Path '$.orderWebStatusDescription' , Ordersubnumber VARCHAR2(30) Path '$.ordersubNumber' , Originallocationid VARCHAR2(1) Path '$.originalLocationId'
      , Originalordernumber           VARCHAR2(30) Path '$.originalOrderNumber' , Originalordersubnumber VARCHAR2(30) Path '$.originalOrderSubNumber' , Originalsaledate VARCHAR2(30) Path '$.originalSaleDate' , Parentorder VARCHAR2(30) Path '$.parentOrder' , Pickupordeliverydate VARCHAR2(20) Path '$.pickupOrDeliveryDate' , Pricecode VARCHAR2(10) Path '$.priceCode' , Promiseddate VARCHAR2(15) Path '$.promisedDate' , Relatedorderscount_Long VARCHAR2(10) Path '$.relatedOrdersCount_long' , Returnactioncode VARCHAR2(10) Path '$.returnActionCode' , Returncategorycode VARCHAR2(15) Path '$.returnCategoryCode' , Returnreasoncode VARCHAR2(50) Path '$.returnReasonCode' ,
      --route
      Routenumber VARCHAR2(30) Path '$.route.routeNumber', Sectornumber VARCHAR2(30) Path '$.route.sectorNumber',
      /*
      NESTED PATH '$.route'
      COLUMNS (routeNumber VARCHAR2(30) PATH '$.routeNumber',
      sectorNumber VARCHAR2(30) PATH '$.sectorNumber')  , -- Need to Check
      */
      Saledate VARCHAR2(30) Path '$.saleDate' , Salelocid VARCHAR2(30) Path '$.saleLocId' , Saleschannel VARCHAR2(20) Path '$.salesChannel' , Salespersonloc VARCHAR2(20) Path '$.salesPersonLoc' , Shipdate VARCHAR2(30) Path '$.shipDate' ,
      --soldTo Group
      Soldto_Contactemailaddr VARCHAR2(30) Path '$.soldTo.contactEmailAddr', Soldto_Contactfirstname VARCHAR2(30) Path '$.soldTo.contactFirstName', Soldto_Contactlastname VARCHAR2(30) Path '$.soldTo.contactLastName', Soldto_Contactphone VARCHAR2(30) Path '$.soldTo.contactPhone', Soldto_Contactphoneext VARCHAR2(30) Path '$.soldTo.contactPhoneExt', Soldto_Soldtocontact VARCHAR2(30) Path '$.soldTo.soldToContact' ,
      /*
      NESTED PATH '$.soldTo'
      COLUMNS (contactEmailAddr VARCHAR2(30) PATH '$.contactEmailAddr',
      contactFirstName VARCHAR2(30) PATH '$.contactFirstName',
      contactLastName VARCHAR2(30) PATH '$.contactLastName',
      contactPhone VARCHAR2(30) PATH '$.contactPhone',
      contactPhoneExt VARCHAR2(30) PATH '$.contactPhoneExt',
      soldToContact VARCHAR2(30) PATH '$.soldToContact')  , -- Need to Check
      */
      -----
      Spcacctnumber VARCHAR2(30) Path '$.spcAcctNumber' , Splitorderflag VARCHAR2(1) Path '$.splitOrderFlag' ,
      --Store Group
      Store_City VARCHAR2(30) Path '$.store.city', Store_Country VARCHAR2(30) Path '$.store.country', Store_Description VARCHAR2(30) Path '$.store.description', Store_Line1 VARCHAR2(30) Path '$.store.line1', Store_Line2 VARCHAR2(30) Path '$.store.line2', Store_Phone VARCHAR2(30) Path '$.store.phone', Store_Receiptnumber VARCHAR2(30) Path '$.store.receiptNumber', Store_State VARCHAR2(30) Path '$.store.state', Storenumber VARCHAR2(30) Path '$.store.storeNumber', Store_Zipcode VARCHAR2(30) Path '$.store.zipCode' , -- Need to Check
      Taxpercent NUMBER Path '$.taxPercent' , Taxableflag VARCHAR2(1) Path '$.taxableFlag' , Totaladjustmentamount NUMBER Path '$.totalAdjustmentAmount' , Totalsaleamount NUMBER Path '$.totalSaleAmount' , Totaltax NUMBER Path '$.totalTax' , Updatedby VARCHAR2(30) Path '$.updatedBy' ,Clientip VARCHAR2(30) Path '$.webOrderInf.clientIP' ,Lastuserid VARCHAR2(30) Path '$.webOrderInf.lastUserId' ,Originaluserid VARCHAR2(30) Path '$.webOrderInf.originalUserId'
      /*
      NESTED PATH '$.webOrderInf'
      COLUMNS (clientIP VARCHAR2(30) PATH '$.clientIP',
      lastUserId VARCHAR2(30) PATH '$.lastUserId',
      originalUserId VARCHAR2(30) PATH '$.originalUserId')   -- Need to Check
      */
      )) ;
    
	SELECT Xxom_Header_Data_Seq.Currval INTO L_Header_Id FROM Dual;
	
	lc_level := 'Order Line';
	
    INSERT
    INTO Xxom_Order_Lines_Int
      (
        Avgcost ,
        Backorderquantity ,
        Bundleid ,
        Campaigncode ,
        Configurationid ,
        Contractcode ,
        Coretype ,
        Costcentercode ,
        Costcenterdescription ,
        Customerproductcode ,
        Department ,
        Division ,
        Enteredproductcode ,
        Extendedprice ,
        Gsaflag ,
        Itemdescription ,
        Itemsource ,
        Itemtype ,
        Kitdept ,
        Kitquantity ,
        Kitseq ,
        Kitsku ,
        Kitvpc ,
        Linecomments ,
        Linenumber ,
        Carrier ,
        Trackingid ,
        Listprice ,
        Omxsku ,
        Originalitemprice ,
        Pocost ,
        Polinenum ,
        Price ,
        Priceoverridecode ,
        Pricetype ,
        Quantity ,
        Shipquantity ,
        Sku ,
        Taxamt ,
        Taxpercent ,
        Unit ,
        Upc ,
        Vendorid ,
        Vendorproductcode ,
        Vendorshipperaccount ,
        Wholesalerproductnumber ,
        Header_Id ,
        Line_Id ,
        Status
      )
    SELECT Avgcost ,
      Backorderquantity ,
      Bundleid ,
      Campaigncode ,
      Configurationid ,
      Contractcode ,
      Coretype ,
      Costcentercode ,
      Costcenterdescription ,
      Customerproductcode ,
      Department ,
      Division ,
      Enteredproductcode ,
      Extendedprice ,
      Gsaflag ,
      Itemdescription ,
      Itemsource ,
      Itemtype ,
      Kitdept ,
      Kitquantity ,
      Kitseq ,
      Kitsku ,
      Kitvpc ,
      Linecomments ,
      Linenumber ,
      Carrier ,
      Trackingid ,
      Listprice ,
      Omxsku ,
      Originalitemprice ,
      Pocost ,
      Polinenum ,
      Price ,
      Priceoverridecode ,
      Pricetype ,
      Quantity ,
      Shipquantity ,
      Sku ,
      Taxamt ,
      Taxpercent ,
      Unit ,
      Upc ,
      Vendorid ,
      Vendorproductcode ,
      Vendorshipperaccount ,
      Wholesalerproductnumber ,
      L_Header_Id ,
      Xxom_Line_Data_Seq.Nextval ,
      'New'
    FROM Dual,
      Json_Table (I.Json_Ord_Data, '$.orderLines[*]' Columns ( Avgcost NUMBER Path '$.avgCost' , Backorderquantity NUMBER Path '$.backorderQuantity' , Bundleid VARCHAR2(30) Path '$.bundleId' , Campaigncode VARCHAR2(30) Path '$.campaignCode' , Configurationid VARCHAR2(30) Path '$.configurationId' , Contractcode VARCHAR2(30) Path '$.contractCode' , Coretype VARCHAR2(30) Path '$.coreType' , Costcentercode VARCHAR2(3) Path '$.costCenterCode' , Costcenterdescription VARCHAR2(50) Path '$.costCenterDescription' , Customerproductcode VARCHAR2(30) Path '$.customerProductCode' , Department VARCHAR2(30) Path '$.department' , Division VARCHAR2(30) Path '$.division' , Enteredproductcode VARCHAR2(30) Path '$.enteredProductCode' , Extendedprice NUMBER Path '$.extendedPrice' , Gsaflag NUMBER Path '$.gsaFlag' , Itemdescription VARCHAR2(50) Path '$.itemDescription' , Itemsource VARCHAR2(30) Path '$.itemSource' , Itemtype VARCHAR2(30) Path '$.itemType' , Kitdept VARCHAR2(30) Path '$.kitDept' ,
      Kitquantity                                                      NUMBER Path '$.kitQuantity' , Kitseq VARCHAR2(50) Path '$.kitSeq' , Kitsku VARCHAR2(50) Path '$.kitSku' , Kitvpc VARCHAR2(50) Path '$.kitVPC' , Linecomments VARCHAR2(50) Path '$.lineComments' , Linenumber NUMBER Path '$.lineNumber' ,
      --lineTrackingNumbers
      Carrier VARCHAR2(50) Path '$.lineTrackingNumbers.carrier' , Trackingid VARCHAR2(50) Path '$.lineTrackingNumbers.trackingId' , Listprice NUMBER Path '$.listPrice' , Omxsku VARCHAR2(30) Path '$.omxSku' , Originalitemprice NUMBER Path '$.originalItemPrice' , Pocost NUMBER Path '$.poCost' , Polinenum NUMBER Path '$.poLineNum' , Price NUMBER Path '$.price' , Priceoverridecode VARCHAR2(30) Path '$.priceOverrideCode' , Pricetype VARCHAR2(30) Path '$.priceType' , Quantity NUMBER Path '$.quantity' , Shipquantity NUMBER Path '$.shipQuantity' , Sku VARCHAR2(30) Path '$.sku' , Taxamt NUMBER Path '$.taxAmt' , Taxpercent NUMBER Path '$.taxPercent' , Unit VARCHAR2(30) Path '$.unit' , Upc VARCHAR2(30) Path '$.upc' , Vendorid VARCHAR2(30) Path '$.vendorID' , Vendorproductcode VARCHAR2(30) Path '$.vendorProductCode' , Vendorshipperaccount VARCHAR2(30) Path '$.vendorShipperAccount' , Wholesalerproductnumber VARCHAR2(30) Path '$.wholesalerProductNumber' ));
    
	lc_level := 'Order Adjustment';
	
    INSERT
    INTO Xxom_Order_Adjustments_Int
      (
        Acctingcouponamount ,
        Adjustmentcode ,
        Adjustmentseqnum ,
        Couponid ,
        Displaycouponamount ,
        Employeeid ,
        Linenum ,
        Adjustment_Id ,
        Header_Id ,
        Line_Id ,
        Status
      )
    SELECT Acctingcouponamount ,
      Adjustmentcode ,
      Adjustmentseqnum ,
      Couponid ,
      Displaycouponamount ,
      Employeeid ,
      Linenum ,
      Xxom_Adjustment_Data_Seq.Nextval ,
      L_Header_Id ,
      (SELECT Line_Id
      FROM Xxom_Order_Lines_Int
      WHERE Header_Id = L_Header_Id
      AND Linenumber  = Linenum
      ) ,
      'New'
    FROM Dual,
      Json_Table (I.Json_Ord_Data, '$.orderAdjustments[*]' Columns (Acctingcouponamount NUMBER Path '$.acctingCouponAmount', Adjustmentcode VARCHAR2(10) Path '$.adjustmentCode', Adjustmentseqnum NUMBER Path '$.adjustmentSeqNum', Couponid NUMBER Path '$.couponId', Displaycouponamount NUMBER Path '$.displayCouponAmount', Employeeid NUMBER Path '$.employeeId', Linenum NUMBER Path '$.lineNum')) ;
    
	lc_level := 'Order Tender';
	
    INSERT
    INTO Xxom_Order_Tenders_Int
      (
        Accountnumber ,
        Acctencryptionkey ,
        Addrverificationcode ,
        Amount ,
        Authentrymode ,
        Authps2000 ,
        Cardnumber ,
        Ccauthcode ,
        Ccauthdate ,
        Ccencryptionkey ,
        Ccmanualauth ,
        Ccrespcode ,
        Cctype ,
        Clrtexttokenflag ,
        Credentialonfile ,
        Desencryptionkey ,
        Expirydate ,
        Method ,
        Paysubtype ,
        Header_Id ,
        Tender_Id ,
        Status ,
		payment_ref
      )
    SELECT Accountnumber ,
      Acctencryptionkey ,
      Addrverificationcode ,
      Amount ,
      Authentrymode ,
      Authps2000 ,
      Cardnumber ,
      Ccauthcode ,
      Ccauthdate ,
      Ccencryptionkey ,
      Ccmanualauth ,
      Ccrespcode ,
      Cctype ,
      Clrtexttokenflag ,
      Credentialonfile ,
      Desencryptionkey ,
      Expirydate ,
      Method ,
      Paysubtype ,
      L_Header_Id ,
      Xxom_Tender_Data_Seq.Nextval ,
      'New',
	  payment_ref
    FROM Dual,
      Json_Table (I.Json_Ord_Data, '$.orderTenders[*]' Columns ( Accountnumber VARCHAR2(30) Path '$.accountNumber' , Acctencryptionkey VARCHAR2(100) Path '$.acctEncryptionKey' , Addrverificationcode VARCHAR2(30) Path '$.addrVerificationCode' , Amount NUMBER Path '$.amount' , Authentrymode VARCHAR2(30) Path '$.authEntryMode' , Authps2000 VARCHAR2(30) Path '$.authPS2000' , Cardnumber VARCHAR2(30) Path '$.cardNumber' , Ccauthcode VARCHAR2(30) Path '$.ccAuthCode' , Ccauthdate VARCHAR2(30) Path '$.ccAuthDate' , Ccencryptionkey VARCHAR2(100) Path '$.ccEncryptionKey' , Ccmanualauth VARCHAR2(30) Path '$.ccManualAuth' , Ccrespcode VARCHAR2(30) Path '$.ccRespCode' , Cctype VARCHAR2(30) Path '$.ccType' , Clrtexttokenflag VARCHAR2(1) Path '$.clrTextTokenFlag' , Credentialonfile VARCHAR2(100) Path '$.credentialOnFile' , Desencryptionkey VARCHAR2(100) Path '$.desEncryptionKey' , Expirydate VARCHAR2(30) Path '$.expiryDate' , Method VARCHAR2(30) Path '$.method' , Paysubtype VARCHAR2(30) Path 
      '$.paySubType' , payment_ref VARCHAR2(20) Path '$.payment_ref' ));
  EXCEPTION
  WHEN OTHERS THEN
	logit ('Error in Xxoe_Populate_Columns while inserting '|| lc_level ||' data of '||lc_order||' into xxom int tables. Error Code:'||SQLCODE);
	logit ('Error Message: '||SQLERRM);
	
	UPDATE Xxom_Import_Int
	set Process_Flag = 'E',Status = 'Error', error_description = 'Error while inserting ' ||lc_level|| ' data'
	where Order_Number = lc_order
	AND Sequence_Num = lc_seq_num
	and Process_Flag = 'P'
	and status = 'New';
	
	delete from Xxom_Order_Headers_Int
	where header_id = L_Header_Id;
		
	delete from Xxom_Order_Lines_Int
	where header_id = L_Header_Id;
	
	delete from Xxom_Order_Adjustments_Int
	where header_id = L_Header_Id;
	
	delete from Xxom_Order_Tenders_Int
	where header_id = L_Header_Id;
	
  END;
  END LOOP;
  UPDATE Xxom_Import_Int SET Process_Flag = 'P', status = 'Processed' WHERE Process_Flag = 'I' and status = 'New';
  Xxoe_Validate_Data;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  logit ('Error in Proc Xxoe_Populate_Columns Error Code:'||SQLCODE);
  logit ('Error Message: '||SQLERRM);
END Xxoe_Populate_Columns;


/* ===========================================================================*
 |  PUBLIC PROCEDURE Xxoe_Data_Load_Prc                                       |
 |                                                                            |
 |  DESCRIPTION                                                               |
 |  This procedure is used to split json file order wise and load             |
 |  each order payload into interface table                                   |
 |                                                                            |
 |  This procedure will be called directly by Concurrent Program              |
 |                                                                            |
 * ===========================================================================*/
PROCEDURE Xxoe_Data_Load_Prc(
    Errbuf OUT VARCHAR2,
    Retcode OUT VARCHAR2,
    P_File VARCHAR2)
IS
  L_Bfile Bfile;
  L_Clob CLOB;
  Buf Raw(32767 );
  Vc      VARCHAR2(32767 );
  Maxsize INTEGER := 32767 ; -- a char can take up to 4 bytes,
  -- so this is the maximum safe length in chars
  Amt      INTEGER      :=1;
  Amtvc    INTEGER      :=1;
  V_Offset INTEGER      := 1;
  Dir_Name VARCHAR2(150) := 'NEW_SAS_ORD_DIR'; --/app/ebs/ctgsiprjdevgb/xxfin/inbound/hvop
  --arcihve folder need to create
  --/app/ebs/ctgsiprjdevgb/xxfin/archive/hvop
  File_Name      VARCHAR2(150) := P_File ;--'test_data_3_lines.json';
  L_Dest_Offset  INTEGER      := 1;
  L_Src_Offset   INTEGER      := 1;
  L_Bfile_Csid   NUMBER       := 0;
  L_Lang_Context INTEGER      := 0;
  L_Warning      INTEGER      := 0;
  Tl_Clob CLOB;
  L_Ord_Number     VARCHAR2(30);
  L_Sub_Ord_Number VARCHAR2(30);
BEGIN
  L_Bfile                         := Bfilename(Dir_Name, File_Name);
  IF (Dbms_Lob.Fileexists(L_Bfile) = 1) THEN
    Dbms_Output.Put_Line('File Exists');
    INSERT
    INTO Xxom_Imp_Cache_Int T VALUES
      (
        Empty_Clob() ,
        Sysdate ,
        FND_GLOBAL.user_id ,
        FND_GLOBAL.user_id ,
        Sysdate
      )
      RETURN Ord_Json_Data
    INTO L_Clob;
    L_Bfile := Bfilename(Dir_Name, File_Name);
    Amt     := Dbms_Lob.Getlength( L_Bfile );
    Dbms_Lob.Fileopen( L_Bfile, Dbms_Lob.File_Readonly );
    WHILE Amt > 0
    LOOP
      IF Amt > Maxsize THEN
        Amt := Maxsize;
      END IF;
      Dbms_Lob.Read( L_Bfile,Amt, V_Offset, Buf );
      Vc    := Utl_Raw.Cast_To_Varchar2(Buf);
      Amtvc := LENGTH(Vc);
      Dbms_Lob.Writeappend( L_Clob, Amtvc, Vc );
      V_Offset := V_Offset                      + Amt;
      Amt      := Dbms_Lob.Getlength( L_Bfile ) - V_Offset + 1;
    END LOOP;
    Dbms_Lob.Fileclose( L_Bfile );
    COMMIT;
    --select count(sequence_num) from xx_om_order_payload;
    FOR Json_Data IN
    (WITH Clob_Table(C) AS
      (SELECT Ord_Json_Data C FROM Xxom_Imp_Cache_Int
      ),
      Recurse(Text,Line) AS
      (SELECT Regexp_Substr(C, '.+', 1, 1) Text,1 Line FROM Clob_Table
      UNION ALL
      SELECT Regexp_Substr(C, '.+', 1, Line+1),
        Line                               +1
      FROM Recurse R,
        Clob_Table
      WHERE Line<Regexp_Count(C, '.+')
      )
    SELECT Text,Line,Xx_Om_Json_Data_Seq.Nextval Seq_Num FROM Recurse
    )
    LOOP
      BEGIN
        SELECT Ordernumber,
          Ordersubnumber
        INTO L_Ord_Number ,
          L_Sub_Ord_Number
        FROM Dual ,
          Json_Table (Json_Data.Text,'$.orderHeader[*]' Columns ( Ordernumber VARCHAR2(30) Path '$.orderNumber' , Ordersubnumber VARCHAR2(30) Path '$.ordersubNumber' ) );
      EXCEPTION
      WHEN OTHERS THEN
        
		logit ('Error in Proc Xxoe_Data_Load_Prc while getting order and sub_order_num. Error Code:'||SQLCODE);
        logit ('Error Message: '||SQLERRM);
		L_Ord_Number     :='';
        L_Sub_Ord_Number := '';
		
      END;
      INSERT
      INTO Xxom_Import_Int
        (
          Request_Id ,
          Sequence_Num ,
          Order_Number ,
          Sub_Order_Number ,
          Process_Flag ,
          Status ,
          Json_Ord_Data ,
		  file_name,
          Creation_Date ,
          Created_By ,
          Last_Updated_By ,
          Last_Update_Date
        )
        VALUES
        (
          fnd_global.conc_request_id ,
          Json_Data.Seq_Num ,
          L_Ord_Number ,
          L_Sub_Ord_Number ,
          'I' ,
          'New' ,
          Json_Data.Text ,
		  file_name,
          Sysdate ,
          FND_GLOBAL.user_id ,
          FND_GLOBAL.user_id ,
          Sysdate
        ) ;--returning json_ord_data into tl_clob;
      --tl_clob := json_data.text;
    END LOOP;
	
    DELETE
    FROM Xxom_Imp_Cache_Int;
    COMMIT;
    --xxoe_populate_columns;
  ELSE
    --Dbms_Output.Put_Line('File does not exist');
	logit ('File does not exist');
  END IF;

EXCEPTION
WHEN OTHERS THEN
  logit ('Error in Proc Xxoe_Data_Load_Prc Error Code:'||SQLCODE);
  logit ('Error Message: '||SQLERRM);
END Xxoe_Data_Load_Prc;

/* ===========================================================================*
 |  PUBLIC PROCEDURE Xxoe_Validate_Data                                       |
 |                                                                            |
 |  DESCRIPTION                                                               |
 |  This procedure is used to validated and load data into xxoe tables        |
 |  each order payload into interface table                                   |
 |                                                                            |
 |  This procedure will be called from  Xxoe_Populate_Columns proc            |
 |                                                                            |
 * ===========================================================================*/
PROCEDURE Xxoe_Validate_Data
IS
  L_Header_Id NUMBER;
  lc_int_order_number VARCHAR2(50) ; 
  lc_sub_order_number VARCHAR2(50) ;
  lc_level VARCHAR2(50);
  lc_int_header_id NUMBER;
BEGIN
  FOR I  IN
  (SELECT *
  FROM Xxom_Order_Headers_Int
  WHERE Status = 'New'
  ORDER BY Header_Id
  )
  LOOP
   
   lc_int_order_number := I.Ordernumber ;
   lc_sub_order_number := I.Ordersubnumber;
   lc_int_header_id := I.Header_Id;
   
   BEGIN
    SELECT Xx_Oe_Ord_Header_Seq.Nextval INTO L_Header_Id FROM Dual;
    
	lc_level := 'Order Header';
	
	INSERT
    INTO Xx_Oe_Order_Headers_All
      (
        Header_Id ,
        Order_Type_Id ,
        Order_Number ,
		ORIG_SYS_DOCUMENT_REF,
        Version_Number ,
        Order_Category_Code ,
        Open_Flag ,
        Booked_Flag ,
        Creation_Date ,
        Created_By ,
        Last_Updated_By ,
        Last_Update_Date ,
        Order_Source_Id ,
        Ordered_Date ,
		PRICING_DATE,
        Tax_Exempt_Number ,
        Transactional_Curr_Code ,
        Cust_Po_Number ,
        Ship_From_Org_Id ,
        Salesrep_Id ,
        Sales_Channel_Code ,
        Drop_Ship_Flag ,
		FREIGHT_CARRIER_CODE,
		ORG_ID,
		REQUEST_ID,
		REQUEST_DATE
      )
      VALUES
      (
        L_Header_Id ,
        1 ,
        I.Ordernumber || I.Ordersubnumber,
		I.Ordernumber || I.Ordersubnumber,
        1,
        I.Ordercategory ,
        'Y',
        'Y' ,
        Sysdate,
        FND_GLOBAL.user_id,
        FND_GLOBAL.user_id,
        Sysdate ,
        NULL--derive from ORDERSOURCE
        ,
        to_date(i.ORDERDATE,'RRRR-MM-DD'),
		to_date(i.ORDERDATE,'RRRR-MM-DD'),
        I.Customertaxexmptid ,
        I.Ordercurrency ,
        I.Custponumber ,
        I.Invlocid ,
        NULL --SALESPERSON -- derive sale_person_id
        ,
        I.Saleschannel -- derive from OE_LOOKUPS
        ,
        I.Dropshipflag ,
		I.DELIVERYMETHOD,
		FND_PROFILE.VALUE('ORG_ID'),
		fnd_global.conc_request_id ,
		SYSDATE
      );

	lc_level := 'Order Header Attribute';
	
    INSERT
    INTO Xx_Oe_Header_Attributes_All
      (
        Header_Id ,
		canada_pst_tax,
        Release_Number ,
        CUST_DEPT_NO,
		DESKTOP_LOC_ADDR,
		Gift_Flag ,
        Alt_Delv_Address ,
        --Created_By_Store_Id ,
        --Paid_At_Store_Id ,
        Spc_Card_Number ,
		LOYALTY_ID,
        Created_By_Id ,
        Delivery_Method ,
		DELIVERY_CODE,
        Cust_Pref_Email ,
        Cust_Pref_Phone ,
        Cust_Pref_Phextn ,
        Cust_Contact_Name ,
		ORIG_CUST_NAME ,
        Od_Order_Type ,
        Ship_To_Name ,
        Bill_To_Name ,
        Ship_To_Sequence ,
        Ship_To_Address1 ,
        Ship_To_Address2 ,
        Ship_To_City ,
        Ship_To_State ,
        Ship_To_Country ,
		ship_to_county,
        Ship_To_Zip ,
        Tax_Rate ,
        Order_Action_Code ,
        Order_Start_Time ,
        Order_End_Time ,
        Order_Taxable_Cd ,
		ACTION_CODE,
        Override_Delivery_Chg_Cd ,
        Ship_To_Geocode ,
        Cust_Dept_Description ,
        Aops_Geo_Code ,
        External_Transaction_Number ,
        Freight_Tax_Rate ,
        Freight_Tax_Amount ,
		order_total,
        Creation_Date ,
        Created_By ,
        Last_Update_Date ,
        Last_Updated_By
      )
      VALUES
      (
        L_Header_Id ,
        I.ORDERPSTTAX,
	    I.Orderrelease ,
        I.ORDERDEPARTMENT,
		I.orderDesktop,
		I.Giftflag ,
        I.Alternateshipper ,
        --I.Salelocid ,
        --I.Salelocid ,
        I.Spcacctnumber ,
		I.LOYALTYID,
        I.Createbyid ,
        I.Deliverymethod ,
		I.OrderDelcode,
        I.Soldto_Contactemailaddr ,
        I.Soldto_Contactphone ,
        I.Soldto_Contactphoneext ,
        I.SOLDTO_CONTACTFIRSTNAME || ' ' || I.SOLDTO_CONTACTLASTNAME --Soldto_Soldtocontact --/ SOLDTO_CONTACTFIRSTNAME / SOLDTO_CONTACTLASTNAME
        ,I.SOLDTO_CONTACTFIRSTNAME || ' ' || I.SOLDTO_CONTACTLASTNAME,
        I.Ordertype ,
        I.Shipping_Shiptoname ,
        I.Billing_Billtoname ,
        I.Shipping_Addressseq ,
        I.Shipping_Line1 ,
        I.Shipping_Line2 ,
        I.Shipping_City ,
        I.State ,
        I.Shipping_Country ,
		I.Shipping_County,
        I.Zip ,
        I.Taxpercent ,
        I.Actioncode ,
        to_date(i.ORDERDATE || ' '||substr(LPAD(i.ORDERCREATETIME,8,0),1,6) ,'RRRR-MM-DD hh24miss') --i.ORDERCREATETIME
        ,
        to_date(i.ORDERDATE || ' '||substr(LPAD(i.ORDERENDTIME,8,0),1,6) ,'RRRR-MM-DD hh24miss') --i.ORDERENDTIME
        ,
        I.Taxableflag ,
		I.ACTIONCODE,
        I.Orderdeloverridecode ,
        I.Geolocation ,
        I.Deptdescription ,
        I.Geolocation ,
        I.Extordnumber ,
        I.Freighttaxpercent ,
        I.Freighttaxamt ,
		I.Ordertotal,
        Sysdate ,
        FND_GLOBAL.user_id ,
        Sysdate ,
        FND_GLOBAL.user_id
      );
    
	lc_level := 'Order Line';
	
	INSERT
    INTO Xx_Oe_Order_Lines_All
      (
        Line_Id ,
        Header_Id ,
        Line_Type_Id ,
        Line_Number ,
		ORIG_SYS_DOCUMENT_REF,
		ORIG_SYS_LINE_REF,
        Inventory_Item_Id ,
        Shipment_Number ,
        Creation_Date ,
        Created_By ,
        Last_Update_Date ,
        Last_Updated_By ,
        Line_Category_Code ,
        Open_Flag ,
        Booked_Flag ,
        User_Item_Description ,
        Ordered_Item ,
        Order_Quantity_Uom ,
		INVOICED_QUANTITY,
        Shipped_Quantity ,
        Ordered_Quantity ,
        Cust_Po_Number ,
        Unit_Selling_Price , -- Calulation
        Unit_List_Price ,
        Tax_Value ,
		SCHEDULE_SHIP_DATE ,
		PRICING_QUANTITY , 
		PRICING_QUANTITY_UOM , 
		FULFILLED_QUANTITY ,
		ACTUAL_SHIPMENT_DATE ,
		ORG_ID,
		REQUEST_ID ,
		REQUEST_DATE
      )
    SELECT Xx_Oe_Ord_Line_Seq.Nextval,
      L_Header_Id,
      1,
      Linenumber,
	  I.Ordernumber || I.Ordersubnumber,
	  Linenumber,
      1,
      Linenumber,
      Sysdate ,
      FND_GLOBAL.user_id,
      Sysdate,
      FND_GLOBAL.user_id,
      NVL(Itemtype,'N'),
      'N',
      'N' ,
      Sku ,
      Sku ,
      Unit ,
	  Shipquantity,
      Shipquantity ,
      Quantity ,
      Polinenum ,
      (Price - (NVL((
	  SELECT SUM(xoadj.acctingCouponAmount)
	  FROM Xxom_Order_Adjustments_Int xoadj
	  WHERE xoadj.Header_Id = x.Header_Id
	  and xoadj.line_id = x.line_id
	  ),0)/x.Quantity) ),
      Price ,
      I.Totaltax ,
	  TO_DATE(I.PICKUPORDELIVERYDATE,'YYYY-MM-DD') ,
	  shipquantity ,
	  unit ,
	  shipquantity , 
	  TO_DATE(I.SALEDATE,'YYYY-MM-DD') ,
	  FND_PROFILE.VALUE('ORG_ID'),
	  fnd_global.conc_request_id ,
	  SYSDATE
    FROM Xxom_Order_Lines_Int x
    WHERE Header_Id = I.Header_Id
	AND status = 'New';
	--ORDER BY Linenumber;
	
	lc_level := 'Order Line Attribute';
	
    INSERT
    INTO Xx_Oe_Line_Attributes_All
      (
        Line_Id ,
        Creation_Date ,
        Created_By ,
        Last_Update_Date ,
        Last_Updated_By ,
        Cost_Center_Dept ,
        Config_Code ,
        Vendor_Product_Code ,
        Contract_Details ,
		taxable_flag,
		COMMISIONABLE_IND,
        Line_Comments ,
        Backordered_Qty ,
        Sku_Dept ,
        Item_Source ,
        Average_Cost ,
        Po_Cost ,
        Sku_List_Price ,
		UNIT_ORIG_SELLING_PRICE,
        Wholesaler_Item ,
        Gsa_Flag ,
        Price_Change_Reason_Cd ,
		CAMPAIGN_CD,
        Cust_Dept_Description ,
        Upc_Code ,
        Price_Type ,
        Kit_Sku ,
        Kit_Qty ,
        Kit_Vend_Product_Code ,
        Kit_Sku_Dept ,
        Kit_Seqnum,
		item_Description
      )
    SELECT
      (SELECT Line_Id
      FROM Xx_Oe_Order_Lines_All
      WHERE Header_Id = L_Header_Id
      AND Line_Number = X.Linenumber
      ) ,
      Sysdate ,
      FND_GLOBAL.user_id ,
      Sysdate ,
      FND_GLOBAL.user_id ,
      X.Costcentercode ,
      X.Configurationid ,
      X.Vendorproductcode ,
      X.Contractcode ,
	  I.TAXABLEFLAG,
	  I.COMMISIONFLAG,
      X.Linecomments ,
      X.Backorderquantity ,
      X.Department ,
      X.Itemsource ,
      X.Avgcost ,
      X.Pocost ,
      X.listprice, 
	  X.Originalitemprice ,
      X.Wholesalerproductnumber ,
      X.Gsaflag ,
      X.Priceoverridecode ,
	  X.campaignCode,
      X.Costcenterdescription ,
      X.Upc ,
      X.Pricetype ,
      X.Kitsku ,
      X.Kitquantity ,
      X.Kitvpc ,
      X.Kitdept ,
      X.Kitseq,
	  X.ITEMDESCRIPTION
    FROM Xxom_Order_Lines_Int X
    WHERE X.Header_Id = I.Header_Id
	AND status = 'New';
	
	lc_level := 'Order Price Adjustment';
	
    INSERT
    INTO Xx_Oe_Price_Adjustments
      (
        Price_Adjustment_Id ,
        Creation_Date ,
        Created_By ,
        Last_Update_Date ,
        Last_Updated_By ,
        Header_Id ,
        Automatic_Flag ,
        Line_Id ,
        Adjusted_Amount
        ,ATTRIBUTE8
		,ATTRIBUTE6
		,ATTRIBUTE10
		,OPERAND
		,ARITHMETIC_OPERATOR
		,LIST_LINE_TYPE_CODE
		,REQUEST_ID
        --,ATTRIBUTE7
        --,ATTRIBUTE9
        --,ORIG_SYS_DISCOUNT_REF
      )
    SELECT Xx_Oe_Ord_adjustment_Seq.Nextval ,
      Sysdate ,
      FND_GLOBAL.user_id ,
      Sysdate ,
      FND_GLOBAL.user_id ,
      L_Header_Id ,
      'N' ,
      xoline.Line_Id ,
      ---xoa.Displaycouponamount
	  (-1*xoa.displayCouponAmount)/xoline.Ordered_Quantity
	  ,xoa.adjustmentCode
      ,xoa.COUPONID
	  ,xoa.displaycouponamount
	  ,xoa.displaycouponamount
	  ,'LUMPSUM'
	  ,'DIS'
      ,fnd_global.conc_request_id
	  --,coupon Type
      --ADJUSTMENTCODE
      --couponOwner
      --adjustName
    FROM Xxom_Order_Adjustments_Int xoa , Xx_Oe_Order_Lines_All xoline
    WHERE xoa.Header_Id = I.Header_Id
	AND xoline.Header_Id = L_Header_Id
	AND xoa.Linenum = xoline.Line_Number
	AND status = 'New';
	
	IF NVL(I.Totaltax,0)>0 THEN 
		
		lc_level := 'Order Price Adjustment Tax';
		
		INSERT
		INTO Xx_Oe_Price_Adjustments
		(
		PRICE_ADJUSTMENT_ID
		,CREATION_DATE
		,CREATED_BY
		,LAST_UPDATE_DATE
		,LAST_UPDATED_BY 
		,HEADER_ID
		,AUTOMATIC_FLAG
		,LINE_ID
		,LIST_LINE_TYPE_CODE
		,ARITHMETIC_OPERATOR
		,TAX_CODE
		,ADJUSTED_AMOUNT
		,REQUEST_ID
		)
		VALUES
		(
			Xx_Oe_Ord_adjustment_Seq.Nextval ,
			Sysdate ,
			FND_GLOBAL.user_id ,
			Sysdate ,
			FND_GLOBAL.user_id ,
			L_Header_Id ,
			'Y',
			(SELECT MIN(line_id) from Xx_Oe_Order_Lines_All
			where header_id = L_Header_Id
			),--line_id
			'TAX',
			'AMT',
			'Location',
			I.Totaltax
			,fnd_global.conc_request_id
		);
	END IF;
	
	lc_level := 'Order Payment';
      INSERT
      INTO Xx_Oe_Payments
        (
          Payment_Trx_Id ,
          Header_Id ,
          Creation_Date ,
          Created_By ,
          Last_Update_Date ,
          Last_Updated_By ,
          Attribute3 -- CLRTEXTTOKENFLAG
          --ATTRIBUTE5                      -- NA
          ,
          Attribute6 -- CCMANUALAUTH
          --ATTRIBUTE7                      -- MERCHANT_NBR Need to receive from SAS and need to create in int
          ,
          Attribute8 -- AUTHPS2000
          --ATTRIBUTE9                      -- AlliedInd Not in int and payload
          --ATTRIBUTE10                     -- CC Mask no need to capture from crypto vault
          ,
          Attribute11 -- CCTYPE
          ,
          Attribute13 -- CCAUTHCODE
          --ATTRIBUTE14                     -- emv info from rto or crypto vault
          ,
          Payment_Type_Code -- METHOD
          ,
          Credit_Card_Code -- CCTYPE
          ,
          Credit_Card_Number -- CCENCRYPTIONKEY
          ,
          Credit_Card_Holder_Name -- SOLDTO_CONTACTFIRSTNAME || SOLDTO_CONTACTLASTNAME (Header)
          ,CREDIT_CARD_EXPIRATION_DATE     -- EXPIRYDATE
          ,
          Check_Number -- ACCOUNTNUMBER
          ,
          Payment_Amount -- AMOUNT
		  ,PREPAID_AMOUNT
		  ,CREDIT_CARD_APPROVAL_CODE
		  ,REQUEST_ID
          ,PAYMENT_NUMBER                   -- PaySeqNum Not available in int
          ,ORIG_SYS_PAYMENT_REF             -- PaySeqNum Not available in int
        )
      SELECT Xx_Oe_Ord_Payment_Seq.Nextval ,
        L_Header_Id ,
        Sysdate,
        FND_GLOBAL.user_id,
        Sysdate,
        FND_GLOBAL.user_id ,
        Clrtexttokenflag
        --ATTRIBUTE5                      -- NA
        ,
        Ccmanualauth
        --ATTRIBUTE7                      -- MERCHANT_NBR Need to receive from SAS and need to create in int
        ,
        Authps2000
        --ATTRIBUTE9                      -- AlliedInd Not in int and payload
        --ATTRIBUTE10                     -- CC Mask no need to capture from crypto vault
        ,
        Cctype ,
        Ccauthcode
        --ATTRIBUTE14                     -- emv info from rto or crypto vault
        ,
        Method ,
        Cctype ,
        Ccencryptionkey ,
        I.Soldto_Contactfirstname || ' ' || I.Soldto_Contactlastname
        ,DECODE(EXPIRYDATE,'00/00',NULL, TO_DATE('01/'||EXPIRYDATE,'dd/mm/rr'))     -- EXPIRYDATE
        ,
        Accountnumber ,
        Amount
		,Amount
		,Ccauthcode
		,fnd_global.conc_request_id
        ,payment_ref                   -- PaySeqNum Not available in int
        ,payment_ref                   -- PaySeqNum Not available in int
      FROM Xxom_Order_Tenders_Int
      WHERE Header_Id = I.Header_Id
	  AND status = 'New';

	UPDATE Xxom_Order_Headers_Int
	SET status = 'Processed' 
	WHERE Ordernumber = lc_int_order_number 
	AND Header_Id = lc_int_header_id;

	UPDATE Xxom_Order_Lines_Int 
	SET status = 'Processed' 
	WHERE header_id = lc_int_header_id;

	UPDATE Xxom_Order_Adjustments_Int 
	SET status = 'Processed' 
	WHERE header_id = lc_int_header_id;

	UPDATE Xxom_Order_Tenders_Int
	SET status = 'Processed' 
	WHERE header_id = lc_int_header_id;	  
	
	logit ('Order '||lc_int_order_number||' processed');

  EXCEPTION
    WHEN OTHERS THEN
	  lc_level := 'Order Price Adjustment Tax';
      logit ('Error in Proc Xxoe_Validate_Data while inserting '|| lc_level ||' data of '||lc_int_order_number||' into xxom int tables. Error Code:'||SQLCODE);
	  logit ('Error Message: '||SQLERRM);
	  
	  DELETE FROM Xx_Oe_Payments
	  WHERE header_id = L_Header_Id;
	  
	  DELETE FROM Xx_Oe_Price_Adjustments
	  WHERE header_id = L_Header_Id;
	  
	  DELETE FROM Xx_Oe_Line_Attributes_All xolattr
	  WHERE EXISTS 
	  (SELECT 1 
      FROM Xx_Oe_Order_Lines_All xoline
      WHERE xoline.Header_Id = L_Header_Id
	  AND xoline.line_id  = xolattr.line_Id
      );
	  
	  DELETE FROM Xx_Oe_Order_Lines_All
      WHERE Header_Id = L_Header_Id;
	  
	  DELETE FROM Xx_Oe_Header_Attributes_All
	  WHERE header_id = L_Header_Id;
	  
	  DELETE FROM Xx_Oe_Order_Headers_All
	  WHERE header_id = L_Header_Id;
	  
	  UPDATE Xxom_Order_Headers_Int
	  SET status = 'Error' , error_description = 'Error in Proc Xxoe_Validate_Data while inserting '|| lc_level ||' data'
	  WHERE Ordernumber = lc_int_order_number 
	  AND Header_Id = lc_int_header_id;
	  
	  UPDATE Xxom_Order_Lines_Int 
	  SET status = 'Error' , error_description = 'Error in Proc Xxoe_Validate_Data while inserting '|| lc_level ||' data'
	  WHERE header_id = lc_int_header_id;
	  
	  UPDATE Xxom_Order_Adjustments_Int 
	  SET status = 'Error' ,  error_description = 'Error in Proc Xxoe_Validate_Data while inserting '|| lc_level ||' data'
	  WHERE header_id = lc_int_header_id;

      UPDATE Xxom_Order_Tenders_Int
	  SET status = 'Error' ,  error_description = 'Error in Proc Xxoe_Validate_Data while inserting '|| lc_level ||' data'
	  WHERE header_id = lc_int_header_id;
		  
		UPDATE Xxom_Import_Int
		set Process_Flag = 'E',Status = 'Error', error_description = 'Error while inserting ' ||lc_level|| ' data in xxoe table'
		where Order_Number = lc_int_order_number
		AND Sub_Order_Number = lc_sub_order_number;
	END;

  END LOOP;
  
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  
  logit ('Exception in Proc Xxoe_Validate_Data. Error Code:'||SQLCODE);
  logit ('Error Message: '||SQLERRM);
  
END Xxoe_Validate_Data;
END Xxoe_Data_Load_Pkg;

SHOW ERRORS