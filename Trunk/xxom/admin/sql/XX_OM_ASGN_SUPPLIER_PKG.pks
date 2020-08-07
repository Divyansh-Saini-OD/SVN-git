SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_om_asgn_supplier_pkg AUTHID CURRENT_USER
AS

  -- +===========================================================================================+
  -- |                              Office Depot - Project Simplify                              |
  -- |                          Oracle NAIO/WIPRO/Office Depot/Consulting Organization           |
  -- +===========================================================================================+
  -- | Package Name : XX_OM_ASGN_SUPPLIER_PKG                                                    |
  -- | Rice ID      : E1064_AssingSupplierOM                                                     |
  -- | Description  : This package contains procedure which identify supplier site who can       |
  -- |                fulfil the order and populates DFF on order line.These procedures would    |
  -- |                be invoked only for Drop ship and Back-to-Back order lines.                |
  -- |                                                                                           |
  -- | Procedure Name            Description                                                     |
  -- |________________           ____________                                                    |
  -- | xx_om_drop_ship_proc      Extracts the vendor details who can fulfil the                  |
  -- |                           drop ship order line                                            |
  -- |                                                                                           |
  -- | xx_om_back_to_back_proc   Extracts the vendor details who can fulfil the                  |
  -- |                           back-to-back order line                                         |
  -- | Change Record:                                                                            |
  -- |================                                                                           |
  -- |                                                                                           |
  -- | Version       Date            Author                  Description                         |
  -- |=========     ==============   =================      ================                     |
  -- | DRAFT 1A     15-Jan-2007     Vikas Raina             Initial draft version                |
  -- | DRAFT 1B                     Vikas Raina             After Peer Review Changes            |
  -- | 1.0                          Vikas Raina             Baselined                            |
  -- | 1.1          28-Feb-2007     Neeraj Raghuvanshi      As per CR email from Milind on       |
  -- |                                                      21-Feb-2007, the procedure           |
  -- |                                                      XX_OM_DROP_SHIP_PROC   is modified to|
  -- |                                                      get Desktop Delivery Address for Drop|
  -- |                                                      Ship and Non Code Drop Ship Orders.  |
  -- | 1.2          03-Apr-2007     Faiz Mohammad           AS per update in the MD070 addedlogic|
  -- |                                                      for context type drop ship,          |
  -- |                                                      Noncode Dropship,Back To Back,       |
  -- |                                                      Non Code Back to Back                |
  -- | 1.3          16-Apr-2007     Faiz Mohammad           Added logic for checking if line type|
  -- |                                                         is null                           |
  -- | 1.4          06-Jun-2007     Sudharsana Reddy        Formatted the code according to      |
  -- |                                                      the new coding standards doc MD040   |
  -- | 1.5          21-Jun-2007     Sudharsana Reddy        Modified the Global Exception Part   |
  -- +===========================================================================================+


-- ----------------------------------
-- Global Variable Declarations
-- ----------------------------------

exception_object_type xx_om_report_exception_t := xx_om_report_exception_t('OTHERS'
                                                                          ,'OTC'
                                                                          ,'External Fulfillment'
                                                                          ,'Assign Supplier OM'
                                                                          ,NULL
                                                                          ,NULL
                                                                          ,'ORDER_LINE_ID'
                                                                          ,NULL);
-- -----------------------------------
-- Procedures Declarations
-- -----------------------------------

    -- +===================================================================+
    -- | Name  : xx_log_exception_proc                                     |
    -- | Description : Procedure to log exceptions from this package using |
    -- |               the Common Exception Handling Framework             |
    -- |                                                                   |
    -- | Parameters :       Error_Code                                     |
    -- |                    Error_Description                              |
    -- |                    Entity_Reference_Id                            |
    -- |                                                                   |
    -- +===================================================================+

PROCEDURE xx_log_exception_proc  ( p_error_code        IN  VARCHAR2
                                  ,p_error_description IN  VARCHAR2
                                  ,p_entity_ref_id     IN  NUMBER
                                 );

    -- +===================================================================+
    -- | Name  : xx_om_drop_ship_proc                                      |
    -- | Description : Extracts the vendor details who can fulfil the drop |
    -- |               ship order line                                     |
    -- |                                                                   |
    -- | Parameters :       p_line_id                                      |
    -- |                    p_source_type_code                             |
    -- |                                                                   |
    -- | Returns    :       x_vendor_id                                    |
    -- |                    x_vendor_site_id                               |
    -- |                    x_loc_var                                      |
    -- |                    x_dropship_type                                |
    -- +===================================================================+


PROCEDURE xx_om_drop_ship_proc (
                                p_line_id               IN         NUMBER
                               ,p_source_type_code      IN         VARCHAR2
                               ,x_vendor_id             OUT NOCOPY NUMBER
                               ,x_vendor_site_id        OUT NOCOPY NUMBER
                               ,x_loc_var               OUT NOCOPY VARCHAR2 --Included in Version 1.2
                               ,x_dropship_type         OUT NOCOPY VARCHAR2 --Included in Version 1.2
                              );
    -- +===================================================================+
    -- | Name  : xx_om_drop_ship_proc                                      |
    -- | Description : Extracts the vendor details who can fulfil the      |
    -- |               back-to-back order line                             |
    -- |                                                                   |
    -- | Parameters :       p_item_id                                      |
    -- |                    p_source_type_code                             |
    -- |                                                                   |
    -- | Returns    :       x_vendor_id                                    |
    -- |                    x_vendor_site_id                               |
    -- |                    x_backtoback_type                              |
    -- |                                                                   |
    -- +===================================================================+

PROCEDURE xx_om_back_to_back_proc  (
                                     p_line_id               IN  NUMBER
                                    ,p_source_type_code      IN  VARCHAR2
                                    ,p_item_id               IN  NUMBER
                                    ,x_vendor_id             OUT NOCOPY  NUMBER
                                    ,x_vendor_site_id        OUT NOCOPY  NUMBER
                                    ,x_backtoback_type       OUT NOCOPY  VARCHAR2 --Included in Version 1.2
                                   );

END xx_om_asgn_supplier_pkg ;
/

SHOW ERRORS;