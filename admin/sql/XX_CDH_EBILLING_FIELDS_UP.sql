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
-- | Name        : XX_CDH_EBILLING_FIELDS_UP                               |
-- | Description : Update script for XX_CDH_EBILLING_FIELDS                |
-- |Change History:                                                        |
-- |---------------                                                        |
-- | DEFECT ID : 45279                                                     |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     12-Jul-2018 Capgemini          Original Defect#45279          |
-- | 2.0     25-Jul-2018 Capgemini          Reverting the setup changes    |
-- +=======================================================================+

PROMPT
PROMPT Creating Index....
PROMPT

 UPDATE xx_fin_translatevalues xftv
    SET --enabled_flag  = 'N',        --Modified for ver 2.0 post UAT testing 
        --end_date_active = sysdate   --Modified for ver 2.0 post UAT testing 
        enabled_flag  = 'Y',          --Modified for ver 2.0 post UAT testing
	end_date_active = NULL        --Modified for ver 2.0 post UAT testing
  WHERE SOURCE_VALUE2 LIKE 'Sales Person'
    AND xftv.translate_id IN
           (SELECT xftd.translate_id
              FROM xx_fin_translatedefinition xftd
             WHERE xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
            );
COMMIT;
SHOW ERRORS;