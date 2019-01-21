CREATE OR REPLACE PACKAGE BODY APPS.xx_ce_cc_stmt_match_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                                                                                 |
-- +=================================================================================+
-- | Name       : xx_ce_cc_stmt_match_pkg.pkb                                       |
-- | Description: E2079 OD: CE CreditCard AJB Statement Match                        |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |  1.0     2011-02-09   Joe Klein          New package copied from E1310 to       |
-- |                                          create separate package for the       | 
-- |                                          match procedure.                       |
-- |                                          Include fix for defect 9249 where      |
-- |                                          status_13 was not being updated on     |
-- |                                          996 and 998 tables.                    |
-- |                                          Also changed number of multi match     |
-- |                                          attempt from 7 days to 5 days for E2079|
-- |                                          as compared to E1310.                  |
-- |                                          Also removed NOWAIT from cursor        |
-- |                                          stmt_cc_lines_cur FOR UPDATE clause.   |
-- |                                          Added update of LAST_UPDATED_BY and    |
-- |                                          LAST_UPDATE_DATE columns for any       |
-- |                                          tables that are updated.               |
-- |  1.0     2011-04-21   Joe Klein          E2079, CR 898, Remove check of CHBK    |
-- |                                          codes when updating 996 table. This    |
-- |                                          same check was also removed from       |
-- |                                          view xx_ce_ajb996_v.                   |
-- /  1.1     2013-08-02   Rishabh Chhajer    Retrofitted as per R12 Upgrade for     /
-- /                                          Rice E2079                             /
-- /  1.2     2013-09-20   Rishabh Chhajer    Changed as per R12 Retrofit Defect no. /
-- /                                          #25372,modified trx_code_id to trx_code/
-- +=================================================================================+
-- -------------------------------------------
-- Global Variables
-- ----------------------------------------------
   gn_request_id              NUMBER         := fnd_global.conc_request_id;
   gn_user_id                 NUMBER         := fnd_global.user_id;
   gn_org_id                  NUMBER         := fnd_profile.VALUE ('ORG_ID');
   gn_error                   NUMBER         := 2;
   gn_warning                 NUMBER         := 1;
   gn_normal                  NUMBER         := 0;
   g_print_line               VARCHAR2 (125);


-- +=================================================================================+
-- |                                                                                 |
-- |Name        : create_open_interface                                              |
-- |Description : This procedure will be used to insert the record into              |
-- |              xx_ce_999_interface table for reconcilaition                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE create_open_interface (
      x_errbuf                 OUT NOCOPY      VARCHAR2
    , x_retcode                OUT NOCOPY      NUMBER
    , p_ce_interface_seq       IN              NUMBER
    , p_stmt_header_id         IN              NUMBER
    , p_stmt_line_id           IN              NUMBER
    , p_bank_account_id        IN              NUMBER
    , p_trx_date               IN              DATE
    , p_currency_code          IN              VARCHAR2
    , p_amount                 IN              NUMBER
    , p_match_amount           IN              NUMBER
    , p_record_type            IN              VARCHAR2
    , p_provider_code          IN              VARCHAR2
    , p_bank_rec_id            IN              VARCHAR2
    , p_group_id               IN              VARCHAR2
    , p_trx_code_id_original   IN              NUMBER
    , p_trx_num_original       IN              VARCHAR2
    , p_trx_code_original      IN              VARCHAR2      -- Added by Rishabh as per R12 Retrofit Defect no.#25372
   )
   IS
   lc_trx_code      VARCHAR2(20);
   lc_trx_type      VARCHAR2(20);
   ln_amount        NUMBER;
   BEGIN
   fnd_file.put_line (fnd_file.LOG, ' ');
   fnd_file.put_line (fnd_file.LOG, 'Entered the Open Interface Creation');
   --------------------------------------------------------------------------------
--Added For the defect 14866
--------------------------------------------------------------------------------
   BEGIN
      SELECT TRX_CODE
        INTO lc_trx_code
        FROM ce_transaction_codes
       --WHERE transaction_code_id = p_trx_code_id_original; -- Commented by Rishabh as per R12 Retrofit Defect no.#25372
       WHERE trx_code = p_trx_code_original;  -- Added by Rishabh as per R12 Retrofit Defect no.25372
    EXCEPTION
      When NO_DATA_FOUND
      Then
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG, 'No data found in the Transaction Codes table for the transaction code:' || p_trx_code_original);
      When Others
      Then
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG, 'Error In getting transaction code:' || SQLERRM);
    END;
        fnd_file.put_line (fnd_file.LOG, 'Trx_code:' || lc_trx_code);
    BEGIN
        SELECT XFTV.target_value1
          INTO lc_trx_type
          FROM xx_fin_translatedefinition  XFTD
                ,xx_fin_translatevalues XFTV
        WHERE XFTV.translate_id = XFTD.translate_id
        AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND XFTV.source_value1 = lc_trx_code
        AND XFTD.translation_name = 'XX_CE_RECON_PAYMENT_TYPE'
        AND XFTV.enabled_flag = 'Y'
        AND XFTD.enabled_flag = 'Y';
        ln_amount := p_amount * -1;
        fnd_file.put_line (fnd_file.LOG, 'Amount Multiplied by * -1 : '|| ln_amount);
                fnd_file.put_line (fnd_file.LOG, 'Trx_type:' || lc_trx_type);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
          SELECT XFTV.target_value1
             INTO lc_trx_type
                FROM xx_fin_translatedefinition  XFTD
                    ,xx_fin_translatevalues XFTV
              WHERE XFTV.translate_id = XFTD.translate_id
              AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
              AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
              AND XFTV.source_value1 = 'EXCEPTION'
              AND XFTD.translation_name = 'XX_CE_RECON_PAYMENT_TYPE'
              AND XFTV.enabled_flag = 'Y'
              AND XFTD.enabled_flag = 'Y';
         ln_amount := p_amount;
         fnd_file.put_line (fnd_file.LOG, 'Amount NOT Multiplied by * -1 : '|| ln_amount);
                 fnd_file.put_line (fnd_file.LOG, 'Trx_type:' || lc_trx_type);
     END;
