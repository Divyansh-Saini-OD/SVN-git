SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE xx_ar_subscriptions_mt_pkg 
AS
-- +===============================================================================+
-- |  Office Depot                                                                 |
-- +===============================================================================+
-- |  Name:  XX_AR_SUBSCRIPTIONS_MT_PKG                                            |
-- |                                                                               |
-- |  Description:  This package body is to process subscription billing           |
-- |                                                                               |
-- |  Change Record:                                                               |
-- +===============================================================================+
-- | Version     Date         Author              Remarks                          |
-- | =========   ===========  =============       =================================|
-- | 1.0         11-DEC-2017  Sreedhar Mohan      Initial version                  |
-- | 2.0         03-JAN-2018  Jai Shankar Kumar   Changed incorporated as per MD70 |
-- | 3.0         07-MAR-2018  Sahithi Kunnuru     Modified PACKAGE                 |
-- | 4.0         06-AUG-2018  Punit Gupta         Added Function for the Report    |
-- |                                              OD: Subscription Billing Auth    |
-- |                                              Failures Report as per NAIT-50736|
-- +===============================================================================+                                                                         
  
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
								 
  /*******************************************
  *  Function to fetch the Subscription Errors
  ********************************************/
  FUNCTION xx_ar_subscr_errors(p_contract_number IN VARCHAR2,
                               p_contract_id IN NUMBER,
                               p_billing_sequence_number IN NUMBER)
							   RETURN VARCHAR2;
								 
END;
/
