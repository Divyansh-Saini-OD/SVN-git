SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AR_STD_LBX_SUB_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_AR_STD_LBX_SUB_PKG AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Oracle Cloud Services                                |
-- +=================================================================================+
-- | Name       : XX_AR_STD_LBX_SUB_PKG.pkb                                          |
-- | Description: OD: AR Standard Lockbox Submission Program                         |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version     Date         Authors            Remarks                              |
-- |========    ===========  ===============    ============================         |
-- |DRAFT 1A    07-APR-2010  Sundaram S         Initial draft version                |
-- |Version1.1  07-APR-2010  Sambasiva Reddy D  Modified for Defect # 4188           |
-- |Version1.2  08-Nov-2010  Sundaram S         Added new parameter for Defect 8808  |
-- |1.3         10-Nov-2011  Pradeep Mariappan  Modified for parallel execution of   |
-- |                                            validation part of ARLPLB to improve |
-- |                                            performance # defect 14764           |
-- |1.4         16-Nov-2011  Pradeep Mariappan  Fixed a bug for inserting same       |
-- |                                            records into ar_transmissions        |
-- |1.5         27-Aug-2013  Deepak V           E0062 - Modified for R12 upgrade retrofit.   |
-- |                                            For insert into AR_TRANSMISSIONS_ALL |
-- |                                            two additional columns have been added|    
-- |1.6         27-Oct-2015  Vasu Raparla       Removed Schema References for R12.2  |
-- |1.7         26-Oct-2017  Uday Jadhav        VPS:Added fnd_concurrent_requests table in  |
-- |											cursor c_wrap_temp_rec to pick the   |
-- |											transactions based on resp_id	     |
-- +=================================================================================+
-- | Name        : XX_AR_PROC_LBX_MAIN                                               |
-- | Description : This procedure will be used to insert into AR_TRANSMISSIONS_ALL   |
-- |               ,AR_PAYMENTS_INTERFACE_ALL and Submit Wrapper Parallel Program    |
-- |                                                                                 |
-- | Parameters  : x_errbuf                                                          |
-- |              ,x_retcode                                                         |
-- |              ,p_days_start_purge                                                |
-- |              ,p_cycle_date   --Added for defect 8808                            |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- +=================================================================================+

  PROCEDURE xx_proc_lbx_main ( x_errbuf                  OUT     NOCOPY     VARCHAR2
                              ,x_retcode                 OUT     NOCOPY     NUMBER
                              ,p_days_start_purge        IN                 NUMBER
                              ,p_cycle_date              IN                 VARCHAR2-- Added for Defect#8808
                              )
  IS
-------------------------
-- Variable Declaration
-------------------------
    ln_count_main        NUMBER :=0;
    lc_check_main        VARCHAR2(1);
    ln_tran_req_id       NUMBER;
    ln_transmission_id   NUMBER;
    ln_prl_req_id        NUMBER;
    lc_error_details     VARCHAR2(32000);
    lc_error_location    VARCHAR2(4000);
    ln_unprocd_cnt       NUMBER := 0;
    lc_chk_flag          VARCHAR2(4000);
    lc_request_data      VARCHAR2(4000);
    ln_this_request_id   NUMBER;
    ln_file_count        NUMBER;
    ln_loop_count        NUMBER;
    ln_exceptn_cnt       NUMBER;
    lc_trans_name        VARCHAR2(30);

  BEGIN
    lc_chk_flag        := FND_CONC_GLOBAL.request_data;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'value of lc_chk_flag: '||lc_chk_flag) ;
    ln_this_request_id := FND_GLOBAL.CONC_REQUEST_ID;
    FND_FILE.put_line(FND_FILE.LOG,'[WIP] Request_data - '||NVL(lc_chk_flag,'FIRST'));

    <<main_loop>>
    lc_check_main     := 'N';
    ln_exceptn_cnt    := 0;
    ln_count_main     := 0;
    ln_unprocd_cnt    := 0;
    ln_loop_count     := 0;
    lc_trans_name     := NULL;
---+===========================================
-- Check whether Custom main Program is running
---+===========================================
    lc_error_location := 'LBXWRP-1001';
    lc_error_details  := 'Checking the Status of OD: AR Lockbox Process - Mains program';
    ln_count_main := xx_custom_main_program_check ;
    IF ln_count_main > 0 THEN
      lc_check_main := 'Y';
    END IF;
