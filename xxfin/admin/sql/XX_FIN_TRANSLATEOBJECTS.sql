-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                                                                          |
-- +==========================================================================+
-- | SQL Script to create Grants for the following tables                     |
-- |                                                                          |
-- |                      TABLE:  XXFIN.XX_FIN_TRANSLATEDEFINITION
-- |                              XXFIN.XX_FIN_TRANSLATEVALUES
-- |                              XXFIN.XX_FIN_TRANSLATERESPONSIBILITY
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   ================     ==============================|
-- | V1.0     30-NOV-2007  P.SANKARAN           Initial version               |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

GRANT SELECT ON XXFIN.XX_FIN_TRANSLATEDEFINITION TO XXCNV;

GRANT SELECT ON XXFIN.XX_FIN_TRANSLATEVALUES TO XXCNV;

GRANT SELECT ON XXFIN.XX_FIN_TRANSLATERESPONSIBILITY TO XXCNV;

SHOW ERROR;