-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to add responsibility to access the Translation                |
-- |XX_AR_SUBSCR_VENDORS|                                                     |	
-- |Email address.                                                            |  
-- |Table    :  xx_fin_translateresponsibility                                |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          20-SEP-2018   Punit Gupta             Initial Version        |

INSERT INTO xx_fin_translateresponsibility (translate_id,responsibility_id,read_only_flag,creation_date,created_by,last_update_date,last_updated_by,last_update_login,security_value_id) 
VALUES (75446,52300,null,SYSDATE,-1,SYSDATE,-1,-1,(SELECT MAX(security_value_id)+ 1 FROM xx_fin_translateresponsibility));

INSERT INTO xx_fin_translateresponsibility (translate_id,responsibility_id,read_only_flag,creation_date,created_by,last_update_date,last_updated_by,last_update_login,security_value_id) 
VALUES (75446,52270,null,SYSDATE,-1,SYSDATE,-1,-1,(SELECT MAX(security_value_id)+ 1 FROM xx_fin_translateresponsibility));

COMMIT;
