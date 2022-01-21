SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE XX_CE_MRKTPLC_INVOKE_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_CE_MRKTPLC_INVOKE_PKG                                                          |
  -- |                                                                                            |
  -- |  Description: This package body is for Settlement and Reconciliation for MarketPlaces      |
  -- |  RICE ID   :  I3091_CM MarketPlaces Settlement and Reconciliation-Redesign                                      |
  -- |  Description:  Insert from MRKPLC HDR and DTL records into XX_CE_AJB996,XX_CE_AJB998,        |
  -- |                                                                        XX_CE_AJB999        |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         05/23/2018   M K Pramod Kumar     Initial version                              |
  -- +============================================================================================+
  /****************
  * MAIN PROCEDURE *
  ****************/
  PROCEDURE MAIN_MPL_INVOKE_PROC(
      errbuff OUT VARCHAR2,
      retcode OUT NUMBER,
      p_market_place   IN VARCHAR2,
      p_debug_flag     IN VARCHAR2 DEFAULT 'N' );
	  
END XX_CE_MRKTPLC_INVOKE_PKG;
/
