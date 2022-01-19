create or replace PACKAGE BODY xx_ce_lockbox_recon_pkg
AS
-- +==========================================================================================+
-- |                       Office Depot - Project Simplify                                    |
-- |                            Providge Consulting                                           |
-- +==========================================================================================+
-- | Name       : XX_CE_LOCKBOX_RECON_PKG.pkb                                                 |
-- | Description: Cash Management Lockbox Reconciliation E1297-Extension                      |
-- |                                                                                          |
-- |                                                                                          |
-- |                                                                                          |
-- |                                                                                          |
-- |Change Record                                                                             |
-- |==============                                                                            |
-- |Version   Date         Authors            Remarks                                         |
-- |========  ===========  ===============    ================================================|
-- |DRAFT 1A  10-JUL-2007  Sunayan Mohanty    Initial draft version                           |
-- |1.0       03-AUG-2007  Sunayan Mohanty    Incorporated all the review comments            |
-- |          24-SEP-2007  Terry Banks        Set to read only trx_code 115 CSL rows          |
-- |          16-OCT-2007  Sunayan Mohanty    Added the trx Code'001' Validation              |
-- |          23-OCT-2007  Sunayan Mohanty    Use Lockbox Number to find out the Batch Amount |
-- |                                          from AR_Batches for all close transmission      |
-- |                                          Remove the GL entry for any difference amount   |
-- |                                          Bank of America and 5/3rd Bank are going to     |
-- |                                          provide lockbox number in invoice text column   |
-- |                                          Added Email id p_email_id as parameter to use   |
-- |          24-OCT-2007  Sunayan Mohanty    Added Bank Account in Output Report             |
-- |          06-NOV-2007  Sunayan Mohanty    Changed p_from_date and p_to_date are           |
-- |                                           non - mandatory                                |
-- |                                          Changed the matching of bank deposit            |
-- |                                            and in CE statement lines for sum of          |
-- |                                            same lockbox number                           |
-- |          02-FEB-2008  Terry Banks        Changed ajb_file_number to bank_rec_id          |
-- |                                          to allow for table changes.                     |
-- |          20-MAR-2008  Deepak Gowda       Resolution of defects 5601,5602 and 5603        |
-- |                                          Added Lockbox Number to 999_Interface.          |
-- |                                          Set Deposit Matched and Expenses complete flags |
-- |          26-SEP-2008  Deepak Gowda       Defect 11603-Remove hard coding of lockboxes    |
-- |                                          and move to tranlation OD_CE_GET_STMT_LOCKBOX   |
-- |          22-OCT-2008  Deepak Gowda       Record the automatically matched transmissions  |
-- |                                          so that they can be reviewed on manual from     |
-- |2.0       30-OCT-2008  Hemalatha S        Removed the hardcoded value for trx_code and    |
-- |                                          used the translation's source_value2 for        |
-- |                                          Defect # - 11634.                               |
-- |2.1       08-JUL-2013 Darshini            E1297 - Modified for R12 Upgrade Retrofit       |
-- |2.2       19-SEP-2013 Darshini            E1297 - Modified to change trx_code_id to       |
-- |                                          trx_code                                        |
-- |2.3       28-OCT-2013 Avinash             R12.2 Compliance Changes                        |
-- |2.4       22-FEB-2016 Havinder Rakhra     Defect 37221; Added to_char in query to improve performance|
-- |2.5       01-NOV-2017 Sreedhar Mohan      As part of VPS project modified where-clause to |
-- |                                          check ce_bank_accounts.bank_account_type 'LBX'  |
-- |2.6       16-NOV-2021 Shreyas Thorat      NAIT-174903 Unreconciled Bank Lines for Lockboxes unable    |
-- |                                          to manually clear - need process for auto clearing  |
-- +==========================================================================================+

   -- -------------------------------------------
-- Global Variables
-- -------------------------------------------
   gn_request_id          NUMBER        := fnd_global.conc_request_id;
   gn_user_id             NUMBER        := fnd_global.user_id;
   gn_login_id            NUMBER        := fnd_global.login_id;
   gn_org_id              NUMBER        := fnd_profile.VALUE ('ORG_ID');
   gn_set_of_bks_id       NUMBER        := fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
   gc_conc_short_name     VARCHAR2 (30) := 'XXCELOCKBOXRECON';
   gn_error               NUMBER        := 2;
   gn_warning             NUMBER        := 1;
   gn_normal              NUMBER        := 0;
   gc_lockbox_translation VARCHAR2 (30) := 'OD_CE_GET_STMT_LOCKBOX'; -- Modified for defect # - 11634.

-- +=================================================================================+
-- | Name        : PRINT_MESSAGE_HEADER                                              |
-- | Description : This procedure will be used to print the                          |
-- |               record process details                                            |
-- |                                                                                 |
-- | Parameters  : None                                                              |
-- |                                                                                 |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- |                                                                                 |
-- +=================================================================================+
   PROCEDURE print_message_header (
      x_errbuf    OUT NOCOPY   VARCHAR2
    , x_retcode   OUT NOCOPY   NUMBER
   )
   IS
   BEGIN
-- ------------------------------------------------
-- Set the Concurrent program Output header display
-- ------------------------------------------------
      fnd_file.new_line (fnd_file.output, 1);
      fnd_file.new_line (fnd_file.output, 1);
      fnd_file.put_line (fnd_file.output, RPAD ('=', 120, '='));
      fnd_file.put_line (fnd_file.output
                       ,    RPAD (' ', 35, ' ')
                         || 'Cash Management Lockbox Reconciliation Extension'
                         || RPAD (' ', 35, ' ')
                        );
      fnd_file.new_line (fnd_file.output, 1);
      fnd_file.put_line (fnd_file.output
                       ,    'Request ID : '
                         || gn_request_id
                         || RPAD (' ', 60, ' ')
                         || 'Request Date : '
                         || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH:MI:SS')
                        );
      fnd_file.put_line (fnd_file.output, RPAD ('=', 120, '='));
      fnd_file.new_line (fnd_file.output, 1);
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('Lockbox', 10, ' ')
                         || ' '
                         || RPAD ('Bank Account ', 23, ' ')
                         || ' '
                         || RPAD ('Statement#  ', 15, ' ')
                         || ' '
                         || RPAD ('Stmt Date ', 10, ' ')
                         || ' '
                         || RPAD ('Line#', 5, ' ')
                         || ' '
                         || LPAD ('Amount', 15, ' ')
                         || ' '
                         || RPAD ('Description', (120 - 83), ' ')
                        );
      fnd_file.put_line (fnd_file.output
                       ,    RPAD ('-', 10, '-')
                         || ' '
                         || RPAD ('-', 23, '-')
                         || ' '
                         || RPAD ('-', 15, '-')
                         || ' '
                         || RPAD ('-', 10, '-')
                         || ' '
                         || RPAD ('-', 5, '-')
                         || ' '
                         || RPAD ('-', 15, '-')
                         || ' '
                         || RPAD ('-', (120 - 83), '-')
                        );
      x_errbuf := NULL;
      x_retcode := gn_normal;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE'
                              , 'XX_CE_LOCKBOX_RECON_PKG.print_message_header'
                               );
         fnd_message.set_token ('PROGRAM'
                              , 'CE Lockbox Reconciliation Extension');
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
-- | p_message                IN      Message Details                                |
-- |                                                                                 |
-- |                                                                                 |
-- | PREREQUISITES                                                                   |
-- |   None.                                                                         |
-- |                                                                                 |
-- | CALLED BY                                                                       |
-- |   recon_process                                                                 |
-- |                                                                                 |
-- +=================================================================================+
   PROCEDURE print_message_footer (
      x_errbuf             OUT NOCOPY      VARCHAR2
    , x_retcode            OUT NOCOPY      NUMBER
    , p_statement_number   IN              VARCHAR2
    , p_stmt_line_num      IN              VARCHAR2
    , p_lockbox_num        IN              VARCHAR2
    , p_bank_act_num       IN              VARCHAR2
    , p_stmt_date          IN              DATE
    , p_stmt_amount        IN              NUMBER
    , p_message            IN              VARCHAR2
   )
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output
                       ,    RPAD (p_lockbox_num, 10, ' ')
                         || ' '
                         || RPAD (NVL (p_bank_act_num, ''), 23, ' ')
                         || ' '
                         || RPAD (NVL (p_statement_number, ' '), 15, ' ')
                         || ' '
                         || RPAD (NVL (TO_CHAR (p_stmt_date, 'DD-MON-RR'), ' ')
                                , 10
                                , ' '
                                 )
                         || ' '
                         || LPAD (NVL (p_stmt_line_num, ' '), 5, ' ')
                         || ' '
                         || LPAD (TO_CHAR (NVL (p_stmt_amount, 0)
                                         , '999G999G990D00'
                                          )
                                , 15
                                , ' '
                                 )
                         || ' '
                         || REPLACE (p_message
                                   , CHR (10)
                                   , CHR (10) || LPAD (' ', 85, ' ')
                                    )
                        );
      x_errbuf := NULL;
      x_retcode := gn_normal;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE'
                              , 'XX_CE_LOCKBOX_RECON_PKG.print_message_footer'
                               );
         fnd_message.set_token ('PROGRAM'
                              , 'CE Lockbox Reconciliation Extension');
         fnd_message.set_token ('SQLERROR', SQLERRM);
         x_errbuf := fnd_message.get;
         x_retcode := gn_error;
         fnd_file.put_line (fnd_file.LOG, '==========================');
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
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  recon_process                                                                  |
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
-------------------------------------------------------------------------------------------------
         fnd_file.new_line (fnd_file.output, 2);
         fnd_file.put_line (fnd_file.output, RPAD ('=', 120, '='));
         fnd_file.new_line (fnd_file.output, 1);
