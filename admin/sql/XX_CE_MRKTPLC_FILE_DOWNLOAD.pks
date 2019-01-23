SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
  
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_CE_MRKTPLC_FILE_DOWNLOAD
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_CE_MRKTPLC_FILE_DOWNLOAD                                                           |
  -- |                                                                                            |
  -- |  Description: Download File for Marketplaces   |
  -- |  RICE ID   : I3123_CM MarketPlaces Expansion               |
  -- |  Description: Download File for Marketplaces          |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         11-JAN-2019   Priyam S           Initial Version  added    Newegg API file donwnload UTL_HTTP Version                         |
  -- +============================================================================================|
  PROCEDURE xx_ce_newegg_utl_https(
      p_process_name VARCHAR2,
      p_request_id   NUMBER,
      p_debug_flag   VARCHAR2,
      p_file_name    VARCHAR2);

END XX_CE_MRKTPLC_FILE_DOWNLOAD;
/

SHOW ERRORS;