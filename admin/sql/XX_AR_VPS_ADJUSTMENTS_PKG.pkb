create or replace PACKAGE BODY XX_AR_VPS_ADJUSTMENTS_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	     :  XX_AR_VPS_ADJUSTMENTS_PKG                                                   |
-- |  RICE ID 	 :  E7047                                          			                    |
-- |  Description:                                                                          	|
-- |                                                           				                    |        
-- +============================================================================================+
-- | Version     Date          Author              Remarks                                      |
-- | =========   ===========   =============       =============================================|
-- | 1.0         28-JUN-2018   Havish Kasina       Initial version                              |
-- | 2.0         16-APR-2019   Satheesh Suthari    NAIT-90178 PENNY ADJ REPORT NEEDS TO BE MODIFIED  |
-- +============================================================================================+

gc_debug 	                VARCHAR2(2);
gn_request_id               fnd_concurrent_requests.request_id%TYPE;
gn_user_id                  fnd_concurrent_requests.requested_by%TYPE;
gn_login_id    	            NUMBER;
gc_error_loc                VARCHAR2(100);  
gc_error_msg                VARCHAR2(1000);
gc_errcode                  VARCHAR2(100);

-- +============================================================================================+
-- |  Name	 : Log Exception                                                                    |
-- |  Description: The log_exception procedure logs all exceptions                              |
-- =============================================================================================|
PROCEDURE log_exception (p_program_name       IN  VARCHAR2
                        ,p_error_location     IN  VARCHAR2
		                ,p_error_msg          IN  VARCHAR2)
IS
ln_login     NUMBER   :=  FND_GLOBAL.LOGIN_ID;
ln_user_id   NUMBER   :=  FND_GLOBAL.USER_ID;
BEGIN
XX_COM_ERROR_LOG_PUB.log_error(
			     p_return_code             => FND_API.G_RET_STS_ERROR
			    ,p_msg_count               => 1
			    ,p_application_name        => 'XXFIN'
			    ,p_program_type            => 'Custom Messages'
			    ,p_program_name            => p_program_name
			    ,p_attribute15             => p_program_name
			    ,p_program_id              => null
			    ,p_module_name             => 'AP'
			    ,p_error_location          => p_error_location
			    ,p_error_message_code      => null
			    ,p_error_message           => p_error_msg
			    ,p_error_message_severity  => 'MAJOR'
			    ,p_error_status            => 'ACTIVE'
			    ,p_created_by              => ln_user_id
			    ,p_last_updated_by         => ln_user_id
			    ,p_last_update_login       => ln_login
			    );

EXCEPTION 
WHEN OTHERS 
THEN 
    fnd_file.put_line(fnd_file.log, 'Error while writing to the log ...'|| SQLERRM);
END log_exception;

/*********************************************************************
* Procedure used to log based on gb_debug value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program log file.  Will prepend
* timestamp to each message logged.  This is useful for determining
* elapse times.
*********************************************************************/
PROCEDURE print_debug_msg (p_message   IN VARCHAR2,
                           p_force     IN BOOLEAN DEFAULT FALSE)
IS
    lc_message   VARCHAR2 (4000) := NULL;
BEGIN
    IF (gc_debug = 'Y' OR p_force)
    THEN
        lc_Message := p_message;
        fnd_file.put_line (fnd_file.log, lc_Message);

        IF ( fnd_global.conc_request_id = 0
            OR fnd_global.conc_request_id = -1)
        THEN
            dbms_output.put_line (lc_message);
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS
    THEN
        NULL;
END print_debug_msg;

/*********************************************************************
* Procedure used to out the text to the concurrent program.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program output file.
*********************************************************************/
PROCEDURE print_out_msg (p_message IN VARCHAR2)
IS
    lc_message   VARCHAR2 (4000) := NULL;
BEGIN
    lc_message := p_message;
    fnd_file.put_line (fnd_file.output, lc_message);

    IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)
    THEN
        dbms_output.put_line (lc_message);
    END IF;
EXCEPTION
WHEN OTHERS
THEN
    NULL;
END print_out_msg;

-- +===============================================================================================+
-- |  Name	 : stage_vps_adj_dtls                                                                  |                 	
-- |  Description: This procedure is to insert the VPS Small Dollar and Penny transactions to the  |
-- |               staging table                                                                   |
-- ================================================================================================|
							  
PROCEDURE stage_vps_adj_dtls(p_errbuf         OUT  VARCHAR2
                            ,p_retcode        OUT  VARCHAR2   
                            ,p_debug          IN   VARCHAR2
							)
