SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY APPS.xx_ap_match_rate_rpt_pkg
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name      :  xx_ap_match_rate_rpt_pkg                                                          |
  -- |  RICE ID   :  E3523 AP Match Rate Dashboard                                            |
  -- |  Description:  Dash board Query are build using pipeline Function for performance          |
  -- |  Change Record:
  -- |  Rice Id:E3523
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         21-dec-2017   Priyam P       Initial version
  -- |  1.1         19-APR-2018   Digamber Somvanshi Code changed for DEFECT NAIT-37732
  ---|  1.2         24-May-18       Priyam Parmar   Code changed for Defect NAIT-29696
  ---|  1.3         10-JUN-18     Priyam Parmar     Code change for Performance tunning.
  ---|  1.4         19-JUN-18     M K Pramod Kumar  Code Fixes to handles scenarios with GL_Transfer_date.
  ---|  1.5         25-JUN-18     M K Pramod Kumar  Code Fixe to derive run time after all Child Programs of Transfer to GL program.
  -- +============================================================================================+
p_run_from_Date date;
p_run_to_Date date;
  
-- +======================================================================+
-- | Name        :  xx_ap_match_rate_rpt_pipe                               |
-- | Description :  Pipe Function to bring the data out to UI           |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_date_from 
---|                p_date_to
---|                p_po_type
---|                p_match_type
--- |               p_ou_name
-- |                                                                      |
-- | Returns     :  Match rate details to UI                                 |
-- |                                                                      |
-- +======================================================================+
FUNCTION xx_ap_match_rate_rpt_pipe(
    p_date_from  DATE ,
    p_date_to    DATE,
    p_po_type    varchar2,
    p_match_type VARCHAR2,
    p_ou_name    varchar2)
  RETURN xx_ap_match_rate_rpt_pkg.match_rate_db_ctt pipelined
IS
  CURSOR c_sum
  IS
    SELECT 1 ord,
      'First Pass' criteria,
      NVL(SUM(total_sys_match_cnt),0) total_sys_match_cnt,
      NVL(SUM(total_inv_count),0) total_inv_cnt
    FROM xx_ap_inv_match_sum_219
    WHERE 1            =1
    AND criteria       ='First Pass'
    AND process_date  >=p_date_from
    AND process_date  <=p_date_to
    AND ou_name        =NVL(p_ou_name,ou_name)
    AND (p_match_type IS NULL
    OR po_match_type  IN
      (SELECT regexp_substr(p_match_type,'[^,]+', 1, LEVEL)
      FROM dual
        CONNECT BY regexp_substr(p_match_type, '[^,]+', 1, LEVEL) IS NOT NULL
      ))
    AND (p_po_type IS NULL
    OR po_type     IN
      (SELECT target_value1
      FROM xx_fin_translatevalues tv,
        xx_fin_translatedefinition td
      WHERE td.translation_name = 'XX_AP_TR_MATCH_PO_TYPE'
      AND tv.translate_id       = td.translate_id
      AND tv.enabled_flag       = 'Y'
      AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
      AND tv.target_value2 IN
        (SELECT regexp_substr(p_po_type,'[^,]+', 1, LEVEL)
        FROM dual
          CONNECT BY regexp_substr(p_po_type, '[^,]+', 1, LEVEL) IS NOT NULL
        )
      ) )
    UNION
    SELECT 5 ord,
      'True Match' criteria,
      NVL(SUM(total_sys_match_cnt),0) total_sys_match_cnt,
      NVL(SUM(total_inv_count),0) total_inv_cnt
    FROM xx_ap_inv_match_sum_219
    WHERE 1            =1
    AND criteria       ='True Match'
    AND ou_name        =NVL(p_ou_name,ou_name)
    AND process_date  >=to_date(p_date_from)-120
    AND process_date  <=to_date(p_date_to)
    AND (p_match_type IS NULL
    OR po_match_type  IN
      (SELECT regexp_substr(p_match_type,'[^,]+', 1, LEVEL)
      FROM dual
        CONNECT BY regexp_substr(p_match_type, '[^,]+', 1, LEVEL) IS NOT NULL
      ))
    AND (p_po_type IS NULL
    OR po_type     IN
      (SELECT target_value1
      FROM xx_fin_translatevalues tv,
        xx_fin_translatedefinition td
      WHERE td.translation_name = 'XX_AP_TR_MATCH_PO_TYPE'
      AND tv.translate_id       = td.translate_id
      AND tv.enabled_flag       = 'Y'
      AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
      AND tv.target_value2 IN
        (SELECT regexp_substr(p_po_type,'[^,]+', 1, LEVEL)
        FROM dual
          CONNECT BY regexp_substr(p_po_type, '[^,]+', 1, LEVEL) IS NOT NULL
        )
      ) )
    UNION
    SELECT 2 ord,
      'All Finalized' criteria,
      NVL(SUM(total_sys_match_cnt),0) total_sys_match_cnt,
      NVL(SUM(total_inv_count),0) total_inv_cnt
    FROM xx_ap_inv_match_sum_219
    WHERE 1            =1
    AND criteria       ='All Finalized'
    AND ou_name        =NVL(p_ou_name,ou_name)
    AND process_date  >=p_date_from
    AND process_date  <=p_date_to
    AND (p_match_type IS NULL
    OR po_match_type  IN
      (SELECT regexp_substr(p_match_type,'[^,]+', 1, LEVEL)
      FROM dual
        CONNECT BY regexp_substr(p_match_type, '[^,]+', 1, LEVEL) IS NOT NULL
      ))
    AND (p_po_type IS NULL
    OR po_type     IN
      (SELECT target_value1
      FROM xx_fin_translatevalues tv,
        xx_fin_translatedefinition td
      WHERE td.translation_name = 'XX_AP_TR_MATCH_PO_TYPE'
      AND tv.translate_id       = td.translate_id
      AND tv.enabled_flag       = 'Y'
      AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
      AND tv.target_value2 IN
        (SELECT regexp_substr(p_po_type,'[^,]+', 1, LEVEL)
        FROM dual
          CONNECT BY regexp_substr(p_po_type, '[^,]+', 1, LEVEL) IS NOT NULL
        )
      ) )
    UNION
    SELECT 3 ord,
      'Payment Due' criteria,
      NVL(SUM(total_sys_match_cnt),0) total_sys_match_cnt,
      NVL(SUM(total_inv_count),0) total_inv_cnt
    FROM xx_ap_inv_match_sum_219
    WHERE 1            =1
    AND ou_name        =NVL(p_ou_name,ou_name)
    AND criteria       ='Payment Due'
    AND process_date  >= p_date_from
    AND process_date  <= p_date_to
    AND (p_match_type IS NULL
    OR po_match_type  IN
      (SELECT regexp_substr(p_match_type,'[^,]+', 1, LEVEL)
      FROM dual
        CONNECT BY regexp_substr(p_match_type, '[^,]+', 1, LEVEL) IS NOT NULL
      ))
    AND (p_po_type IS NULL
    OR po_type     IN
      (SELECT target_value1
      FROM xx_fin_translatevalues tv,
        xx_fin_translatedefinition td
      WHERE td.translation_name = 'XX_AP_TR_MATCH_PO_TYPE'
      AND tv.translate_id       = td.translate_id
      AND tv.enabled_flag       = 'Y'
      AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
      AND tv.target_value2 IN
        (SELECT regexp_substr(p_po_type,'[^,]+', 1, LEVEL)
        FROM dual
          CONNECT BY regexp_substr(p_po_type, '[^,]+', 1, LEVEL) IS NOT NULL
        )
      ) )
    UNION
    SELECT 4 ord,
      'Payment Due in 8 days' criteria,
      NVL(SUM(total_sys_match_cnt),0) total_sys_match_cnt,
      NVL(SUM(total_inv_count),0) total_inv_cnt
    FROM xx_ap_inv_match_sum_219
    WHERE 1            =1
    AND ou_name        =NVL(p_ou_name,ou_name)
    AND criteria       ='Payment Due in 8 days'
    AND process_date  >= to_date(p_date_from)+8
    AND process_date  <= to_date(p_date_to)  +8
    AND (p_match_type IS NULL
    OR po_match_type  IN
      (SELECT regexp_substr(p_match_type,'[^,]+', 1, LEVEL)
      FROM dual
        CONNECT BY regexp_substr(p_match_type, '[^,]+', 1, LEVEL) IS NOT NULL
      ))
    AND (p_po_type IS NULL
    OR po_type     IN
      (SELECT target_value1
      FROM xx_fin_translatevalues tv,
        xx_fin_translatedefinition td
      WHERE td.translation_name = 'XX_AP_TR_MATCH_PO_TYPE'
      AND tv.translate_id       = td.translate_id
      AND tv.enabled_flag       = 'Y'
      AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
      AND tv.target_value2 IN
        (SELECT regexp_substr(p_po_type,'[^,]+', 1, LEVEL)
        FROM dual
          CONNECT BY regexp_substr(p_po_type, '[^,]+', 1, LEVEL) IS NOT NULL
        )
      ) )
    ORDER BY ord ;
  TYPE match_rate_db_ctt
IS
  TABLE OF xx_ap_match_rate_rpt_pkg.match_rate_db INDEX BY pls_integer;
  l_match_rate_db match_rate_db_ctt;
  l_error_count NUMBER;
  ex_dml_errors EXCEPTION;
  pragma exception_init(ex_dml_errors, -24381);
  n              NUMBER := 0;
  v_sys_mat_cnt  NUMBER;
  v_match_rate   NUMBER;
  v_max_det_date DATE;
  l_days         NUMBER :=1;
