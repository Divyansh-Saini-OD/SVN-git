create or replace PACKAGE BODY XX_AR_EBL_RENDER_TXT_PKG
AS
   -- +===========================================================================================+
   -- |                  Office Depot - Project Simplify                                          |
   -- +===========================================================================================+
   -- | Name        : GET_TRANSLATION                                                             |
   -- | Description : This Procedure is used for to get the Translation values                    |
   -- |Parameters   : p_translation_name                                                          |
   -- |             , p_source_value1                                                             |
   -- |             , p_source_value2                                                             |
   -- |             , x_target_value1                                                             |
   -- |Change Record:                                                                             |
   -- |===============                                                                            |
   -- |Version   Date          Author                 Remarks                                     |
   -- |=======   ==========   =============           ============================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                       |
   -- |                                               (Master Defect#37585)                       |
   -- | 1.1      01-MAR-2017  Rohit Gupta             Fixed the missing header issue.             |
   -- |                                               Defect #41016                               |
   -- | 1.2      18-APR-2017  Suresh Naragam          Defect #41426                               |
   -- | 1.3      28-APR-2018  Atul Khard              Defect #44465 Labels not outputing correctly|
   -- | 1.4      18-May-2018  Aniket J    CG          Changes for Requirement  #NAIT-36070        |
   -- | 1.5      29-Sep-2019  Atul Khard              Bug fix identified in #NAIT-106275          |
   -- +===========================================================================================+
   PROCEDURE GET_TRANSLATION (p_translation_name   IN            VARCHAR2,
                              p_source_value1      IN            VARCHAR2,
                              p_source_value2      IN            VARCHAR2,
                              x_target_value1      IN OUT NOCOPY VARCHAR2)
   IS
      ls_target_value1    VARCHAR2 (240);
      ls_target_value2    VARCHAR2 (240);
      ls_target_value3    VARCHAR2 (240);
      ls_target_value4    VARCHAR2 (240);
      ls_target_value5    VARCHAR2 (240);
      ls_target_value6    VARCHAR2 (240);
      ls_target_value7    VARCHAR2 (240);
      ls_target_value8    VARCHAR2 (240);
      ls_target_value9    VARCHAR2 (240);
      ls_target_value10   VARCHAR2 (240);
      ls_target_value11   VARCHAR2 (240);
      ls_target_value12   VARCHAR2 (240);
      ls_target_value13   VARCHAR2 (240);
      ls_target_value14   VARCHAR2 (240);
      ls_target_value15   VARCHAR2 (240);
      ls_target_value16   VARCHAR2 (240);
      ls_target_value17   VARCHAR2 (240);
      ls_target_value18   VARCHAR2 (240);
      ls_target_value19   VARCHAR2 (240);
      ls_target_value20   VARCHAR2 (240);
      ls_error_message    VARCHAR2 (240);
   BEGIN
      XX_FIN_TRANSLATE_PKG.
      XX_FIN_TRANSLATEVALUE_PROC (p_translation_name   => p_translation_name,
                                  p_source_value1      => p_source_value1,
                                  p_source_value2      => p_source_value2,
                                  x_target_value1      => x_target_value1,
                                  x_target_value2      => ls_target_value2,
                                  x_target_value3      => ls_target_value3,
                                  x_target_value4      => ls_target_value4,
                                  x_target_value5      => ls_target_value5,
                                  x_target_value6      => ls_target_value6,
                                  x_target_value7      => ls_target_value7,
                                  x_target_value8      => ls_target_value8,
                                  x_target_value9      => ls_target_value9,
                                  x_target_value10     => ls_target_value10,
                                  x_target_value11     => ls_target_value11,
                                  x_target_value12     => ls_target_value12,
                                  x_target_value13     => ls_target_value13,
                                  x_target_value14     => ls_target_value14,
                                  x_target_value15     => ls_target_value15,
                                  x_target_value16     => ls_target_value16,
                                  x_target_value17     => ls_target_value17,
                                  x_target_value18     => ls_target_value18,
                                  x_target_value19     => ls_target_value19,
                                  x_target_value20     => ls_target_value20,
                                  x_error_message      => ls_error_message);
   END GET_TRANSLATION;

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
   PROCEDURE xx_ar_ebl_txt_update_status (p_file_id       IN NUMBER,
                                          p_cust_doc_id   IN VARCHAR2,
                                          p_status        IN VARCHAR2,
                                          p_file_data     IN BLOB,
                                          p_error_msg     IN VARCHAR2)
   IS
   BEGIN
      fnd_file.
      put_line (
         fnd_file.LOG,
         'Updating Status in xx_ar_ebl_file table with status ' || p_status);

      UPDATE XX_AR_EBL_FILE
         SET status = NVL (p_status, status),
             file_data = NVL (p_file_data, file_data),
             status_detail = p_error_msg,
             last_updated_by = fnd_global.user_id,
             last_update_date = SYSDATE,
             last_update_login = fnd_global.user_id
       WHERE file_id = p_file_id AND cust_doc_id = p_cust_doc_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.
         put_line (
            fnd_file.LOG,
               'Error While Updating the status in xx_ar_ebl_file for '
            || p_cust_doc_id
            || ' - '
            || p_file_id);
   END;

   -- +===========================================================================================+
   -- |                  Office Depot - Project Simplify                                          |
   -- +===========================================================================================+
   -- | Name        : CHECK_CHILD_REQUEST                                                         |
   -- | Description : This Procedure is used for to check the Concurrent Program Completion Status|
   -- |Parameters   : p_translation_name                                                          |
   -- |             , p_source_value1                                                             |
   -- |             , p_source_value2                                                             |
   -- |             , x_target_value1                                                             |
   -- |Change Record:                                                                             |
   -- |===============                                                                            |
   -- |Version   Date          Author                 Remarks                                     |
   -- |=======   ==========   =============           ============================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                       |
   -- +===========================================================================================+
   PROCEDURE CHECK_CHILD_REQUEST (p_request_id IN OUT NOCOPY NUMBER)
   IS
      call_status   BOOLEAN;
      rphase        VARCHAR2 (80);
      rstatus       VARCHAR2 (80);
      dphase        VARCHAR2 (30);
      dstatus       VARCHAR2 (30);
      MESSAGE       VARCHAR2 (240);
   BEGIN
      call_status :=
         FND_CONCURRENT.get_request_status (p_request_id,
                                            '',
                                            '',
                                            rphase,
                                            rstatus,
                                            dphase,
                                            dstatus,
                                            MESSAGE);

      IF ( (dphase = 'COMPLETE') AND (dstatus = 'NORMAL'))
      THEN
         fnd_file.
         put_line (
            fnd_file.output,
            'child request id: ' || p_request_id || ' completed successfully');
      ELSE
         fnd_file.
         put_line (
            fnd_file.output,
               'child request id: '
            || p_request_id
            || ' did not complete successfully');
      END IF;
   END CHECK_CHILD_REQUEST;

   -- +===========================================================================================+
   -- |                  Office Depot - Project Simplify                                          |
   -- +===========================================================================================+
   -- | Name        : RENDER_TXT_P                                                                |
   -- | Description : This Procedure is used for multithreading the etxt data into                |
   -- |               batches and to submit the child procedure RENDER_TXT_C                      |
   -- |Parameters   : p_billing_dt                                                                |
   -- |             , p_debug_flag                                                                |
   -- |Change Record:                                                                             |
   -- |===============                                                                            |
   -- |Version   Date          Author                 Remarks                                     |
   -- |=======   ==========   =============           ============================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                       |
   -- +===========================================================================================+
   PROCEDURE RENDER_TXT_P (Errbuf            OUT NOCOPY VARCHAR2,
                           Retcode           OUT NOCOPY VARCHAR2,
                           p_billing_dt   IN            VARCHAR2,
                           p_debug_flag   IN            VARCHAR2)
   IS
      ln_thread_count       NUMBER;
      n_conc_request_id     NUMBER := NULL;
      ls_req_data           VARCHAR2 (240);
      ln_request_id         NUMBER;                       -- parent request id
      cnt_warnings          INTEGER := 0;
      cnt_errors            INTEGER := 0;
      request_status        BOOLEAN;
      ln_purge_days         NUMBER;
      lc_err_location_msg   VARCHAR2 (1000);
   BEGIN
      ls_req_data := fnd_conc_global.request_data;
      ln_request_id := fnd_global.conc_request_id;

      IF ls_req_data IS NOT NULL
      THEN
         fnd_file.
         put_line (
            fnd_file.output,
            ' Back at beginning after spawing ' || ls_req_data || ' threads.');
         ln_thread_count := ls_req_data;

         IF ln_thread_count > 0
         THEN
            fnd_file.put_line (fnd_file.output, 'Checking child threads...');

            -- Check all child requests to see how they finished...
            FOR child_request_rec
               IN (SELECT request_id, status_code
                     FROM fnd_concurrent_requests
                    WHERE parent_request_id = ln_request_id)
            LOOP
               check_child_request (child_request_rec.request_id);

               IF (   child_request_rec.status_code = 'G'
                   OR child_request_rec.status_code = 'X'
                   OR child_request_rec.status_code = 'D'
                   OR child_request_rec.status_code = 'T')
               THEN
                  cnt_warnings := cnt_warnings + 1;
               ELSIF (child_request_rec.status_code = 'E')
               THEN
                  cnt_errors := cnt_errors + 1;
               END IF;
            END LOOP;                                 -- FOR child_request_rec

            IF cnt_errors > 0
            THEN
               fnd_file.
               put_line (fnd_file.output,
                         'Setting completion status to ERROR.');
               request_status :=
                  fnd_concurrent.set_completion_status ('ERROR', '');
            ELSIF cnt_warnings > 0
            THEN
               fnd_file.
               put_line (fnd_file.output,
                         'Setting completion status to WARNING.');
               request_status :=
                  fnd_concurrent.set_completion_status ('WARNING', '');
            ELSE
               fnd_file.
               put_line (fnd_file.output,
                         'Setting completion status to NORMAL.');
               request_status :=
                  fnd_concurrent.set_completion_status ('NORMAL', '');
            END IF;
         END IF;

         RETURN;                                              -- end of parent
      END IF;

      get_translation ('AR_EBL_CONFIG',
                       'RENDER_TXT',
                       'PURGE_STG_AFTER_N_DAYS',
                       ln_purge_days);

      IF ln_purge_days IS NOT NULL
      THEN
         IF ln_purge_days > 0
         THEN
            DELETE FROM XX_AR_EBL_TXT_HDR_STG
                  WHERE creation_date < (SYSDATE - ln_purge_days);

            DELETE FROM XX_AR_EBL_TXT_DTL_STG
                  WHERE creation_date < (SYSDATE - ln_purge_days);

            DELETE FROM XX_AR_EBL_TXT_TRL_STG
                  WHERE creation_date < (SYSDATE - ln_purge_days);

            COMMIT;
         END IF;
      END IF;

      get_translation ('AR_EBL_CONFIG',
                       'RENDER_TXT',
                       'N_THREADS',
                       ln_thread_count);

      IF ln_thread_count IS NULL
      THEN
         ln_thread_count := 1;
      END IF;

      fnd_file.
      put_line (fnd_file.output,
                'spawning ' || ln_thread_count || ' thread(s)');

      FOR i IN 1 .. ln_thread_count
      LOOP
         fnd_file.put_line (fnd_file.output, 'thread: ' || i);

         n_conc_request_id :=
            FND_REQUEST.
            submit_request (application   => 'XXFIN' -- application short name
                                                    ,
                            program       => 'XX_AR_EBL_RENDER_TXT_C' -- concurrent program name
                                                                     ,
                            sub_request   => TRUE    -- is this a sub-request?
                                                 ,
                            argument1     => i                    -- thread_id
                                              ,
                            argument2     => ln_thread_count,
                            argument3     => p_debug_flag);

         -- ===========================================================================
         -- if request was successful
         -- ===========================================================================
         IF (n_conc_request_id > 0)
         THEN
            -- ===========================================================================
            -- must commit work so that the concurrent manager polls the request
            -- ===========================================================================
            COMMIT;

            fnd_file.
            put_line (fnd_file.output,
                      ' Concurrent Request ID: ' || n_conc_request_id || '.');
         -- ===========================================================================
         -- else errors have occured for request
         -- ===========================================================================
         ELSE
            -- ===========================================================================
            -- retrieve and raise any errors
            -- ===========================================================================
            FND_MESSAGE.raise_error;
         END IF;
      END LOOP;

      FND_CONC_GLOBAL.
      SET_REQ_GLOBALS (conc_status    => 'PAUSED',
                       request_data   => TO_CHAR (ln_thread_count));
   END RENDER_TXT_P;

   -- +==================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- +===================================================================================+
   -- | Name        : RENDER_TXT_C                                                        |
   -- | Description : This Procedure is used for framing the dynamic query to fetch data  |
   -- |               from the Configuration tables and to write the data into TXT File   |
   -- |Parameters   : p_thread_id                                                         |
   -- |             , p_thread_count                                                      |
   -- |             , p_debug_flag                                                        |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author                 Remarks                             |
   -- |=======   ==========   =============           ====================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version               |
   -- +===================================================================================+
   PROCEDURE RENDER_TXT_C (p_errbuf            OUT NOCOPY VARCHAR2,
                           p_retcode           OUT NOCOPY VARCHAR2,
                           p_thread_id      IN            NUMBER,
                           p_thread_count   IN            NUMBER,
                           p_debug_flag     IN            VARCHAR2)
   IS
      CURSOR c_txt_files
      IS
           SELECT F.file_id, F.file_name, F.cust_doc_id
             FROM XX_AR_EBL_FILE F
            WHERE     F.status = 'RENDER'
                  AND F.file_type = 'TXT'
                  AND F.invoice_type = 'CONS'
                  AND MOD (F.transmission_id, p_thread_count) = p_thread_id - 1
                  AND F.org_id = FND_GLOBAL.org_id
         ORDER BY file_id;

      ln_file_id                      xx_ar_ebl_file.file_id%TYPE;
      lc_file_name                    xx_ar_ebl_file.file_name%TYPE;
      lc_cust_doc_id                  xx_ar_ebl_file.cust_doc_id%TYPE;
      lc_output_file                  UTL_FILE.FILE_TYPE;
      lc_hdr_error_flag               VARCHAR2 (1) := NULL;
      lc_dtl_error_flag               VARCHAR2 (1) := NULL;
      lc_trl_error_flag               VARCHAR2 (1) := NULL;
      lc_hdr_error_msg                VARCHAR2 (2000);
      lc_dtl_error_msg                VARCHAR2 (2000);
      lc_trl_error_msg                VARCHAR2 (2000);
      ln_org_id                       NUMBER := fnd_profile.VALUE ('ORG_ID');
      ex_hdr_render_exception_found   EXCEPTION;
      ex_dtl_render_exception_found   EXCEPTION;
      ex_trl_render_exception_found   EXCEPTION;
      ex_file_move_to_archieve        EXCEPTION;
      lb_src_file                     BFILE;
      lb_dst_file                     BLOB;
      lgh_file                        BINARY_INTEGER;
      lc_err_location_msg             VARCHAR2 (1000);
      lb_debug_flag                   BOOLEAN;
      lc_file_creation_type           VARCHAR2 (30);
      lc_delimiter_char               VARCHAR2 (30);
      lb_file_exists                  BOOLEAN;
      ln_file_len                     NUMBER;
      lbi_blocksize                   BINARY_INTEGER;
   BEGIN
      IF (p_debug_flag = 'Y')
      THEN
         lb_debug_flag := TRUE;
      ELSE
         lb_debug_flag := FALSE;
      END IF;

      lc_err_location_msg :=
            'Parameters ==>'
         || CHR (13)
         || 'Debug flag : '
         || p_debug_flag
         || CHR (13)
         || 'Thread Id  : '
         || p_thread_id
         || CHR (13)
         || 'Thread_count : '
         || p_thread_count;
      XX_AR_EBL_COMMON_UTIL_PKG.
      PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

      OPEN c_txt_files;

      LOOP
         FETCH c_txt_files
         INTO ln_file_id, lc_file_name, lc_cust_doc_id;

         EXIT WHEN c_txt_files%NOTFOUND;

         BEGIN
            BEGIN
               SELECT DISTINCT file_creation_type, delimiter_char
                 INTO lc_file_creation_type, lc_delimiter_char
                 FROM xx_cdh_ebl_main
                WHERE cust_doc_id = lc_cust_doc_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lc_file_creation_type := NULL;
                  lc_delimiter_char := NULL;
            END;

            lc_err_location_msg :=
                  'File Creation Type : '
               || lc_file_creation_type
               || ' ,Delimiter Character : '
               || lc_delimiter_char;
            XX_AR_EBL_COMMON_UTIL_PKG.
            PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);

            IF lc_file_creation_type = 'DELIMITED'
               AND lc_delimiter_char = 'TAB'
            THEN
               lc_delimiter_char := CHR (9);
            END IF;

            lc_output_file :=
               UTL_FILE.FOPEN ('XXFIN_EBL_CONS',
                               lc_file_name,
                               'W',
                               32767);    --/app/ebs/ctgsidev02/xxfin/outbound
            lc_err_location_msg :=
                  'Cust Doc Id : '
               || lc_cust_doc_id
               || CHR (13)
               || 'File Name : '
               || lc_file_name
               || CHR (13)
               || 'File Id : '
               || ln_file_id;
            XX_AR_EBL_COMMON_UTIL_PKG.
            PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
            lc_err_location_msg := 'Rendering TXT Header Summary Data...';
            XX_AR_EBL_COMMON_UTIL_PKG.
            PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

            render_txt_hdr_summary_data (lc_cust_doc_id,
                                         ln_file_id,
                                         ln_org_id,
                                         lc_output_file,
                                         lc_file_creation_type,
                                         lc_delimiter_char,
                                         p_debug_flag,
                                         lc_hdr_error_flag,
                                         lc_hdr_error_msg);

            IF lc_hdr_error_flag = 'Y'
            THEN
               RAISE ex_hdr_render_exception_found;
            END IF;

            lc_err_location_msg := 'Rendering TXT Detail Data...';
            XX_AR_EBL_COMMON_UTIL_PKG.
            PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

            render_txt_dtl_data (lc_cust_doc_id,
                                 ln_file_id,
                                 ln_org_id,
                                 lc_output_file,
                                 lc_file_creation_type,
                                 lc_delimiter_char,
                                 p_debug_flag,
                                 lc_dtl_error_flag,
                                 lc_dtl_error_msg);

            IF lc_dtl_error_flag = 'Y'
            THEN
               RAISE ex_dtl_render_exception_found;
            END IF;

            lc_err_location_msg := 'Rendering TXT Trailer Data...';
            XX_AR_EBL_COMMON_UTIL_PKG.
            PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

            render_txt_trl_data (lc_cust_doc_id,
                                 ln_file_id,
                                 ln_org_id,
                                 lc_output_file,
                                 lc_file_creation_type,
                                 lc_delimiter_char,
                                 p_debug_flag,
                                 lc_trl_error_flag,
                                 lc_trl_error_msg);

            IF lc_trl_error_flag = 'Y'
            THEN
               RAISE ex_trl_render_exception_found;
            END IF;

            IF     lc_hdr_error_flag = 'N'
               AND lc_dtl_error_flag = 'N'
               AND lc_trl_error_flag = 'N'
            THEN
               BEGIN
                  lc_err_location_msg :=
                        'Rendering TXT is Successful for Cust Doc Id : '
                     || lc_cust_doc_id
                     || ' File Id '
                     || ln_file_id;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
                  UTL_FILE.FCLOSE (lc_output_file);
                  lb_src_file := BFILENAME ('XXFIN_EBL_CONS', lc_file_name);

                      SELECT file_data
                        INTO lb_dst_file
                        FROM xx_ar_ebl_file
                       WHERE file_id = ln_file_id
                  FOR UPDATE ;

                  DBMS_LOB.fileopen (lb_src_file, DBMS_LOB.file_readonly);
                  lgh_file := DBMS_LOB.getlength (lb_src_file);

                  IF lgh_file <> 0
                  THEN
                     DBMS_LOB.
                     loadfromfile (lb_dst_file, lb_src_file, lgh_file);
                  END IF;

                  lc_err_location_msg :=
                     'Rendering TXT is Successful, Updating TXT file in xx_ar_ebl_file table.';
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
                  xx_ar_ebl_txt_update_status (ln_file_id,
                                               lc_cust_doc_id,
                                               'RENDERED',
                                               lb_dst_file,
                                               NULL);
                  --Calling procedure to move data from main tables to history tables.(same procedure for XLS and TXT, parameter delivery method is different)
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  UPDATE_BILL_STATUS_eXLS (ln_file_id,
                                           'CONS',
                                           'eTXT',
                                           fnd_global.conc_request_id,
                                           p_debug_flag);
                  COMMIT;
                  DBMS_LOB.fileclose (lb_src_file);
                  lc_err_location_msg :=
                     'Checking file exists or not before Moving file to Archive Folder.';
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
                  UTL_FILE.fgetattr (location      => 'XXFIN_EBL_CONS',
                                     filename      => lc_file_name,
                                     fexists       => lb_file_exists,
                                     file_length   => ln_file_len,
                                     block_size    => lbi_blocksize);

                  IF lb_file_exists AND ln_file_len > 0
                  THEN
                     BEGIN
                        lc_err_location_msg :=
                           'File Exists. Moving file to Archive Folder.';
                        XX_AR_EBL_COMMON_UTIL_PKG.
                        PUT_LOG_LINE (lb_debug_flag,
                                      TRUE,
                                      lc_err_location_msg);
                        UTL_FILE.
                        fcopy (
                           'XXFIN_EBL_CONS',
                           lc_file_name,
                           'XXFIN_OUTBOUND_ARCH',
                           SUBSTR (lc_file_name,
                                   1,
                                   LENGTH (lc_file_name) - 4)
                           || TO_CHAR (SYSDATE, 'ddmmyyyhh24miss')
                           || '.TXT');
                        UTL_FILE.fremove ('XXFIN_EBL_CONS', lc_file_name);
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           RAISE ex_file_move_to_archieve;
                     END;
                  END IF;
               EXCEPTION
                  WHEN ex_file_move_to_archieve
                  THEN
                     UTL_FILE.fclose (lc_output_file);
                     lc_err_location_msg :=
                           'Error While moving the file to archive dir'
                        || ' - '
                        || SQLCODE
                        || ' - '
                        || SQLERRM;
                     XX_AR_EBL_COMMON_UTIL_PKG.
                     PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
                     xx_ar_ebl_txt_update_status (ln_file_id,
                                                  lc_cust_doc_id,
                                                  'RENDER_ERROR',
                                                  EMPTY_BLOB (),
                                                  lc_err_location_msg);
                  WHEN OTHERS
                  THEN
                     UTL_FILE.fclose (lc_output_file);
                     lc_err_location_msg :=
                           'Error While Updating BLOB'
                        || ' - '
                        || SQLCODE
                        || ' - '
                        || SQLERRM;
                     XX_AR_EBL_COMMON_UTIL_PKG.
                     PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
                     xx_ar_ebl_txt_update_status (ln_file_id,
                                                  lc_cust_doc_id,
                                                  'RENDER_ERROR',
                                                  EMPTY_BLOB (),
                                                  lc_err_location_msg);
               END;
            END IF;
         EXCEPTION
            WHEN UTL_FILE.invalid_path
            THEN
               UTL_FILE.fclose (lc_output_file);
               lc_err_location_msg :=
                  'Invalid File Path ' || SQLCODE || ' - ' || SQLERRM;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
               xx_ar_ebl_txt_update_status (ln_file_id,
                                            lc_cust_doc_id,
                                            'RENDER_ERROR',
                                            EMPTY_BLOB (),
                                            lc_err_location_msg);
            WHEN UTL_FILE.invalid_mode
            THEN
               UTL_FILE.fclose (lc_output_file);
               lc_err_location_msg :=
                  'Invalid Mode ' || SQLCODE || ' - ' || SQLERRM;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
               xx_ar_ebl_txt_update_status (ln_file_id,
                                            lc_cust_doc_id,
                                            'RENDER_ERROR',
                                            EMPTY_BLOB (),
                                            lc_err_location_msg);
            WHEN UTL_FILE.internal_error
            THEN
               UTL_FILE.fclose (lc_output_file);
               lc_err_location_msg :=
                  'Internal Error ' || SQLCODE || ' - ' || SQLERRM;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
               xx_ar_ebl_txt_update_status (ln_file_id,
                                            lc_cust_doc_id,
                                            'RENDER_ERROR',
                                            EMPTY_BLOB (),
                                            lc_err_location_msg);
            WHEN UTL_FILE.invalid_operation
            THEN
               UTL_FILE.fclose (lc_output_file);
               lc_err_location_msg :=
                  'Invalid Operation ' || SQLCODE || ' - ' || SQLERRM;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
               xx_ar_ebl_txt_update_status (ln_file_id,
                                            lc_cust_doc_id,
                                            'RENDER_ERROR',
                                            EMPTY_BLOB (),
                                            lc_err_location_msg);
            WHEN UTL_FILE.invalid_filehandle
            THEN
               UTL_FILE.fclose (lc_output_file);
               lc_err_location_msg :=
                  'Invalid File Handle ' || SQLCODE || ' - ' || SQLERRM;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
               xx_ar_ebl_txt_update_status (ln_file_id,
                                            lc_cust_doc_id,
                                            'RENDER_ERROR',
                                            EMPTY_BLOB (),
                                            lc_err_location_msg);
            WHEN UTL_FILE.write_error
            THEN
               UTL_FILE.fclose (lc_output_file);
               lc_err_location_msg :=
                  'Write Error ' || SQLCODE || ' - ' || SQLERRM;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
               xx_ar_ebl_txt_update_status (ln_file_id,
                                            lc_cust_doc_id,
                                            'RENDER_ERROR',
                                            EMPTY_BLOB (),
                                            lc_err_location_msg);
            WHEN ex_hdr_render_exception_found
            THEN
               UTL_FILE.fclose (lc_output_file);
               lc_err_location_msg := lc_hdr_error_msg;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
               xx_ar_ebl_txt_update_status (ln_file_id,
                                            lc_cust_doc_id,
                                            'RENDER_ERROR',
                                            EMPTY_BLOB (),
                                            lc_err_location_msg);
            WHEN ex_dtl_render_exception_found
            THEN
               UTL_FILE.fclose (lc_output_file);
               lc_err_location_msg := lc_dtl_error_msg;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
               xx_ar_ebl_txt_update_status (ln_file_id,
                                            lc_cust_doc_id,
                                            'RENDER_ERROR',
                                            EMPTY_BLOB (),
                                            lc_err_location_msg);
            WHEN ex_trl_render_exception_found
            THEN
               UTL_FILE.fclose (lc_output_file);
               lc_err_location_msg := lc_trl_error_msg;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
               xx_ar_ebl_txt_update_status (ln_file_id,
                                            lc_cust_doc_id,
                                            'RENDER_ERROR',
                                            EMPTY_BLOB (),
                                            lc_err_location_msg);
            WHEN ex_file_move_to_archieve
            THEN
               UTL_FILE.fclose (lc_output_file);
               lc_err_location_msg :=
                     'Error While moving the file to archive dir'
                  || ' - '
                  || SQLCODE
                  || ' - '
                  || SQLERRM;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
               xx_ar_ebl_txt_update_status (ln_file_id,
                                            lc_cust_doc_id,
                                            NULL,
                                            NULL,
                                            lc_err_location_msg);
            WHEN OTHERS
            THEN
               UTL_FILE.fclose (lc_output_file);
               lc_err_location_msg :=
                     'Error While Rendering TXT for Cust Doc Id : '
                  || lc_cust_doc_id
                  || ' File Id '
                  || ln_file_id
                  || ' - '
                  || SQLCODE
                  || ' - '
                  || SQLERRM;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
               xx_ar_ebl_txt_update_status (ln_file_id,
                                            lc_cust_doc_id,
                                            'RENDER_ERROR',
                                            EMPTY_BLOB (),
                                            lc_err_location_msg);
         END;
      END LOOP;

      CLOSE c_txt_files;
   EXCEPTION
      WHEN OTHERS
      THEN
         UTL_FILE.fclose (lc_output_file);
         lc_err_location_msg :=
               'Error While Rendering TXT for Cust Doc Id : '
            || lc_cust_doc_id
            || ' File Id '
            || ln_file_id
            || ' - '
            || SQLCODE
            || ' - '
            || SQLERRM;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
         xx_ar_ebl_txt_update_status (ln_file_id,
                                      lc_cust_doc_id,
                                      'RENDER_ERROR',
                                      EMPTY_BLOB (),
                                      lc_err_location_msg);
   END RENDER_TXT_C;

   -- +=====================================================================================+
   -- |                  Office Depot - Project Simplify                                    |
   -- +=====================================================================================+
   -- | Name        : GET_FORMATTED_ETXT_COLUMN                                             |
   -- | Description : This Function is used for framing the column with start and end       |
   -- |               positions with right/left justification based on configuration tables |
   -- |Parameters   : p_cust_doc_id                                                         |
   -- |             , p_justify                                                             |
   -- |             , p_start_position                                                      |
   -- |             , p_end_position                                                        |
   -- |             , p_fill_txt                                                            |
   -- |             , p_column_name                                                         |
   -- |             , p_debug_flag                                                          |
   -- |Change Record:                                                                       |
   -- |===============                                                                      |
   -- |Version   Date          Author                 Remarks                               |
   -- |=======   ==========   =============           ======================================|
   -- | 1.0      04-MAR-2016  Suresh N                Initial draft version                 |
   -- | 1.1      05-JAN-2017  Thilak CG               Defect# NAIT-22703                    |
   -- +=====================================================================================+
   FUNCTION GET_FORMATTED_ETXT_COLUMN (p_cust_doc_id      IN NUMBER,
                                       p_alignment        IN VARCHAR2,
                                       p_start_position   IN NUMBER,
                                       p_end_position     IN NUMBER,
                                       p_fill_txt         IN VARCHAR2,
                                       p_prepend_char     IN VARCHAR2,
                                       p_append_char      IN VARCHAR2,
                                       p_data_type        IN VARCHAR2,
                                       p_data_format      IN VARCHAR2,
                                       p_column_name      IN VARCHAR2,
                                       p_debug_flag       IN VARCHAR2,
                                       p_delimiter_char   IN VARCHAR2,
									   p_label            IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      lc_formatted_column   VARCHAR2 (1000);
      lc_column             VARCHAR2 (200);
	  lc_nodecimal          VARCHAR2 (100);
      lc_alignment          VARCHAR2 (10);
      lc_fill_txt           VARCHAR2 (200);
	  lc_decimal_flag       VARCHAR2 (5) := 'N';
      ln_position           NUMBER;
   BEGIN
      --fnd_file.put_line(fnd_file.log,'In the Formatted etxt column...Column Name : '||p_column_name||' - '||p_data_type||' - '||p_data_format);
      IF     p_data_type = 'VARCHAR2'
         AND p_delimiter_char IS NOT NULL
         AND p_delimiter_char != CHR (9)
      THEN
         lc_column :=
               'replace('
            || p_column_name
            || ','
            || ''''
            || p_delimiter_char
            || ''''
            || ','
            || ''' '''
            || ')';
      ELSE
         lc_column := p_column_name;
      END IF;

      IF p_alignment IS NULL
      THEN
         lc_alignment := 'LPAD';
      ELSE
         lc_alignment := p_alignment;
      END IF;

      IF RTRIM (LTRIM (p_fill_txt)) IS NULL
      THEN
         lc_fill_txt := ' ';
      ELSE
         lc_fill_txt := RTRIM (LTRIM (p_fill_txt));
      END IF;

      IF p_data_format IS NOT NULL
      THEN
         IF p_data_type = 'DATE'
         THEN
            lc_column :=
                  'TO_CHAR(TO_DATE('
               || lc_column
               || ','
               || '''YYYY-MM-DD'''
               || '),'
               || ''''
               || p_data_format
               || ''''
               || ')';
         ELSIF p_data_type = 'NUMERIC' AND p_data_format IS NOT NULL AND p_data_format <> 0  -- Added by Punit CG on 12-JUL-17 for Defect# defect #42321
         THEN
		    -- Added by Thilak CG on 05-JAN-18 for Defect# NAIT-22703
		    lc_nodecimal := NULL;
			lc_decimal_flag := 'N';


		    IF p_data_format = '9900'
			THEN
			lc_decimal_flag := 'Y';
		    lc_nodecimal := '*100';
			--lc_column := 'SUBSTR('||lc_column||',1,(INSTR('||lc_column||',''.'')+2))';
			lc_column := 'ltrim(rtrim(TO_CHAR('||lc_column||','||'''99999990.00'''||')))'; --added to fix bug NAIT-106275
			ELSIF p_data_format = '999000'
			THEN
			lc_decimal_flag := 'Y';
			lc_nodecimal := '*1000';
	        --lc_column := 'SUBSTR('||lc_column||',1,(INSTR('||lc_column||',''.'')+3))';
			lc_column := 'ltrim(rtrim(TO_CHAR('||lc_column||','||'''99999990.000'''||')))'; --added to fix bug NAIT-106275
			END IF;

			IF lc_decimal_flag = 'Y'
			THEN
            lc_column :=
                  'ltrim(rtrim('
               || lc_column || lc_nodecimal
               || '))';
			ELSE
            lc_column :=
                  'ltrim(rtrim(TO_CHAR('
               || lc_column
               || ','
               || ''''
               || p_data_format
               || ''''
               || ')))';
			END IF;
            -- End of Defect# NAIT-22703			-- Changes for the defect#41371

         END IF;
      END IF;

      IF p_prepend_char IS NOT NULL
      THEN
         lc_column := '''' || p_prepend_char || '''' || '||' || lc_column;
      END IF;

      IF p_append_char IS NOT NULL
      THEN
         lc_column := lc_column || '||' || '''' || p_append_char || '''';
      END IF;

      ln_position := p_end_position - p_start_position;

      IF lc_alignment = 'LPAD' AND p_end_position IS NOT NULL
      THEN
         ln_position := ln_position + 1;
         lc_formatted_column :=
               'rpad(nvl(substr('
            || lc_column
            || ',1,'
            || ln_position
            || '),'
            || ''' '''
            || '),'
            || ln_position
            || ','
            || ''''
            || lc_fill_txt
            || ''''
            || ')';
      ELSIF lc_alignment = 'RPAD' AND p_start_position IS NOT NULL
      THEN
         ln_position := ln_position + 1;
         lc_formatted_column :=
               'lpad(nvl(substr('
            || lc_column
            || ',1,'
            || ln_position
            || '),'
            || ''' '''
            || '),'
            || ln_position
            || ','
            || ''''
            || lc_fill_txt
            || ''''
            || ')';
      ELSE
         lc_formatted_column := lc_column;
      END IF;

      RETURN lc_formatted_column;
   END;

   -- +=====================================================================================+
   -- |                  Office Depot - Project Simplify                                    |
   -- +=====================================================================================+
   -- | Name        : GET_SORT_COLUMNS                                                      |
   -- | Description : This Function is used for framing the sort columns                    |
   -- |Parameters   : p_cust_doc_id                                                         |
   -- |             , p_trx_type                                                            |
   -- |Change Record:                                                                       |
   -- |===============                                                                      |
   -- |Version   Date          Author                 Remarks                               |
   -- |=======   ==========   =============           ======================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                 |
   -- +=====================================================================================+
   FUNCTION GET_SORT_COLUMNS (p_cust_doc_id   IN NUMBER,
                              p_record_type   IN VARCHAR2)
      RETURN VARCHAR2
   IS
      CURSOR c_sort_columns
      IS
           SELECT sort_col_num,
                  sort_order,
                  sort_type,
                  data_type
             FROM (SELECT ROWNUM sort_col_num,
                          sort_order,
                          sort_type,
                          data_type
                     FROM (SELECT xcetdt.seq record_order,
                                  xcetdt.sort_order,
                                  NVL (xcetdt.sort_type, ' ') sort_type,
                                  xftv.target_value1 data_type
                             FROM xx_fin_translatedefinition xftd,
                                  xx_fin_translatevalues xftv,
                                  xx_cdh_ebl_templ_dtl_txt xcetdt
                            WHERE     xftd.translate_id = xftv.translate_id
                                  AND xftv.source_value1 = xcetdt.field_id
                                  AND xcetdt.cust_doc_id = p_cust_doc_id
                                  AND xcetdt.record_type = p_record_type
								  AND xcetdt.rownumber = 1
                                  AND xftd.translation_name = 'XX_CDH_EBL_TXT_DET_FIELDS'
								  AND xftv.target_value19 = 'DT'
                                  AND xftv.enabled_flag = 'Y'
                                  AND TRUNC (SYSDATE) BETWEEN TRUNC (
                                                                 xftv.
                                                                 start_date_active)
                                                          AND TRUNC (
                                                                 NVL (
                                                                    xftv.
                                                                    end_date_active,
                                                                    SYSDATE + 1))
                                  AND xcetdt.attribute20 = 'Y'
                           UNION
                           SELECT xcetdt.seq record_order,
                                  xcetdt.sort_order,
                                  NVL (xcetdt.sort_type, ' ') sort_type,
                                  'VARCHAR2' data_type
                             FROM xx_cdh_ebl_templ_dtl_txt xcetdt,
                                  xx_cdh_ebl_concat_fields_txt xcecft
                            WHERE     xcetdt.field_id = xcecft.conc_field_id
                                  AND xcetdt.cust_doc_id = xcecft.cust_doc_id
                                  AND xcetdt.cust_doc_id = p_cust_doc_id
                                  AND xcetdt.record_type = p_record_type
								  AND xcetdt.rownumber = 1
                           UNION     -- Query to get the Split Columns Columns
                           SELECT xcetdt.seq,
                                  xcetdt.sort_order,
                                  NVL (xcetdt.sort_type, ' ') sort_type,
                                  'VARCHAR2' data_type
                             FROM xx_cdh_ebl_templ_dtl_txt xcetdt
                            WHERE     cust_doc_id = p_cust_doc_id
                                  AND record_type = p_record_type
								  AND rownumber = 1
                                  AND base_field_id IS NOT NULL
                                  AND attribute20 = 'Y'
                           ORDER BY record_order))
            WHERE sort_order IS NOT NULL AND sort_type IS NOT NULL
         ORDER BY 2;

      lc_sort_columns   VARCHAR2 (2000) := NULL;
   BEGIN
      --query to get the column number
      FOR sort_columns IN c_sort_columns
      LOOP
            lc_sort_columns :=
                  lc_sort_columns
               || 'XTDS.COLUMN'
               || sort_columns.sort_col_num
               || ' '
               || sort_columns.sort_type
               || ',';
      END LOOP;

      RETURN lc_sort_columns;
   END;

   -- +=====================================================================================+
   -- |                  Office Depot - Project Simplify                                    |
   -- +=====================================================================================+
   -- | Name        : RENDER_TXT_HDR_SUMMARY_DATA                                           |
   -- | Description : This Procedure is used for framing the sql based on                   |
   -- |               Header Summary data and write it into TXT file.                       |
   -- |Parameters   : p_cust_doc_id                                                         |
   -- |             , p_file_id                                                             |
   -- |             , p_org_id                                                              |
   -- |             , p_output_file                                                         |
   -- |             , p_debug_flag                                                          |
   -- |             , p_error_flag                                                          |
   -- |Change Record:                                                                       |
   -- |===============                                                                      |
   -- |Version   Date          Author                 Remarks                               |
   -- |=======   ==========   =============           ======================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                 |
   -- |      1.1 25-MAY-2017  Punit Gupta CG          Changes done for defect raised in UAT |
   -- |      1.2 18-May-2018  Aniket J    CG          Changes for Requirement  #NAIT-36070  |
   -- +=====================================================================================+
   PROCEDURE RENDER_TXT_HDR_SUMMARY_DATA (
      p_cust_doc_id          IN     NUMBER,
      p_file_id              IN     NUMBER,
      p_org_id               IN     NUMBER,
      p_output_file          IN     UTL_FILE.FILE_TYPE,
      p_file_creation_type   IN     VARCHAR2,
      p_delimiter_char       IN     VARCHAR2,
      p_debug_flag           IN     VARCHAR2,
      p_hdr_error_flag          OUT VARCHAR2,
      p_hdr_error_msg           OUT VARCHAR2)
   IS
      CURSOR get_dist_rows
      IS
           SELECT DISTINCT rownumber
             FROM xx_cdh_ebl_templ_hdr_txt
            WHERE cust_doc_id = p_cust_doc_id           --AND attribute1 = 'Y'
              AND attribute20 = 'Y'
         ORDER BY rownumber;

      CURSOR c_hdr_summary_fields (
         p_rownum IN NUMBER)
      IS
         SELECT TO_NUMBER (xftv.source_value1) field_id,
                xcetht.seq,
                xcetht.label,
                xftv.target_value1 data_type,
                xcetht.cust_doc_id,
                xcetht.rownumber rec_order                --Formatting columns
                                          ,
                xcetht.data_format,
                xcetht.start_txt_pos,
                xcetht.end_txt_pos,
                xcetht.fill_txt_pos,
                xcetht.alignment,
                xcetht.start_val_pos,
                xcetht.end_val_pos,
                xcetht.prepend_char,
                xcetht.append_char,
				--Start Added by Aniket CG 15 May #NAIT-36070
				xftv.target_value24,
                xftv.source_value4
				--End Added by Aniket CG 15 May #NAIT-36070
           FROM xx_fin_translatedefinition xftd,
                xx_fin_translatevalues xftv,
                xx_cdh_ebl_templ_hdr_txt xcetht
          WHERE     xftd.translate_id = xftv.translate_id
                AND xftv.source_value1 = xcetht.field_id
                AND xcetht.cust_doc_id = p_cust_doc_id
                AND xcetht.rownumber = p_rownum
                AND xftd.translation_name = 'XX_CDH_EBL_TXT_HDR_FIELDS'
                AND xftv.target_value19 = 'DT' -- Uncommented by Punit on 25-MAY-2017
                AND xftv.enabled_flag = 'Y'
                AND TRUNC (SYSDATE) BETWEEN TRUNC (xftv.start_date_active)
                                        AND TRUNC (
                                               NVL (xftv.end_date_active,
                                                    SYSDATE + 1))
                --AND xcetht.attribute1 = 'Y'
                AND xcetht.attribute20 = 'Y'
         UNION
         SELECT xcetht.field_id field_id,
                xcetht.seq,
                xcetht.label,
                'VARCHAR2' data_type,
                xcetht.cust_doc_id,
                xcetht.rownumber rec_order                --Formatting columns
                                          ,
                xcetht.data_format,
                xcetht.start_txt_pos,
                xcetht.end_txt_pos,
                xcetht.fill_txt_pos,
                xcetht.alignment,
                xcetht.start_val_pos,
                xcetht.end_val_pos,
                xcetht.prepend_char,
                xcetht.append_char,
					--Start Added by Aniket CG 15 May #NAIT-36070
				NULL,
                NULL
				--End Added by Aniket CG 15 May #NAIT-36070
           FROM xx_cdh_ebl_templ_hdr_txt xcetht,
                xx_cdh_ebl_concat_fields_txt xcecft
          WHERE     xcetht.field_id = xcecft.conc_field_id
                AND xcetht.cust_doc_id = xcecft.cust_doc_id
                AND xcetht.cust_doc_id = p_cust_doc_id
                AND xcetht.rownumber = p_rownum
         ORDER BY rec_order, seq;

      lc_column             VARCHAR2 (20) := 'COLUMN';
      ln_count              NUMBER := 1;

      TYPE lc_ref_cursor IS REF CURSOR;

      lc_cursor             lc_ref_cursor;
      lc_txt_line           VARCHAR2 (32767);
      lc_build_hdr_sql      VARCHAR2 (32767);
      lc_build_hdr_label    VARCHAR2 (32767) := NULL;
      lc_row_order          NUMBER;
      lc_err_location_msg   VARCHAR2 (32767);
      lb_debug_flag         BOOLEAN;
      lc_print_hdr_label    VARCHAR2 (1);
      lc_hdr_col_label      VARCHAR2 (200);
	   --Start Added by Aniket CG 15 May #NAIT-36070
      ln_total_rec_cnt      NUMBER := 0;
      ln_total_hdr_rec_cnt  NUMBER := 0;
      ln_total_trl_rec_cnt  NUMBER := 0;
      ln_total_dtl_rec_cnt  NUMBER := 0;
      lc_update_column      VARCHAR2 (32767);
      ln_total_rec_nbl_cnt      NUMBER := 0;
      ln_total_hdr_rec_nbl_cnt  NUMBER := 0;
      ln_total_trl_rec_nbl_cnt  NUMBER := 0;
      ln_total_dtl_rec_nbl_cnt  NUMBER := 0;
      lc_update_nbl_column    VARCHAR2 (32767);
      ln_total_dtl_cnt        NUMBER := 0;
      ln_total_dtl_sku_cnt    NUMBER := 0;
      ln_total_dtl_inv_cnt    NUMBER := 0;
      --End Added by Aniket CG 15 May #NAIT-36070
   BEGIN
      IF (p_debug_flag = 'Y')
      THEN
         lb_debug_flag := TRUE;
      ELSE
         lb_debug_flag := FALSE;
      END IF;

      lc_err_location_msg := 'In Render Header Summary Data ';
      XX_AR_EBL_COMMON_UTIL_PKG.
      PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);

      BEGIN
         SELECT DISTINCT NVL (include_label, 'N')
           INTO lc_print_hdr_label
           FROM xx_cdh_ebl_templ_hdr_txt
          WHERE cust_doc_id = p_cust_doc_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            lc_print_hdr_label := 'N';
      END;

      --Build the cursor to write the header summary data into eTXT File.
      OPEN get_dist_rows;

      LOOP
         FETCH get_dist_rows INTO lc_row_order;

         EXIT WHEN get_dist_rows%NOTFOUND;
         lc_build_hdr_label := NULL;

         FOR lc_hdr_summary_fields IN c_hdr_summary_fields (lc_row_order)
         LOOP
            fnd_file.put_line (fnd_file.LOG, p_cust_doc_id);

			 --Start Added by Aniket CG 15 May #NAIT-36070
              BEGIN
                IF LOWER(lc_hdr_summary_fields.target_value24) = 'xx_ar_ebl_txt_spl_logic_pkg.get_total_rec_count' AND UPPER(lc_hdr_summary_fields.source_value4) = 'TOTAL_REC_CNT_NBL' THEN
                  ln_total_hdr_rec_nbl_cnt                    := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_HDR_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'N') ;
                  ln_total_trl_rec_nbl_cnt                    := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_TRL_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'N') ;
                  ln_total_dtl_rec_nbl_cnt                    := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_DTL_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'N') ;
                  ln_total_rec_nbl_cnt                        := ln_total_hdr_rec_nbl_cnt+ln_total_trl_rec_nbl_cnt + ln_total_dtl_rec_nbl_cnt;
                  lc_update_nbl_column                        := 'UPDATE xx_ar_ebl_txt_hdr_stg SET ' || lc_column || ln_count ||' = '|| ln_total_rec_nbl_cnt || '
              where  rec_type != ' ||'''FID'' and file_id =' || p_file_id || ' and rec_order = ' || lc_row_order ;
                  fnd_file.put_line (fnd_file.LOG, 'In Count with No Lable ' || ln_total_rec_nbl_cnt );
                  EXECUTE IMMEDIATE lc_update_nbl_column;
                ELSIF LOWER(lc_hdr_summary_fields.target_value24) = 'xx_ar_ebl_txt_spl_logic_pkg.get_total_rec_count' AND UPPER(lc_hdr_summary_fields.source_value4) = 'TOTAL_REC_CNT_LBL' THEN
                  ln_total_hdr_rec_cnt                           := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_HDR_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'Y') ;
                  ln_total_trl_rec_cnt                           := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_TRL_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'Y') ;
                  ln_total_dtl_rec_cnt                           := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_DTL_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'Y') ;
                  ln_total_rec_cnt                               := ln_total_hdr_rec_cnt+ln_total_trl_rec_cnt + ln_total_dtl_rec_cnt;
                  lc_update_column                               := 'UPDATE xx_ar_ebl_txt_hdr_stg SET ' || lc_column || ln_count ||' = '|| ln_total_rec_cnt || '
              where  rec_type != ' ||'''FID'' and file_id =' || p_file_id || ' and rec_order = ' || lc_row_order ;
                  fnd_file.put_line (fnd_file.LOG, ' In count  WITH LABEL ' || ln_total_rec_cnt );
                  EXECUTE IMMEDIATE lc_update_column;
                ELSIF LOWER(lc_hdr_summary_fields.target_value24) = 'xx_ar_ebl_txt_spl_logic_pkg.get_total_rec_count' AND UPPER(lc_hdr_summary_fields.source_value4) = 'TOTAL_REC_CNT' THEN
                  ln_total_dtl_inv_cnt                           := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_INV_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'INV') ;
                  lc_update_column                               := 'UPDATE xx_ar_ebl_txt_hdr_stg SET ' || lc_column || ln_count ||' = '|| ln_total_dtl_inv_cnt || '
              where  rec_type != ' ||'''FID'' and file_id =' || p_file_id || ' and rec_order = ' || lc_row_order ;
                  fnd_file.put_line (fnd_file.LOG, 'wave4 - WITH INV COUNT ' || ln_total_dtl_inv_cnt );
                  EXECUTE IMMEDIATE lc_update_column;
                ELSIF LOWER(lc_hdr_summary_fields.target_value24) = 'xx_ar_ebl_txt_spl_logic_pkg.get_total_rec_count' AND UPPER(lc_hdr_summary_fields.source_value4) = 'TOTAL_REC_CNT_SKU' THEN
                  ln_total_dtl_sku_cnt                           := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_INV_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'SKU') ;
                  lc_update_column                               := 'UPDATE xx_ar_ebl_txt_hdr_stg SET ' || lc_column || ln_count ||' = '|| ln_total_dtl_sku_cnt || '
              where  rec_type != ' ||'''FID'' and file_id =' || p_file_id || ' and rec_order = ' || lc_row_order ;
                  fnd_file.put_line (fnd_file.LOG, ' In count SKU COUNT ' || ln_total_dtl_sku_cnt );
                  EXECUTE IMMEDIATE lc_update_column;
                ELSIF LOWER(lc_hdr_summary_fields.target_value24) = 'xx_ar_ebl_txt_spl_logic_pkg.get_total_rec_count' AND UPPER(lc_hdr_summary_fields.source_value4) = 'TOTAL_REC_CNT_DTL' THEN
                  ln_total_dtl_cnt                               := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_INV_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'DTL') ;
                  lc_update_column                               := 'UPDATE xx_ar_ebl_txt_hdr_stg SET ' || lc_column || ln_count ||' = '|| ln_total_dtl_cnt || '
              where  rec_type != ' ||'''FID'' and file_id =' || p_file_id || ' and rec_order = ' || lc_row_order ;
                  fnd_file.put_line (fnd_file.LOG, ' IN Count  WITH DTL COUNT ' || ln_total_dtl_cnt );
                  EXECUTE IMMEDIATE lc_update_column;
                END IF;
              EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line (fnd_file.LOG, ' Error In Updating Counts ' || SQLERRM );
              END;
              -- END Added by Aniket CG 15 May #NAIT-36070

            IF p_file_creation_type = 'DELIMITED'
            THEN
               lc_build_hdr_sql :=
                  lc_build_hdr_sql
                  || get_formatted_etxt_column (
                        p_cust_doc_id,
                        lc_hdr_summary_fields.alignment,
                        lc_hdr_summary_fields.start_val_pos,
                        lc_hdr_summary_fields.end_val_pos,
                        lc_hdr_summary_fields.fill_txt_pos,
                        lc_hdr_summary_fields.prepend_char,
                        lc_hdr_summary_fields.append_char,
                        lc_hdr_summary_fields.data_type,
                        lc_hdr_summary_fields.data_format,
                        lc_column || ln_count,
                        p_debug_flag,
                        p_delimiter_char)
                  || '||'
                  || ''''
                  || p_delimiter_char
                  || ''''
                  || '||';
               lc_build_hdr_label :=
                     lc_build_hdr_label
                  || lc_hdr_summary_fields.label
                  || p_delimiter_char;
               ln_count := ln_count + 1;
            ELSIF p_file_creation_type = 'FIXED'
            THEN
               lc_build_hdr_sql :=
                  lc_build_hdr_sql
                  || get_formatted_etxt_column (
                        p_cust_doc_id,
                        lc_hdr_summary_fields.alignment,
                        lc_hdr_summary_fields.start_val_pos,
                        lc_hdr_summary_fields.end_val_pos,
                        lc_hdr_summary_fields.fill_txt_pos,
                        lc_hdr_summary_fields.prepend_char,
                        lc_hdr_summary_fields.append_char,
                        lc_hdr_summary_fields.data_type,
                        lc_hdr_summary_fields.data_format,
                        lc_column || ln_count,
                        p_debug_flag,
                        NULL)
                  || '||';
               lc_hdr_col_label := NULL;

               BEGIN
                  SELECT LPAD (lc_hdr_summary_fields.label,
                               ((lc_hdr_summary_fields.end_txt_pos - lc_hdr_summary_fields.start_txt_pos) +1), --Changed for Defect # 44465 -- lc_hdr_summary_fields.start_val_pos,
                               ' ')
                    INTO lc_hdr_col_label
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lc_hdr_col_label := NULL;
               END;

               lc_build_hdr_label := lc_build_hdr_label || lc_hdr_col_label;
               ln_count := ln_count + 1;
            END IF;
         END LOOP;                                      --c_hdr_summary_fields

         IF p_file_creation_type = 'DELIMITED'
         THEN
            lc_build_hdr_sql :=
               SUBSTR (
                  lc_build_hdr_sql,
                  1,
                  (LENGTH (lc_build_hdr_sql) - LENGTH (p_delimiter_char) - 6));
            lc_build_hdr_label :=
               SUBSTR (
                  lc_build_hdr_label,
                  1,
                  (LENGTH (lc_build_hdr_label) - LENGTH (p_delimiter_char)));
         ELSIF p_file_creation_type = 'FIXED'
         THEN
            lc_build_hdr_sql :=
               SUBSTR (lc_build_hdr_sql, 1, (LENGTH (lc_build_hdr_sql) - 2));
         END IF;

         lc_err_location_msg := 'Selected Columns : ' || lc_build_hdr_sql;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);

         lc_build_hdr_sql :=
               'SELECT DISTINCT '
            || lc_build_hdr_sql
            || ' FROM XX_AR_EBL_TXT_HDR_STG WHERE file_id = '
            || p_file_id
            || ' AND REC_TYPE != '
            || '''FID'''
            || ' AND REC_ORDER = '
            || lc_row_order;
         lc_err_location_msg := 'Header Summary SQL : ' || lc_build_hdr_sql;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);

         IF lc_print_hdr_label = 'Y' AND ln_count > 2
         THEN
            UTL_FILE.put_line (p_output_file, lc_build_hdr_label || CHR (13));
            UTL_FILE.fflush (p_output_file);
         ELSIF lc_print_hdr_label = 'Y'
         THEN
            UTL_FILE.put (p_output_file, lc_build_hdr_label || CHR (13));
            UTL_FILE.put (p_output_file, '     ');
            UTL_FILE.fflush (p_output_file);
         END IF;

         OPEN lc_cursor FOR lc_build_hdr_sql;

         LOOP
            FETCH lc_cursor INTO lc_txt_line;

            EXIT WHEN lc_cursor%NOTFOUND;
            lc_err_location_msg := 'Header Line : ' || lc_txt_line;
            XX_AR_EBL_COMMON_UTIL_PKG.
            PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
            UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
            UTL_FILE.fflush (p_output_file);
         END LOOP;                                          --lc_build_hdr_sql

         lc_build_hdr_sql := NULL;
         ln_count := 1;
      END LOOP;                                                --get_dist_rows

      CLOSE get_dist_rows;
      p_hdr_error_flag := 'N';
   EXCEPTION
      WHEN OTHERS
      THEN
         lc_err_location_msg :=
               'Error While Rendering Header Summary Data for Cust Doc Id : '
            || p_cust_doc_id
            || ' - '
            || 'File Id : '
            || p_file_id
            || ' - '
            || SQLCODE
            || ' - '
            || SQLERRM;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
         p_hdr_error_flag := 'Y';
         p_hdr_error_msg := lc_err_location_msg;
   END RENDER_TXT_HDR_SUMMARY_DATA;

   -- +=====================================================================================+
   -- |                  Office Depot - Project Simplify                                    |
   -- +=====================================================================================+
   -- | Name        : RENDER_TXT_DTL_DATA                                                   |
   -- | Description : This Procedure is used for framing the sql based on                   |
   -- |               Detail(Header/Lines/Dist Lines) data and write it into TXT file.      |
   -- |Parameters   : p_cust_doc_id                                                         |
   -- |             , p_file_id                                                             |
   -- |             , p_org_id                                                              |
   -- |             , p_output_file                                                         |
   -- |             , p_debug_flag                                                          |
   -- |             , p_error_flag                                                          |
   -- |Change Record:                                                                       |
   -- |===============                                                                      |
   -- |Version   Date          Author                 Remarks                               |
   -- |=======   ==========   =============           ======================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                 |
   -- |1.1       21-MAR-2017  Suresh N                Changes done for the defect#38962     |
   -- |1.2       25-MAY-2017  Punit Gupta CG          Changes done for defect raised in UAT |
   -- |1.3       12-JUL-2017  Punit Gupta CG          Changes for the defect#41307          |
   -- |1.4       12-OCT-2017  Thilak CG               Changes for the UAT defect#13836      |
   -- |1.5       14-OCT-2017  Thilak CG               Changes for the UAT defect#14189      |
   -- +=====================================================================================+
   PROCEDURE RENDER_TXT_DTL_DATA (p_cust_doc_id          IN     NUMBER,
                                  p_file_id              IN     NUMBER,
                                  p_org_id               IN     NUMBER,
                                  p_output_file          IN     UTL_FILE.FILE_TYPE,
                                  p_file_creation_type   IN     VARCHAR2,
                                  p_delimiter_char       IN     VARCHAR2,
                                  p_debug_flag           IN     VARCHAR2,
                                  p_dtl_error_flag          OUT VARCHAR2,
                                  p_dtl_error_msg           OUT VARCHAR2)
   IS
      -- Added and Modified by Punit on 12-JUL-2017 for Defect # 41307
     /* CURSOR get_dist_custtrx (p_sort_columns IN VARCHAR2)
      IS
	       SELECT customer_trx_id FROM
		   (SELECT *
             FROM xx_ar_ebl_txt_dtl_stg
             WHERE file_id = p_file_id
             AND cust_doc_id = p_cust_doc_id
             AND rec_type != 'FID'
			 AND trx_line_number = 1
			 AND customer_trx_id IS NOT NULL
		    ORDER BY p_sort_columns); */ -- Added by Thilak CG on 14-OCT-2017 for Defect#14189

       CURSOR c_get_dist_record_type (p_customer_trx_id IN NUMBER)
      IS
           SELECT DISTINCT record_type
             FROM xx_cdh_ebl_templ_dtl_txt xcedt,
			      xx_ar_ebl_txt_dtl_stg  xaebtds
            WHERE xcedt.cust_doc_id = xaebtds.cust_doc_id
			AND   xcedt.attribute20 = 'Y'
            AND   xaebtds.file_id = p_file_id
            AND   xcedt.cust_doc_id = p_cust_doc_id
			AND xaebtds.customer_trx_id = p_customer_trx_id
         ORDER BY record_type;

		CURSOR get_dist_rows (p_record_type IN VARCHAR2)
      IS
           SELECT DISTINCT xcedt.rownumber
             FROM xx_cdh_ebl_templ_dtl_txt xcedt
            WHERE xcedt.attribute20 = 'Y'
            AND   xcedt.cust_doc_id = p_cust_doc_id
			AND   xcedt.record_type = p_record_type
         ORDER BY xcedt.rownumber;

      ln_get_line_dist_rows      NUMBER;

      /*CURSOR get_dist_rows (p_customer_trx_id IN NUMBER)
      IS
           SELECT DISTINCT xcedt.rownumber
             FROM xx_cdh_ebl_templ_dtl_txt xcedt,
			      xx_ar_ebl_txt_dtl_stg  xaebtds
            WHERE xcedt.cust_doc_id = xaebtds.cust_doc_id
			AND xcedt.attribute20 = 'Y'
            AND xaebtds.file_id = p_file_id
            AND xcedt.cust_doc_id = p_cust_doc_id
			AND xaebtds.customer_trx_id = p_customer_trx_id
         ORDER BY xcedt.rownumber;

      ln_get_line_dist_rows      NUMBER;

      CURSOR c_get_dist_record_type (p_rownum IN NUMBER)
      IS
           SELECT DISTINCT record_type
             FROM xx_cdh_ebl_templ_dtl_txt
            WHERE cust_doc_id = p_cust_doc_id
			AND rownumber = p_rownum -- Added by Punit on 12-JUL-2017 for Defect # 41307
         ORDER BY record_type;*/

      CURSOR c_get_dtl_fields_info (
         p_record_type   IN VARCHAR2,
         p_rownum        IN NUMBER)
      IS
         -- End of Added and Modified by Punit on 12-JUL-2017 for Defect # 41307
         SELECT TO_NUMBER (xftv.source_value1) field_id,
                xcetdt.seq record_order,
                xcetdt.label,
                xftv.target_value1 data_type,
                xcetdt.cust_doc_id,
                xcetdt.rownumber rec_order -- Added rec_order column by Punit for Defect# 41307
                                          --Formatting columns
                ,
                xcetdt.data_format,
                xcetdt.start_txt_pos,
                xcetdt.end_txt_pos,
                xcetdt.fill_txt_pos,
                xcetdt.alignment,
                xcetdt.start_val_pos,
                xcetdt.end_val_pos,
                xcetdt.prepend_char,
                xcetdt.append_char,
				xcetdt.sort_order,
				xcetdt.sort_type,
				xftv.source_value4 col_name
           FROM xx_fin_translatedefinition xftd,
                xx_fin_translatevalues xftv,
                xx_cdh_ebl_templ_dtl_txt xcetdt
          WHERE     xftd.translate_id = xftv.translate_id
                AND xftv.source_value1 = xcetdt.field_id
                AND xcetdt.cust_doc_id = p_cust_doc_id
                AND xcetdt.record_type = p_record_type
                AND xcetdt.rownumber = p_rownum -- Added by Punit on 12-JUL-2017 for Defect # 41307
                AND xftd.translation_name = 'XX_CDH_EBL_TXT_DET_FIELDS'
                AND xftv.target_value19 = 'DT' -- Uncommented by Punit on 25-MAY-2017
                AND xftv.enabled_flag = 'Y'
                AND TRUNC (SYSDATE) BETWEEN TRUNC (xftv.start_date_active)
                                        AND TRUNC (
                                               NVL (xftv.end_date_active,
                                                    SYSDATE + 1))
                AND xcetdt.attribute20 = 'Y'
         UNION
         SELECT xcetdt.field_id field_id,
                xcetdt.seq record_order,
                xcetdt.label,
                'VARCHAR2' data_type,
                xcetdt.cust_doc_id,
                xcetdt.rownumber rec_order -- Added rec_order column by Punit for Defect# 41307
                                          --Formatting columns
                ,
                xcetdt.data_format,
                xcetdt.start_txt_pos,
                xcetdt.end_txt_pos,
                xcetdt.fill_txt_pos,
                xcetdt.alignment,
                xcetdt.start_val_pos,
                xcetdt.end_val_pos,
                xcetdt.prepend_char,
                xcetdt.append_char,
				xcetdt.sort_order,
				xcetdt.sort_type,
				NULL col_name
           FROM xx_cdh_ebl_templ_dtl_txt xcetdt,
                xx_cdh_ebl_concat_fields_txt xcecft
          WHERE     xcetdt.field_id = xcecft.conc_field_id
                AND xcetdt.cust_doc_id = xcecft.cust_doc_id
                AND xcetdt.cust_doc_id = p_cust_doc_id
                AND xcetdt.record_type = p_record_type
                AND xcetdt.rownumber = p_rownum -- Added by Punit on 12-JUL-2017 for Defect # 41307
         UNION                       -- Query to get the Split Columns Columns
         SELECT xcetdt.field_id field_id,
                xcetdt.seq record_order,
                xcetdt.label,
                'VARCHAR2' data_type,
                xcetdt.cust_doc_id,
                xcetdt.rownumber rec_order -- Added rec_order column by Punit for Defect# 41307
                                          --Formatting columns
                ,
                xcetdt.data_format,
                xcetdt.start_txt_pos,
                xcetdt.end_txt_pos,
                xcetdt.fill_txt_pos,
                xcetdt.alignment,
                xcetdt.start_val_pos,
                xcetdt.end_val_pos,
                xcetdt.prepend_char,
                xcetdt.append_char,
				xcetdt.sort_order,
				xcetdt.sort_type,
				NULL col_name
           FROM xx_cdh_ebl_templ_dtl_txt xcetdt
          WHERE     cust_doc_id = p_cust_doc_id
                AND record_type = p_record_type
                AND xcetdt.rownumber = p_rownum -- Added by Punit on 12-JUL-2017 for Defect # 41307
                AND base_field_id IS NOT NULL
                AND attribute20 = 'Y'
         ORDER BY record_order;

      CURSOR c_get_summary_fields_info
      IS
           SELECT TO_NUMBER (xftv.source_value1) field_id,
                  xcetdt.seq record_order,
                  xcetdt.label,
                  xftv.target_value1 data_type,
                  xcetdt.cust_doc_id,
                  xcetdt.data_format,
                  xcetdt.start_txt_pos,
                  xcetdt.end_txt_pos,
                  xcetdt.fill_txt_pos,
                  xcetdt.alignment,
                  xcetdt.start_val_pos,
                  xcetdt.end_val_pos,
                  xcetdt.prepend_char,
                  xcetdt.append_char,
				  xcetdt.sort_order,
				  xcetdt.sort_type,
				  xcetdt.record_type,
				  xftv.source_value4 col_name
             FROM xx_fin_translatedefinition xftd,
                  xx_fin_translatevalues xftv,
                  xx_cdh_ebl_templ_dtl_txt xcetdt
            WHERE     xftd.translate_id = xftv.translate_id
                  AND XFTV.SOURCE_VALUE1 = XCETDT.FIELD_ID
                  AND XCETDT.CUST_DOC_ID = p_cust_doc_id
                  AND xftd.translation_name = 'XX_CDH_EBL_TXT_DET_FIELDS'
                  AND xftv.target_value19 = 'DT' -- Uncommented by Punit on 25-MAY-2017
                  AND xftv.enabled_flag = 'Y'
                  AND TRUNC (SYSDATE) BETWEEN TRUNC (XFTV.START_DATE_ACTIVE)
                                          AND TRUNC (
                                                 NVL (XFTV.END_DATE_ACTIVE,
                                                      SYSDATE + 1))
                  AND xcetdt.attribute20 = 'Y'
         ORDER BY record_order;

      lc_column                  VARCHAR2 (20) := 'COLUMN';
      ln_count                   NUMBER := 1;

      TYPE lc_ref_cursor IS REF CURSOR;

      c_dtl_hdr_cursor           lc_ref_cursor;
      c_dtl_line_cursor          lc_ref_cursor;
      c_dtl_dist_line_cursor     lc_ref_cursor;
	  c_get_dist_custtrx         lc_ref_cursor;
      lc_txt_line                VARCHAR2 (32767);
	  ln_hdr_repeat_cnt          NUMBER := 0;
	  ln_dtl_repeat_cnt          NUMBER := 0;
	  ln_dist_repeat_cnt         NUMBER := 0;
      ln_max_rownum	             NUMBER := 0;
	  ln_hdr_cnt                 NUMBER;
      ln_customer_trx_id         NUMBER;
      ln_customer_trx_line_id    NUMBER;
      lc_build_dtl_sql           VARCHAR2 (32767) := NULL;
      lc_build_dtl_label         VARCHAR2 (32767) := NULL;
      lc_trx_type                VARCHAR2 (30);
      lc_dtl_hdr_sql             VARCHAR2 (32767);
      lc_dtl_lines_sql           VARCHAR2 (32767);
      lc_dtl_dist_lines_sql      VARCHAR2 (32767);
      lc_err_location_msg        VARCHAR2 (32767);
      lb_debug_flag              BOOLEAN;
      lc_hdr_exists              VARCHAR2 (1);
      lc_line_exists             VARCHAR2 (1);
      lc_dist_exists             VARCHAR2 (1);
      lc_print_dtl_label         VARCHAR2 (1);
      lc_repeat_dtl_header       VARCHAR2 (1);
      lc_dtl_col_label           VARCHAR2 (200);
      lc_build_dtl_hdr_label     VARCHAR2 (32767);
      lc_build_dtl_line_label    VARCHAR2 (32767);
      lc_build_dtl_dist_label    VARCHAR2 (32767);
	  lc_custtrx_hdr_sort_cols   VARCHAR2 (2000);
	  lc_custtrx_line_sort_cols  VARCHAR2 (2000);
	  lc_custtrx_sort_columns    VARCHAR2 (2000);
      lc_dtl_hdr_sort_columns    VARCHAR2 (2000);
      lc_dtl_line_sort_columns   VARCHAR2 (2000);
      lc_dtl_dist_sort_columns   VARCHAR2 (2000);
	  ln_get_customer_trx_id     NUMBER := 0;
      --lc_txt_line_previous               VARCHAR2(32767) := NULL;    --Commented for Defect#41426
      --lc_txt_line_current                VARCHAR2(32767) := NULL;    --Commented for Defect#41426
      lc_summary_bill_doc        VARCHAR2 (1);
	  lc_sort_columns            VARCHAR2 (5000)  := NULL;
      lc_summary_build_sql       VARCHAR2 (32767) := NULL;
      lc_summary_build_label     VARCHAR2 (32767) := NULL;
   BEGIN
      IF (p_debug_flag = 'Y')
      THEN
         lb_debug_flag := TRUE;
      ELSE
         lb_debug_flag := FALSE;
      END IF;

      lc_err_location_msg := 'In Render Detail Data... ';
      XX_AR_EBL_COMMON_UTIL_PKG.
      PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);

      BEGIN
         SELECT DISTINCT NVL (include_header, 'N'), NVL (repeat_header, 'N')
           INTO lc_print_dtl_label, lc_repeat_dtl_header
           FROM xx_cdh_ebl_templ_dtl_txt
          WHERE cust_doc_id = p_cust_doc_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            lc_print_dtl_label := 'N';
            lc_repeat_dtl_header := 'N';
      END;

      lc_err_location_msg :=
            'Include Header Flag : '
         || lc_print_dtl_label
         || ' - Repeat Header Flag : '
         || lc_repeat_dtl_header;
      XX_AR_EBL_COMMON_UTIL_PKG.
      PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);

      -- Checking for Summary Bill
      BEGIN
         SELECT NVL (SUMMARY_BILL, 'N')
           INTO lc_summary_bill_doc
           FROM XX_CDH_EBL_MAIN
          WHERE cust_doc_id = p_cust_doc_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            lc_summary_bill_doc := 'N';
      END;

      IF lc_summary_bill_doc = 'Y'
      THEN
         lc_err_location_msg :=
            ' Selected cust doc id ' || p_cust_doc_id || ' is Summay Bill';
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
         lc_sort_columns := NULL;
         FOR lc_get_summary_fields_info IN c_get_summary_fields_info
         LOOP
		    -- Added by Thilak CG on 12-OCT-2017 for Wave2 UAT Defect#13836
            IF lc_get_summary_fields_info.sort_order IS NOT NULL AND lc_get_summary_fields_info.sort_type IS NOT NULL AND lc_get_summary_fields_info.record_type = 'LINE'
            THEN
		      lc_sort_columns :=
			     lc_sort_columns
				 || 'COLUMN'
			     || ln_count
			     || ' '
			     || lc_get_summary_fields_info.sort_type
			     || ',';
            END IF;
		    -- End
		    -- Added by Thilak CG on 12-OCT-2017 for Wave2 UAT Defect#13836
		    IF lc_get_summary_fields_info.col_name = 'ELEC_DETAIL_SEQ_NUMBER'
			THEN
			ln_count := ln_count + 1;
            ELSE
            -- End
            IF p_file_creation_type = 'DELIMITED'
            THEN
               lc_summary_build_sql :=
                  lc_summary_build_sql
                  || get_formatted_etxt_column (
                        p_cust_doc_id,
                        lc_get_summary_fields_info.alignment,
                        lc_get_summary_fields_info.start_val_pos,
                        lc_get_summary_fields_info.end_val_pos,
                        lc_get_summary_fields_info.fill_txt_pos,
                        lc_get_summary_fields_info.prepend_char,
                        lc_get_summary_fields_info.append_char,
                        lc_get_summary_fields_info.data_type,
                        lc_get_summary_fields_info.data_format,
                        lc_column || ln_count,
                        p_debug_flag,
                        p_delimiter_char)
                  || '||'
                  || ''''
                  || p_delimiter_char
                  || ''''
                  || '||';
               lc_summary_build_label :=
                     lc_summary_build_label
                  || lc_get_summary_fields_info.label
                  || p_delimiter_char;
               ln_count := ln_count + 1;
            ELSIF p_file_creation_type = 'FIXED'
            THEN
               lc_summary_build_sql :=
                  lc_summary_build_sql
                  || get_formatted_etxt_column (
                        p_cust_doc_id,
                        lc_get_summary_fields_info.alignment,
                        lc_get_summary_fields_info.start_val_pos,
                        lc_get_summary_fields_info.end_val_pos,
                        lc_get_summary_fields_info.fill_txt_pos,
                        lc_get_summary_fields_info.prepend_char,
                        lc_get_summary_fields_info.append_char,
                        lc_get_summary_fields_info.data_type,
                        lc_get_summary_fields_info.data_format,
                        lc_column || ln_count,
                        p_debug_flag,
                        NULL)
                  || '||';
               lc_dtl_col_label := NULL;

               BEGIN
                  SELECT LPAD (lc_get_summary_fields_info.label,
                               ((lc_get_summary_fields_info.end_txt_pos - lc_get_summary_fields_info.start_txt_pos) +1), --Changed for Defect # 44465
                               ' ')
                    INTO lc_dtl_col_label
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lc_dtl_col_label := NULL;
               END;

               lc_summary_build_label :=
                  lc_summary_build_label || lc_dtl_col_label;
               ln_count := ln_count + 1;
            END IF;
		   END IF;

         END LOOP;                                     --c_get_dtl_fields_info

         lc_err_location_msg := ' Detail Columns SQL ' || lc_summary_build_sql;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
         lc_err_location_msg := ' Detail Lables are ' || lc_dtl_col_label;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);

         IF p_file_creation_type = 'DELIMITED'
         THEN
            lc_summary_build_sql :=
               SUBSTR (
                  lc_summary_build_sql,
                  1,
                  (  LENGTH (lc_summary_build_sql)
                   - LENGTH (p_delimiter_char)
                   - 6));
            lc_summary_build_label :=
               SUBSTR (
                  lc_summary_build_label,
                  1,
                  (LENGTH (lc_summary_build_label)
                   - LENGTH (p_delimiter_char)));
         ELSIF p_file_creation_type = 'FIXED'
         THEN
            lc_summary_build_sql :=
               SUBSTR (lc_summary_build_sql,
                       1,
                       (LENGTH (lc_summary_build_sql) - 2));
         END IF;

         lc_err_location_msg := 'SQL Columns : ' || lc_summary_build_sql;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
         lc_dtl_lines_sql :=
               'SELECT CUSTOMER_TRX_ID, CUSTOMER_TRX_LINE_ID, '
            || lc_summary_build_sql
            || ' AS lc_text FROM XX_AR_EBL_TXT_DTL_STG WHERE file_id = '
            || p_file_id
            || ' AND cust_doc_id = '
            || p_cust_doc_id
            || ' AND REC_TYPE != '
            || '''FID''';
         lc_dtl_line_sort_columns := lc_sort_columns;
        --    get_sort_columns (p_cust_doc_id, lc_trx_type);
         lc_err_location_msg := 'lc_dtl_line_sort_columns : ' || lc_dtl_line_sort_columns;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
         lc_err_location_msg := 'Detail Line SQL : ' || lc_dtl_lines_sql;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
         lc_build_dtl_line_label := lc_summary_build_label;
         lc_line_exists := 'Y';
         lc_hdr_exists := 'N';
         lc_dist_exists := 'N';
         lc_err_location_msg := ' Detail Columns SQL ' || lc_dtl_lines_sql;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
         lc_err_location_msg :=
            ' Detail Lables are ' || lc_build_dtl_line_label;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
         lc_err_location_msg := 'Opening the Cursors ';
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
         lc_err_location_msg :=
               'Header Exists : '
            || lc_hdr_exists
            || ' - '
            || ' Line Exists : '
            || lc_line_exists
            || ' - '
            || ' Dist Line Exists : '
            || lc_dist_exists;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

         -----------> Opening Cursors based on setup Start.
         IF     lc_hdr_exists = 'Y'
            AND lc_line_exists = 'Y'
            AND lc_dist_exists = 'Y'
         THEN
            lc_err_location_msg :=
               'Opening the Header Cursor, Query :' || lc_dtl_hdr_sql;
            XX_AR_EBL_COMMON_UTIL_PKG.
            PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

            IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_hdr_repeat_cnt = 0
            THEN
               UTL_FILE.
               put_line (p_output_file, lc_build_dtl_hdr_label || CHR (13));
			   ln_hdr_repeat_cnt := 1;
            END IF;

            lc_dtl_lines_sql :=
               lc_dtl_lines_sql
               || ' AND customer_trx_id=nvl(:pcustomer_trx_id,customer_trx_id)';
            lc_dtl_lines_sql :=
                  lc_dtl_lines_sql
               || ' ORDER BY '
               || lc_dtl_line_sort_columns
               || ' CUSTOMER_TRX_ID, trx_line_number,stg_id';
            lc_dtl_dist_lines_sql :=
               lc_dtl_dist_lines_sql
               || ' AND customer_trx_id=nvl(:pcustomer_trx_id,customer_trx_id)'
               || ' AND customer_trx_line_id=:pcustomer_trx_line_id';
            lc_dtl_dist_lines_sql :=
                  lc_dtl_dist_lines_sql
               || ' ORDER BY '
               || lc_dtl_dist_sort_columns
               || ' trx_line_number,stg_id';

            OPEN c_dtl_hdr_cursor FOR lc_dtl_hdr_sql;           -- hdr cursor.

            LOOP
               FETCH c_dtl_hdr_cursor
               INTO ln_customer_trx_id, lc_txt_line;

               EXIT WHEN c_dtl_hdr_cursor%NOTFOUND;

               IF lc_repeat_dtl_header = 'Y'
               THEN
                  UTL_FILE.
                  put_line (p_output_file,
                            lc_build_dtl_hdr_label || CHR (13));
               END IF;

               lc_err_location_msg :=
                  'Writing the header level record into file ' || lc_txt_line;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
               UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
               UTL_FILE.fflush (p_output_file);
               lc_err_location_msg :=
                  'Opening the Lines Cursor, Query :' || lc_dtl_lines_sql;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

               IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_dtl_repeat_cnt = 0
               THEN
                  UTL_FILE.
                  put_line (p_output_file,
                            lc_build_dtl_line_label || CHR (13));
				  ln_dtl_repeat_cnt := 1;
               END IF;

               OPEN c_dtl_line_cursor FOR lc_dtl_lines_sql
                  USING ln_customer_trx_id;                    -- line cursor.

               LOOP
                  FETCH c_dtl_line_cursor
                  INTO ln_customer_trx_id,
                       ln_customer_trx_line_id,
                       lc_txt_line;

                  EXIT WHEN c_dtl_line_cursor%NOTFOUND;

                  IF lc_repeat_dtl_header = 'Y'
                  THEN
                     UTL_FILE.
                     put_line (p_output_file,
                               lc_build_dtl_line_label || CHR (13));
                  END IF;

                  --fnd_file.put_line(fnd_file.log,lc_txt_line);
                  lc_err_location_msg :=
                     'Writing the line level record into file '
                     || lc_txt_line;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                  UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
                  UTL_FILE.fflush (p_output_file);
                  lc_err_location_msg :=
                     'Opening the Dist Lines Cursor, Query :'
                     || lc_dtl_dist_lines_sql;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

                  IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_dist_repeat_cnt = 0
                  THEN
                     UTL_FILE.
                     put_line (p_output_file,
                               lc_build_dtl_dist_label || CHR (13));
					 ln_dist_repeat_cnt := 1;
                  END IF;

                  OPEN c_dtl_dist_line_cursor FOR lc_dtl_dist_lines_sql
                     USING ln_customer_trx_id, ln_customer_trx_line_id; -- dist line cursor.

                  LOOP
                     FETCH c_dtl_dist_line_cursor
                     INTO ln_customer_trx_id,
                          ln_customer_trx_line_id,
                          lc_txt_line;

                     EXIT WHEN c_dtl_dist_line_cursor%NOTFOUND;

                     IF lc_repeat_dtl_header = 'Y'
                     THEN
                        UTL_FILE.
                        put_line (p_output_file,
                                  lc_build_dtl_dist_label || CHR (13));
                     END IF;

                     lc_err_location_msg :=
                        'Writing the dist level record into file '
                        || lc_txt_line;
                     XX_AR_EBL_COMMON_UTIL_PKG.
                     PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                     UTL_FILE.
                     put_line (p_output_file, lc_txt_line || CHR (13));
                     UTL_FILE.fflush (p_output_file);
                  END LOOP;                                -- dist line cursor

                  CLOSE c_dtl_dist_line_cursor;
               END LOOP;                                        -- line cursor

               CLOSE c_dtl_line_cursor;
            END LOOP;                                            -- hdr cursor

            CLOSE c_dtl_hdr_cursor;
         ELSIF     lc_hdr_exists = 'N'
               AND lc_line_exists = 'Y'
               AND lc_dist_exists = 'Y'
         THEN
            lc_dtl_lines_sql :=
                  lc_dtl_lines_sql
               || ' ORDER BY '
               || lc_dtl_line_sort_columns
               || ' customer_trx_id, trx_line_number,stg_id';
            lc_dtl_dist_lines_sql :=
               lc_dtl_dist_lines_sql
               || ' AND customer_trx_id=nvl(:pcustomer_trx_id,customer_trx_id)'
               || ' AND customer_trx_line_id=:pcustomer_trx_line_id';
            lc_dtl_dist_lines_sql :=
                  lc_dtl_dist_lines_sql
               || ' ORDER BY '
               || lc_dtl_dist_sort_columns
               || ' trx_line_number, stg_id';
            lc_err_location_msg :=
               'Opening the Lines Cursor, Query :' || lc_dtl_lines_sql;
            XX_AR_EBL_COMMON_UTIL_PKG.
            PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

            IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_dtl_repeat_cnt = 0
            THEN
               UTL_FILE.
               put_line (p_output_file, lc_build_dtl_line_label || CHR (13));
			   ln_dtl_repeat_cnt := 1;
            END IF;

            OPEN c_dtl_line_cursor FOR lc_dtl_lines_sql;       -- line cursor.

            LOOP
               FETCH c_dtl_line_cursor
               INTO ln_customer_trx_id, ln_customer_trx_line_id, lc_txt_line;

               EXIT WHEN c_dtl_line_cursor%NOTFOUND;

               IF lc_repeat_dtl_header = 'Y'
               THEN
                  UTL_FILE.
                  put_line (p_output_file,
                            lc_build_dtl_line_label || CHR (13));
               END IF;

               lc_err_location_msg :=
                  'Writing the line level record into file ' || lc_txt_line;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
               UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
               UTL_FILE.fflush (p_output_file);
               lc_err_location_msg :=
                  'Opening the Dist Lines Cursor, Query :'
                  || lc_dtl_dist_lines_sql;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

               IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_dist_repeat_cnt = 0
               THEN
                  UTL_FILE.
                  put_line (p_output_file,
                            lc_build_dtl_dist_label || CHR (13));
				  ln_dist_repeat_cnt := 1;
               END IF;

               OPEN c_dtl_dist_line_cursor FOR lc_dtl_dist_lines_sql
                  USING ln_customer_trx_id, ln_customer_trx_line_id; -- dist line cursor.

               LOOP
                  FETCH c_dtl_dist_line_cursor
                  INTO ln_customer_trx_id,
                       ln_customer_trx_line_id,
                       lc_txt_line;

                  EXIT WHEN c_dtl_dist_line_cursor%NOTFOUND;

                  IF lc_repeat_dtl_header = 'Y'
                  THEN
                     UTL_FILE.
                     put_line (p_output_file,
                               lc_build_dtl_dist_label || CHR (13));
                  END IF;

                  --fnd_file.put_line(fnd_file.log,lc_txt_line);
                  lc_err_location_msg :=
                     'Writing the dist level record into file '
                     || lc_txt_line;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                  UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
                  UTL_FILE.fflush (p_output_file);
               END LOOP;                                   -- dist line cursor

               CLOSE c_dtl_dist_line_cursor;
            END LOOP;                                           -- line cursor

            CLOSE c_dtl_line_cursor;
         ELSIF     lc_hdr_exists = 'Y'
               AND lc_line_exists = 'Y'
               AND lc_dist_exists = 'N'
         THEN
            lc_err_location_msg :=
               'Opening the Header Cursor, Query :' || lc_dtl_hdr_sql;
            XX_AR_EBL_COMMON_UTIL_PKG.
            PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

            IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_hdr_repeat_cnt = 0
            THEN
               UTL_FILE.
               put_line (p_output_file, lc_build_dtl_hdr_label || CHR (13));
			   ln_hdr_repeat_cnt := 1;
            END IF;

            lc_dtl_lines_sql :=
               lc_dtl_lines_sql
               || ' AND customer_trx_id=nvl(:pcustomer_trx_id,customer_trx_id)';
            lc_dtl_lines_sql :=
                  lc_dtl_lines_sql
               || ' ORDER BY '
               || lc_dtl_line_sort_columns
               || ' customer_trx_id, trx_line_number ,stg_id';
            lc_dtl_lines_sql :=
                  'SELECT customer_trx_id, lc_text FROM ('
               || lc_dtl_lines_sql
               || ')';
            lc_err_location_msg :=
               'Opening the Lines Cursor, Query :' || lc_dtl_lines_sql;
            XX_AR_EBL_COMMON_UTIL_PKG.
            PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

            OPEN c_dtl_hdr_cursor FOR lc_dtl_hdr_sql;           -- hdr cursor.

            LOOP
               FETCH c_dtl_hdr_cursor
               INTO ln_customer_trx_id, lc_txt_line;

               EXIT WHEN c_dtl_hdr_cursor%NOTFOUND;

               IF lc_repeat_dtl_header = 'Y'
               THEN
                  UTL_FILE.
                  put_line (p_output_file,
                            lc_build_dtl_hdr_label || CHR (13));
               END IF;

               lc_err_location_msg :=
                  'Writing the header level record into file ' || lc_txt_line;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
               UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
               UTL_FILE.fflush (p_output_file);
               lc_err_location_msg :=
                  'Opening the Lines Cursor, Query :' || lc_dtl_lines_sql;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

               IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_dtl_repeat_cnt = 0
               THEN
                  UTL_FILE.
                  put_line (p_output_file,
                            lc_build_dtl_line_label || CHR (13));
				  ln_dtl_repeat_cnt := 1;
               END IF;

               --lc_txt_line_previous := NULL;
               --lc_txt_line_current := NULL;
               OPEN c_dtl_line_cursor FOR lc_dtl_lines_sql
                  USING ln_customer_trx_id;                    -- line cursor.

               LOOP
                  FETCH c_dtl_line_cursor
                  INTO ln_customer_trx_id, lc_txt_line;

                  EXIT WHEN c_dtl_line_cursor%NOTFOUND;

                  IF lc_repeat_dtl_header = 'Y'
                  THEN
                     UTL_FILE.
                     put_line (p_output_file,
                               lc_build_dtl_line_label || CHR (13));
                  END IF;

                  --lc_txt_line_current := lc_txt_line;
                  --IF NVL(lc_txt_line_previous,'X') != lc_txt_line_current THEN
                  lc_err_location_msg :=
                     'Writing the line level record into file '
                     || lc_txt_line;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                  UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
                  UTL_FILE.fflush (p_output_file);
               --END IF;
               --lc_txt_line_previous := lc_txt_line;
               END LOOP;                                        -- line cursor

               CLOSE c_dtl_line_cursor;
            END LOOP;                                            -- hdr cursor

            CLOSE c_dtl_hdr_cursor;
         ELSIF     lc_hdr_exists = 'N'
               AND lc_line_exists = 'Y'
               AND lc_dist_exists = 'N'
         THEN
            lc_dtl_lines_sql :=
                  lc_dtl_lines_sql
               || ' ORDER BY '
               || lc_dtl_line_sort_columns
               || ' customer_trx_id, trx_line_number, stg_id ';
            --lc_dtl_lines_sql := 'SELECT DISTINCT lc_text FROM ('||lc_dtl_lines_sql||')';
            lc_dtl_lines_sql :=
               'SELECT lc_text FROM (' || lc_dtl_lines_sql || ')';
            lc_err_location_msg :=
               'Opening the Lines Cursor, Query :' || lc_dtl_lines_sql;
            XX_AR_EBL_COMMON_UTIL_PKG.
            PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

            IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_dtl_repeat_cnt = 0
            THEN
               UTL_FILE.
               put_line (p_output_file, lc_build_dtl_line_label || CHR (13));
			   ln_dtl_repeat_cnt := 1;
            END IF;

            ln_customer_trx_id := NULL;

            --lc_txt_line_previous := NULL;
            --lc_txt_line_current := NULL;
            OPEN c_dtl_line_cursor FOR lc_dtl_lines_sql;       -- line cursor.

            LOOP
               FETCH c_dtl_line_cursor INTO lc_txt_line;

               EXIT WHEN c_dtl_line_cursor%NOTFOUND;

               --fnd_file.put_line(fnd_file.log,lc_txt_line);
               IF lc_repeat_dtl_header = 'Y'
               THEN
                  UTL_FILE.
                  put_line (p_output_file,
                            lc_build_dtl_line_label || CHR (13));
               END IF;

               --lc_txt_line_current := lc_txt_line;
               --IF NVL(lc_txt_line_previous,'X') != lc_txt_line_current THEN
               lc_err_location_msg :=
                  'Writing the line level record into file ' || lc_txt_line;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
               UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
               UTL_FILE.fflush (p_output_file);
            --END IF;
            --lc_txt_line_previous := lc_txt_line;
            END LOOP;                                           -- line cursor

            CLOSE c_dtl_line_cursor;
         ELSIF     lc_hdr_exists = 'Y'
               AND lc_line_exists = 'N'
               AND lc_dist_exists = 'N'
         THEN
            lc_err_location_msg :=
               'Opening the Header Cursor, Query :' || lc_dtl_hdr_sql;
            XX_AR_EBL_COMMON_UTIL_PKG.
            PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

            --start of changes for defect 41016
            IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_hdr_repeat_cnt = 0
            THEN
               UTL_FILE.
               put_line (p_output_file, lc_build_dtl_hdr_label || CHR (13));
			   ln_hdr_repeat_cnt := 1;
            END IF;

            --end of changes for defect 41016
            OPEN c_dtl_hdr_cursor FOR lc_dtl_hdr_sql;           -- hdr cursor.

            LOOP
               FETCH c_dtl_hdr_cursor
               INTO ln_customer_trx_id, lc_txt_line;

               EXIT WHEN c_dtl_hdr_cursor%NOTFOUND;

               IF lc_repeat_dtl_header = 'Y'
               THEN
                  UTL_FILE.
                  put_line (p_output_file,
                            lc_build_dtl_hdr_label || CHR (13));
               END IF;

               lc_err_location_msg :=
                  'Writing the header level record into file ' || lc_txt_line;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
               UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
               UTL_FILE.fflush (p_output_file);
            END LOOP;                                            -- hdr cursor

            CLOSE c_dtl_hdr_cursor;
         ELSE
            lc_err_location_msg :=
                  'Error While Rendering TXT Details Data for Cust Doc Id : '
               || p_cust_doc_id
               || ' - '
               || 'File Id : '
               || p_file_id
               || ' - '
               || 'record types selection, Header : '
               || lc_hdr_exists
               || ', Lines : '
               || lc_line_exists
               || ' Dist Lines :'
               || lc_dist_exists;
            p_dtl_error_flag := 'Y';
            p_dtl_error_msg := lc_err_location_msg;
         END IF;              -----------> Opening Cursors based on setup End.

         p_dtl_error_flag := 'N';
      --Summary Bill Changes End
      ELSE
         --Build the cursor to write the detail data into eTXT File.
         lc_hdr_exists := 'N';
         lc_line_exists := 'N';
         lc_dist_exists := 'N';
         ln_count := 1;
         ln_hdr_cnt := 0;

        -- Added and Commented by Thilak on 27-OCT-2017 for Defect # 13836
		BEGIN
         SELECT COUNT(1)
		   INTO ln_hdr_cnt
         FROM xx_fin_translatedefinition xftd,
              xx_fin_translatevalues xftv,
              xx_cdh_ebl_templ_dtl_txt xcetdt
         WHERE xftd.translate_id = xftv.translate_id
         AND xftv.source_value1 = xcetdt.field_id
         AND xcetdt.cust_doc_id = p_cust_doc_id
         AND xcetdt.record_type = 'HDR'
         AND xftd.translation_name = 'XX_CDH_EBL_TXT_DET_FIELDS'
		 AND xftv.target_value19 = 'DT'
         AND xftv.enabled_flag = 'Y'
         AND TRUNC (SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE + 1))
         AND xcetdt.attribute20 = 'Y';
        EXCEPTION
         WHEN OTHERS
         THEN
            ln_hdr_cnt := 0;
        END;

         lc_custtrx_hdr_sort_cols := get_sort_columns (p_cust_doc_id, 'HDR');
		 lc_custtrx_line_sort_cols := get_sort_columns (p_cust_doc_id, 'LINE');

         IF lc_custtrx_hdr_sort_cols IS NOT NULL AND lc_custtrx_line_sort_cols IS NULL AND ln_hdr_cnt != 0
		 THEN
         lc_custtrx_sort_columns := lc_custtrx_hdr_sort_cols || 'customer_trx_id,trx_line_number,stg_id';
         lc_err_location_msg := 'Header Level lc_custtrx_sort_columns : ' || lc_custtrx_sort_columns;
         XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
		 ELSIF lc_custtrx_hdr_sort_cols IS NOT NULL AND lc_custtrx_line_sort_cols IS NOT NULL AND ln_hdr_cnt != 0
		 THEN
         lc_custtrx_sort_columns := lc_custtrx_hdr_sort_cols || 'customer_trx_id,trx_line_number,stg_id';
         lc_err_location_msg := 'Header Level lc_custtrx_sort_columns : ' || lc_custtrx_sort_columns;
         XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
		 ELSIF lc_custtrx_hdr_sort_cols IS NULL AND lc_custtrx_line_sort_cols IS NOT NULL AND ln_hdr_cnt = 0
		 THEN
         lc_custtrx_sort_columns := lc_custtrx_line_sort_cols || 'customer_trx_id,trx_line_number,stg_id';
         lc_err_location_msg := 'Line Level lc_custtrx_sort_columns : ' || lc_custtrx_sort_columns;
         XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
		 ELSIF lc_custtrx_hdr_sort_cols IS NULL AND lc_custtrx_line_sort_cols IS NOT NULL AND ln_hdr_cnt != 0
		 THEN
         lc_custtrx_sort_columns := 'customer_trx_id,trx_line_number,stg_id';
         lc_err_location_msg := 'Line Level lc_custtrx_sort_columns : ' || lc_custtrx_sort_columns;
         XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
		 ELSIF lc_custtrx_hdr_sort_cols IS NULL AND lc_custtrx_line_sort_cols IS NULL
		 THEN
         lc_custtrx_sort_columns := 'customer_trx_id,trx_line_number,stg_id';
         lc_err_location_msg := 'Default lc_custtrx_sort_columns : ' || lc_custtrx_sort_columns;
         XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
         END IF;

         OPEN c_get_dist_custtrx FOR 'SELECT xtds.customer_trx_id
										FROM
										(SELECT xtds.*,
										        ROW_NUMBER() OVER (PARTITION BY CUSTOMER_TRX_ID ORDER BY '||lc_custtrx_sort_columns||') AS SEQNUM
										   FROM xx_ar_ebl_txt_dtl_stg xtds
										  WHERE xtds.file_id        = ' ||p_file_id||
										   'AND xtds.cust_doc_id    = ' ||p_cust_doc_id||
										   'AND xtds.rec_type      != ''FID''
										    AND xtds.trx_type       = DECODE('||ln_hdr_cnt||',0,''LINE'',''HDR'')
										    AND xtds.customer_trx_id IS NOT NULL
										    ORDER BY '||lc_custtrx_sort_columns||') xtds WHERE seqnum = 1';
         LOOP
           -- Added by Punit on 12-OCT-2017
		   lc_hdr_exists := 'N';
           lc_line_exists := 'N';
           lc_dist_exists := 'N';
		   -- End of Added by Punit on 12-OCT-2017
           ln_get_customer_trx_id := 0;

		  FETCH c_get_dist_custtrx INTO ln_get_customer_trx_id;
		  lc_err_location_msg := ' ln_get_customer_trx_id: ' || ln_get_customer_trx_id;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
        -- Ended by Thilak on 27-OCT-2017 for Defect # 13836

            EXIT WHEN c_get_dist_custtrx%NOTFOUND;

		 OPEN c_get_dist_record_type (ln_get_customer_trx_id);

            LOOP
               FETCH c_get_dist_record_type INTO lc_trx_type;

               EXIT WHEN c_get_dist_record_type%NOTFOUND;


         OPEN get_dist_rows(lc_trx_type);

         LOOP
           -- Added by Punit on 13-OCT-2017
		   lc_hdr_exists  := 'N';
           lc_line_exists := 'N';
           lc_dist_exists := 'N';
		   -- End of Added by Punit on 13-OCT-2017

            FETCH get_dist_rows INTO ln_get_line_dist_rows;

            EXIT WHEN get_dist_rows%NOTFOUND;
			  lc_build_dtl_label := NULL;
               lc_dtl_lines_sql := NULL;
               lc_build_dtl_line_label := NULL;
               lc_sort_columns := NULL;
               FOR lc_get_dtl_fields_info
                  IN c_get_dtl_fields_info (lc_trx_type,
                                            ln_get_line_dist_rows)
               -- End of Added and Commented by Punit on 12-JUL-2017 for Defect # 41307
               LOOP
				-- Added by Thilak CG on 12-OCT-2017 for Wave2 UAT Defect#13836
                IF lc_get_dtl_fields_info.sort_order IS NOT NULL AND lc_get_dtl_fields_info.sort_type IS NOT NULL
                THEN
					lc_sort_columns :=
						  lc_sort_columns
					   || 'COLUMN'
					   || ln_count
					   || ' '
					   || lc_get_dtl_fields_info.sort_type
					   || ',';
                END IF;
                -- End
			    -- Added by Thilak CG on 12-OCT-2017 for Wave2 UAT Defect#13836
				IF lc_get_dtl_fields_info.col_name = 'ELEC_DETAIL_SEQ_NUMBER'
				THEN
				ln_count := ln_count + 1;
				ELSE
                -- End
                  --fnd_file.put_line(fnd_file.log,p_cust_doc_id);
                  IF p_file_creation_type = 'DELIMITED'
                  THEN
                     lc_build_dtl_sql :=
                        lc_build_dtl_sql
                        || get_formatted_etxt_column (
                              p_cust_doc_id,
                              lc_get_dtl_fields_info.alignment,
                              lc_get_dtl_fields_info.start_val_pos,
                              lc_get_dtl_fields_info.end_val_pos,
                              lc_get_dtl_fields_info.fill_txt_pos,
                              lc_get_dtl_fields_info.prepend_char,
                              lc_get_dtl_fields_info.append_char,
                              lc_get_dtl_fields_info.data_type,
                              lc_get_dtl_fields_info.data_format,
                              lc_column || ln_count,
                              p_debug_flag,
                              p_delimiter_char,
							  lc_get_dtl_fields_info.label)
                        || '||'
                        || ''''
                        || p_delimiter_char
                        || ''''
                        || '||';
                     lc_build_dtl_label :=
                           lc_build_dtl_label
                        || lc_get_dtl_fields_info.label
                        || p_delimiter_char;
                     ln_count := ln_count + 1;
                  ELSIF p_file_creation_type = 'FIXED'
                  THEN
                     lc_build_dtl_sql :=
                        lc_build_dtl_sql
                        || get_formatted_etxt_column (
                              p_cust_doc_id,
                              lc_get_dtl_fields_info.alignment,
                              lc_get_dtl_fields_info.start_val_pos,
                              lc_get_dtl_fields_info.end_val_pos,
                              lc_get_dtl_fields_info.fill_txt_pos,
                              lc_get_dtl_fields_info.prepend_char,
                              lc_get_dtl_fields_info.append_char,
                              lc_get_dtl_fields_info.data_type,
                              lc_get_dtl_fields_info.data_format,
                              lc_column || ln_count,
                              p_debug_flag,
                              NULL,
							  lc_get_dtl_fields_info.label)
                        || '||';
                     lc_dtl_col_label := NULL;

                     BEGIN
                        SELECT LPAD (lc_get_dtl_fields_info.label,
                                     ((lc_get_dtl_fields_info.end_txt_pos - lc_get_dtl_fields_info.start_txt_pos) +1), --Changed for Defect # 44465 -- lc_get_dtl_fields_info.start_val_pos,
                                     ' ')
                          INTO lc_dtl_col_label
                          FROM DUAL;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           lc_dtl_col_label := NULL;
                     END;

                     lc_build_dtl_label :=
                        lc_build_dtl_label || lc_dtl_col_label;
                     ln_count := ln_count + 1;
                  END IF;
				END IF;

               END LOOP;                               --c_get_dtl_fields_info

               IF p_file_creation_type = 'DELIMITED'
               THEN
                  lc_build_dtl_sql :=
                     SUBSTR (
                        lc_build_dtl_sql,
                        1,
                        (  LENGTH (lc_build_dtl_sql)
                         - LENGTH (p_delimiter_char)
                         - 6));
                  lc_build_dtl_label :=
                     SUBSTR (
                        lc_build_dtl_label,
                        1,
                        (LENGTH (lc_build_dtl_label)
                         - LENGTH (p_delimiter_char)));
               ELSIF p_file_creation_type = 'FIXED'
               THEN
                  lc_build_dtl_sql :=
                     SUBSTR (lc_build_dtl_sql,
                             1,
                             (LENGTH (lc_build_dtl_sql) - 2));
               END IF;

               lc_err_location_msg := 'SQL Columns : ' || lc_build_dtl_sql;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);

               --fnd_file.put_line(fnd_file.log,lc_build_dtl_sql);
               IF lc_trx_type = 'HDR'
               THEN
                  --lc_dtl_hdr_sql := 'SELECT DISTINCT CUSTOMER_TRX_ID,'||lc_build_dtl_sql||' FROM XX_AR_EBL_TXT_DTL_STG WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_TYPE != '||'''FID'''||' AND TRX_TYPE = '||''''||lc_trx_type||'''';

				  lc_dtl_hdr_sql :=
                     'SELECT CUSTOMER_TRX_ID,' || lc_build_dtl_sql
                     || ' AS lc_text FROM XX_AR_EBL_TXT_DTL_STG WHERE file_id = '
                     || p_file_id
                     || ' AND cust_doc_id = '
                     || p_cust_doc_id
                     || ' AND REC_TYPE != '
                     || '''FID'''
                     || ' AND TRX_TYPE = '
                     || ''''
                     || lc_trx_type
                     || ''''
                     || ' AND REC_ORDER = '
                     || ln_get_line_dist_rows
					 || ' AND CUSTOMER_TRX_ID = '
					 || ln_get_customer_trx_id;-- Added rec_order column by Punit for Defect# 41307
                  lc_dtl_hdr_sort_columns := lc_sort_columns;
                 --    get_sort_columns (p_cust_doc_id, lc_trx_type);
                  lc_err_location_msg := 'lc_dtl_hdr_sort_columns : ' || lc_dtl_hdr_sort_columns;
				  XX_AR_EBL_COMMON_UTIL_PKG.
				  PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                  lc_dtl_hdr_sql :=
                        lc_dtl_hdr_sql
                     || ' ORDER BY '
                     || lc_dtl_hdr_sort_columns
                     || ' CUSTOMER_TRX_ID, trx_line_number,stg_id';
                  lc_err_location_msg :=
                     'Detail Header SQL : ' || lc_dtl_hdr_sql;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                  lc_build_dtl_hdr_label := lc_build_dtl_label;
                  ln_count := 1;
                  lc_build_dtl_sql := NULL;
                  lc_build_dtl_label := NULL;
                  lc_hdr_exists := 'Y';
               ELSIF lc_trx_type = 'LINE'
               THEN
                  --lc_dtl_lines_sql := 'SELECT DISTINCT CUSTOMER_TRX_ID, CUSTOMER_TRX_LINE_ID, '||lc_build_dtl_sql||' FROM XX_AR_EBL_TXT_DTL_STG WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_TYPE != '||'''FID'''||' AND TRX_TYPE = '||''''||lc_trx_type||'''';
                  lc_dtl_lines_sql :=
                     'SELECT CUSTOMER_TRX_ID, CUSTOMER_TRX_LINE_ID, '
                     || lc_build_dtl_sql
                     || ' AS lc_text FROM XX_AR_EBL_TXT_DTL_STG WHERE file_id = '
                     || p_file_id
                     || ' AND cust_doc_id = '
                     || p_cust_doc_id
                     || ' AND REC_TYPE != '
                     || '''FID'''
                     || ' AND TRX_TYPE = '
                     || ''''
                     || lc_trx_type
                     || ''''
                     || ' AND REC_ORDER = '
                     || ln_get_line_dist_rows
					 || ' AND CUSTOMER_TRX_ID = '
					 || ln_get_customer_trx_id; -- Added rec_order column by Punit for Defect# 41307
				  lc_dtl_line_sort_columns := lc_sort_columns;
                --     get_sort_columns (p_cust_doc_id, lc_trx_type);
				  lc_err_location_msg := 'lc_dtl_line_sort_columns : ' || lc_dtl_line_sort_columns;
				  XX_AR_EBL_COMMON_UTIL_PKG.
				  PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                  lc_err_location_msg :=
                     'Detail Line SQL : ' || lc_dtl_lines_sql;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                  lc_build_dtl_line_label := lc_build_dtl_label;
                  ln_count := 1;
                  lc_build_dtl_sql := NULL;
                  lc_build_dtl_label := NULL;
                  lc_line_exists := 'Y';
               ELSIF lc_trx_type = 'DIST'
               THEN
                  --lc_dtl_dist_lines_sql := 'SELECT DISTINCT CUSTOMER_TRX_ID, CUSTOMER_TRX_LINE_ID, '||lc_build_dtl_sql||' FROM XX_AR_EBL_TXT_DTL_STG WHERE file_id = '||p_file_id||' AND cust_doc_id = '||p_cust_doc_id||' AND REC_TYPE != '||'''FID'''||' AND TRX_TYPE = '||''''||lc_trx_type||'''';
                  lc_dtl_dist_lines_sql :=
                     'SELECT CUSTOMER_TRX_ID, CUSTOMER_TRX_LINE_ID, '
                     || lc_build_dtl_sql
                     || ' AS lc_text FROM XX_AR_EBL_TXT_DTL_STG WHERE file_id = '
                     || p_file_id
                     || ' AND cust_doc_id = '
                     || p_cust_doc_id
                     || ' AND REC_TYPE != '
                     || '''FID'''
                     || ' AND TRX_TYPE = '
                     || ''''
                     || lc_trx_type
                     || '''';
                  lc_dtl_dist_sort_columns := lc_sort_columns;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                --     get_sort_columns (p_cust_doc_id, lc_trx_type);
				  lc_err_location_msg := 'lc_dtl_dist_sort_columns : ' || lc_dtl_dist_sort_columns;
				  XX_AR_EBL_COMMON_UTIL_PKG.
				  PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);

                  lc_build_dtl_dist_label := lc_build_dtl_label;
                  ln_count := 1;
                  lc_build_dtl_sql := NULL;
                  lc_build_dtl_label := NULL;
                  lc_dist_exists := 'Y';
               END IF;
            --END LOOP;                                 --c_get_dist_record_type

            --CLOSE c_get_dist_record_type;

            -----------> Opening Cursors based on setup Start.
            lc_err_location_msg := 'Opening the Cursors ';
            XX_AR_EBL_COMMON_UTIL_PKG.
            PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
            lc_err_location_msg :=
                  'Header Exists : '
               || lc_hdr_exists
               || ' - '
               || ' Line Exists : '
               || lc_line_exists
               || ' - '
               || ' Dist Line Exists : '
               || lc_dist_exists;
            XX_AR_EBL_COMMON_UTIL_PKG.
            PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

            IF     lc_hdr_exists = 'Y'
               AND lc_line_exists = 'Y'
               AND lc_dist_exists = 'Y'
            THEN
               lc_err_location_msg :=
                  'Opening the Header Cursor, Query :' || lc_dtl_hdr_sql;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

               IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_hdr_repeat_cnt = 0
               THEN
                  UTL_FILE.
                  put_line (p_output_file,
                            lc_build_dtl_hdr_label || CHR (13));

				 ln_max_rownum := 0;
				 SELECT NVL(MAX(ROWNUMBER),1)
				   INTO ln_max_rownum
				   FROM xx_cdh_ebl_templ_dtl_txt
				  WHERE cust_doc_id = p_cust_doc_id
					AND attribute20 = 'Y'
					AND record_type = lc_trx_type;

				  IF ln_max_rownum = ln_get_line_dist_rows
				  THEN
				  ln_hdr_repeat_cnt := 1;
				  END IF;

               END IF;

               lc_dtl_lines_sql :=
                  lc_dtl_lines_sql
                  || ' AND customer_trx_id=nvl(:pcustomer_trx_id,customer_trx_id)';
               lc_dtl_lines_sql :=
                     lc_dtl_lines_sql
                  || ' ORDER BY '
                  || lc_dtl_line_sort_columns
                  || ' CUSTOMER_TRX_ID, trx_line_number,stg_id';
               lc_dtl_dist_lines_sql :=
                  lc_dtl_dist_lines_sql
                  || ' AND customer_trx_id=nvl(:pcustomer_trx_id,customer_trx_id)'
                  || ' AND customer_trx_line_id=:pcustomer_trx_line_id';
               lc_dtl_dist_lines_sql :=
                     lc_dtl_dist_lines_sql
                  || ' ORDER BY '
                  || lc_dtl_dist_sort_columns
                  || ' trx_line_number ,stg_id';

               OPEN c_dtl_hdr_cursor FOR lc_dtl_hdr_sql;        -- hdr cursor.

               LOOP
                  FETCH c_dtl_hdr_cursor
                  INTO ln_customer_trx_id, lc_txt_line;

                  EXIT WHEN c_dtl_hdr_cursor%NOTFOUND;

                  IF lc_repeat_dtl_header = 'Y'
                  THEN
                     UTL_FILE.
                     put_line (p_output_file,
                               lc_build_dtl_hdr_label || CHR (13));
                  END IF;

                  lc_err_location_msg :=
                     'Writing the header level record into file '
                     || lc_txt_line;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                  UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
                  UTL_FILE.fflush (p_output_file);
                  lc_err_location_msg :=
                     'Opening the Lines Cursor, Query :' || lc_dtl_lines_sql;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

                  IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_dtl_repeat_cnt = 0
                  THEN
                     UTL_FILE.
                     put_line (p_output_file,
                               lc_build_dtl_line_label || CHR (13));

					 ln_max_rownum := 0;
					 SELECT NVL(MAX(ROWNUMBER),1)
					   INTO ln_max_rownum
					   FROM xx_cdh_ebl_templ_dtl_txt
					  WHERE cust_doc_id = p_cust_doc_id
						AND attribute20 = 'Y'
						AND record_type = lc_trx_type;

					  IF ln_max_rownum = ln_get_line_dist_rows
					  THEN
					  ln_dtl_repeat_cnt := 1;
					  END IF;
                  END IF;

                  OPEN c_dtl_line_cursor FOR lc_dtl_lines_sql
                     USING ln_customer_trx_id;                 -- line cursor.

                  LOOP
                     FETCH c_dtl_line_cursor
                     INTO ln_customer_trx_id,
                          ln_customer_trx_line_id,
                          lc_txt_line;

                     EXIT WHEN c_dtl_line_cursor%NOTFOUND;

                     IF lc_repeat_dtl_header = 'Y'
                     THEN
                        UTL_FILE.
                        put_line (p_output_file,
                                  lc_build_dtl_line_label || CHR (13));
                     END IF;

                     --fnd_file.put_line(fnd_file.log,lc_txt_line);
                     lc_err_location_msg :=
                        'Writing the line level record into file '
                        || lc_txt_line;
                     XX_AR_EBL_COMMON_UTIL_PKG.
                     PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                     UTL_FILE.
                     put_line (p_output_file, lc_txt_line || CHR (13));
                     UTL_FILE.fflush (p_output_file);
                     lc_err_location_msg :=
                        'Opening the Dist Lines Cursor, Query :'
                        || lc_dtl_dist_lines_sql;
                     XX_AR_EBL_COMMON_UTIL_PKG.
                     PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

                     IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_dist_repeat_cnt = 0
                     THEN
                        UTL_FILE.
                        put_line (p_output_file,
                                  lc_build_dtl_dist_label || CHR (13));

						 ln_max_rownum := 0;
						 SELECT NVL(MAX(ROWNUMBER),1)
						   INTO ln_max_rownum
						   FROM xx_cdh_ebl_templ_dtl_txt
						  WHERE cust_doc_id = p_cust_doc_id
							AND attribute20 = 'Y'
							AND record_type = lc_trx_type;

						  IF ln_max_rownum = ln_get_line_dist_rows
						  THEN
						  ln_dist_repeat_cnt := 1;
						  END IF;
                     END IF;

                     OPEN c_dtl_dist_line_cursor FOR lc_dtl_dist_lines_sql
                        USING ln_customer_trx_id, ln_customer_trx_line_id; -- dist line cursor.

                     LOOP
                        FETCH c_dtl_dist_line_cursor
                        INTO ln_customer_trx_id,
                             ln_customer_trx_line_id,
                             lc_txt_line;

                        EXIT WHEN c_dtl_dist_line_cursor%NOTFOUND;

                        IF lc_repeat_dtl_header = 'Y'
                        THEN
                           UTL_FILE.
                           put_line (p_output_file,
                                     lc_build_dtl_dist_label || CHR (13));
                        END IF;

                        lc_err_location_msg :=
                           'Writing the dist level record into file '
                           || lc_txt_line;
                        XX_AR_EBL_COMMON_UTIL_PKG.
                        PUT_LOG_LINE (lb_debug_flag,
                                      FALSE,
                                      lc_err_location_msg);
                        UTL_FILE.
                        put_line (p_output_file, lc_txt_line || CHR (13));
                        UTL_FILE.fflush (p_output_file);
                     END LOOP;                             -- dist line cursor

                     CLOSE c_dtl_dist_line_cursor;
                  END LOOP;                                     -- line cursor

                  CLOSE c_dtl_line_cursor;
               END LOOP;                                         -- hdr cursor

               CLOSE c_dtl_hdr_cursor;
            ELSIF     lc_hdr_exists = 'N'
                  AND lc_line_exists = 'Y'
                  AND lc_dist_exists = 'Y'
            THEN
               lc_dtl_lines_sql :=
                     lc_dtl_lines_sql
                  || ' ORDER BY '
                  || lc_dtl_line_sort_columns
                  || ' customer_trx_id, trx_line_number,stg_id';
               lc_dtl_dist_lines_sql :=
                  lc_dtl_dist_lines_sql
                  || ' AND customer_trx_id=nvl(:pcustomer_trx_id,customer_trx_id)'
                  || ' AND customer_trx_line_id=:pcustomer_trx_line_id';
               lc_dtl_dist_lines_sql :=
                     lc_dtl_dist_lines_sql
                  || ' ORDER BY '
                  || lc_dtl_dist_sort_columns
                  || ' trx_line_number,stg_id';
               lc_err_location_msg :=
                  'Opening the Lines Cursor, Query :' || lc_dtl_lines_sql;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

               IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_dtl_repeat_cnt = 0
               THEN
                  UTL_FILE.
                  put_line (p_output_file,
                            lc_build_dtl_line_label || CHR (13));

                 ln_max_rownum := 0;
				 SELECT NVL(MAX(ROWNUMBER),1)
				   INTO ln_max_rownum
				   FROM xx_cdh_ebl_templ_dtl_txt
				  WHERE cust_doc_id = p_cust_doc_id
					AND attribute20 = 'Y'
					AND record_type = lc_trx_type;

				  IF ln_max_rownum = ln_get_line_dist_rows
				  THEN
				  ln_dtl_repeat_cnt := 1;
				  END IF;
               END IF;

               OPEN c_dtl_line_cursor FOR lc_dtl_lines_sql;    -- line cursor.

               LOOP
                  FETCH c_dtl_line_cursor
                  INTO ln_customer_trx_id,
                       ln_customer_trx_line_id,
                       lc_txt_line;

                  EXIT WHEN c_dtl_line_cursor%NOTFOUND;

                  IF lc_repeat_dtl_header = 'Y'
                  THEN
                     UTL_FILE.
                     put_line (p_output_file,
                               lc_build_dtl_line_label || CHR (13));
                  END IF;

                  lc_err_location_msg :=
                     'Writing the line level record into file '
                     || lc_txt_line;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                  UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
                  UTL_FILE.fflush (p_output_file);
                  lc_err_location_msg :=
                     'Opening the Dist Lines Cursor, Query :'
                     || lc_dtl_dist_lines_sql;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

                  IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_dist_repeat_cnt = 0
                  THEN
                     UTL_FILE.
                     put_line (p_output_file,
                               lc_build_dtl_dist_label || CHR (13));

					 ln_max_rownum := 0;
					 SELECT NVL(MAX(ROWNUMBER),1)
					   INTO ln_max_rownum
					   FROM xx_cdh_ebl_templ_dtl_txt
					  WHERE cust_doc_id = p_cust_doc_id
						AND attribute20 = 'Y'
						AND record_type = lc_trx_type;

					  IF ln_max_rownum = ln_get_line_dist_rows
					  THEN
					  ln_dist_repeat_cnt := 1;
					  END IF;
                  END IF;

                  OPEN c_dtl_dist_line_cursor FOR lc_dtl_dist_lines_sql
                     USING ln_customer_trx_id, ln_customer_trx_line_id; -- dist line cursor.

                  LOOP
                     FETCH c_dtl_dist_line_cursor
                     INTO ln_customer_trx_id,
                          ln_customer_trx_line_id,
                          lc_txt_line;

                     EXIT WHEN c_dtl_dist_line_cursor%NOTFOUND;

                     IF lc_repeat_dtl_header = 'Y'
                     THEN
                        UTL_FILE.
                        put_line (p_output_file,
                                  lc_build_dtl_dist_label || CHR (13));
                     END IF;

                     --fnd_file.put_line(fnd_file.log,lc_txt_line);
                     lc_err_location_msg :=
                        'Writing the dist level record into file '
                        || lc_txt_line;
                     XX_AR_EBL_COMMON_UTIL_PKG.
                     PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                     UTL_FILE.
                     put_line (p_output_file, lc_txt_line || CHR (13));
                     UTL_FILE.fflush (p_output_file);
                  END LOOP;                                -- dist line cursor

                  CLOSE c_dtl_dist_line_cursor;
               END LOOP;                                        -- line cursor

               CLOSE c_dtl_line_cursor;
            ELSIF     lc_hdr_exists = 'Y'
                  AND lc_line_exists = 'Y'
                  AND lc_dist_exists = 'N'
            THEN
               lc_err_location_msg :=
                  'Opening the Header Cursor, Query :' || lc_dtl_hdr_sql;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

               IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_hdr_repeat_cnt = 0
               THEN
                  UTL_FILE.
                  put_line (p_output_file,
                            lc_build_dtl_hdr_label || CHR (13));

                 ln_max_rownum := 0;
				 SELECT NVL(MAX(ROWNUMBER),1)
				   INTO ln_max_rownum
				   FROM xx_cdh_ebl_templ_dtl_txt
				  WHERE cust_doc_id = p_cust_doc_id
					AND attribute20 = 'Y'
					AND record_type = lc_trx_type;

				  IF ln_max_rownum = ln_get_line_dist_rows
				  THEN
				  ln_hdr_repeat_cnt := 1;
				  END IF;
               END IF;

               lc_dtl_lines_sql :=
                  lc_dtl_lines_sql
                  || ' AND customer_trx_id=nvl(:pcustomer_trx_id,customer_trx_id)';
               lc_dtl_lines_sql :=
                     lc_dtl_lines_sql
                  || ' ORDER BY '
                  || lc_dtl_line_sort_columns
                  || ' customer_trx_id, trx_line_number,stg_id';
               lc_dtl_lines_sql :=
                     'SELECT customer_trx_id, lc_text FROM ('
                  || lc_dtl_lines_sql
                  || ')';
               lc_err_location_msg :=
                  'Opening the Lines Cursor, Query :' || lc_dtl_lines_sql;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

               OPEN c_dtl_hdr_cursor FOR lc_dtl_hdr_sql;        -- hdr cursor.

               LOOP
                  FETCH c_dtl_hdr_cursor
                  INTO ln_customer_trx_id, lc_txt_line;

                  EXIT WHEN c_dtl_hdr_cursor%NOTFOUND;

                  IF lc_repeat_dtl_header = 'Y'
                  THEN
                     UTL_FILE.
                     put_line (p_output_file,
                               lc_build_dtl_hdr_label || CHR (13));
                  END IF;

                  lc_err_location_msg :=
                     'Writing the header level record into file '
                     || lc_txt_line;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                  UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
                  UTL_FILE.fflush (p_output_file);
                  lc_err_location_msg :=
                     'Opening the Lines Cursor, Query :' || lc_dtl_lines_sql;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

                  IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_dtl_repeat_cnt = 0
                  THEN
                     UTL_FILE.
                     put_line (p_output_file,
                               lc_build_dtl_line_label || CHR (13));

					 ln_max_rownum := 0;
					 SELECT NVL(MAX(ROWNUMBER),1)
					   INTO ln_max_rownum
					   FROM xx_cdh_ebl_templ_dtl_txt
					  WHERE cust_doc_id = p_cust_doc_id
						AND attribute20 = 'Y'
						AND record_type = lc_trx_type;

					  IF ln_max_rownum = ln_get_line_dist_rows
					  THEN
					  ln_dtl_repeat_cnt := 1;
					  END IF;
                  END IF;

			     --END LOOP;                                         -- hdr cursor     --- Added by Punit on 16-OCT-2017
                 --CLOSE c_dtl_hdr_cursor;                                              --- Added by Punit on 16-OCT-2017
                  --lc_txt_line_previous := NULL;
                  --lc_txt_line_current := NULL;
                  OPEN c_dtl_line_cursor FOR lc_dtl_lines_sql
                     USING ln_customer_trx_id;                 -- line cursor.

                  LOOP
                     FETCH c_dtl_line_cursor
                     INTO ln_customer_trx_id, lc_txt_line;

                     EXIT WHEN c_dtl_line_cursor%NOTFOUND;

                     IF lc_repeat_dtl_header = 'Y'
                     THEN
                        UTL_FILE.
                        put_line (p_output_file,
                                  lc_build_dtl_line_label || CHR (13));
                     END IF;

                     --lc_txt_line_current := lc_txt_line;
                     --IF NVL(lc_txt_line_previous,'X') != lc_txt_line_current THEN
                     lc_err_location_msg :=
                        'Writing the line level record into file '
                        || lc_txt_line;
                     XX_AR_EBL_COMMON_UTIL_PKG.
                     PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                     UTL_FILE.
                     put_line (p_output_file, lc_txt_line || CHR (13));
                     UTL_FILE.fflush (p_output_file);
                  --END IF;
                  --lc_txt_line_previous := lc_txt_line;
                  END LOOP;                                     -- line cursor

                  CLOSE c_dtl_line_cursor;
               END LOOP;                                         -- hdr cursor     --- Commented by Punit on 16-OCT-2017
              CLOSE c_dtl_hdr_cursor;                                              --- Commented by Punit on 16-OCT-2017
            ELSIF     lc_hdr_exists = 'N'
                  AND lc_line_exists = 'Y'
                  AND lc_dist_exists = 'N'
            THEN
               lc_dtl_lines_sql :=
                     lc_dtl_lines_sql
                  || ' ORDER BY '
                  || lc_dtl_line_sort_columns
                  || ' customer_trx_id, trx_line_number ,stg_id';
               --lc_dtl_lines_sql := 'SELECT DISTINCT lc_text FROM ('||lc_dtl_lines_sql||')';
               lc_dtl_lines_sql :=
                  'SELECT lc_text FROM (' || lc_dtl_lines_sql || ')';
               lc_err_location_msg :=
                  'Opening the Lines Cursor, Query :' || lc_dtl_lines_sql;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

               IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_dtl_repeat_cnt = 0
               THEN
                  UTL_FILE.
                  put_line (p_output_file,
                            lc_build_dtl_line_label || CHR (13));

                 ln_max_rownum := 0;
				 SELECT NVL(MAX(ROWNUMBER),1)
				   INTO ln_max_rownum
				   FROM xx_cdh_ebl_templ_dtl_txt
				  WHERE cust_doc_id = p_cust_doc_id
					AND attribute20 = 'Y'
					AND record_type = lc_trx_type;

				  IF ln_max_rownum = ln_get_line_dist_rows
				  THEN
				  ln_dtl_repeat_cnt := 1;
				  END IF;
               END IF;

               ln_customer_trx_id := NULL;

               --lc_txt_line_previous := NULL;
               --lc_txt_line_current := NULL;
               OPEN c_dtl_line_cursor FOR lc_dtl_lines_sql;    -- line cursor.

               LOOP
                  FETCH c_dtl_line_cursor INTO lc_txt_line;

                  EXIT WHEN c_dtl_line_cursor%NOTFOUND;

                  --fnd_file.put_line(fnd_file.log,lc_txt_line);
                  IF lc_repeat_dtl_header = 'Y'
                  THEN
                     UTL_FILE.
                     put_line (p_output_file,
                               lc_build_dtl_line_label || CHR (13));
                  END IF;

                  --lc_txt_line_current := lc_txt_line;
                  --IF NVL(lc_txt_line_previous,'X') != lc_txt_line_current THEN
                  lc_err_location_msg :=
                     'Writing the line level record into file '
                     || lc_txt_line;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                  UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
                  UTL_FILE.fflush (p_output_file);
               --END IF;
               --lc_txt_line_previous := lc_txt_line;
               END LOOP;                                        -- line cursor

               CLOSE c_dtl_line_cursor;
            ELSIF     lc_hdr_exists = 'Y'
                  AND lc_line_exists = 'N'
                  AND lc_dist_exists = 'N'
            THEN
               lc_err_location_msg :=
                  'Opening the Header Cursor, Query :' || lc_dtl_hdr_sql;
               XX_AR_EBL_COMMON_UTIL_PKG.
               PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);

               --start of changes for defect 41016
               IF lc_print_dtl_label = 'Y' AND lc_repeat_dtl_header = 'N' AND ln_hdr_repeat_cnt = 0
               THEN
                  UTL_FILE.
                  put_line (p_output_file,
                            lc_build_dtl_hdr_label || CHR (13));

                 ln_max_rownum := 0;
				 SELECT NVL(MAX(ROWNUMBER),1)
				   INTO ln_max_rownum
				   FROM xx_cdh_ebl_templ_dtl_txt
				  WHERE cust_doc_id = p_cust_doc_id
					AND attribute20 = 'Y'
					AND record_type = lc_trx_type;

				  IF ln_max_rownum = ln_get_line_dist_rows
				  THEN
				  ln_hdr_repeat_cnt := 1;
				  END IF;
               END IF;

               --end of changes for defect 41016
               OPEN c_dtl_hdr_cursor FOR lc_dtl_hdr_sql;        -- hdr cursor.

               LOOP
                  FETCH c_dtl_hdr_cursor
                  INTO ln_customer_trx_id, lc_txt_line;

                  EXIT WHEN c_dtl_hdr_cursor%NOTFOUND;

                  IF lc_repeat_dtl_header = 'Y'
                  THEN
                     UTL_FILE.
                     put_line (p_output_file,
                               lc_build_dtl_hdr_label || CHR (13));
                  END IF;

                  lc_err_location_msg :=
                     'Writing the header level record into file '
                     || lc_txt_line;
                  XX_AR_EBL_COMMON_UTIL_PKG.
                  PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
                  UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
                  UTL_FILE.fflush (p_output_file);
               END LOOP;                                         -- hdr cursor

               CLOSE c_dtl_hdr_cursor;
            ELSE
               lc_err_location_msg :=
                  'Error While Rendering TXT Details Data for Cust Doc Id : '
                  || p_cust_doc_id
                  || ' - '
                  || 'File Id : '
                  || p_file_id
                  || ' - '
                  || 'record types selection, Header : '
                  || lc_hdr_exists
                  || ', Lines : '
                  || lc_line_exists
                  || ' Dist Lines :'
                  || lc_dist_exists;
               p_dtl_error_flag := 'Y';
               p_dtl_error_msg := lc_err_location_msg;
            END IF;           -----------> Opening Cursors based on setup End.
         -- Added on 12-JUL-2017 for Defect#41307
         END LOOP;                                             --get_dist_rows

         CLOSE get_dist_rows;


	END LOOP;                                 --c_get_dist_record_type

  CLOSE c_get_dist_record_type;


		 END LOOP;                         --get_dist_rows

		 CLOSE c_get_dist_custtrx;

         -- End of Added on 12-JUL-2017 for Defect#41307
         p_dtl_error_flag := 'N';
      END IF;                     -- Summary Bill
   EXCEPTION
      WHEN OTHERS
      THEN
         lc_err_location_msg :=
               'Error While Rendering TXT Details Data for Cust Doc Id : '
            || p_cust_doc_id
            || ' - '
            || 'File Id : '
            || p_file_id
            || ' - '
            || SQLCODE
            || ' - '
            || SQLERRM;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
         p_dtl_error_flag := 'Y';
         p_dtl_error_msg := lc_err_location_msg;
   END RENDER_TXT_DTL_DATA;

   -- +=====================================================================================+
   -- |                  Office Depot - Project Simplify                                    |
   -- +=====================================================================================+
   -- | Name        : RENDER_TXT_TRL_DATA                                                   |
   -- | Description : This Procedure is used for framing the sql based on                   |
   -- |               Trailer Records data and write it into TXT file.                      |
   -- |Parameters   : p_cust_doc_id                                                         |
   -- |             , p_file_id                                                             |
   -- |             , p_org_id                                                              |
   -- |             , p_output_file                                                         |
   -- |             , p_debug_flag                                                          |
   -- |             , p_error_flag                                                          |
   -- |Change Record:                                                                       |
   -- |===============                                                                      |
   -- |Version   Date          Author                 Remarks                               |
   -- |=======   ==========   =============           ======================================|
   -- |DRAFT 1.0 04-MAR-2016  Suresh N                Initial draft version                 |
   -- |      1.1 25-MAY-2017  Punit Gupta CG          Changes done for defect raised in UAT |
   -- |      1.2 18-May-2018  Aniket J    CG          Changes for Requirement  #NAIT-36070  |
   -- +=====================================================================================+
   PROCEDURE RENDER_TXT_TRL_DATA (p_cust_doc_id          IN     NUMBER,
                                  p_file_id              IN     NUMBER,
                                  p_org_id               IN     NUMBER,
                                  p_output_file          IN     UTL_FILE.FILE_TYPE,
                                  p_file_creation_type   IN     VARCHAR2,
                                  p_delimiter_char       IN     VARCHAR2,
                                  p_debug_flag           IN     VARCHAR2,
                                  p_trl_error_flag          OUT VARCHAR2,
                                  p_trl_error_msg           OUT VARCHAR2)
   IS
      CURSOR get_dist_rows
      IS
           SELECT DISTINCT rownumber
             FROM xx_cdh_ebl_templ_trl_txt
            WHERE cust_doc_id = p_cust_doc_id           --AND attribute1 = 'Y'
              AND attribute20 = 'Y'
         ORDER BY rownumber;

      CURSOR c_trl_fields (
         p_rownum IN NUMBER)
      IS
         SELECT TO_NUMBER (xftv.source_value1) field_id,
                xcetht.seq,
                xcetht.label,
                xftv.target_value1 data_type,
                xcetht.cust_doc_id,
                xcetht.rownumber rec_order                --Formatting columns
                                          ,
                xcetht.data_format,
                xcetht.start_txt_pos,
                xcetht.end_txt_pos,
                xcetht.fill_txt_pos,
                xcetht.alignment,
                xcetht.start_val_pos,
                xcetht.end_val_pos,
                xcetht.prepend_char,
                xcetht.append_char,
				 -- Added by Aniket CG 15 May #NAIT-36070
                xftv.target_value24,
                xftv.source_value4
                  -- Added by Aniket CG 15 May #NAIT-36070
           FROM xx_fin_translatedefinition xftd,
                xx_fin_translatevalues xftv,
                xx_cdh_ebl_templ_trl_txt xcetht
          WHERE     xftd.translate_id = xftv.translate_id
                AND xftv.source_value1 = xcetht.field_id
                AND xcetht.cust_doc_id = p_cust_doc_id
                AND xcetht.rownumber = p_rownum
                AND xftd.translation_name = 'XX_CDH_EBL_TXT_TRL_FIELDS'
                AND xftv.target_value19 = 'DT' -- Uncommented by Punit on 25-MAY-2017
                AND xftv.enabled_flag = 'Y'
                AND TRUNC (SYSDATE) BETWEEN TRUNC (xftv.start_date_active)
                                        AND TRUNC (
                                               NVL (xftv.end_date_active,
                                                    SYSDATE + 1))
                --AND xcetht.attribute1 = 'Y'
                AND xcetht.attribute20 = 'Y'
         UNION
         SELECT xcetht.field_id field_id,
                xcetht.seq,
                xcetht.label,
                'VARCHAR2' data_type,
                xcetht.cust_doc_id,
                xcetht.rownumber rec_order                --Formatting columns
                                          ,
                xcetht.data_format,
                xcetht.start_txt_pos,
                xcetht.end_txt_pos,
                xcetht.fill_txt_pos,
                xcetht.alignment,
                xcetht.start_val_pos,
                xcetht.end_val_pos,
                xcetht.prepend_char,
                xcetht.append_char,
				 -- Added by Aniket CG 15 May #NAIT-36070
                NULL,
                NULL
                  --End Added by Aniket CG 15 May #NAIT-36070
           FROM xx_cdh_ebl_templ_trl_txt xcetht,
                xx_cdh_ebl_concat_fields_txt xcecft
          WHERE     xcetht.field_id = xcecft.conc_field_id
                AND xcetht.cust_doc_id = xcecft.cust_doc_id
                AND xcetht.cust_doc_id = p_cust_doc_id
                AND xcetht.rownumber = p_rownum
         ORDER BY rec_order, seq;

      lc_column             VARCHAR2 (20) := 'COLUMN';
      ln_count              NUMBER := 1;

      TYPE lc_ref_cursor IS REF CURSOR;

      lc_cursor             lc_ref_cursor;
      lc_txt_line           VARCHAR2 (32767);
      lc_build_trl_sql      VARCHAR2 (32767);
      lc_row_order          NUMBER;
      lc_err_location_msg   VARCHAR2 (32767);
      lb_debug_flag         BOOLEAN;
      lc_build_trl_label    VARCHAR2 (32767) := NULL;
      lc_print_trl_label    VARCHAR2 (1);
      lc_col_trl_label      VARCHAR2 (200);
	   --Start Added by Aniket CG 15 May #NAIT-36070
      ln_total_rec_cnt      NUMBER := 0;
      ln_total_hdr_rec_cnt  NUMBER := 0;
      ln_total_trl_rec_cnt  NUMBER := 0;
      ln_total_dtl_rec_cnt  NUMBER := 0;
      lc_update_column      VARCHAR2 (32767);
      ln_total_rec_nbl_cnt      NUMBER := 0;
      ln_total_hdr_rec_nbl_cnt  NUMBER := 0;
      ln_total_trl_rec_nbl_cnt  NUMBER := 0;
      ln_total_dtl_rec_nbl_cnt  NUMBER := 0;
      lc_update_nbl_column    VARCHAR2 (32767);
      ln_total_dtl_cnt        NUMBER := 0;
      ln_total_dtl_sku_cnt    NUMBER := 0;
      ln_total_dtl_inv_cnt    NUMBER := 0;
      --End Added by Aniket CG 15 May #NAIT-36070
   BEGIN
      IF (p_debug_flag = 'Y')
      THEN
         lb_debug_flag := TRUE;
      ELSE
         lb_debug_flag := FALSE;
      END IF;

      lc_err_location_msg := 'In Render Trailer Data... ';
      XX_AR_EBL_COMMON_UTIL_PKG.
      PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);

      BEGIN
         SELECT DISTINCT NVL (include_label, 'N')
           INTO lc_print_trl_label
           FROM xx_cdh_ebl_templ_trl_txt
          WHERE cust_doc_id = p_cust_doc_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            lc_print_trl_label := 'N';
      END;

      --Build the cursor to write the header summary data into eTXT File.
      OPEN get_dist_rows;

      LOOP
         FETCH get_dist_rows INTO lc_row_order;

         EXIT WHEN get_dist_rows%NOTFOUND;
         lc_build_trl_label := NULL;

         FOR lc_trl_fields IN c_trl_fields (lc_row_order)
         LOOP
            fnd_file.put_line (fnd_file.LOG, p_cust_doc_id);
			--Start Added by Aniket CG 15 May #NAIT-36070
              BEGIN
                IF LOWER(lc_trl_fields.target_value24) = 'xx_ar_ebl_txt_spl_logic_pkg.get_total_rec_count' AND UPPER(lc_trl_fields.source_value4) = 'TOTAL_REC_CNT_NBL' THEN
                  ln_total_hdr_rec_nbl_cnt                    := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_HDR_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'N') ;
                  ln_total_trl_rec_nbl_cnt                    := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_TRL_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'N') ;
                  ln_total_dtl_rec_nbl_cnt                    := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_DTL_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'N') ;
                  ln_total_rec_nbl_cnt                        := ln_total_hdr_rec_nbl_cnt+ln_total_trl_rec_nbl_cnt + ln_total_dtl_rec_nbl_cnt;
                  lc_update_nbl_column                        := 'UPDATE xx_ar_ebl_txt_trl_stg SET ' || lc_column || ln_count ||' = '|| ln_total_rec_nbl_cnt || '
              where  rec_type != ' ||'''FID'' and file_id =' || p_file_id || ' and rec_order = ' || lc_row_order ;
                  fnd_file.put_line (fnd_file.LOG, 'In Count with No Lable ' || ln_total_rec_nbl_cnt );
                  EXECUTE IMMEDIATE lc_update_nbl_column;
                ELSIF LOWER(lc_trl_fields.target_value24) = 'xx_ar_ebl_txt_spl_logic_pkg.get_total_rec_count' AND UPPER(lc_trl_fields.source_value4) = 'TOTAL_REC_CNT_LBL' THEN
                  ln_total_hdr_rec_cnt                           := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_HDR_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'Y') ;
                  ln_total_trl_rec_cnt                           := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_TRL_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'Y') ;
                  ln_total_dtl_rec_cnt                           := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_DTL_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'Y') ;
                  ln_total_rec_cnt                               := ln_total_hdr_rec_cnt+ln_total_trl_rec_cnt + ln_total_dtl_rec_cnt;
                  lc_update_column                               := 'UPDATE xx_ar_ebl_txt_trl_stg SET ' || lc_column || ln_count ||' = '|| ln_total_rec_cnt || '
              where  rec_type != ' ||'''FID'' and file_id =' || p_file_id || ' and rec_order = ' || lc_row_order ;
                  fnd_file.put_line (fnd_file.LOG, ' In count  WITH LABEL ' || ln_total_rec_cnt );
                  EXECUTE IMMEDIATE lc_update_column;
                ELSIF LOWER(lc_trl_fields.target_value24) = 'xx_ar_ebl_txt_spl_logic_pkg.get_total_rec_count' AND UPPER(lc_trl_fields.source_value4) = 'TOTAL_REC_CNT' THEN
                  ln_total_dtl_inv_cnt                           := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_INV_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'INV') ;
                  lc_update_column                               := 'UPDATE xx_ar_ebl_txt_trl_stg SET ' || lc_column || ln_count ||' = '|| ln_total_dtl_inv_cnt || '
              where  rec_type != ' ||'''FID'' and file_id =' || p_file_id || ' and rec_order = ' || lc_row_order ;
                  fnd_file.put_line (fnd_file.LOG, 'wave4 - WITH INV COUNT ' || ln_total_dtl_inv_cnt );
                  EXECUTE IMMEDIATE lc_update_column;
                ELSIF LOWER(lc_trl_fields.target_value24) = 'xx_ar_ebl_txt_spl_logic_pkg.get_total_rec_count' AND UPPER(lc_trl_fields.source_value4) = 'TOTAL_REC_CNT_SKU' THEN
                  ln_total_dtl_sku_cnt                           := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_INV_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'SKU') ;
                  lc_update_column                               := 'UPDATE xx_ar_ebl_txt_trl_stg SET ' || lc_column || ln_count ||' = '|| ln_total_dtl_sku_cnt || '
              where  rec_type != ' ||'''FID'' and file_id =' || p_file_id || ' and rec_order = ' || lc_row_order ;
                  fnd_file.put_line (fnd_file.LOG, ' In count SKU COUNT ' || ln_total_dtl_sku_cnt );
                  EXECUTE IMMEDIATE lc_update_column;
                ELSIF LOWER(lc_trl_fields.target_value24) = 'xx_ar_ebl_txt_spl_logic_pkg.get_total_rec_count' AND UPPER(lc_trl_fields.source_value4) = 'TOTAL_REC_CNT_DTL' THEN
                  ln_total_dtl_cnt                               := XX_AR_EBL_RENDER_TXT_PKG.RENDER_TXT_INV_CNT ( p_cust_doc_id , p_file_id, lc_row_order , p_org_id, p_file_creation_type , p_delimiter_char, p_debug_flag ,'DTL') ;
                  lc_update_column                               := 'UPDATE xx_ar_ebl_txt_trl_stg SET ' || lc_column || ln_count ||' = '|| ln_total_dtl_cnt || '
              where  rec_type != ' ||'''FID'' and file_id =' || p_file_id || ' and rec_order = ' || lc_row_order ;
                  fnd_file.put_line (fnd_file.LOG, ' IN Count  WITH DTL COUNT ' || ln_total_dtl_cnt );
                  EXECUTE IMMEDIATE lc_update_column;
                END IF;
              EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line (fnd_file.LOG, ' Error In Updating Counts ' || SQLERRM );
              END;
              -- END Added by Aniket CG 15 May #NAIT-36070


            IF p_file_creation_type = 'DELIMITED'
            THEN
               lc_build_trl_sql :=
                     lc_build_trl_sql
                  || get_formatted_etxt_column (p_cust_doc_id,
                                                lc_trl_fields.alignment,
                                                lc_trl_fields.start_val_pos,
                                                lc_trl_fields.end_val_pos,
                                                lc_trl_fields.fill_txt_pos,
                                                lc_trl_fields.prepend_char,
                                                lc_trl_fields.append_char,
                                                lc_trl_fields.data_type,
                                                lc_trl_fields.data_format,
                                                lc_column || ln_count,
                                                p_debug_flag,
                                                p_delimiter_char)
                  || '||'
                  || ''''
                  || p_delimiter_char
                  || ''''
                  || '||';
               lc_build_trl_label :=
                     lc_build_trl_label
                  || lc_trl_fields.label
                  || p_delimiter_char;
               ln_count := ln_count + 1;
            ELSIF p_file_creation_type = 'FIXED'
            THEN
               lc_build_trl_sql :=
                     lc_build_trl_sql
                  || get_formatted_etxt_column (p_cust_doc_id,
                                                lc_trl_fields.alignment,
                                                lc_trl_fields.start_val_pos,
                                                lc_trl_fields.end_val_pos,
                                                lc_trl_fields.fill_txt_pos,
                                                lc_trl_fields.prepend_char,
                                                lc_trl_fields.append_char,
                                                lc_trl_fields.data_type,
                                                lc_trl_fields.data_format,
                                                lc_column || ln_count,
                                                p_debug_flag,
                                                NULL)
                  || '||';
               lc_col_trl_label := NULL;

               BEGIN
                  SELECT LPAD (lc_trl_fields.label,
                               ((lc_trl_fields.end_txt_pos - lc_trl_fields.start_txt_pos) +1), --Changed for Defect 44465  --lc_trl_fields.start_val_pos,
                               ' ')
                    INTO lc_col_trl_label
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lc_col_trl_label := NULL;
               END;

               lc_build_trl_label := lc_build_trl_label || lc_col_trl_label;
               ln_count := ln_count + 1;
            END IF;
         END LOOP;                                              --c_trl_fields

         IF p_file_creation_type = 'DELIMITED'
         THEN
            lc_build_trl_sql :=
               SUBSTR (
                  lc_build_trl_sql,
                  1,
                  (LENGTH (lc_build_trl_sql) - LENGTH (p_delimiter_char) - 6));
            lc_build_trl_label :=
               SUBSTR (
                  lc_build_trl_label,
                  1,
                  (LENGTH (lc_build_trl_label) - LENGTH (p_delimiter_char)));
         ELSIF p_file_creation_type = 'FIXED'
         THEN
            lc_build_trl_sql :=
               SUBSTR (lc_build_trl_sql, 1, (LENGTH (lc_build_trl_sql) - 2));
         END IF;

         lc_err_location_msg := 'Trailer Columns : ' || lc_build_trl_sql;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
         lc_build_trl_sql :=
               'SELECT DISTINCT '
            || lc_build_trl_sql
            || ' FROM XX_AR_EBL_TXT_TRL_STG WHERE file_id = '
            || p_file_id
            || ' AND REC_TYPE != '
            || '''FID'''
            || ' AND REC_ORDER = '
            || lc_row_order;
         lc_err_location_msg := 'Trailer SQL : ' || lc_build_trl_sql;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);

         IF lc_print_trl_label = 'Y'
         THEN
            UTL_FILE.put_line (p_output_file, lc_build_trl_label || CHR (13));
            UTL_FILE.fflush (p_output_file);
         END IF;

         OPEN lc_cursor FOR lc_build_trl_sql;

         LOOP
            FETCH lc_cursor INTO lc_txt_line;

            EXIT WHEN lc_cursor%NOTFOUND;
            --fnd_file.put_line(fnd_file.log,lc_txt_line);
            UTL_FILE.put_line (p_output_file, lc_txt_line || CHR (13));
            UTL_FILE.fflush (p_output_file);
         END LOOP;                                          --lc_build_trl_sql

         lc_build_trl_sql := NULL;
         ln_count := 1;
      END LOOP;                                                --get_dist_rows

      CLOSE get_dist_rows;
      p_trl_error_flag := 'N';
   EXCEPTION
      WHEN OTHERS
      THEN
         lc_err_location_msg :=
               'Error While Rendering TXT Details Data for Cust Doc Id : '
            || p_cust_doc_id
            || ' - '
            || 'File Id : '
            || p_file_id
            || ' - '
            || SQLCODE
            || ' - '
            || SQLERRM;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, TRUE, lc_err_location_msg);
         p_trl_error_msg := lc_err_location_msg;
         p_trl_error_flag := 'Y';
   END RENDER_TXT_TRL_DATA;

