SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_ROADNET_TO_EBS_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XX_OM_ROADNET_TO_EBS_PKG                                  |
-- | RICE ID : I1014_RoadnetToEBS                                      |
-- | Description      : Package Specification containing Updation of   |
-- |                    route number and stop number in EBS which is   |  
-- |                    sent by Roadnet System.                        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   25-Apr-2007   Shashi Kumar.    Initial Draft version    |
-- |                                                                   |
-- +===================================================================+
AS

g_exception xx_om_report_exception_t := xx_om_report_exception_t('OTHERS','OTC','Order Management','RoadNet TO EBS',NULL,NULL,NULL,NULL);

lt_delivery_attributes xx_wsh_delivery_att_t := xx_wsh_delivery_att_t(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

TYPE XX_OM_DELIVERY_REC_TYPE IS RECORD(
                                       regionid         VARCHAR2(240),
                                       delivery_number  VARCHAR (30),
                                       delivery_date    DATE,
                                       route_number     VARCHAR2(240),
                                       stop_number      VARCHAR2(240),
                                       user_field3      VARCHAR2(10)
                                      );

TYPE XX_OM_DELIVERY_TBL 
IS TABLE OF XX_OM_DELIVERY_REC_TYPE INDEX BY BINARY_INTEGER;

-- +===================================================================+
-- | Name  : Log_Exceptions                                            |
-- | Description: This procedure will be responsible to store all      |
-- |              the exceptions occured during the procees using      |
-- |              global custom exception handling framework           |
-- |                                                                   |
-- | Parameters:  p_error_code , p_error_description                   |
-- |                                                                   |
-- | Returns :    None                                                 |
-- +===================================================================+

PROCEDURE log_exceptions(
                         p_error_code        IN  VARCHAR2
                        ,p_error_description IN  VARCHAR2
                        );

-- +===================================================================+
-- | Name  : import_route                                              |
-- |                                                                   |
-- | Description: This Procedure is used to update the route and       |
-- |              delivery details in EBS.                             |
-- |                                                                   |
-- | Parameters:  p_delivery_tbl                                       |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- +===================================================================+

PROCEDURE import_route(
                       p_delivery_tbl IN  XX_OM_DELIVERY_TBL
                      );
          
END XX_OM_ROADNET_TO_EBS_PKG;
/

SHOW ERRORS;
EXIT;