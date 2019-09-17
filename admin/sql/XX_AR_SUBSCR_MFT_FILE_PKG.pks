SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE xx_ar_subscr_mft_file_pkg
AS
  -- +=========================================================================
  -- ===================+
  -- |  Office Depot
  -- |
  -- +=========================================================================
  -- ===================+
  -- |  Name:  XX_AR_SUBSCR_MFT_FILE_PKG
  -- |
  -- |
  -- |
  -- |  Description:  This package is to used to update the Receipt Numbers in
  -- the Subscriptions  |
  -- |                table for AB Customers where the receipt_number is NULL
  -- |
  -- |
  -- |
  -- |  Change Record:
  -- |
  -- +=========================================================================
  -- ===================+
  -- | Version     Date         Author           Remarks
  -- |
  -- | =========   ===========  =============    ==============================
  -- =================  |
  -- | 1.0         05-JUN-2019  PUNIT_CG         Initial version  for Defect#
  -- NAIT-95909
  -- | 1.1         17-SEP-19    Priyam P         added wrapper program to be
  -- called from Shell script
  -- +=========================================================================
  -- ===================+
  /******
  * MAIN
  ******/
  PROCEDURE mft_generate_file(
      p_errbuf OUT VARCHAR2,
      p_retcode OUT VARCHAR2,
      p_debug_flag IN VARCHAR2,
      p_as_of_date IN VARCHAR2);
  PROCEDURE mft_generate_file_wrapper(
      p_debug_flag IN VARCHAR2,
      p_as_of_date IN VARCHAR2);
END;
/
SHOW ERRORS;
EXIT;