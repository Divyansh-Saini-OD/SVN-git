SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_ASGN_SUPPLIER_PKG
AS
 
 -- +===========================================================================================+
 -- |                              Oracle NAIO (India)                                          |
 -- |                               Bangalore,  India                                           |
 -- +===========================================================================================+
 -- | Package Name : XX_OM_ASGN_SUPPLIER_PKG                                                    |
 -- | Description  : This package contains procedure which identify supplier site who can       |
 -- |                fulfil the order and populates DFF on order line.These procedures would    |
 -- |                be invoked only for Drop ship and Back-to-Back order lines.                |
 -- |                                                                                           |
 -- | Procedure Name            Description                                                     |
 -- |________________           ____________                                                    |
 -- | XX_OM_DROP_SHIP_PROC       Extracts the vendor details who can fulfil the                 |
 -- |                           drop ship order line                                            |
 -- |                                                                                           |
 -- | XX_OM_BACK_TO_BACK_PROC   Extracts the vendor details who can fulfil the                  |
 -- |                           back-to-back order line                                         |
 -- | Change Record:                                                                            |
 -- |================                                                                           |
 -- |                                                                                           |
 -- | Version       Date            Author                  Description                         |
 -- |=========     ==============   =================      ================                     |
 -- | DRAFT 1A      15-Jan-2007     Vikas Raina            Initial draft version                |
 -- | DRAFT 1B                      Vikas Raina            After Peer Review Changes            |
 -- | 1.0                           Vikas Raina            Baselined                            |
 -- | 1.1           28-Feb-2007     Neeraj Raghuvanshi     As per CR email from Milind on       |
 -- |                                                      21-Feb-2007, the procedure           |
 -- |                                                      XX_OM_DROP_SHIP_PROC   is modified to|
 -- |                                                      get Desktop Delivery Address for Drop|
 -- |                                                      Ship and Non Code Drop Ship Orders.  |
 -- |1.2            3-Apr-2007      Faiz Mohammad          AS per update in the MD070 addedlogic|
 -- |                                                      for context type drop ship,          |
 -- |                                                      Noncode Dropship,Back To Back,       |
 -- |                                                      Non Code Back to Back                |
 -- |1.3           16-Apr-2007     Faiz Mohammad           Added logic for checking if line type| 
 -- |                                                         is null                           |
 -- +===========================================================================================+


/*-----------------------------------------------------------------------------
PROCEDURE  : XX_LOG_EXCEPTION_PROC
DESCRIPTION: Procedure to log exceptions

------------------------------------------------------------------------------*/
-- Version 1.2 -- Included
Procedure XX_LOG_EXCEPTION_PROC( p_error_code        IN  VARCHAR2
                                ,p_error_description IN  VARCHAR2
                                ,p_function          IN  VARCHAR2
                                ,p_entity_ref        IN  VARCHAR2
                                ,p_entity_ref_id     IN  NUMBER
                                )
AS
x_errbuf              VARCHAR2(1000);
x_retcode             VARCHAR2(40);


BEGIN

           exception_object_type.p_exception_header  :=    G_exception_header;
           exception_object_type.p_track_code        :=    G_track_code;
           exception_object_type.p_solution_domain   :=    G_solution_domain;
           exception_object_type.p_function          :=    p_function;
           exception_object_type.p_error_code        :=    p_error_code;
	   exception_object_type.p_error_description :=    p_error_description;
	   exception_object_type.p_entity_ref        :=    G_entity_ref;
 	   exception_object_type.p_entity_ref_id     :=    p_entity_ref_id;


           XXOD_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(exception_object_type,x_errbuf,x_retcode);

END;
-- End -- Version 1.2


/*----------------------------------------------------------------------------------------------------------------
PROCEDURE  : XX_OM_DROP_SHIP_PROC
DESCRIPTION: Extracts the vendor details who can fulfil the drop ship order.
                       line
----------------------------------------------------------------------------------------------------------------*/
Procedure XX_OM_DROP_SHIP_PROC (
                                p_line_id               IN  NUMBER
                               ,p_source_type_code      IN  VARCHAR2
                               ,x_vendor_id             OUT NUMBER
                               ,x_vendor_site_id        OUT NUMBER
                               ,x_loc_var               OUT VARCHAR2-- Version 1.2
                               ,x_dropship_type         OUT VARCHAR2-- Version 1.2
                               )
