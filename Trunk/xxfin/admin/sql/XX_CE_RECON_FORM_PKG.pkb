CREATE OR REPLACE PACKAGE BODY xx_ce_recon_form_pkg
AS
-- +=========================================================================================+
-- |  Office Depot - Project Simplify                                                        |
-- |  Providge Consulting                                                                    |
-- +=========================================================================================+
-- |  Name:  XX_CE_RECON_FORM_PKG                                                            |    
-- |  RICE : I3091                                                                           |
-- |  Description:  This package is used by the OD Unmatched CC Deposits form.               |
-- |                                                                                         |
-- |  Change Record:                                                                         |
-- +=========================================================================================+
-- | Version     Date         Author           Remarks                                       |
-- | =========   ===========  =============    ==============================================|
-- | 1.0         14-Feb-2008  B.Looman         Initial version                               |
-- |             03-Jun-2008  D.Gowda          Defect 7632 Add parameter p_trx_001_id to     |
-- |                                           update submitted_bank_stmt_ln and lockbox_stmt|
-- |             20-Oct-2008  D. Gowda         Defect 12022-Update field JE_STATUS_FLAG to   |
-- |                                           NULL on statement line after matching(same as |
-- |                                           defect 9338)                                  |
-- |             27-Oct-2008  D. Gowda         Defect 12163 - Update flag after Journal Entry|
-- |                                            is created and record GroupID for JE.        |
-- | 2.0         08-Jul-2013  Darshini         E1297 - Modified for R12 Upgrade Retrofit     |
-- | 2.1         19-SEP-2013  Darshini         E1297 - Modified to change trx_code_id        | 
-- |                                           to trx_code                                   |
-- | 2.2         10-FEB-2015  Madhan Sanjeevi  Defect# 33454 - Discrepancy in Accounting Date|
-- |                                           for the same Journal Group ID                 |
-- | 2.3         29-OCT-2013  Avinash          R12.2 Compliance Changes	                     |
-- | 2.4         05-JUL-2018  Paddy Sanjeevi   To use index for is_bank_stmt_submitted,      |
-- |                                           is_lockbox_in_interface,update_submitted_lockbox_stmt|
-- +================================================================================================+
   TYPE t_recon_tab IS TABLE OF xx_ce_recon_jrnl%ROWTYPE
      INDEX BY PLS_INTEGER;

-- +=========================================================================================+
-- Fetches the org-specific AR system parameters (i.e. set of books, currency, etc.)
-- +=========================================================================================+
-- Commented and added by Darshini(2.0) for R12 Upgrade Retrofit
   /*PROCEDURE get_ar_system_parameters (
      x_chart_of_accounts_id   OUT   gl_sets_of_books.chart_of_accounts_id%TYPE
    , x_currency_code          OUT   gl_sets_of_books.currency_code%TYPE
    , x_gl_short_name          OUT   gl_sets_of_books.short_name%TYPE
    , x_set_of_books_id        OUT   gl_sets_of_books.set_of_books_id%TYPE
   )*/
   PROCEDURE get_ar_system_parameters (
      x_chart_of_accounts_id   OUT   gl_ledgers.chart_of_accounts_id%TYPE
    , x_currency_code          OUT   gl_ledgers.currency_code%TYPE
    , x_gl_short_name          OUT   gl_ledgers.short_name%TYPE
    , x_set_of_books_id        OUT   gl_ledgers.ledger_id%TYPE
   )
   --end of addition
   IS
      lc_sub_name   CONSTANT VARCHAR2 (50) := 'GET_AR_SYSTEM_PARAMETERS';

      CURSOR c_ar_params
      IS
         SELECT gl.chart_of_accounts_id, gl.currency_code, gl.short_name
              , gl.ledger_id
		   --Commented and added by Darshini(2.0) for R12 Upgrade Retrofit
           --FROM gl_sets_of_books gl, 
		     FROM gl_ledgers gl,
			 --end of addition
		        ar_system_parameters asp
          WHERE asp.set_of_books_id = gl.ledger_id;
   BEGIN
      OPEN c_ar_params;

      FETCH c_ar_params
       INTO x_chart_of_accounts_id, x_currency_code, x_gl_short_name
          , x_set_of_books_id;

      CLOSE c_ar_params;
   END;

