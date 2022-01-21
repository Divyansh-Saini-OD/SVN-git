SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE XX_AP_TRADE_RCT_INQ_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name        : xx_ap_trade_rct_inq_pkg                                                     |
  -- |  RICE ID     : E3523
  -- |  Solution ID : 218 AP Trade – Receipt Detail Inquiry                                       |
  -- |  Description : Dash board Query are build using pipeline Function for performance          |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-Nov-17   Priyam Parmar    Initial version
  -- | 1.1         11-JAN-2018 PRIYAM           Changes done for user id and performance
  -- +============================================================================================+

-----Global definition of parameters
      G_DATE_FROM   date ;
      G_DATE_TO     date ;
      G_INVOICE_ID NUMBER;
      G_RECEIPT_ID NUMBER;
      G_PO_HEADER_ID NUMBER;
      G_INVENTORY_ITEM_ID NUMBER;
      G_SUPPLIER_SITE_ID number;
      G_VENDOR_ID NUMBER;
      G_USER_ID     number;
    --  G_RESULT VARCHAR2(5);
    ---  G_ERROR  VARCHAR2(1000);


TYPE AP_TRADE_RCT_DET
IS
  RECORD
  (
    RECEIPT_NUM      VARCHAR2(25),
    RCP_DATE         DATE,
    SUPPLIER_NUM     VARCHAR2(50),
    SUPPLIER_NAME    VARCHAR2(100),
    SUPPLIER_SITE    VARCHAR2(100),
    PO               VARCHAR2(20),
    PO_LINE_NUM      NUMBER,
    SKU              VARCHAR2(100),
    LOCATION         VARCHAR2(100),
    UOM              VARCHAR2(100),
    REC_LINE_NUM     NUMBER,
    RECEIPT_LINE_AMT NUMBER,
    PO_QTY           NUMBER,
    RCP_QTY          NUMBER,
    INV_QTTY         NUMBER,
    INVOICE_NUM      VARCHAR2(100),
    INV_NUM_FIFO     VARCHAR2(100),
    UNINV_QTTY       NUMBER,
    UNINV_AMT        NUMBER,
    RCT_AGE          NUMBER,
    UNIT_PRICE       NUMBER,
    TOTAL_REC_LINE_AMT NUMBER,
    TOTAL_UNINV_AMT NUMBER,
    ------ADDED 17 JAN 2018
    ITEM_ID NUMBER ,VENDOR_SITE_ID NUMBER,po_line_id number,INV_VAL varchar2(10)
    );
TYPE AP_TRADE_RCT_DET_CTT
IS
  TABLE OF XX_AP_TRADE_RCT_INQ_PKG.AP_TRADE_RCT_DET;


function get_inv_status(p_invoice_id in number)
RETURN VARCHAR2;
  ------------------------------------------------------------
  -- AP Trade Receipt Detail Inquiry
  -- Solution ID: 218.0
  -- RICE_ID :E3523
  ---description: Main PIPE function
  ------------------------------------------------------------
  FUNCTION XX_AP_TRADE_RCT_INQUIRY(
      P_DATE_FROM   DATE ,
      P_DATE_TO     DATE ,
      P_INVOICE_ID number,
      P_RECEIPT_ID number,
      P_PO_HEADER_ID number,
      P_INVENTORY_ITEM_ID number,
      P_SUPPLIER_SITE_ID number,
      P_VENDOR_ID NUMBER,
      P_USER_ID     NUMBER)
    RETURN XX_AP_TRADE_RCT_INQ_PKG.AP_TRADE_RCT_DET_CTT PIPELINED;
  ------------------------------------------------------------
  -- AP Trade Receipt Detail Inquiry
  -- Solution ID: 218.0
  -- RICE_ID :E3523
  ---description: Function to get Invoice Qty applied to Receipt
  ------------------------------------------------------------

   procedure XXAPRECEITPDETINQ_WRAPPER (   P_DATE_FROM   DATE ,
      P_DATE_TO     DATE ,
      P_INVOICE_ID number,
      P_RECEIPT_ID number,
      P_PO_HEADER_ID number,
      P_INVENTORY_ITEM_ID number,
      P_SUPPLIER_SITE_ID number,
      P_VENDOR_ID number,
      P_USER_ID     NUMBER,
      P_request_id  OUT number);



  FUNCTION F_INV_QTTY(
      P_PO_NUM      VARCHAR2,
      P_PO_LINE_ID  NUMBER,
      P_RECEIPT_NUM VARCHAR2,
      p_user_id number )
    RETURN NUMBER;
  ------------------------------------------------------------
  -- AP Trade Receipt Detail Inquiry
  -- Solution ID: 218.0
  -- RICE_ID :E3523
  -- description: Function to get FIFO invoice number
  ------------------------------------------------------------
  FUNCTION F_INV_NUMBER(
      P_PO_NUM      VARCHAR2,
      P_PO_LINE_ID  NUMBER,
      P_RECEIPT_NUM VARCHAR2,
      p_user_id number)
    RETURN VARCHAR2;
    
    
    
      FUNCTION F_INV_QTTY_REQUEST(
      P_PO_NUM      VARCHAR2,
      P_PO_LINE_ID  NUMBER,
      p_receipt_num varchar2,
      p_user_id number ,P_REQUEST_ID NUMBER)
    RETURN NUMBER;
    
     FUNCTION F_INV_NUMBER_REQUEST(
      P_PO_NUM      VARCHAR2,
      P_PO_LINE_ID  NUMBER,
      p_receipt_num varchar2,
      p_user_id number,P_REQUEST_ID NUMBER)
    RETURN VARCHAR2;


  ------------------------------------------------------------
  -- AP Trade Receipt Detail Inquiry
  -- Solution ID: 218.0
  -- RICE_ID :E3523
  -- description: Procedure to Populate Temp table
  ------------------------------------------------------------
   FUNCTION BEFOREREPORT
    return boolean;
    
     function afterreport
    RETURN BOOLEAN;

FUNCTION XX_AP_TRADE_RCT_INQUIRY_XML
  RETURN XX_AP_TRADE_RCT_INQ_PKG.AP_TRADE_RCT_DET_CTT PIPELINED;

  PROCEDURE GET_DATA_TEMP(
      P_DATE_FROM   DATE ,
      P_DATE_TO     DATE ,
      P_USER_ID     number,
      P_INVOICE_ID number,
      P_RECEIPT_ID number,
      P_PO_HEADER_ID number,
      P_INVENTORY_ITEM_ID number,
      P_SUPPLIER_SITE_ID NUMBER,
      P_VENDOR_ID NUMBER,
      P_RESULT OUT varchar2,
      P_ERROR OUT VARCHAR2
      );
  ------------------------------------------------------------
  -- AP Trade Receipt Detail Inquiry
  -- Solution ID: 218.0
  -- RICE_ID :E3523
  -- description: Function to get SKU DETAILS
  ------------------------------------------------------------
FUNCTION get_sku(
    P_PO_ITEM_ID NUMBER)
  RETURN VARCHAR2;


END XX_AP_TRADE_RCT_INQ_PKG;

/

SHOW ERRORS;