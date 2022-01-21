-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                                                                          |
-- +==========================================================================+
-- | SQL Script to create Grants for the following tables                     |
-- |                                                                          |
-- |                      TABLE:  XXTWE_TAX_PARTNER 	            |
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
-- | V1.0     26-SEP-2014  S. Perlas            Initial version               |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON


GRANT SELECT, INSERT, UPDATE, DELETE ON xxfin.XXTWE_TAX_PARTNER TO APPS;

SHOW ERROR