--------------------------------------------------------------------------------
-- End of the change fro defect 14866
--------------------------------------------------------------------------------
-- ------------------------------------------------
-- Insert the record into xx_ce_999_interface table
-- ------------------------------------------------
      INSERT INTO xx_ce_999_interface
                  (statement_header_id, statement_line_id, bank_account_id
                 , trx_number, trx_id, record_type
                 , trx_type, status, currency_code, amount, match_amount
                 , trx_date, processor_id, bank_rec_id, GROUP_ID
                 , bank_trx_code_id_original, bank_trx_number_original
                 , deposits_matched, creation_date, created_by
                 , last_update_date, last_updated_by
		 ,bank_trx_code_original -- Added by Rishabh as per R12 Retrofit Defect no.#25372
                  )
           VALUES (p_stmt_header_id, p_stmt_line_id, p_bank_account_id
                 , p_ce_interface_seq, p_ce_interface_seq, p_record_type
                 , lc_trx_type, 'FLOAT', p_currency_code, ln_amount, p_match_amount
                 , p_trx_date, p_provider_code, p_bank_rec_id, p_group_id
                 , p_trx_code_id_original, p_trx_num_original
                 , 'Y', SYSDATE, gn_user_id
                 , SYSDATE, gn_user_id
		 ,p_trx_code_original -- Addded by Rishabh as per R12 Retrofit Defect no.#25372
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE'
                              , 'XX_CE_AJB_CC_RECON_PKG.create_open_interface'
                               );
         fnd_message.set_token ('PROGRAM', 'CE AJB Creditcard Reconciliation');
         fnd_message.set_token ('SQLERROR', SQLERRM);
         x_errbuf := fnd_message.get;
         x_retcode := gn_error;
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
   END create_open_interface;


