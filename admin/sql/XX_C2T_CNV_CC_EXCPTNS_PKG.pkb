create or replace PACKAGE BODY  XX_C2T_CNV_CC_EXCPTNS_PKG
AS
-- +=====================================================================================================+
-- |                              Office Depot                                                           |
-- +=====================================================================================================+
-- |  Name:  XX_C2T_CNV_CC_EXCPTNS_OM_PKG                                                                |
-- |                                                                                                     |
-- |  Description: Pre-Processing Credit Cards for OE Payments, Deposits, Returns, IBY History and ORDT  |
-- |                                                                                                     |
-- |  Rice ID:     C0705                                                                                 |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- | =========   ===========  =============        ======================================================|
-- |    1.0      02-FEB-2016  Havish Kasina        Initial Version for Payments,Deposits,Returns,ORDT and|
-- |                                               IBY History                                           |
-- |    1.1      05-FEB-2016  Harvinder Rakhra     Added Primary key columns to OUT file in ORDT and IBY |
-- |                                               Pkgs                                                  |
-- |    1.2      05-FEB-2016  Havish Kasina        Added Primary key columns to log file in OE Payments, |
-- |                                               Deposits and Returns Procedures                       |
-- |    1.3      08-FEB-2016  Harvinder Rakhra     Added Log for First six and last 4 digit of CC #      |
-- |    1.4      17-FEB-2016  Harvinder Rakhra     Added logic to discard credit card with Junk Characters|
-- |    1.5      03-Mar-2016  Avinash Baddam       Call ajb get token for exception records,check for disc
-- |						   records and special chars
-- |    1.6      07-Apr-2016  Avinash Baddam       Added check for citi bin ranges			 |
-- |    1.7      13-Dec-2016  Avinash Baddam       AMEX Conv Changes                                     |
-- |    1.8      16-MAR-2017  Avinash Baddam       Outstanding Cleanup Records (Post-Amex)               |
---+=====================================================================================================+
-- ================
-- Global Variables
-- ================
  gc_debug                   VARCHAR2(1)        := 'N';
  gc_error_loc               VARCHAR2(4000)     := NULL;
  gc_error_debug             VARCHAR2(4000);
  gn_user_id                 NUMBER             := FND_GLOBAL.USER_ID;
  gn_login_id                NUMBER             := FND_GLOBAL.LOGIN_ID;
  gc_source_path             VARCHAR2(100)      := 'XXFIN_OUTBOUND';
  gc_mode                    VARCHAR2 (1)       := 'W';
  gc_file_name               VARCHAR2(200); 
  gc_context                 VARCHAR2(30)       := 'XX_C2T_CNV_EXCEP_CONTEXT';
  gc_key_label               VARCHAR2(40)       := 'DES20151029A';
  gc_algorithm               VARCHAR2(10)       := '3DES';
  gc_format                  VARCHAR2(10)       := 'EBCDIC';
  
-- +===================================================================+
-- | PROCEDURE  : LOCATION_AND_LOG                                     |
-- |                                                                   |
-- | DESCRIPTION: Performs the following actions based on parameters   |
-- |              1. Sets gc_error_location                            |
-- |              2. Writes to log file if debug is on                 |
-- |                                                                   |
-- | PARAMETERS : p_debug, p_debug_msg                                 |
-- |                                                                   |
-- | RETURNS    : None                                                 |
-- +===================================================================+
PROCEDURE location_and_log (p_debug           IN  VARCHAR2,
                            p_debug_msg       IN  VARCHAR2
                            )
IS
BEGIN
    gc_error_loc := p_debug_msg;   -- set error location

    IF p_debug = 'Y' THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG, gc_error_loc);
    END IF;

END LOCATION_AND_LOG;

-- +===================================================================+
-- | PROCEDURE  : extract_pmts_exceptions                              |
-- |                                                                   |
-- | DESCRIPTION: Extract OE Payments Exception Records                |
-- |                                                                   |
-- | PARAMETERS : p_debug_flag                                         |
-- |                                                                   |
-- | RETURNS    : None                                                 |
-- +===================================================================+  
PROCEDURE extract_pmts_exceptions (  
                                        p_debug_flag               IN           VARCHAR2									
                                   )
IS   
    -- ==================
    -- Cursor Declaration
    -- ==================                               
    CURSOR cur_ext_payments
    IS
    SELECT /*+FULL(OE_PMT) PARALLEL(OE_PMT,32)*/
	       credit_card_number_new   
           ,key_label_new
           ,oe_payment_id		   
    FROM   xx_c2t_cc_token_stg_oe_pmt OE_PMT
    WHERE  1 = 1
      AND  re_encrypt_status = 'C'
      AND  convert_status = 'N'
    ;
	
	-- =======================
    -- Record Type Declaration
    -- =======================   
	   TYPE r_cc_excep_oe_pmt 
       IS
         RECORD ( credit_card_number_new        xx_c2t_cc_token_stg_oe_pmt.credit_card_number_new%TYPE,
                  key_label_new                 xx_c2t_cc_token_stg_oe_pmt.key_label_new%TYPE,
			      oe_payment_id                 xx_c2t_cc_token_stg_oe_pmt.oe_payment_id%TYPE);
	
    -- ======================
    -- Table Type Declaration
    -- ====================== 	
	   TYPE t_cc_excep_oe_pmt	
	   IS
	     TABLE OF r_cc_excep_oe_pmt INDEX BY BINARY_INTEGER;
    
    -- ================
    -- Local Variables
    -- ================
    l_cc_excep_oe_pmt           t_cc_excep_oe_pmt;
    lc_cc_decrypted             VARCHAR2(4000)  := NULL;
    lc_cc_decrypt_error         VARCHAR2(4000)  := NULL;
    lc_cc_encrypted_new         VARCHAR2(4000)  := NULL;
    lc_cc_encrypt_error         VARCHAR2(4000)  := NULL;
    lc_cc_key_label_new         VARCHAR2(4000)  := NULL;
	ln_err_count                NUMBER          := 0;
	ln_error_idx                NUMBER          := 0;
	lc_error_msg                VARCHAR2(4000);
    lc_error_action             VARCHAR2(2000);
    ln_total_records_processed  NUMBER          := 0;
    ln_success_records          NUMBER          := 0;
    ln_failed_records           NUMBER          := 0;
	
	lc_filehandle               UTL_FILE.file_type;
	lc_string                   VARCHAR2(1000);

BEGIN    
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Initialize the EXCEPTION PROGRAM for OE Payments'); 
     gc_file_name := 'xx_c2t_cnv_cc_exceptions_payments.txt'; 
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Payments File Name :'||gc_file_name); 
	 lc_filehandle := UTL_FILE.fopen (gc_source_path, gc_file_name, gc_mode);
	 
     OPEN cur_ext_payments;
     LOOP
      l_cc_excep_oe_pmt.DELETE; --- Deleting the data in the Table type 
		  FETCH cur_ext_payments BULK COLLECT
		  INTO l_cc_excep_oe_pmt;

     ln_total_records_processed := ln_total_records_processed + l_cc_excep_oe_pmt.COUNT;
    
       FOR i IN 1 .. l_cc_excep_oe_pmt.COUNT
       LOOP
		  BEGIN
            lc_cc_decrypted     := NULL;
            lc_cc_decrypt_error := NULL;
            lc_error_msg        := NULL;
            lc_cc_encrypted_new := NULL;
            lc_cc_encrypt_error := NULL;
            lc_cc_key_label_new := NULL;
            lc_error_action     := NULL;
            ln_err_count        := NULL;
            ln_error_idx        := NULL;
            lc_string	        := NULL;		
