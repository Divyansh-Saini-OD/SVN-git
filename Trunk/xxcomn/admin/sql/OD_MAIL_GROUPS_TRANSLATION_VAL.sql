SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                                                                                |
-- +================================================================================+
-- | SQL Script to insert translation value into translation OD_MAIL_GROUPS         |
-- |                                                                                |
-- | OD_MAIL_GROUPS_TRANSLATION_VAL.sql                                             |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author               Remarks                             |
-- |=======   ==========   =============        ====================================|
-- | V1.0     14-JUN-17    Havish Kasina        Initial version. defect#40762       |
-- |                                                                                |
-- +================================================================================+


DECLARE
  ln_user_id             NUMBER         := NVL ( FND_GLOBAL.USER_ID, -1);
  ln_login_id            NUMBER         := NVL ( FND_GLOBAL.LOGIN_ID , -1);
  ln_translate_id        NUMBER;
  ln_translate_value_id  NUMBER;
BEGIN
  
  dbms_output.put_line('Selecting the Translate Id ');
  
  SELECT translate_id
  INTO ln_translate_id
  FROM xx_fin_translatedefinition 
  WHERE translation_name ='OD_MAIL_GROUPS';


  dbms_output.put_line('Selecting the max translate value from sequence.');
  
  SELECT XX_FIN_TRANSLATEVALUES_S.NEXTVAL
  INTO ln_translate_value_id
  FROM DUAL;
  
  dbms_output.put_line('Inserting New Tranlation values for OD: Custom GSCC Automation Report ');
  
  Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                      SOURCE_VALUE1,
									  TARGET_VALUE1,
									  CREATION_DATE,
									  CREATED_BY,
									  LAST_UPDATE_DATE,
									  LAST_UPDATED_BY,
									  LAST_UPDATE_LOGIN,
									  START_DATE_ACTIVE,
									  ENABLED_FLAG,
									  TRANSLATE_VALUE_ID) 
                              values (ln_translate_id,
							          'XXOD_COMN_GSCC_VIOLATIONS',
									  'IT_ERP_SYSTEMS@officedepot.com,it_erp_contractors@officedepot.com,erp-engineering@officedepot.com,EBS_AMS_FIN_Support@officedepot.com,ebs_ams_crm_support@officedepot.com,ebs_ams_scm_support@officedepot.com',
									  sysdate,
									  ln_user_id,
									  sysdate,
									  ln_user_id,
									  ln_login_id,
									  sysdate,
									  'Y',
									  ln_translate_value_id);

  IF sql%rowcount > 0 THEN
    dbms_output.put_line('New Translation value Created');
  end if;

  COMMIT;

  EXCEPTION WHEN OTHERS THEN
    dbms_output.put_line('Error while executing the sql statements'||sqlcode||' - '||sqlerrm);
    ROLLBACK;
END;
/

