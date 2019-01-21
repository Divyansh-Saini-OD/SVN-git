-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_SFA_WWW_LEAD_MSTR_PKG.pkb                        |
-- | Description      :I2043 Leads_from_WWW_and_Jmillennia                 |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      15-Feb-2008 David Woods        Initial version                |
-- +=======================================================================+

create or replace package body XX_SFA_WWW_LEAD_MSTR_PKG
AS 
PROCEDURE sfa_lead_mstr_main 
   (x_errbuf              OUT NOCOPY VARCHAR2
   ,x_retcode             OUT NOCOPY NUMBER
   )
IS
    ln_batch_id             NUMBER;
    ln_batch_descr          VARCHAR2(50);
    lc_batch_error_msg      VARCHAR2(2000);
    lc_error_msg            VARCHAR2(2000);
    lc_request_set          varchar2(32);
    lv_process_name         varchar2(32) := 'SFA WWW LEAD';
    lv_msg_text             varchar2(80);
    lc_program_name         VARCHAR2(32);
    lc_stage_name           varchar2(32);
    lc_package_name         varchar2(32) := 'XX_SFA_WWW_LEAD_MSTR_PKG';
    lc_procedure_name       varchar2(32) := 'LOAD LEADS';
    lc_sqlerr_code          varchar2(100);
    lc_sqlerr_msg           varchar2(2000);
    lc_source_system        varchar2(10) := 'WWW';
    le_batch_id_error       EXCEPTION;
    le_request_set_notfound EXCEPTION;
    le_submit_pgm_failed    EXCEPTION;
    le_submit_set_failed    EXCEPTION;
    lb_success              BOOLEAN;

    ln_req_id          NUMBER;
    lv_phase           VARCHAR2(50) := NULL;
    lv_status          VARCHAR2(50) := NULL;
    lv_dev_phase       VARCHAR2(15) := NULL;
    lv_dev_status      VARCHAR2(15) := NULL;
    lb_wait            BOOLEAN;
    lv_message         VARCHAR2(4000) := NULL;

BEGIN    
    XX_SFA_WWW_CONV_PKG.get_batch_id
      (  p_process_name      => lv_process_name
        ,p_group_id          => 'N/A'
        ,x_batch_descr       => ln_batch_descr
        ,x_batch_id          => ln_batch_id
        ,x_error_msg         => lc_batch_error_msg
      );

    fnd_file.put_line (fnd_file.log, 
      'batch_id=' || ln_batch_id || ', batch_name=' || ln_batch_descr);

    if lc_batch_error_msg is null then
        INSERT INTO XXCRM.XX_SFA_WWW_BATCH_ID
          (batch_id
          ,batch_descr
          ,create_date)
        Values 
          (ln_batch_id
          ,ln_batch_descr
          ,sysdate);
        COMMIT;
    else
        RAISE le_batch_id_error;
    end if;
    fnd_file.put_line (fnd_file.log, 'batch_id process completed-no errors');
    fnd_file.put_line (fnd_file.log, 'end step 1 – generate batch id');
  
    fnd_file.put_line (fnd_file.log,' ');
    lc_request_set := 'XX_SFA_WWW_LEAD_SET';
    lb_success := fnd_submit.set_request_set('XXCRM', lc_request_set);
    If lb_success then 
        fnd_file.put_line (fnd_file.log,
          'request set ' || lc_request_set || ' found');
    else
        RAISE le_request_set_notfound;
    End if;
    fnd_file.put_line (fnd_file.log, 
      'end step 2 – set request set ' || lc_request_set);

    fnd_file.put_line (fnd_file.log,' ');
    Lc_program_name := 'XX_SFA_WWW_LEAD';
    lc_stage_name := 'STAGE10';
    Lb_success := fnd_submit.submit_program 
       (application => 'XXCRM'
       ,stage       => lc_stage_name
       ,program     => lc_program_name 
       ,argument1   => ln_batch_id              
       );
    if lb_success then 
        fnd_file.put_line (fnd_file.log,
          'program ' || Lc_program_name || ' has been submitted');
    Else
        RAISE le_submit_pgm_failed;
    End if;
    fnd_file.put_line (fnd_file.log, 
      'end step 3 – submit program ' || lc_program_name);

    fnd_file.put_line (fnd_file.log,' ');
    Lc_program_name := 'XXSFALEADSINT'; 
    lc_stage_name := 'STAGE20';
    Lb_success := fnd_submit.submit_program 
       (application => 'XXCRM'
       ,stage       => lc_stage_name
       ,program     => lC_program_name
       ,argument1   => ln_batch_id
       );
   if lb_success then 
        fnd_file.put_line (fnd_file.log,
          'program ' || Lc_program_name || ' has been submitted');
    Else
        RAISE le_submit_pgm_failed;
    End if;
    fnd_file.put_line (fnd_file.log, 
      'end step 4 – submit program ' || lc_program_name);

    -- Submit the Request Set 
      
    ln_req_id := fnd_submit.submit_set(NULL,false);
      
    IF ln_req_id = 0 THEN
        RAISE le_submit_set_failed;      
    ELSE
        fnd_file.put_line(fnd_file.LOG,' ');     
        fnd_file.put_line(fnd_file.LOG,
          'Request Set ' || lc_request_set || 
          ' submitted with request id: ' || to_char(ln_req_id));
        COMMIT;
    END IF;
    fnd_file.put_line (fnd_file.log, 
      'end step 5 – submit request set ' || lc_request_set);

    -- Wait for request set to Complete
          
    lb_wait := fnd_concurrent.wait_for_request
        (request_id => ln_req_id
        ,INTERVAL   => 10
        ,phase      => lv_phase
        ,status     => lv_status
        ,dev_phase  => lv_dev_phase
        ,dev_status => lv_dev_status
        ,message    => lv_message
        );
    fnd_file.put_line (fnd_file.log, 
      'end step 6 – wait for request (to complete) ' || lc_request_set);

    fnd_file.put_line (fnd_file.log,' ');
    fnd_file.put_line (fnd_file.log,lc_package_name || ' ending');

