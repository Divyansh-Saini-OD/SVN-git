create or replace 
PACKAGE XX_AR_CONTRACTS_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_AR_CONTRACTS_PKG                                                                |
  -- |                                                                                            |
  -- |  Description:  This package is to export Service Contract information to SAS               |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author             Remarks                                        |
  -- | =========   ===========  =============      =============================================  |
  -- | 1.0         22-JAN-2018  Jaishankar Kumar   Initial version                                |
  -- +============================================================================================+

PROCEDURE import_contracts ( errbuff      OUT VARCHAR2
                           , retcode      OUT VARCHAR2
						   , p_contract_file_name_in  IN VARCHAR2
                           ); 
END XX_AR_CONTRACTS_PKG;
/
SHOW ERRORS;