SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
-- +==========================================================================+
-- |                             Office Depot                                 |
-- +==========================================================================+
-- | Table Script to create the following object                              |
-- | Table  : XXFIN.XXFIN_FINAL_PURGED_CUSTOMERS                                        |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     12-FEB-2021  Ankit Jaiswal        Initial version               |
-- +==========================================================================+

GRANT SELECT, INSERT, UPDATE, DELETE ON XXFIN.XXFIN_FINAL_PURGED_CUSTOMERS TO APPS;

SHOW ERROR;