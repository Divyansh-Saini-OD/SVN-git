SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_WACA_FEED_PKG
IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name    :  XX_OM_WACA_FEED_PKG                                    |
-- | Rice ID : I0428 Warranty Sales Info Interface                     |
-- | Description:This Interface is used to extract all                 |
-- |              the warranty Items and  Transfer the                 |
-- |              warranty feed to WACA                                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- | 1.0     23-MAY-2007  Mohanakrishnan        Initial draft version  |
-- |                                                                   |  
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
	 
PROCEDURE GET_WACA_DATA         ( 
                                  p_waca_type    IN          VARCHAR2
			         ,p_line_id      IN          oe_order_lines_all.line_id%TYPE
				 ,x_waca_data    OUT NOCOPY  waca_rec_type
			        )
AS
       -- +=======================================================================================================+
	-- | Name  : get_waca_data                                                                                  |
	-- | Description : This procedure gets the required data that needs to be sent to WACA.                     |                                   
	-- |               Based on the given business rules for Data can be segrgated into                         |
	-- |               9  different types.                                                                      |
	-- |                                                                                                        |
	-- |		   a)Warranty Header level - POS source type - Generic Customer WACA data                   |
	-- |		   b)Warranty Header level - POS source type - Non-Generic Customer WACA data               |
	-- |		   c)Warranty Header level - Non POS source type  WACA data                                 |
	-- |		   e)Warranty SKU Line level - POS source type - Generic Customer WACA data                 |
	-- |		   f)Warranty SKU Line level - POS source type - Non-Generic Customer WACA data             |
	-- |		   g)Warranty SKU Line level - Non POS source type - WACA data                              |
	-- |		   i)Warranty RMA Header level - POS source type - Generic Customer WACA data               |
	-- |		   j)Warranty RMA Header level - POS source type - Non-Generic Customer WACA data           |
	-- |		   k)Warranty RMA Header level - Non POS source type -  WACA data                           |
	-- |                                                                                                        |
	-- | Parameters :  p_waca_type   Type of data that needs to be extracted ,                                  |
	-- |                                 values can  'WO'  -> Stand alone warranty items                        |
	-- |				                 'WR'  -> Warranty Items                                    |
	-- |                                             'WM'  -> Warranty with Machine skus                        |
        -- |                                                                                                        |
	-- |		   P_line_id     Line id                                                                    |
	-- |		   x_waca_data   Extracted Data                                                             |   
	-- |                                                                                                        |
	-- +========================================================================================================+

   EX_MANDATORY_FIELD  EXCEPTION ;

   lr_waca_wo          waca_head_rec_type ;
   lc_rma_number       oe_order_headers_all.order_number%TYPE ;
   ln_line_number      oe_order_lines_all.line_id%TYPE ;
   ln_rel_party_id     ar_contacts_v.rel_party_id%TYPE ;
   lc_first_name       ar_contacts_v.first_name%TYPE ;
   lc_last_name        ar_contacts_v.last_name%TYPE ;

   lc_sqlcode              VARCHAR2 (100);
   lc_sqlerrm              VARCHAR2 (1000);
   lc_errbuff              VARCHAR2 (1000); 
   lc_retcode              VARCHAR2 (100);
   lc_error_message        VARCHAR2 (4000);
   ln_serial_count         NUMBER    :=0;

   CURSOR lcu_waca_wo ( p_line_id  oe_order_lines_all.line_id%TYPE )
   IS
   SELECT   order_number                                               "order_number"
	   ,DECODE (OOS.name
	           ,gc_pos_source
	           ,XXOL.waca_item_ctr_num
		   ,NULL)                                              "warranty_number" 
	   ,OOS.name                                                   "order_source" 
	   ,MSIB.segment1                                              "warranty_sku"
	   ,MSIB.description                                           "warranty_description"
	   ,DECODE (OOS.name
	           ,gc_pos_source,SYSDATE
		   ,OOLA.request_date)                                 "Warranty_Application_Date"
	   ,OOLA.ordered_quantity                                      "Quantity_Sold"
	   ,OOLA.unit_selling_price                                    "Retail_Price"
	   ,OOLA.ship_from_org_id                                      "Store_ID"
	   ,OOHA.salesrep_id                                           "Salesman_ID"
	   ,hcaa.account_number                                        "customer_number"
	   ,HP.party_name	                                       "company_name"
	   ,HL.address1                                                "ship_to_addr1"
	   ,HL.address2                                                "ship_to_addr2"
	   ,DECODE (OOS.name
	           ,gc_pos_source,HLA.location_code
		   ,HL.city )                                          "ship_to_city"
	   ,HL.state                                                   "ship_to_state"
	   ,HL.postal_code                                             "ship_to_zip"
	   ,DECODE( HL.country
	           ,'US','United States'
		   ,'CA','Canada'
		   ,HL.country)                                        "ship_to_country"
	   ,DECODE(OOHA.transactional_curr_code
	          ,'USD','USA'
		  ,'CAD','CANADA'
		  , OOHA.transactional_curr_code)                       "Currency"
	   ,ACUV.customer_class_meaning                                "customer_class_meaning"
	   ,ACUV.customer_type_meaning                                 "customer_type_meaning"
	   ,HCAA.cust_account_id                                       "cust_account_id"
	   ,OOLA.request_date                                          "Return_Date"
	   ,MSIB.serial_number_control_code                            "serial_control"
   FROM    ar_customers_v       ACUV 
	   ,hz_cust_accounts_all HCAA
	   ,hz_cust_site_uses_all HCSU
	   ,hz_cust_acct_sites_all HCAS
	   ,hz_party_sites HPS
	   ,hz_locations HL
	   ,hr_locations_all HLA
	   ,hz_parties HP
	   ,mtl_system_items_b   MSIB
	   ,xx_om_line_attributes_all XXOL
	   ,oe_order_sources      OOS    
	   ,oe_order_headers_all OOHA
	   ,oe_order_lines_all   OOLA
   WHERE   OOHA.header_id         = OOLA.header_id
   AND     OOHA.order_source_id   = OOS.order_source_id
   AND     OOLA.inventory_item_id = MSIB.inventory_item_id (+)
   AND     OOLA.ship_from_org_id  = MSIB.organization_id (+)
   AND     OOLA.ship_from_org_id  = HLA.inventory_organization_id (+)
   AND     OOLA.line_id           = XXOL.line_id (+)
   AND     OOHA.ship_to_org_id    = HCSU.site_use_id (+)
   AND     HCAA.cust_account_id   = HCAS.cust_account_id
   AND     HCSU.cust_acct_site_id = HCAS.cust_acct_site_id
   AND     HCAS.party_site_id     = HPS.party_site_id (+)	  
   AND     HPS.location_id        = HL.location_id (+)
   AND     HPS.party_id           = HP.party_id (+)
   AND     HCSU.site_use_code     = 'SHIP_TO'
   AND     HCAA.cust_account_id   = ACUV.customer_id (+)
   AND     OOLA.line_id           = p_line_id ;
 

	
   --Select First available contact name if multiple contacts exists.
   CURSOR lcu_contact_name ( p_customer_id  ar_contacts_v.customer_id%TYPE )
   IS
   SELECT  first_name
	  ,last_name
	  ,rel_party_id
   FROM  ar_contacts_v 
   WHERE contact_id =  ( 
			 SELECT MIN(contact_id) 
			 FROM  ar_contacts_v 
			 WHERE  customer_id = p_customer_id
		       ) ;

    --TO Select any one of the phone number if multiple contacts exists.
   CURSOR lcu_phone ( p_owner_table_id  ar_phones_v.owner_table_id%TYPE )
   IS
   SELECT APV1.area_code||APV1.phone_number
   FROM   ar_phones_v APV1
   WHERE APV1.phone_type_meaning =gc_phone
   AND   APV1.status = 'A'		 						
   AND   APV1.owner_table_id=p_owner_table_id
   AND   ROWNUM < 2;

    --TO Select any one of the fax number if multiple contacts exists.
   CURSOR lcu_fax ( p_owner_table_id  ar_phones_v.owner_table_id%TYPE )
   IS
   SELECT APV1.area_code||APV1.phone_number
   FROM   ar_phones_v APV1
   WHERE APV1.phone_type_meaning =gc_fax
   AND   APV1.status = 'A'		 
   AND   APV1.owner_table_id=p_owner_table_id
   AND   ROWNUM < 2;

    --TO Select any one of the Email address if multiple contacts exists.
   CURSOR lcu_email ( p_owner_table_id  ar_phones_v.owner_table_id%TYPE )
   IS
   SELECT APV1.email_address
   FROM   ar_phones_v APV1
   WHERE APV1.phone_type_meaning =gc_email
   AND   APV1.status = 'A'		 
   AND   APV1.owner_table_id=p_owner_table_id
   AND   ROWNUM < 2;

    --TO Select any one of the mobile number if multiple contacts exists.
   CURSOR lcu_mobile ( p_owner_table_id  ar_phones_v.owner_table_id%TYPE )
   IS
   SELECT APV1.email_address
   FROM   ar_phones_v APV1
   WHERE APV1.phone_type_meaning =gc_mobile
   AND   APV1.status = 'A'		 
   AND   APV1.owner_table_id=p_owner_table_id
   AND   ROWNUM < 2;

   -- fetch the Original order number in case of a RMA order.
   CURSOR lcu_rma_order ( p_line_id oe_order_lines_all.line_id%TYPE  )
   IS
   SELECT  OOHA.order_number
	  ,XXOL.ret_ref_line_id   
   FROM    oe_order_headers_all OOHA
	  ,oe_order_lines_all   OOLA
	  ,oe_order_lines_all   OOLA1
	  ,xx_om_line_attributes_all XXOL
   WHERE  OOHA.HEADER_ID          = OOLA1.header_id
   AND    OOLA1.line_id           = XXOL.ret_ref_line_id
   AND    OOLA.line_id            = p_line_id
   AND    OOLA.line_id            = XXOL.line_id;


   --SERIAL NUMBER
   CURSOR   lcu_serial_number ( p_line_id mtl_material_transactions.source_line_id%TYPE )
   IS
   SELECT   COUNT( MSN.serial_number )
   FROM     mtl_material_transactions MMT
	   ,mtl_serial_numbers MSN
   WHERE    MMT.transaction_id = MSN.last_transaction_id
   AND      MMT.source_line_id = p_line_id ;
								 