AS 

   -- Cursor to fetch the Penny adjustments
    CURSOR penny_adj_dtls(p_from_amt  NUMBER) 
	IS
        SELECT  'ADJUSTMENTS'               TRX_CATEGORY
		       ,aps.class                   INVOICE_CLASS 
               ,rct.customer_trx_id         CUSTOMER_TRX_ID	
               ,rct.trx_number              TRANSACTION_NUMBER
			   ,rct.trx_date                TRANSACTION_DATE
			   ,rct.set_of_books_id         SET_OF_BOOKS_ID 
			   ,rct.attribute1              VENDOR_NUM
			   ,aps.payment_schedule_id     PAYMENT_SCHEDULE_ID
               ,aps.amount_due_remaining    AMOUNT	
               ,rct.invoice_currency_code 	CURRENCY_CODE
		       ,'WRITE OFF'                 REASON_CODE
		       ,'W/O to penny adj -----------------------  Reason Code: WRITE OFF  Adj Activity: VPS_PENNY_ADJ_OD' COMMENTS
               ,'VPS_PENNY_ADJ_OD'   ADJ_ACTIVITY_NAME
               ,rct.bill_to_customer_id     CUST_ACCOUNT_ID
               ,hca.account_number          CUST_ACCT_NUMBER
			   ,hca.account_name            CUST_ACCT_NAME
               ,rct.attribute7              SEND_REFUND
               ,rct.attribute3              REFUND_STATUS	
               ,aps.status                  TRX_STATUS
               ,NULL                        TRX_MESSAGE
		       ,NULL                        ERROR_MESSAGE
               ,'N'                         PROCESS_FLAG	
          FROM  ra_customer_trx_all rct 
	           ,hz_cust_accounts hca
               ,ar_payment_schedules_all aps
         WHERE 1 = 1 
           AND rct.bill_to_customer_id = hca.cust_account_id
           AND rct.customer_trx_id= aps.customer_trx_id
           AND rct.attribute_category='US_VPS' 
           AND hca.status = 'A'
           AND aps.status = 'OP'
           AND aps.class IN ( 'INV','DM')
		   AND (aps.amount_due_remaining > 0 AND aps.amount_due_remaining <= p_from_amt)
           AND NOT EXISTS ( SELECT 1
                      FROM xx_ar_vps_adj_dtls_stg
					 WHERE customer_trx_id = rct.customer_trx_id);
                     
   -- Cursor to fetch the Small Dollar adjustments
    CURSOR small_dollar_adj_dtls(p_from_amt  NUMBER,
	                             p_days      NUMBER) 
	IS
	    SELECT 'ADJUSTMENTS'                       TRX_CATEGORY
		       ,aps.class                          INVOICE_CLASS
               ,rct.customer_trx_id                CUSTOMER_TRX_ID	
               ,rct.trx_number                     TRANSACTION_NUMBER
			   ,rct.trx_date                       TRANSACTION_DATE
			   ,rct.set_of_books_id                SET_OF_BOOKS_ID
			   ,rct.attribute1                     VENDOR_NUM
			   ,aps.payment_schedule_id            PAYMENT_SCHEDULE_ID
               ,aps.amount_due_remaining           AMOUNT	
               ,rct.invoice_currency_code 	       CURRENCY_CODE
		       ,'WRITE OFF'                        REASON_CODE
		       ,'W/O to small dollar adj -----------------------  Reason Code: WRITE OFF  Adj Activity: VPS_SMALL_DOLLAR_ADJ_OD' COMMENTS
               ,'VPS_SMALL_DOLLAR_ADJ_OD'   ADJ_ACTIVITY_NAME
               ,rct.bill_to_customer_id            CUST_ACCOUNT_ID
               ,hca.account_number                 CUST_ACCT_NUMBER
			   ,hca.account_name                   CUST_ACCT_NAME
               ,rct.attribute7                     SEND_REFUND
               ,rct.attribute3                     REFUND_STATUS	
               ,aps.status                         TRX_STATUS
               ,NULL                               TRX_MESSAGE
		       ,NULL                               ERROR_MESSAGE
               ,'N'                                PROCESS_FLAG	
          FROM  ra_customer_trx_all rct 
	           ,hz_cust_accounts hca
               ,ar_payment_schedules_all aps
         WHERE 1 = 1 
           AND rct.bill_to_customer_id = hca.cust_account_id
           AND rct.customer_trx_id= aps.customer_trx_id
           AND rct.attribute_category='US_VPS' 
           AND hca.status = 'A'
           AND aps.class IN ( 'INV','DM')
           AND aps.status = 'OP'
           -- AND aps.amount_due_remaining <> aps.amount_due_original
           AND aps.due_date <= SYSDATE - p_days -- 180
		   AND (aps.amount_due_remaining > 0.01 AND aps.amount_due_remaining <= p_from_amt)
           AND NOT EXISTS ( SELECT 1
                              FROM xx_ar_vps_adj_dtls_stg
					         WHERE customer_trx_id = rct.customer_trx_id);
							 
	TYPE penny_details IS TABLE OF penny_adj_dtls%ROWTYPE
    INDEX BY PLS_INTEGER;
	
	TYPE small_dollar_details IS TABLE OF small_dollar_adj_dtls%ROWTYPE
    INDEX BY PLS_INTEGER;
  
    l_penny_detail_tab 		      penny_details;
	l_small_dollar_detail_tab     small_dollar_details;
	indx                 	      NUMBER;
    ln_batch_size		          NUMBER := 250;			     	
    ln_from_amt                   NUMBER;
	ln_days                       NUMBER;
	ln_total_records_processed    NUMBER;
    ln_success_records            NUMBER;
    ln_failed_records             NUMBER;
	lc_error_msg                  VARCHAR2(200);
	
