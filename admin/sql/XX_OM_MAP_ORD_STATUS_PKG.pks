SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_om_map_ord_status_pkg AUTHID CURRENT_USER

-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : XX_OM_MAP_ORD_STATUS_PKG                                    |
-- | Rice ID     : E1264_TranslateMapOMOrderStatus                             |
-- | Description : Update the statuses on the Order Header Level and Order Line|
-- |               Level DFF attributes to reflect the various custom statuses |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 21-Jun-2007  Sudharsana Reddy       Initial draft version         |
-- |1.0      01-Aug-2007  Vidhya Valantina T     Baselined after testing       |
-- |                                                                           |
-- +===========================================================================+

AS

-- ----------------------------------
-- Global Variable Declarations
-- ----------------------------------

  exception_object_type xx_om_report_exception_t := xx_om_report_exception_t('OTHERS'
                                                                            ,'OTC'
                                                                            ,'Order Cycle'
                                                                            ,'Translate Map OM Order Status'
                                                                            , NULL
                                                                            , NULL
                                                                            , NULL
                                                                            , NULL);
-- -----------------------------------
-- Procedures Declarations
-- -----------------------------------

    -- +===================================================================+
    -- | Name  : Write_Exception                                           |
    -- | Description : Procedure to log exceptions from this package using |
    -- |               the Common Exception Handling Framework             |
    -- |                                                                   |
    -- | Parameters :       Error_Code                                     |
    -- |                    Error_Description                              |
    -- |                    Entity_ref                                     |
    -- |                    Entity_Reference_Id                            |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Write_Exception ( p_error_code        IN  VARCHAR2
                               ,p_error_description IN  VARCHAR2
                               ,p_entity_ref        IN  VARCHAR2
                               ,p_entity_ref_id     IN  NUMBER
                              );

    -- +===================================================================+
    -- | Name        : Attribute_Update                                    |
    -- | Description : Procedure updates DFF attributes with Translated    |
    -- |               Custom Status on Order header and line levels.      |
    -- |                                                                   |
    -- | Parameters  : Header_Id                                           |
    -- |               Line_Id                                             |
    -- |               Lookup_Code                                         |
    -- |                                                                   |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Attribute_Update ( p_header_id   IN NUMBER DEFAULT NULL
                                ,p_line_id     IN NUMBER DEFAULT NULL
                                ,p_lookup_code IN VARCHAR2
                               );


    -- +===================================================================+
    -- | Name        :  Status_Update                                      |
    -- | Description :  Procedure is derive the custom (order,line) status |
    -- |                code from lookup based on Priority wise            |
    -- |                                                                   |
    -- | Parameters  :  Order_Header_Id                                    |
    -- |                Order_Line_Id                                      |
    -- |                Event                                              |
    -- |                Hold_Level                                         |
    -- |                                                                   |
    -- | Returns     :  Return_Status                                      |
    -- |                                                                   |
    -- +===================================================================+


    PROCEDURE Status_Update ( p_order_header_id  IN  NUMBER   DEFAULT NULL
                             ,p_order_line_id    IN  NUMBER   DEFAULT NULL
                             ,p_event            IN  NUMBER
                             ,p_hold_level       IN  VARCHAR2 DEFAULT NULL
                             ,x_return_status    OUT VARCHAR2
                            );

END xx_om_map_ord_status_pkg;
/

SHOW ERRORS;