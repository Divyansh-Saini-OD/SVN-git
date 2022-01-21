create or replace PACKAGE BODY XX_AP_NACHABOA_EFT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Office Depot Organization                      |
-- +===================================================================+
-- | Name  : xx_ap_nachaboa_eft_pkg                                    |
-- | Description      :  Package contains program units which will be  |
-- |                     called in the payment process request hook    |
-- |                     package to generate extra information for     |
-- |                     format payment which will be                  |
-- |                     sent to Bank of America. This program replaces|
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author          Remarks                    |
-- |=======   ==========   =============   ============================|
-- |1.0       27-JUL-2013  Satyajeet M    I0438 - Initial draft version|
-- |1.1       04-Oct-2013  Satyajeet M    Added logic to add template  |  
-- |                                      name in the final file name  |
-- |1.2      09-Oct-2013   Satyajeet M    modfied code for bug for     |
-- |                                      incorrect card number        |
-- |1.3      18-Nov-2013   Satyajeet M    Added code for decryption    |
-- |1.4      04-Dec-2013   Satyajeet M    Changed the payment process  |
-- |                                     profile system name to EFT_PPP|
-- |                                      as per SIT02 setup. REF#PPP  |
-- |1.5      09-DEC-2013   Satyajeet M     Changed the retturn type of |
-- |                                        paymented_details function |
-- |                                        to CLOB from VARCHAR2      |
-- |1.6      13-Dec-2013   Satyajeet M   Code fix for defect 26389     |
-- |1.7      13-Mar-2014   Darshini      Changes for defect 28592.     |
-- |                                     Included IF condition to submit|
-- |                                     File Copy only for EFT_PPP.   |
-- |1.8      14-Mar-2014   Darshini      Changes for defect 28958.     |
-- |                                     Changed to use the Credit Card|
-- |                                     from the Exp Report instead of|
-- |                                     that assigned to Employee.    |
-- |1.9      18-Mar-2014   Darshini      Changes for defect 28958.     |
-- |                                     Included condition as a       | 
-- |                                     single expense report could   |
-- |                                     have multiple transactions.   |
-- |2.0      18-Mar-2014   Jay Gupta     Defect# 28983                 |
-- |2.1      19-Mar-2014   Darshini      Changes for defects 28958 and 28983.     |
-- |                                     Included parameters and logic |
-- |                                     in payment_details function.  |
-- |2.2      19-Mar-2014   Jay Gupta     Defect 28983                  |
-- |2.3      20-Mar-2014   Veronica      Changes for defect 28958 for Pcard.|
-- |2.4      20-Mar-2014   Paddy Sanjeevi Removed \ in lc_invoice_description for JP Morgan|
-- |2.5      25-Mar-2014   Veronica      Changed the get_dec_ccno      |
-- |                                     to a private function.        |
-- |2.6      04-Nov-2015   Harvinder Rakhra Retroffit R12.2            |
-- |2.7      08-Mar-2017   Madhan Sanjeevi Encryption fail Defect#41209|
-- |2.8      01-July-2018  Bhargavi Ankolekar Adding replace function to 
-- |                      replace carriage return from the invoice     |
-- | 						description and invoice number column for defect #45026 |
-- +===================================================================+
AS

   --ln_isa_seq_num           NUMBER := 0;  --V2.0
   --lc_st_cntrl_num          NUMBER := 1;  --V2.0
   
-- +===================================================================+
-- | Name  : get_dec_ccno                                               |
-- | Description: This  fuction will return decrypted creditcard numnber|
-- |                                                                   |
-- +===================================================================+
   FUNCTION get_dec_ccno(p_identifier IN VARCHAR2
						,p_encrypted  IN VARCHAR2)
     RETURN VARCHAR2
   IS
     lc_encrypted_cc_data    iby_creditcard.attribute4%TYPE;
	 lc_identifier           iby_creditcard.attribute5%TYPE;
	 lc_decrypted_cc_data    iby_creditcard.attribute5%TYPE;
	 lc_decrypted_error_msg  VARCHAR2(1000);
   BEGIN
      lc_identifier  := p_identifier;
	  lc_encrypted_cc_data :=    p_encrypted;

	  /* set the context for decryption */
	  DBMS_SESSION.set_context(namespace => 'XX_AP_CCOUT_CONTEXT', -- Context provided by 
                               ATTRIBUTE => 'TYPE',
                                VALUE => 'EBS'
							    );	
	  
      XX_OD_SECURITY_KEY_PKG.DECRYPT (X_DECRYPTED_VAL => lc_decrypted_cc_data
                                     ,X_ERROR_MESSAGE => lc_decrypted_error_msg
                                     ,P_MODULE => 'AJB'
                                     ,P_KEY_LABEL => lc_identifier
                                     ,P_ALGORITHM => '3DES'
                                     ,P_ENCRYPTED_VAL => lc_encrypted_cc_data
                                     ,P_FORMAT => 'BASE64'
                                     ); 
     RETURN lc_decrypted_cc_data;									 
   EXCEPTION
     WHEN OTHERS THEN
           fnd_file.put_line (fnd_file.LOG, 'Error in decryption ' || lc_decrypted_error_msg);
	   lc_decrypted_cc_data := '          ';
	   RETURN lc_decrypted_cc_data;
   END get_dec_ccno;
   
-- +===================================================================+
-- | Name  : SETTLE_DATE                                               |
-- | Description: This  fuction will return the next available business|
-- |             date. The number to days to settle a payment will be  |
-- |          stored on the xx_po_vendor_sites_kff_v (eft_settle_days) |
-- |           field                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |                                                                   |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  17-Sep-2014 Satyajeet M      Initial draft version       |
-- |                                                                   |
-- +===================================================================+
   FUNCTION settle_date (
      p_vendor_id        IN   NUMBER,
      p_vendor_site_id   IN   NUMBER,
      p_check_date       IN   DATE
   )
      RETURN VARCHAR2
   IS
      lc_settle_days   VARCHAR2 (4);
      lc_settle_date   VARCHAR2 (6);
   BEGIN
      SELECT NVL (xpvs.eft_settle_days, 0)
        INTO lc_settle_days
        FROM xx_po_vendor_sites_kff_v xpvs, ap_supplier_sites aps
       WHERE xpvs.vendor_site_id = aps.vendor_site_id
         AND aps.vendor_site_id = p_vendor_site_id
         AND aps.vendor_id = p_vendor_id;

      lc_settle_date :=
         TO_CHAR
              (xxod_fin_reports_pkg.ap_get_business_day (  p_check_date
                                                         + NVL
                                                              (lc_settle_days,
                                                               0
                                                              )
                                                        ),
               'YYMMDD'
              );
      RETURN lc_settle_date;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
   END settle_date;

   FUNCTION payment_details (
      p_vendor_id         IN       NUMBER,
      p_vendor_site_id    IN       NUMBER,
      p_vendor_type       IN       VARCHAR2,
      p_payment_type      IN       VARCHAR2,
      p_payment_id        IN       NUMBER,
      p_batch_cnt         IN       NUMBER,
      p_isa_seq_num       IN       NUMBER, -- Changes for defect 28958 and 28983
      p_st_cntrl_num      IN       NUMBER, -- Changes for defect 28958 and 28983
      x_addenda_rec_cnt   OUT      NUMBER
   )
    --  RETURN VARCHAR2 -- Commented 09122013
	RETURN CLOB -- Added 09122013
   AS
--------------------------------------
-- Global
--------------------------------------
      lc_amex_vendor_name      xx_fin_translatevalues.source_value1%TYPE;
      lc_garnish_vendor_type   xx_fin_translatevalues.source_value1%TYPE;
      lc_edi_sender_id         xx_fin_translatevalues.source_value1%TYPE;
      lc_test_indicator        xx_fin_translatevalues.source_value1%TYPE;
      lc_edi_qualifier         xx_fin_translatevalues.source_value1%TYPE;
      ln_gs_edi_sender_id      xx_fin_translatevalues.source_value1%TYPE;
      ln_edi_duns_id           xx_fin_translatevalues.source_value1%TYPE;
      lc_file_id_mod           xx_fin_translatevalues.source_value1%TYPE;
      lc_edi_id                xx_fin_translatevalues.source_value1%TYPE;
      -- need to be defined
      lc_current_step          VARCHAR2 (1000);
      --lc_entrydetail2          VARCHAR2 (200);  -- Commented 09122013
      --lc_print_line            VARCHAR2 (5000); -- Commented 09122013
      --lc_print_line_tot        VARCHAR2 (5000); -- Commented 09122013
	  --lc_entrydetail2          VARCHAR2 (1000);   -- Added 09122013
    lc_entrydetail2          CLOB;   -- Added 09122013
	  lc_print_line            CLOB; -- Added 09122013
      lc_print_line_tot        CLOB; -- Added 09122013
      ln_wrap_length           NUMBER                                   := 80;
      -- number of columns before return character
      ln_rec_length            NUMBER;
   --V2.0   ln_isa_seq_num           NUMBER                                    := 0;
      ln_isa_seq_num           NUMBER; -- Changes for defect 28958 (V2.1)
      ln_rec_seq_num           NUMBER                                    := 0;
      ln_rec_cntrl_num         NUMBER                                    := 0;
      ln_pay_tot_amt           NUMBER                                    := 0;
