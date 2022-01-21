SET VERIFY       OFF

  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_CDH_EBL_EXL_SP_DETAILS                                                          |
  -- |                                                                                            |
  -- |  Description:  This script is to create translations for the fields that need to be        |
  -- |                exempted from further processing in the customer docs                       |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         26-JUL-2018  Capgemini        Initial version - Created for Defect#45279       |
  -- +============================================================================================+

INSERT INTO XX_FIN_TRANSLATEDEFINITION (TRANSLATE_ID,TRANSLATION_NAME,SOURCE_SYSTEM,TARGET_SYSTEM,PURPOSE,TRANSLATE_DESCRIPTION,RELATED_MODULE,SOURCE_FIELD1,SOURCE_FIELD2,SOURCE_FIELD3,SOURCE_FIELD4,SOURCE_FIELD5,SOURCE_FIELD6,SOURCE_FIELD7,TARGET_FIELD1,TARGET_FIELD2,TARGET_FIELD3,TARGET_FIELD4,TARGET_FIELD5,TARGET_FIELD6,TARGET_FIELD7,TARGET_FIELD8,TARGET_FIELD9,TARGET_FIELD10,TARGET_FIELD11,TARGET_FIELD12,TARGET_FIELD13,TARGET_FIELD14,TARGET_FIELD15,TARGET_FIELD16,TARGET_FIELD17,TARGET_FIELD18,TARGET_FIELD19,TARGET_FIELD20,CREATION_DATE,CREATED_BY,LAST_UPDATE_DATE,LAST_UPDATED_BY,LAST_UPDATE_LOGIN,START_DATE_ACTIVE,END_DATE_ACTIVE,ENABLED_FLAG,SOURCE_FIELD8,SOURCE_FIELD9,SOURCE_FIELD10,DO_NOT_REFRESH,TARGET_FIELD21,TARGET_FIELD22,TARGET_FIELD23,TARGET_FIELD24,TARGET_FIELD25,TARGET_FIELD26,TARGET_FIELD27,TARGET_FIELD28,TARGET_FIELD29,TARGET_FIELD30) values (XX_FIN_TRANSLATEDEFINITION_S.NEXTVAL,'XX_CDH_EBL_EXL_SP_DETAILS',null,null,null,null,'XXCRM','Field_ID','Field_Name',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,sysdate,-1,sysdate,-1,-1,sysdate,null,'Y',null,null,null,'N',null,null,null,null,null,null,null,null,null,null);

INSERT INTO XXFIN.XX_FIN_TRANSLATERESPONSIBILITY (TRANSLATE_ID,RESPONSIBILITY_ID,READ_ONLY_FLAG,CREATION_DATE,CREATED_BY,LAST_UPDATE_DATE,LAST_UPDATED_BY,LAST_UPDATE_LOGIN,SECURITY_VALUE_ID) values (XX_FIN_TRANSLATEDEFINITION_S.currval,52270,null,sysdate,-1,sysdate,-1,-1,XX_FIN_TRANSLATERESPONSIBIL_S.NEXTVAL);

Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,SOURCE_VALUE1,SOURCE_VALUE2,SOURCE_VALUE3,SOURCE_VALUE4,SOURCE_VALUE5,SOURCE_VALUE6,SOURCE_VALUE7,TARGET_VALUE1,TARGET_VALUE2,TARGET_VALUE3,TARGET_VALUE4,TARGET_VALUE5,TARGET_VALUE6,TARGET_VALUE7,TARGET_VALUE8,TARGET_VALUE9,TARGET_VALUE10,TARGET_VALUE11,TARGET_VALUE12,TARGET_VALUE13,TARGET_VALUE14,TARGET_VALUE15,TARGET_VALUE16,TARGET_VALUE17,TARGET_VALUE18,TARGET_VALUE19,TARGET_VALUE20,CREATION_DATE,CREATED_BY,LAST_UPDATE_DATE,LAST_UPDATED_BY,LAST_UPDATE_LOGIN,START_DATE_ACTIVE,END_DATE_ACTIVE,READ_ONLY_FLAG,ENABLED_FLAG,SOURCE_VALUE8,SOURCE_VALUE9,SOURCE_VALUE10,TRANSLATE_VALUE_ID,TARGET_VALUE21,TARGET_VALUE22,TARGET_VALUE23,TARGET_VALUE24,TARGET_VALUE25,TARGET_VALUE26,TARGET_VALUE27,TARGET_VALUE28,TARGET_VALUE29,TARGET_VALUE30) values (XX_FIN_TRANSLATEDEFINITION_S.currval,'10109','Sales Person',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,sysdate,-1,sysdate,-1,-1,sysdate,null,null,'Y',null,null,null,XX_FIN_TRANSLATEVALUES_S.NEXTVAL,null,null,null,null,null,null,null,null,null,null);

COMMIT;
/

SHOW ERRORS;
EXIT;