-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to update the translation value with the new DL                |	
-- |                                                                          |  
-- |Table    :    xx_fin_translatevalues                                      |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          25-JAN-2019   Punit Gupta             Initial version        |

UPDATE xx_fin_translatevalues XFTV
SET XFTV.target_value2  = 'Subscription_Services_Prod_Support@officedepot.onmicrosoft.com'
WHERE XFTV.translate_id = (
                           SELECT translate_id 
                           FROM   xx_fin_translatedefinition XFTD
                           WHERE  XFTD.translation_name = 'XX_AR_SC_EMAIL_ADDR'
                          )
AND  XFTV.target_value1 = 'OD_TECH'
/
UPDATE xx_fin_translatevalues XFTV
SET XFTV.target_value2  = 'Subscription_Services_Prod_Support@officedepot.onmicrosoft.com'
WHERE XFTV.translate_id = (
                           SELECT translate_id 
                           FROM   xx_fin_translatedefinition XFTD
                           WHERE  XFTD.translation_name = 'XX_AR_SUBSCR_VENDORS'
                          )
AND  XFTV.target_value1 IN ('01132448',
                            '01285689',
                            '01279982',
                            '01306234',
                            '01242135'
                            )
/
COMMIT;
   
SHOW ERRORS;

EXIT;


