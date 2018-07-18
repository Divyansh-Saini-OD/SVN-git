-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : UPDATE XX_FIN_TRANSLATEVALUES for MINI AVF                                  |
-- | Rice Id      :                                                                             | 
-- | Description  : re-orrange the fields in the MINI AVF template            |  
-- | Purpose      : MODIFY                                           |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      | 
-- |=======    ========    =================    ==============================================+
-- |DRAFT 1A   20-JUN-2014   Arun Gannarapu       Initial Version                           |
-- |                                                                                            |
-- +============================================================================================+


SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF



PROMPT
PROMPT MODIFYING the Table XX_FIN_TRANSLATEVALUES......
PROMPT

UPDATE XX_FIN_TRANSLATEVALUES
SET Source_value3 = 'V'
WHERE TRANSLATE_ID = (select TRANSLATE_ID from apps.XX_FIN_TRANSLATEDEFINITION  where TRANSLATION_NAME = 'XX_CS_MPS_MINI_AVF_UPLOAD')
and source_value2 IN ( 'BLACK_THRESHOLD', 'CYAN_THRESHOLD','MAGENTA_THRESHOLD','YELLOW_THRESHOLD');
/

INSERT INTO XX_FIN_TRANSLATEVALUES(TRANSLATE_ID, SOURCE_VALUE1, SOURCE_VALUE2, SOURCE_VALUE3, SOURCE_VALUE4, SOURCE_VALUE5, SOURCE_VALUE6, SOURCE_VALUE7, TARGET_VALUE1, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN, START_DATE_ACTIVE, END_DATE_ACTIVE, ENABLED_FLAG, SOURCE_VALUE8, SOURCE_VALUE9, TRANSLATE_VALUE_ID)
VALUES ((select TRANSLATE_ID from apps.XX_FIN_TRANSLATEDEFINITION  where TRANSLATION_NAME = 'XX_CS_MPS_MINI_AVF_UPLOAD'), 'XX_CS_MPS_DEVICE_B_STG', 'EMAIL_ADDRESS', 'V', 'Email Address', '0', 'AJ', '1', 'OD MPS Mini AVF Upload', SYSDATE, 26176, SYSDATE, 26176, 0, SYSDATE, NULL,'Y', 'CS', 'XX_CS_MPS_MINI_AVF_UPLD', XX_FIN_TRANSLATEVALUES_S.NEXTVAL);


COMMIT;

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