-- +=================================================================================+
-- | Name        : match_stmt_to_ajb_batches                                         |
-- | Description : This procedure matches credit card provider bank deposits         |
-- |               to AJB Reconciliation batches                                     |
-- |                                                                                 |
-- +=================================================================================+
   PROCEDURE match_stmt_to_ajb_batches (
      x_errbuf          OUT NOCOPY      VARCHAR2
    , x_retcode         OUT NOCOPY      NUMBER
    , p_provider_code   IN              VARCHAR2
    , p_from_date       IN              VARCHAR2
    , p_to_date         IN              VARCHAR2
   )
   IS
      CURSOR stmt_cc_lines_cur (
         lp_provider_code   VARCHAR2
       , lp_from_date       DATE
       , lp_to_date         DATE
      )
      IS
         SELECT   statement_header_id, bank_account_id, statement_number
                , statement_date, currency_code, attribute14, attribute15
                , statement_line_id, line_number, trx_date, trx_type, amount
                , status, trx_code_id, effective_date, bank_trx_number
                , bank_account_name, bank_account_num, trx_text
                , bank_deposit_line_descr, provider_code, customer_text
                , invoice_text, bank_account_text, reference_txt
                , ce_statement_lines, je_status_flag, accounting_date
                , gl_account_ccid, bank_account_type, inactive_date, trx_code
             FROM xx_ce_stmt_cc_deposits_v
            WHERE 1 = 1
              AND NVL (trx_code, '0') != '001'
              AND provider_code = NVL (lp_provider_code, provider_code)
              AND statement_date BETWEEN NVL (lp_from_date, statement_date)
                                     AND NVL (lp_to_date, statement_date)
              AND NVL (status, 'UNRECONCILED') = 'UNRECONCILED'
              AND NVL (attribute15, 'X') != ('PROCESSED-E1310')
         ORDER BY bank_account_num
                , statement_date
                , statement_header_id
                , statement_number
                , line_number;
      CURSOR lock_statement (p_statement_header_id IN NUMBER)
      IS
         SELECT     1
               FROM ce_statement_headers
              WHERE statement_header_id = p_statement_header_id
         FOR UPDATE;
      CURSOR ajb_single_match_cur (
         p_provider   IN   VARCHAR2
       , p_trx_date   IN   DATE
       , p_amount     IN   NUMBER
      )
      IS
         SELECT   processor_id, bank_rec_id, recon_date
                , SUM (net_amount) net_amount
             FROM xx_ce_ajb_net_amounts_v xnet
            WHERE 1 = 1
              AND processor_id = p_provider                       --Defect 7926.
              AND recon_date <= p_trx_date
              AND status_1310 = 'NEW'                             -- Added for Defect 2610
             /* AND NOT EXISTS (
                    SELECT bank_rec_id
                      FROM xx_ce_999_interface
                     WHERE bank_rec_id = xnet.bank_rec_id
                       AND processor_id = xnet.processor_id)*/   -- Commented for Defect 2610
         GROUP BY processor_id, bank_rec_id, recon_date
           HAVING SUM (net_amount) = p_amount;
      CURSOR ajb_multi_match_cur (p_provider IN VARCHAR2, p_trx_date IN DATE)
      IS
         SELECT   processor_id, bank_rec_id, recon_date
                , SUM (net_amount) net_amount
             FROM xx_ce_ajb_net_amounts_v xnet
            WHERE 1 = 1
              AND recon_date <= p_trx_date
              AND processor_id = p_provider
              AND status_1310 = 'NEW'                             -- Added for Defect 2610
             /* AND NOT EXISTS (
                    SELECT bank_rec_id
                      FROM xx_ce_999_interface
                     WHERE bank_rec_id = xnet.bank_rec_id
                       AND processor_id = xnet.processor_id)*/   -- Commented for Defect 2610
         GROUP BY processor_id, bank_rec_id, recon_date
         ORDER BY recon_date DESC;
      CURSOR lcu_get_001_trx_code (
         p_bank_account   IN   ce_bank_Accounts.bank_account_id%TYPE        --- Modified as per R12 Retorfit by Rishabh Chhajer
      )
      IS
         SELECT transaction_code_id
	       ,trx_code --   Addded by Rishabh as per R12 Retrofit Defect no.#25372 
           FROM ce_transaction_codes
          WHERE bank_account_id = p_bank_account
            AND trx_code = '001'
            AND SYSDATE BETWEEN NVL (start_date, SYSDATE)
                            AND NVL (end_date, SYSDATE + 1);
      stmt_cc_lines_rec    stmt_cc_lines_cur%ROWTYPE;
      multi_match_rec      ajb_multi_match_cur%ROWTYPE;
      TYPE stmt_cc_tab IS TABLE OF stmt_cc_lines_cur%ROWTYPE
         INDEX BY BINARY_INTEGER;
      TYPE multi_match_tab IS TABLE OF ajb_multi_match_cur%ROWTYPE
         INDEX BY BINARY_INTEGER;
      ccdeptab             stmt_cc_tab;
      multimatchtab        multi_match_tab;
      ln_id_count          NUMBER;
      ln_multi_id_count    NUMBER;
      lc_processor_id      xx_ce_ajb998.processor_id%TYPE;
      lc_bank_rec_id       xx_ce_ajb998.bank_rec_id%TYPE;
      ld_recon_date        DATE;
      ln_net_amount        NUMBER;
      x_err_buf            VARCHAR2 (2000);
      x_ret_code           NUMBER;
      ln_trx_id            NUMBER;
      lc_savepoint         VARCHAR2 (200);
      lc_multi_savepoint   VARCHAR2 (200);
      ln_001_trx_code_id   NUMBER;
      lc_001_trx_code      VARCHAR2(30);			-- Addded by Rishabh as per R12 Retrofit Defect no.#25372
      lc_location          VARCHAR2 (200);
      ln_multi_total       NUMBER;
      lc_matched_status    VARCHAR2 (1)                     := 'N';
      lc_status            VARCHAR2 (30);
      ld_from_date         DATE;
      ld_to_date           DATE;
      lc_stmtsavepoint     VARCHAR2 (50);
      ln_rows_updated      NUMBER;
   BEGIN
      IF p_from_date IS NOT NULL
      THEN
         ld_from_date := fnd_conc_date.string_to_date (p_from_date);
      END IF;
      IF p_to_date IS NOT NULL
      THEN
         ld_to_date := fnd_conc_date.string_to_date (p_to_date);
      END IF;
