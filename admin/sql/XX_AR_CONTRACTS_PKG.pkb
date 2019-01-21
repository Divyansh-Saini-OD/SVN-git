CREATE OR REPLACE PACKAGE BODY XX_AR_CONTRACTS_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_AR_CONTRACTS_PKG                                                     |
  -- |                                                                                            |
  -- |  Description:  This package is to export Payment information to SAS                        |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author                Remarks                                     |
  -- | =========   ===========  ================      ==========================================  |
  -- | 1.0         16-JAN-2018  Jaishankar Kumar      Initial version                             |
  -- +============================================================================================+
  
PROCEDURE import_contracts ( errbuff      OUT VARCHAR2
                           , retcode      OUT VARCHAR2
						   , p_contract_file_name_in  IN VARCHAR2
                           )
is
--------------------------------------------------
-- Cursor Declaration
--------------------------------------------------
CURSOR cur_contracts_header (p_program_id_in NUMBER)
IS
   SELECT xac.*
     FROM xx_ar_contracts_gtt xac
    WHERE xac.program_id = p_program_id_in
      AND xac.contract_line_number = 1;
	  	  
CURSOR cur_contract_line ( p_contract_in      NUMBER
                         , p_program_id_in    NUMBER
						 )
IS
    SELECT xac.*
      FROM xx_ar_contracts_gtt xac
     WHERE xac.program_id = p_program_id_in
	   AND xac.contract_id = p_contract_in;
	   
-- Start variable declaration by JAI_CG
   l_retcode           NUMBER    := 0;
   l_errbuf            VARCHAR2(5000) := NULL;   
   lv_appl_short_name_in       VARCHAR2(10)  := 'XXFIN';
   lv_program_in               VARCHAR2(100) := 'XX_AR_CONTRACTS_PRG';
   lv_description_in           VARCHAR2(100) := 'OD: AR Contracts Loader Program';
   lv_file_loc                 VARCHAR2(240) := '$XXFIN_DATA/inbound';
   lv_control_file             VARCHAR2(240) := 'XX_AR_CONTRACTS_CTL.ctl';
   lv_request_id_num           NUMBER;
   lv_request_complete_bln     BOOLEAN;
   lv_phase_txt                VARCHAR2(20);
   lv_status_txt               VARCHAR2(20);
   lv_dev_phase_txt            VARCHAR2(20);
   lv_dev_status_txt           VARCHAR2(20);
   lv_message_txt              VARCHAR2 (200);
   ln_header_count             NUMBER := 0;
   ln_line_count               NUMBER := 0;
   ln_record_count             NUMBER := 0;
   ln_contract_amount          NUMBER := 0;
   
-- End variable declaration by JAI_CG

BEGIN
   FND_FILE.PUT_LINE(FND_FILE.LOG, '***************************************');   -- Added by JAI_CG
   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Starting import_contracts routine for data file: '||p_contract_file_name_in);        
   FND_FILE.PUT_LINE(FND_FILE.LOG, '***************************************');
