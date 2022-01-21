CREATE OR REPLACE PACKAGE BODY xx_ce_cc_trans_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                                                                                 |
-- +=================================================================================+
-- | Name       : xx_ce_cc_trans_pkg.pks                                             |
-- | Description: E2082 OD: CE CreditCard Transaction Journals                       |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |  1.0     2011-04-27   Joe Klein          New package.  Copied 996 and 998       |
-- |                                          code from E1310 package                |
-- |                                          XX_CE_AJB_CC_RECON_PKG                 |
-- |                                          Make appropriate changes for E2082     |
-- |                                          and SDR project.                       |
-- |                                                                                 |
-- |  1.1     2011-05-07   Joe Klein          Added procedure update_xx_ce_ajb99x    |
-- |                                          to update xx_ce_999_interface table    |
-- |                                          setting appropriate                    |
-- |                                          x99*_GL_COMPLETE(996 or 998) to 'Y' for|
-- |                                          processor_id and bank_rec_id, even if  |
-- |                                          no records on xx_ce_ajb996             |
-- |                                          or xx_ce_ajb998 tables.                |
-- |                                                                                 |
-- |  1.2     2011-05-25   Joe Klein          Defect 11660                           |
-- |                                          1) Fixed error handling to end in      |
-- |                                          warning if invalid card type.          |
-- |                                          2) For 998 record selection, add       |
-- |                                          'WHERE status = 'MATCHED_AR to select. |
-- |                                          3) When selecting against              |
-- |                                          xx_ce_recon_glact_hdr_v, use           |
-- |                                          om_card_type instead of ajb_card_type. |
-- |                                                                                 |
-- |  1.3     2011-06-03   Joe Klein          Defect 11660                           |
-- |                                          1) Fixed error handling to close       |
-- |                                          lcu_get_recon_batches cursor if any    |
-- |                                          errors and rollbacks.                  |
-- | 1.4      2013-08-01   Anantha Reddy      Replaced equivalent table names as     |
-- |                                          per R12 upgrade                        |
-- | 1.5      2015-10-28   Avinash Baddam     R12.2 Compliance changes               |
-- +=================================================================================+


-- -------------------------------------------
-- Global Variables
-- ----------------------------------------------
   gn_request_id              NUMBER         := fnd_global.conc_request_id;
   gn_user_id                 NUMBER         := fnd_global.user_id;
   gn_org_id                  NUMBER         := fnd_profile.VALUE ('ORG_ID');
   gn_set_of_bks_id           NUMBER         := fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
   gc_conc_short_name         VARCHAR2 (30)  := 'XXCECCTRANSJRNL';
   gn_error                   NUMBER         := 2;
   gn_warning                 NUMBER         := 1;
   gn_normal                  NUMBER         := 0;
   gn_coa_id                  NUMBER;
   gc_delimiter               VARCHAR2 (30)  := '.';
   gc_currency_code           VARCHAR2 (30);
   g_print_line               VARCHAR2 (125)
      := '------------------------------------------------------------------------------------------------------------------------';


-- +=================================================================================+
-- |                                                                                 |
-- | PROCEDURE                                                                       |
-- |   print_message_header                                                          |
-- |                                                                                 |
-- | DESCRIPTION                                                                     |
-- |  Procedure to Print the Message Header                                          |
-- |                                                                                 |
-- | PARAMETERS                                                                      |
-- | ==========                                                                      |
-- | NAME                    TYPE    DESCRIPTION                                     |
-- | ----------------------- ------- ----------------------------------------        |
-- | x_errbuf                 OUT     Error message.                                 |
-- | x_retcode                OUT     Error code.                                    |
-- | p_title                  IN      Message Title                                  |
-- +=================================================================================+
   PROCEDURE print_message_header (
      x_errbuf    OUT NOCOPY   VARCHAR2
    , x_retcode   OUT NOCOPY   NUMBER
    , p_title     IN           VARCHAR2
   )
   IS
   BEGIN
-- ------------------------------------------------
-- Set the Concurrent program Output header display
-- ------------------------------------------------
      fnd_file.new_line (fnd_file.output, 1);
      fnd_file.put_line (fnd_file.output
                       ,    LPAD (' ', 40, ' ')
                         || p_title
                        );
      fnd_file.new_line (fnd_file.output, 1);
      fnd_file.put_line (fnd_file.output
                       ,    'Request ID: '
                         || gn_request_id
                         || RPAD (' ', 60, ' ')
                         || 'Request Date: '
                         || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MM')
                        );
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
         fnd_message.set_token ('PACKAGE'
                              , 'XX_CE_CC_TRANS_PKG.print_message_header'
                               );
         fnd_message.set_token ('PROGRAM'
                              , 'OD: CE CreditCard Transaction Journals'
                               );
         fnd_message.set_token ('SQLERROR', SQLERRM);
         x_errbuf := fnd_message.get;
         x_retcode := gn_error;
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
      x_errbuf         OUT NOCOPY      VARCHAR2
    , x_retcode        OUT NOCOPY      NUMBER
    , p_bank_rec_id    IN              VARCHAR2
    , p_processor_id   IN              VARCHAR2
    , p_card_type      IN              VARCHAR2
    , p_store_num      IN              VARCHAR2
    , p_net_amount     IN              NUMBER
    , p_process_date   IN              VARCHAR2
    , p_message        IN              VARCHAR2
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
                            || REPLACE (p_message
                                      , CHR (10)
                                      , CHR (10) || RPAD (' ', (40), ' ')
                                       )
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
                            || REPLACE (p_message
                                      , CHR (10)
                                      , CHR (10) || RPAD (' ', (40), ' ')
                                       )
                           );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE'
                              , 'XX_CE_CC_TRANS_PKG.print_message_footer'
                               );
         fnd_message.set_token ('PROGRAM'
                              , 'OD: CE CreditCard Transaction Journals'
                               );
         fnd_message.set_token ('SQLERROR', SQLERRM);
         x_errbuf := fnd_message.get;
         x_retcode := gn_error;
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
      x_errbuf    OUT NOCOPY      VARCHAR2
    , x_retcode   OUT NOCOPY      NUMBER
    , p_total     IN              NUMBER
    , p_error     IN              NUMBER
    , p_success   IN              NUMBER
   )
   IS
   BEGIN
      IF p_total > 0
      THEN
         fnd_file.new_line (fnd_file.output, 1);
-------------------------------------------------------------------------------------------------
         fnd_file.put_line
             (fnd_file.output
            , '==============================================================='
             );
         fnd_file.put_line (fnd_file.output
                          ,    'OD: CE CreditCard Transaction Journals : '
                            || 'E2082'
                           );
         fnd_file.put_line
              (fnd_file.output
             , '==============================================================='
              );
         fnd_file.put_line (fnd_file.output
                          ,    'Total Records Found               : '
                            || NVL (p_total, 0)
                           );
         fnd_file.put_line (fnd_file.output
                          ,    'Error Records                     : '
                            || NVL (p_error, 0)
                           );
         fnd_file.put_line (fnd_file.output
                          ,    'Success Records                   : '
                            || NVL (p_success, 0)
                           );
         fnd_file.put_line
              (fnd_file.output
             , '==============================================================='
              );
         fnd_file.new_line (fnd_file.output, 4);
      ELSE
-------------------------------------------------------------------------------------------------------------
         fnd_file.new_line (fnd_file.output, 2);
         fnd_file.put_line (fnd_file.output
                          ,    RPAD ('-', 46, '-')
                            || '  No Records to process  '
                            || RPAD ('-', 46, '-')
                           );
-------------------------------------------------------------------------------------------------------------
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE'
                              , 'XX_CE_CC_TRANS_PKG.print_message_summary'
                               );
         fnd_message.set_token ('PROGRAM', 'OD: CE CreditCard Transaction Journals');
         fnd_message.set_token ('SQLERROR', SQLERRM);
         x_errbuf := fnd_message.get;
         x_retcode := gn_error;
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
   END print_message_summary;