-- ------------------------------------------------
-- Set the Concurrent program Output header display
-- ------------------------------------------------
      xx_ce_cc_common_pkg.od_message ('O', ' ');
      xx_ce_cc_common_pkg.od_message ('O'
                ,    RPAD (' ', 30, ' ')
                  || ' Cash Management AJB Statement Matching '
                  || RPAD (' ', 30, ' ')
                 );
      xx_ce_cc_common_pkg.od_message ('O', ' ');
      xx_ce_cc_common_pkg.od_message ('O'
                ,    'Request ID : '
                  || gn_request_id
                  || RPAD (' ', 60, ' ')
                  || 'Request Date : '
                  || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH:MM:SS')
                 );
      xx_ce_cc_common_pkg.od_message ('O', RPAD ('=', 120, '='));
      xx_ce_cc_common_pkg.od_message ('O', ' ');
      xx_ce_cc_common_pkg.od_message ('O'
                ,    RPAD ('Bank Account# ', 30, ' ')
                  || ' '
                  || RPAD ('Statement Number', 30, ' ')
                  || ' '
                  || RPAD ('Line #', 10, ' ')
                  || ' '
                  || RPAD ('Processor', 10, ' ')
                  || ' '
                  || 'Description'
                 );
      xx_ce_cc_common_pkg.od_message ('O'
                ,    RPAD ('-', 30, '-')
                  || ' '
                  || RPAD ('-', 30, '-')
                  || ' '
                  || RPAD ('-', 10, '-')
                  || ' '
                  || RPAD ('-', 10, '-')
                  || ' '
                  || RPAD ('-', (120 - 84), '-')
                 );
      xx_ce_cc_common_pkg.od_message ('M'
                ,    'Parameters - Provider:'
                  || NVL (p_provider_code, 'ALL')
                  || '   From:'
                  || NVL (p_from_date, 'Not Specified')
                  || '    Through:'
                  || NVL (p_to_date, 'Not Specified.')
                 );
      OPEN stmt_cc_lines_cur (p_provider_code, ld_from_date, ld_to_date);
      LOOP
         FETCH stmt_cc_lines_cur
         BULK COLLECT INTO ccdeptab LIMIT 100;
         EXIT WHEN ccdeptab.COUNT = 0;
         ln_id_count := ln_id_count + ccdeptab.COUNT;
         xx_ce_cc_common_pkg.od_message ('M', g_print_line);
         xx_ce_cc_common_pkg.od_message ('M'
                   ,    'Start:'
                     || ccdeptab.COUNT
                     || ' Credit Card Deposits identified.'
                    );
         IF ccdeptab.COUNT > 0
         THEN
            FOR i IN ccdeptab.FIRST .. ccdeptab.LAST
            LOOP
               BEGIN
                  lc_matched_status := 'N';
                  xx_ce_cc_common_pkg.od_message ('M', g_print_line);
                  xx_ce_cc_common_pkg.od_message ('M'
                            ,    'Bank Account:'
                              || ccdeptab (i).bank_account_num
                              || ' /Statement#:'
                              || ccdeptab (i).statement_number
                              || ' /Line:'
                              || ccdeptab (i).line_number
                              || ' /Date:'
                              || ccdeptab (i).trx_date
                              || ' /Provider:'
                              || ccdeptab (i).provider_code
                              || ' /Amount:'
                              || ccdeptab (i).currency_code
                              || ' '
                              || ccdeptab (i).amount
                             );
                  lc_location := 'Before Locking Statement';
                  SAVEPOINT lc_stmtsavepoint;
                  OPEN lock_statement (ccdeptab (i).statement_header_id);
                  BEGIN                             --Single match process start
                     lc_location :=
                                'Before Set Savepoint for Single match process';
                     lc_savepoint :=
                           ccdeptab (i).provider_code
                        || '-'
                        || ccdeptab (i).statement_header_id
                        || '-'
                        || ccdeptab (i).statement_line_id;
                     SAVEPOINT lc_savepoint;
                     --xx_ce_cc_common_pkg.od_message('M', 'Savepoint:' || lc_savepoint);
                     lc_location := 'After Set Savepoint';
                     OPEN ajb_single_match_cur (ccdeptab (i).provider_code
                                              , ccdeptab (i).trx_date
                                              , ccdeptab (i).amount
                                               );
                     FETCH ajb_single_match_cur
                      INTO lc_processor_id, lc_bank_rec_id, ld_recon_date
                         , ln_net_amount;
                     IF ajb_single_match_cur%FOUND
                     THEN
                        lc_location := 'Single match found';
                        xx_ce_cc_common_pkg.od_message
                           ('M'
                          ,    'Matched AJB Bank Rec ID:'
                            || lc_bank_rec_id
                            || ' Date:'
                            || ld_recon_date
                            || ' for Provider '
                            || lc_processor_id
                            || '. Interfacing Match Data to Auto-Recon 999 Interface.'
                           );
-- ------------------------------------------------
-- Get the Nexval Value
-- ------------------------------------------------
                        SELECT xx_ce_999_interface_s.NEXTVAL
                          INTO ln_trx_id
                          FROM DUAL;
                        x_errbuf := NULL;
                        x_retcode := NULL;
                        lc_location := 'Create 999 Interface for Single match';
                        create_open_interface (x_errbuf
                                             , x_retcode
                                             , ln_trx_id
                                             , ccdeptab (i).statement_header_id
                                             , ccdeptab (i).statement_line_id
                                             , ccdeptab (i).bank_account_id
                                             , ccdeptab (i).trx_date
                                             , ccdeptab (i).currency_code
                                             , ccdeptab (i).amount
                                             , ccdeptab (i).amount
                                             , 'AJB'
                                             , lc_processor_id
                                             , lc_bank_rec_id
                                             , ccdeptab (i).statement_line_id
                                             , ccdeptab (i).trx_code_id
                                             , ccdeptab (i).bank_trx_number
					     , ccdeptab (i).trx_code-- Added by Rishabh as per R12 Retrofit defect no.#25372
                                              );