IS
--Included Version 1.2--
lc_vendor_site_id       po_vendor_sites_all.VENDOR_SITE_ID%TYPE;--Attribute7.xx_om_lines_attributes_all.segment4--vendor_site_id
lc_desktop_del_address  oe_order_lines_all.ATTRIBUTE6%TYPE;--Attribute6.xx_om_lines_attributes_all.Segment4
lc_vendor_site_code     po_vendor_sites.VENDOR_SITE_CODE%TYPE;
lc_dept_costcenter      oe_order_lines_all.ATTRIBUTE6%TYPE;--Attribute6.xx_om_lines_attributes_all.Segment2
lc_loc_var              po_requisitions_interface_all.LINE_ATTRIBUTE6%TYPE;
lc_cust_soldto          oe_order_lines_all.SOLD_TO_ORG_ID%type;
lc_deptcost             oe_order_lines_all.attribute6%TYPE;
lc_attribute16          hz_cust_accounts.ATTRIBUTE16%TYPE;
lc_vendor_info          oe_order_lines_all.ATTRIBUTE7%TYPE;
lc_dropship_type        oe_order_lines_all.ATTRIBUTE6%TYPE;
l_dropship_type         fnd_lookups.LOOKUP_CODE%TYPE;
ln_exception_occured    NUMBER := 0;
lc_entity_ref           VARCHAR2(40);
lc_entity_ref_id        NUMBER;
lc_function             VARCHAR2(40);
-- End Version 1.2
lc_vendor_name          po_vendors.vendor_name%TYPE;
lc_vendor_id            NUMBER;
lc_error_code           VARCHAR2(40);
lc_error_msg            VARCHAR2(1000);
ln_line_type_id         oe_order_lines_all.LINE_TYPE_ID%TYPE;
ex_line_type            EXCEPTION;                     
lc_process_further_flag VARCHAR2(1) :='Y';

BEGIN


  --Check if Order Source Type is 'EXTERNAL'

IF p_source_type_code = 'EXTERNAL' THEN
   --checking if line_type_id is Null--Added for 1.3
   BEGIN
     SELECT OOLA.line_type_id
     INTO   ln_line_type_id
     FROM   oe_order_lines_all OOLA
     WHERE  line_id =p_line_id;
     
     IF ln_line_type_id is NULL THEN
     Raise ex_line_type;
     lc_process_further_flag := 'N';
     END IF;
   EXCEPTION
     WHEN ex_line_type THEN
          ln_exception_occured := 1;
	  lc_error_code        := '01';
	  lc_error_msg         := SUBSTR('PO REQUISTION LINE NOT ELIGIBLE',1,235);
	  lc_function          :='DROPSHIP';
	  lc_entity_ref        := 'ORDER LINE ID';
	  lc_entity_ref_id     := p_line_id;
     WHEN OTHERS THEN
	  ln_exception_occured := 1;
	  lc_error_code        := '02';
	  lc_error_msg         := SUBSTR('UnExpected Error while deriving line type',1,235);
	  lc_function          :='DROPSHIP';
	  lc_entity_ref        := 'ORDER LINE ID';
	  lc_entity_ref_id     := p_line_id;
     END;
	  
     IF ln_exception_occured > 0 THEN
	ln_exception_occured := 0;
	XX_LOG_EXCEPTION_PROC (lc_error_code
	                      ,lc_error_msg
	                      ,lc_function
	                      ,lc_entity_ref
	                      ,lc_entity_ref_id
	                      );
    END IF;
    
   -- setting the lc_process_further_flag ='Y' to proceed further
   IF lc_process_further_flag = 'Y' THEN    

  --Checking if the DropShip Order is of the type Noncode where SEGMENT16 will have the value NonCode
   BEGIN
      SELECT KFF.SEGMENT16
      INTO   lc_dropship_type
      FROM   oe_order_lines_all OOLA
	     ,xx_om_lines_attributes_all KFF
	     ,oe_order_lines_all_dfv DFV
	     ,oe_order_headers_all OOHA
      WHERE KFF.combination_id = OOLA.attribute6
      AND   OOLA.line_id       = p_line_id
      AND   OOLA.rowid         = DFV.row_id
      AND   OOHA.header_id     = OOLA.header_id;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        ln_exception_occured := 1;
	lc_error_code        := '03';
	lc_error_msg         := SUBSTR('No data found for dropshiptype-NoneCode',1,235);
	lc_function          :='DROPSHIP';
	lc_entity_ref        := 'ORDER LINE ID';
	lc_entity_ref_id     := p_line_id;
   WHEN OTHERS THEN
        ln_exception_occured := 1;
	lc_error_code        :='04';
	lc_error_msg         := SUBSTR('Unexpected Error for dropshiptype-NoneCode',1,235);
	lc_function          :='DROPSHIP';
        lc_entity_ref        :='ORDER LINE ID';
	lc_entity_ref_id     := p_line_id;
   END;

   IF ln_exception_occured > 0 THEN
      ln_exception_occured := 0;
      XX_LOG_EXCEPTION_PROC (lc_error_code
	                     ,lc_error_msg
	                     ,lc_function
	                     ,lc_entity_ref
	                     ,lc_entity_ref_id
                            );

   END IF;

