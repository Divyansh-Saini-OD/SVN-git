/* Formatted on 2011/06/21 14:22 (Formatter Plus v4.8.0) */
SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body xx_ce_cc_fee_pkg
PROMPT Program exits if the creation is not successful

create or replace
PACKAGE BODY xx_ce_cc_fee_pkg
AS
-- +===================================================================================+
-- |                            Oracle Consulting                                      |
-- +===================================================================================+
-- | Name       : XX_CE_CC_FEE_PKG.pkb                                                 |
-- | Description: Cash Management AJB Creditcard Fee Journals Program                  |
-- |                                                                                   |
-- |Change Record                                                                      |
-- |==============                                                                     |
-- |Version   Date         Authors              Remarks                                |
-- |========  ===========  ===============      ============================           |
-- |Draft 1A  04-Mar-2011  Sreenivasa Tirumala  Intial Draft Version                   |
-- |1.0       04-Mar-2011  Sreenivasa Tirumala  Intial Draft Version                   |
-- |1.1       02-Jun-2011  Sreenivasa Tirumala  Defect-11849 - Added code to check     |
-- |                                            for the Company based on Currency of   |
-- |                                            999 Interface table                    |
-- |1.2       21-Jun-2011  Gaurav Agarwal       Defect-12224 - OD CM Credit Card Fees- |
-- |                                            Hard Coded LOB as 90 for CR entry      |
-- |1.3       17-Aug-2011  Sreenivasa Tirumala  Code changed for Defect- 13233         |
-- |                                            Credit Card Fee Journal booked 4 times |
-- |1.4       23-Oct-2013  KirubhaSamuel        Code changed for Defect- 25473         |
-- |1.5	      01-Apr-2015  Rakesh Polepalli     Code changed for Defect- 33616         |
-- |1.6       28-Oct-2015  Avinash Baddam       R12.2 Compliance changes
-- +===================================================================================+

   -- -------------------------------------------
-- Global Variables
-- ----------------------------------------------
   gn_request_id                 NUMBER := fnd_global.conc_request_id;
   gn_user_id                    NUMBER := fnd_global.user_id;
   gn_org_id                     NUMBER := fnd_profile.VALUE ('ORG_ID');
   gn_set_of_bks_id              NUMBER := fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
   gc_conc_short_name            VARCHAR2 (30) := 'XXCEAFEEJRNL';
   gn_error                      NUMBER := 2;
   gn_warning                    NUMBER := 1;
   gn_normal                     NUMBER := 0;
   gn_coa_id                     NUMBER;
   gc_delimiter                  VARCHAR2 (30) := '.';
   gc_currency_code              VARCHAR2 (30);
   g_print_line                  VARCHAR2 (125) := '------------------------------------------------------------------------------------------------------------------------';

-- +=================================================================================+
-- | Name        : update_xx_ce_999                                                  |
-- | Description : This procedure will be used to update                             |
-- |               record process details                                            |
-- |                                                                                 |
-- | Parameters  : None                                                              |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- |                                                                                 |
-- +=================================================================================+
   PROCEDURE update_xx_ce_999 (
      p_provider_code IN VARCHAR2
    , p_bank_rec_id IN VARCHAR2
   )
   IS
      ln_count                      NUMBER := 0;
   BEGIN
-- ------------------------------------------------
-- Set the Concurrent program Output header display
-- ------------------------------------------------
      fnd_file.put_line (fnd_file.LOG, ' Before Updating xx_ce_999_interface ');

      UPDATE xx_ce_999_interface xc9i
         SET x999_gl_complete = 'Y'
           , last_update_date = SYSDATE
           , last_updated_by = fnd_global.user_id
       WHERE NVL (x999_gl_complete, 'N') != 'Y'
         AND record_type = 'AJB'
         AND processor_id = p_provider_code
         AND bank_rec_id = NVL (p_bank_rec_id, bank_rec_id)
         AND xc9i.deposits_matched = 'Y'
         AND NOT EXISTS (SELECT 1
                           FROM xx_ce_ajb999 xca
                          WHERE 1 = 1
                            AND xca.bank_rec_id = xc9i.bank_rec_id
                            AND xca.processor_id = xc9i.processor_id);

      ln_count    := SQL%ROWCOUNT;
      fnd_file.put_line (fnd_file.LOG, ' Total records updated  :' || ln_count);
      fnd_file.put_line (fnd_file.LOG, ' After Updating xx_ce_999_interface ');
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, ' Error While updating xx_ce_999_interface in update_xx_ce_999 :' || SQLERRM);
   END update_xx_ce_999;

-- +=================================================================================+
-- | Name        : PRINT_MESSAGE_HEADER                                              |
-- | Description : This procedure will be used to print the                          |
-- |               record process details                                            |
-- |                                                                                 |
-- | Parameters  : None                                                              |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- |                                                                                 |
-- +=================================================================================+
   PROCEDURE print_message_header (
      x_errbuf OUT NOCOPY VARCHAR2
    , x_retcode OUT NOCOPY NUMBER
   )
   IS
   BEGIN
-- ------------------------------------------------
-- Set the Concurrent program Output header display
-- ------------------------------------------------
      fnd_file.new_line (fnd_file.output, 1);
      fnd_file.put_line (fnd_file.output, LPAD (' ', 40, ' ') || 'AJB Creditcard Fee Reconciliation');
      fnd_file.new_line (fnd_file.output, 1);
      fnd_file.put_line (fnd_file.output, 'Request ID: ' || gn_request_id || RPAD (' ', 60, ' ') || 'Request Date: ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MM'));
      fnd_file.put_line (fnd_file.output, RPAD ('-', 120, '-'));
      fnd_file.new_line (fnd_file.output, 1);
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('BankRecID', 18, ' ')
                         || ' '
                         || RPAD ('Processor', 9, ' ')
                         || ' '
                         || RPAD ('Card Type', 10, ' ')
                         || ' '
                         || RPAD ('Store', 6, ' ')
                         || ' '
                         || LPAD ('Net Amount', 12, ' ')
                         || ' '
                         || RPAD ('Recon Date', 10, ' ')
                         || ' '
                         || 'Status'
                        );
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('-', 18, '-')
                         || ' '
                         || RPAD ('-', 9, '-')
                         || ' '
                         || RPAD ('-', 10, '-')
                         || ' '
                         || RPAD ('-', 6, '-')
                         || ' '
                         || RPAD ('-', 12, '-')
                         || ' '
                         || RPAD ('-', 10, '-')
                         || ' '
                         || RPAD ('-', 120 - 71, '-')
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE', 'XX_CE_CC_FEE_PKG.print_message_header');
         fnd_message.set_token ('PROGRAM', 'CE AJB Creditcard Fee Journals Program');
         fnd_message.set_token ('SQLERROR', SQLERRM);
         x_errbuf     := fnd_message.get;
         x_retcode    := gn_error;
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
   END print_message_header;

-- +=================================================================================+
-- |                                                                                 |
-- | PROCEDURE                                                                       |
-- |   print_message_footer                                                          |
-- |                                                                                 |
-- | DESCRIPTION                                                                     |
-- |  Procedure to Print the Message Details                                         |
-- |                                                                                 |
-- | PARAMETERS                                                                      |
-- | ==========                                                                      |
-- | NAME                    TYPE    DESCRIPTION                                     |
-- | ----------------------- ------- ----------------------------------------        |
-- | x_errbuf                 OUT     Error message.                                 |
-- | x_retcode                OUT     Error code.                                    |
-- | p_bank_rec_id            IN      Message Details                                |
-- | p_processor_id           IN      Processor Code                                 |
-- | p_card_type              IN      Card Type                                      |
-- | p_store_num              IN      Store Number                                   |
-- | p_net_amount             IN      Net Amount                                     |
-- | p_process_date           IN      Process Date                                   |
-- | p_message                IN      Message Details                                |
-- +=================================================================================+
   PROCEDURE print_message_footer (
      x_errbuf OUT NOCOPY VARCHAR2
    , x_retcode OUT NOCOPY NUMBER
    , p_bank_rec_id IN VARCHAR2
    , p_processor_id IN VARCHAR2
    , p_card_type IN VARCHAR2
    , p_store_num IN VARCHAR2
    , p_net_amount IN NUMBER
    , p_process_date IN VARCHAR2
    , p_message IN VARCHAR2
   )
   IS
   BEGIN
      IF p_message IS NULL
      THEN
         fnd_file.put_line (fnd_file.output
                          ,    RPAD (NVL (p_bank_rec_id, ' '), 18, ' ')
                            || ' '
                            || RPAD (NVL (p_processor_id, ' '), 9, ' ')
                            || ' '
                            || RPAD (NVL (p_card_type, ' '), 10, ' ')
                            || ' '
                            || RPAD (p_store_num, 6, ' ')
                            || ' '
                            || LPAD (NVL (p_net_amount, 0), 12, ' ')
                            || ' '
                            || LPAD (NVL (p_process_date, ' '), 10)
                            || ' '
                            || REPLACE (p_message, CHR (10), CHR (10) || RPAD (' ', (40), ' '))
                           );
      ELSE
         fnd_file.put_line (fnd_file.output
                          ,    RPAD (NVL (p_bank_rec_id, ' '), 18, ' ')
                            || ' '
                            || RPAD (NVL (p_processor_id, ' '), 9)
                            || ' '
                            || RPAD (NVL (p_card_type, ' '), 10, ' ')
                            || ' '
                            || RPAD (p_store_num, 6, ' ')
                            || ' '
                            || LPAD (NVL (p_net_amount, 0), 12, ' ')
                            || ' '
                            || LPAD (NVL (p_process_date, ' '), 10)
                            || ' '
                            || REPLACE (p_message, CHR (10), CHR (10) || RPAD (' ', (40), ' '))
                           );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE', 'XX_CE_CC_FEE_PKG.print_message_footer');
         fnd_message.set_token ('PROGRAM', 'CE AJB Creditcard Fee Journals Program');
         fnd_message.set_token ('SQLERROR', SQLERRM);
         x_errbuf     := fnd_message.get;
         x_retcode    := gn_error;
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
   END print_message_footer;

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  print_message_summary                                                          |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | Procedure to Print Summary of the Record Process                                |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message.                                  |
-- |x_retcode                OUT     Error code.                                     |
-- |p_total                  IN      Total Records Found                             |
-- |p_error                  IN      Error Records                                   |
-- |p_success                IN      Success Records                                 |
-- +=================================================================================+
   PROCEDURE print_message_summary (
      x_errbuf OUT NOCOPY VARCHAR2
    , x_retcode OUT NOCOPY NUMBER
    , p_total IN NUMBER
    , p_error IN NUMBER
    , p_success IN NUMBER
   )
   IS
   BEGIN
      IF p_total > 0
      THEN
         fnd_file.new_line (fnd_file.output, 2);
