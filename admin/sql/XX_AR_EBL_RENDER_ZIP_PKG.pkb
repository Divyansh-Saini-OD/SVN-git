create or replace
PACKAGE BODY XX_AR_EBL_RENDER_ZIP_PKG AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- +====================================================================================================+
-- | Name        : XX_AR_EBL_RENDER_ZIP_PKG                                                             |
-- | Description : Package body for eBilling zip rendering concurrent program                           |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       15-Apr-2010 Bushrod Thomas     Initial draft version.      			 	                        |
-- |                                                                                                    |
-- +====================================================================================================+
*/

-- ===========================================================================
-- procedure for printing to the output
-- ===========================================================================
PROCEDURE put_out_line
( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
IS
BEGIN
  -- if in concurrent program, print to output file
  IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
    FND_FILE.put_line(FND_FILE.OUTPUT,NVL(p_buffer,' '));
  -- else print to DBMS_OUTPUT
  ELSE
    DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
  END IF;
END put_out_line;


-- ===========================================================================
-- procedure for printing to the log
-- ===========================================================================
PROCEDURE put_log_line
( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
IS
BEGIN
  -- if in concurrent program, print to log file
  IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
    FND_FILE.put_line(FND_FILE.LOG,NVL(p_buffer,' '));
  -- else print to DBMS_OUTPUT
  ELSE
    DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
  END IF;
END put_log_line;

-- ===========================================================================
-- procedure for logging errors
-- ===========================================================================
PROCEDURE PUT_ERR_LINE (
  p_error_message IN VARCHAR2 := ' '
 ,p_attribute1   IN VARCHAR2 := null
 ,p_attribute2   IN VARCHAR2 := null
 ,p_attribute3   IN VARCHAR2 := null
) IS
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error(p_module_name   => 'AR'
                                ,p_program_name  => 'XX_AR_EBL_RENDER_ZIP_PKG'
                                ,p_attribute1    => p_attribute1
                                ,p_attribute2    => p_attribute2
                                ,p_attribute3    => p_attribute3
                                ,p_attribute4    => fnd_global.user_name
                                ,p_error_message => p_error_message
                                ,p_created_by    => fnd_global.user_id);
END PUT_ERR_LINE;


PROCEDURE get_translation(
  p_translation_name IN VARCHAR2
 ,p_source_value1    IN VARCHAR2
 ,p_source_value2    IN VARCHAR2
 ,x_target_value1    IN OUT NOCOPY VARCHAR2
)
IS
  ls_target_value1  VARCHAR2(240);
  ls_target_value2  VARCHAR2(240);
  ls_target_value3  VARCHAR2(240);
  ls_target_value4  VARCHAR2(240);
  ls_target_value5  VARCHAR2(240);
  ls_target_value6  VARCHAR2(240);
  ls_target_value7  VARCHAR2(240);
  ls_target_value8  VARCHAR2(240);
  ls_target_value9  VARCHAR2(240);
  ls_target_value10 VARCHAR2(240);
  ls_target_value11 VARCHAR2(240);
  ls_target_value12 VARCHAR2(240);
  ls_target_value13 VARCHAR2(240);
  ls_target_value14 VARCHAR2(240);
  ls_target_value15 VARCHAR2(240);
  ls_target_value16 VARCHAR2(240);
  ls_target_value17 VARCHAR2(240);
  ls_target_value18 VARCHAR2(240);
  ls_target_value19 VARCHAR2(240);
  ls_target_value20 VARCHAR2(240);
  ls_error_message  VARCHAR2(240);
BEGIN
  xx_fin_translate_pkg.xx_fin_translatevalue_proc(
    p_translation_name => p_translation_name
   ,p_source_value1    => p_source_value1
   ,p_source_value2    => p_source_value2
   ,x_target_value1    => x_target_value1
   ,x_target_value2    => ls_target_value2
   ,x_target_value3    => ls_target_value3
   ,x_target_value4    => ls_target_value4
   ,x_target_value5    => ls_target_value5
   ,x_target_value6    => ls_target_value6
   ,x_target_value7    => ls_target_value7
   ,x_target_value8    => ls_target_value8
   ,x_target_value9    => ls_target_value9
   ,x_target_value10   => ls_target_value10
   ,x_target_value11   => ls_target_value11
   ,x_target_value12   => ls_target_value12
   ,x_target_value13   => ls_target_value13
   ,x_target_value14   => ls_target_value14
   ,x_target_value15   => ls_target_value15
   ,x_target_value16   => ls_target_value16
   ,x_target_value17   => ls_target_value17
   ,x_target_value18   => ls_target_value18
   ,x_target_value19   => ls_target_value19
   ,x_target_value20   => ls_target_value20
   ,x_error_message    => ls_error_message
  );
END;



PROCEDURE CHECK_CHILD_REQUEST (
   p_request_id  IN OUT  NOCOPY  NUMBER
) IS
  call_status     boolean;
  rphase          varchar2(80);
  rstatus         varchar2(80);
  dphase          varchar2(30);
  dstatus         varchar2(30);
  message         varchar2(240);
BEGIN
  call_status := FND_CONCURRENT.get_request_status(
                        p_request_id,
                        '',
                        '',
                        rphase,
                        rstatus,
                        dphase,
                        dstatus,
                        message);
  IF ((dphase = 'COMPLETE') and (dstatus = 'NORMAL')) THEN
      put_log_line( 'child request id: ' || p_request_id || ' completed successfully');
  ELSE
      put_log_line( 'child request id: ' || p_request_id || ' did not complete successfully');
  END IF;
END CHECK_CHILD_REQUEST;


PROCEDURE RENDER_ZIP_P (
    Errbuf            OUT NOCOPY VARCHAR2
   ,Retcode           OUT NOCOPY VARCHAR2
)
IS
  ln_thread_count     NUMBER;
  n_conc_request_id   NUMBER := NULL;
  ls_req_data         VARCHAR2(240);
  ln_request_id       NUMBER;        -- parent request id
  cnt_warnings        INTEGER := 0;
  cnt_errors          INTEGER := 0;
  request_status      BOOLEAN;  
BEGIN
  ls_req_data := fnd_conc_global.request_data;
  ln_request_id := fnd_global.conc_request_id;

  IF ls_req_data IS NOT NULL THEN
    put_log_line( ' Back at beginning after spawing ' || ls_req_data || ' threads.');
    ln_thread_count := ls_req_data;

    IF ln_thread_count > 0 THEN
      put_log_line ( 'Checking child threads...');
                      
      -- Check all child requests to see how they finished...
      FOR child_request_rec IN (SELECT request_id, status_code
                                  FROM fnd_concurrent_requests
                                 WHERE parent_request_id = ln_request_id) LOOP
         check_child_request(child_request_rec.request_id);
        IF ( child_request_rec.status_code = 'G' OR child_request_rec.status_code = 'X'
          OR child_request_rec.status_code ='D' OR child_request_rec.status_code ='T'  ) THEN
            cnt_warnings := cnt_warnings + 1;
        ELSIF ( child_request_rec.status_code = 'E' ) THEN
            cnt_errors := cnt_errors + 1;
        END IF;
      END LOOP; -- FOR child_request_rec

      IF cnt_errors > 0 THEN
        put_log_line( 'Setting completion status to ERROR.');
        request_status := fnd_concurrent.set_completion_status('ERROR', '');
      ELSIF cnt_warnings > 0 THEN
        put_log_line( 'Setting completion status to WARNING.');      
        request_status := fnd_concurrent.set_completion_status('WARNING', '');  
      ELSE
        put_log_line( 'Setting completion status to NORMAL.');
        request_status := fnd_concurrent.set_completion_status('NORMAL', '');
      END IF;
    END IF;

    RETURN; -- end of parent
  END IF;

  get_translation('AR_EBL_CONFIG','RENDER_ZIP','N_THREADS',ln_thread_count);
  IF ln_thread_count IS NULL THEN
    ln_thread_count := 1;
  END IF;

  put_log_line('spawning ' || ln_thread_count || ' thread(s)');

  FOR i IN 1..ln_thread_count LOOP
    put_log_line('thread: ' || i);

    n_conc_request_id :=
      FND_REQUEST.submit_request
      ( application    => 'XXFIN'                      -- application short name
       ,program        => 'XX_AR_EBL_RENDER_ZIP_C'     -- concurrent program name
       ,sub_request    => TRUE                         -- is this a sub-request?
       ,argument1      => i                            -- thread_id
       ,argument2      => ln_thread_count);

    -- ===========================================================================
    -- if request was successful
    -- ===========================================================================
    IF (n_conc_request_id > 0) THEN
      -- ===========================================================================
      -- if a child request, then update it for concurrent mgr to process
      -- ===========================================================================
/*    -- Instead of doing the following Update, use FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED', request_data => to_char(ln_thread_count)) -- See below
      -- This program will then restart when the child programs are done, so if fnd_conc_global.request_data is NOT NULL at start of proc, check child statuses and end.
      -- If either this Update, or the set_req_globals approach, is not done, the child programs will hang in Invalid, No Manager status.

        UPDATE fnd_concurrent_requests
           SET phase_code = 'P',
               status_code = 'I'
         WHERE request_id = n_conc_request_id;
*/
      -- ===========================================================================
      -- must commit work so that the concurrent manager polls the request
      -- ===========================================================================
      COMMIT;

      put_log_line( ' Concurrent Request ID: ' || n_conc_request_id || '.' );

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
  
  FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED', request_data => to_char(ln_thread_count));
  
END RENDER_ZIP_P;



  PROCEDURE TRANSMISSIONS_TO_ZIP (
    P_TREAD_ID    IN NUMBER
   ,P_TREAD_COUNT IN NUMBER
   ,X_CURSOR      OUT SYS_REFCURSOR
  ) IS
  BEGIN
    OPEN X_CURSOR FOR

    SELECT /*+ index(M XX_CDH_EBL_MAIN__UIDX01) index(T XX_AR_EBL_TRANSMISSION_N2) */ T.transmission_id
      FROM XX_AR_EBL_TRANSMISSION T
      JOIN XX_CDH_EBL_MAIN M
        ON T.customer_doc_id=M.cust_doc_id
     WHERE T.status='SEND'
       AND MOD(T.transmission_id,P_TREAD_COUNT)=P_TREAD_ID
       AND T.org_id=FND_GLOBAL.org_id
       AND M.zip_required='Y'
       AND NOT EXISTS (SELECT * FROM XX_AR_EBL_FILE F WHERE F.transmission_id=T.transmission_id AND F.file_type<>'ZIP' AND NVL(F.status,'X')<>'RENDERED')
       AND EXISTS (SELECT * FROM XX_AR_EBL_FILE F WHERE F.transmission_id=T.transmission_id AND F.file_type<>'ZIP')
       AND EXISTS (SELECT * FROM XX_AR_EBL_FILE F WHERE F.transmission_id=T.transmission_id AND F.file_type='ZIP' AND NVL(F.status,'X')<>'RENDERED')
     ORDER BY transmission_id;
  END TRANSMISSIONS_TO_ZIP;


  PROCEDURE FILES_TO_ZIP (
    P_TRANSMISSION_ID IN NUMBER
   ,X_CURSOR          OUT SYS_REFCURSOR
  ) IS
  BEGIN
    OPEN X_CURSOR FOR
  
    SELECT F.file_id, NVL2(D.dup_file_name,rownum || '/' || F.file_name,F.file_name) file_name, F.file_data
      FROM XX_AR_EBL_FILE F
      LEFT OUTER JOIN
          (SELECT lower(file_name) dup_file_name
             FROM XX_AR_EBL_FILE
            WHERE transmission_id=P_TRANSMISSION_ID
              AND file_type<>'ZIP'
            GROUP BY lower(file_name)
            HAVING COUNT(1)>1) D
        ON D.dup_file_name=lower(F.file_name)
     WHERE F.transmission_id=P_TRANSMISSION_ID
       AND F.file_type<>'ZIP';
  END FILES_TO_ZIP;


  PROCEDURE SHOW_FILES_TO_ZIP (
    P_TREAD_ID    IN NUMBER
   ,P_TREAD_COUNT IN NUMBER    
  ) IS
    lc_transmissions   SYS_REFCURSOR;
    lc_files           SYS_REFCURSOR;
    ln_transmission_id NUMBER;
    ln_file_id         XX_AR_EBL_FILE.file_id%TYPE;
    ls_file_name       XX_AR_EBL_FILE.file_name%TYPE;
    lb_file_data       XX_AR_EBL_FILE.file_data%TYPE;
  BEGIN
    XX_AR_EBL_RENDER_ZIP_PKG.TRANSMISSIONS_TO_ZIP(P_TREAD_ID,P_TREAD_COUNT,lc_transmissions);
    LOOP
      FETCH lc_transmissions INTO ln_transmission_id;
      EXIT WHEN lc_transmissions%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('transmission ' || ln_transmission_id);

      XX_AR_EBL_RENDER_ZIP_PKG.FILES_TO_ZIP(ln_transmission_id,lc_files);
      LOOP
        FETCH lc_files INTO ln_file_id,ls_file_name,lb_file_data;
        EXIT WHEN lc_files%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('  --> ' || ls_file_name);
      END LOOP;
      CLOSE lc_files;
    END LOOP;
    CLOSE lc_transmissions;
  END SHOW_FILES_TO_ZIP;

END XX_AR_EBL_RENDER_ZIP_PKG;

/