/* Start of changes for update statement for Defect 2610*/

                        ln_rows_updated := 0;
                        UPDATE /*+ INDEX(XCA8 XX_CE_AJB998_N13)*/ xxfin.xx_ce_ajb998 xca8
                        SET xca8.status_1310 = 'PROCESSED'
                          , last_update_date = SYSDATE
                          , last_updated_by = gn_user_id
                        WHERE xca8.bank_rec_id = lc_bank_rec_id
                        AND xca8.processor_id =  lc_processor_id
                        AND xca8.recon_date <= ccdeptab (i).trx_date
                        AND xca8.org_id = gn_org_id
                        AND xca8.status_1310 = 'NEW'
                        AND xca8.status IN ('PREPROCESSED', 'MATCHED_AR')
                        AND TRIM (xca8.rej_reason_code) IS NULL
                        AND xca8.recon_header_id IS NOT NULL;
                        ln_rows_updated := SQL%ROWCOUNT;

                        fnd_file.put_line (fnd_file.log,ln_rows_updated || ' rows updated (Single-match) in xx_ce_ajb998, processor_id '
                                                                        ||lc_processor_id
                                                                        || ' , bank rec id '
                                                                        ||lc_bank_rec_id);

                        ln_rows_updated := 0;
                        UPDATE xxfin.xx_ce_ajb996 xca6
                        SET xca6.status_1310 = 'PROCESSED'
                          , last_update_date = SYSDATE
                          , last_updated_by = gn_user_id
                        WHERE xca6.bank_rec_id = lc_bank_rec_id
                        AND xca6.processor_id =  lc_processor_id
                        AND xca6.recon_date <= ccdeptab (i).trx_date
                        AND xca6.org_id = gn_org_id
                        AND xca6.status_1310 = 'NEW'
                        AND xca6.status IN ('PREPROCESSED', 'MATCHED_AR');
                       /* AND EXISTS (                      -- TEST FOR CHARGEBACK TYPE AND PROVIDER
                                     SELECT 1
                                     FROM xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
                                     WHERE xftv.translate_id = xftd.translate_id
                                       AND xftd.translation_name = 'OD_CE_AJB_CHBK_CODES'
                                       AND NVL (xftv.enabled_flag, 'N') = 'Y'
                                       AND NVL (xca6.sdate, SYSDATE) BETWEEN xftv.start_date_active
                                                                         AND NVL (xftv.end_date_active
                                                                                , SYSDATE + 1
                                                                                 )
                                       AND ((processor_id = xftv.source_value1
                                             AND (xftv.target_value1 IS NULL
                                                  OR chbk_action_code = xftv.target_value1
                                                 )
                                             AND (xftv.target_value2 IS NULL
                                                  OR chbk_alpha_code = xftv.target_value2
                                                 )
                                             AND (xftv.target_value3 IS NULL
                                                  OR chbk_numeric_code = xftv.target_value3
                                                 )
                                            ))
                                    )*/   --- commented for E2079, CR 898
                        ln_rows_updated := SQL%ROWCOUNT;

                        fnd_file.put_line (fnd_file.log,ln_rows_updated || ' rows updated (Single-match) in xx_ce_ajb996, processor_id '
                                                                        ||lc_processor_id
                                                                        || ', bank rec id '
                                                                        ||lc_bank_rec_id);


                       COMMIT;
/* End of changes for update statement for Defect 2610*/
                        IF x_errbuf IS NULL
                           AND x_ret_code IS NULL
                        THEN
                           BEGIN
-- ------------------------------------------------
-- Get the Trx Code Id fo '001'
-- ------------------------------------------------
                              ln_001_trx_code_id := NULL;
			      lc_001_trx_code:= NULL;	-- Added by Rishabh as per R12 Retrofit defect no.#25372
                              OPEN lcu_get_001_trx_code
                                                   (ccdeptab (i).bank_account_id
                                                   );
                              FETCH lcu_get_001_trx_code
                               INTO ln_001_trx_code_id
			           ,lc_001_trx_code;		-- Added by Rishabh as per R12 Retrofit defect no.#25372
                              CLOSE lcu_get_001_trx_code;
-- -------------------------------------------
-- Check wheather Trx Code '001' is set up or not
-- -------------------------------------------
                              IF lc_001_trx_code IS NOT NULL
                              THEN
                                 UPDATE ce_statement_lines
                                    SET attribute9 = ccdeptab (i).trx_code_id
                                      , attribute10 = ccdeptab (i).bank_trx_number
                                      , trx_code_id = ln_001_trx_code_id
                                      , bank_trx_number = ln_trx_id
                                      , je_status_flag = NULL
                                      , last_update_date = SYSDATE
                                      , last_updated_by = gn_user_id
				      , trx_code= lc_001_trx_code	-- Added by Rishabh as per R12 Retrofit defect no.#25372
                                  WHERE statement_line_id = ccdeptab (i).statement_line_id
                                    AND statement_header_id = ccdeptab (i).statement_header_id;
                              ELSE
                                 xx_ce_cc_common_pkg.od_message
                                    ('M'
                                   ,    'Trx Code is not setup for bank account:'
                                     || ccdeptab (i).bank_account_num
                                    );
                                 x_errbuf :=
                                       'Trx Code is not setup for bank account:'
                                    || ccdeptab (i).bank_account_num;
                              END IF;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 x_errbuf := SQLERRM;
                                 x_retcode := 2;
                           END;
                        END IF;
                        IF x_errbuf IS NOT NULL
                           OR x_ret_code IS NOT NULL
                        THEN
                           --Raise error and rollback.
                           xx_ce_cc_common_pkg.od_message ('M', '* * * * Error * * * *');
                           xx_ce_cc_common_pkg.od_message ('M'
                                     , x_errbuf || ' : RetCode:' || x_ret_code
                                      );
                           xx_ce_cc_common_pkg.od_message ('M', ' ');
                           ROLLBACK TO lc_savepoint;
                           lc_matched_status := 'N';
                        ELSE
                           lc_matched_status := 'Y';
                        END IF;
                     ELSE
                        xx_ce_cc_common_pkg.od_message ('M', 'Single Recon file match not found.');
                        lc_matched_status := 'N';
                     END IF;
                     CLOSE ajb_single_match_cur;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        xx_ce_cc_common_pkg.od_message
                              ('M'
                             ,    'Exception in single recon file match after '
                               || lc_location
                              );
                  END;                              -- End Single match process.
-------------------------------------------------------------------
 --                   Multi Match Process                        --