-------------------------------------------------------------------------------------------------
         fnd_file.put_line (fnd_file.output, '===============================================================');
         fnd_file.put_line (fnd_file.output, 'CE AJB Creditcard Reconciliation Extension : ' || 'E2081');
         fnd_file.put_line (fnd_file.output, '===============================================================');
         fnd_file.put_line (fnd_file.output, 'Total Records Found               : ' || NVL (p_total, 0));
         fnd_file.put_line (fnd_file.output, 'Error Records                     : ' || NVL (p_error, 0));
         fnd_file.put_line (fnd_file.output, 'Success Records                   : ' || NVL (p_success, 0));
         fnd_file.put_line (fnd_file.output, '===============================================================');
      ELSE
-------------------------------------------------------------------------------------------------------------
         fnd_file.new_line (fnd_file.output, 2);
         fnd_file.put_line (fnd_file.output, RPAD ('-', 46, '-') || '  No Store Fees to process  ' || RPAD ('-', 46, '-'));
-------------------------------------------------------------------------------------------------------------
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE', 'XX_CE_CC_FEE_PKG.print_message_summary');
         fnd_message.set_token ('PROGRAM', 'CE AJB Creditcard Fee Journals');
         fnd_message.set_token ('SQLERROR', SQLERRM);
         x_errbuf     := fnd_message.get;
         x_retcode    := gn_error;
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
   END print_message_summary;

-- +=================================================================================+
-- | Name        : CREATE_FEE_JOURNAL                                                |
-- | Description : Procedure to create Journals on the Credit Card Fees provided     |
-- |               by AJB                                                            |
-- |                                                                                 |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message                                   |
-- |x_retcode                OUT     Error code                                      |
-- |p_provider_code          IN      Provider Code                                   |
-- |p_bank_rec_id            IN      Bank Reconciliation ID                          |
-- +=================================================================================+
   PROCEDURE create_fee_journal (
      x_errbuf OUT NOCOPY VARCHAR2
    , x_retcode OUT NOCOPY NUMBER
    , p_provider_code IN VARCHAR2
    , p_bank_rec_id IN VARCHAR2
   )
   IS
      CURSOR lcu_get_intf_batches (
         lp_processor_id VARCHAR2
       , lp_bank_rec_id VARCHAR2
      )
      IS
         SELECT trx_id
              , bank_rec_id
              , processor_id
              , trx_date
              , currency_code
           FROM xx_ce_999_interface xc9i
          WHERE 1 = 1
            AND record_type = 'AJB'
            AND processor_id = NVL (lp_processor_id, xc9i.processor_id)
            AND xc9i.deposits_matched = 'Y'
            AND NVL (xc9i.x999_gl_complete, 'N') = 'N'
            AND xc9i.status = 'FLOAT'
            AND xc9i.bank_rec_id = NVL (lp_bank_rec_id, xc9i.bank_rec_id)
            AND ((EXISTS (SELECT 1
                            FROM xx_ce_ajb999_v xca9
							WHERE NVL (xca9.attribute1, 'FEE_RECON_NO') != 'FEE_RECON_YES'      -- Added for the Defect 6138.
                           --WHERE NVL (xca9.status_1310, 'ERROR') != 'PROCESSED'			--commented for the defect#33616
                             AND xca9.bank_rec_id = xc9i.bank_rec_id
                             AND xca9.processor_id = xc9i.processor_id)
                 )
                );

      CURSOR lcu_get_recon_batches (
         p_processor_id VARCHAR2
       , p_bank_rec_id VARCHAR2
      )
      IS
         SELECT   xcan.bank_rec_id
                , xcan.processor_id
                , xcan.store_num
                , xcan.recon_date
                , xcan.currency
                , xcan.cardtype card_type
                , SUM (  NVL (  NVL (xcan.adj_fee, 0)
                              + NVL (xcan.cost_funds_amt, 0)
                              + NVL (xcan.deposit_hold_amt, 0)
                              + NVL (xcan.deposit_release_amt, 0)
                              + NVL (xcan.discount_amt, 0)
                              + NVL (xcan.monthly_assessment_fee, 0)
                              + NVL (xcan.monthly_discount_amt, 0)
                              + NVL (xcan.reserved_amt, 0)
                              + NVL (xcan.service_fee, 0)
                            , 0
                             )
                       * -1
                      ) net_amount
             FROM xx_ce_ajb999_v xcan                                                                                                                 --xx_ce_ajb_net_amounts_v xcan
            WHERE 1 = 1
              AND xcan.bank_rec_id = p_bank_rec_id
              AND xcan.processor_id = p_processor_id
              AND NVL (xcan.attribute1, 'FEE_RECON_NO') != 'FEE_RECON_YES'                                                                            --  Added for the Defect 6138.
         --   AND xcan.store_num = '005910'
         --   AND ROWNUM <10
         GROUP BY xcan.bank_rec_id
                , xcan.processor_id
                , xcan.store_num
                , xcan.recon_date
                , xcan.currency
                , xcan.cardtype;

      CURSOR lcu_get_recon_hdr (
         p_processor IN VARCHAR2
       , p_card_type IN VARCHAR2
       , p_process_date IN DATE
       , p_store_num IN NUMBER
      )
      IS
         SELECT DISTINCT xcgh.header_id
                       , xcgh.provider_code
                       , xcgh.org_id
                       , xcgh.ajb_card_type
                       , xcgh.recon_credit_costcenter ar_recv_costcenter
                       , xcgh.recon_credit_account ar_recv_account
                       , xcgh.recon_card_type_costcenter card_type_costcenter
                       , xcgh.recon_card_type_account card_type_account
                       , xcgh.bank_clearing_costcenter
                       , xcgh.bank_clearing_account
                       , xcgh.bank_clearing_location
                    FROM xx_ce_recon_glact_hdr_v xcgh
                   WHERE xcgh.provider_code = p_processor
                     AND xcgh.ajb_card_type = p_card_type
                     AND p_process_date BETWEEN xcgh.effective_from_date AND NVL (xcgh.effective_to_date, p_process_date + 1)
                ORDER BY xcgh.provider_code
                       , xcgh.ajb_card_type;

-------------------------------------------
-- Get all the un-processed store fees summaries
-- by procesor id and cardtype
-- -------------------------------------------
      CURSOR lcu_get_store_fees (
         p_bank_rec_id IN VARCHAR2
       , p_processor_id IN VARCHAR2
       , p_card_type IN VARCHAR2
       , p_store_num IN VARCHAR2
       , p_currency IN VARCHAR2
      )
      IS
         SELECT   LPAD (xca9.store_num, 6, '0') store_num
                , xca9.provider_type
                , xca9.cardtype
                , xca9.submission_date
                , xca9.processor_id
                , xca9.sequence_id_999
                , xca9.bank_rec_id
                , xca9.currency
             FROM xx_ce_ajb999_v xca9
			 WHERE NVL (xca9.attribute1, 'FEE_RECON_NO') != 'FEE_RECON_YES'                       -- Added for the defect 6138.
            --WHERE NVL (xca9.status_1310, 'ERROR') != 'PROCESSED'										-- commented for the defect#33616
              AND bank_rec_id = p_bank_rec_id
              AND processor_id = p_processor_id
              AND cardtype = p_card_type
              AND store_num = p_store_num
              AND currency = p_currency
         ORDER BY 1
                , 2
                , 3;

-- -------------------------------------------
-- Get the details accounts to reconcile
-- -------------------------------------------
      CURSOR lcu_get_recon_dtl (
         p_header_id IN VARCHAR2
       , p_process_date IN DATE
       , p_store_num IN NUMBER
      )
      IS
         SELECT xcrd.details_id
              , xcrd.charge_code
              , xcrd.charge_description
              , xcrd.costcenter charge_costcenter
              , xcrd.charge_debit_act charge_debit_account
              , xcrd.charge_credit_act charge_credit_account
              , xcrd.location_from
              , xcrd.location_to
              , xcrd.effective_from_date
              , xcrd.effective_to_date
           FROM xx_ce_recon_glact_dtl xcrd
          WHERE 1 = 1
            AND xcrd.header_id = p_header_id
            AND p_store_num BETWEEN xcrd.location_from AND xcrd.location_to
            AND p_process_date BETWEEN xcrd.effective_from_date AND NVL (xcrd.effective_to_date, p_process_date + 1);

-- -------------------------------------------
-- Get the Chart of Accounts ID
-- -------------------------------------------
      CURSOR lcu_get_coaid
      IS
         SELECT gsob.chart_of_accounts_id
              , gsob.currency_code
           FROM gl_sets_of_books gsob
          WHERE set_of_books_id = gn_set_of_bks_id;

