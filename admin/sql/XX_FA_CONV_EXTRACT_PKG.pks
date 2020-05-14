SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE XX_FA_CONV_EXTRACT_PKG

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
AS
  P_BOOK_TYPEC VARCHAR2(50);
  TYPE ASSET_ERROR_DETAILS_REC
IS
  RECORD
  (
    ASSET_NUMBER XX_FA_CONV_ASSET_HDR.ASSET_ID%type ,
    BOOK_TYPE_CODE XX_FA_CONV_ASSET_HDR.BOOK_TYPE_CODE%type ,
    ASSET_DESCRIPTION XX_FA_CONV_ASSET_HDR.ASSET_DESCRIPTION%type ,
    TRANSACTION_NAME XX_FA_CONV_ASSET_HDR.TRANSACTION_NAME%type ,
    ASSET_TYPE XX_FA_CONV_ASSET_HDR.ASSET_TYPE%type,
    COST XX_FA_CONV_ASSET_HDR.COST%type ,
    DEPRECIATION_RESERVE XX_FA_CONV_ASSET_HDR.DEPRECIATION_RESERVE%type ,
    YTD_DEPRECIATION XX_FA_CONV_ASSET_HDR.YTD_DEPRECIATION%type ,
    LIFE_IN_MONTHS XX_FA_CONV_ASSET_HDR.LIFE_IN_MONTHS%type ,
    ASSET_UNITS XX_FA_CONV_ASSET_HDR.ASSET_UNITS%type ,
    DATE_PLACED_IN_SERVICE XX_FA_CONV_ASSET_HDR.DATE_PLACED_IN_SERVICE%type ,
    UNITS_ASSIGNED XX_FA_CONV_ASSET_DTL.UNITS_ASSIGNED%type ,
    ERROR_DESCRIPTION XX_FA_CONV_ASSET_HDR.ERROR_DESCRIPTION%type );
TYPE ASSET_ERROR_DETAILS_TBL
IS
  TABLE OF XX_FA_CONV_EXTRACT_PKG.ASSET_ERROR_DETAILS_REC;
  FUNCTION XX_FA_ASSET_ERROR_DETAILS(P_BOOK_TYPEC VARCHAR2)
    RETURN XX_FA_CONV_EXTRACT_PKG.ASSET_ERROR_DETAILS_TBL PIPELINED;
  FUNCTION BEFOREREPORT
    RETURN BOOLEAN;
  PROCEDURE XX_OD_FA_CON_SCRIPT_wrapper(
      P_ERRBUF         VARCHAR2,
      p_retcode        NUMBER,
      P_module         VARCHAR2,
      P_BOOK_TYPE_CODE VARCHAR2,
      p_book_class     VARCHAR2,
      p_extract_type   VARCHAR2);
  PROCEDURE XX_FA_ASSET_DEPR_EXTRACT(
      P_ERRBUF OUT VARCHAR2,
      p_retcode OUT NUMBER,
      P_BOOK_TYPE_CODE VARCHAR2);
  FUNCTION xx_gl_beacon_mapping_f1(
      p_source VARCHAR2,
      p_type   VARCHAR2,
      p_flag   VARCHAR2)
    RETURN VARCHAR2;
END XX_FA_CONV_EXTRACT_PKG;
/
SHOW ERRORS;