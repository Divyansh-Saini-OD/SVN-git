---+========================================================================================================+        
---|                                        Office Depot - Project Simplify                                 |
---|                                                                                                        |
---+========================================================================================================+
---|    Application             : AR                                                                        |
---|                                                                                                        |
---|    Name                    : XX_OM_SHIPPING_STATUS_V.vw                                                           |
---|                                                                                                        |
---|    Description             : This view is being created for the defect 2481 for having a DB link       |
---|                              Between the OM tables and Taxware for the taxware monthend extract.       |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                    |
---|    ------------    ----------------- ---------------    ---------------------                          |
---|    1.0             02-DEC-2009       Pradeep Krishnan   Initial Version                                |
---|    1.1             11-FEB-2016       Vasu Raparla        Removed Schema References for R.12.2          |                                                                                                 |
---+========================================================================================================+
CREATE OR REPLACE VIEW XX_OM_SHIPPING_STATUS_V AS
SELECT wdd.source_header_number order_number
     , wdd.source_header_id     header_id
     , wdd.source_line_id       line_id
     , wdd.source_line_number   line_number
     , wdd.requested_quantity   ordered_quantity
     , wdd.shipped_quantity     shipped_quantity
     , wdd.cancelled_quantity   cancelled_quantity
     , wdd.released_status      release_status
     , wl.meaning               status
     , ool.flow_status_code     flow_status_code
     , ool.request_date         requested_date
     , ool.actual_shipment_date actual_ship_date
     , ool.schedule_ship_date   schedule_ship_date
 FROM  wsh_delivery_details wdd
     , wsh_lookups wl
     , oe_order_lines_all ool
WHERE wdd.released_status = wl.lookup_code
  AND wl.lookup_type = 'PICK_STATUS'
  AND wdd.source_line_id = ool.line_id
  AND wdd.source_code = 'OE';   
/ 