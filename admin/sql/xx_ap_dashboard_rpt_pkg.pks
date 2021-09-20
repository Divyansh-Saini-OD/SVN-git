SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE xx_ap_dashboard_rpt_pkg
AS
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  xx_ap_dashboard_rpt_pkg                                                          |
  -- |  RICE ID   :  E3522 AP Dashboard Report Package                                            |
  -- |  Description:  Dash board Query are build using pipeline Function for performance          |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         11/10/2017   Digamber S       Initial version                                  |
  -- | 1.1         11/10/2017   Digamber S       RTV Reconcilation                                |
  -- | 1.1         18/01/2018   Digamber S       Incorporetd hint for performance                 |
  -- +============================================================================================+
TYPE chargeback_db
IS
  Record
  (
    vendor_id            NUMBER,
    vendor_site_id       NUMBER,
    VendorAssistant_code VARCHAR2(100),
    VendorAssistant_Name VARCHAR2(2500),
    SupplierNum          VARCHAR2(100),
    SupplierName         VARCHAR2(250),
    VendorSite_code      VARCHAR2(100),
    Invoice_id           NUMBER,
    invoice_num          VARCHAR2(100),
    Invoice_date         DATE,
    Pricing_amt          NUMBER,
    Pricing_Ln_cnt       NUMBER,
    Pricing_voucr_cnt    NUMBER,
    Shortage_amt         NUMBER,
    Shortage_Ln_cnt      NUMBER,
    Shortage_vouchr_cnt  NUMBER,
    Other_amt            NUMBER,
    Other_Ln_cnt         NUMBER,
    Other_voucher_cnt    NUMBER ,
    Org_id               NUMBER,
    Line_type            VARCHAR2(150),
    DESCRIPTION          VARCHAR2(250),
    Typecode             VARCHAR2(150),
    po_num               VARCHAR2(50),
    sku                  VARCHAR2(250),
    reason_code          varchar2(150),
    line_amount          number,
    total_amt            NUMBER);
TYPE chargeback_db_ctt
IS
  TABLE OF XX_AP_DASHBOARD_RPT_PKG.CHARGEBACK_DB;
  -- Ap Trade Reconciliation dashboard Report
TYPE ap_trade_rtv_recon
IS
  Record
  (
    APPLICATION VARCHAR2(50),
    Country     VARCHAR2(50),
    /*INVOICE_NUM        VARCHAR2(100),
    INVOICE_DATE       DATE,
    RTV_NUMBER         VARCHAR2(50),
    SKU                VARCHAR2(250),
    RETURN_CODE        VARCHAR2(50),
    RETURN_DESCRIPTION VARCHAR2(250),
    FREQUENCY_CODE     VARCHAR2(50),*/
    DY_73_AMT NUMBER,
    WY_73_AMT NUMBER,
    MY_73_AMT NUMBER,
    Qy_73_Amt NUMBER
    /*DY_OTH_AMT         NUMBER,
    WY_OTH_AMT         NUMBER,
    MY_OTH_AMT         NUMBER,
    QY_OTH_AMT         NUMBER*/
  ) ;
TYPE ap_trade_rtv_recon_ctt
IS
  TABLE OF xx_ap_dashboard_rpt_pkg.ap_trade_rtv_recon;
  -- Trade Match Analysis
TYPE ap_trade_match_analysis
IS
  Record
  (
    OU_NAME              VARCHAR2(50),
    Invoice_id           NUMBER,
    Invoice_num          VARCHAR2(50),
    invoice_date         DATE,
    vendor_id            NUMBER,
    vendor_site_id       NUMBER,
    assistant_code       VARCHAR2(50),
    VendorAsistant       VARCHAR2(250),
    Sup_num              VARCHAR2(50),
    supplier             VARCHAR2(250),
    vendor_site_code     VARCHAR2(150),
    inv_source           VARCHAR2(150),
    po_type              VARCHAR2(150),
    Oracle_User_Name     VARCHAR2(50),
    Man_inv              NUMBER,
    TDM_inv              NUMBER,
    EDI_inv              NUMBER,
    OTH_inv              NUMBER,
    MANUALY_MATCHED      NUMBER,
    TOTAL_INV_COUNT      NUMBER,
    system_matched       NUMBER,
    system_matched_per   NUMBER,
    manually_matched_per NUMBER ) ;
TYPE ap_trade_match_analysis_ctt
IS
  TABLE OF xx_ap_dashboard_rpt_pkg.ap_trade_match_analysis;
  FUNCTION VENDOR_ASSISTANT(
      p_assistant_code VARCHAR2)
    RETURN VARCHAR2;
  ------------------------------------------------------------
  -- AP Trade – Charge Back Summary
  -- Solution ID: 214.0
  -- RICE_ID : E3522
  ------------------------------------------------------------
FUNCTION xx_ap_trade_chbk_summary(
    P_DATE_FROM      DATE ,
    P_DATE_TO        DATE,
    P_ORG_ID         NUMBER,
    P_VENDOR_ID      NUMBER,
    P_VENDOR_SITE_ID NUMBER,
    P_ASSIST_CODE    VARCHAR2,
    P_ITEM_ID        NUMBER,
    P_REPORT_OPTION  VARCHAR2,    
    p_disp_option   VARCHAR2,  -- 'S' 'D'
    P_PRC_EXCEP  VARCHAR2,
    P_QTY_EXCEP  VARCHAR2,
    P_OTH_EXCEP  VARCHAR2
    )
   RETURN xx_ap_dashboard_rpt_pkg.chargeback_db_ctt pipelined;
  ------------------------------------------------------------
  -- Ap Trade AP Trade – RTV Reconcilation
  -- Solution ID: 217.0
  -- RICE_ID : E3522
  ------------------------------------------------------------
  FUNCTION xx_ap_trade_rtv_reconcilation(
      p_date_from   DATE ,
      p_date_to     DATE ,
      p_period_from VARCHAR2,
      P_Period_to   VARCHAR2)
    RETURN xx_ap_dashboard_rpt_pkg.ap_trade_rtv_recon_ctt pipelined;
  ------------------------------------------------------------
  -- AP Trade – Match Analysis
  -- Solution ID: 215.0
  -- RICE_ID : E3522
  ------------------------------------------------------------
  
  -- AP Trade – Match Analysis
  FUNCTION xx_ap_trade_match_analysis(
      p_date_from      DATE ,
      p_date_to        DATE ,
      P_Period_From    VARCHAR2,
      P_Period_To      VARCHAR2,
      P_Org_Id         NUMBER,
      P_Vendor_Id      NUMBER,
      P_vendor_site_id NUMBER,
      P_Assist         VARCHAR2,
      P_Drop_Ship_Flag VARCHAR2,
      P_report_option  VARCHAR2 )
    RETURN xx_ap_dashboard_rpt_pkg.ap_trade_match_analysis_ctt pipelined;
  FUNCTION get_hold_release_date(
      p_invoice_id NUMBER)
    RETURN DATE ;
  FUNCTION get_hold_release_by(
      p_invoice_id NUMBER)
    RETURN VARCHAR2 ;
  FUNCTION get_user_name(
      p_user_id NUMBER)
    RETURN VARCHAR2 ;
  FUNCTION get_po_category(
      p_po_header_id NUMBER)
    RETURN VARCHAR2 ;
END;
/

SHOW ERRORS;