BEGIN

   -- fetch the all inforamtion into record type variable and process it accordingly
   OPEN lcu_waca_wo ( P_line_id );	   
   FETCH lcu_waca_wo
   INTO  lr_waca_wo ;
   CLOSE lcu_waca_wo ; 


   -- FETCH CONTACT NAMES
   OPEN lcu_contact_name ( lr_waca_wo.cust_account_id);	   
   FETCH lcu_contact_name
   INTO  lc_first_name,lc_last_name,ln_rel_party_id ;
   CLOSE lcu_contact_name ;

   x_waca_data.line_id        := P_line_id ;
   gc_line_id                 := P_line_id ;

   -- WACA type check
   IF p_waca_type IN ( 'WO' ,'WR' ) THEN  --WACA type


      -- if it is a Header warranty Item
      x_waca_data.record_code := 'C';               
      x_waca_data.batch_number := TO_CHAR(sysdate,'CCYYMMDD');            
	       
      -- Mandatory fields check for SOURCE TYPE = 'POS'
      IF lr_waca_wo.order_source = gc_pos_source THEN   -- POS/NON-POS     
           x_waca_data.Order_Source           := lr_waca_wo.Order_Source ;
	   x_waca_data.Store_ID               := lr_waca_wo.Store_ID ;	   	   
	   x_waca_data.Ship_to_City           := lr_waca_wo.Ship_to_City ; 

	 IF  ( lr_waca_wo.Order_Number IS NOT NULL ) THEN
             x_waca_data.Order_Number           := lr_waca_wo.Order_Number ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Order_Number',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

         IF ( lr_waca_wo.Warranty_Number IS NOT NULL ) THEN
            x_waca_data.Warranty_Number        := lr_waca_wo.Warranty_Number ;
         ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Warranty_Number',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF ( lr_waca_wo.Warranty_SKU IS NOT NULL ) THEN
            x_waca_data.Warranty_SKU           := lr_waca_wo.Warranty_SKU ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Warranty_SKU',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF ( lr_waca_wo.Warranty_Description IS NOT NULL ) THEN
	     x_waca_data.Warranty_Description   := lr_waca_wo.Warranty_Description ;  
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Warranty_Description',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF ( lr_waca_wo.Warranty_Application_Date IS NOT NULL ) THEN
	     x_waca_data.Warranty_Application_Date  := lr_waca_wo.Warranty_Application_Date ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Warranty_Application_Date',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF ( lr_waca_wo.Quantity_Sold IS NOT NULL ) THEN
	    x_waca_data.Quantity_Sold          := lr_waca_wo.Quantity_Sold ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Quantity_Sold',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF ( lr_waca_wo.Retail_Price IS NOT NULL )  THEN
            x_waca_data.Retail_Price           := lr_waca_wo.Retail_Price  ;   
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Retail_Price',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF ( lr_waca_wo.Salesman_ID IS NOT NULL ) THEN
	    x_waca_data.Salesman_ID            := lr_waca_wo.Salesman_ID  ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Salesman_ID',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF ( lr_waca_wo.Currency IS NOT NULL ) THEN
            x_waca_data.Currency               := lr_waca_wo.Currency  ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Currency ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF ( lr_waca_wo.ship_to_country IS NOT NULL)  THEN
            x_waca_data.ship_to_country        := lr_waca_wo.ship_to_country ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','ship_to_country',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;
  
	

	 -- check if it is generic customer 
	 IF  (lr_waca_wo.customer_class_meaning = gc_store 
	      AND lr_waca_wo.customer_type_meaning  = gc_cust_type )  THEN
	    x_waca_data.Customer_Number         := NULL ;         
	    x_waca_data.Contact_First_Name      := NULL ;    
	    x_waca_data.Contact_Last_Name       := NULL ;  
	    x_waca_data.Company_Name            := NULL ;  
	    x_waca_data.Ship_to_Addr1           := NULL ;  
	    x_waca_data.Ship_to_Addr2           := NULL ;    
	    x_waca_data.Ship_to_State           := NULL ;  
	    x_waca_data.Ship_to_Zip             := NULL ;  
	 ELSE	        
	    -- OTHER NON- GENERIC CUSTOMERS
	       
	    x_waca_data.Customer_Number         := lr_waca_wo.Customer_Number ;         
	    x_waca_data.Contact_First_Name      := lc_first_name ;  
	    x_waca_data.Contact_Last_Name       := lc_last_name ;
	    x_waca_data.Company_Name            := lr_waca_wo.Company_Name ; 
	    x_waca_data.Ship_to_Addr1           := lr_waca_wo.Ship_to_Addr1 ; 
	    x_waca_data.Ship_to_Addr2           := lr_waca_wo.Ship_to_Addr2 ; 
	    x_waca_data.Ship_to_City            := lr_waca_wo.Ship_to_City ; 
	    x_waca_data.Ship_to_State           := lr_waca_wo.Ship_to_State ; 
	    x_waca_data.Ship_to_Zip             := lr_waca_wo.Ship_to_Zip ;  

	 END IF; --generic customer 
		  
      ELSE -- NON-POS CUSTOMER

         x_waca_data.Warranty_Number         := lr_waca_wo.Warranty_Number ;
	 x_waca_data.Order_Source            := lr_waca_wo.Order_Source ; 
	 x_waca_data.Store_ID                := NULL ;
	 x_waca_data.Salesman_ID             := lr_waca_wo.Salesman_ID  ;
	 x_waca_data.Ship_to_Addr2           := lr_waca_wo.Ship_to_Addr2 ; 
	 x_waca_data.Ship_to_City            := lr_waca_wo.Ship_to_City ; 
	 x_waca_data.Ship_to_State           := lr_waca_wo.Ship_to_State ; 
	 x_waca_data.Ship_to_Zip             := lr_waca_wo.Ship_to_Zip ; 
	 x_waca_data.Ship_to_City            := lr_waca_wo.Ship_to_City ; 
	 
	   -- Values assignment in case of NON-POS type customer
	 IF ( lr_waca_wo.Order_Number IS NOT NULL ) THEN
	     x_waca_data.Order_Number           := lr_waca_wo.Order_Number ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Order_Number ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF ( lr_waca_wo.Warranty_SKU IS NOT NULL ) THEN
	    x_waca_data.Warranty_SKU           := lr_waca_wo.Warranty_SKU ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Warranty_SKU ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF (lr_waca_wo.Warranty_Description IS NOT NULL ) THEN
	    x_waca_data.Warranty_Description   := lr_waca_wo.Warranty_Description ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Warranty_Description ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF ( lr_waca_wo.Warranty_Application_Date IS NOT NULL )  THEN
	    x_waca_data.Warranty_Application_Date  := lr_waca_wo.Warranty_Application_Date ;   
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Warranty_Application_Date ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF lr_waca_wo.Quantity_Sold IS NOT NULL  THEN
	     x_waca_data.Quantity_Sold          := lr_waca_wo.Quantity_Sold ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Quantity_Sold ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF lr_waca_wo.Retail_Price IS NOT NULL  THEN
	    x_waca_data.Retail_Price           := lr_waca_wo.Retail_Price  ;  
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Retail_Price ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF lr_waca_wo.Customer_Number IS NOT NULL  THEN
	     x_waca_data.Customer_Number         := lr_waca_wo.Customer_Number ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Customer_Number ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF lc_first_name IS NOT NULL  THEN
	    x_waca_data.Contact_First_Name      := lc_first_name ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','first_name ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF lc_last_name IS NOT NULL  THEN
	    x_waca_data.Contact_Last_Name       := lc_last_name ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','last_name ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF lr_waca_wo.Company_Name IS NOT NULL THEN
	    x_waca_data.Company_Name            := lr_waca_wo.Company_Name ; 
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Company_Name ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF lr_waca_wo.Ship_to_Addr1 IS NOT NULL THEN
	     x_waca_data.Ship_to_Addr1           := lr_waca_wo.Ship_to_Addr1 ; 
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Ship_to_Addr1 ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF lr_waca_wo.ship_to_country IS NOT NULL THEN
	    x_waca_data.ship_to_country         := lr_waca_wo.ship_to_country ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','ship_to_country ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF (lr_waca_wo.Currency IS NOT NULL )  THEN 
	    x_waca_data.Currency                := lr_waca_wo.Currency  ;
	 ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Currency ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;		      	
 
      END IF;  -- POS/NON-POS
 

      -- Data common to Warranty Header level -  WACA 

      -- Fetch contact point information - phone number
      OPEN lcu_phone ( ln_rel_party_id );	   
      FETCH lcu_phone
      INTO  x_waca_data.Phone ;
      CLOSE lcu_phone ;

      -- Fetch contact point information - Fax
      OPEN lcu_fax ( ln_rel_party_id);	   
      FETCH lcu_fax
      INTO  x_waca_data.Fax_Number ;
      CLOSE lcu_fax ;

   
      -- Fetch contact point information - mobile
      OPEN lcu_mobile ( ln_rel_party_id );	   
      FETCH lcu_mobile
      INTO  x_waca_data.Office_or_Mobile_no ;
      CLOSE lcu_mobile ;


      -- Fetch contact point information - email
      OPEN lcu_email ( ln_rel_party_id );	   
      FETCH lcu_email
      INTO  x_waca_data.Email ;
      CLOSE lcu_email ;

      x_waca_data.Machine_SKU          := NULL ;       
      x_waca_data.Machine_SKU_Price    := NULL ;       
      x_waca_data.Serial_Number        := NULL ;       
      x_waca_data.Product_Description  := NULL ;
	     
      -- fields specific to Return warranty items  
      IF p_waca_type = 'WR' THEN
	 
	 x_waca_data.sales_type            := 'C';

	 -- Fetch RMA information 

	 OPEN lcu_rma_order ( p_line_id );	   
	 FETCH lcu_rma_order
	 INTO  lc_rma_number,ln_line_number ;
	 CLOSE lcu_rma_order ;

	

	 IF ln_line_number IS  NULL THEN	   
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','RMA LINE Number ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
	 END IF;

	 IF lr_waca_wo.order_source = gc_pos_source THEN
	    x_waca_data.Return_order_Number  := lr_waca_wo.Warranty_Number ;
	 ELSE
	    IF lc_rma_number IS  NULL THEN	   
	       FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	       FND_MESSAGE.SET_TOKEN('REQ_FIELD','RMA Number ',FALSE );
               lc_error_message := FND_MESSAGE.GET; 
	       RAISE EX_MANDATORY_FIELD ;
	    END IF;
	    x_waca_data.Return_order_Number  := lc_rma_number ;                       	        
	 END IF ;
				    
	 x_waca_data.Return_Date          := lr_waca_wo.Return_Date ;         
	 x_waca_data.Order_Line_no        := ln_line_number ; 
      ELSE
	 x_waca_data.sales_type           := 'S';
	 x_waca_data.Return_order_Number  := NULL ;       
	 x_waca_data.Return_Date          := NULL ;         
	 x_waca_data.Order_Line_no        := NULL ;       
      END IF;



   ELSE  --Warranty  Line level Machine SKU WACA DATA
      
      x_waca_data.Record_Code                := 'L';               
      x_waca_data.Batch_Number               := TO_CHAR(sysdate,'CCYYMMDD');           			 
      x_waca_data.Order_Source               := NULL;              
      x_waca_data.Warranty_SKU               := NULL;             
      x_waca_data.Warranty_Description       := NULL;      
      x_waca_data.Warranty_Application_Date  := NULL; 
      x_waca_data.Retail_Price               := NULL ;     
      x_waca_data.Store_id                   := NULL ;               
      x_waca_data.Salesman_id                := NULL ;
      x_waca_data.Customer_Number            := NULL ;         
      x_waca_data.Contact_First_Name         := NULL ;    
      x_waca_data.Contact_Last_Name          := NULL ;  
      x_waca_data.Company_Name               := NULL ;
      x_waca_data.Phone                      := NULL ;
      x_waca_data.Fax_Number                 := NULL ;
      x_waca_data.Office_or_Mobile_no        := NULL ;
      x_waca_data.sales_type                 := NULL ;  
      x_waca_data.Return_order_Number        := NULL ;       
      x_waca_data.Return_Date                := NULL ;         
      x_waca_data.Order_Line_no              := NULL ;       
      x_waca_data.Serial_Number              := NULL  ;         
      x_waca_data.Ship_to_Addr2              := lr_waca_wo.Ship_to_Addr2 ;      
      x_waca_data.Ship_to_State              := lr_waca_wo.Ship_to_State ; 
      x_waca_data.Ship_to_Zip                := lr_waca_wo.Ship_to_Zip ;
      x_waca_data.Ship_to_City               := lr_waca_wo.Ship_to_City ; 

      -- Mandatory fields for Line level Machine SKU WACA DATA
      IF ( lr_waca_wo.Order_Number           IS NOT NULL ) THEN
         x_waca_data.Order_Number               := lr_waca_wo.Order_Number ; 
      ELSE
          FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	  FND_MESSAGE.SET_TOKEN('REQ_FIELD','Order_Number ',FALSE );
          lc_error_message := FND_MESSAGE.GET; 
	  RAISE EX_MANDATORY_FIELD ;
      END IF;

      IF ( lr_waca_wo.Currency               IS NOT NULL ) THEN
          x_waca_data.Currency                   := lr_waca_wo.Currency  ;
      ELSE
          FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	  FND_MESSAGE.SET_TOKEN('REQ_FIELD','Currency ',FALSE );
          lc_error_message := FND_MESSAGE.GET; 
	  RAISE EX_MANDATORY_FIELD ;
      END IF;

      IF ( lr_waca_wo.ship_to_country        IS NOT NULL ) THEN 
         x_waca_data.ship_to_country            := lr_waca_wo.ship_to_country ;
      ELSE
          FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	  FND_MESSAGE.SET_TOKEN('REQ_FIELD','ship_to_country ',FALSE );
          lc_error_message := FND_MESSAGE.GET; 
	  RAISE EX_MANDATORY_FIELD ;
      END IF;

      IF ( lr_waca_wo.Warranty_SKU           IS NOT NULL ) THEN
         x_waca_data.Machine_SKU                := lr_waca_wo.Warranty_SKU ;
      ELSE
         FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	 FND_MESSAGE.SET_TOKEN('REQ_FIELD','Warranty_SKU ',FALSE );
         lc_error_message := FND_MESSAGE.GET; 
	 RAISE EX_MANDATORY_FIELD ;
      END IF;

      IF (  lr_waca_wo.Retail_Price          IS NOT NULL ) THEN
         x_waca_data.Machine_SKU_Price          := lr_waca_wo.Retail_Price ;
      ELSE
         FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	 FND_MESSAGE.SET_TOKEN('REQ_FIELD','Retail_Price ',FALSE );
         lc_error_message := FND_MESSAGE.GET; 
	 RAISE EX_MANDATORY_FIELD ;
      END IF;

      IF ( lr_waca_wo.Warranty_Description   IS NOT NULL ) THEN
         x_waca_data.Product_Description        := lr_waca_wo.Warranty_Description ;
      ELSE
         FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	 FND_MESSAGE.SET_TOKEN('REQ_FIELD','Warranty_Description ',FALSE );
         lc_error_message := FND_MESSAGE.GET; 
	 RAISE EX_MANDATORY_FIELD ;
      END IF;

      IF ( lr_waca_wo.Quantity_Sold          IS NOT NULL ) THEN
         x_waca_data.Quantity_Sold              := lr_waca_wo.Quantity_Sold  ;
      ELSE
         FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	 FND_MESSAGE.SET_TOKEN('REQ_FIELD','Quantity_Sold ',FALSE );
         lc_error_message := FND_MESSAGE.GET; 
	 RAISE EX_MANDATORY_FIELD ;
      END IF;

        



      IF lr_waca_wo.order_source = gc_pos_source THEN   -- POS/NON-POS

         IF  lr_waca_wo.Warranty_Number IS NOT NULL  THEN
	    x_waca_data.Warranty_Number            := lr_waca_wo.Warranty_Number ;  	    
         ELSE
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	    FND_MESSAGE.SET_TOKEN('REQ_FIELD','Warranty_Number ',FALSE );
            lc_error_message := FND_MESSAGE.GET; 
	    RAISE EX_MANDATORY_FIELD ;
         END IF; 

      -- check if it is generic customer 
	 IF  (lr_waca_wo.customer_class_meaning = gc_store 
	     AND lr_waca_wo.customer_type_meaning  = gc_cust_type )  THEN				
	    x_waca_data.Ship_to_Addr1           := NULL ;  	  	    
	 ELSE
	    -- OTHER NON- GENERIC CUSTOMERS					   
	       x_waca_data.Ship_to_Addr1           := lr_waca_wo.Ship_to_Addr1 ; 
	 END IF; --generic customer

      ELSE --Non- POS        
         x_waca_data.Warranty_Number            := lr_waca_wo.Warranty_Number ;	 
	 IF ( lr_waca_wo.Ship_to_Addr1 IS NOT NULL ) THEN					   
	     x_waca_data.Ship_to_Addr1           := lr_waca_wo.Ship_to_Addr1 ;
	 ELSE
	     FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	     FND_MESSAGE.SET_TOKEN('REQ_FIELD','Ship_to_Addr1 ',FALSE );
             lc_error_message := FND_MESSAGE.GET; 
	     RAISE EX_MANDATORY_FIELD ;
         END IF;
 	               
      END IF; -- POS/NON-POS

      --if serial controlled
      IF lr_waca_wo.serial_control <> 1 THEN
         
	 OPEN lcu_serial_number ( P_line_id );	   
	 FETCH lcu_serial_number
	 INTO  ln_serial_count ;
         CLOSE lcu_serial_number ; 

         IF  ln_serial_count = lr_waca_wo.Quantity_Sold THEN 
            x_waca_data.serial_control := 'Y' ;
         ELSE 
	     FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_MANDATORY');
	     FND_MESSAGE.SET_TOKEN('REQ_FIELD','Serial number ',FALSE );
             lc_error_message := FND_MESSAGE.GET; 
	     RAISE EX_MANDATORY_FIELD ;
         END IF;
      ELSE
         x_waca_data.serial_control := 'N' ;
      END IF ; 

   END IF;  --WACA type
		  
   x_waca_data.status := 'S' ; 

