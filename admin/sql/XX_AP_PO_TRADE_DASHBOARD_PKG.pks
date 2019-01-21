SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace 
PACKAGE xx_ap_po_trade_dashboard_pkg
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  xx_ap_po_trade_dashboard_pkg                                                          |
  -- |  RICE ID   :  E3522 AP Dashboard Report Package
  -- | Solution ID: 211.0 PO Inquiry
  -- |  Description:  Dash board Query are build using pipeline Function for performance          |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         11/16/2017   Jitendra Atale   Initial version                                  |
  -- +============================================================================================+
TYPE ap_po_trade_db
IS
  Record
  (
     PO_header_id  Number,
     PO_Number  VARCHAR2(20),
     PO_Date DATE,
     Supplier_Name VARCHAR2(150),
     Supplier_Number VARCHAR2(150),
     Supplier_Site VARCHAR2(15),
     PO_Amount NUMBER,
     Order_Qty NUMBER,
     Receipt_Qty  NUMBER,
     Balance_Qty  NUMBER,
     Last_Receipt Date,
     PO_Type VARCHAR2(30),
     Payment_term VARCHAR2(50),
     status VARCHAR2(25),
     Org_ID NUMBER
                                  );
TYPE ap_po_trade_db_ctt
IS
  TABLE OF xx_ap_po_trade_dashboard_pkg.ap_po_trade_db;

TYPE ap_po_trade_details_db
IS
  Record
  (
     PO_header_id  Number,
     PO_line_id  Number,
     PO_Number VARCHAR2(20),
     Line_Number NUMBER,
     SKU VARCHAR2(25),
     SKU_DESCRIPTION VARCHAR2(250),
     Dept VARCHAR2(1000),
     UOM VARCHAR2(250),
     QUANTITY NUMBER,
     UNIT_PRICE NUMBER,
     Line_Amount  NUMBER,
     VPC VARCHAR2(1000),
     Location VARCHAR2(50),
     Match_Level VARCHAR2(50),
     Received_Qty NUMBER,
     Invoiced_Qty NUMBER,
     Receipt_number VARCHAR2(50),
     Invoice_number  VARCHAR2(50),
     Unmatched_Qty NUMBER,
     Accrual_Amount NUMBER,
     WrittenOff_Amount VARCHAR2(100),
     Accrual_Account NUMBER,
     Variance_Account NUMBER
     );
TYPE ap_po_trade_details_db_ctt
IS
  TABLE OF xx_ap_po_trade_dashboard_pkg.ap_po_trade_details_db;

TYPE ap_po_trade_rec_db
IS
  Record
  (
     PO_header_id  Number,
     PO_line_id  Number,
     Receipt_number VARCHAR2(50),
     Receipt_Date date,
     Qty Number
                                  );
TYPE ap_po_trade_rec_db_ctt
IS
  TABLE OF xx_ap_po_trade_dashboard_pkg.ap_po_trade_rec_db;

TYPE ap_po_trade_inv_db
IS
  Record
  (
     PO_header_id  Number,
     PO_line_id  Number,
     Invoice_number VARCHAR2(50),
     Invoice_Qty Number,
     Invoice_Price Number,
     Status Varchar2(50) );
TYPE ap_po_trade_inv_db_ctt
IS
  TABLE OF xx_ap_po_trade_dashboard_pkg.ap_po_trade_inv_db;

TYPE ap_po_trade_writeoff_db
IS
  Record
  (
     PO_header_id  Number,
     PO_line_id  Number,
     Reason_code VARCHAR2(50),
     Writeoff_Date date,
     Amount Number
                                  );
TYPE ap_po_trade_writeoff_db_ctt
IS
  TABLE OF xx_ap_po_trade_dashboard_pkg.ap_po_trade_writeoff_db;
  FUNCTION XX_AP_TRADE_GET_PO_DETAILS(
      p_po_header_id IN NUMBER,
      p_po_line_id   IN NUMBER DEFAULT NULL,
      p_type         IN VARCHAR2)
    RETURN VARCHAR2;
    FUNCTION ap_trade_po_Inquiry_headers(
        p_date_from         DATE,
        p_date_to           DATE,
        p_po_header_id      NUMBER,
        p_vendor_id         NUMBER,
        p_vendor_site_id    NUMBER,
        p_Inventory_item_id NUMBER,
        p_location_id       NUMBER,
        p_status            VARCHAR2,
        p_org_id            NUMBER,
        p_Dropship          VARCHAR2,
        p_FrontDoor         VARCHAR2,
        p_Noncode           VARCHAR2,
        p_Consignment       VARCHAR2,
        p_trade             VARCHAR2,
        p_NewStore          VARCHAR2,
        p_Replenishment     VARCHAR2,
        p_directimport      VARCHAR2 )
      RETURN xx_ap_po_trade_dashboard_pkg.ap_po_trade_db_ctt pipelined;

  -- Ap Trade PO Inquiry dashboard Report
      FUNCTION ap_trade_po_Inquiry_details(
           p_po_header_id NUMBER,
           p_PO_Num VARCHAR2)
        RETURN xx_ap_po_trade_dashboard_pkg.ap_po_trade_details_db_ctt pipelined;
    
       FUNCTION xx_ap_get_disp_receipts(
            p_po_line_id NUMBER  )
        RETURN xx_ap_po_trade_dashboard_pkg.ap_po_trade_rec_db_ctt pipelined;
    
      FUNCTION xx_ap_get_disp_invoice(
           p_po_header_id NUMBER, p_po_line_id NUMBER  )
        RETURN xx_ap_po_trade_dashboard_pkg.ap_po_trade_inv_db_ctt pipelined;
    
      FUNCTION xx_ap_get_disp_writeoff(
           p_po_header_id NUMBER, p_po_line_id NUMBER  )
        RETURN xx_ap_po_trade_dashboard_pkg.ap_po_trade_writeoff_db_ctt pipelined;
    
      FUNCTION get_inv_status(p_invoice_id in number)
      RETURN VARCHAR2;
  ------------------------------------------------------------
  -- AP Trade PO Inquiry
  -- Solution ID: 211.0
  -- RICE_ID : E3522
  ------------------------------------------------------------
END xx_ap_po_trade_dashboard_pkg;
/
SHOW ERROR;