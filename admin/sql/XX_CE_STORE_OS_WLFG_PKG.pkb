create or replace PACKAGE BODY      XX_CE_STORE_OS_WLFG_PKG
AS
/*
-- +=================================================================================+
-- |                       Office Depot                                                                                                                           |
-- |                                                                                                                                                      |
-- +=================================================================================+
-- | Name       : XX_CE_STORE_OS_WLFG_PKG.pkb                                        |
-- | Description: OD Cash Management Store Over/Short and Cash Sweep Extension                          |
-- |                                            for Wells FargoBank                                                                                                                                                                     |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version  Date         Authors            Remarks                                 |
-- |=======  ===========  ===============    ============================            |
-- |1.0      30-Mar-2020  Amit Kumar        Initial version                                                                                      |
-- |                                                                                 |
-- |=================================================================================|
-- | Name        : OD: CM Store Over/Short and Cash Concentration WF                 |
-- | Description : This procedure will be used to process the                        |
-- |               OD Cash Management Store Deposit Over/Short                       |
-- |               and Cash Concentration extention for Wells Fargo Bank                                           |
-- |(E1318 Copy Modified )                                                                                                                                                                                                                           |
-- |                                                                                                                                                                                                                                                                                                                          |
-- | Exection File Name: XX_CE_STORE_OS_WLFG_PKG.STORE_OS_CC_MAIN                                                                       |
-- |                                                                                                                                                                                                                                                                                                                          |
-- |                                                                                 |
-- | Parameters  : None                                                              |
-- |                                                                                 |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- |                                                                                 |
-- +=================================================================================+
*/

   gc_line   VARCHAR2 (100)       := '------------------------------------------------------------' ;

   gc_trans_name   VARCHAR2 (50)  := 'XX_CM_E1319_STORE_OS_CC';

   FUNCTION pf_derive_lob (pfv_location IN VARCHAR2, pfv_cost_center IN VARCHAR2)
      RETURN VARCHAR2
   IS
      pfv_lob             gl_code_combinations.segment7%TYPE;
      pfv_error_message   VARCHAR2 (200);
   BEGIN
      xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc (pfv_location
                                                         , pfv_cost_center
                                                         , pfv_lob
                                                         , pfv_error_message
                                                          );

      IF pfv_error_message IS NOT NULL
      THEN
         pfv_lob := -1;
      END IF;

      RETURN (NVL (pfv_lob, -1));
   END;

   PROCEDURE store_os_cc_main (
      x_errbuf    OUT NOCOPY   VARCHAR2
    , x_retcode   OUT NOCOPY   NUMBER
                , p_corpbank_acct_id IN NUMBER
   )
   AS
      n1                             NUMBER;
      gn_set_of_bks_id               NUMBER
                                      := fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
      gn_org_id                      NUMBER     := fnd_profile.VALUE ('ORG_ID');
      lc_aba_key                     VARCHAR2 (006);
      ln_bank_account_id             NUMBER;
      lc_bank_account_num            ce_bank_accounts.bank_account_num%TYPE;
      ln_ccid                        NUMBER;
      gn_coa_id                      NUMBER;
      lc_csl_bank_account_text       ce_statement_lines.bank_account_text%TYPE;
      lc_csl_bank_trx_number         ce_statement_lines.bank_trx_number%TYPE;
      lc_csl_customer_text           ce_statement_lines.customer_text%TYPE;
      lc_csl_invoice_text            ce_statement_lines.invoice_text%TYPE;
      ln_csl_deposit_amt             ce_statement_lines.amount%TYPE;
      ln_csl_statement_line_id       ce_statement_lines.statement_line_id%TYPE;
      ln_csl_statement_header_id     ce_statement_lines.statement_header_id%TYPE;
      ln_csl_trx_code_id             ce_statement_lines.trx_code_id%TYPE;
      ln_csl_trx_code                ce_statement_lines.trx_code%TYPE;
      ln_csl_trx_code_001_id         NUMBER;
      ln_csl_trx_code_001            ce_statement_lines.trx_code%TYPE;
      ld_csl_trx_date                ce_statement_lines.trx_date%TYPE;
      lc_currency_code               ce_bank_accounts.currency_code%TYPE;
      ln_deposit_bank_difference     NUMBER;
      lc_error_loc                   VARCHAR2 (60);
      lc_error_msg                   VARCHAR2 (2500);
      le_exception_999               EXCEPTION;
      le_exception_bad_store         EXCEPTION;
      le_exception_gl_call           EXCEPTION;
      le_exception_store_accounts    EXCEPTION;
      le_exception_store_receipts    EXCEPTION;
      le_exception_trx_code          EXCEPTION;
      le_exception_no_match          EXCEPTION;
      le_exception_translate         EXCEPTION;
      ln_group_id                    NUMBER;
      lc_print_line                  VARCHAR2 (200);
      ln_loc_id                      NUMBER;
      lc_loc_4                       VARCHAR2 (4);
      ln_login_id                    NUMBER              := fnd_global.login_id;
      lc_oracle_error_msg            VARCHAR2 (1000);
      ln_org_id                      NUMBER;
      lc_output_msg                  VARCHAR2 (255);
      ln_request_id                  NUMBER       := fnd_global.conc_request_id;
      ln_retcode                     NUMBER;
      ld_sales_date                  DATE;
      lc_seg_co                      gl_code_combinations.segment1%TYPE;
      lc_seg_cost                    gl_code_combinations.segment2%TYPE;
      lc_seg_acct                    gl_code_combinations.segment3%TYPE;
      lc_seg_loc                     gl_code_combinations.segment4%TYPE;
      lc_seg_ic                      gl_code_combinations.segment5%TYPE;
      lc_seg_lob                     gl_code_combinations.segment6%TYPE;
      lc_seg_fut                     gl_code_combinations.segment7%TYPE;
      ln_seq_999                     NUMBER;
      lc_serial_loc                  VARCHAR2 (8);
      lc_serial_num                  xx_ce_store_bank_deposits.serial_num%TYPE;
      ln_set_of_books_id             gl_ledgers.ledger_id%TYPE;
      lc_status_cd                   xx_ce_store_bank_deposits.status_cd%TYPE;
      ln_store_amount                NUMBER;
      lc_store_cash_account          gl_code_combinations.segment3%TYPE;
      lc_store_cash_clearing         gl_code_combinations.segment3%TYPE;
      lc_store_seg_cost              gl_code_combinations.segment2%TYPE;
      ln_store_deposit_seq_nbr       NUMBER;
      ln_store_receipts_difference   NUMBER;
      ln_sum_ar_receipts             NUMBER;
      ln_sum_ar_refunds              NUMBER;
      ln_sum_db_card_cash_backs      NUMBER;
      ln_sum_cash_deposits           NUMBER;
      ln_sum_check_deposits          NUMBER;
      ln_sum_misc_deposits           NUMBER;
      ln_sum_other_deposits          NUMBER;
      ln_sum_petty                   NUMBER;
      lc_translate_error             VARCHAR2 (400);
      lc_translate_seg_acct          gl_code_combinations.segment3%TYPE;
      lc_translate_seg_cost          gl_code_combinations.segment2%TYPE;
      ln_user_id                     NUMBER               := fnd_global.user_id;
      ln_error                       NUMBER                                := 2;
      ln_warning                     NUMBER                                := 1;
      ln_normal                      NUMBER                                := 0;
      lc_je_line_dsc                 VARCHAR2 (240);
      lc_ch_dep_savepoint            VARCHAR2 (100);
      lc_sdb_savepoint               VARCHAR2 (200);
      lc_st_dep_savepoint            VARCHAR2 (200);
      ln_rec_count                   NUMBER                                := 0;
      ln_det_count                   NUMBER                                := 0;
      lc_output_line                 VARCHAR2 (2000);
      lc_trans_seg_cost              gl_code_combinations.segment2%TYPE;
      lc_trans_seg_cost_dr           gl_code_combinations.segment2%TYPE;
      lc_trans_seg_cost_mis          gl_code_combinations.segment2%TYPE;
      lc_trans_seg_cost_mis_dr       gl_code_combinations.segment2%TYPE;
      lc_trans_seg_acct              gl_code_combinations.segment3%TYPE;
      lc_trans_seg_acct_dr           gl_code_combinations.segment3%TYPE;
      lc_trans_seg_acct_mis_dr       gl_code_combinations.segment3%TYPE;
      lc_trans_seg_loc               gl_code_combinations.segment4%TYPE;
      lc_trans_seg_loc_mis_dr        gl_code_combinations.segment4%TYPE;
      lb_flag                        BOOLEAN DEFAULT FALSE;
      lc_flag                        VARCHAR2(1) DEFAULT 'N';
      ln_sum_cash_check_deposits     NUMBER;
      ld_bank_statement_date         ce_statement_headers.statement_date%TYPE;
      lc_match_type                  VARCHAR2(20);
      ln_appl_id                     fnd_application.application_id%TYPE;
      ln_days                        NUMBER;
      LN_CORPBANK_ACCT_ID            NUMBER := NVL(P_CORPBANK_ACCT_ID,11640);

      CURSOR c_store_deposit
      IS
      SELECT sales_Date,
            loc_id,
            status_cd,
            serial_num,
            amount,
            seq_nbr,
            deposit_type,
            location_id
          FROM
            (SELECT /*+ INDEX(xcs,XX_CE_STORE_BANK_DEPOSITS_F3) */  DISTINCT sales_date,
                          loc_id,
                          status_cd,
                          serial_num,
                          amount ,
                          seq_nbr,
                          deposit_type,
                          LPAD (TO_CHAR (xcs.loc_id), 6, '0') location_id
            FROM xx_ce_store_bank_deposits xcs
            WHERE status_cd ='N'
            AND  EXISTS
                                            (SELECT 1
                                            FROM hr_all_organization_units hro
                                            WHERE hro.attribute1                                      = to_char(xcs.loc_id)
                                            AND xx_fin_country_defaults_pkg.f_org_id (hro.attribute5) = gn_org_id
                                            AND hro.TYPE                                             IN
                                                          (SELECT XFTV.TARGET_value1
                                                          FROM xx_fin_translatedefinition XFTD ,
                                                            xx_fin_translatevalues XFTV
                                                          WHERE XFTD.translate_id   = XFTV.translate_id
                                                          AND XFTD.translation_name = gc_trans_name
                                                          AND XFTV.source_value1    = 'ORG_TYPE'
                                                          AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                                          AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                                          AND XFTV.enabled_flag = 'Y'
                                                          AND XFTD.enabled_flag = 'Y'
                                                          )
                                            )
            )
          WHERE location_id IN
            (SELECT SUBSTR (cba.agency_location_code, 3)
            FROM CE_BANK_ACCOUNTS CBA,
                          HZ_PARTIES HP
            WHERE hp.party_id =cba.bank_id
            AND hp.party_name ='WELLS FARGO BANK'
            AND hp.party_type ='ORGANIZATION'
            AND HP.STATUS     ='A'
            AND upper(cba.bank_Account_name) LIKE '%WELLS%'
            )
          ORDER BY 1,  2;


       CURSOR c_store_deposit_bank
       IS
       SELECT sales_Date,
         loc_id,
         status_cd,
         serial_num,
         amount,
         seq_nbr,
         deposit_type,
         location_id
       FROM
         (SELECT /*+ INDEX(xcs,XX_CE_STORE_BANK_DEPOSITS_F3) */  DISTINCT sales_date,
                       loc_id,
                       status_cd,
                       serial_num,
                       amount ,
                       seq_nbr,
                       deposit_type,
                       LPAD (TO_CHAR (xcs.loc_id), 6, '0') location_id
         FROM xx_ce_store_bank_deposits xcs
         WHERE status_cd =
                       (SELECT XFTV.TARGET_value1
                       FROM xx_fin_translatedefinition XFTD ,
                         xx_fin_translatevalues XFTV
                       WHERE XFTD.translate_id   = XFTV.translate_id
                       AND XFTD.translation_name = gc_trans_name
                       AND XFTV.source_value1    = 'IN_STATUS_CODE'
                       AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                       AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                       AND XFTV.enabled_flag = 'Y'
                       AND XFTD.enabled_flag = 'Y'
                       )
         AND deposit_type NOT IN ('PTY','CHG')
         AND EXISTS
                       (SELECT 1
                       FROM hr_all_organization_units hro
                       WHERE hro.attribute1                                      = TO_CHAR(xcs.loc_id)
                       AND xx_fin_country_defaults_pkg.f_org_id (hro.attribute5) = gn_org_id
                       AND hro.TYPE                                             IN
                         (SELECT XFTV.TARGET_value1
                         FROM xx_fin_translatedefinition XFTD ,
                                       xx_fin_translatevalues XFTV
                         WHERE XFTD.translate_id   = XFTV.translate_id
                         AND XFTD.translation_name = gc_trans_name
                         AND XFTV.source_value1    = 'ORG_TYPE'
                         AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                         AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                         AND XFTV.enabled_flag = 'Y'
                         AND XFTD.enabled_flag = 'Y'
                         )
                       )
         )
       WHERE location_id IN
         (SELECT SUBSTR (cba.agency_location_code, 3)
         FROM CE_BANK_ACCOUNTS CBA,
                       HZ_PARTIES HP
         WHERE hp.party_id =cba.bank_id
         AND hp.party_name ='WELLS FARGO BANK'
         AND hp.party_type ='ORGANIZATION'
         AND HP.STATUS     ='A'
         AND upper(cba.bank_Account_name) LIKE '%WELLS%'
         )
       ORDER BY 1,  2;


