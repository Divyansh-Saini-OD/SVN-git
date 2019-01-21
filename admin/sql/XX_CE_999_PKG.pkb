create or replace 
PACKAGE BODY ce_999_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Providge Consulting                                  |
-- +=================================================================================+
-- | Name       : XX_CE_999_PKG.pkb                                                  |
-- | Description: OD Reconciliation Open  Interface Package                          |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version  Date         Authors            Remarks                                 |
-- |=======  ===========  ===============    ============================            |
-- |1.0      07-AUG-2007  Terry Banks        Initial version                         |
-- |1.1      13-SEP-2007  Terry Banks        Changed lockbox cursor for batches to   |
-- |                                         use lockbox_batch_name.                 |
-- |1.2      24-OCT-2007  Terry Banks        Changes for Change Request to take      |
-- |                                         care of changes to  credit card recon   |
-- |                                         around chargeback processing.           |
-- |1.3      27-NOV-2007  Terry Banks        Changes for new processing by Order     |
-- |                                         Management to provide unique ties to    |
-- |                                         the cash receipt and for card type      |
-- |                                         and other misc. changes.                |
-- |1.4      17-DEC-2007  Terry Banks        Revised chargeback (AJB996 processing   |
-- |                                         to ignore chargeback types that Jane    |
-- |                                         Bily said should not be used.           |
-- |1.5      06-FEB-2008  Terry Banks        LNK test corrections incl defect 3975   |
-- |1.6      26-FEB-2008  Terry Banks        Changes for CR 319                      |
-- |1.7      28-Mar-2008  Deepak Gowda       CR319 Defect 5821 - Added Locking when  |
-- |                                           clearing Lockbox Receipts. Update     |
-- |                                           only interface lines that map to a    |
-- |                                           statement line.                       |
-- |1.8      15-May-2008  Deepak Gowda      CR382 Defect 6182 - Re-wrote Chargeback  |
-- |                                        handling process lp_process_996s.Modified|
-- |                                        logging and output.                      |
-- |1.9      05-Jun-2008  Deepak Gowda      When creating receipt for negative CB,   |
-- |                                        if receipt and inv nums are null use 'CB'|
-- |2.0      24-Jun-2008  Deepak Gowda      Updated log and outputs improve clarity  |
-- |                                        Defect 8436- Lock ar_cash_receipts and   |
-- |                                        receipt_history before clearing receipt  |
-- |                                        If len(receipt num) < 30 use entire value|
-- |2.1      26-Jun-2008  Deepak Gowda      Removed locking when selecting from views|
-- |                                        XX_CE_AJB996_AR_V and XX_CE_AJB998_AR_V  |
-- |2.2      27-Jun-2008  Deepak Gowda      Remove re-processing of errored receipts |
-- |2.3      10-Jul-2008  Deepak Gowda      Defect 8656-When clearing the OD Custom  |
-- |                                         $0 receipts for refunds, update the cash|
-- |                                        and clearing accounts in AR distributions|
-- |                                         with the AJB transaction amount         |
-- |2.4      10-Jul-2008  Deepak Gowda      Defect 8722-Log message if receipt is    |
-- |                                         already cleared/reversed-do not clear   |
-- |                                         again                                   |
-- |2.5      20-Aug-2008  Deepak Gowda      Defect 10089-When no receipt number is   |
-- |                                        received from provider, all receipts are |
-- |                                        being created as 'CB' instead of 'CB-nnn |
-- |2.6      14-Jul-2009  Pradeep Krishnan  Defect 736 - Fixed the save point which  |
-- |                                        which was wrongly defined and referred   |
-- |                                        to.                                      |
-- |2.7      28-Aug-2009  Hemalatha S       PROD Defect: 1716,2046                   |
-- |                                        Commented NULL and selected              |
-- |                                        default_customer_id from                 |
-- |                                        xx_ce_recon_glact_hdr when the header id |
-- |                                        is not null while creating debit memo.   |
-- |2.8      22-JUN-2009  Jude Felix .A     PROD Defect: 4721                        |
-- |                                        Added Logic to Create Zero Dollar        |
-- |                                        Receipts for the Corresponding non Zero  |
-- |                                        Dollar Receipt                           |
-- |                                                                                 |
-- |2.9      20-APR-2011  Sreenivasa T      Modified the package as per the SDR      |
-- |                                        changes to update XX_AR_ORDER_RECEIPT_DTL|
-- |                                        table, if a record exists in the above   |
-- |                                        table,else we proceed with standard way  |
-- |         11-May-2011  Gaurav Agarwal    expenses_complete flag is replaced by    |
-- |                                        x999_gl_complete.          ..............|
-- |                                        As per the discussion WRT to SDR project,|
-- |                                        Commented XX_CE_999_INTERFACE table cols |
-- |                                        such as chargebacks_complete             |
-- |                                        and chargebacks_processed_ctr from all   |
-- |                                        UPDATE and SELECT Statements related to  |
-- |                                        the 999 Interface Table.                 |
-- |         30-Jun-2011  Gaurav Agarwal    expenses_complete flag logic is changed  |
-- |                                        for defect 12407. expenses_complete flag |
-- |                                        will  be replaced with x999_gl_complete only
-- |                                        for where 999.RECORD_TYPE = 'AJB'        |
-- | 2.10    30-Nov-2011  Abdul Khan        Added logic for Zero Dollar Receipts     |
-- |                                        QC Defect # 13263                        |
-- |2.11     21-Sep-2013  Vivek Seethamraju Incorporated changes to fix CRP2 defect  |
-- |                                        25092                                    |
-- |2.12     11-Jul-2013  P. Lohiya         AutoReconciliation running long          |
-- |2.13     19-MAR-2015  Shravya Gattu     EVENT_ID not populating for CLEARED	     |
-- |					    LOCKBOX RECEIPTS.Defect#31832.	     |
-- |2.14     30-SEP-2015  John Wilson       Code modified for the defect # 35794     |   
-- |2.15     28-Oct-2015  Avinash Baddam    R12.2 Compliance changes  		     |
-- |2.16     30-apr-2018  Abhishek Kumar    Debug profile added for the defect #43970|
-- +=================================================================================+

-- +=================================================================================+
-- |Name        :                                                                    |
-- | Description : This procedure will be used to process the                        |
-- |               Reconciliation Open Interface records that                        |
-- |               CE Autoreconciliation matched with rows in                        |
-- |               CE_STATEMENT_LINES so they can be reconciled.                     |
-- |               NOTE: The Oracle package specification for                        |
-- |               CE_999_PKG is kept and the structure of this                      |
-- |               package is matched to it.  There is no need to                    |
-- |               have a custom package specification.                              |
-- |                                                                                 |
-- | Parameters  : None                                                              |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- +=================================================================================+
--
/* ---------- Declarations  --------------------------------- */
   PG_DEBUG varchar2(10) := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');
   v_cash_receipt_num               VARCHAR2 (20);
   v_cash_receipt_id                NUMBER;
   v_ce_dm_rec                      xx_ce_chargeback_dm%ROWTYPE;
   v_concurrent_request_id          fnd_concurrent_requests.request_id%TYPE;
   v_receipt_pay_from_customer_id   NUMBER;
   v_trx_id                         NUMBER;
   v_iface_rec                      xx_ce_999_interface%ROWTYPE;
   v_996_rec                        xx_ce_ajb996_ar_v%ROWTYPE;
   v_996_ar_v_rec                   xx_ce_ajb996_ar_v%ROWTYPE;
   v_998_ar_v_rec                   xx_ce_ajb998_ar_v%ROWTYPE;
   v_error_loc                      VARCHAR2 (50);
   v_error_sub_loc                  VARCHAR2 (50);
   v_error_msg                      VARCHAR2 (2000);
   v_996_all_ok                     VARCHAR2 (1);
   v_998_all_ok                     VARCHAR2 (1);
   v_999_iface_rowid                ROWID;
   v_exception_apply_receipt        EXCEPTION;
   v_exception_clear_receipt        EXCEPTION;
   v_exception_create_dm            EXCEPTION;
   v_exception_create_receipt       EXCEPTION;
   v_exception_bad_store_os         EXCEPTION;
   v_exception_bad_ajb              EXCEPTION;
   v_exception_bad_lbox             EXCEPTION;
   v_exception_bad_vset             EXCEPTION;
   v_exception_gl_call              EXCEPTION;
   v_exception_996_receipt          EXCEPTION;
   v_exception_upd_999              EXCEPTION;
   v_exception_upd_csl              EXCEPTION;
   le_invalid_batch_info            EXCEPTION;
   v_gl_output_msg                  VARCHAR2 (1000);
   v_group_id                       NUMBER;
   v_recon_jrnl_id                  NUMBER;
   v_user_id                        NUMBER               := fnd_global.login_id;
   v_oracle_error_msg               VARCHAR2 (1000);
   v_print_line                     VARCHAR2 (2000);
   v_temp_print                     VARCHAR2 (30);
   gn_batch_id                      NUMBER;
   g_line                           VARCHAR2 (150)      := RPAD ('-', 120, '-');

   --  Cursor lc_iface_cur retrieves the single 999-Iface row
   --  that was sent to this program by CE Auto Recon.  Using the
   --  ce_statement_line_id stored in vset_group_id we can then
   --  retrieve all 999-Iface rows in cursor lc_ajb998r_vgrp
   --  to then get their 996/998 data.
   --
   --  NOTE: The join to ce_statement_headers makes
   --        this select act as if the interface table
   --        were multi-org enabled.
   --
   CURSOR lc_iface_cur
   IS
      SELECT xc.*
        FROM xx_ce_999_interface xc, ce_statement_headers csh
       WHERE xc.trx_id = v_trx_id
         AND NVL (xc.deposits_matched, '~') = 'Y'
         --AND NVL (xc.expenses_complete, '~') = 'Y'
         --  AND NVL (xc.x999_gl_complete, '~') = 'Y' -- added by Gaurav Agarwal commneted by Gaurav on 30-Jun-2011
           AND decode( xc.RECORD_TYPE,'AJB', NVL (xc.x999_gl_complete, '~'), NVL (xc.expenses_complete, '~')) = 'Y' -- Added by Gaurav Agarwal on 30-Jun-2011
         AND csh.statement_header_id = xc.statement_header_id;

   -- Cursor lc_get_gl_jrnl retrieves the GL journal entries produced
   -- by E1310 Matching Form.  They are grouped by group_id, which
   -- ties them together by provider, bank_rec_id and statement line.
   -- Only those that have not been sent to the GL staging table
   -- and have had the AJB999 fees and discounts processed are selected.
   --
   /*CURSOR lc_get_gl_jrnl
   IS
      SELECT     a.*
            FROM xx_ce_recon_jrnl a, xx_ce_999_interface b
           WHERE 1 = 1
             AND a.statement_line_id = b.GROUP_ID
             AND a.sent_to_gl_flag = 'N'
             AND b.GROUP_ID = v_iface_rec.GROUP_ID
      FOR UPDATE;
     */
   PROCEDURE lp_print (lp_line IN VARCHAR2, lp_both IN VARCHAR2)
   IS
   BEGIN
      IF fnd_global.conc_request_id () > 0
      THEN
         CASE
            WHEN UPPER (lp_both) = 'BOTH'
            THEN
               fnd_file.put_line (fnd_file.LOG, lp_line);
               fnd_file.put_line (fnd_file.output, lp_line);
            WHEN UPPER (lp_both) = 'LOG'
            THEN
               fnd_file.put_line (fnd_file.LOG, lp_line);
            ELSE
               fnd_file.put_line (fnd_file.output, lp_line);
         END CASE;
      ELSE
         DBMS_OUTPUT.put_line (lp_line);
      END IF;
   END;                                                              -- lp_print

   PROCEDURE lp_get_gl_group_id
   IS
   BEGIN
      SELECT gl_interface_control_s.NEXTVAL
        INTO v_group_id
        FROM DUAL;
   END;

   FUNCTION lf_derive_lob (lfv_location IN VARCHAR2, lfv_cost_center IN VARCHAR2)
      RETURN VARCHAR2
   IS
      lfv_lob             gl_code_combinations.segment7%TYPE;
      lfv_error_message   VARCHAR2 (200);
   BEGIN
      xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc (lfv_location
                                                         , lfv_cost_center
                                                         , lfv_lob
                                                         , lfv_error_message
                                                          );

      IF lfv_error_message IS NOT NULL
      THEN
         lfv_lob := -1;
      END IF;

      RETURN (NVL (lfv_lob, -1));
   END;

   PROCEDURE lp_create_gl (
      lpv_dr                IN   NUMBER
    , lpv_cr                IN   NUMBER
    , lpv_set_of_books_id   IN   NUMBER
    , lpv_accounting_date   IN   DATE
    , lpv_currency_code     IN   VARCHAR2
    , lpv_seg_co            IN   VARCHAR2
    , lpv_seg_cost          IN   VARCHAR2
    , lpv_seg_acct          IN   VARCHAR2
    , lpv_seg_loc           IN   VARCHAR2
    , lpv_seg_ic            IN   VARCHAR2
    , lpv_reference10       IN   VARCHAR2
   )
   /*-- -------------------------------------------
     -- Call the GL Common Package to create
     -- Gl Interface records
     -- -----------------------------------------*/
   IS
      lpv_char_date   VARCHAR2 (20);
      lpv_seg_lob     VARCHAR2 (20);
   BEGIN
      lpv_char_date := TO_CHAR (lpv_accounting_date, 'YYYY-MM-DD');
      --  Call function to get line of business
      lpv_seg_lob := lf_derive_lob (lpv_seg_loc, lpv_seg_cost);
      --  Call GL package to create the GL entry
      xx_gl_interface_pkg.create_stg_jrnl_line
                                     (p_status => 'NEW'
                                    , p_date_created => SYSDATE
                                    , p_created_by => v_user_id
                                    , p_actual_flag => 'A'
                                    , p_group_id => v_group_id
                                    , p_batch_name => lpv_char_date
                                    --reference1
      ,                               p_batch_desc => ' '
                                    --reference2
      ,                               p_user_source_name => 'OD CM Lockbox'
                                    , p_user_catgory_name => 'Miscellaneous'
                                    , p_set_of_books_id => lpv_set_of_books_id
                                    , p_accounting_date => lpv_accounting_date
                                    , p_currency_code => lpv_currency_code
                                    , p_company => lpv_seg_co
                                    , p_cost_center => lpv_seg_cost
                                    , p_account => lpv_seg_acct
                                    , p_location => lpv_seg_loc
                                    , p_intercompany => lpv_seg_ic
                                    , p_channel => lpv_seg_lob
                                    , p_future => '000000'
                                    , p_entered_dr => lpv_dr
                                    , p_entered_cr => lpv_cr
                                    , p_je_name => NULL
                                    , p_je_line_dsc => lpv_reference10
                                    , x_output_msg => v_gl_output_msg
                                     );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_oracle_error_msg := SQLERRM;
         v_error_loc := 'LP_CREATE_GL: ' || v_error_loc;
         RAISE v_exception_gl_call;
   END;                                          -- lp_create_gl local procedure

   PROCEDURE lp_log_comn_error (
      lp_object_type   IN   VARCHAR2
    , lp_object_id     IN   VARCHAR2
   )
   IS
   BEGIN
      fnd_message.set_name ('XXFIN', 'CE_AUTO_RECONCILIATION_OPEN_INTERFACE');
      fnd_message.set_token ('ERR_LOC', v_error_loc || v_error_sub_loc);
      fnd_message.set_token ('ERR_ORA', v_oracle_error_msg);
      xx_com_error_log_pub.log_error
                 (p_program_type => 'CONCURRENT PROGRAM'
                , p_program_name => 'CE: Auto Reconciliation - Open Interface'
                , p_program_id => fnd_global.conc_program_id
                , p_module_name => 'CE'
                , p_error_location => 'Error at ' || v_error_loc
                   || v_error_sub_loc
                , p_error_message_count => 1
                , p_error_message_code => 'E'
                , p_error_message => NVL (v_error_msg, v_oracle_error_msg)
                , p_error_message_severity => 'Major'
                , p_notify_flag => 'Y'
                , p_recipient => ''
                , p_object_type => lp_object_type
                , p_object_id => lp_object_id
                 );
   END;                                                     -- lp_log_comn_error

   FUNCTION lf_get_country (fv_number_country IN VARCHAR2)
      RETURN VARCHAR2
   IS
      fv_alpha_country   VARCHAR2 (2) := 'US';                   -- Default it.
   BEGIN
      SELECT a.territory_code
        INTO fv_alpha_country
        FROM fnd_territories a
       WHERE a.iso_numeric_code = fv_number_country;

      RETURN (fv_alpha_country);
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN (fv_alpha_country);
   END;                                                        -- lf_get_country

   FUNCTION lf_get_currency (fv_number_currency IN VARCHAR2)
      RETURN VARCHAR2
   IS
      fv_alpha_currency   VARCHAR2 (15) := 'USD';                -- Default it.
   BEGIN
      SELECT a.currency_code
        INTO fv_alpha_currency
        FROM fnd_currencies a
       WHERE a.attribute1 = fv_number_currency;

      RETURN (fv_alpha_currency);
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN (fv_alpha_currency);
   END;                                                       -- lf_get_currency

   PROCEDURE lp_get_dm_trx_type_ids (
      p_header_id           IN       NUMBER
    , p_processor_id        IN       VARCHAR2
    , p_trx_date            IN       DATE
    , x_cust_trx_type_id    OUT      NUMBER
    , x_memo_line_id        OUT      NUMBER
    , x_receipt_method_id   OUT      NUMBER
    , x_dflt_customer_id    OUT      NUMBER
   )
--  --------------------------------------------------------------
--  -    Procedure to determine the AR Customer Transaction Type -
--  -    and memo line type for the Debit Memo being created     -
--  -    based on data in the AJB 996 row being processed.       -
--  -    Also returns receipt_method_id.                         -
--  -    Use defaults that are defined by processor when chbk    -
--  -    cannot be matched to AR.                                -
--  --------------------------------------------------------------
   IS
   BEGIN
      IF p_header_id IS NOT NULL
      THEN
         SELECT a.dm_cust_trx_type_id, a.dm_memo_line_id, a.receipt_method_id
              --, NULL Commented for PROD Defect 2046,1716
              , a.default_customer_id -- Added for PROD Defect 2046,1716
           INTO x_cust_trx_type_id, x_memo_line_id, x_receipt_method_id
              , x_dflt_customer_id
           FROM xx_ce_recon_glact_hdr a
          WHERE header_id = p_header_id;
      ELSE
         SELECT a.default_dm_cust_trx_type_id, a.default_dm_memo_line_id
              , a.default_receipt_method_id, a.default_customer_id
           INTO x_cust_trx_type_id, x_memo_line_id
              , x_receipt_method_id, x_dflt_customer_id
           FROM xx_ce_recon_glact_hdr a
          WHERE p_trx_date BETWEEN a.effective_from_date
                               AND NVL (a.effective_to_date, SYSDATE)
            AND a.org_id = fnd_profile.VALUE ('ORG_ID')
            AND a.provider_code = p_processor_id
            AND ROWNUM = 1;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_cust_trx_type_id := NULL;
         x_memo_line_id := NULL;
         x_receipt_method_id := NULL;
         x_dflt_customer_id := NULL;
         v_print_line :=
                    '***** Error retrieving DM and Receipt Types and Defaults.';
         lp_print (v_print_line, 'BOTH');
   --  End of getting id values
   END lp_get_dm_trx_type_ids;               -- Procedure lp_get_dm_trx_type_ids

   PROCEDURE lp_apply_receipt (
      lp_dm_trx_id         IN   NUMBER
    , lp_apply_amount      IN   NUMBER
    , lp_cash_receipt_id   IN   NUMBER
   )
   IS
      l_return_status   VARCHAR2 (200);
      l_msg_count       NUMBER;
      l_msg_data        VARCHAR2 (200);
      lc_err_msg        VARCHAR2 (2000);
   BEGIN
      v_error_sub_loc := 'lp_apply_receipt ';
      v_print_line :=
            'Start lp_apply_receipt, DM id / Amt / Receipt id: '
         || lp_dm_trx_id
         || ' / '
         || lp_apply_amount
         || ' / '
         || lp_cash_receipt_id;
      lp_print (v_print_line, 'LOG');
      ar_receipt_api_pub.APPLY
                              (p_api_version => 1.0
                             , p_init_msg_list => fnd_api.g_true
                             , p_validation_level => fnd_api.g_valid_level_full
                             , p_customer_trx_id => lp_dm_trx_id
                             , p_amount_applied => lp_apply_amount
                             , p_cash_receipt_id => lp_cash_receipt_id
                             , x_return_status => l_return_status
                             , x_msg_count => l_msg_count
                             , x_msg_data => l_msg_data
                              );

      IF l_return_status <> 'S'                                   --  no success
      THEN
         v_error_sub_loc := 'API NOT Successful. Receipt Not Applied';
         RAISE v_exception_apply_receipt;
      END IF;
   EXCEPTION
      WHEN v_exception_apply_receipt
      THEN
         v_error_msg := 'Other Error on Apply receipt: ';
         v_print_line :=
               NVL (v_oracle_error_msg, v_error_msg)
            || ' in '
            || v_error_loc
            || v_error_sub_loc
            || ' for '
            || 'ChgBk '
            || lp_cash_receipt_id
            || ' FAILED  ****** ';
         lp_print (v_print_line, 'BOTH');

         FOR i IN 1 .. l_msg_count
         LOOP
            lc_err_msg := fnd_msg_pub.get (p_encoded => fnd_api.g_false);
            v_print_line :=
                       'M' || '*** ' || i || '.' || SUBSTR (lc_err_msg, 1, 255);
            lp_print (v_print_line, 'BOTH');

            IF l_msg_data IS NOT NULL
            THEN
               v_print_line :=
                  SUBSTR (l_msg_data || '/' || i || '.' || lc_err_msg, 1, 2000);
               lp_print (v_print_line, 'BOTH');
            ELSE
               v_print_line := SUBSTR (i || '.' || lc_err_msg, 1, 2000);
               lp_print (v_print_line, 'BOTH');
            END IF;
         END LOOP;
      WHEN OTHERS
      THEN
         v_error_msg := 'Other Error on Apply receipt: ';
         v_print_line :=
               NVL (v_oracle_error_msg, v_error_msg)
            || ' in '
            || v_error_loc
            || v_error_sub_loc
            || ' for '
            || 'ChgBk '
            || lp_cash_receipt_id
            || ' FAILED  ****** ';
         lp_print (v_print_line, 'BOTH');

         FOR i IN 1 .. l_msg_count
         LOOP
            lc_err_msg := fnd_msg_pub.get (p_encoded => fnd_api.g_false);
            v_print_line :=
                       'M' || '*** ' || i || '.' || SUBSTR (lc_err_msg, 1, 255);
            lp_print (v_print_line, 'BOTH');

            IF l_msg_data IS NOT NULL
            THEN
               v_print_line :=
                  SUBSTR (l_msg_data || '/' || i || '.' || lc_err_msg, 1, 2000);
               lp_print (v_print_line, 'BOTH');
            ELSE
               v_print_line := SUBSTR (i || '.' || lc_err_msg, 1, 2000);
               lp_print (v_print_line, 'BOTH');
            END IF;
         END LOOP;
   END lp_apply_receipt;

   PROCEDURE lp_clear_ar_receipt (
      lp_cash_receipt_id   IN       NUMBER
    , lp_amount_cleared    IN       NUMBER
    , lp_bank_currency     IN       VARCHAR2
    , lp_receipt_number    IN       VARCHAR2
    , lp_source            IN       VARCHAR2
    , lp_clear_status      OUT      VARCHAR2
   )
   IS
      CURSOR c
      IS
         SELECT     crh.cash_receipt_history_id, crh.status, acr.amount
               FROM ar_cash_receipt_history crh, ar_cash_receipts acr
              WHERE 1 = 1
                AND crh.cash_receipt_id = acr.cash_receipt_id
                AND acr.cash_receipt_id = lp_cash_receipt_id
                AND crh.current_record_flag = 'Y';

      CURSOR dist (lp_cash_receipt_id IN NUMBER, lp_crh_id IN NUMBER)
      IS
         SELECT   ad.source_type, ad.line_id
             FROM ar_distributions_all ad
                , ar_cash_receipts_all acr
                , ar_cash_receipt_history_all acrh
            WHERE 1 = 1
              AND acr.cash_receipt_id = acrh.cash_receipt_id
              AND ad.source_id = acrh.cash_receipt_history_id
              AND acrh.cash_receipt_history_id = lp_crh_id
              AND acrh.cash_receipt_id = lp_cash_receipt_id
              AND ad.source_table = 'CRH'
              AND acrh.status = 'CLEARED'
              AND NVL (amount_dr, 0) = 0
              AND NVL (amount_cr, 0) = 0
         ORDER BY ad.line_id DESC;

      lp_crh_id               NUMBER;
      lp_trx_date             DATE                                  := SYSDATE;
     --lp_gl_date              DATE                                := SYSDATE;     		Commented to resolve event_id null for defect 31832
      lp_gl_date              DATE                                  := TRUNC(SYSDATE);  -- Applied TRUNC on sysdate to eliminate timestamp issue in defect 31832
      lp_actual_value_date    DATE                                  := SYSDATE;
      lp_exchange_date        VARCHAR2 (10)                         := NULL;
      -- sysdate ; --'SLD';
      lp_exchange_rate_type   VARCHAR2 (10)                         := NULL;
      --'Spot';
      lp_exchange_rate        NUMBER                                := NULL;
      --1;
      lp_amount_factored      NUMBER                                := 0;
      lp_module_name          VARCHAR2 (30)        := 'CE Recon Open Interface:';
      lp_module_version       VARCHAR2 (10)                         := '1.0';
      ln_receipt_amount       NUMBER;
      lc_receipt_status       ar_cash_receipt_history.status%TYPE;
      ln_amt_dr               NUMBER;
      ln_amt_cr               NUMBER;
      ln_remit_count          NUMBER                                := 0;
      ln_cash_count           NUMBER                                := 0;
      ex_clear_receipt        EXCEPTION;
   BEGIN
      v_error_msg := NULL;
      v_oracle_error_msg := NULL;

      OPEN c;

      FETCH c
       INTO lp_crh_id, lc_receipt_status, ln_receipt_amount;

      IF lc_receipt_status = 'CLEARED'
      THEN
         v_error_msg := 'Receipt already cleared.';
         lp_clear_status := 'C';
      ELSIF lc_receipt_status = 'REVERSED'
      THEN
         v_error_msg := 'Receipt Reversed.';
         lp_clear_status := 'R';
      ELSE
         IF ln_receipt_amount = 0
            AND lp_source = 'AJB'
         THEN
            arp_cashbook.CLEAR (lp_cash_receipt_id
                                   , lp_trx_date
                                   , lp_gl_date
                                   , lp_actual_value_date
                                   , lp_exchange_date
                                   , lp_exchange_rate_type
                                   , lp_exchange_rate
                                   , lp_bank_currency
                                   , 0                       --lp_amount_cleared
                                   , lp_amount_factored
                                   , lp_module_name
                                   , lp_module_version
                                   , lp_crh_id
                                    );

            -- Update the accounting amounts to the trx_amount
            -- when the receipt is $0 which is a OD custom receipt created
            -- to manage special refunds.
            IF lp_crh_id IS NOT NULL
            THEN
               FOR dist_rec IN dist (lp_cash_receipt_id, lp_crh_id)
               LOOP
                  -- Update only the latest remittance line
                  -- There will normally be only on DR to Remittance
                  -- and CR to for $0 refund receipts
                  -- corresponding to the 'CLEARED' status.
                  -- In case there are more than one line for the status
                  -- update only the latest (Order By Desc on Query)
                  IF dist_rec.source_type = 'REMITTANCE'
                     AND ln_remit_count < 1
                  THEN
                     ln_remit_count := ln_remit_count + 1;

                     IF NVL (lp_amount_cleared, 0) < 0
                     THEN
                        ln_amt_dr := ABS (lp_amount_cleared);
                        ln_amt_cr := NULL;
                     ELSE
                        ln_amt_dr := NULL;
                        ln_amt_cr := ABS (lp_amount_cleared);
                     END IF;

                     UPDATE ar_distributions_all
                        SET amount_dr = ln_amt_dr
                          , amount_cr = ln_amt_cr
                          , acctd_amount_dr = ln_amt_dr
                          , acctd_amount_cr = ln_amt_cr
                      WHERE line_id = dist_rec.line_id;
                  ELSIF dist_rec.source_type = 'CASH'
                        AND ln_cash_count < 1
                  THEN
                     ln_cash_count := ln_cash_count + 1;

                     IF NVL (lp_amount_cleared, 0) < 0
                     THEN
                        ln_amt_dr := NULL;
                        ln_amt_cr := ABS (lp_amount_cleared);
                     ELSE
                        ln_amt_dr := ABS (lp_amount_cleared);
                        ln_amt_cr := NULL;
                     END IF;

                     UPDATE ar_distributions_all
                        SET amount_dr = ln_amt_dr
                          , amount_cr = ln_amt_cr
                          , acctd_amount_dr = ln_amt_dr
                          , acctd_amount_cr = ln_amt_cr
                      WHERE line_id = dist_rec.line_id;
                  ELSE
                     NULL;
                  END IF;
               END LOOP;

               lp_clear_status := 'Y';
            ELSE
               v_error_msg :=
                             'Error Getting Cash receipt history for Clearing!';
               lp_clear_status := 'N';
               RAISE v_exception_clear_receipt;
            END IF;
         ELSE
            arp_cashbook.CLEAR (lp_cash_receipt_id
                                   , lp_trx_date
                                   , lp_gl_date
                                   , lp_actual_value_date
                                   , lp_exchange_date
                                   , lp_exchange_rate_type
                                   , lp_exchange_rate
                                   , lp_bank_currency
                                   , lp_amount_cleared
                                   , lp_amount_factored
                                   , lp_module_name
                                   , lp_module_version
                                   , lp_crh_id
                                    );
            lp_clear_status := 'Y';
         END IF;
      END IF;

      CLOSE c;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF c%ISOPEN
         THEN
            CLOSE c;
         END IF;

         lp_clear_status := 'N';
         v_error_sub_loc := ': Clr Rcpt';
         v_error_msg := 'Clear receipt FAILED: ';
         v_oracle_error_msg := SQLERRM;
         RAISE v_exception_clear_receipt;
   END lp_clear_ar_receipt;

   PROCEDURE lp_update_999
   IS
   BEGIN
      v_error_sub_loc := 'lp_update_999';

      UPDATE xx_ce_999_interface
         SET status = 'CLEARED'
           , gl_date = v_iface_rec.gl_date
           , cleared_amount = v_iface_rec.cleared_amount
           , cleared_date = v_iface_rec.cleared_date
           , charges_amount = v_iface_rec.charges_amount
           , error_amount = v_iface_rec.error_amount
           , exchange_rate_date = v_iface_rec.exchange_rate_date
           , exchange_rate_type = v_iface_rec.exchange_rate_type
           , exchange_rate = v_iface_rec.exchange_rate
           , last_update_date = SYSDATE
           , last_updated_by = fnd_global.user_id
           , concurrent_pgm_last = v_concurrent_request_id
           , receipts_processed_ctr =
                                  NVL (v_iface_rec.receipts_processed_ctr, 0)
                                  + 1
--           , chargebacks_processed_ctr =
--                               NVL (v_iface_rec.chargebacks_processed_ctr, 0)
--                               + 1     -- V2.9 Commented By Sreenivas
           , receipts_complete = v_998_all_ok
--           , chargebacks_complete = v_996_all_ok
       WHERE ROWID = v_999_iface_rowid;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_oracle_error_msg := SQLERRM;
         v_print_line :=
               NVL (v_oracle_error_msg, v_error_msg)
            || ' in '
            || v_error_loc
            || v_error_sub_loc;
         lp_print (v_print_line, 'BOTH');
         RAISE v_exception_upd_999;
   END lp_update_999;

   PROCEDURE lp_update_csl
   IS
   BEGIN
      v_error_sub_loc := 'lp_update_csl';

      UPDATE ce_statement_lines csl
         SET csl.trx_code_id = v_iface_rec.bank_trx_code_id_original
           , csl.trx_code = v_iface_rec.bank_trx_code_original
           , csl.bank_trx_number = v_iface_rec.bank_trx_number_original
           , csl.last_update_date = SYSDATE
           , csl.last_updated_by = fnd_global.user_id
       WHERE csl.statement_line_id = v_iface_rec.statement_line_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_oracle_error_msg := SQLERRM;
         v_print_line :=
               NVL (v_oracle_error_msg, v_error_msg)
            || ' in '
            || v_error_loc
            || v_error_sub_loc;
         lp_print (v_print_line, 'BOTH');
         RAISE v_exception_upd_csl;
   END lp_update_csl;

   PROCEDURE lp_create_debit_memo (
      p_996_rec       IN       v_996_ar_v_rec%TYPE
    , x_dm_id_out     OUT      NUMBER
    , x_dm_number     OUT      VARCHAR2
    , x_customer_id   OUT      NUMBER
   )
   IS
      l_cust_trx_type_id       NUMBER;
      l_return_status          VARCHAR2 (1);
      l_msg_count              NUMBER;
      l_msg_data               VARCHAR2 (2000);
      l_memo_line_id           NUMBER;
      l_batch_id               NUMBER;
      l_cnt                    NUMBER                                      := 0;
      l_batch_source_rec       ar_invoice_api_pub.batch_source_rec_type;
      l_receipt_counter        NUMBER;
      l_receipt_method_id      NUMBER;
      l_trx_header_tbl         ar_invoice_api_pub.trx_header_tbl_type;
      l_trx_lines_tbl          ar_invoice_api_pub.trx_line_tbl_type;
      l_trx_dist_tbl           ar_invoice_api_pub.trx_dist_tbl_type;
      l_trx_salescredits_tbl   ar_invoice_api_pub.trx_salescredits_tbl_type;
      l_customer_trx_id        NUMBER;
      l_currency_code          VARCHAR2 (3);
      l_seq                    NUMBER;
      l_dflt_customer_id       NUMBER;
      lc_trx_number            VARCHAR2 (20);
   BEGIN
      v_error_sub_loc := 'lp_create_debit_memo';
      l_cnt := 0;
      lc_trx_number := NULL;

      SELECT ra_customer_trx_s.NEXTVAL
        INTO l_seq
        FROM DUAL;

--  ------------------------------------------------------------------ -
--  -   Get customer trx type and memo line id and receipt_method_id   -
--  ------------------------------------------------------------------ -
      lp_get_dm_trx_type_ids (p_996_rec.recon_header_id
                            , p_996_rec.processor_id
                            , p_996_rec.trx_date
                            , l_cust_trx_type_id
                            , l_memo_line_id
                            , l_receipt_method_id
                            , l_dflt_customer_id
                             );

      IF p_996_rec.ar_cash_receipt_id IS NOT NULL
      THEN
         l_trx_header_tbl (1).bill_to_customer_id :=
                                                 p_996_rec.ar_pay_from_customer;
         x_customer_id := p_996_rec.ar_pay_from_customer;
      ELSE
         l_trx_header_tbl (1).bill_to_customer_id := l_dflt_customer_id;
         x_customer_id := l_dflt_customer_id;
      END IF;

      l_trx_header_tbl (1).trx_header_id := l_seq;
      l_trx_header_tbl (1).cust_trx_type_id := l_cust_trx_type_id;
      l_trx_header_tbl (1).trx_currency := p_996_rec.currency;
      --c. Populate batch source information.
      l_batch_source_rec.batch_source_id := gn_batch_id;
      --d. Populate line 1 information.
      l_trx_lines_tbl (1).trx_header_id := l_seq;
      l_trx_lines_tbl (1).trx_line_id := 101;
      l_trx_lines_tbl (1).line_number := 1;
      l_trx_lines_tbl (1).memo_line_id := l_memo_line_id;
      l_trx_lines_tbl (1).description :=
            'Chargeback from '
         || p_996_rec.processor_id
         || '/Receipt#:'
         || p_996_rec.receipt_num
         || '/Invoice#:'
         || p_996_rec.invoice_num
         || '/Chbk Code:'
         || NVL (p_996_rec.chbk_action_code
               , p_996_rec.chbk_alpha_code || '-' || p_996_rec.chbk_numeric_code
                )
         || '/Ref:'
         || p_996_rec.chbk_ref_num
         || '/Ret Ref:'
         || p_996_rec.ret_ref_num
         || '/Store:'
         || p_996_rec.store_num
         || '/Batch:'
         || p_996_rec.bank_rec_id
         || '/Seq:'
         || p_996_rec.sequence_id_996;
      l_trx_lines_tbl (1).quantity_invoiced := 1;
      l_trx_lines_tbl (1).unit_selling_price := p_996_rec.chbk_amt;
      l_trx_lines_tbl (1).line_type := 'LINE';
      l_return_status := NULL;
      l_msg_data := NULL;
      l_msg_count := NULL;
      arp_standard.enable_debug;
      ar_invoice_api_pub.create_single_invoice
                              (p_api_version => 1.0
                             , p_batch_source_rec => l_batch_source_rec
                             , p_trx_header_tbl => l_trx_header_tbl
                             , p_trx_lines_tbl => l_trx_lines_tbl
                             , p_trx_dist_tbl => l_trx_dist_tbl
                             , p_trx_salescredits_tbl => l_trx_salescredits_tbl
                             , x_customer_trx_id => l_customer_trx_id
                             , x_return_status => l_return_status
                             , x_msg_count => l_msg_count
                             , x_msg_data => l_msg_data
                              );

      /* ---------------------------------------------------------------------
      --   NOTE:  An error here will require that this chargeback's
      --          debit memo will have to be created manually.  The
      --          remainder of this AJB996-Chargeback file will still
      --          (attempt to) be processed.
      -- -------------------------------------------------------------------*/
      IF l_return_status <> fnd_api.g_ret_sts_success
      THEN
         x_dm_id_out := -99;
         lp_print (   LPAD (p_996_rec.sequence_id_996, 10, ' ')
                   || ' '
                   || RPAD (NVL (p_996_rec.ar_receipt_number, '- NULL -')
                          , 30
                          , ' '
                           )
                   || ' '
                   || RPAD (NVL (p_996_rec.invoice_num, '- NULL -'), 30, ' ')
                   || ' '
                   || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ')
                   || ' '
                   || RPAD (NVL (lc_trx_number, ' '), 30, ' ')
                   || ' '
                   || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ')
                   || ' '
                   || RPAD (' * * Error * * ', 30, ' ')
                 , 'BOTH'
                  );
         v_error_msg :=
               LPAD (' ', 12, ' ')
            || 'Error Creating DM for Chbk '
            || p_996_rec.processor_id
            || '/ Chbk Code:'
            || NVL (p_996_rec.chbk_action_code
                  ,    p_996_rec.chbk_alpha_code
                    || '-'
                    || p_996_rec.chbk_numeric_code
                   )
            || '/ Ref:'
            || NVL (p_996_rec.chbk_ref_num, 'NONE')
            || '/ Ret Ref:'
            || NVL (p_996_rec.ret_ref_num, 0)
            || '/ Store:'
            || p_996_rec.store_num;
         lp_print (v_error_msg, 'LOG');

         IF l_msg_data IS NOT NULL
            OR fnd_msg_pub.get (p_encoded => fnd_api.g_false) IS NOT NULL
         THEN
            v_print_line :=
                  LPAD (' ', 12, ' ')
               || LTRIM (RTRIM (fnd_msg_pub.get (p_encoded => fnd_api.g_false)));
            lp_print (v_print_line, 'LOG');
         END IF;

         RAISE v_exception_create_dm;
      ELSE
         SELECT COUNT (*)
           INTO l_cnt
           FROM ar_trx_errors_gt;

         IF l_cnt = 0
         THEN
            x_dm_id_out := l_customer_trx_id;
            v_error_msg := NULL;

            BEGIN
               SELECT trx_number
                 INTO lc_trx_number
                 FROM ra_customer_trx
                WHERE customer_trx_id = l_customer_trx_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lc_trx_number := NULL;
            END;

            x_dm_number := lc_trx_number;
            lp_print (   LPAD (p_996_rec.sequence_id_996, 10, ' ')
                      || ' '
                      || RPAD (NVL (p_996_rec.ar_receipt_number, '- NULL -')
                             , 30
                             , ' '
                              )
                      || ' '
                      || RPAD (NVL (p_996_rec.invoice_num, '- NULL -'), 30, ' ')
                      || ' '
                      || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ')
                      || ' '
                      || RPAD (NVL (lc_trx_number, ' '), 30, ' ')
                      || ' '
                      || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ')
                      || ' '
                      || RPAD ('Created Debit Memo', 30, ' ')
                    , 'BOTH'
                     );
         ELSE
            x_dm_id_out := -99;
            lp_print (   LPAD (p_996_rec.sequence_id_996, 10, ' ')
                      || ' '
                      || RPAD (NVL (p_996_rec.ar_receipt_number, '- NULL -')
                             , 30
                             , ' '
                              )
                      || ' '
                      || RPAD (NVL (p_996_rec.invoice_num, '- NULL -'), 30, ' ')
                      || ' '
                      || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ')
                      || ' '
                      || RPAD (NVL (lc_trx_number, ' '), 30, ' ')
                      || ' '
                      || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ')
                      || ' '
                      || RPAD (' * * Error * * ', 30, ' ')
                    , 'BOTH'
                     );
            v_error_msg :=
               SUBSTR (   LPAD (' ', 12, ' ')
                       || 'Error Creating DM for Chbk '
                       || p_996_rec.processor_id
                       || '/ Chbk Code:'
                       || NVL (p_996_rec.chbk_action_code
                             ,    p_996_rec.chbk_alpha_code
                               || '-'
                               || p_996_rec.chbk_numeric_code
                              )
                       || '/ Ref:'
                       || NVL (p_996_rec.chbk_ref_num, 'NONE')
                       || '/ Ret Ref:'
                       || NVL (p_996_rec.ret_ref_num, 0)
                       || '/ Store:'
                       || p_996_rec.store_num
                     , 1
                     , 2000
                      );
            v_print_line := v_error_msg;
            lp_print (v_print_line, 'LOG');

            IF l_msg_data IS NOT NULL
               OR fnd_msg_pub.get (p_encoded => fnd_api.g_false) IS NOT NULL
            THEN
               v_print_line :=
                     LPAD (' ', 12, ' ')
                  || 'API Error(s):'
                  || LTRIM (RTRIM (fnd_msg_pub.get (p_encoded => fnd_api.g_false)
                                  )
                           );
               lp_print (v_print_line, 'LOG');
            END IF;

            RAISE v_exception_create_dm;
         END IF;
      END IF;
   EXCEPTION
      WHEN v_exception_create_dm
      THEN
         IF l_cnt > 0
         THEN
            SELECT    error_message
                   || NVL2 (invalid_value, ':' || invalid_value, NULL)
              INTO v_print_line
              FROM ar_trx_errors_gt
             WHERE ROWNUM = 1;

            lp_print (LPAD (' ', 12, ' ') || v_print_line, 'LOG');
         END IF;

         RAISE v_exception_create_dm;
      WHEN OTHERS
      THEN
         v_oracle_error_msg := SQLERRM;
         lp_print (   LPAD (p_996_rec.sequence_id_996, 10, ' ')
                   || ' '
                   || RPAD (NVL (p_996_rec.ar_receipt_number, '- NULL -')
                          , 30
                          , ' '
                           )
                   || ' '
                   || RPAD (NVL (p_996_rec.invoice_num, '- NULL -'), 30, ' ')
                   || ' '
                   || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ')
                   || ' '
                   || RPAD (NVL (lc_trx_number, ' '), 30, ' ')
                   || ' '
                   || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ')
                   || ' '
                   || RPAD (' * * Error * * ', 30, ' ')
                 , 'BOTH'
                  );

         IF l_cnt > 0
         THEN
            SELECT    error_message
                   || NVL2 (invalid_value, ':' || invalid_value, NULL)
              INTO v_print_line
              FROM ar_trx_errors_gt
             WHERE ROWNUM = 1;

            lp_print (LPAD (' ', 12, ' ') || v_print_line, 'LOG');
         END IF;

         v_print_line :=
               NVL (v_oracle_error_msg, v_error_msg)
            || ' in '
            || v_error_loc
            || v_error_sub_loc;
         lp_print (LPAD (' ', 12, ' ') || v_print_line, 'LOG');

         IF SQLCODE IS NOT NULL
            OR SQLERRM IS NOT NULL
         THEN
            lp_print (LPAD (' ', 12, ' ') || SQLCODE || ':' || SQLERRM, 'LOG');
         END IF;

         RAISE v_exception_create_dm;             -- Calling block will rollback
                                                  -- to skip this 996 rowl
   END lp_create_debit_memo;                      -- Procedure Create_Debit_Memo

   PROCEDURE lp_create_receipt (
      p_996_rec      IN       v_996_ar_v_rec%TYPE
    , x_trx_id_out   OUT      NUMBER
   )
   IS
      ln_cust_trx_type_id    NUMBER;
      lc_currency_code       VARCHAR2 (5);
      ln_memo_line_id        NUMBER;
      lc_receipt_number      VARCHAR2 (30);
      lc_return_status       VARCHAR2 (200);
      ln_msg_count           NUMBER;
      ln_receipt_method_id   NUMBER;
      lc_msg_data            VARCHAR2 (2000);
      lc_mesg                VARCHAR2 (2000);
      lc_err_msg             VARCHAR2 (2000);
      ln_cr_id               NUMBER;
      ln_count               NUMBER                               := 0;
      ln_dflt_customer_id    NUMBER;
      ln_customer_id         NUMBER;
      lc_search_receipt      VARCHAR2 (200);
      lc_comments            ar_cash_receipts_all.comments%TYPE;
   BEGIN
      v_error_sub_loc := 'Create Receipt';
     --  ------------------------------------------------------------------ -
--  -   Get customer trx type and memo line id and receipt_method_id   -
--  ------------------------------------------------------------------ -
      lp_get_dm_trx_type_ids (p_996_rec.recon_header_id
                            , p_996_rec.processor_id
                            , p_996_rec.trx_date
                            , ln_cust_trx_type_id
                            , ln_memo_line_id
                            , ln_receipt_method_id
                            , ln_dflt_customer_id
                             );

      IF p_996_rec.ar_pay_from_customer IS NOT NULL
      THEN
         ln_customer_id := p_996_rec.ar_pay_from_customer;
      ELSE
         v_error_sub_loc :=
                         'Use Default customer (' || ln_dflt_customer_id || ')';
         ln_customer_id := ln_dflt_customer_id;
      END IF;

      v_error_sub_loc := 'Set Search Receipt Number';
      lc_search_receipt :=
                  NVL (NVL (p_996_rec.receipt_num, p_996_rec.invoice_num), 'CB');

      --if p_996_rec.invoice_num is not null then
      SELECT COUNT (*)
        INTO ln_count
        FROM ar_cash_receipts
       WHERE pay_from_customer = ln_customer_id
         AND receipt_number LIKE lc_search_receipt || '%';

--      IF lc_search_receipt = 'CB-'
--      THEN
--         lc_search_receipt := 'CB';
--      END IF;
      IF ln_count > 0
      THEN
         v_error_sub_loc := 'Receipt# Null:Count > 0';

         IF (LENGTH (lc_search_receipt) + LENGTH (ln_count) + 1) > 30
         THEN
            lc_receipt_number :=
                  SUBSTR
                     (lc_search_receipt
                    , (30 - LENGTH (ln_count) - 1) * -1
                    , (30 - LENGTH (ln_count) - 1
                      )                  --Length of counter and seperator "-"".
                     )
               || '-'
               || (ln_count + 1);
         ELSE
            lc_receipt_number := lc_search_receipt || '-' || (ln_count + 1);
         END IF;
      ELSE
         v_error_sub_loc := 'Receipt# Null:Count = 0';
         lc_receipt_number :=
            NVL (SUBSTR (lc_search_receipt, -30, 30)
               , lc_search_receipt || '-' || (ln_count + 1)
                );
      END IF;

        --  ln_customer_id := ln_dflt_customer_id;
      -- END IF;
      v_error_sub_loc := 'Call create cash receipt API.';
      lc_return_status := NULL;
      lc_msg_data := NULL;
      ln_msg_count := NULL;
      lc_comments :=
            'Chargeback Reversal from '
         || p_996_rec.processor_id
         || '/Receipt#:'
         || p_996_rec.receipt_num
         || '/Invoice#:'
         || p_996_rec.invoice_num
         || '/Chbk Code:'
         || NVL (p_996_rec.chbk_action_code
               , p_996_rec.chbk_alpha_code || '-' || p_996_rec.chbk_numeric_code
                )
         || '/Ref:'
         || p_996_rec.chbk_ref_num
         || '/Ret Ref:'
         || p_996_rec.ret_ref_num
         || '/Store:'
         || p_996_rec.store_num
         || '/Batch:'
         || p_996_rec.bank_rec_id
         || '/Seq:'
         || p_996_rec.sequence_id_996;
      arp_standard.enable_debug;
      ar_receipt_api_pub.create_cash
                              (p_api_version => 1.0
                             , p_init_msg_list => fnd_api.g_true
                             , p_validation_level => fnd_api.g_valid_level_full
                             , p_receipt_number => lc_receipt_number
                             , p_amount => p_996_rec.chbk_amt * -1
                             , p_receipt_method_id => ln_receipt_method_id
                             , p_receipt_date => SYSDATE
                             , p_currency_code => p_996_rec.currency
                             , p_customer_id => ln_customer_id
                             , p_comments => lc_comments
                             , p_cr_id => x_trx_id_out
                             , x_return_status => lc_return_status
                             , x_msg_count => ln_msg_count
                             , x_msg_data => lc_msg_data
                              );

      IF lc_return_status <> 'S'                                  --  no success
      THEN
         v_error_sub_loc := 'API NOT Successful. Receipt Not Created';
         lp_print (   LPAD (p_996_rec.sequence_id_996, 10, ' ')
                   || ' '
                   || RPAD (NVL (p_996_rec.ar_receipt_number, '- NULL -')
                          , 30
                          , ' '
                           )
                   || ' '
                   || RPAD (NVL (p_996_rec.invoice_num, '- NULL -'), 30, ' ')
                   || ' '
                   || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ')
                   || ' '
                   || RPAD (lc_receipt_number, 30, ' ')
                   || ' '
                   || LPAD (NVL (p_996_rec.chbk_amt, 0) * -1, 15, ' ')
                   || ' '
                   || RPAD (' * * Error * * ', 30, ' ')
                 , 'BOTH'
                  );
         v_print_line :=
               LPAD (' ', 12, ' ')
            || 'Error Creating Receipt for Chargeback '
            || p_996_rec.processor_id
            || '/ Chbk Code:'
            || NVL (p_996_rec.chbk_action_code
                  ,    p_996_rec.chbk_alpha_code
                    || '-'
                    || p_996_rec.chbk_numeric_code
                   )
            || '/ Ref:'
            || NVL (p_996_rec.chbk_ref_num, 'None')
            || '/ Ret Ref:'
            || NVL (p_996_rec.ret_ref_num, 0)
            || '/ Store:'
            || p_996_rec.store_num;
         lp_print (v_print_line, 'LOG');

         IF NVL (ln_msg_count, 0) > 0
         THEN
            FOR i IN 1 .. ln_msg_count
            LOOP
               lc_err_msg := fnd_msg_pub.get (p_encoded => fnd_api.g_false);
               v_print_line :=
                     LPAD (' ', 15, ' ')
                  || 'Msg '
                  || i
                  || ': '
                  || SUBSTR (lc_err_msg, 1, 255);
               lp_print (v_print_line, 'LOG');

               IF lc_msg_data IS NOT NULL
               THEN
                  v_print_line :=
                        LPAD (' ', 15, ' ')
                     || SUBSTR (lc_msg_data || '/' || i || ':' || lc_err_msg
                              , 1
                              , 2000
                               );
                  lp_print (v_print_line, 'LOG');
               ELSE
                  lc_msg_data :=
                        LPAD (' ', 15, ' ')
                     || SUBSTR (i || ':' || lc_err_msg, 1, 2000);
                  lp_print (v_print_line, 'LOG');
               END IF;
            END LOOP;
         END IF;
      ELSE
         v_error_sub_loc := 'API Success. Receipt Created';
         lp_print (   LPAD (p_996_rec.sequence_id_996, 10, ' ')
                   || ' '
                   || RPAD (NVL (p_996_rec.ar_receipt_number, '- NULL -')
                          , 30
                          , ' '
                           )
                   || ' '
                   || RPAD (NVL (p_996_rec.invoice_num, '- NULL -'), 30, ' ')
                   || ' '
                   || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ')
                   || ' '
                   || RPAD (lc_receipt_number, 30, ' ')
                   || ' '
                   || LPAD (NVL (p_996_rec.chbk_amt, 0) * -1, 15, ' ')
                   || ' '
                   || RPAD ('Created Receipt', 30, ' ')
                 , 'BOTH'
                  );
      END IF;                                         -- Check of return_status.
   EXCEPTION
      WHEN OTHERS
      THEN
          if (v_error_sub_loc <> 'API NOT Successful. Receipt Not Created' ) THEN
         lp_print (   LPAD (p_996_rec.sequence_id_996, 10, ' ')
                   || ' '
                   || RPAD (NVL (p_996_rec.ar_receipt_number, '- NULL -')
                          , 30
                          , ' '
                           )
                   || ' '
                   || RPAD (NVL (p_996_rec.invoice_num, '- NULL -'), 30, ' ')
                   || ' '
                   || LPAD (NVL (p_996_rec.chbk_amt, 0), 15, ' ')
                   || ' '
                   || RPAD (lc_receipt_number, 30, ' ')
                   || ' '
                   || LPAD (NVL (p_996_rec.chbk_amt, 0) * -1, 15, ' ')
                   || ' '
                   || RPAD (' * * Error * * ', 30, ' ')
                 , 'BOTH'
                  );
         v_oracle_error_msg := SQLCODE || ':' || SQLERRM;
         v_print_line :=
               LPAD (' ', 12, ' ')
            || 'Other Error creating Receipt:'
            || NVL (v_oracle_error_msg, v_error_msg)
            || ' @ loc:'
            || v_error_loc
            || v_error_sub_loc;
         lp_print (v_print_line, 'LOG');
         END IF;
         RAISE v_exception_create_receipt;
   END lp_create_receipt;

   /* ---------------------------------------------------------------------
   |  PUBLIC FUNCTION                                                      |
   |       lock_row                                                        |
   |                                                                       |
   |  DESCRIPTION                                                          |
   |       This procedure would be called when open-interface transactions |
   |       need to be locked                                               |
   |                                                                       |
   |                                                                       |
   |  HISTORY                                                              |
    --------------------------------------------------------------------- */
   PROCEDURE lock_row (
      x_call_mode   VARCHAR2
    , x_trx_type    VARCHAR2
    , x_trx_rowid   VARCHAR2
   )
   IS
   /* Example lock_open cursor

     trx_id ROWID;

     CURSOR lock_open IS
     select rowid
     from xx_ce_999_interface
     where rowid = X_trx_rowid
     for update of trx_id nowait;

   */

   /* Note: xx_ce_999_interface is the base table of ce_999_interface_v in this example. */
   BEGIN
      NULL;
   /* Example of lock_row procedure with cursor and exception handling

     OPEN lock_open;
     FETCH lock_open INTO trx_id;
     IF (lock_open%NOTFOUND) THEN
       CLOSE lock_open;
       RAISE NO_DATA_FOUND;
     END IF;
     CLOSE lock_open;

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       IF lock_open%ISOPEN THEN
         CLOSE lock_open;
       END IF;
       RAISE NO_DATA_FOUND;
     WHEN APP_EXCEPTION.RECORD_LOCK_EXCEPTION THEN
       IF lock_open%ISOPEN THEN
         CLOSE lock_open;
       END IF;
       RAISE APP_EXCEPTION.RECORD_LOCK_EXCEPTION;
   */
   END lock_row;

   /* ---------------------------------------------------------------------
   |  PUBLIC PROCEDURE                                                     |
   |       clear                                                           |
   |                                                                       |
   |  DESCRIPTION                                                          |
   |       This procedure would be called during clearing phase            |
   |       NOTE: This is a transactional procedure.  It executes one       |
   |             time for each time called by CE Autoreconciliation        |
   |             when it matched a statement line to a line in the         |
   |             XX_CE_999_INTERFACE table.                                |
   |  HISTORY                                                              |
    --------------------------------------------------------------------- */
   PROCEDURE CLEAR (
      x_trx_id           NUMBER                                -- transaction id
    , x_trx_type         VARCHAR2            -- trans type -- ('PAYMENT'/'CASH')
    , x_status           VARCHAR2                                      -- status
    , x_trx_number       VARCHAR2                          -- transaction number
    , x_trx_date         DATE                                -- transaction date
    , x_trx_currency     VARCHAR2                         -- trans currency code
    , x_gl_date          DATE                                         -- gl date
    , x_bank_currency    VARCHAR2                          -- bank currency code
    , x_cleared_amount   NUMBER                          -- amount to be cleared
    , x_cleared_date     DATE                                    -- cleared date
    , x_charges_amount   NUMBER                                -- charges amount
    , x_errors_amount    NUMBER                                 -- errors amount
    , x_exchange_date    DATE                              -- exchange rate date
    , x_exchange_type    VARCHAR2                          -- exchange rate type
    , x_exchange_rate    NUMBER                                 -- exchange rate
   )
   IS
      PROCEDURE       -- Private procedure to perform required processing for
                      -- STORE OVER/SHORT and CASH CONCENTRATION.  There is no
                      -- required processing for this however.  We just need
                      -- to let the OI and CSL rows get marked as completed
                      -- which will happen in the main procedure after the call
                      -- to this procedure.
               lp_clear_bank_os
      IS
      BEGIN
         SAVEPOINT save_store_os_main;

         UPDATE xx_ce_999_interface
            SET status = 'CLEARED'
              , last_update_date = SYSDATE
              , last_updated_by = fnd_global.user_id
              , concurrent_pgm_last = v_concurrent_request_id
          WHERE status = 'FLOAT'
            AND trx_id = v_iface_rec.trx_id;
      --  End of block for 'LOCKBOX_DAY'
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK TO save_store_os_main;
            v_print_line :=
                  '* * Error Updating CE Open Interface/Bank Statement Line for TrxID:'
               || v_iface_rec.trx_id
               || '. STOPPED PROCESSING BATCH! Review Log for details.';
            lp_print (v_print_line, 'BOTH');
            lp_print ('* * Error: ' || SQLCODE || '-' || SQLERRM, 'LOG');
            lp_print (' ', 'BOTH');
            v_oracle_error_msg := SQLERRM;
            --x_retcode          := ln_error;
            v_print_line :=
                  NVL (v_oracle_error_msg, v_error_msg)
               || ' in Store O/S Recon - Clearing process';
            lp_print (v_print_line, 'BOTH');
            RAISE v_exception_bad_store_os;
      END lp_clear_bank_os;

      -- Private procedure to perform required processing for
                -- clearing AR receipts found in the AJB file(s) passed
                -- in the OI record.
      PROCEDURE lp_clear_ajb
      IS
         le_exception_bad_vset      EXCEPTION;
         lv_acr_key                 VARCHAR2 (30);
         lv_acr_amount              NUMBER;
         lv_ar_receipt_id           NUMBER;
         lv_ar_receipt_number       VARCHAR2 (70);
         lv_ajb_bank_rec_id         VARCHAR2 (50);
         lv_ajb_processor_id        VARCHAR2 (50);
         lv_ajb_vset_group          NUMBER;
         lv_dm_bal                  NUMBER;
         lv_dm_id                   NUMBER;
         lc_dm_number               ra_customer_trx.trx_number%TYPE;
         lc_dm_receipt_number       ar_cash_receipts_all.receipt_number%TYPE;
         ln_customer_id             NUMBER;
         lv_xc9i_trx_id             NUMBER;
         lc_err_batches_savepoint   VARCHAR2 (100);
         lc_batches_savepoint       VARCHAR2 (100);

         CURSOR lc_ajb996_ar
         IS
            SELECT *
              FROM xx_ce_ajb996_ar_v                           --xx_ce_ajb996_v
             WHERE NVL (status_1295, '~') <> 'Y'
               AND processor_id = lv_ajb_processor_id
               AND bank_rec_id = lv_ajb_bank_rec_id;

         --  This cursor is for processing all of the 999-Iface rows that
         --  contain the specific ce_statement_line_id that CE Auto Recon
         --  matched and sent to this program.  This id may or may not have
         --  more than one 999-Interface row.
         CURSOR lc_ajb998r_vgrp
         IS
            SELECT     xc9i.bank_rec_id, xc9i.processor_id, xc9i.trx_id
                     , xc9i.ROWID
                  FROM xx_ce_999_interface xc9i
                 WHERE xc9i.GROUP_ID = v_iface_rec.GROUP_ID
                   AND NVL (record_type, '~') = 'AJB'
                   AND xc9i.status = 'FLOAT'
                   AND NVL (xc9i.deposits_matched, 'N') = 'Y'
                  -- AND NVL (xc9i.expenses_complete, 'N') = 'Y'
                   AND NVL (xc9i.x999_gl_complete, 'N') = 'Y'; -- V2.9 Added by Gaurav Agarwal
                  -- AND NVL (xc9i.chargebacks_complete,'N') = 'Y'; --V2.9 Commented By Sreenivas

         --  This cursor is for reprocessing any 996/998 files that had
         --  detail records that failed to process correctly.  The program
         --  will attempt this 6 times based on receipts_processed_ctr
         --  and/or chargebacks_processed_ctr stored in the 999-Interface
         --  row.  the single statement deposit
         --  and AJB bank_rec_id that CE Auto Recon matched.
         --  20080703 - Update to process only for same bank account
         --   and provider as the above process.
         CURSOR lc_999_iface_errors
         IS
            SELECT     xc9i.bank_rec_id, xc9i.processor_id, xc9i.trx_id
                     , xc9i.ROWID
                  FROM xx_ce_999_interface xc9i
                 WHERE 1 = 1
                   AND NVL (record_type, '~') = 'AJB'
                   AND NVL (status, 'FLOAT') = 'CLEARED'
                   AND NVL (xc9i.deposits_matched, 'N') = 'Y'
                   --AND NVL (xc9i.expenses_complete, 'N') = 'Y'
           AND NVL (xc9i.x999_gl_complete, 'N') = 'Y'   -- Added By Gaurav Agarwal
                   AND NVL (xc9i.concurrent_pgm_last, 0) <>
                                                         v_concurrent_request_id
                   AND ((NVL (xc9i.receipts_complete, 'N') = 'N'
                         AND NVL (xc9i.receipts_processed_ctr, 0) BETWEEN 0 AND 6
                        )
--                        OR (NVL (xc9i.chargebacks_complete, 'N') = 'N'
--                            AND NVL (xc9i.chargebacks_processed_ctr, 0) BETWEEN 0
--                                                                            AND 6
--                           ) -- V2.9 Commented by Sreenivas
                       )
                   AND processor_id = v_iface_rec.processor_id
                   AND bank_account_id = v_iface_rec.bank_account_id;

         CURSOR lc_ajb998_ar_v
         IS
            SELECT *
              FROM xx_ce_ajb998_ar_v
             WHERE 1 = 1
               AND bank_rec_id = lv_ajb_bank_rec_id
               AND processor_id = lv_ajb_processor_id
               AND NVL (status_1295, '~') NOT IN ('C', 'R', 'Y');

         CURSOR get_dm (p_cash_receipt_id IN NUMBER, p_receipt_number IN VARCHAR2)
         IS
            SELECT a.*
              FROM xx_ce_chargeback_dm a
             WHERE (a.cash_receipt_id = p_cash_receipt_id
                    OR receipt_number = p_receipt_number
                   )
               AND a.creation_date =
                     (SELECT MAX (b.creation_date)
                        FROM xx_ce_chargeback_dm b
                       WHERE (b.cash_receipt_id = a.cash_receipt_id
                              OR b.receipt_number = p_receipt_number
                             ));

         PROCEDURE lp_process_998s
         --  This procedure does the actual processing of 998 detail records
         IS
            ln_998_count                NUMBER        := 0;
            ln_998_err_count            NUMBER        := 0;
            ln_998_success              NUMBER        := 0;
            ln_998_tot_amt              NUMBER        := 0;
            ln_998_err_amt              NUMBER        := 0;
            ln_998_ar_tot_amt           NUMBER        := 0;
            ln_998_ar_err_amt           NUMBER        := 0;
            ln_998_success_tot_amt      NUMBER        := 0;
            ln_998_success_ar_tot_amt   NUMBER        := 0;
            lc_status_msg               VARCHAR2 (30);
            lc_clear_status             VARCHAR2 (1);
            lc_cash_receipt_id          NUMBER        := 0; --Added for the Defect 4721 by Jude
            lc_amount                   NUMBER        := 0; --Added for the Defect 4721 by Jude
            lc_currency_code            VARCHAR2(15);       --Added for the Defect 4721 by Jude
            lc_receipt_number           VARCHAR2(30);       --Added for the Defect 4721 by Jude
            ln_update_count             NUMBER;
            ln_payment_amt              NUMBER;             --Added for QC Defect # 13263 -- Zero Dollar Receipt
         BEGIN
            SAVEPOINT save_998_main;
            v_print_line :=
                  'Processing 998 Receipts for BankRecID:'
               || lv_ajb_bank_rec_id
               || ' / Processor:'
               || lv_ajb_processor_id
               || ' (Review Log for Error details)';
            lp_print (v_print_line, 'BOTH');

            FOR v_998_ar_v_rec IN lc_ajb998_ar_v
            LOOP
               SAVEPOINT save_998_row;

               --lp_print(v_print_line, 'BOTH');            -- CC or Debit/Check.
               BEGIN                          -- Clear the receipt for this row
                  IF v_998_ar_v_rec.ar_cash_receipt_id IS NOT NULL
                  THEN
                     ln_998_count := ln_998_count + 1;
                     ln_998_tot_amt :=
                            ln_998_tot_amt + NVL (v_998_ar_v_rec.trx_amount, 0);
                     ln_998_ar_tot_amt :=
                          ln_998_ar_tot_amt + NVL (v_998_ar_v_rec.ar_amount, 0);

                     IF ln_998_count = 1
                     THEN
                        lp_print (   RPAD ('998 Seq ID', 10, ' ')
                                  || ' '
                                  || RPAD ('Type', 10, ' ')
                                  || ' '
                                  || RPAD ('Receipt#', 30, ' ')
                                  || ' '
                                  || LPAD ('Trx Amt', 15, ' ')
                                  || ' '
                                  || RPAD ('iPay Batch', 20, ' ')
                                  || ' '
                                  || RPAD ('Status', 30, ' ')
                                , 'BOTH'
                                 );
                        lp_print (   RPAD ('-', 10, '-')
                                  || ' '
                                  || RPAD ('-', 10, '-')
                                  || ' '
                                  || RPAD ('-', 30, '-')
                                  || ' '
                                  || RPAD ('-', 15, '-')
                                  || ' '
                                  || RPAD ('-', 20, '-')
                                  || ' '
                                  || RPAD ('-', 30, '-')
                                , 'BOTH'
                                 );
                     END IF;

                     lc_clear_status := 'N';
                     lc_status_msg := NULL;
                     ln_update_count := 0;

                     --V2.9 SDR Project Requirement starts

                     -- Added for QC Defect # 13263 -- Zero Dollar Receipt -- Start
                     BEGIN

                         SELECT dtl.payment_amount
                          INTO ln_payment_amt
                          FROM xx_ce_ajb998 ajb998,
                               xx_ar_order_receipt_dtl dtl
                         WHERE 1 = 1
                           AND ajb998.provider_type = 'CREDIT'
                           AND ajb998.trx_type = 'REFUND'
                           AND dtl.cash_receipt_id = ajb998.ar_cash_receipt_id
                           AND dtl.org_id = ajb998.org_id
                           AND ajb998.ar_cash_receipt_id = v_998_ar_v_rec.ar_cash_receipt_id
                           AND dtl.order_payment_id = v_998_ar_v_rec.order_payment_id
                           ;

                         IF ln_payment_amt = 0 THEN

                             UPDATE xx_ar_order_receipt_dtl
                             SET    receipt_status = 'CLEARED'
                                   ,cleared_date   = SYSDATE
                                   ,last_update_date = SYSDATE
                                   ,last_updated_by = fnd_global.user_id
                                   ,last_update_login =  fnd_global.login_id
                             WHERE  order_payment_id = v_998_ar_v_rec.order_payment_id
                             AND    cash_receipt_id = v_998_ar_v_rec.ar_cash_receipt_id
                             AND    payment_amount = 0
                             AND    remitted = 'Y';

                         END IF;

                     EXCEPTION WHEN OTHERS THEN

                        lp_print (' ', 'LOG');
                        v_print_line := 'Exception raised while updating Zero Dollar Receipt in ORDT. cash_receipt_id :' || v_998_ar_v_rec.ar_cash_receipt_id || ' Exception : ' || SQLERRM;
                        lp_print (v_print_line, 'LOG');

                     END;
                     -- Added for QC Defect # 13263 -- Zero Dollar Receipt -- End

                     UPDATE XX_AR_ORDER_RECEIPT_DTL
                     SET    receipt_status = 'CLEARED'
                           ,cleared_date   = SYSDATE
                           ,last_update_date = SYSDATE
                           ,last_updated_by = fnd_global.user_id
                           ,last_update_login =  fnd_global.login_id
                     WHERE  order_payment_id = v_998_ar_v_rec.order_payment_id
                     AND    payment_amount =  v_998_ar_v_rec.trx_amount
                     AND    remitted = 'Y';

                     ln_update_count := SQL%ROWCOUNT;

                     -- SDR Project Requirement ends

                     IF ln_update_count = 0 THEN
                        lp_clear_ar_receipt (v_998_ar_v_rec.ar_cash_receipt_id
                                            , v_998_ar_v_rec.trx_amount
                                            , v_998_ar_v_rec.currency_code
                                            , v_998_ar_v_rec.receipt_num
                                            , 'AJB'
                                            , lc_clear_status
                                             );

                     ELSE
                        lc_clear_status := 'Y';
                     END IF;

                     UPDATE xx_ce_ajb998 a9
                        SET a9.status_1295 = lc_clear_status               --'Y'
                      WHERE sequence_id_998 = v_998_ar_v_rec.sequence_id_998;


                     IF lc_clear_status = 'R'
                     THEN
                        lc_status_msg := 'Receipt is Reversed!';
                     ELSIF lc_clear_status = 'C'
                     THEN
                        lc_status_msg := 'Receipt is already Cleared';
                     ELSIF lc_clear_status = 'Y'
                     THEN
                        lc_status_msg := 'Cleared';
                     ELSIF lc_clear_status = 'N'
                     THEN
                        lc_status_msg := '* * * Error * * * ';
                     ELSE
                        lc_status_msg := 'Invalid Status';
                     END IF;

                     v_print_line :=
                        (   RPAD (v_998_ar_v_rec.sequence_id_998, 10, ' ')
                         || ' '
                         || RPAD (NVL (v_998_ar_v_rec.provider_type, ' ')
                                , 10
                                , ' '
                                 )
                         || ' '
                         || RPAD (NVL (v_998_ar_v_rec.receipt_num, ' '), 30
                                , ' ')
                         || ' '
                         || LPAD (NVL (v_998_ar_v_rec.trx_amount, 0), 15, ' ')
                         || ' '
                         || RPAD (NVL (v_998_ar_v_rec.ipay_batch_num, ' ')
                                , 20
                                , ' '
                                 )
                         || ' '
                         || RPAD (lc_status_msg, 30, ' ')
                        );
                     lp_print (v_print_line, 'LOG');

----------------------------------------------------------------------------------
--Clearing Zero Receipts  --Starting  Added for the Defect 4721 by Jude              
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
	-- Debug profile added for defect #43970 START 
-----------------------------------------------------------------------------------
                     BEGIN
						IF
						PG_DEBUG = 'Y' THEN
                        lp_print (' ', 'LOG');
                        v_print_line := 'Searching for Zero Dollar Receipt for the Customer Receipt Reference  :' || v_998_ar_v_rec.ar_customer_receipt_reference;
                        lp_print (v_print_line, 'LOG');
						END IF;
                        SELECT  NVL(XCARV.cash_receipt_id,0)
                               ,XCARV.amount
                               ,XCARV.currency_code
                               ,XCARV.receipt_number
                        INTO    lc_cash_receipt_id
                               ,lc_amount
                               ,lc_currency_code
                               ,lc_receipt_number
                        FROM    xx_ce_ajb_receipts_v XCARV
                        WHERE   xcarv.customer_receipt_reference = v_998_ar_v_rec.ar_customer_receipt_reference
                        AND     xcarv.amount                     = 0
                    --    AND     TRUNC(xcarv.receipt_date)        = TRUNC(v_998_ar_v_rec.ar_receipt_date);
                        AND     xcarv.receipt_date        = TRUNC(v_998_ar_v_rec.ar_receipt_date); -- Removed TRUNC by P Lohiya for Defect 30059

                        IF lc_cash_receipt_id <> 0 THEN
							IF 
							PG_DEBUG = 'Y' THEN
                            lp_print (' ', 'LOG');
                            v_print_line := 'Zero Dollar Found for the Customer Receipt Reference  :' || v_998_ar_v_rec.ar_customer_receipt_reference;
                            lp_print (v_print_line, 'LOG');
						    END IF;
                            lp_clear_ar_receipt (lc_cash_receipt_id
                                               , lc_amount
                                               , lc_currency_code
                                               , lc_receipt_number
                                               , 'AJB'
                                               , lc_clear_status
                                                );
                        ELSE
						   IF PG_DEBUG = 'Y' THEN
                           lp_print (' ', 'LOG');
                           v_print_line := 'No Zero Dollar Found for the Customer Receipt Reference  :' || v_998_ar_v_rec.ar_customer_receipt_reference;
                           lp_print (v_print_line, 'LOG');
						   END IF;

                        END IF;

                     EXCEPTION

                        WHEN NO_DATA_FOUND THEN
							IF PG_DEBUG = 'Y' THEN

                           v_print_line := 'NO DATA FOUND';
                           lp_print (v_print_line, 'LOG');

                           v_print_line := 'CUSTOMER_RECEIPT_REFERENCE  : '|| v_998_ar_v_rec.ar_customer_receipt_reference ||
                                           '  RECEIPT_DATE : ' || TRUNC(v_998_ar_v_rec.ar_receipt_date) ;
                           lp_print (v_print_line, 'LOG');
						   END IF;

                        WHEN OTHERS THEN
						IF PG_DEBUG = 'Y' THEN

                           v_print_line := 'Other Exception raised : '|| SQLERRM;
                           lp_print (v_print_line, 'LOG');
						   END IF;
                     END;
----------------------------------------------------------------------------------
	-- Debug profile added for defect #43970 END
-----------------------------------------------------------------------------------					 
					         
----------------------------------------------------------------------------------
--Clearing Zero Receipts  --Ending  Added for the Defect 4721 by Jude
----------------------------------------------------------------------------------


                  ELSE                               -- matching receipt found?.
                     RAISE v_exception_clear_receipt;
                  END IF;                            -- matching receipt found?.
               EXCEPTION
                  WHEN v_exception_clear_receipt
                  THEN
                     v_print_line :=
                        (   RPAD (v_998_ar_v_rec.sequence_id_998, 10, ' ')
                         || ' '
                         || RPAD (v_998_ar_v_rec.provider_type, 10, ' ')
                         || ' '
                         || RPAD (NVL (v_998_ar_v_rec.receipt_num, ' '), 30
                                , ' ')
                         || ' '
                         || LPAD (NVL (v_998_ar_v_rec.trx_amount, 0), 15, ' ')
                         || ' '
                         || RPAD (NVL (v_998_ar_v_rec.ipay_batch_num, ' ')
                                , 20
                                , ' '
                                 )
                         || ' '
                         || RPAD ('* * * Error * * * ', 30, ' ')
                        );
                     lp_print (v_print_line, 'BOTH');
                     v_print_line :=
                           LPAD (' ', 12, ' ')
                        || NVL (v_oracle_error_msg, v_error_msg)
                        || ' in '
                        || v_error_loc
                        || v_error_sub_loc
                        || ' clearing receipt #'
                        || v_998_ar_v_rec.receipt_num
                        || '/'
                        || v_998_ar_v_rec.ar_cash_receipt_id;
                     lp_print (v_print_line, 'LOG');
                     ROLLBACK TO save_998_row;
                     ln_998_err_count := ln_998_err_count + 1;
                     ln_998_err_amt :=
                             ln_998_err_amt + NVL (v_998_ar_v_rec.trx_amount, 0);
                     ln_998_ar_err_amt :=
                           ln_998_ar_err_amt + NVL (v_998_ar_v_rec.ar_amount, 0);
                     v_998_all_ok := 'N';

                     UPDATE xx_ce_ajb998 a8
                        SET a8.status_1295 = 'N'
                      WHERE sequence_id_998 = v_998_ar_v_rec.sequence_id_998;
                  --AND bank_rec_id = v_998_ar_v_rec.bank_rec_id;
                  WHEN OTHERS
                  THEN
                     v_print_line :=
                        (   RPAD (NVL (v_998_ar_v_rec.sequence_id_998, ' ')
                                , 10
                                , ' '
                                 )
                         || ' '
                         || RPAD (NVL (v_998_ar_v_rec.provider_type, ' ')
                                , 10
                                , ' '
                                 )
                         || ' '
                         || RPAD (NVL (v_998_ar_v_rec.receipt_num, ' '), 30
                                , ' ')
                         || ' '
                         || LPAD (NVL (v_998_ar_v_rec.trx_amount, 0), 15, ' ')
                         || ' '
                         || RPAD (NVL (v_998_ar_v_rec.ipay_batch_num, ' ')
                                , 20
                                , ' '
                                 )
                         || ' '
                         || RPAD ('* * * Error * * * ', 30, ' ')
                        );
                     lp_print (v_print_line, 'BOTH');
                     v_998_all_ok := 'N';
                     v_print_line :=
                        (   LPAD (' ', 12, ' ')
                         || 'Other Error:'
                         || SQLCODE
                         || ':'
                         || SQLERRM
                        );
                     lp_print (v_print_line, 'BOTH');
                     ROLLBACK TO save_998_row;
                     ln_998_err_count := ln_998_err_count + 1;
                     ln_998_err_amt :=
                             ln_998_err_amt + NVL (v_998_ar_v_rec.trx_amount, 0);
                     ln_998_ar_err_amt :=
                           ln_998_ar_err_amt + NVL (v_998_ar_v_rec.ar_amount, 0);


                     UPDATE xx_ce_ajb998 a8
                        SET a8.status_1295 = 'N'
                          , last_update_date = SYSDATE
                      WHERE a8.sequence_id_998 = v_998_ar_v_rec.sequence_id_998;

                     lp_print (' ', 'BOTH');
               END;                                      --  End of this 998 row
            END LOOP;                -- End of looping through this AJB 998 file

            lp_print (' ', 'BOTH');
            lp_print (g_line, 'BOTH');
            lp_print (   LPAD (' ', 30, ' ')
                      || '998 Process Summary (Bank Rec ID:'
                      || lv_ajb_bank_rec_id
                      || ' Processor:'
                      || lv_ajb_processor_id
                      || ')'
                    , 'BOTH'
                     );
            lp_print (g_line, 'BOTH');
            ln_998_success := ln_998_count - ln_998_err_count;
            ln_998_success_tot_amt := ln_998_tot_amt - ln_998_err_amt;
            ln_998_success_ar_tot_amt := ln_998_ar_tot_amt - ln_998_ar_err_amt;
            lp_print (   LPAD (' ', 30, ' ')
                      || LPAD ('Count', 15, ' ')
                      || LPAD (' ', 10, ' ')
                      || LPAD ('AJB Amount', 15, ' ')
                      || LPAD (' ', 10, ' ')
                      || LPAD ('AR Amount', 15, ' ')
                    , 'BOTH'
                     );
            lp_print (   LPAD (' ', 30, ' ')
                      || LPAD ('-', 15, '-')
                      || LPAD (' ', 10, ' ')
                      || LPAD ('-', 15, '-')
                      || LPAD (' ', 10, ' ')
                      || LPAD ('-', 15, '-')
                    , 'BOTH'
                     );
            lp_print (   LPAD ('Successfully Processed', 29, ' ')
                      || ':'
                      || LPAD (ln_998_success, 15, ' ')
                      || LPAD (' ', 10, ' ')
                      || LPAD (ln_998_success_tot_amt, 15, ' ')
                      || LPAD (' ', 10, ' ')
                      || LPAD (ln_998_success_ar_tot_amt, 15, ' ')
                    , 'BOTH'
                     );
            lp_print (   LPAD ('Error Processing', 29, ' ')
                      || ':'
                      || LPAD (ln_998_err_count, 15, ' ')
                      || LPAD (' ', 10, ' ')
                      || LPAD (ln_998_err_amt, 15, ' ')
                      || LPAD (' ', 10, ' ')
                      || LPAD (ln_998_ar_err_amt, 15, ' ')
                    , 'BOTH'
                     );
            lp_print (g_line, 'BOTH');
            lp_print (' ', 'BOTH');
            lp_print (' ', 'BOTH');
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK TO save_998_main;
               v_998_all_ok := 'N';
               v_print_line :=
                     '* * Error Clearing Receipts '
                  || lv_ajb_bank_rec_id
                  || '/'
                  || lv_ajb_processor_id
                  || '/'
                  || lv_xc9i_trx_id
                  || '. STOPPED PROCESSING BATCH! Review Log for details.';
               lp_print (v_print_line, 'BOTH');
               lp_print (   '* * Error after loc:'
                         || v_error_sub_loc
                         || ' : '
                         || SQLCODE
                         || '-'
                         || SQLERRM
                       , 'LOG'
                        );
               lp_print (' ', 'BOTH');
         END lp_process_998s;
/*
         PROCEDURE lp_process_996s
         IS
            ln_996_count       NUMBER := 0;
            ln_996_err_count   NUMBER := 0;
            ln_996_success     NUMBER := 0;
         BEGIN
            lp_print (' ', 'BOTH');
            v_print_line :=
                  'Processing Chargebacks for BankRecID:'
               || lv_ajb_bank_rec_id
               || ' / Processor:'
               || lv_ajb_processor_id
               || '(Review log for error details)';
            lp_print (v_print_line, 'BOTH');
            lp_print (g_line, 'BOTH');
            lp_print (   RPAD ('996 Seq ID', 10, ' ')
                      || ' '
                      || RPAD ('Receipt#', 30, ' ')
                      || ' '
                      || RPAD ('Invoice#', 30, ' ')
                      || ' '
                      || LPAD ('Chbk Amt', 15, ' ')
                      || ' '
                      || RPAD ('DM/Receipt#', 30, ' ')
                      || ' '
                      || LPAD ('DM/Receipt Amt', 15, ' ')
                      || ' '
                      || RPAD ('Status', 30, ' ')
                    , 'BOTH'
                     );
            lp_print (   RPAD ('-', 10, '-')
                      || ' '
                      || RPAD ('-', 30, '-')
                      || ' '
                      || RPAD ('-', 30, '-')
                      || ' '
                      || RPAD ('-', 15, '-')
                      || ' '
                      || RPAD ('-', 30, '-')
                      || ' '
                      || RPAD ('-', 15, '-')
                      || ' '
                      || RPAD ('-', 30, '-')
                    , 'BOTH'
                     );

            BEGIN
               SELECT batch_source_id
                 INTO gn_batch_id
                 FROM ra_batch_sources
                WHERE NAME LIKE 'MISC_CBDM%'
                  AND status = 'A'
                  AND SYSDATE BETWEEN start_date AND NVL (end_date, SYSDATE + 1)
                  AND ROWNUM = 1;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_error_sub_loc := 'Find Debit Memo Batch Source';
                  v_print_line :=
                        LPAD (' ', 12, ' ')
                     || '* * Error: Transaction Batch source is not defined! * * .';
                  lp_print (v_print_line, 'BOTH');

                  IF SQLCODE IS NOT NULL
                     OR SQLERRM IS NOT NULL
                  THEN
                     lp_print (LPAD (' ', 12, ' ') || SQLCODE || ':' || SQLERRM
                             , 'LOG'
                              );
                  END IF;

                  RAISE le_invalid_batch_info;
            END;

            FOR v_996_rec IN lc_ajb996_ar
            LOOP
               BEGIN
                  SAVEPOINT save_996_row;
                  ln_996_count := ln_996_count + 1;

                  IF v_996_rec.chbk_amt > 0
                  --  Chargeback reduces net deposit amount so create DM.
                  THEN
                     lv_dm_id := 0;
                     lp_create_debit_memo (v_996_rec
                                         , lv_dm_id
                                         , lc_dm_number
                                         , ln_customer_id
                                          );

                     IF lv_dm_id > 0
                     THEN
                        UPDATE ra_customer_trx_all
                           SET ct_reference =
                                  SUBSTR (   v_996_rec.processor_id
                                          || '/'
                                          || v_996_rec.ar_receipt_number
                                          || '/'
                                          || v_996_rec.bank_rec_id
                                          || '/'
                                          || v_996_rec.sequence_id_996
                                        , 1
                                        , 30
                                         )
                             , special_instructions =
                                  (   'CB-'
                                   || v_996_rec.processor_id
                                   || '/Receipt#:'
                                   || v_996_rec.receipt_num
                                   || '/Invoice#:'
                                   || v_996_rec.invoice_num
                                   || '/Chbk Code:'
                                   || NVL (v_996_rec.chbk_action_code
                                         ,    v_996_rec.chbk_alpha_code
                                           || '-'
                                           || v_996_rec.chbk_numeric_code
                                          )
                                   || '/Ref:'
                                   || v_996_rec.chbk_ref_num
                                   || '/Ret Ref:'
                                   || v_996_rec.ret_ref_num
                                   || '/Store:'
                                   || v_996_rec.store_num
                                   || '/Batch:'
                                   || v_996_rec.bank_rec_id
                                   || '/Seq:'
                                   || v_996_rec.sequence_id_996
                                  )
                         WHERE customer_trx_id = lv_dm_id;

                        INSERT INTO xx_ce_chargeback_dm
                                    (seq_id
                                   , cash_receipt_id, debit_memo_trx_id
                                   , receipt_number
                                   , debit_memo_number, customer_id
                                   , sequence_id_996, creation_date
                                   , created_by, last_update_date
                                   , last_updated_by
                                    )
                             VALUES (xx_ce_chargeback_dm_s.NEXTVAL
                                   , v_996_rec.ar_cash_receipt_id, lv_dm_id
                                   , NVL (v_996_rec.receipt_num
                                        , v_996_rec.invoice_num
                                         )
                                   , lc_dm_number, ln_customer_id
                                   , v_996_rec.sequence_id_996, SYSDATE
                                   , v_user_id, SYSDATE
                                   , v_user_id
                                    );

                        UPDATE xx_ce_ajb996 a6
                           SET a6.status_1295 = 'Y'
                             , last_update_date = SYSDATE
                         WHERE a6.sequence_id_996 = v_996_rec.sequence_id_996;
                     END IF;
                  ELSIF v_996_rec.chbk_amt < 0
                  --  Chargeback increases net deposit amount so create Receipt.
                  THEN
                     v_cash_receipt_id := 0;
                     lp_create_receipt (v_996_rec, v_cash_receipt_id);

                     IF v_cash_receipt_id > 0
                     THEN
                        BEGIN
-- -----------------------------------------------
-- - Look for DM with a balance greater than -
-- - this new receipt.  If found, then apply it. -
-- -----------------------------------------------
                           v_ce_dm_rec := NULL;
                           v_error_sub_loc := 'Receipt Created - Check for DM';

                           BEGIN
                              OPEN get_dm (v_996_rec.ar_cash_receipt_id
                                         , NVL (v_996_rec.receipt_num
                                              , v_996_rec.invoice_num
                                               )
                                          );

                              FETCH get_dm
                               INTO v_ce_dm_rec;

                              CLOSE get_dm;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 v_ce_dm_rec := NULL;
                           END;

                           --  Get the debit memo balance  --
                           lv_dm_bal := 0;

                           IF NVL (v_ce_dm_rec.debit_memo_trx_id, -99) > 0
                           THEN
                              lv_dm_bal :=
                                 arp_bal_util.get_trx_balance
                                    (p_customer_trx_id => v_ce_dm_rec.debit_memo_trx_id
                                   , p_open_receivables_flag => NULL
                                    );
                           END IF;

                           -- Apply receipt to DM if DM balance > chargeback amount
                           IF NVL (lv_dm_bal, 0) >=
                                               (NVL (v_996_rec.chbk_amt, 0) * -1
                                               )
                           --  Remember, chbk_amt is negative here so
                           --  we have to change the sign for comparing
                           --  to the DM amount.
                           THEN
                              lp_apply_receipt (v_ce_dm_rec.debit_memo_trx_id
                                              , (NVL (v_996_rec.chbk_amt, 0)
                                                 * -1
                                                )
                                              , v_cash_receipt_id
                                               );
                           END IF;                               -- lv_dm_bal >=
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_error_sub_loc :=
                                               'Find DM: Exception-When Others';
                              v_print_line :=
                                    LPAD (' ', 12, ' ')
                                 || '** Error finding/applying Receipt to DM. Review Log for details.';
                              lp_print (v_print_line, 'BOTH');
                              lp_print (SQLCODE || '-' || SQLERRM, 'LOG');
                        END;                     --Look for DM to apply receipt.

                        -- Receipt was processed successfully,
                        UPDATE xx_ce_ajb996 a6
                           SET a6.status_1295 = 'Y'
                             , last_update_date = SYSDATE
                         WHERE a6.sequence_id_996 = v_996_rec.sequence_id_996;
                     END IF;                            -- Cash Receipt Created.
                  END IF;                                      --chbk_amt check.
               EXCEPTION
                  WHEN v_exception_create_dm
                  THEN
                     ROLLBACK TO save_996_row;
                     v_996_all_ok := 'N';
                     ln_996_err_count := ln_996_err_count + 1;

                     UPDATE xx_ce_ajb996 a6
                        SET a6.status_1295 = 'N'
                          , last_update_date = SYSDATE
                      WHERE a6.sequence_id_996 = v_996_rec.sequence_id_996;
                  --AND bank_rec_id = v_996_rec.bank_rec_id;
                  WHEN v_exception_create_receipt
                  THEN
                     ROLLBACK TO save_996_row;
                     v_996_all_ok := 'N';
                     ln_996_err_count := ln_996_err_count + 1;

                     UPDATE xx_ce_ajb996 a6
                        SET a6.status_1295 = 'N'
                          , last_update_date = SYSDATE
                      WHERE a6.sequence_id_996 = v_996_rec.sequence_id_996;
                  --AND bank_rec_id = v_996_rec.bank_rec_id;
                  WHEN OTHERS
                  THEN
                     ROLLBACK TO save_996_row;
                     v_996_all_ok := 'N';
                     ln_996_err_count := ln_996_err_count + 1;

                     UPDATE xx_ce_ajb996 a6
                        SET a6.status_1295 = 'N'
                          , last_update_date = SYSDATE
                      WHERE a6.sequence_id_996 = v_996_rec.sequence_id_996;

                     --AND bank_rec_id = v_996_rec.bank_rec_id;
                     lp_print (   LPAD (v_996_rec.sequence_id_996, 10, ' ')
                               || ' '
                               || RPAD (NVL (v_996_rec.ar_receipt_number
                                           , '- NULL -'
                                            )
                                      , 30
                                      , ' '
                                       )
                               || ' '
                               || RPAD (NVL (v_996_rec.invoice_num, '- NULL -')
                                      , 30
                                      , ' '
                                       )
                               || ' '
                               || LPAD (NVL (v_996_rec.chbk_amt, 0), 15, ' ')
                               || ' '
                               || RPAD (' ', 30, ' ')
                               || ' '
                               || LPAD (' ', 15, ' ')
                               || ' '
                               || RPAD (' * * Error * * ', 30, ' ')
                             , 'BOTH'
                              );

                     IF SQLCODE IS NOT NULL
                        OR SQLERRM IS NOT NULL
                     THEN
                        lp_print (LPAD (' ', 12, ' ') || SQLCODE || ':'
                                  || SQLERRM
                                , 'LOG'
                                 );
                     END IF;
               END;
            END LOOP;

            lp_print (' ', 'BOTH');
            lp_print (g_line, 'BOTH');
            lp_print (   LPAD (' ', 30, ' ')
                      || '996 Chargeback Process Summary (Bank Rec ID:'
                      || lv_ajb_bank_rec_id
                      || ' Processor:'
                      || lv_ajb_processor_id
                      || ')'
                    , 'BOTH'
                     );
            lp_print (g_line, 'BOTH');
            ln_996_success := ln_996_count - ln_996_err_count;

            IF ln_996_count > 0
            THEN
               lp_print (   LPAD ('Successfully Processed', 29, ' ')
                         || ':'
                         || LPAD (ln_996_success, 15, ' ')
                       , 'BOTH'
                        );
            ELSE
               lp_print (' - - No 996 transactions to clear - -', 'BOTH');
            END IF;

            lp_print (   LPAD ('Error Processing', 29, ' ')
                      || ':'
                      || LPAD (ln_996_err_count, 15, ' ')
                    , 'BOTH'
                     );
            lp_print (' ', 'BOTH');
            lp_print (g_line, 'BOTH');
            lp_print (' ', 'BOTH');
         EXCEPTION
            WHEN le_invalid_batch_info
            THEN
               v_996_all_ok := 'N';
               ROLLBACK TO save_996_main;
            WHEN OTHERS
            THEN
               v_996_all_ok := 'N';
               ROLLBACK TO save_996_main;
               v_print_line :=
                     '** Error Processing Chargebacks '
                  || lv_ajb_bank_rec_id
                  || '/'
                  || lv_ajb_processor_id
                  || '/'
                  || lv_xc9i_trx_id
                  || '. PROCESSING STOPPED!. Review Log for details.';
               lp_print (v_print_line, 'BOTH');
               lp_print (   'Error after loc:'
                         || v_error_sub_loc
                         || ' : '
                         || SQLCODE
                         || '-'
                         || SQLERRM
                       , 'LOG'
                        );
               lp_print (' ', 'BOTH');
         END lp_process_996s;
*/
      --
      BEGIN                                 --  Start of lp_clear_ajb processing
         v_error_loc := 'AJB Processing:';
         BEGIN                 -- Loop to get all ajb file numbers for this
                               -- group defined in the 999-Iface row fetched by
                               -- lc_iface_cur at the start of this program.
                               -- Note that  "vset_file" in AJB has changed
                               -- to "bank_rec_id".
            lc_batches_savepoint := 'RegularBatchesSavepoint';
            SAVEPOINT lc_batches_savepoint;
            lp_print (' ', 'BOTH');
            lp_print (g_line, 'BOTH');
            lp_print (   LPAD (' ', 30, ' ')
                      || ' Reconciling Credit Card Transactions'
                    , 'BOTH'
                     );
            lp_print (g_line, 'BOTH');
            lp_print (' ', 'BOTH');
            FOR vg IN lc_ajb998r_vgrp
            LOOP                           -- For a single ajb file number in
                                           -- this particular vset group number.
               lv_ajb_bank_rec_id := vg.bank_rec_id;
               lv_ajb_processor_id := vg.processor_id;
               lv_xc9i_trx_id := vg.trx_id;
               v_999_iface_rowid := vg.ROWID;
               v_998_all_ok := 'Y';
               v_996_all_ok := 'Y';
               --  Process the 998 file detail records
               lp_process_998s;
               lp_print (' ', 'BOTH');
               --  Now do the charge backs
             ---  lp_process_996s;
               lp_print (' ', 'BOTH');
               --  Now update this xx_ce_999_interface row
               lp_update_999;
               lp_print (' ', 'BOTH');
            END LOOP;                              -- End Loop for vset_group_id
         EXCEPTION
            WHEN OTHERS
            THEN
               IF SQLCODE = -54
               THEN
                  v_print_line := 'Batch is locked by other request/user';
                  lp_print (v_print_line, 'BOTH');
                  ROLLBACK TO lc_batches_savepoint;
               ELSE
                  --v_error_sub_loc := '';
                  v_oracle_error_msg := SQLERRM;
                  --x_retcode          := ln_error;
                  v_print_line :=
                        NVL (v_oracle_error_msg, v_error_msg)
                     || ' in '
                     || v_error_loc
                     || v_error_sub_loc;
                  lp_print (v_print_line, 'BOTH');
               END IF;
         END;

         -- Comment out lines that errors from other runs
            -- Move these to a seperate concurrent program
         BEGIN          -- Loop to get all bank rec ids for prior processed
                        -- 999-Iface rows that had one or more detail row errors
                        -- when last processed.
            lc_err_batches_savepoint := 'ErrBatchesSavePoint';

            FOR ie IN lc_999_iface_errors
            LOOP                                 -- For a single bank_rec_id in
                                                 -- this group that had errors.
               SAVEPOINT lc_err_batch_savepoint;
               lv_ajb_bank_rec_id := ie.bank_rec_id;
               lv_ajb_processor_id := ie.processor_id;
               lv_xc9i_trx_id := ie.trx_id;
               v_999_iface_rowid := ie.ROWID;
               v_998_all_ok := 'Y';
               v_996_all_ok := 'Y';
               lp_print
                  (   'Process Errors from prior reconciliations for Bank Account. BankRecID:'
                   || lv_ajb_bank_rec_id
                   || ' / ProcessorID:'
                   || lv_ajb_processor_id
                   || ' /TrxID:'
                   || lv_xc9i_trx_id
                 , 'BOTH'
                  );
               --  Process the 998 file detail records
               lp_process_998s;
               --  Now do the charge backs
               ---lp_process_996s;
               --  Now update this xx_ce_999_interface row
               ----lp_update_999;
            END LOOP;    -- End Loop for prior processed 999-Iface rows w/errors
         EXCEPTION
            WHEN OTHERS
            THEN
               IF SQLCODE = -54
               THEN
                  v_print_line := 'Batch is locked by other request/user';
                  lp_print (v_print_line, 'BOTH');
                  ROLLBACK TO lc_err_batches_savepoint;
               ELSE
                  --v_error_sub_loc := '';
                  v_oracle_error_msg := SQLERRM;
                  --x_retcode          := ln_error;
                  v_print_line :=
                        NVL (v_oracle_error_msg, v_error_msg)
                     || ' in '
                     || v_error_loc
                     || v_error_sub_loc;
                  lp_print (v_print_line, 'BOTH');
                  ROLLBACK TO lc_err_batches_savepoint;
               END IF;
         END;
      EXCEPTION
         WHEN OTHERS
         THEN
            --v_error_sub_loc := '';
            v_oracle_error_msg := SQLERRM;
            --x_retcode          := ln_error;
            v_print_line :=
                  NVL (v_oracle_error_msg, v_error_msg)
               || ' in '
               || v_error_loc
               || v_error_sub_loc;
            lp_print (v_print_line, 'BOTH');
            --lp_log_comn_error ('AJB loop had unknown error for vset: '
            --                  ,v_iface_rec.ajb_file_number);
            RAISE v_exception_bad_ajb;
      END lp_clear_ajb;

      PROCEDURE lp_clear_lockbox
      IS
         -- Updated 28-Mar-2008 By D.Gowda
         -- Selected only UnCleared Records for Clearing.
         -- Select for Update
         CURSOR lc_daily_lbox
         IS
            SELECT     arc.cash_receipt_id, arc.amount, arc.currency_code
                     , arc.receipt_number
                  FROM ar_cash_receipts arc
                     , ar_cash_receipt_history acrh
                 WHERE 1 = 1
                   AND acrh.cash_receipt_id = arc.cash_receipt_id
                   AND arc.deposit_date = v_iface_rec.lockbox_deposit_date
                   AND arc.receipt_method_id = v_iface_rec.receipt_method_id
                   AND acrh.current_record_flag = 'Y'
                   AND acrh.status != 'CLEARED';

         ln_lkbx_count       NUMBER       := 0;
         ln_lkbx_err_count   NUMBER       := 0;
         lc_clear_status     VARCHAR2 (1);
      BEGIN
         v_error_loc := 'Clear Lbox: ';

         BEGIN                                     --  Loop through all lockbox
            SAVEPOINT save_lkbx_main;
            v_error_sub_loc := 'LBox-Day';
            v_temp_print := v_iface_rec.lockbox_deposit_date;
            lp_print (' ', 'BOTH');
            lp_print (g_line, 'BOTH');
            lp_print (   LPAD (' ', 30, ' ')
                      || 'Clearing Lockbox Transactions for '
                      || v_temp_print
                    , 'BOTH'
                     );
            lp_print (g_line, 'BOTH');
            lp_print (' ', 'BOTH');

            FOR lbd IN lc_daily_lbox
            LOOP                                       --  receipts for this day
               BEGIN                                           -- process a row
                  SAVEPOINT save_lkbx_rcpt_row;
                  lp_clear_ar_receipt (lbd.cash_receipt_id
                                     , lbd.amount
                                     , lbd.currency_code
                                     , lbd.receipt_number
                                     , 'LOCKBOX'
                                     , lc_clear_status
                                      );
                  ln_lkbx_count := ln_lkbx_count + 1;
               EXCEPTION
                  WHEN v_exception_clear_receipt
                  THEN
                     ROLLBACK TO save_lkbx_rcpt_row;
                     ln_lkbx_err_count := ln_lkbx_err_count + 1;

                     IF ln_lkbx_err_count = 1
                     THEN
                        lp_print ('Error clearing the following receipts'
                                , 'BOTH'
                                 );
                        lp_print (' ', 'BOTH');
                        lp_print (   RPAD ('Receipt#', 30, ' ')
                                  || ' '
                                  || LPAD ('Trx Amt', 15, ' ')
                                , 'OUT'
                                 );
                        lp_print (   RPAD ('-', 30, '-')
                                  || ' '
                                  || RPAD ('-', 15, '-')
                                , 'OUT'
                                 );
                     END IF;

                     v_print_line :=
                        (   RPAD (lbd.receipt_number, 30, ' ')
                         || ' '
                         || LPAD (lbd.amount, 15, ' ')
                        );
                     lp_print (v_print_line, 'BOTH');
               END;
            END LOOP;

            --  Now set all interface rows for this lockbox,
            --  and deposit-date to 'CLEARED'.

            -- 28-Mar-2008 - D.Gowda
            -- Update only for Statement Trx ID being processed
            -- Otherwise Other Statement lines will not have
            -- anything on the 999 interface to clear against!!!
            BEGIN
               UPDATE xx_ce_999_interface
                  SET status = 'CLEARED'
                    , last_update_date = SYSDATE
                    , last_updated_by = fnd_global.user_id
                WHERE status = 'FLOAT'
                  AND lockbox_deposit_date = v_iface_rec.lockbox_deposit_date
                  AND receipt_method_id = v_iface_rec.receipt_method_id
                  --AND trx_number = v_trx_id  -- commented for 35794 
				  AND trx_number = to_char(v_trx_id) ;   -- Added for the defect 35794
            END;

            lp_print (' ', 'BOTH');
            lp_print (g_line, 'BOTH');
            lp_print (   LPAD (' ', 30, ' ')
                      || 'Lockbox Reconciliation Process Summary'
                    , 'BOTH'
                     );
            lp_print (g_line, 'BOTH');

            IF ln_lkbx_count > 0
            THEN
               lp_print (   'Successfully Processed '
                         || ':'
                         || ln_lkbx_count
                         || ' lockbox Receipts.'
                       , 'BOTH'
                        );
            ELSE
               lp_print (' - - No lockbox transactions to clear - -', 'BOTH');
            END IF;

            IF ln_lkbx_err_count > 0
            THEN
               lp_print
                      (   ln_lkbx_err_count
                       || ' lockbox transactions were not cleared due to errors.'
                     , 'BOTH'
                      );
            END IF;

            lp_print (g_line, 'BOTH');
            lp_print (' ', 'BOTH');
            lp_print (' ', 'BOTH');
         END;                                 --  End of block for 'LOCKBOX_DAY'
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK TO save_lkbx_main;
            v_print_line :=
                  '* * Error Clearing Receipts for date'
               || v_iface_rec.lockbox_deposit_date
               || '. STOPPED PROCESSING BATCH! Review Log for details.';
            lp_print (v_print_line, 'BOTH');
            lp_print ('* * Error: ' || SQLCODE || '-' || SQLERRM, 'LOG');
            lp_print (' ', 'BOTH');
            v_oracle_error_msg := SQLERRM;
            --x_retcode          := ln_error;
            v_print_line :=
                  NVL (v_oracle_error_msg, v_error_msg)
               || ' in lockbox recon - clearing process';
            lp_print (v_print_line, 'BOTH');
            RAISE v_exception_bad_lbox;
      END lp_clear_lockbox;
   BEGIN
      /* Note: xx_ce_999_interface is the base table of ce_999_interface_v in this
               example */

      /* Note: You are required to pass the status column to your proprietary
         database. The Reconciliation Open Interface feature requires a
         non-null status column to function correctly. */

      --  NOTE:  This is where processing starts when package and
      --         procedure is called from CE AutoReconciliation
      v_concurrent_request_id := fnd_global.conc_request_id ();
      v_print_line :=
            'Concurrent Request: '
         || v_concurrent_request_id
         || ' called E1295 for trx_id:'
         || x_trx_id;
      lp_print (v_print_line, 'BOTH');

      BEGIN                                         --  Get the interface record
         v_trx_id := x_trx_id;

         OPEN lc_iface_cur;

         FETCH lc_iface_cur
          INTO v_iface_rec;

         IF (lc_iface_cur%NOTFOUND)
         THEN
            CLOSE lc_iface_cur;

            v_print_line :=
                  ' * * * Matching Open Interface data not found for Trx Id:'
               || v_trx_id;
            lp_print (v_print_line, 'BOTH');
            v_print_line := ' * * * Fees for the process may not be processed.';
            lp_print (v_print_line, 'BOTH');
            RAISE NO_DATA_FOUND;
         END IF;

         CLOSE lc_iface_cur;
      END;                                          --   End of get iface record

      -- Create a database savepoint in case of
      -- an error in processing this particular
      -- row. An error means that we do not want
      -- have this data saved.
      SAVEPOINT one_rec_e1295;

      CASE UPPER (v_iface_rec.record_type)
         WHEN 'STORE_O/S'
         THEN
            lp_print ('Call Extension to Process Store O/S.', 'LOG');
            lp_clear_bank_os;
         WHEN 'AJB'
         THEN
            lp_print ('Call Extension to Process Credit Card Reconciliation.'
                    , 'LOG'
                     );
            lp_clear_ajb;

         -- Defect 5821 Move GL Entry creation to CR 319 forms.
         --lp_process_group_gl;
      WHEN 'LOCKBOX_DAY'
         THEN
            lp_print ('Call Extension to Process Lockboxes.', 'LOG');
            lp_clear_lockbox;
            -- Defect 5821 Move GL Entry creation to CR 319 forms.
            --lp_process_group_gl;
      --WHEN 'LOCKBOX_BATCH'
      --THEN
      --   lp_clear_lockbox;
      --   lp_process_group_gl ;
      END CASE;

      --  Now update the ce_statement_lines row to set
      --  it back to the original values
      lp_update_csl;
   -- Don't commit in this package because that
   -- should be done in the calling package
   --COMMIT;
   EXCEPTION
      WHEN v_exception_upd_999
      THEN
         ROLLBACK TO SAVEPOINT one_rec_e1295;
      -- Logging handled in local proc.
      WHEN v_exception_upd_csl
      THEN
         ROLLBACK TO SAVEPOINT one_rec_e1295;
      -- Logging handled in local proc.
      WHEN v_exception_bad_vset
      THEN
         ROLLBACK TO SAVEPOINT one_rec_e1295;
      -- Logging handled in local proc.
      WHEN v_exception_bad_store_os
      THEN
         ROLLBACK TO SAVEPOINT one_rec_e1295;
      -- Logging handled in local proc.
      WHEN v_exception_bad_ajb
      THEN
         ROLLBACK TO SAVEPOINT one_rec_e1295;
      -- Logging handled in local proc.
      WHEN v_exception_bad_lbox
      THEN
         ROLLBACK TO SAVEPOINT one_rec_e1295;
   -- Logging handled in local proc.
   END CLEAR;

   /* ---------------------------------------------------------------------
   |  PUBLIC PROCEDURE                                                     |
   |       unclear                                                         |
   |                   NOTE: THIS SHOULD NEVER BE CALLED                   |
   |  DESCRIPTION                                                          |
   |       This procedure would be called during unclearing phase          |
   |                                                                       |
   |  HISTORY                                                              |
    --------------------------------------------------------------------- */
   PROCEDURE unclear (
      x_trx_id     NUMBER                                      -- transaction id
    , x_trx_type   VARCHAR2               -- transaction type ('PAYMENT'/'CASH')
    , x_status     VARCHAR2                                            -- status
    , x_trx_date   DATE                                      -- transaction date
    , x_gl_date    DATE                                               -- gl date
   )
   IS
   BEGIN
      /* Note: xx_ce_999_interface is the base table of ce_999_interface_v in this
               example */

      /* Note: You are required to pass the status column to your proprietary
         database. The Reconciliation Open Interface feature requires a
         non-null status column to function correctly. */

      /* Note: If you have not defined the value for the open interface float status
         in the System Parameter Form, i.e. OPEN_INTERFACE_FLOAT_STATUS column
         in the CE_SYSTEM_PARAMETERS_ALL table, you are required to do so. */

      /* Example of unclear procedure */
      --lp_update_999;
      lp_print (' * * * * * NO CUSTOMIZATION FOR UNCLEAR * * * * ', 'BOTH');
   /* Reconciliation Accounting Logic goes here */
   --NULL;
   END unclear;
END ce_999_pkg;
/