SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE BODY XX_AP_RTVCONS_PKG
AS
  -- +==========================================================================+
  -- |                  Office Depot - Project Simplify                         |
  -- |                            Providge                                      |
  -- +==========================================================================+
  -- | Name             :    XX_AP_RTVCONS_PKG                                  |
  -- | Description      :    Package for Chargeback RTV Consignment             |
  -- | RICE ID          :    R 7040                                             |
  -- |                                                                          |
  -- |                                                                          |
  -- |Change Record:                                                            |
  -- |===============                                                           |
  -- |Version   Date         Author              Remarks                        |
  -- |=======   ===========  ================    ========================       |
  -- | 1.0      15-Jan-2018  Phani Teja R          Initial                      |
  -- | 1.1      06-Feb-2018  Phani Teja R          Added date parameters        |
  -- +==========================================================================+
FUNCTION findDispCode(P_INVOICE_NBR VARCHAR2)
RETURN VARCHAR2 
IS
    P_REASON_CD_O VARCHAR2(10)        := NULL;
    P_RGA_NBR_O  VARCHAR2(60)         := NULL;
    P_CARRIER_ID_O VARCHAR2(60)       := NULL;
    P_SHIP_NAME_O  VARCHAR2(60)       := NULL;
    P_SHIP_ADDR_LINE_1_O  VARCHAR2(60) := NULL;
    P_SHIP_ADDR_LINE_2_O VARCHAR2(60) := NULL;
    P_SHIP_CITY_O  VARCHAR2(60)       := NULL;
    P_SHIP_STATE_O VARCHAR2(60)       := NULL;
    P_SHIP_ZIP_O   VARCHAR2(60)       := NULL;
    P_SHIP_COUNTRY_CD_O  VARCHAR2(60) := NULL;
    P_CONT_RGA_FLG_O VARCHAR2(60)     := NULL;
    P_RTV_RGA_O   VARCHAR2(60)        := NULL;
    P_FAX_DD_WRKSHT_FLG_O VARCHAR2(60) := NULL;
    P_CONT_DESTROY_FLG_O VARCHAR2(60) := NULL;
    P_RTV_DESTROY_RGA_O  VARCHAR2(60) := NULL;
   -- P_INVOICE_NBR        VARCHAR2(60) := NULL;
   LC_DISP_CD VARCHAR2(20) := NULL;
   LC_DISP_DESCR VARCHAR2(60) := NULL;
   lv_disp_code Varchar2(120) := NULL;
    
BEGIN
    BEGIN
    SELECT DISTINCT XARH.RETURN_CODE ,
    XARH.RETURN_DESCRIPTION      
    INTO P_REASON_CD_O ,
    lc_disp_descr     
    FROM XX_AP_RTV_HDR_ATTR XARH,
      XX_AP_RTV_LINES_ATTR XARL
    WHERE XARH.HEADER_ID    =XARL.HEADER_ID
    AND XARH.FREQUENCY_CODE =P_FREQUENCY
    AND XARH.INVOICE_NUM = P_INVOICE_NBR;
 EXCEPTION
 WHEN OTHERS THEN
 FND_FILE.PUT_LINE(FND_FILE.LOG, 'exception while querying for disposition code');
 END;
 
 LV_DISP_CODE := P_REASON_CD_O||'-'||LC_DISP_DESCR;
 FND_FILE.PUT_LINE(FND_FILE.LOG, lv_disp_code);
 /*
    
IF P_REASON_CD_O IN ('BB', 'DD', 'MS') THEN

    IF P_CONT_RGA_FLG_O = 'Y' THEN
         lc_disp_cd := '01';
         lc_disp_descr := 'RETURN - WRITE VENDOR FOR RGA';
    ELSE
      IF P_RTV_RGA_O IS NOT NULL THEN
             lc_disp_cd := '02';
             lc_disp_descr := 'RETURN - PERM. VENDOR RGA';
      ELSE
        IF P_FAX_DD_WRKSHT_FLG_O = 'Y' THEN
                lc_disp_cd := '03';
                lc_disp_descr := 'RETURN - FAX/CALL VEND FOR RGA';
        ELSE
                lc_disp_cd := '04';
                lc_disp_descr := 'RETURN - CALL BUYER FOR INST.';
        END IF;
      END IF;
    END IF;
  ELSIF P_REASON_CD_O = 'DC' THEN
    IF P_CONT_DESTROY_FLG_O = 'Y' THEN
       lc_disp_cd := '21';
       lc_disp_descr := 'DESTROY-WRITE VENDOR FOR AUTH.';
    ELSE
      IF P_RTV_DESTROY_RGA_O IS NOT NULL THEN
         lc_disp_cd := '22';
         lc_disp_descr := 'DESTROY-VENDOR PERM. AUTH.';
      ELSE
         lc_disp_cd := '73';
         lc_disp_descr := 'DESTROY-OPTION 73';
      END IF;
    END IF;
  ELSIF P_REASON_CD_O = 'PR' THEN
      lc_disp_cd := '41';
      lc_disp_descr := 'MARK DOWN, SELL IN PLACE';
  END IF;  
 */  