-- +============================================================================================+
-- Gets the nextval from the XX_CE_999_INTERFACE_S sequence
-- +============================================================================================+
   FUNCTION get_999_interface_nextval
      RETURN NUMBER
   IS
      lc_sub_name   CONSTANT VARCHAR2 (50) := 'GET_999_INTERFACE_NEXTVAL';
      ln_next_id             NUMBER        DEFAULT NULL;

      CURSOR c_nextval
      IS
         SELECT xx_ce_999_interface_s.NEXTVAL
           FROM DUAL;
   BEGIN
      OPEN c_nextval;

      FETCH c_nextval
       INTO ln_next_id;

      CLOSE c_nextval;

      RETURN ln_next_id;
   END;

-- +============================================================================================+
-- Gets the nextval from the XX_CE_LOCKBOX_TRANS_ID_S sequence
-- +============================================================================================+
   FUNCTION get_lockbox_trans_id_nextval
      RETURN NUMBER
   IS
      lc_sub_name   CONSTANT VARCHAR2 (50) := 'GET_LOCKBOX_TRANS_ID_NEXTVAL';
      ln_next_id             NUMBER        DEFAULT NULL;

      CURSOR c_nextval
      IS
         SELECT xx_ce_lockbox_trans_id_s.NEXTVAL
           FROM DUAL;
   BEGIN
      OPEN c_nextval;

      FETCH c_nextval
       INTO ln_next_id;

      CLOSE c_nextval;

      RETURN ln_next_id;
   END;

-- +============================================================================================+
-- Gets the nextval from the XX_CE_RECON_JRNL_ID_S sequence
-- +============================================================================================+
   FUNCTION get_recon_jrnl_id_nextval
      RETURN NUMBER
   IS
      lc_sub_name   CONSTANT VARCHAR2 (50) := 'GET_RECON_JRNL_ID_NEXTVAL';
      ln_next_id             NUMBER        DEFAULT NULL;

      CURSOR c_nextval
      IS
         SELECT xx_ce_recon_jrnl_id_s.NEXTVAL
           FROM DUAL;
   BEGIN
      OPEN c_nextval;

      FETCH c_nextval
       INTO ln_next_id;

      CLOSE c_nextval;

      RETURN ln_next_id;
   END;

-- +============================================================================================+
-- Gets the nextval from the GL_INTERFACE_CONTROL_S sequence
-- +============================================================================================+
   FUNCTION get_gl_iface_group_id_nextval
      RETURN NUMBER
   IS
      lc_sub_name   CONSTANT VARCHAR2 (50) := 'GET_GL_IFACE_GROUP_ID_NEXTVAL';
      ln_next_id             NUMBER        DEFAULT NULL;

      CURSOR c_nextval
      IS
         SELECT gl_interface_control_s.NEXTVAL
           FROM DUAL;
   BEGIN
      OPEN c_nextval;

      FETCH c_nextval
       INTO ln_next_id;

      CLOSE c_nextval;

      RETURN ln_next_id;
   END;

-- +============================================================================================+
-- Returns True/False if bank deposit statement has already been submitted
-- +============================================================================================+
   FUNCTION is_bank_stmt_submitted (
      p_statement_header_id   IN   ce_statement_headers.statement_header_id%TYPE
    , p_statement_line_id     IN   ce_statement_lines.statement_line_id%TYPE
   )
      RETURN BOOLEAN
   IS
      lc_sub_name   CONSTANT VARCHAR2 (50) := 'IS_BANK_STMT_SUBMITTED';
      n_submit_cnt           NUMBER        DEFAULT NULL;

      CURSOR c_submitted
      IS
         SELECT COUNT (1)
           FROM xx_ce_999_interface
          WHERE deposits_matched = 'Y'
            AND statement_header_id = TO_CHAR(p_statement_header_id)
            AND statement_line_id = p_statement_line_id;
   BEGIN
      -- get count of deposits matched
      OPEN c_submitted;

      FETCH c_submitted
       INTO n_submit_cnt;

      CLOSE c_submitted;

      -- return if if any deposits already
      IF (n_submit_cnt > 0)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END;