--Checking for the dropship is Nonecode Drop Ship or Drop ship and cheking for lookupcode
   
   IF lc_dropship_type IS NOT NULL THEN
      l_dropship_type := 'NC DROPSHIP';
   ELSE
      l_dropship_type := 'DROPSHIP';
   END IF;
--With the lookup code derived cheking with the lookup meaning
   BEGIN
      SELECT meaning
      INTO   x_dropship_type
      FROM   fnd_lookups
      WHERE  lookup_type='OD_PO_CANCEL_ISP'
      AND    lookup_code=l_dropship_type;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        ln_exception_occured := 1;
        lc_error_code        := '05';
        lc_error_msg         := SUBSTR('No data found for dropshiptype',1,235);
        lc_function          :='DROPSHIP';
	lc_entity_ref        :='ORDER LINE ID';
	lc_entity_ref_id     := p_line_id;
   WHEN OTHERS THEN
        ln_exception_occured := 1;
        lc_error_code        := '06';
        lc_error_msg         := SUBSTR('Unexpected Error for dropshiptype',1,235);
        lc_function          :='DROPSHIP';
        lc_entity_ref        :='ORDER LINE ID';
	lc_entity_ref_id     := p_line_id;
   END;

   IF ln_exception_occured > 0 THEN
      ln_exception_occured := 0;
      XX_LOG_EXCEPTION_PROC (lc_error_code
	                    ,lc_error_msg
	                    ,lc_function
	                    ,lc_entity_ref
	                    ,lc_entity_ref_id
                            );

   END IF;
--Fetch attribute7 from order line, which holds the cocatenated segment of vendor_site_code and vendor_name.
--Get the Attribute Values in Oe_Order_Lines_All Table for deriving vendor details--
   BEGIN
      SELECT SUBSTR(KFF.segment4,1,instr(KFF.segment4,'.')-1)
            ,SUBSTR(KFF.segment4,instr(KFF.segment4,'.',1,1)+1)
            ,OOLA.sold_to_org_id
      INTO   lc_vendor_name
      	    ,lc_vendor_site_code
      	    ,lc_cust_soldto
      FROM   oe_order_lines_all OOLA
           ,xx_om_lines_attributes_all KFF
           ,oe_order_lines_all_dfv DFV
           ,oe_order_headers_all OOHA
      WHERE KFF.combination_id = OOLA.attribute7
      AND   OOLA.line_id       = p_line_id
      AND   OOLA.rowid         = DFV.row_id
      AND   OOHA.header_id     = OOLA.header_id;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        ln_exception_occured := 1;
        lc_error_code        := '07';
        lc_error_msg         := SUBSTR('No data found while deriving vendor informations',1,235);
        lc_function          :='DROPSHIP';
	lc_entity_ref        :='ORDER LINE ID';
	lc_entity_ref_id     := p_line_id;
   WHEN OTHERS THEN
        ln_exception_occured := 1;
        lc_error_code        := '08';
        lc_error_msg         := SUBSTR('Unexpected Error while deriving vendor informations',1,235);
        lc_function          :='DROPSHIP';
        lc_entity_ref        :='ORDER LINE ID';
	lc_entity_ref_id     := p_line_id;
   END;

   IF ln_exception_occured > 0 THEN
      ln_exception_occured := 0;
      XX_LOG_EXCEPTION_PROC(lc_error_code
	                    ,lc_error_msg
	                    ,lc_function
	                    ,lc_entity_ref
	                    ,lc_entity_ref_id
                           );

   END IF;