BEGIN
  IF l_match_rate_db.count > 0 THEN
    l_match_rate_db.DELETE;
  end if;
 /* BEGIN
    SELECT MAX(run_date) INTO v_max_det_date FROM xx_ap_inv_match_detail_219;
  EXCEPTION
  WHEN OTHERS THEN
    v_max_det_date:=TRUNC(sysdate-1);
    l_days        :=1;
  END;
  ----Logic for Avg out the data when date range is given
  IF p_date_from IS NOT NULL AND p_date_to IS NOT NULL THEN
    IF p_date_to  > v_max_det_date THEN
      l_days     :=ROUND(to_date(v_max_det_date||' 23:59:59','DD-MON-RR HH24:MI:SS')-to_date(p_date_from||' 00:00:00','DD-MON-RR HH24:MI:SS'));
    ELSE
      l_days :=ROUND(to_date(p_date_to||' 23:59:59','DD-MON-RR HH24:MI:SS')-to_date(p_date_from||' 00:00:00','DD-MON-RR HH24:MI:SS'));
    END IF;
  ELSE
    l_days:=1;
  END IF;*/
  FOR i IN c_sum
  LOOP
    v_match_rate:=0;
    BEGIN
      IF i.total_inv_cnt <> 0 THEN
        v_match_rate     := NVL(ROUND(((i.total_sys_match_cnt*100)/i.total_inv_cnt),2),0);
      END IF;
      l_match_rate_db(n).run_date            :=SYSDATE-1;
      l_match_rate_db(n).criteria            :=i.criteria;
      l_match_rate_db(n).total_inv_cnt       :=i.total_inv_cnt;
      l_match_rate_db(n).total_sys_match_cnt :=i.total_sys_match_cnt;
      l_match_rate_db(n).match_rate          :=v_match_rate;
      n                                      := n+1;
    END;
  END LOOP;
  IF l_match_rate_db.count                  = 0 THEN
    l_match_rate_db(0).run_date            :=NULL;
    l_match_rate_db(0).criteria            :=NULL;
    l_match_rate_db(0).total_inv_cnt       :=NULL;
    l_match_rate_db(0).total_sys_match_cnt :=NULL;
    l_match_rate_db(0).match_rate          :=NULL;
  END IF;
  FOR i IN l_match_rate_db.FIRST .. l_match_rate_db.LAST
  LOOP
    pipe ROW ( l_match_rate_db(i) ) ;
  END LOOP;
  RETURN;
EXCEPTION
WHEN ex_dml_errors THEN
  l_error_count := SQL%bulk_exceptions.count;
  dbms_output.put_line('Number of failures: ' || l_error_count);
  FOR i IN 1 .. l_error_count
  LOOP
    dbms_output.put_line ( 'Error: ' || i || ' Array Index: ' || SQL%bulk_exceptions(i).error_index || ' Message: ' || sqlerrm(-SQL%bulk_exceptions(i).error_code) ) ;
  END LOOP;
END xx_ap_match_rate_rpt_pipe;
-- +======================================================================+
-- | Name        :  get_run_Start_end_Dates                               |
-- | Description :  Procedure to get from and to date based on Gl transfer program completion          |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_Date 
---|                p_from_Date
---|                p_to_Date
---|         
-- |                                                                      |
-- | Returns     : gl transfer from and to date                                |
-- |                                                                      |
-- +======================================================================+
PROCEDURE get_run_Start_end_Dates(
    p_Date IN DATE,
    p_from_Date OUT DATE,
    p_to_Date OUT DATE)
IS

CURSOR gl_transfer_rundate(p_run_date DATE)
IS
SELECT b.actual_start_date,b.actual_completion_Date,b.request_id
  FROM fnd_concurrent_requests b,
       fnd_concurrent_programs_vl a
 WHERE a.concurrent_program_name = 'XLAGLTRN'
   AND b.concurrent_program_id     =a.concurrent_program_id
   AND b.phase_code                ='C'
   AND b.requested_by                 =90102 
   AND TRUNC(b.actual_completion_Date) BETWEEN TRUNC(p_run_date) AND TRUNC(p_run_date)+1
   AND SUBSTR(b.argument6,1,10)=TO_CHAR(p_date,'YYYY/MM/DD')
   AND b.responsibility_id=52296
 ORDER BY request_id DESC;
	
CURSOR gl_transfer_rundate_child(p_request_id number )
IS
SELECT max(b.actual_completion_Date) actual_completion_Date
  FROM fnd_concurrent_requests b
 WHERE (parent_request_id=p_request_id or b.request_id=p_request_id);
 
TYPE gl_transfer_rundate_type IS TABLE OF gl_transfer_rundate%rowtype INDEX BY pls_integer;
  
gl_transfer_rundate_tb gl_transfer_rundate_type;

BEGIN
  p_from_Date:=NULL;
  p_to_Date  :=NULL;
  OPEN gl_transfer_rundate(p_Date);
  FETCH gl_transfer_rundate bulk collect INTO gl_transfer_rundate_tb;
  CLOSE gl_transfer_rundate;
  IF gl_transfer_rundate_tb.count=0 THEN
     p_to_Date:=p_Date;
     p_from_Date:=p_Date;
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception to derive GL Transfer date for the run date :'||p_date);
  ELSIF gl_transfer_rundate_tb.count=1 THEN
    FOR indx IN gl_transfer_rundate_tb.first..gl_transfer_rundate_tb.last
    LOOP
	  p_from_Date:=gl_transfer_rundate_tb(indx).actual_start_Date;
	  FOR rec IN gl_transfer_rundate_child(gl_transfer_rundate_tb(indx).request_id) LOOP
	    p_to_Date:=rec.actual_completion_Date+.025;
	  END LOOP;

    END LOOP;
  END IF;
EXCEPTION
  WHEN others THEN
    p_to_Date:=p_Date;
    p_from_Date:=p_Date;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'When others in get_run_start_end_dates  :'||SQLERRM);
END get_run_Start_end_Dates;

-- +======================================================================+
-- | Name        :  xx_ap_upd_inv_detail_firstpass                               |
-- | Description :  Procedure to update validation date for First pass invoices into   xx_ap_inv_match_detail_219 table        |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_Date 
---|                                                                      |
-- | Returns     :                                |
-- |                                                                      |
-- +======================================================================+

PROCEDURE xx_ap_upd_inv_detail_firstpass(
    p_date IN DATE )
IS
  CURSOR c_inv_first_pass
  IS
    SELECT rowid drowid,
      invoice_id
    FROM xx_ap_inv_match_detail_219 a
    WHERE a.run_date     =p_date
    AND a.first_pass_flag='Y'
    AND EXISTS
      (SELECT 'x'
      FROM xla_events xev,
        xla_ae_headers xah,
        xla_transaction_entities xte
      WHERE xte.source_id_int_1=a.invoice_id
      AND xte.entity_code      = 'AP_INVOICES'
      AND xte.application_id   = 200
      AND xev.entity_id        =xte.entity_id
      AND xev.application_id   =xte.application_id
      AND xev.event_type_code LIKE '%VALIDATED%'
      AND xev.process_status_code = 'P'
      AND xev.event_status_code   ='P'
      AND xah.event_id            =xev.event_id
      AND xah.entity_id           =xev.entity_id
      AND xah.application_id      =xev.application_id
      AND xah.ledger_id           =xte.ledger_id+0
      AND xah.gl_transfer_date BETWEEN   p_run_from_Date and p_run_to_Date  
	 /* TO_DATE(TO_CHAR( p_run_from_Date)
        ||' 00:00:00','DD-MON-RR HH24:MI:SS')
      AND to_date(TO_CHAR(p_run_to_Date)
        ||' 23:59:59','DD-MON-RR HH24:MI:SS') */
      );
  v_validation_date       DATE;
  v_validation_flag       VARCHAR2(5);
  l_rel_by                VARCHAR2(100);
  l_rel_date              DATE;
  l_HOLD_LAST_UPDATE_DATE DATE;
  l_hold_count            NUMBER;
  l_HOLD_LAST_UPDATED_BY  VARCHAR2(64);
BEGIN
  FOR i IN c_inv_first_pass
  LOOP
    UPDATE xx_ap_inv_match_detail_219
    SET validation_flag='Y',
      validation_date  =p_date
    WHERE rowid        =i.drowid;
    COMMIT;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,SQLCODE||sqlerrm);
  v_validation_date:=NULL;
END xx_ap_upd_inv_detail_firstpass;

-- +======================================================================+
-- | Name        :  xx_ap_upd_inv_detail_truematch                               |
-- | Description :  Procedure to update validation date for true match into   xx_ap_inv_match_detail_219 table        |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_Date 
---|                                                                      |
-- | Returns     :                                |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_ap_upd_inv_detail_truematch(
    p_date IN DATE )
IS
  CURSOR c_inv_true_match
  IS
    SELECT a.rowid drowid,
      a.invoice_id
    FROM xx_ap_inv_match_detail_219 a
    WHERE a.run_date     =p_date
    AND a.true_match_flag='Y';
  v_validation_date       DATE;
  v_validation_flag       VARCHAR2(5);
  l_rel_by                VARCHAR2(100);
  l_rel_date              DATE;
  l_HOLD_LAST_UPDATE_DATE DATE;
  l_hold_count            NUMBER;
  l_HOLD_LAST_UPDATED_BY  VARCHAR2(64);
BEGIN
  FOR i IN c_inv_true_match
  LOOP
    BEGIN
      SELECT MIN(xah.gl_transfer_date)
      INTO v_validation_date
      FROM xla_events xev,
        xla_ae_headers xah,
        xla_transaction_entities xte
      WHERE 1                =1
      AND xte.source_id_int_1=i.invoice_id
      AND xte.entity_code    = 'AP_INVOICES'
      AND xte.application_id = 200
      AND xev.entity_id      =xte.entity_id
      AND xev.application_id =xte.application_id
      AND xev.event_type_code LIKE '%VALIDATED%'
      AND xev.process_status_code = 'P'
      AND xev.event_status_code   ='P'
      AND xah.event_id            =xev.event_id
      AND xah.entity_id           =xev.entity_id
      AND xah.application_id      =xev.application_id
      AND xah.ledger_id           =xte.ledger_id+0
      AND xah.gl_transfer_date BETWEEN  
      to_date(TO_CHAR( p_run_from_Date)
        ||' 00:00:00','DD-MON-RR HH24:MI:SS')-120
      AND TO_DATE(TO_CHAR(p_run_to_Date )
        ||' 23:59:59','DD-MON-RR HH24:MI:SS') ;
      UPDATE xx_ap_inv_match_detail_219
      SET validation_flag='Y',
        validation_date  =v_validation_date
      WHERE rowid        =i.drowid;
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,SQLCODE||sqlerrm);
END xx_ap_upd_inv_detail_truematch;
-- +======================================================================+
-- | Name        :  xx_ap_upd_matched_by_firstpass                               |
-- | Description :  Procedure to update matched by for First Pass into   xx_ap_inv_match_detail_219 table        |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_Date 
---|                                                                      |
-- | Returns     :                                |
-- |                                                                      |
-- +======================================================================+

PROCEDURE xx_ap_upd_matched_by_firstpass(
    p_date IN DATE)
