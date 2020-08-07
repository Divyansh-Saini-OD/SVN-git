CREATE OR REPLACE VIEW XX_CRM_BULK_RESP_SETUP_V 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name         : XX_CRM_BULK_RESP_SETUP_V                           |
-- | CR           : CR769                                              |
-- | Description  : This view is FINTRANS Table setup which is used to |
-- |                hide the type of Import based upon the             |
-- |                Responsibility that the user logs in.              |
-- |Change Record :                                                    |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |Draft 1a 29-Jun-2010  Mangalasundari K Initial draft version       |
-- +===================================================================+
AS 

SELECT xftv.source_value1 TEMPLATE_ID ,
    xftv.source_value2 RESPONSIBILITY_ID ,
    xftv.source_value3 TEMPLATE_CODE ,
    xftv.source_value4 RESPONSIBILITY_KEY ,
    xftv.source_value5 TEMPLATE_NAME
  FROM xx_fin_translatedefinition xftd ,
    xx_fin_translatevalues xftv
  WHERE xftd.translate_id   = xftv.translate_id
  AND xftd.translation_name ='OD_RESP_TEMPLATE'
  AND xftv.END_DATE_ACTIVE IS NULL
  AND xftv.ENABLED_FLAG     ='Y';


WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
