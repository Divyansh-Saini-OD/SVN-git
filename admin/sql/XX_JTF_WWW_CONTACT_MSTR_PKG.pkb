-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_JTF_WWW_CONTACT_MSTR_PKG.pkb                     |
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

create or replace package body XX_JTF_WWW_CONTACT_MSTR_PKG
AS 
PROCEDURE jtf_contact_mstr_main 
   (x_errbuf              OUT NOCOPY VARCHAR2
   ,x_retcode             OUT NOCOPY NUMBER
  )
IS
    ln_batch_id             NUMBER;
    ln_batch_descr          VARCHAR2(50);
    lc_batch_error_msg      VARCHAR2(2000);
    lc_error_msg            VARCHAR2(2000);
    lc_request_set          varchar2(32);
    lc_process_name         varchar2(32) := 'JTF WWW CONTACT';
    lc_program_name         VARCHAR2(32);
    lc_stage_name           varchar2(32);
    lc_package_name         varchar2(32) := 'XX_JTF_WWW_CONTACT_MSTR_PKG';
    lc_procedure_name       varchar2(32) := 'LOAD CONTACTS';
    lc_sqlerr_code          varchar2(100);
    lc_sqlerr_msg           varchar2(2000);
    lc_source_system        varchar2(10) := 'WWW';
    ln_new_prospects_cnt    NUMBER;
    ln_HZ_PARTIES_CNT       NUMBER;
    ln_hz_party_sites_cnt   NUMBER;
    ln_hz_org_contacts_cnt  NUMBER;
    ln_hz_contact_points_cnt NUMBER;    
    
    lb_success              BOOLEAN;
    le_request_set_notfound EXCEPTION;
    le_submit_pgm_failed    EXCEPTION;
    le_submit_set_failed    EXCEPTION;
    le_batch_ID_error       EXCEPTION;

    lc_max_error_tolerance  number := 50;
    lc_submit_OWB_Load      varchar2(1) := 'Y';

    lc_submit_bulk          varchar2(1) := 'Y';
    lc_create_cust_acct     varchar2(1) := 'N';
    lc_create_contact       varchar2(1) := 'N';
    lc_create_cust_prof     varchar2(1) := 'N';
    lc_create_bank_payment  varchar2(1) := 'N';
    lc_create_ext_attrib    varchar2(1) := 'N';
    lc_import_run_option    varchar2(8) := 'COMPLETE';
    lc_run_batch_dedup      varchar2(1) := 'N';
    lc_batch_dedup_rule     varchar2(1) := null;
    lc_action_duplicates    varchar2(1) := null;
    lc_run_addr_val         varchar2(1) := 'N';
    lc_run_reg_dedup        varchar2(1) := 'N';
    lc_reg_dedup_rule       varchar2(1) := null;
    lc_generate_fuzzy_key   varchar2(1) := 'N';

    ln_req_id          NUMBER;
    lv_phase           VARCHAR2(50) := NULL;
    lv_status          VARCHAR2(50) := NULL;
    lv_dev_phase       VARCHAR2(15) := NULL;
    lv_dev_status      VARCHAR2(15) := NULL;
    lb_wait            BOOLEAN;
    lv_message         VARCHAR2(4000) := NULL;

BEGIN    
    XX_JTF_WWW_CONV_PKG.get_batch_id
      (  p_process_name      => lc_process_name
        ,p_group_id          => 'N/A'
        ,x_batch_descr       => ln_batch_descr
        ,x_batch_id          => ln_batch_id
        ,x_error_msg         => lc_batch_error_msg
      );
 
    fnd_file.put_line (fnd_file.log, 
       'batch_id=' || ln_batch_id || ', batch_name=' || ln_batch_descr);

    if lc_batch_error_msg is null then
        INSERT INTO XXCRM.XX_JTF_WWW_BATCH_ID
          (batch_id
          ,batch_descr
          ,create_date)
        Values 
          (ln_batch_id
          ,ln_batch_descr
          ,sysdate);
        COMMIT;
    else
        RAISE le_batch_ID_error;
    end if;

    fnd_file.put_line (fnd_file.log, 
      'batch_id process completed-no errors');
    fnd_file.put_line (fnd_file.log, 'end step 1 – generate batch id');
--  
    fnd_file.put_line (fnd_file.log,' ');
    lc_request_set := 'XX_JTF_WWW_CONTACT_SET';
    lb_success := fnd_submit.set_request_set('XXCRM', lc_request_set);
    If lb_success then 
        fnd_file.put_line (fnd_file.log,
          'request set ' || lc_request_set || ' found');
    else
        RAISE le_request_set_notfound;
    End if;
    fnd_file.put_line (fnd_file.log, 
      'end step 2 – set request set ' || lc_request_set);