IS
  CURSOR c_inv_first_pass_val
  IS
    SELECT invoice_id,
      inv_creation_date creation_date,
      invoice_num,
      release_date,
      vendor_id,
      vendor_site_id,
      match_criteria,
      validation_flag,
      invoice_source
    FROM xx_ap_inv_match_detail_219
    WHERE first_pass_flag='Y'
    AND validation_flag  ='Y'
    AND run_date         =p_date;
  l_svc_esp_vps           NUMBER;
  l_svc_esp_fin           NUMBER;
  l_appsmgr               NUMBER;
  l_rel_by                VARCHAR2(100);
  l_rel_date              DATE;
  l_HOLD_LAST_UPDATE_DATE DATE;
  l_hold_count            NUMBER;
  l_HOLD_LAST_UPDATED_BY  VARCHAR2(64);
BEGIN
  BEGIN
    SELECT MAX(DECODE(u.user_name,'SVC_ESP_VPS',u.user_id,-1)),
      MAX(DECODE(u.user_name,'SVC_ESP_FIN',u.user_id,     -1)),
      MAX(DECODE(u.user_name,'APPSMGR',u.user_id,         -1))
    INTO l_svc_esp_vps,
      l_svc_esp_fin,
      l_appsmgr
    FROM fnd_user u
    WHERE u.user_name IN ('SVC_ESP_VPS', 'SVC_ESP_FIN','APPSMGR') ;
  EXCEPTION
  WHEN OTHERS THEN
    l_svc_esp_vps:= 3839857;
    l_svc_esp_fin:=90102;
    l_appsmgr    := 5;
    fnd_file.put_line(fnd_file.LOG,'Inside Exception - USER');
  END;
  BEGIN
    FOR i IN c_inv_first_pass_val
    LOOP
      xx_ap_match_rate_rpt_pkg.xx_ap_release_by (p_invoice_id => i.invoice_id, p_invoice_creation_date=>i.creation_date, p_invoice_num =>i.invoice_num, p_vendor_id =>i.vendor_id, p_vendor_site_id => i.vendor_site_id, p_match_criteria=> i.match_criteria, p_validation_flag=> i.validation_flag, p_appsmgr=> l_appsmgr, p_svc_esp_fin => l_svc_esp_fin, p_svc_esp_vps => l_svc_esp_vps, p_rel_by=> l_rel_by, p_rel_date=> l_rel_date, p_hold_last_update_date=> l_hold_last_update_date , p_hold_last_updated_by => l_hold_last_updated_by, p_hold_count=> l_hold_count );
      UPDATE xx_ap_inv_match_detail_219
      SET matched_by         =l_rel_by,
        hold_count           =l_hold_count,
        hold_last_update_date=l_hold_last_update_date,
        hold_last_updated_by =l_hold_last_updated_by
      WHERE invoice_id       =i.invoice_id
      AND run_date           =p_date
      AND first_pass_flag    ='Y';
      COMMIT;
    END LOOP;
  END;
END xx_ap_upd_matched_by_firstpass;

-- +======================================================================+
-- | Name        :  xx_ap_upd_matched_by_truematch                               |
-- | Description :  Procedure to update matched by for True Match into   xx_ap_inv_match_detail_219 table        |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_Date 
---|                                                                      |
-- | Returns     :                                |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_ap_upd_matched_by_truematch(
    p_date IN DATE)
IS
  CURSOR c_inv_true_match_val
  IS
    SELECT invoice_id,
      inv_creation_date creation_date,
      invoice_num,
      release_date,
      vendor_id,
      vendor_site_id,
      match_criteria,
      validation_flag
    FROM xx_ap_inv_match_detail_219
    WHERE true_match_flag='Y'
    AND validation_flag  ='Y'
    AND run_date         =p_date;
  l_svc_esp_vps           NUMBER;
  l_svc_esp_fin           NUMBER;
  l_appsmgr               NUMBER;
  l_rel_by                VARCHAR2(100);
  l_rel_date              DATE;
  l_HOLD_LAST_UPDATE_DATE DATE;
  l_hold_count            NUMBER;
  l_HOLD_LAST_UPDATED_BY  VARCHAR2(64);
BEGIN
  BEGIN
    SELECT MAX(DECODE(u.user_name,'SVC_ESP_VPS',u.user_id,-1)),
      MAX(DECODE(u.user_name,'SVC_ESP_FIN',u.user_id,     -1)),
      MAX(DECODE(u.user_name,'APPSMGR',u.user_id,         -1))
    INTO l_svc_esp_vps,
      l_svc_esp_fin,
      l_appsmgr
    FROM fnd_user u
    WHERE u.user_name IN ('SVC_ESP_VPS', 'SVC_ESP_FIN','APPSMGR') ;
  EXCEPTION
  WHEN OTHERS THEN
    l_svc_esp_vps:= 3839857;
    l_svc_esp_fin:=90102;
    l_appsmgr    := 5;
    fnd_file.put_line(fnd_file.LOG,'Inside Exception - USER');
  END;
  BEGIN
    FOR i IN c_inv_true_match_val
    LOOP
      xx_ap_match_rate_rpt_pkg.xx_ap_release_by (p_invoice_id => i.invoice_id, p_invoice_creation_date=>i.creation_date, p_invoice_num =>i.invoice_num, p_vendor_id =>i.vendor_id, p_vendor_site_id => i.vendor_site_id, p_match_criteria=> i.match_criteria, p_validation_flag=> i.validation_flag, p_appsmgr=> l_appsmgr, p_svc_esp_fin => l_svc_esp_fin, p_svc_esp_vps => l_svc_esp_vps, p_rel_by=> l_rel_by, p_rel_date=> l_rel_date, p_hold_last_update_date=> l_hold_last_update_date , p_hold_last_updated_by => l_hold_last_updated_by, p_hold_count=> l_hold_count );
      UPDATE xx_ap_inv_match_detail_219
      SET matched_by         =l_rel_by,
        hold_count           =l_hold_count,
        hold_last_update_date=l_hold_last_update_date,
        hold_last_updated_by =l_hold_last_updated_by
      WHERE invoice_id       =i.invoice_id
      AND run_date           =p_date
      AND true_match_flag    ='Y';
      COMMIT;
    END LOOP;
  END;
END xx_ap_upd_matched_by_truematch;

-- +======================================================================+
-- | Name        :  xx_ap_insert_inv_match_detail                               |
-- | Description :  Procedure to insert data into   xx_ap_inv_match_detail_219 table        |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_Date 
---|                                                                      |
-- | Returns     :                                |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_ap_insert_inv_match_detail(
    errbuf OUT VARCHAR2,
    retcode OUT VARCHAR2,
    p_date DATE)
