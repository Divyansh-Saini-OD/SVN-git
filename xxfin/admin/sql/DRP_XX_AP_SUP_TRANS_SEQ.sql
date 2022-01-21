SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
whenever SQLERROR CONTINUE;
whenever OSERROR EXIT FAILURE ROLLBACK;
-- +==========================================================================+
-- |                  Office Depot - Project IDMS                             |
-- |                                                                          |
-- +==========================================================================+
-- | SQL Script to drop the following objects                               |
-- | SYNONYM       : XX_AP_SUP_TRANS_SEQ                                      |
-- | Rice ID : C0709                                                          |        -- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     08-JAN-2018  Sunil Kalal           Initial Version              | 
-- |                                                                          |
-- +==========================================================================+



DROP SYNONYM XX_AP_SUP_TRANS_SEQ;

SHOW error
 