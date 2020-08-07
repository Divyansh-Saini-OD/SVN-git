SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_C2FO_AWARD_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
 
----------------***************************************************---------------------
----------------***************************************************---------------------

----------------***************************************************---------------------
----------------***************************************************--------------------- 
 /***************************************************************/
 /* PACKAGE BODY                                                */
 /* DATE: 31-AUG-2018                                           */
 /***************************************************************/
 
CREATE OR REPLACE PACKAGE BODY XX_AP_C2FO_AWARD_PKG AS
/********************************************************************************************************************
*   Name:        XX_AP_C2FO_AWARD_PKG
*   PURPOSE:     This package was created for the C2O Extract Process
*   @author      Joshua Wilson - C2FO
*   @version     12.1.3.1.0
*   @comments    
*
*   REVISIONS:
*   Ver          Date             Author                        Company           Description
*   ---------    ----------       ---------------               ----------        -----------------------------------
*   12.1.3.1.0   5/01/15          Joshua Wilson                 C2FO              1. Created this package.          |
*   12.1.3.1.0   8/31/2018        Nageswara Rao Chennupati      C2FO              1. Updated the package as per the |
*                                                                                 new requirements.                 |
*   1.0          9/2/2018         Antonio Morales               OD                OD Initial Customized Version     |
*********************************************************************************************************************
*/

 /***************************************************************/
 /* PROCEDURE PROCESS_AWARD                                     */
 /* Procedure to process award data                             */
 /***************************************************************/

    PROCEDURE PROCESS_AWARD(errbuf        OUT VARCHAR2, 
                            retcode       OUT NUMBER,
                            p_file_prefix  IN VARCHAR2
                           ) IS

        v_status                        VARCHAR2(1);
        v_record_count                  NUMBER;
        l_seq_id                        NUMBER;
        l_user_id                       NUMBER := fnd_global.user_id;
        lv_request_id                   NUMBER;
        v_process_msg                   VARCHAR2(2000);
        v_file_name                     VARCHAR2(240);
        lc_phase                        VARCHAR2(50);
        lc_status                       VARCHAR2(50);
        lc_dev_phase                    VARCHAR2(50);
        lc_dev_status                   VARCHAR2(50);
        lc_message                      VARCHAR2(50);
        l_req_return_status             BOOLEAN;
        l_count                         NUMBER(9) DEFAULT 0;
        l_error_msg                     VARCHAR2(2000);
        l_process_status                VARCHAR2(1);
        l_tot_err_msg                   VARCHAR2(2000);
        l_sup_hold_flag                 VARCHAR2(1);
        l_sup_hold_all_payments_flag    VARCHAR2(1);
        l_site_hold_all_payments_flag   VARCHAR2(1);
        l_hold_invoice_id               NUMBER;
        l_invoice_num                   VARCHAR2(50);
        l_award_num_cnt                 NUMBER;
        l_liability_ccid_cnt            NUMBER;
        l_inv_int_cnt                   NUMBER;
        l_staging_rec_cnt               NUMBER;
        l_act_inv_dd_upd_rec_cnt        NUMBER;    
        l_cm_dd_upd_rec_cnt             NUMBER;
        l_award_file_record_count       NUMBER;
        l_stg_table_record_count        NUMBER;
        l_possible_cm_record_count      NUMBER;
        l_created_cm_record_count       NUMBER;
        l_erreored_cm_record_count      NUMBER;
        l_dd_update_record_count        NUMBER;
        l_duplicate_record_count        NUMBER;
        l_stg_success_record_count      NUMBER;
        l_stg_error_record_count        NUMBER;

        CURSOR c1_award IS 
        SELECT xmd.rowid   c2fo_c1_rowid,
               aia.invoice_id,
               aia.invoice_num,
               aia.voucher_num,
               xmd.award_num,
               DECODE(xmd.vat_to_be_discounted,1,(xmd.income *-1),(xmd.if_inv_tobe_dis_0_cm_amt *-1)) as cm_inv_amt,
               DECODE(xmd.vat_to_be_discounted,1,(xmd.if_inv_tobe_dis_1_cm_line_amt *-1),(xmd.income *-1)) as cm_inv_line_amt,
               aia.invoice_currency_code,
               aia.payment_currency_code,
               xmd.award_description,
               aia.vendor_site_id,
               xmd.pay_date,
               xmd.award_num_terms_id,
               aia.org_id,                              
               aia.vendor_id,
               aia.payment_method_code,
               aia.pay_group_lookup_code,
			   xmd.expense_ccid,
			   aia.accts_pay_code_combination_id,
			   decode(assa.terms_date_basis, 'Goods Received',xmd.pay_date, NULL) goods_received_date
          FROM ap_supplier_sites_all assa,
               ap_suppliers sup,
               gl_code_combinations gcc,
               ap_payment_schedules_all apsa,
               ap_invoices_all aia,
               ap_terms at,
               xx_ap_c2fo_award_data_staging xmd
         WHERE aia.terms_id = at.term_id
           AND aia.invoice_id = xmd.ebs_invoice_id
           AND apsa.invoice_id = aia.invoice_id
           AND apsa.payment_num = 1
           AND apsa.payment_status_flag||'' = 'N'  -- Modified for Performance
           AND gcc.code_combination_id = aia.accts_pay_code_combination_id
           AND xmd.ebs_org_id = assa.org_id
           AND aia.org_id = xmd.ebs_org_id
           AND apsa.org_id = aia.org_id
           AND aia.vendor_site_id = assa.vendor_site_id
           AND xmd.ebs_vendor_site_id = aia.vendor_site_id
           AND aia.vendor_id = sup.vendor_id
           AND xmd.ebs_vendor_id = aia.vendor_id
           AND xmd.award_file_batch_name = c_award_file_batch_name
           AND xmd.process_status = 'STAGED_FOR_INTERFACE_REC'
           AND xmd.process_flag = 'N'
           AND aia.approval_ready_flag = 'Y'
           AND NVL(aia.prepay_flag,'N') = 'N'
           AND aia.source <> 'US_OD_C2FO'
           AND (apps.ap_invoices_pkg.get_approval_status(aia.invoice_id,aia.invoice_amount,aia.payment_status_flag,aia.invoice_type_lookup_code)) = 'APPROVED'
           AND aia.wfapproval_status IN ('MANUALLY APPROVED','NOT REQUIRED','WFAPPROVED')
           AND xmd.award_record_activities = 'CREATE_CM_AND_UPDATE_DUE_DATE';

        CURSOR c2_award IS
        SELECT xmd.rowid   c2fo_c2_rowid,
               apii.invoice_num,
               xmd.process_status,
               xmd.process_flag,
               xmd.award_record_activities,
               apii.status,
               apii.request_id,
               xmd.invoice_import_request_id,
               xmd.award_file_batch_name,
               xmd.ebs_vendor_id,
               xmd.ebs_vendor_site_id,
               xmd.ebs_org_id
          FROM xx_ap_c2fo_award_data_staging xmd,
               ap_invoices_interface apii
         WHERE xmd.ebs_org_id = apii.org_id
           AND xmd.ebs_vendor_site_id = apii.vendor_site_id
           AND xmd.ebs_vendor_id = apii.vendor_id
           AND xmd.award_num = apii.invoice_num
           AND apii.invoice_type_lookup_code = 'CREDIT'
           AND apii.source = 'US_OD_C2FO'
           -- AND apii.pay_group_lookup_code = 'C2FO'
           AND xmd.award_file_batch_name = c_award_file_batch_name
           AND xmd.process_status = 'INTERFACED'
           AND xmd.process_flag = 'N'
           AND xmd.award_record_activities = 'CREATE_CM_AND_UPDATE_DUE_DATE';

        CURSOR c3_award IS
        SELECT xmd.rowid   c2fo_c3_rowid,
               xmd.award_num,
               xmd.process_status,
               xmd.process_flag,
               xmd.award_record_activities,
               xmd.pay_date,
               xmd.invoice_import_request_id,
               xmd.award_file_batch_name,
               xmd.ebs_vendor_id,
               xmd.ebs_vendor_site_id,
               xmd.ebs_org_id,
               xmd.ebs_invoice_id
          FROM xx_ap_c2fo_award_data_staging xmd
         WHERE xmd.award_file_batch_name = c_award_file_batch_name
           AND xmd.process_status IN ('UPDATE_DUE_DATE_ONLY_REC','CM_CREATED')
           AND xmd.process_flag = 'N';

        CURSOR c5_award IS
               SELECT xmd.rowid   c2fo_c5_rowid,
                      xmd.award_num,
                      xmd.process_status,
                      xmd.process_flag,
                      xmd.award_record_activities,
                      xmd.pay_date,
                      xmd.invoice_import_request_id,
                      xmd.award_file_batch_name,
                      xmd.ebs_vendor_id,
                      xmd.ebs_vendor_site_id,
                      xmd.ebs_org_id,
                      xmd.ebs_cm_invoice_id
                 FROM xx_ap_c2fo_award_data_staging xmd
                WHERE xmd.award_file_batch_name = c_award_file_batch_name
                  AND xmd.process_status IN ('CM_CREATED')
                  AND xmd.process_flag = 'N';                          

        CURSOR c4_award IS
        SELECT *
          FROM xx_ap_c2fo_award_data_staging xmd
         WHERE 1=1
           AND xmd.award_file_batch_name = c_award_file_batch_name;                              

    BEGIN
        fnd_file.put_line(fnd_file.log,' ');
        fnd_file.put_line(fnd_file.log,' ');
        fnd_file.put_line(fnd_file.log,'File Award Process Started.');
        fnd_file.put_line(fnd_file.log,' ');
        fnd_file.put_line(fnd_file.log,'********** Input Parameters Starts **********');
        fnd_file.put_line(fnd_file.log,'p_file_prefix:       ' || p_file_prefix);
        fnd_file.put_line(fnd_file.log,' ');
        fnd_file.put_line(fnd_file.log,'Upload Directory:   ' || c_upload_directory);
        fnd_file.put_line(fnd_file.log,'Archive Directory:   ' || c_archive_directory);
        fnd_file.put_line(fnd_file.log,'********** Input Parameters Ends **********');
        fnd_file.put_line(fnd_file.log,' ');
        fnd_file.put_line(fnd_file.log,' ');

        v_status := 'S';

      --Create External table file AND archive source file
        v_file_name := p_file_prefix|| '_award_'|| TO_CHAR(trunc(SYSDATE),'YYYYMMDD')|| '.csv';
