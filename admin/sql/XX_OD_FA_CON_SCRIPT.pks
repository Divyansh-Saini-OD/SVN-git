SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
  
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE XX_OD_FA_CON_SCRIPT
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_OD_FA_CON_SCRIPT                                                           |
  -- |                                                                                            |
  -- |  Description:Scripts for FA conversion   |
  -- |  RICE ID   :                |
  -- |  Description:           |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         01-APR-2019   Priyam S           Initial Version  added                           |
  -- +============================================================================================|
  procedure xx_od_fa_con_script_wrapper(
      P_ERRBUF         VARCHAR2,
      p_retcode        number,
      P_module varchar2,
      P_BOOK_TYPE_CODE VARCHAR2,
      P_BOOK_CLASS     VARCHAR2);
END XX_OD_FA_CON_SCRIPT;
/

SHOW ERRORS;