RETURN lv_disp_code;
  
END findDispCode;

FUNCTION beforeReport
  RETURN BOOLEAN
IS
  lv_start_date DATE := TRUNC(to_date(sysdate));
  lv_end_date   DATE := TRUNC(to_date(sysdate));
  lv_qtr        VARCHAR2(2); -- :=3;
  LV_MONTH      VARCHAR2(15);-- :='SEP-17';
  lv_frequency VARCHAR2(15) := NULL;
  
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'inside before report');
    BEGIN
    SELECT instance_name INTO G_INSTANCE FROM v$instance;
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in finding instance name');
  END;

  BEGIN
    SELECT TO_CHAR(TO_DATE(sysdate, 'DD-MON-YY'), 'Q')INTO lv_qtr FROM DUAL;
    SELECT TO_CHAR(sysdate, 'MON-YY') INTO lv_month FROM dual;  
  END;
  
  IF P_FREQUENCY = 'QY' THEN
    BEGIN
      SELECT MIN(start_date),
        MAX(end_date)
      INTO lv_start_date,
        lv_end_date
      FROM gl_periods
      WHERE period_year = EXTRACT (YEAR FROM sysdate)
      AND QUARTER_NUM   = NVL(TO_NUMBER(LV_QTR), QUARTER_NUM);
      
      LV_FREQUENCY :='QUARTERLY';
    
    END;
  END IF;
  IF P_FREQUENCY = 'MY' THEN
    BEGIN
      SELECT MIN(start_date) ,
        MAX(end_date)
      INTO lv_start_date,
        lv_end_date
      FROM gl_periods
      WHERE period_year = EXTRACT (YEAR FROM sysdate)
      AND period_name   = NVL(lv_month, period_name);
            