-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- +=====================================================================================+
-- | Name        : RENDER_TXT_HDR_CNT                                                   |
-- | Description : This Function is used for to get counts in Header                     |
-- |Parameters   : p_cust_doc_id                                                         |
-- |             , p_file_id                                                             |
-- |             , p_org_id                                                              |
-- |             , p_output_file                                                         |
-- |             , p_debug_flag                                                          |
-- |             , p_error_flag                                                          |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date          Author                 Remarks                               |
-- |=======   ==========   =============           ======================================|
-- | 1.1      18-May-2018  Aniket J    CG          Changes for Requirement  #NAIT-36070  |
-- +=====================================================================================+
FUNCTION RENDER_TXT_HDR_CNT(
    p_cust_doc_id        IN NUMBER,
    p_file_id            IN NUMBER,
    p_rownum             IN NUMBER,
    p_org_id             IN NUMBER,
    p_file_creation_type IN VARCHAR2,
    p_delimiter_char     IN VARCHAR2,
    p_debug_flag         IN VARCHAR2,
    p_lbl_flag           IN VARCHAR2 DEFAULT 'N')
  RETURN NUMBER
IS
  CURSOR get_dist_rows
  IS
    SELECT DISTINCT rownumber
    FROM xx_cdh_ebl_templ_hdr_txt
    WHERE cust_doc_id = p_cust_doc_id --AND attribute1 = 'Y'
    AND attribute20   = 'Y'
    ORDER BY rownumber;
  CURSOR c_hdr_summary_fields ( p_rownum IN NUMBER)
  IS
    SELECT TO_NUMBER (xftv.source_value1) field_id,
      xcetht.seq,
      xcetht.label,
      xftv.target_value1 data_type,
      xcetht.cust_doc_id,
      xcetht.rownumber rec_order --Formatting columns
      ,
      xcetht.data_format,
      xcetht.start_txt_pos,
      xcetht.end_txt_pos,
      xcetht.fill_txt_pos,
      xcetht.alignment,
      xcetht.start_val_pos,
      xcetht.end_val_pos,
      xcetht.prepend_char,
      xcetht.append_char
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv,
      xx_cdh_ebl_templ_hdr_txt xcetht
    WHERE xftd.translate_id   = xftv.translate_id
    AND xftv.source_value1    = xcetht.field_id
    AND xcetht.cust_doc_id    = p_cust_doc_id
    AND xcetht.rownumber      = p_rownum
    AND xftd.translation_name = 'XX_CDH_EBL_TXT_HDR_FIELDS'
    AND xftv.target_value19   = 'DT' -- Uncommented by Punit on 25-MAY-2017
    AND xftv.enabled_flag     = 'Y'
    AND TRUNC (SYSDATE) BETWEEN TRUNC (xftv.start_date_active) AND TRUNC ( NVL (xftv.end_date_active, SYSDATE + 1))
      --AND xcetht.attribute1 = 'Y'
    AND xcetht.attribute20 = 'Y'
  UNION
  SELECT xcetht.field_id field_id,
    xcetht.seq,
    xcetht.label,
    'VARCHAR2' data_type,
    xcetht.cust_doc_id,
    xcetht.rownumber rec_order --Formatting columns
    ,
    xcetht.data_format,
    xcetht.start_txt_pos,
    xcetht.end_txt_pos,
    xcetht.fill_txt_pos,
    xcetht.alignment,
    xcetht.start_val_pos,
    xcetht.end_val_pos,
    xcetht.prepend_char,
    xcetht.append_char
  FROM xx_cdh_ebl_templ_hdr_txt xcetht,
    xx_cdh_ebl_concat_fields_txt xcecft
  WHERE xcetht.field_id  = xcecft.conc_field_id
  AND xcetht.cust_doc_id = xcecft.cust_doc_id
  AND xcetht.cust_doc_id = p_cust_doc_id
  AND xcetht.rownumber   = p_rownum
  ORDER BY rec_order,
    seq;
  lc_column VARCHAR2 (20) := 'COLUMN';
  ln_count  NUMBER        := 1;