IS
  CURSOR c_first_pass_nedi
  IS
    SELECT a.invoice_id,
      a.invoice_date,
      a.invoice_amount,
      a.vendor_id,
      a.vendor_site_id,
      a.source invoice_source,
      a.invoice_num invoice_num,
      a.created_by,
      b.vendor_site_code supplier_site,
      c.segment1 suppliernum,
      A.creation_date creation_date,
      A.last_update_date ,
      A.last_updated_by,
      A.gl_date gl_date,
      NVL(py.discount_date,py.due_date) pay_due_date,
      a.creation_date release_date,
      (SELECT DECODE(receipt_required_flag,'Y','3-WAY','N','2-WAY')
      FROM po_line_locations_all
      WHERE po_header_id =NVL(A.po_header_id,A.quick_po_header_id)
      AND ROWNUM         <2
      ) match_type,
    c.vendor_name vendor_name,
    NULL validation_date,
    ph.attribute_category po_type,
    hr.name ou_name,
    'N' Validation_flag,
    'INV_NEDI' criteria
  FROM hr_operating_units hr,
    po_headers_all ph,
    ap_suppliers c,
    ap_supplier_sites_all b,
    ap_payment_schedules_all py,
    ap_invoices_all A
  WHERE A.creation_date BETWEEN TO_DATE(TO_CHAR(p_date)
    ||' 00:00:00','DD-MON-RR HH24:MI:SS')
  AND TO_DATE(TO_CHAR(p_date)
    ||' 23:59:59','DD-MON-RR HH24:MI:SS')
  AND a.source                 <> 'US_OD_TRADE_EDI'
  AND A.invoice_type_lookup_code='STANDARD'
  AND A.invoice_num NOT LIKE '%ODDBUIA%'
  AND a.cancelled_date  IS NULL
  AND b.vendor_site_id   =A.vendor_site_id
  AND py.invoice_id      =A.invoice_id
  AND c.vendor_id        =b.vendor_id
  AND ph.po_header_id    =NVL(a.po_header_id,a.quick_po_header_id)
  AND hr.organization_id = a.org_id
  AND NOT EXISTS
    (SELECT 1
    FROM ap_invoices_all aia
    WHERE aia.invoice_num LIKE A.INVOICE_NUM
      ||'ODDBUIA%'
    AND aia.vendor_id      =a.vendor_id
    AND aia.vendor_site_id =a.vendor_site_id
    )----added to exclude recreated invoice
  AND EXISTS
    (SELECT 'x'
    FROM xx_fin_translatevalues tv,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       = 'Y'
    AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
    AND tv.target_value1 = b.attribute8
      ||''
    )
  AND EXISTS
    (SELECT 'x'
    FROM xx_fin_translatevalues tv ,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TR_MATCH_INVOICES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       ='Y'
    AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
    AND tv.target_value1=a.source
    );
  CURSOR c_first_pass_edi
  IS
    SELECT a.invoice_id,
      a.invoice_date,
      a.invoice_amount,
      a.vendor_id,
      a.vendor_site_id,
      a.source invoice_source,
      a.invoice_num invoice_num,
      a.created_by,
      b.vendor_site_code supplier_site,
      c.segment1 suppliernum,
      A.creation_date creation_date,
      A.last_update_date ,
      A.last_updated_by,
      A.gl_date gl_date,
      NVL(py.discount_date,py.due_date) pay_due_date,
      to_date(a.attribute4,'DD-MON-YYYY') release_date,
      (SELECT DECODE(receipt_required_flag,'Y','3-WAY','N','2-WAY')
      FROM po_line_locations_all
      WHERE po_header_id =NVL(A.po_header_id,A.quick_po_header_id)
      AND ROWNUM         <2
      ) match_type,
    c.vendor_name vendor_name,
    NULL validation_date,
    ph.attribute_category po_type,
    hr.name ou_name,
    'N' Validation_flag,
    'INV_EDI' criteria
  FROM hr_operating_units hr,
    po_headers_all ph,
    ap_suppliers c,
    ap_supplier_sites_all b,
    ap_payment_schedules_all py,
    ap_invoices_all a
  WHERE 1=1
  AND to_date(A.attribute4,'DD-MON-YYYY') BETWEEN TO_DATE(p_date,'DD-MON-RRRR') AND to_date(p_date,'DD-MON-RRRR')
  AND a.source                  ='US_OD_TRADE_EDI'
  AND A.invoice_type_lookup_code='STANDARD'
  AND A.invoice_num NOT LIKE '%ODDBUIA%'
  AND a.cancelled_date  IS NULL
  AND b.vendor_site_id   =A.vendor_site_id+0
  AND py.invoice_id      =A.invoice_id    +0
  AND c.vendor_id        =b.vendor_id
  AND ph.po_header_id    =NVL(a.po_header_id,a.quick_po_header_id)
  AND hr.organization_id = a.org_id
  AND EXISTS
    (SELECT 'x'
    FROM xx_fin_translatevalues tv,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       = 'Y'
    AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
    AND tv.target_value1 = b.attribute8
      ||''
    )
  AND EXISTS
    (SELECT 'x'
    FROM xx_fin_translatevalues tv ,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TR_MATCH_INVOICES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       ='Y'
    AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
    AND tv.target_value1=a.source
    );
  CURSOR c_all_finalized
  IS
    SELECT
      /*+ LEADING(xah) */
      a.invoice_id,
      a.invoice_date,
      a.invoice_amount,
      a.vendor_id,
      a.vendor_site_id,
      a.source invoice_source,
      a.invoice_num invoice_num,
      a.created_by,
      b.vendor_site_code supplier_site,
      c.segment1 suppliernum,
      A.creation_date creation_date,
      A.last_update_date ,
      A.last_updated_by,
      A.gl_date gl_date,
      NVL(py.discount_date,py.due_date) pay_due_date,
      DECODE(SOURCE,'US_OD_TRADE_EDI',to_date(a.attribute4,'DD-MON-YYYY'),a.creation_date) release_date,
      (SELECT DECODE(receipt_required_flag,'Y','3-WAY','N','2-WAY')
      FROM po_line_locations_all
      WHERE po_header_id =NVL(A.po_header_id,A.quick_po_header_id)
      AND ROWNUM         <2
      ) match_type,
    c.vendor_name vendor_name,
    xah.gl_transfer_date validation_date,
    ph.attribute_category po_type,
    hr.name ou_name,
    'Y' Validation_flag,
    'INV_DT' criteria
  FROM hr_operating_units hr,
    po_headers_all ph,
    ap_payment_schedules_all py,
    ap_suppliers c,
    ap_supplier_sites_all b,
    ap_invoices_all A,
    xla_transaction_entities xte ,
    xla_events xev,
    xla_ae_headers xah
  WHERE 1 =1
  /*AND xah.gl_transfer_date BETWEEN TO_DATE(TO_CHAR( p_run_from_Date )
    ||' 00:00:00','DD-MON-RR HH24:MI:SS')
  AND to_date(TO_CHAR(p_run_to_Date)
    ||' 23:59:59','DD-MON-RR HH24:MI:SS') */	
	AND xah.gl_transfer_date BETWEEN  p_run_from_Date and p_run_to_Date	
  AND xah.application_id = 200
  AND xev.event_id       = xah.event_id
  AND xev.entity_id      =xah.entity_id
  AND xev.application_id = xah.application_id
  AND xev.event_type_code LIKE '%VALIDATED%'
  AND xev.process_status_code   = 'P'
  AND xev.event_status_code     ='P'
  AND xte.entity_id             = xev.entity_id
  AND xte.entity_code           = 'AP_INVOICES'
  AND xte.application_id        = xev.application_id
  AND xte.ledger_id+0           = xah.ledger_id
  AND A.invoice_id              =xte.source_id_int_1
  AND A.invoice_type_lookup_code='STANDARD'
  AND A.invoice_num NOT LIKE '%ODDBUIA%'
  AND a.cancelled_date  IS NULL
  AND b.vendor_site_id   =A.vendor_site_id
  AND py.invoice_id      =A.invoice_id
  AND c.vendor_id        =b.vendor_id
  AND ph.po_header_id    =NVL(a.po_header_id,a.quick_po_header_id)
  AND hr.organization_id = a.org_id
  AND EXISTS
    (SELECT 'x'
    FROM xx_fin_translatevalues tv,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       = 'Y'
    AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
    AND tv.target_value1 = b.attribute8
      ||''
    )
  AND EXISTS
    (SELECT 'x'
    FROM xx_fin_translatevalues tv ,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TR_MATCH_INVOICES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       ='Y'
    AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
    AND tv.target_value1=a.source
    )
  AND NOT EXISTS
    (SELECT 1
    FROM xx_ap_inv_match_detail_219 b
    WHERE b.invoice_id    =a.invoice_id
    AND match_criteria    ='INV_DT'
    AND ALL_FINALIZED_FLAG='Y'
    );
  CURSOR c_true_match_nedi
  IS
    SELECT a.invoice_id,
      a.invoice_date,
      a.invoice_amount,
      a.vendor_id,
      a.vendor_site_id,
      a.source invoice_source,
      a.invoice_num invoice_num,
      a.created_by,
      b.vendor_site_code supplier_site,
      c.segment1 suppliernum,
      A.creation_date creation_date,
      A.last_update_date ,
      A.last_updated_by,
      A.gl_date gl_date,
      NVL(py.discount_date,py.due_date) pay_due_date,
      a.creation_date release_date,
      (SELECT DECODE(receipt_required_flag,'Y','3-WAY','N','2-WAY')
      FROM po_line_locations_all
      WHERE po_header_id =NVL(A.po_header_id,A.quick_po_header_id)
      AND ROWNUM         <2
      ) match_type,
    c.vendor_name vendor_name,
    NULL validation_date,
    ph.attribute_category po_type,
    hr.name ou_name,
    'N' validation_flag,
    'INV_TMNEDI' criteria
  FROM hr_operating_units hr,
    po_headers_all ph,
    ap_suppliers c,
    ap_supplier_sites_all b,
    ap_payment_schedules_all py,
    ap_invoices_all a
  WHERE a.creation_date BETWEEN to_date(TO_CHAR(p_date)
    ||' 00:00:00','DD-MON-RR HH24:MI:SS')-120
  AND TO_DATE(TO_CHAR(p_date)
    ||' 23:59:59','DD-MON-RR HH24:MI:SS')-120
  AND A.invoice_type_lookup_code='STANDARD'
  AND a.source                 <> 'US_OD_TRADE_EDI'
  AND A.invoice_num NOT LIKE '%ODDBUIA%'
  AND a.cancelled_date  IS NULL
  AND b.vendor_site_id   =A.vendor_site_id
  AND py.invoice_id      =A.invoice_id
  AND c.vendor_id        =b.vendor_id
  AND ph.po_header_id    =NVL(a.po_header_id,a.quick_po_header_id)
  AND hr.organization_id = a.org_id
  AND NOT EXISTS
    (SELECT 1
    FROM ap_invoices_all aia
    WHERE aia.invoice_num LIKE A.INVOICE_NUM
      ||'ODDBUIA%'
    AND aia.vendor_id      =a.vendor_id
    AND aia.vendor_site_id =a.vendor_site_id
    )----added to exclude recreated invoice
  AND EXISTS
    (SELECT 'x'
    FROM xx_fin_translatevalues tv,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       = 'Y'
    AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
    AND tv.target_value1 = b.attribute8
      ||''
    )
  AND EXISTS
    (SELECT 'x'
    FROM xx_fin_translatevalues tv ,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TR_MATCH_INVOICES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       ='Y'
    AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
    AND tv.target_value1=a.source
    );
  CURSOR c_true_match_edi
  IS
    SELECT a.invoice_id,
      a.invoice_date,
      a.invoice_amount,
      a.vendor_id,
      a.vendor_site_id,
      a.source invoice_source,
      a.invoice_num invoice_num,
      a.created_by,
      b.vendor_site_code supplier_site,
      c.segment1 suppliernum,
      A.creation_date creation_date,
      A.last_update_date ,
      A.last_updated_by,
      A.gl_date gl_date,
      NVL(py.discount_date,py.due_date) pay_due_date,
      to_date(a.attribute4,'DD-MON-YYYY') release_date,
      (SELECT DECODE(receipt_required_flag,'Y','3-WAY','N','2-WAY')
      FROM po_line_locations_all
      WHERE po_header_id =NVL(A.po_header_id,A.quick_po_header_id)
      AND ROWNUM         <2
      ) match_type,
    c.vendor_name vendor_name,
    NULL validation_date,
    ph.attribute_category po_type,
    hr.name ou_name,
    'N' validation_flag,
    'INV_TMEDI' criteria
  FROM hr_operating_units hr,
    po_headers_all ph,
    ap_payment_schedules_all py,
    ap_suppliers c,
    ap_supplier_sites_all b,
    ap_invoices_all A
  WHERE 1 =1
  AND to_date(A.attribute4,'DD-MON-YYYY') BETWEEN TO_DATE(p_date,'DD-MON-RRRR')-120 AND to_date(p_date,'DD-MON-RRRR')-120
  AND a.source                   ='US_OD_TRADE_EDI'
  AND A.invoice_type_lookup_code ='STANDARD'
  AND A.invoice_num NOT LIKE '%ODDBUIA%'
  AND a.cancelled_date  IS NULL
  AND b.vendor_site_id   =A.vendor_site_id+0
  AND py.invoice_id      =A.invoice_id    +0
  AND c.vendor_id        =b.vendor_id
  AND ph.po_header_id    =NVL(a.po_header_id,a.quick_po_header_id)
  AND hr.organization_id = a.org_id
  AND EXISTS
    (SELECT 'x'
    FROM xx_fin_translatevalues tv,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       = 'Y'
    AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
    AND tv.target_value1 = b.attribute8
      ||''
    )
  AND EXISTS
    (SELECT 'x'
    FROM xx_fin_translatevalues tv ,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TR_MATCH_INVOICES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       ='Y'
    AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
    AND tv.target_value1=a.source
    ) ;
  CURSOR c_payment_due
  IS
    SELECT
      /*+ LEADING(p) */
      a.invoice_id,
      a.invoice_date,
      a.invoice_amount,
      a.vendor_id,
      a.vendor_site_id,
      a.source invoice_source,
      a.invoice_num invoice_num,
      a.created_by,
      b.vendor_site_code supplier_site,
      c.segment1 suppliernum,
      A.creation_date creation_date,
      A.last_update_date,
      A.last_updated_by,
      a.gl_date gl_date,
      NVL(p.discount_date,p.due_date) pay_due_date,
      DECODE(SOURCE,'US_OD_TRADE_EDI',to_date(a.attribute4,'DD-MON-YYYY'),a.creation_date) release_date,
      (SELECT DECODE(receipt_required_flag,'Y','3-WAY','N','2-WAY')
      FROM po_line_locations_all
      WHERE po_header_id =NVL(A.po_header_id,A.quick_po_header_id)
      AND ROWNUM         <2
      ) match_type,
    c.vendor_name vendor_name,
    xah.gl_transfer_date validation_date,
    ph.attribute_category po_type,
    hr.name ou_name,
    'Y' Validation_flag,
    'PAY_DT' criteria
  FROM hr_operating_units hr,
    po_headers_all ph,
    xla_transaction_entities xte ,
    xla_events xev,
    xla_ae_headers xah,
    ap_suppliers c,
    ap_supplier_sites_all b,
    ap_invoices_all A,
    ap_payment_schedules_all p
  WHERE 1=1
  AND NVL(p.discount_date,p.due_date) BETWEEN to_date(p_date,'DD-MON-RRRR') AND to_date(p_date,'DD-MON-RRRR')
  AND p.payment_method_code    IN ('EFT', 'CHECK')
  AND a.invoice_id              =p.invoice_id
  AND A.invoice_type_lookup_code='STANDARD'
  AND A.invoice_num NOT LIKE '%ODDBUIA%'
  AND a.cancelled_date  IS NULL
  AND b.vendor_site_id   =A.vendor_site_id
  AND c.vendor_id        =b.vendor_id
  AND ph.po_header_id    =NVL(a.po_header_id,a.quick_po_header_id)
  AND hr.organization_id = a.org_id
  AND EXISTS
    (SELECT 'x'
    FROM xx_fin_translatevalues tv,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       = 'Y'
    AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
    AND tv.target_value1 = b.attribute8
      ||''
    )
  AND EXISTS
    (SELECT 'x'
    FROM xx_fin_translatevalues tv ,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TR_MATCH_INVOICES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       ='Y'
    AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
    AND tv.target_value1 =A.SOURCE
    )
  AND xte.source_id_int_1 = A.invoice_id
  AND xte.application_id  = 200
  AND xte.entity_code     = 'AP_INVOICES'
  AND xev.application_id  = 200
  AND xev.entity_id       = xte.entity_id
  AND xev.event_type_code LIKE '%VALIDATED%'
  AND xev.process_status_code = 'P'
  AND xah.ledger_id           = xte.ledger_id
  AND xah.event_id            = xev.event_id
  AND xah.application_id      = 200
  AND xah.gl_transfer_date   <=p_run_to_Date;
  CURSOR c_pay_due_8days
  IS
    SELECT
      /*+ LEADING(p) */
      a.invoice_id,
      a.invoice_date,
      a.invoice_amount,
      a.vendor_id,
      a.vendor_site_id,
      a.source invoice_source,
      a.invoice_num invoice_num,
      a.created_by,
      b.vendor_site_code supplier_site,
      c.segment1 suppliernum,
      A.creation_date creation_date,
      A.last_update_date,
      A.last_updated_by,
      a.gl_date gl_date,
      NVL(p.discount_date,p.due_date) pay_due_date,
      DECODE(SOURCE,'US_OD_TRADE_EDI',to_date(a.attribute4,'DD-MON-YYYY'),a.creation_date) release_date,
      (SELECT DECODE(receipt_required_flag,'Y','3-WAY','N','2-WAY')
      FROM po_line_locations_all
      WHERE po_header_id =NVL(A.po_header_id,A.quick_po_header_id)
      AND ROWNUM         <2
      ) match_type,
    c.vendor_name vendor_name,
    xah.gl_transfer_date validation_date,
    ph.attribute_category po_type,
    hr.name ou_name,
    'Y' Validation_flag,
    'PAY_DT_8' criteria
  FROM hr_operating_units hr,
    po_headers_all ph,
    xla_transaction_entities xte ,
    xla_events xev,
    xla_ae_headers xah,
    ap_suppliers c,
    ap_supplier_sites_all b,
    ap_invoices_all a,
    ap_payment_schedules_all p
  WHERE 1 =1
  AND NVL(p.discount_date,p.due_date) BETWEEN to_date(p_date,'DD-MON-RRRR')+8 AND to_date(p_date,'DD-MON-RRRR')+8
  AND p.payment_method_code                                                  IN ('EFT', 'CHECK')
  AND p.payment_method_code                                                  IN ('EFT', 'CHECK')
  AND a.invoice_id              =p.invoice_id
  AND A.invoice_type_lookup_code='STANDARD'
  AND A.invoice_num NOT LIKE '%ODDBUIA%'
  AND a.cancelled_date  IS NULL
  AND b.vendor_site_id   =A.vendor_site_id
  AND c.vendor_id        =b.vendor_id
  AND ph.po_header_id    =NVL(a.po_header_id,a.quick_po_header_id)
  AND hr.organization_id = a.org_id
  AND EXISTS
    (SELECT 'x'
    FROM xx_fin_translatevalues tv,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       = 'Y'
    AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
    AND tv.target_value1 = b.attribute8
      ||''
    )
  AND EXISTS
    (SELECT 'x'
    FROM xx_fin_translatevalues tv ,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TR_MATCH_INVOICES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       ='Y'
    AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,SYSDATE)
    AND tv.target_value1 =A.SOURCE
    )
  AND xte.source_id_int_1 = A.invoice_id
  AND xte.application_id  = 200
  AND xte.entity_code     = 'AP_INVOICES'
  AND xev.application_id  = 200
  AND xev.entity_id       = xte.entity_id
  AND xev.event_type_code LIKE '%VALIDATED%'
  AND xev.process_status_code = 'P'
  AND xah.ledger_id           = xte.ledger_id
  AND xah.event_id            = xev.event_id
  AND xah.application_id      = 200
  AND xah.gl_transfer_date   <=p_run_to_Date;
  l_match_criteria        VARCHAR2(500);
  l_record_creation_date  DATE;
  l_first_pass_flag       VARCHAR2(1);
  l_true_match_flag       VARCHAR2(1);
  l_all_finalized_flag    VARCHAR2(1);
  l_payment_due_tdy_flag  VARCHAR2(1);
  l_due_8_days_flag       VARCHAR2(1);
  v_daily_count           NUMBER;
  v_daily_count_fp        NUMBER;
  v_daily_count_tm        NUMBER;
  v_hold_date             DATE;
  l_svc_esp_vps           NUMBER;
  l_svc_esp_fin           NUMBER;
  l_appsmgr               NUMBER;
  l_rel_by                VARCHAR2(100);
  l_rel_date              DATE;
  l_HOLD_LAST_UPDATE_DATE DATE;
  l_hold_count            NUMBER;
  l_hold_last_updated_by  VARCHAR2(64);
  v_sum_cnt               NUMBER;
  l_rec_cnt               NUMBER:=0;