--Get The Attribute values for attribute16 which has CUST SHIP TO values
   
   IF lc_cust_soldto is NOT NULL THEN
     BEGIN
         SELECT attribute16
         INTO   lc_attribute16
         FROM   HZ_CUST_ACCOUNTS
         WHERE  cust_account_id = lc_cust_soldto;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
          ln_exception_occured := 1;
	  lc_error_code        := '09';
	  lc_error_msg         := SUBSTR('No data found while deriving customer ship to values',1,235);
	  lc_function          :='DROPSHIP';
	  lc_entity_ref        :='ORDER LINE ID';
	  lc_entity_ref_id     := p_line_id;
     WHEN OTHERS THEN
          ln_exception_occured := 1;
	  lc_error_code        := '10';
	  lc_error_msg         := SUBSTR('UnExpected Error while deriving customer ship to values',1,235);
	  lc_function          :='DROPSHIP';
	  lc_entity_ref        :='ORDER LINE ID';
	  lc_entity_ref_id     := p_line_id;
     END;

     IF ln_exception_occured > 0 THEN
        ln_exception_occured := 0;
        XX_LOG_EXCEPTION_PROC(lc_error_code
	                     ,lc_error_msg
	                     ,lc_function
	                     ,lc_entity_ref
	                     ,lc_entity_ref_id
                              );

     END IF;

   END IF;----IF lc_cust_soldto is NOT NULL THEN

  --To Fetch the attributes for deriving desktop delivery and costcenter
   BEGIN
      SELECT KFF.segment2 --Costcenter/Department
            ,KFF.segment4 --Desktop_Delivery_Address
      INTO
             lc_deptcost
            ,lc_desktop_del_address
      FROM   oe_order_lines_all OOLA
            ,xx_om_lines_attributes_all KFF
            ,oe_order_lines_all_dfv DFV
            ,oe_order_headers_all OOHA
      WHERE  KFF.combination_id = OOLA.attribute6
      AND    OOLA.line_id       = p_line_id
      AND    OOLA.rowid         = DFV.row_id
      AND    OOHA.header_id     =OOLA.header_id;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        ln_exception_occured := 1;
	lc_error_code        := '11';
        lc_error_msg         := SUBSTR('No data found while deriving desktop delivery address-costcenterdept',1,235);
        lc_function          :='DROPSHIP';
        lc_entity_ref        :='ORDER LINE ID';
	lc_entity_ref_id     := p_line_id;
   WHEN OTHERS THEN
        ln_exception_occured := 1;
	lc_error_code        := '12';
	lc_error_msg         := SUBSTR('Unexpected Error while deriving desktop delivery address-costcenterdept',1,235);
	lc_function          :='DROPSHIP';
	lc_entity_ref        :='ORDER LINE ID';
	lc_entity_ref_id     := p_line_id;
   END;

   IF ln_exception_occured > 0 THEN
      ln_exception_occured := 0;
      XX_LOG_EXCEPTION_PROC(lc_error_code
	                   ,lc_error_msg
	                   ,lc_function
	                   ,lc_entity_ref
	                   ,lc_entity_ref_id
                            );

   END IF;


  --Checking for cust ship to values
   IF lc_attribute16 = 'Yes - By Cost Center' THEN
      lc_loc_var := lc_deptcost;
   ELSE
      lc_loc_var := lc_desktop_del_address;
   END IF;--IF lc_attribute16 = 'Yes - By Cost Center' THEN

/* This extracted vendor_site_code and vendor_name is then used to extract vendor id and vendor site id
*/

   BEGIN
      SELECT PVS.vendor_site_id,
    	     PV.vendor_id
      INTO
    	     lc_vendor_site_id,
             lc_vendor_id
      FROM  po_vendor_sites_all PVS,
    	    po_vendors pv
      WHERE PV.vendor_name =lc_vendor_name
      AND   PVS.vendor_site_code = lc_vendor_site_code
      AND   PV.vendor_id =pvs.vendor_id;

   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        ln_exception_occured := 1;
        lc_error_code        := '13';
        lc_error_msg         := SUBSTR('No data found while deriving deriving vendor details',1,235);
        lc_function          :='DROPSHIP';
        lc_entity_ref        :='ORDER LINE ID';
	lc_entity_ref_id     := p_line_id;
   WHEN OTHERS THEN
        ln_exception_occured := 1;
	lc_error_code        := '14';
	lc_error_msg         := SUBSTR('UnExpected Error while deriving deriving vendor details',1,235);
	lc_function          :='DROPSHIP';
	lc_entity_ref        :='ORDER LINE ID';
	lc_entity_ref_id     := p_line_id;
   END;

   IF ln_exception_occured > 0 THEN
      ln_exception_occured := 0;
      XX_LOG_EXCEPTION_PROC(lc_error_code
	                   ,lc_error_msg
	                   ,lc_function
	                   ,lc_entity_ref
	                   ,lc_entity_ref_id
                           );
   END IF;

   END IF; --IF lc_process_further_flag = 'Y' THEN