-- +============================================================================================+
-- function checking if lockbox transmissions exist for this lockbox statement
-- +============================================================================================+
   FUNCTION lockbox_transmissions_exist (
      p_statement_header_id   IN   ce_statement_headers.statement_header_id%TYPE
    , p_bank_account_id       IN   ce_statement_headers.bank_account_id%TYPE
    , p_lockbox_number        IN   ar_lockboxes.lockbox_number%TYPE
    , p_statement_date        IN   ce_statement_headers.statement_date%TYPE
   )
      RETURN BOOLEAN
   IS
      n_count   NUMBER DEFAULT 0;

      CURSOR c_trans
      IS
         SELECT COUNT (1)
           FROM xx_ce_lockbox_transmissions
          WHERE bank_account_id = p_bank_account_id
            AND lockbox_number = p_lockbox_number
            AND deposit_date = p_statement_date;
   BEGIN
      OPEN c_trans;

      FETCH c_trans
       INTO n_count;

      CLOSE c_trans;

      IF (n_count > 0)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END;

-- +============================================================================================+
-- function checking if interface lines exist for this lockbox statement
-- +============================================================================================+
   FUNCTION is_lockbox_in_interface (
      p_statement_header_id   IN   ce_statement_headers.statement_header_id%TYPE
    , p_lockbox_number        IN   ar_lockboxes.lockbox_number%TYPE
   )
      RETURN BOOLEAN
   IS
      n_count   NUMBER DEFAULT 0;

      CURSOR c_iface
      IS
         SELECT COUNT (1)
           FROM xx_ce_999_interface
          WHERE statement_header_id = TO_CHAR(p_statement_header_id)
            AND lockbox_number = p_lockbox_number;
   BEGIN
      OPEN c_iface;

      FETCH c_iface
       INTO n_count;

      CLOSE c_iface;

      IF (n_count > 0)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END;

-- +============================================================================================+
-- Create lockbox transmissions for the transmissions that match the statement
-- +============================================================================================+
   PROCEDURE create_lockbox_transmissions (
      p_statement_header_id   IN       ce_statement_headers.statement_header_id%TYPE
    , p_bank_account_id       IN       ce_statement_headers.bank_account_id%TYPE
    , p_lockbox_number        IN       ar_lockboxes.lockbox_number%TYPE
    , p_statement_date        IN       ce_statement_headers.statement_date%TYPE
    , x_receipt_method_id     OUT      ar_receipt_methods.receipt_method_id%TYPE
   )
   IS
      CURSOR c_rcpt_mthd
      IS
         SELECT receipt_method_id
           FROM xx_ce_lockbox_transmissions
          WHERE bank_account_id = p_bank_account_id
            AND lockbox_number = p_lockbox_number
            AND deposit_date = p_statement_date;
   BEGIN
      INSERT INTO xx_ce_lockbox_transmissions
                  (lockbox_transmission_id, statement_header_id
                 , bank_account_id, lockbox_number, receipt_method_id
                 , deposit_date, transmission_id, deposits_matched, amount
                 , manually_matched, creation_date, created_by
                 , last_update_date, last_updated_by)
         (SELECT xx_ce_lockbox_trans_id_s.NEXTVAL, p_statement_header_id
               , bank_account_id, lockbox_number, receipt_method_id
               , deposit_date, transmission_id, 'N', amount, 'Y', SYSDATE
               , fnd_global.user_id, SYSDATE, fnd_global.user_id
            FROM xx_ce_lockbox_transmissions_v
           WHERE bank_account_id = p_bank_account_id
             AND lockbox_number = p_lockbox_number
             AND deposit_date = p_statement_date);

      OPEN c_rcpt_mthd;

      FETCH c_rcpt_mthd
       INTO x_receipt_method_id;

      CLOSE c_rcpt_mthd;
   END;

