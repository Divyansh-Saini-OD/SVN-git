SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_AP_INV_TRADE_DASHBOARD_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE
--

create or replace 
PACKAGE xx_ap_inv_trade_dashboard_pkg
AS
  -- +============================================================================================+
  --   Office Depot - Project Simplify
  --
  -- +============================================================================================+
  --   Name        : xx_ap_inv_trade_dashboard_pkg
  --   RICE ID     : 3522 AP Dashboard Report Package
  --   Solution ID : 213 Invoice Lines section
  --   Description : Dash board Query are build using pipeline Function for performance
  --   Change Record
  -- +============================================================================================+
  --  Version     Date         Author           Remarks
  --  =========   ===========  =============    ==================================================
  --  1.0         15-Nov-17    Priyam Parmar       Initial version
  --
  -- +============================================================================================+
  -------Function to calculate Vendor assistant-----------------------
  FUNCTION vendor_assistant(
      p_assistant_code VARCHAR2)
    RETURN VARCHAR2;
  -----GET_INV_STATUS--
  FUNCTION get_inv_status(
      p_invoice_id NUMBER)
    RETURN VARCHAR2;
  ---Hold Lookup code--
  FUNCTION xx_ap_hold_placed(
      p_invoice_id       NUMBER,
      p_line_location_id NUMBER,
      p_type             NUMBER)
    RETURN VARCHAR2;
  --------------------------header and line details -------------------------
type ap_inv_trade_header_db
IS
  record
  (
    vendorasistant VARCHAR2(250),
    ---  OU_NAME             VARCHAR2(100),
    sup_num        VARCHAR2(100),
    sup_name       VARCHAR2(200),
    sup_site       VARCHAR2(100),
    invoice_num    VARCHAR2(50),
    invoice_id     NUMBER,
    invoice_date   DATE,
    invoice_amount NUMBER,
    freight_amount NUMBER,
    tax_amount     NUMBER,
    po_num         VARCHAR2(25),
    payment_term   VARCHAR2(25),
    terms_date     DATE,
    due_date       DATE,
    gl_date        DATE,
    inv_cur_code   VARCHAR2(5),
    payment_method VARCHAR2(25),
    pay_group      VARCHAR2(25),
    inv_source     VARCHAR2(25),
    po_type        VARCHAR2(50),
    ---PO_TYPE_CODE        VARCHAR2(50),
    invoice_status      VARCHAR2(50),
    payment_numb        VARCHAR2(50) ,
    payment_date        DATE,
    amount_paid         NUMBER,
    payment_status      VARCHAR2(50),
    payment_status_code VARCHAR2(5),
    chargeback_flag     VARCHAR2(5),
    invoice_type        VARCHAR2(25)
    --- INVOICE_STATUS_CODE VARCHAR2(5),
    ---  INVOICE_ID          NUMBER
  );
type ap_inv_trade_header_db_ctt
IS
  TABLE OF xx_ap_inv_trade_dashboard_pkg.ap_inv_trade_header_db;
  -----------------------PIPE Function For header and Line ----------------------
  FUNCTION xx_ap_inv_pay_inq(
      p_date_from      DATE ,
      p_date_to        DATE ,
      p_gl_date_from   DATE,
      p_gl_date_to     DATE,
      p_po_date_from   DATE,
      p_po_date_to     DATE,
      p_vendor_id      NUMBER,
      p_vendor_site_id NUMBER,
      p_assist_code    VARCHAR2,--CHECK THIS
      p_po_header_id   NUMBER,
      p_invoice_num    VARCHAR2,
      p_org_id         NUMBER,
      p_invoice_source VARCHAR2,
      p_invoice_type   VARCHAR2,
      p_invoice_status VARCHAR2,
      p_pay_status     VARCHAR2,
      p_payment_num    NUMBER,--CHECK THIS
      p_dropship       VARCHAR2,
      p_frontdoor      VARCHAR2,
      p_noncode        VARCHAR2,
      p_consignment    VARCHAR2,
      p_trade          VARCHAR2,
      p_newstore       VARCHAR2,
      p_replenishment  VARCHAR2,
      p_directimport   VARCHAR2,
      p_freight        VARCHAR2,
      p_tax            VARCHAR2,
      p_chargeback     VARCHAR2,
      p_excep_pricing  VARCHAR2,
      p_excep_qty      VARCHAR2,
      p_excep_freight  VARCHAR2,
      p_excep_oth      VARCHAR2 )
    RETURN xx_ap_inv_trade_dashboard_pkg.ap_inv_trade_header_db_ctt pipelined;
  --------------------------LINE
type ap_inv_trade_line_db
IS
  record
  (
    line_number            NUMBER,
    line_type              VARCHAR2(100),
    po_number              VARCHAR2(100),
    po_line_num            NUMBER,
    invoice_line_amount    NUMBER,
    description            VARCHAR2(240),
    sku                    VARCHAR2(100),
    sku_description        VARCHAR2(240),
    uom                    VARCHAR2(25),
    po_quantity            NUMBER,
    received_quantity      VARCHAR2(150),
    invoiced_quantity      NUMBER,
    po_price               NUMBER,
    invoice_price          NUMBER,
    holds_placed           VARCHAR2(2000),
    hold_date              DATE,
    hold_released_by       VARCHAR2(300),
    hold_release_date      DATE,
    hold_release_reason    VARCHAR2(3000),
    charge_acc_reason_code VARCHAR2(3000),
    charge_account         VARCHAR2(200),
    charge_back_line       VARCHAR2(100),
    answer_code            VARCHAR2(100),
    orig_inv_line_num      VARCHAR2(150),
    invoice_id             NUMBER
    
  );
type ap_inv_trade_line_db_ctt
IS
  TABLE OF xx_ap_inv_trade_dashboard_pkg.ap_inv_trade_line_db;
  -----------------------PIPE Function For header and Line ----------------------
  FUNCTION xx_ap_inv_pay_line_inq(
      p_invoice_id NUMBER,
      p_chrg_flag  VARCHAR2)
    RETURN xx_ap_inv_trade_dashboard_pkg.ap_inv_trade_line_db_ctt pipelined;
  FUNCTION f_freight_amount(
      p_invoice_id NUMBER)
    RETURN NUMBER;
  ----------------------Function to calculate TAX Amount ---------------------
  FUNCTION f_tax_amount(
      p_invoice_id NUMBER)
    RETURN NUMBER;
END xx_ap_inv_trade_dashboard_pkg;

/
show error