-----------------
--Control Headers
-----------------
      lc_intchg_cntrl          VARCHAR2 (200);
      --Interchange Control Header (ISA)
      lc_func_grp_cntrl        VARCHAR2 (200);
      --Functional Group Control Header (GS)
      lc_trans_set_cntrl       VARCHAR2 (200);
      --Transaction Set Control Header (ST)
      lc_beg_pay_order         VARCHAR2 (2000);
      --Beginning Segment for Payment Order(BPR)
      lc_trn_hdr_rec           VARCHAR2 (200);
      lc_ref_hdr_rec           VARCHAR2 (200);
      lc_n1pe_hdr_rec          VARCHAR2 (200);
      lc_n1pr_hdr_rec          VARCHAR2 (200);
      lc_ent_hdr_rec           VARCHAR2 (200);
      lc_vendor_name           ap_suppliers.vendor_name%TYPE;
------------------
-- Trailer records
------------------
      lc_se_tran_set_trail     VARCHAR2 (200);                  -- SE Trailer
      lc_ge_tran_set_trail     VARCHAR2 (200);                  -- GE Trailer
      lc_lea_cntrl_trailer     VARCHAR2 (200);                 -- IEA Trailer
      ln_se_rec_cnt            NUMBER                                    := 0;
      --sum records from ST - SE
      ln_ge_rec_cnt            NUMBER                                    := 0;
      --sum records from GS - GE

      -- Missing Globals
   --V2.0   lc_st_cntrl_num          NUMBER                                    := 0;
      lc_st_cntrl_num          NUMBER; -- Changes for defect 28958 V2.1
      --Global
      lc_bank_routing_num      VARCHAR2 (100)                  := '063000021';
      
	  -- Global Routing Number
      lc_bank_account_num      VARCHAR2 (100)            := 'BANK OF AMERICA';
      ln_check_number          VARCHAR2 (100);
      ln_detail_counter        NUMBER                                    := 0;
      --lc_return_addend       VARCHAR2 (4000); -- Commented 09122013
	  lc_return_addend         CLOB; -- Added 09122013
      ln_batch_count           NUMBER                                    := 0;
      lc_rec_dfi_bank_id       NUMBER                                    := 0;
      lc_rec_dfi_bank_acct     VARCHAR2 (240);
      -- lc_addenda               VARCHAR2 (4000); -- Commented 09122013
	  lc_addenda               CLOB;
      ln_batch_total_cnt       NUMBER                                    := 0;
      ln_total_record_cnt      NUMBER                                    := 0;
      ln_file_addenda_cnt      NUMBER                                    := 0;
      lc_detail_counter        NUMBER                                    := 0;
-----------------------------
-- Vendor RMR Variables
-----------------------------
      ln_invoice_num           ap_selected_invoices.invoice_num%TYPE;
      ln_payment_amount        ap_selected_invoices.payment_amount%TYPE;
      ln_invoice_amount        ap_selected_invoices.invoice_amount%TYPE;
      ln_discount_amount       ap_selected_invoices.discount_amount%TYPE;
      lc_rmr_code              VARCHAR2 (2);
-----------------------------------------------------
 -- variable lc_invoice_description
-----------------------------------------------------
      lc_invoice_description   ap_selected_invoices.invoice_description%TYPE;

-- Changes for the private get_dec_ccno. V2.5
lc_jpm_cc_attribute5  iby_creditcard.attribute5%TYPE;
lc_jpm_cc_attribute4  iby_creditcard.attribute4%TYPE;
ln_jpm_payment_amount iby_docs_payable_all.payment_amount%TYPE;
lc_jpm_invoice_num    ap_invoices.invoice_num%TYPE;
-- End of changes V2.5

---------------------------------------------------
-- Garnishment payee Details cursor 705 DED records
---------------------------------------------------
     -- Details for Garnishment records are loaded into
     -- ap_invoice_distributions_all.attritube12.  Values are delimited
     -- by a '*' within the field. The field layout is defined below:
     -- (Case_Identifier*SSN*Parent_Name*FIPS_Code*Employee_Termination_Indicator)
      CURSOR garnish_details_cursor
      IS
         SELECT    'DED'
                || '*'
                || 'CS'
                || '*'
                ||
                   -- Case Identifier
                   SUBSTR (SUBSTR (aida.attribute12,
                                   1,
                                   (INSTR (aida.attribute12, '*', 1, 1) - 1
                                   )
                                  ),
                           1,
                           20
                          )
                || '*'
                ||
                   -- Pay Date
                   TO_CHAR (NVL (ipa.payment_date, SYSDATE), 'YYMMDD')
                || '*'
                || NVL (aida.amount * 100, 0)
                || '*'
                ||
                   -- SSN
                   DECODE (asi.org_id,
                           404, SUBSTR (SUBSTR (aida.attribute12,
                                                (  INSTR (aida.attribute12,
                                                          '*',
                                                          1,
                                                          1
                                                         )
                                                 + 1
                                                ),
                                                  (  INSTR (aida.attribute12,
                                                            '*',
                                                            1,
                                                            2
                                                           )
                                                   - 1
                                                  )
                                                - INSTR (aida.attribute12,
                                                         '*',
                                                         1,
                                                         1
                                                        )
                                               ),
                                        1,
                                        9
                                       ),
                           ' '
                          )
                || '*'
                ||
                   -- Medical Support Indicator
                   NVL (SUBSTR (aida.attribute12,
                                (INSTR (aida.attribute12, '*', 1, 2) + 1
                                ),
                                  (INSTR (aida.attribute12, '*', 1, 3) - 1)
                                - INSTR (aida.attribute12, '*', 1, 2)
                               ),
                        ' '
                       )
                || '*'
                ||
                   -- Parent Name
                   NVL (SUBSTR (SUBSTR (aida.attribute12,
                                        (  INSTR (aida.attribute12, '*', 1, 3)
                                         + 1
                                        ),
                                          (  INSTR (aida.attribute12,
                                                    '*',
                                                    1,
                                                    4
                                                   )
                                           - 1
                                          )
                                        - INSTR (aida.attribute12, '*', 1, 3)
                                       ),
                                1,
                                10
                               ),
                        ' '
                       )
                || '*'
                ||
                   -- FIPS Code
                   NVL (SUBSTR (SUBSTR (aida.attribute12,
                                        (  INSTR (aida.attribute12, '*', 1, 4)
                                         + 1
                                        ),
                                          (  INSTR (aida.attribute12,
                                                    '*',
                                                    1,
                                                    5
                                                   )
                                           - 1
                                          )
                                        - INSTR (aida.attribute12, '*', 1, 4)
                                       ),
                                1,
                                7
                               ),
                        ' '
                       )
                || '*'
                ||
                   -- Employment Termination Indicator
                   NVL (SUBSTR (aida.attribute12,
                                (INSTR (aida.attribute12, '*', 1, 5) + 1
                                ),
                                  (LENGTH (aida.attribute12) + 1)
                                - INSTR (aida.attribute12, '*', 1, 5)
                               ),
                        ' '
                       )
                || '\'
           FROM ap_invoices_all asi,
                iby_docs_payable_all idp,
                iby_payments_all ipa,
                ap_invoice_distributions_all aida,
                ap_suppliers ap
          WHERE ipa.payment_id = idp.payment_id
            AND ipa.payee_party_id = ap.party_id
            AND NVL (ap.vendor_type_lookup_code, 'Y') = p_vendor_type
            AND asi.invoice_num = idp.calling_app_doc_ref_number
            AND asi.invoice_id = idp.calling_app_doc_unique_ref2
            AND ipa.payment_id = p_payment_id
            AND aida.invoice_id = asi.invoice_id
            AND aida.amount <> 0
            AND idp.document_status = 'PAYMENT_CREATED';

---------------------------------------------------
-- JP Morgan payee Details cursor 705 RMR records
---------------------------------------------------
      CURSOR jpm_details_cursor
      IS
