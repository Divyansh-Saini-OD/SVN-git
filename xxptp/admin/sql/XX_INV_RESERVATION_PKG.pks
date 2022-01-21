SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_GI_RESERVATION_PKG AUTHID CURRENT_USER
AS
-- +==============================================================================+
-- |                  Office Depot - Project Simplify                             |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                  |
-- +==============================================================================+
-- |                                                                              |
-- |                                                                              |
-- |Change Record:                                                                |
-- |===============                                                               |
-- |Version   Date        Author           Remarks                                |
-- |=======   ==========  =============    =======================================|
-- |Draft 1a  30-OCT-2007 Siddharth Singh  Initial draft version                  |
-- +==============================================================================+



PROCEDURE Inventory_Reservation (p_reserve_option                IN VARCHAR2
                                ,p_reservation_key               IN VARCHAR2
                                ,p_demand_type_id                IN VARCHAR2  DEFAULT 13
                                ,p_location                      IN VARCHAR2
                                ,p_item_number                   IN VARCHAR2
                                ,p_primary_uom_code              IN VARCHAR2
                                ,p_reservation_uom_code          IN VARCHAR2
                                ,p_primary_reservation_quantity  IN NUMBER
                                ,p_creation_date                 IN VARCHAR2
                                ,p_subinventory                  IN VARCHAR2  DEFAULT 'STOCK'
                                ,p_attribute11                   IN VARCHAR2
                                ,p_attribute12                   IN VARCHAR2
                                ,p_attribute13                   IN VARCHAR2
                                ,p_attribute14                   IN VARCHAR2
                                ,p_attribute15                   IN VARCHAR2
                                ,x_status                        OUT VARCHAR2
                                ,x_error_message                 OUT VARCHAR2
                                 );

END XX_GI_RESERVATION_PKG;
/
SHOW ERRORS;
EXIT;