EXCEPTION
WHEN  EX_MANDATORY_FIELD THEN
   x_waca_data.status := 'E';                 
   gc_err_code      := 'XX_OM_0007_WACA_MANDATORY';
   gc_err_desc      := SUBSTR(lc_error_message,1,1000) ;
   gc_entity_ref    := 'line_id';
   gn_entity_ref_id :=NVL(gc_line_id,0);
   err_report_type    :=
   XXOM.XX_OM_REPORT_EXCEPTION_T (
				  gc_exception_header
				 ,gc_exception_track
				 ,gc_exception_sol_dom
				 ,gc_error_function
				 ,gc_err_code
				 ,gc_err_desc
				 ,gc_entity_ref
				 ,gn_entity_ref_id
				 );
			    
   XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
						 err_report_type
						,lc_errbuff
						,lc_retcode
					       );

WHEN  OTHERS THEN
   x_waca_data.status := 'E';
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0001_WACA_UNKNOWN_ERROR');
   lc_error_message := FND_MESSAGE.GET;
   lc_sqlcode       := SQLCODE;
   lc_sqlerrm       := SUBSTR( SQLERRM,1,1000);
   gc_err_code      := 'XX_OM_0001_WACA_UNKNOWN_ERROR';
   gc_err_desc      := SUBSTR(lc_error_message||'Error while processing WACA Lines '||lc_sqlerrm,1,1000);
   gc_entity_ref    := 'line_id';
   gn_entity_ref_id :=NVL(gc_line_id,0);
   err_report_type    :=
   XXOM.XX_OM_REPORT_EXCEPTION_T (
				   gc_exception_header
				  ,gc_exception_track
				  ,gc_exception_sol_dom
				  ,gc_error_function
				  ,gc_err_code
				  ,gc_err_desc
				  ,gc_entity_ref
				  ,gn_entity_ref_id
				 );
			    
   XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
						err_report_type
					       ,lc_errbuff
					       ,lc_retcode
						);
END GET_WACA_DATA ;
---------------------------------------------------------------------------------------------------------------
PROCEDURE WRITE_DATA_TO_FILE (
	                       p_waca_data    IN      waca_rec_type
	                      ,x_status       OUT     VARCHAR2
		             )
