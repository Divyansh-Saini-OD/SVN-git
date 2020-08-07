SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE body xx_ap_inv_dropship_ui_pkg
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- | Name       :  xx_ap_inv_dropship_ui_pkg                                                 |
  -- | RICE ID   :    E3522 AP Dashboard Report Package
  -- | Solution ID:
  -- |  Description:  Dash board Query to get dropship deduction and non-deduction records
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         07/19/2018   Ragni Gupta       Initial version                                 |
  -- | 1.1         08/20/2018   Ragni Gupta       Fixed query for performance tuning              |
  -- +============================================================================================+
FUNCTION GET_DROPSHIP_DEDUCTION_SUMMARY(
    P_INV_START_DATE DATE,
    P_INV_END_DATE   DATE,
    P_GL_START_DATE  DATE,
    P_GL_END_DATE    DATE,
    P_ORG_ID         NUMBER,
    P_VENDOR_ID      NUMBER,
    P_VENDOR_SITE_ID NUMBER,
    P_INVOICE_ID     NUMBER,
    P_REASON_CODE    VARCHAR2)
  RETURN XX_AP_INV_DROPSHIP_UI_PKG.AP_INV_DROPSHIP_SUM_DB_CTT PIPELINED
IS
TYPE inv_cursor
IS
  REF
  CURSOR;
    c1 inv_cursor;
    l_ap_inv_dropship_db XX_AP_INV_DROPSHIP_UI_PKG.AP_INV_DROPSHIP_SUM_DB_CTT;
    l_error_count NUMBER;
    n             NUMBER := 0;
    l_start_date  DATE;
    l_end_date    DATE;
  BEGIN
    IF P_INV_START_DATE                                                                                                                                                                                                                                                                                                                                                                                                                                            IS NOT NULL THEN
      OPEN C1 FOR SELECT INV.ORG_ID, SUPP.VENDOR_NAME Supplier_Name, SUPP.SEGMENT1 Supplier_Num, SITE.VENDOR_SITE_CODE Supplier_Site, INV.INVOICE_DATE Invoice_Date, INV.INVOICE_NUM Invoice_Number, INV.INVOICE_AMOUNT Total, SUBSTR(INV.INVOICE_NUM,3,2) Reason_Code, INV.DESCRIPTION CHECK_DESCRIPTION, INV.CREATION_DATE Creation_Date, HOU.NAME OU_Name FROM AP_INVOICES_ALL INV, AP_SUPPLIERS SUPP, AP_SUPPLIER_SITES_ALL SITE, HR_OPERATING_UNITS HOU WHERE 1=1 AND INV.INVOICE_DATE BETWEEN to_date(TO_CHAR(P_INV_START_DATE)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(TO_CHAR(P_INV_END_DATE)||' 23:59:59','DD-MON-RR HH24:MI:SS') AND INV.SOURCE||'' = 'US_OD_DROPSHIP' AND INV.INVOICE_TYPE_LOOKUP_CODE = 'DEBIT' AND INV.INVOICE_NUM LIKE 'DS%' AND INV.CANCELLED_DATE IS NULL AND INV.ORG_ID +0 = P_ORG_ID AND INV.INVOICE_ID = NVL(P_INVOICE_ID, INV.INVOICE_ID) AND INV.VENDOR_ID = NVL(P_VENDOR_ID, INV.VENDOR_ID) AND INV.VENDOR_SITE_ID = NVL(P_VENDOR_SITE_ID, INV.VENDOR_SITE_ID) AND (P_REASON_CODE IS
        NULL OR SUBSTR(INV.INVOICE_NUM,3,2)                                                                                                                                                                                                                                                                                                                                                                                                                         = P_REASON_CODE) AND HOU.ORGANIZATION_ID = INV.ORG_ID AND SUPP.VENDOR_ID = INV.VENDOR_ID AND SITE.VENDOR_SITE_ID = INV.VENDOR_SITE_ID ;
    ELSE
      OPEN C1 FOR SELECT INV.ORG_ID, SUPP.VENDOR_NAME Supplier_Name, SUPP.SEGMENT1 Supplier_Num, SITE.VENDOR_SITE_CODE Supplier_Site, INV.INVOICE_DATE Invoice_Date, INV.INVOICE_NUM Invoice_Number, INV.INVOICE_AMOUNT Total, SUBSTR(INV.INVOICE_NUM,3,2) Reason_Code, INV.DESCRIPTION CHECK_DESCRIPTION, INV.CREATION_DATE Creation_Date, HOU.NAME OU_Name FROM AP_INVOICES_ALL INV, AP_SUPPLIERS SUPP, AP_SUPPLIER_SITES_ALL SITE, HR_OPERATING_UNITS HOU WHERE 1=1 AND (P_GL_START_DATE IS NULL OR (INV.GL_DATE BETWEEN to_date(TO_CHAR(P_GL_START_DATE)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(TO_CHAR(P_GL_END_DATE)||' 23:59:59','DD-MON-RR HH24:MI:SS'))) AND INV.SOURCE||'' = 'US_OD_DROPSHIP' AND INV.INVOICE_TYPE_LOOKUP_CODE = 'DEBIT' AND INV.INVOICE_NUM LIKE 'DS%' AND INV.CANCELLED_DATE IS NULL AND INV.ORG_ID+0 = P_ORG_ID AND INV.INVOICE_ID = NVL(P_INVOICE_ID, INV.INVOICE_ID) AND INV.VENDOR_ID = NVL(P_VENDOR_ID, INV.VENDOR_ID) AND INV.VENDOR_SITE_ID = NVL(P_VENDOR_SITE_ID, INV.VENDOR_SITE_ID)
      AND (P_REASON_CODE                                                                                                                                                                                                                                                                                                                                                                                                                                           IS NULL OR SUBSTR(INV.INVOICE_NUM,3,2) = P_REASON_CODE) AND HOU.ORGANIZATION_ID = INV.ORG_ID AND SUPP.VENDOR_ID = INV.VENDOR_ID AND SITE.VENDOR_SITE_ID = INV.VENDOR_SITE_ID;
    END IF;
    LOOP
      FETCH C1 BULK COLLECT
      INTO l_ap_inv_dropship_db limit 500;
    FOR i IN 1 .. l_ap_inv_dropship_db.count
    LOOP
      pipe row (l_ap_inv_dropship_db(i));
    END LOOP;
    EXIT
  WHEN C1%NOTFOUND;
  END LOOP;
  CLOSE C1;
  RETURN ;
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Error caught in Dropship Deduction Summary procedure '||SQLERRM);
END GET_DROPSHIP_DEDUCTION_SUMMARY;
--
FUNCTION GET_DROPSHIP_DEDUCTION_DETAIL(
    P_INV_START_DATE DATE,
    P_INV_END_DATE   DATE,
    P_GL_START_DATE  DATE,
    P_GL_END_DATE    DATE,
    P_ORG_ID         NUMBER,
    P_VENDOR_ID      NUMBER,
    P_VENDOR_SITE_ID NUMBER,
    P_INVOICE_ID     NUMBER,
    P_REASON_CODE    VARCHAR2)
  RETURN XX_AP_INV_DROPSHIP_UI_PKG.AP_INV_DROPSHIP_DB_CTT PIPELINED
IS
TYPE detail_cursor
IS
  REF
  CURSOR;
    c1 detail_cursor;
  TYPE ap_inv_dropship_db_ctt
IS
  TABLE OF xx_ap_inv_dropship_ui_pkg.AP_INV_DROPSHIP_DET_DB INDEX BY PLS_INTEGER;
  l_ap_inv_dropship_db ap_inv_dropship_db_ctt;
  l_error_count NUMBER;
  n             NUMBER := 0;
  l_start_date  DATE;
  l_end_date    DATE;
BEGIN
  IF l_ap_inv_dropship_db.count > 0 THEN
    l_ap_inv_dropship_db.delete;
  END IF;
  IF P_INV_START_DATE IS NOT NULL THEN
    OPEN C1 FOR SELECT INV.ORG_ID,
    SUPP.VENDOR_NAME Supplier_Name,
    SUPP.SEGMENT1 Supplier_Num,
    SITE.VENDOR_SITE_CODE Supplier_Site,
    INV.INVOICE_DATE Invoice_Date,
    INV.INVOICE_NUM Invoice_Num,
    XLNE.SKU SKU,
    XLNE.QUANTITY QTY,
    (XLNE.COST*-1) COST,
    XLNE.LINE_DESCRIPTION Check_Descrition,
    XLNE.RETURN_ORDER_NUM RTN_Order,
    XLNE.RETURN_ORDER_SUB RTN_Sub,
    XLNE.ORIG_ORDER_NUM Orig_Order,
    XLNE.ORIG_ORDER_SUB Ori_Sub,
    HOU.NAME OU_Name FROM AP_INVOICES_ALL INV,
    XX_AP_TRADE_INV_LINES XLNE,
    AP_SUPPLIERS SUPP,
    AP_SUPPLIER_SITES_ALL SITE,
    HR_OPERATING_UNITS HOU WHERE 1=1 AND INV.INVOICE_DATE BETWEEN to_date(TO_CHAR(P_INV_START_DATE)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(TO_CHAR(P_INV_END_DATE)||' 23:59:59','DD-MON-RR HH24:MI:SS') AND INV.SOURCE||'' = 'US_OD_DROPSHIP' AND INV.INVOICE_TYPE_LOOKUP_CODE = 'DEBIT' AND INV.INVOICE_NUM LIKE 'DS%' AND INV.CANCELLED_DATE IS NULL AND INV.ORG_ID+0 = P_ORG_ID AND INV.INVOICE_ID = NVL(P_INVOICE_ID, INV.INVOICE_ID) AND INV.VENDOR_ID = NVL(P_VENDOR_ID, INV.VENDOR_ID) AND INV.VENDOR_SITE_ID = NVL(P_VENDOR_SITE_ID, INV.VENDOR_SITE_ID) AND (P_REASON_CODE IS NULL OR XLNE.REASON_CODE = P_REASON_CODE) AND HOU.ORGANIZATION_ID = INV.ORG_ID AND SUPP.VENDOR_ID = INV.VENDOR_ID AND SITE.VENDOR_SITE_ID = INV.VENDOR_SITE_ID AND XLNE.INVOICE_NUMBER = INV.INVOICE_NUM;
  ELSE
    OPEN C1 FOR SELECT INV.ORG_ID,
    SUPP.VENDOR_NAME Supplier_Name,
    SUPP.SEGMENT1 Supplier_Num,
    SITE.VENDOR_SITE_CODE Supplier_Site,
    INV.INVOICE_DATE Invoice_Date,
    INV.INVOICE_NUM Invoice_Num,
    XLNE.SKU SKU,
    XLNE.QUANTITY QTY,
    (XLNE.COST*-1) COST,
    XLNE.LINE_DESCRIPTION Check_Descrition,
    XLNE.RETURN_ORDER_NUM RTN_Order,
    XLNE.RETURN_ORDER_SUB RTN_Sub,
    XLNE.ORIG_ORDER_NUM Orig_Order,
    XLNE.ORIG_ORDER_SUB Ori_Sub,
    HOU.NAME OU_Name FROM AP_INVOICES_ALL INV,
    XX_AP_TRADE_INV_LINES XLNE,
    AP_SUPPLIERS SUPP,
    AP_SUPPLIER_SITES_ALL SITE,
    HR_OPERATING_UNITS HOU WHERE 1=1 AND (P_GL_START_DATE IS NULL OR (INV.GL_DATE BETWEEN to_date(TO_CHAR(P_GL_START_DATE)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(TO_CHAR(P_GL_END_DATE)||' 23:59:59','DD-MON-RR HH24:MI:SS'))) AND INV.SOURCE||'' = 'US_OD_DROPSHIP' AND INV.INVOICE_TYPE_LOOKUP_CODE = 'DEBIT' AND INV.INVOICE_NUM LIKE 'DS%' AND INV.CANCELLED_DATE IS NULL AND INV.ORG_ID+0 = P_ORG_ID AND INV.INVOICE_ID = NVL(P_INVOICE_ID, INV.INVOICE_ID) AND INV.VENDOR_ID = NVL(P_VENDOR_ID, INV.VENDOR_ID) AND INV.VENDOR_SITE_ID = NVL(P_VENDOR_SITE_ID, INV.VENDOR_SITE_ID) AND (P_REASON_CODE IS NULL OR XLNE.REASON_CODE = P_REASON_CODE) AND HOU.ORGANIZATION_ID = INV.ORG_ID AND SUPP.VENDOR_ID = INV.VENDOR_ID AND SITE.VENDOR_SITE_ID = INV.VENDOR_SITE_ID AND XLNE.INVOICE_NUMBER = INV.INVOICE_NUM;
  END IF;
  LOOP
    FETCH C1 BULK COLLECT
    INTO l_ap_inv_dropship_db limit 500;
  FOR i IN 1 .. l_ap_inv_dropship_db.count
  LOOP
    pipe row (l_ap_inv_dropship_db(i));
  END LOOP;
  EXIT
WHEN C1%NOTFOUND;
END LOOP;
CLOSE C1;
RETURN ;
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Error caught in dropship deduction detail procedure '||SQLERRM);
END GET_DROPSHIP_DEDUCTION_DETAIL;
FUNCTION GET_DROPSHIP_NON_DEDUCTION(
    P_START_DATE     DATE,
    P_END_DATE       DATE,
    P_ORG_ID         NUMBER,
    P_VENDOR_ID      NUMBER,
    P_VENDOR_SITE_ID NUMBER,
    P_PO_NUM         VARCHAR2,
    P_REASON_CODE    VARCHAR2)
  RETURN XX_AP_INV_DROPSHIP_UI_PKG.AP_DROPSHIP_NONDED_DB_CTT PIPELINED
IS
  CURSOR C1
  IS
    SELECT APS.VENDOR_NAME Supplier_Name,
      APS.SEGMENT1 Supplier_Num,
      ASSA.VENDOR_SITE_CODE Supplier_Site,
      XND.SALES_DATE Sales_Date,
      XND.RETURN_ORDER_NUM RTN_Order,
      XND.RETURN_ORDER_SUB RTN_Sub,
      XND.ORIG_ORDER_NUM Orig_Order,
      XND.ORIG_ORDER_SUB Orig_Sub,
      XND.LOCATION_NUM Location,
      XND.PO_NUMBER PO_Num,
      XND.SKU SKU,
      XND.QUANTITY QTY,
      (XND.COST*-1) COST,
      XND.RETRUN_REASON_CODE RTN_REASON_CODE,
      XND.RETURN_AUTH_CODE RTN_AUTH_CODE,
      XND.CREATION_DATE Import_Date
    FROM XX_AP_DROPSHIP_NON_DEDUCTIONS XND,
      AP_SUPPLIERS APS,
      AP_SUPPLIER_SITES_ALL ASSA
    WHERE 1            =1
    AND (P_START_DATE IS NULL
    OR (XND.SALES_DATE BETWEEN to_date(TO_CHAR(P_START_DATE)
      ||' 00:00:00','DD-MON-RR HH24:MI:SS')
    AND to_date(TO_CHAR(P_END_DATE)
      ||' 23:59:59','DD-MON-RR HH24:MI:SS')))
    AND LTRIM(ASSA.VENDOR_SITE_CODE_ALT, '0') = LTRIM(XND.VENDOR_NUM, '0')
    AND ((ASSA.INACTIVE_DATE                 IS NULL)
    OR (ASSA.INACTIVE_DATE                    > SYSDATE))
    AND ASSA.PAY_SITE_FLAG                    = 'Y'
    AND ASSA.ORG_ID                           = P_ORG_ID
    AND (P_REASON_CODE                       IS NULL
    OR XND.RETRUN_REASON_CODE                 = P_REASON_CODE)
    AND APS.VENDOR_ID                         = ASSA.VENDOR_ID
    AND APS.VENDOR_ID                         = NVL(P_VENDOR_ID, APS.VENDOR_ID)
    AND ASSA.VENDOR_SITE_ID                   = NVL(P_VENDOR_SITE_ID, ASSA.VENDOR_SITE_ID)
    AND XND.PO_NUMBER                         = NVL(P_PO_NUM, XND.PO_NUMBER);
TYPE ap_dropship_nonded_db_ctt
IS
  TABLE OF xx_ap_inv_dropship_ui_pkg.AP_DROPSHIP_NONDED_DB INDEX BY PLS_INTEGER;
  l_ap_dropship_nonded_db ap_dropship_nonded_db_ctt;
  l_error_count NUMBER;
  n             NUMBER := 0;
BEGIN
  IF l_ap_dropship_nonded_db.count > 0 THEN
    l_ap_dropship_nonded_db.delete;
  END IF;
  OPEN C1;
  LOOP
    FETCH C1 BULK COLLECT
    INTO l_ap_dropship_nonded_db limit 500;
    FOR i IN 1 .. l_ap_dropship_nonded_db.count
    LOOP
      pipe row (l_ap_dropship_nonded_db(i));
    END LOOP;
    EXIT
  WHEN C1%NOTFOUND;
  END LOOP;
  CLOSE C1;
  RETURN ;
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Error caught in main procedure '||SQLERRM);
END GET_DROPSHIP_NON_DEDUCTION;
END xx_ap_inv_dropship_ui_pkg;
/

SHOW ERRORS;