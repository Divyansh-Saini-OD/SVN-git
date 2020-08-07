SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT CREATING PACKAGE BODY XX_AR_LOCKBOX_PROCESS_PKG
PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE

create or replace
PACKAGE BODY      XX_AR_LOCKBOX_PROCESS_PKG AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Providge Consulting                                  |
-- +=================================================================================+
-- | Name       : xx_ar_lockbox_process_pkg.pks                                      |
-- | Description: AR Lockbox Custom Auto Cash Rules E0062-Extension                  |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- | 1.0      07-AUG-2007  Shiva Rao/SunayanM Initial draft version                  |
-- | 1.1      28-MAR-2008  Sai Bala           Defect 5787                            |
-- | 1.2      10-MAY-2008  Sai Bala           Added Auto Cash Rule Totals Report     |
-- | 1.3      01-JUN-2008  Sandeep Pandhare   Defect 7547                            |
-- | 1.4      24-JUN-2008  Brian J Looman     Defect 8311 - delete old trxns from    |
-- |                                            XX_AR_PAYMENTS_INTERFACE             |
-- | 1.5      11-AUG-2008  Brian J Looman     Defect 9686 - fixed Partial invoice    |
-- |                                            matching logic, removed amount match |
-- | 1.6      29-Apr-2009  Shobana S          Defect 14630                           |
-- | 1.7      06-JUL-2009  P.Suresh           Defect 407.                            |
-- | 1.8      22-JUL-2009  P.Suresh           Defect 954 - Added new derivation for  |
-- |                                          customer number.                       |
-- |                                          Defect 955 - Used deposit date to      |
-- |                                          populate creation_date.                |
-- | 1.9      03-AUG-2009  R.Aldridge         Defect 954 - Adjust derivation logic   |
-- |                                          for invalid cust# (EBS and AOPS)       |
-- | 1.10     16-SEP-2009  Vinaykumar S       Defect 2063 - To display Parent ID and |
-- |                                          pause the main program when the child  |
-- |                                          program is executing                   |
-- | 1.11     02-OCT-2009  Aravind A          Defect 2063                            |
-- | 1.12     22-OCT-2009  RamyaPriya M       Modified for the CR #684 --            |
-- |                                          (Defect #976,#1858)                    |
-- | 1.13     26-NOV-2009  RamyaPriya M       Modified for Defect #976 -- Added Hint |
-- | 1.14     01-DEC-2009  Aravind A          Defect 3316 invoke BPEL process to     |
-- |                                          release ESP jobs                       |
-- | 1.15     11-DEC-2009  RamyaPriya M       Modified for the CR #684 --            |
-- |                                          (Defect #976,#1858)                    |
-- | 1.16     17-DEC-2009  RamyaPriya M       Modified for the CR #684 --Defect #976 |
-- | 1.17     22-DEC-2009  RamyaPriya M       Modified for the Defect #976           |
-- | 1.18     31-DEC-2009  Bhuvaneswary S     Updated for defect 1486 CR 642 R1.2    |
-- | 1.18     06-JAN-2010  RamyaPriya M       Modified for the Defect #2063          |
-- | 1.19     08-JAN-2010  Sambasiva Reddy D  Modified for the Defect #3913          |
-- | 1.20     26-JAN-10    RamyaPriya M       Modified for the Defect #3983,#4005    |
-- | 1.21     27-JAN-10    RamyaPriya M       Modified for the Defect #4128          |
-- | 1.22     01-FEB-10    RamyaPriya M       Modified for the Defect #3984          |
-- | 1.23     02-FEB-10    Sambasiva Reddy D  Modified for the Defect # 3983, 3984   |
-- | 1.24     03-FEB-10    Sambasiva Reddy    Modified for the Defect # 4287         |
-- | 1.25     03-FEB-10    Sambasiva Reddy D  Modified for the Defect # 4284         |
-- | 1.26     04-FEB-10    RamyaPriya M       Modified for the Defect # 3984         |
-- | 1.27     05-FEB-10    Sambasiva Reddy D  Modified for the Defect # 4064         |
-- | 1.28     10-FEB-10    Sambasiva Reddy D  Modified for the Defect # 4064         |
-- |                                          separted the lcu_get_trx_number        |
-- |                                          UNION ALL made it into two cursors     |
-- | 1.29     11-FEB-10    P.Sankaran         For the LCU_GET_TRX_NUMBER cursor,     |
-- |                                          remove criteria to check for status    |
-- |                                          OP and AMOUNT_DUE_REMAINING <> 0.      |
-- |                                          Also, create a separate cursor for     |
-- |                                          back orders as the criterion changes   |
-- |                                          above do not apply for back orders.    |
-- | 1.30     12-FEB-10    RamyaPriya M       Modified for the Defect #3983          |
-- | 1.31     12-FEB-10    Sambasiva Reddy D  Removed printing_original_date check   |
-- |                                          from LCU_GET_TRX_NUMBER cursor         |
-- | 1.32     12-FEB-10    P.Sankaran         Added more log messages for debugging  |
-- | 1.33     15-FEB-10    P.Sankaran         Added a DELETE statement to cleanup    |
-- |                                          the customer relationship array        |
-- | 1.34     01-Apr-10    Ray Strauss        CR 752 DEFECT 3198 - copy incoming     |
-- |                                          data to XX_AR_INBOUND_LOCKBOX_DATA for |
-- |                                          reporting purposes                     |
-- | 1.35     16-MAR-10    Sundaram S         Modified for the Defect #4720          |
-- | 1.36     16-MAR-10    RamyaPriya M       Modified for the Defect #2033          |
-- | 1.37     07-APR-10    Sundaram S         Modified for the defect #5071          |
-- | 1.38     09-APR-10    RamyaPriya M       Modified for the Defect #4320          |
-- | 1.39     10-APR-10    Sundaram S         Modified for the Defect #2033          |
-- | 1.40     19-APR-10    RamyaPriya M       Modified for the Defect #4720          |
-- | 1.41     19-APR-10    RamyaPriya M       Modified for the Defect #4720          |
-- |                                          To Perform BO Match for 9 digit alone  |
-- | 1.42     21-Apr-10    Sundaram S         Modified for the Defect #5071          |
-- |                                          To purge data if there is no 9 Record  |
-- | 1.43     22-Apr-10    Sundaram S         Modified for the Defect #2033          |
-- |                                          Modified to populate File name in '4'  |
-- | 1.44     22-Apr-10    Sambasiva Reddy D  Modified for the Defect #4720          |
-- |                                          commented amount match for 12 digit    |
-- |                                          rule                                   |
-- | 1.45     27-Apr-10    Sambasiva Reddy D  Modified for the Defect #4320          |
-- |                                          Modified the code for SQL loader       |
-- |                                          when it completed in error or warning  |
-- | 1.46     27-Sep-10    Sundaram S         Modified the code for defect# 8065     |
-- | 1.47     16-May-11    Deepti S           Modified the code for CR#872           |
-- |          02-Jun-11    Gaurav Agarwal     Hint index added by Gaurav Agarwal for |
-- |                                          performance defect # 11818             |
-- |          10-Jun-11    Gaurav Agarwal     changes for defcet 11971 AR - for CR872|
-- |                                          need to allow multiple ACH Sending IDs |
-- |                                          to one OD Customer                     |
-- | 1.48     08-Aug-11    Sunildev           Transfer output file to XNET           |
-- | 1.49     11-Aug-11    Saikumar Reddy     Commented ANY_COMBO procedure call in  |
-- |                       (595997)           procedure auto_cash_match_rules for    |
-- |                                          defect# 13069                          |
-- | 1.50     21-Oct-11    P.Sankaran         - Use interim table for open trans     |
-- |                                          - Update 999999x '4' records           |
-- | 1.51     11-JAN-12    P.Sankaran         Performance fix in the cursor          |
-- |                                          LCU_GET_CUSTOMER_TRX_ALL to drive off  |
-- |                                          XX_AR_LOCKBOX_INTERIM table to look    |
-- |                                          for related customer transactions.     |
-- | 1.52     11-JAN-12    P.Sankaran         Defect 16200 - Increase LC_AC_ERR_MSG  |
-- |                                          variable from 1000 to 4000 characters  |
-- |                                          for numeric or value error occurring   |
-- |                                          in custom_auto_cash.  Also, initalized |
-- |                                          back order count field to 5 as default.|
-- | 1.53     11-JAN-12    P.Sankaran         Changed all joins to drive of          |
-- |                                          XX_AR_LOCKBOX_INTERIM table before     |
-- |                                          using primary index on RA_CUSTOMER_TRX |
-- |                                          preventing reads from old partitions.  |
-- | 1.54     12-SEP-12    B.Nanapaneni       Defect#19194 code added by Gaurav      |
-- | 1.55     31-JUL-13    Deepak V           E0062 - Changed for R12 Upgrade retrofit |  
-- |                                          Changed the valid_customer proc to use |
-- |                                          IBY table instead of ap_bank_account   |
-- |                                          for R12 retrofit changes.              |
-- | 1.56     15-DEC-13    Deepak V           QC Defect 26700                        |
-- | 1.57     11-Feb-14    Deepak V           QC Defect 28062. Included BANKACCOUNT  |
-- |                                          condition.                             |
-- | 1.58     22-OCT-15    Vasu Raparla       Removed Schema References for R12.2    |
-- | 1.59     12-NOV-18    Sahithi kunuru     Changed logic for match invoice from   |
-- |                                          12 digits to 11 digits NAIT-72199      |
-- +=================================================================================+
  -- -------------------------------------------
  -- Global Variables
  -- -------------------------------------------
  gn_request_id               NUMBER        :=  FND_GLOBAL.CONC_REQUEST_ID;
  gn_user_id                  NUMBER        :=  FND_GLOBAL.USER_ID;
  gn_login_id                 NUMBER        :=  FND_GLOBAL.LOGIN_ID;
  gn_org_id                   NUMBER        :=  FND_PROFILE.VALUE('ORG_ID');
  gn_set_of_bks_id            NUMBER        :=  FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');
  gc_conc_short_name          VARCHAR2(60)  :=  'XX_AR_LOCKBOX_PROCESS_MAIN';
  gc_lb_bai_translation       VARCHAR2(50)  := 'AR_LOCKBOX_BAI_FILES';
  gn_error                    NUMBER        :=  2;
  gn_warning                  NUMBER        :=  1;
  gn_normal                   NUMBER        :=  0;
  gn_cur_precision            fnd_currencies.precision%TYPE;
  gn_cur_mult_dvd             NUMBER;
  gc_file_name                xx_ar_payments_interface.FILE_NAME%TYPE;  -- Added for Defect # 4284
  gn_global_cnt               NUMBER        := 0;
-------------------------------------------------
--Start of changes -- For CR #684 -- Defect #1858
-------------------------------------------------
  gn_tot_cust_removed         NUMBER := 0;
  ln_count                    NUMBER :=1;
  TYPE CustnumList  IS TABLE OF xx_ar_payments_interface.customer_number%TYPE INDEX BY BINARY_INTEGER;
  TYPE ChecknumList IS TABLE OF xx_ar_payments_interface.check_number%TYPE INDEX BY BINARY_INTEGER;
  TYPE AmountList   IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE MICRnumList  IS TABLE OF VARCHAR2(150) INDEX BY BINARY_INTEGER;
  TYPE MICRCustnumList IS TABLE OF hz_cust_accounts_all.account_number%TYPE INDEX BY BINARY_INTEGER;
  gt_cust_number        CustnumList;
  gt_check_number       ChecknumList;
  gt_check_amt          AmountList;
  gt_micr_num           MICRnumList;
  gt_micr_cust_num      MICRCustnumList;
-------------------------------------------------
--End of changes -- For CR #684 -- Defect #1858
-------------------------------------------------
------------------------------------
--Start of changes for Defect #3983
------------------------------------
   TYPE BO_Invoice_record IS RECORD(customer_number      hz_cust_accounts.account_number%TYPE
                                   ,check_number         VARCHAR2(30)
                                   ,invoice_number       VARCHAR2(50)
                                   ,invoice_amount       NUMBER
                                   ,sub_invoice_number   VARCHAR2(50)
                                   ,sub_invoice_amount   NUMBER
                                   );

   TYPE BO_invoice_type IS TABLE OF BO_Invoice_record INDEX BY BINARY_INTEGER;

   gt_bo_invoice                   BO_invoice_type;
   gn_bo_count                     NUMBER :=1;
   gn_tot_bo_inv_processed         NUMBER := 0;
----------------------------------
-- End of changes for Defect #3983
----------------------------------
-------------------------------------
-- Start of Changes for Defect #3984
-------------------------------------
   TYPE discount_rec_type IS RECORD( term_id                     ra_terms_lines.term_id%TYPE
                                    ,sequence_num                ra_terms_lines.sequence_num%TYPE
                                    ,due_days                    ra_terms_lines.due_days%TYPE
                                    ,due_day_of_month            ra_terms_lines.due_day_of_month%TYPE
                                    ,discount_day_of_month       ra_terms_lines_discounts.discount_day_of_month%TYPE
                                    ,discount_months_forward     ra_terms_lines_discounts.discount_months_forward%TYPE
                                    ,discount_percent            ra_terms_lines_discounts.discount_percent%TYPE
                                    ,discount_days               ra_terms_lines_discounts.discount_days%TYPE
                                   );
  TYPE discount_rec_tbl_type IS TABLE OF discount_rec_type INDEX BY BINARY_INTEGER;
  lcu_discount_rec_tbl          discount_rec_tbl_type;
  ------------------------------------

  gn_ncr_request_id           NUMBER        := NVL(FND_GLOBAL.CONC_REQUEST_ID, DBMS_RANDOM.random() );
  ld_deposit_date             DATE;
  GB_DEBUG                    BOOLEAN         DEFAULT TRUE;  -- print debug/log output
--
-- Sai - 05/11/2008 to calculate totals for all matches, per Damon
--
  TYPE match_record IS RECORD
  ( match_status             varchar2(100) --xx_ar_payments_interface.inv_match_status%TYPE
   ,check_count              NUMBER
   ,tot_amount               NUMBER
   ,total_check_match        NUMBER
   ,inv_paid_this_type       NUMBER
   ,dollar_paid_this_type    NUMBER
   ,match_by_units           NUMBER
   ,match_by_dollars         NUMBER );

  TYPE match_table_type IS TABLE OF match_record INDEX BY BINARY_INTEGER;

  gt_match_details            match_table_type;

-- ==========================================================================
-- procedure to turn on/off debug
-- ==========================================================================
PROCEDURE set_debug
( p_debug      IN      BOOLEAN       DEFAULT TRUE )
IS
BEGIN
  GB_DEBUG := p_debug;
END;

-- ==========================================================================
-- procedure for printing to the log
-- ==========================================================================
PROCEDURE put_log_line
( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
IS
BEGIN
  --if debug is on (defaults to true)
  IF (GB_DEBUG) THEN
    -- if in concurrent program, print to log file
    IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
      FND_FILE.put_line(FND_FILE.LOG,NVL(p_buffer,' '));
    -- else print to DBMS_OUTPUT
    ELSE
      DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
    END IF;
  END IF;
END;

-- -------------------------------------------
-- Declare Private Procedures for Print Output
-- -------------------------------------------
-- Declare Procedure Print Messag Header
PROCEDURE print_message_header
(x_errmsg                 OUT   NOCOPY  VARCHAR2
,x_retstatus              OUT   NOCOPY  NUMBER );

-- Declare Procedure Print Messag Footer
PROCEDURE print_message_footer
(x_errmsg                 OUT   NOCOPY  VARCHAR2
,x_retstatus              OUT   NOCOPY  NUMBER
,p_customer_id            IN            NUMBER
,p_check                  IN            VARCHAR2
,p_transaction            IN            VARCHAR2
,p_tran_amount            IN            NUMBER
,p_sub_amount             IN            NUMBER
,p_sub_invoice            IN            VARCHAR2 );

-- Declare Procedure Print Messag Summary
PROCEDURE print_message_summary
(x_errmsg                OUT   NOCOPY  VARCHAR2
 ,x_retstatus             OUT   NOCOPY  NUMBER
 ,p_tot_inv_bnk           IN            NUMBER
 ,p_tot_inv_match         IN            NUMBER
 ,p_tot_amt_match         IN            NUMBER  );

-- Declare Procedure Print Autocash Process Report
PROCEDURE print_autocash_report
(x_errmsg                OUT   NOCOPY  VARCHAR2
 ,x_retstatus             OUT   NOCOPY  NUMBER
 ,p_process_num           IN            VARCHAR2
 ,p_status                IN            VARCHAR2
 ,pn_match_status_count   IN           NUMBER );

-- Declare Procedure Print Customer Validation Report --Added for CR#684 -- Defect #1858 on 11-DEC-09
PROCEDURE print_cust_validation_report
(x_errmsg                OUT   NOCOPY  VARCHAR2
 ,x_retstatus             OUT   NOCOPY  NUMBER);

 -- Declare Procedure Print BO_INVOICE_STATUS_REPORT  --Added for Defect #3983
PROCEDURE bo_invoice_status_report
(x_errmsg                OUT   NOCOPY  VARCHAR2
 ,x_retstatus             OUT   NOCOPY  NUMBER);

 -- Declare Procedure xx_matched_invoices  --Added for Defect #2033
PROCEDURE xx_matched_invoices
( p_trx_number       IN   VARCHAR2
 ,p_ins_flag         IN   VARCHAR2
 ,p_trx_not_exist    OUT  VARCHAR2);
-- =============================
-- Added for the Defect #4320
-- =============================
PROCEDURE LOCKBOX_PROCESS_MAIN
( x_errbuf                 OUT   NOCOPY  VARCHAR2
 ,x_retcode                OUT   NOCOPY  NUMBER
 ,p_filename                IN            VARCHAR2
 ,p_email_notf              IN            VARCHAR2  DEFAULT NULL
 ,p_check_digit             IN            NUMBER
 ,p_trx_type                IN            VARCHAR2  DEFAULT NULL
 ,p_trx_threshold           IN            NUMBER    DEFAULT NULL
 ,p_from_days               IN            NUMBER    DEFAULT NULL
 ,p_to_days                 IN            NUMBER    DEFAULT NULL
 ,p_debug_flag              IN            VARCHAR2  DEFAULT 'Y'
 ,p_back_order_configurable IN            NUMBER    DEFAULT 5
)
IS
---+===============================================================================================
---|  This procedure will be registered as a concurrent program which will be called by a BPEL
---|  process. The procedure will validate if the file has already been processed and report the error
---|  if required. It calls the procedure LOCKBOX_AUTOCASH_RULES to apply the custom auto cash rules.
---|  After all the validation is successfull it calls the Standard Lockbox process with the appropriate
---|  parameters.
---+===============================================================================================

---+===============================================================================================
---|  Define the cursor to select the locbox numbers for the given process number
---+===============================================================================================
  CURSOR Lockbox_num_cur(p_cur_process_num VARCHAR2)
  IS
    SELECT DISTINCT lockbox_number
    FROM   xx_ar_payments_interface
    WHERE  process_num = p_cur_process_num
    AND    record_type = '5';

  Lockbox_num_rec      Lockbox_num_cur%ROWTYPE;

  lc_err_mesg          VARCHAR2(1000);
  lc_err_status        VARCHAR2(20);
  lc_err_pos           VARCHAR(20);
  lc_dummy             VARCHAR2(10);
  ln_trans_for_id      NUMBER;
  lc_request_data      VARCHAR2(120);
  ld_dep_date          DATE;
  lc_lb_wait           BOOLEAN;
  lc_conc_phase        VARCHAR2(100);
  lc_conc_status       VARCHAR2(100);
  lc_dev_phase         VARCHAR2(100);
  lc_dev_status        VARCHAR2(100);
  lc_conc_message      VARCHAR2(100);
  ln_ldr_req_id        NUMBER;
  ln_lck_req_id        NUMBER;
  ln_lockbox_id        NUMBER;
  lc_req_bil_loc       VARCHAR2(20);
  lc_lck_filename      VARCHAR2(200);
  lc_compl_stat        BOOLEAN;
  lc_rcpt_proc_name    VARCHAR2(100);
  ln_tran_rec_cnt      NUMBER;
  ln_tran_amt          NUMBER;
  lc_trans_name        VARCHAR2(60);
  lc_ac_err_msg        VARCHAR2(4000);       /* Defect 16200 - Numeric or value error */
  lc_trx_type          VARCHAR2(30);

  lc_control_file      VARCHAR2(200);
  lc_program_name      VARCHAR2(200);
  lc_file_suffix       VARCHAR2(200);
  ln_prog_appl_id      NUMBER;
  ln_conc_prog_id      NUMBER;
  ln_load_count        NUMBER;
  ln_rec_count         NUMBER;
  ln_check_index       NUMBER;
  ln_tolerance         NUMBER;

  ln_ac_ret_code       NUMBER;
  ln_mail_request_id   NUMBER;
  ln_check_digit       NUMBER;
  ln_trx_threshold     NUMBER;
  ln_from_days         NUMBER;
  ln_to_days           NUMBER;

  lc_holiday_flag      VARCHAR2(1);
  lc_holiday_enabled   VARCHAR2(1);
  ld_deposit_day       VARCHAR2(10);
  ld_deposit_year      VARCHAR2(4);
  ld_gl_date           DATE;
  lc_chk_flag          VARCHAR2(120);
  ln_err_cnt           NUMBER;
  ln_wrn_cnt           NUMBER;
  ln_nrm_cnt           NUMBER;
  EX_MAIN_EXCEPTION    EXCEPTION;

  TYPE BatchList IS TABLE OF XX_AR_PAYMENTS_INTERFACE.BATCH_NAME%TYPE;
  TYPE ItemList  IS TABLE OF XX_AR_PAYMENTS_INTERFACE.ITEM_NUMBER%TYPE;
  TYPE InvoiceList IS TABLE OF XX_AR_PAYMENTS_INTERFACE.INVOICE1%TYPE;
  TYPE AmountList  IS TABLE OF XX_AR_PAYMENTS_INTERFACE.AMOUNT_APPLIED1%TYPE;
  l_batch_name  BatchList;
  l_item_number ItemList;
  l_invoice     InvoiceList;
  l_amount      AmountList;

  --Added the following parameters for Defect #12526, these params are used to submit XPTR transfer
  lc_xptr_name       xx_fin_translatevalues.target_value1%TYPE;
  l_file_name        fnd_concurrent_requests.outfile_name%TYPE;
  l_out_dir          VARCHAR2(100);
  lp_filename        VARCHAR2(50);
  l_request_id       NUMBER;


BEGIN

---+================
  -- set debug flag
---+================
    IF (NVL(p_debug_flag,'Y') = 'Y') THEN
      set_debug(TRUE);
    ELSE
      set_debug(FALSE);
    END IF;

    put_log_line('[BEGIN] LOCKBOX_PROCESS_MAIN - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

    gn_ncr_request_id  := NVL(FND_GLOBAL.CONC_REQUEST_ID, DBMS_RANDOM.random() );    -- get current request_id

    lc_lck_filename := SUBSTR(p_filename,INSTR(p_filename,'/',-1)+1);
    lc_trans_name   := SUBSTR(lc_lck_filename,1,30);
    gc_file_name    := lc_lck_filename;  --Added for Defect #2033 on 22-Apr-10

    lc_chk_flag := FND_CONC_GLOBAL.request_data;

    put_log_line('[WIP] Request_data - '||lc_chk_flag );

---+===============================================================================================
-- |  Step #1 -- FIRST
---+===============================================================================================

  IF (NVL(SUBSTR(lc_chk_flag,1,INSTR(lc_chk_flag,'-',1)-1),'FIRST') ='FIRST') THEN

---+===============================================================================================
---|  Select the transmission format ID
---+===============================================================================================
    lc_err_pos := 'LCK-1001';
    put_log_line('[WIP] Transmission Format ID Check - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

      BEGIN
        SELECT transmission_format_id
          INTO ln_trans_for_id
          FROM ar_transmission_formats
         WHERE format_name = 'OD_US LOCKBOX'
           AND status_lookup_code = 'A';

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lc_err_status := 'Y';
            lc_err_mesg := 'The Transmission format OD_US BOA LOCKBOX is NOT defined';
            RAISE_APPLICATION_ERROR ( -20001,lc_err_mesg);
        END;


---+========================================================================================================
---|  Check if the transmission is already created for this datafile and set the status as 'NEW' for new trans
---+========================================================================================================

    lc_err_pos := 'LCK-1002';
    put_log_line('[WIP] Transmission Already Exists Check - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
      BEGIN
        SELECT 'x'
          INTO   lc_dummy
          FROM   ar_transmissions_all
         WHERE  transmission_name = lc_trans_name;

        lc_err_status := 'Y';
        lc_err_mesg := 'The File: '||lc_lck_filename||' has already been processed.';
        RAISE_APPLICATION_ERROR ( -20002,lc_err_mesg);

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        put_log_line('The File:  '||lc_lck_filename||'  is a NEW Transmission');
      END;

---+===============================================================================================
---|  Determine the SQL*Loader concurrent program to execute for the given file (using translations)
---+===============================================================================================

    lc_err_pos := 'LCK-1002B';

    put_log_line('[WIP] Lockbox Translations - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

    put_log_line('Get the Translation values for the BAI File being processed...');
    put_log_line('  File Name = ' || lc_lck_filename );
    put_log_line('  Translation = ' || gc_lb_bai_translation );

    gc_file_name := lc_lck_filename;

      BEGIN
         SELECT tv.source_value1 control_file_suffix,
                tv.target_value1 concurrent_program
         INTO   lc_file_suffix,
                lc_program_name
         FROM   xx_fin_translatedefinition td,
                xx_fin_translatevalues tv
         WHERE  td.translate_id = tv.translate_id
         AND    td.translation_name = gc_lb_bai_translation
         AND    lc_lck_filename LIKE '%' || tv.source_value1 || '.txt%';

         put_log_line('  File Name Suffix = ' || lc_file_suffix );
         put_log_line('  Concurrent Program = ' || lc_program_name );
      EXCEPTION
         WHEN OTHERS THEN
         lc_err_status := 'Y';
         lc_err_mesg := 'The Translation has not be defined for this bank BAI file.' || chr(10)
          || ' ( File Name = ' || lc_lck_filename || chr(10)
          || ' Translation = ' || gc_lb_bai_translation || ' ) ' ;
         RAISE_APPLICATION_ERROR (-20003,lc_err_mesg);
      END;

---+===============================================================================================
---|  Validate the SQL*Loader concurrent program defined in the Translation
---+===============================================================================================

        lc_err_pos := 'LCK-1002C';
        put_log_line('Validate Concurrent Program and that it is a SQL*Loader executable');

        BEGIN
          SELECT fcp.application_id,
                 fcp.concurrent_program_id,
                 fe.execution_file_name
            INTO ln_prog_appl_id,
                 ln_conc_prog_id,
                 lc_control_file
            FROM fnd_concurrent_programs fcp,
                 fnd_executables fe
           WHERE fcp.executable_application_id = fe.application_id
             AND fcp.executable_id = fe.executable_id
             AND fe.execution_method_code = 'L'  -- only SQL*Loader
             AND fcp.concurrent_program_name = lc_program_name;

        put_log_line('  Control File Name = ' || lc_control_file );

        EXCEPTION
          WHEN OTHERS THEN
            lc_err_status := 'Y';
            lc_err_mesg := 'The Concurrent Program for this Translation is not a valid SQL*Loader program.' || chr(10)
               || ' ( Program Name = ' || lc_program_name || ' ) ' ;
            RAISE_APPLICATION_ERROR (-20004,lc_err_mesg);
        END;

---+===============================================================================================
---|  Verify that another SQL*Loader program is not running for this same file (lockbox)
---+===============================================================================================

        lc_err_pos := 'LCK-1002D';

        ln_check_index := 0;
        ln_tolerance := 6;

     LOOP
           ln_load_count := 0;
           ln_rec_count := 0;
           ln_check_index := ln_check_index + 1;

        BEGIN
           SELECT COUNT(1)
             INTO ln_load_count
             FROM fnd_concurrent_requests
            WHERE program_application_id = ln_prog_appl_id
              AND concurrent_program_id = ln_conc_prog_id
              AND phase_code IN ('P','R');  -- Pending or Running requests
        EXCEPTION
           WHEN OTHERS THEN
             ln_load_count := 0;
        END;

        IF (ln_load_count = 0) THEN
          BEGIN
            SELECT COUNT(1)
              INTO ln_rec_count
              FROM xx_ar_payments_interface
             WHERE process_num = 'RCT-BATCH'
               AND file_name = lc_file_suffix;
          EXCEPTION
            WHEN OTHERS THEN
              ln_rec_count := 0;
          END;
        END IF;

        EXIT WHEN (ln_load_count = 0 AND ln_rec_count = 0) OR ln_check_index >= ln_tolerance;

        put_log_line('[WIP] Wait on existing SQL*Loader (try #' || ln_check_index || ') - '
          || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
       DBMS_LOCK.sleep(10);  -- wait 10 seconds, and try again
     END LOOP;

      IF (ln_load_count > 0) THEN
        lc_err_status := 'Y';
        lc_err_mesg := 'SQL*Loader is already running for the same lockbox/BAI File (suffix). ' ||
                       ' Please wait for the other SQL*Loader program to complete.' || chr(10) ||
                       '  File Name Suffix = ' || lc_file_suffix;
        RAISE_APPLICATION_ERROR ( -20005,lc_err_mesg);
      END IF;

      IF (ln_rec_count > 0) THEN
        lc_err_status := 'Y';
        lc_err_mesg := 'Old/Bad data exists in XX_AR_PAYMENTS_INTERFACE for the same' ||
                       ' lockbox/BAI File (suffix). .  Please purge this old/bad data.' || chr(10) ||
                       '  File Name Suffix = ' || lc_file_suffix;
        RAISE_APPLICATION_ERROR ( -20006,lc_err_mesg);
      END IF;

---+===============================================================================================
---|  If it is a new transmission then submit the Loader process to insert the records into the
---|  table XX_AR_PAYMENTS_INTERFACE
---+===============================================================================================

      lc_err_pos := 'LCK-1003';

      put_log_line('[WIP] Submit SQL*Loader - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

              ln_ldr_req_id :=  FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                           ,lc_program_name
                                                           ,''
                                                           ,SYSDATE
                                                           ,TRUE
                                                           ,p_filename
                                                           );
              COMMIT;
             lc_request_data := 'COMPLETE'||'-'||lc_file_suffix||'-'||ln_trans_for_id;

             put_log_line('[WIP] Pause on the Main Program ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );     
             -- Added for defect 2063
             put_log_line('[WIP] SQL Loader Request ID '||ln_ldr_req_id);                                        -- Added for defect 2063

             FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=> lc_request_data);                     -- Added for defect 2063
             put_log_line('[WIP] Checking the status of Main Program');                                         -- Added for defect 2063
             COMMIT;
             RETURN;
  END IF;
-------------------
--Step #1 -- Ends
-------------------

---+===============================================================================================
---|  Create a unique process name for the file, every record for a given file will have a default
---|  value of 'RCT-BATCH' in the process_num column
---+===============================================================================================
-------------------
--Step #2 -- Starts
-------------------
 IF (NVL(SUBSTR(lc_chk_flag,1,INSTR(lc_chk_flag,'-',1)-1),'FIRST') ='COMPLETE') THEN

---+==================================================================
---|  Update XX_AR_PAYMENTS_INTERFACE records with Process Name and Num
---+==================================================================

       lc_err_pos := 'LCK-1004';

       put_log_line('[WIP] Update XX_AR_PAYMENTS_INTERFACE records - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

       SELECT 'RCT'||to_char(sysdate,'DDMMHH24MISS')||'-'||gn_ncr_request_id
       INTO  lc_rcpt_proc_name
       FROM  dual;

       lc_file_suffix  := SUBSTR(lc_chk_flag
                                ,INSTR(lc_chk_flag,'-',1,1)+1
                                ,(INSTR(lc_chk_flag,'-',1,2) - INSTR(lc_chk_flag,'-',1,1))-1
                                );
       ln_trans_for_id := SUBSTR(lc_chk_flag,INSTR(lc_chk_flag,'-',-1)+1);

       put_log_line('File Suffix -- '    || lc_file_suffix);
       put_log_line('Transmission ID -- '|| ln_trans_for_id);

       UPDATE xx_ar_payments_interface
          SET process_num = lc_rcpt_proc_name,
              file_name   = lc_lck_filename
        WHERE process_num = 'RCT-BATCH'
          AND file_name   = lc_file_suffix;

       COMMIT;

---+===================================
---|  Check SQL*Loader Program Status
---+===================================

     lc_err_pos := 'LCK-1005';

     put_log_line('Check SQL*Loader Program Status - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

     BEGIN
          SELECT SUM(CASE WHEN status_code = 'E'
                          THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN status_code = 'G'
                          THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN status_code = 'C'
                          THEN 1 ELSE 0 END)
          INTO   ln_err_cnt
                ,ln_wrn_cnt
                ,ln_nrm_cnt
          FROM   fnd_concurrent_requests
          WHERE  priority_request_id = gn_request_id;

--          IF (ln_err_cnt > 0) OR (ln_wrn_cnt > 0 AND ln_err_cnt = 0) THEN   -- Commented for Defect # 4320 on 4/27/2010
          IF (ln_err_cnt > 0 OR ln_wrn_cnt > 0 ) THEN  -- Added for Defect # 4320 on 4/27/2010
             put_log_line('SQL * Loader Program ended in Error/Warning');
             lc_err_mesg := 'SQL * Loader Program ended in Error/Warning';
             x_errbuf    := 'SQL * Loader Program ended in Error/Warning';
-- ======================
-- Purge Interface table
-- ======================
             DELETE FROM xx_ar_payments_interface
             WHERE process_num = lc_rcpt_proc_name
             AND   file_name   = lc_lck_filename;
             put_log_line('Number of records SQL * Loader Program purged --  ' || SQL%ROWCOUNT);
             COMMIT;
             RAISE_APPLICATION_ERROR ( -20007,lc_err_mesg);
          END IF;
     EXCEPTION
          WHEN OTHERS THEN

        -- Added IF Block for Defect # 4320 on 4/27/2010
            IF (ln_err_cnt > 0 OR ln_wrn_cnt > 0 ) THEN

                RAISE_APPLICATION_ERROR ( -20007,lc_err_mesg);

            END IF;
             put_log_line('Error @ SQL *LOADER Programs Status Check');
             lc_err_mesg := 'Error @ SQL *LOADER Programs Status Check';
             x_errbuf    := 'Error @ SQL *LOADER Programs Status Check';
     END;

---+========================================================
---|  Get transmission count and totals from record type 9
---+========================================================

     lc_err_pos := 'LCK-1006';

     put_log_line('[WIP] Get transmission count/totals - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

    BEGIN
      SELECT transmission_record_count
            ,transmission_amount
        INTO ln_tran_rec_cnt
            ,ln_tran_amt
        FROM xx_ar_payments_interface
       WHERE record_type = '9'
         AND process_num = lc_rcpt_proc_name;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
         lc_err_status := 'Y';                                                   -- Added for defect #5071
         lc_err_mesg := 'There is no 9 record for file'||' '||lc_rcpt_proc_name; -- Added for defect #5071
          DELETE FROM xx_ar_payments_interface
          WHERE process_num = lc_rcpt_proc_name;                                -- Added for defect #5071 on 21-Apr-10
          put_log_line('[WIP] Rows rollbacked - ' || SQL%ROWCOUNT );            -- Added for defect #5071 on 21-Apr-10
          COMMIT;                                                               -- Added for defect #5071 on 21-Apr-10
         RAISE_APPLICATION_ERROR ( -20009,lc_err_mesg);                         -- Added for defect #5071
    END;

--  Prakash Sankaran - Deleting '4' records that have invalid invoice numbers --

    UPDATE xx_ar_payments_interface
    SET   invoice1 = NULL
    WHERE process_num = lc_rcpt_proc_name
    AND   file_name   = lc_lck_filename
    AND   record_type = '4'
    AND   invoice1 like '9999%';

    UPDATE xx_ar_payments_interface
    SET   invoice2 = NULL
    WHERE process_num = lc_rcpt_proc_name
    AND   file_name   = lc_lck_filename
    AND   record_type = '4'
    AND   invoice2 like '9999%';

    UPDATE xx_ar_payments_interface
    SET   invoice3 = NULL
    WHERE process_num = lc_rcpt_proc_name
    AND   file_name   = lc_lck_filename
    AND   record_type = '4'
    AND   invoice3 like '9999%';

-- End of '4' record deletes  --

---+===============================================================================================
---|  Copy raw Lockbox data to reporting table X_AR_INBOUND_LOCKBOX_DATA CR 752 DEFECT 3198
---+===============================================================================================

      lc_err_pos := 'LCK-1007';

      put_log_line('Begin loading raw lockbox data into xx_ar_inbound_lockbox_data for '||lc_lck_filename);

      BEGIN
      INSERT INTO XX_AR_INBOUND_LOCKBOX_DATA
               (file_name,
                batch_name,
                item_number,
                check_number,
                remittance_amount,
                transit_routing_number,
                account,
                customer_number,
                invoice,
                amount_applied)
                (select   b.file_name,
                        b.batch_name,
                        b.item_number,
                        b.check_number,
                        b.remittance_amount/100,
                        b.transit_routing_number,
                        b.account,
                        b.customer_number,
                        a1.invoice1,
                        a1.amount_applied1/100
                 from   xx_ar_payments_interface a1,
                        xx_ar_payments_interface b
                 where  b.file_name = lc_lck_filename
                 and    b.file_name = a1.file_name
                 and    b.batch_name = a1.batch_name (+)
                 and    b.item_number = a1.item_number (+)
                 and    b.record_type = 6
                 and    a1.record_type = 4
                 --and   (a1.invoice1 is not null or a1.amount_applied1 <> 0) -- Commented for defect#8065
                 UNION ALL
                 select b.file_name,
                        b.batch_name,
                        b.item_number,
                        b.check_number,
                        b.remittance_amount/100,
                        b.transit_routing_number,
                        b.account,
                        b.customer_number,
                        a2.invoice2,
                        a2.amount_applied2/100
                 from   xx_ar_payments_interface a2,
                        xx_ar_payments_interface b
                 where  b.file_name = lc_lck_filename
                 and    b.file_name = a2.file_name
                 and    b.batch_name = a2.batch_name
                 and    b.item_number= a2.item_number
                 and    b.record_type = 6
                 and    a2.record_type = 4
                 --and   (a2.invoice2 is not null or a2.amount_applied2 <> 0 ) -- Commented for defect#8065
                 UNION ALL
                 select b.file_name,
                        b.batch_name,
                        b.item_number,
                        b.check_number,
                        b.remittance_amount/100,
                        b.transit_routing_number,
                        b.account,
                        b.customer_number,
                        a3.invoice3,
                        a3.amount_applied3/100
                 from   xx_ar_payments_interface a3,
                        xx_ar_payments_interface b
                 where  b.file_name = lc_lck_filename
                 and    b.file_name = a3.file_name
                 and    b.batch_name = a3.batch_name
                 and    b.item_number = a3.item_number
                 and    b.record_type = 6
                 and    a3.record_type = 4
                 --and   (a3.invoice3 is not null or a3.amount_applied3 <> 0)  -- Commented for defect#8065
                 UNION ALL
                 select b.file_name,
                        b.batch_name,
                        b.item_number,
                        b.check_number,
                        b.remittance_amount/100,
                        b.transit_routing_number,
                        b.account,
                        b.customer_number,
                        null,
                        null
                 from   xx_ar_payments_interface b
                 where  file_name = lc_lck_filename
                 and    b.record_type = 6
                 and    not exists (select 'x'
                                    from   xx_ar_payments_interface a
                                    where  a.file_name = b.file_name
                                    and    a.batch_name = b.batch_name
                                    and    a.item_number = b.item_number
                                    and    a.record_type = '4')
              );
       END;

       COMMIT;

       put_log_line('Completed loading xx_ar_inbound_lockbox_data'||' '||SQLCODE||' '||SQLERRM);

  -- ============================================================================
  --   Fetch the deposit date, then validate and default GL date using this date
  --   defect 9686
  -- ============================================================================
      lc_err_pos := 'LCK-1008';

      put_log_line('[WIP] Deposit Date Validation');

       DECLARE
        x_defaulting_rule_used   VARCHAR2(200);
        x_error_message          VARCHAR2(4000);

       CURSOR lcu_deposit_date IS
          SELECT deposit_date
            FROM xx_ar_payments_interface
           WHERE process_num = lc_rcpt_proc_name
         AND file_name = lc_lck_filename
         AND deposit_date IS NOT NULL;
       BEGIN
         put_log_line( 'Validate and default GL Date using Deposit Date' );

    -- get the deposit date from the payments in this lockbox
         OPEN lcu_deposit_date;
         FETCH lcu_deposit_date
         INTO ld_deposit_date;
         CLOSE lcu_deposit_date;

         put_log_line( '  Deposit Date = ' || ld_deposit_date );

         SELECT TO_CHAR(ld_deposit_date,'YYYY')
         INTO   ld_deposit_year
         FROM   DUAL;

         put_log_line( '  Deposit YEAR = ' || ld_deposit_year );

       BEGIN

        SELECT V.target_value1, V.ENABLED_FLAG
        INTO   lc_holiday_flag, lc_holiday_enabled
        FROM   xx_fin_translatedefinition D,
               xx_fin_translatevalues     V
        WHERE  D.translate_id = V.translate_id
        AND    D.translation_name = 'AR_RECEIPTS_BANK_HOLIDAYS'
        AND    UPPER(V.source_value1) = UPPER(ld_deposit_year)
        AND    UPPER(V.source_value2) = UPPER(ld_deposit_date);
       EXCEPTION
        WHEN OTHERS THEN
        lc_holiday_flag := ' ';
       END;

       put_log_line( '  Holiday table flags = ' || lc_holiday_flag );

       IF lc_holiday_flag = 'Y' AND lc_holiday_enabled = 'Y' THEN
        SELECT TO_DATE(ld_deposit_date,'dd-mon-yy') + 1
        INTO   ld_deposit_date
        FROM   DUAL;
       END IF;

       put_log_line( '  Deposit Date before Holiday check = ' || ld_deposit_date );

       SELECT TO_CHAR(ld_deposit_date,'DAY')
       INTO   ld_deposit_day
       FROM   DUAL;

       put_log_line( '  Deposit DOW = ' || ld_deposit_day );

       IF TRIM(ld_deposit_day) = 'SATURDAY' THEN
          SELECT TO_DATE(ld_deposit_date,'dd-mon-yy') + 2
          INTO   ld_deposit_date
          FROM   DUAL;
       END IF;

       IF TRIM(ld_deposit_day) = 'SUNDAY' THEN
          SELECT TO_DATE(ld_deposit_date,'dd-mon-yy') + 1
          INTO   ld_deposit_date
          FROM   DUAL;
       END IF;

       put_log_line( '  Deposit Date after SUNDAY check = ' || ld_deposit_date );

       SELECT TO_CHAR(ld_deposit_date,'YYYY')
       INTO   ld_deposit_year
       FROM   DUAL;

       put_log_line( '  Deposit YEAR = ' || ld_deposit_year );

       BEGIN

        SELECT V.target_value1, V.ENABLED_FLAG
        INTO   lc_holiday_flag, lc_holiday_enabled
        FROM   xx_fin_translatedefinition D,
         xx_fin_translatevalues     V
        WHERE  D.translate_id = V.translate_id
        AND    D.translation_name = 'AR_RECEIPTS_BANK_HOLIDAYS'
        AND    UPPER(V.source_value1) = UPPER(ld_deposit_year)
        AND    UPPER(V.source_value2) = UPPER(ld_deposit_date);
        EXCEPTION
             WHEN OTHERS THEN
                  lc_holiday_flag := ' ';
       END;

       put_log_line( '  Holiday table flags = ' || lc_holiday_flag );

       IF lc_holiday_flag = 'Y' AND lc_holiday_enabled = 'Y' THEN
          SELECT TO_DATE(ld_deposit_date,'dd-mon-yy') + 1
          INTO   ld_deposit_date
          FROM   DUAL;
       END IF;

       put_log_line( '  Deposit Date after Holiday check = ' || ld_deposit_date );

    -- validate and default the GL date for the payment interface
       IF (NOT ARP_STANDARD.validate_and_default_gl_date
            ( gl_date                => ld_deposit_date,
              trx_date               => ld_deposit_date,
              validation_date1       => NULL,
              validation_date2       => NULL,
              validation_date3       => NULL,
              default_date1          => NULL,
              default_date2          => NULL,
              default_date3          => NULL,
              p_allow_not_open_flag  => NULL,
              p_invoicing_rule_id    => NULL,
              p_set_of_books_id      => NULL,
              p_application_id       => NULL,
              default_gl_date        => ld_gl_date,
              defaulting_rule_used   => x_defaulting_rule_used,
              error_message          => x_error_message ) )
       THEN
        RAISE_APPLICATION_ERROR(-20010,
          ' API Errors [ARP_STANDARD.validate_and_default_gl_date]:' || chr(10) ||
            x_error_message );
       END IF;

       put_log_line( '  GL Date = ' || ld_gl_date );
       put_log_line( '  Rule Used = ' || x_defaulting_rule_used );
       END;

---+===============================================================================================
---|  Get the Lockbox Number for the transmission
---+===============================================================================================

   lc_err_pos := 'LCK-1009';

   put_log_line('[WIP] Get transmission lockboxes - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

    OPEN Lockbox_num_cur(lc_rcpt_proc_name);
    LOOP
      FETCH Lockbox_num_cur INTO Lockbox_num_rec;
      EXIT WHEN Lockbox_num_cur%NOTFOUND;

      BEGIN

        SELECT lockbox_id
          INTO ln_lockbox_id
          FROM ar_lockboxes
         WHERE lockbox_number = Lockbox_num_rec.lockbox_number
           AND status = 'A';

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
         lc_err_status := 'Y';
         lc_err_mesg := 'Lockbox Number '||Lockbox_num_rec.lockbox_number||' Not setup in AR, for File '||p_filename;
      END;

    END LOOP;
    CLOSE Lockbox_num_cur;


   IF lc_err_status = 'Y' THEN
    RAISE_APPLICATION_ERROR ( -20011,'Please Setup the Above mentioned Lockboxes');
   END IF;

---+===============================================================================================
---|  Call the procedure for Partial matching and Custom auto cash rules
---+===============================================================================================

    lc_err_pos := 'LCK-1010';

   put_log_line('[WIP] Custom Auto Cash Rules- ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

   ln_check_digit     := p_check_digit;
   lc_trx_type        := p_trx_type;
   ln_trx_threshold   := p_trx_threshold;
   ln_from_days       := p_from_days;
   ln_to_days         := p_to_days;

   XX_AR_LOCKBOX_PROCESS_PKG.CUSTOM_AUTO_CASH
   ( lc_ac_err_msg,
     ln_ac_ret_code,
     lc_rcpt_proc_name,
     ln_check_digit,
     lc_trx_type,
     ln_trx_threshold,
     ln_from_days,
     ln_to_days,
     p_back_order_configurable
    );

   put_log_line('Return Code:'||ln_ac_ret_code);
   put_log_line('lc_ac_err_msg:'||lc_ac_err_msg);

  IF ln_ac_ret_code = gn_error THEN
    lc_err_mesg := 'Custom Autocash rules failed, Lockbox submition will not proceed without custom rules';
    put_log_line('Error Occured at Position:'||lc_err_mesg||' : '||lc_ac_err_msg);
    RAISE EX_MAIN_EXCEPTION;
  END IF;

      UPDATE xx_ar_payments_interface xxarpi1
         SET amount_applied1 = (SELECT remittance_amount
                                  FROM xx_ar_payments_interface xxarpi2
                                 WHERE xxarpi2.process_num = xxarpi1.process_num
                                   AND xxarpi2.record_type = '6'
                                   AND xxarpi2.batch_name  = xxarpi1.batch_name
                                   AND xxarpi2.item_number = xxarpi1.item_number
                                   AND xxarpi2.process_num = lc_rcpt_proc_name
                                   AND rownum =1
                               )
       WHERE process_num     = lc_rcpt_proc_name
         AND NVL(amount_applied1,0) = 0
         AND invoice1 IS NOT NULL
         AND invoice2 IS NULL
         AND invoice3 IS NULL
         AND record_type = '4'
         AND NOT EXISTS ( SELECT 1 FROM xx_ar_payments_interface xxarpi3
                                  WHERE xxarpi3.process_num = xxarpi1.process_num
                                              AND xxarpi3.record_type = '4'
                                    AND xxarpi3.batch_name  = xxarpi1.batch_name
                                    AND xxarpi3.item_number = xxarpi1.item_number
                                    AND xxarpi3.process_num = lc_rcpt_proc_name
                                    AND xxarpi3.rowid <> xxarpi1.rowid )
        RETURNING         batch_name,item_number,invoice1,amount_applied1
        BULK COLLECT INTO l_batch_name, l_item_number,l_invoice,l_amount;

        put_log_line(' [WIP] No of Records Updated - ' || SQL%ROWCOUNT );

---+===============================================================================================
---|  Insert the processed file info into xx_ar_lbx_wrapper_temp table -- Defect #4320
---+===============================================================================================

    lc_err_pos := 'LCK-1011';

    put_log_line('[WIP] Insert into xx_ar_lbx_wrapper_temp table - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

      INSERT INTO xx_ar_lbx_wrapper_temp
      (transmission_record_count
       ,transmission_amount
       ,transmission_format_id
       ,entire_file_name
       ,exact_file_name
       ,process_num
       ,gl_date
       ,lbx_custom_main_req_id
       ,deposit_date
       ,email_notify_flag
       ,creation_date
       ,created_by
       ,last_update_date
       ,last_updated_by
       )
      VALUES
      (ln_tran_rec_cnt                       --TRANSMISSION_RECORD_COUNT
       ,ln_tran_amt                          --TRANSMISSION_AMOUNT
       ,ln_trans_for_id                      --TRANSMISSION_FORMAT_ID
       ,p_filename                           --FILE_NAME WITH ENTIRE PATH
       ,lc_lck_filename                      --DERIVED FILE NAME
       ,lc_rcpt_proc_name                    --PROCESS_NUM
       ,ld_gl_date                           --GL_DATE
       ,gn_request_id                        --LBX_CUSTOM_MAIN_REQ_ID
       ,ld_deposit_date                      --DEPOSIT DATE
       ,p_email_notf
       ,SYSDATE
       ,FND_GLOBAL.USER_ID
       ,SYSDATE
       ,FND_GLOBAL.USER_ID
       );
----------------------------------------------------------------------------------------------------

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '**********************************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$0 PAYMENT REPORT~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '**********************************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' TRANMISSION NAME     : ' || lc_trans_name);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '**********************************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~LIST OF INVOICES UPDATED FOR $0 PAYMENT REPORT~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '**********************************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      ' INVOICE NUMBER                                                                    AMOUNT                 ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '**********************************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));

      FOR i in 1..l_invoice.COUNT LOOP
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
        '    '||l_invoice(i) ||'                                                                        ' || l_amount(i));
      END LOOP;

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '**********************************************************************************************************');


---+===============================================================================================
---|  Check if there are any errors and set the completion status to WARNING
---+===============================================================================================

  IF (lc_err_mesg IS NOT NULL) THEN
    lc_compl_stat := fnd_concurrent.set_completion_status('WARNING','');
  END IF;

---+===============================================================================================
---|  Handle the Other exceptions
---+===============================================================================================

  END IF;                               --endif_complete

  	--Invoke File copy program to copy lockbox output file to XPTR

	IF nvl(fnd_profile.value_specific('XX_FIN_DISABLE_XPTR_OP'),
           'N') = 'N'
    THEN

      BEGIN
        SELECT substr(val.target_value1,3)
          INTO lc_xptr_name
          FROM xx_fin_translatedefinition def
              ,xx_fin_translatevalues     val
         WHERE def.translate_id = val.translate_id
           AND def.translation_name = 'XXOD_FIN_XPTR'
           AND val.source_value1 = 'XX_AR_LOCKBOX_PROCESS_MAIN'
           AND SYSDATE BETWEEN def.start_date_active AND
               nvl(def.end_date_active,
                   SYSDATE + 1)
           AND SYSDATE BETWEEN val.start_date_active AND
               nvl(val.end_date_active,
                   SYSDATE + 1)
           AND def.enabled_flag = 'Y'
           AND val.enabled_flag = 'Y';
        IF lc_xptr_name IS NOT NULL
        THEN
          l_out_dir := '/app/xptrrs/orarpt/orclar/' || lc_xptr_name;
		ELSE
          l_out_dir    := '/app/xptrrs/orarpt/orclar/ARLBMAIN';
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          lc_xptr_name := NULL;
          l_out_dir    := '/app/xptrrs/orarpt/orclar/ARLBMAIN';
      END;

      BEGIN

        SELECT outfile_name
          INTO l_file_name
          FROM fnd_concurrent_requests
         WHERE request_id = fnd_global.conc_request_id;

      EXCEPTION
        WHEN OTHERS THEN
          l_file_name := NULL;
      END;
      IF l_file_name IS NOT NULL
      THEN
        l_out_dir  := l_out_dir || fnd_global.conc_request_id || '.out';
        l_request_id := fnd_request.submit_request(application => 'XXFIN',
                                                   program     => 'XXCOMFILCOPY',
                                                   description => 'OD: Common File Copy',
                                                   start_time  => to_char(SYSDATE,
                                                                          'DD-MON-YY HH24:MI:SS'),
                                                   sub_request => FALSE,
                                                   argument1   => l_file_name,
                                                   argument2   => l_out_dir);
        IF l_request_id = 0
        THEN
          fnd_file.put_line(fnd_file.log,
                            '+----------------------------------------------------------------+');
          fnd_file.put_line(fnd_file.log,
                            '                                                                  ');
          fnd_file.put_line(fnd_file.log,
                            'XPTR Program is not invoked');
        ELSE
		  fnd_file.put_line(fnd_file.log,
                            'XPTR Program to transfer file to XNET is invoked, requeust id is" ' || l_request_id);
          COMMIT;
        END IF;
      END IF;
    END IF;

EXCEPTION
WHEN EX_MAIN_EXCEPTION THEN
  x_errbuf   := lc_err_pos ||'-'||lc_err_mesg;
  x_retcode  := gn_error;
  -- -------------------------------------------
  -- Call the Custom Common Error Handling
  -- -------------------------------------------
  XX_COM_ERROR_LOG_PUB.LOG_ERROR
  ( p_program_type            => 'CONCURRENT PROGRAM'
   ,p_program_name            => gc_conc_short_name
   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
   ,p_module_name             => 'AR'
   ,p_error_location          => 'Error at ' || lc_err_pos
   ,p_error_message_count     => 1
   ,p_error_message_code      => 'E'
   ,p_error_message           => lc_err_mesg
   ,p_error_message_severity  => 'Major'
   ,p_notify_flag             => 'N'
   ,p_object_type             => 'Main Lockbox Process'
  );
  put_log_line('==========================');
  put_log_line(x_errbuf);
  ROLLBACK;
WHEN OTHERS THEN
  lc_err_mesg := 'Error Occured at Position = '||lc_err_pos||' : '||SQLCODE||' : '||SQLERRM;
  x_errbuf := SQLERRM;
  x_retcode := 2;
  put_log_line(lc_err_mesg);
  XX_COM_ERROR_LOG_PUB.LOG_ERROR
  ( p_program_type             => 'CONCURRENT PROGRAM'
   ,p_program_name            => 'AR CUSTOM LOCKBOX'
   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
   ,p_module_name             => 'AR'
   ,p_error_location          => 'Error at ' || lc_err_pos
   ,p_error_message_count     => 1
   ,p_error_message_code      => 'E'
   ,p_error_message           => lc_err_mesg
   ,p_error_message_severity  => 'Major'
   ,p_notify_flag             => 'N'
   ,p_object_type             => 'Main Lockbox Process'
  );

  lc_compl_stat := fnd_concurrent.set_completion_status('ERROR','');
  ROLLBACK;
END LOCKBOX_PROCESS_MAIN;


/* --Commented for the Defect #4320
PROCEDURE LOCKBOX_PROCESS_MAIN
( x_errbuf                 OUT   NOCOPY  VARCHAR2
 ,x_retcode                OUT   NOCOPY  NUMBER
 ,p_filename                IN            VARCHAR2
 ,p_email_notf              IN            VARCHAR2  DEFAULT NULL
 ,p_check_digit             IN            NUMBER
 ,p_trx_type                IN            VARCHAR2  DEFAULT NULL
 ,p_trx_threshold           IN            NUMBER    DEFAULT NULL
 ,p_from_days               IN            NUMBER    DEFAULT NULL
 ,p_to_days                 IN            NUMBER    DEFAULT NULL
 ,p_days_start_purge        IN            NUMBER    DEFAULT 120
 ,p_debug_flag              IN            VARCHAR2  DEFAULT 'Y'
 ,p_back_order_configurable IN            NUMBER    -- Added for Defect #3983 on 26-JAN-10
)
IS
---+===============================================================================================
---|  This procedure will be registered as a concurrent program which will be called by a BPEL
---|  process. The procedure will validate if the file has already been processed and report the error
---|  if required. It calls the procedure LOCKBOX_AUTOCASH_RULES to apply the custom auto cash rules.
---|  After all the validation is successfull it calls the Standard Lockbox process with the appropriate
---|  parameters.
---+===============================================================================================


---+===============================================================================================
---|  Define the cursor to select the locbox numbers for the given process number
---+===============================================================================================
  CURSOR Lockbox_num_cur(p_cur_process_num VARCHAR2)
  IS
    SELECT DISTINCT lockbox_number
    FROM   xx_ar_payments_interface
    WHERE  process_num = p_cur_process_num
    AND    record_type = '5';

  Lockbox_num_rec      Lockbox_num_cur%ROWTYPE;

  lc_err_mesg          VARCHAR2(1000);
  lc_err_status        VARCHAR2(20);
  lc_err_pos           VARCHAR(20);
  lc_dummy             VARCHAR2(10);
  ln_trans_for_id      NUMBER;
  lc_lockbox_num       VARCHAR2(20);
  ld_dep_date          DATE;
  lc_trans_ins         VARCHAR2(10);
  ln_tran_req_id       NUMBER;
  ln_transmission_id   NUMBER;
  lc_lb_wait           BOOLEAN;
  lc_conc_phase        VARCHAR2(100);
  lc_conc_status       VARCHAR2(100);
  lc_dev_phase         VARCHAR2(100);
  lc_dev_status        VARCHAR2(100);
  lc_conc_message      VARCHAR2(100);
  ln_ldr_req_id        NUMBER;
  ln_lck_req_id        NUMBER;
  ln_lockbox_id        NUMBER;
  lc_req_bil_loc       VARCHAR2(20);
  lc_lck_filename      VARCHAR2(200);
  lc_compl_stat        BOOLEAN;
  lc_rcpt_proc_name    VARCHAR2(100);
  ln_tran_rec_cnt      NUMBER;
  ln_tran_amt          NUMBER;
  lc_trans_name        VARCHAR2(60);
  lc_ac_err_msg        VARCHAR2(4000);
  lc_trx_type          VARCHAR2(30);

  lc_control_file      VARCHAR2(200);
  lc_program_name      VARCHAR2(200);
  lc_file_suffix       VARCHAR2(200);
  ln_prog_appl_id      NUMBER;
  ln_conc_prog_id      NUMBER;
  ln_load_count        NUMBER;
  ln_rec_count         NUMBER;
  ln_check_index       NUMBER;
  ln_tolerance         NUMBER;

  ln_ac_ret_code       NUMBER;
  ln_mail_request_id   NUMBER;
  ln_check_digit       NUMBER;
  ln_trx_threshold     NUMBER;
  ln_from_days         NUMBER;
  ln_to_days           NUMBER;

  lc_holiday_flag      VARCHAR2(1);
  lc_holiday_enabled   VARCHAR2(1);
  ld_deposit_day       VARCHAR2(10);
  ld_deposit_year      VARCHAR2(4);
  ld_gl_date           DATE;
  lc_chk_flag          VARCHAR2(10);            -- Added for Defect # 2063.
  ln_err_cnt           NUMBER;                  -- Added for Defect # 4128
  ln_wrn_cnt           NUMBER;                  -- Added for Defect # 4128
  ln_nrm_cnt           NUMBER;                  -- Added for Defect # 4128
  EX_MAIN_EXCEPTION    EXCEPTION;

  TYPE BatchList IS TABLE OF XX_AR_PAYMENTS_INTERFACE.BATCH_NAME%TYPE;
  TYPE ItemList  IS TABLE OF XX_AR_PAYMENTS_INTERFACE.ITEM_NUMBER%TYPE;
  TYPE InvoiceList IS TABLE OF XX_AR_PAYMENTS_INTERFACE.INVOICE1%TYPE;
  TYPE AmountList  IS TABLE OF XX_AR_PAYMENTS_INTERFACE.AMOUNT_APPLIED1%TYPE;
  l_batch_name  BatchList;
  l_item_number ItemList;
  l_invoice     InvoiceList;
  l_amount      AmountList;

  --Added for defect 3316
  PROCEDURE INVOKE_ESP_BPEL_PROCESS(p_filename IN VARCHAR2)
  IS
     lc_method            XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_namespace         XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_soap_action       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_bpel_url          XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_debug_mode        XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_process_name      XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_as2name           XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_domain_name       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_bpel_input1       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_bpel_input2       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_bpel_input3       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lr_req_typ           XX_FIN_BPEL_SOAP_API_PKG.request_rec_type   DEFAULT   NULL;
     lr_resp_typ          XX_FIN_BPEL_SOAP_API_PKG.response_rec_type  DEFAULT   NULL;
     lc_lb_headername     XX_FIN_TRANSLATEVALUES.source_value1%TYPE   DEFAULT   NULL;
     lc_loc               VARCHAR2(3);

  BEGIN

      lc_loc := '1';
      put_log_line(CHR(13)||CHR(13));
      put_log_line('-------------------- Invoking BPEL Process to release ESP job --------------------');
      put_log_line('p_filename           : '||p_filename);

      lc_loc := '2';
      FOR lcu_bpel_param IN (SELECT   XFTV.source_value1
                                     ,XFTV.target_value1
                                     ,XFTV.target_value2
                             FROM     xx_fin_translatedefinition XFTD
                                     ,xx_fin_translatevalues XFTV
                             WHERE   XFTD.translate_id = XFTV.translate_id
                             AND     XFTD.translation_name = 'AR_LOCKBOX_BPEL_SETUP'
                             AND     XFTV.target_value1 IN ('BPEL_INVOKE','BPEL_INPUT')
                             AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                             AND     SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                             AND     XFTV.enabled_flag = 'Y'
                             AND     XFTD.enabled_flag = 'Y')
      LOOP
         IF (lcu_bpel_param.target_value1 = 'BPEL_INVOKE') THEN
            IF (lcu_bpel_param.source_value1 = 'METHOD') THEN
                lc_method := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'NAMESPACE') THEN
                lc_namespace  := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'SOAP_ACTION') THEN
                lc_soap_action := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'URL') THEN
                lc_bpel_url    := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'DEBUG_MODE') THEN
                lc_debug_mode  := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'PROCESS_NAME') THEN
                lc_process_name := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'DOMAIN_NAME') THEN
                lc_domain_name := lcu_bpel_param.target_value2;
            END IF;
         ELSIF (lcu_bpel_param.target_value1 = 'BPEL_INPUT') THEN
            IF (lcu_bpel_param.source_value1 = 'BPEL_INPUT1') THEN
                lc_bpel_input1 := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'BPEL_INPUT2') THEN
                lc_bpel_input2 := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'BPEL_INPUT3') THEN
                lc_bpel_input3 := lcu_bpel_param.target_value2;
            END IF;
         END IF;
      END LOOP;

      lc_loc := '3';
      lc_lb_headername := SUBSTR(p_filename,INSTR(p_filename,'/',-1,1)+1);

      lc_lb_headername := SUBSTR(lc_lb_headername,1,INSTR(lc_lb_headername,'.',-1,1)-1);

      lc_lb_headername := SUBSTR(lc_lb_headername,16);

      lc_loc := '4';
      SELECT   XFTV.target_value2
      INTO     lc_as2name
      FROM     xx_fin_translatedefinition XFTD
              ,xx_fin_translatevalues XFTV
      WHERE   XFTD.translate_id = XFTV.translate_id
      AND     XFTD.translation_name = 'AR_LOCKBOX_BPEL_SETUP'
      AND     XFTV.target_value1 = 'AS2NAME'
      AND     XFTV.source_value1 = lc_lb_headername
      AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
      AND     SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
      AND     XFTV.enabled_flag = 'Y'
      AND     XFTD.enabled_flag = 'Y' ;

      put_log_line('BPEL Parameters derived from AR_BPEL_LOCKBOX_SETUP Translation');
      put_log_line('METHOD            : '||lc_method);
      put_log_line('NAMESPACE         : '||lc_namespace);
      put_log_line('SOAP_ACTION       : '||lc_soap_action);
      put_log_line('URL               : '||lc_bpel_url);
      put_log_line('DEBUG_MODE        : '||lc_debug_mode);
      put_log_line('PROCESS_NAME      : '||lc_process_name);
      put_log_line('DOMAIN_NAME       : '||lc_domain_name);
      put_log_line('BPEL_INPUT1       : '||lc_bpel_input1);
      put_log_line('BPEL_INPUT2       : '||lc_bpel_input2);
      put_log_line('BPEL_INPUT3       : '||lc_bpel_input3);


      lc_loc := '5';
      lr_req_typ := XX_FIN_BPEL_SOAP_API_PKG.new_request(
                                                        lc_method
                                                        ,lc_namespace
                                                        );

      lc_loc := '6';
      XX_FIN_BPEL_SOAP_API_PKG.add_parameter(
                                             lr_req_typ
                                            ,lc_bpel_input1
                                            ,'xsd:string'
                                            ,lc_process_name
                                            );

      lc_loc := '7';
      XX_FIN_BPEL_SOAP_API_PKG.add_parameter(
                                             lr_req_typ
                                            ,lc_bpel_input2
                                            ,'xsd:string'
                                            ,lc_domain_name
                                            );

      lc_loc := '8';
      XX_FIN_BPEL_SOAP_API_PKG.add_parameter(
                                             lr_req_typ
                                            ,lc_bpel_input3
                                            ,'xsd:string'
                                            ,lc_as2name
                                            );

      put_log_line('BPEL Process Request/Response'||CHR(13));

      lc_loc := '9';
      lr_resp_typ := XX_FIN_BPEL_SOAP_API_PKG.invoke(
                                                     lr_req_typ
                                                    ,lc_bpel_url
                                                    ,lc_soap_action
                                                    );
  EXCEPTION
     WHEN OTHERS THEN
        put_log_line('Error occured at '||lc_loc||' due to '||CHR(13)||SQLERRM);
  END INVOKE_ESP_BPEL_PROCESS;

BEGIN
  -- set debug
  IF (NVL(p_debug_flag,'Y') = 'Y') THEN
    set_debug(TRUE);
  ELSE
    set_debug(FALSE);
  END IF;

  put_log_line('[BEGIN] LOCKBOX_PROCESS_MAIN - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

  -- get current request_id
  gn_ncr_request_id  := NVL(FND_GLOBAL.CONC_REQUEST_ID, DBMS_RANDOM.random() );

  lc_lck_filename := SUBSTR(p_filename,INSTR(p_filename,'/',-1)+1);
  lc_trans_name := SUBSTR(lc_lck_filename,1,30);

   lc_chk_flag := FND_CONC_GLOBAL.request_data;             -- Added for Defect # 2063

   put_log_line(' [WIP] Request_data - '||lc_chk_flag );    -- Added for Defect # 2063

---+===============================================================================================
---|  Select the transmission format ID
---+===============================================================================================

      lc_err_pos := 'LCK-1001';

    BEGIN
      SELECT transmission_format_id
        INTO   ln_trans_for_id
        FROM   ar_transmission_formats
        WHERE  format_name = 'OD_US LOCKBOX'
        AND    status_lookup_code = 'A';

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lc_err_status := 'Y';
        lc_err_mesg := 'The Transmission format OD_US BOA LOCKBOX is NOT defined';
        --put_log_line('Error Occured at Position = '||lc_err_pos||' : '||lc_err_mesg);
        --lc_compl_stat := fnd_concurrent.set_completion_status('ERROR','');
           RAISE_APPLICATION_ERROR ( -20001,lc_err_mesg);
    END;


---+===============================================================================================
---|  Check if the transmission is already created for this datafile
---+===============================================================================================

 IF (NVL(lc_chk_flag,'FIRST') <> 'COMPLETE') THEN              -- Added the IF Logic for Defect 2063

     lc_err_pos := 'LCK-1002';

            BEGIN
              SELECT 'x'
                INTO   lc_dummy
                FROM   ar_transmissions_all
                WHERE  transmission_name = lc_trans_name;

              lc_err_status := 'Y';
              lc_err_mesg := 'The File: '||lc_lck_filename||' has already been processed.';
              --put_log_line('Error Occured at Position = '||lc_err_pos||' : '||lc_err_mesg);
              --lc_compl_stat := fnd_concurrent.set_completion_status('ERROR','');
                 RAISE_APPLICATION_ERROR ( -20002,lc_err_mesg);

            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                lc_trans_ins := 'Y';
            END;


---+===============================================================================================
---|  Periodically archive and purge data in XX_AR_PAYMENTS_INTERFACE table
---|    Defect 8311 - Brian J Looman - 24-Jun-2008   (defaults to 120)
---+===============================================================================================

    lc_err_pos := 'LCK-1002A';

    put_log_line('[WIP] Purge Old Interface Data - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

          IF (p_days_start_purge > 0) THEN
             DELETE FROM XX_AR_PAYMENTS_INTERFACE
             WHERE creation_date < TRUNC(SYSDATE) - NVL(p_days_start_purge,120);

             put_log_line('Purged Old Records (Days Old = ' || p_days_start_purge || ')');
             put_log_line('  Deleted ' || SQL%ROWCOUNT || ' records.');

             COMMIT;
          END IF;
 END IF;

 ---+===============================================================================================
---|  Determine the SQL*Loader concurrent program to execute for the given file (using translations)
---+===============================================================================================

    lc_err_pos := 'LCK-1002B';

    put_log_line('[WIP] Lockbox Translations - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

    put_log_line('Get the Translation values for the BAI File being processed...');
    put_log_line('  File Name = ' || lc_lck_filename );
    put_log_line('  Translation = ' || gc_lb_bai_translation );

   gc_file_name := lc_lck_filename; -- Added for Defect # 4284

      BEGIN
         SELECT tv.source_value1 control_file_suffix,
                tv.target_value1 concurrent_program
         INTO   lc_file_suffix,
                lc_program_name
         FROM   xx_fin_translatedefinition td,
                xx_fin_translatevalues tv
         WHERE  td.translate_id = tv.translate_id
         AND    td.translation_name = gc_lb_bai_translation
         AND    lc_lck_filename LIKE '%' || tv.source_value1 || '.txt%';

         put_log_line('  File Name Suffix = ' || lc_file_suffix );
         put_log_line('  Concurrent Program = ' || lc_program_name );
      EXCEPTION
         WHEN OTHERS THEN
         lc_err_status := 'Y';
         lc_err_mesg := 'The Translation has not be defined for this bank BAI file.' || chr(10)
          || ' ( File Name = ' || lc_lck_filename || chr(10)
          || ' Translation = ' || gc_lb_bai_translation || ' ) ' ;
      --put_log_line('Error Occured at Position = '||lc_err_pos||' : '||lc_err_mesg);
      --lc_compl_stat := FND_CONCURRENT.set_completion_status('ERROR','');
         RAISE_APPLICATION_ERROR (-20001,lc_err_mesg);
      END;

---+===============================================================================================
---|  Validate the SQL*Loader concurrent program defined in the Translation
---+===============================================================================================
-------------------
--Step #1 -- Starts
-------------------
  IF (NVL(lc_chk_flag,'FIRST') ='FIRST') THEN              -- Added the IF Logic for Defect 2063

        lc_err_pos := 'LCK-1002C';
        put_log_line('Validate Concurrent Program and that it is a SQL*Loader executable');

        BEGIN
          SELECT fcp.application_id,
                 fcp.concurrent_program_id,
                 fe.execution_file_name
            INTO ln_prog_appl_id,
                 ln_conc_prog_id,
                 lc_control_file
            FROM fnd_concurrent_programs fcp,
                 fnd_executables fe
           WHERE fcp.executable_application_id = fe.application_id
             AND fcp.executable_id = fe.executable_id
             AND fe.execution_method_code = 'L'  -- only SQL*Loader
             AND fcp.concurrent_program_name = lc_program_name;

        put_log_line('  Control File Name = ' || lc_control_file );

        EXCEPTION
          WHEN OTHERS THEN
            lc_err_status := 'Y';

            lc_err_mesg := 'The Concurrent Program for this Translation is not a valid SQL*Loader program.' || chr(10)
               || ' ( Program Name = ' || lc_program_name || ' ) ' ;
      --put_log_line('Error Occured at Position = '||lc_err_pos||' : '||lc_err_mesg);
      --lc_compl_stat := FND_CONCURRENT.set_completion_status('ERROR','');

            RAISE_APPLICATION_ERROR (-20001,lc_err_mesg);
        END;

---+===============================================================================================
---|  Verify that another SQL*Loader program is not running for this same file (lockbox)
---+===============================================================================================

        lc_err_pos := 'LCK-1002D';

        ln_check_index := 0;
        ln_tolerance := 6;

     LOOP
           ln_load_count := 0;
           ln_rec_count := 0;
           ln_check_index := ln_check_index + 1;

        BEGIN
           SELECT COUNT(1)
             INTO ln_load_count
             FROM fnd_concurrent_requests
            WHERE program_application_id = ln_prog_appl_id
              AND concurrent_program_id = ln_conc_prog_id
              AND phase_code IN ('P','R');  -- Pending or Running requests
        EXCEPTION
           WHEN OTHERS THEN
             ln_load_count := 0;
        END;

        IF (ln_load_count = 0) THEN
          BEGIN
            SELECT COUNT(1)
              INTO ln_rec_count
              FROM xx_ar_payments_interface
             WHERE process_num = 'RCT-BATCH'
               AND file_name = lc_file_suffix;
          EXCEPTION
            WHEN OTHERS THEN
              ln_rec_count := 0;
          END;
        END IF;

        EXIT WHEN (ln_load_count = 0 AND ln_rec_count = 0) OR ln_check_index >= ln_tolerance;

        put_log_line('[WIP] Wait on existing SQL*Loader (try #' || ln_check_index || ') - '
          || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
       DBMS_LOCK.sleep(10);  -- wait 10 seconds, and try again
     END LOOP;

      IF (ln_load_count > 0) THEN
        lc_err_status := 'Y';
        lc_err_mesg := 'SQL*Loader is already running for the same lockbox/BAI File (suffix). ' ||
                       ' Please wait for the other SQL*Loader program to complete.' || chr(10) ||
                       '  File Name Suffix = ' || lc_file_suffix;
        RAISE_APPLICATION_ERROR ( -20003,lc_err_mesg);
      END IF;

      IF (ln_rec_count > 0) THEN
        lc_err_status := 'Y';
        lc_err_mesg := 'Old/Bad data exists in XX_AR_PAYMENTS_INTERFACE for the same' ||
                       ' lockbox/BAI File (suffix). .  Please purge this old/bad data.' || chr(10) ||
                       '  File Name Suffix = ' || lc_file_suffix;
        RAISE_APPLICATION_ERROR ( -20003,lc_err_mesg);
      END IF;

---+===============================================================================================
---|  If it is a new transmission then submit the Loader process to insert the records into the
---|  table XX_AR_PAYMENTS_INTERFACE
---+===============================================================================================

      lc_err_pos := 'LCK-1003';

      put_log_line('[WIP] Submit SQL*Loader - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

              ln_ldr_req_id :=
                FND_REQUEST.SUBMIT_REQUEST
                ( 'XXFIN',
                  lc_program_name,  -- 'XXARLBLOAD', - defect 7605, call SQL*Loader prog based on BAI file
                  '',
                  SYSDATE,
                  --FALSE,
                  TRUE,                -- Added for the Defect 2063
                  p_filename );

            COMMIT;

          --put_log_line('[WIP] Wait on SQL*Loader - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );         -- Commented 
for Defect 2063

             put_log_line('[WIP] Pause on the Main Program ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );     -- Added for 
defect 2063
             put_log_line('[WIP] SQL Loader Request ID '||ln_ldr_req_id);                                        -- Added for 
defect 2063

             FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>'SECOND');                     -- Added for 
defect 2063
             put_log_line('[WIP] Checking the status of Main Program');                                         -- Added for 
defect 2063
             COMMIT;
             RETURN;                                                                    -- Added for defect 2063
  END IF;   -- End of IF for request data FIRST
-------------------
--Step #1 -- Ends
-------------------

  /*  IF ln_ldr_req_id > 0 THEN
     lc_lb_wait := fnd_concurrent.wait_for_request(
       ln_ldr_req_id,
       10,
       0,
       lc_conc_phase,
       lc_conc_status,
       lc_dev_phase,
       lc_dev_status,
       lc_conc_message );
   END IF;

--   put_log_line('[WIP] SQL*Loader Complete - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

 /*  IF TRIM(lc_conc_status) = 'Error' THEN
     lc_err_status := 'Y';
     lc_err_mesg := 'Error Loading the BAI file: '||p_filename||
                      ': Please check the Log file for Request ID : '||ln_ldr_req_id;
     --put_log_line('Error Occured at Position = '||lc_err_pos||' : '||
     --         lc_err_mesg||' : '||SQLCODE||' : '||SQLERRM);
     --lc_compl_stat := fnd_concurrent.set_completion_status('ERROR','');
     RAISE_APPLICATION_ERROR ( -20003,lc_err_mesg);
   END IF; */                        -- Commented for the Defect # 2063

---+===============================================================================================
---|  Copy raw Lockbox data to reporting table X_AR_INBOUND_LOCKBOX_DATA
---+===============================================================================================
/*        put_log_line('Begin loading raw lockbox data into xx_ar_inbound_lockbox_data for '||lc_lck_filename);

        BEGIN
      INSERT INTO XX_AR_INBOUND_LOCKBOX_DATA
               (file_name,
                batch_name,
                item_number,
                check_number,
                remittance_amount,
                transit_routing_number,
                account,
                customer_number,
                invoice,
                amount_applied)
                (select   b.file_name,
                        b.batch_name,
                        b.item_number,
                        b.check_number,
                        b.remittance_amount/100,
                        b.transit_routing_number,
                        b.account,
                        b.customer_number,
                        a1.invoice1,
                        a1.amount_applied1/100
                 from   xx_ar_payments_interface a1,
                        xx_ar_payments_interface b
                 where  b.file_name = lc_lck_filename
                 and    b.file_name = a1.file_name
                 and    b.batch_name = a1.batch_name (+)
                 and    b.item_number = a1.item_number (+)
                 and    b.record_type = 6
                 and    a1.record_type = 4
                 and   (a1.invoice1 is not null or a1.amount_applied1 <> 0)
                 UNION ALL
                 select b.file_name,
                        b.batch_name,
                        b.item_number,
                        b.check_number,
                        b.remittance_amount/100,
                        b.transit_routing_number,
                        b.account,
                        b.customer_number,
                        a2.invoice2,
                        a2.amount_applied2/100
                 from   xx_ar_payments_interface a2,
                        xx_ar_payments_interface b
                 where  b.file_name = lc_lck_filename
                 and    b.file_name = a2.file_name
                 and    b.batch_name = a2.batch_name
                 and    b.item_number= a2.item_number
                 and    b.record_type = 6
                 and    a2.record_type = 4
                 and   (a2.invoice2 is not null or a2.amount_applied2 <> 0 )
                 UNION ALL
                 select b.file_name,
                        b.batch_name,
                        b.item_number,
                        b.check_number,
                        b.remittance_amount/100,
                        b.transit_routing_number,
                        b.account,
                        b.customer_number,
                        a3.invoice3,
                        a3.amount_applied3/100
                 from   xx_ar_payments_interface a3,
                        xx_ar_payments_interface b
                 where  b.file_name = lc_lck_filename
                 and    b.file_name = a3.file_name
                 and    b.batch_name = a3.batch_name
                 and    b.item_number = a3.item_number
                 and    b.record_type = 6
                 and    a3.record_type = 4
                 and   (a3.invoice3 is not null or a3.amount_applied3 <> 0)
                 UNION ALL
                 select b.file_name,
                        b.batch_name,
                        b.item_number,
                        b.check_number,
                        b.remittance_amount/100,
                        b.transit_routing_number,
                        b.account,
                        b.customer_number,
                        null,
                        null
                 from   xx_ar_payments_interface b
                 where  file_name = lc_lck_filename
                 and    b.record_type = 6
                 and    not exists (select 'x'
                                    from   xx_ar_payments_interface a
                                    where  a.file_name = b.file_name
                                    and    a.batch_name = b.batch_name
                                    and    a.item_number = b.item_number
                                    and    a.record_type = '4')
              );
        END;

      COMMIT;

        put_log_line('completed loading xx_ar_inbound_lockbox_data'||' '||sqlcode||' '||sqlerrm);

---+===============================================================================================
---|  Create a unique process name for the file, every record for a given file will have a default
---|  value of 'RCT-BATCH' in the process_num column
---+===============================================================================================
-------------------
--Step #2 -- Starts
-------------------
 IF (NVL(lc_chk_flag,'FIRST') ='SECOND') THEN                --Added for defect 2063   --if_second

       put_log_line('[WIP] Update XX_AR_PAYMENTS_INTERFACE records - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

       SELECT 'RCT'||to_char(sysdate,'DDMMHH24MISS')||'-'||gn_ncr_request_id
       INTO  lc_rcpt_proc_name
       FROM  dual;


       UPDATE xx_ar_payments_interface
          SET process_num = lc_rcpt_proc_name,
              file_name = lc_lck_filename
       WHERE process_num = 'RCT-BATCH'
      -- defect 7605, update records based on control file that imported them.
       AND file_name = lc_file_suffix;

       COMMIT;

  -- ==========================================================================
  -- fetch the deposit date, then validate and default GL date using this date
  --   defect 9686
  -- ==========================================================================
      DECLARE
        x_defaulting_rule_used   VARCHAR2(200);
        x_error_message          VARCHAR2(4000);

      CURSOR lcu_deposit_date IS
          SELECT deposit_date
            FROM xx_ar_payments_interface
           WHERE process_num = lc_rcpt_proc_name
         AND file_name = lc_lck_filename
         AND deposit_date IS NOT NULL;
  BEGIN
    put_log_line( 'Validate and default GL Date using Deposit Date' );

    -- get the deposit date from the payments in this lockbox
    OPEN lcu_deposit_date;
    FETCH lcu_deposit_date
     INTO ld_deposit_date;
    CLOSE lcu_deposit_date;

    put_log_line( '  Deposit Date = ' || ld_deposit_date );

  SELECT TO_CHAR(ld_deposit_date,'YYYY')
    INTO   ld_deposit_year
    FROM   DUAL;

    put_log_line( '  Deposit YEAR = ' || ld_deposit_year );


  BEGIN

        SELECT V.target_value1, V.ENABLED_FLAG
        INTO   lc_holiday_flag, lc_holiday_enabled
        FROM   xx_fin_translatedefinition D,
         xx_fin_translatevalues     V
        WHERE  D.translate_id = V.translate_id
        AND    D.translation_name = 'AR_RECEIPTS_BANK_HOLIDAYS'
        AND    UPPER(V.source_value1) = UPPER(ld_deposit_year)
        AND    UPPER(V.source_value2) = UPPER(ld_deposit_date);
        EXCEPTION
             WHEN OTHERS THEN
                  lc_holiday_flag := ' ';
    END;

    put_log_line( '  Holiday table flags = ' || lc_holiday_flag );

    IF lc_holiday_flag = 'Y' AND lc_holiday_enabled = 'Y' THEN
       SELECT TO_DATE(ld_deposit_date,'dd-mon-yy') + 1
       INTO   ld_deposit_date
       FROM   DUAL;
    END IF;

    put_log_line( '  Deposit Date before Holiday check = ' || ld_deposit_date );

    SELECT TO_CHAR(ld_deposit_date,'DAY')
    INTO   ld_deposit_day
    FROM   DUAL;

    put_log_line( '  Deposit DOW = ' || ld_deposit_day );

    IF TRIM(ld_deposit_day) = 'SATURDAY' THEN
       SELECT TO_DATE(ld_deposit_date,'dd-mon-yy') + 2
       INTO   ld_deposit_date
       FROM   DUAL;
    END IF;

    IF TRIM(ld_deposit_day) = 'SUNDAY' THEN
       SELECT TO_DATE(ld_deposit_date,'dd-mon-yy') + 1
       INTO   ld_deposit_date
       FROM   DUAL;
    END IF;

    put_log_line( '  Deposit Date after SUNDAY check = ' || ld_deposit_date );

    SELECT TO_CHAR(ld_deposit_date,'YYYY')
    INTO   ld_deposit_year
    FROM   DUAL;

    put_log_line( '  Deposit YEAR = ' || ld_deposit_year );

    BEGIN

        SELECT V.target_value1, V.ENABLED_FLAG
        INTO   lc_holiday_flag, lc_holiday_enabled
        FROM   xx_fin_translatedefinition D,
         xx_fin_translatevalues     V
        WHERE  D.translate_id = V.translate_id
        AND    D.translation_name = 'AR_RECEIPTS_BANK_HOLIDAYS'
        AND    UPPER(V.source_value1) = UPPER(ld_deposit_year)
        AND    UPPER(V.source_value2) = UPPER(ld_deposit_date);
        EXCEPTION
             WHEN OTHERS THEN
                  lc_holiday_flag := ' ';
    END;

    put_log_line( '  Holiday table flags = ' || lc_holiday_flag );

    IF lc_holiday_flag = 'Y' AND lc_holiday_enabled = 'Y' THEN
       SELECT TO_DATE(ld_deposit_date,'dd-mon-yy') + 1
       INTO   ld_deposit_date
       FROM   DUAL;
    END IF;

    put_log_line( '  Deposit Date after Holiday check = ' || ld_deposit_date );

    -- validate and default the GL date for the payment interface
    IF (NOT ARP_STANDARD.validate_and_default_gl_date
            ( gl_date                => ld_deposit_date,
              trx_date               => ld_deposit_date,
              validation_date1       => NULL,
              validation_date2       => NULL,
              validation_date3       => NULL,
              default_date1          => NULL,
              default_date2          => NULL,
              default_date3          => NULL,
              p_allow_not_open_flag  => NULL,
              p_invoicing_rule_id    => NULL,
              p_set_of_books_id      => NULL,
              p_application_id       => NULL,
              default_gl_date        => ld_gl_date,
              defaulting_rule_used   => x_defaulting_rule_used,
              error_message          => x_error_message ) )
    THEN
      RAISE_APPLICATION_ERROR(-20124,
        ' API Errors [ARP_STANDARD.validate_and_default_gl_date]:' || chr(10) ||
          x_error_message );
    END IF;

    put_log_line( '  GL Date = ' || ld_gl_date );
    put_log_line( '  Rule Used = ' || x_defaulting_rule_used );
  END;


---+===============================================================================================
---|  Get transmission count and totals from record type 9
---+===============================================================================================

     lc_err_pos := 'LCK-1004';

   put_log_line('[WIP] Get transmission count/totals - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

    BEGIN

      SELECT transmission_record_count,
               transmission_amount
        INTO   ln_tran_rec_cnt,
               ln_tran_amt
        FROM   xx_ar_payments_interface
        WHERE  record_type = '9'
            AND    process_num = lc_rcpt_proc_name;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
         lc_err_status := 'Y'; -- Added for defect #5071
         lc_err_mesg := 'There is no 9 record for file'||' '||lc_rcpt_proc_name;-- Added for defect #5071
         RAISE_APPLICATION_ERROR ( -20125,lc_err_mesg);-- Added for defect #5071
    END;

---+===============================================================================================
---|  Get the Lockbox Number for the transmission
---+===============================================================================================

   lc_err_pos := 'LCK-1006';

   put_log_line('[WIP] Get transmission lockboxes - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

    OPEN Lockbox_num_cur(lc_rcpt_proc_name);
    LOOP
      FETCH Lockbox_num_cur INTO Lockbox_num_rec;
      EXIT WHEN Lockbox_num_cur%NOTFOUND;

      BEGIN

        SELECT lockbox_id
          INTO ln_lockbox_id
          FROM ar_lockboxes
         WHERE lockbox_number = Lockbox_num_rec.lockbox_number
           AND status = 'A';

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
         lc_err_status := 'Y';
         lc_err_mesg := 'Lockbox Number '||Lockbox_num_rec.lockbox_number||' Not setup in AR, for File '||p_filename;
         --put_log_line('Error Occured at Position = '||lc_err_pos||' : '||
         --         lc_err_mesg||' : '||SQLCODE||' : '||SQLERRM);
      END;

    END LOOP;
    CLOSE Lockbox_num_cur;


   IF lc_err_status = 'Y' THEN
    --lc_compl_stat := fnd_concurrent.set_completion_status('ERROR','');
    RAISE_APPLICATION_ERROR ( -20004,'Please Setup the Above mentioned Lockboxes');

   END IF;

---+===============================================================================================
---|  If it is a new transmission then create a record in the table ar_transmissions_all
---+===============================================================================================

      lc_err_pos := 'LCK-1007';

    IF lc_trans_ins = 'Y' THEN
      put_log_line('[WIP] Insert Transmission  - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

       SELECT fnd_concurrent_requests_s.nextval,
          ar_transmissions_s.nextval
       INTO   ln_tran_req_id,
          ln_transmission_id
       FROM   dual;

      INSERT INTO ar_transmissions_all
      VALUES
      ( ln_tran_req_id          -- TRANSMISSION_REQUEST_ID
        ,fnd_global.user_id          -- CREATED_BY
        ,trunc(sysdate)              -- CREATION_DATE
        ,fnd_global.user_id          -- LAST_UPDATED_BY
        ,trunc(sysdate)              -- LAST_UPDATE_DATE
        ,NULL                        -- LAST_UPDATE_LOGIN
        ,trunc(sysdate)              -- TRANS_DATE
        ,to_char(sysdate,'HH:MI')    -- TIME
        ,ln_tran_rec_cnt             -- COUNT
        ,ln_tran_amt                 -- AMOUNT
        ,0                           -- VALIDATED_COUNT
        ,0                           -- VALIDATED_AMOUNT
        ,NULL                        -- ORIGIN
        ,NULL                        -- DESTINATION
        ,'NB'                        -- STATUS
        ,NULL                        -- COMMENTS
        ,NULL                        -- REQUESTED_LOCKBOX_ID
        ,ln_trans_for_id   -- REQUESTED_TRANS_FORMAT_ID
        ,NULL           -- REQUESTED_GL_DATE
        ,NULL           -- ATTRIBUTE_CATEGORY
        ,NULL           -- ATTRIBUTE1
        ,NULL           -- ATTRIBUTE2
        ,NULL           -- ATTRIBUTE3
        ,NULL           -- ATTRIBUTE4
        ,NULL           -- ATTRIBUTE5
        ,NULL           -- ATTRIBUTE6
        ,NULL           -- ATTRIBUTE7
        ,NULL           -- ATTRIBUTE8
        ,NULL           -- ATTRIBUTE9
        ,NULL           -- ATTRIBUTE10
        ,NULL           -- ATTRIBUTE11
        ,NULL           -- ATTRIBUTE12
        ,NULL           -- ATTRIBUTE13
        ,NULL           -- ATTRIBUTE14
        ,NULL           -- ATTRIBUTE15
        ,lc_trans_name               -- TRANSMISSION_NAME
        ,ln_transmission_id         -- TRANSMISSION_ID
        ,ln_tran_req_id   -- LATEST_REQUEST_ID
        ,fnd_profile.value('ORG_ID') -- ORG_ID
      );
    END IF;-- Commented as moved this to wrapper program for defect#4320

---+===============================================================================================
---|  Call the procedure for Partial matching and Custom auto cash rules
---+===============================================================================================
    lc_err_pos := 'LCK-1008';

   ln_check_digit     := p_check_digit;
   lc_trx_type        := p_trx_type;
   ln_trx_threshold   := p_trx_threshold;
   ln_from_days       := p_from_days;
   ln_to_days         := p_to_days;

   XX_AR_LOCKBOX_PROCESS_PKG.CUSTOM_AUTO_CASH
   ( lc_ac_err_msg,
     ln_ac_ret_code,
     lc_rcpt_proc_name,
     ln_check_digit,
     lc_trx_type,
     ln_trx_threshold,
     ln_from_days,
     ln_to_days,
     p_back_order_configurable -- Added for Defect #3983 on 26-JAN-10
    );

   put_log_line('Return Code:'||ln_ac_ret_code);
   put_log_line('lc_ac_err_msg:'||lc_ac_err_msg);

  IF ln_ac_ret_code = gn_error THEN
    lc_err_mesg := 'Custom Autocash rules failed, Lockbox submition will not proceed without custom rules';
    put_log_line('Error Occured at Position:'||lc_err_mesg||' : '||lc_ac_err_msg);
    RAISE EX_MAIN_EXCEPTION;
  END IF;

      /* QC 407 - Synced invoice amount with receipt amount */
/*      UPDATE xx_ar_payments_interface xxarpi1
         SET amount_applied1 = (SELECT remittance_amount
                                  FROM xx_ar_payments_interface xxarpi2
                                 WHERE xxarpi2.process_num = xxarpi1.process_num
                                   AND xxarpi2.record_type = '6'
                                   AND xxarpi2.batch_name  = xxarpi1.batch_name
                                   AND xxarpi2.item_number = xxarpi1.item_number
                                   AND xxarpi2.process_num = lc_rcpt_proc_name
                                   AND rownum =1
                               )
       WHERE process_num     = lc_rcpt_proc_name
         AND NVL(amount_applied1,0) = 0
         AND invoice1 IS NOT NULL
         AND invoice2 IS NULL
         AND invoice3 IS NULL
         AND record_type = '4'
         AND NOT EXISTS ( SELECT 1 FROM xx_ar_payments_interface xxarpi3
                                  WHERE xxarpi3.process_num = xxarpi1.process_num
                                              AND xxarpi3.record_type = '4'
                                    AND xxarpi3.batch_name  = xxarpi1.batch_name
                                    AND xxarpi3.item_number = xxarpi1.item_number
                                    AND xxarpi3.process_num = lc_rcpt_proc_name
                                    AND xxarpi3.rowid <> xxarpi1.rowid )
        RETURNING         batch_name,item_number,invoice1,amount_applied1
        BULK COLLECT INTO l_batch_name, l_item_number,l_invoice,l_amount;
       /* End Fix QC 407. */
/*
        put_log_line(' [WIP] No of Records Updated - ' || SQL%ROWCOUNT );


---+===============================================================================================
---|  Selected the records from the interim table and insert into the Interface table
---+===============================================================================================

    lc_err_pos := 'LCK-1009';

   put_log_line('[WIP] Move Payment Interface records  - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

    INSERT INTO ar_payments_interface_all
    ( transmission_record_id,
     transmission_request_id,
     record_type,
     gl_date,     -- added for defect 9686
     destination_account,
     origination,
     lockbox_number,
     deposit_date,
     batch_name,
     item_number,
     remittance_amount,
     transit_routing_number,
     account,
     check_number,
     customer_number,
     overflow_sequence,
     overflow_indicator,
     invoice1,
     invoice2,
     invoice3,
     amount_applied1,
     amount_applied2,
     amount_applied3,
     batch_record_count,
     batch_amount,
     lockbox_record_count,
     lockbox_amount,
     transmission_record_count,
     transmission_amount,-- Added for the CR 642 Defect 1486 R1.2
     transmission_id,
     -- bill_to_location,
     attribute_category,
     attribute1,
     attribute2,
     attribute3,
     attribute4,
     attribute5,
     attribute15,
     status,
     creation_date,
     created_by,
     last_update_date,
     last_updated_by )
    ( SELECT
       ar_payments_interface_s.nextval,
       ln_tran_req_id,
       record_type,
       ld_gl_date,     -- added for defect 9686
       destination_account,
       origination,
       lockbox_number,
       ld_deposit_date,   -- added for defect 12067
       batch_name,
       item_number,
       remittance_amount,
       transit_routing_number,
       account,
       check_number,
       customer_number,
       overflow_sequence,
       overflow_indicator,
       trim(invoice1),
       trim(invoice2),
       trim(invoice3),
       amount_applied1,
       amount_applied2,
       amount_applied3,
       batch_record_count,
       batch_amount,
       lockbox_record_count,
       lockbox_amount,
       transmission_record_count,
       transmission_amount,-- Added for the CR 642 Defect 1486 R1.2
       ln_transmission_id,
       --bill_to_location,
       'SALES_ACCT',
       attribute1,
       attribute2,
       attribute3,
       attribute4,
       attribute5,
       inv_match_status,
       status,
       ld_deposit_date,  -- Defect 955
       fnd_global.user_id,
       ld_deposit_date,  -- Defect 955
       fnd_global.user_id
     FROM xx_ar_payments_interface
     WHERE process_num = lc_rcpt_proc_name
    );

---+===============================================================================================
---|  Submit the standard Lockbox process with the required parameters
---+===============================================================================================

    lc_err_pos := 'LCK-1010';

    put_log_line('[WIP] Submit Standard Lockbox  - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

            ln_lck_req_id := FND_REQUEST.SUBMIT_REQUEST
              ( 'AR',
                'ARLPLB',
                '',
                SYSDATE,
                --FALSE,
                TRUE,  -- Added for the Defect 2063
                 'N',                  -- New Transmission
                ln_transmission_id,
                ln_tran_req_id,
                lc_trans_name,
                'N',                   -- Submit Import Flag
                NULL,                  -- Data File Path
                NULL,                  -- Data File Name
                ln_trans_for_id,       -- Transmission Format
                'Y',                   -- Submit Validation Flag
                'N',                   -- Pay Unrelated Invoices Flag
                NULL, --ln_lockbox_id, -- Internal ID For Lockbox #
                TO_CHAR(ld_gl_date,'YYYY/MM/DD HH24:MI:SS'),   -- GL Date (defect 9686)
                'R',                   -- Report Format (Show Only Rejected)
                'N',                   -- Complete Batches Only Flag
                'Y',                   -- Submit Post Batch Process Flag
                'N',                   -- Use Alternate Name Search
                'Y',                   -- Post Partial Amount
                NULL,
                fnd_profile.value('ORG_ID')
                );

           COMMIT;

        put_log_line('[WIP] Request ID of Standard Lockbox  '||ln_lck_req_id);     --Added for defect 2063
        ---- Commented as moved this to wrapper program for defect#4320

---+===============================================================================================
---|  Check if the lockbox process completed normal
---+===============================================================================================
  /* IF ln_lck_req_id > 0 THEN
     lc_lb_wait := fnd_concurrent.wait_for_request
     ( ln_lck_req_id,
       10,
       0,
       lc_conc_phase,
       lc_conc_status,
       lc_dev_phase,
       lc_dev_status,
       lc_conc_message );
   END IF;                      -- Commented for the Defect # 2063.

          IF trim(lc_conc_status) = 'Error' THEN
            lc_err_status := 'Y';
            lc_err_mesg := 'Lockbox Process Completed in Error, Please check the Log file for Request ID : '||
                                ln_lck_req_id;
            --put_log_line('Error Occured at Position = '||lc_err_pos||' : '||
            --         lc_err_mesg||' : '||SQLCODE||' : '||SQLERRM);
            --lc_compl_stat := fnd_concurrent.set_completion_status('ERROR','');
            RAISE_APPLICATION_ERROR ( -20005,lc_err_mesg);

          END IF;  */         -- Commented for Defect 2063
---+===============================================================================================
---|  Generate report for the $0 payment in the concurrent request output file
---+===============================================================================================
/*
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '**********************************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$0 PAYMENT REPORT~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '**********************************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' TRANMISSION NAME     : ' || lc_trans_name);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '**********************************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~LIST OF INVOICES UPDATED FOR $0 PAYMENT REPORT~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '**********************************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      ' INVOICE NUMBER                                                                    AMOUNT                 ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '**********************************************************************************************************');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));

      FOR i in 1..l_invoice.COUNT LOOP
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
        '    '||l_invoice(i) ||'                                                                        ' || l_amount(i));
      END LOOP;

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
      '**********************************************************************************************************');

       FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>'COMPLETE'); --Added for defect 2063
       COMMIT;

       RETURN;                                                                           --Added for defect 2063
    END IF;                                                                              --endif_second

---+===============================================================================================
---|  Check if there are any errors and set the completion status to WARNING
---+===============================================================================================

  IF (NVL(lc_chk_flag,'FIRST') ='COMPLETE') THEN                                                 --Added for defect 2063  
if_complete

  IF lc_err_mesg = 'Y' THEN
    lc_compl_stat := fnd_concurrent.set_completion_status('WARNING','');
  END IF;

---+===============================================================================================
---|  Handle the Other exceptions
---+===============================================================================================

  IF p_email_notf IS NOT NULL THEN
    -- -------------------------------------------
    -- Call the Common Emailer Program
    -- -------------------------------------------
    ln_mail_request_id :=
      FND_REQUEST.SUBMIT_REQUEST
      (application => 'xxfin'
      ,program     => 'XXODROEMAILER'
      ,description => ''
      ,sub_request => TRUE
      ,start_time  => TO_CHAR(SYSDATE, 'DD-MON-YY HH:MI:SS')
      ,argument1   => ''
      ,argument2   => p_email_notf
      ,argument3   => 'AR Lockbox Custom Partial Invoice Match  - ' ||TRUNC(SYSDATE)
      ,argument4   => ''
      ,argument5   => 'Y'
      ,argument6   => gn_request_id
      );
    COMMIT;

    IF ln_mail_request_id IS NULL OR ln_mail_request_id = 0 THEN
      lc_err_pos := 'Failed to submit the Standard Common Emailer Program';
      RAISE EX_MAIN_EXCEPTION;
    END IF;
  END IF;
  -----------------------------------------
  -- Start of Changes for the Defect #4128
  -----------------------------------------
    BEGIN
          SELECT SUM(CASE WHEN status_code = 'E'
                          THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN status_code = 'G'
                          THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN status_code = 'C'
                          THEN 1 ELSE 0 END)
          INTO   ln_err_cnt
                ,ln_wrn_cnt
                ,ln_nrm_cnt
          FROM   fnd_concurrent_requests
          WHERE  priority_request_id = gn_request_id;

          IF ln_err_cnt > 0 THEN
             put_log_line('Child requests of OD: AR Lockbox Process - Mains ended in Error');
             x_errbuf  := 'Completion of OD: AR Lockbox Process - Mains program';
             x_retcode := 2;
          ELSIF ln_wrn_cnt > 0 AND ln_err_cnt = 0 THEN
             put_log_line('Child requests of OD: AR Lockbox Process - Mains ended in warning');
             x_errbuf  := 'Completion of OD: AR Lockbox Process - Mains program';
             x_retcode := 1;
          ELSIF ln_err_cnt = 0 AND ln_wrn_cnt = 0 AND ln_nrm_cnt > 0 THEN
             x_errbuf  := 'Completion of OD: AR Lockbox Process - Mains program';
             x_retcode := 0;
          END IF;
    EXCEPTION
          WHEN NO_DATA_FOUND THEN
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Child Programs Submitted');
             x_errbuf  := 'Completion of OD: AR Lockbox Process - Mains program';
             x_retcode := 0;
    END;
  -----------------------------------------
  -- End of Changes for the Defect #4128
  -----------------------------------------
 END IF;                               --endif_complete

 --Added as part of defect 3316
 --invoke BPEL process to release ESP jobs
 INVOKE_ESP_BPEL_PROCESS(p_filename);

EXCEPTION
WHEN EX_MAIN_EXCEPTION THEN
  x_errbuf   := lc_err_pos ||'-'||lc_err_mesg;
  x_retcode  := gn_error;
  -- -------------------------------------------
  -- Call the Custom Common Error Handling
  -- -------------------------------------------
  XX_COM_ERROR_LOG_PUB.LOG_ERROR
  ( p_program_type            => 'CONCURRENT PROGRAM'
   ,p_program_name            => gc_conc_short_name
   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
   ,p_module_name             => 'AR'
   ,p_error_location          => 'Error at ' || lc_err_pos
   ,p_error_message_count     => 1
   ,p_error_message_code      => 'E'
   ,p_error_message           => lc_err_mesg
   ,p_error_message_severity  => 'Major'
   ,p_notify_flag             => 'N'
   ,p_object_type             => 'Main Lockbox Process'
  );
  put_log_line('==========================');
  put_log_line(x_errbuf);
  ROLLBACK;
WHEN OTHERS THEN
  lc_err_mesg := 'Error Occured at Position = '||lc_err_pos||' : '||SQLCODE||' : '||SQLERRM;
  x_errbuf := SQLERRM;
  x_retcode := 2;
  put_log_line(lc_err_mesg);
  XX_COM_ERROR_LOG_PUB.LOG_ERROR
  ( p_program_type             => 'CONCURRENT PROGRAM'
   ,p_program_name            => 'AR CUSTOM LOCKBOX'
   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
   ,p_module_name             => 'AR'
   ,p_error_location          => 'Error at ' || lc_err_pos
   ,p_error_message_count     => 1
   ,p_error_message_code      => 'E'
   ,p_error_message           => lc_err_mesg
   ,p_error_message_severity  => 'Major'
   ,p_notify_flag             => 'N'
   ,p_object_type             => 'Main Lockbox Process'
  );

  lc_compl_stat := fnd_concurrent.set_completion_status('ERROR','');
  ROLLBACK;
END LOCKBOX_PROCESS_MAIN;
*/ -- Commented for the Defect #4320
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Providge Consulting                                  |
-- +=================================================================================+
-- | Name       : xx_ar_lockbox_process_pkg.pkb                                      |
-- | Description: AR Lockbox Custom Auto Cash Rules E0062-Extension                  |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |DRAFT 1A  29-AUG-2007  Sunayan Mohanty    Initial draft version                  |
-- |1.0       22-OCT-2009  RamyaPriya M       Modified for the CR #684               |
-- +=================================================================================+
-- | Name        : VALID_CUSTOMER                                                    |
-- | Description : This procedure will be used to check the valid                    |
-- |               Customer Lockbox records                                          |
-- |                                                                                 |
-- | Parameters  : p_transit_routing_num                                             |
-- |               p_account                                                         |
-- |                                                                                 |
-- | Returns     : x_customer_id                                                     |
-- |               x_party_id                                                        |
-- |                                                                                 |
-- +=================================================================================+
/*FUNCTION valid_customer   (p_transit_routing_num   IN           VARCHAR2
                          ,p_account               IN           VARCHAR2
                          )RETURN NUMBER
IS
  -- -------------------------------------------
  -- Get the Valid customer based on the
  -- bank routing number and bank act number
  -- -------------------------------------------
  CURSOR lcu_get_customer   ( p_routing_num   IN   ap_bank_branches.bank_num%TYPE
                             ,p_bank_act_num  IN   ap_bank_accounts_all.bank_account_num%TYPE
                            )
  IS
  SELECT ABAU.customer_id
        ,ABAU.customer_site_use_id
  FROM   ap_bank_account_uses            ABAU
       , ap_bank_accounts                ABA
       , ap_bank_branches                ABB
  WHERE  ABAU.external_bank_account_id      =  ABA.bank_account_id
  AND    ABA.bank_branch_id                 =  ABB.bank_branch_id
  AND    ABB.bank_num                       =  TRIM(p_routing_num)
  AND    ABA.bank_account_num               =  TRIM(p_bank_act_num)
  AND    NVL(ABAU.start_date,SYSDATE)      <=  ld_deposit_date
  AND    NVL(ABAU.end_date, TO_DATE('31-12-4712 00:00:00', 'DD-MM-YYYY HH24:MI:SS'))   >=  ld_deposit_date
  AND    NVL(ABA.inactive_date,TO_DATE('31-12-4712 00:00:00', 'DD-MM-YYYY HH24:MI:SS')) >=  ld_deposit_date
  AND    NVL(ABB.end_date, TO_DATE('31-12-4712 00:00:00', 'DD-MM-YYYY HH24:MI:SS'))    >=  ld_deposit_date
  AND    ABAU.customer_id IS NOT NULL;

  -- -------------------------------------------
  -- Loccal Variable Decalration
  -- -------------------------------------------
  ln_customer_id               NUMBER;
  ln_customer_site_use_id      NUMBER;

BEGIN

  -- -------------------------------------------
  -- Open the cursor and check for valid customer
  -- -------------------------------------------
  OPEN  lcu_get_customer ( p_routing_num   => p_transit_routing_num
                          ,p_bank_act_num  => p_account
                         );
  FETCH lcu_get_customer INTO  ln_customer_id
                              ,ln_customer_site_use_id;

  -- -------------------------------------------
  -- Check the Duplicate Customer
  -- -------------------------------------------
  put_log_line('Customer Id:'||ln_customer_id);
  put_log_line('lcu_get_customer%ROWCOUNT:'||lcu_get_customer%ROWCOUNT);
  IF lcu_get_customer%ROWCOUNT > 1 THEN
    fnd_message.set_name ('XXFIN','XX_AR_204_DUP_CUSTOMER');
    fnd_message.set_token('ROUTING_NUM',p_transit_routing_num);
    fnd_message.set_token('ACCOUNT_NUM',p_account);
    put_log_line(fnd_message.get);
    --RETURN 0;  --Commented for the defect #976
    RETURN -1;   --Added for the defect #976
  ELSE
    -- -------------------------------------------
    -- Return the customer number
    -- -------------------------------------------
    IF ln_customer_id IS NOT NULL THEN
      RETURN ln_customer_id;
    ELSE
      RETURN 0;
    END IF;
  END IF;
  CLOSE lcu_get_customer;

EXCEPTION
WHEN OTHERS THEN
  RETURN 0;
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.VALID_CUSTOMER');
  fnd_message.set_token('PROGRAM','Lockbox Valid Customer Checking');
  fnd_message.set_token('SQLERROR',SQLERRM);
  put_log_line('==========================');
  put_log_line(fnd_message.get);
END valid_customer;
*/  --Commented for the CR#684 -- Defect #976
--------------------------------------------------------------------------
-- Start of Changes for CR#684 --Defect #976
--------------------------------------------------------------------------
PROCEDURE  valid_customer (x_customer_id             OUT   NOCOPY   NUMBER
                          ,x_party_id                OUT   NOCOPY   NUMBER
                          ,x_micr_cust_num           OUT   NOCOPY   VARCHAR2
                          ,p_transit_routing_num      IN            VARCHAR2
                          ,p_account                  IN            VARCHAR2
                          )
IS
  -- -------------------------------------------
  -- Local Variable Declaration
  -- -------------------------------------------
BEGIN
--------------------------------------------------
--Commented for CR #684 -- Defect #976 on 11-DEC-09
---------------------------------------------------
  /*
  SELECT ABAU.customer_id             --Added for CR#684 -- Defect #976 on 11-DEC-09
        ,HCA.party_id                          --Added for CR#684
        ,HCA.account_number                    --Added for CR#684
  INTO   x_customer_id
        ,x_party_id
        ,x_micr_cust_num
  FROM   ap_bank_account_uses            ABAU
       , ap_bank_accounts                ABA
       , ap_bank_branches                ABB
       , hz_cust_accounts                HCA   --Added for CR#684
  WHERE  ABAU.external_bank_account_id      =  ABA.bank_account_id
  AND    HCA.cust_account_id                =  ABAU.customer_id    --Added for CR#684
  AND    ABA.bank_branch_id                 =  ABB.bank_branch_id
  AND    ABB.bank_num                       =  TRIM(p_transit_routing_num)
  AND    ABA.bank_account_num               =  TRIM(p_account)
  AND    NVL(ABAU.attribute1,'-1')         <>  'ACH' --1.54 Defect#19194
  AND    NVL(ABAU.start_date,SYSDATE)      <=  ld_deposit_date
  AND    NVL(ABAU.end_date, TO_DATE('31-12-4712 00:00:00', 'DD-MM-YYYY HH24:MI:SS'))   >=  ld_deposit_date
  AND    NVL(ABA.inactive_date,TO_DATE('31-12-4712 00:00:00', 'DD-MM-YYYY HH24:MI:SS')) >=  ld_deposit_date
  AND    NVL(ABB.end_date, TO_DATE('31-12-4712 00:00:00', 'DD-MM-YYYY HH24:MI:SS'))    >=  ld_deposit_date
  AND    ABAU.customer_id IS NOT NULL;
  */
  -- -------------------------------------------------------------------------------------------------
  -- Get the Valid customer based on the bank routing number and bank acct number
  -- Added below SQL for CR #684 (Defect #976) on 11-DEC-09
  -- since Bank account can be assigned to the customer
  -- either at the Customer level or at the Customer site level.
  -- MICR combination is valid as long as it is assigned to same Customer
  -- -------------------------------------------------------------------------------------------------
    --New query created for R12 retrofit (1.55)
	SELECT HCA.cust_account_id
          ,HCA.party_id
          ,HCA.account_number	 
    INTO   x_customer_id
          ,x_party_id
          ,x_micr_cust_num		  	       
	FROM IBY_EXT_BANK_ACCOUNTS ext_bank, 
	     IBY_EXTERNAL_PAYERS_ALL ext_payer,
		   hz_cust_accounts hca,
		   iby_pmt_instr_uses_all acc_instr,
       iby_ext_bank_branches_v branch		 
	WHERE branch.branch_number = TRIM(p_transit_routing_num)
	  AND ext_bank.bank_account_num = TRIM(p_account)
	  AND acc_instr.start_date <=   ld_deposit_date --Changed for QC Defect 26700
      AND NVL(acc_instr.end_date, TO_DATE('31-12-4712 00:00:00', 'DD-MM-YYYY HH24:MI:SS'))   >=  ld_deposit_date
      AND NVL(ext_bank.end_date,TO_DATE('31-12-4712 00:00:00', 'DD-MM-YYYY HH24:MI:SS'))     >=   ld_deposit_date
	  AND branch.branch_party_id = ext_bank.branch_id
      AND acc_instr.ext_pmt_party_id = ext_payer.ext_payer_id
	  AND ext_payer.cust_account_id = hca.cust_account_id
	  AND ext_bank.ext_bank_account_id = acc_instr.instrument_id
      --AND acc_instr.ext_pmt_party_id = ext_payer.ext_payer_id -- Commented this for defect 28062
      AND acc_instr.instrument_type='BANKACCOUNT'; -- Included this condition for defect 28062
	
    /*	Query commented for R12 retrofit.
    SELECT HCA.cust_account_id
          ,HCA.party_id
          ,HCA.account_number
    INTO   x_customer_id
          ,x_party_id
          ,x_micr_cust_num
    FROM   hz_cust_accounts         HCA
    WHERE  1=1
      AND  EXISTS (SELECT  1
                   FROM   ap_bank_account_uses            ABAU
                        , ap_bank_accounts                ABA
                        , ap_bank_branches                ABB
                   WHERE    ABAU.external_bank_account_id      =  ABA.bank_account_id
                     AND    ABAU.customer_id                   =  HCA.cust_account_id
                     AND    ABA.bank_branch_id                 =  ABB.bank_branch_id
                     AND    ABB.bank_num                       =  TRIM(p_transit_routing_num)
                     AND    ABA.bank_account_num               =  TRIM(p_account)
                     AND    NVL(ABAU.start_date,SYSDATE)      <=  ld_deposit_date
                     AND    NVL(ABAU.end_date, TO_DATE('31-12-4712 00:00:00', 'DD-MM-YYYY HH24:MI:SS'))   >=  ld_deposit_date
                     AND    NVL(ABA.inactive_date,TO_DATE('31-12-4712 00:00:00', 'DD-MM-YYYY HH24:MI:SS')) >=  
ld_deposit_date
                     AND    NVL(ABB.end_date, TO_DATE('31-12-4712 00:00:00', 'DD-MM-YYYY HH24:MI:SS'))    >=  ld_deposit_date
                     AND    ABAU.customer_id IS NOT NULL
                   );
	*/
  -- -------------------------------------------
  -- Check the Duplicate Customer
  -- -------------------------------------------
  put_log_line('MICR Customer Id:'||x_customer_id);
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      x_customer_id := 0;
      x_party_id    := 0;
      x_micr_cust_num := NULL;
      put_log_line('No Data found for MICR Customer ID');
   WHEN TOO_MANY_ROWS THEN
      put_log_line('Too Many Values for MICR Customer ID');
      fnd_message.set_name ('XXFIN','XX_AR_204_DUP_CUSTOMER');
      fnd_message.set_token('ROUTING_NUM',p_transit_routing_num);
      fnd_message.set_token('ACCOUNT_NUM',p_account);
      put_log_line(fnd_message.get);
      x_customer_id := -1;
      x_party_id    := -1;
      x_micr_cust_num := NULL;
    WHEN OTHERS THEN
      x_customer_id := 0;
      x_party_id    := 0;
      fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
      fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.VALID_CUSTOMER');
      fnd_message.set_token('PROGRAM','Lockbox Valid Customer Checking');
      fnd_message.set_token('SQLERROR',SQLERRM);
      put_log_line('==========================');
      put_log_line(fnd_message.get);
END valid_customer;
--------------------------------------------------------------------------
-- End of Changes for CR#684 --Defect #976
--------------------------------------------------------------------------
-- +=================================================================================+
-- | Name        : CHECK_POSITION_MATCH                                              |
-- | Description : This function will be used to check the valid                     |
-- |               Customer Lockbox records                                          |
-- |                                                                                 |
-- | Parameters  : p_oracle_invoice                                                  |
-- |               p_custom_invoice                                                  |
-- |               p_profile_digit_check                                             |
-- | Returns     : BOOLEAN                                                           |
-- |                                                                                 |
-- |                                                                                 |
-- +=================================================================================+
FUNCTION check_position_match
(p_oracle_invoice      IN VARCHAR2
,p_custom_invoice      IN VARCHAR2
,p_profile_digit_check IN NUMBER
)
RETURN BOOLEAN
IS
  -- -------------------------------------------
  -- Local Variable Decalration
  -- -------------------------------------------
  ln_match_counter        NUMBER          := 0;
  ln_limit_pos            NUMBER          := 9;
  ln_offset               NUMBER          := 0;
  li_index                INTEGER         := 1;
  ln_tolerance            NUMBER          := 20;
  ln_tol_index            NUMBER          := 0;

  ln_direction            NUMBER          := 0;

  lc_track_match          VARCHAR2(4000)  := NULL;

BEGIN
  put_log_line('Position Match');
  put_log_line('  p_oracle_invoice = "' || p_oracle_invoice || '"' );
  put_log_line('  p_custom_invoice = "' || p_custom_invoice || '"' );
  put_log_line('  p_profile_digit_check = "' || p_profile_digit_check || '"' );

  ln_match_counter := 0;

  -- ====================================================================================
  -- loop through oracle number, matching at least p_profile_digit_check digits in custom
  --    i.e.   examples based on 6-digit match
  --           123456789 matches 1234XXX89 - (couple numbers incorrect)
  --           123456789 does not match 234567891 (missing numbers) - use next algorithm
  -- ====================================================================================
  FOR i IN 1..LEAST(LENGTH(p_custom_invoice),ln_limit_pos) LOOP
    IF ( SUBSTR(p_custom_invoice,i,1) = SUBSTR(p_oracle_invoice,i,1) ) THEN
      lc_track_match := lc_track_match || i || 'x, ';
      ln_match_counter := ln_match_counter + 1;
    END IF;
  END LOOP;

  -- ====================================================================================
  -- if no match was found using above partial invoice match, use next matching algorithm
  -- ====================================================================================
  IF (ln_match_counter < p_profile_digit_check) THEN
    ln_match_counter := 0;
    li_index := 1;

    -- ====================================================================================
    -- loop through oracle number, matching a part of the custom invoice number
    --   considers missing numbers
    --    i.e.   examples based on 6-digit match
    --           123456789 matches 23456789 (missing digits)
    --           123456789 matches 1234789 (missing digits)
    --           123456789 matches 12345611789 (additional digits)
    -- ====================================================================================
    LOOP
      IF ( li_index+ln_offset < LEAST(LENGTH(p_oracle_invoice),ln_limit_pos) AND ln_direction IN (0,1)
         AND SUBSTR(p_custom_invoice,li_index,1) = SUBSTR(p_oracle_invoice,li_index+ln_offset,1) )
      THEN
        lc_track_match := lc_track_match || li_index || ':' || ln_offset || 'a, ';
        ln_match_counter := ln_match_counter + 1;
        li_index := li_index + 1;
        ln_direction := 1;
      ELSIF ( li_index+ln_offset < LEAST(LENGTH(p_custom_invoice),ln_limit_pos) AND ln_direction IN (0,-1)
         AND SUBSTR(p_custom_invoice,li_index+ln_offset,1) = SUBSTR(p_oracle_invoice,li_index,1) )
      THEN
        lc_track_match := lc_track_match || li_index || ':' || ln_offset || 'b, ';
        ln_match_counter := ln_match_counter + 1;
        li_index := li_index + 1;
        ln_direction := -1;
      ELSE
        lc_track_match := lc_track_match || li_index || ':' || ln_offset || 'c, ';
        EXIT WHEN ( li_index+ln_offset
          > GREATEST(LEAST(LENGTH(p_custom_invoice),ln_limit_pos),
                 LEAST(LENGTH(p_oracle_invoice),ln_limit_pos)) );
        ln_offset := ln_offset + 1;
      END IF;

      EXIT WHEN
        (  li_index >= LENGTH(p_custom_invoice)
        OR ln_match_counter >= p_profile_digit_check );

      ln_tol_index := ln_tol_index + 1;
      EXIT WHEN ln_tol_index > ln_tolerance;   -- just as a fallback, prevent infinite loops
    END LOOP;
  END IF;


  -- -------------------------------------------
  -- Loop Through 9 time and check wheather
  -- the matching should p_profile_digit_check
  -- number
  -- -------------------------------------------
  /* FOR i IN 1..9 LOOP

    IF SUBSTR(p_custom_invoice,i,1) = SUBSTR(p_oracle_invoice,i,1) THEN
       ln_match_counter := ln_match_counter + 1;
    ELSIF SUBSTR(p_custom_invoice,(i+1),1) = SUBSTR(p_oracle_invoice,i,1) THEN
      ln_match_counter := ln_match_counter + 1;
    ELSIF SUBSTR(p_custom_invoice,(i-1),1) = SUBSTR(p_oracle_invoice,i,1) THEN
      ln_match_counter := ln_match_counter + 1;
    END IF;

  END LOOP; */

  put_log_line('* Matching: ' || lc_track_match );

  --put_log_line('Match Counter :' || ln_match_counter);
  IF ln_match_counter >= p_profile_digit_check THEN
    put_log_line('Invoice Matched ');
    RETURN TRUE;
  ELSE
    --put_log_line('Invoice Not Matched ');
    RETURN FALSE;
  END IF;

EXCEPTION
WHEN OTHERS THEN
-- put_log_line('In exception block. Oracle error message = '||substr(sqlerrm,1,200));
  RETURN FALSE;
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.CHECK_POSITION_MATCH');
  fnd_message.set_token('PROGRAM','Partial Invoice Matching Process');
  fnd_message.set_token('SQLERROR',SQLERRM);
  put_log_line('==========================');
  put_log_line(fnd_message.get);
END check_position_match;

-- +=================================================================================+
-- | Name        : DISCOUNT_CALCULATE                                                |
-- | Description : This function will be used to check the valid                     |
-- |               discount % for the customer and consider the best one             |
-- |               Modified for the Defect #3984 on 04-FEB-10                        |
-- |                                                                                 |
-- | Parameters  : p_term_id                                                         |
-- |               p_diff_days                                                       |
-- |                                                                                 |
-- | Returns     : NUMBER                                                            |
-- |                                                                                 |
-- |                                                                                 |
-- +=================================================================================+
FUNCTION discount_calculate
(p_payment_term_id       IN NUMBER
,p_trx_date              IN DATE
,p_deposit_date          IN DATE
)RETURN NUMBER
IS
  -- -------------------------------------------
  -- Local Variable Decalration
  -- -------------------------------------------
  ln_discount_percent          NUMBER := NULL;
  ln_payment_diff_days         NUMBER;
  lc_trxn_day                  VARCHAR2(10);
  lc_trxn_mnth                 VARCHAR2(50);
  lc_trxn_year                 VARCHAR2(50);
  ln_actual_discount_mnth_fwd  NUMBER;
  lc_discount_expiry_day       VARCHAR2(10);
  lc_discount_expiry_mnth      VARCHAR2(50);
  lc_discount_expiry_year      VARCHAR2(50);
  ld_add_month_date            DATE;
  ld_expiry_discount_date      DATE;
  ln_temp_disc_percent         NUMBER := NULL;
  ln_temp_discount             NUMBER := 0;
  BEGIN
    ln_payment_diff_days := p_deposit_date - p_trx_date;
    lc_trxn_day          := TO_CHAR(p_trx_date,'DD');
    lc_trxn_mnth         := TO_CHAR(p_trx_date,'MM');
    lc_trxn_year         := TO_CHAR(p_trx_date,'YYYY');

  -- -------------------------------------------
  -- Loop through all the discounts for the
  -- customer and check the best discount
  -- percent for the diierence payment days
  -- -------------------------------------------

  FOR ln_disc_cnt IN 1..lcu_discount_rec_tbl.COUNT
  LOOP
   IF(lcu_discount_rec_tbl(ln_disc_cnt).term_id = p_payment_term_id) THEN
      IF (lcu_discount_rec_tbl(ln_disc_cnt).discount_days IS NULL) THEN
-------------------------------------------------------
-- Calculate Discount % based on Discount day of month
-------------------------------------------------------
         IF(lc_trxn_day > lcu_discount_rec_tbl(ln_disc_cnt).due_day_of_month) THEN
             ln_actual_discount_mnth_fwd := lcu_discount_rec_tbl(ln_disc_cnt).discount_months_forward + 1;
         ELSE
             ln_actual_discount_mnth_fwd := lcu_discount_rec_tbl(ln_disc_cnt).discount_months_forward;
         END IF;
             lc_discount_expiry_day  := lcu_discount_rec_tbl(ln_disc_cnt).discount_day_of_month;
             ld_add_month_date       := TO_DATE(lc_discount_expiry_day||'-'||lc_trxn_mnth||'-'||lc_trxn_year,'DD-MM-YYYY');
             ld_expiry_discount_date := ADD_MONTHS(ld_add_month_date,ln_actual_discount_mnth_fwd);

        IF(TO_DATE(p_deposit_date,'DD-MM-YYYY') <= TO_DATE(ld_expiry_discount_date,'DD-MM-YYYY')) THEN
                    ln_discount_percent := lcu_discount_rec_tbl(ln_disc_cnt).discount_percent;
                    RETURN ln_discount_percent;
        END IF;
----------------------------------------------
-- Calculate Discount % based on Discount day
----------------------------------------------
      ELSIF (lcu_discount_rec_tbl(ln_disc_cnt).discount_days >= ln_payment_diff_days) THEN
            ln_discount_percent := lcu_discount_rec_tbl(ln_disc_cnt).discount_percent;
            RETURN ln_discount_percent;
      END IF;
   END IF;
  END LOOP;

  IF ln_discount_percent IS NULL THEN
    ln_discount_percent := 0;
    RETURN ln_discount_percent;
  ELSE
    RETURN ln_discount_percent;
  END IF;

EXCEPTION
WHEN OTHERS THEN
-- put_log_line('In exception block. Oracle error message = '||substr(sqlerrm,1,200));
  RETURN 0;
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.DISCOUNT_CALCULATE');
  fnd_message.set_token('PROGRAM','Discount Calculate for the Payment Terms');
  fnd_message.set_token('SQLERROR',SQLERRM);
END discount_calculate;

/*FUNCTION discount_calculate
(p_payment_term_id       IN NUMBER
,p_paymentr_diff_days    IN NUMBER
)RETURN NUMBER
IS
  -- -------------------------------------------
  -- Cursor to get the discount % and different
  -- days for apply discounts for individual customer
  -- and based on the deposit date and transaction date
  -- -------------------------------------------
  CURSOR lcu_get_discount  (p_term_id  IN ra_terms_b.term_id%TYPE)
  IS
  SELECT RTV.term_id
        ,RTL.sequence_num
        ,RTL.due_days
        ,RTLD.terms_lines_discount_id
        ,RTLD.discount_percent
        ,RTLD.discount_days
  FROM   ra_terms_lines_discounts  RTLD
        ,ra_terms_vl               RTV
        ,ra_terms_lines            RTL
  WHERE  RTLD.term_id                 =   RTV.term_id
  AND    RTLD.term_id                 =   RTL.term_id
  AND    RTLD.sequence_num            =   RTL.sequence_num
  AND    SYSDATE BETWEEN RTV.start_date_active  AND  NVL(RTV.end_date_active, SYSDATE + 1)
  AND    RTLD.term_id                 =   p_term_id
  --AND    RTV.in_use                   =  'Y'
  ORDER BY  RTV.term_id
           ,RTL.sequence_num
           ,RTL.due_days
           ,RTLD.terms_lines_discount_id;

  -- -------------------------------------------
  -- Local Variable Decalration
  -- -------------------------------------------
  get_discount_rec           lcu_get_discount%ROWTYPE;

  ln_discount_percent        NUMBER;

BEGIN

  -- -------------------------------------------
  -- Loop through all the discounts for the
  -- customer and check the best discount
  -- percent for the diierence payment days
  -- -------------------------------------------
  OPEN  lcu_get_discount ( p_term_id  =>  p_payment_term_id );
  LOOP
  FETCH lcu_get_discount  INTO get_discount_rec;
  EXIT WHEN lcu_get_discount%NOTFOUND;

    IF get_discount_rec.discount_days >= p_paymentr_diff_days THEN

       ln_discount_percent := get_discount_rec.discount_percent;

    END IF;

  END LOOP;
  CLOSE lcu_get_discount;

  IF ln_discount_percent IS NULL THEN
    ln_discount_percent := 0;
    RETURN ln_discount_percent;
  ELSE
    RETURN ln_discount_percent;
  END IF;

  /*
  put_log_line('Discount Percent :' || );
  */
/*
EXCEPTION
WHEN OTHERS THEN
-- put_log_line('In exception block. Oracle error message = '||substr(sqlerrm,1,200));
  RETURN 0;
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.DISCOUNT_CALCULATE');
  fnd_message.set_token('PROGRAM','Discount Calculate for the Payment Terms');
  fnd_message.set_token('SQLERROR',SQLERRM);
  put_log_line('==========================');
  put_log_line(fnd_message.get);
END discount_calculate;
*/   --Commented for the Defect #3984
-- +=================================================================================+
-- | Name        : PRINT_MESSAGE_HEADER                                              |
-- | Description : This procedure will be used to print the                          |
-- |               record process details                                            |
-- |                                                                                 |
-- | Parameters  : None                                                              |
-- |                                                                                 |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE print_message_header
(x_errmsg             OUT   NOCOPY  VARCHAR2
,x_retstatus          OUT   NOCOPY  NUMBER
)
IS
BEGIN
  -- ------------------------------------------------
  -- Set the Concurrent program Output header display
  -- ------------------------------------------------
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',50,'=')||'   Office Depot    '||RPAD('=',50,'='));
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LPAD('Invoice Partial Match',76,' '));
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Request ID : '||gn_request_id||RPAD(' ',60,' ')||'Request Date : '||TO_CHAR
(SYSDATE,'DD-MON-YYYY HH:MM:SS'));
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',125,'='));

  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('Cust# From Bank ',23)||RPAD('Check# ',15)||RPAD('Tran# ',23)||RPAD('Amt# ',15)||
RPAD('Substituted Inv # ',23)||RPAD('Amt# ',23));
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',(20-1),'-')||'    '||RPAD('-',(12-1),'-')||'      '||RPAD('-',(25-1),'-')||
RPAD('-',(20-1),'-')||RPAD('-',(20-1),'-')||RPAD('-',(20-1),'-')||''||RPAD('-',(100-60),'-'));

EXCEPTION
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.print_message_header');
  fnd_message.set_token('PROGRAM','AR Lockbox CUstom Autocash Print Process Details');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg      := fnd_message.get;
  x_retstatus   := gn_error;
  put_log_line('==========================');
  put_log_line(x_retstatus);
END print_message_header;

-- +=================================================================================+
-- | Name        : PRINT_MESSAGE_FOOTER                                              |
-- | Description : This procedure will be used to print the                          |
-- |               record process details                                            |
-- |                                                                                 |
-- | Parameters  : p_customer_id                                                     |
-- |               p_check                                                           |
-- |               p_transaction                                                     |
-- |               p_tran_amount                                                     |
-- |               p_sub_amount                                                      |
-- |               p_sub_invoice                                                     |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE print_message_footer
(x_errmsg                 OUT NOCOPY  VARCHAR2
,x_retstatus              OUT NOCOPY  NUMBER
,p_customer_id             IN         NUMBER
,p_check                   IN         VARCHAR2
,p_transaction             IN         VARCHAR2
,p_tran_amount             IN         NUMBER
,p_sub_amount              IN         NUMBER
,p_sub_invoice             IN         VARCHAR2
)
IS
-- ------------------------------------------------
-- Custosr to get the customer number based
-- customer id from parameter
-- ------------------------------------------------
CURSOR lcu_get_customer_number
IS
SELECT HCA.account_number
FROM   hz_cust_accounts   HCA
WHERE  HCA.cust_account_id = p_customer_id;

lc_customer_number        hz_cust_accounts_all.account_number%TYPE;

BEGIN

  OPEN   lcu_get_customer_number;
  FETCH  lcu_get_customer_number INTO lc_customer_number;
  CLOSE  lcu_get_customer_number;

  IF p_sub_invoice IS NOT NULL THEN
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(NVL(lc_customer_number,''),16)||'    '||LPAD(NVL(p_check,''),16)||'  '||LPAD(NVL
(p_transaction,''),16)||'  '||LPAD(NVL(p_tran_amount,''),16)||'     '||LPAD(NVL(p_sub_invoice,''),16)||'  '||LPAD(NVL
(p_sub_amount,''),16));
  END IF;

EXCEPTION
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.print_message_footer');
  fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash Print Process Details');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg     := fnd_message.get;
  x_retstatus  := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
END print_message_footer;

-- +=================================================================================+
-- | Name        : PRINT_MESSAGE_SUMMARY                                             |
-- | Description : This procedure will be used to print the                          |
-- |               Total records of for all process criteria of Custom Auto Cash Rules|
-- |                                                                                 |
-- | Parameters  : p_tot_inv_bnk                                                     |
-- |               p_tot_inv_match                                                   |
-- |               p_tot_amt_match                                                   |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE print_message_summary
(x_errmsg               OUT NOCOPY VARCHAR2
,x_retstatus            OUT NOCOPY NUMBER
,p_tot_inv_bnk          IN         NUMBER
,p_tot_inv_match        IN         NUMBER
,p_tot_amt_match        IN         NUMBER )
IS
BEGIN

  IF p_tot_inv_bnk > 0 THEN
    -------------------------------------------------------------------------------------------------
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',50,'=')||'   End Process Details    '||RPAD('=',45,'='));
    -------------------------------------------------------------------------------------------------

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'=================================================================');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'AR Lockbox Custom Partial Invoice Match Summary :Invoice / Amount');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'=================================================================');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total invoices received from bank                     : '||p_tot_inv_bnk);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total invoices substituted with invoice lookup        : '||NVL(p_tot_inv_match,0));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total invoices substituted with amount lookup         : '||NVL(p_tot_amt_match,0));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total invoices substituted                            : '||TO_CHAR(NVL
(p_tot_inv_match,0) + NVL(p_tot_amt_match,0)));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total invoices not substituted                        : '||TO_CHAR(NVL
(p_tot_inv_bnk,0) - (NVL(p_tot_inv_match,0) + NVL(p_tot_amt_match,0))));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'=================================================================');

    put_log_line('Total invoices received from bank                   :'||p_tot_inv_bnk);
    put_log_line('Total invoices substituted with invoice lookup      :'||NVL(p_tot_inv_match,0));
    put_log_line('Total invoices substituted with amount lookup       :'||NVL(p_tot_amt_match,0));
    put_log_line('Total invoices substituted                          :'||TO_CHAR(NVL(p_tot_inv_match,0) + NVL
(p_tot_amt_match,0)));
    put_log_line('Total invoices not substituted                      :'||TO_CHAR(NVL(p_tot_inv_bnk,0) - (NVL
(p_tot_inv_match,0) + NVL(p_tot_amt_match,0))));
    put_log_line('AR Lockbox Custom Autocash Rule Extension: '||'E0062');


  ELSE
    -------------------------------------------------------------------------------------------------------------
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',50,'-')||'  No Record Found for Processing   '||RPAD('-',45,'-'));
    -------------------------------------------------------------------------------------------------------------
  END IF;

EXCEPTION
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.print_message_summary');
  fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash Print Process Details');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg     := fnd_message.get;
  x_retstatus  := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
END print_message_summary;

-- +=================================================================================+
-- | Name        : PRINT_AUTOCASH_REPORT                                             |
-- | Description : This procedure will be used to print the                          |
-- |               record process details                                            |
-- |                                                                                 |
-- | Parameters  : None                                                              |
-- |                                                                                 |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE print_autocash_report
(x_errmsg             OUT   NOCOPY  VARCHAR2
,x_retstatus          OUT   NOCOPY  NUMBER
,p_process_num         IN           VARCHAR2
,p_status              IN           VARCHAR2
,pn_match_status_count IN           NUMBER )
IS
  -- ------------------------------------------------
  -- Get All Record Type '6' from Auto Cash Match
  -- ------------------------------------------------
  CURSOR lcu_get_all_proc_6_records
  IS
  SELECT XAPI.customer_id
        ,XAPI.check_number
        ,XAPI.remittance_amount
        ,XAPI.batch_name
        ,XAPI.item_number
        ,HCA.account_number
  FROM   xx_ar_payments_interface  XAPI
        ,hz_cust_accounts          HCA
  WHERE  XAPI.process_num         = p_process_num
  AND    XAPI.record_type         = '6'
  --AND    XAPI.auto_cash_request   = gn_request_id
  AND    XAPI.customer_id         = HCA.cust_account_id
  AND    XAPI.inv_match_status    = p_status; --IN ('CLEAR_ACCOUNT','EXACT_MATCH','DATE_RANGE_MATCH','PULSE_PAY_MATCH','ANY_COMBINATION_MATCH');

  -- ------------------------------------------------
  -- Get All Record Type '4' from Auto Cash Match
  -- ------------------------------------------------
  CURSOR lcu_get_all_proc_4_records
  ( p_customer_id  IN NUMBER
   ,p_batch_name   IN VARCHAR2
   ,p_item_number  IN NUMBER )
  IS
  SELECT XAPI.invoice1
        ,XAPI.trx_date
        ,XAPI.amount_applied1
        ,XAPI.auto_cash_status
  FROM   xx_ar_payments_interface  XAPI
  WHERE  XAPI.process_num        = p_process_num
  AND    XAPI.record_type        ='4'
  --AND    XAPI.auto_cash_request  = gn_request_id
  AND    XAPI.customer_id        = p_customer_id
  AND    XAPI.batch_name         = p_batch_name
  AND    XAPI.item_number        = p_item_number;

  -- ------------------------------------------------
  -- Get total amount for all the checks
  -- ------------------------------------------------
  CURSOR lcu_get_tot_amount
  IS
  SELECT SUM(XAPI.remittance_amount / gn_cur_mult_dvd ) remittance_amount
  FROM   xx_ar_payments_interface  XAPI
  WHERE  XAPI.process_num         = p_process_num
  AND    XAPI.record_type         = '6'
  --AND    XAPI.auto_cash_request   = gn_request_id
  GROUP BY XAPI.process_num;

  -- ------------------------------------------------
  -- Get total count of check received from bank
  -- ------------------------------------------------
  CURSOR lcu_get_check_count
  IS
  SELECT COUNT(XAPI.check_number) check_count
  FROM   xx_ar_payments_interface  XAPI
  WHERE  XAPI.process_num         = p_process_num
  AND    XAPI.record_type         = '6';
  --AND    XAPI.auto_cash_request   = gn_request_id;

  -- ------------------------------------------------
  -- Local Variables Decalration
  -- ------------------------------------------------
  get_all_proc_6_records         lcu_get_all_proc_6_records%ROWTYPE;
  get_all_proc_4_records         lcu_get_all_proc_4_records%ROWTYPE;

  lc_customer_number             hz_cust_accounts_all.account_number%TYPE;

  ln_total_check_rcv             NUMBER;
  ln_total_check_match           NUMBER;
  ln_total_dollar_rcv            NUMBER;
  ln_inv_paid_this_type          NUMBER;
  ln_dollar_paid_this_type       NUMBER;
  ln_match_by_units              NUMBER;
  ln_match_by_dollars            NUMBER;
  ln_tot_amount                  NUMBER;
  ln_check_count                 NUMBER;
  lc_status                      VARCHAR2(100);


BEGIN

  IF p_status = 'CLEAR_ACCOUNT' THEN
    lc_status   := 'Clear Account';
  ELSIF p_status = 'EXACT_MATCH' THEN
    lc_status   := 'Exact Match';
  ELSIF p_status = 'DATE_RANGE_MATCH' THEN
    lc_status := 'Date Range';
  ELSIF p_status = 'PULSE_PAY_MATCH' THEN
    lc_status := 'Pulse Pay';
  ELSIF p_status = 'ANY_COMBINATION_MATCH' THEN
    lc_status := 'Any Combination';
  ELSIF p_status = 'CONSOLIDATED_MATCH' THEN
    lc_status := 'Consolidated Bill';
  ELSIF p_status = 'PURCHASE_ORDER_MATCH' THEN
    lc_status := 'Purchase Order';
  ELSIF p_status = 'AS_IS_CONSOLIDATED_MATCH' THEN  --Added for Defect #3983
    lc_status := 'AS IS Consolidated Match';        --Added for Defect #3983
  ELSE
    lc_status := NULL;
  END IF;
  -- ------------------------------------------------
  -- Set the Concurrent program Output header display
  -- ------------------------------------------------
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,2);
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',50,'=')||'   Office Depot    '||RPAD('=',50,'='));
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LPAD('Autocash Match',76,' '));
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Request ID : '||gn_request_id||RPAD(' ',60,' ')||'Request Date : '||TO_CHAR
(SYSDATE,'DD-MON-YYYY HH:MM:SS'));
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',125,'='));

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('Algorithm Type:'||lc_status,130,' '));

  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('Cust# From Bank ',23)||LPAD('Check# ',15)||LPAD('Check Amt ',15)||LPAD('Tran# 
',15)||RPAD('   Tran Date ',15)||LPAD('      Amt# ',23));
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',(20-1),'-')||'    '||RPAD('-',(12-1),'-')||'      '||RPAD('-',(25-1),'-')||
RPAD('-',(20-1),'-')||RPAD('-',(20-1),'-')||RPAD('-',(20-1),'-')||''||RPAD('-',(80-60),'-'));

  ln_total_check_rcv        := 0;
  ln_total_dollar_rcv       := 0;
  ln_inv_paid_this_type     := 0;
  ln_dollar_paid_this_type  := 0;
  ln_match_by_units         := 0;
  ln_match_by_dollars       := 0;
  ln_total_check_match      := 0;
  ln_tot_amount             := 0;
  ln_check_count            := 0;

  -- ------------------------------------------------
  -- Loop Through all the '6' records
  -- ------------------------------------------------
  OPEN lcu_get_all_proc_6_records;
  LOOP
  FETCH lcu_get_all_proc_6_records INTO get_all_proc_6_records;
  EXIT WHEN lcu_get_all_proc_6_records%NOTFOUND;

    ln_total_check_rcv    := ln_total_check_rcv + 1;
    ln_total_check_match  := ln_total_check_match + 1;
    ln_total_dollar_rcv   := ln_total_dollar_rcv + (get_all_proc_6_records.remittance_amount / gn_cur_mult_dvd);

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(NVL(get_all_proc_6_records.account_number,''),16)||'    '||LPAD(NVL
(get_all_proc_6_records.check_number,''),16)||'     '||LPAD(NVL((get_all_proc_6_records.remittance_amount /gn_cur_mult_dvd) 
,''),16));

    -- ------------------------------------------------
    -- Loop Through all the '4' records
    -- ------------------------------------------------
    OPEN lcu_get_all_proc_4_records ( p_customer_id => get_all_proc_6_records.customer_id
                                     ,p_batch_name  => get_all_proc_6_records.batch_name
                                     ,p_item_number => get_all_proc_6_records.item_number);
    LOOP
    FETCH lcu_get_all_proc_4_records  INTO get_all_proc_4_records;
    EXIT WHEN lcu_get_all_proc_4_records%NOTFOUND;

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                     '||LPAD(NVL
(get_all_proc_4_records.invoice1,''),16)||'     '||LPAD(NVL(get_all_proc_4_records.trx_date,''),16)||'     '||LPAD(NVL
((get_all_proc_4_records.amount_applied1 / gn_cur_mult_dvd),''),16));

      ln_inv_paid_this_type     := ln_inv_paid_this_type + 1;
      ln_dollar_paid_this_type  := ln_dollar_paid_this_type + (get_all_proc_4_records.amount_applied1 / gn_cur_mult_dvd);

    END LOOP;
    CLOSE lcu_get_all_proc_4_records;

  END LOOP;
  CLOSE lcu_get_all_proc_6_records;

----------------------------------------------------------------------------------------
  --Reverted the Changes made to the CR #684 --Defect #1858 on 11-DEC-09
  --Since new Procedure print_cust_validation_report has been developed to achieve this.
  --Start of changes for CR #684 --Defect #1858
----------------------------------------------------------------------------------------
/*
FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('Cust# From Bank ',23)
                                  ||LPAD('Check# ',16)
                                  ||LPAD('Check Amt ',23)
                                  ||LPAD('MICR# ',30)
                                  ||LPAD('Cust# for MICR ',20)
                  );
FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',(16-1),'-')
                                   ||LPAD(' ',17,' ')
                                   ||RPAD('-',(8-1),'-')
                                   ||LPAD(' ',13,' ')
                                   ||RPAD('-',(21-1),'-')
                                   ||RPAD('-',(20-1),'-')
                                   ||RPAD('-',(80-60),'-')
                  );
FOR cntr IN 1..ln_count-1 LOOP
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(NVL(gt_cust_number(cntr),''),15)
                                     ||LPAD(' ',7,' ')
                                     ||LPAD(NVL(gt_check_number(cntr),''),16)
                                     ||LPAD(' ',7,' ')
                                     ||LPAD(NVL(gt_check_amt(cntr) ,''),16)
                                     ||LPAD(' ',2,' ')
                                     ||LPAD(NVL(gt_micr_num(cntr) ,''),28)
                                     ||LPAD(NVL(gt_micr_cust_num(cntr) ,''),20)
                      );
END LOOP;
-----------------------------------------------------
  --End of changes for CR #684 --Defect #1858
-----------------------------------------------------
*/ --   --Reverted the Changes made to the CR #684 --Defect #1858 on 11-DEC-09
  -- ------------------------------------------------
  -- Total Check Amount Received from Bank
  -- ------------------------------------------------
  OPEN  lcu_get_tot_amount;
  FETCH lcu_get_tot_amount INTO ln_tot_amount;
  CLOSE lcu_get_tot_amount;
  -- ------------------------------------------------
  -- Total Check Received from bank
  -- ------------------------------------------------
  OPEN  lcu_get_check_count;
  FETCH lcu_get_check_count INTO ln_check_count;
  CLOSE lcu_get_check_count;
  -- ------------------------------------------------
  -- Calculate the percentage
  -- ------------------------------------------------
  IF ln_total_check_match = 0 OR  ln_total_check_rcv = 0 THEN
    ln_match_by_units := 0;
  ELSE
    ln_match_by_units := ROUND(((ln_total_check_match / ln_check_count) * 100),2);
    --ln_match_by_units :=   ROUND(((ln_total_check_match / ln_total_check_rcv) * 100),2);
  END IF;

  IF ln_total_dollar_rcv = 0 OR ln_dollar_paid_this_type = 0 THEN
     ln_match_by_dollars := 0;
  ELSE
     ln_match_by_dollars := ROUND(((ln_dollar_paid_this_type / ln_tot_amount) * 100),2);
     --ln_match_by_dollars  := ROUND(((ln_total_dollar_rcv / ln_dollar_paid_this_type) * 100),2);
  END IF;

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'========================================================================');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'AR Lockbox Custom Autocash Rule Extension Match Summary: '||lc_status);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'========================================================================');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total checks received                                 : '||ln_check_count);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total dollars received                                : '||ln_tot_amount);
--  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Customer Numbers Removed                        : '||gn_tot_cust_removed); ----
--Reverted the Changes made to the CR #684 --Defect #1858 on 11-DEC-09
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Checks matched for this type                          : '||ln_total_check_match);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invoices paid for this type                           : '||ln_inv_paid_this_type);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Dollars paid for this type                            : '||ln_dollar_paid_this_type);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'% Match by units                                      : '||ln_match_by_units);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'% Match by dollars                                    : '||ln_match_by_dollars);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'========================================================================');

  --
  -- Sai - 05/11/2008 to calculate totals for all matches, per Damon
  --
  gt_match_details(pn_match_status_count).match_status          := lc_status;
  gt_match_details(pn_match_status_count).check_count           := NVL(ln_check_count,0);
  gt_match_details(pn_match_status_count).tot_amount            := NVL(ln_tot_amount,0);
  gt_match_details(pn_match_status_count).total_check_match     := NVL(ln_total_check_match,0);
  gt_match_details(pn_match_status_count).inv_paid_this_type    := NVL(ln_inv_paid_this_type,0);
  gt_match_details(pn_match_status_count).dollar_paid_this_type := NVL(ln_dollar_paid_this_type,0);
  gt_match_details(pn_match_status_count).match_by_units        := NVL(ln_match_by_units,0);
  gt_match_details(pn_match_status_count).match_by_dollars      := NVL(ln_match_by_dollars,0);
  put_log_line('pn_match_status_count='||pn_match_status_count);
  put_log_line('gt_match_details(pn_match_status_count).match_status='||gt_match_details
(pn_match_status_count).match_status);
  put_log_line('gt_match_details(pn_match_status_count).check_count='||gt_match_details(pn_match_status_count).check_count);
  put_log_line('gt_match_details(pn_match_status_count).total_check_match='||gt_match_details
(pn_match_status_count).total_check_match);
  --
  -- Sai - 05/11/2008 to calculate totals for all matches, per Damon
  --

EXCEPTION
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.print_autocash_report');
  fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash Print Process Details');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg      := fnd_message.get;
  x_retstatus   := gn_error;
  put_log_line('==========================');
  put_log_line(x_retstatus);
END print_autocash_report;
-----------------------------------------------------------
--Start of Changes for CR #684 -- Defect #1858 on 11-DEC-09
-----------------------------------------------------------
-- +========================================================================================+
-- | Name        : PRINT_CUST_VALIDATION_REPORT                                             |
-- | Description : This procedure will be used to print the                                 |
-- |               blanked out Customer details whenever the BAI Customer and MICR Customer |
-- |               are related.Added as a part of CR#684 (Defect #1858)                     |
-- |                                                                                        |
-- | Parameters  : None                                                                     |
-- |                                                                                        |
-- |                                                                                        |
-- | Returns     : x_errmsg                                                                 |
-- |               x_retstatus                                                              |
-- |                                                                                        |
-- +========================================================================================+
PROCEDURE print_cust_validation_report
(x_errmsg             OUT   NOCOPY  VARCHAR2
,x_retstatus          OUT   NOCOPY  NUMBER
)
IS
BEGIN
  -- ------------------------------------------------
  -- Set the Concurrent program Output header display
  -- ------------------------------------------------
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,2);
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LPAD('BAI Customer Number Validation Report',76,' '));
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('Cust# From Bank ',23)
                                    ||LPAD('Check# ',16)
                                    ||LPAD('Check Amt ',23)
                                    ||LPAD('MICR# ',30)
                                    ||LPAD('Cust# for MICR ',20)
                    );
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',(16-1),'-')
                                     ||LPAD(' ',17,' ')
                                     ||RPAD('-',(8-1),'-')
                                     ||LPAD(' ',13,' ')
                                     ||RPAD('-',(21-1),'-')
                                     ||RPAD('-',(20-1),'-')
                                     ||RPAD('-',(80-60),'-')
                    );
  FOR cntr IN 1..ln_count-1 LOOP
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(NVL(gt_cust_number(cntr),''),15)
                                     ||LPAD(' ',7,' ')
                                     ||LPAD(NVL(gt_check_number(cntr),''),16)
                                     ||LPAD(' ',7,' ')
                                     ||LPAD(NVL(gt_check_amt(cntr) ,''),16)
                                     ||LPAD(' ',2,' ')
                                     ||LPAD(NVL(gt_micr_num(cntr) ,''),28)
                                     ||LPAD(NVL(gt_micr_cust_num(cntr) ,''),20)
                      );
  END LOOP;

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'========================================================================');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'AR Lockbox Custom Autocash BAI Customer Validation Summary ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'========================================================================');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Customer Numbers Removed                        : '||gn_tot_cust_removed);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'========================================================================');
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

EXCEPTION
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.print_cust_validation_report');
  fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash Print Process Details');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg      := fnd_message.get;
  x_retstatus   := gn_error;
  put_log_line('==========================');
  put_log_line(x_retstatus);
END print_cust_validation_report;
---------------------------------------------------------
--End of Changes for CR #684 -- Defect #1858 on 11-DEC-09
---------------------------------------------------------
-----------------------------------
--Start of Changes for Defect #3983
-----------------------------------
-- +========================================================================================+
-- | Name        : BO_INVOICE_STATUS_REPORT                                           |
-- | Description : This procedure will be used to print the                                 |
-- |               Back Order Invoice Substitution Match                                    |
-- |               Added as a part of #3983                                                 |
-- |                                                                                        |
-- | Parameters  : None                                                                     |
-- |                                                                                        |
-- |                                                                                        |
-- | Returns     : x_errmsg                                                                 |
-- |               x_retstatus                                                              |
-- |                                                                                        |
-- +========================================================================================+
PROCEDURE bo_invoice_status_report
(x_errmsg             OUT   NOCOPY  VARCHAR2
,x_retstatus          OUT   NOCOPY  NUMBER
)
IS
BEGIN
  -- ------------------------------------------------
  -- Set the Concurrent program Output header display
  -- ------------------------------------------------
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,2);
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LPAD('BO Invoice Status Report',76,' '));
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('Cust# From Bank ',23)
                                     ||RPAD('Check# ',22)
                                     ||RPAD('Tran# ',23)
                                     ||RPAD('Amt# ',10)
                                     ||RPAD('Substituted Inv # ',28)
                                     ||RPAD('Amt# ',23)
                   );
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',(20-1),'-')
                                     ||'    '
                                     ||RPAD('-',(12-1),'-')
                                     ||'           '
                                     ||RPAD('-',(25-1),'-')
                                     ||RPAD('-',(20-1),'-')
                                     ||RPAD('-',(25-1),'-')
                    );
  FOR cntr IN 1..gn_bo_count-1 LOOP
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(NVL(gt_bo_invoice(cntr).customer_number,''),16)
                                      ||'    '
                                      ||LPAD(NVL(gt_bo_invoice(cntr).check_number,''),16)
                                      ||'  '
                                      ||LPAD(NVL(gt_bo_invoice(cntr).invoice_number,''),16)
                                      ||'  '
                                      ||LPAD(NVL(gt_bo_invoice(cntr).invoice_amount,''),16)
                                      ||'     '
                                      ||LPAD(NVL(gt_bo_invoice(cntr).sub_invoice_number,''),16)
                                      ||'  '
                                      ||LPAD(NVL(gt_bo_invoice(cntr).sub_invoice_amount,''),16)
                      );
  END LOOP;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'========================================================================');
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
EXCEPTION
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.bo_invoice_status_report');
  fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash Print Process Details');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg      := fnd_message.get;
  x_retstatus   := gn_error;
  put_log_line('==========================');
  put_log_line(x_retstatus);
END bo_invoice_status_report;
---------------------------------------------------------
--End of Changes for CR #684 -- Defect #1858 on 11-DEC-09
---------------------------------------------------------

PROCEDURE print_autocash_report_totals
(x_errmsg              OUT   NOCOPY  VARCHAR2
,x_retstatus           OUT   NOCOPY  NUMBER
,pn_match_status_count IN    NUMBER
)
IS
--  -- ------------------------------------------------
--  -- Get total amount for all the checks
--  -- ------------------------------------------------
--  CURSOR lcu_get_tot_amount
--  IS
--  SELECT SUM(XAPI.remittance_amount / gn_cur_mult_dvd ) remittance_amount
--  FROM   xx_ar_payments_interface  XAPI
--  WHERE  XAPI.process_num         = p_process_num
--  AND    XAPI.record_type         = '6'
--  --AND    XAPI.auto_cash_request   = gn_request_id
--  GROUP BY XAPI.process_num;

--  -- ------------------------------------------------
--  -- Get total count of check received from bank
--  -- ------------------------------------------------
--  CURSOR lcu_get_check_count
--  IS
--  SELECT COUNT(XAPI.check_number) check_count
--  FROM   xx_ar_payments_interface  XAPI
--  WHERE  XAPI.process_num         = p_process_num
--  AND    XAPI.record_type         = '6';
--  --AND    XAPI.auto_cash_request   = gn_request_id;


  ln_total_check_rcv             NUMBER;
  ln_total_check_match           NUMBER;
  ln_total_dollar_rcv            NUMBER;
  ln_inv_paid_this_type          NUMBER;
  ln_dollar_paid_this_type       NUMBER;
  ln_match_by_units              NUMBER;
  ln_match_by_dollars            NUMBER;
  ln_tot_amount                  NUMBER;
  ln_check_count                 NUMBER;
  lc_status                      VARCHAR2(100);


BEGIN

  -- ------------------------------------------------
  -- Set the Concurrent program Output header display
  -- ------------------------------------------------
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,2);
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',50,'=')||'   Office Depot    '||RPAD('=',50,'='));
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LPAD('Autocash Match',76,' '));
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Request ID : '||gn_request_id||RPAD(' ',60,' ')||'Request Date : '||TO_CHAR
(SYSDATE,'DD-MON-YYYY HH:MM:SS'));
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',125,'='));

--  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
--  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('Cust# From Bank ',23)||LPAD('Check# ',15)||LPAD('Check Amt ',15)||LPAD('Tran# ',15)||RPAD('   Tran Date ',15)||LPAD('      Amt# ',23));
--  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',(20-1),'-')||'    '||RPAD('-',(12-1),'-')||'      '||RPAD('-',(25-1),'-')||RPAD('-',(20-1),'-')||RPAD('-',(20-1),'-')||RPAD('-',(20-1),'-')||''||RPAD('-',(80-60),'-'));

  ln_total_check_rcv        := 0;
  ln_total_dollar_rcv       := 0;
  ln_inv_paid_this_type     := 0;
  ln_dollar_paid_this_type  := 0;
  ln_match_by_units         := 0;
  ln_match_by_dollars       := 0;
  ln_total_check_match      := 0;
  ln_tot_amount             := 0;
  ln_check_count            := 0;


--  -- ------------------------------------------------
--  -- Total Check Amount Received from Bank
--  -- ------------------------------------------------
--  OPEN  lcu_get_tot_amount;
--  FETCH lcu_get_tot_amount INTO ln_tot_amount;
--  CLOSE lcu_get_tot_amount;
--  -- ------------------------------------------------
--  -- Total Check Received from bank
--  -- ------------------------------------------------
--  OPEN  lcu_get_check_count;
--  FETCH lcu_get_check_count INTO ln_check_count;
--  CLOSE lcu_get_check_count;
--  -- ------------------------------------------------
--  -- Calculate the percentage
--  -- ------------------------------------------------
--  IF ln_total_check_match = 0 OR  ln_total_check_rcv = 0 THEN
--    ln_match_by_units := 0;
--  ELSE
--    ln_match_by_units := ROUND(((ln_total_check_match / ln_check_count) * 100),2);
--    --ln_match_by_units :=   ROUND(((ln_total_check_match / ln_total_check_rcv) * 100),2);
--  END IF;

--  IF ln_total_dollar_rcv = 0 OR ln_dollar_paid_this_type = 0 THEN
--     ln_match_by_dollars := 0;
--  ELSE
--     ln_match_by_dollars := ROUND(((ln_dollar_paid_this_type / ln_tot_amount) * 100),2);
--     --ln_match_by_dollars  := ROUND(((ln_total_dollar_rcv / ln_dollar_paid_this_type) * 100),2);
--  END IF;

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('=',(115),'='));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'AR Lockbox Custom Autocash Rule Extension: Summary of Match Types');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('=',(115),'='));
    FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
       RPAD('Match Type ',25) || ' ' ||
       LPAD('Checks Matched',15) || ' ' ||
       LPAD('% Match By Units',20) || ' ' ||
       LPAD('Dollars Paid',20) || ' ' ||
       LPAD('% Match By Dollars',20) || ' ' ||
       LPAD('Invoices',10)  );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',(115),'-'));

    put_log_line('pn_match_status_count='||pn_match_status_count);
    FOR i IN 1..pn_match_status_count LOOP
      put_log_line('In FOR LOOP for i ='||i);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
       RPAD(gt_match_details(i).match_status, 25) ||
       LPAD(gt_match_details(i).total_check_match, 15) ||
       LPAD(ROUND(gt_match_details(i).total_check_match/gt_match_details(i).check_count*100, 2) || '%', 20) ||
       LPAD(gt_match_details(i).dollar_paid_this_type, 20) ||
       LPAD(ROUND(gt_match_details(i).dollar_paid_this_type/gt_match_details(i).tot_amount*100, 2) || '%', 20) ||
       LPAD(gt_match_details(i).inv_paid_this_type, 10)  );
      ln_check_count           := gt_match_details(i).check_count;
      ln_tot_amount            := gt_match_details(i).tot_amount;
      ln_total_check_match     := gt_match_details(i).total_check_match + ln_total_check_match;
      ln_inv_paid_this_type    := gt_match_details(i).inv_paid_this_type + ln_inv_paid_this_type;
      ln_dollar_paid_this_type := gt_match_details(i).dollar_paid_this_type + ln_dollar_paid_this_type;
      ln_match_by_units        := gt_match_details(i).match_by_units + ln_match_by_units;
      ln_match_by_dollars      := gt_match_details(i).match_by_dollars + ln_match_by_dollars;
    END LOOP;
    FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',(115),'-'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
       RPAD('TOTALS ', 25) ||
       LPAD(ln_total_check_match, 15) ||
       LPAD(ROUND(ln_total_check_match/ln_check_count*100, 2) || '%', 20) ||
       LPAD(ln_dollar_paid_this_type, 20) ||
       LPAD(ROUND(ln_dollar_paid_this_type/ln_tot_amount*100, 2) || '%', 20) ||
       LPAD(ln_inv_paid_this_type, 10)  );
    FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total checks received                                 : '||ln_check_count);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total dollars received                                : '||ln_tot_amount);
-- Defect 7547
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Dollars Hit Rate                                : '||ROUND(ln_total_check_match/ln_check_count, 2) || '%');
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Custom Match Hit Rate                           : '||ROUND(ln_dollar_paid_this_type/ln_tot_amount,2) || '%');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Dollars Hit Rate                                : '||ROUND(ln_dollar_paid_this_type/ln_tot_amount*100,2) || '%');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Custom Match Hit Rate                           : '||ROUND(ln_total_check_match/ln_check_count*100, 2) || '%');
-- Defect 7547
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('=',(115),'='));


EXCEPTION
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.print_autocash_report_totals');
  fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash Print Process Details');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg      := fnd_message.get;
  x_retstatus   := gn_error;
  put_log_line('print_autocash_report_totals>>==========================');
  put_log_line(x_retstatus);
END print_autocash_report_totals;


-- +=================================================================================+
-- | Name        : CREATE_INTERFACE_RECORD                                           |
-- | Description : This procedure will be created the records into                   |
-- |               xx_ar_payments_interface table for record type 4                  |
-- |                                                                                 |
-- | Parameters  : p_record                                                          |
-- |                                                                                 |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE create_interface_record
(x_errmsg             OUT   NOCOPY  VARCHAR2
,x_retstatus          OUT   NOCOPY  NUMBER
,p_record              IN           xx_ar_payments_interface%ROWTYPE
)
IS

ln_cur_mult      NUMBER;

BEGIN

  -- -------------------------------------------
  -- Assign the value to currency multiplication
  -- -------------------------------------------
  IF gn_cur_precision    = 1 THEN
    ln_cur_mult := 10;
  ELSIF  gn_cur_precision = 2 THEN
    ln_cur_mult := 100;
  ELSIF gn_cur_precision  = 3 THEN
    ln_cur_mult := 1000;
  ELSIF gn_cur_precision  = 4 THEN
    ln_cur_mult := 10000;
  ELSIF gn_cur_precision  = 5 THEN
    ln_cur_mult := 100000;
  ELSE
    ln_cur_mult := 100;
  END IF;
  -- -------------------------------------------
  -- Insert Into XX_AR_PAYMENTS_INTERFACE table
  -- For record_type '4'
  -- -------------------------------------------
--  put_log_line('gc_file_name ' || gc_file_name );
  INSERT INTO xx_ar_payments_interface
   ( status
    ,record_type
    ,batch_name
    ,item_number
    ,overflow_sequence
    ,overflow_indicator
    ,invoice1
    ,amount_applied1
    ,trx_date
    ,process_num
    ,file_name
    ,inv_match_status
    ,customer_id
    ,auto_cash_status
    ,auto_cash_request
    ,creation_date
    ,last_update_date
    ,created_by
   )
   VALUES
   ( p_record.status
    ,p_record.record_type
    ,p_record.batch_name
    ,p_record.item_number
    ,p_record.overflow_sequence
    ,p_record.overflow_indicator
    ,p_record.invoice1
    ,p_record.amount_applied1 * ln_cur_mult
    ,p_record.trx_date
    ,p_record.process_num
--    ,NULL --,p_record.file_name  -- Calrification    -- Commented for the Defect # 4284
    ,gc_file_name      -- Added for the Defect # 4284
    ,p_record.inv_match_status
    ,p_record.customer_id
    ,p_record.auto_cash_status
    ,gn_request_id
    ,sysdate
    ,sysdate
    ,gn_user_id
   );


   --COMMIT; -- Commit for each record
   --put_log_line('Record Inserted into interface table');

EXCEPTION
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.create_interface_record');
  fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash Print Process Details');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg     := fnd_message.get;
  x_retstatus  := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
END create_interface_record;

-- +=================================================================================+
-- | Name        : UPDATE_LCKB_REC                                                   |
-- | Description : This procedure will be used for update the status in custom       |
-- |               auto lock box interface table xx_ar_payments_interface            |
-- |                                                                                 |
-- | Parameters  : p_process_num                                                     |
-- |               p_record_type                                                     |
-- |               p_invoice                                                         |
-- |               p_inv_match_status                                                |
-- |               p_invoice1_2_3                                                    |
-- |               p_invoice1_2_3_status                                             |
-- |               p_match_type                                                      |
-- |               p_rowid                                                           |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE update_lckb_rec
( x_errmsg                    OUT   NOCOPY  VARCHAR2
, x_retstatus                 OUT   NOCOPY  NUMBER
, p_process_num               IN            VARCHAR2
, p_record_type               IN            VARCHAR2
, p_invoice                   IN            VARCHAR2   DEFAULT NULL
, p_inv_match_status          IN            VARCHAR2   DEFAULT NULL
, p_invoice1_2_3              IN            VARCHAR2   DEFAULT NULL
, p_invoice1_2_3_status       IN            VARCHAR2   DEFAULT NULL
, p_match_type                IN            VARCHAR2   DEFAULT NULL
, p_rowid                     IN            VARCHAR2
)
IS

BEGIN

  -- ------------------------------------------------
  -- Update the record status in custom interface table
  -- xx_ar_payments_interface table with inv match status
  -- ------------------------------------------------

  --IF p_record_type = '4' THEN

    UPDATE xx_ar_payments_interface XAPI
    SET    XAPI.invoice1_status   = DECODE(p_record_type,'4',DECODE(p_invoice1_2_3,'INVOICE1',p_invoice1_2_3_status, 
XAPI.invoice1_status),XAPI.invoice1_status)
          ,XAPI.invoice2_status   = DECODE(p_record_type,'4',DECODE(p_invoice1_2_3,'INVOICE2',p_invoice1_2_3_status, 
XAPI.invoice2_status),XAPI.invoice2_status)
          ,XAPI.invoice3_status   = DECODE(p_record_type,'4',DECODE(p_invoice1_2_3,'INVOICE3',p_invoice1_2_3_status, 
XAPI.invoice3_status),XAPI.invoice3_status)
          ,XAPI.invoice1          = DECODE(p_invoice1_2_3_status,'INVOICE_EXISTS',XAPI.invoice1,DECODE
(p_record_type,'4',DECODE(p_invoice1_2_3,'INVOICE1',p_invoice,XAPI.invoice1),XAPI.invoice1))
          ,XAPI.invoice2          = DECODE(p_invoice1_2_3_status,'INVOICE_EXISTS',XAPI.invoice2,DECODE
(p_record_type,'4',DECODE(p_invoice1_2_3,'INVOICE2',p_invoice,XAPI.invoice2),XAPI.invoice2))
          ,XAPI.invoice3          = DECODE(p_invoice1_2_3_status,'INVOICE_EXISTS',XAPI.invoice3,DECODE
(p_record_type,'4',DECODE(p_invoice1_2_3,'INVOICE3',p_invoice,XAPI.invoice3),XAPI.invoice3))
          --,XAPI.inv_match_status  = DECODE(p_record_type,'6',XAPI.inv_match_status ||p_inv_match_status,XAPI.inv_match_status)
          ,XAPI.inv_match_status  = DECODE(p_record_type,'6',p_inv_match_status,XAPI.inv_match_status)
    WHERE  XAPI.rowid             = p_rowid
    AND    XAPI.record_type       = p_record_type
    AND    XAPI.process_num       = p_process_num;

 -- ELSIF  p_record_type = '6' THEN
  /*
    UPDATE xx_ar_payments_interface XAPI
    SET    XAPI.inv_match_status   = XAPI.inv_match_status ||p_inv_match_status
    WHERE  XAPI.rowid              = p_rowid
    AND    XAPI.record_type        = p_record_type
    AND    XAPI.process_num        = p_process_num;

  END IF;
  */

  --COMMIT;

EXCEPTION
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.update_lckb_rec');
  fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash Update Record');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg           := fnd_message.get;
  x_retstatus        := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
END update_lckb_rec;

-- +=================================================================================+
-- | Name        : DELETE_LCKB_REC                                                   |
-- | Description : This procedure will be used for delete the record type 4 records  |
-- |               from custom interface table if any custom auto cash rule or       |
-- |               Consolidated Bill Rule will match                                 |
-- | Parameters  : p_process_num                                                     |
-- |               p_record_type                                                     |
-- |               p_rowid                                                           |
-- |               p_customer_id                                                     |
-- |               p_record                                                          |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE delete_lckb_rec
( x_errmsg                    OUT   NOCOPY  VARCHAR2
, x_retstatus                 OUT   NOCOPY  NUMBER
, p_process_num               IN            VARCHAR2
, p_record_type               IN            VARCHAR2
, p_rowid                     IN            VARCHAR2
, p_customer_id               IN            NUMBER
, p_record                    IN            xx_ar_payments_interface%ROWTYPE
)
IS

BEGIN

  -- -------------------------------------------
  -- Call the delete procedure to delete all 4
  -- records for the same batch and item of record 6
  -- -------------------------------------------
  DELETE FROM xx_ar_payments_interface  XAPI
  WHERE XAPI.record_type          = '4'
  AND   XAPI.process_num          = p_process_num
  --AND  (XAPI.auto_cash_request IS NULL
  --  OR XAPI.auto_cash_request    <> gn_request_id)
  AND  XAPI.batch_name            = p_record.batch_name
  AND  XAPI.item_number           = p_record.item_number
  AND  p_customer_id              = (SELECT XAPI1.customer_id
                                     FROM   xx_ar_payments_interface XAPI1
                                     WHERE  XAPI1.rowid       = p_rowid
                                     AND    XAPI1.record_type = '6');


EXCEPTION
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.delete_lckb_rec');
  fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash Delete Record');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg           := fnd_message.get;
  x_retstatus        := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
END delete_lckb_rec;

-- +=================================================================================+
-- | Name        : XX_MATCHED_INVOICES                                               |
-- | Description : This procedure will be used to insert the matched invoices into   |
-- |               a global temp table to avoid duplicate receipts                   |
-- |               Added for the defect# 2033                                        |
-- |                                                                                 |
-- | Parameters  : p_trx_number                                                      |
-- |              ,p_insert_flag                                                     |
-- | Returns     : p_trx_exist                                                       |
-- +=================================================================================+

  PROCEDURE xx_matched_invoices( p_trx_number       IN   VARCHAR2
                                ,p_ins_flag         IN   VARCHAR2
                                ,p_trx_not_exist    OUT  VARCHAR2
                               )
  AS
  PRAGMA AUTONOMOUS_TRANSACTION;
  ln_dummy    NUMBER;
  BEGIN
      IF (p_ins_flag = 'INSERT') THEN
          INSERT INTO xx_ar_matched_invoices VALUES ( p_trx_number);
          COMMIT;
          p_trx_not_exist :='N';
          gn_global_cnt := gn_global_cnt + 1;
      ELSIF(p_ins_flag = 'DELETE') THEN
          DELETE FROM xx_ar_matched_invoices;
          COMMIT;
          p_trx_not_exist :='N';
          gn_global_cnt   := 0;
      ELSIF (p_ins_flag = 'MATCH') THEN
          BEGIN
             SELECT 1
               INTO ln_dummy
               FROM xx_ar_matched_invoices
              WHERE trx_number = p_trx_number;
             p_trx_not_exist := 'N';
             put_log_line('Transn '|| p_trx_number || 'already Matched in 12 digit/9 digit/BO Match');
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
            p_trx_not_exist :='Y';
          END;
      END IF;
  EXCEPTION
  WHEN OTHERS THEN
    p_trx_not_exist := 'Y';
    put_log_line('Error @ global xx_matched_invoices procedure');
  END xx_matched_invoices;
-- +=================================================================================+
-- | Name        : PULSE_PAY_RULE                                                    |
-- | Description : This procedure will be used Find out the sum of invoices for      |
-- |               a unique due day for last 3 months to match check amount with BAI file|
-- |                                                                                 |
-- | Parameters  : p_customer_id                                                     |
-- |               p_match_type                                                      |
-- |               p_term_id                                                         |
-- |               p_deposit_date                                                    |
-- |               p_cur_precision                                                   |
-- |               p_process_num                                                     |
-- |               p_rowid                                                           |
-- |               p_record                                                          |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |               x_pulse_pay_match                                                 |
-- +=================================================================================+
PROCEDURE pulse_pay_rule
(x_errmsg             OUT   NOCOPY  VARCHAR2
,x_retstatus          OUT   NOCOPY  NUMBER
,x_pulse_pay_match    OUT   NOCOPY  VARCHAR2
,p_customer_id         IN           NUMBER
,p_match_type          IN           VARCHAR2  DEFAULT NULL
,p_record              IN           xx_ar_payments_interface%ROWTYPE
,p_term_id             IN           NUMBER    DEFAULT NULL
,p_deposit_date        IN           DATE      DEFAULT NULL
,p_cur_precision       IN           NUMBER    DEFAULT NULL
,p_process_num         IN           VARCHAR2
,p_rowid               IN           VARCHAR2
)
IS

  -- -------------------------------------------
  -- Cursor Get Sum of the Amount Due
  -- for a specific customer and a unique day
  -- of the last three months
  -- -------------------------------------------
  CURSOR lcu_get_sum_amt
  ( p_customer     IN hz_cust_accounts_all.cust_account_id%TYPE
    ,p_from_date    IN DATE
    ,p_to_date      IN DATE
    --,p_unique_date  IN DATE
   )
  IS
  -- Added for Defect #3984
    SELECT SUM(amount_due_remaining) amount_due_remaining
          ,trx_date                  trx_date
    FROM
        (SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */  APS.acctd_amount_due_remaining        amount_due_remaining
               ,aps.trx_date  trx_date
         FROM   XX_AR_LOCKBOX_INTERIM  APS
               ,ra_customer_trx ract
        WHERE  APS.class = 'CM'
        AND    APS.status                          = 'OP'
        AND    APS.acctd_amount_due_remaining      <> 0
        AND    APS.customer_id = p_customer              --Added for the Defect #4005
        AND    APS.trx_date BETWEEN p_from_date  AND  p_to_date
        AND    RACT.customer_trx_id  = APS.customer_trx_id        --Added for the Defect #4005
--        AND    RACT.bill_to_customer_id = APS.customer_id
        AND    RACT.printing_original_date IS NOT NULL            -- Added for Defect # 3913
        UNION ALL
        SELECT   /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */
                CASE WHEN (p_deposit_date <= APS.due_date) THEN
                                 ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(APS.term_id
                                                                                                                              
            ,APS.trx_date
                                                                                                                              
            ,p_deposit_date
                                                                                                                              
            )
                                                      )
                               ,gn_cur_precision
                                )
                      ELSE APS.acctd_amount_due_remaining
                      END amount_due_remaining
              ,aps.trx_date  trx_date
        FROM   XX_AR_LOCKBOX_INTERIM  APS
              ,ra_customer_trx ract
        WHERE  APS.class = 'INV'
        AND    APS.status                          = 'OP'
        AND    APS.acctd_amount_due_remaining      <> 0
        AND    APS.customer_id = p_customer              --Added for the Defect #4005
        AND    APS.trx_date BETWEEN p_from_date  AND  p_to_date
        AND    RACT.customer_trx_id  = APS.customer_trx_id        --Added for the Defect #4005
--        AND    RACT.bill_to_customer_id = APS.customer_id
        AND    RACT.printing_original_date IS NOT NULL            --Added for Defect # 3913
        )
        GROUP BY trx_date
        ORDER BY trx_date DESC;
/*  --Commented for the Defect #3984
  SELECT SUM(ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(p_term_id,(p_deposit_date - APS.trx_date))),gn_cur_precision)) 
amount_due_remaining
        ,aps.trx_date
--        ,APS.due_date
  FROM   ar_payment_schedules  APS
        ,ra_customer_trx ract
  WHERE  APS.class                           IN ('INV','CM')
  AND    APS.status                          = 'OP'
  AND    APS.acctd_amount_due_remaining      <> 0
  --AND    APS.customer_id                     = p_customer --Commented for the Defect #4005
  AND    ract.bill_to_customer_id = p_customer              --Added for the Defect #4005
  AND    aps.trx_date BETWEEN p_from_date  AND  p_to_date
--  AND    APS.due_date  BETWEEN p_from_date  AND  p_to_date
--  AND    ract.trx_number = aps.trx_number           --Commented for the Defect #4005
  AND    ract.customer_trx_id  = aps.customer_trx_id  --Added for the Defect #4005
  AND    ract.bill_to_customer_id = aps.customer_id
--  AND    ract.printing_pending = 'N'   -- Commented for Defect # 3913
  AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
  GROUP BY aps.trx_date
--  GROUP BY APS.due_date
  ORDER BY aps.trx_date DESC;
--  ORDER BY APS.due_date DESC;
*/
  -- -------------------------------------------
  -- Get the all transactions of a specific customer
  -- and specific Unique Due Day
  -- -------------------------------------------
  CURSOR lcu_get_all_trx
  ( p_customer     IN hz_cust_accounts_all.cust_account_id%TYPE
    ,p_unique_date  IN DATE
   )
  IS
-- Added for the Defect #3984
  SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */ APS.trx_number  trx_number
         ,APS.acctd_amount_due_remaining       acctd_amount_due_remaining --Added for Defect #3984
        ,APS.trx_date    trx_date
        ,APS.due_date    due_date
  FROM   XX_AR_LOCKBOX_INTERIM  APS
        ,ra_customer_trx ract
  WHERE  APS.class                           = 'CM'
  AND    APS.status                          = 'OP'
  AND    APS.acctd_amount_due_remaining      <> 0
  AND    APS.customer_id = p_customer                --Added for the Defect #4005
  AND    ract.customer_trx_id     = aps.customer_trx_id       --Added for the Defect #4005
--  AND    ract.bill_to_customer_id = aps.customer_id
  AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
  AND    TO_CHAR(APS.trx_date,'DD-MON-YYYY') = p_unique_date
  UNION ALL
  SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */ APS.trx_number   trx_number
         ,CASE WHEN (p_deposit_date <= APS.due_date) THEN
                                 ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(APS.term_id
                                                                                                                              
            ,APS.trx_date
                                                                                                                              
            ,p_deposit_date
                                                                                                                              
            )
                                                      )
                               ,gn_cur_precision
                                )
                      ELSE APS.acctd_amount_due_remaining
                      END amount_due_remaining
        ,APS.trx_date     trx_date
        ,APS.due_date     due_date
  FROM   XX_AR_LOCKBOX_INTERIM  APS
        ,ra_customer_trx ract
  WHERE  APS.class                           = 'INV'
  AND    APS.status                          = 'OP'
  AND    APS.acctd_amount_due_remaining      <> 0
  AND    APS.customer_id = p_customer                --Added for the Defect #4005
  AND    ract.customer_trx_id     = aps.customer_trx_id       --Added for the Defect #4005
--  AND    ract.bill_to_customer_id = aps.customer_id
  AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
  AND    TO_CHAR(APS.trx_date,'DD-MON-YYYY') = p_unique_date
  ORDER BY trx_date DESC;
/*
  SELECT APS.trx_number
         ,ROUND((APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(APS.term_id
                                                                                                                              
        ,APS.trx_date
                                                                                                                              
        ,p_deposit_date
                                                                                                                              
        )
                                                  )
                 )
                ,gn_cur_precision
                ) acctd_amount_due_remaining --Added for Defect #3984
        --,ROUND((APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(p_term_id,(p_deposit_date - APS.trx_date)))),gn_cur_precision) 
acctd_amount_due_remaining --Commented for the Defect #3984
        ,APS.trx_date
        ,APS.due_date
  FROM   ar_payment_schedules  APS
        ,ra_customer_trx ract
  WHERE  APS.class                           IN ('INV','CM')
  AND    APS.status                          = 'OP'
  AND    APS.acctd_amount_due_remaining      <> 0
--  AND    APS.customer_id                     = p_customer   --Commented for the Defect #4005
--  AND    ract.trx_number = aps.trx_number                   --Commented for the Defect #4005
  AND    ract.bill_to_customer_id = p_customer                --Added for the Defect #4005
  AND    ract.customer_trx_id     = aps.customer_trx_id       --Added for the Defect #4005
  AND    ract.bill_to_customer_id = aps.customer_id
--  AND    ract.printing_pending = 'N'  -- Commented for Defect # 3913
  AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
  --AND    APS.due_date  BETWEEN p_from_date  AND  p_to_date
  AND    TO_CHAR(APS.trx_date,'DD-MON-YYYY') = p_unique_date
--  ORDER BY APS.due_date DESC;
  ORDER BY aps.trx_date DESC;
*/ --Commented for the Defect #3984
  /*
  SELECT APS.trx_number
        ,APS.acctd_amount_due_remaining
        ,APS.trx_date
  FROM   ar_payment_schedules     APS
  WHERE  APS.class                      IN ('INV','CM')
  AND    APS.status                     = 'OP'
  AND    APS.acctd_amount_due_remaining <> 0
  AND    APS.customer_id                = p_customer
  AND    TO_CHAR(APS.due_date,'DD-MON-YYYY')     = p_unique_date;
  */

  -- -------------------------------------------
  -- Local Variables Decalration
  -- -------------------------------------------
  --get_unique_due_date            lcu_get_unique_due_date%ROWTYPE;
  get_all_trx                    lcu_get_all_trx%ROWTYPE;
  lr_record                      xx_ar_payments_interface%ROWTYPE;

  ln_amount_due_remaining        ar_payment_schedules_all.amount_due_remaining%TYPE;

  lc_pulse_pay_match             VARCHAR2(1);
  lc_errmsg                      VARCHAR2(4000);
  lc_error_details               VARCHAR2(32000);
  lc_error_location              VARCHAR2(4000);

  ln_retcode                     NUMBER;
  ln_loop_counter                NUMBER;
  ln_overflow_sequence           NUMBER;
  ln_check_fifty_counter         NUMBER;

  ld_due_date                    DATE;

  PULSE_PAY_EXCEPTION            EXCEPTION;

BEGIN

  -- Initializing Check Fifity Unique Days Counter
  ln_check_fifty_counter    :=  0;
  -- -------------------------------------------
  -- Loop Through all the Unique Due Days for
  -- last 3 months for a specific customer
  -- -------------------------------------------
  /*
  OPEN  lcu_get_unique_due_date( p_customer    =>  p_customer_id
                                ,p_from_date   =>  (TRUNC(SYSDATE) - 90)
                                ,p_to_date     =>  TRUNC(SYSDATE)
                               );
  LOOP
  FETCH lcu_get_unique_due_date INTO get_unique_due_date;
  EXIT WHEN lcu_get_unique_due_date%NOTFOUND;
  */
    -- -------------------------------------------
    -- Initializing Local Variables
    -- -------------------------------------------
    ln_amount_due_remaining      :=  NULL;
    lc_pulse_pay_match           :=  NULL;
    ln_loop_counter              :=  0;
    ln_overflow_sequence         :=  0;
    ld_due_date                  :=  NULL;

    -- -------------------------------------------
    --
    --
    -- -------------------------------------------
    OPEN lcu_get_sum_amt
    ( p_customer    =>  p_customer_id
     ,p_from_date   =>  (TRUNC(SYSDATE) - 90)
     ,p_to_date     =>  TRUNC(SYSDATE)
     --,p_unique_date =>  get_unique_due_date.unique_due_date
    );
    LOOP
    FETCH lcu_get_sum_amt  INTO ln_amount_due_remaining
                               ,ld_due_date;
    EXIT WHEN lcu_get_sum_amt%NOTFOUND;

      ln_check_fifty_counter  :=  ln_check_fifty_counter + 1;

      IF ln_amount_due_remaining  = p_record.remittance_amount THEN
        -- -------------------------------------------
        -- Set the Pulse Pay Match Flag to 'Y'
        -- -------------------------------------------
        lc_pulse_pay_match   := 'Y';

        -- -------------------------------------------
        -- Call the delete procedure to delete all 4
        -- records for the same batch and item of record 6
        -- -------------------------------------------
        lc_error_location  :=  'Calling the delete procedure for second bucket from date range rule';
        delete_lckb_rec
        ( x_errmsg         =>  lc_errmsg
         ,x_retstatus      =>  ln_retcode
         ,p_process_num    =>  p_process_num
         ,p_record_type    =>  '6'
         ,p_rowid          =>  p_rowid
         ,p_customer_id    =>  p_customer_id
         ,p_record         =>  p_record
        );

        IF ln_retcode  = gn_error THEN
          lc_error_details := lc_error_location||':'|| lc_errmsg;
          RAISE PULSE_PAY_EXCEPTION;
        END IF;
        -- -------------------------------------------
        -- Get all the transactions from oracle for
        -- specific Unique Due Day Records
        -- -------------------------------------------
        OPEN lcu_get_all_trx ( p_customer    =>  p_customer_id
                              ,p_unique_date =>  ld_due_date  --get_unique_due_date.unique_due_date
                             );
        LOOP
        FETCH lcu_get_all_trx INTO get_all_trx;
        EXIT WHEN lcu_get_all_trx%NOTFOUND;

          -- Incrementing Counter in the loop
          ln_loop_counter      := ln_loop_counter + 1;
          ln_overflow_sequence := ln_overflow_sequence + 1;
          -- -------------------------------------------
          -- Create records into Custom Interface table
          -- xx_ar_payments_interfcae for record type 4
          -- -------------------------------------------
          -- Assigning the value into record columns
          --
          lr_record.status                := 'AR_PLB_NEW_RECORD';
          lr_record.record_type           := '4';
          lr_record.batch_name            := p_record.batch_name;
          lr_record.item_number           := p_record.item_number;
          lr_record.invoice1              := get_all_trx.trx_number;
          lr_record.amount_applied1       := get_all_trx.acctd_amount_due_remaining;
          lr_record.trx_date              := get_all_trx.trx_date;
          lr_record.process_num           := p_record.process_num;
          lr_record.customer_id           := p_customer_id;
          lr_record.auto_cash_status      := 'PULSEPAY_MATCHED';
          lr_record.overflow_sequence     := ln_overflow_sequence;
          /*
          IF ln_loop_counter = 1 THEN
            lr_record.overflow_indicator  := '9';
          ELSIF ln_loop_counter <> 1 THEN
            lr_record.overflow_indicator  := '0';
          END IF;
          */
          lr_record.overflow_indicator  := '0';
          -- -------------------------------------------
          -- Calling the Create Interface record procedure
          -- -------------------------------------------
          create_interface_record
          ( x_errmsg      =>  lc_errmsg
           ,x_retstatus   =>  ln_retcode
           ,p_record      =>  lr_record
          );

          IF ln_retcode  = gn_error THEN
            lc_error_details := lc_error_location||':'|| lc_errmsg;
            RAISE PULSE_PAY_EXCEPTION;
          END IF;
          -- -------------------------------------------
          -- Call the Print Message Footer Procedure to
          -- print the detail transaction
          -- -------------------------------------------
          /*
          print_message_footer
          ( x_errmsg                 =>  lc_errmsg
           ,x_retstatus              =>  ln_retcode
           ,p_customer_id            =>  ln_customer_id
           ,p_check                  =>  get_lockbox_rec.check_number
           ,p_transaction            =>  get_lockbox_det_rec.invoice3
           ,p_tran_amount            =>  ln_amount_applied3
           ,p_sub_amount             =>  get_trx_number.acctd_amount_due_remaining
           ,p_sub_invoice            =>  get_trx_number.trx_number
          );
          */

        END LOOP;
        CLOSE lcu_get_all_trx;

        UPDATE xx_ar_payments_interface XAPI
        SET    XAPI.overflow_indicator = '9'
        WHERE  XAPI.record_type        = '4'
        AND    XAPI.process_num        = p_process_num
        --AND    XAPI.auto_cash_request  = gn_request_id
        AND    XAPI.overflow_sequence  = ln_loop_counter
        AND    XAPI.batch_name         = p_record.batch_name
        AND    XAPI.item_number        = p_record.item_number
        AND    p_customer_id           =
           (SELECT XAPI1.customer_id
            FROM   xx_ar_payments_interface XAPI1
            WHERE  XAPI1.rowid        = p_rowid
            AND    XAPI1.record_type  = '6'
            AND    XAPI1.batch_name   = p_record.batch_name
            AND    XAPI1.item_number  = p_record.item_number);

        EXIT;

      ELSE
        -- -------------------------------------------
        -- If the Counter is greater than or equal to 50 then it will exit from the
        -- main loop. the counter is for total number of unique days for a customer
        -- and for current date to last three months
        -- -------------------------------------------
        IF ln_check_fifty_counter >= 50 THEN
          EXIT;
        END IF;
      END IF;

    END LOOP;
    CLOSE lcu_get_sum_amt;
  /*
  END LOOP;
  CLOSE lcu_get_unique_due_date;
  */
  /*
  IF lc_pulse_pay_match = 'Y' THEN
    UPDATE xx_ar_payments_interface XAPI
    SET    XAPI.overflow_indicator = '9'
    WHERE  XAPI.record_type        = 4
    AND    XAPI.process_num        = p_process_num
    AND    XAPI.overflow_sequence  = SELECT MAX(overflow_sequence)
                                     FROM   xx_ar_payments_interface XAPI1
                                     WHERE  XAPI1.rowid    = p_rowid
                                     AND
  END IF;
  */

  x_pulse_pay_match  := lc_pulse_pay_match;

EXCEPTION
WHEN PULSE_PAY_EXCEPTION THEN
  x_errmsg     := lc_error_details;
  x_retstatus  := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.pulse_pay_rule');
  fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash Print Process Details');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg           := fnd_message.get;
  x_retstatus        := gn_error;
  x_pulse_pay_match := NULL;
  put_log_line('==========================');
  put_log_line(x_errmsg);
END pulse_pay_rule;

-- +=================================================================================+
-- | Name        : DATE_RANGE_RULE                                                   |
-- | Description : This procedure will be used Find out the sum of invoices for      |
-- |               a particular range of dates to match with BAI file                |
-- |                                                                                 |
-- | Parameters  : p_customer_id                                                     |
-- |               p_match_type                                                      |
-- |               p_record                                                          |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE date_range_rule
(x_errmsg             OUT   NOCOPY  VARCHAR2
,x_retstatus          OUT   NOCOPY  NUMBER
,x_date_range_match   OUT   NOCOPY  VARCHAR2
,p_customer_id         IN           NUMBER
,p_match_type          IN           VARCHAR2  DEFAULT NULL
,p_record              IN           xx_ar_payments_interface%ROWTYPE
,p_term_id             IN           NUMBER    DEFAULT NULL
,p_deposit_date        IN           DATE      DEFAULT NULL
,p_cur_precision       IN           NUMBER    DEFAULT NULL
,p_process_num         IN           VARCHAR2
,p_rowid               IN           VARCHAR2
)
IS

  -- -------------------------------------------
  -- Cursor Get all the date range buckets
  -- for a specific customer and if any
  -- transactions are due
  -- -------------------------------------------
--  CURSOR lcu_get_bucket_ranges (p_customer IN hz_cust_accounts_all.cust_account_id%TYPE)
--  IS
--  SELECT DISTINCT TO_CHAR(APS.due_date,'MON-YYYY')                             due_mth_yr
--         ,TO_CHAR(APS.due_date,'MMYYYY')                                       ordered_mth_yr
--         ,'01-'||TO_CHAR(APS.due_date,'MON-YYYY')                              first_date
--         ,'15-'||TO_CHAR(APS.due_date,'MON-YYYY')                              first_bucket
--         ,'16-'||TO_CHAR(APS.due_date,'MON-YYYY')                              second_bucket
--         ,TO_CHAR(last_day(to_char(APS.due_date,'DD-MON-YYYY')),'DD-MON-YYYY') last_date
--  FROM   ar_payment_schedules  APS
--  WHERE  APS.class                      IN ('INV','CM')
--  AND    APS.status                     = 'OP'
--  AND    APS.acctd_amount_due_remaining <> 0
--  AND    APS.customer_id                = p_customer
--  ORDER BY TO_CHAR(APS.due_date,'MMYYYY');
  CURSOR lcu_get_bucket_ranges (p_customer IN hz_cust_accounts_all.cust_account_id%TYPE)
  IS
  SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */ DISTINCT TO_CHAR(APS.trx_date,'MON-YYYY')                             
due_mth_yr
         ,TO_CHAR(APS.trx_date,'MMYYYY')                                       ordered_mth_yr
         ,'01-'||TO_CHAR(APS.trx_date,'MON-YYYY')                              first_date
         ,'15-'||TO_CHAR(APS.trx_date,'MON-YYYY')                              first_bucket
         ,'16-'||TO_CHAR(APS.trx_date,'MON-YYYY')                              second_bucket
--         ,TO_CHAR(last_day(to_char(APS.due_date,'DD-MON-YYYY')),'DD-MON-YYYY') last_date   -- Commented for Defect # 4287
         ,TO_CHAR(last_day(to_char(APS.trx_date,'DD-MON-YYYY')),'DD-MON-YYYY') last_date     -- Added for Defect # 4287
  FROM   XX_AR_LOCKBOX_INTERIM  APS
        ,ra_customer_trx ract
  WHERE  APS.class                      IN ('INV','CM')
  AND    APS.status                     = 'OP'
  AND    APS.acctd_amount_due_remaining <> 0
  AND    APS.customer_id                = p_customer  --Commented for the Defect #4005
--  AND    APS.trx_number = RACT.trx_number             --Commented for the Defect #4005
--  AND    RACT.bill_to_customer_id = p_customer          --Added for the Defect #4005
  AND    APS.customer_trx_id = RACT.customer_trx_id  --Added for the Defect #4005
--  AND    APS.customer_id = RACT.bill_to_customer_id
--  AND    ract.printing_pending = 'N'   --Commenetd for Defect # 3913
  AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
  ORDER BY TO_CHAR(aps.trx_date,'MMYYYY');

  -- -------------------------------------------
  -- Get the sum amount of a specific customer
  -- and specific date range
  -- -------------------------------------------
  CURSOR lcu_get_sum_amount
  ( p_customer  IN  hz_cust_accounts_all.cust_account_id%TYPE
   ,p_from_date IN  DATE
   ,p_to_date   IN  DATE)
  IS
      SELECT SUM(amount_due_remaining) amount_due_remaining
      FROM
        (SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */ APS.acctd_amount_due_remaining        amount_due_remaining
               ,aps.customer_id  customer_id
         FROM   XX_AR_LOCKBOX_INTERIM  APS
               ,ra_customer_trx ract
        WHERE  APS.class = 'CM'
        AND    APS.status                          = 'OP'
        AND    APS.acctd_amount_due_remaining <> 0
        AND    APS.customer_id = p_customer       --Added for the Defect #4005
        AND    APS.customer_trx_id = RACT.customer_trx_id  --Added for the Defect #4005
--        AND    APS.customer_id = RACT.bill_to_customer_id
        AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
        AND    APS.trx_date BETWEEN p_from_date AND p_to_date
        UNION ALL
        SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */
              ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(APS.term_id
                                                                                                                              
            ,APS.trx_date
                                                                                                                              
            ,p_deposit_date
                                                                                                                              
            )
                                                      )
                   ,gn_cur_precision
                    )            amount_due_remaining
               ,aps.customer_id  customer_id
        FROM   XX_AR_LOCKBOX_INTERIM  APS
              ,ra_customer_trx ract
        WHERE  APS.class = 'INV'
        AND    APS.status                          = 'OP'
        AND    APS.acctd_amount_due_remaining <> 0
        AND    APS.customer_id = p_customer       --Added for the Defect #4005
        AND    APS.customer_trx_id = RACT.customer_trx_id  --Added for the Defect #4005
--        AND    APS.customer_id = RACT.bill_to_customer_id
        AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
        AND    APS.trx_date BETWEEN p_from_date AND p_to_date
        )
        GROUP BY customer_id;
/*
  SELECT SUM(ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(p_term_id,(p_deposit_date - APS.trx_date))),gn_cur_precision)) 
amount_due_remaining
  FROM   ar_payment_schedules  APS
        ,ra_customer_trx ract
  WHERE  APS.class                      IN ('INV','CM')
  AND    APS.status                     = 'OP'
  AND    APS.acctd_amount_due_remaining <> 0
 -- AND    APS.customer_id = p_customer              --Commented for the Defect #4005
 -- AND    APS.trx_number = RACT.trx_number          --Commented for the Defect #4005
  AND    RACT.bill_to_customer_id = p_customer       --Added for the Defect #4005
  AND    APS.customer_trx_id = RACT.customer_trx_id  --Added for the Defect #4005
  AND    APS.customer_id = RACT.bill_to_customer_id
--  AND    ract.printing_pending = 'N'   --Commented for Defect # 3913
  AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
--  AND    APS.due_date BETWEEN p_from_date AND p_to_date
  AND    APS.trx_date BETWEEN p_from_date AND p_to_date
  GROUP BY APS.customer_id;
*/ --Commented for the Defect #3984
  -- -------------------------------------------
  -- Get the all transactions of a specific customer
  -- and specific range of dates
  -- -------------------------------------------
  CURSOR lcu_get_all_trx
  ( p_customer  IN  hz_cust_accounts_all.cust_account_id%TYPE
    ,p_from_date IN  DATE
    ,p_to_date   IN  DATE
   )
  IS
-- Added for the Defect #3984
  SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */
          APS.trx_number  trx_number
         ,APS.acctd_amount_due_remaining        amount_due_remaining --Added for Defect #3984
        ,APS.trx_date    trx_date
  FROM   XX_AR_LOCKBOX_INTERIM  APS
        ,ra_customer_trx ract
  WHERE  APS.class                      = 'CM'
  AND    APS.status                     = 'OP'
  AND    APS.acctd_amount_due_remaining <> 0
  AND    APS.customer_id = p_customer          --Added for the Defect #4005
  AND    APS.customer_trx_id = RACT.customer_trx_id     --Added for the Defect #4005
--  AND    APS.customer_id = RACT.bill_to_customer_id
  AND    ract.printing_original_date IS NOT NULL        -- Added for Defect # 3913
  AND    APS.trx_date BETWEEN p_from_date AND p_to_date
  UNION ALL
  SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */
         APS.trx_number   trx_number
         ,CASE WHEN (p_deposit_date <= APS.due_date) THEN
                                 ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(APS.term_id
                                                                                                                              
            ,APS.trx_date
                                                                                                                              
            ,p_deposit_date
                                                                                                                              
            )
                                                      )
                               ,gn_cur_precision
                                )
                      ELSE APS.acctd_amount_due_remaining
                      END amount_due_remaining
        ,APS.trx_date     trx_date
  FROM   XX_AR_LOCKBOX_INTERIM  APS
        ,ra_customer_trx ract
  WHERE  APS.class                      = 'INV'
  AND    APS.status                     = 'OP'
  AND    APS.acctd_amount_due_remaining <> 0
  AND    APS.customer_id = p_customer          --Added for the Defect #4005
  AND    APS.customer_trx_id = RACT.customer_trx_id     --Added for the Defect #4005
--  AND    APS.customer_id = RACT.bill_to_customer_id
  AND    ract.printing_original_date IS NOT NULL        -- Added for Defect # 3913
  AND    APS.trx_date BETWEEN p_from_date AND p_to_date;
/*
  SELECT APS.trx_number
        ,ROUND((APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(APS.term_id
                                                                                                                              
       ,APS.trx_date
                                                                                                                              
       ,p_deposit_date
                                                                                                                              
        )
                                                  )
                )
              ,gn_cur_precision
              ) amount_due_remaining  --Added for the Defect #3984
--      ,ROUND((APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(p_term_id,(p_deposit_date - APS.trx_date)))),gn_cur_precision) 
amount_due_remaining  -- Commented for the Defect #3984
        ,APS.trx_date
  FROM   ar_payment_schedules     APS
        ,ra_customer_trx ract
  WHERE  APS.class                      IN ('INV','CM')
  AND    APS.status                     = 'OP'
  AND    APS.acctd_amount_due_remaining <> 0
--  AND    APS.customer_id                = p_customer  --Commented for the Defect #4005
--  AND    APS.trx_number = RACT.trx_number             --Commented for the Defect #4005
  AND    RACT.bill_to_customer_id = p_customer          --Added for the Defect #4005
  AND    APS.customer_trx_id = RACT.customer_trx_id     --Added for the Defect #4005
  AND    APS.customer_id = RACT.bill_to_customer_id
--  AND    ract.printing_pending = 'N'  --Commented for Defect # 3913
  AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
  AND    APS.trx_date BETWEEN p_from_date AND p_to_date;
--  AND    APS.due_date BETWEEN p_from_date AND p_to_date;
*/ --Commented for the Defect #3984
  -- -------------------------------------------
  -- Declare Local Variables
  -- -------------------------------------------
  get_bucket_ranges            lcu_get_bucket_ranges%ROWTYPE;
  get_all_trx                  lcu_get_all_trx%ROWTYPE;
  lr_record                    xx_ar_payments_interface%ROWTYPE;

  ln_amount_due_remaining      ar_payment_schedules_all.amount_due_remaining%TYPE;

  lc_first_bucket_flag         VARCHAR2(1);
  lc_second_bucket_flag        VARCHAR2(1);
  lc_third_bucket_flag         VARCHAR2(1);
  lc_date_range_match          VARCHAR2(1);
  lc_errmsg                    VARCHAR2(4000);
  lc_error_details             VARCHAR2(32000);
  lc_error_location            VARCHAR2(4000);

  ln_retcode                   NUMBER;
  ln_loop_counter              NUMBER;
  ln_overflow_sequence         NUMBER;
  ln_tot_amount                NUMBER;

  DATE_RANGE_EXCEPTION         EXCEPTION;

BEGIN

  -- -------------------------------------------
  -- Get all the Date Range Buckets after
  -- Open the cursor
  -- -------------------------------------------
  --fnd_file.put_line(fnd_file.output,'Date Range Proc Proc Num:-'||p_record.process_num);

  OPEN  lcu_get_bucket_ranges (p_customer => p_customer_id);
  LOOP
  FETCH lcu_get_bucket_ranges  INTO get_bucket_ranges;
  EXIT WHEN lcu_get_bucket_ranges%NOTFOUND;

    -- -------------------------------------------
    -- Initializing Local Variables
    -- -------------------------------------------
    ln_amount_due_remaining      := NULL;
    lc_first_bucket_flag         := NULL;
    lc_second_bucket_flag        := NULL;
    lc_third_bucket_flag         := NULL;
    lc_date_range_match          := NULL;
    ln_loop_counter              := 0;
    ln_overflow_sequence         := 0;
    -- -------------------------------------------
    -- Get Sum of all the transactions from oracle for
    -- for bucket1 - Date Range 1st day of the month
    -- upto 15th of the month
    -- -------------------------------------------
    OPEN lcu_get_sum_amount ( p_customer    => p_customer_id
                             ,p_from_date   => get_bucket_ranges.first_date
                             ,p_to_date     => get_bucket_ranges.first_bucket
                            );
    FETCH lcu_get_sum_amount INTO ln_amount_due_remaining;
    CLOSE lcu_get_sum_amount;

    IF ln_amount_due_remaining  = p_record.remittance_amount THEN
      -- -------------------------------------------
      -- Set the First Bucket Flag to 'Y'
      -- -------------------------------------------
      lc_first_bucket_flag := 'Y';
      lc_date_range_match  := 'Y';
      -- -------------------------------------------
      -- Call the delete procedure to delete all 4
      -- records for the same batch and item of record 6
      -- -------------------------------------------
      lc_error_location  :=  'Calling the delete procedure for first bucket from date range rule';
      delete_lckb_rec
      ( x_errmsg         =>  lc_errmsg
       ,x_retstatus      =>  ln_retcode
       ,p_process_num    =>  p_process_num
       ,p_record_type    =>  '6'
       ,p_rowid          =>  p_rowid
       ,p_customer_id    =>  p_customer_id
       ,p_record         =>  p_record
      );
      IF ln_retcode  = gn_error THEN
        lc_error_details := lc_error_location||':'|| lc_errmsg;
        RAISE DATE_RANGE_EXCEPTION;
      END IF;
      -- -------------------------------------------
      -- Get all the transactions from oracle for
      -- specific range dates and assign to bucket
      -- -------------------------------------------
      OPEN lcu_get_all_trx
      ( p_customer    => p_customer_id
        ,p_from_date   => get_bucket_ranges.first_date
        ,p_to_date     => get_bucket_ranges.first_bucket
       );
      LOOP
      FETCH lcu_get_all_trx INTO get_all_trx;
      EXIT WHEN lcu_get_all_trx%NOTFOUND;

        -- Incrementing Counter in the loop
        ln_loop_counter      := ln_loop_counter + 1;
        ln_overflow_sequence := ln_overflow_sequence + 1;
        -- -------------------------------------------
        -- Call the Create Record Procedure to create record type '4'
        -- into xx_ar_payments_interface table for matching bucket
        -- -------------------------------------------
        -- Assigning the value into record columns
        --
        lr_record.status                := 'AR_PLB_NEW_RECORD';
        lr_record.record_type           := '4';
        lr_record.batch_name            := p_record.batch_name;
        lr_record.item_number           := p_record.item_number;
        lr_record.invoice1              := get_all_trx.trx_number;
        lr_record.amount_applied1       := get_all_trx.amount_due_remaining;
        lr_record.trx_date              := get_all_trx.trx_date;
        lr_record.process_num           := p_record.process_num;
        --lr_record.inv_match_status      := 'INVOICE_DATERANGE_MATCHED';
        lr_record.customer_id           := p_customer_id;
        lr_record.auto_cash_status      := 'DATERANGE_MATCHED';
        lr_record.overflow_sequence     := ln_overflow_sequence;
        /*
        IF ln_loop_counter = 1 THEN
          lr_record.overflow_indicator  := '9';
        ELSIF ln_loop_counter <> 1 THEN
          lr_record.overflow_indicator  := '0';
        END IF;
        */
        lr_record.overflow_indicator  := '0';
        -- -------------------------------------------
        -- Calling the Create Interface record procedure
        -- -------------------------------------------
        create_interface_record
        ( x_errmsg      =>  lc_errmsg
         ,x_retstatus   =>  ln_retcode
         ,p_record      =>  lr_record
        );

        IF ln_retcode  = gn_error THEN
          lc_error_details := lc_error_location||':'|| lc_errmsg;
          RAISE DATE_RANGE_EXCEPTION;
        END IF;
        -- -------------------------------------------
        -- Call the Print Message Footer Procedure to
        -- print the detail transaction
        -- -------------------------------------------
        /*
        print_message_footer
        ( x_errmsg                 =>  lc_errmsg
         ,x_retstatus              =>  ln_retcode
         ,p_customer_id            =>  ln_customer_id
         ,p_check                  =>  get_lockbox_rec.check_number
         ,p_transaction            =>  get_lockbox_det_rec.invoice3
         ,p_tran_amount            =>  ln_amount_applied3
         ,p_sub_amount             =>  get_trx_number.acctd_amount_due_remaining
         ,p_sub_invoice            =>  get_trx_number.trx_number
        );
        */

      END LOOP;
      CLOSE lcu_get_all_trx;

        UPDATE xx_ar_payments_interface XAPI
        SET    XAPI.overflow_indicator = '9'
        WHERE  XAPI.record_type        = '4'
        AND    XAPI.process_num        = p_process_num
        --AND    XAPI.auto_cash_request  = gn_request_id
        AND    XAPI.overflow_sequence  = ln_loop_counter
        AND    XAPI.batch_name         = p_record.batch_name
        AND    XAPI.item_number        = p_record.item_number
        AND    p_customer_id           =
           (SELECT XAPI1.customer_id
            FROM   xx_ar_payments_interface XAPI1
            WHERE  XAPI1.rowid        = p_rowid
            AND    XAPI1.record_type  = '6'
            AND    XAPI1.batch_name   = p_record.batch_name
            AND    XAPI1.item_number  = p_record.item_number);

      EXIT; -- Exit from the main loop

    END IF;
    -- -------------------------------------------
    -- Get Sum of all the transactions from oracle for
    -- for bucket2 - Date Range 16th day of the month
    -- upto last day of the month
    -- -------------------------------------------
    OPEN lcu_get_sum_amount
    ( p_customer    => p_customer_id
     ,p_from_date   => get_bucket_ranges.second_bucket
     ,p_to_date     => get_bucket_ranges.last_date
    );
    FETCH lcu_get_sum_amount INTO ln_amount_due_remaining;
    CLOSE lcu_get_sum_amount;

    IF ln_amount_due_remaining  = p_record.remittance_amount THEN
      -- -------------------------------------------
      -- Set the Second Bucket Flag to 'Y'
      -- -------------------------------------------
      lc_second_bucket_flag := 'Y';
      lc_date_range_match   := 'Y';
      -- -------------------------------------------
      -- Call the delete procedure to delete all 4
      -- records for the same batch and item of record 6
      -- -------------------------------------------
      lc_error_location  :=  'Calling the delete procedure for second bucket from date range rule';
      delete_lckb_rec
      ( x_errmsg         =>  lc_errmsg
       ,x_retstatus      =>  ln_retcode
       ,p_process_num    =>  p_process_num
       ,p_record_type    =>  '6'
       ,p_rowid          =>  p_rowid
       ,p_customer_id    =>  p_customer_id
       ,p_record         =>  p_record
      );

      IF ln_retcode  = gn_error THEN
        lc_error_details := lc_error_location||':'|| lc_errmsg;
        RAISE DATE_RANGE_EXCEPTION;
      END IF;
      -- -------------------------------------------
      -- Get all the transactions from oracle for
      -- specific range dates and assign to bucket
      -- -------------------------------------------
      OPEN lcu_get_all_trx
      ( p_customer    => p_customer_id
        ,p_from_date   => get_bucket_ranges.second_bucket
        ,p_to_date     => get_bucket_ranges.last_date
       );
      LOOP
      FETCH lcu_get_all_trx INTO get_all_trx;
      EXIT WHEN lcu_get_all_trx%NOTFOUND;

        -- Incrementing Counter in the loop
        ln_loop_counter      := ln_loop_counter + 1;
        ln_overflow_sequence := ln_overflow_sequence + 1;
        -- -------------------------------------------
        -- Call the Create Record Procedure to create record type '4'
        -- into xx_ar_payments_interface table for matching bucket
        -- -------------------------------------------
        -- Assigning the value into record columns
        --
        lr_record.status                := 'AR_PLB_NEW_RECORD';
        lr_record.record_type           := '4';
        lr_record.batch_name            := p_record.batch_name;
        lr_record.item_number           := p_record.item_number;
        lr_record.invoice1              := get_all_trx.trx_number;
        lr_record.amount_applied1       := get_all_trx.amount_due_remaining;
        lr_record.trx_date              := get_all_trx.trx_date;
        lr_record.process_num           := p_record.process_num;
        --lr_record.inv_match_status      := 'INVOICE_DATERANGE_MATCHED';
        lr_record.customer_id           := p_customer_id;
        lr_record.auto_cash_status      := 'DATERANGE_MATCHED';
        lr_record.overflow_sequence     := ln_overflow_sequence;
        /*
        IF ln_loop_counter = 1 THEN
          lr_record.overflow_indicator  := '9';
        ELSIF ln_loop_counter <> 1 THEN
          lr_record.overflow_indicator  := '0';
        END IF;
        */
        lr_record.overflow_indicator  := '0';
        -- -------------------------------------------
        -- Calling the Create Interface record procedure
        -- -------------------------------------------
        create_interface_record ( x_errmsg      =>  lc_errmsg
                             ,x_retstatus   =>  ln_retcode
                                 ,p_record      =>  lr_record
                                );

        IF ln_retcode  = gn_error THEN
          lc_error_details := lc_error_location||':'|| lc_errmsg;
          RAISE DATE_RANGE_EXCEPTION;
        END IF;
        -- -------------------------------------------
        -- Call the Print Message Footer Procedure to
        -- print the detail transaction
        -- -------------------------------------------
        /*
        print_message_footer
        ( x_errmsg                 =>  lc_errmsg
         ,x_retstatus              =>  ln_retcode
         ,p_customer_id            =>  ln_customer_id
         ,p_check                  =>  get_lockbox_rec.check_number
         ,p_transaction            =>  get_lockbox_det_rec.invoice3
         ,p_tran_amount            =>  ln_amount_applied3
         ,p_sub_amount             =>  get_trx_number.acctd_amount_due_remaining
         ,p_sub_invoice            =>  get_trx_number.trx_number
        );
        */

      END LOOP;
      CLOSE lcu_get_all_trx;

        UPDATE xx_ar_payments_interface XAPI
        SET    XAPI.overflow_indicator = '9'
        WHERE  XAPI.record_type        = '4'
        AND    XAPI.process_num        = p_process_num
        --AND    XAPI.auto_cash_request  = gn_request_id
        AND    XAPI.overflow_sequence  = ln_loop_counter
        AND    XAPI.batch_name         = p_record.batch_name
        AND    XAPI.item_number        = p_record.item_number
        AND    p_customer_id           =
             (SELECT XAPI1.customer_id
              FROM   xx_ar_payments_interface XAPI1
              WHERE  XAPI1.rowid        = p_rowid
              AND    XAPI1.record_type  = '6'
              AND    XAPI1.batch_name   = p_record.batch_name
              AND    XAPI1.item_number  = p_record.item_number);

      EXIT; -- Exit from the main loop

    END IF;
    -- -------------------------------------------
    -- Get Sum of all the transactions from oracle for
    -- for bucket3 - Date Range 1st day of the month
    -- upto last day of the month
    -- -------------------------------------------
    OPEN lcu_get_sum_amount ( p_customer    => p_customer_id
                             ,p_from_date   => get_bucket_ranges.first_date
                             ,p_to_date     => get_bucket_ranges.last_date
                            );
    FETCH lcu_get_sum_amount INTO ln_amount_due_remaining;
    CLOSE lcu_get_sum_amount;

    IF ln_amount_due_remaining  = p_record.remittance_amount THEN

      put_log_line('lr_record3' ||'-'||p_record.remittance_amount);
      put_log_line('ln_amount_due_remaining' ||'-'||ln_amount_due_remaining);
      put_log_line('get_bucket_ranges.first_date' ||'-'||get_bucket_ranges.first_date);
      put_log_line('get_bucket_ranges.last_date' ||'-'||get_bucket_ranges.last_date);
      -- -------------------------------------------
      -- Set the Third Bucket Flag to 'Y'
      -- -------------------------------------------
      lc_third_bucket_flag  := 'Y';
      lc_date_range_match   := 'Y';
      fnd_file.put_line(fnd_file.output,'Date Range Proc third bucket flag:-'||lc_third_bucket_flag);
      -- -------------------------------------------
      -- Call the delete procedure to delete all 4
      -- records for the same batch and item of record 6
      -- -------------------------------------------
      lc_error_location  :=  'Calling the delete procedure for third bucket from date range rule';
      delete_lckb_rec
      ( x_errmsg         =>  lc_errmsg
       ,x_retstatus      =>  ln_retcode
       ,p_process_num    =>  p_process_num
       ,p_record_type    =>  '6'
       ,p_rowid          =>  p_rowid
       ,p_customer_id    =>  p_customer_id
       ,p_record         =>  p_record
      );
      IF ln_retcode  = gn_error THEN
        lc_error_details := lc_error_location||':'|| lc_errmsg;
        RAISE DATE_RANGE_EXCEPTION;
      END IF;
      -- -------------------------------------------
      -- Get all the transactions from oracle for
      -- specific range dates and assign to bucket
      -- -------------------------------------------
      OPEN lcu_get_all_trx
      ( p_customer    => p_customer_id
        ,p_from_date   => get_bucket_ranges.first_date
        ,p_to_date     => get_bucket_ranges.last_date
       );
      LOOP
      FETCH lcu_get_all_trx INTO get_all_trx;
      EXIT WHEN lcu_get_all_trx%NOTFOUND;

        -- Incrementing Counter in the loop
        ln_loop_counter      := ln_loop_counter + 1;
        ln_overflow_sequence := ln_overflow_sequence + 1;
        -- -------------------------------------------
        -- Call the Create Record Procedure to create record type '4'
        -- into xx_ar_payments_interface table for matching bucket
        -- -------------------------------------------
        -- Assigning the value into record columns
        --
        ln_tot_amount := ln_tot_amount + get_all_trx.amount_due_remaining;

        lr_record.status                := 'AR_PLB_NEW_RECORD';
        lr_record.record_type           := '4';
        lr_record.batch_name            := p_record.batch_name;
        lr_record.item_number           := p_record.item_number;
        lr_record.invoice1              := get_all_trx.trx_number;
        lr_record.amount_applied1       := get_all_trx.amount_due_remaining;
        lr_record.trx_date              := get_all_trx.trx_date;
        lr_record.process_num           := p_record.process_num;
        --lr_record.inv_match_status      := 'INVOICE_DATERANGE_MATCHED';
        lr_record.customer_id           := p_customer_id;
        lr_record.auto_cash_status      := 'DATERANGE_MATCHED';
        lr_record.overflow_sequence     := ln_overflow_sequence;
        /*
        IF ln_loop_counter = 1 THEN
          lr_record.overflow_indicator  := '9';
        ELSIF ln_loop_counter <> 1 THEN
          lr_record.overflow_indicator  := '0';
        END IF;
        */
        lr_record.overflow_indicator  := '0';
        -- -------------------------------------------
        -- Calling the Create Interface record procedure
        -- -------------------------------------------
        create_interface_record
        ( x_errmsg      =>  lc_errmsg
         ,x_retstatus   =>  ln_retcode
         ,p_record      =>  lr_record
        );

        IF ln_retcode  = gn_error THEN
          lc_error_details := lc_error_location||':'|| lc_errmsg;
          RAISE DATE_RANGE_EXCEPTION;
        END IF;
        -- -------------------------------------------
        -- Call the Print Message Footer Procedure to
        -- print the detail transaction
        -- -------------------------------------------
        /*
        print_message_footer
        ( x_errmsg                 =>  lc_errmsg
         ,x_retstatus              =>  ln_retcode
         ,p_customer_id            =>  ln_customer_id
         ,p_check                  =>  get_lockbox_rec.check_number
         ,p_transaction            =>  get_lockbox_det_rec.invoice3
         ,p_tran_amount            =>  ln_amount_applied3
         ,p_sub_amount             =>  get_trx_number.acctd_amount_due_remaining
         ,p_sub_invoice            =>  get_trx_number.trx_number
        );
        */

      END LOOP;
      CLOSE lcu_get_all_trx;

        UPDATE xx_ar_payments_interface XAPI
        SET    XAPI.overflow_indicator = '9'
        WHERE  XAPI.record_type        = '4'
        AND    XAPI.process_num        = p_process_num
        --AND    XAPI.auto_cash_request  = gn_request_id
        AND    XAPI.overflow_sequence  = ln_loop_counter
        AND    XAPI.batch_name         = p_record.batch_name
        AND    XAPI.item_number        = p_record.item_number
        AND    p_customer_id           =
           (SELECT XAPI1.customer_id
            FROM   xx_ar_payments_interface XAPI1
            WHERE  XAPI1.rowid        = p_rowid
            AND    XAPI1.record_type  = '6'
            AND    XAPI1.batch_name   = p_record.batch_name
            AND    XAPI1.item_number  = p_record.item_number);

      EXIT; -- Exit from the main loop

    END IF;
  END LOOP;
  CLOSE lcu_get_bucket_ranges;

    --fnd_file.put_line(fnd_file.output,'ln_tot_amount:-'||ln_tot_amount);

  IF lc_date_range_match = 'Y' THEN
    x_date_range_match  := 'Y';
  ELSE
    x_date_range_match  := NULL;
  END IF;

EXCEPTION
WHEN DATE_RANGE_EXCEPTION THEN
  x_errmsg     := lc_error_details;
  x_retstatus  := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.date_range_rule');
  fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash Print Process Details');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg           := fnd_message.get;
  x_retstatus        := gn_error;
  x_date_range_match := NULL;
  put_log_line('==========================');
  put_log_line(x_errmsg);
END date_range_rule;

-- +=================================================================================+
-- | Name        : ANY_COMBO                                                         |
-- | Description : This procedure will be used Find out any combination invoice match|
-- |                                                                                 |
-- |                                                                                 |
-- | Parameters  : p_customer_id                                                     |
-- |               p_match_type                                                      |
-- |               p_term_id                                                         |
-- |               p_deposit_date                                                    |
-- |               p_cur_precision                                                   |
-- |               p_process_num                                                     |
-- |               p_rowid                                                           |
-- |               p_record                                                          |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |               x_any_combo_match                                                 |
-- +=================================================================================+
PROCEDURE any_combo
( x_errmsg          OUT NOCOPY   VARCHAR2
,x_retstatus       OUT NOCOPY   NUMBER
,x_any_combo_match OUT NOCOPY   VARCHAR2
,p_customer_id     IN           NUMBER
,p_match_type      IN           VARCHAR2 DEFAULT NULL
,p_record          IN           xx_ar_payments_interface%ROWTYPE
,p_process_num     IN           VARCHAR2
,p_rowid           IN           VARCHAR2
,p_max_trx         IN           NUMBER
,p_from_days       IN           NUMBER
,p_to_days         IN           NUMBER
,p_trx_class       IN           VARCHAR2
,p_term_id         IN           NUMBER    DEFAULT NULL
,p_deposit_date    IN           DATE      DEFAULT NULL
,p_cur_precision   IN           NUMBER    DEFAULT NULL
)
 IS

 -- ===================
 -- REF CURSORS
 -- ===================
 TYPE L_Inv_Ref_Cur IS REF CURSOR;

 -- ===================
 -- Local Variables
 -- ===================
 lc_error_details VARCHAR2(30000) :=TO_CHAR(NULL);
 any_combo_error  EXCEPTION;
 ln_start_with    NUMBER  :=65;
 lb_matching      BOOLEAN :=FALSE;
 lr_record        xx_ar_payments_interface%ROWTYPE;
 lb_status        BOOLEAN :=FALSE;
 lb_trx_exists    BOOLEAN :=FALSE;
 l_count          NUMBER;

 -- ===================
 -- ASSOCIATIVE ARRAYS
 -- ===================
 TYPE Invoice_Tbl IS RECORD
  (
    trx_seq     VARCHAR2(1)
   ,trx_date    DATE
   ,trx_number  VARCHAR2(80)
   ,trx_bal_amt NUMBER
  );
 TYPE Invoice_Arr IS TABLE OF Invoice_Tbl INDEX BY PLS_INTEGER;
 Inv_Rec           Invoice_Tbl;
 xx_ar_invoice_arr Invoice_Arr;

 PROCEDURE Create_Invoice_Array (p_trx_exists OUT BOOLEAN) IS
 -- ===================
 -- Local Variables
 -- ===================

 lc_any_combo_sql VARCHAR2(30000) :=TO_CHAR(NULL);
 Invoice_Cursor    L_Inv_Ref_Cur;
 pop_invoice_error EXCEPTION;

 -- =====================================
 -- Begin (Create_Invoice_Array)
 -- =====================================
BEGIN
  IF nvl(UPPER(p_trx_class),'BOTH') ='BOTH' THEN
   lc_any_combo_sql :=
  'SELECT TO_CHAR(NULL)
         ,TO_CHAR(b.trx_date ,''DD-MON-RRRR'')
         ,b.trx_number
         ,CASE WHEN (:d_deposit_date <= b.due_date AND b.class = ''INV'') THEN
                                ROUND(b.acctd_amount_due_remaining - (b.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(b.term_id,b.trx_date,:d_deposit_date)),:n_cur_precision)
                      ELSE b.acctd_amount_due_remaining
                      END amount_due_remaining   --Added for the Defect #3984
--         ,ROUND(b.acctd_amount_due_remaining - (b.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(:n_term_id,(:d_deposit_date - b.trx_date))),:n_cur_precision) 
amount_due_remaining --Commented for the Defect #3984
  FROM   XX_AR_LOCKBOX_INTERIM b
        ,ra_customer_trx ract
  WHERE  b.customer_id =:customer_id
    AND  trunc(b.due_date) between (trunc(sysdate)-nvl(:from_days ,90)) and (trunc(sysdate)-nvl(:to_days ,30))
    AND  b.status =''OP''
    AND  b.class IN (''INV'' ,''CM'')
    AND  b.amount_due_remaining<>0
--    AND  ract.trx_number = b.trx_number          --Commented for the Defect #4005
    AND  ract.customer_trx_id = b.customer_trx_id  --Added for the Defect #4005
    AND  ract.bill_to_customer_id = b.customer_id
--    AND  ract.printing_pending = ''N''   --Commented foe Defect # 3913
    AND  ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
    AND  rownum<nvl(:max_inv ,15)+1
  ORDER BY trunc(b.trx_date) desc';
  OPEN Invoice_Cursor FOR lc_any_combo_sql USING p_deposit_date ,p_deposit_date ,p_cur_precision ,p_customer_id ,p_from_days 
,p_to_days ,p_max_trx;  --Added for the Defect #3984
--   OPEN Invoice_Cursor FOR lc_any_combo_sql USING p_term_id ,p_deposit_date ,p_cur_precision ,p_customer_id ,p_from_days ,p_to_days ,p_max_trx;  --Commented for the Defect #3984
  ELSE
   lc_any_combo_sql :=
  'SELECT TO_CHAR(NULL)
         ,TO_CHAR(b.trx_date ,''DD-MON-RRRR'')
         ,b.trx_number
         ,CASE WHEN (:d_deposit_date <= b.due_date AND b.class = ''INV'') THEN
                                ROUND(b.acctd_amount_due_remaining - (b.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(b.term_id,b.trx_date,:d_deposit_date)),:n_cur_precision)
                      ELSE b.acctd_amount_due_remaining
                      END amount_due_remaining   --Added for the Defect #3984
--         ,ROUND(b.acctd_amount_due_remaining - (b.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(:n_term_id,(:d_deposit_date - b.trx_date))),:n_cur_precision) 
amount_due_remaining  --Commented for the Defect #3984
  FROM   XX_AR_LOCKBOX_INTERIM b
        ,ra_customer_trx ract
  WHERE  b.customer_id =:customer_id
    AND  trunc(b.due_date) between (trunc(sysdate)-nvl(:from_days ,90)) and (trunc(sysdate)-nvl(:to_days ,30))
           -- nvl((trunc(sysdate)-nvl(:from_days ,90)) ,trunc(b.due_date)) and nvl((trunc(sysdate)-nvl(:to_days ,30)) ,trunc
(b.due_date))
    AND  b.status =''OP''
    AND  b.class =:trxclass
    AND  b.amount_due_remaining<>0
    AND  rownum<nvl(:max_inv ,15)+1
  --  AND  ract.trx_number = b.trx_number          --Commented for the Defect #4005
    AND  ract.customer_trx_id = b.customer_trx_id  --Added for the Defect #4005
    AND  ract.bill_to_customer_id = b.customer_id
--    AND  ract.printing_pending = ''N''  --Commmented for Defect # 3913
    AND  ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
  ORDER BY trunc(b.trx_date) desc';
  OPEN Invoice_Cursor FOR lc_any_combo_sql USING p_deposit_date ,p_deposit_date ,p_cur_precision ,p_customer_id ,p_from_days 
,p_to_days ,p_trx_class ,p_max_trx; --Added for the Defect #3984
--   OPEN Invoice_Cursor FOR lc_any_combo_sql USING p_term_id ,p_deposit_date ,p_cur_precision ,p_customer_id ,p_from_days ,p_to_days ,p_trx_class ,p_max_trx; --Commented for the Defect #3984
  END IF;

   LOOP
    FETCH Invoice_Cursor INTO Inv_Rec;
     EXIT WHEN Invoice_Cursor%NOTFOUND;
      xx_ar_invoice_arr(ln_start_with).trx_seq     :=CHR(ln_start_with);
      xx_ar_invoice_arr(ln_start_with).trx_date    :=Inv_Rec.trx_date;
      xx_ar_invoice_arr(ln_start_with).trx_number  :=Inv_Rec.trx_number;
      xx_ar_invoice_arr(ln_start_with).trx_bal_amt :=Inv_Rec.trx_bal_amt;
    ln_start_with :=ln_start_with+1;
     IF ln_start_with >90 THEN
      EXIT;
     END IF;
   END LOOP;
  p_trx_exists :=TRUE;
 CLOSE Invoice_Cursor;
 EXCEPTION
   WHEN NO_DATA_FOUND THEN
    p_trx_exists :=FALSE;
   WHEN pop_invoice_error THEN
    x_errmsg     := lc_error_details;
    x_retstatus  := 2;
    put_log_line('==========================');
    put_log_line(x_errmsg);
   WHEN OTHERS THEN
    fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
    fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.Create_Invoice_Array');
    fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash -Any Combo');
    fnd_message.set_token('SQLERROR',SQLERRM);
    x_errmsg           :=fnd_message.get;
    x_retstatus        :=2;
    x_any_combo_match  :=TO_CHAR(NULL);
    put_log_line('==========================');
   put_log_line(x_errmsg);
 END Create_Invoice_Array;

PROCEDURE Find_Matching_Trx
(
 p_ncr_combi_str IN  VARCHAR2
,p_matching      OUT BOOLEAN
) IS
 -- ===================
 -- Local Variables
 -- ===================
 ln_running_total    NUMBER :=0;
 find_matching_error EXCEPTION;

-- ================================
-- Begin (Find_Matching_Trx)
-- ================================
BEGIN
 FOR indx IN 1..length(p_ncr_combi_str)
  LOOP
   ln_running_total := ln_running_total
                      +
                       (xx_ar_invoice_arr(ASCII(SUBSTR(p_ncr_combi_str ,indx ,1))).trx_bal_amt);
  END LOOP;
   IF (ln_running_total =p_record.remittance_amount) THEN
    -- ========================================================================
    -- We found a matching combination of invoices to the remittance amount.
    -- ========================================================================
    p_matching :=TRUE;
   ELSE
    p_matching :=FALSE;
   END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
   p_matching :=FALSE;
  WHEN find_matching_error THEN
   x_errmsg     := lc_error_details;
   x_retstatus  := 2;
   put_log_line('==========================');
   put_log_line(x_errmsg);
  WHEN OTHERS THEN
   fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
   fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.Find_Matching_Trx');
   fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash -Any Combo');
   fnd_message.set_token('SQLERROR',SQLERRM);
   x_errmsg           :=fnd_message.get;
   x_retstatus        :=2;
   x_any_combo_match  :=TO_CHAR(NULL);
   put_log_line('==========================');
   put_log_line(x_errmsg);
END Find_Matching_Trx;

PROCEDURE Insert_Overflow_Records
           (
            p_ncr_combi_str IN  VARCHAR2
           ,p_status        OUT BOOLEAN
           ) IS
 -- ===================
 -- Local Variables
 -- ===================
lc_errmsg  VARCHAR2(4000);
ln_retcode NUMBER;
insert_overflow_error EXCEPTION;
any_combo_exception   EXCEPTION;
-- ================================
-- Begin (Insert_Overflow_Records)
-- ================================
BEGIN
   -- ===================================================
   -- Delete existing overflow records [Record Type 4]
   -- ===================================================
   delete_lckb_rec
   ( x_errmsg      =>lc_errmsg
    ,x_retstatus   =>ln_retcode
    ,p_process_num =>p_process_num
    ,p_record_type =>'6'
    ,p_rowid       =>p_rowid
    ,p_customer_id =>p_customer_id
    ,p_record      =>p_record
   );
    --put_log_line('In AnyCombo -@Delete Overflow =>'||lc_errmsg);

  <<overflow_insert_counter>>
 FOR indx IN 1..length(p_ncr_combi_str)
  LOOP

   -- ==========================================
   -- Insert overflow records [Record Type 4]
   -- ==========================================
   lr_record.status            :='AR_PLB_NEW_RECORD';
   lr_record.record_type       :='4';
   lr_record.batch_name        :=p_record.batch_name;
   lr_record.item_number       :=p_record.item_number;
   lr_record.invoice1          :=xx_ar_invoice_arr(ASCII(SUBSTR(p_ncr_combi_str ,indx ,1))).trx_number;
   lr_record.amount_applied1   :=xx_ar_invoice_arr(ASCII(SUBSTR(p_ncr_combi_str ,indx ,1))).trx_bal_amt;
   lr_record.trx_date          :=xx_ar_invoice_arr(ASCII(SUBSTR(p_ncr_combi_str ,indx ,1))).trx_date;
   lr_record.process_num       :=p_record.process_num;
   lr_record.customer_id       :=p_customer_id;
   lr_record.auto_cash_status  :='ANY_COMBO_MATCHED';
   lr_record.overflow_sequence :=overflow_insert_counter.indx;

   --put_log_line('Invoice :'||lr_record.invoice1||' ,'||'Amount Applied :'||lr_record.amount_applied1);

    -- =============================
    -- Assign Overflow indicator.
    -- First overflow record "0"
    -- Last  overflow record "9"
    -- =============================

     IF overflow_insert_counter.indx != length(p_ncr_combi_str) THEN
      lr_record.overflow_indicator  := '0';
     ELSE
      lr_record.overflow_indicator  := '9';
     END IF;

    create_interface_record
     ( x_errmsg    =>lc_errmsg
      ,x_retstatus =>ln_retcode
      ,p_record    =>lr_record
     );

    IF ln_retcode  = gn_error THEN
       lc_error_details := 'Calling Create Interface Record from Any Combo Procedure-'||':'|| lc_errmsg;
       RAISE any_combo_exception;
    END IF;
   -- put_log_line('In AnyCombo -@CreateInterface Overflow =>'||lc_errmsg);
   -- ============================================================
   -- Update parent receipt record with status [Record Type 6]
   -- ============================================================
  END LOOP;

  IF ln_retcode IS NULL OR ln_retcode = gn_normal THEN
    x_any_combo_match := 'Y';
  ELSIF ln_retcode = gn_error THEN
    x_any_combo_match := 'N';
  ELSE
    x_any_combo_match := NULL;
  END IF;

EXCEPTION
  WHEN any_combo_exception THEN
    x_errmsg           := lc_error_details || lc_errmsg;
    x_retstatus        := gn_error;
    x_any_combo_match  := TO_CHAR(NULL);
    put_log_line('==========================');
    put_log_line(x_errmsg);
  WHEN INSERT_OVERFLOW_ERROR THEN
    x_errmsg     := lc_error_details;
    x_retstatus  := gn_error;
    put_log_line('==========================');
    put_log_line(x_errmsg);
  WHEN OTHERS THEN
    fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
    fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.Insert_Overflow_Records');
    fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash -Any Combo');
    fnd_message.set_token('SQLERROR',SQLERRM);
    x_errmsg           :=fnd_message.get;
    x_retstatus        :=gn_error;
    x_any_combo_match  :=TO_CHAR(NULL);
    put_log_line('==========================');
    put_log_line(x_errmsg);
END Insert_Overflow_Records;

PROCEDURE Search_Matching_Combi IS
 -- ===================
 -- Local Variables
 -- ===================
 search_matching_error EXCEPTION;

-- ================================
-- Begin (Search_Matching_Combi)
-- ================================
BEGIN
 FOR COMBI_REC IN
  (
    SELECT *
    FROM   xx_ar_anycombo_ncr_gtmp
    --WHERE request_id = gn_ncr_request_id
  )
  LOOP
   --put_log_line('Inside Search Matching Loop...');
   --put_log_line('Check Combination ,Start Time :'||TO_CHAR(SYSDATE ,'DD-MON-RRRR HH24:MI:SS'));
     Find_Matching_Trx(combi_rec.ncr_string ,lb_matching);
   --put_log_line('Check Combination ,End   Time :'||TO_CHAR(SYSDATE ,'DD-MON-RRRR HH24:MI:SS'));

    IF (lb_matching) THEN
      put_log_line('================================================');
      put_log_line('Matched combination :'||combi_rec.ncr_string);
      FOR str_indx IN 1..length(combi_rec.ncr_string)
       LOOP
        put_log_line( '       Invoice =>'
           ||xx_ar_invoice_arr(ASCII(SUBSTR(combi_rec.ncr_string ,str_indx ,1))).trx_number
         );
       END LOOP;
      put_log_line('================================================');
     Insert_Overflow_Records
      (
        combi_rec.ncr_string
       ,lb_status
      );
    ELSE
     NULL;
     -- ===================================
     -- Current combination did not match.
     -- Let us check the next one.
     -- ===================================
    END IF;
  END LOOP;
EXCEPTION
  WHEN search_matching_error THEN
   x_errmsg     := lc_error_details;
   x_retstatus  := 2;
   put_log_line('==========================');
   put_log_line(x_errmsg);
  WHEN OTHERS THEN
   fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
   fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.Search_Matching_Combi');
   fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash -Any Combo');
   fnd_message.set_token('SQLERROR',SQLERRM);
   x_errmsg           :=fnd_message.get;
   x_retstatus        :=2;
   x_any_combo_match  :=TO_CHAR(NULL);
   put_log_line('==========================');
   put_log_line(x_errmsg);
END Search_Matching_Combi;

-- ==========================
-- Main (any_combo)
-- ==========================
BEGIN

put_log_line('===========================================================');
put_log_line('***** Any Combo -Parameter *****');
put_log_line('      ---------------------                       ');
-- put_log_line('Customer ID        :'||p_customer_id);
-- put_log_line('Check Number       :'||p_record.check_number);
-- put_log_line('Check Amount       :'||TO_CHAR(p_record.remittance_amount));
-- put_log_line('Match Type         :'||p_match_type);
-- put_log_line('Batch Name         :'||p_record.batch_name);
-- put_log_line('Item  Number       :'||p_record.item_number);
-- put_log_line('Process Number     :'||p_process_num);
   put_log_line('Rowid              :'||p_rowid);
-- put_log_line('Maximum Invoices   :'||p_max_trx);
-- put_log_line('From Days          :'||p_from_days);
-- put_log_line('To Days            :'||p_to_days);
-- put_log_line('Transaction Class  :'||p_trx_class);
-- put_log_line('Term ID            :'||p_term_id);
-- put_log_line('Deposit Date       :'||p_deposit_date);
-- put_log_line('Currency Precision :'||p_cur_precision);
-- put_log_line('===========================================================');
-- put_log_line('');

 -- =================================================
 -- Step1: Get all open invoices for the customer
 --        and copy it to an array.
 -- =================================================
 put_log_line('Enter :Step1');
  Create_Invoice_Array(lb_trx_exists);
 IF (lb_trx_exists) THEN
  IF (xx_ar_invoice_arr.COUNT >0) THEN
   put_log_line('================================================');
   put_log_line('Transaction Array:');
   FOR rec IN xx_ar_invoice_arr.FIRST .. xx_ar_invoice_arr.LAST
    LOOP

      put_log_line(
       xx_ar_invoice_arr(rec).trx_seq
      ||'|'||
       TO_CHAR(xx_ar_invoice_arr(rec).trx_date,'DD-MON-YYYY')
      ||'|'||
       xx_ar_invoice_arr(rec).trx_number
      ||'|'||
       TO_CHAR(xx_ar_invoice_arr(rec).trx_bal_amt)
     );
    END LOOP;
   put_log_line('Exit  :Step1');
   -- ====================================================
   -- Step2: Get all combinations to be checked for the
   --        list of open invoices retrieved in step1.
   -- ====================================================
   put_log_line('Enter :Step2');

    --xx_ar_lockbox_process_pkg.Gen_Combinations;
      SELECT COUNT(*)
      INTO   l_count
      FROM   xx_ar_anycombo_ncr_gtmp;
      --WHERE  request_id = gn_ncr_request_id;

   put_log_line('    Total Combinations :'||l_count);

   put_log_line('Exit  :Step2');

   -- ====================================================
   -- Step3: For each combination from step2, determine
   --        if the receipt amount is a match.
   -- ====================================================

   put_log_line('Enter :Step3');
    Search_Matching_Combi;
   put_log_line('Exit  :Step3');

  ELSE
   put_log_line('Any Combo: Number of Invoices to check =0');
   --put_log_line('Total Invoice Array Count :'||TO_CHAR(xx_ar_invoice_arr.COUNT));
   --put_log_line('Any Combo: Number of Invoices to check =0 ,Exit...');
  END IF;
 ELSE
  put_log_line('Any Combo: Number of Invoices to check =0');
 END IF;
EXCEPTION
  WHEN any_combo_error THEN
   x_errmsg     := lc_error_details;
   x_retstatus  := gn_error;
   put_log_line('==========================');
   put_log_line(x_errmsg);
  WHEN OTHERS THEN
   fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
   fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.any_combo');
   fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash -Any Combo');
   fnd_message.set_token('SQLERROR',SQLERRM);
   x_errmsg           :=fnd_message.get;
   x_retstatus        :=gn_error;
   x_any_combo_match  :=TO_CHAR(NULL);
   put_log_line('==========================');
   put_log_line(x_errmsg);
END any_combo;


-- +=================================================================================+
-- | Name        : AS_IS_CONSOLIDATED_MATCH_RULE       -- Added for Defect #3983     |
-- | Description : 1. Validate BAI Invoice Number is a Consolidated Bill Number      |
-- |               2. If Match Found then delete current '4' records                 |
-- |                  and create '4' records using the individual invoices/CMs that  |
-- |                  are open for that consolidated bill                            |
-- |               3. If Match not found then proceed with Partial Invoice Match     |
-- |                                                                                 |
-- |                                                                                 |
-- | Parameters  : p_record                                                          |
-- |               p_term_id                                                         |
-- |               p_customer_id                                                     |
-- |               p_deposit_date                                                    |
-- |               p_rowid                                                           |
-- |               p_process_num                                                     |
-- |               p_invoice_num                                                     |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE as_is_consolidated_match_rule
(x_errmsg             OUT   NOCOPY  VARCHAR2
,x_retstatus          OUT   NOCOPY  NUMBER
,x_invoice_exists     OUT   NOCOPY  VARCHAR2
,x_invoice_status     OUT   NOCOPY  VARCHAR2
,p_record             IN            xx_ar_payments_interface%ROWTYPE
,p_term_id            IN            NUMBER
,p_customer_id        IN            NUMBER
,p_deposit_date       IN            DATE
,p_rowid              IN            VARCHAR2
,p_process_num        IN            VARCHAR2
,p_invoice_num        IN            NUMBER
,p_applied_amt        IN            NUMBER       --Added for Defect #3983 on 12-FEB-10
)
IS
  -- -----------------------------------------------
  -- Match BAI Invoice with Oracle Consolidated bill
  -- -----------------------------------------------
  CURSOR lcu_get_cons_det
  IS
-- Added for Defect #3983 on 11-FEB-10
  SELECT SUM(amount_due_remaining)  amount_due_remaining
        ,cons_inv_id                cons_inv_id
  FROM(
    SELECT APS.acctd_amount_due_remaining       amount_due_remaining
          ,APS.cons_inv_id  cons_inv_id
    FROM   XX_AR_LOCKBOX_INTERIM  APS
    WHERE  APS.status            = 'OP'
    AND    APS.customer_id IN (SELECT column_value
                               FROM TABLE(
                                          CAST(lt_related_custid_type AS XX_AR_CUSTID_TAB_T)
                                         )
                              )
    AND    APS.class             = 'CM'
    AND    APS.cons_inv_id       IS NOT NULL
    AND    APS.cons_inv_id       = p_invoice_num
    UNION ALL
    SELECT CASE WHEN (p_deposit_date <= APS.due_date) THEN
                                   ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(APS.term_id
                                                                                                                              
                                ,APS.trx_date
                                                                                                                              
                                ,p_deposit_date
                                                                                                                              
                                 )
                                                                          )
                                       ,gn_cur_precision
                                        )
              ELSE APS.acctd_amount_due_remaining
              END amount_due_remaining
        ,APS.cons_inv_id
  FROM   XX_AR_LOCKBOX_INTERIM  APS
  WHERE  APS.status            = 'OP'
  AND    APS.customer_id IN (SELECT column_value
                               FROM TABLE(
                                          CAST(lt_related_custid_type AS XX_AR_CUSTID_TAB_T)
                                         )
                            )
  AND    APS.class             = 'INV'
  AND    APS.cons_inv_id       IS NOT NULL
  AND    APS.cons_inv_id       = p_invoice_num
  )
  GROUP BY cons_inv_id;
-- Commented for Defect #3983 on 14-FEB-10
/*
  SELECT DISTINCT APS.cons_inv_id
        ,APS.customer_id
  FROM   ar_payment_schedules  APS
  WHERE  APS.status      = 'OP'
  AND    APS.customer_id  IN (SELECT column_value
                                FROM TABLE(
                                           CAST(lt_related_custid_type AS XX_AR_CUSTID_TAB_T)
                                          )
                             )
  AND    APS.class        IN ('INV','CM')
  AND    APS.cons_inv_id = p_invoice_num
  AND    APS.cons_inv_id IS NOT NULL;
*/
  -- -------------------------------------------
  --
  -- -------------------------------------------
  CURSOR lcu_get_cons_det_trx (p_cons_inv_id  IN  NUMBER)
  IS
  SELECT APS.acctd_amount_due_remaining amount_due_remaining
        ,APS.cons_inv_id
        ,APS.trx_number
        ,APS.trx_date
  FROM   XX_AR_LOCKBOX_INTERIM  APS
  WHERE  APS.status            = 'OP'
  AND    APS.class             = 'CM'
  AND    APS.cons_inv_id       = p_cons_inv_id
  UNION ALL
  SELECT CASE WHEN (p_deposit_date <= APS.due_date) THEN
                                 ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(APS.term_id
                                                                                                                              
            ,APS.trx_date
                                                                                                                              
            ,p_deposit_date
                                                                                                                              
            )
                                                      )
                               ,gn_cur_precision
                                )
              ELSE APS.acctd_amount_due_remaining
              END amount_due_remaining
        ,APS.cons_inv_id
        ,APS.trx_number
        ,APS.trx_date
  FROM   XX_AR_LOCKBOX_INTERIM  APS
  WHERE  APS.status            = 'OP'
  AND    APS.class             = 'INV'
  AND    APS.cons_inv_id       = p_cons_inv_id;

  -- -------------------------------------------
  -- Local Variable Declarations
  -- -------------------------------------------
  get_cons_det_trx              lcu_get_cons_det_trx%ROWTYPE;
  get_cons_det                  lcu_get_cons_det%ROWTYPE;
  lr_record                     xx_ar_payments_interface%ROWTYPE;

  lc_error_location             VARCHAR2(32000);
  lc_error_details              VARCHAR2(32000);
  lc_errmsg                     VARCHAR2(32000);

  ln_retcode                    NUMBER;
  ln_amount_due_remaining       NUMBER;
  ln_cons_inv_id                NUMBER;
  ln_overflow_seq               NUMBER :=0;
  ln_loop_cntr                  NUMBER :=0;

  EX_CONS_EXCEPTION             EXCEPTION;

BEGIN

  ln_cons_inv_id      :=  NULL;
  x_invoice_exists    := 'N';
  x_invoice_status    :=  NULL;
  -- ----------------------------------------------
  -- Loop through all the records of Consolidated
  -- ----------------------------------------------
  lc_error_location := 'Calling the AS IS Consolidated Match Rule ';

  OPEN lcu_get_cons_det;
  FETCH lcu_get_cons_det INTO get_cons_det;
  CLOSE  lcu_get_cons_det;
    IF (get_cons_det.cons_inv_id IS NOT NULL)THEN
              x_invoice_exists     := 'Y';
              x_invoice_status     := 'AS_IS_CONSOLIDATED_MATCH';
              ln_cons_inv_id       := get_cons_det.cons_inv_id;
-- Call Delete Procedure to delete existing '4' records
              lc_error_location :=  'Calling the delete procedure for AS IS Consolidated Match Rule';
              delete_lckb_rec
              ( x_errmsg         =>  lc_errmsg
               ,x_retstatus      =>  ln_retcode
               ,p_process_num    =>  p_process_num
               ,p_record_type    =>  '6'
               ,p_rowid          =>  p_rowid
               ,p_customer_id    =>  p_customer_id
               ,p_record         =>  p_record
              );
              IF ln_retcode  = gn_error THEN
                 lc_error_details := lc_error_location||':'|| lc_errmsg;
                 RAISE EX_CONS_EXCEPTION;
              END IF;
-------------------------------------------------------------------------------------------
-- Create '4' records only when the BAI Amt matches with the Open Amt for Consolidated Bill
-------------------------------------------------------------------------------------------
              IF(get_cons_det.amount_due_remaining = p_applied_amt) THEN  --Added for Defect #3983 on 12-FEB-10
                OPEN  lcu_get_cons_det_trx (p_cons_inv_id  => ln_cons_inv_id );
                LOOP
                FETCH lcu_get_cons_det_trx  INTO get_cons_det_trx;
                EXIT WHEN lcu_get_cons_det_trx%NOTFOUND;

-- ----------------------------------------------------------
-- Call the Create Record Procedure to create record type '4'
-- into xx_ar_payments_interface table for matching bucket
-- ----------------------------------------------------------
    -- Assigning the value into record columns

                      ln_loop_cntr      := ln_loop_cntr + 1;
                      ln_overflow_seq   := ln_overflow_seq + 1;

                      lr_record.status                := 'AR_PLB_NEW_RECORD';
                      lr_record.record_type           := '4';
                      lr_record.batch_name            := p_record.batch_name;
                      lr_record.item_number           := p_record.item_number;
                      lr_record.invoice1              := get_cons_det_trx.trx_number;
                      lr_record.amount_applied1       := get_cons_det_trx.amount_due_remaining;
                      lr_record.trx_date              := get_cons_det_trx.trx_date;
                      lr_record.process_num           := p_process_num;
                      lr_record.inv_match_status      := 'AS_IS_CONSOLIDATED_MATCH';
                      lr_record.customer_id           := p_customer_id;
                      lr_record.auto_cash_status      := 'AS_IS_CONSOLIDATED_MATCH';
                      lr_record.overflow_sequence     := ln_overflow_seq;
                      lr_record.overflow_indicator    := '0';

-- -------------------------------------------
-- Calling the Create Interface record procedure
-- -------------------------------------------
                      create_interface_record ( x_errmsg      =>  lc_errmsg
                                               ,x_retstatus   =>  ln_retcode
                                               ,p_record      =>  lr_record
                                              );
                     IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_CONS_EXCEPTION;
                     END IF;
                END LOOP;
                CLOSE lcu_get_cons_det_trx;

                UPDATE xx_ar_payments_interface XAPI
                SET    XAPI.overflow_indicator = '9'
                WHERE  XAPI.record_type        = '4'
                AND    XAPI.process_num        = p_process_num
                AND    XAPI.overflow_sequence  = ln_loop_cntr
                AND    XAPI.batch_name         = p_record.batch_name
                AND    XAPI.item_number        = p_record.item_number
                AND    p_customer_id           =
                            (SELECT XAPI1.customer_id
                             FROM   xx_ar_payments_interface XAPI1
                             WHERE  XAPI1.rowid        = p_rowid
                             AND    XAPI1.record_type  = '6'
                             AND    XAPI1.batch_name   = p_record.batch_name
                             AND    XAPI1.item_number  = p_record.item_number);
              END IF;
------------------------------------------------------------------------------
-- Update Invoice Match Status in Record Type '6' as AS_IS_CONSOLIDATED_MATCH
------------------------------------------------------------------------------
             update_lckb_rec
            ( x_errmsg                    => lc_errmsg
             ,x_retstatus                 => ln_retcode
             ,p_process_num               => p_process_num
             ,p_record_type               => '6'
             ,p_inv_match_status          => 'AS_IS_CONSOLIDATED_MATCH'
             ,p_rowid                     => p_rowid
            );

            IF ln_retcode  = gn_error THEN
               lc_error_details := lc_error_location||':'|| lc_errmsg;
               RAISE EX_CONS_EXCEPTION;
            END IF;
    END IF;
    COMMIT;
EXCEPTION
WHEN EX_CONS_EXCEPTION THEN
  x_errmsg     := lc_error_details;
  x_retstatus  := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.as_is_consolidated_match_rule');
  fnd_message.set_token('PROGRAM','AR Lockbox AS IS Consolidated Match Rule Procedure');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg     := fnd_message.get;
  x_retstatus  := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
END as_is_consolidated_match_rule;
-- +=================================================================================+
-- | Name        : CONSOLIDATED_BILL_RULE                                            |
-- | Description : This procedure will apply Consolidated Bill Rule for all the '6'  |
-- |               record type records after not qualify exact match, clear account  |
-- |               match and partial invoice match process                           |
-- |                                                                                 |
-- | Parameters  : p_record                                                          |
-- |               p_term_id                                                         |
-- |               p_customer_id                                                     |
-- |               p_deposit_date                                                    |
-- |               p_rowid                                                           |
-- |               p_process_num                                                     |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE consolidated_bill_rule
(x_errmsg             OUT   NOCOPY  VARCHAR2
,x_retstatus          OUT   NOCOPY  NUMBER
,p_record             IN            xx_ar_payments_interface%ROWTYPE
,p_term_id            IN            NUMBER
,p_customer_id        IN            NUMBER
,p_deposit_date       IN            DATE
,p_rowid              IN            VARCHAR2
,p_process_num        IN            VARCHAR2
)
IS

  -- -------------------------------------------
  -- Sum of all amount for a specific consolidated bill
  -- -------------------------------------------
  CURSOR lcu_get_sum_cons_amt
  IS
/*  SELECT SUM(ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(p_term_id,(p_deposit_date - APS.trx_date))),gn_cur_precision)) 
amount_due_remaining
        ,APS.cons_inv_id
  FROM   ar_payment_schedules  APS
  WHERE  APS.status            = 'OP'
  AND    APS.customer_id       =  p_customer_id
  AND    APS.class             IN ('INV','CM')
  AND    APS.cons_inv_id       IS NOT NULL
  GROUP BY APS.cons_inv_id; */ -- Commented for the Defect # 3984
--------------------------
-- Added for Defect #3984
--------------------------
SELECT SUM(amount_due_remaining)  amount_due_remaining
      ,cons_inv_id                cons_inv_id
FROM(
  SELECT APS.acctd_amount_due_remaining       amount_due_remaining
        ,APS.cons_inv_id  cons_inv_id
  FROM   XX_AR_LOCKBOX_INTERIM  APS
  WHERE  APS.status            = 'OP'
  AND    APS.customer_id       =  p_customer_id
  AND    APS.class             = 'CM'
  AND    APS.cons_inv_id       IS NOT NULL
  UNION ALL
  SELECT CASE WHEN (p_deposit_date <= APS.due_date) THEN
                                 ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(APS.term_id
                                                                                                                              
            ,APS.trx_date
                                                                                                                              
            ,p_deposit_date
                                                                                                                              
            )
                                                      )
                               ,gn_cur_precision
                                )
              ELSE APS.acctd_amount_due_remaining
              END amount_due_remaining
        ,APS.cons_inv_id
  FROM   XX_AR_LOCKBOX_INTERIM  APS
  WHERE  APS.status            = 'OP'
  AND    APS.customer_id       =  p_customer_id
  AND    APS.class             = 'INV'
  AND    APS.cons_inv_id       IS NOT NULL
  )
GROUP BY cons_inv_id;

  -- -------------------------------------------
  --
  -- -------------------------------------------
  CURSOR lcu_get_cons_trx (p_cons_inv_id  IN  NUMBER)
  IS
-- Added for the Defect #3984
  SELECT APS.acctd_amount_due_remaining    amount_due_remaining
        ,APS.cons_inv_id
        ,APS.trx_number
        ,APS.trx_date
  FROM   XX_AR_LOCKBOX_INTERIM  APS
  WHERE  APS.status            = 'OP'
  AND    APS.class             = 'CM'
  AND    APS.cons_inv_id       = p_cons_inv_id
  UNION ALL
  SELECT CASE WHEN (p_deposit_date <= APS.due_date) THEN
                                 ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(APS.term_id
                                                                                                                              
            ,APS.trx_date
                                                                                                                              
            ,p_deposit_date
                                                                                                                              
            )
                                                      )
                               ,gn_cur_precision
                                )
                      ELSE APS.acctd_amount_due_remaining
                      END amount_due_remaining
        ,APS.cons_inv_id
        ,APS.trx_number
        ,APS.trx_date
  FROM   XX_AR_LOCKBOX_INTERIM  APS
  WHERE  APS.status            = 'OP'
  AND    APS.class             = 'INV'
  AND    APS.cons_inv_id       = p_cons_inv_id;
/*
  SELECT ROUND((APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(p_term_id,(p_deposit_date - APS.trx_date)))),gn_cur_precision) 
amount_due_remaining
        ,APS.cons_inv_id
        ,APS.trx_number
        ,APS.trx_date
  FROM   ar_payment_schedules  APS
  WHERE  APS.status            = 'OP'
  AND    APS.customer_id       =  p_customer_id
  AND    APS.class             IN ('INV','CM')
  AND    APS.cons_inv_id       = p_cons_inv_id;
*/  --Commented for the Defect #3984
  -- -------------------------------------------
  -- Local Variable Declarations
  -- -------------------------------------------
  get_cons_trx                  lcu_get_cons_trx%ROWTYPE;
  get_sum_cons_amt              lcu_get_sum_cons_amt%ROWTYPE;
  lr_record                     xx_ar_payments_interface%ROWTYPE;

  lc_error_location             VARCHAR2(32000);
  lc_error_details              VARCHAR2(32000);
  lc_errmsg                     VARCHAR2(32000);
  lc_cons_match                 VARCHAR2(1);

  ln_retcode                    NUMBER;
  ln_amount_due_remaining       NUMBER;
  ln_cons_inv_id                NUMBER;
  ln_cons_count                 NUMBER :=0;
  ln_overflow_sequence          NUMBER :=0;
  ln_loop_counter               NUMBER :=0;

  EX_CONS_EXCEPTION             EXCEPTION;

BEGIN

  lc_cons_match       :=  NULL;
  ln_cons_inv_id      :=  NULL;
  -- -------------------------------------------
  -- Loop through all the records of Consolidated
  -- -------------------------------------------
  lc_error_location := 'Calling the Consolidated Bill Rule ';

  OPEN lcu_get_sum_cons_amt;
  LOOP
  FETCH lcu_get_sum_cons_amt INTO get_sum_cons_amt;
  EXIT WHEN lcu_get_sum_cons_amt%NOTFOUND;

    IF get_sum_cons_amt.amount_due_remaining = p_record.remittance_amount THEN
      lc_cons_match            := 'Y';
      ln_cons_count            := ln_cons_count + 1;
      ln_amount_due_remaining  := get_sum_cons_amt.amount_due_remaining;
      ln_cons_inv_id           := get_sum_cons_amt.cons_inv_id;

    END IF;
  END LOOP;

    IF ln_cons_count =  1 THEN

      -- Call Delete Procedure
      lc_error_location :=  'Calling the delete procedure for consolidated bill rule';
      delete_lckb_rec
      ( x_errmsg         =>  lc_errmsg
       ,x_retstatus      =>  ln_retcode
       ,p_process_num    =>  p_process_num
       ,p_record_type    =>  '6'
       ,p_rowid          =>  p_rowid
       ,p_customer_id    =>  p_customer_id
       ,p_record         =>  p_record
      );
      IF ln_retcode  = gn_error THEN
        lc_error_details := lc_error_location||':'|| lc_errmsg;
        RAISE EX_CONS_EXCEPTION;
      END IF;


      OPEN  lcu_get_cons_trx (p_cons_inv_id  => ln_cons_inv_id );
      LOOP
      FETCH lcu_get_cons_trx  INTO get_cons_trx;
      EXIT WHEN lcu_get_cons_trx%NOTFOUND;

        -- -------------------------------------------
    -- Call the Create Record Procedure to create record type '4'
    -- into xx_ar_payments_interface table for matching bucket
    -- -------------------------------------------
    -- Assigning the value into record columns
    --
        -- Incrementing Counter in the loop
        ln_loop_counter      := ln_loop_counter + 1;
        ln_overflow_sequence := ln_overflow_sequence + 1;

    lr_record.status                := 'AR_PLB_NEW_RECORD';
    lr_record.record_type           := '4';
    lr_record.batch_name            := p_record.batch_name;
    lr_record.item_number           := p_record.item_number;
    lr_record.invoice1              := get_cons_trx.trx_number;
    lr_record.amount_applied1       := get_cons_trx.amount_due_remaining;
    lr_record.trx_date              := get_cons_trx.trx_date;
    lr_record.process_num           := p_process_num;
    --lr_record.inv_match_status      := 'CONSOLIDATED_MATCH';
    lr_record.customer_id           := p_customer_id;
    lr_record.auto_cash_status      := 'CONSOLIDATED_MATCH';
    lr_record.overflow_sequence     := ln_overflow_sequence;
    /*
    IF ln_loop_counter = 1 THEN
      lr_record.overflow_indicator  := '9';
    ELSIF ln_loop_counter <> 1 THEN
      lr_record.overflow_indicator  := '0';
    END IF;
    */
    lr_record.overflow_indicator  := '0';
    -- -------------------------------------------
    -- Calling the Create Interface record procedure
    -- -------------------------------------------
    -- Call Create Procedure
    create_interface_record ( x_errmsg      =>  lc_errmsg
                             ,x_retstatus   =>  ln_retcode
                             ,p_record      =>  lr_record
                            );

    IF ln_retcode  = gn_error THEN
      lc_error_details := lc_error_location||':'|| lc_errmsg;
      RAISE EX_CONS_EXCEPTION;
    END IF;

    END LOOP;
    CLOSE lcu_get_cons_trx;

        UPDATE xx_ar_payments_interface XAPI
        SET    XAPI.overflow_indicator = '9'
        WHERE  XAPI.record_type        = '4'
        AND    XAPI.process_num        = p_process_num
        --AND    XAPI.auto_cash_request  = gn_request_id
        AND    XAPI.overflow_sequence  = ln_loop_counter
        AND    XAPI.batch_name         = p_record.batch_name
        AND    XAPI.item_number        = p_record.item_number
        AND    p_customer_id           =
             (SELECT XAPI1.customer_id
              FROM   xx_ar_payments_interface XAPI1
              WHERE  XAPI1.rowid        = p_rowid
              AND    XAPI1.record_type  = '6'
              AND    XAPI1.batch_name   = p_record.batch_name
              AND    XAPI1.item_number  = p_record.item_number);

    END IF;
  CLOSE lcu_get_sum_cons_amt;

  -- -------------------------------------------
  -- Calling the Update Interface record procedure
  -- -------------------------------------------
  IF lc_cons_match = 'Y' THEN
    -- Call Update Procedure
    update_lckb_rec
    ( x_errmsg                    => lc_errmsg
     ,x_retstatus                 => ln_retcode
     ,p_process_num               => p_process_num
     ,p_record_type               => '6'
     ,p_inv_match_status          => 'CONSOLIDATED_MATCH'
     ,p_rowid                     => p_rowid
    );

    IF ln_retcode  = gn_error THEN
      lc_error_details := lc_error_location||':'|| lc_errmsg;
      RAISE EX_CONS_EXCEPTION;
    END IF;
  END IF;
EXCEPTION
WHEN EX_CONS_EXCEPTION THEN
  x_errmsg     := lc_error_details;
  x_retstatus  := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.consolidated_bill_rule');
  fnd_message.set_token('PROGRAM','AR Lockbox Consolidated Bill Rule Procedure');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg     := fnd_message.get;
  x_retstatus  := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
END consolidated_bill_rule;


-- +=================================================================================+
-- | Name        : PURCHASE_ORDER_RULE                                               |
-- | Description : This procedure will apply Purchase Order Rule for all the '6'     |
-- |               record type records after not qualify exact match, clear account  |
-- |               match and partial invoice match process                           |
-- |                                                                                 |
-- | Parameters  : p_record                                                          |
-- |               p_term_id                                                         |
-- |               p_customer_id                                                     |
-- |               p_deposit_date                                                    |
-- |               p_rowid                                                           |
-- |               p_process_num                                                     |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE purchase_order_rule
(x_errmsg             OUT   NOCOPY  VARCHAR2
,x_retstatus          OUT   NOCOPY  NUMBER
,p_record             IN            xx_ar_payments_interface%ROWTYPE
,p_term_id            IN            NUMBER
,p_customer_id        IN            NUMBER
,p_deposit_date       IN            DATE
,p_rowid              IN            VARCHAR2
,p_process_num        IN            VARCHAR2
)
IS

  -- -------------------------------------------
  -- Sum of all amount for a specific purchase order
  -- -------------------------------------------
  CURSOR lcu_get_sum_po_amt
  IS
-- Added for the Defect #3984
      SELECT SUM(amount_due_remaining) amount_due_remaining
            ,purchase_order            purchase_order
      FROM
        (SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */ APS.acctd_amount_due_remaining            amount_due_remaining
               ,RCT.purchase_order
         FROM   XX_AR_LOCKBOX_INTERIM  APS
               ,ra_customer_trx       RCT
         WHERE  APS.customer_trx_id   = RCT.customer_trx_id
         AND    APS.status            = 'OP'
         AND    APS.customer_id = p_customer_id  --Added for the Defect #4005
         AND    APS.class             = 'CM'
         AND    RCT.purchase_order    IS NOT NULL
         AND    RCT.printing_original_date IS NOT NULL     -- Added for Defect # 3913
        UNION ALL
        SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */ CASE WHEN (p_deposit_date <= APS.due_date) THEN
                                 ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(APS.term_id
                                                                                                                              
            ,APS.trx_date
                                                                                                                              
            ,p_deposit_date
                                                                                                                              
            )
                                                      )
                               ,gn_cur_precision
                                )
                      ELSE APS.acctd_amount_due_remaining
                      END amount_due_remaining
               ,RCT.purchase_order
         FROM   XX_AR_LOCKBOX_INTERIM  APS
               ,ra_customer_trx       RCT
         WHERE  APS.customer_trx_id   = RCT.customer_trx_id
         AND    APS.status            = 'OP'
         AND    APS.customer_id = p_customer_id  --Added for the Defect #4005
         AND    APS.class             = 'INV'
         AND    RCT.purchase_order    IS NOT NULL
         AND    RCT.printing_original_date IS NOT NULL     -- Added for Defect # 3913
        )
        GROUP BY purchase_order;
/*
  SELECT SUM(ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(p_term_id,(p_deposit_date - APS.trx_date))),gn_cur_precision)) 
amount_due_remaining
        ,RCT.purchase_order
  FROM   ar_payment_schedules  APS
        ,ra_customer_trx       RCT
  WHERE  APS.customer_trx_id   = RCT.customer_trx_id
  AND    APS.status            = 'OP'
--  AND    APS.customer_id       =  p_customer_id  --Commented for the Defect #4005
  AND    RCT.bill_to_customer_id = p_customer_id  --Added for the Defect #4005
  AND    APS.class             IN ('INV','CM')
  AND    RCT.purchase_order    IS NOT NULL
--  AND    RCT.printing_pending = 'N'   --Commented for Defect # 3913
  AND    RCT.printing_original_date IS NOT NULL     -- Added for Defect # 3913
  GROUP BY RCT.purchase_order;
*/  --Commented for the Defect #3984
  -- -------------------------------------------
  -- Get transaction details for purchase order
  -- -------------------------------------------
  CURSOR lcu_get_po_trx (p_purchase_order  IN  VARCHAR2)
  IS
         SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */ APS.acctd_amount_due_remaining    amount_due_remaining
               ,RCT.purchase_order
               ,APS.trx_number
               ,APS.trx_date
         FROM   XX_AR_LOCKBOX_INTERIM  APS
               ,ra_customer_trx       RCT
         WHERE  APS.customer_trx_id   = RCT.customer_trx_id
         AND    APS.status            = 'OP'
         AND    APS.customer_id = p_customer_id  --Added for the Defect #4005
         AND    APS.class             = 'CM'
         AND    RCT.printing_original_date IS NOT NULL     -- Added for Defect # 3913
         AND    RCT.purchase_order    = p_purchase_order
         UNION ALL
         SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */
               ROUND((APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(APS.term_id
                                                                                                                              
       ,APS.trx_date
                                                                                                                              
       ,p_deposit_date
                                                                                                                              
        )
                                                 )
                )
               ,gn_cur_precision
               )                      amount_due_remaining
               ,RCT.purchase_order
               ,APS.trx_number
               ,APS.trx_date
         FROM   XX_AR_LOCKBOX_INTERIM  APS
               ,ra_customer_trx       RCT
         WHERE  APS.customer_trx_id   = RCT.customer_trx_id
         AND    APS.status            = 'OP'
         AND    APS.customer_id = p_customer_id  --Added for the Defect #4005
         AND    APS.class             = 'INV'
         AND    RCT.printing_original_date IS NOT NULL     -- Added for Defect # 3913
         AND    RCT.purchase_order    = p_purchase_order;
/*
  SELECT ROUND((APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(p_term_id,(p_deposit_date - APS.trx_date)))),gn_cur_precision) 
amount_due_remaining
        ,RCT.purchase_order
        ,APS.trx_number
        ,APS.trx_date
  FROM   ar_payment_schedules  APS
        ,ra_customer_trx       RCT
  WHERE  APS.customer_trx_id   = RCT.customer_trx_id
  AND    APS.status            = 'OP'
--  AND    APS.customer_id       =  p_customer_id  --Commented for the Defect #4005
  AND    RCT.bill_to_customer_id = p_customer_id  --Added for the Defect #4005
  AND    APS.class             IN ('INV','CM')
--  AND    RCT.printing_pending = 'N'   --Commented for Defect # 3913
  AND    RCT.printing_original_date IS NOT NULL     -- Added for Defect # 3913
  AND    RCT.purchase_order    = p_purchase_order;
*/  --Commented for the Defect #3984
  -- -------------------------------------------
  -- Local Variable Declarations
  -- -------------------------------------------
  get_po_trx                    lcu_get_po_trx%ROWTYPE;
  get_sum_po_amt                lcu_get_sum_po_amt%ROWTYPE;
  lr_record                     xx_ar_payments_interface%ROWTYPE;

  lc_error_location             VARCHAR2(32000);
  lc_error_details              VARCHAR2(32000);
  lc_errmsg                     VARCHAR2(32000);
  lc_po_match                   VARCHAR2(1);

  ln_retcode                    NUMBER;
  ln_amount_due_remaining       NUMBER;
  ln_purchase_order             VARCHAR2(50);
  ln_po_count                   NUMBER :=0;
  ln_overflow_sequence          NUMBER :=0;
  ln_loop_counter               NUMBER :=0;

  EX_PO_EXCEPTION               EXCEPTION;

BEGIN

  lc_po_match                :=  NULL;
  ln_purchase_order          :=  NULL;
  -- -------------------------------------------
  -- Loop through all the records of PO
  -- -------------------------------------------
  lc_error_location := 'Calling the Purchase Order Rule ';

  OPEN lcu_get_sum_po_amt;
  LOOP
  FETCH lcu_get_sum_po_amt INTO get_sum_po_amt;
  EXIT WHEN lcu_get_sum_po_amt%NOTFOUND;

    IF get_sum_po_amt.amount_due_remaining = p_record.remittance_amount THEN
      lc_po_match              := 'Y';
      ln_po_count              := ln_po_count + 1;
      ln_amount_due_remaining  := get_sum_po_amt.amount_due_remaining;
      ln_purchase_order        := get_sum_po_amt.purchase_order;
    END IF;
  END LOOP;

    IF ln_po_count =  1 THEN

      -- Call Delete Procedure
      lc_error_location :=  'Calling the delete procedure for purchase order rule';
      delete_lckb_rec
      ( x_errmsg         =>  lc_errmsg
       ,x_retstatus      =>  ln_retcode
       ,p_process_num    =>  p_process_num
       ,p_record_type    =>  '6'
       ,p_rowid          =>  p_rowid
       ,p_customer_id    =>  p_customer_id
       ,p_record         =>  p_record
      );
      IF ln_retcode  = gn_error THEN
        lc_error_details := lc_error_location||':'|| lc_errmsg;
        RAISE EX_PO_EXCEPTION;
      END IF;

      OPEN  lcu_get_po_trx (p_purchase_order  => ln_purchase_order );
      LOOP
      FETCH lcu_get_po_trx  INTO get_po_trx;
      EXIT WHEN lcu_get_po_trx%NOTFOUND;

        -- -------------------------------------------
    -- Call the Create Record Procedure to create record type '4'
    -- into xx_ar_payments_interface table for matching bucket
    -- -------------------------------------------
    -- Assigning the value into record columns
    --
        -- Incrementing Counter in the loop
        ln_loop_counter      := ln_loop_counter + 1;
        ln_overflow_sequence := ln_overflow_sequence + 1;

    lr_record.status                := 'AR_PLB_NEW_RECORD';
    lr_record.record_type           := '4';
    lr_record.batch_name            := p_record.batch_name;
    lr_record.item_number           := p_record.item_number;
    lr_record.invoice1              := get_po_trx.trx_number;
    lr_record.amount_applied1       := get_po_trx.amount_due_remaining;
    lr_record.trx_date              := get_po_trx.trx_date;
    lr_record.process_num           := p_process_num;
    --lr_record.inv_match_status      := 'PURCHASE_ORDER_MATCH';
    lr_record.customer_id           := p_customer_id;
    lr_record.auto_cash_status      := 'PURCHASE_ORDER_MATCH';
    lr_record.overflow_sequence     := ln_overflow_sequence;
    /*
    IF ln_loop_counter = 1 THEN
      lr_record.overflow_indicator  := '9';
    ELSIF ln_loop_counter <> 1 THEN
      lr_record.overflow_indicator  := '0';
    END IF;
    */
    lr_record.overflow_indicator  := '0';
    -- -------------------------------------------
    -- Calling the Create Interface record procedure
    -- -------------------------------------------
    -- Call Create Procedure
    create_interface_record
    ( x_errmsg      =>  lc_errmsg
     ,x_retstatus   =>  ln_retcode
     ,p_record      =>  lr_record
    );

    IF ln_retcode  = gn_error THEN
      lc_error_details := lc_error_location||':'|| lc_errmsg;
      RAISE EX_PO_EXCEPTION;
        END IF;

      END LOOP;
      CLOSE lcu_get_po_trx;

        UPDATE xx_ar_payments_interface XAPI
        SET    XAPI.overflow_indicator = '9'
        WHERE  XAPI.record_type        = '4'
        AND    XAPI.process_num        = p_process_num
        --AND    XAPI.auto_cash_request  = gn_request_id
        AND    XAPI.overflow_sequence  = ln_loop_counter
        AND    XAPI.batch_name         = p_record.batch_name
        AND    XAPI.item_number        = p_record.item_number
        AND    p_customer_id           =
           (SELECT XAPI1.customer_id
            FROM   xx_ar_payments_interface XAPI1
            WHERE  XAPI1.rowid        = p_rowid
            AND    XAPI1.record_type  = '6'
            AND    XAPI1.batch_name   = p_record.batch_name
            AND    XAPI1.item_number  = p_record.item_number);

    END IF;
  CLOSE lcu_get_sum_po_amt;

  -- -------------------------------------------
  -- Calling the Update Interface record procedure
  -- -------------------------------------------
  IF lc_po_match = 'Y' THEN
    -- Call Update Procedure
    update_lckb_rec
    ( x_errmsg                    => lc_errmsg
     ,x_retstatus                 => ln_retcode
     ,p_process_num               => p_process_num
     ,p_record_type               => '6'
     ,p_inv_match_status          => 'PURCHASE_ORDER_MATCH'
     ,p_rowid                     => p_rowid
    );

    IF ln_retcode  = gn_error THEN
      lc_error_details := lc_error_location||':'|| lc_errmsg;
      RAISE EX_PO_EXCEPTION;
    END IF;
  END IF;
EXCEPTION
WHEN EX_PO_EXCEPTION THEN
  x_errmsg     := lc_error_details;
  x_retstatus  := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.purchase_order_rule');
  fnd_message.set_token('PROGRAM','AR Lockbox Purchase Order Rule Procedure');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg     := fnd_message.get;
  x_retstatus  := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
END purchase_order_rule;



-- +=================================================================================+
-- | Name        : AUTO_CASH_MATCH_RULES                                             |
-- | Description : This procedure will apply Date Range / Pulse Pay /                |
-- |               Any Combination Rules for all the '6' record type records         |
-- |               after not qualify exact match, clear account match,               |
-- |               and consolidated bill rule match partial invoice match process    |
-- |                                                                                 |
-- | Parameters  : p_record                                                          |
-- |               p_term_id                                                         |
-- |               p_customer_id                                                     |
-- |               p_deposit_date                                                    |
-- |               p_rowid                                                           |
-- |               p_process_num                                                     |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE auto_cash_match_rules
(x_errmsg             OUT   NOCOPY  VARCHAR2
,x_retstatus          OUT   NOCOPY  NUMBER
,p_record             IN            xx_ar_payments_interface%ROWTYPE
,p_term_id            IN            NUMBER
,p_customer_id        IN            NUMBER
,p_deposit_date       IN            DATE
,p_rowid              IN            VARCHAR2
,p_process_num        IN            VARCHAR2
,p_trx_type           IN            VARCHAR2  DEFAULT NULL
,p_trx_threshold      IN            NUMBER    DEFAULT NULL
,p_from_days          IN            NUMBER    DEFAULT NULL
,p_to_days            IN            NUMBER    DEFAULT NULL
)
IS

  -- -------------------------------------------
  -- Local Variable Declarations
  -- -------------------------------------------
  lc_error_location             VARCHAR2(32000);
  lc_error_details              VARCHAR2(32000);
  lc_errmsg                     VARCHAR2(32000);
  lc_date_range_match           VARCHAR2(1);
  lc_pulse_pay_match            VARCHAR2(1);
  lc_any_comb_match             VARCHAR2(1);

  ln_retcode                    NUMBER;

  EX_AUTOCASH_EXCEPTION         EXCEPTION;

BEGIN

  put_log_line('[BEGIN] AUTO_CASH_MATCH_RULES - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

  -- -------------------------------------------
  -- Initializing the Variables
  -- -------------------------------------------
  lc_date_range_match  :=  NULL;
  lc_pulse_pay_match   :=  NULL;
  lc_any_comb_match    :=  NULL;
  lc_error_details     :=  NULL;
  lc_error_location    :=  NULL;
  -- -------------------------------------------
  -- Call Date Range Rule Procedure
  -- -------------------------------------------
  lc_error_location := 'Calling the Date range Rule ';

  put_log_line('lr_record2' ||'-'||p_record.remittance_amount);

  put_log_line('[BEGIN] Date Range - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

  date_range_rule   ( x_errmsg              =>  lc_errmsg
                     ,x_retstatus           =>  ln_retcode
                     ,x_date_range_match    =>  lc_date_range_match
                     ,p_customer_id         =>  p_customer_id
                     ,p_match_type          =>  'DATE_RANGE'
                     ,p_record              =>  p_record
                     ,p_term_id             =>  p_term_id
                     ,p_deposit_date        =>  p_deposit_date
                     ,p_cur_precision       =>  gn_cur_precision
                     ,p_process_num         =>  p_process_num
                     ,p_rowid               =>  p_rowid
                     );

  put_log_line('[END] Date Range - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

  --fnd_file.put_line(fnd_file.output,'Date Range Match Flag:-'||lc_date_range_match);

  IF ln_retcode  = gn_error THEN
    lc_error_details := lc_error_location||':'|| lc_errmsg;
    RAISE EX_AUTOCASH_EXCEPTION;
  END IF;
  -- -------------------------------------------
  -- Check the record is match or not under
  -- date range rule
  -- -------------------------------------------
  IF lc_date_range_match IS NULL THEN
    -- -------------------------------------------
    -- Call the Pulse Pay Procedure
    -- -------------------------------------------
    lc_error_location := 'Calling the Pulse Pay Rule ';

    put_log_line('[BEGIN] Pulse Pay - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

    pulse_pay_rule    ( x_errmsg              =>  lc_errmsg
                       ,x_retstatus           =>  ln_retcode
                       ,x_pulse_pay_match     =>  lc_pulse_pay_match
                       ,p_customer_id         =>  p_customer_id
                       ,p_match_type          =>  'PULSE_PAY'
                       ,p_record              =>  p_record
                       ,p_term_id             =>  p_term_id
                       ,p_deposit_date        =>  p_deposit_date
                       ,p_cur_precision       =>  gn_cur_precision
                       ,p_process_num         =>  p_process_num
                       ,p_rowid               =>  p_rowid
                        );

    put_log_line('[END] Pulse Pay - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

    --fnd_file.put_line(fnd_file.output,'Pulse Pay Match Flag:-'||lc_pulse_pay_match);

    IF ln_retcode  = gn_error THEN
      lc_error_details := lc_error_location||':'|| lc_errmsg;
      RAISE EX_AUTOCASH_EXCEPTION;
    END IF;

    IF lc_pulse_pay_match = 'Y' THEN

      lc_error_location := 'Update the Status after pulse pay rule match';
      -- -------------------------------------------
      -- Update the Invoice Match Status for
      -- Record Type 6- Pulse Pay
      -- -------------------------------------------
      update_lckb_rec ( x_errmsg                    => lc_errmsg
                       ,x_retstatus                 => ln_retcode
                       ,p_process_num               => p_process_num
                       ,p_record_type               => '6'
                       ,p_inv_match_status          => 'PULSE_PAY_MATCH'
                       ,p_rowid                     => p_rowid
                      );

      IF ln_retcode  = gn_error THEN
        lc_error_details := lc_error_location||':'|| lc_errmsg;
        RAISE EX_AUTOCASH_EXCEPTION;
      END IF;

    END IF;


  ELSIF lc_date_range_match  = 'Y' THEN

    lc_error_location := 'Update the Status after date range match';
    -- -------------------------------------------
    -- Update the Invoice Match Status for
    -- Record Type 6- Pulse Pay
    -- -------------------------------------------
    update_lckb_rec ( x_errmsg                    => lc_errmsg
                     ,x_retstatus                 => ln_retcode
                     ,p_process_num               => p_process_num
                     ,p_record_type               => '6'
                     ,p_inv_match_status          => 'DATE_RANGE_MATCH'
                     ,p_rowid                     => p_rowid
                    );

    IF ln_retcode  = gn_error THEN
      lc_error_details := lc_error_location||':'|| lc_errmsg;
      RAISE EX_AUTOCASH_EXCEPTION;
    END IF;

  END IF;

-- Commented below any_combo procedure call for defect# 13069.
/*  -- -------------------------------------------
  -- Check Pulse Pay Match or Not
  -- If match then update the status
  -- else call the any combination procedure
  -- -------------------------------------------
  IF lc_pulse_pay_match IS NULL AND lc_date_range_match IS NULL THEN
    -- -------------------------------------------
    -- Call the Any Combination Procedure
    -- -------------------------------------------
    lc_error_location := 'Calling the Any Combination Rule ';

    put_log_line('[BEGIN] Any Combo - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

    any_combo         ( x_errmsg              =>  lc_errmsg
                       ,x_retstatus           =>  ln_retcode
                       ,x_any_combo_match     =>  lc_any_comb_match
                       ,p_customer_id         =>  p_customer_id
                       ,p_match_type          =>  'ANY_COMBINATION'
                       ,p_record              =>  p_record
                       ,p_process_num         =>  p_process_num
                       ,p_rowid               =>  p_rowid
                       ,p_max_trx             =>  p_trx_threshold
                       ,p_from_days           =>  p_from_days
                       ,p_to_days             =>  p_to_days
                       ,p_trx_class           =>  p_trx_type
                       ,p_term_id             =>  p_term_id
                       ,p_deposit_date        =>  p_deposit_date
                       ,p_cur_precision       =>  gn_cur_precision
                      );

    put_log_line('[END] Any Combo - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

    --fnd_file.put_line(fnd_file.output,'Any Combo Match Flag:-'||lc_any_comb_match);

    IF ln_retcode  = gn_error THEN
      lc_error_details := lc_error_location||':'|| lc_errmsg;
      RAISE EX_AUTOCASH_EXCEPTION;
    END IF;

    IF lc_any_comb_match ='Y' THEN

      lc_error_location := 'Update the Status after any combination match';
      -- -------------------------------------------
      -- Update the Invoice Match Status for
      -- Record Type 6- Pulse Pay
      -- -------------------------------------------
      update_lckb_rec ( x_errmsg                    => lc_errmsg
                       ,x_retstatus                 => ln_retcode
                       ,p_process_num               => p_process_num
                       ,p_record_type               => '6'
                       ,p_inv_match_status          => 'ANY_COMBINATION_MATCH'
                       ,p_rowid                     => p_rowid
                      );

      IF ln_retcode  = gn_error THEN
        lc_error_details := lc_error_location||':'|| lc_errmsg;
        RAISE EX_AUTOCASH_EXCEPTION;
      END IF;

    END IF;
  END IF;
  */
-- Commented code end for defect# 13069
  put_log_line('[END] AUTO_CASH_MATCH_RULES - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

EXCEPTION
WHEN EX_AUTOCASH_EXCEPTION THEN
  x_errmsg     := lc_error_details;
  x_retstatus  := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
WHEN OTHERS THEN
  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.auto_cash_match_rules');
  fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash Match Rules Procedure');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg     := fnd_message.get;
  x_retstatus  := gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
END auto_cash_match_rules;

-- +=================================================================================+
-- | Name        : Gen_Combinations                                                  |
-- | Description : This procedure will be used to populate the different             |
-- |               combination strings to be checked based on the total number of    |
-- |               invoices which is the based on the mathematical                   |
-- |               formula N choose R                                                |
-- | Parameters  : NONE                                                              |
-- | Returns     : NONE                                                              |
-- |                                                                                 |
-- +=================================================================================+

PROCEDURE Gen_Combinations
(
  p_total_invoices IN  NUMBER
 ,x_errmsg         OUT NOCOPY VARCHAR2
 ,x_retstatus      OUT NOCOPY NUMBER
) IS
 -- ===================
 -- Local Variables
 -- ===================
 gen_combo_error   EXCEPTION;
 x_any_combo_match VARCHAR2(10000) :=TO_CHAR(NULL);

-- ================================
-- Begin (Gen_Combinations)
-- ================================
BEGIN
 FOR n_choose_r IN 1 .. nvl(p_total_invoices ,15)
  LOOP
   FOR COMBI IN
    (
     SELECT combinations
     FROM (
           SELECT REPLACE (SYS_CONNECT_BY_PATH (n, '/'), '/') combinations
           FROM
            (
             SELECT CHR(ASCII ('A') + LEVEL - 1) n
             FROM DUAL
             CONNECT BY LEVEL <=nvl(p_total_invoices ,15)
            )
           CONNECT BY n > PRIOR n
          )
     WHERE LENGTH(combinations) =n_choose_r
    )
   LOOP
    BEGIN
     SAVEPOINT landmark;
     INSERT INTO xx_ar_anycombo_ncr_gtmp
      ( request_id,
        ncr_string )
     VALUES
      ( gn_ncr_request_id,
        combi.combinations );
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        put_log_line('==========================');
        put_log_line('Duplicate value at insert combinations. '||SQLERRM);
        ROLLBACK TO landmark;
      WHEN OTHERS THEN
        put_log_line('==========================');
        put_log_line('Others at insert combinations. '||SQLERRM);
        ROLLBACK TO landmark;
    END;
   END LOOP;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
   fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
   fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.Gen_Combinations');
   fnd_message.set_token('PROGRAM','AR Lockbox Custom Autocash');
   fnd_message.set_token('SQLERROR',SQLERRM);
   x_errmsg           :=fnd_message.get;
   x_retstatus        :=gn_error;
   x_any_combo_match  :=TO_CHAR(NULL);
   put_log_line('==========================');
   put_log_line(x_errmsg);
END Gen_Combinations;

-- +=================================================================================+
-- | Name        : CUSTOM_AUTO_CASH                                                  |
-- | Description : This procedure will be used to process the                        |
-- |               AR Lockbox Custom Auto Cash Rules                                 |
-- |                                                                                 |
-- | Parameters  : p_process_num                                                     |
-- |               p_check_digit                                                     |
-- |               p_trx_type                                                        |
-- |               p_trx_threshold                                                   |
-- |               p_from_days                                                       |
-- |               p_to_days                                                         |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE custom_auto_cash
(x_errmsg                 OUT   NOCOPY  VARCHAR2
,x_retstatus              OUT   NOCOPY  NUMBER
,p_process_num             IN            VARCHAR2
,p_check_digit             IN            NUMBER
,p_trx_type                IN            VARCHAR2  DEFAULT NULL
,p_trx_threshold           IN            NUMBER    DEFAULT NULL
,p_from_days               IN            NUMBER    DEFAULT NULL
,p_to_days                 IN            NUMBER    DEFAULT NULL
,p_back_order_configurable IN            NUMBER    -- Added for Defect #3983 on 26-JAN-10
)
IS

  -- -------------------------------------------
  -- Cursor for get all lockbox records for
  -- the same file for record type 6
  -- -------------------------------------------
  CURSOR lcu_get_lockbox_rec ( p_process_number  IN  VARCHAR2
                              ,p_record_type     IN  VARCHAR2)
  IS
  SELECT TRIM(XAPI.status)                status
        ,TRIM(XAPI.record_type)           record_type
        ,TRIM(XAPI.destination_account)   destination_account
        ,TRIM(XAPI.origination)           origination
        ,TRIM(XAPI.lockbox_number)        lockbox_number
        ,XAPI.deposit_date                deposit_date
        ,XAPI.deposit_time                deposit_time
        ,TRIM(XAPI.batch_name)            batch_name
        ,TRIM(XAPI.item_number)           item_number
        ,XAPI.remittance_amount
        ,TRIM(XAPI.transit_routing_number)transit_routing_number
        ,TRIM(XAPI.account)               account
        ,TRIM(XAPI.check_number)          check_number
        ,TRIM(XAPI.customer_number)       customer_number
        ,TRIM(XAPI.overflow_sequence)     overflow_sequence
        ,TRIM(XAPI.overflow_indicator)    overflow_indicator
        ,TRIM(XAPI.invoice1)              invoice1
        ,TRIM(XAPI.invoice2)              invoice2
        ,TRIM(XAPI.invoice3)              invoice3
        ,TRIM(XAPI.amount_applied1)       amount_applied1
        ,TRIM(XAPI.amount_applied2)       amount_applied2
        ,TRIM(XAPI.amount_applied3)       amount_applied3
        ,XAPI.batch_record_count
        ,XAPI.batch_amount
        ,XAPI.lockbox_record_count
        ,XAPI.lockbox_amount
        ,XAPI.transmission_record_count
        ,XAPI.transmission_amount
        ,TRIM(XAPI.record_status)         record_status
        ,TRIM(XAPI.process_num)           process_num
        ,TRIM(XAPI.file_name)             file_name
        ,XAPI.error_mesg
        ,XAPI.inv_match_status
        ,XAPI.process_date
        ,XAPI.error_flag
        ,Xapi.Rowid
         ,XAPI.sending_company_id           sending_company_id -- Added for CR#872
  FROM   xx_ar_payments_interface    XAPI
  WHERE  XAPI.process_num        =  TRIM(p_process_number)
  AND    XAPI.record_type        =  TRIM(p_record_type);

  -- -------------------------------------------
  -- Cursor for get all lockbox records for
  -- the same file for record type 4
  -- and corresponding batch and item number of
  -- record type 6
  -- -------------------------------------------
  CURSOR lcu_get_lockbox_det_rec
  ( p_process_number  IN  VARCHAR2
    ,p_record_type     IN  VARCHAR2
    ,p_batch_name      IN  VARCHAR2
    ,p_item_number     IN  NUMBER)
  IS
  SELECT TRIM(XAPI.status)                status
        ,TRIM(XAPI.record_type)           record_type
        ,TRIM(XAPI.destination_account)   destination_account
        ,TRIM(XAPI.origination)           origination
        ,TRIM(XAPI.lockbox_number)        lockbox_number
        ,XAPI.deposit_date                deposit_date
        ,XAPI.deposit_time                deposit_time
        ,TRIM(XAPI.batch_name)            batch_name
        ,TRIM(XAPI.item_number)           item_number
        ,XAPI.remittance_amount
        ,TRIM(XAPI.transit_routing_number)transit_routing_number
        ,TRIM(XAPI.account)               account
        ,TRIM(XAPI.check_number)          check_number
        ,TRIM(XAPI.customer_number)       customer_number
        ,TRIM(XAPI.overflow_sequence)     overflow_sequence
        ,TRIM(XAPI.overflow_indicator)    overflow_indicator
        ,TRIM(XAPI.invoice1)              invoice1
        ,TRIM(XAPI.invoice2)              invoice2
        ,TRIM(XAPI.invoice3)              invoice3
        ,TRIM(XAPI.amount_applied1)       amount_applied1
        ,TRIM(XAPI.amount_applied2)       amount_applied2
        ,TRIm(XAPI.amount_applied3)       amount_applied3
        ,XAPI.batch_record_count
        ,XAPI.batch_amount
        ,XAPI.lockbox_record_count
        ,XAPI.lockbox_amount
        ,XAPI.transmission_record_count
        ,XAPI.transmission_amount
        ,TRIM(XAPI.record_status)         record_status
        ,TRIM(XAPI.process_num)           process_num
        ,TRIM(XAPI.file_name)             file_name
        ,XAPI.error_mesg
        ,XAPI.inv_match_status
        ,XAPI.process_date
        ,XAPI.error_flag
        ,XAPI.ROWID
  FROM   xx_ar_payments_interface    XAPI
  WHERE  XAPI.process_num        =  TRIM(p_process_number)
  AND    XAPI.record_type        =  TRIM(p_record_type)
  AND    XAPI.batch_name         =  TRIM(p_batch_name)
  AND    XAPI.item_number        =  TRIM(p_item_number);

  -- -------------------------------------------
  -- Cursor for validate the customer number
  -- -------------------------------------------
  CURSOR lcu_valid_customer ( p_customer_num  IN hz_cust_accounts_all.account_number%TYPE)
  IS
  SELECT HCA.cust_account_id
        ,HCA.account_number
        ,HCA.party_id --Added for CR#684 --Defect #976
  FROM   hz_cust_accounts  HCA
  WHERE  orig_system_reference = p_customer_num ||'-00001-A0' ;
-- Defect 955 Modified based on Ray's confirmation. orig_system_reference like p_customer_num || '%' ;
--  WHERE  substr(orig_system_reference,1,8) = p_customer_num
--  AND    HCA.status         = 'A';                           -- Commented for Defect 14630

  -- -------------------------------------------
  -- Cursor for validate the customer number
  -- -------------------------------------------
  CURSOR lcu_get_cust_match_profile (p_cust_account_id  IN hz_cust_accounts.cust_account_id%TYPE)
  IS
  SELECT HCP.lockbox_matching_option
        ,HCP.standard_terms
        ,HCP.cons_inv_flag
  FROM   hz_customer_profiles    HCP
  WHERE  HCP.cust_account_id   =  p_cust_account_id
  AND    HCP.site_use_id       IS NULL  -- Added on 07-Oct-07 11.48Am by Sunayan
  AND    HCP.status            = 'A';

  -- -------------------------------------------
  -- Check the Invoice is exist or not in
  -- Oracle for Same Customer and Same amount
  -- and transaction number
  -- -------------------------------------------
-- // Added for Defect # 4064 on 02/10/10
  --Start for Defect # 4064

  CURSOR lcu_get_trx_number  ( p_trx_number   IN VARCHAR2
                              )
  IS
  SELECT APS.trx_number
        ,APS.trx_date
        ,APS.acctd_amount_due_remaining
        ,RACT.bill_to_customer_id
        ,APS.due_date
        ,APS.term_id
  FROM   ar_payment_schedules  APS
        ,ra_customer_trx ract
  WHERE  APS.class                      IN ('INV','CM')
  AND    RACT.bill_to_customer_id IN (SELECT column_value
                                        FROM TABLE(
                                                   CAST(lt_related_custid_type AS XX_AR_CUSTID_TAB_T)
                                                   )
                                      )
  AND    RACT.trx_number      = p_trx_number
  AND    RACT.customer_trx_id = APS.customer_trx_id
  AND    ract.bill_to_customer_id = aps.customer_id
--  AND    ract.printing_original_date IS NOT NULL   -- Commeneted for Defect # 3983
  ;


-- // Added for Defect # 4064 on 02/11/10  - 1.29 - P.Sankaran
  --Start for Defect # 4064

  CURSOR lcu_get_trx_number_bo  ( p_trx_number   IN VARCHAR2
                              )
  IS
  SELECT APS.trx_number
        ,APS.trx_date
        ,APS.acctd_amount_due_remaining
        ,RACT.bill_to_customer_id
        ,APS.due_date
        ,APS.term_id
  FROM   XX_AR_LOCKBOX_INTERIM  APS
        ,ra_customer_trx ract
  WHERE  APS.class                      IN ('INV','CM')
  AND    APS.status                     = 'OP'
  AND    RACT.bill_to_customer_id IN (SELECT column_value
                                        FROM TABLE(
                                                   CAST(lt_related_custid_type AS XX_AR_CUSTID_TAB_T)
                                                   )
                                      )
  AND    RACT.trx_number      = p_trx_number
  AND    RACT.customer_trx_id = APS.customer_trx_id
  AND    ract.bill_to_customer_id = aps.customer_id
  AND    ract.printing_original_date IS NOT NULL
  AND    APS.acctd_amount_due_remaining <> 0;

-- Hint Index added by Gaurav Agarwal for performance defect # 11818
  CURSOR lcu_get_trx_number_all
  IS
--  SELECT /*+ index (APS AR_PAYMENT_SCHEDULES_N2) */    REMOVED HINT - Prakash Sankaran
    SELECT     APS.trx_number                     trx_number
        ,APS.trx_date                       trx_date
        ,APS.acctd_amount_due_remaining     acctd_amount_due_remaining
        ,RACT.bill_to_customer_id           bill_to_customer_id
        ,APS.due_date                       due_date
        ,APS.term_id                        term_id
        ,'N'                                processed_flag  --Added for the Defect #2033
  FROM   XX_AR_LOCKBOX_INTERIM  APS
        ,ra_customer_trx ract
  WHERE  APS.class                      IN ('INV','CM')
  AND    APS.status                     = 'OP'
  AND    APS.customer_id IN (SELECT column_value
                                        FROM TABLE(
                                                   CAST(lt_related_custid_type AS XX_AR_CUSTID_TAB_T)
                                                   )
                                      )
AND    RACT.customer_trx_id = APS.customer_trx_id
--AND    ract.bill_to_customer_id = aps.customer_id
AND    ract.printing_original_date IS NOT NULL
AND    APS.acctd_amount_due_remaining <> 0;

  --END for Defect # 4064

  -- Start Added for Defect# 4720
CURSOR lcu_get_trx_number_tdc ( p_trx_number   IN VARCHAR2
                              )
  IS
  SELECT APS.trx_number
        ,APS.trx_date
        ,APS.acctd_amount_due_remaining
        ,RACT.bill_to_customer_id
        ,APS.due_date
        ,APS.term_id
  FROM   ar_payment_schedules  APS
        ,ra_customer_trx RACT
  WHERE  APS.class IN ('INV','CM')
  AND    RACT.trx_number      = p_trx_number
  AND    RACT.customer_trx_id = APS.customer_trx_id
  AND    RACT.bill_to_customer_id = APS.customer_id
  --AND    APS.acctd_amount_due_remaining <> 0 -- Commented on 19-APR-10
  ;

  --END Added for Defect# 4720

 -- // Commented for Defect # 4064 on 02/10/10

/*  CURSOR lcu_get_trx_number  ( p_trx_number   IN VARCHAR2
                              --,p_customer_id  IN NUMBER  --Commented for CR#684 --Defect #976
                              )
  IS
 -- Added for Defect # 4064
SELECT   APS.trx_number
        ,APS.trx_date
        ,APS.acctd_amount_due_remaining
        ,RACT.bill_to_customer_id
        ,APS.due_date
        ,APS.term_id
  FROM   ar_payment_schedules  APS
        ,ra_customer_trx ract
  WHERE  APS.class                      IN ('INV','CM')
  AND    APS.status                     = 'OP'
  AND    RACT.bill_to_customer_id IN (SELECT column_value
                                        FROM TABLE(
                                                   CAST(lt_related_custid_type AS XX_AR_CUSTID_TAB_T)
                                                   )
                                      )
AND    p_trx_number is null
AND    RACT.customer_trx_id = APS.customer_trx_id
AND    ract.bill_to_customer_id = aps.customer_id
AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
AND    APS.acctd_amount_due_remaining <> 0
UNION ALL
  SELECT APS.trx_number
        ,APS.trx_date
        ,APS.acctd_amount_due_remaining
        ,RACT.bill_to_customer_id
        ,APS.due_date
        ,APS.term_id
  FROM   ar_payment_schedules  APS
        ,ra_customer_trx ract
  WHERE  APS.class                      IN ('INV','CM')
  AND    APS.status                     = 'OP'
  AND    RACT.bill_to_customer_id IN (SELECT column_value
                                        FROM TABLE(
                                                   CAST(lt_related_custid_type AS XX_AR_CUSTID_TAB_T)
                                                   )
                                      )
  AND    RACT.trx_number      = p_trx_number
  AND    RACT.customer_trx_id = APS.customer_trx_id
  AND    ract.bill_to_customer_id = aps.customer_id
  AND    ract.printing_original_date IS NOT NULL
  AND    APS.acctd_amount_due_remaining <> 0;
*/
  -- // Commented for Defect # 4064

 --SELECT /*+ NO_EXPAND INDEX(RACT RA_CUSTOMER_TRX_N11) */   --Added on 26-NOV-09 for Defect #976
 /*        APS.trx_number
        ,APS.trx_date
        ,APS.acctd_amount_due_remaining
        ,RACT.bill_to_customer_id       --Added for CR #684 --Defect #976
        ,APS.due_date                   --Added for Defect #3984
        ,APS.term_id                    --Added for Defect #3984
  FROM   ar_payment_schedules  APS
        ,ra_customer_trx ract
  WHERE  APS.class                      IN ('INV','CM')
  AND    APS.status                     = 'OP'
 -- AND    APS.customer_id                = p_customer_id --Commented for CR#684 --Defect #976
--  AND    APS.customer_id IN (SELECT column_value   --Commented for Defect #976 on 22-DEC-09
  AND    RACT.bill_to_customer_id IN (SELECT column_value --Added for Defect #976 on 22-DEC-09
                                        FROM TABLE(
                                                   CAST(lt_related_custid_type AS XX_AR_CUSTID_TAB_T)
                                                   )
                                      )                             --Added for CR #684 --Defect #976
  --AND    APS.trx_number  = NVL(p_trx_number,APS.trx_number) --Commented for Defect #976 on 22-DEC-09
--  AND    ract.trx_number = aps.trx_number                   --Commented for Defect #976 on 22-DEC-09
  AND    RACT.trx_number      = NVL(p_trx_number,RACT.trx_number)  --Added for Defect #976 on 22-DEC-09
  AND    RACT.customer_trx_id = APS.customer_trx_id                --Added for Defect #976 on 22-DEC-09
  AND    ract.bill_to_customer_id = aps.customer_id
--  AND    ract.printing_pending = 'N'   --Commented for Defect # 3913
  AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
  AND    APS.acctd_amount_due_remaining <> 0;*/

  -- -------------------------------------------
  -- Check the Invoice is exist or not in
  -- Oracle for Same Customer and Same amount
  -- and Cons Billing Number
  -- -------------------------------------------
  CURSOR lcu_get_cons_bill_num ( p_trx_number   IN VARCHAR2
                                ,p_customer_id  IN NUMBER)
  IS
  SELECT ACI.cons_billing_number
        ,APS.trx_date
        ,APS.acctd_amount_due_remaining
  FROM   XX_AR_LOCKBOX_INTERIM  APS
        ,ar_cons_inv           ACI
  WHERE  APS.status                     = 'OP'
  AND    APS.cons_inv_id                =  ACI.cons_inv_id
  AND    ACI.customer_id                =  p_customer_id
  AND    ACI.cons_billing_number        =  NVL(p_trx_number,ACI.cons_billing_number)
  AND    APS.acctd_amount_due_remaining <>  0;

  -- -------------------------------------------
  -- Get the Deposit Date for the same Batch
  -- Same customer for the record type 7
  -- -------------------------------------------
  CURSOR lcu_get_bai_deposit_dt ( p_batch_name     IN VARCHAR2
                                 ,p_process_number IN VARCHAR2)
  IS
  SELECT XAPI.deposit_date           deposit_date
        ,TRIM(XAPI.batch_name)       batch_name
  FROM   xx_ar_payments_interface  XAPI
  WHERE  XAPI.record_type      =  '7'
  AND    XAPI.batch_name       = p_batch_name
  AND    XAPI.process_num      = p_process_number;

  -- -------------------------------------------
  -- Cursor to Get the Currency and Precision
  -- -------------------------------------------
  CURSOR luc_currency_per
  IS
  SELECT FCUR.precision
  FROM   fnd_currencies          FCUR
        ,gl_sets_of_books        GSB
  WHERE  FCUR.currency_code                     = GSB.currency_code
  AND    GSB.set_of_books_id                    = gn_set_of_bks_id
  AND    FCUR.enabled_flag                      = 'Y'
  AND    NVL(FCUR.end_date_active, SYSDATE + 1) > SYSDATE;

  -- -------------------------------------------
  -- This cursor is used for to identify
  -- whether the reoc is applicable for
  -- which process like the record is for
  -- partial invoice match or custom autocash
  -- rule process
  -- -------------------------------------------
  CURSOR lcu_count_autocash_proc ( p_process_num  IN  xx_ar_payments_interface.process_num%TYPE
                                  ,p_batch_name   IN  xx_ar_payments_interface.batch_name%TYPE
                                  ,p_item_number  IN  xx_ar_payments_interface.item_number%TYPE )
  IS
  SELECT COUNT(XAPI.record_type)
  FROM   xx_ar_payments_interface    XAPI
  WHERE  XAPI.process_num        =   p_process_num
  AND    XAPI.batch_name         =   p_batch_name
  AND    XAPI.item_number        =   p_item_number
  AND    XAPI.record_type        =  '6'
  AND    NOT EXISTS (SELECT XAPI1.process_num
                     FROM   xx_ar_payments_interface XAPI1
                     WHERE  XAPI1.process_num = XAPI.process_num
                     AND    XAPI1.record_type   = '4'
                     AND    XAPI1.batch_name    = XAPI.batch_name
                     AND    XAPI1.item_number   = XAPI.item_number);

  -- -------------------------------------------
  -- Cursor for Sum all the open invoice for the
  -- individual customer and match with remittance amt
  -- -------------------------------------------
  CURSOR lcu_get_sum_amt_due_remaining ( p_customer     IN  hz_cust_accounts_all.cust_account_id%TYPE
                                        ,p_term_id      IN  NUMBER
                                        ,p_deposit_date IN  DATE)
  IS
-- Added for Defect #3984
             SELECT  /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */ SUM(amount_due_remaining) FROM
                     (SELECT CASE WHEN (p_deposit_date <= APS.due_date) THEN
                                 ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(APS.term_id
                                                                                                                              
            ,APS.trx_date
                                                                                                                              
            ,p_deposit_date
                                                                                                                              
            )
                                                      )
                               ,gn_cur_precision
                                )
                      ELSE APS.acctd_amount_due_remaining
                      END amount_due_remaining
                     ,ract.bill_to_customer_id customer_id
           FROM   XX_AR_LOCKBOX_INTERIM  APS
                 ,ra_customer_trx ract
           WHERE  APS.customer_id = p_customer  --Added for the Defect #4005
           AND    APS.status       = 'OP'
           AND    ract.customer_trx_id = aps.customer_trx_id --Added for the Defect #4005
--           AND    ract.bill_to_customer_id = aps.customer_id
           AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
           AND    APS.term_id IS NOT NULL
           UNION ALL
             SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */ APS.acctd_amount_due_remaining    amount_due_remaining
                   ,ract.bill_to_customer_id customer_id
           FROM   XX_AR_LOCKBOX_INTERIM  APS
                 ,ra_customer_trx ract
           WHERE  APS.customer_id = p_customer  --Added for the Defect #4005
           AND    APS.status       = 'OP'
           AND    ract.customer_trx_id = aps.customer_trx_id --Added for the Defect #4005
--           AND    ract.bill_to_customer_id = aps.customer_id
           AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
           AND    APS.term_id IS NULL)
           GROUP BY customer_id;
/*
  SELECT SUM(ROUND(APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(p_term_id,(p_deposit_date - APS.trx_date))),gn_cur_precision)) 
amount_due_remaining
  FROM   ar_payment_schedules  APS
        ,ra_customer_trx ract
  WHERE  ract.bill_to_customer_id = p_customer  --Added for the Defect #4005
  --APS.customer_id  = p_customer  --Commented for the Defect #4005
  --AND    APS.class        IN ('INV','CM')
  AND    APS.status       = 'OP'
  --AND    ract.trx_number = aps.trx_number         --Commented for the Defect #4005
  AND    ract.customer_trx_id = aps.customer_trx_id --Added for the Defect #4005
  AND    ract.bill_to_customer_id = aps.customer_id
--  AND    ract.printing_pending = 'N'  --Commented for Defect # 3913
  AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
  GROUP BY APS.customer_id;
*/ --Commented for the Defect #3984
  -- -------------------------------------------
  -- Get the all transactions of a specific customer
  -- and specific range of dates
  -- -------------------------------------------
  CURSOR lcu_get_all_trx ( p_customer     IN   hz_cust_accounts_all.cust_account_id%TYPE
                          ,p_term_id      IN   NUMBER
                          ,p_deposit_date IN   DATE
                          ,p_check_amount IN   NUMBER
                         )
  IS
  --Added for the Defect #3984
  SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */
         APS.trx_number trx_number
        ,APS.trx_date trx_date
  FROM   XX_AR_LOCKBOX_INTERIM     APS
        ,ra_customer_trx ract
  WHERE  APS.class                      = 'INV'
  AND    APS.status                     = 'OP'
  AND    ROUND((APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(APS.term_id,APS.trx_date,p_deposit_date))),gn_cur_precision) = p_check_amount
  AND    APS.customer_id = p_customer          --Added for the Defect #4005
  AND    ract.customer_trx_id = aps.customer_trx_id     --Added for the Defect #4005
--  AND    ract.bill_to_customer_id = aps.customer_id
  AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
  AND    APS.due_date >= p_deposit_date
  UNION ALL
  SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */
         APS.trx_number trx_number
        ,APS.trx_date trx_date
  FROM   XX_AR_LOCKBOX_INTERIM     APS
        ,ra_customer_trx ract
  WHERE  APS.class                      = 'INV'
  AND    APS.status                     = 'OP'
  AND    APS.acctd_amount_due_remaining = p_check_amount
  AND    APS.customer_id = p_customer          --Added for the Defect #4005
  AND    ract.customer_trx_id = aps.customer_trx_id     --Added for the Defect #4005
--  AND    ract.bill_to_customer_id = aps.customer_id
  AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
  AND    APS.due_date < p_deposit_date
  UNION ALL
  SELECT /*+ INDEX(XX_AR_LOCKBOX_INTERIM_N1) */
         APS.trx_number trx_number
        ,APS.trx_date trx_date
  FROM   XX_AR_LOCKBOX_INTERIM     APS
        ,ra_customer_trx ract
  WHERE  APS.class                      = 'CM'
  AND    APS.status                     = 'OP'
  AND    APS.acctd_amount_due_remaining = p_check_amount
  AND    APS.customer_id = p_customer          --Added for the Defect #4005
  AND    ract.customer_trx_id = aps.customer_trx_id     --Added for the Defect #4005
--  AND    ract.bill_to_customer_id = aps.customer_id
  AND    ract.printing_original_date IS NOT NULL
  ORDER BY        -- Added for Defect # 4720
   trx_date       -- Added for Defect # 4720 -- On 19-APR-10
  ,trx_number;    -- Added for Defect # 4720 -- On 19-APR-10

  /*
  SELECT APS.trx_number
        ,APS.trx_date
  FROM   ar_payment_schedules     APS
        ,ra_customer_trx ract
  WHERE  APS.class                      IN ('INV','CM')
  AND    APS.status                     = 'OP'
  AND    ROUND((APS.acctd_amount_due_remaining - (APS.acctd_amount_due_remaining / 100 * 
xx_ar_lockbox_process_pkg.discount_calculate(p_term_id,(p_deposit_date - APS.trx_date)))),gn_cur_precision) = p_check_amount
  --AND    APS.customer_id                = p_customer  --Commented for the Defect #4005
  --AND    ract.trx_number = aps.trx_number             --Commented for the Defect #4005
  AND    ract.bill_to_customer_id = p_customer          --Added for the Defect #4005
  AND    ract.customer_trx_id = aps.customer_trx_id     --Added for the Defect #4005
  AND    ract.bill_to_customer_id = aps.customer_id
--  AND    ract.printing_pending = 'N'  -- Commneted for Defect # 3913
  AND    ract.printing_original_date IS NOT NULL     -- Added for Defect # 3913
;
*/  --Commented for the Defect #3984
  -- -------------------------------------------
  -- Cursor for get the Count of inv match status
  -- -------------------------------------------
  CURSOR lcu_get_status_count ( p_rowid         IN VARCHAR2
                               ,p_process_num   IN VARCHAR2
                               ,p_record_type   IN VARCHAR2
                               )
  IS
  SELECT COUNT(XAPI.inv_match_status)
  FROM   xx_ar_payments_interface   XAPI
  WHERE  XAPI.rowid         = p_rowid
  AND    XAPI.process_num   = p_process_num
  AND    XAPI.record_type   = p_record_type
  AND    XAPI.inv_match_status IS NOT NULL;

  -- -------------------------------------------
  -- Cursor for get the Count of inv match status
  -- -------------------------------------------
  CURSOR lcu_get_dist_status  ( p_process_num   IN VARCHAR2
                               ,p_record_type   IN VARCHAR2
                               )
  IS
  SELECT DISTINCT(XAPI.inv_match_status)  inv_match_status
  FROM   xx_ar_payments_interface   XAPI
  WHERE  XAPI.process_num     = p_process_num
  AND    XAPI.record_type     = p_record_type
  AND    XAPI.inv_match_status IS NOT NULL
  AND    XAPI.inv_match_status NOT IN ('PARTIAL_INVOICE_AMOUNT_EXISTS');

  -- -------------------------------------------------------------------------------
  -- Added for the CR#684 -- Defect #976
  -- Cursor for getting the Customers related through OD_FIN_PAY_WITHIN relationship
  -- -------------------------------------------------------------------------------

  CURSOR lcu_get_related_cust  ( p_party_id     IN NUMBER
                                ,p_deposit_date IN DATE
                                ,p_customer_id  IN NUMBER
                               )
  IS
       SELECT COUNT(HCA.cust_account_id)
       FROM   hz_relationships HR
             ,hz_cust_accounts HCA
       WHERE 1=1
       AND HR.object_id                = HCA.party_id
       AND HCA.cust_account_id         = p_customer_id
       AND HR.subject_id               = p_party_id
       AND NVL(HR.end_date,SYSDATE+1)  > p_deposit_date
       AND HR.status                   = 'A'
       AND HR.relationship_type        = 'OD_FIN_PAY_WITHIN';
------------------------------------------
-- Added for the Defect #3984 on 04-FEB-10
------------------------------------------
-- -----------------------------------------------------------------------
-- Cursor to get the discount % to apply discounts for individual invoices
-- and based on the deposit date and transaction date
-- -----------------------------------------------------------------------
  CURSOR lcu_get_discount
  IS
  SELECT RTL.term_id
        ,RTL.sequence_num
        ,RTL.due_days
        ,RTL.due_day_of_month
        ,RTLD.discount_day_of_month
        ,RTLD.discount_months_forward
        ,RTLD.discount_percent
        ,RTLD.discount_days
  FROM   ra_terms_lines_discounts  RTLD
        ,ra_terms_lines            RTL
  WHERE  RTLD.term_id                 =   RTL.term_id
  AND    RTLD.sequence_num            =   RTL.sequence_num
  ORDER BY  RTLD.discount_percent DESC;
-----------------------------------------------------
--Added for the Defect #2063 on 06-JAN-10
-----------------------------------------------------
  TYPE trxn_det_rec_type IS RECORD
  ( trx_number                  ar_payment_schedules.trx_number%TYPE
   ,trx_date                    ar_payment_schedules.trx_date%TYPE
   ,acctd_amount_due_remaining  ar_payment_schedules.acctd_amount_due_remaining%TYPE
   ,bill_to_customer_id         ra_customer_trx_all.bill_to_customer_id%TYPE
   ,due_date                    ar_payment_schedules.due_date%TYPE    --Added for Defect #3984
   ,term_id                     ar_payment_schedules.term_id%TYPE     --Added for Defect #3984
   ,processed_flag              VARCHAR2(5)                           --Added for Defect #2033
  );

  TYPE trxn_det_tbl_type IS TABLE OF trxn_det_rec_type INDEX BY BINARY_INTEGER;

  lcu_trxn_det_tbl              trxn_det_tbl_type;
  lc_fetched_flag               VARCHAR2(5);  -- Added for Defect # 2063

  -- ---------------------------------------
  -- Local Variables Declaration
  -- ---------------------------------------
  get_lockbox_rec               lcu_get_lockbox_rec%ROWTYPE;
  get_lockbox_det_rec           lcu_get_lockbox_det_rec%ROWTYPE;
  get_trx_number                lcu_get_trx_number%ROWTYPE;
  get_cons_bill_num             lcu_get_cons_bill_num%ROWTYPE;
  get_bai_deposit_dt            lcu_get_bai_deposit_dt%ROWTYPE;
  get_all_trx                   lcu_get_all_trx%ROWTYPE;
  get_dist_status               lcu_get_dist_status%ROWTYPE;
-------------------------------------------------------
--Start of Changes -- For CR #684 -- Defect #976, #1858
-------------------------------------------------------
  ln_custid_count               NUMBER;
  ln_related_cust_cnt           NUMBER;
  ln_micr_customer_id           hz_cust_accounts_all.cust_account_id%TYPE;
  ln_micr_party_id              hz_cust_accounts_all.party_id%TYPE;
  ln_party_id                   hz_cust_accounts_all.party_id%TYPE;
  ln_ora_party_id               hz_cust_accounts_all.party_id%TYPE;
  ln_micr_cust_number           hz_cust_accounts_all.account_number%TYPE;
  lc_micr_number                VARCHAR2(150);
  ln_check_amt                  NUMBER;
-------------------------------------------------------
--End of Changes -- For CR #684 -- Defect #976, #1858
-------------------------------------------------------
-------------------------------------------------------
-- Start of Changes -- For Defect #3983 on 26-JAN-10
-------------------------------------------------------
  lc_invoice_exists                     VARCHAR2(5);
  lc_det_rec_invoice1                   xx_ar_payments_interface.invoice1%TYPE;
  lc_det_rec_invoice2                   xx_ar_payments_interface.invoice2%TYPE;
  lc_det_rec_invoice3                   xx_ar_payments_interface.invoice3%TYPE;
  lc_zero_suffix                        VARCHAR2(10) := '00';
  ln_invoice_suffix                     NUMBER := 1;
  lc_invoice_status                     VARCHAR2(60);
  ln_suffix_match_cnt                   NUMBER := 0;
  lc_consolidated_check                 VARCHAR2(5);
  ln_bo_inv_cust_num                    hz_cust_accounts.account_number%TYPE;

  ln_con_invoice1                       NUMBER:=0;
  ln_con_invoice2                       NUMBER:=0;
  ln_con_invoice3                       NUMBER:=0;

  ln_invoice1_length                    NUMBER:=0;   -- Added for Defect# 4720
  ln_invoice2_length                    NUMBER:=0;   -- Added for Defect# 4720
  ln_invoice3_length                    NUMBER:=0;   -- Added for Defect# 4720
  lc_trxn_not_exists                    VARCHAR2(1); -- Added for Defect# 2033
-------------------------------------------------------
--End of Changes -- For Defect #3983 on 26-JAN-10
-------------------------------------------------------

  lc_cust_match_profile         hz_customer_profiles.lockbox_matching_option%TYPE;
  ln_customer_id                hz_cust_accounts_all.cust_account_id%TYPE;

  lc_oracle_cust_num            VARCHAR2(40);
  ln_standard_terms             hz_customer_profiles.standard_terms%TYPE;
  lc_cons_inv_flag              hz_customer_profiles.cons_inv_flag%TYPE;
  lr_record                     xx_ar_payments_interface%ROWTYPE;

  ln_discount_percent           NUMBER;
  ln_diff_amount                NUMBER;
  ln_amount_applied1            NUMBER;
  ln_amount_applied2            NUMBER;
  ln_amount_applied3            NUMBER;

  ln_tot_inv_rcv_bnk            NUMBER   :=0;
  ln_tot_ora_inv_match          NUMBER   :=0;
  ln_tot_amt_inv_match          NUMBER   :=0;
  ln_mail_request_id            NUMBER   :=0;
  ln_retcode                    NUMBER   :=0;
  ln_inv_match_counter          NUMBER   :=0;
  ln_profile_digit_check        NUMBER;
  ln_count_autocash_proc        NUMBER;
  ln_get_sum_amt_due_remaining  NUMBER;
  ln_status_count               NUMBER   :=0;
--  ln_trx_number_count           NUMBER   :=0;  --Commented for the Defect #4720
  ln_remittance_amount          NUMBER;
  ln_no_of_match_count          NUMBER;
  ln_trx_amount                 NUMBER;
  ln_ora_cust_acct_id           NUMBER;

  lc_error_details              VARCHAR2(32000);
  lc_error_location             VARCHAR2(32000);
  lc_errmsg                     VARCHAR2(32000);
  lc_inv_match_status           VARCHAR2(100);
  lc_source_err_flag            VARCHAR2(1);
  lc_date_range_match           VARCHAR2(1);
  lc_pulse_pay_match            VARCHAR2(1);
  lc_clear_act_match            VARCHAR2(1);
  lc_exact_match                VARCHAR2(1);
  lc_trx_number                 VARCHAR2(60);

  ld_trx_date                   DATE;

  lb_inv_match                  BOOLEAN;
  lb_inv_amount_match           BOOLEAN;

  EX_MAIN_EXCEPTION             EXCEPTION;

  truncate_stmnt                VARCHAR2(100) :=TO_CHAR(NULL);
  ln_match_status_count         NUMBER;

BEGIN

  put_log_line('[BEGIN] CUSTOM_AUTO_CASH - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

  -- =================================================
  -- Call the truncate the temp table of any combo
  -- =================================================
    --truncate_stmnt :='TRUNCATE TABLE XXFIN.XX_AR_ANYCOMBO_NCR_GTMP';
    --EXECUTE IMMEDIATE truncate_stmnt;

  -- =================================================
  -- Populate the combinations.
  -- =================================================
    Gen_Combinations(p_trx_threshold ,lc_errmsg ,ln_retcode);
    IF ln_retcode  = gn_error THEN
       lc_error_details := 'Error at Gen Combinations'||':'|| lc_errmsg;
     RAISE EX_MAIN_EXCEPTION;
    END IF;

  put_log_line('[WIP] Gen_Comb Complete - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
  -----------------------------------------
  -- Start of changes for the Defect #3984
  -----------------------------------------

      OPEN lcu_get_discount;
      FETCH lcu_get_discount BULK COLLECT INTO lcu_discount_rec_tbl;
      CLOSE lcu_get_discount;
      put_log_line('Count of Discount Terms Fetched --  '||lcu_discount_rec_tbl.COUNT);

  -----------------------------------------

  -- -------------------------------------------
  -- Initialize the Local Variables
  -- -------------------------------------------
  ln_count_autocash_proc   := NULL;
  ln_profile_digit_check   := NVL(p_check_digit,6);
  lc_errmsg                := NULL;
  lc_inv_match_status      := 'PARTIAL_INVOICE_AMOUNT_EXISTS';

  -- -------------------------------------------
  -- Get the Currency Precision from functional
  -- currency
  -- -------------------------------------------
  OPEN  luc_currency_per;
  FETCH luc_currency_per  INTO gn_cur_precision;
  CLOSE luc_currency_per;
  --
  --
  --
  IF gn_cur_precision = 1 THEN
    gn_cur_mult_dvd := 10;
  ELSIF gn_cur_precision = 2 THEN
    gn_cur_mult_dvd := 100;
  ELSIF gn_cur_precision = 3 THEN
    gn_cur_mult_dvd := 1000;
  ELSIF gn_cur_precision = 4 THEN
    gn_cur_mult_dvd := 10000;
  ELSIF gn_cur_precision = 5 THEN
    gn_cur_mult_dvd := 100000;
  END IF;

  -- -------------------------------------------
  -- Call the Print Message Header
  -- -------------------------------------------
  print_message_header
   (x_errmsg      =>   lc_errmsg
   ,x_retstatus   =>   ln_retcode
   );

  IF ln_retcode  = gn_error THEN
      lc_error_location := 'Error at Print Message Header: '|| lc_errmsg;
      RAISE EX_MAIN_EXCEPTION;
  END IF;
  -- -------------------------------------------
  -- Loop through and find the valid customer
  -- -------------------------------------------
  OPEN   lcu_get_lockbox_rec ( p_process_number   => p_process_num
                              ,p_record_type      => '6' );
  LOOP
  FETCH  lcu_get_lockbox_rec  INTO get_lockbox_rec;
  EXIT WHEN lcu_get_lockbox_rec%NOTFOUND;

  put_log_line('Start of 6th record ' || get_lockbox_rec.batch_name||' - '||get_lockbox_rec.item_number||' - '||TO_CHAR
(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

    -- -------------------------------------------
    -- Initializing Local Variables
    -- -------------------------------------------
    lc_error_location            := 'Initializing Local Variables';
    lc_source_err_flag           := 'N';
    lc_error_details             := NULL;
    ln_customer_id               := NULL;
    lc_cust_match_profile        := NULL;
    ln_standard_terms            := NULL;
    ld_trx_date                  := NULL;
    ln_diff_amount               := NULL;
    ln_count_autocash_proc       := NULL;
    lc_date_range_match          := NULL;
    lc_pulse_pay_match           := NULL;
    lc_clear_act_match           := NULL;
    lc_exact_match               := NULL;
    ln_get_sum_amt_due_remaining := NULL;
    ln_remittance_amount         := NULL;
    lc_cons_inv_flag             := NULL;
    lc_trx_number                := NULL;
    lc_oracle_cust_num           := NULL; -- Sai Bala on 04-MAR-2007 to address Defect 5140
    ln_discount_percent          := 0;
    ln_no_of_match_count         := 0;
    ln_trx_amount                := 0;
-------------------------------------------------------
--Start of Changes -- For CR #684 -- Defect #976, #1858
-------------------------------------------------------
    ln_micr_customer_id          := NULL;
    ln_micr_party_id             := NULL;
    ln_party_id                  := NULL;
    ln_ora_party_id              := NULL;
    ln_micr_cust_number          := NULL;
    lc_fetched_flag              := 'N';
-------------------------------------------------------
--End of Changes -- For CR #684 -- Defect #976, #1858
-------------------------------------------------------
    -- -------------------------------------------
    -- Call the valid valid_customer function
    -- to validate the customer for the same
    -- bank routing number and bank account number
    -- -------------------------------------------

    --put_log_line('[WIP] Fetch LB Rec - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

/*    lc_error_location := 'Mandatory Check for Customer Number';
    IF get_lockbox_rec.customer_number IS NULL THEN
      put_log_line('Customer Number is NULL' );

      IF get_lockbox_rec.account IS NULL
        OR get_lockbox_rec.transit_routing_number IS NULL THEN

        lc_source_err_flag   := 'Y';
        fnd_message.set_name ('XXFIN','XX_AR_202_NO_CUSTOMER_INFO');
        lc_error_details     := lc_error_details||fnd_message.get||CHR(10);
        --
        put_log_line('Bank Account or Bank Routing Number is not available for the record batch name' ||
get_lockbox_rec.batch_name);

      ELSE

        ln_customer_id := valid_customer( p_transit_routing_num  => get_lockbox_rec.transit_routing_number
                                         ,p_account              => get_lockbox_rec.account
                                        );
        IF ln_customer_id = 0 THEN

          lc_source_err_flag   := 'Y';
          fnd_message.set_name ('XXFIN','XX_AR_203_NOT_VALID_CUSTOMER');
          fnd_message.set_token('BANK_ROUTING',get_lockbox_rec.transit_routing_number);
          fnd_message.set_token('ACCOUNT',get_lockbox_rec.account);
          lc_error_details     := lc_error_details||fnd_message.get||CHR(10);

          --
          --put_log_line('There is no valid customer for Bank Account / Routing Number' ||get_lockbox_rec.account ||'/'||
get_lockbox_rec.transit_routing_number);
        END IF;
      END IF;
    ELSE
      put_log_line('Customer Number is Defined (' || get_lockbox_rec.customer_number || ')' );
      -- -------------------------------------------
      -- Validate the Customer number
      -- -------------------------------------------
      OPEN   lcu_valid_customer (p_customer_num  => get_lockbox_rec.customer_number);
      FETCH  lcu_valid_customer INTO ln_customer_id,
                                     lc_oracle_cust_num;
      CLOSE  lcu_valid_customer;

      -- QC Defect 954. Added new derivation for customer number.

      ln_ora_cust_acct_id := NULL;
      BEGIN
           SELECT  cust_account_id
             INTO  ln_ora_cust_acct_id
             FROM  hz_cust_accounts
            WHERE  account_number = LTRIM(get_lockbox_rec.customer_number,'0');
      EXCEPTION
            WHEN OTHERS THEN
                 ln_ora_cust_acct_id := NULL;
      END;

      -- 03-AUG-2009 - Adjust derivation logic for invalid cust# (EBS and AOPS)
      -- DO NOT NULL OUT THE CUSTOMER NUMBER IF CUSTOMER# FROM LOCKBOX FILE DOES NOT MATCH EITHER
      --IF ln_ora_cust_acct_id IS  NULL AND (ln_customer_id IS NULL OR ln_customer_id = 0) THEN
      --      -- NULL OUT THE CUSTOMER NUMBER. -- Why = 0 check ? Just retained the old code.
      --      UPDATE xx_ar_payments_interface XAPI
      --            SET    XAPI.customer_number   = NULL
      --            WHERE  XAPI.rowid             = get_lockbox_rec.rowid
      --            AND    XAPI.process_num       = get_lockbox_rec.process_num;
            --      ln_customer_id := NULL;
      --      lc_source_err_flag   := 'Y';
      --      fnd_message.set_name ('XXFIN','XX_AR_202_NO_CUSTOMER_INFO');
      --      lc_error_details     := lc_error_details||fnd_message.get||CHR(10);
      --      put_log_line('Customer Number is not available for the record batch name' ||get_lockbox_rec.batch_name);

      IF    ln_ora_cust_acct_id IS NOT NULL AND ln_customer_id IS NOT NULL AND
            ln_customer_id <> 0 AND ln_customer_id <> ln_ora_cust_acct_id THEN
         -- NULL OUT THE CUSTOMER NUMBER;
            UPDATE xx_ar_payments_interface XAPI
                     SET XAPI.customer_number   = NULL
                   WHERE XAPI.rowid             = get_lockbox_rec.rowid
               AND XAPI.process_num       = get_lockbox_rec.process_num;

            ln_customer_id := NULL;
            lc_source_err_flag   := 'Y';
            lc_error_details     := lc_error_details||'More than one customer found ...' ||CHR(10);
            put_log_line('More than one customer found with Legacy or Oracle account number' ||
get_lockbox_rec.customer_number);


      ELSIF ln_ora_cust_acct_id IS NOT NULL AND (ln_customer_id IS NULL OR ln_customer_id = 0) THEN
            ln_customer_id     := ln_ora_cust_acct_id;
            lc_oracle_cust_num := LTRIM(get_lockbox_rec.customer_number,'0');

      ELSIF ln_ora_cust_acct_id IS NULL AND ln_customer_id IS NOT NULL THEN
            NULL; -- EBS customer number and account id retrieved and assigned by lcu_valid_customer.

      END IF;

      /* Commented the below logic for QC Defect 954

      IF ln_customer_id IS NULL OR ln_customer_id = 0 THEN
      --
        --IF get_lockbox_rec.account IS NULL-------------
        --  OR get_lockbox_rec.transit_routing_number IS NULL THEN

          lc_source_err_flag   := 'Y';
          fnd_message.set_name ('XXFIN','XX_AR_202_NO_CUSTOMER_INFO');
          lc_error_details     := lc_error_details||fnd_message.get||CHR(10);

          put_log_line('Customer Number is not available for the record batch name' ||get_lockbox_rec.batch_name);

        --ELSE


        --END IF;
      ELSE


         IF lc_oracle_cust_num = get_lockbox_rec.customer_number THEN

            put_log_line('Legacy Customer# has the same value as Oracle Cust#'||get_lockbox_rec.customer_number||' : '||
get_lockbox_rec.batch_name);

            UPDATE xx_ar_payments_interface XAPI
            SET    XAPI.customer_number   = NULL
            WHERE  XAPI.rowid             = get_lockbox_rec.rowid
            AND    XAPI.process_num       = get_lockbox_rec.process_num;

            ln_customer_id := valid_customer( p_transit_routing_num  => get_lockbox_rec.transit_routing_number
                                             ,p_account              => get_lockbox_rec.account
                                          );
            IF ln_customer_id = 0 THEN

              lc_source_err_flag   := 'Y';
              fnd_message.set_name ('XXFIN','XX_AR_203_NOT_VALID_CUSTOMER');
              fnd_message.set_token('BANK_ROUTING',get_lockbox_rec.transit_routing_number);
              fnd_message.set_token('ACCOUNT',get_lockbox_rec.account);
              lc_error_details     := lc_error_details||fnd_message.get||CHR(10);


              put_log_line('There is no valid customer for Bank Account' ||get_lockbox_rec.account ||
get_lockbox_rec.transit_routing_number);

            END IF;

         END IF;
      --
      END IF;
      End of Defect 954 */
  --  END IF; */ --Commented for the defect #976 (CR#684)
    -- -------------------------------------------
    -- Get the Deposit Date for the Batch of
    -- Record Type 6 and there should be only
    -- one single record for record type and 7 and
    -- for the same batch
    -- -------------------------------------------
    OPEN  lcu_get_bai_deposit_dt ( p_batch_name      => get_lockbox_rec.batch_name
                                  ,p_process_number  => p_process_num
                                 );
    FETCH  lcu_get_bai_deposit_dt  INTO get_bai_deposit_dt;
    CLOSE  lcu_get_bai_deposit_dt;

-----------------------------------------------------------------------
-- Start of Changes for the CR #684 -- Defect #976
-----------------------------------------------------------------------
   IF get_lockbox_rec.customer_number IS NULL THEN
           put_log_line('Customer Number is NULL' );

           IF (get_lockbox_rec.account IS NULL OR get_lockbox_rec.transit_routing_number IS NULL) THEN

              lc_source_err_flag   := 'Y';
              fnd_message.set_name ('XXFIN','XX_AR_202_NO_CUSTOMER_INFO');
              lc_error_details     := lc_error_details||fnd_message.get||CHR(10);

               put_log_line('Bank Account or Bank Routing Number is not available for the record batch name' ||
get_lockbox_rec.batch_name);

           ELSE
               valid_customer( x_customer_id          => ln_customer_id
                              ,x_party_id             => ln_party_id
                              ,x_micr_cust_num        => ln_micr_cust_number
                              ,p_transit_routing_num  => get_lockbox_rec.transit_routing_number
                              ,p_account              => get_lockbox_rec.account
                             );
               IF (ln_customer_id IN(0,-1)) THEN   --Added for defect #976
                    ln_customer_id := NULL;
                    ln_party_id    := NULL;
                    lc_source_err_flag   := 'Y';
                    fnd_message.set_name ('XXFIN','XX_AR_203_NOT_VALID_CUSTOMER');
                    fnd_message.set_token('BANK_ROUTING',get_lockbox_rec.transit_routing_number);
                    fnd_message.set_token('ACCOUNT',get_lockbox_rec.account);
                    lc_error_details     := lc_error_details||fnd_message.get||CHR(10);
               END IF;
           END IF;
   ELSE
           put_log_line('Customer Number is Defined (' || get_lockbox_rec.customer_number || ')' );
      -- -------------------------------------------
      -- Validate the Customer Number
      -- -------------------------------------------
          OPEN   lcu_valid_customer (p_customer_num  => get_lockbox_rec.customer_number);
          FETCH  lcu_valid_customer INTO ln_customer_id
                                        ,lc_oracle_cust_num
                                        ,ln_party_id;
          CLOSE  lcu_valid_customer;

          ln_ora_cust_acct_id := NULL;
          ln_ora_party_id     := NULL;

          BEGIN
               SELECT  cust_account_id
                      ,party_id
                 INTO  ln_ora_cust_acct_id
                      ,ln_ora_party_id
                 FROM  hz_cust_accounts
                WHERE  account_number = LTRIM(get_lockbox_rec.customer_number,'0');
          EXCEPTION
                WHEN OTHERS THEN
                ln_ora_cust_acct_id := NULL;
                ln_ora_party_id     := NULL;
          END;

          IF (ln_ora_cust_acct_id IS NOT NULL
              AND ln_customer_id IS NOT NULL
              AND ln_customer_id <> 0
              AND ln_customer_id <> ln_ora_cust_acct_id
             )THEN

         -- NULL OUT THE CUSTOMER NUMBER;

                UPDATE xx_ar_payments_interface XAPI
                   SET XAPI.customer_number   = NULL
                 WHERE XAPI.rowid             = get_lockbox_rec.rowid
                   AND XAPI.process_num       = get_lockbox_rec.process_num;

                ln_customer_id := NULL;
                ln_party_id    := NULL;
                lc_source_err_flag   := 'Y';
                lc_error_details     := lc_error_details||'More than one customer found ...' ||CHR(10);
                put_log_line('More than one customer found with Legacy or Oracle account number' ||
get_lockbox_rec.customer_number);

          ELSIF ln_ora_cust_acct_id IS NOT NULL AND (ln_customer_id IS NULL OR ln_customer_id = 0) THEN
                ln_customer_id  := ln_ora_cust_acct_id;
                ln_party_id     := ln_ora_party_id;
                lc_oracle_cust_num := LTRIM(get_lockbox_rec.customer_number,'0');

          ELSIF ln_ora_cust_acct_id IS NULL AND ln_customer_id IS NOT NULL THEN
                NULL; -- EBS customer number and account id retrieved and assigned by lcu_valid_customer.
          END IF;
-----------------------------------------------------------------------------------
--Added for CR#684 -- Defect #976
--Valid Customer ID -- ln_customer_id -- Based on BAI Customer Number
--Valid Party ID    -- ln_party_id
--Scenarios handled for the customers related through OD_FIN_PAY_WITHIN relationship
------------------------------------------------------------------------------------
           IF (get_lockbox_rec.account IS NULL OR get_lockbox_rec.transit_routing_number IS NULL) THEN
              lc_source_err_flag   := 'Y';
              fnd_message.set_name ('XXFIN','XX_AR_202_NO_CUSTOMER_INFO');
              lc_error_details     := lc_error_details||fnd_message.get||CHR(10);
              put_log_line('Bank Account or Bank Routing Number is not available for the record batch name' ||
get_lockbox_rec.batch_name);
           ELSE
               valid_customer( x_customer_id          => ln_micr_customer_id
                              ,x_party_id             => ln_micr_party_id
                              ,x_micr_cust_num        => ln_micr_cust_number
                              ,p_transit_routing_num  => get_lockbox_rec.transit_routing_number
                              ,p_account              => get_lockbox_rec.account
                             );
           END IF;
---------------------------------------------------------------------------------------
-- Valid Customer ID and MICR Customer ID -- NOT SAME
---------------------------------------------------------------------------------------
         IF( ln_customer_id <> ln_micr_customer_id
             AND ln_micr_customer_id NOT IN (-1,0)
             AND ln_customer_id IS NOT NULL
             AND ln_micr_customer_id IS NOT NULL
             ) THEN
           --Fetch the related customer for the valid customer
            OPEN lcu_get_related_cust(
                                      p_party_id     => ln_party_id
                                     ,p_deposit_date => get_bai_deposit_dt.deposit_date
                                     , p_customer_id  => ln_micr_customer_id
                                     );
            FETCH lcu_get_related_cust INTO ln_related_cust_cnt;
                ------------------------------------------------------------------
                -- Scenario1 : Valid Customer ID and MICR Customer ID are RELATED
                --             NULL OUT CUSTOMER NUMBER
                ------------------------------------------------------------------
                IF (ln_related_cust_cnt > 0) THEN

                    lc_micr_number             := get_lockbox_rec.transit_routing_number||' '||get_lockbox_rec.account;
                    ln_check_amt               := get_lockbox_rec.remittance_amount /gn_cur_mult_dvd ;
                    gt_cust_number(ln_count)   := get_lockbox_rec.customer_number;
                    gt_check_number(ln_count)  := get_lockbox_rec.check_number;
                    gt_check_amt(ln_count)     := ln_check_amt;
                    gt_micr_num(ln_count)      := lc_micr_number;
                    gt_micr_cust_num(ln_count) := ln_micr_cust_number;
                    ln_count                   := ln_count + 1;

                    lc_oracle_cust_num   := NULL; --NULL OUT CUSTOMER NUMBER when RELATED
                    gn_tot_cust_removed  := gn_tot_cust_removed + 1;

                END IF;
            CLOSE lcu_get_related_cust;
                ----------------------------------------------------------------------------------
                -- Scenario1 and 2 : Valid Customer ID and MICR Customer ID RELATED or not RELATED
                --                   Substitution logic -- MICR Customer ID
                ----------------------------------------------------------------------------------
                    ln_customer_id := ln_micr_customer_id;
                    ln_party_id    := ln_micr_party_id;
---------------------------------------------------------------------------------------------------
-- Scenario3(a) and 5 : Valid as well as invalid Customer ID and Too many values for MICR Customer ID
---------------------------------------------------------------------------------------------------
         ELSIF (ln_micr_customer_id = -1) THEN
--------------------------------------------------------------------------------------------------------
-- If MICR is assigned to Multiple Customer then for a valid BAI file Customer number program should
-- replace the BAI Customer Number with Oracle Customer number-- Added for Defect #976 On 17-DEC-09
--------------------------------------------------------------------------------------------------------
                IF (ln_customer_id IS NOT NULL) THEN
                      UPDATE xx_ar_payments_interface XAPI
                         SET XAPI.customer_number   = lc_oracle_cust_num
                       WHERE XAPI.rowid             = get_lockbox_rec.rowid
                         AND XAPI.process_num       = get_lockbox_rec.process_num;
                END IF;

                ln_customer_id := NULL;
                ln_party_id    := NULL;
                lc_source_err_flag   := 'Y';
                lc_error_details     := lc_error_details||'More than one customer found ...' ||CHR(10);
                put_log_line('More than one customer found for MICR customer ID' ||ln_micr_customer_id);
----------------------------------------------------------------------------------------
-- Scenario3(b) : Valid Customer ID and no value for MICR Customer ID
----------------------------------------------------------------------------------------
         ELSIF (ln_customer_id IS NOT NULL
                AND ln_micr_customer_id = 0
               ) THEN
                NULL; -- Valid Customer ID and Party ID used for substitution
----------------------------------------------------------------------------------------
-- Scenario4   : Invalid Customer ID but valid MICR Customer ID exists
----------------------------------------------------------------------------------------
         ELSIF (ln_customer_id IS NULL
                AND ln_micr_customer_id IS NOT NULL
                AND ln_micr_customer_id NOT IN (-1,0)
                ) THEN
                    ln_customer_id := ln_micr_customer_id;
                    ln_party_id    := ln_micr_party_id;
                    lc_oracle_cust_num := LTRIM(get_lockbox_rec.customer_number,'0'); --Added for #976 on 11-DEC-09
----------------------------------------------------------------------------------------
-- Scenario6   : Invalid Customer ID and No values for MICR Customer ID
----------------------------------------------------------------------------------------
         ELSIF (ln_customer_id IS NULL
                AND ln_micr_customer_id = 0
                ) THEN
                ln_customer_id := NULL;
                ln_party_id    := NULL;
                lc_source_err_flag   := 'Y';
                lc_error_details     := lc_error_details||'No customer found ...' ||CHR(10);
                put_log_line('Invalid Customer ID and No customer found for MICR customer ID' ||ln_micr_customer_id);
----------------------------------------------------------------------------------------
-- Scenario7   : Customer ID and MICR Customer ID -- SAME
----------------------------------------------------------------------------------------
         ELSIF ( ln_customer_id = ln_micr_customer_id
                 AND ln_micr_customer_id NOT IN (-1,0)
                 AND ln_customer_id IS NOT NULL
                 AND ln_micr_customer_id IS NOT NULL
                ) THEN
                NULL; -- Valid Customer ID and Party ID used for substitution
         END IF;
   END IF;
----------------------------------------------------------------------------------------
--End of changes for CR #684 -- Defect #976
----------------------------------------------------------------------------------------
    --put_log_line('[WIP] Fetch Deposit Date - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

    -- -------------------------------------------
    -- Check the Customer is valid then call the
    -- Partial Invoice Match and Custom Autocash rule
    -- -------------------------------------------
    --IF ln_customer_id IS NOT NULL AND ln_customer_id <> 0 THEN     --Commented for the CR#684 --Defect #976

     --  Added the code for CR#872

    If (Ln_Customer_Id Is Null And Ln_Party_Id Is Null) Then

     put_log_line('Getting the Customer details through Sending Company ID'|| get_lockbox_rec.sending_company_id);
     BEGIN
		 SELECT HCA.cust_account_id
			,HCA.account_number
			,Hca.Party_Id
		 INTO ln_customer_id,
			 lc_oracle_cust_num,
			 ln_party_id
		 From   Hz_Cust_Accounts  Hca
		 WHERE HCA.cust_account_id = (SELECT cust_account_id FROM XX_CDH_EXT_ACH_ID_V WHERE 
ach_id=get_lockbox_rec.sending_company_id
							and rownum = 1); -- rownum =1 added for or CR872 need to allow multiple ACH Sending IDs to one OD Customer defect # 11971
                                                           -- LTRIM(get_lockbox_rec.sending_company_id,0));--Ltrim Commented by Gaurav
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
     ln_customer_id := NULL;
       Ln_Party_Id    := Null;
      put_log_line('No Data found for the corresponding Sending Company ID '|| get_lockbox_rec.sending_company_id);
   WHEN TOO_MANY_ROWS THEN
       ln_customer_id := NULL;
       ln_party_id    := NULL;
	  put_log_line('Too Many Values for Sending Company ID'||get_lockbox_rec.sending_company_id);


    WHEN OTHERS THEN
       ln_customer_id := NULL;
       ln_party_id    := NULL;


End;
END IF;

      IF (ln_customer_id IS NOT NULL AND ln_party_id IS NOT NULL) THEN --Added for the CR#684 --Defect #976
      -- -------------------------------------------
      -- Update the Customer ID into custom interface
      -- table xx_ar_payments_interface for process reference
      -- -------------------------------------------
           UPDATE xx_ar_payments_interface XAPI
           SET    XAPI.customer_id       = ln_customer_id
                 ,XAPI.customer_number   = lc_oracle_cust_num
                 ,XAPI.auto_cash_request = gn_request_id
           WHERE  XAPI.rowid             = get_lockbox_rec.rowid
           AND    XAPI.process_num       = get_lockbox_rec.process_num;

      -- -------------------------------------------
      -- Check Customer Profile for Matching by receipts
      -- Lockbox matching Option
      -- -------------------------------------------
           OPEN  lcu_get_cust_match_profile ( p_cust_account_id  =>  ln_customer_id );
           FETCH lcu_get_cust_match_profile  INTO lc_cust_match_profile
                                                 ,ln_standard_terms
                                                 ,lc_cons_inv_flag;
           CLOSE lcu_get_cust_match_profile;

           lc_error_location := 'Check the Receipt Match Profile of Customer';
           put_log_line('Customer' || ln_customer_id);

         --put_log_line('[WIP] LB matching Option - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

      -- -------------------------------------------
      -- Open the cursor to get the counter of record
      -- type '4' is not available for record type '6'
      -- -------------------------------------------
           OPEN  lcu_count_autocash_proc ( p_process_num   =>  get_lockbox_rec.process_num
                                          ,p_batch_name    =>  get_lockbox_rec.batch_name
                                          ,p_item_number   =>  get_lockbox_rec.item_number);
           FETCH lcu_count_autocash_proc INTO ln_count_autocash_proc;
           CLOSE lcu_count_autocash_proc;

         --put_log_line('[WIP] Count 4 recs - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

           ln_remittance_amount   := get_lockbox_rec.remittance_amount / gn_cur_mult_dvd; --SUBSTR(get_lockbox_rec.remittance_amount,1,LENGTH(get_lockbox_rec.remittance_amount)-gn_cur_precision)||'.'||SUBSTR(get_lockbox_rec.remittance_amount,(LENGTH(get_lockbox_rec.remittance_amount)-1));
      -- -------------------------------------------
      -- Call the Custom Auto Cash Rules
      -- Assign the values into record type
      -- -------------------------------------------
           lr_record.status                     :=   get_lockbox_rec.status;
           lr_record.record_type                :=   get_lockbox_rec.record_type;
           lr_record.destination_account        :=   get_lockbox_rec.destination_account;
           lr_record.origination                :=   get_lockbox_rec.origination;
           lr_record.lockbox_number             :=   get_lockbox_rec.lockbox_number;
           lr_record.deposit_date               :=   get_lockbox_rec.deposit_date;
           lr_record.deposit_time               :=   get_lockbox_rec.deposit_time;
           lr_record.batch_name                 :=   get_lockbox_rec.batch_name;
           lr_record.item_number                :=   get_lockbox_rec.item_number;
           lr_record.remittance_amount          :=   ln_remittance_amount;
           lr_record.transit_routing_number     :=   get_lockbox_rec.transit_routing_number;
           lr_record.account                    :=   get_lockbox_rec.account;
           lr_record.check_number               :=   get_lockbox_rec.check_number;
           lr_record.customer_number            :=   get_lockbox_rec.customer_number;
           lr_record.overflow_sequence          :=   get_lockbox_rec.overflow_sequence;
           lr_record.overflow_indicator         :=   get_lockbox_rec.overflow_indicator;
           lr_record.invoice1                   :=   get_lockbox_rec.invoice1;
           lr_record.invoice2                   :=   get_lockbox_rec.invoice2;
           lr_record.invoice3                   :=   get_lockbox_rec.invoice3;
           lr_record.batch_record_count         :=   get_lockbox_rec.batch_record_count;
           lr_record.batch_amount               :=   get_lockbox_rec.batch_amount;
           lr_record.lockbox_record_count       :=   get_lockbox_rec.lockbox_record_count;
           lr_record.lockbox_amount             :=   get_lockbox_rec.lockbox_amount;
           lr_record.transmission_record_count  :=   get_lockbox_rec.transmission_record_count;
           lr_record.transmission_amount        :=   get_lockbox_rec.transmission_amount;
           lr_record.record_status              :=   get_lockbox_rec.record_status;
           lr_record.process_num                :=   get_lockbox_rec.process_num;
           lr_record.file_name                  :=   get_lockbox_rec.file_name;
           lr_record.error_mesg                 :=   get_lockbox_rec.error_mesg;
           lr_record.inv_match_status           :=   get_lockbox_rec.inv_match_status;
           lr_record.process_date               :=   get_lockbox_rec.process_date;
           lr_record.error_flag                 :=   get_lockbox_rec.error_flag;
           --lr_record.customer_id                :=    ln_customer_id;
           --lr_record.rowid                      :=    get_lockbox_rec.rowid;

           -- -------------------------------------------
                 -- If Counter is > 0 then its custom auto cash
                 -- rule procedure will be called
           -- -------------------------------------------
           IF ln_count_autocash_proc > 0 THEN

               --ln_trx_number_count := 0;
             --fnd_file.put_line(fnd_file.output,'Auto Cash Counter:-'||ln_count_autocash_proc);
             -- -------------------------------------------
             -- Check Customer Balance Match Rule
             -- If it match then its Clear Account Match
             -- Update the Status Clear Account Match
             -- -------------------------------------------
               lc_error_location := 'Check the Customer total balance ';
               OPEN  lcu_get_sum_amt_due_remaining ( p_customer     =>  ln_customer_id
                                                    ,p_term_id      =>  ln_standard_terms
                                                    ,p_deposit_date =>  get_bai_deposit_dt.deposit_date);
               FETCH lcu_get_sum_amt_due_remaining INTO ln_get_sum_amt_due_remaining;
               CLOSE lcu_get_sum_amt_due_remaining;

             --put_log_line('[WIP] Fetch Sum Due - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

               put_log_line('get_lockbox_rec.remittance_amount'||get_lockbox_rec.remittance_amount);
               put_log_line('ln_get_sum_amt_due_remaining'||ln_get_sum_amt_due_remaining);

               IF ln_get_sum_amt_due_remaining  =  (get_lockbox_rec.remittance_amount / gn_cur_mult_dvd)  THEN

                  lc_clear_act_match  := 'Y';

                  put_log_line('lc_clear_act_match'||lc_clear_act_match);
          -- -------------------------------------------
          -- Update the Status for record type '6'
          -- for Total Customer Balance equal to check amount
          -- then the status is updated to 'CLEAR_ACCOUNT'
          -- -------------------------------------------
                  lc_error_location := 'Call the Update Status Procedure for Clear Account Match for Invoice1 record type 6';
                  update_lckb_rec
                  ( x_errmsg                    => lc_errmsg
                   ,x_retstatus                 => ln_retcode
                   ,p_process_num               => p_process_num
                   ,p_record_type               => '6'
                   ,p_inv_match_status          => 'CLEAR_ACCOUNT'
                   ,p_rowid                     => get_lockbox_rec.rowid
                  );

                  IF ln_retcode  = gn_error THEN
                     lc_error_details := lc_error_location||':'|| lc_errmsg;
                     RAISE EX_MAIN_EXCEPTION;
                  END IF;

               ELSE
                  -- -------------------------------------------
                  -- Check Customer Balance Match Rule
                  -- If it match then its Clear Account Match
                  -- Update the Status Clear Account Match
                  -- -------------------------------------------
                  OPEN lcu_get_all_trx
                    ( p_customer       =>  ln_customer_id
                     ,p_term_id        =>  ln_standard_terms
                     ,p_deposit_date   =>  get_bai_deposit_dt.deposit_date
                     ,p_check_amount   =>  lr_record.remittance_amount);
                  put_log_line('[WIP] Exact Match Rule - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
                  LOOP
                  FETCH lcu_get_all_trx INTO get_all_trx;
                  put_log_line('[WIP] No of TRX fetched -  ' ||lcu_get_all_trx%ROWCOUNT);       -- Testing
                  EXIT WHEN lcu_get_all_trx%NOTFOUND;

                  --IF ln_trx_number_count = 1 AND get_all_trx.trx_number IS NOT NULL THEN-- Commented for defect#4720

                  IF (get_all_trx.trx_number IS NOT NULL) THEN -- Added for defect# 4720

                     lc_exact_match  := 'Y';
                   --fnd_file.put_line(fnd_file.output,'lc_exact_match:-'||lc_exact_match);
                   -- -------------------------------------------
                   -- Call the Create Record Procedure to create record type '4'
                   -- into xx_ar_payments_interface table for matching bucket
                   -- -------------------------------------------
                   -- Assigning the value into record columns

                      lr_record.status                := 'AR_PLB_NEW_RECORD';
                      lr_record.record_type           := '4';
                      lr_record.batch_name            := get_lockbox_rec.batch_name;
                      lr_record.item_number           := get_lockbox_rec.item_number;
                      lr_record.invoice1              := get_all_trx.trx_number;
                      lr_record.amount_applied1       := ln_remittance_amount;
                      lr_record.trx_date              := get_all_trx.trx_date;
                      lr_record.process_num           := p_process_num;
                    --lr_record.inv_match_status      := 'INVOICE_DATERANGE_MATCHED';
                      lr_record.customer_id           := ln_customer_id;
                      lr_record.auto_cash_status      := 'EXACT_MATCH';
                      lr_record.file_name             := NULL;
                      lr_record.overflow_sequence     := 1;
                      lr_record.overflow_indicator    :='9';

                  put_log_line('TRX number matched - '||get_all_trx.trx_number);  --Testing
                  put_log_line('Date - '||get_all_trx.trx_date);                  --Testing
                       -- -------------------------------------------
                      -- Calling the Create Interface record procedure
                      -- -------------------------------------------
                      lc_error_location := 'Call the Create Interface record Procedure for';
                      create_interface_record ( x_errmsg      =>  lc_errmsg
                                               ,x_retstatus   =>  ln_retcode
                                               ,p_record      =>  lr_record
                                              );

                      IF ln_retcode  = gn_error THEN
                         lc_error_details := lc_error_location||':'|| lc_errmsg;
                         RAISE EX_MAIN_EXCEPTION;
                      END IF;
                      -- -------------------------------------------
                      -- Update the Status for record type '6'
                      -- for Total check amount equal to one invoice amount
                      -- then the status is updated to 'EXACT_ACCOUNT'
                      -- -------------------------------------------
                     lc_error_location := 'Call the Update Status Procedure for Exact Match for Invoice1 record type 6';
                     update_lckb_rec
                     ( x_errmsg                    => lc_errmsg
                      ,x_retstatus                 => ln_retcode
                      ,p_process_num               => p_process_num
                      ,p_record_type               => '6'
                      ,p_inv_match_status          => 'EXACT_MATCH'
                      ,p_rowid                     => get_lockbox_rec.rowid
                     );

                     IF ln_retcode  = gn_error THEN
                       lc_error_details := lc_error_location||':'|| lc_errmsg;
                       RAISE EX_MAIN_EXCEPTION;
                     END IF;
                  END IF;

                --fnd_file.put_line(fnd_file.output,'ln_customer_id:-'||ln_customer_id);
                --fnd_file.put_line(fnd_file.output,'ln_standard_terms:-'||ln_standard_terms);
                --fnd_file.put_line(fnd_file.output,'Deposit Date:-'||get_bai_deposit_dt.deposit_date);
                --fnd_file.put_line(fnd_file.output,'Remittance Amount:-'||lr_record.remittance_amount);
                --fnd_file.put_line(fnd_file.output,'Rowcount:-'||lcu_get_all_trx%ROWCOUNT);

                  --ln_trx_number_count := ln_trx_number_count + 1; Commented for Defect# 4720

                  EXIT WHEN lc_exact_match = 'Y';-- Added for defect# 4720
                  END LOOP;
                  CLOSE lcu_get_all_trx;

                  --ln_trx_number_count := 0;   --Commented for the Defect #4720

               END IF;
      -- -------------------------------------------
      -- Call the Partial Invoice Match Process
      -- -------------------------------------------
           ELSE

              put_log_line('[WIP] Partial Match - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

        -------------------------------------------------
        --Start of changes for CR#684 -- Defect 976
        --Fetch the related Customers for Partial Invoice Match
        -------------------------------------------------
              BEGIN
              ln_custid_count:=1;
                lt_related_custid_type.DELETE;
                 FOR ln_custid_rec IN ( SELECT customer_id
                                              ,sort_order
                                        FROM
                                          (SELECT ln_customer_id            customer_id
                                                 ,1                         sort_order
                                           FROM   dual
                                           UNION ALL
                                           SELECT HCA.cust_account_id      customer_id
                                                 ,2                        sort_order
                                           FROM   hz_relationships HR
                                                 ,hz_cust_accounts HCA
                                           WHERE 1=1
                                           AND HR.object_id                = HCA.party_id
                                           AND HR.subject_id               = ln_party_id
                                           AND NVL(HR.end_date,SYSDATE+1)  > get_bai_deposit_dt.deposit_date
                                           AND HR.status                   = 'A'
                                           AND HR.relationship_type        = 'OD_FIN_PAY_WITHIN'
                                          )
                                        ORDER BY sort_order
                                     )
                 LOOP
                    lt_related_custid_type.EXTEND;
                    lt_related_custid_type(ln_custid_count) := ln_custid_rec.customer_id;
                    ln_custid_count:=ln_custid_count+1;
                 END LOOP;
                 put_log_line('Customer and related customers count ' || (ln_custid_count-1));
              EXCEPTION
              WHEN NO_DATA_FOUND
              THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Related Customer id retreival failed:'||SQLERRM);
              WHEN OTHERS
              THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Related Customer id retreival failed:'||SQLERRM);
              END;
         -------------------------------------------------
         --End of changes for CR#684 -- Defect 976
         -------------------------------------------------

              lcu_trxn_det_tbl.DELETE; -- To Purge Open invoice Pl/SQL table for every '6' record
              put_log_line('Number of Records in global temp table -- ' || gn_global_cnt);
              xx_matched_invoices(NULL,'DELETE',lc_trxn_not_exists);  --To Purge Global Temp Table for every '6' record
              put_log_line('Number of Records in global temp table after every 6 record purge -- ' || gn_global_cnt);
        -- -------------------------------------------
        -- Open the all the 4record type for all the
        -- record type 6 for the corresponding
        -- batch name and item number
        -- -------------------------------------------
              lc_error_location := 'Loop through all the detail records of record type 4 for record type 6';
              OPEN lcu_get_lockbox_det_rec
               (  p_process_number   =>  p_process_num
                 ,p_record_type      =>  '4'
                 ,p_batch_name       =>  get_lockbox_rec.batch_name
                 ,p_item_number      =>  get_lockbox_rec.item_number
               );
              LOOP
              FETCH  lcu_get_lockbox_det_rec INTO  get_lockbox_det_rec;
              EXIT WHEN lcu_get_lockbox_det_rec%NOTFOUND;
          --put_log_line('[WIP] Fetch 4 Rec - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

              lb_inv_match             := FALSE;
              lb_inv_amount_match      := FALSE;
              ln_invoice1_length       := 0;            --Added for the Defect #4720
              ln_invoice2_length       := 0;            --Added for the Defect #4720
              ln_invoice3_length       := 0;            --Added for the Defect #4720
          -- -------------------------------------------
          -- Check the Invoice1 is Exist in Oracle Or Not
          -- -------------------------------------------
              lc_error_location := 'Check the Invoice1 is exist in Oracle or not';
--------------------------------------------------------------
-- Start of Changes for Defect #3983 -- 26-JAN-10
--------------------------------------------------------------
              IF(get_lockbox_det_rec.invoice1 IS NOT NULL) THEN
                 lc_invoice_exists     := 'N';
                 lc_invoice_status     := NULL;
                 lc_consolidated_check := 'N';
                 ln_invoice1_length    := LENGTH(get_lockbox_det_rec.invoice1);  -- Added for Defect #4720 on 16-MAR-10

--------------------------------------------------------------
-- Start of Changes for Defect #4720 -- 16-MAR-10
--------------------------------------------------------------
-- Twelve Digit Check tdc
--------------------------------------------------------------
-- Step  #1 -- Check Length of Invoice greater than equal to 12
--------------------------------------------------------------
                 IF  (ln_invoice1_length >= 11) THEN --NAIT-72199
                     lc_consolidated_check                     := 'N';
                     get_trx_number.trx_number                 := NULL;
                     get_trx_number.acctd_amount_due_remaining := NULL;
                     lc_det_rec_invoice1                       := get_lockbox_det_rec.invoice1;
                     ln_tot_inv_rcv_bnk                        := ln_tot_inv_rcv_bnk + 1;   -- Counter for total invoice recieved from bank
----------------------------------------
-- Step #2 -- Invoice1 Exists in Oracle
----------------------------------------
                     put_log_line('INVOICE1 Length >=11 ' || lc_det_rec_invoice1 || ' ' || TO_CHAR(SYSDATE,'DD-MON-RRRR 
HH24:MI:SS') );
                     OPEN   lcu_get_trx_number_tdc  ( p_trx_number  =>  lc_det_rec_invoice1
                                                    );
                     FETCH  lcu_get_trx_number_tdc  INTO get_trx_number;
                     CLOSE  lcu_get_trx_number_tdc;

                     IF(get_trx_number.trx_number IS NOT NULL) THEN

  -- Start for defect # 4720  4/22/2010

                           lc_invoice_exists     := 'Y';
                           lc_invoice_status     := 'INVOICE_EXISTS';
                           xx_matched_invoices(lc_det_rec_invoice1,'INSERT',lc_trxn_not_exists); --- Added for Defect #2033
                           put_log_line('Invoice1 -- '||lc_det_rec_invoice1||' -- Exists in Oracle');

/*
                        IF((get_bai_deposit_dt.deposit_date <= get_trx_number.due_date)
                                      AND (get_trx_number.term_id IS NOT NULL)
                                    ) THEN
                                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate
(get_trx_number.term_id
                                                                                                       
,get_trx_number.trx_date
                                                                                                       
,get_bai_deposit_dt.deposit_date
                                                                                                        );
                        END IF;

                        ln_amount_applied1  := get_lockbox_det_rec.amount_applied1 / gn_cur_mult_dvd;
                        ln_diff_amount := ROUND((get_trx_number.acctd_amount_due_remaining * (1 - ln_discount_percent / 
100)),2) - ln_amount_applied1;

                        IF ln_diff_amount = 0 THEN
                           lc_invoice_exists     := 'Y';
                           lc_invoice_status     := 'INVOICE_EXISTS';
                           xx_matched_invoices(lc_det_rec_invoice1,'INSERT',lc_trxn_not_exists); --- Added for Defect #2033
                           put_log_line('Invoice1 -- '||lc_det_rec_invoice1||' -- Exists in Oracle');
                        ELSE
                           lc_invoice_exists     := 'N';
                           lc_invoice_status    := NULL;
                        END IF;
*/  -- End for defect # 4720  4/22/2010
                     ELSE
                        lc_invoice_exists     := 'N';
                        lc_invoice_status    := NULL;
                     END IF;

--------------------------------------------------------------
-- END of Changes for Defect #4720 -- 16-MAR-10
--------------------------------------------------------------
-- Nine digit check
--------------------------------------------------------------
-- Step  #1 -- Check Length of Invoice greater than equal to 9
--------------------------------------------------------------
                 ELSIF ((ln_invoice1_length >=9) AND (ln_invoice1_length <= 11)) THEN  -- Changed for defect 4720
                    lc_consolidated_check                     := 'N';
                    get_trx_number.trx_number                 := NULL;
                    get_trx_number.acctd_amount_due_remaining := NULL;
                    lc_det_rec_invoice1                       := get_lockbox_det_rec.invoice1;
                    ln_tot_inv_rcv_bnk                        := ln_tot_inv_rcv_bnk + 1;   -- Counter for total invoice recieved from bank
----------------------------------------
-- Step #2 -- Invoice1 Exists in Oracle
----------------------------------------
                    put_log_line('INVOICE1 Length > 9 ' || lc_det_rec_invoice1 || ' ' || TO_CHAR(SYSDATE,'DD-MON-RRRR 
HH24:MI:SS') );
                    OPEN   lcu_get_trx_number  ( p_trx_number  =>  lc_det_rec_invoice1
                                               );
                    FETCH  lcu_get_trx_number  INTO get_trx_number;
                    CLOSE  lcu_get_trx_number;

                    IF(get_trx_number.trx_number IS NOT NULL) THEN
                         lc_invoice_exists  := 'Y';
                         lc_invoice_status := 'INVOICE_EXISTS';
                         xx_matched_invoices(lc_det_rec_invoice1,'INSERT',lc_trxn_not_exists); --- Added for Defect #2033
                    ELSIF(ln_invoice1_length = 9) THEN  --Added for 4720 on 19-APR-10
--------------------------------------------------------------------------------------------------
-- Step # 3 , 4 -- Suffix ('001' thru '005') to Invoice1 depends on p_back_order_configurable parameter
--------------------------------------------------------------------------------------------------
                         ln_invoice_suffix   := 0;
                         ln_suffix_match_cnt := 0;
                         ln_discount_percent := 0;

                           FOR ln_bo_cnt IN 1..p_back_order_configurable
                           LOOP
                               lc_det_rec_invoice1 := get_lockbox_det_rec.invoice1;
                               ln_invoice_suffix   := ln_invoice_suffix + 1;
                               lc_det_rec_invoice1 := lc_det_rec_invoice1 || lc_zero_suffix || ln_invoice_suffix;
                               put_log_line('Inside Back Order ' || lc_det_rec_invoice1 || ' ' || TO_CHAR(SYSDATE,'DD-MON-
RRRR HH24:MI:SS') );

                               OPEN   lcu_get_trx_number_bo  ( p_trx_number    =>  lc_det_rec_invoice1
                                                          );
                               FETCH  lcu_get_trx_number_bo  INTO get_trx_number;
                               CLOSE  lcu_get_trx_number_bo;

                               IF(get_trx_number.trx_number IS NOT NULL) THEN
                                  IF((get_bai_deposit_dt.deposit_date <= get_trx_number.due_date)
                                      AND (get_trx_number.term_id IS NOT NULL)
                                    ) THEN
                                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate
(get_trx_number.term_id
                                                                                                       
,get_trx_number.trx_date
                                                                                                       
,get_bai_deposit_dt.deposit_date
                                                                                                        );
                                  END IF;
                                    ln_amount_applied1  := get_lockbox_det_rec.amount_applied1 / gn_cur_mult_dvd;
--                                    ln_diff_amount     := ((ln_amount_applied1 * (100 / (100 - ln_discount_percent))) - get_trx_number.acctd_amount_due_remaining);  -- Commented for Defect # 3984
                                      ln_diff_amount := ROUND((get_trx_number.acctd_amount_due_remaining * (1 - ln_discount_percent / 100)),2) - ln_amount_applied1;  -- Added for Defect # 3984

                                    IF ln_diff_amount = 0 THEN
                                       lc_invoice_exists     := 'Y';
                                       lc_invoice_status     := 'BO_INVOICE_EXISTS';
                                       ln_suffix_match_cnt   := ln_suffix_match_cnt + 1;
                                       xx_matched_invoices(lc_det_rec_invoice1,'INSERT',lc_trxn_not_exists); --- Added for Defect #2033
                                       put_log_line('Invoice1 with Suffix -- '||lc_det_rec_invoice1||' -- Exists in Oracle');
                                    ELSE
                                       lc_invoice_exists     := 'N';
                                       lc_invoice_status    := NULL;
                                    END IF;
                               ELSE
                                       lc_invoice_exists     := 'N';
                                       lc_invoice_status    := NULL;
                               END IF;
                               EXIT WHEN ln_suffix_match_cnt = 1;
                           END LOOP;
                    END IF;
                 END IF;
------------------------------------------------------------------------------------
                 IF lc_cons_inv_flag = 'Y' and lc_invoice_exists = 'N' THEN
                       lc_error_location := 'Calling the AS IS Consolidated Match Rule';
                       put_log_line('[BEGIN] AS IS Consolidated Match Rule For Invoice1 - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
                       lc_consolidated_check := 'Y';

                       BEGIN

                           ln_con_invoice1 := TO_NUMBER(get_lockbox_det_rec.invoice1);

                       EXCEPTION

                               WHEN OTHERS THEN
                                   ln_con_invoice1 := 0;
                       END;

                       IF ln_con_invoice1 != 0 THEN

                           ln_amount_applied1  := get_lockbox_det_rec.amount_applied1 / gn_cur_mult_dvd;  --Added for Defect #3983 on 12-FEB-10

                           as_is_consolidated_match_rule
                           ( x_errmsg         =>  lc_errmsg
                            ,x_retstatus      =>  ln_retcode
                            ,x_invoice_exists =>  lc_invoice_exists
                            ,x_invoice_status =>  lc_invoice_status
                            ,p_record         =>  lr_record
                            ,p_term_id        =>  ln_standard_terms
                            ,p_customer_id    =>  ln_customer_id
                            ,p_deposit_date   =>  get_bai_deposit_dt.deposit_date
                            ,p_rowid          =>  get_lockbox_rec.rowid
                            ,p_process_num    =>  get_lockbox_rec.process_num
                            ,p_invoice_num    =>  get_lockbox_det_rec.invoice1
                            ,p_applied_amt    =>  ln_amount_applied1  --Added for Defect #3983 on 12-FEB-10
                           );

                           IF ln_retcode  = gn_error THEN
                            lc_error_location := 'Error at AS IS Consolidated Match Rule: '|| lc_errmsg;
                            RAISE EX_MAIN_EXCEPTION;
                           END IF;
                           put_log_line('[END] AS IS Consolidated Match Rule For Invoice1 - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
                           IF(lc_invoice_exists = 'Y' AND lc_invoice_status IS NOT NULL) THEN
                             EXIT;
                           END IF;
                           ln_con_invoice1 := 0;
                        END IF;
                 END IF;
---------------------------------
-- Update Record Type '6' and '4'
---------------------------------
                 IF( lc_invoice_exists = 'Y' AND lc_invoice_status IS NOT NULL ) THEN
                      IF( lc_consolidated_check = 'N') THEN
---------------------------------
-- Update Inv_match_status - '6'
---------------------------------
                             lc_error_location := 'Call the Update Status Procedure for Invoice Exists for Invoice1 record type 6';
                             update_lckb_rec
                            ( x_errmsg                    => lc_errmsg
                             ,x_retstatus                 => ln_retcode
                             ,p_process_num               => p_process_num
                             ,p_record_type               => '6'
                             ,p_inv_match_status          => lc_inv_match_status --'PARTIAL_INVOICE_AMOUNT_EXISTS'
                             ,p_rowid                     => get_lockbox_rec.rowid
                             );

                            IF ln_retcode  = gn_error THEN
                               lc_error_details := lc_error_location||':'|| lc_errmsg;
                               RAISE EX_MAIN_EXCEPTION;
                            END IF;
--------------------------------
-- Update Invoice1 Status - '4'
--------------------------------
                           lc_error_location := 'Call the Update Status Procedure for Invoice Exists for Invoice1 record type 4';
                           update_lckb_rec
                           ( x_errmsg                    => lc_errmsg
                            ,x_retstatus                 => ln_retcode
                            ,p_process_num               => p_process_num
                            ,p_record_type               => '4'
                            ,p_invoice                   => lc_det_rec_invoice1  -- To Substitute Oracle Invoice or Suffixed Invoice Number
                            ,p_invoice1_2_3              => 'INVOICE1'
                            ,p_invoice1_2_3_status       => lc_invoice_status   -- INVOICE_EXISTS OR BO_INVOICE_EXISTS
                            ,p_rowid                     => get_lockbox_det_rec.rowid
                           );

                           IF ln_retcode  = gn_error THEN
                             lc_error_details := lc_error_location||':'|| lc_errmsg;
                             RAISE EX_MAIN_EXCEPTION;
                           END IF;
---------------------------------------------------------------------
-- Get Invoice details for Back Orders to Print in the Output Section
---------------------------------------------------------------------
                           IF (lc_invoice_status = 'BO_INVOICE_EXISTS') THEN
                               BEGIN
                                  SELECT HCA.account_number
                                    INTO ln_bo_inv_cust_num
                                    FROM hz_cust_accounts   HCA
                                   WHERE HCA.cust_account_id = ln_customer_id;
                               EXCEPTION
                                   WHEN OTHERS THEN
                                     put_log_line('Error @ while deriving Customer number for BO_INVOICE_STATUS Report');
                               END;
                               gt_bo_invoice(gn_bo_count).customer_number    := ln_bo_inv_cust_num;
                               gt_bo_invoice(gn_bo_count).check_number       := get_lockbox_rec.check_number;
                               gt_bo_invoice(gn_bo_count).invoice_number     := get_lockbox_det_rec.invoice1;
                               gt_bo_invoice(gn_bo_count).invoice_amount     := ln_amount_applied1;
                               gt_bo_invoice(gn_bo_count).sub_invoice_number := lc_det_rec_invoice1;
                               gt_bo_invoice(gn_bo_count).sub_invoice_amount := get_trx_number.acctd_amount_due_remaining;
                               gn_bo_count := gn_bo_count + 1;
                               gn_tot_bo_inv_processed := gn_tot_bo_inv_processed + 1;
                           END IF;
                      END IF;
                 ELSE
---------------------------------------------------------------------------------------------------------
-- If Invoices Doesn't Exists in Oracle Even after adding Suffix then proceed Check Digit Position Match
---------------------------------------------------------------------------------------------------------
                    lc_inv_match_status   := 'PARTIAL_INVOICE_AMOUNT_EXISTS';
                    ln_inv_match_counter  := 0;

                    IF(lc_fetched_flag = 'N') THEN
-- Commented for Defect # 4064
/*                     OPEN lcu_get_trx_number ( p_trx_number    =>  NULL);
                       FETCH lcu_get_trx_number BULK COLLECT INTO lcu_trxn_det_tbl;
                       CLOSE lcu_get_trx_number;
*/
-- Start for Defect # 4064
                       put_log_line('[BEGIN] INVOICE1 LCU_GET_TRX_NUMBER_ALL ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
                       OPEN lcu_get_trx_number_all;
                       FETCH lcu_get_trx_number_all BULK COLLECT INTO lcu_trxn_det_tbl;
                       CLOSE lcu_get_trx_number_all;
-- End for Defect # 4064

                       put_log_line('Count of Open Invoices Fetched --  '||lcu_trxn_det_tbl.COUNT || ' ' || TO_CHAR
(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
                       lc_fetched_flag := 'Y';
                    END IF;
----------------------------------------------------------------------
-- Fetch all the Open Invoices of Valid Customer and Related Customers
----------------------------------------------------------------------
                    FOR ln_trxn_cnt IN 1..lcu_trxn_det_tbl.COUNT
                    LOOP

                      ln_diff_amount        := NULL;
                      ln_amount_applied1    := NULL;
                      lb_inv_amount_match   := FALSE;
                      lc_trxn_not_exists    := 'N';        --Added for the Defect #2033

                      IF ((lcu_trxn_det_tbl(ln_trxn_cnt).trx_number IS NOT NULL )
                         AND (lcu_trxn_det_tbl(ln_trxn_cnt).processed_flag = 'N'))  --Added for Defect #2033
                      THEN
----------------------------------------------------------------------
-- Check whether invoice already matched in 12 digit,9 digit,BO Match
-- Added for Defect #2033
----------------------------------------------------------------------
                       xx_matched_invoices(lcu_trxn_det_tbl(ln_trxn_cnt).trx_number,'MATCH',lc_trxn_not_exists);
                       IF(lc_trxn_not_exists = 'Y') THEN
                  -- -------------------------------------------
                  -- Call the function to get the discount
                  -- percent for the each selected transaction
                  -- by passing customer terms and difference
                  -- of bai deposit date and oracle invoice
                  -- transaction date
                  -- -------------------------------------------
                           IF( (get_bai_deposit_dt.deposit_date <= get_trx_number.due_date)
                                AND (get_trx_number.term_id IS NOT NULL)
                             ) THEN
                                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate(get_trx_number.term_id                                                                                                      
,get_trx_number.trx_date
                                                                                                       
,get_bai_deposit_dt.deposit_date
                                                                                                        );
                           END IF;
                              ln_amount_applied1  := get_lockbox_det_rec.amount_applied1 / gn_cur_mult_dvd; --SUBSTR(get_lockbox_det_rec.amount_applied1,1,LENGTH(get_lockbox_det_rec.amount_applied1)-gn_cur_precision)||'.'||SUBSTR(get_lockbox_det_rec.amount_applied1,(LENGTH(get_lockbox_det_rec.amount_applied1)-1));
--                              ln_diff_amount      := ((ln_amount_applied1 * (100 / (100 - ln_discount_percent))) - lcu_trxn_det_tbl(ln_trxn_cnt).acctd_amount_due_remaining);   -- Commented for Defect # 3984
                              ln_diff_amount      := ROUND((lcu_trxn_det_tbl(ln_trxn_cnt).acctd_amount_due_remaining * (1 - ln_discount_percent / 100)),2) - ln_amount_applied1;  -- Added for Defect # 3984
                              IF ln_diff_amount = 0 THEN
                                 lb_inv_amount_match := TRUE;
                              ELSE
                                 lb_inv_amount_match := FALSE;
                              END IF;
-- ---------------------------------------------------------------
-- Call the partial match function check_position_match by passing
-- Oracle Invoice number and BAI Invoice number
-- ---------------------------------------------------------------
                              IF (lb_inv_amount_match) THEN  -- B.Looman: Only call inv match if amts already match
                                  put_log_line('[BEGIN check_position_match]' || get_lockbox_det_rec.invoice1 || ' ' || 
TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
                                  lb_inv_match := check_position_match
                                                            ( p_oracle_invoice      => lcu_trxn_det_tbl
(ln_trxn_cnt).trx_number
                                                             ,p_custom_invoice      => get_lockbox_det_rec.invoice1
                                                             ,p_profile_digit_check => ln_profile_digit_check
                                                            );
                                  put_log_line('[END check_position_match] ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
                              END IF;

                              IF lb_inv_match = TRUE AND lb_inv_amount_match = TRUE THEN
                                    lcu_trxn_det_tbl(ln_trxn_cnt).processed_flag := 'Y';   --Added for Defect #2033
                                    ln_inv_match_counter := ln_inv_match_counter + 1;
                                    put_log_line('ln_inv_match_counter1'||ln_inv_match_counter);
-- -----------------------------------------------------------------------------------
-- Update the Invoice1 xx_ar_payments_interface to Oracle Invoice Number after matcing
-- ------------------------------------------------------------------------------------
                                    lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice1 
record type 4';
                                    update_lckb_rec
                                      ( x_errmsg                    => lc_errmsg
                                       ,x_retstatus                 => ln_retcode
                                       ,p_process_num               => p_process_num
                                       ,p_record_type               => '4'
                                       ,p_invoice                   => lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                                       ,p_invoice1_2_3              => 'INVOICE1'
                                       ,p_invoice1_2_3_status       => 'INVOICE_MATCH'
                                       ,p_rowid                     => get_lockbox_det_rec.rowid
                                      );

                                    IF ln_retcode  = gn_error THEN
                                      lc_error_details := lc_error_location||':'|| lc_errmsg;
                                      RAISE EX_MAIN_EXCEPTION;
                                    END IF;
-- -----------------------------------------------------
-- Update the Invoice Match Status for -- Record Type 6
-- -----------------------------------------------------
                                    lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice1 
record type 6';
                                    update_lckb_rec
                                     ( x_errmsg                    => lc_errmsg
                                      ,x_retstatus                 => ln_retcode
                                      ,p_process_num               => p_process_num
                                      ,p_record_type               => '6'
                                      ,p_inv_match_status          => lc_inv_match_status --'PARTIAL_INVOICE_AMOUNT_EXISTS'
                                      ,p_rowid                     => get_lockbox_rec.rowid
                                     );

                                     IF ln_retcode  = gn_error THEN
                                       lc_error_details := lc_error_location||':'|| lc_errmsg;
                                       RAISE EX_MAIN_EXCEPTION;
                                     END IF;

                                    ln_tot_ora_inv_match  :=  ln_tot_ora_inv_match + 1;    --Counter for Total invoice match wit Oracle Invoice
-- -----------------------------------------------------------------------
-- Call the Print Message Footer Procedure to print the detail transaction
-- -----------------------------------------------------------------------
                                    print_message_footer
                                     ( x_errmsg                 =>  lc_errmsg
                                      ,x_retstatus              =>  ln_retcode
                                      ,p_customer_id            =>  lcu_trxn_det_tbl(ln_trxn_cnt).bill_to_customer_id --Added for CR#684 --Defect #976
                                      ,p_check                  =>  get_lockbox_rec.check_number
                                      ,p_transaction            =>  get_lockbox_det_rec.invoice1
                                      ,p_tran_amount            =>  ln_amount_applied1
                                      ,p_sub_amount             =>  lcu_trxn_det_tbl(ln_trxn_cnt).acctd_amount_due_remaining
                                      ,p_sub_invoice            =>  lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                                     );

                                     IF ln_retcode  = gn_error THEN
                                         lc_error_details := lc_error_location||':'|| lc_errmsg;
                                         RAISE EX_MAIN_EXCEPTION;
                                     END IF;
                                     EXIT;
                              END IF;
                       END IF;     --Added for Defect #2033
                      END IF;
                    END LOOP;
                 END IF;
              END IF;
          -- -------------------------------------------
          -- Check the Invoice2 is Exist in Oracle Or Not
          -- -------------------------------------------
              lc_error_location := 'Check the Invoice2 is exist in Oracle or not';
              IF(get_lockbox_det_rec.invoice2 IS NOT NULL) THEN
                 lc_invoice_exists     := 'N';
                 lc_invoice_status     := NULL;
                 lc_consolidated_check := 'N';
                 ln_invoice2_length    := LENGTH(get_lockbox_det_rec.invoice2);  -- Added for Defect #4720 on 16-MAR-10

--------------------------------------------------------------
-- Start of Changes for Defect #4720 -- 16-MAR-10
--------------------------------------------------------------

-- Twelve Digit Check tdc
--------------------------------------------------------------
-- Step  #1 -- Check Length of Invoice greater than equal to 12
--------------------------------------------------------------
                 IF  (ln_invoice2_length >= 11) THEN --NAIT-72199
                     lc_consolidated_check                     := 'N';
                     get_trx_number.trx_number                 := NULL;
                     get_trx_number.acctd_amount_due_remaining := NULL;
                     lc_det_rec_invoice2                       := get_lockbox_det_rec.invoice2;
                     ln_tot_inv_rcv_bnk                        := ln_tot_inv_rcv_bnk + 1;   -- Counter for total invoice recieved from bank

----------------------------------------
-- Step #2 -- Invoice1 Exists in Oracle
----------------------------------------
                     put_log_line('INVOICE2 Length >=11 ' || lc_det_rec_invoice2 || ' ' || TO_CHAR(SYSDATE,'DD-MON-RRRR 
HH24:MI:SS') );
                     OPEN   lcu_get_trx_number_tdc  ( p_trx_number  =>  lc_det_rec_invoice2
                                                    );
                     FETCH  lcu_get_trx_number_tdc  INTO get_trx_number;
                     CLOSE  lcu_get_trx_number_tdc;

                     IF(get_trx_number.trx_number IS NOT NULL) THEN

  -- Start for Defect # 4720 4/22/2010

                           lc_invoice_exists     := 'Y';
                           lc_invoice_status     := 'INVOICE_EXISTS';
                           xx_matched_invoices(lc_det_rec_invoice2,'INSERT',lc_trxn_not_exists); --- Added for Defect #2033
                           put_log_line('Invoice2 -- '||lc_det_rec_invoice2||' -- Exists in Oracle');

/*
                        IF((get_bai_deposit_dt.deposit_date <= get_trx_number.due_date)
                                      AND (get_trx_number.term_id IS NOT NULL)
                                    ) THEN
                                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate
(get_trx_number.term_id
                                                                                                       
,get_trx_number.trx_date
                                                                                                       
,get_bai_deposit_dt.deposit_date
                                                                                                        );
                        END IF;

                        ln_amount_applied2  := get_lockbox_det_rec.amount_applied2 / gn_cur_mult_dvd;
                        ln_diff_amount := ROUND((get_trx_number.acctd_amount_due_remaining * (1 - ln_discount_percent / 
100)),2) - ln_amount_applied2;

                        IF ln_diff_amount = 0 THEN
                           lc_invoice_exists     := 'Y';
                           lc_invoice_status     := 'INVOICE_EXISTS';
                           xx_matched_invoices(lc_det_rec_invoice2,'INSERT',lc_trxn_not_exists); --- Added for Defect #2033
                           put_log_line('Invoice2 -- '||lc_det_rec_invoice2||' -- Exists in Oracle');
                        ELSE
                           lc_invoice_exists     := 'N';
                           lc_invoice_status    := NULL;
                        END IF;
*/  --End for Defect # 4720 4/22/2010
                     ELSE
                        lc_invoice_exists     := 'N';
                        lc_invoice_status    := NULL;
                     END IF;

--------------------------------------------------------------
-- END of Changes for Defect #4720 -- 16-MAR-10
--------------------------------------------------------------
-- Nine digit check
--------------------------------------------------------------
-- Step  #1 -- Check Length of Invoice greater than equal to 9
--------------------------------------------------------------
                 ELSIF ((ln_invoice2_length >=9) AND (ln_invoice2_length <= 11)) THEN   -- Changed for defect 4720
                    lc_consolidated_check                     := 'N';
                    get_trx_number.trx_number                 := NULL;
                    get_trx_number.acctd_amount_due_remaining := NULL;
                    lc_det_rec_invoice2                       := get_lockbox_det_rec.invoice2;
                    ln_tot_inv_rcv_bnk                        := ln_tot_inv_rcv_bnk + 1;   -- Counter for total invoice recieved from bank

----------------------------------------
-- Step #2 -- Invoice2 Exists in Oracle
----------------------------------------
                    put_log_line('INVOICE2 Length > 9 ' || lc_det_rec_invoice2 || ' ' || TO_CHAR(SYSDATE,'DD-MON-RRRR 
HH24:MI:SS') );
                    OPEN   lcu_get_trx_number  ( p_trx_number  =>  lc_det_rec_invoice2
                                               );
                    FETCH  lcu_get_trx_number  INTO get_trx_number;
                    CLOSE  lcu_get_trx_number;

                    IF(get_trx_number.trx_number IS NOT NULL) THEN
                         lc_invoice_exists  := 'Y';
                         lc_invoice_status := 'INVOICE_EXISTS';
                         xx_matched_invoices(lc_det_rec_invoice2,'INSERT',lc_trxn_not_exists); --- Added for Defect #2033
                    ELSIF(ln_invoice2_length = 9) THEN    ----Added for 4720 on 19-APR-10
--------------------------------------------------------------------------------------------------
-- Step # 3 , 4 -- Suffix ('001' thru '005') to Invoice2 depends on p_back_order_configurable parameter
--------------------------------------------------------------------------------------------------
                         ln_invoice_suffix   := 0;
                         ln_suffix_match_cnt := 0;
                         ln_discount_percent := 0;

                           FOR ln_bo_cnt IN 1..p_back_order_configurable
                           LOOP
                               lc_det_rec_invoice2 := get_lockbox_det_rec.invoice2;
                               ln_invoice_suffix   := ln_invoice_suffix + 1;
                               lc_det_rec_invoice2 := lc_det_rec_invoice2 || lc_zero_suffix || ln_invoice_suffix;
                               put_log_line('Inside Back Order ' || lc_det_rec_invoice2 || ' ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

                               OPEN   lcu_get_trx_number_bo  ( p_trx_number    =>  lc_det_rec_invoice2
                                                          );
                               FETCH  lcu_get_trx_number_bo  INTO get_trx_number;
                               CLOSE  lcu_get_trx_number_bo;

                               IF(get_trx_number.trx_number IS NOT NULL) THEN
                                   IF( (get_bai_deposit_dt.deposit_date <= get_trx_number.due_date)
                                        AND (get_trx_number.term_id IS NOT NULL)
                                     ) THEN
                                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate
(get_trx_number.term_id
                                                                                                       
,get_trx_number.trx_date
                                                                                                       
,get_bai_deposit_dt.deposit_date
                                                                                                 );
                                   END IF;
                                    ln_amount_applied2  := get_lockbox_det_rec.amount_applied2 / gn_cur_mult_dvd;
--                                    ln_diff_amount     := ((ln_amount_applied2 * (100 / (100 - ln_discount_percent))) - get_trx_number.acctd_amount_due_remaining);  -- Commneted for Defect # 3984
                                      ln_diff_amount := ROUND((get_trx_number.acctd_amount_due_remaining * (1 - ln_discount_percent / 100)),2) - ln_amount_applied2;  -- Added for Defect # 3984
                                    IF ln_diff_amount = 0 THEN
                                       lc_invoice_exists     := 'Y';
                                       lc_invoice_status    := 'BO_INVOICE_EXISTS';
                                       ln_suffix_match_cnt   := ln_suffix_match_cnt + 1;
                                       xx_matched_invoices(lc_det_rec_invoice2,'INSERT',lc_trxn_not_exists); --- Added for Defect #2033
                                       put_log_line('Invoice2 with Suffix -- '||lc_det_rec_invoice2||' -- Exists in Oracle');
                                    ELSE
                                       lc_invoice_exists     := 'N';
                                       lc_invoice_status    := NULL;
                                    END IF;
                               ELSE
                                       lc_invoice_exists     := 'N';
                                       lc_invoice_status    := NULL;
                               END IF;
                               EXIT WHEN ln_suffix_match_cnt = 1;
                           END LOOP;
                    END IF;
                END IF;
------------------------------------------------------------------------------------
-- Step  #5 -- Check Invoice1 whose length less than 9 is a Consolidated Bill Number
------------------------------------------------------------------------------------
                 IF lc_cons_inv_flag = 'Y' and lc_invoice_exists = 'N' THEN
                       lc_error_location := 'Calling the AS IS Consolidated Match Rule';
                       put_log_line('[BEGIN] AS IS Consolidated Match Rule For Invoice 2- ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
                       lc_consolidated_check := 'Y';

                       BEGIN

                           ln_con_invoice2 := TO_NUMBER(get_lockbox_det_rec.invoice2);

                       EXCEPTION

                               WHEN OTHERS THEN
                                   ln_con_invoice2 := 0;
                       END;

                       IF ln_con_invoice2 != 0 THEN

                           ln_amount_applied2  := get_lockbox_det_rec.amount_applied2 / gn_cur_mult_dvd;  --Added for Defect #3983 on 12-FEB-10

                           as_is_consolidated_match_rule
                           ( x_errmsg         =>  lc_errmsg
                            ,x_retstatus      =>  ln_retcode
                            ,x_invoice_exists =>  lc_invoice_exists
                            ,x_invoice_status =>  lc_invoice_status
                            ,p_record         =>  lr_record
                            ,p_term_id        =>  ln_standard_terms
                            ,p_customer_id    =>  ln_customer_id
                            ,p_deposit_date   =>  get_bai_deposit_dt.deposit_date
                            ,p_rowid          =>  get_lockbox_rec.rowid
                            ,p_process_num    =>  get_lockbox_rec.process_num
                            ,p_invoice_num    =>  get_lockbox_det_rec.invoice2
                            ,p_applied_amt    =>  ln_amount_applied2  --Added for Defect #3983 on 12-FEB-10
                           );
                          IF ln_retcode  = gn_error THEN
                             lc_error_location := 'Error at AS IS Consolidated Match Rule : '|| lc_errmsg;
                             RAISE EX_MAIN_EXCEPTION;
                          END IF;
                          put_log_line('[END] AS IS Consolidated Match Rule For Invoice2 - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR 
HH24:MI:SS') );
                          IF(lc_invoice_exists = 'Y' AND lc_invoice_status IS NOT NULL) THEN
                          EXIT;
                          END IF;
                           ln_con_invoice2 := 0;
                        END IF;
                 END IF;

---------------------------------
-- Update Record Type '6' and '4'
---------------------------------
                 IF(lc_invoice_exists = 'Y' AND lc_invoice_status IS NOT NULL ) THEN
                      IF( lc_consolidated_check = 'N') THEN
---------------------------
-- Update Inv_match_status
---------------------------
                             lc_error_location := 'Call the Update Status Procedure for Invoice Exists for Invoice2 record 
type 6';
                             update_lckb_rec
                            ( x_errmsg                    => lc_errmsg
                             ,x_retstatus                 => ln_retcode
                             ,p_process_num               => p_process_num
                             ,p_record_type               => '6'
                             ,p_inv_match_status          => lc_inv_match_status --'PARTIAL_INVOICE_AMOUNT_EXISTS'
                             ,p_rowid                     => get_lockbox_rec.rowid
                             );

                            IF ln_retcode  = gn_error THEN
                               lc_error_details := lc_error_location||':'|| lc_errmsg;
                               RAISE EX_MAIN_EXCEPTION;
                            END IF;
--------------------------
-- Update Invoice2 Status
--------------------------
                            lc_error_location := 'Call the Update Status Procedure for Invoice Exists for Invoice2 record 
type 4';
                            update_lckb_rec
                            ( x_errmsg                    => lc_errmsg
                             ,x_retstatus                 => ln_retcode
                             ,p_process_num               => p_process_num
                             ,p_record_type               => '4'
                             ,p_invoice                   => lc_det_rec_invoice2  -- To Substitute Oracle Invoice or Suffixed Invoice Number
                             ,p_invoice1_2_3              => 'INVOICE2'
                             ,p_invoice1_2_3_status       => lc_invoice_status   -- INVOICE_EXISTS OR BO_INVOICE_EXISTS
                             ,p_rowid                     => get_lockbox_det_rec.rowid
                            );

                           IF ln_retcode  = gn_error THEN
                             lc_error_details := lc_error_location||':'|| lc_errmsg;
                             RAISE EX_MAIN_EXCEPTION;
                           END IF;
---------------------------------------------------------------------
-- Get Invoice details for Back Orders to Print in the Output Section
---------------------------------------------------------------------
                           IF (lc_invoice_status = 'BO_INVOICE_EXISTS') THEN

                               BEGIN
                                  SELECT HCA.account_number
                                    INTO ln_bo_inv_cust_num
                                    FROM hz_cust_accounts   HCA
                                   WHERE HCA.cust_account_id = ln_customer_id;
                               EXCEPTION
                                   WHEN OTHERS THEN
                                     put_log_line('Error @ while deriving Customer number for BO_INVOICE_STATUS Report');
                               END;

                               gt_bo_invoice(gn_bo_count).customer_number    := ln_bo_inv_cust_num;
                               gt_bo_invoice(gn_bo_count).check_number       := get_lockbox_rec.check_number;
                               gt_bo_invoice(gn_bo_count).invoice_number     := get_lockbox_det_rec.invoice2;
                               gt_bo_invoice(gn_bo_count).invoice_amount     := ln_amount_applied2;
                               gt_bo_invoice(gn_bo_count).sub_invoice_number := lc_det_rec_invoice2;
                               gt_bo_invoice(gn_bo_count).sub_invoice_amount := get_trx_number.acctd_amount_due_remaining;
                               gn_bo_count := gn_bo_count + 1;
                               gn_tot_bo_inv_processed := gn_tot_bo_inv_processed + 1;
                           END IF;
                      END IF;
                 ELSE
-----------------------------
-- Call Partial Invoice Match
-----------------------------
                    lc_inv_match_status   := 'PARTIAL_INVOICE_AMOUNT_EXISTS';
                    ln_inv_match_counter  := 0;
                    IF(lc_fetched_flag = 'N') THEN
 --Commented for Defect # 4064
/*                     OPEN lcu_get_trx_number ( p_trx_number    =>  NULL);
                       FETCH lcu_get_trx_number BULK COLLECT INTO lcu_trxn_det_tbl;
                       CLOSE lcu_get_trx_number;
*/
 --Start for Defect # 4064
                       put_log_line('[BEGIN] INVOICE2 LCU_GET_TRX_NUMBER_ALL ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
                       OPEN lcu_get_trx_number_all;
                       FETCH lcu_get_trx_number_all BULK COLLECT INTO lcu_trxn_det_tbl;
                       CLOSE lcu_get_trx_number_all;
 --End for Defect # 4064

                       put_log_line('Count of Open Invoices Fetched --  '||lcu_trxn_det_tbl.COUNT || ' ' || TO_CHAR
(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
                       lc_fetched_flag := 'Y';
                    END IF;
----------------------------------------------------------------------
-- Fetch all the Open Invoices of Valid Customer and Related Customers
----------------------------------------------------------------------
                    FOR ln_trxn_cnt IN 1..lcu_trxn_det_tbl.COUNT
                    LOOP

                      ln_diff_amount        := NULL;
                      ln_amount_applied2    := NULL;
                      lb_inv_amount_match   := FALSE;
                      lc_trxn_not_exists    := 'N';        --Added for the Defect #2033

                      IF ((lcu_trxn_det_tbl(ln_trxn_cnt).trx_number IS NOT NULL)
                         AND (lcu_trxn_det_tbl(ln_trxn_cnt).processed_flag = 'N'))  --Added for Defect #2033
                      THEN
----------------------------------------------------------------------
-- Check whether invoice already matched in 12 digit,9 digit,BO Match
-- Added for Defect #2033
----------------------------------------------------------------------
                       xx_matched_invoices(lcu_trxn_det_tbl(ln_trxn_cnt).trx_number,'MATCH',lc_trxn_not_exists);
                       IF(lc_trxn_not_exists = 'Y') THEN
                  -- -------------------------------------------
                  -- Call the function to get the discount
                  -- percent for the each selected transaction
                  -- by passing customer terms and difference
                  -- of bai deposit date and oracle invoice
                  -- transaction date
                  -- -------------------------------------------
                           IF( (get_bai_deposit_dt.deposit_date <= get_trx_number.due_date)
                                AND (get_trx_number.term_id IS NOT NULL)
                             ) THEN
                                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate
(get_trx_number.term_id
                                                                                                       
,get_trx_number.trx_date
                                                                                                       
,get_bai_deposit_dt.deposit_date
                                                                                                        );
                           END IF;
                              ln_amount_applied2  := get_lockbox_det_rec.amount_applied2 / gn_cur_mult_dvd; --SUBSTR(get_lockbox_det_rec.amount_applied1,1,LENGTH(get_lockbox_det_rec.amount_applied1)-gn_cur_precision)||'.'||SUBSTR(get_lockbox_det_rec.amount_applied1,(LENGTH(get_lockbox_det_rec.amount_applied1)-1));
--                              ln_diff_amount      := ((ln_amount_applied2 * (100 / (100 - ln_discount_percent))) - lcu_trxn_det_tbl(ln_trxn_cnt).acctd_amount_due_remaining);  -- Commented for Defect # 3984
                                ln_diff_amount := ROUND((lcu_trxn_det_tbl(ln_trxn_cnt).acctd_amount_due_remaining * (1 - ln_discount_percent / 100)),2) - ln_amount_applied2;  -- Added for Defect # 3984
                              IF ln_diff_amount = 0 THEN
                                 lb_inv_amount_match := TRUE;
                              ELSE
                                 lb_inv_amount_match := FALSE;
                              END IF;
-- ---------------------------------------------------------------
-- Call the partial match function check_position_match by passing
-- Oracle Invoice number and BAI Invoice number
-- ---------------------------------------------------------------
                              IF (lb_inv_amount_match) THEN  -- B.Looman: Only call inv match if amts already match
                                  put_log_line('[BEGIN check_position_match]' || get_lockbox_det_rec.invoice2 || ' ' || 
TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
                                  lb_inv_match := check_position_match
                                                            ( p_oracle_invoice      => lcu_trxn_det_tbl
(ln_trxn_cnt).trx_number
                                                             ,p_custom_invoice      => get_lockbox_det_rec.invoice2
                                                             ,p_profile_digit_check => ln_profile_digit_check
                                                            );
                                  put_log_line('[END check_position_match] ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
                              END IF;

                              IF lb_inv_match = TRUE AND lb_inv_amount_match = TRUE THEN
                                    lcu_trxn_det_tbl(ln_trxn_cnt).processed_flag := 'Y';   --Added for Defect #2033
                                    ln_inv_match_counter := ln_inv_match_counter + 1;
                                    put_log_line('ln_inv_match_counter2'||ln_inv_match_counter);
-- -----------------------------------------------------------------------------------
-- Update the Invoice2 xx_ar_payments_interface to Oracle Invoice Number after matcing
-- ------------------------------------------------------------------------------------
                                    lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice2 
record type 4';
                                    update_lckb_rec
                                      ( x_errmsg                    => lc_errmsg
                                       ,x_retstatus                 => ln_retcode
                                       ,p_process_num               => p_process_num
                                       ,p_record_type               => '4'
                                       ,p_invoice                   => lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                                       ,p_invoice1_2_3              => 'INVOICE2'
                                       ,p_invoice1_2_3_status       => 'INVOICE_MATCH'
                                       ,p_rowid                     => get_lockbox_det_rec.rowid
                                      );

                                    IF ln_retcode  = gn_error THEN
                                      lc_error_details := lc_error_location||':'|| lc_errmsg;
                                      RAISE EX_MAIN_EXCEPTION;
                                    END IF;
-- -----------------------------------------------------
-- Update the Invoice Match Status for -- Record Type 6
-- -----------------------------------------------------
                                    lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice2 
record type 6';
                                    update_lckb_rec
                                     ( x_errmsg                    => lc_errmsg
                                      ,x_retstatus                 => ln_retcode
                                      ,p_process_num               => p_process_num
                                      ,p_record_type               => '6'
                                      ,p_inv_match_status          => lc_inv_match_status --'PARTIAL_INVOICE_AMOUNT_EXISTS'
                                      ,p_rowid                     => get_lockbox_rec.rowid
                                     );

                                     IF ln_retcode  = gn_error THEN
                                       lc_error_details := lc_error_location||':'|| lc_errmsg;
                                       RAISE EX_MAIN_EXCEPTION;
                                     END IF;

                                    ln_tot_ora_inv_match  :=  ln_tot_ora_inv_match + 1;  --Counter for Total invoice match wit Oracle Invoice
-- -----------------------------------------------------------------------
-- Call the Print Message Footer Procedure to print the detail transaction
-- -----------------------------------------------------------------------
                                    print_message_footer
                                     ( x_errmsg                 =>  lc_errmsg
                                      ,x_retstatus              =>  ln_retcode
                                      ,p_customer_id            =>  lcu_trxn_det_tbl(ln_trxn_cnt).bill_to_customer_id --Added for CR#684 --Defect #976
                                      ,p_check                  =>  get_lockbox_rec.check_number
                                      ,p_transaction            =>  get_lockbox_det_rec.invoice2
                                      ,p_tran_amount            =>  ln_amount_applied2
                                      ,p_sub_amount             =>  lcu_trxn_det_tbl(ln_trxn_cnt).acctd_amount_due_remaining
                                      ,p_sub_invoice            =>  lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                                     );

                                     IF ln_retcode  = gn_error THEN
                                         lc_error_details := lc_error_location||':'|| lc_errmsg;
                                         RAISE EX_MAIN_EXCEPTION;
                                     END IF;
                                     EXIT;
                              END IF;
                       END IF;   --Added for Defect #2033
                      END IF;
                    END LOOP;
                 END IF;
              END IF;
          -- -------------------------------------------
          -- Check the Invoice3 is Exist in Oracle Or Not
          -- -------------------------------------------
              lc_error_location := 'Check the Invoice3 is exist in Oracle or not';
              IF(get_lockbox_det_rec.invoice3 IS NOT NULL) THEN
                 lc_invoice_exists     := 'N';
                 lc_invoice_status     := NULL;
                 lc_consolidated_check := 'N';
                 ln_invoice3_length    := LENGTH(get_lockbox_det_rec.invoice3);  -- Added for Defect #4720 on 16-MAR-10

--------------------------------------------------------------
-- Start of Changes for Defect #4720 -- 16-MAR-10
--------------------------------------------------------------
-- Twelve Digit Check tdc
--------------------------------------------------------------
-- Step  #1 -- Check Length of Invoice greater than equal to 12
--------------------------------------------------------------
                 IF  (ln_invoice3_length >= 11) THEN --NAIT-72199
                     lc_consolidated_check                     := 'N';
                     get_trx_number.trx_number                 := NULL;
                     get_trx_number.acctd_amount_due_remaining := NULL;
                     lc_det_rec_invoice3                       := get_lockbox_det_rec.invoice3;
                     ln_tot_inv_rcv_bnk                        := ln_tot_inv_rcv_bnk + 1;   -- Counter for total invoice recieved from bank

----------------------------------------
-- Step #2 -- Invoice1 Exists in Oracle
----------------------------------------
                     put_log_line('INVOICE3 Length >=11 ' || lc_det_rec_invoice3 || ' ' || TO_CHAR(SYSDATE,'DD-MON-RRRR 
HH24:MI:SS') );
                     OPEN   lcu_get_trx_number_tdc  ( p_trx_number  =>  lc_det_rec_invoice3
                                                    );
                     FETCH  lcu_get_trx_number_tdc  INTO get_trx_number;
                     CLOSE  lcu_get_trx_number_tdc;

                     IF(get_trx_number.trx_number IS NOT NULL) THEN

-- Start for Defect # 4720 4/22/2010
                           lc_invoice_exists     := 'Y';
                           lc_invoice_status     := 'INVOICE_EXISTS';
                           xx_matched_invoices(lc_det_rec_invoice3,'INSERT',lc_trxn_not_exists); --- Added for Defect #2033
                           put_log_line('Invoice3 -- '||lc_det_rec_invoice3||' -- Exists in Oracle');
/*
                        IF((get_bai_deposit_dt.deposit_date <= get_trx_number.due_date)
                                      AND (get_trx_number.term_id IS NOT NULL)
                                    ) THEN
                                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate
(get_trx_number.term_id
                                                                                                       
,get_trx_number.trx_date
                                                                                                       
,get_bai_deposit_dt.deposit_date
                                                                                                        );
                        END IF;

                        ln_amount_applied3  := get_lockbox_det_rec.amount_applied3 / gn_cur_mult_dvd;
                        ln_diff_amount := ROUND((get_trx_number.acctd_amount_due_remaining * (1 - ln_discount_percent / 
100)),2) - ln_amount_applied3;

                        IF ln_diff_amount = 0 THEN
                           lc_invoice_exists     := 'Y';
                           lc_invoice_status     := 'INVOICE_EXISTS';
                           xx_matched_invoices(lc_det_rec_invoice3,'INSERT',lc_trxn_not_exists); --- Added for Defect #2033
                           put_log_line('Invoice3 -- '||lc_det_rec_invoice3||' -- Exists in Oracle');
                        ELSE
                           lc_invoice_exists     := 'N';
                           lc_invoice_status    := NULL;
                        END IF;
*/ -- End for Defect # 4720  4/22/2010
                     ELSE
                        lc_invoice_exists     := 'N';
                        lc_invoice_status    := NULL;
                     END IF;

--------------------------------------------------------------
-- END of Changes for Defect #4720 -- 16-MAR-10
--------------------------------------------------------------
-- Nine digit check
--------------------------------------------------------------
-- Step  #1 -- Check Length of Invoice greater than equal to 9
--------------------------------------------------------------
                 ELSIF ((ln_invoice3_length >=9) AND (ln_invoice3_length <= 11)) THEN -- Changed for defect 4720
                    lc_consolidated_check                     := 'N';
                    get_trx_number.trx_number                 := NULL;
                    get_trx_number.acctd_amount_due_remaining := NULL;
                    lc_det_rec_invoice3                       := get_lockbox_det_rec.invoice3;
                    ln_tot_inv_rcv_bnk                        := ln_tot_inv_rcv_bnk + 1;   -- Counter for total invoice recieved from bank

----------------------------------------
-- Step #2 -- Invoice3 Exists in Oracle
----------------------------------------
                    put_log_line('INVOICE3 Length > 9 ' || lc_det_rec_invoice3 || ' ' || TO_CHAR(SYSDATE,'DD-MON-RRRR 
HH24:MI:SS') );
                    OPEN   lcu_get_trx_number  ( p_trx_number  =>  lc_det_rec_invoice3
                                               );
                    FETCH  lcu_get_trx_number  INTO get_trx_number;
                    CLOSE  lcu_get_trx_number;

                    IF(get_trx_number.trx_number IS NOT NULL) THEN
                         lc_invoice_exists  := 'Y';
                         lc_invoice_status := 'INVOICE_EXISTS';
                         xx_matched_invoices(lc_det_rec_invoice3,'INSERT',lc_trxn_not_exists); --- Added for Defect #2033
                    ELSIF(ln_invoice3_length = 9) THEN    ----Added for 4720 on 19-APR-10
--------------------------------------------------------------------------------------------------
-- Step # 3 , 4 -- Suffix ('001' thru '005') to Invoice3 depends on p_back_order_configurable parameter
--------------------------------------------------------------------------------------------------
                         ln_invoice_suffix   := 0;
                         ln_suffix_match_cnt := 0;
                         ln_discount_percent := 0;

                           FOR ln_bo_cnt IN 1..p_back_order_configurable
                           LOOP
                               lc_det_rec_invoice3 := get_lockbox_det_rec.invoice3;
                               ln_invoice_suffix   := ln_invoice_suffix + 1;
                               lc_det_rec_invoice3 := lc_det_rec_invoice3 || lc_zero_suffix || ln_invoice_suffix;
                               put_log_line('Inside Back Order ' || lc_det_rec_invoice3 || ' ' || TO_CHAR(SYSDATE,'DD-MON-
RRRR HH24:MI:SS') );

                               OPEN   lcu_get_trx_number_bo  ( p_trx_number    =>  lc_det_rec_invoice3
                                                          );
                               FETCH  lcu_get_trx_number_bo  INTO get_trx_number;
                               CLOSE  lcu_get_trx_number_bo;

                               IF(get_trx_number.trx_number IS NOT NULL) THEN
                                   IF( (get_bai_deposit_dt.deposit_date <= get_trx_number.due_date)
                                         AND (get_trx_number.term_id IS NOT NULL)
                                     ) THEN
                                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate
(get_trx_number.term_id
                                                                                                       
,get_trx_number.trx_date
                                                                                                       
,get_bai_deposit_dt.deposit_date
                                                                                                        );
                                   END IF;
                                    ln_amount_applied3  := get_lockbox_det_rec.amount_applied3 / gn_cur_mult_dvd;
--                                    ln_diff_amount     := ((ln_amount_applied3 * (100 / (100 - ln_discount_percent))) - get_trx_number.acctd_amount_due_remaining);  -- Commnted for Defect # 3984
                                    ln_diff_amount := ROUND((get_trx_number.acctd_amount_due_remaining * (1 - ln_discount_percent / 100)),2) - ln_amount_applied3;  -- Added for Defect # 3984
                                    IF ln_diff_amount = 0 THEN
                                       lc_invoice_exists     := 'Y';
                                       lc_invoice_status    := 'BO_INVOICE_EXISTS';
                                       ln_suffix_match_cnt   := ln_suffix_match_cnt + 1;
                                       xx_matched_invoices(lc_det_rec_invoice3,'INSERT',lc_trxn_not_exists); --- Added for Defect #2033
                                       put_log_line('Invoice3 with Suffix -- '||lc_det_rec_invoice3||' -- Exists in Oracle');
                                    ELSE
                                       lc_invoice_exists     := 'N';
                                       lc_invoice_status    := NULL;
                                    END IF;
                               ELSE
                                       lc_invoice_exists     := 'N';
                                       lc_invoice_status    := NULL;
                               END IF;
                               EXIT WHEN ln_suffix_match_cnt = 1;
                           END LOOP;
                    END IF;
                 END IF;
------------------------------------------------------------------------------------
-- Step  #5 -- Check Invoice3 whose length less than 9 is a Consolidated Bill Number
------------------------------------------------------------------------------------
                 IF lc_cons_inv_flag = 'Y' and lc_invoice_exists = 'N' THEN
                       lc_error_location := 'Calling the AS IS Consolidated Match Rule';
                       put_log_line('[BEGIN] AS IS Consolidated Match Rule For Invoice 3 - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR 
HH24:MI:SS') );
                       lc_consolidated_check := 'Y';

                       BEGIN

                           ln_con_invoice3 := TO_NUMBER(get_lockbox_det_rec.invoice3);

                       EXCEPTION

                               WHEN OTHERS THEN
                                   ln_con_invoice3 := 0;
                       END;

                       IF ln_con_invoice3 != 0 THEN
                           ln_amount_applied3  := get_lockbox_det_rec.amount_applied3 / gn_cur_mult_dvd;  --Added for Defect #3983 on 12-FEB-10

                           as_is_consolidated_match_rule
                           ( x_errmsg         =>  lc_errmsg
                            ,x_retstatus      =>  ln_retcode
                            ,x_invoice_exists =>  lc_invoice_exists
                            ,x_invoice_status =>  lc_invoice_status
                            ,p_record         =>  lr_record
                            ,p_term_id        =>  ln_standard_terms
                            ,p_customer_id    =>  ln_customer_id
                            ,p_deposit_date   =>  get_bai_deposit_dt.deposit_date
                            ,p_rowid          =>  get_lockbox_rec.rowid
                            ,p_process_num    =>  get_lockbox_rec.process_num
                            ,p_invoice_num    =>  get_lockbox_det_rec.invoice3
                            ,p_applied_amt    =>  ln_amount_applied3  --Added for Defect #3983 on 12-FEB-10
                           );
                            IF ln_retcode  = gn_error THEN
                              lc_error_location := 'Error at AS IS Consolidated Match Rule : '|| lc_errmsg;
                              RAISE EX_MAIN_EXCEPTION;
                            END IF;
                            put_log_line('[END] AS IS Consolidated Match Rule For Invoice 3 - ' || TO_CHAR(SYSDATE,'DD-MON-
RRRR HH24:MI:SS') );
                            IF(lc_invoice_exists = 'Y' AND lc_invoice_status IS NOT NULL) THEN
                             EXIT;
                            END IF;
                           ln_con_invoice3 := 0;
                        END IF;
                 END IF;
---------------------------------
-- Update Record Type '6' and '4'
---------------------------------
                 IF( lc_invoice_exists = 'Y' AND lc_invoice_status IS NOT NULL ) THEN
                     IF( lc_consolidated_check = 'N' ) THEN
---------------------------
-- Update Inv_match_status
---------------------------
                             lc_error_location := 'Call the Update Status Procedure for Invoice Exists for Invoice3 record 
type 6';
                             update_lckb_rec
                            ( x_errmsg                    => lc_errmsg
                             ,x_retstatus                 => ln_retcode
                             ,p_process_num               => p_process_num
                             ,p_record_type               => '6'
                             ,p_inv_match_status          => lc_inv_match_status --'PARTIAL_INVOICE_AMOUNT_EXISTS'
                             ,p_rowid                     => get_lockbox_rec.rowid
                             );

                            IF ln_retcode  = gn_error THEN
                               lc_error_details := lc_error_location||':'|| lc_errmsg;
                               RAISE EX_MAIN_EXCEPTION;
                            END IF;
--------------------------
-- Update Invoice3 Status
--------------------------
                           lc_error_location := 'Call the Update Status Procedure for Invoice Exists for Invoice3 record type 
4';
                           update_lckb_rec
                           ( x_errmsg                    => lc_errmsg
                            ,x_retstatus                 => ln_retcode
                            ,p_process_num               => p_process_num
                            ,p_record_type               => '4'
                            ,p_invoice                   => lc_det_rec_invoice3  -- To Substitute Oracle Invoice or Suffixed Invoice Number
                            ,p_invoice1_2_3              => 'INVOICE3'
                            ,p_invoice1_2_3_status       => lc_invoice_status   -- INVOICE_EXISTS OR BO_INVOICE_EXISTS
                            ,p_rowid                     => get_lockbox_det_rec.rowid
                           );

                           IF ln_retcode  = gn_error THEN
                             lc_error_details := lc_error_location||':'|| lc_errmsg;
                             RAISE EX_MAIN_EXCEPTION;
                           END IF;
---------------------------------------------------------------------
-- Get Invoice details for Back Orders to Print in the Output Section
---------------------------------------------------------------------
                           IF (lc_invoice_status = 'BO_INVOICE_EXISTS') THEN

                               BEGIN
                                  SELECT HCA.account_number
                                    INTO ln_bo_inv_cust_num
                                    FROM hz_cust_accounts   HCA
                                   WHERE HCA.cust_account_id = ln_customer_id;
                               EXCEPTION
                                   WHEN OTHERS THEN
                                     put_log_line('Error @ while deriving Customer number for BO_INVOICE_STATUS Report');
                               END;

                               gt_bo_invoice(gn_bo_count).customer_number    := ln_bo_inv_cust_num;
                               gt_bo_invoice(gn_bo_count).check_number       := get_lockbox_rec.check_number;
                               gt_bo_invoice(gn_bo_count).invoice_number     := get_lockbox_det_rec.invoice3;
                               gt_bo_invoice(gn_bo_count).invoice_amount     := ln_amount_applied3;
                               gt_bo_invoice(gn_bo_count).sub_invoice_number := lc_det_rec_invoice3;
                               gt_bo_invoice(gn_bo_count).sub_invoice_amount := get_trx_number.acctd_amount_due_remaining;
                               gn_bo_count := gn_bo_count + 1;
                               gn_tot_bo_inv_processed := gn_tot_bo_inv_processed + 1;
                           END IF;
                     END IF;
                 ELSE
-----------------------------
-- Call Partial Invoice Match
-----------------------------
                    lc_inv_match_status   := 'PARTIAL_INVOICE_AMOUNT_EXISTS';
                    ln_inv_match_counter  := 0;
                    IF(lc_fetched_flag = 'N') THEN
-- Commented for Defect # 4064
/*                     OPEN lcu_get_trx_number ( p_trx_number    =>  NULL);
                       FETCH lcu_get_trx_number BULK COLLECT INTO lcu_trxn_det_tbl;
                       CLOSE lcu_get_trx_number;
*/
-- Start for Defect # 4064
                       put_log_line('[BEGIN] INVOICE3 LCU_GET_TRX_NUMBER_ALL ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
                       OPEN lcu_get_trx_number_all;
                       FETCH lcu_get_trx_number_all BULK COLLECT INTO lcu_trxn_det_tbl;
                       CLOSE lcu_get_trx_number_all;
-- End for Defect # 4064

                       put_log_line('Count of Open Invoices Fetched --  '||lcu_trxn_det_tbl.COUNT || ' ' || TO_CHAR
(SYSDATE,'DD-MON-RRRR HH24:MI:SS'));
                       lc_fetched_flag := 'Y';
                    END IF;
----------------------------------------------------------------------
-- Fetch all the Open Invoices of Valid Customer and Related Customers
----------------------------------------------------------------------
                    FOR ln_trxn_cnt IN 1..lcu_trxn_det_tbl.COUNT
                    LOOP

                      ln_diff_amount        := NULL;
                      ln_amount_applied3    := NULL;
                      lb_inv_amount_match   := FALSE;
                      lc_trxn_not_exists    := 'N';        --Added for the Defect #2033
                      IF ((lcu_trxn_det_tbl(ln_trxn_cnt).trx_number IS NOT NULL)
                         AND (lcu_trxn_det_tbl(ln_trxn_cnt).processed_flag = 'N'))  --Added for Defect #2033
                      THEN
----------------------------------------------------------------------
-- Check whether invoice already matched in 12 digit,9 digit,BO Match
-- Added for Defect #2033
----------------------------------------------------------------------
                       xx_matched_invoices(lcu_trxn_det_tbl(ln_trxn_cnt).trx_number,'MATCH',lc_trxn_not_exists);
                       IF(lc_trxn_not_exists = 'Y') THEN
                  -- -------------------------------------------
                  -- Call the function to get the discount
                  -- percent for the each selected transaction
                  -- by passing customer terms and difference
                  -- of bai deposit date and oracle invoice
                  -- transaction date
                  -- -------------------------------------------
                           IF( (get_bai_deposit_dt.deposit_date <= get_trx_number.due_date)
                                AND (get_trx_number.term_id IS NOT NULL)
                             ) THEN
                                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate
(get_trx_number.term_id
                                                                                                       
,get_trx_number.trx_date
                                                                                                       
,get_bai_deposit_dt.deposit_date
                                                                                                        );
                           END IF;
                              ln_amount_applied3  := get_lockbox_det_rec.amount_applied3 / gn_cur_mult_dvd; --SUBSTR(get_lockbox_det_rec.amount_applied1,1,LENGTH(get_lockbox_det_rec.amount_applied1)-gn_cur_precision)||'.'||SUBSTR(get_lockbox_det_rec.amount_applied1,(LENGTH(get_lockbox_det_rec.amount_applied1)-1));
--                              ln_diff_amount      := ((ln_amount_applied3 * (100 / (100 - ln_discount_percent))) - lcu_trxn_det_tbl(ln_trxn_cnt).acctd_amount_due_remaining);
                              ln_diff_amount := ROUND((lcu_trxn_det_tbl(ln_trxn_cnt).acctd_amount_due_remaining * (1 - 
ln_discount_percent / 100)),2) - ln_amount_applied3;  -- Added for Defect # 3984
                              IF ln_diff_amount = 0 THEN
                                 lb_inv_amount_match := TRUE;
                              ELSE
                                 lb_inv_amount_match := FALSE;
                              END IF;
-- ---------------------------------------------------------------
-- Call the partial match function check_position_match by passing
-- Oracle Invoice number and BAI Invoice number
-- ---------------------------------------------------------------
                              IF (lb_inv_amount_match) THEN  -- B.Looman: Only call inv match if amts already match
                                  put_log_line('[BEGIN check_position_match]' || get_lockbox_det_rec.invoice3 || ' ' || 
TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
                                  lb_inv_match := check_position_match
                                                            ( p_oracle_invoice      => lcu_trxn_det_tbl
(ln_trxn_cnt).trx_number
                                                             ,p_custom_invoice      => get_lockbox_det_rec.invoice3
                                                             ,p_profile_digit_check => ln_profile_digit_check
                                                            );
                                  put_log_line('[END check_position_match] ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
                              END IF;

                              IF lb_inv_match = TRUE AND lb_inv_amount_match = TRUE THEN
                                    lcu_trxn_det_tbl(ln_trxn_cnt).processed_flag := 'Y';    --Added for Defect #2033
                                    ln_inv_match_counter := ln_inv_match_counter + 1;
                                    put_log_line('ln_inv_match_counter3'||ln_inv_match_counter);
-- -----------------------------------------------------------------------------------
-- Update the Invoice3 xx_ar_payments_interface to Oracle Invoice Number after matcing
-- ------------------------------------------------------------------------------------
                                    lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice3 
record type 4';
                                    update_lckb_rec
                                      ( x_errmsg                    => lc_errmsg
                                       ,x_retstatus                 => ln_retcode
                                       ,p_process_num               => p_process_num
                                       ,p_record_type               => '4'
                                       ,p_invoice                   => lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                                       ,p_invoice1_2_3              => 'INVOICE3'
                                       ,p_invoice1_2_3_status       => 'INVOICE_MATCH'
                                       ,p_rowid                     => get_lockbox_det_rec.rowid
                                      );

                                    IF ln_retcode  = gn_error THEN
                                      lc_error_details := lc_error_location||':'|| lc_errmsg;
                                      RAISE EX_MAIN_EXCEPTION;
                                    END IF;
-- -----------------------------------------------------
-- Update the Invoice Match Status for -- Record Type 6
-- -----------------------------------------------------
                                    lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice3 
record type 6';
                                    update_lckb_rec
                                     ( x_errmsg                    => lc_errmsg
                                      ,x_retstatus                 => ln_retcode
                                      ,p_process_num               => p_process_num
                                      ,p_record_type               => '6'
                                      ,p_inv_match_status          => lc_inv_match_status --'PARTIAL_INVOICE_AMOUNT_EXISTS'
                                      ,p_rowid                     => get_lockbox_rec.rowid
                                     );

                                     IF ln_retcode  = gn_error THEN
                                       lc_error_details := lc_error_location||':'|| lc_errmsg;
                                       RAISE EX_MAIN_EXCEPTION;
                                     END IF;

                                    ln_tot_ora_inv_match  :=  ln_tot_ora_inv_match + 1;  --Counter for Total invoice match wit Oracle Invoice
-- -----------------------------------------------------------------------
-- Call the Print Message Footer Procedure to print the detail transaction
-- -----------------------------------------------------------------------
                                    print_message_footer
                                     ( x_errmsg                 =>  lc_errmsg
                                      ,x_retstatus              =>  ln_retcode
                                      ,p_customer_id            =>  lcu_trxn_det_tbl(ln_trxn_cnt).bill_to_customer_id --Added for CR#684 --Defect #976
                                      ,p_check                  =>  get_lockbox_rec.check_number
                                      ,p_transaction            =>  get_lockbox_det_rec.invoice3
                                      ,p_tran_amount            =>  ln_amount_applied3
                                      ,p_sub_amount             =>  lcu_trxn_det_tbl(ln_trxn_cnt).acctd_amount_due_remaining
                                      ,p_sub_invoice            =>  lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                                     );

                                     IF ln_retcode  = gn_error THEN
                                         lc_error_details := lc_error_location||':'|| lc_errmsg;
                                         RAISE EX_MAIN_EXCEPTION;
                                     END IF;
                                     EXIT;
                              END IF;
                       END IF; --Added for the Defect #3983
                      END IF;
                    END LOOP;
                 END IF;
              END IF;
              COMMIT;
              END LOOP;
              CLOSE lcu_get_lockbox_det_rec;
           END IF;
-- End of Changes for the Defect #3983
--------------------------------------------
--------------------------------------------
-- Commented for Defect #3983 -- 26-JAN-10
--------------------------------------------
          -- -------------------------------------------
          -- Check if the matching profiles are
          -- INVOICE  / NULL
          -- -------------------------------------------
/*
            lc_error_location := 'Check the Invoice1 in Oracle ';
            IF get_lockbox_det_rec.invoice1 IS NOT NULL THEN

              get_trx_number.trx_number                 := NULL;
              get_trx_number.acctd_amount_due_remaining := NULL;

              OPEN   lcu_get_trx_number  ( p_trx_number    =>  get_lockbox_det_rec.invoice1
                                         -- ,p_customer_id   =>  ln_customer_id  --Commented for CR #684 --Defect #976
                                         );
              FETCH  lcu_get_trx_number  INTO get_trx_number;
              CLOSE  lcu_get_trx_number;

              -- Counter for total invoice recieved from bank
              ln_tot_inv_rcv_bnk    := ln_tot_inv_rcv_bnk + 1;
              -- -------------------------------------------
              -- Check the trx number is null and here consider
              -- the invoice discount amount and match with
              -- oracle trx number by using partial match
              -- -------------------------------------------
              --put_log_line('Customer Profile' || lc_cust_match_profile);
              --put_log_line('Customer Trx' || get_trx_number.trx_number);
              -----------------------------------------------------
              -- Start of Changes for the Defect #2063 -- 06-JAN-10
              -----------------------------------------------------
             IF get_trx_number.trx_number IS NULL THEN
                ln_inv_match_counter  := 0;
         -------------------------------------------------
         --Start of changes for Defect #2063 -- 06-JAN-10
         -------------------------------------------------
               IF(lc_fetched_flag = 'N') THEN
                       OPEN lcu_get_trx_number ( p_trx_number    =>  NULL);
                       FETCH lcu_get_trx_number BULK COLLECT INTO lcu_trxn_det_tbl;
                       CLOSE lcu_get_trx_number;
                       put_log_line('Count of Open Invoices Fetched --  '||lcu_trxn_det_tbl.COUNT);
                       lc_fetched_flag := 'Y'; --Added on 06-JAN-10
               END IF;
          -------------------------------------------------
         --End of changes for Defect #2063 -- 06-JAN-10
         -------------------------------------------------
                -- -------------------------------------------
                -- Get All the Trx Number for the Same
                -- Customer and Amount from Oracle
                -- -------------------------------------------
                FOR ln_trxn_cnt IN 1..lcu_trxn_det_tbl.COUNT
                LOOP

                  ln_diff_amount        := NULL;
                  ln_amount_applied1    := NULL;
                  lb_inv_amount_match   := FALSE;

                  IF lcu_trxn_det_tbl(ln_trxn_cnt).trx_number IS NOT NULL THEN
                    -- -------------------------------------------
                    -- Call the function to get the discount
                    -- percent for the each selected transaction
                    -- by passing customer terms and difference
                    -- of bai deposit date and oracle invoice
                    -- transaction date
                    -- -------------------------------------------
                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate( p_payment_term_id     => 
ln_standard_terms
                                                                                         ,p_paymentr_diff_days  => 
(get_bai_deposit_dt.deposit_date -  lcu_trxn_det_tbl(ln_trxn_cnt).trx_date)
                                                                                       );

                    ln_amount_applied1 := get_lockbox_det_rec.amount_applied1 / gn_cur_mult_dvd; --SUBSTR
(get_lockbox_det_rec.amount_applied1,1,LENGTH(get_lockbox_det_rec.amount_applied1)-gn_cur_precision)||'.'||SUBSTR
(get_lockbox_det_rec.amount_applied1,(LENGTH(get_lockbox_det_rec.amount_applied1)-1));
                    ln_diff_amount     := ((ln_amount_applied1 * (100 / (100 - ln_discount_percent))) - lcu_trxn_det_tbl
(ln_trxn_cnt).acctd_amount_due_remaining);

                    IF ln_diff_amount = 0 THEN
                      lb_inv_amount_match := TRUE;
                    ELSE
                      lb_inv_amount_match := FALSE;
                    END IF;
                    -- -------------------------------------------
                    -- Call the partial match funcition
                    -- check_position_match by passing
                    -- Oracle Invoice number and BAI Invoice number
                    -- -------------------------------------------
                    IF (lb_inv_amount_match) THEN  -- B.Looman: Only call inv match if amts already match
                      lb_inv_match := check_position_match
                      ( p_oracle_invoice      => lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                        ,p_custom_invoice      => get_lockbox_det_rec.invoice1
                        ,p_profile_digit_check => ln_profile_digit_check
                       );
                    END IF;

                    IF lb_inv_match = TRUE AND lb_inv_amount_match = TRUE THEN

                      ln_inv_match_counter := ln_inv_match_counter + 1;
                      put_log_line('ln_inv_match_counter1'||ln_inv_match_counter);
                      -- -------------------------------------------
                      -- Update the Invoice1 xx_ar_payments_interface
                      -- to Oracle Invoice Number after matcing
                      -- -------------------------------------------
                      lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice1 record type 4';
                      update_lckb_rec
                      ( x_errmsg                    => lc_errmsg
                       ,x_retstatus                 => ln_retcode
                       ,p_process_num               => p_process_num
                       ,p_record_type               => '4'
                       ,p_invoice                   => lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                       ,p_invoice1_2_3              => 'INVOICE1'
                       ,p_invoice1_2_3_status       => 'INVOICE_MATCH'
                       ,p_rowid                     => get_lockbox_det_rec.rowid
                      );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;
                      -- -------------------------------------------
                      -- Update the Invoice Match Status for
                      -- Record Type 6
                      -- -------------------------------------------
                      lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice1 record type 6';
                      update_lckb_rec
                      ( x_errmsg                    => lc_errmsg
                       ,x_retstatus                 => ln_retcode
                       ,p_process_num               => p_process_num
                       ,p_record_type               => '6'
                       ,p_inv_match_status          => lc_inv_match_status --'PARTIAL_INVOICE1-'
                       ,p_rowid                     => get_lockbox_rec.rowid
                      );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;

                      --Counter for Total invoice match wit Oracle Invoice
                      ln_tot_ora_inv_match  :=  ln_tot_ora_inv_match + 1;

                      -- -------------------------------------------
                      -- Call the Print Message Footer Procedure to
                      -- print the detail transaction
                      -- -------------------------------------------
                      print_message_footer
                      ( x_errmsg                 =>  lc_errmsg
                       ,x_retstatus              =>  ln_retcode
                       --,p_customer_id            =>  ln_customer_id                   --Commented for the CR #684
                       ,p_customer_id            =>  lcu_trxn_det_tbl(ln_trxn_cnt).bill_to_customer_id --Added for CR#684 --
Defect #976
                       ,p_check                  =>  get_lockbox_rec.check_number
                       ,p_transaction            =>  get_lockbox_det_rec.invoice1
                       ,p_tran_amount            =>  ln_amount_applied1
                       ,p_sub_amount             =>  lcu_trxn_det_tbl(ln_trxn_cnt).acctd_amount_due_remaining
                       ,p_sub_invoice            =>  lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                       );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;

                      EXIT;

                    END IF;
                  END IF;
                END LOOP;
              -----------------------------------------------------
              -- End of Changes for the Defect #2063 -- 06-JAN-10
              -----------------------------------------------------
/* --Commented for the Defect 2063 -- 06-JAN-10
              IF get_trx_number.trx_number IS NULL THEN

                ln_inv_match_counter  := 0;
                -- -------------------------------------------
                -- Get All the Trx Number for the Same
                -- Customer and Amount from Oracle
                -- -------------------------------------------

                OPEN   lcu_get_trx_number  ( p_trx_number    =>  NULL
                                            -- ,p_customer_id   =>  ln_customer_id  --Commented for CR #684 --Defect #976
                                           );
                LOOP
                FETCH  lcu_get_trx_number  INTO get_trx_number;
                EXIT WHEN lcu_get_trx_number%NOTFOUND;

                  ln_diff_amount        := NULL;
                  ln_amount_applied1    := NULL;
                  lb_inv_amount_match   := FALSE;

                  IF get_trx_number.trx_number IS NOT NULL THEN
                    -- -------------------------------------------
                    -- Call the function to get the discount
                    -- percent for the each selected transaction
                    -- by passing customer terms and difference
                    -- of bai deposit date and oracle invoice
                    -- transaction date
                    -- -------------------------------------------
                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate( p_payment_term_id     => 
ln_standard_terms
                                                                                         ,p_paymentr_diff_days  => 
(get_bai_deposit_dt.deposit_date -  get_trx_number.trx_date)
                                                                                       );

                    ln_amount_applied1 := get_lockbox_det_rec.amount_applied1 / gn_cur_mult_dvd; --SUBSTR
(get_lockbox_det_rec.amount_applied1,1,LENGTH(get_lockbox_det_rec.amount_applied1)-gn_cur_precision)||'.'||SUBSTR
(get_lockbox_det_rec.amount_applied1,(LENGTH(get_lockbox_det_rec.amount_applied1)-1));
                    ln_diff_amount     := ((ln_amount_applied1 * (100 / (100 - ln_discount_percent))) - 
get_trx_number.acctd_amount_due_remaining);

                    IF ln_diff_amount = 0 THEN
                      lb_inv_amount_match := TRUE;
                    ELSE
                      lb_inv_amount_match := FALSE;
                    END IF;
                    -- -------------------------------------------
                    -- Call the partial match funcition
                    -- check_position_match by passing
                    -- Oracle Invoice number and BAI Invoice number
                    -- -------------------------------------------
                    IF (lb_inv_amount_match) THEN  -- B.Looman: Only call inv match if amts already match
                      lb_inv_match := check_position_match
                      ( p_oracle_invoice      => get_trx_number.trx_number
                        ,p_custom_invoice      => get_lockbox_det_rec.invoice1
                        ,p_profile_digit_check => ln_profile_digit_check
                       );
                    END IF;

                    IF lb_inv_match = TRUE AND lb_inv_amount_match = TRUE THEN

                      ln_inv_match_counter := ln_inv_match_counter + 1;
                      put_log_line('ln_inv_match_counter1'||ln_inv_match_counter);
                      -- -------------------------------------------
                      -- Update the Invoice1 xx_ar_payments_interface
                      -- to Oracle Invoice Number after matcing
                      -- -------------------------------------------
                      lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice1 record type 4';
                      update_lckb_rec
                      ( x_errmsg                    => lc_errmsg
                       ,x_retstatus                 => ln_retcode
                       ,p_process_num               => p_process_num
                       ,p_record_type               => '4'
                       ,p_invoice                   => get_trx_number.trx_number
                       ,p_invoice1_2_3              => 'INVOICE1'
                       ,p_invoice1_2_3_status       => 'INVOICE_MATCH'
                       ,p_rowid                     => get_lockbox_det_rec.rowid
                      );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;
                      -- -------------------------------------------
                      -- Update the Invoice Match Status for
                      -- Record Type 6
                      -- -------------------------------------------
                      lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice1 record type 6';
                      update_lckb_rec
                      ( x_errmsg                    => lc_errmsg
                       ,x_retstatus                 => ln_retcode
                       ,p_process_num               => p_process_num
                       ,p_record_type               => '6'
                       ,p_inv_match_status          => lc_inv_match_status --'PARTIAL_INVOICE1-'
                       ,p_rowid                     => get_lockbox_rec.rowid
                      );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;

                      --Counter for Total invoice match wit Oracle Invoice
                      ln_tot_ora_inv_match  :=  ln_tot_ora_inv_match + 1;

                      -- -------------------------------------------
                      -- Call the Print Message Footer Procedure to
                      -- print the detail transaction
                      -- -------------------------------------------
                      print_message_footer
                      ( x_errmsg                 =>  lc_errmsg
                       ,x_retstatus              =>  ln_retcode
                       --,p_customer_id            =>  ln_customer_id                   --Commented for the CR #684
                       ,p_customer_id            =>  get_trx_number.bill_to_customer_id --Added for CR#684 --Defect #976
                       ,p_check                  =>  get_lockbox_rec.check_number
                       ,p_transaction            =>  get_lockbox_det_rec.invoice1
                       ,p_tran_amount            =>  ln_amount_applied1
                       ,p_sub_amount             =>  get_trx_number.acctd_amount_due_remaining
                       ,p_sub_invoice            =>  get_trx_number.trx_number
                       );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;

                      EXIT;

                    END IF;
                  END IF;
                END LOOP;
                CLOSE  lcu_get_trx_number; */ --Commented for the Defect #2063
/*
              ELSE
                -- -------------------------------------------
                -- Update the Invoice match status if the invoice
                -- is matched with Oracle Invoice for record type 6
                -- -------------------------------------------
                lc_error_location := 'Call the Update Status Procedure for Invoice Exists for Invoice1 record type 6';
                update_lckb_rec
                ( x_errmsg                    => lc_errmsg
                 ,x_retstatus                 => ln_retcode
                 ,p_process_num               => p_process_num
                 ,p_record_type               => '6'
                 ,p_inv_match_status          => lc_inv_match_status --'INVOICE_EXISTS1-'
                 ,p_rowid                     => get_lockbox_rec.rowid
                 );

                 IF ln_retcode  = gn_error THEN
                   lc_error_details := lc_error_location||':'|| lc_errmsg;
                   RAISE EX_MAIN_EXCEPTION;
                 END IF;
                -- -------------------------------------------
                -- Update the Invoice1 Status if the invoice
                -- is matched with Oracle Invoice for record type 4
                -- -------------------------------------------
                lc_error_location := 'Call the Update Status Procedure for Invoice Exists for Invoice1 record type 4';
                update_lckb_rec
                ( x_errmsg                    => lc_errmsg
                 ,x_retstatus                 => ln_retcode
                 ,p_process_num               => p_process_num
                 ,p_record_type               => '4'
                 ,p_invoice                   => NULL
                 ,p_invoice1_2_3              => 'INVOICE1'
                 ,p_invoice1_2_3_status       => 'INVOICE_EXISTS'
                 ,p_rowid                     => get_lockbox_det_rec.rowid
                );

                IF ln_retcode  = gn_error THEN
                  lc_error_details := lc_error_location||':'|| lc_errmsg;
                  RAISE EX_MAIN_EXCEPTION;
                END IF;

              END IF;
            END IF;
            -- -------------------------------------------
            -- Check the Invoice2 is Exist in Oracle Or Not
            -- -------------------------------------------
            lc_error_location := 'Check the Invoice2 in Oracle ';
            IF get_lockbox_det_rec.invoice2 IS NOT NULL THEN

              get_trx_number.trx_number                 := NULL;
              get_trx_number.acctd_amount_due_remaining := NULL;

              OPEN   lcu_get_trx_number  ( p_trx_number    =>  get_lockbox_det_rec.invoice2
                                          -- ,p_customer_id   =>  ln_customer_id  --Commented for CR #684 --Defect #976
                                         );
              FETCH  lcu_get_trx_number  INTO get_trx_number;
              CLOSE  lcu_get_trx_number;

              -- Counter for total invoice recieved from bank
              ln_tot_inv_rcv_bnk  := ln_tot_inv_rcv_bnk + 1;
              -----------------------------------------------------
              -- Start of changes for the Defect #2063 -- 06-JAN-10
              -----------------------------------------------------
              IF get_trx_number.trx_number IS NULL THEN
                ln_inv_match_counter := 0;

                IF(lc_fetched_flag = 'N') THEN
                       OPEN lcu_get_trx_number ( p_trx_number    =>  NULL);
                       FETCH lcu_get_trx_number BULK COLLECT INTO lcu_trxn_det_tbl;
                       CLOSE lcu_get_trx_number;
                       put_log_line('Count of Open Invoices Fetched --  '||lcu_trxn_det_tbl.COUNT);
                       lc_fetched_flag := 'Y';
                END IF; --Added on 06-JAN-10

                -- -------------------------------------------
                -- Get All the Trx Number for the Same
                -- Customer and Amount from Oracle
                -- -------------------------------------------
                FOR ln_trxn_cnt IN 1..lcu_trxn_det_tbl.COUNT
                LOOP

                  ln_diff_amount       := NULL;
                  ln_amount_applied2   := NULL;
                  lb_inv_amount_match  := FALSE;

                  --put_log_line('Get Trx Num: '||get_trx_number.trx_number);
                  IF lcu_trxn_det_tbl(ln_trxn_cnt).trx_number IS NOT NULL THEN
                    -- -------------------------------------------
                    -- Call the function to get the discount
                    -- percent for the each selected transaction
                    -- by passing customer terms and difference
                    -- of bai deposit date and oracle invoice
                    -- transaction date
                    -- -------------------------------------------
                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate( p_payment_term_id     => 
ln_standard_terms
                                                                                        ,p_paymentr_diff_days  => 
(get_bai_deposit_dt.deposit_date -  lcu_trxn_det_tbl(ln_trxn_cnt).trx_date)
                                                                                       );

                    ln_amount_applied2  := get_lockbox_det_rec.amount_applied2 / gn_cur_mult_dvd; --SUBSTR
(get_lockbox_det_rec.amount_applied2,1,LENGTH(get_lockbox_det_rec.amount_applied2)-gn_cur_precision)||'.'||SUBSTR
(get_lockbox_det_rec.amount_applied2,(LENGTH(get_lockbox_det_rec.amount_applied2)-1));
                    ln_diff_amount      := ((ln_amount_applied2 * (100 / (100 - ln_discount_percent))) - lcu_trxn_det_tbl
(ln_trxn_cnt).acctd_amount_due_remaining);

                    IF ln_diff_amount = 0 THEN
                      lb_inv_amount_match := TRUE;
                    ELSE
                      lb_inv_amount_match := FALSE;
                    END IF;
                    -- -------------------------------------------
                    -- Call the partial match funcition
                    -- check_position_match by passing
                    -- Oracle Invoice number and BAI Invoice number
                    -- -------------------------------------------
                    IF (lb_inv_amount_match) THEN  -- B.Looman: Only call inv match if amts already match
                      lb_inv_match := check_position_match
                      ( p_oracle_invoice      => lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                        ,p_custom_invoice      => get_lockbox_det_rec.invoice2
                        ,p_profile_digit_check => ln_profile_digit_check
                       );
                    END IF;

                    IF lb_inv_match = TRUE AND lb_inv_amount_match = TRUE THEN

                      ln_inv_match_counter  := ln_inv_match_counter + 1;
                      -- -------------------------------------------
                      -- Update the Invoice2 xx_ar_payments_interface
                      -- to Oracle Invoice Number after matcing
                      -- -------------------------------------------
                      lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice2 record type 4';
                      update_lckb_rec
                      ( x_errmsg                    => lc_errmsg
                       ,x_retstatus                 => ln_retcode
                       ,p_process_num               => p_process_num
                       ,p_record_type               => '4'
                       ,p_invoice                   => lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                       ,p_invoice1_2_3              => 'INVOICE2'
                       ,p_invoice1_2_3_status       => 'INVOICE_MATCH'
                       ,p_rowid                     => get_lockbox_det_rec.rowid
                      );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;
                      -- -------------------------------------------
                      -- Update the Invoice Match Status for
                      -- Record Type 6
                      -- -------------------------------------------
                      lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice2 record type 6';
                      update_lckb_rec
                      ( x_errmsg                    => lc_errmsg
                       ,x_retstatus                 => ln_retcode
                       ,p_process_num               => p_process_num
                       ,p_record_type               => '6'
                       ,p_inv_match_status          => lc_inv_match_status --'PARTIAL_INVOICE2-'
                       ,p_rowid                     => get_lockbox_rec.rowid
                      );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;

                      --Counter for Total invoice match with Oracle Invoice
                      ln_tot_ora_inv_match  :=  ln_tot_ora_inv_match + 1;
                      -- -------------------------------------------
                      -- Call the Print Message Footer Procedure to
                      -- print the detail transaction
                      -- -------------------------------------------
                      print_message_footer
                      ( x_errmsg                 =>  lc_errmsg
                       ,x_retstatus              =>  ln_retcode
                       --,p_customer_id            =>  ln_customer_id                   --Commented for the CR #684
                       ,p_customer_id            =>  lcu_trxn_det_tbl(ln_trxn_cnt).bill_to_customer_id --Added for CR#684 --
Defect #976
                       ,p_check                  =>  get_lockbox_rec.check_number
                       ,p_transaction            =>  get_lockbox_det_rec.invoice2
                       ,p_tran_amount            =>  ln_amount_applied2
                       ,p_sub_amount             =>  lcu_trxn_det_tbl(ln_trxn_cnt).acctd_amount_due_remaining
                       ,p_sub_invoice            =>  lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                       );
                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;

                      EXIT;
                    END IF;
                  END IF;
                END LOOP;
----------------------------------
-- End of Changes for Defect #2063
----------------------------------

/* Commented for the Defect #2063 -- 06-JAN-10
              IF get_trx_number.trx_number IS NULL THEN
                ln_inv_match_counter := 0;
                -- -------------------------------------------
                -- Get All the Trx Number for the Same
                -- Customer and Amount from Oracle
                -- -------------------------------------------
                OPEN   lcu_get_trx_number  ( p_trx_number    =>  NULL
                                            -- ,p_customer_id   =>  ln_customer_id  --Commented for CR #684 --Defect #976
                                           );
                LOOP
                FETCH  lcu_get_trx_number  INTO get_trx_number;
                EXIT WHEN lcu_get_trx_number%NOTFOUND;

                  ln_diff_amount       := NULL;
                  ln_amount_applied2   := NULL;
                  lb_inv_amount_match  := FALSE;

                  --put_log_line('Get Trx Num: '||get_trx_number.trx_number);
                  IF get_trx_number.trx_number IS NOT NULL THEN
                    -- -------------------------------------------
                    -- Call the function to get the discount
                    -- percent for the each selected transaction
                    -- by passing customer terms and difference
                    -- of bai deposit date and oracle invoice
                    -- transaction date
                    -- -------------------------------------------
                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate( p_payment_term_id     => 
ln_standard_terms
                                                                                        ,p_paymentr_diff_days  => 
(get_bai_deposit_dt.deposit_date -  get_trx_number.trx_date)
                                                                                       );

                    ln_amount_applied2  := get_lockbox_det_rec.amount_applied2 / gn_cur_mult_dvd; --SUBSTR
(get_lockbox_det_rec.amount_applied2,1,LENGTH(get_lockbox_det_rec.amount_applied2)-gn_cur_precision)||'.'||SUBSTR
(get_lockbox_det_rec.amount_applied2,(LENGTH(get_lockbox_det_rec.amount_applied2)-1));
                    ln_diff_amount      := ((ln_amount_applied2 * (100 / (100 - ln_discount_percent))) - 
get_trx_number.acctd_amount_due_remaining);

                    IF ln_diff_amount = 0 THEN
                      lb_inv_amount_match := TRUE;
                    ELSE
                      lb_inv_amount_match := FALSE;
                    END IF;
                    -- -------------------------------------------
                    -- Call the partial match funcition
                    -- check_position_match by passing
                    -- Oracle Invoice number and BAI Invoice number
                    -- -------------------------------------------
                    IF (lb_inv_amount_match) THEN  -- B.Looman: Only call inv match if amts already match
                      lb_inv_match := check_position_match
                      ( p_oracle_invoice      => get_trx_number.trx_number
                        ,p_custom_invoice      => get_lockbox_det_rec.invoice2
                        ,p_profile_digit_check => ln_profile_digit_check
                       );
                    END IF;

                    IF lb_inv_match = TRUE AND lb_inv_amount_match = TRUE THEN

                      ln_inv_match_counter  := ln_inv_match_counter + 1;
                      -- -------------------------------------------
                      -- Update the Invoice2 xx_ar_payments_interface
                      -- to Oracle Invoice Number after matcing
                      -- -------------------------------------------
                      lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice2 record type 4';
                      update_lckb_rec
                      ( x_errmsg                    => lc_errmsg
                       ,x_retstatus                 => ln_retcode
                       ,p_process_num               => p_process_num
                       ,p_record_type               => '4'
                       ,p_invoice                   => get_trx_number.trx_number
                       ,p_invoice1_2_3              => 'INVOICE2'
                       ,p_invoice1_2_3_status       => 'INVOICE_MATCH'
                       ,p_rowid                     => get_lockbox_det_rec.rowid
                      );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;
                      -- -------------------------------------------
                      -- Update the Invoice Match Status for
                      -- Record Type 6
                      -- -------------------------------------------
                      lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice2 record type 6';
                      update_lckb_rec
                      ( x_errmsg                    => lc_errmsg
                       ,x_retstatus                 => ln_retcode
                       ,p_process_num               => p_process_num
                       ,p_record_type               => '6'
                       ,p_inv_match_status          => lc_inv_match_status --'PARTIAL_INVOICE2-'
                       ,p_rowid                     => get_lockbox_rec.rowid
                      );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;

                      --Counter for Total invoice match with Oracle Invoice
                      ln_tot_ora_inv_match  :=  ln_tot_ora_inv_match + 1;
                      -- -------------------------------------------
                      -- Call the Print Message Footer Procedure to
                      -- print the detail transaction
                      -- -------------------------------------------
                      print_message_footer
                      ( x_errmsg                 =>  lc_errmsg
                       ,x_retstatus              =>  ln_retcode
                       --,p_customer_id            =>  ln_customer_id                   --Commented for the CR #684
                       ,p_customer_id            =>  get_trx_number.bill_to_customer_id --Added for CR#684 --Defect #976
                       ,p_check                  =>  get_lockbox_rec.check_number
                       ,p_transaction            =>  get_lockbox_det_rec.invoice2
                       ,p_tran_amount            =>  ln_amount_applied2
                       ,p_sub_amount             =>  get_trx_number.acctd_amount_due_remaining
                       ,p_sub_invoice            =>  get_trx_number.trx_number
                       );
                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;

                      EXIT;
                    END IF;
                  END IF;
                END LOOP;
                CLOSE  lcu_get_trx_number; */ --Commented for the Defect #2063 -- 06-JAN-10
/*
              ELSE
                -- -------------------------------------------
                -- Update the Invoice match status if the invoice
                -- is matched with Oracle Invoice for record type 6
                -- -------------------------------------------
                lc_error_location := 'Call the Update Status Procedure for Invoice Exists for Invoice2 record type 6';
                update_lckb_rec
                ( x_errmsg                    => lc_errmsg
                 ,x_retstatus                 => ln_retcode
                 ,p_process_num               => p_process_num
                 ,p_record_type               => '6'
                 ,p_inv_match_status          => lc_inv_match_status --'INVOICE_EXISTS2-'
                 ,p_rowid                     => get_lockbox_rec.rowid
                 );

                IF ln_retcode  = gn_error THEN
                  lc_error_details := lc_error_location||':'|| lc_errmsg;
                  RAISE EX_MAIN_EXCEPTION;
                END IF;
                -- -------------------------------------------
                -- Update the Invoice2 Status if the invoice
                -- is matched with Oracle Invoice for record type 4
                -- -------------------------------------------
                lc_error_location := 'Call the Update Status Procedure for Invoice Exists for Invoice2 record type 4';
                update_lckb_rec
                ( x_errmsg                    => lc_errmsg
                 ,x_retstatus                 => ln_retcode
                 ,p_process_num               => p_process_num
                 ,p_record_type               => '4'
                 ,p_invoice                   => NULL
                 ,p_invoice1_2_3              => 'INVOICE2'
                 ,p_invoice1_2_3_status       => 'INVOICE_EXISTS'
                 ,p_rowid                     => get_lockbox_det_rec.rowid
                );

                IF ln_retcode  = gn_error THEN
                  lc_error_details := lc_error_location||':'|| lc_errmsg;
                  RAISE EX_MAIN_EXCEPTION;
                END IF;

              END IF;
            END IF;
            -- -------------------------------------------
            -- Check the Invoice3 is Exist in Oracle Or Not
            -- -------------------------------------------
            lc_error_location := 'Check the Invoice3 in Oracle ';
            IF get_lockbox_det_rec.invoice3 IS NOT NULL THEN

              get_trx_number.trx_number                 := NULL;
              get_trx_number.acctd_amount_due_remaining := NULL;

              OPEN   lcu_get_trx_number  ( p_trx_number    =>  get_lockbox_det_rec.invoice3
                                          -- ,p_customer_id   =>  ln_customer_id  --Commented for CR #684 --Defect #976
                                         );
              FETCH  lcu_get_trx_number  INTO get_trx_number;
              CLOSE  lcu_get_trx_number;

              -- Counter for total invoice recieved from bank
              ln_tot_inv_rcv_bnk  := ln_tot_inv_rcv_bnk + 1;
----------------------------------------------------
--Start of Changes for the Defect #2063 -- 06-JAN-10
----------------------------------------------------
                IF get_trx_number.trx_number IS NULL THEN
                ln_inv_match_counter := 0;

                   IF(lc_fetched_flag = 'N') THEN
                       OPEN lcu_get_trx_number ( p_trx_number    =>  NULL);
                       FETCH lcu_get_trx_number BULK COLLECT INTO lcu_trxn_det_tbl;
                       CLOSE lcu_get_trx_number;
                       put_log_line('Count of Open Invoices Fetched --  '||lcu_trxn_det_tbl.COUNT);
                       lc_fetched_flag := 'Y';
                   END IF;  --Added on 06-JAN-10
                -- -------------------------------------------
                -- Get All the Trx Number for the Same
                -- Customer and Amount from Oracle
                -- -------------------------------------------
                FOR ln_trxn_cnt IN 1..lcu_trxn_det_tbl.COUNT
                LOOP

                  ln_diff_amount       := NULL;
                  ln_amount_applied3   := NULL;
                  lb_inv_amount_match  := FALSE;

                  IF lcu_trxn_det_tbl(ln_trxn_cnt).trx_number IS NOT NULL THEN
                    -- -------------------------------------------
                    -- Call the function to get the discount
                    -- percent for the each selected transaction
                    -- by passing customer terms and difference
                    -- of bai deposit date and oracle invoice
                    -- transaction date
                    -- -------------------------------------------
                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate
                    ( p_payment_term_id     => ln_standard_terms
                      ,p_paymentr_diff_days  => (get_bai_deposit_dt.deposit_date -  lcu_trxn_det_tbl(ln_trxn_cnt).trx_date)
                     );

                    ln_amount_applied3 := get_lockbox_det_rec.amount_applied3 / gn_cur_mult_dvd; --SUBSTR
(get_lockbox_det_rec.amount_applied3,1,LENGTH(get_lockbox_det_rec.amount_applied3)-gn_cur_precision)||'.'||SUBSTR
(get_lockbox_det_rec.amount_applied3,(LENGTH(get_lockbox_det_rec.amount_applied3)-1));
                    ln_diff_amount     := ((ln_amount_applied3 * (100 / (100 - ln_discount_percent))) - lcu_trxn_det_tbl
(ln_trxn_cnt).acctd_amount_due_remaining);

                    IF ln_diff_amount = 0 THEN
                      lb_inv_amount_match := TRUE;
                    ELSE
                      lb_inv_amount_match := FALSE;
                    END IF;
                    -- -------------------------------------------
                    -- Call the partial match funcition
                    -- check_position_match by passing
                    -- Oracle Invoice number and BAI Invoice number
                    -- -------------------------------------------
                    IF (lb_inv_amount_match) THEN  -- B.Looman: Only call inv match if amts already match
                      lb_inv_match := check_position_match
                      ( p_oracle_invoice      => lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                        ,p_custom_invoice      => get_lockbox_det_rec.invoice3
                        ,p_profile_digit_check => ln_profile_digit_check
                       );
                    END IF;

                    IF lb_inv_match = TRUE AND lb_inv_amount_match = TRUE THEN

                      ln_inv_match_counter  := ln_inv_match_counter + 1;
                      -- -------------------------------------------
                      -- Update the Invoice3 xx_ar_payments_interface
                      -- to Oracle Invoice Number after matcing
                      -- -------------------------------------------
                      lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice3 record type 4';
                      update_lckb_rec
                      ( x_errmsg                    => lc_errmsg
                       ,x_retstatus                 => ln_retcode
                       ,p_process_num               => p_process_num
                       ,p_record_type               => '4'
                       ,p_invoice                   => lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                       ,p_invoice1_2_3              => 'INVOICE3'
                       ,p_invoice1_2_3_status       => 'INVOICE_MATCH'
                       ,p_rowid                     => get_lockbox_det_rec.rowid
                      );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;
                      -- -------------------------------------------
                      -- Update the Invoice Match Status for
                      -- Record Type 6
                      -- -------------------------------------------
                      lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice3 record type 6';
                      update_lckb_rec
                      ( x_errmsg                    => lc_errmsg
                       ,x_retstatus                 => ln_retcode
                       ,p_process_num               => p_process_num
                       ,p_record_type               => '6'
                       ,p_inv_match_status          => lc_inv_match_status --'PARTIAL_INVOICE3-'
                       ,p_rowid                     => get_lockbox_rec.rowid
                      );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;

                      --Counter for Total invoice match wit Oracle Invoice
                      ln_tot_ora_inv_match  :=  ln_tot_ora_inv_match + 1;
                      -- -------------------------------------------
                      -- Call the Print Message Footer Procedure to
                      -- print the detail transaction
                      -- -------------------------------------------
                      print_message_footer
                      ( x_errmsg                 =>  lc_errmsg
                       ,x_retstatus              =>  ln_retcode
                       --,p_customer_id            =>  ln_customer_id                   --Commented for the CR #684
                       ,p_customer_id            =>  lcu_trxn_det_tbl(ln_trxn_cnt).bill_to_customer_id --Added for CR#684 --
Defect #976
                       ,p_check                  =>  get_lockbox_rec.check_number
                       ,p_transaction            =>  get_lockbox_det_rec.invoice3
                       ,p_tran_amount            =>  ln_amount_applied3
                       ,p_sub_amount             =>  lcu_trxn_det_tbl(ln_trxn_cnt).acctd_amount_due_remaining
                       ,p_sub_invoice            =>  lcu_trxn_det_tbl(ln_trxn_cnt).trx_number
                       );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;

                      EXIT;
                    END IF;
                  END IF;
                END LOOP;
--------------------------------------------------
--End of Changes for the Defect #2063 -- 06-JAN-10
--------------------------------------------------
/* Commented for the Defect #2063 -- 06-JAN-10
              IF get_trx_number.trx_number IS NULL THEN

                ln_inv_match_counter      := 0;
                -- -------------------------------------------
                -- Get All the Trx Number for the Same
                -- Customer and Amount from Oracle
                -- -------------------------------------------
                OPEN  lcu_get_trx_number  ( p_trx_number    =>  NULL
                                           -- ,p_customer_id   =>  ln_customer_id  --Commented for CR #684 --Defect #976
                                          );
                LOOP
                FETCH  lcu_get_trx_number  INTO get_trx_number;
                EXIT WHEN lcu_get_trx_number%NOTFOUND;

                  ln_diff_amount       := NULL;
                  ln_amount_applied3   := NULL;
                  lb_inv_amount_match  := FALSE;

                  IF get_trx_number.trx_number IS NOT NULL THEN
                    -- -------------------------------------------
                    -- Call the function to get the discount
                    -- percent for the each selected transaction
                    -- by passing customer terms and difference
                    -- of bai deposit date and oracle invoice
                    -- transaction date
                    -- -------------------------------------------
                    ln_discount_percent := xx_ar_lockbox_process_pkg.discount_calculate
                    ( p_payment_term_id     => ln_standard_terms
                      ,p_paymentr_diff_days  => (get_bai_deposit_dt.deposit_date -  get_trx_number.trx_date)
                     );

                    ln_amount_applied3 := get_lockbox_det_rec.amount_applied3 / gn_cur_mult_dvd; --SUBSTR
(get_lockbox_det_rec.amount_applied3,1,LENGTH(get_lockbox_det_rec.amount_applied3)-gn_cur_precision)||'.'||SUBSTR
(get_lockbox_det_rec.amount_applied3,(LENGTH(get_lockbox_det_rec.amount_applied3)-1));
                    ln_diff_amount     := ((ln_amount_applied3 * (100 / (100 - ln_discount_percent))) - 
get_trx_number.acctd_amount_due_remaining);

                    IF ln_diff_amount = 0 THEN
                      lb_inv_amount_match := TRUE;
                    ELSE
                      lb_inv_amount_match := FALSE;
                    END IF;
                    -- -------------------------------------------
                    -- Call the partial match funcition
                    -- check_position_match by passing
                    -- Oracle Invoice number and BAI Invoice number
                    -- -------------------------------------------
                    IF (lb_inv_amount_match) THEN  -- B.Looman: Only call inv match if amts already match
                      lb_inv_match := check_position_match
                      ( p_oracle_invoice      => get_trx_number.trx_number
                        ,p_custom_invoice      => get_lockbox_det_rec.invoice3
                        ,p_profile_digit_check => ln_profile_digit_check
                       );
                    END IF;

                    IF lb_inv_match = TRUE AND lb_inv_amount_match = TRUE THEN

                      ln_inv_match_counter  := ln_inv_match_counter + 1;
                      -- -------------------------------------------
                      -- Update the Invoice3 xx_ar_payments_interface
                      -- to Oracle Invoice Number after matcing
                      -- -------------------------------------------
                      lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice3 record type 4';
                      update_lckb_rec
                      ( x_errmsg                    => lc_errmsg
                       ,x_retstatus                 => ln_retcode
                       ,p_process_num               => p_process_num
                       ,p_record_type               => '4'
                       ,p_invoice                   => get_trx_number.trx_number
                       ,p_invoice1_2_3              => 'INVOICE3'
                       ,p_invoice1_2_3_status       => 'INVOICE_MATCH'
                       ,p_rowid                     => get_lockbox_det_rec.rowid
                      );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;
                      -- -------------------------------------------
                      -- Update the Invoice Match Status for
                      -- Record Type 6
                      -- -------------------------------------------
                      lc_error_location := 'Call the Update Status Procedure for Invoice Match for Invoice3 record type 6';
                      update_lckb_rec
                      ( x_errmsg                    => lc_errmsg
                       ,x_retstatus                 => ln_retcode
                       ,p_process_num               => p_process_num
                       ,p_record_type               => '6'
                       ,p_inv_match_status          => lc_inv_match_status --'PARTIAL_INVOICE3-'
                       ,p_rowid                     => get_lockbox_rec.rowid
                      );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;

                      --Counter for Total invoice match wit Oracle Invoice
                      ln_tot_ora_inv_match  :=  ln_tot_ora_inv_match + 1;
                      -- -------------------------------------------
                      -- Call the Print Message Footer Procedure to
                      -- print the detail transaction
                      -- -------------------------------------------
                      print_message_footer
                      ( x_errmsg                 =>  lc_errmsg
                       ,x_retstatus              =>  ln_retcode
                       --,p_customer_id            =>  ln_customer_id                   --Commented for the CR #684
                       ,p_customer_id            =>  get_trx_number.bill_to_customer_id --Added for CR#684 --Defect #976
                       ,p_check                  =>  get_lockbox_rec.check_number
                       ,p_transaction            =>  get_lockbox_det_rec.invoice3
                       ,p_tran_amount            =>  ln_amount_applied3
                       ,p_sub_amount             =>  get_trx_number.acctd_amount_due_remaining
                       ,p_sub_invoice            =>  get_trx_number.trx_number
                       );

                      IF ln_retcode  = gn_error THEN
                        lc_error_details := lc_error_location||':'|| lc_errmsg;
                        RAISE EX_MAIN_EXCEPTION;
                      END IF;

                      EXIT;
                    END IF;
                  END IF;
                END LOOP;
                CLOSE  lcu_get_trx_number; */ --Commented for the Defect #2063 --06-JAN-10
/*
              ELSE
                -- -------------------------------------------
                -- Update the Invoice match status if the invoice
                -- is matched with Oracle Invoice for record type 6
                -- -------------------------------------------
                lc_error_location := 'Call the Update Status Procedure for Invoice Exists for Invoice3 record type 6';
                update_lckb_rec
                ( x_errmsg                    => lc_errmsg
                 ,x_retstatus                 => ln_retcode
                 ,p_process_num               => p_process_num
                 ,p_record_type               => '6'
                 ,p_inv_match_status          => lc_inv_match_status --'INVOICE_EXISTS3-'
                 ,p_rowid                     => get_lockbox_rec.rowid
                 );

                IF ln_retcode  = gn_error THEN
                  lc_error_details := lc_error_location||':'|| lc_errmsg;
                  RAISE EX_MAIN_EXCEPTION;
                END IF;

                -- -------------------------------------------
                -- Update the Invoice1 Status if the invoice
                -- is matched with Oracle Invoice for record type 4
                -- -------------------------------------------
                lc_error_location := 'Call the Update Status Procedure for Invoice Exists for Invoice3 record type 4';
                update_lckb_rec
                ( x_errmsg                    => lc_errmsg
                 ,x_retstatus                 => ln_retcode
                 ,p_process_num               => p_process_num
                 ,p_record_type               => '4'
                 ,p_invoice                   => NULL
                 ,p_invoice1_2_3              => 'INVOICE3'
                 ,p_invoice1_2_3_status       => 'INVOICE_EXISTS'
                 ,p_rowid                     => get_lockbox_det_rec.rowid
                );

                IF ln_retcode  = gn_error THEN
                  lc_error_details := lc_error_location||':'|| lc_errmsg;
                  RAISE EX_MAIN_EXCEPTION;
                END IF;

              END IF;
            END IF;
        END LOOP;
        CLOSE lcu_get_lockbox_det_rec;
        --COMMIT; -- Commit at Detail Record
      END IF;
*/
----------------------------------------------------
-- Commented for the Defect #3983 -- 26-JAN-10
----------------------------------------------------
      -- -------------------------------------------
      -- Call the Consolidated Bill Rule  Procedure
      -- -------------------------------------------
      OPEN  lcu_get_status_count ( p_rowid       => get_lockbox_rec.rowid
                                  ,p_process_num => p_process_num
                                  ,p_record_type => '6'
                                 );
      FETCH lcu_get_status_count  INTO ln_status_count;
      CLOSE lcu_get_status_count;

      put_log_line('cons_inv_flag:'||lc_cons_inv_flag);
      put_log_line('ln_status_count:'||ln_status_count);

      IF ln_status_count = 0 AND lc_cons_inv_flag = 'Y' THEN
        -- Call the Consolidated Bill Rule  Procedure
        lc_error_location := 'Calling the Consolidated Bill Rule procedure';

        put_log_line('[BEGIN] Consolidated Bill - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

        consolidated_bill_rule
        ( x_errmsg        =>  lc_errmsg
         ,x_retstatus     =>  ln_retcode
         ,p_record        =>  lr_record
         ,p_term_id       =>  ln_standard_terms
         ,p_customer_id   =>  ln_customer_id
         ,p_deposit_date  =>  get_bai_deposit_dt.deposit_date
         ,p_rowid         =>  get_lockbox_rec.rowid
         ,p_process_num   =>  get_lockbox_rec.process_num
        );

        put_log_line('[END] Consolidated Bill - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

        IF ln_retcode  = gn_error THEN
           lc_error_location := 'Error at Consolidated Bill Rule: '|| lc_errmsg;
           RAISE EX_MAIN_EXCEPTION;
        END IF;
      END IF;


      -- -------------------------------------------
      -- Call the Purchase Order Rule Procedure
      -- -------------------------------------------
      OPEN  lcu_get_status_count ( p_rowid       => get_lockbox_rec.rowid
                                  ,p_process_num => p_process_num
                                  ,p_record_type => '6'
                                 );
      FETCH lcu_get_status_count  INTO ln_status_count;
      CLOSE lcu_get_status_count;

      put_log_line('ln_status_count:'||ln_status_count);

      IF ln_status_count = 0 THEN
        -- Call the Purchase Order Rule Procedure
        lc_error_location := 'Calling the Purchase Order Rule procedure';

        put_log_line('[BEGIN] Purchase Order - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

        purchase_order_rule
        ( x_errmsg        =>  lc_errmsg
         ,x_retstatus     =>  ln_retcode
         ,p_record        =>  lr_record
         ,p_term_id       =>  ln_standard_terms
         ,p_customer_id   =>  ln_customer_id
         ,p_deposit_date  =>  get_bai_deposit_dt.deposit_date
         ,p_rowid         =>  get_lockbox_rec.rowid
         ,p_process_num   =>  get_lockbox_rec.process_num
        );

        put_log_line('[END] Purchase Order - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

        IF ln_retcode  = gn_error THEN
           lc_error_location := 'Error at Purchase Order Rule: '|| lc_errmsg;
           RAISE EX_MAIN_EXCEPTION;
        END IF;
      END IF;



      -- -------------------------------------------
      -- Call the Autocash Rules auto_cash_match_rules
      -- for Date Range / Pulse Pay / Any Combination
      -- -------------------------------------------
      OPEN  lcu_get_status_count ( p_rowid       => get_lockbox_rec.rowid
                                  ,p_process_num => p_process_num
                                  ,p_record_type => '6'
                                 );
      FETCH lcu_get_status_count  INTO ln_status_count;
      CLOSE lcu_get_status_count;

      IF ln_status_count = 0 THEN
        -- Calling the Auto Cash Match Procedure
        lc_error_location := 'Calling the auto cash match rules procedure';

        auto_cash_match_rules
        ( x_errmsg          =>  lc_errmsg
         ,x_retstatus       =>  ln_retcode
         ,p_record          =>  lr_record
         ,p_term_id         =>  ln_standard_terms
         ,p_customer_id     =>  ln_customer_id
         ,p_deposit_date    =>  get_bai_deposit_dt.deposit_date
         ,p_rowid           =>  get_lockbox_rec.rowid
         ,p_process_num     =>  get_lockbox_rec.process_num
         ,p_trx_type        =>  p_trx_type
         ,p_trx_threshold   =>  p_trx_threshold
         ,p_from_days       =>  p_from_days
         ,p_to_days         =>  p_to_days
        );

        IF ln_retcode  = gn_error THEN
           lc_error_location := 'Error at auto cash match: '|| lc_errmsg;
           RAISE EX_MAIN_EXCEPTION;
        END IF;
      END IF;
    ELSE
      put_log_line('==========================');
      put_log_line(lc_error_location ||'-'||lc_error_details);
    END IF;
  END LOOP;
  CLOSE lcu_get_lockbox_rec;
  -- -------------------------------------------
  -- Call the Print Message Record Summary
  -- -------------------------------------------
  print_message_summary
  (x_errmsg            => lc_errmsg
  ,x_retstatus          => ln_retcode
  ,p_tot_inv_bnk        => ln_tot_inv_rcv_bnk
  ,p_tot_inv_match     => ln_tot_ora_inv_match
  ,p_tot_amt_match     => ln_tot_amt_inv_match
  );

  IF ln_retcode  = gn_error THEN
    lc_error_location := 'Error at Print Message Summary: '|| lc_errmsg;
    RAISE EX_MAIN_EXCEPTION;
  END IF;
  -- -------------------------------------------
  -- Commit Once all the all the process is
  -- done and calling after print message summary procedure
  -- -------------------------------------------
  COMMIT; -- Commit after all the records processed
  x_retstatus := gn_normal;
  ------------------------------------
  -- Start of Changes for Defect #3983   -- Output Section -- BO_INVOICE_EXISTS
  ------------------------------------
  IF gn_tot_bo_inv_processed > 0 THEN
        bo_invoice_status_report  (x_errmsg      => lc_errmsg
                                  ,x_retstatus   => ln_retcode
                                  );
      IF ln_retcode  = gn_error THEN
        lc_error_location := 'Error at BO Invoice Status Report Call '|| lc_errmsg;
        RAISE EX_MAIN_EXCEPTION;
      END IF;
        FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LPAD('Count of Invoices Matched with BO Order Suffix --  '||
gn_tot_bo_inv_processed,76,' '));
        FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
  ELSE
        FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LPAD('BO Invoice Exists Status Report',76,' '));
        FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'========================================================================');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Count of Invoices matched with back order suffix : 0')  ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'========================================================================');
  END IF;
  ------------------------------------
  -- End of Changes for Defect #3983
  ------------------------------------
  -- -------------------------------------------
  -- Loop through all the Distinct status and
  -- calling the print autocash processed status
  -- -------------------------------------------
  ln_match_status_count := 0;
  OPEN lcu_get_dist_status
  ( p_process_num  => p_process_num
   ,p_record_type  => '6'
   );
  LOOP
  FETCH lcu_get_dist_status INTO get_dist_status;
  EXIT WHEN lcu_get_dist_status%NOTFOUND;
    -- -------------------------------------------
    -- Call the Auto Cash Rule Report
    -- -------------------------------------------
    ln_match_status_count := ln_match_status_count + 1;
    put_log_line('ln_match_status_count='||ln_match_status_count || ' for ' || get_dist_status.inv_match_status);
    print_autocash_report
    (x_errmsg      => lc_errmsg
     ,x_retstatus   => ln_retcode
     ,p_process_num => p_process_num
     ,p_status      => get_dist_status.inv_match_status
     ,pn_match_status_count => ln_match_status_count
     );

    IF ln_retcode  = gn_error THEN
      lc_error_location := 'Error at Autocash Print Report: '|| lc_errmsg;
      RAISE EX_MAIN_EXCEPTION;
    END IF;

  END LOOP;
  CLOSE lcu_get_dist_status;

  -- -------------------------------------------
  -- Call the Auto Cash Rule Totals Report
  -- -------------------------------------------
  put_log_line('ln_match_status_count='||ln_match_status_count);
  IF ln_match_status_count > 0 THEN
      print_autocash_report_totals(x_errmsg      => lc_errmsg
                                  ,x_retstatus   => ln_retcode
                                  ,pn_match_status_count => ln_match_status_count
                                  );

      IF ln_retcode  = gn_error THEN
        lc_error_location := 'Error at Autocash Print Report Totals: '|| lc_errmsg;
        RAISE EX_MAIN_EXCEPTION;
      END IF;
  END IF;

  -- -----------------------------------------------------------------------
  -- Call the BAI Customer Validation Report -- print_cust_validation_report
  -- Start of changes for CR#684 -- Defect #1858 on 11-DEC-09
  -- -----------------------------------------------------------------------
  IF gn_tot_cust_removed > 0 THEN
      put_log_line('Total Number of BAI Customers Removed(as they were related to MICR Customer):'||gn_tot_cust_removed);
      print_cust_validation_report(x_errmsg      => lc_errmsg
                                  ,x_retstatus   => ln_retcode
                                  );
      IF ln_retcode  = gn_error THEN
        lc_error_location := 'Error at Print Cust Validation Report '|| lc_errmsg;
        RAISE EX_MAIN_EXCEPTION;
      END IF;
  ELSE
        FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LPAD('BAI Customer Number Validation Report',76,' '));
        FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'========================================================================');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Customer Numbers Removed                        : '||gn_tot_cust_removed);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'========================================================================');
  END IF;
  --------------------------------------------------------------
  --End of Changes for CR#684 -- Defect #1858 on 11-DEC-09
  --------------------------------------------------------------
  XX_MATCHED_INVOICES(NULL,'DELETE',lc_trxn_not_exists);   --To Purge Global Temp Table
  put_log_line('[END] CUSTOM_AUTO_CASH - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

EXCEPTION
WHEN EX_MAIN_EXCEPTION THEN
  ROLLBACK;

  x_errmsg   := lc_error_location ||'-'||lc_error_details;
  x_retstatus:= gn_error;
  put_log_line('==========================');
  put_log_line(x_errmsg);
WHEN OTHERS THEN
  ROLLBACK;

  fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_AR_LOCKBOX_PROCESS_PKG.CUSTOM_AUTO_CASH');
  fnd_message.set_token('PROGRAM','Lockbox Custom Autocash Matching');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg     := lc_error_location||'-'||lc_error_details||'-'||fnd_message.get;
  x_retstatus  := gn_error;
      -- -------------------------------------------
      -- Call the Custom Common Error Handling
      -- -------------------------------------------
      XX_COM_ERROR_LOG_PUB.LOG_ERROR
             (
                p_program_type            => 'CONCURRENT PROGRAM'
               ,p_program_name            => gc_conc_short_name
               ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
               ,p_module_name             => 'AR'
               ,p_error_location          => 'Error at ' || lc_error_location
               ,p_error_message_count     => 1
               ,p_error_message_code      => 'E'
               ,p_error_message           => lc_error_details
               ,p_error_message_severity  => 'Major'
               ,p_notify_flag             => 'N'
               ,p_object_type             => 'LOCKBOX AUTOCASH'
             );
  put_log_line('==========================');
  put_log_line(x_errmsg);
  --
END CUSTOM_AUTO_CASH;

END XX_AR_LOCKBOX_PROCESS_PKG;
/
SHOW ERROR