BEGIN
  xla_security_pkg.set_security_context(602);
  l_record_creation_date:=TRUNC(p_date);

  get_run_Start_end_Dates(p_date,p_run_from_Date,p_run_to_Date);


  SELECT COUNT(1)
  INTO v_sum_cnt
  FROM xx_ap_inv_match_sum_219
  WHERE run_date=l_record_creation_date;
  IF v_sum_cnt  > 0 THEN
    fnd_file.put_line(fnd_file.log,'Records already processed for run_date '||l_record_creation_date);
    retcode :=2;
  ELSE
    BEGIN
      SELECT MAX(DECODE(u.user_name,'SVC_ESP_VPS',u.user_id,-1)),
        MAX(DECODE(u.user_name,'SVC_ESP_FIN',u.user_id,     -1)),
        MAX(DECODE(u.user_name,'APPSMGR',u.user_id,         -1))
      INTO l_svc_esp_vps,
        l_svc_esp_fin,
        l_appsmgr
      FROM fnd_user u
      WHERE u.user_name IN ('SVC_ESP_VPS', 'SVC_ESP_FIN','APPSMGR') ;
    EXCEPTION
    WHEN OTHERS THEN
      l_svc_esp_vps:= 3839857;
      l_svc_esp_fin:=90102;
      l_appsmgr    := 5;
      fnd_file.put_line(fnd_file.LOG,'Inside Exception - USER');
    END;
    FOR i IN c_first_pass_nedi
    LOOP
      l_rec_cnt:=l_rec_cnt+1;
      BEGIN
        L_MATCH_CRITERIA       :=NULL;
        l_first_pass_flag      :='N';
        l_true_match_flag      :='N';
        l_all_finalized_flag   :='N';
        l_payment_due_tdy_flag :='N';
        l_due_8_days_flag      :='N';
        l_first_pass_flag      :='Y';
        INSERT
        INTO xx_ap_inv_match_detail_219
          (
            invoice_id ,
            suppliernum,
            supplier_site ,
            inv_creation_date ,
            gl_date,
            release_date,
            validation_date,
            po_match_type ,
            po_type ,
            pay_due_date,
            matched_by,
            run_date,
            match_criteria,
            first_pass_flag ,
            true_match_flag ,
            all_finalized_flag ,
            payment_due_tdy_flag ,
            due_8_days_flag,
            ou_name,
            invoice_source,
            invoice_num ,
            CREATED_BY,
            LAST_UPDATE_DATE,
            LAST_UPDATED_BY,
            validation_flag,
            hold_count,
            HOLD_LAST_UPDATE_DATE,
            HOLD_LAST_UPDATED_BY,
            vendor_id,
            vendor_site_id,
            invoice_date,
            invoice_amount,
            vendor_name
          )
          VALUES
          (
            i.invoice_id ,
            i.suppliernum,
            i.supplier_site ,
            i.creation_date ,
            i.gl_date,
            i.release_date,
            NULL,---DECODE( l_rel_by,'PENDING',NULL,i.validation_date),
            i.match_type ,
            i.po_type ,
            i.pay_due_date ,
            'Needs Revalidation',-- l_rel_by,
            l_record_creation_date,
            i.criteria,
            l_first_pass_flag,
            l_true_match_flag ,
            l_all_finalized_flag ,
            l_payment_due_tdy_flag ,
            l_due_8_days_flag,
            i.ou_name,
            i.invoice_source,
            i.invoice_num ,
            i.CREATED_BY,
            i.LAST_UPDATE_DATE,
            i.LAST_UPDATED_BY,
            i.validation_flag,
            0,
            NULL, --l_HOLD_LAST_UPDATE_DATE,
            NULL,---l_hold_last_updated_by,
            i.vendor_id,
            i.vendor_site_id,
            i.invoice_date,
            i.invoice_amount,
            i.vendor_name
          );
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'UNHANDLED EXCEPTION OCCURRED IN PACKAGE XX_AP_INSERT_INV_MATCH_DETAIL In First Pass Cursor  ERRMSG:' ||sqlerrm);
        retcode:='2';
      END;
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'First Pass Non-EDI Record count : '||TO_CHAR(l_rec_cnt));
    l_rec_cnt:=0;
    FOR i IN c_first_pass_edi
    LOOP
      l_rec_cnt:=l_rec_cnt+1;
      BEGIN
        L_MATCH_CRITERIA       :=NULL;
        l_first_pass_flag      :='N';
        l_true_match_flag      :='N';
        l_all_finalized_flag   :='N';
        l_payment_due_tdy_flag :='N';
        l_due_8_days_flag      :='N';
        l_first_pass_flag      :='Y';
        INSERT
        INTO xx_ap_inv_match_detail_219
          (
            invoice_id ,
            suppliernum,
            supplier_site ,
            inv_creation_date ,
            gl_date,
            release_date,
            validation_date,
            po_match_type ,
            po_type ,
            pay_due_date,
            matched_by,
            run_date,
            match_criteria,
            first_pass_flag ,
            true_match_flag ,
            all_finalized_flag ,
            payment_due_tdy_flag ,
            due_8_days_flag,
            ou_name,
            invoice_source,
            invoice_num ,
            CREATED_BY,
            LAST_UPDATE_DATE,
            LAST_UPDATED_BY,
            validation_flag,
            hold_count,
            HOLD_LAST_UPDATE_DATE,
            HOLD_LAST_UPDATED_BY,
            vendor_id,
            vendor_site_id,
            invoice_date,
            invoice_amount,
            vendor_name
          )
          VALUES
          (
            i.invoice_id ,
            i.suppliernum,
            i.supplier_site ,
            i.creation_date ,
            i.gl_date,
            i.release_date,
            NULL,---DECODE( l_rel_by,'PENDING',NULL,i.validation_date),
            i.match_type ,
            i.po_type ,
            i.pay_due_date ,
            'Needs Revalidation',-- l_rel_by,
            l_record_creation_date,
            i.criteria,
            l_first_pass_flag,
            l_true_match_flag ,
            l_all_finalized_flag ,
            l_payment_due_tdy_flag ,
            l_due_8_days_flag,
            i.ou_name,
            i.invoice_source,
            i.invoice_num ,
            i.CREATED_BY,
            i.LAST_UPDATE_DATE,
            i.LAST_UPDATED_BY,
            i.validation_flag,
            0,    --l_hold_count,
            NULL, --l_HOLD_LAST_UPDATE_DATE,
            NULL,---l_hold_last_updated_by,
            i.vendor_id,
            i.vendor_site_id,
            i.invoice_date,
            i.invoice_amount,
            i.vendor_name
          );
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'UNHANDLED EXCEPTION OCCURRED IN PACKAGE XX_AP_INSERT_INV_MATCH_DETAIL In First Pass Cursor  ERRMSG:' ||sqlerrm);
        retcode:='2';
      END;
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'First Pass EDI Record count : '||TO_CHAR(l_rec_cnt));
    l_rec_cnt:=0;
    FOR i IN c_all_finalized
    LOOP
      l_rec_cnt:=l_rec_cnt+1;
      BEGIN
        L_MATCH_CRITERIA       :=NULL;
        l_first_pass_flag      :='N';
        l_true_match_flag      :='N';
        l_all_finalized_flag   :='N';
        l_payment_due_tdy_flag :='N';
        l_due_8_days_flag      :='N';
        xx_ap_match_rate_rpt_pkg.xx_ap_release_by (p_invoice_id => i.invoice_id, p_invoice_creation_date=>i.creation_date,p_invoice_num =>i.invoice_num, p_vendor_id =>i.vendor_id, p_vendor_site_id => i.vendor_site_id, p_match_criteria=> i.criteria, p_validation_flag=> i.validation_flag, p_appsmgr=> l_appsmgr, p_svc_esp_fin => l_svc_esp_fin, p_svc_esp_vps => l_svc_esp_vps, p_rel_by=> l_rel_by, p_rel_date=> l_rel_date, p_hold_last_update_date=> l_hold_last_update_date , p_hold_last_updated_by => l_hold_last_updated_by, p_hold_count=> l_hold_count );
        l_all_finalized_flag :='Y';
        INSERT
        INTO xx_ap_inv_match_detail_219
          (
            invoice_id ,
            suppliernum,
            supplier_site ,
            inv_creation_date ,
            gl_date,
            release_date,
            validation_date,
            po_match_type ,
            po_type ,
            pay_due_date,
            matched_by,
            run_date,
            match_criteria,
            first_pass_flag ,
            true_match_flag ,
            all_finalized_flag ,
            payment_due_tdy_flag ,
            due_8_days_flag,
            ou_name,
            invoice_source,
            invoice_num ,
            CREATED_BY,
            LAST_UPDATE_DATE,
            LAST_UPDATED_BY,
            validation_flag,
            hold_count,
            HOLD_LAST_UPDATE_DATE,
            HOLD_LAST_UPDATED_BY,
            vendor_id,
            vendor_site_id,
            invoice_date,
            invoice_amount,
            vendor_name
          )
          VALUES
          (
            i.invoice_id ,
            i.suppliernum,
            i.supplier_site ,
            i.creation_date ,
            i.gl_date,
            i.release_date,
            i.validation_date,
            i.match_type ,
            i.po_type ,
            i.pay_due_date ,
            l_rel_by,
            l_record_creation_date,
            i.criteria,
            l_first_pass_flag,
            l_true_match_flag ,
            l_all_finalized_flag ,
            l_payment_due_tdy_flag ,
            l_due_8_days_flag,
            i.ou_name,
            i.invoice_source,
            i.invoice_num ,
            i.CREATED_BY,
            i.LAST_UPDATE_DATE,
            i.LAST_UPDATED_BY,
            i.validation_flag,
            l_hold_count,
            l_HOLD_LAST_UPDATE_DATE,
            l_hold_last_updated_by,
            i.vendor_id,
            i.vendor_site_id,
            i.invoice_date,
            i.invoice_amount,
            i.vendor_name
          );
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'UNHANDLED EXCEPTION OCCURRED IN PACKAGE XX_AP_INSERT_INV_MATCH_DETAIL in All Finalized Cursor  ERRMSG:' ||sqlerrm);
        retcode:='2';
      END;
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'All Finalized Record count : '||TO_CHAR(l_rec_cnt));
    l_rec_cnt:=0;
    FOR i IN c_true_match_nedi
    LOOP
      l_rec_cnt:=l_rec_cnt+1;
      BEGIN
        L_MATCH_CRITERIA       :=NULL;
        l_first_pass_flag      :='N';
        l_true_match_flag      :='N';
        l_all_finalized_flag   :='N';
        l_payment_due_tdy_flag :='N';
        l_due_8_days_flag      :='N';
        l_true_match_flag      :='Y';
        INSERT
        INTO xx_ap_inv_match_detail_219
          (
            invoice_id ,
            suppliernum,
            supplier_site ,
            inv_creation_date ,
            gl_date,
            release_date,
            validation_date,
            po_match_type ,
            po_type ,
            pay_due_date,
            matched_by,
            run_date,
            match_criteria,
            first_pass_flag ,
            true_match_flag ,
            all_finalized_flag ,
            payment_due_tdy_flag ,
            due_8_days_flag,
            ou_name,
            invoice_source,
            invoice_num ,
            CREATED_BY,
            LAST_UPDATE_DATE,
            LAST_UPDATED_BY,
            validation_flag,
            hold_count,
            HOLD_LAST_UPDATE_DATE,
            HOLD_LAST_UPDATED_BY,
            vendor_id,
            vendor_site_id,
            invoice_date,
            invoice_amount,
            vendor_name
          )
          VALUES
          (
            i.invoice_id ,
            i.suppliernum,
            i.supplier_site ,
            i.creation_date ,
            i.gl_date,
            i.release_date,
            NULL,---DECODE( l_rel_by,'PENDING',NULL,i.validation_date),
            i.match_type ,
            i.po_type ,
            i.pay_due_date ,
            'Needs Revalidation',-- l_rel_by,
            l_record_creation_date,
            i.criteria,
            l_first_pass_flag,
            l_true_match_flag ,
            l_all_finalized_flag ,
            l_payment_due_tdy_flag ,
            l_due_8_days_flag,
            i.ou_name,
            i.invoice_source,
            i.invoice_num ,
            i.CREATED_BY,
            i.LAST_UPDATE_DATE,
            i.LAST_UPDATED_BY,
            i.validation_flag,
            0,    --l_hold_count,
            NULL, --l_HOLD_LAST_UPDATE_DATE,
            NULL,---l_hold_last_updated_by,
            i.vendor_id,
            i.vendor_site_id,
            i.invoice_date,
            i.invoice_amount,
            i.vendor_name
          );
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'UNHANDLED EXCEPTION OCCURRED IN PACKAGE XX_AP_INSERT_INV_MATCH_DETAIL In True match Cursor ERRMSG:' ||sqlerrm);
        retcode:='2';
      END;
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'True Match Non-EDI Record count : '||TO_CHAR(l_rec_cnt));
    l_rec_cnt:=0;
    FOR i IN c_true_match_edi
    LOOP
      l_rec_cnt:=l_rec_cnt+1;
      BEGIN
        L_MATCH_CRITERIA       :=NULL;
        l_first_pass_flag      :='N';
        l_true_match_flag      :='N';
        l_all_finalized_flag   :='N';
        l_payment_due_tdy_flag :='N';
        l_due_8_days_flag      :='N';
        l_true_match_flag      :='Y';
        INSERT
        INTO xx_ap_inv_match_detail_219
          (
            invoice_id ,
            suppliernum,
            supplier_site ,
            inv_creation_date ,
            gl_date,
            release_date,
            validation_date,
            po_match_type ,
            po_type ,
            pay_due_date,
            matched_by,
            run_date,
            match_criteria,
            first_pass_flag ,
            true_match_flag ,
            all_finalized_flag ,
            payment_due_tdy_flag ,
            due_8_days_flag,
            ou_name,
            invoice_source,
            invoice_num ,
            CREATED_BY,
            LAST_UPDATE_DATE,
            LAST_UPDATED_BY,
            validation_flag,
            hold_count,
            HOLD_LAST_UPDATE_DATE,
            HOLD_LAST_UPDATED_BY,
            vendor_id,
            vendor_site_id,
            invoice_date,
            invoice_amount,
            vendor_name
          )
          VALUES
          (
            i.invoice_id ,
            i.suppliernum,
            i.supplier_site ,
            i.creation_date ,
            i.gl_date,
            i.release_date,
            NULL,---DECODE( l_rel_by,'PENDING',NULL,i.validation_date),
            i.match_type ,
            i.po_type ,
            i.pay_due_date ,
            'Needs Revalidation',-- l_rel_by,
            l_record_creation_date,
            i.criteria,
            l_first_pass_flag,
            l_true_match_flag ,
            l_all_finalized_flag ,
            l_payment_due_tdy_flag ,
            l_due_8_days_flag,
            i.ou_name,
            i.invoice_source,
            i.invoice_num ,
            i.CREATED_BY,
            i.LAST_UPDATE_DATE,
            i.LAST_UPDATED_BY,
            i.validation_flag,
            0,    --l_hold_count,
            NULL, --l_HOLD_LAST_UPDATE_DATE,
            NULL,---l_hold_last_updated_by,
            i.vendor_id,
            i.vendor_site_id,
            i.invoice_date,
            i.invoice_amount,
            i.vendor_name
          );
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'UNHANDLED EXCEPTION OCCURRED IN PACKAGE XX_AP_INSERT_INV_MATCH_DETAIL In True match Cursor ERRMSG:' ||sqlerrm);
        retcode:='2';
      END;
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'True Match EDI Record count : '||TO_CHAR(l_rec_cnt));
    l_rec_cnt:=0;
    FOR i IN c_payment_due
    LOOP
      l_rec_cnt:=l_rec_cnt+1;
      BEGIN
        L_MATCH_CRITERIA       :=NULL;
        l_first_pass_flag      :='N';
        l_true_match_flag      :='N';
        l_all_finalized_flag   :='N';
        l_payment_due_tdy_flag :='N';
        l_due_8_days_flag      :='N';
        xx_ap_match_rate_rpt_pkg.xx_ap_release_by (p_invoice_id => i.invoice_id, p_invoice_creation_date=>i.creation_date,p_invoice_num =>i.invoice_num, p_vendor_id =>i.vendor_id, p_vendor_site_id => i.vendor_site_id, p_match_criteria=> i.criteria, p_validation_flag=> i.validation_flag, p_appsmgr=> l_appsmgr, p_svc_esp_fin => l_svc_esp_fin, p_svc_esp_vps => l_svc_esp_vps, p_rel_by=> l_rel_by, p_rel_date=> l_rel_date, p_hold_last_update_date=> l_hold_last_update_date , p_hold_last_updated_by => l_hold_last_updated_by, p_hold_count=> l_hold_count );
        l_payment_due_tdy_flag :='Y';
        INSERT
        INTO xx_ap_inv_match_detail_219
          (
            invoice_id ,
            suppliernum,
            supplier_site ,
            inv_creation_date ,
            gl_date,
            release_date,
            validation_date,
            po_match_type ,
            po_type ,
            pay_due_date,
            matched_by,
            run_date,
            match_criteria,
            first_pass_flag ,
            true_match_flag ,
            all_finalized_flag ,
            payment_due_tdy_flag ,
            due_8_days_flag,
            ou_name,
            invoice_source,
            invoice_num ,
            CREATED_BY,
            LAST_UPDATE_DATE,
            LAST_UPDATED_BY,
            validation_flag,
            hold_count,
            HOLD_LAST_UPDATE_DATE,
            HOLD_LAST_UPDATED_BY,
            vendor_id,
            vendor_site_id,
            invoice_date,
            invoice_amount,
            vendor_name
          )
          VALUES
          (
            i.invoice_id ,
            i.suppliernum,
            i.supplier_site ,
            i.creation_date ,
            i.gl_date,
            i.release_date,
            i.validation_date,
            i.match_type ,
            i.po_type ,
            i.pay_due_date ,
            l_rel_by, --I.MATCHED_BY,
            l_record_creation_date,
            i.criteria,
            l_first_pass_flag,
            l_true_match_flag ,
            l_all_finalized_flag ,
            l_payment_due_tdy_flag ,
            l_due_8_days_flag,
            i.ou_name,
            i.invoice_source,
            i.invoice_num ,
            i.CREATED_BY,
            i.LAST_UPDATE_DATE,
            i.LAST_UPDATED_BY,
            i.validation_flag,
            l_hold_count,
            l_HOLD_LAST_UPDATE_DATE,
            l_hold_last_updated_by,
            i.vendor_id,
            i.vendor_site_id,
            i.invoice_date,
            i.invoice_amount,
            i.vendor_name
          );
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'UNHANDLED EXCEPTION OCCURRED IN PACKAGE XX_AP_INSERT_INV_MATCH_DETAIL In Payment due Cursor  ERRMSG:' ||sqlerrm);
        retcode:='2';
      END;
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Due Record count : '||TO_CHAR(l_rec_cnt));
    l_rec_cnt:=0;
    FOR i IN c_pay_due_8days
    LOOP
      l_rec_cnt:=l_rec_cnt+1;
      BEGIN
        L_MATCH_CRITERIA       :=NULL;
        l_first_pass_flag      :='N';
        l_true_match_flag      :='N';
        l_all_finalized_flag   :='N';
        l_payment_due_tdy_flag :='N';
        l_due_8_days_flag      :='N';
        xx_ap_match_rate_rpt_pkg.xx_ap_release_by(p_invoice_id => i.invoice_id, p_invoice_creation_date=>i.creation_date,p_invoice_num =>i.invoice_num, p_vendor_id =>i.vendor_id, p_vendor_site_id => i.vendor_site_id, p_match_criteria=> i.criteria, p_validation_flag=> i.validation_flag, p_appsmgr=> l_appsmgr, p_svc_esp_fin => l_svc_esp_fin, p_svc_esp_vps => l_svc_esp_vps, p_rel_by=> l_rel_by, p_rel_date=> l_rel_date, p_hold_last_update_date=> l_hold_last_update_date , p_hold_last_updated_by => l_hold_last_updated_by, p_hold_count=> l_hold_count );
        l_due_8_days_flag :='Y';
        INSERT
        INTO xx_ap_inv_match_detail_219
          (
            invoice_id ,
            suppliernum,
            supplier_site ,
            inv_creation_date ,
            gl_date,
            release_date,
            validation_date,
            po_match_type ,
            po_type ,
            pay_due_date,
            matched_by,
            run_date,
            match_criteria,
            first_pass_flag ,
            true_match_flag ,
            all_finalized_flag ,
            payment_due_tdy_flag ,
            due_8_days_flag,
            ou_name,
            invoice_source,
            invoice_num ,
            CREATED_BY,
            LAST_UPDATE_DATE,
            LAST_UPDATED_BY,
            validation_flag,
            hold_count,
            HOLD_LAST_UPDATE_DATE,
            hold_last_updated_by,
            vendor_id,
            vendor_site_id,
            invoice_date,
            invoice_amount,
            vendor_name
          )
          VALUES
          (
            i.invoice_id ,
            i.suppliernum,
            i.supplier_site ,
            i.creation_date ,
            i.gl_date,
            i.release_date,
            i.validation_date,
            i.match_type ,
            i.po_type ,
            i.pay_due_date ,
            l_rel_by, --I.MATCHED_BY,
            l_record_creation_date,
            i.criteria,
            l_first_pass_flag,
            l_true_match_flag ,
            l_all_finalized_flag ,
            l_payment_due_tdy_flag ,
            l_due_8_days_flag,
            i.ou_name,
            i.invoice_source,
            i.invoice_num ,
            i.CREATED_BY,
            i.LAST_UPDATE_DATE,
            i.LAST_UPDATED_BY,
            i.validation_flag,
            l_hold_count,
            l_HOLD_LAST_UPDATE_DATE,
            l_hold_last_updated_by,
            i.vendor_id,
            i.vendor_site_id,
            i.invoice_date,
            i.invoice_amount,
            i.vendor_name
          );
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'UNHANDLED EXCEPTION OCCURRED IN PACKAGE XX_AP_INSERT_INV_MATCH_DETAIL for Payment due in 8 days Cursor ERRMSG:' ||sqlerrm);
        retcode:='2';
      END;
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Due 8 Days Record count : '||TO_CHAR(l_rec_cnt));
    l_rec_cnt:=0;
    ---------------------For First Pass---------------------------
    BEGIN
      SELECT NVL(COUNT(invoice_id),0)
      INTO v_daily_count_FP
      FROM xx_ap_inv_match_detail_219
      WHERE run_date     =l_record_creation_date
      AND first_pass_flag='Y';
      fnd_file.put_line(fnd_file.log,'No of Records inserted on ' ||p_date || ' is ' || v_daily_count_FP);
      ---begin
      IF v_daily_count_FP > 0 THEN
        xx_ap_match_rate_rpt_pkg.xx_ap_upd_inv_detail_firstPass(l_record_creation_date);
        xx_ap_match_rate_rpt_pkg.xx_ap_upd_matched_by_firstpass(l_record_creation_date);
      END IF ;
    END;
    -------------------------For True Match-------------------------
    BEGIN
      SELECT NVL(COUNT(invoice_id),0)
      INTO v_daily_count_tm
      FROM xx_ap_inv_match_detail_219
      WHERE run_date     =l_record_creation_date
      AND true_match_flag='Y';
      fnd_file.put_line(fnd_file.log,'No of Records inserted on ' ||p_date || ' is ' || v_daily_count_tm);
      IF v_daily_count_tm > 0 THEN
        xx_ap_match_rate_rpt_pkg.xx_ap_upd_inv_detail_truematch(l_record_creation_date);
        xx_ap_match_rate_rpt_pkg.xx_ap_upd_matched_by_truematch(l_record_creation_date);
      END IF ;
    END;
    ------------------------For Summary Table Insert--------------------------
    BEGIN
      SELECT NVL(COUNT(invoice_id),0)
      INTO v_daily_count
      FROM xx_ap_inv_match_detail_219
      WHERE run_date=l_record_creation_date;
      fnd_file.put_line(fnd_file.log,'No of Records inserted on ' ||p_date || ' is ' || v_daily_count);
      ---begin
      IF v_daily_count > 0 THEN
        xx_ap_match_rate_rpt_pkg.xx_ap_insert_inv_match_summary(l_record_creation_date);
      END IF ;
    END;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'UNHANDLED EXCEPTION OCCURRED IN PACKAGE XX_AP_INSERT_INV_MATCH_DETAIL ' ||sqlerrm);
  retcode:='2';
