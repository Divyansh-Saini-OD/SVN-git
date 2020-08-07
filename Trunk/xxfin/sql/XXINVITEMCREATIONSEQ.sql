-- +==========================================================================+
-- |                      Oracle GSD  (India)                                 |
-- |                       Hyderabad  India                                   |
-- +==========================================================================+
-- | SQL Script to create the following objects                               |
-- |             Sequence    : XX_INV_ITEM_CREATION_PKG_S                     |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     25-JUL-2011  Sreenivasa Tirumala  Initial version               |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON


DROP SEQUENCE apps.xx_inv_item_creation_pkg_s;

CREATE SEQUENCE  "APPS"."XX_INV_ITEM_CREATION_PKG_S"  MINVALUE 1 MAXVALUE 2147483647 INCREMENT BY 1 START WITH 10000000 NOORDER  NOCYCLE ;

SHOW ERROR