/**
      -- Copy file name to csv file in AWARD directory
      Begin
	  
	  --Archive File
        utl_file.fcopy(C_UPLOAD_DIRECTORY,v_file_name,C_ARCHIVE_DIRECTORY,v_file_name);
        FND_FILE.PUT_LINE(FND_FILE.LOG, '     '||v_file_name||' copied to AWARD directory for processing.');

        --Rename File
--      utl_file.frename(C_UPLOAD_DIRECTORY,v_file_name,C_UPLOAD_DIRECTORY,'xxdd_c2fo_award.csv',TRUE);
--      FND_FILE.PUT_LINE(FND_FILE.LOG, '     '||v_file_name||' moved to ARCHIVE directory.');

      Exception
        When others THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, '     Error copying file '||v_file_name||' to AWARD directory, please check your award AND archive file paths.  '||SQLERRM);
          v_status := 'E';
          retcode := 1;
      End; 
**/
      -- Insert records into XX_AP_C2FO_MEMO_DATA_STAGING table

        IF v_status = 'S' THEN

            BEGIN
                SELECT COUNT(1)
                  INTO v_record_count
                  FROM xx_ap_c2fo_award_data_external;

                 fnd_file.put_line(fnd_file.log,'     Record count FROM xx_ap_c2fo_MEMO_DATA_EXTERNAL is '|| v_record_count|| '.');

            EXCEPTION
                WHEN OTHERS THEN
                     v_status := 'E';
                     fnd_file.put_line(fnd_file.log,'     Error returning count FROM xx_ap_c2fo_MEMO_DATA_EXTERNAL table.');
                     retcode := 1;
            END;
			
			-- Derive the Credit Memo term Id based the profile XX_AP_C2FO_MEMO_TERM_ID
			
            BEGIN
                SELECT term_id
                  INTO  c_memo_term_id
                  FROM ap_terms at
				  WHERE at.term_id = fnd_profile.value('XX_AP_C2FO_MEMO_TERM_ID');

                 fnd_file.put_line(fnd_file.log,'     The c_memo_term_id is '|| c_memo_term_id|| '.');

            EXCEPTION
                WHEN OTHERS THEN
                     v_status := 'E';
                     fnd_file.put_line(fnd_file.log,'Error deriving the Credit Memo term Id using profile XX_AP_C2FO_MEMO_TERM_ID.');
                     retcode := 1;
            END;

			-- Derive the Expense CCId for the award from Financial Options
			
            BEGIN
				SELECT disc_taken_code_combination_id
					INTO g_us_expense_ccid
				FROM ap_system_parameters_all aspa
				    ,hr_operating_units hou
				WHERE hou.name = 'OU_US'
				  AND aspa.org_id = hou.organization_id;

                 fnd_file.put_line(fnd_file.log,'     The g_us_expense_ccid is '|| g_us_expense_ccid|| '.');

				SELECT disc_taken_code_combination_id
					INTO g_ca_expense_ccid
          FROM ap_system_parameters_all aspa
              ,hr_operating_units hou
				 WHERE hou.name = 'OU_CA'
				   AND aspa.org_id = hou.organization_id;

                 fnd_file.put_line(fnd_file.log,'     The g_ca_expense_ccid is '|| g_ca_expense_ccid|| '.');				 

            EXCEPTION
                WHEN OTHERS THEN
                     v_status := 'E';
                     fnd_file.put_line(fnd_file.log,'     Error deriving the Expense or charge account from financial options of US or CA.');
                     retcode := 1;
            END;
			

            BEGIN

            fnd_file.put_line(fnd_file.log,'   ');
            fnd_file.put_line(fnd_file.log,'   ');
            fnd_file.put_line(fnd_file.log,' Stage 01 - insert the records into table xx_ap_c2fo_award_data_staging - Starts ');

                INSERT
                  INTO xx_ap_c2fo_award_data_staging
                       (company_id,                    
                       company_name                  ,
                       division_id                   ,
                       invoice_id                    ,
                       original_amount               ,
                       currency                      ,
                       original_due_date             ,
                       discount_percentage           ,
                       discounted_invoice_amount     ,
                       pay_date                      ,
                       offer_apr_amount              ,
                       transaction_type              ,
                       covers_adjustment             ,
                       adjusted_invoice_amount       ,
                       income                        ,
                       vat_to_be_discounted          ,
                       ebs_invoice_tax_rate          ,
                       if_inv_tobe_dis_1_cm_line_amt ,
                       if_inv_tobe_dis_0_cm_amt      ,
                       award_num                     ,
                       award_description             ,
                       invoice_currency_code         ,
                       payment_currency_code         ,
                       payment_method_code           ,
                       pay_group_lookup_code         ,
                       liability_ccid                ,
                       expense_ccid                  ,
                       award_num_terms_id            ,
                       buyer_name                    ,
                       ebs_supplier_number           ,
                       ebs_vendor_site_code          ,
                       ebs_invoice_num               ,
                       ebs_voucher_num               ,
                       ebs_org_id                    ,
                       ebs_vendor_id                 ,
                       ebs_vendor_site_id            ,
                       ebs_invoice_id                ,
                       ebs_cm_invoice_id             ,
                       invoice_import_request_id     ,
                       stage_date                    ,
                       award_file_batch_name         ,
                       award_record_activities       ,
                       process_flag                  ,
                       process_status                ,
                       processed_date                ,
                       error_msg                     )
                SELECT company_id,
                       company_name,
                       division_id,
                       invoice_id,
                       original_amount,
                       currency,
                       TO_DATE(original_due_date,'yyyy-mm-dd'),
                       discount_percentage,
                       discounted_invoice_amount,
                       TO_DATE(pay_date,'yyyy-mm-dd'),
                       offer_apr_amount,
                       transaction_type,
                       covers_adjustment,
                       adjusted_invoice_amount,                        
                       (NVL(income,0)),
                       xmde.vat_to_be_discounted,                    
                       (ROUND((NVL(xmde.original_vat,0)*100)/(NVL(xmde.ebs_inv_amt_before_cash_disc,0)),2)),
                       (ROUND(((NVL(xmde.income,0))*NVL(xmde.ebs_inv_amt_before_cash_disc,0))/(NVL(xmde.original_vat,0)+NVL(xmde.ebs_inv_amt_before_cash_disc,0)),2)),                        
                       (ROUND(((NVL(xmde.income,0))*((NVL(xmde.ebs_inv_amt_before_cash_disc,0))+(NVL(xmde.original_vat,0))))/NVL(xmde.ebs_inv_amt_before_cash_disc,0),2)),
                       (CASE NVL(xmde.income,0) WHEN 0 THEN NULL
                                                ELSE NVL2(xmde.ebs_voucher_num,(xmde.ebs_invoice_num||xmde.ebs_voucher_num||'C2FO'),(xmde.ebs_invoice_num||'AWARD')) 
                       END), 
                       (CASE NVL(xmde.income,0) WHEN 0 THEN NULL
                                                ELSE NVL2(xmde.ebs_voucher_num,( 'Award file for Invoice/Voucher '||xmde.ebs_invoice_num||xmde.ebs_voucher_num||
                                                     'C2FO'),('Award file for Invoice '|| xmde.ebs_invoice_num))
                       END),
                       currency,
                       local_currency_key,
                       (SELECT aia.payment_method_code FROM ap_invoices_all aia WHERE aia.org_id=xmde.ebs_org_id AND aia.invoice_id=xmde.ebs_invoice_id),
                       ebs_pay_group,
                       null, --c_liability_ccid,
                       decode(ebs_org_id, 404, g_us_expense_ccid, g_ca_expense_ccid),  --c_expense_ccid,
                       c_memo_term_id,
                       buyer_name,
                       ebs_supplier_number,
                       ebs_vendor_site_code,
                       ebs_invoice_num,
                       ebs_voucher_num,
                       ebs_org_id,
                       ebs_vendor_id,
                       ebs_vendor_site_id,
                       ebs_invoice_id,
                       NULL,
                       0,
                       SYSDATE,
                        c_award_file_batch_name,
                       (CASE NVL(xmde.income,0) WHEN 0 THEN 'UPDATE_DUE_DATE'
                                                ELSE 'CREATE_CM_AND_UPDATE_DUE_DATE' 
                       END),
                       'N',
                       CASE (SELECT COUNT(*)
                               FROM xx_ap_c2fo_award_data_staging xmds
                              WHERE xmds.process_status= 'PROCESSED' 
                                AND process_flag = 'Y'
                                AND xmds.company_id = xmde.company_id
                                AND xmds.invoice_id = xmde.invoice_id) WHEN 0 THEN DECODE(NVL(income,0),0,'UPDATE_DUE_DATE_ONLY_REC','STAGED_FOR_INTERFACE_REC')
                                                                       ELSE 'DUPLICATE'
                       END,
                       NULL,
                       NULL
                  FROM xx_ap_c2fo_award_data_external xmde
                 WHERE 1=1;

                COMMIT;

                UPDATE xx_ap_c2fo_award_data_staging xads
                   SET xads.process_flag = 'E',
                       xads.error_msg = 'Duplicate Record Error.',
					   xads.last_update_date = sysdate,
					   xads.last_updated_by = l_user_id
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   AND xads.process_status = 'DUPLICATE';

                SELECT COUNT(*)
                  INTO l_staging_rec_cnt
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name;

                fnd_file.put_line(fnd_file.log,'    Inserted records into the xx_ap_c2fo_award_data_staging table.');

                fnd_file.put_line(fnd_file.log,'    Inserted record count: '||l_staging_rec_cnt|| ' for the batch: '||c_award_file_batch_name);

            EXCEPTION
                WHEN OTHERS THEN
                    ROLLBACK;
                    v_status := 'E';
                    fnd_file.put_line(fnd_file.log,'Error inserting records into xx_ap_c2fo_AWARD_DATA_EXTERNAL table.  ' || sqlerrm);
                    retcode := 1;
            END;

        END IF;

        fnd_file.put_line(fnd_file.log,' Stage 01 - insert the records into table xx_ap_c2fo_award_data_staging - Ends ');


        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');        
        fnd_file.put_line(fnd_file.log,' Stage 02 - Validate the records in the table "xx_ap_c2fo_award_data_staging" for the batch  :'||c_award_file_batch_name||' - Starts');

        -- +======================================================================================================+
        -- | Validations - starts here.
        -- +======================================================================================================+    
        BEGIN

        FOR c4_award_rec IN c4_award 
        LOOP

        l_count          := l_count + 1;
        l_error_msg      := NULL;
        l_process_status := NULL;
        l_tot_err_msg    := NULL;

        -- +======================================================================================================+
        -- | Validation#01 - STARTS - Checking the Holds AT Supplier and supplier site level.
        -- +======================================================================================================+         

            BEGIN

            l_error_msg      := NULL;
            l_process_status := NULL;            
		    -- Modified for performance 
            SELECT NVL(sup.hold_flag,'N'),
                   NVL(sup.hold_all_payments_flag,'N'),
                   NVL(assa.hold_all_payments_flag,'N')
              INTO l_sup_hold_flag,
                   l_sup_hold_all_payments_flag,
                   l_site_hold_all_payments_flag              
              FROM ap_suppliers sup,
                   ap_supplier_sites_all assa,
                   ap_invoices_all aia
             WHERE 1 = 1
			   AND aia.invoice_id = c4_award_rec.ebs_invoice_id
               AND aia.org_id+0 = c4_award_rec.ebs_org_id
			   AND aia.vendor_id+0 = c4_award_rec.ebs_vendor_id
               AND aia.vendor_site_id+0 = c4_award_rec.ebs_vendor_site_id
			   AND assa.vendor_site_id = aia.vendor_site_id
			   AND assa.org_id = aia.org_id
			   AND assa.vendor_id+0 = aia.vendor_id
               AND sup.vendor_id = assa.vendor_id;
			   
            EXCEPTION
                 WHEN OTHERS THEN
                        l_process_status := 'E';
                        l_error_msg      := 'Holds applied for the the supplier'||c4_award_rec.ebs_supplier_number||'-'||c4_award_rec.ebs_vendor_site_code;
            END;

             IF l_sup_hold_flag = 'N' AND l_sup_hold_all_payments_flag = 'N' AND l_site_hold_all_payments_flag = 'N'  THEN
                    l_process_status := 'N';
             ELSE     
                    l_process_status := 'E';
                    l_error_msg      := 'Holds applied for the the supplier'||c4_award_rec.ebs_supplier_number||'-'||c4_award_rec.ebs_vendor_site_code;
             END IF;    

            IF l_process_status = 'E' THEN             

                UPDATE xx_ap_c2fo_award_data_staging xads
                       SET xads.process_status = 'VALIDATION_ERROR',
                           xads.error_msg = c4_award_rec.error_msg||'-'||l_error_msg,
                           xads.process_flag = l_process_status,
						   xads.last_update_date = sysdate,
						   xads.last_updated_by = l_user_id						   
                     WHERE 1 = 1
                       AND xads.company_id = c4_award_rec.company_id
                       AND xads.invoice_id = c4_award_rec.invoice_id
                       AND xads.award_file_batch_name=c_award_file_batch_name;
            ELSE    
                l_process_status := 'N';

                UPDATE xx_ap_c2fo_award_data_staging xads
                   SET xads.process_flag = l_process_status,
					   xads.last_update_date = sysdate,
					   xads.last_updated_by = l_user_id				   
                 WHERE 1 = 1
                   AND xads.company_id = c4_award_rec.company_id
                   AND xads.invoice_id = c4_award_rec.invoice_id
                   AND xads.award_file_batch_name=c_award_file_batch_name
                   AND NVL(xads.process_flag, 'N') != 'E';

            END IF;            

        -- +======================================================================================================+
        -- | Validation#01 - ENDS - Checking the Holds AT Supplier and supplier site level.
        -- +======================================================================================================+

        -- +======================================================================================================+
        -- | Validation#02 - Starts - Checking the Holds on the invoice
        -- +======================================================================================================+         

            BEGIN

            l_error_msg      := NULL;
            l_process_status := NULL;

            SELECT NVL(COUNT(aha.invoice_id),0)
              INTO l_hold_invoice_id            
              FROM ap_holds_all aha 
             WHERE aha.release_lookup_code is null
             AND aha.invoice_id= c4_award_rec.ebs_invoice_id;

             EXCEPTION
                    WHEN OTHERS THEN
                        l_process_status := 'E';
                        l_error_msg      := 'Hold applied for the invoice:'||c4_award_rec.ebs_invoice_num;
             END;

             IF l_hold_invoice_id !=0 THEN
                    l_process_status := 'E';
                    l_error_msg      := 'Hold applied for the invoice:'||c4_award_rec.ebs_invoice_num;
             ELSE     
                    l_process_status := 'N';
             END IF;

            IF l_process_status = 'E' THEN             

               UPDATE xx_ap_c2fo_award_data_staging xads
                  SET xads.process_status = 'VALIDATION_ERROR',
                      xads.error_msg = c4_award_rec.error_msg||'-'||l_error_msg,
                      xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id					  
                WHERE 1 = 1
                  AND xads.company_id = c4_award_rec.company_id
                  AND xads.invoice_id = c4_award_rec.invoice_id
                  AND xads.award_file_batch_name=c_award_file_batch_name;
            ELSE    
                l_process_status := 'N';

                UPDATE xx_ap_c2fo_award_data_staging xads
                   SET xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id					   
                 WHERE 1 = 1
                   AND xads.company_id = c4_award_rec.company_id
                   AND xads.invoice_id = c4_award_rec.invoice_id
                   AND xads.award_file_batch_name=c_award_file_batch_name
                   AND NVL(xads.process_flag, 'N') != 'E';

            END IF;    

        -- +======================================================================================================+
        -- | Validation#02 - ENDS - Checking the Holds on the invoice
        -- +======================================================================================================+                

        -- +======================================================================================================+
        -- | Validation#03 - Starts - Checking the INVOICE NUMBER EXISTS OR NOT.
        -- +======================================================================================================+         

            BEGIN

            l_error_msg      := NULL;
            l_process_status := NULL;            
			
			-- Modified for performance
            
			SELECT aia.invoice_num
              INTO l_invoice_num
              FROM ap_invoices_all aia
             WHERE 1 = 1
               AND aia.vendor_id+0 = c4_award_rec.ebs_vendor_id
               AND aia.vendor_site_id+0 = c4_award_rec.ebs_vendor_site_id
               AND aia.org_id+0 = c4_award_rec.ebs_org_id
               AND aia.invoice_num||'' = c4_award_rec.ebs_invoice_num
               AND aia.invoice_id = c4_award_rec.ebs_invoice_id;

            EXCEPTION
                 WHEN OTHERS THEN
                        l_process_status := 'E';
                        l_error_msg      := 'invoice_num Error, Invoice num:'||'-'||c4_award_rec.ebs_invoice_num||'-'|| 'is not exists in application.';
            END;

            IF l_invoice_num = c4_award_rec.ebs_invoice_num  THEN
               l_process_status := 'N';
            ELSE     
               l_process_status := 'E';
               l_error_msg      := 'invoice_num Error, Invoice num:'||'-'||c4_award_rec.ebs_invoice_num||'-'|| 'is not exists in application.';
            END IF;    

            IF l_process_status = 'E' THEN             

               UPDATE xx_ap_c2fo_award_data_staging xads
                  SET xads.process_status = 'VALIDATION_ERROR',
                      xads.error_msg = c4_award_rec.error_msg||'-'||l_error_msg,
                      xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id					  
                WHERE 1 = 1
                  AND xads.company_id = c4_award_rec.company_id
                  AND xads.invoice_id = c4_award_rec.invoice_id
                  AND xads.award_file_batch_name=c_award_file_batch_name;
            ELSE    
                l_process_status := 'N';

                UPDATE xx_ap_c2fo_award_data_staging xads
                   SET xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id				   
                 WHERE 1 = 1
                   AND xads.company_id = c4_award_rec.company_id
                   AND xads.invoice_id = c4_award_rec.invoice_id
                   AND xads.award_file_batch_name=c_award_file_batch_name
                   AND NVL(xads.process_flag, 'N') != 'E';

            END IF;

        -- +======================================================================================================+
        -- | Validation#03 - Ends - Checking the iNVOICE NUMBER EXISTS OR NOT.
        -- +======================================================================================================+        

        -- +======================================================================================================+
        -- | Validation#04 - STARTS - Checking the AWARD NUMBER(NEW INVOICE NUMBER/ CREDIT MEMO) EXISTS OR NOT.
        -- +======================================================================================================+         

            BEGIN

            l_error_msg      := NULL;
            l_process_status := NULL;


            IF NVL(c4_award_rec.income,0) != 0 AND c4_award_rec.award_record_activities='CREATE_CM_AND_UPDATE_DUE_DATE' THEN

			-- Modified for performance
            BEGIN
                SELECT COUNT(aia.invoice_id)
                  INTO l_award_num_cnt
                  FROM ap_invoices_all aia
                 WHERE 1 = 1
                   AND aia.vendor_id+0 = c4_award_rec.ebs_vendor_id
                   AND aia.vendor_site_id+0 = c4_award_rec.ebs_vendor_site_id
                   AND aia.org_id+0 = c4_award_rec.ebs_org_id
                   AND aia.invoice_num = c4_award_rec.award_num;

            EXCEPTION
                 WHEN OTHERS THEN
                      l_process_status := 'E';
                      l_error_msg      := 'award_num Error, award_num/invoice_num(credit memoS):'||'-'||c4_award_rec.award_num||'-'|| 'is already exists.';
            END;

            IF l_award_num_cnt = 0  THEN
               l_process_status := 'N';
            ELSE     
               l_process_status := 'E';
               l_error_msg      := 'award_num Error, award_num/invoice_num(credit memo):'||'-'||c4_award_rec.award_num||'-'|| 'is already exists.';
            END IF;    

            IF l_process_status = 'E' THEN             

                UPDATE xx_ap_c2fo_award_data_staging xads
                   SET process_status = 'VALIDATION_ERROR',
                       error_msg = c4_award_rec.error_msg||'-'||l_error_msg,
                       process_flag = l_process_status,
					   xads.last_update_date = sysdate,
					   xads.last_updated_by = l_user_id					   
                 WHERE 1 = 1
                   AND xads.company_id = c4_award_rec.company_id
                   AND xads.invoice_id = c4_award_rec.invoice_id
                   AND xads.award_file_batch_name=c_award_file_batch_name;
            ELSE    
                l_process_status := 'N';

                UPDATE xx_ap_c2fo_award_data_staging xads
                   SET process_flag = l_process_status,
					   xads.last_update_date = sysdate,
					   xads.last_updated_by = l_user_id				   
                 WHERE 1 = 1
                   AND xads.company_id = c4_award_rec.company_id
                   AND xads.invoice_id = c4_award_rec.invoice_id
                   AND xads.award_file_batch_name=c_award_file_batch_name
                   AND NVL(xads.process_flag, 'N') != 'E';

            END IF;
            END IF;
            END;

        -- +======================================================================================================+
        -- | Validation#04 - Ends - Checking the AWARD NUMBER(NEW INVOICE NUMBER/ CREDIT MEMO) EXISTS OR NOT.
        -- +======================================================================================================+                

        -- +======================================================================================================+
        -- | Validation#05 - STARTS - Validating the Liability account CCID.
        -- +======================================================================================================+         
		/**  We derive it from the invoice.
            BEGIN

            l_error_msg      := NULL;
            l_process_status := NULL;            

            SELECT NVL(gcc.code_combination_id,0)
              INTO l_liability_ccid_cnt
              FROM gl_code_combinations gcc
             WHERE 1 = 1
               AND gcc.account_type = 'L'
               AND gcc.enabled_flag = 'Y'
               AND gcc.code_combination_id = c4_award_rec.liability_ccid;

            EXCEPTION
                 WHEN OTHERS THEN
                      l_process_status := 'E';
                      l_error_msg      := 'Liability Account Error, for award_num:'||'-'||c4_award_rec.award_num;
            END;

            IF l_liability_ccid_cnt != 0  THEN
               l_process_status := 'N';
            ELSE     
               l_process_status := 'E';
               l_error_msg      := 'Liability Account Error, for award_num:'||'-'||c4_award_rec.award_num;
            END IF;    

            IF l_process_status = 'E' THEN             

               UPDATE xx_ap_c2fo_award_data_staging xads
                  SET xads.process_status = 'VALIDATION_ERROR',
                      xads.error_msg = c4_award_rec.error_msg||'-'||l_error_msg,
                      xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id					  
                WHERE 1 = 1
                  AND xads.company_id = c4_award_rec.company_id
                  AND xads.invoice_id = c4_award_rec.invoice_id
                  AND xads.award_file_batch_name=c_award_file_batch_name;
            ELSE    
               l_process_status := 'N';

               UPDATE xx_ap_c2fo_award_data_staging xads
                  SET xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id					  				  
                WHERE 1 = 1
                  AND xads.company_id = c4_award_rec.company_id
                  AND xads.invoice_id = c4_award_rec.invoice_id
                  AND xads.award_file_batch_name=c_award_file_batch_name
                  AND NVL(xads.process_flag, 'N') != 'E';

            END IF;
	**/
        -- +======================================================================================================+
        -- | Validation#05 - Ends - Checking the AWARD NUMBER(NEW INVOICE NUMBER/ CREDIT MEMO) EXISTS OR NOT.
        -- +======================================================================================================+                        

        -- +======================================================================================================+
        -- | Validation#06 - STARTS - Validating the dist_code_combination_id.
        -- +======================================================================================================+         

            BEGIN

            l_error_msg      := NULL;
            l_process_status := NULL;            

            SELECT NVL(gcc.code_combination_id,0)
              INTO l_liability_ccid_cnt
              FROM gl_code_combinations gcc
             WHERE 1 = 1
               AND gcc.enabled_flag = 'Y'
               AND gcc.code_combination_id = c4_award_rec.expense_ccid;

            EXCEPTION
                 WHEN OTHERS THEN
                      l_process_status := 'E';
                      l_error_msg      := 'Distribution Account Error, for award_num:'||'-'||c4_award_rec.award_num;
            END;

            IF l_liability_ccid_cnt != 0  THEN
               l_process_status := 'N';
            ELSE     
               l_process_status := 'E';
               l_error_msg      := 'Distribution Account Error, for award_num:'||'-'||c4_award_rec.award_num;
            END IF;    

            IF l_process_status = 'E' THEN             

               UPDATE xx_ap_c2fo_award_data_staging xads
                  SET xads.process_status = 'VALIDATION_ERROR',
                      xads.error_msg = c4_award_rec.error_msg||'-'||l_error_msg,
                      xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id					  
                WHERE 1 = 1
                  AND xads.company_id = c4_award_rec.company_id
                  AND xads.invoice_id = c4_award_rec.invoice_id
                  AND xads.award_file_batch_name=c_award_file_batch_name;
            ELSE    
               l_process_status := 'N';

               UPDATE xx_ap_c2fo_award_data_staging xads
                  SET xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id				  
                WHERE 1 = 1
                  AND xads.company_id = c4_award_rec.company_id
                  AND xads.invoice_id = c4_award_rec.invoice_id
                  AND xads.award_file_batch_name=c_award_file_batch_name
                  AND NVL(xads.process_flag, 'N') != 'E';

            END IF;

        -- +======================================================================================================+
        -- | Validation#06 - ENDS - Validating the dist_code_combination_id.
        -- +======================================================================================================+                                

        END LOOP;        
        END;
        COMMIT;

        -- +======================================================================================================+
        -- | Validations - END.
        -- +======================================================================================================+        

        fnd_file.put_line(fnd_file.log,' Stage 02 - Validate the records in the table "xx_ap_c2fo_award_data_staging" for the batch  :'||c_award_file_batch_name||' - ENDS');


        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');        
        fnd_file.put_line(fnd_file.log,' Stage 03 - insert the records into tables ap_invoices_interface and  ap_invoice_lines_interface - Starts ');

