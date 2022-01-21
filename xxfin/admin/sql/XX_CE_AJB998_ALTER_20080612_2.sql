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
-- |1.0       12-Jun-2008   DGowda         Defects 8023                         |
-- |                                                                            |
-- +============================================================================+

ALTER TABLE xxfin.xx_ce_ajb998
 ADD (recon_date DATE);

CREATE INDEX xx_ce_ajb998_n5 ON xxfin.xx_ce_ajb998(recon_date);

