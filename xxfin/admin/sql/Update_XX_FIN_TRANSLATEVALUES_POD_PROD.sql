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
-- | Name        : Update_XX_FIN_TRANSLATEVALUES_POD_PROD                  |
-- | Description : Update script for XX_CDH_EBILLING_FIELDS                |
-- |Change History:                                                        |
-- |---------------                                                        |
-- | DEFECT ID :                                                           |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     11-FEB-2019 Capgemini          Updating DTS integration       |
-- |                                        URL/credentials specific       |
-- |                                        for PROD                       |
-- +=======================================================================+

PROMPT
PROMPT Updating translation....
PROMPT

 UPDATE xx_fin_translatevalues xftv
    SET target_value1 = 'https://osbprd01.na.odcorp.net/osb-infra/eai/REST/ShipmentService/getOrderShipmentStatus',
        target_value2 = 'SVC-ECOMWS',
        target_value3 = 'kdl7F2nq'
  WHERE xftv.translate_id IN
        (SELECT xftd.translate_id
           FROM xx_fin_translatedefinition xftd
          WHERE xftd.translation_name ='XX_AR_EBL_REST_SERVICE_DT'
        );
COMMIT;
SHOW ERRORS;