TYPE lc_ref_cursor
IS
  REF
  CURSOR;
    lc_cursor lc_ref_cursor;
    lc_txt_line         VARCHAR2 (32767);
    lc_build_hdr_sql    VARCHAR2 (32767);
    lc_build_hdr_label  VARCHAR2 (32767) := NULL;
    lc_row_order        NUMBER;
    lc_err_location_msg VARCHAR2 (32767);
    lb_debug_flag       BOOLEAN;
    lc_print_hdr_label  VARCHAR2 (1);
    lc_hdr_col_label    VARCHAR2 (200);
    --Aniket 15may
    ln_total_rec_cnt      NUMBER := 0 ;
    ln_total_rec_cnt_rnum NUMBER := 0;
  BEGIN
    IF (p_debug_flag = 'Y') THEN
      lb_debug_flag := TRUE;
    ELSE
      lb_debug_flag := FALSE;
    END IF;

    BEGIN
      SELECT DISTINCT NVL (include_label, 'N')
      INTO lc_print_hdr_label
      FROM xx_cdh_ebl_templ_hdr_txt
      WHERE cust_doc_id = p_cust_doc_id;
  EXCEPTION
  WHEN OTHERS THEN
    lc_print_hdr_label := 'N';
  END;
  --Build the cursor to write the header summary data into eTXT File.
  OPEN get_dist_rows;
  LOOP
    FETCH get_dist_rows INTO lc_row_order;
    EXIT
  WHEN get_dist_rows%NOTFOUND;

    FOR lc_hdr_summary_fields IN c_hdr_summary_fields (lc_row_order)
    LOOP

      IF p_file_creation_type    = 'DELIMITED' THEN
        lc_build_hdr_sql        := lc_build_hdr_sql || get_formatted_etxt_column ( p_cust_doc_id, lc_hdr_summary_fields.alignment, lc_hdr_summary_fields.start_val_pos, lc_hdr_summary_fields.end_val_pos, lc_hdr_summary_fields.fill_txt_pos, lc_hdr_summary_fields.prepend_char, lc_hdr_summary_fields.append_char, lc_hdr_summary_fields.data_type, lc_hdr_summary_fields.data_format, lc_column || ln_count, p_debug_flag, p_delimiter_char) || '||' || '''' || p_delimiter_char || '''' || '||';
        lc_build_hdr_label      := lc_build_hdr_label || lc_hdr_summary_fields.label || p_delimiter_char;
        ln_count                := ln_count + 1;
      ELSIF p_file_creation_type = 'FIXED' THEN
        lc_build_hdr_sql        := lc_build_hdr_sql || get_formatted_etxt_column ( p_cust_doc_id, lc_hdr_summary_fields.alignment, lc_hdr_summary_fields.start_val_pos, lc_hdr_summary_fields.end_val_pos, lc_hdr_summary_fields.fill_txt_pos, lc_hdr_summary_fields.prepend_char, lc_hdr_summary_fields.append_char, lc_hdr_summary_fields.data_type, lc_hdr_summary_fields.data_format, lc_column || ln_count, p_debug_flag, NULL) || '||';
        lc_hdr_col_label        := NULL;
        BEGIN
          SELECT LPAD (lc_hdr_summary_fields.label, lc_hdr_summary_fields.start_val_pos, ' ')
          INTO lc_hdr_col_label
          FROM DUAL;
        EXCEPTION
        WHEN OTHERS THEN
          lc_hdr_col_label := NULL;
        END;
        lc_build_hdr_label := lc_build_hdr_label || lc_hdr_col_label;
        ln_count           := ln_count + 1;
      END IF;
    END LOOP; --c_hdr_summary_fields
    IF p_file_creation_type    = 'DELIMITED' THEN
      lc_build_hdr_sql        := SUBSTR ( lc_build_hdr_sql, 1, (LENGTH (lc_build_hdr_sql)     - LENGTH (p_delimiter_char) - 6));
      lc_build_hdr_label      := SUBSTR ( lc_build_hdr_label, 1, (LENGTH (lc_build_hdr_label) - LENGTH (p_delimiter_char)));
    ELSIF p_file_creation_type = 'FIXED' THEN
      lc_build_hdr_sql        := SUBSTR (lc_build_hdr_sql, 1, (LENGTH (lc_build_hdr_sql) - 2));
    END IF;

    lc_build_hdr_sql :=
               'SELECT DISTINCT '
            || lc_build_hdr_sql
            || ' FROM XX_AR_EBL_TXT_HDR_STG WHERE file_id = '
            || p_file_id
            || ' AND REC_TYPE != '
            || '''FID'''
            || ' AND REC_ORDER = '
            || lc_row_order;
         lc_err_location_msg := 'Header Summary SQL : ' || lc_build_hdr_sql;
         XX_AR_EBL_COMMON_UTIL_PKG.
         PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);

     fnd_file.put_line (fnd_file.LOG,'Wave 4 HDR function  Return  ' || lc_build_hdr_sql ) ;
    EXECUTE IMMEDIATE ' select count(1)   FROM  ( '|| lc_build_hdr_sql ||')' INTO ln_total_rec_cnt_rnum;
    lc_build_hdr_sql     := NULL;
    ln_count             := 1;
    ln_total_rec_cnt     := ln_total_rec_cnt + ln_total_rec_cnt_rnum ;
    IF lc_print_hdr_label = 'Y' THEN
      IF p_lbl_flag       = 'Y' THEN
        ln_total_rec_cnt := ln_total_rec_cnt +1 ; --add label line count
      END IF;
    END IF;
  END LOOP;
  fnd_file.put_line (fnd_file.LOG,'Wave 4 HDR function  Return  ' || ln_total_rec_cnt ) ;
  RETURN ln_total_rec_cnt;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG,' Error IN RENDER_TXT_HDR_CNT ' || SQLERRM );
  RETURN 0;
