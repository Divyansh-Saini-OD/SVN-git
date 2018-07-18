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
-- |DRAFT 1A   20-SEP-2014   Arun Gannarapu       Initial Version per Defect 27312              |
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


INSERT INTO XX_FIN_TRANSLATEVALUES(TRANSLATE_ID, SOURCE_VALUE1, SOURCE_VALUE2, SOURCE_VALUE3, SOURCE_VALUE4, SOURCE_VALUE5, SOURCE_VALUE6, SOURCE_VALUE7, TARGET_VALUE1, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN, START_DATE_ACTIVE, END_DATE_ACTIVE, ENABLED_FLAG, SOURCE_VALUE8, SOURCE_VALUE9, TRANSLATE_VALUE_ID)
VALUES ((select TRANSLATE_ID from apps.XX_FIN_TRANSLATEDEFINITION  where TRANSLATION_NAME = 'XX_CS_MPS_MINI_AVF_UPLOAD'), 'XX_CS_MPS_DEVICE_B_STG', 'BLACK_THRESHOLD', 'N', 'Black Threshold', '0', 'AE', '1', 'OD MPS Mini AVF Upload', SYSDATE, 26176, SYSDATE, 26176, 0, SYSDATE, NULL,'Y', 'CS', 'XX_CS_MPS_MINI_AVF_UPLD', XX_FIN_TRANSLATEVALUES_S.NEXTVAL);

INSERT INTO XX_FIN_TRANSLATEVALUES(TRANSLATE_ID, SOURCE_VALUE1, SOURCE_VALUE2, SOURCE_VALUE3, SOURCE_VALUE4, SOURCE_VALUE5, SOURCE_VALUE6, SOURCE_VALUE7, TARGET_VALUE1, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN, START_DATE_ACTIVE, END_DATE_ACTIVE, ENABLED_FLAG, SOURCE_VALUE8, SOURCE_VALUE9, TRANSLATE_VALUE_ID)
VALUES ((select TRANSLATE_ID from apps.XX_FIN_TRANSLATEDEFINITION  where TRANSLATION_NAME = 'XX_CS_MPS_MINI_AVF_UPLOAD'), 'XX_CS_MPS_DEVICE_B_STG', 'CYAN_THRESHOLD', 'N', 'Cyan Toner', '0', 'AF', '1', 'OD MPS Mini AVF Upload', SYSDATE, 26176, SYSDATE, 26176, 0, SYSDATE, NULL,'Y', 'CS', 'XX_CS_MPS_MINI_AVF_UPLD', XX_FIN_TRANSLATEVALUES_S.NEXTVAL);

INSERT INTO XX_FIN_TRANSLATEVALUES(TRANSLATE_ID, SOURCE_VALUE1, SOURCE_VALUE2, SOURCE_VALUE3, SOURCE_VALUE4, SOURCE_VALUE5, SOURCE_VALUE6, SOURCE_VALUE7, TARGET_VALUE1, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN, START_DATE_ACTIVE, END_DATE_ACTIVE, ENABLED_FLAG, SOURCE_VALUE8, SOURCE_VALUE9, TRANSLATE_VALUE_ID)
VALUES ((select TRANSLATE_ID from apps.XX_FIN_TRANSLATEDEFINITION  where TRANSLATION_NAME = 'XX_CS_MPS_MINI_AVF_UPLOAD'), 'XX_CS_MPS_DEVICE_B_STG', 'MAGENTA_THRESHOLD', 'N', 'Magenta Toner', '0', 'AG', '1', 'OD MPS Mini AVF Upload', SYSDATE, 26176, SYSDATE, 26176, 0, SYSDATE, NULL,'Y', 'CS', 'XX_CS_MPS_MINI_AVF_UPLD', XX_FIN_TRANSLATEVALUES_S.NEXTVAL);

INSERT INTO XX_FIN_TRANSLATEVALUES(TRANSLATE_ID, SOURCE_VALUE1, SOURCE_VALUE2, SOURCE_VALUE3, SOURCE_VALUE4, SOURCE_VALUE5, SOURCE_VALUE6, SOURCE_VALUE7, TARGET_VALUE1, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN, START_DATE_ACTIVE, END_DATE_ACTIVE, ENABLED_FLAG, SOURCE_VALUE8, SOURCE_VALUE9, TRANSLATE_VALUE_ID)
VALUES ((select TRANSLATE_ID from apps.XX_FIN_TRANSLATEDEFINITION  where TRANSLATION_NAME = 'XX_CS_MPS_MINI_AVF_UPLOAD'), 'XX_CS_MPS_DEVICE_B_STG', 'YELLOW_THRESHOLD', 'N', 'Yellow Toner', '0', 'AH', '1', 'OD MPS Mini AVF Upload', SYSDATE, 26176, SYSDATE, 26176, 0, SYSDATE, NULL,'Y', 'CS', 'XX_CS_MPS_MINI_AVF_UPLD', XX_FIN_TRANSLATEVALUES_S.NEXTVAL);

INSERT INTO XX_FIN_TRANSLATEVALUES(TRANSLATE_ID, SOURCE_VALUE1, SOURCE_VALUE2, SOURCE_VALUE3, SOURCE_VALUE4, SOURCE_VALUE5, SOURCE_VALUE6, SOURCE_VALUE7, TARGET_VALUE1, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, LAST_UPDATE_LOGIN, START_DATE_ACTIVE, END_DATE_ACTIVE, ENABLED_FLAG, SOURCE_VALUE8, SOURCE_VALUE9, TRANSLATE_VALUE_ID)
VALUES ((select TRANSLATE_ID from apps.XX_FIN_TRANSLATEDEFINITION  where TRANSLATION_NAME = 'XX_CS_MPS_MINI_AVF_UPLOAD'), 'XX_CS_MPS_DEVICE_B_STG', 'AUTO_RELEASE', 'V', 'Auto Release', '0', 'AI', '1', 'OD MPS Mini AVF Upload', SYSDATE, 26176, SYSDATE, 26176, 0, SYSDATE, NULL,'Y', 'CS', 'XX_CS_MPS_MINI_AVF_UPLD', XX_FIN_TRANSLATEVALUES_S.NEXTVAL);


COMMIT;

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