--            ========================================================================
            -- DECRYPTING the Credit Card Number
--            ========================================================================
            location_and_log(gc_debug,' ');
			location_and_log(gc_debug, 'OE Payment ID :'||l_cc_excep_oe_pmt (i).oe_payment_id);
            location_and_log(gc_debug, 'Decrypting CARD ID :'||l_cc_excep_oe_pmt (i).credit_card_number_new);
            DBMS_SESSION.SET_CONTEXT( namespace => gc_context
						            , attribute => 'TYPE'
						            , value     => 'EBS');
                        
            XX_OD_SECURITY_KEY_PKG.DECRYPT( p_module        => 'AJB' 
                                          , p_key_label     => l_cc_excep_oe_pmt (i).key_label_new
                                          , p_encrypted_val => l_cc_excep_oe_pmt (i).credit_card_number_new
                                          , p_algorithm     => gc_algorithm
                                          , x_decrypted_val => lc_cc_decrypted
                                          , x_error_message => lc_cc_decrypt_error);
										  
            lc_error_msg := SUBSTR(lc_cc_decrypt_error,1,4000);
            lc_error_action := 'DECRYPT';
			
            location_and_log(gc_debug, 'Decrypted Number: '||SUBSTR(lc_cc_decrypted,-4));
										  
            IF ( (lc_cc_decrypt_error IS NOT NULL) OR (lc_cc_decrypted IS NULL)) THEN --If decryption is Unsuccessful

                location_and_log(gc_debug,'Decrypting Error Message :'||lc_error_msg);
                
                ln_failed_records := ln_failed_records + 1;
				
            ELSE --If decryption is Successful
	            --========================================================================
	            -- ENCRYPTING/ Tokenizing the Credit Card Number again
	            --========================================================================
                DBMS_SESSION.SET_CONTEXT( namespace => gc_context
                                        , attribute => 'TYPE'
                                        , value     => 'OM');

                XX_OD_SECURITY_KEY_PKG.ENCRYPT_OUTLABEL( p_module        => 'HVOP' 
                                                       , p_key_label     => gc_key_label
                                                       , p_algorithm     => gc_algorithm
                                                       , p_format        => gc_format
                                                       , p_decrypted_val => lc_cc_decrypted
                                                       , x_encrypted_val => lc_cc_encrypted_new
                                                       , x_error_message => lc_cc_encrypt_error
                                                       , x_key_label     => lc_cc_key_label_new);
													   
                lc_error_msg := SUBSTR(lc_cc_encrypt_error,1,4000);
                lc_error_action := 'ENCRYPT';
													  
                IF ( (lc_cc_encrypt_error IS NOT NULL) OR (lc_cc_encrypted_new IS NULL)) THEN --If encryption is Unsuccessful

                   location_and_log(gc_debug, 'Encrypting Error Message :'||lc_error_msg);
                   
                   ln_failed_records := ln_failed_records + 1;
					
                ELSE  --If encryption is successful
                   location_and_log(gc_debug, 'Encrypted Number :'||lc_cc_encrypted_new);
                   lc_string := lc_cc_encrypted_new||' '||lc_cc_key_label_new;
                   location_and_log(gc_debug, 'String is : '||lc_string);
				            UTL_FILE.put_line (lc_filehandle, lc_string);
                   ln_success_records  := ln_success_records + 1;
                END IF;
            END IF;
          EXCEPTION
           WHEN OTHERS 
           THEN
                   location_and_log(gc_debug,'WHEN OTHERS ERROR encountered ' 
				                        || '. OE Payment ID: ' || l_cc_excep_oe_pmt(i).oe_payment_id
                                        || '. Credit Card Number: ' || l_cc_excep_oe_pmt(i).credit_card_number_new
                                        || '. Error Message: ' || SQLERRM);
                   
                   ln_failed_records := ln_failed_records + 1;
          END;
        END LOOP;       
   
      EXIT WHEN cur_ext_payments%NOTFOUND;
     END LOOP;
      
    CLOSE cur_ext_payments;
	
	UTL_FILE.fclose (lc_filehandle);
	
    --========================================================================
    -- Updating the OUTPUT FILE
	  --========================================================================
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed :: '||ln_total_records_processed);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed Successfully :: '||ln_success_records);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Failed :: '||ln_failed_records);
       
   EXCEPTION 
      WHEN UTL_FILE.INVALID_MODE
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20051, 'Invalid Mode Parameter');
      WHEN UTL_FILE.INVALID_PATH
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20052, 'Invalid File Location');
      WHEN UTL_FILE.INVALID_FILEHANDLE
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20053, 'Invalid Filehandle');
      WHEN UTL_FILE.INVALID_OPERATION
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20054, 'Invalid Operation');
      WHEN UTL_FILE.WRITE_ERROR
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20056, 'Write Error');
      WHEN UTL_FILE.INTERNAL_ERROR
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20057, 'Internal Error');
      WHEN UTL_FILE.FILE_OPEN
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20059, 'File Already Opened');  
      WHEN OTHERS 
      THEN
	      fnd_file.put_line(fnd_file.log,' When OTHERS Exception in OE Payments :'||SQLERRM);

END extract_pmts_exceptions;                                   
                                 
-- +===================================================================+
-- | PROCEDURE  : extract_deps_exceptions                              |
-- |                                                                   |
-- | DESCRIPTION: Extract Deposits Exception Records                   |
-- |                                                                   |
-- | PARAMETERS : p_debug_flag                                         |
-- |                                                                   |
-- | RETURNS    : None                                                 |
-- +===================================================================+                  
PROCEDURE extract_deps_exceptions ( 
                                    p_debug_flag               IN           VARCHAR2                                    
                                  )
