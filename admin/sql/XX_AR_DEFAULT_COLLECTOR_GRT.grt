SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Table Script to create the following object                              |
-- | Grant  : xx_ar_default_collector_temp                                    |
-- | For R0528 , OD: AR Default                                               |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     07-Jan-2009  Jennifer Jegam        Initial version              |
-- |                                                                          |
-- +==========================================================================+

GRANT SELECT,UPDATE,INSERT ON  XXFIN.xx_ar_default_collector_temp TO APPS;

SHOW ERROR;