---------------##########@@@@@@@@@@@@@@@-------------------        
        BEGIN

        SELECT COUNT(*) 
          INTO l_inv_int_cnt
          FROM xx_ap_c2fo_award_data_staging xmd
         WHERE 1=1                 
           AND xmd.award_file_batch_name = c_award_file_batch_name
           AND xmd.process_status = 'STAGED_FOR_INTERFACE_REC'
           AND xmd.process_flag = 'N'
           AND xmd.award_record_activities = 'CREATE_CM_AND_UPDATE_DUE_DATE';

        END;

---------------##########@@@@@@@@@@@@@@@-------------------                

        IF l_inv_int_cnt != 0 THEN        

        FOR c1_award_rec IN c1_award LOOP

            BEGIN
             SELECT ap_invoices_interface_s.NEXTVAL
               INTO l_seq_id
               FROM dual;          

          --Create Memo Header

		  -- gl_date: OD uses the default value as the creation_date and OD needs creation_date as gl_date
             INSERT
               INTO ap_invoices_interface
                    (
                    invoice_id,
                    invoice_num,
                    invoice_date,
                    invoice_type_lookup_code,
                    invoice_amount,
                    invoice_currency_code,
                    payment_currency_code,
                    description,
                    last_update_date,
                    last_updated_by,
                    creation_date,
                    created_by,
                    source,
                    vendor_site_id,
                  ---  gl_date,   
					goods_received_date,
                    org_id,
                    vendor_id,
                    terms_id,
                    payment_method_code,
                    pay_group_lookup_code,
                    accts_pay_code_combination_id,
                    group_id,
					attribute7
                    )
             VALUES (
                    l_seq_id,
                    c1_award_rec.award_num,  --Can be configured by client                   
                    trunc(SYSDATE),
                    'CREDIT',
                    c1_award_rec.cm_inv_amt,
                    c1_award_rec.invoice_currency_code,
                    c1_award_rec.payment_currency_code,
                    c1_award_rec.award_description,
                    SYSDATE,
                    l_user_id,
                    SYSDATE,
                    l_user_id,
                    'US_OD_C2FO',
                    c1_award_rec.vendor_site_id,
                   -- c1_award_rec.pay_date,
					c1_award_rec.goods_received_date,
                    c1_award_rec.org_id,
                    c1_award_rec.vendor_id,
                    c1_award_rec.award_num_terms_id,
                    c1_award_rec.payment_method_code,
                    c1_award_rec.PAY_GROUP_LOOKUP_CODE,
                    c1_award_rec.accts_pay_code_combination_id,
                    c_award_file_batch_name,
					'US_OD_C2FO'    -- attribute7
                    );

          --Create Memo Line

             INSERT
               INTO ap_invoice_lines_interface (
                    invoice_id,
                    line_number,
                    line_type_lookup_code,
                    amount,
                    description,
                    last_update_date,
                    last_updated_by,
                    creation_date,
                    created_by,
                    dist_code_combination_id,
                    --dist_code_concatenated,
                    org_id
                    )
             VALUES (
                    l_seq_id,
                    1,
                    'ITEM',
                    c1_award_rec.cm_inv_line_amt,
                    c1_award_rec.award_description,
                    SYSDATE,
                    l_user_id,
                    SYSDATE,
                    l_user_id,
                    c1_award_rec.expense_ccid,
                    --NULL,
                    c1_award_rec.org_id
                    );

             UPDATE xx_ap_c2fo_award_data_staging xads
                SET xads.process_status = 'INTERFACED',
                    xads.processed_date = SYSDATE,
					xads.last_update_date = sysdate,
					xads.last_updated_by = l_user_id					
              WHERE ROWID = c1_award_rec.c2fo_c1_rowid;
