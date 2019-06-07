SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_C2FO_AWARD_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

create or replace 
PACKAGE BODY XX_AP_C2FO_AWARD_PKG AS
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
*   1.1        11/26/2018         Vivek Kumar                                      Added XPTR option - NAIT -63055  |
*   1.2        04/18/2019         Arun DSouza                                     Added Funding Partner Code        |
*   1.3        06/07/2019         Arun DSouza                   OD                Added debit balance pay group     |
*********************************************************************************************************************
*/


 /***************************************************************/
 /* PROCEDURE PROCESS_AWARD                                     */
 /* Procedure to process award data                             */
 /***************************************************************/

    PROCEDURE PROCESS_AWARD(errbuf        OUT VARCHAR2,
                            retcode       OUT NUMBER,
                            p_file_prefix  IN VARCHAR2
                           ) is
        c_award_file_batch_name VARCHAR2(50) := 'XX_AP_C2FO'||'-'||TO_CHAR(SYSDATE,'RRRRMMDDHH24MISS');
 
        v_status                        VARCHAR2(1);
        v_record_count                  NUMBER;
        v_errbuf                        VARCHAR2(500);
        v_retcode                       NUMBER;
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
        lc_boolean                      BOOLEAN;  --NAIT 63055
	    	lc_boolean1						BOOLEAN;  --NAIT 63055

-----------------------Phase-2--------------------------------------------------------
 -- Funding Partner local variables Below 
--------------------------------------------------------------------------------------
        lv_c2fo_pay_group_lookup_code 	varchar2(50) 	:= 'US_OD_TRADE_SPECIAL_TERMS'; 
        -- nvl(fnd_profile.value('XXC2FO_PAY_GROUP_LOOKUP_CODE'),'C2FO');
--        lc_user_id                       NUMBER := fnd_global.user_id;
        lv_process_r_cnt                 NUMBER(9) DEFAULT 0;
--        lv_file_name                     VARCHAR2(240);
--        lv_file_status                   VARCHAR2(1);
        LV_PROCESS_FLAG                  VARCHAR2(1);
     		lv_process_stage 			        	 VARCHAR2(50);
        lv_process_msg                   VARCHAR2(2000);
        lv_sup_hold_flag                 VARCHAR2(1);
        lv_sup_hold_all_payments_flag    VARCHAR2(1);
        lv_site_hold_all_payments_flag   VARCHAR2(1);
        lv_invoice_num                   VARCHAR2(50);
        lv_err_msg                       VARCHAR2(2000);
        lv_tot_err_msg                   VARCHAR2(2000);
        lv_cp_status                     VARCHAR2(50);
        lv_cp_phase                      VARCHAR2(50);
        lv_cp_dev_phase                  VARCHAR2(50);
        lv_cp_dev_status                 VARCHAR2(50);
        lv_cp_message                    VARCHAR2(50);
        lv_cp_req_return_status          BOOLEAN;
        lv_inv_id_seq_id                 NUMBER;
        lv_hold_invoice_id               NUMBER;
        lv_inv_import_request_id         NUMBER;
        lv_cms_inv_val_request_id        NUMBER;
        lv_inv_pur_request_id            NUMBER;
        lv_r_cnt                         NUMBER;
        lv_award_num_r_cnt               NUMBER;
        lv_liability_ccid_r_cnt          NUMBER;
        lv_inv_iface_r_cnt               NUMBER;
        lv_staging_r_cnt                 NUMBER;
        lv_current_processing_r_cnt      NUMBER;
        lv_previous_rejected_r_cnt       NUMBER;
        lv_act_inv_dd_dd_upd_r_cnt       NUMBER;
        lv_cms_dd_dd_upd_r_cnt           NUMBER;
        lv_award_file_r_cnt              NUMBER;
        lv_possible_cms_r_cnt            NUMBER;
        lv_created_cms_r_cnt             NUMBER;
        lv_erreored_cms_r_cnt            NUMBER;
        lv_dd_dd_update_r_cnt            NUMBER;
        lv_duplicate_r_cnt               NUMBER;
        lv_stg_success_r_cnt             NUMBER;
        lv_stg_err_r_cnt                 NUMBER;

-----------------------Phase-2-------End-------------------------------------------------


		lv_fp_relationship_cnt 			NUMBER;
		lv_fp_active_relationship_cnt  	NUMBER;
		lv_fp_rs_seq_id             	NUMBER;
		lv_fp_ebs_relationship_id       NUMBER;			
		lv_fp_relationship_id       	NUMBER;
		lv_fp_ebs_inv_amt_after_disc	NUMBER;
		
		lv_fp_duplicate_r_cnt 			NUMBER;
		lv_fp_stg_err_r_cnt 			NUMBER;
		lv_fp_stg_success_r_cnt 		NUMBER;
		lv_fp_award_file_r_cnt 			NUMBER;
		lv_fp_staging_r_cnt 			NUMBER;
		lv_fp_current_processing_r_cnt 	NUMBER;
		lv_fp_previous_rejected_r_cnt 	NUMBER;


     CURSOR c1_batch_all IS
        SELECT *
          FROM xx_ap_c2fo_award_data_staging xmd
         WHERE 1=1
           AND xmd.award_file_batch_name = c_award_file_batch_name;
           
-----------------------Phase-1--------------------------------------------------------
 -- Early Payment Discounting Credit Memo Cursors Below 
 -- Processes only award_record_activities = 'CREATE_CM_AND_UPDATE_DUE_DATE'
 -------------------------------------------------------------------------------

         -- cmdd Credit_Memo_Due_date
        
        CURSOR c2_early_pay_cmdd IS
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

        CURSOR c3_credit_memo_intf IS
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

       CURSOR c4_cm_created IS
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
                  AND xmd.process_flag = 'N'
                  AND xmd.award_record_activities = 'CREATE_CM_AND_UPDATE_DUE_DATE';  -- fp_added


        CURSOR c5_upd_due_dt IS
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
           AND xmd.process_flag = 'N'
           AND xmd.award_record_activities = 'CREATE_CM_AND_UPDATE_DUE_DATE'; -- fp_added

 -----------------------Phase-2--------------------------------------------------------
 -- Funding Partner Buyer Toggle Cursors Below 
 -- Processes only award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
 --------------------------------------------------------------------------------------
 
 	--+===========================================================================================================+
		--  Purpose -- Cursor To Validate The Current Processing Batch Records.
		--   		-- Current Processing Batch Records ( Current Award File Records And Previous Error Records)
		--   		-- Previous Error Records ( Validation Failed Records and Payables Import Program Rejected Records)		
		--+============================================================================================================+

        CURSOR C_VAL_DTLS IS SELECT *
                               FROM xx_ap_c2fo_award_data_staging xads
                              WHERE 1 = 1
                      --          AND xads.processing_batch_name = gc_current_process_batch_name
                               AND xads.processing_batch_name = c_award_file_batch_name
								AND xads.process_flag = 'N'
								AND xads.process_stage = 'UPDATE_RD_AND_PG';

		--+===========================================================================================================+
		--  Purpose -- Cursor to Validate the remit details.
		--+============================================================================================================+								

        CURSOR c_cr_relation IS SELECT xads.ebs_org_id,
										xads.ebs_vendor_id,
										xads.ebs_vendor_site_id,
										xads.award_file_batch_name,
										xads.award_record_activities,
										xads.process_flag,
										xads.process_stage,
	--									xads.error_msg,
										xads.fund_type,
										xads.ebs_party_id,
										xads.ebs_party_site_id,
										xads.ebs_remit_to_party_id,
										xads.ebs_remit_to_party_site_id,
										xads.ebs_remit_to_vendor_site_id,
										xads.ebs_relationship_id,
										XADS.EBS_RELATIONSHIP_CNT,
										XADS.EBS_OLDEST_OPEN_INV_DATE,
--                    xads.original_due_date,
										XADS.EBS_EXT_BANK_ACCOUNT_ID
							  FROM xx_ap_c2fo_award_data_staging xads
								  WHERE 1 = 1
--									AND xads.processing_batch_name = gc_current_process_batch_name
									AND xads.award_file_batch_name = c_award_file_batch_name              
									AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
									AND xads.process_stage = 'SUCCESSFULLY_VALIDATED'
									AND xads.process_flag = 'N'
							   GROUP BY xads.ebs_org_id,
										xads.ebs_vendor_id,
										xads.ebs_vendor_site_id,
										xads.award_file_batch_name,
										xads.award_record_activities,
										xads.process_flag,
										XADS.PROCESS_STAGE,
--										xads.error_msg,
										xads.fund_type,
										xads.ebs_party_id,
										xads.ebs_party_site_id,
										xads.ebs_remit_to_party_id,
										xads.ebs_remit_to_party_site_id,
										xads.ebs_remit_to_vendor_site_id,
										xads.ebs_relationship_id,
										XADS.EBS_RELATIONSHIP_CNT,
										xads.ebs_oldest_open_inv_date,
--                    xads.original_due_date,
										xads.ebs_ext_bank_account_id;

		--+===========================================================================================================+
		--  Purpose -- Cursor to update the invoice details 
					-- Invoice types 1 and 2 (standard invoices, credit memos etc...)
					-- Update the invoice Remittance details.
					-- Update the invoice pay group.					
		--+============================================================================================================+								

        CURSOR c_upd_fp_inv_rd_pg_dtls IS SELECT xads.rowid	stg_rowid,
												aia.rowid	inv_rowid,
												aia.invoice_id,
												aia.vendor_id,
												aia.invoice_num,
												aia.vendor_site_id,
												aia.invoice_type_lookup_code,
												aia.terms_id,
												aia.org_id,
												aia.party_id,
												aia.party_site_id,
												xads.ebs_ext_bank_account_id,
												xads.ebs_remit_to_supplier_name,
												xads.ebs_remit_to_vendor_id,
												xads.ebs_remit_to_supplier_site,
												xads.ebs_remit_to_vendor_site_id,
												xads.ebs_relationship_id
								           FROM AP_INVOICES_ALL AIA,
												        xx_ap_c2fo_award_data_staging xads
								          WHERE 1 = 1
											AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
											AND xads.process_stage = 'FUND_TYPE_RS_CREATED_OR_ONE_ACTIVE_RS_EXISTS'
											AND xads.process_flag = 'N'
											AND xads.ebs_vendor_id = aia.vendor_id
											AND xads.ebs_vendor_site_id = aia.vendor_site_id
											AND xads.ebs_org_id = aia.org_id
											AND xads.ebs_invoice_id = aia.invoice_id
											AND xads.award_file_batch_name = c_award_file_batch_name;
--											AND xads.processing_batch_name = gc_current_process_batch_name;

		--+===========================================================================================================+
		--  Purpose -- Cursor to update the invoice payment schedules details 
					-- Invoice types 1 and 2 (standard invoices, credit memos etc...)
					-- Update the invoice payment schedule Remittance details.
		--+============================================================================================================+								

        CURSOR c_upd_fp_inv_ps_rd_pg_dtls IS SELECT xads.rowid	stg_ps_rowid,
													apsa.rowid	inv_ps_rowid,
													apsa.invoice_id,
													xads.ebs_invoice_num,
													apsa.org_id,												
													xads.ebs_remit_to_supplier_name,
													xads.ebs_remit_to_vendor_id,
													xads.ebs_remit_to_supplier_site,
													xads.ebs_remit_to_vendor_site_id,
													xads.ebs_relationship_id,
													xads.ebs_ext_bank_account_id
											   FROM AP_PAYMENT_SCHEDULES_ALL APSA,
													    xx_ap_c2fo_award_data_staging xads
											  WHERE 1 = 1
												AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
												AND xads.process_stage = 'FP_INVOICE_RD_PG_UPDATED'
												AND xads.process_flag = 'N'
												AND xads.ebs_org_id = apsa.org_id
												AND xads.ebs_invoice_id = apsa.invoice_id
												AND apsa.payment_num = 1
												AND xads.award_file_batch_name = c_award_file_batch_name;		
--												AND xads.processing_batch_name = gc_current_process_batch_name;			                        

		--+===========================================================================================================+
		--  Purpose -- Cursor Definitions - ENDS.			
		--+============================================================================================================+								  

 

    BEGIN
 
        fnd_file.put_line(fnd_file.log,'Step-1');
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
        
