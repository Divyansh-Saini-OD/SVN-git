SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE XX_AP_INV_REASON_CODE_UI_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- | Name       :  xx_ap_inv_reason_code_ui_pkg                                                 |
  -- | RICE ID   :    E3522 AP Dashboard Report Package
  -- | Solution ID:   216 Invoice Details with Reason Code
  -- |  Description:  Dash board Query to get validated invoice details with reason code
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         11/17/2017   Ragni Gupta       Initial version                                  |
  -- +============================================================================================+
TYPE AP_INV_REASONCODE_DB
IS
  RECORD
  (
    ORG_ID             NUMBER,
    VENDOR_ASSISTANT   VARCHAR2(250),
    SUPPLIER_NUM       VARCHAR2(50),
    SUPPLIER_NAME      VARCHAR2(250),
    SUPPLIER_SITE      VARCHAR2(250),
    SUPP_SITE_CATEGORY VARCHAR2(25),
    INVOICE_NUM        VARCHAR2(50),
    INVOICE_AMOUNT     NUMBER,
    INVOICE_PERCENT    NUMBER,
    DEBIT_MEMO         VARCHAR2(240),
    PO_TYPE            VARCHAR(30),
    PO_NUM             VARCHAR2(30),
    --LINE_NUM           NUMBER,
    SKU                VARCHAR2(40),
    REASON_CODE        VARCHAR2(25),
    LINE_DESCRIPTION   VARCHAR2(250),
    CHBK_FLAG          VARCHAR2(10),
    REASON_CODE_AMT    NUMBER,
    DROPSHIP  VARCHAR2(250));
TYPE AP_INV_REASONCODE_DB_CTT
IS
  TABLE OF XX_AP_INV_REASON_CODE_UI_PKG.AP_INV_REASONCODE_DB;
  
  TYPE AP_INV_REASONCODE_SUM_DB
IS
  RECORD
  (
    ORG_ID             NUMBER,
    VENDOR_ASSISTANT   VARCHAR2(250),
    SUPPLIER_NUM       VARCHAR2(50),
    SUPPLIER_NAME      VARCHAR2(250),
    SUPPLIER_SITE      VARCHAR2(250),
    SUPP_SITE_CATEGORY VARCHAR2(25),
    INVOICE_NUM        VARCHAR2(50),
    INVOICE_AMOUNT     NUMBER,
    INVOICE_PERCENT    NUMBER,
    DEBIT_MEMO         VARCHAR2(240),    
    REASON_CODE        VARCHAR2(25),    
    CHBK_FLAG          VARCHAR2(10),
    REASON_CODE_AMT    NUMBER,
    DROPSHIP  VARCHAR2(250));
TYPE AP_INV_REASONCODE_SUM_DB_CTT
IS
  TABLE OF XX_AP_INV_REASON_CODE_UI_PKG.AP_INV_REASONCODE_SUM_DB;
  FUNCTION GET_AP_INV_REASONCODE_SUMMARY(      
      P_START_DATE  DATE,
      P_END_DATE    DATE,
      P_PERIOD_FROM VARCHAR2,
      P_PERIOD_TO   VARCHAR2,
      P_ORG_ID NUMBER,
      P_VENDOR_ID NUMBER,
      P_VENDOR_SITE_ID NUMBER,
      P_VEND_ASSIT_CODE VARCHAR2,
      P_ITEM_ID NUMBER,
      P_REASON_CODE VARCHAR2,
      P_DROPSHIP VARCHAR2)
    RETURN XX_AP_INV_REASON_CODE_UI_PKG.AP_INV_REASONCODE_SUM_DB_CTT PIPELINED;
    
    FUNCTION GET_AP_INV_REASONCODE_DETAIL(      
      P_START_DATE  DATE,
      P_END_DATE    DATE,
      P_PERIOD_FROM VARCHAR2,
      P_PERIOD_TO   VARCHAR2,
      P_ORG_ID NUMBER,
      P_VENDOR_ID NUMBER,
      P_VENDOR_SITE_ID NUMBER,
      P_VEND_ASSIT_CODE VARCHAR2,
      P_ITEM_ID NUMBER,
      P_REASON_CODE VARCHAR2,
      P_DROPSHIP VARCHAR2)
    RETURN XX_AP_INV_REASON_CODE_UI_PKG.AP_INV_REASONCODE_DB_CTT PIPELINED;
    
    FUNCTION VENDOR_ASSISTANT(
    P_ASSISTANT_CODE VARCHAR2)RETURN VARCHAR2;
    FUNCTION DEBIT_MEMO(P_INVOICE_NUM VARCHAR2, LINE_NUM NUMBER) RETURN VARCHAR2; 
 FUNCTION DEBIT_MEMO_AMT(
    P_PO_HEADER_ID NUMBER,
    P_PO_LINE_ID   NUMBER,
    P_LINE_AMT      NUMBER,
    P_REASON_CODE VARCHAR2,
    P_INV_AMT NUMBER)
  RETURN NUMBER;
    
    -------------------added to remove po tables from main pipe query-------------
    FUNCTION GET_PO_HEADER_DET ( P_PO_CRITERIA VARCHAR2 ,P_PO_HEADER_ID NUMBER) RETURN VARCHAR2;    
    FUNCTION GET_SKU(P_ITEM_ID NUMBER) RETURN NUMBER;
    

END;
/

SHOW ERRORS;