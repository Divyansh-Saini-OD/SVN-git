 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 PROMPT Creating Package Specification XX_WSH_SHIPPING_LABEL_PKG
 PROMPT Program exits if the creation is not successful
 WHENEVER SQLERROR CONTINUE
 
CREATE OR REPLACE
PACKAGE XX_WSH_SHIPPING_LABEL_PKG
 AS
 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                  |
 -- |                       WIPRO Technologies                          |
 -- +===================================================================+
 -- | Name :        Shipping Label                                      |
 -- | Rice ID:      E1292                                               |
 -- | Description : This package aids printing of Shipping Labels.      |
 -- |               It generates Shipping Label data in a format        |
 -- |               recognisable to Intermec Printer. The label data is |
 -- |               generated for Internal Sales Orders. When a sales   |
 -- |               order is confirmed for shipment, the labels are     |
 -- |               printed. The output of this program is in IPL       |
 -- |               language which is sent to the Intermec Printer for  |
 -- |               printing. A concurrent program with host execuatble |
 -- |               is submitted from this package to direct the output |
 -- |               to the printer.                                     |
 -- |Change Record:                                                     |
 -- |===============                                                    |
 -- |Version   Date          Author              Remarks                |
 -- |=======   ==========   =============        =======================|
 -- |1.0       25-SEP-2007  Hemalatha.S          Initial version        |
 -- |                       Wipro Technologies                          |
 -- |1.1       17-JUN-2013  Bapuji Nanapaneni    Added Rice ID          | 
 -- |1.2       30-JAN-2017  Avinash Baddam       Defect 38317           |
 -- |1.3       23-OCT-2017  Venkata Battu	     Defect 43375		    |
 -- +===================================================================+
 -- +===================================================================+
 -- | Name        : LABELS_DATA                                         |
 -- |                                                                   |
 -- | Description : This procedure will be the executable of Concurrent |
 -- |               Program " OD: WSH Shipping Label Data-Intermec "    |
 -- |                                                                   |
 -- | Parameters  :  x_error_buff, x_ret_code,p_trip_id                 |
 -- |               ,p_trip_stop_id,p_departure_date_low                |
 -- |               ,p_departure_date_high,p_freight_code               |
 -- |               ,p_delivery_id,p_container_id,p_organization_id,    |
 -- |                p_printer_name                                     |
 -- +===================================================================+

PROCEDURE LABELS_DATA (
                        x_error_buff            OUT      VARCHAR2
                        ,x_ret_code             OUT      NUMBER
                        ,p_trip_id              IN       VARCHAR2
                        ,p_trip_stop_id         IN       VARCHAR2
                        ,p_departure_date_low   IN       DATE
                        ,p_departure_date_high  IN       DATE
                        ,p_freight_code         IN       VARCHAR2
                        ,p_organization_id      IN       VARCHAR2
                        ,p_delivery_id          IN       NUMBER
                        ,p_container_id         IN       VARCHAR2
                        ,p_reprint              IN       VARCHAR2
                       );

PROCEDURE LOAD_TRACKING_DATA(
                         x_error_buff           OUT      VARCHAR2
                        ,x_ret_code             OUT      NUMBER
                        ,p_filename		IN	 VARCHAR2
                        );
						
PROCEDURE REPROCESS_LABELS_DATA(x_error_buff  OUT  VARCHAR2      -- Procedure added for the defect#43375
                               ,x_ret_code    OUT  VARCHAR2
                               ,p_order_nbr    IN  VARCHAR2
                               ,p_tracking_id  IN  NUMBER
							   ,p_days         IN  NUMBER 
                               ,p_debug_lvl    IN  VARCHAR2 DEFAULT 'N'			   
                               );						

END XX_WSH_SHIPPING_LABEL_PKG;
/
SHOW ERR