end xx_ap_insert_inv_match_detail;
-- +======================================================================+
-- | Name        :  XX_AP_INSERT_INV_MATCH_SUMMARY                               |
-- | Description :  Procedure to insert data into   xx_ap_inv_match_sum_219 table        |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_Date 
---|                                                                      |
-- | Returns     :                                |
-- |                                                                      |
-- +======================================================================+
PROCEDURE XX_AP_INSERT_INV_MATCH_SUMMARY(
    p_date DATE)
IS
  CURSOR c_total_count
  IS
    SELECT 1 ord,
      run_date,
      run_date process_date,
      'First Pass' criteria,
      NVL(SUM(DECODE(matched_by,'SYS-F',1,0)),0) total_sys_match_cnt,
      COUNT(invoice_id) total_inv_cnt,
      po_match_type,
      po_type,
      OU_name
    FROM xx_ap_inv_match_detail_219
    WHERE 1             =1
    AND first_pass_flag ='Y'
    AND run_date        =p_date
    GROUP BY run_date,
      po_match_type,
      po_type,
      OU_name
  UNION
  SELECT 5 ord,
    run_date,
    run_date process_date,
    'True Match' criteria,
    NVL(SUM(DECODE(matched_by,'SYS-F',1,'SYS',1,0)),0) total_sys_match_cnt,
    COUNT(invoice_id) total_inv_cnt,
    po_match_type,
    po_type,
    OU_name
  FROM xx_ap_inv_match_detail_219
  WHERE 1             =1
  AND true_match_flag ='Y'
  AND run_date        =p_date
  GROUP BY run_date,
    validation_date,
    po_match_type,
    po_type,
    OU_name
  UNION
  SELECT 2 ord,
    run_date,
    run_date process_date,
    'All Finalized' criteria,
    NVL(SUM(DECODE(matched_by,'SYS-F',1,'SYS',1,0)),0) total_sys_match_cnt,
    COUNT(invoice_id) total_inv_cnt,
    po_match_type,
    po_type,
    OU_name
  FROM xx_ap_inv_match_detail_219
  WHERE 1                =1
  AND all_finalized_flag ='Y'
  AND run_date           =p_date
  GROUP BY run_date,
    po_match_type,
    po_type,
    OU_name
  UNION
  SELECT 3 ord,
    run_date,
    pay_due_Date process_date,
    'Payment Due' criteria,
    NVL(SUM(DECODE(matched_by,'SYS-F',1,'SYS',1,0)),0) total_sys_match_cnt,
    COUNT(invoice_id) total_inv_cnt,
    po_match_type,
    po_type,
    OU_name
  FROM xx_ap_inv_match_detail_219
  WHERE 1                  =1
  AND payment_due_tdy_flag ='Y'
  AND run_date             =p_date
  GROUP BY run_date,
    pay_due_Date,
    po_match_type,
    po_type,
    OU_name
  UNION
  SELECT 4 ord,
    run_date,
    pay_due_Date process_date,
    'Payment Due in 8 days' criteria,
    NVL(SUM(DECODE(matched_by,'SYS-F',1,'SYS',1 ,0)),0) total_sys_match_cnt,
    COUNT(invoice_id) total_inv_cnt,
    po_match_type,
    po_type,
    OU_name
  FROM xx_ap_inv_match_detail_219
  WHERE 1             =1
  AND due_8_days_flag ='Y'
  AND run_date        =p_date
  GROUP BY run_date,
    pay_due_Date,
    po_match_type,
    po_type,
    OU_name
  ORDER BY ord ;