-------------------------------------------------------------------
                  IF lc_matched_status = 'N'
                  THEN
                     BEGIN                         --Multi-Match process start.
                        lc_location :=
                                 'Before Set Savepoint for Multi-match routine';
                        lc_multi_savepoint :=
                              ccdeptab (i).provider_code
                           || '-'
                           || ccdeptab (i).statement_header_id
                           || '-'
                           || ccdeptab (i).statement_line_id
                           || '-M';
                        SAVEPOINT lc_multi_savepoint;
                        --xx_ce_cc_common_pkg.od_message('M', 'Savepoint:' || lc_multi_savepoint);
                        lc_location := 'After Set Savepoint';
                        ln_multi_total := 0;
                        ln_multi_id_count := 0;
                        lc_location := 'Before Open Ajb Multi Match Cur';
                        OPEN ajb_multi_match_cur (ccdeptab (i).provider_code
                                                , ccdeptab (i).trx_date
                                                 );
                        LOOP
                           lc_location := 'Inside Ajb Multi Match Cur loop';
                           FETCH ajb_multi_match_cur
                           BULK COLLECT INTO multimatchtab;
                           -- If only one batch is found, then we can ignore since
                           -- it was not matched in single match procedure above.
                           -- Process only when multiple batches are available to match.
                           EXIT WHEN multimatchtab.COUNT < 2;
                           IF multimatchtab.COUNT > 1
                           THEN                        --Multi-Match Cur%Found.
                              lc_location :=
                                       'Inside Ajb Multi Match After Count > 0';
                              xx_ce_cc_common_pkg.od_message ('M'
                                        ,    'Found '
                                          || multimatchtab.COUNT
                                          || ' batch(es) for Provider'
                                         );
                              FOR m IN multimatchtab.FIRST .. multimatchtab.LAST
                              LOOP
                                 lc_location := 'Inside Deposits loop ' || m;
                                 ln_multi_total :=
                                      ln_multi_total
                                    + multimatchtab (m).net_amount;
                                 ln_multi_id_count := ln_multi_id_count + 1;
                                 EXIT WHEN ln_multi_id_count > 5;  --changed from 7 to 5 for E2079 as compared to E1310.
                                 --Check if the total matches statement deposit
                                 IF ln_multi_total = ccdeptab (i).amount
                                 THEN
                                    lc_matched_status := 'Y';
                                    xx_ce_cc_common_pkg.od_message ('M'
                                              ,    'Match found with '
                                                || ln_multi_id_count
                                                || ' batch(es)!'
                                               );
                                    x_errbuf := NULL;
                                    x_retcode := NULL;
                                    -- Pass the batches that matched to 999 Interface.
                                    FOR k IN 1 .. m
                                    LOOP
                                 -- ------------------------------------------------
-- Get the Nexval Value
-- ------------------------------------------------
                                       SELECT xx_ce_999_interface_s.NEXTVAL
                                         INTO ln_trx_id
                                         FROM DUAL;
                                       lc_location :=
                                             'Create 999 Interface for Multi match batch '
                                          || k
                                          || '.';
                                       create_open_interface
                                               (x_errbuf
                                              , x_retcode
                                              , ln_trx_id
                                              , ccdeptab (i).statement_header_id
                                              , ccdeptab (i).statement_line_id
                                              , ccdeptab (i).bank_account_id
                                              , ccdeptab (i).trx_date
                                              , ccdeptab (i).currency_code
                                              , ccdeptab (i).amount
                                              , multimatchtab (k).net_amount
                                              , 'AJB'
                                              , multimatchtab (k).processor_id
                                              , multimatchtab (k).bank_rec_id
                                              , ccdeptab (i).statement_line_id
                                              , ccdeptab (i).trx_code_id
                                              , ccdeptab (i).bank_trx_number
    				              , ccdeptab (i).trx_code-- Added by Rishabh as per R12 Retrofit defect no.#25372
                                               );

/* Start of changes for update statement for Defect 2610*/

                                       ln_rows_updated := 0;
                                       UPDATE /*+ INDEX(XCA8 XX_CE_AJB998_N13)*/ xxfin.xx_ce_ajb998 xca8
                                          SET xca8.status_1310 = 'PROCESSED'
                                            , last_update_date = SYSDATE
                                            , last_updated_by = gn_user_id
                                        --WHERE xca8.bank_rec_id = lc_bank_rec_id  --commented for defect 9249
                                        --  AND xca8.processor_id =  lc_processor_id  --commented for defect 9249
                                        WHERE xca8.bank_rec_id = multimatchtab (k).bank_rec_id  --added for defect 9249
                                          AND xca8.processor_id = multimatchtab (k).processor_id  --added for defect 9249
                                          AND xca8.recon_date <= ccdeptab (i).trx_date
                                          AND xca8.org_id = gn_org_id
                                          AND xca8.status_1310 = 'NEW'
                                          AND xca8.status IN ('PREPROCESSED', 'MATCHED_AR')
                                          AND TRIM (xca8.rej_reason_code) IS NULL
                                          AND xca8.recon_header_id IS NOT NULL;
                                          ln_rows_updated := SQL%ROWCOUNT;

                                       --added for defect 9249
                                       fnd_file.put_line (fnd_file.log,ln_rows_updated || ' rows updated (Multi-match) in xx_ce_ajb998, processor_id '
                                                                                       ||multimatchtab (k).processor_id
                                                                                       || ', bank rec id '
                                                                                       ||multimatchtab (k).bank_rec_id);

                                       ln_rows_updated := 0;
                                       UPDATE xxfin.xx_ce_ajb996 xca6
                                          SET xca6.status_1310 = 'PROCESSED'
                                            , last_update_date = SYSDATE
                                            , last_updated_by = gn_user_id
                                        --WHERE xca6.bank_rec_id = lc_bank_rec_id  --commented for defect 9249
                                        --  AND xca6.processor_id =  lc_processor_id  --commented for defect 9249
                                        WHERE xca6.bank_rec_id = multimatchtab (k).bank_rec_id  --added for defect 9249
                                          AND xca6.processor_id =  multimatchtab (k).processor_id  --added for defect 9249
                                          AND xca6.recon_date <= ccdeptab (i).trx_date
                                          AND xca6.org_id = gn_org_id
                                          AND xca6.status_1310 = 'NEW'
                                          AND xca6.status IN ('PREPROCESSED', 'MATCHED_AR');
                                          /*AND EXISTS (-- TEST FOR CHARGEBACK TYPE AND PROVIDER
                                                       SELECT 1
                                                         FROM xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
                                                        WHERE xftv.translate_id = xftd.translate_id
                                                          AND xftd.translation_name = 'OD_CE_AJB_CHBK_CODES'
                                                          AND NVL (xftv.enabled_flag, 'N') = 'Y'
                                                          AND NVL (xca6.sdate, SYSDATE) BETWEEN xftv.start_date_active
                                                                         AND NVL (xftv.end_date_active
                                                                                , SYSDATE + 1
                                                                                 )
                                                          AND ((processor_id = xftv.source_value1
                                                          AND (xftv.target_value1 IS NULL
                                                               OR chbk_action_code = xftv.target_value1
                                                               )
                                                          AND (xftv.target_value2 IS NULL
                                                               OR chbk_alpha_code = xftv.target_value2
                                                              )
                                                          AND (xftv.target_value3 IS NULL
                                                               OR chbk_numeric_code = xftv.target_value3
                                                              )
                                                              ))
                                                    )*/   --- commented for E2079, CR 898
                                       ln_rows_updated := SQL%ROWCOUNT;
