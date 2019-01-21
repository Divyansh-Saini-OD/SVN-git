create or replace PACKAGE BODY XX_AR_RECALC_BILL_DATE_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_AR_RECALC_BILL_DATE_PKG                                                      |
-- |  RICE ID 	 : I3126      			                                                        |
-- |  Description:         								                                        |
-- |  Change Record:                                                                            |      
-- +============================================================================================+
-- | Version     Date         Author          Remarks                                           |
-- | =========   ===========  =============   ==================================================|
-- | 1.0         18-OCT-2018  Havish Kasina   Initial version                                   |  
-- | 1.1         21-JAN-2019  Havish Kasina   Added new parameter p_billing_date                |
-- +============================================================================================+

gc_debug 	                VARCHAR2(2);
gn_request_id               fnd_concurrent_requests.request_id%TYPE;
gn_user_id                  fnd_concurrent_requests.requested_by%TYPE;
gn_login_id    	            NUMBER;

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
			    ,p_module_name             => 'AR'
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

-- +============================================================================================+
-- |  Name	 : print_debug_msg                                                                  |
-- |  Description: Procedure used to log based on gb_debug value or if p_force is TRUE. Will log|
-- |               to dbms_output if request id is not set,else will log to concurrent program  |
-- |               log file. Will prepend timestamp to each message logged. This is useful for  |
-- |               determining elapse times                                                     |
-- =============================================================================================|
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
            print_debug_msg (lc_message);
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS
    THEN
        NULL;
END print_debug_msg;

-- +============================================================================================+
-- |  Name	 : print_out_msg                                                                    |
-- |  Description: Procedure used to out the text to the concurrent program. Will log to        |
-- |               dbms_output if request id is not set,else will log to concurrent program     |
-- |               output file.                                                                 |
-- =============================================================================================|
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

-- +==========================================================================================================+
-- |  Name	 : update_new_bill_date                                                                           |                 	
-- |  Description: This procedure is to update the new billing date for the Bill complete transactions        |
-- ===========================================================================================================|
PROCEDURE update_new_bill_date(p_errbuf         OUT  VARCHAR2
                              ,p_retcode        OUT  VARCHAR2
                              ,p_debug          IN   VARCHAR2
							  ,p_billing_date   IN   VARCHAR2)
AS 
  /* Declaration */
  CURSOR get_bill_signal_trx_dtls
  IS
    SELECT rct.billing_date,
           rct.bill_to_site_use_id, 
           rct.bill_to_customer_id, 
	       rct.term_id,
	       rct.term_due_date,
		   rct.trx_number,
		   rct.customer_trx_id,
		   xsbs.child_order_number,
		   xsbs.billing_date_flag,
		   NULL due_date,
		   xsbs.error_message
      FROM ra_customer_trx_all rct,
           xx_scm_bill_signal xsbs
     WHERE xsbs.billing_date_flag = 'N'
       AND rct.trx_number = xsbs.child_order_number;
	   
  TYPE trx_details IS TABLE OF get_bill_signal_trx_dtls%ROWTYPE
  INDEX BY PLS_INTEGER;
  
  l_trx_dtls_tab              trx_details;
  indx                 	      NUMBER;
  ln_batch_size		          NUMBER := 250;
  lc_error_loc                VARCHAR2(100) := 'XX_AR_RECALC_BILL_DATE_PKG.update_new_bill_date';   
  lc_error_msg                VARCHAR2(1000);
  lc_errcode                  VARCHAR2(100);	
  ln_err_count		          NUMBER;
  ln_error_idx		          NUMBER;
  ln_total_records_processed  NUMBER;
  ln_success_records          NUMBER;
  ln_failed_records           NUMBER;
  ln_cust_account_id          hz_cust_accounts.cust_account_id%TYPE;  
  lc_account_number           hz_cust_accounts.account_number%TYPE;
  lc_cycle_name               ar_cons_bill_cycles_tl.cycle_name%TYPE;
  ln_billing_cycle_id         ar_cons_bill_cycles_tl.billing_cycle_id%TYPE;
  ld_billing_date             ra_customer_trx_all.billing_date%TYPE;
  ld_new_due_date             ra_customer_trx_all.billing_date%TYPE;
  ld_new_bill_date            ra_customer_trx_all.term_due_date%TYPE;
    
