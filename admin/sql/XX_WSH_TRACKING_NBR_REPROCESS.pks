CREATE OR REPLACE PACKAGE XX_WSH_TRACKING_NBR_REPROCESS
AS
-- +========================================================================================================================+
-- |                  Office Depot - Project Simplify                                                                       |
-- |                  Office Depot                                                                                          |
-- +========================================================================================================================+
-- | Name  : XX_WSH_TRACKING_NBR_REPROCESS                                                                                  |
-- | Rice ID: I1272                                                                                                         |
-- | Description      : This Program will re-process the tracking number from EBIZ to DB2                                   |
-- |                                                                                                                        |
-- |                                                                                                                        |
-- |Change Record:                                                                                                          |
-- |===============                                                                                                         |
-- |Version     Date          Author                     Remarks                                                            |
-- |=======     ==========    =============              ==============================                                     |
-- |DRAFT 1A    18-OCT-2017   Venkata Battu              Initial draft version                                              |
-- +========================================================================================================================+
PROCEDURE main( x_error_buff  OUT  VARCHAR2
               ,x_ret_code    OUT  VARCHAR2
               ,p_tracking_id  IN  NUMBER
               ,p_order_nbr    IN  VARCHAR2
               ,p_delivery_id  IN  NUMBER
               ,p_trip_id      IN  NUMBER
               ,p_debug_lvl    IN  NUMBER DEFAULT 0			   
             );
END XX_WSH_TRACKING_NBR_REPROCESS;
/
			  