---+=================================================
-- Check the no. of unprocessed records in Temp table
---+=================================================
    lc_error_location := 'LBXWRP-1002';
    lc_error_details  := 'Derive the unprocessed record count';
    ln_unprocd_cnt := xx_custom_wrapper_check ;
---+=========================================
-- Step#1 -- Submit Wrapper Parallel Program
---+=========================================
    IF(ln_unprocd_cnt > 0 AND NVL(lc_chk_flag,'FIRST') <> 'COMPLETE')THEN
      xx_submit_program(ln_loop_count, ln_exceptn_cnt,p_cycle_date, x_errbuf, x_retcode) ;
      IF(ln_loop_count <> ln_exceptn_cnt) THEN
        lc_request_data := 'SECOND';
        ln_count_main := xx_custom_main_program_check ;
        IF ln_count_main > 0 THEN
          lc_check_main := 'Y';
        END IF;
       -- FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=> lc_request_data);
        FND_FILE.put_line(FND_FILE.LOG,'[WIP] Checking the status of Main Program');
       -- COMMIT;
       -- RETURN;
      ELSE
        GOTO main_loop;
      END IF;
---+================================================================
--Check whether Main program is running and if yes GO TO Main loop
---+================================================================
    ELSIF (lc_check_main = 'Y' AND ln_unprocd_cnt = 0 AND NVL(lc_chk_flag,'FIRST') <> 'COMPLETE') THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Waiting for OD: AR Lockbox Process - Mains program to Complete');
      DBMS_LOCK.SLEEP(120);
      GOTO main_loop;
    ELSIF(lc_check_main = 'N' AND ln_unprocd_cnt = 0 AND NVL(lc_chk_flag,'FIRST') <>' COMPLETE') THEN
      lc_chk_flag := 'COMPLETE';
      FND_FILE.put_line(FND_FILE.LOG,'No record to process -- Go to ' || lc_chk_flag || ' phase');
    END IF;

    IF (lc_check_main = 'Y') THEN 
      DBMS_LOCK.SLEEP(120);
      GOTO main_loop;
    END IF ;
---+================================================================================================
---|  Complete Phase
---+================================================================================================
    IF(lc_chk_flag = 'COMPLETE' AND lc_check_main = 'N' AND ln_unprocd_cnt = 0) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Step#3 -- Archive and Purge');
      ln_file_count := 0;
      lc_error_location := 'LBXWRP-1006';
      lc_error_details  := 'Check OD: AR Standard Lockbox Submission Program - Child Program Status';
      xx_wrapper_pgm_status (ln_this_request_id, x_errbuf, x_retcode) ;
      xx_program_output (ln_this_request_id, ln_file_count) ;
      lc_error_location := 'LBXWRP-1006';
      lc_error_details  := 'Archive and purge';
      xx_purge_data (p_days_start_purge) ;
    END IF;
  EXCEPTION 
    WHEN OTHERS THEN
      ROLLBACK;
      fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
      fnd_message.set_token('PACKAGE','XX_PROCESS_LBX_WRAP_PKG.XX_PROC_LBX_MAIN');
      fnd_message.set_token('PROGRAM','Wrapper program');
      fnd_message.set_token('SQLERROR',SQLERRM);
      x_errbuf     := lc_error_location||'-'||lc_error_details||'-'||fnd_message.get;
      x_retcode  := 2;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR
          (
             p_program_type            => 'CONCURRENT PROGRAM'
            ,p_program_name            => 'XX_LOCKBOX_WRAPPER_PROGRAM'
            ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
            ,p_module_name             => 'AR'
            ,p_error_location          => 'Error at ' || lc_error_location
            ,p_error_message_count     => 1
            ,p_error_message_code      => 'E'
            ,p_error_message           => lc_error_details
            ,p_error_message_severity  => 'Major'
            ,p_notify_flag             => 'N'
            ,p_object_type             => 'LOCKBOX AUTOCASH'
          );
  END XX_PROC_LBX_MAIN;

FUNCTION xx_custom_main_program_check return NUMBER IS 
  l_count_main NUMBER := 0 ;
BEGIN
  SELECT  COUNT(1) INTO  l_count_main
    FROM  fnd_concurrent_requests FCR, fnd_concurrent_programs FCP
    WHERE  FCR.concurrent_program_id   = FCP.concurrent_program_id
      AND  FCP.concurrent_program_name = 'XX_AR_LOCKBOX_PROCESS_MAIN'
      AND  FCR.phase_code IN ('P','R');
  IF l_count_main > 0 THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'No. of OD: AR Lockbox Custom Main Program is running currently -- ' || l_count_main);
  END IF;
  RETURN l_count_main ;
