SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AR_STD_LBX_SUB_CHILD_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_AR_STD_LBX_SUB_CHILD_PKG AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Oracle Cloud Services                                |
-- +=================================================================================+
-- | Name       : XX_AR_STD_LBX_SUB_CHILD_PKG.pkb                                    |
-- | Description: OD: AR Standard Lockbox Submission Program - Child                 |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |DRAFT 1A  10-APR-2010  Sundaram S         Initial draft version                  |
-- |1.1       04-MAY-2010  Ramya priya M      Modified for defect#4320               |
-- |1.2       25-OCT-2011  Pradeep Mariappan  Modified for parallel execution of     |
-- |                                          validation part of ARLPLB to improve   |
-- |                                          performance # defect 14764             |
-- |1.3       30-AUG-2013  Deepak V           E0062-Changes made for R12 upgrade.    |
-- |                                          Modified the request submission of     |
-- |                                          Process Lockboxes.                     |
-- |1.4       27-ICT-2015  Vasu Raparla       Removed Schema References for R12.2    |
-- +=================================================================================+
-- | Name        : XX_AR_STD_LBX_SUB_CHILD_PKG                                       |
-- | Description : This procedure will be used to Submit Processs Lockbox            |
-- |               and invoke BPEL process to release ESP jobs                       |
-- | Parameters  : x_errbuf                                                          |
-- |              ,x_retcode                                                         |
-- |              ,p_file_name                                                       |
-- |              ,p_custom_main_req_id                                              |
-- |              ,p_transmission_id                                                 |
-- |              ,p_trans_request_id                                                |
-- |              ,p_trans_format_id                                                 |
-- |              ,p_gl_date                                                         |
-- |              ,p_email_notify_flag                                               |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- +=================================================================================+

  PROCEDURE XX_PROC_LBX_CHILD_MAIN ( x_errbuf                  OUT     NOCOPY     VARCHAR2
                                    ,x_retcode                 OUT     NOCOPY     NUMBER
                                    ,p_file_name               IN                 VARCHAR2
                                    ,p_custom_main_req_id      IN                 NUMBER
                                    ,p_transmission_id         IN                 NUMBER
                                    ,p_trans_request_id        IN                 NUMBER
                                    ,p_trans_format_id         IN                 NUMBER
                                    ,p_gl_date                 IN                 DATE
                                    ,p_email_notify_flag       IN                 VARCHAR2)
  IS
---------------------------------
-- Variable Declaration
---------------------------------
    lc_error_details     VARCHAR2(4000);
    lc_error_location    VARCHAR2(4000);
    lc_chk_flag          VARCHAR2(120);
    lc_request_data      VARCHAR2(120);
    ln_mail_request_id   NUMBER;
    lc_conc_status       VARCHAR2(50);
    ln_lbx_req_id        NUMBER;
    ln_lck_req_id        NUMBER;
    lc_lck_filename      VARCHAR2(200);
    lc_trans_name        VARCHAR2(30);
    ln_err_cnt           NUMBER;
    ln_wrn_cnt           NUMBER;
    ln_nrm_cnt           NUMBER;
    ln_term_cnt          NUMBER;       -- Added on 04-MAY-10
    l_custom_lockbox_status NUMBER := 0 ; -- Added by Pradeep Mariappan

