-- +============================================================================+
-- | Office Depot - Project Simplify                                            |
-- | Providge Consulting                                                        |
-- +============================================================================+
-- | SQL Script to alter table:  XX_CE_AJB998                                   |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date          Author         Remarks                              |
-- |=======   ===========   =============  =====================================|
-- |1.0       12-Jun-2008   DGowda         Defects 7358                         |
-- |                                                                            |
-- +============================================================================+

ALTER TABLE XXFIN.XX_CE_AJB998
RENAME COLUMN REF_NUM TO REF_NUM_OLD;

ALTER TABLE XXFIN.XX_CE_AJB998
 ADD (REF_NUM  VARCHAR2(250));

UPDATE XXFIN.XX_CE_AJB998
   SET REF_NUM = REF_NUM_OLD;

COMMIT;

ALTER TABLE XXFIN.XX_CE_AJB998 DROP COLUMN REF_NUM_OLD;