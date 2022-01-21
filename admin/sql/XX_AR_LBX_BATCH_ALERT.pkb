create or replace
PACKAGE BODY XX_AR_LBX_BATCH_ALERT
AS
  -- +====================================================================================================================================+
  -- |                                Office Depot - Project Simplify                                                                     |
  -- |                                     Oracle AMS Support                                                                             |
  -- +====================================================================================================================================+
  -- |  Name:  XX_AR_LBX_BATCH_ALERT (RICE ID : E0000)                                                                                    |
  -- |                                                                                                                                    |
  -- |  Description:  This package will be used for automating the lockbox Batch Monitoring Activities                                    |
  -- |    GET_LBX_STATS           This procedure will fetch lockbox details and send email alert to AMS batch team                        |
  -- |    GET_TRANSLATIONS        This procedure will fetch translation values for a given translation name and source                    |
  -- |    GET_LB_FILE_DATA        This procedure will fetch details of lockbox files received and for a given cycle date expected         |
  -- |    GET_RECORD_COUNT        This procedure will fetch record counts for lockbox files of a given date and send the data to business |
  -- |    PREPARE_AND_SEND_EMAIL  This procedure will send html email alerts to appropriate teams                                         |
  -- |                                                                                                                                    |
  -- |  Change Record:                                                                                                                    |
  -- +====================================================================================================================================+
  -- | Version     Date         Author               Remarks                                                                              |
  -- | =========   ===========  =============        =====================================================================================|
  -- | 1.0         17-Apr-2012  Archana N.           Initial version - QC Defect # 20100                                                  |
  -- +====================================================================================================================================+
  gc_source_field1  VARCHAR2(240) := NULL;
  gc_target_field1  VARCHAR2(240) := NULL;
  gc_target_field2  VARCHAR2(240) := NULL;
  gc_target_field3  VARCHAR2(240) := NULL;
  gc_target_field4  VARCHAR2(240) := NULL;
  gc_target_field5  VARCHAR2(240) := NULL;
  gc_target_field6  VARCHAR2(240) := NULL;
  gc_target_field7  VARCHAR2(240) := NULL;
  gc_target_field8  VARCHAR2(240) := NULL;
  gc_target_field9  VARCHAR2(240) := NULL;
  gc_target_field10 VARCHAR2(240) := NULL;
  gc_target_field11 VARCHAR2(240) := NULL;
  gc_target_field12 VARCHAR2(240) := NULL;
  gc_target_field13 VARCHAR2(240) := NULL;
  gc_target_field14 VARCHAR2(240) := NULL;
  gc_target_field15 VARCHAR2(240) := NULL;
  gc_target_field16 VARCHAR2(240) := NULL;
  gc_target_field17 VARCHAR2(240) := NULL;
  gc_target_field18 VARCHAR2(240) := NULL;
  gc_target_field19 VARCHAR2(240) := NULL;
  gc_target_field20 VARCHAR2(240) := NULL;
  gc_source_value1  VARCHAR2(240) := NULL;
  gc_target_value1  VARCHAR2(240) := NULL;
  gc_target_value2  VARCHAR2(240) := NULL;
  gc_target_value3  VARCHAR2(240) := NULL;
  gc_target_value4  VARCHAR2(240) := NULL;
  gc_target_value5  VARCHAR2(240) := NULL;
  gc_target_value6  VARCHAR2(240) := NULL;
  gc_target_value7  VARCHAR2(240) := NULL;
  gc_target_value8  VARCHAR2(240) := NULL;
  gc_target_value9  VARCHAR2(240) := NULL;
  gc_target_value10 VARCHAR2(240) := NULL;
  gc_target_value11 VARCHAR2(240) := NULL;
  gc_target_value12 VARCHAR2(240) := NULL;
  gc_target_value13 VARCHAR2(240) := NULL;
  gc_target_value14 VARCHAR2(240) := NULL;
  gc_target_value15 VARCHAR2(240) := NULL;
  gc_target_value16 VARCHAR2(240) := NULL;
  gc_target_value17 VARCHAR2(240) := NULL;
  gc_target_value18 VARCHAR2(240) := NULL;
  gc_target_value19 NUMBER        := 0;
  gc_target_value20 NUMBER        := 0;
  gn_conc_req_id    NUMBER        := 0;
  gc_mainp_status   VARCHAR2(15)  := NULL;
  gc_program_name   VARCHAR2(80)  := NULL;
  gc_short_name     VARCHAR2(30)  := NULL;
  p_debug_flag      VARCHAR2(50);
  lc_day_of_week    VARCHAR2(50);
  ln_recd_fcount    NUMBER(20) := 0; --counter for number of files received for a given cycle date.
  ln_exp_fcount     NUMBER(20) ;     --count of expected lockbox files for a given cycle date.
  p_cycle_date    VARCHAR2(30);
  lc_holiday_flag VARCHAR2(8) := 'E';
  lc_holiday      VARCHAR2(300);
  
TYPE t_list IS TABLE OF VARCHAR2(20);
  lc_trans_list t_list   := t_list();
  lc_missing_list t_list := t_list();
  lc_lbx_flist t_list    := t_list();
  ln_index NUMBER;
  lc_day   VARCHAR2(50);
  
TYPE t_hol_dates IS TABLE OF VARCHAR2(50);
  
  l_hol_dates t_hol_dates;
  lc_mail_host     VARCHAR2(30)   := NULL;
  lc_from          VARCHAR2(80)   := NULL;
  lc_subject       VARCHAR2(80)   := NULL;
  lc_title_html    VARCHAR2(100)  := NULL;
  lc_body_hdr_html VARCHAR2(4000) := NULL;
  lc_body_dtl_html VARCHAR2(4000) := NULL;
  lc_trans_status  VARCHAR2(15)   := NULL;
  lc_email_status  VARCHAR2(15)   := NULL;
  lc_source_field1 VARCHAR2(30)   := NULL;
  lc_source_value1 VARCHAR2(80)   := NULL;
  lc_cc_list       VARCHAR2(100)  := NULL;
  lc_missing_txt   VARCHAR2(800)  := NULL;
  lc_err_buff      VARCHAR2(100);
  lc_ret_code      VARCHAR(50);
  lc_cdate DATE ;
  lc_cycle_date  VARCHAR2(50) ;
  ln_trans_index NUMBER ;
  
  -- +============================================================================+
  -- | Name             : GET_TRANSLATIONS                                        |
  -- |                                                                            |
  -- | Description      : This procedure will fetch translation values for a given|
  -- |                    translation name and source                             |
  -- |                                                                            |
  -- | Parameters       : p_debug_flag       IN  VARCHAR2                         |
  -- |                  : p_translation_name IN  VARCHAR2                         |
  -- |                  : p_source_field1    IN  VARCHAR2                         |
  -- |                                                                            |
  -- | Change Record:                                                             |
  -- | ==============                                                             |
  -- | Version  Date         Author          Remarks                              |
  -- | =======  ===========  =============   ===================================  |
  -- | 1.0      17-Apr-2012  Archana N.      Initial version - QC Defect # 20100  |
  -- +============================================================================+

