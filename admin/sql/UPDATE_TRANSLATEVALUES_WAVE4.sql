REM================================================================================================
REM                                 Start Of Script
REM================================================================================================
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +=======================================================================+
-- |                                Office Depot                           |
-- +=======================================================================+
-- | Name        : xx_fin_translatevalues                     		       |
-- | Description : Update script for xx_fin_translatevalues                |
-- |Change History:                                                        |
-- |---------------                                                        |
-- | DEFECT ID :                                                           |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     30-Aug-2018 Aniket CG          Wave 4 Requirement             |
-- +=======================================================================+

PROMPT
PROMPT Updating TXT....
PROMPT

update XX_FIN_TRANSLATEVALUES
set TARGET_VALUE26 = NULL
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_DET_FIELDS')
and SOURCE_VALUE1 in (40162,40163,40164,40165);

COMMIT;
SHOW ERRORS;