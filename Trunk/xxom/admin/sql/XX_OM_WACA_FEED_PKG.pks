SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_WACA_FEED_PKG
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
   TYPE child_rec_type IS RECORD( child_line_id        VARCHAR2(100)
                                        );
   TYPE child_tbl_type IS TABLE OF child_rec_type 
   INDEX BY BINARY_INTEGER; 
   
   TYPE waca_rec_type IS RECORD (  
                                   Record_Code                 VARCHAR2(50)
                                  ,Batch_Number                VARCHAR2(50) 
                                  ,Order_Number                oe_order_headers_all.order_number%TYPE
                                  ,Warranty_Number             VARCHAR2(240) 
                                  ,Order_Source                VARCHAR2(240)  
                                  ,warranty_sku                mtl_system_items_b.segment1%TYPE 
                                  ,Warranty_Description        mtl_system_items_b.description%TYPE 
                                  ,Warranty_Application_Date   oe_order_lines_all.request_date%TYPE
                                  ,Quantity_Sold               oe_order_lines_all.ordered_quantity%TYPE
                                  ,Retail_Price                oe_order_lines_all.unit_selling_price%TYPE
                                  ,store_id                    oe_order_lines_all.ship_from_org_id%TYPE
                                  ,salesman_id                 oe_order_headers_all.salesrep_id%TYPE
                                  ,customer_number             hz_cust_accounts.account_number%TYPE
                                  ,Contact_First_Name          hz_parties.person_first_name%TYPE
                                  ,Contact_Last_Name           hz_parties.person_last_name%TYPE
                                  ,Company_Name                hz_parties.party_name%TYPE
                                  ,Ship_to_Addr1               hz_locations.address1%TYPE
                                  ,Ship_to_Addr2               hz_locations.address2%TYPE
                                  ,Ship_to_City                hz_locations.city%TYPE
                                  ,Ship_to_State               hz_locations.state%TYPE
                                  ,Ship_to_Zip                 hz_locations.postal_code%TYPE
                                  ,Ship_to_Country             hz_locations.country%TYPE
                                  ,Currency                    oe_order_headers_all.transactional_curr_code%TYPE
                                  ,Phone                       VARCHAR2(240)
                                  ,Fax_Number                  VARCHAR2(240)
                                  ,Office_or_Mobile_no         VARCHAR2(240) 
                                  ,Email                       hz_contact_points.email_address%TYPE
                                  ,Sales_Type                  VARCHAR2(10)
                                  ,Return_order_Number         VARCHAR2(240)
                                  ,Return_Date                 oe_order_headers_all.request_date%TYPE
                                  ,Order_Line_no               oe_order_lines_all.line_id%TYPE
                                  ,Machine_SKU                 mtl_system_items_b.segment1%TYPE
                                  ,Machine_SKU_Price           oe_order_lines_all.unit_selling_price%TYPE
                                  ,Serial_Number               mtl_serial_numbers.serial_number%TYPE 
                                  ,Product_Description         mtl_system_items_b.description%TYPE
				  ,ordered_quantity            oe_order_lines_all.ordered_quantity%TYPE
				  ,status                      VARCHAR2(10)
				  ,line_id                     oe_order_lines_all.line_id%TYPE
				  ,serial_control              VARCHAR2(1)
                                   );
    TYPE waca_tbl_type IS TABLE OF waca_rec_type INDEX BY BINARY_INTEGER; 

    TYPE waca_head_rec_type IS RECORD (  
                                   Order_Number          oe_order_headers_all.order_number%TYPE
                                  ,Warranty_Number             VARCHAR2(240) 
                                  ,Order_Source                VARCHAR2(240)  
                                  ,Warranty_SKU                mtl_system_items_b.segment1%TYPE 
                                  ,Warranty_Description        mtl_system_items_b.description%TYPE 
                                  ,Warranty_Application_Date   oe_order_lines_all.request_date%TYPE
                                  ,Quantity_Sold               oe_order_lines_all.ordered_quantity%TYPE
                                  ,Retail_Price                oe_order_lines_all.unit_selling_price%TYPE
				  ,store_id                    oe_order_lines_all.ship_from_org_id%TYPE
                                  ,salesman_id                 oe_order_headers_all.salesrep_id%TYPE
                                  ,Customer_Number             hz_cust_accounts.account_number%TYPE 
                                  ,Company_Name                hz_parties.party_name%TYPE
                                  ,Ship_to_Addr1               hz_locations.address1%TYPE
                                  ,Ship_to_Addr2               hz_locations.address2%TYPE
                                  ,Ship_to_City                hz_locations.city%TYPE
                                  ,Ship_to_State               hz_locations.state%TYPE
                                  ,Ship_to_Zip                 hz_locations.postal_code%TYPE
                                  ,Ship_to_Country             hz_locations.country%TYPE
                                  ,Currency                    oe_order_headers_all.transactional_curr_code%TYPE
				  ,customer_class_meaning      VARCHAR2(240)
				  ,customer_type_meaning       VARCHAR2(240)
				  ,cust_account_id		NUMBER
				  ,Return_Date                 oe_order_lines_all.request_date%TYPE
				  ,serial_control              mtl_system_items_b.serial_number_control_code%TYPE
                                   );
				
  
   gc_waca_supplier       VARCHAR2(30) ;
   gc_order_category      VARCHAR2(20) := 'RETURN' ;
   gc_pos_source          VARCHAR2(30) ;
   gc_phone               VARCHAR2(20) := 'Telephone' ;
   gc_fax                 VARCHAR2(20) := 'Fax' ;
   gc_email               VARCHAR2(20) := 'E-mail' ;
   gc_mobile              VARCHAR2(20) := 'Mobile' ;
   gc_utl_file_path       VARCHAR2(100);
   gc_utl_file_name       VARCHAR2(100);
   gf_utl_file_handle     UTL_FILE.FILE_TYPE;
   gc_src_lookup_typ      FND_LOOKUP_VALUES.lookup_type%TYPE DEFAULT 'XX_OM_WACA_NON_POS_SRC_TYPES';
   gc_err_code            VARCHAR2(100);
   gc_err_desc            VARCHAR2(1000);
   gc_entity_ref          VARCHAR2(100);
   gn_entity_ref_id       VARCHAR2(100);
   err_report_type         xxom.xx_om_report_exception_t;
   gc_exception_header     VARCHAR2(100) := 'OTHERS';
   gc_exception_track      VARCHAR2(100) := 'OTC';
   gc_exception_sol_dom    VARCHAR2(100) := 'Order Management';
   gc_error_function       VARCHAR2(100) := 'I0428-WACA Interface';
   gc_line_id              oe_order_lines_all.line_id%TYPE ;
   gc_status               VARCHAR2(20) := 'P';
   gc_store                VARCHAR2(20) ;
   gc_cust_type            VARCHAR2(20) := 'Internal' ;
   gc_stat_cancel          VARCHAR2(20) := 'CANCELLED' ;
   gc_stat_entered         VARCHAR2(20) := 'ENTERED' ;
   gc_waca_hold            VARCHAR2(30) ;
   gc_waca_profile         VARCHAR2(30) := 'XX_OM_WACA_FILE_NAME' ;
   gc_user_id              NUMBER       := FND_PROFILE.VALUE('USER_ID');



   TYPE orderdetail_rec_type IS RECORD( 
                                        parent_line_id        VARCHAR2(100)
					);
   TYPE orderdetail_tbl_type IS TABLE OF orderdetail_rec_type
   INDEX BY BINARY_INTEGER;  

   TYPE line_rec_type IS RECORD( 
                                line_id        VARCHAR2(100)
				);
   TYPE line_tbl_type IS TABLE OF line_rec_type INDEX BY BINARY_INTEGER;

 
   
