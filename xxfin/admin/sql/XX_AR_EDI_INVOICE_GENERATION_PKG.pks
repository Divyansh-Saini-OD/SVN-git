create or replace 
PACKAGE XX_AR_EDI_INV_GENERATION_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_AR_EDI_INV_GENERATION_PKG                                                       |
  -- |                                                                                            |
  -- |  Description:  This package is to launch EDI Invoice Generation program                    |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         20-JUN-2018  JAI_CG           Initial version                                  |
  -- +============================================================================================+
  
  PROCEDURE submit_inv_genration(errbuff       OUT VARCHAR2, 
                                 retcode       OUT VARCHAR2,
                                 p_send_inv_edi IN VARCHAR2);

END XX_AR_EDI_INV_GENERATION_PKG;
/
SHOW ERRORS;
EXIT;