SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE      XX_CE_MRKTPLC_LOAD_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_CE_MRKTPLC_LOAD_PKG                                                             |
  -- |                                                                                            |
  -- |  Description: This package body is to Load MarketPlaces DataFiles |
  -- |  RICE ID   :  I3123_CM MarketPlaces Expansion                |
  -- |  Description:  Load Program for for all marketplaces            |
  -- |                                                                                |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         05/23/2018   M K Pramod Kumar     Initial version                              |
  -- +============================================================================================+
  /****************
  * MAIN PROCEDURE *
  ****************/
   P_FROM_DATE VARCHAR2(100);
   p_to_date varchar2(100);
TYPE varchar2_table
IS
  TABLE OF VARCHAR2(32767) INDEX BY BINARY_INTEGER;
  PROCEDURE parse(
      p_delimstring IN VARCHAR2 ,
      p_table OUT varchar2_table ,
      p_nfields OUT INTEGER ,
      p_delim IN VARCHAR2 DEFAULT chr(
        9) ,
      p_error_msg OUT VARCHAR2 ,
      p_retcode OUT VARCHAR2);
   PROCEDURE load_ebay_files(
      p_errbuf OUT VARCHAR2 ,
      p_retcode OUT VARCHAR2 ,
      p_process_name VARCHAR2,
      p_file_name    VARCHAR2,
      p_file_type    VARCHAR2,
      p_debug_flag VARCHAR2,
	  p_request_id number );
  PROCEDURE main_mpl_load_proc(
      p_market_place IN VARCHAR2,
      p_file_name    IN VARCHAR2,
      P_DEBUG_FLAG   IN VARCHAR2 DEFAULT 'N',
	  p_request_id IN NUMBER );
    
 function beforeReport return boolean;
END XX_CE_MRKTPLC_LOAD_PKG;

/

SHOW ERRORS;