END RENDER_TXT_HDR_CNT;
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- +=====================================================================================+
-- | Name        : RENDER_TXT_TRL_CNT                                                    |
-- | Description : This Function is used for to get counts in TRL                        |
-- |Parameters   : p_cust_doc_id                                                         |
-- |             , p_file_id                                                             |
-- |             , p_org_id                                                              |
-- |             , p_output_file                                                         |
-- |             , p_debug_flag                                                          |
-- |             , p_error_flag                                                          |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date          Author                 Remarks                               |
-- |=======   ==========   =============           ======================================|
-- | 1.1      18-May-2018  Aniket J    CG          Changes for Requirement  #NAIT-36070  |
-- +=====================================================================================+
FUNCTION RENDER_TXT_TRL_CNT(
    p_cust_doc_id        IN NUMBER,
    p_file_id            IN NUMBER,
    p_rownum             IN NUMBER,
    p_org_id             IN NUMBER,
    p_file_creation_type IN VARCHAR2,
    p_delimiter_char     IN VARCHAR2,
    p_debug_flag         IN VARCHAR2,
    p_lbl_flag           IN VARCHAR2 DEFAULT 'N')
  RETURN NUMBER
IS
  CURSOR get_dist_rows
  IS
    SELECT DISTINCT rownumber
    FROM xx_cdh_ebl_templ_trl_txt
    WHERE cust_doc_id = p_cust_doc_id --AND attribute1 = 'Y'
    AND attribute20   = 'Y'
    ORDER BY rownumber;
  CURSOR c_trl_fields ( p_rownum IN NUMBER)
  IS
    SELECT TO_NUMBER (xftv.source_value1) field_id,
      xcetht.seq,
      xcetht.label,
      xftv.target_value1 data_type,
      xcetht.cust_doc_id,
      xcetht.rownumber rec_order --Formatting columns
      ,
      xcetht.data_format,
      xcetht.start_txt_pos,
      xcetht.end_txt_pos,
      xcetht.fill_txt_pos,
      xcetht.alignment,
      xcetht.start_val_pos,
      xcetht.end_val_pos,
      xcetht.prepend_char,
      xcetht.append_char
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv,
      xx_cdh_ebl_templ_trl_txt xcetht
    WHERE xftd.translate_id   = xftv.translate_id
    AND xftv.source_value1    = xcetht.field_id
    AND xcetht.cust_doc_id    = p_cust_doc_id
    AND xcetht.rownumber      = p_rownum
    AND xftd.translation_name = 'XX_CDH_EBL_TXT_TRL_FIELDS'
    AND xftv.target_value19   = 'DT' -- Uncommented by Punit on 25-MAY-2017
    AND xftv.enabled_flag     = 'Y'
    AND TRUNC (SYSDATE) BETWEEN TRUNC (xftv.start_date_active) AND TRUNC ( NVL (xftv.end_date_active, SYSDATE + 1))
      --AND xcetht.attribute1 = 'Y'
    AND xcetht.attribute20 = 'Y'
  UNION
  SELECT xcetht.field_id field_id,
    xcetht.seq,
    xcetht.label,
    'VARCHAR2' data_type,
    xcetht.cust_doc_id,
    xcetht.rownumber rec_order --Formatting columns
    ,
    xcetht.data_format,
    xcetht.start_txt_pos,
    xcetht.end_txt_pos,
    xcetht.fill_txt_pos,
    xcetht.alignment,
    xcetht.start_val_pos,
    xcetht.end_val_pos,
    xcetht.prepend_char,
    xcetht.append_char
  FROM xx_cdh_ebl_templ_trl_txt xcetht,
    xx_cdh_ebl_concat_fields_txt xcecft
  WHERE xcetht.field_id  = xcecft.conc_field_id
  AND xcetht.cust_doc_id = xcecft.cust_doc_id
  AND xcetht.cust_doc_id = p_cust_doc_id
  AND xcetht.rownumber   = p_rownum
  ORDER BY rec_order,
    seq;
  lc_column VARCHAR2 (20) := 'COLUMN';
  ln_count  NUMBER        := 1;
