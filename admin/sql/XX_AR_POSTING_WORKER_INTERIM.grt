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
-- |             Grant    : xx_ar_posting_worker_interim                      |
-- |             RICE     : E2050 - AR Parallel GL Transfer Program           |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ===========  ===================  ==============================|
-- | V1.0     23-MAR-2010  R.Aldridge           Initial version - Defect 4889 |
-- |                                            Performance recommendation    |
-- +==========================================================================+

GRANT ALL ON xxfin.xx_ar_posting_worker_interim TO apps WITH GRANT OPTION;

SHOW ERROR