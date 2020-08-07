create or replace
PACKAGE BODY xx_ap_eftnachaboa_pkg
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |           Office Depot Organization                               |
-- +===================================================================+
-- | Name  : XX_AP_EFTNACHABOA_PKG                                     |
-- | Description      :  Package to format EFT NACHA file that will be |
-- |                     sent to Bank of America. This program replaces|
-- |                     XXAPXEFTNACHABOA.rpt                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  07-JUN-2008 P.Marco          Initial draft version       |
-- |1.0       07-JUL-2208 Sarat Uppalapati Defect# 8750                |
-- |1.1       15-JUL-2008 Sandeeep Pandhare Defect# 8932               |
-- |1.2       17-JUL-2008 P.Marco          Defect 6651: Both the AMEX  |
-- |                                       and the Vendor records      |
-- |                                       require a additional BPR,TRN|
-- |                                       ,REF,N1,ENT Records added   |
-- |                                        after the BPR record,      |
-- |                                       Added DUNS_ID to translation|
-- |                                       table, Default trailer recor|
-- |                                       d counters to '1'.          |
-- |1.3       28-AUG-2008 P.Marco      Defect 6650 removed space       |
-- |                                       BPR record                  |
-- |                                                                   |
-- |1.4       3-SEPT-2008 P.Marco     Defect 10693                     |
-- |1.5       5_SEPT-2008 P.MARCO     CR461 RMR record needs to        |
-- |                                      have dynamic CR Code to      |
-- |                                      handle credit menos          |
-- |                                                                   |
-- |1.6      10-Sept-2008 P.Marco         Defect 11003 : Multi-Site    |
-- |                                      Vendors have incorrect       |
-- |                                      addendas                     |
-- |                                                                   |
-- |1.7      21-Oct-2008  P.Marco         Defect 11953: EFT file is    |
-- |                                      missing Invoice Description  |
-- |                                                                   |
-- |1.8      22-MAY-2009  P.Marco         Defect 15436: Make Settlement|
-- |                                      site specific                |
-- |1.9      23-MAY-2009  P.Marco         Defect 15365: modified Where |
-- |                                      clause to include ok to pay  |
-- |                                      flag at the invoice level    |
-- |                                                                   |
-- |2.0      28-MAY-2009  P.Marco         Defect 15550 Added counters  |
-- |                                      to code to account for REF   |
-- |                                      records created by defect    |
-- |                                      11952                        |
-- |                                                                   |
-- |2.1      03-JUN-2009  P.Marco         Defect 15612 Modified AMEX   |
-- |                                      RMR Rec. change CM to 11 sec-|
-- |                                      ond amount should be dropped.|
-- |                                      Change to ENT record         |
-- |                                                                   |
-- |2.2       29-JUL-2009  P.Marco         Defect 561 removed some     |
-- |                                      changes from 15612 and added |
-- |                                      new REF for Load number      |
-- |                                                                   |
-- |2.3      20-AUG-2009  P.Marco         Defect 2133 Modified join    |
-- |                                      condition on AMEX RMR Cursor |
-- |                                      to join on  Vendor_site_code |
-- |2.4      31-Jan-2012  Gaurav Agarwal  Code modified for CR561      |
-- |2.4      13-Feb-2012  Gaurav Agarwal  Code modified for CR561      |
-- |2.5      28-Feb-2012  Deepti S        Defect#16679 - Encrypt File  |
-- |2.6      01-Mar-2012  Jay Gupta       Defect#17327                 |
-- |2.7      06-Mar-2012  Jay Gupta       Defect#17412                 |
-- |2.8      09-Mar-2012  Jay Gupta       Defect#17487                 |
-- |2.9      16-Mar-2012  Jay Gupta       Code issue for V2.5          |
-- |3.0      07-Aug-2012  Abdul Khan      Code fix for QC Defect 19757 |
-- |3.1      27-Oct-2015  Harvinder Rakhra Retrofit R12.2              |
-- |3.2      08-Mar-2017  Madhan Sanjeevi Encryption fail Defect#41209 |
-- +===================================================================+

   ---------------------
-- Global Variables
---------------------
   gc_bank_routing_num    ap_bank_branches.bank_num%TYPE;
   gc_bank_account_num    ap_bank_accounts.bank_account_num%TYPE;
   gc_rec_dfi_bank_id     ap_selected_invoice_checks.bank_num%TYPE;
   gc_rec_dfi_bank_acct   ap_selected_invoice_checks.bank_account_num%TYPE;
   gc_checkrun_name       ap_selected_invoice_checks.checkrun_name%TYPE;
   gc_vendor_name         ap_selected_invoice_checks.vendor_name%TYPE;
   gn_check_number        ap_selected_invoice_checks.check_number%TYPE;
   g_filehandle           UTL_FILE.file_type;
   -- gc_output_file       VARCHAR2 (20) := 'BOA_EFT_NACHA'; -- Defect 8750 removed
   gc_output_file         VARCHAR2 (100);
   gc_output_file_dest         VARCHAR2 (100);
---------------------------------------------------------------------------
-- Detail variables due to time contraints Several values have been added
-- to translation table due to time contraints in code delivery
---------------------------------------------------------------------------
   gc_edi_sender_id       xx_fin_translatevalues.source_value3%TYPE;
   -- '1592663954'
   gc_test_indicator      xx_fin_translatevalues.source_value4%TYPE;
   -- 'P' or Test='T'
   gn_gs_edi_sender_id    xx_fin_translatevalues.source_value5%TYPE;
   -- '6123410000'
   gc_file_id_modifier    xx_fin_translatevalues.source_value6%TYPE;
   -- 'A'
   gn_edi_duns_id         xx_fin_translatevalues.source_value7%TYPE;
   -- '3153531108'
   gc_edi_qualifier       VARCHAR2 (2);               -- Prod ='01'Test ='ZZ'
   gc_edi_id              VARCHAR2 (15);                 -- 'BANK OF AMERICA'
   gn_isa_seq_num         NUMBER                                         := 0;
   gc_st_cntrl_num        NUMBER                                         := 1;
   -- Always 1
   gc_current_step        VARCHAR2 (250);
   gn_batch_amt_tot       NUMBER                                         := 0;
   --Totals the credit amount of each batch
   gn_entry_hash_num      NUMBER                                         := 0;
   --Batch Trailer hash number
   gn_detail_counter      NUMBER                                         := 0;
                                                      --Detail record counter
------------------
--counters
------------------
   gn_func_grp_cnt        NUMBER                                         := 0;
   --Number of functional groups counter
   --Used in IEA record
   gn_batch_total_cnt     NUMBER                                         := 0;
   --Batch trailer count
   gn_batch_count         NUMBER                                         := 0;
   --Counts the number of batches in file
   gn_total_record_cnt    NUMBER                                         := 0;
   --Total record count in file
   gn_file_addenda_cnt    NUMBER                                         := 0;
   --File trailer addenda total
   gn_file_hash_total     NUMBER                                         := 0;
   --File trailer hash total
   gn_file_amt_tot        NUMBER                                         := 0;
  

   --File trailer amount total

   -- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |           Office Depot Organization               |
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
-- |Version   Date        Author           Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  07-JUN-2008 P.Marco          Initial draft version       |
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
      gc_current_step := ' Step: FUNCTION SETTLE_DATE ';

            -----------------------------------
            --   remove query per defect 15436
            -----------------------------------
--          SELECT xpvs.eft_settle_days
--            INTO lc_settle_days
--            FROM xx_po_vendor_sites_kff_v xpvs,
--                 po_vendor_sites pvs,
--                 po_vendors pv
--           WHERE xpvs.vendor_site_id = pvs.vendor_site_id
--             AND pvs.vendor_id =  p_vendor_id
--             AND xpvs.eft_settle_days is not null
--             AND rownum = 1;

      ------------------------------
-- Added code per defect 15436
------------------------------
      SELECT NVL (xpvs.eft_settle_days, 0)
        INTO lc_settle_days
        FROM xx_po_vendor_sites_kff_v xpvs, po_vendor_sites pvs
       WHERE xpvs.vendor_site_id = pvs.vendor_site_id
         AND pvs.vendor_site_id = p_vendor_site_id
         AND pvs.vendor_id = p_vendor_id;

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

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |           Office Depot Organization               |
-- +===================================================================+
-- | Name  : PAYMENT_DETAILS                                           |
-- | Description : This program will create and write details for the  |
-- |               addenda record (type 7 record)                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  07-JUN-2008 P.Marco          Initial draft version       |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE payment_details (
      p_vendor_id        IN   NUMBER,
      p_vendor_site_id   IN   NUMBER,
      p_vendor_type      IN   VARCHAR2,
      p_payment_type     IN   VARCHAR2
   )
   AS
      lc_entrydetail2          VARCHAR2 (200);
      lc_print_line            VARCHAR2 (5000);
      lc_print_line_tot        VARCHAR2 (5000);
      ln_wrap_length           NUMBER                                   := 80;
      -- number of columns before return character
      ln_rec_length            NUMBER;
      ln_isa_seq_num           NUMBER                                    := 0;
      ln_rec_seq_num           NUMBER                                    := 0;
      ln_rec_cntrl_num         NUMBER                                    := 0;
      ln_pay_tot_amt           NUMBER                                    := 0;
                                           -- pay total amount for BPR record
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
      lc_trn_hdr_rec           VARCHAR2 (200);       --Defect 6651 TRN record
      lc_ref_hdr_rec           VARCHAR2 (200);       --Defect 6651 REF record
      lc_n1pe_hdr_rec          VARCHAR2 (200);     --Defect 6651 N1 PE record
      lc_n1pr_hdr_rec          VARCHAR2 (200);     --Defect 6651 N1 PR record
      lc_ent_hdr_rec           VARCHAR2 (200);       --Defect 6651 ENT reocrd
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
-----------------------------
-- CR461 Vendor RMR Variables
-----------------------------
      ln_invoice_num           ap_selected_invoices.invoice_num%TYPE;
      ln_payment_amount        ap_selected_invoices.payment_amount%TYPE;
      ln_invoice_amount        ap_selected_invoices.invoice_amount%TYPE;
      ln_discount_amount       ap_selected_invoices.discount_amount%TYPE;
      lc_rmr_code              VARCHAR2 (2);