-- Changes for the private get_dec_ccno. V2.5
         --SELECT    'RMR'
         --       || '*'
         --       || 'IV'
         --       || '*'
         --       --|| icc.ccnumber -- Commeted as the cardnumber will be encrypted 
	--			-- Start: Added for decryption of the data
	--			||xx_ap_nachaboa_eft_pkg.get_dec_ccno( icc.attribute5 -- identifier
	--			              ,icc.attribute4 -- lc_encrypted_data  
	--						  )
         --      -- End: added for decryption of the data							  
         --       || '**'
         --       || LTRIM (TO_CHAR (NVL (idp.payment_amount, 0),
         --                          '999999999.99')
         --                )
         --       || '\'
         --       || 'REF*1Z*'
         --       || ai.invoice_num
         --       || '\'
----
         SELECT icc.attribute5 -- identifier
                ,icc.attribute4 -- lc_encrypted_data  
                ,idp.payment_amount
                ,ai.invoice_num
-- End of changes V2.5
           FROM iby_payments_all ipa,       --ap_selected_invoice_checks asic,
                iby_docs_payable_all idp,          --ap_selected_invoices asi,
                ap_invoices ai,
                --ap_suppliers aps,
                ap_expense_report_headers_all aerh,
                ap_cards_all c,
                iby_creditcard icc
          WHERE idp.calling_app_doc_unique_ref2 = ai.invoice_id
            AND idp.payment_id = ipa.payment_id
            AND idp.DOCUMENT_STATUS = 'PAYMENT_CREATED'
            AND ipa.supplier_site_id = p_vendor_site_id
            AND aerh.vouchno = ai.invoice_id
            AND c.employee_id = aerh.employee_id
            AND ipa.payment_id = p_payment_id
            --AND icc.instrid = c.card_id                -- Bug : Commmented --Invalid card number
            AND icc.instrid = c.card_reference_id        -- Bug : Added -- card reference
            -- AND icc.ccnumber = -- Commented for defect 28958
            AND c.card_id = -- Changed for defect 28958
                   -- NVL ((SELECT DISTINCT apt.card_number -- Commented for defect 28958
                   (SELECT apt.card_id -- Changed for defect 28958
                                    FROM ap_expense_report_headers_all aph,
                                         ap_credit_card_trxns_all apt
                                   WHERE apt.report_header_id =
                                                          aph.report_header_id
                                     AND aph.report_header_id =
                                                         --aph.bothpay_parent_id),
                                                         aerh.bothpay_parent_id --),
									 AND rownum = 1 --Added for Defect# 28958, as a single expense report could have multiple transactions.
                        --icc.ccnumber
                       );

----------------------------------------------
-- VENDOR payee Details cursor 705 RMR records
----------------------------------------------
      CURSOR vendor_details_cursor
      IS
         ----SELECT SUBSTR (aia.invoice_num, 1, 30),
		 SELECT replace(SUBSTR (aia.invoice_num, 1, 30),CHR(13)),-----Adding for defect #45026
                LTRIM (TO_CHAR (NVL (idp.payment_amount, 0), '999999999.99')),
                LTRIM (TO_CHAR (NVL (aia.invoice_amount, 0), '999999999.99')),
                LTRIM (TO_CHAR (NVL (idp.payment_curr_discount_taken, 0),
                                '999999999.99'
                               )
                      ),
                ----aia.description
				replace(aia.description,CHR(13)) ------- Adding for defect #45026
                ,aia.invoice_date --v2.3
           FROM iby_payments_all iba,
                iby_docs_payable_all idp,
                ap_invoices_all aia
          WHERE iba.payment_id = p_payment_id
            AND idp.payment_id = iba.payment_id
            AND aia.invoice_id = idp.calling_app_doc_unique_ref2
            AND idp.document_status = 'PAYMENT_CREATED';

----------------------------------------------
-- amex_details_cursor
----------------------------------------------
      CURSOR amex_details_cursor
      IS
         SELECT    'RMR'
                || '*'
                || 'CM'
                || '*'
                || xais.global_attribute1
                || '**'
                || LTRIM (TO_CHAR (NVL (ipa.payment_amount, 0),
                                   '999999999.99')
                         )
                || '\'
                || 'REF*'
                || SUBSTR (asi.invoice_num, 1, 2)
                || '*'
                || SUBSTR (asi.invoice_num, 3, 2)
                || '\REF*'
                || SUBSTR (asi.invoice_num, 5, 2)
                || '*'
                || SUBSTR (asi.invoice_num, 7, 2)
                || '*'
                || SUBSTR (asi.invoice_num, 9, 2)
                || '\'
           FROM iby_payments_all ipa,
                iby_docs_payable_all idp,
                ap_invoices asi,
                xx_ap_inv_interface_stg xais
          WHERE ipa.payment_id = idp.payment_id
            AND asi.invoice_id = idp.calling_app_doc_unique_ref2
            AND ipa.supplier_site_id = p_vendor_site_id
            AND LTRIM (xais.attribute10, 0) =
                     RTRIM (LTRIM (ipa.payee_supplier_site_name, 'E0'), 'PRY')
            AND xais.invoice_date = asi.invoice_date
            AND TRIM (xais.invoice_num) = TRIM (asi.invoice_num)
            AND ipa.payment_id = p_payment_id
            AND idp.DOCUMENT_STATUS = 'PAYMENT_CREATED';
            ln_site_count number;  --V2.0
            lc_pcard_inv_desc varchar2(500);  --V2.3
            ld_pcard_inv_date ap_invoices_all.invoice_date%type;  --V2.3
   BEGIN
	  
  
      ln_batch_count := p_batch_cnt;
      lc_detail_counter := p_batch_cnt;
      ln_detail_counter := p_batch_cnt;

------------------------------------------
-- Derive the parameter values
------------------------------------------
      SELECT val.source_value1,          -- Vendor Name for the Amex Payments,
                               val.source_value2,
                                                 -- Vendor Type for the Child Garnish Payments
                                                 val.source_value3,
             -- EDI Sender Id
             val.source_value4,                              -- Test Indicator
                               DECODE (val.source_value4, 'P', '01', 'ZZ'),
             -- lc_edi_qualifier
             val.source_value5,            -- EDI GS Sender ID (705 GS Record)
                               val.source_value6,
             -- File ID Modifier Temporary workaround default 'A'
             val.source_value7                                  -- EDI Duns Id
        INTO lc_amex_vendor_name, lc_garnish_vendor_type, lc_edi_sender_id,
             lc_test_indicator, lc_edi_qualifier,
             ln_gs_edi_sender_id, lc_file_id_mod,
             ln_edi_duns_id
        FROM xx_fin_translatedefinition def, xx_fin_translatevalues val
       WHERE def.translate_id = val.translate_id
         AND def.translation_name = 'OD_AP_NACHA_DETAILS'
         AND SYSDATE BETWEEN def.start_date_active
                         AND NVL (def.end_date_active, SYSDATE + 1)
         AND SYSDATE BETWEEN val.start_date_active
                         AND NVL (val.end_date_active, SYSDATE + 1)
         AND def.enabled_flag = 'Y'
         AND val.enabled_flag = 'Y';

-------------------------------------------------
-- get Bank Branch Number and bank account number
-------------------------------------- ----------
      SELECT NVL (iba.int_bank_account_number, 0)       -- Bank Account number
                                                 ,
             NVL (iba.int_bank_branch_number, '06300002')
                                                         -- Bank Routing Number
      ,
             NVL (iba.int_bank_name, 'BANK OF AMERICA'),          -- lc_edi_id
             iba.paper_document_number,                         -- CheckNumber
                                       iba.ext_branch_number,
             --lc_rec_dfi_bank_id
             iba.ext_bank_account_number             --lc_rec_dfi_bank_account
        INTO lc_bank_account_num,
             lc_bank_routing_num,
             lc_edi_id,
             ln_check_number, lc_rec_dfi_bank_id,
             lc_rec_dfi_bank_acct
        FROM iby_payments_all iba
       WHERE payment_id = p_payment_id;

-------------------------------
-- Initalize 705 Header records
-------------------------------
      --ln_isa_seq_num := ln_isa_seq_num + 1; -- Changes for defect 28958 V2.1
      ln_isa_seq_num := p_isa_seq_num; -- Changes for defect 28958 V2.1
      --lc_st_cntrl_num := lc_st_cntrl_num + 1; -- Changes for defect 28958 V2.1
      lc_st_cntrl_num := p_st_cntrl_num; -- Changes for defect 28958 V2.1