BEGIN
  FOR i IN c_total_count
  LOOP
    BEGIN
      INSERT
      INTO xx_ap_inv_match_sum_219
        (
          run_date ,
          process_date,
          criteria ,
          total_inv_count ,
          total_sys_match_cnt,
          po_match_type ,
          po_type ,
          ou_name
        )
        VALUES
        (
          p_date,
          i.process_date,
          i.criteria,
          i.total_inv_cnt,
          i.total_sys_match_cnt,
          i.po_match_type ,
          i.po_type ,
          i.ou_name
        );
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'UNHANDLED EXCEPTION OCCURRED IN PACKAGE XX_AP_INSERT_INV_MATCH_SUMMARY ERRMSG:' ||sqlerrm);
    END;
  END LOOP;
end xx_ap_insert_inv_match_summary;
-- +======================================================================+
-- | Name        :  xx_ap_release_by                               |
-- | Description :  Procedure to get Matched by details        |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_invoice_id ,p_invoice_creation_date,p_invoice_num,p_vendor_id,p_vendor_site_id,p_match_criteria,p_validation_flag
--|  p_appsmgr,p_svc_esp_fin,p_svc_esp_vps
---|                                                                      |
-- | Returns     :  p_rel_by,  p_rel_date,   p_hold_last_update_date,p_hold_last_updated_by    ,p_hold_count                     |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_ap_release_by
  (
    p_invoice_id IN NUMBER,
    p_invoice_creation_date DATE,
    p_invoice_num           VARCHAR2,
    p_vendor_id             NUMBER,
    p_vendor_site_id        NUMBER,
    p_match_criteria  IN VARCHAR2,
    p_validation_flag IN VARCHAR2,
    p_appsmgr         IN NUMBER,
    p_svc_esp_fin     IN NUMBER,
    p_svc_esp_vps     IN NUMBER,
    p_rel_by OUT VARCHAR2,
    p_rel_date out date,
    p_hold_last_update_date OUT DATE,
    p_hold_last_updated_by OUT VARCHAR2,
    p_hold_count OUT NUMBER
  )
