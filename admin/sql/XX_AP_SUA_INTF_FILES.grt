SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
-- +==========================================================================+
-- |                             Office Depot                                 |
-- +==========================================================================+
-- | Table Script to create the following object                              |
-- | Table  : XXFIN.XX_AP_SUA_INTF_FILES                      	                  |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     18-FEB-2021  Manjush DH	        Initial version               |
-- +==========================================================================+

GRANT SELECT, INSERT, UPDATE, DELETE ON XXFIN.XX_AP_SUA_INTF_FILES TO APPS;

SHOW ERROR;