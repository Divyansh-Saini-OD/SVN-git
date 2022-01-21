CREATE OR REPLACE PACKAGE  XX_OD_UPDATE_PROFILES_PKG
AS
-- +===================================================================================+
-- |                                 Office Depot                                      |
-- +===================================================================================+
-- | Name        :  XX_OD_UPDATE_PROFILES_PKG                                          |
-- | Description :  This Package will be used to update the Profile option values and  |
-- |                Translation values                                                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version  Date           Author          Remarks                                    |
-- |=======  ============   =============   ===========================================|
-- |1.0      30-Nov-2016    Havish Kasina   Added a new procedure                      |
-- |                                        xx_update_profile_values for Defect 39631  |
-- +===================================================================================+
  
   -----------------------------------------------------------------------
   --Procedure to update the Profile option values and Translation values
   -----------------------------------------------------------------------
   PROCEDURE xx_update_profile_values(lc_run_top IN VARCHAR2);
   
END XX_OD_UPDATE_PROFILES_PKG;
/
SHOW ERRORS;
EXIT;