-- +============================================================================+
-- | Office Depot - Project Simplify                                            |
-- | Providge Consulting                                                        |
-- +============================================================================+
-- | SQL Script to alter table:  XX_CE_AJB999                                   |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date          Author         Remarks                              |
-- |=======   ===========   =============  =====================================|
-- |1.0       23-Jul-2008   D. Gowda       Defect 7926 - Performance updates -  |
-- |                                       Preprocess join to fnd_currencies,   |   
-- |                                       fnd_territories		        |
-- |                                                                            |
-- |                                                                            |
-- +============================================================================+

ALTER TABLE xxfin.xx_ce_ajb999 ADD territory_code VARCHAR2(2);

ALTER TABLE xxfin.xx_ce_ajb999 ADD currency VARCHAR2(15);