PROCEDURE get_translations(
    p_debug_flag       IN VARCHAR2,
    p_translation_name IN VARCHAR2,
    p_source_field1    IN VARCHAR2)
IS
BEGIN
  l_to_tbl.EXTEND(20);
  l_cc_tbl.EXTEND(20);
  fnd_file.put_line(fnd_file.LOG,'Begining of get_translations');
  SELECT def.source_field1,
    def.target_field1,
    def.target_field2,
    def.target_field3,
    def.target_field4,
    def.target_field5,
    def.target_field6,
    def.target_field7,
    def.target_field8,
    def.target_field9,
    def.target_field10,
    def.target_field11,
    def.target_field12,
    def.target_field13,
    def.target_field14,
    def.target_field15,
    def.target_field16,
    def.target_field17,
    def.target_field18,
    def.target_field19,
    def.target_field20,
    val.source_value1,
    val.target_value1,
    val.target_value2,
    val.target_value3,
    val.target_value4,
    val.target_value5,
    val.target_value6,
    val.target_value7,
    val.target_value8,
    val.target_value9,
    val.target_value10,
    val.target_value11,
    val.target_value12,
    val.target_value13,
    val.target_value14,
    val.target_value15,
    val.target_value16,
    val.target_value17,
    val.target_value18,
    val.target_value19,
    val.target_value20
  INTO gc_source_field1,
    gc_target_field1,
    gc_target_field2,
    gc_target_field3,
    gc_target_field4,
    gc_target_field5,
    gc_target_field6,
    gc_target_field7,
    gc_target_field8,
    gc_target_field9,
    gc_target_field10,
    gc_target_field11,
    gc_target_field12,
    gc_target_field13,
    gc_target_field14,
    gc_target_field15,
    gc_target_field16,
    gc_target_field17,
    gc_target_field18,
    gc_target_field19,
    gc_target_field20,
    gc_source_value1,
    gc_target_value1,
    gc_target_value2,
    gc_target_value3,
    gc_target_value4,
    gc_target_value5,
    gc_target_value6,
    gc_target_value7,
    gc_target_value8,
    gc_target_value9,
    gc_target_value10,
    gc_target_value11,
    gc_target_value12,
    gc_target_value13,
    gc_target_value14,
    gc_target_value15,
    gc_target_value16,
    gc_target_value17,
    gc_target_value18,
    gc_target_value19,
    gc_target_value20
  FROM xxfin.xx_fin_translatedefinition def,
    xxfin.xx_fin_translatevalues val
  WHERE def.translate_id   = val.translate_id
  AND def.translation_name = p_translation_name
  AND val.source_value1    = p_source_field1
  AND def.enabled_flag     = 'Y'
  AND val.enabled_flag     = 'Y'
  AND SYSDATE BETWEEN def.start_date_active AND NVL (def.end_date_active, SYSDATE + 1)
  AND SYSDATE BETWEEN val.start_date_active AND NVL (val.end_date_active, SYSDATE + 1);
  fnd_file.put_line(fnd_file.LOG,'End of get_translations');
END get_translations;

-- +============================================================================+
-- | Name             : GET_LB_FILE_DATA                                        |
-- |                                                                            |
-- | Description      : This procedure will fetch details of lockbox files      |
-- |                    received and for a given cycle date expected            |
-- |                                                                            |
-- | Parameters       : lc_cdate IN DATE                                        |
-- |                                                                            |
-- | Change Record:                                                             |
-- | ==============                                                             |
-- | Version  Date         Author          Remarks                              |
-- | =======  ===========  =============   ===================================  |
-- | 1.0      17-Apr-2012  Archana N.      Initial version - QC Defect # 20100  |
-- +============================================================================+

PROCEDURE get_lb_file_data(
    lc_cdate IN DATE)
IS
  ln_fls_req_id       NUMBER(20);
  lc_file_path        VARCHAR2(100);
  lc_debug_flag       VARCHAR2(50);
  lc_translation_name VARCHAR2(50) := 'XX_EBL_COMMON_TRANS';
  lc_source_field     VARCHAR2(50) := 'lbx_file_path';
  lc_search_string    VARCHAR2(50);
  lc_lbx_fname        VARCHAR2(50);
  lc_temp_fname       VARCHAR2(50);
  lc_user             NUMBER(20);
  lc_fls_status       BOOLEAN;
  lb_layout           BOOLEAN;
  lc_sphase           VARCHAR2(50);
  lc_sstatus          VARCHAR2(50);
  lc_sdevphase        VARCHAR2(50);
  lc_sdevstatus       VARCHAR2(50);
  lc_smessage         VARCHAR2(50);
  fhandle UTL_FILE.FILE_TYPE;
  lc_file_line VARCHAR2(100);
  k BINARY_INTEGER      := 1;
  ln_trans_index   NUMBER := 0;
  ln_success_flag  NUMBER := 0;
  ln_check_counter NUMBER := 0;
  ln_year          NUMBER ;
  CURSOR c_saturday IS
    (SELECT val.source_value1
    FROM xxfin.xx_fin_translatedefinition def,
      xxfin.xx_fin_translatevalues val
    WHERE def.translate_id       = val.translate_id
    AND def.translation_name     = 'XX_AR_LB_CALENDAR'
    AND upper(def.target_field7) = trim(lc_day_of_week)
    AND val.target_value7        = 1 --indicating the corresponding file is expected for saturday.
    AND def.enabled_flag         = 'Y'
    AND val.enabled_flag         = 'Y'
    AND SYSDATE BETWEEN def.start_date_active AND NVL (def.end_date_active, SYSDATE + 1)
    AND SYSDATE BETWEEN val.start_date_active AND NVL (val.end_date_active, SYSDATE + 1)
    );
  CURSOR c_sunday IS
    (SELECT val.source_value1
    FROM xxfin.xx_fin_translatedefinition def,
      xxfin.xx_fin_translatevalues val
    WHERE def.translate_id       = val.translate_id
    AND def.translation_name     = 'XX_AR_LB_CALENDAR'
    AND upper(def.target_field1) = trim(lc_day_of_week)
    AND val.target_value1        = 1 --indicating the corresponding file is expected for sunday.
    AND def.enabled_flag         = 'Y'
    AND val.enabled_flag         = 'Y'
    AND SYSDATE BETWEEN def.start_date_active AND NVL (def.end_date_active, SYSDATE + 1)
    AND SYSDATE BETWEEN val.start_date_active AND NVL (val.end_date_active, SYSDATE + 1)
    );
  CURSOR c_weekday IS
    (SELECT val.source_value1
    FROM xxfin.xx_fin_translatedefinition def,
      xxfin.xx_fin_translatevalues val
    WHERE def.translate_id   = val.translate_id
    AND def.translation_name = 'XX_AR_LB_CALENDAR'
    AND val.target_value3    = 1
    AND def.enabled_flag     = 'Y'
    AND val.enabled_flag     = 'Y'
    AND SYSDATE BETWEEN def.start_date_active AND NVL (def.end_date_active, SYSDATE + 1)
    AND SYSDATE BETWEEN val.start_date_active AND NVL (val.end_date_active, SYSDATE + 1)
    );