END IF; --IF p_source_type_code = 'EXTERNAL' THEN
x_vendor_id            := lc_vendor_id;
x_vendor_site_id       := lc_vendor_site_id;
x_loc_var              := lc_loc_var;

END XX_OM_DROP_SHIP_PROC;

/*-----------------------------------------------------------------
PROCEDURE  : XX_OM_BACK_TO_BACK_PROC
DESCRIPTION: Extracts the vendor details who can fulfil the order
             for Back-to-Back Order.
-----------------------------------------------------------------*/
Procedure XX_OM_BACK_TO_BACK_PROC  (
                                     p_line_id               IN   NUMBER
                                    ,p_source_type_code      IN   VARCHAR2
                                    ,p_item_id               IN   NUMBER
                                    ,x_vendor_id             OUT  NUMBER
                                    ,x_vendor_site_id        OUT  NUMBER
                                    ,x_backtoback_type       OUT  VARCHAR2  --Included in Version 1.2
                                   )
IS

lc_vendor_site_id       po_vendor_sites_all.VENDOR_SITE_ID%TYPE;
lc_vendor_site_code     po_vendor_sites.VENDOR_SITE_CODE%TYPE;
lc_vendor_name          po_vendors.VENDOR_NAME%TYPE;
lc_vendor_id            po_vendors.VENDOR_ID%TYPE;
lc_ato_flag             mtl_system_items_b.REPLENISH_TO_ORDER_FLAG%TYPE;
lc_backtoback_type      oe_order_lines_all.ATTRIBUTE6%TYPE;
l_backtoback_type       fnd_lookups.LOOKUP_CODE%TYPE;
lc_error_code           VARCHAR2(40);
lc_error_msg            VARCHAR2(1000);
ln_exception_occured    NUMBER := 0;
lc_entity_ref           VARCHAR2(40);
lc_entity_ref_id        NUMBER;
ln_line_type_id         oe_order_lines_all.line_type_id%TYPE;
ex_line_type            EXCEPTION;
lc_process_further_flag VARCHAR2(1):='Y';
lc_function             VARCHAR2(40);