END xx_custom_main_program_check ;

FUNCTION xx_custom_wrapper_check return NUMBER IS 
  l_count_main NUMBER := 0 ;
BEGIN
  SELECT  COUNT(1) INTO  l_count_main
    FROM  xx_ar_lbx_wrapper_temp XAWT ,fnd_concurrent_requests fcr
      WHERE XAWT.processed = 'N' 
      AND lbx_custom_main_req_id=fcr.request_id
      AND fcr.responsibility_id=FND_GLOBAL.RESP_ID ;
	/*
	FROM  xx_ar_lbx_wrapper_temp XAWT
    WHERE  XAWT.processed = 'N';
	*/
  FND_FILE.PUT_LINE(FND_FILE.LOG,'No. of unprocessed records in xx_ar_lbx_wrapper_temp table -- ' ||l_count_main);
  RETURN l_count_main ;
END xx_custom_wrapper_check ;

PROCEDURE xx_submit_program (p_loop_count IN OUT NUMBER, p_exceptn_cnt IN OUT NUMBER, p_cycle_date IN VARCHAR2 
                            ,p_errbuf  OUT VARCHAR2 ,p_retcode OUT NUMBER) IS 
  CURSOR c_wrap_temp_rec IS
    SELECT   XAWT.transmission_record_count
            ,XAWT.transmission_amount
            ,XAWT.transmission_format_id
            ,XAWT.entire_file_name
            ,XAWT.exact_file_name
            ,XAWT.process_num
            ,XAWT.gl_date
            ,XAWT.processed
            ,XAWT.email_notify_flag
            ,XAWT.lbx_custom_main_req_id
            ,XAWT.deposit_date
            ,XAWT.transmission_id
      FROM  xx_ar_lbx_wrapper_temp XAWT ,fnd_concurrent_requests fcr
      WHERE XAWT.processed = 'N' 
      AND lbx_custom_main_req_id=fcr.request_id
      AND fcr.responsibility_id=FND_GLOBAL.RESP_ID 
      ORDER BY  transmission_record_count
      ; 
	  /*
	  FROM  xx_ar_lbx_wrapper_temp XAWT
      WHERE XAWT.processed = 'N' 
      ORDER BY  transmission_record_count;
	  */
	  
  l_error_details     VARCHAR2(32000);
  l_error_location    VARCHAR2(4000);
  l_tran_req_id       NUMBER;
  l_transmission_id   NUMBER;
  l_prl_req_id        NUMBER;
  l_trans_name        VARCHAR2(30);

BEGIN
          FOR ln_proc_lbx IN c_wrap_temp_rec
          LOOP
            BEGIN
               l_trans_name   := SUBSTR(ln_proc_lbx.exact_file_name,1,30);                   -- Transmission Name