---------------------------------
-- Private Procedure Declaration
---------------------------------
    PROCEDURE INVOKE_ESP_BPEL_PROCESS(p_filename IN VARCHAR2)
    IS
     lc_method            XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_namespace         XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_soap_action       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_bpel_url          XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_debug_mode        XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_process_name      XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_as2name           XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_domain_name       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_bpel_input1       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_bpel_input2       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lc_bpel_input3       XX_FIN_TRANSLATEVALUES.target_value2%TYPE   DEFAULT   NULL;
     lr_req_typ           XX_FIN_BPEL_SOAP_API_PKG.request_rec_type   DEFAULT   NULL;
     lr_resp_typ          XX_FIN_BPEL_SOAP_API_PKG.response_rec_type  DEFAULT   NULL;
     lc_lb_headername     XX_FIN_TRANSLATEVALUES.source_value1%TYPE   DEFAULT   NULL;
     lc_loc               VARCHAR2(3);

    BEGIN

      lc_loc := '1';
      FND_FILE.put_line(FND_FILE.LOG,CHR(13)||CHR(13));
      FND_FILE.put_line(FND_FILE.LOG,'-------------------- Invoking BPEL Process to release ESP job --------------------');
      FND_FILE.put_line(FND_FILE.LOG,'p_filename           : '||p_filename);

      lc_loc := '2';
      FOR lcu_bpel_param IN (SELECT   XFTV.source_value1
                                     ,XFTV.target_value1
                                     ,XFTV.target_value2
                             FROM     xx_fin_translatedefinition XFTD
                                     ,xx_fin_translatevalues XFTV
                             WHERE   XFTD.translate_id = XFTV.translate_id
                             AND     XFTD.translation_name = 'AR_LOCKBOX_BPEL_SETUP'
                             AND     XFTV.target_value1 IN ('BPEL_INVOKE','BPEL_INPUT')
                             AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                             AND     SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                             AND     XFTV.enabled_flag = 'Y'
                             AND     XFTD.enabled_flag = 'Y')
      LOOP
         IF (lcu_bpel_param.target_value1 = 'BPEL_INVOKE') THEN
            IF (lcu_bpel_param.source_value1 = 'METHOD') THEN 
                lc_method := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'NAMESPACE') THEN
                lc_namespace  := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'SOAP_ACTION') THEN 
                lc_soap_action := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'URL') THEN
                lc_bpel_url    := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'DEBUG_MODE') THEN
                lc_debug_mode  := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'PROCESS_NAME') THEN
                lc_process_name := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'DOMAIN_NAME') THEN
                lc_domain_name := lcu_bpel_param.target_value2;
            END IF;
         ELSIF (lcu_bpel_param.target_value1 = 'BPEL_INPUT') THEN
            IF (lcu_bpel_param.source_value1 = 'BPEL_INPUT1') THEN 
                lc_bpel_input1 := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'BPEL_INPUT2') THEN 
                lc_bpel_input2 := lcu_bpel_param.target_value2;
            ELSIF (lcu_bpel_param.source_value1 = 'BPEL_INPUT3') THEN 
                lc_bpel_input3 := lcu_bpel_param.target_value2;
            END IF;
         END IF;
      END LOOP;

      lc_loc := '3';
      lc_lb_headername := SUBSTR(p_filename,INSTR(p_filename,'/',-1,1)+1);

      lc_lb_headername := SUBSTR(lc_lb_headername,1,INSTR(lc_lb_headername,'.',-1,1)-1);

      lc_lb_headername := SUBSTR(lc_lb_headername,16);

      lc_loc := '4';
      SELECT   XFTV.target_value2
      INTO     lc_as2name
      FROM     xx_fin_translatedefinition XFTD
              ,xx_fin_translatevalues XFTV
      WHERE   XFTD.translate_id = XFTV.translate_id
      AND     XFTD.translation_name = 'AR_LOCKBOX_BPEL_SETUP'
      AND     XFTV.target_value1 = 'AS2NAME'
      AND     XFTV.source_value1 = lc_lb_headername
      AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
      AND     SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
      AND     XFTV.enabled_flag = 'Y'
      AND     XFTD.enabled_flag = 'Y' ;

      FND_FILE.put_line(FND_FILE.LOG,'BPEL Parameters derived from AR_BPEL_LOCKBOX_SETUP Translation');
      FND_FILE.put_line(FND_FILE.LOG,'METHOD            : '||lc_method);
      FND_FILE.put_line(FND_FILE.LOG,'NAMESPACE         : '||lc_namespace);
      FND_FILE.put_line(FND_FILE.LOG,'SOAP_ACTION       : '||lc_soap_action);
      FND_FILE.put_line(FND_FILE.LOG,'URL               : '||lc_bpel_url);
      FND_FILE.put_line(FND_FILE.LOG,'DEBUG_MODE        : '||lc_debug_mode);
      FND_FILE.put_line(FND_FILE.LOG,'PROCESS_NAME      : '||lc_process_name);
      FND_FILE.put_line(FND_FILE.LOG,'DOMAIN_NAME       : '||lc_domain_name);
      FND_FILE.put_line(FND_FILE.LOG,'BPEL_INPUT1       : '||lc_bpel_input1);
      FND_FILE.put_line(FND_FILE.LOG,'BPEL_INPUT2       : '||lc_bpel_input2);
      FND_FILE.put_line(FND_FILE.LOG,'BPEL_INPUT3       : '||lc_bpel_input3);


      lc_loc := '5';
      lr_req_typ := XX_FIN_BPEL_SOAP_API_PKG.new_request(
                                                        lc_method
                                                        ,lc_namespace
                                                        );

      lc_loc := '6';
      XX_FIN_BPEL_SOAP_API_PKG.add_parameter(
                                             lr_req_typ
                                            ,lc_bpel_input1
                                            ,'xsd:string'
                                            ,lc_process_name
                                            );

      lc_loc := '7';
      XX_FIN_BPEL_SOAP_API_PKG.add_parameter(
                                             lr_req_typ
                                            ,lc_bpel_input2
                                            ,'xsd:string'
                                            ,lc_domain_name
                                            );

      lc_loc := '8';
      XX_FIN_BPEL_SOAP_API_PKG.add_parameter(
                                             lr_req_typ
                                            ,lc_bpel_input3
                                            ,'xsd:string'
                                            ,lc_as2name
                                            );

      FND_FILE.put_line(FND_FILE.LOG,'BPEL Process Request/Response'||CHR(13));
      FND_FILE.put_line(FND_FILE.LOG,CHR(13)||CHR(13));

      lc_loc := '9';
      lr_resp_typ := XX_FIN_BPEL_SOAP_API_PKG.invoke(
                                                     lr_req_typ
                                                    ,lc_bpel_url
                                                    ,lc_soap_action
                                                    );
    EXCEPTION
     WHEN OTHERS THEN
        FND_FILE.put_line(FND_FILE.LOG,'Error occured at '||lc_loc||' due to '||CHR(13)||SQLERRM);
    END INVOKE_ESP_BPEL_PROCESS;

