SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | SQL Script to create the following object                                |
-- |             Grant    : xx_fin_program_stats                              |
-- |                      For E2015 , AR – GL Multithread Transfer to         |
-- |                      General Ledger                                      |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date              Author               Remarks               |
-- |=======      ==========        =============        ===================== |
-- | V1.0        12-NOV-2008       Aravind A.           Initial version       |
-- |                                                                          |
-- +==========================================================================+

GRANT ALL ON xxfin.xx_fin_program_stats TO apps;

SHOW ERROR