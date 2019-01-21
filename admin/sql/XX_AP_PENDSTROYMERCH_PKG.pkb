SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE Body XX_AP_PENDSTROYMERCH_PKG
AS
  -- +==========================================================================+
  -- |                  Office Depot - Project Simplify                         |
  -- |                            Providge                                      |
  -- +==========================================================================+
  -- | Name             :    XX_AP_PENDSTROYMERCH_PKG                           |
  -- | Description      :    Package for AP Open Invoice Conversion             |
  -- | RICE ID          :    R7033                                              |
  -- |                                                                          |
  -- |                                                                          |
  -- |Change Record:                                                            |
  -- |===============                                                           |
  -- |Version   Date         Author              Remarks                        |
  -- |=======   ===========  ================    ========================       |
  -- | 1.0      27-Sep-2017  Prabeethsoy Nair      Initial                      |
  -- | 1.1      10-Nov-2017  Jitendra Atale        Added Email bursting         |
  -- | 1.2      03-MAY-2018  Priyam Parmar         Added P_date as parameter    |
  -- | 1.3	    30-May-2018   Prabeethsoy Nair		 NAIT-39667 - Laoyout changes |
  -- +==========================================================================+
FUNCTION beforeReport
  RETURN BOOLEAN
IS
  lv_start_date DATE := TRUNC(to_date(sysdate));
  lv_end_date   DATE := TRUNC(to_date(sysdate));
  p_date        DATE;
  l_date        DATE := TRUNC(to_date(sysdate));
  lv_qtr        VARCHAR2(2); -- :=3;
  lv_month      VARCHAR2(15);-- :='SEP-17';
  lv_wk_day     VARCHAR2(100);
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'inside before report');
  BEGIN
    SELECT instance_name INTO G_INSTANCE FROM v$instance;
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in finding instance name');
  END;
  IF P_RUN_DATE IS NULL THEN
    P_date      := TRUNC(to_date(sysdate));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Run Date when P_RUN_DATE is NULL :  '|| p_date);
  ELSE
    p_date:= to_date(TO_CHAR(fnd_date.canonical_to_date (P_RUN_DATE),'YY-MON-DD'),'DD-MON-YY');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Run Date is :  '|| p_date);
  END IF;
  BEGIN
    SELECT TO_CHAR(TO_DATE(P_date, 'DD-MON-YY'), 'Q')INTO lv_qtr FROM DUAL;
    SELECT TO_CHAR(P_date, 'MON-YY') INTO lv_month FROM dual;
    --FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR at XX_AP_PENDSTROYMERCH_PKG.beforeReport wile cacluating current qtr/month:- ' || sqlerrm);
  END;
  IF P_FREQUENCY = 'QY' THEN
    BEGIN
      SELECT MIN(start_date) ,
        MAX(end_date)
      INTO lv_start_date,
        lv_end_date
      FROM gl_periods
      WHERE period_year = EXTRACT (YEAR FROM P_date)
      AND quarter_num   = NVL(TO_NUMBER(lv_qtr), quarter_num);
    END;
  END IF;
  IF P_FREQUENCY = 'MY' THEN
    BEGIN
      SELECT MIN(start_date) ,
        MAX(end_date)
      INTO lv_start_date,
        lv_end_date
      FROM gl_periods
      WHERE period_year = EXTRACT (YEAR FROM P_date)
      AND period_name   = NVL(lv_month, period_name);
    END;
  END IF;
  IF P_FREQUENCY = 'WY' THEN
    BEGIN
      SELECT TO_CHAR(to_date(p_date), 'DY') INTO lv_wk_day FROM dual;
      IF lv_wk_day = 'SAT' THEN
        SELECT to_date(next_day(P_date-7, 'sun')) ,
          to_date(P_date)
        INTO lv_start_date,
          lv_end_date
        FROM dual;
      ELSE
        SELECT to_date(next_day(P_date-7, 'sun')) ,
          to_date(next_day(P_date, 'sat')) 
        INTO lv_start_date,
          lv_end_date
        FROM DUAL;
      END IF;
    END;
  END IF;
  