-- +=================================================================================+
-- | Name        : lp_create_998_journals                                            |
-- | Description : Procedure to create journals for transaction(998) data provided   |
-- |               by AJB.                                                           |
-- |                                                                                 |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message                                   |
-- |x_retcode                OUT     Error code                                      |
-- |p_provider_code          IN      Provider Code                                   |
-- |p_bank_rec_id            IN      Bank Reconciliation ID                          |
-- +=================================================================================+
   PROCEDURE lp_create_998_journals  (
      x_errbuf    OUT NOCOPY   VARCHAR2
    , x_retcode   OUT NOCOPY   NUMBER
    , p_provider_code IN VARCHAR2
    , p_bank_rec_id   IN VARCHAR2
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
            FROM xx_ce_999_interface xc9i
           WHERE 1 = 1
             AND record_type = 'AJB'
             AND processor_id = NVL (lp_processor_id, xc9i.processor_id)
             AND xc9i.deposits_matched = 'Y'
             AND NVL (xc9i.x998_gl_complete, 'N') = 'N'
             AND xc9i.bank_rec_id = NVL(lp_bank_rec_id,xc9i.bank_rec_id)
             AND (   (EXISTS (SELECT 1
                                FROM xx_ce_ajb998_v xca8
                               WHERE xca8.bank_rec_id = xc9i.bank_rec_id
                                 AND xca8.processor_id = xc9i.processor_id
                                 AND xca8.status = 'MATCHED_AR')                -- Defect 11660 added
                     )
                 );

   CURSOR lcu_get_recon_batches (
      p_processor_id VARCHAR2
    , p_bank_rec_id VARCHAR2
   )
   IS
      SELECT   xcan.bank_rec_id
             , xcan.processor_id
             , xcan.recon_date
             , xcan.currency
             , xcan.card_type
             , SUM (xcan.trx_amount) trx_amount
          FROM xx_ce_ajb998_v xcan
         WHERE 1 = 1
           AND xcan.bank_rec_id = p_bank_rec_id
           AND xcan.processor_id = p_processor_id
           AND xcan.status = 'MATCHED_AR'                                       -- Defect 11660 added
      GROUP BY xcan.bank_rec_id
             , xcan.processor_id
             , xcan.recon_date
             , xcan.currency
             , xcan.card_type;

   CURSOR lcu_get_recon_hdr (
      p_processor IN VARCHAR2
    , p_card_type IN VARCHAR2
    , p_process_date IN DATE
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
                 FROM xx_ce_recon_glact_hdr_v xcgh, fnd_lookup_values lv        -- Defect 11660 added join to fnd_lookup_values
                WHERE xcgh.provider_code = p_processor
               --   AND xcgh.ajb_card_type = p_card_type                        -- Defect 11660 commented
                  AND lv.meaning = p_card_type                                  -- Defect 11660 added
                  AND lv.lookup_code  = xcgh.om_card_type                       -- Defect 11660 added
                  AND lv.enabled_flag = 'Y'                                     -- Defect 11660 added
                  AND lv.lookup_type  = 'OD_PAYMENT_TYPES'                      -- Defect 11660 added
                  AND p_process_date BETWEEN xcgh.effective_from_date AND NVL (xcgh.effective_to_date, p_process_date + 1)
             ORDER BY xcgh.provider_code
                    , xcgh.ajb_card_type;

-- -------------------------------------------
-- Get the Chart of Accounts ID
-- -------------------------------------------
   --1.4-Replaced equivalent table as per R12 upgrade
   CURSOR lcu_get_coaid
   IS
      SELECT gll.chart_of_accounts_id
           , gll.currency_code
        FROM gl_ledgers gll
       WHERE ledger_id = gn_set_of_bks_id;

-- -------------------------------------------
-- Local Variable Declaration
-- -------------------------------------------

   intf_batches_rec              lcu_get_intf_batches%ROWTYPE;
   recon_batches_rec             lcu_get_recon_batches%ROWTYPE;
   recon_hdr_rec                 lcu_get_recon_hdr%ROWTYPE;
   lc_error_details              VARCHAR2 (32000);
   lc_error_location             VARCHAR2 (32000);
   lc_errmsg                     VARCHAR2 (2000);
   lc_output_msg                 VARCHAR2 (2000);
   lc_source_err_flag            VARCHAR2 (1);
   lc_err_msg                    VARCHAR2 (2000);
   lc_company                    VARCHAR2 (150);
   lc_intercompany               VARCHAR2 (30) := '0000';
   lc_future                     VARCHAR2 (30) := '000000';
   lc_ar_recv_lob                VARCHAR2 (150);
   lc_bank_clearing_lob          VARCHAR2 (150);
   lc_error_flag                 VARCHAR2 (1) := 'N';
   ln_success_rec                NUMBER := 0;
   ln_total_rec                  NUMBER := 0;
   ln_error_rec                  NUMBER := 0;
   ln_retcode                    NUMBER;
   ln_err_msg_count              NUMBER;
   ln_group_id                   NUMBER;
   ln_ar_recv_ccid               NUMBER;
   lc_ar_recv_acct               gl_code_combinations_kfv.concatenated_segments%TYPE;
   lc_ar_recv_cc                 VARCHAR2(100);
   ln_bank_clearing_ccid         NUMBER;
   lc_bank_clearing_acct         gl_code_combinations_kfv.concatenated_segments%TYPE;
   lc_bank_clearing_cc           VARCHAR2(100);
   ln_entered_dr_amount          NUMBER;
   ln_entered_cr_amount          NUMBER;
   ln_email_request_id           NUMBER;
   lc_email_address              VARCHAR2 (1000);                                                                                                       -- Added for the Defect 6138
   lc_email_body                 VARCHAR2 (10000);
   lc_intf_batch_savepoint       VARCHAR2 (100);
   ex_recon_batch_exception      EXCEPTION;
   lc_je_line_desc               gl_je_lines.description%TYPE;
   lc_orig_store_num             xx_ce_ajb998.store_num%TYPE;
   lc_message                    VARCHAR2 (100);
   lc_orig_card_type             xx_ce_ajb998.card_type%TYPE;
   ln_entered_dr_total           NUMBER := 0;
   ln_entered_cr_total           NUMBER := 0;
   lc_processed                  VARCHAR2(100);
   lc_title                      VARCHAR2(100);
   ln_count                      NUMBER := 0 ;

   BEGIN

-- -------------------------------------------
-- Call the Print Message Header
-- -------------------------------------------
   lc_title := 'Creditcard 998 Transaction Journal';
   print_message_header (x_errbuf => lc_errmsg, x_retcode => ln_retcode, p_title => lc_title);

   xx_ce_cc_common_pkg.od_message ('M', ' ');
   xx_ce_cc_common_pkg.od_message ('M', ' ');
   xx_ce_cc_common_pkg.od_message ('M', ' ');
   xx_ce_cc_common_pkg.od_message ('M', '--------------------------- Start 998 Transaction Journals procedure ------------------------');
   xx_ce_cc_common_pkg.od_message ('M', ' ');
   xx_ce_cc_common_pkg.od_message ('M'
             ,    'Parameters - Provider:'
               || NVL (p_provider_code, 'ALL')
               || '   Bank Reconciliation ID: '
               || NVL (p_bank_rec_id,'ALL')
                );
   xx_ce_cc_common_pkg.od_message ('M', ' ');

-- -------------------------------------------
-- Initializing Local Variables
-- -------------------------------------------
   lc_error_location     := 'Initializing Local Variables';
   lc_source_err_flag    := 'N';
   lc_error_details      := NULL;
   lc_errmsg             := NULL;
   lc_output_msg         := NULL;
   lc_err_msg            := NULL;
   ln_retcode            := 0;
   ln_err_msg_count      := 0;
   ln_success_rec        := 0;
   ln_error_rec          := 0;

-- --------------------------------------------
--  Get all Unreconciled Batches
-- --------------------------------------------
   FOR intf_batches_rec IN lcu_get_intf_batches (p_provider_code, p_bank_rec_id)
   LOOP
    BEGIN
      lc_error_location           := 'Intf Batches before savepoint';
      lc_intf_batch_savepoint     :=  intf_batches_rec.processor_id || '-' || intf_batches_rec.bank_rec_id;
      SAVEPOINT lc_intf_batch_savepoint;

      OPEN lcu_get_recon_batches (intf_batches_rec.processor_id, intf_batches_rec.bank_rec_id);

      LOOP
         BEGIN
            FETCH lcu_get_recon_batches
             INTO recon_batches_rec;

            EXIT WHEN lcu_get_recon_batches%NOTFOUND;

-- -------------------------------------------------
-- Get group id for all GL transaction entries once.
-- -------------------------------------------------
            IF NVL (ln_group_id, 0) = 0
            THEN
               SELECT gl_interface_control_s.NEXTVAL
                 INTO ln_group_id
                 FROM DUAL;
               xx_ce_cc_common_pkg.od_message ('M', 'Group ID:' || ln_group_id);
            END IF;

            lc_error_details            := NULL;
            lc_error_flag               := 'N';
            lc_source_err_flag          := 'N';
            lc_output_msg               := NULL;
            lc_company                  := NULL;
            lc_ar_recv_lob              := NULL;
            lc_bank_clearing_lob        := NULL;
            ln_ar_recv_ccid             := NULL;
            ln_bank_clearing_ccid       := NULL;
            ln_total_rec                := ln_total_rec + 1;

            xx_ce_cc_common_pkg.od_message ('M', ' ');
            xx_ce_cc_common_pkg.od_message ('M', g_print_line);
            fnd_file.put_line (fnd_file.LOG, 'RECORD NUMBER : ' || ln_total_rec);
            xx_ce_cc_common_pkg.od_message ('M', ' ');
            xx_ce_cc_common_pkg.od_message ('M'
                      ,    'Process Bank Rec ID:'
                        || recon_batches_rec.bank_rec_id
                        || ' / Provider:'
                        || recon_batches_rec.processor_id
                        || ' / Card Type:'
                        || NVL (recon_batches_rec.card_type, 'Not Found')
                        || ' / Payment Amount:'
                        || recon_batches_rec.currency
                        || ' '
                        || recon_batches_rec.trx_amount
                       );
            lc_message                  := NULL;
            lc_orig_card_type           := recon_batches_rec.card_type;

            IF recon_batches_rec.card_type IS NULL
            THEN
               recon_batches_rec.card_type    := xx_ce_cc_common_pkg.get_default_card_type (recon_batches_rec.processor_id, gn_org_id);
               lc_message                     := 'Default Card Type to ' || recon_batches_rec.card_type || '. ';
               xx_ce_cc_common_pkg.od_message ('M', 'No Card type - Defaulting to ' || recon_batches_rec.card_type);
            END IF;

            IF recon_batches_rec.card_type IS NULL
            THEN
               xx_ce_cc_common_pkg.od_message ('M', 'Cannot default Card Type for Provider!');
               lc_error_flag := 'Y';
               RAISE ex_recon_batch_exception;
            END IF;

            lc_orig_store_num := '010000';  -- For E2082, always use loc 10000 to get company

            IF lcu_get_recon_hdr%ISOPEN
            THEN
               CLOSE lcu_get_recon_hdr;
            END IF;

            recon_hdr_rec               := NULL;

            BEGIN
               OPEN lcu_get_recon_hdr (p_processor         => recon_batches_rec.processor_id
                                     , p_card_type         => recon_batches_rec.card_type
                                     , p_process_date      => recon_batches_rec.recon_date
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

            recon_hdr_rec      := NULL;
            lc_error_location  := 'Error:Derive Company from location-Store ' || lc_orig_store_num;
            lc_company         := xx_gl_translate_utl_pkg.derive_company_from_location (p_location => lc_orig_store_num, p_org_id => gn_org_id);

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
                                           || ')';
            lc_error_details            := NULL;
            lc_error_flag               := 'N';

-- -------------------------------------------
--  Get the Accounting.
-- -------------------------------------------
            FOR recon_hdr_rec IN lcu_get_recon_hdr (p_processor         => recon_batches_rec.processor_id
                                                  , p_card_type         => recon_batches_rec.card_type
                                                  , p_process_date      => recon_batches_rec.recon_date
                                                   )
            LOOP
               BEGIN
                  ln_ar_recv_ccid          := NULL;
                  ln_bank_clearing_ccid    := NULL;
                  lc_ar_recv_lob           := NULL;
                  lc_bank_clearing_lob     := NULL;
                  ln_entered_dr_amount     := NULL;
                  ln_entered_cr_amount     := NULL;
                  lc_je_line_desc          :=    'Net Payment for '
                                             || recon_batches_rec.processor_id
                                             || ' / Card Type:'
                                             || recon_hdr_rec.ajb_card_type
                                             || ' / Recon Batch '
                                             || recon_batches_rec.bank_rec_id;

-- -----------------------------------------------
--  Derive the DR Bank Clearing Account CCID.
-- -----------------------------------------------
                  lc_error_location        :=    'Error:Derive DR Bank Clearing LOB from location ('
                                              || lc_orig_store_num
                                              || ') and costcenter ('
                                              || recon_hdr_rec.bank_clearing_costcenter
                                              || ').';
                  xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc (p_location           => lc_orig_store_num
                                                                     , p_cost_center        => recon_hdr_rec.bank_clearing_costcenter
                                                                     , x_lob                => lc_bank_clearing_lob
                                                                     , x_error_message      => lc_errmsg
                                                                      );

                  IF lc_bank_clearing_lob IS NULL
                  THEN
                     fnd_message.set_name ('XXFIN', 'XX_CE_021_LOB_NOT_SETUP');
                     lc_error_details    :=    'Error Getting DR Bank Clearing LOB for location '
                                            || lc_orig_store_num
                                            || ' Cost Center '
                                            || recon_hdr_rec.bank_clearing_costcenter
                                            || lc_error_details
                                            || '/'
                                            || lc_errmsg
                                            || '-'
                                            || fnd_message.get;
                     lc_error_flag       := 'Y';
                     xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                     RAISE ex_recon_batch_exception;
                  END IF;
                  IF lc_bank_clearing_cc  IS NULL THEN
                      lc_bank_clearing_cc := recon_hdr_rec.bank_clearing_costcenter;
                  END IF;

                  lc_bank_clearing_acct :=
                           lc_company
                        || gc_delimiter
                        || recon_hdr_rec.bank_clearing_costcenter
                        || gc_delimiter
                        || recon_hdr_rec.bank_clearing_account
                        || gc_delimiter
                        || lc_orig_store_num
                        || gc_delimiter
                        || lc_intercompany
                        || gc_delimiter
                        || lc_bank_clearing_lob
                        || gc_delimiter
                        || lc_future;
                     lc_error_location := 'Get DR Bank Clearing CCID for ' || lc_bank_clearing_acct;
                     ln_bank_clearing_ccid := fnd_flex_ext.get_ccid
                                       (application_short_name => 'SQLGL'
                                      , key_flex_code => 'GL#'
                                      , structure_number => gn_coa_id
                                      , validation_date => SYSDATE
                                      , concatenated_segments => lc_bank_clearing_acct
                                       );
                     IF ln_bank_clearing_ccid = 0
                     THEN
                        fnd_message.set_name ('XXFIN'
                                            , 'XX_CE_022_CCID_NOT_SETUP'
                                             );
                        lc_error_details :=
                              'Error Deriving DR Bank Clearing Account CCID for '
                           || lc_bank_clearing_acct
                           || '-'
                           || lc_error_details
                           || '-'
                           || fnd_message.get;
                        lc_error_flag := 'Y';
                        xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                        RAISE ex_recon_batch_exception;
                     END IF;

                     IF recon_batches_rec.trx_amount < 0 THEN
                        ln_entered_dr_amount := 0;
                        ln_entered_cr_amount := ABS(recon_batches_rec.trx_amount);
                     ELSE
                        ln_entered_dr_amount := recon_batches_rec.trx_amount;
                        ln_entered_cr_amount := 0;
                     END IF;
                     --ln_entered_dr_amount := ABS(recon_batches_rec.trx_amount);
                     --ln_entered_cr_amount := 0;

                     xx_gl_interface_pkg.create_stg_jrnl_line (
                                            p_status                 => 'NEW'
                                          , p_date_created           => TRUNC (SYSDATE)
                                          , p_created_by             => gn_user_id
                                          , p_actual_flag            => 'A'
                                          , p_group_id               => ln_group_id
                                          , p_je_reference           => ln_group_id
                                          , p_batch_name             => TO_CHAR (SYSDATE, 'YYYY/MM/DD')
                                          , p_batch_desc             => NULL
                                          , p_user_source_name       => 'OD CM Credit Settle'
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
                                          , p_ccid                   => ln_bank_clearing_ccid
                                          , p_entered_dr             => ln_entered_dr_amount
                                          , p_entered_cr             => ln_entered_cr_amount
                                          , p_je_line_dsc            => lc_je_line_desc
                                          , x_output_msg             => lc_output_msg
                                           );
                     IF lc_output_msg IS NOT NULL
                     THEN
                        lc_error_details    := 'Error creating 998 DR Journal line:' || lc_error_details || lc_output_msg;
                        lc_error_flag       := 'Y';
                        xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                        RAISE ex_recon_batch_exception;
                     END IF;
                     xx_ce_cc_common_pkg.od_message
                               ('M'
                              ,    RPAD (   'DR Amt to Bank Cash Clearing:'
                                         || recon_batches_rec.currency
                                         || ' '
                                         || recon_batches_rec.trx_amount
                                       , 50
                                       , ' '
                                        )
                                || ' '
                                || RPAD (lc_bank_clearing_acct, 45, ' ')
                                || LPAD (ABS(recon_batches_rec.trx_amount)
                                       , 12
                                       , ' '
                                        )
                               );


-- -----------------------------------------------
--  Derive the CR AR Receivable Account CCID.
-- -----------------------------------------------
                  lc_error_location        :=    'Error:Derive CR AR Receivable LOB from location ('
                                              || lc_orig_store_num
                                              || ') and costcenter ('
                                              || recon_hdr_rec.ar_recv_costcenter
                                              || ').';
                  xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc (p_location           => lc_orig_store_num
                                                                     , p_cost_center        => recon_hdr_rec.ar_recv_costcenter
                                                                     , x_lob                => lc_ar_recv_lob
                                                                     , x_error_message      => lc_errmsg
                                                                      );

                  IF lc_ar_recv_lob IS NULL
                  THEN
                     fnd_message.set_name ('XXFIN', 'XX_CE_023_LOB_NOT_SETUP');
                     lc_error_details    :=    'Error Getting CR AR Receivable LOB for location '
                                            || lc_orig_store_num
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
                  END IF;
                  IF lc_ar_recv_cc  IS NULL THEN
                      lc_ar_recv_cc := recon_hdr_rec.ar_recv_costcenter;
                  END IF;
                  lc_ar_recv_acct :=
                           lc_company
                        || gc_delimiter
                        || recon_hdr_rec.ar_recv_costcenter
                        || gc_delimiter
                        || recon_hdr_rec.ar_recv_account
                        || gc_delimiter
                        || lc_orig_store_num
                        || gc_delimiter
                        || lc_intercompany
                        || gc_delimiter
                        || lc_ar_recv_lob
                        || gc_delimiter
                        || lc_future;
                     lc_error_location := 'Get CR AR Receivable CCID for ' || lc_ar_recv_acct;
                     ln_ar_recv_ccid := fnd_flex_ext.get_ccid
                                       (application_short_name => 'SQLGL'
                                      , key_flex_code => 'GL#'
                                      , structure_number => gn_coa_id
                                      , validation_date => SYSDATE
                                      , concatenated_segments => lc_ar_recv_acct
                                       );
                     IF ln_ar_recv_ccid = 0
                     THEN
                        fnd_message.set_name ('XXFIN'
                                            , 'XX_CE_024_CCID_NOT_SETUP'
                                             );
                        lc_error_details :=
                              'Error Deriving CR AR Receivable Account CCID for '
                           || lc_ar_recv_acct
                           || '-'
                           || lc_error_details
                           || '-'
                           || fnd_message.get;
                        lc_error_flag := 'Y';
                        xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                        RAISE ex_recon_batch_exception;
                     END IF;

                     IF recon_batches_rec.trx_amount < 0 THEN
                        ln_entered_dr_amount := ABS(recon_batches_rec.trx_amount);
                        ln_entered_cr_amount := 0;
                     ELSE
                        ln_entered_dr_amount := 0;
                        ln_entered_cr_amount := recon_batches_rec.trx_amount;
                     END IF;
                     --ln_entered_dr_amount := 0;
                     --ln_entered_cr_amount := ABS(recon_batches_rec.trx_amount);

                     xx_gl_interface_pkg.create_stg_jrnl_line (
                                            p_status                 => 'NEW'
                                          , p_date_created           => TRUNC (SYSDATE)
                                          , p_created_by             => gn_user_id
                                          , p_actual_flag            => 'A'
                                          , p_group_id               => ln_group_id
                                          , p_je_reference           => ln_group_id
                                          , p_batch_name             => TO_CHAR (SYSDATE, 'YYYY/MM/DD')
                                          , p_batch_desc             => NULL
                                          , p_user_source_name       => 'OD CM Credit Settle'
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
                                          , p_entered_dr             => ln_entered_dr_amount
                                          , p_entered_cr             => ln_entered_cr_amount
                                          , p_je_line_dsc            => lc_je_line_desc
                                          , x_output_msg             => lc_output_msg
                                           );

                     IF lc_output_msg IS NOT NULL
                     THEN
                        lc_error_details    := 'Error creating 998 CR Journal line:' || lc_error_details || lc_output_msg;
                        lc_error_flag       := 'Y';
                        xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                        RAISE ex_recon_batch_exception;
                     END IF;
                     xx_ce_cc_common_pkg.od_message
                               ('M'
                              ,    RPAD (   'CR Amt to AR CC Receivable:  '
                                         || recon_batches_rec.currency
                                         || ' '
                                         || recon_batches_rec.trx_amount
                                       , 50
                                       , ' '
                                        )
                                || ' '
                                || RPAD (lc_ar_recv_acct, 45, ' ')
                                || LPAD (' ', 12, ' ')
                                || ' '
                                || LPAD (ABS(recon_batches_rec.trx_amount)
                                       , 12
                                       , ' '
                                        )
                               );


               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lc_error_details    := 'Other Error Processing Recon Header : ' || lc_error_location || '. ' || SQLCODE || ':' || SQLERRM;
                     xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                     lc_error_flag       := 'Y';
                     RAISE ex_recon_batch_exception;
               END;
            END LOOP;       -- end recon_hdr_rec loop

            lc_error_location           := 'After Get Recon Hdr';

            IF recon_batches_rec.trx_amount =0 THEN
               lc_processed := 'No Amount to be Processed';
            ELSE
               lc_processed := 'Processed';
            END IF;

            print_message_footer (x_errbuf            => lc_errmsg
                                , x_retcode           => ln_retcode
                                , p_bank_rec_id       => recon_batches_rec.bank_rec_id
                                , p_processor_id      => recon_batches_rec.processor_id
                                , p_card_type         => NVL (lc_orig_card_type, recon_batches_rec.card_type)
                                , p_store_num         => lc_orig_store_num
                                , p_net_amount        => recon_batches_rec.trx_amount
                                , p_process_date      => recon_batches_rec.recon_date
                                , p_message           => lc_message || NVL (lc_error_details, lc_processed)
                                 );

             IF lc_error_details IS NULL AND NVL (lc_error_flag, 'N') = 'N' THEN
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
            WHEN OTHERS
            THEN
               print_message_footer (x_errbuf            => lc_errmsg
                                   , x_retcode           => ln_retcode
                                   , p_bank_rec_id       => recon_batches_rec.bank_rec_id
                                   , p_processor_id      => recon_batches_rec.processor_id
                                   , p_card_type         => NVL (lc_orig_card_type, recon_batches_rec.card_type)
                                   , p_store_num         => lc_orig_store_num
                                   , p_net_amount        => recon_batches_rec.trx_amount
                                   , p_process_date      => recon_batches_rec.recon_date
                                   , p_message           => NVL (lc_error_details, 'Error - Review Log for details')
                                    );
               --lc_error_flag    := 'Y';
               --ln_error_rec     := ln_error_rec + 1;
               RAISE ex_recon_batch_exception;
         END;
      END LOOP;   -- end get_recon_batches

      CLOSE lcu_get_recon_batches;

      xx_ce_cc_common_pkg.od_message ('M', ' ');
      xx_ce_cc_common_pkg.od_message ('M', g_print_line);
      xx_ce_cc_common_pkg.od_message ('M', ' ');

      BEGIN
         UPDATE xx_ce_999_interface xc9i1
            SET x998_gl_complete = 'Y'
              , concurrent_pgm_last = gn_request_id
              , last_update_date = SYSDATE
              , last_updated_by = gn_user_id
          WHERE bank_rec_id = intf_batches_rec.bank_rec_id
            AND processor_id = intf_batches_rec.processor_id
            AND NVL (deposits_matched, 'N') = 'Y'
            AND NVL (x998_gl_complete, 'N') = 'N';
        ln_count := sql%rowcount;
        fnd_file.put_line (fnd_file.LOG, ' Total xx_ce_999_interface records updated with x996_gl_complete = ''Y'':' || ln_count );
        fnd_file.put_line (fnd_file.LOG, ' ' );
      END;

    EXCEPTION
         WHEN ex_recon_batch_exception
            THEN
               print_message_footer (x_errbuf            => lc_errmsg
                                   , x_retcode           => ln_retcode
                                   , p_bank_rec_id       => recon_batches_rec.bank_rec_id
                                   , p_processor_id      => recon_batches_rec.processor_id
                                   , p_card_type         => NVL (lc_orig_card_type, recon_batches_rec.card_type)
                                   , p_store_num         => lc_orig_store_num
                                   , p_net_amount        => recon_batches_rec.trx_amount
                                   , p_process_date      => recon_batches_rec.recon_date
                                   , p_message           => NVL (lc_error_details, 'Error - Review Log for details')
                                    );
               lc_error_flag    := 'Y';
               ln_error_rec     := ln_error_rec + 1;
               ROLLBACK TO lc_intf_batch_savepoint;
               IF lcu_get_recon_batches%ISOPEN THEN                             --Defect 11660 added this IF block
                  CLOSE lcu_get_recon_batches;
               END IF;
         WHEN OTHERS
         THEN
            xx_ce_cc_common_pkg.od_message ('M', '* * * Error Updating 999 Interface:' || SQLCODE || '-' || SQLERRM);
            ROLLBACK TO lc_intf_batch_savepoint;
            IF lcu_get_recon_batches%ISOPEN THEN                                --Defect 11660 added this IF block
               CLOSE lcu_get_recon_batches;
            END IF;
    END;
   END LOOP;  -- intf_batches_rec loop.

   IF ln_total_rec = 0
   THEN
      xx_ce_cc_common_pkg.od_message ('M', ' ');
      xx_ce_cc_common_pkg.od_message ('M', '  ----------   NO MATCHED BATCHES FOUND FOR PROCESSING ----------');
      xx_ce_cc_common_pkg.od_message ('M', ' ');
   ELSE
      xx_ce_cc_common_pkg.od_message ('M', ' ');
      xx_ce_cc_common_pkg.od_message ('M', ' ');
      xx_ce_cc_common_pkg.od_message ('M', g_print_line);
      xx_ce_cc_common_pkg.od_message ('M', 'Records with Errors:' || ln_error_rec);
      xx_ce_cc_common_pkg.od_message ('M', 'Successful         :' || ln_success_rec);

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
      lc_email_body    :=    'The Credit Card Transaction Journal process has errors.'
                                || '  Please refer the attachment for error details. The program ends in warning until it is corrected.';

      SELECT xftv.target_value1
        INTO lc_email_address
        FROM xx_fin_translatedefinition xftd
           , xx_fin_translatevalues xftv
       WHERE xftv.translate_id = xftd.translate_id
         AND xftd.translation_name = 'XX_CE_FEE_RECON_MAIL_ADDR'
         AND NVL (xftv.enabled_flag, 'N') = 'Y';

      ln_email_request_id    := fnd_request.submit_request (application      => 'xxfin'
                                                         , program          => 'XXODROEMAILER'
                                                         , description      => ''
                                                         , sub_request      => FALSE
                                                         , start_time       => TO_CHAR (SYSDATE, 'DD-MON-YY HH:MI:SS')
                                                         , argument1        => ''
                                                         , argument2        => lc_email_address
                                                         , argument3        => 'AJB Recon Process - ' || TRUNC (SYSDATE)
                                                         , argument4        => lc_email_body
                                                         , argument5        => 'Y'
                                                         , argument6        => gn_request_id
                                                          );
   ELSIF ln_error_rec = 0
   THEN
      x_retcode    := gn_normal;
   END IF;
  EXCEPTION
    WHEN OTHERS
    THEN
      fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
      fnd_message.set_token ('PACKAGE', 'XX_CE_CC_TRANS_PKG.process_trans_journals');
      fnd_message.set_token ('PROGRAM', 'CE Credit Card Reconciliation');
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

   END lp_create_998_journals ;

-- +=================================================================================+
-- | Name        : lp_create_996_journals                                            |
-- | Description : Procedure to create journals for chargebacks(996) data provided   |
-- |               by AJB.                                                           |
-- |                                                                                 |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message                                   |
-- |x_retcode                OUT     Error code                                      |
-- |p_provider_code          IN      Provider Code                                   |
-- |p_bank_rec_id            IN      Bank Reconciliation ID                          |
-- +=================================================================================+
   PROCEDURE lp_create_996_journals  (
      x_errbuf    OUT NOCOPY   VARCHAR2
    , x_retcode   OUT NOCOPY   NUMBER
    , p_provider_code IN VARCHAR2
    , p_bank_rec_id   IN VARCHAR2
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
            FROM xx_ce_999_interface xc9i
           WHERE 1 = 1
             AND record_type = 'AJB'
             AND processor_id = NVL (lp_processor_id, xc9i.processor_id)
             AND xc9i.deposits_matched = 'Y'
             AND NVL (xc9i.x996_gl_complete, 'N') = 'N'
             AND xc9i.bank_rec_id = NVL(lp_bank_rec_id,xc9i.bank_rec_id)
             AND (   (EXISTS (SELECT 1
                                FROM xx_ce_ajb996_v xca8
                               WHERE xca8.bank_rec_id = xc9i.bank_rec_id
                                 AND xca8.processor_id = xc9i.processor_id)
                     )
                 );

   CURSOR lcu_get_recon_batches (
      p_processor_id VARCHAR2
    , p_bank_rec_id VARCHAR2
   )
   IS
      SELECT   xcan.bank_rec_id
             , xcan.processor_id
             , xcan.recon_date
             , xcan.currency
             , xcan.card_type
             , SUM (xcan.chbk_amt) chbk_amt
          FROM xx_ce_ajb996_v xcan
         WHERE 1 = 1
           AND xcan.bank_rec_id = p_bank_rec_id
           AND xcan.processor_id = p_processor_id
      GROUP BY xcan.bank_rec_id
             , xcan.processor_id
             , xcan.recon_date
             , xcan.currency
             , xcan.card_type;

   CURSOR lcu_get_recon_hdr (
      p_processor IN VARCHAR2
    , p_card_type IN VARCHAR2
    , p_process_date IN DATE
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
                 FROM xx_ce_recon_glact_hdr_v xcgh, fnd_lookup_values lv        -- Defect 11660 added join to fnd_lookup_values
                WHERE xcgh.provider_code = p_processor
               --   AND xcgh.ajb_card_type = p_card_type                        -- Defect 11660 commented
                  AND lv.meaning = p_card_type                                  -- Defect 11660 added
                  AND lv.lookup_code  = xcgh.om_card_type                       -- Defect 11660 added
                  AND lv.enabled_flag = 'Y'                                     -- Defect 11660 added
                  AND lv.lookup_type  = 'OD_PAYMENT_TYPES'                      -- Defect 11660 added
                  AND p_process_date BETWEEN xcgh.effective_from_date AND NVL (xcgh.effective_to_date, p_process_date + 1)
             ORDER BY xcgh.provider_code
                    , xcgh.ajb_card_type;

-- -------------------------------------------
-- Get the Chart of Accounts ID
-- -------------------------------------------
--1.4-Replaced equivalent table as per R12 upgrade
   CURSOR lcu_get_coaid
   IS
      SELECT gll.chart_of_accounts_id
           , gll.currency_code
        FROM gl_ledgers gll
       WHERE ledger_id = gn_set_of_bks_id;

-- -------------------------------------------
-- Local Variable Declaration
-- -------------------------------------------

   intf_batches_rec              lcu_get_intf_batches%ROWTYPE;
   recon_batches_rec             lcu_get_recon_batches%ROWTYPE;
   recon_hdr_rec                 lcu_get_recon_hdr%ROWTYPE;
   lc_error_details              VARCHAR2 (32000);
   lc_error_location             VARCHAR2 (32000);
   lc_errmsg                     VARCHAR2 (2000);
   lc_output_msg                 VARCHAR2 (2000);
   lc_source_err_flag            VARCHAR2 (1);
   lc_err_msg                    VARCHAR2 (2000);
   lc_company                    VARCHAR2 (150);
   lc_intercompany               VARCHAR2 (30) := '0000';
   lc_future                     VARCHAR2 (30) := '000000';
   lc_ar_recv_lob                VARCHAR2 (150);
   lc_bank_clearing_lob          VARCHAR2 (150);
   lc_error_flag                 VARCHAR2 (1) := 'N';
   ln_success_rec                NUMBER := 0;
   ln_total_rec                  NUMBER := 0;
   ln_error_rec                  NUMBER := 0;
   ln_retcode                    NUMBER;
   ln_err_msg_count              NUMBER;
   ln_group_id                   NUMBER;
   ln_ar_recv_ccid               NUMBER;
   lc_ar_recv_acct               gl_code_combinations_kfv.concatenated_segments%TYPE;
   lc_ar_recv_cc                 VARCHAR2(100);
   ln_bank_clearing_ccid         NUMBER;
   lc_bank_clearing_acct         gl_code_combinations_kfv.concatenated_segments%TYPE;
   lc_bank_clearing_cc           VARCHAR2(100);
   ln_entered_dr_amount          NUMBER;
   ln_entered_cr_amount          NUMBER;
   ln_email_request_id           NUMBER;
   lc_email_address              VARCHAR2 (1000);
   lc_email_body                 VARCHAR2 (10000);
   lc_intf_batch_savepoint       VARCHAR2 (100);
   ex_recon_batch_exception      EXCEPTION;
   lc_je_line_desc               gl_je_lines.description%TYPE;
   lc_orig_store_num             xx_ce_ajb996.store_num%TYPE;
   lc_message                    VARCHAR2 (100);
   lc_orig_card_type             xx_ce_ajb996.card_type%TYPE;
   ln_entered_dr_total           NUMBER := 0;
   ln_entered_cr_total           NUMBER := 0;
   lc_processed                  VARCHAR2(100);
   lc_title                      VARCHAR2(100);
   ln_count                      NUMBER := 0 ;

   BEGIN

-- -------------------------------------------
-- Call the Print Message Header
-- -------------------------------------------
   lc_title := 'Creditcard 996 Chargeback Journal';
   print_message_header (x_errbuf => lc_errmsg, x_retcode => ln_retcode, p_title => lc_title);

   xx_ce_cc_common_pkg.od_message ('M', ' ');
   xx_ce_cc_common_pkg.od_message ('M', ' ');
   xx_ce_cc_common_pkg.od_message ('M', ' ');
   xx_ce_cc_common_pkg.od_message ('M', '-------------------------- Start 996 Chargeback Journals procedure ------------------------');
   xx_ce_cc_common_pkg.od_message ('M', ' ');
   xx_ce_cc_common_pkg.od_message ('M'
             ,    'Parameters - Provider:'
               || NVL (p_provider_code, 'ALL')
               || '   Bank Reconciliation ID: '
               || NVL (p_bank_rec_id,'ALL')
                );
   xx_ce_cc_common_pkg.od_message ('M', ' ');

-- -------------------------------------------
-- Initializing Local Variables
-- -------------------------------------------
   lc_error_location     := 'Initializing Local Variables';
   lc_source_err_flag    := 'N';
   lc_error_details      := NULL;
   lc_errmsg             := NULL;
   lc_output_msg         := NULL;
   lc_err_msg            := NULL;
   ln_retcode            := 0;
   ln_err_msg_count      := 0;
   ln_success_rec        := 0;
   ln_error_rec          := 0;

-- --------------------------------------------
--  Get all Unreconciled Batches
-- --------------------------------------------
   FOR intf_batches_rec IN lcu_get_intf_batches (p_provider_code, p_bank_rec_id)
   LOOP
    BEGIN
      lc_error_location           := 'Intf Batches before savepoint';
      lc_intf_batch_savepoint     :=  intf_batches_rec.processor_id || '-' || intf_batches_rec.bank_rec_id;
      SAVEPOINT lc_intf_batch_savepoint;

      OPEN lcu_get_recon_batches (intf_batches_rec.processor_id, intf_batches_rec.bank_rec_id);

      LOOP
         BEGIN
            FETCH lcu_get_recon_batches
             INTO recon_batches_rec;

            EXIT WHEN lcu_get_recon_batches%NOTFOUND;

-- -------------------------------------------------
-- Get group id for all GL transaction entries once.
-- -------------------------------------------------
            IF NVL (ln_group_id, 0) = 0
            THEN
               SELECT gl_interface_control_s.NEXTVAL
                 INTO ln_group_id
                 FROM DUAL;
               xx_ce_cc_common_pkg.od_message ('M', 'Group ID:' || ln_group_id);
            END IF;

            lc_error_details            := NULL;
            lc_error_flag               := 'N';
            lc_source_err_flag          := 'N';
            lc_output_msg               := NULL;
            lc_company                  := NULL;
            lc_ar_recv_lob              := NULL;
            lc_bank_clearing_lob        := NULL;
            ln_ar_recv_ccid             := NULL;
            ln_bank_clearing_ccid       := NULL;
            ln_total_rec                := ln_total_rec + 1;

            xx_ce_cc_common_pkg.od_message ('M', ' ');
            xx_ce_cc_common_pkg.od_message ('M', g_print_line);
            fnd_file.put_line (fnd_file.LOG, 'RECORD NUMBER : ' || ln_total_rec);
            xx_ce_cc_common_pkg.od_message ('M', ' ');
            xx_ce_cc_common_pkg.od_message ('M'
                      ,    'Process Bank Rec ID:'
                        || recon_batches_rec.bank_rec_id
                        || ' / Provider:'
                        || recon_batches_rec.processor_id
                        || ' / Card Type:'
                        || NVL (recon_batches_rec.card_type, 'Not Found')
                        || ' / Payment Amount:'
                        || recon_batches_rec.currency
                        || ' '
                        || recon_batches_rec.chbk_amt
                       );
            lc_message                  := NULL;
            lc_orig_card_type           := recon_batches_rec.card_type;

            IF recon_batches_rec.card_type IS NULL
            THEN
               recon_batches_rec.card_type    := xx_ce_cc_common_pkg.get_default_card_type (recon_batches_rec.processor_id, gn_org_id);
               lc_message                     := 'Default Card Type to ' || recon_batches_rec.card_type || '. ';
               xx_ce_cc_common_pkg.od_message ('M', 'No Card type - Defaulting to ' || recon_batches_rec.card_type);
            END IF;

            IF recon_batches_rec.card_type IS NULL
            THEN
               xx_ce_cc_common_pkg.od_message ('M', 'Cannot default Card Type for Provider!');
               lc_error_flag := 'Y';
               RAISE ex_recon_batch_exception;
            END IF;

            lc_orig_store_num := '010000';  -- For E2082, always use loc 10000 to get company

            IF lcu_get_recon_hdr%ISOPEN
            THEN
               CLOSE lcu_get_recon_hdr;
            END IF;

            recon_hdr_rec               := NULL;

            BEGIN
               OPEN lcu_get_recon_hdr (p_processor         => recon_batches_rec.processor_id
                                     , p_card_type         => recon_batches_rec.card_type
                                     , p_process_date      => recon_batches_rec.recon_date
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

            recon_hdr_rec      := NULL;
            lc_error_location  := 'Error:Derive Company from location-Store ' || lc_orig_store_num;
            lc_company         := xx_gl_translate_utl_pkg.derive_company_from_location (p_location => lc_orig_store_num, p_org_id => gn_org_id);

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
                                           || ')';
            lc_error_details            := NULL;
            lc_error_flag               := 'N';

-- -------------------------------------------
--  Get the Accounting.
-- -------------------------------------------
            FOR recon_hdr_rec IN lcu_get_recon_hdr (p_processor         => recon_batches_rec.processor_id
                                                  , p_card_type         => recon_batches_rec.card_type
                                                  , p_process_date      => recon_batches_rec.recon_date
                                                   )
            LOOP
               BEGIN
                  ln_ar_recv_ccid          := NULL;
                  ln_bank_clearing_ccid    := NULL;
                  lc_ar_recv_lob           := NULL;
                  lc_bank_clearing_lob     := NULL;
                  ln_entered_dr_amount     := NULL;
                  ln_entered_cr_amount     := NULL;
                  lc_je_line_desc          :=    'Chargeback Amount for '
                                             || recon_batches_rec.processor_id
                                             || ' / Card Type:'
                                             || recon_hdr_rec.ajb_card_type
                                             || ' / Recon Batch '
                                             || recon_batches_rec.bank_rec_id;

-- -----------------------------------------------
--  Derive the DR AR Receivable Account CCID.
-- -----------------------------------------------
                  lc_error_location        :=    'Error:Derive DR AR Receivable LOB from location ('
                                              || lc_orig_store_num
                                              || ') and costcenter ('
                                              || recon_hdr_rec.ar_recv_costcenter
                                              || ').';
                  xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc (p_location           => lc_orig_store_num
                                                                     , p_cost_center        => recon_hdr_rec.ar_recv_costcenter
                                                                     , x_lob                => lc_ar_recv_lob
                                                                     , x_error_message      => lc_errmsg
                                                                      );

                  IF lc_ar_recv_lob IS NULL
                  THEN
                     fnd_message.set_name ('XXFIN', 'XX_CE_021_LOB_NOT_SETUP');
                     lc_error_details    :=    'Error Getting DR AR Receivable LOB for location '
                                            || lc_orig_store_num
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
                  END IF;
                  IF lc_ar_recv_cc  IS NULL THEN
                      lc_ar_recv_cc := recon_hdr_rec.ar_recv_costcenter;
                  END IF;

                  lc_ar_recv_acct :=
                           lc_company
                        || gc_delimiter
                        || recon_hdr_rec.ar_recv_costcenter
                        || gc_delimiter
                        || recon_hdr_rec.ar_recv_account
                        || gc_delimiter
                        || lc_orig_store_num
                        || gc_delimiter
                        || lc_intercompany
                        || gc_delimiter
                        || lc_ar_recv_lob
                        || gc_delimiter
                        || lc_future;
                     lc_error_location := 'Get DR AR Receivable CCID for ' || lc_ar_recv_acct;
                     ln_ar_recv_ccid := fnd_flex_ext.get_ccid
                                       (application_short_name => 'SQLGL'
                                      , key_flex_code => 'GL#'
                                      , structure_number => gn_coa_id
                                      , validation_date => SYSDATE
                                      , concatenated_segments => lc_ar_recv_acct
                                       );
                     IF ln_ar_recv_ccid = 0
                     THEN
                        fnd_message.set_name ('XXFIN'
                                            , 'XX_CE_022_CCID_NOT_SETUP'
                                             );
                        lc_error_details :=
                              'Error Deriving DR AR Receivable Account CCID for '
                           || lc_ar_recv_acct
                           || '-'
                           || lc_error_details
                           || '-'
                           || fnd_message.get;
                        lc_error_flag := 'Y';
                        xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                        RAISE ex_recon_batch_exception;
                     END IF;

                     IF recon_batches_rec.chbk_amt < 0 THEN
                        ln_entered_dr_amount := 0;
                        ln_entered_cr_amount := ABS(recon_batches_rec.chbk_amt);
                     ELSE
                        ln_entered_dr_amount := recon_batches_rec.chbk_amt;
                        ln_entered_cr_amount := 0;
                     END IF;
                     --ln_entered_dr_amount := ABS(recon_batches_rec.chbk_amt);
                     --ln_entered_cr_amount := 0;

                     xx_gl_interface_pkg.create_stg_jrnl_line (
                                            p_status                 => 'NEW'
                                          , p_date_created           => TRUNC (SYSDATE)
                                          , p_created_by             => gn_user_id
                                          , p_actual_flag            => 'A'
                                          , p_group_id               => ln_group_id
                                          , p_je_reference           => ln_group_id
                                          , p_batch_name             => TO_CHAR (SYSDATE, 'YYYY/MM/DD')
                                          , p_batch_desc             => NULL
                                          , p_user_source_name       => 'OD CM Credit Settle'
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
                                          , p_entered_dr             => ln_entered_dr_amount
                                          , p_entered_cr             => ln_entered_cr_amount
                                          , p_je_line_dsc            => lc_je_line_desc
                                          , x_output_msg             => lc_output_msg
                                           );
                     IF lc_output_msg IS NOT NULL
                     THEN
                        lc_error_details    := 'Error creating 996 DR Journal line:' || lc_error_details || lc_output_msg;
                        lc_error_flag       := 'Y';
                        xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                        RAISE ex_recon_batch_exception;
                     END IF;
                     xx_ce_cc_common_pkg.od_message
                               ('M'
                              ,    RPAD (   'DR Amt to AR CC Receivable:  '
                                         || recon_batches_rec.currency
                                         || ' '
                                         || recon_batches_rec.chbk_amt
                                       , 50
                                       , ' '
                                        )
                                || ' '
                                || RPAD (lc_ar_recv_acct, 45, ' ')
                                || LPAD (ABS(recon_batches_rec.chbk_amt)
                                       , 12
                                       , ' '
                                        )
                               );


-- -----------------------------------------------
--  Derive the CR Bank Clearing Account CCID.
-- -----------------------------------------------
                  lc_error_location        :=    'Error:Derive CR Bank Clearing LOB from location ('
                                              || lc_orig_store_num
                                              || ') and costcenter ('
                                              || recon_hdr_rec.bank_clearing_costcenter
                                              || ').';
                  xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc (p_location           => lc_orig_store_num
                                                                     , p_cost_center        => recon_hdr_rec.bank_clearing_costcenter
                                                                     , x_lob                => lc_bank_clearing_lob
                                                                     , x_error_message      => lc_errmsg
                                                                      );

                  IF lc_bank_clearing_lob IS NULL
                  THEN
                     fnd_message.set_name ('XXFIN', 'XX_CE_023_LOB_NOT_SETUP');
                     lc_error_details    :=    'Error Getting CR Bank Clearing LOB for location '
                                            || lc_orig_store_num
                                            || ' Cost Center '
                                            || recon_hdr_rec.bank_clearing_costcenter
                                            || lc_error_details
                                            || '/'
                                            || lc_errmsg
                                            || '-'
                                            || fnd_message.get;
                     lc_error_flag       := 'Y';
                     xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                     RAISE ex_recon_batch_exception;
                  END IF;
                  IF lc_bank_clearing_cc  IS NULL THEN
                      lc_bank_clearing_cc := recon_hdr_rec.bank_clearing_costcenter;
                  END IF;
                  lc_bank_clearing_acct :=
                           lc_company
                        || gc_delimiter
                        || recon_hdr_rec.bank_clearing_costcenter
                        || gc_delimiter
                        || recon_hdr_rec.bank_clearing_account
                        || gc_delimiter
                        || lc_orig_store_num
                        || gc_delimiter
                        || lc_intercompany
                        || gc_delimiter
                        || lc_bank_clearing_lob
                        || gc_delimiter
                        || lc_future;
                     lc_error_location := 'Get CR Bank Clearing CCID for ' || lc_bank_clearing_acct;
                     ln_bank_clearing_ccid := fnd_flex_ext.get_ccid
                                       (application_short_name => 'SQLGL'
                                      , key_flex_code => 'GL#'
                                      , structure_number => gn_coa_id
                                      , validation_date => SYSDATE
                                      , concatenated_segments => lc_bank_clearing_acct
                                       );
                     IF ln_bank_clearing_ccid = 0
                     THEN
                        fnd_message.set_name ('XXFIN'
                                            , 'XX_CE_024_CCID_NOT_SETUP'
                                             );
                        lc_error_details :=
                              'Error Deriving CR Bank Clearing Account CCID for '
                           || lc_bank_clearing_acct
                           || '-'
                           || lc_error_details
                           || '-'
                           || fnd_message.get;
                        lc_error_flag := 'Y';
                        xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                        RAISE ex_recon_batch_exception;
                     END IF;

                     IF recon_batches_rec.chbk_amt < 0 THEN
                        ln_entered_dr_amount := ABS(recon_batches_rec.chbk_amt);
                        ln_entered_cr_amount := 0;
                     ELSE
                        ln_entered_dr_amount := 0;
                        ln_entered_cr_amount := recon_batches_rec.chbk_amt;
                     END IF;
                     --ln_entered_dr_amount := 0;
                     --ln_entered_cr_amount := ABS(recon_batches_rec.chbk_amt);

                     xx_gl_interface_pkg.create_stg_jrnl_line (
                                            p_status                 => 'NEW'
                                          , p_date_created           => TRUNC (SYSDATE)
                                          , p_created_by             => gn_user_id
                                          , p_actual_flag            => 'A'
                                          , p_group_id               => ln_group_id
                                          , p_je_reference           => ln_group_id
                                          , p_batch_name             => TO_CHAR (SYSDATE, 'YYYY/MM/DD')
                                          , p_batch_desc             => NULL
                                          , p_user_source_name       => 'OD CM Credit Settle'
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
                                          , p_ccid                   => ln_bank_clearing_ccid
                                          , p_entered_dr             => ln_entered_dr_amount
                                          , p_entered_cr             => ln_entered_cr_amount
                                          , p_je_line_dsc            => lc_je_line_desc
                                          , x_output_msg             => lc_output_msg
                                           );

                     IF lc_output_msg IS NOT NULL
                     THEN
                        lc_error_details    := 'Error creating 996 CR Journal line:' || lc_error_details || lc_output_msg;
                        lc_error_flag       := 'Y';
                        xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                        RAISE ex_recon_batch_exception;
                     END IF;
                     xx_ce_cc_common_pkg.od_message
                               ('M'
                              ,    RPAD (   'CR Amt to Bank Cash Clearing:'
                                         || recon_batches_rec.currency
                                         || ' '
                                         || recon_batches_rec.chbk_amt
                                       , 50
                                       , ' '
                                        )
                                || ' '
                                || RPAD (lc_bank_clearing_acct, 45, ' ')
                                || LPAD (' ', 12, ' ')
                                || ' '
                                || LPAD (ABS(recon_batches_rec.chbk_amt)
                                       , 12
                                       , ' '
                                        )
                               );


               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lc_error_details    := 'Other Error Processing Recon Header : ' || lc_error_location || '. ' || SQLCODE || ':' || SQLERRM;
                     xx_ce_cc_common_pkg.od_message ('M', lc_error_details);
                     lc_error_flag       := 'Y';
                     RAISE ex_recon_batch_exception;
               END;
            END LOOP;       -- end recon_hdr_rec loop

            lc_error_location           := 'After Get Recon Hdr';

            IF recon_batches_rec.chbk_amt = 0 THEN
               lc_processed := 'No Amount to be Processed';
            ELSE
               lc_processed := 'Processed';
            END IF;

            print_message_footer (x_errbuf            => lc_errmsg
                                , x_retcode           => ln_retcode
                                , p_bank_rec_id       => recon_batches_rec.bank_rec_id
                                , p_processor_id      => recon_batches_rec.processor_id
                                , p_card_type         => NVL (lc_orig_card_type, recon_batches_rec.card_type)
                                , p_store_num         => lc_orig_store_num
                                , p_net_amount        => recon_batches_rec.chbk_amt
                                , p_process_date      => recon_batches_rec.recon_date
                                , p_message           => lc_message || NVL (lc_error_details, lc_processed)
                                 );

             IF lc_error_details IS NULL AND NVL (lc_error_flag, 'N') = 'N' THEN
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
            WHEN OTHERS
            THEN
               print_message_footer (x_errbuf            => lc_errmsg
                                   , x_retcode           => ln_retcode
                                   , p_bank_rec_id       => recon_batches_rec.bank_rec_id
                                   , p_processor_id      => recon_batches_rec.processor_id
                                   , p_card_type         => NVL (lc_orig_card_type, recon_batches_rec.card_type)
                                   , p_store_num         => lc_orig_store_num
                                   , p_net_amount        => recon_batches_rec.chbk_amt
                                   , p_process_date      => recon_batches_rec.recon_date
                                   , p_message           => NVL (lc_error_details, 'Error - Review Log for details')
                                    );
               --lc_error_flag    := 'Y';
               --ln_error_rec     := ln_error_rec + 1;
               RAISE ex_recon_batch_exception;
         END;
      END LOOP;   -- end get_recon_batches

      CLOSE lcu_get_recon_batches;

      xx_ce_cc_common_pkg.od_message ('M', ' ');
      xx_ce_cc_common_pkg.od_message ('M', g_print_line);
      xx_ce_cc_common_pkg.od_message ('M', ' ');

      BEGIN
         UPDATE xx_ce_999_interface xc9i1
            SET x996_gl_complete = 'Y'
              , concurrent_pgm_last = gn_request_id
              , last_update_date = SYSDATE
              , last_updated_by = gn_user_id
          WHERE bank_rec_id = intf_batches_rec.bank_rec_id
            AND processor_id = intf_batches_rec.processor_id
            AND NVL (deposits_matched, 'N') = 'Y'
            AND NVL (x996_gl_complete, 'N') = 'N';
        ln_count := sql%rowcount;
        fnd_file.put_line (fnd_file.LOG, ' Total xx_ce_999_interface records updated with x996_gl_complete = ''Y'':' || ln_count );
        fnd_file.put_line (fnd_file.LOG, ' ' );
      END;

    EXCEPTION
         WHEN ex_recon_batch_exception
            THEN
               print_message_footer (x_errbuf            => lc_errmsg
                                   , x_retcode           => ln_retcode
                                   , p_bank_rec_id       => recon_batches_rec.bank_rec_id
                                   , p_processor_id      => recon_batches_rec.processor_id
                                   , p_card_type         => NVL (lc_orig_card_type, recon_batches_rec.card_type)
                                   , p_store_num         => lc_orig_store_num
                                   , p_net_amount        => recon_batches_rec.chbk_amt
                                   , p_process_date      => recon_batches_rec.recon_date
                                   , p_message           => NVL (lc_error_details, 'Error - Review Log for details')
                                    );
               lc_error_flag    := 'Y';
               ln_error_rec     := ln_error_rec + 1;
               ROLLBACK TO lc_intf_batch_savepoint;
               IF lcu_get_recon_batches%ISOPEN THEN                             --Defect 11660 added this IF block
                  CLOSE lcu_get_recon_batches;
               END IF;
         WHEN OTHERS
         THEN
            xx_ce_cc_common_pkg.od_message ('M', '* * * Error Updating 999 Interface:' || SQLCODE || '-' || SQLERRM);
            ROLLBACK TO lc_intf_batch_savepoint;
            IF lcu_get_recon_batches%ISOPEN THEN                                --Defect 11660 added this IF block
               CLOSE lcu_get_recon_batches;
            END IF;
    END;
   END LOOP;  -- intf_batches_rec loop.

   IF ln_total_rec = 0
   THEN
      xx_ce_cc_common_pkg.od_message ('M', ' ');
      xx_ce_cc_common_pkg.od_message ('M', '  ----------   NO MATCHED BATCHES FOUND FOR PROCESSING ----------');
      xx_ce_cc_common_pkg.od_message ('M', ' ');
   ELSE
      xx_ce_cc_common_pkg.od_message ('M', ' ');
      xx_ce_cc_common_pkg.od_message ('M', ' ');
      xx_ce_cc_common_pkg.od_message ('M', g_print_line);
      xx_ce_cc_common_pkg.od_message ('M', 'Records with Errors:' || ln_error_rec);
      xx_ce_cc_common_pkg.od_message ('M', 'Successful         :' || ln_success_rec);

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
      lc_email_body    :=    'The Credit Card Transaction Journal process has errors.'
                                || '  Please refer the attachment for error details. The program ends in warning until it is corrected.';

      SELECT xftv.target_value1
        INTO lc_email_address
        FROM xx_fin_translatedefinition xftd
           , xx_fin_translatevalues xftv
       WHERE xftv.translate_id = xftd.translate_id
         AND xftd.translation_name = 'XX_CE_FEE_RECON_MAIL_ADDR'
         AND NVL (xftv.enabled_flag, 'N') = 'Y';

      ln_email_request_id    := fnd_request.submit_request (application      => 'xxfin'
                                                         , program          => 'XXODROEMAILER'
                                                         , description      => ''
                                                         , sub_request      => FALSE
                                                         , start_time       => TO_CHAR (SYSDATE, 'DD-MON-YY HH:MI:SS')
                                                         , argument1        => ''
                                                         , argument2        => lc_email_address
                                                         , argument3        => 'AJB Recon Process - ' || TRUNC (SYSDATE)
                                                         , argument4        => lc_email_body
                                                         , argument5        => 'Y'
                                                         , argument6        => gn_request_id
                                                          );
   ELSIF ln_error_rec = 0
   THEN
      x_retcode    := gn_normal;
   END IF;
  EXCEPTION
    WHEN OTHERS
    THEN
      fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
      fnd_message.set_token ('PACKAGE', 'XX_CE_CC_TRANS_PKG.process_trans_journals');
      fnd_message.set_token ('PROGRAM', 'CE Credit Card Reconciliation');
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

   END lp_create_996_journals ;


-- +=================================================================================+
-- | Name        : update_xx_ce_ajb99x                                               |
-- | Description : This procedure will be used to update xx_ce_999_interface table   |
-- |               setting appropriate x99*_GL_COMPLETE(996 or 998) to 'Y' for       |
-- |               processor_id and bank_rec_id, even if no records on xx_ce_ajb996  |
-- |               or xx_ce_ajb998 tables.                                           |
-- |                                                                                 |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |p_provider_code          IN      Provider Code                                   |
-- |p_bank_rec_id            IN      Bank Reconciliation ID                          |
-- +=================================================================================+
   PROCEDURE update_xx_ce_ajb99x (
      p_provider_code IN VARCHAR2
    , p_bank_rec_id   IN VARCHAR2
   )
   IS
    ln_count number := 0 ;

   BEGIN
-- ------------------------------------------------
-- Set the Concurrent program Output header display
-- ------------------------------------------------
     fnd_file.put_line (fnd_file.LOG, ' Updating xx_ce_999_interface.x996_gl_complete = Y for records without any 996 rows' );
     UPDATE xx_ce_999_interface xc9i
        SET x996_gl_complete = 'Y'
          , last_update_date = sysdate
          , last_updated_by = fnd_global.user_id
      WHERE nvl(x996_gl_complete,'N') != 'Y'
        AND record_type = 'AJB'
        AND processor_id = p_provider_code
        AND bank_rec_id = NVL(p_bank_rec_id, bank_rec_id)
        AND xc9i.deposits_matched = 'Y'
        AND NOT EXISTS (
                       SELECT 1
                         FROM xx_ce_ajb996 xca
                        WHERE 1 = 1
                          AND xca.bank_rec_id = xc9i.bank_rec_id
                          AND xca.processor_id = xc9i.processor_id
                       );
     ln_count := sql%rowcount;
     fnd_file.put_line (fnd_file.LOG, ' Total xx_ce_999_interface records updated without any 996 rows :' || ln_count );
     fnd_file.put_line (fnd_file.LOG, ' ' );

     ln_count := 0;
     fnd_file.put_line (fnd_file.LOG, ' Updating xx_ce_999_interface.x998_gl_complete = Y for records without any 998 rows' );
     UPDATE xx_ce_999_interface xc9i
        SET x998_gl_complete = 'Y'
          , last_update_date = sysdate
          , last_updated_by = fnd_global.user_id
      WHERE nvl(x998_gl_complete,'N') != 'Y'
        AND record_type = 'AJB'
        AND processor_id = p_provider_code
        AND bank_rec_id = NVL(p_bank_rec_id, bank_rec_id)
        AND xc9i.deposits_matched = 'Y'
        AND NOT EXISTS (
                       SELECT 1
                         FROM xx_ce_ajb998 xca
                        WHERE 1 = 1
                          AND xca.bank_rec_id = xc9i.bank_rec_id
                          AND xca.processor_id = xc9i.processor_id
                          AND xca.status = 'MATCHED_AR'  -- Defect 11660 added
                       );
     ln_count := sql%rowcount;
     fnd_file.put_line (fnd_file.LOG, ' Total xx_ce_999_interface records updated without any 998 rows :' || ln_count );
     fnd_file.put_line (fnd_file.LOG, ' ' );

   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, ' Error While updating xx_ce_999_interface in update_xx_ce_ajb99x procedure :' || SQLERRM  );
   END update_xx_ce_ajb99x;



-- +=================================================================================+
-- | Name        : process_trans_journals                                            |
-- | Description : Main procedure to create journals on the credit card chargeback   |
-- |               and transaction data provided by AJB.                             |
-- |                                                                                 |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message                                   |
-- |x_retcode                OUT     Error code                                      |
-- |p_provider_code          IN      Provider Code                                   |
-- |p_bank_rec_id            IN      Bank Reconciliation ID                          |
-- +=================================================================================+
   PROCEDURE process_trans_journals (
      x_errbuf    OUT NOCOPY   VARCHAR2
    , x_retcode   OUT NOCOPY   NUMBER
    , p_provider_code IN VARCHAR2
    , p_bank_rec_id   IN VARCHAR2
   )
   IS


-- -------------------------------------------
-- Get the Chart of Accounts ID
-- -------------------------------------------
--1.4-Replaced equivalent table as per R12 upgrade
   CURSOR lcu_get_coaid
   IS
      SELECT gll.chart_of_accounts_id
           , gll.currency_code
        FROM gl_ledgers gll
       WHERE ledger_id = gn_set_of_bks_id;

-- -------------------------------------------
-- Local Variable Declaration
-- -------------------------------------------

   lc_error_details              VARCHAR2 (32000);
   lc_error_location             VARCHAR2 (32000);
   lc_errmsg                     VARCHAR2 (2000);
   lc_source_err_flag            VARCHAR2 (1);
   ln_retcode                    NUMBER;
   ln_group_id                   NUMBER;

   BEGIN

   xx_ce_cc_common_pkg.od_message ('M', ' ');
   xx_ce_cc_common_pkg.od_message ('M', '  ----------------------    Start Recon Process     ------------------------');
   xx_ce_cc_common_pkg.od_message ('M', ' ');
   xx_ce_cc_common_pkg.od_message ('M'
             ,    'Parameters - Provider:'
               || NVL (p_provider_code, 'ALL')
               || '   Bank Reconciliation ID: '
               || NVL (p_bank_rec_id,'ALL')
                );
   xx_ce_cc_common_pkg.od_message ('M', ' ');

-- -------------------------------------------
-- Initializing Local Variables
-- -------------------------------------------
   lc_error_location     := 'Initializing Local Variables';
   lc_source_err_flag    := 'N';
   lc_error_details      := NULL;
   lc_errmsg             := NULL;
   ln_retcode            := 0;

-- -------------------------------------------
-- Check the set of Books ID
-- -------------------------------------------
   lc_error_location := 'Mandatory Check Set of Books Id';
   IF gn_set_of_bks_id IS NULL
   THEN
      lc_source_err_flag := 'Y';
      fnd_message.set_name ('XXFIN', 'XX_CE_002_SOB_NOT_SETUP');
      lc_error_details := lc_error_details || '-' || fnd_message.get;
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
-- Get the Delimiter.
-- -------------------------------------------
   gc_delimiter          := fnd_flex_ext.get_delimiter (application_short_name => 'SQLGL', key_flex_code => 'GL#', structure_number => gn_coa_id);

-- -------------------------------------------
-- Create 998 journals.
-- -------------------------------------------
   lp_create_998_journals(x_errbuf => lc_errmsg, x_retcode => ln_retcode, p_provider_code => p_provider_code, p_bank_rec_id => p_bank_rec_id);
-- --------------------------------------------

-- -------------------------------------------
-- Create 996 journals.
-- -------------------------------------------
   lp_create_996_journals(x_errbuf => lc_errmsg, x_retcode => ln_retcode, p_provider_code => p_provider_code, p_bank_rec_id => p_bank_rec_id);
-- --------------------------------------------

-- -------------------------------------------
-- Set x996_gl_complete = 'Y' and x998_gl_complete = 'Y' where no 996 or 998 records exist
-- -------------------------------------------
   update_xx_ce_ajb99x(p_provider_code => p_provider_code, p_bank_rec_id => p_bank_rec_id);

   x_retcode := ln_retcode;

   EXCEPTION
     WHEN OTHERS
     THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE', 'XX_CE_CC_TRANS_PKG.process_trans_journals');
         fnd_message.set_token ('PROGRAM', 'CE Credit Card Reconciliation');
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
   END process_trans_journals;

END xx_ce_cc_trans_pkg;
/