TYPE lc_ref_cursor
IS
  REF
  CURSOR;
    lc_cursor lc_ref_cursor;
    lc_txt_line           VARCHAR2 (32767);
    lc_build_trl_sql      VARCHAR2 (32767);
    lc_row_order          NUMBER;
    lc_err_location_msg   VARCHAR2 (32767);
    lb_debug_flag         BOOLEAN;
    lc_build_trl_label    VARCHAR2 (32767) := NULL;
    lc_print_trl_label    VARCHAR2 (1);
    lc_col_trl_label      VARCHAR2 (200);
    ln_total_rec_cnt      NUMBER := 0;
    ln_total_rec_cnt_rnum NUMBER := 0;
  BEGIN
    IF (p_debug_flag = 'Y') THEN
      lb_debug_flag := TRUE;
    ELSE
      lb_debug_flag := FALSE;
    END IF;
    BEGIN
      SELECT DISTINCT NVL (include_label, 'N')
      INTO lc_print_trl_label
      FROM xx_cdh_ebl_templ_trl_txt
      WHERE cust_doc_id = p_cust_doc_id;
  EXCEPTION
  WHEN OTHERS THEN
    lc_print_trl_label := 'N';
  END;
  --Build the cursor to write the header summary data into eTXT File.
  OPEN get_dist_rows;
  LOOP
    FETCH get_dist_rows INTO lc_row_order;
    EXIT
  WHEN get_dist_rows%NOTFOUND;
    FOR lc_trl_fields IN c_trl_fields (lc_row_order)
    LOOP
      IF p_file_creation_type    = 'DELIMITED' THEN
        lc_build_trl_sql        := lc_build_trl_sql || get_formatted_etxt_column (p_cust_doc_id, lc_trl_fields.alignment, lc_trl_fields.start_val_pos, lc_trl_fields.end_val_pos, lc_trl_fields.fill_txt_pos, lc_trl_fields.prepend_char, lc_trl_fields.append_char, lc_trl_fields.data_type, lc_trl_fields.data_format, lc_column || ln_count, p_debug_flag, p_delimiter_char) || '||' || '''' || p_delimiter_char || '''' || '||';
        lc_build_trl_label      := lc_build_trl_label || lc_trl_fields.label || p_delimiter_char;
        ln_count                := ln_count + 1;
      ELSIF p_file_creation_type = 'FIXED' THEN
        lc_build_trl_sql        := lc_build_trl_sql || get_formatted_etxt_column (p_cust_doc_id, lc_trl_fields.alignment, lc_trl_fields.start_val_pos, lc_trl_fields.end_val_pos, lc_trl_fields.fill_txt_pos, lc_trl_fields.prepend_char, lc_trl_fields.append_char, lc_trl_fields.data_type, lc_trl_fields.data_format, lc_column || ln_count, p_debug_flag, NULL) || '||';
        lc_col_trl_label        := NULL;
        BEGIN
          SELECT LPAD (lc_trl_fields.label, lc_trl_fields.start_val_pos, ' ')
          INTO lc_col_trl_label
          FROM DUAL;
        EXCEPTION
        WHEN OTHERS THEN
          lc_col_trl_label := NULL;
        END;
        lc_build_trl_label := lc_build_trl_label || lc_col_trl_label;
        ln_count           := ln_count + 1;
      END IF;
    END LOOP; --c_trl_fields
    IF p_file_creation_type    = 'DELIMITED' THEN
      lc_build_trl_sql        := SUBSTR ( lc_build_trl_sql, 1, (LENGTH (lc_build_trl_sql)     - LENGTH (p_delimiter_char) - 6));
      lc_build_trl_label      := SUBSTR ( lc_build_trl_label, 1, (LENGTH (lc_build_trl_label) - LENGTH (p_delimiter_char)));
    ELSIF p_file_creation_type = 'FIXED' THEN
      lc_build_trl_sql        := SUBSTR (lc_build_trl_sql, 1, (LENGTH (lc_build_trl_sql) - 2));
    END IF;


    lc_build_trl_sql :=
               'SELECT DISTINCT '
            || lc_build_trl_sql
            || ' FROM XX_AR_EBL_TXT_TRL_STG WHERE file_id = '
            || p_file_id
            || ' AND REC_TYPE != '
            || '''FID'''
            || ' AND REC_ORDER = '
            || lc_row_order;

    EXECUTE IMMEDIATE ' select count(1)   FROM  ( '|| lc_build_trl_sql ||')' INTO ln_total_rec_cnt_rnum;
    lc_build_trl_sql     := NULL;
    ln_count             := 1;
    ln_total_rec_cnt     := ln_total_rec_cnt + ln_total_rec_cnt_rnum ;
    IF lc_print_trl_label = 'Y' THEN
      IF p_lbl_flag       = 'Y' THEN
        ln_total_rec_cnt := ln_total_rec_cnt +1 ; --add label line count
      END IF;
    END IF;
  END LOOP;
  fnd_file.put_line (fnd_file.LOG,'Wave 4 TRL Function Return  ' || ln_total_rec_cnt ) ;
  RETURN ln_total_rec_cnt;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG,'Wave 4 TRL Exception  ' || SQLERRM ) ;
  RETURN 0;
