		SET SHOW OFF
		SET VERIFY OFF
		SET ECHO OFF
		SET TAB OFF
		SET FEEDBACK OFF
		SET TERM ON

		PROMPT Creating PACKAGE BODY XX_AP_TRIAL_WRAP_PKG


		WHENEVER SQLERROR CONTINUE

		create or replace
		PACKAGE BODY XX_AP_TRIAL_WRAP_PKG AS

		-- +======================================================================================+
		-- |                  Office Depot - Project Simplify                                     |
		-- |                       WIPRO Technologies                                             |
		-- +======================================================================================+
		-- | Name :      OD: AP Trail Balance Report Wrapper - Master                             |
		-- | Description : To perform multi-threading based on Vendor Sites                       |
		-- |                                                                                      |
		-- |                                                                                      |
		-- |                                                                                      |
		-- |Change Record:                                                                        |
		-- |===============                                                                       |
		-- |Version   Date          Author              Remarks                                   |
		-- |=======   ==========   =============        ==========================================|
		-- |1.0       22-DEC-10    RamyaPriya M         Initial version                           |
		-- |1.1		  31-JUL-13    Sheetal Sundaram       R0453- APTrialBalance R12 Retrofit Change |
		-- |1.2		  23-OCT-13    Darshini               R0453- Modified to include the Sub-Ledger |
		-- |                                            tables for Defect# 26047                  |
		-- |1.3       04-NOV-13    Veronica             R0453- Modified for defect # 26028        |
		-- |1.4       26-DEC-13    Jay Gupta            Defect# 27380, Set for all org            |
		-- |1.5       08-JAN-14    Jay Gupta            Calling Child Program once, just commented| 
		-- |                                            loop and condition from main query        |
		-- |                                            search changes with version# 1.5          |
		-- |1.6		  14-MAR-14    Darshini               R0453- Modified to add NVL condition to |
		-- |                                            payment method for defect# 28959          |
		-- |1.7       17-MAR-14    Jay Gupta            Defect# 28991 - Supplier Merge            |
        -- |1.8       04-NOV-15    Harvinder Rakhra     Retroffit R12.2                           |
        -- |1.9       25-FEB-16    Harvinder Rakhra     Defect#37264; Added schema prefix in TRUNCATE Statement |
	    -- |2.0       20-MAR-18    M K Pramod Kumar     Modified to Fix Performance Issue-Removed Child Program call, 
		--												Removed get_posting_status function call.
	    -- |2.1       08-APR-18    M K Pramod Kumar     Added Leading(aiv) Hint in Master Program
		-- +======================================================================================+
			gn_expense VARCHAR2(10) := '20204000';
			gn_trade   VARCHAR2(10) := '20101000';
			 gd_due_date VARCHAR2(14);
		-- +===================================================================+
		-- | Name : XX_VENDOR_SITES_MASTER                                     |
		-- | Description : This Program will collect all the vendor sites      |
		-- |               This program then submits a OD: AP Trial Balance    |
		-- |               Report Wrapper - Child for each of the batches      |
		-- |                                                                   |
		-- | Program "OD: AP Trail Balance Report Wrapper - Master"            |
		-- |                                                                   |
		-- | Parameters :                                                      |
		-- |                                                                   |
		-- |   Returns  : x_error_buff,x_ret_code                              |
		-- +===================================================================+

		PROCEDURE XX_VENDOR_SITES_MASTER (x_error_buff         OUT VARCHAR2
										  ,x_ret_code           OUT NUMBER
										  ,p_batch_size         IN  NUMBER
										  ,p_no_workers         IN  NUMBER
										  )
			AS

		----------------------
		--Variable Declaration
		----------------------
			  ln_batch_size                  NUMBER        := 0;
			  ln_min_site_id                 NUMBER        := 0;
			  ln_max_site_id                 NUMBER        := 0;
			  ln_request_id                  NUMBER        := 0;
			  ln_this_request_id             NUMBER        := FND_GLOBAL.CONC_REQUEST_ID ;
			  lc_request_data                VARCHAR2(4000):= NULL;
			  lc_setup_exception             EXCEPTION;
			  ln_err_cnt                     NUMBER        := 0;
			  ln_wrn_cnt                     NUMBER        := 0;
			  ln_nrm_cnt                     NUMBER        := 0;
			  lc_error_location              VARCHAR2(4000):= NULL;
			  lc_error_debug                 VARCHAR2(4000):= NULL;
			  ln_vendor_site_id_low          NUMBER;
			  ln_vendor_site_id_high         NUMBER;
			  ln_tot_elg_vendor_sites        NUMBER;
			  ln_child_req_id                NUMBER;

			 CURSOR lcu_inv_det(p_ca_org_id    IN NUMBER
							  ,p_us_org_id    IN NUMBER
							  ,p_acc_met_opt  IN VARCHAR2
							  ,p_sacc_met_opt IN VARCHAR2
							  )
			IS
			SELECT  /*+ LEADING(aiv) INDEX(Apss AP_SUPPLIER_SITES_U1) */
					DECODE (SUBSTR(APSS.ATTRIBUTE8 ,1,2),'EX', 'EXPENSE','TR','TRADE' )        LIABILITY 
				   ,NVL(APSS.attribute9,APSS.attribute7)    LEGACY_VENDOR 
				   ,APS.segment1  SUPPLIER_NUMBER 
				   ,APSS.vendor_site_code VENDOR_SITE_CODE 
				   ,APS.vendor_name      VENDOR_NAME 
				   ,FND_GLOBAL.CONC_REQUEST_ID CHILD_REQ_ID
				   ,AIV.invoice_currency_code                                          CURRENCY 
				   ,NVL(to_char(aiv.doc_sequence_value),AIV.voucher_num)                VOUCHER 
				   ,LTRIM(SUBSTR(AIV.attribute7,INSTR(AIV.attribute7,'_',6),10),'_')   SOURCE 
				   ,AIV.invoice_num                                                    INVOICE 
				   ,AIV.invoice_id                                                     INVOICE_ID 
				   ,TO_CHAR(AIV.invoice_date,'MM/DD/YY')                               INV_DATE 
				   ,DECODE(UPPER(NVL(AIV.payment_method_code,AIV.payment_method_lookup_code)),'CHECK','C','EFT','E','WIRE','W','CLEARING','CL')   PAYMENT_METHOD --Modified for defect#28959 
				   ,TRUNC (SYSDATE-AIV.invoice_date)                                   AGED 
				   ,SUM(NVL(XAL.entered_cr,0))                                         ENTERED_CR 
				   ,SUM(NVL(XAL.entered_dr,0))                                         ENTERED_DR 
				   ,DECODE(AIV.Org_id,p_us_org_id,'US',p_ca_org_id,'CA') ||'-'||DECODE (SUBSTR(APSS.ATTRIBUTE8 ,1,2),'EX','EXPENSE','TR','TRADE' )||'-'||AIV.invoice_currency_code ORG_ID
				   ,NULL STATUS
				 FROM  
				    xla_ae_lines xal
				   ,xla_ae_headers xah				   
				   ,xla_transaction_entities xte
				   ,gl_code_combinations gcc
				   ,ap_suppliers aps 
				   ,ap_supplier_sites_all Apss
				   ,ap_invoices_all aiv
 			 WHERE 1=1 
			   AND AIV.payment_status_flag='N'
               AND aiv.cancelled_date IS NULL 
			   AND NVL(AIV.attribute7,'ATTRIBUTE7NULL') NOT IN ('US_OD_RTV_CONSIGNMENT','US_OD_CONSIGN_INV') 
               /*and  exists (select 1 from ap_invoice_distributions_all aida where (p_acc_met_opt = 'Accrual' OR p_sacc_met_opt = 'Accrual')
							and aida.invoice_id=aiv.invoice_id and aida.accrual_posted_flag='Y'
			   union all
			   select 1 from ap_invoice_distributions_all aida where (p_acc_met_opt = 'Cash' OR p_sacc_met_opt = 'Cash')
			  and aida.invoice_id=aiv.invoice_id and aida.cash_posted_flag='Y'
			   ) */
			   --AND apss.vendor_id = aiv.vendor_id 
			   AND apss.vendor_site_id = aiv.vendor_site_id 
			   AND aps.vendor_id = apss.vendor_id 
               --AND aps.vendor_id = aiv.vendor_id
               AND GCC.code_combination_id=AIV.accts_pay_code_combination_id
			   AND GCC.account_type = 'L' 
			   AND GCC.segment3 IN (gn_expense,gn_trade)			   
			   AND XTE.source_id_int_1 = AIV.invoice_id       
			   AND XTE.APPLICATION_ID   = 200
			   AND XTE.ENTITY_CODE      = 'AP_INVOICES'   
			   AND XAH.entity_id = XTE.entity_id	
			   AND XAh.application_id = XTE.application_id			   
			   AND XAL.ae_header_id=XAH.ae_header_id
			   AND XAL.application_id=XAH.application_id
			   AND XAL.ACCOUNTING_CLASS_CODE = 'LIABILITY'  
			   AND DECODE(xal.source_table,'AP_INVOICE_PAYMENTS','Y',XAH.GL_TRANSFER_STATUS_CODE) = 'Y' --V1.3, Added
			   AND XAL.account_overlay_source_id is null   
		 GROUP BY 
					DECODE (SUBSTR(APSS.ATTRIBUTE8 ,1,2),'EX', 'EXPENSE','TR','TRADE' ) 
				   ,NVL(APSS.attribute9,APSS.attribute7) 
				   ,APS.segment1 
				   ,APSS.vendor_site_code 
				   ,AIV.invoice_currency_code 
				   ,APS.vendor_name      
				   ,NVL(to_char(aiv.doc_sequence_value),AIV.voucher_num)
				   ,LTRIM(SUBSTR(AIV.attribute7,INSTR(AIV.attribute7,'_',6),10),'_') 
				   ,AIV.invoice_num 
				   ,AIV.invoice_id 
				   ,TO_CHAR(AIV.invoice_date,'MM/DD/YY') 
				   --,DECODE(UPPER(AIV.payment_method_lookup_code),'CHECK','C','EFT','E','WIRE','W','CLEARING','CL') --Commented for defect#28959
				   ,DECODE(UPPER(NVL(AIV.payment_method_code,AIV.payment_method_lookup_code)),'CHECK','C','EFT','E','WIRE','W','CLEARING','CL') --Modified for defect#28959
				   ,TRUNC (SYSDATE-AIV.invoice_date) 
				   ,DECODE(AIV.Org_id,p_us_org_id,'US',p_ca_org_id,'CA') ||'-'||DECODE (SUBSTR(APSS.ATTRIBUTE8 ,1,2),'EX','EXPENSE','TR','TRADE' )||'-'||AIV.invoice_currency_code;
				   
			  
			 ln_ca_org_id            NUMBER;
			ln_us_org_id            NUMBER;
			lc_us_ecum_flag         VARCHAR2(20);
			lc_ca_ecum_flag         VARCHAR2(20);
			lc_acc_met_opt          VARCHAR2(20);
			lc_sacc_met_opt         VARCHAR2(20);
			ln_total_invoices       NUMBER := 0;
			ln_current_req_id       NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
			ln_SECURITY_PROFILE_ID  NUMBER;  -- V1.4

			TYPE lt_invoice_id_det IS TABLE OF XX_AP_TRIAL_PRE_STG%ROWTYPE;
			lt_invoices_det                  lt_invoice_id_det;

			TYPE lt_invoice_id_interim_det IS TABLE OF XX_AP_TRIAL_FINAL_STG%ROWTYPE;
			lt_invoices_interim_det                  lt_invoice_id_interim_det;
			
			

			  BEGIN
				 
			   FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
			   FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
			   FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
			   xla_security_pkg.set_security_context(602);
			
				ln_ca_org_id := xx_fin_country_defaults_pkg.f_org_id('CA',sysdate);
				ln_us_org_id := xx_fin_country_defaults_pkg.f_org_id('US',sysdate);
				MO_GLOBAL.SET_POLICY_CONTEXT('S',FND_GLOBAL.ORG_ID);
				
				
				  FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
				  FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
				  FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
				  FND_FILE.PUT_LINE (FND_FILE.LOG,'Delete XX_AP_TRIAL_PRE_STG');

				   FND_FILE.PUT_LINE (FND_FILE.LOG, 'Truncating existing records from temp table XX_AP_TRIAL_PRE_STG ');
				  EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AP_TRIAL_PRE_STG';
				  EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AP_TRIAL_FINAL_STG';

				 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
				 FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
				 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
				 FND_FILE.PUT_LINE (FND_FILE.LOG,'RICE ID : R0453');                                              --Added for defect# 26028
				 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
				-- FND_FILE.PUT_LINE (FND_FILE.LOG,'Number of records in the thread : '|| p_batch_size);              
				-- FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
				-- FND_FILE.PUT_LINE (FND_FILE.LOG,'Range of invoice ids in the thread: '|| p_min_invoice_id || ' to ' || p_max_invoice_id);

				 SELECT NVL(purch_encumbrance_flag,'N')
				 INTO   lc_us_ecum_flag
				 FROM   financials_system_params_all
				 WHERE  org_id     = ln_us_org_id;

				 SELECT NVL(purch_encumbrance_flag,'N')
				 INTO   lc_ca_ecum_flag
				 FROM   financials_system_params_all
				 WHERE  org_id     = ln_ca_org_id ;

				 SELECT accounting_method_option
					   ,secondary_accounting_method
				 INTO   lc_acc_met_opt
					   ,lc_sacc_met_opt
				 FROM   ap_system_parameters; 

					 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
					 FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
					 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');

				  OPEN lcu_inv_det(ln_ca_org_id
								  ,ln_us_org_id
								  ,lc_acc_met_opt
								  ,lc_sacc_met_opt
								  );
				  LOOP
					 --FETCH lcu_inv_det BULK COLLECT INTO lt_invoices_det LIMIT p_batch_size;    
					   FETCH lcu_inv_det BULK COLLECT INTO lt_invoices_det LIMIT p_batch_size;       --Commented/Added for defect #26028
						   FORALL i IN 1..lt_invoices_det.COUNT
							  INSERT INTO XX_AP_TRIAL_PRE_STG
							  VALUES lt_invoices_det(i);
							  ln_total_invoices := ln_total_invoices + lt_invoices_det.COUNT;
							  EXIT WHEN lcu_inv_det%NOTFOUND;
				  END LOOP;
				  CLOSE lcu_inv_det;
				  COMMIT;

					 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
					 FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
					 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');

				  BEGIN
				  INSERT INTO XX_AP_TRIAL_FINAL_STG
					(    SELECT 
						   XAII.LIABILITY        
						  ,XAII.LEGACY_VENDOR
						  ,XAII.SUPPLIER_NUMBER
						  ,XAII.VENDOR_SITE_CODE
						  ,XAII.VENDOR_NAME    
						  ,XAII.CHILD_REQ_ID   
						  ,XAII.CURRENCY       
						  ,XAII.VOUCHER        
						  ,XAII.SOURCE         
						  ,XAII.INVOICE        
						  ,XAII.INVOICE_ID     
						  ,XAII.INV_DATE       
						  ,XAII.PAYMENT_METHOD 
						  ,XAII.AGED           
						  ,XAII.ENTERED_CR     
						  ,XAII.ENTERED_DR
						  ,XAII.ORG_ID
						  ,XX_AP_TRIAL_WRAP_PKG.get_discount_amount(xaii.invoice_id) DISC_AMT
						  ,XX_AP_TRIAL_WRAP_PKG.get_due_date(xaii.invoice_id)     DUE_DATE
								,xx_ap_trial_wrap_pkg.xx_ap_trial_app_status(XAII.invoice_id) STATUS
				FROM  XX_AP_TRIAL_PRE_STG  XAII
				WHERE 1=1 --child_req_id = ln_current_req_id
				and  exists (select 1 from ap_invoice_distributions_all aida where (lc_acc_met_opt = 'Accrual' OR lc_sacc_met_opt = 'Accrual')
							and aida.invoice_id=XAII.invoice_id and aida.accrual_posted_flag='Y'			  
			   )
				AND  (entered_cr - entered_dr)   <> 0
					);
				FND_FILE.PUT_LINE (FND_FILE.LOG,SQL%ROWCOUNT);
				END;

					 FND_FILE.PUT_LINE (FND_FILE.LOG,'Total Records in Interim ' || ln_total_invoices);
					 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
					 FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
					 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
			
			
			
			EXCEPTION
			   WHEN lc_setup_exception THEN
			   FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_location);
			   x_ret_code := 2;
			   WHEN OTHERS THEN
			   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
			   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_location);
			   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_debug);
			   ROLLBACK;
			   x_ret_code := 2;
			END XX_VENDOR_SITES_MASTER;

		-- +===================================================================+
		-- | Name : XX_INV_SITES_CHILD                                         |
		-- | Description : This Program automatically will picks all the       |
		-- |                 invoices and inserts into the                     |
		-- |                 xx_ap_trail_inv_interim table                     |
		-- | Program "OD: AP Trail Balance Report Wrapper - Child"             |
		-- |                                                                   |
		-- | Parameters :                                                      |
		-- |                                                                   |
		-- |   Returns  : x_error_buff,x_ret_code                              |
		-- +===================================================================+

		PROCEDURE XX_INV_SITES_CHILD  (x_error_buff         OUT VARCHAR2
									  ,x_ret_code           OUT NUMBER
									  ,p_batch_size         IN  NUMBER
									  ,p_thread_count       IN NUMBER                 -- Added for Defect#26028
									  --,p_min_site_id        IN  NUMBER     
									  --,p_max_site_id        IN  NUMBER
									  ,p_min_invoice_id    IN  NUMBER                 -- Added/Commented for Defect#26028
									  ,p_max_invoice_id    IN  NUMBER							  
									   )
			AS
			CURSOR lcu_inv_det(p_ca_org_id    IN NUMBER
							  ,p_us_org_id    IN NUMBER
							  ,p_acc_met_opt  IN VARCHAR2
							  ,p_sacc_met_opt IN VARCHAR2
							  )
			IS
			SELECT  /*+ INDEX(APSS,AP_SUPPLIER_SITES_U1) */ 
					DECODE (SUBSTR(APSS.ATTRIBUTE8 ,1,2),'EX', 'EXPENSE','TR','TRADE' )        LIABILITY 
				   ,NVL(APSS.attribute9,APSS.attribute7)    LEGACY_VENDOR 
				   ,APS.segment1  SUPPLIER_NUMBER 
				   ,APSS.vendor_site_code VENDOR_SITE_CODE 
				   ,APS.vendor_name      VENDOR_NAME 
				   ,FND_GLOBAL.CONC_REQUEST_ID CHILD_REQ_ID
				   ,AIV.invoice_currency_code                                          CURRENCY 
				   ,AIV.voucher_num                                                    VOUCHER 
				   ,LTRIM(SUBSTR(AIV.attribute7,INSTR(AIV.attribute7,'_',6),10),'_')   SOURCE 
				   ,AIV.invoice_num                                                    INVOICE 
				   ,AIV.invoice_id                                                     INVOICE_ID 
				   ,TO_CHAR(AIV.invoice_date,'MM/DD/YY')                               INV_DATE 
				   --,DECODE(UPPER(AIV.payment_method_lookup_code),'CHECK','C','EFT','E','WIRE','W','CLEARING','CL')   PAYMENT_METHOD --Commented for defect#28959
				   ,DECODE(UPPER(NVL(AIV.payment_method_code,AIV.payment_method_lookup_code)),'CHECK','C','EFT','E','WIRE','W','CLEARING','CL')   PAYMENT_METHOD --Modified for defect#28959 
				   ,TRUNC (SYSDATE-AIV.invoice_date)                                   AGED 
				   ,SUM(NVL(XAL.entered_cr,0))                                         ENTERED_CR 
				   ,SUM(NVL(XAL.entered_dr,0))                                         ENTERED_DR 
				   ,DECODE(AIV.Org_id,p_us_org_id,'US',p_ca_org_id,'CA') ||'-'||DECODE (SUBSTR(APSS.ATTRIBUTE8 ,1,2),'EX','EXPENSE','TR','TRADE' )||'-'||AIV.invoice_currency_code ORG_ID
				   ,NULL STATUS
				 FROM  
					ap_suppliers aps 
				   ,ap_supplier_sites_all Apss
				   ,ap_invoices_all aiv
				   ,gl_code_combinations gcc
				   ,xla_ae_headers xah
				   ,xla_ae_lines xal
				   ,xla_transaction_entities_UPG xte
			WHERE 1=1 
			   AND aps.vendor_id = apss.vendor_id 
			   AND apss.vendor_id = aiv.vendor_id 
			   AND apss.vendor_site_id = aiv.vendor_site_id 
               AND aps.vendor_id = aiv.vendor_id
			   AND XAH.ae_header_id = XAL.ae_header_id
			   AND XAH.application_id = XAL.application_id 
         --V1.7      AND XAL.PARTY_ID= APSS.VENDOR_ID
         --V1.7      AND XAL.PARTY_SITE_ID = APSS.VENDOR_SITE_ID 
               AND AIV.accts_pay_code_combination_id = GCC.code_combination_id
               --  AND AIV.INVOICE_ID=AIP.INVOICE_ID(+)	  
			   AND XAH.entity_id = XTE.entity_id	 
			   AND XAh.application_id = XTE.application_id
			   AND XTE.source_id_int_1 = AIV.invoice_id           
			   AND GCC.account_type = 'L' 
			   AND GCC.segment3 IN (gn_expense,gn_trade)  -- ('20204000','20101000') 
               AND XAL.application_id = 200
               --AND (aiv.invoice_amount - nvl(aiv.amount_paid,0))<>0  
			   AND nvl(AIV.payment_status_flag,'N')='N'
			   AND XTE.entity_code = 'AP_INVOICES' --,'AP_PAYMENTS') 
			   AND aiv.cancelled_date IS NULL 
			   AND NVL(AIV.attribute7,'ATTRIBUTE7NULL') NOT IN ('US_OD_RTV_CONSIGNMENT','US_OD_CONSIGN_INV') 
			   AND XAL.ACCOUNTING_CLASS_CODE = 'LIABILITY'  
			   AND DECODE(xal.source_table,'AP_INVOICE_PAYMENTS','Y',XAH.GL_TRANSFER_STATUS_CODE) = 'Y' --V1.3, Added
			   AND XAL.account_overlay_source_id is null   
               AND xx_ap_trial_wrap_pkg.get_posting_status(AIV.invoice_id,p_acc_met_opt,p_sacc_met_opt) <> 'N'
			--   AND AIV.invoice_id BETWEEN p_min_invoice_id and p_max_invoice_id  -- V1.5, 
		 GROUP BY 
					DECODE (SUBSTR(APSS.ATTRIBUTE8 ,1,2),'EX', 'EXPENSE','TR','TRADE' ) 
				   ,NVL(APSS.attribute9,APSS.attribute7) 
				   ,APS.segment1 
				   ,APSS.vendor_site_code 
				   ,AIV.invoice_currency_code 
				   ,APS.vendor_name      
				   ,AIV.voucher_num 
				   ,LTRIM(SUBSTR(AIV.attribute7,INSTR(AIV.attribute7,'_',6),10),'_') 
				   ,AIV.invoice_num 
				   ,AIV.invoice_id 
				   ,TO_CHAR(AIV.invoice_date,'MM/DD/YY') 
				   --,DECODE(UPPER(AIV.payment_method_lookup_code),'CHECK','C','EFT','E','WIRE','W','CLEARING','CL') --Commented for defect#28959
				   ,DECODE(UPPER(NVL(AIV.payment_method_code,AIV.payment_method_lookup_code)),'CHECK','C','EFT','E','WIRE','W','CLEARING','CL') --Modified for defect#28959
				   ,TRUNC (SYSDATE-AIV.invoice_date) 
				   ,DECODE(AIV.Org_id,p_us_org_id,'US',p_ca_org_id,'CA') ||'-'||DECODE (SUBSTR(APSS.ATTRIBUTE8 ,1,2),'EX','EXPENSE','TR','TRADE' )||'-'||AIV.invoice_currency_code;
				   
		/* -- V1.4	Prod Code	   
		SELECT  --*+ INDEX(PVS,PO_VENDOR_SITES_U1) *-- DECODE (SUBSTR(PVS.ATTRIBUTE8 ,1,2),'EX', 'EXPENSE','TR','TRADE' )        LIABILITY                                                                                                                                                                        
				   ,NVL(PVS.attribute9,PVS.attribute7)    LEGACY_VENDOR                                                                                                                                                                                                                                             
				   ,PV.segment1  SUPPLIER_NUMBER                                                                                                                                                                                                                                                                    
				   ,PVS.vendor_site_code VENDOR_SITE_CODE                                                                                                                                                                                                                                                           
				   ,PV.vendor_name      VENDOR_NAME                                                                                                                                                                                                                                                                 
				   ,FND_GLOBAL.CONC_REQUEST_ID CHILD_REQ_ID                                                                                                                                                                                                                                                         
				   ,AIV.invoice_currency_code                                          CURRENCY                                                                                                                                                                                                                     
				   ,AIV.voucher_num                                                    VOUCHER                                                                                                                                                                                                                      
				   ,LTRIM(SUBSTR(AIV.attribute7,INSTR(AIV.attribute7,'_',6),10),'_')   SOURCE 
				   ,AIV.invoice_num                                                    INVOICE                                                                                                                                                                                                                      
				   ,AIV.invoice_id                                                     INVOICE_ID                                                                                                                                                                                                                   
				   ,TO_CHAR(AIV.invoice_date,'MM/DD/YY')                               INV_DATE                                                                                                                                                                                                                     
				   ,DECODE(UPPER(AIV.payment_method_lookup_code),'CHECK','C','EFT','E','WIRE','W','CLEARING','CL')   PAYMENT_METHOD                                                                                                                                                                                 
				   ,TRUNC (SYSDATE-AIV.invoice_date)                                   AGED                                                                                                                                                                                                                         
				   ,SUM(NVL(aal.entered_cr,0))                                         ENTERED_CR                                                                                                                                                                                                                   
				   ,SUM(NVL(aal.entered_dr,0))                                         ENTERED_DR                                                                                                                                                                                                                   
				   ,DECODE(AIV.Org_id,p_us_org_id,'US',p_ca_org_id,'CA') ||'-'||DECODE (SUBSTR(PVS.ATTRIBUTE8 ,1,2),'EX','EXPENSE','TR','TRADE' )||'-'||AIV.invoice_currency_code ORG_ID                                                                                                                            
				   ,NULL STATUS                                                                                                                                                                                                                                                                                     
			 FROM  po_vendors                PV                                                                                                                                                                                                                                                                     
				  ,po_vendor_sites_all       PVS                                                                                                                                                                                                                                                                    
				  ,ap_invoices_all           AIV                                                                                                                                                                                                                                                                    
				  ,gl_code_combinations      GCC
				  ,ap_ae_lines_all           AAL                                                                                                                                                                                                                                                                    
				  ,ap_ae_headers_all         AAH                                                                                                                                                                                                                                                                    
			WHERE 1=1                                                                                                                                                                                                                                                                                               
			  AND AIV.cancelled_date IS NULL                                                                                                                                                                                                                                                                        
			  AND NVL(AIV.attribute7,'ATTRIBUTE7NULL') NOT IN ('US_OD_RTV_CONSIGNMENT','US_OD_CONSIGN_INV')                                                                                                                                                                                                         
			  AND xx_ap_trial_wrap_pkg.get_posting_status(AIV.invoice_id,p_acc_met_opt,p_sacc_met_opt) <> 'N'                                                                                                                                                                                                       
			  AND AIV.Org_id IN (p_us_org_id,p_ca_org_id)                                                                                                                                                                                                                                                           
			  AND PVS.vendor_site_id BETWEEN p_min_site_id and p_max_site_id                                                                                                                                                                                                                                        
			  AND PV.vendor_id = AIV.vendor_id                                                                                                                                                                                                                                                                      
			  AND PVS.vendor_site_id = AIV.vendor_site_id                                                                                                                                                                                                                                                           
			  AND PVS.vendor_id = PV.vendor_id                                                                                                                                                                                                                                                                      
			  AND GCC.code_combination_id = AIV.accts_pay_code_combination_id                                                                                                                                                                                                                                       
			  AND GCC.account_type = 'L' 
			  AND GCC.segment3 IN (gn_expense,gn_trade)--('20204000','20101000')                                                                                                                                                                                                                                    
			  AND AAL.account_overlay_source_id is null                                                                                                                                                                                                                                                             
			  AND AAL.reference2 = AIV.invoice_id                                                                                                                                                                                                                                                                   
			  AND AAL.ae_line_type_code = 'LIABILITY'                                                                                                                                                                                                                                                               
			  AND AAH.ae_header_id = AAL.ae_header_id                                                                                                                                                                                                                                                               
			  AND DECODE(source_table,'AP_INVOICE_PAYMENTS','Y',AAH.GL_TRANSFER_FLAG) = 'Y'                                                                                                                                                                                                                         
			GROUP BY                                                                                                                                                                                                                                                                                                
					DECODE (SUBSTR(PVS.ATTRIBUTE8 ,1,2),'EX', 'EXPENSE','TR','TRADE' )                                                                                                                                                                                                                              
				   ,NVL(PVS.attribute9,PVS.attribute7)                                                                                                                                                                                                                                                              
				   ,PV.segment1                                                                                                                                                                                                                                                                                     
				   ,PVS.vendor_site_code                                                                                                                                                                                                                                                                            
				   ,AIV.invoice_currency_code                                                                                                                                                                                                                                                                       
				   ,PV.vendor_name
				   ,AIV.voucher_num                                                                                                                                                                                                                                                                                 
				   ,LTRIM(SUBSTR(AIV.attribute7,INSTR(AIV.attribute7,'_',6),10),'_')                                                                                                                                                                                                                                
				   ,AIV.invoice_num                                                                                                                                                                                                                                                                                 
				  ,AIV.invoice_id                                                                                                                                                                                                                                                                                   
				  ,TO_CHAR(AIV.invoice_date,'MM/DD/YY')                                                                                                                                                                                                                                                             
				  ,DECODE(UPPER(AIV.payment_method_lookup_code),'CHECK','C','EFT','E','WIRE','W','CLEARING','CL')                                                                                                                                                                                                   
				  ,TRUNC (SYSDATE-AIV.invoice_date)                                                                                                                                                                                                                                                                 
				  ,DECODE(AIV.Org_id,p_us_org_id,'US',p_ca_org_id,'CA') ||'-'||DECODE (SUBSTR(PVS.ATTRIBUTE8 ,1,2),'EX','EXPENSE','TR','TRADE' )||'-'||AIV.invoice_currency_code;                                                                                                                                   		   
				*/   -- V1.4 
				   
				   
		  
		----------------------
		--Variable Declaration
		----------------------
			ln_ca_org_id            NUMBER;
			ln_us_org_id            NUMBER;
			lc_us_ecum_flag         VARCHAR2(20);
			lc_ca_ecum_flag         VARCHAR2(20);
			lc_acc_met_opt          VARCHAR2(20);
			lc_sacc_met_opt         VARCHAR2(20);
			ln_total_invoices       NUMBER := 0;
			ln_current_req_id       NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
			ln_SECURITY_PROFILE_ID  NUMBER;  -- V1.4

			TYPE lt_invoice_id_det IS TABLE OF XX_AP_TRIAL_PRE_STG%ROWTYPE;
			lt_invoices_det                  lt_invoice_id_det;

			TYPE lt_invoice_id_interim_det IS TABLE OF XX_AP_TRIAL_FINAL_STG%ROWTYPE;
			lt_invoices_interim_det                  lt_invoice_id_interim_det;

			BEGIN
				ln_ca_org_id := xx_fin_country_defaults_pkg.f_org_id('CA',sysdate);
				ln_us_org_id := xx_fin_country_defaults_pkg.f_org_id('US',sysdate);
				MO_GLOBAL.SET_POLICY_CONTEXT('S',FND_GLOBAL.ORG_ID);
				/*
				-- Defect# 27380, Start for passing security profile
				BEGIN
				  SELECT SECURITY_PROFILE_ID
				  INTO ln_SECURITY_PROFILE_ID
				  FROM PER_SECURITY_PROFILES
				  WHERE SECURITY_PROFILE_NAME='OD_GLOBAL';
				EXCEPTION
				WHEN OTHERS THEN
				  ln_SECURITY_PROFILE_ID := 1062;
				END;
				mo_global.set_policy_context('M',NULL);
				mo_global.set_org_access(NULL,ln_SECURITY_PROFILE_ID,'SQLAP');
				-- Defect# 27380, end;   
				*/

				 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
				 FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
				 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
				 FND_FILE.PUT_LINE (FND_FILE.LOG,'RICE ID : R0453');                                              --Added for defect# 26028
				 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
				 FND_FILE.PUT_LINE (FND_FILE.LOG,'Number of records in the thread : '|| p_thread_count);              
				 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
				 FND_FILE.PUT_LINE (FND_FILE.LOG,'Range of invoice ids in the thread: '|| p_min_invoice_id || ' to ' || p_max_invoice_id);

				 SELECT NVL(purch_encumbrance_flag,'N')
				 INTO   lc_us_ecum_flag
				 FROM   financials_system_params_all
				 WHERE  org_id     = ln_us_org_id;

				 SELECT NVL(purch_encumbrance_flag,'N')
				 INTO   lc_ca_ecum_flag
				 FROM   financials_system_params_all
				 WHERE  org_id     = ln_ca_org_id ;

				 SELECT accounting_method_option
					   ,secondary_accounting_method
				 INTO   lc_acc_met_opt
					   ,lc_sacc_met_opt
				 FROM   ap_system_parameters; 

					 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
					 FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
					 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');

				  OPEN lcu_inv_det(ln_ca_org_id
								  ,ln_us_org_id
								  ,lc_acc_met_opt
								  ,lc_sacc_met_opt
								  );
				  LOOP
					 --FETCH lcu_inv_det BULK COLLECT INTO lt_invoices_det LIMIT p_batch_size;    
					   FETCH lcu_inv_det BULK COLLECT INTO lt_invoices_det LIMIT p_thread_count;       --Commented/Added for defect #26028
						   FORALL i IN 1..lt_invoices_det.COUNT
							  INSERT INTO XX_AP_TRIAL_PRE_STG
							  VALUES lt_invoices_det(i);
							  ln_total_invoices := ln_total_invoices + lt_invoices_det.COUNT;
							  EXIT WHEN lcu_inv_det%NOTFOUND;
				  END LOOP;
				  CLOSE lcu_inv_det;
				  COMMIT;

					 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
					 FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
					 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');

				  BEGIN
				  INSERT INTO XX_AP_TRIAL_FINAL_STG
					(    SELECT 
						   XAII.LIABILITY        
						  ,XAII.LEGACY_VENDOR
						  ,XAII.SUPPLIER_NUMBER
						  ,XAII.VENDOR_SITE_CODE
						  ,XAII.VENDOR_NAME    
						  ,XAII.CHILD_REQ_ID   
						  ,XAII.CURRENCY       
						  ,XAII.VOUCHER        
						  ,XAII.SOURCE         
						  ,XAII.INVOICE        
						  ,XAII.INVOICE_ID     
						  ,XAII.INV_DATE       
						  ,XAII.PAYMENT_METHOD 
						  ,XAII.AGED           
						  ,XAII.ENTERED_CR     
						  ,XAII.ENTERED_DR
						  ,XAII.ORG_ID
						  ,XX_AP_TRIAL_WRAP_PKG.get_discount_amount(xaii.invoice_id) DISC_AMT
						  ,XX_AP_TRIAL_WRAP_PKG.get_due_date(xaii.invoice_id)     DUE_DATE
								,xx_ap_trial_wrap_pkg.xx_ap_trial_app_status(XAII.invoice_id) STATUS
				FROM  XX_AP_TRIAL_PRE_STG  XAII
				WHERE child_req_id = ln_current_req_id
				AND  (entered_cr - entered_dr)   <> 0
					);
				FND_FILE.PUT_LINE (FND_FILE.LOG,SQL%ROWCOUNT);
				END;

					 FND_FILE.PUT_LINE (FND_FILE.LOG,'Total Records in Interim ' || ln_total_invoices);
					 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');
					 FND_FILE.PUT_LINE (FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
					 FND_FILE.PUT_LINE (FND_FILE.LOG,'     ');

			END XX_INV_SITES_CHILD;

		  -- +============================================================================+
		  -- | PROCEDURE NAME : XX_AP_TRIAL_APP_STATUS                                 |
		  -- |                                                                            |
		  -- | DESCRIPTION    : This Procedure is use to update the status of the invoice |
		  -- |                                                                            |
		  -- |                                                                            |
		  -- |                                                                            |
		  -- | PARAMETERS     : p_batch_number                                            |
		  -- |                                                                            |
		  -- |                                                                            |
		  -- |Version   Date         Author               Remarks                         |
		  -- |========  ===========  ===================  ================================|
		  -- |1.0       22-DEC-2010  A.JUDE FELIX ANTONY  initial draft                   |
		  -- |                                                                            |
		  -- +============================================================================+

			FUNCTION XX_AP_TRIAL_APP_STATUS ( p_invoice_id IN NUMBER
											 )
			RETURN VARCHAR2
			AS
			lc_approval_status   VARCHAR2(2):= NULL;
            ln_count NUMBER; -- V1.4
			BEGIN
			-- V1.4, Added below query and if else , moved from RDF to here
			SELECT count(1)
			INTO ln_count
			FROM ap_holds_all APH
			WHERE  APH.invoice_id =  p_invoice_id
			AND    APH.release_lookup_code is NULL;
			IF ln_count > 0 THEN
			   lc_approval_status := 'H';
			ELSE
			
			SELECT   'A'
			INTO     lc_approval_status
			FROM     XX_AP_TRIAL_PRE_STG xatii
			WHERE    1=1
			AND      NVL((NVL(xatii.entered_cr,0) - NVL(xatii.entered_dr,0)),0)   <> 0
			AND      xatii.invoice_id = p_invoice_id
			AND      EXISTS(SELECT 1 FROM ap_invoice_distributions_all aid
							WHERE aid.invoice_id = xatii.invoice_id
							AND NVL(aid.match_status_flag,'N') <> 'N'
							)
			AND      EXISTS(SELECT 1 FROM ap_invoices_all AIV
							WHERE AIV.cancelled_date IS NULL
							AND   AIV.invoice_id = xatii.invoice_id
							)
			/* V1.4, not required				
			AND      NOT EXISTS(SELECT 1 FROM ap_holds_all APH
							   WHERE  APH.invoice_id =  xatii.invoice_id
							   AND    APH.release_lookup_code is NULL
							   ) */
							   ; 
			END IF;
			RETURN lc_approval_status;
			EXCEPTION
			   WHEN OTHERS THEN
			   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
			   lc_approval_status := NULL;
			   RETURN lc_approval_status;
			END XX_AP_TRIAL_APP_STATUS;

		  -- +==================================================================================+
		  -- | PROCEDURE NAME : get_posting_status                                              |
		  -- |                                                                                  |
		  -- | DESCRIPTION    : This Procedure is used to get the posting status of the invoice |
		  -- |                                                                                  |
		  -- |                                                                                  |
		  -- |                                                                                  |
		  -- | PARAMETERS     : p_batch_number                                                  |
		  -- |                                                                                  |
		  -- |                                                                                  |
		  -- |Version   Date         Author               Remarks                               |
		  -- |========  ===========  ===================  ======================================|
		  -- |1.0       22-DEC-2010  Ganesan JV           Moved the function from XX_AP_TRIAL_BAL_PKG|
		  -- |                                                                                  |
		  -- +==================================================================================+
			FUNCTION get_posting_status(p_invoice_id IN NUMBER  
										,p_acc_met_opt IN VARCHAR2
										,p_sacc_met_opt IN VARCHAR2     )
				 RETURN VARCHAR2
			 IS
				 invoice_posting_flag           VARCHAR2(1);
				 distribution_posting_flag      VARCHAR2(1);
		  --       accounting_method_option	VARCHAR2(25); --commented for 4662
		--         secondary_accounting_method	VARCHAR2(25); --commented for 4662

				 ---------------------------------------------------------------------
				 -- Declare cursor to establish the invoice-level posting flag
				 --
				 -- The first two selects simply look at the posting flags (cash and/or
				 -- accrual) for the distributions.  The rest is to cover one specific
				 -- case when some of the distributions are fully posting (Y) and some
				 -- are unposting (N).  The status should be partial (P).
				 --
				 CURSOR posting_cursor IS
				 
				 SELECT accrual_posted_flag
				 FROM   ap_invoice_distributions_all
				 WHERE  invoice_id = p_invoice_id
				 AND    (p_acc_met_opt = 'Accrual'
						 OR p_sacc_met_opt = 'Accrual')
				 UNION
				 SELECT 'P'
				 FROM   ap_invoice_distributions_all
				 WHERE  invoice_id = p_invoice_id
				 AND    (accrual_posted_flag || '' = 'Y'
						  AND (p_acc_met_opt = 'Accrual'
							   OR p_sacc_met_opt = 'Accrual'))
				 AND EXISTS
						(SELECT 'An N is also in the valid flags'
						 FROM   ap_invoice_distributions_all
						 WHERE  invoice_id = p_invoice_id
						 AND    	(accrual_posted_flag || '' = 'N'
								  AND (p_acc_met_opt = 'Accrual'
									   OR p_sacc_met_opt = 'Accrual')));

			 BEGIN

				 ---------------------------------------------------------------------
				 -- Get Primary and Secondary Accounting Methods
				 --
				/* SELECT accounting_method_option,
						secondary_accounting_method
				 INTO   accounting_method_option,
						secondary_accounting_method
				 FROM   ap_system_parameters;*/  --commented for 4662

				 ---------------------------------------------------------------------
				 -- Establish the invoice-level posting flag
				 --
				 -- Use the following ordering sequence to determine the invoice-level
				 -- posting flag:
				 --                     'S' - Selected
				 --                     'P' - Partial
				 --                     'N' - Unposted
				 --                     'Y' - Posted
				 --
				 -- Initialize invoice-level posting flag
				 --
				 invoice_posting_flag := 'X';

				 OPEN posting_cursor;

				 LOOP
					 FETCH posting_cursor INTO distribution_posting_flag;
					 EXIT WHEN posting_cursor%NOTFOUND;

					 IF (distribution_posting_flag = 'S') THEN
						 invoice_posting_flag := 'S';
					 ELSIF (distribution_posting_flag = 'P' AND
							invoice_posting_flag <> 'S') THEN
						 invoice_posting_flag := 'P';
					 ELSIF (distribution_posting_flag = 'N' AND
							invoice_posting_flag NOT IN ('S','P')) THEN
						 invoice_posting_flag := 'N';
					 ELSIF (invoice_posting_flag NOT IN ('S','P','N')) THEN
						 invoice_posting_flag := 'Y';
					 END IF;

				 END LOOP;

				 CLOSE posting_cursor;

				 if (invoice_posting_flag = 'X') then
				   -- No distributions belong to this invoice; therefore,
			   -- the invoice-level posting status should be 'N'
				   invoice_posting_flag := 'N';
				 end if;

				 RETURN(invoice_posting_flag);

			 END get_posting_status;
		  -- +==================================================================================+
		  -- | PROCEDURE NAME : get_posting_status                                              |
		  -- |                                                                                  |
		  -- | DESCRIPTION    : This Procedure is used to get the posting status of the invoice |
		  -- |                                                                                  |
		  -- |                                                                                  |
		  -- |                                                                                  |
		  -- | PARAMETERS     : p_batch_number                                                  |
		  -- |                                                                                  |
		  -- |                                                                                  |
		  -- |Version   Date         Author               Remarks                               |
		  -- |========  ===========  ===================  ======================================|
		  -- |1.0       22-DEC-2010  Ganesan JV           Moved the function from XX_AP_TRIAL_BAL_PKG|
		  -- |                                                                                  |
		  -- +==================================================================================+
			 function get_discount_amount(p_invoice_id IN NUMBER) RETURN NUMBER IS
				/*Added by Ganesan for defect 4662*/
				ln_disc_amt NUMBER;
				begin
					  SELECT SUM(DECODE(NVL(APS.discount_amount_available,0)
									  , NVL(APS.DISCOUNT_AMOUNT_REMAINING,0),NVL(APS.discount_amount_available,0),
										  (  NVL(APS.discount_amount_available,0)
										- (NVL(APS.THIRD_DISC_AMT_AVAILABLE,0)
									  + NVL(APS.SECOND_DISC_AMT_AVAILABLE,0)
									  + NVL(APS.DISCOUNT_AMOUNT_REMAINING,0))))) DISC_AMT
					  INTO ln_disc_amt
					  FROM ap_payment_schedules_all APS where APS.invoice_id = p_invoice_id;
				  RETURN ln_disc_amt;
				exception 
					when no_data_found then
						RETURN 0;
					when others then
						RETURN 0;
				end get_discount_amount;
			 function get_due_date(p_invoice_id IN NUMBER) RETURN VARCHAR2 IS
				/*Added by Ganesan for defect 4662*/
				lc_due_date VARCHAR2(14);
				begin
				   SELECT TO_CHAR(MAX(APS.DUE_DATE),'MM/DD/YY')  DUE_DATE
				 INTO lc_due_date
				 FROM ap_payment_schedules_all APS 
					where APS.invoice_id = p_invoice_id;
				 RETURN lc_due_date;
			EXCEPTION
				when no_data_found then
						RETURN NULL;
					when others then
						RETURN NULL;
				end get_due_date;
			
		END XX_AP_TRIAL_WRAP_PKG;
		/