---------------------------------
-- Private Function Declaration
-- Added by Pradeep Mariappan
---------------------------------

  FUNCTION submit_custom_arlplb (p_transmission_id IN NUMBER
                                         , p_trans_request_id IN NUMBER
                                         , lc_trans_name IN VARCHAR2
                                         , p_trans_format_id IN NUMBER
                                         , p_gl_date IN DATE
                                         , p_custom_main_req_id IN NUMBER
                                         , p_lbx_file_name IN VARCHAR2
                                         ) return NUMBER IS 
   ln_req_id NUMBER;
   l_status_code VARCHAR2(1) := ''; -- Added by Pradeep
   l_phase_code VARCHAR2(1) := '';  -- Added by Pradeep
   l_exit_condition NUMBER := 0 ;  -- Added by Pradeep
   l_submit_condition NUMBER := 0 ; -- Added by Pradeep
   lc_chk_flag          VARCHAR2(120);
   lc_request_data      VARCHAR2(120);
   lc_conc_status       VARCHAR2(120);
  BEGIN

    ln_req_id := FND_REQUEST.SUBMIT_REQUEST (  'AR' -- Application
                                               ,'XX_ARLPLB' -- Program
                                               ,'' -- Description
                                               ,SYSDATE -- Start Time
                                               ,FALSE -- Sub Request
                                               ,'N' -- New Transmission
                                               ,p_transmission_id
                                               ,p_trans_request_id
                                               ,lc_trans_name
                                               ,'N' -- Submit Import
                                               ,NULL -- Data File
                                               ,NULL -- Control File
                                               ,p_trans_format_id
                                               ,'Y' -- Submit Validation
                                               ,'N' -- Pay Unrelated Invoices
                                               ,NULL -- Lockbox Id
                                               ,TO_CHAR(p_gl_date,'YYYY/MM/DD HH24:MI:SS') -- GL_DATE
                                               ,'R' -- Report Format
                                               ,'N' -- Complete Batches
                                               ,'N' -- submit post batch 
                                               ,'N' -- alternate name search option
                                               ,'Y' -- Post Partial Amount or Reject Entire Receipt 
                                               ,NULL -- USSGL Transaction Code
                                               ,FND_PROFILE.VALUE('ORG_ID') -- Operating Unit            
											   ,'N' --Apply Unearned Discount                            Added for R12 Upgrade retrofit
												,1   --No Of Instances (1 - 99)                          Added for R12 Upgrade retrofit
												,'L'  --Source type flag (S - SmartCash or L - Lockbox)  Added for R12 Upgrade retrofit
												,NULL --Scoring Model                                    Added for R12 Upgrade retrofit
                                            );
    COMMIT;
    FND_FILE.put_line(FND_FILE.LOG,'Custom Request ID of Standard Lockbox for validation  '||ln_req_id);     

    IF (ln_req_id IS NULL OR ln_req_id = 0)THEN
      FND_FILE.PUT_LINE (FND_FILE.LOG,'Failed to submit the Standard Lockbox for Validation ' || ' : ' || SQLCODE || ' : ' || SQLERRM);
    END IF;
    LOOP
      BEGIN
        SELECT status_code
               ,phase_code
               ,DECODE(status_code, 'E','Failure'
                                      , 'X','Terminated'
                                      , 'G','Warning'
                                      , 'D','Cancelled'
                                      , 'C','Success'
                                      ,'No Status Code Matched'
                          )
        INTO l_status_Code, l_phase_code, lc_conc_status
        FROM fnd_concurrent_requests 
        WHERE request_id = ln_req_id ;
      EXCEPTION 
        WHEN no_data_found THEN 
          l_status_code := 'E' ;
          l_phase_code := 'C' ;
          lc_conc_status := 'Failure';
      END ;
      IF ( l_status_code = 'C' AND l_phase_code = 'C' ) THEN 
        l_exit_condition := 1 ;
        l_submit_condition := 1 ;
      ELSIF ( l_status_code <> 'C' AND l_phase_code = 'C' ) THEN
        l_exit_condition := 1 ;
        l_submit_condition := 0 ;
      ELSE
        DBMS_LOCK.SLEEP(60) ; -- Sleep for 60 seconds
        l_exit_condition := 0 ;
      END IF; 
      EXIT WHEN l_exit_condition = 1 ;
    END LOOP; 

    -- Update wrapper temp with Y
    UPDATE xx_ar_lbx_wrapper_temp
      SET  processed = 'Y'
          ,transmission_id           = p_transmission_id
          ,process_lbx_val_req_id    = ln_req_id
          ,process_lbx_val_status    = lc_conc_status
    WHERE lbx_custom_main_req_id     = p_custom_main_req_id
      AND exact_file_name            = p_lbx_file_name;
		
    RETURN l_submit_condition ;
    EXCEPTION 
      WHEN others THEN 
        FND_FILE.put_line(FND_FILE.LOG,'Exception in submit_custom_arlplb: '||substr(SQLERRM, 1, 80));
        RETURN 0 ;
  END ;

  BEGIN

        lc_chk_flag     := FND_CONC_GLOBAL.request_data;
        lc_lck_filename := SUBSTR(p_file_name,INSTR(p_file_name,'/',-1)+1);    -- File Name
        lc_trans_name   := SUBSTR(lc_lck_filename,1,30);                       -- Transmission Name

        FND_FILE.put_line(FND_FILE.LOG,'[WIP] Request_data - '||NVL(lc_chk_flag,'FIRST'));