-------------------
--ISA Header Record
-------------------
      lc_current_step := ' Step: Intialize ISA Header Record ';
      DBMS_OUTPUT.put_line (lc_current_step);
      
      IF p_payment_type = 'GARNSH'
      THEN
         lc_intchg_cntrl :=
               'ISA*'
            || '00*'
            || '          *'
            || '00*'
            || '          *'
            || '08*'
            || RPAD (SUBSTR (lc_edi_sender_id, 1, 10), 15, ' ')
            || '*'
            || lc_edi_qualifier
            || '*'
            || RPAD (SUBSTR (lc_edi_id                   -- need to be defined
                                      ,
                             1, 15), 15, ' ')
            || '*'
            || TO_CHAR (SYSDATE, 'YYMMDD')
            || '*'
            || TO_CHAR (SYSDATE, 'HH24MI')
            || '*'
            || 'U*'
            || '00400*'
            || LPAD (ln_isa_seq_num, 9, '0')
            || '*'
            || '0*'
            || lc_test_indicator
            || '*\';
      ELSIF p_payment_type = 'JP MORGAN'
      THEN
        -- V2.0, Added else condition for Pcard
        -- V2.3, Changed to use translation value.
        BEGIN
         SELECT COUNT(1)
         INTO ln_site_count
         FROM AP_SUPPLIER_SITES_all assa
              ,ap_suppliers asu
              ,xx_fin_translatedefinition def
              ,xx_fin_translatevalues val
         WHERE def.translate_id = val.translate_id
         AND def.translation_name = 'XX_PCARD_DETAILS'
         AND SYSDATE BETWEEN def.start_date_active
                         AND NVL (def.end_date_active, SYSDATE + 1)
         AND SYSDATE BETWEEN val.start_date_active
                         AND NVL (val.end_date_active, SYSDATE + 1)
         AND def.enabled_flag = 'Y'
         AND val.enabled_flag = 'Y'
         AND asu.vendor_id = assa.vendor_id
         AND asu.vendor_id = p_vendor_id
         AND asu.segment1 = val.target_value2
         AND assa.VENDOR_SITE_ID = P_VENDOR_SITE_ID
         AND assa.VENDOR_SITE_CODE = val.target_value3;

          --SELECT COUNT(1)
          --INTO ln_site_count
          --FROM AP_SUPPLIER_SITES_all
          --WHERE VENDOR_SITE_ID = P_VENDOR_SITE_ID
          --AND VENDOR_SITE_CODE = 'E814674PY';
        EXCEPTION
        WHEN OTHERS THEN
          ln_site_count := 0;
        END;
        IF ln_site_count   = 0 THEN
          lc_intchg_cntrl := 
          'ISA*' 
          || '00*' 
          || '          *' 
          || '00*' 
          || '          *' 
          || 'ZZ*' 
          || RPAD (SUBSTR (lc_edi_sender_id, 1, 10), 15, ' ') 
          || '*' 
          || 'ZZ' 
          || '*' 
          || RPAD (SUBSTR ('021000021      ', 1, 15), 15, ' ') 
          || '*' 
          || TO_CHAR (SYSDATE, 'YYMMDD') 
          || '*' 
          || TO_CHAR (SYSDATE, 'HH24MI') 
          || '*' 
          || 'U*' 
          || '00200*' 
          || LPAD (ln_isa_seq_num, 9, '0') 
          || '*' 
          || '0*' 
          || lc_test_indicator 
          || '*~\';            
        else                     
         lc_intchg_cntrl :=
               'ISA*'
            || '00*'
            || '          *'
            || '00*'
            || '          *'
            || '08*'
            || RPAD (SUBSTR (lc_edi_sender_id, 1, 10), 15, ' ')
            || '*'
            || lc_edi_qualifier
            || '*'
            || RPAD (SUBSTR (lc_edi_id, 1, 15), 15, ' ')
            || '*'
            || TO_CHAR (SYSDATE, 'YYMMDD')
            || '*'
            || TO_CHAR (SYSDATE, 'HH24MI')
            || '*'
            || 'U*'
            || '00401*'
            || LPAD (ln_isa_seq_num, 9, '0')
            || '*'
            || '0*'
            || lc_test_indicator
            || '*~\';
        END IF;
      ELSE
---------------------------------------------------------------------
-- NOn- Garishment records need to have a ~ At the end of the records
-- ISA12 should be 00401, not 00400
-- and ISA 06 need RPAD with spaces for 15
---------------------------------------------------------------------
         lc_intchg_cntrl :=
               'ISA*'
            || '00*'
            || '          *'
            || '00*'
            || '          *'
            || '08*'
            || RPAD (SUBSTR (lc_edi_sender_id, 1, 10), 15, ' ')
            || '*'
            || lc_edi_qualifier
            || '*'
            || RPAD (SUBSTR (lc_edi_id, 1, 15), 15, ' ')
            || '*'
            || TO_CHAR (SYSDATE, 'YYMMDD')
            || '*'
            || TO_CHAR (SYSDATE, 'HH24MI')
            || '*'
            || 'U*'
            || '00401*'
            || LPAD (ln_isa_seq_num, 9, '0')
            || '*'
            || '0*'
            || lc_test_indicator
            || '*~\';
      END IF;

------------------
--GS Header Record
------------------
      lc_current_step := ' Step: Intialize GS Header Record ';

      IF p_payment_type = 'JP MORGAN'
      -- Changes for defect 28958. 20th Mar 2014
      AND ln_site_count = 0
      -- End of changes for defect 28958. 20th Mar 2014
      THEN
         lc_func_grp_cntrl :=
               'GS*'
            || 'RA*'
            || ln_gs_edi_sender_id
            || '*'
            || lc_edi_id
            || '*'
            || TO_CHAR (SYSDATE, 'YYYYMMDD')
            || '*'
            || TO_CHAR (SYSDATE, 'HH24MISS  ')
            || '*'
            || '000000001*'
            || 'X'
            || '*'
            || '004010'
            || '\';
      ELSE
         lc_func_grp_cntrl :=
               'GS*'
            || 'RA*'
            || ln_gs_edi_sender_id
            || '*'
            || lc_edi_id
            || '*'
            || TO_CHAR (SYSDATE, 'YYYYMMDD')
            || '*'
            || TO_CHAR (SYSDATE, 'HH24MI')
            || '*'
            || '000000001*'
            || 'X'
            || '*'
            || '004010'
            || '\';
      END IF;

      ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
------------------
--ST Header Record
------------------
      lc_current_step := ' Step: Intialize ST Header Record ';
      lc_trans_set_cntrl :=
              'ST*' || '820*' || LPAD (lc_st_cntrl_num               -- global
                                                      ,
                                       9, '0') || '\';
      ln_se_rec_cnt := ln_se_rec_cnt + 1;
      ln_ge_rec_cnt := ln_ge_rec_cnt + 1;

------------------------------
-- Get Summary amount total
------------------------------
      IF p_payment_type = 'GARNSH'
      THEN
-----------------------------
-- Granishment AMOUNT SUMMARY
-----------------------------
         lc_current_step := ' Step: Granishment AMOUNT SUMMARY ';

         SELECT SUM (NVL (aida.amount, 0.00))
           INTO ln_pay_tot_amt
           FROM iby_payments_all iba,
                iby_docs_payable_all idp,
                ap_invoices_all aia,
                ap_invoice_distributions_all aida
          WHERE iba.payment_id = p_payment_id
            AND idp.payment_id = iba.payment_id
            AND aia.invoice_id = idp.calling_app_doc_unique_ref2
            AND aida.invoice_id = aia.invoice_id
            AND idp.document_status = 'PAYMENT_CREATED';

         fnd_file.put_line (fnd_file.LOG,
                            'Granisment AMOUNT SUMMARY' || p_vendor_id
                           );
      ELSIF p_payment_type IN ('AMEX', 'JP MORGAN')
      THEN
         SELECT NVL (SUM (iba.payment_amount), 0)
           INTO ln_pay_tot_amt
           FROM iby_payments_all iba
          WHERE iba.payment_id = p_payment_id;

         fnd_file.put_line (fnd_file.LOG,
                            'AMEX AMOUNT SUMMARY' || p_vendor_id);
      ELSE
------------------------
-- VENDOR AMOUNT SUMMARY
------------------------
         lc_current_step := ' Step:  VENDOR AMOUNT SUMMARY ';

         SELECT SUM ((NVL (idp.payment_amount, 0)))
           INTO ln_pay_tot_amt
           FROM iby_payments_all iba,
                iby_docs_payable_all idp,
                ap_invoices_all aia
          WHERE iba.payment_id = p_payment_id
            AND idp.payment_id = iba.payment_id
            AND aia.invoice_id = idp.calling_app_doc_unique_ref2
            AND idp.document_status = 'PAYMENT_CREATED';

         fnd_file.put_line (fnd_file.LOG,
                            'VENDOR AMOUNT SUMMARY' || p_vendor_id
                           );
      END IF;