BEGIN
  fnd_file.put_line(fnd_file.LOG,'Entering the procedure get_lb_file_data.');
  SELECT TO_CHAR(lc_cdate,'YYYY') INTO ln_year FROM dual;
  fnd_file.put_line (fnd_file.LOG,'Value of ln_year'||ln_year);
  lc_trans_list.EXTEND(20);
  lc_missing_list.EXTEND(20);
  lc_lbx_flist.EXTEND(20);
  EXECUTE IMMEDIATE 'SELECT val.target_value1 
  FROM xxfin.xx_fin_translatedefinition def,               
  xxfin.xx_fin_translatevalues val         
  WHERE def.translate_id     = val.translate_id           
  AND def.translation_name = ''XX_BANK_HOLIDAY_CALENDAR''           
  AND val.source_value1 = '||ln_year||'           
  AND def.enabled_flag     = ''Y''           
  AND val.enabled_flag     = ''Y''           
  AND SYSDATE BETWEEN def.start_date_active AND NVL (def.end_date_active, SYSDATE + 1)           
  AND SYSDATE BETWEEN val.start_date_active AND NVL (val.end_date_active, SYSDATE + 1)' 
  BULK COLLECT INTO l_hol_dates ;
  
  IF SQL%NOTFOUND THEN
    fnd_file.put_line(fnd_file.LOG,'No holiday details available for the year - '||ln_year);
  ELSE
    fnd_file.put_line (fnd_file.LOG, 'Holiday dates successfully fetched');
    FOR i IN l_hol_dates.FIRST..l_hol_dates.LAST
    LOOP
      IF (TO_CHAR(lc_cdate,'DD-MON-YYYY') = l_hol_dates(i)) THEN
        lc_holiday_flag                  := 'Y';
        SELECT val.target_value2
        INTO lc_holiday
        FROM xxfin.xx_fin_translatedefinition def,
          xxfin.xx_fin_translatevalues val
        WHERE def.translate_id   = val.translate_id
        AND def.translation_name = 'XX_BANK_HOLIDAY_CALENDAR'
        AND val.target_value1    = l_hol_dates(i)
        AND def.enabled_flag     = 'Y'
        AND val.enabled_flag     = 'Y'
        AND SYSDATE BETWEEN def.start_date_active AND NVL (def.end_date_active, SYSDATE + 1)
        AND SYSDATE BETWEEN val.start_date_active AND NVL (val.end_date_active, SYSDATE + 1);
        fnd_file.put_line (fnd_file.LOG, 'Its a bank holiday - '||lc_holiday);
      END IF;
    END LOOP;
  END IF; --closing the no_holiday_details available loop
  IF lc_holiday_flag = 'N' THEN
    fnd_file.put_line (fnd_file.LOG,'There is no bank holiday for the given cycle date');
  END IF;
  SELECT TO_CHAR(lc_cdate,'YYYYMMDD') INTO lc_cycle_date FROM dual;
  SELECT TO_CHAR(lc_cdate,'DAY') INTO lc_day_of_week FROM dual;
  SELECT to_number(TO_CHAR(lc_cdate,'D'),9) INTO ln_trans_index FROM dual;
  fnd_file.put_line (fnd_file.LOG, 'Cycle Date : '||lc_cycle_date);
  fnd_file.put_line (fnd_file.LOG, 'Day of week : '||lc_day_of_week);
  fnd_file.put_line (fnd_file.LOG, 'value of trans_index : '||ln_trans_index);
  EXECUTE IMMEDIATE 'SELECT sum(val.target_value'||ln_trans_index||') 
  FROM xxfin.xx_fin_translatedefinition def,               
  xxfin.xx_fin_translatevalues val         
  WHERE def.translate_id     = val.translate_id           
  AND def.translation_name = ''XX_AR_LB_CALENDAR''           
  AND def.enabled_flag     = ''Y''           
  AND val.enabled_flag     = ''Y''           
  AND SYSDATE BETWEEN def.start_date_active AND NVL (def.end_date_active, SYSDATE + 1)           
  AND SYSDATE BETWEEN val.start_date_active AND NVL (val.end_date_active, SYSDATE + 1)' 
  INTO ln_exp_fcount ;
  
  fnd_file.put_line (fnd_file.LOG,'Debug flag : '||p_debug_flag);
  fnd_file.put_line (fnd_file.LOG,'Translation Setup Details');
  fnd_file.put_line (fnd_file.LOG,'Translation Name     - '|| lc_translation_name);
  fnd_file.put_line(fnd_file.LOG,'Source field - '||lc_source_field);
  fnd_file.put_line (fnd_file.LOG,'Translation Values   ');
  get_translations(lc_debug_flag,lc_translation_name,lc_source_field);
  fnd_file.put_line (fnd_file.LOG, RPAD(gc_source_field1, 20, ' ') || ' - ' || gc_source_value1);
  fnd_file.put_line (fnd_file.LOG,RPAD(gc_target_field1, 20, ' ') || ' - ' || gc_target_value1);
  fnd_file.put_line (fnd_file.LOG, RPAD(gc_target_field2, 20, ' ') || ' - ' || gc_target_value2);
  fnd_file.put_line (fnd_file.LOG, RPAD(gc_target_field3, 20, ' ') || ' - ' || gc_target_value3);
  fnd_file.put_line (fnd_file.LOG, RPAD(gc_target_field4, 20, ' ') || ' - ' || gc_target_value4);
  fnd_file.put_line (fnd_file.LOG, RPAD(gc_target_field5, 20, ' ') || ' - ' || gc_target_value5);
  fnd_file.put_line (fnd_file.LOG, RPAD(gc_target_field6, 20, ' ') || ' - ' || gc_target_value6);
  fnd_file.put_line (fnd_file.LOG,RPAD(gc_target_field7, 20, ' ') || ' - ' || gc_target_value7);
  fnd_file.put_line (fnd_file.LOG, RPAD(gc_target_field8, 20, ' ') || ' - ' || gc_target_value8);
  fnd_file.put_line (fnd_file.LOG, RPAD(gc_target_field9, 20, ' ') || ' - ' || gc_target_value9);
  fnd_file.put_line (fnd_file.LOG,RPAD(gc_target_field10, 20, ' ') || ' - ' || gc_target_value10);
  fnd_file.put_line (fnd_file.LOG, RPAD(gc_target_field11, 20, ' ') || ' - ' || gc_target_value11);
  fnd_file.put_line (fnd_file.LOG, RPAD(gc_target_field12, 20, ' ') || ' - ' || gc_target_value12);
  fnd_file.put_line (fnd_file.LOG,RPAD(gc_target_field13, 20, ' ') || ' - ' || gc_target_value13);
  fnd_file.put_line (fnd_file.LOG,RPAD(gc_target_field14, 20, ' ') || ' - ' || gc_target_value14);
  fnd_file.put_line (fnd_file.LOG, RPAD(gc_target_field15, 20, ' ') || ' - ' || gc_target_value15);
  lc_file_path := gc_target_value1;
  fnd_file.put_line(fnd_file.LOG,'Target value fetched for p_file_path : '|| lc_file_path);
  lc_search_string := 'LB*'||lc_cycle_date||'*';
  --call common file listing program
  ln_fls_req_id := FND_REQUEST.SUBMIT_REQUEST(application => 'XXCOMN', 
                                              PROGRAM => 'XXCOMNFILELS', 
                                              description => '', 
                                              start_time => SYSDATE, 
                                              sub_request => FALSE, 
                                              argument1 => lc_file_path, 
                                              argument2 => lc_search_string);
  COMMIT;
  fnd_file.put_line(fnd_file.LOG,'File listing prog submitted : '|| ln_fls_req_id);
  
  lc_fls_status           := FND_CONCURRENT.WAIT_FOR_REQUEST( request_id => ln_fls_req_id ,
                                                              INTERVAL => '60' ,
                                                              phase => lc_sphase ,
                                                              status => lc_sstatus ,
                                                              dev_phase => lc_sdevphase ,
                                                              dev_status => lc_sdevstatus ,
                                                              MESSAGE => lc_smessage );
  IF (UPPER(lc_sstatus)    = 'ERROR') THEN
    lc_err_buff           := 'The Report Completed in ERROR';
    lc_ret_code           := 2;
  ELSIF (UPPER(lc_sstatus) = 'WARNING') THEN
    lc_err_buff           := 'The Report Completed in WARNING';
    lc_ret_code           := 1;
  ELSE
    lc_err_buff := 'The Report Completion is NORMAL';
    lc_ret_code := 0;
  END IF;
  fnd_file.put_line(fnd_file.LOG, 'Completion status : '||lc_err_buff);
  fhandle := UTL_FILE.FOPEN('LBX_DIR','o'||TO_CHAR(ln_fls_req_id)||'.out','R');
  fnd_file.put_line(fnd_file.LOG,'List of lockbox files received..');
  LOOP
    BEGIN
                       <<inner_loop>> UTL_FILE.GET_LINE(fhandle, lc_file_line);
      ln_recd_fcount  := ln_recd_fcount+1;
      lc_temp_fname   := SUBSTR(lc_file_line,instr(lc_file_line,'LB'));
      lc_lbx_fname    := rtrim(SUBSTR(lc_temp_fname,16),'.txt');
      lc_lbx_flist(k) := lc_lbx_fname;
      fnd_file.put_line(fnd_file.LOG,lc_lbx_flist(k));
      k:= k+1;
    EXCEPTION
    WHEN no_data_found THEN
      fnd_file.put_line(fnd_file.LOG,'Data read from the output file is complete');
      fnd_file.put_line(fnd_file.LOG,'Number of files received : '||ln_recd_fcount);
      EXIT;
    END; -- end of inner loop
  END LOOP;
  UTL_FILE.FCLOSE(fhandle);
  fnd_file.put_line(fnd_file.LOG,'Cycle day : '||upper(lc_day_of_week));
  IF (trim(upper(lc_day_of_week)) = 'SATURDAY') THEN
    fnd_file.put_line(fnd_file.LOG,'Cycle day is Saturday..');
    OPEN c_saturday;
    FETCH c_saturday BULK COLLECT INTO lc_trans_list;
    CLOSE c_saturday;
  ELSIF (trim(upper(lc_day_of_week)) = 'SUNDAY') THEN
    OPEN c_sunday;
    FETCH c_sunday BULK COLLECT INTO lc_trans_list;
    fnd_file.put_line(fnd_file.LOG,'Cycle day is Sunday..');
    CLOSE c_sunday;
  ELSE
    OPEN c_weekday;
    FETCH c_weekday BULK COLLECT INTO lc_trans_list;
    CLOSE c_weekday;
  END IF;
  fnd_file.put_line(fnd_file.LOG,'Transmission list..');
  FOR i IN lc_trans_list.FIRST..lc_trans_list.LAST
  LOOP
    fnd_file.put_line(fnd_file.LOG,lc_trans_list(i));
  END LOOP;
  lc_missing_list := lc_trans_list MULTISET
  EXCEPT lc_lbx_flist ;
  fnd_file.put_line(fnd_file.LOG,'List of received files..');
  FOR i IN lc_lbx_flist.FIRST..lc_lbx_flist.LAST
  LOOP
    fnd_file.put_line(fnd_file.LOG,lc_lbx_flist(i));
  END LOOP;
  fnd_file.put_line(fnd_file.LOG,'List of missing files..');
  FOR i IN lc_missing_list.FIRST..lc_missing_list.LAST
  LOOP
    fnd_file.put_line(fnd_file.LOG,lc_missing_list(i));
  END LOOP;
  ln_check_counter := lc_missing_list.count;
  fnd_file.put_line(fnd_file.LOG,'Number of files expected :'||ln_exp_fcount);
  fnd_file.put_line(fnd_file.LOG,'Number of files received :'||ln_recd_fcount);
  fnd_file.put_line(fnd_file.LOG,'Number of files missing :'||ln_check_counter);
  
  EXCEPTION
  WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG, 'Exception at PROCEDURE get_lb_file_data : ' || SQLERRM);
  RETURN;
  
  fnd_file.put_line(fnd_file.LOG,'Exiting the procedure get_lb_file_data.');