/* End of changes for update statement for Defect 2610*/

                                       --added for defect 9249
                                       fnd_file.put_line (fnd_file.log,ln_rows_updated || ' rows updated (Multi-match) in xx_ce_ajb996, processor_id '
                                                                                       ||multimatchtab (k).processor_id
                                                                                       || ', bank rec id '
                                                                                       ||multimatchtab (k).bank_rec_id);

                                       xx_ce_cc_common_pkg.od_message
                                          ('M'
                                         ,    'Transfer to 999 Interface: Batch '
                                           || k
                                           || ' of '
                                           || m
                                           || ') : Recon ID:'
                                           || multimatchtab (k).bank_rec_id
                                           || ' Batch Amount '
                                           || multimatchtab (k).net_amount
                                           || '/ Total for '
                                           || ln_multi_id_count
                                           || ' batch(es):'
                                           || ln_multi_total
                                          );
                                    END LOOP;                      --End j loop.
                                    IF x_errbuf IS NULL
                                       AND x_ret_code IS NULL
                                    THEN
                                       BEGIN
                     -- ------------------------------------------------
-- Get the Trx Code Id fo '001'
-- ------------------------------------------------
                                          ln_001_trx_code_id := NULL;
					  lc_001_trx_code:= NULL;			-- Added by Rishabh as per R12 Retrofit defect no.25372
                                          OPEN lcu_get_001_trx_code
                                                   (ccdeptab (i).bank_account_id
                                                   );
                                          FETCH lcu_get_001_trx_code
                                           INTO ln_001_trx_code_id
					       ,lc_001_trx_code;			-- Added by Rishabh as per R12 Retrofit defect no.25372
                                          CLOSE lcu_get_001_trx_code;
-- -------------------------------------------
-- Check wheather Trx Code '001' is set up or not
-- -------------------------------------------
                                          IF lc_001_trx_code IS NOT NULL
                                          THEN
                                             UPDATE ce_statement_lines
                                                SET attribute9 = ccdeptab (i).trx_code_id
                                                  , attribute10 = ccdeptab (i).bank_trx_number
                                                  , trx_code_id = ln_001_trx_code_id
                                                  , bank_trx_number = ln_trx_id
                                                  , je_status_flag = NULL
                                                  , last_update_date = SYSDATE
                                                  , last_updated_by = gn_user_id
						  , trx_code= lc_001_trx_code	-- Added by Rishabh as per R12 Retrofit defect no.#25372
                                              WHERE statement_line_id = ccdeptab (i).statement_line_id
                                                AND statement_header_id = ccdeptab (i).statement_header_id;
                                          ELSE
                                             xx_ce_cc_common_pkg.od_message
                                                ('M'
                                               ,    'Trx Code is not setup for bank account:'
                                                 || ccdeptab (i).bank_account_num
                                                );
                                             x_errbuf :=
                                                   'Trx Code is not setup for bank account:'
                                                || ccdeptab (i).bank_account_num;
                                          END IF;
                                       EXCEPTION
                                          WHEN OTHERS
                                          THEN
                                             x_errbuf := SQLERRM;
                                             x_retcode := 2;
                                       END;
                                    END IF;
                                    IF x_errbuf IS NOT NULL
                                       OR x_ret_code IS NOT NULL
                                    THEN
                                       --Raise error and rollback.
                                       xx_ce_cc_common_pkg.od_message ('M'
                                                 , '* * * * Error * * * *');
                                       xx_ce_cc_common_pkg.od_message ('M', x_errbuf);
                                       xx_ce_cc_common_pkg.od_message ('M', ' ');
                                       ROLLBACK TO lc_multi_savepoint;
                                    ELSE
                                       lc_matched_status := 'Y';
                                    END IF;
                                    EXIT;   --Exit multi-loop since match found.