-- -------------------------------------------
-- Local Variable Declaration
-- -------------------------------------------
      intf_batches_rec              lcu_get_intf_batches%ROWTYPE;
      store_fee_rec                 lcu_get_store_fees%ROWTYPE;
      recon_batches_rec             lcu_get_recon_batches%ROWTYPE;
      recon_hdr_rec                 lcu_get_recon_hdr%ROWTYPE;
      recon_dtl_rec                 lcu_get_recon_dtl%ROWTYPE;
      lc_error_details              VARCHAR2 (32000);
      lc_error_location             VARCHAR2 (32000);
      lc_errmsg                     VARCHAR2 (2000);
      lc_output_msg                 VARCHAR2 (2000);
      lc_trx_valid_flag             VARCHAR2 (1);
      lc_source_err_flag            VARCHAR2 (1);
      lc_err_msg                    VARCHAR2 (2000);
      --lc_provider_code            VARCHAR2(30);
      lc_email_addr                 VARCHAR2 (60);
      lc_sql                        VARCHAR2 (4000);
      lc_company                    VARCHAR2 (150);
      lc_intercompany               VARCHAR2 (30) := '0000';
      lc_future                     VARCHAR2 (30) := '000000';
      lc_ar_recv_lob                VARCHAR2 (150);
      lc_card_type_lob              VARCHAR2 (150);
      lc_bank_clearing_lob          VARCHAR2 (150);
      lc_charge_lob                 VARCHAR2 (150);
      lc_error_flag                 VARCHAR2 (1) := 'N';
      ln_no_fee_count               NUMBER := 0;
      ln_success_rec                NUMBER := 0;
      ln_total_rec                  NUMBER := 0;
      ln_error_rec                  NUMBER := 0;
      ln_currency_cnt               NUMBER := 0;
      ln_retcode                    NUMBER;
      ln_err_msg_count              NUMBER;
      ln_group_id                   NUMBER;
      ln_charge_amt                 NUMBER;
      ln_charge_total               NUMBER;
      ln_ar_recv_ccid               NUMBER;
      lc_ar_recv_acct               gl_code_combinations_kfv.concatenated_segments%TYPE;
      --ln_card_type_ccid           NUMBER;
      --lc_card_type_acct           gl_code_combinations_kfv.concatenated_segments%TYPE;
      ln_bank_clearing_ccid         NUMBER;
      lc_bank_clearing_acct         gl_code_combinations_kfv.concatenated_segments%TYPE;
      ln_charge_ccid                NUMBER;
      lc_charge_acct                gl_code_combinations_kfv.concatenated_segments%TYPE;
      ln_entered_dr_amount          NUMBER;
      ln_entered_cr_amount          NUMBER;
      ln_mail_request_id            NUMBER;
      lc_mail_address               VARCHAR2 (1000);                                                                                                    -- Added for the Defect 6138
      lc_errored_store              CLOB;                                                                                                               -- Added for the Defect 6138
      lc_err_store_num              CLOB;                                                                                                               -- Added for the Defect 6138
      lc_count_flag                 VARCHAR2 (1);                                                                                                       -- Added for the Defect 6138
      lc_user_source_name           VARCHAR2 (50) := 'OD CM Credit Card Fee';
      ln_application_id             fnd_application.application_id%TYPE;
      lc_period_name                gl_period_statuses.period_name%TYPE;
      ex_main_exception             EXCEPTION;
      lc_recon_batch_savepoint      VARCHAR2 (100);
      lc_intf_batch_savepoint       VARCHAR2 (100);
      ex_recon_batch_exception      EXCEPTION;
      ex_recon_batch_exception1     EXCEPTION;
      ex_store_fee_exception        EXCEPTION;
      lc_store_fees_savepoint       VARCHAR2 (100);
      lc_je_line_desc               gl_je_lines.description%TYPE;
      lc_orig_store_num             xx_ce_ajb999.store_num%TYPE;
      lc_message                    VARCHAR2 (100);
      lc_orig_card_type             xx_ce_ajb999.cardtype%TYPE;
      --Added for Release 1.1 CR 601 Defect 1419
      lc_translation_type  CONSTANT VARCHAR (200) := 'XX_CM_1310_CLEARING_ACCNT';
      lc_org_name                   hr_all_organization_units.NAME%TYPE;
      lc_ccid_company               xx_fin_translatevalues.target_value1%TYPE;
      lc_ccid_location              xx_fin_translatevalues.target_value2%TYPE;
      lc_ccid_intercompany          xx_fin_translatevalues.target_value3%TYPE;
      lc_ccid_future                xx_fin_translatevalues.target_value4%TYPE;
      lc_ccid_lob                   xx_fin_translatevalues.target_value5%TYPE;
      lc_ccid_costcenter            xx_fin_translatevalues.target_value6%TYPE;
      ln_entered_dr_total           NUMBER := 0;
      ln_entered_cr_total           NUMBER := 0;
      ln_gross_amount               NUMBER := 0;

      --End of changes for Release 1.1 CR 601 Defect 1419
      TYPE ret_fee_amt_type IS REF CURSOR;

      lc_ret_fee_amt_cur            ret_fee_amt_type;
      lc_period_start               gl_periods.period_name%TYPE;
      lc_ar_recv_costcenter         VARCHAR2 (100);
      lc_bank_clearing_account      VARCHAR2 (100);
      lc_processed                  VARCHAR2 (100) := 'Processed';
      ln_store_count                NUMBER := 0;
      lc_instance                   VARCHAR2 (100);
      lc_company1                   VARCHAR2 (150);                                                                                                         -- V1.1 - Added variable
   BEGIN
      xx_ce_cc_common_pkg.od_message ('M', ' ');
      xx_ce_cc_common_pkg.od_message ('M', '  ----------------------    Start Recon Process     ------------------------');
      xx_ce_cc_common_pkg.od_message ('M', ' ');
      xx_ce_cc_common_pkg.od_message ('M', 'Parameters - Provider:' || NVL (p_provider_code, 'ALL') || '   Bank Reconciliation ID: ' || NVL (p_bank_rec_id, 'ALL'));
      xx_ce_cc_common_pkg.od_message ('M', ' ');
-- -------------------------------------------
-- Initializing Local Variables
-- -------------------------------------------
      lc_error_location     := 'Initializing Local Variables';
      lc_source_err_flag    := 'N';
      lc_trx_valid_flag     := 'N';
      lc_error_details      := NULL;
      lc_errmsg             := NULL;
      lc_output_msg         := NULL;
      lc_err_msg            := NULL;
      ln_retcode            := 0;
      ln_currency_cnt       := 0;
      ln_err_msg_count      := 0;
-- -------------------------------------------
-- Check the set of Books ID
-- -------------------------------------------
      lc_error_location     := 'Mandatory Check Set of Books Id';

      IF gn_set_of_bks_id IS NULL
      THEN
         lc_source_err_flag    := 'Y';
         fnd_message.set_name ('XXFIN', 'XX_CE_002_SOB_NOT_SETUP');
         lc_error_details      := lc_error_details || '-' || fnd_message.get;
      END IF;

      IF gn_set_of_bks_id IS NOT NULL
      THEN
         OPEN lcu_get_coaid;

         FETCH lcu_get_coaid
          INTO gn_coa_id
             , gc_currency_code;

         CLOSE lcu_get_coaid;

         IF gn_coa_id IS NULL
         THEN
            lc_source_err_flag    := 'Y';
            fnd_message.set_name ('XXFIN', 'XX_CE_003_COA_NOT_SETUP');
            lc_error_details      := lc_error_details || '-' || fnd_message.get;
         END IF;
      END IF;

      xx_ce_cc_common_pkg.od_message ('M', 'Chart of Accounts ID:' || gn_coa_id);

-- -------------------------------------------
-- Get the GL Period Name
-- -------------------------------------------
      BEGIN
         SELECT period_name
           INTO lc_period_start
           FROM gl_periods gp
          WHERE gp.period_set_name = 'OD 445 CALENDAR'
            AND TO_DATE (SYSDATE) BETWEEN gp.start_date AND gp.end_date;

         xx_ce_cc_common_pkg.od_message ('M', 'GL Period:' || lc_period_start);
      EXCEPTION
         WHEN OTHERS
         THEN
            lc_source_err_flag    := 'Y';
            xx_ce_cc_common_pkg.od_message ('M', 'Exception Raised when getting GL Periods' || SQLERRM);
      END;

-- -------------------------------------------
-- Get the Delimiter.
-- -------------------------------------------
      gc_delimiter          := fnd_flex_ext.get_delimiter (application_short_name => 'SQLGL', key_flex_code => 'GL#', structure_number => gn_coa_id);
-- -------------------------------------------
-- Call the Print Message Header
-- -------------------------------------------
      print_message_header (x_errbuf => lc_errmsg, x_retcode => ln_retcode);
      lc_error_location     := 'Start.';
-- -------------------------------------------
-- Get all the Matched Recon batches with un-processed fees.
-- -------------------------------------------
      ln_success_rec        := 0;
      ln_error_rec          := 0;

-- --------------------------------------------
--  Get all Unreconciled Batches
-- --------------------------------------------
      FOR intf_batches_rec IN lcu_get_intf_batches (p_provider_code, p_bank_rec_id)
      LOOP
         lc_intf_batch_savepoint    := recon_batches_rec.processor_id || '-' || recon_batches_rec.bank_rec_id;
         SAVEPOINT lc_intf_batch_savepoint;
         ln_entered_cr_total        := 0;
         ln_entered_dr_total        := 0;
         lc_company1                := NULL;

         OPEN lcu_get_recon_batches (intf_batches_rec.processor_id, intf_batches_rec.bank_rec_id);

         LOOP
            BEGIN
               FETCH lcu_get_recon_batches
                INTO recon_batches_rec;

               EXIT WHEN lcu_get_recon_batches%NOTFOUND;

-- -------------------------------------------------
-- Get group id for all GL transaction entries Once.
-- -------------------------------------------------
               IF NVL (ln_group_id, 0) = 0
               THEN
                  SELECT gl_interface_control_s.NEXTVAL
                    INTO ln_group_id
                    FROM DUAL;

                  xx_ce_cc_common_pkg.od_message ('M', 'Group ID:' || ln_group_id);
               END IF;

