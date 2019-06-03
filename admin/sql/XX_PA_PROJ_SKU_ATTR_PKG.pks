CREATE OR REPLACE PACKAGE APPS.XX_PA_PROJ_SKU_ATTR_PKG 
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PA_PROJ_SKU_ATTR_PKG.pks                                          |
-- | Description      : Package spec for CR853 PLM Projects Enhancements                     |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========       =============    ========================                    |
-- |1.0        19-Sep-2010      Rama Dwibhashyam  Initial draft version                      |
-- +=========================================================================================+

AS

PROCEDURE Process_Main(
                            x_message_data  OUT VARCHAR2
                           ,x_message_code  OUT NUMBER
                           ,p_project_number IN  VARCHAR2 
                           );
                           
 END XX_PA_PROJ_SKU_ATTR_PKG ;
/