SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE xx_ar_subcription_authfail_pkg
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_AR_SUBCRIPTION_AUTHFAIL_PKG                                                     |
  -- |                                                                                            |
  -- |  Description:  This package is to used to Email Payment Authorization Report to all the    |
  -- |                Impacted Vendors who have taken the Subscriptions                           |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         05-SEP-2018  PUNIT_CG         Initial version  for Defect# NAIT-50736          |
  -- +============================================================================================+

  /******
  * MAIN
  ******/

  PROCEDURE email_authfail_rpt_vendor(errbuff       OUT VARCHAR2,
                                      retcode       OUT VARCHAR2,
                                      p_as_of_date  IN  VARCHAR2,
                                      p_debug_flag  IN  VARCHAR2,
                                      p_send_email  IN  VARCHAR2);
END;
/
SHOW ERRORS;
EXIT;