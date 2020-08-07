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
-- |1.0       20-JAN-2010   Vinaykumar S   Defect 2610                          |
-- |                                                                            |
-- +============================================================================+

  SET SHOW         OFF
  SET VERIFY       OFF
  SET ECHO         OFF
  SET TAB          OFF
  SET FEEDBACK     ON

   UPDATE xx_ce_ajb999 xca9 SET xca9.status_1310 = 'NEW' 
   WHERE  1 = 1
   AND  NOT EXISTS (
                    SELECT bank_rec_id
                    FROM xx_ce_999_interface
                    WHERE bank_rec_id = xca9.bank_rec_id
                    AND processor_id = xca9.processor_id
                    );