END RENDER_TXT_TRL_CNT;
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- +=====================================================================================+
-- | Name        : RENDER_TXT_DTL_CNT                                                    |
-- | Description : This Function is used for to get counts in TRL                        |
-- |Parameters   : p_cust_doc_id                                                         |
-- |             , p_file_id                                                             |
-- |             , p_org_id                                                              |
-- |             , p_output_file                                                         |
-- |             , p_debug_flag                                                          |
-- |             , p_error_flag                                                          |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date          Author                 Remarks                               |
-- |=======   ==========   =============           ======================================|
-- | 1.1      18-May-2018  Aniket J    CG          Changes for Requirement  #NAIT-36070  |
-- +=====================================================================================+
FUNCTION RENDER_TXT_DTL_CNT(
    p_cust_doc_id        IN NUMBER,
    p_file_id            IN NUMBER,
    p_rownum             IN NUMBER,
    p_org_id             IN NUMBER,
    p_file_creation_type IN VARCHAR2,
    p_delimiter_char     IN VARCHAR2,
    p_debug_flag         IN VARCHAR2,
    p_lbl_flag           IN VARCHAR2 DEFAULT 'N')
  RETURN NUMBER
IS
  CURSOR c_get_dist_record_type
  IS
    SELECT DISTINCT record_type
    FROM xx_cdh_ebl_templ_dtl_txt xcedt,
      xx_ar_ebl_txt_dtl_stg xaebtds
    WHERE xcedt.cust_doc_id = xaebtds.cust_doc_id
    AND xcedt.attribute20   = 'Y'
    AND xaebtds.file_id     = p_file_id
    AND xcedt.cust_doc_id   = p_cust_doc_id
      --AND xaebtds.customer_trx_id = p_customer_trx_id
    ORDER BY record_type;
  CURSOR get_dist_rows (p_record_type IN VARCHAR2)
  IS
    SELECT DISTINCT xcedt.rownumber
    FROM xx_cdh_ebl_templ_dtl_txt xcedt
    WHERE xcedt.attribute20 = 'Y'
    AND xcedt.cust_doc_id   = p_cust_doc_id
    AND xcedt.record_type   = p_record_type
    ORDER BY xcedt.rownumber;
  ln_get_line_dist_rows NUMBER;
  -- existing
  lc_txt_line               VARCHAR2 (32767);
  ln_hdr_repeat_cnt         NUMBER := 0;
  ln_dtl_repeat_cnt         NUMBER := 0;
  ln_dist_repeat_cnt        NUMBER := 0;
  ln_max_rownum             NUMBER := 0;
  ln_hdr_cnt                NUMBER;
  ln_customer_trx_id        NUMBER;
  ln_customer_trx_line_id   NUMBER;
  lc_build_dtl_sql          VARCHAR2 (32767) := NULL;
  lc_build_dtl_label        VARCHAR2 (32767) := NULL;
  ln_count                  NUMBER;
  lc_dtl_hdr_sql            VARCHAR2 (32767);
  lc_dtl_lines_sql          VARCHAR2 (32767);
  lc_dtl_dist_lines_sql     VARCHAR2 (32767);
  lc_err_location_msg       VARCHAR2 (32767);
  lb_debug_flag             BOOLEAN;
  lc_hdr_exists             VARCHAR2 (1);
  lc_line_exists            VARCHAR2 (1);
  lc_dist_exists            VARCHAR2 (1);
  lc_print_dtl_label        VARCHAR2 (1);
  lc_repeat_dtl_header      VARCHAR2 (1);
  lc_dtl_col_label          VARCHAR2 (200);
  lc_build_dtl_hdr_label    VARCHAR2 (32767);
  lc_build_dtl_line_label   VARCHAR2 (32767);
  lc_build_dtl_dist_label   VARCHAR2 (32767);
  lc_custtrx_hdr_sort_cols  VARCHAR2 (2000);
  lc_custtrx_line_sort_cols VARCHAR2 (2000);
  lc_custtrx_sort_columns   VARCHAR2 (2000);
  lc_dtl_hdr_sort_columns   VARCHAR2 (2000);
  lc_dtl_line_sort_columns  VARCHAR2 (2000);
  lc_dtl_dist_sort_columns  VARCHAR2 (2000);
  ln_get_customer_trx_id    NUMBER := 0;
  lc_summary_bill_doc       VARCHAR2 (1);
  lc_sort_columns           VARCHAR2 (5000)  := NULL;
  lc_summary_build_sql      VARCHAR2 (32767) := NULL;
  lc_summary_build_label    VARCHAR2 (32767) := NULL;
  --
  lc_trx_type          VARCHAR2 (30);
  ln_label_count       NUMBER := 0;
  ln_label_data_count  NUMBER := 0;
  ln_label_total_count NUMBER :=0;