--                AND xads.award_file_batch_name = c_award_file_batch_name
--                AND xads.award_num = c1_award_rec.award_num
--                AND xads.ebs_org_id = c1_award_rec.org_id
--                AND xads.ebs_vendor_id = c1_award_rec.vendor_id
--                AND xads.ebs_vendor_site_id = c1_award_rec.vendor_site_id
--                AND NVL(xads.process_flag, 'N') != 'E'
--                AND xads.process_status = 'STAGED_FOR_INTERFACE_REC';

             COMMIT;

            EXCEPTION
                WHEN OTHERS THEN
                    v_process_msg := 'Error While loading to the interface tables'||'-'||sqlerrm;

                    UPDATE xx_ap_c2fo_award_data_staging xads
                       SET xads.process_status = 'ERROR',
                           xads.process_flag = 'E',
                           xads.error_msg = v_process_msg,
						   xads.last_update_date = sysdate,
					       xads.last_updated_by = l_user_id
                     WHERE ROWID = c1_award_rec.c2fo_c1_rowid;
--                        AND xads.award_file_batch_name = c_award_file_batch_name
--                        AND xads.award_num = c1_award_rec.award_num
--                        AND xads.ebs_org_id = c1_award_rec.org_id
--                        AND xads.ebs_vendor_id = c1_award_rec.vendor_id
--                        AND xads.ebs_vendor_site_id = c1_award_rec.vendor_site_id
--                        AND NVL(xads.process_flag, 'N') != 'E'
--                        AND xads.process_status = 'STAGED_FOR_INTERFACE_REC';

            END;
        END LOOP;

        fnd_file.put_line(fnd_file.log,' Stage 03 - insert the records into tables ap_invoices_interface and  ap_invoice_lines_interface - Ends ');


        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');        
        fnd_file.put_line(fnd_file.log,' Stage 04 - Submiting the Program - Payables Open Interface Import - Starts ');
		
		--- Go-Live time, we trigger the program only for OD_US org.

        lv_request_id := fnd_request.submit_request (
                                        application => 'SQLAP' -- application short name
                                       ,program => 'APXIIMPT' -- program short name
                                       ,description => NULL -- program name
                                       ,start_time => NULL -- start date
                                       ,sub_request => FALSE -- sub-request
                                       ,argument1 => '404'   -- Operating Unit
                                       ,argument2 => 'US_OD_C2FO'  -- Source
                                       ,argument3 => null --c_award_file_batch_name -- Group
                                       ,argument4 => c_award_file_batch_name -- Batch Name
                                       --,argument4 => 'C2FO ' || SYSDATE -- Batch Name
                                       ,argument5 => null   -- Hold Name
                                       ,argument6 => null   -- Hold Reason
                                       ,argument7 => null   -- GL Date
                                       ,argument8 =>'N'     -- Purge
                                       ,argument9 =>'N'     -- Trace Switch
                                       ,argument10 =>'N'    -- Debug Switch
                                       ,argument11 =>'N'     -- Summarize
                                       ,argument12 =>'1000'   -- Commit Batch
                                       ,argument13 =>l_user_id  -- User Id
                                       ,argument14 =>-1      -- Login Id
                                       );
        COMMIT;

        -------------

        IF lv_request_id = 0 THEN
           fnd_file.put_line(fnd_file.log,'Request Not Submitted due to "' || fnd_message.get || '".');
        ELSE
           fnd_file.put_line(fnd_file.log,'The Program "APXIIMPT - Payables Open Interface Import" submitted successfully – Request id :' || lv_request_id);
        END IF;

        IF lv_request_id > 0 THEN

            LOOP
                --
                --To make process execution to wait for 1st program to complete
                --
                l_req_return_status := fnd_concurrent.wait_for_request (request_id    => lv_request_id
                                                                        ,INTERVAL    => 15                 --interval Number of seconds to wait between checks
                                                                        ,max_wait     => 0                 --Maximum number of seconds to wait for the request completion                                             
                                                                        ,phase       => lc_phase          -- out argument
                                                                        ,status        => lc_status         -- out argument
                                                                        ,dev_phase     => lc_dev_phase     -- out argument
                                                                        ,dev_status    => lc_dev_status    -- out argument
                                                                        ,message    => lc_message         -- out argument
                                                                        );                        
                EXIT WHEN UPPER (lc_phase) = 'COMPLETED' OR UPPER (lc_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
            END LOOP;

                IF UPPER (lc_phase) = 'COMPLETED' AND UPPER (lc_status) = 'ERROR' THEN
                    fnd_file.put_line(fnd_file.log,'The "APXIIMPT - Payables Open Interface Import" completed in error. Oracle request id: '||lv_request_id ||' '||SQLERRM);
                ELSIF UPPER (lc_phase) = 'COMPLETED' AND UPPER (lc_status) = 'NORMAL' THEN
                    fnd_file.put_line(fnd_file.log,'The "APXIIMPT - Payables Open Interface Import" request successful for request id: ' || lv_request_id);
                ELSE
                    fnd_file.put_line(fnd_file.log,'The "APXIIMPT - Payables Open Interface Import" request failed. Oracle request id: ' || lv_request_id ||' '||SQLERRM);
                END IF;

        END IF;

        fnd_file.put_line(fnd_file.log,' Stage 04 - Submiting the Program - Payables Open Interface Import - Ends ');

        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,' Stage 05 - Updating the staging table based on the Program - Payables Open Interface Import Results - Starts ');

        FOR c2_award_rec IN c2_award LOOP

            BEGIN

            IF c2_award_rec.status = 'PROCESSED' THEN

                BEGIN
                    UPDATE xx_ap_c2fo_award_data_staging xads
                       SET xads.process_status = 'CM_CREATED',
                           xads.processed_date = SYSDATE,
                           xads.ebs_cm_invoice_id = (SELECT aia.invoice_id
                                                       FROM ap_invoices_all aia 
                                                      WHERE aia.org_id=c2_award_rec.ebs_org_id 
                                                        AND aia.vendor_id=c2_award_rec.ebs_vendor_id 
                                                        AND aia.vendor_site_id= c2_award_rec.ebs_vendor_site_id
                                                        AND aia.invoice_num=c2_award_rec.invoice_num),
                           xads.invoice_import_request_id=c2_award_rec.request_id,
						   xads.last_update_date = sysdate,
						   xads.last_updated_by = l_user_id						   
                    WHERE ROWID = c2_award_rec.c2fo_c2_rowid;