---+===============================================================================================
---|  STEP#1 -- Submit Process Lockbox with the required parameters
---+===============================================================================================
        IF(NVL(SUBSTR(lc_chk_flag,1,INSTR(lc_chk_flag,'-',1)-1),'FIRST') = 'FIRST') THEN

              lc_error_location := 'LBXWRP-1001';
              lc_error_details  := 'Submitting Process lockbox';

              /* Start of Code Changes by Pradeep Mariappan */ 
              FND_FILE.put_line(FND_FILE.LOG,'[WIP] Step# 1 Submit Custom Standard Lockbox  - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );
              l_custom_lockbox_status := submit_custom_arlplb (p_transmission_id, p_trans_request_id, lc_trans_name, 
                                                       p_trans_format_id, p_gl_date, p_custom_main_req_id, lc_lck_filename) ;

              IF (l_custom_lockbox_status = 1 ) THEN               
                FND_FILE.put_line(FND_FILE.LOG,'[WIP] Step# 2 Submit Standard Lockbox  - ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS') );

                ln_lck_req_id := FND_REQUEST.SUBMIT_REQUEST (  'AR' -- Application
                                                            ,'ARLPLB' -- Program
                                                            ,'' -- Description
                                                            ,SYSDATE -- Start Time
                                                            ,TRUE -- Sub Request
                                                            ,'N' -- New Transmission
                                                            ,p_transmission_id
                                                            ,p_trans_request_id
                                                            ,lc_trans_name
                                                            ,'N' -- Submit Import 
                                                            ,NULL -- Data File
                                                            ,NULL -- Control File
                                                            ,p_trans_format_id
                                                            ,'N' -- Submit Validation
                                                            ,'N' -- Pay Unrelated Invoices
                                                            ,NULL -- Lockbox Id
                                                            ,TO_CHAR(p_gl_date,'YYYY/MM/DD HH24:MI:SS') -- GL_DATE
                                                            ,'R' -- Report Format
                                                            ,'N' -- Complete Batches Only
                                                            ,'Y' -- submit post batch 
                                                            ,'N' -- alternate name search option
                                                            ,'Y' -- Post Partial Amount or Reject Entire Receipt 
                                                            ,NULL -- USSGL Transaction Code
                                                            ,FND_PROFILE.VALUE('ORG_ID') -- Operating Unit
															,'N' --Apply Unearned Discount                           Added for R12 Upgrade retrofit
															,10   --No Of Instances (1 - 99)                          Added for R12 Upgrade retrofit
															,'L'  --Source type flag (S - SmartCash or L - Lockbox)  Added for R12 Upgrade retrofit
															,NULL --Scoring Model                                    Added for R12 Upgrade retrofit
                                                          );
                COMMIT;
                FND_FILE.put_line(FND_FILE.LOG,'[WIP] Request ID of Standard Lockbox  '||ln_lck_req_id);
                lc_request_data := 'COMPLETE'||'-'||ln_lck_req_id;
                FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=> lc_request_data);
                FND_FILE.put_line(FND_FILE.LOG,'[WIP] Checking the status of OD: AR Standard Lockbox Submission Program - Child');
                COMMIT;
              END IF; 
              /* End of Code Changes by Pradeep Mariappan */ 
              RETURN;
        END IF;

