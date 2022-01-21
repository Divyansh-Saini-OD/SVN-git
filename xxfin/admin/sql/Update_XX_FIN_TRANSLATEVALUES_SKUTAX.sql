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
-- | Name        : Update_XX_FIN_TRANSLATEVALUES_SKUTAX                    |
-- | Description : Update script for XX_CDH_EBILLING_FIELDS                |
-- |Change History:                                                        |
-- |---------------                                                        |
-- | DEFECT ID :                                                           |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     20-SEP-2018 Capgemini          Updating for SKU Level Tax     |
-- |                                        and SKU Level Total fields     |
-- +=======================================================================+

PROMPT
PROMPT Creating Index....
PROMPT

 UPDATE xx_fin_translatevalues xftv
    SET source_value10='N'
  WHERE SOURCE_VALUE1 in (10167,10168)
    AND xftv.translate_id IN
        (SELECT xftd.translate_id
           FROM xx_fin_translatedefinition xftd
          WHERE xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
        );
COMMIT;
SHOW ERRORS;