EXCEPTION
    WHEN le_submit_set_failed THEN
      x_errbuf := fnd_message.get;       
      lc_error_msg := 'submit request set for ' || lc_request_set || ' failed, msg: ' || x_errbuf;

      fnd_file.put_line (fnd_file.log,' ');
      fnd_file.put_line(fnd_file.LOG, 
        'An error occurred. ' || lc_error_msg);
      fnd_file.put_line(fnd_file.LOG,' ');

      INSERT INTO xx_com_exceptions_log_conv
        (exception_id
        ,log_date
        ,batch_id
        ,package_name
        ,procedure_name
        ,source_system_code
        ,exception_log)
      VALUES 
        (xxcomn.xx_exception_id_s1.nextval
        ,TO_CHAR(SYSDATE,'DD-MON-YYYY')
        ,ln_batch_id
        ,lc_package_name
        ,lc_procedure_name
        ,lc_source_system
        ,lc_error_msg);
      
      COMMIT;
  
      x_retcode := 2;

    WHEN le_submit_pgm_failed THEN
      ROLLBACK;

      lc_error_msg := 'submit of program ' || lc_program_name || 
                      ' in state ' || lc_stage_name || ' failed';

      fnd_file.put_line (fnd_file.log,' ');
      fnd_file.put_line(fnd_file.LOG,
        'An error occurred. ' || lc_error_msg);
      fnd_file.put_line(fnd_file.LOG,' ');

      INSERT INTO xx_com_exceptions_log_conv
        (exception_id
        ,log_date
        ,batch_id
        ,package_name
        ,procedure_name
        ,source_system_code
        ,exception_log)
      VALUES 
        (xxcomn.xx_exception_id_s1.nextval
        ,TO_CHAR(SYSDATE,'DD-MON-YYYY')
        ,ln_batch_id
        ,lc_package_name
        ,lc_procedure_name
        ,lc_source_system
        ,lc_error_msg);
      
      COMMIT;
  
      x_retcode := 2;

    WHEN le_request_set_notfound THEN
      ROLLBACK;

      lc_error_msg := 'set request set for ' || lc_request_set || ' failed';

      fnd_file.put_line (fnd_file.log,' ');
      fnd_file.put_line(fnd_file.LOG,
        'An error occured. ' || lc_error_msg);
      fnd_file.put_line(fnd_file.LOG,' ');

      INSERT INTO xx_com_exceptions_log_conv
        (exception_id
        ,log_date
        ,batch_id
        ,package_name
        ,procedure_name
        ,source_system_code
        ,exception_log)
      VALUES 
        (xxcomn.xx_exception_id_s1.nextval
        ,TO_CHAR(SYSDATE,'DD-MON-YYYY')
        ,ln_batch_id
        ,lc_package_name
        ,lc_procedure_name
        ,lc_source_system
        ,lc_error_msg);
      
      COMMIT;
  
      x_retcode := 2;

    WHEN le_batch_id_error THEN
      fnd_file.put_line(fnd_file.LOG,' ');
      fnd_file.put_line(fnd_file.LOG,
        'Error while creating Batch ID. ' || lc_batch_error_msg);
      fnd_file.put_line(fnd_file.LOG,' ');
      
      INSERT INTO xx_com_exceptions_log_conv
        (exception_id
        ,log_date
        ,batch_id
        ,package_name
        ,procedure_name
        ,source_system_code
        ,exception_log)
      VALUES 
        (xxcomn.xx_exception_id_s1.nextval
        ,TO_CHAR(SYSDATE,'DD-MON-YYYY')
        ,ln_batch_id
        ,lc_package_name
        ,lc_procedure_name
        ,lc_source_system
        ,lc_batch_error_msg);
      
      COMMIT;
      
      x_retcode := 2;

    WHEN OTHERS THEN
      fnd_message.set_name('XXCRM','XX_CDH_0033_WWW_LEAD_ERR');
      
      lc_error_msg 
        := fnd_message.get || ' ORA ERR:' || SQLCODE || ':' || SQLERRM;
      
      lc_sqlerr_code := SQLCODE;
   
      lc_sqlerr_msg := SQLERRM;
      
      ROLLBACK;
      
      fnd_file.put_line(fnd_file.LOG,' ');
      fnd_file.put_line(fnd_file.LOG,
        'An error occured. ' || lc_error_msg);      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      INSERT INTO xx_com_exceptions_log_conv
        (exception_id
        ,log_date
        ,batch_id
        ,package_name
        ,procedure_name
        ,source_system_code
        ,exception_log
        ,oracle_error_code
        ,oracle_error_msg)
      VALUES 
        (xxcomn.xx_exception_id_s1.nextval
        ,TO_CHAR(SYSDATE,'DD-MON-YYYY')
        ,ln_batch_id
        ,lc_package_name
        ,lc_procedure_name
        ,lc_source_system
        ,lc_error_msg
        ,lc_sqlerr_code
        ,lc_sqlerr_msg);
      
      COMMIT;
      
      x_retcode := 2;

END sfa_lead_mstr_main;

END XX_SFA_WWW_LEAD_MSTR_PKG;
/
Show errors
/
