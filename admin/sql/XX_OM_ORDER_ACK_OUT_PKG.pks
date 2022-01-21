SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        : XX_OM_ORDER_ACK_OUT_PKG                             |
-- | RICE ID     : I0194_OrdAck                                        |
-- | Description : Package containing procedures to extract the Order  |
-- |               acknowledgement related data from the EBS.          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A  01-Jan-2007    Shashi Kumar    Initial draft version     |
-- |                                                                   |
-- +===================================================================+

CREATE OR REPLACE PACKAGE XX_OM_ORDER_ACK_OUT_PKG
AS

g_exception xx_om_report_exception_t:= xx_om_report_exception_t('OTHERS','OTC','Order Management','Order Acknowledgement',NULL,NULL,NULL,NULL);

-- +===================================================================+
-- | Name       : Log_Exceptions                                       |
-- | Description: This procedure will be responsible to store all      |
-- |              the exceptions occured during the procees using      |
-- |              global custom exception handling framework           |
-- |                                                                   |
-- | Parameters:  p_error_code , p_error_description                   |
-- |                                                                   |
-- | Returns :    None                                                 |
-- +===================================================================+

PROCEDURE log_exceptions(
                         p_error_code        IN  VARCHAR2
                        ,p_error_description IN  VARCHAR2
                        );

-- +===================================================================+
-- | Name       : order_ack_header                                     |
-- |                                                                   |
-- | Description: This Procedure is used to derive and extract the     |
-- |              Order Header details.                                |
-- |                                                                   |
-- | Parameters : p_header_id                                          |
-- |              p_order_source                                       |
-- |              p_subtotal                                           |
-- |              p_fr_ord_tot                                         |
-- |              p_misc_ord_tot                                       |
-- |              p_tax_value                                          |
-- |              p_email                                              |
-- |              p_ftp                                                |
-- |              p_record_type                                        |
-- |              p_odemanddt                                          |
-- |              p_ofrom                                              |
-- | Returns    : None                                                 |
-- |                                                                   |
-- +===================================================================+

PROCEDURE order_ack_header(p_header_id     IN  NUMBER,
                           p_order_source  IN  VARCHAR2,
                           p_subtotal      OUT NUMBER,
                           p_fr_ord_tot    OUT NUMBER,
                           p_misc_ord_tot  OUT NUMBER,
                           p_tax_value     OUT NUMBER,
                           p_email         OUT VARCHAR2,
                           p_ftp           OUT VARCHAR2,
                           p_record_type   OUT VARCHAR2,
                           p_odemanddt     OUT VARCHAR2,
                           p_ofrom         OUT VARCHAR2
                          );

-- +===================================================================+
-- | Name       : order_ack_line                                       |
-- |                                                                   |
-- | Description: This Procedure is used to derive and extract the     |
-- |              Order Line details.                                  |
-- |                                                                   |
-- | Parameters : p_header_id                                          |
-- |              p_line_id                                            |
-- |              p_cross_item_type                                    |
-- |              p_unit_price                                         |
-- |              p_email                                              |
-- |              p_netamount                                          |
-- |              p_ship_qty                                           |
-- | Returns    : None                                                 |
-- |                                                                   |
-- +===================================================================+

PROCEDURE order_ack_line(p_header_id       IN NUMBER,
                         p_line_id         IN NUMBER,
                         p_cross_item_type OUT VARCHAR2,
                         p_unit_price      OUT NUMBER,
                         p_email           OUT VARCHAR2,
                         p_netamount       OUT NUMBER,
                         p_ship_qty        OUT NUMBER
                        );

END XX_OM_ORDER_ACK_OUT_PKG;
/

SHOW ERRORS;

--EXIT;