---+==================================================
---|Create a record in the table ar_transmissions_all
---+==================================================
              p_loop_count := p_loop_count + 1;
              FND_FILE.put_line(FND_FILE.LOG,'[WIP] Insert Transmission  - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
              FND_FILE.put_line(FND_FILE.LOG,' Transmission name - ' || l_trans_name );

              l_error_location := 'LBXWRP-1003';
              l_error_details  := 'Inserting into ar_transmissions_all';

              SELECT   fnd_concurrent_requests_s.NEXTVAL
                      ,ar_transmissions_s.NEXTVAL
                INTO  l_tran_req_id
                     ,l_transmission_id
                FROM  DUAL;

              INSERT INTO ar_transmissions_all
              VALUES
              (l_tran_req_id                            -- TRANSMISSION_REQUEST_ID
              ,FND_GLOBAL.USER_ID                        -- CREATED_BY
              ,TRUNC(SYSDATE)                            -- CREATION_DATE
              ,FND_GLOBAL.USER_ID                        -- LAST_UPDATED_BY
              ,TRUNC(SYSDATE)                            -- LAST_UPDATE_DATE
              ,NULL                                      -- LAST_UPDATE_LOGIN
              ,TRUNC(SYSDATE)                            -- TRANS_DATE
              ,TO_CHAR(SYSDATE,'HH:MI')                  -- TIME
              ,ln_proc_lbx.transmission_record_count     -- COUNT
              ,ln_proc_lbx.transmission_amount           -- AMOUNT
              ,0                                         -- VALIDATED_COUNT
              ,0                                         -- VALIDATED_AMOUNT
              ,NULL                                      -- ORIGIN
              ,NULL                                      -- DESTINATION
              ,'NB'                                      -- STATUS
              ,NULL                                      -- COMMENTS
              ,NULL                                      -- REQUESTED_LOCKBOX_ID
              ,ln_proc_lbx.transmission_format_id        -- REQUESTED_TRANS_FORMAT_ID
              ,NULL                                      -- REQUESTED_GL_DATE
              ,NULL                                      -- ATTRIBUTE_CATEGORY
              ,TO_CHAR(p_cycle_date)                     -- ATTRIBUTE1 -- modified NULL and Added p_cycle_Date for defect 8808
              ,NULL                                      -- ATTRIBUTE2
              ,NULL                                      -- ATTRIBUTE3
              ,NULL                                      -- ATTRIBUTE4
              ,NULL                                      -- ATTRIBUTE5
              ,NULL                                      -- ATTRIBUTE6
              ,NULL                                      -- ATTRIBUTE7
              ,NULL                                      -- ATTRIBUTE8
              ,NULL                                      -- ATTRIBUTE9
              ,NULL                                      -- ATTRIBUTE10
              ,NULL                                      -- ATTRIBUTE11
              ,NULL                                      -- ATTRIBUTE12
              ,NULL                                      -- ATTRIBUTE13
              ,NULL                                      -- ATTRIBUTE14
              ,NULL                                      -- ATTRIBUTE15
              ,l_trans_name                             -- TRANSMISSION_NAME
              ,l_transmission_id                        -- TRANSMISSION_ID
              ,l_tran_req_id                            -- LATEST_REQUEST_ID
              ,FND_PROFILE.VALUE('ORG_ID')               -- ORG_ID
			  ,NULL                                      -- SOURCE_TYPE_FLAG  (Added For R12 retrofit)
			  ,NULL                                      -- SCORING_MODEL_ID  (Added For R12 retrofit)
              );

---+===============================================================================================
---|  Selected the records from the interim table and insert into the Interface table
---+===============================================================================================

              l_error_location := 'LBXWRP-1004';
              l_error_details :='Inserting into ar_payments_interface_all';

              FND_FILE.put_line(FND_FILE.LOG,'[WIP] Move Payment Interface records  - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

              INSERT INTO ar_payments_interface_all
              (transmission_record_id,
              transmission_request_id,
              record_type,
              gl_date,
              destination_account,
              origination,
              lockbox_number,
              deposit_date,
              batch_name,
              item_number,
              remittance_amount,
              transit_routing_number,
              account,
              check_number,
              customer_number,
              overflow_sequence,
              overflow_indicator,
              invoice1,
              invoice2,
              invoice3,
              amount_applied1,
              amount_applied2,
              amount_applied3,
              batch_record_count,
              batch_amount,
              lockbox_record_count,
              lockbox_amount,
              transmission_record_count,
              transmission_amount,
              transmission_id,
              attribute_category,
              attribute1,
              attribute2,
              attribute3,
              attribute4,
              attribute5,
              attribute15,
              status,
			  org_id,     -- Added for R12 upgrade
              creation_date,
              created_by,
              last_update_date,
              last_updated_by )
              ( SELECT
              ar_payments_interface_s.nextval,
              l_tran_req_id,
              record_type,
              ln_proc_lbx.gl_date,
              destination_account,
              origination,
              lockbox_number,
              ln_proc_lbx.deposit_date,
              batch_name,
              item_number,
              remittance_amount,
              transit_routing_number,
              account,
              check_number,
              customer_number,
              overflow_sequence,
              overflow_indicator,
              trim(invoice1),
              trim(invoice2),
              trim(invoice3),
              amount_applied1,
              amount_applied2,
              amount_applied3,
              batch_record_count,
              batch_amount,
              lockbox_record_count,
              lockbox_amount,
              transmission_record_count,
              transmission_amount,
              l_transmission_id,
              'SALES_ACCT',
              attribute1,
              attribute2,
              attribute3,
              attribute4,
              attribute5,
              inv_match_status,
              status,
			  FND_PROFILE.VALUE('ORG_ID'), -- Added for R12 upgrade
              ln_proc_lbx.deposit_date,
              fnd_global.user_id,
              ln_proc_lbx.deposit_date,
              fnd_global.user_id
              FROM xx_ar_payments_interface
              WHERE process_num = ln_proc_lbx.process_num
              );

---+===============================================================================================
---|  Submit the standard Lockbox process with the required parameters
---+===============================================================================================

              l_error_location := 'LBXWRP-1005';
              l_error_details := 'Submitting Custom Standard Lockbox Submission';

              FND_FILE.put_line(FND_FILE.LOG,'[WIP] Submit Custom Standard Lockbox Submission Program  - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

              l_prl_req_id := FND_REQUEST.SUBMIT_REQUEST (  'xxfin'
                                                            ,'XX_AR_STD_LBX_SUB_CHILD'
                                                            ,''
                                                            ,SYSDATE
                                                            ,FALSE -- changed by pradeep
                                                            -- ,TRUE -- old value
                                                            ,ln_proc_lbx.entire_file_name
                                                            ,ln_proc_lbx.lbx_custom_main_req_id
                                                            ,l_transmission_id
                                                            ,l_tran_req_id
                                                            ,ln_proc_lbx.transmission_format_id
                                                            ,ln_proc_lbx.gl_date
                                                            ,ln_proc_lbx.email_notify_flag
                                                          );
              COMMIT;
                 UPDATE xx_ar_lbx_wrapper_temp
                    SET  processed = 'C'
                    /* Pradeep M: updating it to C to indicate being picked up by LBX Submission Child */ 
                  WHERE lbx_custom_main_req_id = ln_proc_lbx.lbx_custom_main_req_id
                    AND exact_file_name        = ln_proc_lbx.exact_file_name;
              COMMIT;
              FND_FILE.put_line(FND_FILE.LOG,'[WIP] Request ID of OD: AR Standard Lockbox Submission Program  '||l_prl_req_id);
            EXCEPTION
              WHEN OTHERS THEN
                 FND_FILE.put_line(FND_FILE.LOG,l_error_location
                                                ||'--'
                                                ||l_error_details
                                                || 'Oracle Error Code'
                                                ||'--'
                                                ||SQLCODE
                                                ||'--'
                                                ||SQLERRM
                                   );
                 p_exceptn_cnt := p_exceptn_cnt + 1;
                 UPDATE xx_ar_lbx_wrapper_temp
                    SET  processed = 'E'
                  WHERE lbx_custom_main_req_id = ln_proc_lbx.lbx_custom_main_req_id
                    AND exact_file_name        = ln_proc_lbx.exact_file_name;
                 p_retcode := 2;
            END;
       END LOOP;

END xx_submit_program ;

PROCEDURE xx_purge_data (p_days_start_purge IN NUMBER) IS 
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'[WIP] Move to History table - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
  IF (p_days_start_purge IS NOT NULL) THEN
    INSERT INTO xx_ar_payments_intf_history 
      ( SELECT * FROM xx_ar_payments_interface A
          WHERE 1=1
          AND NOT EXISTS (SELECT DISTINCT process_num
          FROM xx_ar_payments_interface B
          WHERE B.creation_date >= TRUNC(SYSDATE) - p_days_start_purge AND B.process_num = A.process_num )
      );
    FND_FILE.PUT_LINE(FND_FILE.LOG,'  Inserted ' || SQL%ROWCOUNT || ' records into xx_ar_payments_intf_history');
    COMMIT;

    FND_FILE.PUT_LINE(FND_FILE.LOG,'[WIP] Purge Old Interface Data - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
    DELETE FROM xx_ar_payments_interface A
      WHERE 1=1 AND NOT EXISTS (SELECT DISTINCT process_num FROM xx_ar_payments_interface B
                                  WHERE B.creation_date >= TRUNC(SYSDATE) - p_days_start_purge
                                    AND B.process_num = A.process_num
                               );
    FND_FILE.PUT_LINE(FND_FILE.LOG,'  Deleted ' || SQL%ROWCOUNT || ' records.');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Purged Old Records (Days Old = ' || p_days_start_purge || ')');
    COMMIT;
  END IF;

  FND_FILE.put_line(FND_FILE.LOG,'[WIP] Move to History table - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
 INSERT INTO xx_ar_lbx_wrapper_temp_history 
    ( SELECT xawt.* FROM  xx_ar_lbx_wrapper_temp XAWT ,fnd_concurrent_requests fcr WHERE XAWT.processed = 'Y' AND lbx_custom_main_req_id=fcr.request_id AND fcr.responsibility_id=FND_GLOBAL.RESP_ID);
	/*( SELECT * FROM XX_AR_LBX_WRAPPER_TEMP WHERE processed = 'Y'); */
  FND_FILE.put_line(FND_FILE.LOG,'No. of records moved to history table - '||SQL%ROWCOUNT);
  COMMIT;
  FND_FILE.put_line(FND_FILE.OUTPUT,'');
  FND_FILE.put_line(FND_FILE.LOG,'[WIP] Purge Old Processed Data - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
  DELETE
      FROM xx_ar_lbx_wrapper_temp xawt  
      WHERE xawt.processed      = 'Y'
      AND EXISTS
      (
        SELECT 1 FROM fnd_concurrent_requests fcr
        WHERE
        fcr.request_id=xawt.lbx_custom_main_req_id
        AND fcr.responsibility_id =FND_GLOBAL.RESP_ID
      )
      ;  
  /*DELETE FROM xx_ar_lbx_wrapper_temp WHERE processed = 'Y'; */
  COMMIT;
END xx_purge_data ;

PROCEDURE xx_program_output (p_this_request_id IN NUMBER, p_file_count IN OUT NUMBER) IS 
BEGIN 
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Office Depot',50,' ')||LPAD('Date : '||TO_CHAR(SYSDATE, 'DD-MON-YYYY'),117,' '));
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Request ID: '||RPAD(p_this_request_id,45,' ')||LPAD('Page : '||1,100,' '));
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                      OD: AR Standard Lockbox Submission Program                                  ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('File Name',35)
                                  ||LPAD('Process Lockbox Req ID',25)
                                  ||LPAD('Process Lockbox Status',35)
                                  ||LPAD('No.of Records Processed',35)
                                  ||LPAD('Amount',20)
                   );
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

  FOR ln_cnt IN (SELECT XAWT.exact_file_name
                       ,XAWT.process_lbx_req_id
                       ,XAWT.process_lbx_status
                       ,XAWT.transmission_record_count
                       ,XAWT.transmission_amount
                   FROM  xx_ar_lbx_wrapper_temp XAWT ,fnd_concurrent_requests fcr 
				   WHERE XAWT.processed = 'Y' 
				   AND XAWT.lbx_custom_main_req_id=fcr.request_id 
				   AND fcr.responsibility_id=FND_GLOBAL.RESP_ID)
/*
  FOR ln_cnt IN (SELECT exact_file_name
                       ,process_lbx_req_id
                       ,process_lbx_status
                       ,transmission_record_count
                       ,transmission_amount
                   FROM xx_ar_lbx_wrapper_temp
                   WHERE processed = 'Y')*/				   


  LOOP
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(ln_cnt.exact_file_name,35)
                                    ||LPAD(ln_cnt.process_lbx_req_id       ,25)
                                    ||LPAD(ln_cnt.process_lbx_status       ,35)
                                    ||LPAD(ln_cnt.transmission_record_count,35)
                                    ||LPAD(ln_cnt.transmission_amount      ,20)
                     );
    p_file_count := p_file_count + 1;
  END LOOP;
  FND_FILE.put_line(FND_FILE.OUTPUT,' ');
  FND_FILE.put_line(FND_FILE.OUTPUT,'Total Number of Files Processed :  ' || p_file_count );
  FND_FILE.put_line(FND_FILE.OUTPUT,' ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('*** End of Report ***',90,' '));
END xx_program_output ;

PROCEDURE xx_wrapper_pgm_status (p_this_request_id IN NUMBER
                                ,p_errbuf  OUT VARCHAR2
                                ,p_retcode OUT NUMBER ) IS 
  l_err_cnt           NUMBER;
  l_wrn_cnt           NUMBER;
  l_nrm_cnt           NUMBER;
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Check OD: AR Standard Lockbox Submission Program - Child Status - ' 
                                 || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

  BEGIN
    SELECT SUM(CASE WHEN status_code = 'E' THEN 1 ELSE 0 END)
          ,SUM(CASE WHEN status_code = 'G' THEN 1 ELSE 0 END)
          ,SUM(CASE WHEN status_code = 'C' THEN 1 ELSE 0 END)
       INTO   l_err_cnt
             ,l_wrn_cnt
             ,l_nrm_cnt
       FROM   fnd_concurrent_requests
       WHERE  priority_request_id = p_this_request_id;

    IF (l_err_cnt > 0) OR (l_wrn_cnt > 0 AND l_err_cnt = 0) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'OD: AR Standard Lockbox Submission Program - Child ended in Error/Warning');
      p_errbuf    := 'OD: AR Standard Lockbox Submission Program - Child ended in Error/Warning';
      p_retcode   := 2;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error @ Custom Child Program Status Check');
      p_errbuf    := 'Error @ Custom Child Program Status Check';
  END;
END xx_wrapper_pgm_status ;
END XX_AR_STD_LBX_SUB_PKG;
/
SHOW ERR