BEGIN

  /* Check if the order line is Back-to-back order line.
    For this extract ATO_FLAG of the item on the order line from ITEM-MASTER. */
   BEGIN
      SELECT distinct replenish_to_order_flag
      INTO   lc_ato_flag
      FROM   mtl_system_items_b
      WHERE  Inventory_item_id = p_item_id;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        ln_exception_occured := 1;
	lc_error_code        := '15';
	lc_error_msg         := SUBSTR('No data found while deriving ATO_FLAG',1,235);
	lc_function          :='BACKTOBACK';
	lc_entity_ref        :='ORDER LINE ID';
	lc_entity_ref_id     := p_line_id;
   WHEN OTHERS THEN
        ln_exception_occured := 1;
        lc_error_code        := '16';
        lc_error_msg         := SUBSTR('UnExpected Error while deriving ATO_FLAG',1,235);
        lc_function          :='BACKTOBACK';
	lc_entity_ref        :='ORDER LINE ID';
	lc_entity_ref_id     := p_line_id;
   END;

   IF ln_exception_occured > 0 THEN
      ln_exception_occured := 0;
      XX_LOG_EXCEPTION_PROC(lc_error_code
	                   ,lc_error_msg
	                   ,lc_function
	                   ,lc_entity_ref
	                   ,lc_entity_ref_id
                            );

   END IF;


  -- Only if the order line is Back-to-Back Order
   IF p_source_type_code = 'INTERNAL' and lc_ato_flag = 'Y' THEN
      
     --checking if the line_type_id is Null
      BEGIN
           SELECT OOLA.line_type_id
           INTO   ln_line_type_id
           FROM   oe_order_lines_all OOLA
           WHERE  line_id =p_line_id;
           
           IF ln_line_type_id is NULL THEN
           Raise ex_line_type;
           lc_process_further_flag := 'N';
           END IF;
      EXCEPTION
      WHEN ex_line_type THEN
           ln_exception_occured := 1;
	   lc_error_code        := '17';
	   lc_error_msg         := SUBSTR('No data found while deriving line type',1,235);
	   lc_function          :='BACKTOBACK';
	   lc_entity_ref        :='ORDER LINE ID';
	   lc_entity_ref_id     := p_line_id;
      WHEN OTHERS THEN
      	   ln_exception_occured := 1;
	   lc_error_code        := '18';
	   lc_error_msg         := SUBSTR('UnExpected Error while deriving line type',1,235);
	   lc_function          :='BACKTOBACK';
	   lc_entity_ref        :='ORDER LINE ID';
	   lc_entity_ref_id     := p_line_id;
      END;
      	  
      IF ln_exception_occured > 0 THEN
      	 ln_exception_occured := 0;
      	 XX_LOG_EXCEPTION_PROC (lc_error_code
	                       ,lc_error_msg
	                       ,lc_function
	                       ,lc_entity_ref
	                       ,lc_entity_ref_id
      	                       );
      END IF;
      
  -- setting the lc_process_further_flag ='Y' to proceed further
      IF lc_process_further_flag = 'Y' THEN       

   --Get the Attribute Values in Oe_Order_Lines_All Table for Non-Code Back to Back
    --To check for backtoback order  is Noncode type
      BEGIN
         SELECT KFF.SEGMENT16
         INTO   lc_backtoback_type
         FROM   oe_order_lines_all OOLA
               ,xx_om_lines_attributes_all KFF
               ,oe_order_lines_all_dfv DFV
               ,oe_order_headers_all OOHA
         WHERE KFF.combination_id = OOLA.attribute6
         AND   OOLA.line_id       = p_line_id
         AND   OOLA.rowid         = DFV.row_id
         AND   OOHA.header_id     = OOLA.header_id;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           ln_exception_occured := 1;
	   lc_error_code        := '19';
	   lc_error_msg         := SUBSTR('No data found while deriving Noncode Back to Back Order type',1,235);
	   lc_function          :='BACKTOBACK';
	   lc_entity_ref        :='ORDER LINE ID';
	   lc_entity_ref_id     := p_line_id;
      WHEN OTHERS THEN
           ln_exception_occured := 1;
	   lc_error_code        := '20';
	   lc_error_msg         := SUBSTR('UnExpected Error while deriving Noncode Back to Back Order type',1,235);
	   lc_function          :='BACKTOBACK';
	   lc_entity_ref        :='ORDER LINE ID';
	   lc_entity_ref_id     := p_line_id;
      END;

      IF ln_exception_occured > 0 THEN
         ln_exception_occured := 0;
         XX_LOG_EXCEPTION_PROC(lc_error_code
	                       ,lc_error_msg
	                       ,lc_function
	                       ,lc_entity_ref
	                       ,lc_entity_ref_id
                               );

      END IF;
   --to check for the Noncode BacktoBack Order or BacktoBack Order
     IF lc_backtoback_type IS NOT NULL THEN
        l_backtoback_type := 'NC BACKTOBACK';
     ELSE
        l_backtoback_type := 'BACKTOBACK';
     END IF;
 --With the lookup code derived cheking with the lookup meaning and storing in the out variable

     BEGIN
        SELECT meaning
        INTO   x_backtoback_type
        FROM   fnd_lookups
        WHERE  lookup_type='OD_PO_CANCEL_ISP'
        AND    lookup_code=l_backtoback_type;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
          ln_exception_occured := 1;
	  lc_error_code        := '21';
	  lc_error_msg         := SUBSTR('No data found while deriving Back to Back Order type',1,235);
	  lc_function          :='BACKTOBACK';
	  lc_entity_ref        :='ORDER LINE ID';
	  lc_entity_ref_id     := p_line_id;
     WHEN OTHERS THEN
          ln_exception_occured := 1;
	  lc_error_code        := '22';
	  lc_error_msg         := SUBSTR('UnExpected Error while deriving Back to Back Order type',1,235);
	  lc_function          :='BACKTOBACK';
	  lc_entity_ref        :='ORDER LINE ID';
	  lc_entity_ref_id     := p_line_id;
     END;

     IF ln_exception_occured > 0 THEN
        ln_exception_occured := 0;
        XX_LOG_EXCEPTION_PROC (lc_error_code
	                      ,lc_error_msg
	                      ,lc_function
	                      ,lc_entity_ref
	                      ,lc_entity_ref_id
                               );
     END IF;

   --Fetch attribute7 from order line, which holds the cocatenated segment of vendor_site_code and vendor_name.
   --Get the Attribute Values in Oe_Order_Lines_All Table for deriving vendor details--
     BEGIN
        SELECT SUBSTR(KFF.segment4,1,instr(KFF.segment4,'.')-1)
              ,SUBSTR(KFF.segment4,instr(KFF.segment4,'.',1,1)+1)
        INTO  lc_vendor_name
             ,lc_vendor_site_code
        FROM  oe_order_lines_all OOLA
             ,xx_om_lines_attributes_all KFF
             ,oe_order_lines_all_dfv DFV
             ,oe_order_headers_all OOHA
       WHERE KFF.combination_id = OOLA.attribute7
       AND   OOLA.line_id       = p_line_id
       AND   OOLA.rowid         = DFV.row_id
       AND   OOHA.header_id     = OOLA.header_id;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
          ln_exception_occured := 1;
	  lc_error_code        := '23';
	  lc_error_msg         := SUBSTR('No data found while deriving Vendor Information',1,235);
	  lc_function          :='BACKTOBACK';
	  lc_entity_ref        :='ORDER LINE ID';
	  lc_entity_ref_id     := p_line_id;
     WHEN OTHERS THEN
          ln_exception_occured := 1;
	  lc_error_code        := '24';
	  lc_error_msg         := SUBSTR('UnExpected Error while deriving Vendor Information',1,235);
	  lc_function          :='BACKTOBACK';
	  lc_entity_ref        :='ORDER LINE ID';
	  lc_entity_ref_id     := p_line_id;
     END;

     IF ln_exception_occured > 0 THEN
        ln_exception_occured := 0;
        XX_LOG_EXCEPTION_PROC(lc_error_code
	                     ,lc_error_msg
	                     ,lc_function
	                     ,lc_entity_ref
	                     ,lc_entity_ref_id
                              );

     END IF;