AS
	        -- +==========================================================================+
                -- | Name  : write_data_to_file                                               |
                -- | Description : Procedure  to write the extracted data in                  |
	        -- |               the given file path                                        |            
                -- | Parameters :                                                             |
                -- |           p_waca_data    -- Warranty Data                                |
                -- |           x_status       -- Status                                       |	
	        -- |                                                                          |
                -- +==========================================================================+

   lc_sqlcode              VARCHAR2 (100);
   lc_sqlerrm              VARCHAR2 (1000);
   lc_errbuff              VARCHAR2 (1000); 
   lc_retcode              VARCHAR2 (100);
   lc_error_message        VARCHAR2 (4000);

BEGIN

   

   IF UTL_FILE.IS_OPEN(gf_utl_file_handle) THEN
      NULL ;
   ELSE
      gf_utl_file_handle := UTL_FILE.FOPEN( gc_utl_file_path, gc_utl_file_name,'w' );
   END IF;
 
   --write the data using utl_file package
   UTL_FILE.PUT_LINE( 
		      gf_utl_file_handle, p_waca_data.Record_Code||CHR(9)||                
		      p_waca_data.Batch_Number||CHR(9)||               
		      p_waca_data.Order_Number||CHR(9)||               
		      p_waca_data.Warranty_Number||CHR(9)||            
		      p_waca_data.Order_Source||CHR(9)||               
		      p_waca_data.Warranty_SKU||CHR(9)||                
		      p_waca_data.Warranty_Description||CHR(9)||        
		      p_waca_data.Warranty_Application_Date||CHR(9)||  
		      p_waca_data.Quantity_Sold||CHR(9)||               
		      p_waca_data.Retail_Price||CHR(9)||                
		      p_waca_data.Store_ID||CHR(9)||                   
		      p_waca_data.Salesman_ID||CHR(9)||                 
		      p_waca_data.Customer_Number||CHR(9)||            
		      p_waca_data.Contact_First_Name||CHR(9)||         
		      p_waca_data.Contact_Last_Name||CHR(9)||          
		      p_waca_data.Company_Name||CHR(9)||               
		      p_waca_data.Ship_to_Addr1||CHR(9)||               
		      p_waca_data.Ship_to_Addr2||CHR(9)||               
		      p_waca_data.Ship_to_City||CHR(9)||               
		      p_waca_data.Ship_to_State||CHR(9)||               
		      p_waca_data.Ship_to_Zip||CHR(9)||                
		      p_waca_data.Ship_to_Country||CHR(9)||             
		      p_waca_data.Currency||CHR(9)||                   
		      p_waca_data.Phone||CHR(9)||                      
		      p_waca_data.Fax_Number||CHR(9)||                 
		      p_waca_data.Office_or_Mobile_no||CHR(9)||        
		      p_waca_data.Email||CHR(9)||                      
		      p_waca_data.Sales_Type||CHR(9)||                  
		      p_waca_data.Return_order_Number||CHR(9)||         
		      p_waca_data.Return_Date||CHR(9)||                 
		      p_waca_data.Order_Line_no||CHR(9)||               
		      p_waca_data.Machine_SKU||CHR(9)||                 
		      p_waca_data.Machine_SKU_Price||CHR(9)||           
		      p_waca_data.Serial_Number||CHR(9)||               
		      p_waca_data.Product_Description
		    );
   x_status := 'S';
EXCEPTION
WHEN OTHERS THEN
   x_status := 'E';
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0001_WACA_UNKNOWN_ERROR');
   lc_error_message := FND_MESSAGE.GET;
   lc_sqlcode       := SQLCODE;
   lc_sqlerrm       := SUBSTR( SQLERRM,1,1000);
   gc_err_code      := 'XX_OM_0001_WACA_UNKNOWN_ERROR';
   gc_err_desc      :=  SUBSTR(lc_error_message||'Error while processing WACA Lines  '||lc_sqlerrm,1,1000);
   gc_entity_ref    := 'line_id';
   gn_entity_ref_id :=NVL(gc_line_id,0);
   err_report_type    :=
   XXOM.XX_OM_REPORT_EXCEPTION_T (
				  gc_exception_header
				 ,gc_exception_track
				 ,gc_exception_sol_dom
				 ,gc_error_function
				 ,gc_err_code
				 ,gc_err_desc
				 ,gc_entity_ref
				 ,gn_entity_ref_id
				 );
			    
   XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
						 err_report_type
						,lc_errbuff
						,lc_retcode
						);
END WRITE_DATA_TO_FILE ;
                     
---------------------------------------------------------------------------------------------------------------
PROCEDURE UPDATE_LINE ( 
                        p_line_id IN      oe_order_lines_all.line_id%TYPE 
		       ,x_status  OUT     VARCHAR2
		       ,p_status_code IN  VARCHAR2
		       )
AS	  
                -- +==========================================================================+
                -- | Name  : Update line                                                      |
                -- | Description : Procedure  to update the Warranty line status              |
	        -- |                                                                          |            
                -- | Parameters :                                                             |
                -- |           p_line_id      -- Line id                                      |
                -- |           x_status       -- Update Status                                |
		-- |           p_status_code  -- Status code  Ex:- values can be 'E' or 'P'   |
		-- |			                                                      |    
	        -- |                                                                          |
                -- +==========================================================================+  


   lc_sqlcode               VARCHAR2 (100);
   lc_sqlerrm               VARCHAR2 (1000);
   lc_errbuff               VARCHAR2 (1000); 
   lc_retcode               VARCHAR2 (100);
   lc_error_message         VARCHAR2 (1000);
   lc_return_status         VARCHAR2 (10);

-- variables for calling custom API
    lt_line_rec                 XX_OM_LINE_ATTRIBUTES_T ;
    lc_licence_address          xx_om_line_attributes_all.licence_address%TYPE;
    lc_vendor_config_id         xx_om_line_attributes_all.vendor_config_id%TYPE;
    lc_fulfillment_type         xx_om_line_attributes_all.fulfillment_type%TYPE;
    lc_line_type                xx_om_line_attributes_all.line_type%TYPE;
    lc_line_modifier            xx_om_line_attributes_all.line_modifier%TYPE;
    lc_release_num              xx_om_line_attributes_all.release_num%TYPE;
    lc_cost_center_dept         xx_om_line_attributes_all.cost_center_dept%TYPE;
    lc_desktop_del_addr         xx_om_line_attributes_all.desktop_del_addr%TYPE;
    lc_vendor_site_id           xx_om_line_attributes_all.vendor_site_id%TYPE;
    lc_pos_trx_num              xx_om_line_attributes_all.pos_trx_num%TYPE;
    lc_one_time_deal            xx_om_line_attributes_all.one_time_deal%TYPE;
    lc_trans_line_status        xx_om_line_attributes_all.trans_line_status%TYPE;
    ln_cust_price               xx_om_line_attributes_all.cust_price%TYPE;
    lc_cust_uom                 xx_om_line_attributes_all.cust_uom%TYPE;
    lc_cust_comments            xx_om_line_attributes_all.cust_comments%TYPE;
    lc_pip_campaign_id          xx_om_line_attributes_all.pip_campaign_id%TYPE;
    ln_ext_top_model_line_id    xx_om_line_attributes_all.ext_top_model_line_id%TYPE;
    ln_ext_link_to_line_id      xx_om_line_attributes_all.ext_link_to_line_id%TYPE;
    lc_config_code              xx_om_line_attributes_all.config_code%TYPE;
    lc_gift_message             xx_om_line_attributes_all.gift_message%TYPE;
    lc_gift_email               xx_om_line_attributes_all.gift_email%TYPE;
    lc_return_rga_number        xx_om_line_attributes_all.return_rga_number%TYPE;
    ld_delivery_date_from       xx_om_line_attributes_all.delivery_date_from%TYPE;
    ld_delivery_date_to         xx_om_line_attributes_all.delivery_date_to%TYPE;
    lc_wholesaler_fac_cd        xx_om_line_attributes_all.wholesaler_fac_cd%TYPE;
    lc_wholesaler_acct_num      xx_om_line_attributes_all.wholesaler_acct_num%TYPE;
    lc_return_act_cat_code      xx_om_line_attributes_all.return_act_cat_code%TYPE;
    lc_po_del_details           xx_om_line_attributes_all.po_del_details%TYPE;
    ln_ret_ref_header_id        xx_om_line_attributes_all.ret_ref_header_id%TYPE;
    ln_ret_ref_line_id          xx_om_line_attributes_all.ret_ref_line_id%TYPE;
    lc_ship_to_flag             xx_om_line_attributes_all.ship_to_flag%TYPE;            
    lc_item_note                xx_om_line_attributes_all.item_note%TYPE;               
    lc_special_desc             xx_om_line_attributes_all.special_desc%TYPE;            
    lc_non_cd_line_type         xx_om_line_attributes_all.non_cd_line_type%TYPE;        
    lc_supplier_type            xx_om_line_attributes_all.supplier_type%TYPE;           
    lc_vendor_product_code      xx_om_line_attributes_all.vendor_product_code%TYPE;     
    lc_contract_details         xx_om_line_attributes_all.contract_details%TYPE;        
    lc_aops_orig_order_num      xx_om_line_attributes_all.aops_orig_order_num%TYPE;     
    ld_aops_orig_order_date     xx_om_line_attributes_all.aops_orig_order_date%TYPE;    
    lc_item_comments            xx_om_line_attributes_all.item_comments%TYPE;           
    ln_backordered_qty          xx_om_line_attributes_all.backordered_qty%TYPE;         
    lc_taxable_flag             xx_om_line_attributes_all.taxable_flag%TYPE;            
    ln_waca_parent_id           xx_om_line_attributes_all.waca_parent_id%TYPE;          
    ln_aops_orig_order_line_num xx_om_line_attributes_all.aops_orig_order_line_num%TYPE;
    lc_sku_dept                 xx_om_line_attributes_all.sku_dept%TYPE;                
    lc_item_source              xx_om_line_attributes_all.item_source%TYPE;             
    ln_average_cost             xx_om_line_attributes_all.average_cost%TYPE;            
    ln_canada_pst_tax           xx_om_line_attributes_all.canada_pst_tax%TYPE;          
    ln_po_cost                  xx_om_line_attributes_all.po_cost%TYPE;                 
    lc_waca_status              xx_om_line_attributes_all.waca_status%TYPE;
    lc_resourcing_flag          xx_om_line_attributes_all.resourcing_flag%TYPE;
    lc_cust_item_number         xx_om_line_attributes_all.cust_item_number%TYPE;        
    ld_pod_date                 xx_om_line_attributes_all.pod_date%TYPE;           
    ln_return_auth_id           xx_om_line_attributes_all.return_auth_id%TYPE;          
    lc_return_code              xx_om_line_attributes_all.return_code%TYPE;             
    ln_sku_list_price           xx_om_line_attributes_all.sku_list_price%TYPE;          
    lc_waca_item_ctr_num        xx_om_line_attributes_all.waca_item_ctr_num%TYPE;       
    ld_new_schedule_ship_date   xx_om_line_attributes_all.new_schedule_ship_date%TYPE ; 
    ld_new_schedule_arr_date    xx_om_line_attributes_all.new_schedule_arr_date%TYPE;   
    ln_taylor_unit_price        xx_om_line_attributes_all.taylor_unit_price%TYPE;       
    ln_taylor_unit_cost         xx_om_line_attributes_all.taylor_Unit_cost%TYPE;        
    ln_xdock_inv_org_id         xx_om_line_attributes_all.xdock_inv_org_id%TYPE;         
    lc_payment_subtype_cod_ind  xx_om_line_attributes_all.payment_subtype_cod_ind%TYPE; 
    lc_del_to_post_office_ind   xx_om_line_attributes_all.del_to_post_office_ind%TYPE;  
    lc_wholesaler_item          xx_om_line_attributes_all.wholesaler_item%TYPE;         
    lc_cust_comm_pref           xx_om_line_attributes_all.cust_comm_pref%TYPE;          
    lc_cust_pref_email          xx_om_line_attributes_all.cust_pref_email%TYPE;         
    lc_cust_pref_fax            xx_om_line_attributes_all.cust_pref_fax%TYPE;         
    lc_cust_pref_phone          xx_om_line_attributes_all.cust_pref_phone%TYPE;         
    lc_cust_pref_phextn         xx_om_line_attributes_all.cust_pref_phextn%TYPE;        
    ln_freight_line_id          xx_om_line_attributes_all.freight_line_id%TYPE;         
    ln_freight_primary_line_id  xx_om_line_attributes_all.freight_primary_line_id%TYPE; 
    ld_creation_date            xx_om_line_attributes_all.creation_date%TYPE;           
    lc_created_by               xx_om_line_attributes_all.created_by%TYPE;              
    ld_last_update_date         xx_om_line_attributes_all.last_update_date%TYPE;        
    ln_last_updated_by          xx_om_line_attributes_all.last_updated_by%TYPE;         
    ln_last_update_login        xx_om_line_attributes_all.last_update_login%TYPE;       
 
	   