---------------------------
--Create BPR Header Record
---------------------------
      lc_current_step := ' Step:  Creating BPR Header Record ';
      lc_beg_pay_order :=
            'BPR*'
         || 'C*'
         || RTRIM (LTRIM (TO_CHAR (SUBSTR (NVL (ln_pay_tot_amt, 0), 1, 18),
                                   '999999999999999.99'
                                  )
                         )
                  )
         || '*C'
         || '*ACH*CTX*01*'
         || lc_bank_routing_num
         || '*DA*'
         || lc_bank_account_num
         || '*'
         || ln_edi_duns_id
         || '**'
         || '01*'
         || lc_rec_dfi_bank_id
         || '*DA*'
         || lc_rec_dfi_bank_acct
         || '\';

      IF p_payment_type = 'JP MORGAN'
      THEN
         lc_beg_pay_order :=
               'BPR*'
            || 'C*'
            || RTRIM (LTRIM (TO_CHAR (SUBSTR (NVL (ln_pay_tot_amt, 0), 1, 18),
                                      '999999999999999.99'
                                     )
                            )
                     )
            || '*C'
            || '*ACH*CTX*01*'
            || lc_bank_routing_num
            || '*DA*'
            || lc_bank_account_num
            || '*'
            || ln_edi_duns_id
            || '**'
            || '01*'
            || lc_rec_dfi_bank_id
            || '*DA*'
            || lc_rec_dfi_bank_acct;

            -- Changes for Defect 28958. 20th Mar 2014
            IF ln_site_count = 0 THEN
                lc_beg_pay_order := lc_beg_pay_order || '*' || TO_CHAR (SYSDATE, 'YYYYMMDD') || '\';
            ELSE
                lc_beg_pay_order := lc_beg_pay_order || '\';
            END IF;
            -- End of changes for Defect 28958. 20th Mar 2014
      END IF;

      ln_se_rec_cnt := ln_se_rec_cnt + 1;
      ln_ge_rec_cnt := ln_ge_rec_cnt + 1;

-------------------------------------------------------------------
-- Both the AMEX and the Vendor records require a
-- additional TRN,REF,N1,ENT Records added after the BPR record
-------------------------------------------------------------------
      IF p_payment_type <> 'GARNSH'
      THEN
---------------------------
-- Create TRN Header Record
---------------------------
         IF p_payment_type <> 'JP MORGAN'
            -- Changes for defect 28958
            OR (p_payment_type = 'JP MORGAN' AND ln_site_count > 0)
            -- End of Changes for defect 28958
         THEN
            lc_current_step := ' Step:  Creating TRN Header Record ';
            lc_trn_hdr_rec := 'TRN*1*' || ln_check_number        --was global
                              || '\';
            ln_se_rec_cnt := ln_se_rec_cnt + 1;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
---------------------------
-- Create REF Header Record
---------------------------
            lc_current_step := ' Step:  Creating REF Header Record ';
            lc_ref_hdr_rec :=
                       'REF*BT*' || TO_CHAR (SYSDATE, 'YYYYMMDDHH24MI')
                       || '\';
            ln_se_rec_cnt := ln_se_rec_cnt + 1;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
         END IF;

         BEGIN
            SELECT vendor_name
              INTO lc_vendor_name
              FROM ap_suppliers
             WHERE vendor_id = p_vendor_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_vendor_name := '';
         END;

---------------------------
-- Create N1PE Header Record
---------------------------
         lc_current_step := ' Step:  Creating N1PE Header Record ';

         IF p_payment_type = 'AMEX'
         THEN
            lc_ref_hdr_rec := lc_ref_hdr_rec || 'REF*ZZ*LOAD 66033\';
            lc_n1pe_hdr_rec := 'N1*PE*AMEX\';
         ELSIF p_payment_type = 'JP MORGAN'
         THEN
            -- Changes for defect 28958
            IF ln_site_count   = 0 THEN
                lc_n1pe_hdr_rec := 'N1*PE*JPMORGAN COMMERCIAL CARD\';
            ELSE
                lc_n1pe_hdr_rec := 'N1*PE*' || lc_vendor_name || '\';
            END IF;
            -- End of Changes for defect 28958
         ELSE
            lc_n1pe_hdr_rec := 'N1*PE*' || lc_vendor_name || '\';
         END IF;

         ln_se_rec_cnt := ln_se_rec_cnt + 1;
         ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
---------------------------
-- Create N1PR Header Record
---------------------------
         lc_current_step := ' Step:  Creating N1PR Header Record ';
         lc_n1pr_hdr_rec := 'N1*PR*OFFICE DEPOT\';
         ln_se_rec_cnt := ln_se_rec_cnt + 1;
         ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
---------------------------
-- Create ENT Header Record
---------------------------
         lc_current_step := ' Step:  Creating ENT Header Record ';

         IF p_payment_type = 'AMEX'
         THEN
            lc_ent_hdr_rec := 'ENT*6033\';
            lc_beg_pay_order :=
                  lc_beg_pay_order
               || lc_trn_hdr_rec
               || lc_ref_hdr_rec
               || lc_n1pr_hdr_rec
               || lc_n1pe_hdr_rec
               || lc_ent_hdr_rec;
         ELSE
            lc_ent_hdr_rec := 'ENT*1\';
            lc_beg_pay_order :=
                  lc_beg_pay_order
               || lc_trn_hdr_rec
               || lc_ref_hdr_rec
               || lc_n1pr_hdr_rec
               || lc_n1pe_hdr_rec
               || lc_ent_hdr_rec;
            ln_se_rec_cnt := ln_se_rec_cnt + 1;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
         END IF;
      END IF;

----------------------------------------------------------------------
-- Create one large string for all the Functional group header records
-- ISA, GS, ST will be created at this point.
----------------------------------------------------------------------
      lc_current_step := ' Step:  Functional group header records ';
      lc_print_line_tot :=
            lc_intchg_cntrl
         || lc_func_grp_cntrl
         || lc_trans_set_cntrl
         || lc_beg_pay_order;
      ln_rec_length := NVL (LENGTH (lc_print_line_tot), 0);
-------------------------------------------------------------------------
-- LOOP to write 705 records and make sure that they do not continue past
-- column defined in ln_wrap_length
-------------------------------------------------------------------------
      lc_current_step := ' Step: LOOP to write 705 records ';

      WHILE ln_rec_length > ln_wrap_length
      LOOP
-------------------------
-- Increment Record Counts
-------------------------
         ln_rec_seq_num := ln_rec_seq_num + 1;
-------------------------------------------------------
-- Write 705 Functional group header recordsRecord with
-- appended record seq and detail counter
-------------------------------------------------------
         lc_print_line :=
               '705'
            || SUBSTR (lc_print_line_tot, 1, ln_wrap_length)
            || LPAD (ln_rec_seq_num, 4, '0')
            || LPAD (ln_detail_counter                               -- global
                                      ,
                     7, '0');

         IF lc_addenda IS NULL
         THEN
            lc_addenda := lc_print_line;
         ELSE
            lc_addenda := lc_addenda || CHR (13) || lc_print_line;
         END IF;

         ----UTL_FILE.put_line (g_filehandle, lc_print_line);
         ln_batch_total_cnt := ln_batch_total_cnt + 1;
         ln_total_record_cnt := ln_total_record_cnt + 1;
         ln_file_addenda_cnt := ln_file_addenda_cnt + 1;
-----------------------------------------------
-- Get remainder of String for wrapping records
-----------------------------------------------
         lc_print_line_tot :=
               SUBSTR (lc_print_line_tot, (ln_wrap_length + 1), ln_rec_length);
         ln_rec_length := LENGTH (lc_print_line_tot);
      END LOOP;

      fnd_file.put_line (fnd_file.LOG,
                         'p_payment_type   1  - > ' || p_payment_type
                        );
----------------------------------------------------
-- Cursor to create 705 DED records for Garnishments
----------------------------------------------------
      lc_current_step := ' Step:  Cursor to create 705 DED Garnishments ';

      IF p_payment_type = 'GARNSH'
      THEN
         lc_current_step := 'Step: OPENING garnish_details_cursor';

         OPEN garnish_details_cursor;

         LOOP
            FETCH garnish_details_cursor
             INTO lc_entrydetail2;

            EXIT WHEN garnish_details_cursor%NOTFOUND;
            ln_se_rec_cnt := ln_se_rec_cnt + 1;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
            ln_batch_total_cnt := ln_batch_total_cnt + 1;
------------------------------------------------------
-- Create one large string for all the 705 DED Details
------------------------------------------------------
            lc_current_step :=
               ' Step:  Create one large string for '
               || 'all the 705 Garnish';
            lc_print_line_tot := lc_print_line_tot || lc_entrydetail2;
            ln_rec_length := NVL (LENGTH (lc_print_line_tot), 0);

            IF ln_rec_length > ln_wrap_length
            THEN
-------------------------
-- Increment Record Count
-------------------------
               ln_rec_seq_num := ln_rec_seq_num + 1;