-- +============================================================================================+
-- Create interface lines for the lockbox stmt lines
-- +============================================================================================+
   PROCEDURE create_lockbox_interface_lines (
      p_statement_header_id   IN   ce_statement_headers.statement_header_id%TYPE
    , p_lockbox_number        IN   ar_lockboxes.lockbox_number%TYPE
    , p_receipt_method_id     IN   ar_receipt_methods.receipt_method_id%TYPE
   )
   IS
      ln_trx_id         xx_ce_999_interface.trx_id%TYPE   DEFAULT NULL;

      CURSOR c_stmt_line
      IS
         SELECT bank_account_id, bank_account_num, statement_header_id
              , statement_line_id, statement_date, currency_code, amount
              , lockbox_number, trx_code_id, bank_trx_number
			  , trx_code -- Added for R12 Upgrade Retrofit
           FROM xx_ce_stmt_lockbox_lines_v
          WHERE statement_header_id = p_statement_header_id
            AND lockbox_number = p_lockbox_number;

      TYPE t_stmt_line_tab IS TABLE OF c_stmt_line%ROWTYPE
         INDEX BY PLS_INTEGER;

      l_stmt_line_tab   t_stmt_line_tab;
   BEGIN
      OPEN c_stmt_line;

      FETCH c_stmt_line
      BULK COLLECT INTO l_stmt_line_tab;

      CLOSE c_stmt_line;

      IF (l_stmt_line_tab.COUNT > 0)
      THEN
         FOR i_index IN l_stmt_line_tab.FIRST .. l_stmt_line_tab.LAST
         LOOP
            ln_trx_id := get_999_interface_nextval ();

            INSERT INTO xx_ce_999_interface
                        (trx_id, bank_account_id
                       , trx_type, trx_number
                       , trx_date
                       , currency_code, status
                       , amount, record_type
                       , bank_account_num
                       , lockbox_deposit_date, lockbox_batch
                       , lockbox_number
                       , receipt_method_id
                       , statement_header_id
                       , statement_line_id
                       , GROUP_ID, manually_matched
                       , creation_date, created_by, last_update_date
                       , last_updated_by, receipts_processed_ctr
                       , chargebacks_processed_ctr, deposits_matched
                       , expenses_complete, receipts_complete
                       , chargebacks_complete, bank_trx_code_id_original
                       , bank_trx_number_original
					   , bank_trx_code_original -- Added for R12 Upgrade Retrofit
                        )
                 VALUES (ln_trx_id, l_stmt_line_tab (i_index).bank_account_id
                       , 'CASH', ln_trx_id
                       , l_stmt_line_tab (i_index).statement_date
                       , l_stmt_line_tab (i_index).currency_code, 'FLOAT'
                       , l_stmt_line_tab (i_index).amount, 'LOCKBOX_DAY'
                       , l_stmt_line_tab (i_index).bank_account_num
                       , l_stmt_line_tab (i_index).statement_date, NULL
                       ,                     -- NVL(customer_text,invoice_text),
                         l_stmt_line_tab (i_index).lockbox_number
                       , p_receipt_method_id
                       , l_stmt_line_tab (i_index).statement_header_id
                       , l_stmt_line_tab (i_index).statement_line_id
                       , l_stmt_line_tab (i_index).statement_line_id, 'Y'
                       , SYSDATE, fnd_global.user_id, SYSDATE
                       , fnd_global.user_id, 0
                       , 0, 'N'
                       , 'N', 'N'
                       , 'N', l_stmt_line_tab (i_index).trx_code_id
                       , l_stmt_line_tab (i_index).bank_trx_number
					   , l_stmt_line_tab (i_index).trx_code -- Added for R12 Upgrade Retrofit
                        );
         END LOOP;
      END IF;
   END;