BEGIN
   SELECT                   
         licence_address            
        ,vendor_config_id           
        ,fulfillment_type           
        ,line_type                  
        ,line_modifier              
        ,release_num                
        ,cost_center_dept           
        ,desktop_del_addr                   
        ,pos_trx_num                
        ,one_time_deal              
        ,trans_line_status          
        ,cust_price                 
        ,cust_uom                   
        ,cust_comments              
        ,pip_campaign_id            
        ,ext_top_model_line_id      
        ,ext_link_to_line_id        
        ,config_code                
        ,gift_message               
        ,gift_email                 
        ,return_rga_number          
        ,delivery_date_from         
        ,delivery_date_to           
        ,wholesaler_fac_cd          
        ,wholesaler_acct_num        
        ,return_act_cat_code        
        ,po_del_details             
        ,ret_ref_header_id        
        ,ret_ref_line_id          
        ,ship_to_flag               
        ,item_note                  
        ,special_desc               
        ,non_cd_line_type           
        ,supplier_type              
        ,vendor_product_code        
        ,contract_details           
        ,aops_orig_order_num        
        ,aops_orig_order_date       
        ,item_comments              
        ,backordered_qty            
        ,taxable_flag               
        ,waca_parent_id             
        ,aops_orig_order_line_num   
        ,sku_dept                   
        ,item_source                
        ,average_cost               
        ,canada_pst_tax             
        ,po_cost                    
        ,waca_status                
        ,cust_item_number           
        ,pod_date                   
        ,return_auth_id             
        ,return_code                
        ,sku_list_price             
        ,waca_item_ctr_num          
        ,new_schedule_ship_date     
        ,new_schedule_arr_date      
        ,taylor_unit_price          
        ,taylor_unit_cost           
        ,xdock_inv_org_id           
        ,payment_subtype_cod_ind    
        ,del_to_post_office_ind     
        ,wholesaler_item            
        ,cust_comm_pref             
        ,cust_pref_email            
        ,cust_pref_fax              
        ,cust_pref_phone            
        ,cust_pref_phextn           
        ,freight_line_id            
        ,freight_primary_line_id    
    INTO                                
         lc_licence_address             
        ,lc_vendor_config_id            
        ,lc_fulfillment_type            
        ,lc_line_type                   
        ,lc_line_modifier               
        ,lc_release_num                 
        ,lc_cost_center_dept            
        ,lc_desktop_del_addr                      
        ,lc_pos_trx_num                 
        ,lc_one_time_deal               
        ,lc_trans_line_status           
        ,ln_cust_price                  
        ,lc_cust_uom                    
        ,lc_cust_comments               
        ,lc_pip_campaign_id             
        ,ln_ext_top_model_line_id       
        ,ln_ext_link_to_line_id         
        ,lc_config_code                 
        ,lc_gift_message                
        ,lc_gift_email                  
        ,lc_return_rga_number           
        ,ld_delivery_date_from          
        ,ld_delivery_date_to            
        ,lc_wholesaler_fac_cd           
        ,lc_wholesaler_acct_num         
        ,lc_return_act_cat_code         
        ,lc_po_del_details              
        ,ln_ret_ref_header_id         
        ,ln_ret_ref_line_id           
        ,lc_ship_to_flag                
        ,lc_item_note                   
        ,lc_special_desc                
        ,lc_non_cd_line_type            
        ,lc_supplier_type               
        ,lc_vendor_product_code         
        ,lc_contract_details            
        ,lc_aops_orig_order_num         
        ,ld_aops_orig_order_date        
        ,lc_item_comments               
        ,ln_backordered_qty             
        ,lc_taxable_flag                
        ,ln_waca_parent_id              
        ,ln_aops_orig_order_line_num    
        ,lc_sku_dept                    
        ,lc_item_source                 
        ,ln_average_cost                
        ,ln_canada_pst_tax              
        ,ln_po_cost                     
        ,lc_waca_status                 
        ,lc_cust_item_number            
        ,ld_pod_date                    
        ,ln_return_auth_id              
        ,lc_return_code                 
        ,ln_sku_list_price              
        ,lc_waca_item_ctr_num           
        ,ld_new_schedule_ship_date      
        ,ld_new_schedule_arr_date       
        ,ln_taylor_unit_price           
        ,ln_taylor_unit_cost            
        ,ln_xdock_inv_org_id            
        ,lc_payment_subtype_cod_ind     
        ,lc_del_to_post_office_ind      
        ,lc_wholesaler_item             
        ,lc_cust_comm_pref              
        ,lc_cust_pref_email             
        ,lc_cust_pref_fax               
        ,lc_cust_pref_phone             
        ,lc_cust_pref_phextn            
        ,ln_freight_line_id             
        ,ln_freight_primary_line_id     
    FROM   xx_om_line_attributes_all
    WHERE  line_id = p_line_id ;
    
   lt_line_rec := XX_OM_LINE_ATTRIBUTES_T ( p_line_id                    
                                            ,lc_licence_address             
                                            ,lc_vendor_config_id            
                                            ,lc_fulfillment_type            
                                            ,lc_line_type                   
                                            ,lc_line_modifier               
                                            ,lc_release_num                 
                                            ,lc_cost_center_dept            
                                            ,lc_desktop_del_addr        
                                            ,lc_vendor_site_id                       
                                            ,lc_pos_trx_num                 
                                            ,lc_one_time_deal               
                                            ,lc_trans_line_status           
                                            ,ln_cust_price                  
                                            ,lc_cust_uom                    
                                            ,lc_cust_comments               
                                            ,lc_pip_campaign_id             
                                            ,ln_ext_top_model_line_id       
                                            ,ln_ext_link_to_line_id         
                                            ,lc_config_code                 
                                            ,lc_gift_message                
                                            ,lc_gift_email                  
                                            ,lc_return_rga_number           
                                            ,ld_delivery_date_from          
                                            ,ld_delivery_date_to            
                                            ,lc_wholesaler_fac_cd           
                                            ,lc_wholesaler_acct_num         
                                            ,lc_return_act_cat_code         
                                            ,lc_po_del_details              
                                            ,ln_ret_ref_header_id         
                                            ,ln_ret_ref_line_id           
                                            ,lc_ship_to_flag                
                                            ,lc_item_note                   
                                            ,lc_special_desc                
                                            ,lc_non_cd_line_type            
                                            ,lc_supplier_type               
                                            ,lc_vendor_product_code         
                                            ,lc_contract_details            
                                            ,lc_aops_orig_order_num         
                                            ,ld_aops_orig_order_date        
                                            ,lc_item_comments               
                                            ,ln_backordered_qty             
                                            ,lc_taxable_flag                
                                            ,ln_waca_parent_id              
                                            ,ln_aops_orig_order_line_num    
                                            ,lc_sku_dept                    
                                            ,lc_item_source                 
                                            ,ln_average_cost                
                                            ,ln_canada_pst_tax              
                                            ,ln_po_cost                     
                                            ,lc_resourcing_flag            
                                            ,p_status_code                 
                                            ,lc_cust_item_number            
                                            ,ld_pod_date                    
                                            ,ln_return_auth_id              
                                            ,lc_return_code                 
                                            ,ln_sku_list_price              
                                            ,lc_waca_item_ctr_num           
                                            ,ld_new_schedule_ship_date      
                                            ,ld_new_schedule_arr_date       
                                            ,ln_taylor_unit_price           
                                            ,ln_taylor_unit_cost            
                                            ,ln_xdock_inv_org_id            
                                            ,lc_payment_subtype_cod_ind     
                                            ,lc_del_to_post_office_ind      
                                            ,lc_wholesaler_item             
                                            ,lc_cust_comm_pref              
                                            ,lc_cust_pref_email             
                                            ,lc_cust_pref_fax               
                                            ,lc_cust_pref_phone             
                                            ,lc_cust_pref_phextn            
                                            ,ln_freight_line_id             
                                            ,ln_freight_primary_line_id  
                                            ,SYSDATE
                                            ,FND_GLOBAL.USER_ID
                                            ,SYSDATE
                                            ,FND_GLOBAL.USER_ID
                                            ,FND_GLOBAL.USER_ID
                                            );

    XX_OM_LINE_ATTRIBUTES_PKG.UPDATE_ROW(
                                           p_line_rec        => lt_line_rec
                                          ,x_return_status  => lc_return_status
                                          ,x_errbuf         => lc_errbuff
                                         );
 
    x_status := lc_return_status ;       

                                                                                                                            
