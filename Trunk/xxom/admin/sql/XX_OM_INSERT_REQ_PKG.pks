SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE
PACKAGE XX_OM_INSERT_REQ_PKG 
-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |                    WIPRO Consulting Organization                                          |
-- +===========================================================================================+
-- | Name         : XX_OM_INSERT_REQ_PKG                                                       |
-- | Rice Id      : E1279                                                                      | 
-- | Description  : Package Specification                                                      |
-- |                                                                                           |
-- |Change Record:                                                                             | 
-- |===============                                                                            |
-- |Version    Date          Author           		Remarks                                |
-- |=======    ==========    =============    	     ========================================= |
-- |V1.0      21-MAY-2007   SANDEEP GORLA(WIPRO)    Initial draft version		       |
-- |V1.1      07-JUN-2007   SANDEEP GORLA(WIPRO)    Changed the code to assign error_code      |
-- |                                                direclty to the global exception procedure |
-- |						    XX_LOG_EXCEPTION_PROC instead of custom    |   
-- |                                                numbers.				       |
-- |V1.2      10-JUL-2007   SANDEEP GORLA(WIPRO)    Modified the code to remove hardcoding of  |
-- |                                                attribute_category and assign to a variable|
-- +===========================================================================================+

AS						     				     
  
  --  Global constant holding the package name
  
   
  G_exception_header   CONSTANT VARCHAR2(40) := 'CrossDockReqInterface';
  G_track_code         CONSTANT VARCHAR2(5)  := 'OTC';
  G_solution_domain    CONSTANT VARCHAR2(40) := 'OrderManagement';
  G_function           CONSTANT VARCHAR2(40) := 'CrossDockReqInterface';
  
  
  
  -- Variable Declaration for exception handling
exception_object_type xx_om_report_exception_t := xx_om_report_exception_t(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
  
  
  --Procedure to insert sales order information into requisition interface table
  --to create internal requisition
  PROCEDURE INSERT_INTO_REQ_INTF (p_source            IN   PO_REQUISITIONS_INTERFACE_ALL.interface_source_code%TYPE
                                 ,p_inv_item_id       IN   OE_ORDER_LINES_ALL.inventory_item_id%TYPE
                                 ,p_uom               IN   OE_ORDER_LINES_ALL.order_quantity_uom%TYPE
                                 ,p_ord_quantity      IN   OE_ORDER_LINES_ALL.ordered_quantity%TYPE
                                 ,p_need_by_date      IN   OE_ORDER_LINES_ALL.schedule_ship_date%TYPE
                                 ,p_dest_org_id       IN   MTL_PARAMETERS.organization_id%TYPE
                                 ,p_delivery_loc_id   IN   HR_LOCATIONS_ALL.location_id%TYPE
                                 ,p_source_org_id     IN   MTL_PARAMETERS.organization_id%TYPE
                                 ,p_dest_subinv_code  IN   VARCHAR2
                                 ,p_so_order_number   IN   OE_ORDER_HEADERS_ALL.order_number%TYPE
                                 ,p_so_line_id        IN   OE_ORDER_LINES_ALL.line_id%TYPE
                                 ,x_result            OUT  VARCHAR2);

END XX_OM_INSERT_REQ_PKG;
/
SHOW ERRORS

