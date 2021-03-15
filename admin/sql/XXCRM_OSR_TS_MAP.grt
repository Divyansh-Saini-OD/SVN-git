-- +==========================================================================+
-- |                  Office Depot - Project Optimize                         |
-- +==========================================================================+
-- |SQL Script to create                                                      |
-- |                                                                          |
-- |GRANT: XXCRM.XXCRM_OSR_TS_MAP                                              |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author               Remarks                      |
-- |=======   ==========    ================     =============================|
-- | V1.0     15-Mar-2021   Amit Kumar           Initial version-NAIT-174584  |
-- |                                                                          |
-- +==========================================================================+

GRANT SELECT ON XXCRM.XXCRM_OSR_TS_MAP TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT ALL ON XXCRM.XXCRM_OSR_TS_MAP TO APPS WITH GRANT OPTION;
