CREATE OR REPLACE VIEW apps.XXFIN_BULK_RESP_SETUP_V (TEMPLATE_ID
						     ,RESPONSIBILITY_ID
						     ,TEMPLATE_CODE
						     ,RESPONSIBILITY_KEY
						     ,TEMPLATE_NAME)
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name         : XXFIN_BULK_RESP_SETUP_V.vw                         |
-- | CR           :                                                    |
-- | Description  : This view is FINTRANS Table setup which is used to |
-- |                hide the type of Import based upon the             |
-- |                Responsibility that the user logs in.              |
-- | RICE : E3056                                                      |
-- |Change Record :                                                    |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ============================|
-- |Draft 1   12-May-2013  Satish Silveri   Initial draft version       |
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
  AND xftd.translation_name ='OD_FIN_UPLOAD_TEMPLATES'
  AND SYSDATE BETWEEN xftv.start_date_active AND NVL (xftv.end_date_active, SYSDATE)
  AND xftv.ENABLED_FLAG     ='Y';
/

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
