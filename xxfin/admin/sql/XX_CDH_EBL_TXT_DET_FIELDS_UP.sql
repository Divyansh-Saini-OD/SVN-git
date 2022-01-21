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
-- | Name        : XX_CDH_EBL_TXT_DET_FIELDS_UP                            |
-- | Description : Update script for XX_CDH_EBL_TXT_DET_FIELDS             |
-- |Change History:                                                        |
-- |---------------                                                        |
-- | DEFECT ID : 45279                                                     |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     12-Jul-2018 Capgemini          Original Defect#45279          |
-- | 2.0     25-Jul-2018 Capgemini          Reverting the setup changes    |
-- | 3.0     12-AUG-2018 Capgemini          Updating for SKU level tax     |
-- +=======================================================================+

PROMPT
PROMPT Creating Index....
PROMPT

 UPDATE xx_fin_translatevalues xftv
    SET target_value14 = NULL
  WHERE SOURCE_VALUE1 in (40166,40167)
    AND xftv.translate_id IN
        (SELECT xftd.translate_id
           FROM xx_fin_translatedefinition xftd
          WHERE xftd.translation_name ='XX_CDH_EBL_TXT_DET_FIELDS'
        );
COMMIT;
SHOW ERRORS;