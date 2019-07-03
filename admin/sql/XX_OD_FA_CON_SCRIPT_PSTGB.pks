SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
  
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE XX_OD_FA_CON_SCRIPT_PSTGB
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_OD_FA_CON_SCRIPT_PSTGB                                                           |
  -- |                                                                                            |
  -- |  Description:Scripts for FA conversion   |
  -- |  RICE ID   :                |
  -- |  Description:           |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         01-JUL-2019   Priyam S           Initial Version  added                           |
  -- +============================================================================================|
  procedure XX_OD_FA_CON_SCRIPT_wrapper(
      P_ERRBUF         VARCHAR2,
      p_retcode        number,
      P_module varchar2,
      P_BOOK_TYPE_CODE VARCHAR2,
      p_book_class     varchar2);
      
/*  FUNCTION xx_gl_beacon_mapping_f1(
      p_source VARCHAR2,
      p_type   varchar2,
      p_flag   varchar2) return varchar2;*/
END XX_OD_FA_CON_SCRIPT_PSTGB;
/

SHOW ERRORS;