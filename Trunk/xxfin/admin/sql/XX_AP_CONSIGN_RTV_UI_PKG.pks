SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE XX_AP_CONSIGN_RTV_UI_PKG
AS
-- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_AP_CONSIGN_RTV_UI_PKG                                                         |
  -- |  RICE ID   :  E3523
  -- |  Solution ID: 212                                                              			  |
  -- |  Description:  PAckage will be used to fetch consignment RTV data for dashboard
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         11/1/2017   Ragni Gupta       Initial version                                  |
  -- +============================================================================================+
G_START_DATE  DATE;
G_END_DATE  DATE;
TYPE CONSIGN_RTV_DB
IS
  RECORD
  ( SUPPLIER_SITE VARCHAR2(50),
    SUPPLIER_NAME VARCHAR2(250),
    ORIGINAL_RTV VARCHAR2(250),    
    TRANSACTION_DATE DATE,
    LOCATION VARCHAR2(10),
    SKU VARCHAR2(100),
    FREIGHT_CARRIER VARCHAR2(250),
    FREIGHT_BILL VARCHAR2(250),
    RGA VARCHAR2(250),
    VENDOR_PRODUCT VARCHAR2(250),
    DESCRIPTION VARCHAR2(1000),
    TRANSACTION_QUANTITY NUMBER,
    TRANSACTION_COST NUMBER,
    EXTENDED_COST NUMBER
  );
TYPE CONSIGN_RTV_DB_CTT
IS
  TABLE OF XX_AP_CONSIGN_RTV_UI_PKG.CONSIGN_RTV_DB;
  FUNCTION CONSIGN_PIPE (  P_VENDOR_ID      NUMBER,
  P_VEND_SITE_ID NUMBER ,
  P_ITEM_ID NUMBER,
  P_RTV VARCHAR2,
  P_RGA VARCHAR2,
  P_LOCATION_ID NUMBER,
  P_DATE_FROM DATE ,
  P_DATE_TO DATE,
  P_ORG_ID NUMBER,
  P_GL_PERIOD_FROM VARCHAR2,
  P_GL_PERIOD_TO VARCHAR2)
    RETURN XX_AP_CONSIGN_RTV_UI_PKG.CONSIGN_RTV_DB_CTT PIPELINED;

END;
/

SHOW ERRORS;