-- Remove Else  after testing
------------------------------------------------------
                                 ELSE
                                    -- Statement not matched.
                                    lc_matched_status := 'N';
                                    FOR l IN 1 .. m
                                    LOOP
                                       xx_ce_cc_common_pkg.od_message
                                               ('M'
                                              ,    'Unmatched: Batch '
                                                || l
                                                || ' of '
                                                || m
                                                || ') : Recon ID:'
                                                || multimatchtab (l).bank_rec_id
                                                || ' Batch Amount '
                                                || multimatchtab (l).net_amount
                                                || ' total for '
                                                || ln_multi_id_count
                                                || ' batches:'
                                                || ln_multi_total
                                               );
                                    END LOOP;                      --End j loop.
                                    xx_ce_cc_common_pkg.od_message ('M'
                                              ,    'Match not found with '
                                                || ln_multi_id_count
                                                || ' batch(es)!'
                                               );
                                 END IF;
                              END LOOP;        --Multimatchtab first..last loop.
                              IF ln_multi_id_count = 0
                              THEN
                                 xx_ce_cc_common_pkg.od_message ('M'
                                           , 'No Matching Recon batches found!'
                                            );
                              END IF;
                           END IF;                    --Multimatchtab count > 0.
                        END LOOP;                        ---Multimatch cur loop.
                        CLOSE ajb_multi_match_cur;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           xx_ce_cc_common_pkg.od_message
                              ('M'
                             ,    'Exception in Multiple recon file match after '
                               || lc_location
                              );
                           xx_ce_cc_common_pkg.od_message ('M', SQLCODE || ':' || SQLERRM);
                           ROLLBACK TO lc_multi_savepoint;
                     END;
                  END IF;                               --lc_matched_status='N'.
                  IF lc_matched_status = 'Y'
                  THEN
                     lc_status := 'Matched';
                  ELSE
                     lc_status := 'Not Matched';
                  END IF;
                  CLOSE lock_statement;
                  xx_ce_cc_common_pkg.od_message ('O'
                            ,    RPAD (NVL (ccdeptab (i).bank_account_num, ' ')
                                     , 30
                                     , ' '
                                      )
                              || ' '
                              || RPAD (NVL (ccdeptab (i).statement_number, ' ')
                                     , 30
                                     , ' '
                                      )
                              || ' '
                              || LPAD (NVL (TO_CHAR (ccdeptab (i).line_number)
                                          , ' '
                                           )
                                     , 10
                                     , ' '
                                      )
                              || ' '
                              || RPAD (NVL (ccdeptab (i).provider_code, ' ')
                                     , 10
                                     , ' '
                                      )
                              || ' '
                              || lc_status
                             );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     IF SQLCODE = -54
                     THEN
                        ROLLBACK TO lc_stmtsavepoint;
                        xx_ce_cc_common_pkg.od_message
                           ('M'
                          , 'Statement is locked and is being processed by other request/user'
                           );
                        xx_ce_cc_common_pkg.od_message
                                ('O'
                               ,    RPAD (NVL (ccdeptab (i).bank_account_num
                                             , ' '
                                              )
                                        , 30
                                        , ' '
                                         )
                                 || ' '
                                 || RPAD (NVL (ccdeptab (i).statement_number
                                             , ' '
                                              )
                                        , 30
                                        , ' '
                                         )
                                 || ' '
                                 || LPAD
                                        (NVL (TO_CHAR (ccdeptab (i).line_number)
                                            , ' '
                                             )
                                       , 10
                                       , ' '
                                        )
                                 || ' '
                                 || RPAD (NVL (ccdeptab (i).provider_code, ' ')
                                        , 10
                                        , ' '
                                         )
                                 || ' '
                                 || 'Locked by other User/Process'
                                );
                     ELSE
                        ROLLBACK TO lc_stmtsavepoint;
                        xx_ce_cc_common_pkg.od_message ('M'
                                  , 'Error/Warning:' || SQLCODE || '-'
                                    || SQLERRM
                                   );
                        xx_ce_cc_common_pkg.od_message
                                ('O'
                               ,    RPAD (NVL (ccdeptab (i).bank_account_num
                                             , ' '
                                              )
                                        , 30
                                        , ' '
                                         )
                                 || ' '
                                 || RPAD (NVL (ccdeptab (i).statement_number
                                             , ' '
                                              )
                                        , 30
                                        , ' '
                                         )
                                 || ' '
                                 || LPAD
                                        (NVL (TO_CHAR (ccdeptab (i).line_number)
                                            , ' '
                                             )
                                       , 10
                                       , ' '
                                        )
                                 || ' '
                                 || RPAD (NVL (ccdeptab (i).provider_code, ' ')
                                        , 10
                                        , ' '
                                         )
                                 || ' '
                                 || '* * * * Error * * * *'
                                );
                     END IF;
                     IF lock_statement%ISOPEN
                     THEN
                        CLOSE lock_statement;
                     END IF;
               END;
            END LOOP;                               -- ccdeptab first..last loop
            xx_ce_cc_common_pkg.od_message ('M', g_print_line);
         END IF;                                   -- stmt_cc_dep_tab.COUNT > 0.
      END LOOP;                                        --stmt_cc_lines_cur loop.
   END match_stmt_to_ajb_batches;

END xx_ce_cc_stmt_match_pkg;
/

