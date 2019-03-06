SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_ONT_DELIVERY_TO_ROADNET_PKG
IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XXOD_DELIVERY_TO_ROADNET_PKG                              |
-- | Description      : Package Specification containing procedure     |
-- |                    for DeliveryToRoadnet                          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   27-FEB-2007   Faiz Mohammad    Initial draft version    |
-- |DRAFT 2A   06-JUN-2007   Sudharsana Reddy Formated the code against|
-- |                                          to New MD040             |
-- +===================================================================+

g_exception xx_om_report_exception_t:= xx_om_report_exception_t('OTHERS','OTC','Order Management','Delivery To Roadnet',NULL,NULL,NULL,NULL);

-- +===================================================================+
-- | Name  : log_exceptions                                            |
-- | Description: This procedure is used to log the exceptions         |
-- |                                                                   |
-- | Parameters:                                                       |
-- | Returns :                                                         |
-- |                                                                   |
-- +===================================================================+

PROCEDURE log_exceptions;

-- +===================================================================+
-- | Name  : xx_om_delivery_to_roadnet                                 |
-- | Description: This procedure is used to import the deliveries      |
-- |              to roadnet                                           |
-- |                                                                   |
-- | Parameters:                                                       |
-- | Returns :                                                         |
-- |                                                                   |
-- +===================================================================+

PROCEDURE delivery_to_roadnet (p_delivery_id IN NUMBER,
                               x_xml OUT NOCOPY XMLTYPE
                              );

END XX_ONT_DELIVERY_TO_ROADNET_PKG;
/
SHOW ERRORS;
EXIT;