--        v_file_name := 'xxdd_c2fo_award.csv';
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
        fnd_file.put_line(fnd_file.log,'Step-2');
 
 
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

       fnd_file.put_line(fnd_file.log,'Step-3');
 

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

       fnd_file.put_line(fnd_file.log,'Step-4');
 

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

      FND_FILE.PUT_LINE(FND_FILE.log,'Step-4.1 Update Funding Source ');

 
   begin
   
		UPDATE XX_AP_C2FO_FP_FUNDING_SOURCE xcfst
			   SET (xcfst.fund_bank_account_num
					,xcfst.fund_currency_code
					,xcfst.fund_ext_bank_account_id
					,xcfst.fund_bank_name
					,xcfst.fund_bank_number
					,xcfst.fund_bank_id
					,xcfst.fund_branch_name
					,xcfst.fund_branch_number
					,xcfst.fund_branch_id
					,xcfst.fund_org_id
					,xcfst.fund_vendor_id
					,xcfst.fund_vendor_site_id
					,xcfst.fund_party_id
					,xcfst.fund_party_site_id
					,xcfst.fund_supplier_number
					,xcfst.fund_sup_enabled_flag
					,xcfst.fund_sup_end_date_active
					,xcfst.fund_sup_hold_flag
					,xcfst.fund_sup_hold_all_pay_flag
					,xcfst.fund_sup_site_pay_site_flag
					,xcfst.fund_sup_site_hold_all_pay_flg
					,XCFST.FUND_SUP_SITE_INACTIVE_DATE
					,xcfst.fund_sup_site_bank_start_date
					,xcfst.fund_sup_site_bank_end_date
					,xcfst.last_updated_by
					,xcfst.last_update_date
					)
					=
					(
			  SELECT ieba.bank_account_num
					,ieba.currency_code
					,ieba.ext_bank_account_id
					,party_bank.party_name
					,branch_prof.bank_or_branch_number
					,ieba.bank_id fund_bank_id
					,party_branch.party_name
					,branch_prof.bank_or_branch_number
					,ieba.branch_id
					,assa.org_id
					,assa.vendor_id
					,assa.vendor_site_id
					,sup.party_id
					,assa.party_site_id
					,sup.segment1
					,sup.enabled_flag
					,sup.end_date_active
					,NVL(sup.hold_flag,'N')
					,sup.hold_all_payments_flag
					,ASSA.PAY_SITE_FLAG
					,assa.hold_all_payments_flag
					,ASSA.INACTIVE_DATE
					,nvl(ipiua.start_date,sysdate-30)
					,ipiua.end_date
					,l_user_id
					,SYSDATE
			   FROM  hz_parties party_supp
					,ap_suppliers sup
					,hz_party_sites site_supp
					,ap_supplier_sites_all assa
					,iby_external_payees_all iepa
					,iby_pmt_instr_uses_all ipiua
					,iby_ext_bank_accounts ieba
					,hz_parties party_bank
					,hz_parties party_branch
					,hz_organization_profiles bank_prof
					,hz_organization_profiles branch_prof
					,hr_all_organization_units haou
    WHERE 1=1
				AND party_supp.party_id = sup.party_id
				AND party_supp.party_id = site_supp.party_id
				AND assa.org_id = haou.organization_id
				AND site_supp.party_site_id = assa.party_site_id
				AND assa.vendor_id = sup.vendor_id
				AND iepa.payee_party_id = party_supp.party_id
				AND iepa.party_site_id = site_supp.party_site_id
				AND iepa.supplier_site_id = assa.vendor_site_id
				AND iepa.ext_payee_id = ipiua.ext_pmt_party_id (+)
				AND ipiua.instrument_id (+) = ieba.ext_bank_account_id 
				AND ieba.bank_id = party_bank.party_id 
				AND ieba.bank_id = party_branch.party_id
				AND party_branch.party_id = branch_prof.party_id
				AND party_bank.party_id = bank_prof.party_id
--				AND haou.NAME =  'OU_US' -- xcfst.fund_operating_unit
				AND haou.NAME =   xcfst.fund_operating_unit
				AND party_supp.party_name = xcfst.fund_supplier_name
				AND assa.vendor_site_code = xcfst.fund_supplier_site
				AND ieba.bank_account_name = xcfst.fund_bank_account_name
--				AND party_supp.party_name like 'SEVENTH GENERATION%'
--				AND assa.vendor_site_code = 'TST781210PY'
--				AND ieba.bank_account_name = '121000358 19620064'
				AND nvl(sup.hold_flag,'N') = 'N'
				AND sup.hold_all_payments_flag = 'N'
				AND assa.hold_all_payments_flag = 'N');

		commit;		
		end;


       fnd_file.put_line(fnd_file.log,'Step-5');
 

            BEGIN
            
---------------Phase-1-----Phase-2------Combined-Insert--------------------------------------------------
 -- Insert records into Staging table from External table for both Phase 1 and Phase 2
 -- Added extra funding partner columns for Phase 2
 --------------------------------------------------------------------------------------------------------                  
            
            fnd_file.put_line(fnd_file.log,'   ');
            fnd_file.put_line(fnd_file.log,'   ');
            fnd_file.put_line(fnd_file.log,' Stage 01 - insert the records into table xx_ap_c2fo_award_data_staging - Starts ');

                INSERT
                  INTO XX_AP_C2FO_AWARD_DATA_STAGING
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
                       PROCESSED_DATE                ,
                       ERROR_MSG                     ,
        -- new fields added below for FP
                       FUND_TYPE		
                      ,EBS_PARTY_ID					
                      ,EBS_PARTY_SITE_ID				
                      ,EBS_REMIT_TO_SUPPLIER_NAME	
                      ,EBS_REMIT_TO_SUPPLIER_SITE
                      ,EBS_REMIT_TO_VENDOR_ID		
                      ,EBS_REMIT_TO_VENDOR_SITE_ID	
                      ,EBS_REMIT_TO_PARTY_ID		
                      ,EBS_REMIT_TO_PARTY_SITE_ID	
                      ,EBS_RELATIONSHIP_ID			
                      ,EBS_RELATIONSHIP_CNT			
                      ,EBS_OLDEST_OPEN_INV_DATE	
                      ,EBS_EXT_BANK_ACCOUNT_ID	
                      ,SUPPLIER_BANK_ACCOUNT_ID
                      ,CREATION_DATE		
                      ,CREATED_BY		
                      ,LAST_UPDATE_DATE	
                      ,LAST_UPDATED_BY	                       
                       )
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
                       XMDE.VAT_TO_BE_DISCOUNTED,
        (ROUND((NVL(xmde.original_vat,0)*100)/(NVL(xmde.ebs_inv_amt_before_cash_disc,0)),2)),
                       --ebs_invoice_tax_rate
                       (ROUND(((NVL(XMDE.INCOME,0))*NVL(XMDE.EBS_INV_AMT_BEFORE_CASH_DISC,0))/(NVL(XMDE.ORIGINAL_VAT,0)+NVL(XMDE.EBS_INV_AMT_BEFORE_CASH_DISC,0)),2)),
                       --if_inv_tobe_dis_1_cm_line_amt
                       (ROUND(((NVL(XMDE.INCOME,0))*((NVL(XMDE.EBS_INV_AMT_BEFORE_CASH_DISC,0))+(NVL(XMDE.ORIGINAL_VAT,0))))/NVL(XMDE.EBS_INV_AMT_BEFORE_CASH_DISC,0),2)),
                       --if_inv_tobe_dis_0_cm_amt
                       (CASE NVL(xmde.income,0) WHEN 0 THEN NULL
                                                ELSE NVL2(xmde.ebs_voucher_num,(xmde.ebs_invoice_num||xmde.ebs_voucher_num||'C2FO'),(xmde.ebs_invoice_num||'AWARD'))
                       END),
                       -- award_num
                       (CASE NVL(xmde.income,0) WHEN 0 THEN NULL
                                                ELSE NVL2(xmde.ebs_voucher_num,( 'Award file for Invoice/Voucher '||xmde.ebs_invoice_num||xmde.ebs_voucher_num||
                                                     'C2FO'),('Award file for Invoice '|| xmde.ebs_invoice_num))
                       END),
                       --award_description
                       CURRENCY, --invoice_currency_code
                       local_currency_key, --payment_currency_code
                       (SELECT AIA.PAYMENT_METHOD_CODE FROM AP_INVOICES_ALL AIA WHERE AIA.ORG_ID=XMDE.EBS_ORG_ID AND AIA.INVOICE_ID=XMDE.EBS_INVOICE_ID),
                       EBS_PAY_GROUP, --pay_group_lookup_code
                       NULL, --c_liability_ccid, (fpdiff not commented in fp code)
                       DECODE(EBS_ORG_ID, 404, G_US_EXPENSE_CCID, G_CA_EXPENSE_CCID),  --c_expense_ccid, (fpdiff added org_id in prod)
                       c_memo_term_id, -- (fpdiff in fp fetched from invoices, in prod from ap_terms and c2fo system profile)
                       buyer_name,
                       ebs_supplier_number,
                       ebs_vendor_site_code,
                       ebs_invoice_num,
                       ebs_voucher_num,
                       ebs_org_id,
                       ebs_vendor_id,
                       ebs_vendor_site_id,
                       ebs_invoice_id,
                        NULL, --ebs_cm_invoice_id
                       0,    --invoice_import_request_id
                       SYSDATE, --stage_date
                        C_AWARD_FILE_BATCH_NAME, -- award_file_batch_name (fpdiff different names set in pkg spec global variable) 
                       --PROCESSING_BATCH_NAME  (fpdiff new column same as award_file_batch_name)	
                       (CASE NVL(xmde.income,0) WHEN 0 THEN 'UPDATE_DUE_DATE'
                                                ELSE 'CREATE_CM_AND_UPDATE_DUE_DATE'
                       END), --award_record_activities
                       /*  fpdiff new case stmt                    
                       (CASE NVL(xmde.income,0) WHEN 0 THEN 'UPDATE_DD_DD_AND_PG'
                            ELSE 'CREATE_CM_UPD_DD_DD_AND_UPDATE_DD_DD_PG' 
                        END),                   
                       
                        */                      
                       'N',  --process_flag
                       CASE (SELECT COUNT(*)
                               FROM xx_ap_c2fo_award_data_staging xmds
                              WHERE xmds.process_status= 'PROCESSED'
                                AND process_flag = 'Y'
                                AND xmds.company_id = xmde.company_id
                                AND XMDS.INVOICE_ID = XMDE.INVOICE_ID) 
                          WHEN 0 THEN DECODE(NVL(INCOME,0),0,'UPDATE_DUE_DATE_ONLY_REC',
                                                            'STAGED_FOR_INTERFACE_REC')
                          ELSE 'DUPLICATE'
                       END, --process_status                    
 /*    fpdiff                                      
					CASE (SELECT COUNT(*) 
             FROM xx_ap_c2fo_award_data_staging xads 
               WHERE xads.process_stage= 'SUCCESSFULLY_PROCESSED' 
               AND process_flag = 'Y' 
               AND xads.company_id = xade.company_id 
               AND xads.invoice_id = xade.invoice_id )
				 WHEN 0 THEN DECODE(NVL(xade.income,0),0,'UPDATE_DUE_DATES_PAY_GROUP_ONLY',
                             'STAGED_FOR_INTERFACE')
               ELSE 'DUPLICATE' 
         END,                                                                
 */                      
                       null, --processed_date
                       NULL,  --error_msg
 -- added new fields below for FP
 						fund_type,
						(select aia.party_id from ap_invoices_all aia where aia.org_id=xmde.ebs_org_id and aia.invoice_id=xmde.ebs_invoice_id),
             --EBS_PARTY_ID
						(select aia.party_site_id from ap_invoices_all aia where aia.org_id=xmde.ebs_org_id and aia.invoice_id=xmde.ebs_invoice_id),
            --EBS_PARTY_SITE_ID
--            null,  
						(select XCFST.FUND_SUPPLIER_NAME from XX_AP_C2FO_FP_FUNDING_SOURCE XCFST), -- where 1=1 and XCFST.FUND_TYPE = XMDE.FUND_TYPE and sysdate between XCFST.FUND_SUP_SITE_BANK_START_DATE and NVL(XCFST.FUND_SUP_SITE_BANK_END_DATE,sysdate+1)),
            --EBS_REMIT_TO_SUPPLIER_NAME
						(select xcfst.fund_supplier_site from xx_ap_c2fo_fp_funding_source xcfst), -- where 1=1 and xcfst.fund_type = xmde.fund_type and sysdate between xcfst.fund_sup_site_bank_start_date and nvl(xcfst.fund_sup_site_bank_end_date,sysdate+1)),
            --EBS_REMIT_TO_SUPPLIER_SITE
						(select xcfst.fund_vendor_id from xx_ap_c2fo_fp_funding_source xcfst), -- where 1=1 and xcfst.fund_type = xmde.fund_type and sysdate between xcfst.fund_sup_site_bank_start_date and nvl(xcfst.fund_sup_site_bank_end_date,sysdate+1)),						
            --EBS_REMIT_TO_VENDOR_ID
						(select xcfst.fund_vendor_site_id from xx_ap_c2fo_fp_funding_source xcfst), --  where 1=1 and xcfst.fund_type = xmde.fund_type and sysdate between xcfst.fund_sup_site_bank_start_date and nvl(xcfst.fund_sup_site_bank_end_date,sysdate+1)),												
            --EBS_REMIT_TO_VENDOR_SITE_ID
						(select xcfst.fund_party_id from xx_ap_c2fo_fp_funding_source xcfst), -- where 1=1 and xcfst.fund_type = xmde.fund_type and sysdate between xcfst.fund_sup_site_bank_start_date and nvl(xcfst.fund_sup_site_bank_end_date,sysdate+1)),
             --EBS_REMIT_TO_PARTY_ID
						(select xcfst.fund_party_site_id from xx_ap_c2fo_fp_funding_source xcfst), -- where 1=1 and xcfst.fund_type = xmde.fund_type and sysdate between xcfst.fund_sup_site_bank_start_date and nvl(xcfst.fund_sup_site_bank_end_date,sysdate+1)),
            --EBS_REMIT_TO_PARTY_SITE_ID
						null,
            --EBS_RELATIONSHIP_ID
						null,
            --EBS_RELATIONSHIP_CNT
						(select min(aia.invoice_date) from ap_invoices_all aia 
							WHERE 1=1 
							  AND aia.org_id= xmde.ebs_org_id 
							  AND aia.vendor_id = xmde.ebs_vendor_id 
							  AND aia.vendor_site_id = xmde.ebs_vendor_site_id
							  AND nvl(aia.prepay_flag,'N') = 'N'
							  AND nvl(aia.pay_group_lookup_code,'X') <> 'C2FO'
							  AND aia.invoice_type_lookup_code NOT IN ('EXPENSE REPORT','PREPAYMENT')
							  and nvl(aia.amount_paid,0) = 0),
            -- EBS_OLDEST_OPEN_INV_DATE
						(select xcfst.fund_ext_bank_account_id from xx_ap_c2fo_fp_funding_source xcfst), -- where 1=1 and xcfst.fund_type = xmde.fund_type and sysdate between xcfst.fund_sup_site_bank_start_date and nvl(xcfst.fund_sup_site_bank_end_date,sysdate)),
           -- EBS_EXT_BANK_ACCOUNT_ID
            (SELECT AIA.EXTERNAL_BANK_ACCOUNT_ID FROM AP_INVOICES_ALL AIA WHERE AIA.ORG_ID=XMDE.EBS_ORG_ID AND AIA.INVOICE_ID=XMDE.EBS_INVOICE_ID), 			
            -- SUPPLIER_BANK_ACCOUNT_ID
        		    SYSDATE, --creation_date
						l_user_id,   --created_by
						sysdate,     --last_update_date
						l_user_id    --last_updated_by
        FROM xx_ap_c2fo_award_data_external XMDE
         WHERE 1=1;
            

                COMMIT;
 
        fnd_file.put_line(fnd_file.log,'Step-6');
 
                 
 -----------------------Phase-2--------------------------------------------------------
 -- Funding Partner Buyer Toggle 
 -- Updates Staging table award_record_activities column to 'UPDATE_RD_AND_PG_TYPE'
 --------------------------------------------------------------------------------------       
  	--+===========================================================================================================+
		--  STEP#04
		--  Purpose -- Update the staging table "xx_ap_c2fo_award_data_staging" for Reprocessing - STARTS.			
		--+============================================================================================================+

				 UPDATE xx_ap_c2fo_award_data_staging xads
					SET xads.process_stage = 'UPDATE_RD_AND_PG',
						xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE',
						xads.last_update_date = SYSDATE,
						xads.last_updated_by = l_user_id
				  WHERE 1 = 1
  					AND xads.award_file_batch_name = c_award_file_batch_name