EXCEPTION
WHEN NO_DATA_FOUND THEN
   x_status := 'E';
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_WACA_UPD_ERROR');
   lc_error_message := FND_MESSAGE.GET;
   lc_sqlcode       := SQLCODE;
   lc_sqlerrm       := SUBSTR( SQLERRM,1,1000);
   gc_err_code      := 'XX_OM_0007_WACA_UPD_ERROR';
   gc_err_desc      :=  SUBSTR(lc_error_message||'Error while processing WACA Lines '||lc_sqlerrm,1,1000);
   gc_entity_ref    := 'line_id';
   gn_entity_ref_id :=NVL(gc_line_id,0);
   err_report_type    :=
   XXOM.XX_OM_REPORT_EXCEPTION_T (
				  gc_exception_header
				 ,gc_exception_track
				 ,gc_exception_sol_dom
				 ,gc_error_function
				 ,gc_err_code
				 ,gc_err_desc
				 ,gc_entity_ref
				 ,gn_entity_ref_id
				 );
			    
   XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
						err_report_type
					       ,lc_errbuff
					       ,lc_retcode
						);
   
WHEN OTHERS THEN
   x_status := 'E';
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0001_WACA_UNKNOWN_ERROR');
   lc_error_message := FND_MESSAGE.GET;
   lc_sqlcode       := SQLCODE;
   lc_sqlerrm       := SUBSTR( SQLERRM,1,1000);
   gc_err_code      := 'XX_OM_0001_WACA_UNKNOWN_ERROR';
   gc_err_desc      :=  SUBSTR(lc_error_message||'Error while processing WACA Lines '||lc_sqlerrm,1,1000);
   gc_entity_ref    := 'line_id';
   gn_entity_ref_id :=NVL(gc_line_id,0);
   err_report_type    :=
   XXOM.XX_OM_REPORT_EXCEPTION_T (
				  gc_exception_header
				 ,gc_exception_track
				 ,gc_exception_sol_dom
				 ,gc_error_function
				 ,gc_err_code
				 ,gc_err_desc
				 ,gc_entity_ref
				 ,gn_entity_ref_id
				 );
			    
   XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
						err_report_type
					       ,lc_errbuff
					       ,lc_retcode
						);
END UPDATE_LINE ;
---------------------------------------------------------------------------------------------------------------------
FUNCTION GET_SERIAL_NUMBER ( 
                             p_line_id        IN  oe_order_lines_all.line_id%TYPE
                            ,p_order_of_item  IN  NUMBER
		            ) RETURN  VARCHAR2
       AS
                -- +==========================================================================+
                -- | Name  : get_serial_number                                                |
                -- | Description : Function to get the serial number given the line id        |
	        -- |                                                                          |            
                -- | Parameters :                                                             |
                -- |           p_line_id      --> Line id                                     |
                -- |           p_order_of_item --> Order of the Item                          |
		-- |                           Ex:- if the  value 2 is passed, 2nd            |
		-- |			       serial number in the series will be fetched    |    
	        -- |                                                                          |
                -- +==========================================================================+
   CURSOR lcu_serial_number ( p_line_id mtl_material_transactions.source_line_id%TYPE ) 
   IS
   SELECT   MSN.serial_number 
   FROM     mtl_material_transactions MMT
	   ,mtl_serial_numbers MSN
   WHERE   MMT.transaction_id = MSN.last_transaction_id
   AND     MMT.source_line_id=p_line_id;
		

   lc_sqlcode              VARCHAR2 (100);
   lc_sqlerrm              VARCHAR2 (1000);
   lc_errbuff              VARCHAR2 (1000); 
   lc_retcode              VARCHAR2 (100);
   lc_error_message        VARCHAR2 (4000);

BEGIN

   -- fetch the serial number and return to the called procedure

   FOR serial_number_rec_type IN lcu_serial_number ( p_line_id )
   LOOP
      IF lcu_serial_number%ROWCOUNT = p_order_of_item THEN     
	 RETURN serial_number_rec_type.serial_number ;
      END IF;
   END LOOP;
   --returns null value if it is not a serial controlled item.
   RETURN NULL;

EXCEPTION
WHEN OTHERS THEN	  
   --x_status := 'E';
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0001_WACA_UNKNOWN_ERROR');
   lc_error_message := FND_MESSAGE.GET;
   lc_sqlcode       := SQLCODE;
   lc_sqlerrm       := SUBSTR( SQLERRM,1,1000);
   gc_err_code      := 'XX_OM_0001_WACA_UNKNOWN_ERROR';
   gc_err_desc      :=  SUBSTR(lc_error_message||'Error while processing WACA Lines '||lc_sqlerrm,1,1000);
   gc_entity_ref    := 'line_id';
   gn_entity_ref_id :=NVL(gc_line_id,0);
   err_report_type    :=
   XXOM.XX_OM_REPORT_EXCEPTION_T (
				   gc_exception_header
				  ,gc_exception_track
				  ,gc_exception_sol_dom
				  ,gc_error_function
				  ,gc_err_code
				  ,gc_err_desc
				  ,gc_entity_ref
				  ,gn_entity_ref_id
				 );
			    
   XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
						err_report_type
					       ,lc_errbuff
					       ,lc_retcode
						);
   RETURN NULL;   
END GET_SERIAL_NUMBER ;

---------------------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_WACA_LINES ( 
                              x_errbuff          OUT      VARCHAR2
                             ,x_retcode		 OUT      NUMBER                                                                                                       
                             ,p_file_name        IN       VARCHAR2
		             ,p_file_location    IN       VARCHAR2
			     ,p_waca_supplier    IN       VARCHAR2
			     ,p_pos_source       IN       VARCHAR2
			     ,p_store_type       IN       VARCHAR2
			     ,p_hold_name        IN       VARCHAR2
		             )
AS
	  
		-- +==========================================================================+
                -- | Name  : extract_waca_lines                                               |
                -- | Description : Main procedure to extract all the Warranty lines .         |
	        -- |               This procedure is called from concurrent program           |
	        -- |                                                                          |            
                -- | Parameters :      x_errbuff       -- conc. Prog Parameter                |
                -- |                   x_retcode       -- conc. Prog Parameter                |
                -- |                   p_file_name     -- File name                           |
                -- |                   p_file_location -- location where the file is created  |
                -- |                   p_waca_supplier -- WACA supplier                       |    
                -- |                   p_pos_source    -- 'POS' source value                  |
	        -- |                                                                          |
                -- +==========================================================================+
	   
-- Declaration of Variables
ln_machine_sku_line_id  oe_order_lines_all.line_id%TYPE;
lc_waca_type            VARCHAR2(10);
ln_parent_rec_id        oe_order_lines_all.line_id%TYPE;
ln_child_rec_id         oe_order_lines_all.line_id%TYPE;
ln_machine_sku_cnt      NUMBER;
lt_child_id             child_tbl_type ;
lr_waca_parent          waca_rec_type ;
lt_waca_child_data      waca_tbl_type ;
EX_INCOMPLETE_BUNDLE    EXCEPTION;
ln_lines_counter        PLS_INTEGER;
lc_sqlcode              VARCHAR2 (100);
lc_sqlerrm              VARCHAR2 (1000);
lc_errbuff              VARCHAR2 (1000); 
lc_retcode              VARCHAR2 (100);
lc_error_message        VARCHAR2 (4000);
lc_write_status         VARCHAR2(10);
lc_update_status        VARCHAR2(10);
ln_sku_cnt              NUMBER;
ln_hold_exists          oe_hold_sources_all.released_flag%TYPE;
	

   -- Main query to fetch all the eligible Warranty lines

   CURSOR lcu_waca_main 
   IS
   SELECT OOLA.line_id
	 ,OOLA.header_id
	 ,OTTA.order_category_code
   FROM   oe_transaction_types_all OTTA
	 ,xx_om_line_attributes_all XXOL
	 ,oe_order_sources      OOS    
	 ,oe_order_headers_all OOHA
	 ,oe_order_lines_all OOLA
    ,po_vendor_sites_all PVSA
    ,po_vendors PV
   WHERE OOLA.header_id = OOHA.header_id          
   AND   OOHA.order_source_id   = OOS.order_source_id
   AND   OOLA.line_id   = XXOL.line_id 
   AND   OOLA.line_type_id = OTTA.transaction_type_id
   AND   OOLA .ship_from_org_id IS NOT NULL
   AND   OOLA.flow_status_code NOT IN ( gc_stat_cancel, gc_stat_entered )
   AND   XXOL.vendor_site_id = PVSA .vendor_site_id
   AND   PVSA .vendor_id     = PV.vendor_id
   AND   PV.vendor_name      = gc_waca_supplier
   AND   ( XXOL.waca_status  IS NULL OR   XXOL.waca_status = 'E' ) ;                        

	 
   -- cursor to check if hold exists in warranty line with machine SKUs. 
   CURSOR lcu_hold_exists (p_line_id oe_order_holds_all.line_id%TYPE ) 
   IS
   SELECT OHSA.released_flag
   FROM   oe_hold_definitions OHD
	 ,oe_order_holds_all OOHA1
	 ,oe_hold_sources_all OHSA  
   WHERE  OOHA1.line_id = p_line_id
   AND   OOHA1.hold_source_id = OHSA.hold_source_id       
   AND   OHSA.released_flag ='N'
   AND   OHSA.hold_id = OHD.hold_id
   AND   OHD.name = gc_waca_hold  ;

           
   -- cursor to fetch the count of machine SKU lines  for the given warranty line.
   CURSOR lcu_waca_machine_sku_cnt ( p_line_id oe_order_lines_all.line_id%TYPE )
   IS
   SELECT COUNT(OOLA.line_id)
   FROM   oe_order_lines_all OOLA        
	, xx_om_line_attributes_all XXOL
   WHERE OOLA.line_id   = XXOL.line_id                 
   AND  XXOL.waca_parent_id     = p_line_id ; 

   -- cursor to fetch the machine SKU lines for the given warranty line.
   CURSOR lcu_waca_machine_sku ( p_line_id oe_order_lines_all.line_id%TYPE )
   IS
   SELECT OOLA.line_id
	 ,OOLA.header_id
   FROM   oe_order_lines_all OOLA        
	, xx_om_line_attributes_all XXOL
   WHERE OOLA.line_id   = XXOL.line_id   
   AND   XXOL.waca_parent_id    =  p_line_id  ;  

   -- cursor to fetch profile that stores the WACA file name.
   CURSOR lcu_waca_profile
   IS
   SELECT  FPOV.application_id
          ,FPOV.profile_option_id
	  ,FPOV.level_id
	  ,FPOV.level_value
	  ,FPOV.level_value_application_id
	  ,FPOV.level_value2
   FROM   fnd_profile_option_values FPOV
         ,fnd_profile_options FPO 
   WHERE  FPOV.profile_option_id =FPO.profile_option_id 
   AND     FPO.profile_option_name = gc_waca_profile ;
	 	 



