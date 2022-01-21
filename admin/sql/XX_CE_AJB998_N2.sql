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
-- |1.0       20-JAN-2010   Vinaykumar S   Defect 2610                          |
-- |                                                                            |
-- +============================================================================+

  SET SHOW         OFF
  SET VERIFY       OFF
  SET ECHO         OFF
  SET TAB          OFF
  SET FEEDBACK     ON

   UPDATE xxfin.xx_ce_ajb998 xca8
   SET xca8.status_1310 = 'PROCESSED'
   WHERE 1 = 1
   AND xca8.status IN ('PREPROCESSED', 'MATCHED_AR')
   AND TRIM (xca8.rej_reason_code) IS NULL
   AND xca8.recon_header_id IS NOT NULL
   AND EXISTS  (
                SELECT bank_rec_id
                FROM xx_ce_999_interface
                WHERE bank_rec_id = xca8.bank_rec_id
                AND processor_id = xca8.processor_id
                );