LV_FREQUENCY :='MONTHLY';
      
    END;
  END IF;
  IF P_FREQUENCY = 'WY' THEN
    BEGIN
      SELECT to_date(next_day(SYSDATE-7, 'sun')) ,
        to_date(next_day(SYSDATE, 'sat'))
      INTO lv_start_date,
        lv_end_date
      FROM gl_periods
      WHERE period_year = EXTRACT (YEAR FROM sysdate)
      AND rownum        =1;
      
  LV_FREQUENCY :='WEEKLY';
    END;
  END IF;
  
  --added on 06-Feb-2018  Version 1.1  
  	 IF P_START_DATE IS NOT NULL AND P_END_DATE IS NOT NULL
	 	THEN 
	     G_WHERE_CLAUSE :=  'and XPVS.SEGMENT44='''||LV_FREQUENCY||''' and MMT.TRANSACTION_DATE BETWEEN  TO_DATE(TO_CHAR(''' || P_START_DATE||' 00:00:00' ||''')' ||','||'''DD-MON-YY HH24:MI:SS'''  ||')'
||  ' and ' || 'TO_DATE(TO_CHAR('''|| P_END_DATE ||' 23:59:59' ||''')' ||','||'''DD-MON-YY HH24:MI:SS'''  ||')';	
		
		ELSIF P_START_DATE IS NOT NULL AND P_END_DATE IS NULL 
	 	THEN
		    G_WHERE_CLAUSE :=  'and XPVS.SEGMENT44='''||LV_FREQUENCY||''' and MMT.TRANSACTION_DATE >= TO_DATE(TO_CHAR(''' || P_START_DATE||' 00:00:00' ||''')' ||','||'''DD-MON-YY HH24:MI:SS'''  ||')';
		ELSIF P_START_DATE IS NULL AND P_END_DATE IS NOT NULL
		THEN 
		    G_WHERE_CLAUSE :=  'and XPVS.SEGMENT44='''||LV_FREQUENCY||''' and MMT.TRANSACTION_DATE <= TO_DATE(TO_CHAR(''' || P_END_DATE||' 23:59:59' ||''')' ||','||'''DD-MON-YY HH24:MI:SS'''  ||')';
		
		ELSIF P_START_DATE IS NULL AND P_END_DATE IS NULL
		THEN
		    -- addeed below 26 jan 2018
		    G_WHERE_CLAUSE :=  'AND MMT.ATTRIBUTE10 IS NULL AND XPVS.SEGMENT44='''||LV_FREQUENCY||''' and MMT.TRANSACTION_DATE BETWEEN  TO_DATE(TO_CHAR(''' || lv_start_date||' 00:00:00' ||''')' ||','||'''DD-MON-YY HH24:MI:SS'''  ||')'
||  ' and ' || 'TO_DATE(TO_CHAR('''|| lv_end_date ||' 23:59:59' ||''')' ||','||'''DD-MON-YY HH24:MI:SS'''  ||')';
     
	 END IF;
-- added on 06-Feb-2018  Version 1.1

  --G_WHERE_CLAUSE := 'and trunc(MMT.TRANSACTION_DATE) BETWEEN ''' || lv_start_date || ''' and ''' || lv_end_date || '''';
  -- commented 26 jan 18  G_WHERE_CLAUSE := 'and XPVS.SEGMENT44='''||LV_FREQUENCY||''' and trunc(MMT.TRANSACTION_DATE) BETWEEN ''' || lv_start_date || ''' and ''' || lv_end_date || '''';
 

  XX_AP_XML_BURSTING_PKG.Get_email_detail( 'XXAPRTVCONXML',G_SMTP_SERVER,G_EMAIL_SUBJECT,G_EMAIL_CONTENT,G_DISTRIBUTION_LIST) ;
  --null;
  FND_FILE.PUT_LINE(FND_FILE.LOG,G_WHERE_CLAUSE);


  RETURN true;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR at XX_AP_RTVCONS_PKG.beforeReport:- ' || SQLERRM);
END BEFOREREPORT;

FUNCTION afterReport return BOOLEAN
 IS
  p_request_id NUMBER;
  L_REQUEST_ID NUMBER;
  lv_start_date DATE := TRUNC(to_date(sysdate));
  lv_end_date   DATE := TRUNC(to_date(sysdate));
  lv_qtr        VARCHAR2(2); -- :=3;
  LV_MONTH      VARCHAR2(15);-- :='SEP-17';
  lv_frequency VARCHAR2(15) := NULL;
  lv_count NUMBER :=0;

  CURSOR C1(L_FREQUENCY VARCHAR2,L_START_DATE DATE, L_END_DATE DATE)
IS
SELECT DISTINCT mmt.transaction_id
  from XX_PO_VENDOR_SITES_KFF XPVS,
  XX_AP_RTV_HDR_ATTR XARH,
  XX_AP_RTV_LINES_ATTR XARL,
  MTL_MATERIAL_TRANSACTIONS MMT,
  --MTL_SYSTEM_ITEMS_B MSIB,
  AP_SUPPLIERS ASU,
  AP_SUPPLIER_SITES_ALL ASA
WHERE 1                                 =1
AND  XPVS.SEGMENT44= L_FREQUENCY
AND  XPVS.SEGMENT43 <> '100'
AND TRUNC(MMT.TRANSACTION_DATE) BETWEEN L_START_DATE  AND  L_END_DATE
AND MMT.TRANSACTION_SOURCE_NAME         = 'OD CONSIGNMENT RTV'
AND MMT.ATTRIBUTE1                     IS NOT NULL
AND MMT.ATTRIBUTE2                     IS NOT NULL
--AND MMT.ATTRIBUTE5 IS NOT NULL
AND MMT.attribute10 is null
AND LTRIM(ASA.vendor_site_code_alt,'0') = LTRIM(MMT.ATTRIBUTE1,'0')
AND ASA.PAY_SITE_FLAG                   ='Y'
AND ASU.VENDOR_ID                       = ASA.VENDOR_ID
AND ASA.ATTRIBUTE12                     = XPVS.VS_KFF_ID
AND XARL.HEADER_ID                      = XARH.HEADER_ID
AND XARL.RTV_NUMBER                     = XARH.RTV_NUMBER
AND XARH.RECORD_STATUS                  = 'C'  
 --AND MSIB.INVENTORY_ITEM_ID              = MMT.INVENTORY_ITEM_ID
  --AND MSIB.ORGANIZATION_ID+0              = MMT.ORGANIZATION_ID
AND mmt.attribute2 = xarh.rtv_number
AND mmt.ATTRIBUTE3 = xarl.rga_number;
-- added on 06th Feb , Version 1.1
  CURSOR C2(L_FREQUENCY VARCHAR2,L_START_DATE DATE)
IS
SELECT DISTINCT mmt.transaction_id
  from XX_PO_VENDOR_SITES_KFF XPVS,
  XX_AP_RTV_HDR_ATTR XARH,
  XX_AP_RTV_LINES_ATTR XARL,
  MTL_MATERIAL_TRANSACTIONS MMT,
  --MTL_SYSTEM_ITEMS_B MSIB,
  AP_SUPPLIERS ASU,
  AP_SUPPLIER_SITES_ALL ASA
WHERE 1                                 =1
AND  XPVS.SEGMENT44= L_FREQUENCY
AND  XPVS.SEGMENT43 <> '100'
AND TRUNC(MMT.TRANSACTION_DATE) >= L_START_DATE  
AND MMT.TRANSACTION_SOURCE_NAME         = 'OD CONSIGNMENT RTV'
AND MMT.ATTRIBUTE1                     IS NOT NULL
AND MMT.ATTRIBUTE2                     IS NOT NULL
--AND MMT.ATTRIBUTE5 IS NOT NULL
AND MMT.attribute10 is null
AND LTRIM(ASA.vendor_site_code_alt,'0') = LTRIM(MMT.ATTRIBUTE1,'0')
AND ASA.PAY_SITE_FLAG                   ='Y'
AND ASU.VENDOR_ID                       = ASA.VENDOR_ID
AND ASA.ATTRIBUTE12                     = XPVS.VS_KFF_ID
AND XARL.HEADER_ID                      = XARH.HEADER_ID
AND XARL.RTV_NUMBER                     = XARH.RTV_NUMBER
AND XARH.RECORD_STATUS                  = 'C'  
 --AND MSIB.INVENTORY_ITEM_ID              = MMT.INVENTORY_ITEM_ID
  --AND MSIB.ORGANIZATION_ID+0              = MMT.ORGANIZATION_ID
AND mmt.attribute2 = xarh.rtv_number
AND mmt.ATTRIBUTE3 = xarl.rga_number;

  CURSOR C3(L_FREQUENCY VARCHAR2, L_END_DATE DATE)
IS
SELECT DISTINCT mmt.transaction_id
  from XX_PO_VENDOR_SITES_KFF XPVS,
  XX_AP_RTV_HDR_ATTR XARH,
  XX_AP_RTV_LINES_ATTR XARL,
  MTL_MATERIAL_TRANSACTIONS MMT,
  --MTL_SYSTEM_ITEMS_B MSIB,
  AP_SUPPLIERS ASU,
  AP_SUPPLIER_SITES_ALL ASA
WHERE 1                                 =1
AND  XPVS.SEGMENT44= L_FREQUENCY
AND  XPVS.SEGMENT43 <> '100'
AND TRUNC(MMT.TRANSACTION_DATE) <= L_END_DATE
AND MMT.TRANSACTION_SOURCE_NAME         = 'OD CONSIGNMENT RTV'
AND MMT.ATTRIBUTE1                     IS NOT NULL
AND MMT.ATTRIBUTE2                     IS NOT NULL
--AND MMT.ATTRIBUTE5 IS NOT NULL
AND MMT.attribute10 is null
AND LTRIM(ASA.vendor_site_code_alt,'0') = LTRIM(MMT.ATTRIBUTE1,'0')
AND ASA.PAY_SITE_FLAG                   ='Y'
AND ASU.VENDOR_ID                       = ASA.VENDOR_ID
AND ASA.ATTRIBUTE12                     = XPVS.VS_KFF_ID
AND XARL.HEADER_ID                      = XARH.HEADER_ID
AND XARL.RTV_NUMBER                     = XARH.RTV_NUMBER
AND XARH.RECORD_STATUS                  = 'C'  
 --AND MSIB.INVENTORY_ITEM_ID              = MMT.INVENTORY_ITEM_ID
  --AND MSIB.ORGANIZATION_ID+0              = MMT.ORGANIZATION_ID
AND mmt.attribute2 = xarh.rtv_number
AND mmt.ATTRIBUTE3 = xarl.rga_number;

BEGIN 

 BEGIN
    SELECT instance_name INTO G_INSTANCE FROM v$instance;
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in finding instance name');
  END;

  BEGIN
    SELECT TO_CHAR(TO_DATE(sysdate, 'DD-MON-YY'), 'Q')INTO lv_qtr FROM DUAL;
    SELECT TO_CHAR(sysdate, 'MON-YY') INTO lv_month FROM dual;  
  END;
  
  IF P_FREQUENCY = 'QY' THEN
    BEGIN
      SELECT MIN(start_date),
        MAX(end_date)
      INTO lv_start_date,
        lv_end_date
      FROM gl_periods
      WHERE period_year = EXTRACT (YEAR FROM sysdate)
      AND QUARTER_NUM   = NVL(TO_NUMBER(LV_QTR), QUARTER_NUM);
      
      LV_FREQUENCY :='QUARTERLY';
    
    END;
  END IF;
  
  IF P_FREQUENCY = 'MY' THEN
    BEGIN
      SELECT MIN(start_date),
        MAX(end_date)
      INTO lv_start_date,
        lv_end_date
      FROM gl_periods
      WHERE period_year = EXTRACT (YEAR FROM sysdate)
      AND period_name   = NVL(lv_month, period_name);
            
LV_FREQUENCY :='MONTHLY';
      
    END;
  END IF;
  
  IF P_FREQUENCY = 'WY' THEN
    BEGIN
      SELECT to_date(next_day(SYSDATE-7, 'sun')) ,
        to_date(next_day(SYSDATE, 'sat'))
      INTO lv_start_date,
        lv_end_date
      FROM gl_periods
      WHERE period_year = EXTRACT (YEAR FROM sysdate)
      AND rownum        =1;    
  LV_FREQUENCY :='WEEKLY';
    END;
  END IF;
--lv_start_date:='01-OCT-17';
  --lv_end_date:='31-DEC-17';  
  
  
IF P_START_DATE IS NOT NULL AND P_END_DATE IS NOT NULL
THEN

LV_START_DATE := fnd_date.canonical_to_date(P_START_DATE);
LV_END_DATE   := fnd_date.canonical_to_date(P_END_DATE);
BEGIN 

FOR I1 IN C1(LV_FREQUENCY,P_START_DATE,P_END_DATE)
LOOP
/*
UPDATE MTL_MATERIAL_TRANSACTIONS 
SET ATTRIBUTE10='Y' 
WHERE TRANSACTION_ID=I1.TRANSACTION_ID;
*/
lv_count := lv_count+1;
END LOOP;

--COMMIT;
FND_FILE.PUT_LINE(FND_FILE.LOG,P_START_DATE);
FND_FILE.PUT_LINE(FND_FILE.LOG,P_END_DATE);
FND_FILE.PUT_LINE(FND_FILE.LOG,'COMMIT successful');
EXCEPTION
WHEN OTHERS THEN
FND_FILE.PUT_LINE(FND_FILE.LOG,'error while updating attribute');

END;

ELSIF  P_START_DATE IS NOT NULL AND P_END_DATE IS NULL
THEN

LV_START_DATE := fnd_date.canonical_to_date(P_START_DATE);
--LV_END_DATE   := fnd_date.canonical_to_date(P_END_DATE);
BEGIN 

FOR I2 IN C2(LV_FREQUENCY,P_START_DATE)
LOOP
/*
UPDATE MTL_MATERIAL_TRANSACTIONS 
SET ATTRIBUTE10='Y' 
WHERE TRANSACTION_ID=I2.TRANSACTION_ID;
*/
lv_count := lv_count+1;
END LOOP;

COMMIT;
FND_FILE.PUT_LINE(FND_FILE.LOG,'COMMIT successful');
EXCEPTION
WHEN OTHERS THEN
FND_FILE.PUT_LINE(FND_FILE.LOG,'error while updating attribute');

END;

ELSIF P_START_DATE IS NULL AND P_END_DATE IS NOT NULL
THEN

--LV_START_DATE := fnd_date.canonical_to_date(P_START_DATE);
LV_END_DATE   := fnd_date.canonical_to_date(P_END_DATE);
BEGIN 

FOR I3 IN C3(LV_FREQUENCY,P_END_DATE)
LOOP
/*
UPDATE MTL_MATERIAL_TRANSACTIONS 
SET ATTRIBUTE10='Y' 
WHERE TRANSACTION_ID=I3.TRANSACTION_ID;
*/
lv_count := lv_count+1;
END LOOP;

COMMIT;
FND_FILE.PUT_LINE(FND_FILE.LOG,'COMMIT successful');
FND_FILE.PUT_LINE(FND_FILE.LOG,lv_count);
EXCEPTION
WHEN OTHERS THEN
FND_FILE.PUT_LINE(FND_FILE.LOG,'error while updating attribute');

END;

ELSIF P_END_DATE IS  NULL AND P_START_DATE IS NULL 
THEN

BEGIN 

FOR I1 IN C1(LV_FREQUENCY,LV_START_DATE,LV_END_DATE)
LOOP
UPDATE MTL_MATERIAL_TRANSACTIONS 
SET ATTRIBUTE10='Y' 
WHERE TRANSACTION_ID=I1.TRANSACTION_ID;
lv_count := lv_count+1;
END LOOP;

COMMIT;
FND_FILE.PUT_LINE(FND_FILE.LOG,'COMMIT successful');
EXCEPTION
WHEN OTHERS THEN
FND_FILE.PUT_LINE(FND_FILE.LOG,'error while updating attribute');

END;

END IF;


   IF P_END_DATE IS NULL AND P_START_DATE IS NULL 
   THEN
   p_request_id := FND_GLOBAL.CONC_REQUEST_ID;
    IF (lv_count > 0) THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submitting : XML Publisher Report Bursting Program');
    l_request_id := FND_REQUEST.SUBMIT_REQUEST('XDO', 'XDOBURSTREP', NULL, NULL, FALSE, 'Y', p_request_id, 'Y');
    Fnd_File.PUT_LINE(Fnd_File.LOG, 'After submitting bursting ');
    COMMIT;
    END IF;
  END IF;
  
  RETURN(TRUE);
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception in after_report function '||SQLERRM );
END AFTERREPORT;
END XX_AP_RTVCONS_PKG;
/

SHOW ERRORS;