-- -------------------------------------------
-- Loop through all the statement records
-- for the from and to date range
-- -------------------------------------------
               lc_error_location           := 'Recon Batches before savepoint';
               lc_recon_batch_savepoint    :=    recon_batches_rec.processor_id
                                              || '-'
                                              || recon_batches_rec.card_type
                                              || '-'
                                              || recon_batches_rec.bank_rec_id
                                              || '-'
                                              || recon_batches_rec.store_num;
               SAVEPOINT lc_recon_batch_savepoint;
               lc_error_details            := NULL;
               lc_error_flag               := 'N';
               lc_source_err_flag          := 'N';
               lc_trx_valid_flag           := 'N';
               lc_period_name              := NULL;
               lc_output_msg               := NULL;
               ln_currency_cnt             := 0;
               --ln_diff_amount := 0;
               --lc_provider_code := NULL;
               lc_sql                      := NULL;
               lc_company                  := NULL;
               lc_ar_recv_lob              := NULL;
               --lc_card_type_lob := NULL;
               lc_bank_clearing_lob        := NULL;
               lc_charge_lob               := NULL;
               ln_ar_recv_ccid             := NULL;
               --ln_card_type_ccid := NULL;
               ln_bank_clearing_ccid       := NULL;
               ln_charge_ccid              := NULL;
               -- ln_net_amount := 0;
               ln_charge_total             := 0;
               ln_total_rec                := ln_total_rec + 1;
               xx_ce_cc_common_pkg.od_message ('M', ' ');
               xx_ce_cc_common_pkg.od_message ('M', g_print_line);
               fnd_file.put_line (fnd_file.LOG, 'RECORD NUMBER : ' || ln_total_rec);
               lc_message                  := NULL;
               xx_ce_cc_common_pkg.od_message ('M', ' ');
               xx_ce_cc_common_pkg.od_message ('M'
                                             ,    'Process Bank Rec ID:'
                                               || recon_batches_rec.bank_rec_id
                                               || ' / Provider:'
                                               || recon_batches_rec.processor_id
                                               || ' / Card Type:'
                                               || NVL (recon_batches_rec.card_type, 'Not Found')
                                               || ' / Store:'
                                               || recon_batches_rec.store_num
                                               || ' / Net Amount:'
                                               || recon_batches_rec.currency
                                               || ' '
                                               || recon_batches_rec.net_amount
                                              );
               lc_message                  := NULL;
               lc_orig_card_type           := recon_batches_rec.card_type;

               IF recon_batches_rec.card_type IS NULL
               THEN
                  recon_batches_rec.card_type    := xx_ce_cc_common_pkg.get_default_card_type (recon_batches_rec.processor_id, gn_org_id                   --Added for Defect #1061
                                                                                                                                        );
                  lc_message                     := 'Default Card Type to ' || recon_batches_rec.card_type || '. ';
                  xx_ce_cc_common_pkg.od_message ('M', 'No Card type - Defaulting to ' || recon_batches_rec.card_type);
               END IF;

               IF recon_batches_rec.card_type IS NULL
               THEN
                  xx_ce_cc_common_pkg.od_message ('M', 'Cannot default Card Type for Provider!');
                  lc_error_flag    := 'Y';
                  RAISE ex_recon_batch_exception;
               END IF;

               lc_orig_store_num           := recon_batches_rec.store_num;

               --Defect 8802 - If Store comes in as '000000' then use '001099'.
               IF    recon_batches_rec.store_num = '000000'
                  OR recon_batches_rec.store_num IS NULL
               THEN
                  recon_batches_rec.store_num    := '001099';
               END IF;

               IF NVL (lc_orig_store_num, '0') != recon_batches_rec.store_num
               THEN
                  IF lc_message IS NOT NULL
                  THEN
                     lc_message    := lc_message || '. ';
                  END IF;

                  lc_message    := lc_message || 'Used Location 001099 for Accounting. ';
                  xx_ce_cc_common_pkg.od_message ('M', '* * ' || lc_message);
               END IF;

               IF lcu_get_recon_hdr%ISOPEN
               THEN
                  CLOSE lcu_get_recon_hdr;
               END IF;

               recon_hdr_rec               := NULL;

               -- Defect 9402
               BEGIN
                  OPEN lcu_get_recon_hdr (p_processor         => recon_batches_rec.processor_id
                                        , p_card_type         => recon_batches_rec.card_type
                                        , p_process_date      => recon_batches_rec.recon_date
                                        , p_store_num         => lc_orig_store_num
                                         --recon_batches_rec.store_num
                                         );

                  FETCH lcu_get_recon_hdr
                   INTO recon_hdr_rec;

                  CLOSE lcu_get_recon_hdr;

                  IF recon_hdr_rec.header_id IS NULL
                  THEN
                     xx_ce_cc_common_pkg.od_message ('M', 'Invalid Card Type for Provider! ' || recon_batches_rec.card_type);
                     lc_error_flag    := 'Y';
                     RAISE ex_recon_batch_exception;
                  END IF;
               EXCEPTION
                  WHEN ex_recon_batch_exception
                  THEN
                     RAISE ex_recon_batch_exception;
                  WHEN OTHERS
                  THEN
                     IF lcu_get_recon_hdr%ISOPEN
                     THEN
                        CLOSE lcu_get_recon_hdr;
                     END IF;

                     xx_ce_cc_common_pkg.od_message ('M', 'Other Error Validating Card Type for Provider! ' || recon_batches_rec.card_type);
                     lc_error_flag    := 'Y';
                     RAISE ex_recon_batch_exception;
               END;

               recon_hdr_rec               := NULL;
               lc_error_location           := 'Error:Derive Company from location-Store ' || recon_batches_rec.store_num;
               lc_company                  := xx_gl_translate_utl_pkg.derive_company_from_location (p_location => recon_batches_rec.store_num, p_org_id => gn_org_id  -- Defect 9365
                                                                                                                                                                    );

               IF lc_company IS NULL
               THEN
                  fnd_message.set_name ('XXFIN', 'XX_CE_020_COMPANY_NOT_SETUP');
                  lc_error_details    := 'Error:' || lc_error_location || '-' || fnd_message.get;
                  xx_ce_cc_common_pkg.od_message ('M', 'Error:Cannot derive Company from Location!');
                  lc_error_flag       := 'Y';
                  RAISE ex_recon_batch_exception;
               END IF;

               lc_error_location           :=    'Get Recon Header Details ('
                                              || recon_batches_rec.processor_id
                                              || '/'
                                              || recon_batches_rec.card_type
                                              || '/'
                                              || recon_batches_rec.recon_date
                                              || '/'
                                              || recon_batches_rec.store_num
                                              || ')';
               lc_error_details            := NULL;
               lc_error_flag               := 'N';

-- -------------------------------------------
--  Get the Fee Columns and Accounting.
-- -------------------------------------------
               FOR recon_hdr_rec IN lcu_get_recon_hdr (p_processor         => recon_batches_rec.processor_id
                                                     , p_card_type         => recon_batches_rec.card_type
                                                     , p_process_date      => recon_batches_rec.recon_date
                                                     , p_store_num         => lc_orig_store_num
                                                      --recon_batches_rec.store_num
                                                      )
               LOOP
                  BEGIN
                     ln_ar_recv_ccid          := NULL;
                     --ln_card_type_ccid := NULL;
                     ln_bank_clearing_ccid    := NULL;
                     lc_ar_recv_lob           := NULL;
                     --lc_card_type_lob := NULL;
                     lc_bank_clearing_lob     := NULL;
                     ln_entered_dr_amount     := NULL;
                     ln_entered_cr_amount     := NULL;
                     -- Defect 5700 - If we get Multiple 999 Lines for same
                     -- provider/store/card type - Reset the Charge Total Amount
                     -- so that GL entries balance (Cr. Total charges is correct).
                     ln_charge_total          := 0;
                     lc_error_location        := 'Get Recon Store Fees for Card Type:' || recon_hdr_rec.ajb_card_type;
--**************************************************************
-- Process Store Fees for each Processor/Card Type in Batch.
--**************************************************************
-- Use the original store number sent from AJB when getting the
-- 999 file fee data.
                     xx_ce_cc_common_pkg.od_message ('M', 'Process fees for Card Type:' || recon_hdr_rec.ajb_card_type);

                     FOR store_fee_rec IN lcu_get_store_fees (recon_batches_rec.bank_rec_id
                                                            , recon_batches_rec.processor_id
                                                            , recon_hdr_rec.ajb_card_type
                                                            , lc_orig_store_num                                                                        --recon_batches_rec.store_num
                                                            , recon_batches_rec.currency
                                                             )
                     LOOP
                        BEGIN
---                  SELECT count(*)
---                    INTO ln_store_count
---                FROM xx_ce_recon_glact_dtl xcrd
---                   WHERE 1 = 1
---                 AND xcrd.header_id =  recon_hdr_rec.header_id
---                 AND recon_batches_rec.store_num BETWEEN xcrd.location_from AND xcrd.location_to
---                 AND TRUNC (SYSDATE) BETWEEN xcrd.effective_from_date AND NVL (xcrd.effective_to_date, TRUNC(SYSDATE) + 1);
-- -------------------------------------------
-- Get Fee Details and Accounting.
-- -------------------------------------------
-- Use '001099' when getting accounting info for 'store 000000'.
---                        IF ln_store_count > 0 then
                           FOR recon_dtl_rec IN lcu_get_recon_dtl (p_header_id         => recon_hdr_rec.header_id
                                                                 , p_process_date      => TRUNC (SYSDATE)
                                                                 , p_store_num         => recon_batches_rec.store_num
                                                                  )
                           LOOP
                              lc_error_location    := 'Getting Store Fee Column Details for store ' || recon_batches_rec.store_num || ' Header ID:' || recon_hdr_rec.header_id;
                              ln_charge_ccid       := NULL;
                              lc_charge_lob        := NULL;
                              ln_charge_amt        := NULL;
-- ------------------------------------------------------
-- Dynamic Sql to get the 999 store fee column value
-- eg. if charge_code value from xx_ce_recon_glact_dtl
-- maps to DISCOUNT_AMT field on the 999 file, the query
-- below retrieves the value in the DISCOUNT_AMT field.
-- ------------------------------------------------------
                              lc_sql               := 'SELECT ' || recon_dtl_rec.charge_code || ' FROM  xx_ce_ajb999_v
                     WHERE sequence_id_999 = :v_sequence_id';

                              BEGIN
                                 OPEN lc_ret_fee_amt_cur
                                  FOR lc_sql USING store_fee_rec.sequence_id_999;

                                 FETCH lc_ret_fee_amt_cur
                                  INTO ln_charge_amt;

                                 CLOSE lc_ret_fee_amt_cur;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    lc_error_flag       := 'Y';
                                    lc_error_details    := 'Other error geting charge code: ' || SQLCODE || ':' || SQLERRM;
                                    xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                                    RAISE ex_recon_batch_exception;
                              END;

                              --xx_ce_cc_common_pkg.od_message('M', 'Charge Amt:' || ln_charge_amt);
							  
							  
                              IF NVL (ln_charge_amt, 0) != 0
                              THEN