BEGIN


   --- open utl_file
   IF UTL_FILE.IS_OPEN(gf_utl_file_handle) THEN
      UTL_FILE.FCLOSE(gf_utl_file_handle);
   END IF;

   gc_utl_file_path := p_file_location ;
   gc_utl_file_name := p_file_name     ;


 
   gc_pos_source    := p_pos_source ;
   gc_waca_supplier := p_waca_supplier ;
   gc_store         := p_store_type ;
   gc_waca_hold     := p_hold_name  ;

   FOR waca_main_rec_type IN lcu_waca_main
   LOOP 
      gc_line_id := waca_main_rec_type.line_id ;
      ln_hold_exists := 'Y';
      BEGIN
		     
      -- check if the Warranty item is a Return Item 
      IF waca_main_rec_type.order_category_code  = gc_order_category THEN  -- warranty type
	 -- Return warranty Items
	 lc_waca_type := 'WR' ;
	
	 ln_parent_rec_id := waca_main_rec_type.line_id ;

	 -- get the WACA data for the return line
	 GET_WACA_DATA  (
			 'WR'   
			 ,ln_parent_rec_id      
			 ,lr_waca_parent 
			);
	

	 IF lr_waca_parent.status = 'S' THEN
	   
	   FND_FILE.PUT_LINE ( FND_FILE.LOG ,'Warranty Return line - Line id :'||ln_parent_rec_id 
	                       || ' has been written to the file ');   	 
	    -- Write Header data to the file
	    WRITE_DATA_TO_FILE ( 
				lr_waca_parent
			       ,lc_write_status
			       );

	    --check if write status is success
	    IF lc_write_status = 'S' THEN
	       -- Update the Warranty line as processed.   
	       UPDATE_LINE ( 
			    ln_parent_rec_id
			    ,lc_update_status
			    ,'P'
			    );

	       -- check if the update line is successful
	       IF lc_update_status <> 'S' THEN
		  -- write to error table stating the line table update has failed.
		  FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0008_WACA_LINE_UPD_FAIL');
		  lc_error_message := FND_MESSAGE.GET;                  
		  gc_err_code      := 'XX_OM_0008_WACA_LINE_UPD_FAIL';
		  gc_err_desc      := lc_error_message ;
		  gc_entity_ref    := 'line_id';
		  gn_entity_ref_id :=NVL(gc_line_id,0);
		  err_report_type    :=
		     XXOM.XX_OM_REPORT_EXCEPTION_T (
						     gc_exception_header
						    ,gc_exception_track
						    ,gc_exception_sol_dom
						    ,gc_error_function
						    ,gc_err_code
						    ,gc_err_desc
						    ,gc_entity_ref
						    ,gn_entity_ref_id
						   );
					   
		  XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
								err_report_type
							       ,lc_errbuff
							       ,lc_retcode
							      );
	       END IF;
	    ELSE	       
	       -- Update the Warranty line as Errored.  
	       UPDATE_LINE (
			    ln_parent_rec_id
			   ,lc_update_status
			   ,'E'
			   );
				  
	    END IF;
         ELSE
	    FND_FILE.PUT_LINE ( FND_FILE.LOG ,'Warranty Return line - Line id :'||ln_parent_rec_id 
	                           || ' has errored since one of the mandatory fields has failed ');
	 END IF; 

      ELSE  -- warranty type
         -- All the regular warranty items shall flow in this part    	   
	 -- check if the warranty has any assocciated SKUs.
	 OPEN lcu_waca_machine_sku_cnt ( waca_main_rec_type.line_id );	   
	 FETCH lcu_waca_machine_sku_cnt
	 INTO  ln_machine_sku_cnt ;
	 CLOSE lcu_waca_machine_sku_cnt ;      	    
		     
	 -- check if the warranty lines has any assoicated machine SKUs   
	 IF ( ln_machine_sku_cnt <> 0 ) THEN -- Warranty line with Machine SKU lines.
         
	    -- check if the Warranty  line has WACA hold on it	
	    FOR hold_exists_rec_type IN lcu_hold_exists ( waca_main_rec_type.line_id )
	    LOOP
	       ln_hold_exists := hold_exists_rec_type.released_flag ; 
	    END LOOP;

	    IF NVL(ln_hold_exists,'Y') <> 'N' THEN
	       lc_waca_type := 'WM' ;
	       ln_parent_rec_id := waca_main_rec_type.line_id ;		     	   
               -- getting header WACA data
	       GET_WACA_DATA  ( 
	                        'WO'   
				,ln_parent_rec_id      
				,lr_waca_parent 
			      );
	        IF lr_waca_parent.status = 'S' THEN		
	           -- Table Variable Initialization.
		   lt_waca_child_data.DELETE ;
		   ln_lines_counter := 1;
		   FOR waca_machine_sku_rec_type IN  lcu_waca_machine_sku ( waca_main_rec_type.line_id )
		   LOOP   
		      --extract child info 
		      GET_WACA_DATA  (
			              'WM'	
				      ,waca_machine_sku_rec_type.line_id      
				      ,lt_waca_child_data(ln_lines_counter) 
				     ) ; 								       
		      IF lt_waca_child_data(ln_lines_counter).status <>  'S' THEN
			 FND_FILE.PUT_LINE ( FND_FILE.LOG ,'Warranty line with machine SKUs - Line id :'||ln_parent_rec_id 
			                      || ' has errored since one of the mandatory fields has failed ');
			 -- Update the Warranty line as Errored.
			 UPDATE_LINE (
			              ln_parent_rec_id
				     ,lc_update_status
				     ,'E'
				      );                         
			 RAISE EX_INCOMPLETE_BUNDLE ;
		       END IF; -- get child data status
		       ln_lines_counter := ln_lines_counter + 1;
						 
		   END LOOP;
		ELSE
		   FND_FILE.PUT_LINE ( FND_FILE.LOG ,'Warranty line with machine SKUs - Line id :'||ln_parent_rec_id 
		         		    || ' has errored since one of the mandatory fields has failed ');
		   -- Update the Warranty line as Errored. 
		   UPDATE_LINE (
		                ln_parent_rec_id
			       ,lc_update_status
			       ,'E'
			       ); 
		   RAISE EX_INCOMPLETE_BUNDLE ;
		END IF; -- get parent data status
				  
		-- Writing to the utl_file shall proceeed only when all the item data 
		-- have been successfully extracted.
		  
		-- Write Header (Warranty line ) data to the file
		   
		WRITE_DATA_TO_FILE ( 
		                    lr_waca_parent
				   ,lc_write_status 
				   );
		IF lc_write_status = 'S' THEN
		   FND_FILE.PUT_LINE ( FND_FILE.LOG ,'Warranty line with machine SKUs - Line id :'||
		                       ln_parent_rec_id || ' has been written to the file ');   	 
		   -- Update the Warranty line as processed.   
		   UPDATE_LINE (
		                ln_parent_rec_id
			       ,lc_update_status
			       ,'P'
			       );
		   -- check if the update line is successful
		   IF lc_update_status <> 'S' THEN
		      -- write to error table stating the line table update has failed.
		      FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0008_WACA_LINE_UPD_FAIL');
		      lc_error_message := FND_MESSAGE.GET;                  
		      gc_err_code      := 'XX_OM_0008_WACA_LINE_UPD_FAIL';
		      gc_err_desc      := lc_error_message ;
		      gc_entity_ref    := 'line_id';
		      gn_entity_ref_id :=NVL(gc_line_id,0);
		      err_report_type    :=
		      XXOM.XX_OM_REPORT_EXCEPTION_T (
						      gc_exception_header
						     ,gc_exception_track
						     ,gc_exception_sol_dom
						     ,gc_error_function
						     ,gc_err_code
						     ,gc_err_desc
						     ,gc_entity_ref
						     ,gn_entity_ref_id
						    );
						    
		      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
								    err_report_type
								   ,lc_errbuff
								   ,lc_retcode
								  );
		   END IF; -- update status
		ELSE
		   -- Update the Warranty line as Errored.		       
		   UPDATE_LINE ( 
				ln_parent_rec_id
			       ,lc_update_status
			       ,'E'
			       );
					      
		END IF; -- parent write status
		-- Write Machine SKUs data to the file
		FOR i in lt_waca_child_data.FIRST..lt_waca_child_data.LAST
		LOOP
		   ln_sku_cnt := lt_waca_child_data(i).Quantity_Sold ;					    
		   FOR j in 1..ln_sku_cnt 
		   LOOP  
		      lt_waca_child_data(i).Quantity_Sold :=1;		     
                      IF lt_waca_child_data(i).serial_control = 'Y' THEN
		          lt_waca_child_data(i).Serial_Number := get_serial_number(lt_waca_child_data(i).line_id,j);
                      ELSE 
			  lt_waca_child_data(i).Serial_Number := NULL;
		      END IF;			   	
		      -- Write lines data to the file multiple times matching with line quantity
		      WRITE_DATA_TO_FILE ( 
			                  lt_waca_child_data(i)
					 ,lc_write_status   
					  );
		   END LOOP;					     
		END LOOP;                    

	    END IF; --Hold exists
         ELSE  -- Stand alone Warrantly only Items 
	    ln_parent_rec_id := waca_main_rec_type.line_id ;
            lc_waca_type := 'WO' ;
            GET_WACA_DATA  ( 
			    'WO'   
		            ,ln_parent_rec_id      
			    ,lr_waca_parent 
		           );  
	     IF lr_waca_parent.status = 'S' THEN			
	        -- Write Header data to the file
	        WRITE_DATA_TO_FILE ( 
			            lr_waca_parent
			           ,lc_write_status
			           );
		IF lc_write_status = 'S' THEN
		   FND_FILE.PUT_LINE ( FND_FILE.LOG ,'Stand alone Warranty line - Line id :'||ln_parent_rec_id 
				     || ' has been written to the file ');   	 
		   -- Update the Warranty line as processed.   
		   UPDATE_LINE ( 
				 ln_parent_rec_id
				,lc_update_status
				,'P'
			       );
		   -- check if the update line is successful
	           IF lc_update_status <> 'S' THEN
		       -- write to error table stating the line table update has failed.
		       FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0008_WACA_LINE_UPD_FAIL');
		       lc_error_message := FND_MESSAGE.GET;                  
		       gc_err_code      := 'XX_OM_0008_WACA_LINE_UPD_FAIL';
		       gc_err_desc      :=  SUBSTR(lc_error_message,1,1000) ;
		       gc_entity_ref    := 'line_id';
		       gn_entity_ref_id :=NVL(gc_line_id,0);
		       err_report_type    :=
			      XXOM.XX_OM_REPORT_EXCEPTION_T (
							     gc_exception_header
							    ,gc_exception_track
							    ,gc_exception_sol_dom
							    ,gc_error_function
							    ,gc_err_code
							    ,gc_err_desc
							    ,gc_entity_ref
							    ,gn_entity_ref_id
							    );
						       
		       XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
								     err_report_type
								    ,lc_errbuff
								    ,lc_retcode
								    );
	           END IF; -- update status
	        ELSE                    
	           -- Update the Warranty line as Errored. 
	           UPDATE_LINE ( 
			        ln_parent_rec_id
			       ,lc_update_status
			       ,'E'
			       );
		END IF; -- write status
             ELSE
	        FND_FILE.PUT_LINE ( FND_FILE.LOG ,'Stand alone Warranty line - Line id :'||ln_parent_rec_id 
					    || ' has errored since one of the mandatory fields has failed ');
	     END IF;  -- extract status
          END IF; --warranty items
      END IF; -- warranty type
			    

      EXCEPTION
      WHEN EX_INCOMPLETE_BUNDLE THEN		
      FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_WACA_INCOMPLETE_WAR');
      lc_error_message := FND_MESSAGE.GET;
      gc_err_code      := 'XX_OM_0002_WACA_INCOMPLETE_WAR';
      gc_err_desc      :=  SUBSTR(lc_error_message,1,1000) ;
      gc_entity_ref    := 'line_id';
      gn_entity_ref_id :=NVL(gc_line_id,0);
      err_report_type    :=
      XXOM.XX_OM_REPORT_EXCEPTION_T (
				     gc_exception_header
				    ,gc_exception_track
				    ,gc_exception_sol_dom
				    ,gc_error_function
				    ,gc_err_code
				    ,gc_err_desc
				    ,gc_entity_ref
				    ,gn_entity_ref_id
				    );
	     
      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
						   err_report_type
						  ,lc_errbuff
						  ,lc_retcode
						  );
      END ;
		    
   END LOOP;

   FND_FILE.PUT_LINE (FND_FILE.LOG ,' ');  
   FND_FILE.PUT_LINE (FND_FILE.LOG ,'------------------------------------------------------------------------');

   IF UTL_FILE.IS_OPEN(gf_utl_file_handle) THEN
      -- close the utl_file
      UTL_FILE.FCLOSE(gf_utl_file_handle);
      FND_FILE.PUT_LINE (FND_FILE.LOG ,' WACA file '|| p_file_name ||' has successfully been generated in '||p_file_location);

      -- updating profile value so that , file transfer program shall pick up this file for transfer
      FOR waca_profile_rec_type IN lcu_waca_profile
      LOOP
         FND_PROFILE_OPTION_VALUES_PKG.UPDATE_ROW(
                                        x_application_id              => waca_profile_rec_type.application_id
                                       , x_profile_option_id          => waca_profile_rec_type.profile_option_id
                                        ,x_level_id                   => waca_profile_rec_type.level_id
                                        ,x_level_value                => waca_profile_rec_type.level_value
                                        ,x_level_value_application_id => waca_profile_rec_type.level_value_application_id
                                        ,x_level_value2               => waca_profile_rec_type.level_value2 
                                        ,x_profile_option_value       => p_file_name
                                        ,x_last_update_date           => SYSDATE
                                        ,x_last_updated_by            => gc_user_id
                                        ,x_last_update_login          => gc_user_id
                                       );
      END LOOP; 
      COMMIT;
   ELSE   
       
      FND_FILE.PUT_LINE (FND_FILE.LOG ,'No records satisfy the required conditions and file has not been created');      
   END IF;

   FND_FILE.PUT_LINE (FND_FILE.LOG ,'------------------------------------------------------------------------');
 
  
   COMMIT;

