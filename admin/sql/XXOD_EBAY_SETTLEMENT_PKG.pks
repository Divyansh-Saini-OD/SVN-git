CREATE OR REPLACE PACKAGE XXOD_EBAY_SETTLEMENT_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name          : XXOD_EBAY_SETTLEMENT_PKG                                                  |
  -- |  Description   : Package to consume Ebay REST finance APIs for settlement process          |
  -- |  Change Record :                                                                           |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    =================================================|
  -- | 1.0         23-Sep-2020  Mayur Palsokar   Initial version                                  |
  -- +============================================================================================+
  
  -- +============================================================================================+
  -- |  Procedure    : XXOD_GET_AUTH_INFO                                                         |
  -- |  Description : Get authorization code and and redirect URI                                 |
  -- +============================================================================================+
  PROCEDURE XXOD_GET_AUTH_INFO (P_AUTH_CODE OUT VARCHAR2, 
                                P_REDIRECT_URI OUT VARCHAR2);
   
  -- +============================================================================================+
  -- |  Function    : XXOD_GET_AUTH_STRING                                                        |
  -- |  Description : Get authorization string                                                    |
  -- +============================================================================================+
  FUNCTION XXOD_GET_AUTH_STRING
   RETURN VARCHAR2;
	
  -- +============================================================================================+
  -- |  Procedure   : XXOD_GENERATE_REFRESH_TOKEN                                                 |
  -- |  Description : Exchanging the authorization code for a User access token                   |
  -- +============================================================================================+
  PROCEDURE XXOD_GENERATE_REFRESH_TOKEN(
	  X_ERRBUF OUT VARCHAR2,
      X_RETCODE OUT NUMBER);
  
  -- +============================================================================================+
  -- |  Function    : XXOD_GET_ACCESS_TOKEN                                                       |
  -- |  Description : get refresh token using user access toekn                                   |
  -- +============================================================================================+
  FUNCTION XXOD_GET_ACCESS_TOKEN(
      P_SCOPE IN VARCHAR2,
	  P_AUTH_STRING IN VARCHAR2)
    RETURN VARCHAR2;
  
  -- +============================================================================================+
  -- |  Procedure    : XXOD_GET_TRANSACTIONS                                                      |
  -- |  Description : Get transactions                                                            |
  -- +============================================================================================+
  PROCEDURE XXOD_GET_TRANSACTIONS(
      P_ACCESS_TOKEN IN VARCHAR2);

  -- +============================================================================================+
  -- |  Procedure    : XXOD_GET_ORDERS                                                            |
  -- |  Description : Get Orders                                                                  |
  -- +============================================================================================+
  PROCEDURE XXOD_GET_ORDERS(
      P_ACCESS_TOKEN IN VARCHAR2);

  -- +============================================================================================+
  -- |  Procedure   : XXOD_LOAD_SETTLEMENT_DATA                                                   |
  -- |  Description : Load transactions and Orders data in table                                  |
  -- +============================================================================================+
  PROCEDURE XXOD_LOAD_SETTLEMENT_DATA;
  
  -- +============================================================================================+
  -- |  Procedure   : WRITE_LOG                                                                   |
  -- +============================================================================================+
  PROCEDURE WRITE_LOG(
      P_DISPLAY_FLG IN VARCHAR2,
      P_LOCATION    IN VARCHAR2 DEFAULT NULL,
      P_STATEMENT   IN VARCHAR2 DEFAULT NULL);	 
  
  -- +============================================================================================+
  -- |  Procedure   : MAIN                                                                        |
  -- |  Description : Load transactions and Orders  data in table                                 |
  -- +============================================================================================+
  PROCEDURE MAIN;

END XXOD_EBAY_SETTLEMENT_PKG;

/
SHOW ERRORS;