--                        AND award_file_batch_name = c_award_file_batch_name
--                        AND award_num = c2_award_rec.invoice_num
--                        AND ebs_org_id = c2_award_rec.ebs_org_id
--                        AND ebs_vendor_id = c2_award_rec.ebs_vendor_id
--                        AND ebs_vendor_site_id = c2_award_rec.ebs_vendor_site_id
--                        --AND c2_award_rec.status = 'PROCESSED'
--                        AND NVL(xads.process_flag, 'N') != 'E'
--                        AND xads.process_status = 'INTERFACED';

                EXCEPTION
                     WHEN OTHERS THEN
                        v_process_msg := 'Errors due to Payables Open Interface Import.'||'-'||sqlerrm;
                        UPDATE xx_ap_c2fo_award_data_staging xads
                           SET xads.process_status = 'ERROR',
                               xads.process_flag = 'E',
                               xads.error_msg = v_process_msg,
                               xads.invoice_import_request_id=c2_award_rec.request_id,
							   xads.last_update_date = sysdate,
							   xads.last_updated_by = l_user_id
                         WHERE ROWID = c2_award_rec.c2fo_c2_rowid;
--                        AND xads.award_file_batch_name = c_award_file_batch_name
--                        AND xads.award_num = c2_award_rec.invoice_num
--                        AND xads.ebs_org_id = c2_award_rec.ebs_org_id
--                        AND xads.ebs_vendor_id = c2_award_rec.ebs_vendor_id
--                        AND xads.ebs_vendor_site_id = c2_award_rec.ebs_vendor_site_id
--                        --AND c2_award_rec.status = 'PROCESSED'
--                        AND NVL(xads.process_flag, 'N') != 'E'
--                        AND xads.process_status = 'INTERFACED';

                END;

            ELSE

                BEGIN

                    UPDATE xx_ap_c2fo_award_data_staging xads
                       SET xads.process_status = 'INTERFACE_ERRORED',
                           xads.process_flag = 'E',
                           xads.processed_date = SYSDATE,
                           xads.invoice_import_request_id=c2_award_rec.request_id,
                           xads.error_msg = 'Errors due to Payables Open Interface Import.',
						   xads.last_update_date = sysdate,
					       xads.last_updated_by = l_user_id						   
                     WHERE ROWID = c2_award_rec.c2fo_c2_rowid;
