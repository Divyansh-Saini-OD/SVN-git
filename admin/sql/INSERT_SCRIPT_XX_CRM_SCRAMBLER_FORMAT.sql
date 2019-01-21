SET SERVEROUTPUT ON;
DECLARE
ln_count          NUMBER := 0;
ln_translate_id   NUMBER;
BEGIN
-- Delete the Translation
  DELETE FROM XX_FIN_TRANSLATEVALUES
  WHERE TRANSLATE_ID = (SELECT TRANSLATE_ID FROM XX_FIN_TRANSLATEDEFINITION
                         WHERE TRANSLATION_NAME = 'XX_CRM_SCRAMBLER_FORMAT');
                         
  DELETE FROM XX_FIN_TRANSLATEDEFINITION
  WHERE TRANSLATION_NAME = 'XX_CRM_SCRAMBLER_FORMAT';
  DBMS_OUTPUT.PUT_LINE(' Deleted the XX_CRM_SCRAMBLER_FORMAT Translation');

ln_translate_id := XX_FIN_TRANSLATEDEFINITION_S.NEXTVAL;

-- Create the Transaltion Name
    Insert into XX_FIN_TRANSLATEDEFINITION
                         (TRANSLATE_ID,
                          TRANSLATION_NAME,
						              TRANSLATE_DESCRIPTION,
						              SOURCE_FIELD1,
						              SOURCE_FIELD2,
                          SOURCE_FIELD3,
                          SOURCE_FIELD4,
						              CREATION_DATE,
						              CREATED_BY,
						              LAST_UPDATE_DATE,
						              LAST_UPDATED_BY,
						              LAST_UPDATE_LOGIN,
						              START_DATE_ACTIVE,
						              END_DATE_ACTIVE,
						              ENABLED_FLAG) 
			            values (ln_translate_id,
				                 'XX_CRM_SCRAMBLER_FORMAT',
						             'Export table with specific column scrambler',
						             'TABLE_NAME',
						             'COLUMN_NAME',
                         'DATA_TYPE',
                         'DATA_LENGTH',
						              to_date(SYSDATE,'DD-MON-RR'),
                          FND_GLOBAL.USER_ID,
						              to_date(SYSDATE,'DD-MON-RR'),
						              FND_GLOBAL.USER_ID,
						              FND_GLOBAL.LOGIN_ID,
						              to_date(SYSDATE,'DD-MON-RR'),
						              null,
						              'Y');     
