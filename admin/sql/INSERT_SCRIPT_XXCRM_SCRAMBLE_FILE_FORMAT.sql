SET SERVEROUTPUT ON;
DECLARE
ln_count          NUMBER := 0;
ln_translate_id   NUMBER;
BEGIN
-- Delete the Translation
  DELETE FROM XX_FIN_TRANSLATEVALUES
  WHERE TRANSLATE_ID = (SELECT TRANSLATE_ID FROM XX_FIN_TRANSLATEDEFINITION
                         WHERE TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT');
  
   DELETE FROM XX_FIN_TRANSLATEDEFINITION
  WHERE TRANSLATION_NAME = 'XXCRM_SCRAMBL_FILE_FORMAT';  
  DBMS_OUTPUT.PUT_LINE(' Deleted the XXCRM_SCRAMBL_FILE_FORMAT Translation');
  
ln_translate_id := XX_FIN_TRANSLATEDEFINITION_S.NEXTVAL;

-- Create the Transaltion Name
    Insert into XX_FIN_TRANSLATEDEFINITION
                         (TRANSLATE_ID,
                          TRANSLATION_NAME,
						              TRANSLATE_DESCRIPTION,
						              SOURCE_FIELD1,
						              SOURCE_FIELD2,
						              SOURCE_FIELD3,
						              CREATION_DATE,
						              CREATED_BY,
						              LAST_UPDATE_DATE,
						              LAST_UPDATED_BY,
						              LAST_UPDATE_LOGIN,
						              START_DATE_ACTIVE,
						              END_DATE_ACTIVE,
						              ENABLED_FLAG) 
			            values (ln_translate_id,
				                 'XXCRM_SCRAMBL_FILE_FORMAT',
						             'CRM Scrambler File Format',
						             'TABLE_NAME',
						             'COLUMN_NAME',
						             'SEQUENCE',
						              to_date(SYSDATE,'DD-MON-RR'),
                          0,
						              to_date(SYSDATE,'DD-MON-RR'),
						              null,
						              0,
						              to_date(SYSDATE,'DD-MON-RR'),
						              null,
						              'Y');     
-- Row 1
  Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CUST_ACCOUNT_ID',
                                    '1',
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
                                    'RELEASE_VALUE',
                                    '29',
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
                                    'ORGANIZATION_NUMBER',
                                    '3',
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
                                    'CUSTOMER_NUMBER_AOPS',
                                    '4',
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
                                    '5',
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
                                    'STATUS',
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
                                    'CUSTOMER_TYPE',
                                    '7',
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
                                    'CUSTOMER_CLASS_CODE',
                                    '8',
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
                                    'SALES_CHANNEL_CODE',
                                    '9',
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
                                    'SIC_CODE',
                                    '10',
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
                                    'CUST_CATEGORY_CODE',
                                    '11',
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
                                    '12',
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
  -- Row 13
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'SIC_CODE_TYPE',
                                    '13',
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
  -- Row 14
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'COLLECTOR_NUMBER',
                                    '14',
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
   -- Row 15
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'COLLECTOR_NAME',
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
-- Row 16
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CREDIT_CHECKING',
                                    '16',
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
 
-- Row 17
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CREDIT_RATING',
                                    '17',
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
 -- Row 18
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'ACCOUNT_ESTABLISHED_DATE',
                                    '18',
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
  -- Row 19
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'ACCOUNT_CREDIT_LIMIT_USD',
                                    '19',
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
   -- Row 20
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'ACCOUNT_CREDIT_LIMIT_CAD',
                                    '20',
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
    -- Row 21
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'ORDER_CREDIT_LIMIT_USD',
                                    '21',
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
  
  -- Row 22
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'ORDER_CREDIT_LIMIT_CAD',
                                    '22',
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
 -- Row 23
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CREDIT_CLASSIFICATION',
                                    '23',
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
 -- Row 24
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'EXPOSURE_ANALYSIS_SEGMENT',
                                    '24',
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
  -- Row 25
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'RISK_CODE',
                                    '25',
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
   -- Row 26
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'SOURCE_OF_CREATION_FOR_CREDIT',
                                    '26',
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
  -- Row 27
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'PO_VALUE',
                                    '27',
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
  -- Row 28
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'PO',
                                    '28',
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
   -- Row 29
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CUSTOMER_NUMBER',
                                    '2',
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
  
-- Row 30
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'RELEASE',
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
 -- Row 31
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'COST_CENTER_VALUE',
                                    '31',
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
 -- Row 32
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'COST_CENTER',
                                    '32',
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
  -- Row 33
     Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'DESKTOP_VALUE',
                                    '33',
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
   
-- Row 34
Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'DESKTOP',
                                    '34',
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
  
   -- Row 35
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'OMX_ACCOUNT_NUMBER',
                                    '35',
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
  
  -- Row 36
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'BILLDOCS_DELIVERY_METHOD',
                                    '36',
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
  -- Row 37
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'SITE_USE_ID',
                                    '1',
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
   -- Row 38
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'ORG_ID',
                                    '2',
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
  -- Row 39
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CUST_ACCOUNT_ID',
                                    '3',
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
  -- Row 40
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    '4',
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
  -- Row 41
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    '5',
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
  -- Row 42
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'ADDRESS3',
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
  -- Row 43
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'ADDRESS4',
                                    '7',
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
  -- Row 44
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    '8',
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
  -- Row 45
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    '9',
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
  -- Row 46
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    '10',
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
  -- Row 47
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'PROVINCE',
                                    '11',
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
  -- Row 48
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'COUNTRY',
                                    '12',
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
  -- Row 49
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'PARTY_SITE_NUMBER',
                                    '13',
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
  -- Row 50
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'PRIMARY_FLAG',
                                    '14',
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
  -- Row 51
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'SEQUENCE',
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
  -- Row 52
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'ORIG_SYSTEM_REFERENCE',
                                    '16',
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
  -- Row 53
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'LOCATION',
                                    '17',
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
  -- Row 54
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'COLLECTOR_NUMBER',
                                    '18',
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
  -- Row 55
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'COLLECTOR_NAME',
                                    '19',
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
  -- Row 56
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'SEND_STATEMENTS',
                                    '21',
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
  -- Row 57
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CREDIT_LIMIT_USD',
                                    '22',
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
  -- Row 58
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CREDIT_LIMIT_CAD',
                                    '23',
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
  -- Row 59
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'PROFILE_CLASS_NAME',
                                    '24',
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
 -- Row 60
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CONSOLIDATED_BILLING',
                                    '25',
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
 -- Row 61
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CONS_BILLING_FORMATS_TYPE',
                                    '26',
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
 -- Row 62
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'BILL_IN_THE_BOX',
                                    '27',
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
 -- Row 63
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'BILLING_CURRENCY',
                                    '28',
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
 -- Row 64
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'DUNNING_DELIVERY',
                                    '29',
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
 -- Row 65
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'STATEMENT_DELIVERY',
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
 -- Row 66
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'TAXWARE_ENTITY_CODE',
                                    '31',
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
 -- Row 67
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'REMIT_TO_SALES_CHANNEL',
                                    '32',
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
 -- Row 68
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'EDI_LOCATION',
                                    '33',
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
 -- Row 69
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'ADDRESSEE',
                                    '34',
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
 -- Row 70
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'IDENTIFYING_ADDRESS',
                                    '35',
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
 -- Row 71
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'ACCT_SITE_STATUS',
                                    '36',
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
 -- Row 72
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'SITE_USE_STATUS',
                                    '37',
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
 -- Row 73
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'SITE_USE_CODE',
                                    '38',
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
 -- Row 74
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CONT_OSR',
                                    '1',
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
 -- Row 75
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CUST_ACCOUNT_ID',
                                    '2',
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
 -- Row 76
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'SITE_USE_ID',
                                    '3',
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
 -- Row 77
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CONTACT_NUMBER',
                                    '4',
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
 -- Row 78
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    '5',
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
 -- Row 79
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
 -- Row 80
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'JOB_TITLE',
                                    '7',
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
 -- Row 81
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    '8',
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
 -- Row 82
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CONT_POINT_PURPOSE',
                                    '9',
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
 -- Row 83
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CONT_POINT_PRIMARY_FLAG',
                                    '10',
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
 -- Row 84
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CONTACT_ROLE_PRIMARY_FLAG',
                                    '11',
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
 -- Row 85
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CONTACT_POINT_TYPE',
                                    '12',
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
 -- Row 86
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'PHONE_LINE_TYPE',
                                    '13',
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
 -- Row 87
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'COUNTRY_CODE',
                                    '14',
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
 -- Row 88
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
 -- Row 89
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    '16',
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
 -- Row 90
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'EXTENSION',
                                    '17',
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
 -- Row 91
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'SITE_OSR',
                                    '18',
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
  end if;
 -- Row 92
   Insert into XX_FIN_TRANSLATEVALUES (TRANSLATE_ID,
                                    SOURCE_VALUE1,
                                    SOURCE_VALUE2,
                                    SOURCE_VALUE3,
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
                                    'CONT_POINT_OSR',
                                    '19',
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