END get_lb_file_data;

-- +============================================================================+
-- | Name             : PREPARE_AND_SEND_EMAIL                                  |
-- |                                                                            |
-- | Description      : This procedure will send html email alerts to           |
-- |                    appropriate teams                                       |
-- |                                                                            |
-- | Parameters       : p_debug_flag    IN  VARCHAR2                            |
-- |                  : p_from          IN  VARCHAR2                            |
-- |                  : p_to_tbl     IN  t_recipient                            |
-- |                  : p_cc_tbl     IN  t_recipient                            |
-- |                  : p_mail_host     IN  VARCHAR2                            |
-- |                  : p_subject       IN  VARCHAR2                            |
-- |                  : p_title_html    IN  VARCHAR2                            |
-- |                  : p_body_hdr_html IN  VARCHAR2                            |
-- |                  : p_body_dtl_html IN  VARCHAR2                            |
-- |                  : p_return_status OUT VARCHAR2                            |
-- |                                                                            |
-- | Change Record:                                                             |
-- | ==============                                                             |
-- | Version  Date         Author          Remarks                              |
-- | =======  ===========  =============   ===================================  |
-- | 1.0      17-Apr-2012  Archana N.      Initial version - QC Defect # 20100  |
-- +============================================================================+

PROCEDURE prepare_and_send_email(
    p_debug_flag      IN VARCHAR2,
    p_from            IN VARCHAR2,
    p_to_tbl          IN t_recipient,
    p_cc_tbl          IN t_recipient,
    p_mail_host       IN VARCHAR2,
    p_subject         IN VARCHAR2,
    p_title_html      IN VARCHAR2,
    p_body_hdr_html   IN VARCHAR2,
    p_body_dtl_html   IN VARCHAR2,
    p_return_status OUT VARCHAR2 )