-- +============================================================================================+
-- Update the statement line for the submitted bank deposit statement
-- +============================================================================================+
   PROCEDURE update_submitted_bank_stmt_ln (
      p_statement_header_id   IN   ce_statement_headers.statement_header_id%TYPE
    , p_statement_line_id     IN   ce_statement_lines.statement_line_id%TYPE
    , p_interface_trx_id      IN   xx_ce_999_interface.trx_id%TYPE
    , p_trx_001_id            IN   ce_transaction_codes.transaction_code_id%TYPE
	, p_trx_001_code          IN   ce_transaction_codes.trx_code%TYPE --Added for R12 Upgrade Retrofit
   )
   IS
      lc_sub_name   CONSTANT VARCHAR2 (50) := 'UPDATE_SUBMITTED_BANK_STMT_LN';
   BEGIN
      UPDATE ce_statement_lines
         --Commented and added for R12 Upgrade Retrofit
		 --SET attribute9 = trx_code_id
		 SET attribute9 = trx_code
           , attribute10 = bank_trx_number
           , trx_code_id = p_trx_001_id
		   , trx_code = p_trx_001_code --Added for R12 Upgrade Retrofit
           , bank_trx_number = p_interface_trx_id
           , je_status_flag = NULL                               -- Defect 12022
           , last_update_date = SYSDATE
           , last_updated_by = fnd_global.user_id
       WHERE statement_header_id = p_statement_header_id
         AND statement_line_id = p_statement_line_id;
   END;

-- +============================================================================================+
-- Update the statement lines for the submitted lockbox statement
-- +============================================================================================+
   PROCEDURE update_submitted_lockbox_stmt (
      p_statement_header_id   IN   ce_statement_headers.statement_header_id%TYPE
    , p_bank_account_id       IN   xx_ce_stmt_cc_deposits_v.bank_account_id%TYPE
    , p_lockbox_number        IN   ar_lockboxes.lockbox_number%TYPE
    , p_statement_date        IN   ce_statement_headers.statement_date%TYPE
    , p_interface_trx_id      IN   xx_ce_999_interface.trx_id%TYPE
    , p_trx_001_id            IN   ce_transaction_codes.transaction_code_id%TYPE
	, p_trx_001_code          IN   ce_transaction_codes.trx_code%TYPE --Added for R12 Upgrade Retrofit
   )
   IS
      lc_sub_name   CONSTANT VARCHAR2 (50) := 'UPDATE_SUBMITTED_LOCKBOX_STMT';

      CURSOR intf_stmt_lines
      IS
         SELECT trx_id, statement_line_id, statement_header_id
              , bank_trx_code_id_original, bank_trx_number_original
			  , bank_trx_code_original --Added for R12 Upgrade Retrofit
           FROM xx_ce_999_interface xc9i
          WHERE 1 = 1
            AND xc9i.bank_account_id = p_bank_account_id
            AND xc9i.statement_header_id = TO_CHAR(p_statement_header_id)
            AND xc9i.lockbox_number = p_lockbox_number
            AND xc9i.lockbox_deposit_date = p_statement_date
            AND xc9i.record_type = 'LOCKBOX_DAY'
            AND xc9i.manually_matched = 'Y';
   BEGIN
      FOR intf_stmt_lines_rec IN intf_stmt_lines
      LOOP
         UPDATE ce_statement_lines l
            SET attribute9 =
                   /* Commented and added for R12 Upgrade Retrofit
				   NVL (intf_stmt_lines_rec.bank_trx_code_id_original
                      , l.trx_code_id
                       )*/
					   NVL (intf_stmt_lines_rec.bank_trx_code_original
                      , l.trx_code
                       )
              , attribute10 =
                   NVL (intf_stmt_lines_rec.bank_trx_number_original
                      , l.bank_trx_number
                       )
              , trx_code_id = p_trx_001_id
			  , trx_code = p_trx_001_code --Added for R12 Upgrade Retrofit
              , bank_trx_number = intf_stmt_lines_rec.trx_id     -- Defect 12078
              , je_status_flag = NULL                            -- Defect 12022
              , last_update_date = SYSDATE
              , last_updated_by = fnd_global.user_id
          WHERE statement_header_id = intf_stmt_lines_rec.statement_header_id
            AND l.statement_line_id = intf_stmt_lines_rec.statement_line_id;
          -- Defect 12078 - Since the Stmt Line ID is being selected from
          -- the open interface the below check is not required.
