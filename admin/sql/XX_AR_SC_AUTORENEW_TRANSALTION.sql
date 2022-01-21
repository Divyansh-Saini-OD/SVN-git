-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to insert the new Translation values for                        |	
-- |Email addresses for the Contract Billing Report.                          |  
-- |Table    :  xx_fin_translatevalues             |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          14-FEB-2019   Punit Gupta             Initial Version        |

-- Translation Values
Insert into XX_FIN_TRANSLATEVALUES
   (TRANSLATE_ID,SOURCE_VALUE1,TARGET_VALUE1,TARGET_VALUE2,TARGET_VALUE3,CREATION_DATE,CREATED_BY,LAST_UPDATE_DATE,LAST_UPDATED_BY,LAST_UPDATE_LOGIN,START_DATE_ACTIVE,ENABLED_FLAG,TRANSLATE_VALUE_ID)
 Values
   ((SELECT translate_id FROM xx_fin_translatedefinition XFTD WHERE  XFTD.translation_name = 'XX_AR_SUBSCRIPTIONS'),'BILL_AUTORENEWAL_EMAIL_SERVICE', 'https://ch-kube-rnd-min.uschecomrnd.net/services/subscription-email-notifications/eaiapi/subscriptions/advanceautoRenewalEmailNotification','SVC-EBSWS','svcebs4uat',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.NEXTVAL);

COMMIT;
