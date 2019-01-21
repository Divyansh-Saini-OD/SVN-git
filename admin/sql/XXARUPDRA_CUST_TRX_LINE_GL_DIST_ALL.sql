-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
---|  Application    :   AR                                                   |
---|                                                                          |
---|  Name           :   XXARUPDRA_CUST_TRX_LINE_GL_DIST_ALL.sql              |
---|                                                                          |
---|  Description    :   This script updates POSTING_WORKER_NUMBER of         |
---|                                   RA_CUST_TRX_LINE_GL_DIST_ALL table     |
---|                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author               Remarks                      |
-- |=======   ==========    ================     =============================|
-- | V1.0     20-NOV-2009  Anitha Devarajulu    For Defect 2851               |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

UPDATE AR.RA_CUST_TRX_LINE_GL_DIST_ALL
SET POSTING_WORKER_NUMBER = 1
WHERE POSTING_CONTROL_ID = -3;

COMMIT;

SHOW ERROR