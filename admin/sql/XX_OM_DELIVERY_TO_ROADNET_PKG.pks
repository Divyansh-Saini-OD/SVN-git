SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_om_delivery_to_roadnet_pkg AUTHID CURRENT_USER
IS
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name   : XX_OM_DELIVERY_TO_ROADNET_PKG                                                  |
-- | RICE ID: I1164_DeliveryToRoadNet                                                        |
-- | Description      : Package Body containing procedure for DeliveryToRoadnet              |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   27-FEB-2007       Faiz Mohammad    Initial draft version                      |
-- |DRAFT 1B   24-MAY-2007       Sudharsana       Validating XML According                   |
-- |                                              to GetCarrierroute.xsd and formatted code  |
-- |                                              according to New MD040 Standards           |
-- |                                                                                         |
-- |DRAFT 1C   11-Jun-2007       Shashi Kumar     Altered the code to include the callto BPEL|
-- |                                              to GetCarrierroute.xsd and formatted code  |
-- |                                              according to New MD040 Standards.          |
-- |                                              Altered the XML that has been generated    |
-- |1.0        12-Jun-2007       Shashi Kumar     Baselined after testing.                   |
-- |1.1        22-Jun-2007       Sudharsana       Alter the package/procudure name           |
-- |                                              Modified Global Exception part             |
-- +=========================================================================================+

g_exception xx_om_report_exception_t:= xx_om_report_exception_t( 'OTHERS'
                                                                ,'OTC'
                                                                ,'Order Management'
                                                                ,'Delivery To Roadnet'
                                                                ,NULL
                                                                ,NULL
                                                                ,'DELIVERY_ID'
                                                                ,NULL);

-- -----------------------------------
-- Procedures Declarations
-- -----------------------------------

    -- +===================================================================+
    -- | Name  : log_exceptions                                            |
    -- | Description : Procedure to log exceptions from this package using |
    -- |               the Common Exception Handling Framework             |
    -- |                                                                   |
    -- | Parameters :       Error_Code                                     |
    -- |                    Error_Description                              |
    -- |                    Entity_Reference_Id                            |
    -- |                                                                   |
    -- +===================================================================+

PROCEDURE log_exceptions ( p_error_code        IN  VARCHAR2
                          ,p_error_description IN  VARCHAR2
                          ,p_entity_ref_id     IN  NUMBER
                         );


-- +===================================================================+
-- | Name  :      delivery_to_roadnet                                  |
-- | Description: This procedure is used to import the deliveries      |
-- |              to roadnet                                           |
-- |                                                                   |
-- | Parameters:      p_delivery_id                                    |
-- | Returns :        x_xml                                            |
-- |                                                                   |
-- +===================================================================+

PROCEDURE delivery_to_roadnet (p_delivery_id IN NUMBER,
                               x_xml OUT NOCOPY XMLTYPE
                              );

END xx_om_delivery_to_roadnet_pkg;
/

SHOW ERRORS;