--                        AND award_file_batch_name = c_award_file_batch_name
--                        AND award_num = c2_award_rec.invoice_num
--                        AND ebs_org_id = c2_award_rec.ebs_org_id
--                        AND ebs_vendor_id = c2_award_rec.ebs_vendor_id
--                        AND ebs_vendor_site_id = c2_award_rec.ebs_vendor_site_id
--                        --AND c2_award_rec.status != 'PROCESSED'
--                        AND NVL(xads.process_flag, 'N') != 'E'
--                        AND xads.process_status = 'INTERFACED';

                EXCEPTION
                     WHEN OTHERS THEN
                          v_process_msg := 'Errors due to Payables Open Interface Import.'||'-'||sqlerrm;

                          UPDATE xx_ap_c2fo_award_data_staging xads
                             SET xads.process_status = 'ERROR',
                                 xads.process_flag = 'E',
                                 xads.error_msg = v_process_msg,
                                 xads.invoice_import_request_id=c2_award_rec.request_id,
								 xads.last_update_date = sysdate,
								 xads.last_updated_by = l_user_id								 
                           WHERE ROWID = c2_award_rec.c2fo_c2_rowid;
--                            AND xads.award_file_batch_name = c_award_file_batch_name
--                            AND xads.award_num = c2_award_rec.invoice_num
--                            AND xads.ebs_org_id = c2_award_rec.ebs_org_id
--                            AND xads.ebs_vendor_id = c2_award_rec.ebs_vendor_id
--                            AND xads.ebs_vendor_site_id = c2_award_rec.ebs_vendor_site_id
--                            --AND c2_award_rec.status != 'PROCESSED'
--                            AND NVL(xads.process_flag, 'N') != 'E'
--                            AND xads.process_status = 'INTERFACED';

                END;
            END IF;    
            END;

        END LOOP;

        COMMIT;

        fnd_file.put_line(fnd_file.log,' Stage 05 - Updating the staging table based on the Program - Payables Open Interface Import Results - Ends ');