BEGIN
  IF (p_debug_flag = 'Y') THEN
    lb_debug_flag := TRUE;
  ELSE
    lb_debug_flag := FALSE;
  END IF;
  lc_err_location_msg := 'In Detail Count Data... ';
  XX_AR_EBL_COMMON_UTIL_PKG. PUT_LOG_LINE (lb_debug_flag, FALSE, lc_err_location_msg);
  IF p_lbl_flag = 'Y' THEN
    BEGIN
      SELECT DISTINCT NVL (include_header, 'N'),
        NVL (repeat_header, 'N')
      INTO lc_print_dtl_label,
        lc_repeat_dtl_header
      FROM xx_cdh_ebl_templ_dtl_txt
      WHERE cust_doc_id = p_cust_doc_id;
    EXCEPTION
    WHEN OTHERS THEN
      lc_print_dtl_label   := 'N';
      lc_repeat_dtl_header := 'N';
    END;
    ln_count            := 1;
    ln_hdr_cnt          := 0;
    ln_label_count      := 0;
    ln_label_data_count := 0;
    OPEN c_get_dist_record_type ;
    LOOP
      FETCH c_get_dist_record_type INTO lc_trx_type;
      EXIT
    WHEN c_get_dist_record_type%NOTFOUND;
      OPEN get_dist_rows(lc_trx_type);
      LOOP
        FETCH get_dist_rows INTO ln_get_line_dist_rows;
        EXIT
      WHEN get_dist_rows%NOTFOUND;
        IF lc_trx_type          = 'HDR' THEN
          IF lc_print_dtl_label ='Y' AND ln_hdr_repeat_cnt = 0 THEN
            ln_label_count     := ln_label_count + 1 ;
            ln_max_rownum      := 0;
            SELECT NVL(MAX(ROWNUMBER),1)
            INTO ln_max_rownum
            FROM xx_cdh_ebl_templ_dtl_txt
            WHERE cust_doc_id    = p_cust_doc_id
            AND attribute20      = 'Y'
            AND record_type      = lc_trx_type;
            IF ln_max_rownum     = ln_get_line_dist_rows THEN
              ln_hdr_repeat_cnt := 1;
            END IF;
          END IF;
        elsif lc_trx_type       ='LINE' THEN
          IF lc_print_dtl_label ='Y' AND ln_dtl_repeat_cnt = 0 THEN
            ln_label_count     := ln_label_count + 1 ;
            ln_max_rownum      := 0;
            SELECT NVL(MAX(ROWNUMBER),1)
            INTO ln_max_rownum
            FROM xx_cdh_ebl_templ_dtl_txt
            WHERE cust_doc_id    = p_cust_doc_id
            AND attribute20      = 'Y'
            AND record_type      = lc_trx_type;
            IF ln_max_rownum     = ln_get_line_dist_rows THEN
              ln_dtl_repeat_cnt := 1;
            END IF;
          END IF;
        elsif lc_trx_type       ='DIST' THEN
          IF lc_print_dtl_label ='Y' AND ln_dist_repeat_cnt = 0 THEN
            ln_label_count     := ln_label_count + 1 ;
            ln_max_rownum      := 0;
            SELECT NVL(MAX(ROWNUMBER),1)
            INTO ln_max_rownum
            FROM xx_cdh_ebl_templ_dtl_txt
            WHERE cust_doc_id     = p_cust_doc_id
            AND attribute20       = 'Y'
            AND record_type       = lc_trx_type;
            IF ln_max_rownum      = ln_get_line_dist_rows THEN
              ln_dist_repeat_cnt := 1;
            END IF;
          END IF;
        END IF;
      END LOOP;
      CLOSE get_dist_rows;
    END LOOP;
    CLOSE c_get_dist_record_type;
  END IF;
  -- get distint line in the details tables
  SELECT COUNT(1)
  INTO ln_label_data_count
  FROM xx_ar_ebl_txt_dtl_stg
  WHERE file_id         = p_file_id
  AND rec_type         != 'FID';
  ln_label_total_count := ln_label_data_count + ln_label_count;
  fnd_file.put_line (fnd_file.LOG,'Wave 4 DTL Funciton lablel Return  ' || ln_label_count ) ;
  fnd_file.put_line (fnd_file.LOG,'Wave 4 DTL Function data Return  ' || ln_label_data_count ) ;
  fnd_file.put_line (fnd_file.LOG,'Wave 4 DTL Function total Return  ' || ln_label_total_count ) ;
  RETURN ln_label_total_count ;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG,'Wave 4 DTL Function Exception ' || SQLERRM ) ;
  RETURN 0;