---+===============================================================================================
---|  STEP#2 -- Invoke ESP BPEL Process and Submit Emailer
---+===============================================================================================

        IF(NVL(SUBSTR(lc_chk_flag,1,INSTR(lc_chk_flag,'-',1)-1),'FIRST') = 'COMPLETE') THEN

           FND_FILE.put_line(FND_FILE.LOG,'[WIP] Step #2 - Submit Emailer and Invoke ESP BPEL Process');
           ln_lbx_req_id := TO_NUMBER(SUBSTR(lc_chk_flag,INSTR(lc_chk_flag,'-',1)+1));
--+=============================
-- Derive Process Lockbox Status
--+=============================
           lc_error_location := 'LBXWRP-1002';
           lc_error_details  := 'Derive Process Lockbox Status';

           BEGIN
             SELECT DECODE(status_code, 'E','Failure'
                                      , 'X','Terminated'
                                      , 'G','Warning'
                                      , 'D','Cancelled'
                                      , 'C','Success'
                                      ,'No Status Code Matched'
                          )
                   ,CASE WHEN status_code = 'E'
                             THEN 1 ELSE 0 END
                   ,CASE WHEN status_code = 'G'
                             THEN 1 ELSE 0 END
                   ,CASE WHEN status_code = 'C'
                            THEN 1 ELSE 0 END
                   ,CASE WHEN status_code = 'X'            --Added on 04-MAY-10 for Defect # 4320
                             THEN 1 ELSE 0 END
               INTO lc_conc_status
                   ,ln_err_cnt
                   ,ln_wrn_cnt
                   ,ln_nrm_cnt
                   ,ln_term_cnt            --Added on 04-MAY-10 for Defect # 4320
               FROM fnd_concurrent_requests 
              WHERE request_id = ln_lbx_req_id;

              IF (ln_err_cnt > 0) OR (ln_term_cnt > 0)THEN   --Added ((ln_term_cnt > 0)) on 04-MAY-10 for Defect # 4320
                     FND_FILE.put_line(FND_FILE.LOG,'Process Lockbox ended in Error/Terminated');
                     x_errbuf  := 'Completion of OD: AR Standard Lockbox Submission Program - Child program';
                     x_retcode := 2;
                     RAISE_APPLICATION_ERROR ( -20001,'Process Lockbox ended in Error/Terminated');
              ELSIF (ln_wrn_cnt > 0)THEN
                    FND_FILE.put_line(FND_FILE.LOG,'Process Lockbox ended in Warning');
                    x_errbuf  := 'Completion of OD: AR Standard Lockbox Submission Program - Child program';
                    x_retcode := 1;
              END IF;

           EXCEPTION
              WHEN OTHERS THEN
                 FND_FILE.put_line(FND_FILE.LOG,lc_error_location
                                                ||'--'
                                                ||lc_error_details
                                                || 'Oracle Error Code'
                                                ||'--'
                                                ||SQLCODE
                                                ||'--'
                                                ||SQLERRM
                                   );
           END;

           FND_FILE.put_line(FND_FILE.LOG,'Process Lockbox -- Request ID -- '
                                           || ln_lbx_req_id 
                                           ||' -- Ended in -- '
                                           || lc_conc_status
                             );