IS
    -- ==================
    -- Cursor Declaration
    -- ==================   
    CURSOR cur_ext_deposits
    IS
    SELECT  /*+FULL(DEP) PARALLEL(DEP,32)*/
	        credit_card_number_new   
           ,key_label_new
           ,deposit_id		   
    FROM   xx_c2t_cc_token_stg_deposits DEP
    WHERE  1 = 1
      AND  re_encrypt_status = 'C'
      AND  convert_status = 'N' 
    ;
    
	-- =======================
    -- Record Type Declaration
    -- ======================= 
       TYPE r_cc_excep_stg_dep 
       IS
         RECORD ( credit_card_number_new        xx_c2t_cc_token_stg_deposits.credit_card_number_new%TYPE,
                  key_label_new                 xx_c2t_cc_token_stg_deposits.key_label_new%TYPE,
			      deposit_id                    xx_c2t_cc_token_stg_deposits.deposit_id%TYPE);
	
    -- ======================
    -- Table Type Declaration
    -- ====================== 	
	   TYPE t_cc_excep_stg_dep	
	   IS
	     TABLE OF r_cc_excep_stg_dep INDEX BY BINARY_INTEGER;
    
    -- ================
    -- Local Variables
    -- ================
    l_cc_excep_stg_dep          t_cc_excep_stg_dep;
    lc_cc_decrypted             VARCHAR2(4000)  := NULL;
    lc_cc_decrypt_error         VARCHAR2(4000)  := NULL;
    lc_cc_encrypted_new         VARCHAR2(4000)  := NULL;
    lc_cc_encrypt_error         VARCHAR2(4000)  := NULL;
    lc_cc_key_label_new         VARCHAR2(4000)  := NULL;
	ln_err_count                NUMBER          := 0;
	ln_error_idx                NUMBER          := 0;
	lc_error_msg                VARCHAR2(4000);
    lc_error_action             VARCHAR2(2000);
    ln_total_records_processed  NUMBER          := 0;
    ln_success_records          NUMBER          := 0;
    ln_failed_records           NUMBER          := 0;
	
	lc_filehandle               UTL_FILE.file_type;
	lc_string                   VARCHAR2 (1000);
    
BEGIN    
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Initialize the EXCEPTION PROGRAM for Deposits'); 
     gc_file_name := 'xx_c2t_cnv_cc_exceptions_deposits.txt';
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Deposits File Name :'||gc_file_name); 
	 lc_filehandle := UTL_FILE.fopen (gc_source_path, gc_file_name, gc_mode);
	 
     OPEN cur_ext_deposits;
     LOOP
      l_cc_excep_stg_dep.DELETE; --- Deleting the data in the Table type 
		  FETCH cur_ext_deposits BULK COLLECT
		  INTO l_cc_excep_stg_dep;

     ln_total_records_processed := ln_total_records_processed + l_cc_excep_stg_dep.COUNT;
    
       FOR i IN 1 .. l_cc_excep_stg_dep.COUNT
       LOOP
		  BEGIN
            lc_cc_decrypted     := NULL;
            lc_cc_decrypt_error := NULL;
            lc_error_msg        := NULL;
            lc_cc_encrypted_new := NULL;
            lc_cc_encrypt_error := NULL;
            lc_cc_key_label_new := NULL;
            lc_error_action     := NULL;
            ln_err_count        := NULL;
            ln_error_idx        := NULL;	
			lc_string           := NULL;
            --========================================================================
            -- DECRYPTING the Credit Card Number
            --========================================================================
            location_and_log(gc_debug,' ');
			location_and_log(gc_debug, 'Deposit ID :'||l_cc_excep_stg_dep (i).deposit_id);
            location_and_log(gc_debug, 'Decrypting CARD ID :'||l_cc_excep_stg_dep (i).credit_card_number_new);
            DBMS_SESSION.SET_CONTEXT( namespace => gc_context
						            , attribute => 'TYPE'
						            , value     => 'EBS');

            XX_OD_SECURITY_KEY_PKG.DECRYPT( p_module        => 'AJB'
                                          , p_key_label     => l_cc_excep_stg_dep (i).key_label_new
                                          , p_encrypted_val => l_cc_excep_stg_dep (i).credit_card_number_new
                                          , p_algorithm     => gc_algorithm
                                          , x_decrypted_val => lc_cc_decrypted
                                          , x_error_message => lc_cc_decrypt_error);
										  
            lc_error_msg := SUBSTR(lc_cc_decrypt_error,1,4000);
            lc_error_action := 'DECRYPT';
			
            location_and_log(gc_debug, 'Decrypted Number :'||SUBSTR(lc_cc_decrypted,-4));
										  
            IF ( (lc_cc_decrypt_error IS NOT NULL) OR (lc_cc_decrypted IS NULL)) THEN --If decryption is Unsuccessful

                location_and_log(gc_debug,'Decrypting Error Message :'||lc_error_msg);
                
                ln_failed_records := ln_failed_records + 1;
				
            ELSE --If decryption is Successful
	            --========================================================================
	            -- ENCRYPTING/ Tokenizing the Credit Card Number again
	            --========================================================================
                DBMS_SESSION.SET_CONTEXT( namespace => gc_context
                                        , attribute => 'TYPE'
                                        , value     => 'OM');

                XX_OD_SECURITY_KEY_PKG.ENCRYPT_OUTLABEL( p_module        => 'HVOP' 
                                                       , p_key_label     => gc_key_label
                                                       , p_algorithm     => gc_algorithm
                                                       , p_format        => gc_format
                                                       , p_decrypted_val => lc_cc_decrypted
                                                       , x_encrypted_val => lc_cc_encrypted_new
                                                       , x_error_message => lc_cc_encrypt_error
                                                       , x_key_label     => lc_cc_key_label_new);
													   
                lc_error_msg := SUBSTR(lc_cc_encrypt_error,1,4000);
                lc_error_action := 'ENCRYPT';
													  
                IF ( (lc_cc_encrypt_error IS NOT NULL) OR (lc_cc_encrypted_new IS NULL)) THEN --If encryption is Unsuccessful

                   location_and_log(gc_debug, 'Encrypting Error Message :'||lc_error_msg);
                   
                   ln_failed_records := ln_failed_records + 1;
					
                ELSE  --If encryption is successful
                   location_and_log(gc_debug, 'Encrypted Number :'||lc_cc_encrypted_new);
                   lc_string := lc_cc_encrypted_new||' '||lc_cc_key_label_new;
                   location_and_log(gc_debug, 'String is '||lc_string);
				   UTL_FILE.put_line (lc_filehandle, lc_string);
                   ln_success_records  := ln_success_records + 1;
                END IF;
            END IF;
          EXCEPTION
           WHEN OTHERS 
           THEN
                   location_and_log(gc_debug,'WHEN OTHERS ERROR encountered ' 
				                        || '. Deposit ID: ' || l_cc_excep_stg_dep(i).deposit_id
                                        || '. Credit Card Number: ' || l_cc_excep_stg_dep(i).credit_card_number_new
                                        || '. Error Message: ' || SQLERRM);
                   
                   ln_failed_records := ln_failed_records + 1;
          END;
        END LOOP;
        
   
      EXIT WHEN cur_ext_deposits%NOTFOUND;
     END LOOP;
      
    CLOSE cur_ext_deposits;
	
	UTL_FILE.fclose (lc_filehandle);
	
    --========================================================================
    -- Updating the OUTPUT FILE
	  --========================================================================
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed :: '||ln_total_records_processed);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed Successfully :: '||ln_success_records);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Failed :: '||ln_failed_records);
       
   EXCEPTION 
      WHEN UTL_FILE.INVALID_MODE
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20051, 'Invalid Mode Parameter');
      WHEN UTL_FILE.INVALID_PATH
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20052, 'Invalid File Location');
      WHEN UTL_FILE.INVALID_FILEHANDLE
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20053, 'Invalid Filehandle');
      WHEN UTL_FILE.INVALID_OPERATION
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20054, 'Invalid Operation');
      WHEN UTL_FILE.WRITE_ERROR
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20056, 'Write Error');
      WHEN UTL_FILE.INTERNAL_ERROR
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20057, 'Internal Error');
      WHEN UTL_FILE.FILE_OPEN
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20059, 'File Already Opened');  
      WHEN OTHERS 
      THEN
	      fnd_file.put_line(fnd_file.log,' When OTHERS Exception in Deposits :'||SQLERRM);