BEGIN
    fnd_file.put_line(fnd_file.log,' Process Date :'||SYSDATE);
    fnd_file.put_line(fnd_file.log,' Input Parameters ');
	fnd_file.put_line(fnd_file.log,' Debug Flag :'||p_debug);
	
    gc_debug	               := p_debug;
    --  gn_request_id              := fnd_global.conc_request_id;
    --  gn_user_id                 := fnd_global.user_id;
    --  gn_login_id                := fnd_global.login_id; 
	ln_from_amt                := NULL;
	ln_days                    := NULL;
	ln_total_records_processed := 0;
	ln_success_records         := 0;
	ln_failed_records          := 0;
	gc_error_loc               := 'XX_AR_VPS_ADJUSTMENTS_PKG.stage_vps_adj_dtls';   
    gc_error_msg               := NULL;
    gc_errcode                 := NULL;
	
	--=============================================
	  -- Staging the VPS Penny adjustments details 
	--=============================================
	print_debug_msg('To get the details from the Translation OD_VPS_TRANSLATION for VPS_PENNY_ADJ_OD',TRUE);
	BEGIN
        SELECT TO_NUMBER(target_value1)
	      INTO ln_from_amt      
          FROM xx_fin_translatevalues
         WHERE translate_id IN (SELECT translate_id 
          			              FROM xx_fin_translatedefinition 
          			              WHERE translation_name = 'OD_VPS_TRANSLATION' 
          			                AND enabled_flag = 'Y')
           AND source_value1 = 'VPS_PENNY_ADJ_OD';
    EXCEPTION
    WHEN OTHERS
    THEN
       	ln_from_amt := 0.01;
    END;
	
	print_debug_msg('Start processing all the VPS Penny Adjusments Records',TRUE);  
	OPEN penny_adj_dtls(ln_from_amt);
    LOOP
	    l_penny_detail_tab.DELETE;  --- Deleting the data in the Table type
        FETCH penny_adj_dtls BULK COLLECT INTO l_penny_detail_tab LIMIT ln_batch_size;
        EXIT WHEN l_penny_detail_tab.COUNT = 0;
		  
		ln_total_records_processed := ln_total_records_processed + l_penny_detail_tab.COUNT;
		FOR indx IN l_penny_detail_tab.FIRST..l_penny_detail_tab.LAST 
        LOOP
            BEGIN
		        INSERT INTO XX_AR_VPS_ADJ_DTLS_STG ( trx_category       
		                                           , invoice_class      
		                                           , customer_trx_id    
		                                           , transaction_number 
												   , transaction_date
												   , set_of_books_id
												   , vendor_num
												   , payment_schedule_id
		                                           , amount             
		                                           , currency_code      
		                                           , reason_code        
		                                           , comments           
		                                           , adj_activity_name  
		                                           , cust_account_id    
		                                           , cust_acct_number  
                                                   , cust_acct_name												   
		                                           , send_refund        
		                                           , refund_status      
		                                           , trx_status         
		                                           , trx_message        
		                                           , request_id         
		                                           , creation_date      
		                                           , created_by         
		                                           , last_update_date   
		                                           , last_updated_by    
		                                           , last_update_login  
		                                           , error_message      
		                                           , process_flag       
		                                           )
							                VALUES ( l_penny_detail_tab(indx).trx_category         
		                                           , l_penny_detail_tab(indx).invoice_class      
                                                   , l_penny_detail_tab(indx).customer_trx_id    
		                                           , l_penny_detail_tab(indx).transaction_number 
												   , l_penny_detail_tab(indx).transaction_date
												   , l_penny_detail_tab(indx).set_of_books_id
												   , l_penny_detail_tab(indx).vendor_num
												   , l_penny_detail_tab(indx).payment_schedule_id
		                                           , l_penny_detail_tab(indx).amount             
		                                           , l_penny_detail_tab(indx).currency_code      
		                                           , l_penny_detail_tab(indx).reason_code        
		                                           , l_penny_detail_tab(indx).comments           
		                                           , l_penny_detail_tab(indx).adj_activity_name  
		                                           , l_penny_detail_tab(indx).cust_account_id    
		                                           , l_penny_detail_tab(indx).cust_acct_number 
                                                   , l_penny_detail_tab(indx).cust_acct_name												   
		                                           , l_penny_detail_tab(indx).send_refund        
		                                           , l_penny_detail_tab(indx).refund_status      
		                                           , l_penny_detail_tab(indx).trx_status         
		                                           , l_penny_detail_tab(indx).trx_message        
		                                           , gn_request_id         
		                                           , SYSDATE      
		                                           , gn_user_id         
		                                           , SYSDATE   
		                                           , gn_user_id    
		                                           , gn_login_id  
		                                           , l_penny_detail_tab(indx).error_message      
		                                           , l_penny_detail_tab(indx).process_flag       
		                                           );
			    ln_success_records  := ln_success_records + 1;
			EXCEPTION
			  WHEN OTHERS
			  THEN
				ln_failed_records := ln_failed_records +1;
                gc_error_msg := SUBSTR(sqlerrm,1,100);
			END;
        END LOOP; -- l_penny_detail_tab
	END LOOP; --penny_adj_dtls
    CLOSE penny_adj_dtls;

	FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Staging table Details for Penny Adjustments');
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed for Penny Adjustments :: '||ln_total_records_processed);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Success Records :: '||ln_success_records);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Failed Records :: '||ln_failed_records);
	FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
	
    --=================================================
	  -- Staging the Small Dollar adjustments details 
	--=================================================
	ln_from_amt                := NULL;
	ln_days                    := NULL;
	ln_total_records_processed := 0;
	ln_success_records         := 0;
	ln_failed_records          := 0;
	print_debug_msg('To get the details from the Translation OD_VPS_TRANSLATION for VPS_SMALL_DOLLAR_ADJ_OD',TRUE);
	BEGIN
        SELECT TO_NUMBER(target_value1),
		       TO_NUMBER(target_value2)
	      INTO ln_from_amt,
               ln_days		  
          FROM xx_fin_translatevalues
         WHERE translate_id IN (SELECT translate_id 
          			              FROM xx_fin_translatedefinition 
          			              WHERE translation_name = 'OD_VPS_TRANSLATION' 
          			                AND enabled_flag = 'Y')
           AND source_value1 = 'VPS_SMALL_DOLLAR_ADJ_OD';
    EXCEPTION
    WHEN OTHERS
    THEN
       	ln_from_amt := 1;
		ln_days     := 180;
    END;
	
	print_debug_msg('Start processing all the VPS Small Dollar Adjusments Records',TRUE);  
	OPEN small_dollar_adj_dtls(ln_from_amt,ln_days);
    LOOP
	    l_small_dollar_detail_tab.DELETE;  --- Deleting the data in the Table type
        FETCH small_dollar_adj_dtls BULK COLLECT INTO l_small_dollar_detail_tab LIMIT ln_batch_size;
        EXIT WHEN l_small_dollar_detail_tab.COUNT = 0;
		  
		ln_total_records_processed := ln_total_records_processed + l_small_dollar_detail_tab.COUNT;
		FOR indx IN l_small_dollar_detail_tab.FIRST..l_small_dollar_detail_tab.LAST 
        LOOP
            BEGIN
		        INSERT INTO XX_AR_VPS_ADJ_DTLS_STG ( trx_category       
		                                           , invoice_class      
		                                           , customer_trx_id    
		                                           , transaction_number 
												   , transaction_date
												   , set_of_books_id
												   , vendor_num
												   , payment_schedule_id
		                                           , amount             
		                                           , currency_code      
		                                           , reason_code        
		                                           , comments           
		                                           , adj_activity_name  
		                                           , cust_account_id    
		                                           , cust_acct_number 
                                                   , cust_acct_name												   
		                                           , send_refund        
		                                           , refund_status      
		                                           , trx_status         
		                                           , trx_message        
		                                           , request_id         
		                                           , creation_date      
		                                           , created_by         
		                                           , last_update_date   
		                                           , last_updated_by    
		                                           , last_update_login  
		                                           , error_message      
		                                           , process_flag       
		                                           )
							                VALUES ( l_small_dollar_detail_tab(indx).trx_category         
		                                           , l_small_dollar_detail_tab(indx).invoice_class      
                                                   , l_small_dollar_detail_tab(indx).customer_trx_id    
		                                           , l_small_dollar_detail_tab(indx).transaction_number 
												   , l_small_dollar_detail_tab(indx).transaction_date
												   , l_small_dollar_detail_tab(indx).set_of_books_id
												   , l_small_dollar_detail_tab(indx).vendor_num
												   , l_small_dollar_detail_tab(indx).payment_schedule_id
		                                           , l_small_dollar_detail_tab(indx).amount             
		                                           , l_small_dollar_detail_tab(indx).currency_code      
		                                           , l_small_dollar_detail_tab(indx).reason_code        
		                                           , l_small_dollar_detail_tab(indx).comments           
		                                           , l_small_dollar_detail_tab(indx).adj_activity_name  
		                                           , l_small_dollar_detail_tab(indx).cust_account_id    
		                                           , l_small_dollar_detail_tab(indx).cust_acct_number
                                                   , l_small_dollar_detail_tab(indx).cust_acct_name												   
		                                           , l_small_dollar_detail_tab(indx).send_refund        
		                                           , l_small_dollar_detail_tab(indx).refund_status      
		                                           , l_small_dollar_detail_tab(indx).trx_status         
		                                           , l_small_dollar_detail_tab(indx).trx_message        
		                                           , gn_request_id         
		                                           , SYSDATE      
		                                           , gn_user_id         
		                                           , SYSDATE   
		                                           , gn_user_id    
		                                           , gn_login_id  
		                                           , l_small_dollar_detail_tab(indx).error_message      
		                                           , l_small_dollar_detail_tab(indx).process_flag       
		                                           );
			    ln_success_records  := ln_success_records + 1;
			EXCEPTION
			  WHEN OTHERS
			  THEN
				ln_failed_records := ln_failed_records +1;
                gc_error_msg := SUBSTR(sqlerrm,1,100);
			END;
        END LOOP; -- l_small_dollar_detail_tab
	END LOOP; --small_dollar_adj_dtls
    CLOSE small_dollar_adj_dtls;
	--========================================================================
		-- Updating the OUTPUT FILE
	--========================================================================
	FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Staging table Details for Small Dollar Adjustments:');
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed for Small Dollar Adjustments :: '||ln_total_records_processed);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Success Records :: '||ln_success_records);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Failed Records :: '||ln_failed_records);
	FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
	
