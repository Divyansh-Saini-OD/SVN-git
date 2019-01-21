SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
 
PROMPT Creating Package Body xx_ce_ajb_cc_recon_pkg
PROMPT Program exits if the creation is not successful

create or replace
PACKAGE BODY xx_ce_ajb_cc_recon_pkg
AS
-- +===================================================================================+
-- |                       Office Depot - Project Simplify                             |
-- |                            Providge Consulting                                    |
-- +===================================================================================+
-- | Name       : XXCEAJBCCRECON.plb                                                   |
-- | Description: Cash Management AJB Creditcard Reconciliation E1310-Extension        |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record                                                                      |
-- |==============                                                                     |
-- |Version   Date         Authors            Remarks                                  |
-- |========  ===========  ===============    ============================             |
-- |DRAFT 1A  14-AUG-2007  Sunayan Mohanty    Initial draft version                    |
-- |DRAFT 1   19-NOV-2007  Deepak Gowda       Re-write of Draft version                |
-- | V1.0     11-MAR-2008  Deepak Gowda       Defect 5316 Resolution - field Status    |
-- |                                          was being updated instead of status_1310 |
-- |1.1       11-MAR-2008  Deepak Gowda       Defect 5421 Resolution -999 Interface    |
-- |                                          amount column to be the same as the      |
-- |                                          statement line amount - Add a new column |
-- |                                          to the 999 interface table for inserting |
-- |                                          the matching batch amount                |
-- |1.2       24-MAR-2008  Deepak Gowda       Defect 5700 - If we get Multiple 999     |
-- |                                            Lines for same provider/store/card     |
-- |                                            type, reset the Charge Total Amount.   |
-- |1.3       02-APR-2008  Deepak Gowda       Defect 5946 - Revised Log Messages       |
-- |1.4       16-APR-2008  Deepak Gowda       Defect 6176 - Credit of fees to AR Recv  |
-- |                                            was not deriving CCID .                |
-- |1.5       15-MAY-2008  Deepak Gowda       Defect 6395 added bpel_delete_recs       |
-- |1.6       02-Jun-2008  Deepak Gowda       Defect 7633 - Multiple providers in same |
-- |                                           single AJB batch-process seperately.    |
-- |                                           If Debit Amount is negative, then CR and|
-- |                                           vice-versa. Revised log and output      |
-- |1.7       17-Jun-2008  Deepak Gowda       Defect 7926-Added restrictive condition  |
-- |                                           provider to CURSOR ajb_single_match_cur |
-- |1.8       02-Jul-2008  Deepak Gowda       Defects 8710 and 8765-Add parameters     |
-- |                                           provider_code and date range to match   |
-- |                                           and recon processes. Revise Output      |
-- |1.9       07-Jul-2008  Deepak Gowda       Defect 8802 - If Store comes in as '     |
-- |                                           000000' then use '001099' for accounting|
-- |2.0       11-Jul-2008  Deepak Gowda       Defect 8877-Do not select stores for fee |
-- |                                           reprocessing if they are marked as done |
-- |2.1       11-Jul-2008  Deepak Gowda       Defect 8936-Do not create GL entries when|
-- |                                           Net Amount is 0                         |
-- |2.2       14-Jul-2008  Deepak Gowda       Defect 8940-Update accounting            |
-- |2.3       14-Jul-2008  Deepak Gowda       Added locking for concurrently running   |
-- |                                           matching and fee recon processes        |
-- |2.4       25-Jul-2008  Deepak Gowda       Defects 7926 and 8960 - Add Pre-processor|
-- |                                           procedure to pre-process 998, 996,999   |
-- |                                           transactions to move code from trigger  |
-- |                                           and views - Derive currency, country,   |
-- |                                           Org ID and AR matching information.
-- |                                          Modified to use multi-org view for       |
-- |                                            xx_ce_recon_glact_hdr                  |
-- |2.5       28-Jul-2008  Deepak Gowda       Defect 9333 - In Accrual Process, check  |
-- |                                           for Card Type along with Provider  when |
-- |                                           checking if fees are already Accrued    |
-- |2.6       29-Jul-2008  Deepak Gowda       Defect 9365-Pass Org Id to GL API when   |
-- |                                           deriving Company from Location          |
-- |2.7       30-Jul-2008  Deepak Gowda       Defect 9338-Update field JE_STATUS_FLAG  |
-- |                                           to NULL on statement line after matching|
-- |2.8       30-Jul-2008  Deepak Gowda       Defect 9402-Raise exception when invalid |
-- |                                           card types are received from AJB        |
-- |2.9       19-Aug-2008  Deepak Gowda       Defect 10048 - 998 and 996 recs marked   |
-- |                                           as MATCHED_AR when both Cash Receipt ID |
-- |                                           and Recon Date were not found           |
-- |3.0       20-Aug-2008  Deepak Gowda       Defect 10088-Update bank rec id with     |
-- |                                          territory_code(country_code) since same  |
-- |                                          bank_rec_id could be received by multiple|
-- |                                          operating units.                         |
-- |3.1       29-Aug-2008  Deepak Gowda       Locking 998 and 996 transactions when    |
-- |                                           matching to AR receipts to avoid        |
-- |                                           conflicts between multiple instances    |
-- |3.2       04-Sep-2008  Deepak Gowda       Defect 10761 - 999 fee processing error  |
-- |                                           is being marked as 'ERRORED' instead of |
-- |                                           'ERROR' - Also batches from other OU are|
-- |                                            being processed incorrectly.           |
-- |3.3       12-Sep-2008  Deepak Gowda       Defect 9402 -Default cardtype on 999 data|
-- |                                           to the defaults for provider when an    |
-- |                                           invalid/unknown value is received       |
-- |3.4       12-Sep-2008  Deepak Gowda       Defect 11038-Split batches for each card-|
-- |                                           type received from NABCRD               |
-- |                                                                                   |
-- |                                                                                   |
-- |3.5       21-May-2009 Pradeep Krishnan     Defect 14866 -Adding the Payment type   |
-- |                                            for processing                         |
-- |                                                                                   |
-- |3.6       27-May-2009 Pradeep Krishnan    Defect 14688 - Adding the filter         |
-- |                                          condition to avoid the reprocessing of   |
-- |                                          NABCRD records.                          |
-- |                                                                                   |
-- |3.7       03-Jul-2009 Pradeep Krishnan    Defect 517 : CM: E1310 Receipt Date      |
-- |                                          and Transaction                          |
-- |                                          Date logic                               |
-- |3.8       22-Jul-2009 Pradeep Krishnan    Defect 15775 : CM - 1310 Cash Clearing   |
-- |                                          entry created during Fee Reconciliation  |
-- |                                          Process not including Chargback 996      |
-- |                                          Records.                                 |
-- |3.9       28-Aug-2009 Hemalatha S         PROD Defect: 1716,2046                   |
-- |                                          Making all xx_ce_ajb_inbound_preprocess  |
-- |                                          cursor queries org specific.             |
-- |4.0       18-Sep-2009 Cindhu Menaka       For Release 1.1 CR # 601 Defect 1362     |
-- |                                          Making changes in Deriving Bank Cash     |
-- |                                          Clearing CCID for Country US.            |
-- |4.1       23-Sep-2009 Bhuvaneswary S      For Release 1.1 CR # 707 Defect 1890     |
-- |                                          Modified recon_process to process all the|
-- |                                          records in 998 table irrespectice of the |
-- |                                          presence in 999 table                    |
-- |4.2       06-Oct-2009 Raghu               For Release 1.1 CR # 601 Defect 2930     |
-- |4.3       28-Dec-2009 Vinaykumar S        Defect 2610 - PERFORMANCE - (E1310)      |
-- |                                          CM:  Performance Enhancments for R1.2    |
-- |4.4       29-Jan-2010 Aravind A.          PRD Defect 4216, changed the problematic |
-- |                                          SQL to check duplicate files             |
-- |4.6       18-JUN-2010 RamyaPriya M        PROD Defect: 1061                        |
-- |                                          Changes made to derive default card type |
-- |                                          based on org_id                          |
-- |4.7       22-JUN-2010 Jude Felix . A      PRD Defect 4721  Changed the cursor      |
-- |                                          all_998_non_cr_cur to fetch              |
-- |                                          only non zero dollar receipts            |
-- |4.8       27-JUL-2010 Rani Asaithambi     Modified for the PROD Defect 6138.       |
-- |4.9       17-OCT-2010 Jude Felix . A      PRD Defect #8421,changed the problematic |
-- |                                          Delete sql           
-- |5.0       06-26-2014  Manjusha Tangirala  Added PAYPAL for defct 27667             |
-- |6.0       27-OCT-2015 Avinash Badddam     R12.2 Compliance changes                 |
-- |7.0       18-MAY-2016 Avinash Baddam      Changes for defect#37859   	       |
-- |8.0       29-JUL-2016 Avinash Baddam      R12.2 Change
-- +===================================================================================+
   -- -------------------------------------------
-- Global Variables
-- ----------------------------------------------
   gn_request_id              NUMBER         := fnd_global.conc_request_id;
   gn_user_id                 NUMBER         := fnd_global.user_id;
   gn_login_id                NUMBER         := fnd_global.login_id;
   gn_org_id                  NUMBER         := fnd_profile.VALUE ('ORG_ID');
   gn_set_of_bks_id           NUMBER         := fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
   gc_conc_short_name         VARCHAR2 (30)  := 'XXCEAJBRECON';
   gc_match_conc_short_name   VARCHAR2 (30)  := 'XXCEAJBMATCH';
   gn_error                   NUMBER         := 2;
   gn_warning                 NUMBER         := 1;
   gn_normal                  NUMBER         := 0;
   gn_coa_id                  NUMBER;
   gn_match_request_id        NUMBER;
   gc_delimiter               VARCHAR2 (30)  := '.';
   gc_currency_code           VARCHAR2 (30);
   g_print_line               VARCHAR2 (125)
      := '------------------------------------------------------------------------------------------------------------------------';
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
      fnd_file.put_line (fnd_file.output
                       ,    LPAD (' ', 40, ' ')
                         || 'AJB Creditcard Fee Reconciliation'
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
                              , 'XX_CE_AJB_CC_RECON_PKG.print_message_header'
                               );
         fnd_message.set_token ('PROGRAM'
                              , 'CE AJB Creditcard Reconciliation Extension'
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
-- | p_processor_id           IN      Message Details                                |
-- | p_store_num                                                                     |
-- | p_process_date                                                                  |
-- | p_message                                                                       |
-- |                                                                                 |
-- | PREREQUISITES                                                                   |
-- |   None.                                                                         |
-- |                                                                                 |
-- | CALLED BY                                                                       |
-- |   recon_process                                                                 |
-- |                                                                                 |
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
                              , 'XX_CE_AJB_CC_RECON_PKG.print_message_footer'
                               );
         fnd_message.set_token ('PROGRAM'
                              , 'CE AJB Creditcard Reconciliation Extension'
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
         fnd_file.new_line (fnd_file.output, 2);
-------------------------------------------------------------------------------------------------
         fnd_file.put_line
             (fnd_file.output
            , '==============================================================='
             );
         fnd_file.put_line (fnd_file.output
                          ,    'CE AJB Creditcard Reconciliation Extension : '
                            || 'E1310'
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
      ELSE
-------------------------------------------------------------------------------------------------------------
         fnd_file.new_line (fnd_file.output, 2);
         fnd_file.put_line (fnd_file.output
                          ,    RPAD ('-', 46, '-')
                            || '  No Store Fees to process  '
                            || RPAD ('-', 46, '-')
                           );
-------------------------------------------------------------------------------------------------------------
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE'
                              , 'XX_CE_AJB_CC_RECON_PKG.print_message_summary'
                               );
         fnd_message.set_token ('PROGRAM', 'CE AJB Creditcard Reconciliation');
         fnd_message.set_token ('SQLERROR', SQLERRM);
         x_errbuf := fnd_message.get;
         x_retcode := gn_error;
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
   END print_message_summary;
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
-- |p_trx_date               IN      Trnsaction Code ID                              |
-- |p_currency_code          IN      Currency Code                                   |
-- |p_country_code           IN      Country Code                                    |
-- |p_amount                 IN      Amount                                          |
-- |p_provider_code          IN      Provider Name                                   |
-- |p_vset_file              IN      Vset File                                       |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  Accrual_Process                                                                |
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
       WHERE transaction_code_id = p_trx_code_id_original;
    EXCEPTION
      When NO_DATA_FOUND
      Then
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG, 'No data found in the Transaction Codes table for the transaction code id:' || p_trx_code_id_original);
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
        fnd_file.put_line (fnd_file.LOG, 'Amount Miltiplied by * -1 : '|| ln_amount);
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
         fnd_file.put_line (fnd_file.LOG, 'Amount NOT Miltiplied by * -1 : '|| ln_amount);
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
                  )
           VALUES (p_stmt_header_id, p_stmt_line_id, p_bank_account_id
                 , p_ce_interface_seq, p_ce_interface_seq, p_record_type
                 , lc_trx_type, 'FLOAT', p_currency_code, ln_amount, p_match_amount
                 , p_trx_date, p_provider_code, p_bank_rec_id, p_group_id
                 , p_trx_code_id_original, p_trx_num_original
                 , 'Y', SYSDATE, gn_user_id
                 , SYSDATE, gn_user_id
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
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  accrual_process                                                                |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | This procedure will be used to create                                           |
-- | Accrual GL Accounting entries                                                   |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errmsg                 OUT     Error message.                                  |
-- |x_retstatus              OUT     Error code.                                     |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  recon_process                                                                  |
-- +=================================================================================+
   PROCEDURE accrual_process (
      x_errmsg          OUT NOCOPY      VARCHAR2
    , x_retstatus       OUT NOCOPY      NUMBER
    , p_process_date    IN              VARCHAR2
    , p_provider_code   IN              VARCHAR2
    , p_ajb_card_type   IN              VARCHAR2
   )
   IS
-- ------------------------------------------------
-- Get Receipts volume from AR along with card types
-- and processor code to create accrual entries
-- ------------------------------------------------
      CURSOR lcu_get_accrual_summary (lp_process_date IN DATE)
      IS
         SELECT   xacr.org_id, xacr.provider_code, xacr.ajb_card_type
                , xacr.om_card_type, xacr.receipt_date, xacr.currency_code
                , hdr.header_id
                , NVL (hdr.auto_reversal_days, 0) auto_reversal_days
                , hdr.accrual_liability_account
                , hdr.accrual_liability_costcenter
                , hdr.accrual_liability_location, SUM (xacr.amount) amount
             FROM xx_ce_accrual_receipts_v xacr, xx_ce_recon_glact_hdr_v hdr
            WHERE xacr.header_id = hdr.header_id
              AND NVL (xacr.amount, 0) != 0
              AND xacr.provider_code = NVL (p_provider_code, xacr.provider_code)
              AND xacr.ajb_card_type = NVL (p_ajb_card_type, xacr.ajb_card_type)
              AND xacr.receipt_date = lp_process_date
              AND NOT EXISTS (
                    SELECT 1
                      FROM xx_ce_cc_fee_accrual_log
                     WHERE process_date = xacr.receipt_date
                       AND org_id = xacr.org_id
                       AND provider_code = hdr.provider_code
                       AND om_card_type_code = hdr.om_card_type
                       AND currency_code = xacr.currency_code)
         GROUP BY xacr.org_id
                , xacr.provider_code
                , xacr.ajb_card_type
                , xacr.om_card_type
                , xacr.receipt_date
                , xacr.currency_code
                , hdr.header_id
                , hdr.auto_reversal_days
                , hdr.accrual_liability_account
                , hdr.accrual_liability_costcenter
                , hdr.accrual_liability_location;
-- ------------------------------------------------
-- Get all the accrual account details from
-- custom accrual setup tables
-- ------------------------------------------------
      CURSOR lcu_get_accrual_accounts (
         p_header_id      IN   NUMBER
       , p_process_date   IN   DATE
      )
      IS
         SELECT xcgh.provider_code, xcgh.ajb_card_type, xcad.charge_code
              , xcad.charge_description, xcad.charge_percentage
              , xcad.costcenter, xcad.charge_debit_act, xcad.charge_credit_act
              , xcad.location_from, xcad.effective_from_date
              , xcad.effective_to_date, xcad.accrual_frequency
           --, xcgh.accrual_liability_costcenter
           --, xcgh.accrual_liability_account
           --, xcgh.accrual_liability_location
         FROM   xx_ce_accrual_glact_dtl xcad, xx_ce_recon_glact_hdr_v xcgh
          WHERE xcgh.header_id = xcad.header_id
            AND xcgh.header_id = p_header_id
            AND p_process_date BETWEEN xcad.effective_from_date
                                   AND NVL (xcad.effective_to_date
                                          , p_process_date + 1
                                           );
-- ------------------------------------------------
-- Get the Application ID
-- ------------------------------------------------
      CURSOR lcu_get_application
      IS
         SELECT fap.application_id
           FROM fnd_application fap
          WHERE fap.application_short_name = 'SQLGL';
-- ------------------------------------------------
-- Cursor to get the Future Period Name and
-- Validate the Accounting Date
-- ------------------------------------------------
      CURSOR lcu_get_gl_future_periods (p_application_id NUMBER)
      IS
         SELECT gps1.start_date, gps1.end_date, gps1.period_name
           FROM gl_period_statuses gps1
          WHERE gps1.application_id = p_application_id
            AND gps1.set_of_books_id = gn_set_of_bks_id
            AND gps1.closing_status IN ('O', 'F')
            AND gps1.start_date =
                  (SELECT gps.end_date + 1
                     FROM gl_period_statuses gps
                    WHERE gps.set_of_books_id = gn_set_of_bks_id
                      AND gps.closing_status IN ('O', 'F')
                      AND TO_DATE (TRUNC (SYSDATE), 'DD-MON-RRRR')
                            BETWEEN gps.start_date
                                AND gps.end_date
                      AND gps.application_id = p_application_id);
-- -------------------------------------------
-- Local Variable Declaration
-- -------------------------------------------
      get_accrual_accounts_rec    lcu_get_accrual_accounts%ROWTYPE;
      get_gl_future_periods_rec   lcu_get_gl_future_periods%ROWTYPE;
      lr_accrual_summary_rec      lcu_get_accrual_summary%ROWTYPE;
      lc_company                  VARCHAR2 (30);
      lc_account                  VARCHAR2 (30);
      lc_lob                      VARCHAR2 (30);
      lc_intercompany             VARCHAR2 (30)                       := '0000';
      lc_future                   VARCHAR2 (30)                      := '000000';
      lc_accrual_error            VARCHAR2 (4000);
      lc_error                    VARCHAR2 (2000);
      lc_error_flag               VARCHAR2 (1)                        := 'N';
      lc_output_msg               VARCHAR2 (1000);
      lc_error_location           VARCHAR2 (2000);
      lc_accr_liab_cost           VARCHAR2 (150);
      lc_accr_liab_acct           VARCHAR2 (150);
      lc_accr_liab_loc            VARCHAR2 (150);
      lc_accr_liab_company        VARCHAR2 (150);
      lc_accr_liab_lob            VARCHAR2 (150);
      ln_per_amt                  NUMBER;
      ln_entered_dr_amount        NUMBER;
      ln_entered_cr_amount        NUMBER;
      ln_group_id                 NUMBER;
      ln_application_id           NUMBER;
      ln_ccid                     NUMBER;
      ln_total_cr_amount          NUMBER;
      ln_accr_liab_ccid           NUMBER;
      ln_rev_ccid                 NUMBER;
      ln_retcode                  NUMBER;
      lc_je_rev_flg               VARCHAR2 (30);
      lc_je_rev_period            VARCHAR2 (15);
      lc_je_rev_method            VARCHAR2 (20);
      ln_accrual_id               NUMBER;
      ld_process_date             DATE;
      ex_accrual                  EXCEPTION;
      lc_savepoint                VARCHAR2 (80);
      lc_fee_acct                 VARCHAR2 (100);
      lc_acc_liab_acct            VARCHAR2 (100);
      ld_reversal_date            DATE;
      lc_je_line_desc             VARCHAR2 (240);
      lc_user_source_name         VARCHAR2 (50)         := 'OD CM Credit Settle';
      lc_line                     VARCHAR2 (100)
         := '+-----------------------------------------------------------------------------------------------+';
      lc_sub_line                 VARCHAR2 (80)
         := '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ';
      lc_org_name                 VARCHAR2(30);------------FOR RELEASE 1.1 CR # 601
   BEGIN
      IF p_process_date IS NOT NULL
      THEN
         ld_process_date := fnd_conc_date.string_to_date (p_process_date);
      END IF;
      IF gn_coa_id IS NULL
      THEN
         BEGIN
            SELECT chart_of_accounts_id
              INTO gn_coa_id
              --FROM gl_sets_of_books --changed for R12 upgrade V8.0.
              FROM gl_ledgers
             WHERE ledger_id = gn_set_of_bks_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG
                                , 'Error Getting Chart of Accounts!'
                                 );
               RAISE;
         END;
      END IF;
-- ------------------------------------------------
-- Get the Application ID
-- ------------------------------------------------
      OPEN lcu_get_application;
      FETCH lcu_get_application
       INTO ln_application_id;
      CLOSE lcu_get_application;
-- -------------------------------------------
-- Get Group id once for all the GL
-- Accrual entries for the same set of book
-- -------------------------------------------
      SELECT gl_interface_control_s.NEXTVAL
        INTO ln_group_id
        FROM DUAL;
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, 'Group ID:' || TO_CHAR (ln_group_id));
-- ------------------------------------------------
-- Loop through all the processor records in
-- AJB accrual records
-- ------------------------------------------------
      FOR lr_accrual_summary_rec IN lcu_get_accrual_summary (ld_process_date)
      LOOP
         BEGIN
            fnd_file.put_line (fnd_file.LOG, lc_line);
            fnd_file.put_line (fnd_file.LOG
                             ,    'Provider:'
                               || lr_accrual_summary_rec.provider_code
                               || ' / Card Type:'
                               || lr_accrual_summary_rec.ajb_card_type
                               || ' / Receipt Dt:'
                               || lr_accrual_summary_rec.receipt_date
                               || ' / Amt:'
                               || lr_accrual_summary_rec.currency_code
                               || ' '
                               || lr_accrual_summary_rec.amount
                              );
            lc_savepoint :=
                  'SAVEPOINT-XXCECCRECON'
               || ln_group_id
               || '-'
               || lr_accrual_summary_rec.provider_code
               || '-'
               || lr_accrual_summary_rec.ajb_card_type;
            SAVEPOINT lc_savepoint;
            --fnd_file.put_line(fnd_file.LOG, 'Set ' || lc_savepoint);
            --fnd_file.put_line(fnd_file.LOG, ' ');
            ln_total_cr_amount := NULL;
            lc_accr_liab_company := NULL;
            lc_accr_liab_cost := NULL;
            lc_accr_liab_acct := NULL;
            lc_accr_liab_loc := NULL;
            lc_accr_liab_lob := NULL;
            ln_accr_liab_ccid := NULL;
            lc_accr_liab_cost :=
                             lr_accrual_summary_rec.accrual_liability_costcenter;
            lc_accr_liab_acct :=
                                lr_accrual_summary_rec.accrual_liability_account;
            lc_accr_liab_loc :=
                               lr_accrual_summary_rec.accrual_liability_location;
-- ------------------------------------------------
-- Get the Accounting segments for Corporate Acts
-- ------------------------------------------------
-- Get the Company based on the location
-- ------------------------------------------------
            IF lc_accr_liab_company IS NULL
            THEN
               lc_error_location :=
                     'Error:Derive Accrual liability Company from location '
                  || lc_accr_liab_loc;
               lc_accr_liab_company :=
                  xx_gl_translate_utl_pkg.derive_company_from_location
                                                (p_location => lc_accr_liab_loc
                                               , p_org_id => gn_org_id
                                                -- Defect 9365
                                                );
            END IF;
            IF (lc_accr_liab_company IS NULL)
            THEN
               fnd_message.set_name ('XXFIN', 'XX_CE_020_COMPANY_NOT_SETUP');
               lc_accrual_error := lc_accrual_error || '-' || fnd_message.get;
            END IF;
-- ------------------------------------------------
-- Get the LOB Based on Costcenter and Location
-- ------------------------------------------------
            IF lc_accr_liab_lob IS NULL
            THEN
               lc_error_location :=
                  'Error:Derive Accrual Liability LOB from location and costcenter ';
               xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc
                                           (p_location => lc_accr_liab_loc
                                          , p_cost_center => lc_accr_liab_cost
                                          , x_lob => lc_accr_liab_lob
                                          , x_error_message => lc_error
                                           );
            END IF;
            IF (lc_accr_liab_lob IS NULL)
            THEN
               fnd_message.set_name ('XXFIN', 'XX_CE_021_LOB_NOT_SETUP');
               lc_accrual_error := lc_accrual_error || '-' || fnd_message.get;
            END IF;
-- ------------------------------------------------
-- Get Account Code Combination Id
-- ------------------------------------------------
            lc_accr_liab_acct :=
                  lc_accr_liab_company
               || gc_delimiter
               || lc_accr_liab_cost
               || gc_delimiter
               || lc_accr_liab_acct
               || gc_delimiter
               || lc_accr_liab_loc
               || gc_delimiter
               || lc_intercompany
               || gc_delimiter
               || lc_accr_liab_lob
               || gc_delimiter
               || lc_future;
            lc_error_location :=
                  'Get the Accrual Liability CCID from fnd_flex_ext.get_ccid '
               || lc_accr_liab_acct;
