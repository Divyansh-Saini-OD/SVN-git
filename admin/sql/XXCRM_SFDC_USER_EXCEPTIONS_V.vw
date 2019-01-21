SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===========================================================================================+
-- |                  Office Depot                                                               |
-- |                                                                                   |
-- +===========================================================================================+
-- | Name        : xxcrm_sfdc_user_exceptions_v                                                         |
-- | Description :                                                          |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1     05-Apr-2012    Prasad      Initial draft version  	                       |
-- |                                                                                          |
-- +===========================================================================================+

CREATE OR REPLACE VIEW xxcrm_sfdc_user_exceptions_v
AS  SELECT TRANSLATE_VALUE_ID MAP_ID,
  T.SOURCE_VALUE1 EMPLOYEE_NUM,
 T.TARGET_VALUE1 OVERWRITE,
  T.TARGET_VALUE2 PROFILE,
   T.TARGET_VALUE3 DISCONTINUE,
  T.CREATED_BY,
  T.LAST_UPDATED_BY,
  T.LAST_UPDATE_DATE,
  T.LAST_UPDATE_LOGIN
FROM apps.XX_FIN_TRANSLATEVALUES T
    WHERE TRANSLATE_ID =
    (SELECT TRANSLATE_ID
    FROM APPS.XX_FIN_TRANSLATEDEFINITION
    WHERE TRANSLATION_NAME = 'XX_CRM_SFDC_USEREXCEPTION')
  AND TRUNC(SYSDATE) BETWEEN NVL(START_DATE_ACTIVE, SYSDATE-1) AND NVL(END_DATE_ACTIVE, SYSDATE+1);

SHOW ERRORS;
