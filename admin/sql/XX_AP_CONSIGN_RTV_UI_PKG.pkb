SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE BODY      XX_AP_CONSIGN_RTV_UI_PKG
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
FUNCTION CONSIGN_PIPE(
    P_VENDOR_ID    NUMBER,
    P_VEND_SITE_ID NUMBER ,
    P_ITEM_ID      NUMBER,   
    P_RTV           VARCHAR2,	--Added 30 jan
    P_RGA            VARCHAR2,
    P_LOCATION_ID    NUMBER,
    P_DATE_FROM      DATE ,
    P_DATE_TO        DATE,
    P_ORG_ID         NUMBER,
    P_GL_PERIOD_FROM VARCHAR2,
    P_GL_PERIOD_TO   VARCHAR2)
  RETURN XX_AP_CONSIGN_RTV_UI_PKG.CONSIGN_RTV_DB_CTT PIPELINED
IS
  CURSOR C3
  IS
    SELECT 
      ASA.VENDOR_SITE_CODE SUPPLIER_SITE,
      ASU.VENDOR_NAME SUPPLIER_NAME ,
      MMT.ATTRIBUTE2 ORIGINAL_RTV ,      
      MMT.TRANSACTION_DATE TRANSACTION_DATE,      
      SUBSTR(HR.LOCATION_CODE,INSTR(HR.LOCATION_CODE,':')-4,4) LOCATION ,
      MSIB.SEGMENT1 SKU ,
      MMT.ATTRIBUTE5 FREIGHT_CARRIER ,
      MMT.ATTRIBUTE4 FREIGHT_BILL ,
      MMT.ATTRIBUTE3 RGA ,
      MMT.ATTRIBUTE6 VENDOR_PRODUCT ,
      MSIB.DESCRIPTION ,
      MMT.TRANSACTION_QUANTITY ,
      MMT.TRANSACTION_COST ,
      (MMT.TRANSACTION_COST * MMT.TRANSACTION_QUANTITY) EXTENDED_COST
    FROM 
      MTL_SYSTEM_ITEMS_B MSIB,
      HR_LOCATIONS_ALL HR,
      AP_SUPPLIERS ASU,
      AP_SUPPLIER_SITES_ALL ASA,
      MTL_MATERIAL_TRANSACTIONS MMT
    WHERE 1                         =1    
    AND MMT.TRANSACTION_DATE       BETWEEN    TO_DATE(TO_CHAR(G_START_DATE)||' 00:00:00','DD-MON-YY HH24:MI:SS')
        AND TO_DATE(TO_CHAR(G_END_DATE) ||' 23:59:59','DD-MON-RR HH24:MI:SS')
    AND MMT.TRANSACTION_SOURCE_NAME = 'OD CONSIGNMENT RTV' 
    AND MMT.ATTRIBUTE1 IS NOT NULL
    AND MMT.INVENTORY_ITEM_ID = NVL(P_ITEM_ID, MMT.INVENTORY_ITEM_ID)    
    AND LTRIM(asa.vendor_site_code_alt,'0')=LTRIM(MMT.ATTRIBUTE1,'0')         
    AND ASA.PAY_SITE_FLAG='Y'
    AND ASU.VENDOR_ID           = ASA.VENDOR_ID
    AND MSIB.INVENTORY_ITEM_ID = MMT.INVENTORY_ITEM_ID
    AND MSIB.ORGANIZATION_ID+0   = MMT.ORGANIZATION_ID
    AND HR.INVENTORY_ORGANIZATION_ID         = MMT.ORGANIZATION_ID     
    AND HR.LOCATION_ID         = NVL(P_LOCATION_ID, HR.LOCATION_ID)
    AND ASU.VENDOR_ID          = NVL(P_VENDOR_ID , ASU.VENDOR_ID)
    AND ASA.VENDOR_SITE_ID     = NVL(P_VEND_SITE_ID, ASA.VENDOR_SITE_ID)
    AND NVL(MMT.ATTRIBUTE3,'X') = NVL(P_RGA,NVL(MMT.ATTRIBUTE3,'X'))    
	AND NVL(MMT.ATTRIBUTE2,'X') = NVL(P_RTV,NVL(MMT.ATTRIBUTE2,'X'))     --Added 30 Jan
    AND ASA.org_id=NVL(p_org_id,asa.org_id);

  TYPE CONSIGNMENT_DB_CTT
  IS
  TABLE OF XX_AP_CONSIGN_RTV_UI_PKG.consign_rtv_db INDEX BY PLS_INTEGER;
  L_CONSIGNMENT_DB CONSIGNMENT_DB_CTT;
  --L_CONSIGNMENT_DB XX_AP_CONSIGN_RTV_UI_PKG.CONSIGN_RTV_DB_CTT;
  L_ERROR_COUNT NUMBER;
  EX_DML_ERRORS EXCEPTION;
  PRAGMA EXCEPTION_INIT(EX_DML_ERRORS, -24381);
  N             NUMBER := 0;
  LV_START_DATE DATE;
  LV_END_DATE   DATE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('procedure started');
  IF ((P_DATE_FROM IS NOT NULL ) AND (P_DATE_TO IS NOT NULL)) THEN
    G_START_DATE   := P_DATE_FROM;
    G_END_DATE     := P_DATE_TO;
    DBMS_OUTPUT.PUT_LINE('inside if '||G_START_DATE||'----'||G_END_DATE);
    DBMS_OUTPUT.PUT_LINE('inside if '||P_LOCATION_ID||'----'||P_LOCATION_ID);
  ELSE
    BEGIN
      SELECT TO_DATE(START_DATE,'DD-MON-YY')
      INTO G_START_DATE
      FROM GL_PERIODS P
      WHERE ADJUSTMENT_PERIOD_FLAG = 'N'
      AND PERIOD_SET_NAME          = 'OD 445 CALENDAR'
      AND PERIOD_NAME              = P_GL_PERIOD_FROM;
      SELECT TO_DATE(END_DATE,'DD-MON-YY')
      INTO G_END_DATE
      FROM GL_PERIODS P
      WHERE ADJUSTMENT_PERIOD_FLAG = 'N'
      AND PERIOD_SET_NAME          = 'OD 445 CALENDAR'
      AND PERIOD_NAME              = P_GL_PERIOD_TO;
      DBMS_OUTPUT.PUT_LINE('inside else '||G_START_DATE||'----'||G_END_DATE);
    EXCEPTION
    WHEN OTHERS THEN
      G_START_DATE := TO_DATE(TRUNC(SYSDATE+10),'DD-MON-YY');
      G_END_DATE   := TO_DATE(TRUNC(SYSDATE+10),'DD-MON-YY');
      DBMS_OUTPUT.PUT_LINE('exception if '||LV_START_DATE||'----'||LV_END_DATE);
    END;
  END IF;
  IF L_CONSIGNMENT_DB.COUNT > 0 THEN
      L_CONSIGNMENT_DB.DELETE;
    END IF;
   
  OPEN C3;
  LOOP
    FETCH C3 BULK COLLECT
    INTO L_CONSIGNMENT_DB LIMIT 500;
    FOR I IN 1 .. L_CONSIGNMENT_DB.COUNT
    LOOP
      PIPE ROW (L_CONSIGNMENT_DB(I));
    END LOOP;
    EXIT
  WHEN C3%NOTFOUND;
  END LOOP;
  CLOSE C3;
 RETURN;
EXCEPTION
WHEN EX_DML_ERRORS THEN
  L_ERROR_COUNT := SQL%BULK_EXCEPTIONS.COUNT;
  DBMS_OUTPUT.PUT_LINE('Number of failures: ' || L_ERROR_COUNT);
  FOR I IN 1 .. L_ERROR_COUNT
  LOOP
    DBMS_OUTPUT.PUT_LINE ( 'Error: ' || I || ' Array Index: ' || SQL%BULK_EXCEPTIONS(I).ERROR_INDEX || ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(I).ERROR_CODE) ) ;
  END LOOP;
END CONSIGN_PIPE;
END;
/

SHOW ERRORS;