EXCEPTION
WHEN UTL_FILE.INVALID_PATH THEN
   UTL_FILE.FCLOSE(gf_utl_file_handle);
   FND_FILE.PUT_LINE (FND_FILE.LOG ,'Invalid File Path ');
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0003_WACA_UTL_ERROR');
   lc_error_message := FND_MESSAGE.GET;
   gc_err_code      := 'XX_OM_0003_WACA_UTL_ERROR';
   gc_err_desc      :=  SUBSTR(lc_error_message,1,1000) ;
   gc_entity_ref    := 'line_id';
   gn_entity_ref_id := NVL(gc_line_id,0);
   err_report_type    :=
   XXOM.XX_OM_REPORT_EXCEPTION_T ( 
				   gc_exception_header
				  ,gc_exception_track
				  ,gc_exception_sol_dom
				  ,gc_error_function
				  ,gc_err_code
				  ,gc_err_desc
				  ,gc_entity_ref
				  ,gn_entity_ref_id
				 );
			    
   XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
						err_report_type
					       ,lc_errbuff
					       ,lc_retcode
						);
WHEN UTL_FILE.INVALID_MODE THEN
   UTL_FILE.FCLOSE(gf_utl_file_handle); 
   FND_FILE.PUT_LINE (FND_FILE.LOG ,'Invalid Mode ');
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0003_WACA_UTL_ERROR');
   lc_error_message := FND_MESSAGE.GET;
   gc_err_code      := 'XX_OM_0003_WACA_UTL_ERROR';
   gc_err_desc      :=  SUBSTR(lc_error_message,1,1000) ;
   gc_entity_ref    := 'line_id';
   gn_entity_ref_id := NVL(gc_line_id,0);
   err_report_type    :=
   XXOM.XX_OM_REPORT_EXCEPTION_T ( 
				   gc_exception_header
				  ,gc_exception_track
				  ,gc_exception_sol_dom
				  ,gc_error_function
				  ,gc_err_code
				  ,gc_err_desc
				  ,gc_entity_ref
				  ,gn_entity_ref_id
				 );
			    
   XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
						err_report_type
					       ,lc_errbuff
					       ,lc_retcode
						);
WHEN UTL_FILE.INVALID_OPERATION THEN
   UTL_FILE.FCLOSE(gf_utl_file_handle);
   FND_FILE.PUT_LINE (FND_FILE.LOG ,'Invalid Operation ');
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0003_WACA_UTL_ERROR');
   lc_error_message := FND_MESSAGE.GET;
   gc_err_code      := 'XX_OM_0003_WACA_UTL_ERROR';
   gc_err_desc      :=  SUBSTR(lc_error_message,1,1000) ;
   gc_entity_ref    := 'line_id';
   gn_entity_ref_id := NVL(gc_line_id,0);
   err_report_type    :=
   XXOM.XX_OM_REPORT_EXCEPTION_T ( 
				   gc_exception_header
				  ,gc_exception_track
				  ,gc_exception_sol_dom
				  ,gc_error_function
				  ,gc_err_code
				  ,gc_err_desc
				  ,gc_entity_ref
				  ,gn_entity_ref_id
				 );
			    
   XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
						err_report_type
					       ,lc_errbuff
					       ,lc_retcode
						);
WHEN UTL_FILE.WRITE_ERROR THEN
   UTL_FILE.FCLOSE(gf_utl_file_handle);
   FND_FILE.PUT_LINE (FND_FILE.LOG ,'Write While calling Utl Package');
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0003_WACA_UTL_ERROR');
   lc_error_message := FND_MESSAGE.GET;
   gc_err_code      := 'XX_OM_0003_WACA_UTL_ERROR';
   gc_err_desc      :=  SUBSTR(lc_error_message,1,1000) ;
   gc_entity_ref    := 'line_id';
   gn_entity_ref_id := NVL(gc_line_id,0);
   err_report_type    :=
   XXOM.XX_OM_REPORT_EXCEPTION_T ( 
				   gc_exception_header
				  ,gc_exception_track
				  ,gc_exception_sol_dom
				  ,gc_error_function
				  ,gc_err_code
				  ,gc_err_desc
				  ,gc_entity_ref
				  ,gn_entity_ref_id
				 );
			    
   XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
						err_report_type
					       ,lc_errbuff
					       ,lc_retcode
						);
WHEN OTHERS THEN
   UTL_FILE.FCLOSE(gf_utl_file_handle);
   -- Calling the exception framework
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0001_WACA_UNKNOWN_ERROR');
   lc_error_message := FND_MESSAGE.GET;
   lc_sqlcode       := SQLCODE;
   lc_sqlerrm       := SUBSTR( SQLERRM,1,1000);
   gc_err_code      := 'XX_OM_0001_WACA_UNKNOWN_ERROR';
   gc_err_desc      :=  SUBSTR(lc_error_message||'Error while processing WACA Lines  '||lc_sqlerrm,1,1000);
   FND_FILE.PUT_LINE (FND_FILE.LOG ,gc_err_desc );
   gc_entity_ref    := 'line_id';
   gn_entity_ref_id := NVL(gc_line_id,0);
   err_report_type    :=
   XXOM.XX_OM_REPORT_EXCEPTION_T ( 
				   gc_exception_header
				  ,gc_exception_track
				  ,gc_exception_sol_dom
				  ,gc_error_function
				  ,gc_err_code
				  ,gc_err_desc
				  ,gc_entity_ref
				  ,gn_entity_ref_id
				 );
			    
   XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
						err_report_type
					       ,lc_errbuff
					       ,lc_retcode
						);
                        
END EXTRACT_WACA_LINES;
	  
END XX_OM_WACA_FEED_PKG;
/
SHO ERR