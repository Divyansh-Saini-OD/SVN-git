-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       Providge Consulting                           |
-- +=====================================================================+
-- | Name :  IEX_F_SCORING_INVOICES_OD_V                                 |
-- | Description : view For IEX Scoring Engine Harness Job               |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       11-FEB-2010      Sadath            Created Base version    |
-- |                        Wipro technologies   for R1.1  Defect #3955  |
-- |                                                                     |
-- +=====================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

CREATE OR REPLACE VIEW IEX_F_SCORING_INVOICES_OD_V 
AS
   SELECT payment_schedule_id
   FROM   ar_payment_schedules ar
   WHERE  ar.class IN('INV', 'DM', 'CB')
   AND    AR.GL_DATE_CLOSED       > trunc(SYSDATE - 30)
   AND    ar.due_date            <= TRUNC(sysdate)
   AND    ((ar.status             = 'OP'
   AND    (ar.amount_in_dispute is not null OR NOT EXISTS
   (SELECT 1
   FROM   iex_delinquencies_all dll
   WHERE  dll.payment_schedule_id = ar.payment_schedule_id
   AND    dll.status              = 'DELINQUENT'))) 
          OR(ar.status            = 'CL'
   AND    EXISTS
   (SELECT 1
   FROM   iex_delinquencies_all dll
   WHERE  dll.payment_schedule_id = ar.payment_schedule_id
   AND    dll.status              = 'DELINQUENT')))
/
SHOW ERR