--					AND xads.award_file_batch_name = gc_current_process_batch_name
	  				AND xads.fund_type IS NOT NULL
		  			AND xads.process_flag = 'N';

   COMMIT;			
 
        fnd_file.put_line(fnd_file.log,'Step-7');
              
 -------------------Phase-2-----End -------------------------               
                

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
                    fnd_file.put_line(fnd_file.log,'Error inserting records into xx_ap_c2fo_award_data_external table.  ' || sqlerrm);
                    retcode := 1;
            END;

        END IF;

       fnd_file.put_line(fnd_file.log,'Step-8');
 

        fnd_file.put_line(fnd_file.log,' Stage 01 - insert the records into table xx_ap_c2fo_award_data_staging - Ends ');


 -----------------------Phase-2--------------------------------------------------------
 -- Funding Partner Buyer Toggle 
 -- Updates Staging table award_record_activities column to 'UPDATE_RD_AND_PG_TYPE'
 -- To Re-process old Error Records
 --------------------------------------------------------------------------------------       

              SELECT COUNT(*)
                  INTO lv_fp_staging_r_cnt
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE 1 = 1
				   AND xads.fund_type IS NOT NULL
				   AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
				   AND xads.award_file_batch_name = c_award_file_batch_name;
           -- xads.award_file_batch_name = gc_current_process_batch_name;



		--+===========================================================================================================+
		--  Purpose -- Update the staging table column process_flag to 'N' from process_flag = 'E'.
					-- UPDATE - TO REPROCESS THE REJECTED RECORDS.
		--+============================================================================================================+

       UPDATE  xx_ap_c2fo_award_data_staging xads
          SET 
            --xads.processing_batch_name = gc_current_process_batch_name,
            xads.award_file_batch_name = c_award_file_batch_name,
						xads.process_flag = 'N',
						xads.process_stage = 'UPDATE_RD_AND_PG',
						xads.processed_date = NULL,
						xads.error_msg = NULL,
						xads.last_update_date = SYSDATE,
						xads.last_updated_by = l_user_id
                  WHERE 1 = 1
                    AND xads.process_stage NOT IN  ('DUPLICATE')
					--AND xads.process_stage IN  ('VALIDATION_ERROR','FUND_TYPE_RS_ERROR','FP_INVOICE_RD_PG_UPDATE_ERROR','FP_INVOICE_PS_RD_UPDATE_ERROR')
					AND xads.fund_type IS NOT NULL
					AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
					AND xads.process_flag = 'E';

         COMMIT;

       fnd_file.put_line(fnd_file.log,'Step-9');
 
                SELECT COUNT(*)
                  INTO lv_fp_award_file_r_cnt
                  FROM xx_ap_c2fo_award_data_external;

                fnd_file.put_line(fnd_file.log,'FP Award File Record count FROM xxc2fo_fp_award_data_external is -  '|| lv_fp_award_file_r_cnt|| '.');

  
                SELECT COUNT(*)
                  INTO lv_fp_current_processing_r_cnt
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE 1 = 1 
				   AND xads.fund_type IS NOT NULL
				   AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
           AND xads.award_file_batch_name = c_award_file_batch_name;
           
--				   AND xads.processing_batch_name = gc_current_process_batch_name;

        lv_fp_previous_rejected_r_cnt := ( lv_fp_current_processing_r_cnt - lv_fp_staging_r_cnt );

        fnd_file.put_line(fnd_file.LOG,' Inserted record count from FP award file: '||lv_fp_staging_r_cnt|| ' for this batch: '|| c_award_file_batch_name);
				fnd_file.put_line(fnd_file.LOG,' FP Processing previous rejected record count: '||lv_fp_previous_rejected_r_cnt|| ' for this batch: '|| c_award_file_batch_name);
				fnd_file.put_line(fnd_file.log,' FP Current processing record count: '||lv_fp_current_processing_r_cnt|| ' for this batch: '|| c_award_file_batch_name);

       fnd_file.put_line(fnd_file.log,'Step-10');
 

 -------------------Phase-2-----End -------------------------               


        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,' Stage 02 - Validate the records in the table "xx_ap_c2fo_award_data_staging" for the batch  :'||c_award_file_batch_name||' - Starts');

        -- +======================================================================================================+
        -- | Validations - starts here.
        -- +======================================================================================================+
        BEGIN

       fnd_file.put_line(fnd_file.log,'Step-11');
 
        FOR c1_batch_all_rec IN c1_batch_all
        LOOP


          FND_FILE.PUT_LINE(FND_FILE.log,'Step-11.01 c1_batch_all');
          FND_FILE.PUT_LINE(FND_FILE.log,'*******Processing Invoice : ' ||  c1_batch_all_rec.invoice_id);

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
			   AND aia.invoice_id = c1_batch_all_rec.ebs_invoice_id
               AND aia.org_id+0 = c1_batch_all_rec.ebs_org_id
			   AND aia.vendor_id+0 = c1_batch_all_rec.ebs_vendor_id
               AND aia.vendor_site_id+0 = c1_batch_all_rec.ebs_vendor_site_id
			   AND assa.vendor_site_id = aia.vendor_site_id
			   AND assa.org_id = aia.org_id
			   AND assa.vendor_id+0 = aia.vendor_id
               AND sup.vendor_id = assa.vendor_id;

            EXCEPTION
                 WHEN OTHERS THEN
                        l_process_status := 'E';
                        l_error_msg      := 'Holds applied for the the supplier'||c1_batch_all_rec.ebs_supplier_number||'-'||c1_batch_all_rec.ebs_vendor_site_code;
            END;

             IF l_sup_hold_flag = 'N' AND l_sup_hold_all_payments_flag = 'N' AND l_site_hold_all_payments_flag = 'N'  THEN
                    l_process_status := 'N';
             ELSE
                    l_process_status := 'E';
                    l_error_msg      := 'Holds applied for the the supplier'||c1_batch_all_rec.ebs_supplier_number||'-'||c1_batch_all_rec.ebs_vendor_site_code;
             END IF;

       fnd_file.put_line(fnd_file.log,'Step-12');
 
            IF l_process_status = 'E' THEN

                UPDATE xx_ap_c2fo_award_data_staging xads
                       SET xads.process_status = 'VALIDATION_ERROR',
                           xads.error_msg = c1_batch_all_rec.error_msg||'-'||l_error_msg,
                           xads.process_flag = l_process_status,
						   xads.last_update_date = sysdate,
						   xads.last_updated_by = l_user_id
                     WHERE 1 = 1
                       AND xads.company_id = c1_batch_all_rec.company_id
                       AND xads.invoice_id = c1_batch_all_rec.invoice_id
                       AND xads.award_file_batch_name=c_award_file_batch_name;
            ELSE
                l_process_status := 'N';

                UPDATE xx_ap_c2fo_award_data_staging xads
                   SET xads.process_flag = l_process_status,
					   xads.last_update_date = sysdate,
					   xads.last_updated_by = l_user_id
                 WHERE 1 = 1
                   AND xads.company_id = c1_batch_all_rec.company_id
                   AND xads.invoice_id = c1_batch_all_rec.invoice_id
                   AND xads.award_file_batch_name=c_award_file_batch_name
                   AND NVL(xads.process_flag, 'N') != 'E';

            END IF;

       fnd_file.put_line(fnd_file.log,'Step-13');
 

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
             AND aha.invoice_id= c1_batch_all_rec.ebs_invoice_id;

             EXCEPTION
                    WHEN OTHERS THEN
                        l_process_status := 'E';
                        l_error_msg      := 'Hold applied for the invoice:'||c1_batch_all_rec.ebs_invoice_num;
             END;

             IF l_hold_invoice_id !=0 THEN
                    l_process_status := 'E';
                    l_error_msg      := 'Hold applied for the invoice:'||c1_batch_all_rec.ebs_invoice_num;
             ELSE
                    l_process_status := 'N';
             END IF;

       fnd_file.put_line(fnd_file.log,'Step-14');
 
            IF l_process_status = 'E' THEN

               UPDATE xx_ap_c2fo_award_data_staging xads
                  SET xads.process_status = 'VALIDATION_ERROR',
                      xads.error_msg = c1_batch_all_rec.error_msg||'-'||l_error_msg,
                      xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id
                WHERE 1 = 1
                  AND xads.company_id = c1_batch_all_rec.company_id
                  AND xads.invoice_id = c1_batch_all_rec.invoice_id
                  AND xads.award_file_batch_name=c_award_file_batch_name;
            ELSE
                l_process_status := 'N';

                UPDATE xx_ap_c2fo_award_data_staging xads
                   SET xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id
                 WHERE 1 = 1
                   AND xads.company_id = c1_batch_all_rec.company_id
                   AND xads.invoice_id = c1_batch_all_rec.invoice_id
                   AND xads.award_file_batch_name=c_award_file_batch_name
                   AND NVL(xads.process_flag, 'N') != 'E';

            END IF;

       fnd_file.put_line(fnd_file.log,'Step-15');
 
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
               AND aia.vendor_id+0 = c1_batch_all_rec.ebs_vendor_id
               AND aia.vendor_site_id+0 = c1_batch_all_rec.ebs_vendor_site_id
               AND aia.org_id+0 = c1_batch_all_rec.ebs_org_id
               AND aia.invoice_num||'' = c1_batch_all_rec.ebs_invoice_num
               AND aia.invoice_id = c1_batch_all_rec.ebs_invoice_id;

            EXCEPTION
                 WHEN OTHERS THEN
                        l_process_status := 'E';
                        l_error_msg      := 'invoice_num Error, Invoice num:'||'-'||c1_batch_all_rec.ebs_invoice_num||'-'|| 'is not exists in application.';
            END;

       fnd_file.put_line(fnd_file.log,'Step-16');
 

            IF l_invoice_num = c1_batch_all_rec.ebs_invoice_num  THEN
               l_process_status := 'N';
            ELSE
               l_process_status := 'E';
               l_error_msg      := 'invoice_num Error, Invoice num:'||'-'||c1_batch_all_rec.ebs_invoice_num||'-'|| 'is not exists in application.';
            END IF;

            IF l_process_status = 'E' THEN

               UPDATE xx_ap_c2fo_award_data_staging xads
                  SET xads.process_status = 'VALIDATION_ERROR',
                      xads.error_msg = c1_batch_all_rec.error_msg||'-'||l_error_msg,
                      xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id
                WHERE 1 = 1
                  AND xads.company_id = c1_batch_all_rec.company_id
                  AND xads.invoice_id = c1_batch_all_rec.invoice_id
                  AND xads.award_file_batch_name=c_award_file_batch_name;
            ELSE
                l_process_status := 'N';

                UPDATE xx_ap_c2fo_award_data_staging xads
                   SET xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id
                 WHERE 1 = 1
                   AND xads.company_id = c1_batch_all_rec.company_id
                   AND xads.invoice_id = c1_batch_all_rec.invoice_id
                   AND xads.award_file_batch_name=c_award_file_batch_name
                   AND NVL(xads.process_flag, 'N') != 'E';

            END IF;
            
       fnd_file.put_line(fnd_file.log,'Step-17');
             

        -- +======================================================================================================+
        -- | Validation#03 - Ends - Checking the iNVOICE NUMBER EXISTS OR NOT.
        -- +======================================================================================================+

        -- +======================================================================================================+
        -- | Validation#04 - STARTS - Checking the AWARD NUMBER(NEW INVOICE NUMBER/ CREDIT MEMO) EXISTS OR NOT.
        -- +======================================================================================================+

            BEGIN

            l_error_msg      := NULL;
            l_process_status := NULL;

            IF NVL(c1_batch_all_rec.income,0) != 0 AND c1_batch_all_rec.award_record_activities='CREATE_CM_AND_UPDATE_DUE_DATE' THEN

			-- Modified for performance
            BEGIN
                SELECT COUNT(aia.invoice_id)
                  INTO l_award_num_cnt
                  FROM ap_invoices_all aia
                 WHERE 1 = 1
                   AND aia.vendor_id+0 = c1_batch_all_rec.ebs_vendor_id
                   AND aia.vendor_site_id+0 = c1_batch_all_rec.ebs_vendor_site_id
                   AND aia.org_id+0 = c1_batch_all_rec.ebs_org_id
                   AND aia.invoice_num = c1_batch_all_rec.award_num;

            EXCEPTION
                 WHEN OTHERS THEN
                      l_process_status := 'E';
                      l_error_msg      := 'award_num Error, award_num/invoice_num(credit memoS):'||'-'||c1_batch_all_rec.award_num||'-'|| 'is already exists.';
            END;

       fnd_file.put_line(fnd_file.log,'Step-18');


            IF l_award_num_cnt = 0  THEN
               l_process_status := 'N';
            ELSE
               l_process_status := 'E';
               l_error_msg      := 'award_num Error, award_num/invoice_num(credit memo):'||'-'||c1_batch_all_rec.award_num||'-'|| 'is already exists.';
            END IF;

            IF l_process_status = 'E' THEN

                UPDATE xx_ap_c2fo_award_data_staging xads
                   SET process_status = 'VALIDATION_ERROR',
                       error_msg = c1_batch_all_rec.error_msg||'-'||l_error_msg,
                       process_flag = l_process_status,
					   xads.last_update_date = sysdate,
					   xads.last_updated_by = l_user_id
                 WHERE 1 = 1
                   AND xads.company_id = c1_batch_all_rec.company_id
                   AND xads.invoice_id = c1_batch_all_rec.invoice_id
                   AND xads.award_file_batch_name=c_award_file_batch_name;
            ELSE
                l_process_status := 'N';

                UPDATE xx_ap_c2fo_award_data_staging xads
                   SET process_flag = l_process_status,
					   xads.last_update_date = sysdate,
					   xads.last_updated_by = l_user_id
                 WHERE 1 = 1
                   AND xads.company_id = c1_batch_all_rec.company_id
                   AND xads.invoice_id = c1_batch_all_rec.invoice_id
                   AND xads.award_file_batch_name=c_award_file_batch_name
                   AND NVL(xads.process_flag, 'N') != 'E';

            END IF;
            END IF;
            END;

       fnd_file.put_line(fnd_file.log,'Step-19');

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
               AND gcc.code_combination_id = c1_batch_all_rec.liability_ccid;

            EXCEPTION
                 WHEN OTHERS THEN
                      l_process_status := 'E';
                      l_error_msg      := 'Liability Account Error, for award_num:'||'-'||c1_batch_all_rec.award_num;
            END;

            IF l_liability_ccid_cnt != 0  THEN
               l_process_status := 'N';
            ELSE
               l_process_status := 'E';
               l_error_msg      := 'Liability Account Error, for award_num:'||'-'||c1_batch_all_rec.award_num;
            END IF;

            IF l_process_status = 'E' THEN

               UPDATE xx_ap_c2fo_award_data_staging xads
                  SET xads.process_status = 'VALIDATION_ERROR',
                      xads.error_msg = c1_batch_all_rec.error_msg||'-'||l_error_msg,
                      xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id
                WHERE 1 = 1
                  AND xads.company_id = c1_batch_all_rec.company_id
                  AND xads.invoice_id = c1_batch_all_rec.invoice_id
                  AND xads.award_file_batch_name=c_award_file_batch_name;
            ELSE
               l_process_status := 'N';

               UPDATE xx_ap_c2fo_award_data_staging xads
                  SET xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id
                WHERE 1 = 1
                  AND xads.company_id = c1_batch_all_rec.company_id
                  AND xads.invoice_id = c1_batch_all_rec.invoice_id
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
               AND gcc.code_combination_id = c1_batch_all_rec.expense_ccid;

            EXCEPTION
                 WHEN OTHERS THEN
                      l_process_status := 'E';
                      l_error_msg      := 'Distribution Account Error, for award_num:'||'-'||c1_batch_all_rec.award_num;
            END;

            IF l_liability_ccid_cnt != 0  THEN
               l_process_status := 'N';
            ELSE
               l_process_status := 'E';
               l_error_msg      := 'Distribution Account Error, for award_num:'||'-'||c1_batch_all_rec.award_num;
            END IF;

       fnd_file.put_line(fnd_file.log,'Step-20');


            IF l_process_status = 'E' THEN

               UPDATE xx_ap_c2fo_award_data_staging xads
                  SET xads.process_status = 'VALIDATION_ERROR',
                      xads.error_msg = c1_batch_all_rec.error_msg||'-'||l_error_msg,
                      xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id
                WHERE 1 = 1
                  AND xads.company_id = c1_batch_all_rec.company_id
                  AND xads.invoice_id = c1_batch_all_rec.invoice_id
                  AND xads.award_file_batch_name=c_award_file_batch_name;
            ELSE
               l_process_status := 'N';

               UPDATE xx_ap_c2fo_award_data_staging xads
                  SET xads.process_flag = l_process_status,
					  xads.last_update_date = sysdate,
					  xads.last_updated_by = l_user_id
                WHERE 1 = 1
                  AND xads.company_id = c1_batch_all_rec.company_id
                  AND xads.invoice_id = c1_batch_all_rec.invoice_id
                  AND xads.award_file_batch_name=c_award_file_batch_name
                  AND NVL(xads.process_flag, 'N') != 'E';

            END IF;

       fnd_file.put_line(fnd_file.log,'Step-21');

        -- +======================================================================================================+
        -- | Validation#06 - ENDS - Validating the dist_code_combination_id.
        -- +======================================================================================================+