-------------------------------------------------------------------------------------------------
         fnd_file.put_line
             (fnd_file.output
            , '==============================================================='
             );
         fnd_file.put_line (fnd_file.output
                          , 'CE Lockbox Reconciliation Extension : ' || 'E1297'
                           );
         fnd_file.put_line
              (fnd_file.output
             , '==============================================================='
              );
         fnd_file.put_line (fnd_file.output
                          ,    RPAD ('Total Statement Lines', 25, ' ')
                            || ':'
                            || NVL (p_total, 0)
                           );
         fnd_file.put_line (fnd_file.output
                          ,    RPAD ('Error Records', 25, ' ')
                            || ':'
                            || NVL (p_error, 0)
                           );
         fnd_file.put_line (fnd_file.output
                          ,    RPAD ('Success Records', 25, ' ')
                            || ':'
                            || NVL (p_success, 0)
                           );
         fnd_file.put_line
              (fnd_file.output
             , '==============================================================='
              );
      ELSE
-------------------------------------------------------------------------------------------------------------
         fnd_file.put_line (fnd_file.output
                          ,    RPAD ('-', 50, '-')
                            || '  No Record Found for Processing   '
                            || RPAD ('-', 45, '-')
                           );
-------------------------------------------------------------------------------------------------------------
      END IF;

      x_errbuf := NULL;
      x_retcode := gn_normal;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE'
                              , 'XX_CE_LOCKBOX_RECON_PKG.print_message_summary'
                               );
         fnd_message.set_token ('PROGRAM', 'CE Lockbox Reconciliation');
         fnd_message.set_token ('SQLERROR', SQLERRM);
         x_errbuf := fnd_message.get;
         x_retcode := gn_error;
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
   END print_message_summary;

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  record_transmissions                                                           |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | This procedure will be used to create the                                       |
-- Create lockbox transmissions for the transmissions that match the statement       |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |p_statement_header_id    IN      Statement Header ID                             |
-- |p_bank_account_id        IN      Bank Account ID                                 |
-- |p_lockbox_number         IN      Lockbox Number                                  |
-- |p_deposit_date           IN      Lockbox Deposit Date                            |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  recon_process                                                                  |
-- +=================================================================================+
   PROCEDURE record_lockbox_transmissions (
      p_statement_header_id   IN   ce_statement_headers.statement_header_id%TYPE
    , p_bank_account_id       IN   ce_statement_headers.bank_account_id%TYPE
    , p_lockbox_number        IN   ar_lockboxes.lockbox_number%TYPE
    , p_statement_date        IN   ce_statement_headers.statement_date%TYPE
   )
   IS
   BEGIN
      INSERT INTO xx_ce_lockbox_transmissions
                  (lockbox_transmission_id, statement_header_id
                 , bank_account_id, lockbox_number, receipt_method_id
                 , deposit_date, transmission_id, deposits_matched, amount
                 , manually_matched, creation_date, created_by
                 , last_update_date, last_updated_by)
         (SELECT xx_ce_lockbox_trans_id_s.NEXTVAL, p_statement_header_id
               , bank_account_id, lockbox_number, receipt_method_id
               , deposit_date, transmission_id, 'Y', amount, 'N', SYSDATE
               , fnd_global.user_id, SYSDATE, fnd_global.user_id
            FROM xx_ce_lockbox_transmissions_v
           WHERE bank_account_id = p_bank_account_id
             AND lockbox_number = p_lockbox_number
             AND deposit_date = p_statement_date);
   END record_lockbox_transmissions;

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  create_open_interface                                                          |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | This procedure will be used to create the                                       |
-- | record into xx_ce_999_interface table for reconcilaition                        |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message.                                  |
-- |x_retcode                OUT     Error code.                                     |
-- |p_trx_code_id            IN      Trnsaction Code ID                              |
-- |p_bank_account_id        IN      Bank Account ID                                 |
-- |p_bank_trx_number_org    IN      Bank Transaction Number Original                |
-- |p_trx_date               IN      Transaction Date                                |
-- |p_currency_code          IN      Currency Code                                   |
-- |p_amount                 IN      Amount                                          |
-- |p_statement_header_id    IN      Statement Header ID                             |
-- |p_statement_line_id      IN      Statement Line ID                               |
-- |p_provider_code          IN      Provider Code                                   |
-- |p_receipt_method_id      IN      Receipt Method ID                               |
-- |p_lockbox_batch          IN      Lockbox Batch                                   |
-- |p_lockbox_deposit_date   IN      Lockbox Deposit Date                            |
-- |p_ajb_bank_rec_id        IN      AJB File Ref Number                             |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  recon_process                                                                  |
-- +=================================================================================+
   PROCEDURE create_open_interface (
      x_errbuf                 OUT NOCOPY      VARCHAR2
    , x_retcode                OUT NOCOPY      NUMBER
    , x_interface_seq          OUT NOCOPY      NUMBER
    , p_trx_code_id            IN              NUMBER
	, p_trx_code               IN              VARCHAR2 --Added for R12 Upgrade Retrofit
    , p_bank_account_id        IN              NUMBER
    , p_bank_trx_number_org    IN              VARCHAR2
    , p_trx_date               IN              DATE
    , p_currency_code          IN              VARCHAR2
    , p_amount                 IN              NUMBER
    , p_statement_header_id    IN              NUMBER
    , p_statement_line_id      IN              NUMBER
    , p_provider_code          IN              VARCHAR2
    , p_receipt_method_id      IN              NUMBER DEFAULT NULL
    , p_lockbox_batch          IN              VARCHAR2 DEFAULT NULL
    , p_lockbox_number         IN              VARCHAR2
    , p_lockbox_deposit_date   IN              DATE
    , p_ajb_bank_rec_id        IN              VARCHAR2
   )
   IS
      ln_ce_interface_seq   NUMBER;
   BEGIN
-- ------------------------------------------------
-- Get the Nexval Value
-- ------------------------------------------------
      SELECT xx_ce_999_interface_s.NEXTVAL
        INTO ln_ce_interface_seq
        FROM DUAL;

-- ------------------------------------------------
-- Insert the record into xx_ce_999_interface table
-- ------------------------------------------------
      INSERT INTO xx_ce_999_interface
                  (trx_id, bank_trx_code_id_original, bank_account_id
                 , trx_type, trx_type_dsp, trx_number, trx_date
                 , currency_code, status, amount, record_type
                 , bank_trx_number_original, lockbox_deposit_date
                 , lockbox_batch, lockbox_number, receipt_method_id
                 , deposits_matched, expenses_complete, statement_header_id
                 , statement_line_id, creation_date, created_by
                 , last_update_date, last_updated_by, bank_rec_id
				 , bank_trx_code_original --Added for R12 Upgrade Retrofit
                  )
           VALUES (ln_ce_interface_seq, p_trx_code_id, p_bank_account_id
                 , 'CASH', NULL, ln_ce_interface_seq, p_trx_date
                 , p_currency_code, 'FLOAT', p_amount, p_provider_code
                 , p_bank_trx_number_org, p_lockbox_deposit_date
                 , p_lockbox_batch, p_lockbox_number, p_receipt_method_id
                 , 'Y', 'Y', p_statement_header_id
                 , p_statement_line_id, SYSDATE, gn_user_id
                 , SYSDATE, gn_user_id, p_ajb_bank_rec_id
				 , p_trx_code --Added for R12 Upgrade Retrofit
                  );

      x_interface_seq := ln_ce_interface_seq;
      x_errbuf := NULL;
      x_retcode := gn_normal;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE'
                              , 'XX_CE_LOCKBOX_RECON_PKG.create_open_interface'
                               );
         fnd_message.set_token ('PROGRAM'
                              , 'CE Lockbox Reconciliation Extension');
         fnd_message.set_token ('SQLERROR', SQLERRM);
         x_errbuf := fnd_message.get;
         x_retcode := gn_error;
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
   END create_open_interface;

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  update_stmt_rec                                                                |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | This procedure will be used to update the                                       |
-- | status into CE Statement Header / Lines Tables after processing                 |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message.                                  |
-- |x_retcode                OUT     Error code.                                     |
-- |p_bank_stmt_header       IN      Statement Header ID                             |
-- |p_bank_stmt_line         IN      Statement Line ID                               |
-- |                                                                                 |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  recon_process                                                                  |
-- +=================================================================================+
   PROCEDURE update_stmt_rec (
      x_errbuf             OUT NOCOPY      VARCHAR2
    , x_retcode            OUT NOCOPY      NUMBER
    , p_bank_stmt_header   IN              NUMBER
    , p_bank_stmt_line     IN              NUMBER
    , p_bank_account_id    IN              NUMBER
    , p_create_gl          IN              VARCHAR2
    , p_interface_seq      IN              NUMBER
    , p_001_trx_code_id    IN              NUMBER DEFAULT NULL
    , p_001_trx_code       IN              VARCHAR2 DEFAULT NULL --Added for R12 Upgrade Retrofit
   )
   IS
   BEGIN