-- -------------------------------------------
-- Derive Charge CCID.
-- -------------------------------------------
                                 lc_error_location    := 'Error:Derive Charge LOB from location and costcenter ';
                                 xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc (p_location           => recon_batches_rec.store_num
                                                                                    , p_cost_center        => recon_dtl_rec.charge_costcenter
                                                                                    , x_lob                => lc_charge_lob
                                                                                    , x_error_message      => lc_errmsg
                                                                                     );

                                 IF lc_charge_lob IS NULL
                                 THEN
                                    fnd_message.set_name ('XXFIN', 'XX_CE_021_LOB_NOT_SETUP');
                                    lc_error_details    :=    'Error deriving Charge LOB for location '
                                                           || recon_batches_rec.store_num
                                                           || ' Cost Center '
                                                           || recon_dtl_rec.charge_costcenter
                                                           || '/'
                                                           || lc_error_details
                                                           || '-'
                                                           || lc_errmsg
                                                           || fnd_message.get;
                                    xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                                    lc_error_flag       := 'Y';
                                    RAISE ex_recon_batch_exception;
                                 END IF;                                                                                                                             --lc_charge_lob

                                 lc_charge_acct       :=    lc_company
                                                         || gc_delimiter
                                                         || recon_dtl_rec.charge_costcenter
                                                         || gc_delimiter
                                                         || recon_dtl_rec.charge_debit_account
                                                         || gc_delimiter
                                                         || recon_batches_rec.store_num
                                                         || gc_delimiter
                                                         || lc_intercompany
                                                         || gc_delimiter
                                                         || lc_charge_lob
                                                         || gc_delimiter
                                                         || lc_future;
                                 lc_error_location    := 'Processing Fee ' || recon_dtl_rec.charge_description || ': Get CCID for ' || lc_charge_acct;
                                 --xx_ce_cc_common_pkg.od_message('M', lc_error_location);
                                 ln_charge_ccid       := fnd_flex_ext.get_ccid (application_short_name      => 'SQLGL'
                                                                              , key_flex_code               => 'GL#'
                                                                              , structure_number            => gn_coa_id
                                                                              , validation_date             => SYSDATE
                                                                              , concatenated_segments       => lc_charge_acct
                                                                               );

                                 IF ln_charge_ccid = 0
                                 THEN
                                    fnd_message.set_name ('XXFIN', 'XX_CE_023_CCID_NOT_SETUP');
                                    lc_error_details    := lc_error_details || 'Error deriving Charge Debit Account CCID for ' || lc_charge_acct || '-' || fnd_message.get;
                                    lc_error_flag       := 'Y';
                                    xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                                    RAISE ex_recon_batch_exception;
                                 END IF;                                                                                                                            --ln_charge_ccid

								 
-- -------------------------------------------
-- Create Journal Entries for Fee Expense.
-- -------------------------------------------
                                 lc_error_location    := 'Create JE for Fee detail for Recon batch';
                                 lc_je_line_desc      :=    'Bank Rec ID:'
                                                         || intf_batches_rec.bank_rec_id
                                                         || '/Fee Type:'
                                                         || recon_dtl_rec.charge_description
                                                         || '/Card Type:'
                                                         || lc_orig_card_type
                                                         || '/GL Period '
                                                         || lc_period_start
                                                         || '/Gross Amount '
                                                         || recon_batches_rec.net_amount;
                                 xx_ce_cc_common_pkg.od_message ('M', 'lc_je_line_desc:' || lc_je_line_desc);

                                 IF ln_charge_amt < 0
                                 THEN
                                    ln_entered_dr_amount    := 0;
                                    ln_entered_cr_amount    := ABS (ln_charge_amt);
                                    xx_ce_cc_common_pkg.od_message ('M'
                                                                  ,    RPAD (   'CR '
                                                                             || recon_dtl_rec.charge_description
                                                                             || '(Seq:'
                                                                             || store_fee_rec.sequence_id_999
                                                                             || '):'
                                                                             || store_fee_rec.currency
                                                                             || ' '
                                                                             || ln_charge_amt
                                                                           , 50
                                                                           , ' '
                                                                            )
                                                                    || ' '
                                                                    || RPAD (lc_charge_acct, 45, ' ')
                                                                    || LPAD (' ', 12, ' ')
                                                                    || ' '
                                                                    || LPAD (ABS (ln_charge_amt), 12, ' ')
                                                                   );
                                 ELSE
                                    ln_entered_dr_amount    := ABS (ln_charge_amt);
                                    ln_entered_cr_amount    := 0;
                                    xx_ce_cc_common_pkg.od_message ('M'
                                                                  ,    RPAD (   'DR '
                                                                             || recon_dtl_rec.charge_description
                                                                             || ' (Seq:'
                                                                             || store_fee_rec.sequence_id_999
                                                                             || ') Amt:'
                                                                             || store_fee_rec.currency
                                                                             || ' '
                                                                             || ln_charge_amt
                                                                           , 50
                                                                           , ' '
                                                                            )
                                                                    || ' '
                                                                    || RPAD (lc_charge_acct, 45, ' ')
                                                                    || LPAD (ABS (ln_charge_amt), 12, ' ')
                                                                   );
                                 END IF;

                                 xx_gl_interface_pkg.create_stg_jrnl_line (p_status                 => 'NEW'
                                                                         , p_date_created           => TRUNC (SYSDATE)
                                                                         , p_created_by             => gn_user_id
                                                                         , p_actual_flag            => 'A'
                                                                         , p_group_id               => ln_group_id
                                                                         , p_je_reference           => ln_group_id
                                                                         , p_batch_name             => TO_CHAR (SYSDATE, 'YYYY/MM/DD')
                                                                         , p_batch_desc             => NULL
                                                                         , p_user_source_name       => lc_user_source_name
                                                                         , p_user_catgory_name      => 'Miscellaneous'
                                                                         , p_set_of_books_id        => gn_set_of_bks_id
                                                                         , p_accounting_date        => TRUNC (SYSDATE)
                                                                         , p_currency_code          => store_fee_rec.currency
                                                                         , p_company                => NULL
                                                                         , p_cost_center            => NULL
                                                                         , p_account                => NULL
                                                                         , p_location               => NULL
                                                                         , p_intercompany           => NULL
                                                                         , p_channel                => NULL
                                                                         , p_future                 => NULL
                                                                         , p_ccid                   => ln_charge_ccid
                                                                         , p_entered_dr             => ln_entered_dr_amount
                                                                         , p_entered_cr             => ln_entered_cr_amount
                                                                         , p_je_line_dsc            => lc_je_line_desc
                                                                         , x_output_msg             => lc_output_msg
                                                                          );

-- -------------------------------------------
-- Calling the Exception
-- If insertion Failed into XX_GL_INTERFACE_NA_STG.
-- -------------------------------------------
                                 IF lc_output_msg IS NOT NULL
                                 THEN
                                    lc_error_details    := 'Error creating Journal line:' || lc_error_details || lc_output_msg;
                                    lc_error_flag       := 'Y';
                                    xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                                    RAISE ex_recon_batch_exception;
                                 END IF;

---------------------------------------------------
--  Add Fee Charges to Fee total.
---------------------------------------------------

                                 ln_charge_total      := NVL (ln_charge_total, 0) + NVL (ln_charge_amt, 0);
                                 xx_ce_cc_common_pkg.od_message ('M', 'Charge Running Total:' || ln_charge_total);
                              ELSE                                                                                                                              --ln_charge_amt = 0;
                                 xx_ce_cc_common_pkg.od_message ('M'
                                                               , 'No ' || recon_dtl_rec.charge_description || ' amount in batch (Seq:' || store_fee_rec.sequence_id_999 || ')');
                              END IF;
							  
                           END LOOP;                                                                                                                             --lcu_get_recon_dtl

---            ELSE
---                lc_error_flag       := 'Y';
---                lc_error_details    := 'Setup of the Store '||recon_batches_rec.store_num||' is Missing' || lc_error_details || '-' || SQLCODE || ':' || SQLERRM;
---                xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
---                RAISE ex_recon_batch_exception;
---            END IF;
-- ------------------------------------------------
-- Update after the Processing the 999 fee record.
-- ------------------------------------------------
                           lc_error_location    := 'Update Store Fee processed status for Seq:' || store_fee_rec.sequence_id_999 || ' Amount:        ' || ln_charge_total;
						   
						   --Changes for Defect #25473 Starts here
						   IF ABS(ln_charge_total) != ABS(recon_batches_rec.net_amount)
							  THEN
							  fnd_file.put_line (fnd_file.LOG,' Charge Total:' || ln_charge_total || ' Net Amount:' || recon_batches_rec.net_amount || ' Charge Amount is not equal or less than Net amount');
							  fnd_file.put_line(fnd_file.OUTPUT, 'Missing the set up for one of the Fee column');
							  RAISE ex_recon_batch_exception;
							  END IF;
							  --Changes for Defect #25473 Ends here
							  
                           /* For setting the status of attribute1 to FEE_RECON_YES for processed records.Added for the Defect 6138 */
                           UPDATE xx_ce_ajb999 xca9
                              SET xca9.attribute1 = DECODE (lc_error_flag                                                                             ----Added for the Defect 6138.
                                                          , 'Y', 'FEE_RECON_NO', 'N', 'FEE_RECON_YES', xca9.attribute1)
                                , last_update_date = SYSDATE
                                , last_updated_by = gn_user_id
                            WHERE xca9.sequence_id_999 = store_fee_rec.sequence_id_999
                              AND xca9.store_num = lc_orig_store_num
                              --recon_batches_rec.store_num
                              AND xca9.processor_id = store_fee_rec.processor_id
                              AND xca9.cardtype = lc_orig_card_type;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              lc_error_flag       := 'Y';
                              lc_error_details    := 'Other error processing store fees. ' || lc_error_details || '-' || SQLCODE || ':' || SQLERRM;
                              xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                              RAISE ex_recon_batch_exception;
                        END;
                     END LOOP;                                                                                                                                        -- Store Fees.