AS
  v_from           VARCHAR2(80)   := NULL;
  v_mail_host      VARCHAR2(30)   := NULL;
  v_subject        VARCHAR2(80)   := NULL;
  lc_title_html    VARCHAR2(100)  := NULL;
  lc_body_hdr_html VARCHAR2(4000) := NULL;
  lc_body_dtl_html VARCHAR2(4000) := NULL;
  l_to_list        VARCHAR2(1000) := NULL;
  l_cc_list        VARCHAR2(1000) := NULL;
  lc_instance      VARCHAR2(100)  := NULL;
  lc_host_name     VARCHAR2(100)  := NULL;
  crlf             VARCHAR2(2)    := chr(13) || chr(10);
  v_mail_conn utl_smtp.connection;
BEGIN
  v_from           := p_from;
  v_mail_host      := p_mail_host;
  v_subject        := p_subject;
  lc_title_html    := p_title_html;
  lc_body_hdr_html := p_body_hdr_html;
  lc_body_dtl_html := p_body_dtl_html;
  FOR i            IN l_to_tbl.FIRST..l_to_tbl.LAST
  LOOP
    l_to_list := l_to_list||l_to_tbl(i)||';';
  END LOOP;
  FOR i IN l_cc_tbl.FIRST..l_cc_tbl.LAST
  LOOP
    l_cc_list := l_cc_list||l_cc_tbl(i)||';';
  END LOOP;
  fnd_file.put_line (fnd_file.LOG, 'PROCEDURE prepare_and_send_email - Begin');
  fnd_file.put_line (fnd_file.LOG, 'Prepare and Send Email Notification');
  fnd_file.put_line (fnd_file.LOG, RPAD('From', 20, ' ') || ' - ' || v_from);
  FOR i IN 1..gc_target_value19
  LOOP
    fnd_file.put_line (fnd_file.LOG, RPAD('To', 20, ' ') || ' - ' || l_to_tbl(i));
  END LOOP;
  FOR i IN 1..gc_target_value20
  LOOP
    fnd_file.put_line (fnd_file.LOG, RPAD('Cc', 20, ' ') || ' - ' || l_cc_tbl(i));
  END LOOP;
  fnd_file.put_line (fnd_file.LOG, RPAD('Subject', 20, ' ') || ' - ' || v_subject);
  fnd_file.put_line (fnd_file.LOG, RPAD('Email Server', 20, ' ') || ' - ' || v_mail_host);
  SELECT instance_name,host_name INTO lc_instance,lc_host_name FROM v$instance;
  BEGIN
    v_mail_conn := utl_smtp.open_connection(v_mail_host,25);
    utl_smtp.helo(v_mail_conn,v_mail_host);
    utl_smtp.mail(v_mail_conn,v_from);
    FOR i IN 1..gc_target_value19
    LOOP
      utl_smtp.rcpt(v_mail_conn,l_to_tbl(i));
    END LOOP;
    FOR i IN 1..gc_target_value20
    LOOP
      utl_smtp.rcpt(v_mail_conn,l_cc_tbl(i));
    END LOOP;
    utl_smtp.DATA(v_mail_conn,'Return-Path: ' || v_from || utl_tcp.crlf || 
    'Sent: ' || TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') || utl_tcp.crlf || 
    'From: ' || v_from || utl_tcp.crlf || 
    'Subject: ' || v_subject || ' | ' || lc_instance ||utl_tcp.crlf || 
    'To: ' || l_to_list || utl_tcp.crlf || 
    'Cc: ' || l_cc_list || utl_tcp.crlf || 
    'Content-Type: multipart/mixed; boundary="MIME.Bound"' ||utl_tcp.crlf || utl_tcp.crlf || '--MIME.Bound' || utl_tcp.crlf || 'Content-Type: multipart/alternative; boundary="MIME.Bound2"' 
    || utl_tcp.crlf || utl_tcp.crlf || '--MIME.Bound2' || utl_tcp.crlf || 'Content-Type: text/html; ' || utl_tcp.crlf || 'Content-Transfer_Encoding: 7bit' || utl_tcp.crlf ||utl_tcp.crlf || utl_tcp.crlf ||'<html><head><title>'||lc_title_html||'</title></head>       
    <body> <font face = "verdana" size = "2" color="#336699">'||lc_body_hdr_html||'<br><br>'||lc_body_dtl_html||'<br><br><b> Note </b> - ' ||gc_target_value9 || '                
    <br><hr></font></body></html>' || utl_tcp.crlf || '--MIME.Bound2--' || utl_tcp.crlf || utl_tcp.crlf);
    utl_smtp.quit(v_mail_conn);
    p_return_status := 'SUCCESS';
    gc_mainp_status := 'SUCCESS';
    fnd_file.put_line (fnd_file.LOG, 'Exiting the procedure - prepare_and_send_email');
  EXCEPTION
  WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
    lc_body_hdr_html := lc_body_hdr_html || '<br> <b> ' || gc_target_value15 || ' </b><br> Error Details : ' || SQLERRM;
    fnd_file.put_line (fnd_file.LOG, 'Exception at PROCEDURE prepare_and_send_email : ' || SQLERRM);
    p_return_status := 'FAILURE';
    gc_mainp_status := 'FAILURE';
    
    WHEN OTHERS THEN
    fnd_file.put_line (fnd_file.LOG, 'Exception at PROCEDURE prepare_and_send_email : ' || SQLERRM);
    p_return_status := 'FAILURE';
    END;

END prepare_and_send_email;

-- +============================================================================+
-- | Name             : GET_RECORD_COUNT                                        |
-- |                                                                            |
-- | Description      : This procedure will fetch record counts for lockbox     |
-- |                    files of a given date and send the data to business.    |
-- |                                                                            |
-- | Parameters       : x_err_buf OUT VARCHAR2                                  |
-- |                  : x_ret_code    OUT  VARCHAR2                             |
-- |                  : p_cycle_date IN VARCHAR2 --Cycle Date                   |
-- |                  : p_send_mail IN VARCHAR2                                 |
-- |                                                                            |
-- | Change Record:                                                             |
-- | ==============                                                             |
-- | Version  Date         Author          Remarks                              |
-- | =======  ===========  =============   ===================================  |
-- | 1.0      17-Apr-2012  Archana N.      Initial version - QC Defect # 20100  |
-- +============================================================================+

PROCEDURE get_record_count(
    x_err_buf OUT VARCHAR2,
    x_ret_code OUT VARCHAR2,
    p_cycle_date IN VARCHAR2,
    p_send_mail  IN VARCHAR2)
IS
TYPE rec_lb_rec_count IS RECORD(
    lc_rec_fname xx_ar_lbx_wrapper_temp_history.exact_file_name%type,
    lc_rec_count xx_ar_lbx_wrapper_temp_history.transmission_record_count%type);
  lc_rec_lb_rec_count rec_lb_rec_count;
TYPE t_lb_rec_count IS TABLE OF rec_lb_rec_count;
  lc_tbl_lb_rec_count t_lb_rec_count := t_lb_rec_count();
  lc_tbl_hdr1   VARCHAR2(100)          := 'Filename';
  lc_tbl_hdr2   VARCHAR2(100)          := 'Record Count';
  lc_email_flag VARCHAR2(16)           := p_send_mail;
  lc_cdate DATE                        := TRUNC(to_date(p_cycle_date,'YYYY/MM/DD HH24:MI:SS'));
  lc_cdate2     VARCHAR2(50) ;
  lc_str        VARCHAR2(1000) ;
  l_comp_status BOOLEAN;
  lc_row_count  NUMBER := 0;
  lc_rec_tbl    VARCHAR2(3000);
BEGIN
  fnd_file.put_line (fnd_file.LOG,'Entering the procedure - get_record_count');
  lc_tbl_lb_rec_count.EXTEND(30);
  SELECT TO_CHAR(lc_cdate,'YYYYMMDD') INTO lc_cdate2 FROM dual;
  fnd_file.put_line (fnd_file.LOG,'Cyle Date for record count : '||lc_cdate2);
  lc_str := 'SELECT exact_file_name,transmission_record_count from xx_ar_lbx_wrapper_temp_history where exact_file_name like ''LB_%'||lc_cdate2||'%''' ;
  EXECUTE IMMEDIATE lc_str BULK COLLECT INTO lc_tbl_lb_rec_count ;
  IF SQL%notfound THEN
    fnd_file.put_line (fnd_file.LOG,'No data exists for the given cycle date');
    RETURN;
  END IF;
  --invoking the get_file_schedule to get the list of missing and received lockbox files
  get_lb_file_data(lc_cdate);
  fnd_file.put_line (fnd_file.output,'Record count data fetched from cursor for cycle date - '||lc_cdate2);
  FOR indx IN lc_tbl_lb_rec_count.FIRST..lc_tbl_lb_rec_count.LAST
  LOOP
    fnd_file.put_line (fnd_file.output, lc_tbl_lb_rec_count(indx).lc_rec_fname||' '||lc_tbl_lb_rec_count(indx).lc_rec_count);
  END LOOP;
  IF (lc_email_flag = 'Y') THEN
    fnd_file.put_line (fnd_file.LOG,'Preparing to send email ..');
    SELECT def.target_field1,val.target_value1
    INTO lc_source_field1,lc_source_value1
    FROM xxfin.xx_fin_translatedefinition def,
      xxfin.xx_fin_translatevalues val
    WHERE def.translate_id   = val.translate_id
    AND def.translation_name = 'AR_EBL_EMAIL_CONFIG'
    AND def.target_field1    = 'SMTP_SERVER'
    AND def.enabled_flag     = 'Y'
    AND val.enabled_flag     = 'Y'
    AND SYSDATE BETWEEN def.start_date_active AND NVL (def.end_date_active, SYSDATE + 1)
    AND SYSDATE BETWEEN val.start_date_active AND NVL (val.end_date_active, SYSDATE + 1);
    lc_mail_host := lc_source_value1;
    get_translations(p_debug_flag,'XX_AR_LB_EMAIL_FORMAT','Record Count');
    FOR indx IN lc_tbl_lb_rec_count.FIRST..lc_tbl_lb_rec_count.LAST
    LOOP
      lc_rec_tbl  := lc_rec_tbl||'<tr><td>'||lc_tbl_lb_rec_count(indx).lc_rec_fname||'</td><td>'||lc_tbl_lb_rec_count(indx).lc_rec_count||'</td></tr>';
      lc_row_count:=lc_row_count+1;
    END LOOP;
    fnd_file.put_line (fnd_file.LOG,'count of rows : '||lc_row_count);
    IF ln_recd_fcount <> 0 THEN --table check loop
      fnd_file.put_line (fnd_file.LOG,'One or more lockbox files have been received for this cycle date ');
      lc_from          := gc_target_value1;
      l_to_tbl(1)      := gc_target_value11;
      l_to_tbl(2)      := gc_target_value12;
      l_to_tbl(3)      := gc_target_value13;
      l_to_tbl(4)      := gc_target_value14;
      l_cc_tbl(1)      := gc_target_value15;
      l_cc_tbl(2)      := gc_target_value16;
      l_cc_tbl(3)      := gc_target_value17;
      l_cc_tbl(4)      := gc_target_value18;
      lc_subject       := gc_target_value2||TO_CHAR(lc_cdate,'MM/DD');
      lc_title_html    := gc_target_value3;
      lc_body_hdr_html := '<font color="#990000">'||gc_target_value4||'<br><br>'||gc_target_value5||' '||TO_CHAR(lc_cdate,'MM/DD')||'<br>';
      lc_body_dtl_html := '<table border="1"><tr><th>'||lc_tbl_hdr1||'</th><th>'||lc_tbl_hdr2||'</th></tr>'||lc_rec_tbl||'</table>';
      lc_missing_txt   := '<br>'||gc_target_value6||TO_CHAR(lc_cdate,'MM/DD');
      IF ln_recd_fcount = ln_exp_fcount THEN
        fnd_file.put_line (fnd_file.LOG,'case 1 : all expected files have been received');
        prepare_and_send_email ( p_debug_flag => p_debug_flag, 
                                 p_from => lc_from, 
                                 p_to_tbl => l_to_tbl, 
                                 p_cc_tbl => l_cc_tbl, 
                                 p_mail_host => lc_mail_host, 
                                 p_subject => lc_subject, 
                                 p_title_html => lc_title_html, 
                                 p_body_hdr_html => lc_body_hdr_html, 
                                 p_body_dtl_html => lc_body_dtl_html,  
                                 p_return_status => lc_email_status );
      ELSE
        fnd_file.put_line (fnd_file.LOG,'case 2 : Some files are missing and this needs to communicated');
        lc_body_dtl_html := lc_body_dtl_html||lc_missing_txt||'<br><br>';
        --adding the list of missing files to the email alert
        FOR i IN lc_missing_list.FIRST..lc_missing_list.LAST
        LOOP
          lc_body_dtl_html := lc_body_dtl_html||lc_missing_list(i)||'<br><br>';
        END LOOP;
        prepare_and_send_email ( p_debug_flag => p_debug_flag, 
                                 p_from => lc_from, 
                                 p_to_tbl => l_to_tbl, 
                                 p_cc_tbl => l_cc_tbl, 
                                 p_mail_host => lc_mail_host, 
                                 p_subject => lc_subject, 
                                 p_title_html => lc_title_html, 
                                 p_body_hdr_html => lc_body_hdr_html, 
                                 p_body_dtl_html => lc_body_dtl_html,  
                                 p_return_status => lc_email_status );
      END IF;
    ELSE
      fnd_file.put_line (fnd_file.LOG,'No lockbox files have been received for this cycle date');
      lc_from          := gc_target_value1;
      l_to_tbl(1)      := gc_target_value11;
      l_to_tbl(2)      := gc_target_value12;
      l_to_tbl(3)      := gc_target_value13;
      l_to_tbl(4)      := gc_target_value14;
      l_cc_tbl(1)      := gc_target_value15;
      l_cc_tbl(2)      := gc_target_value16;
      l_cc_tbl(3)      := gc_target_value17;
      l_cc_tbl(4)      := gc_target_value18;
      lc_subject       := gc_target_value2||TO_CHAR(lc_cdate,'MM/DD');
      lc_title_html    := gc_target_value3;
      lc_body_hdr_html := '<font color="#990000">'||gc_target_value4||'<br><br>'||'Please find below the details of lockbox files for cycle date - '||' '||TO_CHAR(lc_cdate,'MM/DD')||'<br> None of the files have been received.';
      lc_missing_txt   := '<br>'||gc_target_value6||TO_CHAR(lc_cdate,'MM/DD');
      lc_body_dtl_html := lc_body_dtl_html||lc_missing_txt||'<br><br>';
      --adding the list of missing files to the email alert
      FOR i IN lc_missing_list.FIRST..lc_missing_list.LAST
      LOOP
        lc_body_dtl_html := lc_body_dtl_html||lc_missing_list(i)||'<br><br>';
      END LOOP;
      prepare_and_send_email ( p_debug_flag => p_debug_flag, 
                               p_from => lc_from, 
                               p_to_tbl => l_to_tbl, 
                               p_cc_tbl => l_cc_tbl, 
                               p_mail_host => lc_mail_host, 
                               p_subject => lc_subject, 
                               p_title_html => lc_title_html, 
                               p_body_hdr_html => lc_body_hdr_html, 
                               p_body_dtl_html => lc_body_dtl_html, 
                               p_return_status => lc_email_status );
    END IF; -- closing table structure check loop
  END IF;
  IF x_ret_code    = 1 THEN
    l_comp_status := fnd_concurrent.set_completion_status('WARNING',NULL);
  END IF;
  fnd_file.put_line (fnd_file.LOG,'Exiting the procedure - get_record_count');
  EXCEPTION
  WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG, 'Exception at PROCEDURE get_record_count : ' || SQLERRM);
  RETURN;
  