-- ------------------------------------------------
-- Update the record into ce_statement_headers_all
-- ce_statement_lines tables after processing the
-- each line record
-- ------------------------------------------------
      UPDATE ce_statement_lines csl
         SET attribute9 =
                DECODE (p_create_gl
				-- Commented and added for R12 Upgrade Retrofit
                      --, 'YES', trx_code_id
                      --, 'NO', trx_code_id
                      , 'YES', trx_code
                      , 'NO', trx_code
					  --end of addition
					  , attribute9
                       )
           , attribute10 =
                DECODE (p_create_gl
                      , 'YES', bank_trx_number
                      , 'NO', bank_trx_number
                      , attribute10
                       )
           , csl.attribute15 =
                DECODE (p_create_gl
                      , 'YES', 'PROCESSED-E1297'
                      , 'NO', 'PROCESSED-E1297'
                      , 'E', 'ERROR-E1297'
                       )
           , csl.bank_trx_number =
                DECODE (p_create_gl
                      , 'YES', p_interface_seq
                      , 'NO', p_interface_seq
                      , csl.bank_trx_number
                       )
			--Commented and added for R12 Upgrade Retrofit
           --, csl.trx_code_id =
		   , csl.trx_code =
                DECODE (p_create_gl
                      , 'YES', p_001_trx_code
                      , 'NO', p_001_trx_code
                      --Commented and added for R12 Upgrade Retrofit
					  --, csl.trx_code_id
					  , csl.trx_code
                       )
       WHERE csl.statement_header_id = p_bank_stmt_header
         AND csl.statement_line_id = p_bank_stmt_line;

      x_errbuf := NULL;
      x_retcode := gn_normal;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, '* * Error Updating Statement Line!');
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE'
                              , 'XX_CE_LOCKBOX_RECON_PKG.update_stmt_rec'
                               );
         fnd_message.set_token ('PROGRAM'
                              , 'CE Lockbox Reconciliation Extension');
         fnd_message.set_token ('SQLERROR', SQLERRM);
         x_errbuf := fnd_message.get;
         x_retcode := gn_error;
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
   END update_stmt_rec;