--***************************************************************
-- -----------------------------------------------
--  Derive the Credit AR Receivable Account CCID.
-- -----------------------------------------------
                     lc_error_location        :=    'Error:Derive AR Receivable LOB from location ('
                                                 || recon_batches_rec.store_num
                                                 || ') and costcenter ('
                                                 || recon_hdr_rec.ar_recv_costcenter
                                                 || ').';
                     xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc (p_location           => recon_batches_rec.store_num
                                                                        , p_cost_center        => recon_hdr_rec.ar_recv_costcenter
                                                                        , x_lob                => lc_ar_recv_lob
                                                                        , x_error_message      => lc_errmsg
                                                                         );

                     IF lc_ar_recv_lob IS NULL
                     THEN
                        fnd_message.set_name ('XXFIN', 'XX_CE_021_LOB_NOT_SETUP');
                        lc_error_details    :=    'Error Getting AR Receivable LOB for location '
                                               || recon_batches_rec.store_num
                                               || ' Cost Center '
                                               || recon_hdr_rec.ar_recv_costcenter
                                               || lc_error_details
                                               || '/'
                                               || lc_errmsg
                                               || '-'
                                               || fnd_message.get;
                        lc_error_flag       := 'Y';
                        xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                        RAISE ex_recon_batch_exception;
                     END IF;                                                                                                                                       -- lc_ar_recv_lob

                     IF lc_ar_recv_costcenter IS NULL
                     THEN
                        lc_ar_recv_costcenter    := recon_hdr_rec.ar_recv_costcenter;
                     END IF;

                     IF lc_bank_clearing_account IS NULL
                     THEN
                        lc_bank_clearing_account    := recon_hdr_rec.bank_clearing_account;
                     END IF;

                     SELECT SUBSTR (NAME, 4, 2)
                       INTO lc_org_name
                       FROM hr_all_organization_units
                      WHERE organization_id = gn_org_id;

    --- End of Changes for CR 601 for R1.1 Defect 1362
-- -------------------------------------------
-- Create offset Journal Entries for Fee Expense Total to AR Receivable Account.
-- -------------------------------------------
                     IF NVL (ln_charge_total, 0) != 0
                     THEN
                        lc_error_location    := 'CREDIT AR Receivable Journal Entries for each provider and store';
                        lc_je_line_desc      :=    'AR CC Recv:Fee total for '
                                                || recon_batches_rec.processor_id
                                                || '/Card Type:'
                                                || recon_hdr_rec.ajb_card_type
                                                || '/Store '
                                                || recon_batches_rec.store_num
                                                || '/Recon Batch '
                                                || recon_batches_rec.bank_rec_id;

                        IF ln_charge_total < 0
                        THEN
                           ln_entered_dr_amount    := ABS (ln_charge_total);
                           ln_entered_dr_total     := ln_entered_dr_total + ln_entered_dr_amount;
                           ln_entered_cr_amount    := 0;
                           ln_entered_cr_total     := ln_entered_cr_total + ln_entered_cr_amount;
                        ELSE
                           ln_entered_dr_amount    := 0;
                           ln_entered_dr_total     := ln_entered_dr_total + ln_entered_dr_amount;
                           ln_entered_cr_amount    := ABS (ln_charge_total);
                           ln_entered_cr_total     := ln_entered_cr_total + ln_entered_cr_amount;
                        END IF;
                     ELSE
                        xx_ce_cc_common_pkg.od_message ('M', 'No Store fees to Process');
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        lc_error_details    := 'Other Error Processing Recon Header : ' || lc_error_location || '. ' || SQLCODE || ':' || SQLERRM;
                        xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                        lc_error_flag       := 'Y';
                        RAISE ex_recon_batch_exception;
                  END;
               END LOOP;                                                                                                                                           -- recon_hdr_rec.

-- ------------------------------------------------
-- Calling the Exception
-- If insertion into XX_GL_INTERFACE_NA_STG failed.
-- ------------------------------------------------
               IF lc_output_msg IS NOT NULL
               THEN
                  lc_error_details    := 'Error Creating JE for Fee Total to AR CC Receivable (Bank) Account ' || lc_ar_recv_acct || '-' || lc_error_details || lc_output_msg;
                  lc_error_flag       := 'Y';
                  xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                  RAISE ex_recon_batch_exception;
               END IF;

               lc_error_location           := 'After Get Recon Hdr';

-- -------------------------------------------
-- Call the Print Message Details.
-- -------------------------------------------
               IF recon_batches_rec.net_amount = 0
               THEN
                  lc_processed    := 'No Amount to be Processed';
               ELSE
                  lc_processed    := 'Processed';
               END IF;

               print_message_footer (x_errbuf            => lc_errmsg
                                   , x_retcode           => ln_retcode
                                   , p_bank_rec_id       => recon_batches_rec.bank_rec_id
                                   , p_processor_id      => recon_batches_rec.processor_id
                                   , p_card_type         => NVL (lc_orig_card_type, recon_batches_rec.card_type)
                                   , p_store_num         => lc_orig_store_num
                                   --recon_batches_rec.store_num
               ,                     p_net_amount        => recon_batches_rec.net_amount
                                   , p_process_date      => recon_batches_rec.recon_date
                                   , p_message           => lc_message || NVL (lc_error_details, lc_processed)
                                    );

               IF     lc_error_details IS NULL
                  AND NVL (lc_error_flag, 'N') = 'N'
               THEN
                  --               xx_ce_cc_common_pkg.od_message
                  --                         ('M'
                  --                        , '**** Update 999 Interface set x999_gl Complete="Y"'
                  --                         );
                  ln_success_rec    := NVL (ln_success_rec, 0) + 1;
               ELSE
                  xx_ce_cc_common_pkg.od_message ('M'
                                                ,    '* * * Error: All Expenses for Recon batch:'
                                                  || recon_batches_rec.bank_rec_id
                                                  || ' / Processor: '
                                                  || recon_batches_rec.processor_id
                                                  || ' could not be processed!'
                                                  || '. '
                                                  || lc_error_details
                                                 );
                  xx_ce_cc_common_pkg.od_message ('M', '');
                  RAISE ex_recon_batch_exception;
               END IF;
            EXCEPTION
               WHEN ex_recon_batch_exception
               THEN
-- -------------------------------------------
-- Call the Print Message Details.
-- -------------------------------------------
                  print_message_footer (x_errbuf            => lc_errmsg
                                      , x_retcode           => ln_retcode
                                      , p_bank_rec_id       => recon_batches_rec.bank_rec_id
                                      , p_processor_id      => recon_batches_rec.processor_id
                                      , p_card_type         => NVL (lc_orig_card_type, recon_batches_rec.card_type)
                                      , p_store_num         => lc_orig_store_num
                                      --recon_batches_rec.store_num
                  ,                     p_net_amount        => recon_batches_rec.net_amount
                                      , p_process_date      => recon_batches_rec.recon_date
                                      , p_message           => NVL (lc_error_details, 'Error - Review Log for details')
                                       );
                  ROLLBACK TO lc_recon_batch_savepoint;
                  /* Added for the Defect 6138 - Starts here */
                  lc_error_flag    := 'Y';

                  UPDATE xx_ce_ajb999 xca9
                     SET xca9.attribute1 = 'FEE_RECON_NO'
                       , last_update_date = SYSDATE
                       , last_updated_by = gn_user_id
                   WHERE bank_rec_id = recon_batches_rec.bank_rec_id
                     AND processor_id = recon_batches_rec.processor_id
                     AND cardtype = NVL (lc_orig_card_type, recon_batches_rec.card_type)
                     AND store_num = recon_batches_rec.store_num;

                  -- To get the errored store numbers to display in mail body
                  IF lc_err_store_num IS NULL
                  THEN
                     lc_err_store_num    := recon_batches_rec.store_num;
                  ELSE
                     lc_err_store_num    := lc_err_store_num || ',' || recon_batches_rec.store_num;
                     lc_count_flag       := 'Y';
                  END IF;

                  /* Added for the Defect 6138 - Ends here */
                  UPDATE xx_ce_999_interface xc9i1
                     SET x999_gl_complete = 'N'
                       , concurrent_pgm_last = gn_request_id
                       , last_update_date = SYSDATE
                       , last_updated_by = gn_user_id
                   WHERE bank_rec_id = recon_batches_rec.bank_rec_id
                     AND processor_id = recon_batches_rec.processor_id
                     AND NVL (deposits_matched, 'N') = 'Y'
--                  AND NVL (expenses_complete, 'N') = 'N';
                     AND NVL (x999_gl_complete, 'N') = 'N';                                                                                -- Added by Gaurav Agarwal for x999 flag.

                  ln_error_rec     := ln_error_rec + 1;
               WHEN OTHERS
               THEN