-----------------------------------------------------
-- Defect 11953 added variable lc_invoice_discription
-----------------------------------------------------
      lc_invoice_discription   ap_selected_invoices.invoice_description%TYPE;

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
                   TO_CHAR (NVL (asic.payment_date, SYSDATE), 'YYMMDD')
                || '*'
                || NVL (aida.amount * 100, 0)
                || '*'
                ||
                   -- SSN
                   DECODE (asi.country,
                           'US', SUBSTR (SUBSTR (aida.attribute12,
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
           FROM ap_invoices ai,
                ap_selected_invoices asi,
                ap_selected_invoice_checks asic,
                ap_invoice_distributions_all aida,
                po_vendors pv
          WHERE asic.selected_check_id = asi.pay_selected_check_id
            AND asic.vendor_id = pv.vendor_id
            AND NVL (pv.vendor_type_lookup_code, 'Y') = p_vendor_type
            AND asi.invoice_num = ai.invoice_num
            AND ai.invoice_id = asi.invoice_id
            AND asic.vendor_id = p_vendor_id
            AND asic.vendor_site_id = p_vendor_site_id         -- Defect 11003
            AND aida.invoice_id = asi.invoice_id
            AND asic.ok_to_pay_flag = 'Y'
            AND asi.ok_to_pay_flag = 'Y'             -- Added per defect 15365
            AND aida.amount <> 0;

---------------------------------------------------
-- AMEX payee Details cursor 705 RMR records
---------------------------------------------------
      CURSOR amex_details_cursor
      IS
         SELECT    'RMR'
                || '*'
                || 'CM'
                || 
                   -- First removed per defect 15612 later added per defect 561

                   --  '11' ||                                                           -- first Added per defect 15612 later removed per defect 561
                   '*'
                || xais.global_attribute1
                || '**'
                ||                                     -- Added per defect 561
                   LTRIM (TO_CHAR (NVL (asi.payment_amount, 0),
                                   '999999999.99')
                         )
                || 
                   -- NVL(ASI.payment_amount*100,0)||                                    Defect 6651 explict decimal needed in RMR
                   -- '*'||                                                              removed per defect 15612
                   --  LTRIM(TO_CHAR(NVL(ASI.payment_amount,0),'999999999.99'))||        removed per defect 15612
                   -- NVL(ASI.payment_amount*100,0)||                                    Defect 6651 explict decimal needed in RMR
                   '\'
                || 'REF*'
                || SUBSTR (asi.invoice_num, 1, 2)
                ||                                   --Defect 6651 REF Trailer
                   '*'
                || SUBSTR (asi.invoice_num, 3, 2)
                || '\REF*'
                || SUBSTR (asi.invoice_num, 5, 2)
                ||                                   --Defect 6651 REF Trailer
                   '*'
                || SUBSTR (asi.invoice_num, 7, 2)
                || '*'
                || SUBSTR (asi.invoice_num, 9, 2)
                || '\'
           FROM ap_selected_invoice_checks asic,
                ap_selected_invoices asi,
                ap_invoices ai,
                xx_ap_inv_interface_stg xais
          WHERE asic.selected_check_id = asi.pay_selected_check_id
            AND ai.invoice_id = asi.invoice_id
            AND asic.vendor_id = p_vendor_id
            AND asic.vendor_site_id = p_vendor_site_id         -- Defect 11003
            -- AND  XAIS.attribute10        =   ai.attribute10                     -- Removed per defect 2133 Added for the Defect : 6302
            AND LTRIM (xais.attribute10, 0) =
                            RTRIM (LTRIM (asic.vendor_site_code, 'E0'), 'PRY')
            --Added per defect 2133
            AND xais.invoice_date = ai.invoice_date
            AND asic.ok_to_pay_flag = 'Y'
            AND asi.ok_to_pay_flag = 'Y'             -- Added per defect 15365
            AND TRIM (xais.invoice_num) = TRIM (ai.invoice_num)
            AND asic.checkrun_name = gc_checkrun_name;

---------------------------------------------------
-- JP Morgan payee Details cursor 705 RMR records
---------------------------------------------------
      CURSOR jpm_details_cursor
      IS            
         SELECT    'RMR'
                || '*'
                || 'IV'
                || '*'
                || c.card_number
                || '**'
                || LTRIM (TO_CHAR (NVL (asi.payment_amount, 0),
                                   '999999999.99')
                         )
                || '\'
                || 'REF*1Z*'
                || ai.invoice_num
                || '\'
           FROM ap_selected_invoice_checks asic,
                ap_selected_invoices asi,
                ap_invoices ai,
                ap_expense_report_headers_all h,
                ap_cards_all c
          WHERE asic.selected_check_id = asi.pay_selected_check_id
            AND ai.invoice_id = asi.invoice_id
            AND asic.vendor_id = p_vendor_id
            AND asic.vendor_site_id = p_vendor_site_id
            AND asic.ok_to_pay_flag = 'Y'
            AND asi.ok_to_pay_flag = 'Y'
            AND h.vouchno = ai.invoice_id
            AND h.employee_id = c.employee_id
            AND asic.checkrun_name = gc_checkrun_name
            /*Added for QC Defect # 19757 - Duplicate records in JP Morgan EFT because of two cards assigned to an employee - Start*/
            AND c.card_number =  NVL ( (SELECT DISTINCT apt.card_number
                                          FROM ap_expense_report_headers_all aph,
                                               ap_credit_card_trxns_all apt
                                         WHERE apt.report_header_id    = aph.report_header_id
                                           AND aph.report_header_id    = h.bothpay_parent_id
                                        ) , c.card_number )
            /*Added for QC Defect # 19757 - Duplicate records in JP Morgan EFT because of two cards assigned to an employee - End*/
            ;           

----------------------------------------------
-- VENDOR payee Details cursor 705 RMR records
----------------------------------------------
      CURSOR vendor_details_cursor
      IS
         SELECT SUBSTR (asi.invoice_num, 1, 30),
                LTRIM (TO_CHAR (NVL (asi.payment_amount, 0), '999999999.99')),
                LTRIM (TO_CHAR (NVL (asi.invoice_amount, 0), '999999999.99')),
                LTRIM (TO_CHAR (NVL (asi.discount_amount, 0), '999999999.99')),
                asi.invoice_description                        -- Defect 11953
           FROM ap_selected_invoice_checks asic, ap_selected_invoices asi
          WHERE asic.selected_check_id = asi.pay_selected_check_id
            AND asic.vendor_id = p_vendor_id
            AND asic.vendor_site_id = p_vendor_site_id         -- Defect 11003
            AND asic.ok_to_pay_flag = 'Y'
            AND asi.ok_to_pay_flag = 'Y'             -- Added per defect 15365
            AND asic.checkrun_name = gc_checkrun_name;
--------------------------------------------------------------------------------
--  CR461 vendor_details_cursor cursor modified to brake apart record string.
--  below the orginal code is commented out.
--------------------------------------------------------------------------------

   --      SELECT   'RMR'||
   --               '*'||
   --               'IV'||
   --               '*'||
   --               SUBSTR(ASI.invoice_num,1,30)||
   --               '**'||
   --               LTRIM(TO_CHAR(NVL(ASI.payment_amount,0),'999999999.99'))||
   --               '*'||
   --               LTRIM(TO_CHAR(NVL(ASI.invoice_amount,0),'999999999.99'))||
   --               '*'||
   --               LTRIM(TO_CHAR(NVL(ASI.discount_amount,0),'999999999.99'))||
   --               '\'
   --         FROM
   --               ap_selected_invoice_checks   ASIC
   --               ,ap_selected_invoices         ASI
   --        WHERE  ASIC.selected_check_id     =  ASI.pay_selected_check_id
   --          AND   ASIC.vendor_id            =  p_vendor_id
   --          AND   ASIC.ok_to_pay_flag       = 'Y'
   --          AND asic.checkrun_name          = gc_checkrun_name;
   BEGIN
      fnd_file.put_line (fnd_file.LOG,
                         'p_payment_type    - > ' || p_payment_type
                        );
-------------------------------
-- Initalize 705 Header records
-------------------------------
      gn_isa_seq_num := gn_isa_seq_num + 1;
      gc_st_cntrl_num := gc_st_cntrl_num + 1;
-------------------
--ISA Header Record
-------------------
      gc_current_step := ' Step: Intialize ISA Header Record ';

      IF p_payment_type = 'GARNSH'
      THEN
         lc_intchg_cntrl :=
               'ISA*'
            || '00*'
            || '          *'
            || '00*'
            || '          *'
            || '08*'
            || RPAD (SUBSTR (gc_edi_sender_id, 1, 10), 15, ' ')
            || '*'
            || gc_edi_qualifier
            || '*'
            || RPAD (SUBSTR (gc_edi_id, 1, 15), 15, ' ')
            || '*'
            || TO_CHAR (SYSDATE, 'YYMMDD')
            || '*'
            || TO_CHAR (SYSDATE, 'HH24MI')
            || '*'
            || 'U*'
            || '00400*'
            || LPAD (gn_isa_seq_num, 9, '0')
            || '*'
            || '0*'
            || gc_test_indicator
            || '*\';
      ELSIF p_payment_type = 'JP MORGAN'
      THEN
         lc_intchg_cntrl :=
               'ISA*'
            || '00*'
            || '          *'
            || '00*'
            || '          *'
            || 'ZZ*'
            || RPAD (SUBSTR (gc_edi_sender_id, 1, 10), 15, ' ')
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
            || LPAD (gn_isa_seq_num, 9, '0')
            || '*'
            || 
               -- '*'||'U*'|| '00400*'||LPAD(gn_isa_seq_num,9,'0') ||'*'||
               '0*'
            || gc_test_indicator
            || '*~\';
      ELSE
---------------------------------------------------------------------
-- NOn- Garishment records need to have a ~ At the end of the records
---------------------------------------------------------------------
-- Defect 10693 ISA12 should be 00401, not 00400
-- and ISA 06 need RPAD with spaces for 15
         lc_intchg_cntrl :=
               'ISA*'
            || '00*'
            || '          *'
            || '00*'
            || '          *'
            || '08*'
            || RPAD (SUBSTR (gc_edi_sender_id, 1, 10), 15, ' ')
            || '*'
            ||
               -- '08*'||gn_gs_edi_sender_id||'*'||
               gc_edi_qualifier
            || '*'
            || RPAD (SUBSTR (gc_edi_id, 1, 15), 15, ' ')
            || '*'
            || TO_CHAR (SYSDATE, 'YYMMDD')
            || '*'
            || TO_CHAR (SYSDATE, 'HH24MI')
            || '*'
            || 'U*'
            || '00401*'
            || LPAD (gn_isa_seq_num, 9, '0')
            || '*'
            || 
               -- '*'||'U*'|| '00400*'||LPAD(gn_isa_seq_num,9,'0') ||'*'||
               '0*'
            || gc_test_indicator
            || '*~\';
      END IF;

------------------
--GS Header Record
------------------
      gc_current_step := ' Step: Intialize GS Header Record ';

      IF p_payment_type = 'JP MORGAN'                       -- added for CR561
      THEN
         lc_func_grp_cntrl :=
               'GS*'
            || 'RA*'
            || gn_gs_edi_sender_id
            || '*'
            || gc_edi_id
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
            || gn_gs_edi_sender_id
            || '*'
            || gc_edi_id
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

      -- Defect 10693 removed * from record  '004010*'||'\';
      ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
------------------
--ST Header Record
------------------
      gc_current_step := ' Step: Intialize ST Header Record ';
      lc_trans_set_cntrl :=
                       'ST*' || '820*' || LPAD (gc_st_cntrl_num, 9, '0')
                       || '\';
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
         gc_current_step := ' Step: Granishment AMOUNT SUMMARY ';

         SELECT NVL (SUM (aida.amount), 0.00)
           INTO ln_pay_tot_amt
           FROM ap_invoices ai,
                ap_selected_invoices asi,
                ap_selected_invoice_checks asic,
                ap_invoice_distributions_all aida,
                po_vendors pv
          WHERE asic.selected_check_id = asi.pay_selected_check_id
            AND asic.vendor_id = pv.vendor_id
            AND NVL (pv.vendor_type_lookup_code, 'Y') = p_vendor_type
            AND asi.invoice_num = ai.invoice_num
            AND ai.invoice_id = asi.invoice_id
            AND asic.vendor_id = p_vendor_id
            AND asic.vendor_site_id = p_vendor_site_id         -- defect 11003
            AND aida.invoice_id = asi.invoice_id
            AND asic.ok_to_pay_flag = 'Y'
            AND asi.ok_to_pay_flag = 'Y'              --Added per defect 15365
            AND aida.amount <> 0;

         fnd_file.put_line (fnd_file.LOG,
                            'Granisment AMOUNT SUMMARY' || p_vendor_id
                           );
      ELSIF p_payment_type IN ('AMEX', 'JP MORGAN')
      THEN
----------------------
-- AMEX AMOUNT SUMMARY
----------------------
         gc_current_step := ' Step: AMEX AMOUNT SUMMARY ';

         SELECT NVL (SUM (asi.payment_amount), 0.00)
           INTO ln_pay_tot_amt
           FROM ap_selected_invoice_checks asic,
                ap_selected_invoices asi,
                ap_invoices ai
          WHERE asic.selected_check_id = asi.pay_selected_check_id
            AND ai.invoice_id = asi.invoice_id
            AND asic.vendor_id = p_vendor_id
            AND asic.vendor_site_id = p_vendor_site_id         -- defect 11003
            AND asic.ok_to_pay_flag = 'Y'
            AND asi.ok_to_pay_flag = 'Y'              --Added per defect 15365
            AND asic.checkrun_name = gc_checkrun_name;

         fnd_file.put_line (fnd_file.LOG,
                            'AMEX AMOUNT SUMMARY' || p_vendor_id);
      ELSE
------------------------
-- VENDOR AMOUNT SUMMARY
------------------------
         gc_current_step := ' Step:  VENDOR AMOUNT SUMMARY ';

         SELECT SUM (NVL (asi.payment_amount, 0.00))
           INTO ln_pay_tot_amt
           FROM ap_selected_invoice_checks asic, ap_selected_invoices asi
          WHERE asic.selected_check_id = asi.pay_selected_check_id
            AND asic.vendor_id = p_vendor_id
            AND asic.vendor_site_id = p_vendor_site_id         -- defect 11003
            AND asic.ok_to_pay_flag = 'Y'
            AND asi.ok_to_pay_flag = 'Y'              --Added per defect 15365
            AND asic.checkrun_name = gc_checkrun_name;

         fnd_file.put_line (fnd_file.LOG,
                            'VENDOR AMOUNT SUMMARY' || p_vendor_id
                           );
      END IF;

---------------------------
--Create BPR Header Record
---------------------------
      gc_current_step := ' Step:  Creating BPR Header Record ';
      gn_batch_amt_tot := ln_pay_tot_amt;
      gn_file_amt_tot := gn_file_amt_tot + gn_batch_amt_tot;
      -- Defect 10693 BPR11 Blank value omitted
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
         || gc_bank_routing_num
         || '*DA*'
         || gc_bank_account_num
         || '*'
         || gn_edi_duns_id
         || '**'
         || '01*'
         || gc_rec_dfi_bank_id
         || '*DA*'
         || gc_rec_dfi_bank_acct
         || '\';

      IF p_payment_type = 'JP MORGAN'
      THEN                                                  -- added for cr561
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
            || gc_bank_routing_num
            || '*DA*'
            || gc_bank_account_num
            || '*'
            || gn_edi_duns_id
            || '**'
            || '01*'
            || gc_rec_dfi_bank_id
            || '*DA*'
            || gc_rec_dfi_bank_acct
            || '*'
            || TO_CHAR (SYSDATE, 'YYYYMMDD')
            || '\';
      END IF;                                               -- added for cr561

      ln_se_rec_cnt := ln_se_rec_cnt + 1;
      ln_ge_rec_cnt := ln_ge_rec_cnt + 1;

-------------------------------------------------------------------
-- Per defect 6651: Both the AMEX and the Vendor records require a
-- additional TRN,REF,N1,ENT Records added after the BPR record
-------------------------------------------------------------------
      IF p_payment_type <> 'GARNSH'
      THEN
---------------------------
-- Create TRN Header Record  (Defect 6651)
---------------------------
         IF p_payment_type <> 'JP MORGAN'
         THEN
            gc_current_step := ' Step:  Creating TRN Header Record ';
            lc_trn_hdr_rec := 'TRN*1*' || gn_check_number || '\';
            ln_se_rec_cnt := ln_se_rec_cnt + 1;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
---------------------------
-- Create REF Header Record  (Defect 6651)
---------------------------
            gc_current_step := ' Step:  Creating REF Header Record ';
            lc_ref_hdr_rec :=
                       'REF*BT*' || TO_CHAR (SYSDATE, 'YYYYMMDDHH24MI')
                       || '\';
            ln_se_rec_cnt := ln_se_rec_cnt + 1;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
         END IF;

---------------------------
-- Create N1PE Header Record  (Defect 6651)
---------------------------
         gc_current_step := ' Step:  Creating N1PE Header Record ';

         IF p_payment_type = 'AMEX'
         THEN
-------------------------------------------------------------------
-- Per defect 561 concat load number reference to header REF field
-------------------------------------------------------------------
            lc_ref_hdr_rec := lc_ref_hdr_rec || 'REF*ZZ*LOAD 66033\';
            -- Added per defect 561
            lc_n1pe_hdr_rec := 'N1*PE*AMEX\';
         ELSIF p_payment_type = 'JP MORGAN'               --- ADDEED FOR CR561
         THEN
            -- lc_ref_hdr_rec := lc_ref_hdr_rec || 'REF*ZZ*LOAD 66033\';
            lc_n1pe_hdr_rec := 'N1*PE*JPMORGAN COMMERCIAL CARD\';
         --- ADDEED FOR CR561
         ELSE
            lc_n1pe_hdr_rec := 'N1*PE*' || gc_vendor_name || '\';
         END IF;

         ln_se_rec_cnt := ln_se_rec_cnt + 1;
         ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
---------------------------
-- Create N1PR Header Record  (Defect 6651)
---------------------------
         gc_current_step := ' Step:  Creating N1PR Header Record ';
         lc_n1pr_hdr_rec := 'N1*PR*OFFICE DEPOT\';
         ln_se_rec_cnt := ln_se_rec_cnt + 1;
         ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
---------------------------
-- Create ENT Header Record  (Defect 6651)
---------------------------
         gc_current_step := ' Step:  Creating ENT Header Record ';

         IF p_payment_type = 'AMEX'
         THEN
            --lc_ent_hdr_rec    := 'ENT*6033\';                                                    removed per defect 15612
            lc_ent_hdr_rec := 'ENT*6033\';            -- Added per defect 561
            lc_beg_pay_order :=
                  lc_beg_pay_order
               || lc_trn_hdr_rec
               || lc_ref_hdr_rec
               ||                                    -- Added per defect 15612
                  lc_n1pr_hdr_rec
               || lc_n1pe_hdr_rec
               || lc_ent_hdr_rec;                      -- Added per defect 561
         --                  lc_n1pr_hdr_rec  || lc_n1pe_hdr_rec;                            -- Added per defect 15612 then removed
                                                                                             -- per defect 561
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
      -- Defect 10693 reversed the order of PE and PR fields two line below commented out

      -- lc_beg_pay_order := lc_beg_pay_order || lc_trn_hdr_rec || lc_ref_hdr_rec ||
      --                     lc_n1pe_hdr_rec  || lc_n1pr_hdr_rec || lc_ent_hdr_rec;
      END IF;

----------------------------------------------------------------------
-- Create one large string for all the Functional group header records
-- ISA, GS, ST will be created at this point.
----------------------------------------------------------------------
      gc_current_step := ' Step:  Functional group header records ';
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
      gc_current_step := ' Step: LOOP to write 705 records ';

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
            || LPAD (gn_detail_counter, 7, '0');
         UTL_FILE.put_line (g_filehandle, lc_print_line);
         gn_batch_total_cnt := gn_batch_total_cnt + 1;
         gn_total_record_cnt := gn_total_record_cnt + 1;
         gn_file_addenda_cnt := gn_file_addenda_cnt + 1;
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
      gc_current_step := ' Step:  Cursor to create 705 DED Garnishments ';

      IF p_payment_type = 'GARNSH'
      THEN
         gc_current_step := 'Step: OPENING garnish_details_cursor';

         OPEN garnish_details_cursor;

         LOOP
            FETCH garnish_details_cursor
             INTO lc_entrydetail2;

            EXIT WHEN garnish_details_cursor%NOTFOUND;
            ln_se_rec_cnt := ln_se_rec_cnt + 1;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
            --gn_batch_total_cnt := gn_batch_total_cnt + 1;

            ------------------------------------------------------
-- Create one large string for all the 705 DED Details
------------------------------------------------------
            gc_current_step :=
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
               gc_current_step := ' Step:  Write 705 Record for Garnishment ';
               lc_print_line :=
                     '705'
                  || SUBSTR (lc_print_line_tot, 1, ln_wrap_length)
                  || LPAD (ln_rec_seq_num, 4, '0')
                  || LPAD (gn_detail_counter, 7, '0');
               UTL_FILE.put_line (g_filehandle, lc_print_line);
               gn_batch_total_cnt := gn_batch_total_cnt + 1;
               gn_total_record_cnt := gn_total_record_cnt + 1;
               gn_file_addenda_cnt := gn_file_addenda_cnt + 1;
-----------------------------------------------
-- Get remainder of String for wrapping records
-----------------------------------------------
               gc_current_step :=
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
         gc_current_step := 'Step: OPENING amex_details_cursor';

 fnd_file.put_line (fnd_file.LOG,
                         'Step: OPENING amex_details_cursor -->  ' || p_payment_type
                        );
         OPEN amex_details_cursor;

         LOOP
            FETCH amex_details_cursor
             INTO lc_entrydetail2;

            EXIT WHEN amex_details_cursor%NOTFOUND;
            ln_se_rec_cnt := ln_se_rec_cnt + 1;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
            --gn_batch_total_cnt := gn_batch_total_cnt + 1;

            ------------------------------------------------------------------
--Defect 6651 Added Two to the counter for the trailer REF records
------------------------------------------------------------------
            ln_se_rec_cnt := ln_se_rec_cnt + 2;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 2;
--------------------------------------------------------------
-- Create one large string for all the 705 DED Details
--------------------------------------------------------------
            gc_current_step :=
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
                  || LPAD (gn_detail_counter, 7, '0');
               UTL_FILE.put_line (g_filehandle, lc_print_line);
               gn_batch_total_cnt := gn_batch_total_cnt + 1;
               gn_total_record_cnt := gn_total_record_cnt + 1;
               gn_file_addenda_cnt := gn_file_addenda_cnt + 1;
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

--Below  added for CR561
--------------------------------------------
-- Cursor to create 705 DED records for AMEX
--------------------------------------------
      IF p_payment_type = 'JP MORGAN'
      THEN
         gc_current_step := 'Step: OPENING jpm_details_cursor';

         OPEN jpm_details_cursor;

         LOOP
            FETCH jpm_details_cursor
             INTO lc_entrydetail2;

            EXIT WHEN jpm_details_cursor%NOTFOUND;
            ln_se_rec_cnt := ln_se_rec_cnt + 1;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
            --gn_batch_total_cnt := gn_batch_total_cnt + 1;

            ------------------------------------------------------------------
--Defect 6651 Added Two to the counter for the trailer REF records
------------------------------------------------------------------
            -- V2.6, instead of 2 trailer REF, it will be 1 in case of JP MORGAN
            ln_se_rec_cnt := ln_se_rec_cnt + 1;   --2;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;   --2;
--------------------------------------------------------------
-- Create one large string for all the 705 DED Details
--------------------------------------------------------------
            gc_current_step :=
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
                  || LPAD (gn_detail_counter, 7, '0');
               UTL_FILE.put_line (g_filehandle, lc_print_line);
               gn_batch_total_cnt := gn_batch_total_cnt + 1;
               gn_total_record_cnt := gn_total_record_cnt + 1;
               gn_file_addenda_cnt := gn_file_addenda_cnt + 1;
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

         CLOSE jpm_details_cursor;
      END IF;

-- added for CR561

      ------------------------------------------------
-- Cursor to create 705 DED records for Vendors
------------------------------------------------
      IF p_payment_type = 'VENDOR'
      THEN
         gc_current_step := 'Step: OPENING vendor_details_cursor';

         OPEN vendor_details_cursor;

         LOOP
            FETCH vendor_details_cursor
             INTO ln_invoice_num, ln_payment_amount, ln_invoice_amount,
                  ln_discount_amount, lc_invoice_discription;

            -- Defect 11953 added line
            EXIT WHEN vendor_details_cursor%NOTFOUND;
            ln_se_rec_cnt := ln_se_rec_cnt + 1;
            ln_ge_rec_cnt := ln_ge_rec_cnt + 1;

----------------------------------------------------
-- CR461 credit memos for vendor RMR records need to
-- contain a CM in the RMR1 record
----------------------------------------------------
            IF ln_payment_amount < 0
            THEN
               lc_rmr_code := 'CM';
            ELSE
               lc_rmr_code := 'IV';
            END IF;

-----------------------------------------------
-- Defect 11953: Added IF statement to create
-- additional REF record if invoice discription
-- exists.
-----------------------------------------------
            IF lc_invoice_discription IS NULL
            THEN
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
                  || '\';
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
                  || lc_invoice_discription
                  || '\';
               ln_se_rec_cnt := ln_se_rec_cnt + 1;   -- Added per defect 15550
               ln_ge_rec_cnt := ln_ge_rec_cnt + 1;   -- Added per Defect 15550
            END IF;

--------------------------------------------------------------
-- Create one large string for all the 705 DED Vendor Details
--------------------------------------------------------------
            gc_current_step :=
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
                  || LPAD (gn_detail_counter, 7, '0');
               UTL_FILE.put_line (g_filehandle, lc_print_line);
               gn_batch_total_cnt := gn_batch_total_cnt + 1;
               gn_total_record_cnt := gn_total_record_cnt + 1;
               gn_file_addenda_cnt := gn_file_addenda_cnt + 1;
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

      gc_current_step := 'Step: Intialize the 705 trailer records';
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
         || LPAD (gc_st_cntrl_num, 9, '0')
         || '\';
---------------------------------------
-- Transaction Set Trailer Summary (GE)
---------------------------------------
      ln_ge_rec_cnt := ln_ge_rec_cnt + 1;
      -- Defect 6651

      -- lc_ge_tran_set_trail := 'GE'||'*'||ln_ge_rec_cnt||'*'||'         '||'\';
      lc_ge_tran_set_trail := 'GE' || '*' || '1' || '*' || '000000001' || '\';
---------------------------------------
-- Transaction Set Trailer Summary (IEA)
---------------------------------------

      -- Defect 6651

      -- lc_lea_cntrl_trailer  := 'IEA'||'*'|| RPAD(gn_func_grp_cnt,4,'0')||'*'||
      --                           LPAD(gn_isa_seq_num,9,'0')||'\';
      lc_lea_cntrl_trailer :=
             'IEA' || '*' || '1' || '*' || LPAD (gn_isa_seq_num, 9, '0')
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
            || LPAD (gn_detail_counter, 7, '0');
         UTL_FILE.put_line (g_filehandle, lc_print_line);
         gn_batch_total_cnt := gn_batch_total_cnt + 1;
         gn_total_record_cnt := gn_total_record_cnt + 1;
         gn_file_addenda_cnt := gn_file_addenda_cnt + 1;
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
            UTL_FILE.put_line (g_filehandle,
                                  '705'
                               || lc_print_line_tot
                               || LPAD (ln_rec_seq_num, 4, '0')
                               || LPAD (gn_batch_count, 7, '0')
                              );
            gn_batch_total_cnt := gn_batch_total_cnt + 1;
            gn_total_record_cnt := gn_total_record_cnt + 1;
            gn_file_addenda_cnt := gn_file_addenda_cnt + 1;
         ELSE
            UTL_FILE.put_line (g_filehandle,
                                  '705'
                               || RPAD (lc_print_line_tot,
                                        (  (ln_wrap_length - ln_rec_length)
                                         + ln_rec_length
                                        ),
                                        ' '
                                       )
                               || LPAD (ln_rec_seq_num, 4, '0')
                               || LPAD (gn_batch_count, 7, '0')
                              );
            gn_batch_total_cnt := gn_batch_total_cnt + 1;
            gn_total_record_cnt := gn_total_record_cnt + 1;
            gn_file_addenda_cnt := gn_file_addenda_cnt + 1;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line
                    (fnd_file.LOG,
                        'Error:  XX_AP_EFTNACHABOA_PKG.payee_details_cursor '
                     || SQLERRM ()
                    );
   END payment_details;
   
   
-- V2.7, Below procedure created for this defect
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |           Office Depot Organization                               |
-- +===================================================================+
-- | Name  : jp_morgan_rec_counts                                      |
-- | Description :Local procedure to get the count of records in case  | 
-- |              of JP Morgan and which has card Program setup        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       06-Mar-2012 Jay Gupta        Initial draft version       |
-- +===================================================================+   
   
      PROCEDURE jp_morgan_rec_counts (
         p_vendor_id        IN   NUMBER,
         p_vendor_site_id   IN   NUMBER,
         xn_count OUT NUMBER)
      AS
         ln_isa_seq_num number:=0;
         ln_st_cntrl_num number:=0;
         lc_intchg_cntrl          VARCHAR2 (200);
         lc_func_grp_cntrl        VARCHAR2 (200);  
         lc_trans_set_cntrl       VARCHAR2 (200);  
         ln_se_rec_cnt            NUMBER := 0;  
         lc_beg_pay_order         VARCHAR2 (2000); 
         lc_n1pe_hdr_rec          VARCHAR2 (200);
         lc_n1pr_hdr_rec          VARCHAR2 (200);
         lc_ent_hdr_rec           VARCHAR2 (200);
         ln_rec_seq_num           NUMBER := 0;        
         lc_entrydetail2          VARCHAR2 (200);
         lc_print_line            VARCHAR2 (5000);
         lc_print_line_tot        VARCHAR2 (5000);
         ln_wrap_length           NUMBER := 80;
         ln_rec_length            NUMBER := 0;
         ln_total_record_cnt      NUMBER := 0;
         lc_se_tran_set_trail     VARCHAR2 (200);
         lc_ge_tran_set_trail     VARCHAR2 (200); 
         lc_lea_cntrl_trailer     VARCHAR2 (200);
         ln_pay_tot_amt           NUMBER := 0;
   
   ---------------------------------------------------
   -- JP Morgan payee Details cursor 705 RMR records
   ---------------------------------------------------
         CURSOR jpm_details_cursor
         IS
            SELECT    'RMR'
                   || '*'
                   || 'IV'
                   || '*'
                   || c.card_number
                   || '**'
                   || LTRIM (TO_CHAR (NVL (asi.payment_amount, 0),
                                      '999999999.99')
                            )
                   || '\'
                   || 'REF*1Z*'
                   || ai.invoice_num
                   || '\'
              FROM ap_selected_invoice_checks asic,
                   ap_selected_invoices asi,
                   ap_invoices ai,
                   ap_expense_report_headers_all h,
                   ap_cards_all c
             WHERE asic.selected_check_id = asi.pay_selected_check_id
               AND ai.invoice_id = asi.invoice_id
               AND asic.vendor_id = p_vendor_id
               AND asic.vendor_site_id = p_vendor_site_id
               AND asic.ok_to_pay_flag = 'Y'
               AND asi.ok_to_pay_flag = 'Y'
               AND h.vouchno = ai.invoice_id
               AND h.employee_id = c.employee_id
               AND asic.checkrun_name = gc_checkrun_name;
               
      BEGIN
         fnd_file.put_line (fnd_file.LOG,'Counting the JP Morgan Records');
         ln_isa_seq_num := ln_isa_seq_num + 1;
         ln_st_cntrl_num := ln_st_cntrl_num + 1;
   
            lc_intchg_cntrl :=
                  'ISA*'
               || '00*'
               || '          *'
               || '00*'
               || '          *'
               || 'ZZ*'
               || RPAD (SUBSTR (gc_edi_sender_id, 1, 10), 15, ' ')
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
               || 
                  -- '*'||'U*'|| '00400*'||LPAD(ln_isa_seq_num,9,'0') ||'*'||
                  '0*'
               || gc_test_indicator
               || '*~\';
   
            lc_func_grp_cntrl :=
                  'GS*'
               || 'RA*'
               || gn_gs_edi_sender_id
               || '*'
               || gc_edi_id
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
   
         lc_trans_set_cntrl :=
                          'ST*' || '820*' || LPAD (ln_st_cntrl_num, 9, '0')
                          || '\';
         ln_se_rec_cnt := ln_se_rec_cnt + 1;
   
            SELECT NVL (SUM (asi.payment_amount), 0.00)
              INTO ln_pay_tot_amt
              FROM ap_selected_invoice_checks asic,
                   ap_selected_invoices asi,
                   ap_invoices ai
             WHERE asic.selected_check_id = asi.pay_selected_check_id
               AND ai.invoice_id = asi.invoice_id
               AND asic.vendor_id = p_vendor_id
               AND asic.vendor_site_id = p_vendor_site_id         -- defect 11003
               AND asic.ok_to_pay_flag = 'Y'
               AND asi.ok_to_pay_flag = 'Y'              --Added per defect 15365
               AND asic.checkrun_name = gc_checkrun_name;
   
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
               || gc_bank_routing_num
               || '*DA*'
               || gc_bank_account_num
               || '*'
               || gn_edi_duns_id
               || '**'
               || '01*'
               || gc_rec_dfi_bank_id
               || '*DA*'
               || gc_rec_dfi_bank_acct
               || '*'
               || TO_CHAR (SYSDATE, 'YYYYMMDD')
               || '\';
   
         ln_se_rec_cnt := ln_se_rec_cnt + 1;
   
         lc_n1pe_hdr_rec := 'N1*PE*JPMORGAN COMMERCIAL CARD\';
   
         ln_se_rec_cnt := ln_se_rec_cnt + 1;
            
         lc_n1pr_hdr_rec := 'N1*PR*OFFICE DEPOT\';
         
         ln_se_rec_cnt := ln_se_rec_cnt + 1;
   
         lc_ent_hdr_rec := 'ENT*1\';
         
         lc_beg_pay_order :=
                     lc_beg_pay_order
                 -- || lc_trn_hdr_rec
                 -- || lc_ref_hdr_rec
                  || lc_n1pr_hdr_rec
                  || lc_n1pe_hdr_rec
                  || lc_ent_hdr_rec;
         
         ln_se_rec_cnt := ln_se_rec_cnt + 1;
         
         lc_print_line_tot :=
               lc_intchg_cntrl
            || lc_func_grp_cntrl
            || lc_trans_set_cntrl
            || lc_beg_pay_order;
            
         ln_rec_length := NVL (LENGTH (lc_print_line_tot), 0);
   
         WHILE ln_rec_length > ln_wrap_length
         LOOP
            ln_rec_seq_num := ln_rec_seq_num + 1;
            lc_print_line :=
                  '705'
               || SUBSTR (lc_print_line_tot, 1, ln_wrap_length)
               || LPAD (ln_rec_seq_num, 4, '0')
               || LPAD (gn_detail_counter, 7, '0');
   
            ln_total_record_cnt := ln_total_record_cnt + 1;
            lc_print_line_tot :=
                  SUBSTR (lc_print_line_tot, (ln_wrap_length + 1), ln_rec_length);
            ln_rec_length := LENGTH (lc_print_line_tot);
         END LOOP;
   
         OPEN jpm_details_cursor;
         LOOP
            FETCH jpm_details_cursor
                INTO lc_entrydetail2;
   
               EXIT WHEN jpm_details_cursor%NOTFOUND;
               ln_se_rec_cnt := ln_se_rec_cnt + 1;
               ln_se_rec_cnt := ln_se_rec_cnt + 1; 
               lc_print_line_tot := lc_print_line_tot || lc_entrydetail2;
               ln_rec_length := NVL (LENGTH (lc_print_line_tot), 0);
   
               IF ln_rec_length > ln_wrap_length
               THEN
                  ln_rec_seq_num := ln_rec_seq_num + 1;
                  lc_print_line :=
                        '705'
                     || SUBSTR (lc_print_line_tot, 1, ln_wrap_length)
                     || LPAD (ln_rec_seq_num, 4, '0')
                     || LPAD (gn_detail_counter, 7, '0');
                  ln_total_record_cnt := ln_total_record_cnt + 1;
                  lc_print_line_tot :=
                     SUBSTR (lc_print_line_tot,
                             (ln_wrap_length + 1),
                             ln_rec_length
                            );
                  ln_rec_length := LENGTH (lc_print_line_tot);
               END IF;
            END LOOP;
   
            CLOSE jpm_details_cursor;
            
         ln_se_rec_cnt := ln_se_rec_cnt + 1;
   
         lc_se_tran_set_trail :=
               'SE'
            || '*'
            || SUBSTR (ln_se_rec_cnt, 1, 6)
            || '*'
            || LPAD (ln_st_cntrl_num, 9, '0')
            || '\';
   
         lc_ge_tran_set_trail := 'GE' || '*' || '1' || '*' || '000000001' || '\';
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
            ln_rec_seq_num := ln_rec_seq_num + 1;
            lc_print_line :=
                  '705'
               || SUBSTR (lc_print_line_tot, 1, ln_wrap_length)
               || LPAD (ln_rec_seq_num, 4, '0')
               || LPAD (gn_detail_counter, 7, '0');
   
            ln_total_record_cnt := ln_total_record_cnt + 1;
            lc_print_line_tot :=
                  SUBSTR (lc_print_line_tot, (ln_wrap_length + 1), ln_rec_length);
            ln_rec_length := LENGTH (lc_print_line_tot);
         END LOOP;
            
         ln_rec_length := LENGTH (lc_print_line_tot);
         lc_print_line_tot := SUBSTR (lc_print_line_tot, 1, ln_rec_length);
         
   -----------------------------------------------
   -- Get remainder of String for wrapping records
   -----------------------------------------------
         ln_rec_length := LENGTH (lc_print_line_tot);
         lc_print_line_tot := SUBSTR (lc_print_line_tot, 1, ln_rec_length);
   
         IF ln_rec_length <= ln_wrap_length AND NVL (ln_rec_length, 0) <> 0
         THEN
            ln_rec_seq_num := ln_rec_seq_num + 1;
            ln_total_record_cnt := ln_total_record_cnt + 1;
         END IF;
         xn_count := ln_total_record_cnt;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line(fnd_file.LOG,'Error: while counting the records for JP Morgan '
                        || SQLERRM ()
                       );
   END jp_morgan_rec_counts;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |           Office Depot Organization               |
-- +===================================================================+
-- | Name  : EFT_NACHA820_FORMAT                                       |
-- | Description :Main program called to format EFT payment file.      |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  07-JUN-2008 P.Marco          Initial draft version       |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE eft_nacha820_format (
      errbuff       OUT      VARCHAR2,
      retcode       OUT      VARCHAR2,
      p_pay_batch   IN       VARCHAR2
       )
   AS
-- ******************************************
-- Variables defined
-- ******************************************
      gn_request_id            NUMBER        := fnd_global.conc_request_id
                                                                          ();
      ln_req_id                NUMBER;
      lc_time_stamp            DATE                                := SYSDATE;
      lc_batcherheader         VARCHAR2 (200);
      lc_entrydetail           VARCHAR2 (200);
      lc_entrydetail2          VARCHAR2 (200);
      lc_fileheader            VARCHAR2 (200);
      lc_batch_trailer         VARCHAR2 (200);
      lc_file_trialer          VARCHAR2 (200);
      lc_print_line            VARCHAR2 (200);
      lc_settle_date           VARCHAR2 (6);
      lc_check_date            DATE;
      lc_payment_type          VARCHAR2 (20);
      lc_phase                 VARCHAR2 (50);
      lc_status                VARCHAR2 (50);
      lc_dev_phase             VARCHAR2 (50);
      lc_dev_status            VARCHAR2 (50);
      lc_message               VARCHAR2 (1000);
      lb_result                BOOLEAN;
      lc_batch_amt_temp        VARCHAR2 (50);
      lc_file_amt_temp         VARCHAR2 (50);
      ln_bank_num              ap_bank_branches.bank_number%TYPE;
      lc_checkrun_name         ap_selected_invoice_checks.checkrun_name%TYPE;
      ln_selected_check_id     ap_selected_invoice_checks.selected_check_id%TYPE;
      lc_vendor_name           ap_selected_invoice_checks.vendor_name%TYPE;
      ln_vendor_id             ap_selected_invoice_checks.vendor_id%TYPE;
      ln_vendor_site_id        ap_selected_invoice_checks.vendor_site_id%TYPE;
      lc_vendor_type_lk_code   po_vendors.vendor_type_lookup_code%TYPE;
      lc_amex_vendor_name      xx_fin_translatevalues.source_value1%TYPE;
      lc_garnish_vendor_type   xx_fin_translatevalues.source_value2%TYPE;
      lc_dbname                v$database.NAME%TYPE;
      
      --V2.5
      lc_key VARCHAR2(100);
      lc_encrypt_file_flag CHAR(1);
      --V2.7
      ln_count_705 NUMBER;
      lc_rec_count_705 VARCHAR2 (200);
      ln_card_prog_count NUMBER;
-------------------------------
--payee cursor (LC_ENTRYDETAIL)
-------------------------------
      CURSOR payee_cursor
      IS
         SELECT      '6'
                  || DECODE (asic.check_amount,
                             0, DECODE (UPPER (asic.bank_account_type),
                                        'SAVINGS', '33',
                                        '23'
                                       ),
                             DECODE (UPPER (asic.bank_account_type),
                                     'SAVINGS', '32',
                                     '22'
                                    )
                            )
                  || SUBSTR (NVL (asic.bank_num, '06300002'), 1, 8)
                  || NVL (SUBSTR (asic.bank_num, 9, 1), 1)
                  || RPAD (SUBSTR (asic.bank_account_num, 1, 17), 17, ' ')
                  || LPAD ((asic.check_amount * 100), 10, '0')
                  || RPAD (SUBSTR (UPPER (asic.vendor_num), 1, 15), 15, ' ')
               /* V2.8, Always need to pass '    ' except 'JP MORGAN CHASE' 
                        and which has card program defined 
                        Commented original line and added new */
               /*   || DECODE (UPPER (asic.vendor_name),
                             'JP MORGAN CHASE', '0002',
                             '    '
                            )  */
                  || '    '  -- V2.8 Ends
                  || RPAD (SUBSTR (UPPER (asic.vendor_name), 1, 18), 18, ' ')
                  || '  '
                  || '1'
                  || SUBSTR (NVL (abb.bank_num, '06300002'), 1, 8)
                                                                  -- LC_ENTRYDETAIL
                  ,
                  NVL (SUBSTR (abb.bank_num, 1, 8), '06300002') -- ln_BANK_NUM
                                                               ,
                  asic.checkrun_name                       -- lc_checkrun_name
                                    ,
                  asic.selected_check_id               -- ln_selected_check_id
                                        ,
                  asic.vendor_name                           -- gc_vendor_name
                                  ,
                  asic.vendor_id                               -- ln_vendor_id
                                ,
                  pv.vendor_type_lookup_code         -- lc_vendor_type_lk_code
                                            ,
                  aisc.check_date                             -- lc_check_date
                                 ,
                  SUBSTR (NVL (asic.bank_num, '06300002'), 1, 12)
                                                                 -- Receiving DFI (bank) Identification
                  ,
                  SUBSTR (NVL (asic.bank_account_num, 0), 1, 17)
                                                                -- DFI (Bank) Account Number
                  ,
                  asic.check_number                         -- gn_check_number
                                   ,
                  asic.vendor_site_id                          -- Defect 11003
             FROM ap_bank_branches abb,
                  ap_invoice_selection_criteria aisc,
                  ap_bank_accounts aba,
                  ap_selected_invoice_checks asic,
                  po_vendors pv
            WHERE aisc.bank_account_id = aba.bank_account_id
              AND aba.bank_branch_id = abb.bank_branch_id
              AND asic.checkrun_name = aisc.checkrun_name
              AND asic.ok_to_pay_flag = 'Y'
              AND asic.checkrun_name = p_pay_batch
              AND asic.vendor_id = pv.vendor_id
         ORDER BY asic.vendor_name;

      -- Get all the ftp parameters
           --v_ftp_host       VARCHAR2(50):= FND_PROFILE.VALUE('AP_CHK_FTP_HOST');
           --v_ftp_user    VARCHAR2(50):= FND_PROFILE.VALUE('AP_CHK_FTP_USER');
           --v_ftp_pwd     VARCHAR2(50)      := FND_PROFILE.VALUE('AP_CHK_FTP_PWD');
           --v_remote_dir     VARCHAR2(50):= FND_PROFILE.VALUE('AP_CHK_FTP_DIR');
           --v_mode        VARCHAR2(50):= 'ascii';
      v_file_dir               VARCHAR2 (50)                     := '/usr/tmp';
      v_filename               VARCHAR2 (50);
   BEGIN
-------------------
-- Open output file
-------------------
      gc_current_step := ' Step: Open output file ';

      -- defect# 8750 , 8932
      SELECT 'BOA_EFT_' || SUBSTR (vendor_pay_group, 7) || '_NACHA'
        INTO gc_output_file
        FROM ap_invoice_selection_criteria
       WHERE checkrun_name = p_pay_batch;

      g_filehandle := UTL_FILE.fopen ('XXFIN_OUTBOUND', gc_output_file, 'w');
--------------------------------------------------------------------------------
-- Values below were added to the OD_AP_NACHA_DETAILS Translation table
-- to remove hardcoded values
--------------------------------------------------------------------------------
-- gc_edi_sender_id       VARCHAR2 (10) := '1592663954';
-- gc_edi_qualifier       VARCHAR2 (2)  := '01';          Prod ='01'Test ='ZZ'
-- gc_test_indicator      VARCHAR2 (1)  := 'P';           Prod ='P' Test = 'T'
-- gn_gs_edi_sender_id    VARCHAR2 (10) := '6123410000';
-- gc_file_id_modifier := This variable was added as a quick workaround do to the
--                        time constraints to have the code delivered.
--                        'A' for the first EFT output file each day.
--                        Increment to B, C, and so on for additional files sent
--                        the same day.
---------------------------------------------------------------------------------

      ----------------------------
-- Setting Program variables
----------------------------
      gc_current_step := ' Step: Setting Program variable ';

      SELECT val.source_value1            -- Vendor Name for the Amex Payments
                              ,
             val.source_value2   -- Vendor Type for the Child Garnish Payments
                              ,
             val.source_value3                                -- EDI Sender Id
                              ,
             val.source_value4                               -- Test Indicator
                              ,
             DECODE (val.source_value4, 'P', '01', 'ZZ')   -- gc_edi_qualifier
                                                        ,
             val.source_value5             -- EDI GS Sender ID (705 GS Record)
                              ,
             val.source_value6
                              -- File ID Modifier Temporary workaround default 'A'
      ,      val.source_value7                                  -- EDI Duns Id
        INTO lc_amex_vendor_name,
             lc_garnish_vendor_type,
             gc_edi_sender_id,
             gc_test_indicator,
             gc_edi_qualifier,
             gn_gs_edi_sender_id,
             gc_file_id_modifier, gn_edi_duns_id
        FROM xx_fin_translatedefinition def, xx_fin_translatevalues val
       WHERE def.translate_id = val.translate_id
         AND def.translation_name = 'OD_AP_NACHA_DETAILS'
         AND SYSDATE BETWEEN def.start_date_active
                         AND NVL (def.end_date_active, SYSDATE + 1)
         AND SYSDATE BETWEEN val.start_date_active
                         AND NVL (val.end_date_active, SYSDATE + 1)
         AND def.enabled_flag = 'Y'
         AND val.enabled_flag = 'Y';

      gc_checkrun_name := p_pay_batch;
      gn_file_amt_tot := 0;
-------------------------------
-- Setting Production variable
-------------------------------
      gc_current_step := ' Step: Setting Production variable ';
      lc_dbname := NULL;

      SELECT NAME
        INTO lc_dbname
        FROM v$database;

      IF gc_test_indicator IS NULL
      THEN
         IF UPPER (lc_dbname) = 'GSIPRDGB'
         THEN
            gc_test_indicator := 'P';
            gc_edi_qualifier := '01';
         ELSE
            gc_test_indicator := 'T';
            gc_edi_qualifier := 'ZZ';
         END IF;
      END IF;

----------------------------
-- Build File Header Record
----------------------------
   -- Both the 101 (C_FILEHEADER) and 520 (C_BATCHEADER) are created using the
   -- select statement below.
      gc_current_step := ' Step: Build File Header Record ';

      SELECT      '101'
               || LPAD (SUBSTR (NVL (abb.bank_num, '063000021'), 1, 10),
                        10,
                        ' '
                       )
               || LPAD (SUBSTR (gc_edi_sender_id, 1, 10), 10, '0')
               || TO_CHAR (SYSDATE, 'YYMMDD')
               || TO_CHAR (SYSDATE, 'HHMM')
               || gc_file_id_modifier
               || '094'
               || '101'
               || RPAD (SUBSTR (UPPER (abb.bank_name), 1, 23), 23, ' ')
               || RPAD (SUBSTR (UPPER ('OFFICE DEPOT'), 1, 23), 23, ' ')
               || RPAD (' ', 8, ' ')
                                    -- C_FILEHEADER
      ,
                  '5200'
               || RPAD (SUBSTR (UPPER ('OFFICE DEPOT'), 1, 16), 16, ' ')
               || RPAD (SUBSTR (aisc.checkrun_name, 1, 20), 20, ' ')
               || LPAD (SUBSTR (gc_edi_sender_id, 1, 10), 10, '0')
               || 'CTX'
               || RPAD (SUBSTR (UPPER (asic.checkrun_name), 1, 10), 10, ' ')
               || TO_CHAR (SYSDATE, 'MMDDYY')
               || TO_CHAR (asic.creation_date, 'YYMMDD')
               || '   '
               || '1'
               || LPAD (SUBSTR (NVL (abb.bank_num, '06300002'), 1, 8), 8, '0')
                                                                              -- C_BATCHHEADER
      ,
               NVL (abb.bank_num, '06300002')              -- BANK ROUTING Num
                                             ,
               NVL (aba.bank_account_num, 0)            -- Bank Account number
                                            ,
               NVL (SUBSTR (UPPER (abb.bank_name), 1, 15), 'BANK OF AMERICA')
          INTO lc_fileheader,
               lc_batcherheader,
               gc_bank_routing_num,
               gc_bank_account_num,
               gc_edi_id
          FROM ap_bank_branches abb,
               ap_invoice_selection_criteria aisc,
               ap_bank_accounts aba,
               ap_selected_invoice_checks asic
         WHERE aisc.bank_account_id = aba.bank_account_id
           AND aba.bank_branch_id = abb.bank_branch_id
           AND asic.checkrun_name = aisc.checkrun_name
           AND asic.ok_to_pay_flag = 'Y'
           AND asic.checkrun_name = p_pay_batch
           AND ROWNUM = 1
      ORDER BY asic.vendor_name;

--------------------------------
-- Write Header Records
--------------------------------
      gc_current_step := ' Step: Write Header Records ';
      lc_print_line := lc_fileheader;
      UTL_FILE.put_line (g_filehandle, lc_print_line);
      gn_total_record_cnt := gn_total_record_cnt + 1;
      gn_func_grp_cnt := gn_func_grp_cnt + 1;
      gn_batch_count := 0;
      gn_total_record_cnt := 0;
-------------------------------
-- Fetching Payee Header record
-------------------------------
      gc_current_step := ' Step: Fetching Payee Header record ';

      OPEN payee_cursor;

      LOOP
         FETCH payee_cursor
          INTO lc_entrydetail, ln_bank_num, lc_checkrun_name,
               ln_selected_check_id, gc_vendor_name, ln_vendor_id,
               lc_vendor_type_lk_code, lc_check_date, gc_rec_dfi_bank_id,
               gc_rec_dfi_bank_acct, gn_check_number, ln_vendor_site_id;

         EXIT WHEN payee_cursor%NOTFOUND;
         lc_print_line := lc_entrydetail;
----------------------------------
--Intialize batch trailer counters
----------------------------------
         gn_batch_total_cnt := 0;
         gn_entry_hash_num := 0;
         gn_batch_amt_tot := 0;
         gn_batch_count := gn_batch_count + 1;
         gn_detail_counter := 0;
------------------------------------
-- Calling Settlement DATE FUNCTION
------------------------------------
         gc_current_step := ' Step: Calling Settlement DATE FUNCTION ';
         lc_settle_date :=
            settle_date (ln_vendor_id,
                         ln_vendor_site_id,
                         NVL (lc_check_date, SYSDATE)
                        );         -- Added ln_vendor_site_id per defect 15436
--------------------------
--Printing of 520 records
--------------------------
         gc_current_step := ' Step: Printing of 520 records ';
         lc_print_line :=
               SUBSTR (lc_batcherheader, 1, 69)
            || NVL (lc_settle_date, TO_CHAR (SYSDATE, 'YYMMDD'))
            || SUBSTR (lc_batcherheader, 76, LENGTH (lc_batcherheader))
            || LPAD (gn_batch_count, 7, '0');
         UTL_FILE.put_line (g_filehandle, lc_print_line);
         gn_total_record_cnt := gn_total_record_cnt + 1;
--------------------------
--Printing of 622 records
--------------------------
         gc_current_step := ' Step: Printing of 622 records ';
         gn_detail_counter := gn_detail_counter + 1;
         
         /* V2.7, In case of JP Morgan, and which has credit card program
         need to change the total row count */
         
         IF gc_vendor_name = 'JP MORGAN CHASE' 
         THEN
            SELECT count(1)
              INTO ln_card_prog_count
              FROM AP_CARD_PROGRAMS
             WHERE vendor_id = ln_vendor_id
               AND vendor_site_id = ln_vendor_site_id;
            
            IF ln_card_prog_count > 0 THEN 
               jp_morgan_rec_counts(ln_vendor_id,ln_vendor_site_id,ln_count_705); 
               IF NVL(ln_count_705,0) > 0 THEN
                  lc_rec_count_705 := substr(lc_entrydetail,1,54)||lpad(ln_count_705,4,'0')||substr(lc_entrydetail,59);
                  lc_entrydetail := lc_rec_count_705;
               END IF;
            END IF; 
         END IF;
         -- V2.7 Changes end
         
         lc_print_line := lc_entrydetail || LPAD (gn_detail_counter, 7, '0');
         UTL_FILE.put_line (g_filehandle, lc_print_line);
         gn_total_record_cnt := gn_total_record_cnt + 1;
         gn_batch_total_cnt := gn_batch_total_cnt + 1;
         gn_entry_hash_num := gn_entry_hash_num + gc_rec_dfi_bank_id;
------------------------------------------------
-- Calling PAYMENT_DETIALS Proc for 705 records
------------------------------------------------
         gc_current_step := ' Step: Calling details 705 records ';
         fnd_file.put_line (fnd_file.LOG,
                            'gc_vendor_name   > ' || gc_vendor_name
                           );
         fnd_file.put_line (fnd_file.LOG,
                            'lc_vendor_name   > ' || lc_vendor_name
                           );

         IF lc_vendor_type_lk_code = lc_garnish_vendor_type
         THEN
            lc_payment_type := 'GARNSH';
            payment_details (ln_vendor_id,
                             ln_vendor_site_id,
                             lc_garnish_vendor_type,
                             lc_payment_type
                            );
         ELSIF gc_vendor_name = lc_amex_vendor_name
         THEN
            lc_payment_type := 'AMEX';
            payment_details (ln_vendor_id,
                             ln_vendor_site_id,
                             lc_garnish_vendor_type,
                             lc_payment_type
                            );
         -- Added for CR561
         ELSIF gc_vendor_name = 'JP MORGAN CHASE'
         THEN
            lc_payment_type := 'JP MORGAN';
            payment_details (ln_vendor_id,
                             ln_vendor_site_id,
                             lc_garnish_vendor_type,
                             lc_payment_type
                            );
         -- Added for CR561
         ELSE
            lc_payment_type := 'VENDOR';
            payment_details (ln_vendor_id,
                             ln_vendor_site_id,
                             lc_garnish_vendor_type,
                             lc_payment_type
                            );
         END IF;

-----------------------------------
-- Creating Batch Trialer 8 Records
-----------------------------------
         gc_current_step := ' Step: Creating Batch Trialer 8 Records ';
         lc_batch_trailer :=
               '8200'
            || LPAD (SUBSTR (((gn_batch_total_cnt)), 1, 6), 6, '0')
            || LPAD (SUBSTR (gn_entry_hash_num, 1, 10), 10, '0')
            || '000000000000'
            || SUBSTR
                  (LPAD (NVL (REPLACE (TO_CHAR (SUBSTR (gn_batch_amt_tot,
                                                        1,
                                                        13
                                                       ),
                                                '0000000000.00'
                                               ),
                                       '.',
                                       ''
                                      ),
                              '000000000000'
                             ),
                         13,
                         '0'
                        ),
                   2,
                   12
                  )
            || gc_edi_sender_id
            || '                   '
            || '      '
            || NVL (SUBSTR (gc_bank_routing_num, 1, 8), '06300002')
            || LPAD (gn_batch_count, 7, '0');
         gn_file_hash_total := gn_file_hash_total + gn_entry_hash_num;
         lc_print_line := lc_batch_trailer;
         UTL_FILE.put_line (g_filehandle, lc_print_line);
         gn_total_record_cnt := gn_total_record_cnt + 1;
      END LOOP;

------------------------------------------
--Creating and Write file 9 Trailer record
------------------------------------------
      gc_current_step := ' Step: Creating and Write 9 Trailer record ';
      lc_file_trialer :=
            '9'
         || LPAD (SUBSTR (((gn_batch_count)), 1, 6), 6, '0')
         || LPAD (SUBSTR ((CEIL ((gn_total_record_cnt + 1) / 10)), 1, 6),
                  6,
                  '0'
                 )
         || LPAD (SUBSTR ((gn_batch_count + gn_file_addenda_cnt), 1, 8),
                  8,
                  '0'
                 )
         || LPAD (SUBSTR (gn_file_hash_total, 1, 10), 10, '0')
         || '000000000000'
         || SUBSTR (LPAD (NVL (REPLACE (TO_CHAR (SUBSTR (gn_file_amt_tot,
                                                         1,
                                                         13
                                                        ),
                                                 '0000000000.00'
                                                ),
                                        '.',
                                        ''
                                       ),
                               '000000000000'
                              ),
                          13,
                          '0'
                         ),
                    2,
                    12
                   )
         || RPAD (' ', 39, ' ');
      lc_print_line := lc_file_trialer;
      UTL_FILE.put_line (g_filehandle, lc_print_line);

      CLOSE payee_cursor;

      UTL_FILE.fflush (g_filehandle);
      UTL_FILE.fclose (g_filehandle);

      DBMS_LOCK.sleep (5);
      
      -- 2.5 Required for encryption logic
      gc_output_file_dest := gc_output_file
                                     || '_'
                                     || TO_CHAR (SYSDATE, 'MMDDYYYYHH24MISS')
                                     || '.txt';
                                     
      /*
       ln_req_id := fnd_request.submit_request('XXFIN','XXCOMFILCOPY',
                      '','01-OCT-04 00:00:00',FALSE,'$XXFIN_DATA/outbound/'||
                       gc_output_file ,'$XXFIN_DATA/ftp/out/nacha/' ||
                       gc_output_file ||'_'||to_char(sysdate,'MMDDYYYYHH24MISS')||'.txt' ,'',''); */
 ----------------------------------------
--Rename and copy file to file directory
----------------------------------------
-- THE XXCOMFILECOPY concurrent program will move file from XXFIN_OUTBOUND
-- directory to the XXFIN/ftp/out/nacha directory where BPEL is monitoring
-- for the file to arrive.

      gc_current_step := ' Step: Rename and copy file to file dir ';
                       
      ln_req_id :=
         fnd_request.submit_request ('XXFIN',
                                     'XXCOMFILCOPY',
                                     '',
                                     '01-OCT-04 00:00:00',
                                     FALSE,
                                     '$XXFIN_DATA/outbound/' || gc_output_file,
                                     '$XXFIN_DATA/ftp/out/nacha/' ||gc_output_file_dest,
                                     null,
                                     null,
                                     'Y',
                                     null -- V2.9 No need to archive here -- 'N'  
                                    );
      COMMIT;
	  
	  --Below logic added for defect# 41209
	  IF ln_req_id > 0 THEN
      LOOP
            
      lb_result    := fnd_concurrent.wait_for_request (ln_req_id, 10, 200, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message);
	  
	  EXIT
        WHEN UPPER (lc_phase) = 'COMPLETED' OR UPPER (lc_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
      END LOOP;
	  END IF;
      
    
 --------------------------------------------
--2.5 Encrypt the file and place in same directory
--------------------------------------------
-- THE XXCOMENPTFILE concurrent program will encrypt the  file in the
-- directory  XXFIN/ftp/out/nacha directory where BPEL is monitoring
-- for the file to arrive.

    IF LC_STATUS !='Normal'  THEN 
       fnd_file.put_line(fnd_file.LOG,'Error:  File is not copied '|| SQLERRM ());
    ELSE     
       BEGIN
          SELECT XFTV.TARGET_VALUE1, XFTV.TARGET_VALUE2
            INTO lc_key, lc_encrypt_file_flag
            FROM xx_fin_translatedefinition XFTD ,
                 xx_fin_translatevalues XFTV
           WHERE XFTV.translate_id = XFTD.translate_id
             AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
             AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
             AND XFTV.source_value1    = 'I0438_BOA_EFT_EXP_EFT_NACHA'
             AND XFTD.translation_name = 'OD_PGP_KEYS'
             AND XFTV.enabled_flag     = 'Y'
             AND XFTD.enabled_flag     = 'Y';
             
             IF   (lc_key is not null and NVL(lc_encrypt_file_flag,'N') = 'Y' )
             THEN
                gc_current_step := ' Step: Encrypt the file in the file dir ';
      
                ln_req_id := fnd_request.submit_request  (application => 'XXFIN',
                                                      program => 'XXCOMENPTFILE' , 
                                                      argument1 => '$XXFIN_DATA/ftp/out/nacha/'
                                                                   || gc_output_file_dest,
                                                      argument2 => lc_key , 
                                                        argument3 => 'Y'
                                                      );
                COMMIT;
				--Below logic added for defect# 41209
				IF ln_req_id > 0 THEN
				LOOP
                    lb_result    := fnd_concurrent.wait_for_request (ln_req_id, 10, 200, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message);
                   
				EXIT
					WHEN UPPER (lc_phase) = 'COMPLETED' OR UPPER (lc_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
				END LOOP;
				END IF;
	  
                IF lc_status !='Normal'  THEN 
                   fnd_file.put_line(fnd_file.LOG,'Error:  File is not Encrypted '|| SQLERRM ());
                ELSE 
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'File is Encrypted ');
                END IF;
            END IF;
        EXCEPTION
          WHEN OTHERS THEN
             fnd_file.put_line(fnd_file.LOG,'Key not found '|| SQLERRM ());
        END;
     END IF;     
                
      
-- ------------------------------------
-- Update the status field to FORMATTED
-- ------------------------------------
      gc_current_step := ' Step: Update the status field to FORMATTED ';

      UPDATE ap_inv_selection_criteria_all
         SET status = 'FORMATTED'
       WHERE checkrun_name = p_pay_batch;

      COMMIT;
      gc_current_step := NULL;
   EXCEPTION
      WHEN UTL_FILE.invalid_mode
      THEN
         fnd_file.put_line (fnd_file.LOG, 'utl_file.Invalid Mode Parameter');
         retcode := 1;
      WHEN UTL_FILE.invalid_path
      THEN
         fnd_file.put_line (fnd_file.LOG, 'utl_file.Invalid File Location');
         retcode := 1;
      WHEN UTL_FILE.invalid_filehandle
      THEN
         fnd_file.put_line (fnd_file.LOG, 'utl_file.Invalid Filehandle');
         retcode := 1;
      WHEN UTL_FILE.invalid_operation
      THEN
         fnd_file.put_line (fnd_file.LOG, 'utl_file.Invalid Operation');
         retcode := 1;
      WHEN UTL_FILE.read_error
      THEN
         fnd_file.put_line (fnd_file.LOG, 'utl_file.Read Error');
         retcode := 1;
      WHEN UTL_FILE.internal_error
      THEN
         fnd_file.put_line (fnd_file.LOG, 'utl_file.Internal Error');
         retcode := 1;
      WHEN UTL_FILE.charsetmismatch
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'utl_file.Opened With FOPEN_NCHAR ');
         retcode := 1;
      WHEN UTL_FILE.file_open
      THEN
         fnd_file.put_line (fnd_file.LOG, 'utl_file.File Already Opened');
         retcode := 1;
      WHEN UTL_FILE.invalid_maxlinesize
      THEN
         fnd_file.put_line (fnd_file.LOG, 'utl_file.Line Size Exceeds 32K');
         retcode := 1;
      WHEN UTL_FILE.invalid_filename
      THEN
         fnd_file.put_line (fnd_file.LOG, 'utl_file.Invalid File Name');
         retcode := 1;
      WHEN UTL_FILE.access_denied
      THEN
         fnd_file.put_line (fnd_file.LOG, 'utl_file.File Access Denied By');
         retcode := 1;
      WHEN UTL_FILE.invalid_offset
      THEN
         fnd_file.put_line (fnd_file.LOG, 'utl_file.FSEEK Param Less Than 0');
         retcode := 1;
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Other Exception' || SQLERRM ());
         retcode := 1;
         errbuff := gc_current_step;
   END;
END XX_AP_EFTNACHABOA_PKG;
/

show err;

exit;
