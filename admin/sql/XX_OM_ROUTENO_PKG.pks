SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE  XX_OM_ROUTENO_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name  : XX_OM_ROUTENO_PKG.pks                                     |
-- | Rice ID      :I0311_WholesalerRoutingNo                           |
-- | Description      : This package is used to update route number    |
-- |                    obtained from transport web service to the TRIP|
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   17-APR-2007   Francis M        Initial draft version    |
-- |1.0        19-JUN-2007   Hema Chikkanna   Updated the Comments     |
-- |                                          Section as per onsite    |
-- |                                          requirement              |
-- |1.1        29-JUN-2007   Hema Chikkanna   Updated the file name    |
-- |                                          Section as new MD40 Std  |
-- +===================================================================+

ge_exception xx_om_report_exception_t := xx_om_report_exception_t
                                                            (
                                                                'OTHERS'
                                                               ,'OTC'
                                                               ,'Pick Release'
                                                               ,'WholeSalerRoutingNo'
                                                               ,NULL
                                                               ,NULL
                                                               ,'DELIVERY ID'
                                                               ,NULL
                                                            );

----------------------------------------------------
-- Procedure to extract the Customer location 
-- and warehouse details for the given Delivery ID
-- and passing it on to Roadnet system to get the 
-- Preferred Route ID
----------------------------------------------------
PROCEDURE  get_routeno (
                         p_delivery_id   IN         PLS_INTEGER
                        ,x_region_id     OUT NOCOPY PLS_INTEGER 
                        ,x_location_id   OUT NOCOPY VARCHAR2
                        ,x_location_type OUT NOCOPY VARCHAR2
                        ,x_status        OUT NOCOPY VARCHAR2
                       ); 

------------------------------------------------
-- This procedure will be used to update the
-- Route Number for the given Delivery and TRIP
-------------------------------------------------
PROCEDURE   update_routeno( 
                            p_delivery_id  IN  PLS_INTEGER
                           ,p_route_no     IN  VARCHAR2
                           ,x_error_msg    OUT NOCOPY VARCHAR2                           
                          );   
                          

                       
END  XX_OM_ROUTENO_PKG;
/

SHOW ERRORS;

EXIT;