END extract_deps_exceptions;

-- +===================================================================+
-- | PROCEDURE  : extract_rets_exceptions                              |
-- |                                                                   |
-- | DESCRIPTION: Extract Returns Exception Records                    |
-- |                                                                   |
-- | PARAMETERS : p_debug_flag                                         |
-- |                                                                   |
-- | RETURNS    : None                                                 |
-- +===================================================================+                   
PROCEDURE extract_rets_exceptions ( 
                                    p_debug_flag               IN           VARCHAR2									
                                  )	
IS
    -- ==================
    -- Cursor Declaration
    -- ==================   
    CURSOR cur_ext_returns
    IS
    SELECT /*+FULL(RET) PARALLEL(RET,32)*/
	       credit_card_number_new,
           key_label_new,
		   return_id
      FROM xx_c2t_cc_token_stg_returns RET
     WHERE 1 = 1
       AND re_encrypt_status = 'C'
       AND convert_status = 'N' 
    ;
    
	-- =======================
    -- Record Type Declaration
    -- ======================= 
	   TYPE r_cc_excep_stg_ret 
       IS
         RECORD ( credit_card_number_new        xx_c2t_cc_token_stg_returns.credit_card_number_new%TYPE,
                  key_label_new                 xx_c2t_cc_token_stg_returns.key_label_new%TYPE,
			      return_id                     xx_c2t_cc_token_stg_returns.return_id%TYPE);
	
    -- ======================
    -- Table Type Declaration
    -- ====================== 	
	   TYPE t_cc_excep_stg_ret	
	   IS
	     TABLE OF r_cc_excep_stg_ret INDEX BY BINARY_INTEGER;
    
    -- ================
    -- Local Variables
    -- ================
    l_cc_excep_stg_ret          t_cc_excep_stg_ret;
    lc_cc_decrypted             VARCHAR2(4000)  := NULL;
    lc_cc_decrypt_error         VARCHAR2(4000)  := NULL;
    lc_cc_encrypted_new         VARCHAR2(4000)  := NULL;
    lc_cc_encrypt_error         VARCHAR2(4000)  := NULL;
    lc_cc_key_label_new         VARCHAR2(4000)  := NULL;
	ln_err_count                NUMBER          := 0;
	ln_error_idx                NUMBER          := 0;
	lc_error_msg                VARCHAR2(4000);
    lc_error_action             VARCHAR2(2000);
    ln_total_records_processed  NUMBER          := 0;
    ln_success_records          NUMBER          := 0;
    ln_failed_records           NUMBER          := 0;
	
	lc_filehandle               UTL_FILE.file_type;
	lc_string                   VARCHAR2 (1000);