-- Row 1
  Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                      SOURCE_VALUE1,
                                      SOURCE_VALUE2,
                                      SOURCE_VALUE3,
                                      SOURCE_VALUE4,
                                      CREATION_DATE,
                                      CREATED_BY,
                                      LAST_UPDATE_DATE,
                                      LAST_UPDATED_BY,
                                      LAST_UPDATE_LOGIN,
                                      START_DATE_ACTIVE,
                                      END_DATE_ACTIVE,
                                      READ_ONLY_FLAG,
                                      ENABLED_FLAG,
                                      TRANSLATE_VALUE_ID) 
                              values (ln_translate_id,
                                      'XX_CRM_CUSTADDR_STG',
                                      'ADDRESS1',
                                      'VARCHAR2',
                                      '240',
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      FND_GLOBAL.LOGIN_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      null,
                                      null,
                                      'Y',
                                      XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
      IF SQL%ROWCOUNT = 1
      THEN
         ln_count := ln_count + 1;
     END IF;
-- Row 2                                  
      Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                      SOURCE_VALUE1,
                                      SOURCE_VALUE2,
                                      SOURCE_VALUE3,
                                      SOURCE_VALUE4,
                                      CREATION_DATE,
                                      CREATED_BY,
                                      LAST_UPDATE_DATE,
                                      LAST_UPDATED_BY,
                                      LAST_UPDATE_LOGIN,
                                      START_DATE_ACTIVE,
                                      END_DATE_ACTIVE,
                                      READ_ONLY_FLAG,
                                      ENABLED_FLAG,
                                      TRANSLATE_VALUE_ID) 
                              values (ln_translate_id,
                                      'XX_CRM_CUSTADDR_STG',
                                      'ADDRESS2',
                                      'VARCHAR2',
                                      '240',
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      FND_GLOBAL.LOGIN_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      null,
                                      null,
                                      'Y',
                                      XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
      IF SQL%ROWCOUNT = 1
      THEN
         ln_count := ln_count + 1;
     END IF;

-- Row 3
      Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                      SOURCE_VALUE1,
                                      SOURCE_VALUE2,
                                      SOURCE_VALUE3,
                                      SOURCE_VALUE4,
                                      CREATION_DATE,
                                      CREATED_BY,
                                      LAST_UPDATE_DATE,
                                      LAST_UPDATED_BY,
                                      LAST_UPDATE_LOGIN,
                                      START_DATE_ACTIVE,
                                      END_DATE_ACTIVE,
                                      READ_ONLY_FLAG,
                                      ENABLED_FLAG,
                                      TRANSLATE_VALUE_ID) 
                              values (ln_translate_id,
                                      'XX_CRM_CUSTADDR_STG',
                                      'CITY',
                                      'VARCHAR2',
                                      '60',
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      FND_GLOBAL.LOGIN_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      null,
                                      null,
                                      'Y',
                                      XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
      IF SQL%ROWCOUNT = 1
      THEN
         ln_count := ln_count + 1;
     END IF;
-- Row 4
      Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                      SOURCE_VALUE1,
                                      SOURCE_VALUE2,
                                      SOURCE_VALUE3,
                                      SOURCE_VALUE4,
                                      CREATION_DATE,
                                      CREATED_BY,
                                      LAST_UPDATE_DATE,
                                      LAST_UPDATED_BY,
                                      LAST_UPDATE_LOGIN,
                                      START_DATE_ACTIVE,
                                      END_DATE_ACTIVE,
                                      READ_ONLY_FLAG,
                                      ENABLED_FLAG,
                                      TRANSLATE_VALUE_ID) 
                              values (ln_translate_id,
                                      'XX_CRM_CUSTADDR_STG',
                                      'POSTAL_CODE',
                                      'VARCHAR2',
                                      '60',
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      FND_GLOBAL.LOGIN_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      null,
                                      null,
                                      'Y',
                                      XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
      IF SQL%ROWCOUNT = 1
      THEN
         ln_count := ln_count + 1;
     END IF;
-- Row 5
      Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                      SOURCE_VALUE1,
                                      SOURCE_VALUE2,
                                      SOURCE_VALUE3,
                                      SOURCE_VALUE4,
                                      CREATION_DATE,
                                      CREATED_BY,
                                      LAST_UPDATE_DATE,
                                      LAST_UPDATED_BY,
                                      LAST_UPDATE_LOGIN,
                                      START_DATE_ACTIVE,
                                      END_DATE_ACTIVE,
                                      READ_ONLY_FLAG,
                                      ENABLED_FLAG,
                                      TRANSLATE_VALUE_ID) 
                              values (ln_translate_id,
                                      'XX_CRM_CUSTADDR_STG',
                                      'STATE',
                                      'VARCHAR2',
                                      '60',
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      FND_GLOBAL.LOGIN_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      null,
                                      null,
                                      'Y',
                                      XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
      IF SQL%ROWCOUNT = 1
      THEN
         ln_count := ln_count + 1;
     END IF;
-- Row 6
      Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                      SOURCE_VALUE1,
                                      SOURCE_VALUE2,
                                      SOURCE_VALUE3,
                                      SOURCE_VALUE4,
                                      CREATION_DATE,
                                      CREATED_BY,
                                      LAST_UPDATE_DATE,
                                      LAST_UPDATED_BY,
                                      LAST_UPDATE_LOGIN,
                                      START_DATE_ACTIVE,
                                      END_DATE_ACTIVE,
                                      READ_ONLY_FLAG,
                                      ENABLED_FLAG,
                                      TRANSLATE_VALUE_ID) 
                              values (ln_translate_id,
                                      'XX_CRM_CUSTCONT_STG',
                                      'AREA_CODE',
                                      'VARCHAR2',
                                      '6',
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      FND_GLOBAL.LOGIN_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      null,
                                      null,
                                      'Y',
                                      XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
      IF SQL%ROWCOUNT = 1
      THEN
         ln_count := ln_count + 1;
     END IF;
-- Row 7
      Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                      SOURCE_VALUE1,
                                      SOURCE_VALUE2,
                                      SOURCE_VALUE3,
                                      SOURCE_VALUE4,
                                      CREATION_DATE,
                                      CREATED_BY,
                                      LAST_UPDATE_DATE,
                                      LAST_UPDATED_BY,
                                      LAST_UPDATE_LOGIN,
                                      START_DATE_ACTIVE,
                                      END_DATE_ACTIVE,
                                      READ_ONLY_FLAG,
                                      ENABLED_FLAG,
                                      TRANSLATE_VALUE_ID) 
                              values (ln_translate_id,
                                      'XX_CRM_CUSTCONT_STG',
                                      'EMAIL_ADDRESS',
                                      'VARCHAR2',
                                      '60',
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      FND_GLOBAL.LOGIN_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      null,
                                      null,
                                      'Y',
                                      XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
      IF SQL%ROWCOUNT = 1
      THEN
         ln_count := ln_count + 1;
     END IF;
-- Row 8
      Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                      SOURCE_VALUE1,
                                      SOURCE_VALUE2,
                                      SOURCE_VALUE3,
                                      SOURCE_VALUE4,
                                      CREATION_DATE,
                                      CREATED_BY,
                                      LAST_UPDATE_DATE,
                                      LAST_UPDATED_BY,
                                      LAST_UPDATE_LOGIN,
                                      START_DATE_ACTIVE,
                                      END_DATE_ACTIVE,
                                      READ_ONLY_FLAG,
                                      ENABLED_FLAG,
                                      TRANSLATE_VALUE_ID) 
                              values (ln_translate_id,
                                      'XX_CRM_CUSTCONT_STG',
                                      'FIRST_NAME',
                                      'VARCHAR2',
                                      '120',
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      FND_GLOBAL.LOGIN_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      null,
                                      null,
                                      'Y',
                                      XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
      IF SQL%ROWCOUNT = 1
      THEN
         ln_count := ln_count + 1;
     END IF;
-- Row 9
      Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                      SOURCE_VALUE1,
                                      SOURCE_VALUE2,
                                      SOURCE_VALUE3,
                                      SOURCE_VALUE4,
                                      CREATION_DATE,
                                      CREATED_BY,
                                      LAST_UPDATE_DATE,
                                      LAST_UPDATED_BY,
                                      LAST_UPDATE_LOGIN,
                                      START_DATE_ACTIVE,
                                      END_DATE_ACTIVE,
                                      READ_ONLY_FLAG,
                                      ENABLED_FLAG,
                                      TRANSLATE_VALUE_ID) 
                              values (ln_translate_id,
                                      'XX_CRM_CUSTCONT_STG',
                                      'LAST_NAME',
                                      'VARCHAR2',
                                      '120',
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      FND_GLOBAL.LOGIN_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      null,
                                      null,
                                      'Y',
                                      XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
      IF SQL%ROWCOUNT = 1
      THEN
         ln_count := ln_count + 1;
     END IF;
-- Row 10
      Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                      SOURCE_VALUE1,
                                      SOURCE_VALUE2,
                                      SOURCE_VALUE3,
                                      SOURCE_VALUE4,
                                      CREATION_DATE,
                                      CREATED_BY,
                                      LAST_UPDATE_DATE,
                                      LAST_UPDATED_BY,
                                      LAST_UPDATE_LOGIN,
                                      START_DATE_ACTIVE,
                                      END_DATE_ACTIVE,
                                      READ_ONLY_FLAG,
                                      ENABLED_FLAG,
                                      TRANSLATE_VALUE_ID) 
                              values (ln_translate_id,
                                      'XX_CRM_CUSTCONT_STG',
                                      'PHONE_NUMBER',
                                      'VARCHAR2',
                                      '15',
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      FND_GLOBAL.LOGIN_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      null,
                                      null,
                                      'Y',
                                      XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
      IF SQL%ROWCOUNT = 1
      THEN
         ln_count := ln_count + 1;
     END IF;
-- Row 11
      Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                      SOURCE_VALUE1,
                                      SOURCE_VALUE2,
                                      SOURCE_VALUE3,
                                      SOURCE_VALUE4,
                                      CREATION_DATE,
                                      CREATED_BY,
                                      LAST_UPDATE_DATE,
                                      LAST_UPDATED_BY,
                                      LAST_UPDATE_LOGIN,
                                      START_DATE_ACTIVE,
                                      END_DATE_ACTIVE,
                                      READ_ONLY_FLAG,
                                      ENABLED_FLAG,
                                      TRANSLATE_VALUE_ID) 
                              values (ln_translate_id,
                                      'XX_CRM_CUSTMAST_HEAD_STG',
                                      'CUSTOMER_NAME',
                                      'VARCHAR2',
                                      '360',
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      FND_GLOBAL.LOGIN_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      null,
                                      null,
                                      'Y',
                                      XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
      IF SQL%ROWCOUNT = 1
      THEN
         ln_count := ln_count + 1;
     END IF;
-- Row 12
      Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                      SOURCE_VALUE1,
                                      SOURCE_VALUE2,
                                      SOURCE_VALUE3,
                                      SOURCE_VALUE4,
                                      CREATION_DATE,
                                      CREATED_BY,
                                      LAST_UPDATE_DATE,
                                      LAST_UPDATED_BY,
                                      LAST_UPDATE_LOGIN,
                                      START_DATE_ACTIVE,
                                      END_DATE_ACTIVE,
                                      READ_ONLY_FLAG,
                                      ENABLED_FLAG,
                                      TRANSLATE_VALUE_ID) 
                              values (ln_translate_id,
                                      'XX_CRM_CUSTMAST_HEAD_STG',
                                      'DUNS_NUMBER',
                                      'VARCHAR2',
                                      '30',
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      FND_GLOBAL.USER_ID,
                                      FND_GLOBAL.LOGIN_ID,
                                      to_date(SYSDATE,'DD-MON-RR'),
                                      null,
                                      null,
                                      'Y',
                                      XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
      IF SQL%ROWCOUNT = 1
      THEN
         ln_count := ln_count + 1;
     END IF;     
dbms_output.put_line ('Records processed :'||ln_count);
COMMIT;
EXCEPTION 
WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE ('Unexpected Error : ' || SQLERRM);
END;
/
show errors;