-----------------------------------
-- Write 705 Record for Garnishment
-----------------------------------
               lc_current_step := ' Step:  Write 705 Record for Garnishment ';
               lc_print_line :=
                     '705'
                  || SUBSTR (lc_print_line_tot, 1, ln_wrap_length)
                  || LPAD (ln_rec_seq_num, 4, '0')
                  || LPAD (lc_detail_counter, 7, '0');

               IF lc_addenda IS NULL
               THEN
                  lc_addenda := lc_print_line;
               ELSE
                  lc_addenda := lc_addenda || CHR (13) || lc_print_line;
               END IF;

               ln_batch_total_cnt := ln_batch_total_cnt + 1;
               ln_total_record_cnt := ln_total_record_cnt + 1;
               ln_file_addenda_cnt := ln_file_addenda_cnt + 1;
-----------------------------------------------
-- Get remainder of String for wrapping records
-----------------------------------------------
               lc_current_step :=
                            ' Step: Get remainder of wrapping Garish records ';
               lc_print_line_tot :=
                  SUBSTR (lc_print_line_tot,
                          (ln_wrap_length + 1),
                          ln_rec_length
                         );
               ln_rec_length := LENGTH (lc_print_line_tot);
            END IF;
         END LOOP;

         CLOSE garnish_details_cursor;
      END IF;

--------------------------------------------
-- Cursor to create 705 DED records for AMEX
--------------------------------------------
      fnd_file.put_line (fnd_file.LOG,
                         'p_payment_type   2  - > ' || p_payment_type
                        );

      IF p_payment_type = 'AMEX'
      THEN
         lc_current_step := 'Step: OPENING amex_details_cursor';
         fnd_file.put_line (fnd_file.LOG,
                               'Step: OPENING amex_details_cursor -->  '
                            || p_payment_type
                           );

         OPEN amex_details_cursor;

         LOOP
            FETCH amex_details_cursor
             INTO lc_entrydetail2;

            EXIT WHEN amex_details_cursor%NOTFOUND;
            ln_se_rec_cnt := ln_se_rec_cnt + 1;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
            ln_batch_total_cnt := ln_batch_total_cnt + 1;
------------------------------------------------------------------
-- Added Two to the counter for the trailer REF records
------------------------------------------------------------------
            ln_se_rec_cnt := ln_se_rec_cnt + 2;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 2;
--------------------------------------------------------------
-- Create one large string for all the 705 DED Details
--------------------------------------------------------------
            lc_current_step :=
                       ' Step:  Create one large string for all the 705 AMEX';
            lc_print_line_tot := lc_print_line_tot || lc_entrydetail2;
            ln_rec_length := NVL (LENGTH (lc_print_line_tot), 0);

            IF ln_rec_length > ln_wrap_length
            THEN
-------------------------
-- Increment Record Count
-------------------------
               ln_rec_seq_num := ln_rec_seq_num + 1;
-------------------
-- Write 705 Record
-------------------
               lc_print_line :=
                     '705'
                  || SUBSTR (lc_print_line_tot, 1, ln_wrap_length)
                  || LPAD (ln_rec_seq_num, 4, '0')
                  || LPAD (ln_detail_counter, 7, '0');

               IF lc_addenda IS NULL
               THEN
                  lc_addenda := lc_print_line;
               ELSE
                  lc_addenda := lc_addenda || CHR (13) || lc_print_line;
               END IF;

               ln_batch_total_cnt := ln_batch_total_cnt + 1;
               ln_total_record_cnt := ln_total_record_cnt + 1;
               ln_file_addenda_cnt := ln_file_addenda_cnt + 1;
-----------------------------------------------
-- Get remainder of String for wrapping records
-----------------------------------------------
               lc_print_line_tot :=
                  SUBSTR (lc_print_line_tot,
                          (ln_wrap_length + 1),
                          ln_rec_length
                         );
               ln_rec_length := LENGTH (lc_print_line_tot);
            END IF;
         END LOOP;

         CLOSE amex_details_cursor;
      END IF;

--------------------------------------------
-- Cursor to create 705 DED records for JP MORGAN
--------------------------------------------
      IF p_payment_type = 'JP MORGAN'
      THEN
         lc_current_step := 'Step: OPENING jpm_details_cursor';

         OPEN jpm_details_cursor;

         LOOP
            FETCH jpm_details_cursor
-- Changes for the private get_dec_ccno. V2.5
             --INTO lc_entrydetail2;
            INTO lc_jpm_cc_attribute5, lc_jpm_cc_attribute4,
                 ln_jpm_payment_amount, lc_jpm_invoice_num;

            EXIT WHEN jpm_details_cursor%NOTFOUND;

            lc_entrydetail2 := 'RMR'
                             || '*'
                             || 'IV'
                             || '*'
                             -- Start: Added for decryption of the data
                             || get_dec_ccno( lc_jpm_cc_attribute5 -- identifier
                                             ,lc_jpm_cc_attribute4 -- lc_encrypted_data
                                            )
                             -- End: added for decryption of the data							  
                             || '**'
                             || LTRIM (TO_CHAR (NVL (ln_jpm_payment_amount, 0), '999999999.99') )
                             || '\'
                             || 'REF*1Z*'
                             || lc_jpm_invoice_num
                             || '\';

-- End of changes V2.5

            ln_se_rec_cnt := ln_se_rec_cnt + 1;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
            ln_batch_total_cnt := ln_batch_total_cnt + 1;
------------------------------------------------------------------
--Two to the counter for the trailer REF records
------------------------------------------------------------------
-- V2.6, instead of 2 trailer REF, it will be 1 in case of JP MORGAN
            ln_se_rec_cnt := ln_se_rec_cnt + 1;                          --2;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;                          --2;
--------------------------------------------------------------
-- Create one large string for all the 705 DED Details
--------------------------------------------------------------
            lc_current_step :=
                  ' Step:  Create one large string for all the 705 JP Morgan';
            lc_print_line_tot := lc_print_line_tot || lc_entrydetail2;
            ln_rec_length := NVL (LENGTH (lc_print_line_tot), 0);

            IF ln_rec_length > ln_wrap_length
            THEN
-------------------------
-- Increment Record Count
-------------------------
               ln_rec_seq_num := ln_rec_seq_num + 1;
-------------------
-- Write 705 Record
-------------------
               lc_print_line :=
                     '705'
                  || SUBSTR (lc_print_line_tot, 1, ln_wrap_length)
                  || LPAD (ln_rec_seq_num, 4, '0')
                  || LPAD (ln_detail_counter, 7, '0');

               IF lc_addenda IS NULL
               THEN
                  lc_addenda := lc_print_line;
               ELSE
                  lc_addenda := lc_addenda || CHR (13) || lc_print_line;
               END IF;

               ln_batch_total_cnt := ln_batch_total_cnt + 1;
               ln_total_record_cnt := ln_total_record_cnt + 1;
               ln_file_addenda_cnt := ln_file_addenda_cnt + 1;
-----------------------------------------------
-- Get remainder of String for wrapping records
-----------------------------------------------
               lc_print_line_tot :=
                  SUBSTR (lc_print_line_tot,
                          (ln_wrap_length + 1),
                          ln_rec_length
                         );
               ln_rec_length := LENGTH (lc_print_line_tot);
            END IF;
         END LOOP;
      END IF;

------------------------------------------------
-- Cursor to create 705 DED records for Vendors
------------------------------------------------
      IF p_payment_type = 'VENDOR'
            -- Changes for defect 28958
            OR (p_payment_type = 'JP MORGAN' AND ln_site_count > 0)
            -- End of Changes for defect 28958
      THEN
         lc_current_step := 'Step: OPENING vendor_details_cursor';

         OPEN vendor_details_cursor;

         LOOP
            FETCH vendor_details_cursor
             INTO ln_invoice_num, ln_payment_amount, ln_invoice_amount,
                  ln_discount_amount, lc_invoice_description
                  ,ld_pcard_inv_date;

            EXIT WHEN vendor_details_cursor%NOTFOUND;
            ln_se_rec_cnt := ln_se_rec_cnt + 1;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;

----------------------------------------------------
-- Credit memos for vendor RMR records need to
-- contain a CM in the RMR1 record
----------------------------------------------------
            IF ln_payment_amount < 0
            THEN
               lc_rmr_code := 'CM';
            ELSE
               lc_rmr_code := 'IV';
            END IF;

