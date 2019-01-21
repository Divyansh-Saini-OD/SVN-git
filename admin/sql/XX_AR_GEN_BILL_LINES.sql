-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | SQL Script to create                                                     |
-- |                                                                          |
-- |                      INDEXES: XX_AR_GEN_BILL_LINES                    |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     28-AUG-2009  Sambasiva Reddy D    Initial version               |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

--Script to gather Stats:

Exec fnd_stats.gather_table_Stats('XXFIN','XX_AR_GEN_BILL_LINES_ALL', percent=>10);

