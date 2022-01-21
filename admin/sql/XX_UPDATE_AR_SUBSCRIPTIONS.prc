-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to update columns of XX_AR_SUBSCRIPTIONS with the required flag|	
-- |                                                                          |  
-- |Table    :    XX_AR_SUBSCRIPTIONS                                         |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          22-JUL-2019   Punit Gupta                                    |
-- +==========================================================================+

UPDATE XX_AR_SUBSCRIPTIONS XAS
SET    XAS.ORDT_STAGED_FLAG = 'Y',
       XAS.EMAIL_SENT_FLAG = 'Y', 
       XAS.HISTORY_SENT_FLAG ='Y',
       XAS.LAST_UPDATE_DATE = SYSDATE
WHERE  XAS.billing_sequence_number > 1
AND    XAS.contract_id IN (SELECT contract_id 
                           FROM   XX_AR_CONTRACTS XAC 
                           WHERE  XAC.payment_type = 'AB'
                           AND    XAC.contract_status = 'ACTIVE');

COMMIT;   

SHOW ERRORS;

EXIT;