---+==================
-- Update Temp Table
---+==================
           lc_error_location := 'LBXWRP-1003';
           lc_error_details := 'Update xx_ar_lbx_wrapper_temp table';

           UPDATE xx_ar_lbx_wrapper_temp
              SET  processed = 'Y'
                  ,transmission_id       = p_transmission_id
                  ,process_lbx_req_id    = ln_lbx_req_id
                  ,process_lbx_status    = lc_conc_status
            WHERE lbx_custom_main_req_id = p_custom_main_req_id
              AND exact_file_name        = lc_lck_filename;
           FND_FILE.put_line(FND_FILE.LOG,'No. of rows updated as processed in xx_ar_lbx_wrapper_temp -- '
                                          || SQL%ROWCOUNT
                            );
           COMMIT;
---+======================
-- Submit Emailer
---+======================
           lc_error_location := 'LCK-1003';
           lc_error_details := 'Update Temp table';

           IF (p_email_notify_flag IS NOT NULL) THEN
                 ln_mail_request_id := FND_REQUEST.SUBMIT_REQUEST (application => 'xxfin'
                                                                  ,program     => 'XXODROEMAILER'
                                                                  ,description => ''
                                                                  ,sub_request => TRUE
                                                                  ,start_time  => TO_CHAR(SYSDATE, 'DD-MON-YY HH:MI:SS')
                                                                  ,argument1   => ''
                                                                  ,argument2   => p_email_notify_flag
                                                                  ,argument3   => 'AR Lockbox Custom Partial Invoice Match  - ' ||TRUNC(SYSDATE)
                                                                  ,argument4   => ''
                                                                  ,argument5   => 'Y'
                                                                  ,argument6   => p_custom_main_req_id
                                                                  );
                 COMMIT;
                 IF (ln_mail_request_id IS NULL OR ln_mail_request_id = 0)THEN
                    lc_error_details := 'Failed to submit the Standard Common Emailer Program';
                    FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_details
                                                    || ' : ' 
                                                    || SQLCODE 
                                                    || ' : '
                                                    || SQLERRM
                                       );
                 END IF;
           END IF;
---+======================
-- Invoke ESP BPEL Process
---+======================
           INVOKE_ESP_BPEL_PROCESS(p_file_name);
        END IF;
    EXCEPTION
    WHEN OTHERS THEN
         ROLLBACK;
         fnd_message.set_name ('XXFIN','XX_AR_201_UNEXPECTED');
         fnd_message.set_token('PACKAGE','XX_AR_STD_LBX_SUB_CHILD_PKG.XX_PROC_LBX_CHILD_MAIN');
         fnd_message.set_token('PROGRAM','OD: AR Standard Lockbox Submission Program - Child');
         fnd_message.set_token('SQLERROR',SQLERRM);
         x_errbuf     := lc_error_location||'-'||lc_error_details||'-'||fnd_message.get;
         x_retcode    := 2;
      -- -------------------------------------------
      -- Call the Custom Common Error Handling
      -- -------------------------------------------
         XX_COM_ERROR_LOG_PUB.LOG_ERROR
             (
                p_program_type            => 'CONCURRENT PROGRAM'
               ,p_program_name            => 'XX_AR_STD_LBX_SUB_CHILD'
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
  END XX_PROC_LBX_CHILD_MAIN;
END XX_AR_STD_LBX_SUB_CHILD_PKG;
/
SHOW ERR