PROCEDURE GET_WACA_DATA         ( 
                                  p_waca_type    IN          VARCHAR2
			         ,p_line_id      IN          oe_order_lines_all.line_id%TYPE
				 ,x_waca_data    OUT NOCOPY  waca_rec_type
			        );
	-- +=======================================================================================================+
	-- | Name  : get_waca_data                                                                                  |
	-- | Description : This procedure gets the required data thet needs to be sent to WACA.                     |                                   
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

PROCEDURE WRITE_DATA_TO_FILE ( 
                               p_waca_data    IN      waca_rec_type
	                      ,x_status       OUT     VARCHAR2
			     );
	        -- +==========================================================================+
                -- | Name  : write_data_to_file                                               |
                -- | Description : Procedure  to write the extracted data in                  |
	        -- |               the given file path                                        |            
                -- | Parameters :                                                             |
                -- |           p_waca_data    -- Warranty Data                                |
                -- |           x_status       -- Status                                       |	
	        -- |                                                                          |
                -- +==========================================================================+


PROCEDURE UPDATE_LINE (
                        p_line_id     IN   oe_order_lines_all.line_id%TYPE 
		       ,x_status      OUT  VARCHAR2
		       ,p_status_code IN   VARCHAR2
		       );

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
FUNCTION GET_SERIAL_NUMBER (
                             p_line_id        IN  oe_order_lines_all.line_id%TYPE
                            ,p_order_of_item  IN  NUMBER
		            ) RETURN  VARCHAR2 ;
                -- +==========================================================================+
                -- | Name  : get_serial_number                                                |
                -- | Description : Function to get the serial number given the line id        |
	        -- |                                                                          |            
                -- | Parameters :                                                             |
                -- |           p_line_id      -- Line id                                      |
                -- |           p_order_of_item -- Order of the Item                           |
		-- |                           Ex:- if the  value 2 is passed, 2nd            |
		-- |			       serial number in the series will be fetched    |    
	        -- |          RETURNS  -- serial_number                                       |
                -- |                                                                          |
                -- +==========================================================================+

PROCEDURE EXTRACT_WACA_LINES ( 
                              x_errbuff          OUT      VARCHAR2
                             ,x_retcode		 OUT      NUMBER                                                                                                       
                             ,p_file_name        IN       VARCHAR2
		             ,p_file_location    IN       VARCHAR2
			     ,p_waca_supplier    IN       VARCHAR2
			     ,p_pos_source       IN       VARCHAR2
			     ,p_store_type       IN       VARCHAR2
			     ,p_hold_name        IN       VARCHAR2
		             );

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
  
  
END XX_OM_WACA_FEED_PKG;
/
SHO ERR