-------------------Phase-2 ------------ Validation ---------------------------------
        IF  c1_batch_all_rec.award_record_activities='UPDATE_RD_AND_PG_TYPE' THEN

                BEGIN
                    lv_err_msg 		:= NULL;
                    lv_process_flag	:= NULL;

          SELECT (apps.xx_ap_c2fo_int_ebs_ap_pay_pkg.amt_or_amt_netvat_after_disc(aia.org_id,aia.invoice_id) )
					   INTO lv_fp_ebs_inv_amt_after_disc
					   FROM ap_invoices_all aia
					  WHERE 1 = 1
						AND aia.vendor_id = c1_batch_all_rec.ebs_vendor_id
                        AND aia.vendor_site_id = c1_batch_all_rec.ebs_vendor_site_id
                        AND aia.org_id = c1_batch_all_rec.ebs_org_id
                        AND aia.invoice_num = c1_batch_all_rec.ebs_invoice_num
                        AND aia.invoice_id = c1_batch_all_rec.ebs_invoice_id;

                EXCEPTION
                    WHEN OTHERS THEN

                        lv_process_flag := 'E';
                        lv_err_msg := lv_err_msg||'-'||'invoice original_amount exception Error, at Invoice num:'||'-'||c1_batch_all_rec.ebs_invoice_num||'-'|| '.';

                END;

       fnd_file.put_line(fnd_file.log,'Step-22');


                IF lv_fp_ebs_inv_amt_after_disc = c1_batch_all_rec.original_amount THEN

                    lv_process_flag := 'N';

                ELSE

                    lv_process_flag	:= 'E';
                    lv_err_msg 		:= lv_err_msg||'-'||'invoice original_amount Error, Invoice num:'||'-'|| c1_batch_all_rec.ebs_invoice_num||'-'|| ', amount is not matching with the award file invoice amount.';

                END IF;


          IF lv_process_flag = 'E' THEN

           UPDATE xx_ap_c2fo_award_data_staging xads
						SET xads.process_stage = 'VALIDATION_ERROR',
						    xads.process_flag = lv_process_flag,
							xads.error_msg = lv_err_msg,							
							xads.last_update_date = SYSDATE,
							xads.last_updated_by = l_user_id
                      WHERE 1 = 1
					    AND xads.fund_type IS NOT NULL
				        AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
                        AND xads.company_id = c1_batch_all_rec.company_id
                        and XADS.INVOICE_ID = c1_batch_all_rec.INVOICE_ID
                        and XADS.AWARD_FILE_BATCH_NAME=C_AWARD_FILE_BATCH_NAME;
               --         AND xads.processing_batch_name = gc_current_process_batch_name;

                ELSE

                    lv_process_flag := 'N';

           UPDATE xx_ap_c2fo_award_data_staging xads
						SET xads.process_stage = 'SUCCESSFULLY_VALIDATED',
							xads.process_flag = lv_process_flag,
							xads.last_update_date = SYSDATE,
							xads.last_updated_by = l_user_id
                      WHERE 1 = 1
					    AND xads.fund_type IS NOT NULL
				        AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
                        AND xads.company_id = c1_batch_all_rec.company_id
                        and XADS.INVOICE_ID = c1_batch_all_rec.INVOICE_ID
                        AND xads.award_file_batch_name=c_award_file_batch_name
             --         AND xads.processing_batch_name = gc_current_process_batch_name
                        AND nvl(xads.process_flag,'N') != 'E';

                END IF;



    END IF;

---------------x Remit to Fields check

                lv_err_msg 		:= NULL;
                lv_process_flag	:= NULL;


             FND_FILE.PUT_LINE(FND_FILE.log,'Step-22.5');

      IF  C1_BATCH_ALL_REC.AWARD_RECORD_ACTIVITIES='UPDATE_RD_AND_PG_TYPE' 
          AND C1_BATCH_ALL_REC.FUND_TYPE IS NOT NULL then

            FND_FILE.PUT_LINE(FND_FILE.log,'Step-22.6');
            
                lv_process_flag := 'N';

             FND_FILE.PUT_LINE(FND_FILE.log,'Fund Type : ');                              
             FND_FILE.PUT_LINE(FND_FILE.log,'Value : ' || C1_BATCH_ALL_REC.Fund_type);         

             FND_FILE.PUT_LINE(FND_FILE.log,'C1_BATCH_ALL_REC.EBS_REMIT_TO_SUPPLIER_NAME');                              
             FND_FILE.PUT_LINE(FND_FILE.log,'Value : ' || c1_batch_all_rec.EBS_REMIT_TO_SUPPLIER_NAME);         
                      
             FND_FILE.PUT_LINE(FND_FILE.log,'C1_BATCH_ALL_REC.EBS_REMIT_TO_SUPPLIER_SITE	');                              
             FND_FILE.PUT_LINE(FND_FILE.log,'Value : ' || C1_BATCH_ALL_REC.EBS_REMIT_TO_SUPPLIER_SITE)	;         


--              if  c1_batch_all_rec.EBS_REMIT_TO_SUPPLIER_NAME	is NULL then
--                    LV_PROCESS_FLAG	:= 'E';
--                    LV_ERR_MSG 		:= LV_ERR_MSG||'-'||'Ebs_Remit_to_supplier_Name is Null, Invoice num:'||'-'|| C1_BATCH_ALL_REC.EBS_INVOICE_NUM;
              if  C1_BATCH_ALL_REC.EBS_REMIT_TO_SUPPLIER_SITE	is NULL then
                    LV_PROCESS_FLAG	:= 'E';
                    LV_ERR_MSG 		:= LV_ERR_MSG||'-'||'Ebs_Remit_to_supplier_Site is Null, Invoice num:'||'-'|| C1_BATCH_ALL_REC.EBS_INVOICE_NUM; 
              elsif  C1_BATCH_ALL_REC.EBS_REMIT_TO_VENDOR_ID	is NULL then
                    LV_PROCESS_FLAG	:= 'E';
                    LV_ERR_MSG 		:= LV_ERR_MSG||'-'||'Ebs_Remit_to_Vendor_Id is Null, Invoice num:'||'-'|| C1_BATCH_ALL_REC.EBS_INVOICE_NUM;
              elsif  C1_BATCH_ALL_REC.EBS_REMIT_TO_VENDOR_SITE_ID	is NULL then
                    LV_PROCESS_FLAG	:= 'E';
                    LV_ERR_MSG 		:= LV_ERR_MSG||'-'||'Ebs_Remit_to_Vendor_Site_Id is Null, Invoice num:'||'-'|| C1_BATCH_ALL_REC.EBS_INVOICE_NUM;
              elsif  C1_BATCH_ALL_REC.EBS_REMIT_TO_PARTY_ID	is NULL then
                    LV_PROCESS_FLAG	:= 'E';
                    LV_ERR_MSG 		:= LV_ERR_MSG||'-'||'Ebs_Remit_to_Party_Id is Null, Invoice num:' ||'-' || C1_BATCH_ALL_REC.EBS_INVOICE_NUM;
              ELSIF  C1_batch_all_rEC.EBS_REMIT_TO_PARTY_SITE_ID is null then
                    LV_PROCESS_FLAG	:= 'E';
                    lv_err_msg 		:= lv_err_msg||'-'||'Ebs_Remit_to_Party_Site_Id is Null, Invoice num:'||'-'|| c1_batch_all_rec.ebs_invoice_num; 
              elsif  c1_batch_all_rec.ebs_ext_bank_account_id is null then
                    lv_process_flag	:= 'E';
                    lv_err_msg 		:= lv_err_msg||'-'||'FUNDING SOURCE Ebs_Ext_Bank_Account_Id is Null, Invoice num:'||'-'|| c1_batch_all_rec.ebs_invoice_num; 
              elsif  c1_batch_all_rec.payment_method_code = 'CHECK' then
                    lv_process_flag	:= 'E';
                    lv_err_msg 		:= lv_err_msg||'-'||'FP AWARD cannot have Payment Method of CHECK, Invoice num:'||'-'|| c1_batch_all_rec.ebs_invoice_num; 
              end if;
     
                     
          IF lv_process_flag = 'E' THEN

           UPDATE xx_ap_c2fo_award_data_staging xads
						SET xads.process_stage = 'VALIDATION_ERROR',
						    xads.process_flag = lv_process_flag,
							xads.error_msg = lv_err_msg,							
							xads.last_update_date = SYSDATE,
							xads.last_updated_by = l_user_id
                      WHERE 1 = 1
					    AND xads.fund_type IS NOT NULL
				        AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
                        AND xads.company_id = c1_batch_all_rec.company_id
                        and XADS.INVOICE_ID = c1_batch_all_rec.INVOICE_ID
                        and XADS.AWARD_FILE_BATCH_NAME=C_AWARD_FILE_BATCH_NAME;
               --         AND xads.processing_batch_name = gc_current_process_batch_name;

           ELSE

              lv_process_flag := 'N';

           UPDATE xx_ap_c2fo_award_data_staging xads
						SET xads.process_stage = 'SUCCESSFULLY_VALIDATED',
							xads.process_flag = lv_process_flag,
							xads.last_update_date = SYSDATE,
							xads.last_updated_by = l_user_id
                      WHERE 1 = 1
					    AND xads.fund_type IS NOT NULL
				        AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
                        AND xads.company_id = c1_batch_all_rec.company_id
                        and XADS.INVOICE_ID = c1_batch_all_rec.INVOICE_ID
                        AND xads.award_file_batch_name=c_award_file_batch_name
             --         AND xads.processing_batch_name = gc_current_process_batch_name
                        AND nvl(xads.process_flag,'N') != 'E';

          END IF;

        END IF;

