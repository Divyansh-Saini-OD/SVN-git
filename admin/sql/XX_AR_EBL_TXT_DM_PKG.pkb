create or replace PACKAGE BODY XX_AR_EBL_TXT_DM_PKG
AS
  -- +====================================================================================+
  -- |                  Office Depot - Project Simplify                                   |
  -- +====================================================================================+
  -- | Name        : XX_AR_EBL_TXT_MASTER_PROG                                            |
  -- | Description : This Procedure is used for multi threading the etxt data into        |
  -- |               batches and to submit the child procedure XX_AR_EBL_TXT_CHILD_PROG   |
  -- |               for every batch                                                      |
  -- |Parameters   :  p_debug_flag                                                        |
  -- |               ,p_batch_size                                                        |
  -- |               ,p_thread_cnt                                                        |
  -- |               ,p_doc_type                                                          |
  -- |               ,p_cycle_date                                                        |
  -- |               ,p_delivery_method                                                   |
  -- |Change Record:                                                                      |
  -- |===============                                                                     |
  -- |Version    Date          Author                 Remarks                             |
  -- |=======    ==========   =============           ====================================|
  -- |DRAFT 1.0  04-MAR-2016  Suresh N                Initial draft version               |
  -- |                                               (Master Defect#37585)                |
  -- |      1.1  14-FEB-2017  Punit Gupta CG          Requirement# (2282,2302,40015)      |
  -- |      1.2  24-FEB-2017  Suresh N                Changes for Defect#40027,38962      |
  -- |      1.3  15-APR-2017  Punit Gupta CG          Changes for Defect#41733,41793,41784|
  -- |      1.4  25-MAY-2017  Punit Gupta CG          Changes for Defect #42226           |
  -- |      1.5  05-JUN-2017  Punit Gupta CG          Changes for Defect#42312            |
  -- |      1.6  05-JUN-2017  Suresh Naragam          Changes for the Defect#42322        |
  -- |      1.7  12-JUN-2017  Punit Gupta CG          Changes for the Defect#42381        |
  -- |      1.8  21-JUN-2017  Punit Gupta CG          Changes for the Defect#42496        |
  -- |      1.9  05-JUL-2017  Punit Gupta CG          Changes for the Defect#39140        |
  -- |      1.10 25-JUL-2017  Thilak Kumar CG         Changes for the Defect#42380,40174  |
  -- |      1.11 05-DEC-2017  Thilak Kumar CG         Changes for the Defect#14525        |
  -- |      1.12 12-DEC-2017  Thilak Kumar CG         Changes for the Defect#42790,21270  |
  -- |      1.13 15-Dec-2017  Aniket J     CG         Changes for Defect#22772            |
  -- |      1.14 22-Jan-2018  Aniket J     CG         Changes for Defect#24883            |
  -- |      1.15 01-Mar-2018  Thilak Kumar CG         Changes for Defect#29739            |
  -- |      1.16 15-May-2018  Aniket J     CG         Changes for Requirement  #NAIT-29364|
  -- |      1.17 09-JUN-2018  Thilak       CG         Changes for Requirement#NAIT-17796  |
  -- |      1.18 16-JUL-2018  Aniket J     CG         Changes for Requirement#NAIT-50280  |
  -- |      1.19 20-JUN-2020  Divyansh Saini          Changes done for NAIT-129167        |
  -- +====================================================================================+
PROCEDURE XX_AR_EBL_TXT_MASTER_PROG(
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER ,
    p_debug_flag IN VARCHAR2 ,
    p_batch_size IN NUMBER ,
    p_thread_cnt IN NUMBER ,
    p_doc_type   IN VARCHAR2 -- ( IND/CONS)
    ,
    p_cycle_date      IN VARCHAR2 ,
    p_delivery_method IN VARCHAR2 )
IS
  ln_org_id            NUMBER                := fnd_profile.value('ORG_ID');
  lc_conc_pgm_name     VARCHAR2(50)          := 'XXAREBLTXTC';
  lc_appl_short_name   CONSTANT VARCHAR2(50) := 'XXFIN';
  ln_request_id        NUMBER ;
  lc_request_data      VARCHAR2(15);
  ln_cnt_err_request   NUMBER;
  ln_cnt_war_request   NUMBER;
  ln_parent_request_id NUMBER;
  lc_err_location_msg  VARCHAR2(1000);
  lb_debug_flag        BOOLEAN;
  ln_thread_count      NUMBER := 0;
  lc_batch_id xx_ar_ebl_cons_hdr_main.batch_id%TYPE;
  lc_status VARCHAR2(20) := 'MANIP_READY';
TYPE lcu_batch_id
IS
  REF
  CURSOR;
    get_batch_id lcu_batch_id;
  BEGIN
    IF (p_debug_flag = 'Y') THEN
      lb_debug_flag := TRUE;
    ELSE
      lb_debug_flag := FALSE;
    END IF;
    lc_err_location_msg := 'Parameters ==>' || CHR(13) || 'Debug flag : ' || p_debug_flag || CHR(13) || 'Batch_size : ' || p_batch_size || CHR(13) || 'Thread_count : ' || p_thread_cnt || CHR(13) || 'Document type : ' || p_doc_type || CHR(13) || 'Cycle Date :' || p_cycle_date;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
    ln_parent_request_id := fnd_global.conc_request_id;
    lc_request_data      :=FND_CONC_GLOBAL.request_data;
    IF ( lc_request_data IS NULL) THEN
      XX_AR_EBL_COMMON_UTIL_PKG.MULTI_THREAD(p_batch_size,p_thread_cnt,p_debug_flag,p_delivery_method,ln_parent_request_id,p_doc_type,lc_status,p_cycle_date);
      IF( p_doc_type = 'CONS') THEN
        OPEN get_batch_id FOR
        SELECT DISTINCT XAECHM.batch_id
        FROM xx_ar_ebl_cons_hdr_main XAECHM
          --V1.1    ,xx_ar_ebl_file XAEF
        WHERE XAECHM.billdocs_delivery_method = p_delivery_method
        AND XAECHM.status                     = 'MARKED_FOR_RENDER'
        AND XAECHM.org_id                     = ln_org_id;
      lc_err_location_msg                    := 'Opening Cursor for Consolidated document';
    END IF;
    LOOP
      FETCH get_batch_id INTO lc_batch_id;
      EXIT
    WHEN get_batch_id%NOTFOUND;
      ln_request_id := FND_REQUEST.SUBMIT_REQUEST ( application => lc_appl_short_name ,program => lc_conc_pgm_name ,description => NULL ,start_time => NULL ,sub_request => TRUE ,argument1 => lc_batch_id ,argument2 => p_doc_type ,argument3 => p_debug_flag ,argument4 => p_cycle_date );
      COMMIT;
      lc_err_location_msg := 'Submitted child for the batch ID ' || lc_batch_id;
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
      ln_thread_count := ln_thread_count + 1;
    END LOOP;
    IF ln_thread_count >0 THEN
      FND_CONC_GLOBAL.set_req_globals( conc_status => 'PAUSED',request_data => 'COMPLETE');
      lc_err_location_msg := 'Submitted ' || ln_thread_count ||' Child programs';
      ln_thread_count     := 0;
    ELSE
      lc_err_location_msg := 'There is no data in the extraction table for manipulation program to process.';
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
    END IF;
  ELSE
    SELECT COUNT(*)
    INTO ln_cnt_err_request
    FROM fnd_concurrent_requests
    WHERE parent_request_id = ln_parent_request_id
    AND phase_code          = 'C'
    AND status_code         = 'E';
    SELECT COUNT(*)
    INTO ln_cnt_war_request
    FROM fnd_concurrent_requests
    WHERE parent_request_id = ln_parent_request_id
    AND phase_code          = 'C'
    AND status_code         = 'G';
    IF ln_cnt_war_request  <> 0 THEN
      lc_err_location_msg  := ln_cnt_err_request ||' Child Requests are Warning Out.Please, Check the Child Requests LOG for Details';
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
      x_ret_code := 1;
    END IF;
    IF ln_cnt_err_request <> 0 THEN
      lc_err_location_msg := ln_cnt_err_request ||' Child Requests Errored Out.Please, Check the Child Requests LOG for Details';
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
      x_ret_code := 2;
    END IF;
    IF (ln_cnt_war_request = 0 AND ln_cnt_err_request = 0) THEN
      lc_err_location_msg := ' OD: AR EBL Individual Data Manipluation TXT Parent program Completed Successfully';
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  x_ret_code := 1;
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,'ERROR in XX_AR_EBL_TXT_MASTER_PROG: ' || SQLERRM || CHR(13) || 'Code Location : ' || lc_err_location_msg );
END XX_AR_EBL_TXT_MASTER_PROG;
-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : xx_ar_ebl_txt_update_status                                         |
-- | Description : This Procedure is used to update the error/render status in         |
-- |               xx_ar_ebl_file table                                                |
-- |Parameters   : p_cust_doc_id                                                       |
-- |             , p_extract_batch_id                                                  |
-- |             , p_batch_id                                                          |
-- |             , p_status                                                            |
-- |             , p_error_msg                                                         |
-- |             , p_doc_type                                                          |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
PROCEDURE xx_ar_ebl_txt_update_status(
    p_cust_doc_id      IN NUMBER ,
    p_extract_batch_id IN NUMBER ,
    p_batch_id         IN NUMBER ,
    p_status           IN VARCHAR2 ,
    p_error_msg        IN VARCHAR2 ,
    p_doc_type         IN VARCHAR2 )
IS
BEGIN
  IF p_doc_type = 'IND' THEN
    NULL;
    /*UPDATE xx_ar_ebl_ind_hdr_main
    SET status             = p_error_msg
    ,request_id         = fnd_global.conc_request_id
    ,last_updated_by    = fnd_global.user_id
    ,last_updated_date  = sysdate
    ,last_updated_login = fnd_global.user_id
    WHERE parent_cust_doc_id = p_cust_doc_id
    AND   extract_batch_id   = p_extract_batch_id
    AND   batch_id           = p_batch_id;
    UPDATE XX_AR_EBL_FILE
    SET status_detail      = p_error_msg
    ,status             = p_status
    ,last_updated_by     = fnd_global.user_id
    ,last_update_date   = sysdate
    ,last_update_login = fnd_global.user_id
    WHERE file_id IN (SELECT file_id
    FROM   xx_ar_ebl_ind_hdr_main
    WHERE  parent_cust_doc_id = p_cust_doc_id
    AND   extract_batch_id    = p_extract_batch_id
    AND   batch_id            = p_batch_id); */
  ELSIF p_doc_type = 'CONS' THEN
    UPDATE xx_ar_ebl_cons_hdr_main
    SET status               = p_error_msg ,
      request_id             = fnd_global.conc_request_id ,
      last_updated_by        = fnd_global.user_id ,
      last_updated_date      = sysdate ,
      last_updated_login     = fnd_global.user_id
    WHERE parent_cust_doc_id = p_cust_doc_id
    AND extract_batch_id     = p_extract_batch_id
    AND batch_id             = p_batch_id;
    UPDATE XX_AR_EBL_FILE
    SET status_detail   = p_error_msg ,
      status            = p_status ,
      file_data         = EMPTY_BLOB() ,
      last_updated_by   = fnd_global.user_id ,
      last_update_date  = sysdate ,
      last_update_login = fnd_global.user_id
    WHERE file_id      IN
      (SELECT file_id
      FROM xx_ar_ebl_cons_hdr_main
      WHERE parent_cust_doc_id = p_cust_doc_id
      AND extract_batch_id     = p_extract_batch_id
      AND batch_id             = p_batch_id
      );
  END IF;
END xx_ar_ebl_txt_update_status;
-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : xx_ar_ebl_txt_update_status                                         |
-- | Description : This Procedure is used to update the error/render status in         |
-- |               xx_ar_ebl_file table                                                |
-- |Parameters   : p_cust_doc_id                                                       |
-- |             , p_extract_batch_id                                                  |
-- |             , p_batch_id                                                          |
-- |             , p_status                                                            |
-- |             , p_error_msg                                                         |
-- |             , p_doc_type                                                          |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
PROCEDURE xx_ar_ebl_txt_update_status(
    p_batch_id        IN NUMBER ,
    p_hdr_from_status IN VARCHAR2 ,
    p_hdr_to_status   IN VARCHAR2 ,
    p_ebl_from_status IN VARCHAR2 ,
    p_ebl_to_status   IN VARCHAR2 ,
    p_doc_type        IN VARCHAR2 )
IS
BEGIN
  IF p_doc_type = 'IND' THEN
    NULL;
    /*UPDATE xx_ar_ebl_ind_hdr_main
    SET status = p_hdr_to_status
    ,request_id         = fnd_global.conc_request_id
    ,last_updated_by    = fnd_global.user_id
    ,last_updated_date  = sysdate
    ,last_updated_login = fnd_global.user_id
    WHERE batch_id          = p_batch_id
    AND   status = p_hdr_from_status;
    UPDATE XX_AR_EBL_FILE XAEF
    SET XAEF.status             = p_ebl_to_status
    ,last_updated_by    = fnd_global.user_id
    ,last_update_date   = sysdate
    ,last_update_login  = fnd_global.user_id
    WHERE EXISTS ( SELECT 1
    FROM   xx_ar_ebl_ind_hdr_main
    WHERE  file_id            = XAEF.file_id
    AND    batch_id           = p_batch_id )
    AND XAEF.status             = p_ebl_from_status;*/
  ELSIF p_doc_type = 'CONS' THEN
    UPDATE xx_ar_ebl_cons_hdr_main
    SET status           = p_hdr_to_status ,
      request_id         = fnd_global.conc_request_id ,
      last_updated_by    = fnd_global.user_id ,
      last_updated_date  = sysdate ,
      last_updated_login = fnd_global.user_id
    WHERE batch_id       = p_batch_id
    AND status           = p_hdr_from_status;
    UPDATE XX_AR_EBL_FILE XAEF
    SET XAEF.status     = p_ebl_to_status ,
      xaef.file_data    = EMPTY_BLOB() ,
      last_updated_by   = fnd_global.user_id ,
      last_update_date  = sysdate ,
      last_update_login = fnd_global.user_id
    WHERE EXISTS
      (SELECT 1
      FROM xx_ar_ebl_cons_hdr_main
      WHERE file_id = XAEF.file_id
      AND batch_id  = p_batch_id
      )
    AND XAEF.status = p_ebl_from_status;
  END IF;
END xx_ar_ebl_txt_update_status;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : xx_ar_ebl_txt_update_seq_num                                        |
-- | Description : This Procedure is used to update the sequence number by increment 1 |
-- |               for the given cust doc id                                           |
-- |Parameters   : file_id, cust_doc_id, column_name, record_type                      |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-DEC-2015  Suresh N                Initial draft version               |
-- +===================================================================================+
PROCEDURE xx_ar_ebl_txt_update_seq_num(
    p_file_id     IN NUMBER ,
    p_cust_doc_id IN NUMBER ,
    p_column_name IN VARCHAR2 ,
    p_seq_num_fid IN NUMBER ,
    p_org_id      IN NUMBER ,
    p_debug_flag  IN VARCHAR2 ,
    p_error_flag OUT VARCHAR2)
IS
  CURSOR get_cust_trx_id
  IS
    SELECT DISTINCT customer_trx_id
    FROM xx_ar_ebl_txt_dtl_stg
    WHERE file_id   = p_file_id
    AND cust_doc_id = p_cust_doc_id
    AND rec_type   != 'FID'
    ORDER BY customer_trx_id;
  lc_update_sql          VARCHAR2(1000);
  lc_err_location_msg    VARCHAR2(1000);
  ln_get_current_seq_val NUMBER;
  ln_cust_trx_id         NUMBER;
  lb_debug_flag          BOOLEAN;
  ln_current_seq_val     NUMBER;
  ln_inc_seq_val         NUMBER;
BEGIN
  IF (p_debug_flag = 'Y') THEN
    lb_debug_flag := TRUE;
  ELSE
    lb_debug_flag := FALSE;
  END IF;
  lc_err_location_msg := 'Calling spl logic function to get the current seq num ';
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
  --ln_get_current_seq_val := xx_ar_ebl_txt_spl_logic_pkg.get_current_seq_num(p_cust_doc_id,p_file_id,p_org_id,'SEQUENCE_NUM');
  BEGIN
    SELECT DISTINCT seq_start_val,
      seq_inc_val
    INTO ln_current_seq_val,
      ln_inc_seq_val
    FROM xx_cdh_ebl_templ_dtl_txt
    WHERE cust_doc_id = p_cust_doc_id
    AND field_id      = p_seq_num_fid;
  EXCEPTION
  WHEN OTHERS THEN
    ln_current_seq_val  := NULL;
    ln_inc_seq_val      := NULL;
    lc_err_location_msg := 'Error While getting the current seq number and increment value.';
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
  END;
  lc_err_location_msg := 'Current Sequence Value is '||ln_current_seq_val||' Updating stg table sequence number by incrementing '||ln_inc_seq_val||' with current value.';
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
  OPEN get_cust_trx_id;
  LOOP
    FETCH get_cust_trx_id INTO ln_cust_trx_id;
    EXIT
  WHEN get_cust_trx_id%NOTFOUND;
    ln_current_seq_val  := ln_current_seq_val + ln_inc_seq_val;
    lc_update_sql       := 'UPDATE xx_ar_ebl_txt_dtl_stg SET '||p_column_name||' = '||ln_current_seq_val ||' WHERE customer_trx_id = '||ln_cust_trx_id||' AND rec_type != '||'''FID'''||' AND file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id;
    lc_err_location_msg := 'Update SQL is '||lc_update_sql;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
    EXECUTE IMMEDIATE lc_update_sql;
  END LOOP;
  --
  lc_err_location_msg := 'Updating Translation Value back with current running sequence number.';
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
  /*UPDATE xx_fin_translatevalues
  SET target_value7 = ln_current_seq_val
  WHERE translate_id = (SELECT translate_id FROM xx_fin_translatedefinition WHERE translation_name ='XX_AR_EBL_TXT_SPL_LOGIC')
  AND source_value3 = 'SEQUENCE_NUM'
  AND source_value1 = (SELECT account_number
  FROM hz_cust_accounts_all hcaa,
  xx_cdh_cust_acct_ext_b xccaeb
  WHERE xccaeb.cust_account_id = hcaa.cust_account_id
  AND xccaeb.n_ext_attr2 = p_cust_doc_id);*/
  --
  UPDATE xx_cdh_ebl_templ_dtl_txt
  SET seq_start_val = ln_current_seq_val
  WHERE cust_doc_id = p_cust_doc_id
  AND field_id      = p_seq_num_fid;
  --
  lc_err_location_msg := 'Sequence Number Updated Successfully.';
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
EXCEPTION
WHEN OTHERS THEN
  p_error_flag        := 'Y';
  lc_err_location_msg := 'Error While Updating Sequence Number '||SQLCODE||' - '||SUBSTR(sqlerrm,1,255);
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,TRUE ,lc_err_location_msg );
END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : xx_ar_ebl_txt_update_dist_num                                       |
-- | Description : This Procedure is used to update the sequence number by increment 1 |
-- |               for the given cust doc id                                           |
-- |Parameters   : file_id, cust_doc_id, column_name, record_type                      |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-DEC-2015  Suresh N                Initial draft version               |
-- +===================================================================================+
PROCEDURE xx_ar_ebl_txt_update_dist_num(
    p_file_id     IN NUMBER ,
    p_cust_doc_id IN NUMBER ,
    p_column_name IN VARCHAR2 ,
    p_seq_num_fid IN NUMBER ,
    p_org_id      IN NUMBER ,
    p_debug_flag  IN VARCHAR2 ,
    p_error_flag OUT VARCHAR2)
IS
  CURSOR get_cust_trx_line_id
  IS
    SELECT stg_id,
      customer_trx_line_id
    FROM xx_ar_ebl_txt_dtl_stg
    WHERE file_id   = p_file_id
    AND cust_doc_id = p_cust_doc_id
    AND trx_type    = 'DIST'
    AND rec_type   != 'FID'
    ORDER BY customer_trx_id;
  lc_update_sql           VARCHAR2(1000);
  lc_err_location_msg     VARCHAR2(1000);
  ln_get_current_seq_val  NUMBER;
  ln_stg_id               NUMBER;
  ln_cust_trx_line_id     NUMBER;
  ln_current_trx_line_id  NUMBER;
  ln_previous_trx_line_id NUMBER;
  lb_debug_flag           BOOLEAN;
  ln_count                NUMBER := 0;
BEGIN
  IF (p_debug_flag = 'Y') THEN
    lb_debug_flag := TRUE;
  ELSE
    lb_debug_flag := FALSE;
  END IF;
  lc_err_location_msg := 'In the xx_ar_ebl_txt_update_dist_num Procedure to update the Dist Seq Number ';
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
  OPEN get_cust_trx_line_id;
  LOOP
    FETCH get_cust_trx_line_id INTO ln_stg_id, ln_cust_trx_line_id;
    EXIT
  WHEN get_cust_trx_line_id%NOTFOUND;
    ln_current_trx_line_id   := ln_cust_trx_line_id;
    IF ln_current_trx_line_id = ln_previous_trx_line_id THEN
      ln_count               := ln_count + 1;
    ELSE
      ln_count := 1;
    END IF;
    lc_update_sql       := 'UPDATE xx_ar_ebl_txt_dtl_stg SET '||p_column_name||' = '||ln_count ||' WHERE customer_trx_line_id = '||ln_cust_trx_line_id||' AND rec_type != '||'''FID''' ||' AND file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND trx_type = '||'''DIST'''||' AND stg_id = '||ln_stg_id;
    lc_err_location_msg := 'Update SQL is '||lc_update_sql;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
    EXECUTE IMMEDIATE lc_update_sql;
    ln_previous_trx_line_id := ln_cust_trx_line_id;
  END LOOP;
  --
  lc_err_location_msg := 'Dist Sequence Number Updated Successfully.';
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
EXCEPTION
WHEN OTHERS THEN
  p_error_flag        := 'Y';
  lc_err_location_msg := 'Error While Updating Dist Sequence Number '||SQLCODE||' - '||SUBSTR(sqlerrm,1,255);
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,TRUE ,lc_err_location_msg );
END;
-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : XX_AR_EBL_TXT_CHILD_PROG                                            |
-- | Description : This Procedure is used for framing the dynamic query to fetch data  |
-- |               from the Configuration tables and to poplate the txt stagging tables|
-- |Parameters   : p_batch_id                                                          |
-- |             , p_doc_type                                                          |
-- |             , p_debug_flag                                                        |
-- |             , p_cycle_date                                                        |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- |          1.1 14-Feb-2017  Punit Gupta   CG     Requirement# (2282,2302,40015)     |
-- |          1.2 15-Dec-2017  Aniket J      CG     Requirement# (22772)                  |
-- +===================================================================================+
PROCEDURE XX_AR_EBL_TXT_CHILD_PROG(
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER ,
    p_batch_id   IN NUMBER ,
    p_doc_type   IN VARCHAR2 ,
    p_debug_flag IN VARCHAR2 ,
    p_cycle_date IN VARCHAR2 )
IS
  ld_cycle_date           DATE   := FND_DATE.CANONICAL_TO_DATE(p_cycle_date);
  ln_org_id               NUMBER := fnd_profile.value('ORG_ID');
  lc_err_location_msg     VARCHAR2(1000);
  lc_insert_status        VARCHAR2(1000);
  lb_debug_flag           BOOLEAN;
  lc_sel_dist_fid         VARCHAR2(1000);
  lc_sqlerrm              VARCHAR2(1000);
  ex_hdr_err_record_found EXCEPTION;
  ex_dtl_err_record_found EXCEPTION;
  ex_trl_err_record_found EXCEPTION;
TYPE lcu_get_dist_doc
IS
  REF
  CURSOR;
    get_dist_doc lcu_get_dist_doc;
  TYPE lcu_get_dist_fid
IS
  REF
  CURSOR;
    get_dist_fid lcu_get_dist_fid;
    lc_get_dist_fid xx_ar_ebl_cons_hdr_main.file_id%TYPE;
    lc_get_dist_docid xx_ar_ebl_cons_hdr_main.parent_cust_doc_id%TYPE;
    lc_get_dist_ebatchid xx_ar_ebl_cons_hdr_main.extract_batch_id%TYPE;
    lc_hdr_error_flag VARCHAR2(1);
    lc_hdr_error_msg  VARCHAR2(2000);
    lc_dtl_error_flag VARCHAR2(1);
    lc_dtl_error_msg  VARCHAR2(2000);
    lc_trl_error_flag VARCHAR2(1);
    lc_trl_error_msg  VARCHAR2(2000);

--Added by Aniket CG #22772 on 15 Dec 2017
--start
					lc_transaction_type   VARCHAR2(2) := null;
					lc_combo_type_whr     VARCHAR2(1000) := null;
					lc_ar_ebl_update     VARCHAR2(32767) := null;
					ln_total_merchandise_amt 	 NUMBER := 0;
					ln_total_misc_amt 		NUMBER := 0;
					ln_total_gift_card_amt 	NUMBER := 0;
					ln_total_salestax_amt 	NUMBER := 0;
					ln_total_due NUMBER := 0;
          lc_fun_whr    VARCHAR2(100) := null;
          lc_data_sel     VARCHAR2(32767) := null;
          lc_data       VARCHAR2(2) := null;
          lc_data_whr   VARCHAR2(100) := null;
--end

  BEGIN
    IF (p_debug_flag = 'Y') THEN
      lb_debug_flag := TRUE;
    ELSE
      lb_debug_flag := FALSE;
    END IF;
    lc_err_location_msg := 'Parameters ==>' || CHR(13) || 'Debug flag : ' || p_debug_flag || CHR(13) || 'Batch_size : ' || p_batch_id || CHR(13) || 'Document type : ' || p_doc_type || CHR(13) || 'Cycle Date :' || p_cycle_date;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
    --Choosing the cursor based on the doc type parametr passed
    IF p_doc_type = 'CONS' THEN
      OPEN get_dist_doc FOR
      SELECT DISTINCT parent_cust_doc_id,
        extract_batch_id
      FROM xx_ar_ebl_cons_hdr_main
      WHERE batch_id     = p_batch_id
      AND org_id         = ln_org_id;
    lc_sel_dist_fid     := 'SELECT DISTINCT file_id FROM  xx_ar_ebl_cons_hdr_main WHERE batch_id = :p_batch_id AND parent_cust_doc_id = :p_parent_cust_doc_id AND extract_batch_id = :p_ebatchid AND org_id = :ln_org_id';
    lc_err_location_msg := 'Opening Cursor for Consolidated document';
  END IF;
  BEGIN
    LOOP
      FETCH get_dist_doc INTO lc_get_dist_docid, lc_get_dist_ebatchid;
      EXIT
    WHEN get_dist_doc%NOTFOUND;
      SAVEPOINT ins_cust_doc_id;
      OPEN get_dist_fid FOR lc_sel_dist_fid USING p_batch_id,
      lc_get_dist_docid,
      lc_get_dist_ebatchid,
      ln_org_id;
      LOOP
        FETCH get_dist_fid INTO lc_get_dist_fid;
        EXIT
      WHEN get_dist_fid%NOTFOUND;
        BEGIN

      --Start  Added by Aniket CG #22772 on 15 Dec 2017
      IF p_doc_type = 'CONS' THEN
      --Check customer level set up for combo type before inserting in to STG
      BEGIN
        SELECT c_ext_attr13
        INTO lc_transaction_type
        FROM XX_CDH_CUST_ACCT_EXT_B xxcust
        WHERE 1                     =1
        AND xxcust.n_ext_attr2      = lc_get_dist_docid  ;
        IF lc_transaction_type     IS NOT NULL THEN
          IF lc_transaction_type    = 'CR' THEN
            lc_combo_type_whr      := ' AND  hdr.transaction_class =  ''Credit Memo'' ';
            lc_fun_whr             := '''Credit Memo''';
            lc_data_whr            := 'Credit Memo';
          ELSIF lc_transaction_type = 'DB' THEN
            lc_combo_type_whr      := ' AND hdr.transaction_class IN ( ''Invoice'' '|| ','||' ''Debit Memo'' )  ';
            lc_fun_whr             :=   '''Invoice,Debit Memo''';
            lc_data_whr            :=   'Invoice,Debit Memo';
          END IF;
        ELSE
          lc_combo_type_whr := NULL;
          lc_fun_whr := NULL;
        END IF;
        XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,' Print Combo type WHERE CLAUSE  --> ' || lc_combo_type_whr );

        --START Added by Aniket CG 22 Jan 2018
        -- Check Data in Header Source Table before proceeding
         IF lc_transaction_type is not null then
         BEGIN

         lc_data_sel := ' select '||''''||'X'||''''||' from XX_AR_EBL_CONS_HDR_MAIN hdr
         where 1=1    and cust_doc_id = ' || lc_get_dist_docid ||
         ' and file_id =    '  ||  lc_get_dist_fid || lc_combo_type_whr || ' and rownum =1 ' ;

         XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_data_sel );

         execute immediate  lc_data_sel INTO lc_data;

         EXCEPTION WHEN OTHERS THEN
           x_ret_code := 1;
           lc_data := null;
           lc_err_location_msg := 'Data is not available for Combo type set up as  ' || lc_transaction_type || ' Cust Doc Id: ' || lc_get_dist_docid || ' File ID :' || lc_get_dist_fid || ' Erorr MSG: '||  SQLERRM;
           XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
            xx_ar_ebl_txt_update_status(lc_get_dist_docid, lc_get_dist_ebatchid, p_batch_id, 'MANIP_ERROR', lc_err_location_msg, p_doc_type);
           EXIT;
         END ;
         END IF;
      -- END Added by Aniket CG 22 Jan 2018

      EXCEPTION
      WHEN OTHERS THEN
        lc_err_location_msg := 'The exception in finding combo details for ' || lc_get_dist_docid || SQLERRM;
        XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
        lc_transaction_type := NULL;
        lc_combo_type_whr   := NULL;
      END;
      --End  Added by Aniket CG #22772 on 15 Dec 2017

      --Start  Added by Aniket CG #22772 on 15 Dec 2017
      --Since AR EBL FILE Table used in functions so we are updating it before.
      --Considering save point ins_cust_doc_id so it will get revert in case any exception
      IF lc_combo_type_whr IS NOT NULL THEN
        BEGIN
          lc_ar_ebl_update := '
      SELECT SUM(original_invoice_amount-total_gift_card_amount),
      SUM(gross_sale_amount - total_coupon_amount - total_freight_amount - total_discount_amount),
      SUM(total_coupon_amount + total_freight_amount + total_discount_amount),
      SUM(total_gift_card_amount),
      SUM(total_gst_amount + total_pst_amount + total_us_tax_amount)
      FROM   XX_AR_EBL_CONS_HDR_MAIN hdr
      WHERE  hdr.file_id = '|| lc_get_dist_fid || lc_combo_type_whr;
          EXECUTE immediate lc_ar_ebl_update INTO ln_total_due, ln_total_merchandise_amt, ln_total_misc_amt, ln_total_gift_card_amt, ln_total_salestax_amt ;
          UPDATE XX_AR_EBL_FILE
          SET total_due           = ln_total_due ,
            total_merchandise_amt =ln_total_merchandise_amt ,
            total_sales_tax_amt   =ln_total_salestax_amt ,
            total_misc_amt        =ln_total_misc_amt ,
            total_gift_card_amt   =ln_total_gift_card_amt
          WHERE file_id           = lc_get_dist_fid;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE , 'File id ' || lc_get_dist_fid || '  Stst '||lc_ar_ebl_update );
        EXCEPTION
        WHEN OTHERS THEN
          lc_err_location_msg := 'The exception in updating amount to file table ' || lc_get_dist_fid || SQLERRM;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
          ln_total_due             := 0;
          ln_total_merchandise_amt := 0;
          ln_total_misc_amt        := 0;
          ln_total_gift_card_amt   := 0;
          ln_total_salestax_amt    := 0;
        END;
      END IF;

      END IF ;
      --End  Added by Aniket CG #22772 on 15 Dec 2017

          lc_err_location_msg := 'Processing for the Parent cust doc ' || lc_get_dist_docid || ' File id ' || lc_get_dist_fid || ' Extract Batch id ' || lc_get_dist_ebatchid ;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
          --'Build SQL and Process Header Summary/Dtl/Trailer Records'
          lc_err_location_msg := 'Calling Procedure to Process Detail Records Data...';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );

          --Start  Added 2 parameter by Aniket CG #22772 on 15 Dec 2017
          process_txt_dtl_data(p_batch_id, lc_get_dist_docid, lc_get_dist_fid, ld_cycle_date, ln_org_id, p_debug_flag,lc_combo_type_whr, lc_fun_whr,lc_dtl_error_flag, lc_dtl_error_msg);
          --End    Added 2 parameter by Aniket CG #22772 on 15 Dec 2017

          IF lc_dtl_error_flag = 'Y' THEN
            RAISE ex_dtl_err_record_found;
          END IF;
          lc_err_location_msg := 'Calling Procedure to Process Header Summary Data...';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );

          --Start  Added 2 parameter by Aniket CG #22772 on 15 Dec 2017
          process_txt_hdr_summary_data(p_batch_id, lc_get_dist_docid, lc_get_dist_fid, ld_cycle_date, ln_org_id, p_debug_flag, lc_combo_type_whr,lc_fun_whr, lc_hdr_error_flag, lc_hdr_error_msg);
          --End    Added 2 parameter by Aniket CG #22772 on 15 Dec 2017

          IF lc_hdr_error_flag = 'Y' THEN
            RAISE ex_hdr_err_record_found;
          END IF;
          lc_err_location_msg := 'Calling Procedure to Process Trailer Records Data...';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );

         --Start  Added 2 parameter by Aniket CG #22772 on 15 Dec 2017
           process_txt_trl_data(p_batch_id, lc_get_dist_docid, lc_get_dist_fid, ld_cycle_date, ln_org_id, p_debug_flag,lc_combo_type_whr,lc_fun_whr, lc_trl_error_flag, lc_trl_error_msg);
         --End    Added 2 parameter by Aniket CG #22772 on 15 Dec 2017

          IF lc_trl_error_flag = 'Y' THEN
            RAISE ex_trl_err_record_found;
          END IF;
          lc_err_location_msg := 'Updating EBL file table to RENDER status for manipulated records';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
          xx_ar_ebl_txt_update_status(p_batch_id, 'MARKED_FOR_RENDER', 'READY_FOR_RENDER', 'MANIP_READY', 'RENDER', p_doc_type);
          COMMIT;
        EXCEPTION
        WHEN ex_hdr_err_record_found THEN
          x_ret_code := 1;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,'ERROR in XX_AR_EBL_TXT_CHILD_PROG:  Error While Processing ' || CHR(13) || 'Code Location : ' || lc_hdr_error_msg );
          lc_sqlerrm := lc_hdr_error_msg;
          ROLLBACK TO ins_cust_doc_id;
          --ln_count_doc := 0;
          xx_ar_ebl_txt_update_status(lc_get_dist_docid, lc_get_dist_ebatchid, p_batch_id, 'MANIP_ERROR', lc_sqlerrm, p_doc_type);
          EXIT;
        WHEN ex_dtl_err_record_found THEN
          x_ret_code := 1;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,'ERROR in XX_AR_EBL_TXT_CHILD_PROG:  Error While Processing ' || CHR(13) || 'Code Location : ' || lc_dtl_error_msg );
          lc_sqlerrm := lc_dtl_error_msg;
          ROLLBACK TO ins_cust_doc_id;
          --ln_count_doc := 0;
          xx_ar_ebl_txt_update_status(lc_get_dist_docid, lc_get_dist_ebatchid, p_batch_id, 'MANIP_ERROR', lc_sqlerrm, p_doc_type);
          EXIT;
        WHEN ex_trl_err_record_found THEN
          x_ret_code := 1;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,'ERROR in XX_AR_EBL_TXT_CHILD_PROG:  Error While Processing ' || CHR(13) || 'Code Location : ' || lc_trl_error_msg );
          lc_sqlerrm := lc_trl_error_msg;
          ROLLBACK TO ins_cust_doc_id;
          --ln_count_doc := 0;
          xx_ar_ebl_txt_update_status(lc_get_dist_docid, lc_get_dist_ebatchid, p_batch_id, 'MANIP_ERROR', lc_sqlerrm, p_doc_type);
          EXIT;
        WHEN OTHERS THEN
          x_ret_code := 1;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,'ERROR in XX_AR_EBL_TXT_CHILD_PROG: ' || SQLERRM || CHR(13) || 'Code Location : ' || lc_dtl_error_msg );
          lc_sqlerrm := 'Code Location : ' || lc_err_location_msg || ' ERROR in XX_AR_EBL_TXT_CHILD_PROG: ' || SQLERRM || ' for the file id ' || lc_get_dist_fid;
          ROLLBACK TO ins_cust_doc_id;
          xx_ar_ebl_txt_update_status(lc_get_dist_docid, lc_get_dist_ebatchid, p_batch_id, 'MANIP_ERROR', lc_sqlerrm, p_doc_type);
          EXIT;
        END;
      END LOOP;
      CLOSE get_dist_fid;
    END LOOP;
    CLOSE get_dist_doc;
  EXCEPTION
  WHEN OTHERS THEN
    x_ret_code := 1;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,'ERROR in XX_AR_EBL_TXT_CHILD_PROG: ' || SQLERRM || CHR(13) || 'Code Location : ' || lc_err_location_msg );
  END;
END XX_AR_EBL_TXT_CHILD_PROG;
-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : PROCESS_TXT_HDR_SUMMARY_DATA                                                |
-- | Description : This Procedure is used for to framing the dynamic query to fetch data       |
-- |               from the header summary table and to poplate the hdr txt stagging table     |
-- |Parameters   : p_batch_id                                                                  |
-- |             , p_cust_doc_id                                                               |
-- |             , p_file_id                                                                   |
-- |             , p_cycle_date                                                                |
-- |             , p_org_id                                                                    |
-- |             , p_debug_flag                                                                |
-- |             , p_error_flag                                                                |
-- |                                                                                           |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                       |
-- |      1.1 25-MAY-2017  Punit Gupta CG          Changes done for Defect #42226 raised in UAT|
-- |      1.2 11-AUG-2017  Punit Gupta CG          Changes done for Defect #40174              |
-- |      1.3 15-DEC-2017  Aniket J    CG          Changes for Requirement  #22772             |
-- |      1.4 15-May-2018  Aniket J    CG          Changes for Requirement  #NAIT-29364        |
-- +===========================================================================================+
PROCEDURE PROCESS_TXT_HDR_SUMMARY_DATA(
    p_batch_id    IN NUMBER ,
    p_cust_doc_id IN NUMBER ,
    p_file_id     IN NUMBER ,
    p_cycle_date  IN VARCHAR2 ,
    p_org_id      IN NUMBER ,
    p_debug_flag  IN VARCHAR2 ,
    p_cmb_splt_whr   IN VARCHAR2 , --Added by Aniket CG #22772 on 15 Dec 2017
    p_cmb_splt_splfunc_whr IN VARCHAR2 , --Added by Aniket CG #22772 on 15 Dec 2017
    p_hdr_error_flag OUT VARCHAR2 ,
    p_hdr_error_msg OUT VARCHAR2)
IS
  CURSOR get_dist_rows
  IS
    SELECT DISTINCT rownumber
    FROM xx_cdh_ebl_templ_hdr_txt
    WHERE cust_doc_id = p_cust_doc_id
      --AND attribute1 = 'Y'
    AND attribute20 = 'Y'
    ORDER BY rownumber;
  ln_get_dist_rows NUMBER;
  CURSOR c_get_header_fields_info(p_rownum IN NUMBER)
  IS
    SELECT to_number(xftv.source_value1) field_id ,
      xftv.target_value20 tab_name ,
      xftv.source_value4 col_name ,
      xcetht.seq ,
      xcetht.label ,
      xcetht.constant_value cons_val ,
      xftv.target_value14 spl_fields ,
      xftv.target_value1 data_type ,
      xftv.target_value19 rec_type ,
      xcetht.cust_doc_id ,
      'HEADER SUMMARY' trx_type ,
      xftv.target_value24 spl_function,
      xcetht.rownumber rec_order,
      -- Added by Thilak CG for Defect#40174 on 07-AUG-2017
      xcetht.absolute_flag,
      xcetht.dc_indicator,
      -- End
	    --Added by Aniket CG 15 May #NAIT-29364
      xcetht.db_cr_seperator
      --Added by Aniket CG 15 May #NAIT-29364
    FROM xx_fin_translatedefinition xftd ,
      xx_fin_translatevalues xftv ,
      xx_cdh_ebl_templ_hdr_txt xcetht
    WHERE xftd.translate_id   = xftv.translate_id
    AND xftv.source_value1    = xcetht.field_id
    AND xcetht.cust_doc_id    = p_cust_doc_id
    AND xcetht.rownumber      = p_rownum
    AND xftd.translation_name ='XX_CDH_EBL_TXT_HDR_FIELDS'
    AND xftv.target_value19   = 'DT' -- Uncommented by Punit on 25-MAY-2017
    AND xftv.enabled_flag     ='Y'
    AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
      --AND xcetht.attribute1 = 'Y'
    AND xcetht.attribute20 = 'Y'
  UNION
  SELECT xcetht.FIELD_ID ,
    'Concatenate' tab_name
    --,NULL col_name
    ,
    get_conc_field_names(xcetht.cust_doc_id, xcecft.conc_field_id, 'HDR', NULL, p_debug_flag, p_file_id) ,
    xcetht.seq ,
    xcetht.label ,
    NULL cons_val ,
    NULL spl_fields ,
    'VARCHAR2' data_type ,
    'DT' rec_type ,
    xcetht.cust_doc_id ,
    'HEADER SUMMARY' trx_type ,
    NULL ,
    xcetht.rownumber rec_order,
    -- Added by Thilak CG for Defect#40174 on 07-AUG-2017
    xcetht.absolute_flag,
    xcetht.dc_indicator ,
    -- End
	  --Added by Aniket CG 15 May #NAIT-29364
    xcetht.db_cr_seperator
    --Added by Aniket CG 15 May #NAIT-29364
  FROM xx_cdh_ebl_templ_hdr_txt xcetht ,
    xx_cdh_ebl_concat_fields_txt xcecft
  WHERE xcetht.field_id  = xcecft.conc_field_id
  AND xcetht.cust_doc_id = xcecft.cust_doc_id
  AND xcetht.cust_doc_id = p_cust_doc_id
  AND xcetht.rownumber   = p_rownum
  AND xcecft.tab         = 'H'
  ORDER BY rec_order,
    seq;
  lc_from_cons_hdr     CONSTANT VARCHAR2(32767) := ' FROM xx_ar_ebl_cons_hdr_main hdr WHERE hdr.cust_doc_id = '||p_cust_doc_id||' AND hdr.file_id = '||p_file_id||' AND hdr.org_id = '||p_org_id;
  lc_select_cons_hdr   CONSTANT VARCHAR2(32767) := ' (SELECT XX_AR_EBL_TXT_STG_ID_S.nextval,hdr.parent_cust_doc_id,hdr.file_id,fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,';
  lc_insert_const_cols CONSTANT VARCHAR2(32767) := 'INSERT INTO xx_ar_ebl_txt_hdr_stg (stg_id,cust_doc_id,file_id,created_by,creation_date,last_updated_by,last_update_date,last_update_login,trx_type,rec_type,rec_order,cycle_date,batch_id,';
  lc_column            VARCHAR2(20)             := 'column';
  lc_select_var_cols   VARCHAR2(32767);
  lc_insert_col_name   VARCHAR2(32767);
  ln_count             NUMBER := 1;
  lc_hdr_value_fid     VARCHAR2(32767);
  lc_function          VARCHAR2(32767);
  lc_function_return   VARCHAR2(32767);
  lc_err_location_msg  VARCHAR2(32767);
  lb_debug_flag        BOOLEAN;
  lc_hdr_summary_col   VARCHAR2(1000);
  lc_hdr_summary_cols  VARCHAR2(1000);
  lc_row_seq_col       VARCHAR2(1000);
  lc_hs_target_value1  VARCHAR2(1);
  lc_hs_target_value2  VARCHAR2(1);
  lc_hs_target_value3  VARCHAR2(1);
  lc_hs_print_line_num VARCHAR2(1);
  lc_hs_stg_query      VARCHAR2(32767);
  lc_stg_update_query  VARCHAR2(32767);
TYPE lc_ref_cursor
IS
  REF
  CURSOR;
    c_hs_stg_cursor lc_ref_cursor;
    c_stg_row_cursor lc_ref_cursor;
    lc_hs_update_sql  VARCHAR2(32767);
    ln_hs_file_id     VARCHAR2(15);
    ln_hs_cust_doc_id VARCHAR2(15);
    ln_hs_rec_order   VARCHAR2(10);
    ln_hs_line_num    NUMBER := 0;
    -- Below variables added by Thilak 07-AUG-2017 for Defect#40174
    lc_get_abs_amt_cols    VARCHAR2(32767);
    lc_update_abs_amt_cols VARCHAR2(32767);
    ln_abs_cnt             NUMBER        := 0;
    ln_abs_update_cnt      NUMBER        := 0;
    lc_abs_flag            VARCHAR2(1)   := 'N';
    lc_dc_flag             VARCHAR2(1)   := 'N';
    lc_debit               VARCHAR2(15)  := NULL;
    lc_credit              VARCHAR2(15)  := NULL;
    lc_dc_amt_col          VARCHAR2(15)  := NULL;
    lc_dc_indicator_col    VARCHAR2(15)  := NULL;
    lc_dc_amt_decode       VARCHAR2(1000) := NULL;
    lc_dc_update_sql       VARCHAR2(32767);
    -- End
    -- Below variables added by Punit CG on 11-AUG-2017 for Defect#40174
    ln_sign_cnt             NUMBER := 0;
    lc_get_sign_amt_cols    VARCHAR2(32767);
    lc_update_sign_amt_cols VARCHAR2(32767);
    ln_sign_update_cnt      NUMBER         := 0;
    ln_sign_ind_flag        VARCHAR2(1)    := 'N';
    lc_amt_col_for_sign     VARCHAR2(15)   := NULL;
    lc_sign_col_decode      VARCHAR2(15000) := NULL;
    ln_sign_col_str         NUMBER         := NULL;
    lc_sign_flag            VARCHAR2(1)    := 'N';
    lc_amt_sign_flag        VARCHAR2(1)    := 'N';
    ln_sign_col_cnt         NUMBER         := 0;
    lc_sign_amt_field_id    VARCHAR2(15)   := NULL;
    lc_select_sign_amt_cols VARCHAR2(32767);
  TYPE lc_ref_cursor_hdr
  IS
  REF
  CURSOR;
    c_hs_upd_sign_cursor lc_ref_cursor_hdr;
    c_sign_row_cursor lc_ref_cursor_hdr;
    c_hs_update_sql        VARCHAR2(32767);
    ln_hs_sign_file_id     VARCHAR2(15);
    ln_hs_sign_cust_doc_id VARCHAR2(15);
    ln_hs_sign_rec_order   VARCHAR2(10);
    lc_hdr_sign_cols       VARCHAR2(2000);
    lc_row_sign_col        VARCHAR2(1000);
    lc_hs_upd_sign_query   VARCHAR2(32767);
    lc_sign_update_query   VARCHAR2(32767);
    -- End of Below variables added by Punit CG on 11-AUG-2017 for Defect#40174
	-- Start Added by Aniket CG 15 May #NAIT-29364
	  lc_db_cr_nvl_value   VARCHAR2(10);
	  lc_dc_col_orig_flgchk    VARCHAR2(15)  := 'N';
	  lc_dc_amt_col_db          VARCHAR2(15)  :=  NULL;
	  lc_dc_amt_col_cr          VARCHAR2(15)  :=  NULL;
	  lc_dc_amt_decode_db       VARCHAR2(1000) := NULL;
	  lc_dc_amt_decode_cr       VARCHAR2(1000) := NULL;
	  lc_dc_update_sql_db       VARCHAR2(32767);
	  lc_dc_update_sql_cr       VARCHAR2(32767);
    --End Added by Aniket CG 15 May #NAIT-29364
	lv_hide_flag                VARCHAR2(200) := NULL;
	lv_fee_option               NUMBER := 0;
	lv_upd_str     VARCHAR2(2000) := NULL;
    lv_upd_str1    VARCHAR2(2000) := NULL;
  BEGIN
    IF (p_debug_flag = 'Y') THEN
      lb_debug_flag := TRUE;
    ELSE
      lb_debug_flag := FALSE;
    END IF;
    lc_err_location_msg := 'Processing the Header Summary Records... Cust Doc Id :' || p_cust_doc_id || ' File id ' || p_file_id || ' Extract Batch id ' || p_batch_id ;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
    lc_hs_print_line_num := 'N';
    OPEN get_dist_rows;
    LOOP
      FETCH get_dist_rows INTO ln_get_dist_rows;
    EXIT
  WHEN get_dist_rows%NOTFOUND;
    lc_hdr_summary_col   := NULL;
    ln_count             := 1;
    lc_hdr_value_fid     := NULL;
    lc_insert_col_name   := NULL;
    lc_select_var_cols   := NULL;
    lc_function          := NULL;
    ln_abs_cnt           := 0;
    ln_abs_update_cnt    := 0;
    lc_dc_flag           := 'N';
    lc_debit             := NULL;
    lc_credit            := NULL;
    lc_dc_amt_col        := NULL;
    lc_dc_amt_decode     := NULL;
    lc_dc_indicator_col  := NULL;
    lc_get_abs_amt_cols  := NULL;
    lc_dc_update_sql     := NULL;
    ln_sign_cnt          := 0;
    lc_get_sign_amt_cols := NULL;
    --ln_sign_update_cnt   := 0;
    ln_sign_ind_flag     := 'N';
    lc_amt_col_for_sign  := NULL;
    lc_sign_col_decode   := NULL;
    ln_sign_col_str      := NULL;
    lc_hdr_sign_cols     := NULL;
    lc_sign_update_query := NULL;
    lc_hs_upd_sign_query := NULL;
    lc_sign_flag         := 'N';
    lc_amt_sign_flag     := 'N';
    ln_sign_col_cnt      := 0;
	  BEGIN
	    SELECT fee_option
		  INTO lv_fee_option
		  FROM xx_cdh_cust_acct_ext_b
		 WHERE N_EXT_ATTR2 = p_cust_doc_id
		   AND attr_group_id = 166 AND rownum =1;
	  EXCEPTION WHEN OTHERS THEN
	    lv_fee_option:= 0;
	  END;
    FOR lc_get_header_fields_info IN c_get_header_fields_info(ln_get_dist_rows)
    LOOP
	  lv_hide_flag := 'N';

	  --Added for 1.19
	  IF lv_fee_option = 1010 AND UPPER(lc_get_header_fields_info.spl_function) = 'XX_AR_EBL_TXT_SPL_LOGIC_PKG.GET_FEE_AMOUNT' THEN
	    lv_hide_flag := 'N';
	  ELSIF UPPER(lc_get_header_fields_info.spl_function) = 'XX_AR_EBL_TXT_SPL_LOGIC_PKG.GET_FEE_AMOUNT' THEN
	    lv_hide_flag := 'Y';
	  END IF;
	  --End for 1.19  
      IF ln_count           = 1 THEN
        lc_select_var_cols := lc_select_cons_hdr||''''||lc_get_header_fields_info.trx_type||''''||','||''''||lc_get_header_fields_info.rec_type||''''||','||lc_get_header_fields_info.rec_order||',' ||'TO_DATE('||''''||p_cycle_date||''''||',''DD-MON-YY''),'||p_batch_id||',';
        lc_hdr_value_fid   := lc_hdr_value_fid||''''||lc_get_header_fields_info.trx_type||''''||','||'''FID'''||','||lc_get_header_fields_info.rec_order||',' ||'TO_DATE('||''''||p_cycle_date||''''||',''DD-MON-YY''),'||p_batch_id||',';
        lc_insert_col_name := lc_insert_const_cols;
      END IF;
      IF (LOWER(lc_get_header_fields_info.tab_name)    = 'header') THEN
        IF (UPPER(lc_get_header_fields_info.data_type) = 'DATE') THEN
          lc_select_var_cols                          := lc_select_var_cols || 'TO_CHAR(hdr.' || lc_get_header_fields_info.col_name || ',''YYYY-MM-DD''),';
        ELSE
          lc_select_var_cols := lc_select_var_cols||'hdr.'||lc_get_header_fields_info.col_name||',';
        END IF;
      ELSIF (LOWER(lc_get_header_fields_info.tab_name) = 'concatenate') THEN
        lc_select_var_cols                            := lc_select_var_cols||lc_get_header_fields_info.col_name||',';
      ELSIF (LOWER(lc_get_header_fields_info.tab_name) = 'constant') THEN
        lc_select_var_cols                            := lc_select_var_cols||''''||lc_get_header_fields_info.cons_val||''''||',';
      ELSIF (LOWER(lc_get_header_fields_info.tab_name) = 'function') THEN
        IF lc_get_header_fields_info.spl_function     IS NOT NULL THEN
          --lc_function                                 := 'SELECT '||lc_get_header_fields_info.spl_function||'('||p_cust_doc_id||','||p_file_id||','||p_org_id||','||''''||lc_get_header_fields_info.col_name||''''||') FROM DUAL';-- commented by Aniket CG #22772 on 15 Dec 2017
          --fnd_file.put_line(fnd_file.log,lc_function);
		  
--		  IF UPPER(lc_get_header_fields_info.spl_function) = 
		  
          -- start Added by Aniket CG #22772 on 15 Dec 2017
           IF  UPPER(lc_get_header_fields_info.spl_function) IN ( 'XX_AR_EBL_TXT_SPL_LOGIC_PKG.GET_GRAND_TOTAL' , 'XX_AR_EBL_TXT_SPL_LOGIC_PKG.GET_GRAND_FREIGHT_AMT')
           AND p_cmb_splt_splfunc_whr IS NOT NULL THEN
           lc_function                                 := 'SELECT '||lc_get_header_fields_info.spl_function||'('||p_cust_doc_id||','||p_file_id||','||p_org_id||','||''''||lc_get_header_fields_info.col_name||''''||','|| p_cmb_splt_splfunc_whr || ') FROM DUAL';
           ELSE
           lc_function                                 := 'SELECT '||lc_get_header_fields_info.spl_function||'('||p_cust_doc_id||','||p_file_id||','||p_org_id||','||''''||lc_get_header_fields_info.col_name||''''||') FROM DUAL';
           END IF;
          -- end Added by Aniket CG #22772 on 15 Dec 2017
          EXECUTE IMMEDIATE lc_function INTO lc_function_return;
		   --Added by Aniket CG 15 May #NAIT-29364  -- removed and used default as null lc_get_header_fields_info.db_cr_seperator IS NOT NULL AND
                IF   UPPER(lc_get_header_fields_info.col_name) IN ('ORIG_INV_AMT_DB','ORIG_INV_AMT_CR') THEN
                  SELECT lc_get_header_fields_info.db_cr_seperator --,'NULL',NULL,lc_get_header_fields_info.db_cr_seperator)
                  INTO lc_db_cr_nvl_value
                  FROM DUAL;

				  lc_db_cr_nvl_value := nvl(lc_db_cr_nvl_value, 'NULL');

                  IF UPPER(lc_get_header_fields_info.col_name) IN ('ORIG_INV_AMT_DB') THEN
                    lc_select_var_cols := lc_select_var_cols|| ' DECODE (SIGN ('|| lc_function_return || ') ,0,0,1 ,' || lc_function_return || ' , ' || lc_db_cr_nvl_value || ')'|| ',';
                  ELSIF UPPER(lc_get_header_fields_info.col_name) IN ('ORIG_INV_AMT_CR') THEN
                    lc_select_var_cols := lc_select_var_cols|| ' DECODE (SIGN ('|| lc_function_return || ') ,-1 ,' || lc_function_return || ' , '||lc_db_cr_nvl_value|| ')'|| ',';
                  END IF;

                ELSE
                  lc_select_var_cols := lc_select_var_cols||lc_function_return||',';
                END IF;
                --Added by Aniket CG 15 May #NAIT-29364
          -- lc_select_var_cols := lc_select_var_cols||lc_function_return||','; --Commented by Aniket CG 15 May #NAIT-29364
        ELSE
          lc_select_var_cols := lc_select_var_cols||'NULL'||',';
          -- Checking to print line number field is selected for the cust doc id.
          BEGIN
            SELECT xftv.target_value1,
              target_value2,
              target_value3
            INTO lc_hs_target_value1,
              lc_hs_target_value2,
              lc_hs_target_value3
            FROM xx_fin_translatedefinition xftd ,
              xx_fin_translatevalues xftv
            WHERE xftd.translate_id   = xftv.translate_id
            AND xftd.translation_name = 'XX_AR_EBL_TXT_LINE_NUM'
            AND xftv.enabled_flag     = 'Y'
            AND TRUNC(sysdate) BETWEEN TRUNC(XFTV.START_DATE_ACTIVE) AND TRUNC(NVL(XFTV.END_DATE_ACTIVE,SYSDATE+1))
            AND xftv.source_value1 = lc_get_header_fields_info.col_name;
            fnd_file.put_line(fnd_file.log,' Target Values '||lc_hs_target_value1||' - '||lc_hs_target_value1||' - '||lc_hs_target_value1||' - '||lc_hs_target_value1);
            IF lc_hs_target_value1  = 'Y' OR lc_hs_target_value2 = 'Y' OR lc_hs_target_value3 = 'Y' THEN
              lc_hs_print_line_num := 'Y';
              lc_hdr_summary_col   := lc_hdr_summary_col || lc_column||ln_count || ','; -- Modified by Thilak CG on 25-JUL-2017 for Defect#42380
            END IF;
            lc_err_location_msg := ' Print Line Num '||lc_hs_print_line_num||' - Hdr Summary Col '||lc_hdr_summary_col;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
          EXCEPTION
          WHEN OTHERS THEN
            lc_hs_target_value1 := 'N';
            lc_hs_target_value2 := 'N';
            lc_hs_target_value3 := 'N';
          END;
          -- End
        END IF;
      END IF;
      -- Start of changes done by Thilak CG for Defect #40174 on 07-AUG-2017
      IF (UPPER(lc_get_header_fields_info.dc_indicator) IS NOT NULL AND lc_dc_flag = 'N') THEN
        lc_dc_flag                                      := 'Y';
        lc_debit                                        := NULL;
        lc_credit                                       := NULL;
        BEGIN
          SELECT description,
            tag
          INTO lc_debit,
            lc_credit
          FROM fnd_lookup_values_vl FLV
          WHERE FLV.lookup_type  = 'XXOD_EBL_DEBIT_CREDIT_SIGN_IND'
          AND UPPER(flv.meaning) = UPPER(lc_get_header_fields_info.dc_indicator)
          AND FLV.enabled_flag   = 'Y'
          AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
        EXCEPTION
        WHEN OTHERS THEN
          lc_err_location_msg := 'Error during select mapping column from the lookup XXOD_EBL_DEBIT_CREDIT_SIGN_IND';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
          p_hdr_error_flag := 'Y';
          p_hdr_error_msg  := lc_err_location_msg;
        END;
      END IF;

      IF (UPPER(lc_get_header_fields_info.absolute_flag) = 'Y') THEN
        lc_abs_flag                                     := 'Y';
        ln_abs_cnt                                      := 0;
        BEGIN
          SELECT COUNT(flv.lookup_code)
          INTO ln_abs_cnt
          FROM fnd_lookup_values_vl FLV
          WHERE FLV.lookup_type      = 'XX_AR_EBL_TXT_HDR_ABS_COLS'
          AND UPPER(flv.lookup_code) = UPPER(lc_get_header_fields_info.col_name)
          AND FLV.enabled_flag       = 'Y'
          AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
        EXCEPTION
        WHEN OTHERS THEN
          lc_err_location_msg := 'Error during select mapping column from the lookup XX_AR_EBL_TXT_HDR_ABS_COLS';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
          p_hdr_error_flag := 'Y';
          p_hdr_error_msg  := lc_err_location_msg;
        END;
        IF ln_abs_cnt          = 1 THEN
          lc_get_abs_amt_cols := lc_get_abs_amt_cols || ' ' || lc_column || ln_count || ' = ' ||'ABS('||lc_column || ln_count||')'||',';
          ln_abs_update_cnt   := 1;
        END IF;
      END IF;
      -- End of Changes done by Thilak CG for Defect #40174 on 07-AUG-2017
      -- Start of changes done by Thilak CG for Defect #40174 on 07-AUG-2017
      IF UPPER(lc_get_header_fields_info.col_name) = 'ORIGINAL_INVOICE_AMOUNT' THEN
        lc_dc_amt_col := lc_column||ln_count;
		--start Added by Aniket CG 15 May #NAIT-29364
          lc_dc_col_orig_flgchk                          := 'Y';
          ELSIF UPPER(lc_get_header_fields_info.col_name) = 'ORIG_INV_AMT_DB' THEN
            IF lc_dc_col_orig_flgchk                      = 'N' THEN
              lc_dc_amt_col_db                           := lc_column||ln_count;
            END IF;
          ELSIF UPPER(lc_get_header_fields_info.col_name) = 'ORIG_INV_AMT_CR' THEN
            IF lc_dc_col_orig_flgchk                      = 'N' THEN
              lc_dc_amt_col_cr                           := lc_column||ln_count;
            END IF;
            --end Added by Aniket CG 15 May #NAIT-29364
      END IF;

  	  IF UPPER(lc_get_header_fields_info.col_name) = 'DC_INDICATOR' THEN
		lc_dc_indicator_col := lc_column||ln_count;
	  END IF;
	  -- End
      -- Start of changes done by Punit CG for Defect #40174 on 11-AUG-2017
      IF (UPPER(lc_get_header_fields_info.col_name) = 'SIGN') THEN
        lc_get_sign_amt_cols                       := lc_get_sign_amt_cols || ' ' || lc_column || ln_count ||',';
        ln_sign_update_cnt                         := 1;
      END IF;
      IF (lc_sign_flag = 'N' AND lc_amt_sign_flag = 'N' AND UPPER(lc_get_header_fields_info.col_name) = 'SIGN') THEN
        lc_sign_flag  := 'Y';
      END IF;
      BEGIN
        SELECT COUNT(flv.lookup_code)
        INTO ln_sign_cnt
        FROM fnd_lookup_values_vl FLV
        WHERE FLV.lookup_type      = 'XX_AR_EBL_TXT_HDR_SIGN_COLS'
        AND UPPER(flv.lookup_code) = UPPER(lc_get_header_fields_info.col_name)
        AND FLV.enabled_flag       = 'Y'
        AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
        IF (ln_sign_cnt     = 1 AND lc_sign_flag = 'N' AND lc_amt_sign_flag = 'N') THEN
          lc_amt_sign_flag := 'Y';
          --      lc_amt_col_for_sign := lc_column||ln_count;
          --      lc_sign_col_decode := 'DECODE(SIGN(' || lc_amt_col_for_sign || '),''1'',''+'',''-1'',''-'','''')';
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        lc_err_location_msg := 'Error while selecting the mapping SIGN column from the lookup XX_AR_EBL_TXT_HDR_SIGN_COLS';
        XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
        p_hdr_error_flag := 'Y';
        p_hdr_error_msg  := lc_err_location_msg;
      END;
      -- End of changes done by Punit CG for Defect #40174 on 11-AUG-2017
    
    IF lv_hide_flag = 'N' THEN
   	  lc_insert_col_name := lc_insert_col_name||lc_column||ln_count||',';
      lc_hdr_value_fid   := lc_hdr_value_fid||lc_get_header_fields_info.field_id||',';
      ln_count           := ln_count + 1;
    ELSE
      lc_select_var_cols := replace(lc_select_var_cols,lc_function_return||',','');
--	  lv_upd_str := 'update xx_ar_ebl_cons_hdr_main set TOTAL_MISCELLANEOUS_AMOUNT = TOTAL_MISCELLANEOUS_AMOUNT - '||lc_tot_fee_amt||' WHERE parent_cust_doc_id = '||p_cust_doc_id||' AND batch_id = '||p_batch_id;
--	  execute immediate lv_upd_str;
    END IF;
	
	END LOOP;
    lc_insert_col_name  := SUBSTR(lc_insert_col_name,1,LENGTH(lc_insert_col_name)                                                                                                                                                           -1)||')';
    --Added where cluase in below statement by Aniket CG requirement #22772
    lc_select_var_cols  := SUBSTR(lc_select_var_cols,1,LENGTH(lc_select_var_cols)                                                                                                                                                           -1)||lc_from_cons_hdr|| p_cmb_splt_whr  || ')';
    lc_hdr_value_fid    := ' VALUES ('||xx_ar_ebl_txt_stg_id_s.nextval||','||p_cust_doc_id||','||p_file_id||',fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,'||SUBSTR(lc_hdr_value_fid,1,LENGTH(lc_hdr_value_fid)-1)||')';
    lc_err_location_msg := 'Select and Insert Statement for HDR record FID : '||lc_insert_col_name||lc_hdr_value_fid ;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
    lc_err_location_msg := 'Select and Insert Statement for HDR record DT : '||lc_insert_col_name||lc_hdr_value_fid ;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
    fnd_file.put_line(fnd_file.log,lc_insert_col_name||lc_hdr_value_fid);
    fnd_file.put_line(fnd_file.log,lc_insert_col_name||lc_select_var_cols);
    EXECUTE IMMEDIATE lc_insert_col_name||lc_hdr_value_fid;
    EXECUTE IMMEDIATE lc_insert_col_name||lc_select_var_cols;
    -- Start of changes done by Thilak CG for Defect #40174 and 14188 on 07-AUG-2017
    lc_err_location_msg := 'Value of lc_dc_flag: '||lc_dc_flag||' and Value of lc_dc_amt_col: '||lc_dc_amt_col;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
    IF lc_dc_flag = 'Y' AND lc_dc_amt_col IS NOT NULL AND lc_dc_indicator_col IS NOT NULL THEN
      lc_dc_amt_decode    := 'DECODE(SIGN('||lc_dc_amt_col||'),''1'','||''''||lc_debit||''''||','||'''0'','||''''||lc_debit||''''||','||''''||lc_credit||''''||')';
      lc_dc_update_sql    := 'UPDATE XX_AR_EBL_TXT_HDR_STG SET '||lc_dc_indicator_col||' = '||lc_dc_amt_decode||' WHERE rec_type != ''FID'' AND file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_ORDER = '||ln_get_dist_rows;
      lc_err_location_msg := 'Updated Header DC Indicator Column: '||lc_dc_update_sql;
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
      EXECUTE IMMEDIATE lc_dc_update_sql;
	 --START Added by Aniket CG 15 May #NAIT-29364
	ELSIF lc_dc_flag = 'Y' AND  ( lc_dc_amt_col_db IS NOT NULL OR lc_dc_amt_col_cr IS NOT NULL) AND lc_dc_indicator_col IS NOT NULL THEN
	IF lc_dc_flag = 'Y' AND  lc_dc_amt_col_db IS NOT NULL AND lc_dc_indicator_col IS NOT NULL THEN
		lc_dc_amt_decode_db    := 'DECODE(SIGN('||lc_dc_amt_col_db||'),''1'','||''''||lc_debit||''''||','||'''0'','||''''||lc_debit||''''||','||''''||lc_credit||''''||')';
		lc_dc_update_sql_db    := 'UPDATE XX_AR_EBL_TXT_HDR_STG SET '||lc_dc_indicator_col||' = '||lc_dc_amt_decode_db||' WHERE rec_type != ''FID'' AND file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_ORDER = '||ln_get_dist_rows;
		lc_err_location_msg := 'Updated Header Debit Indicator Column: '||lc_dc_update_sql_db;
		XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
		EXECUTE IMMEDIATE lc_dc_update_sql_db;
	END IF;
	IF lc_dc_flag = 'Y' AND  lc_dc_amt_col_cr IS NOT NULL AND lc_dc_indicator_col IS NOT NULL THEN
		lc_dc_amt_decode_cr    := 'DECODE(SIGN('||lc_dc_amt_col_cr||'),''1'','||''''||lc_debit||''''||','||'''0'','||''''||lc_debit||''''||','||''''||lc_credit||''''||')';
		lc_dc_update_sql_cr    := 'UPDATE XX_AR_EBL_TXT_HDR_STG SET '||lc_dc_indicator_col||' = '||lc_dc_amt_decode_cr||' WHERE rec_type != ''FID'' AND file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_ORDER = '||ln_get_dist_rows;
		lc_err_location_msg := 'Updated Header Credit Indicator Column: '||lc_dc_update_sql_cr;
		XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
		EXECUTE IMMEDIATE lc_dc_update_sql_cr;
	END IF;
	--END Added by Aniket CG 15 May #NAIT-29364

    END IF;
    -- End
    IF lc_hs_print_line_num = 'Y' THEN
      lc_err_location_msg  := 'Updating the Line Number in the Header Summary Staging table. ' ;
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
      -- Added by Thilak CG on 25-JUL-2017 for Defect#42380
      lc_hdr_summary_cols := SUBSTR(lc_hdr_summary_col,1,(LENGTH(lc_hdr_summary_col)-1));
      lc_stg_update_query := 'select a.str from (WITH DATA AS
							( SELECT ' ||''''||lc_hdr_summary_cols||''''|| ' str FROM dual
							)
							SELECT trim(regexp_substr(str, ''[^,]+'', 1, LEVEL)) str
							FROM DATA
							CONNECT BY instr(str, '','', 1, LEVEL - 1) > 0) a';
      -- End
      -- Framing the SQL to update the line number in the header staging table
      lc_hs_stg_query := 'SELECT DISTINCT FILE_ID, CUST_DOC_ID, REC_ORDER FROM XX_AR_EBL_TXT_HDR_STG WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_TYPE != '||'''FID'''||' AND REC_ORDER = '||ln_get_dist_rows;
      -- Open the Cursors and update the sequence number
      IF lc_hdr_summary_cols IS NOT NULL THEN
        OPEN c_hs_stg_cursor FOR lc_hs_stg_query; -- hdr cursor.
        LOOP
          FETCH c_hs_stg_cursor INTO ln_hs_file_id, ln_hs_cust_doc_id, ln_hs_rec_order;
          EXIT
        WHEN c_hs_stg_cursor%NOTFOUND;
          ln_hs_line_num := NVL(ln_hs_line_num,0) + 1;
          -- Added by Thilak CG on 25-JUL-2017 for Defect#42380
          OPEN c_stg_row_cursor FOR lc_stg_update_query;
          LOOP
            FETCH c_stg_row_cursor INTO lc_row_seq_col;
            EXIT
          WHEN c_stg_row_cursor%NOTFOUND;
            lc_hs_update_sql    := 'UPDATE XX_AR_EBL_TXT_HDR_STG SET '||lc_row_seq_col||' = '||ln_hs_line_num||' WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_ORDER = '||ln_get_dist_rows;
            lc_err_location_msg := 'Updated Header Row Numbering Column: '||lc_hs_update_sql;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
            EXECUTE IMMEDIATE lc_hs_update_sql;
          END LOOP;
          -- End
        END LOOP;
      END IF;
    END IF;
    -- Added by Punit CG for defect#40174 on 11-AUG-2017
    lc_hdr_sign_cols     := SUBSTR(lc_get_sign_amt_cols,1,LENGTH(lc_get_sign_amt_cols)-1);
    lc_sign_update_query := 'select a.str from (WITH DATA AS
							( SELECT ' ||''''||lc_hdr_sign_cols||''''|| ' str FROM dual
							)
							SELECT trim(regexp_substr(str, ''[^,]+'', 1, LEVEL)) str
							FROM DATA
							CONNECT BY instr(str, '','', 1, LEVEL - 1) > 0) a';
    -- Framing the SQL to update the Sign columns in header staging table
    lc_hs_upd_sign_query:= 'SELECT DISTINCT FILE_ID,CUST_DOC_ID,REC_ORDER FROM XX_AR_EBL_TXT_HDR_STG WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_TYPE != '||'''FID'''||' AND REC_ORDER = '||ln_get_dist_rows;
    -- Open the Cursors and update the Sign columns
	lc_err_location_msg := 'Value of lc_abs_flag is '||lc_abs_flag||' and Value of ln_sign_update_cnt is '||ln_sign_update_cnt;
                  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                     ,FALSE
                                                     ,lc_err_location_msg
                                                    );
    IF ((lc_abs_flag = 'Y') AND (ln_sign_update_cnt = 1)) THEN
      OPEN c_hs_upd_sign_cursor FOR lc_hs_upd_sign_query;
      LOOP
        lc_row_sign_col := NULL;
        FETCH c_hs_upd_sign_cursor
        INTO ln_hs_sign_file_id,
          ln_hs_sign_cust_doc_id,
          ln_hs_sign_rec_order;

        EXIT
      WHEN c_hs_upd_sign_cursor%NOTFOUND;
        OPEN c_sign_row_cursor FOR lc_sign_update_query;
        LOOP
          FETCH c_sign_row_cursor INTO lc_row_sign_col;
          EXIT
        WHEN c_sign_row_cursor%NOTFOUND;
          ln_sign_col_str    := NULL;
          lc_sign_col_decode := NULL;
          BEGIN
            IF lc_amt_sign_flag = 'Y' THEN
              SELECT TO_NUMBER(SUBSTR(lc_row_sign_col,INSTR(lc_row_sign_col,'n')+1))-1
              INTO ln_sign_col_str
              FROM DUAL;
            ELSIF lc_sign_flag = 'Y' THEN
              SELECT TO_NUMBER(SUBSTR(lc_row_sign_col,INSTR(lc_row_sign_col,'n')+1))+1
              INTO ln_sign_col_str
              FROM DUAL;
            END IF;
          EXCEPTION
          WHEN OTHERS THEN
            lc_err_location_msg := 'Error While Selecting the Sign Columns Number : ' || SQLCODE || ' - ' || SQLERRM;
            XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || ln_sign_col_str);
          END;
          BEGIN
            IF ln_sign_col_str     IS NOT NULL THEN
              ln_sign_col_cnt      := 0;
              lc_sign_amt_field_id := NULL;
              EXECUTE IMMEDIATE 'SELECT '||lc_column||ln_sign_col_str|| ' FROM  XX_AR_EBL_TXT_HDR_STG' ||' WHERE file_id = '||p_file_id ||' AND cust_doc_id = '||p_cust_doc_id ||' AND REC_TYPE = '||'''FID''' ||' AND REC_ORDER = '||ln_get_dist_rows INTO lc_sign_amt_field_id;
              lc_err_location_msg := 'Selected Field iD value '||lc_sign_amt_field_id;
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
              SELECT COUNT(flv.lookup_code)
              INTO ln_sign_col_cnt
              FROM fnd_lookup_values_vl FLV
              WHERE FLV.lookup_type      = 'XX_AR_EBL_TXT_HDR_SIGN_COLS'
              AND UPPER(flv.lookup_code) = UPPER(
                (SELECT DISTINCT xftv.source_value4
                FROM Xx_Fin_Translatedefinition Xftd ,
                  Xx_Fin_Translatevalues Xftv
                WHERE xftd.translate_id   = xftv.translate_id
                AND Xftv.Source_Value1    = lc_sign_amt_field_id
                AND xftd.translation_name ='XX_CDH_EBL_TXT_HDR_FIELDS'
                AND Xftv.Enabled_Flag     ='Y'
                AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
                ))
              AND FLV.enabled_flag = 'Y'
              AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
            END IF;
          EXCEPTION
          WHEN OTHERS THEN
            lc_err_location_msg := 'Error while selecting the mapping SIGN column from the lookup XX_AR_EBL_TXT_HDR_SIGN_COLS';
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
            p_hdr_error_flag := 'Y';
            p_hdr_error_msg  := lc_err_location_msg;
          END;
          BEGIN
            IF ln_sign_col_cnt = 1 THEN
              --    ln_sign_col_str    :=  'SUBSTR('||lc_row_sign_col||',INSTR('||lc_row_sign_col||',''N'')+1)'||ln_amtsign_val;
              lc_sign_col_decode      := 'DECODE(SIGN('||lc_column||ln_sign_col_str||'),''1'',''+'',''-1'',''-'','''')';
              lc_update_sign_amt_cols := 'UPDATE XX_AR_EBL_TXT_HDR_STG SET ' ||lc_row_sign_col ||' = '||lc_sign_col_decode ||' WHERE file_id = '||p_file_id ||' AND cust_doc_id = '||p_cust_doc_id ||' AND REC_TYPE != '||'''FID''' ||' AND REC_ORDER = '||ln_get_dist_rows;
              EXECUTE IMMEDIATE lc_update_sign_amt_cols;
              lc_err_location_msg := 'Executed Sign Column updates in XX_AR_EBL_TXT_HDR_STG table';
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg|| '-' ||lc_update_sign_amt_cols );
            END IF;
          EXCEPTION
          WHEN OTHERS THEN
            lc_err_location_msg := 'Error While Updating the Sign Columns of Header Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
            XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_sign_amt_cols);
            p_hdr_error_flag := 'Y';
            p_hdr_error_msg  := lc_err_location_msg;
          END;
        END LOOP;
      END LOOP;
    END IF;
    -- End of Added by Punit CG for defect#40174 on 11-AUG-2017
    -- Added by Thilak CG for defect#40174 on 08-AUG-2017
    IF ((lc_abs_flag          = 'Y') AND (ln_abs_update_cnt = 1)) THEN
      lc_update_abs_amt_cols := 'UPDATE XX_AR_EBL_TXT_HDR_STG SET' || SUBSTR(lc_get_abs_amt_cols,1,LENGTH(lc_get_abs_amt_cols)-1) || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' || p_cust_doc_id || ' AND file_id = ' || p_file_id||' AND REC_ORDER = '||ln_get_dist_rows;
      BEGIN
        EXECUTE IMMEDIATE lc_update_abs_amt_cols;
        lc_err_location_msg := 'Executed Absolute Amount update in XX_AR_EBL_TXT_HDR_STG table';
        XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg|| ' - ' ||lc_update_abs_amt_cols );
      EXCEPTION
      WHEN OTHERS THEN
        lc_err_location_msg := 'Error While Updating the Absolute Amount Columns of Header Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
        XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_abs_amt_cols);
        p_hdr_error_flag := 'Y';
        p_hdr_error_msg  := lc_err_location_msg;
      END;
    END IF;
    -- End
    p_hdr_error_flag := 'N';
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  lc_err_location_msg := 'Error While Inserting the data into header Staging Table : '||SQLCODE||' - '||SQLERRM ;
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
  p_hdr_error_flag := 'Y';
  p_hdr_error_msg  := lc_err_location_msg;
END PROCESS_TXT_HDR_SUMMARY_DATA;
-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : PROCESS_TXT_DTL_DATA                                                        |
-- | Description : This Procedure is used for to framing the dynamic query to fetch data       |
-- |               from the configuration detail table and to poplate the                      |
-- |               dtl txt stagging table                                                      |
-- |Parameters   : p_batch_id                                                                  |
-- |             , p_cust_doc_id                                                               |
-- |             , p_file_id                                                                   |
-- |             , p_cycle_date                                                                |
-- |             , p_org_id                                                                    |
-- |             , p_debug_flag                                                                |
-- |             , p_error_flag                                                                |
-- |                                                                                           |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                       |
-- |      1.1 14-FEB-2017  Punit Gupta CG         Requirement# (2282,2302,40015)               |
-- |      1.2 15-APR-2017  Punit Gupta CG          Changes done for the defect # 41733         |
-- |      1.3 25-MAY-2017  Punit Gupta CG          Changes done for  Defect #42226             |
-- |      1.4 05-JUN-2017  Punit Gupta CG          Changes done for  Defect #42312             |
-- |      1.5 12-JUN-2017  Punit Gupta CG          Changes for the defect#42381                |
-- |      1.6 21-JUN-2017  Punit Gupta CG          Changes for the defect#42496                |
-- |      1.7 05-JUL-2017  Punit Gupta CG          Changes for the defect#39140                |
-- |      1.8 12-JUL-2017  Punit Gupta CG          Changes for the defect#41307                |
-- |      1.9 11-AUG-2017  Punit Gupta CG          Changes for the defect#40174                |
-- |      2.0 15-DEC-2017  Aniket      CG          Changes for the defect#22772                |
-- |      2.1 22-Jan-2018  Aniket      CG          Changes for Defect#24883                    |
-- |      2.2 01-Mar-2018  Thilak      CG          Changes for Defect#29739                    |
-- |      2.3 15-May-2018  Aniket J    CG          Changes for Requirement  #NAIT-29364        |
-- |      2.4 09-JUN-2018  Thilak      CG          Changes for Requirement#NAIT-17796          |
-- |      2.5 09-JUN-2018  Aniket J    CG          Changes for Requirement#NAIT-50280          |
-- +===========================================================================================+
PROCEDURE PROCESS_TXT_DTL_DATA(
    p_batch_id    IN NUMBER ,
    p_cust_doc_id IN NUMBER ,
    p_file_id     IN NUMBER ,
    p_cycle_date  IN VARCHAR2 ,
    p_org_id      IN NUMBER ,
    p_debug_flag  IN VARCHAR2 ,
    p_cmb_splt_whr   IN VARCHAR2 , --Added by Aniket CG #22772 on 15 Dec 2017
    p_cmb_splt_splfunc_whr IN VARCHAR2 , --Added by Aniket CG #22772 on 15 Dec 2017
    p_dtl_error_flag OUT VARCHAR2 ,
    p_dtl_error_msg OUT VARCHAR2)
IS
  -- Added and Modified by Punit on 12-JUL-2017 for Defect # 41307
  CURSOR get_dist_rows
  IS
    SELECT DISTINCT rownumber
    FROM xx_cdh_ebl_templ_dtl_txt
    WHERE cust_doc_id = p_cust_doc_id
      --AND attribute1 = 'Y'
    AND attribute20 = 'Y'
    ORDER BY rownumber;
  ln_get_line_dist_rows NUMBER;
  CURSOR get_dist_record_type (p_rownum IN NUMBER)
  IS
    SELECT DISTINCT record_type
    FROM xx_cdh_ebl_templ_dtl_txt
    WHERE cust_doc_id = p_cust_doc_id
    AND rownumber     = p_rownum -- Added by Punit on 12-JUL-2017 for Defect # 41307
    ORDER BY record_type;
  lc_get_dist_record_type VARCHAR2(100);
  CURSOR c_get_dtl_fields_info(p_record_type IN VARCHAR2,p_rownum IN NUMBER)
    -- End of Added and Modified by Punit on 12-JUL-2017 for Defect # 41307
  IS
    SELECT to_number(xftv.source_value1) field_id ,
      xftv.target_value20 tab_name ,
      xftv.source_value4 col_name ,
      xcetdt.seq record_order ,
      xcetdt.label ,
      xcetdt.constant_value cons_val ,
      xftv.target_value14 spl_fields ,
      xftv.target_value1 data_type ,
      xftv.target_value19 rec_type ,
      xcetdt.cust_doc_id ,
      'DETAIL' record_level ,
      xcetdt.record_type record_type ,
      xcetdt.rownumber rec_order, --Added by Punit on 12-JUL-2017 for Defect # 41307
      xftv.target_value24 spl_function ,
      xcetdt.base_field_id
      --   Added by Punit CG on 06-FEB-2017 For requirement #2282 #2302(C,D)
      ,
      xcetdt.repeat_total_flag ,
      xcetdt.tax_up_flag ,
      xcetdt.freight_up_flag ,
      xcetdt.misc_up_flag ,
      xcetdt.tax_ep_flag ,
      xcetdt.freight_ep_flag ,
      xcetdt.misc_ep_flag
      --  End of Addition by Punit CG on 06-FEB-2017 For requirement #2282 #2302(C,D)
      ,
      xcetdt.sort_order ,
      xcetdt.sort_type
      -- Added by Thilak CG for Defect#40174 on 07-AUG-2017
      ,
      xcetdt.absolute_flag ,
      xcetdt.dc_indicator ,
      -- End
	--Added by Aniket CG 15 May #NAIT-29364
    xcetdt.db_cr_seperator
    --Added by Aniket CG 15 May #NAIT-29364
    FROM xx_fin_translatedefinition xftd ,
      xx_fin_translatevalues xftv ,
      xx_cdh_ebl_templ_dtl_txt xcetdt
    WHERE xftd.translate_id   = xftv.translate_id
    AND xftv.source_value1    = xcetdt.field_id
    AND xcetdt.cust_doc_id    = p_cust_doc_id
    AND xcetdt.record_type    = p_record_type
    AND xcetdt.rownumber      = p_rownum -- Added by Punit on 12-JUL-2017 for Defect # 41307
    AND xftd.translation_name ='XX_CDH_EBL_TXT_DET_FIELDS'
    AND xftv.target_value19   = 'DT' -- Uncommented by Punit on 25-MAY-2017
    AND xftv.enabled_flag     ='Y'
    AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
    AND xcetdt.attribute20 = 'Y'
  UNION
  SELECT xcetdt.FIELD_ID ,
    'Concatenate' tab_name
    --,NULL col_name
    ,
    get_conc_field_names(xcetdt.cust_doc_id, xcecft.conc_field_id, 'DTL', xcetdt.record_type, p_debug_flag, p_file_id) ,
    xcetdt.seq record_order ,
    xcetdt.label ,
    NULL cons_val ,
    NULL spl_fields ,
    'VARCHAR2' data_type ,
    'DT' rec_type ,
    xcetdt.cust_doc_id ,
    'DETAIL' record_level ,
    xcetdt.record_type record_type ,
    xcetdt.rownumber rec_order, --Added by Punit on 12-JUL-2017 for Defect # 41307
    NULL spl_function ,
    xcetdt.base_field_id
    --   Added by Punit CG on 06-FEB-2017 For requirement #2282 #2302(C,D)
    ,
    NULL ,
    NULL ,
    NULL ,
    NULL ,
    NULL ,
    NULL ,
    NULL
    -- End of  Addition by Punit CG on 06-FEB-2017 For requirement #2282 #2302(C,D)
    ,
    xcetdt.sort_order ,
    xcetdt.sort_type
    -- Added by Thilak CG for Defect#40174 on 07-AUG-2017
    ,
    NULL ,
    NULL ,
    -- End
	 --Added by Aniket CG 15 May #NAIT-29364
    xcetdt.db_cr_seperator
    --Added by Aniket CG 15 May #NAIT-29364
  FROM xx_cdh_ebl_templ_dtl_txt xcetdt ,
    xx_cdh_ebl_concat_fields_txt xcecft
  WHERE xcetdt.field_id  = xcecft.conc_field_id
  AND xcetdt.cust_doc_id = xcecft.cust_doc_id
  AND xcetdt.cust_doc_id = p_cust_doc_id
  AND xcetdt.record_type = p_record_type
  AND xcetdt.rownumber   = p_rownum -- Added by Punit on 12-JUL-2017 for Defect # 41307
  AND xcecft.tab         = 'D'
  UNION -- Query to get the Split Columns Columns
  SELECT xcetdt.FIELD_ID ,
    'Split' tab_name ,
    NULL--'split_column_name'--GET SPLIT FIELDS
    ,
    xcetdt.seq ,
    xcetdt.label ,
    NULL cons_val ,
    NULL spl_fields ,
    'VARCHAR2' data_type ,
    'DT' rec_type ,
    xcetdt.cust_doc_id ,
    'DETAIL' record_level ,
    NULL ,
    NULL ,
    NULL , --Added by Punit on 12-JUL-2017 for Defect # 41307
    xcetdt.base_field_id
    --   Added by Punit CG on 06-FEB-2017 For requirement #2282 #2302(C,D)
    ,
    NULL ,
    NULL ,
    NULL ,
    NULL ,
    NULL ,
    NULL ,
    NULL
    -- End of Addition by Punit CG on 06-FEB-2017 For requirement #2282 #2302(C,D)
    ,
    xcetdt.sort_order ,
    xcetdt.sort_type
    -- Added by Thilak CG for Defect#40174 on 07-AUG-2017
    ,
    NULL ,
    NULL ,
    -- End
	 --Added by Aniket CG 15 May #NAIT-29364
    xcetdt.db_cr_seperator
    --Added by Aniket CG 15 May #NAIT-29364
  FROM xx_cdh_ebl_templ_dtl_txt xcetdt
  WHERE xcetdt.cust_doc_id = p_cust_doc_id
  AND xcetdt.record_type   = p_record_type
  AND xcetdt.rownumber     = p_rownum -- Added by Punit on 12-JUL-2017 for Defect # 41307
  AND base_field_id       IS NOT NULL
  AND attribute20          = 'Y'
  ORDER BY record_order;
  lc_from_cons_hdr          CONSTANT VARCHAR2(1000)  := ' FROM xx_ar_ebl_cons_hdr_main hdr WHERE hdr.cust_doc_id = '||p_cust_doc_id||' AND hdr.file_id = '||p_file_id||' AND hdr.org_id = '||p_org_id;
  lc_from_cons_dtl          CONSTANT VARCHAR2(1000)  := ' FROM xx_ar_ebl_cons_hdr_main hdr, xx_ar_ebl_cons_dtl_main dtl WHERE hdr.customer_trx_id = dtl.customer_trx_id AND hdr.parent_cust_doc_id = dtl.parent_cust_doc_id and dtl.trx_line_type = ''ITEM'' AND hdr.org_id='|| p_org_id||' AND hdr.cust_doc_id = '||p_cust_doc_id||' AND hdr.file_id = '||p_file_id;
  lc_select_cons_hdr        CONSTANT VARCHAR2(32767) := ' (SELECT XX_AR_EBL_TXT_STG_ID_S.nextval,hdr.parent_cust_doc_id,hdr.customer_trx_id,hdr.file_id,fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,';
  lc_select_cons_dtl        CONSTANT VARCHAR2(32767) := ' (SELECT XX_AR_EBL_TXT_STG_ID_S.nextval,hdr.parent_cust_doc_id,hdr.customer_trx_id,hdr.cons_inv_id,dtl.trx_line_number,dtl.customer_trx_line_id,hdr.file_id,fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,';
  lc_insert_hdr_const_cols  CONSTANT VARCHAR2(500)   := 'INSERT INTO xx_ar_ebl_txt_dtl_stg (stg_id,cust_doc_id,customer_trx_id,file_id,created_by,creation_date,last_updated_by,last_update_date,last_update_login,trx_type,rec_type,rec_order,cycle_date,batch_id,';                                                  -- Added rec_order column by Punit for Defect# 41307
  lc_insert_dtl_const_cols  CONSTANT VARCHAR2(500)   := 'INSERT INTO xx_ar_ebl_txt_dtl_stg (stg_id,cust_doc_id,customer_trx_id,cons_inv_id,trx_line_number,customer_trx_line_id,file_id,created_by,creation_date,last_updated_by,last_update_date,last_update_login,trx_type,rec_type,rec_order,cycle_date,batch_id,'; -- Added rec_order column by Punit for Defect# 41307
  lc_column                 VARCHAR2(100)             := 'column';
  lc_select_var_cols        VARCHAR2(32767);
  lc_insert_col_name        VARCHAR2(32767);
  ln_count                  NUMBER;
  lc_dtl_value_fid          VARCHAR2(32767);
  lc_function               VARCHAR2(32767);
  lc_function_return        VARCHAR2(32767);
  lc_seq_num_exists         VARCHAR2(1);
  lc_dist_seq_num_exists    VARCHAR2(1);
  lc_seq_num_col            VARCHAR2(1000);
  lc_err_location_msg       VARCHAR2(32767);
  lb_debug_flag             BOOLEAN;
  ln_seq_num_fid            NUMBER;
  ln_current_cust_doc_id    NUMBER;
  ln_current_base_field_id  NUMBER;
  ln_current_file_id        NUMBER;
  ln_previous_cust_doc_id   NUMBER;
  ln_previous_base_field_id NUMBER;
  ln_previous_file_id       NUMBER;
  ln_count1                 NUMBER := 0;
  lc_dist_seq_num_col       VARCHAR2(1000);
  ln_dist_seq_num_fid       NUMBER;
  /* Start of Defined the below  variables for Requirement #2282 by Punit CG on 06-FEB-2017*/
  lc_totals_repeat_flg       VARCHAR2(1);
  lc_get_total_amt_cols      VARCHAR2(32767);
  ln_total_default           VARCHAR2(10) := '0.00';
  lc_update_total_amt_cols   VARCHAR2(32767);
  lc_update_tax_amt_cols     VARCHAR2(32767);
  lc_update_freight_amt_cols VARCHAR2(32767);
  lc_update_misc_amt_cols    VARCHAR2(32767);
  lc_total_column_rpt_elig   VARCHAR2(1) :='N';
  ln_repeat_cnt              NUMBER      := 0;
  ln_update_cnt              NUMBER      := 0;
  lc_repeat_total            VARCHAR2(1) := 'Y';
  /* End of Defined the below variables for Requirement #2282 by Punit CG on 06-FEB-2017*/
  /* Start of Defining the below  variables for Requirement #2303 by Punit CG on 08-FEB-2017*/
  lc_select_non_dt             VARCHAR2(32767);
  lc_insert_col_name_ndt       VARCHAR2(32767);
  lc_insert_select_ndt         VARCHAR2(32767);
  lc_select_ndt                VARCHAR2(32767);
  lc_decode_non_dt             CONSTANT VARCHAR2(1000) := 'DECODE(INSTR(NVL(xxx,''xx''),''$value$''),0,xxx,SUBSTR(xxx,1,INSTR(xxx,''$value$'')-1)|| yyy ||SUBSTR(xxx,INSTR(xxx,''$value$'') + 7))';
--START Added by Aniket CG 15 May #NAIT-29364
  lc_decode_non_dt_db             CONSTANT VARCHAR2(1000) := 'DECODE(INSTR(NVL(xxx,''xx''),''$value1$''),0,xxx,SUBSTR(xxx,1,INSTR(xxx,''$value1$'')-1)|| yyy ||SUBSTR(xxx,INSTR(xxx,''$value1$'') + 8))';
  lc_decode_non_dt_cr             CONSTANT VARCHAR2(1000) := 'DECODE(INSTR(NVL(xxx,''xx''),''$value2$''),0,xxx,SUBSTR(xxx,1,INSTR(xxx,''$value2$'')-1)|| yyy ||SUBSTR(xxx,INSTR(xxx,''$value2$'') + 8))';
--END Added by Aniket CG 15 May #NAIT-29364
  lc_decode_product            CONSTANT VARCHAR2(1000) := 'DECODE(xftv.target_value19,''TX'',''TAX'',''DL'',''DELIVERY'',''MS'',''MISC'')';
  lc_decode_sku                CONSTANT VARCHAR2(1000) := 'DECODE(xftv.target_value19,''TX'',''Sales Tax'',''DL'',''Delivery'',''MS'',''Misc'')';
  lc_decode_verbiage           VARCHAR2(10000);
  lc_decode_hdr_col            VARCHAR2(1000) := get_decode_ndt(p_debug_flag); -- The value wiil be returned by the function will be similar to this 'TO_CHAR(DECODE(xxfv.Target_Value19,''CP'', hdr.TOTAL_COUPON_AMOUNT, ''GC'', hdr.TOTAL_GIFT_CARD_AMOUNT, ''TD'', hdr.TOTAL_TIERED_DISCOUNT_AMOUNT, ''MS'', hdr.TOTAL_MISCELLANEOUS_AMOUNT, ''DL'', hdr.TOTAL_FRIEGHT_AMOUNT, ''BD'', hdr.TOTAL_BULK_AMOUNT, ''PST'', hdr.TOTAL_PST_AMOUNT, ''GST'', hdr.TOTAL_GST_AMOUNT, ''QST'', hdr.TOTAL_QST_AMOUNT, ''TX'', hdr.TOTAL_US_TAX_AMOUNT, ''HST'', hdr.TOTAL_HST_AMOUNT, ''AD'', hdr.TOTAL_ASSOCIATION_DISCOUNT))';
  lc_lkp_meaning               VARCHAR2(50);
  lc_lkp_tag                   VARCHAR2(50);
  lc_lkp_lookup_code           VARCHAR2(1000);
  lc_insert_status             VARCHAR2(1000);
  lc_select_const_cols_dtl     CONSTANT VARCHAR2(32767) := ' (SELECT XX_AR_EBL_TXT_STG_ID_S.nextval,hdr.parent_cust_doc_id,hdr.customer_trx_id,hdr.file_id,fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,''LINE'',';
  lc_insert_const_cols_dtl     CONSTANT VARCHAR2(5000)   := 'INSERT INTO xx_ar_ebl_txt_dtl_stg (stg_id,cust_doc_id,customer_trx_id,file_id,created_by,creation_date,last_updated_by,last_update_date,last_update_login,TRX_TYPE,Batch_Id,NONDT_VALUE,trx_line_number,rec_type,REC_ORDER,cycle_date,';
  lc_unitprice_col             VARCHAR2(150)            := NULL;
  lc_ext_col                   VARCHAR2(150)            := NULL;
  lc_ext_price                 VARCHAR2(5000)           := NULL;
  lc_unit_price                VARCHAR2(5000)           := NULL;
  lc_update_unitprice_ndt      VARCHAR2(32767);
  lc_update_extprice_ndt       VARCHAR2(32767);
  lc_tax_col                   VARCHAR2(150)  := NULL;
  lc_freight_col               VARCHAR2(150)  := NULL;
  lc_misc_col                  VARCHAR2(150)  := NULL;
  lc_tax_up_flag               VARCHAR2(15)   := NULL;
  lc_freight_up_flag           VARCHAR2(15)   := NULL;
  lc_misc_up_flag              VARCHAR2(15)   := NULL;
  lc_tax_ep_flag               VARCHAR2(15)   := NULL;
  lc_freight_ep_flag           VARCHAR2(15)   := NULL;
  lc_misc_ep_flag              VARCHAR2(15)   := NULL;
  lc_tax_amt                   VARCHAR2(5000) := NULL;
  lc_freight_amt               VARCHAR2(5000) := NULL;
  lc_misc_amt                  VARCHAR2(5000) := NULL;
  ln_nondt_qty                 NUMBER         := NULL;
  ln_nondt_qty_update          VARCHAR2(32767);
  lc_update_nondt_qty_amt_cols VARCHAR2(32767);
  lc_rec_type                  VARCHAR2(15):= NULL; -- Added on 12-JUN-2017
  lc_qty_ship_exists           VARCHAR2(1) := 'N';  -- Added on 21-JUN-2017
  /* End of Defined the below  variables for Requirement #2302 by Punit CG on 08-FEB-2017*/
  lc_seq_ndt VARCHAR2(15); -- Defined the variable for Defect #39140 by Punit CG on 05-JUL-2017
  -- Below variables added by Punit CG on 11-AUG-2017 for Defect#40174
  ln_sign_cnt             NUMBER := 0;
  lc_get_sign_amt_cols    VARCHAR2(32767);
  lc_update_sign_amt_cols VARCHAR2(32767);
  ln_sign_update_cnt      NUMBER        := 0;
  ln_sign_ind_flag        VARCHAR2(1)   := 'N';
  lc_amt_col_for_sign     VARCHAR2(15)  := NULL;
  lc_sign_col_decode      VARCHAR2(5000) := NULL;
  ln_sign_col_str         NUMBER        := NULL;
  lc_sign_flag            VARCHAR2(1)   := 'N';
  lc_amt_sign_flag        VARCHAR2(1)   := 'N';
  ln_sign_col_cnt         NUMBER        := 0;
  lc_sign_amt_field_id    VARCHAR2(15)  := NULL;
  lc_select_sign_amt_cols VARCHAR2(32767);
TYPE lc_ref_cursor_dtl
IS
  REF
  CURSOR;
    c_dtl_upd_sign_cursor lc_ref_cursor_dtl;
    c_sign_row_cursor lc_ref_cursor_dtl;
    c_dtl_update_sql        VARCHAR2(32767);
    ln_dtl_sign_file_id     VARCHAR2(15);
    ln_dtl_sign_cust_doc_id VARCHAR2(15);
    ln_dtl_sign_rec_order   VARCHAR2(10);
    lc_dtl_sign_cols        VARCHAR2(2000);
    lc_row_sign_col         VARCHAR2(1000);
    lc_dtl_upd_sign_query   VARCHAR2(32767);
    lc_sign_update_query    VARCHAR2(32767);
    -- End of Below variables added by Punit CG on 11-AUG-2017 for Defect#40174
    lc_print_hdr_line_num     VARCHAR2(1) := 'N';
    lc_hdr_line_num_col       VARCHAR2(1000);
    ln_hdr_line_num_fid       NUMBER;
    ln_hdr_line_num_source    VARCHAR2(1000);
    lc_print_line_line_num    VARCHAR2(1) := 'N';
    lc_line_line_num_col      VARCHAR2(1000);
    ln_line_line_num_fid      NUMBER;
    ln_line_line_num_source   VARCHAR2(1000);
    lc_print_dist_line_num    VARCHAR2(1) := 'N';
    lc_dist_line_num_col      VARCHAR2(1000);
    ln_dist_line_num_fid      NUMBER;
    ln_dist_line_num_source   VARCHAR2(1000);
    lc_hdr_sort_columns       VARCHAR2(2000);
    lc_line_sort_columns      VARCHAR2(2000);
    lc_dist_line_sort_columns VARCHAR2(2000);
    lc_hdr_stg_query          VARCHAR2(32767);
    lc_line_stg_query         VARCHAR2(32767);
    lc_dist_stg_query         VARCHAR2(32767);
  TYPE lc_ref_cursor
  IS
  REF
  CURSOR;
    c_hdr_stg_cursor lc_ref_cursor;
    c_line_stg_cursor lc_ref_cursor;
    c_dist_line_stg_cursor lc_ref_cursor;
    lc_update_hdr_sql       VARCHAR2(32767);
    lc_update_line_sql      VARCHAR2(32767);
    lc_update_dist_line_sql VARCHAR2(32767);
    ln_customer_trx_id      NUMBER;
    ln_customer_trx_line_id NUMBER;
    ln_stg_id               NUMBER;
	ln_hdr_sum_num_max      NUMBER;
	ln_hdr_line_num_max     NUMBER;
    ln_hdr_line_num         NUMBER;
    ln_line_line_num        NUMBER;
    ln_dist_line_num        NUMBER;
    lc_target_value1        VARCHAR2(1) := 'N';
    lc_target_value2        VARCHAR2(1) := 'N';
    lc_target_value3        VARCHAR2(1) := 'N';
    lc_include_label        VARCHAR2(1);
    ln_previous_trx_id      NUMBER;
    ln_current_trx_id       NUMBER;
    CURSOR c_get_summary_fields_info
    IS
      SELECT to_number(xftv.source_value1) field_id ,
        xftv.target_value20 tab_name ,
        xftv.source_value4 col_name ,
        xcetdt.seq record_order ,
        xcetdt.label ,
        xcetdt.constant_value cons_val ,
        xftv.target_value14 spl_fields ,
        xftv.target_value1 data_type ,
        xftv.target_value19 rec_type ,
        xcetdt.cust_doc_id ,
        'DETAIL' record_level ,
        xcetdt.record_type record_type
        --,xcetdt.rownumber --Added by Punit on 12-JUL-2017 for Defect # 41307
        ,
        xftv.target_value24 spl_function ,
        xcetdt.base_field_id ,
        xcetdt.sort_order ,
        xcetdt.sort_type ,
        xftv.target_value25 summary_field
        -- Added by Thilak CG for Defect#40174 on 07-AUG-2017
        ,
        xcetdt.absolute_flag ,
        xcetdt.dc_indicator
        -- End
      FROM xx_fin_translatedefinition xftd ,
        xx_fin_translatevalues xftv ,
        xx_cdh_ebl_templ_dtl_txt xcetdt
      WHERE xftd.translate_id   = xftv.translate_id
      AND xftv.source_value1    = xcetdt.field_id
      AND xcetdt.cust_doc_id    = p_cust_doc_id
      AND xftd.translation_name ='XX_CDH_EBL_TXT_DET_FIELDS'
      AND xftv.target_value19   = 'DT' -- Uncommented by Punit on 25-MAY-2017
      AND xftv.enabled_flag     ='Y'
      AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
      AND XCETDT.ATTRIBUTE20 = 'Y'
      ORDER BY record_order;
    lc_summary_bill_doc          VARCHAR2(1);
    lc_summary_var_cols          VARCHAR2(32767);
    lc_summary_value_fid         VARCHAR2(32767);
    lc_summary_insert_col_name   VARCHAR2(32767);
    lc_insert_summary_const_cols CONSTANT VARCHAR2(500)   := 'INSERT INTO xx_ar_ebl_txt_dtl_stg (stg_id,cust_doc_id,file_id,created_by,creation_date,last_updated_by,last_update_date,last_update_login,trx_type,rec_type,cycle_date,batch_id,';
	--Commented for Defect# 14525 by Thilak CG
    --lc_summary_from_cons         CONSTANT VARCHAR2(1000)  := ' FROM xx_ar_ebl_cons_hdr_main hdr, xx_ar_ebl_cons_dtl_main dtl WHERE hdr.customer_trx_id = dtl.customer_trx_id AND hdr.parent_cust_doc_id = dtl.parent_cust_doc_id and dtl.trx_line_type = ''ITEM'' AND hdr.org_id='|| p_org_id||' AND hdr.cust_doc_id = '||p_cust_doc_id||' AND hdr.file_id = '||p_file_id;
	--Added for Defect# 14525 by Thilak CG
    lc_summary_from_cons         CONSTANT VARCHAR2(1000)  := ' FROM xx_ar_ebl_cons_hdr_main hdr WHERE hdr.org_id='|| p_org_id||' AND hdr.cust_doc_id = '||p_cust_doc_id||' AND hdr.file_id = '||p_file_id;
    --End
    lc_summary_select_cons       CONSTANT VARCHAR2(32767) := ' hdr.parent_cust_doc_id,hdr.file_id,fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,';
    lc_summary_group_by          CONSTANT VARCHAR2(100)   := ' GROUP BY ';
    lc_summary_group_cols        VARCHAR2(32767);
    ln_print_summary_line_num    VARCHAR2(1) := 'N';
    ln_summary_line_num          NUMBER;
    lc_summary_col               VARCHAR2(1000);
    lc_summary_stg_query         VARCHAR2(32767);
    c_summary_stg_cursor lc_ref_cursor;
    lc_update_summary_sql      VARCHAR2(32767);
    lc_summary_sort_columns    VARCHAR2(2000);
    ln_summary_customer_trx_id NUMBER;
    ln_summary_row_id ROWID;
    -- Below variables added by Thilak CG 25-Jun-2017 for Defect#42380
    lc_summary_cols     VARCHAR2(1000);
    lc_row_seq_col      VARCHAR2(1000);
    lc_stg_update_query VARCHAR2(32767);
    c_stg_row_cursor lc_ref_cursor;
    lc_hdr_line_num_cols     VARCHAR2(1000);
    lc_line_line_num_cols    VARCHAR2(1000);
    lc_dist_line_num_cols    VARCHAR2(1000);
    lc_hdr_row_seq_col       VARCHAR2(1000);
    lc_line_row_seq_col      VARCHAR2(1000);
    lc_dist_row_seq_col      VARCHAR2(1000);
	lc_spilt_label           VARCHAR2(1000);
    lc_hdr_stg_update_query  VARCHAR2(32767);
    lc_line_stg_update_query VARCHAR2(32767);
    lc_dist_stg_update_query VARCHAR2(32767);
    c_hdr_stg_row_cursor lc_ref_cursor;
    c_line_stg_row_cursor lc_ref_cursor;
    c_dist_stg_row_cursor lc_ref_cursor;
    -- End
    -- Below variables added by Thilak CG 07-AUG-2017 for Defect#40174
    lc_get_abs_amt_cols    VARCHAR2(32767);
    lc_update_abs_amt_cols VARCHAR2(32767);
    ln_abs_cnt             NUMBER        := 0;
    ln_abs_update_cnt      NUMBER        := 0;
    lc_abs_flag            VARCHAR2(1)   := 'N';
    lc_dc_flag             VARCHAR2(1)   := 'N';
    lc_debit               VARCHAR2(15)  := NULL;
    lc_credit              VARCHAR2(15)  := NULL;
    lc_dc_amt_col          VARCHAR2(15)  := NULL;
    lc_dc_indicator_col    VARCHAR2(15)  := NULL;
    lc_dc_amt_decode       VARCHAR2(1000) := NULL;
    lc_dc_update_sql       VARCHAR2(32767);
    -- End
	lc_nondt_concat_cols    VARCHAR2(10000);
	 -- start Added by Aniket CG 15 May #NAIT-29364
	 lc_db_cr_nvl_value   VARCHAR2(10);
      lc_ext_col_db                   VARCHAR2(150)            := NULL;
      lc_ext_price_db                 VARCHAR2(5000)           := NULL;
      lc_update_extprice_db_ndt       VARCHAR2(32767);
      lc_freight_up_flag_db           VARCHAR2(15)   := NULL;
      lc_misc_up_flag_db              VARCHAR2(15)   := NULL;
      lc_tax_ep_flag_db               VARCHAR2(15)   := NULL;
      lc_freight_ep_flag_db           VARCHAR2(15)   := NULL;
      lc_misc_ep_flag_db              VARCHAR2(15)   := NULL;

      lc_ext_db_nvl_value   VARCHAR2(10);
      lc_ext_cr_nvl_value   VARCHAR2(10);
      lc_ext_col_cr                   VARCHAR2(150)            := NULL;
      lc_ext_price_cr                 VARCHAR2(5000)           := NULL;
      lc_update_extprice_cr_ndt       VARCHAR2(32767);
      lc_freight_up_flag_cr           VARCHAR2(15)   := NULL;
      lc_misc_up_flag_cr             VARCHAR2(15)   := NULL;
      lc_tax_ep_flag_cr               VARCHAR2(15)   := NULL;
      lc_freight_ep_flag_cr           VARCHAR2(15)   := NULL;
      lc_misc_ep_flag_cr              VARCHAR2(15)   := NULL;

      lc_dc_col_orig_flgchk    VARCHAR2(15)  := 'N';
      lc_dc_col_ext_flgchk    VARCHAR2(15)  := 'N';
      lc_dc_amt_col_db          VARCHAR2(15)  :=  NULL;
      lc_dc_amt_col_cr          VARCHAR2(15)  :=  NULL;
      lc_dc_amt_decode_db       VARCHAR2(1000) := NULL;
      lc_dc_amt_decode_cr       VARCHAR2(1000) := NULL;
      lc_dc_update_sql_db       VARCHAR2(32767);
      lc_dc_update_sql_cr       VARCHAR2(32767);
    --end Added by Aniket CG 15 May #NAIT-29364
	  lv_fee_option    NUMBER := 0;
	  lv_hide_flag     VARCHAR2(200);
  	lv_upd_str     VARCHAR2(2000) := NULL;
    lv_upd_str1    VARCHAR2(2000) := NULL;
	ln_hdr_fee     NUMBER := 0;
	ln_hdr_cnt     NUMBER := 0;
  BEGIN
    IF (p_debug_flag = 'Y') THEN
      lb_debug_flag := TRUE;
    ELSE
      lb_debug_flag := FALSE;
    END IF;
	  BEGIN
	    SELECT fee_option
		  INTO lv_fee_option
		  FROM xx_cdh_cust_acct_ext_b
		 WHERE N_EXT_ATTR2 = p_cust_doc_id AND Attr_group_id = 166 and rownum =1;
	  EXCEPTION WHEN OTHERS THEN
	    lv_fee_option:= 0;
	  END;
	
    BEGIN
      SELECT NVL(SUMMARY_BILL,'N')
      INTO lc_summary_bill_doc
      FROM XX_CDH_EBL_MAIN
      WHERE cust_doc_id = p_cust_doc_id;
    EXCEPTION
    WHEN OTHERS THEN
      lc_summary_bill_doc := 'N';
    END;
	BEGIN
	 
	    SELECT count(0)
		  INTO ln_hdr_fee
		FROM xx_fin_translatedefinition xftd ,
		  xx_fin_translatevalues xftv ,
		  xx_cdh_ebl_templ_hdr_txt xcetht
		WHERE xftd.translate_id   = xftv.translate_id
		AND xftv.source_value1    = xcetht.field_id
		AND xcetht.cust_doc_id    = p_cust_doc_id
--		AND xcetht.rownumber      = p_rownum
		AND xftd.translation_name ='XX_CDH_EBL_TXT_HDR_FIELDS'
		AND xftv.target_value19   = 'DT' 
		AND xftv.enabled_flag     ='Y'
		AND UPPER(xftv.target_value24) = 'XX_AR_EBL_TXT_SPL_LOGIC_PKG.GET_FEE_AMOUNT'
		AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1));
	
    EXCEPTION
    WHEN OTHERS THEN
      ln_hdr_fee := 0;	
	END;
	
	
	
    IF lc_summary_bill_doc = 'Y' THEN
      lc_err_location_msg := 'Selected Cust Doc Id : '||p_cust_doc_id||' is Summary Bill Doc';
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
      ln_count := 1;
      SELECT XX_AR_EBL_TXT_STG_ID_S.nextval INTO ln_stg_id FROM DUAL;
      lc_get_abs_amt_cols    := NULL;
      ln_abs_update_cnt      := 0;
      ln_abs_cnt             := 0;
      lc_dc_flag             := 'N';
      lc_debit               := NULL;
      lc_credit              := NULL;
      lc_dc_amt_col          := NULL;
      lc_dc_amt_decode       := NULL;
      lc_dc_indicator_col    := NULL;
      lc_dc_update_sql       := NULL;
      FOR lc_get_summary_fields_info IN c_get_summary_fields_info
      LOOP
	    lv_hide_flag := 'N';
        IF ln_count             = 1 THEN
          lc_select_var_cols   := '''SUMMARY'''||','||''''||lc_get_summary_fields_info.rec_type||''''||',' ||'TO_DATE('||''''||p_cycle_date||''''||',''DD-MON-YY''),'||p_batch_id||',';
          lc_summary_value_fid := lc_summary_value_fid||'''SUMMARY'''||','||'''FID'''||',' ||'TO_DATE('||''''||p_cycle_date||''''||',''DD-MON-YY''),'||p_batch_id||',';
        END IF;
        IF (LOWER(lc_get_summary_fields_info.tab_name)    = 'header') THEN
          IF (UPPER(lc_get_summary_fields_info.data_type) = 'DATE') THEN
            IF lc_get_summary_fields_info.summary_field   = 'Y' THEN
              lc_select_var_cols                         := lc_select_var_cols || 'SUM(hdr.' || lc_get_summary_fields_info.col_name ||'),';
            ELSE
              lc_select_var_cols    := lc_select_var_cols || 'TO_CHAR(hdr.' || lc_get_summary_fields_info.col_name || ',''YYYY-MM-DD''),';
              lc_summary_group_cols := lc_summary_group_cols || 'TO_CHAR(hdr.' || lc_get_summary_fields_info.col_name || ',''YYYY-MM-DD''),';
            END IF;
          ELSE
            IF lc_get_summary_fields_info.summary_field = 'Y' AND lc_get_summary_fields_info.field_id != 11142 THEN
              lc_select_var_cols                       := lc_select_var_cols||'SUM(hdr.'||lc_get_summary_fields_info.col_name||'),';
            --Added for 1.19
			ELSIF lc_get_summary_fields_info.summary_field = 'Y' AND lc_get_summary_fields_info.field_id = 11142 THEN
              lv_upd_str := 'update xx_ar_ebl_cons_hdr_main set TOTAL_MISCELLANEOUS_AMOUNT = TOTAL_MISCELLANEOUS_AMOUNT + (XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id )+ XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id)) WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND batch_id = '||p_batch_id;
              lv_upd_str1 := 'update xx_ar_ebl_cons_hdr_main set SKU_LINES_SUBTOTAL = SKU_LINES_SUBTOTAL - (XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id )+ XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id)) WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND batch_id = '||p_batch_id;
			  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,'In summary Fee ' );
			  IF lv_fee_option =1010 THEN
			     
			     lc_select_var_cols                       := lc_select_var_cols||'sum((
																	SELECT XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(TRX )+ XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(TRX)
																	FROM ((select REGEXP_SUBSTR (dt, ''[^,]+'', 1, level) as TRX
																	from (select listagg(customer_trx_id,'','') within group(order by cust_doc_id) dt from dual)
																	connect by level <= length(regexp_replace(dt,''[^,]*''))+1))))'||',';
			     lv_hide_flag := 'N';
				 execute immediate lv_upd_str1;
			   ELSE
                 lv_hide_flag := 'Y';
				 XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,'Fee hide lv_upd_str1'||lv_upd_str1||' lv_upd_str '||lv_upd_str );
--				 execute immediate lv_upd_str1;
--                 execute immediate lv_upd_str;
			     
			  END IF;
			  --End for 1.19
			ELSE
              lc_select_var_cols    := lc_select_var_cols||'hdr.'||lc_get_summary_fields_info.col_name||',';
              lc_summary_group_cols := lc_summary_group_cols ||'hdr.'|| lc_get_summary_fields_info.col_name || ',';
            END IF;
          END IF;
        ELSIF (LOWER(lc_get_summary_fields_info.tab_name) = 'lines') THEN
		 --Commented for Defect# 14525 by Thilak CG
         /* IF (UPPER(lc_get_summary_fields_info.data_type) = 'DATE') THEN
            IF lc_get_summary_fields_info.summary_field   = 'Y' THEN
              lc_select_var_cols                         := lc_select_var_cols || 'SUM(dtl.' || lc_get_summary_fields_info.col_name ||'),';
            ELSE
              lc_select_var_cols    := lc_select_var_cols || 'TO_CHAR(dtl.' || lc_get_summary_fields_info.col_name || ',''YYYY-MM-DD''),';
              lc_summary_group_cols := lc_summary_group_cols || 'TO_CHAR(dtl.' || lc_get_summary_fields_info.col_name || ',''YYYY-MM-DD''),';
            END IF;
           ELSE
            IF lc_get_summary_fields_info.summary_field = 'Y' THEN
              lc_select_var_cols                       := lc_select_var_cols||'SUM(dtl.' || lc_get_summary_fields_info.col_name ||'),';
            ELSE
              lc_select_var_cols    := lc_select_var_cols||'dtl.'||lc_get_summary_fields_info.col_name||',';
              lc_summary_group_cols := lc_summary_group_cols || 'dtl.'||lc_get_summary_fields_info.col_name || ',';
            END IF;
            END IF;*/
		    --Comment End

		    --Added for Defect# 14525 by Thilak CG
            IF lc_get_summary_fields_info.summary_field = 'Y' AND lc_get_summary_fields_info.col_name = 'ext_price' THEN
			  lc_select_var_cols                       := lc_select_var_cols||'SUM(hdr.SKU_LINES_SUBTOTAL),';
            END IF;
            --End

          --- Added by Punit on 21-JUN-2017
        ELSIF (LOWER(lc_get_summary_fields_info.tab_name) = 'constant') THEN
          lc_select_var_cols                             := lc_select_var_cols|| '''' || REPLACE(lc_get_summary_fields_info.cons_val,'''','''''') || '''' || ',';
          --- End of Added by Punit on 21-JUN-2017
        ELSIF (LOWER(lc_get_summary_fields_info.tab_name) = 'function') THEN
          IF lc_get_summary_fields_info.spl_function     IS NOT NULL THEN
          --  lc_function                                  := 'SELECT '||lc_get_summary_fields_info.spl_function||'('||p_cust_doc_id||','||p_file_id||','||p_org_id||','||''''||lc_get_summary_fields_info.col_name||''''||') FROM DUAL'; ----Comment by Aniket CG #22772 on 15 Dec 2017

            -- start Added by Aniket CG #22772 on 15 Dec 2017
           if  upper(lc_get_summary_fields_info.spl_function) IN ( 'XX_AR_EBL_TXT_SPL_LOGIC_PKG.GET_GRAND_TOTAL' , 'XX_AR_EBL_TXT_SPL_LOGIC_PKG.GET_GRAND_FREIGHT_AMT')
           and p_cmb_splt_splfunc_whr is not null then
           lc_function                                    := 'SELECT '||lc_get_summary_fields_info.spl_function||'('||p_cust_doc_id||','||p_file_id||','||p_org_id||','||''''||lc_get_summary_fields_info.col_name||''''||','|| p_cmb_splt_splfunc_whr || ') FROM DUAL';
           else
             lc_function                                  := 'SELECT '||lc_get_summary_fields_info.spl_function||'('||p_cust_doc_id||','||p_file_id||','||p_org_id||','||''''||lc_get_summary_fields_info.col_name||''''||') FROM DUAL';
           end if;
         -- end Added by Aniket CG #22772 on 15 Dec 2017


            EXECUTE IMMEDIATE lc_function INTO lc_function_return;
            lc_select_var_cols := lc_select_var_cols||lc_function_return||',';
		  ELSE
            lc_select_var_cols := lc_select_var_cols||'NULL'||',';
            -- Checking to print line number field is selected for the cust doc id.
            BEGIN
              SELECT xftv.target_value1,
                target_value2,
                target_value3
              INTO lc_target_value1,
                lc_target_value2,
                lc_target_value3
              FROM xx_fin_translatedefinition xftd ,
                xx_fin_translatevalues xftv
              WHERE xftd.translate_id   = xftv.translate_id
              AND xftd.translation_name = 'XX_AR_EBL_TXT_LINE_NUM'
              AND xftv.enabled_flag     = 'Y'
              AND TRUNC(sysdate) BETWEEN TRUNC(XFTV.START_DATE_ACTIVE) AND TRUNC(NVL(XFTV.END_DATE_ACTIVE,SYSDATE+1))
              AND xftv.source_value1 = lc_get_summary_fields_info.col_name;
              fnd_file.put_line(fnd_file.log,' Target Values '||lc_target_value1||' - '||lc_target_value2||' - '||lc_target_value3);
              IF lc_target_value1          = 'Y' OR lc_target_value2 = 'Y' OR lc_target_value3 = 'Y' THEN
                ln_print_summary_line_num := 'Y';
                lc_summary_col            := lc_summary_col || lc_column||ln_count || ','; -- Modified by Thilak CG on 25-JUL-2017 for Defect#42380
              END IF;
              lc_err_location_msg := ' Print Line Num '||ln_print_summary_line_num||' - Summary Col '||lc_summary_col;
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg);
            EXCEPTION
            WHEN OTHERS THEN
              lc_target_value1 := 'N';
              lc_target_value2 := 'N';
              lc_target_value3 := 'N';
            END;
            -- End
          END IF;
        END IF;
        -- Start of changes done by Thilak CG for Defect #40174 on 07-AUG-2017
        IF (UPPER(lc_get_summary_fields_info.dc_indicator) IS NOT NULL AND lc_dc_flag = 'N') THEN
          lc_dc_flag                                       := 'Y';
          lc_debit                                         := NULL;
          lc_credit                                        := NULL;
          BEGIN
            SELECT description,
              tag
            INTO lc_debit,
              lc_credit
            FROM fnd_lookup_values_vl FLV
            WHERE FLV.lookup_type  = 'XXOD_EBL_DEBIT_CREDIT_SIGN_IND'
            AND UPPER(flv.meaning) = UPPER(lc_get_summary_fields_info.dc_indicator)
            AND FLV.enabled_flag   = 'Y'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
          EXCEPTION
          WHEN OTHERS THEN
            lc_err_location_msg := 'Error during select mapping column from the lookup XXOD_EBL_DEBIT_CREDIT_SIGN_IND';
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
            p_dtl_error_flag := 'Y';
            p_dtl_error_msg  := lc_err_location_msg;
          END;
        END IF;
        IF (UPPER(lc_get_summary_fields_info.absolute_flag) = 'Y') THEN
          lc_abs_flag                                      := 'Y';
          ln_abs_cnt                                       := 0;
          BEGIN
            SELECT COUNT(flv.lookup_code)
            INTO ln_abs_cnt
            FROM fnd_lookup_values_vl FLV
            WHERE FLV.lookup_type      = 'XX_AR_EBL_TXT_DTL_ABS_COLS'
            AND UPPER(flv.lookup_code) = UPPER(lc_get_summary_fields_info.col_name)
            AND FLV.enabled_flag       = 'Y'
            AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
          EXCEPTION
          WHEN OTHERS THEN
            lc_err_location_msg := 'Error during select mapping column from the lookup XX_AR_EBL_TXT_DTL_ABS_COLS';
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
            p_dtl_error_flag := 'Y';
            p_dtl_error_msg  := lc_err_location_msg;
          END;
          IF ln_abs_cnt          = 1 THEN
            lc_get_abs_amt_cols := lc_get_abs_amt_cols || ' ' || lc_column || ln_count || ' = ' ||'ABS('||lc_column || ln_count||')'||',';
            ln_abs_update_cnt   := 1;
          END IF;
        END IF;
        -- End of Changes done by Thilak CG for Defect #40174 on 07-AUG-2017
        -- Start of changes done by Thilak CG for Defect #40174 on 07-AUG-2017
   	    IF UPPER(lc_get_summary_fields_info.col_name) = 'ORIGINAL_INVOICE_AMOUNT' THEN
		   lc_dc_amt_col  := lc_column||ln_count;
		ELSIF UPPER(lc_get_summary_fields_info.col_name) = 'EXT_PRICE' THEN
		   lc_dc_amt_col  := lc_column||ln_count;
		END IF;

   	    IF UPPER(lc_get_summary_fields_info.col_name) = 'DC_INDICATOR' THEN
		   lc_dc_indicator_col := lc_column||ln_count;
	    END IF;
        -- End
        -- Start of changes done by Punit CG for Defect #40174 on 11-AUG-2017
        BEGIN
          SELECT COUNT(flv.lookup_code)
          INTO ln_sign_cnt
          FROM fnd_lookup_values_vl FLV
          WHERE FLV.lookup_type      = 'XX_AR_EBL_TXT_DTL_SIGN_COLS'
          AND UPPER(flv.lookup_code) = UPPER(lc_get_summary_fields_info.col_name)
          AND FLV.enabled_flag       = 'Y'
          AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
          IF (ln_sign_cnt     = 1 AND lc_sign_flag = 'N' AND lc_amt_sign_flag = 'N') THEN
            lc_amt_sign_flag := 'Y';
            -- lc_amt_col_for_sign := lc_column||ln_count;
            --lc_sign_col_decode := 'DECODE(SIGN(' || lc_amt_col_for_sign || '),''1'',''+'',''-1'',''-'','''')';
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          lc_err_location_msg := 'Error while selecting the mapping SIGN column from the lookup XX_AR_EBL_TXT_DTL_SIGN_COLS';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
          p_dtl_error_flag := 'Y';
          p_dtl_error_msg  := lc_err_location_msg;
        END;
        IF (UPPER(lc_get_summary_fields_info.col_name) = 'SIGN') THEN
          lc_get_sign_amt_cols                        := lc_get_sign_amt_cols || ' ' || lc_column || ln_count || ',';
          ln_sign_update_cnt                          := 1;
        END IF;
        IF (lc_sign_flag = 'N' AND lc_amt_sign_flag = 'N' AND UPPER(lc_get_summary_fields_info.col_name) = 'SIGN') THEN
          lc_sign_flag  := 'Y';
        END IF;
		    -- Added by Thilak CG on 12-OCT-2017 for Wave2 UAT Defect#13836
            IF lc_get_summary_fields_info.sort_order IS NOT NULL AND lc_get_summary_fields_info.sort_type IS NOT NULL AND lc_get_summary_fields_info.record_type = 'LINE'
            THEN
		      lc_summary_sort_columns :=
			     lc_summary_sort_columns
				 || 'COLUMN'
			     || ln_count
			     || ' '
			     || lc_get_summary_fields_info.sort_type
			     || ',';
            END IF;
		    -- End
        -- End of changes done by Punit CG for Defect #40174 on 11-AUG-2017
        
		IF lv_hide_flag = 'N' THEN
		    lc_summary_insert_col_name := lc_summary_insert_col_name||lc_column||ln_count||',';
		    lc_summary_value_fid       := lc_summary_value_fid||lc_get_summary_fields_info.field_id||',';
		    ln_count                   := ln_count + 1;
		ELSE
           lc_select_var_cols := replace(lc_select_var_cols,lc_function_return||',','');
--           lv_upd_str := 'update xx_ar_ebl_cons_hdr_main set TOTAL_MISCELLANEOUS_AMOUNT = TOTAL_MISCELLANEOUS_AMOUNT - '||lc_tot_fee_amt||' WHERE parent_cust_doc_id = '||p_cust_doc_id||' AND batch_id = '||p_batch_id;
--           execute immediate lv_upd_str;
		END IF;
      END LOOP;
		IF lv_fee_option !=1010 THEN
			lv_upd_str := 'update xx_ar_ebl_cons_hdr_main set TOTAL_MISCELLANEOUS_AMOUNT = TOTAL_MISCELLANEOUS_AMOUNT + (XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id )+ XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id)) WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND batch_id = '||p_batch_id;
			lv_upd_str1 := 'update xx_ar_ebl_cons_hdr_main set SKU_LINES_SUBTOTAL = SKU_LINES_SUBTOTAL - (XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id )+ XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id)) WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND batch_id = '||p_batch_id;
			execute immediate lv_upd_str;
			execute immediate lv_upd_str1;
		END IF;
      lc_summary_insert_col_name := lc_insert_summary_const_cols||SUBSTR(lc_summary_insert_col_name,1,LENGTH(lc_summary_insert_col_name)                                                                                                                     -1)||')';
      lc_select_var_cols         := '(SELECT '||ln_stg_id||', '||lc_summary_select_cons||SUBSTR(lc_select_var_cols,1,LENGTH(lc_select_var_cols)                                                                                                              -1)||lc_summary_from_cons || p_cmb_splt_whr ; ----Added by Aniket CG #22772 on 15 Dec 2017
      lc_summary_value_fid       := ' VALUES ('||xx_ar_ebl_txt_stg_id_s.nextval||','||p_cust_doc_id||','||p_file_id||',fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,'||SUBSTR(lc_summary_value_fid,1,LENGTH(lc_summary_value_fid)-1)||')';
      lc_summary_group_cols      := lc_summary_group_by||ln_stg_id||','||lc_summary_select_cons||SUBSTR(lc_summary_group_cols,1,LENGTH(lc_summary_group_cols)                                                                                                -1);
      lc_err_location_msg        := lc_summary_insert_col_name||lc_summary_value_fid;
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
      lc_err_location_msg := lc_summary_insert_col_name||lc_select_var_cols||' '||lc_summary_group_cols||')';
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
      EXECUTE IMMEDIATE lc_summary_insert_col_name||lc_summary_value_fid;
      EXECUTE IMMEDIATE lc_summary_insert_col_name||lc_select_var_cols||' '||lc_summary_group_cols||')';
      -- Start of changes done by Thilak CG for Defect #40174 and 14188 on 07-AUG-2017
      lc_err_location_msg := 'Value of lc_dc_flag: '||lc_dc_flag||' and Value of lc_dc_amt_col: '||lc_dc_amt_col;
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
      IF lc_dc_flag = 'Y' AND lc_dc_amt_col IS NOT NULL AND lc_dc_indicator_col IS NOT NULL THEN
        lc_dc_amt_decode    := 'DECODE(SIGN('||lc_dc_amt_col||'),''1'','||''''||lc_debit||''''||','||'''0'','||''''||lc_debit||''''||','||''''||lc_credit||''''||')';
        lc_dc_update_sql    := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET '||lc_dc_indicator_col||' = '||lc_dc_amt_decode||' WHERE rec_type != ''FID'' AND file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id;
        lc_err_location_msg := 'Updated Header DC Indicator Column: '||lc_dc_update_sql;
        XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
        EXECUTE IMMEDIATE lc_dc_update_sql;
      END IF;
      -- End
      IF ln_print_summary_line_num = 'Y' THEN
        -- Framing the SQL to update the line number in the Detail staging table
        --LC_SUMMARY_SORT_COLUMNS := XX_AR_EBL_RENDER_TXT_PKG.GET_SORT_COLUMNS(P_CUST_DOC_ID,'LINE');
        lc_summary_stg_query    := 'SELECT ROWID, CUSTOMER_TRX_ID FROM XX_AR_EBL_TXT_DTL_STG WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_TYPE != '||'''FID'''||' AND TRX_TYPE = '||'''SUMMARY'''||' ORDER BY '||lc_summary_sort_columns||' CUSTOMER_TRX_ID, trx_line_number';
        lc_err_location_msg     := 'Staging table Query for Summary '||lc_summary_stg_query;
        XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
        -- Getting sequence number from header summary.
        ln_summary_line_num := 0;
        -- Added by Thilak CG on 25-JUL-2017 for Defect#42380
        lc_summary_cols     := SUBSTR(lc_summary_col,1,(LENGTH(lc_summary_col)-1));
        lc_stg_update_query := 'select a.str from (WITH DATA AS
								( SELECT ' ||''''||lc_summary_cols||''''|| ' str FROM dual
								)
								SELECT trim(regexp_substr(str, ''[^,]+'', 1, LEVEL)) str
								FROM DATA
								CONNECT BY instr(str, '','', 1, LEVEL - 1) > 0) a';
        -- End
        -- Changes for the defect#42322
        /*SELECT NVL(MAX(ROWNUMBER),ln_summary_line_num)
        INTO ln_summary_line_num
        FROM XX_CDH_EBL_TEMPL_HDR_TXT
        WHERE CUST_DOC_ID = p_cust_doc_id;*/

		  ln_hdr_sum_num_max := 0;
          -- Changes for the defect#42322
          SELECT NVL(MAX(ROWNUMBER),ln_summary_line_num)
          INTO ln_hdr_sum_num_max
          FROM XX_CDH_EBL_TEMPL_HDR_TXT
          WHERE CUST_DOC_ID = p_cust_doc_id;

        SELECT COUNT (DISTINCT xftv.source_value4)
        INTO ln_summary_line_num
        FROM xx_fin_translatedefinition xftd ,
          xx_fin_translatevalues XFTV ,
          xx_cdh_ebl_templ_hdr_txt xcetht
        WHERE xftd.translate_id   = xftv.translate_id
        AND xftd.translation_name = 'XX_CDH_EBL_TXT_HDR_FIELDS'
        AND XFTV.ENABLED_FLAG     = 'Y'
        AND TRUNC(sysdate) BETWEEN TRUNC(XFTV.START_DATE_ACTIVE) AND TRUNC(NVL(XFTV.END_DATE_ACTIVE,sysdate+1))
        AND XFTV.SOURCE_VALUE1 = XCETHT.FIELD_ID
        AND XCETHT.ATTRIBUTE20 = 'Y'
        AND XCETHT.CUST_DOC_ID = p_cust_doc_id
        AND xftv.source_value4     IN
          (SELECT xftv.source_value1
          FROM xx_fin_translatedefinition xftd ,
            xx_fin_translatevalues XFTV
          WHERE xftd.translate_id   = xftv.translate_id
          AND xftd.translation_name = 'XX_AR_EBL_TXT_LINE_NUM'
          AND XFTV.ENABLED_FLAG     = 'Y'
          AND TRUNC(sysdate) BETWEEN TRUNC(XFTV.START_DATE_ACTIVE) AND TRUNC(NVL(XFTV.END_DATE_ACTIVE,sysdate+1))
          );

          IF ln_hdr_sum_num_max > 1 AND ln_summary_line_num = 1
          THEN
		   ln_summary_line_num := ln_hdr_sum_num_max;
          END IF;

        -- Open the Cursors and update the sequence number
        IF lc_summary_cols IS NOT NULL THEN
          OPEN c_summary_stg_cursor FOR lc_summary_stg_query; -- hdr cursor.
          LOOP
            FETCH c_summary_stg_cursor INTO ln_summary_row_id, ln_summary_customer_trx_id;
            EXIT
          WHEN c_summary_stg_cursor%NOTFOUND;
            ln_summary_line_num := NVL(ln_summary_line_num,0) + 1;
            -- Added by Thilak CG on 25-JUL-2017 for Defect#42380
            OPEN c_stg_row_cursor FOR lc_stg_update_query;
            LOOP
              FETCH c_stg_row_cursor INTO lc_row_seq_col;
              EXIT
            WHEN c_stg_row_cursor%NOTFOUND;
              lc_update_summary_sql := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET '||lc_row_seq_col||' = '||ln_summary_line_num||' WHERE ROWID = '||''''||ln_summary_row_id||'''';
              lc_err_location_msg   := 'Updated Line Row Numbering Column: '||lc_update_summary_sql;
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
              EXECUTE IMMEDIATE lc_update_summary_sql;
            END LOOP;
            -- End
          END LOOP;
        END IF;
      END IF;
      -- Added by Punit CG for defect#40174 on 11-AUG-2017
      lc_dtl_sign_cols     := SUBSTR(lc_get_sign_amt_cols,1,LENGTH(lc_get_sign_amt_cols)-1);
      lc_sign_update_query := 'select a.str from (WITH DATA AS
								( SELECT ' ||''''||lc_dtl_sign_cols||''''|| ' str FROM dual
								)
								SELECT trim(regexp_substr(str, ''[^,]+'', 1, LEVEL)) str
								FROM DATA
								CONNECT BY instr(str, '','', 1, LEVEL - 1) > 0) a';
      lc_err_location_msg  := 'Value of lc_sign_update_query is '||lc_sign_update_query;
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
      -- Framing the SQL to update the Sign columns in detail staging table
      lc_dtl_upd_sign_query:= 'SELECT DISTINCT FILE_ID,CUST_DOC_ID,REC_ORDER
								FROM XX_AR_EBL_TXT_DTL_STG
								WHERE file_id = '||p_file_id ||' AND cust_doc_id = '||p_cust_doc_id ||' AND REC_TYPE != '||'''FID''';
      -- Open the Cursors and update the Sign columns
      lc_err_location_msg := 'Value of lc_abs_flag is '||lc_abs_flag||' and Value of ln_sign_update_cnt is '||ln_sign_update_cnt;
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
      IF ((lc_abs_flag = 'Y') AND (ln_sign_update_cnt = 1)) THEN
        OPEN c_dtl_upd_sign_cursor FOR lc_dtl_upd_sign_query;
        LOOP
          FETCH c_dtl_upd_sign_cursor
          INTO ln_dtl_sign_file_id,
            ln_dtl_sign_cust_doc_id,
            ln_dtl_sign_rec_order;
          EXIT
        WHEN c_dtl_upd_sign_cursor%NOTFOUND;
          OPEN c_sign_row_cursor FOR lc_sign_update_query;
          LOOP
            FETCH c_sign_row_cursor INTO lc_row_sign_col;
            EXIT
          WHEN c_sign_row_cursor%NOTFOUND;
            ln_sign_col_str    := NULL;
            lc_sign_col_decode := NULL;
            BEGIN
              IF lc_amt_sign_flag = 'Y' THEN
                SELECT TO_NUMBER(SUBSTR(lc_row_sign_col,INSTR(lc_row_sign_col,'n')+1))-1
                INTO ln_sign_col_str
                FROM DUAL;
              ELSIF lc_sign_flag = 'Y' THEN
                SELECT TO_NUMBER(SUBSTR(lc_row_sign_col,INSTR(lc_row_sign_col,'n')+1))+1
                INTO ln_sign_col_str
                FROM DUAL;
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              lc_err_location_msg := 'Error While Selecting the Sign Columns Number : ' || SQLCODE || ' - ' || SQLERRM;
              XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || ln_sign_col_str);
              p_dtl_error_flag := 'Y';
              p_dtl_error_msg  := lc_err_location_msg;
            END;
            BEGIN
              IF ln_sign_col_str     IS NOT NULL THEN
                ln_sign_col_cnt      := 0;
                lc_sign_amt_field_id := NULL;
                EXECUTE IMMEDIATE 'SELECT '||lc_column||ln_sign_col_str|| ' FROM  XX_AR_EBL_TXT_DTL_STG' ||' WHERE file_id = '||p_file_id ||' AND cust_doc_id = '||p_cust_doc_id ||' AND REC_TYPE = '||'''FID''' INTO lc_sign_amt_field_id;
                lc_err_location_msg := 'Selected Field iD value '||lc_sign_amt_field_id;
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
                SELECT COUNT(flv.lookup_code)
                INTO ln_sign_col_cnt
                FROM fnd_lookup_values_vl FLV
                WHERE FLV.lookup_type      = 'XX_AR_EBL_TXT_DTL_SIGN_COLS'
                AND UPPER(flv.lookup_code) = UPPER(
                  (SELECT DISTINCT xftv.source_value4
                  FROM Xx_Fin_Translatedefinition Xftd ,
                    Xx_Fin_Translatevalues Xftv
                  WHERE xftd.translate_id   = xftv.translate_id
                  AND Xftv.Source_Value1    = lc_sign_amt_field_id
                  AND xftd.translation_name ='XX_CDH_EBL_TXT_DET_FIELDS'
                  AND Xftv.Enabled_Flag     ='Y'
                  AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
                  ))
                AND FLV.enabled_flag = 'Y'
                AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              lc_err_location_msg := 'Error while selecting the mapping SIGN column from the lookup XX_AR_EBL_TXT_DTL_SIGN_COLS for Summary Bill';
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
              p_dtl_error_flag := 'Y';
              p_dtl_error_msg  := lc_err_location_msg;
            END;
            BEGIN
              IF ln_sign_col_cnt = 1 THEN
                --    ln_sign_col_str    :=  'SUBSTR('||lc_row_sign_col||',INSTR('||lc_row_sign_col||',''N'')+1)'||ln_amtsign_val;
                lc_sign_col_decode      := 'DECODE(SIGN('||lc_column||ln_sign_col_str||'),''1'',''+'',''-1'',''-'','''')';
                lc_update_sign_amt_cols := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET ' ||lc_row_sign_col ||' = '||lc_sign_col_decode ||' WHERE file_id = '||p_file_id ||' AND cust_doc_id = '||p_cust_doc_id ||' AND REC_TYPE != '||'''FID''';
                EXECUTE IMMEDIATE lc_update_sign_amt_cols;
                lc_err_location_msg := 'Executed Sign Column updates in XX_AR_EBL_TXT_DTL_STG table';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg|| '-' ||lc_update_sign_amt_cols );
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              lc_err_location_msg := 'Error While Updating the Sign Columns of Detail Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
              XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_sign_amt_cols);
              p_dtl_error_flag := 'Y';
              p_dtl_error_msg  := lc_err_location_msg;
            END;
          END LOOP;
        END LOOP;
      END IF;
      -- End of Added by Punit CG for defect#40174 on 11-AUG-2017
      -- Added by Thilak CG for defect#40174 on 08-AUG-2017
      lc_err_location_msg := 'Summary Detail Value of lc_abs_flag is '||lc_abs_flag||' and Value of ln_abs_update_cnt is '||ln_abs_update_cnt;
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
      IF ((lc_abs_flag          = 'Y') AND (ln_abs_update_cnt = 1)) THEN
        lc_update_abs_amt_cols := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET' || SUBSTR(lc_get_abs_amt_cols,1,LENGTH(lc_get_abs_amt_cols)-1) || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' || p_cust_doc_id || ' AND file_id = ' || p_file_id;
        BEGIN
          EXECUTE IMMEDIATE lc_update_abs_amt_cols;
          lc_err_location_msg := 'Executed Absolute Amount update in XX_AR_EBL_TXT_DTL_STG table for Summary Detail';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg|| ' - ' ||lc_update_abs_amt_cols );
        EXCEPTION
        WHEN OTHERS THEN
          lc_err_location_msg := 'Error While Updating the Absolute Amount Columns of Summary Detail Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
          XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_abs_amt_cols);
          p_dtl_error_flag := 'Y';
          p_dtl_error_msg  := lc_err_location_msg;
        END;
      END IF;
      -- End
    ELSE -- Not Summary Bill
      -- Start of Changes done For Requirement#2302 by Punit CG on 17-MAR-2017
      BEGIN
        SELECT NONDT_QUANTITY
        INTO ln_nondt_qty
        FROM XX_CDH_EBL_MAIN
        WHERE cust_doc_id = p_cust_doc_id;
      EXCEPTION
      WHEN OTHERS THEN
        ln_nondt_qty := NULL;
      END;
      -- End of Changes done For Requirement#2302 by Punit CG on 17-MAR-2017
      -- Added and Commented by Punit on 12-JUL-2017 for Defect # 41307
      ln_get_line_dist_rows := NULL;
      OPEN get_dist_rows;
      LOOP
        FETCH get_dist_rows INTO ln_get_line_dist_rows;
        EXIT
      WHEN get_dist_rows%NOTFOUND;
        lc_get_dist_record_type := NULL;
        lc_hdr_line_num_col     := NULL;
        lc_line_line_num_col    := NULL;
        lc_dist_line_num_col    := NULL;
        lc_hdr_sort_columns     := NULL;
        lc_line_sort_columns    := NULL;
        lc_dist_line_sort_columns := NULL;
        OPEN get_dist_record_type(ln_get_line_dist_rows);
        LOOP
          FETCH get_dist_record_type INTO lc_get_dist_record_type;
          EXIT
        WHEN get_dist_record_type%NOTFOUND;
          -- End of Added and Commented by Punit on 12-JUL-2017 for Defect # 41307
          ln_count           := 1;
          lc_dtl_value_fid   := NULL;
          lc_insert_col_name := NULL;
          lc_select_var_cols := NULL;
          --- Added on 31-JUL-2017
          lc_insert_col_name_ndt := NULL;
          lc_insert_select_ndt   := NULL;
          lc_select_ndt          := NULL;
          lc_select_non_dt       := NULL;
          ln_repeat_cnt          := 0;
          ln_update_cnt          := 0;
          ln_abs_cnt             := 0;
          ln_abs_update_cnt      := 0;
          lc_get_abs_amt_cols    := NULL;
          lc_dc_flag             := 'N';
          lc_debit               := NULL;
          lc_credit              := NULL;
          lc_dc_amt_col          := NULL;
		   -- START Added by Aniket CG 15 May #NAIT-29364
          lc_dc_amt_col_db       := NULL;
          lc_dc_amt_col_cr       := NULL;
          lc_dc_amt_decode_db    := NULL;
          lc_dc_amt_decode_cr    := NULL;
          lc_dc_update_sql_db    := NULL;
          lc_dc_update_sql_cr    := NULL;
          -- END Added by Aniket CG 15 May #NAIT-29364
          lc_dc_amt_decode       := NULL;
          lc_dc_indicator_col    := NULL;
          lc_dc_update_sql       := NULL;
          lc_unitprice_col       := NULL;
          lc_ext_col             := NULL;
          lc_ext_price           := NULL;
          lc_unit_price          := NULL;
          lc_tax_col             := NULL;
          lc_freight_col         := NULL;
          lc_misc_col            := NULL;
          lc_tax_up_flag         := NULL;
          lc_freight_up_flag     := NULL;
          lc_misc_up_flag        := NULL;
          lc_tax_ep_flag         := NULL;
          lc_freight_ep_flag     := NULL;
          lc_misc_ep_flag        := NULL;
          lc_tax_amt             := NULL;
          lc_freight_amt         := NULL;
          lc_misc_amt            := NULL;
          --ln_nondt_qty           := NULL;
          ln_nondt_qty_update   := NULL;
          lc_get_total_amt_cols := NULL;
          lc_rec_type           := NULL; -- Added on 12-JUN-2017
          lc_qty_ship_exists     := 'N';  -- Added on 21-JUN-2017
          -- End of Added on 31-JUL-2017
          -- Below variables initialized by Punit CG on 11-AUG-2017 for Defect#40174
          ln_sign_update_cnt   := 0;
          ln_sign_cnt          := 0;
          lc_get_sign_amt_cols := NULL;
          --ln_sign_update_cnt   := 0;
          ln_sign_ind_flag      := 'N';
          lc_amt_col_for_sign   := NULL;
          lc_sign_col_decode    := NULL;
          lc_dtl_sign_cols      := NULL;
          lc_sign_update_query  := NULL;
          lc_dtl_upd_sign_query := NULL;
          -- End of Below variables initialized by Punit CG on 11-AUG-2017 for Defect#40174
          lc_seq_num_exists      := 'N';
          lc_dist_seq_num_exists := 'N';
          lc_err_location_msg    := 'Processing the Detail Record type...'||lc_get_dist_record_type||' Cust Doc Id :' || p_cust_doc_id || ' File id ' || p_file_id || ' Extract Batch id ' || p_batch_id ;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
          FOR lc_get_dtl_fields_info IN c_get_dtl_fields_info(lc_get_dist_record_type,ln_get_line_dist_rows)
          LOOP
            lv_hide_flag := 'N';
			XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
            lc_err_location_msg := 'CURRENT ROW NUMBER IS => '||ln_get_line_dist_rows||' AND CURRENT RECORD TYPE IS => '||lc_get_dist_record_type;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
            lc_err_location_msg := '************************************************************************************';
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
            lc_err_location_msg := 'Tab Name:'||lc_get_dtl_fields_info.tab_name||', Column Name:'||lc_get_dtl_fields_info.col_name;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
            IF ln_count = 1 THEN
              -- Added rec_order column by Punit for Defect# 41307
              lc_select_var_cols := ''''||lc_get_dist_record_type||''''||','||''''||lc_get_dtl_fields_info.rec_type||''''||','||lc_get_dtl_fields_info.rec_order||','||'TO_DATE('||''''||p_cycle_date||''''||',''DD-MON-YY''),'||p_batch_id||',';
              lc_dtl_value_fid   := lc_dtl_value_fid||''''||lc_get_dist_record_type||''''||','||'''FID'''||','||lc_get_dtl_fields_info.rec_order||','||'TO_DATE('||''''||p_cycle_date||''''||',''DD-MON-YY''),'||p_batch_id||',';
              -- End of Added rec_order column by Punit for Defect# 41307
              --lc_insert_col_name := lc_insert_const_cols;
            END IF;
            IF (LOWER(lc_get_dtl_fields_info.tab_name) = 'header') THEN
              --- Added by Punit for Req# 2302 and Defect# 41733 in SIT03 on 15-APR-2017
              IF (UPPER(lc_get_dtl_fields_info.record_type) = 'LINE') AND lc_get_dtl_fields_info.field_id != 11142 THEN
			  --- Code added by Punit on 10-OCT-2017 for the Production Defect# 42877
			    IF (UPPER(lc_get_dtl_fields_info.data_type) = 'DATE') THEN
                  lc_select_non_dt := lc_select_non_dt || 'TO_CHAR(hdr.' || lc_get_dtl_fields_info.col_name || ',''YYYY-MM-DD''),';
                ELSE
				  lc_select_non_dt := lc_select_non_dt || 'hdr.' || lc_get_dtl_fields_info.col_name || ',';
                END IF;
		      --- End of Code added by Punit on 10-OCT-2017 for the Production Defect# 42877
                lc_insert_col_name_ndt                     := lc_insert_col_name_ndt || lc_column || ln_count || ','; -- Added by Punit on 15-APR-2017
                --lc_select_non_dt                           := lc_select_non_dt || 'hdr.' || lc_get_dtl_fields_info.col_name || ',';
                --- End of Added by Punit for Req# 2302 and Defect# 41733 in SIT03 on 15-APR-2017
              END IF;
              IF (UPPER(lc_get_dtl_fields_info.data_type) = 'DATE') THEN
                lc_select_var_cols                       := lc_select_var_cols || 'TO_CHAR(hdr.' || lc_get_dtl_fields_info.col_name || ',''YYYY-MM-DD''),';
               --Added for 1.19
			  ELSIF lc_get_dtl_fields_info.field_id = 11142 THEN
				  lv_upd_str := 'update xx_ar_ebl_cons_hdr_main set TOTAL_MISCELLANEOUS_AMOUNT = TOTAL_MISCELLANEOUS_AMOUNT + (XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id )+ XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id)) WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND batch_id = '||p_batch_id;
				  lv_upd_str1 := 'update xx_ar_ebl_cons_hdr_main set SKU_LINES_SUBTOTAL = SKU_LINES_SUBTOTAL - (XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id )+ XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id)) WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND batch_id = '||p_batch_id;
				  IF lv_fee_option =1010 THEN
					 
					 lc_select_var_cols := lc_select_var_cols||'(XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(hdr.customer_trx_id )+ XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(hdr.customer_trx_id))'||',';
					 lv_hide_flag := 'N';
                       execute immediate lv_upd_str1;
				   ELSE
					 lv_hide_flag := 'Y';
					 --execute immediate lv_upd_str1;
					 --execute immediate lv_upd_str;
					 
			  END IF;
			  --End for 1.19
			  ELSE
                lc_select_var_cols := lc_select_var_cols||'hdr.'||lc_get_dtl_fields_info.col_name||',';
              END IF;
            ELSIF (LOWER(lc_get_dtl_fields_info.tab_name) = 'lines') THEN
              IF (UPPER(lc_get_dtl_fields_info.data_type) = 'DATE') THEN
                lc_select_var_cols                       := lc_select_var_cols || 'TO_CHAR(dtl.' || lc_get_dtl_fields_info.col_name || ',''YYYY-MM-DD''),';
              ELSE
                lc_select_var_cols := lc_select_var_cols||'dtl.'||lc_get_dtl_fields_info.col_name||',';
              END IF;
              -- Added by Punit CG on 24-MAY-2017 for Defect raised in UAT Cycle1
            ELSIF ((lc_get_dtl_fields_info.tab_name        IS NULL) AND (lc_get_dtl_fields_info.rec_type NOT IN ('TX','DL','MS'))) THEN
              IF (UPPER(lc_get_dtl_fields_info.record_type) = 'LINE') THEN
                lc_select_var_cols                         := lc_select_var_cols||'hdr.'||lc_get_dtl_fields_info.col_name||',';
              END IF;
              -- End of Added by Punit CG on 24-MAY-2017
            ELSIF (LOWER(lc_get_dtl_fields_info.tab_name) = 'concatenate') THEN
              lc_select_var_cols                         := lc_select_var_cols||lc_get_dtl_fields_info.col_name||',';
              --- Added by Punit for Req# 2303 and Defect# 41733 in SIT03 on 15-APR-2017
              IF (UPPER(lc_get_dtl_fields_info.record_type) = 'LINE') THEN
			  --- Code added by Punit on 10-OCT-2017 for the Production Defect# 42877
			    IF (UPPER(lc_get_dtl_fields_info.data_type) = 'DATE') THEN
                  --lc_select_non_dt := lc_select_non_dt || 'TO_CHAR(hdr.' || lc_get_dtl_fields_info.col_name || ',''YYYY-MM-DD''),';
				  lc_select_non_dt := lc_select_non_dt || 'TO_CHAR(' || lc_get_dtl_fields_info.col_name || ',''YYYY-MM-DD''),';
                ELSE
                  --lc_select_non_dt := lc_select_non_dt || 'hdr.' || lc_get_dtl_fields_info.col_name || ',';
				  --Added for Defect# NAIT-17796 by Thilak CG on 09-JUN-2018
                     lc_nondt_concat_cols := NULL;
                     SELECT REPLACE(REPLACE(REPLACE(REPLACE(
					        REPLACE(lc_get_dtl_fields_info.col_name,'dtl.item_description',lc_decode_sku)
					        ,'dtl.inventory_item_number',lc_decode_product)
							,'dtl.entered_product_code',lc_decode_product)
							,'dtl.customer_product_code',lc_decode_product)
							,'dtl.vendor_product_code',lc_decode_product)
					   INTO lc_nondt_concat_cols
					   FROM dual;
                     lc_select_non_dt   := lc_select_non_dt || lc_nondt_concat_cols || ',';

                  /*Commented for Defect# NAIT-17796 by Thilak CG on 09-JUN-2018*/
				  -- lc_select_non_dt   := lc_select_non_dt || lc_get_dtl_fields_info.col_name || ',';
				  -- End of Defect# NAIT-17796				  lc_select_non_dt   := lc_select_non_dt || lc_get_dtl_fields_info.col_name || ',';
                END IF;
		      --- End of Code added by Punit on 10-OCT-2017 for the Production Defect# 42877
                lc_insert_col_name_ndt                     := lc_insert_col_name_ndt || lc_column || ln_count || ','; -- Added by Punit on 15-APR-2017
              --  lc_select_non_dt                           := lc_select_non_dt || lc_get_dtl_fields_info.col_name || ',';
              END IF;
              --- End of Added by Punit for Req# 2303 and Defect# 41733 in SIT03 on 15-APR-2017
            ELSIF (LOWER(lc_get_dtl_fields_info.tab_name) = 'split') THEN
              ln_current_cust_doc_id                     := lc_get_dtl_fields_info.cust_doc_id;
              ln_current_base_field_id                   := lc_get_dtl_fields_info.base_field_id;
              ln_current_file_id                         := p_file_id;
              --- Added by Punit for Req# 2303 and Defect# 41733 in SIT03 on 15-APR-2017
              IF (UPPER(lc_get_dtl_fields_info.record_type) = 'LINE') THEN
                --- Code added by Punit on 10-OCT-2017 for the Production Defect# 42877
			    IF (UPPER(lc_get_dtl_fields_info.data_type) = 'DATE') THEN
                  lc_select_non_dt := lc_select_non_dt || 'TO_CHAR(hdr.' || lc_get_dtl_fields_info.col_name || ',''YYYY-MM-DD''),';
                ELSE
                  lc_select_non_dt := lc_select_non_dt || 'hdr.' || lc_get_dtl_fields_info.col_name || ',';
                END IF;
		      --- End of Code added by Punit on 10-OCT-2017 for the Production Defect# 42877
                lc_insert_col_name_ndt                     := lc_insert_col_name_ndt || lc_column || ln_count || ','; -- Added by Punit on 15-APR-2017
                --lc_select_non_dt                           := lc_select_non_dt || 'hdr.' || lc_get_dtl_fields_info.col_name || ',';
              END IF;
              --- End of Added by Punit for Req# 2303 and Defect# 41733 in SIT03 on 15-APR-2017
              IF ln_current_cust_doc_id <> ln_previous_cust_doc_id OR ln_current_base_field_id <> ln_previous_base_field_id OR ln_previous_file_id <> ln_current_file_id THEN
                ln_count1               := 0; --resetting to zero for new base field id or new cust doc id or new file id.
              END IF;

			  --Added for Defect# 42790 and NAIT-21270 by Thilak CG
			  lc_spilt_label := NULL;
			  ln_count1 := 0;
			  lc_spilt_label := lc_get_dtl_fields_info.label;

			  BEGIN
			   SELECT CASE WHEN split_field1_label = lc_spilt_label THEN 1
			  	  		   WHEN split_field2_label = lc_spilt_label THEN 2
						   WHEN split_field3_label = lc_spilt_label THEN 3
						   WHEN split_field4_label = lc_spilt_label THEN 4
						   WHEN split_field5_label = lc_spilt_label THEN 5
						   WHEN split_field6_label = lc_spilt_label THEN 6
						   ELSE 0 END
			     INTO ln_count1
				 FROM XX_CDH_EBL_SPLIT_FIELDS_TXT
			   WHERE cust_doc_id = lc_get_dtl_fields_info.cust_doc_id
			     AND split_base_field_id = lc_get_dtl_fields_info.base_field_id;
			   EXCEPTION
			   WHEN OTHERS THEN
			    ln_count1 := 0;
			   END;
			   -- End

              --  ln_count1 := ln_count1 + 1;  --Commented for Defect# 42790 and NAIT-21270 by Thilak CG
			  -- Call the function to get the split column
              lc_err_location_msg := 'Getting Split Fields for the Cust Doc Id: '||lc_get_dtl_fields_info.cust_doc_id||' Base Field Id: '||lc_get_dtl_fields_info.base_field_id||' Count: '||ln_count1;
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
              lc_get_dtl_fields_info.col_name := GET_SPLIT_FIELD_NAMES(lc_get_dtl_fields_info.cust_doc_id, lc_get_dtl_fields_info.base_field_id, ln_count1, 'DTL', lc_get_dist_record_type, p_debug_flag);
              ln_previous_cust_doc_id         := lc_get_dtl_fields_info.cust_doc_id;
              ln_previous_base_field_id       := lc_get_dtl_fields_info.base_field_id;
              ln_previous_file_id             := p_file_id;
              lc_select_var_cols              := lc_select_var_cols || lc_get_dtl_fields_info.col_name || ',';
              --Added by Aniket CG UAT Defect#50280
			  lc_select_non_dt        := lc_select_non_dt || lc_get_dtl_fields_info.col_name ||',';
			  lc_insert_col_name_ndt  := lc_insert_col_name_ndt || lc_column || ln_count || ',';
			  --Ended by Aniket CG UAT Defect#50280
              --Added by Punit CG for Defect #39140 on 05-JUL-2017
			  -- Framing the query to concatenate the value from translation for the field  'Electronic Record Type'
            ELSIF (LOWER(lc_get_dtl_fields_info.tab_name) = 'translation') THEN
              lc_err_location_msg                        := 'Framing SQL for fetching value from translation for Electronic Record Type Field';
              lc_select_var_cols                         := lc_select_var_cols || '''' || lc_get_dtl_fields_info.rec_type || ''''|| ',';
              lc_select_non_dt                           := lc_select_non_dt || 'xftv.' || lc_get_dtl_fields_info.col_name || ',';
              -- lc_insert_col_name     := lc_insert_col_name || lc_column || ln_count || ',';
              lc_insert_col_name_ndt := lc_insert_col_name_ndt || lc_column || ln_count || ',';
              -- End  of  Addition by Punit CG for Defect #39140 on 05-JUL-2017
            ELSIF (LOWER(lc_get_dtl_fields_info.tab_name) = 'constant') THEN
              lc_select_var_cols                         := lc_select_var_cols||''''||lc_get_dtl_fields_info.cons_val||''''||',';
              --- Added by Punit for Req# 2303 and Defect# 41733 in SIT03 on 15-APR-2017
              IF (UPPER(lc_get_dtl_fields_info.record_type) = 'LINE') THEN
                lc_insert_col_name_ndt                     := lc_insert_col_name_ndt || lc_column || ln_count || ','; -- Added by Punit on 15-APR-2017
                --lc_select_non_dt                           := lc_select_non_dt || 'hdr.' || lc_get_dtl_fields_info.col_name || ',';
                lc_select_non_dt := lc_select_non_dt || '''' || REPLACE(lc_get_dtl_fields_info.cons_val,'''','''''') || '''' || ','; -- Modified by Punit on 21-JUN-2017
              END IF;
              --- End of Added by Punit for Req# 2303 and Defect# 41733 in SIT03 on 15-APR-2017
            ELSIF (LOWER(lc_get_dtl_fields_info.tab_name) = 'function') THEN
              IF lc_get_dtl_fields_info.spl_function     IS NOT NULL THEN
               -- lc_function                              := 'SELECT '||lc_get_dtl_fields_info.spl_function||'('||p_cust_doc_id||','||p_file_id||','||p_org_id||','||''''||lc_get_dtl_fields_info.col_name||''''||') FROM DUAL'; --commented by Aniket CG #22772 on 15 Dec 2017
                --fnd_file.put_line(fnd_file.log,lc_function);

         -- start Added by Aniket CG #22772 on 15 Dec 2017
           IF  UPPER( lc_get_dtl_fields_info.spl_function ) IN ( 'XX_AR_EBL_TXT_SPL_LOGIC_PKG.GET_GRAND_TOTAL' , 'XX_AR_EBL_TXT_SPL_LOGIC_PKG.GET_GRAND_FREIGHT_AMT')
           AND p_cmb_splt_splfunc_whr IS NOT NULL THEN
           lc_function                              := 'SELECT '||lc_get_dtl_fields_info.spl_function||'('||p_cust_doc_id||','||p_file_id||','||p_org_id||','||''''||lc_get_dtl_fields_info.col_name||''''||','|| p_cmb_splt_splfunc_whr || ') FROM DUAL';
           ELSE
           lc_function                              := 'SELECT '||lc_get_dtl_fields_info.spl_function||'('||p_cust_doc_id||','||p_file_id||','||p_org_id||','||''''||lc_get_dtl_fields_info.col_name||''''||') FROM DUAL';
           END IF;
         -- end Added by Aniket CG #22772 on 15 Dec 2017
                EXECUTE IMMEDIATE lc_function INTO lc_function_return;
                lc_select_var_cols := lc_select_var_cols||lc_function_return||',';
              
			  ELSE
			   --Added 2 Values in  by Aniket CG 15 May #NAIT-29364
                IF UPPER(lc_get_dtl_fields_info.col_name) NOT IN ('SIGN','DC_INDICATOR','ORIG_INV_AMT_DB' , 'ORIG_INV_AMT_CR','EXT_PRICE_DB' ,'EXT_PRICE_CR')  THEN -- Added by Punit CG on 17th Aug 2017 for Defect # 40174
			  --Added 2 Values in  by Aniket CG 15 May #NAIT-29364
				 lc_select_var_cols := lc_select_var_cols||'NULL'||',';
                  -- Checking to print line number in the file or not.
                  BEGIN
                    SELECT xftv.target_value1,
                      target_value2,
                      target_value3
                    INTO lc_target_value1,
                      lc_target_value2,
                      lc_target_value3
                    FROM xx_fin_translatedefinition xftd ,
                      xx_fin_translatevalues xftv
                    WHERE xftd.translate_id   = xftv.translate_id
                    AND xftd.translation_name = 'XX_AR_EBL_TXT_LINE_NUM'
                    AND xftv.enabled_flag     = 'Y'
                    AND TRUNC(sysdate) BETWEEN TRUNC(XFTV.START_DATE_ACTIVE) AND TRUNC(NVL(XFTV.END_DATE_ACTIVE,SYSDATE+1))
                    AND xftv.source_value1 = lc_get_dtl_fields_info.col_name;
                    fnd_file.put_line(fnd_file.log,' Target Values '||lc_target_value1||' - '||lc_target_value2||' - '||lc_target_value3);
                    IF lc_get_dist_record_type    = 'HDR' THEN
                      lc_print_hdr_line_num      := 'Y';
                      lc_hdr_line_num_col        := lc_hdr_line_num_col || lc_column||ln_count || ','; -- Modified by Thilak CG on 25-JUL-2017 for Defect#42380
                      ln_hdr_line_num_fid        := lc_get_dtl_fields_info.field_id;
                      ln_hdr_line_num_source     := lc_get_dtl_fields_info.col_name;
                    ELSIF lc_get_dist_record_type = 'LINE' THEN
                      lc_print_line_line_num     := 'Y';
                      lc_line_line_num_col       := lc_line_line_num_col || lc_column||ln_count || ','; -- Modified by Thilak CG on 25-JUL-2017 for Defect#42380
                      ln_line_line_num_fid       := lc_get_dtl_fields_info.field_id;
                      ln_line_line_num_source    := lc_get_dtl_fields_info.col_name;
                    ELSIF lc_get_dist_record_type = 'DIST' THEN
                      lc_print_dist_line_num     := 'Y';
                      lc_dist_line_num_col       := lc_dist_line_num_col || lc_column||ln_count || ','; -- Modified by Thilak CG on 25-JUL-2017 for Defect#42380
                      ln_dist_line_num_fid       := lc_get_dtl_fields_info.field_id;
                      ln_dist_line_num_source    := lc_get_dtl_fields_info.col_name;
                    END IF;
                    lc_err_location_msg := 'Line Number Print at Header Level '||lc_print_hdr_line_num||' - '||lc_hdr_line_num_col||' - '||ln_hdr_line_num_source ||' - Line Number Print at Lines Level '||lc_print_line_line_num||' - '||lc_line_line_num_col||' - '||ln_line_line_num_source ||' - Line Number Print at Distribution Level '||lc_print_dist_line_num||' - '||lc_dist_line_num_col||' - '||ln_dist_line_num_source;
                    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg);
                  END;
                  -- Start of Added by Punit CG on 17th Aug 2017 for Defect # 40174
                ELSE
				   --Added by Aniket CG 15 May #NAIT-29364  --lc_get_dtl_fields_info.db_cr_seperator IS NOT NULL AND
                      IF  UPPER(lc_get_dtl_fields_info.col_name) IN ('ORIG_INV_AMT_DB','ORIG_INV_AMT_CR','EXT_PRICE_DB','EXT_PRICE_CR')THEN
                        SELECT lc_get_dtl_fields_info.db_cr_seperator
                        INTO lc_db_cr_nvl_value
                        FROM DUAL;

						lc_db_cr_nvl_value:= nvl(lc_db_cr_nvl_value,'NULL');

                        IF UPPER(lc_get_dtl_fields_info.col_name) = 'ORIG_INV_AMT_DB' THEN
                          lc_select_var_cols := lc_select_var_cols|| ' DECODE (SIGN (hdr.original_invoice_amount) ,0,0, 1 , hdr.original_invoice_amount ,'|| lc_db_cr_nvl_value ||' )'|| ',';
                        ELSIF UPPER(lc_get_dtl_fields_info.col_name) = 'ORIG_INV_AMT_CR' THEN
                          lc_select_var_cols := lc_select_var_cols|| ' DECODE (SIGN (hdr.original_invoice_amount) ,-1 , hdr.original_invoice_amount ,'|| lc_db_cr_nvl_value || ' )'|| ',';
                        ELSIF UPPER(lc_get_dtl_fields_info.col_name) ='EXT_PRICE_DB' THEN
                          lc_select_var_cols := lc_select_var_cols|| ' DECODE (SIGN (dtl.ext_price) ,0,0,1,dtl.ext_price ,'|| lc_db_cr_nvl_value || ')'|| ',';
                        ELSIF UPPER(lc_get_dtl_fields_info.col_name) = 'EXT_PRICE_CR' THEN
                          lc_select_var_cols := lc_select_var_cols|| ' DECODE (SIGN (dtl.ext_price) ,-1,dtl.ext_price ,'|| lc_db_cr_nvl_value || ')'|| ',';
                        END IF;
                      ELSE
                        lc_select_var_cols := lc_select_var_cols||'NULL'||',';
                      END IF;
                      --Added by Aniket CG 15 May #NAIT-29364

                  -- lc_select_var_cols := lc_select_var_cols||'NULL'||',';  --Commented by Aniket CG #NAIT-29364
                END IF;
                -- End of Added by Punit CG on 17th Aug 2017 for Defect # 40174
              END IF;
              IF lc_get_dtl_fields_info.col_name = 'SEQUENCE_NUM' THEN
                lc_seq_num_exists               := 'Y';
                lc_seq_num_col                  := lc_column||ln_count;
                ln_seq_num_fid                  := lc_get_dtl_fields_info.field_id;
              END IF;
              IF lc_get_dtl_fields_info.col_name = 'DIST_SEQUENCE_NUM' THEN
                lc_dist_seq_num_exists          := 'Y';
                lc_dist_seq_num_col             := lc_column||ln_count;
                ln_dist_seq_num_fid             := lc_get_dtl_fields_info.field_id;
              END IF;
            END IF;

		    -- Added by Thilak CG on 12-OCT-2017 for Wave2 UAT Defect#13836
            IF lc_get_dtl_fields_info.sort_order IS NOT NULL AND lc_get_dtl_fields_info.sort_type IS NOT NULL AND lc_get_dtl_fields_info.record_type = 'HDR'
            THEN
		      lc_hdr_sort_columns :=
			     lc_hdr_sort_columns
				 || 'COLUMN'
			     || ln_count
			     || ' '
			     || lc_get_dtl_fields_info.sort_type
			     || ',';
            ELSIF lc_get_dtl_fields_info.sort_order IS NOT NULL AND lc_get_dtl_fields_info.sort_type IS NOT NULL AND lc_get_dtl_fields_info.record_type = 'LINE'
            THEN
		      lc_line_sort_columns :=
			     lc_line_sort_columns
				 || 'COLUMN'
			     || ln_count
			     || ' '
			     || lc_get_dtl_fields_info.sort_type
			     || ',';
            ELSIF lc_get_dtl_fields_info.sort_order IS NOT NULL AND lc_get_dtl_fields_info.sort_type IS NOT NULL AND lc_get_dtl_fields_info.record_type = 'DIST'
            THEN
		      lc_dist_line_sort_columns :=
			     lc_dist_line_sort_columns
				 || 'COLUMN'
			     || ln_count
			     || ' '
			     || lc_get_dtl_fields_info.sort_type
			     || ',';
            END IF;
		    -- End

            -- Start of changes done by Thilak CG for Defect #40174 on 07-AUG-2017
            IF (UPPER(lc_get_dtl_fields_info.dc_indicator) IS NOT NULL AND lc_dc_flag = 'N') THEN
              lc_dc_flag                                   := 'Y';
              lc_debit                                     := NULL;
              lc_credit                                    := NULL;
              lc_err_location_msg                          := 'Before DC Indicator Selection';
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
              BEGIN
                SELECT description,
                  tag
                INTO lc_debit,
                  lc_credit
                FROM fnd_lookup_values_vl FLV
                WHERE FLV.lookup_type  = 'XXOD_EBL_DEBIT_CREDIT_SIGN_IND'
                AND UPPER(flv.meaning) = UPPER(lc_get_dtl_fields_info.dc_indicator)
                AND FLV.enabled_flag   = 'Y'
                AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
              EXCEPTION
              WHEN OTHERS THEN
                lc_err_location_msg := 'Error during select mapping column for Detail from the lookup XXOD_EBL_DEBIT_CREDIT_SIGN_IND';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
                p_dtl_error_flag := 'Y';
                p_dtl_error_msg  := lc_err_location_msg;
              END;
            END IF;
            -- End
            -- Start of changes done by Thilak CG for Defect #40174 on 07-AUG-2017
            IF (UPPER(lc_get_dtl_fields_info.absolute_flag) = 'Y') THEN
              lc_abs_flag                                  := 'Y';
              ln_abs_cnt                                   := 0;
              BEGIN
                SELECT COUNT(flv.lookup_code)
                INTO ln_abs_cnt
                FROM fnd_lookup_values_vl FLV
                WHERE FLV.lookup_type      = 'XX_AR_EBL_TXT_DTL_ABS_COLS'
                AND UPPER(flv.lookup_code) = UPPER(lc_get_dtl_fields_info.col_name)
                AND FLV.enabled_flag       = 'Y'
                AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
              EXCEPTION
              WHEN OTHERS THEN
                lc_err_location_msg := 'Error during select mapping column for Detail from the lookup XX_AR_EBL_TXT_DTL_ABS_COLS';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
                p_dtl_error_flag := 'Y';
                p_dtl_error_msg  := lc_err_location_msg;
              END;
              IF ln_abs_cnt          = 1 THEN
                lc_get_abs_amt_cols := lc_get_abs_amt_cols || ' ' || lc_column || ln_count || ' = ' ||'ABS('||lc_column || ln_count||')'||',';
                ln_abs_update_cnt   := 1;
              END IF;
            END IF;
            -- End of Changes done by Thilak CG for Defect #40174 on 07-AUG-2017
            -- Start of changes done by Punit CG for Defect #40174 on 11-AUG-2017
            BEGIN
              SELECT COUNT(flv.lookup_code)
              INTO ln_sign_cnt
              FROM fnd_lookup_values_vl FLV
              WHERE FLV.lookup_type      = 'XX_AR_EBL_TXT_DTL_SIGN_COLS'
              AND UPPER(flv.lookup_code) = UPPER(lc_get_dtl_fields_info.col_name)
              AND FLV.enabled_flag       = 'Y'
              AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
              IF (ln_sign_cnt     = 1 AND lc_sign_flag = 'N' AND lc_amt_sign_flag = 'N') THEN
                lc_amt_sign_flag := 'Y';
                -- lc_amt_col_for_sign := lc_column||ln_count;
                --lc_sign_col_decode := 'DECODE(SIGN(' || lc_amt_col_for_sign || '),''1'',''+'',''-1'',''-'','''')';
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              lc_err_location_msg := 'Error while selecting the mapping SIGN column from the lookup XX_AR_EBL_TXT_DTL_SIGN_COLS';
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
              p_dtl_error_flag := 'Y';
              p_dtl_error_msg  := lc_err_location_msg;
            END;
            IF (UPPER(lc_get_dtl_fields_info.col_name) = 'SIGN') THEN
              lc_get_sign_amt_cols                    := lc_get_sign_amt_cols || ' ' || lc_column || ln_count || ',';
              ln_sign_update_cnt                      := 1;
            END IF;
            IF (lc_sign_flag = 'N' AND lc_amt_sign_flag = 'N' AND UPPER(lc_get_dtl_fields_info.col_name) = 'SIGN') THEN
              lc_sign_flag  := 'Y';
            END IF;
            -- End of changes done by Punit CG for Defect #40174 on 11-AUG-2017
            -- Start of Changes done by Punit CG for Requirement #2282 on 06-FEB-2017
            IF (UPPER(lc_get_dist_record_type)                    = 'LINE') THEN -- Added by Punit on 31-JUL-2017
              IF (UPPER(lc_get_dtl_fields_info.repeat_total_flag) = 'N') THEN
                lc_repeat_total                                  := 'N';
                ln_repeat_cnt                                    := 0;
                BEGIN
                  SELECT COUNT(flv.lookup_code)
                  INTO ln_repeat_cnt
                  FROM fnd_lookup_values_vl FLV
                  WHERE FLV.lookup_type      = 'XX_AR_EBL_TXT_RPT_TOTAL_COLS'
                  AND UPPER(flv.lookup_code) = UPPER(lc_get_dtl_fields_info.col_name)
                  AND FLV.enabled_flag       = 'Y'
                  AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
                EXCEPTION
                WHEN OTHERS THEN
                  lc_err_location_msg := 'Error during select mapping column from the lookup XX_AR_EBL_TXT_RPT_TOTAL_COLS';
                  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
                  p_dtl_error_flag := 'Y';
                  p_dtl_error_msg  := lc_err_location_msg;
                END;
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,'lc_get_dtl_fields_info.col_name '||lc_get_dtl_fields_info.col_name );
				IF (ln_repeat_cnt        = 1 AND (UPPER(lc_get_dtl_fields_info.col_name) NOT IN ('TOTAL_US_TAX_AMOUNT','TOTAL_FREIGHT_AMOUNT','TOTAL_MISCELLANEOUS_AMOUNT','TOTAL_FEE_AMOUNT'))) THEN
                  lc_get_total_amt_cols := lc_get_total_amt_cols || ' ' || lc_column || ln_count || ' = ' ||''''||ln_total_default||''''||',';
                  ln_update_cnt         := 1;
                ELSIF (ln_repeat_cnt        = 1 AND (UPPER(lc_get_dtl_fields_info.col_name) IN ('TOTAL_FEE_AMOUNT')) AND lv_hide_flag = 'N') THEN
                  lc_get_total_amt_cols := lc_get_total_amt_cols || ' ' || lc_column || ln_count || ' = ' ||''''||ln_total_default||''''||',';
				  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,'lc_get_dtl_fields_info.lv_hide_flag '||lv_hide_flag);
                  ln_update_cnt         := 1;
				ELSIF (ln_repeat_cnt     = 1 AND (UPPER(lc_get_dtl_fields_info.col_name) = 'TOTAL_US_TAX_AMOUNT')) THEN
                  lc_tax_col            := lc_column || ln_count;
                  lc_tax_amt            := lc_tax_col || ' = DECODE(rec_type,''TX'','||lc_tax_col||','||''''||ln_total_default||''''||')' ;
                ELSIF (ln_repeat_cnt     = 1 AND (UPPER(lc_get_dtl_fields_info.col_name) = 'TOTAL_FREIGHT_AMOUNT')) THEN
                  lc_freight_col        := lc_column || ln_count;
                  lc_freight_amt        := lc_freight_col || ' = DECODE(rec_type,''DL'','||lc_freight_col||','||''''||ln_total_default||''''||')';
                ELSIF (ln_repeat_cnt     = 1 AND (UPPER(lc_get_dtl_fields_info.col_name) = 'TOTAL_MISCELLANEOUS_AMOUNT')) THEN
                  lc_misc_col           := lc_column || ln_count;
                  lc_misc_amt           := lc_misc_col || ' = DECODE(rec_type,''MS'','||lc_misc_col||','||''''||ln_total_default||''''||')';
                END IF;
              END IF;
              -- End of Changes done by Punit CG for Requirement #2282 on 06-FEB-2017
              -- Start of Changes done by Punit CG for Requirement #2302 (A,G,H) on 08-FEB-2017
              IF (UPPER(lc_get_dtl_fields_info.spl_fields) = 'Y') THEN
                lc_err_location_msg                       := 'Framing the insert and select statement for NON-DT records for special column: '||lc_get_dtl_fields_info.col_name;
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
                BEGIN
                  SELECT flv.meaning,
                    flv.tag,
                    UPPER(flv.lookup_code)
                  INTO lc_lkp_meaning,
                    lc_lkp_tag,
                    lc_lkp_lookup_code
                  FROM fnd_lookup_values_vl FLV
                  WHERE FLV.lookup_type      = 'XX_AR_EBL_NONDT_REC_TYPES'
                  AND UPPER(flv.lookup_code) = UPPER(lc_get_dtl_fields_info.col_name)
                  AND FLV.enabled_flag       = 'Y'
                  AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lc_err_location_msg := 'The special coulumn ' || lc_get_dtl_fields_info.col_name || ' does not have a mapping column in look up XX_AR_EBL_NONDT_REC_TYPES';
                  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
                  p_dtl_error_flag := 'Y';
                  p_dtl_error_msg  := lc_err_location_msg;
                WHEN OTHERS THEN
                  lc_err_location_msg := 'Error during selecting mapping column from the look up XX_AR_EBL_NONDT_REC_TYPES';
                  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
                  p_dtl_error_flag := 'Y';
                  p_dtl_error_msg  := lc_err_location_msg;
                END;
				-- start Added by Aniket CG 15 May #NAIT-29364
                 IF (UPPER(lc_lkp_tag) = 'Y') and UPPER(lc_get_dtl_fields_info.col_name) in ('EXT_PRICE','LINE_LEVEL_COMMENT')THEN
				-- end Added by Aniket CG 15 May #NAIT-29364
				-- IF (UPPER(lc_lkp_tag) = 'Y') THEN  -- Commented by Aniket #NAIT-29364
                  lc_decode_verbiage := REPLACE(lc_decode_non_dt,'xxx',lc_lkp_meaning);
                  lc_decode_verbiage := REPLACE(lc_decode_verbiage,'yyy',lc_decode_hdr_col);
                  lc_select_non_dt   := lc_select_non_dt || lc_decode_verbiage || ',';
				-- start Added by Aniket CG 15 May #NAIT-29364
                ELSIF (UPPER(lc_lkp_tag) = 'Y') and UPPER(lc_get_dtl_fields_info.col_name) in ('EXT_PRICE_DB')THEN
                  lc_decode_verbiage := REPLACE(lc_decode_non_dt_db,'xxx',lc_lkp_meaning);
                  lc_decode_verbiage := REPLACE(lc_decode_verbiage,'yyy',lc_decode_hdr_col);
                  lc_select_non_dt   := lc_select_non_dt || lc_decode_verbiage || ',';
                ELSIF (UPPER(lc_lkp_tag) = 'Y') and UPPER(lc_get_dtl_fields_info.col_name) in ('EXT_PRICE_CR')THEN
                  lc_decode_verbiage := REPLACE(lc_decode_non_dt_cr,'xxx',lc_lkp_meaning);
                  lc_decode_verbiage := REPLACE(lc_decode_verbiage,'yyy',lc_decode_hdr_col);
                  lc_select_non_dt   := lc_select_non_dt || lc_decode_verbiage || ',';
               --end Added by Aniket CG 15 May #NAIT-29364
                ELSIF (lc_lkp_tag    IS NULL AND lc_lkp_lookup_code LIKE '%PRODUCT_CODE%') THEN
                  lc_select_non_dt   := lc_select_non_dt || lc_decode_product || ',';
                ELSIF (lc_lkp_tag    IS NULL AND lc_lkp_lookup_code = 'ITEM_DESCRIPTION') THEN
                  lc_select_non_dt   := lc_select_non_dt || lc_decode_sku || ',';
                ELSE
                  lc_select_non_dt := lc_select_non_dt || lc_lkp_meaning || ',';
                END IF;
                lc_insert_col_name_ndt := lc_insert_col_name_ndt || lc_column || ln_count || ',';
              END IF;
              -- End of Changes done by Punit for Requirement #2302 (A,G,H) on 08-FEB-2017
              -- Start of Changes done by Punit for Requirement #2302 (C,D) on 08-FEB-2017
              IF (UPPER(lc_get_dtl_fields_info.col_name) = 'EXT_PRICE') THEN
                lc_ext_col                              := lc_column || ln_count;
                lc_tax_ep_flag                          := lc_get_dtl_fields_info.tax_ep_flag;
                lc_freight_ep_flag                      := lc_get_dtl_fields_info.freight_ep_flag;
                lc_misc_ep_flag                         := lc_get_dtl_fields_info.misc_ep_flag;
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,('Ext Price ' || lc_ext_col) );
              END IF;
			    -- start Added by Aniket CG 15 May #NAIT-29364
               IF (UPPER(lc_get_dtl_fields_info.col_name) in ('EXT_PRICE_DB')) THEN
                lc_ext_col_db                              := lc_column || ln_count;
                lc_tax_ep_flag_db                          := lc_get_dtl_fields_info.tax_ep_flag;
                lc_freight_ep_flag_db                      := lc_get_dtl_fields_info.freight_ep_flag;
                lc_misc_ep_flag_db                         := lc_get_dtl_fields_info.misc_ep_flag;
                lc_ext_db_nvl_value                        := lc_get_dtl_fields_info.db_cr_seperator;
                  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,('Ext Price DB' || lc_ext_col_db) );
              END IF;
                IF (UPPER(lc_get_dtl_fields_info.col_name) in ('EXT_PRICE_CR')) THEN
                lc_ext_col_cr                              := lc_column || ln_count;
                lc_tax_ep_flag_cr                          := lc_get_dtl_fields_info.tax_ep_flag;
                lc_freight_ep_flag_cr                      := lc_get_dtl_fields_info.freight_ep_flag;
                lc_misc_ep_flag_cr                         := lc_get_dtl_fields_info.misc_ep_flag;
                lc_ext_cr_nvl_value                        := lc_get_dtl_fields_info.db_cr_seperator;
                  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,('Ext Price CR' || lc_ext_col_cr) );
              END IF;
              -- end Added by Aniket CG 15 May #NAIT-29364

              IF (UPPER(lc_get_dtl_fields_info.col_name) = 'UNIT_PRICE') THEN
                lc_unitprice_col                        := lc_column || ln_count;
                lc_tax_up_flag                          := lc_get_dtl_fields_info.tax_up_flag;
                lc_freight_up_flag                      := lc_get_dtl_fields_info.freight_up_flag;
                lc_misc_up_flag                         := lc_get_dtl_fields_info.misc_up_flag;
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,('Unit Price ' || lc_unitprice_col) );
              END IF;
              -- End of Changes done by Punit CG for Requirement #2302 (C,D) on 08-FEB-2017
              -- Start of Changes done by Punit CG for Requirement #2302 (I) on 17-MAR-2017
              IF (UPPER(lc_get_dtl_fields_info.col_name) = 'QUANTITY_SHIPPED') THEN
                lc_qty_ship_exists                      := 'Y'; -- Added on 21-JUN-2017
                IF (ln_nondt_qty                        IS NOT NULL) THEN
                  ln_nondt_qty_update                   := ln_nondt_qty_update|| ' ' || lc_column || ln_count || ' =  '||ln_nondt_qty;
                END IF;
              END IF;
              IF (LOWER(lc_get_dtl_fields_info.col_name) = 'elec_detail_seq_number' ) THEN
                lc_seq_ndt                              := lc_column || ln_count;
              END IF;
            END IF;
            -- End of Changes done by Punit CG for Requirement #2302 (I) on 17-MAR-2017
            -- Start of changes done by Thilak CG for Defect #40174 on 07-AUG-2017
            -- Start Added by Aniket CG Defect#24883
           -- IF lc_get_dist_record_type    = 'HDR' AND UPPER(lc_get_dtl_fields_info.col_name) = 'ORIGINAL_INVOICE_AMOUNT' THEN Commented by Aniket CG Defect#24883
            IF  UPPER(lc_get_dtl_fields_info.col_name) = 'ORIGINAL_INVOICE_AMOUNT' THEN
           -- End Added by Aniket CG Defect#24883
              lc_dc_amt_col              := lc_column||ln_count;
			     --start Added by Aniket CG 15 May #NAIT-29364
                    lc_dc_col_orig_flgchk := 'Y';
                    ELSIF UPPER(lc_get_dtl_fields_info.col_name) = 'ORIG_INV_AMT_DB' THEN
                    IF lc_dc_col_orig_flgchk = 'N'  THEN
                    lc_dc_amt_col_db  := lc_column||ln_count;
                    END IF;
                    ELSIF UPPER(lc_get_dtl_fields_info.col_name) = 'ORIG_INV_AMT_CR' THEN
                    IF lc_dc_col_orig_flgchk = 'N'  THEN
                    lc_dc_amt_col_cr  := lc_column||ln_count;
                    END IF;
				--end Added by Aniket CG 15 May #NAIT-29364
            ELSIF lc_get_dist_record_type = 'LINE' AND UPPER(lc_get_dtl_fields_info.col_name) = 'EXT_PRICE' THEN
              lc_dc_amt_col              := lc_column||ln_count;
		    --start Added by Aniket CG 15 May #NAIT-29364
               lc_dc_col_ext_flgchk := 'Y';
            ELSIF lc_get_dist_record_type = 'LINE' AND UPPER(lc_get_dtl_fields_info.col_name) = 'EXT_PRICE_DB' THEN
                 IF lc_dc_col_ext_flgchk = 'N'  THEN
                 lc_dc_amt_col_db  := lc_column||ln_count;
                 END IF;
            ELSIF lc_get_dist_record_type = 'LINE' AND UPPER(lc_get_dtl_fields_info.col_name) = 'EXT_PRICE_CR' THEN
                IF lc_dc_col_ext_flgchk = 'N'  THEN
                lc_dc_amt_col_cr  := lc_column||ln_count;
                 END IF;
                --end Added by Aniket CG 15 May #NAIT-29364
            END IF;

   	        IF UPPER(lc_get_dtl_fields_info.col_name) = 'DC_INDICATOR' THEN
		      lc_dc_indicator_col := lc_column||ln_count;
	        END IF;
            -- End
            if lv_hide_flag = 'N' THEN 
				lc_insert_col_name := lc_insert_col_name||lc_column||ln_count||',';
				lc_dtl_value_fid   := lc_dtl_value_fid||lc_get_dtl_fields_info.field_id||',';
				ln_count           := ln_count + 1;
			END IF;
          END LOOP;
			IF lv_fee_option !=1010 THEN
				lv_upd_str := 'update xx_ar_ebl_cons_hdr_main set TOTAL_MISCELLANEOUS_AMOUNT = TOTAL_MISCELLANEOUS_AMOUNT + (XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id )+ XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id)) WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND batch_id = '||p_batch_id;
				lv_upd_str1 := 'update xx_ar_ebl_cons_hdr_main set SKU_LINES_SUBTOTAL = SKU_LINES_SUBTOTAL - (XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id )+ XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id)) WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND batch_id = '||p_batch_id;
				execute immediate lv_upd_str;
				execute immediate lv_upd_str1;
			END IF;
          IF lc_get_dist_record_type = 'HDR' THEN
            lc_insert_col_name      := lc_insert_hdr_const_cols||SUBSTR(lc_insert_col_name,1,LENGTH(lc_insert_col_name)                                                                                                                                      -1)||')';
            lc_select_var_cols      := lc_select_cons_hdr||SUBSTR(lc_select_var_cols,1,LENGTH(lc_select_var_cols)                                                                                                                                            -1)||lc_from_cons_hdr|| p_cmb_splt_whr || ')'; --Added by Aniket CG #22772 on 15 Dec 2017
            lc_dtl_value_fid        := ' VALUES ('||xx_ar_ebl_txt_stg_id_s.nextval||','||p_cust_doc_id||',NULL,'||p_file_id||',fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,'||SUBSTR(lc_dtl_value_fid,1,LENGTH(lc_dtl_value_fid)-1)||')';
          ELSE
            lc_insert_col_name := lc_insert_dtl_const_cols||SUBSTR(lc_insert_col_name,1,LENGTH(lc_insert_col_name)                                                                                                                                                     -1)||')';
            lc_select_var_cols := lc_select_cons_dtl||SUBSTR(lc_select_var_cols,1,LENGTH(lc_select_var_cols)                                                                                                                                                           -1)||lc_from_cons_dtl|| p_cmb_splt_whr || ')'; --Added by Aniket CG #22772 on 15 Dec 2017
            lc_dtl_value_fid   := ' VALUES ('||xx_ar_ebl_txt_stg_id_s.nextval||','||p_cust_doc_id||',NULL,NULL,NULL,NULL,'||p_file_id||',fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,'||SUBSTR(lc_dtl_value_fid,1,LENGTH(lc_dtl_value_fid)-1)||')';
          END IF;
          lc_err_location_msg := 'Select and Insert Statement for FID record for : '||lc_get_dist_record_type||' - '||lc_insert_col_name||lc_dtl_value_fid ;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
          lc_err_location_msg := 'Select and Insert Statement for DTL record for : '||lc_get_dist_record_type||' - '||lc_insert_col_name||lc_select_var_cols ;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
          EXECUTE IMMEDIATE lc_insert_col_name||lc_dtl_value_fid;
          EXECUTE IMMEDIATE lc_insert_col_name||lc_select_var_cols;
          --- moved by Punit on 31-JUL-2017
          IF (UPPER(lc_get_dist_record_type) = 'LINE') THEN -- Added by Punit on 31-JUL-2017
            --IF (lc_rec_type = 'LINE') THEN  -- Added by Punit on 12-JUN-2017
            lc_select_ndt := SUBSTR(lc_select_non_dt,1,(LENGTH(lc_select_non_dt)-1));
            -- Added for Defect # 39140 by Punit CG on 05-JUL-2017
            IF ( lc_seq_ndt        IS NULL) THEN
              lc_insert_select_ndt := lc_insert_const_cols_dtl || SUBSTR(lc_insert_col_name_ndt,1,(LENGTH(lc_insert_col_name_ndt)-1)) || ')' || lc_select_const_cols_dtl || p_batch_id ||','||lc_decode_hdr_col ||', NULL,';
            ELSE
              lc_insert_select_ndt := lc_insert_const_cols_dtl || lc_insert_col_name_ndt || lc_seq_ndt || ')' || lc_select_const_cols_dtl || p_batch_id ||','||lc_decode_hdr_col ||', NULL,';
            END IF;
            --End of Added for Defect # 39140 by Punit CG on 05-JUL-2017
            lc_err_location_msg := 'Value of lc_insert_col_name_ndt is : '||lc_insert_col_name_ndt;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,TRUE ,lc_err_location_msg );
            lc_err_location_msg := 'Value of lc_insert_select_ndt is : '||lc_insert_select_ndt;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,TRUE ,lc_err_location_msg );
            lc_err_location_msg := 'Value of lc_select_ndt is : '||lc_select_ndt;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,TRUE ,lc_err_location_msg );
            lc_err_location_msg := 'Calling Child NON_DT Procedure, value of lc_seq_ndt is '||lc_seq_ndt;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,TRUE ,lc_err_location_msg );
            -- ln_get_line_dist_rows parameter Added by Punit for Defect #41307 on 31-JUL-2017

          -- Start Added by Aniket CG #22772 on 15 Dec 2017
           XX_AR_EBL_TXT_CHILD_NON_DT(p_cust_doc_id,p_batch_id,p_file_id,lc_insert_select_ndt,lc_select_ndt,lc_seq_ndt,ln_get_line_dist_rows,p_cmb_splt_whr,'CONS',p_debug_flag,lc_insert_status,p_cycle_date);
          -- End Added by Aniket CG #22772 on 15 Dec 2017

            IF (lc_insert_status  IS NOT NULL) THEN
              lc_err_location_msg := 'Error in inserting NON-DT records: '||lc_insert_status;
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,TRUE ,lc_err_location_msg );
              p_dtl_error_flag := 'Y';
              p_dtl_error_msg  := lc_err_location_msg;
              --ROLLBACK TO ins_cust_doc_id;
            END IF;
            lc_err_location_msg := 'Value of lc_repeat_total is '||lc_repeat_total||' and Value of ln_update_cnt is '||ln_update_cnt ;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg|| '-' ||lc_update_total_amt_cols );
            IF ((lc_repeat_total        = 'N') AND (ln_update_cnt = 1)) THEN
              lc_update_total_amt_cols := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET' || SUBSTR(lc_get_total_amt_cols,1,LENGTH(lc_get_total_amt_cols)-1) || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' || p_cust_doc_id || ' AND file_id = ' || p_file_id || ' AND NVL(trx_line_number,2) != 1 ' || ' AND REC_ORDER = '||ln_get_line_dist_rows -- Added by Punit on 17-AUG-2017 for Defect# 40174
              || ' AND trx_type = '||''''||lc_get_dist_record_type||'''';                                                                                                                                                                                                                                                                  -- Added by Punit on 17-AUG-2017 for Defect# 40174
              BEGIN
                EXECUTE IMMEDIATE lc_update_total_amt_cols;
                lc_err_location_msg := 'Executed Total Amount update in XX_AR_EBL_TXT_DTL_STG table';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg|| '-' ||lc_update_total_amt_cols );
              EXCEPTION
              WHEN OTHERS THEN
                lc_err_location_msg := 'Error While Updating the Total Amount Columns of Detail Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
                XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_total_amt_cols);
                p_dtl_error_flag := 'Y';
                p_dtl_error_msg  := lc_err_location_msg;
              END;
            END IF;
            IF ((lc_repeat_total      = 'N') AND ((lc_tax_col IS NOT NULL))) THEN
              lc_update_tax_amt_cols := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET ' || lc_tax_amt || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' ||p_cust_doc_id || ' AND file_id = ' || p_file_id || ' AND REC_ORDER = '||ln_get_line_dist_rows -- Added by Punit on 17-AUG-2017 for Defect# 40174
              || ' AND trx_type = '||''''||lc_get_dist_record_type||'''';                                                                                                                                                                    -- Added by Punit on 17-AUG-2017 for Defect# 40174
              --|| ' AND trx_line_number IS NULL AND rec_type = ''TX'''; -- Added by Punit on 31-JUL-2017 for Defect# 41307
              BEGIN
                EXECUTE IMMEDIATE lc_update_tax_amt_cols;
                lc_err_location_msg := 'Executed Tax Amount update in XX_AR_EBL_TXT_DTL_STG table';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg|| '-' ||lc_update_tax_amt_cols );
              EXCEPTION
              WHEN OTHERS THEN
                lc_err_location_msg := 'Error While Updating the Tax Amount Columns of Detail Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
                XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_tax_amt_cols);
                p_dtl_error_flag := 'Y';
                p_dtl_error_msg  := lc_err_location_msg;
              END;
            END IF;
            IF ((lc_repeat_total          = 'N') AND (lc_freight_col IS NOT NULL)) THEN
              lc_update_freight_amt_cols := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET ' || lc_freight_amt || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' ||p_cust_doc_id || ' AND file_id = ' || p_file_id || ' AND REC_ORDER = '||ln_get_line_dist_rows -- Added by Punit on 17-AUG-2017 for Defect# 40174
              || ' AND trx_type = '||''''||lc_get_dist_record_type||'''';                                                                                                                                                                            -- Added by Punit on 17-AUG-2017 for Defect# 40174
              --|| ' AND trx_line_number IS NULL AND rec_type = ''DL'''; -- Added by Punit on 31-JUL-2017 for Defect# 41307
              BEGIN
                EXECUTE IMMEDIATE lc_update_freight_amt_cols;
                lc_err_location_msg := 'Executed Freight Amount update in XX_AR_EBL_TXT_DTL_STG table';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg|| '-' ||lc_update_freight_amt_cols );
              EXCEPTION
              WHEN OTHERS THEN
                lc_err_location_msg := 'Error While Updating the Freight Amount Columns of Detail Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
                XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_freight_amt_cols);
                p_dtl_error_flag := 'Y';
                p_dtl_error_msg  := lc_err_location_msg;
              END;
            END IF;
            IF ((lc_repeat_total       = 'N') AND (lc_misc_col IS NOT NULL)) THEN
              lc_update_misc_amt_cols := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET ' || lc_misc_amt || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' ||p_cust_doc_id || ' AND file_id = ' || p_file_id || ' AND REC_ORDER = '||ln_get_line_dist_rows -- Added by Punit on 17-AUG-2017 for Defect# 40174
              || ' AND trx_type = '||''''||lc_get_dist_record_type||'''';                                                                                                                                                                      -- Added by Punit on 17-AUG-2017 for Defect# 40174
              --|| ' AND trx_line_number IS NULL AND rec_type = ''MS'''; -- Added by Punit on 31-JUL-2017 for Defect# 41307
              BEGIN
                EXECUTE IMMEDIATE lc_update_misc_amt_cols;
                lc_err_location_msg := 'Executed Misc Amount update in XX_AR_EBL_TXT_DTL_STG table';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg|| '-' ||lc_update_misc_amt_cols );
              EXCEPTION
              WHEN OTHERS THEN
                lc_err_location_msg := 'Error While Updating the Misc Amount Columns of Detail Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
                XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_misc_amt_cols);
                p_dtl_error_flag := 'Y';
                p_dtl_error_msg  := lc_err_location_msg;
              END;
            END IF;
            --End of Added by Punit CG for Requirement #2282 on 06-FEB-2017
            --Added by Punit CG for Requirement #2302 (C,D) on 21-FEB-2017
            IF (lc_unitprice_col      IS NOT NULL) THEN
              lc_unit_price           := 'DECODE(rec_type,''TX'',DECODE('''||lc_tax_up_flag||''',''N'','||''''||ln_total_default||''''||','||NVL(lc_ext_col,'''''')||'),''DL'',DECODE('''||lc_freight_up_flag||''',''N'','||''''||ln_total_default||''''||','||NVL(lc_ext_col,'''''')||'),''MS'',DECODE('''||lc_misc_up_flag||''',''N'','||''''||ln_total_default||''''||','||NVL(lc_ext_col,'''''')||'),'||lc_unitprice_col||')';
              lc_update_unitprice_ndt := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET ' || lc_unitprice_col || ' = '|| lc_unit_price || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' || p_cust_doc_id || ' AND file_id = ' || p_file_id || ' AND trx_line_number IS NULL AND rec_type IN (''TX'',''DL'',''MS'')' || ' AND REC_ORDER = '||ln_get_line_dist_rows -- Added by Punit on 17-AUG-2017 for Defect# 40174
              || ' AND trx_type = '||''''||lc_get_dist_record_type||'''';                                                                                                                                                                                                                                                                              -- Added by Punit on 17-AUG-2017 for Defect# 40174
              BEGIN
                EXECUTE IMMEDIATE lc_update_unitprice_ndt;
                lc_err_location_msg := 'Executed Unit Price update in XX_AR_EBL_TXT_DTL_STG table';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg||'-' || lc_update_unitprice_ndt );
              EXCEPTION
              WHEN OTHERS THEN
                lc_err_location_msg := 'Error While Executing Unit Price update in Detail Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
                XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_unitprice_ndt);
                p_dtl_error_flag := 'Y';
                p_dtl_error_msg  := lc_err_location_msg;
              END;
            END IF;
            IF (lc_ext_col           IS NOT NULL) THEN
              lc_ext_price           := 'DECODE(rec_type,''TX'',DECODE('''||lc_tax_ep_flag||''',''N'',DECODE('''||lc_tax_col||''',NULL,'||lc_ext_col||','||''''||ln_total_default||''''||'),'||lc_ext_col||'),''DL'',DECODE('''||lc_freight_ep_flag||''',''N'',DECODE('''||lc_freight_col||''',NULL,'||lc_ext_col||','||''''||ln_total_default||''''||'),'||lc_ext_col||'),''MS'',DECODE('''||lc_misc_ep_flag||''',''N'',DECODE('''||lc_misc_col||''',NULL,'||lc_ext_col||','||''''||ln_total_default||''''||'),'||lc_ext_col||'),'||lc_ext_col||')';
              lc_update_extprice_ndt := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET ' || lc_ext_col || ' = ' || lc_ext_price || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' || p_cust_doc_id || ' AND file_id = ' || p_file_id || ' AND trx_line_number IS NULL AND rec_type IN (''TX'',''DL'',''MS'')' || ' AND REC_ORDER = '||ln_get_line_dist_rows -- Added by Punit on 17-AUG-2017 for Defect# 40174
              || ' AND trx_type = '||''''||lc_get_dist_record_type||'''';                                                                                                                                                                                                                                                                       -- Added by Punit on 17-AUG-2017 for Defect# 40174
              BEGIN
                EXECUTE IMMEDIATE lc_update_extprice_ndt;
                lc_err_location_msg := 'Executed Ext Price update in XX_AR_EBL_TXT_DTL_STG table';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg||'-' || lc_update_extprice_ndt );
              EXCEPTION
              WHEN OTHERS THEN
                lc_err_location_msg := 'Error While Executing Ext Price update in Detail Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
                XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_extprice_ndt);
                p_dtl_error_flag := 'Y';
                p_dtl_error_msg  := lc_err_location_msg;
              END;
            END IF;
            -- End of Added by Punit for Requirement #2302 (C,D) on 21-FEB-2017
			 -- start Added by Aniket CG 15 May #NAIT-29364
              lc_ext_cr_nvl_value := nvl (lc_ext_cr_nvl_value , 'NULL');
              IF (lc_ext_col_db           IS NOT NULL) THEN
              lc_ext_price_db           := 'DECODE(rec_type,''TX'',DECODE('''||lc_tax_ep_flag_db||''',''N'',DECODE('''||lc_tax_col||''',NULL,'||lc_ext_col_db||','||''''||ln_total_default||''''||'),'||lc_ext_col_db||'),''DL'',DECODE('''||lc_freight_ep_flag_db||''',''N'',DECODE('''||lc_freight_col||''',NULL,'||lc_ext_col_db||','||''''||ln_total_default||''''||'),'||lc_ext_col_db||'),''MS'',DECODE('''||lc_misc_ep_flag_db||''',''N'',DECODE('''||lc_misc_col||''',NULL,'||lc_ext_col_db||','||''''||ln_total_default||''''||'),'||lc_ext_col_db||'),'||lc_ext_col_db||')';
              lc_update_extprice_db_ndt := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET ' || lc_ext_col_db || ' = ' || ' DECODE ( SIGN ( ' ||lc_ext_price_db || ' ), 1,'||lc_ext_price_db||', ' || lc_ext_cr_nvl_value || ')'  || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' || p_cust_doc_id || ' AND file_id = ' || p_file_id || ' AND trx_line_number IS NULL AND rec_type IN (''TX'',''DL'',''MS'')' || ' AND REC_ORDER = '||ln_get_line_dist_rows -- Added by Punit on 17-AUG-2017 for Defect# 40174
              || ' AND trx_type = '||''''||lc_get_dist_record_type||'''';                                                                                                                                                                                                                                                                       -- Added by Punit on 17-AUG-2017 for Defect# 40174
              BEGIN
                EXECUTE IMMEDIATE lc_update_extprice_db_ndt;
                lc_err_location_msg := 'Executed Ext Price DB update in XX_AR_EBL_TXT_DTL_STG table';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg||'-' || lc_update_extprice_db_ndt );
              EXCEPTION
              WHEN OTHERS THEN
                lc_err_location_msg := 'Error While Executing Ext Price DB update in Detail Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
                XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_extprice_db_ndt);
                p_dtl_error_flag := 'Y';
                p_dtl_error_msg  := lc_err_location_msg;
              END;
            END IF;

             IF (lc_ext_col_cr           IS NOT NULL) THEN
              lc_ext_price_cr           := 'DECODE(rec_type,''TX'',DECODE('''||lc_tax_ep_flag_cr||''',''N'',DECODE('''||lc_tax_col||''',NULL,'||lc_ext_col_cr||','||''''||ln_total_default||''''||'),'||lc_ext_col_cr||'),''DL'',DECODE('''||lc_freight_ep_flag_cr||''',''N'',DECODE('''||lc_freight_col||''',NULL,'||lc_ext_col_cr||','||''''||ln_total_default||''''||'),'||lc_ext_col_cr||'),''MS'',DECODE('''||lc_misc_ep_flag_cr||''',''N'',DECODE('''||lc_misc_col||''',NULL,'||lc_ext_col_cr||','||''''||ln_total_default||''''||'),'||lc_ext_col_cr||'),'||lc_ext_col_cr||')';
              lc_update_extprice_cr_ndt := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET ' || lc_ext_col_cr || ' = ' || ' DECODE ( SIGN ( ' ||lc_ext_price_cr || ' ),-1,'||lc_ext_price_cr||', '|| lc_ext_cr_nvl_value ||')'  || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' || p_cust_doc_id || ' AND file_id = ' || p_file_id || ' AND trx_line_number IS NULL AND rec_type IN (''TX'',''DL'',''MS'')' || ' AND REC_ORDER = '||ln_get_line_dist_rows -- Added by Punit on 17-AUG-2017 for Defect# 40174
              || ' AND trx_type = '||''''||lc_get_dist_record_type||'''';                                                                                                                                                                                                                                                                       -- Added by Punit on 17-AUG-2017 for Defect# 40174
              BEGIN
                EXECUTE IMMEDIATE lc_update_extprice_cr_ndt;
                lc_err_location_msg := 'Executed Ext Price CR update in XX_AR_EBL_TXT_DTL_STG table';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg||'-' || lc_update_extprice_cr_ndt );
              EXCEPTION
              WHEN OTHERS THEN
                lc_err_location_msg := 'Error While Executing Ext Price CR update in Detail Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
                XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_extprice_cr_ndt);
                p_dtl_error_flag := 'Y';
                p_dtl_error_msg  := lc_err_location_msg;
              END;
            END IF;
         --end Added by Aniket CG 15 May #NAIT-29364
            -- Start of Changes done by Punit CG for Requirement #2302 (I) on 17-MAR-2017
            IF (ln_nondt_qty IS NOT NULL AND(UPPER(lc_get_dist_record_type) = 'LINE')AND(lc_qty_ship_exists ='Y')) THEN -- Added on 21-JUN-2017
              BEGIN
                lc_update_nondt_qty_amt_cols := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET ' ||ln_nondt_qty_update || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' || p_cust_doc_id || ' AND file_id = ' || p_file_id || ' AND trx_line_number IS NULL AND rec_type IN (''TX'',''DL'',''MS'')' || ' AND REC_ORDER = '||ln_get_line_dist_rows -- Added by Punit on 17-AUG-2017 for Defect# 40174
                || ' AND trx_type = '||''''||lc_get_dist_record_type||'''';                                                                                                                                                                                                                                                            -- Added by Punit on 17-AUG-2017 for Defect# 40174
                EXECUTE IMMEDIATE lc_update_nondt_qty_amt_cols;
                lc_err_location_msg := 'Executed Qty Shipped Amount update in XX_AR_EBL_TXT_DTL_STG table';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg || '-' ||lc_update_nondt_qty_amt_cols );
              EXCEPTION
              WHEN OTHERS THEN
                lc_err_location_msg := 'Error While Updating the Qty Shipped Amount Column of Detail Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
                XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_nondt_qty_amt_cols);
                p_dtl_error_flag := 'Y';
                p_dtl_error_msg  := lc_err_location_msg;
              END;
            END IF;
          END IF;
          -- Start of changes done by Thilak CG for Defect #40174 and 14188 on 07-AUG-2017
          IF lc_dc_flag = 'Y' AND lc_dc_amt_col IS NOT NULL AND lc_dc_indicator_col IS NOT NULL THEN
            lc_dc_amt_decode    := 'DECODE(SIGN('||lc_dc_amt_col||'),''1'','||''''||lc_debit||''''||','||'''0'','||''''||lc_debit||''''||','||''''||lc_credit||''''||')';
            lc_dc_update_sql    := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET '||lc_dc_indicator_col||' = '||lc_dc_amt_decode||' WHERE rec_type != ''FID'' AND file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND rec_order = '||ln_get_line_dist_rows||' AND trx_type = '||''''||lc_get_dist_record_type||'''';
            lc_err_location_msg := 'Updated Detail DC Indicator Column: '||lc_dc_update_sql;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
            EXECUTE IMMEDIATE lc_dc_update_sql;
	     --start Added by Aniket CG 15 May #NAIT-29364
           ELSIF lc_dc_flag = 'Y' AND  ( lc_dc_amt_col_db IS NOT NULL OR lc_dc_amt_col_cr IS NOT NULL) AND lc_dc_indicator_col IS NOT NULL THEN
            IF lc_dc_flag = 'Y' AND  lc_dc_amt_col_db IS NOT NULL AND lc_dc_indicator_col IS NOT NULL THEN
            lc_dc_amt_decode_db    := 'DECODE(SIGN('||lc_dc_amt_col_db||'),''1'','||''''||lc_debit||''''||','||'''0'','||''''||lc_debit||''''||','||''''||lc_credit||''''||')';
            lc_dc_update_sql_db    := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET '||lc_dc_indicator_col||' = '||lc_dc_amt_decode_db||' WHERE rec_type != ''FID'' AND file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND rec_order = '||ln_get_line_dist_rows||'AND '|| lc_dc_amt_col_db ||' IS NOT NULL  AND trx_type = '||''''||lc_get_dist_record_type||'''';
            lc_err_location_msg := 'Updated Detail DB ORIG Indicator Column: '||lc_dc_update_sql_db;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
            EXECUTE IMMEDIATE lc_dc_update_sql_db;
            END IF;
            IF lc_dc_flag = 'Y' AND  lc_dc_amt_col_cr IS NOT NULL AND lc_dc_indicator_col IS NOT NULL THEN
            lc_dc_amt_decode_cr    := 'DECODE(SIGN('||lc_dc_amt_col_cr||'),''1'','||''''||lc_debit||''''||','||'''0'','||''''||lc_debit||''''||','||''''||lc_credit||''''||')';
            lc_dc_update_sql_cr    := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET '||lc_dc_indicator_col||' = '||lc_dc_amt_decode_cr||' WHERE rec_type != ''FID'' AND file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND rec_order = '||ln_get_line_dist_rows||'AND '|| lc_dc_amt_col_cr ||' IS NOT NULL  AND trx_type = '||''''||lc_get_dist_record_type||'''';
            lc_err_location_msg := 'Updated Detail CR ORIG Indicator Column: '||lc_dc_update_sql_cr;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
            EXECUTE IMMEDIATE lc_dc_update_sql_cr;
            END IF;
            --end Added by Aniket CG 15 May #NAIT-29364
          END IF;
          -- End
          -- Added by Punit CG for defect#40174 on 11-AUG-2017
          lc_dtl_sign_cols     := SUBSTR(lc_get_sign_amt_cols,1,LENGTH(lc_get_sign_amt_cols)-1);
          lc_sign_update_query := 'select a.str from (WITH DATA AS
									( SELECT ' ||''''||lc_dtl_sign_cols||''''|| ' str FROM dual
									)
									SELECT trim(regexp_substr(str, ''[^,]+'', 1, LEVEL)) str
									FROM DATA
									CONNECT BY instr(str, '','', 1, LEVEL - 1) > 0) a';
          lc_err_location_msg := 'Value of lc_sign_update_query is '||lc_sign_update_query;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
          -- Framing the SQL to update the Sign columns in detail staging table
          lc_dtl_upd_sign_query:= 'SELECT DISTINCT FILE_ID,CUST_DOC_ID,REC_ORDER
								   FROM XX_AR_EBL_TXT_DTL_STG
								   WHERE file_id = '||p_file_id ||' AND cust_doc_id = '||p_cust_doc_id ||' AND REC_TYPE != '||'''FID''' ||' AND trx_type = '||''''||lc_get_dist_record_type||'''' ||' AND REC_ORDER = '||ln_get_line_dist_rows;
          -- Open the Cursors and update the Sign columns
          lc_err_location_msg := 'Value of lc_abs_flag is '||lc_abs_flag||' and Value of ln_sign_update_cnt is '||ln_sign_update_cnt;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
          IF ((lc_abs_flag = 'Y') AND (ln_sign_update_cnt = 1)) THEN
            OPEN c_dtl_upd_sign_cursor FOR lc_dtl_upd_sign_query;
            LOOP
              FETCH c_dtl_upd_sign_cursor
              INTO ln_dtl_sign_file_id,
                ln_dtl_sign_cust_doc_id,
                ln_dtl_sign_rec_order;
              EXIT
            WHEN c_dtl_upd_sign_cursor%NOTFOUND;
              OPEN c_sign_row_cursor FOR lc_sign_update_query;
              LOOP
                FETCH c_sign_row_cursor INTO lc_row_sign_col;
                EXIT
              WHEN c_sign_row_cursor%NOTFOUND;
                ln_sign_col_str     := NULL;
                lc_sign_col_decode  := NULL;
                BEGIN
                  IF lc_amt_sign_flag = 'Y' THEN
                    SELECT TO_NUMBER(SUBSTR(lc_row_sign_col,INSTR(lc_row_sign_col,'n')+1))-1
                    INTO ln_sign_col_str
                    FROM DUAL;
                  ELSIF lc_sign_flag = 'Y' THEN
                    SELECT TO_NUMBER(SUBSTR(lc_row_sign_col,INSTR(lc_row_sign_col,'n')+1))+1
                    INTO ln_sign_col_str
                    FROM DUAL;
                  END IF;
                EXCEPTION
                WHEN OTHERS THEN
                  lc_err_location_msg := 'Error While Selecting the Sign Columns Number : ' || SQLCODE || ' - ' || SQLERRM;
                  XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || ln_sign_col_str);
                  p_dtl_error_flag := 'Y';
                  p_dtl_error_msg  := lc_err_location_msg;
                END;
                BEGIN
                  IF ln_sign_col_str    IS NOT NULL THEN
                    ln_sign_col_cnt     := 0;
                    lc_sign_amt_field_id := NULL;
                    EXECUTE IMMEDIATE 'SELECT '||lc_column||ln_sign_col_str|| ' FROM  XX_AR_EBL_TXT_DTL_STG' ||' WHERE file_id = '||p_file_id ||' AND cust_doc_id = '||p_cust_doc_id ||' AND REC_TYPE = '||'''FID''' ||' AND trx_type = '||''''||lc_get_dist_record_type||'''' ||' AND REC_ORDER = '||ln_get_line_dist_rows INTO lc_sign_amt_field_id;
                    lc_err_location_msg := 'Selected Field iD value '||lc_sign_amt_field_id;
                    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
                    SELECT COUNT(flv.lookup_code)
                    INTO ln_sign_col_cnt
                    FROM fnd_lookup_values_vl FLV
                    WHERE FLV.lookup_type      = 'XX_AR_EBL_TXT_DTL_SIGN_COLS'
                    AND UPPER(flv.lookup_code) = UPPER(
                      (SELECT DISTINCT xftv.source_value4
                      FROM Xx_Fin_Translatedefinition Xftd ,
                        Xx_Fin_Translatevalues Xftv
                      WHERE xftd.translate_id   = xftv.translate_id
                      AND Xftv.Source_Value1    = lc_sign_amt_field_id
                      AND xftd.translation_name ='XX_CDH_EBL_TXT_DET_FIELDS'
                      AND Xftv.Enabled_Flag     ='Y'
                      AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
                      ))
                    AND FLV.enabled_flag = 'Y'
                    AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
                  END IF;
                EXCEPTION
                WHEN OTHERS THEN
                  lc_err_location_msg := 'Error while selecting the mapping SIGN column from the lookup XX_AR_EBL_TXT_DTL_SIGN_COLS';
                  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
                  p_dtl_error_flag := 'Y';
                  p_dtl_error_msg  := lc_err_location_msg;
                END;
                BEGIN
                  IF ln_sign_col_cnt     = 1 THEN
                    --    ln_sign_col_str    :=  'SUBSTR('||lc_row_sign_col||',INSTR('||lc_row_sign_col||',''N'')+1)'||ln_amtsign_val;
                    lc_sign_col_decode      := 'DECODE(SIGN('||lc_column||ln_sign_col_str||'),''1'',''+'',''-1'',''-'','''')';
                    lc_update_sign_amt_cols := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET ' ||lc_row_sign_col ||' = '||lc_sign_col_decode ||' WHERE file_id = '||p_file_id ||' AND cust_doc_id = '||p_cust_doc_id ||' AND REC_TYPE != '||'''FID''' ||' AND trx_type = '||''''||lc_get_dist_record_type||'''' ||' AND REC_ORDER = '||ln_get_line_dist_rows;
                    EXECUTE IMMEDIATE lc_update_sign_amt_cols;
                    lc_err_location_msg := 'Executed Sign Column updates in XX_AR_EBL_TXT_DTL_STG table';
                    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg|| '-' ||lc_update_sign_amt_cols );
                  END IF;
                EXCEPTION
                WHEN OTHERS THEN
                  lc_err_location_msg := 'Error While Updating the Sign Columns of Detail Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
                  XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_sign_amt_cols);
                  p_dtl_error_flag := 'Y';
                  p_dtl_error_msg  := lc_err_location_msg;
                END;
              END LOOP;
            END LOOP;
          END IF;
          -- End of Added by Punit CG for defect#40174 on 11-AUG-2017
          -- Added by Thilak CG for defect#40174 on 08-AUG-2017
          lc_err_location_msg := 'Value of lc_abs_flag is '||lc_abs_flag||' and Value of ln_abs_update_cnt is '||ln_abs_update_cnt;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg|| '-' ||lc_update_abs_amt_cols );
          IF ((lc_abs_flag          = 'Y') AND (ln_abs_update_cnt = 1)) THEN
            lc_update_abs_amt_cols := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET' || SUBSTR(lc_get_abs_amt_cols,1,LENGTH(lc_get_abs_amt_cols)-1) || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' || p_cust_doc_id || ' AND file_id = ' || p_file_id ||' AND REC_ORDER = '||ln_get_line_dist_rows || ' AND trx_type = '||''''||lc_get_dist_record_type||'''';
            BEGIN
              EXECUTE IMMEDIATE lc_update_abs_amt_cols;
              lc_err_location_msg := 'Executed Absolute Amount update in XX_AR_EBL_TXT_DTL_STG table';
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg|| '-' ||lc_update_abs_amt_cols );
            EXCEPTION
            WHEN OTHERS THEN
              lc_err_location_msg := 'Error While Updating the Absolute Amount Columns of Detail Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_abs_amt_cols);
              p_dtl_error_flag := 'Y';
              p_dtl_error_msg  := lc_err_location_msg;
            END;
          END IF;
          -- End
          -- End of Changes done by Punit for Requirement #2302 (A,G,H) on 08-FEB-2017
        END LOOP;
        CLOSE get_dist_record_type;
        -- Start of Changes done by Punit for Requirement #2302 (A,G,H) on 08-FEB-2017
        IF lc_seq_num_exists   = 'Y' THEN
          lc_err_location_msg := 'Sequence Number Column Exists. So Calling procedure to update it by incrementing it by 1 in STG table.';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
          --Call the function to Update sequence Number value by incrementing 1
          xx_ar_ebl_txt_update_seq_num(p_file_id, p_cust_doc_id, lc_seq_num_col, ln_seq_num_fid, p_org_id, p_debug_flag, p_dtl_error_flag);
          IF p_dtl_error_flag != 'Y' THEN
            p_dtl_error_flag  := 'N';
          END IF;
        END IF;
        IF lc_dist_seq_num_exists = 'Y' THEN
          lc_err_location_msg    := 'Dist Sequence Number Column Exists. So Calling procedure to update dist line by incrementing it by 1 in STG table.';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
          --Call the function to Update sequence Number value by incrementing 1
          xx_ar_ebl_txt_update_dist_num(p_file_id, p_cust_doc_id, lc_dist_seq_num_col, ln_dist_seq_num_fid, p_org_id, p_debug_flag, p_dtl_error_flag);
          IF p_dtl_error_flag != 'Y' THEN
            p_dtl_error_flag  := 'N';
          END IF;
        END IF;
        -- Updating the Line Number in the Detail Staging table.
        IF lc_print_hdr_line_num = 'Y' OR lc_print_line_line_num = 'Y' OR lc_print_dist_line_num = 'Y' THEN
          -- Added by Thilak CG on 25-JUL-2017 for Defect#42380
          lc_hdr_line_num_cols     := SUBSTR(lc_hdr_line_num_col,1,(LENGTH(lc_hdr_line_num_col)-1));
          lc_hdr_stg_update_query  := 'select a.str from (WITH DATA AS
										( SELECT ' ||''''||lc_hdr_line_num_cols||''''|| ' str FROM dual
										)
										SELECT trim(regexp_substr(str, ''[^,]+'', 1, LEVEL)) str
										FROM DATA
										CONNECT BY instr(str, '','', 1, LEVEL - 1) > 0) a';
          lc_line_line_num_cols    := SUBSTR(lc_line_line_num_col,1,(LENGTH(lc_line_line_num_col)-1));
          lc_line_stg_update_query := 'select a.str from (WITH DATA AS
										( SELECT ' ||''''||lc_line_line_num_cols||''''|| ' str FROM dual
										)
										SELECT trim(regexp_substr(str, ''[^,]+'', 1, LEVEL)) str
										FROM DATA
										CONNECT BY instr(str, '','', 1, LEVEL - 1) > 0) a';
          lc_dist_line_num_cols    := SUBSTR(lc_dist_line_num_col,1,(LENGTH(lc_dist_line_num_col)-1));
          lc_dist_stg_update_query := 'select a.str from (WITH DATA AS
										( SELECT ' ||''''||lc_dist_line_num_cols||''''|| ' str FROM dual
										)
										SELECT trim(regexp_substr(str, ''[^,]+'', 1, LEVEL)) str
										FROM DATA
										CONNECT BY instr(str, '','', 1, LEVEL - 1) > 0) a';
          -- End
          -- Added and Commented by Punit on 12-JUL-2017 for Defect # 41307
          --ln_get_line_dist_rows := NULL;
          /*OPEN get_dist_rows;
          LOOP
          FETCH get_dist_rows INTO ln_get_line_dist_rows;
          EXIT
          WHEN get_dist_rows%NOTFOUND;*/
          lc_get_dist_record_type := NULL;
          OPEN get_dist_record_type(ln_get_line_dist_rows);
          LOOP
            FETCH get_dist_record_type INTO lc_get_dist_record_type;
            EXIT
          WHEN get_dist_record_type%NOTFOUND;
            -- End of Added and Commented by Punit on 12-JUL-2017 for Requirement # 9
            -- Framing the SQL to update the line number in the staging table
            IF lc_get_dist_record_type = 'HDR' THEN
            --  lc_hdr_sort_columns     := xx_ar_ebl_render_txt_pkg.get_sort_columns(p_cust_doc_id,lc_get_dist_record_type);
              lc_hdr_stg_query        := 'SELECT STG_ID, CUSTOMER_TRX_ID FROM XX_AR_EBL_TXT_DTL_STG WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_TYPE != '||'''FID'''||' AND TRX_TYPE = '||''''||lc_get_dist_record_type||''''||' ORDER BY '||lc_hdr_sort_columns||' CUSTOMER_TRX_ID, trx_line_number,STG_ID';
              lc_err_location_msg     := 'Staging table Query for Header '||lc_hdr_stg_query;
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
            ELSIF lc_get_dist_record_type = 'LINE' THEN
            --  lc_line_sort_columns       := xx_ar_ebl_render_txt_pkg.get_sort_columns(p_cust_doc_id,lc_get_dist_record_type);
              lc_line_stg_query          := 'SELECT STG_ID, CUSTOMER_TRX_ID, CUSTOMER_TRX_LINE_ID FROM XX_AR_EBL_TXT_DTL_STG WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_TYPE != '||'''FID'''||' AND TRX_TYPE = '||''''||lc_get_dist_record_type||''''||' AND customer_trx_id=nvl(:pcustomer_trx_id,customer_trx_id)'||' ORDER BY '||lc_line_sort_columns||' CUSTOMER_TRX_ID, trx_line_number, STG_ID';
         -- Start Commented by Thilak CG on 01-MAR-2018 for Defect#29739
		    /*IF lc_target_value3         = 'Y' THEN
                lc_line_stg_query        := 'SELECT STG_ID, CUSTOMER_TRX_ID, CUSTOMER_TRX_LINE_ID FROM XX_AR_EBL_TXT_DTL_STG WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_TYPE != '||'''FID'''||' AND REC_TYPE = '||'''DT'''||' AND TRX_TYPE = '||''''||lc_get_dist_record_type||''''||' AND customer_trx_id=nvl(:pcustomer_trx_id,customer_trx_id)'||' ORDER BY '||lc_line_sort_columns||' CUSTOMER_TRX_ID, trx_line_number, STG_ID';
              END IF;*/
		 -- End
              lc_err_location_msg := 'Staging table Query for Line'||lc_line_stg_query;
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
            ELSIF lc_get_dist_record_type = 'DIST' THEN
            --  lc_dist_line_sort_columns  := xx_ar_ebl_render_txt_pkg.get_sort_columns(p_cust_doc_id,lc_get_dist_record_type);
              lc_dist_stg_query          := 'SELECT STG_ID FROM XX_AR_EBL_TXT_DTL_STG WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_TYPE != '||'''FID'''||' AND TRX_TYPE = '||''''||lc_get_dist_record_type||''''||' AND customer_trx_id=nvl(:pcustomer_trx_id,customer_trx_id)'||' AND customer_trx_line_id=:pcustomer_trx_line_id'||' ORDER BY '||lc_dist_line_sort_columns||' trx_line_number, STG_ID';
              lc_err_location_msg        := 'Staging table Query for Dist Line'||lc_dist_stg_query;
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
            END IF;
          END LOOP;
          CLOSE get_dist_record_type;
          -- Added by Punit on 12-JUL-2017 for Defect# 41307
          --END LOOP;
          --CLOSE get_dist_rows;
          -- End of Added by Punit on 12-JUL-2017 for Defect# 41307
          -- Open the Cursors and update the sequence number
          ln_hdr_line_num := 0;
		  ln_hdr_line_num_max := 0;
          -- Changes for the defect#42322
          SELECT NVL(MAX(ROWNUMBER),ln_hdr_line_num)
          INTO ln_hdr_line_num_max
          FROM XX_CDH_EBL_TEMPL_HDR_TXT
          WHERE CUST_DOC_ID = p_cust_doc_id;

          SELECT COUNT (DISTINCT xftv.source_value4)
          INTO ln_hdr_line_num
          FROM xx_fin_translatedefinition xftd ,
            xx_fin_translatevalues XFTV ,
            xx_cdh_ebl_templ_hdr_txt xcetht
          WHERE xftd.translate_id   = xftv.translate_id
          AND xftd.translation_name = 'XX_CDH_EBL_TXT_HDR_FIELDS'
          AND XFTV.ENABLED_FLAG     = 'Y'
          AND TRUNC(sysdate) BETWEEN TRUNC(XFTV.START_DATE_ACTIVE) AND TRUNC(NVL(XFTV.END_DATE_ACTIVE,sysdate+1))
          AND XFTV.SOURCE_VALUE1 = XCETHT.FIELD_ID
          AND XCETHT.ATTRIBUTE20 = 'Y'
          AND XCETHT.CUST_DOC_ID = p_cust_doc_id
          AND xftv.source_value4 IN
            (SELECT xftv.source_value1
            FROM xx_fin_translatedefinition xftd ,
              xx_fin_translatevalues XFTV
            WHERE xftd.translate_id   = xftv.translate_id
            AND xftd.translation_name = 'XX_AR_EBL_TXT_LINE_NUM'
            AND XFTV.ENABLED_FLAG     = 'Y'
            AND TRUNC(sysdate) BETWEEN TRUNC(XFTV.START_DATE_ACTIVE) AND TRUNC(NVL(XFTV.END_DATE_ACTIVE,sysdate+1))
            );

          IF ln_hdr_line_num_max > 1 AND ln_hdr_line_num = 1
          THEN
		   ln_hdr_line_num := ln_hdr_line_num_max;
          END IF;

          IF lc_hdr_stg_query IS NULL THEN
            lc_hdr_stg_query  := 'SELECT NULL, NULL FROM DUAL';
          END IF;
          OPEN c_hdr_stg_cursor FOR lc_hdr_stg_query; -- hdr cursor.
          LOOP
            FETCH c_hdr_stg_cursor INTO ln_stg_id, ln_customer_trx_id;
            EXIT
          WHEN c_hdr_stg_cursor%NOTFOUND;
            IF ln_stg_id      IS NOT NULL AND lc_print_hdr_line_num = 'Y' AND lc_hdr_line_num_cols IS NOT NULL THEN
              ln_hdr_line_num := NVL(ln_hdr_line_num,0) + 1;
              -- Added by Thilak CG on 25-JUL-2017 for Defect#42380
              OPEN c_hdr_stg_row_cursor FOR lc_hdr_stg_update_query;
              LOOP
                FETCH c_hdr_stg_row_cursor INTO lc_hdr_row_seq_col;
                EXIT
              WHEN c_hdr_stg_row_cursor%NOTFOUND;
                lc_update_hdr_sql   := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET '||lc_hdr_row_seq_col||' = '||ln_hdr_line_num||' WHERE STG_ID = '||ln_stg_id;
                lc_err_location_msg := 'HDR sql '||lc_update_hdr_sql;
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg);
                EXECUTE IMMEDIATE lc_update_hdr_sql;
              END LOOP;
              -- End
              IF lc_target_value3 = 'Y' THEN
                ln_line_line_num := 0;
              END IF;
            END IF;
            IF lc_line_stg_query IS NOT NULL AND lc_line_line_num_cols IS NOT NULL THEN
              ln_previous_trx_id := NULL;
              ln_current_trx_id  := NULL;
              OPEN c_line_stg_cursor FOR lc_line_stg_query USING ln_customer_trx_id; -- line cursor.
              LOOP
                FETCH c_line_stg_cursor
                INTO ln_stg_id,
                  ln_customer_trx_id,
                  ln_customer_trx_line_id;
                EXIT
              WHEN c_line_stg_cursor%NOTFOUND;
                IF lc_print_line_line_num = 'Y' THEN
                  IF lc_target_value1     = 'Y' THEN
                    ln_hdr_line_num      := ln_hdr_line_num + 1;
                    -- Added by Thilak CG on 25-JUL-2017 for Defect#42380
                    OPEN c_line_stg_row_cursor FOR lc_line_stg_update_query;
                    LOOP
                      FETCH c_line_stg_row_cursor INTO lc_line_row_seq_col;
                      EXIT
                    WHEN c_line_stg_row_cursor%NOTFOUND;
                      lc_update_line_sql  := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET '||lc_line_row_seq_col||' = '||ln_hdr_line_num||' WHERE STG_ID = '||ln_stg_id;
                      lc_err_location_msg := 'Updated Line Row Numbering Value 1 in Detail Procedure Column: '||lc_update_line_sql;
                      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
                      EXECUTE IMMEDIATE lc_update_line_sql;
                    END LOOP;
                    -- End
                  ELSIF lc_target_value2     = 'Y' THEN
                    ln_current_trx_id       := ln_customer_trx_id;
                    IF lc_print_hdr_line_num = 'N' AND NVL(ln_current_trx_id,0) != NVL(ln_previous_trx_id,0) THEN
                      ln_hdr_line_num       := NVL(ln_hdr_line_num,0) + 1;
                    END IF;
                    -- Added by Thilak CG on 25-JUL-2017 for Defect#42380
                    OPEN c_line_stg_row_cursor FOR lc_line_stg_update_query;
                    LOOP
                      FETCH c_line_stg_row_cursor INTO lc_line_row_seq_col;
                      EXIT
                    WHEN c_line_stg_row_cursor%NOTFOUND;
                      lc_update_line_sql  := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET '||lc_line_row_seq_col||' = '||ln_hdr_line_num||' WHERE STG_ID = '||ln_stg_id;
                      lc_err_location_msg := 'Updated Line Row Numbering Value 2 in Detail Procedure Column: '||lc_update_line_sql;
                      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
                      EXECUTE IMMEDIATE lc_update_line_sql;
                    END LOOP;
                    -- End
                  ELSIF lc_target_value3     = 'Y' THEN
                    ln_current_trx_id       := ln_customer_trx_id;
                    IF lc_print_hdr_line_num = 'N' AND NVL(ln_current_trx_id,0) != NVL(ln_previous_trx_id,0) THEN
                      ln_line_line_num      := 0;
                    END IF;
                    ln_line_line_num := NVL(ln_line_line_num,0) + 1;
                    -- Added by Thilak CG on 25-JUL-2017 for Defect#42380
                    OPEN c_line_stg_row_cursor FOR lc_line_stg_update_query;
                    LOOP
                      FETCH c_line_stg_row_cursor INTO lc_line_row_seq_col;
                      EXIT
                    WHEN c_line_stg_row_cursor%NOTFOUND;
                      lc_update_line_sql  := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET '||lc_line_row_seq_col||' = '||ln_line_line_num||' WHERE STG_ID = '||ln_stg_id;
                      lc_err_location_msg := 'Updated Line Row Numbering Value 3 in Detail Procedure Column: '||lc_update_line_sql;
                      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
                      EXECUTE IMMEDIATE lc_update_line_sql;
                    END LOOP;
                    -- End
                  END IF;
                  lc_err_location_msg := 'LINE sql '||lc_update_line_sql;
                  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg);
                  ln_previous_trx_id := ln_customer_trx_id;
                END IF;
                IF lc_dist_stg_query IS NOT NULL AND lc_dist_line_num_cols IS NOT NULL THEN
                  OPEN c_dist_line_stg_cursor FOR lc_dist_stg_query USING ln_customer_trx_id,
                  ln_customer_trx_line_id; -- dist line cursor.
                  LOOP
                    FETCH c_dist_line_stg_cursor INTO ln_stg_id;
                    EXIT
                  WHEN c_dist_line_stg_cursor%NOTFOUND;
                    IF lc_print_dist_line_num = 'Y' THEN
                      IF lc_target_value1     = 'Y' THEN
                        ln_hdr_line_num      := ln_hdr_line_num + 1;
                        -- Added by Thilak CG on 25-JUL-2017 for Defect#42380
                        OPEN c_dist_stg_row_cursor FOR lc_dist_stg_update_query;
                        LOOP
                          FETCH c_dist_stg_row_cursor INTO lc_dist_row_seq_col;
                          EXIT
                        WHEN c_dist_stg_row_cursor%NOTFOUND;
                          lc_update_dist_line_sql := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET '||lc_dist_row_seq_col||' = '||ln_hdr_line_num||' WHERE STG_ID = '||ln_stg_id;
                          lc_err_location_msg     := 'Updated Dist Row Numbering Value 1 in Detail Procedure Column: '||lc_update_dist_line_sql;
                          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
                          EXECUTE IMMEDIATE lc_update_dist_line_sql;
                        END LOOP;
                        -- End
                      ELSIF lc_target_value2 = 'Y' THEN
                        -- Added by Thilak CG on 25-JUL-2017 for Defect#42380
                        OPEN c_dist_stg_row_cursor FOR lc_dist_stg_update_query;
                        LOOP
                          FETCH c_dist_stg_row_cursor INTO lc_dist_row_seq_col;
                          EXIT
                        WHEN c_dist_stg_row_cursor%NOTFOUND;
                          lc_update_dist_line_sql := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET '||lc_dist_row_seq_col||' = '||ln_hdr_line_num||' WHERE STG_ID = '||ln_stg_id;
                          lc_err_location_msg     := 'Updated Dist Row Numbering Value 2 in Detail Procedure Column: '||lc_update_dist_line_sql;
                          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
                          EXECUTE IMMEDIATE lc_update_dist_line_sql;
                        END LOOP;
                        -- End
                      ELSIF lc_target_value3 = 'Y' THEN
                        ln_line_line_num    := NVL(ln_line_line_num,0) + 1;
                        -- Added by Thilak CG on 25-JUL-2017 for Defect#42380
                        OPEN c_dist_stg_row_cursor FOR lc_dist_stg_update_query;
                        LOOP
                          FETCH c_dist_stg_row_cursor INTO lc_dist_row_seq_col;
                          EXIT
                        WHEN c_dist_stg_row_cursor%NOTFOUND;
                          lc_update_dist_line_sql := 'UPDATE XX_AR_EBL_TXT_DTL_STG SET '||lc_dist_row_seq_col||' = '||ln_line_line_num||' WHERE STG_ID = '||ln_stg_id;
                          lc_err_location_msg     := 'Updated Dist Row Numbering Value 3 in Detail Procedure Column: '||lc_update_dist_line_sql;
                          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
                          EXECUTE IMMEDIATE lc_update_dist_line_sql;
                        END LOOP;
                        -- End
                      END IF;
                      lc_err_location_msg := 'DIST sql '||lc_update_dist_line_sql;
                      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg);
                    END IF;
                  END LOOP; -- Dist Lines
                END IF;
              END LOOP; -- Lines
            END IF;
          END LOOP; -- Header Lines
        END IF;
        --- Added by Punit on 12-JUL-2017 for Defect# 41307
      END LOOP;
      CLOSE get_dist_rows;
      --End of Added by Punit on 12-JUL-2017 for Defect# 41307
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    lc_err_location_msg := 'Error While Inserting the data into Detail Staging Table : '||SQLCODE||' - '||SQLERRM;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
    p_dtl_error_flag := 'Y';
    p_dtl_error_msg  := lc_err_location_msg;
  END PROCESS_TXT_DTL_DATA;
  -- +===========================================================================================+
  -- |                  Office Depot - Project Simplify                                          |
  -- +===========================================================================================+
  -- | Name        : PROCESS_TXT_TRL_DATA                                                        |
  -- | Description : This Procedure is used for to framing the dynamic query to fetch data       |
  -- |               from the configuration trailer table and to poplate the                     |
  -- |               trl txt stagging table                                                      |
  -- |Parameters   : p_batch_id                                                                  |
  -- |             , p_cust_doc_id                                                               |
  -- |             , p_file_id                                                                   |
  -- |             , p_cycle_date                                                                |
  -- |             , p_org_id                                                                    |
  -- |             , p_debug_flag                                                                |
  -- |             , p_error_flag                                                                |
  -- |                                                                                           |
  -- |Change Record:                                                                             |
  -- |===============                                                                            |
  -- |Version   Date          Author                 Remarks                                     |
  -- |=======   ==========   =============           ============================================|
  -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                       |
  -- |      1.1 25-MAY-2017  Punit Gupta CG          Changes done for  Defect #42226             |
  -- |      1.2 11-AUG-2017  Punit Gupta CG          Changes done for  Defect #40174             |
  -- |      1.3 15-DEC-2017  Aniket                  Changes for Defect #22772                   |
  -- |      1.4 15-May-2018  Aniket J    CG         Changes for Requirement  #NAIT-29364         |
  -- +===========================================================================================+
PROCEDURE PROCESS_TXT_TRL_DATA(
    p_batch_id    IN NUMBER ,
    p_cust_doc_id IN NUMBER ,
    p_file_id     IN NUMBER ,
    p_cycle_date  IN VARCHAR2 ,
    p_org_id      IN NUMBER ,
    p_debug_flag  IN VARCHAR2 ,
    p_cmb_splt_whr   IN VARCHAR2 , --Added by Aniket CG #22772 on 15 Dec 2017
    p_cmb_splt_splfunc_whr IN VARCHAR2 , --Added by Aniket CG #22772 on 15 Dec 2017
    p_trl_error_flag OUT VARCHAR2 ,
    p_trl_error_msg OUT VARCHAR2)
IS
  CURSOR get_dist_rows
  IS
    SELECT DISTINCT rownumber
    FROM xx_cdh_ebl_templ_trl_txt
    WHERE cust_doc_id = p_cust_doc_id
      --AND attribute1 = 'Y'
    AND attribute20 = 'Y'
    ORDER BY rownumber;
  ln_get_dist_rows NUMBER;
  CURSOR c_get_trailer_fields_info(p_rownum IN NUMBER)
  IS
    SELECT to_number(xftv.source_value1) field_id ,
      xftv.target_value20 tab_name ,
      xftv.source_value4 col_name ,
      xcetht.seq ,
      xcetht.label ,
      xcetht.constant_value cons_val ,
      xftv.target_value14 spl_fields ,
      xftv.target_value1 data_type ,
      xftv.target_value19 rec_type ,
      xcetht.cust_doc_id ,
      'TRAILER' trx_type ,
      xftv.target_value24 spl_function ,
      xcetht.rownumber rec_order,
      -- Added by Thilak CG for Defect#40174 on 07-AUG-2017
      xcetht.absolute_flag,
      xcetht.dc_indicator,
		-- End
		--Added by Aniket CG 15 May #NAIT-29364
		xcetht.db_cr_seperator
		--Added by Aniket CG 15 May #NAIT-29364
    FROM xx_fin_translatedefinition xftd ,
      xx_fin_translatevalues xftv ,
      xx_cdh_ebl_templ_trl_txt xcetht
    WHERE xftd.translate_id   = xftv.translate_id
    AND xftv.source_value1    = xcetht.field_id
    AND xcetht.cust_doc_id    = p_cust_doc_id
    AND xcetht.rownumber      = p_rownum
    AND xftd.translation_name ='XX_CDH_EBL_TXT_TRL_FIELDS'
    AND xftv.target_value19   = 'DT' -- Uncommented by Punit on 25-MAY-2017
    AND xftv.enabled_flag     ='Y'
    AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
      --AND xcetht.attribute1 = 'Y'
    AND xcetht.attribute20 = 'Y'
  UNION
  SELECT xcetht.FIELD_ID ,
    'Concatenate' tab_name
    --,NULL col_name
    ,
    get_conc_field_names(xcetht.cust_doc_id, xcecft.conc_field_id, 'TRL', NULL, p_debug_flag, p_file_id) ,
    xcetht.seq ,
    xcetht.label ,
    NULL cons_val ,
    NULL spl_fields ,
    'VARCHAR2' data_type ,
    'DT' rec_type ,
    xcetht.cust_doc_id ,
    'TRAILER' trx_type ,
    NULL ,
    xcetht.rownumber rec_order,
    -- Added by Thilak CG for Defect#40174 on 07-AUG-2017
    xcetht.absolute_flag,
    xcetht.dc_indicator ,
    -- End
	--Added by Aniket CG 15 May #NAIT-29364
    xcetht.db_cr_seperator
    --Added by Aniket CG 15 May #NAIT-29364
  FROM xx_cdh_ebl_templ_trl_txt xcetht ,
    xx_cdh_ebl_concat_fields_txt xcecft
  WHERE xcetht.field_id  = xcecft.conc_field_id
  AND xcetht.cust_doc_id = xcecft.cust_doc_id
  AND xcetht.cust_doc_id = p_cust_doc_id
  AND xcetht.rownumber   = p_rownum
  AND xcecft.tab         = 'T'
  ORDER BY rec_order,
    seq;
  lc_from_cons_hdr      CONSTANT VARCHAR2(32767) := ' FROM xx_ar_ebl_cons_hdr_main hdr WHERE hdr.cust_doc_id = '||p_cust_doc_id||' AND hdr.file_id = '||p_file_id||' AND hdr.org_id = '||p_org_id;
  lc_select_cons_hdr    CONSTANT VARCHAR2(32767) := ' (SELECT XX_AR_EBL_TXT_STG_ID_S.nextval,hdr.parent_cust_doc_id,hdr.file_id,fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,';
  lc_insert_const_cols  CONSTANT VARCHAR2(32767) := 'INSERT INTO xx_ar_ebl_txt_trl_stg (stg_id,cust_doc_id,file_id,created_by,creation_date,last_updated_by,last_update_date,last_update_login,trx_type,rec_type,rec_order,cycle_date,batch_id,';
  lc_column             VARCHAR2(100)             := 'column';
  lc_select_var_cols    VARCHAR2(32767);
  lc_insert_col_name    VARCHAR2(32767);
  ln_count              NUMBER := 1;
  lc_hdr_value_fid      VARCHAR2(32767);
  lc_function           VARCHAR2(32767);
  lc_function_return    VARCHAR2(32767);
  lc_err_location_msg   VARCHAR2(32767);
  lb_debug_flag         BOOLEAN;
  lc_trl_col            VARCHAR2(2000);
  lc_trl_target_value1  VARCHAR2(1);
  lc_trl_target_value2  VARCHAR2(1);
  lc_trl_target_value3  VARCHAR2(1);
  lc_trl_print_line_num VARCHAR2(1);
  lc_trl_stg_query      VARCHAR2(32767);
  TYPE lc_ref_cursor
  IS
  REF
  CURSOR;
    c_trl_stg_cursor lc_ref_cursor;
    lc_trl_update_sql   VARCHAR2(32767);
    ln_trl_file_id      VARCHAR2(15);
    ln_trl_cust_doc_id  VARCHAR2(15);
    ln_trl_rec_order    VARCHAR2(10);
    ln_trl_line_num     NUMBER := 0;
	  ln_hdr_trl_num_max  NUMBER;
    ln_hdr_line_count   NUMBER;
    ln_dtl_line_count   NUMBER;
    ln_stg_id           NUMBER;
    lc_trl_cols         VARCHAR2(2000);
    lc_row_seq_col      VARCHAR2(1000);
    lc_stg_update_query VARCHAR2(32767);
    c_stg_row_cursor lc_ref_cursor;
    -- Below variables added by Thilak 07-AUG-2017 for Defect#40174
    lc_get_abs_amt_cols    VARCHAR2(32767);
    lc_update_abs_amt_cols VARCHAR2(32767);
    ln_abs_cnt             NUMBER        := 0;
    ln_abs_update_cnt      NUMBER        := 0;
    lc_abs_flag            VARCHAR2(1)   := 'N';
    lc_dc_flag             VARCHAR2(1)   := 'N';
    lc_debit               VARCHAR2(15)  := NULL;
    lc_credit              VARCHAR2(15)  := NULL;
    lc_dc_amt_col          VARCHAR2(15)  := NULL;
    lc_dc_indicator_col    VARCHAR2(15)  := NULL;
    lc_dc_amt_decode       VARCHAR2(1000) := NULL;
    lc_dc_update_sql       VARCHAR2(32767);
    -- End
    -- Below variables added by Punit CG on 11-AUG-2017 for Defect#40174
    ln_sign_cnt             NUMBER := 0;
    lc_get_sign_amt_cols    VARCHAR2(32767);
    lc_update_sign_amt_cols VARCHAR2(32767);
    ln_sign_update_cnt      NUMBER         := 0;
    ln_sign_ind_flag        VARCHAR2(1)    := 'N';
    lc_amt_col_for_sign     VARCHAR2(15)   := NULL;
    lc_sign_col_decode      VARCHAR2(1500) := NULL;
    ln_sign_col_str         NUMBER         := NULL;
    lc_sign_flag            VARCHAR2(1)    := 'N';
    lc_amt_sign_flag        VARCHAR2(1)    := 'N';
    ln_sign_col_cnt         NUMBER         := 0;
    lc_sign_amt_field_id    VARCHAR2(15)   := NULL;
    lc_select_sign_amt_cols VARCHAR2(32767);
  TYPE lc_ref_cursor_trl
  IS
  REF
  CURSOR;
    c_trl_upd_sign_cursor lc_ref_cursor_trl;
    c_sign_row_cursor lc_ref_cursor_trl;
    c_trl_update_sql        VARCHAR2(32767);
    ln_trl_sign_file_id     VARCHAR2(15);
    ln_trl_sign_cust_doc_id VARCHAR2(15);
    ln_trl_sign_rec_order   VARCHAR2(10);
    lc_trl_sign_cols        VARCHAR2(2000);
    lc_row_sign_col         VARCHAR2(1000);
    lc_trl_upd_sign_query   VARCHAR2(32767);
    lc_sign_update_query    VARCHAR2(32767);
    -- End of Below variables added by Punit CG on 11-AUG-2017 for Defect#40174

  -- Start Added by Aniket CG 15 May #NAIT-29364
  lc_db_cr_nvl_value   VARCHAR2(10);
  lc_dc_col_orig_flgchk    VARCHAR2(15)  := 'N';
  lc_dc_amt_col_db          VARCHAR2(15)  :=  NULL;
  lc_dc_amt_col_cr          VARCHAR2(15)  :=  NULL;
  lc_dc_amt_decode_db       VARCHAR2(1000) := NULL;
  lc_dc_amt_decode_cr       VARCHAR2(1000) := NULL;
  lc_dc_update_sql_db       VARCHAR2(32767);
  lc_dc_update_sql_cr       VARCHAR2(32767);
  --end Added by Aniket CG 15 May #NAIT-29364

  BEGIN
    IF (p_debug_flag = 'Y') THEN
      lb_debug_flag := TRUE;
    ELSE
      lb_debug_flag := FALSE;
    END IF;
    lc_err_location_msg := 'Processing the Trailer Records... Cust Doc Id :' || p_cust_doc_id || ' File id ' || p_file_id || ' Extract Batch id ' || p_batch_id ;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
    lc_trl_print_line_num := 'N';
    OPEN get_dist_rows;
    LOOP
      FETCH get_dist_rows INTO ln_get_dist_rows;
    EXIT
  WHEN get_dist_rows%NOTFOUND;
    lc_trl_col           := NULL;
    ln_count             := 1;
    lc_hdr_value_fid     := NULL;
    lc_insert_col_name   := NULL;
    lc_select_var_cols   := NULL;
    lc_function          := NULL;
    ln_abs_cnt           := 0;
    ln_abs_update_cnt    := 0;
    lc_dc_flag           := 'N';
    lc_debit             := NULL;
    lc_credit            := NULL;
    lc_dc_amt_col        := NULL;
    lc_dc_amt_decode     := NULL;
    lc_dc_indicator_col  := NULL;
    lc_dc_update_sql     := NULL;
    lc_get_abs_amt_cols  := NULL;
    ln_sign_cnt          := 0;
    lc_get_sign_amt_cols := NULL;
    --ln_sign_update_cnt   := 0;
    ln_sign_ind_flag      := 'N';
    lc_amt_col_for_sign   := NULL;
    lc_sign_col_decode    := NULL;
    lc_trl_sign_cols      := NULL;
    lc_sign_update_query  := NULL;
    lc_trl_upd_sign_query := NULL;
    FOR lc_get_trailer_fields_info IN c_get_trailer_fields_info(ln_get_dist_rows)
    LOOP
      IF ln_count           = 1 THEN
        lc_select_var_cols := lc_select_cons_hdr||''''||lc_get_trailer_fields_info.trx_type||''''||','||''''||lc_get_trailer_fields_info.rec_type||''''||','||lc_get_trailer_fields_info.rec_order||',' ||'TO_DATE('||''''||p_cycle_date||''''||',''DD-MON-YY''),'||p_batch_id||',';
        lc_hdr_value_fid   := lc_hdr_value_fid||''''||lc_get_trailer_fields_info.trx_type||''''||','||'''FID'''||','||lc_get_trailer_fields_info.rec_order||',' ||'TO_DATE('||''''||p_cycle_date||''''||',''DD-MON-YY''),'||p_batch_id||',';
        lc_insert_col_name := lc_insert_const_cols;
      END IF;
      IF (LOWER(lc_get_trailer_fields_info.tab_name)    = 'header') THEN
        IF (UPPER(lc_get_trailer_fields_info.data_type) = 'DATE') THEN
          lc_select_var_cols                           := lc_select_var_cols || 'TO_CHAR(hdr.' || lc_get_trailer_fields_info.col_name || ',''YYYY-MM-DD''),';
        ELSE
          lc_select_var_cols := lc_select_var_cols||'hdr.'||lc_get_trailer_fields_info.col_name||',';
        END IF;
      ELSIF (LOWER(lc_get_trailer_fields_info.tab_name) = 'concatenate') THEN
        lc_select_var_cols                             := lc_select_var_cols||lc_get_trailer_fields_info.col_name||',';
      ELSIF (LOWER(lc_get_trailer_fields_info.tab_name) = 'constant') THEN
        lc_select_var_cols                             := lc_select_var_cols||''''||lc_get_trailer_fields_info.cons_val||''''||',';
      ELSIF (LOWER(lc_get_trailer_fields_info.tab_name) = 'function') THEN
        IF lc_get_trailer_fields_info.spl_function     IS NOT NULL THEN
        --lc_function                                  := 'SELECT '||lc_get_trailer_fields_info.spl_function||'('||p_cust_doc_id||','||p_file_id||','||p_org_id||','||''''||lc_get_trailer_fields_info.col_name||''''||') FROM DUAL'; -- comment added by Aniket CG #22772 on 15 Dec 2017
        -- start Added by Aniket CG #22772 on 15 Dec 2017
				IF upper(lc_get_trailer_fields_info.spl_function) IN ( 'XX_AR_EBL_TXT_SPL_LOGIC_PKG.GET_GRAND_TOTAL' , 'XX_AR_EBL_TXT_SPL_LOGIC_PKG.GET_GRAND_FREIGHT_AMT') AND p_cmb_splt_splfunc_whr IS NOT NULL THEN
				lc_function  := 'SELECT '||lc_get_trailer_fields_info.spl_function||'('||p_cust_doc_id||','||p_file_id||','||p_org_id||','||''''||lc_get_trailer_fields_info.col_name||''''||','|| p_cmb_splt_splfunc_whr || ') FROM DUAL';
				ELSE
				lc_function := 'SELECT '||lc_get_trailer_fields_info.spl_function||'('||p_cust_doc_id||','||p_file_id||','||p_org_id||','||''''||lc_get_trailer_fields_info.col_name||''''||') FROM DUAL';
				END IF;
         -- end Added by Aniket CG #22772 on 15 Dec 2017
          EXECUTE IMMEDIATE lc_function INTO lc_function_return;

				--Added by Aniket CG 15 May #NAIT-29364 lc_get_trailer_fields_info.db_cr_seperator IS NOT NULL  AND
				IF   UPPER(lc_get_trailer_fields_info.col_name) IN ('ORIG_INV_AMT_DB','ORIG_INV_AMT_CR')THEN
				  SELECT lc_get_trailer_fields_info.db_cr_seperator --,'NULL',NULL,lc_get_trailer_fields_info.db_cr_seperator)
				  INTO lc_db_cr_nvl_value
				  FROM DUAL;

				  lc_db_cr_nvl_value := nvl( lc_db_cr_nvl_value , 'NULL');

				  IF UPPER(lc_get_trailer_fields_info.col_name) IN ('ORIG_INV_AMT_DB') THEN
					lc_select_var_cols := lc_select_var_cols|| ' DECODE (SIGN ('|| lc_function_return || ') , 0,0,1 ,' || lc_function_return || ' ,'||lc_db_cr_nvl_value ||')'|| ',';
				  ELSIF UPPER(lc_get_trailer_fields_info.col_name) IN ('ORIG_INV_AMT_CR') THEN
					lc_select_var_cols := lc_select_var_cols|| ' DECODE (SIGN ('|| lc_function_return || ') ,-1 ,' || lc_function_return || ' ,'|| lc_db_cr_nvl_value || ')'|| ',';
				  END IF ;
				ELSE
				  lc_select_var_cols := lc_select_var_cols||lc_function_return||',';
				END IF;
				--Added by Aniket CG 15 May #NAIT-29364
          --lc_select_var_cols := lc_select_var_cols||lc_function_return||',';  -- Commented by Aniket CG 15 May #NAIT-29364
        ELSE
          lc_select_var_cols := lc_select_var_cols||'NULL'||',';
          -- Checking to print line number field is selected for the cust doc id.
          BEGIN
            SELECT xftv.target_value1,
              target_value2,
              target_value3
            INTO lc_trl_target_value1,
              lc_trl_target_value2,
              lc_trl_target_value3
            FROM xx_fin_translatedefinition xftd ,
              xx_fin_translatevalues xftv
            WHERE xftd.translate_id   = xftv.translate_id
            AND xftd.translation_name = 'XX_AR_EBL_TXT_LINE_NUM'
            AND xftv.enabled_flag     = 'Y'
            AND TRUNC(sysdate) BETWEEN TRUNC(XFTV.START_DATE_ACTIVE) AND TRUNC(NVL(XFTV.END_DATE_ACTIVE,SYSDATE+1))
            AND xftv.source_value1 = lc_get_trailer_fields_info.col_name;
            fnd_file.put_line(fnd_file.log,' Target Values '||lc_trl_target_value1||' - '||lc_trl_target_value2||' - '||lc_trl_target_value3);
            IF lc_trl_target_value1  = 'Y' OR lc_trl_target_value2 = 'Y' OR lc_trl_target_value3 = 'Y' THEN
              lc_trl_print_line_num := 'Y';
              lc_trl_col            := lc_trl_col || lc_column||ln_count || ','; -- Modified by Thilak CG on 25-JUL-2017 for Defect#42380
            END IF;
            lc_err_location_msg := ' Print Line Num '||lc_trl_print_line_num||' - Trailer Col '||lc_trl_col;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg);
          EXCEPTION
          WHEN OTHERS THEN
            lc_trl_target_value1 := 'N';
            lc_trl_target_value2 := 'N';
            lc_trl_target_value3 := 'N';
          END;
          -- End
        END IF;
      END IF;
      -- Start of changes done by Thilak CG for Defect #40174 on 07-AUG-2017
      IF (UPPER(lc_get_trailer_fields_info.dc_indicator) IS NOT NULL AND lc_dc_flag = 'N') THEN
        lc_dc_flag                                       := 'Y';
        lc_debit                                         := NULL;
        lc_credit                                        := NULL;
        BEGIN
          SELECT description,
            tag
          INTO lc_debit,
            lc_credit
          FROM fnd_lookup_values_vl FLV
          WHERE FLV.lookup_type  = 'XXOD_EBL_DEBIT_CREDIT_SIGN_IND'
          AND UPPER(flv.meaning) = UPPER(lc_get_trailer_fields_info.dc_indicator)
          AND FLV.enabled_flag   = 'Y'
          AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
        EXCEPTION
        WHEN OTHERS THEN
          lc_err_location_msg := 'Error during select mapping column from the lookup XXOD_EBL_DEBIT_CREDIT_SIGN_IND';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
          p_trl_error_flag := 'Y';
          p_trl_error_msg  := lc_err_location_msg;
        END;
      END IF;
      IF (UPPER(lc_get_trailer_fields_info.absolute_flag) = 'Y') THEN
        lc_abs_flag                                      := 'Y';
        ln_abs_cnt                                       := 0;
        BEGIN
          SELECT COUNT(flv.lookup_code)
          INTO ln_abs_cnt
          FROM fnd_lookup_values_vl FLV
          WHERE FLV.lookup_type      = 'XX_AR_EBL_TXT_HDR_ABS_COLS'
          AND UPPER(flv.lookup_code) = UPPER(lc_get_trailer_fields_info.col_name)
          AND FLV.enabled_flag       = 'Y'
          AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
        EXCEPTION
        WHEN OTHERS THEN
          lc_err_location_msg := 'Error during select mapping column for Trailer from the lookup XX_AR_EBL_TXT_HDR_ABS_COLS';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
          p_trl_error_flag := 'Y';
          p_trl_error_msg  := lc_err_location_msg;
        END;
        IF ln_abs_cnt          = 1 THEN
          lc_get_abs_amt_cols := lc_get_abs_amt_cols || ' ' || lc_column || ln_count || ' = ' ||'ABS('||lc_column || ln_count||')'||',';
          ln_abs_update_cnt   := 1;
        END IF;
      END IF;
      -- End of Changes done by Thilak CG for Defect #40174 on 07-AUG-2017
      -- Start of changes done by Thilak CG for Defect #40174 on 07-AUG-2017
      IF UPPER(lc_get_trailer_fields_info.col_name) = 'ORIGINAL_INVOICE_AMOUNT' THEN
        lc_dc_amt_col := lc_column||ln_count;
		--start Added by Aniket CG 15 May #NAIT-29364
          lc_dc_col_orig_flgchk                          := 'Y';
          ELSIF UPPER(lc_get_trailer_fields_info.col_name) = 'ORIG_INV_AMT_DB' THEN
            IF lc_dc_col_orig_flgchk                      = 'N' THEN
              lc_dc_amt_col_db                           := lc_column||ln_count;
            END IF;
          ELSIF UPPER(lc_get_trailer_fields_info.col_name) = 'ORIG_INV_AMT_CR' THEN
            IF lc_dc_col_orig_flgchk                      = 'N' THEN
              lc_dc_amt_col_cr                           := lc_column||ln_count;
            END IF;
            --end Added by Aniket CG 15 May #NAIT-29364
      END IF;

   	  IF UPPER(lc_get_trailer_fields_info.col_name) = 'DC_INDICATOR' THEN
		lc_dc_indicator_col := lc_column||ln_count;
	  END IF;
	  -- End
      -- Start of changes done by Punit CG for Defect #40174 on 11-AUG-2017
      BEGIN
        SELECT COUNT(flv.lookup_code)
        INTO ln_sign_cnt
        FROM fnd_lookup_values_vl FLV
        WHERE FLV.lookup_type      = 'XX_AR_EBL_TXT_TRL_SIGN_COLS'
        AND UPPER(flv.lookup_code) = UPPER(lc_get_trailer_fields_info.col_name)
        AND FLV.enabled_flag       = 'Y'
        AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
        IF (ln_sign_cnt     = 1 AND lc_sign_flag = 'N' AND lc_amt_sign_flag = 'N') THEN
          lc_amt_sign_flag := 'Y';
          -- lc_amt_col_for_sign := lc_column||ln_count;
          -- lc_sign_col_decode := 'DECODE(SIGN(' || lc_amt_col_for_sign || '),''1'',''+'',''-1'',''-'',''+'')';
          --lc_sign_col_decode := 'DECODE(SIGN('||lc_amt_col_for_sign||'),'||''1''||','||''+''||','||''-1''||','||''-''||','||''''||')';
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        lc_err_location_msg := 'Error while selecting the mapping SIGN column from the lookup XX_AR_EBL_TXT_TRL_SIGN_COLS';
        XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
        p_trl_error_flag := 'Y';
        p_trl_error_msg  := lc_err_location_msg;
      END;
      IF (UPPER(lc_get_trailer_fields_info.col_name) = 'SIGN') THEN
        lc_get_sign_amt_cols                        := lc_get_sign_amt_cols || ' ' || lc_column || ln_count ||',';
        ln_sign_update_cnt                          := 1;
      END IF;
      IF (lc_sign_flag = 'N' AND lc_amt_sign_flag = 'N' AND UPPER(lc_get_trailer_fields_info.col_name) = 'SIGN') THEN
        lc_sign_flag  := 'Y';
      END IF;
      -- End of changes done by Punit CG for Defect #40174 on 11-AUG-2017
      lc_insert_col_name := lc_insert_col_name||lc_column||ln_count||',';
      lc_hdr_value_fid   := lc_hdr_value_fid||lc_get_trailer_fields_info.field_id||',';
      ln_count           := ln_count + 1;
    END LOOP;
    lc_insert_col_name  := SUBSTR(lc_insert_col_name,1,LENGTH(lc_insert_col_name)                                                                                                                                                           -1)||')';
    lc_select_var_cols  := SUBSTR(lc_select_var_cols,1,LENGTH(lc_select_var_cols)                                                                                                                                                           -1)||lc_from_cons_hdr|| p_cmb_splt_whr || ')'; -- Added by Aniket CG #22772 on 15 Dec 2017
    lc_hdr_value_fid    := ' VALUES ('||xx_ar_ebl_txt_stg_id_s.nextval||','||p_cust_doc_id||','||p_file_id||',fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,'||SUBSTR(lc_hdr_value_fid,1,LENGTH(lc_hdr_value_fid)-1)||')';
    lc_err_location_msg := 'Select and Insert Statement for TRL record FID : '||lc_insert_col_name||lc_hdr_value_fid ;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
    lc_err_location_msg := 'Select and Insert Statement for TRL record DT : '||lc_insert_col_name||lc_hdr_value_fid ;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
    fnd_file.put_line(fnd_file.log,lc_insert_col_name||lc_hdr_value_fid);
    fnd_file.put_line(fnd_file.log,lc_insert_col_name||lc_select_var_cols);
    EXECUTE IMMEDIATE lc_insert_col_name||lc_hdr_value_fid;
    EXECUTE IMMEDIATE lc_insert_col_name||lc_select_var_cols;

       fnd_file.put_line(fnd_file.log, ' Combo Type '|| lc_insert_col_name||lc_select_var_cols);

    -- Start of changes done by Thilak CG for Defect #40174 and 14188 on 07-AUG-2017
    lc_err_location_msg := 'Value of lc_dc_flag: '||lc_dc_flag||' and Value of lc_dc_amt_col: '||lc_dc_amt_col;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
    IF lc_dc_flag          = 'Y' AND lc_dc_amt_col IS NOT NULL AND lc_dc_indicator_col IS NOT NULL THEN
      lc_dc_amt_decode    := 'DECODE(SIGN('||lc_dc_amt_col||'),''1'','||''''||lc_debit||''''||','||'''0'','||''''||lc_debit||''''||','||''''||lc_credit||''''||')';
      lc_dc_update_sql    := 'UPDATE XX_AR_EBL_TXT_TRL_STG SET '||lc_dc_indicator_col||' = '||lc_dc_amt_decode||' WHERE rec_type != ''FID'' AND file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_ORDER = '||ln_get_dist_rows;
      lc_err_location_msg := 'Updated Trailer DC Indicator Column: '||lc_dc_update_sql;
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
      EXECUTE IMMEDIATE lc_dc_update_sql;
	--START Added by Aniket CG 15 May #NAIT-29364
        ELSIF lc_dc_flag = 'Y' AND  ( lc_dc_amt_col_db IS NOT NULL OR lc_dc_amt_col_cr IS NOT NULL) AND lc_dc_indicator_col IS NOT NULL THEN
            IF lc_dc_flag = 'Y' AND  lc_dc_amt_col_db IS NOT NULL AND lc_dc_indicator_col IS NOT NULL THEN
                  lc_dc_amt_decode_db    := 'DECODE(SIGN('||lc_dc_amt_col_db||'),''1'','||''''||lc_debit||''''||','||'''0'','||''''||lc_debit||''''||','||''''||lc_credit||''''||')';
                  lc_dc_update_sql_db    := 'UPDATE XX_AR_EBL_TXT_TRL_STG SET '||lc_dc_indicator_col||' = '||lc_dc_amt_decode_db||' WHERE rec_type != ''FID'' AND file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_ORDER = '||ln_get_dist_rows;
                  lc_err_location_msg := 'Updated Trailer DEBIT Indicator Column: '||lc_dc_update_sql_db;
                  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
                  EXECUTE IMMEDIATE lc_dc_update_sql_db;
            END IF;
            IF lc_dc_flag = 'Y' AND  lc_dc_amt_col_cr IS NOT NULL AND lc_dc_indicator_col IS NOT NULL THEN
                lc_dc_amt_decode_cr    := 'DECODE(SIGN('||lc_dc_amt_col_cr||'),''1'','||''''||lc_debit||''''||','||'''0'','||''''||lc_debit||''''||','||''''||lc_credit||''''||')';
                lc_dc_update_sql_cr    := 'UPDATE XX_AR_EBL_TXT_TRL_STG SET '||lc_dc_indicator_col||' = '||lc_dc_amt_decode_cr||' WHERE rec_type != ''FID'' AND file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_ORDER = '||ln_get_dist_rows;
                lc_err_location_msg := 'Updated Trailer CREDIT Indicator Column: '||lc_dc_update_sql_cr;
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
                EXECUTE IMMEDIATE lc_dc_update_sql_cr;
            END IF;
     --END Added by Aniket CG 15 May #NAIT-29364
    END IF;
    -- End
    -- Updating the Line Number in the Detail Staging table.
    IF lc_trl_print_line_num = 'Y' THEN
      -- Framing the SQL to update the line number in the trailer staging table
      lc_trl_stg_query := 'SELECT DISTINCT FILE_ID, CUST_DOC_ID, REC_ORDER FROM XX_AR_EBL_TXT_TRL_STG WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_TYPE != '||'''FID'''||' AND REC_ORDER = '||ln_get_dist_rows;
      -- Getting sequence number from header summay and detail records.
      ln_hdr_line_count := 0;
      -- Added by Thilak CG on 25-JUL-2017 for Defect#42380
      lc_trl_cols         := SUBSTR(lc_trl_col,1,(LENGTH(lc_trl_col)-1));
      lc_stg_update_query := 'select a.str from (WITH DATA AS
							( SELECT ' ||''''||lc_trl_cols||''''|| ' str FROM dual
							)
							SELECT trim(regexp_substr(str, ''[^,]+'', 1, LEVEL)) str
							FROM DATA
							CONNECT BY instr(str, '','', 1, LEVEL - 1) > 0) a';
      -- End
      -- Changes for the defect#42322
      /*SELECT NVL(MAX(ROWNUMBER),ln_hdr_line_count)
      INTO ln_hdr_line_count
      FROM XX_CDH_EBL_TEMPL_HDR_TXT
      WHERE CUST_DOC_ID = p_cust_doc_id;*/

	  ln_hdr_trl_num_max := 0;
       -- Changes for the defect#42322
      SELECT NVL(MAX(ROWNUMBER),ln_hdr_line_count)
        INTO ln_hdr_trl_num_max
        FROM XX_CDH_EBL_TEMPL_HDR_TXT
       WHERE CUST_DOC_ID = p_cust_doc_id;

      SELECT COUNT (DISTINCT xftv.source_value4)
      INTO ln_hdr_line_count
      FROM xx_fin_translatedefinition xftd ,
        xx_fin_translatevalues XFTV ,
        xx_cdh_ebl_templ_hdr_txt xcetht
      WHERE xftd.translate_id   = xftv.translate_id
      AND xftd.translation_name = 'XX_CDH_EBL_TXT_HDR_FIELDS'
      AND XFTV.ENABLED_FLAG     = 'Y'
      AND TRUNC(sysdate) BETWEEN TRUNC(XFTV.START_DATE_ACTIVE) AND TRUNC(NVL(XFTV.END_DATE_ACTIVE,sysdate+1))
      AND XFTV.SOURCE_VALUE1 = XCETHT.FIELD_ID
      AND XCETHT.ATTRIBUTE20 = 'Y'
      AND XCETHT.CUST_DOC_ID = p_cust_doc_id
      AND xftv.source_value4     IN
        (SELECT xftv.source_value1
        FROM xx_fin_translatedefinition xftd ,
          xx_fin_translatevalues XFTV
        WHERE xftd.translate_id   = xftv.translate_id
        AND xftd.translation_name = 'XX_AR_EBL_TXT_LINE_NUM'
        AND XFTV.ENABLED_FLAG     = 'Y'
        AND TRUNC(sysdate) BETWEEN TRUNC(XFTV.START_DATE_ACTIVE) AND TRUNC(NVL(XFTV.END_DATE_ACTIVE,sysdate+1))
        );

      IF ln_hdr_trl_num_max > 1 AND ln_hdr_line_count = 1
      THEN
		ln_hdr_line_count := ln_hdr_trl_num_max;
      END IF;

      ln_dtl_line_count      := 0;
      IF lc_trl_target_value1 = 'Y' THEN
        SELECT COUNT(1)
        INTO ln_dtl_line_count
        FROM XX_AR_EBL_TXT_DTL_STG
        WHERE CUST_DOC_ID = p_cust_doc_id
        AND FILE_ID       = p_file_id
        AND REC_TYPE     != 'FID';
      ELSE
        SELECT COUNT(DISTINCT CUSTOMER_TRX_ID)
        INTO ln_dtl_line_count
        FROM XX_AR_EBL_TXT_DTL_STG
        WHERE CUST_DOC_ID = p_cust_doc_id
        AND FILE_ID       = p_file_id
        AND REC_TYPE     != 'FID';
      END IF;
      ln_trl_line_num := NVL(ln_hdr_line_count,0) + NVL(ln_dtl_line_count,0);
      -- Open the Cursors and update the sequence number
      IF lc_trl_cols IS NOT NULL THEN
        OPEN c_trl_stg_cursor FOR lc_trl_stg_query; -- hdr cursor.
        LOOP
          FETCH c_trl_stg_cursor
          INTO ln_trl_file_id,
            ln_trl_cust_doc_id,
            ln_trl_rec_order;
          EXIT
        WHEN c_trl_stg_cursor%NOTFOUND;
          ln_trl_line_num := NVL(ln_trl_line_num,0) + 1;
          -- Added by Thilak CG on 25-JUL-2017 for Defect#42380
          OPEN c_stg_row_cursor FOR lc_stg_update_query;
          LOOP
            FETCH c_stg_row_cursor INTO lc_row_seq_col;
            EXIT
          WHEN c_stg_row_cursor%NOTFOUND;
            lc_trl_update_sql   := 'UPDATE XX_AR_EBL_TXT_TRL_STG SET '||lc_row_seq_col||' = '||ln_trl_line_num||' WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_ORDER = '||ln_get_dist_rows;
            lc_err_location_msg := 'Updated Trl Row Numbering Column: '||lc_trl_update_sql;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
            EXECUTE IMMEDIATE lc_trl_update_sql;
          END LOOP;
          -- End
        END LOOP;
      END IF;
    END IF;
    -- End
    -- Added by Punit CG for defect#40174 on 11-AUG-2017
    lc_trl_sign_cols     := SUBSTR(lc_get_sign_amt_cols,1,LENGTH(lc_get_sign_amt_cols)-1);
    lc_sign_update_query := 'select a.str from (WITH DATA AS
							( SELECT ' ||''''||lc_trl_sign_cols||''''|| ' str FROM dual
							)
							SELECT trim(regexp_substr(str, ''[^,]+'', 1, LEVEL)) str
							FROM DATA
							CONNECT BY instr(str, '','', 1, LEVEL - 1) > 0) a';
    lc_err_location_msg  := 'Value of lc_sign_update_query is '||lc_sign_update_query;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
    -- Framing the SQL to update the Sign columns in trailer staging table
    lc_trl_upd_sign_query:= 'SELECT DISTINCT FILE_ID,CUST_DOC_ID,REC_ORDER FROM XX_AR_EBL_TXT_TRL_STG WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_TYPE != '||'''FID'''||' AND REC_ORDER = '||ln_get_dist_rows;
    -- Open the Cursors and update the Sign columns
    lc_err_location_msg := 'Value of lc_abs_flag is '||lc_abs_flag||' and Value of ln_sign_update_cnt is '||ln_sign_update_cnt;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
    IF ((lc_abs_flag = 'Y') AND (ln_sign_update_cnt = 1)) THEN
      OPEN c_trl_upd_sign_cursor FOR lc_trl_upd_sign_query;
      LOOP
        FETCH c_trl_upd_sign_cursor
        INTO ln_trl_sign_file_id,
          ln_trl_sign_cust_doc_id,
          ln_trl_sign_rec_order;
        EXIT
      WHEN c_trl_upd_sign_cursor%NOTFOUND;
        OPEN c_sign_row_cursor FOR lc_sign_update_query;
        LOOP
          FETCH c_sign_row_cursor INTO lc_row_sign_col;
          EXIT
        WHEN c_sign_row_cursor%NOTFOUND;
          ln_sign_col_str     := NULL;
          lc_sign_col_decode  := NULL;
          BEGIN
            IF lc_amt_sign_flag = 'Y' THEN
              SELECT TO_NUMBER(SUBSTR(lc_row_sign_col,INSTR(lc_row_sign_col,'n')+1))-1
              INTO ln_sign_col_str
              FROM DUAL;
            ELSIF lc_sign_flag = 'Y' THEN
              SELECT TO_NUMBER(SUBSTR(lc_row_sign_col,INSTR(lc_row_sign_col,'n')+1))+1
              INTO ln_sign_col_str
              FROM DUAL;
            END IF;
          EXCEPTION
          WHEN OTHERS THEN
            lc_err_location_msg := 'Error While Selecting the Sign Columns Number : ' || SQLCODE || ' - ' || SQLERRM;
            XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || ln_sign_col_str);
            p_trl_error_flag := 'Y';
            p_trl_error_msg  := lc_err_location_msg;
          END;
          BEGIN
            IF ln_sign_col_str    IS NOT NULL THEN
              ln_sign_col_cnt     := 0;
              lc_sign_amt_field_id := NULL;
              EXECUTE IMMEDIATE 'SELECT '||lc_column||ln_sign_col_str|| ' FROM  XX_AR_EBL_TXT_TRL_STG' ||' WHERE file_id = '||p_file_id ||' AND cust_doc_id = '||p_cust_doc_id ||' AND REC_TYPE = '||'''FID''' ||' AND REC_ORDER = '||ln_get_dist_rows INTO lc_sign_amt_field_id;
              lc_err_location_msg := 'Selected Field iD value '||lc_sign_amt_field_id;
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
              SELECT COUNT(flv.lookup_code)
              INTO ln_sign_col_cnt
              FROM fnd_lookup_values_vl FLV
              WHERE FLV.lookup_type      = 'XX_AR_EBL_TXT_TRL_SIGN_COLS'
              AND UPPER(flv.lookup_code) = UPPER(
                (SELECT DISTINCT xftv.source_value4
                FROM Xx_Fin_Translatedefinition Xftd ,
                  Xx_Fin_Translatevalues Xftv
                WHERE xftd.translate_id   = xftv.translate_id
                AND Xftv.Source_Value1    = lc_sign_amt_field_id
                AND xftd.translation_name ='XX_CDH_EBL_TXT_TRL_FIELDS'
                AND Xftv.Enabled_Flag     ='Y'
                AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
                ))
              AND FLV.enabled_flag = 'Y'
              AND TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
            END IF;
          EXCEPTION
          WHEN OTHERS THEN
            lc_err_location_msg := 'Error while selecting the mapping SIGN column from the lookup XX_AR_EBL_TXT_TRL_SIGN_COLS';
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
            p_trl_error_flag := 'Y';
            p_trl_error_msg  := lc_err_location_msg;
          END;
          BEGIN
            IF ln_sign_col_cnt     = 1 THEN
              --    ln_sign_col_str    :=  'SUBSTR('||lc_row_sign_col||',INSTR('||lc_row_sign_col||',''N'')+1)'||ln_amtsign_val;
              lc_sign_col_decode      := 'DECODE(SIGN('||lc_column||ln_sign_col_str||'),''1'',''+'',''-1'',''-'','''')';
              lc_update_sign_amt_cols := 'UPDATE XX_AR_EBL_TXT_TRL_STG SET ' ||lc_row_sign_col ||' = '||lc_sign_col_decode ||' WHERE file_id = '||p_file_id ||' AND cust_doc_id = '||p_cust_doc_id ||' AND REC_TYPE != '||'''FID''' ||' AND REC_ORDER = '||ln_get_dist_rows;
              EXECUTE IMMEDIATE lc_update_sign_amt_cols;
              lc_err_location_msg := 'Executed Sign Column updates in XX_AR_EBL_TXT_TRL_STG table';
              XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg|| '-' ||lc_update_sign_amt_cols );
            END IF;
          EXCEPTION
          WHEN OTHERS THEN
            lc_err_location_msg := 'Error While Updating the Sign Columns of Trailer Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
            XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_sign_amt_cols);
            p_trl_error_flag := 'Y';
            p_trl_error_msg  := lc_err_location_msg;
          END;
        END LOOP;
      END LOOP;
    END IF;
    -- End of Added by Punit CG for defect#40174 on 11-AUG-2017
    -- Added by Thilak CG for defect#40174 on 08-AUG-2017
    lc_err_location_msg := 'Value of lc_abs_flag is '||lc_abs_flag||' and Value of ln_abs_update_cnt is '||ln_abs_update_cnt;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
    IF ((lc_abs_flag          = 'Y') AND (ln_abs_update_cnt = 1)) THEN
      lc_update_abs_amt_cols := 'UPDATE XX_AR_EBL_TXT_TRL_STG SET' || SUBSTR(lc_get_abs_amt_cols,1,LENGTH(lc_get_abs_amt_cols)-1) || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' || p_cust_doc_id || ' AND file_id = ' || p_file_id||' AND REC_ORDER = '||ln_get_dist_rows;
      BEGIN
        EXECUTE IMMEDIATE lc_update_abs_amt_cols;
        lc_err_location_msg := 'Executed Absolute Amount update in XX_AR_EBL_TXT_TRL_STG table';
        XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg|| '-' ||lc_update_abs_amt_cols );
      EXCEPTION
      WHEN OTHERS THEN
        lc_err_location_msg := 'Error While Updating the Absolute Amount Columns of Trailer Staging Table : ' || SQLCODE || ' - ' || SQLERRM;
        XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg || '-' || lc_update_abs_amt_cols);
        p_trl_error_flag := 'Y';
        p_trl_error_msg  := lc_err_location_msg;
      END;
    END IF;
    -- End
    p_trl_error_flag := 'N';
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  lc_err_location_msg := 'Error While Inserting the data into Trailer Staging Table : '||SQLCODE||' - '||SQLERRM ;
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
  p_trl_error_flag := 'Y';
  p_trl_error_msg  := lc_err_location_msg;
END PROCESS_TXT_TRL_DATA;
-- +=============================================================================+
-- |                         Office Depot - Enhancement Requirement#2302         |
-- |                                CAPGEMINI                                    |
-- +=============================================================================+
-- | Name        : XX_AR_EBL_TXT_CHILD_NON_DT                                    |
-- | Description : This Procedure is used to insert special columns into the TXT |
-- |               stagging table in the order that the user selects from CDH    |
-- |               for a NON-DT record type                                      |
-- |                                                                             |
-- | Parameters  :  p_cust_doc_id                                                |
-- |               ,p_field_id                                                   |
-- |               ,p_insert                                                     |
-- |               ,p_select                                                     |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |Version   Date          Author                  Remarks                      |
-- |=======   ==========  ========  =============================================|
-- |DRAFT 1.0 08-FEB-2017 Punit CG  Initial version for Req#(2282,2302,40015)    |
-- |      1.1 05-JUL-2017  Punit G                  Changes for Defect # 39140   |
-- |      1.2 31-JUL-2017  Punit G                  Changes for Defect # 41307   |
-- |      1.3 15-DEC-2017  Aniket CG                Changes for Defect #22772       |
-- +=============================================================================+
PROCEDURE XX_AR_EBL_TXT_CHILD_NON_DT(
    p_cust_doc_id IN NUMBER ,
    p_ebatchid    IN NUMBER ,
    p_file_id     IN NUMBER ,
    p_insert      IN VARCHAR2 ,
    p_select      IN VARCHAR2 ,
    p_seq_nondt   IN VARCHAR2, -- Added by Punit for Defect #39140 on 05-JUL-2017
    p_rownum      IN NUMBER,   -- Added by Punit for Defect #41307 on 31-JUL-2017
    p_cmb_splt_whr          IN VARCHAR2 , --Added by Aniket CG #22772 on 15 Dec 2017
    p_doc_type    IN VARCHAR2,
    p_debug_flag  IN VARCHAR2 ,
    p_insert_status OUT VARCHAR2 ,
    p_cycle_date IN DATE )
IS
  -- +=============================================================================+
  -- | Cursor to retrieve all the NON-DT record type for the                       |
  -- | customer document ID                                                        |
  -- +=============================================================================+
  CURSOR lcu_get_all_non_dt_field_info(p_cust_doc_id IN NUMBER)
  IS
    SELECT xftv.target_value19 rec_type ,
      TO_NUMBER(xftv.target_value13) rec_order
    FROM xx_fin_translatedefinition xftd ,
      xx_fin_translatevalues xftv ,
      xx_cdh_ebl_templ_dtl_txt xcetd
    WHERE xftd.translate_id   = xftv.translate_id
    AND xftv.source_value1    = xcetd.field_id
    AND xcetd.cust_doc_id     = p_cust_doc_id
    AND xftd.translation_name = 'XX_CDH_EBL_TXT_DET_FIELDS' --'XX_CDH_EBILLING_FIELDS'
    AND xftv.target_value19  <> 'DT'
    AND xftv.enabled_flag     ='Y'
    AND xcetd.attribute20     = 'Y'      -- Added for Module 4B Release 3
    AND xcetd.rownumber       = p_rownum -- Added by Punit for Defect #41307 on 31-JUL-2017
    AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
    ORDER BY rec_order;
  ln_max_seq    NUMBER;
  ln_count      NUMBER;
  ln_org_id     NUMBER := fnd_profile.value('ORG_ID');
  lc_ndt_stmt   VARCHAR2(32767);
  lc_from       VARCHAR2(32767);
  lb_debug_flag BOOLEAN;
TYPE lcu_get_transactions
IS
  REF
  CURSOR;
    get_transactions lcu_get_transactions;
    lc_get_trans_id xx_ar_ebl_cons_dtl_main.customer_trx_id%TYPE;
    lc_err_location_msg VARCHAR2(1000);
    --Added p_cmb_splt_whr by Aniket CG #22772 on 15 Dec 2017 IN FROM lc_ndt_cons_from
    lc_ndt_cons_from    VARCHAR2(32767) := ' FROM xx_ar_ebl_cons_hdr_main hdr, xx_ar_ebl_cons_dtl_main dtl,
xx_fin_translatedefinition xftd ,xx_fin_translatevalues xftv
WHERE xftv.enabled_flag=''Y''
AND TRUNC(SYSDATE) BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE)
AND hdr.customer_trx_id = dtl.customer_trx_id
AND hdr.parent_cust_doc_id = dtl.parent_cust_doc_id
AND dtl.trx_line_type = ''ITEM''
AND hdr.parent_cust_doc_id ='||p_cust_doc_id || ' AND xftd.translate_id = xftv.translate_id and xftd.translation_name = ''XX_CDH_EBL_TXT_DET_FIELDS''
AND hdr.file_id ='||p_file_id||'
AND hdr.org_id='||ln_org_id|| p_cmb_splt_whr||'
and xftv.target_value19 = ';
    lc_decode_hdr_col VARCHAR2(1000) := get_decode_ndt(p_debug_flag); -- The value will be returned by the function will be similar to this 'TO_CHAR(DECODE(xxfv.Target_Value19,''CP'', hdr.TOTAL_COUPON_AMOUNT, ''GC'', hdr.TOTAL_GIFT_CARD_AMOUNT, ''TD'', hdr.TOTAL_TIERED_DISCOUNT_AMOUNT, ''MS'', hdr.TOTAL_MISCELLANEOUS_AMOUNT, ''DL'', hdr.TOTAL_FRIEGHT_AMOUNT, ''BD'', hdr.TOTAL_BULK_AMOUNT, ''PST'', hdr.TOTAL_PST_AMOUNT, ''GST'', hdr.TOTAL_GST_AMOUNT, ''QST'', hdr.TOTAL_QST_AMOUNT, ''TX'', hdr.TOTAL_US_TAX_AMOUNT, ''HST'', hdr.TOTAL_HST_AMOUNT, ''AD'', hdr.TOTAL_ASSOCIATION_DISCOUNT))';
    -- +=============================================================================+
    -- | Loops through the customer document ID to check if any of the               |
    -- | NON-DT record type is present for processing                                |
    -- +=============================================================================+
  BEGIN
    IF (p_debug_flag = 'Y') THEN
      lb_debug_flag := TRUE;
    ELSE
      lb_debug_flag := FALSE;
    END IF;
    IF (p_doc_type                                                                                                                               = 'CONS') THEN
      IF p_seq_nondt                                                                                                                            IS NOT NULL THEN
        OPEN get_transactions FOR SELECT xaech.customer_trx_id customer_trx_id FROM xx_ar_ebl_cons_hdr_main xaech WHERE xaech.parent_cust_doc_id = p_cust_doc_id
        -- AND    xaech.extract_batch_id   = p_ebatchid
        AND xaech.file_id    = p_file_id;
        lc_err_location_msg := 'Opening Cursor for Consolidated document';
        XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
      END IF;
      lc_from := lc_ndt_cons_from ;
    END IF;
    IF p_seq_nondt IS NULL THEN -- If Electronic Detail Sequence field is NOT configured for the cust doc then non-dt records are inserted in the follwing way
      FOR lcu_rec_all_non_dt_field_info IN lcu_get_all_non_dt_field_info(p_cust_doc_id)
      LOOP
        lc_ndt_stmt := p_insert || '''' || lcu_rec_all_non_dt_field_info.rec_type || '''' || ',' || p_rownum --lcu_rec_all_non_dt_field_info.rec_order Changed by Punit CG on 18-AUG-2017
        || ',' ||'''' ||p_cycle_date ||'''' || ',' || p_select || lc_from || '''' || lcu_rec_all_non_dt_field_info.rec_type || '''' ||'AND dtl.trx_line_number = 1' || 'AND ' || lc_decode_hdr_col || ' != 0) ';
        EXECUTE IMMEDIATE (lc_ndt_stmt);
      END LOOP;
      lc_err_location_msg := 'Executed insertion of non-dt records where Electronic Detail Sequence Number is not present';
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
    ELSE -- If Electronic Detail Sequence field is not configured for the cust doc then non-dt records are inserted transaction wise
      lc_err_location_msg := 'Sequence field is present ';
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
      SELECT COUNT(xcetd.cust_doc_id)
      INTO ln_count
      FROM xx_fin_translatedefinition xftd ,
        xx_fin_translatevalues xftv ,
        xx_cdh_ebl_templ_dtl_txt xcetd
      WHERE xftd.translate_id   = xftv.translate_id
      AND xftv.source_value1    = xcetd.field_id
      AND xcetd.cust_doc_id     = p_cust_doc_id
      AND xftd.translation_name = 'XX_CDH_EBL_TXT_DET_FIELDS' --'XX_CDH_EBILLING_FIELDS'
      AND xftv.target_value19  <> 'DT'
      AND xftv.enabled_flag     ='Y'
      AND xcetd.attribute20     = 'Y'
      AND xcetd.rownumber       = p_rownum -- Added by Punit for Defect #41307 on 31-JUL-2017
      AND TRUNC(SYSDATE) BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE);
    IF ln_count > 0 THEN -- To check if any non-dt field is configured
      LOOP
        FETCH get_transactions INTO lc_get_trans_id;
        EXIT
      WHEN get_transactions%NOTFOUND;
        -- +=============================================================================+
        -- | Loops through the customer document ID to get the maximum of the            |
        -- | electronic sequence from data extraction table                              |
        -- +=== =========================================================================+
        IF (p_doc_type = 'CONS') THEN
          SELECT MAX (elec_detail_seq_number)
          INTO ln_max_seq
          FROM xx_ar_ebl_cons_dtl_main
          WHERE parent_cust_doc_id = p_cust_doc_id
            --AND    extract_batch_id = p_ebatchid
          AND customer_trx_id  = lc_get_trans_id
          AND trx_line_type    = 'ITEM';
          lc_err_location_msg := 'Selecting maximum of elec_detail_seq_number from xx_ar_ebl_cons_dtl_main ';
        END IF;
        -- +=============================================================================+
        -- | Loops through the customer document ID to get the all the NON DT rec type   |
        -- | for inserting the electronic sequence value into the TXT stagging table     |
        -- | for each transaction for the consolidated document type                     |
        -- +=============================================================================+
        ln_max_seq := NVL(ln_max_seq,0)    + 1;
        FOR lcu_rec_all_non_dt_field_info IN lcu_get_all_non_dt_field_info(p_cust_doc_id)
        LOOP
          lc_ndt_stmt := p_insert || '''' || lcu_rec_all_non_dt_field_info.rec_type || '''' || ',' || p_rownum --lcu_rec_all_non_dt_field_info.rec_order Changed by Punit CG on 18-AUG-2017
          || ',' ||'''' ||p_cycle_date ||'''' || ',' || p_select ||',' || ln_max_seq                           -- insert the incremented value for the sequence (ln_max_seq) using ln_max_seq into the TXT stg table
          || lc_from || '''' || lcu_rec_all_non_dt_field_info.rec_type || '''' || ' AND hdr.customer_trx_id = ' ||lc_get_trans_id ||' AND dtl.trx_line_number = 1' || ' AND ' || lc_decode_hdr_col || ' != 0) ';
          EXECUTE IMMEDIATE (lc_ndt_stmt);
          IF SQL%ROWCOUNT <> 0 THEN
            ln_max_seq    := ln_max_seq + 1;
          END IF;
          lc_err_location_msg := 'Executed insertion of non-dt records for transaction ' || lc_get_trans_id;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg || CHR(13) || lc_ndt_stmt );
        END LOOP;
      END LOOP;
      CLOSE get_transactions;
    ELSE
      lc_err_location_msg := 'The cust doc does not have any non DT fields configured';
      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,lc_err_location_msg );
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  p_insert_status := SQLERRM;
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,'ERROR in XX_AR_EBL_TXT_CHILD_NON_DT: ' || SQLERRM || CHR(13) || 'Code Location : ' || lc_err_location_msg );
END XX_AR_EBL_TXT_CHILD_NON_DT;
-- +===================================================================================+
-- |                  Office Depot - Enhancement Requirement#2302                      |
-- |                             CAPGEMINI                                             |
-- +===================================================================================+
-- | Name        : GET_DECODE_NDT                                                      |
-- | Description : This function is used to concatenate the header coumns for which a  |
-- |               non dt record has to be populated in a way as used in the code      |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                  Remarks                            |
-- |=======   ==========  ========  ===================================================|
-- |DRAFT 1.0 08-FEB-2017 Punit CG  Initial Draft version for Req#(2282,2302,40015)    |
-- +===================================================================================+
FUNCTION get_decode_ndt(
    p_debug_flag IN VARCHAR2)
  RETURN VARCHAR2
AS
  lc_decode_ndt VARCHAR2 (1000);
  lb_debug_flag BOOLEAN;
BEGIN
  IF (p_debug_flag = 'Y') THEN
    lb_debug_flag := TRUE;
  ELSE
    lb_debug_flag := FALSE;
  END IF;
  FOR lcu_decode_ndt IN
  (SELECT xftv.source_value4,
    xftv.target_value19,
    xftv.target_value14
  FROM xx_fin_translatedefinition xftd,
    xx_fin_translatevalues xftv
  WHERE xftd.translate_id   = xftv.translate_id
  AND xftd.translation_name = 'XX_CDH_EBL_TXT_DET_FIELDS'
  AND xftv.target_value19  != 'DT'
  AND xftv.enabled_flag     = 'Y'
  AND TRUNC (SYSDATE) BETWEEN TRUNC (xftv.start_date_active) AND TRUNC ( NVL (xftv.end_date_active, SYSDATE + 1))
  )
  LOOP
    IF lcu_decode_ndt.target_value14 = 'NEG' THEN
      lc_decode_ndt                 := lc_decode_ndt || '''' || lcu_decode_ndt.target_value19 || ''',(-1) * HDR.' || lcu_decode_ndt.source_value4 || ',';
    ELSE
      lc_decode_ndt := lc_decode_ndt || '''' || lcu_decode_ndt.target_value19 || ''',HDR.' || lcu_decode_ndt.source_value4 || ',';
    END IF;
  END LOOP;
  lc_decode_ndt := ( 'TO_CHAR(DECODE(xftv.Target_Value19,' || SUBSTR (lc_decode_ndt, 1, (LENGTH (lc_decode_ndt) - 1)) || '))');
  /*XX_AR_EBL_COMMON_UTIL_PKG.
  PUT_LOG_LINE (
  lb_debug_flag,
  FALSE,
  'String returned from the function get_decode_ndt ' || lc_decode_ndt);*/
  RETURN lc_decode_ndt;
END get_decode_ndt;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_column_name                                                     |
-- | Description : This function is used to build the sql columns with concatenated    |
-- |               field names as per setup defined in the concatenation tab           |
-- |Parameters   : cust_doc_id, concatenated_field_id                                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- |      1.1 25-MAY-2017  Punit Gupta CG          Changes done for  Defect #42226     |
-- +===================================================================================+
FUNCTION get_column_name(
    p_field_id     IN NUMBER ,
    p_field_id_seq IN NUMBER ,
    p_cust_doc_id  IN NUMBER ,
    p_trx_type     IN VARCHAR2 ,
    p_record_type  IN VARCHAR2 ,
    p_file_id      IN NUMBER )
  RETURN VARCHAR2
IS
  lc_col_name         VARCHAR2(2000);
  lc_col_type         VARCHAR2(200);
  lc_col_data_type    VARCHAR2(200);
  lc_translation_name VARCHAR2(100)   := NULL;
  lc_format_mask      VARCHAR2(30)    := 'YYYY-MM-DD';
  lc_spl_function     VARCHAR2(2000)  := NULL;
  lc_function         VARCHAR2(32767) := NULL;
  lc_function_return  VARCHAR2(2000);
BEGIN
  IF p_trx_type          = 'HDR' THEN
    lc_translation_name := 'XX_CDH_EBL_TXT_HDR_FIELDS';
  ELSIF p_trx_type       = 'DTL' THEN
    lc_translation_name := 'XX_CDH_EBL_TXT_DET_FIELDS';
  ELSIF p_trx_type       = 'TRL' THEN
    lc_translation_name := 'XX_CDH_EBL_TXT_TRL_FIELDS';
  END IF;
  fnd_file.put_line(fnd_file.log,'Field Id: '||p_field_id||' Translation Name: '||lc_translation_name||' Trx Type : '||p_trx_type);
  BEGIN
    SELECT xftv.source_value4,
      xftv.target_value20,
      xftv.target_value1,
      xftv.target_value24
    INTO lc_col_name,
      lc_col_type,
      lc_col_data_type,
      lc_spl_function
    FROM xx_fin_translatedefinition xftd ,
      xx_fin_translatevalues xftv
    WHERE XFTD.TRANSLATE_ID   = XFTV.TRANSLATE_ID
    AND XFTV.SOURCE_VALUE1    = p_field_id
    AND xftd.translation_name =lc_translation_name
    AND xftv.target_value19   = 'DT' -- Uncommented by Punit on 25-MAY-2017
    AND XFTV.ENABLED_FLAG     ='Y'
    AND TRUNC(SYSDATE) BETWEEN TRUNC(XFTV.START_DATE_ACTIVE) AND TRUNC(NVL(XFTV.END_DATE_ACTIVE,SYSDATE+1));
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error While getting translation values '||SQLERRM);
  END;
  fnd_file.put_line(fnd_file.log,'Column Name is : '||lc_col_name||' Column Type : '||lc_col_type);
  IF lower(lc_col_type) = 'header' THEN
    IF lc_col_data_type = 'DATE' THEN
      IF p_trx_type     = 'HDR' THEN
        BEGIN
          SELECT NVL(rtrim(ltrim(data_format)),'YYYY-MM-DD')
          INTO lc_format_mask
          FROM xx_cdh_ebl_templ_hdr_txt
          WHERE cust_doc_id = p_cust_doc_id
          AND field_id      = p_field_id
          AND seq           = NVL(p_field_id_seq, seq)
          AND attribute20  != 'Y';
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SELECT NVL(rtrim(ltrim(data_format)),'YYYY-MM-DD')
          INTO lc_format_mask
          FROM xx_cdh_ebl_templ_hdr_txt
          WHERE cust_doc_id = p_cust_doc_id
          AND field_id      = p_field_id
          AND seq           = NVL(p_field_id_seq, seq)
          AND attribute20   = 'Y';
        END;
      ELSIF p_trx_type = 'DTL' THEN
        BEGIN
          SELECT NVL(rtrim(ltrim(data_format)),'YYYY-MM-DD')
          INTO lc_format_mask
          FROM xx_cdh_ebl_templ_dtl_txt
          WHERE cust_doc_id = p_cust_doc_id
          AND field_id      = p_field_id
          AND record_type   = p_record_type
          AND seq           = NVL(p_field_id_seq, seq)
          AND attribute20  != 'Y';
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SELECT NVL(rtrim(ltrim(data_format)),'YYYY-MM-DD')
          INTO lc_format_mask
          FROM xx_cdh_ebl_templ_dtl_txt
          WHERE cust_doc_id = p_cust_doc_id
          AND field_id      = p_field_id
          AND record_type   = p_record_type
          AND seq           = NVL(p_field_id_seq, seq)
          AND attribute20   = 'Y';
        END;
      ELSIF p_trx_type = 'TRL' THEN
        BEGIN
          SELECT NVL(rtrim(ltrim(data_format)),'YYYY-MM-DD')
          INTO lc_format_mask
          FROM xx_cdh_ebl_templ_trl_txt
          WHERE cust_doc_id = p_cust_doc_id
          AND field_id      = p_field_id
          AND seq           = NVL(p_field_id_seq, seq)
          AND attribute20  != 'Y';
        EXCEPTION
        WHEN OTHERS THEN
          SELECT NVL(rtrim(ltrim(data_format)),'YYYY-MM-DD')
          INTO lc_format_mask
          FROM xx_cdh_ebl_templ_trl_txt
          WHERE cust_doc_id = p_cust_doc_id
          AND field_id      = p_field_id
          AND seq           = NVL(p_field_id_seq, seq)
          AND attribute20   = 'Y';
        END;
      END IF;
      lc_col_name := 'TO_CHAR('||'hdr.'||lc_col_name||','||''''||lc_format_mask||''''||')';
    ELSE
      lc_col_name := 'hdr.'||lc_col_name;
    END IF;
  ELSIF lower(lc_col_type) = 'lines' THEN
    IF lc_col_data_type    = 'DATE' THEN
      lc_col_name         := 'TO_CHAR('||'dtl.'||lc_col_name||',''YYYY-MM-DD'')';
    ELSE
      lc_col_name := 'dtl.'||lc_col_name;
    END IF;
  ELSIF lc_col_type = 'Constant' THEN
    IF p_trx_type   = 'HDR' THEN
      BEGIN
        SELECT constant_value
        INTO lc_col_name
        FROM xx_cdh_ebl_templ_hdr_txt
        WHERE cust_doc_id = p_cust_doc_id
        AND field_id      = p_field_id
        AND seq           = NVL(p_field_id_seq, seq);
        lc_col_name      := ''''||lc_col_name||'''';
      EXCEPTION
      WHEN OTHERS THEN
        lc_col_name := NULL;
      END;
    ELSIF p_trx_type = 'DTL' THEN
      BEGIN
        SELECT constant_value
        INTO lc_col_name
        FROM xx_cdh_ebl_templ_dtl_txt
        WHERE cust_doc_id = p_cust_doc_id
        AND field_id      = p_field_id
        AND record_type   = p_record_type
        AND seq           = NVL(p_field_id_seq, seq);
        lc_col_name      := ''''||lc_col_name||'''';
      EXCEPTION
      WHEN OTHERS THEN
        lc_col_name := NULL;
      END;
    ELSIF p_trx_type = 'TRL' THEN
      BEGIN
        SELECT constant_value
        INTO lc_col_name
        FROM xx_cdh_ebl_templ_trl_txt
        WHERE cust_doc_id = p_cust_doc_id
        AND field_id      = p_field_id
        AND seq           = NVL(p_field_id_seq, seq);
        lc_col_name      := ''''||lc_col_name||'''';
      EXCEPTION
      WHEN OTHERS THEN
        lc_col_name := NULL;
      END;
    END IF;
  ELSIF lc_col_type = 'Function' THEN
    lc_function    := 'SELECT '||lc_spl_function||'('||p_cust_doc_id||','||p_file_id||', NULL, NULL'||') FROM DUAL';
    EXECUTE IMMEDIATE lc_function INTO lc_function_return;
    lc_col_name := lc_function_return;
  END IF;
  RETURN lc_col_name;
END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_conc_field_name                                                 |
-- | Description : This function is used to build the sql columns with concatenated    |
-- |               field names as per setup defined in the concatenation tab           |
-- |Parameters   : cust_doc_id, concatenated_field_id                                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
FUNCTION get_conc_field_names(
    p_cust_doc_id   IN NUMBER ,
    p_conc_field_id IN NUMBER ,
    p_trx_type      IN VARCHAR2 ,
    p_record_type   IN VARCHAR2 ,
    p_debug_flag    IN VARCHAR2 ,
    p_file_id       IN NUMBER)
  RETURN VARCHAR2
IS
  ln_concatenated_field1     NUMBER;
  ln_concatenated_field2     NUMBER;
  ln_concatenated_field3     NUMBER;
  ln_concatenated_field4     NUMBER;
  ln_concatenated_field5     NUMBER;
  ln_concatenated_field6     NUMBER;
  ln_concatenated_field1_seq NUMBER;
  ln_concatenated_field2_seq NUMBER;
  ln_concatenated_field3_seq NUMBER;
  ln_concatenated_field4_seq NUMBER;
  ln_concatenated_field5_seq NUMBER;
  ln_concatenated_field6_seq NUMBER;
  lc_concatenated_columns    VARCHAR2(2000);
  lc_col_name1               VARCHAR2(200);
  lc_col_name2               VARCHAR2(200);
  lc_col_name3               VARCHAR2(200);
  lc_col_name4               VARCHAR2(200);
  lc_col_name5               VARCHAR2(200);
  lc_col_name6               VARCHAR2(200);
  lb_debug_flag              BOOLEAN;
  lc_err_location_msg        VARCHAR2(2000);
BEGIN
  IF (p_debug_flag = 'Y') THEN
    lb_debug_flag := TRUE;
  ELSE
    lb_debug_flag := FALSE;
  END IF;
  lc_err_location_msg := 'Getting Concatenated Field Names ';
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
  BEGIN
    SELECT conc_base_field_id1,
      conc_base_field_id2,
      conc_base_field_id3,
      conc_base_field_id4,
      conc_base_field_id5,
      conc_base_field_id6 ,
      seq1,
      seq2,
      seq3,
      seq4,
      seq5,
      seq6
    INTO ln_concatenated_field1,
      ln_concatenated_field2,
      ln_concatenated_field3,
      ln_concatenated_field4,
      ln_concatenated_field5,
      ln_concatenated_field6 ,
      ln_concatenated_field1_seq,
      ln_concatenated_field2_seq,
      ln_concatenated_field3_seq,
      ln_concatenated_field4_seq,
      ln_concatenated_field5_seq,
      ln_concatenated_field6_seq
    FROM xx_cdh_ebl_concat_fields_txt
    WHERE cust_doc_id = p_cust_doc_id
    AND conc_field_id = p_conc_field_id;
  EXCEPTION
  WHEN OTHERS THEN
    ln_concatenated_field1     := NULL;
    ln_concatenated_field2     := NULL;
    ln_concatenated_field3     := NULL;
    ln_concatenated_field4     := NULL;
    ln_concatenated_field5     := NULL;
    ln_concatenated_field6     := NULL;
    ln_concatenated_field1_seq := NULL;
    ln_concatenated_field2_seq := NULL;
    ln_concatenated_field3_seq := NULL;
    ln_concatenated_field4_seq := NULL;
    ln_concatenated_field5_seq := NULL;
    ln_concatenated_field6_seq := NULL;
  END;
  lc_err_location_msg := 'Conctenated Fields: '||ln_concatenated_field1||' - '||ln_concatenated_field2||' - '||ln_concatenated_field3||' - '||ln_concatenated_field4||' - '||ln_concatenated_field5||' - '||ln_concatenated_field6;
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,FALSE ,lc_err_location_msg );
  IF ln_concatenated_field1 IS NOT NULL THEN
    lc_col_name1            := get_column_name(ln_concatenated_field1,ln_concatenated_field1_seq,p_cust_doc_id,p_trx_type,p_record_type,p_file_id);
  END IF;
  IF ln_concatenated_field2 IS NOT NULL THEN
    lc_col_name2            := get_column_name(ln_concatenated_field2,ln_concatenated_field2_seq,p_cust_doc_id,p_trx_type,p_record_type,p_file_id);
  END IF;
  IF ln_concatenated_field3 IS NOT NULL THEN
    lc_col_name3            := get_column_name(ln_concatenated_field3,ln_concatenated_field3_seq,p_cust_doc_id,p_trx_type,p_record_type,p_file_id);
  END IF;
  IF ln_concatenated_field4 IS NOT NULL THEN
    lc_col_name4            := get_column_name(ln_concatenated_field4,ln_concatenated_field4_seq,p_cust_doc_id,p_trx_type,p_record_type,p_file_id);
  END IF;
  IF ln_concatenated_field5 IS NOT NULL THEN
    lc_col_name5            := get_column_name(ln_concatenated_field5,ln_concatenated_field5_seq,p_cust_doc_id,p_trx_type,p_record_type,p_file_id);
  END IF;
  IF ln_concatenated_field6 IS NOT NULL THEN
    lc_col_name6            := get_column_name(ln_concatenated_field6,ln_concatenated_field6_seq,p_cust_doc_id,p_trx_type,p_record_type,p_file_id);
  END IF;
  IF lc_col_name1           IS NOT NULL THEN
    lc_concatenated_columns := lc_concatenated_columns||lc_col_name1;
  END IF;
  IF lc_col_name2           IS NOT NULL THEN
    lc_concatenated_columns := lc_concatenated_columns||'||'||lc_col_name2;
  END IF;
  IF lc_col_name3           IS NOT NULL THEN
    lc_concatenated_columns := lc_concatenated_columns||'||'||lc_col_name3;
  END IF;
  IF lc_col_name4           IS NOT NULL THEN
    lc_concatenated_columns := lc_concatenated_columns||'||'||lc_col_name4;
  END IF;
  IF lc_col_name5           IS NOT NULL THEN
    lc_concatenated_columns := lc_concatenated_columns||'||'||lc_col_name5;
  END IF;
  IF lc_col_name6           IS NOT NULL THEN
    lc_concatenated_columns := lc_concatenated_columns||'||'||lc_col_name6;
  END IF;
  lc_err_location_msg := 'Conctenated Columns: '||lc_concatenated_columns;
  RETURN lc_concatenated_columns;
EXCEPTION
WHEN OTHERS THEN
  lc_err_location_msg := SQLCODE||' - '||SUBSTR(sqlerrm,1,255);
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag ,TRUE ,lc_err_location_msg );
END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_split_field_count                                               |
-- | Description : This function is used to get the split fields count                 |
-- |Parameters   : cust_doc_id, p_base_field_id                                        |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
FUNCTION get_split_field_count(
    p_cust_doc_id   IN NUMBER,
    p_base_field_id IN NUMBER)
  RETURN NUMBER
IS
  lc_split_field1_label VARCHAR2(200);
  lc_split_field2_label VARCHAR2(200);
  lc_split_field3_label VARCHAR2(200);
  lc_split_field4_label VARCHAR2(200);
  lc_split_field5_label VARCHAR2(200);
  lc_split_field6_label VARCHAR2(200);
  ln_count              NUMBER := 0;
BEGIN
  BEGIN
    SELECT split_field1_label,
      split_field2_label,
      split_field3_label,
      split_field4_label,
      split_field5_label,
      split_field6_label
    INTO lc_split_field1_label,
      lc_split_field2_label,
      lc_split_field3_label,
      lc_split_field4_label,
      lc_split_field5_label,
      lc_split_field6_label
    FROM XX_CDH_EBL_SPLIT_FIELDS_TXT
    WHERE cust_doc_id       = p_cust_doc_id
    AND split_base_field_id = p_base_field_id;
  EXCEPTION
  WHEN OTHERS THEN
    lc_split_field1_label := NULL;
    lc_split_field2_label := NULL;
    lc_split_field3_label := NULL;
    lc_split_field4_label := NULL;
    lc_split_field5_label := NULL;
    lc_split_field6_label := NULL;
  END;
  IF lc_split_field1_label IS NOT NULL THEN
    ln_count               := ln_count + 1;
  END IF;
  IF lc_split_field2_label IS NOT NULL THEN
    ln_count               := ln_count + 1;
  END IF;
  IF lc_split_field3_label IS NOT NULL THEN
    ln_count               := ln_count + 1;
  END IF;
  IF lc_split_field4_label IS NOT NULL THEN
    ln_count               := ln_count + 1;
  END IF;
  IF lc_split_field5_label IS NOT NULL THEN
    ln_count               := ln_count + 1;
  END IF;
  IF lc_split_field6_label IS NOT NULL THEN
    ln_count               := ln_count + 1;
  END IF;
  RETURN ln_count;
END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_split_field_names                                               |
-- | Description : This function is used to build the sql columns with split           |
-- |               field names as per setup defined in the split tab                   |
-- |Parameters   : cust_doc_id, p_base_field_id                                        |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
-- +===================================================================================+
FUNCTION get_split_field_names(
    p_cust_doc_id   IN NUMBER,
    p_base_field_id IN NUMBER,
    p_count         IN NUMBER,
    p_trx_type      IN VARCHAR2,
    p_record_type   IN VARCHAR2,
    p_debug_flag    IN VARCHAR2)
  RETURN VARCHAR2
IS
  lc_split_column_name       VARCHAR2 (1000);
  ln_start_position          VARCHAR2 (100);
  ln_end_position            VARCHAR2 (500);
  ln_digit_length            VARCHAR2 (10);
  ln_positions1              VARCHAR2 (10);
  ln_positions2              VARCHAR2 (10);
  ln_position                VARCHAR2 (10);
  ln_split_positions         VARCHAR2 (10);
  ln_split_base_field_id     NUMBER;
  ln_fixed_position          VARCHAR2 (20);
  ln_delimiter               VARCHAR2 (10);
  lc_col_name                VARCHAR2 (200);
  ln_previous_start_position VARCHAR2 (10);
  ln_previous_end_position   VARCHAR2 (10);
  ln_previous_digit_length   VARCHAR2 (10);
  lc_max_splits              NUMBER;
  lb_debug_flag              BOOLEAN;
  lc_err_location_msg        VARCHAR2 (1000);
  ln_split_type              VARCHAR2 (10);
  ln_startend_positions      VARCHAR2 (100);
BEGIN
  IF (p_debug_flag = 'Y') THEN
    lb_debug_flag := TRUE;
  ELSE
    lb_debug_flag := FALSE;
  END IF;
  lc_err_location_msg := 'In the get_split_field_names procedure ';
  XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
  SELECT split_base_field_id,
    split_type,
    fixed_position,
    delimiter
  INTO ln_split_base_field_id,
    ln_split_type,
    ln_fixed_position,
    ln_delimiter
  FROM XX_CDH_EBL_SPLIT_FIELDS_TXT
  WHERE cust_doc_id       = p_cust_doc_id
  AND split_base_field_id = p_base_field_id;
  lc_err_location_msg    := 'Split Base Field Id: ' || ln_split_base_field_id || ' Fixed Position: ' || ln_fixed_position || ' Delimiter: ' || ln_delimiter;
  XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
  IF ln_split_base_field_id IS NOT NULL THEN
    lc_err_location_msg     := 'Calling Get Column Name ';
    lc_col_name             := get_column_name (ln_split_base_field_id, NULL, p_cust_doc_id, p_trx_type, p_record_type, NULL);
    --fnd_file.put_line(fnd_file.log,lc_col_name);
  END IF;
  lc_err_location_msg := 'Column Name is: ' || lc_col_name;
  XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
  IF lc_col_name                             IS NOT NULL AND ln_split_type = 'FP' AND ln_fixed_position IS NOT NULL THEN
    IF REGEXP_COUNT (ln_fixed_position, ',') <> 0 AND p_count = 1 THEN
      ln_start_position                      := p_count;
      ln_end_position                        := SUBSTR (ln_fixed_position, p_count, INSTR (ln_fixed_position, ',', p_count, p_count) - 1);
      SELECT 'SUBSTR('
        || lc_col_name
        || ','
        || ln_start_position
        || ','
        || ln_end_position
        || ')'
      INTO lc_split_column_name
      FROM DUAL;
    ELSIF REGEXP_COUNT (ln_fixed_position, ',') <> 0 AND p_count > 1 THEN
      SELECT INSTR (ln_fixed_position, ',', 1, p_count - 1),
        INSTR (ln_fixed_position, ',', 1, p_count)
      INTO ln_start_position,
        ln_end_position
      FROM DUAL;
      IF TO_NUMBER (ln_start_position) > 0 AND TO_NUMBER (ln_end_position) >= 0 THEN
        SELECT DECODE ( ln_end_position, 0, LENGTH ( SUBSTR (ln_fixed_position, ln_start_position + 1)), ( (ln_end_position - 1) - ln_start_position))
        INTO ln_digit_length
        FROM DUAL;
        ln_positions2 := SUBSTR (ln_fixed_position, ln_start_position + 1, ln_digit_length);
        SELECT DECODE (p_count                                        - 2, 0, 0, INSTR (ln_fixed_position, ',', 1, p_count - 2)),
          INSTR (ln_fixed_position, ',', 1, p_count                   - 1)
        INTO ln_previous_start_position,
          ln_previous_end_position
        FROM DUAL;
        ln_previous_digit_length := (ln_previous_end_position                             - 1) - ln_previous_start_position;
        ln_positions1            := SUBSTR (ln_fixed_position, ln_previous_start_position + 1, ln_previous_digit_length) + 1;
        SELECT 'SUBSTR('
          || lc_col_name
          || ','
          || ln_positions1
          || ',('
          || ln_positions2
          || '-'
          || ln_positions1
          || ')+1)'
        INTO lc_split_column_name
        FROM DUAL;
      ELSIF TO_NUMBER (ln_start_position) = 0 AND TO_NUMBER (ln_end_position) = 0 THEN
        ln_start_position                := SUBSTR (ln_fixed_position, INSTR (ln_fixed_position, ',', 1, p_count - 2) + 1) + 1;
        SELECT 'SUBSTR('
          || lc_col_name
          || ','
          || ln_start_position
          || ')'
        INTO lc_split_column_name
        FROM DUAL;
      END IF;
    ELSIF REGEXP_COUNT (ln_fixed_position, ',') = 0 AND p_count = 1 THEN
      ln_start_position                        := p_count;
      SELECT 'SUBSTR('
        || lc_col_name
        || ','
        || ln_start_position
        || ','
        || ln_fixed_position
        || ')'
      INTO lc_split_column_name
      FROM DUAL;
    ELSIF REGEXP_COUNT (ln_fixed_position, ',') = 0 AND p_count > 1 THEN
      SELECT 'SUBSTR('
        || lc_col_name
        || ','
        || ln_fixed_position
        || '+1'
        || ')'
      INTO lc_split_column_name
      FROM DUAL;
    END IF;
  ELSIF lc_col_name IS NOT NULL AND ln_split_type = 'FL' AND ln_fixed_position IS NOT NULL THEN -- for Flexible split type
    SELECT positions
    INTO ln_startend_positions
    FROM
      (SELECT REGEXP_SUBSTR (ln_fixed_position, '[^,]+', 1, LEVEL) positions
      FROM DUAL
      WHERE ROWNUM                                                       < p_count + 1
        CONNECT BY REGEXP_SUBSTR (ln_fixed_position, '[^,]+', 1, LEVEL) IS NOT NULL
      MINUS
      SELECT REGEXP_SUBSTR (ln_fixed_position, '[^,]+', 1, LEVEL) positions
      FROM DUAL
      WHERE ROWNUM                                                       < p_count
        CONNECT BY REGEXP_SUBSTR (ln_fixed_position, '[^,]+', 1, LEVEL) IS NOT NULL
      );
    ln_start_position := SUBSTR (ln_startend_positions, 1, INSTR (ln_startend_positions, '-', 1, 1) - 1);
    ln_end_position   := SUBSTR (ln_startend_positions, INSTR (ln_startend_positions, '-', 1, 1)    + 1) - SUBSTR (ln_startend_positions, 1, INSTR (ln_startend_positions, '-', 1, 1) - 1);
    SELECT 'SUBSTR('
      || lc_col_name
      || ','
      || ln_start_position
      || ','
      || ln_end_position
      || '+1'
      || ')'
    INTO lc_split_column_name
    FROM DUAL;
  ELSIF lc_col_name     IS NOT NULL AND ln_split_type = 'D' AND ln_delimiter IS NOT NULL THEN
    lc_max_splits       := get_split_field_count (p_cust_doc_id, p_base_field_id);
    IF p_count           = 1 THEN
      ln_start_position := 1;
      ln_end_position   := 'INSTR(' || lc_col_name || ',' || '''' || ln_delimiter || '''' || ',1,' || p_count || ')-1';
      SELECT 'DECODE('
        || 'INSTR('
        || lc_col_name
        || ','
        || ''''
        || ln_delimiter
        || ''''
        || ',1,'
        || p_count
        || ')'
        || ','
        || '0'
        || ','
        || 'SUBSTR('
        || lc_col_name
        || ','
        || ln_start_position
        || ')'
        || ','
        || 'SUBSTR('
        || lc_col_name
        || ','
        || ln_start_position
        || ','
        || ln_end_position
        || '))'
      INTO lc_split_column_name
      FROM DUAL;
    ELSIF p_count           = lc_max_splits THEN
      lc_split_column_name := 'DECODE(' || 'INSTR(' || lc_col_name || ',' || '''' || ln_delimiter || '''' || ',1,' || p_count || '-1' || ')' || ',0,' || '''' || NULL || '''' || ',' || 'SUBSTR(' || lc_col_name || ',' || 'INSTR(' || lc_col_name || ',' || '''' || ln_delimiter || '''' || ',1,' || p_count || '-1' || ')+1' || ')' || ')';
    ELSIF p_count           < lc_max_splits THEN
      SELECT 'INSTR('
        || lc_col_name
        || ','
        || ''''
        || ln_delimiter
        || ''''
        || ',1,'
        || p_count
        || '-1'
        || ')+1',
        '((INSTR('
        || lc_col_name
        || ','
        || ''''
        || ln_delimiter
        || ''''
        || ',1,'
        || p_count
        || ')) - (INSTR('
        || lc_col_name
        || ','
        || ''''
        || ln_delimiter
        || ''''
        || ',1,'
        || p_count
        || '-1'
        || ')+1))'
      INTO ln_start_position,
        ln_end_position
      FROM DUAL;
      lc_split_column_name := 'CASE WHEN ' || '(INSTR(' || lc_col_name || ',' || '''' || ln_delimiter || '''' || ',1,' || p_count || ') = 0 AND ' || 'INSTR(' || lc_col_name || ',' || '''' || ln_delimiter || '''' || ',1,' || p_count || '-1' || ') = 0) THEN NULL ' || ' WHEN ' || 'INSTR(' || lc_col_name || ',' || '''' || ln_delimiter || '''' || ',1,' || p_count || ') = 0 THEN ' || 'SUBSTR(' || lc_col_name || ',' || ln_start_position || ')' || ' ELSE SUBSTR(' || lc_col_name || ',' || ln_start_position || ',' || ln_end_position || ')' || ' END';
    END IF;
  END IF;
  lc_err_location_msg := 'Split Column: ' || lc_split_column_name;
  XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
  RETURN lc_split_column_name;
EXCEPTION
WHEN OTHERS THEN
  lc_err_location_msg := SQLCODE || ' - ' || SUBSTR (SQLERRM, 1, 255);
  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
END;
END XX_AR_EBL_TXT_DM_PKG;
/