-- ------------------------------------------------
-- Get CCID of Liability Accrual Liability
-- ------------------------------------------------
            IF (ln_accr_liab_ccid IS NULL
                OR ln_accr_liab_ccid = 0)
            THEN
               ln_accr_liab_ccid :=
                  fnd_flex_ext.get_ccid
                                    (application_short_name => 'SQLGL'
                                   , key_flex_code => 'GL#'
                                   , structure_number => gn_coa_id
                                   , validation_date => SYSDATE
                                   , concatenated_segments => lc_accr_liab_acct
                                    );
               IF ln_accr_liab_ccid = 0
               THEN
                  lc_error := fnd_flex_ext.GET_MESSAGE;
                  fnd_file.put_line (fnd_file.LOG
                                   ,    'Error Getting CCID for Accrual A/c '
                                     || lc_accr_liab_acct
                                     || ':'
                                     || SUBSTR (lc_error, 1, 200)
                                    );
                  fnd_message.set_name ('XXFIN', 'XX_CE_023_CCID_NOT_SETUP');
                  lc_accrual_error :=
                          lc_accrual_error || lc_error || '-' || fnd_message.get;
                  lc_error_flag := 'Y';
                  RAISE ex_accrual;
               END IF;
            END IF;
            fnd_file.put_line (fnd_file.LOG
                             ,    'Accrual Liability A/c:'
                               || lc_accr_liab_acct
                               || ' (Accrual CCID:'
                               || ln_accr_liab_ccid
                               || ')'
                              );
-- ------------------------------------------------
-- Get the Percentage and Accounting segments
-- for create GL accrual entries
-- ------------------------------------------------
            lc_error_location := ' Process Fee Lines to Accrue';
            OPEN lcu_get_accrual_accounts
                          (p_header_id => lr_accrual_summary_rec.header_id
                         , p_process_date => lr_accrual_summary_rec.receipt_date
                          );
            LOOP
               FETCH lcu_get_accrual_accounts
                INTO get_accrual_accounts_rec;
               EXIT WHEN lcu_get_accrual_accounts%NOTFOUND;
               fnd_file.put_line (fnd_file.LOG, lc_sub_line);
               fnd_file.put_line (fnd_file.LOG, ' ');
               fnd_file.put_line
                                (fnd_file.LOG
                               ,    'Process Fee: '
                                 || get_accrual_accounts_rec.charge_description
                                 || '   '
                                 || get_accrual_accounts_rec.charge_percentage
                                 || '%  Accrual Frequency: '
                                 || get_accrual_accounts_rec.accrual_frequency
                                );
               fnd_file.put_line (fnd_file.LOG, ' ');
               lc_accrual_error := NULL;
               lc_account := NULL;
               lc_lob := NULL;
               lc_error_flag := 'N';
               ln_per_amt := 0;
               ln_entered_dr_amount := NULL;
               lc_output_msg := NULL;
               lc_je_rev_flg := NULL;
               lc_je_rev_period := NULL;
               lc_je_rev_method := NULL;
               ld_reversal_date := NULL;
               lc_je_line_desc := NULL;
               lc_error_location :=
                     'Error:Derive (Fee) Company from location '
                  || get_accrual_accounts_rec.location_from;
               lc_company :=
                  xx_gl_translate_utl_pkg.derive_company_from_location
                          (p_location => get_accrual_accounts_rec.location_from
                         , p_org_id => gn_org_id                  -- Defect 9365
                          );
               IF (lc_company IS NULL
                   OR lc_accr_liab_company IS NULL)
               THEN
                  fnd_message.set_name ('XXFIN', 'XX_CE_020_COMPANY_NOT_SETUP');
                  lc_accrual_error :=
                                     lc_accrual_error || '-' || fnd_message.get;
               END IF;
               lc_error_location :=
                            'Error:Derive Fee LOB from location and costcenter ';
               xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc
                          (p_location => get_accrual_accounts_rec.location_from
                         , p_cost_center => get_accrual_accounts_rec.costcenter
                         , x_lob => lc_lob
                         , x_error_message => lc_error
                          );
               IF (lc_lob IS NULL
                   OR lc_accr_liab_lob IS NULL)
               THEN
                  fnd_message.set_name ('XXFIN', 'XX_CE_021_LOB_NOT_SETUP');
                  lc_accrual_error :=
                                     lc_accrual_error || '-' || fnd_message.get;
               END IF;
               lc_fee_acct :=
                     lc_company
                  || gc_delimiter
                  || get_accrual_accounts_rec.costcenter
                  || gc_delimiter
                  || get_accrual_accounts_rec.charge_debit_act
                  || gc_delimiter
                  || get_accrual_accounts_rec.location_from
                  || gc_delimiter
                  || lc_intercompany
                  || gc_delimiter
                  || lc_lob
                  || gc_delimiter
                  || lc_future;
-- ------------------------------------------------
-- Get the CCID.
-- ------------------------------------------------
               IF lc_error_flag = 'N'
               THEN
                  ln_ccid :=
                     fnd_flex_ext.get_ccid
                                          (application_short_name => 'SQLGL'
                                         , key_flex_code => 'GL#'
                                         , structure_number => gn_coa_id
                                         , validation_date => SYSDATE
                                         , concatenated_segments => lc_fee_acct
                                          );
                  IF ln_ccid = 0
                  THEN
                     lc_error := fnd_flex_ext.GET_MESSAGE;
                     fnd_file.put_line (fnd_file.LOG
                                      ,    'Error getting Fee Acct CCID for ('
                                        || lc_fee_acct
                                        || ': '
                                        || SUBSTR (lc_error, 1, 200)
                                       );
                     fnd_message.set_name ('XXFIN', 'XX_CE_023_CCID_NOT_SETUP');
                     lc_accrual_error :=
                          lc_accrual_error || lc_error || '-' || fnd_message.get;
                     lc_error_flag := 'Y';
                     RAISE ex_accrual;
                  END IF;
               END IF;
               fnd_file.put_line (fnd_file.LOG
                                ,    'Fee A/c:'
                                  || lc_fee_acct
                                  || ' (Fee CCID:'
                                  || ln_ccid
                                  || ')'
                                 );
               lc_je_line_desc :=
                  SUBSTR (   lr_accrual_summary_rec.provider_code
                          || ' / '
                          || lr_accrual_summary_rec.ajb_card_type
                          || ' / Trx Dt:'
                          || lr_accrual_summary_rec.receipt_date
                          || ' / Gross Amt:'
                          || lr_accrual_summary_rec.currency_code
                          || ' '
                          || lr_accrual_summary_rec.amount
                          || ' / '
                          || get_accrual_accounts_rec.charge_description
                        , 1
                        , 240
                         );
-- -------------------------------------------
-- Call the GL Common Package to create
-- GL Accrual Entry
-- If Monthly Fees, then create a self reversing entry for next period,
-- If daily, create an addioinal reversal entry after offset days.
-- -------------------------------------------
               IF get_accrual_accounts_rec.accrual_frequency = 'MONTHLY'
               THEN
                  OPEN lcu_get_gl_future_periods
                                         (p_application_id => ln_application_id);
                  FETCH lcu_get_gl_future_periods
                   INTO get_gl_future_periods_rec;
                  CLOSE lcu_get_gl_future_periods;
                  IF get_gl_future_periods_rec.period_name IS NULL
                  THEN
                     fnd_message.set_name ('XXFIN'
                                         , 'XX_CE_024_GL_PERIOD_NOT_SETUP'
                                          );
                     lc_accrual_error :=
                                      lc_accrual_error || '-' || fnd_message.get;
                     lc_error_flag := 'Y';
                  END IF;
                  lc_je_rev_flg := 'YES';
                  lc_je_rev_period := get_gl_future_periods_rec.period_name;
                  lc_je_rev_method := 'NO';          --Use Dr Cr Reversal method
                  lc_je_line_desc :=
                     SUBSTR (   lc_je_line_desc
                             || '/ Auto Reverses '
                             || lc_je_rev_period
                           , 1
                           , 240
                            );
               ELSE
                  lc_je_rev_flg := NULL;
                  lc_je_rev_period := NULL;
                  lc_je_rev_method := NULL;
                  ld_reversal_date :=
                     TRUNC (SYSDATE)
                     + lr_accrual_summary_rec.auto_reversal_days;
                  lc_je_line_desc :=
                     SUBSTR (   lc_je_line_desc
                             || '/ Reverses on '
                             || ld_reversal_date
                           , 1
                           , 240
                            );
               END IF;
-- ------------------------------------------------
-- Create Accounting Entries
-- By calling common custom GL package
-- ------------------------------------------------
               IF lc_error_flag = 'N'
               THEN
                  ln_per_amt :=
                     ROUND (  lr_accrual_summary_rec.amount
                            * (get_accrual_accounts_rec.charge_percentage / 100
                              )
                          , 2
                           );
-------------------------------------------------------------------
-- Create the following entries
--
-- DR Daily/Monthly  Fee
--                             CR. Daily/Monthly Accrual Liability
--
-- Monthly Entries will Self-Reverse in the next period
-- AND Automaically create the following
--
-- DR. Daily/Monthly Accrual Liability
--
--                                       CR Daily/Monthly  Fee
--
--
-- Daily Entries will have to be reversed after this step.
-------------------------------------------------------------------
                  lc_error_location :=
                        'Create Accrual Journal entry for Fee: '
                     || get_accrual_accounts_rec.charge_description;
                  xx_gl_interface_pkg.create_stg_jrnl_line
                       (p_status => 'NEW'
                      , p_date_created => TRUNC (SYSDATE)
                      , p_created_by => gn_user_id
                      , p_actual_flag => 'A'
                      , p_group_id => ln_group_id
                      , p_je_reference => ln_group_id
                      , p_batch_name => TO_CHAR (SYSDATE, 'YYYY/MM/DD')
                      , p_batch_desc => NULL
                      , p_user_source_name => lc_user_source_name
                      , p_user_catgory_name => 'Miscellaneous'
                      , p_set_of_books_id => gn_set_of_bks_id
                      , p_accounting_date => TRUNC (SYSDATE)
                      , p_currency_code => lr_accrual_summary_rec.currency_code
                      , p_company => NULL
                      , p_cost_center => NULL
                      , p_account => NULL
                      , p_location => NULL
                      , p_intercompany => NULL
                      , p_channel => NULL
                      , p_future => NULL
                      , p_je_rev_flg => lc_je_rev_flg
                      , p_je_rev_period => lc_je_rev_period
                      , p_je_rev_method => lc_je_rev_method
                      , p_ccid => ln_ccid
                      , p_entered_dr => ln_per_amt
                      , p_entered_cr => NULL
                      , p_je_line_dsc => lc_je_line_desc
                      , x_output_msg => lc_output_msg
                       );
                  fnd_file.put_line (fnd_file.LOG
                                   , 'DR  ' || lc_fee_acct || '   '
                                     || ln_per_amt
                                    );
-- -------------------------------------------
-- Calling the Exception
-- If insertion Failed into XX_GL_INTERFACE_NA_STG
-- -------------------------------------------
                  IF lc_output_msg IS NOT NULL
                  THEN
                     lc_accrual_error := lc_accrual_error || lc_output_msg;
                     RAISE ex_accrual;
                  END IF;
                  --Create the Accrual Liability entry
                  lc_error_location :=
                        'Create Accrual Liability Journal Entry for Fee: '
                     || get_accrual_accounts_rec.charge_description;
                  xx_gl_interface_pkg.create_stg_jrnl_line
                       (p_status => 'NEW'
                      , p_date_created => TRUNC (SYSDATE)
                      , p_created_by => gn_user_id
                      , p_actual_flag => 'A'
                      , p_group_id => ln_group_id
                      , p_je_reference => ln_group_id
                      , p_batch_name => TO_CHAR (SYSDATE, 'YYYY/MM/DD')  -- NULL
                      , p_batch_desc => NULL
                      , p_user_source_name => lc_user_source_name
                      --'OD CM Credit Settle'
                  ,     p_user_catgory_name => 'Miscellaneous'
                      , p_set_of_books_id => gn_set_of_bks_id
                      , p_accounting_date => TRUNC (SYSDATE)
                      , p_currency_code => lr_accrual_summary_rec.currency_code
                      , p_company => NULL
                      , p_cost_center => NULL
                      , p_account => NULL
                      , p_location => NULL
                      , p_intercompany => NULL
                      , p_channel => NULL
                      , p_future => NULL
                      , p_je_rev_flg => lc_je_rev_flg
                      , p_je_rev_period => lc_je_rev_period
                      , p_je_rev_method => lc_je_rev_method
                      , p_ccid => ln_accr_liab_ccid
                      , p_entered_dr => NULL
                      , p_entered_cr => ln_per_amt
                      , p_je_line_dsc => lc_je_line_desc
                      , x_output_msg => lc_output_msg
                       );
                  fnd_file.put_line (fnd_file.LOG
                                   ,    'CR  '
                                     || lc_accr_liab_acct
                                     || '                     '
                                     || ln_per_amt
                                    );
                  IF get_accrual_accounts_rec.accrual_frequency = 'MONTHLY'
                  THEN
                     fnd_file.put_line (fnd_file.LOG, ' ');
                     fnd_file.put_line (fnd_file.LOG
                                      ,    'Monthly Fee Auto Reverses '
                                        || lc_je_rev_period
                                       );
                  END IF;
-- -------------------------------------------
-- Calling the Exception
-- If insertion Failed into XX_GL_INTERFACE_NA_STG
-- -------------------------------------------
                  IF lc_output_msg IS NOT NULL
                  THEN
                     lc_accrual_error := lc_accrual_error || lc_output_msg;
                     RAISE ex_accrual;
                  END IF;
-- -------------------------------------------
-- Monthly Charges will Self reverse from above.
-- Reverse the Daily charges after the offset days below.
-- -------------------------------------------
                  IF get_accrual_accounts_rec.accrual_frequency = 'DAILY'
                  THEN
                     lc_error_location :=
                           'Create Reversal for Journal Entry for Daily Fee: '
                        || get_accrual_accounts_rec.charge_description;
                     fnd_file.put_line (fnd_file.LOG, ' ');
                     fnd_file.put_line (fnd_file.LOG
                                      ,    'Daily Fee Reverses on '
                                        || ld_reversal_date
                                       );
                     lc_je_line_desc :=
                        SUBSTR (   'Reversal of Accrual on '
                                || TRUNC (SYSDATE)
                                || ' :'
                                || lc_je_line_desc
                              , 1
                              , 240
                               );
                     -- Reverse the Above Entry for Daily fees
                     -- after the offset number of days.
                     xx_gl_interface_pkg.create_stg_jrnl_line
                        (p_status => 'NEW'
                       , p_date_created => TRUNC (SYSDATE)
                       , p_created_by => gn_user_id
                       , p_actual_flag => 'A'
                       , p_group_id => ln_group_id
                       , p_je_reference => ln_group_id
                       , p_batch_name => TO_CHAR (ld_reversal_date
                                                , 'YYYY/MM/DD')
                       , p_batch_desc => NULL
                       , p_user_source_name => lc_user_source_name
                       , p_user_catgory_name => 'Miscellaneous'
                       , p_set_of_books_id => gn_set_of_bks_id
                       , p_accounting_date => ld_reversal_date
                       , p_currency_code => lr_accrual_summary_rec.currency_code
                       , p_company => NULL
                       , p_cost_center => NULL
                       , p_account => NULL
                       , p_location => NULL
                       , p_intercompany => NULL
                       , p_channel => NULL
                       , p_future => NULL
                       , p_je_rev_flg => NULL
                       , p_je_rev_period => NULL
                       , p_je_rev_method => NULL
                       , p_ccid => ln_ccid
                       , p_entered_dr => NULL
                       , p_entered_cr => ln_per_amt
                       , p_je_line_dsc => lc_je_line_desc
                       , x_output_msg => lc_output_msg
                        );
                     fnd_file.put_line (fnd_file.LOG
                                      ,    'CR  '
                                        || lc_fee_acct
                                        || '                     '
                                        || ln_per_amt
                                       );
-- -------------------------------------------
-- Calling the Exception
-- If insertion Failed into XX_GL_INTERFACE_NA_STG
-- -------------------------------------------
                     IF lc_output_msg IS NOT NULL
                     THEN
                        lc_accrual_error := lc_accrual_error || lc_output_msg;
                        RAISE ex_accrual;
                     END IF;
                     lc_error_location :=
                           'Create Reversal of Accrual Liability Journal Entry for Daily Fee: '
                        || get_accrual_accounts_rec.charge_description;
                     xx_gl_interface_pkg.create_stg_jrnl_line
                        (p_status => 'NEW'
                       , p_date_created => TRUNC (SYSDATE)
                       , p_created_by => gn_user_id
                       , p_actual_flag => 'A'
                       , p_group_id => ln_group_id
                       , p_je_reference => ln_group_id
                       , p_batch_name => TO_CHAR (ld_reversal_date
                                                , 'YYYY/MM/DD')          -- NULL
                       , p_batch_desc => NULL
                       , p_user_source_name => lc_user_source_name
                       , p_user_catgory_name => 'Miscellaneous'
                       , p_set_of_books_id => gn_set_of_bks_id
                       , p_accounting_date => ld_reversal_date
                       , p_currency_code => lr_accrual_summary_rec.currency_code
                       , p_company => NULL
                       , p_cost_center => NULL
                       , p_account => NULL
                       , p_location => NULL
                       , p_intercompany => NULL
                       , p_channel => NULL
                       , p_future => NULL
                       , p_ccid => ln_accr_liab_ccid
                       , p_entered_dr => ln_per_amt
                       , p_entered_cr => NULL
                       , p_je_line_dsc => lc_je_line_desc
                       , x_output_msg => lc_output_msg
                        );
                     fnd_file.put_line (fnd_file.LOG
                                      ,    'DR: '
                                        || lc_accr_liab_acct
                                        || '   '
                                        || ln_per_amt
                                       );
-- -------------------------------------------
-- Calling the Exception
-- If insertion Failed into XX_GL_INTERFACE_NA_STG
-- -------------------------------------------
                     IF lc_output_msg IS NOT NULL
                     THEN
                        lc_accrual_error := lc_accrual_error || lc_output_msg;
                        RAISE ex_accrual;
                     END IF;
                  END IF;
               END IF;
               fnd_file.put_line (fnd_file.LOG, ' ');
            END LOOP;
            CLOSE lcu_get_accrual_accounts;
            fnd_file.put_line (fnd_file.LOG, ' ');
-- -------------------------------------------
-- Log the accruals for future refence and to prevent duplication
-- -------------------------------------------
            SELECT xx_ce_cc_fee_accrual_log_s.NEXTVAL
              INTO ln_accrual_id
              FROM DUAL;
            INSERT INTO xx_ce_cc_fee_accrual_log
                        (accrual_id, process_date
                       , om_card_type_code
                       , ajb_card_type
                       , currency_code
                       , amount
                       , provider_code, GROUP_ID
                       , request_id
                       , org_id, status, creation_date
                       , created_by, last_update_date, last_updated_by
                        )
                 VALUES (ln_accrual_id, ld_process_date
                       , lr_accrual_summary_rec.om_card_type
                       , lr_accrual_summary_rec.ajb_card_type
                       , lr_accrual_summary_rec.currency_code
                       , lr_accrual_summary_rec.amount
                       , lr_accrual_summary_rec.provider_code, ln_group_id
                       , fnd_global.conc_request_id
                       , lr_accrual_summary_rec.org_id, 'PROCESSED', SYSDATE
                       , gn_user_id, SYSDATE, gn_user_id
                        );
         EXCEPTION
            WHEN ex_accrual
            THEN
               x_errmsg :=
                     '***Error at:'
                  || lc_error_location
                  || '-'
                  || lc_accrual_error
                  || '. Rolling back to savepoint:'
                  || lc_savepoint;
               fnd_file.put_line (fnd_file.LOG, x_errmsg);
               ROLLBACK TO lc_savepoint;
            WHEN OTHERS
            THEN
               x_errmsg :=
                     '***Error at:'
                  || lc_error_location
                  || '-'
                  || lc_accrual_error
                  || '. Rolling back to savepoint:'
                  || lc_savepoint;
               fnd_file.put_line (fnd_file.LOG, x_errmsg);
               ROLLBACK TO lc_savepoint;
         END;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE'
                              , 'XX_CE_AJB_CC_RECON_PKG.accrual_process'
                               );
         fnd_message.set_token ('PROGRAM', 'CE AJB Creditcard Reconciliation');
         fnd_message.set_token ('SQLERROR', SQLERRM);
         x_errmsg := fnd_message.get;
         x_retstatus := gn_error;
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, x_errmsg);
   END accrual_process;
   FUNCTION get_default_card_type (p_processor_id IN VARCHAR2
                                  ,p_org_id       IN NUMBER    --Added for Defect #1061
                                  )
      RETURN VARCHAR2
   IS
   BEGIN
      IF p_processor_id IN ('MPSCRD', 'NABCRD')
      THEN
         RETURN 'VISA';
      ELSIF p_processor_id = 'CCSCRD'
      THEN
         RETURN 'PL COMMERCIAL';
      ELSIF p_processor_id = 'AMX3RD'
      THEN
         RETURN 'AMEX';
      ELSIF p_processor_id = 'DCV3RN'
      THEN
         RETURN 'DISCOVER';
      ELSIF (p_processor_id = 'TELCHK' AND p_org_id = 404) -- Added for Defect #1061
      THEN
         RETURN 'ECA';
      ELSIF (p_processor_id = 'TELCHK' AND p_org_id = 403) -- Added for Defect #1061
      THEN
         RETURN 'Paper';
      Elsif (P_Processor_Id= 'PAYPAL')
      THEN RETURN 'PAYPAL';
      END IF;
   END get_default_card_type;
-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  recon_process                                                                  |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | Procedure to process the 999 Store Records and call the reversal process        |
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
-- |  recon_process                                                                  |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- +=================================================================================+
   PROCEDURE recon_process (
      x_errbuf          OUT NOCOPY      VARCHAR2
    , x_retcode         OUT NOCOPY      NUMBER
    , p_provider_code   IN              VARCHAR2
    , p_from_date       IN              VARCHAR2
    , p_to_date         IN              VARCHAR2
    , p_email_id        IN              VARCHAR2 DEFAULT NULL
   )
   AS
      CURSOR lcu_get_intf_batches (
         lp_processor_id   VARCHAR2
       , lp_from_date      DATE
       , lp_to_date        DATE
      )
      IS
         SELECT     trx_id, bank_rec_id, processor_id, trx_date
               FROM xx_ce_999_interface xc9i
              WHERE 1 = 1
                AND record_type = 'AJB'
                AND processor_id = NVL (lp_processor_id, xc9i.processor_id)
                AND trx_date BETWEEN NVL (lp_from_date, xc9i.trx_date)
                                 AND NVL (lp_to_date, xc9i.trx_date)
                AND xc9i.deposits_matched = 'Y'
                AND NVL (xc9i.expenses_complete, 'N') = 'N'
                AND ((EXISTS (
                         SELECT 1
                         FROM xx_ce_ajb999_v xca9
                         WHERE NVL (xca9.status_1310, 'ERROR') != 'PROCESSED'
                         AND NVL(xca9.attribute1,'FEE_RECON_NO') != 'FEE_RECON_YES'  -- Added for the Defect 6138.
                         AND xca9.bank_rec_id = xc9i.bank_rec_id
                         AND xca9.processor_id = xc9i.processor_id)
                     )
                     OR (((SELECT COUNT (1)
                           FROM xx_ce_ajb999_v xca9
                           WHERE NVL (xca9.status_1310, 'ERROR') != 'PROCESSED'
                           AND NVL(XCA9.ATTRIBUTE1,'FEE_RECON_NO') != 'FEE_RECON_YES' --  Added for the Defect 6138.
                           AND xca9.bank_rec_id = xc9i.bank_rec_id
                           AND xca9.processor_id = xc9i.processor_id) = 0
                         )
                         AND ((EXISTS (
                                  SELECT 1
                                  FROM xx_ce_ajb998_v xca8
                                  WHERE xca8.bank_rec_id = xc9i.bank_rec_id
                                  AND xca8.processor_id = xc9i.processor_id)
                              )
                              OR (EXISTS (
                                     SELECT 1
                                     FROM xx_ce_ajb996_v xca6
                                     WHERE xca6.bank_rec_id = xc9i.bank_rec_id
                                     AND xca6.processor_id =
                                                               xc9i.processor_id)
                                 )
                             )
                        )
                    )
         FOR UPDATE NOWAIT;
      CURSOR lcu_get_recon_batches (
         p_processor_id   VARCHAR2
       , p_bank_rec_id    VARCHAR2
      )
      IS
         SELECT   xcan.bank_rec_id, xcan.processor_id, xcan.store_num
                , xcan.recon_date, xcan.currency, xcan.card_type
                , SUM (xcan.net_amount) net_amount
             FROM xx_ce_ajb_net_amounts_v xcan
            WHERE 1 = 1
              AND xcan.bank_rec_id = p_bank_rec_id
              AND xcan.processor_id = p_processor_id
              AND   NVL(xcan.attribute1,'FEE_RECON_NO') !='FEE_RECON_YES'   --  Added for the Defect 6138.
              -- Commented this portion for the CR 707 defect 1890 for R1.1
              /*AND ((EXISTS (
                       SELECT 1
                         FROM xx_ce_ajb999_v xca9
                        WHERE NVL (xca9.status_1310, 'ERROR') != 'PROCESSED'
                          AND xca9.bank_rec_id = xcan.bank_rec_id
                          AND xca9.processor_id = xcan.processor_id
                          AND xca9.store_num = xcan.store_num
                          AND xca9.cardtype = xcan.card_type)
                   )
                   OR ((SELECT COUNT (1)
                          FROM xx_ce_ajb999_v xca9
                         WHERE xca9.bank_rec_id = xcan.bank_rec_id
                           AND xca9.processor_id = xcan.processor_id) = 0
                      )         -- Checking "No fee" Batches to book Net entries
                  )   */                   --Do not check for ERROR-WILL DUPLICATE
                  -- End of the change for CR 707 defect 1890
         GROUP BY xcan.bank_rec_id
                , xcan.processor_id
                , xcan.store_num
                , xcan.recon_date
                , xcan.currency
                , xcan.card_type;
      /* --Defect 8940.
         CURSOR lcu_get_recon_batches(
            lp_processor_id  VARCHAR2
          , lp_from_date     DATE
          , lp_to_date       DATE
         )
         IS
            SELECT   xcan.bank_rec_id, xcan.processor_id, xcan.store_num
                   , xcan.recon_date, xcan.currency, xcan.card_type
                   , SUM(xcan.net_amount) net_amount
                FROM xx_ce_ajb_net_amounts_v xcan
                   , xx_ce_999_interface xc9i
               WHERE 1 = 1
                 AND xcan.processor_id = NVL(lp_processor_id, xcan.processor_id)
                 AND xcan.recon_date BETWEEN NVL(lp_from_date, xcan.recon_date)
                                         AND NVL(lp_to_date, xcan.recon_date)
                 AND xc9i.bank_rec_id = xcan.bank_rec_id
                 AND xc9i.processor_id = xcan.processor_id           --Defect 7633.
                 AND NVL(xc9i.deposits_matched, 'N') = 'Y'
                 AND NVL(xc9i.expenses_complete, 'N') = 'N'
                 AND( (EXISTS(SELECT 1
                                FROM xx_ce_ajb999_v xca9
                               WHERE NVL(xca9.status_1310, 'ERROR') != 'PROCESSED'
                                 AND bank_rec_id = xcan.bank_rec_id
                                 AND processor_id = xcan.processor_id
                                 AND store_num = xcan.store_num
                                 AND currency = xcan.currency)
                      )
                     OR( (SELECT COUNT(1)
                            FROM xx_ce_ajb999_v xca9
                           WHERE bank_rec_id = xcan.bank_rec_id
                             AND processor_id = xcan.processor_id
                             AND store_num = xcan.store_num
                             AND currency = xcan.currency) = 0
                       )
                    )
            GROUP BY xcan.bank_rec_id
                   , xcan.processor_id
                   , xcan.store_num
                   , xcan.recon_date
                   , xcan.currency
                   , xcan.card_type;
        */ --Defect 8940.
         /*  -- Defect  8877 Do not select store fees that were already processed.
         CURSOR lcu_get_recon_batches(
            lp_processor_id  VARCHAR2
          , lp_from_date     DATE
          , lp_to_date       DATE
         )
         IS
            SELECT   bank_rec_id, processor_id, store_num, recon_date, currency
                   , net_amount, COUNT(*)
                FROM xx_ce_ajb_net_amounts_v xca9
               WHERE 1 = 1
                 AND processor_id = NVL(lp_processor_id, processor_id)
                 AND recon_date BETWEEN NVL(lp_from_date, recon_date)
                                    AND NVL(lp_to_date, recon_date)
                 AND EXISTS(SELECT 1
                              FROM xx_ce_999_interface
                             WHERE bank_rec_id = xca9.bank_rec_id
                               AND processor_id = xca9.processor_id  --Defect 7633.
                               AND NVL(deposits_matched, 'N') = 'Y'
                               AND NVL(expenses_complete, 'N') = 'N')
            GROUP BY bank_rec_id
                   , processor_id
                   , store_num
                   , recon_date
                   , currency
                   , net_amount;
          */
      CURSOR lcu_get_recon_hdr (
         p_processor      IN   VARCHAR2
       , p_card_type      IN   VARCHAR2
       , p_process_date   IN   DATE
       , p_store_num      IN   NUMBER
      )
      IS
         SELECT DISTINCT xcgh.header_id, xcgh.provider_code, xcgh.org_id
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
                     AND p_process_date BETWEEN xcgh.effective_from_date
                                            AND NVL (xcgh.effective_to_date
                                                   , p_process_date + 1
                                                    )
                ORDER BY xcgh.provider_code, xcgh.ajb_card_type;
