SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_ASGN_SUPPLIER_PKG AUTHID CURRENT_USER
AS

 -- +===========================================================================================+
 -- |                              Oracle NAIO (India)                                          |
 -- |                               Bangalore,  India                                           |
 -- +===========================================================================================+
 -- | Package Name : XX_OM_ASGN_SUPPLIER_PKG                                                    |
 -- | Description  : This package contains procedure which identify supplier site who can       |
 -- |                fulfil the order and populates DFF on order line.These procedures would    |
 -- |                be invoked only for Drop ship and Back-to-Back order lines.                |
 -- |                                                                                           |
 -- | Procedure Name            Description                                                     |
 -- |________________           ____________                                                    |
 -- | XXOE_DROP_SHIP_PROC       Extracts the vendor details who can fulfil the                  |
 -- |                           drop ship order line                                            |
 -- |                                                                                           |
 -- | XXCTO_BACK_TO_BACK_PROC   Extracts the vendor details who can fulfil the                  |
 -- |                           back-to-back order line                                         |
 -- | Change Record:                                                                            |
 -- |================                                                                           |
 -- |                                                                                           |
 -- | Version       Date            Author                  Description                         |
 -- |=========     ==============   =================      ================                     |
 -- | DRAFT 1A      15-Jan-2007     Vikas Raina            Initial draft version                |
 -- | DRAFT 1B                      Vikas Raina            After Peer Review Changes            |
 -- | 1.0                           Vikas Raina            Baselined                            |
 -- | 1.1           28-Feb-2007     Neeraj Raghuvanshi     As per CR email from Milind on       |
 -- |                                                      21-Feb-2007, the procedure           |
 -- |                                                      XX_OM_DROP_SHIP_PROC is modified to  |
 -- |                                                      get Desktop Delivery Address for Drop|
 -- |                                                      Ship and Non Code Drop Ship Orders.  |
 -- |1.2            3-Apr-2007      Faiz Mohammad          AS per update in the MD070 addedlogic|
 -- |                                                      for context type drop ship,          |
 -- |                                                      Noncode Dropship,Back To Back,       |
 -- |                                                      Non Code Back to Back                |
 -- |1.3           16-Apr-2007     Faiz Mohammad           Added logic for checking if line type| 
 -- |                                                         is null                           |
 -- +===========================================================================================+

--  Global constant holding the package name

-- Version 1.2 --Included
G_exception_header   CONSTANT VARCHAR2(40) := 'OTHERS';
G_track_code         CONSTANT VARCHAR2(5)  := 'OTC';
G_solution_domain    CONSTANT VARCHAR2(40) := 'External Fulfillment';
G_entity_ref         CONSTANT VARCHAR2(40) := 'ORDER LINE ID';
G_entity_ref_id      NUMBER;


-- Variable Declaration for exception handling
exception_object_type xxod_report_exception:= xxod_report_exception(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
/*-----------------------------------------------------------------------------
PROCEDURE  : XX_LOG_EXCEPTION_PROC
DESCRIPTION: Procedure to log Exceptions.

------------------------------------------------------------------------------*/
Procedure XX_LOG_EXCEPTION_PROC  (   p_error_code        IN  VARCHAR2
                                    ,p_error_description IN  VARCHAR2
                                    ,p_function          IN  VARCHAR2
                                    ,p_entity_ref        IN  VARCHAR2
                                    ,p_entity_ref_id     IN  NUMBER
                                   );


-- End -- Version 1.2
/*-------------------------------------------------------------------------
PROCEDURE  : XX_OM_DROP_SHIP_PROC
DESCRIPTION: Extracts the vendor details who can fulfil the drop ship order.
                        line
---------------------------------------------------------------------------*/
Procedure XX_OM_DROP_SHIP_PROC (
                                p_line_id               IN  NUMBER
                               ,p_source_type_code      IN  VARCHAR2
                               ,x_vendor_id             OUT NUMBER
                               ,x_vendor_site_id        OUT NUMBER
                               ,x_loc_var               OUT VARCHAR2 --Included in Version 1.2
                               ,x_dropship_type         OUT VARCHAR2 --Included in Version 1.2
                              );

/*-----------------------------------------------------------------------------
PROCEDURE  : XX_OM_BACK_TO_BACK_PROC
DESCRIPTION: Extracts the vendor details who can fulfil the back-to-back order
                        line.
------------------------------------------------------------------------------*/
Procedure XX_OM_BACK_TO_BACK_PROC  (
                                     p_line_id               IN   NUMBER
				    ,p_source_type_code      IN   VARCHAR2
				    ,p_item_id               IN   NUMBER
				    ,x_vendor_id             OUT  NUMBER
				    ,x_vendor_site_id        OUT  NUMBER
                                    ,x_backtoback_type       OUT  VARCHAR2 --Included in Version 1.2
                                   );

END XX_OM_ASGN_SUPPLIER_PKG ;
/
SHOW ERRORS

--EXIT;