-----------*********************************************-----------------------    

        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');        
        fnd_file.put_line(fnd_file.log,' Stage 06.AA - Updating the due date for the created credit memos - Starts ');

        BEGIN

                SELECT COUNT(*)
                  INTO l_cm_dd_upd_rec_cnt
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   AND xads.process_status IN ('CM_CREATED')
                   AND xads.ebs_cm_invoice_id is not null
                   AND xads.process_flag = 'N';
        END;

        fnd_file.put_line(fnd_file.log,' Update credit memos count : -'||l_cm_dd_upd_rec_cnt);

        IF l_cm_dd_upd_rec_cnt != 0 THEN        

        FOR c5_award_rec IN c5_award LOOP

            BEGIN
				-- Modified for performance
                UPDATE ap_payment_schedules_all apsa
                   SET apsa.due_date = c5_award_rec.pay_date,
                       apsa.discount_date = NVL2(apsa.discount_date,c5_award_rec.pay_date,NULL),
                       apsa.second_discount_date  = NVL2(apsa.second_discount_date,c5_award_rec.pay_date,NULL),
                       apsa.third_discount_date  = NVL2(apsa.third_discount_date,c5_award_rec.pay_date,NULL),
					   apsa.last_update_date = sysdate,
					   apsa.last_updated_by = l_user_id,					   
					   apsa.last_update_login = fnd_global.login_id
                 WHERE 1 = 1
                   AND apsa.payment_status_flag||'' = 'N'
                   AND apsa.org_id+0 = c5_award_rec.ebs_org_id
                   AND apsa.invoice_id = c5_award_rec.ebs_cm_invoice_id;

            EXCEPTION
                WHEN OTHERS THEN
                     v_process_msg := 'Error while updating the credit memo pay date'||'-'||sqlerrm;
                     UPDATE xx_ap_c2fo_award_data_staging xads
                        SET xads.process_status = 'ERROR',
                            xads.process_flag = 'E',
                            xads.error_msg = v_process_msg,
							xads.last_update_date = sysdate,
							xads.last_updated_by = l_user_id							
                      WHERE ROWID = c5_award_rec.c2fo_c5_rowid;
--                        AND xads.award_file_batch_name = c_award_file_batch_name
--                        AND xads.award_num = c5_award_rec.award_num
--                        AND xads.ebs_org_id = c5_award_rec.ebs_org_id
--                        AND xads.ebs_vendor_id = c5_award_rec.ebs_vendor_id
--                        AND xads.ebs_vendor_site_id = c5_award_rec.ebs_vendor_site_id
--                        AND xads.ebs_invoice_id = c5_award_rec.ebs_cm_invoice_id
--                        AND NVL(xads.process_flag, 'N') != 'E'
--                        AND xads.process_status IN ('CM_CREATED');

            END;
        END LOOP;

        COMMIT;        

        ELSE

            fnd_file.put_line(fnd_file.log,'Stage 06.AA - There is no newly created credit memo records to update the due date.');

        END IF;

        fnd_file.put_line(fnd_file.log,' Stage 06.AA - Updating the due date for the created credit memos - Ends ');

