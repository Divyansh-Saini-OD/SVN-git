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
-- |1.0       23-Jul-2008   D. Gowda       Defect 7926 - Performance updates -  |
-- |                                       Preprocess join to fnd_currencies,   |   
-- |                                       fnd_territories, AR and iPayments    |
-- |                                                                            |
-- |                                                                            |
-- +============================================================================+

ALTER TABLE xxfin.xx_ce_ajb998 ADD recon_header_id NUMBER;

ALTER TABLE xxfin.xx_ce_ajb998 ADD ar_cash_receipt_id NUMBER;

ALTER TABLE xxfin.xx_ce_ajb998 ADD territory_code VARCHAR2(2);

ALTER TABLE xxfin.xx_ce_ajb998 ADD currency VARCHAR2(15);