--            AND EXISTS
--                     -- defect 5822,update only lines for this bank/lockbox/date
--                      (
--                  SELECT 1
--                    FROM xx_ce_stmt_lockbox_lines_v
--                   WHERE statement_line_id = l.statement_line_id
--                     AND statement_header_id = p_statement_header_id
--                     AND bank_account_id = p_bank_account_id
--                     AND lockbox_number = p_lockbox_number
--                     AND statement_date = p_statement_date);
      END LOOP;                                          -- intf_stmt_lines loop

      UPDATE xx_ce_999_interface
         SET deposits_matched = 'Y'
       WHERE statement_header_id = TO_CHAR(p_statement_header_id)
         AND lockbox_number = p_lockbox_number
         AND lockbox_deposit_date = p_statement_date;

      UPDATE xx_ce_lockbox_transmissions
         SET deposits_matched = 'Y'
       WHERE statement_header_id = p_statement_header_id
         AND lockbox_number = p_lockbox_number
         AND deposit_date = p_statement_date;
   END;

-- +============================================================================================+
-- Create the GL Recon Journal Entries for this submitted bank statement
-- +============================================================================================+
   PROCEDURE create_gl_recon_je (
      p_recon_tab   IN OUT NOCOPY   t_recon_tab
    , x_group_id    OUT             gl_interface.GROUP_ID%TYPE
   )
   IS
      lc_sub_name   CONSTANT VARCHAR2 (50)              := 'CREATE_GL_RECON_JE';
      lc_group_id            gl_interface.GROUP_ID%TYPE   DEFAULT NULL;
      x_gl_output_msg        VARCHAR2 (4000)              DEFAULT NULL;
      ln_count               NUMBER                       := 0;
   BEGIN
      lc_group_id := get_gl_iface_group_id_nextval ();

      FOR i_index IN p_recon_tab.FIRST .. p_recon_tab.LAST
      LOOP
         xx_gl_interface_pkg.create_stg_jrnl_line
                (p_status => p_recon_tab (i_index).status
               , p_date_created => p_recon_tab (i_index).creation_date
               , p_created_by => p_recon_tab (i_index).created_by
               , p_actual_flag => p_recon_tab (i_index).actual_flag
               , p_group_id => lc_group_id
               , p_batch_name => p_recon_tab (i_index).batch_name
               , p_batch_desc => p_recon_tab (i_index).batch_desc
               , p_user_source_name => p_recon_tab (i_index).user_source_name
               , p_user_catgory_name => p_recon_tab (i_index).user_catgory_name
               , p_set_of_books_id => p_recon_tab (i_index).set_of_books_id
               , p_accounting_date => p_recon_tab (i_index).accounting_date
               , p_currency_code => p_recon_tab (i_index).currency_code
               , p_company => p_recon_tab (i_index).gl_company
               , p_cost_center => p_recon_tab (i_index).gl_cost_center
               , p_account => p_recon_tab (i_index).gl_account
               , p_location => p_recon_tab (i_index).gl_location
               , p_intercompany => p_recon_tab (i_index).gl_intercompany
               , p_channel => p_recon_tab (i_index).gl_channel
               , p_future => p_recon_tab (i_index).gl_future
               , p_entered_dr => p_recon_tab (i_index).entered_dr
               , p_entered_cr => p_recon_tab (i_index).entered_cr
               , p_je_name => p_recon_tab (i_index).je_name
               , p_je_line_dsc => p_recon_tab (i_index).je_line_dsc
               , x_output_msg => x_gl_output_msg
                );
         ln_count := ln_count + 1;

         IF (x_gl_output_msg IS NOT NULL)
         THEN
            DBMS_OUTPUT.put_line ('GL-MSG: ' || x_gl_output_msg);
            raise_application_error
                        (-20002
                       ,    'Errors in creating the staged GL Journal Entries.'
                         || CHR (10)
                         || x_gl_output_msg
                        );
         END IF;

         x_group_id := lc_group_id;
      --UPDATE xx_ce_recon_jrnl
      --   SET sent_to_gl_flag = 'Y'
      -- WHERE recon_jrnl_id = p_recon_tab(i_index).recon_jrnl_id;
      --DBMS_OUTPUT.put_line ('Updated ' || SQL%ROWCOUNT || ' row[s].');
      END LOOP;
   END;

