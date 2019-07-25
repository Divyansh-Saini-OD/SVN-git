SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE xx_ar_subscriptions_mt_pkg 
AS
-- +================================================================================+
-- |  Office Depot                                                                  |
-- +================================================================================+
-- |  Name:  XX_AR_SUBSCRIPTIONS_MT_PKG                                             |
-- |                                                                                |
-- |  Description:  This package body is to process subscription billing            |
-- |                                                                                |
-- |  Change Record:                                                                |
-- +================================================================================+
-- | Version     Date         Author              Remarks                           |
-- | =========   ===========  =============       ==================================|
-- | 1.0         11-DEC-2017  Sreedhar Mohan      Initial version                   |
-- | 2.0         03-JAN-2018  Jai Shankar Kumar   Changed incorporated as per MD70  |
-- | 3.0         07-MAR-2018  Sahithi Kunnuru     Modified PACKAGE                  |
-- | 4.0         16-JAN-2019  Punit Gupta         Changed for NAIT-78415            |
-- | 5.0         26-MAR-2019  Sahithi K           Update SCM with trans_id for      |
-- |                                              existing contracts NAIT-89231     |
-- | 6.0         22-APR-2019  Dattatray Bachate   Added New Procedure - NAIT-83868  |
-- | 7.0         03-MAY-2019  Kayeed / Arvind     Added New Procedure - NAIT-93356  |
-- | 8.0         03-MAY-2019  Dattatray Bachate   Added New Procedure - NAIT-93356  |
-- | 9.0         20-JUN-2019  Punit Gupta         Added New Procedure - NAIT-72201  |
-- | 10.0        25-JUL-2019  Sahithi K           Added New Procedure - NAIT-101994 |
-- +================================================================================+

  /******
  * MAIN
  ******/

  PROCEDURE process_eligible_subscriptions(errbuff            OUT VARCHAR2,
                                           retcode            OUT NUMBER,
                                           p_debug_flag       IN  VARCHAR2 DEFAULT 'N',
                                           p_populate_invoice IN  VARCHAR2,
                                           p_create_receipt   IN  VARCHAR2,
                                           p_email_flag       IN  VARCHAR2,
                                           p_history_flag     IN  VARCHAR2);
  /******************************
  *  Import Contract Information
  ******************************/

  PROCEDURE import_contract_info(errbuff      OUT VARCHAR2,
                                 retcode      OUT NUMBER,
                                 p_debug_flag IN  VARCHAR2 DEFAULT 'N');
                                          
  /**************************************
  *  Import Recurring Billing Information
  **************************************/

  PROCEDURE import_recurring_billing_info(errbuff      OUT VARCHAR2,
                                          retcode      OUT NUMBER,
                                          p_debug_flag IN  VARCHAR2 DEFAULT 'N');

  /**************************************
  *  Auto Invoice Wrapper Program
  **************************************/
  PROCEDURE process_auto_invoice(errbuff      OUT  VARCHAR2,
                                 retcode      OUT  VARCHAR2,
                                 p_debug_flag IN   VARCHAR2 DEFAULT 'N');
  /**************************************
  *  Auto Renewal Email Program
  **************************************/
  PROCEDURE send_email_autorenew(errbuff      OUT  VARCHAR2,
                                 retcode      OUT  NUMBER,
                                 p_debug_flag IN   VARCHAR2 DEFAULT 'N');
                                 
  /**************************************
  * Procedure to generate billing history
  **************************************/

  PROCEDURE generate_bill_history_payload(errbuff            OUT VARCHAR2,
                                          retcode            OUT NUMBER,
                                          p_file_path        IN  VARCHAR2,
                                          p_debug_flag       IN  VARCHAR2 DEFAULT 'N',
                                          p_text_value       IN  VARCHAR2);
                                          
  /*********************************************************
  * Procedure to get trans id by performing $0 authorization
  *********************************************************/

  PROCEDURE update_trans_id_scm(errbuff            OUT VARCHAR2,
                                retcode            OUT NUMBER,
                                p_debug_flag       IN  VARCHAR2 DEFAULT 'N');

  /********************************************
  * Procedure to Purge Subscription Payload and
  * Error Table's more than 30 day's older data
  ********************************************/
  PROCEDURE xx_ar_subs_payload_purge_prc (errbuff   OUT       VARCHAR2,
                                          retcode   OUT       NUMBER
                                          );
                                          
  /*************************************************
  * Procedure for Closed Stores Accounting Remapping
  *************************************************/

  PROCEDURE get_store_close_info(p_store_number IN         VARCHAR2,
                                 x_store_info   OUT NOCOPY VARCHAR2
                                 );

  /***********************************
  * Procedure to validate the location
  ***********************************/

  PROCEDURE xx_relocation_store_vald_prc(errbuff        OUT       VARCHAR2,
                                         retcode        OUT       NUMBER
                                        );

  /*********************************************************
  * Procedure to update the receipt number for AB customers
  **********************************************************/
  PROCEDURE txn_receiptnum_update(errbuff      OUT VARCHAR2,
                                  retcode      OUT VARCHAR2,
                                  p_debug_flag IN  VARCHAR2);

  /***********************************************************************************
  * Procedure to write off invoice related to TERMINATED AND CLOSED contracts in SCM *
  ***********************************************************************************/
  PROCEDURE process_adjustments(errbuff        OUT VARCHAR2
                               ,retcode        OUT NUMBER
                               ,p_debug_flag   IN  VARCHAR2 DEFAULT 'N'
                               );
END;
/