EXCEPTION
WHEN OTHERS
THEN
    ROLLBACK;				   
	p_retcode   := '2';
    fnd_file.put_line(fnd_file.log,'Error Message :'||gc_error_msg); 
    gc_error_msg := substr(sqlerrm,1,250);
    print_debug_msg ('XX_AR_VPS_ADJUSTMENTS_PKG.stage_vps_adj_dtls - '||gc_error_msg,TRUE);
    log_exception ('XX_AR_VPS_ADJUSTMENTS_PKG.stage_vps_adj_dtls',
	                gc_error_loc,
		            gc_error_msg);
END stage_vps_adj_dtls; 

-- +===================================================================+
-- | Name  : update_error_status_prc                                   |
-- | Description      : This Procedure will update errors flag and     |
-- |                    error message based on above calling api's     |
-- |                                                                   |
-- | Parameters      : p_customer_trx_id  IN -> Customer TRX ID        |
-- |                   p_process_flag     IN -> Process Flag           |
-- |                   p_error_message    IN -> Error message          |
-- |                   p_adjustment_id    IN -> Adjustment ID          |
-- |                   p_adjustment_num   IN -> Adjustment Number      |
-- +===================================================================+
PROCEDURE update_status_prc ( p_customer_trx_id IN NUMBER
                            , p_process_flag    IN VARCHAR2
                            , p_error_message   IN VARCHAR2
							, p_adjustment_id   IN NUMBER
							, p_adjustment_num  IN VARCHAR2
                            ) 
IS
BEGIN	   
	UPDATE xx_ar_vps_adj_dtls_stg
	   SET process_flag = p_process_flag,
		   error_message = p_error_message,
		   adjustment_id = p_adjustment_id,
		   adjustment_number = p_adjustment_num,
		   last_update_date = SYSDATE,
		   last_updated_by = gn_user_id,
		   request_id = gn_request_id
	 WHERE customer_trx_id = p_customer_trx_id;
    COMMIT;
			    
EXCEPTION
    WHEN OTHERS 
	THEN
        fnd_file.put_line(fnd_file.log, 'WHEN OTHERS RAISED in updating error_flag :  '||SQLERRM);
END update_status_prc;	

-- +===================================================================+
-- | Name  : send_email                                                |
-- | Description      : This Procedure is to send the newly created    |
-- |                    adjustments in the email to Business           |
-- +===================================================================+
PROCEDURE send_email 
IS
    CURSOR c_success 
	IS
		SELECT xxstg.vendor_num,
               xxstg.cust_acct_number, 
			   xxstg.cust_acct_name,
               xxstg.transaction_number,
			   xxstg.transaction_date,
               xxstg.adj_activity_name,
               aaa.adjustment_number,
               aaa.type,
               aaa.creation_date,
               aaa.amount			   
		  FROM xx_ar_vps_adj_dtls_stg  xxstg,
		       ar_adjustments_all aaa
		 WHERE xxstg.adjustment_id = aaa.adjustment_id
		   AND xxstg.process_flag = 'C' 
		   AND xxstg.email_status IS NULL
		   AND xxstg.request_id = gn_request_id
          ; 
	
	/* Local Variables */

    lc_conn                   	UTL_SMTP.connection;
    lc_attach_text            	VARCHAR2(32767);
    lc_success_data 			VARCHAR2(32767);
    lc_inv_sum                  VARCHAR2(32767);
    lc_exp_data 				VARCHAR2(32767);
    lc_err_msg         		    VARCHAR2(32767);
    lc_err_nums 				NUMBER := 0;
    lc_mail_from       		    VARCHAR2(100);
    lc_mail_to       			VARCHAR2(100);
    lc_mail_request_id 		    NUMBER;
    lc_body 					BLOB := utl_raw.cast_to_raw('Attached Receipts and Invoices Created in EBS Successfully');
    lc_file_data 				BLOB;
    lc_src_data 				BLOB;
    lc_record 					NUMBER :=1;
    lc_err_msg_cnt 			    NUMBER :=1;
    lc_excp_msg_cnt 			NUMBER :=1;
    lv_invoice_sum              NUMBER;
    lv_row_cnt                  NUMBER := 0;
	lc_instance                 VARCHAR2(10):= NULL;