-- +============================================================================================+
-- Create the GL Recon Journal Entries for this AJB CC stmt
-- +============================================================================================+
   PROCEDURE create_ajb_cc_gl (
      p_statement_header_id   IN   ce_statement_headers.statement_header_id%TYPE
    , p_statement_line_id     IN   ce_statement_lines.statement_line_id%TYPE
   )
   IS
      lc_sub_name   CONSTANT VARCHAR2 (50)                := 'CREATE_AJB_CC_GL';
      ln_group_id            gl_interface.GROUP_ID%TYPE;
	  l_rec_cnt    NUMBER := 0; --Added for Defect# 33454
	  l_state_max_date DATE;

      CURSOR c_recon
      IS
         SELECT *
           FROM xx_ce_recon_jrnl
          WHERE statement_header_id = p_statement_header_id
            AND statement_line_id = p_statement_line_id;

      l_recon_tab            t_recon_tab;
   BEGIN
      --Added the below logic for Defect# 33454
	  SELECT COUNT(DISTINCT accounting_date) INTO l_rec_cnt
	  FROM xx_ce_recon_jrnl
          WHERE statement_header_id = p_statement_header_id
            AND statement_line_id = p_statement_line_id;
	  
      IF l_rec_cnt > 1 THEN
	    BEGIN
	      SELECT MAX(accounting_date) INTO l_state_max_date
			                           FROM xx_ce_recon_jrnl 
			                          WHERE statement_header_id = p_statement_header_id 
									    AND statement_line_id = p_statement_line_id;
	      UPDATE xx_ce_recon_jrnl
             SET  accounting_date = NVL(l_state_max_date,sysdate),
		          batch_name = TO_CHAR(NVL(l_state_max_date,sysdate),'YYYY/MM/DD')
           WHERE statement_header_id = p_statement_header_id
            AND statement_line_id = p_statement_line_id;

		 EXCEPTION
		     WHEN OTHERS THEN
			   NULL;
		END;
      END IF;	  
	
      OPEN c_recon;

      FETCH c_recon
      BULK COLLECT INTO l_recon_tab;
        
      IF (l_recon_tab.COUNT > 0)
      THEN
       create_gl_recon_je (p_recon_tab => l_recon_tab
                           , x_group_id => ln_group_id
                            );
	  END IF;

      CLOSE c_recon;

      -- Defect 12163 - Update flag after Journal Entry is created.
      UPDATE xx_ce_recon_jrnl
         SET sent_to_gl_flag = 'Y'
           , status = 'TRANSFERRED'
           , GROUP_ID = ln_group_id
       WHERE statement_header_id = p_statement_header_id
         AND statement_line_id = p_statement_line_id;
	  
   END;

-- +============================================================================================+
-- Create the GL Recon Journal Entries for this lockbox stmt
-- +============================================================================================+
   PROCEDURE create_lockbox_gl (
      p_statement_header_id   IN   ce_statement_headers.statement_header_id%TYPE
    , p_bank_account_id       IN   xx_ce_stmt_cc_deposits_v.bank_account_id%TYPE
    , p_lockbox_number        IN   ar_lockboxes.lockbox_number%TYPE
    , p_statement_date        IN   ce_statement_headers.statement_date%TYPE
   )
   IS
      lc_sub_name   CONSTANT VARCHAR2 (50)               := 'CREATE_LOCKBOX_GL';

      CURSOR c_recon
      IS
         SELECT *
           FROM xx_ce_recon_jrnl
          WHERE statement_header_id = p_statement_header_id
            AND lockbox_number = p_lockbox_number
            AND statement_date = p_statement_date;

      l_recon_tab            t_recon_tab;
      ln_group_id            gl_interface.GROUP_ID%TYPE;
   BEGIN
      OPEN c_recon;

      FETCH c_recon
      BULK COLLECT INTO l_recon_tab;

      CLOSE c_recon;

      IF (l_recon_tab.COUNT > 0)
      THEN
         create_gl_recon_je (p_recon_tab => l_recon_tab
                           , x_group_id => ln_group_id      --Defect 12163
                            );
      END IF;

      UPDATE xx_ce_999_interface
         SET expenses_complete = 'Y'
       WHERE statement_header_id = p_statement_header_id
         AND lockbox_number = p_lockbox_number
         AND lockbox_deposit_date = p_statement_date;

      UPDATE xx_ce_recon_jrnl
         SET sent_to_gl_flag = 'Y'
           , status = 'TRANSFERRED'            --Defect 12163
           , GROUP_ID = ln_group_id
       WHERE statement_header_id = p_statement_header_id
         AND lockbox_number = p_lockbox_number
         AND statement_date = p_statement_date;
   END;