-- -------------------------------------------
-- Call the Print Message Details.
-- -------------------------------------------
                  print_message_footer (x_errbuf            => lc_errmsg
                                      , x_retcode           => ln_retcode
                                      , p_bank_rec_id       => recon_batches_rec.bank_rec_id
                                      , p_processor_id      => recon_batches_rec.processor_id
                                      , p_card_type         => NVL (lc_orig_card_type, recon_batches_rec.card_type)
                                      , p_store_num         => lc_orig_store_num
                                      --recon_batches_rec.store_num
                  ,                     p_net_amount        => recon_batches_rec.net_amount
                                      , p_process_date      => recon_batches_rec.recon_date
                                      , p_message           => NVL (lc_error_details, 'Error - Review Log for details')
                                       );
                  ROLLBACK TO lc_recon_batch_savepoint;
                  /* Added for the Defect 6138 - Starts here */
                  lc_error_flag    := 'Y';

                  UPDATE xx_ce_ajb999 xca9
                     SET xca9.attribute1 = 'FEE_RECON_NO'
                       , last_update_date = SYSDATE
                       , last_updated_by = gn_user_id
                   WHERE bank_rec_id = recon_batches_rec.bank_rec_id
                     AND processor_id = recon_batches_rec.processor_id
                     AND store_num = recon_batches_rec.store_num;

                  IF lc_err_store_num IS NULL
                  THEN
                     lc_err_store_num    := recon_batches_rec.store_num;
                  ELSE
                     lc_err_store_num    := lc_err_store_num || ',' || recon_batches_rec.store_num;
                     lc_count_flag       := 'Y';
                  END IF;

                  /* Added for the Defect 6138 - Ends here */
                  UPDATE xx_ce_999_interface xc9i1
                     SET x999_gl_complete = 'N'
                       , concurrent_pgm_last = gn_request_id
                       , last_update_date = SYSDATE
                       , last_updated_by = gn_user_id
                   WHERE bank_rec_id = recon_batches_rec.bank_rec_id
                     AND processor_id = recon_batches_rec.processor_id
                     AND NVL (deposits_matched, 'N') = 'Y'
--                  AND NVL (expenses_complete, 'N') = 'N';
                     AND NVL (x999_gl_complete, 'N') = 'N';                                                                                -- Added by Gaurav Agarwal for x999 flag.

                  xx_ce_cc_common_pkg.od_message ('M', 'Error at:' || lc_error_location || '. ' || SQLCODE || ':' || SQLERRM);
                  ln_error_rec     := ln_error_rec + 1;
            END;                                                                                                                                               -- Recon Batches End;
         END LOOP;                                                                                                                                                  -- recon_batches

         CLOSE lcu_get_recon_batches;

         BEGIN
            ln_gross_amount      := 0;
            xx_ce_cc_common_pkg.od_message ('M', ' ');
            xx_ce_cc_common_pkg.od_message ('M', g_print_line);
            xx_ce_cc_common_pkg.od_message ('M', ' lc_ar_recv_lob:' || lc_ar_recv_lob);

            --V1.1 - Checking for the Company based on the currency passed in 999 Interface Table.
            IF (intf_batches_rec.currency_code = 'CAD')
            THEN
               lc_company1    := '1003';
            ELSE
               lc_company1    := '1001';
            END IF;

            lc_ar_recv_acct      :=    lc_company1                                                                                                              --'1001'--lc_company
                                    || gc_delimiter
                                    || lc_ar_recv_costcenter                                                                                      --recon_hdr_rec.ar_recv_costcenter
                                    || gc_delimiter
                                    || lc_bank_clearing_account                         --recon_hdr_rec.bank_clearing_account --ar_recv_account -- Updated as part of new requirment
                                    || gc_delimiter
                                    || '010000'                                                                                                        --recon_batches_rec.store_num
                                    || gc_delimiter
                                    || lc_intercompany
                                    || gc_delimiter
                                    || '90' -- lc_ar_recv_lob v1.2 lob is hardcoded as 90 by Gaurav as per defect 12224 for US and CA both
                                    || gc_delimiter
                                    || lc_future;
            lc_error_location    := 'Get AR Receivable CCID for ' || lc_ar_recv_acct;
            ln_ar_recv_ccid      := fnd_flex_ext.get_ccid (application_short_name      => 'SQLGL'
                                                         , key_flex_code               => 'GL#'
                                                         , structure_number            => gn_coa_id
                                                         , validation_date             => SYSDATE
                                                         , concatenated_segments       => lc_ar_recv_acct
                                                          );

            IF ln_ar_recv_ccid = 0
            THEN
               fnd_message.set_name ('XXFIN', 'XX_CE_023_CCID_NOT_SETUP');
               lc_error_details    := 'Error Deriving AR Receivable Account CCID for ' || lc_ar_recv_acct || '-' || lc_error_details || '-' || fnd_message.get;
               lc_error_flag       := 'Y';
               xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
               RAISE ex_recon_batch_exception1;
            END IF;
            lc_bank_clearing_account := null; --added for defect 20340
            IF NVL (ln_entered_dr_total, 0) != 0
            THEN
               xx_ce_cc_common_pkg.od_message ('M'
                                             ,    RPAD ('DR Fee Total to AR CC Receivable Bank:' || recon_batches_rec.currency || ' ' || ln_entered_dr_total, 50, ' ')
                                               || ' '
                                               || RPAD (lc_ar_recv_acct, 45, ' ')
                                               || LPAD (' ', 12, ' ')
                                               || ' '
                                               || LPAD (ABS (ln_entered_dr_total), 12, ' ')
                                              );
            END IF;

            IF NVL (ln_entered_cr_total, 0) != 0
            THEN
               xx_ce_cc_common_pkg.od_message ('M'
                                             ,    RPAD ('CR Fee Total to AR CC Receivable Bank:' || recon_batches_rec.currency || ' ' || ln_entered_cr_total, 50, ' ')
                                               || ' '
                                               || RPAD (lc_ar_recv_acct, 45, ' ')
                                               || LPAD (' ', 12, ' ')
                                               || ' '
                                               || LPAD (ABS (ln_entered_cr_total), 12, ' ')
                                              );
            END IF;

            ln_gross_amount      := ln_entered_cr_total - ln_entered_dr_total;

            IF ln_gross_amount < 0
            THEN
               ln_entered_dr_total    := ln_gross_amount;
               ln_entered_cr_total    := 0;
            ELSE
               ln_entered_dr_total    := 0;
               ln_entered_cr_total    := ln_gross_amount;
            END IF;

            lc_je_line_desc      := 'Bank Rec ID:' || intf_batches_rec.bank_rec_id || '/GL Period:' || lc_period_start || '/Gross Amount:' || ABS (ln_gross_amount);
            xx_ce_cc_common_pkg.od_message ('M', 'lc_je_line_desc For AR:' || lc_je_line_desc);
            xx_ce_cc_common_pkg.od_message ('M', 'ln_entered_dr_total:' || ln_entered_dr_total);
            xx_ce_cc_common_pkg.od_message ('M', 'ln_entered_cr_total:' || ln_entered_cr_total);

            IF ln_gross_amount != 0
            THEN
               xx_gl_interface_pkg.create_stg_jrnl_line (p_status                 => 'NEW'
                                                       , p_date_created           => TRUNC (SYSDATE)
                                                       , p_created_by             => gn_user_id
                                                       , p_actual_flag            => 'A'
                                                       , p_group_id               => ln_group_id
                                                       , p_je_reference           => ln_group_id
                                                       , p_batch_name             => TO_CHAR (SYSDATE, 'YYYY/MM/DD')                                                         -- NULL
                                                       , p_batch_desc             => NULL
                                                       , p_user_source_name       => lc_user_source_name
                                                       , p_user_catgory_name      => 'Miscellaneous'
                                                       , p_set_of_books_id        => gn_set_of_bks_id
                                                       , p_accounting_date        => TRUNC (SYSDATE)
                                                       , p_currency_code          => recon_batches_rec.currency
                                                       , p_company                => NULL
                                                       , p_cost_center            => NULL
                                                       , p_account                => NULL
                                                       , p_location               => NULL
                                                       , p_intercompany           => NULL
                                                       , p_channel                => NULL
                                                       , p_future                 => NULL
                                                       , p_ccid                   => ln_ar_recv_ccid
                                                       , p_entered_dr             => ABS (ln_entered_dr_total)
                                                       , p_entered_cr             => ABS (ln_entered_cr_total)
                                                       , p_je_line_dsc            => lc_je_line_desc
                                                       , x_output_msg             => lc_output_msg
                                                        );
            END IF;
         EXCEPTION
            WHEN ex_recon_batch_exception1
            THEN
-- -----------------------------------------
-- Call thPrint Message Details.
-- -----------------------------------------
               xx_ce_cc_common_pkg.od_message ('M', 'EXP1');
               print_message_footer (x_errbuf            => lc_errmsg
                                   , x_retcode           => ln_retcode
                                   , p_bank_rec_id       => intf_batches_rec.bank_rec_id
                                   , p_processor_id      => intf_batches_rec.processor_id
                                   , p_card_type         => NVL (lc_orig_card_type, recon_batches_rec.card_type)
                                   , p_store_num         => lc_orig_store_num
                                   --recon_batches_rec.store_num
               ,                     p_net_amount        => recon_batches_rec.net_amount
                                   , p_process_date      => recon_batches_rec.recon_date
                                   , p_message           => NVL (lc_error_details, 'Error - Review Log for details')
                                    );
               ROLLBACK TO lc_intf_batch_savepoint;
               /* Added for the Defect 6138 - Starts here */
               lc_error_flag    := 'Y';

               UPDATE xx_ce_ajb999 xca9
                  SET xca9.attribute1 = 'FEE_RECON_NO'
                    , last_update_date = SYSDATE
                    , last_updated_by = gn_user_id
                WHERE bank_rec_id = intf_batches_rec.bank_rec_id
                  AND processor_id = intf_batches_rec.processor_id
                  AND nvl(attribute1,'FEE_RECON_NO')<>'FEE_RECON_YES';  --Condition Added for V1.3 Defect 13233

               -- AND cardtype = NVL (lc_orig_card_type, recon_batches_rec.card_type)
               -- AND store_num = recon_batches_rec.store_num;

               /* Added for the Defect 6138 - Ends here */
               UPDATE xx_ce_999_interface xc9i1
                  SET                                                                                                                                      --expenses_complete = 'N'
                     x999_gl_complete = 'N'
                   , concurrent_pgm_last = gn_request_id
                   , last_update_date = SYSDATE
                   , last_updated_by = gn_user_id
                WHERE bank_rec_id = recon_batches_rec.bank_rec_id
                  AND processor_id = recon_batches_rec.processor_id
                  AND NVL (deposits_matched, 'N') = 'Y'
--                  AND NVL (expenses_complete, 'N') = 'N';
                  AND NVL (x999_gl_complete, 'N') = 'N';                                                                                   -- Added by Gaurav Agarwal for x999 flag.

