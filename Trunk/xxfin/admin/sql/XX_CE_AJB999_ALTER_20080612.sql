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
-- |1.0       12-Jun-2008   DGowda         Defect 8023                          |
-- |                                                                            |
-- +============================================================================+

ALTER TABLE xxfin.xx_ce_ajb999
 ADD (recon_date DATE);

CREATE INDEX xx_ce_ajb999_n1 ON xxfin.xx_ce_ajb999(bank_rec_id);

CREATE INDEX xx_ce_ajb999_n2 ON xxfin.xx_ce_ajb999(processor_id);
 
CREATE INDEX xx_ce_ajb999_n3 ON xxfin.xx_ce_ajb999(provider_type);
 
CREATE INDEX xx_ce_ajb999_n4 ON xxfin.xx_ce_ajb999(cardtype);
 
CREATE INDEX xx_ce_ajb999_n5 ON xxfin.xx_ce_ajb999(store_num);
 
CREATE INDEX xx_ce_ajb999_n6 ON xxfin.xx_ce_ajb999(org_id);      
      
CREATE INDEX xx_ce_ajb999_n7 ON xxfin.xx_ce_ajb999(recon_date); 