-- Start fetching Data file detail by JAI_CG
   BEGIN       
         lv_request_id_num := apps.fnd_request.submit_request(application     => lv_appl_short_name_in
                                                             ,program      => lv_program_in
                                                             ,description  => lv_description_in
                                                             ,start_time   => TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')
                                                             ,sub_request  => FALSE
                                                             ,argument1    => lv_file_loc
                                                             ,argument2    => p_contract_file_name_in
                                                             ,argument3    => lv_control_file
                                                             );
	 COMMIT;
	    
	 IF lv_request_id_num = 0 THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, '************************************************'); 
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Conc. Program  failed to submit :' || lv_description_in); 
            FND_FILE.PUT_LINE(FND_FILE.LOG, '************************************************'); 
	       
            retcode := 2;
         ELSE
            FND_FILE.PUT_LINE(FND_FILE.LOG, '************************************************'); 
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Program is successfully Submitted , Request Id :' || lv_request_id_num); 
            FND_FILE.PUT_LINE(FND_FILE.LOG, '************************************************'); 
            
            lv_request_complete_bln := apps.fnd_concurrent.wait_for_request(request_id => lv_request_id_num
                                                                              ,phase      => lv_phase_txt
                                                                              ,status     => lv_status_txt
                                                                              ,dev_phase  => lv_dev_phase_txt
                                                                              ,dev_status => lv_dev_status_txt
                                                                              ,message    => lv_message_txt
                                                                              );
         
            IF UPPER(lv_dev_status_txt) = 'NORMAL' AND UPPER(lv_dev_phase_txt) = 'COMPLETE' THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG, 'OD: AR Subscriptions Payment Import successful for the Request Id: '
                                              ||lv_request_id_num||'. '); 
               UPDATE xx_ar_contracts_gtt
                  SET program_id = lv_request_id_num
				     ,CREATION_DATE = SYSDATE
					 ,LAST_UPDATE_DATE = SYSDATE
					 ,CREATED_BY = FND_GLOBAL.USER_ID
					 ,LAST_UPDATED_BY = FND_GLOBAL.USER_ID
					 ,LAST_UPDATE_LOGIN = FND_GLOBAL.LOGIN_ID
                WHERE program_id IS NULL;
				  
				COMMIT;  

               FND_FILE.PUT_LINE(FND_FILE.LOG, 'Staging table has been updated with request_id. '||lv_request_id_num);
            ELSE
               FND_FILE.PUT_LINE(FND_FILE.LOG, 'SQL Loader Program does not completed normally. ');
               retcode := 2;
            END IF;
         END IF;

      EXCEPTION WHEN OTHERS THEN
	     errbuff := 'Exception In Submit Conc. Program :' || '-' || SQLERRM;
         FND_FILE.PUT_LINE(FND_FILE.LOG, '**********************************************');
         FND_FILE.PUT_LINE(FND_FILE.LOG, errbuff);
         FND_FILE.PUT_LINE(FND_FILE.LOG, '**********************************************');
         retcode := 2; -- Terminate the program                                                             
      END;
	  
 -- End submitting Data Loader by JAI_CG 
      BEGIN
	  -- Start populating contract tables
         FOR rec_contracts_header IN cur_contracts_header (lv_request_id_num) LOOP
		 BEGIN
		    SELECT SUM(xac.total_amount) 
			  INTO ln_contract_amount
			  FROM xxfin.xx_ar_contracts_gtt xac 
			 WHERE program_id = lv_request_id_num
			   AND contract_id = rec_contracts_header.contract_id;
		 
            -- Updating header record is it exists in the table
			UPDATE xxfin.xx_ar_contracts
			   SET contract_id = rec_contracts_header.contract_id
                 , contract_number = rec_contracts_header.contract_number         
                 , contract_name = rec_contracts_header.contract_name 
                 , contract_status = rec_contracts_header.contract_status     
                 , contract_major_version = rec_contracts_header.contract_major_version 
                 , contract_start_date = rec_contracts_header.contract_start_date     
                 , contract_end_date = rec_contracts_header.contract_end_date       
                 , contract_billing_freq = rec_contracts_header.contract_billing_freq   
                 , bill_to_cust_account_number = rec_contracts_header.bill_cust_account_number
                 , bill_to_customer_name = rec_contracts_header.bill_cust_name         
                 , bill_to_osr = rec_contracts_header.bill_to_osr 
                 , customer_email = rec_contracts_header.customer_email 				 
                 , initial_order_number = rec_contracts_header.initial_order_number   
                 , store_number = rec_contracts_header.store_number           
                 , payment_type = rec_contracts_header.payment_type           
                 --, payment_identifier = rec_contracts_header.payment_identifier     
                 , card_type = rec_contracts_header.card_type       
                 , card_tokenenized_flag = rec_contracts_header.card_tokenized_flag                
                 , card_token = rec_contracts_header.card_token    
                 , card_encryption_hash = rec_contracts_header.card_encryption_hash  
                 , card_holder_name = rec_contracts_header.card_holder_name             
                 , card_expiration_date = rec_contracts_header.card_expiration_date   
                 , card_encryption_label = rec_contracts_header.card_encryption_label  
                 , ref_associate_number = rec_contracts_header.ref_associate_number   
                 , sales_representative = rec_contracts_header.sales_representative  
                 , loyalty_member_number = rec_contracts_header.loyalty_member_number         
                 , total_contract_amount = ln_contract_amount  --rec_contracts_header.total_amount 
                 , payment_term = rec_contracts_header.payment_term  
                 , last_update_date = rec_contracts_header.last_update_date 
                 , last_updated_by = rec_contracts_header.last_updated_by  
                 , last_update_login = rec_contracts_header.last_update_login
                 , program_id = rec_contracts_header.program_id
			 WHERE contract_id = rec_contracts_header.contract_id
               AND contract_number = rec_contracts_header.contract_number
			   --AND contract_billing_freq = rec_contracts_header.contract_billing_freq
			   ;
			   
			IF ( SQL%rowcount <> 0 ) THEN
			   FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_AR_CONTRACTS got updated for contract number: '||rec_contracts_header.contract_number);
			ELSE
			   INSERT INTO xx_ar_contracts
                      ( contract_id
                      , contract_number         
                      , contract_name 
                      , contract_status     
                      , contract_major_version 
                      , contract_start_date     
                      , contract_end_date       
                      , contract_billing_freq   
                      , bill_to_cust_account_number
                      , bill_to_customer_name         
                      , bill_to_osr 
                      , customer_email					  
                      , initial_order_number     
                      , store_number           
                      , payment_type           
                      --, payment_identifier     
                      , card_type       
                      , card_tokenenized_flag                
                      , card_token    
                      , card_encryption_hash  
                      , card_holder_name             
                      , card_expiration_date   
                      , card_encryption_label  
                      , ref_associate_number   
                      , sales_representative  
                      , loyalty_member_number         
                      , total_contract_amount
                      , payment_term    
                      , creation_date    
                      , last_update_date 
                      , created_by       
                      , last_updated_by  
                      , last_update_login
                      , program_id
					  )			   
		       VALUES ( rec_contracts_header.contract_id
                      , rec_contracts_header.contract_number         
                      , rec_contracts_header.contract_name 
                      , rec_contracts_header.contract_status     
                      , rec_contracts_header.contract_major_version 
                      , rec_contracts_header.contract_start_date     
                      , rec_contracts_header.contract_end_date       
                      , rec_contracts_header.contract_billing_freq   
                      , rec_contracts_header.bill_cust_account_number
                      , rec_contracts_header.bill_cust_name         
                      , rec_contracts_header.bill_to_osr 
                      , rec_contracts_header.customer_email					  
                      , rec_contracts_header.initial_order_number     
                      , rec_contracts_header.store_number           
                      , rec_contracts_header.payment_type 
                      , rec_contracts_header.card_type       
                      , rec_contracts_header.card_tokenized_flag                
                      , rec_contracts_header.card_token    
                      , rec_contracts_header.card_encryption_hash  
                      , rec_contracts_header.card_holder_name             
                      , rec_contracts_header.card_expiration_date   
                      , rec_contracts_header.card_encryption_label  
                      , rec_contracts_header.ref_associate_number   
                      , rec_contracts_header.sales_representative  
                      , rec_contracts_header.loyalty_member_number         
                      , ln_contract_amount  --rec_contracts_header.total_amount 
                      , rec_contracts_header.payment_term    
                      , rec_contracts_header.creation_date    
                      , rec_contracts_header.last_update_date 
                      , rec_contracts_header.created_by       
                      , rec_contracts_header.last_updated_by  
                      , rec_contracts_header.last_update_login
                      , rec_contracts_header.program_id
		              );
		    END IF;	  
			ln_header_count := ln_header_count + 1;
				   
            FOR rec_contract_line IN cur_contract_line ( rec_contracts_header.contract_id
													   , rec_contracts_header.program_id) LOOP
	        BEGIN
			   -- Updating line records if exists
			   UPDATE xx_ar_contract_lines
			      SET contract_id = rec_contract_line.contract_id                
                    , contract_line_number = rec_contract_line.contract_line_number   
                    , initial_order_line = rec_contract_line.initial_order_line	
                    , item_name = rec_contract_line.item_name              
                    , item_description = rec_contract_line.item_description       
                    , quantity = rec_contract_line.quantity                 
                    , contract_line_start_date = rec_contract_line.contract_line_start_date  
                    , contract_line_end_date = rec_contract_line.contract_line_end_date    
                    , contract_line_billing_freq = rec_contract_line.contract_line_billing_freq    
                    , payment_term = rec_contract_line.payment_term     
                    , uom_code = rec_contract_line.uom_code                  				  
                    , contract_line_amount = rec_contract_line.total_amount
                    , program  = rec_contract_line.program
                    , cancellation_date  = rec_contract_line.cancellation_date
                    , last_update_date = rec_contract_line.last_update_date 
                    , last_updated_by = rec_contract_line.last_updated_by  
                    , last_update_login = rec_contract_line.last_update_login
                    , program_id = rec_contract_line.program_id
		        WHERE contract_id = rec_contract_line.contract_id	
                  AND contract_line_number = rec_contract_line.contract_line_number 	
                  AND contract_line_billing_freq = rec_contract_line.contract_line_billing_freq 
				  ;
			   
			IF ( SQL%rowcount <> 0 ) THEN
			   FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_AR_CONTRACT_LINES got updated for contract id: '||rec_contract_line.contract_id
			                                 ||' and line number: '||rec_contract_line.contract_line_number);
			ELSE
               INSERT INTO xx_ar_contract_lines 
			          ( contract_id                
                      , contract_line_number   
                      , initial_order_line	
                      , item_name              
                      , item_description       
                      , quantity                 
                      , contract_line_start_date  
                      , contract_line_end_date    
                      , contract_line_billing_freq    
                      , payment_term     
                      , uom_code                  				  
                      , contract_line_amount
                      , program
                      , cancellation_date              
                      , creation_date    
                      , last_update_date 
                      , created_by       
                      , last_updated_by  
                      , last_update_login
                      , program_id      
					  )
		   	   VALUES ( rec_contract_line.contract_id                
                      , rec_contract_line.contract_line_number   
                      , rec_contract_line.initial_order_line	
                      , rec_contract_line.item_name              
                      , rec_contract_line.item_description       
                      , rec_contract_line.quantity                 
                      , rec_contract_line.contract_line_start_date  
                      , rec_contract_line.contract_line_end_date    
                      , rec_contract_line.contract_line_billing_freq    
                      , rec_contract_line.payment_term     
                      , rec_contract_line.uom_code                  				  
                      , rec_contract_line.total_amount
                      , rec_contract_line.program
                      , rec_contract_line.cancellation_date              
                      , rec_contract_line.creation_date    
                      , rec_contract_line.last_update_date 
                      , rec_contract_line.created_by       
                      , rec_contract_line.last_updated_by  
                      , rec_contract_line.last_update_login
                      , rec_contract_line.program_id      
				      );
			END IF;		  
			
			ln_line_count  := ln_line_count  + 1;
		    EXCEPTION
		       WHEN OTHERS THEN
			      errbuff := 'Exception raised while populating xx_ar_contract_lines for contract Id: '
				                                 ||rec_contracts_header.contract_id||' and line: '
												 ||rec_contract_line.contract_line_number
												 ||' - '||SQLERRM;
			      FND_FILE.PUT_LINE(FND_FILE.LOG, errbuff);
				  EXIT;
		    END;	
         END LOOP;
		 EXCEPTION
		    WHEN OTHERS THEN
			   errbuff := 'Exception raised while populating XX_AR_CONTRACTS for contract Id: '
			                                  ||rec_contracts_header.contract_id
											  ||' - '||SQLERRM;
			   FND_FILE.PUT_LINE(FND_FILE.LOG, errbuff);
				  EXIT;
		 END;	
      END LOOP;
	  
	  IF NVL(ln_header_count, 0) = 0 THEN
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'No valid records are imported for processing. ');
	  ELSE	 
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'Count of records populated on xx_ar_contracts is: '||ln_header_count);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Count of records populated on xx_ar_contract_lines is: '||ln_line_count);
	  END IF; 
   EXCEPTION	  
      WHEN OTHERS THEN
	     errbuff := 'Unhandled exception raised while inserting records in Contracts table: '||SQLERRM;
	     FND_FILE.PUT_LINE(FND_FILE.LOG, errbuff);
   END; 
   -- Start truncating table
   BEGIN
      SELECT COUNT(*)
	    INTO ln_record_count
	    FROM xx_ar_contracts_gtt
	   WHERE program_id = lv_request_id_num;

      IF ln_record_count =	ln_line_count THEN
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'All records are inserted in Contracts table and hence truncating XX_AR_CONTRACTS_GTT table. ');
		 EXECUTE IMMEDIATE 'TRUNCATE TABLE xxfin.xx_ar_contracts_gtt';
	  ELSE
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'All records are not inserted in Contracts table. ');
	  END IF;	 
   
   EXCEPTION
      WHEN OTHERS THEN
         errbuff :='Unhandled exception raised while checking if all records are inserted in contracts tables. '||SQLERRM;
	     FND_FILE.PUT_LINE(FND_FILE.LOG,errbuff);
	  
      END;	  
    
EXCEPTION
  WHEN OTHERS THEN
    errbuff :='Unexpected Error in XX_AR_CONTRACTS_PKG.import_contracts: '||DBMS_UTILITY.format_error_backtrace||SQLERRM;
    FND_FILE.PUT_LINE(FND_FILE.LOG, errbuff);
END import_contracts;
      
END XX_AR_CONTRACTS_PKG;
/
SHOW ERRORS;