BEGIN    
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Initialize the EXCEPTION PROGRAM for Retruns'); 
     gc_file_name := 'xx_c2t_cnv_cc_exceptions_returns.txt'; 
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Returns File Name :'||gc_file_name); 
	 lc_filehandle := UTL_FILE.fopen (gc_source_path, gc_file_name, gc_mode);
	 
     OPEN cur_ext_returns;
     LOOP
      l_cc_excep_stg_ret.DELETE; --- Deleting the data in the Table type 
		  FETCH cur_ext_returns BULK COLLECT
		  INTO l_cc_excep_stg_ret;

     ln_total_records_processed := ln_total_records_processed + l_cc_excep_stg_ret.COUNT;
    
       FOR i IN 1 .. l_cc_excep_stg_ret.COUNT
       LOOP
		  BEGIN
            lc_cc_decrypted     := NULL;
            lc_cc_decrypt_error := NULL;
            lc_error_msg        := NULL;
            lc_cc_encrypted_new := NULL;
            lc_cc_encrypt_error := NULL;
            lc_cc_key_label_new := NULL;
            lc_error_action     := NULL;
            ln_err_count        := NULL;
            ln_error_idx        := NULL;	
			lc_string           := NULL;
            --========================================================================
            -- DECRYPTING the Credit Card Number
            --========================================================================
            location_and_log(gc_debug,' ');
			location_and_log(gc_debug, 'Return ID :'||l_cc_excep_stg_ret (i).return_id);
            location_and_log(gc_debug, 'Decrypting CARD ID :'||l_cc_excep_stg_ret (i).credit_card_number_new);
            DBMS_SESSION.SET_CONTEXT( namespace => gc_context
						            , attribute => 'TYPE'
						            , value     => 'EBS');

            XX_OD_SECURITY_KEY_PKG.DECRYPT( p_module        => 'AJB'
                                          , p_key_label     => l_cc_excep_stg_ret (i).key_label_new
                                          , p_encrypted_val => l_cc_excep_stg_ret (i).credit_card_number_new
                                          , p_algorithm     => gc_algorithm
                                          , x_decrypted_val => lc_cc_decrypted
                                          , x_error_message => lc_cc_decrypt_error);
										  
            lc_error_msg := SUBSTR(lc_cc_decrypt_error,1,4000);
            lc_error_action := 'DECRYPT';
			
            location_and_log(gc_debug, 'Decrypted Number : '||SUBSTR(lc_cc_decrypted,-4));
										  
            IF ( (lc_cc_decrypt_error IS NOT NULL) OR (lc_cc_decrypted IS NULL)) THEN --If decryption is Unsuccessful

                location_and_log(gc_debug,'Decrypting Error Message :'||lc_error_msg);
                
                ln_failed_records := ln_failed_records + 1;
				
            ELSE --If decryption is Successful
	            --========================================================================
	            -- ENCRYPTING/ Tokenizing the Credit Card Number again
	            --========================================================================
                DBMS_SESSION.SET_CONTEXT( namespace => gc_context
                                        , attribute => 'TYPE'
                                        , value     => 'OM');

                XX_OD_SECURITY_KEY_PKG.ENCRYPT_OUTLABEL( p_module        => 'HVOP' 
                                                       , p_key_label     => gc_key_label
                                                       , p_algorithm     => gc_algorithm
                                                       , p_format        => gc_format
                                                       , p_decrypted_val => lc_cc_decrypted
                                                       , x_encrypted_val => lc_cc_encrypted_new
                                                       , x_error_message => lc_cc_encrypt_error
                                                       , x_key_label     => lc_cc_key_label_new);
													   
                lc_error_msg := SUBSTR(lc_cc_encrypt_error,1,4000);
                lc_error_action := 'ENCRYPT';
													  
                IF ( (lc_cc_encrypt_error IS NOT NULL) OR (lc_cc_encrypted_new IS NULL)) THEN --If encryption is Unsuccessful

                   location_and_log(gc_debug, 'Encrypting Error Message :'||lc_error_msg);
                   
                   ln_failed_records := ln_failed_records + 1;
					
                ELSE  --If encryption is successful
                   location_and_log(gc_debug, 'Encrypted Number :'||lc_cc_encrypted_new);
                   lc_string := lc_cc_encrypted_new||' '||lc_cc_key_label_new;
                   location_and_log(gc_debug, 'String is '||lc_string);
                   
				   UTL_FILE.put_line (lc_filehandle, lc_string);
                   ln_success_records  := ln_success_records + 1;
                END IF;
            END IF;
          EXCEPTION
           WHEN OTHERS 
           THEN
                   location_and_log(gc_debug,'WHEN OTHERS ERROR encountered ' 
				                        || '. Return ID: ' || l_cc_excep_stg_ret(i).return_id
                                        || '. Credit Card Number: ' || l_cc_excep_stg_ret(i).credit_card_number_new
                                        || '. Error Message: ' || SQLERRM);
                   
                   ln_failed_records := ln_failed_records + 1;
          END;
        END LOOP;       
   
      EXIT WHEN cur_ext_returns%NOTFOUND;
     END LOOP;
      
    CLOSE cur_ext_returns;
	
	UTL_FILE.fclose (lc_filehandle);
	
    --========================================================================
    -- Updating the OUTPUT FILE
	  --========================================================================
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed :: '||ln_total_records_processed);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed Successfully :: '||ln_success_records);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Failed :: '||ln_failed_records);
       
   EXCEPTION 
   WHEN UTL_FILE.INVALID_MODE
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20051, 'Invalid Mode Parameter');
      WHEN UTL_FILE.INVALID_PATH
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20052, 'Invalid File Location');
      WHEN UTL_FILE.INVALID_FILEHANDLE
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20053, 'Invalid Filehandle');
      WHEN UTL_FILE.INVALID_OPERATION
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20054, 'Invalid Operation');
      WHEN UTL_FILE.WRITE_ERROR
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20056, 'Write Error');
      WHEN UTL_FILE.INTERNAL_ERROR
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20057, 'Internal Error');
      WHEN UTL_FILE.FILE_OPEN
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20059, 'File Already Opened');       
      WHEN OTHERS 
      THEN
	       fnd_file.put_line(fnd_file.log,' When OTHERS Exception in Returns :'||SQLERRM);
 END extract_rets_exceptions;
 
 /* Version 1.5 changes*/
 PROCEDURE extract_iby_hist_exceptions ( 
                                               p_debug_flag               IN           VARCHAR2                                  
                                    )
 IS
    CURSOR cur_iby_hist
    IS
       SELECT  /*+parallel(IBY_HIST) full(IBY_HIST) */
               DISTINCT credit_card_number_new   
              ,key_label_new 
         FROM xx_c2t_cc_token_stg_iby_hist IBY_HIST
        WHERE convert_status IS NULL;
    
    TYPE r_cc_excep_stg_dep 
    IS
      RECORD ( credit_card_number_new        xx_c2t_cc_token_stg_iby_hist.credit_card_number_new%TYPE,
               key_label_new                 xx_c2t_cc_token_stg_iby_hist.key_label_new%TYPE
	     );
	   
    TYPE t_cc_excep_stg_dep	
    IS
    TABLE OF r_cc_excep_stg_dep INDEX BY BINARY_INTEGER;
    
    -- Local Variables
    l_cc_excep_stg_dep          t_cc_excep_stg_dep;
    ln_batch_size		NUMBER := 1000; 
    lc_cc_decrypted             VARCHAR2(4000)  := NULL;
    lc_cc_decrypt_error         VARCHAR2(4000)  := NULL;
    lc_cc_encrypted_new         VARCHAR2(4000)  := NULL;
    lc_cc_encrypt_error         VARCHAR2(4000)  := NULL;
    lc_cc_key_label_new         VARCHAR2(4000)  := NULL;
    ln_err_count                NUMBER          := 0;
    ln_error_idx                NUMBER          := 0;
    lc_error_msg                VARCHAR2(4000);
    lc_error_action             VARCHAR2(2000);
    ln_total_records_processed  NUMBER          := 0;
    ln_success_records          NUMBER          := 0;
    ln_failed_records           NUMBER          := 0;
	
    lc_filehandle               UTL_FILE.file_type;
    lc_string                   VARCHAR2 (1000);
    
 BEGIN    
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Initialize the EXCEPTION PROGRAM for IBY History');    
    gc_file_name := 'xx_c2t_cnv_cc_exceptions_ibyhist.txt'; 	
    lc_filehandle := UTL_FILE.fopen (gc_source_path, gc_file_name, gc_mode);
	 
    OPEN cur_iby_hist;
    LOOP
       FETCH cur_iby_hist BULK COLLECT INTO l_cc_excep_stg_dep LIMIT ln_batch_size;
       EXIT WHEN l_cc_excep_stg_dep.COUNT = 0;
       
       ln_total_records_processed := ln_total_records_processed + l_cc_excep_stg_dep.COUNT;
    
       FOR i IN 1 .. l_cc_excep_stg_dep.COUNT
       LOOP
	  BEGIN
             lc_string := l_cc_excep_stg_dep (i).credit_card_number_new||' '||l_cc_excep_stg_dep (i).key_label_new;
           --location_and_log(gc_debug, 'String is '||lc_string);
   	     UTL_FILE.put_line (lc_filehandle, lc_string);
             ln_success_records  := ln_success_records + 1;
          EXCEPTION
          WHEN OTHERS 
          THEN
             location_and_log(gc_debug,'WHEN OTHERS ERROR encountered ' 
                                        || '. Credit Card Number: ' || l_cc_excep_stg_dep(i).credit_card_number_new
                                        || '. Error Message: ' || SQLERRM);
                   
             ln_failed_records := ln_failed_records + 1;
          END;
       END LOOP;
    END LOOP;
      
    CLOSE cur_iby_hist;
	
    UTL_FILE.fclose (lc_filehandle);
	
    --========================================================================
    -- Updating the OUTPUT FILE
    --========================================================================
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed :: '||ln_total_records_processed);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed Successfully :: '||ln_success_records);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Failed :: '||ln_failed_records);
       
 EXCEPTION 
     WHEN UTL_FILE.INVALID_MODE
     THEN
       UTL_FILE.FCLOSE_ALL;
       RAISE_APPLICATION_ERROR (-20051, 'Invalid Mode Parameter');
     WHEN UTL_FILE.INVALID_PATH
     THEN
       UTL_FILE.FCLOSE_ALL;
       RAISE_APPLICATION_ERROR (-20052, 'Invalid File Location');
     WHEN UTL_FILE.INVALID_FILEHANDLE
     THEN
       UTL_FILE.FCLOSE_ALL;
       RAISE_APPLICATION_ERROR (-20053, 'Invalid Filehandle');
     WHEN UTL_FILE.INVALID_OPERATION
     THEN
       UTL_FILE.FCLOSE_ALL;
       RAISE_APPLICATION_ERROR (-20054, 'Invalid Operation');
     WHEN UTL_FILE.WRITE_ERROR
     THEN
       UTL_FILE.FCLOSE_ALL;
       RAISE_APPLICATION_ERROR (-20056, 'Write Error');
     WHEN UTL_FILE.INTERNAL_ERROR
     THEN
       UTL_FILE.FCLOSE_ALL;
       RAISE_APPLICATION_ERROR (-20057, 'Internal Error');
     WHEN UTL_FILE.FILE_OPEN
     THEN
       UTL_FILE.FCLOSE_ALL;
       RAISE_APPLICATION_ERROR (-20059, 'File Already Opened');
     WHEN OTHERS 
     THEN
       IF cur_iby_hist%ISOPEN THEN
             CLOSE cur_iby_hist;
       END IF;
       fnd_file.put_line(fnd_file.log,' When OTHERS Exception in IBY HIST EXCEPTIONS :'||SQLERRM);
 END extract_iby_hist_exceptions;
   
 /* Version 1.5 changes made to call ajb gettoken for exception records*/
 PROCEDURE extract_ordt_exceptions ( 
                                    p_debug_flag               IN           VARCHAR2                                    
                                    )
 IS
   
      CURSOR excpt_stg_cur IS
        SELECT record_id,credit_card_number_new,cc_key_label_new
          FROM  xx_c2t_cc_token_stg_excptns
         WHERE ajb_token_status = 'N';
                                                             
       TYPE excpt_stg IS TABLE OF excpt_stg_cur%ROWTYPE
       INDEX BY PLS_INTEGER;
       l_excpt_stg_tab 	excpt_stg;
      
	   lc_cc_decrypted     VARCHAR2(4000)  := NULL;
	   lc_token_decrypted  VARCHAR2(4000)  := NULL;
	   lc_cc_decrypt_error VARCHAR2(4000)  := NULL;
	   lc_cc_encrypt_error VARCHAR2(4000)  := NULL;
	   lc_error_msg        VARCHAR2(4000);
	   ln_err_count        NUMBER;
	   lc_error_action     VARCHAR2(2000);
	   ln_total_records_processed  NUMBER  := 0;
	   ln_success_records          NUMBER  := 0;
	   ln_failed_records           NUMBER  := 0;
	   ln_max_card_id              NUMBER;
	   lc_credit_card_number_new   VARCHAR2(80);
	   lc_cc_key_label_new         VARCHAR2(80);
	   lc_token		       VARCHAR2(80);
	   lc_token_number_new         VARCHAR2(80);
	   lc_token_key_label_new      VARCHAR2(80);
	   lc_first_six                VARCHAR2(6);
	   lc_last_four		       VARCHAR2(4); 
	   indx                 	NUMBER;
	   ln_batch_size		NUMBER := 1000; 
	   l_exit_prog_flag            xx_fin_translatevalues.target_value1%TYPE;

	   data_exception                	EXCEPTION;
	   exit_program           		EXCEPTION;
	   

        -- +===================================================================+
	-- | PROCEDURE  : XX_EXIT_PROGRAM_CHECK                                |
	-- | DESCRIPTION: Performs the following actions based on parameters   |
	-- |              1. Sets p_program_name: Checks if the program needs  |
	-- +===================================================================+
	  PROCEDURE xx_exit_program_check(p_program_name    IN  VARCHAR2
                                        , x_exit_prog_flag  OUT VARCHAR2)
	  IS
             l_exit_prog_flag    xx_fin_translatevalues.target_value1%TYPE;
	  BEGIN
	     SELECT    NVL(xftv.target_value1,'N')
	       INTO    l_exit_prog_flag
	       FROM    xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
	      WHERE    xftd.translate_id = xftv.translate_id
		AND    xftd.translation_name = 'XX_PROGRAM_CONTROL'
		AND    xftv.source_value1 = p_program_name
		AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE+1)
		AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE+1)
		AND    xftv.enabled_flag = 'Y'
		AND    xftd.enabled_flag = 'Y';
             x_exit_prog_flag := l_exit_prog_flag;
          EXCEPTION
          WHEN OTHERS THEN
	       fnd_file.put_line(fnd_file.log,'WHEN OTHERS EXCEPTION of xx_exit_program_check - exiting :: '||SQLERRM);	
	       x_exit_prog_flag := 'Y';
          END xx_exit_program_check;
	   
	   
   BEGIN   
      fnd_file.put_line(fnd_file.log,'Initialize the EXCEPTION PROGRAM for GETTOKEN');  

      SELECT MAX (card_id)
	INTO ln_max_card_id
	FROM xx_c2t_cc_token_crypto_vault;
	
      fnd_file.put_line(fnd_file.log,'Processing exception staging records..');
      
      OPEN excpt_stg_cur;
      LOOP
         FETCH excpt_stg_cur BULK COLLECT INTO l_excpt_stg_tab LIMIT ln_batch_size;
         EXIT WHEN l_excpt_stg_tab.COUNT = 0;

         --Check to continue/ stop the program
         xx_exit_program_check(p_program_name    => 'XX_C2T_CNV_CC_EXCEPTIONS'
                              ,x_exit_prog_flag  => l_exit_prog_flag);
								   
         IF l_exit_prog_flag = 'Y' THEN
            RAISE exit_program;
         END IF;

         FOR indx IN l_excpt_stg_tab.FIRST..l_excpt_stg_tab.LAST 
         LOOP
         
            BEGIN
            
                  lc_credit_card_number_new  := l_excpt_stg_tab(indx).credit_card_number_new;
		  lc_cc_key_label_new        := l_excpt_stg_tab(indx).cc_key_label_new;

                  lc_first_six        := NULL;
                  lc_last_four        := NULL;
		  lc_cc_decrypted     := NULL;
	          lc_cc_decrypt_error := NULL;
	          lc_error_msg        := NULL;
	          lc_cc_encrypt_error := NULL;
	          lc_error_action     := NULL;

	          --========================================================================
	          -- DECRYPTING the Credit Card Number
	          --========================================================================
	          location_and_log(gc_debug, 'Decrypting CARD Number New '||lc_credit_card_number_new||' key label'||lc_cc_key_label_new);
	         
                  DBMS_SESSION.SET_CONTEXT( namespace => gc_context
				          , attribute => 'TYPE'
				          , value     => 'EBS');

	          XX_OD_SECURITY_KEY_PKG.DECRYPT( p_module        => 'AJB'
					        , p_key_label     => lc_cc_key_label_new
					        , p_encrypted_val => lc_credit_card_number_new
					        , p_algorithm     => '3DES'
					        , x_decrypted_val => lc_cc_decrypted
					        , x_error_message => lc_cc_decrypt_error);

	          lc_error_msg := SUBSTR(lc_cc_decrypt_error,1,4000);
	          lc_error_action := 'DECRYPT';

	          IF ( (lc_cc_decrypt_error IS NOT NULL) OR (lc_cc_decrypted IS NULL)) 
	          THEN --Unsuccessful
		      lc_error_msg := 'Decrypting Error Message for '||lc_credit_card_number_new|| ': '||lc_error_msg;
		      RAISE data_exception;
		
		  --Version 1.7 Amex conv
	          /*ELSIF SUBSTR (lc_cc_decrypted, 1, 1) != '3'
	          THEN --AMEX and CITI Not required
		      lc_error_msg := 'Decrypt - NOT AMEX CARD : '||lc_credit_card_number_new;
		      RAISE data_exception;*/
		      
		  --Version 1.5 Added check for discover records
	          /*ELSIF ((SUBSTR (lc_cc_decrypted, 1, 1) = '3' and LENGTH(lc_cc_decrypted) <> 14)) 
	          THEN --AMEX and CITI Not required
		      lc_error_msg := 'Decrypt - AMEX OR CITI CARD : '||lc_credit_card_number_new;
		      RAISE data_exception;*/		      
		      
		  --Start Version 1.6 check for bin ranges for citi cards
	          ELSIF (LENGTH(lc_cc_decrypted)= 16 and SUBSTR (lc_cc_decrypted, 1, 7) = '6011656') 
	          THEN 
		      lc_error_msg := 'CITI CARD : '||lc_credit_card_number_new ||' Bin Value:'||SUBSTR (lc_cc_decrypted, 1, 7);
		      RAISE data_exception;
	          ELSIF (LENGTH(lc_cc_decrypted)= 15 and SUBSTR (lc_cc_decrypted, 1, 6) = '601116') 
	          THEN 
		      lc_error_msg := 'CITI CARD : '||lc_credit_card_number_new ||' Bin Value:'||SUBSTR (lc_cc_decrypted, 1, 6);
		      RAISE data_exception;
	          ELSIF (LENGTH(lc_cc_decrypted)= 16 and SUBSTR (lc_cc_decrypted, 1, 6) = '601156') 
		  THEN 
		      lc_error_msg := 'CITI CARD : '||lc_credit_card_number_new ||' Bin Value:'||SUBSTR (lc_cc_decrypted, 1, 6);
		      RAISE data_exception;
	          ELSIF (LENGTH(lc_cc_decrypted)= 15 and SUBSTR (lc_cc_decrypted, 1, 6) = '601156') 
		  THEN 
		      lc_error_msg := 'CITI CARD : '||lc_credit_card_number_new ||' Bin Value:'||SUBSTR (lc_cc_decrypted, 1, 6);
		      RAISE data_exception;
	          ELSIF (LENGTH(lc_cc_decrypted)= 18 and SUBSTR (lc_cc_decrypted, 1, 9) = '600525154') 
		  THEN 
		      lc_error_msg := 'CITI CARD : '||lc_credit_card_number_new ||' Bin Value:'||SUBSTR (lc_cc_decrypted, 1, 9);
		      RAISE data_exception;
	          ELSIF (LENGTH(lc_cc_decrypted)= 16 and SUBSTR (lc_cc_decrypted, 1, 8) = '60352810') 
		  THEN 
		      lc_error_msg := 'CITI CARD : '||lc_credit_card_number_new ||' Bin Value:'||SUBSTR (lc_cc_decrypted, 1, 8);
		      RAISE data_exception;
	          ELSIF (LENGTH(lc_cc_decrypted)= 18 and SUBSTR (lc_cc_decrypted, 1, 9) = '600525154') 
		  THEN 
		      lc_error_msg := 'CITI CARD : '||lc_credit_card_number_new ||' Bin Value:'||SUBSTR (lc_cc_decrypted, 1, 9);
		      RAISE data_exception;
	          ELSIF (LENGTH(lc_cc_decrypted)= 16 and SUBSTR (lc_cc_decrypted, 1, 8) = '60352880') 
		  THEN 
		      lc_error_msg := 'CITI CARD : '||lc_credit_card_number_new ||' Bin Value:'||SUBSTR (lc_cc_decrypted, 1, 8);
		      RAISE data_exception;	
	          ELSIF (LENGTH(lc_cc_decrypted)= 16 and SUBSTR (lc_cc_decrypted, 1, 6) = '603543') 
		  THEN 
		      lc_error_msg := 'CITI CARD : '||lc_credit_card_number_new ||' Bin Value:'||SUBSTR (lc_cc_decrypted, 1, 6);
		      RAISE data_exception;		      
		  --End Version 1.6 		      
		      
		     --Version 1.4 Added logic to remove Invalid cards with Junk Characters
		  --Version 1.5 Added check for special characters
	          ELSIF ((SUBSTR (lc_cc_decrypted, 1, 1) NOT IN ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')) OR (LENGTH(TRIM(TRANSLATE(lc_cc_decrypted,'0123456789',' '))) > 0))
	          THEN
		      lc_error_msg := 'CARD With Junk Characters: '||lc_credit_card_number_new;
	              RAISE data_exception;	
	          END IF;

	          --========================================================================
	          -- --If decryption is Successful - GetToken/ Get Token from AJB
	          --========================================================================
	          BEGIN
	             lc_first_six := SUBSTR(lc_cc_decrypted,1,6);
	             lc_last_four := SUBSTR(lc_cc_decrypted,-4,4);
	             location_and_log(gc_debug, 'First six '||lc_first_six||' Last Four'||lc_last_four);
	          EXCEPTION
	          WHEN others THEN
	             lc_error_msg := 'CARD with Junk CharactersFSx: '||lc_credit_card_number_new;
	             RAISE data_exception;	
	          END;
	          
	          lc_token     := NULL;
	          lc_error_msg := NULL;
	          XX_C2T_AJB_GetToken.get_cc_token(lc_cc_decrypted,lc_token,lc_error_msg);
	          IF lc_error_msg IS NOT NULL 
	          THEN
		     lc_error_msg := 'GetToken Response for cc new:'||lc_credit_card_number_new ||' Error msg '||lc_error_msg;
		     RAISE data_exception;
	          END IF;  

	          lc_token_decrypted  := lc_token;
	          lc_error_msg        := NULL;
	          lc_cc_encrypt_error := NULL;
	          lc_error_action     := NULL;
	          lc_token_number_new := NULL;
	          lc_token_key_label_new := NULL;

	          --xx_location_and_log( 'ENCRYPTION TOKEN NUMBER ');
	          
	          DBMS_SESSION.SET_CONTEXT( namespace => gc_context --question whether to use gc_context or 'XX_C2T_CNV_CRYPTO_CONTEXT'
				          , attribute => 'TYPE'
				          , value     => 'EBS');

	          XX_OD_SECURITY_KEY_PKG.ENCRYPT_OUTLABEL( p_module        => 'AJB'
						         , p_key_label     => NULL
						         , p_algorithm     => '3DES'
						         , p_decrypted_val => lc_token_decrypted
						         , x_encrypted_val => lc_token_number_new
						         , x_error_message => lc_cc_encrypt_error
						         , x_key_label     => lc_token_key_label_new);

	          lc_error_msg := lc_cc_encrypt_error;
	          lc_error_action := 'ENCRYPT_TOKEN';

	          IF ( (lc_cc_encrypt_error IS NOT NULL) OR (lc_token_number_new IS NULL)) 
	          THEN --Unsuccessful
		     lc_error_msg := 'Encrypting Error Message '||lc_error_msg;
		     RAISE data_exception;
		  END IF;

	          --If encryption is successful
	          location_and_log(gc_debug,'*********RECORD IS SUCCESSFULL FOR CC New:'||lc_credit_card_number_new);
	          --=====================================================================================
	          -- Updating the new Credit Card Number/ Token Value in table XX_C2T_CC_TOKEN_CRYPTO_VAULT
	          --=====================================================================================
	          ln_max_card_id := ln_max_card_id +1;
                  INSERT INTO xx_c2t_cc_token_crypto_vault(card_id
                  					  ,credit_card_number_orig
                  					  ,cc_key_label_orig
                  					  ,first_six
                  					  ,last_four
                  					  ,credit_card_number_new
                  					  ,cc_key_label_new
                  					  ,token_number_orig
                  					  ,token_key_label_orig
                  					  ,token_number_new
                  					  ,token_key_label_new
                  					  ,re_encrypt_status
                  					  ,error_action
                  					  ,error_message
                  					  ,created_by
                  					  ,creation_date
                  					  ,last_updated_by
                  					  ,last_update_date
                  					  ,last_update_login)
						  values (ln_max_card_id
						  	 ,NULL
						  	 ,NULL
						  	 ,lc_first_six
						  	 ,lc_last_four
						  	 ,lc_credit_card_number_new
						  	 ,lc_cc_key_label_new
						  	 ,NULL
						  	 ,NULL
						  	 ,lc_token_number_new
						  	 ,lc_token_key_label_new
						  	 ,'C'
						  	 ,NULL
						  	 ,NULL
						  	 ,gn_user_id
						  	 ,sysdate
						  	 ,gn_user_id
						  	 ,sysdate
						  	 ,gn_login_id);
						  	 
	          UPDATE xx_c2t_cc_token_stg_excptns
	             SET  ajb_token_status = 'P'
	                 ,last_updated_by  = gn_user_id
	                 ,last_update_date = sysdate
	           WHERE record_id = l_excpt_stg_tab(indx).record_id;						  	 

	          ln_success_records  := ln_success_records + 1;
	          
	    EXCEPTION
	       WHEN data_exception THEN
		  fnd_file.put_line(fnd_file.log,lc_error_msg);
		  lc_error_msg := substr(lc_error_msg,1,2000);
		  UPDATE xx_c2t_cc_token_stg_excptns
		     SET  ajb_token_status = 'E'
		          ,error_action = 'DATAEXCEPTION'
		          ,error_message = lc_error_msg
	                  ,last_updated_by  = gn_user_id
	                  ,last_update_date = sysdate		          
		   WHERE record_id = l_excpt_stg_tab(indx).record_id;
		  ln_failed_records  := ln_failed_records + 1;
		  
	       WHEN others THEN
	          lc_error_msg := substr(sqlerrm,1,2000);
	          fnd_file.put_line(fnd_file.log,'OthersException'||SUBSTR(SQLERRM,1,250));
	          UPDATE xx_c2t_cc_token_stg_excptns
		     SET  ajb_token_status = 'E'
		          ,error_action = 'OTHERSEXCEPTION'
		          ,error_message = lc_error_msg
	                  ,last_updated_by  = gn_user_id
	                  ,last_update_date = sysdate			          
		   WHERE record_id = l_excpt_stg_tab(indx).record_id;
		  ln_failed_records  := ln_failed_records + 1;
	    END;
	    ln_total_records_processed := ln_total_records_processed + 1;
	    
	 END LOOP;
	 
         COMMIT;
	
    END LOOP;
    CLOSE excpt_stg_cur;
     --========================================================================
     -- Updating the OUTPUT FILE
     --========================================================================
	   FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed :: '||ln_total_records_processed);
	   FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
	   FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed Successfully :: '||ln_success_records);
	   FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
	   FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Failed :: '||ln_failed_records);
   EXCEPTION 
   WHEN exit_program THEN
       fnd_file.put_line(fnd_file.log,' ENDING exception Program. EXIT FLAG has been updated to YES');
   WHEN OTHERS 
      THEN
	 fnd_file.put_line(fnd_file.log,' When OTHERS Exception in ORDT EXCEPTIONS :'||SQLERRM);
   END extract_ordt_exceptions;
                                 
-- +===================================================================+
-- | PROCEDURE  : exceptions_main                                      |
-- |                                                                   |
-- | PARAMETERS : p_debug_flag , p_process_type                        |
-- |                                                                   |
-- | RETURNS    : x_errbuf , x_retcode                                 |
-- +===================================================================+ 
PROCEDURE exceptions_main        ( 
                                   x_errbuf                   OUT NOCOPY   VARCHAR2
                                  ,x_retcode                  OUT NOCOPY   NUMBER
                                  ,p_debug_flag               IN           VARCHAR2	
                                  ,p_process_type             IN           VARCHAR2								  
								 )
IS 
BEGIN
    gc_debug := p_debug_flag;
	
	   -------------------------------------------------
       -- Print Parameter Names and Values to Log File
       -------------------------------------------------

       FND_FILE.PUT_LINE (FND_FILE.LOG, '');
       FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
       FND_FILE.PUT_LINE (FND_FILE.LOG, 'Process Type               : ' || p_process_type);
       FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag                 : ' || p_debug_flag);
       FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
       FND_FILE.PUT_LINE (FND_FILE.LOG, '');
	   
	   IF  p_process_type = 'PAYMENTS'
	   THEN
	       location_and_log(gc_debug,'Calling OE Payments Exceptions Procedure');		   
		   extract_pmts_exceptions(p_debug_flag => gc_debug );
		   
		   ELSIF p_process_type = 'DEPOSITS'
		   THEN
		      location_and_log(gc_debug,'Calling Deposits Exceptions Procedure');			  
			  extract_deps_exceptions(p_debug_flag => gc_debug);
			  
			  ELSIF p_process_type = 'RETURNS'
        THEN
			     location_and_log(gc_debug,'Calling Returns Exceptions Procedure');			  
			     extract_rets_exceptions(p_debug_flag => gc_debug);
           
           ELSIF p_process_type = 'IBY_HIST'
           THEN
			        location_and_log(gc_debug,'Calling IBY History Exceptions Procedure');			  
			        extract_iby_hist_exceptions(p_debug_flag => gc_debug);  
              
              ELSIF p_process_type = 'ORDT'
              THEN
                  location_and_log(gc_debug,'Calling ORDT Exceptions Procedure');			  
			            extract_ordt_exceptions(p_debug_flag => gc_debug);         
	   END IF;
  EXCEPTION
    WHEN OTHERS THEN
    x_retcode    := 2; -- ERROR
	  gc_error_loc := 'WHEN OTHERS ERROR encountered in EXCEPTIONS_MAIN PROCEDURE: ' || '. Error Message: ' || SQLERRM;
	  x_errbuf     := gc_error_loc;
      
END exceptions_main;	   
  
END XX_C2T_CNV_CC_EXCPTNS_PKG;
/ 
EXIT;                              