-----------------------------------------------
-- statement to create
-- additional REF record if invoice discription
-- exists.
-----------------------------------------------
            IF lc_invoice_description IS NULL
            THEN
               --V2.3, Changed the description
               lc_pcard_inv_desc := null;
               if ln_site_count > 0 then -- Added If else
                       begin
                                SELECT 'REF*ZZ*'||val.target_value1   
                 INTO lc_pcard_inv_desc
                 FROM AP_SUPPLIER_SITES_all assa
                      ,ap_suppliers asu
                      ,xx_fin_translatedefinition def
                      ,xx_fin_translatevalues val
                 WHERE def.translate_id = val.translate_id
                 AND def.translation_name = 'XX_PCARD_DETAILS'
                 AND SYSDATE BETWEEN def.start_date_active
                                 AND NVL (def.end_date_active, SYSDATE + 1)
                 AND SYSDATE BETWEEN val.start_date_active
                                 AND NVL (val.end_date_active, SYSDATE + 1)
                 AND def.enabled_flag = 'Y'
                 AND val.enabled_flag = 'Y'
                 AND asu.vendor_id = assa.vendor_id
                 AND asu.vendor_id = p_vendor_id
                 AND asu.segment1 = val.target_value2
                 AND assa.VENDOR_SITE_ID = P_VENDOR_SITE_ID
                 AND assa.VENDOR_SITE_CODE = val.target_value3;
                 exception
                 when others then
                      null;
                end;
               lc_pcard_inv_desc:=lc_pcard_inv_desc||to_char(ld_pcard_inv_date,'MMYY')||'*P-Card '||to_char(ld_pcard_inv_date,'MM/YY')||' Statement\';
               
                  lc_entrydetail2 :=
                     'RMR*'
                  || lc_rmr_code
                  || '*'
                  || ln_invoice_num
                  || '**'
                  || ln_payment_amount
                  || '*'
                  || ln_invoice_amount
                  || '*'
                  || ln_discount_amount
                  || '\'
                  || lc_pcard_inv_desc;
               
               else             
              
              
               lc_entrydetail2 :=
                     'RMR*'
                  || lc_rmr_code
                  || '*'
                  || ln_invoice_num
                  || '**'
                  || ln_payment_amount
                  || '*'
                  || ln_invoice_amount
                  || '*'
                  || ln_discount_amount
                  || '\'
                  || 'REF*ZZ*'
                  || ln_invoice_num
                   || '*\';                  
                  end if; --V2.3
            ELSE
               lc_entrydetail2 :=
                     'RMR*'
                  || lc_rmr_code
                  || '*'
                  || ln_invoice_num
                  || '**'
                  || ln_payment_amount
                  || '*'
                  || ln_invoice_amount
                  || '*'
                  || ln_discount_amount
                  || '\'
                  -- Additional REF Record
                  || 'REF*ZZ*'
                  || ln_invoice_num
                  || '*'
                  || lc_invoice_description
                  || '\';
               ln_se_rec_cnt := ln_se_rec_cnt + 1;
               ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
            END IF;

--------------------------------------------------------------
-- Create one large string for all the 705 DED Vendor Details
--------------------------------------------------------------
            lc_current_step :=
               ' Step:  Create one large string for ' || 'all the 705 Vendors';
            lc_print_line_tot := lc_print_line_tot || lc_entrydetail2;
            ln_rec_length := NVL (LENGTH (lc_print_line_tot), 0);

            IF ln_rec_length > ln_wrap_length
            THEN
-------------------------
-- Increment Record Count
-------------------------
               ln_rec_seq_num := ln_rec_seq_num + 1;
---------------
-- Write Record
---------------
               lc_print_line :=
                     '705'
                  || SUBSTR (lc_print_line_tot, 1, ln_wrap_length)
                  || LPAD (ln_rec_seq_num, 4, '0')
                  || LPAD (ln_detail_counter, 7, '0');
               lc_addenda := lc_addenda || CHR (13) || lc_print_line;
               ln_batch_total_cnt := ln_batch_total_cnt + 1;
               ln_total_record_cnt := ln_total_record_cnt + 1;
               ln_file_addenda_cnt := ln_file_addenda_cnt + 1;
-----------------------------------------------
-- Get remainder of String for wrapping records
-----------------------------------------------
               lc_print_line_tot :=
                  SUBSTR (lc_print_line_tot,
                          (ln_wrap_length + 1),
                          ln_rec_length
                         );
               ln_rec_length := LENGTH (lc_print_line_tot);
            END IF;
         END LOOP;

         CLOSE vendor_details_cursor;
      END IF;

      lc_current_step := 'Step: Intialize the 705 trailer records';
--------------------------------------------------------------------------
-- Intialize the 705 trailer records Transaction Set Trailer Summary (SE)
--------------------------------------------------------------------------
      ln_se_rec_cnt := ln_se_rec_cnt + 1;
      ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
      lc_se_tran_set_trail :=
            'SE'
         || '*'
         || SUBSTR (ln_se_rec_cnt, 1, 6)
         || '*'
         || LPAD (lc_st_cntrl_num, 9, '0')
         || '\';
---------------------------------------
-- Transaction Set Trailer Summary (GE)
---------------------------------------
      ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
      lc_ge_tran_set_trail := 'GE' || '*' || '1' || '*' || '000000001' || '\';
---------------------------------------
-- Transaction Set Trailer Summary (IEA)
---------------------------------------
      lc_lea_cntrl_trailer :=
             'IEA' || '*' || '1' || '*' || LPAD (ln_isa_seq_num, 9, '0')
             || '\';
--------------------------------------------------------------
-- Concatenate remainder to DED records to the trailer records
--------------------------------------------------------------
      lc_print_line_tot :=
            lc_print_line_tot
         || lc_se_tran_set_trail
         || lc_ge_tran_set_trail
         || lc_lea_cntrl_trailer;
      ln_rec_length := NVL (LENGTH (lc_print_line_tot), 0);

      WHILE ln_rec_length > ln_wrap_length
      LOOP
-------------------------
-- Increment Record Count
-------------------------
         ln_rec_seq_num := ln_rec_seq_num + 1;
---------------
-- Write Record
---------------
         lc_print_line :=
               '705'
            || SUBSTR (lc_print_line_tot, 1, ln_wrap_length)
            || LPAD (ln_rec_seq_num, 4, '0')
            || LPAD (ln_detail_counter, 7, '0');
         lc_addenda := lc_addenda || CHR (13) || lc_print_line;
         --UTL_FILE.put_line (g_filehandle, lc_print_line);
         ln_batch_total_cnt := ln_batch_total_cnt + 1;
         ln_total_record_cnt := ln_total_record_cnt + 1;
         ln_file_addenda_cnt := ln_file_addenda_cnt + 1;
-----------------------------------------------
-- Get remainder of String for wrapping records
-----------------------------------------------
         lc_print_line_tot :=
               SUBSTR (lc_print_line_tot, (ln_wrap_length + 1), ln_rec_length);
         ln_rec_length := LENGTH (lc_print_line_tot);
      END LOOP;

-----------------------------------------------
-- Get remainder of String for wrapping records
-----------------------------------------------
      ln_rec_length := LENGTH (lc_print_line_tot);
      lc_print_line_tot := SUBSTR (lc_print_line_tot, 1, ln_rec_length);

      IF ln_rec_length <= ln_wrap_length AND NVL (ln_rec_length, 0) <> 0
      THEN
-------------------------
-- Increment Record Count
-------------------------
         ln_rec_seq_num := ln_rec_seq_num + 1;

         IF ln_rec_length = ln_wrap_length
         THEN
            lc_return_addend :=
                  '705'
               || lc_print_line_tot
               || LPAD (ln_rec_seq_num, 4, '0')
               || LPAD (ln_batch_count, 7, '0');
            ln_batch_total_cnt := ln_batch_total_cnt + 1;
            ln_total_record_cnt := ln_total_record_cnt + 1;
            ln_file_addenda_cnt := ln_file_addenda_cnt + 1;
         ELSE
            lc_return_addend :=
                  '705'
               || RPAD (lc_print_line_tot,
                        ((ln_wrap_length - ln_rec_length) + ln_rec_length
                        ),
                        ' '
                       )
               || LPAD (ln_rec_seq_num, 4, '0')
               || LPAD (ln_batch_count, 7, '0');
            ln_batch_total_cnt := ln_batch_total_cnt + 1;
            ln_total_record_cnt := ln_total_record_cnt + 1;
            ln_file_addenda_cnt := ln_file_addenda_cnt + 1;
         END IF;

         x_addenda_rec_cnt := ln_file_addenda_cnt;
         RETURN lc_addenda || CHR (13) || lc_return_addend;
      -- returns the addend record
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Error:  xx_ap_nachaboa_eft_pkg' || SQLERRM ()
                           );
   END payment_details;

   /*--------------------------------------------------------------
   | function : eft_file_move
   |
   |
   ---------------------------------------------------------------*/
   FUNCTION eft_file_move (p_sub_guid IN RAW, p_event IN OUT wf_event_t)
      RETURN VARCHAR2
   IS
      l_event_data           CLOB;
      ln_request_id          NUMBER;
      ln_request_id2         NUMBER;
      ln_request_id3         NUMBER;
      lc_event_name          VARCHAR2 (100);
      --lc_status              VARCHAR2 (100)  := 'SUCCESS';
      lc_err_msg             VARCHAR2 (1000);
      lc_prog_code           VARCHAR2 (100)  := 'XXCOMENPTFILE';
      lc_appl_name           VARCHAR2 (100)  := 'XXFIN';
      lc_out_file_name       VARCHAR2 (1000);
      lc_short_nm            VARCHAR2 (1000);
      ln_user_id             NUMBER;
      ln_resp_id             NUMBER;
      ln_resp_appl_id        NUMBER;
      lc_output_file_dest    VARCHAR2 (1000);
      lc_phase               VARCHAR2 (50);
      lc_status              VARCHAR2 (50);
      lc_dev_phase           VARCHAR2 (50);
      lc_dev_status          VARCHAR2 (50);
      lc_message             VARCHAR2 (1000);
      lb_result              BOOLEAN;
      lc_key                 VARCHAR2 (100);
      lc_encrypt_file_flag   VARCHAR2 (1);
      lc_temp_name           VARCHAR2 (45);
      lc_pay_instr_id        NUMBER;