END get_record_count;

-- +============================================================================+
-- | Name             : GET_LBX_STATS                                           |
-- |                                                                            |
-- | Description      : This procedure will fetch lockbox details and send email|
-- |                    alert to AMS batch team.                                |
-- |                                                                            |
-- | Parameters       : x_err_buf OUT VARCHAR2                                  |
-- |                  : x_ret_code    OUT  VARCHAR2                             |
-- |                  : p_cycle_date IN VARCHAR2 --Cycle Date                   |
-- |                                                                            |
-- | Change Record:                                                             |
-- | ==============                                                             |
-- | Version  Date         Author          Remarks                              |
-- | =======  ===========  =============   ===================================  |
-- | 1.0      17-Apr-2012  Archana N.      Initial version - QC Defect # 20100  |
-- +============================================================================+

PROCEDURE get_lbx_stats(
    x_err_buf OUT VARCHAR2,
    x_ret_code OUT VARCHAR2,
    p_cycle_date IN VARCHAR2)
IS
  lc_cdate DATE := TRUNC(to_date(p_cycle_date,'YYYY/MM/DD HH24:MI:SS'));
BEGIN
  fnd_file.put_line (fnd_file.LOG, 'Begin procedure - get_lbx_stats');
  get_lb_file_data(lc_cdate);
  get_translations(p_debug_flag,'XX_AR_LB_EMAIL_FORMAT','Test Run');
  lc_from          := gc_target_value1;
  lc_subject       := gc_target_value2;
  lc_title_html    := gc_target_value3;
  lc_body_hdr_html := gc_target_value4;
  l_to_tbl(1)      := gc_target_value11;
  l_to_tbl(2)      := gc_target_value12;
  l_to_tbl(3)      := gc_target_value13;
  l_to_tbl(4)      := gc_target_value14;
  l_cc_tbl(1)      := gc_target_value15;
  l_cc_tbl(2)      := gc_target_value16;
  l_cc_tbl(3)      := gc_target_value17;
  l_cc_tbl(4)      := gc_target_value18;
  SELECT def.target_field1,
    val.target_value1
  INTO lc_source_field1,
    lc_source_value1
  FROM xxfin.xx_fin_translatedefinition def,
    xxfin.xx_fin_translatevalues val
  WHERE def.translate_id   = val.translate_id
  AND def.translation_name = 'AR_EBL_EMAIL_CONFIG'
  AND def.target_field1    = 'SMTP_SERVER'
  AND def.enabled_flag     = 'Y'
  AND val.enabled_flag     = 'Y'
  AND SYSDATE BETWEEN def.start_date_active AND NVL (def.end_date_active, SYSDATE + 1)
  AND SYSDATE BETWEEN val.start_date_active AND NVL (val.end_date_active, SYSDATE + 1);
  lc_mail_host       := lc_source_value1;
  IF ((ln_recd_fcount = ln_exp_fcount) AND lc_holiday_flag = 'N') THEN
    fnd_file.put_line (fnd_file.LOG, 'case 1: All files received, there is no bank holiday');
    lc_subject           := lc_subject || TO_CHAR(lc_cdate, 'MM/DD') || ' (No Action Required)';
    lc_body_hdr_html     := '<font face = "verdana" size = "3" color="#990000">'||lc_body_hdr_html ||'<br> <p align = "CENTER"> <b> <u>'
    || ' - No Action Required (Count of Lockbox files received is equal to expected count) for Cycle Date ' || TO_CHAR(lc_cdate, 'MM/DD') 
    || '</u></b></p></font>';
    lc_body_dtl_html     := '<font color="#990000"><b>' || gc_target_value5 || TO_CHAR(lc_cdate, 'MM/DD') || ' </b> <br><br> <b>' 
    || gc_target_value6 || ln_exp_fcount || ' </b> <br><br><b>' || gc_target_value7 || ln_recd_fcount || ' </b> <br><br>';
  ELSIF ((ln_recd_fcount <> ln_exp_fcount) AND lc_holiday_flag = 'N') THEN
    fnd_file.put_line (fnd_file.LOG, 'case 2: All files have not been received , there is no bank holiday');
    --case 2 Action needed
    lc_subject       := lc_subject || TO_CHAR(lc_cdate, 'MM/DD') ||' (Action Required)';
    lc_body_hdr_html := '<font face = "verdana" size = "3" color="#990000">'||lc_body_hdr_html ||'<br> <p align = "CENTER"> <b> <u>' 
    || ' <br> Action Required (Count of Lockbox files received is NOT equal to expected count) for Cycle Date ' || TO_CHAR(lc_cdate, 'MM/DD') 
    || '</u></b></p></font>';
    lc_body_dtl_html := '<font color="#990000"><b>' || gc_target_value5 || TO_CHAR(lc_cdate, 'MM/DD') || ' </b> <br><br> <b>' 
    || gc_target_value6 || ln_exp_fcount ||' </b> <br><br><b>' || gc_target_value7 || ln_recd_fcount || ' </b> <br><br><b>' 
    || gc_target_value8 || ' </b> <br><br>';
    --adding list of missing files
    FOR i IN lc_missing_list.FIRST..lc_missing_list.LAST
    LOOP
      lc_body_dtl_html := lc_body_dtl_html||lc_missing_list(i)||'<br><br>';
    END LOOP;
  ELSIF ((ln_recd_fcount <> ln_exp_fcount) AND lc_holiday_flag = 'Y') THEN
    fnd_file.put_line (fnd_file.LOG, 'case 3: All files have not been received , could be due to bank holiday - '||lc_holiday);
    lc_subject       := lc_subject || TO_CHAR(lc_cdate, 'MM/DD') ||' (Action Required)';
    lc_body_hdr_html := '<font face = "verdana" size = "3" color="#990000">'||lc_body_hdr_html ||'<br> <p align = "CENTER"> <b> <u>' 
    || ' <br> Action Required (Count of Lockbox files received is NOT equal to expected count) for Cycle Date ' || TO_CHAR(lc_cdate, 'MM/DD')
    || '</u></b></p></font>';
    lc_body_dtl_html := '<font color="#990000"><b>' || gc_target_value5 || TO_CHAR(lc_cdate, 'MM/DD') || ' </b> <br><br> <b>' 
    || gc_target_value6 || ln_exp_fcount ||' </b> <br><br><b>' || gc_target_value7 || ln_recd_fcount || ' </b> <br><br><b>' 
    || gc_target_value8 || '<br> Missing files could be due to bank holiday - '||lc_holiday||' </b> <br><br>';
    --adding list of missing files
    FOR i IN lc_missing_list.FIRST..lc_missing_list.LAST
    LOOP
      lc_body_dtl_html := lc_body_dtl_html||lc_missing_list(i)||'<br><br>';
    END LOOP;
  ELSIF ((ln_recd_fcount = ln_exp_fcount) AND lc_holiday_flag = 'E') THEN
    fnd_file.put_line (fnd_file.LOG, 'case 4: All files received, holiday details are missing');
    lc_subject           := lc_subject || TO_CHAR(lc_cdate, 'MM/DD') || ' (No Action Required)';
    lc_body_hdr_html     := '<font face = "verdana" size = "3" color="#990000">'||lc_body_hdr_html ||'<br> <p align = "CENTER"> <b> <u>'
    || ' - No Action Required (Count of Lockbox files received is equal to expected count) for Cycle Date ' || TO_CHAR(lc_cdate, 'MM/DD')
    || '</u></b></p></font>';
    lc_body_dtl_html     := '<font color="#990000"><b>' || gc_target_value5 || TO_CHAR(lc_cdate, 'MM/DD') || ' </b> <br><br> <b>' 
    || gc_target_value6 || ln_exp_fcount || ' </b> <br><br><b>' || gc_target_value7 || ln_recd_fcount || ' </b> <br><br>';
  ELSIF ((ln_recd_fcount <> ln_exp_fcount) AND lc_holiday_flag = 'E') THEN
    fnd_file.put_line (fnd_file.LOG, 'case 5: All files have not been received, holiday details are missing ');
    lc_subject       := lc_subject || TO_CHAR(lc_cdate, 'MM/DD') ||' (Action Required)';
    lc_body_hdr_html := '<font face = "verdana" size = "3" color="#990000">'||lc_body_hdr_html ||'<br> <p align = "CENTER"> <b> <u>' 
    || ' <br> Action Required (Count of Lockbox files received is NOT equal to expected count) for Cycle Date ' || TO_CHAR(lc_cdate, 'MM/DD')
    || '</u></b></p></font>';
    lc_body_dtl_html := '<font color="#990000"><b>' || gc_target_value5 || TO_CHAR(lc_cdate, 'MM/DD') || ' </b> <br><br> <b>' 
    || gc_target_value6 || ln_exp_fcount ||' </b> <br><br><b>' || gc_target_value7 || ln_recd_fcount || ' </b> <br><br><b>' 
    || gc_target_value8 || '<br> </b> <br><br>';
    FOR i IN lc_missing_list.FIRST..lc_missing_list.LAST
    LOOP
      lc_body_dtl_html := lc_body_dtl_html||lc_missing_list(i)||'<br><br>';
    END LOOP;
  END IF;
  prepare_and_send_email ( p_debug_flag => p_debug_flag, 
                           p_from => lc_from, 
                           p_to_tbl => l_to_tbl, 
                           p_cc_tbl => l_cc_tbl, 
                           p_mail_host => lc_mail_host, 
                           p_subject => lc_subject, 
                           p_title_html => lc_title_html, 
                           p_body_hdr_html => lc_body_hdr_html, 
                           p_body_dtl_html => lc_body_dtl_html, 
                           p_return_status => lc_email_status );
  fnd_file.put_line (fnd_file.LOG, 'PROCEDURE prepare_and_send_email   - Return Status : ' || lc_email_status);
  IF lc_email_status = 'SUCCESS' THEN
    fnd_file.put_line (fnd_file.LOG, 'Email Notification Successfully Sent.');
    gc_mainp_status := 'SUCCESS';
  ELSE
    fnd_file.put_line (fnd_file.LOG, 'Email Notification Not Sent.');
    gc_mainp_status := 'FAILURE';
  END IF;
  fnd_file.put_line (fnd_file.LOG, 'End of procedure - get_lbx_stats');
  EXCEPTION
  WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG, 'Exception at PROCEDURE get_lbx_stats : ' || SQLERRM);
  RETURN;
END get_lbx_stats;
END XX_AR_LBX_BATCH_ALERT;
/
