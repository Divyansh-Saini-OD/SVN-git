CREATE OR REPLACE VIEW apps.XX_CRM_BULK_RESP_SETUP_V (TEMPLATE_ID
						     ,RESPONSIBILITY_ID
						     ,TEMPLATE_CODE
						     ,RESPONSIBILITY_KEY
						     ,TEMPLATE_NAME)
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name         : XX_CRM_BULK_RESP_SETUP_V.vw                        |
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
  FROM apps.xx_fin_translatedefinition xftd ,
       apps.xx_fin_translatevalues xftv
  WHERE xftd.translate_id   = xftv.translate_id
  AND xftd.translation_name ='OD_RESP_TEMPLATE'
  AND SYSDATE BETWEEN xftv.start_date_active AND NVL (xftv.end_date_active, SYSDATE)
  AND xftv.ENABLED_FLAG     ='Y';
/

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
