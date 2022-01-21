-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to update the payment terms of unprocessed accounts            |	
-- |                                                                          |  
-- |Table    :    ar_cons_inv_all                                             |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          04-OCT-2017   Punit Gupta             Regression Test        |

delete from ar_cons_inv_all WHERE customer_id in (34677884) and creation_date >= sysdate-5;

UPDATE AR_PAYMENT_SCHEDULES_ALL SET EXCLUDE_FROM_CONS_BILL_FLAG = 'N' 
where customer_trx_id in (SELECT CT.customer_trx_id
FROM   APPS.RA_CUSTOMER_TRX_ALL   CT,
       APPS.AR_PAYMENT_SCHEDULES_ALL PS
WHERE  PS.CUSTOMER_SITE_USE_ID     = 85595536
AND    PS.CONS_INV_ID              IS NULL
AND    PS.invoice_currency_code    = nvl('USD', PS.invoice_currency_code)
AND    CT.CUSTOMER_TRX_ID          = PS.CUSTOMER_TRX_ID
AND    CT.printing_option = 'PRI'
AND    PS.CLASS                    IN ('INV', 'DM', 'DEP', 'CB','CM')
--AND    NVL(PS.EXCLUDE_FROM_CONS_BILL_FLAG, 'N') <> 'Y'
AND    NVL(CT.BILLING_DATE, CT.TRX_DATE) <= '08-DEC-17');

COMMIT;   

SHOW ERRORS;

EXIT;