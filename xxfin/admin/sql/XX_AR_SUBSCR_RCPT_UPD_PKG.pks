SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_ar_subscr_rcpt_upd_pkg
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_AR_SUBSCR_RCPT_UPD_PKG                                                          |
  -- |                                                                                            |
  -- |  Description:  This package is to used to update the Receipt Numbers in the Subscriptions  |
  -- |                table for AB Customers where the receipt_number is NULL                     |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         15-NOV-2018  PUNIT_CG         Initial version  for Defect# NAIT-72201          |
  -- +============================================================================================+

  /******
  * MAIN
  ******/

  PROCEDURE txn_receiptnum_update(errbuff       OUT VARCHAR2,
                                  retcode       OUT VARCHAR2,
                                  p_debug_flag  IN  VARCHAR2);
END;
/
SHOW ERRORS;
EXIT;