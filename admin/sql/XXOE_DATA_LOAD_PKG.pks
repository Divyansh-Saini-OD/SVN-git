create or replace PACKAGE XXOE_DATA_LOAD_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Optimize                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name      :  XX_OE_DATA_LOAD_PKG                                                          |
  -- |  RICE ID   :                                              |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0      28-Apr-2021      Shreyas Thorat            Initial draft version  |
  -- +============================================================================================+
  PROCEDURE XXOE_DATA_LOAD_PRC(
      ERRBUF OUT VARCHAR2,
      RETCODE OUT VARCHAR2);
  PROCEDURE XXOE_VALIDATE_DATA ( P_START_ID IN VARCHAR2 , P_END_ID IN VARCHAR2 ) ;
  PROCEDURE xxoe_populate_columns(
	ERRBUF OUT VARCHAR2,
	RETCODE OUT VARCHAR2);
  --PROCEDURE XXOE_PROCESS_DATA ( P_START_ID IN VARCHAR2 , P_END_ID IN VARCHAR2 ) ;
  PROCEDURE xxom_load_data ( P_START_ID IN VARCHAR2 , P_END_ID IN VARCHAR2 );
	
END XXOE_DATA_LOAD_PKG;