/* This extracted vendor site code and vendor name is then used to extract vendor id and vendor site id
*/

    BEGIN
       SELECT PVS.vendor_site_id,
              PV.vendor_id
       INTO
              lc_vendor_site_id,
              lc_vendor_id
       FROM   po_vendor_sites_all PVS,
              po_vendors pv
       WHERE  PV.vendor_name =lc_vendor_name
       AND    PVS.vendor_site_code = lc_vendor_site_code
       AND    PV.vendor_id =pvs.vendor_id;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
         ln_exception_occured := 1;
	 lc_error_code        := '25';
	 lc_error_msg         := SUBSTR('No Data found while deriving Vendor Information',1,235);
	 lc_function          :='BACKTOBACK';
	 lc_entity_ref        :='ORDER LINE ID';
	 lc_entity_ref_id     := p_line_id;
    WHEN OTHERS THEN
         ln_exception_occured := 1;
	 lc_error_code        := '25';
	 lc_error_msg         := SUBSTR('UnExpected Error while deriving Vendor Information',1,235);
	 lc_function          :='BACKTOBACK';
	 lc_entity_ref        :='ORDER LINE ID';
	 lc_entity_ref_id     := p_line_id;
    END;

    IF ln_exception_occured > 0 THEN
       ln_exception_occured := 0;
       XX_LOG_EXCEPTION_PROC  (lc_error_code
	                      ,lc_error_msg
	                      ,lc_function
	                      ,lc_entity_ref
	                      ,lc_entity_ref_id
                              ) ;

    END IF;

   END IF;-- IF lc_process_further_flag = 'Y' THEN
   
   END IF;--IF p_source_type_code = 'INTERNAL' THEN
x_vendor_id            := lc_vendor_id;
x_vendor_site_id       := lc_vendor_site_id;

END XX_OM_BACK_TO_BACK_PROC;


END XX_OM_ASGN_SUPPLIER_PKG;
/
SHOW ERRORS

-- EXIT;