BEGIN
   gc_debug	                  := p_debug;
   gn_request_id              := fnd_global.conc_request_id;
   gn_user_id                 := fnd_global.user_id;
   gn_login_id                := fnd_global.login_id; 
   ln_total_records_processed := 0;
   ln_success_records         := 0;
   ln_failed_records          := 0;
   
   print_debug_msg ('Input Parameters' ,TRUE);
   print_debug_msg ('Debug Flag :'|| gc_debug ,TRUE);
   print_debug_msg ('Billing Date :'||p_billing_date, TRUE);
   print_debug_msg ('                  ',TRUE);
   print_debug_msg ('Processing the Eligible Transactions',FALSE);
   
   OPEN get_bill_signal_trx_dtls;
   LOOP
	    l_trx_dtls_tab.DELETE;  --- Deleting the data in the Table type
        FETCH get_bill_signal_trx_dtls BULK COLLECT INTO l_trx_dtls_tab;
        EXIT WHEN l_trx_dtls_tab.COUNT = 0;
		    
		ln_total_records_processed := ln_total_records_processed + l_trx_dtls_tab.COUNT;
		print_debug_msg('Total number of Records :'||ln_total_records_processed);
		
		FOR indx IN l_trx_dtls_tab.FIRST..l_trx_dtls_tab.LAST 
        LOOP
		print_debug_msg('                          ');
		print_debug_msg('Processing Trx Number :'||l_trx_dtls_tab(indx).trx_number);
        BEGIN 
		   ln_cust_account_id   := NULL;
		   lc_account_number    := NULL; 
		   lc_cycle_name        := NULL;   
		   ln_billing_cycle_id  := NULL;
		   ld_billing_date      := NULL;
		   ld_new_due_date      := NULL;
		   ld_new_bill_date     := NULL; 
		   ----------------------------------------------------------------------------
		   /* Step 1: To get the billing cycle id */
		   ----------------------------------------------------------------------------
           BEGIN
		       SELECT hca.cust_account_id ,
                      hca.account_number , 
	                  acbct.cycle_name , 
	                  acbct.billing_cycle_id
				 INTO ln_cust_account_id,
					  lc_account_number,
					  lc_cycle_name,
					  ln_billing_cycle_id
                 FROM ar_cons_bill_cycles_tl acbct,
	                  ar_cons_bill_cycle_dates acbcd,
	                  ra_terms rt,
	                  hz_customer_profiles hcp ,
	                  hz_cust_accounts hca 
                WHERE 1 = 1              
                  AND acbcd.billing_cycle_id = rt.billing_cycle_id
                  AND acbcd.billing_cycle_id = acbct.billing_cycle_id
                  AND acbct.language = 'US'
                  AND rt.Term_Id = hcp.standard_Terms
                  AND HCP.site_use_id IS NULL
                  AND HCP.cons_inv_flag = 'Y' 
                  AND EXISTS ( SELECT 1
                                 FROM hz_cust_acct_sites_all hcasa
                                WHERE hcasa.cust_account_id = hca.cust_account_id
                                --  AND hcasa.org_id = hca.org_id
							 )
                  AND hcp.cust_account_id = hca.cust_account_id
                  AND hca.cust_Account_id = l_trx_dtls_tab(indx).bill_to_customer_id 
                GROUP BY hca.cust_account_id ,
                         hca.account_number , 
		                 acbct.cycle_name , 
		                 acbct.billing_cycle_id; 
		   EXCEPTION
			   WHEN TOO_MANY_ROWS
	           THEN 
				   SELECT hca.cust_account_id ,
                          hca.account_number , 
	                      acbct.cycle_name , 
	                      acbct.billing_cycle_id
					 INTO ln_cust_account_id,
						  lc_account_number,
						  lc_cycle_name,
						  ln_billing_cycle_id
                     FROM ar_cons_bill_cycles_tl acbct,
	                      ar_cons_bill_cycle_dates acbcd,
	                      ra_terms rt,
	                      hz_customer_profiles hcp ,
	                      hz_cust_accounts hca 
                    WHERE 1 = 1              
                      AND acbcd.billing_cycle_id = rt.billing_cycle_id
                      AND acbcd.billing_cycle_id = acbct.billing_cycle_id
                      AND acbct.language = 'US'
                      AND rt.Term_Id = hcp.standard_Terms
                      AND HCP.site_use_id IS NULL
                      AND HCP.cons_inv_flag = 'Y' 
                      AND EXISTS ( SELECT 1
                                     FROM hz_cust_acct_sites_all hcasa
                                    WHERE hcasa.cust_account_id = hca.cust_account_id
                                      AND hcasa.org_id = hca.org_id)
                      AND hcp.cust_account_id = hca.cust_account_id
                      AND hca.cust_Account_id = l_trx_dtls_tab(indx).bill_to_customer_id 
					  AND ROWNUM = 1;
						 
		       WHEN OTHERS
			   THEN
				    ln_cust_account_id  := NULL;
					lc_account_number   := NULL;
					lc_cycle_name       := NULL;
					ln_billing_cycle_id := NULL;
		   END;
		   
		   print_debug_msg('Cust account ID :'||ln_cust_account_id);
		   print_debug_msg('Cust account Number :'||lc_account_number);
		   print_debug_msg('Cycle Name :'||lc_cycle_name);
		   print_debug_msg('Billing Cycle ID :'||ln_billing_cycle_id);
		   
		   ----------------------------------------------------------------------------
		   /* Step 2: To get the last bill date */
		   ----------------------------------------------------------------------------
		   print_debug_msg('Cust account Site use ID :'||l_trx_dtls_tab(indx).bill_to_site_use_id);
		   BEGIN
		     SELECT MAX(NVL(billing_date,cut_off_date))
			   INTO ld_billing_date
               FROM ar_cons_inv_all ci1
              WHERE ci1.site_use_id   = l_trx_dtls_tab(indx).bill_to_site_use_id 
                AND ci1.currency_code = 'USD'
                AND (ci1.status IN ('ACCEPTED', 'FINAL')
                AND NVL(ci1.billing_date,ci1.cut_off_date)  = (SELECT MAX(nvl(ci2.billing_date,ci2.cut_off_date))
                                                                 FROM ar_cons_inv_all ci2
                                                                WHERE ci2.site_use_id   = l_trx_dtls_tab(indx).bill_to_site_use_id 
                                                                  AND ci2.currency_code = 'USD'
                                                                  AND ci2.status IN ('ACCEPTED', 'FINAL'))
                     OR (ci1.status = 'MERGE_PENDING'
                         AND NVL(ci1.billing_date,ci1.cut_off_date) <= TRUNC(SYSDATE)
			            )
	                );
		   EXCEPTION
		        WHEN OTHERS
		        THEN
		            ld_billing_date := l_trx_dtls_tab(indx).billing_date;
		   END;
		   IF ld_billing_date IS NULL
		   THEN
		       ld_billing_date := l_trx_dtls_tab(indx).billing_date;
		   END IF;
		   print_debug_msg('Billing Date :'||ld_billing_date);
		   
		   ----------------------------------------------------------------------------
		   /* Step 3: To derive the new BILLING date */
		   ----------------------------------------------------------------------------
		   IF p_billing_date IS NULL
		   THEN
		       BEGIN
		            SELECT MAX(billable_date)
                      INTO ld_new_bill_date
                      FROM ar_cons_bill_cycle_dates
                     WHERE billing_cycle_id = ln_billing_cycle_id
                       AND billable_date BETWEEN  TRUNC(ld_billing_date) AND TRUNC(SYSDATE);
					-- print_debug_msg('p_billing_date - Test 1');
		       EXCEPTION
		       WHEN OTHERS
		       THEN
		           ld_new_bill_date := NULL;
				   -- print_debug_msg('p_billing_date - Test 2');
		       END;
		   ELSE
		       print_debug_msg('p_billing_date :'||p_billing_date);
		       BEGIN
		            SELECT MAX(billable_date)
                      INTO ld_new_bill_date
                      FROM ar_cons_bill_cycle_dates
                     WHERE billing_cycle_id = ln_billing_cycle_id
                       AND billable_date BETWEEN  TRUNC(ld_billing_date) AND TRUNC(TO_DATE(p_billing_date,'DD-MON-YYYY'));
				-- print_debug_msg('p_billing_date - Test 3');
		       EXCEPTION
		       WHEN OTHERS
		       THEN
			       -- print_debug_msg('p_billing_date - Test 4');
		           ld_new_bill_date := TO_DATE(p_billing_date,'DD-MON-YYYY');
		       END;
		   END IF;
		   
		   IF ld_new_bill_date IS NULL
		   THEN
		       SELECT MAX(billable_date)
                 INTO ld_new_bill_date
                 FROM ar_cons_bill_cycle_dates
                WHERE billing_cycle_id = ln_billing_cycle_id
                  AND billable_date <= TRUNC(SYSDATE);
				-- print_debug_msg('p_billing_date - Test 5');
			END IF;
		   print_debug_msg('New Billing Date :'||ld_new_bill_date);
		   
		   ----------------------------------------------------------------------------
		   /* Step 4: To derive the new DUE date */
		   ----------------------------------------------------------------------------		     
		   l_trx_dtls_tab(indx).billing_date := NVL(ld_new_bill_date,l_trx_dtls_tab(indx).billing_date);
		   print_debug_msg('New Billing Date1 :'||l_trx_dtls_tab(indx).billing_date);
		   
		   ld_new_due_date := ar_bfb_utils_pvt.get_due_date(l_trx_dtls_tab(indx).billing_date, l_trx_dtls_tab(indx).term_id);
		   print_debug_msg('Due Date :'||ld_new_due_date);
		   
		   l_trx_dtls_tab(indx).due_date := NVL(ld_new_due_date,l_trx_dtls_tab(indx).term_due_date);
		   print_debug_msg('Due Date1 :'||l_trx_dtls_tab(indx).due_date);
		   
		   ln_success_records  := ln_success_records + 1;
		   l_trx_dtls_tab(indx).billing_date_flag := 'C';
           l_trx_dtls_tab(indx).error_message := NULL;
		   print_debug_msg('Sucess Records :'||ln_success_records); 
		EXCEPTION
		WHEN OTHERS
		THEN
			ln_failed_records := ln_failed_records +1;
            lc_error_msg := SUBSTR(sqlerrm,1,255);
            print_debug_msg ('Customer_Trd_id=['||to_char(l_trx_dtls_tab(indx).customer_trx_id)||'], RB, '||lc_error_msg,FALSE);
            l_trx_dtls_tab(indx).billing_date_flag := 'E';
            l_trx_dtls_tab(indx).error_message :='Unable to get the new bill date for the customer_trx_id :'||l_trx_dtls_tab(indx).customer_trx_id||' '||lc_error_msg;
			print_debug_msg('Failed Records :'||ln_failed_records); 
			print_debug_msg('Error Message :'||l_trx_dtls_tab(indx).error_message); 
        END;
        END LOOP; -- l_trx_dtls_tab		
		
		BEGIN
	        print_debug_msg('Starting update of xx_scm_bill_signal #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
	       	--FORALL indx IN 1..l_trx_dtls_tab.COUNT
	       	--SAVE EXCEPTIONS
			FOR indx IN 1..l_trx_dtls_tab.COUNT
			LOOP
			    
			-- update AR_PAYMENT_SCHEDULES_ALL			
			    UPDATE ar_payment_schedules_all
                   SET due_date = l_trx_dtls_tab(indx).due_date
                 WHERE customer_trx_id = l_trx_dtls_tab(indx).customer_trx_id;
				 
			 -- update RA_CUSTOMER_TRX_ALL 
			    UPDATE ra_customer_trx_all
			       SET billing_date = l_trx_dtls_tab(indx).billing_date,
                       term_due_date = l_trx_dtls_tab(indx).due_date,
				       last_updated_by = gn_user_id,
				       last_update_date = SYSDATE,
				       last_update_login = gn_login_id
			     WHERE customer_trx_id = l_trx_dtls_tab(indx).customer_trx_id;
			
            -- update XX_SCM_BILL_SIGNAL			
   		        UPDATE xx_scm_bill_signal
	       	       SET billing_date_flag = l_trx_dtls_tab(indx).billing_date_flag,
	       		       error_message = l_trx_dtls_tab(indx).error_message, 
				       customer_id = l_trx_dtls_tab(indx).bill_to_customer_id,
					   site_use_id = l_trx_dtls_tab(indx).bill_to_site_use_id,
	     		       last_update_date  = SYSDATE,
	                   last_updated_by   = gn_user_id,
	                   last_update_login = gn_login_id
	       	     WHERE child_order_number = l_trx_dtls_tab(indx).child_order_number; 
			END LOOP; 					
		    COMMIT;
	        EXCEPTION
	        WHEN OTHERS 
			THEN
	            print_debug_msg('Bulk Exception raised',FALSE);
	            ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
	            FOR i IN 1..ln_err_count
	            LOOP
	               ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
	               lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
	               print_debug_msg('Customer Trx ID =['||to_char(l_trx_dtls_tab(ln_error_idx).customer_trx_id)||'], Error msg=['||lc_error_msg||']',FALSE);
	            END LOOP; -- bulk_err_loop FOR UPDATE
	        END;
	        print_debug_msg('Ending Update of xx_scm_bill_signal #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
		   		   
   END LOOP; --get_bill_signal_trx_dtls
   -- COMMIT;   
   CLOSE get_bill_signal_trx_dtls; -- get_bill_signal_trx_dtls
   
EXCEPTION
WHEN OTHERS
THEN			   
	p_retcode   := '2';
    fnd_file.put_line(fnd_file.log,'Error Message :'||lc_error_msg); 
    lc_error_msg := substr(sqlerrm,1,250);
    print_debug_msg ('XX_AR_RECALC_BILL_DATE_PKG.update_new_bill_date - '||lc_error_msg,TRUE);
    log_exception ('XX_AR_RECALC_BILL_DATE_PKG.update_new_bill_date',
	                lc_error_loc,
		            lc_error_msg); 
END update_new_bill_date;

END XX_AR_RECALC_BILL_DATE_PKG;
/
SHOW ERRORS;