--------------x

-------------------Phase-2 ------------ End ---------------------------------


        END LOOP;  --c1_batch_all
        END;
        COMMIT;

    FND_FILE.PUT_LINE(FND_FILE.log,'****************************************************************************** ');
    FND_FILE.PUT_LINE(FND_FILE.log,'********** Start of EARLY PAYMENT - CREDIT MEMO PROCESSING ******************* ');
    FND_FILE.PUT_LINE(FND_FILE.log,'****************************************************************************** ');


       fnd_file.put_line(fnd_file.log,'Step-23');

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

       fnd_file.put_line(fnd_file.log,'Step-24');


---------------##########@@@@@@@@@@@@@@@-------------------

        IF l_inv_int_cnt != 0 THEN

        FOR c2_early_pay_cmdd_rec IN c2_early_pay_cmdd LOOP


         FND_FILE.PUT_LINE(FND_FILE.log,'Step-24.01 c2_early_pay_cmdd');
          FND_FILE.PUT_LINE(FND_FILE.log,'*******Processing Invoice : ' ||  c2_early_pay_cmdd_rec.INVOICE_ID);


            BEGIN
             SELECT ap_invoices_interface_s.NEXTVAL
               INTO l_seq_id
               FROM dual;

          --Create Memo Header
          
       fnd_file.put_line(fnd_file.log,'Step-25');


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
                    c2_early_pay_cmdd_rec.award_num,  --Can be configured by client
                    trunc(SYSDATE),
                    'CREDIT',
                    c2_early_pay_cmdd_rec.cm_inv_amt,
                    c2_early_pay_cmdd_rec.invoice_currency_code,
                    c2_early_pay_cmdd_rec.payment_currency_code,
                    c2_early_pay_cmdd_rec.award_description,
                    SYSDATE,
                    l_user_id,
                    SYSDATE,
                    l_user_id,
                    'US_OD_C2FO',
                    c2_early_pay_cmdd_rec.vendor_site_id,
                   -- c2_early_pay_cmdd_rec.pay_date,
					c2_early_pay_cmdd_rec.goods_received_date,
                    c2_early_pay_cmdd_rec.org_id,
                    c2_early_pay_cmdd_rec.vendor_id,
                    c2_early_pay_cmdd_rec.award_num_terms_id,
                    c2_early_pay_cmdd_rec.payment_method_code,
                    c2_early_pay_cmdd_rec.PAY_GROUP_LOOKUP_CODE,
                    c2_early_pay_cmdd_rec.accts_pay_code_combination_id,
                    c_award_file_batch_name,
					'US_OD_C2FO'    -- attribute7
                    );

          --Create Memo Line

       fnd_file.put_line(fnd_file.log,'Step-26');


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
                    c2_early_pay_cmdd_rec.cm_inv_line_amt,
                    c2_early_pay_cmdd_rec.award_description,
                    SYSDATE,
                    l_user_id,
                    SYSDATE,
                    l_user_id,
                    c2_early_pay_cmdd_rec.expense_ccid,
                    --NULL,
                    c2_early_pay_cmdd_rec.org_id
                    );

             UPDATE xx_ap_c2fo_award_data_staging xads
                SET xads.process_status = 'INTERFACED',
                    xads.processed_date = SYSDATE,
					xads.last_update_date = sysdate,
					xads.last_updated_by = l_user_id
              WHERE ROWID = c2_early_pay_cmdd_rec.c2fo_c1_rowid;
--                AND xads.award_file_batch_name = c_award_file_batch_name
--                AND xads.award_num = c2_early_pay_cmdd_rec.award_num
--                AND xads.ebs_org_id = c2_early_pay_cmdd_rec.org_id
--                AND xads.ebs_vendor_id = c2_early_pay_cmdd_rec.vendor_id
--                AND xads.ebs_vendor_site_id = c2_early_pay_cmdd_rec.vendor_site_id
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
                     WHERE ROWID = c2_early_pay_cmdd_rec.c2fo_c1_rowid;
--                        AND xads.award_file_batch_name = c_award_file_batch_name
--                        AND xads.award_num = c2_early_pay_cmdd_rec.award_num
--                        AND xads.ebs_org_id = c2_early_pay_cmdd_rec.org_id
--                        AND xads.ebs_vendor_id = c2_early_pay_cmdd_rec.vendor_id
--                        AND xads.ebs_vendor_site_id = c2_early_pay_cmdd_rec.vendor_site_id
--                        AND NVL(xads.process_flag, 'N') != 'E'
--                        AND xads.process_status = 'STAGED_FOR_INTERFACE_REC';

            END;
        END LOOP;

       fnd_file.put_line(fnd_file.log,'Step-27');


        fnd_file.put_line(fnd_file.log,' Stage 03 - insert the records into tables ap_invoices_interface and  ap_invoice_lines_interface - Ends ');


        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,' Stage 04 - Submiting the Program - Payables Open Interface Import - Starts ');

		--- Go-Live time, we trigger the program only for OD_US org.

		----Changes For NAIT 63055 Starts Here ---

-- Set printer options
lc_boolean := fnd_submit.set_print_options (printer => 'XPTR'
											,style => 'TEXT'
											,copies => 1 );

IF lc_boolean THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'l_boolean');
END IF;
--Add printer
lc_boolean1 := fnd_request.add_printer (printer => 'XPTR'
										,copies => 1);
IF lc_boolean1 THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_boolean1');
END IF;
---v_layout := FND_REQUEST.ADD_LAYOUT('SQLAP' ,'APXIIMPT' ,'en' ,'US' ,'TEXT');

       fnd_file.put_line(fnd_file.log,'Step-28');

		---Changes For NAIT 63055 Ends Here ----

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

       fnd_file.put_line(fnd_file.log,'Step-29');

        -------------

        IF lv_request_id = 0 THEN
           fnd_file.put_line(fnd_file.log,'Request Not Submitted due to "' || fnd_message.get || '".');
        ELSE
           fnd_file.put_line(fnd_file.log,'The Program "APXIIMPT - Payables Open Interface Import" submitted successfully ?Request id :' || lv_request_id);
        END IF;

        IF lv_request_id > 0 THEN

            LOOP
            
                   fnd_file.put_line(fnd_file.log,'Step-30');

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

       fnd_file.put_line(fnd_file.log,'Step-31');

        fnd_file.put_line(fnd_file.log,' Stage 04 - Submiting the Program - Payables Open Interface Import - Ends ');

        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,' Stage 05 - Updating the staging table based on the Program - Payables Open Interface Import Results - Starts ');

        FOR c3_credit_memo_intf_rec IN c3_credit_memo_intf LOOP

          FND_FILE.PUT_LINE(FND_FILE.log,'Step-31.01  c3_credit_memo_intf');
          FND_FILE.PUT_LINE(FND_FILE.log,'*******Processing CM Invoice : ' ||  C3_CREDIT_MEMO_INTF_REC.INVOICE_NUM);


            BEGIN

            IF c3_credit_memo_intf_rec.status = 'PROCESSED' THEN

       fnd_file.put_line(fnd_file.log,'Step-32');


                BEGIN
                    UPDATE xx_ap_c2fo_award_data_staging xads
                       SET xads.process_status = 'CM_CREATED',
                           xads.processed_date = SYSDATE,
                           xads.ebs_cm_invoice_id = (SELECT aia.invoice_id
                                                       FROM ap_invoices_all aia
                                                      WHERE aia.org_id=c3_credit_memo_intf_rec.ebs_org_id
                                                        AND aia.vendor_id=c3_credit_memo_intf_rec.ebs_vendor_id
                                                        AND aia.vendor_site_id= c3_credit_memo_intf_rec.ebs_vendor_site_id
                                                        AND aia.invoice_num=c3_credit_memo_intf_rec.invoice_num),
                           xads.invoice_import_request_id=c3_credit_memo_intf_rec.request_id,
						   xads.last_update_date = sysdate,
						   xads.last_updated_by = l_user_id
                    WHERE ROWID = c3_credit_memo_intf_rec.c2fo_c2_rowid;
--                        AND award_file_batch_name = c_award_file_batch_name
--                        AND award_num = c3_credit_memo_intf_rec.invoice_num
--                        AND ebs_org_id = c3_credit_memo_intf_rec.ebs_org_id
--                        AND ebs_vendor_id = c3_credit_memo_intf_rec.ebs_vendor_id
--                        AND ebs_vendor_site_id = c3_credit_memo_intf_rec.ebs_vendor_site_id
--                        --AND c3_credit_memo_intf_rec.status = 'PROCESSED'
--                        AND NVL(xads.process_flag, 'N') != 'E'
--                        AND xads.process_status = 'INTERFACED';

                EXCEPTION
                     WHEN OTHERS THEN
                        v_process_msg := 'Errors due to Payables Open Interface Import.'||'-'||sqlerrm;
                        UPDATE xx_ap_c2fo_award_data_staging xads
                           SET xads.process_status = 'ERROR',
                               xads.process_flag = 'E',
                               xads.error_msg = v_process_msg,
                               xads.invoice_import_request_id=c3_credit_memo_intf_rec.request_id,
							   xads.last_update_date = sysdate,
							   xads.last_updated_by = l_user_id
                         WHERE ROWID = c3_credit_memo_intf_rec.c2fo_c2_rowid;
--                        AND xads.award_file_batch_name = c_award_file_batch_name
--                        AND xads.award_num = c3_credit_memo_intf_rec.invoice_num
--                        AND xads.ebs_org_id = c3_credit_memo_intf_rec.ebs_org_id
--                        AND xads.ebs_vendor_id = c3_credit_memo_intf_rec.ebs_vendor_id
--                        AND xads.ebs_vendor_site_id = c3_credit_memo_intf_rec.ebs_vendor_site_id
--                        --AND c3_credit_memo_intf_rec.status = 'PROCESSED'
--                        AND NVL(xads.process_flag, 'N') != 'E'
--                        AND xads.process_status = 'INTERFACED';

                END;

            ELSE

       fnd_file.put_line(fnd_file.log,'Step-33');

                BEGIN

                    UPDATE xx_ap_c2fo_award_data_staging xads
                       SET xads.process_status = 'INTERFACE_ERRORED',
                           xads.process_flag = 'E',
                           xads.processed_date = SYSDATE,
                           xads.invoice_import_request_id=c3_credit_memo_intf_rec.request_id,
                           xads.error_msg = 'Errors due to Payables Open Interface Import.',
						   xads.last_update_date = sysdate,
					       xads.last_updated_by = l_user_id
                     WHERE ROWID = c3_credit_memo_intf_rec.c2fo_c2_rowid;
--                        AND award_file_batch_name = c_award_file_batch_name
--                        AND award_num = c3_credit_memo_intf_rec.invoice_num
--                        AND ebs_org_id = c3_credit_memo_intf_rec.ebs_org_id
--                        AND ebs_vendor_id = c3_credit_memo_intf_rec.ebs_vendor_id
--                        AND ebs_vendor_site_id = c3_credit_memo_intf_rec.ebs_vendor_site_id
--                        --AND c3_credit_memo_intf_rec.status != 'PROCESSED'
--                        AND NVL(xads.process_flag, 'N') != 'E'
--                        AND xads.process_status = 'INTERFACED';

                EXCEPTION
                     WHEN OTHERS THEN
                          v_process_msg := 'Errors due to Payables Open Interface Import.'||'-'||sqlerrm;

       fnd_file.put_line(fnd_file.log,'Step-34');


                          UPDATE xx_ap_c2fo_award_data_staging xads
                             SET xads.process_status = 'ERROR',
                                 xads.process_flag = 'E',
                                 xads.error_msg = v_process_msg,
                                 xads.invoice_import_request_id=c3_credit_memo_intf_rec.request_id,
								 xads.last_update_date = sysdate,
								 xads.last_updated_by = l_user_id
                           WHERE ROWID = c3_credit_memo_intf_rec.c2fo_c2_rowid;