-- +============================================================================================+
-- Delete the incomplete (not submitted) xx_ce_999_interface lines
-- +============================================================================================+
   PROCEDURE delete_incomplete_interface_ln
   IS
      lc_sub_name   CONSTANT VARCHAR2 (50) := 'DELETE_INCOMPLETE_INTERFACE_LN';
   BEGIN
      DELETE FROM xx_ce_999_interface
            WHERE manually_matched = 'Y'
              AND deposits_matched = 'N'
              AND expenses_complete = 'N'
              AND record_type = 'LOCKBOX_DAY';
   END;
   
  
--Added for the Defect# 37945
-- +============================================================================================+
-- Update the incomplete xx_ce_999_interface lines
-- +============================================================================================+

	PROCEDURE check_incomplete_lines(
		p_statement_header_id   IN   ce_statement_headers.statement_header_id%TYPE
	  , p_statement_line_id     IN   ce_statement_lines.statement_line_id%TYPE
	  , p_bank_rec_id			IN	 xx_ce_999_interface.bank_rec_id%type
	  , p_processor_id			IN	 xx_ce_999_interface.processor_id%type
	  , p_trx_type				IN	 xx_ce_999_interface.trx_type%type
	  , p_currency				IN	 xx_ce_999_interface.currency_code%type	
	)
	IS
		lc_sub_name   CONSTANT VARCHAR2 (50) := 'CHECK_INCOMPLETE_LINES';
		
		ln_count	NUMBER	:= 0;
		ln_bank_account_id		xx_ce_999_interface.bank_account_id%type  DEFAULT NULL;
		ln_bank_account_num		xx_ce_999_interface.bank_account_num%type  DEFAULT NULL;
		ln_amount				xx_ce_999_interface.amount%type  DEFAULT NULL;
		ln_trx_code_original	xx_ce_999_interface.bank_trx_code_original%type  DEFAULT NULL;
		
		
	BEGIN
	
		SELECT	count(1)
		INTO	ln_count
		FROM	xx_ce_999_interface
		WHERE	bank_rec_id = p_bank_rec_id
		AND 	processor_id = p_processor_id
		AND 	status is NULL
		AND		amount is null
		AND 	creation_date > sysdate-1;
		
		IF(ln_count = 1)
		THEN
				SELECT  csh.bank_account_id
					  , csl.amount
					  , aba.bank_account_num
					  , csl.attribute9 trx_code_original
				INTO	ln_bank_account_id
				      , ln_amount
					  , ln_bank_account_num
					  , ln_trx_code_original
				FROM	ce_statement_lines csl
					  , ce_statement_headers csh
					  , ce_bank_accounts aba
				WHERE	csl.statement_header_id = csh.statement_header_id
				AND		csh.bank_account_id = aba.bank_account_id
				AND		csl.statement_line_id = p_statement_line_id;
				
				
				UPDATE	xx_ce_999_interface
				SET		bank_account_id = ln_bank_account_id
					  , trx_type = p_trx_type
					  , currency_code = p_currency
					  , status = 'FLOAT'
					  , amount = ln_amount
					  , record_type = 'AJB'
					  , bank_account_num = ln_bank_account_num
					  , group_id = p_statement_line_id
					  , bank_trx_code_original = ln_trx_code_original
				WHERE	bank_rec_id = p_bank_rec_id
				AND		processor_id = p_processor_id
				AND 	status is NULL;
				
		END IF;
		EXCEPTION
		     WHEN OTHERS THEN
			   NULL;
		
	END;
   
END;
/

