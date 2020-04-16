SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE XX_AR_SUBSC_ITEM_REV_REC_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_AR_SUBSC_ITEM_REV_REC_PKG                                                            |
  -- |                                                                                            |
  -- |  Description: This package body is for identifying Subscription Items are eligible 
  --                 for REV REc and insert into XX_AR_SUBSCRIPTION_ITEMS              |
  -- |                                                                                |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         08/Apr/2020   M K Pramod Kumar     Initial version                              |
  -- +============================================================================================+
  
  /****************
  * MAIN PROCEDURE *
  ****************/
PROCEDURE MAIN_ITEM_REV_REC_PROCESS(
    errbuff OUT VARCHAR2,
    retcode OUT NUMBER);
	  
	
	


  
END XX_AR_SUBSC_ITEM_REV_REC_PKG;
/
show errors;
exit;