BEGIN  
    -- To get the To email and From email      
    BEGIN
      SELECT target_value1,target_value2 
	    INTO lc_mail_from,lc_mail_to
        FROM xx_fin_translatedefinition xftd
           , xx_fin_translatevalues xftv
       WHERE xftv.translate_id = xftd.translate_id
         AND xftd.translation_name ='OD_VPS_TRANSLATION'
         AND source_value1 = 'SMALL_DOLLAR_PENNY_ADJ'
         AND NVL (xftv.enabled_flag, 'N') = 'Y';
     
    EXCEPTION          		
	WHEN OTHERS 
	THEN
	    fnd_file.put_line(fnd_file.log,'OD_VPS_TRANSLATION: Not able to Derive Email IDS'||SQLERRM);  
    END;  

    -- To get the instance name
    SELECT SUBSTR(instance_name,4)
	  INTO lc_instance
      FROM V$INSTANCE;	
            
    dbms_lob.createtemporary(lc_file_data, TRUE);
	
    lc_success_data :=chr(13)||chr(10)||'**********************************************************************************'||chr(13)||chr(10); 	
    lc_success_data :=lc_success_data||'OD: AR VPS Small Dollar and Penny Adjustments Job Run on '||to_char(sysdate,'MM/DD/YYYY hh24:mi:ss')||chr(13)||chr(10);
    lc_success_data :=lc_success_data||'**********************************************************************************'||chr(13)||chr(10);
    lc_success_data :=lc_success_data||'Following Adjustments Created in EBS Successfully at '||TO_CHAR(SYSDATE,'MM/DD/YYYY hh24:mi:ss')||CHR(13)||CHR(10); 
    lc_success_data :=lc_success_data||'**********************************************************************************'||chr(13)||chr(10)||chr(13)||chr(10); 
    lc_success_data :=lc_success_data||'VENDOR NUMBER       '
	                                 ||'CUSTOMER NUMBER     '
									 ||'CUSTOMER NAME                           '
									 ||'TRANSACTION NUMBER  '
									 ||'TRANSACTION DATE    '
	                                 ||'ADJUSTMENT NUMBER   '
	                                 ||'ADJUSTMENT TYPE     '
									 ||'ADJUSTMENT DATE     '
									 ||'ADJUSTMENT AMOUNT   '
									 ||'ACTIVITY NAME                 '
									 ||CHR(13)||CHR(10);
    lc_success_data :=lc_success_data||'----------------------------------------------------------------------------------------------------------------------------------------------------------------'
	                                 ||'--------------------------------------------------'||chr(13)||chr(10); 
			  
    lc_record:=1;
          
    FOR r in c_success
	LOOP
        lv_row_cnt := lv_row_cnt + 1;
		IF lc_record=1 
		THEN
			lc_src_data := utl_raw.cast_to_raw(lc_success_data||RPAD(r.vendor_num,20,' ')
			                                                  ||RPAD(r.cust_acct_number,20,' ')
															  ||RPAD(r.cust_acct_name,40,' ')--NAIT-90178 PENNY ADJ REPORT NEEDS TO BE MODIFIED
															  ||RPAD(r.transaction_number,20,' ')
															  ||RPAD(TO_CHAR(r.transaction_date,'DD-MON-YYYY'),20,' ')
															  ||RPAD(r.adjustment_number,20,' ')
															  ||RPAD(r.type,20,' ')
															  ||RPAD(TO_CHAR(r.creation_date,'DD-MON-YYYY'),20,' ')
			                                                  ||RPAD(TO_CHAR(r.amount,'99G999G990D00'),20,' ')
															  ||RPAD(r.adj_activity_name,30,' ')
															  ||chr(13)||chr(10)); 
		ELSE
			lc_src_data := utl_raw.cast_to_raw(  RPAD(r.vendor_num,20,' ')
			                                   ||RPAD(r.cust_acct_number,20,' ')
											   ||RPAD(r.cust_acct_name,40,' ')--NAIT-90178 PENNY ADJ REPORT NEEDS TO BE MODIFIED
											   ||RPAD(r.transaction_number,20,' ')
											   ||RPAD(TO_CHAR(r.transaction_date,'DD-MON-YYYY'),20,' ')
											   ||RPAD(r.adjustment_number,20,' ')
											   ||RPAD(r.type,20,' ')
											   ||RPAD(TO_CHAR(r.creation_date,'DD-MON-YYYY'),20,' ')
			                                   ||RPAD(TO_CHAR(r.amount,'99G999G990D00'),20,' ')
											   ||RPAD(r.adj_activity_name,30,' ')
											   ||chr(13)||chr(10)); 
            
		END IF;
		dbms_lob.append(lc_file_data,lc_src_data); 
		lc_record:= lc_record+1; 
	END LOOP;  
	
    lc_conn := xx_pa_pb_mail.begin_mail(sender             => lc_mail_from,
                                        recipients         => lc_mail_to,
                                        cc_recipients      => NULL,
                                        subject            => 'VPS Small Dollar and Penny Adjustments Details for '||to_char(sysdate,'MM/DD/YYYY hh24:mi:ss')||' - '||lc_instance,
                                        mime_type          => xx_pa_pb_mail.multipart_mime_type
                                       );

                    
    xx_pa_pb_mail.begin_attachment(conn       => lc_conn,
                                   mime_type  => 'text/plain',
                                   inline     => NULL,
                                   filename   => NULL,
                                   transfer_enc => NULL); 
                 
    xx_pa_pb_mail.xx_attch_doc (lc_conn,
                                'VPS Small Dollar and Penny Adjustments Details '||to_char(sysdate,'DD_MON_YYYY')||'.txt',
                                lc_file_data,
                                'text/plain; charset=UTF-8'
                                ); 

    xx_pa_pb_mail.end_attachment (conn => lc_conn);
                 
    xx_pa_pb_mail.end_mail (conn => lc_conn);
	
	fnd_file.put_line(fnd_file.log,'Able to send mail '); 
	
	-- To Update the email status to 'Y'
    UPDATE XX_AR_VPS_ADJ_DTLS_STG
       SET email_status = 'Y'
     WHERE process_flag = 'C'
       AND email_status is NULL
       AND request_id = gn_request_id ;
            
EXCEPTION           
    WHEN OTHERS
    THEN
        fnd_file.put_line(fnd_file.log,'Unable to send mail '||SQLERRM);  
END;

-- +===================================================================+
-- | Name  : CREATE_ADJ_PRC                                            |
-- | Description      : This Procedure will process Adjustment in AR   |
-- |                    based on category = 'ADJUSTMENTS'              |
-- |                                                                   |
-- | Parameters      : p_debug            IN -> Set Debug DEFAULT 'N'  |
-- |                   p_category         IN -> TRX CATEGORY           |
-- |                   p_inp_adj_rec      IN -> Customer TRX ID        |
-- |                   x_new_adjust_number OUT                         |
-- |                   x_new_adjust_id     OUT                         |
-- |                   X_return_status     OUT                         |
-- |                   x_return_message    OUT                         |
-- +===================================================================+
PROCEDURE create_adj_prc( p_debug             IN         VARCHAR2
                        , p_category          IN         VARCHAR2
                        , p_inp_adj_rec       IN         ar_adjustments%ROWTYPE
                        , x_new_adjust_number OUT        VARCHAR2
                        , x_new_adjust_id     OUT        NUMBER
                        , x_return_status     OUT NOCOPY VARCHAR2
                        , x_return_message    OUT NOCOPY VARCHAR2
                        ) 
