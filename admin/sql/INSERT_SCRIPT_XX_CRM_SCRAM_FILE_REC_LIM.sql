SET SERVEROUTPUT ON;
DECLARE
ln_count          NUMBER := 0;
ln_translate_id   NUMBER;
BEGIN
 -- Delete the Translation
  DELETE FROM XX_FIN_TRANSLATEVALUES
  WHERE TRANSLATE_ID = (SELECT TRANSLATE_ID FROM XX_FIN_TRANSLATEDEFINITION
                         WHERE TRANSLATION_NAME = 'XX_CRM_SCRAM_FILE_REC_LIM');
                         
  DELETE FROM XX_FIN_TRANSLATEDEFINITION
  WHERE TRANSLATION_NAME = 'XX_CRM_SCRAM_FILE_REC_LIM';
  DBMS_OUTPUT.PUT_LINE(' Deleted the XX_CRM_SCRAM_FILE_REC_LIM Translation');

ln_translate_id := XX_FIN_TRANSLATEDEFINITION_S.NEXTVAL;

-- Create the Transaltion Name
    Insert into XX_FIN_TRANSLATEDEFINITION
                         (TRANSLATE_ID,
                          TRANSLATION_NAME,
						              TRANSLATE_DESCRIPTION,
						              SOURCE_FIELD1,
						              SOURCE_FIELD2,
						              CREATION_DATE,
						              CREATED_BY,
						              LAST_UPDATE_DATE,
						              LAST_UPDATED_BY,
						              LAST_UPDATE_LOGIN,
						              START_DATE_ACTIVE,
						              END_DATE_ACTIVE,
						              ENABLED_FLAG) 
			            values (ln_translate_id,
				                 'XX_CRM_SCRAM_FILE_REC_LIM',
						             'CRM Scrambler File Record Limit',
						             'TABLE_NAME',
						             'RECORD_CNT',
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
                                      '1000000',
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
                                      '1000000',
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
                                      '1000000',
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