IS
  v_recreated_inv_cnt NUMBER:=0;
BEGIN
  SELECT NVL(COUNT(*),0)
  INTO v_recreated_inv_cnt
  FROM ap_invoices_all a
  WHERE a.invoice_num LIKE p_invoice_num
    ||'ODDBUIA%'
  AND a.vendor_id        =p_vendor_id
  AND a.vendor_site_id   =p_vendor_site_id;
  IF v_recreated_inv_cnt > 0 THEN
    BEGIN
      SELECT rel_by,
        last_update_date,
        last_update_date,
        last_updated_by,
        1 hold_count
      INTO p_rel_by,
        p_rel_date,
        p_hold_last_update_date,
        p_hold_last_updated_by,
        p_hold_count
      FROM
        (SELECT m.last_update_date,
          m.last_updated_by,
          m.invoice_id,
          'MAN' rel_by
        FROM ap_holds_all m
        WHERE ROWID =
          (SELECT MAX(ROWID)
          FROM ap_holds_all A
          WHERE A.last_update_date =
            (SELECT MAX(b.last_update_date)
            FROM ap_holds_all b
            WHERE 1          =1
            AND b.invoice_id = a.invoice_id
            )
          AND A.invoice_id           = m.invoice_id
          AND A.release_lookup_code IS NOT NULL
          )
        ) h
      WHERE h.invoice_id = p_invoice_id;
    EXCEPTION
    WHEN OTHERS THEN
      p_rel_by                :='MAN';
      p_rel_date              := p_invoice_creation_date;
      p_hold_last_update_date := NULL;
      p_hold_last_updated_by  := NULL;
      p_hold_count            := 0;
    END ;
  ELSE
    BEGIN
      SELECT rel_by,
        last_update_date,
        last_update_date,
        last_updated_by,
        1 hold_count
      INTO p_rel_by,
        p_rel_date,
        p_hold_last_update_date,
        p_hold_last_updated_by,
        p_hold_count
      FROM
        (SELECT m.last_update_date,
          m.last_updated_by,
          m.invoice_id,
          NVL(DECODE( m.last_updated_by,p_appsmgr,'SYS',p_svc_esp_fin,'SYS',p_svc_esp_vps,'SYS','MAN'),'SYS') rel_by
        FROM ap_holds_all m
        WHERE ROWID =
          (SELECT MAX(ROWID)
          FROM ap_holds_all A
          WHERE A.last_update_date =
            (SELECT MAX(b.last_update_date)
            FROM ap_holds_all b
            WHERE 1                 =1
            AND b.invoice_id        = A.invoice_id
            AND b.hold_lookup_code <> 'OD NO Receipt'---addded to exclude this hold from SYS
            )
          AND A.invoice_id           = m.invoice_id
          AND A.release_lookup_code IS NOT NULL
          AND A.hold_lookup_code    <> 'OD NO Receipt'---addded to exclude this hold from SYS
          )
        ) h
      WHERE h.invoice_id = p_invoice_id;
    EXCEPTION
    WHEN OTHERS THEN
      SELECT 'SYS-F' rel_by,
        NULL,
        NULL,
        NULL,
        0 hold_count
      INTO p_rel_by,
        p_rel_date,
        p_HOLD_LAST_UPDATE_DATE,
        p_HOLD_LAST_UPDATED_By,
        p_hold_count
      FROM dual;
    END ;
  END IF;
END xx_ap_release_by;
/*FUNCTION get_release_date(
p_invoice_id NUMBER)
RETURN DATE
IS
v_release_date DATE;
BEGIN
SELECT MAX(ah2.last_update_date)
INTO v_release_date
FROM ap_holds_all ah2
WHERE ah2.invoice_id     = p_invoice_id
AND release_lookup_code IS NOT NULL;
RETURN v_release_date;
EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END get_release_date;*/
END xx_ap_match_rate_rpt_pkg;
/
SHOW ERROR;