/*
 CURSOR lcu_get_recon_hdr(
    p_processor     IN  VARCHAR2
  --, p_card_type     IN  VARCHAR2
 ,  p_process_date  IN  DATE
  , p_store_num     IN  NUMBER
 )
 IS
    SELECT   xcgh.header_id, xcgh.provider_code, xcgh.org_id
           , xcgh.ajb_card_type
           , xcgh.recon_credit_costcenter ar_recv_costcenter
           , xcgh.recon_credit_account ar_recv_account
           , xcgh.recon_card_type_costcenter card_type_costcenter
           , xcgh.recon_card_type_account card_type_account
           , xcgh.bank_clearing_costcenter, xcgh.bank_clearing_account
           , xcgh.bank_clearing_location, COUNT(*) no_of_fees
        FROM xx_ce_recon_glact_hdr xcgh, xx_ce_recon_glact_dtl xcrd
       WHERE xcgh.provider_code = p_processor
         -- AND xcgh.ajb_card_type = p_card_type
         AND xcgh.org_id = gn_org_id
         AND xcgh.header_id = xcrd.header_id
         AND p_store_num BETWEEN xcrd.location_from AND xcrd.location_to
         AND p_process_date BETWEEN xcrd.effective_from_date
                                AND NVL(xcrd.effective_to_date
                                      , p_process_date + 1
                                       )
    GROUP BY xcgh.header_id
           , xcgh.provider_code
           , xcgh.org_id
           , xcgh.ajb_card_type
           , xcgh.recon_credit_costcenter
           , xcgh.recon_credit_account
           , xcgh.recon_card_type_costcenter
           , xcgh.recon_card_type_account
           , xcgh.bank_clearing_costcenter
           , xcgh.bank_clearing_account
           , xcgh.bank_clearing_location
    ORDER BY xcgh.provider_code, xcgh.ajb_card_type;
  */-- -------------------------------------------
 -- Get all the un-processed store fees summaries
 -- by procesor id and cardtype
 -- -------------------------------------------
      CURSOR lcu_get_store_fees (
         p_bank_rec_id    IN   VARCHAR2
       , p_processor_id   IN   VARCHAR2
       , p_card_type      IN   VARCHAR2
       , p_store_num      IN   VARCHAR2
       , p_currency       IN   VARCHAR2
      )
      IS
         SELECT     LPAD (xca9.store_num, 6, '0') store_num, xca9.provider_type
                  , xca9.cardtype, xca9.submission_date, xca9.processor_id
                  , xca9.sequence_id_999, xca9.bank_rec_id, xca9.currency
               FROM xx_ce_ajb999_v xca9
              WHERE NVL (xca9.status_1310, 'ERROR') != 'PROCESSED'
              AND   NVL(xca9.attribute1,'FEE_RECON_NO') !='FEE_RECON_YES'  -- Added for the defect 6138.
                AND bank_rec_id = p_bank_rec_id
                AND processor_id = p_processor_id
                AND cardtype = p_card_type
                AND store_num = p_store_num
                AND currency = p_currency
         FOR UPDATE NOWAIT
           ORDER BY 1, 2, 3;
-- -------------------------------------------
-- Get the details accounts to reconcile
-- -------------------------------------------
      CURSOR lcu_get_recon_dtl (
         p_header_id      IN   VARCHAR2
       , p_process_date   IN   DATE
       , p_store_num      IN   NUMBER
      )
      IS
         SELECT xcrd.details_id, xcrd.charge_code, xcrd.charge_description
              , xcrd.costcenter charge_costcenter
              , xcrd.charge_debit_act charge_debit_account
              , xcrd.charge_credit_act charge_credit_account
              , xcrd.location_from, xcrd.location_to, xcrd.effective_from_date
              , xcrd.effective_to_date
           FROM xx_ce_recon_glact_dtl xcrd
          WHERE 1 = 1
            AND xcrd.header_id = p_header_id
            AND p_store_num BETWEEN xcrd.location_from AND xcrd.location_to
            AND p_process_date BETWEEN xcrd.effective_from_date
                                   AND NVL (xcrd.effective_to_date
                                          , p_process_date + 1
                                           );
-- -------------------------------------------
-- Get the Chart of Accounts ID
-- -------------------------------------------
      CURSOR lcu_get_coaid
      IS
         SELECT gsob.chart_of_accounts_id, gsob.currency_code
           --FROM gl_sets_of_books gsob --Changed for R12
           FROM gl_ledgers gsob  
          WHERE ledger_id = gn_set_of_bks_id;
-- -------------------------------------------
-- Local Variable Declaration
-- -------------------------------------------
      --no_fees_recon_batch_rec   lcu_get_no_fees_recon_batches%ROWTYPE;
      intf_batches_rec           lcu_get_intf_batches%ROWTYPE;
      store_fee_rec              lcu_get_store_fees%ROWTYPE;
      recon_batches_rec          lcu_get_recon_batches%ROWTYPE;
      recon_hdr_rec              lcu_get_recon_hdr%ROWTYPE;
      recon_dtl_rec              lcu_get_recon_dtl%ROWTYPE;
      lc_error_details           VARCHAR2 (32000);
      lc_error_location          VARCHAR2 (32000);
      lc_errmsg                  VARCHAR2 (2000);
      lc_output_msg              VARCHAR2 (2000);
      lc_trx_valid_flag          VARCHAR2 (1);
      lc_source_err_flag         VARCHAR2 (1);
      lc_err_msg                 VARCHAR2 (2000);
      --lc_provider_code          VARCHAR2(30);
      lc_email_addr              VARCHAR2 (60);
      lc_sql                     VARCHAR2 (4000);
      lc_company                 VARCHAR2 (150);
      lc_intercompany            VARCHAR2 (30)                         := '0000';
      lc_future                  VARCHAR2 (30)                       := '000000';
      lc_ar_recv_lob             VARCHAR2 (150);
      lc_card_type_lob           VARCHAR2 (150);
      lc_bank_clearing_lob       VARCHAR2 (150);
      lc_charge_lob              VARCHAR2 (150);
      lc_error_flag              VARCHAR2 (1)                             := 'N';
      ln_no_fee_count            NUMBER                                     := 0;
      ln_success_rec             NUMBER                                     := 0;
      ln_total_rec               NUMBER                                     := 0;
      ln_error_rec               NUMBER                                     := 0;
      ln_currency_cnt            NUMBER                                     := 0;
      ln_retcode                 NUMBER;
      --ln_diff_amount            NUMBER;
      --ln_net_amount             NUMBER;
      ln_err_msg_count           NUMBER;
      ln_group_id                NUMBER;
      ln_charge_amt              NUMBER;
      ln_charge_total            NUMBER;
      ln_ar_recv_ccid            NUMBER;
      lc_ar_recv_acct            gl_code_combinations_kfv.concatenated_segments%TYPE;
      --ln_card_type_ccid         NUMBER;
      --lc_card_type_acct         gl_code_combinations_kfv.concatenated_segments%TYPE;
      ln_bank_clearing_ccid      NUMBER;
      lc_bank_clearing_acct      gl_code_combinations_kfv.concatenated_segments%TYPE;
      ln_charge_ccid             NUMBER;
      lc_charge_acct             gl_code_combinations_kfv.concatenated_segments%TYPE;
      ln_entered_dr_amount       NUMBER;
      ln_entered_cr_amount       NUMBER;
      ln_mail_request_id         NUMBER;
      lc_mail_address            VARCHAR2 (1000);  -- Added for the Defect 6138
      lc_errored_store           VARCHAR2 (10000); -- Added for the Defect 6138
      lc_err_store_num           VARCHAR2 (10000); -- Added for the Defect 6138
      lc_count_flag              VARCHAR2 (1);    -- Added for the Defect 6138
      lc_user_source_name        VARCHAR2 (50)          := 'OD CM Credit Settle';
      ln_application_id          fnd_application.application_id%TYPE;
      lc_period_name             gl_period_statuses.period_name%TYPE;
      ex_main_exception          EXCEPTION;
      lc_recon_batch_savepoint   VARCHAR2 (100);
      ex_recon_batch_exception   EXCEPTION;
      ex_store_fee_exception     EXCEPTION;
      lc_store_fees_savepoint    VARCHAR2 (100);
      lc_je_line_desc            gl_je_lines.description%TYPE;
      lc_orig_store_num          xx_ce_ajb999.store_num%TYPE;
      lc_message                 VARCHAR2 (100);
      lc_orig_card_type          xx_ce_ajb999.cardtype%TYPE;
      --Added for Release 1.1 CR 601 Defect 1419
      lc_translation_type        CONSTANT VARCHAR(200):= 'XX_CM_1310_CLEARING_ACCNT';
      lc_org_name                hr_all_organization_units.name%TYPE;
      lc_ccid_company            xx_fin_translatevalues.target_value1%TYPE;
      lc_ccid_location           xx_fin_translatevalues.target_value2%TYPE;
      lc_ccid_intercompany       xx_fin_translatevalues.target_value3%TYPE;
      lc_ccid_future             xx_fin_translatevalues.target_value4%TYPE;
      lc_ccid_lob                xx_fin_translatevalues.target_value5%TYPE;
      lc_ccid_costcenter         xx_fin_translatevalues.target_value6%TYPE;
      --End of changes for Release 1.1 CR 601 Defect 1419
      TYPE ret_fee_amt_type IS REF CURSOR;
      lc_ret_fee_amt_cur         ret_fee_amt_type;
      ld_from_date               DATE;
      ld_to_date                 DATE;
   BEGIN
      IF p_from_date IS NOT NULL
      THEN
         ld_from_date := TRUNC (fnd_conc_date.string_to_date (p_from_date));
      END IF;
      IF p_to_date IS NOT NULL
      THEN
         ld_to_date := TRUNC (fnd_conc_date.string_to_date (p_to_date));
      END IF;
      od_message ('M', ' ');
      od_message
         ('M'
        , '  ----------------------    Start Recon Process     ------------------------'
         );
      od_message ('M', ' ');
      od_message ('M'
                ,    'Parameters - Provider:'
                  || NVL (p_provider_code, 'ALL')
                  || '   From:'
                  || NVL (TO_CHAR (ld_from_date), 'Not Specified')
                  || '    Through:'
                  || NVL (TO_CHAR (ld_to_date), 'Not Specified.')
                 );
      od_message ('M', ' ');
-- -------------------------------------------
-- Initializing Local Variables
-- -------------------------------------------
      lc_error_location := 'Initializing Local Variables';
      lc_source_err_flag := 'N';
      lc_trx_valid_flag := 'N';
      lc_error_details := NULL;
      lc_errmsg := NULL;
      lc_output_msg := NULL;
      lc_err_msg := NULL;
      --lc_provider_code := NULL;
      ln_retcode := 0;
      ln_currency_cnt := 0;
      ln_err_msg_count := 0;
      --ln_group_id := 0;
      g_print_line := g_print_line || '-';
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
-- -------------------------------------------
-- Get the Chart of Account Id.
-- -------------------------------------------
      IF gn_set_of_bks_id IS NOT NULL
      THEN
         OPEN lcu_get_coaid;
         FETCH lcu_get_coaid
          INTO gn_coa_id, gc_currency_code;
         CLOSE lcu_get_coaid;
         IF gn_coa_id IS NULL
         THEN
            lc_source_err_flag := 'Y';
            fnd_message.set_name ('XXFIN', 'XX_CE_003_COA_NOT_SETUP');
            lc_error_details := lc_error_details || '-' || fnd_message.get;
         END IF;
      END IF;
      od_message ('M', 'Chart of Accounts ID:' || gn_coa_id);
-- -------------------------------------------
-- Get the Delimiter.
-- -------------------------------------------
      gc_delimiter :=
         fnd_flex_ext.get_delimiter (application_short_name => 'SQLGL'
                                   , key_flex_code => 'GL#'
                                   , structure_number => gn_coa_id
                                    );
-- -------------------------------------------
-- Call the Print Message Header
-- -------------------------------------------
      print_message_header (x_errbuf => lc_errmsg, x_retcode => ln_retcode);
      lc_error_location := 'Start.';
-- -------------------------------------------
-- Get all the Matched Recon batches with un-processed fees.
-- -------------------------------------------
      ln_success_rec := 0;
      ln_error_rec := 0;
-- --------------------------------------------
--  Get all Unreconciled Batches
-- --------------------------------------------
      FOR intf_batches_rec IN lcu_get_intf_batches (p_provider_code
                                                  , ld_from_date
                                                  , ld_to_date
                                                   )
      LOOP

         OPEN lcu_get_recon_batches (intf_batches_rec.processor_id
                                   , intf_batches_rec.bank_rec_id
                                    );
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
                  od_message ('M', 'Group ID:' || ln_group_id);
               END IF;