--                            AND xads.award_file_batch_name = c_award_file_batch_name
--                            AND xads.award_num = c3_credit_memo_intf_rec.invoice_num
--                            AND xads.ebs_org_id = c3_credit_memo_intf_rec.ebs_org_id
--                            AND xads.ebs_vendor_id = c3_credit_memo_intf_rec.ebs_vendor_id
--                            AND xads.ebs_vendor_site_id = c3_credit_memo_intf_rec.ebs_vendor_site_id
--                            --AND c3_credit_memo_intf_rec.status != 'PROCESSED'
--                            AND NVL(xads.process_flag, 'N') != 'E'
--                            AND xads.process_status = 'INTERFACED';

                END;
            END IF;
            END;

       fnd_file.put_line(fnd_file.log,'Step-35');


        END LOOP;

        COMMIT;

        fnd_file.put_line(fnd_file.log,' Stage 05 - Updating the staging table based on the Program - Payables Open Interface Import Results - Ends ');

-----------*********************************************-----------------------

        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,' Stage 06.AA - Updating the due date for the created credit memos - Starts ');

        BEGIN
        
               fnd_file.put_line(fnd_file.log,'Step-36');


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

       fnd_file.put_line(fnd_file.log,'Step-37');

        FOR c4_cm_created_rec IN c4_cm_created LOOP

          FND_FILE.PUT_LINE(FND_FILE.log,'Step-37.01  c4_cm_created');
          FND_FILE.PUT_LINE(FND_FILE.log,'*******Processing CM Invoice : ' ||  c4_cm_created_rec.ebs_cm_invoice_id);

            BEGIN
				-- Modified for performance
                UPDATE ap_payment_schedules_all apsa
                   SET apsa.due_date = c4_cm_created_rec.pay_date,
                       apsa.discount_date = NVL2(apsa.discount_date,c4_cm_created_rec.pay_date,NULL),
                       apsa.second_discount_date  = NVL2(apsa.second_discount_date,c4_cm_created_rec.pay_date,NULL),
                       apsa.third_discount_date  = NVL2(apsa.third_discount_date,c4_cm_created_rec.pay_date,NULL),
					   apsa.last_update_date = sysdate,
					   apsa.last_updated_by = l_user_id,
					   apsa.last_update_login = fnd_global.login_id
                 WHERE 1 = 1
                   AND apsa.payment_status_flag||'' = 'N'
                   AND apsa.org_id+0 = c4_cm_created_rec.ebs_org_id
                   AND apsa.invoice_id = c4_cm_created_rec.ebs_cm_invoice_id;

            EXCEPTION
                WHEN OTHERS THEN
                     v_process_msg := 'Error while updating the credit memo pay date'||'-'||sqlerrm;
                     UPDATE xx_ap_c2fo_award_data_staging xads
                        SET xads.process_status = 'ERROR',
                            xads.process_flag = 'E',
                            xads.error_msg = v_process_msg,
							xads.last_update_date = sysdate,
							xads.last_updated_by = l_user_id
                      WHERE ROWID = c4_cm_created_rec.c2fo_c5_rowid;
--                        AND xads.award_file_batch_name = c_award_file_batch_name
--                        AND xads.award_num = c4_cm_created_rec.award_num
--                        AND xads.ebs_org_id = c4_cm_created_rec.ebs_org_id
--                        AND xads.ebs_vendor_id = c4_cm_created_rec.ebs_vendor_id
--                        AND xads.ebs_vendor_site_id = c4_cm_created_rec.ebs_vendor_site_id
--                        AND xads.ebs_invoice_id = c4_cm_created_rec.ebs_cm_invoice_id
--                        AND NVL(xads.process_flag, 'N') != 'E'
--                        AND xads.process_status IN ('CM_CREATED');

            END;
        END LOOP;

       fnd_file.put_line(fnd_file.log,'Step-38');

        COMMIT;

        ELSE

            fnd_file.put_line(fnd_file.log,'Stage 06.AA - There is no newly created credit memo records to update the due date.');

        END IF;

       fnd_file.put_line(fnd_file.log,'Step-39');

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
        
               fnd_file.put_line(fnd_file.log,'Step-40');


                SELECT COUNT(*)
                  INTO l_act_inv_dd_upd_rec_cnt
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   AND xads.process_status IN ('UPDATE_DUE_DATE_ONLY_REC','CM_CREATED')
                   AND xads.process_flag = 'N';

        END;

        IF l_act_inv_dd_upd_rec_cnt != 0 THEN

         FOR c5_upd_due_dt_rec IN c5_upd_due_dt LOOP

          FND_FILE.PUT_LINE(FND_FILE.log,'Step-40.01  c5_upd_due_dt');
          FND_FILE.PUT_LINE(FND_FILE.log,'*******Processing EBS Invoice : ' ||  c5_upd_due_dt_rec.EBS_INVOICE_ID);



       fnd_file.put_line(fnd_file.log,'Step-41');

            BEGIN
				-- Modified for performance
                UPDATE ap_payment_schedules_all apsa
                   SET apsa.due_date = c5_upd_due_dt_rec.pay_date,
                       apsa.discount_date = NVL2(apsa.discount_date,c5_upd_due_dt_rec.pay_date,NULL),
                       apsa.second_discount_date  = NVL2(apsa.second_discount_date,c5_upd_due_dt_rec.pay_date,NULL),
                       apsa.third_discount_date  = NVL2(apsa.third_discount_date,c5_upd_due_dt_rec.pay_date,NULL),
					   apsa.last_update_date = sysdate,
					   apsa.last_updated_by = l_user_id,
					   apsa.last_update_login = fnd_global.login_id
                 WHERE 1 = 1
                   AND apsa.payment_status_flag||'' = 'N'
                   AND apsa.org_id+0 = c5_upd_due_dt_rec.ebs_org_id
                   AND apsa.invoice_id = c5_upd_due_dt_rec.ebs_invoice_id;

            EXCEPTION
                WHEN OTHERS THEN
                     v_process_msg := 'Error while updating the pay date'||'-'||sqlerrm;
                     UPDATE xx_ap_c2fo_award_data_staging xads
                        SET xads.process_status = 'ERROR',
                            xads.process_flag = 'E',
                            xads.error_msg = v_process_msg,
							xads.last_update_date = sysdate,
							xads.last_updated_by = l_user_id
                      WHERE ROWID = c5_upd_due_dt_rec.c2fo_c3_rowid;
--                        AND xads.award_file_batch_name = c_award_file_batch_name
--                        AND xads.award_num = c5_upd_due_dt_rec.award_num
--                        AND xads.ebs_org_id = c5_upd_due_dt_rec.ebs_org_id
--                        AND xads.ebs_vendor_id = c5_upd_due_dt_rec.ebs_vendor_id
--                        AND xads.ebs_vendor_site_id = c5_upd_due_dt_rec.ebs_vendor_site_id
--                        AND xads.ebs_invoice_id = c5_upd_due_dt_rec.ebs_invoice_id
--                        AND NVL(xads.process_flag, 'N') != 'E'
--                        AND xads.process_status IN ('UPDATE_DUE_DATE_ONLY_REC','CM_CREATED');

            END;
        END LOOP;

        COMMIT;

       fnd_file.put_line(fnd_file.log,'Step-42');

        ELSE

            fnd_file.put_line(fnd_file.log,' Stage 06.BB - There is no valid existing Invoice records to update the due date.');

        END IF;

        fnd_file.put_line(fnd_file.log,' Stage 06.BB - Updating the due date for the existing invoice - Ends ');


-----------*********************************************-----------------------


        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,' Stage 07 - Updating the status for processed records - Starts ');

        BEGIN

       fnd_file.put_line(fnd_file.log,'Step-43');

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

       fnd_file.put_line(fnd_file.log,'Step-44');


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
                  where xads.award_file_batch_name = c_award_file_batch_name
                    and xads.fund_type is null;

                fnd_file.put_line(fnd_file.log,'Staging Table Record count FROM xx_ap_c2fo_award_data_staging is -  '|| l_stg_table_record_count|| '.');
            END;

       fnd_file.put_line(fnd_file.log,'Step-45');

            BEGIN
                SELECT COUNT(*)
                  INTO l_stg_success_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                  where xads.award_file_batch_name = c_award_file_batch_name
                  AND xads.process_flag = 'Y'
                  and xads.process_status = 'PROCESSED'
                  and xads.fund_type is null;

                fnd_file.put_line(fnd_file.log,'Successfully processed records is -  '|| l_stg_success_record_count|| '.');
            END;

            BEGIN
                SELECT COUNT(*)
                  INTO l_stg_error_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   AND xads.process_flag != 'Y'
                   and xads.process_status != 'PROCESSED'
                   and xads.fund_type is null;

                fnd_file.put_line(fnd_file.log,'Total Error Records is -  '|| l_stg_error_record_count|| '.');

            END;

       fnd_file.put_line(fnd_file.log,'Step-46');

            BEGIN
                SELECT COUNT(*)
                  INTO l_possible_cm_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   and xads.award_record_activities = 'CREATE_CM_AND_UPDATE_DUE_DATE'
                   and xads.fund_type is null;

                fnd_file.put_line(fnd_file.log,'Posible credit memo record count - '|| l_possible_cm_record_count|| '.');
            END;

            BEGIN
                SELECT COUNT(*)
                  INTO l_created_cm_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   AND xads.award_record_activities = 'CREATE_CM_AND_UPDATE_DUE_DATE'
                   AND xads.process_status = 'PROCESSED'
                   and xads.process_flag = 'Y'
                   and xads.fund_type is null;

                fnd_file.put_line(fnd_file.log,'Created credit memo record count - '|| l_created_cm_record_count|| '.');
            END;

       fnd_file.put_line(fnd_file.log,'Step-47');

            BEGIN
                SELECT COUNT(*)
                  INTO l_erreored_cm_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   AND xads.award_record_activities = 'CREATE_CM_AND_UPDATE_DUE_DATE'
                   AND xads.process_status != 'PROCESSED'
                   and xads.process_flag = 'E'
                   and xads.fund_type is null;

                fnd_file.put_line(fnd_file.log,'Errored credit memo record count - '|| l_erreored_cm_record_count|| '.');
            END;

            BEGIN
                SELECT COUNT(*)
                  INTO l_dd_update_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   AND xads.process_status = 'PROCESSED'
                   and xads.process_flag = 'Y'
                   and xads.fund_type is null;

                fnd_file.put_line(fnd_file.log,'Updated (Invoices and Credit memo) due date record count - '|| l_dd_update_record_count|| '.');
            END;
            
       fnd_file.put_line(fnd_file.log,'Step-48');

            BEGIN
                SELECT COUNT(*)
                  INTO l_duplicate_record_count
                  FROM xx_ap_c2fo_award_data_staging xads
                 WHERE xads.award_file_batch_name = c_award_file_batch_name
                   and xads.process_status = 'DUPLICATE'
                   and xads.fund_type is null;

                    fnd_file.put_line(fnd_file.log,'Duplicate Record count - '|| l_duplicate_record_count|| '.');
            END;

---------@@@@@@@@@@@@@*********************-------------------

-----------------------Phase-2----Begin------------------------------------------------
 -- Funding Partner Buyer Toggle Code Below 
 --------------------------------------------------------------------------------------

    FND_FILE.PUT_LINE(FND_FILE.log,'****************************************************************************** ');
    FND_FILE.PUT_LINE(FND_FILE.log,'********** Start of FUNDING PARTNER PROCESSING ******************************* ');
    FND_FILE.PUT_LINE(FND_FILE.log,'****************************************************************************** ');


		--+===========================================================================================================+
		--  STEP#02
		--  Purpose -- Update the funding  table. - STARTS.			
		--+============================================================================================================+

