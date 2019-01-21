SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE XX_AP_SMB_INT_MKTPLACE_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_AP_SMB_INT_MKTPLACE_PKG                                                      |
  -- |  RICE ID   :                                                                            |
  -- |  Description:                                                                       |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- |1.0          10/09/2018   Arun DSouza      Initial Version - SMB Internal Marketplace       |
  -- +============================================================================================+
  v_inv_num VARCHAR2(200); ---- Added NAIT-48272 (Defect#45304)
  v_ven_num VARCHAR2(200); ---- Added NAIT-48272 (Defect#45304)
  v_po_num  VARCHAR2(200); ---- Added NAIT-48272 (Defect#45304)
  PROCEDURE log_exception(
      p_program_name   IN VARCHAR2 ,
      p_error_location IN VARCHAR2 ,
      p_error_msg      IN VARCHAR2);
  PROCEDURE load_prestaging(
      p_errbuf OUT VARCHAR2 ,
      p_retcode OUT VARCHAR2 ,
      p_filepath  IN VARCHAR2 ,
      p_source    IN VARCHAR2 ,
      p_file_name IN VARCHAR2 ,
      p_debug     IN VARCHAR2);
  PROCEDURE load_data_to_staging_smb(
      p_errbuf OUT VARCHAR2 ,
      p_retcode OUT VARCHAR2 ,
      p_source    IN VARCHAR2 ,
      p_debug     IN VARCHAR2 ,
      p_from_date IN VARCHAR2 ,
      p_to_date   IN VARCHAR2 );
END XX_AP_SMB_INT_MKTPLACE_PKG;
/

SHOW ERRORS;