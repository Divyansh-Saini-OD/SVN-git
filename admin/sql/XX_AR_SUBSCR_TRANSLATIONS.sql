-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to insert the new Translations having the Vendor Number and    |	
-- |Email address.                                                             |  
-- |Table    :  xx_ar_contract_lines                                          |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          17-SEP-2018   Punit Gupta             Initial Version        |

-- Definition
Insert into XX_FIN_TRANSLATEDEFINITION
   (TRANSLATE_ID, TRANSLATION_NAME, SOURCE_SYSTEM, TARGET_SYSTEM, PURPOSE, TRANSLATE_DESCRIPTION, RELATED_MODULE, TARGET_FIELD1, TARGET_FIELD2, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN, START_DATE_ACTIVE, ENABLED_FLAG, DO_NOT_REFRESH)
 Values
   (XX_FIN_TRANSLATEDEFINITION_S.NEXTVAL, 'XX_AR_SUBSCR_VENDORS', '', '', 'TRANSLATION', 'Translation having the Vendor Number and Email addresses for Billing Auth Failures Report.', 'Receivables', 'Vendor Number', 'Email Address', sysdate,-1, sysdate, -1, -1, sysdate, 'Y', 'N');

-- Values
Insert into XX_FIN_TRANSLATEVALUES
   (TRANSLATE_ID, TARGET_VALUE1, TARGET_VALUE2, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN, START_DATE_ACTIVE, ENABLED_FLAG, TRANSLATE_VALUE_ID)
 Values
   (XX_FIN_TRANSLATEDEFINITION_S.CURRVAL, '248277', 'punit.gupta@officedepot.com,thilak.ethiraj@officedepot.com', sysdate,-1, sysdate, -1, -1, sysdate,'Y', XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
Insert into XX_FIN_TRANSLATEVALUES
   (TRANSLATE_ID, TARGET_VALUE1, TARGET_VALUE2, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN, START_DATE_ACTIVE, ENABLED_FLAG, TRANSLATE_VALUE_ID)
 Values
   (XX_FIN_TRANSLATEDEFINITION_S.CURRVAL, '312720', 'punit.gupta@officedepot.com,aarthi.puthran@officedepot.com', sysdate,-1, sysdate, -1, -1, sysdate,'Y', XX_FIN_TRANSLATEVALUES_S.NEXTVAL);

COMMIT;