-- Added Translation to Check the Starting Value of MIS Income Account
      CURSOR c_seg_acct
      IS
         SELECT XFTV.TARGET_value1
           FROM xx_fin_translatedefinition XFTD
               ,xx_fin_translatevalues XFTV
          WHERE XFTD.translate_id = XFTV.translate_id
            AND XFTD.translation_name = gc_trans_name
            AND XFTV.source_value1 = 'SEG_ACCT_SUBSTR'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';

      CURSOR rpt_gl
      IS
         SELECT   a.user_je_category_name, a.user_je_source_name
                , COUNT ('x') gl_cnt, SUM (a.entered_cr) gl_cr
                , SUM (a.entered_dr) gl_dr, a.segment1, a.segment2, a.segment3
                , a.segment4, a.segment5, a.segment6
             FROM xx_gl_interface_na_stg a
            WHERE a.GROUP_ID = ln_group_id
         GROUP BY a.user_je_category_name
                , a.user_je_source_name
                , a.segment1
                , a.segment2
                , a.segment3
                , a.segment4
                , a.segment5
                , a.segment6;

      CURSOR c_check_db_status(lp_sales_date DATE, lp_loc_id NUMBER
      , lp_status_cd VARCHAR2, lp_serial_num VARCHAR2, lp_amount NUMBER
      , lp_seq_nbr NUMBER, lp_deposit_type VARCHAR2)
      IS
         SELECT 1

                    FROM xx_ce_store_bank_deposits xcs
                    WHERE xcs.sales_date = lp_sales_date
                      AND xcs.loc_id=lp_loc_id
                      AND xcs.status_cd=lp_status_cd
                      AND xcs.serial_num=lp_serial_num
                      AND xcs.amount=lp_amount
                      AND xcs.seq_nbr=lp_seq_nbr
                      AND xcs.deposit_type=lp_deposit_type
                      AND rownum=1;--Added due to the distinct clause in the cursor c_store_deposit_bank

                PROCEDURE lp_print(
                                lp_line IN VARCHAR2,
                                lp_both IN VARCHAR2)
                IS
                  ln_addnl_line_len NUMBER DEFAULT 110;
                  ln_char_count     NUMBER := 0;
                  ln_line_count     NUMBER := 0;
                BEGIN
                  IF fnd_global.conc_request_id () > 0 THEN
                                CASE
                                WHEN UPPER (lp_both) = 'BOTH' THEN
                                  fnd_file.put_line (fnd_file.LOG, lp_line);
                                  IF NVL (LENGTH (lp_line), 0) > 120 THEN
                                                FOR x IN 1 .. ( TRUNC ( (LENGTH (lp_line) - 120) / ln_addnl_line_len ) + 2 )
                                                LOOP
                                                  ln_line_count   := NVL (ln_line_count, 0) + 1;
                                                  IF ln_line_count = 1 THEN
                                                                fnd_file.put_line (fnd_file.output , SUBSTR (lp_line, 1, 120) );
                                                                ln_char_count := NVL (ln_char_count, 0) + 120;
                                                  ELSE
                                                                fnd_file.put_line (fnd_file.output , LPAD (' ' , 120 - ln_addnl_line_len , ' ' ) || SUBSTR (LTRIM (lp_line) , ln_char_count + 1 , ln_addnl_line_len ) );
                                                                ln_char_count := NVL (ln_char_count, 0)              + ln_addnl_line_len;
                                                  END IF;
                                                END LOOP;
                                  ELSE
                                                fnd_file.put_line (fnd_file.output, lp_line);
                                  END IF;
                                WHEN UPPER (lp_both) = 'LOG' THEN
                                  fnd_file.put_line (fnd_file.LOG, lp_line);
                                WHEN UPPER (lp_both)           = 'OUT' THEN
                                  IF NVL (LENGTH (lp_line), 0) > 120 THEN
                                                FOR x IN 1 .. ( TRUNC ( (LENGTH (lp_line) - 120) / ln_addnl_line_len ) + 2 )
                                                LOOP
                                                  ln_line_count   := NVL (ln_line_count, 0) + 1;
                                                  IF ln_line_count = 1 THEN
                                                                fnd_file.put_line (fnd_file.output , SUBSTR (lp_line, 1, 120) );
                                                                ln_char_count := NVL (ln_char_count, 0) + 120;
                                                  ELSE
                                                                fnd_file.put_line (fnd_file.output , LPAD (' ' , 120 - ln_addnl_line_len , ' ' ) || SUBSTR (LTRIM (lp_line) , ln_char_count + 1 , ln_addnl_line_len ) );
                                                                ln_char_count := NVL (ln_char_count, 0)              + ln_addnl_line_len;
                                                  END IF;
                                                END LOOP;
                                  ELSE
                                                fnd_file.put_line (fnd_file.output, lp_line);
                                  END IF;
                                ELSE
                                  fnd_file.put_line (fnd_file.output, lp_line);
                                END CASE;
                  ELSE
                                DBMS_OUTPUT.put_line (lp_line);
                  END IF;
                END; -- lp_print

   -- **************** procedure for null serial num replacement  *******************

      PROCEDURE NULL_SER_NUM_REPLACE
      IS
        ln_ser_count                   VARCHAR2(4) := 0;
        lc_sc_serial_num               VARCHAR2(4);
        lc_sc_max_ser_num              NUMBER;

        BEGIN
          BEGIN
            SELECT SUBSTR(MAX(serial_num),2,3)
            INTO   lc_sc_max_ser_num
            FROM   xx_ce_store_bank_deposits
            WHERE  serial_num LIKE 'X%'
            AND    last_update_date =(SELECT MAX(last_update_date)
                                      FROM   xx_ce_store_bank_deposits
                                      WHERE  serial_num LIKE 'X%'
                                      );
          EXCEPTION
            WHEN OTHERS
            THEN
              lp_print ('When others exception has raised in MAX(serial_num) select statement.'|| SQLERRM , 'LOG');
              RAISE;

          END;

          IF lc_sc_max_ser_num IS NULL THEN
            lc_sc_serial_num := 'X001';
          ELSIF lc_sc_max_ser_num = '0' THEN
           lc_sc_serial_num := 'X001';
          ELSIF lc_sc_max_ser_num = '00' THEN
           lc_sc_serial_num := 'X001';
          ELSIF lc_sc_max_ser_num = '000' THEN
           lc_sc_serial_num := 'X001';
          END IF;

          IF lc_sc_max_ser_num <> 999 THEN
            ln_ser_count := lc_sc_max_ser_num+1;
            lc_sc_serial_num := CONCAT('X',LPAD(ln_ser_count,3,0));
          ELSE
            lc_sc_serial_num := 'X001';
          END IF;

          -- Wait for 1 second if the lc_sc_max_ser_num = 999

          IF lc_sc_max_ser_num = 999 THEN
            lp_print('Waiting for a second in 999th record ','LOG');
            DBMS_LOCK.SLEEP(1);
          END IF;

          -- Updating the Serial Numbers for null serial numbers in xx_ce_store_bank_deposits table.

          UPDATE xx_ce_store_bank_deposits
          SET    serial_num       = lc_sc_serial_num
                ,last_update_date = SYSDATE
          WHERE  seq_nbr = ln_store_deposit_seq_nbr;

          lp_print ('Seq number: ' ||ln_store_deposit_seq_nbr|| 'Location: ' || ln_loc_id || '/ Sales date:'
                    || ld_sales_date||'  serial_num: '|| lc_sc_serial_num, 'LOG'
                   );
        EXCEPTION
          WHEN OTHERS
          THEN
            lp_print ('When others exception has raised in the procedure NULL_SER_NUM_REPLACE.'|| SQLERRM , 'LOG');
        END;
   -- **************** procedure for null serial num replacement Ends here ****************


      PROCEDURE lp_create_gl (
         lpv_dr                IN   NUMBER
       , lpv_cr                IN   NUMBER
       , lpv_accounting_date   IN   DATE
       , lpv_description       IN   VARCHAR2
      )
      /*-- -------------------------------------------
        -- Call the GL Common Package to create
        -- Gl Interface records
        -- -----------------------------------------*/
      IS
         ln_gl_ccid         NUMBER;
         lpv_char_date      VARCHAR2 (20);
         lpv_reference10    xx_gl_interface_na_stg.reference10%TYPE;
                                -- Added Local Variables
         lc_closing_status  GL_PERIOD_STATUSES.closing_status%TYPE;
         ld_accounting_date DATE;
         lc_source_name     VARCHAR2(25);
         lc_category_name   VARCHAR2(25);
         ln_status_count    NUMBER;

      BEGIN
         BEGIN
            SELECT XFTV.TARGET_value1
              INTO lc_source_name
              FROM xx_fin_translatedefinition XFTD
                   ,xx_fin_translatevalues XFTV
             WHERE XFTD.translate_id = XFTV.translate_id
               AND XFTD.translation_name = gc_trans_name
               AND XFTV.source_value1 = 'SOURCE_NAME'
               AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
               AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
               AND XFTV.enabled_flag = 'Y'
               AND XFTD.enabled_flag = 'Y';

            SELECT XFTV.TARGET_value1
              INTO lc_category_name
              FROM xx_fin_translatedefinition XFTD
                   ,xx_fin_translatevalues XFTV
             WHERE XFTD.translate_id = XFTV.translate_id
               AND XFTD.translation_name = gc_trans_name
               AND XFTV.source_value1 = 'CATEGORY_NAME'
               AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
               AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
               AND XFTV.enabled_flag = 'Y'
               AND XFTD.enabled_flag = 'Y';

         EXCEPTION
         WHEN NO_DATA_FOUND THEN
            lc_error_msg :=
                  'ERROR - Source and Category translation is not found.';
            lc_source_name := NULL;
            lc_category_name := NULL;
         WHEN OTHERS THEN
            lc_source_name := NULL;
            lc_category_name := NULL;
            lc_error_loc := 'LP_CREATE_GL - Source Name and Category Name: ' || lc_error_loc;
         END;

         lpv_char_date := TO_CHAR (lpv_accounting_date, 'YYYY-MM-DD');
         --  Call function to get line of business
         lc_seg_lob := pf_derive_lob (lc_seg_loc, lc_seg_cost);
         ln_gl_ccid :=
            fnd_flex_ext.get_ccid ('SQLGL'
                                      , 'GL#'
                                      , gn_coa_id
                                      , SYSDATE
                                      ,    lc_seg_co
                                        || '.'
                                        || lc_seg_cost
                                        || '.'
                                        || lc_seg_acct
                                        || '.'
                                        || lc_seg_loc
                                        || '.'
                                        || lc_seg_ic
                                        || '.'
                                        || lc_seg_lob
                                        || '.'
                                        || '000000'
                                       );

         IF NVL (ln_gl_ccid, 0) = 0
         THEN
            lc_error_msg := SUBSTR (fnd_flex_ext.GET_MESSAGE (), 1, 2500);
            lp_print (   'Code Combination for '
                      || lc_seg_co
                      || '.'
                      || lc_seg_cost
                      || '.'
                      || lc_seg_acct
                      || '.'
                      || lc_seg_loc
                      || '.'
                      || lc_seg_ic
                      || '.'
                      || lc_seg_lob
                      || '.'
                      || '000000'
                      || ' not found! '
                      || lc_error_msg
                    , 'BOTH'
                     );
            RAISE le_exception_gl_call;
         END IF;

