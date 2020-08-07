SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE
PACKAGE XX_OM_INTREQ_PKG 
-- +============================================================================================+
-- |                  Office Depot - Project Simplify                                           |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                                |
-- +============================================================================================+
-- | Name         : XX_OM_INTREQ_PKG                                                            |
-- | Rice Id      : E1279                                                                       |
-- | Description  : Package Specification                                                       |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author           		Remarks                                 |
-- |=======    ==========    =============    	     ===========================                |
-- |V1.0       28-MAY-2007   SANDEEP GORLA(WIPRO)     Initial draft version                     |
-- |V1.1       12-JUN-2007   SANDEEP GORLA(WIPRO)     Modified the code to look at segment18    |
-- |                                                  instead of segment16 as the segment was   |
-- |                                                  not defined in front end while developing |
-- |                                                  the code.                                 |
-- |V1.2       09-JUL-2007   SANDEEP GORLA(WIPRO)     Modified the code to write the error mess.|
-- |                                                  to exception pool.                        |  
-- |V1.3       23-JUL-2007   SANDEEP GORLA(WIPRO)     Modified the code to implement new        |
-- |                                                  attribute structure.                      |
-- +============================================================================================+  
AS
  
   --  Global constant holding the package name
     
      
     G_exception_header   CONSTANT VARCHAR2(40) := 'CrossDockCreateIntReq';
     G_track_code         CONSTANT VARCHAR2(5)  := 'OTC';
     G_solution_domain    CONSTANT VARCHAR2(40) := 'OrderManagement';
     G_function           CONSTANT VARCHAR2(40) := 'CrossDockCreateIntReq';
     
     
     
     -- Variable Declaration for exception handling
   exception_object_type xx_om_report_exception_t := xx_om_report_exception_t(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
  
  
   --Procedure to check whether the sales order is eligible for requisition creation or not                              
    PROCEDURE IS_SALES_ORDER_ELIGIBLE( x_retcode          OUT VARCHAR2
                                      ,x_errbuf           OUT VARCHAR2
                                      ,p_source           IN  VARCHAR2
                                      ,p_order_number     IN  NUMBER
                                      ,p_from_Date        IN  DATE
                                      ,p_to_date          IN  DATE
                                      );
    
  --Procedure to insert sales order information into requisition interface table
  --to create internal requisition
    PROCEDURE INSERT_INTREQ_INTF (x_retcode        OUT VARCHAR2
                                 ,x_errbuf         OUT VARCHAR2
                                 ,p_source         IN  Po_Requisitions_Interface_All.interface_source_code%TYPE
                                 ,p_order_number   IN  Oe_Order_Headers_All.order_number%TYPE
                                 ,p_line_id        IN  Oe_Order_lines_All.line_id%TYPE);
 
END XX_OM_INTREQ_PKG;
/
SHOW ERRORS