-- -------------------------------------------
-- Loop through all the statement records
-- for the from and to date range
-- -------------------------------------------
               lc_error_location := 'Recon Batches before savepoint';
               lc_recon_batch_savepoint :=
                     recon_batches_rec.processor_id
                  || '-'
                  || recon_batches_rec.card_type
                  || '-'
                  || recon_batches_rec.bank_rec_id
                  || '-'
                  || recon_batches_rec.store_num;
               SAVEPOINT lc_recon_batch_savepoint;
               lc_error_details := NULL;
               lc_error_flag := 'N';
               lc_source_err_flag := 'N';
               lc_trx_valid_flag := 'N';
               lc_period_name := NULL;
               lc_output_msg := NULL;
               ln_currency_cnt := 0;
               --ln_diff_amount := 0;
               --lc_provider_code := NULL;
               lc_sql := NULL;
               lc_company := NULL;
               lc_ar_recv_lob := NULL;
               --lc_card_type_lob := NULL;
               lc_bank_clearing_lob := NULL;
               lc_charge_lob := NULL;
               ln_ar_recv_ccid := NULL;
               --ln_card_type_ccid := NULL;
               ln_bank_clearing_ccid := NULL;
               ln_charge_ccid := NULL;
               -- ln_net_amount := 0;
               ln_charge_total := 0;
               --

               ln_total_rec := ln_total_rec + 1;
               --
                FND_FILE.PUT_LINE(FND_FILE.LOG,'TOTAL RECORD IS ' ||ln_total_rec);
               lc_message := NULL;
               od_message ('M', ' ');
               od_message ('M', g_print_line);
               od_message ('M', ' ');
               od_message ('M'
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
               lc_message := NULL;
               lc_orig_card_type := recon_batches_rec.card_type;
               IF recon_batches_rec.card_type IS NULL
               THEN
                  recon_batches_rec.card_type :=
                         get_default_card_type (recon_batches_rec.processor_id
                                               ,gn_org_id   --Added for Defect #1061
                                               );
                  lc_message :=
                        'Default Card Type to '
                     || recon_batches_rec.card_type
                     || '. ';
                  od_message ('M'
                            ,    'No Card type - Defaulting to '
                              || recon_batches_rec.card_type
                             );
               END IF;
               IF recon_batches_rec.card_type IS NULL
               THEN
                  od_message ('M', 'Cannot default Card Type for Provider!');
                  lc_error_flag := 'Y';
                  RAISE ex_recon_batch_exception;
               END IF;
               lc_orig_store_num := recon_batches_rec.store_num;
               --Defect 8802 - If Store comes in as '000000' then use '001099'.
               IF recon_batches_rec.store_num = '000000'
                  OR recon_batches_rec.store_num IS NULL
               THEN
                  recon_batches_rec.store_num := '001099';
               END IF;
               IF NVL (lc_orig_store_num, '0') != recon_batches_rec.store_num
               THEN
                  IF lc_message IS NOT NULL
                  THEN
                     lc_message := lc_message || '. ';
                  END IF;
                  lc_message :=
                           lc_message || 'Used Location 001099 for Accounting. ';
                  od_message ('M', '* * ' || lc_message);
               END IF;
               IF lcu_get_recon_hdr%ISOPEN
               THEN
                  CLOSE lcu_get_recon_hdr;
               END IF;
               recon_hdr_rec := NULL;
               -- Defect 9402
               BEGIN
                  OPEN lcu_get_recon_hdr
                               (p_processor => recon_batches_rec.processor_id
                              , p_card_type => recon_batches_rec.card_type
                              , p_process_date => recon_batches_rec.recon_date
                              , p_store_num => lc_orig_store_num
                               --recon_batches_rec.store_num
                               );
                  FETCH lcu_get_recon_hdr
                   INTO recon_hdr_rec;
                                  CLOSE lcu_get_recon_hdr;
                  IF recon_hdr_rec.header_id IS NULL
                  THEN
                     od_message ('M'
                               ,    'Invalid Card Type for Provider! '
                                 || recon_batches_rec.card_type
                                );
                     lc_error_flag := 'Y';
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
                     od_message
                           ('M'
                          ,    'Other Error Validating Card Type for Provider! '
                            || recon_batches_rec.card_type
                           );
                     lc_error_flag := 'Y';
                     RAISE ex_recon_batch_exception;
               END;
               recon_hdr_rec := NULL;
               lc_error_location :=
                     'Error:Derive Company from location-Store '
                  || recon_batches_rec.store_num;
               lc_company :=
                  xx_gl_translate_utl_pkg.derive_company_from_location
                                     (p_location => recon_batches_rec.store_num
                                    , p_org_id => gn_org_id       -- Defect 9365
                                     );
               IF lc_company IS NULL
               THEN
                  fnd_message.set_name ('XXFIN', 'XX_CE_020_COMPANY_NOT_SETUP');
                  lc_error_details :=
                        'Error:' || lc_error_location || '-' || fnd_message.get;
                  od_message ('M'
                            , 'Error:Cannot derive Company from Location!');
                  lc_error_flag := 'Y';
                  RAISE ex_recon_batch_exception;
               END IF;
               lc_error_location :=
                     'Get Recon Header Details ('
                  || recon_batches_rec.processor_id
                  || '/'
                  || recon_batches_rec.card_type
                  || '/'
                  || recon_batches_rec.recon_date
                  || '/'
                  || recon_batches_rec.store_num
                  || ')';
               lc_error_details := NULL;
               lc_error_flag := 'N';
-- -------------------------------------------
--  Get the Fee Columns and Accounting.
-- -------------------------------------------
               FOR recon_hdr_rec IN
                  lcu_get_recon_hdr
                                (p_processor => recon_batches_rec.processor_id
                               , p_card_type => recon_batches_rec.card_type
                               , p_process_date => recon_batches_rec.recon_date
                               , p_store_num => lc_orig_store_num
                                --recon_batches_rec.store_num
                                )
               LOOP

                  BEGIN
                     ln_ar_recv_ccid := NULL;
                     --ln_card_type_ccid := NULL;
                     ln_bank_clearing_ccid := NULL;
                     lc_ar_recv_lob := NULL;
                     --lc_card_type_lob := NULL;
                     lc_bank_clearing_lob := NULL;
                     ln_entered_dr_amount := NULL;
                     ln_entered_cr_amount := NULL;
                     -- Defect 5700 - If we get Multiple 999 Lines for same
                     -- provider/store/card type - Reset the Charge Total Amount
                     -- so that GL entries balance (Cr. Total charges is correct).
                     ln_charge_total := 0;
                     lc_error_location :=
                           'Get Recon Store Fees for Card Type:'
                        || recon_hdr_rec.ajb_card_type;
--**************************************************************
-- Process Store Fees for each Processor/Card Type in Batch.
--**************************************************************
-- Use the original store number sent from AJB when getting the
-- 999 file fee data.
                     od_message ('M'
                               ,    'Process fees for Card Type:'
                                 || recon_hdr_rec.ajb_card_type
                                );
                     FOR store_fee_rec IN
                        lcu_get_store_fees
                                (recon_batches_rec.bank_rec_id
                               , recon_batches_rec.processor_id
                               , recon_hdr_rec.ajb_card_type
                               , lc_orig_store_num --recon_batches_rec.store_num
                               , recon_batches_rec.currency
                                )
                     LOOP
                        BEGIN

-- -------------------------------------------
-- Get Fee Details and Accounting.
-- -------------------------------------------
-- Use '001099' when getting accounting info for 'store 000000'.
                           FOR recon_dtl_rec IN
                              lcu_get_recon_dtl
                                    (p_header_id => recon_hdr_rec.header_id
                                   , p_process_date => TRUNC (SYSDATE)
                                   , p_store_num => recon_batches_rec.store_num
                                    )
                           LOOP

                              lc_error_location :=
                                    'Getting Store Fee Column Details for store '
                                 || recon_batches_rec.store_num
                                 || ' Header ID:'
                                 || recon_hdr_rec.header_id;
                              ln_charge_ccid := NULL;
                              lc_charge_lob := NULL;
                              ln_charge_amt := NULL;
-- ------------------------------------------------------
-- Dynamic Sql to get the 999 store fee column value
-- eg. if charge_code value from xx_ce_recon_glact_dtl
-- maps to DISCOUNT_AMT field on the 999 file, the query
-- below retrieves the value in the DISCOUNT_AMT field.
-- ------------------------------------------------------
                              lc_sql :=
                                    'SELECT '
                                 || recon_dtl_rec.charge_code
                                 || ' FROM  xx_ce_ajb999_v
                             WHERE sequence_id_999 = :v_sequence_id';
                              BEGIN
                                 OPEN lc_ret_fee_amt_cur FOR lc_sql
                                 USING store_fee_rec.sequence_id_999;
                                 FETCH lc_ret_fee_amt_cur
                                  INTO ln_charge_amt;

                                 CLOSE lc_ret_fee_amt_cur;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    lc_error_flag := 'Y';
                                    lc_error_details :=
                                          'Other error geting charge code: '
                                       || SQLCODE
                                       || ':'
                                       || SQLERRM;
                                    od_message ('M', lc_error_details);
                                    RAISE ex_recon_batch_exception;
                              END;
                              --od_message('M', 'Charge Amt:' || ln_charge_amt);
                              IF NVL (ln_charge_amt, 0) != 0
                              THEN
-- -------------------------------------------
-- Derive Charge CCID.
-- -------------------------------------------
                                 lc_error_location :=
                                    'Error:Derive Charge LOB from location and costcenter ';
                                 xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc
                                    (p_location => recon_batches_rec.store_num
                                   , p_cost_center => recon_dtl_rec.charge_costcenter
                                   , x_lob => lc_charge_lob
                                   , x_error_message => lc_errmsg
                                    );
                                 IF lc_charge_lob IS NULL
                                 THEN
                                    fnd_message.set_name
                                                     ('XXFIN'
                                                    , 'XX_CE_021_LOB_NOT_SETUP'
                                                     );
                                    lc_error_details :=
                                          'Error deriving Charge LOB for location '
                                       || recon_batches_rec.store_num
                                       || ' Cost Center '
                                       || recon_dtl_rec.charge_costcenter
                                       || '/'
                                       || lc_error_details
                                       || '-'
                                       || lc_errmsg
                                       || fnd_message.get;
                                    od_message ('M', lc_error_details);
                                    lc_error_flag := 'Y';
                                    RAISE ex_recon_batch_exception;
                                 END IF;                         --lc_charge_lob
                                 lc_charge_acct :=
                                       lc_company
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
                                 lc_error_location :=
                                       'Processing Fee '
                                    || recon_dtl_rec.charge_description
                                    || ': Get CCID for '
                                    || lc_charge_acct;
                                 --od_message('M', lc_error_location);
                                 ln_charge_ccid :=
                                    fnd_flex_ext.get_ccid
                                        (application_short_name => 'SQLGL'
                                       , key_flex_code => 'GL#'
                                       , structure_number => gn_coa_id
                                       , validation_date => SYSDATE
                                       , concatenated_segments => lc_charge_acct
                                        );
                                 IF ln_charge_ccid = 0
                                 THEN
                                    fnd_message.set_name
                                                    ('XXFIN'
                                                   , 'XX_CE_023_CCID_NOT_SETUP'
                                                    );
                                    lc_error_details :=
                                          lc_error_details
                                       || 'Error deriving Charge Debit Account CCID for '
                                       || lc_charge_acct
                                       || '-'
                                       || fnd_message.get;
                                    lc_error_flag := 'Y';
                                    od_message ('M', lc_error_details);
                                    RAISE ex_recon_batch_exception;
                                 END IF;                        --ln_charge_ccid
-- -------------------------------------------
-- Create Journal Entries for Fee Expense.
-- -------------------------------------------
                                 lc_error_location :=
                                      'Create JE for Fee detail for Recon batch';
                                 lc_je_line_desc :=
                                       'Fee: Provider:'
                                    || store_fee_rec.processor_id
                                    || ' Card Type:'
                                    || lc_orig_card_type
                                    --store_fee_rec.cardtype
                                    || ' Store '
                                    || recon_batches_rec.store_num
                                    || ' in AJB Recon Batch '
                                    || store_fee_rec.bank_rec_id
                                    || ' Fee:'
                                    || recon_dtl_rec.charge_description;
                                 IF ln_charge_amt < 0
                                 THEN
                                    ln_entered_dr_amount := 0;
                                    ln_entered_cr_amount := ABS (ln_charge_amt);
                                    od_message
                                       ('M'
                                      ,    RPAD
                                              (   'DR '
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
                                    ln_entered_dr_amount := ABS (ln_charge_amt);
                                    ln_entered_cr_amount := 0;
                                    od_message
                                       ('M'
                                      ,    RPAD
                                              (   'DR '
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
                                 xx_gl_interface_pkg.create_stg_jrnl_line
                                     (p_status => 'NEW'
                                    , p_date_created => TRUNC (SYSDATE)
                                    , p_created_by => gn_user_id
                                    , p_actual_flag => 'A'
                                    , p_group_id => ln_group_id
                                    , p_je_reference => ln_group_id
                                    , p_batch_name => TO_CHAR (SYSDATE
                                                             , 'YYYY/MM/DD'
                                                              )
                                    , p_batch_desc => NULL
                                    , p_user_source_name => lc_user_source_name
                                    , p_user_catgory_name => 'Miscellaneous'
                                    , p_set_of_books_id => gn_set_of_bks_id
                                    , p_accounting_date => TRUNC (SYSDATE)
                                    , p_currency_code => store_fee_rec.currency
                                    , p_company => NULL
                                    , p_cost_center => NULL
                                    , p_account => NULL
                                    , p_location => NULL
                                    , p_intercompany => NULL
                                    , p_channel => NULL
                                    , p_future => NULL
                                    , p_ccid => ln_charge_ccid
                                    , p_entered_dr => ln_entered_dr_amount
                                    , p_entered_cr => ln_entered_cr_amount
                                    , p_je_line_dsc => lc_je_line_desc
                                    , x_output_msg => lc_output_msg
                                     );
-- -------------------------------------------
-- Calling the Exception
-- If insertion Failed into XX_GL_INTERFACE_NA_STG.
-- -------------------------------------------
                                 IF lc_output_msg IS NOT NULL
                                 THEN
                                    lc_error_details :=
                                          'Error creating Journal line:'
                                       || lc_error_details
                                       || lc_output_msg;
                                    lc_error_flag := 'Y';
                                    od_message ('M', lc_error_details);
                                    RAISE ex_recon_batch_exception;
                                 END IF;
---------------------------------------------------
--  Add Fee Charges to Fee total.
---------------------------------------------------
                                 ln_charge_total :=
                                      NVL (ln_charge_total, 0)
                                    + NVL (ln_charge_amt, 0);
                              --od_message('M'
                              --        , 'Charge Running Total:'
                              --           || ln_charge_total
                              --          );
                              ELSE                          --ln_charge_amt = 0;
                                 od_message
                                           ('M'
                                          ,    'No '
                                            || recon_dtl_rec.charge_description
                                            || ' amount in batch (Seq:'
                                            || store_fee_rec.sequence_id_999
                                            || ')'
                                           );
                              END IF;
                           END LOOP;                         --lcu_get_recon_dtl
-- ------------------------------------------------
-- Update after the Processing the 999 fee record.
-- ------------------------------------------------
                           lc_error_location :=
                                 'Update Store Fee processed status for Seq:'
                              || store_fee_rec.sequence_id_999
                              || ' Amount:        '
                              || ln_charge_total;
                           --od_message('M', lc_error_location);

/* For setting the status of attribute1 to FEE_RECON_YES for processed records.Added for the Defect 6138 */

                           UPDATE xx_ce_ajb999 xca9
                           SET xca9.status_1310 = DECODE (lc_error_flag
                                                  --,'Y','ERRORED'--Defect100
                                                        , 'Y', 'ERROR'
                                                        , 'N', 'PROCESSED'
                                                        , xca9.status_1310
                                                         )
                              ,xca9.attribute1   = DECODE (lc_error_flag  ----Added for the Defect 6138.
                                                  --,'Y','ERRORED'--Defect100
                                                        ,'Y', 'FEE_RECON_NO'
                                                        ,'N', 'FEE_RECON_YES'
                                                        ,xca9.attribute1
                                                          )
                            WHERE xca9.sequence_id_999 = store_fee_rec.sequence_id_999
                            AND xca9.store_num = lc_orig_store_num
                              --recon_batches_rec.store_num
                            AND xca9.processor_id = store_fee_rec.processor_id
                            AND xca9.cardtype = lc_orig_card_type;

                           EXCEPTION
                           WHEN OTHERS
                           THEN
                              lc_error_flag := 'Y';
                              lc_error_details :=
                                    'Other error processing store fees. '
                                 || lc_error_details
                                 || '-'
                                 || SQLCODE
                                 || ':'
                                 || SQLERRM;
                              od_message ('M', lc_error_details);
                              RAISE ex_recon_batch_exception;
                        END;
                     END LOOP;                                    -- Store Fees.
--***************************************************************
                     -- -----------------------------------------------
--  Derive the Credit AR Receivable Account CCID.
-- -----------------------------------------------
                     lc_error_location :=
                           'Error:Derive AR Receivable LOB from location ('
                        || recon_batches_rec.store_num
                        || ') and costcenter ('
                        || recon_hdr_rec.ar_recv_costcenter
                        || ').';
                     xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc
                             (p_location => recon_batches_rec.store_num
                            , p_cost_center => recon_hdr_rec.ar_recv_costcenter
                            , x_lob => lc_ar_recv_lob
                            , x_error_message => lc_errmsg
                             );
                     IF lc_ar_recv_lob IS NULL
                     THEN
                        fnd_message.set_name ('XXFIN'
                                            , 'XX_CE_021_LOB_NOT_SETUP'
                                             );
                        lc_error_details :=
                              'Error Getting AR Receivable LOB for location '
                           || recon_batches_rec.store_num
                           || ' Cost Center '
                           || recon_hdr_rec.ar_recv_costcenter
                           || lc_error_details
                           || '/'
                           || lc_errmsg
                           || '-'
                           || fnd_message.get;
                        lc_error_flag := 'Y';
                        od_message ('M', lc_error_details);
                        RAISE ex_recon_batch_exception;
                     END IF;                                   -- lc_ar_recv_lob
                     lc_ar_recv_acct :=
                           lc_company
                        || gc_delimiter
                        || recon_hdr_rec.ar_recv_costcenter
                        || gc_delimiter
                        || recon_hdr_rec.ar_recv_account
                        || gc_delimiter
                        || recon_batches_rec.store_num
                        || gc_delimiter
                        || lc_intercompany
                        || gc_delimiter
                        || lc_ar_recv_lob
                        || gc_delimiter
                        || lc_future;
                     lc_error_location :=
                                'Get AR Receivable CCID for ' || lc_ar_recv_acct;
                     ln_ar_recv_ccid :=
                        fnd_flex_ext.get_ccid
                                       (application_short_name => 'SQLGL'
                                      , key_flex_code => 'GL#'
                                      , structure_number => gn_coa_id
                                      , validation_date => SYSDATE
                                      , concatenated_segments => lc_ar_recv_acct
                                       );
                     IF ln_ar_recv_ccid = 0
                     THEN
                        fnd_message.set_name ('XXFIN'
                                            , 'XX_CE_023_CCID_NOT_SETUP'
                                             );
                        lc_error_details :=
                              'Error Deriving AR Receivable Account CCID for '
                           || lc_ar_recv_acct
                           || '-'
                           || lc_error_details
                           || '-'
                           || fnd_message.get;
                        lc_error_flag := 'Y';
                        od_message ('M', lc_error_details);
                        RAISE ex_recon_batch_exception;
                     END IF;                                  --ln_ar_recv_ccid.
/* -- Defect 8940
-- -------------------------------------------
-- Derive Card Type Receivable CCID
-- -------------------------------------------
lc_error_location :=
   'Derive the Card Type LOB from location ('
   || recon_batches_rec.store_num
   || ') and costcenter ('
   || recon_hdr_rec.card_type_costcenter
   || ').';
xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc
         (p_location           => recon_batches_rec.store_num
        , p_cost_center        => recon_hdr_rec.card_type_costcenter
        , x_lob                => lc_card_type_lob
        , x_error_message      => lc_errmsg
         );
IF lc_card_type_lob IS NULL
THEN
   fnd_message.set_name('XXFIN', 'XX_CE_021_LOB_NOT_SETUP');
   lc_error_details :=
      'Error Getting Card Type LOB for location '
      || recon_batches_rec.store_num
      || ' Cost Center '
      || recon_hdr_rec.card_type_costcenter
      || lc_error_details
      || '/'
      || lc_errmsg
      || '-'
      || fnd_message.get;
   od_message('M', lc_error_details);
   lc_error_flag := 'Y';
   RAISE ex_recon_batch_exception;
END IF;                                     --lc_card_type_lob
lc_card_type_acct := lc_company
                     || gc_delimiter
                     || recon_hdr_rec.card_type_costcenter
                     || gc_delimiter
                     || recon_hdr_rec.card_type_account
                     || gc_delimiter
                     || recon_batches_rec.store_num
                     || gc_delimiter
                     || lc_intercompany
                     || gc_delimiter
                     || lc_card_type_lob
                     || gc_delimiter
                     || lc_future;
lc_error_location := 'Get Card Type Receivable CCID for '
                     || lc_card_type_acct;
--od_message('M', lc_error_location);
ln_card_type_ccid :=
   fnd_flex_ext.get_ccid
                   (application_short_name      => 'SQLGL'
                  , key_flex_code               => 'GL#'
                  , structure_number            => gn_coa_id
                  , validation_date             => SYSDATE
                  , concatenated_segments       => lc_card_type_acct
                   );
IF ln_card_type_ccid = 0
THEN
   fnd_message.set_name('XXFIN', 'XX_CE_023_CCID_NOT_SETUP');
   lc_error_details := 'Error Getting Card Type CCID for '
                       || lc_card_type_acct
                       || '/'
                       || lc_error_details
                       || '-'
                       || fnd_message.get;
   lc_error_flag := 'Y';
   od_message('M', lc_error_details);
   RAISE ex_recon_batch_exception;
END IF;                                    --ln_card_type_ccid
*/ -- Defect 8940
-- -------------------------------------------
-- Derive Bank Cash Clearing CCID
-- -------------------------------------------
          --Added for Release 1.1 CR 601  Defect 1362
           SELECT SUBSTR(name,4,2)
             INTO lc_org_name
               FROM hr_all_organization_units
                 WHERE organization_id=gn_org_id;
           IF lc_org_name='CA'
                 THEN
          -- End of change for  Release 1.1 CR 601  Defect 1362
           FND_FILE.PUT_LINE(FND_FILE.LOG,'CCID value has not defined properly');
                    lc_error_location :=
                           'Error:Derive Bank Cash Clearing LOB from location('
                        || recon_hdr_rec.bank_clearing_location
                        || ') and costcenter('
                        || recon_hdr_rec.bank_clearing_costcenter
                        || ').';
                      xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc
                        (p_location => recon_hdr_rec.bank_clearing_location
                       , p_cost_center => recon_hdr_rec.bank_clearing_costcenter
                       , x_lob => lc_bank_clearing_lob
                       , x_error_message => lc_errmsg
                        );
                     IF lc_bank_clearing_lob IS NULL
                     THEN
                        fnd_message.set_name ('XXFIN'
                                            , 'XX_CE_021_LOB_NOT_SETUP'
                                             );
                        lc_error_details :=
                              'Error Getting bank clearing  for location '
                           || recon_hdr_rec.bank_clearing_location
                           || ' Cost Center '
                           || recon_hdr_rec.bank_clearing_costcenter
                           || lc_error_details
                           || '/'
                           || lc_errmsg
                           || '-'
                           || fnd_message.get;
                        od_message ('M', lc_error_details);
                        lc_error_flag := 'Y';
                        RAISE ex_recon_batch_exception;
                     END IF;                              --lc_bank_clearing_lob*
                    lc_bank_clearing_acct :=
                           lc_company
                        || gc_delimiter
                        || recon_hdr_rec.bank_clearing_costcenter
                        || gc_delimiter
                        || recon_hdr_rec.bank_clearing_account
                        || gc_delimiter
                        || recon_hdr_rec.bank_clearing_location
                        || gc_delimiter
                        || lc_intercompany
                        || gc_delimiter
                        || lc_bank_clearing_lob
                        || gc_delimiter          ---Added by Raghu for CR601/defect 2930
                        || lc_future;
                     lc_error_location :=
                          'Get Bank Clearing CCID for CA ' || lc_bank_clearing_acct;
                     --od_message('M', lc_error_location);
                     ln_bank_clearing_ccid :=
                        fnd_flex_ext.get_ccid
                                 (application_short_name => 'SQLGL'
                                , key_flex_code => 'GL#'
                                , structure_number => gn_coa_id
                                , validation_date => SYSDATE
                                , concatenated_segments => lc_bank_clearing_acct
                                 );
                     IF ln_bank_clearing_ccid = 0
                     THEN
                        lc_error_flag := 'Y';
                        fnd_message.set_name ('XXFIN'
                                            , 'XX_CE_023_CCID_NOT_SETUP'
                                             );
                        lc_error_details :=
                              'Error Getting bank clearing CCID for '
                           || lc_bank_clearing_acct
                           || '/'
                           || lc_error_details
                           || '-'
                           || fnd_message.get;
                        od_message ('M', lc_error_details);
                        RAISE ex_recon_batch_exception;
                     END IF;                             --ln_bank_clearing_ccid for CA
          --Added the following for Release 1.1 CR 601  Defect 1362
       ELSE
              BEGIN
              SELECT XFTV.target_value1,XFTV.target_value2
                    ,XFTV.target_value3,XFTV.target_value4
                    ,XFTV.target_value5,XFTV.target_value6
              INTO lc_ccid_company,lc_ccid_costcenter
                    ,lc_ccid_location,lc_ccid_intercompany
                    ,lc_ccid_lob,lc_ccid_future
              FROM xx_fin_translatedefinition  XFTD
                   ,xx_fin_translatevalues XFTV
              WHERE XFTV.translate_id = XFTD.translate_id
               AND   substr(source_value1,4,2)=lc_org_name
                AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                 AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                  AND XFTD.translation_name = lc_translation_type
                   AND XFTV.enabled_flag = 'Y'
                    AND XFTD.enabled_flag = 'Y';
         EXCEPTION
                WHEN NO_DATA_FOUND THEN
                     lc_ccid_company       :=NULL;
                     lc_ccid_costcenter    :=NULL;
                     lc_ccid_location      :=NULL;
                     lc_ccid_intercompany  :=NULL;
                     lc_ccid_lob           :=NULL;
                     lc_ccid_future        :=NULL;
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'CCID value has not defined properly');
                RAISE;
                WHEN OTHERS THEN
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to retrieve CCID Details from Translation');
                RAISE;
         END;
           IF (lc_ccid_company IS NULL
                OR lc_ccid_costcenter IS NULL
                 OR lc_ccid_location IS NULL
                  OR lc_ccid_intercompany IS NULL
                   OR lc_ccid_lob IS NULL
                    OR lc_ccid_future IS NULL)  THEN
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'CCID value IS INVALID');
           ELSE
               lc_bank_clearing_acct :=
                                        lc_ccid_company
                                        || gc_delimiter
                                        || lc_ccid_costcenter
                                        || gc_delimiter
                                        || recon_hdr_rec.bank_clearing_account
                                        || gc_delimiter
                                        || lc_ccid_location
                                        || gc_delimiter
                                        || lc_ccid_intercompany
                                        || gc_delimiter
                                        || lc_ccid_lob
                                        || gc_delimiter
                                        || lc_ccid_future;
               lc_error_location :='Get Bank Clearing CCID for ' || lc_bank_clearing_acct;
               ln_bank_clearing_ccid :=
                                  fnd_flex_ext.get_ccid
                                 (application_short_name => 'SQLGL'
                                , key_flex_code => 'GL#'
                                , structure_number => gn_coa_id
                                , validation_date => SYSDATE
                                , concatenated_segments => lc_bank_clearing_acct
                                 );
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'BANK CASH CLEARING CCID IS '|| ln_bank_clearing_ccid);
              IF ln_bank_clearing_ccid = 0
              THEN
              lc_error_flag := 'Y';
                   FND_MESSAGE.SET_NAME ('XXFIN'
                                        , 'XX_CE_023_CCID_NOT_SETUP'
                                         );
                 lc_error_details :=
                              'Error Getting bank clearing CCID for '
                           || lc_bank_clearing_acct
                           || '/'
                           || lc_error_details
                           || '-'
                           || FND_MESSAGE.GET;
                        od_message ('M', lc_error_details);
                        RAISE ex_recon_batch_exception;
              END IF;                             --ln_bank_clearing_ccid for US
           END IF;
       END IF;
        --- End of Changes for CR 601 for R1.1 Defect 1362
-- -------------------------------------------
-- Create offset Journal Entries for Fee Expense Total to AR Receivable Account.
-- -------------------------------------------
                     IF NVL (ln_charge_total, 0) != 0
                     THEN
                        lc_error_location :=
                           'CREDIT AR Receivable Journal Entries for each provider and store';
                        lc_je_line_desc :=
                              'AR CC Recv:Fee total for '
                           || recon_batches_rec.processor_id
                           || ' / Card Type:'
                           || recon_hdr_rec.ajb_card_type
                           || ' / Store '
                           || recon_batches_rec.store_num
                           || ' / Recon Batch '
                           || recon_batches_rec.bank_rec_id;
                        IF ln_charge_total < 0
                        THEN
                           ln_entered_dr_amount := ABS (ln_charge_total);
                           ln_entered_cr_amount := 0;
                           od_message
                              ('M'
                             ,    RPAD
                                     (   'CR Fee Total to AR CC Receivable Bank:'
                                      || recon_batches_rec.currency
                                      || ' '
                                      || ln_charge_total
                                    , 50
                                    , ' '
                                     )
                               || ' '
                               || RPAD (lc_ar_recv_acct, 45, ' ')
                               || LPAD (ABS (ln_charge_total), 12, ' ')
                              );
                        ELSE
                           ln_entered_dr_amount := 0;
                           ln_entered_cr_amount := ABS (ln_charge_total);
                           od_message
                              ('M'
                             ,    RPAD
                                     (   'CR Fee Total to AR CC Receivable Bank:'
                                      || recon_batches_rec.currency
                                      || ' '
                                      || ln_charge_total
                                    , 50
                                    , ' '
                                     )
                               || ' '
                               || RPAD (lc_ar_recv_acct, 45, ' ')
                               || LPAD (' ', 12, ' ')
                               || ' '
                               || LPAD (ABS (ln_charge_total), 12, ' ')
                              );
                        END IF;
                        xx_gl_interface_pkg.create_stg_jrnl_line
                                 (p_status => 'NEW'
                                , p_date_created => TRUNC (SYSDATE)
                                , p_created_by => gn_user_id
                                , p_actual_flag => 'A'
                                , p_group_id => ln_group_id
                                , p_je_reference => ln_group_id
                                , p_batch_name => TO_CHAR (SYSDATE
                                                         , 'YYYY/MM/DD') -- NULL
                                , p_batch_desc => NULL
                                , p_user_source_name => 'OD CM Credit Settle'
                                , p_user_catgory_name => 'Miscellaneous'
                                , p_set_of_books_id => gn_set_of_bks_id
                                , p_accounting_date => TRUNC (SYSDATE)
                                , p_currency_code => recon_batches_rec.currency
                                , p_company => NULL
                                , p_cost_center => NULL
                                , p_account => NULL
                                , p_location => NULL
                                , p_intercompany => NULL
                                , p_channel => NULL
                                , p_future => NULL
                                , p_ccid => ln_ar_recv_ccid
                                , p_entered_dr => ln_entered_dr_amount
                                , p_entered_cr => ln_entered_cr_amount
                                , p_je_line_dsc => lc_je_line_desc
                                , x_output_msg => lc_output_msg
                                 );
-- ------------------------------------------------
-- Calling the Exception
-- If insertion into XX_GL_INTERFACE_NA_STG failed.
-- ------------------------------------------------
                        IF lc_output_msg IS NOT NULL
                        THEN
                           lc_error_details :=
                                 'Error Creating JE for Fee Total to AR CC Receivable (Bank) Account '
                              || lc_ar_recv_acct
                              || '-'
                              || lc_error_details
                              || lc_output_msg;
                           lc_error_flag := 'Y';
                           od_message ('M', lc_error_details);
                           RAISE ex_recon_batch_exception;
                        END IF;
                     ELSE
                        od_message ('M', 'No Store fees to Process');
                     END IF;
 -- --------------------------------------------------------------------
 -- Create Debit Journal Entries for Net Amount to card type receivable.
 -- --------------------------------------------------------------------
--Defect 8940 -- Updated accounting.
                     IF NVL (recon_batches_rec.net_amount, 0) != 0
                     THEN
                        /* -- Defect 8940.
                        lc_error_location :=
                             'Create Card Type Receivable Journal Entries for Net Amount for each provider and store';
                          lc_je_line_desc :=
                             'Card Type Recv: Net (Deposit) Amount for '
                             || recon_batches_rec.processor_id
                             || ' / Card Type:'
                             || recon_hdr_rec.ajb_card_type
                             || ' / Store '
                             || recon_batches_rec.store_num
                             || ' / in Recon Batch '
                             || recon_batches_rec.bank_rec_id;
                          IF recon_batches_rec.net_amount < 0
                          THEN
                             ln_entered_dr_amount := 0;
                             ln_entered_cr_amount :=
                                                   ABS(recon_batches_rec.net_amount);
                             od_message
                                 ('M'
                                , RPAD('DR Net Amt to Card Type Receivable:'
                                       || recon_batches_rec.currency
                                       || ' '
                                       || recon_batches_rec.net_amount
                                     , 50
                                     , ' '
                                      )
                                  || ' '
                                  || RPAD(lc_card_type_acct, 45, ' ')
                                  || LPAD(' ', 12, ' ')
                                  || ' '
                                  || LPAD(ABS(recon_batches_rec.net_amount), 12, ' ')
                                 );
                          ELSE
                             ln_entered_dr_amount :=
                                                   ABS(recon_batches_rec.net_amount);
                             ln_entered_cr_amount := 0;
                             od_message
                                 ('M'
                                , RPAD('DR Net Amt to Card Type Receivable:'
                                       || recon_batches_rec.currency
                                       || ' '
                                       || recon_batches_rec.net_amount
                                     , 50
                                     , ' '
                                      )
                                  || ' '
                                  || RPAD(lc_card_type_acct, 45, ' ')
                                  || LPAD(ABS(recon_batches_rec.net_amount), 12, ' ')
                                 );
                          END IF;
                          xx_gl_interface_pkg.create_stg_jrnl_line
                                      (p_status                 => 'NEW'
                                     , p_date_created           => TRUNC(SYSDATE)
                                     , p_created_by             => gn_user_id
                                     , p_actual_flag            => 'A'
                                     , p_group_id               => ln_group_id
                                     , p_je_reference           => ln_group_id
                                     , p_batch_name             => TO_CHAR
                                                                        (SYSDATE
                                                                       , 'YYYY/MM/DD'
                                                                        )
                                     , p_batch_desc             => NULL
                                     , p_user_source_name       => 'OD CM Credit Settle'
                                     , p_user_catgory_name      => 'Miscellaneous'
                                     , p_set_of_books_id        => gn_set_of_bks_id
                                     , p_accounting_date        => TRUNC(SYSDATE)
                                     , p_currency_code          => recon_batches_rec.currency
                                     , p_company                => NULL
                                     , p_cost_center            => NULL
                                     , p_account                => NULL
                                     , p_location               => NULL
                                     , p_intercompany           => NULL
                                     , p_channel                => NULL
                                     , p_future                 => NULL
                                     , p_ccid                   => ln_card_type_ccid
                                     , p_entered_dr             => ln_entered_dr_amount
                                     , p_entered_cr             => ln_entered_cr_amount
                                     , p_je_line_dsc            => lc_je_line_desc
                                     , x_output_msg             => lc_output_msg
                                      );
                          -- -------------------------------------------
                          -- Calling the Exception
                          -- If insertion Faild into XX_GL_INTERFACE_NA_STG
                          -- -------------------------------------------
                          IF lc_output_msg IS NOT NULL
                          THEN
                             lc_error_details :=
                                'Error Creating JE for Net (Deposit) Amount to Card Type Receivable Account '
                                || lc_card_type_acct
                                || '-'
                                || lc_error_details
                                || lc_output_msg;
                             lc_error_flag := 'Y';
                             od_message('M', lc_error_details);
                             RAISE ex_recon_batch_exception;
                          END IF;
                          */ -- Defect 8940.
                        -- --------------------------------------------------------------------------
-- Create Debit Journal Entries for Net Amount to Bank cash clearing.
-- --------------------------------------------------------------------------
                        lc_error_location :=
                           'Debit Bank cash clearing Journal Entries for Net Amount for each provider and store';
                        lc_je_line_desc :=
                              'Bank Cash Clearing:Net (Deposit) Amount for '
                           || recon_batches_rec.processor_id
                           || ' / Card Type:'
                           || recon_hdr_rec.ajb_card_type
                           || ' / Store '
                           || recon_batches_rec.store_num
                           || ' in Recon Batch '
                           || recon_batches_rec.bank_rec_id;
                        IF recon_batches_rec.net_amount < 0
                        THEN
                           ln_entered_dr_amount := 0;
                           ln_entered_cr_amount :=
                                             ABS (recon_batches_rec.net_amount);
                           od_message
                               ('M'
                              ,    RPAD (   'DR Net Amt to Bank Cash Clearing:'
                                         || recon_batches_rec.currency
                                         || ' '
                                         || recon_batches_rec.net_amount
                                       , 50
                                       , ' '
                                        )
                                || ' '
                                || RPAD (lc_bank_clearing_acct, 45, ' ')
                                || LPAD (' ', 12, ' ')
                                || ' '
                                || LPAD (ABS (recon_batches_rec.net_amount)
                                       , 12
                                       , ' '
                                        )
                               );
                        ELSE
                           ln_entered_dr_amount :=
                                             ABS (recon_batches_rec.net_amount);
                           ln_entered_cr_amount := 0;
                           od_message
                               ('M'
                              ,    RPAD (   'DR Net Amt to Bank Cash Clearing:'
                                         || recon_batches_rec.currency
                                         || ' '
                                         || recon_batches_rec.net_amount
                                       , 50
                                       , ' '
                                        )
                                || ' '
                                || RPAD (lc_bank_clearing_acct, 45, ' ')
                                || LPAD (ABS (recon_batches_rec.net_amount)
                                       , 12
                                       , ' '
                                        )
                               );
                        END IF;
                        xx_gl_interface_pkg.create_stg_jrnl_line
                                 (p_status => 'NEW'
                                , p_date_created => TRUNC (SYSDATE)
                                , p_created_by => gn_user_id
                                , p_actual_flag => 'A'
                                , p_group_id => ln_group_id
                                , p_je_reference => ln_group_id
                                , p_batch_name => TO_CHAR (SYSDATE
                                                         , 'YYYY/MM/DD')
                                , p_batch_desc => NULL
                                , p_user_source_name => 'OD CM Credit Settle'
                                , p_user_catgory_name => 'Miscellaneous'
                                , p_set_of_books_id => gn_set_of_bks_id
                                , p_accounting_date => TRUNC (SYSDATE)
                                , p_currency_code => recon_batches_rec.currency
                                , p_company => NULL
                                , p_cost_center => NULL
                                , p_account => NULL
                                , p_location => NULL
                                , p_intercompany => NULL
                                , p_channel => NULL
                                , p_future => NULL
                                , p_ccid => ln_bank_clearing_ccid
                                , p_entered_dr => ln_entered_dr_amount
                                , p_entered_cr => ln_entered_cr_amount
                                , p_je_line_dsc => lc_je_line_desc
                                , x_output_msg => lc_output_msg
                                 );
-- -------------------------------------------------
-- Calling the Exception
-- If insertion into XX_GL_INTERFACE_NA_STG failed.
-- -------------------------------------------------
                        IF lc_output_msg IS NOT NULL
                        THEN
                           lc_error_details :=
                                 'Error Creating Debit JE for Net (Deposit) Amount to Bank cash clearing Account '
                              || lc_bank_clearing_acct
                              || '-'
                              || lc_error_details
                              || lc_output_msg;
                           lc_error_flag := 'Y';
                           od_message ('M', lc_error_details);
                           RAISE ex_recon_batch_exception;
                        END IF;
-- ---------------------------------------------------------------
-- Create Credit Journal Entries for Net Amount to AR Receivable.
-- ---------------------------------------------------------------
                        lc_error_location :=
                           'CREDIT: AR Receivable Journal Entries for Net Amount for each provider and store';
                        lc_je_line_desc :=
                              'AR CC Receivable:Net(Deposit) Amount for '
                           || recon_batches_rec.processor_id
                           || ' / Card Type:'
                           || recon_hdr_rec.ajb_card_type
                           || ' / Store '
                           || recon_batches_rec.store_num
                           || ' in Recon Batch '
                           || recon_batches_rec.bank_rec_id;
                        IF recon_batches_rec.net_amount < 0
                        THEN
                           ln_entered_dr_amount :=
                                             ABS (recon_batches_rec.net_amount);
                           ln_entered_cr_amount := 0;
                           od_message
                                ('M'
                               ,    RPAD (   'CR Net Amt to AR CC Receivable: '
                                          || recon_batches_rec.currency
                                          || ' '
                                          || recon_batches_rec.net_amount
                                        , 50
                                        , ' '
                                         )
                                 || ' '
                                 || RPAD (lc_ar_recv_acct, 45, ' ')
                                 || LPAD (ABS (recon_batches_rec.net_amount)
                                        , 12
                                        , ' '
                                         )
                                );
                        ELSE
                           ln_entered_dr_amount := 0;
                           ln_entered_cr_amount :=
                                             ABS (recon_batches_rec.net_amount);
                           od_message
                                 ('M'
                                ,    RPAD (   'CR Net Amt to AR CC Receivable:'
                                           || recon_batches_rec.currency
                                           || ' '
                                           || recon_batches_rec.net_amount
                                         , 50
                                         , ' '
                                          )
                                  || ' '
                                  || RPAD (lc_ar_recv_acct, 45, ' ')
                                  || LPAD (' ', 12, ' ')
                                  || ' '
                                  || LPAD (ABS (recon_batches_rec.net_amount)
                                         , 12
                                         , ' '
                                          )
                                 );
                        END IF;
                        xx_gl_interface_pkg.create_stg_jrnl_line
                                 (p_status => 'NEW'
                                , p_date_created => TRUNC (SYSDATE)
                                , p_created_by => gn_user_id
                                , p_actual_flag => 'A'
                                , p_group_id => ln_group_id
                                , p_je_reference => ln_group_id
                                , p_batch_name => TO_CHAR (SYSDATE
                                                         , 'YYYY/MM/DD')
                                , p_batch_desc => NULL
                                , p_user_source_name => 'OD CM Credit Settle'
                                , p_user_catgory_name => 'Miscellaneous'
                                , p_set_of_books_id => gn_set_of_bks_id
                                , p_accounting_date => TRUNC (SYSDATE)
                                , p_currency_code => recon_batches_rec.currency
                                , p_company => NULL
                                , p_cost_center => NULL
                                , p_account => NULL
                                , p_location => NULL
                                , p_intercompany => NULL
                                , p_channel => NULL
                                , p_future => NULL
                                , p_ccid => ln_ar_recv_ccid
                                , p_entered_dr => ln_entered_dr_amount
                                , p_entered_cr => ln_entered_cr_amount
                                , p_je_line_dsc => lc_je_line_desc
                                , x_output_msg => lc_output_msg
                                 );
-- ------------------------------------------------
-- Calling the Exception
-- If insertion into XX_GL_INTERFACE_NA_STG failed.
-- ------------------------------------------------
                        IF lc_output_msg IS NOT NULL
                        THEN
                           lc_error_details :=
                                 'Error creating offset JE for Net (Deposit) Amount to AR Receivable Account '
                              || lc_ar_recv_acct
                              || '-'
                              || lc_error_details
                              || lc_output_msg;
                           lc_error_flag := 'Y';
                           od_message ('M', lc_error_details);
                           RAISE ex_recon_batch_exception;
                        END IF;
                      /*
                      -- -----------------------------------------------------------------------------
                      -- Create Step 2 Credit Journal Entries for Net Amount to card type receivable.
                      -- -----------------------------------------------------------------------------
                      lc_error_location :=
                         'Create Card Type Receivable Journal Entries for Net Amount for each provider and store';
                      lc_je_line_desc :=
                         'Card Type Receivable: Net (Deposit) Amount for :'
                         || recon_batches_rec.processor_id
                         || ' / Card Type:'
                         || recon_hdr_rec.ajb_card_type
                         || ' / Store '
                         || recon_batches_rec.store_num
                         || ' in Recon Batch '
                         || recon_batches_rec.bank_rec_id;
                      IF recon_batches_rec.net_amount < 0
                      THEN
                         ln_entered_dr_amount :=
                                            ABS(recon_batches_rec.net_amount);
                         ln_entered_cr_amount := 0;
                         od_message
                            ('M'
                           , RPAD('DR Net Amt to Card Type Receivable:'
                                  || recon_batches_rec.currency
                                  || ' '
                                  || recon_batches_rec.net_amount
                                , 50
                                , ' '
                                 )
                             || ' '
                             || RPAD(lc_card_type_acct, 45, ' ')
                             || LPAD(ABS(recon_batches_rec.net_amount)
                                   , 12
                                   , ' '
                                    )
                            );
                      ELSE
                         ln_entered_dr_amount := 0;
                         ln_entered_cr_amount :=
                                            ABS(recon_batches_rec.net_amount);
                         od_message
                            ('M'
                           , RPAD('DR Net Amt to Card Type Receivable:'
                                  || recon_batches_rec.currency
                                  || ' '
                                  || recon_batches_rec.net_amount
                                , 50
                                , ' '
                                 )
                             || ' '
                             || RPAD(lc_card_type_acct, 45, ' ')
                             || LPAD(' ', 12, ' ')
                             || ' '
                             || LPAD(ABS(recon_batches_rec.net_amount)
                                   , 12
                                   , ' '
                                    )
                            );
                      END IF;
                      xx_gl_interface_pkg.create_stg_jrnl_line
                               (p_status                 => 'NEW'
                              , p_date_created           => TRUNC(SYSDATE)
                              , p_created_by             => gn_user_id
                              , p_actual_flag            => 'A'
                              , p_group_id               => ln_group_id
                              , p_je_reference           => ln_group_id
                              , p_batch_name             => TO_CHAR
                                                                 (SYSDATE
                                                                , 'YYYY/MM/DD'
                                                                 )
                              , p_batch_desc             => NULL
                              , p_user_source_name       => 'OD CM Credit Settle'
                              , p_user_catgory_name      => 'Miscellaneous'
                              , p_set_of_books_id        => gn_set_of_bks_id
                              , p_accounting_date        => TRUNC(SYSDATE)
                              , p_currency_code          => recon_batches_rec.currency
                              , p_company                => NULL
                              , p_cost_center            => NULL
                              , p_account                => NULL
                              , p_location               => NULL
                              , p_intercompany           => NULL
                              , p_channel                => NULL
                              , p_future                 => NULL
                              , p_ccid                   => ln_card_type_ccid
                              , p_entered_dr             => ln_entered_dr_amount
                              , p_entered_cr             => ln_entered_cr_amount
                              , p_je_line_dsc            => lc_je_line_desc
                              , x_output_msg             => lc_output_msg
                               );
                      -- ------------------------------------------------
                      -- Calling the Exception
                      -- If insertion into XX_GL_INTERFACE_NA_STG failed.
                      -- ------------------------------------------------
                      IF lc_output_msg IS NOT NULL
                      THEN
                         lc_error_details :=
                            'Error Creating Credit JE (Step 2) for Net (Deposit) Amount to Card Type Receivable Account '
                            || lc_card_type_acct
                            || '-'
                            || lc_error_details
                            || lc_output_msg;
                         lc_error_flag := 'Y';
                         od_message('M', lc_error_details);
                         RAISE ex_recon_batch_exception;
                      END IF;
                     */
/* For update the attribute1 column of 998 and 996 tables - Starts Here*/
                     UPDATE xx_ce_ajb998 xca8
                     SET    xca8.attribute1    = DECODE (lc_error_flag  ----Added for the Defect 6138.
                                                  --,'Y','ERRORED'--Defect100
                                                        ,'Y', 'FEE_RECON_NO'
                                                        ,'N', 'FEE_RECON_YES'
                                                        ,xca8.attribute1
                                                          )
                     WHERE xca8.bank_rec_id    = recon_batches_rec.bank_rec_id
                     AND xca8.processor_id     = recon_batches_rec.processor_id
                     AND xca8.store_num        = recon_batches_rec.store_num;

                     UPDATE xx_ce_ajb996 xca6
                     SET    xca6.attribute1    = DECODE (lc_error_flag  ----Added for the Defect 6138.
                                           --,'Y','ERRORED'--Defect100
                                                 ,'Y', 'FEE_RECON_NO'
                                                 ,'N', 'FEE_RECON_YES'
                                                 ,xca6.attribute1
                                                   )
                     WHERE xca6.bank_rec_id    = recon_batches_rec.bank_rec_id
                     AND xca6.processor_id     = recon_batches_rec.processor_id
                     AND xca6.store_num        = recon_batches_rec.store_num;
                            /* For update the attribute1 column of 998 and 996 tables - Ends Here*/

                     END IF;                               --IF net Amount != 0.
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        lc_error_details :=
                              'Other Error Processing Recon Header : '
                           || lc_error_location
                           || '. '
                           || SQLCODE
                           || ':'
                           || SQLERRM;
                        od_message ('M', lc_error_details);
                        lc_error_flag := 'Y';
                        RAISE ex_recon_batch_exception;
                  END;
               END LOOP;                                       -- recon_hdr_rec.
               lc_error_location := 'After Get Recon Hdr';
-- -------------------------------------------
-- Call the Print Message Details.
-- -------------------------------------------
               print_message_footer
                              (x_errbuf => lc_errmsg
                             , x_retcode => ln_retcode
                             , p_bank_rec_id => recon_batches_rec.bank_rec_id
                             , p_processor_id => recon_batches_rec.processor_id
                             , p_card_type => NVL (lc_orig_card_type
                                                 , recon_batches_rec.card_type
                                                  )
                             , p_store_num => lc_orig_store_num
                             --recon_batches_rec.store_num
               ,               p_net_amount => recon_batches_rec.net_amount
                             , p_process_date => recon_batches_rec.recon_date
                             , p_message => lc_message
                                || NVL (lc_error_details, 'Processed')
                              );
               IF lc_error_details IS NULL
                  AND NVL (lc_error_flag, 'N') = 'N'
               THEN
                  --               od_message
                  --                         ('M'
                  --                        , '**** Update 999 Interface set Expenses Complete="Y"'
                  --                         );
                  ln_success_rec := NVL (ln_success_rec, 0) + 1;
               ELSE
                  od_message ('M'
                            ,    '* * * Error: All Expenses for Recon batch:'
                              || recon_batches_rec.bank_rec_id
                              || ' / Processor: '
                              || recon_batches_rec.processor_id
                              || ' could not be processed!'
                              || '. '
                              || lc_error_details
                             );
                  od_message ('M', '');
                  RAISE ex_recon_batch_exception;
               END IF;
            EXCEPTION
               WHEN ex_recon_batch_exception
               THEN
-- -------------------------------------------
-- Call the Print Message Details.
-- -------------------------------------------
                  print_message_footer
                            (x_errbuf => lc_errmsg
                           , x_retcode => ln_retcode
                           , p_bank_rec_id => recon_batches_rec.bank_rec_id
                           , p_processor_id => recon_batches_rec.processor_id
                           , p_card_type => NVL (lc_orig_card_type
                                               , recon_batches_rec.card_type
                                                )
                           , p_store_num => lc_orig_store_num
                           --recon_batches_rec.store_num
                  ,          p_net_amount => recon_batches_rec.net_amount
                           , p_process_date => recon_batches_rec.recon_date
                           , p_message => NVL (lc_error_details
                                             , 'Error - Review Log for details'
                                              )
                            );
                  ROLLBACK TO lc_recon_batch_savepoint;
                  /* Commented for the Defect 6138 - Starts here 
                     UPDATE xx_ce_ajb999 xca9
                     SET status_1310 = 'ERROR'
                       , last_update_date = SYSDATE
                   WHERE bank_rec_id = recon_batches_rec.bank_rec_id
                     AND processor_id = recon_batches_rec.processor_id
                     AND cardtype =
                            NVL (lc_orig_card_type, recon_batches_rec.card_type)
                     AND store_num = recon_batches_rec.store_num;
                          Commented for the Defect 6138 - Ends here */

                    /* Added for the Defect 6138 - Starts here */

                          lc_error_flag := 'Y';  
                          
                          UPDATE xx_ce_ajb999 xca9
                          SET status_1310 = 'ERROR'
                             ,xca9.attribute1   ='FEE_RECON_NO'
                             ,last_update_date = SYSDATE
                          WHERE bank_rec_id    = recon_batches_rec.bank_rec_id
                          AND processor_id     = recon_batches_rec.processor_id
                          AND cardtype         = NVL (lc_orig_card_type, recon_batches_rec.card_type)
                          AND store_num        = recon_batches_rec.store_num;
                 
              
                          UPDATE xx_ce_ajb998 xca8
                          SET xca8.attribute1   =  'FEE_RECON_NO'
                             ,last_update_date = SYSDATE
                          WHERE bank_rec_id    = recon_batches_rec.bank_rec_id
                          AND processor_id     = recon_batches_rec.processor_id
                          AND store_num        = recon_batches_rec.store_num;

                          UPDATE xx_ce_ajb996 xca6
                          SET xca6.attribute1   =  'FEE_RECON_NO'
                             ,last_update_date = SYSDATE
                          WHERE bank_rec_id    = recon_batches_rec.bank_rec_id
                          AND processor_id     = recon_batches_rec.processor_id
                          AND store_num        = recon_batches_rec.store_num;
                       -- To get the errored store numbers to display in mail body
                           IF lc_err_store_num is null 
                           THEN
                             lc_err_store_num:= recon_batches_rec.store_num;
                           ELSE 
                             lc_err_store_num:=lc_err_store_num||','||recon_batches_rec.store_num;
                             lc_count_flag := 'Y';
                           END IF;

                    /* Added for the Defect 6138 - Ends here */
                          UPDATE xx_ce_999_interface xc9i1
                          SET expenses_complete = 'N'
                            , concurrent_pgm_last = gn_request_id
                            , last_update_date = SYSDATE
                          WHERE bank_rec_id = recon_batches_rec.bank_rec_id
                          AND processor_id = recon_batches_rec.processor_id
                          AND NVL (deposits_matched, 'N') = 'Y'
                          AND NVL (expenses_complete, 'N') = 'N';
                          ln_error_rec := ln_error_rec + 1;
                 
               WHEN OTHERS
               THEN
-- -------------------------------------------
-- Call the Print Message Details.
-- -------------------------------------------
                  print_message_footer
                            (x_errbuf => lc_errmsg
                           , x_retcode => ln_retcode
                           , p_bank_rec_id => recon_batches_rec.bank_rec_id
                           , p_processor_id => recon_batches_rec.processor_id
                           , p_card_type => NVL (lc_orig_card_type
                                               , recon_batches_rec.card_type
                                                )
                           , p_store_num => lc_orig_store_num
                           --recon_batches_rec.store_num
                  ,          p_net_amount => recon_batches_rec.net_amount
                           , p_process_date => recon_batches_rec.recon_date
                           , p_message => NVL (lc_error_details
                                             , 'Error - Review Log for details'
                                              )
                            );
                  ROLLBACK TO lc_recon_batch_savepoint;
                  /* Commented for the Defect 6138 - Starts here 
                     UPDATE xx_ce_ajb999 xca9
                     SET status_1310 = 'ERROR'
                       , last_update_date = SYSDATE
                     WHERE bank_rec_id = recon_batches_rec.bank_rec_id
                     AND processor_id = recon_batches_rec.processor_id
                     AND store_num = recon_batches_rec.store_num;
                     Commented for the Defect 6138 - Ends here */

                /* Added for the Defect 6138 - Starts here */
                     lc_error_flag := 'Y';          
                     UPDATE xx_ce_ajb999 xca9
                     SET status_1310 = 'ERROR'
                        ,xca9.attribute1   = 'FEE_RECON_NO'
                        ,last_update_date  = SYSDATE
                     WHERE bank_rec_id = recon_batches_rec.bank_rec_id
                     AND processor_id = recon_batches_rec.processor_id
                     AND store_num = recon_batches_rec.store_num;

                     UPDATE xx_ce_ajb998 xca8
                     SET xca8.attribute1   = 'FEE_RECON_NO'
                       ,last_update_date = SYSDATE
                     WHERE bank_rec_id    = recon_batches_rec.bank_rec_id
                     AND processor_id     = recon_batches_rec.processor_id
                     AND store_num        = recon_batches_rec.store_num;

                     UPDATE xx_ce_ajb996 xca6
                     SET xca6.attribute1   =  'FEE_RECON_NO'
                       ,last_update_date = SYSDATE
                     WHERE bank_rec_id    = recon_batches_rec.bank_rec_id
                     AND processor_id     = recon_batches_rec.processor_id
                     AND store_num        = recon_batches_rec.store_num;
                         
                       
                     IF lc_err_store_num IS NULL 
                     THEN
                       lc_err_store_num:= recon_batches_rec.store_num;
                     ELSE 
                       lc_err_store_num:=lc_err_store_num||','||recon_batches_rec.store_num;
                       lc_count_flag := 'Y';
                     END IF;
                    /* Added for the Defect 6138 - Ends here */

                     UPDATE xx_ce_999_interface xc9i1
                     SET expenses_complete = 'N'
                       , concurrent_pgm_last = gn_request_id
                       , last_update_date = SYSDATE
                     WHERE bank_rec_id = recon_batches_rec.bank_rec_id
                     AND processor_id = recon_batches_rec.processor_id
                     AND NVL (deposits_matched, 'N') = 'Y'
                     AND NVL (expenses_complete, 'N') = 'N';
                                      od_message ('M'
                            ,    'Error at:'
                              || lc_error_location
                              || '. '
                              || SQLCODE
                              || ':'
                              || SQLERRM
                             );
                     ln_error_rec := ln_error_rec + 1;
            END;                                           -- Recon Batches End;
         END LOOP;                                              -- recon_batches
         CLOSE lcu_get_recon_batches;
         BEGIN
            --Update 999 interface row if all expenses for provider
            -- and batch were sucessfully processed.
            UPDATE xx_ce_999_interface xc9i1
            SET expenses_complete = 'Y'
              , concurrent_pgm_last = gn_request_id
              , last_update_date = SYSDATE
            WHERE bank_rec_id = intf_batches_rec.bank_rec_id
            AND processor_id = intf_batches_rec.processor_id
            AND NVL (deposits_matched, 'N') = 'Y'
            AND NVL (expenses_complete, 'N') = 'N'
            AND ((EXISTS (                                    -- Defect 10756
                        SELECT 1
                        FROM xx_ce_ajb998_v xca8
                         WHERE xca8.bank_rec_id = xc9i1.bank_rec_id
                         AND xca8.processor_id = xc9i1.processor_id)
                 )
                    OR (EXISTS (
                           SELECT 1
                           FROM xx_ce_ajb996_v xca6
                           WHERE xca6.bank_rec_id = xc9i1.bank_rec_id
                           AND xca6.processor_id = xc9i1.processor_id)
                       )
                    OR (EXISTS (
                           SELECT 1
                             FROM xx_ce_ajb999_v xca9
                            WHERE xca9.bank_rec_id = xc9i1.bank_rec_id
                              AND xca9.processor_id = xc9i1.processor_id)
                       )
                )
            AND NOT EXISTS (
                     SELECT 1
                     FROM xx_ce_ajb_net_amounts_v xcan --xx_ce_ajb999_v  --Added for the Defect 6138
                     WHERE xcan.attribute1             = 'FEE_RECON_NO'  --Added for the Defect 6138
                   --WHERE NVL (status_1310, 'ERROR') = 'ERROR'          --Commented for the Defect 6138
                     AND bank_rec_id = xc9i1.bank_rec_id
                     AND processor_id = xc9i1.processor_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               od_message ('M'
                         ,    '* * * Error Updating 999 Interface:'
                           || SQLCODE
                           || '-'
                           || SQLERRM
                          );
         END;
      END LOOP;                                        -- intf_batches_rec loop.
      IF ln_total_rec = 0
      THEN
         od_message ('M', ' ');
         od_message
            ('M'
           , '  ----------   NO MATCHED BATCHES FOUND FOR PROCESSING FEES  ----------'
            );
         od_message ('M', ' ');
      ELSE
         od_message ('M', ' ');
         od_message ('M', ' ');
         od_message ('M', g_print_line);
         od_message ('M', 'Fees with Errors:' || ln_error_rec);
         od_message ('M', 'Successful      :' || ln_success_rec);

         /*Added for the Defect 6138 Starts Here*/
         IF ln_error_rec > 0
         THEN 
           od_message ('M', 'The program ends in warning until the errored store numbers are corrected.'); 
         END IF;
         /* Added for the Defect 6138 Starts Here*/

         od_message ('M', g_print_line);
         od_message ('M', ' ');
      END IF;
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
                                 , argument3 => 'AJB Recon Process - '
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

         /* Added for the Defect 6138 Starts here */

        IF lc_count_flag ='Y'
        THEN 
          lc_errored_store := 'The store numbers '||lc_err_store_num ||' have errored due to setup issues.Please refer the attachment for error details. The program ends in warning until it is corrected.'; -- Mail Body
        ELSE
          lc_errored_store := 'The store number '||lc_err_store_num ||' has errored due to setup issues.Please refer the attachment for error details.The program ends in warning until it is corrected.'; -- Mail Body
        END IF;

        SELECT xftv.target_value1 
        INTO lc_mail_address
        FROM xx_fin_translatedefinition xftd
            ,xx_fin_translatevalues xftv
        WHERE xftv.translate_id = xftd.translate_id
        AND xftd.translation_name = 'XX_CE_FEE_RECON_MAIL_ADDR'
        AND NVL (xftv.enabled_flag, 'N') = 'Y';

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
                                 , argument2 => lc_mail_address
                                 , argument3 => 'AJB Recon Process - '
                                    || TRUNC (SYSDATE)
                                 , argument4 => lc_errored_store
                                 , argument5 => 'Y'
                                 , argument6 => gn_request_id
                                  );
         /* Added for the Defect 6138 ends here */
      ELSIF ln_error_rec = 0
      THEN
         x_retcode := gn_normal;
      END IF;
   EXCEPTION
      WHEN ex_main_exception
      THEN
         x_errbuf := lc_error_location || '-' || lc_error_details;
         x_retcode := gn_error;
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
      WHEN OTHERS
      THEN
         IF SQLCODE = -54
         THEN
            od_message ('M', ' ');
            od_message ('M', g_print_line);
            od_message ('M', ' ');
            od_message ('M'
                      , 'Provider batches are locked by other request/user'
                       );
            od_message ('O'
                      , 'Provider batches are locked by other request/user');
            od_message ('M', ' ');
            od_message ('M', g_print_line);
            ROLLBACK;
         ELSE
            ROLLBACK;
            fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
            fnd_message.set_token ('PACKAGE'
                                 , 'XX_CE_AJB_CC_RECON_PKG.recon_process'
                                  );
            fnd_message.set_token ('PROGRAM', 'CE Credit Card Reconciliation');
            fnd_message.set_token ('SQLERROR', SQLERRM);
            x_errbuf :=
                  lc_error_location
               || '-'
               || lc_error_details
               || '-'
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
                                 , p_object_type => 'CREDIT CARD RECONCILIATION'
                                  );
            fnd_file.put_line (fnd_file.LOG, '==========================');
            fnd_file.put_line (fnd_file.LOG, x_errbuf);
         END IF;
   END recon_process;
-- +=================================================================================+
-- | Name        : MATCH_STMT_TO_AJB_BATCHES                                         |
-- | Description : This procedure matches credit card provider bank deposits         |
-- |               to AJB Reconciliation batches                                     |
-- |                                                                                 |
-- | Parameters  :                                                                   |
-- |                                                                                 |
-- | Returns     :                                                                   |
-- |                                                                                 |
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
         FOR UPDATE NOWAIT;
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
         p_bank_account   IN   ce_bank_accounts.bank_account_id%TYPE 
      ) --commented for defect#37859 ap_bank_accounts_all.bank_account_id%TYPE
      IS
         SELECT transaction_code_id
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
      lc_location          VARCHAR2 (200);
      ln_multi_total       NUMBER;
      lc_matched_status    VARCHAR2 (1)                     := 'N';
      lc_status            VARCHAR2 (30);
      ld_from_date         DATE;
      ld_to_date           DATE;
      lc_stmtsavepoint     VARCHAR2 (50);
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
      od_message ('O', ' ');
      od_message ('O'
                ,    RPAD (' ', 30, ' ')
                  || ' Cash Management AJB Statement Matching '
                  || RPAD (' ', 30, ' ')
                 );
      od_message ('O', ' ');
      od_message ('O'
                ,    'Request ID : '
                  || gn_request_id
                  || RPAD (' ', 60, ' ')
                  || 'Request Date : '
                  || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH:MM:SS')
                 );
      od_message ('O', RPAD ('=', 120, '='));
      od_message ('O', ' ');
      od_message ('O'
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
      od_message ('O'
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
      od_message ('M'
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
         od_message ('M', g_print_line);
         od_message ('M'
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
                  od_message ('M', g_print_line);
                  od_message ('M'
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
                     --od_message('M', 'Savepoint:' || lc_savepoint);
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
                        od_message
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
                                              );
/* Start of changes for update statement for Defect 2610*/

                        UPDATE /*+ INDEX(XCA8 XX_CE_AJB998_N13)*/ xx_ce_ajb998 xca8
                        SET xca8.status_1310 = 'PROCESSED'
                        WHERE xca8.bank_rec_id = lc_bank_rec_id
                        AND xca8.processor_id =  lc_processor_id
                        AND xca8.recon_date <= ccdeptab (i).trx_date
                        AND xca8.org_id = gn_org_id
                        AND xca8.status_1310 = 'NEW'
                        AND xca8.status IN ('PREPROCESSED', 'MATCHED_AR')
                        AND TRIM (xca8.rej_reason_code) IS NULL
                        AND xca8.recon_header_id IS NOT NULL;

                        fnd_file.put_line (fnd_file.log,'Updated xx_ce_ajb998 table for processor_id' ||lc_processor_id);
                        fnd_file.put_line (fnd_file.log,'Updated xx_ce_ajb998 table for bank rec id' ||lc_bank_rec_id);

                        UPDATE xx_ce_ajb996 xca6
                        SET xca6.status_1310 = 'PROCESSED'
                        WHERE xca6.bank_rec_id = lc_bank_rec_id
                        AND xca6.processor_id =  lc_processor_id
                        AND xca6.recon_date <= ccdeptab (i).trx_date
                        AND xca6.org_id = gn_org_id
                        AND xca6.status_1310 = 'NEW'
                        AND xca6.status IN ('PREPROCESSED', 'MATCHED_AR')
                        AND EXISTS (                      -- TEST FOR CHARGEBACK TYPE AND PROVIDER
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
                                    );

                        fnd_file.put_line (fnd_file.log,'Updated xx_ce_ajb996 table for processor_id' ||lc_processor_id);
                        fnd_file.put_line (fnd_file.log,'Updated xx_ce_ajb996 table for bank rec id' ||lc_bank_rec_id);

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
                              OPEN lcu_get_001_trx_code
                                                   (ccdeptab (i).bank_account_id
                                                   );
                              FETCH lcu_get_001_trx_code
                               INTO ln_001_trx_code_id;
                              CLOSE lcu_get_001_trx_code;
-- -------------------------------------------
-- Check wheather Trx Code '001' is set up or not
-- -------------------------------------------
                              IF ln_001_trx_code_id IS NOT NULL
                              THEN
                                 UPDATE ce_statement_lines
                                    SET attribute9 = ccdeptab (i).trx_code_id
                                      , attribute10 =
                                                    ccdeptab (i).bank_trx_number
                                      , trx_code_id = ln_001_trx_code_id
                                      , bank_trx_number = ln_trx_id
                                      , je_status_flag = NULL
                                  WHERE statement_line_id =
                                                  ccdeptab (i).statement_line_id
                                    AND statement_header_id =
                                                ccdeptab (i).statement_header_id;
                              ELSE
                                 od_message
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
                           od_message ('M', '* * * * Error * * * *');
                           od_message ('M'
                                     , x_errbuf || ' : RetCode:' || x_ret_code
                                      );
                           od_message ('M', ' ');
                           ROLLBACK TO lc_savepoint;
                           lc_matched_status := 'N';
                        ELSE
                           lc_matched_status := 'Y';
                        END IF;
                     ELSE
                        od_message ('M', 'Single Recon file match not found.');
                        lc_matched_status := 'N';
                     END IF;
                     CLOSE ajb_single_match_cur;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        od_message
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
                        --od_message('M', 'Savepoint:' || lc_multi_savepoint);
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
                              od_message ('M'
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
                                 EXIT WHEN ln_multi_id_count > 7;
                                 --Check if the total matches statement deposit
                                 IF ln_multi_total = ccdeptab (i).amount
                                 THEN
                                    lc_matched_status := 'Y';
                                    od_message ('M'
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
                                               );

/* Start of changes for update statement for Defect 2610*/

                                       UPDATE /*+ INDEX(XCA8 XX_CE_AJB998_N13)*/ xx_ce_ajb998 xca8
                                        SET xca8.status_1310 = 'PROCESSED'
                                        WHERE xca8.bank_rec_id = lc_bank_rec_id
                                        AND xca8.processor_id =  lc_processor_id
                                        AND xca8.recon_date <= ccdeptab (i).trx_date
                                        AND xca8.org_id = gn_org_id
                                        AND xca8.status_1310 = 'NEW'
                                        AND xca8.status IN ('PREPROCESSED', 'MATCHED_AR')
                                        AND TRIM (xca8.rej_reason_code) IS NULL
                                        AND xca8.recon_header_id IS NOT NULL;

                                       UPDATE xx_ce_ajb996 xca6
                        SET xca6.status_1310 = 'PROCESSED'
                        WHERE xca6.bank_rec_id = lc_bank_rec_id
                        AND xca6.processor_id =  lc_processor_id
                        AND xca6.recon_date <= ccdeptab (i).trx_date
                        AND xca6.org_id = gn_org_id
                        AND xca6.status_1310 = 'NEW'
                        AND xca6.status IN ('PREPROCESSED', 'MATCHED_AR')
                        AND EXISTS (                      -- TEST FOR CHARGEBACK TYPE AND PROVIDER
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
                                    );
/* End of changes for update statement for Defect 2610*/

                                       od_message
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
                                          OPEN lcu_get_001_trx_code
                                                   (ccdeptab (i).bank_account_id
                                                   );
                                          FETCH lcu_get_001_trx_code
                                           INTO ln_001_trx_code_id;
                                          CLOSE lcu_get_001_trx_code;
-- -------------------------------------------
-- Check wheather Trx Code '001' is set up or not
-- -------------------------------------------
                                          IF ln_001_trx_code_id IS NOT NULL
                                          THEN
                                             UPDATE ce_statement_lines
                                                SET attribute9 =
                                                        ccdeptab (i).trx_code_id
                                                  , attribute10 =
                                                       ccdeptab (i).bank_trx_number
                                                  , trx_code_id =
                                                              ln_001_trx_code_id
                                                  , bank_trx_number = ln_trx_id
                                                  , je_status_flag = NULL
                                              WHERE statement_line_id =
                                                       ccdeptab (i).statement_line_id
                                                AND statement_header_id =
                                                      ccdeptab (i).statement_header_id;
                                          ELSE
                                             od_message
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
                                       od_message ('M'
                                                 , '* * * * Error * * * *');
                                       od_message ('M', x_errbuf);
                                       od_message ('M', ' ');
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
                                       od_message
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
                                    od_message ('M'
                                              ,    'Match not found with '
                                                || ln_multi_id_count
                                                || ' batch(es)!'
                                               );
                                 END IF;
                              END LOOP;        --Multimatchtab first..last loop.
                              IF ln_multi_id_count = 0
                              THEN
                                 od_message ('M'
                                           , 'No Matching Recon batches found!'
                                            );
                              END IF;
                           END IF;                    --Multimatchtab count > 0.
                        END LOOP;                        ---Multimatch cur loop.
                        CLOSE ajb_multi_match_cur;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           od_message
                              ('M'
                             ,    'Exception in Multiple recon file match after '
                               || lc_location
                              );
                           od_message ('M', SQLCODE || ':' || SQLERRM);
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
                  od_message ('O'
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
                        od_message
                           ('M'
                          , 'Statement is locked and is being processed by other request/user'
                           );
                        od_message
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
                        od_message ('M'
                                  , 'Error/Warning:' || SQLCODE || '-'
                                    || SQLERRM
                                   );
                        od_message
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
            od_message ('M', g_print_line);
         END IF;                                   -- stmt_cc_dep_tab.COUNT > 0.
      END LOOP;                                        --stmt_cc_lines_cur loop.
   END match_stmt_to_ajb_batches;
   FUNCTION get_recon_date (p_bank_rec_id IN xx_ce_ajb999.bank_rec_id%TYPE)
      RETURN DATE
   IS
      l_recon_date   DATE;
   BEGIN
      SELECT TO_DATE (SUBSTR (p_bank_rec_id, 1, 8), 'YYYYMMDD')
        INTO l_recon_date
        FROM DUAL;
      RETURN l_recon_date;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_recon_date;
   PROCEDURE bpel_delete_recs (
      p_table_name   IN       VARCHAR2
    , p_file_name    IN       VARCHAR2
    , p_error_flag   OUT      VARCHAR2
    , p_message      OUT      VARCHAR2
   )
   IS
   BEGIN
      SAVEPOINT bpel_delete_recs;
      IF p_table_name IS NULL
         OR p_file_name IS NULL
      THEN
         p_error_flag := 'Y';
         p_message := 'Invalid Table / File Name';
      END IF;
      IF UPPER (LTRIM (RTRIM (p_table_name))) = 'XX_CE_AJB998'
      THEN
         
       /*DELETE FROM xx_ce_ajb998
               WHERE UPPER (LTRIM (RTRIM (ajb_file_name))) =
                                            UPPER (LTRIM (RTRIM (p_file_name)));*/ --Commented for Defect #8421
         DELETE FROM xx_ce_ajb998
               WHERE ajb_file_name = p_file_name ; --Added for Defect #8421
         
         p_error_flag := 'N';
         p_message := 'Deleted from XX_CE_AJB998 table';
      ELSIF UPPER (LTRIM (RTRIM (p_table_name))) = 'XX_CE_AJB996'
      THEN
         
       /*DELETE FROM xx_ce_ajb996
               WHERE UPPER (LTRIM (RTRIM (ajb_file_name))) =
                                            UPPER (LTRIM (RTRIM (p_file_name)));*/ --Commented for Defect #8421
        
         DELETE FROM xx_ce_ajb996
               WHERE ajb_file_name = p_file_name ; --Added for Defect #8421

         p_error_flag := 'N';
         p_message := 'Deleted from XX_CE_AJB996 table';
      ELSIF UPPER (LTRIM (RTRIM (p_table_name))) = 'XX_CE_AJB999'
      THEN
         
       /*DELETE FROM xx_ce_ajb999
               WHERE UPPER (LTRIM (RTRIM (ajb_file_name))) =
                                            UPPER (LTRIM (RTRIM (p_file_name)));*/ --Commented for Defect #8421

         DELETE FROM xx_ce_ajb999
               WHERE ajb_file_name = p_file_name ;  --Added for Defect #8421

         p_error_flag := 'N';
         p_message := 'Deleted from XX_CE_AJB999 table';
      ELSE
         p_error_flag := 'Y';
         p_message := 'Invalid table name :' || p_table_name;
      END IF;
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK TO bpel_delete_recs;
         p_error_flag := 'Y';
         p_message := 'Error:' || SQLCODE || '-' || SQLERRM;
   END bpel_delete_recs;                                     --bpel_delete_recs.
   -- Function BPEL_CHECK_DUP_FILE
   --    Returns 'T' if file has been loaded
   --    Returns 'F' if file has not been loaded
   --    Returns 'E' if error
   FUNCTION bpel_check_dup_file (
      p_table_name   IN   VARCHAR2
    , p_file_name    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      lc_found_val   NUMBER;
   BEGIN
      IF p_table_name IS NULL
         OR p_file_name IS NULL
      THEN
         RETURN 'E';
      END IF;
      IF UPPER (LTRIM (RTRIM (p_table_name))) = 'XX_CE_AJB998'
      THEN
         BEGIN
            --Commented for defect 4216
            /*SELECT 1
              INTO lc_found_val
              FROM xx_ce_ajb998
             WHERE UPPER (LTRIM (RTRIM (ajb_file_name))) =
                                             UPPER (LTRIM (RTRIM (p_file_name)))
               AND ROWNUM = 1;*/
            --Added for defect 4216
            SELECT 1
              INTO lc_found_val
              FROM xx_ce_ajb998
             WHERE ajb_file_name = p_file_name
               AND ROWNUM = 1;
            RETURN 'T';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               RETURN 'F';
            WHEN OTHERS
            THEN
               RETURN 'E';
         END;
      ELSIF UPPER (LTRIM (RTRIM (p_table_name))) = 'XX_CE_AJB996'
      THEN
         BEGIN
            --Commented for defect 4216
            /*SELECT 1
              INTO lc_found_val
              FROM xx_ce_ajb996
             WHERE UPPER (LTRIM (RTRIM (ajb_file_name))) =
                                             UPPER (LTRIM (RTRIM (p_file_name)))
               AND ROWNUM = 1;*/
            --Added for defect 4216
            SELECT 1
              INTO lc_found_val
              FROM xx_ce_ajb996
             WHERE ajb_file_name = p_file_name
               AND ROWNUM = 1;
            RETURN 'T';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               RETURN 'F';
            WHEN OTHERS
            THEN
               RETURN 'E';
         END;
      ELSIF UPPER (LTRIM (RTRIM (p_table_name))) = 'XX_CE_AJB999'
      THEN
         BEGIN
            --Commented for defect 4216
            /*SELECT 1
              INTO lc_found_val
              FROM xx_ce_ajb998
             WHERE UPPER (LTRIM (RTRIM (ajb_file_name))) =
                                             UPPER (LTRIM (RTRIM (p_file_name)))
               AND ROWNUM = 1;*/
            --Added for defect 4216
            SELECT 1
              INTO lc_found_val
              FROM xx_ce_ajb999
             WHERE ajb_file_name = p_file_name
               AND ROWNUM = 1;
            RETURN 'T';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               RETURN 'F';
            WHEN OTHERS
            THEN
               RETURN 'E';
         END;
      ELSE
         RETURN 'E';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 'E';
   END bpel_check_dup_file;
   FUNCTION bpel_record_file_load (
      p_file_type          IN   VARCHAR2
    , p_file_name          IN   VARCHAR2
    , p_bpel_instance_id   IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
   BEGIN
      INSERT INTO xx_ce_ajb_file_log
                  (log_seq_id, file_type, file_name
                 , bpel_instance_id, creation_date
                  )
           VALUES (xx_ce_ajb_file_log_s.NEXTVAL, p_file_type, p_file_name
                 , p_bpel_instance_id, SYSDATE
                  );
      RETURN 'T';
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 'F';
   END bpel_record_file_load;
   PROCEDURE xx_ce_ajb_inbound_preprocess (
      x_errbuf          OUT NOCOPY      VARCHAR2
    , x_retcode         OUT NOCOPY      NUMBER
    , p_file_type       IN              VARCHAR2
    , p_ajb_file_name   IN              VARCHAR2
    , p_batch_size      IN              NUMBER
   )
   IS
      /* Define Variables */
      v_bank_rec_id         xx_ce_ajb996.bank_rec_id%TYPE;
      v_currency            fnd_currencies.currency_code%TYPE;
      v_currency_code       xx_ce_ajb996.currency_code%TYPE;
      v_country_code        xx_ce_ajb996.country_code%TYPE;
      v_org_id              hr_all_organization_units.organization_id%TYPE;
      v_recon_date          xx_ce_ajb996.recon_date%TYPE;
      v_territory_code      fnd_territories.territory_code%TYPE;
      ln_recon_header_id    xx_ce_recon_glact_hdr.header_id%TYPE;
      lc_card_type          xx_ce_recon_glact_hdr.ajb_card_type%TYPE;
      lc_card_num           xx_ce_ajb996.card_num%TYPE;
      lc_996_savepoint      VARCHAR2 (100)                    := 'Savepoint996';
      lc_998_savepoint      VARCHAR2 (100)                    := 'Savepoint998';
      lc_996_unmatched_savepoint      VARCHAR2 (100)          := 'Savepoint996unmatched';
      /* Cursor for preprocessing 996 country/org */
      CURSOR org_996_cur
      IS
         SELECT DISTINCT country_code
                    FROM xx_ce_ajb996
                   WHERE status = 'PREPROCESSING'
                     AND country_code IS NOT NULL
                     AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
                     --AND org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
      /* Cursor for preprocessing 996 currency */
      CURSOR currency_996_cur
      IS
         SELECT DISTINCT currency_code
                    FROM xx_ce_ajb996
                   WHERE status = 'PREPROCESSING'
                     AND currency_code IS NOT NULL
                     AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name)
                     AND org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
      /* Cursor for preprocessing 996 bank_rec_id */
      CURSOR bank_996_cur
      IS
         SELECT DISTINCT bank_rec_id
                    FROM xx_ce_ajb996
                   WHERE status = 'PREPROCESSING'
                     AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name)
                     AND org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
      TYPE all_99x_rec IS RECORD (
         x99x_rowid        ROWID
       , cash_receipt_id   NUMBER
       , header_id         NUMBER
       , processor_id      xx_ce_ajb998.processor_id%TYPE
       , ajb_card_type     xx_ce_recon_glact_hdr.ajb_card_type%TYPE
       , bank_rec_id       xx_ce_ajb998.bank_rec_id%TYPE
      );
      TYPE all_996_unmatched_rec IS RECORD (
         x99x_rowid        ROWID
       , processor_id      xx_ce_ajb998.processor_id%TYPE
       , bank_rec_id       xx_ce_ajb998.bank_rec_id%TYPE
       , ajb_file_name     xx_ce_ajb998.ajb_file_name%TYPE
       , card_num          xx_ce_ajb998.card_num%TYPE
       , provider_type     xx_ce_ajb998.provider_type%TYPE
      );
      TYPE all_99x_tab IS TABLE OF all_99x_rec
         INDEX BY BINARY_INTEGER;
      TYPE all_996_unmatched_tab IS TABLE OF all_996_unmatched_rec
         INDEX BY BINARY_INTEGER;
      all_99x_data               all_99x_tab;
      all_99x_null               all_99x_tab;
      all_996_unmatched_data     all_996_unmatched_tab;
      all_996_unmatched_null     all_996_unmatched_tab;
      /* Cursor for preprocessing all 996 data */
      CURSOR all_996_cr_cur
      IS
         SELECT     xca6.ROWID row_id
                  , (SELECT cash_receipt_id
                       FROM xx_ce_ajb_receipts_v xcarv
                      WHERE ROWNUM = 1
                        AND xca6.processor_id = xcarv.provider_code
                        AND xca6.org_id = xcarv.org_id
                        AND xca6.trx_date - 0 = xcarv.receipt_date - 0
                        AND xca6.receipt_num = xcarv.receipt_number)
                                                                cash_receipt_id
                  , (SELECT header_id
                       FROM xx_ce_ajb_receipts_v xcarv
                      WHERE ROWNUM = 1
                        AND xca6.processor_id = xcarv.provider_code
                        AND xca6.org_id = xcarv.org_id
                        AND xca6.trx_date - 0 = xcarv.receipt_date - 0
                        AND xca6.receipt_num = xcarv.receipt_number) header_id
                  , xca6.processor_id
                  , (SELECT ajb_card_type
                       FROM xx_ce_ajb_receipts_v xcarv
                      WHERE ROWNUM = 1
                        AND xca6.processor_id = xcarv.provider_code
                        AND xca6.org_id = xcarv.org_id
                        AND xca6.trx_date - 0 = xcarv.receipt_date - 0
                        AND xca6.receipt_num = xcarv.receipt_number)
                                                                  ajb_card_type
                  , xca6.bank_rec_id
               FROM xx_ce_ajb996 xca6
              WHERE 1 = 1
                AND xca6.org_id = gn_org_id -- Added for PROD Defect: 2046,1716
                AND xca6.status = 'PREPROCESSED'
                AND xca6.ajb_file_name =
                                       NVL (p_ajb_file_name, xca6.ajb_file_name)
                AND xca6.provider_type = 'CREDIT'
                AND NOT EXISTS (
                      SELECT 1
                        FROM xx_ce_999_interface
                       WHERE bank_rec_id = xca6.bank_rec_id
                         AND processor_id = xca6.processor_id)
         FOR UPDATE NOWAIT;
               /* Cursor for populating the recon_header_id for all unmatched 996 data */
      CURSOR all_996_unmatched_cr_cur
      IS
        SELECT  xca6.ROWID row_id
              , xca6.processor_id
              , xca6.bank_rec_id
              , xca6.ajb_file_name
              , xca6.card_num
              , xca6.provider_type
          FROM xx_ce_ajb996 xca6
        WHERE 1 = 1
          AND xca6.org_id = gn_org_id -- Added for PROD Defect: 2046,1716
          AND xca6.status in ('PREPROCESSED' , 'PREPROCESSING', 'NOTMATCHED')
          AND xca6.ajb_file_name = NVL (p_ajb_file_name, xca6.ajb_file_name)
          AND xca6.recon_header_id is NULL
          AND NOT EXISTS (
                SELECT 1
                  FROM xx_ce_999_interface
                 WHERE bank_rec_id = xca6.bank_rec_id
                   AND processor_id = xca6.processor_id)
         FOR UPDATE NOWAIT;
      CURSOR all_996_non_cr_cur
      IS
         SELECT     xca6.ROWID row_id
                  , (SELECT cash_receipt_id
                       FROM xx_ce_ajb_receipts_v xcarv
                      WHERE ROWNUM = 1
                        AND xca6.processor_id = xcarv.provider_code
                        AND xca6.org_id = xcarv.org_id
                        AND xca6.receipt_num = xcarv.customer_receipt_reference
                        AND (xca6.trx_date - 0 = xcarv.receipt_date - 0
                            OR xca6.trx_date - 0 = xcarv.receipt_date + 1))
                                                                cash_receipt_id
                  , (SELECT header_id
                       FROM xx_ce_ajb_receipts_v xcarv
                      WHERE ROWNUM = 1
                        AND xca6.processor_id = xcarv.provider_code
                        AND xca6.org_id = xcarv.org_id
                        AND xca6.receipt_num = xcarv.customer_receipt_reference
                        AND (xca6.trx_date - 0 = xcarv.receipt_date - 0
                            OR xca6.trx_date - 0 = xcarv.receipt_date + 1))
                                                                      header_id
                  , xca6.processor_id
                  , (SELECT ajb_card_type
                       FROM xx_ce_ajb_receipts_v xcarv
                      WHERE ROWNUM = 1
                        AND xca6.processor_id = xcarv.provider_code
                        AND xca6.org_id = xcarv.org_id
                        AND xca6.receipt_num = xcarv.customer_receipt_reference
                        AND (xca6.trx_date - 0 = xcarv.receipt_date - 0
                            OR xca6.trx_date - 0 = xcarv.receipt_date + 1))
                                                                  ajb_card_type
                  , xca6.bank_rec_id
               FROM xx_ce_ajb996 xca6
              WHERE 1 = 1
                AND xca6.org_id = gn_org_id -- Added for PROD Defect: 2046,1716
                AND xca6.status = 'PREPROCESSED'
                AND xca6.ajb_file_name =
                                       NVL (p_ajb_file_name, xca6.ajb_file_name)
                AND xca6.provider_type IN ('CHECK', 'DEBIT')
                AND NOT EXISTS (
                      SELECT 1
                        FROM xx_ce_999_interface
                       WHERE bank_rec_id = xca6.bank_rec_id
                         AND processor_id = xca6.processor_id)
         FOR UPDATE NOWAIT;
      CURSOR all_996_no_cardtype_cur
      IS
         SELECT     xca6.ROWID row_id, ar_cash_receipt_id cash_receipt_id
                  , recon_header_id header_id, processor_id, '' ajb_card_type
                  , bank_rec_id
               FROM xx_ce_ajb996 xca6
              WHERE 1 = 1
                AND xca6.org_id = gn_org_id -- Added for PROD Defect: 2046,1716
                AND xca6.status = 'NOTMATCHED'
                AND xca6.processor_id = 'NABCRD'
                AND xca6.ajb_file_name =
                                       NVL (p_ajb_file_name, xca6.ajb_file_name)
                AND SUBSTR (bank_rec_id, -2, 2) NOT IN (
                                   SELECT '-' || SUBSTR (ajb_card_type, 1, 1)
                                     FROM xx_ce_recon_glact_hdr xcrgh
                                    WHERE xca6.processor_id =
                                                             xcrgh.provider_code)
                AND NOT EXISTS (
                      SELECT 1
                        FROM xx_ce_999_interface
                       WHERE bank_rec_id = xca6.bank_rec_id
                         AND processor_id = xca6.processor_id)
         FOR UPDATE NOWAIT;
      /* Cursor for preprocessing 998 country/org */
      CURSOR org_998_cur
      IS
         SELECT DISTINCT country_code
                    FROM xx_ce_ajb998
                   WHERE status = 'PREPROCESSING'
                     AND country_code IS NOT NULL
                     AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
                     --ANd org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
      /* Cursor for preprocessing 998 currency */
      CURSOR currency_998_cur
      IS
         SELECT DISTINCT currency_code
                    FROM xx_ce_ajb998
                   WHERE status = 'PREPROCESSING'
                     AND currency_code IS NOT NULL
                     AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name)
                     AND org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
      /* Cursor for preprocessing 998 bank_rec_id */
      CURSOR bank_998_cur
      IS
         SELECT DISTINCT bank_rec_id
                    FROM xx_ce_ajb998
                   WHERE status = 'PREPROCESSING'
                     AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name)
                     AND org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
      /* Cursor for preprocessing all 998 data */
      CURSOR all_998_cr_cur
      IS
         SELECT     xca8.ROWID row_id
                  , (SELECT cash_receipt_id
                       FROM xx_ce_ajb_receipts_v xcarv
                      WHERE ROWNUM = 1
                        AND xca8.processor_id = xcarv.provider_code
                        AND xca8.org_id = xcarv.org_id
                        AND xca8.trx_date - 0 = xcarv.receipt_date - 0
                        AND xca8.receipt_num = xcarv.receipt_number
                        AND ((xcarv.amount = 0)
                             OR (xcarv.amount != 0
                                 AND xca8.trx_amount = xcarv.amount
                                )
                            )) cash_receipt_id
                  , (SELECT header_id
                       FROM xx_ce_ajb_receipts_v xcarv
                      WHERE ROWNUM = 1
                        AND xca8.processor_id = xcarv.provider_code
                        AND xca8.org_id = xcarv.org_id
                        AND xca8.trx_date - 0 = xcarv.receipt_date - 0
                        AND xca8.receipt_num = xcarv.receipt_number
                        AND ((xcarv.amount = 0)
                             OR (xcarv.amount != 0
                                 AND xca8.trx_amount = xcarv.amount
                                )
                            )) header_id
                  , xca8.processor_id
                  , (SELECT ajb_card_type
                       FROM xx_ce_ajb_receipts_v xcarv
                      WHERE ROWNUM = 1
                        AND xca8.processor_id = xcarv.provider_code
                        AND xca8.org_id = xcarv.org_id
                        AND xca8.trx_date - 0 = xcarv.receipt_date - 0
                        AND xca8.receipt_num = xcarv.receipt_number
                        AND ((xcarv.amount = 0)
                             OR (xcarv.amount != 0
                                 AND xca8.trx_amount = xcarv.amount
                                )
                            )) ajb_card_type
                  , xca8.bank_rec_id
               FROM xx_ce_ajb998 xca8
              WHERE 1 = 1
                AND xca8.org_id = gn_org_id -- Added for PROD Defect: 2046,1716
                AND xca8.rej_reason_code IS NULL
                AND xca8.status = 'PREPROCESSED'
                AND xca8.ajb_file_name =
                                       NVL (p_ajb_file_name, xca8.ajb_file_name)
                AND xca8.provider_type = 'CREDIT'
                AND NOT EXISTS (
                      SELECT 1
                        FROM xx_ce_999_interface
                       WHERE bank_rec_id = xca8.bank_rec_id
                         AND processor_id = xca8.processor_id)
         FOR UPDATE NOWAIT;
      CURSOR all_998_non_cr_cur
      IS
        SELECT     xca8.ROWID row_id
                  , (SELECT cash_receipt_id
                       FROM xx_ce_ajb_receipts_v xcarv
                      WHERE ROWNUM = 1
                        AND xca8.processor_id = xcarv.provider_code
                        AND xca8.org_id = xcarv.org_id
                        AND xca8.receipt_num = xcarv.customer_receipt_reference
                        AND (xca8.trx_date - 0 = xcarv.receipt_date - 0
                            OR xca8.trx_date - 0 = xcarv.receipt_date + 1)
                        AND xcarv.amount != 0 --Added for Defect 4721 by Jude
                        AND xca8.trx_amount = xcarv.amount )cash_receipt_id

                        /*AND ((xcarv.amount = 0)  --Commented for Defect 4721 by Jude
                             OR (xcarv.amount != 0
                                 AND xca8.trx_amount = xcarv.amount
                                )
                            )) cash_receipt_id*/
                  , (SELECT header_id
                       FROM xx_ce_ajb_receipts_v xcarv
                      WHERE ROWNUM = 1
                        AND xca8.processor_id = xcarv.provider_code
                        AND xca8.org_id = xcarv.org_id
                        AND xca8.receipt_num = xcarv.customer_receipt_reference
                        AND (xca8.trx_date - 0 = xcarv.receipt_date - 0
                            OR xca8.trx_date - 0 = xcarv.receipt_date + 1)
                        AND xcarv.amount != 0 --Added for Defect 4721 by Jude
                        AND xca8.trx_amount = xcarv.amount ) header_id

                        /*AND ((xcarv.amount = 0)  --Commented for Defect 4721 by Jude
                             OR (xcarv.amount != 0
                                 AND xca8.trx_amount = xcarv.amount
                                )
                            )) header_id*/
                  , xca8.processor_id
                  , (SELECT ajb_card_type
                       FROM xx_ce_ajb_receipts_v xcarv
                      WHERE ROWNUM = 1
                        AND xca8.processor_id = xcarv.provider_code
                        AND xca8.org_id = xcarv.org_id
                        AND xca8.receipt_num = xcarv.customer_receipt_reference
                        AND (xca8.trx_date - 0 = xcarv.receipt_date - 0
                             OR xca8.trx_date - 0 = xcarv.receipt_date + 1)
                        AND xcarv.amount != 0 --Added for Defect 4721 by Jude
                        AND xca8.trx_amount = xcarv.amount ) ajb_card_type

                        /*AND ((xcarv.amount = 0)  --Commented for Defect 4721 by Jude
                             OR (xcarv.amount != 0
                                 AND xca8.trx_amount = xcarv.amount
                                )
                            )) ajb_card_type*/

                  , xca8.bank_rec_id
               FROM xx_ce_ajb998 xca8
              WHERE 1 = 1
                AND xca8.org_id = gn_org_id -- Added for PROD Defect: 2046,1716
                AND xca8.status = 'PREPROCESSED'
                AND xca8.ajb_file_name =
                                       NVL (p_ajb_file_name, xca8.ajb_file_name)
                AND xca8.provider_type IN ('CHECK', 'DEBIT')
                AND xca8.rej_reason_code IS NULL
                AND NOT EXISTS (
                      SELECT 1
                        FROM xx_ce_999_interface
                       WHERE bank_rec_id = xca8.bank_rec_id
                         AND processor_id = xca8.processor_id)
         FOR UPDATE NOWAIT;
      /* Cursor for preprocessing 999 country/org */
      CURSOR org_999_cur
      IS
         SELECT DISTINCT country_code
                    FROM xx_ce_ajb999
                   WHERE status = 'PREPROCESSING'
                     AND country_code IS NOT NULL
                     AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
                     --AND org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
      /* Cursor for preprocessing 999 currency */
      CURSOR currency_999_cur
      IS
         SELECT DISTINCT currency_code
                    FROM xx_ce_ajb999
                   WHERE status = 'PREPROCESSING'
                     AND currency_code IS NOT NULL
                     AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name)
                     AND org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
      /* Cursor for preprocessing 999 bank_rec_id */
      CURSOR bank_999_cur
      IS
         SELECT DISTINCT bank_rec_id
                    FROM xx_ce_ajb999
                   WHERE status = 'PREPROCESSING'
                     AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name)
                     AND org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
      /* Cursor for preprocessing unknown 999 cardtypes. */
      CURSOR bad_999_cardtypes_cur
      IS
         SELECT ROWID row_id, processor_id
           FROM xx_ce_ajb999
          WHERE org_id = gn_org_id -- Added for PROD Defect: 2046,1716
            AND status = 'PREPROCESSING'
            AND cardtype NOT IN (SELECT DISTINCT ajb_card_type
                                            FROM xx_ce_recon_glact_hdr);
      lc_default_cardtype   xx_ce_recon_glact_hdr.ajb_card_type%TYPE;
   BEGIN
      fnd_file.put_line (fnd_file.LOG
                       ,    'Starting xx_ce_ajb_inbound_preprocess at '
                         || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                        );
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, LPAD ('-', 100, '-'));
      /* Update all status */
      UPDATE xx_ce_ajb996
         SET status = 'PREPROCESSING'
       WHERE status IS NULL
        -- AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
         AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
      /* Process the 996 p_file_type */
      IF NVL (UPPER (p_file_type), 'ALL') IN ('996', 'ALL')
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Preprocessing 996 data...');
         /* Logic from xx_ce_ajb996_t and xx_ce_ajb996_v on xx_ce_ajb996 */
         /* Only open the org_996_cur if it is not already open */
         IF org_996_cur%ISOPEN
         THEN
            NULL;
         ELSE
            OPEN org_996_cur;
            fnd_file.put_line (fnd_file.LOG, 'Preprocessing 996 country/orgs.');
         END IF;
         LOOP
            /* Populate variables using cursor fetch.  No point using bulk collect as < 5 */
            FETCH org_996_cur
             INTO v_country_code;
            /* Keep fetching until no more records are found */
            EXIT WHEN NOT org_996_cur%FOUND;
            BEGIN
               /* Lookup the org_id for the country */
               SELECT xx_fin_country_defaults_pkg.f_org_id (territory_code)
                    , territory_code
                 INTO v_org_id
                    , v_territory_code
                 FROM fnd_territories
                WHERE iso_numeric_code = v_country_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_org_id := NULL;
            END;
            fnd_file.put_line (fnd_file.LOG
                             ,    '  Updating 996 country_code values of '
                               || v_country_code
                               || ' with org_id of '
                               || v_org_id
                               || ' and territory_code of '
                               || v_territory_code
                               || '.'
                              );
            /* Update the source value */
            UPDATE xx_ce_ajb996
               SET org_id = v_org_id
                 , territory_code = v_territory_code
             WHERE status = 'PREPROCESSING'
               AND country_code = v_country_code;
         END LOOP;
         CLOSE org_996_cur;
         fnd_file.put_line (fnd_file.LOG
                          , 'Finished preprocessing 996 country/orgs.'
                           );
         fnd_file.put_line
                      (fnd_file.LOG
                     , 'Updating 996 bank_rec_id values with -XX provider_type.'
                      );
         /* Update all bank_rec_ids  */
         UPDATE xx_ce_ajb996
            SET bank_rec_id =
                      bank_rec_id
                   || '-'
                   || SUBSTR (provider_type, 1, 2)
                   || '-'
                   || territory_code
          WHERE status = 'PREPROCESSING'
            AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
            AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
         fnd_file.put_line
            (fnd_file.LOG
           , 'Finished preprocessing 996 bank_rec_id values with -XX provider_type.'
            );
         /* Only open the currency_996_cur if it is not already open */
         IF currency_996_cur%ISOPEN
         THEN
            NULL;
         ELSE
            OPEN currency_996_cur;
            fnd_file.put_line (fnd_file.LOG, 'Preprocessing 996 currencies.');
         END IF;
         LOOP
            /* Populate variables using cursor fetch.  No point using bulk collect as < 5 */
            FETCH currency_996_cur
             INTO v_currency_code;
            /* Keep fetching until no more records are found */
            EXIT WHEN NOT currency_996_cur%FOUND;
            BEGIN
               /* Lookup the currency for the country */
               SELECT currency_code
                 INTO v_currency
                 FROM fnd_currencies
                WHERE attribute1 = v_currency_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_currency := NULL;
            END;
            fnd_file.put_line (fnd_file.LOG
                             ,    '  Updating 996 currency_code values of '
                               || v_currency_code
                               || ' with currency of '
                               || v_currency
                               || '.'
                              );
            /* Update the source value */
            UPDATE xx_ce_ajb996
               SET currency = v_currency
             WHERE status = 'PREPROCESSING'
               AND currency_code = v_currency_code;
         END LOOP;
         CLOSE currency_996_cur;
         fnd_file.put_line (fnd_file.LOG
                          , 'Finished preprocessing 996 currencies.'
                           );
         /* Only open the bank_996_cur if it is not already open */
         IF bank_996_cur%ISOPEN
         THEN
            NULL;
         ELSE
            OPEN bank_996_cur;
            fnd_file.put_line (fnd_file.LOG, 'Preprocessing 996 bank_rec_ids.');
         END IF;
         LOOP
            /* Populate variables using cursor fetch */
            FETCH bank_996_cur
             INTO v_bank_rec_id;
            /* Keep fetching until no more records are found */
            EXIT WHEN NOT bank_996_cur%FOUND;
            BEGIN
               v_recon_date :=
                          xx_ce_ajb_cc_recon_pkg.get_recon_date (v_bank_rec_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  BEGIN
                     v_recon_date :=
                             TO_DATE (SUBSTR (v_bank_rec_id, 1, 8), 'YYYYMMDD');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_recon_date := TRUNC (SYSDATE);
                  END;
            END;
            fnd_file.put_line (fnd_file.LOG
                             ,    '  Updating 996 bank_rec_id values of '
                               || v_bank_rec_id
                               || ' with recon_date of '
                               || v_recon_date
                               || '.'
                              );
            /* Update the source value */
            UPDATE xx_ce_ajb996
               SET recon_date = v_recon_date
             WHERE status = 'PREPROCESSING'
               AND bank_rec_id = v_bank_rec_id;
         END LOOP;
         CLOSE bank_996_cur;
         fnd_file.put_line (fnd_file.LOG
                          ,    '  Updating 996 NULL recon_date values with '
                            || TRUNC (SYSDATE)
                            || '.'
                           );
         /* Update the source value */
         UPDATE xx_ce_ajb996
            SET recon_date = TRUNC (SYSDATE)
          WHERE status = 'PREPROCESSING'
            AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
            AND recon_date IS NULL;
         fnd_file.put_line (fnd_file.LOG
                          , 'Finished preprocessing 996 bank_rec_ids.'
                           );
         fnd_file.put_line (fnd_file.LOG, 'Preprocessing 996 receipt_nums.');
         /* Update the source value */
         UPDATE xx_ce_ajb996
            SET attribute21 = receipt_num
              , receipt_num =
                   SUBSTR (receipt_num || '#'
                         , 1
                         , INSTR (receipt_num || '#', '#') - 1
                          )
          WHERE status = 'PREPROCESSING'
            AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
            AND provider_type = 'CREDIT'
            AND receipt_num IS NOT NULL;
         fnd_file.put_line (fnd_file.LOG
                          , 'Finished preprocessing 996 country/orgs.'
                           );
         fnd_file.put_line (fnd_file.LOG
                          , 'Updating status of all 996 preprocessed records.'
                           );
         /* Update status */
         UPDATE xx_ce_ajb996
            SET status = 'PREPROCESSED'
              , last_update_date = SYSDATE
          WHERE status = 'PREPROCESSING'
            AND org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
         fnd_file.put_line
                    (fnd_file.LOG
                   , 'Finished updating status of all 996 preprocessed records.'
                    );
         fnd_file.put_line (fnd_file.LOG, '996 data preprocessed!');
         /* End of logic from xx_ce_ajb996_t and xx_ce_ajb996_v on xx_ce_ajb996, commit */
         COMMIT;
  --    xx_ce_ajb996_ar_v
           BEGIN
              fnd_file.put_line (fnd_file.LOG
                               , 'Match CreditCard 996 Transactions to AR.'
                                );
              all_99x_data := all_99x_null;
              SAVEPOINT lc_996_savepoint;
              OPEN all_996_cr_cur;
              LOOP
                 FETCH all_996_cr_cur
                 BULK COLLECT INTO all_99x_data LIMIT p_batch_size;
                 EXIT WHEN all_99x_data.COUNT = 0;
                 FOR idx IN all_99x_data.FIRST .. all_99x_data.LAST
                 LOOP
                    -- If matching AR record and Recon Setup is found
                    IF all_99x_data (idx).cash_receipt_id IS NOT NULL
                       --Defect 10048
                       AND all_99x_data (idx).header_id IS NOT NULL
                    THEN
                       UPDATE xx_ce_ajb996
                          SET status = 'MATCHED_AR'
                            , ar_cash_receipt_id =
                                                all_99x_data (idx).cash_receipt_id
                            , recon_header_id = all_99x_data (idx).header_id
                            , last_update_date = SYSDATE
                        WHERE ROWID = all_99x_data (idx).x99x_rowid;
                       -- Split the Batch for NABCRD.
                       -- Check if it was already split in an earlier run.
                       IF all_99x_data (idx).processor_id = 'NABCRD'
                          AND SUBSTR (all_99x_data (idx).bank_rec_id, -2, 2) !=
                                   '-'
                                || NVL (SUBSTR (all_99x_data (idx).ajb_card_type
                                              , 1
                                              , 1
                                               )
                                      , 'V'
                                       )
                       THEN
                          UPDATE xx_ce_ajb996
                             SET bank_rec_id =
                                       bank_rec_id
                                    || '-'
                                    || NVL
                                          (SUBSTR
                                                 (all_99x_data (idx).ajb_card_type
                                                , 1
                                                , 1
                                                 )
                                         , 'V'
                                          )
                               , last_update_date = SYSDATE
                           WHERE ROWID = all_99x_data (idx).x99x_rowid;
                       END IF;                                        -- If NABCRD
                    ELSE
                       IF all_99x_data (idx).processor_id = 'NABCRD'
             --- Added for defect 14688
             AND SUBSTR (all_99x_data (idx).bank_rec_id, -2, 2) !=
                                   '-'
                                || NVL (SUBSTR (all_99x_data (idx).ajb_card_type
                                              , 1
                                              , 1
                                               )
                                      , 'V'
                                       )
                       THEN
                          UPDATE xx_ce_ajb996
                             SET status = 'NOTMATCHED'
                               , last_update_date = SYSDATE
                           WHERE ROWID = all_99x_data (idx).x99x_rowid;
                       END IF;                                            --NABCRD
                    END IF;                         -- Cash_receipt_id is not null
                 END LOOP;                                        -- 99x_data loop
              END LOOP;                                               --996_cr_cur
              COMMIT;
              CLOSE all_996_cr_cur;
           EXCEPTION
              WHEN OTHERS
              THEN
                 CLOSE all_996_cr_cur;
                 ROLLBACK TO lc_996_savepoint;
                 IF SQLCODE = -54
                 THEN
                    od_message
                       ('M'
                      , '996 CreditCard data is being matched to AR by other request/user'
                       );
                 ELSE
                    od_message ('M'
                              , 'Error/Warning:' || SQLCODE || '-' || SQLERRM
                               );
                 END IF;
           END;                                                   --all_996_cr_cur
           --*********Added for defect 15775*************
            BEGIN
                fnd_file.put_line (fnd_file.LOG
                         , 'Update the Recon Header Id for all the unmatched 996 records'
                          );
                all_99x_data := all_99x_null;
                SAVEPOINT lc_996_unmatched_savepoint;
                OPEN all_996_unmatched_cr_cur;
                LOOP
                   FETCH all_996_unmatched_cr_cur
                   BULK COLLECT INTO all_996_unmatched_data LIMIT p_batch_size;
                   EXIT WHEN all_996_unmatched_data.COUNT = 0;
                   FOR idx IN all_996_unmatched_data.FIRST .. all_996_unmatched_data.LAST
                   LOOP
                    IF all_996_unmatched_data (idx).processor_id = 'DCV3RN' THEN
                      lc_card_type := 'DISCOVER';
                    ELSE
                    lc_card_num := SUBSTR(all_996_unmatched_data (idx).card_num,1,2);
                    lc_card_type := XX_CM_TRACK_LOG_PKG.get_card_type(all_996_unmatched_data (idx).processor_id
                                    ,all_996_unmatched_data (idx).ajb_file_name
                                    ,all_996_unmatched_data (idx).provider_type
                                    ,lc_card_num);
                    END IF;
                    fnd_file.put_line (fnd_file.LOG
                         , 'lc_card_type : '|| lc_card_type||'  '||'provider_type: '||all_996_unmatched_data (idx).provider_type
                          );
                    IF lc_card_type is NULL THEN
                      fnd_file.put_line (fnd_file.LOG
                         , 'Card Type is NULL for the processor_id : '|| all_996_unmatched_data (idx).processor_id
                          );
                    ELSE
                      BEGIN
                        SELECT HEADER_ID
                        INTO ln_recon_header_id
                        FROM xx_ce_recon_glact_hdr_v
                        WHERE AJB_CARD_TYPE = lc_card_type
                        AND PROVIDER_CODE = all_996_unmatched_data (idx).processor_id;
                      fnd_file.put_line (fnd_file.LOG
                         , 'recon_header_id:'||  ln_recon_header_id
                          );
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                          fnd_file.put_line (fnd_file.LOG
                            , 'No recon header id found for the card type : '
                            ||lc_card_type ||' and for the processor_id : '
                            || all_996_unmatched_data (idx).processor_id
                            );
                        WHEN OTHERS THEN
                          od_message ('M'
                          , 'Error/Warning:' || SQLCODE || '-' || SQLERRM
                          );
                      END;
                      UPDATE XX_CE_AJB996
                      SET RECON_HEADER_ID = ln_recon_header_id
                      WHERE ROWID = all_996_unmatched_data (idx).x99x_rowid;
                    END IF;
                   END LOOP;                                        -- 99x_data loop
                END LOOP;                                               --996_cr_cur
                COMMIT;
                CLOSE all_996_unmatched_cr_cur;
               EXCEPTION
                WHEN OTHERS
                THEN
                   CLOSE all_996_unmatched_cr_cur;
                   ROLLBACK TO lc_996_unmatched_savepoint;
                   IF SQLCODE = -54
                   THEN
                    od_message
                     ('M'
                    , '996 CreditCard data is being updated by other request/user'
                     );
                   ELSE
                    od_message ('M'
                        , 'Error/Warning:' || SQLCODE || '-' || SQLERRM
                         );
                   END IF;
               END;                                                   --all_996_unmatched_cr_cur
           --*****End of change for defect 15775**********
         BEGIN
            fnd_file.put_line (fnd_file.LOG
                             , 'Match Non-CreditCard 996 Transactions to AR.'
                              );
            all_99x_data := all_99x_null;
            SAVEPOINT lc_996_savepoint;
            OPEN all_996_non_cr_cur;
            LOOP
               FETCH all_996_non_cr_cur
               BULK COLLECT INTO all_99x_data LIMIT p_batch_size;
               EXIT WHEN all_99x_data.COUNT = 0;
               FOR idx IN all_99x_data.FIRST .. all_99x_data.LAST
               LOOP
                  -- If matching AR record and Recon Setup is found
                  IF all_99x_data (idx).cash_receipt_id IS NOT NULL
                     --Defect 10048
                     AND all_99x_data (idx).header_id IS NOT NULL
                  THEN
                     UPDATE xx_ce_ajb996
                        SET status = 'MATCHED_AR'
                          , ar_cash_receipt_id =
                                              all_99x_data (idx).cash_receipt_id
                          , recon_header_id = all_99x_data (idx).header_id
                          , last_update_date = SYSDATE
                      WHERE ROWID = all_99x_data (idx).x99x_rowid;
                      -- Split the Batch for NABCRD.
                     -- Check if it was already split in an earlier run.
                     IF all_99x_data (idx).processor_id = 'NABCRD'
                        AND SUBSTR (all_99x_data (idx).bank_rec_id, -2, 2) !=
                                 '-'
                              || NVL (SUBSTR (all_99x_data (idx).ajb_card_type
                                            , 1
                                            , 1
                                             )
                                    , 'V'
                                     )
                     THEN
                        UPDATE xx_ce_ajb996
                           SET bank_rec_id =
                                     bank_rec_id
                                  || '-'
                                  || NVL
                                        (SUBSTR
                                               (all_99x_data (idx).ajb_card_type
                                              , 1
                                              , 1
                                               )
                                       , 'V'
                                        )
                             , last_update_date = SYSDATE
                         WHERE ROWID = all_99x_data (idx).x99x_rowid;
                     END IF;                                        -- If NABCRD
                  ELSE
                     IF all_99x_data (idx).processor_id = 'NABCRD'
                     THEN
                        UPDATE xx_ce_ajb996
                           SET status = 'NOTMATCHED'
                             , last_update_date = SYSDATE
                         WHERE ROWID = all_99x_data (idx).x99x_rowid;
                     END IF;
                  END IF;                         -- cash receipt is is not null
               END LOOP;                                             -- 99x loop
            END LOOP;                                      --996_non_cr_cur loop
            COMMIT;
            CLOSE all_996_non_cr_cur;
         EXCEPTION
            WHEN OTHERS
            THEN
               CLOSE all_996_non_cr_cur;
               ROLLBACK TO lc_996_savepoint;
               IF SQLCODE = -54
               THEN
                  od_message
                     ('M'
                    , '996 NABCARD BankRecID is being by updated by other request/user'
                     );
               ELSE
                  od_message ('M'
                            , 'Error/Warning:' || SQLCODE || '-' || SQLERRM
                             );
               END IF;
         END;                                               --all_996_non_cr_cur
         BEGIN
            fnd_file.put_line
               (fnd_file.LOG
              , 'Update BankRecID for Non-AR-Matched 996 Transactions for NABCRD.'
               );
            all_99x_data := all_99x_null;
            SAVEPOINT lc_996_savepoint;
            OPEN all_996_no_cardtype_cur;
            LOOP
               FETCH all_996_no_cardtype_cur
               BULK COLLECT INTO all_99x_data LIMIT p_batch_size;
               EXIT WHEN all_99x_data.COUNT = 0;
               FOR idx IN all_99x_data.FIRST .. all_99x_data.LAST
               LOOP
                  UPDATE xx_ce_ajb996
                     SET status = 'PREPROCESSED'
                       , bank_rec_id = bank_rec_id || '-V'
                       , last_update_date = SYSDATE
                   WHERE ROWID = all_99x_data (idx).x99x_rowid;
               END LOOP;
            END LOOP;
         EXCEPTION
            WHEN OTHERS
            THEN
               CLOSE all_996_non_cr_cur;
               ROLLBACK TO lc_996_savepoint;
               IF SQLCODE = -54
               THEN
                  od_message
                     ('M'
                    , '996 Non-CreditCard data is being matched to AR by other request/user'
                     );
               ELSE
                  od_message ('M'
                            , 'Error/Warning:' || SQLCODE || '-' || SQLERRM
                             );
               END IF;
         END;
      END IF;                        -- NVL (p_file_type, 'ALL') IN ('996', ALL)
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, LPAD ('-', 100, '-'));
      /* Process the 998 p_file_type */
      IF NVL (UPPER (p_file_type), 'ALL') IN ('998', 'ALL')
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Preprocessing 998 data...');
         /* Update status */
         UPDATE xx_ce_ajb998
            SET status = 'PREPROCESSING'
          WHERE status IS NULL
            --AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
            AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
         /* Logic from xx_ce_ajb998_t and xx_ce_ajb998_v on xx_ce_ajb998 */
         /* Only open the org_998_cur if it is not already open */
         IF org_998_cur%ISOPEN
         THEN
            NULL;
         ELSE
            OPEN org_998_cur;
            fnd_file.put_line (fnd_file.LOG, 'Preprocessing 998 country/orgs.');
         END IF;
         LOOP
            /* Populate variables using cursor fetch.  No point using bulk collect as < 5 */
            FETCH org_998_cur
             INTO v_country_code;
            /* Keep fetching until no more records are found */
            EXIT WHEN NOT org_998_cur%FOUND;
            BEGIN
               /* Lookup the org_id for the country */
               SELECT xx_fin_country_defaults_pkg.f_org_id (territory_code)
                    , territory_code
                 INTO v_org_id
                    , v_territory_code
                 FROM fnd_territories
                WHERE iso_numeric_code = v_country_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_org_id := NULL;
            END;
            fnd_file.put_line (fnd_file.LOG
                             ,    '  Updating 998 country_code values of '
                               || v_country_code
                               || ' with org_id of '
                               || v_org_id
                               || ' and territory_code of '
                               || v_territory_code
                               || '.'
                              );
            /* Update the source value */
            UPDATE xx_ce_ajb998
               SET org_id = v_org_id
                 , territory_code = v_territory_code
             WHERE status = 'PREPROCESSING'
               AND country_code = v_country_code;
         END LOOP;
         CLOSE org_998_cur;
         fnd_file.put_line (fnd_file.LOG
                          , 'Finished preprocessing 998 country/orgs.'
                           );
         fnd_file.put_line
                      (fnd_file.LOG
                     , 'Updating 998 bank_rec_id values with -XX provider_type.'
                      );
         /* Update status */
         UPDATE xx_ce_ajb998
            SET bank_rec_id =
                      bank_rec_id
                   || '-'
                   || SUBSTR (provider_type, 1, 2)
                   || '-'
                   || territory_code
          WHERE status = 'PREPROCESSING'
            AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
            AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
         fnd_file.put_line
            (fnd_file.LOG
           , 'Finished preprocessing 998 bank_rec_id values with -XX provider_type.'
            );
         /* Only open the currency_998_cur if it is not already open */
         IF currency_998_cur%ISOPEN
         THEN
            NULL;
         ELSE
            OPEN currency_998_cur;
            fnd_file.put_line (fnd_file.LOG, 'Preprocessing 998 currencies.');
         END IF;
         LOOP
            /* Populate variables using cursor fetch.  No point using bulk collect as < 5 */
            FETCH currency_998_cur
             INTO v_currency_code;
            /* Keep fetching until no more records are found */
            EXIT WHEN NOT currency_998_cur%FOUND;
            BEGIN
               /* Lookup the currency for the country */
               SELECT currency_code
                 INTO v_currency
                 FROM fnd_currencies
                WHERE attribute1 = v_currency_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_currency := NULL;
            END;
            fnd_file.put_line (fnd_file.LOG
                             ,    '  Updating 998 currency_code values of '
                               || v_currency_code
                               || ' with currency of '
                               || v_currency
                               || '.'
                              );
            /* Update the source value */
            UPDATE xx_ce_ajb998
               SET currency = v_currency
             WHERE status = 'PREPROCESSING'
               AND currency_code = v_currency_code;
         END LOOP;
         CLOSE currency_998_cur;
         fnd_file.put_line (fnd_file.LOG
                          , 'Finished preprocessing 998 currencies.'
                           );
         /* Only open the bank_998_cur if it is not already open */
         IF bank_998_cur%ISOPEN
         THEN
            NULL;
         ELSE
            OPEN bank_998_cur;
            fnd_file.put_line (fnd_file.LOG, 'Preprocessing 998 bank_rec_ids.');
         END IF;
         LOOP
            /* Populate variables using cursor fetch */
            FETCH bank_998_cur
             INTO v_bank_rec_id;
            /* Keep fetching until no more records are found */
            EXIT WHEN NOT bank_998_cur%FOUND;
            BEGIN
               v_recon_date :=
                          xx_ce_ajb_cc_recon_pkg.get_recon_date (v_bank_rec_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  BEGIN
                     v_recon_date :=
                             TO_DATE (SUBSTR (v_bank_rec_id, 1, 8), 'YYYYMMDD');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_recon_date := TRUNC (SYSDATE);
                  END;
            END;
            fnd_file.put_line (fnd_file.LOG
                             ,    '  Updating 998 bank_rec_id values of '
                               || v_bank_rec_id
                               || ' with recon_date of '
                               || v_recon_date
                               || '.'
                              );
            /* Update the source value */
            UPDATE xx_ce_ajb998
               SET recon_date = v_recon_date
             WHERE status = 'PREPROCESSING'
               AND bank_rec_id = v_bank_rec_id;
         END LOOP;
         CLOSE bank_998_cur;
         fnd_file.put_line (fnd_file.LOG
                          ,    '  Updating 998 NULL recon_date values with '
                            || TRUNC (SYSDATE)
                            || '.'
                           );
         /* Update the source value */
         UPDATE xx_ce_ajb998
            SET recon_date = TRUNC (SYSDATE)
          WHERE status = 'PREPROCESSING'
            AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
            AND recon_date IS NULL;
         fnd_file.put_line (fnd_file.LOG
                          , 'Finished preprocessing 998 bank_rec_ids.'
                           );
         fnd_file.put_line (fnd_file.LOG, 'Preprocessing 998 receipt_nums.');
         /* Update the source value */
         UPDATE xx_ce_ajb998
            SET attribute21 = receipt_num
              , receipt_num =
                   SUBSTR (receipt_num || '#'
                         , 1
                         , INSTR (receipt_num || '#', '#') - 1
                          )
          WHERE status = 'PREPROCESSING'
            AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
            AND provider_type = 'CREDIT'
            AND receipt_num IS NOT NULL;
         fnd_file.put_line (fnd_file.LOG
                          , 'Finished preprocessing 998 country/orgs.'
                           );
         fnd_file.put_line (fnd_file.LOG
                          , 'Updating status of all 998 preprocessed records.'
                           );
         /* Update all bank_rec_ids */
         UPDATE xx_ce_ajb998
            SET status = 'PREPROCESSED'
              , last_update_date = SYSDATE
          WHERE status = 'PREPROCESSING'
            AND org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
         fnd_file.put_line
                    (fnd_file.LOG
                   , 'Finished updating status of all 998 preprocessed records.'
                    );
         fnd_file.put_line (fnd_file.LOG, '998 data preprocessed!');
         /* End of logic from xx_ce_ajb998_t and xx_ce_ajb998_v on xx_ce_ajb998, commit */
         COMMIT;
         --xx_ce_ajb998_ar_v
         BEGIN
            fnd_file.put_line (fnd_file.LOG
                             , 'Match CreditCard 998 Transactions to AR.'
                              );
            all_99x_data := all_99x_null;
            SAVEPOINT lc_998_savepoint;
            OPEN all_998_cr_cur;
            LOOP
               FETCH all_998_cr_cur
               BULK COLLECT INTO all_99x_data LIMIT p_batch_size;
               EXIT WHEN all_99x_data.COUNT = 0;
               FOR idx IN all_99x_data.FIRST .. all_99x_data.LAST
               LOOP
                  -- If matching AR record and Recon Setup is found
                  IF all_99x_data (idx).cash_receipt_id IS NOT NULL
                     --Defect 10048
                     AND all_99x_data (idx).header_id IS NOT NULL
                  THEN
                     UPDATE xx_ce_ajb998
                        SET status = 'MATCHED_AR'
                          , ar_cash_receipt_id =
                                              all_99x_data (idx).cash_receipt_id
                          , recon_header_id = all_99x_data (idx).header_id
                          , last_update_date = SYSDATE
                      WHERE ROWID = all_99x_data (idx).x99x_rowid;
                     -- Split the Batch for NABCRD.
                     IF all_99x_data (idx).processor_id = 'NABCRD'
                     THEN
                        UPDATE xx_ce_ajb998
                           SET bank_rec_id =
                                     bank_rec_id
                                  || '-'
                                  || NVL
                                        (SUBSTR
                                               (all_99x_data (idx).ajb_card_type
                                              , 1
                                              , 1
                                               )
                                       , 'V'
                                        )
                         WHERE ROWID = all_99x_data (idx).x99x_rowid;
                     END IF;
                  END IF;    -- cash receipt id and recon header id is not null.
               END LOOP;
            END LOOP;
            COMMIT;
            CLOSE all_998_cr_cur;
         EXCEPTION
            WHEN OTHERS
            THEN
               IF all_998_cr_cur%ISOPEN
               THEN
                  CLOSE all_998_cr_cur;
               END IF;
               ROLLBACK TO lc_998_savepoint;
               IF SQLCODE = -54
               THEN
                  od_message
                     ('M'
                    , '998 CreditCard data is being matched to AR by other request/user'
                     );
               ELSE
                  od_message ('M'
                            , 'Error/Warning:' || SQLCODE || '-' || SQLERRM
                             );
               END IF;
         END;                                                  -- all_998_cur_cr
         --xx_ce_ajb998_ar_v
         BEGIN
            fnd_file.put_line (fnd_file.LOG
                             , 'Match Non-CreditCard 998 Transactions to AR.'
                              );
            all_99x_data := all_99x_null;
            SAVEPOINT lc_998_savepoint;
            OPEN all_998_non_cr_cur;
            LOOP
               FETCH all_998_non_cr_cur
               BULK COLLECT INTO all_99x_data LIMIT p_batch_size;
               EXIT WHEN all_99x_data.COUNT = 0;
               FOR idx IN all_99x_data.FIRST .. all_99x_data.LAST
               LOOP
                  -- If matching AR record and Recon Setup is found
                  IF all_99x_data (idx).cash_receipt_id IS NOT NULL
                     --Defect 10048
                     AND all_99x_data (idx).header_id IS NOT NULL
                  THEN
                     UPDATE xx_ce_ajb998
                        SET status = 'MATCHED_AR'
                          , ar_cash_receipt_id =
                                              all_99x_data (idx).cash_receipt_id
                          , recon_header_id = all_99x_data (idx).header_id
                          , last_update_date = SYSDATE
                      WHERE ROWID = all_99x_data (idx).x99x_rowid;
                     -- Split the Batch for NABCRD.
                     IF all_99x_data (idx).processor_id = 'NABCRD'
                     THEN
                        UPDATE xx_ce_ajb998
                           SET bank_rec_id =
                                     bank_rec_id
                                  || '-'
                                  || NVL
                                        (SUBSTR
                                               (all_99x_data (idx).ajb_card_type
                                              , 1
                                              , 1
                                               )
                                       , 'V'
                                        )
                         WHERE ROWID = all_99x_data (idx).x99x_rowid;
                     END IF;
                  END IF;    -- cash receipt id and recon header id is not null.
               END LOOP;
            END LOOP;
            COMMIT;
            CLOSE all_998_non_cr_cur;
         EXCEPTION
            WHEN OTHERS
            THEN
               IF all_998_non_cr_cur%ISOPEN
               THEN
                  CLOSE all_998_non_cr_cur;
               END IF;
               ROLLBACK TO lc_998_savepoint;
               IF SQLCODE = -54
               THEN
                  od_message
                     ('M'
                    , '998 Non CreditCard data is being matched to AR by other request/user'
                     );
               ELSE
                  od_message ('M'
                            , 'Error/Warning:' || SQLCODE || '-' || SQLERRM
                             );
               END IF;
         END;                                                  -- all_998_cur_cr
      END IF;                       --NVL (p_file_type, 'ALL') IN ('998', 'ALL')
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, LPAD ('-', 100, '-'));
      /* Process the 999 p_file_type */
      IF NVL (UPPER (p_file_type), 'ALL') IN ('999', 'ALL')
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Preprocessing 999 data...');
         /* Update status */
         UPDATE xx_ce_ajb999
            SET status = 'PREPROCESSING'
          WHERE status IS NULL
           -- AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
            AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
         /* Logic from xx_ce_ajb999_t and xx_ce_ajb999_v on xx_ce_ajb999 */
         /* Only open the org_999_cur if it is not already open */
         IF org_999_cur%ISOPEN
         THEN
            NULL;
         ELSE
            OPEN org_999_cur;
            fnd_file.put_line (fnd_file.LOG, 'Preprocessing 999 country/orgs.');
         END IF;
         LOOP
            /* Populate variables using cursor fetch.  No point using bulk collect as < 5 */
            FETCH org_999_cur
             INTO v_country_code;
            /* Keep fetching until no more records are found */
            EXIT WHEN NOT org_999_cur%FOUND;
            BEGIN
               /* Lookup the org_id for the country */
               SELECT xx_fin_country_defaults_pkg.f_org_id (territory_code)
                    , territory_code
                 INTO v_org_id
                    , v_territory_code
                 FROM fnd_territories
                WHERE iso_numeric_code = v_country_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_org_id := NULL;
            END;
            fnd_file.put_line (fnd_file.LOG
                             ,    '  Updating 999 country_code values of '
                               || v_country_code
                               || ' with org_id of '
                               || v_org_id
                               || ' and territory_code of '
                               || v_territory_code
                               || '.'
                              );
            /* Update the source value */
            UPDATE xx_ce_ajb999
               SET org_id = v_org_id
                 , territory_code = v_territory_code
             WHERE status = 'PREPROCESSING'
               AND country_code = v_country_code;
         END LOOP;
         CLOSE org_999_cur;
         fnd_file.put_line (fnd_file.LOG
                          , 'Finished preprocessing 999 country/orgs.'
                           );
         fnd_file.put_line
                      (fnd_file.LOG
                     , 'Updating 999 bank_rec_id values with -XX provider_type.'
                      );
         /* Update all bank_rec_ids */
         -- Only for NABCRD, split based on cardtype
         UPDATE xx_ce_ajb999
            SET bank_rec_id =
                      bank_rec_id
                   || '-'
                   || SUBSTR (provider_type, 1, 2)
                   || '-'
                   || territory_code
          WHERE status = 'PREPROCESSING'
            AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
            AND processor_id != 'NABCRD'
            AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
         UPDATE xx_ce_ajb999
            SET bank_rec_id =
                      bank_rec_id
                   || '-'
                   || SUBSTR (provider_type, 1, 2)
                   || '-'
                   || territory_code
                   || '-'
                   || NVL (SUBSTR (cardtype, 1, 1), 'V')
          WHERE status = 'PREPROCESSING'
            AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
            AND processor_id = 'NABCRD'
            AND ajb_file_name = NVL (p_ajb_file_name, ajb_file_name);
         fnd_file.put_line
            (fnd_file.LOG
           , 'Finished preprocessing 999 bank_rec_id values with -XX provider_type.'
            );
         /* Only open the currency_999_cur if it is not already open */
         IF currency_999_cur%ISOPEN
         THEN
            NULL;
         ELSE
            OPEN currency_999_cur;
            fnd_file.put_line (fnd_file.LOG, 'Preprocessing 999 currencies.');
         END IF;
         LOOP
            /* Populate variables using cursor fetch.  No point using bulk collect as < 5 */
            FETCH currency_999_cur
             INTO v_currency_code;
            /* Keep fetching until no more records are found */
            EXIT WHEN NOT currency_999_cur%FOUND;
            BEGIN
               /* Lookup the currency for the country */
               SELECT currency_code
                 INTO v_currency
                 FROM fnd_currencies
                WHERE attribute1 = v_currency_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_currency := NULL;
            END;
            fnd_file.put_line (fnd_file.LOG
                             ,    '  Updating 999 currency_code values of '
                               || v_currency_code
                               || ' with currency of '
                               || v_currency
                               || '.'
                              );
            /* Update the source value */
            UPDATE xx_ce_ajb999
               SET currency = v_currency
             WHERE status = 'PREPROCESSING'
               AND currency_code = v_currency_code;
         END LOOP;
         CLOSE currency_999_cur;
         fnd_file.put_line (fnd_file.LOG
                          , 'Finished preprocessing 999 currencies.'
                           );
         /* Only open the bank_999_cur if it is not already open */
         IF bank_999_cur%ISOPEN
         THEN
            NULL;
         ELSE
            OPEN bank_999_cur;
            fnd_file.put_line (fnd_file.LOG, 'Preprocessing 999 bank_rec_ids.');
         END IF;
         LOOP
            /* Populate variables using cursor fetch */
            FETCH bank_999_cur
             INTO v_bank_rec_id;
            /* Keep fetching until no more records are found */
            EXIT WHEN NOT bank_999_cur%FOUND;
            BEGIN
               v_recon_date :=
                          xx_ce_ajb_cc_recon_pkg.get_recon_date (v_bank_rec_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  BEGIN
                     v_recon_date :=
                             TO_DATE (SUBSTR (v_bank_rec_id, 1, 8), 'YYYYMMDD');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_recon_date := TRUNC (SYSDATE);
                  END;
            END;
            fnd_file.put_line (fnd_file.LOG
                             ,    '  Updating 999 bank_rec_id values of '
                               || v_bank_rec_id
                               || ' with recon_date of '
                               || v_recon_date
                               || '.'
                              );
            /* Update the source value */
            UPDATE xx_ce_ajb999
               SET recon_date = v_recon_date
             WHERE status = 'PREPROCESSING'
               AND bank_rec_id = v_bank_rec_id;
         END LOOP;
         CLOSE bank_999_cur;
         fnd_file.put_line (fnd_file.LOG
                          ,    '  Updating 999 NULL recon_date values with '
                            || TRUNC (SYSDATE)
                            || '.'
                           );
         /* Update the source value */
         UPDATE xx_ce_ajb999
            SET recon_date = TRUNC (SYSDATE)
          WHERE status = 'PREPROCESSING'
            AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
            AND recon_date IS NULL;
         fnd_file.put_line
                      (fnd_file.LOG
                     , '  Updating 999 invalid card types to provider defaults.'
                      );
         UPDATE xx_ce_ajb999 a
            SET cardtype = TRIM (cardtype)
          WHERE status = 'PREPROCESSING'
            AND org_id = gn_org_id -- Added for PROD Defect: 2046,1716
            AND cardtype != TRIM (cardtype);
         BEGIN
            all_99x_data := all_99x_null;
            SAVEPOINT lc_998_savepoint;
            FOR bad_999_cardtypes_rec IN bad_999_cardtypes_cur
            LOOP
               lc_default_cardtype :=
                     get_default_card_type (bad_999_cardtypes_rec.processor_id
                                           ,gn_org_id    --Added for Defect #1061
                                           );
               UPDATE xx_ce_ajb999 a
                  SET cardtype = lc_default_cardtype
                WHERE ROWID = bad_999_cardtypes_rec.row_id;
            END LOOP;
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK TO lc_998_savepoint;
               od_message ('M', 'Error/Warning:' || SQLCODE || '-' || SQLERRM);
         END;
         fnd_file.put_line (fnd_file.LOG
                          , 'Updating status of all 999 preprocessed records.'
                           );
         /* Update all bank_rec_ids and status */
         UPDATE xx_ce_ajb999
            SET status = 'PREPROCESSED'
              , last_update_date = SYSDATE
          WHERE status = 'PREPROCESSING'
            AND org_id = gn_org_id; -- Added for PROD Defect: 2046,1716
         fnd_file.put_line
                    (fnd_file.LOG
                   , 'Finished updating status of all 999 preprocessed records.'
                    );
         fnd_file.put_line (fnd_file.LOG, '999 data preprocessed!');
         /* End of logic from xx_ce_ajb999_t and xx_ce_ajb999_v on xx_ce_ajb999, commit */
         COMMIT;
      END IF;                        -- NVL (p_file_type, 'ALL') IN ('999', ALL)
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, LPAD ('-', 100, '-'));
      fnd_file.put_line (fnd_file.LOG
                       ,    'Finishing xx_ce_ajb_inbound_preprocess at '
                         || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                        );
   END xx_ce_ajb_inbound_preprocess;
   PROCEDURE od_message (
      p_msg_type         IN   VARCHAR2
    , p_msg              IN   VARCHAR2
    , p_msg_loc          IN   VARCHAR2 DEFAULT NULL
    , p_addnl_line_len   IN   NUMBER DEFAULT 110
   )
   IS
      ln_char_count   NUMBER := 0;
      ln_line_count   NUMBER := 0;
   BEGIN
      IF p_msg_type = 'M'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_msg);
      ELSIF p_msg_type = 'O'
      THEN
         /* If message cannot fit on one line,
         -- break into multiple lines */-- fnd_file.put_line(fnd_file.output, p_msg);
         IF NVL (LENGTH (p_msg), 0) > 120
         THEN
            FOR x IN 1 .. (TRUNC ((LENGTH (p_msg) - 120) / p_addnl_line_len) + 2
                          )
            LOOP
               ln_line_count := NVL (ln_line_count, 0) + 1;
               IF ln_line_count = 1
               THEN
                  fnd_file.put_line (fnd_file.output, SUBSTR (p_msg, 1, 120));
                  ln_char_count := NVL (ln_char_count, 0) + 120;
               ELSE
                  fnd_file.put_line (fnd_file.output
                                   ,    LPAD (' ', 120 - p_addnl_line_len, ' ')
                                     || SUBSTR (LTRIM (p_msg)
                                              , ln_char_count + 1
                                              , p_addnl_line_len
                                               )
                                    );
                  ln_char_count := NVL (ln_char_count, 0) + p_addnl_line_len;
               END IF;
            END LOOP;
         ELSE
            fnd_file.put_line (fnd_file.output, p_msg);
         END IF;
      ELSIF p_msg_type = 'E'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_msg);
         DECLARE
            l_return_code             VARCHAR2 (1)                       := 'E';
            l_msg_count               NUMBER                               := 1;
            ln_request_id             NUMBER
                                       := fnd_profile.VALUE ('CONC_REQUEST_ID');
            lc_conc_prog_short_name   fnd_concurrent_programs.concurrent_program_name%TYPE;
         BEGIN
            SELECT concurrent_program_name
              INTO lc_conc_prog_short_name
              FROM fnd_concurrent_requests fcr, fnd_concurrent_programs_vl fcp
             WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
               AND fcr.request_id = ln_request_id;
            xx_com_error_log_pub.log_error
                                     (p_program_type => 'CONCURRENT PROGRAM'
                                    , p_program_name => lc_conc_prog_short_name
                                    , p_program_id => ln_request_id
                                    , p_module_name => 'xxfin'
                                    , p_error_location => p_msg_loc
                                    , p_error_message_count => 1
                                    , p_error_message_code => 'E'
                                    , p_error_message => p_msg || ' / '
                                       || SQLCODE || ':' || SQLERRM
                                    , p_error_message_severity => 'MAJOR'
                                    , p_notify_flag => 'N'
                                    , p_object_type => 'OD Refunds'
                                    , p_object_id => NULL
                                    , p_return_code => l_return_code
                                    , p_msg_count => l_msg_count
                                     );
         -- COMMIT;
         END;
      END IF;
   END od_message;
END xx_ce_ajb_cc_recon_pkg;
/
show err;
/