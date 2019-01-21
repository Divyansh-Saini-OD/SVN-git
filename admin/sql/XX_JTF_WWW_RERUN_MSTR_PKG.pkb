-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_JTF_WWW_RERUN_MSTR_PKG.pkb                       |
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

create or replace package body XX_JTF_WWW_RERUN_MSTR_PKG
AS 
PROCEDURE jtf_rerun_mstr_main 
   (x_errbuf              OUT NOCOPY VARCHAR2
   ,x_retcode             OUT NOCOPY NUMBER
   ,p_batch_id            IN  NUMBER
  )
IS
    lc_request_set          varchar2(32);
    ln_batch_id             NUMBER;
    lc_error_msg            VARCHAR2(2000);

    lc_program_name         VARCHAR2(32);
    lc_stage_name           varchar2(32);
    lc_package_name         varchar2(32) := 'XX_JTF_WWW_RERUN_MSTR_PKG';
    lc_procedure_name       varchar2(32) := 'RERUN MSTR';
    lc_sqlerr_code          varchar2(100);
    lc_sqlerr_msg           varchar2(2000);
    lc_source_system        varchar2(10) := 'WWW';
 
    lb_success              BOOLEAN;
    le_request_set_notfound EXCEPTION;
    le_submit_pgm_failed    EXCEPTION;
    le_submit_set_failed    EXCEPTION;
    le_batch_id_invalid     EXCEPTION;

    ln_req_id               NUMBER;
    lv_phase                VARCHAR2(50) := NULL;
    lv_status               VARCHAR2(50) := NULL;
    lv_dev_phase            VARCHAR2(15) := NULL;
    lv_dev_status           VARCHAR2(15) := NULL;
    lb_wait                 BOOLEAN;
    lv_message              VARCHAR2(4000) := NULL;
    lv_select_end_date      varchar2(20);

BEGIN    
    ln_batch_id := p_batch_id;
    FND_FILE.put_line(fnd_file.log,
      'batch_id=' || p_batch_id);   

    fnd_file.put_line (fnd_file.log,' ');
    lc_request_set := 'XX_JTF_WWW_RERUN_SET';
    lb_success := fnd_submit.set_request_set('XXCRM', lc_request_set);
    If lb_success then 
        fnd_file.put_line (fnd_file.log,
          'request set ' || lc_request_set || ' found');
    else
        RAISE le_submit_pgm_failed;
    End if;
    fnd_file.put_line (fnd_file.log, 
      'end step 2 – set request set ' || lc_request_set);
--
    fnd_file.put_line (fnd_file.log,' ');
    Lc_program_name := 'XX_JTF_WWW_RERUN';
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
--
    fnd_file.put_line (fnd_file.log,' ');
    Lc_program_name := 'XX_JTF_WWW_PROSPECT_MSTR';
    lc_stage_name := 'STAGE20';
    Lb_success := fnd_submit.submit_program 
       (application => 'XXCRM'
       ,stage       => lc_stage_name
       ,program     => lc_program_name          
       );
    if lb_success then 
        fnd_file.put_line (fnd_file.log,
          'program ' || Lc_program_name || ' has been submitted');
    Else
        RAISE le_submit_pgm_failed;
    End if;
    fnd_file.put_line (fnd_file.log, 
      'end step 4 – submit program ' || lc_program_name);
--
    fnd_file.put_line (fnd_file.log,' ');
    Lc_program_name := 'XX_JTF_WWW_CONTACT_MSTR';
    lc_stage_name := 'STAGE30';
    Lb_success := fnd_submit.submit_program 
       (application => 'XXCRM'
       ,stage       => lc_stage_name
       ,program     => lc_program_name     
       );
    if lb_success then 
        fnd_file.put_line (fnd_file.log,
          'program ' || Lc_program_name || ' has been submitted');
    Else
        RAISE le_submit_pgm_failed;
    End if;
    fnd_file.put_line (fnd_file.log, 
      'end step 5 – submit program ' || lc_program_name);
--

    fnd_file.put_line (fnd_file.log,' ');
    Lc_program_name := 'XX_JTF_WWW_LEAD_MSTR'; 
    lc_stage_name := 'STAGE40';
    Lb_success := fnd_submit.submit_program 
       (application => 'XXCRM'
       ,stage       => lc_stage_name
       ,program     => lc_program_name     
       );
   if lb_success then 
        fnd_file.put_line (fnd_file.log,
          'program ' || Lc_program_name || ' has been submitted');
    Else
        RAISE le_submit_pgm_failed;
    End if;
    fnd_file.put_line (fnd_file.log, 
      'end step 6 – submit program ' || lc_program_name);

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
      'end step 7 – submit request set ' || lc_request_set);
    
    -- Wait for XX_CDH_SOLAR_CUST_CONV Program to Complete
          
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
      'end step 8 – wait for request (to complete) ' || lc_request_set);

    fnd_file.put_line (fnd_file.log,' ');
    fnd_file.put_line (fnd_file.log,lc_package_name || ' ending');

EXCEPTION
    WHEN le_submit_pgm_failed THEN
      ROLLBACK;

      lc_error_msg := 'submit of program ' || lc_program_name || 
                      ' in state ' || lc_stage_name || ' failed';

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

    WHEN le_submit_set_failed THEN
      x_errbuf := fnd_message.get;        
      
      ROLLBACK;

      lc_error_msg := 'submit of request set ' || lc_request_set || ' failed';

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

    WHEN le_request_set_notfound then
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

    WHEN OTHERS THEN
      fnd_message.set_name('XXCRM','XX_CDH_0032_WWW_CONTACT_ERR');
      
      lc_error_msg := fnd_message.get || ' ORA ERR:' || SQLCODE || ':' || SQLERRM;
      
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

END jtf_rerun_mstr_main;

END XX_JTF_WWW_RERUN_MSTR_PKG;
/
Show errors
/