-- +=================================================================================+
-- |                                                                                 |
-- |FUNCTION                                                                         |
-- |  get_lockbox_num                                                                |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | Procedure to process the CE Bank Deposit and AR Receipts                        |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |p_bank_account_num        IN     Bank Account Number                             |
-- |p_invoice_text           IN     Text from Invoice text field on BAI Line         |
-- |x_lockbox_text           OUT    Lockbox Number                                   |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  Main Procedure                                                                 |
-- |                                                                                 |
-- +=================================================================================+
   FUNCTION get_lockbox_num (
      p_bank_account_num   IN   VARCHAR2
    , p_invoice_text       IN   VARCHAR2
    , p_trx_code           IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      lc_lockbox               ar_lockboxes_all.lockbox_number%TYPE;
      ln_start_char            NUMBER;
      ln_length                NUMBER;
      lp_out03                 VARCHAR2 (100);
      lp_out04                 VARCHAR2 (100);
      lp_out05                 VARCHAR2 (100);
      lp_out06                 VARCHAR2 (100);
      lp_out07                 VARCHAR2 (100);
      lp_out08                 VARCHAR2 (100);
      lp_out09                 VARCHAR2 (100);
      lp_out10                 VARCHAR2 (100);
      lp_out11                 VARCHAR2 (100);
      lp_out12                 VARCHAR2 (100);
      lp_out13                 VARCHAR2 (100);
      lp_out14                 VARCHAR2 (100);
      lp_out15                 VARCHAR2 (100);
      lp_out16                 VARCHAR2 (100);
      lp_out17                 VARCHAR2 (100);
      lp_out18                 VARCHAR2 (100);
      lp_out19                 VARCHAR2 (100);
      lp_out20                 VARCHAR2 (100);
      lc_tran_error            VARCHAR2 (1000);
   BEGIN
--      IF p_bank_account_num = '3756582099'
--      THEN
--         SELECT lockbox_number
--           INTO lc_lockbox
--           FROM ar_lockboxes
--          WHERE 1 = 1
--            AND status = 'A'
--            AND SUBSTR (lockbox_number, 1, 7) = SUBSTR (p_invoice_text, 1, 7);
--      ELSIF p_bank_account_num IN ('00089918474', '07021329490', '09990204472')
--      THEN
--         --5/3rd Bank Lockbox Accounts.
--         SELECT lockbox_number
--           INTO lc_lockbox
--           FROM ar_lockboxes
--          WHERE 1 = 1
--            AND status = 'A'
--            AND SUBSTR (lockbox_number, -3, 3) = SUBSTR (p_invoice_text, -3, 3);
--      ELSE
--         lc_lockbox := NULL;
--      END IF;

      xx_fin_translate_pkg.xx_fin_translatevalue_proc
                                 (p_translation_name => gc_lockbox_translation
                                , p_source_value1 => p_bank_account_num
                                , p_source_value2 => p_trx_code
                                , x_target_value1 => ln_start_char
                                , x_target_value2 => ln_length
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
                                , x_error_message => lc_tran_error
                                 );

      IF NVL (ln_start_char, 0) != 0
         AND NVL (ln_length, 0) != 0
         AND p_invoice_text IS NOT NULL
      THEN
         SELECT lockbox_number
           INTO lc_lockbox
           FROM ar_lockboxes
          WHERE 1 = 1
            AND status = 'A'
            AND SUBSTR (lockbox_number, ln_start_char, ln_length) =
                               SUBSTR (p_invoice_text, ln_start_char, ln_length);
      ELSE
         lc_lockbox := NULL;
      END IF;
	  --Start NAIT-174903 
	  IF p_bank_account_num = '09990204472' --AND p_trx_code = '555' 
	  THEN
	  BEGIN
		 SELECT lockbox_number
           INTO lc_lockbox
           FROM ar_lockboxes_all ar
          WHERE 1 = 1
            AND status = 'A'
            AND EXISTS (
				SELECT 1 
				FROM xx_fin_translatedefinition XFTD ,xx_fin_translatevalues XFT
				WHERE  XFTD.translate_id = XFT.translate_id
				AND    XFTD.translation_name = gc_lockbox_translation
				AND    XFT.enabled_flag = 'Y'
				AND    XFT.source_value1 = p_bank_account_num
				AND    XFT.source_value2 = p_trx_code
				AND (( SUBSTR (ar.lockbox_number, XFT.target_value1, xft.target_value2) = SUBSTR (p_invoice_text, XFT.target_value1, xft.target_value2))
						OR (ar.lockbox_number LIKE  '%'||SUBSTR (p_invoice_text, XFT.target_value1, xft.target_value2)||'%' )
					)
				/*
				AND ((length(p_invoice_text)<=7 AND  SUBSTR (ar.lockbox_number, XFT.target_value1, xft.target_value2) = SUBSTR (p_invoice_text, XFT.target_value1, xft.target_value2))
				OR (length(p_invoice_text)>7 AND ar.lockbox_number LIKE  '%'||SUBSTR (p_invoice_text, XFT.target_value1, xft.target_value2)||'%' )
				)*/
				);
		EXCEPTION		 
		WHEN  OTHERS THEN 
			lc_lockbox:= NULL;
		END;		

	  END IF;
	  --End NAIT-174903 

      RETURN lc_lockbox;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line (lc_tran_error);
         RETURN (NULL);
   END get_lockbox_num;

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  recon_process                                                                  |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | Procedure to process the CE Bank Deposit and AR Receipts                        |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message.                                  |
-- |x_retcode                OUT     Error code.                                     |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  Main Procedure                                                                 |
-- |                                                                                 |
-- +=================================================================================+
   PROCEDURE recon_process (
      x_errbuf          OUT NOCOPY      VARCHAR2
    , x_retcode         OUT NOCOPY      NUMBER
    , p_run_from_date   IN              VARCHAR2
    , p_run_to_date     IN              VARCHAR2
    , p_email_id        IN              VARCHAR2 DEFAULT NULL
   )
   IS
-- -------------------------------------------
-- Get the Chart of Accounts ID
-- -------------------------------------------
      CURSOR lcu_get_coaid
      IS
         SELECT gl.chart_of_accounts_id
		 -- Commented and added by Darshini(2.1) for R12 Upgrade Retrofit
           --FROM gl_sets_of_books gsob
		   --WHERE set_of_books_id = gn_set_of_bks_id;
		   FROM gl_ledgers gl
		  WHERE ledger_id = gn_set_of_bks_id;

-- -------------------------------------------
-- Cursor for get the Sum of total amount
-- for a lockbox and for date
-- -------------------------------------------
      CURSOR lcu_get_sum_lckbx_amt (p_from_date IN DATE, p_to_date IN DATE)
      IS
         SELECT   SUM (csl.amount) tot_lck_amount, cba.bank_account_num
                , csh.statement_header_id
                --, SUBSTR (csl.invoice_text, 1, 7) invoice_text
                  ,get_lockbox_num (cba.bank_account_num
                                  , csl.invoice_text
				                          , ctc.trx_code
                                   ) lockbox_num
                , csh.bank_account_id, csh.statement_date
             FROM ce_statement_headers csh
                , ce_statement_lines csl
				-- Commented and added by Darshini(2.1) for R12 Upgrade Retrofit
                --, ap_bank_accounts aba
				, ce_bank_accounts cba
				--end of addition
				, ce_transaction_codes ctc
                , ar_lockboxes al
            WHERE csh.statement_header_id = csl.statement_header_id
              AND csh.bank_account_id = cba.bank_account_id
              --Commented and added for R12 Upgrade Retrofit
			  --AND csl.trx_code_id = ctc.transaction_code_id(+)
			  AND csl.trx_code = ctc.trx_code(+)
              AND al.lockbox_number =
                        get_lockbox_num (cba.bank_account_num, csl.invoice_text, ctc.trx_code)
              AND ctc.trx_code IN (SELECT XFT.source_value2           -- Added this select statement for defect # - 11634
                                   FROM   xx_fin_translatedefinition XFTD
                                         ,xx_fin_translatevalues XFT
                                   WHERE  XFTD.translate_id = XFT.translate_id
                                   AND    XFTD.translation_name = gc_lockbox_translation
                                   AND    XFT.enabled_flag = 'Y'
                                   AND    XFT.source_value1 = cba.bank_account_num
                                   AND    XFT.source_value2 IS NOT NULL)
              AND ctc.bank_account_id = cba.bank_account_id
              AND (csl.status IS NULL
                   OR UPPER (csl.status) = 'UNRECONCILED')
              AND (csl.attribute15 IS NULL
                   OR csl.attribute15 NOT IN ('PROCESSED-E1297')
                  )
              AND csh.statement_date BETWEEN NVL (p_from_date
                                                , csh.statement_date
                                                 )
                                         AND NVL (p_to_date, csh.statement_date)
              AND (cba.bank_account_type LIKE 'Corporate%Lockbox' or cba.bank_account_type LIKE 'LBX')
              --Commented and added by Darshini(2.1) for R12 Upgrade Retrofit
			  --AND NVL (aba.inactive_date, p_from_date) BETWEEN p_from_date
			  AND NVL (cba.end_date, p_from_date) BETWEEN p_from_date  --end of addition
                                                           AND p_to_date
              --Changes for defect #18113
			  AND not exists ( SELECT '1' FROM xx_ce_lockbox_transmissions WHERE bank_account_id = csh.bank_account_id AND lockbox_number = al.lockbox_number AND deposit_date = csh.statement_date )
              AND not exists (SELECT '1' FROM xx_ce_999_interface xx WHERE xx.statement_header_id = TO_CHAR(csh.statement_header_id) AND xx.lockbox_number = al.lockbox_number )  --Version 2.4; Added TO_CHAR
              AND not exists ( SELECT '1' FROM xx_ce_999_interface yy WHERE yy.deposits_matched = 'Y' AND yy.statement_header_id = TO_CHAR(csh.statement_header_id) AND yy.statement_line_id = csl.statement_line_id )--Version 2.4; Added TO_CHAR
			  --End of changes for defect #18113
         GROUP BY get_lockbox_num (cba.bank_account_num, csl.invoice_text,ctc.trx_code)
                , cba.bank_account_num
                , csh.bank_account_id
                , csh.statement_header_id
                , csh.statement_date
         ORDER BY get_lockbox_num (cba.bank_account_num, csl.invoice_text,ctc.trx_code)
                --, invoice_text
                , cba.bank_account_num
                , csh.statement_date
                , csh.statement_header_id;

-- -------------------------------------------
-- Get all the Lockbox  Bank Statement Lines
-- from CE statement header and lines tables
-- -------------------------------------------
      CURSOR lcu_bnk_stmt_hdr_line (
         p_statement_header_id   IN   NUMBER
       , p_lockbox_num           IN   VARCHAR2
       , p_from_date             IN   DATE
       , p_to_date               IN   DATE
      )
      IS
         SELECT   csh.statement_header_id, csh.bank_account_id
                , csh.statement_number, csh.statement_date
                , NVL (csh.currency_code, cba.currency_code) currency_code
                , csl.attribute14, csl.attribute15, csl.statement_line_id
                , csl.line_number, csl.trx_date, csl.trx_type, csl.amount
                , csl.status
				, csl.trx_code_id
				, csl.trx_code --Added for R12 Upgrade Retrofit
				, csl.effective_date
                , csl.bank_trx_number, csl.trx_text, csl.customer_text
                , csl.invoice_text, csl.bank_account_text, csl.reference_txt
                , csl.ce_statement_lines, csl.je_status_flag
                , csl.accounting_date, csl.gl_account_ccid
                , cba.bank_account_name, cba.bank_account_num
                , cba.bank_account_type
				--Commented and added by Darshini(2.1) for R12 Upgrade Retrofit
				--aba.inactive_date,
				, cba.end_date
				-- end of addition
				, al.lockbox_number
             FROM                                --ce_statement_headers_v    CSH
                  ce_statement_headers csh
                , ce_statement_lines csl
				-- Commented and added by Darshini(2.1) for R12 Upgrade Retrofit
                --, ap_bank_accounts aba
				, ce_bank_accounts cba
				--end of addition
                , ce_transaction_codes ctc
                , ar_lockboxes al
            WHERE csh.statement_header_id = p_statement_header_id
              AND csh.statement_header_id = csl.statement_header_id
              AND csh.bank_account_id = cba.bank_account_id
			  --Commented and added for R12 Upgrade Retrofit
              --AND csl.trx_code_id = ctc.transaction_code_id(+)
			  AND csl.trx_code = ctc.trx_code(+)
              AND al.lockbox_number =
                        get_lockbox_num (cba.bank_account_num, csl.invoice_text,ctc.trx_code)
              AND get_lockbox_num (cba.bank_account_num, csl.invoice_text, ctc.trx_code) =
                                                                   p_lockbox_num
              AND ctc.trx_code IN (SELECT XFT.source_value2           -- Added this select statement for defect # - 11634
                                   FROM   xx_fin_translatedefinition XFTD
                                         ,xx_fin_translatevalues XFT
                                   WHERE  XFTD.translate_id = XFT.translate_id
                                   AND    XFTD.translation_name = gc_lockbox_translation
                                   AND    XFT.enabled_flag = 'Y'
                                   AND    XFT.source_value1 = cba.bank_account_num
                                   AND    XFT.source_value2 IS NOT NULL)
              AND ctc.bank_account_id = cba.bank_account_id
              AND (csl.status IS NULL
                   OR UPPER (csl.status) = 'UNRECONCILED')
              AND (csl.attribute15 IS NULL
                   OR csl.attribute15 NOT IN ('PROCESSED-E1297')
                  )
              AND csh.statement_date BETWEEN NVL (p_from_date
                                                , csh.statement_date
                                                 )
                                         AND NVL (p_to_date, csh.statement_date)
              AND (cba.bank_account_type LIKE 'Corporate%Lockbox' or cba.bank_account_type LIKE 'LBX')
              --Commented and added by Darshini(2.1) for R12 Upgrade retrofit
			  --AND NVL (aba.inactive_date, p_from_date) BETWEEN p_from_date
			  AND NVL (cba.end_date, p_from_date) BETWEEN p_from_date   --end of addition
                                                           AND p_to_date
         ORDER BY get_lockbox_num (cba.bank_account_num, csl.invoice_text,ctc.trx_code)
                , cba.bank_account_num
                , csh.statement_number
                , csl.line_number;

       /*
      -- -------------------------------------------
      -- Get all the Lockbox  Bank Statement Lines
      -- from CE statement header and lines tables
      -- -------------------------------------------
            CURSOR lcu_get_bank_ccid (
               p_trx_code_id      IN  ce.ce_transaction_codes.transaction_code_id%TYPE
             , p_bank_account_id  IN  ap.ap_bank_accounts_all.bank_account_id%TYPE
            )
            IS
               SELECT aba.bank_account_id, aba.bank_account_name
                    , aba.bank_account_num, aba.bank_branch_id, aba.set_of_books_id
                    , aba.currency_code, aba.description, aba.bank_account_type
                    , aba.account_type, aba.org_id, aba.cash_clearing_ccid
                    , aba.bank_charges_ccid, aba.bank_errors_ccid
                    , aba.on_account_ccid, aba.unapplied_ccid
                    , aba.unidentified_ccid, aba.remittance_ccid, cjm.trx_code_id
                    , cjm.gl_account_ccid, cjm.reference_txt
                 FROM ap_bank_accounts aba, ce_je_mappings cjm
                WHERE aba.bank_account_id = p_bank_account_id
                  AND aba.bank_account_id = cjm.bank_account_id(+)
                  AND cjm.bank_account_id(+) = p_bank_account_id
                  AND cjm.trx_code_id(+) = p_trx_code_id
                  AND NVL (aba.inactive_date, SYSDATE + 1) > SYSDATE;


       -- -------------------------------------------
       -- Get the Sum of all the receipts Amount
       -- Lockbox Batch and deposit date
       -- -------------------------------------------
       CURSOR lcu_get_rcpt_amt ( p_bank_account_id  IN ap_bank_accounts_all.bank_account_id%TYPE
                                ,p_deposit_date     IN DATE
                                ,p_batch_name       IN ar_batches_all.name%TYPE)
       IS
       SELECT SUM(CR.AMOUNT)            amount
           ,  CR.deposit_date           deposit_date
           ,  BAT.lockbox_batch_name    name
       FROM  ap_bank_branches                         ABB1
           , ap_bank_accounts                         ABA1
           , ap_bank_branches                         ABB2
           , ap_bank_branches                         ABB3
           , ap_bank_branches                         ABB4
           , ap_bank_accounts                         ABA2
           , ar_vat_tax                               VAT
           , hz_cust_accounts                         CUST
           , hz_parties                               PARTY
           , ar_receipt_methods                       REC_METHOD
           , ar_receipt_classes                       RC
           , hz_cust_site_uses                        HCSU
           , ar_lookups                               ALK1
           , ar_lookups                               ALK2
           , ar_lookups                               ALK3
           , ar_lookups                               ALK4
           , gl_daily_conversion_types                GL_DCT
           , ar_cash_receipt_history                  CRH_REM
           , ar_batches                               REM_BAT
           , ar_receivables_trx                       REC_TRX
           , ar_distribution_sets                     DIST_SET
           , ar_payment_schedules                     PS
           , ar_cash_receipt_history                  CRH_CURRENT
           , ar_batches                               BAT
           , ar_batches                               BAT_BR
           , ar_cash_receipts                         CR
           , ar_cash_receipt_history                  CRH_FIRST_POSTED
        WHERE CR.pay_from_customer                             = CUST.cust_account_id ( + )
        AND   CUST.party_id                                    = PARTY.party_id ( + )
        AND   ALK1.lookup_type( + )                            = 'AR_NOTE_STATUS'
        AND   ALK1.lookup_code( + )                            = CRH_CURRENT.note_status
        AND   ABB1.bank_branch_id( + )                         = CR.issuer_bank_branch_id
        AND   ABA1.bank_account_id( + )                        = CR.remittance_bank_account_id
        AND   ABA1.bank_branch_id                              = ABB2.bank_branch_id ( + )
        AND   ABA2.bank_account_id( + )                        = CR.customer_bank_account_id
        AND   ABA2.bank_branch_id                              = ABB3.bank_branch_id ( + )
        AND   CR.customer_bank_branch_id                       = ABB4.bank_branch_id ( + )
        AND   VAT.vat_tax_id( + )                              = CR.vat_tax_id
        AND   CR.receipt_method_id                             = REC_METHOD.receipt_method_id
        AND   REC_METHOD.receipt_class_id                      = RC.receipt_class_id
        AND   CR.customer_site_use_id                          = HCSU.site_use_id ( + )
        AND   CR.receivables_trx_id                            = REC_TRX.receivables_trx_id ( + )
        AND   CR.distribution_set_id                           = DIST_SET.distribution_set_id ( + )
        AND   ALK2.lookup_type( + )                            = 'REVERSAL_CATEGORY_TYPE'
        AND   ALK2.lookup_code( + )                            = CR.reversal_category
        AND   ALK3.lookup_type( + )                            = 'CKAJST_REASON'
        AND   ALK3.lookup_code( + )                            = CR.reversal_reason_code
        AND   ALK4.lookup_code( + )                            = CR.reference_type
        AND   ALK4.lookup_type( + )                            = 'CB_REFERENCE_TYPE'
        AND   GL_DCT.conversion_type( + )                      = CR.exchange_rate_type
        AND   CRH_REM.cash_receipt_id( + )                     = CR.cash_receipt_id
        AND NOT EXISTS ( SELECT cash_receipt_history_id
                         FROM   ar_cash_receipt_history CRH3
                         WHERE  CRH3.status                    = 'REMITTED'
                         AND    CRH3.cash_receipt_id           = CR.cash_receipt_id
                         AND    CRH3.cash_receipt_history_id   < CRH_REM.cash_receipt_history_id )
        AND CRH_REM.status( + )                                = 'REMITTED'
        AND CRH_REM.batch_id                                   = REM_BAT.batch_id( + )
        AND REM_BAT.type( + )                                  = 'REMITTANCE'
        AND PS.cash_receipt_id( + )                            = CR.cash_receipt_id
        AND CRH_CURRENT.cash_receipt_id                        = CR.cash_receipt_id
        AND CRH_CURRENT.current_record_flag                    = NVL ( 'Y', CR.receipt_number )
        AND CRH_FIRST_POSTED.batch_id                          = BAT.batch_id ( + )
        AND BAT.TYPE( + )                                      = 'MANUAL'
        AND CRH_FIRST_POSTED.cash_receipt_id( + )              = CR.cash_receipt_id
        AND CRH_FIRST_POSTED.first_posted_record_flag( + )     = 'Y'
        AND CRH_FIRST_POSTED.batch_id                          = BAT_BR.batch_id( + )
        AND BAT_BR.type ( + )                                  = 'BR'
        AND ABA1.BANK_ACCOUNT_ID                               = p_bank_account_id
        AND CR.deposit_date                                    = NVL(p_deposit_date,CR.deposit_date)
        AND BAT.lockbox_batch_name                             = NVL(p_batch_name, BAT.lockbox_batch_name )
        GROUP BY CR.deposit_date
                ,BAT.lockbox_batch_name;


      -- -------------------------------------------
      -- Get the Accounting Segments based on the
      -- CCID from bank Account Setup
      -- -------------------------------------------
            CURSOR lcu_get_aff_segments (
               p_code_combination_id  IN  gl_code_combinations.code_combination_id%TYPE
            )
            IS
               SELECT gcc.segment1 company, gcc.segment2 cost_center
                    , gcc.segment3 ACCOUNT, gcc.segment4 LOCATION
                    , gcc.segment5 intercompany, gcc.segment6 channel
                    , gcc.segment7 future
                 FROM gl_code_combinations gcc
                WHERE gcc.code_combination_id = p_code_combination_id
                  AND gcc.enabled_flag = 'Y';

      -- -------------------------------------------
      -- Get the Receipt Method ID
      -- -------------------------------------------
            CURSOR lcu_get_recpt_method (
               p_batch_name    IN  ar_batches_all.NAME%TYPE
             , p_deposit_date  IN  DATE
            )
            IS
               SELECT ab.receipt_method_id
                 FROM ar_batches ab
                WHERE ab.lockbox_batch_name = p_batch_name
                  AND ab.deposit_date = p_deposit_date;

      */

      -- -------------------------------------------
-- Get the Trx Type, Trx Code, Trx Description
-- for Trx Code id and Bank Act Id
-- -------------------------------------------
      CURSOR lcu_get_trx_code (
         --Commented and added for R12 Upgrade Retrofit
		 --p_trx_code_id       IN   ce_transaction_codes.transaction_code_id%TYPE
		 p_trx_code          IN   ce_transaction_codes.trx_code%TYPE
       --, p_bank_account_id   IN   ap_bank_accounts_all.bank_account_id%TYPE
	   , p_bank_account_id   IN   ce_bank_accounts.bank_account_id%TYPE
       , p_start_date        IN   DATE
       , p_end_date          IN   DATE
      )
      IS
         SELECT ctc.trx_code, ctc.trx_type, ctc.description, ctc.reconcile_flag
              /*Commented and added for R12 Upgrade Retrofit
			  , ctc.transaction_code_id
		   FROM ce_transaction_codes ctc
           WHERE ctc.transaction_code_id =
                                    NVL (p_trx_code_id, ctc.transaction_code_id)*/
		   FROM ce_transaction_codes ctc
           WHERE ctc.trx_code =
                                    NVL (p_trx_code, ctc.trx_code)
			-- end of addition
            AND ctc.bank_account_id =
                                    NVL (p_bank_account_id, ctc.bank_account_id)
            AND ctc.trx_type IN ('CREDIT', 'MISC_CREDIT')
            AND NVL (ctc.start_date, p_start_date - 1) <= p_start_date
            AND NVL (ctc.end_date, p_end_date + 1) >= p_end_date;

-- -------------------------------------------
-- Get count of the Deposit Currency Code
-- -------------------------------------------
      CURSOR lcu_get_cur_code (
         p_currency_code   IN   fnd_currencies.currency_code%TYPE
      )
      IS
         SELECT COUNT (fc.currency_code)
           FROM fnd_currencies fc
          WHERE fc.currency_code = p_currency_code
            AND fc.enabled_flag = 'Y'
            AND fc.currency_flag = 'Y'
            AND NVL (fc.end_date_active, SYSDATE + 1) > SYSDATE;

-- ------------------------------------------------
-- Get the Transaction Code id
-- ------------------------------------------------
      CURSOR lcu_get_001_trx_code (
         --Commented and added for R12 Upgrade Retrofit
		 --p_bank_account   IN   ap_bank_accounts_all.bank_account_id%TYPE
		 p_bank_account   IN   ce_bank_accounts.bank_account_id%TYPE
      )
      IS
         SELECT transaction_code_id
		       , trx_code  --Added for R12 Upgrade Retrofit
           FROM ce_transaction_codes
          WHERE bank_account_id = p_bank_account
            AND trx_code = '001'
            AND NVL (end_date, SYSDATE + 1) > SYSDATE;

-- ------------------------------------------------
-- Cursor to get the Batch Amount for Lockbox
-- Needs to match with CE Statement tables
-- ------------------------------------------------
     /*  -- 2008/10/21 -- DGowda - Replace with View so that it is identical to
                                -- Manual Matching Form
     CURSOR lcu_get_deposit_amt (
         p_lockbox_number    IN   ar_lockboxes_all.lockbox_number%TYPE
       , p_bank_account_id   IN   ap_bank_accounts_all.bank_account_id%TYPE
       , p_deposit_date      IN   DATE
      )
      IS
         SELECT   abv.lockbox_number, abv.receipt_method_id, abv.deposit_date
                , SUM (abv.control_amount) amount
             FROM ar_batches_v abv, ar_transmissions ata
            WHERE abv.transmission_id = ata.transmission_id
              AND ata.status = 'CL'
              AND abv.lockbox_number = p_lockbox_number
              AND abv.remittance_bank_account_id = p_bank_account_id
              AND abv.deposit_date = p_deposit_date
         GROUP BY abv.lockbox_number, abv.receipt_method_id, abv.deposit_date
         ORDER BY abv.deposit_date DESC;
       */
      CURSOR lcu_get_deposit_amt (
         p_lockbox_number    IN   ar_lockboxes_all.lockbox_number%TYPE
       --Commented and added for R12 Upgrade Retrofit
	   --, p_bank_account_id   IN   ap_bank_accounts_all.bank_account_id%TYPE
	   , p_bank_account_id   IN   ce_bank_accounts.bank_account_id%TYPE
       , p_deposit_date      IN   DATE
      )
      IS
         SELECT   lockbox_number, receipt_method_id, deposit_date
                , SUM (amount) amount
             FROM xx_ce_lockbox_transmissions_v ata
            WHERE lockbox_number = p_lockbox_number
              AND bank_account_id = p_bank_account_id
              AND deposit_date = p_deposit_date
         GROUP BY lockbox_number, receipt_method_id, deposit_date;

-- -------------------------------------------
-- Local Variable Declaration
-- -------------------------------------------
      bnk_stmt_hdr_line_rec          lcu_bnk_stmt_hdr_line%ROWTYPE;
      get_trx_code_rec               lcu_get_trx_code%ROWTYPE;
      -- get_rcpt_amt_rec              lcu_get_rcpt_amt%ROWTYPE;
      -- get_bank_ccid_rec             lcu_get_bank_ccid%ROWTYPE;
      -- get_aff_segments_rec          lcu_get_aff_segments%ROWTYPE;
      get_deposit_amt                lcu_get_deposit_amt%ROWTYPE;
      get_sum_lckbx_amt              lcu_get_sum_lckbx_amt%ROWTYPE;
      lc_error_details               VARCHAR2 (32000);
      lc_error_location              VARCHAR2 (32000);
      lc_errmsg                      VARCHAR2 (2000);
      lc_output_msg                  VARCHAR2 (2000);
      lc_trx_vald_flag               VARCHAR2 (1);
      lc_source_err_flag             VARCHAR2 (1);
      lc_err_msg                     VARCHAR2 (2000);
      lc_provider_code               VARCHAR2 (30);
      lc_email_addr                  VARCHAR2 (60);
      lb_amt_match                   BOOLEAN;
      ln_success_rec                 NUMBER                                 := 0;
      ln_total_rec                   NUMBER                                 := 0;
      ln_error_rec                   NUMBER                                 := 0;
      ln_currency_cnt                NUMBER                                 := 0;
      ln_retcode                     NUMBER;
      ln_diff_amount                 NUMBER;
      ln_err_msg_count               NUMBER;
      ln_group_id                    NUMBER;
      ln_entered_bnk_err_dr_amount   NUMBER;
      ln_entered_bnk_err_cr_amount   NUMBER;
      ln_entered_bnk_csh_dr_amount   NUMBER;
      ln_entered_bnk_csh_cr_amount   NUMBER;
      ln_receipt_method_id           NUMBER;
      ln_mail_request_id             NUMBER;
      ln_interface_seq               NUMBER;
      ln_001_trx_code_id             NUMBER;
	  ln_001_trx_code                VARCHAR2(30); --Added for R12 Upgrade Retrofit
      ln_application_id              fnd_application.application_id%TYPE;
      lc_period_name                 gl_period_statuses.period_name%TYPE;
      ln_coa_id                      gl_sets_of_books.chart_of_accounts_id%TYPE;
      ex_main_exception              EXCEPTION;
      ex_lkbx_deposit_exception      EXCEPTION;
      lc_lkbx_deposit_savepoint      VARCHAR2 (30)        := 'LOCKBOX_SAVEPOINT';
   BEGIN
-- -------------------------------------------
-- Initializing Local Variables
-- -------------------------------------------
      lc_error_location := 'Initializing Local Variables';
      fnd_file.put_line (fnd_file.LOG, lc_error_location);
      lc_source_err_flag := 'N';
      lc_trx_vald_flag := 'N';
      lc_error_details := NULL;
      lc_errmsg := NULL;
      lc_output_msg := NULL;
      ln_receipt_method_id := NULL;
      lc_err_msg := NULL;
      lc_provider_code := NULL;
      lb_amt_match := FALSE;
      ln_retcode := 0;
      ln_currency_cnt := 0;
      ln_err_msg_count := 0;
      ln_group_id := 0;
-- -------------------------------------------
-- Check the set of Books ID
-- -------------------------------------------
      lc_error_location := 'Mandatory Check Set of Books Id';
      fnd_file.put_line (fnd_file.LOG, lc_error_location);

      IF gn_set_of_bks_id IS NULL
      THEN
         lc_source_err_flag := 'Y';
         fnd_message.set_name ('XXFIN', 'XX_CE_002_SOB_NOT_SETUP');
         lc_error_details := lc_error_details || fnd_message.get || CHR (10);
      END IF;

-- -------------------------------------------
-- Get the Chart of Account Id
-- -------------------------------------------
      IF gn_set_of_bks_id IS NOT NULL
      THEN
         OPEN lcu_get_coaid;

         FETCH lcu_get_coaid
          INTO ln_coa_id;

         CLOSE lcu_get_coaid;

         IF ln_coa_id IS NULL
         THEN
            lc_source_err_flag := 'Y';
            fnd_message.set_name ('XXFIN', 'XX_CE_003_COA_NOT_SETUP');
            lc_error_details := lc_error_details || fnd_message.get || CHR (10);
         END IF;
      END IF;

-- -------------------------------------------
-- Get one time group id for all the GL
-- transaction entry
-- -------------------------------------------
      SELECT gl_interface_control_s.NEXTVAL
        INTO ln_group_id
        FROM DUAL;

-- -------------------------------------------
-- Call the Print Message Header
-- -------------------------------------------
      print_message_header (x_errbuf => lc_errmsg, x_retcode => ln_retcode);

-- -------------------------------------------
-- Total Amount for a Lockbox all the deposit
--  for a day
-- -------------------------------------------
      OPEN lcu_get_sum_lckbx_amt
                  (p_from_date => fnd_conc_date.string_to_date (p_run_from_date)
                 , p_to_date => fnd_conc_date.string_to_date (p_run_to_date)
                  );

      LOOP
         FETCH lcu_get_sum_lckbx_amt
          INTO get_sum_lckbx_amt;

         EXIT WHEN lcu_get_sum_lckbx_amt%NOTFOUND;
         SAVEPOINT lc_lkbx_deposit_savepoint;

         BEGIN
            -- Added on 06-Nov-2007
            -- Amount will be used from batch control amount for lockbox and transmission per day
            lb_amt_match := FALSE;
            get_deposit_amt.amount := NULL;
            fnd_file.put_line (fnd_file.LOG
                             ,    'Match AR Lockbox Batch(es) for Lockbox #: '
                               || get_sum_lckbx_amt.lockbox_num
                               || ' / Stmt Date: '
                               || get_sum_lckbx_amt.statement_date
                               || ' / Stmt Amount: '
                               || get_sum_lckbx_amt.tot_lck_amount
                              );

            OPEN lcu_get_deposit_amt
                        (p_lockbox_number => get_sum_lckbx_amt.lockbox_num
                       , p_bank_account_id => get_sum_lckbx_amt.bank_account_id
                       , p_deposit_date => get_sum_lckbx_amt.statement_date
                        );

            FETCH lcu_get_deposit_amt
             INTO get_deposit_amt;

            CLOSE lcu_get_deposit_amt;

            -- Assiging the Lb Amount Match if the amount is match then TRUE else FALSE
            IF get_deposit_amt.amount = get_sum_lckbx_amt.tot_lck_amount
               AND get_deposit_amt.amount IS NOT NULL
            THEN
               lb_amt_match := TRUE;
               fnd_file.put_line
                           (fnd_file.LOG
                          , 'Matched Bank Deposits to Sum of Lockbox Receipts.'
                           );
               record_lockbox_transmissions
                  (p_statement_header_id => get_sum_lckbx_amt.statement_header_id
                 , p_bank_account_id => get_sum_lckbx_amt.bank_account_id
                 , p_lockbox_number => get_sum_lckbx_amt.lockbox_num
                 , p_statement_date => get_sum_lckbx_amt.statement_date
                  );
            ELSE
               lb_amt_match := FALSE;
               fnd_file.put_line
                           (fnd_file.LOG
                          , 'Deposit could not be matched to Lockbox receipts.'
                           );
            END IF;

-- -------------------------------------------
-- Loop through all the statement records
-- for the from and to date range for the given lockbox number.
-- -------------------------------------------
            OPEN lcu_bnk_stmt_hdr_line
                   (p_statement_header_id => get_sum_lckbx_amt.statement_header_id
                  , p_lockbox_num => get_sum_lckbx_amt.lockbox_num
                  , p_from_date => fnd_conc_date.string_to_date (p_run_from_date)
                  , p_to_date => fnd_conc_date.string_to_date (p_run_to_date)
                   );

            LOOP
               FETCH lcu_bnk_stmt_hdr_line
                INTO bnk_stmt_hdr_line_rec;

               EXIT WHEN lcu_bnk_stmt_hdr_line%NOTFOUND;
               lc_error_details := NULL;
               lc_source_err_flag := 'N';
               lc_trx_vald_flag := 'N';
               lc_error_location := NULL;
               lc_period_name := NULL;
               lc_output_msg := NULL;
               ln_currency_cnt := 0;
               ln_diff_amount := 0;
               ln_interface_seq := NULL;
               ln_entered_bnk_err_dr_amount := NULL;
               ln_entered_bnk_err_cr_amount := NULL;
               ln_entered_bnk_csh_dr_amount := NULL;
               ln_entered_bnk_csh_cr_amount := NULL;
               ln_receipt_method_id := NULL;
               lc_provider_code := NULL;
               ln_001_trx_code_id := NULL;
			   ln_001_trx_code := NULL;
               --
               ln_total_rec := ln_total_rec + 1;

-- ------------------------------------------------
-- Get the Trx Code Id fo '001'
-- ------------------------------------------------
               OPEN lcu_get_001_trx_code
                       (p_bank_account => bnk_stmt_hdr_line_rec.bank_account_id);

               FETCH lcu_get_001_trx_code
                INTO ln_001_trx_code_id
				     , ln_001_trx_code; --Added for R12 Upgrade Retrofit

               CLOSE lcu_get_001_trx_code;

-- -------------------------------------------
-- Check wheather Trx Code '001' is set up or not
-- -------------------------------------------
               lc_error_location :=
                      'Mandatory Check for Trx Code 001 for each bank account ';

               --Commented and added for R12 Upgrade Retrofit
			   --IF ln_001_trx_code_id IS NULL
			   IF ln_001_trx_code IS NULL
               THEN
                  lc_source_err_flag := 'Y';
                  lc_error_details :=
                        lc_error_details
                     || 'Trx Code is not setup for bank account:'
                     || bnk_stmt_hdr_line_rec.bank_account_num
                     || CHR (10);
               END IF;

-- -------------------------------------------
-- Validate the Deposit Currency Code
-- -------------------------------------------
               lc_error_location := 'Mandatory Check for Currency Code';

               IF bnk_stmt_hdr_line_rec.currency_code IS NULL
               THEN
                  lc_source_err_flag := 'Y';
                  fnd_message.set_name ('XXFIN', 'XX_CE_004_NO_CURRENCY_VALUE');
                  fnd_message.set_token ('STATEMENT_NUMBER'
                                       , bnk_stmt_hdr_line_rec.statement_number
                                        );
                  fnd_message.set_token ('STATEMENT_DATE'
                                       , bnk_stmt_hdr_line_rec.statement_date
                                        );
                  fnd_message.set_token ('BANK_ACCOUNT'
                                       , bnk_stmt_hdr_line_rec.bank_account_num
                                        );
                  lc_error_details :=
                                 lc_error_details || fnd_message.get || CHR (10);
               ELSE
                  OPEN lcu_get_cur_code
                         (p_currency_code => bnk_stmt_hdr_line_rec.currency_code
                         );

                  FETCH lcu_get_cur_code
                   INTO ln_currency_cnt;

                  CLOSE lcu_get_cur_code;

                  IF ln_currency_cnt = 0
                  THEN
                     lc_source_err_flag := 'Y';
                     fnd_message.set_name ('XXFIN'
                                         , 'XX_CE_005_CURRENCY_NOT_SETUP'
                                          );
                     fnd_message.set_token ('CURRENCY_CODE'
                                          , bnk_stmt_hdr_line_rec.currency_code
                                           );
                     fnd_message.set_token
                                         ('STATEMENT_NUMBER'
                                        , bnk_stmt_hdr_line_rec.statement_number
                                         );
                     fnd_message.set_token ('STATEMENT_DATE'
                                          , bnk_stmt_hdr_line_rec.statement_date
                                           );
                     fnd_message.set_token
                                         ('BANK_ACCOUNT'
                                        , bnk_stmt_hdr_line_rec.bank_account_num
                                         );
                     lc_error_details :=
                                 lc_error_details || fnd_message.get || CHR (10);
                  END IF;
               END IF;

-- -------------------------------------------
-- Validate the transsaction code id
-- should not be null
-- -------------------------------------------
               lc_error_location := 'Mandatory Check for Transaction Code Id';

               --Commented and added for R12 Upgrade Retrofit
			   --IF bnk_stmt_hdr_line_rec.trx_code_id IS NULL
			   IF bnk_stmt_hdr_line_rec.trx_code IS NULL
               THEN
                  lc_source_err_flag := 'Y';
                  fnd_message.set_name ('XXFIN', 'XX_CE_006_NO_TRX_CODE_VALUE');
                  fnd_message.set_token ('STATEMENT_NUMBER'
                                       , bnk_stmt_hdr_line_rec.statement_number
                                        );
                  fnd_message.set_token ('LINE_NUMBER'
                                       , bnk_stmt_hdr_line_rec.line_number
                                        );
                  lc_error_details :=
                                 lc_error_details || fnd_message.get || CHR (10);
               ELSE
-- -------------------------------------------
-- Validate the Transaction Code
-- -------------------------------------------
                  OPEN lcu_get_trx_code
                         --Commented and added for R12 Upgrade Retrofit
						 --(p_trx_code_id => bnk_stmt_hdr_line_rec.trx_code_id
						 (p_trx_code    => bnk_stmt_hdr_line_rec.trx_code
                        , p_bank_account_id => bnk_stmt_hdr_line_rec.bank_account_id
                        , p_start_date => fnd_conc_date.string_to_date
                                                                (p_run_from_date)
                        , p_end_date => fnd_conc_date.string_to_date
                                                                  (p_run_to_date)
                         );

                  FETCH lcu_get_trx_code
                   INTO get_trx_code_rec;

                  CLOSE lcu_get_trx_code;

-- -------------------------------------------
-- Validate / Error for Transaction code
-- -------------------------------------------
                  IF get_trx_code_rec.trx_code IS NULL
                  THEN
                     lc_source_err_flag := 'Y';
                     lc_trx_vald_flag := 'Y';
                     fnd_message.set_name ('XXFIN'
                                         , 'XX_CE_007_TRX_CODE_NOT_SETUP'
                                          );
                     fnd_message.set_token
                                         ('STATEMENT_NUMBER'
                                        , bnk_stmt_hdr_line_rec.statement_number
                                         );
                     fnd_message.set_token ('LINE_NUMBER'
                                          , bnk_stmt_hdr_line_rec.line_number
                                           );
                     fnd_message.set_token
                                         ('BANK_ACCOUNT'
                                        , bnk_stmt_hdr_line_rec.bank_account_num
                                         );
                     fnd_message.set_token ('TRX_ID'
                                          --Commented and added for R12 Upgrade Retrofit
										  --, bnk_stmt_hdr_line_rec.trx_code_id
										  , bnk_stmt_hdr_line_rec.trx_code
                                           );
                     lc_error_details :=
                                 lc_error_details || fnd_message.get || CHR (10);
                  END IF;
               END IF;

-- -------------------------------------------
-- Checking the Transaction code
-- for Lockbox Deposit
-- -------------------------------------------
               lc_error_location :=
                            'Check for Transaction code Description for Deposit';

               IF lc_trx_vald_flag = 'N'
                  AND lc_source_err_flag = 'N'
               THEN
                  lc_provider_code := 'LOCKBOX_DAY';

                  IF lb_amt_match = TRUE
                  THEN
-- -------------------------------------------
-- Calling the Create Open Interface
-- Procedure to crerate the record into
-- XX_CE_999_INTERFACE custom table
-- for receonciliation
-- -------------------------------------------
                     lc_error_location :=
                        'Inserting into XX_CE_999_INTERFACE table and Updating the CE Statement Header and Lines after processing';
                     create_open_interface
                        (p_trx_code_id => bnk_stmt_hdr_line_rec.trx_code_id
					   , p_trx_code => bnk_stmt_hdr_line_rec.trx_code
                       , p_bank_account_id => bnk_stmt_hdr_line_rec.bank_account_id
                       , p_bank_trx_number_org => bnk_stmt_hdr_line_rec.bank_trx_number
                       , p_trx_date => bnk_stmt_hdr_line_rec.trx_date
                       , p_currency_code => bnk_stmt_hdr_line_rec.currency_code
                       , p_amount => bnk_stmt_hdr_line_rec.amount
                       , p_statement_header_id => bnk_stmt_hdr_line_rec.statement_header_id
                       , p_statement_line_id => bnk_stmt_hdr_line_rec.statement_line_id
                       , p_provider_code => lc_provider_code
                       --, p_receipt_method_id         =>  ln_receipt_method_id
                       , p_receipt_method_id => get_deposit_amt.receipt_method_id
                       , p_lockbox_batch => bnk_stmt_hdr_line_rec.customer_text
                       , p_lockbox_number => bnk_stmt_hdr_line_rec.lockbox_number
                       --, p_lockbox_deposit_date      =>  get_rcpt_amt_rec.deposit_date
                       , p_lockbox_deposit_date => get_deposit_amt.deposit_date
                       , p_ajb_bank_rec_id => NULL
                       , x_errbuf => lc_err_msg
                       , x_retcode => ln_retcode
                       , x_interface_seq => ln_interface_seq
                        );
-- -------------------------------------------
-- Calling the Update Procedure to Update
-- the CE_STATEMENT_HEADERS_ALL /
-- CE_STATEMENT_LINES after Processing records
-- -------------------------------------------
                     update_stmt_rec
                        (p_bank_stmt_header => bnk_stmt_hdr_line_rec.statement_header_id
                       , p_bank_stmt_line => bnk_stmt_hdr_line_rec.statement_line_id
                       , p_bank_account_id => bnk_stmt_hdr_line_rec.bank_account_id
                       , p_create_gl => 'NO'
                       , p_interface_seq => ln_interface_seq
                       , p_001_trx_code_id => ln_001_trx_code_id
					   , p_001_trx_code => ln_001_trx_code
                       , x_errbuf => lc_err_msg
                       , x_retcode => ln_retcode
                        );

-- -------------------------------------------
-- Calling the Exception
-- if insertion / updation failed
-- -------------------------------------------
                     IF ln_retcode = gn_error
                     THEN
                        lc_error_details := lc_err_msg;
                        RAISE ex_lkbx_deposit_exception;
                     END IF;
                  --Commented on Nov-06-2007
                  --ELSIF get_deposit_amt.amount IS NULL
                  --  OR get_deposit_amt.amount <> bnk_stmt_hdr_line_rec.amount THEN
                  ELSE
                     -- lb_amt_match = FALSE
                     /*
                     fnd_message.set_name ('XXFIN', 'XX_CE_008_NO_RCPT_AMT');
                     fnd_message.set_token
                                        ('STATEMENT_NUMBER'
                                       , bnk_stmt_hdr_line_rec.statement_number
                                        );
                     fnd_message.set_token ('STATEMENT_DATE'
                                          , bnk_stmt_hdr_line_rec.statement_date
                                           );
                     fnd_message.set_token ('LINE_NUMBER'
                                          , bnk_stmt_hdr_line_rec.line_number
                                           );
                     fnd_message.set_token ('LOCKBOX_BATCH'
                                          , bnk_stmt_hdr_line_rec.invoice_text
                                           );
                     lc_error_details :=
                                 lc_error_details || fnd_message.get || CHR (10);
                     */
                     lc_error_details := 'No Matching Lockbox Batch(es)';
-- -------------------------------------------
-- Calling the Update Procedure to Update
-- the CE_STATEMENT_HEADERS_ALL /
-- CE_STATEMENT_LINES after Processing records
-- -------------------------------------------
                     update_stmt_rec
                        (p_bank_stmt_header => bnk_stmt_hdr_line_rec.statement_header_id
                       , p_bank_stmt_line => bnk_stmt_hdr_line_rec.statement_line_id
                       , p_bank_account_id => bnk_stmt_hdr_line_rec.bank_account_id
                       , p_create_gl => 'E'
                       , p_interface_seq => ln_interface_seq
                       , p_001_trx_code => NULL --Added for R12 Upgrade Retrofit
					   , p_001_trx_code_id => NULL
                       , x_errbuf => lc_err_msg
                       , x_retcode => ln_retcode
                        );
-- -------------------------------------------
-- Calling the Exception
-- if insertion / updation failed
-- -------------------------------------------
                     lc_error_location :=
                        'Updating the CE Statement Header and Lines after processing';

                     IF ln_retcode = gn_error
                     THEN
                        lc_error_details := lc_err_msg;
                        RAISE ex_lkbx_deposit_exception;
                     END IF;
                  END IF;
               END IF;

-- -------------------------------------------
-- Call the Print Message Details
-- -------------------------------------------
               print_message_footer
                  (x_errbuf => lc_errmsg
                 , x_retcode => ln_retcode
                 , p_statement_number => bnk_stmt_hdr_line_rec.statement_number
                 , p_stmt_line_num => bnk_stmt_hdr_line_rec.line_number
                 , p_lockbox_num => bnk_stmt_hdr_line_rec.lockbox_number
                 , p_bank_act_num => bnk_stmt_hdr_line_rec.bank_account_num
                 , p_stmt_date => bnk_stmt_hdr_line_rec.statement_date
                 , p_stmt_amount => bnk_stmt_hdr_line_rec.amount
                 , p_message => NVL (lc_error_details
                                   , 'Matched to AR Batch(es)')
                  );

               IF lc_error_details IS NULL
               THEN
                  ln_success_rec := ln_success_rec + 1;
               ELSE
                  ln_error_rec := ln_error_rec + 1;
               END IF;
            END LOOP;

            CLOSE lcu_bnk_stmt_hdr_line;
         EXCEPTION
            WHEN ex_lkbx_deposit_exception
            THEN
               fnd_file.put_line (fnd_file.LOG
                                ,    'Error processing Deposits for Lockbox '
                                  || get_sum_lckbx_amt.lockbox_num
                                  || ' / Stmt Date: '
                                  || get_sum_lckbx_amt.statement_date
                                  || ' / Stmt Amount: '
                                  || get_sum_lckbx_amt.tot_lck_amount
                                  || '. Error:'
                                  || lc_error_details
                                 );
               ROLLBACK TO lc_lkbx_deposit_savepoint;
               ln_error_rec := ln_error_rec + 1;
            WHEN OTHERS
            THEN
               RAISE;
         END;
      END LOOP;

      CLOSE lcu_get_sum_lckbx_amt;

      COMMIT;
-- -------------------------------------------
-- Call the Print Message Record Summary
-- -------------------------------------------
      print_message_summary (x_errbuf => lc_errmsg
                           , x_retcode => ln_retcode
                           , p_success => ln_success_rec
                           , p_error => ln_error_rec
                           , p_total => ln_total_rec
                            );

      IF p_email_id IS NOT NULL
      THEN
-- -------------------------------------------
-- Call the Common Emailer Program
-- -------------------------------------------
         ln_mail_request_id :=
            fnd_request.submit_request
                                  (application => 'xxfin'
                                 , program => 'XXODROEMAILER'
                                 , description => ''
                                 , sub_request => FALSE
                                 , start_time => TO_CHAR (SYSDATE
                                                        , 'DD-MON-YY HH:MI:SS'
                                                         )
                                 , argument1 => ''
                                 , argument2 => p_email_id
                                 , argument3 => 'Lockbox Recon - '
                                    || TRUNC (SYSDATE)
                                 , argument4 => ''
                                 , argument5 => 'Y'
                                 , argument6 => gn_request_id
                                  );
         COMMIT;

         IF ln_mail_request_id IS NULL
            OR ln_mail_request_id = 0
         THEN
            lc_error_location :=
                         'Failed to submit the Standard Common Emailer Program';
            RAISE ex_main_exception;
         END IF;
      END IF;

-- -------------------------------------------
-- Setting the Request Status based one the
-- Process record count
-- -------------------------------------------
      IF ln_error_rec > 0
      THEN
         x_retcode := gn_warning;
      ELSIF ln_error_rec = 0
      THEN
         x_retcode := gn_normal;
      END IF;
   EXCEPTION
      WHEN ex_main_exception
      THEN
         x_errbuf := lc_error_location || '-' || lc_error_details;
         x_retcode := gn_error;
-- -------------------------------------------
-- Call the Custom Common Error Handling
-- -------------------------------------------
         xx_com_error_log_pub.log_error
                                   (p_program_type => 'CONCURRENT PROGRAM'
                                  , p_program_name => gc_conc_short_name
                                  , p_program_id => fnd_global.conc_program_id
                                  , p_module_name => 'CE'
                                  , p_error_location => 'Error at '
                                     || lc_error_location
                                  , p_error_message_count => 1
                                  , p_error_message_code => 'E'
                                  , p_error_message => lc_error_details
                                  , p_error_message_severity => 'Major'
                                  , p_notify_flag => 'N'
                                  , p_object_type => 'LOCKBOX RECONCILIATION'
                                   );
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE'
                              , 'XX_CE_LOCKBOX_RECON_PKG.recon_process'
                               );
         fnd_message.set_token ('PROGRAM', 'CE Lockbox Reconciliation');
         fnd_message.set_token ('SQLERROR', SQLERRM);
         x_errbuf :=
            lc_error_location || '-' || lc_error_details || '-'
            || fnd_message.get;
         x_retcode := gn_error;
-- -------------------------------------------
-- Call the Custom Common Error Handling
-- -------------------------------------------
         xx_com_error_log_pub.log_error
                                    (p_program_type => 'CONCURRENT PROGRAM'
                                   , p_program_name => gc_conc_short_name
                                   , p_program_id => fnd_global.conc_program_id
                                   , p_module_name => 'CE'
                                   , p_error_location => 'Error at '
                                      || lc_error_location
                                   , p_error_message_count => 1
                                   , p_error_message_code => 'E'
                                   , p_error_message => lc_error_details
                                   , p_error_message_severity => 'Major'
                                   , p_notify_flag => 'N'
                                   , p_object_type => 'LOCKBOX RECONCILIATION'
                                    );
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
   --
   END recon_process;
END xx_ce_lockbox_recon_pkg;
/