lv_start_date :=to_date(lv_start_date ||' 00:00:00','DD-MON-RR HH24:MI:SS');
lv_end_date :=to_date(lv_end_date||' 23:59:59','DD-MON-RR HH24:MI:SS'); 
  fnd_file.put_line(fnd_file.log,to_char(lv_start_date,'DD-MON-RR HH24:MI:SS'));
  fnd_file.put_line(fnd_file.log,to_char(lv_end_date,'DD-MON-RR HH24:MI:SS'));

  --AND xarh.CREATION_DATE BETWEEN to_date(:P1||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(:P2||' 11:59:00','DD-MON-RR HH24:MI:SS');
 --G_WHERE_CLAUSE := ' and xarh.frequency_code = '''||P_FREQUENCY||''' and xarh.creation_date  BETWEEN ''' || to_date(lv_start_date,'DD-MON-RR HH24:MI:SS') || ''' and ''' || to_date(lv_end_date,'DD-MON-RR HH24:MI:SS')|| '''';
G_WHERE_CLAUSE  := ' and xarh.frequency_code = '''||P_FREQUENCY||''' and xarh.creation_date  BETWEEN  to_date(''' ||lv_start_date||''',''DD-MON-RR HH24:MI:SS'') and to_date(''' || lv_end_date||''',''DD-MON-RR HH24:MI:SS'')';
   -- NAIT-39667 Changed by Prabeethsoy Nair as part of accomidate layout changes.
  
  fnd_file.put_line(fnd_file.log,G_WHERE_CLAUSE);
  XX_AP_XML_BURSTING_PKG.Get_email_detail( 'XX_AP_PENDSTROYMERCHXML' , g_SMTP_SERVER,G_EMAIL_SUBJECT, G_EMAIL_CONTENT, G_DISTRIBUTION_LIST) ;
  BEGIN
    SELECT COUNT(*)
    INTO G_REC_COUNT
    FROM ap_supplier_sites_all aspa,
      ap_suppliers asp ,
      xx_ap_rtv_hdr_attr xarh
    WHERE xarh.record_status                                                                                      ='N'
    AND xarh.return_description                                                                                   ='DESTROY-OPTION 73'
    AND asp.vendor_id                                                                                             =aspa.vendor_id
    AND aspa.pay_site_flag                                                                                        = 'Y'
    AND NVL(aspa.inactive_date,sysdate)                                                                          >= TRUNC(sysdate)
    AND ltrim(NVL(aspa.attribute9,(NVL(aspa.attribute7,NVL(aspa.vendor_site_code_alt,aspa.vendor_site_id)))),'0') = ltrim(xarh.vendor_num,'0')
    AND xarh.frequency_code                                                                                       = P_FREQUENCY
    AND TRUNC(xarh.creation_date) BETWEEN lv_start_date AND lv_end_date
      --11/9/2017 - Commented  AND xarh.invoice_num like 'RTV730%' by Jitendra for defect NAIT-17094
      --AND xarh.invoice_num like 'RTV730%'
    AND EXISTS
      (SELECT 1
      FROM xx_ap_rtv_lines_attr xarl
      WHERE xarh.rtv_number = xarl.rtv_number
      );
  EXCEPTION
  WHEN OTHERS THEN
    G_REC_COUNT :=0;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'G_REC_COUNT ' || G_REC_COUNT);
  END;
  RETURN true;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR at XX_AP_PENDSTROYMERCH_PKG.beforeReport:- ' || sqlerrm);
END BEFOREREPORT;
FUNCTION afterReport
  RETURN BOOLEAN
IS
  l_request_id NUMBER;
BEGIN
  P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
  --IF G_DISTRIBUTION_LIST IS NOT NULL THEN
  IF G_REC_COUNT > 0 THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submitting : XML Publisher Report Bursting Program');
    l_request_id := FND_REQUEST.SUBMIT_REQUEST('XDO', 'XDOBURSTREP', NULL, NULL, FALSE, 'Y', P_CONC_REQUEST_ID, 'Y');
    Fnd_File.PUT_LINE(Fnd_File.LOG, 'Completed ');
    COMMIT;
  END IF;
  RETURN(TRUE);
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Unable to submit burst request ' || SQLERRM);
  --RAISE;
END afterReport;
END XX_AP_PENDSTROYMERCH_PKG;
/

SHOW ERROR;