END RENDER_TXT_DTL_CNT;
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify                                    |
-- +=====================================================================================+
-- | Name        : RENDER_TXT_INV_CNT                                                    |
-- | Description : This Function is used for to get counts in INV                        |
-- |Parameters   : p_cust_doc_id                                                         |
-- |             , p_file_id                                                             |
-- |             , p_org_id                                                              |
-- |             , p_output_file                                                         |
-- |             , p_debug_flag                                                          |
-- |             , p_error_flag                                                          |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date          Author                 Remarks                               |
-- |=======   ==========   =============           ======================================|
-- | 1.1      18-May-2018  Aniket J    CG          Changes for Requirement  #NAIT-36070  |
-- +=====================================================================================+
FUNCTION RENDER_TXT_INV_CNT(
    p_cust_doc_id        IN NUMBER,
    p_file_id            IN NUMBER,
    p_rownum             IN NUMBER,
    p_org_id             IN NUMBER,
    p_file_creation_type IN VARCHAR2,
    p_delimiter_char     IN VARCHAR2,
    p_debug_flag         IN VARCHAR2,
    p_input_type         IN VARCHAR2 )
  RETURN NUMBER
IS
  ln_total_inv_rec_cnt  NUMBER := 0;
  ln_total_sku_rec_cnt  NUMBER := 0;
  ln_total_dtl_rec_cnt  NUMBER := 0;
  ln_total_rec_cnt      NUMBER := 0;
  ln_total_rec_cnt_rnum NUMBER := 0;
BEGIN
  IF p_input_type = 'INV' THEN
    SELECT COUNT( DISTINCT customer_trx_id)
    INTO ln_total_inv_rec_cnt
    FROM xx_ar_ebl_txt_dtl_stg
    WHERE rec_type         != 'FID'
    AND cust_doc_id         = p_cust_doc_id
    AND trx_type            = 'HDR'
    AND file_id             = p_file_id ;
    IF ln_total_inv_rec_cnt = 0 THEN
      SELECT COUNT( DISTINCT customer_trx_id)
      INTO ln_total_inv_rec_cnt
      FROM xx_ar_ebl_txt_dtl_stg
      WHERE rec_type != 'FID'
      AND cust_doc_id = p_cust_doc_id
      AND file_id     = p_file_id ;
    END IF;
    ln_total_rec_cnt :=ln_total_inv_rec_cnt ;
  ELSIF p_input_type  = 'SKU' THEN
    SELECT COUNT(1)
    INTO ln_total_sku_rec_cnt
    FROM xx_ar_ebl_txt_dtl_stg
    WHERE rec_type    = 'DT'
    AND cust_doc_id   = p_cust_doc_id
    AND file_id       = p_file_id ;
    ln_total_rec_cnt := ln_total_sku_rec_cnt;
  ELSIF p_input_type  = 'DTL' THEN
    SELECT COUNT(1)
    INTO ln_total_dtl_rec_cnt
    FROM xx_ar_ebl_txt_dtl_stg
    WHERE rec_type   != 'FID'
    AND cust_doc_id   = p_cust_doc_id
    AND file_id       = p_file_id ;
    ln_total_rec_cnt := ln_total_dtl_rec_cnt ;
  END IF;
  fnd_file.put_line (fnd_file.LOG,'Wave 4 Func Return  ' || ln_total_rec_cnt ) ;
  RETURN ln_total_rec_cnt;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG, ' Error IN DTL Function ' || SQLERRM );
  RETURN 0;
END RENDER_TXT_INV_CNT;
END XX_AR_EBL_RENDER_TXT_PKG;
/