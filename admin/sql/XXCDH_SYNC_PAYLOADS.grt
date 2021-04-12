-- +==========================================================================+
-- |                  Office Depot - Project Optimize                         |
-- +==========================================================================+
-- |SQL Script to create                                                      |
-- |                                                                          |
-- |GRANT: XXCRM.XXCDH_SYNC_PAYLOADS                                             |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author               Remarks                      |
-- |=======   ==========    ================     =============================|
-- | V1.0     15-Mar-2021   Amit Kumar           Initial version-NAIT-174584  |
-- |                                                                          |
-- +==========================================================================+

GRANT SELECT ON XXCRM.XXCDH_SYNC_PAYLOADS TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT ALL ON XXCRM.XXCDH_SYNC_PAYLOADS TO APPS WITH GRANT OPTION;
