-- +============================================================================+
-- | Office Depot - Project Simplify                                            |
-- | Providge Consulting                                                        |
-- +============================================================================+
-- | SQL Script to alter table:  XX_CE_AJB996                                   |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date          Author         Remarks                              |
-- |=======   ===========   =============  =====================================|
-- |1.0       12-Jun-2008   DGowda         Defect 8023                          |
-- |                                                                            |
-- +============================================================================+

ALTER TABLE xxfin.xx_ce_ajb996
 ADD (recon_date DATE);

CREATE INDEX xx_ce_ajb996_n10 ON xxfin.xx_ce_ajb996(recon_date); 
CREATE INDEX xx_ce_ajb996_n11 ON xxfin.xx_ce_ajb996(org_id, provider_type, receipt_num, recon_date);