--
    fnd_file.put_line (fnd_file.log,' ');
    Lc_program_name := 'XX_JTF_WWW_CONTACT';
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
    Lc_program_name := 'XX_CDH_OWB_CVSTG'; 
    lc_stage_name := 'STAGE20';
    Lb_success := fnd_submit.submit_program 
       (application => 'XXCNV'
       ,stage       => lc_stage_name
       ,program     => lc_program_name
       ,argument1   => ln_batch_id
       ,argument2   => ln_batch_id
       ,argument3   => lc_max_error_tolerance
       ,argument4   => lc_submit_OWB_load
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
    Lc_program_name := 'XX_CDH_CUST_CONV_MASTER'; 
    lc_stage_name := 'STAGE30';
    Lb_success := fnd_submit.submit_program 
       (application => 'XXCNV'
       ,stage       => lc_stage_name
       ,program     => lc_program_name
       ,argument1   => ln_batch_id
       ,argument2   => ln_batch_id
       ,argument3   => lc_submit_bulk
       ,argument4   => lc_create_cust_acct
       ,argument5   => lc_create_contact
       ,argument6   => lc_create_cust_prof
       ,argument7   => lc_create_bank_payment
       ,argument8   => lc_create_ext_attrib 
       ,argument9   => lc_import_run_option
       ,argument10  => lc_run_batch_dedup
       ,argument11  => lc_batch_dedup_rule 
       ,argument12  => lc_action_duplicates
       ,argument13  => lc_run_addr_val
       ,argument14  => lc_run_reg_dedup
       ,argument15  => lc_reg_dedup_rule
       ,argument16  => lc_generate_fuzzy_key
       );
    if lb_success then 
        fnd_file.put_line (fnd_file.log,
          'program ' || Lc_program_name || ' has been submitted');
    Else
        RAISE le_submit_pgm_failed;
    End if;
    fnd_file.put_line (fnd_file.log, 
      'end step 5 – submit program ' || lc_program_name);

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
      'end step 6 – submit request set ' || lc_request_set);
    
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
      'end step 7 – wait for request (to complete) ' || lc_request_set);

    fnd_file.put_line (fnd_file.log,
      'queries from HZ_ORIG_SYS_REFERENCES:');

    Select count(*) into ln_new_prospects_cnt
      from xxcrm.xx_jtf_www_new_prospects;
    fnd_file.put_line (fnd_file.log,
      '  new prospects cnt=' || ln_new_prospects_cnt);
   
    Select count(*) into ln_HZ_PARTIES_CNT
      From hz_orig_sys_references
     Where orig_system = 'SX'
       And orig_system_reference 
            in (select lpad(internid,10,'0') || '-WWW'
                  from xxcrm.xx_jtf_www_new_prospects)
       and owner_table_name = 'HZ_PARTIES';
    fnd_file.put_line (fnd_file.log,
      '  HZ_PARTIES cnt=' || ln_hz_parties_cnt);

    Select count(*) into ln_hz_party_sites_cnt
      From hz_orig_sys_references
     Where orig_system = 'SX'
       And orig_system_reference 
            in (select lpad(internid,10,'0') || '-WWW'
                  from xxcrm.xx_jtf_www_new_prospects) 
       and owner_table_name = 'HZ_PARTY_SITES';
    fnd_file.put_line (fnd_file.log,
      '  HZ_PARTY_SITES cnt=' || ln_hz_party_sites_cnt);

    Select count(*) into ln_hz_org_contacts_cnt
      From hz_orig_sys_references
     Where orig_system = 'SX'
       And orig_system_reference 
            in (select lpad(internid,10,'0') || '-WWW'
                  from xxcrm.xx_jtf_www_new_prospects) 
       and owner_table_name = 'HZ_ORG_CONTACTS';
    fnd_file.put_line (fnd_file.log,
      '  HZ_ORG_CONTACTS cnt=' || ln_hz_org_contacts_cnt);

    Select count(*) into ln_hz_contact_points_cnt
      From hz_orig_sys_references
     Where orig_system = 'SX'
       And orig_system_reference 
            in (select lpad(internid,10,'0') || '-WWW-GEN'
                  from xxcrm.xx_jtf_www_new_prospects)
       and owner_table_name = 'HZ_CONTACT_POINTS';
    fnd_file.put_line (fnd_file.log,
      '  HZ_CONTACT_POINTS cnt=' || ln_hz_contact_points_cnt);

    if ln_HZ_PARTIES_CNT <> ln_new_prospects_cnt then 
        fnd_file.put_line (fnd_file.log,
          '*** possible error in HZ_PARTIES setup ***');
        x_retcode := 1;
    end if;

    if ln_HZ_PARTy_sites_CNT <> ln_new_prospects_cnt then 
        fnd_file.put_line (fnd_file.log,
          '*** possible error in HZ_PARTY_SITES setup ***');
        x_retcode := 1;
    end if;

    if ln_HZ_ORG_CONTACTS_CNT <> ln_new_prospects_cnt then 
        fnd_file.put_line (fnd_file.log,
          '*** possible error in HZ_ORG_CONTACTS setup ***');
        x_retcode := 1;
    end if;

    if ln_HZ_CONTACT_POINTS_CNT <> ln_new_prospects_cnt then 
        fnd_file.put_line (fnd_file.log,
          '*** possible error in HZ_CONTACT_POINTS setup ***');
        x_retcode := 1;
    end if;

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

    WHEN le_request_set_notfound  THEN
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

    WHEN le_batch_ID_error THEN
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
      fnd_message.set_name('XXCRM','XX_CDH_0032_WWW_CONTACT_ERR');
      
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

END jtf_contact_mstr_main;

END XX_JTF_WWW_CONTACT_MSTR_PKG;
/
Show errors
/