-- Added Translation for Verifying the Status of the Period


         BEGIN
            SELECT closing_status
              INTO lc_closing_status
              FROM GL_PERIOD_STATUSES gp
             WHERE lpv_accounting_date BETWEEN start_date AND end_date
               AND ledger_id = gn_set_of_bks_id
               AND application_id = ln_appl_id;
         EXCEPTION
            WHEN OTHERS THEN
            lc_closing_status := 'C';
            lc_error_loc := 'LP_CREATE_GL - Closing Status for Accounting_Date: ' || lc_error_loc;

         END;


         IF (lc_closing_status <> 'O') THEN
            ld_accounting_date := TRUNC(SYSDATE);
         ELSE
        -- Check the count of open periods
            SELECT COUNT(*)
            INTO ln_status_count
            FROM GL_PERIOD_STATUSES gp
            WHERE closing_status='O'
                                                AND ledger_id = gn_set_of_bks_id
            AND application_id = ln_appl_id;

                                    -- If only one period is open, pass Accounting Date as Sales Date
                                                IF (ln_status_count=1)
                                                                THEN
                                                                ld_accounting_date := lpv_accounting_date;
                                                                ELSE
                                                                                  --- If more than one period is open ,pass Accounting Date as Current Period(Sysdate)
                                                                ld_accounting_date := TRUNC(SYSDATE);
                                                END IF;
                                END IF;

                                fnd_file.put_line (fnd_file.LOG,'ld_accounting_date '|| ld_accounting_date);

                                --Use Sysdate for Accounting date instead of Sales date.
         --  Call GL package to create the GL entry
         xx_gl_interface_pkg.create_stg_jrnl_line
                                     (p_status => 'NEW'
                                    , p_date_created => SYSDATE
                                    , p_created_by => ln_user_id
                                    , p_actual_flag => 'A'
                                    , p_group_id => ln_group_id
                                    , p_batch_name => lpv_char_date
                                    , p_batch_desc => ' '
                                    , p_user_source_name => lc_source_name
                                    , p_user_catgory_name => lc_category_name
                                    , p_set_of_books_id => ln_set_of_books_id
                                   , p_accounting_date => ld_accounting_date
                                    , p_currency_code => lc_currency_code
                                    , p_company => lc_seg_co
                                    , p_cost_center => lc_seg_cost
                                    , p_account => lc_seg_acct
                                    , p_location => lc_seg_loc
                                    , p_intercompany => lc_seg_ic
                                    , p_channel => lc_seg_lob
                                    , p_future => '000000'
                                    , p_entered_dr => lpv_dr
                                    , p_entered_cr => lpv_cr
                                    , p_je_name => NULL
                                    , p_je_reference => ln_group_id
                                    , p_je_line_dsc => SUBSTR (lpv_description
                                                             , 1
                                                             , 240
                                                              )
                                    , x_output_msg => lc_output_msg
                                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            lc_oracle_error_msg := SQLERRM;
            lc_error_loc := 'LP_CREATE_GL: ' || lc_error_loc;
            RAISE le_exception_gl_call;
      END; -- lp_create_gl local procedure ends here

      PROCEDURE lp_get_store_data
      IS
      BEGIN
         SELECT aba.bank_account_id
                                                  , aba.bank_account_num
                                                  , aba.currency_code
                                                  , hou.set_of_books_id
                                                  , cbau.org_id
                                                  , gcc.segment1
                                                  , gcc.segment2
                                                  , gcc.segment3
                                                  , gcc.segment4
                                                  , gcc.segment5
                                                  , gcc.segment6
                                                  , gcc.segment7
                                                  , gcc2.segment3
           INTO ln_bank_account_id, lc_bank_account_num, lc_currency_code
              , ln_set_of_books_id, ln_org_id, lc_seg_co, lc_seg_cost
              , lc_seg_acct, lc_seg_loc, lc_seg_ic, lc_seg_lob
              , lc_seg_fut, lc_store_cash_clearing
           FROM gl_code_combinations gcc
              , gl_code_combinations gcc2
              , ce_bank_accounts  aba
                                                  , ce_bank_acct_uses cbau
                          , hr_operating_units hou
          WHERE aba.asset_code_combination_id = gcc.code_combination_id
            AND aba.cash_clearing_ccid = gcc2.code_combination_id
            AND lc_aba_key = gcc.segment4
            AND NVL (cbau.end_date, SYSDATE + 1) > TRUNC (SYSDATE)
                                                AND NVL (aba.end_date, SYSDATE + 1) > TRUNC (SYSDATE)
                                                AND aba.bank_account_id = cbau.bank_account_id
                                                AND hou.organization_id = cbau.org_id
            AND bank_account_type in ('Deposit','DEPOSIT')
            AND gcc.segment4 = SUBSTR (aba.agency_location_code, 3)
            AND gcc.segment4 =
                  SUBSTR (aba.bank_account_name_alt
                        , LENGTH (aba.bank_account_name_alt) - 5
                         )
            AND gcc.segment4 =
                  TRANSLATE (UPPER (aba.description)
                           , '0123456789ODEPITRS -'
                           , '0123456789'
                            )
            AND gcc.segment4 =
                  SUBSTR (aba.bank_account_name
                        , LENGTH (aba.bank_account_name) - 5
                         )
                                                AND aba.bank_id in (SELECT hp.party_id FROM HZ_PARTIES hp
                                                                                                                                WHERE UPPER(hp.party_name) ='WELLS FARGO BANK'
                                                                                                                                AND hp.party_type='ORGANIZATION');

         lc_store_cash_account := lc_seg_acct;                         -- Hold the store's cash account
         lc_store_seg_cost := lc_seg_cost;                   -- Hold the store's cost center


      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lc_error_msg :=
                  'ERROR - Bank account setup incorrectly for store : '
               || lc_aba_key;
            RAISE le_exception_bad_store;
         WHEN TOO_MANY_ROWS
         THEN
            lc_error_msg :=
                  'ERROR - Multiple bank accounts set up for store : '
               || lc_aba_key;
            RAISE le_exception_store_accounts;
      END;                                                  -- lp_get_store_data

      PROCEDURE lp_log_comn_error (
         lp_object_type   IN   VARCHAR2
       , lp_object_id     IN   VARCHAR2
      )
      IS
      BEGIN
         fnd_message.set_name ('XXFIN', 'XX_CE_STORE_OS_WLFG_PKG_ERR');
         fnd_message.set_token ('ERR_LOC', lc_error_loc);
         fnd_message.set_token ('ERR_ORA', lc_oracle_error_msg);
         xx_com_error_log_pub.log_error
              (p_program_type => 'CONCURRENT PROGRAM'
             , p_program_name => 'OD: Store Over/Short and Cash Concentration'
             , p_program_id => fnd_global.conc_program_id
             , p_module_name => 'CE'
             , p_error_location => 'Error at ' || lc_error_loc
             , p_error_message_count => 1
             , p_error_message_code => 'E'
             , p_error_message => NVL (lc_error_msg, lc_oracle_error_msg)
             , p_error_message_severity => 'Major'
             , p_notify_flag => 'N'
             , p_object_type => lp_object_type
             , p_object_id => lp_object_id
              );
      END;                                                  -- lp_log_comn_error

      --  Create the CE Reconciliation Open Interface record
      --  and update the ce_statement_lines so they can be matched
      PROCEDURE create_open_interface (
         x_errbuf                OUT NOCOPY      VARCHAR2
       , x_retcode               OUT NOCOPY      NUMBER
       , p_trx_code_id           IN              NUMBER
       , p_trx_code              IN              VARCHAR2
       , p_bank_trx_number_org   IN              VARCHAR2
       , p_statement_header_id   IN              NUMBER
       , p_statement_line_id     IN              NUMBER
       , p_record_type           IN              VARCHAR2
       , p_trx_date              IN              DATE
       , p_amount                IN              VARCHAR2
      )
      IS
         ln_transaction_code_id   NUMBER;
      BEGIN
         lp_print (' ln_bank_account_id :: '||ln_bank_account_id, 'LOG');
         SELECT xx_ce_999_interface_s.NEXTVAL
           INTO ln_seq_999
           FROM DUAL;

         lp_print (' ln_seq_999 :: '||ln_seq_999, 'LOG');
                                --  Get 001 trx_code_id for this bank
         BEGIN
                                                SELECT  transaction_code_id       ,trx_code
              INTO ln_csl_trx_code_001_id      ,ln_csl_trx_code_001
              FROM ce_transaction_codes
             WHERE bank_account_id = ln_bank_account_id
               AND trx_code = '001'
               AND NVL (end_date, SYSDATE + 1) > SYSDATE;
               lp_print (' ln_csl_trx_code_001_id :: '||ln_csl_trx_code_001_id, 'LOG');
               lp_print (' ln_csl_trx_code_001 :: '||ln_csl_trx_code_001, 'LOG');
         EXCEPTION
            WHEN OTHERS
            THEN
               x_retcode := ln_error;
               lc_error_loc := 'Get TrxCode:' || lc_error_loc;
               lc_oracle_error_msg := SQLERRM;

               lp_print (' ln_bank_account_id :: '||ln_bank_account_id, 'LOG');
               lp_print (' lc_oracle_error_msg :: '||lc_oracle_error_msg, 'LOG');
               lc_print_line :=
                     NVL (lc_oracle_error_msg, lc_error_msg)
                  || ' in '
                  || lc_error_loc;
               lp_print (lc_print_line, 'BOTH');

               RAISE le_exception_trx_code;
         END;
                                -- End of retrieve bank 001 trx_code_id

                                -- ------------------------------------------------
                                -- Insert the record into xx_ce_999_interface table
                                -- ------------------------------------------------

        lp_print (' xx_ce_999_interface :: ', 'LOG');
                                                INSERT
                                                                INTO xx_ce_999_interface
                                                                  (
                                                                                trx_id,
                                                                                trx_number,
                                                                                bank_trx_code_id_original ,
                                                                                bank_trx_code_original   ,
                                                                                bank_trx_number_original,
                                                                                statement_header_id ,
                                                                                statement_line_id,
                                                                                record_type,
                                                                                creation_date ,
                                                                                created_by,
                                                                                last_update_date,
                                                                                last_updated_by,
                                                                                trx_type ,
                                                                                status,
                                                                                bank_account_id,
                                                                                currency_code ,
                                                                                trx_date,
                                                                                amount,
                                                                                match_amount,
                                                                                deposits_matched ,
                                                                                expenses_complete
                                                                  )
                                                                  VALUES
                                                                  (
                                                                                ln_seq_999,
                                                                                ln_seq_999,
                                                                                p_trx_code_id ,
                                                                                p_trx_code  ,
                                                                                p_bank_trx_number_org,
                                                                                p_statement_header_id ,
                                                                                p_statement_line_id,
                                                                                p_record_type,
                                                                                SYSDATE ,
                                                                                ln_user_id,
                                                                                SYSDATE,
                                                                                ln_user_id,
                                                                                'CASH' ,
                                                                                'FLOAT',
                                                                                LN_CORPBANK_ACCT_ID,
                                                                                lc_currency_code ,
                                                                                p_trx_date,
                                                                                p_amount,
                                                                                p_amount,
                                                                                'Y' ,
                                                                                'Y'
                                                                  );

                                -- ------------------------------------------------
                                -- Update the ce_statement_lines record
                                -- ------------------------------------------------
         lp_print (' ce_statement_lines :: ', 'LOG');

         UPDATE ce_statement_lines csl
            SET csl.attribute15 = 'PROC-E1319-YES'
              , csl.trx_code_id = ln_csl_trx_code_001_id
                                                  , csl.trx_code = ln_csl_trx_code_001
              , csl.bank_trx_number = ln_seq_999
          WHERE csl.statement_line_id = ln_csl_statement_line_id;

         lp_print (' ce_statement_lines updated :: ', 'LOG');
      EXCEPTION
         WHEN le_exception_trx_code
         THEN
            --NULL;
            RAISE;
         WHEN OTHERS
         THEN
            lc_oracle_error_msg := SQLERRM;
            x_retcode := ln_error;
            lc_error_loc := 'Write 999:' || lc_error_loc;
            lp_print (   NVL (lc_oracle_error_msg, lc_error_msg)
                      || ' in '
                      || lc_error_loc
                    , 'BOTH'
                     );
            --RAISE le_exception_999;
            RAISE;
      END create_open_interface;

      PROCEDURE lp_translate (
         lp_source1      IN       VARCHAR2
       , lp_source2      IN       VARCHAR2
       , lp_out_cc       OUT      VARCHAR2
       , lp_out_acct     OUT      VARCHAR2
       , lp_tran_error   OUT      VARCHAR2
      )
      IS
         lp_out03              VARCHAR2 (100);
         lp_out04              VARCHAR2 (100);
         lp_out05              VARCHAR2 (100);
         lp_out06              VARCHAR2 (100);
         lp_out07              VARCHAR2 (100);
         lp_out08              VARCHAR2 (100);
         lp_out09              VARCHAR2 (100);
         lp_out10              VARCHAR2 (100);
         lp_out11              VARCHAR2 (100);
         lp_out12              VARCHAR2 (100);
         lp_out13              VARCHAR2 (100);
         lp_out14              VARCHAR2 (100);
         lp_out15              VARCHAR2 (100);
         lp_out16              VARCHAR2 (100);
         lp_out17              VARCHAR2 (100);
         lp_out18              VARCHAR2 (100);
         lp_out19              VARCHAR2 (100);
         lp_out20              VARCHAR2 (100);
         lp_cc_translation     VARCHAR2 (40)   := 'GL_PSFIN_COST_CENTER';
         lp_acct_translation   VARCHAR2 (40)   := 'GL_PSFIN_ACCOUNT';
         lc_target1            VARCHAR2 (100);
         lc_target2            VARCHAR2 (100);
         lc_tran_err           VARCHAR2 (1000);
      BEGIN
         lp_print (   'Get translation for Legacy Dept/Acct:'
                   || lp_source1
                   || '/'
                   || lp_source2
                 , 'LOG'
                  );
         lp_out_cc := NULL;
         lp_out_acct := NULL;
         lc_target1 := NULL;
         lc_target2 := NULL;
         -- Get translation for the Department/Cost Center.
         xx_fin_translate_pkg.xx_fin_translatevalue_proc
                                       (p_translation_name => lp_cc_translation
                                     , p_source_value1 => lp_source1
                                      , x_target_value1 => lc_target1
                                      , x_target_value2 => lc_target2
                                      , x_target_value3 => lp_out03
                                      , x_target_value4 => lp_out04
                                      , x_target_value5 => lp_out05
                                      , x_target_value6 => lp_out06
                                      , x_target_value7 => lp_out07
                                      , x_target_value8 => lp_out08
                                      , x_target_value9 => lp_out09
                                      , x_target_value10 => lp_out10
                                      , x_target_value11 => lp_out11
                                      , x_target_value12 => lp_out12
                                      , x_target_value13 => lp_out13
                                      , x_target_value14 => lp_out14
                                      , x_target_value15 => lp_out15
                                      , x_target_value16 => lp_out16
                                      , x_target_value17 => lp_out17
                                      , x_target_value18 => lp_out18
                                      , x_target_value19 => lp_out19
                                      , x_target_value20 => lp_out20
                                      , x_error_message => lp_tran_error
                                       );
         lp_out_cc := NVL (lc_target1, lc_target2);
         lc_tran_err := lp_tran_error;
         lp_tran_error := NULL;
         lc_target1 := NULL;
         lc_target2 := NULL;
         -- Get translation for the Account.
         xx_fin_translate_pkg.xx_fin_translatevalue_proc
                                     (p_translation_name => lp_acct_translation
                                    , p_source_value1 => lp_source2
                                    , x_target_value1 => lc_target1
                                    , x_target_value2 => lc_target2
                                    , x_target_value3 => lp_out03
                                    , x_target_value4 => lp_out04
                                    , x_target_value5 => lp_out05
                                    , x_target_value6 => lp_out06
                                    , x_target_value7 => lp_out07
                                    , x_target_value8 => lp_out08
                                    , x_target_value9 => lp_out09
                                    , x_target_value10 => lp_out10
                                    , x_target_value11 => lp_out11
                                    , x_target_value12 => lp_out12
                                    , x_target_value13 => lp_out13
                                    , x_target_value14 => lp_out14
                                    , x_target_value15 => lp_out15
                                    , x_target_value16 => lp_out16
                                    , x_target_value17 => lp_out17
                                    , x_target_value18 => lp_out18
                                    , x_target_value19 => lp_out19
                                    , x_target_value20 => lp_out20
                                    , x_error_message => lp_tran_error
                                     );
         lp_out_acct := NVL (lc_target1, lc_target2);
         lp_tran_error := lc_tran_err || lp_tran_error;
         lp_print (   'Translated values for Dept/Acct:'
                   || NVL (lp_out_cc, 'NOT FOUND')
                   || '/'
                   || NVL (lp_out_acct, 'NOT FOUND')
                 , 'LOG'
                  );
         -- If no transalation error but a target value is not found
         --Then note error.
         IF (lp_out_cc IS NULL
             OR lp_out_acct IS NULL)
         THEN
            lp_print ('Error: Translation value(s) not found! ' || lp_tran_error
                    , 'LOG'
                     );
         END IF;
      END lp_translate;

      PROCEDURE lp_pty_mis
      IS
/*   ********************************************************** */
/*   *                                                        * */
/*   * This procedure creates GL entries for all 'PTY'        * */
/*   * and  'MIS' transactions.                               * */
/*   * It is called inside lp_process_store_receipt_os        * */
/*   ********************************************************** */
         CURSOR lc_pty_mis
         IS
            SELECT xcs.deposit_type, xcs.loc_id, xcs.sales_date
                 , SUBSTR (xcs.log_num, 4, 3) dept
                 , SUBSTR (xcs.bag_num, 4, 4)|| SUBSTR (xcs.log_num, 1, 3) acct
                 , xcs.amount
              FROM xx_ce_store_bank_deposits xcs
             WHERE xcs.deposit_type IN ('PTY', 'MIS')
                                                   AND xcs.sales_date = ld_sales_date
               AND NVL (xcs.status_cd, '~') NOT IN(
                                                                                                                                                                                SELECT XFTV.TARGET_value1
                                                                                                                                                                                   FROM xx_fin_translatedefinition XFTD
                                                                                                                                                                                                                ,xx_fin_translatevalues XFTV
                                                                                                                                                                                  WHERE XFTD.translate_id = XFTV.translate_id
                                                                                                                                                                                                AND XFTD.translation_name = gc_trans_name
                                                                                                                                                                                                AND XFTV.source_value1 = 'EX_STATUS_CODE'
                                                                                                                                                                                                AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                                                                                                                                                                                AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                                                                                                                                                                                AND XFTV.enabled_flag = 'Y'
                                                                                                                                                                                                AND XFTD.enabled_flag = 'Y')
               AND xcs.loc_id = ln_loc_id;

                                -- Added Local Variables
         ln_lr_loc    xx_ce_store_bank_deposits.loc_id%TYPE;
         ln_gr_loc    xx_ce_store_bank_deposits.loc_id%TYPE;

      BEGIN
         lp_print ('Start PTY/MIS processing.', 'LOG');

                                -- Added Translation to get the account, cost center details
                                                   BEGIN
                                                                SELECT  XFTV.TARGET_value2
                                                                                                ,XFTV.TARGET_value3
                                                                   INTO  lc_trans_seg_acct
                                                                                                ,lc_trans_seg_cost
                                                                   FROM  xx_fin_translatedefinition XFTD
                                                                                   , xx_fin_translatevalues XFTV
                                                                WHERE  XFTD.translate_id = XFTV.translate_id
                                                                   AND  XFTD.translation_name = gc_trans_name
                                                                   AND  XFTV.source_value2 = 'PTY_CR'
                                                                   AND  SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                                                   AND  SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                                                   AND  XFTV.enabled_flag = 'Y'
                                                                   AND  XFTD.enabled_flag = 'Y';


                                                                SELECT XFTV.TARGET_value1
                                                                   INTO ln_lr_loc
                                                                   FROM xx_fin_translatedefinition XFTD
                                                                                                ,xx_fin_translatevalues XFTV
                                                                  WHERE XFTD.translate_id = XFTV.translate_id
                                                                                AND XFTD.translation_name = gc_trans_name
                                                                                AND XFTV.source_value1 = 'LR_LOC'
                                                                                AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                                                                AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                                                                AND XFTV.enabled_flag = 'Y'
                                                                                AND XFTD.enabled_flag = 'Y';



                                                                SELECT XFTV.TARGET_value1
                                                                   INTO ln_gr_loc
                                                                   FROM xx_fin_translatedefinition XFTD
                                                                                                ,xx_fin_translatevalues XFTV
                                                                  WHERE XFTD.translate_id = XFTV.translate_id
                                                                                AND XFTD.translation_name = gc_trans_name
                                                                                AND XFTV.source_value1 = 'GR_LOC'
                                                                                AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                                                                AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                                                                AND XFTV.enabled_flag = 'Y'
                                                                                AND XFTD.enabled_flag = 'Y';


                                                   EXCEPTION
                                                                WHEN NO_DATA_FOUND THEN
                                                                                lc_error_msg :=
                                                                                                  'ERROR - Translation setup is not found : ';
                                                                                lc_trans_seg_acct := 00000;
                                                                                lc_trans_seg_cost := 00000;
                                                                                ln_lr_loc         := 99999;
                                                                                ln_gr_loc         := 00000;

                                                                WHEN OTHERS THEN
                                                                                lc_trans_seg_acct := 00000;
                                                                                lc_trans_seg_cost := 00000;
                                                                                ln_lr_loc         := 99999;
                                                                                ln_gr_loc         := 00000;
                                                                                lc_error_loc := 'LC_PTY_MIS - Translation setup is not found: ' || lc_error_loc;
                                                   END;

         FOR ii IN lc_pty_mis
         LOOP  --  Get the PTY and MIS trans
            lc_translate_error := '~';



            BEGIN  --  Translate Integral Oracle
               lp_translate (LPAD (ii.dept, 4, '0')
                           , ii.acct
                          , lc_translate_seg_cost
                           , lc_translate_seg_acct
                           , lc_translate_error
                            );

               IF NVL (lc_translate_error, '~') <> '~'
               THEN
                  RAISE le_exception_translate;
               END IF;

               --  Do GL entry creation for this transaction
            IF ii.deposit_type = 'PTY'
               THEN
                  -- Do GL entries for this 'PTY' transaction
                  -- Always Credit store ""Over/Short System"" for the PTY trans amount

                  lc_seg_loc := lc_aba_key;
                  lc_seg_cost := lc_trans_seg_cost;
                  lc_seg_acct := lc_trans_seg_acct;


                  lp_print('lc_seg_cost:'||lc_seg_cost,'BOTH');
                  lp_print('lc_seg_acct:'||lc_seg_acct,'BOTH');

                  lc_je_line_dsc :=
                        lc_seg_loc
                     || '/'
                     || TO_CHAR (ii.sales_date, 'DD-MON-RR')
                     || '/'
                     || ' Petty Cash Dep';

                  lp_print('lc_je_line_dsc:'||lc_je_line_dsc,'BOTH');
                  lp_create_gl (0, ii.amount, ii.sales_date, lc_je_line_dsc);
                  lp_print('lc_je_line_dsc:'||lc_je_line_dsc,'LOG');
                  --  Now do the DR side
                  lc_seg_acct := lc_translate_seg_acct;


                                                -- Added Translation to get Account, Cost center and Location Details
               BEGIN
                  SELECT XFTV.TARGET_value2
                         ,XFTV.TARGET_value3
                         ,XFTV.TARGET_value4
                    INTO lc_trans_seg_acct_dr
                         ,lc_trans_seg_cost_dr
                         ,lc_trans_seg_loc
                    FROM xx_fin_translatedefinition XFTD
                         ,xx_fin_translatevalues XFTV
                   WHERE XFTD.translate_id = XFTV.translate_id
                     AND XFTD.translation_name = gc_trans_name
                     AND XFTV.source_value2 = 'PTY_DR'
                     AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                     AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                     AND XFTV.enabled_flag = 'Y'
                     AND XFTD.enabled_flag = 'Y';

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     lc_error_msg :=
                        'ERROR - Translation setup is not found : ';
                     lc_trans_seg_acct_dr := 00000;
                     lc_trans_seg_cost_dr := 00000;
                     lc_trans_seg_loc  := 00000;

                  WHEN OTHERS THEN
                     lc_trans_seg_acct_dr := 00000;
                     lc_trans_seg_cost_dr := 00000;
                     lc_trans_seg_loc  := 00000;
                     lc_error_loc := 'LC_PTY_MIS ' || lc_error_loc;
               END;

                  IF lc_seg_acct = lc_trans_seg_acct_dr
                 THEN                           -- gets done at corporate level
                     lc_seg_cost := lc_trans_seg_cost_dr;
                     lc_seg_loc := lc_trans_seg_loc;
                     lc_je_line_dsc :=
                           lc_seg_loc
                        || '/'
                        || TO_CHAR (ii.sales_date, 'DD-MON-RR')
                        || '/'
                        || ' CAD Debit Cards';

                  ELSE                             -- use the translate cost-ctr
                     lc_seg_cost := lc_translate_seg_cost;
                     lc_seg_loc := lc_aba_key;
                     lc_je_line_dsc :=
                           lc_seg_loc
                        || '/'
                        || TO_CHAR (ii.sales_date, 'DD-MON-RR')
                        || '/'
                        || ' Misc Inc';

                  END IF;

                                                lp_create_gl (ii.amount, 0, ii.sales_date, lc_je_line_dsc);

            ELSIF ii.deposit_type = 'MIS'

                                                   THEN
                                                                  lb_flag := FALSE;
                  -- Do GL entries for this 'MIS' transaction
                  lc_seg_loc := lc_aba_key;
                  lc_seg_cost := lc_translate_seg_cost;
                  lc_seg_acct := lc_translate_seg_acct;


                                                                -- Added Translation value for verifying the Starting value of the Account
                  FOR i IN c_seg_acct
                  LOOP
                     IF ((SUBSTR(lc_seg_acct,0,1)) = i.TARGET_value1) THEN
                        lb_flag := TRUE;
                     END IF;
                  END LOOP;

                  IF (lb_flag) THEN
                     SELECT XFTV.TARGET_value3
                       INTO lc_trans_seg_cost_mis
                       FROM xx_fin_translatedefinition XFTD
                            ,xx_fin_translatevalues XFTV
                      WHERE XFTD.translate_id = XFTV.translate_id
                        AND XFTD.translation_name = gc_trans_name
                        AND XFTV.source_value2 = 'MIS'
                        AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                        AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                        AND XFTV.enabled_flag = 'Y'
                        AND XFTD.enabled_flag = 'Y';

                     lc_seg_cost := lc_trans_seg_cost_mis;


                  END IF;

                  lc_je_line_dsc :=
                        lc_seg_loc
                     || '/'
                     || TO_CHAR (ii.sales_date, 'DD-MON-RR')
                     || '/'
                     || ' Misc Expense';
                  --Credit translated account for the MIS trans amount

                                                                  lp_create_gl (0, ii.amount, ii.sales_date, lc_je_line_dsc);


                                                -- Added Translation to get the Account, Cost Center and Location Details
               BEGIN
                  SELECT XFTV.TARGET_value2
                         ,XFTV.TARGET_value3
                         ,XFTV.TARGET_value4
                    INTO lc_trans_seg_acct_mis_dr
                         ,lc_trans_seg_cost_mis_dr
                         ,lc_trans_seg_loc_mis_dr
                    FROM xx_fin_translatedefinition XFTD
                         ,xx_fin_translatevalues XFTV
                   WHERE XFTD.translate_id = XFTV.translate_id
                     AND XFTD.translation_name = gc_trans_name
                     AND XFTV.source_value2 = 'LOC'
                     AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                     AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                     AND XFTV.enabled_flag = 'Y'
                     AND XFTD.enabled_flag = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     lc_error_msg :=
                        'ERROR - Translation setup is not found : ';
                     lc_trans_seg_acct_mis_dr := 00000;
                     lc_trans_seg_cost_mis_dr := 00000;
                     lc_trans_seg_loc_mis_dr  := 00000;

                  WHEN OTHERS THEN
                     lc_trans_seg_acct_mis_dr := 00000;
                     lc_trans_seg_cost_mis_dr := 00000;
                     lc_trans_seg_loc_mis_dr  := 00000;
                     lc_error_loc := 'LC_PTY_MIS - MIS' || lc_error_loc;
               END;


                  -- Debit  store clearing account for the MIS trans amount
                  -- if not a CSC location, otherwise debit the account for
                  -- ""Wachovia - Miscellaneous Corporate Deposits Clearing""
                  IF ii.loc_id < ln_lr_loc  AND ii.loc_id > ln_gr_loc
                  THEN
                     lc_seg_loc := lc_trans_seg_loc_mis_dr;
                     lc_seg_cost := lc_trans_seg_cost_mis_dr;
                     lc_seg_acct := lc_trans_seg_acct_mis_dr;
                     lc_je_line_dsc :=
                           lc_seg_loc
                        || '/'
                        || TO_CHAR (ii.sales_date, 'DD-MON-RR')
                        || '/'
                        || ' Misc Deposit';
                     lp_create_gl (ii.amount, 0, ii.sales_date, lc_je_line_dsc);

                  ELSE
                     lc_seg_loc := lc_aba_key;
                     lc_seg_cost := lc_store_seg_cost;
                     lc_seg_acct := lc_store_cash_clearing;
                     lc_je_line_dsc :=
                           lc_seg_loc
                        || '/'
                        || TO_CHAR (ii.sales_date, 'DD-MON-RR')
                        || '/'
                        || ' Misc Deposit';
                     lp_create_gl (ii.amount, 0, ii.sales_date, lc_je_line_dsc);
                  END IF;                                     -- End of CSC test
            END IF;                               -- End of IF for trans type
            END;
         END LOOP;
      END lp_pty_mis;

/*   ********************************************************** */
/*   *                                                        * */
/*   * This procedure creates GL entries for all incoming     * */
/*   * transactions by:                                       * */
/*   *    a)  calling lp_pty_mis to do those trans types      * */
/*   *    b)  creating GL for all non 'PTY', 'MIS', 'CHG'     * */
/*   *                        'CHK', 'CSH', and other         * */
/*   *        transactions at a summary level                 * */
/*   * Then it determines any over/short condition between    * */
/*   * the store recorded deposits and the AR Cash Receipts   * */
/*   * for the day and creates appropriate GL entries.        * */
/*   *                                                        * */
/*   ********************************************************** */
      PROCEDURE lp_process_store_receipt_os
      IS
      BEGIN
         lc_error_loc := 'Store/Receipts Loop';
         ln_sum_petty := 0;
         ln_sum_cash_deposits := 0;
         ln_sum_check_deposits := 0;
         ln_sum_other_deposits := 0;
         ln_sum_misc_deposits := 0;
         /*  ****************************************************
         --  Call local procedure to Create Gl for PTY and MIS
         --  transactions.  Canadian Debit Cards are in PTY.   */
         lp_pty_mis;    --  This is the local procedure to do above.

                                BEGIN
                                                SELECT XFTV.TARGET_value2
                                                INTO   lc_trans_seg_acct
                                                FROM   xx_fin_translatedefinition XFTD
                                                                   ,xx_fin_translatevalues XFTV
                                                WHERE  XFTD.translate_id = XFTV.translate_id
                                                   AND  XFTD.translation_name = gc_trans_name
                                                   AND  XFTV.source_value2 = 'DEPOSIT_STORE_CASH'
                                                   AND  SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                                   AND  SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                                   AND  XFTV.enabled_flag = 'Y'
                                                   AND  XFTD.enabled_flag = 'Y';
                                  EXCEPTION
                                                WHEN NO_DATA_FOUND THEN
                                                                lc_error_msg :=
                                                                   'ERROR - Translation setup is not found : ';
                                                                lc_trans_seg_acct := 00000;
                                                WHEN OTHERS THEN
                                                                lc_trans_seg_acct := 00000;
                                                                lc_error_loc := 'lp_process_store_receipt_os' || lc_error_loc;
                                  END;


         SELECT                                                       --loc_id,
                SUM (DECODE (pd.deposit_type                -- Sum up Petty Cash
                           , 'PTY', pd.amount
                           , 0
                            )
                    ) pty
              , SUM (DECODE (pd.deposit_type             -- Sum up Misc Deposits
                           , 'MIS', pd.amount
                           , 0
                            )
                    ) mis
              , SUM (DECODE (pd.deposit_type                      -- Sum up Cash
                           , 'CSH', pd.amount
                           , 0
                            )) csh
              , SUM (DECODE (pd.deposit_type                     -- Sum up Check
                           , 'CHK', pd.amount
                           , 0
                            )
                    ) chk
              , SUM (DECODE (pd.deposit_type                -- Sum up all except
                           , 'PTY', 0                              -- Petty Cash
                           , 'CHG', 0                                  -- Change
                           , 'MIS', 0                           -- Misc Deposits
                           , 'CSH', 0                                    -- Cash
                           , 'CHK', 0                                  -- Checks
                           , pd.amount
                            )
                    ) other
           INTO ln_sum_petty
              , ln_sum_misc_deposits
              , ln_sum_cash_deposits
              , ln_sum_check_deposits
              , ln_sum_other_deposits
           FROM xx_ce_store_bank_deposits pd
          WHERE NVL (pd.status_cd, '~') NOT IN (
                                            SELECT XFTV.TARGET_value1
                                              FROM xx_fin_translatedefinition XFTD
                                                   ,xx_fin_translatevalues XFTV
                                             WHERE XFTD.translate_id = XFTV.translate_id
                                               AND XFTD.translation_name = gc_trans_name
                                               AND XFTV.source_value1 = 'EX_STATUS_CODE'
                                               AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                               AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                              AND XFTV.enabled_flag = 'Y'
                                               AND XFTD.enabled_flag = 'Y')
            AND pd.loc_id = ln_loc_id
                                               AND pd.sales_date = ld_sales_date;

         -- Do GL entries for the cash, check, and other deposits
         -- but do not include the misc deposits since they
         -- will have different cost-centers, accounts etc.
         -- Debit store cash clearing acct for deposits
         lc_seg_loc := lc_aba_key;
         lc_seg_acct := lc_store_cash_clearing;
         lc_seg_cost := lc_store_seg_cost;
         lc_je_line_dsc :=
               lc_seg_loc
            || '/'
            || TO_CHAR (ld_sales_date, 'DD-MON-RR')
            || '/'
           || ' AR2 POS OvrShrt';


         IF ln_sum_cash_deposits > 0
         THEN
            lp_create_gl (ln_sum_cash_deposits
                        , 0
                        , ld_sales_date
                        , lc_je_line_dsc || '- Store Cash Deposit'
                         );
         END IF;

         IF ln_sum_check_deposits > 0
         THEN
            lp_create_gl (ln_sum_check_deposits
                        , 0
                        , ld_sales_date
                        , lc_je_line_dsc || '- Store Check Deposit'
                         );
         END IF;

         IF ln_sum_other_deposits > 0
         THEN
            lp_create_gl (ln_sum_other_deposits
                        , 0
                        , ld_sales_date
                        , lc_je_line_dsc || '- Store Other Deposit'
                         );
         END IF;

         -- Credit ""Store Cash In Transit"" acct for deposit amount
         lc_seg_acct := lc_trans_seg_acct;

         IF ln_sum_cash_deposits > 0
         THEN
            lp_create_gl (0
                        , ln_sum_cash_deposits
                        , ld_sales_date
                        , lc_je_line_dsc || '- Store Cash Deposit'
                         );
         END IF;

         IF ln_sum_check_deposits > 0
         THEN
            lp_create_gl (0
                        , ln_sum_check_deposits
                        , ld_sales_date
                        , lc_je_line_dsc || '- Store Check Deposit'
                         );
         END IF;

         IF ln_sum_other_deposits > 0
         THEN
            lp_create_gl (0
                        , ln_sum_other_deposits
                        , ld_sales_date
                        , lc_je_line_dsc || '- Store Other Deposit'
                         );
         END IF;

--------------------------------------------------------------------------
-- End Removal of System Overshort - 20080913 - DGG
-- Above will be replaced by an export of Overshort from
-- Legacy Sales Accounting and interfaced to GL at a later date
--------------------------------------------------------------------------
         UPDATE xx_ce_store_bank_deposits a
            SET a.status_cd = 'S'
              , a.status_date = SYSDATE
              , a.last_update_date = SYSDATE
              , a.last_updated_by = fnd_global.user_id
          WHERE a.loc_id = ln_loc_id
            AND trunc(a.sales_date) = trunc(ld_sales_date)
            AND NVL (a.status_cd, '~') IN (SELECT XFTV.TARGET_value1
                                             FROM xx_fin_translatedefinition XFTD
                                                   ,xx_fin_translatevalues XFTV
                                            WHERE XFTD.translate_id = XFTV.translate_id
                                              AND XFTD.translation_name = gc_trans_name
                                              AND XFTV.source_value1 = 'UPD_STATUS_CODE'
                                              AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                              AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                              AND XFTV.enabled_flag = 'Y'
                                              AND XFTD.enabled_flag = 'Y');


      EXCEPTION
         WHEN le_exception_translate
         THEN
            ln_sum_ar_receipts := 0;
            RAISE le_exception_translate;
         WHEN OTHERS
         THEN
            ln_sum_ar_receipts := 0;
            RAISE;
      END;                                        --end local procedure lp_Process_Store_Receipt_OS

/* ----------------------------------------------------*/
/*                                                     */
/*          START OF THE MAIN PROCEDURE                */
/*                                                     */
/* ----------------------------------------------------*/
-- STORE_OS_CC_MAIN Starts Here
   BEGIN
      lp_print ('Started at ' || TO_CHAR (SYSDATE, 'dd-mon-yyyy hh:mi:ss')
              , 'LOG'
               );
      lp_print ('', 'OUT');
      lc_print_line :=
            TO_CHAR (SYSDATE, 'DD-MON-YY')
         || '                              E1319-Store Over/Short and Cash Concentration';
      lp_print (lc_print_line, 'OUT');
      lp_print
         ('                                                       Processing Summary'
        , 'OUT'
         );
      lp_print (' ', 'BOTH');
                  lp_print ('P_CORPBANK_ACCT_ID '||P_CORPBANK_ACCT_ID, 'LOG');
                  lp_print ('LN_CORPBANK_ACCT_ID '||LN_CORPBANK_ACCT_ID, 'LOG');

        BEGIN
          mo_global.set_policy_context('S',FND_PROFILE.VALUE('ORG_ID'));
        END;


      SELECT gsob.chart_of_accounts_id
        INTO gn_coa_id
        FROM gl_ledgers gsob  , ar_system_parameters asp
       WHERE asp.set_of_books_id = gsob.ledger_id;

      SELECT gl_interface_control_s.NEXTVAL
        INTO ln_group_id
        FROM DUAL;

      SELECT application_id
        INTO ln_appl_id
        FROM fnd_application
       WHERE application_short_name = 'SQLGL';

      BEGIN
         SELECT XFTV.TARGET_value1
           INTO ln_days
           FROM xx_fin_translatedefinition XFTD
               ,xx_fin_translatevalues XFTV
          WHERE XFTD.translate_id = XFTV.translate_id
            AND XFTD.translation_name = gc_trans_name
            AND XFTV.source_value1 = 'NO_OF_DAYS'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN OTHERS THEN
            ln_days := 0;
      END;

      lp_print ('Group ID:' || ln_group_id, 'LOG');
      lc_error_loc := 'Store Deposit Loop';
      lp_print ('Process System Over/Short', 'BOTH');
      lp_print (gc_line, 'BOTH');
      lp_print (' ', 'BOTH');

      FOR sd IN c_store_deposit
      LOOP
         lc_aba_key := LPAD (TO_CHAR (sd.loc_id), 6, '0');
         ln_loc_id := sd.loc_id;
         ld_sales_date := TRUNC (sd.sales_date);
         lc_status_cd := NVL (sd.status_cd, '~');
         lp_print ('', 'LOG');
         lp_print (gc_line, 'LOG');
         lp_print (   'Process location:'
                   || lc_aba_key
                   || ' / Sales Date:'
                   || ld_sales_date
                 , 'LOG'
                  );
                                fnd_file.put_line (fnd_file.LOG, 'LN_CORPBANK_ACCT_ID : '||LN_CORPBANK_ACCT_ID );
         ln_rec_count := NVL (ln_rec_count, 0) + 1;

         IF ln_rec_count = 1
         THEN
            lp_print (   RPAD (' Store #', 9, ' ')
                      || '  '
                      || RPAD ('Date', 9, ' ')
                      || '  '
                      || 'Error'
                    , 'OUT'
                     );
            lp_print (   LPAD ('-', 9, '-')
                      || '  '
                      || LPAD ('-', 9, '-')
                      || '  '
                      || LPAD ('-', 70, '-')
                    , 'OUT'
                     );
         END IF;

         BEGIN                                             -- Process Store Data
            lc_st_dep_savepoint :='Savepoint-' || ln_loc_id || '-' || ld_sales_date;
            SAVEPOINT lc_st_dep_savepoint;
            -- Get bank data for this store

                                                fnd_file.put_line (fnd_file.LOG, 'Wells -MAIN calling  lp_get_store_data ');

            lp_get_store_data;                  -- Get bank data for this store
            --  Process Store to AR receipts Compare
            --  will not happen if get Store Bank Account data failed.

            lp_print ('Process Store Deposits', 'LOG');

                                                fnd_file.put_line (fnd_file.LOG, 'Wells -MAIN calling  lp_process_store_receipt_os ');
            lp_process_store_receipt_os;                     -- Local Procedure

            lp_print (   LPAD (lc_aba_key, 9, ' ')
                      || '  '
                      || LPAD (ld_sales_date, 9, ' ')
                      || '  Processed.'
                    , 'OUT'
                     );

          --  End Process Store to AR receipts Compare
         EXCEPTION
            WHEN le_exception_translate
            THEN
               lp_print
                  (   LPAD (ld_sales_date, 9, ' ')
                   || '  '
                   || LPAD (lc_aba_key, 9, ' ')
                   || '  Error getting translation value(s). Review log for details.'
                 , 'OUT'
                  );

               ROLLBACK TO lc_st_dep_savepoint;
            WHEN le_exception_bad_store
            THEN
               lc_error_loc := 'Store Deposit LOOP:lp_get_store_data';
               lp_print (lc_error_msg, 'LOG');
               lp_print (   LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || LPAD (lc_aba_key, 9, ' ')
                         || '  Bank account setup incorrectly for store.'
                       , 'OUT'
                        );

               ROLLBACK TO lc_st_dep_savepoint;
            WHEN le_exception_store_accounts
            THEN
               lc_error_loc := 'Store Deposit LOOP:lp_get_store_data';
               lp_print (lc_error_msg, 'LOG');
               lp_print (   LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || LPAD (lc_aba_key, 9, ' ')
                         || '  Multiple bank accounts set up for store.'
                       , 'OUT'
                        );

               ROLLBACK TO lc_st_dep_savepoint;
            WHEN OTHERS
            THEN
               lp_print (   LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || LPAD (lc_aba_key, 9, ' ')
                         || '  Error processing store deposits. '
                         || SQLCODE
                         || '-'
                         || SQLERRM
                       , 'LOG'
                        );
               ROLLBACK TO lc_st_dep_savepoint;
         END;                                          -- End Process Store Data

      END LOOP;                                                                --

      --  Process Bank to Store (Manual) Over/Shorts
      lc_error_loc := 'Store-Bank O/S Loop';
      lp_print ('', 'BOTH');
      lp_print ('', 'BOTH');
      lp_print ('Process Manual/Bank Over-Short(s)', 'BOTH');
      lp_print (gc_line, 'BOTH');
      lp_print ('', 'BOTH');
      ln_rec_count := 0;
-- Updates the PTY Transactions before matching criteria starts
      UPDATE xx_ce_store_bank_deposits xcs
         SET xcs.status_cd = 'B'
       WHERE xcs.deposit_type = 'PTY'
         AND xcs.status_cd IN (
                               SELECT XFTV.TARGET_value1
                                 FROM xx_fin_translatedefinition XFTD
                                      ,xx_fin_translatevalues XFTV
                                WHERE XFTD.translate_id = XFTV.translate_id
                                  AND XFTD.translation_name = gc_trans_name
                                  AND XFTV.source_value1 = 'IN_STATUS_CODE'
                                  AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                  AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                  AND XFTV.enabled_flag = 'Y'
                                  AND XFTD.enabled_flag = 'Y');
                                fnd_file.put_line (fnd_file.LOG,'ROWS UPDATED- '||       SQL%ROWCOUNT ||  '   Wells -MAIN updating status = B  for PTY Deposit');

      COMMIT;

      FOR sdb IN c_store_deposit_bank       -- All POS/SA deposit lines that are
      LOOP                                    -- not 'PTY' or 'CHG' deposit type
                                              -- and status code = 'S'
      FOR cds IN c_check_db_status(sdb.sales_date , sdb.loc_id
      , sdb.status_cd , sdb.serial_num , sdb.amount
      , sdb.seq_nbr , sdb.deposit_type )
      LOOP
        lp_print ('', 'LOG');
                                lp_print ('', 'LOG');


                                lp_print ( 'MAIN starting c_store_deposit_bank and c_check_db_status cursors ','LOG');
                                lp_print ( 'LN_CORPBANK_ACCT_ID : '||LN_CORPBANK_ACCT_ID, 'LOG' );

         BEGIN
            lc_flag := 'N';
            lc_aba_key := LPAD (TO_CHAR (sdb.loc_id), 6, '0');
                                                lc_error_loc :=Null;
            ln_loc_id := sdb.loc_id;
            ld_sales_date := TRUNC (sdb.sales_date);
            lc_status_cd := NVL (sdb.status_cd, '~');
            lc_serial_num := LPAD (sdb.serial_num, 4, '0');
            lc_serial_loc := lc_serial_num || SUBSTR (lc_aba_key, 3, 4);
            ln_store_amount := sdb.amount;
            ln_store_deposit_seq_nbr := sdb.seq_nbr;

            IF (NVL(sdb.SERIAL_NUM,'NULL') IN ('NULL','0','00','000','0000')) THEN

                lp_print(sdb.SERIAL_NUM,'BOTH');

                NULL_SER_NUM_REPLACE;  -- Calling the procedure - NULL_SER_NUM_REPLACE
            END IF;

            lp_print (' ', 'LOG');
                                                lp_print ('gn_org_id '||gn_org_id, 'LOG');

            lp_print (gc_line, 'LOG');
            lp_print ('Location: ' || ln_loc_id || '/ Sales date:'
                      || ld_sales_date
                    , 'LOG'
                     );
            lc_sdb_savepoint :=
                  'Savepoint_'
               || ln_loc_id
               || '-'
               || ld_sales_date
               || '-'
               || lc_serial_num
               || '-'
               || ln_store_deposit_seq_nbr;

            SAVEPOINT lc_sdb_savepoint;
            ln_rec_count := NVL (ln_rec_count, 0) + 1;
            lp_print (' ln_rec_count :: '||ln_rec_count, 'LOG');

            IF ln_rec_count = 1
            THEN

               lp_print (   RPAD (' Store #', 9, ' ')
                         || '  '
                         || RPAD (' Sales Date', 11, ' ')
                         || '  '
                         || RPAD (' Bank Stmt Date', 15, ' ')
                         || '  '
                         || LPAD (' Seq #', 9, ' ')
                         || '   Error'
                       , 'OUT'
                        );
               lp_print (   LPAD ('-', 9, '-')
                         || '  '
                         || LPAD ('-', 11, '-')
                         || '  '
                         || LPAD ('-', 15, '-')
                         || '  '
                         || LPAD ('-', 9, '-')
                         || '  '
                         || LPAD ('-', 50, '-')
                       , 'OUT'
                        );
            END IF;

            -- Get bank data for this store
            lp_print (' lp_get_store_data :: '||lc_error_loc, 'LOG');
            lp_get_store_data;

            lp_print ('lp_get_store_data :: '||lc_error_loc, 'LOG');
            BEGIN                --  MATCH TO BAI DEPOSIT
                                 --  Get statement lines with dff15 blank
                                 --  If 'MIS' type just set up for GL creation.
                                 --  If other type then do the
                                 --  NOTE:  The 2 may change to a 1 or an alpha.
            lp_print (' lc_flag :: '||lc_flag, 'LOG');

                                                lp_print (' ln_bank_account_id :: '||ln_bank_account_id, 'LOG');
                                                lp_print (' lc_aba_key / Store Location :: '||lc_aba_key, 'LOG');

               IF lc_flag = 'N' THEN
                  BEGIN
                     SELECT /*+ leading(csh) ordered use_nl(csh,csl,ctc) index(csl,CE_STATEMENT_LINES_N1) index(CSH,CE_STATEMENT_HEADERS_U2) */
                                                                                        csl.amount
                           ,csl.statement_line_id
                           ,csl.trx_code_id
                           ,csl.trx_code
                           ,csl.bank_trx_number
                           ,csl.statement_header_id
                           ,csl.invoice_text
                           ,csl.bank_account_text
                           ,csl.customer_text
                           ,csl.trx_date
                           ,csh.statement_date
                       INTO ln_csl_deposit_amt
                           ,ln_csl_statement_line_id
                           ,ln_csl_trx_code_id
                                                                                                                ,ln_csl_trx_code
                           ,lc_csl_bank_trx_number
                           ,ln_csl_statement_header_id
                           ,lc_csl_invoice_text
                           ,lc_csl_bank_account_text
                           ,lc_csl_customer_text
                           ,ld_csl_trx_date
                           ,ld_bank_statement_date
                      FROM ce_statement_headers csh
                          ,ce_statement_lines csl
                          ,ce_transaction_codes ctc
                     WHERE csl.attribute15 is null
                       AND csl.statement_header_id = csh.statement_header_id
                                                                                   AND csh.bank_account_id =LN_CORPBANK_ACCT_ID
                       AND LPAD(TO_CHAR(ln_loc_id),9,'0') = SUBSTR (csl.CUSTOMER_TEXT,3)
                                                                                   AND csl.status!='RECONCILED'
                                                                                   AND csl.trx_code = ctc.trx_code
                       AND ctc.bank_account_id = ln_bank_account_id
                       AND ctc.reconcile_flag = 'OI'
                       AND csl.amount = ln_store_amount
                       AND rownum = 1;

                       lc_flag := 'Y';
                       lc_match_type := 'Exact Amount Match!';

                                                                                lp_print (' lc_match_type :: '||lc_match_type, 'LOG');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                                                                                                lp_print (' Exact MAtch :: '||SQLERRM, 'LOG');
                  END;
               END IF;

                                                                lp_print (' lc_flag 1 :: '||lc_flag, 'LOG');

               IF lc_flag = 'N' THEN
                  BEGIN
                     SELECT SUM (pd.amount) total_amount
                       INTO ln_sum_cash_check_deposits
                       FROM xx_ce_store_bank_deposits pd
                      WHERE NVL (pd.status_cd, '~') = (
                                            SELECT XFTV.TARGET_value1
                                              FROM xx_fin_translatedefinition XFTD
                                                   ,xx_fin_translatevalues XFTV
                                             WHERE XFTD.translate_id = XFTV.translate_id
                                               AND XFTD.translation_name = gc_trans_name
                                               AND XFTV.source_value1 = 'IN_STATUS_CODE'
                                               AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                               AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                               AND XFTV.enabled_flag = 'Y'
                                               AND XFTD.enabled_flag = 'Y')
                        AND pd.loc_id = ln_loc_id
                        AND pd.deposit_type IN (SELECT XFTV.TARGET_value1
                                                  FROM xx_fin_translatedefinition XFTD
                                                      ,xx_fin_translatevalues XFTV
                                                WHERE XFTD.translate_id = XFTV.translate_id
                                                  AND XFTD.translation_name = gc_trans_name
                                                  AND XFTV.source_value1 = 'MULTI_MATCH'
                                                  AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                                  AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                                  AND XFTV.enabled_flag = 'Y'
                                                  AND XFTD.enabled_flag = 'Y')
                                                                                                AND pd.sales_date = ld_sales_date;

                     lp_print (' ld_sales_date :: '||ld_sales_date, 'LOG');

                    lp_print ('lc flag is N :: '||lc_error_loc, 'LOG');
                     SELECT  /*+ leading(csh) ordered use_nl(csh,csl,ctc) index(csl,CE_STATEMENT_LINES_N1) index(CSH,CE_STATEMENT_HEADERS_U2) */
                                                                                        csl.amount
                           ,csl.statement_line_id
                           ,csl.trx_code_id
                                                                                                   ,csl.trx_code
                           ,csl.bank_trx_number
                           ,csl.statement_header_id
                           ,csl.invoice_text
                           ,csl.bank_account_text
                           ,csl.customer_text
                           ,csl.trx_date
                           ,csh.statement_date
                       INTO ln_csl_deposit_amt
                           ,ln_csl_statement_line_id
                           ,ln_csl_trx_code_id
                                                                                                   ,ln_csl_trx_code
                           ,lc_csl_bank_trx_number
                           ,ln_csl_statement_header_id
                           ,lc_csl_invoice_text
                           ,lc_csl_bank_account_text
                           ,lc_csl_customer_text
                           ,ld_csl_trx_date
                           ,ld_bank_statement_date
                       FROM ce_statement_headers csh
                           ,ce_statement_lines csl
                           ,ce_transaction_codes ctc
                      WHERE csl.attribute15 is null
                        AND csl.statement_header_id = csh.statement_header_id
                                                                                                AND csh.bank_account_id =LN_CORPBANK_ACCT_ID
                        AND LPAD(TO_CHAR(ln_loc_id),9,'0') = SUBSTR (csl.CUSTOMER_TEXT,3)
                                                                                                AND csl.status!='RECONCILED'
                                                                                                AND csl.trx_code = ctc.trx_code
                        AND ctc.bank_account_id = ln_bank_account_id
                        AND ctc.reconcile_flag = 'OI'
                        AND csl.amount = ln_sum_cash_check_deposits
                        AND rownum = 1;

                                                                                   lc_flag := 'Y';
                       lc_match_type := 'Multi Amount Match!';

                                                                                   lp_print (' lc_match_type 1 :: '||lc_match_type, 'LOG');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                                                                                                lp_print (' error Finding Multi Match :: '||SQLERRM, 'LOG');
                        NULL;
                  END;
               END IF;

            lp_print (' lc_flag 2 :: '||lc_flag, 'LOG');
               IF lc_flag = 'N' THEN
                  BEGIN
                     SELECT  /*+ leading(csh) ordered use_nl(csh,csl,ctc) index(csl,CE_STATEMENT_LINES_N1) index(CSH,CE_STATEMENT_HEADERS_U2) */
                                                                                        csl.amount
                           ,csl.statement_line_id
                           ,csl.trx_code_id
                                                                                                   ,csl.trx_code
                           ,csl.bank_trx_number
                           ,csl.statement_header_id
                           ,csl.invoice_text
                           ,csl.bank_account_text
                           ,csl.customer_text
                           ,csl.trx_date
                           ,csh.statement_date
                       INTO ln_csl_deposit_amt
                           ,ln_csl_statement_line_id
                           ,ln_csl_trx_code_id
                                                                                                   ,ln_csl_trx_code
                           ,lc_csl_bank_trx_number
                           ,ln_csl_statement_header_id
                           ,lc_csl_invoice_text
                           ,lc_csl_bank_account_text
                           ,lc_csl_customer_text
                           ,ld_csl_trx_date
                           ,ld_bank_statement_date
                       FROM ce_statement_headers csh
                           ,ce_statement_lines csl
                           ,ce_transaction_codes ctc
                      WHERE csl.attribute15 is null
                        AND csl.statement_header_id = csh.statement_header_id
                                                                                                AND csh.bank_account_id =LN_CORPBANK_ACCT_ID
                                                                                                AND csl.status!='RECONCILED'
                             AND csl.trx_code = ctc.trx_code
                        AND ctc.bank_account_id = ln_bank_account_id
                        AND ctc.reconcile_flag = 'OI'
                        AND ((SUBSTR (csl.invoice_text
                                     , LENGTH (csl.invoice_text) - 8
                                        , 9
                                      ) = lc_serial_loc || '2'
                              )
                              OR (SUBSTR (csl.invoice_text
                                     , LENGTH (csl.invoice_text) - 7
                                        , 8
                                         ) = lc_serial_loc
                                  )
                            )
                        AND (TRUNC (csl.trx_date) BETWEEN ld_sales_date
                                                 AND ld_sales_date + ln_days)
                        AND rownum = 1;
                        lc_flag := 'Y';
                        lc_match_type := 'Serial Number Match!';

                                                                                lp_print (' lc_match_type 2 :: '||lc_match_type, 'LOG');
                     ln_deposit_bank_difference :=
                                            ln_csl_deposit_amt - ln_store_amount;

                     SELECT XFTV.TARGET_value2
                            ,XFTV.TARGET_value3
                       INTO lc_trans_seg_acct
                            ,lc_trans_seg_cost
                       FROM xx_fin_translatedefinition XFTD
                            ,xx_fin_translatevalues XFTV
                      WHERE XFTD.translate_id = XFTV.translate_id
                        AND XFTD.translation_name = gc_trans_name
                        AND XFTV.source_value2 = 'DIFFERENCE'
                        AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                        AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                        AND XFTV.enabled_flag = 'Y'
                        AND XFTD.enabled_flag = 'Y';

                                                                                lp_print (' ln_deposit_bank_difference :: '||ln_deposit_bank_difference, 'LOG');
                     -- Create GL entries if there is an over/short condition
                     IF ln_deposit_bank_difference = 0
                     THEN
                        NULL;

                     ELSIF ln_deposit_bank_difference < 0
                     THEN
                        -- Bank deposit was lesser than store recorded deposit so
                        -- Debit store over/short manual acct for difference
                        lc_seg_acct := lc_trans_seg_acct;
                        lc_seg_cost := lc_trans_seg_cost;

                                                                                                lp_print (' lc_aba_key :: '||lc_aba_key, 'LOG');
                        lc_seg_loc := lc_aba_key;
                        lc_je_line_dsc :=
                              lc_seg_loc
                           || '/'
                           || TO_CHAR (ld_sales_date, 'DD-MON-RR')
                           || '/'
                           || ' BK2 POS OvrShrt';
                        lp_print ('Before lp_create_gl :: '||lc_error_loc, 'LOG');
                        lp_create_gl (ABS (ln_deposit_bank_difference)
                                    , 0
                                    , ld_sales_date
                                    , lc_je_line_dsc
                                     );
                                                                                                lp_print (' After lp_create_gl 1 :: '||lc_error_loc, 'LOG');

                        lc_seg_acct := lc_store_cash_clearing;
                        lc_seg_cost := lc_store_seg_cost;

                        lp_create_gl (0
                                    , ABS (ln_deposit_bank_difference)
                                    , ld_sales_date
                                    , lc_je_line_dsc
                                     );
                        lp_print('lc_seg_cost:'||lc_seg_cost,'BOTH');
                                                                                                lp_print (' After lp_create_gl 2 :: '||lc_error_loc, 'LOG');
                     ELSE
                        -- Bank deposit was greater than store recorded deposit so
                        -- Crebit store over/short manual acct for difference
                        lc_seg_loc := lc_aba_key;
                        lc_je_line_dsc :=
                              lc_seg_loc
                           || '/'
                           || TO_CHAR (ld_sales_date, 'DD-MON-RR')
                           || '/'
                           || ' BK2 POS OvrShrt';


                                                                                                lp_print (' Before lp_create_gl 2 :: '||lc_error_loc, 'LOG');
                        lp_create_gl (0
                                    , ABS (ln_deposit_bank_difference)
                                    , ld_sales_date
                                    , lc_je_line_dsc
                                     );

                                                                                                lp_print (' After lp_create_gl 3 :: '||lc_error_loc, 'LOG');
                        lc_seg_acct := lc_store_cash_clearing;
                        lc_seg_cost := lc_store_seg_cost;

                        lp_create_gl (ABS (ln_deposit_bank_difference)
                                    , 0
                                    , ld_sales_date
                                    , lc_je_line_dsc
                                     );
                                                                                                lp_print (' After lp_create_gl 4 :: '||lc_error_loc, 'LOG');
                        lp_print('lc_seg_cost:'||lc_seg_cost,'BOTH');
                     END IF;            --  End of there was a difference amount
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        RAISE le_exception_no_match;
                  END;                              --   MATCH OTHER TRANS TYPES
               END IF;          --  End of MIS trans type or other deposit type.

               /* -- -------------------------------------------
                  -- Now call the Create Open Interface
                  -- Procedure to create the record in the
                  -- XX_CE_999_INTERFACE custom table
                  -- for reconciliation and update the
                  -- CE.CE_STATEMENT_LINES table with necessary
                  -- values for matching.
                  -- ------------------------------------------- */
               lp_print (' create_open_interface :: ', 'LOG');

               create_open_interface
                           (
                                                                                                                p_trx_code_id => ln_csl_trx_code_id
                                                                                                  , p_trx_code => ln_csl_trx_code
                          , p_bank_trx_number_org => lc_csl_bank_trx_number
                          , p_statement_header_id => ln_csl_statement_header_id
                          , p_statement_line_id => ln_csl_statement_line_id
                          , p_record_type => 'STORE_O/S'
                          , p_trx_date => ld_csl_trx_date
                          , p_amount => ln_csl_deposit_amt
                          , x_errbuf => lc_error_msg
                          , x_retcode => ln_retcode
                           );
               lp_print ('Passed to 999 Interface'||lc_error_loc, 'LOG');

               lc_error_loc := 'Update store_bank_deposits in ' || lc_match_type;

               lp_print (' lc_error_loc :: '||lc_error_loc, 'LOG');

               IF(lc_match_type = 'Multi Amount Match!') THEN
                  UPDATE xx_ce_store_bank_deposits pd
                     SET status_cd = 'B'
                   WHERE pd.loc_id = ln_loc_id
                     AND pd.deposit_type IN (SELECT XFTV.TARGET_value1
                                               FROM xx_fin_translatedefinition XFTD
                                                   ,xx_fin_translatevalues XFTV
                                              WHERE XFTD.translate_id = XFTV.translate_id
                                                AND XFTD.translation_name = gc_trans_name
                                                AND XFTV.source_value1 = 'MULTI_MATCH'
                                                AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                                AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                                AND XFTV.enabled_flag = 'Y'
                                                AND XFTD.enabled_flag = 'Y')
                     AND TRUNC (pd.sales_date) = ld_sales_date;
               ELSE
                  UPDATE xx_ce_store_bank_deposits
                     SET status_cd = 'B'
                   WHERE seq_nbr = ln_store_deposit_seq_nbr;
               END IF;

               lp_print (   LPAD (lc_aba_key, 9, ' ')
                         || '  '
                         || LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || LPAD (ld_bank_statement_date, 14, ' ')
                         || '  '
                         || LPAD (ln_store_deposit_seq_nbr, 8, ' ')
                         || '  '
                         || LPAD ('Processed',13, ' ')
                         || '  '
                         || lc_match_type
                       , 'BOTH'
                        );

               lc_error_loc := 'Store-Bank O/S Loop';
            END;                                 --  End of MATCH TO BAI DEPOSIT
         EXCEPTION
            WHEN le_exception_bad_store
            THEN
               lc_error_loc := lc_error_loc || ':lp_get_store_data';
               lp_print (lc_error_msg, 'BOTH');

               lc_error_loc := 'Store-Bank O/S Loop';
               lp_print (   LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || LPAD (lc_aba_key, 9, ' ')
                         || '  '
                         || '               '
                         || LPAD (ln_store_deposit_seq_nbr, 9, ' ')
                         || '      Bank account setup incorrectly for store.'
                       , 'OUT'
                        );
               ROLLBACK TO lc_sdb_savepoint;
            WHEN le_exception_store_accounts
            THEN
               lc_error_loc := lc_error_loc || ':lp_get_store_data';
               lp_print (lc_error_msg, 'BOTH');

               lc_error_loc := 'Store-Bank O/S Loop';
               lp_print (   LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || LPAD (lc_aba_key, 11, ' ')
                         || '  '
                         || '               '
                         || LPAD (ln_store_deposit_seq_nbr, 9, ' ')
                         || '      Multiple bank accounts set up for store.'
                       , 'OUT'
                        );
               ROLLBACK TO lc_sdb_savepoint;
            WHEN le_exception_no_match
            THEN                        --  That's OK since deposit may not have
                                        --  gotten to ce_statement_lines yet.
               lp_print ('Store bank deposit match not found.', 'LOG');
               lp_print ( LPAD (lc_aba_key, 9, ' ')
                         || '  '
                         ||LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || '               '
                         || LPAD (ln_store_deposit_seq_nbr, 9, ' ')
                         || '      Store bank deposit match not found'
                       , 'OUT'
                        );
               ROLLBACK TO lc_sdb_savepoint;
            WHEN OTHERS
            THEN
               lp_print (   LPAD (ld_sales_date, 9, ' ')
                         || '  '
                         || LPAD (lc_aba_key, 9, ' ')
                         || '  '
                         || '      Error processing Store bank deposit -'
                         || SQLCODE
                         || '-'
                         || SQLERRM
                         || '  Rolling back to savepoint '
                         || lc_sdb_savepoint
                       , 'LOG'
                        );
               ROLLBACK TO lc_sdb_savepoint;
         END;              -- End of process block for c_store_bank_deposit loop
      END LOOP;
      END LOOP;                             --  End of c_store_bank_deposit loop

      lp_print (' ', 'LOG');
      x_retcode := ln_normal;
      lp_print ('Finished ' || TO_CHAR (SYSDATE, 'dd-mon-yyyy hh:mi:ss'), 'LOG');
   EXCEPTION

      WHEN OTHERS
      THEN
         ROLLBACK;
         x_retcode := ln_error;
         lc_error_loc := lc_error_loc || ' - Main procedure exception';
         lp_print (lc_error_msg, 'BOTH');
         lp_log_comn_error ('STORE OVER/SHORT - CC', 'Unresolved');
   END store_os_cc_main;
END XX_CE_STORE_OS_WLFG_PKG;    
/