--               ln_error_rec     := ln_error_rec + 1;
            WHEN OTHERS
            THEN
-- -----------------------------------------
-- Call thPrint Message Details.
-- -----------------------------------------
               xx_ce_cc_common_pkg.od_message ('M', 'OTHERS Before EXP1');
               print_message_footer (x_errbuf            => lc_errmsg
                                   , x_retcode           => ln_retcode
                                   , p_bank_rec_id       => intf_batches_rec.bank_rec_id
                                   , p_processor_id      => intf_batches_rec.processor_id
                                   , p_card_type         => NVL (lc_orig_card_type, recon_batches_rec.card_type)
                                   , p_store_num         => lc_orig_store_num
                                   --recon_batches_rec.store_num
               ,                     p_net_amount        => recon_batches_rec.net_amount
                                   , p_process_date      => recon_batches_rec.recon_date
                                   , p_message           => NVL (lc_error_details, 'Error - Review Log for details')
                                    );
               ROLLBACK TO lc_intf_batch_savepoint;
               /* Added for the Defect 6138 - Starts here */
               lc_error_flag    := 'Y';

               /* Added for the Defect 6138 - Ends here */
               UPDATE xx_ce_999_interface xc9i1
                  SET
--expenses_complete = 'N'
                      x999_gl_complete = 'N'
                    , concurrent_pgm_last = gn_request_id
                    , last_update_date = SYSDATE
                    , last_updated_by = gn_user_id
                WHERE bank_rec_id = intf_batches_rec.bank_rec_id
                  AND processor_id = intf_batches_rec.processor_id
                  AND NVL (deposits_matched, 'N') = 'Y'
                  AND NVL (x999_gl_complete, 'N') = 'N';

               xx_ce_cc_common_pkg.od_message ('M', 'Error at:' || lc_error_location || '. ' || SQLCODE || ':' || SQLERRM);
               ln_error_rec     := ln_error_rec + 1;
         END;

         BEGIN
            --Update 999 interface row if all expenses for provider
            -- and batch were sucessfully processed.
            UPDATE xx_ce_999_interface xc9i1
               SET x999_gl_complete = 'Y'
                 , concurrent_pgm_last = gn_request_id
                 , last_update_date = SYSDATE
                 , last_updated_by = gn_user_id
             WHERE bank_rec_id = intf_batches_rec.bank_rec_id
               AND processor_id = intf_batches_rec.processor_id
               AND NVL (deposits_matched, 'N') = 'Y'
               AND NVL (x999_gl_complete, 'N') = 'N'
               AND NOT EXISTS (SELECT 1
                                 FROM xx_ce_ajb_net_amounts_v xcan                                                                     --xx_ce_ajb999_v  --Added for the Defect 6138
                                WHERE xcan.attribute1 = 'FEE_RECON_NO'                                                                                   --Added for the Defect 6138
                                  --WHERE NVL (status_1310, 'ERROR') = 'ERROR'          --Commented for the Defect 6138
                                  AND bank_rec_id = xc9i1.bank_rec_id
                                  AND processor_id = xc9i1.processor_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               xx_ce_cc_common_pkg.od_message ('M', '* * * Error Updating 999 Interface:' || SQLCODE || '-' || SQLERRM);
         END;
      END LOOP;                                                                                                                                            -- intf_batches_rec loop.

      IF ln_total_rec = 0
      THEN
         xx_ce_cc_common_pkg.od_message ('M', ' ');
         xx_ce_cc_common_pkg.od_message ('M', '  ----------   NO MATCHED BATCHES FOUND FOR PROCESSING FEES  ----------');
         xx_ce_cc_common_pkg.od_message ('M', ' ');
      ELSE
         xx_ce_cc_common_pkg.od_message ('M', ' ');
         xx_ce_cc_common_pkg.od_message ('M', ' ');
         xx_ce_cc_common_pkg.od_message ('M', g_print_line);
         xx_ce_cc_common_pkg.od_message ('M', 'Fees with Errors:' || ln_error_rec);
         xx_ce_cc_common_pkg.od_message ('M', 'Successful      :' || ln_success_rec);

         /*Added for the Defect 6138 Starts Here*/
         IF ln_error_rec > 0
         THEN
            xx_ce_cc_common_pkg.od_message ('M', 'The program ends in warning until the errored store numbers are corrected.');
         END IF;

         /* Added for the Defect 6138 Starts Here*/
         xx_ce_cc_common_pkg.od_message ('M', g_print_line);
         xx_ce_cc_common_pkg.od_message ('M', ' ');
      END IF;

-- -------------------------------------------
-- Call the Print Message Record Summary
-- -------------------------------------------
      print_message_summary (x_errbuf => lc_errmsg, x_retcode => ln_retcode, p_success => ln_success_rec, p_error => ln_error_rec, p_total => ln_total_rec);

-- -------------------------------------------
-- Setting the Request Status based one the
-- Process record count
-- -------------------------------------------
      IF ln_error_rec > 0
      THEN
         x_retcode             := gn_warning;

         /* Added for the Defect 6138 Starts here */
         IF lc_count_flag = 'Y'
         THEN
            lc_errored_store    :=    'The store numbers '
                                   || lc_err_store_num
                                   || ' have errored due to setup issues.Please refer the attachment for error details. The program ends in warning until it is corrected.';
         -- Mail Body
         ELSE
            lc_errored_store    :=    'The store number '
                                   || lc_err_store_num
                                   || ' has errored due to setup issues.Please refer the attachment for error details.The program ends in warning until it is corrected.';
         -- Mail Body
         END IF;

         IF LENGTH (lc_errored_store) > 240
         THEN
            ---xx_ce_cc_common_pkg.od_message ('M','Errored Store Details:'||lc_errored_store);
            lc_errored_store    := 'Too Many Stores to Set, Please check Log file of Conc Req ID-' || gn_request_id || ' ' || lc_errored_store;
         END IF;

         SELECT xftv.target_value1
           INTO lc_mail_address
           FROM xx_fin_translatedefinition xftd
              , xx_fin_translatevalues xftv
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name = 'XX_CE_FEE_RECON_MAIL_ADDR'
            AND NVL (xftv.enabled_flag, 'N') = 'Y';

         SELECT SYS_CONTEXT ('USERENV', 'DB_NAME')
           INTO lc_instance
           FROM DUAL;

         ln_mail_request_id    := fnd_request.submit_request (application      => 'xxfin'
                                                            , program          => 'XXODROEMAILER'
                                                            , description      => ''
                                                            , sub_request      => FALSE
                                                            , start_time       => TO_CHAR (SYSDATE, 'DD-MON-YY HH:MI:SS')
                                                            , argument1        => ''
                                                            , argument2        => lc_mail_address
                                                            , argument3        => lc_instance || '_AJB Recon Process - ' || TRUNC (SYSDATE)
                                                            , argument4        => SUBSTR (lc_errored_store, 1, 240)
                                                            , argument5        => 'Y'
                                                            , argument6        => gn_request_id
                                                             );
         xx_ce_cc_common_pkg.od_message ('M', 'ln_mail_request_id' || ln_mail_request_id);
      /* Added for the Defect 6138 ends here */
      ELSIF ln_error_rec = 0
      THEN
         x_retcode    := gn_normal;
      END IF;

--
-- Code addaed by Gaurav to update 999 interface table
      BEGIN
         fnd_file.put_line (fnd_file.LOG, 'calling update_xx_ce_999 + ');
         update_xx_ce_999 (p_provider_code, p_bank_rec_id);
         fnd_file.put_line (fnd_file.LOG, 'calling update_xx_ce_999 _ ');
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG, '==========================');
            fnd_file.put_line (fnd_file.LOG, SQLERRM);
      END;
-- code addition ends;
   EXCEPTION
      WHEN ex_main_exception
      THEN
         x_errbuf     := lc_error_location || '-' || lc_error_details;
         x_retcode    := gn_error;
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
      WHEN OTHERS
      THEN
         IF SQLCODE = -54
         THEN
            xx_ce_cc_common_pkg.od_message ('M', ' ');
            xx_ce_cc_common_pkg.od_message ('M', g_print_line);
            xx_ce_cc_common_pkg.od_message ('M', ' ');
            xx_ce_cc_common_pkg.od_message ('M', 'Provider batches are locked by other request/user');
            xx_ce_cc_common_pkg.od_message ('O', 'Provider batches are locked by other request/user');
            xx_ce_cc_common_pkg.od_message ('M', ' ');
            xx_ce_cc_common_pkg.od_message ('M', g_print_line);
            ROLLBACK;
         ELSE
            ROLLBACK;
            xx_ce_cc_common_pkg.od_message ('M', 'Main Others');
            fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
            fnd_message.set_token ('PACKAGE', 'XX_CE_CC_FEE_PKG.create_fee_journal');
            fnd_message.set_token ('PROGRAM', 'CE Credit Card Fee Reconciliation');
            fnd_message.set_token ('SQLERROR', SQLERRM);
            x_errbuf     := lc_error_location || '-' || lc_error_details || '-' || fnd_message.get;
            x_retcode    := gn_error;
-- -------------------------------------------
-- Call the Custom Common Error Handling
-- -------------------------------------------
            xx_com_error_log_pub.log_error (p_program_type                => 'CONCURRENT PROGRAM'
                                          , p_program_name                => gc_conc_short_name
                                          , p_program_id                  => fnd_global.conc_program_id
                                          , p_module_name                 => 'CE'
                                          , p_error_location              => 'Error at ' || lc_error_location
                                          , p_error_message_count         => 1
                                          , p_error_message_code          => 'E'
                                          , p_error_message               => lc_error_details
                                          , p_error_message_severity      => 'Major'
                                          , p_notify_flag                 => 'N'
                                          , p_object_type                 => 'CREDIT CARD RECONCILIATION'
                                           );
            fnd_file.put_line (fnd_file.LOG, '==========================');
            fnd_file.put_line (fnd_file.LOG, x_errbuf);
         END IF;
   END create_fee_journal;
END xx_ce_cc_fee_pkg;
/

SHOW err;
--EXIT;