-- ------------------------------------------------
-- Cursor to get output file name
-- ------------------------------------------------
      CURSOR c_req_info (cp_request_id NUMBER)
      IS
         SELECT fcr.outfile_name, fcp.concurrent_program_name,
                fcr.requested_by, fcr.responsibility_id,
                fcr.responsibility_application_id
           FROM fnd_concurrent_requests fcr,
                fnd_concurrent_programs fcp
          WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
            AND fcr.program_application_id = fcp.application_id
            AND fcp.concurrent_program_name = 'IBY_FD_PAYMENT_FORMAT_TEXT'
            AND fcr.request_id = cp_request_id
            AND EXISTS (
                   SELECT 1
                     FROM iby_payments_all ipa
                    WHERE ipa.payment_instruction_id = fcr.argument1
                      --AND ipa.payment_profile_sys_name = 'OD_US_EFT_PMT_PROFILE' --Commented #PPP
                      AND ipa.payment_profile_sys_name = 'EFT_PPP' --Added #PPP
                      AND ipa.payment_status = 'FORMATTED');
   BEGIN
      l_event_data := p_event.geteventdata ();
      lc_event_name := p_event.geteventname ();

      IF (p_event.geteventname () =
                                'oracle.apps.fnd.concurrent.request.completed'
         )
      THEN
         ln_request_id :=
                      TO_NUMBER (p_event.getvalueforparameter ('REQUEST_ID'));
      END IF;

      -- Get the details of the Format Payment Instruction program
      OPEN c_req_info (ln_request_id);

      FETCH c_req_info
       INTO lc_out_file_name, lc_short_nm, ln_user_id, ln_resp_id,
            ln_resp_appl_id;

      CLOSE c_req_info;

-- Changes for defect 28592
-- The File Copy should be submitted only when this event is triggered for EFT_PPP.
-- If the cursor returns data, that means it is for EFT_PPP.

   IF lc_out_file_name IS NOT NULL THEN

   -- --------------------------------------------------------
   -- Derive the template name from the Payment Process request Name
   -- based on the assumption that the request name will start with 
   -- payment process template name as prefix, and will contain EFT as initial
   -- -----------------------------------------------------------------------     
      
    BEGIN
      SELECT ipi.payment_instruction_id,
              SUBSTR(ipi.PAY_ADMIN_ASSIGNED_REF_CODE,INSTR(ipi.PAY_ADMIN_ASSIGNED_REF_CODE,'EFT_',1),INSTR(ipi.PAY_ADMIN_ASSIGNED_REF_CODE,'_',1,2))
        INTO lc_pay_instr_id
           , lc_temp_name
        FROM iby_pay_instructions_all ipi
           , fnd_concurrent_requests  fcr
       WHERE fcr.request_id = ln_request_id
         AND ipi.payment_instruction_id = fcr.argument1;
       
       IF lc_temp_name IS NULL THEN
         lc_temp_name := lc_pay_instr_id||'_';
       END IF;
       
    EXCEPTION
      WHEN OTHERS THEN 
        lc_temp_name := '_';    
    END;

-- ---------------------------------------
-- Associate timestamp
-- ---------------------------------------
      SELECT REPLACE (SUBSTR (lc_out_file_name,
                              INSTR (lc_out_file_name, '/', -1) + 1
                             ),
                      ln_request_id || '.out',
                      lc_temp_name||TO_CHAR (SYSDATE, 'MMDDYYYYHH24MISS') || '.txt'
                     )
        INTO lc_output_file_dest
        FROM DUAL;

      fnd_global.apps_initialize (ln_user_id, ln_resp_id,
                                       ln_resp_appl_id);
-- --------------------------------------------------------------------------------------------
-- If it was submitted for Check, then get the default values for Check FTP program
-- --------------------------------------------------------------------------------------------
      ln_request_id2 :=
         fnd_request.submit_request (lc_appl_name,
                                     'XXCOMFILCOPY',
                                     '',
                                     '01-OCT-04 00:00:00',
                                     FALSE,
                                     lc_out_file_name,
                                        '$XXFIN_DATA/ftp/out/nacha/'
                                     || lc_output_file_dest,
                                     NULL,
                                     NULL,
                                     'N',--'Y', LNS2 Testing
                                     NULL
                                    );
      COMMIT;
	  --Below logic added for defect# 41209
	  IF ln_request_id2 > 0 THEN
      LOOP
      lb_result :=
         fnd_concurrent.wait_for_request (ln_request_id2,
                                          10,
                                          200,
                                          lc_phase,
                                          lc_status,
                                          lc_dev_phase,
                                          lc_dev_status,
                                          lc_message
                                         );
		EXIT
        WHEN UPPER (lc_phase) = 'COMPLETED' OR UPPER (lc_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
      END LOOP;
	  END IF;

--
       --------------------------------------------
       --2.5 Encrypt the file and place in same directory
       --------------------------------------------
       -- THE XXCOMENPTFILE concurrent program will encrypt the  file in the
       -- directory  XXFIN/ftp/out/nacha directory where BPEL is monitoring
       -- for the file to arrive.
      IF lc_status != 'Normal'
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Error:  File is not copied ' || SQLERRM ()
                           );
      ELSE
         BEGIN
            SELECT xftv.target_value1, xftv.target_value2
              INTO lc_key, lc_encrypt_file_flag
              FROM xx_fin_translatedefinition xftd,
                   xx_fin_translatevalues xftv
             WHERE xftv.translate_id = xftd.translate_id
               AND SYSDATE BETWEEN xftv.start_date_active
                               AND NVL (xftv.end_date_active, SYSDATE + 1)
               AND SYSDATE BETWEEN xftd.start_date_active
                               AND NVL (xftd.end_date_active, SYSDATE + 1)
               AND xftv.source_value1 = 'I0438_BOA_EFT_EXP_EFT_NACHA'
               AND xftd.translation_name = 'OD_PGP_KEYS'
               AND xftv.enabled_flag = 'Y'
               AND xftd.enabled_flag = 'Y';

            IF (lc_key IS NOT NULL AND NVL (lc_encrypt_file_flag, 'N') = 'Y')
            THEN
               ln_request_id3 :=
                  fnd_request.submit_request
                               (application      => lc_appl_name,
                                program          => 'XXCOMENPTFILE',
                                argument1        =>    '$XXFIN_DATA/ftp/out/nacha/'
                                                    || lc_output_file_dest,
                                argument2        => lc_key,
                                argument3        => 'Y'
                               );
               COMMIT;
			   --Below logic added for defect# 41209
	           IF ln_request_id3 > 0 THEN
               LOOP
               lb_result :=
                  fnd_concurrent.wait_for_request (ln_request_id3,
                                                   10,
                                                   200,
                                                   lc_phase,
                                                   lc_status,
                                                   lc_dev_phase,
                                                   lc_dev_status,
                                                   lc_message
                                                  );
			      EXIT
                    WHEN UPPER (lc_phase) = 'COMPLETED' OR UPPER (lc_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
               END LOOP;
			   END IF;

               IF lc_status != 'Normal'
               THEN
                  fnd_file.put_line (fnd_file.LOG,
                                        'Error:  File is not Encrypted '
                                     || SQLERRM ()
                                    );
               ELSE
                  fnd_file.put_line (fnd_file.LOG, 'File is Encrypted ');
               END IF;
               

               
                
               
            END IF;
            
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                  'Key not found ' || SQLERRM ()
                                 );
         END;
      END IF;

   END IF; -- lc_out_file_name IS NOT NULL. Changes for defect 28592.

      COMMIT;
      RETURN (lc_status);
   EXCEPTION
      WHEN OTHERS
      THEN
         lc_err_msg := SUBSTR (SQLERRM, 1, 2000);
         lc_status := 'ERROR';
         RETURN (lc_status);
   END eft_file_move;
END XX_AP_NACHABOA_EFT_PKG;
/