/*
			UPDATE XX_AP_C2FO_FP_FUNDING_SOURCE xcfst
			   SET (xcfst.fund_bank_account_num
					,xcfst.fund_currency_code
					,xcfst.fund_ext_bank_account_id
					,xcfst.fund_bank_name
					,xcfst.fund_bank_number
					,xcfst.fund_bank_id
					,xcfst.fund_branch_name
					,xcfst.fund_branch_number
					,xcfst.fund_branch_id
					,xcfst.fund_org_id
					,xcfst.fund_vendor_id
					,xcfst.fund_vendor_site_id
					,xcfst.fund_party_id
					,xcfst.fund_party_site_id
					,xcfst.fund_supplier_number
					,xcfst.fund_sup_enabled_flag
					,xcfst.fund_sup_end_date_active
					,xcfst.fund_sup_hold_flag
					,xcfst.fund_sup_hold_all_pay_flag
					,xcfst.fund_sup_site_pay_site_flag
					,xcfst.fund_sup_site_hold_all_pay_flg
					,xcfst.fund_sup_site_inactive_date
					,xcfst.fund_sup_site_bank_start_date
					,xcfst.fund_sup_site_bank_end_date
					,xcfst.last_updated_by
					,xcfst.last_update_date
					)
					=
					(
			  SELECT ieba.bank_account_num
					,ieba.currency_code
					,ieba.ext_bank_account_id
					,party_bank.party_name
					,branch_prof.bank_or_branch_number
					,ieba.bank_id fund_bank_id
					,party_branch.party_name
					,branch_prof.bank_or_branch_number
					,ieba.branch_id
					,assa.org_id
					,assa.vendor_id
					,assa.vendor_site_id
					,sup.party_id
					,assa.party_site_id
					,sup.segment1
					,sup.enabled_flag
					,sup.end_date_active
					,NVL(sup.hold_flag,'N')
					,sup.hold_all_payments_flag
					,assa.pay_site_flag
					,assa.hold_all_payments_flag
					,assa.inactive_date
					,ipiua.start_date
					,ipiua.end_date
					,l_user_id
					,SYSDATE
			   FROM  hz_parties party_supp
					,ap_suppliers sup
					,hz_party_sites site_supp
					,ap_supplier_sites_all assa
					,iby_external_payees_all iepa
					,iby_pmt_instr_uses_all ipiua
					,iby_ext_bank_accounts ieba
					,hz_parties party_bank
					,hz_parties party_branch
					,hz_organization_profiles bank_prof
					,hz_organization_profiles branch_prof
					,hr.hr_all_organization_units haou
              WHERE 1=1
				AND party_supp.party_id = sup.party_id
				AND party_supp.party_id = site_supp.party_id
				AND assa.org_id = haou.organization_id
				AND site_supp.party_site_id = assa.party_site_id
				AND assa.vendor_id = sup.vendor_id
				AND iepa.payee_party_id = party_supp.party_id
				AND iepa.party_site_id = site_supp.party_site_id
				AND iepa.supplier_site_id = assa.vendor_site_id
				AND iepa.ext_payee_id = ipiua.ext_pmt_party_id
				AND ipiua.instrument_id = ieba.ext_bank_account_id
				AND ieba.bank_id = party_bank.party_id
				AND ieba.bank_id = party_branch.party_id
				AND party_branch.party_id = branch_prof.party_id
				AND party_bank.party_id = bank_prof.party_id
				AND haou.name = xcfst.fund_operating_unit
				AND party_supp.party_name = xcfst.fund_supplier_name
				AND assa.vendor_site_code = xcfst.fund_supplier_site
				AND ieba.bank_account_name = xcfst.fund_bank_account_name
				AND nvl(sup.hold_flag,'N') = 'N'
				AND sup.hold_all_payments_flag = 'N'
				AND assa.hold_all_payments_flag = 'N');
*/



       fnd_file.put_line(fnd_file.log,'Step-49');

		--+===========================================================================================================+
		--  STEP#02
		--  Purpose -- Update the funding  table. - ENDS.			
		--+============================================================================================================+	


        BEGIN

		-- +======================================================================================================+
		-- 	STEP#06	--	Relationship cursor. -- STARTS.
		-- +======================================================================================================+

            FOR c_cr_relation_rec IN c_cr_relation LOOP

          FND_FILE.PUT_LINE(FND_FILE.log,'Step-49.01  c_cr_relation');
          FND_FILE.PUT_LINE(FND_FILE.log,'*******Processing Vendor Site : ' ||  c_cr_relation_rec.ebs_vendor_site_ID);


             fnd_file.put_line(fnd_file.log,'Step-50');

                lv_process_r_cnt	:= lv_process_r_cnt + 1;
                lv_err_msg 			:= NULL;
                lv_process_flag 	:= NULL;
                lv_tot_err_msg 		:= NULL;

                BEGIN

                    lv_err_msg := NULL;
                    lv_process_flag := NULL;

                     SELECT COUNT(iepr.relationship_id)
					   INTO lv_fp_relationship_cnt
					   FROM iby_ext_payee_relationships iepr
                      WHERE 1 = 1
						--AND iepr.active = 'Y';
						--AND c_cr_relation_rec.ebs_oldest_open_inv_date/inv_date BETWEEN iepr.from_date AND NVL(iepr.to_date,sysdate)
						AND iepr.party_id = c_cr_relation_rec.ebs_party_id
                        AND iepr.supplier_site_id = c_cr_relation_rec.ebs_vendor_site_id
                        AND iepr.remit_party_id = c_cr_relation_rec.ebs_remit_to_party_id
                        AND iepr.remit_supplier_site_id = c_cr_relation_rec.ebs_remit_to_vendor_site_id;

                EXCEPTION
                     WHEN OTHERS THEN

							lv_process_flag 		:= 'E';
							lv_process_stage 		:= 'FUND_TYPE_RS_ERROR';
							lv_fp_relationship_id	:= NULL;
							lv_err_msg 				:= lv_err_msg||'-'||'Funding type relationship count Error for ebs_vendor_site_id'||'-'||c_cr_relation_rec.ebs_vendor_site_id;

                END;

       fnd_file.put_line(fnd_file.log,'Step-51');

                IF lv_fp_relationship_cnt = 0 THEN

                    BEGIN

       fnd_file.put_line(fnd_file.log,'Step-52');
                    

                        SELECT iby_ext_payee_relship_seq.NEXTVAL
                          INTO lv_fp_rs_seq_id
                          FROM dual;

                        INSERT INTO iby_ext_payee_relationships
                           (relationship_id,
                            party_id,
                            supplier_site_id,
                            remit_party_id,
                            remit_supplier_site_id,
                            from_date,
                            primary_flag,
                            active,
                            created_by,
                            creation_date,
                            last_updated_by,
                            last_update_date,
                            last_update_login,
                            object_version_number)
                          VALUES
                           (lv_fp_rs_seq_id,
                            c_cr_relation_rec.ebs_party_id,
                            c_cr_relation_rec.ebs_vendor_site_id,
                            c_cr_relation_rec.ebs_remit_to_party_id,
                            c_cr_relation_rec.ebs_remit_to_vendor_site_id,
                            c_cr_relation_rec.ebs_oldest_open_inv_date,
                            'N',
                            'Y',
                            l_user_id,
                            SYSDATE,
                            l_user_id,
                            SYSDATE,
                            l_user_id,
                            1);

                        COMMIT;

                        lv_process_flag 		:= 'N';
                        lv_process_stage 		:= 'FUND_TYPE_RS_CREATED_OR_ONE_ACTIVE_RS_EXISTS';
                        lv_fp_relationship_id	:= lv_fp_rs_seq_id;

                    END;

                ELSIF lv_fp_relationship_cnt = 1 THEN

                    BEGIN
                    
       fnd_file.put_line(fnd_file.log,'Step-53');
                    

                         SELECT COUNT(iepr.relationship_id)
                           INTO lv_fp_active_relationship_cnt
                           FROM iby_ext_payee_relationships iepr
                          WHERE 1 = 1
							AND iepr.active = 'Y'
                            AND c_cr_relation_rec.ebs_oldest_open_inv_date BETWEEN iepr.from_date AND nvl(iepr.TO_DATE,SYSDATE)
                            AND iepr.party_id = c_cr_relation_rec.ebs_party_id
                            AND iepr.supplier_site_id = c_cr_relation_rec.ebs_vendor_site_id
                            AND iepr.remit_party_id = c_cr_relation_rec.ebs_remit_to_party_id
                            AND iepr.remit_supplier_site_id = c_cr_relation_rec.ebs_remit_to_vendor_site_id;

                    END;

						IF lv_fp_active_relationship_cnt = 1 THEN

							BEGIN

       fnd_file.put_line(fnd_file.log,'Step-54');

								 SELECT iepr.relationship_id
								   INTO lv_fp_ebs_relationship_id
                                   FROM iby_ext_payee_relationships iepr
                                  WHERE 1 = 1
									and IEPR.ACTIVE = 'Y'
									and c_cr_relation_REC.EBS_OLDEST_OPEN_INV_DATE between IEPR.FROM_DATE and NVL(IEPR.TO_DATE,sysdate)
--									AND c_cr_relation_rec.original_due_date BETWEEN iepr.from_date AND nvl(iepr.TO_DATE,SYSDATE)
									AND iepr.party_id = c_cr_relation_rec.ebs_party_id
									AND iepr.supplier_site_id = c_cr_relation_rec.ebs_vendor_site_id
									AND iepr.remit_party_id = c_cr_relation_rec.ebs_remit_to_party_id
									AND iepr.remit_supplier_site_id = c_cr_relation_rec.ebs_remit_to_vendor_site_id;

							END;

							lv_process_flag 		:= 'N';
							lv_process_stage 		:= 'FUND_TYPE_RS_CREATED_OR_ONE_ACTIVE_RS_EXISTS';
							lv_fp_relationship_id	:= lv_fp_ebs_relationship_id;

						ELSE

							lv_process_flag 		:= 'E';
							lv_process_stage 		:= 'FUND_TYPE_RS_ERROR';
							lv_fp_relationship_id	:= NULL;
							lv_err_msg 				:= lv_err_msg||'-'||'Funding type relationship exists but not active for ebs_vendor_site_id'||'-'||c_cr_relation_rec.ebs_vendor_site_id;

						END IF;

                ELSE

                    lv_process_flag 		:= 'E';
                    lv_process_stage 		:= 'FUND_TYPE_RS_ERROR';
                    lv_fp_relationship_id	:= NULL;
                    lv_err_msg 				:= lv_err_msg||'-'||'More than one Funding type relationships exists for ebs_vendor_site_id'||'-'||c_cr_relation_rec.ebs_vendor_site_id;

                END IF;

       fnd_file.put_line(fnd_file.log,'Step-55');

                IF lv_process_flag = 'E' THEN

                     UPDATE xx_ap_c2fo_award_data_staging xads
						SET xads.ebs_relationship_id = lv_fp_relationship_id,
							xads.process_stage = lv_process_stage,
							xads.error_msg = lv_err_msg,
							xads.process_flag = lv_process_flag,
							xads.last_update_date = SYSDATE,
							xads.last_updated_by = l_user_id
                      WHERE 1 = 1
					    AND xads.fund_type IS NOT NULL
				        AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
						AND xads.ebs_party_id = c_cr_relation_rec.ebs_party_id
                        AND xads.ebs_vendor_site_id = c_cr_relation_rec.ebs_vendor_site_id
                        AND xads.ebs_remit_to_party_id = c_cr_relation_rec.ebs_remit_to_party_id
                        AND xads.ebs_remit_to_vendor_site_id = c_cr_relation_rec.ebs_remit_to_vendor_site_id
                        AND xads.award_file_batch_name = c_award_file_batch_name;
                        --AND xads.processing_batch_name = gc_current_process_batch_name;
                ELSE

                    lv_process_flag := 'N';

                     UPDATE xx_ap_c2fo_award_data_staging xads
						SET xads.ebs_relationship_id = lv_fp_relationship_id,
							xads.process_stage = lv_process_stage,
							xads.process_flag = lv_process_flag,
							xads.last_update_date = SYSDATE,
							xads.last_updated_by = l_user_id
                      WHERE 1 = 1
					    AND xads.fund_type IS NOT NULL
				        AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
                        AND xads.ebs_party_id = c_cr_relation_rec.ebs_party_id
                        AND xads.ebs_vendor_site_id = c_cr_relation_rec.ebs_vendor_site_id
                        AND xads.ebs_remit_to_party_id = c_cr_relation_rec.ebs_remit_to_party_id
                        AND xads.ebs_remit_to_vendor_site_id = c_cr_relation_rec.ebs_remit_to_vendor_site_id
                        AND xads.award_file_batch_name = c_award_file_batch_name
--                        AND xads.processing_batch_name = gc_current_process_batch_name
                        AND nvl(xads.process_flag,'N') != 'E';

                END IF;

       fnd_file.put_line(fnd_file.log,'Step-56');

                COMMIT;

            END LOOP;

		-- +======================================================================================================+
		-- 	STEP#06	--	Relationship cursor. -- STARTS.
		-- +======================================================================================================+

        END;		

		--+===========================================================================================================+
		--  STEP#06
		--  Purpose -- Relationship validation process. - ENDS.		
		--+============================================================================================================+

------------------new2new2new2new2new2new2 relation ship block ends------------------
------------------new2new2new2new2new2new2 relation ship block ends------------------*/

----------------
----------------

------------------ new4new4new4new4new4new4 FP invoice update block starts ----------------
------------------ new4new4new4new4new4new4 FP invoice update block starts ----------------

		--+===========================================================================================================+
		--  STEP#07
		--  Purpose -- Funding Partner invoice update process. - STARTS.			
		--+============================================================================================================+

        BEGIN
		-- +======================================================================================================+
		-- 	STEP#07	--	Funding Partner invoice update cursor. -- STARTS.
		-- +======================================================================================================+

            FOR c_upd_fp_inv_rd_pg_dtls_rec IN c_upd_fp_inv_rd_pg_dtls LOOP

            FND_FILE.PUT_LINE(FND_FILE.log,'Step-56.01  c_upd_fp_inv_rd_pg_dtls_rec');
            FND_FILE.PUT_LINE(FND_FILE.log,'*******Processing Invoice Id : ' ||  c_upd_fp_inv_rd_pg_dtls_rec.invoice_id);
            FND_FILE.PUT_LINE(FND_FILE.log,'*******Processing Invoice : ' ||  C_UPD_FP_INV_RD_PG_DTLS_REC.invoice_num);


                lv_process_r_cnt	:= lv_process_r_cnt + 1;
                lv_err_msg 			:= NULL;
                lv_process_flag 	:= NULL;
                lv_tot_err_msg 		:= NULL;

       fnd_file.put_line(fnd_file.log,'Step-57');

                BEGIN

                    lv_err_msg := NULL;
                    lv_process_flag := NULL;

					 UPDATE ap_invoices_all aia
						set
              aia.pay_group_lookup_code = lv_c2fo_pay_group_lookup_code,
							aia.remit_to_supplier_name = c_upd_fp_inv_rd_pg_dtls_rec.ebs_remit_to_supplier_name,
							aia.remit_to_supplier_id = c_upd_fp_inv_rd_pg_dtls_rec.ebs_remit_to_vendor_id,
							aia.remit_to_supplier_site = c_upd_fp_inv_rd_pg_dtls_rec.ebs_remit_to_supplier_site,
							aia.remit_to_supplier_site_id = c_upd_fp_inv_rd_pg_dtls_rec.ebs_remit_to_vendor_site_id,
							aia.relationship_id = c_upd_fp_inv_rd_pg_dtls_rec.ebs_relationship_id,
							aia.external_bank_account_id = c_upd_fp_inv_rd_pg_dtls_rec.ebs_ext_bank_account_id							
					  WHERE 1 = 1						
						AND aia.invoice_id = c_upd_fp_inv_rd_pg_dtls_rec.invoice_id 
						AND aia.org_id = c_upd_fp_inv_rd_pg_dtls_rec.org_id
						AND aia.ROWID = c_upd_fp_inv_rd_pg_dtls_rec.inv_rowid;

                EXCEPTION				
                     WHEN OTHERS THEN

							lv_process_flag 		:= 'E';

                END;

       fnd_file.put_line(fnd_file.log,'Step-58');

				IF lv_process_flag = 'E' THEN

							lv_process_stage 		:= 'FP_INVOICE_RD_PG_UPDATE_ERROR';
							lv_err_msg 				:= lv_err_msg||'-'||'Funding invoice update exception error for invoice num'||'-'||c_upd_fp_inv_rd_pg_dtls_rec.invoice_num;

                     UPDATE xx_ap_c2fo_award_data_staging xads
						SET xads.process_flag = lv_process_flag,
							xads.process_stage = lv_process_stage,							
							xads.error_msg = lv_err_msg,
							xads.last_update_date = SYSDATE,
							xads.last_updated_by = l_user_id
                      WHERE 1 = 1
					    AND xads.rowid = c_upd_fp_inv_rd_pg_dtls_rec.stg_rowid
						AND xads.fund_type IS NOT NULL
				        AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'						
						AND xads.ebs_invoice_id = c_upd_fp_inv_rd_pg_dtls_rec.invoice_id
						AND xads.ebs_org_id = c_upd_fp_inv_rd_pg_dtls_rec.org_id
						AND xads.award_file_batch_name = c_award_file_batch_name;