-----------*********************************************-----------------------                    

        ELSE

           fnd_file.put_line(fnd_file.log,'     There is no valid records to run the Concurrent Program - Payables Open Interface Import.');

        END IF;


        -------

        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');        
        fnd_file.put_line(fnd_file.log,' Stage 06.BB - Updating the due date for the existing invoice - Starts ');            

        BEGIN

                SELECT COUNT(*)
                  INTO l_act_inv_dd_upd_rec_cnt
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   AND xads.process_status IN ('UPDATE_DUE_DATE_ONLY_REC','CM_CREATED')
                   AND xads.process_flag = 'N';        

        END;

        IF l_act_inv_dd_upd_rec_cnt != 0 THEN

        FOR c3_award_rec IN c3_award LOOP

            BEGIN
				-- Modified for performance
                UPDATE ap_payment_schedules_all apsa
                   SET apsa.due_date = c3_award_rec.pay_date,
                       apsa.discount_date = NVL2(apsa.discount_date,c3_award_rec.pay_date,NULL),
                       apsa.second_discount_date  = NVL2(apsa.second_discount_date,c3_award_rec.pay_date,NULL),
                       apsa.third_discount_date  = NVL2(apsa.third_discount_date,c3_award_rec.pay_date,NULL),
					   apsa.last_update_date = sysdate,
					   apsa.last_updated_by = l_user_id,
					   apsa.last_update_login = fnd_global.login_id
                 WHERE 1 = 1
                   AND apsa.payment_status_flag||'' = 'N'
                   AND apsa.org_id+0 = c3_award_rec.ebs_org_id
                   AND apsa.invoice_id = c3_award_rec.ebs_invoice_id;
                   
            EXCEPTION
                WHEN OTHERS THEN
                     v_process_msg := 'Error while updating the pay date'||'-'||sqlerrm;
                     UPDATE xx_ap_c2fo_award_data_staging xads
                        SET xads.process_status = 'ERROR',
                            xads.process_flag = 'E',
                            xads.error_msg = v_process_msg,
							xads.last_update_date = sysdate,
							xads.last_updated_by = l_user_id							
                      WHERE ROWID = c3_award_rec.c2fo_c3_rowid;
--                        AND xads.award_file_batch_name = c_award_file_batch_name
--                        AND xads.award_num = c3_award_rec.award_num
--                        AND xads.ebs_org_id = c3_award_rec.ebs_org_id
--                        AND xads.ebs_vendor_id = c3_award_rec.ebs_vendor_id
--                        AND xads.ebs_vendor_site_id = c3_award_rec.ebs_vendor_site_id
--                        AND xads.ebs_invoice_id = c3_award_rec.ebs_invoice_id
--                        AND NVL(xads.process_flag, 'N') != 'E'
--                        AND xads.process_status IN ('UPDATE_DUE_DATE_ONLY_REC','CM_CREATED');

            END;
        END LOOP;

        COMMIT;

        ELSE

            fnd_file.put_line(fnd_file.log,' Stage 06.BB - There is no valid existing Invoice records to update the due date.');

        END IF;

        fnd_file.put_line(fnd_file.log,' Stage 06.BB - Updating the due date for the existing invoice - Ends ');


-----------*********************************************-----------------------            


        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');        
        fnd_file.put_line(fnd_file.log,' Stage 07 - Updating the status for processed records - Starts ');        

        BEGIN

            UPDATE xx_ap_c2fo_award_data_staging xads
               SET xads.process_status = 'PROCESSED',
                   xads.process_flag = 'Y',
                   xads.processed_date = SYSDATE,
				   xads.last_update_date = sysdate,
				   xads.last_updated_by = l_user_id				   
             WHERE 1 = 1
               AND xads.award_file_batch_name = c_award_file_batch_name
               AND xads.process_status IN ('UPDATE_DUE_DATE_ONLY_REC','CM_CREATED')
               AND xads.process_flag = 'N';

        END;

        COMMIT;


        fnd_file.put_line(fnd_file.log,' Stage 07 - Updating the status for processed records - Ends ');
        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');


---------@@@@@@@@@@@@@*********************-------------------

            BEGIN
                SELECT COUNT(*)
                  INTO l_award_file_record_count
                  FROM xx_ap_c2fo_award_data_external;

                fnd_file.put_line(fnd_file.log,'Award File Record count FROM XX_AP_C2FO_MEMO_DATA_EXTERNAL is -  '|| l_award_file_record_count|| '.');
            END;

            BEGIN
                SELECT COUNT(*)
                  INTO l_stg_table_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                  where xads.award_file_batch_name = c_award_file_batch_name;

                fnd_file.put_line(fnd_file.log,'Staging Table Record count FROM xx_ap_c2fo_award_data_staging is -  '|| l_stg_table_record_count|| '.');
            END;

            BEGIN
                SELECT COUNT(*)
                  INTO l_stg_success_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                  where xads.award_file_batch_name = c_award_file_batch_name
                  AND xads.process_flag = 'Y'
                  AND xads.process_status = 'PROCESSED';

                fnd_file.put_line(fnd_file.log,'Successfully processed records is -  '|| l_stg_success_record_count|| '.');
            END;

            BEGIN
                SELECT COUNT(*)
                  INTO l_stg_error_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   AND xads.process_flag != 'Y'
                   AND xads.process_status != 'PROCESSED';

                fnd_file.put_line(fnd_file.log,'Total Error Records is -  '|| l_stg_error_record_count|| '.');

            END;

            BEGIN
                SELECT COUNT(*)
                  INTO l_possible_cm_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   AND xads.award_record_activities = 'CREATE_CM_AND_UPDATE_DUE_DATE';

                fnd_file.put_line(fnd_file.log,'Posible credit memo record count - '|| l_possible_cm_record_count|| '.');
            END;

            BEGIN
                SELECT COUNT(*)
                  INTO l_created_cm_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   AND xads.award_record_activities = 'CREATE_CM_AND_UPDATE_DUE_DATE'
                   AND xads.process_status = 'PROCESSED'
                   AND xads.process_flag = 'Y';                    

                fnd_file.put_line(fnd_file.log,'Created credit memo record count - '|| l_created_cm_record_count|| '.');
            END;                        

            BEGIN
                SELECT COUNT(*)
                  INTO l_erreored_cm_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   AND xads.award_record_activities = 'CREATE_CM_AND_UPDATE_DUE_DATE'
                   AND xads.process_status != 'PROCESSED'
                   AND xads.process_flag = 'E';        

                fnd_file.put_line(fnd_file.log,'Errored credit memo record count - '|| l_erreored_cm_record_count|| '.');
            END;        

            BEGIN
                SELECT COUNT(*)
                  INTO l_dd_update_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   AND xads.process_status = 'PROCESSED'
                   AND xads.process_flag = 'Y';        

                fnd_file.put_line(fnd_file.log,'Updated (Invoices and Credit memo) due date record count - '|| l_dd_update_record_count|| '.');
            END;

            BEGIN
                SELECT COUNT(*)
                  INTO l_duplicate_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   AND xads.process_status = 'DUPLICATE';

                    fnd_file.put_line(fnd_file.log,'Duplicate Record count - '|| l_duplicate_record_count|| '.');
            END;            

---------@@@@@@@@@@@@@*********************-------------------


        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');        
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Award Process Completed');
        fnd_file.put_line(fnd_file.log,' ');
        fnd_file.put_line(fnd_file.log,' ');        

    END process_award;

END xx_ap_c2fo_award_pkg; 
/
SHOW ERRORS