IS

/* Local Variables */
lc_return_status         VARCHAR2(1);
ln_msg_count             NUMBER;
lc_msg_data              VARCHAR2(2000);
ln_adj_number            VARCHAR2(30);
ln_adj_id                NUMBER;
lc_type                  VARCHAR2(30);
lc_api_msg               VARCHAR2(240);
lc_approver_limit_check  VARCHAR2(1) := FND_API.G_TRUE;
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    /*
    IF p_debug = 'Y'
	THEN
        fnd_file.put_line(fnd_file.log, 'Category  :                '||P_category);
        fnd_file.put_line(fnd_file.log, 'Customer Transaction ID :  '||p_inp_adj_rec.customer_trx_id);
        fnd_file.put_line(fnd_file.log, 'Amount :                   '||p_inp_adj_rec.amount);
    END IF;
    */
	fnd_file.put_line(fnd_file.log,'Processing the Transaction ID :'||p_inp_adj_rec.customer_trx_id ||' to create the adjustment for');
    ar_adjust_pub.create_adjustment ( p_api_name             => 'XX_AR_VPS_ADJUSTMENTS_PKG'
                                    , p_api_version          => 1.0
                                    , p_init_msg_list        => FND_API.G_TRUE
                                    , p_commit_flag	         => FND_API.G_TRUE
                                    , p_validation_level     => FND_API.G_VALID_LEVEL_FULL
                                    , p_msg_count            => ln_msg_count
                                    , p_msg_data             => lc_api_msg
                                    , p_return_status        => lc_return_status
                                    , p_adj_rec              => p_inp_adj_rec
                                    , p_move_deferred_tax    => 'Y'
                                    , p_new_adjust_number    => ln_adj_number
                                    , p_new_adjust_id        => ln_adj_id
                                    , p_called_from          => NULL
                                    , p_old_adjust_id        => NULL
                                   );
	/*
    IF p_debug = 'Y' THEN
        FND_FILE.Put_Line(FND_FILE.LOG, 'lc_return_status            :'||lc_return_status);
        FND_FILE.Put_Line(FND_FILE.LOG, 'lc_msg_data                 :'||lc_msg_data);
        FND_FILE.Put_Line(FND_FILE.LOG, 'ln_adj_number               :'||ln_adj_number);
        FND_FILE.Put_Line(FND_FILE.LOG, 'ln_adj_id                   :'||ln_adj_id);
    END IF;
    */

    IF lc_return_status = 'S' OR ln_adj_number IS NOT NULL
	THEN
        x_new_adjust_number := ln_adj_number;
        x_new_adjust_id     := ln_adj_id;

    ELSE
        IF lc_msg_data IS NOT NULL THEN
            lc_msg_data      := lc_msg_data || chr(10);
        END IF;
        IF ln_msg_count >= 1 THEN
            FOR I IN 1..ln_msg_count LOOP
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_api_msg : '|| lc_api_msg);
                FND_FILE.PUT_LINE(FND_FILE.LOG,(I||'. '||SUBSTR(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255)));
                IF i = 1 THEN
                    lc_api_msg := I||'. '||SUBSTR(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                END IF;
            END LOOP;
        END IF;
        lc_msg_data      := lc_msg_data || lc_api_msg ||' : '|| p_inp_adj_rec.customer_trx_id;
        x_return_message := SUBSTR(lc_msg_data,1,1999);
    END IF;
    x_return_status := lc_return_status;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED in create_adj_prc :  '||SQLERRM);
        x_return_status  := FND_API.G_RET_STS_ERROR;
        x_return_message := 'WHEN OTHERS RAISED in create_adj_prc :  '||SQLERRM;

END create_adj_prc;	
    
-- +============================================================================================+
-- | Name  : main_prc                                                                           |
-- | Description      : This is the main procedure to create and approve the VPS Penny and Small|
-- |                    Dollar Adjustments                                                      |
-- |                                                                                            |
-- | Parameters       : p_retcode     OUT                                                       |
-- |                    p_errbuf      OUT                                                       |
-- |                    p_debug       IN  -> Set Debug DEFAULT 'N'                              |
-- +============================================================================================+
PROCEDURE main_prc( p_retcode        OUT NOCOPY  NUMBER
                   ,p_errbuf         OUT NOCOPY  VARCHAR2                 
                   ,p_debug          IN          VARCHAR2  DEFAULT 'N'
				   )
AS
    -- Cursor to process the error records
    CURSOR process_err_records
	IS
	  SELECT *
	    FROM xx_ar_vps_adj_dtls_stg
	   WHERE process_flag = 'E';
	
    -- Cursor to process the new records    	
    CURSOR process_new_records
	IS
	  SELECT *
	    FROM xx_ar_vps_adj_dtls_stg
	   WHERE process_flag = 'N';
		 
    -- Cursor to get the Small Dollar and Penny Adjustments 
    CURSOR email_details
    IS
	    SELECT *
	      FROM xx_ar_vps_adj_dtls_stg
	     WHERE request_id = gn_request_id
	       AND process_flag = 'C';
	
	/* Local Variables */
	lc_err_buf             VARCHAR2(2000) := NULL;
	lc_ret_code            NUMBER         := NULL;
	ln_cnt                 NUMBER         := 0;
	ln_adj_count           NUMBER         := 0;
	ln_adj_s_count         NUMBER         := 0;
	ln_adj_f_count         NUMBER         := 0;
	lr_inp_adj_rec	       ar_adjustments%ROWTYPE;
	ln_adjustment_id       NUMBER         := NULL;
	lc_adjustment_number   VARCHAR2(100)  := NULL;
	lc_return_status       VARCHAR2(100)  := NULL;
	lc_return_message      VARCHAR2(2000) := NULL;
	ln_rec_trx_id          NUMBER         := NULL;
	data_exception         EXCEPTION;
	ln_approver_id         NUMBER         := NULL;
	lc_user_name           VARCHAR2(30)   := '749240'; -- Katitza User Name
	ln_resp_id             NUMBER;
	ln_appl_id             NUMBER; 
	v_msg_count            NUMBER(4); 
    v_msg_data             VARCHAR2(2000); 
    v_return_status        VARCHAR2(5); 
	ln_record_count        NUMBER         := 0;

BEGIN
    gc_debug	  := p_debug;
    gn_request_id := fnd_global.conc_request_id;
    gn_user_id    := fnd_global.user_id;
    gn_login_id   := fnd_global.login_id;
	
	fnd_file.put_line(fnd_file.log,'Begining of the Program');
	
	-- Call the stage_vps_adj_dtls procedure to stage all the VPS Penny and Small Dollar Adjustments details to Staging table
	stage_vps_adj_dtls(lc_err_buf,lc_ret_code,gc_debug);
	IF lc_ret_code = '2'
	THEN
	    fnd_file.put_line(fnd_file.log,'Error while inserting the data into staging table xx_ar_vps_adj_dtls_stg');
		RAISE data_exception;
	END IF;
	
	-- Process the error records and to change the process_flag status to 'N'
	fnd_file.put_line(fnd_file.log,'Processing the Error Records');
	FOR i IN process_err_records
	LOOP
	    BEGIN
		    -- To check whether the Adjustment is created for the transaction 
		    BEGIN
			     ln_cnt := 0;
	             SELECT COUNT(1),adjustment_id, adjustment_number
		           INTO ln_cnt, ln_adjustment_id, lc_adjustment_number
		           FROM ar_adjustments_all
		          WHERE customer_trx_id = i.customer_trx_id
			        AND status = 'A'
				  GROUP BY adjustment_id, adjustment_number;
				  
		    EXCEPTION
		    WHEN OTHERS
		    THEN
		        ln_cnt := 0;
		    END;
			
			IF ln_cnt > 0
			THEN
				 
				update_status_prc ( p_customer_trx_id => i.customer_trx_id
                                  , p_process_flag    => 'C'
                                  , p_error_message   => 'Adjustment is Created'
							      , p_adjustment_id   => ln_adjustment_id
							      , p_adjustment_num  => lc_adjustment_number
                                  );
			ELSE
				 
				update_status_prc ( p_customer_trx_id => i.customer_trx_id
                                  , p_process_flag    => 'N'
                                  , p_error_message   => NULL
							      , p_adjustment_id   => NULL
							      , p_adjustment_num  => NULL
                                  );
			END IF;
	    EXCEPTION
		WHEN OTHERS
		THEN
		    fnd_file.put_line(fnd_file.log,'Unable to process the error records from the staging table');
		END;
	END LOOP;
	
	-- Process the new records from the staging table which has process flag as 'N'
	
	fnd_file.put_line(fnd_file.log,'Processing the New Records');
	fnd_file.put_line(fnd_file.OUTPUT, 'BEGINNING OF PROGRAM TO PROCESS THE NEW RECORDS');
    FOR j IN process_new_records 
	LOOP
        lc_return_status  := NULL;
		lc_return_message := NULL;
		
		ln_adj_count := ln_adj_count + 1;

        IF p_debug = 'Y' 
		THEN
		    fnd_file.put_line(fnd_file.log, CHR(10));
            fnd_file.put_line(fnd_file.log, 'Transaction Category :     '||j.trx_category);
            fnd_file.put_line(fnd_file.log, 'Transaction ID:            '||j.customer_trx_id);
			fnd_file.put_line(fnd_file.log, 'Transaction Number:        '||j.transaction_number);
            fnd_file.put_line(fnd_file.log, 'Amount:                    '||j.amount);           
            fnd_file.put_line(fnd_file.log, 'Adjustment Activity Name:  '||j.adj_activity_name);
        END IF;
		
		/* Derive receivable trx id */
        BEGIN
            SELECT receivables_trx_id
              INTO ln_rec_trx_id
              FROM ar_receivables_trx_all
             WHERE UPPER(NAME) = UPPER(j.adj_activity_name);
        EXCEPTION
            WHEN NO_DATA_FOUND 
			THEN
                fnd_file.put_line(fnd_file.log, 'NO Data Found for AR Receivable Trx Name :   '||j.adj_activity_name);
                lc_return_status  := FND_API.G_RET_STS_ERROR;
                lc_return_message := 'NO Data Found for AR Receivable Trx Name :   '||j.adj_activity_name;
                ln_rec_trx_id    := NULL;
            WHEN OTHERS 
			THEN
                fnd_file.put_line(fnd_file.log, 'WHEN OTHERS RAISED while deriving data from AR Receivable Trx Name :  '||SQLERRM);
                lc_return_status  := FND_API.G_RET_STS_ERROR;
                lc_return_message := 'WHEN OTHERS RAISED while deriving data from AR Receivable Trx Name :  '||SQLERRM;
                ln_rec_trx_id    := NULL;
        END;
				
		/* To get the Approver ID */
		BEGIN
            SELECT user_id 
			  INTO ln_approver_id
              FROM fnd_user fu
             WHERE user_name = lc_user_name
               AND EXISTS ( SELECT 1 
			                  FROM ar_approval_user_limits aa
                             WHERE aa.user_id = fu.user_id
                               AND aa.document_type = 'ADJ'
                          );
        EXCEPTION
        WHEN NO_DATA_FOUND
		THEN
            fnd_file.put_line(fnd_file.log, 'NO Data Found for ADJ Approver : '||lc_user_name);
            lc_return_status := FND_API.G_RET_STS_ERROR;
            lc_return_message := 'NO Data Found for ADJ Approver : '||lc_user_name ;
        WHEN OTHERS
		THEN
            fnd_file.put_line(fnd_file.log, 'WHEN OTHERS RAISED in deriving ADJ Approver :  '||SQLERRM);
            lc_return_status := FND_API.G_RET_STS_ERROR;
            lc_return_message := 'WHEN OTHERS RAISED in deriving ADJ Approver :  '||SQLERRM;
        END;
		
		ln_resp_id := fnd_global.resp_id;
        ln_appl_id := fnd_global.resp_appl_id;
        FND_GLOBAL.APPS_INITIALIZE(ln_approver_id,ln_resp_id,ln_appl_id);
		
		lr_inp_adj_rec.acctd_amount         := (-1 * j.amount);
        lr_inp_adj_rec.adjustment_id        := NULL;
        lr_inp_adj_rec.adjustment_number    := NULL;
        lr_inp_adj_rec.adjustment_type      := 'M';        --Manual
        lr_inp_adj_rec.amount               := (-1 * j.amount);
        lr_inp_adj_rec.created_by           := ln_approver_id; -- FND_GLOBAL.USER_ID; 
        lr_inp_adj_rec.created_from         := 'ADJ-API';
        lr_inp_adj_rec.creation_date        := SYSDATE;
        lr_inp_adj_rec.gl_date              := SYSDATE;
        lr_inp_adj_rec.last_update_date     := SYSDATE;
        lr_inp_adj_rec.last_updated_by      := ln_approver_id; -- FND_GLOBAL.USER_ID; 
        lr_inp_adj_rec.posting_control_id   := -3;
        lr_inp_adj_rec.set_of_books_id      := j.set_of_books_id;
        lr_inp_adj_rec.status               := 'A';
        lr_inp_adj_rec.type                 := 'INVOICE' ;     /* ADJ TYPE CHARGES,FREIGHT,INVOICE,LINE,TAX */
        lr_inp_adj_rec.payment_schedule_id  := j.payment_schedule_id;   --Derive from ar_payment_schedules_all
        lr_inp_adj_rec.apply_date           := SYSDATE;
        lr_inp_adj_rec.receivables_trx_id   := ln_rec_trx_id;
        lr_inp_adj_rec.attribute1           := NULL;   
        lr_inp_adj_rec.customer_trx_id      := j.customer_trx_id;   -- Invoice ID for which adjustment is made
        lr_inp_adj_rec.comments             := j.comments;
        lr_inp_adj_rec.reason_code          := j.reason_code;
        lr_inp_adj_rec.approved_by          := ln_approver_id; -- Defect# 21756

        create_adj_prc( p_debug             => p_debug
                      , p_category          => j.trx_category
					  , p_inp_adj_rec       => lr_inp_adj_rec
                      , x_new_adjust_number => lc_adjustment_number
                      , x_new_adjust_id     => ln_adjustment_id
                      , x_return_status     => lc_return_status
                      , x_return_message    => lc_return_message
                      );

        IF p_debug = 'Y' 
		THEN
            fnd_file.put_line(fnd_file.log, 'Adjustment Number:  '||lc_adjustment_number);
            fnd_file.put_line(fnd_file.log, 'Adjustment ID:      '||ln_adjustment_id);
            fnd_file.put_line(fnd_file.log, 'Return Status:      '||lc_return_status);
            fnd_file.put_line(fnd_file.log, 'Return Message:     '||lc_return_message);
        END IF;
		
		fnd_file.put_line(fnd_file.log, 'ADJ CALL '||lc_return_message);
		
		IF lc_return_status != 'S'
		THEN
            update_status_prc ( p_customer_trx_id => j.customer_trx_id
                              , p_process_flag    => 'E'
                              , p_error_message   => lc_return_message
							  , p_adjustment_id   => ln_adjustment_id
							  , p_adjustment_num  => lc_adjustment_number
                              ); 

                ln_adj_f_count := ln_adj_f_count + 1;
        ELSE 
		/*
		    AR_ADJUST_PUB.Approve_Adjustment( 
                                             p_api_name => 'AR_ADJUST_PUB', 
                                             p_api_version => 1.0, 
                                             p_msg_count => v_msg_count , 
                                             p_msg_data => v_msg_data, 
                                             p_return_status => v_return_status, 
                                             p_adj_rec => lr_inp_adj_rec, 
                                             p_old_adjust_id => ln_adjustment_id
				                            ); 
											
			
            IF v_return_status = 'S' 
			THEN											
                update_status_prc ( p_customer_trx_id => j.customer_trx_id
                                  , p_process_flag    => 'C'
                                  , p_error_message   => 'Adjustment is Created'
			    				  , p_adjustment_id   => ln_adjustment_id
			    				  , p_adjustment_num  => lc_adjustment_number
                                  );
                    ln_adj_s_count := ln_adj_s_count + 1;
			ELSE
			    update_status_prc ( p_customer_trx_id => j.customer_trx_id
                                  , p_process_flag    => 'E'
                                  , p_error_message   => lc_return_message
							      , p_adjustment_id   => ln_adjustment_id
							      , p_adjustment_num  => lc_adjustment_number
                                  ); 

                ln_adj_f_count := ln_adj_f_count + 1;
				IF p_debug = 'Y' 
		        THEN
                    fnd_file.put_line(fnd_file.log, 'Customer Trx ID:  '||j.customer_trx_id);
                    fnd_file.put_line(fnd_file.log, 'Return Status:    '||v_return_status);
                    fnd_file.put_line(fnd_file.log, 'Return Message:   '||v_msg_data);
                END IF;
			END IF;
		*/
            update_status_prc ( p_customer_trx_id => j.customer_trx_id
                                      , p_process_flag    => 'C'
                                      , p_error_message   => 'Adjustment is Created'
		    	    				  , p_adjustment_id   => ln_adjustment_id
		    	    				  , p_adjustment_num  => lc_adjustment_number
                                      );
            ln_adj_s_count := ln_adj_s_count + 1;	    
        END IF;
				
	END LOOP;
	COMMIT;
	
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of ADJ Transactions:            '|| ln_adj_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Successfully Processed Transactions:   ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of ADJ Transactions Processed : '|| ln_adj_s_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Failed to Process Transactions:        ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of ADJ Transactions Failed :    '|| ln_adj_f_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'END  OF PROGRAM');
	
    -- Call the send email procedure to send an email
	BEGIN 
	    SELECT COUNT(1) 
	      INTO ln_record_count
          FROM xx_ar_vps_adj_dtls_stg
         WHERE request_id = gn_request_id
	       AND process_flag = 'C'
	       AND email_status IS NULL;
	EXCEPTION
	WHEN OTHERS
	THEN
	    ln_record_count := 0;
	END;
      
    IF ln_record_count >= 1
	THEN 
       send_email;
    ELSE
       fnd_file.put_line(fnd_file.log,'No Records processed');
    END IF;  
	
EXCEPTION
WHEN data_exception
THEN	
	p_retcode := 2;
	fnd_file.put_line(fnd_file.log,'Error Message :'||SQLERRM);	
WHEN OTHERS
THEN	
	p_retcode := 2;
	fnd_file.put_line(fnd_file.log,'Error Message :'||SQLERRM);	
END main_prc; 
 
END XX_AR_VPS_ADJUSTMENTS_PKG;
/
SHOW ERRORS;