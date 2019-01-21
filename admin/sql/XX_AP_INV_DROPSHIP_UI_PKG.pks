SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE XX_AP_INV_DROPSHIP_UI_PKG
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
TYPE AP_INV_DROPSHIP_DET_DB
IS
  RECORD
  (
    ORG_ID             NUMBER,        
    SUPPLIER_NAME      VARCHAR2(250),
    SUPPLIER_NUM       VARCHAR2(50),
    SUPPLIER_SITE      VARCHAR2(250),
    INVOICE_DATE        DATE,
    INVOICE_NUM        VARCHAR2(50),
    SKU VARCHAR2(250),
    QTY NUMBER,
    COST NUMBER,    
    CHECK_DESCRIPTION   VARCHAR2(250),
    RTN_ORDER VARCHAR2(250),
    RTN_SUB        VARCHAR2(250),
    ORIG_ORDER       VARCHAR2(250),
    ORIG_SUB       VARCHAR2(250),
    OU_NAME   VARCHAR2(250)
    );
TYPE AP_INV_DROPSHIP_DB_CTT
IS
  TABLE OF XX_AP_INV_DROPSHIP_UI_PKG.AP_INV_DROPSHIP_DET_DB;
  
  TYPE AP_INV_DROPSHIP_SUM_DB
IS
  RECORD
  (
    ORG_ID             NUMBER,        
    SUPPLIER_NAME      VARCHAR2(250),
    SUPPLIER_NUM       VARCHAR2(50),
    SUPPLIER_SITE      VARCHAR2(250),
    INVOICE_DATE        DATE,
    INVOICE_NUM        VARCHAR2(50),    
    TOTAL     NUMBER,
    REASON_CODE        VARCHAR2(25),
    CHECK_DESCRIPTION   VARCHAR2(250),
    CREATION_dATE       DATE,
    OU_NAME   VARCHAR2(250));
TYPE AP_INV_DROPSHIP_SUM_DB_CTT
IS
  TABLE OF XX_AP_INV_DROPSHIP_UI_PKG.AP_INV_DROPSHIP_SUM_DB;
  FUNCTION GET_DROPSHIP_DEDUCTION_SUMMARY(      
      P_INV_START_DATE  DATE,
      P_INV_END_DATE    DATE,      
      P_GL_START_DATE  DATE,
      P_GL_END_DATE    DATE,
      P_ORG_ID NUMBER,
      P_VENDOR_ID NUMBER,
      P_VENDOR_SITE_ID NUMBER,      
      P_INVOICE_ID NUMBER,
      P_REASON_CODE VARCHAR2)
    RETURN XX_AP_INV_DROPSHIP_UI_PKG.AP_INV_DROPSHIP_SUM_DB_CTT PIPELINED;
    
    FUNCTION GET_DROPSHIP_DEDUCTION_DETAIL(      
      P_INV_START_DATE  DATE,
      P_INV_END_DATE    DATE,      
      P_GL_START_DATE  DATE,
      P_GL_END_DATE    DATE,      
      P_ORG_ID NUMBER,
      P_VENDOR_ID NUMBER,
      P_VENDOR_SITE_ID NUMBER,      
      P_INVOICE_ID NUMBER,
      P_REASON_CODE VARCHAR2)
    RETURN XX_AP_INV_DROPSHIP_UI_PKG.AP_INV_DROPSHIP_DB_CTT PIPELINED;
    
    TYPE AP_DROPSHIP_NONDED_DB
IS
  RECORD
  (
    SUPPLIER_NAME      VARCHAR2(250),    
    SUPPLIER_NUM       VARCHAR2(50),    
    SUPPLIER_SITE      VARCHAR2(250),
    SALES_DATE        DATE,
    RTN_ORDER VARCHAR2(250),
    RTN_SUB        VARCHAR2(250),
    ORIG_ORDER       VARCHAR2(250),
    ORIG_SUB       VARCHAR2(250),
    LOCATION        VARCHAR2(50),
    PO_NUM           VARCHAR2(50),
    SKU VARCHAR2(250),
    QTY NUMBER,
    COST NUMBER,    
    RTN_REASON_CODE   VARCHAR2(250),
    RTN_AUTH_CODE   VARCHAR2(250),    
    IMPORT_DATE   DATE
    );
TYPE AP_DROPSHIP_NONDED_DB_CTT
IS
  TABLE OF XX_AP_INV_DROPSHIP_UI_PKG.AP_DROPSHIP_NONDED_DB;

FUNCTION GET_DROPSHIP_NON_DEDUCTION(      
      P_START_DATE  DATE,
      P_END_DATE    DATE,                  
      P_ORG_ID NUMBER,
      P_VENDOR_ID NUMBER,
      P_VENDOR_SITE_ID NUMBER,      
      P_PO_NUM VARCHAR2,
      P_REASON_CODE VARCHAR2)
    RETURN XX_AP_INV_DROPSHIP_UI_PKG.AP_DROPSHIP_NONDED_DB_CTT PIPELINED;
    
END;
/

SHOW ERRORS;