--          AND xads.processing_batch_name = gc_current_process_batch_name;

                ELSE

							lv_process_flag 	:= 'N';
							lv_process_stage	:= 'FP_INVOICE_RD_PG_UPDATED';

                     UPDATE xx_ap_c2fo_award_data_staging xads
						SET xads.process_flag = lv_process_flag,
							xads.process_stage = lv_process_stage,
							xads.last_update_date = SYSDATE,
							xads.last_updated_by = l_user_id
                      WHERE 1 = 1
					    AND xads.rowid = c_upd_fp_inv_rd_pg_dtls_rec.stg_rowid
						AND xads.fund_type IS NOT NULL
				        AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'						
						AND xads.ebs_invoice_id = c_upd_fp_inv_rd_pg_dtls_rec.invoice_id
						AND xads.ebs_org_id = c_upd_fp_inv_rd_pg_dtls_rec.org_id
						AND xads.award_file_batch_name = c_award_file_batch_name
--          AND xads.processing_batch_name = gc_current_process_batch_name           
                        AND nvl(xads.process_flag,'N') != 'E';

                END IF;

       fnd_file.put_line(fnd_file.log,'Step-59');

				COMMIT;

            END LOOP;

		-- +======================================================================================================+
		-- 	STEP#07	--	Funding Partner invoice update cursor. -- ENDS.
		-- +======================================================================================================+

        END;		

		--+===========================================================================================================+
		--  STEP#07
		--  Purpose -- Funding Partner invoice update process. - ENDS.
		--+============================================================================================================+

------------------ new4new4new4new4new4new4 FP invoice update block ENDS ----------------
------------------ new4new4new4new4new4new4 FP invoice update block ENDS ----------------*/

----------------
----------------

----------------
----------------

------------------ new5new5new5new5new5new5 FP invoice payment schedule update block starts ----------------
------------------ new5new5new5new5new5new5 FP invoice payment schedule update block starts ----------------

		--+===========================================================================================================+
		--  STEP#08
		--  Purpose -- Funding Partner invoice payment schedule update process. - STARTS.			
		--+============================================================================================================+

        BEGIN

		-- +======================================================================================================+
		-- 	STEP#08	--	Funding Partner invoice payment schedule update cursor. -- STARTS.
		-- +======================================================================================================+

       fnd_file.put_line(fnd_file.log,'Step-60');

            FOR c_upd_fp_inv_ps_rd_pg_dtls_rec IN c_upd_fp_inv_ps_rd_pg_dtls LOOP

            FND_FILE.PUT_LINE(FND_FILE.log,'Step-60.01  c_upd_fp_inv_ps_rd_pg_dtls');
            FND_FILE.PUT_LINE(FND_FILE.log,'*******Processing Invoice Id : ' ||  c_upd_fp_inv_ps_rd_pg_dtls_rec.INVOICE_ID);
            FND_FILE.PUT_LINE(FND_FILE.log,'*******Processing Invoice: ' ||  C_UPD_FP_INV_PS_RD_PG_DTLS_REC.ebs_invoice_num);


                lv_process_r_cnt	:= lv_process_r_cnt + 1;
                lv_err_msg 			:= NULL;
                lv_process_flag 	:= NULL;
                lv_tot_err_msg 		:= NULL;

                BEGIN

                    lv_err_msg := NULL;
                    lv_process_flag := NULL;

       fnd_file.put_line(fnd_file.log,'Step-61');


					 UPDATE ap_payment_schedules_all apsa
						SET apsa.remit_to_supplier_name = c_upd_fp_inv_ps_rd_pg_dtls_rec.ebs_remit_to_supplier_name,
							apsa.remit_to_supplier_id = c_upd_fp_inv_ps_rd_pg_dtls_rec.ebs_remit_to_vendor_id,
							apsa.remit_to_supplier_site = c_upd_fp_inv_ps_rd_pg_dtls_rec.ebs_remit_to_supplier_site,
							apsa.remit_to_supplier_site_id = c_upd_fp_inv_ps_rd_pg_dtls_rec.ebs_remit_to_vendor_site_id,
							apsa.relationship_id = c_upd_fp_inv_ps_rd_pg_dtls_rec.ebs_relationship_id,
							apsa.external_bank_account_id = c_upd_fp_inv_ps_rd_pg_dtls_rec.ebs_ext_bank_account_id							
					  WHERE 1 = 1						
						AND apsa.invoice_id = c_upd_fp_inv_ps_rd_pg_dtls_rec.invoice_id 
						AND apsa.org_id = c_upd_fp_inv_ps_rd_pg_dtls_rec.org_id
						AND apsa.ROWID = c_upd_fp_inv_ps_rd_pg_dtls_rec.inv_ps_rowid;

                EXCEPTION				
                     WHEN OTHERS THEN

							lv_process_flag 		:= 'E';

                END;

       fnd_file.put_line(fnd_file.log,'Step-62');

				IF lv_process_flag = 'E' THEN

							lv_process_stage 		:= 'FP_INVOICE_PS_RD_UPDATE_ERROR';
							lv_err_msg 				:= lv_err_msg||'-'||'Funding invoice payment schedule update exception error for invoice num'||'-'||c_upd_fp_inv_ps_rd_pg_dtls_rec.ebs_invoice_num;

                     UPDATE xx_ap_c2fo_award_data_staging xads
						SET xads.process_flag = lv_process_flag,
							xads.process_stage = lv_process_stage,							
							xads.error_msg = lv_err_msg,
							xads.last_update_date = SYSDATE,
							xads.last_updated_by = l_user_id
                      WHERE 1 = 1
					    AND xads.rowid = c_upd_fp_inv_ps_rd_pg_dtls_rec.stg_ps_rowid
						AND xads.fund_type IS NOT NULL
				        AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'						
						AND xads.ebs_invoice_id = c_upd_fp_inv_ps_rd_pg_dtls_rec.invoice_id
						AND xads.ebs_org_id = c_upd_fp_inv_ps_rd_pg_dtls_rec.org_id
						AND xads.award_file_batch_name = c_award_file_batch_name;	
--          AND xads.processing_batch_name = gc_current_process_batch_name;

                ELSE

							lv_process_flag 	:= 'N';
							lv_process_stage	:= 'FP_INVOICE_PS_RD_UPDATED';

                     UPDATE xx_ap_c2fo_award_data_staging xads
						SET xads.process_flag = lv_process_flag,
							xads.process_stage = lv_process_stage,
							xads.last_update_date = SYSDATE,
							xads.last_updated_by = l_user_id
                      WHERE 1 = 1
					    AND xads.rowid = c_upd_fp_inv_ps_rd_pg_dtls_rec.stg_ps_rowid
						AND xads.fund_type IS NOT NULL
						AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'						
						AND xads.ebs_invoice_id = c_upd_fp_inv_ps_rd_pg_dtls_rec.invoice_id
						AND xads.ebs_org_id = c_upd_fp_inv_ps_rd_pg_dtls_rec.org_id
						AND xads.award_file_batch_name = c_award_file_batch_name
--          AND xads.processing_batch_name = gc_current_process_batch_name           
                        AND nvl(xads.process_flag,'N') != 'E';

                END IF;

       fnd_file.put_line(fnd_file.log,'Step-63');

				COMMIT;

            END LOOP;

		-- +======================================================================================================+
		-- 	STEP#08	--	Funding Partner invoice payment schedule update cursor. -- STARTS.
		-- +======================================================================================================+

        END;		

		--+===========================================================================================================+
		--  STEP#08
		--  Purpose -- Funding Partner invoice payment schedule update process. - ENDS.	
		--+============================================================================================================+

------------------ new5new5new5new5new5new5 FP invoice payment schedule update block ENDS ----------------
------------------ new5new5new5new5new5new5 FP invoice payment schedule update block ENDS ----------------*/

----------------
----------------

       fnd_file.put_line(fnd_file.log,'Step-64');

        BEGIN

             UPDATE xx_ap_c2fo_award_data_staging xads
                set xads.process_stage = 'SUCCESSFULLY_PROCESSED',
                    process_status= 'PROCESSED',
			          		xads.process_flag = 'Y',
				          	xads.last_update_date = sysdate,
			          		xads.last_updated_by = l_user_id
              WHERE 1 = 1
                AND xads.award_file_batch_name = c_award_file_batch_name
--              AND xads.processing_batch_name = gc_current_process_batch_name               
				AND xads.fund_type IS NOT NULL
                AND xads.process_stage = 'FP_INVOICE_PS_RD_UPDATED'				
				AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
                AND xads.process_flag = 'N';

        END;

        COMMIT;
		
--------------
--------------

---------@@@@@@@@@@@@@*********************-------------------

            BEGIN
            
       fnd_file.put_line(fnd_file.log,'Step-65');
            
                 SELECT COUNT(*)
                   INTO lv_fp_stg_success_r_cnt
                   FROM xx_ap_c2fo_award_data_staging xads
				  WHERE 1 = 1
					AND xads.fund_type IS NOT NULL
					AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE'
					AND xads.award_file_batch_name = c_award_file_batch_name
--        AND xads.processing_batch_name = gc_current_process_batch_name          
					AND xads.process_flag = 'Y'
					AND xads.process_stage = 'SUCCESSFULLY_PROCESSED';

					fnd_file.put_line(fnd_file.log,'FP Successfully processed record count is -  '|| lv_fp_stg_success_r_cnt|| '.');
            END;	

            begin
                 SELECT COUNT(*)
                   INTO lv_fp_stg_err_r_cnt
                   FROM xx_ap_c2fo_award_data_staging xads
				  WHERE 1 = 1
					AND xads.fund_type IS NOT NULL
					AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE' 
					AND xads.award_file_batch_name = c_award_file_batch_name
					AND xads.process_flag != 'Y'
					AND xads.process_stage != 'SUCCESSFULLY_PROCESSED';

					fnd_file.put_line(fnd_file.log,'FP Total Error Records is -  '|| lv_fp_stg_err_r_cnt|| '.');
            END;				

       fnd_file.put_line(fnd_file.log,'Step-66');


            BEGIN
                 SELECT COUNT(*)
                   into lv_fp_duplicate_r_cnt
                   FROM xx_ap_c2fo_award_data_staging xads
				  WHERE 1 = 1
					AND xads.fund_type IS NOT NULL
					AND xads.award_record_activities = 'UPDATE_RD_AND_PG_TYPE' 
          AND xads.award_file_batch_name = c_award_file_batch_name
--					AND xads.processing_batch_name = gc_current_process_batch_name
					AND xads.process_stage = 'DUPLICATE';

					fnd_file.put_line(fnd_file.log,'FP Duplicate Record count - '|| lv_fp_duplicate_r_cnt|| '.');
            END;			

       FND_FILE.PUT_LINE(FND_FILE.LOG,'------SUBMITTED REMIT BANK EXTRACT PROGRAM-------');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------');

       XX_AP_C2FO_EXTRACT_PKG.REMIT_BANK_EXTRACT( v_errbuf, v_retcode);

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Step-67');


-----------------------Phase-2------Main Body End-----------------------------------------------
 -- Funding Partner Buyer Toggle Code Ends 
 --------------------------------------------------------------------------------------

        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.log,'   ');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Award Process Completed');
        fnd_file.put_line(fnd_file.log,' ');
        fnd_file.put_line(fnd_file.log,' ');

   EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'   ');
        fnd_file.put_line(fnd_file.LOG,'   ');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Award Process Errored with error below :');
        fnd_file.put_line(fnd_file.log, substr(sqlerrm,1,100));
        retcode := 2;
        rollback;
        
    END process_award;

END XX_AP_C2FO_AWARD_PKG;
/
SHOW ERRORS