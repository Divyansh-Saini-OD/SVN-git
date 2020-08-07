SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE XX_AP_BYPASSINV_PKG
AS
-- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_AP_BYPASSINV_PKG                                                             |
  -- |  RICE ID   :  R7039                                                                        |
  -- |  Description:  PAckage will be used to execute before_report which will set email information
  --                  ,certain functions to get depot.sku,mfg_Code UOM information and           |
  --                    after_report will submit XML bursting for Bypass Invoice Report           |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         11/10/2017   Ragni Gupta       Initial version                                  |
  -- +============================================================================================+
FUNCTION beforeReport RETURN BOOLEAN;
FUNCTION GET_MFG_CODE(p_po_num VARCHAR2, p_line_num NUMBER) RETURN VARCHAR2;
FUNCTION GET_SKU(p_po_num VARCHAR2, p_line_num NUMBER, p_item_id NUMBER) RETURN VARCHAR2;
FUNCTION GET_DEPT(p_item_id NUMBER, p_org_id NUMBER, p_po_num VARCHAR2, p_line_num NUMBER) RETURN NUMBER;
FUNCTION GET_UOM(p_po_num VARCHAR2, p_line_num NUMBER) RETURN VARCHAR2;
FUNCTION afterReport RETURN BOOLEAN;
P_CONC_REQUEST_ID   number;
P_START_DATE VARCHAR2(30);
P_END_DATE  VARCHAR2(30);
G_DISTRIBUTION_LIST VARCHAR2(500);
G_EMAIL_SUBJECT     VARCHAR2(100);
G_EMAIL_CONTENT     VARCHAR2(240);
G_SMTP_SERVER   VARCHAR2(250);
G_REC_COUNT NUMBER;
END;
/

SHOW ERRORS;