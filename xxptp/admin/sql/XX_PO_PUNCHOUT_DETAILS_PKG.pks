SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_PO_PUNCHOUT_CONF_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_PO_PUNCHOUT_DETAILS_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_PO_PUNCHOUT_CONF_PKG                                                            |
  -- |                                                                                            |
  -- |  Description:  This package is used by WEB services to load Punchout confirmation          |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-JUN-2017  Arun Gannarapu    Initial version                                 |
  -- +============================================================================================+

  /* $Header: XX_PO_PUNCHOUT_DETAILS_PKG.pls $ */
  /*# 
  * This custom PL/SQL package can be used to stage data from punchout order ship details to Oracle using Web Services.  
  * @rep:scope public
  * @rep:product PO
  * @rep:displayname ODPOPUNCHOUTDET 
  * @rep:category BUSINESS_ENTITY po_punchout_details_interface
  */
  PROCEDURE LOAD_SHIP_DETAILS(
        AOPS_ORDER_NUMBER  IN VARCHAR2,
        PO_NUMBER          IN VARCHAR2,
        QTY                IN NUMBER,
        PO_LINE_NUM        IN NUMBER,
        UNIT_COST          IN VARCHAR2,
        ITEM               IN VARCHAR2,
        OUT               OUT VARCHAR2)
  /*# 
  * Use this procedure to insert data into Custom PO staging table. 
  * @param AOPS_ORDER_NUMBER  AOPS Order Number
  * @param PO_NUMBER  Purchase Order Number 
  * @param QTY Shipped quantity
  * @param PO_LINE_NUM PO Line Number 
  * @param UNIT_COST  Unit cost of the item
  * @param ITEM Sku 
  * @param OUT Contains Payloadvalue
  * @rep:displayname LOAD_SHIP_DETAILS 
  * @rep:category BUSINESS_ENTITY po_punchout_Details_interface
  * @rep:scope public 
  * @rep:lifecycle active 
  */;

  PROCEDURE process_pending_receipts(errbuf        OUT  VARCHAR2,
                                     retcode       OUT  VARCHAR2,
                                     pi_status     IN   xx_po_shipment_details.record_status%TYPE,
                                     pi_po_number  IN   po_headers_all.segment1%TYPE);  

END XX_PO_PUNCHOUT_DETAILS_PKG;
/