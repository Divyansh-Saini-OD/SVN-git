-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       Oracle			                                  |
-- +==========================================================================+
-- | SQL Script to create the following objects                               |
-- |             Table       : XX_GL_INTORD_DET_TEMP                        |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     15-MAR-2011  Sai Kumar Reddy      Update table script to add    |
-- |                                            columns                       | 
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

ALTER TABLE XXFIN.XX_GL_INTORD_DET_TEMP ADD (CUSTOMER_NUMBER VARCHAR2(30),CUSTOMER_NAME VARCHAR2(50),ORIG_SYSTEM_REFERENCE VARCHAR2(240));

COMMIT;
