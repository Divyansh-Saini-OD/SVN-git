-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to add responsibility to access the Translation                |
-- |XX_AR_SC_EMAIL_ADDR|                                                     |	
-- |Email address.                                                            |  
-- |Table    :  xx_fin_translateresponsibility                                |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          04-OCT-2018   Punit Gupta             Initial Version        |

INSERT INTO xx_fin_translateresponsibility (translate_id,responsibility_id,read_only_flag,creation_date,created_by,last_update_date,last_updated_by,last_update_login,security_value_id) 
VALUES ((SELECT TRANSLATE_ID FROM XX_FIN_TRANSLATEDEFINITION WHERE TRANSLATION_NAME = 'XX_AR_SC_EMAIL_ADDR'),52300,null,SYSDATE,-1,SYSDATE,-1,-1,(SELECT MAX(security_value_id)+ 1 FROM xx_fin_translateresponsibility));

INSERT INTO xx_fin_translateresponsibility (translate_id,responsibility_id,read_only_flag,creation_date,created_by,last_update_date,last_updated_by,last_update_login,security_value_id) 
VALUES ((SELECT TRANSLATE_ID FROM XX_FIN_TRANSLATEDEFINITION WHERE TRANSLATION_NAME = 'XX_AR_SC_EMAIL_ADDR'),52270,null,SYSDATE,-1,SYSDATE,-1,-1,(SELECT MAX(security_value_id)+ 1 FROM xx_fin_translateresponsibility));

COMMIT;
