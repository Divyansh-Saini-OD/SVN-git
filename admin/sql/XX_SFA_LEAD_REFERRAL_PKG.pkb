-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |                     Wipro Technologies                                |
-- +=======================================================================+
-- | Name             :XX_SFA_LEAD_REFERRAL_PKG.pks                        |
-- | Description      :I2043 Leads_from_WWW_and_Jmillennia                 |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      15-Feb-2008 David Woods        Initial version                |
-- |1.1      06-MAr-2008 Rizwan Appees      Restructuring the code         |
-- |1.2      11-Apr-2008 Rizwan Appees      Calling Mass Assignment Program|
-- |1.3      30-Apr-2008 Rizwan Appees      Calling lead Assignment Program|
-- |1.4      30-Apr-2008 Sreekanth          RSD Waves logic                |
-- |1.5      21-May-2008 Rizwan Appees      Do not call request set if no  |
-- |                                        Validated Record found         |
-- +=======================================================================+

CREATE OR REPLACE PACKAGE BODY xx_sfa_lead_referral_pkg
AS
-- +===================================================================+
-- | Name             : GET_BATCH_ID                                   |
-- | Description      : This procedure call api to generate Batch ID.  |
-- |                                                                   |
-- | Parameters :      p_process_name                                  |
-- |                   p_group_id                                      |
-- |                   x_batch_descr                                   |
-- |                   x_batch_id                                      |
-- |                   x_error_msg                                     |
-- +===================================================================+

  PROCEDURE get_batch_id
       (p_process_name  IN VARCHAR2
        ,p_group_id     IN VARCHAR2
        ,x_batch_descr  OUT VARCHAR2
        ,x_batch_id     OUT VARCHAR2
        ,x_error_msg    OUT VARCHAR2)
  IS
  ----------------------------------------------------------------------
  ---                Variable Declaration                            ---
  ----------------------------------------------------------------------
    lc_batch_name         VARCHAR2(32);
    lc_description        VARCHAR2(32);
    lc_original_system    VARCHAR2(32) := 'LR';
    ln_est_no_of_records  NUMBER := 500;
    lc_return_status      VARCHAR2(1);
    ln_msg_count          NUMBER;
    ln_counter            NUMBER;
    lc_msg_data           VARCHAR2(2000);
    ln_batch_id           NUMBER;
    ln_seq_nbr            NUMBER;

  BEGIN
  ----------------------------------------------------------------------
  ---                Get Batch ID sequence                           ---
  ----------------------------------------------------------------------
  
    SELECT xxcrm.xx_sfa_lr_batch_s.nextval
    INTO   ln_seq_nbr
    FROM   dual;
    
    lc_batch_name := p_process_name
                     ||'-'
                     ||lpad(ln_seq_nbr,6,'0');
    
    lc_description := lc_batch_name;
    ----------------------------------------------------------------------
    ---                Call import batch API                           ---
    ----------------------------------------------------------------------
    
    hz_imp_batch_summary_v2pub.create_import_batch(p_batch_name => lc_batch_name,p_description => lc_description,
                                                   p_original_system => lc_original_system,p_load_type => '',
                                                   p_est_no_of_records => ln_est_no_of_records,
                                                   x_batch_id => ln_batch_id,x_return_status => lc_return_status,
                                                   x_msg_count => ln_msg_count,x_msg_data => lc_msg_data);
    
    IF lc_return_status <> fnd_api.g_ret_sts_success THEN
      IF ln_msg_count > 0 THEN
        fnd_file.put_line(fnd_file.LOG,'Error while generating batch_id - ');
        
        FOR ln_counter IN 1.. ln_msg_count LOOP
          x_error_msg := x_error_msg
                         ||'Error ->'
                         ||fnd_msg_pub.get(ln_counter,fnd_api.g_false);
        END LOOP;
        
        fnd_msg_pub.delete_msg;
      END IF;
    ELSE
      x_error_msg := NULL;
    END IF;
    
    x_batch_descr := lc_description;
    
    x_batch_id := ln_batch_id;
  END get_batch_id;
  -- +===================================================================+
  -- | Name             : VALIDATE_DATA                                  |
  -- | Description      : This procedure extract eligible lead line and  |
  -- |                    validate the input data.                       |
  -- |                                                                   |
  -- | Parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- +===================================================================+
  
  PROCEDURE validate_data
       (x_errbuf    OUT NOCOPY VARCHAR2
        ,x_retcode  OUT NOCOPY NUMBER)
  IS
  ----------------------------------------------------------------------
  ---                Variable Declaration                            ---
  ----------------------------------------------------------------------
    lc_process_name        VARCHAR2(32) := 'SFA LEAD REFERRAL';
    ln_batch_id            NUMBER;
    ln_batch_descr         VARCHAR2(50);
    lc_error_msg           VARCHAR2(2000);
    le_batch_id_error      EXCEPTION;
    lc_batch_error_msg     VARCHAR2(240);
    lc_rev_band            VARCHAR2(32);
    lc_country             VARCHAR2(32);
    lc_validate_status     VARCHAR2(32);
    ln_tot_cnt             NUMBER := 0;
    ln_val_err_cnt         NUMBER := 0;
    ln_val_success_cnt     NUMBER := 0;
    lc_error_flag          VARCHAR2(32) := 'N';
    lc_application_name    xx_com_error_log.application_name%TYPE := 'XXCRM';
    lc_program_type        xx_com_error_log.program_type%TYPE := 'I2043_Lead_Referral';
    lc_program_name        xx_com_error_log.program_name%TYPE := 'XX_SFA_LEAD_REFERRAL_PKG';
    lc_module_name         xx_com_error_log.module_name%TYPE := 'SFA';
    lc_error_location      xx_com_error_log.error_location%TYPE := 'VALIDATE_DATA';
    lc_token               VARCHAR2(4000);
    lc_error_message_code  VARCHAR2(100);
    lc_err_desc            xx_com_error_log.error_message%TYPE DEFAULT ' ';
    ln_conc_request_id     NUMBER;
    lv_phase               VARCHAR2(50);
    lv_status              VARCHAR2(50);
    lv_dev_phase           VARCHAR2(15);
    lv_dev_status          VARCHAR2(15);
    lb_wait                BOOLEAN;
    lv_message             VARCHAR2(4000);
    lc_orig_system         VARCHAR2(60) := 'LR';
    lc_lead_error_text     VARCHAR2(4000);
    ln_valid_records       NUMBER := 0;

    ----------------------------------------------------------------------
    ---                Cursor Declaration                              ---
    ----------------------------------------------------------------------
    CURSOR lcu_lead_ref IS 
      SELECT *
      FROM   xxcrm.xx_sfa_lead_referrals
      WHERE  NVL(PROCESS_STATUS,'NEW') NOT IN ('PROCESSED', 'SENT_TO_SOLAR');

    CURSOR lcu_update_status(p_batch_id NUMBER) IS 
      SELECT import_interface_id
            ,batch_id
            ,load_status
            ,orig_system_reference
      FROM   as_import_interface
      WHERE  batch_id = p_batch_id;

     CURSOR lcu_lead_error(p_import_interface_id NUMBER) IS 
      SELECT batch_id, 
             import_interface_id, 
             error_text
        FROM as_lead_import_errors 
       WHERE import_interface_id = p_import_interface_id;
    

  BEGIN
  ----------------------------------------------------------------------
  ---                Writing LOG FILE                                ---
  ---  Exception if any will be caught in 'WHEN OTHERS'              ---
  ---  with system generated error message.                          ---
  ----------------------------------------------------------------------
  
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,rpad('Office Depot',40,' ')
                                   ||lpad('DATE: ',60,' ')
                                   ||to_char(SYSDATE,'DD-MON-YYYY HH:MI'));
    
    fnd_file.put_line(fnd_file.LOG,lpad('OD: SFA Lead Referral validate input data',
                                        69,' '));
    -----------------------------------------------------------------------
    ---                         VALIDATIONS.                            ---
    -----------------------------------------------------------------------
    
    FOR lr_lead_ref IN lcu_lead_ref LOOP
      
      lc_error_flag := 'N';
      lc_err_desc   := NULL;
      lc_validate_status := NULL;

      ln_tot_cnt := ln_tot_cnt + 1;
      -----------------------------------------------------------------------
      ---           Find Revenue Band based on the OD WCW count           ---
      -----------------------------------------------------------------------
      --This will be defined as Lookup.
      
      IF lr_lead_ref.num_wc_emp_od < 30 THEN
        lc_rev_band := 'STANDARD';
      ELSIF lr_lead_ref.num_wc_emp_od BETWEEN 30
                                              AND 50 THEN
        lc_rev_band := 'KEY_1';
      ELSIF lr_lead_ref.num_wc_emp_od BETWEEN 51
                                              AND 75 THEN
        lc_rev_band := 'KEY_2';
      ELSIF lr_lead_ref.num_wc_emp_od BETWEEN 76
                                              AND 150 THEN
        lc_rev_band := 'KEY_3';
      ELSIF lr_lead_ref.num_wc_emp_od BETWEEN 151
                                              AND 250 THEN
        lc_rev_band := 'KEY_4';
      ELSIF lr_lead_ref.num_wc_emp_od BETWEEN 251
                                              AND 500 THEN
        lc_rev_band := 'MAJOR_1';
      ELSIF lr_lead_ref.num_wc_emp_od BETWEEN 501
                                              AND 1000 THEN
        lc_rev_band := 'MAJOR_2';
      ELSIF lr_lead_ref.num_wc_emp_od > 1000 THEN
        lc_rev_band := 'MAJOR_3';
      ELSE
        lc_error_flag := 'Y';
        
        fnd_message.set_name('XXCRM','XX_SFA_090_LR_REVBAND_ERR');
        
        lc_token := lr_lead_ref.num_wc_emp_od;
        
        fnd_message.set_token('MESSAGE',lc_token);
        
        lc_err_desc := fnd_message.get;
        --lc_err_desc := 'Invalid WCW. Could not find Revenue Band.';
        
        xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                           p_program_type => lc_program_type,p_program_name => lc_program_name,
                                           p_module_name => lc_module_name,p_error_location => lc_error_location,
                                           p_error_message_code => 'XX_SFA_090_LR_REVBAND_ERR',
                                           p_error_message => substr(lc_err_desc
                                                                     ||'=>'
                                                                     ||SQLERRM,1,4000),
                                           p_error_message_severity => 'MAJOR');
      END IF;
      -----------------------------------------------------------------------
      ---           Find Country Code based on the State Code             ---
      -----------------------------------------------------------------------
      
      BEGIN
        SELECT country_code
        INTO   lc_country
        FROM   (SELECT DISTINCT SUBSTR(lookup_type,1,2) country_code
                                ,lookup_code state_code
                FROM   fnd_common_lookups
                WHERE  lookup_type IN ('CA_PROVINCE'
                                       ,'US_STATE'))
        WHERE  state_code = lr_lead_ref.state;
      EXCEPTION
        WHEN OTHERS THEN
          lc_error_flag := 'Y';
          
          fnd_message.set_name('XXCRM','XX_SFA_091_LR_COUNTRY_ERR');
          
          lc_token := lr_lead_ref.state;
          
          fnd_message.set_token('MESSAGE',lc_token);
          
          lc_err_desc := fnd_message.get;
          
          xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                             p_program_type => lc_program_type,p_program_name => lc_program_name,
                                             p_module_name => lc_module_name,p_error_location => lc_error_location,
                                             p_error_message_code => 'XX_SFA_091_LR_COUNTRY_ERR',
                                             p_error_message => substr(lc_err_desc
                                                                       ||'=>'
                                                                       ||SQLERRM,1,4000),
                                             p_error_message_severity => 'MAJOR');
      END;
      
      IF lc_error_flag = 'N' THEN
        lc_validate_status := 'VALIDATED';
        
        ln_val_success_cnt := ln_val_success_cnt + 1;
      ELSE
        lc_validate_status := 'VALIDATION_ERROR';
        
        ln_val_err_cnt := ln_val_err_cnt + 1;
      END IF;
      -----------------------------------------------------------------------
      ---               Upadte Status,Country and Revenue Band            ---
      -----------------------------------------------------------------------
      
      UPDATE xxcrm.xx_sfa_lead_referrals
      SET    process_status = lc_validate_status
             ,error_message = lc_err_desc
             ,country = lc_country
             ,rev_band = lc_rev_band
             ,prospect_osr = lr_lead_ref.internid||'-00001-'||lc_orig_system
             ,prospect_site_osr = lr_lead_ref.internid||'-00002-'||lc_orig_system
             ,contact_osr = lr_lead_ref.internid||'-CONTACT'
             ,lead_osr = lr_lead_ref.internid||'-00001-'||lc_orig_system
      WHERE  internid = lr_lead_ref.internid;
      
      COMMIT;
    END LOOP;
    
    ----------------------------------------------------------------------
    ---         Printing summary report in the LOG file                ---
    ----------------------------------------------------------------------
            
    fnd_file.put_line(fnd_file.LOG,' ');
            
    fnd_file.put_line(fnd_file.LOG,'Printing Validation Report');
            
    fnd_file.put_line(fnd_file.LOG,'--------------------------');
            
    fnd_file.put_line(fnd_file.LOG,'No of Lead Referrals: '
                                           ||ln_tot_cnt);
            
    fnd_file.put_line(fnd_file.LOG,'No of Invalid Lead Referrals:'
                                           ||ln_val_err_cnt);
            
    fnd_file.put_line(fnd_file.LOG,' ');


    IF (ln_tot_cnt - ln_val_err_cnt) > 0 THEN

            ----------------------------------------------------------------------
            ---                Generate Batch ID                               ---
            ---  Create a Batch ID and insert into XX_CDH_SOLAR_BATCH_ID       ---
            ----------------------------------------------------------------------
            
            fnd_file.put_line(fnd_file.LOG,' ');
            
            fnd_file.put_line(fnd_file.LOG,'Start generating Batch ID');
            
            xx_sfa_lead_referral_pkg.get_batch_id(p_process_name => lc_process_name,p_group_id => 'N/A',
                                                  x_batch_descr => ln_batch_descr,x_batch_id => ln_batch_id,
                                                  x_error_msg => lc_batch_error_msg);
            
            fnd_file.put_line(fnd_file.LOG,'batch_id='
                                           ||ln_batch_id
                                           ||', batch_name='
                                           ||ln_batch_descr);
            
            IF lc_batch_error_msg IS NULL  THEN
              INSERT INTO xxcrm.xx_sfa_lr_batch_id
                         (batch_id
                          ,batch_descr
                          ,create_date)
              VALUES     (ln_batch_id
                          ,ln_batch_descr
                          ,SYSDATE);
              
              COMMIT;
            ELSE
              RAISE le_batch_id_error;
            END IF;

            fnd_file.put_line(fnd_file.LOG,' ');

            fnd_file.put_line(fnd_file.LOG,'Profile OD: Use RSD Waves Logic In Lead Referrals is set to '||fnd_profile.value('XX_SFA_LR_USE_RSD_WAVES_LOGIC'));
	
            fnd_file.put_line(fnd_file.LOG,' ');

	    ----------------------------------------------------------------------
            -- Call OD: SFA Lead Referral RSD Wave Validation only if the profile
            -- OD: Use RSD Waves Logic In Lead Referrals is set to Yes.
            ----------------------------------------------------------------------
            
            IF NVL(fnd_profile.value('XX_SFA_LR_USE_RSD_WAVES_LOGIC'),'Y') = 'Y' THEN

                BEGIN
                -------------------------------------------------------------------------
                -- SUBMIT OD: SFA Lead Referral RSD Wave Validation Program
                -------------------------------------------------------------------------

                fnd_file.put_line(fnd_file.LOG,' ');

                fnd_file.put_line(fnd_file.LOG,'Submitting OD: SFA Lead Referral RSD Wave Validation Program');

                fnd_file.put_line(fnd_file.LOG,'------------------------------------------------------------');

                ln_conc_request_id := fnd_request.submit_request(application => 'XXCRM',
                                                                 program => 'XX_SFA_LR_RSD_WAVE_VALIDATE',
                                                                 description => NULL,
                                                                 start_time => NULL,
                                                                 sub_request => false);

                COMMIT;

                IF ln_conc_request_id = 0 THEN
                fnd_file.put_line(fnd_file.LOG,'OD: SFA Lead Referral RSD Wave Validation Program: '
                                             ||SQLERRM);
                ELSE
                fnd_file.put_line(fnd_file.LOG,' ');

                fnd_file.put_line(fnd_file.LOG,'OD: SFA Lead Referral RSD Wave Validation Program: '
                                             ||to_char(ln_conc_request_id));
                END IF;

                lv_phase := NULL;

                lv_status := NULL;

                lv_dev_phase := NULL;

                lv_dev_status := NULL;

                lv_message := NULL;

                lb_wait := fnd_concurrent.wait_for_request(request_id => ln_conc_request_id,
                                                           INTERVAL => 10,
                                                           phase => lv_phase,
                                                           status => lv_status,
                                                           dev_phase => lv_dev_phase,
                                                           dev_status => lv_dev_status,
                                                           message => lv_message);
                EXCEPTION
                    WHEN OTHERS THEN
                      fnd_file.put_line(fnd_file.LOG,'Error while submitting program, OD: SFA Lead Referral RSD Wave Validation Program: '
                                                     ||SQLERRM);
                END;

	    END IF;    
    
	    SELECT COUNT(1)
	      INTO ln_valid_records
              FROM   xxcrm.xx_sfa_lead_referrals
             WHERE  process_status = 'VALIDATED'; 
	
	    ----------------------------------------------------------------------
            ---         Calling Request Set
            ----------------------------------------------------------------------
            
            IF UPPER(NVL(lv_dev_status,'NEW')) <> 'CANCELLED' AND UPPER(NVL(lv_dev_status,'NEW')) <> 'ERROR' AND UPPER(NVL(lv_dev_status,'NEW')) <> 'TERMINATED' THEN

                IF ln_valid_records <> 0 THEN

			fnd_file.put_line(fnd_file.LOG,' ');

			fnd_file.put_line(fnd_file.LOG,'Submitting Request Set OD: SFA Lead Referrals Request Set');

			fnd_file.put_line(fnd_file.LOG,'---------------------------------------------------------');

			xx_sfa_lead_referral_pkg.submit_request_set(x_errbuf,x_retcode,ln_batch_id);

			COMMIT;

			fnd_file.put_line(fnd_file.LOG,'Submitted Request Set');
		  
			------------------------------------------------------------------------
			--                          UPDATE STATUS                             --
			------------------------------------------------------------------------
			    
			FOR lcr_update_status IN lcu_update_status(ln_batch_id)
			LOOP

			IF lcr_update_status.load_status = 'SUCCESS' THEN
			  
			  UPDATE xx_sfa_lead_referrals
			     SET process_status = 'PROCESSED'
			   WHERE internid = REPLACE(lcr_update_status.orig_system_reference,'-00001-'||lc_orig_system,'');

			ELSE
			   
			   lc_lead_error_text := NULL;

			   FOR lcr_lead_error IN lcu_lead_error(lcr_update_status.import_interface_id)
			   LOOP
			   
				lc_lead_error_text := SUBSTR(lc_lead_error_text ||'.'||lcr_lead_error.error_text,1,4000);

			   END LOOP;

			  UPDATE xx_sfa_lead_referrals
			     SET process_status = 'IMPORT_ERROR',
				 error_message = lc_lead_error_text
			   WHERE internid = REPLACE(lcr_update_status.orig_system_reference,'-00001-'||lc_orig_system,'');
	      
			END IF;
			END LOOP;

			COMMIT;
                ELSE
		       IF NVL(fnd_profile.value('XX_SFA_LR_USE_RSD_WAVES_LOGIC'),'Y') = 'Y' THEN

		          fnd_file.put_line(fnd_file.LOG,' ');

			  fnd_file.put_line(fnd_file.LOG,'NOTE: Current program run did not find a lead referral record belonging to converted RSD waves.');
		          fnd_file.put_line(fnd_file.LOG,'      Therefore, No eligible records were found that can be created in Oracle.');
		          fnd_file.put_line(fnd_file.LOG,'      Refer to output of the report program OD: SFA Lead Referral Report for SOLAR.');
		          fnd_file.put_line(fnd_file.LOG,'      These Leads will be created in SOLAR and not in Oracle.');

		          fnd_file.put_line(fnd_file.LOG,' ');

		       END IF;
		       
                END IF;
		    -------------------------------------------------------------------------
                -- SUBMIT OD: SFA Lead Referral Report for SOLAR
                -------------------------------------------------------------------------

                -- Commented by Kishore Jena on 07/29/2009 as report is going to run independently from ESP
                /*
                IF NVL(fnd_profile.value('XX_SFA_LR_USE_RSD_WAVES_LOGIC'),'Y') = 'Y' THEN

                BEGIN

                fnd_file.put_line(fnd_file.LOG,' ');

                fnd_file.put_line(fnd_file.LOG,'Submitting OD: SFA Lead Referral Report for SOLAR');

                fnd_file.put_line(fnd_file.LOG,'-------------------------------------------------');

                ln_conc_request_id := fnd_request.submit_request(application => 'XXCRM',
                                                                 program => 'XX_SFA_LR_REPORT_FOR_SOLAR',
                                                                 description => NULL,
                                                                 start_time => NULL,
                                                                 sub_request => false);

                COMMIT;

                IF ln_conc_request_id = 0 THEN
                fnd_file.put_line(fnd_file.LOG,'OD: SFA Lead Referral Report for SOLAR: '
                                             ||SQLERRM);
                ELSE
                fnd_file.put_line(fnd_file.LOG,' ');

                fnd_file.put_line(fnd_file.LOG,'OD: SFA Lead Referral Report for SOLAR: '
                                             ||to_char(ln_conc_request_id));
                END IF;

                lv_phase := NULL;

                lv_status := NULL;

                lv_dev_phase := NULL;

                lv_dev_status := NULL;

                lv_message := NULL;

                lb_wait := fnd_concurrent.wait_for_request(request_id => ln_conc_request_id,
                                                           INTERVAL => 10,
                                                           phase => lv_phase,
                                                           status => lv_status,
                                                           dev_phase => lv_dev_phase,
                                                           dev_status => lv_dev_status,
                                                           message => lv_message);
                EXCEPTION
                    WHEN OTHERS THEN
                      fnd_file.put_line(fnd_file.LOG,'Error while submitting program, OD: SFA Lead Referral Report for SOLAR: '
                                                     ||SQLERRM);
                END;

                END IF;    
                */
             END IF;
          ELSE
            fnd_file.put_line(fnd_file.LOG,'Note: Since there are no eligible lead records, call to subsequent programs to create leads is skipped!!!');
          END IF;
           
  COMMIT;
  EXCEPTION
    WHEN le_batch_id_error THEN
      ROLLBACK;
      
      fnd_message.set_name('XXCRM','XX_SFA_092_LR_BATCHID_ERR');
      --XX_SFA_003_LEAD_REF_UNKNOWN_ERR := 'Unknown Error';
      
      lc_err_desc := lc_batch_error_msg;
      
      xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                         p_program_type => lc_program_type,p_program_name => lc_program_name,
                                         p_module_name => lc_module_name,p_error_location => lc_error_location,
                                         p_error_message_code => 'XX_SFA_092_LR_BATCHID_ERR',
                                         p_error_message => substr(lc_err_desc,1,4000),
                                         p_error_message_severity => 'MAJOR');
      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      fnd_file.put_line(fnd_file.LOG,'Error while creating Batch ID. '
                                     ||lc_err_desc);
      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      x_retcode := 2;
    WHEN OTHERS THEN
      ROLLBACK;
      
      fnd_message.set_name('XXCRM','XX_SFA_093_LR_UNKNOWN_ERR');
      --XX_SFA_003_LEAD_REF_UNKNOWN_ERR := 'Unknown Error';
      
      lc_err_desc := fnd_message.get;
      
      xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                         p_program_type => lc_program_type,p_program_name => lc_program_name,
                                         p_module_name => lc_module_name,p_error_location => lc_error_location,
                                         p_error_message_code => 'XX_SFA_093_LR_UNKNOWN_ERR',
                                         p_error_message => substr(lc_err_desc
                                                                   ||'=>'
                                                                   ||SQLERRM,1,4000),
                                         p_error_message_severity => 'MAJOR');
      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      fnd_file.put_line(fnd_file.LOG,'An error occured. '
                                     ||substr(lc_err_desc
                                              ||'=>'
                                              ||SQLERRM,1,4000));
      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      x_retcode := 2;
  END validate_data;
  -- +===================================================================+
  -- | Name             : LOAD_PROSPECTS                                 |
  -- | Description      : This procedure load extracted data into common |
  -- |                    view tables to create prospect.                |
  -- |                                                                   |
  -- | Parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- |                   p_batch_id                                      |
  -- +===================================================================+
  
  PROCEDURE load_prospects
       (x_errbuf     OUT NOCOPY VARCHAR2
        ,x_retcode   OUT NOCOPY NUMBER
        ,p_batch_id  IN NUMBER)
  IS
    ln_batch_id             NUMBER;
    ln_created_by           NUMBER;
    lc_orig_system          VARCHAR2(60) := 'LR';
    lc_org_party_type       VARCHAR2(60) := 'ORGANIZATION';
    lc_created_by_module    VARCHAR2(60) := 'LEAD REFERRAL';
    lc_party_desc           VARCHAR2(60) := 'PARTY';
    lc_bill_to_site_use     VARCHAR2(60) := 'BILL_TO';
    lc_ship_to_site_use     VARCHAR2(60) := 'SHIP_TO';
    lc_phone_country_code   VARCHAR2(60) := 1;
    ln_parties_int_cnt      NUMBER := 0;
    ln_ext_attribs_int_cnt  NUMBER := 0;
    ln_addresses_int_cnt    NUMBER := 0;
    ln_addressuses_int_cnt  NUMBER := 0;
    lc_application_name     xx_com_error_log.application_name%TYPE := 'XXCRM';
    lc_program_type         xx_com_error_log.program_type%TYPE := 'I2043_Lead_Referral';
    lc_program_name         xx_com_error_log.program_name%TYPE := 'XX_SFA_LEAD_REFERRAL_PKG';
    lc_module_name          xx_com_error_log.module_name%TYPE := 'SFA';
    lc_error_location       xx_com_error_log.error_location%TYPE := 'LOAD_PROSPECT';
    lc_token                VARCHAR2(4000);
    lc_error_message_code   VARCHAR2(100);
    lc_err_desc             xx_com_error_log.error_message%TYPE DEFAULT ' ';
    le_load_prospect_error  EXCEPTION;
  BEGIN
  ----------------------------------------------------------------------
  ---                Writing LOG FILE                                ---
  ---  Exception if any will be caught in 'WHEN OTHERS'              ---
  ---  with system generated error message.                          ---
  ----------------------------------------------------------------------
  
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,rpad('Office Depot',40,' ')
                                   ||lpad('DATE: ',60,' ')
                                   ||to_date(SYSDATE,'DD-MON-YYYY HH:MI'));
    
    fnd_file.put_line(fnd_file.LOG,lpad('OD: SFA Lead Referral PROSPECTS to CV tables',
                                        69,' '));
    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    ln_batch_id := p_batch_id;
    
    fnd_file.put_line(fnd_file.LOG,'batch_id='
                                   ||ln_batch_id);
    
    BEGIN
      SELECT fnd_global.user_id
      INTO   ln_created_by
      FROM   dual;
    EXCEPTION
      WHEN no_data_found THEN
        ln_created_by := NULL;
    END;
    ----------------------------------------------------------------------
    ---  Load party data into the common view table.                   ---
    ----------------------------------------------------------------------
    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,' Started inserting PARTIES data into the table'
                                   ||' XXOD_HZ_IMP_PARTIES_INT...');
    
    BEGIN
      INSERT INTO xxod_hz_imp_parties_int
                 (batch_id
                  ,party_orig_system
                  ,party_orig_system_reference
                  ,party_type
                  ,created_by_module
                  ,organization_name
                  ,duns_number_c
                  ,attribute10
                  ,attribute13
                  ,attribute24
                  ,created_by
                  ,creation_date
                  ,attribute_category)
      SELECT ln_batch_id
             ,lc_orig_system
             ,internid
              ||'-00001-'
              ||lc_orig_system
             ,lc_org_party_type
             ,lc_created_by_module
             ,NAME
             ,duns_number
             ,num_wc_emp_od
             ,'PROSPECT' AS attribute13
             ,rev_band
             ,ln_created_by
             ,SYSDATE AS creation_date
             ,country
      FROM   xxcrm.xx_sfa_lead_referrals
      WHERE  process_status = 'VALIDATED';
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,' Error while inserting prospect party records in XXOD_HZ_IMP_PARTIES_INT.'
                                       ||SQLERRM);
        
        lc_err_desc := 'Error while inserting prospect party records in xxod_hz_imp_parties_int';
        
        RAISE le_load_prospect_error;
    END;
    
    ln_parties_int_cnt := SQL%ROWCOUNT;
    
    fnd_file.put_line(fnd_file.LOG,' Inserted Count: '
                                   ||ln_parties_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,' Successfully inserted PARTIES data into the table'
                                   ||' XXOD_HZ_IMP_PARTIES_INT...');
    ----------------------------------------------------------------------
    ---  Load party's addresses data into the common view table.       ---
    ----------------------------------------------------------------------
    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,' Started inserting ADDRESSES data into the table'
                                   ||' XXOD_HZ_IMP_ADDRESSES_INT...');
    
    BEGIN
      INSERT INTO xxod_hz_imp_addresses_int
                 (batch_id
                  ,description
                  ,party_orig_system
                  ,party_orig_system_reference
                  ,site_orig_system
                  ,site_orig_system_reference
                  ,created_by_module
                  ,address1
                  ,city
                  ,province
                  ,state
                  ,postal_code
                  ,country
                  ,primary_flag
                  ,created_by
                  ,creation_date)
                 --SHIP TO ADDRESS
      SELECT ln_batch_id
             ,lc_party_desc
             ,lc_orig_system
             ,internid
              ||'-00001-'
              ||lc_orig_system
             ,lc_orig_system
             ,internid
              ||'-00002-'
              ||lc_orig_system
             ,lc_created_by_module
             ,addr1
             ,city
             ,CASE 
                WHEN (country = 'CA') THEN state
                ELSE NULL
              END province
             ,CASE 
                WHEN (country = 'CA') THEN NULL
                ELSE state
              END state
             ,zip
             ,country
             ,'Y'
             ,ln_created_by
             ,SYSDATE AS creation_date
      FROM   xxcrm.xx_sfa_lead_referrals
      WHERE  process_status = 'VALIDATED';
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,' Error while inserting prospect party address record in XXOD_HZ_IMP_ADDRESSES_INT.'
                                       ||SQLERRM);
        
        lc_err_desc := 'Error while inserting prospect party address record in xxod_hz_imp_addresses_int.';
        
        RAISE le_load_prospect_error;
    END;
    
    ln_addresses_int_cnt := SQL%ROWCOUNT;
    
    fnd_file.put_line(fnd_file.LOG,' Inserted Count: '
                                   ||ln_addresses_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,' Successfully inserted ADDRESSSES data into the table'
                                   ||' XXOD_HZ_IMP_ADDRESSES_INT...');
    ----------------------------------------------------------------------
    ---  Load party's address uses into the common view table.         ---
    ----------------------------------------------------------------------
    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,' Started inserting ADDRESSUSES data into the table'
                                   ||' XXOD_HZ_IMP_ADDRESSUSES_INT...');
    
    BEGIN
      INSERT INTO xxod_hz_imp_addressuses_int
                 (batch_id
                  ,party_orig_system
                  ,party_orig_system_reference
                  ,created_by_module
                  ,site_orig_system
                  ,site_orig_system_reference
                  ,primary_flag
                  ,site_use_type
                  ,created_by
                  ,creation_date)
                 --SHIP TO ADDRESS
      SELECT ln_batch_id
             ,lc_orig_system
             ,internid
              ||'-00001-'
              ||lc_orig_system
             ,lc_created_by_module
             ,lc_orig_system
             ,internid
              ||'-00002-'
              ||lc_orig_system
             ,'Y'
             ,lc_ship_to_site_use
             ,ln_created_by
             ,SYSDATE AS creation_date
      FROM   xxcrm.xx_sfa_lead_referrals
      WHERE  process_status = 'VALIDATED';
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,' Error while inserting prospect party address use record in XXOD_HZ_IMP_ADDRESSUSES_INT.'
                                       ||SQLERRM);
        
        lc_err_desc := 'Error while inserting prospect party address use record in XXOD_HZ_IMP_ADDRESSUSES_INT.';
        
        RAISE le_load_prospect_error;
    END;
    
    ln_addressuses_int_cnt := SQL%ROWCOUNT;
    
    fnd_file.put_line(fnd_file.LOG,' Inserted Count: '
                                   ||ln_addressuses_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,' Successfully inserted ADDRESSSUSES data into the table'
                                   ||' XXOD_HZ_IMP_ADDRESSUSES_INT...');
    ----------------------------------------------------------------------
    ---  Load party's extensible addtributes.                          ---
    ----------------------------------------------------------------------
    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,' Started inserting EXTENSIBLE data into the table'
                                   ||' XXOD_HZ_IMP_EXT_ATTRIBS_INT...');
    
    BEGIN
      INSERT INTO xxod_hz_imp_ext_attribs_int
                 (batch_id
                  ,created_by_module
                  ,orig_system
                  ,orig_system_reference
                  ,interface_entity_name
                  ,interface_entity_reference
                  ,attribute_group_code
                  ,n_ext_attr8)
      SELECT ln_batch_id
             ,lc_created_by_module
             ,lc_orig_system AS orig_system
             ,internid
              ||'-00002-'
              ||lc_orig_system AS orig_system_reference
             ,'SITE' AS interface_entity_name
             ,internid
              ||'-00002-'
              ||lc_orig_system AS interface_entity_reference
             ,'SITE_DEMOGRAPHICS' AS attribute_group_code
             ,num_wc_emp_od AS n_ext_attr8
      FROM   xxcrm.xx_sfa_lead_referrals
      WHERE  process_status = 'VALIDATED';
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,' Error while inserting prospect extensible attributes record in XXOD_HZ_IMP_EXT_ATTRIBS_INT.'
                                       ||SQLERRM);
        
        lc_err_desc := 'Error while inserting prospect extensible attributes record in XXOD_HZ_IMP_EXT_ATTRIBS_INT.';
        
        RAISE le_load_prospect_error;
    END;
    
    ln_ext_attribs_int_cnt := SQL%ROWCOUNT;
    
    fnd_file.put_line(fnd_file.LOG,' Inserted Count: '
                                   ||ln_parties_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,' Started inserting EXTENSIBLE data into the table'
                                   ||' XXOD_HZ_IMP_EXT_ATTRIBS_INT...');
    ----------------------------------------------------------------------
    ---         Printing summary report in the LOG file                ---
    ----------------------------------------------------------------------
    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,'Summary report:');
    
    fnd_file.put_line(fnd_file.LOG,'  XXOD_HZ_IMP_PARTIES_INT insert cnt=====>'
                                   ||ln_parties_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,'  XXOD_HZ_IMP_EXT_ATTRIBS_INT insert cnt=>'
                                   ||ln_ext_attribs_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,'  XXOD_HZ_IMP_ADDRESSES_INT insert cnt===>'
                                   ||ln_addresses_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,'  XXOD_HZ_IMP_ADDRESSUSES_INT insert cnt=>'
                                   ||ln_addressuses_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,' ');

  COMMIT;

  EXCEPTION
    WHEN le_load_prospect_error THEN
      ROLLBACK;

      fnd_message.set_name('XXCRM','XX_SFA_093_LR_UNKNOWN_ERR');
      
      lc_err_desc := lc_err_desc
                     ||SQLERRM;
      
      xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                         p_program_type => lc_program_type,p_program_name => lc_program_name,
                                         p_module_name => lc_module_name,p_error_location => lc_error_location,
                                         p_error_message_code => 'XX_SFA_093_LR_UNKNOWN_ERR',
                                         p_error_message => substr(lc_err_desc,1,4000),
                                         p_error_message_severity => 'MAJOR');
      
      fnd_file.put_line(fnd_file.LOG,' ');

      lc_err_desc := substr('Error while loading Prospects into CV.'||lc_err_desc,1,4000);
      
      UPDATE xxcrm.xx_sfa_lead_referrals
      SET    process_status = 'INTERFACE_ERROR'
             ,error_message = lc_err_desc
      WHERE  process_status = 'VALIDATED';

      COMMIT;

      x_retcode := 2;
    WHEN OTHERS THEN
      ROLLBACK;
      
      fnd_message.set_name('XXCRM','XX_SFA_093_LR_UNKNOWN_ERR');
      --XX_SFA_003_LEAD_REF_UNKNOWN_ERR := 'Unknown Error';
      
      lc_err_desc := fnd_message.get;
      
      xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                         p_program_type => lc_program_type,p_program_name => lc_program_name,
                                         p_module_name => lc_module_name,p_error_location => lc_error_location,
                                         p_error_message_code => 'XX_SFA_093_LR_UNKNOWN_ERR',
                                         p_error_message => substr(lc_err_desc
                                                                   ||'=>'
                                                                   ||SQLERRM,1,4000),
                                         p_error_message_severity => 'MAJOR');
      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      fnd_file.put_line(fnd_file.LOG,'An error occured. '
                                     ||substr(lc_err_desc
                                              ||'=>'
                                              ||SQLERRM,1,4000));
      
      fnd_file.put_line(fnd_file.LOG,' ');

      lc_err_desc := substr(('Error while loading Prospects into CV.'||lc_err_desc||'.'||SQLERRM),1,4000);
      
      UPDATE xxcrm.xx_sfa_lead_referrals
      SET    process_status = 'INTERFACE_ERROR'
             ,error_message = lc_err_desc
      WHERE  process_status = 'VALIDATED';

      COMMIT;

      x_retcode := 2;
  END load_prospects;
  -- +===================================================================+
  -- | Name             : LOAD_CONTACTS                                  |
  -- | Description      : This procedure load extracted data into common |
  -- |                    view tables to create contacts.                |
  -- |                                                                   |
  -- | Parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- |                   p_batch_id                                      |
  -- +===================================================================+
  
  PROCEDURE load_contacts
       (x_errbuf     OUT NOCOPY VARCHAR2
        ,x_retcode   OUT NOCOPY NUMBER
        ,p_batch_id  IN NUMBER)
  IS
    ln_batch_id             NUMBER;
    ln_created_by           NUMBER;
    lc_orig_system          VARCHAR2(60) := 'LR';
    lc_person_party_type    VARCHAR2(60) := 'PERSON';
    lc_created_by_module    VARCHAR2(60) := 'LEAD REFERRAL';
    lc_phone_country_code   VARCHAR2(60) := 1;
    ln_parties_int_cnt      NUMBER := 0;
    ln_ext_attribs_int_cnt  NUMBER := 0;
    ln_addressuses_int_cnt  NUMBER := 0;
    ln_contactpts_int_cnt   NUMBER := 0;
    ln_contacts_int_cnt     NUMBER := 0;
    lc_application_name     xx_com_error_log.application_name%TYPE := 'XXCRM';
    lc_program_type         xx_com_error_log.program_type%TYPE := 'I2043_Lead_Referral';
    lc_program_name         xx_com_error_log.program_name%TYPE := 'XX_SFA_LEAD_REFERRAL_PKG';
    lc_module_name          xx_com_error_log.module_name%TYPE := 'SFA';
    lc_error_location       xx_com_error_log.error_location%TYPE := 'LOAD_CONTACT';
    lc_token                VARCHAR2(4000);
    lc_error_message_code   VARCHAR2(100);
    lc_err_desc             xx_com_error_log.error_message%TYPE DEFAULT ' ';
    le_load_contact_error   EXCEPTION;
  BEGIN
  ----------------------------------------------------------------------
  ---                Writing LOG FILE                                ---
  ---  Exception if any will be caught in 'WHEN OTHERS'              ---
  ---  with system generated error message.                          ---
  ----------------------------------------------------------------------
  
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,rpad('Office Depot',40,' ')
                                   ||lpad('DATE: ',60,' ')
                                   ||to_date(SYSDATE,'DD-MON-YYYY HH:MI'));
    
    fnd_file.put_line(fnd_file.LOG,lpad('OD: SFA Lead Referral load CONTACTS to CV tables',
                                        69,' '));
    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    ln_batch_id := p_batch_id;
    
    fnd_file.put_line(fnd_file.LOG,'batch_id='
                                   ||ln_batch_id);
    
    SELECT fnd_global.user_id
    INTO   ln_created_by
    FROM   dual;
    ----------------------------------------------------------------------
    ---  Load party data into the common view table.                   ---
    ----------------------------------------------------------------------
    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,' Started inserting PARTIES data into the table'
                                   ||' XXOD_HZ_IMP_PARTIES_INT...');
    
    BEGIN
      INSERT INTO xxod_hz_imp_parties_int
                 (batch_id
                  ,party_orig_system
                  ,party_orig_system_reference
                  ,party_type
                  ,created_by_module
                  ,person_first_name
                  ,person_last_name
                  ,person_title
                  ,created_by
                  ,creation_date)
      SELECT ln_batch_id
             ,lc_orig_system AS party_orig_system
             ,internid
              ||'-CONTACT' AS party_orig_system_reference
             ,lc_person_party_type AS party_type
             ,lc_created_by_module
             ,fname
             ,lname
             ,contact_title
             ,ln_created_by
             ,SYSDATE AS creation_date
      FROM   xxcrm.xx_sfa_lead_referrals
      WHERE  process_status = 'VALIDATED';
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,' Error while inserting contact party record in XXOD_HZ_IMP_PARTIES_INT.'
                                       ||SQLERRM);
        
        lc_err_desc := 'Error while inserting contact party record in XXOD_HZ_IMP_PARTIES_INT.';
        
        RAISE le_load_contact_error;
    END;
    
    ln_parties_int_cnt := SQL%ROWCOUNT;
    
    fnd_file.put_line(fnd_file.LOG,' Inserted Count: '
                                   ||ln_parties_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,' Successfully inserted PARTIES data into the table'
                                   ||' XXOD_HZ_IMP_PARTIES_INT...');
    ----------------------------------------------------------------------
    ---  Load contact relationship data into the common view table.    ---
    ----------------------------------------------------------------------
    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,' Started inserting CONTACTS data into the table'
                                   ||' XXOD_HZ_IMP_CONTACTS_INT...');
    
    BEGIN
      INSERT INTO xxod_hz_imp_contacts_int
                 (batch_id
                  ,contact_orig_system
                  ,contact_orig_system_reference
                  ,sub_orig_system
                  ,sub_orig_system_reference
                  ,obj_orig_system
                  ,obj_orig_system_reference
                  ,relationship_type
                  ,relationship_code
                  ,start_date
                  ,created_by_module
                  ,created_by
                  ,creation_date)
      SELECT ln_batch_id
             ,lc_orig_system AS contact_orig_system
             ,internid
              ||'-CONTACT' AS contact_orig_system_reference
             ,lc_orig_system AS sub_orig_system
             ,internid
              ||'-CONTACT' AS sub_orig_system_referernce
             ,lc_orig_system AS obj_orig_system
             ,internid
              ||'-00001-'
              ||lc_orig_system AS obj_orig_system_reference
             ,'CONTACT' AS relationship_type
             ,'CONTACT_OF' AS relationship_code
             ,SYSDATE
             ,lc_created_by_module
             ,ln_created_by
             ,SYSDATE AS creation_date
      FROM   xxcrm.xx_sfa_lead_referrals
      WHERE  process_status = 'VALIDATED';
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,' Error while inserting contact record in XXOD_HZ_IMP_CONTACTS_INT.'
                                       ||SQLERRM);
        
        lc_err_desc := 'Error while inserting contact record in XXOD_HZ_IMP_CONTACTS_INT.';
        
        RAISE le_load_contact_error;
    END;
    
    ln_contacts_int_cnt := SQL%ROWCOUNT;
    
    fnd_file.put_line(fnd_file.LOG,' Inserted Count: '
                                   ||ln_contacts_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,' Successfully inserted CONTACTS data into the table'
                                   ||' XXOD_HZ_IMP_CONTACTS_INT...');
    ----------------------------------------------------------------------
    ---  Load contact point data into the common view table.           ---
    ----------------------------------------------------------------------
    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,' Started inserting CONTACTPTS data into the table'
                                   ||' XXOD_HZ_IMP_CONTACTPTS_INT...');
    
    BEGIN
      INSERT INTO xxod_hz_imp_contactpts_int
                 (batch_id
                  ,created_by_module
                  ,party_orig_system
                  ,party_orig_system_reference
                  ,cp_orig_system
                  ,cp_orig_system_reference
                  ,contact_point_type
                  ,raw_phone_number
                  ,phone_line_type
                  ,phone_country_code
                  ,rel_flag
                  ,primary_flag
                  ,created_by
                  ,creation_date)
      SELECT ln_batch_id
             ,lc_created_by_module
             ,lc_orig_system AS party_orig_system
             ,internid
              ||'-CONTACT' AS party_orig_system_reference
             ,lc_orig_system AS cp_orig_system
             ,internid
              ||'-CONTACT'
              ||'-GEN' AS cp_orig_system_reference
             ,'PHONE' AS contact_point_type
             ,phone AS raw_phone_number
             ,'GEN' AS phone_line_type
             ,lc_phone_country_code
             ,'Y'
             ,'Y'
             ,ln_created_by
             ,SYSDATE AS creation_date
      FROM   xxcrm.xx_sfa_lead_referrals
      WHERE  process_status = 'VALIDATED';
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,' Error while inserting contact point record in XXOD_HZ_IMP_CONTACTPTS_INT.'
                                       ||SQLERRM);
        
        lc_err_desc := 'Error while inserting contact point record in XXOD_HZ_IMP_CONTACTPTS_INT.';
        
        RAISE le_load_contact_error;
    END;
    
    ln_contactpts_int_cnt := SQL%ROWCOUNT;
    
    fnd_file.put_line(fnd_file.LOG,' Inserted Count: '
                                   ||ln_contactpts_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,' Successfully inserted CONTACTPTS data into the table'
                                   ||' XXOD_HZ_IMP_CONTACTPTS_INT...');
    ----------------------------------------------------------------------
    ---  Load contact extensible attribute into the common view table. ---
    ----------------------------------------------------------------------
    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,' Started inserting extensible attributes data into the table'
                                   ||' XXOD_HZ_IMP_EXT_ATTRIBS_INT...');
    
    BEGIN
      INSERT INTO xxod_hz_imp_ext_attribs_int
                 (batch_id
                  ,created_by
                  ,created_by_module
                  ,creation_date
                  ,orig_system
                  ,orig_system_reference
                  ,interface_entity_name
                  ,interface_entity_reference
                  ,attribute_group_code
                  ,c_ext_attr1
                  ,c_ext_attr19
                  ,c_ext_attr20
                  ,d_ext_attr1)
      SELECT ln_batch_id
             ,ln_created_by
             ,lc_created_by_module
             ,SYSDATE AS creation_date
             ,lc_orig_system AS orig_system
             ,internid
              ||'-00002-'
              ||lc_orig_system AS orig_system_reference
             ,'SITE' AS interface_entity_name
             ,internid
              ||'-00002-'
              ||lc_orig_system AS interface_entity_reference
             ,'SITE_CONTACTS' AS attribute_group_code
             ,'A' AS c_ext_attr1
             ,lc_orig_system AS c_ext_attr19
             ,internid
              ||'-CONTACT' AS c_ext_attr20
             ,SYSDATE AS d_ext_attr1
      FROM   xxcrm.xx_sfa_lead_referrals
      WHERE  process_status = 'VALIDATED';
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,' Error while inserting contact extensible attributes record in XXOD_HZ_IMP_EXT_ATTRIBS_INT.'
                                       ||SQLERRM);
        
        lc_err_desc := 'Error while inserting contact extensible attributes record in XXOD_HZ_IMP_EXT_ATTRIBS_INT.';
        
        RAISE le_load_contact_error;
    END;
    
    ln_ext_attribs_int_cnt := SQL%ROWCOUNT;
    
    fnd_file.put_line(fnd_file.LOG,' Inserted Count: '
                                   ||ln_ext_attribs_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,' Successfully inserted extensible attributes data into the table'
                                   ||' XXOD_HZ_IMP_EXT_ATTRIBS_INT...');
    
    ----------------------------------------------------------------------
    ---         Printing summary report in the LOG file                ---
    ----------------------------------------------------------------------
    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,'Summary report:');
    
    fnd_file.put_line(fnd_file.LOG,'  XXOD_HZ_IMP_PARTIES_INT insert cnt=====>'
                                   ||ln_parties_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,'  XXOD_HZ_IMP_CONTACTS_INT insert cnt====>'
                                   ||ln_contacts_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,'  XXOD_HZ_IMP_CONTACTPTS_INT insert cnt==>'
                                   ||ln_contactpts_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,'  XXOD_HZ_IMP_EXT_ATTRIBS_INT insert cnt==>'
                                   ||ln_ext_attribs_int_cnt);
    
    fnd_file.put_line(fnd_file.LOG,' ');

  COMMIT;

  EXCEPTION
    WHEN le_load_contact_error THEN
      ROLLBACK;
      
      fnd_message.set_name('XXCRM','XX_SFA_093_LR_UNKNOWN_ERR');
      
      lc_err_desc := lc_err_desc
                     ||SQLERRM;
      
      xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                         p_program_type => lc_program_type,p_program_name => lc_program_name,
                                         p_module_name => lc_module_name,p_error_location => lc_error_location,
                                         p_error_message_code => 'XX_SFA_093_LR_UNKNOWN_ERR',
                                         p_error_message => substr(lc_err_desc,1,4000),
                                         p_error_message_severity => 'MAJOR');
      
      fnd_file.put_line(fnd_file.LOG,' ');

      lc_err_desc := substr('Error while loading Contacts into CV.'||lc_err_desc,1,4000);

      UPDATE xxcrm.xx_sfa_lead_referrals
      SET    process_status = 'INTERFACE_ERROR'
             ,error_message = lc_err_desc
      WHERE  process_status = 'VALIDATED';

      COMMIT;

      x_retcode := 2;
    WHEN OTHERS THEN
      ROLLBACK;
      
      fnd_message.set_name('XXCRM','XX_SFA_093_LR_UNKNOWN_ERR');
      --XX_SFA_003_LEAD_REF_UNKNOWN_ERR := 'Unknown Error';
      
      lc_err_desc := fnd_message.get;
      
      xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                         p_program_type => lc_program_type,p_program_name => lc_program_name,
                                         p_module_name => lc_module_name,p_error_location => lc_error_location,
                                         p_error_message_code => 'XX_SFA_093_LR_UNKNOWN_ERR',
                                         p_error_message => substr(lc_err_desc
                                                                   ||'=>'
                                                                   ||SQLERRM,1,4000),
                                         p_error_message_severity => 'MAJOR');
      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      fnd_file.put_line(fnd_file.LOG,'An error occured. '
                                     ||substr(lc_err_desc
                                              ||'=>'
                                              ||SQLERRM,1,4000));
      
      fnd_file.put_line(fnd_file.LOG,' ');

      lc_err_desc := substr(('Error while loading Contacts into CV.'||lc_err_desc||'.'||SQLERRM),1,4000);
      
      UPDATE xxcrm.xx_sfa_lead_referrals
      SET    process_status = 'INTERFACE_ERROR'
             ,error_message = lc_err_desc
      WHERE  process_status = 'VALIDATED';

      COMMIT;
      
      x_retcode := 2;
  END load_contacts;
  -- +===================================================================+
  -- | Name             : LOAD_LEADS                                     |
  -- | Description      : This procedure load extracted data into        |
  -- |                    interface tables to create Leads.              |
  -- |                                                                   |
  -- | Parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- |                   p_batch_id                                      |
  -- +===================================================================+
  
  PROCEDURE load_leads
       (x_errbuf     OUT NOCOPY VARCHAR2
        ,x_retcode   OUT NOCOPY NUMBER
        ,p_batch_id  IN NUMBER)
  IS
    ln_batch_id                NUMBER;
    ln_created_by              NUMBER;
    lc_orig_system             VARCHAR2(60) := 'LR';
    lc_source_system           VARCHAR2(60) := 'LEAD REFERRAL';
    lc_created_by_module       VARCHAR2(60) := 'LEAD REFERRAL';
    lc_phone_country_code      VARCHAR2(60) := 1;
    ln_category_id             NUMBER;
    ln_import_interface_id     NUMBER;
    ln_imp_lines_interface_id  NUMBER;
    lc_application_name        xx_com_error_log.application_name%TYPE := 'XXCRM';
    lc_program_type            xx_com_error_log.program_type%TYPE := 'I2043_Lead_Referral';
    lc_program_name            xx_com_error_log.program_name%TYPE := 'XX_SFA_LEAD_REFERRAL_PKG';
    lc_module_name             xx_com_error_log.module_name%TYPE := 'SFA';
    lc_error_location          xx_com_error_log.error_location%TYPE := 'LOAD_LEADS';
    lc_token                   VARCHAR2(4000);
    lc_error_message_code      VARCHAR2(100);
    lc_err_desc                xx_com_error_log.error_message%TYPE DEFAULT ' ';
    exp_supp_cat               EXCEPTION;
    lc_channel_code            VARCHAR2(100);
    lc_source_promotion_id     NUMBER;
    le_load_lead_error         EXCEPTION;
    ln_lead_count              NUMBER := 0;
    
    CURSOR lcu_lead_ref IS 
      SELECT *
      FROM   xxcrm.xx_sfa_lead_referrals
      WHERE  process_status = 'VALIDATED';
  BEGIN
  ----------------------------------------------------------------------
  ---                Writing LOG FILE                                ---
  ---  Exception if any will be caught in 'WHEN OTHERS'              ---
  ---  with system generated error message.                          ---
  ----------------------------------------------------------------------
  
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,rpad('Office Depot',40,' ')
                                   ||lpad('DATE: ',60,' ')
                                   ||to_date(SYSDATE,'DD-MON-YYYY HH:MI'));
    
    fnd_file.put_line(fnd_file.LOG,lpad('OD: SFA Lead Referral load LEADS to CV tables',
                                        69,' '));
    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    ln_batch_id := p_batch_id;
    
    fnd_file.put_line(fnd_file.LOG,'batch_id='
                                   ||ln_batch_id);
    
    SELECT fnd_global.user_id
    INTO   ln_created_by
    FROM   dual;
    ----------------------------------------------------------------------
    ---  Load Lead data into the interface table.                      ---
    ----------------------------------------------------------------------
    
    BEGIN
      SELECT mcv.category_id
      INTO   ln_category_id
      FROM   mtl_categories_vl mcv
      WHERE  UPPER(mcv.description) = 'SUPPLIES'
             AND mcv.enabled_flag = 'Y'
             AND ROWNUM = 1;
    EXCEPTION
      WHEN no_data_found THEN
        RAISE exp_supp_cat;
    END;
    
    BEGIN
      SELECT lookup_code
      INTO   lc_channel_code
      FROM   fnd_lookup_values
      WHERE  lookup_type = 'SALES_CHANNEL'
             AND UPPER(meaning) = 'UNASSIGNED';
    EXCEPTION
      WHEN no_data_found THEN
        lc_channel_code := '';
    END;
    
    FOR lcr_lead_ref IN lcu_lead_ref LOOP
      BEGIN
        SELECT as_import_interface_s.nextval
               ,as_imp_lines_interface_s.nextval
        INTO   ln_import_interface_id
               ,ln_imp_lines_interface_id
        FROM   dual;

        ----------------------------------------------------------------------
        ---  Finding Source Promotion ID.                                  ---
        ----------------------------------------------------------------------
        
        BEGIN
          SELECT campaign_id
          INTO   lc_source_promotion_id
          FROM   ams_source_codes ascc
                 ,ams_campaigns_v acv
          WHERE  ascc.source_code_id = acv.campaign_id
                 AND LTRIM(RTRIM(UPPER(REPLACE(campaign_name,' ','')))) = LTRIM(RTRIM(UPPER(REPLACE(lcr_lead_ref.source,' ',''))))
                 AND acv.status_code = 'ACTIVE'
                 AND TRUNC(SYSDATE) BETWEEN acv.actual_exec_start_date
                                            AND acv.actual_exec_end_date
                 AND ROWNUM = 1;
        EXCEPTION
          WHEN no_data_found THEN
            lc_source_promotion_id := NULL;
        END;
        ----------------------------------------------------------------------
        ---  Load Lead data into the interface table.                      ---
        ----------------------------------------------------------------------
        
        BEGIN
          INSERT INTO as_import_interface
                     (batch_id
                      ,import_interface_id
                      ,orig_system_code
                      ,orig_system_reference
                      ,source_system
                      ,creation_date
                      ,last_update_date
                      ,load_status
                      ,status_code
                      ,created_by
                      ,last_updated_by
                      ,load_date
                      ,description
                      ,promotion_id
                      ,channel_code)
          VALUES     (ln_batch_id
                      ,ln_import_interface_id
                      ,lc_orig_system
                      ,lcr_lead_ref.internid
                       ||'-00001-'
                       ||lc_orig_system
                      ,lc_source_system
                      ,SYSDATE
                      ,SYSDATE
                      ,'STAGED'
                      ,'NEW'
                      ,ln_created_by
                      ,ln_created_by
                      ,SYSDATE
                      ,lcr_lead_ref.NAME
                       ||' SUPPLIES'
                      ,lc_source_promotion_id
                      ,lc_channel_code);
 
        ln_lead_count := ln_lead_count +1;
        
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.LOG,' Error while inserting Lead records in AS_IMPORT_INTERFACE.'
                                           ||SQLERRM);
            
            lc_err_desc := 'Error while inserting Lead records in AS_IMPORT_INTERFACE.';
            
            RAISE le_load_lead_error;
        END;
        ----------------------------------------------------------------------
        ---  Load Lead line data into the interface table.                 ---
        ----------------------------------------------------------------------
        
        BEGIN
          INSERT INTO as_imp_lines_interface
                     (imp_lines_interface_id
                      ,import_interface_id
                      ,last_update_date
                      ,last_updated_by
                      ,creation_date
                      ,created_by
                      ,category_id)
          VALUES     (ln_imp_lines_interface_id
                      ,ln_import_interface_id
                      ,SYSDATE
                      ,ln_created_by
                      ,SYSDATE
                      ,ln_created_by
                      ,ln_category_id);
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.LOG,' Error while inserting Lead lines in AS_IMP_LINES_INTERFACE.'
                                           ||SQLERRM);
            
            lc_err_desc := 'Error while inserting Lead lines in AS_IMP_LINES_INTERFACE.';
            
            RAISE le_load_lead_error;
        END;
        ----------------------------------------------------------------------
        ---  Load Lead OSR into the custom osr table.                      ---
        ----------------------------------------------------------------------
        
        BEGIN
          INSERT INTO xx_as_lead_imp_osr_stg
                     (import_interface_id
                      ,party_orig_system
                      ,party_orig_system_reference
                      ,pty_site_orig_system
                      ,pty_site_orig_system_reference
                      ,contact_orig_system
                      ,contact_orig_system_reference
                      ,cnt_pnt_orig_system
                      ,cnt_pnt_orig_system_reference
                      ,created_by
                      ,creation_date)
          VALUES     (ln_import_interface_id
                      ,lc_orig_system
                      ,lcr_lead_ref.internid
                       ||'-00001-'
                       ||lc_orig_system
                      ,lc_orig_system
                      ,lcr_lead_ref.internid
                       ||'-00002-'
                       ||lc_orig_system
                      ,lc_orig_system
                      ,lcr_lead_ref.internid
                       ||'-CONTACT'
                      ,lc_orig_system
                      ,lcr_lead_ref.internid
                       ||'-CONTACT'
                       ||'-GEN'
                      ,ln_created_by
                      ,SYSDATE);
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.LOG,' Error while inserting Lead OSR in XX_AS_LEAD_IMP_OSR_STG.'
                                           ||SQLERRM);
            
            lc_err_desc := 'Error while inserting Lead OSR in XX_AS_LEAD_IMP_OSR_STG.';
            
            RAISE le_load_lead_error;
        END;
        ----------------------------------------------------------------------
        ---  Update Process Flag = 'Y' if has been processed Successfully  ---
        ----------------------------------------------------------------------
        
        BEGIN
          UPDATE xxcrm.xx_sfa_lead_referrals
          SET    process_status = 'INTERFACED'
          WHERE  internid = lcr_lead_ref.internid;
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.LOG,' Error while updating status in XX_SFA_LEAD_REFERRALS.'
                                           ||SQLERRM);
            
            lc_err_desc := 'Error while updating status in XX_SFA_LEAD_REFERRALS.';
            
            RAISE le_load_lead_error;
        END;
        
        COMMIT;
      EXCEPTION
        WHEN le_load_lead_error THEN
          ROLLBACK;
          
          fnd_message.set_name('XXCRM','XX_SFA_093_LR_UNKNOWN_ERR');
          
          lc_err_desc := lc_err_desc
                         ||SQLERRM;
          
          xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                             p_program_type => lc_program_type,p_program_name => lc_program_name,
                                             p_module_name => lc_module_name,p_error_location => lc_error_location,
                                             p_error_message_code => 'XX_SFA_093_LR_UNKNOWN_ERR',
                                             p_error_message => substr(lc_err_desc,1,4000),
                                             p_error_message_severity => 'MAJOR');
          
          fnd_file.put_line(fnd_file.LOG,' ');
          
          UPDATE xxcrm.xx_sfa_lead_referrals
          SET    process_status = 'INTERFACE_ERROR'
                ,error_message = substr(lc_err_desc,1,4000)
           WHERE  internid = lcr_lead_ref.internid;

          COMMIT;
        
	  x_retcode := 1;
        
	WHEN OTHERS THEN
          fnd_message.set_name('XXCRM','XX_SFA_093_LR_UNKNOWN_ERR');
          --XX_SFA_003_LEAD_REF_UNKNOWN_ERR := 'Unknown Error';
          
          lc_err_desc := fnd_message.get;
          
          xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                             p_program_type => lc_program_type,p_program_name => lc_program_name,
                                             p_module_name => lc_module_name,p_error_location => lc_error_location,
                                             p_error_message_code => 'XX_SFA_093_LR_UNKNOWN_ERR',
                                             p_error_message => substr(lc_err_desc
                                                                       ||'=>'
                                                                       ||SQLERRM,1,4000),
                                             p_error_message_severity => 'MAJOR');
          
          fnd_file.put_line(fnd_file.LOG,' ');
          
          fnd_file.put_line(fnd_file.LOG,'An error occured. '
                                         ||substr(lc_err_desc
                                                  ||'=>'
                                                  ||SQLERRM,1,4000));
          
          fnd_file.put_line(fnd_file.LOG,' ');

          UPDATE xxcrm.xx_sfa_lead_referrals
          SET    process_status = 'INTERFACE_ERROR'
                ,error_message = substr(lc_err_desc,1,4000)
           WHERE  internid = lcr_lead_ref.internid;

          COMMIT;
          
	  x_retcode := 1;

      END;
    END LOOP;
    
    COMMIT;
    ----------------------------------------------------------------------
    ---         Printing summary report in the LOG file                ---
    ----------------------------------------------------------------------
    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,'Summary report:');
    
    fnd_file.put_line(fnd_file.LOG,'  No of Records Inserted into Leads Interface Table=====>'
                                   ||ln_lead_count);
    
    fnd_file.put_line(fnd_file.LOG,' ');

  EXCEPTION
    WHEN exp_supp_cat THEN
      ROLLBACK;
      
      fnd_message.set_name('XXCRM','XX_SFA_0100_NO_SUPP_CAT');
      --XX_SFA_003_LEAD_REF_UNKNOWN_ERR := 'Unknown Error';
      
      lc_err_desc := fnd_message.get;
      
      xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                         p_program_type => lc_program_type,p_program_name => lc_program_name,
                                         p_module_name => lc_module_name,p_error_location => lc_error_location,
                                         p_error_message_code => 'XX_SFA_0100_NO_SUPP_CAT',
                                         p_error_message => substr(lc_err_desc
                                                                   ||'=>'
                                                                   ||SQLERRM,1,4000),
                                         p_error_message_severity => 'MAJOR');
      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      fnd_file.put_line(fnd_file.LOG,'An error occured. '
                                     ||substr(lc_err_desc
                                              ||'=>'
                                              ||SQLERRM,1,4000));
      
      fnd_file.put_line(fnd_file.LOG,' ');

      lc_err_desc := substr((lc_err_desc||'.'||SQLERRM),1,4000);
      
      UPDATE xxcrm.xx_sfa_lead_referrals
      SET    process_status = 'INTERFACE_ERROR'
            ,error_message = lc_err_desc
      WHERE  process_status = 'VALIDATED';

      COMMIT;

      x_retcode := 2;
    WHEN OTHERS THEN
      ROLLBACK;
      
      fnd_message.set_name('XXCRM','XX_SFA_093_LR_UNKNOWN_ERR');
      --XX_SFA_003_LEAD_REF_UNKNOWN_ERR := 'Unknown Error';
      
      lc_err_desc := fnd_message.get;
      
      xx_com_error_log_pub.log_error_crm(p_application_name => lc_application_name,
                                         p_program_type => lc_program_type,p_program_name => lc_program_name,
                                         p_module_name => lc_module_name,p_error_location => lc_error_location,
                                         p_error_message_code => 'XX_SFA_093_LR_UNKNOWN_ERR',
                                         p_error_message => substr(lc_err_desc
                                                                   ||'=>'
                                                                   ||SQLERRM,1,4000),
                                         p_error_message_severity => 'MAJOR');
      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      fnd_file.put_line(fnd_file.LOG,'An error occured. '
                                     ||substr(lc_err_desc
                                              ||'=>'
                                              ||SQLERRM,1,4000));
      
      fnd_file.put_line(fnd_file.LOG,' ');

      lc_err_desc := substr((lc_err_desc||'.'||SQLERRM),1,4000);
      
      UPDATE xxcrm.xx_sfa_lead_referrals
      SET    process_status = 'INTERFACE_ERROR'
            ,error_message = lc_err_desc
      WHERE  process_status = 'VALIDATED';

      COMMIT;

      x_retcode := 2;
  END load_leads;

  -- +===================================================================+
  -- | Name             : SUBMIT_REQUEST_SET                             |
  -- | Description      : This procedure calls request set that contains |
  -- |                    program to load prospect, contact and leads    |
  -- |                    into oracle base tables.                       |
  -- |                                                                   |
  -- | Parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- |                   p_batch_id                                      |
  -- +===================================================================+
  
  PROCEDURE submit_request_set
       (x_errbuf     OUT NOCOPY VARCHAR2
        ,x_retcode   OUT NOCOPY NUMBER
        ,p_batch_id  IN NUMBER
        )
  IS
    le_skip_procedure         EXCEPTION;
    le_submit_failed          EXCEPTION;
    lb_success                BOOLEAN;
    ln_req_id                 NUMBER;
    lv_phase                  VARCHAR2(50);
    lv_status                 VARCHAR2(50);
    lv_dev_phase              VARCHAR2(15);
    lv_dev_status             VARCHAR2(15);
    lb_wait                   BOOLEAN;
    lv_message                VARCHAR2(4000);
    lc_max_tolerance          VARCHAR2(60) := '50';
    lc_submit_owb_yn          VARCHAR2(60) := 'Y';
    lc_submit_bulk_load       VARCHAR2(60) := 'Y';
    lc_imp_run_option         VARCHAR2(60) := 'COMPLETE';
    lc_run_batch_dedup        VARCHAR2(60) := 'N';
    lc_batch_dedup_rule       VARCHAR2(60) := NULL;
    lc_action_dup             VARCHAR2(60) := NULL;
    lc_run_add_val            VARCHAR2(60) := 'N';
    lc_run_reg_dedup          VARCHAR2(60) := 'N';
    lc_reg_dedup_rule         VARCHAR2(60) := NULL;
    lc_gen_fuzzy_key          VARCHAR2(60) := 'N';
    lc_process_extn_upd_yn    VARCHAR2(60) := 'Y';
    lc_process_contact_pt_yn  VARCHAR2(60) := 'Y';
    lc_process_extn_attr_yn   VARCHAR2(60) := 'Y';
    ln_party_site_cnt         NUMBER := 0;
    ln_from_party_site_id     NUMBER;
    ln_to_party_site_id       NUMBER;
    ln_prev_party_site_id     NUMBER;
    ln_start_party_site_id    NUMBER;
    ln_max_party_site_id      NUMBER;

    ln_sales_lead_cnt         NUMBER := 0;
    ln_from_sales_lead_id     NUMBER;
    ln_to_sales_lead_id       NUMBER;
    ln_prev_sales_lead_id     NUMBER;
    ln_start_sales_lead_id    NUMBER;
    ln_max_sales_lead_id      NUMBER;

    ln_nam_terr_id            xx_tm_nam_terr_defn.named_acct_terr_id%TYPE;
    ln_resource_id            jtf_rs_resource_extns.resource_id%TYPE;
    ln_role_id                jtf_rs_roles_b.role_id%TYPE;
    ln_group_id               jtf_rs_groups_b.group_id%TYPE;
    lc_full_access_flag       xx_tm_nam_terr_entity_dtls.full_access_flag%TYPE;
    lc_return_status          VARCHAR2(100);
    lc_message_data           VARCHAR2(1000);
    lc_error_message          VARCHAR2(1000);
    lc_terr_asgnmnt_source    VARCHAR2(200);
    EX_PARTY_SITE_ERROR       EXCEPTION;

    CURSOR lcu_party_site_range IS 
      SELECT party_site_id
      FROM   apps.xxod_hz_imp_addresses_int hiai
             ,apps.hz_party_sites hosr
      WHERE  hiai.site_orig_system_reference = hosr.orig_system_reference
             AND hiai.batch_id = p_batch_id
      ORDER BY  party_site_id;


      CURSOR lcu_sales_lead_range IS 
      SELECT sales_lead_id
      FROM   apps.as_import_interface
      WHERE  batch_id = p_batch_id
        AND  sales_lead_id is NOT NULL
      ORDER BY  sales_lead_id;

  
  BEGIN
  
    ----------------------------------------------------------------------------
    -- Set the context for the request set OD: SFA Lead Referrals Request Set --
    ----------------------------------------------------------------------------
    
    lb_success := fnd_submit.set_request_set('XXCRM','XX_SFA_LR_SET');
    
    IF (lb_success) THEN
      ----------------------------------------------------------------------------------
      -- Submit program OD: SFA Lead Referral Prospect to CV Process; stage STAGE10
      ----------------------------------------------------------------------------------
      
      lb_success := fnd_submit.submit_program(application => 'XXCRM',program => 'XX_SFA_LR_PROSPECT_CV',
                                              stage => 'XX_SFA_LR_LOAD_CV_INTF',argument1 => p_batch_id);
      
      IF (NOT lb_success) THEN
        RAISE le_submit_failed;
      END IF;
      ----------------------------------------------------------------------------------
      -- Submit program OD: SFA Lead Referral Contacts to CV Process; stage STAGE10
      ----------------------------------------------------------------------------------
      
      lb_success := fnd_submit.submit_program(application => 'XXCRM',program => 'XX_SFA_LR_CONTACTS_CV',
                                              stage => 'XX_SFA_LR_LOAD_CV_INTF',argument1 => p_batch_id);
      
      IF (NOT lb_success) THEN
        RAISE le_submit_failed;
      END IF;
      ----------------------------------------------------------------------------------
      -- Submit program OD: SFA Lead Referral Leads to Interface Process; stage STAGE10
      ----------------------------------------------------------------------------------
      
      lb_success := fnd_submit.submit_program(application => 'XXCRM',program => 'XX_SFA_LR_LEADS_INTF',
                                              stage => 'XX_SFA_LR_LOAD_CV_INTF',argument1 => p_batch_id);
      
      IF (NOT lb_success) THEN
        RAISE le_submit_failed;
      END IF;
      ----------------------------------------------------------------------------------
      -- Submit program OD: SFA Load Common View and Interface Tables; stage STAGE20
      ----------------------------------------------------------------------------------
      
      lb_success := fnd_submit.submit_program
                           (  application => 'XXCNV',
                              program     => 'XX_CDH_CONV_LOAD_INT_STG_PKG',
                              stage       => 'XX_CDH_OWB_CVSTG',
                              argument1   => p_batch_id
                           );											  
      
      IF (NOT lb_success) THEN
        RAISE le_submit_failed;
      END IF;
      ----------------------------------------------------------------------------------
      -- Submit program OD: CDH Activate Bulk Batch Program; stage STAGE30
      ----------------------------------------------------------------------------------
      
      lb_success := fnd_submit.submit_program(application => 'XXCRM',program => 'XX_CDH_ACTIVATE_BULK_BATCH',
                                              stage => 'XX_CDH_ACTIVATE_BULK_BATCH',argument1 => p_batch_id);
      
      IF (NOT lb_success) THEN
        RAISE le_submit_failed;
      END IF;
      ----------------------------------------------------------------------------------
      -- Submit program OD: CDH Submit Bulk Import Wrapper Program ; stage STAGE40
      ----------------------------------------------------------------------------------
      
      lb_success := fnd_submit.submit_program(application => 'XXCRM',program => 'XX_CDH_SUBMIT_BULK_WRAPPER',
                                              stage => 'XX_CDH_SUBMIT_BULK_WRAPPER',argument1 => lc_submit_bulk_load,
                                              argument2 => p_batch_id,argument3 => lc_imp_run_option,
                                              argument4 => lc_run_batch_dedup,argument5 => lc_batch_dedup_rule,
                                              argument6 => lc_action_dup,argument7 => lc_run_add_val,
                                              argument8 => lc_run_reg_dedup,argument9 => lc_reg_dedup_rule,
                                              argument10 => lc_gen_fuzzy_key);
      
      IF (NOT lb_success) THEN
        RAISE le_submit_failed;
      END IF;
      -------------------------------------------------------------------------------------
      -- Submit program OD: CDH SOLAR Extensibles Update Program which is in stage STAGE50
      -------------------------------------------------------------------------------------
      
      lb_success := fnd_submit.submit_program(application => 'XXCRM',program => 'XX_CDH_SOLAR_EXT_ATTR_MAIN',
                                              stage => 'XX_CDH_SOLAR_EXT_ATTR_MAIN',argument1 => p_batch_id,
                                              argument2 => lc_process_extn_upd_yn);
      
      IF (NOT lb_success) THEN
        RAISE le_submit_failed;
      END IF;
      -------------------------------------------------------------------------------------
      -- Submit program OD: CDH Customer Contact Points Conversion Program; Stage STAGE60
      -------------------------------------------------------------------------------------
      
      lb_success := fnd_submit.submit_program(application => 'XXCRM',program => 'XX_CDH_CUST_CONTACT_POINT_CONV',
                                              stage => 'XX_CDH_CUST_CONTACT_POINT_CONV',
                                              argument1 => p_batch_id,argument2 => lc_process_contact_pt_yn);
      
      IF (NOT lb_success) THEN
        RAISE le_submit_failed;
      END IF;
      ------------------------------------------------------------------------------------------
      -- Submit program OD: CDH Extensible Attributes Program which is in stage STAGE70
      ------------------------------------------------------------------------------------------
      
      lb_success := fnd_submit.submit_program(application => 'XXCRM',program => 'XX_CDH_CUST_EXT_ATTRIB_CONV',
                                              stage => 'XX_CDH_CUST_EXT_ATTRIB_CONV',argument1 => p_batch_id,
                                              argument2 => lc_process_extn_attr_yn);
      
      IF (NOT lb_success) THEN
        RAISE le_submit_failed;
      END IF;
      ------------------------------------------------------------------------------------------
      -- Submit program OD: SFA Import Sales Leads Inbound which is in stage STAGE80
      ------------------------------------------------------------------------------------------
      
      lb_success := fnd_submit.submit_program(application => 'XXCRM',program => 'XXSFALEADSINT',
                                              stage => 'XXSFALEADSINT',argument1 => p_batch_id);
      
      IF (NOT lb_success) THEN
        RAISE le_submit_failed;
      END IF;
      ------------------------------
      -- Submit the Request Set
      ------------------------------
      
      ln_req_id := fnd_submit.submit_set(NULL,false);
      
      fnd_file.put_line(fnd_file.LOG,'Request Set End');
      
      IF ln_req_id = 0 THEN
        x_errbuf := fnd_message.get;
        
        x_retcode := 2;
        
        fnd_file.put_line(fnd_file.LOG,'Error while submitting Request Set - '
                                       ||x_errbuf);
      ELSE
        fnd_file.put_line(fnd_file.LOG,' ');
        
        fnd_file.put_line(fnd_file.LOG,'Request Set submitted with request id: '
                                       ||to_char(ln_req_id));
        
        COMMIT;
      END IF;
      --------------------------------------------------------------------
      -- Wait for Request Set to Complete
      --------------------------------------------------------------------
      
      lv_phase := NULL;
      
      lv_status := NULL;
      
      lv_dev_phase := NULL;
      
      lv_dev_status := NULL;
      
      lv_message := NULL;
      
      lb_wait := fnd_concurrent.wait_for_request(request_id => ln_req_id,INTERVAL => 10,phase => lv_phase,
                                                 status => lv_status,dev_phase => lv_dev_phase,
                                                 dev_status => lv_dev_status,message => lv_message);
    END IF;

/* Commented by Kishore Jena on 11/17/2009 -- Will call the API directly instead of submitting
   concurrent program
    -------------------------------------------------------------------------
    -- SUBMIT OD: TM Party Site Named Account Mass Assignment Master Program
    ------------------------------------------------------------------------
    
    BEGIN
      SELECT MAX(party_site_id)
      INTO   ln_max_party_site_id
      FROM   apps.xxod_hz_imp_addresses_int hiai
             ,apps.hz_party_sites hosr
      WHERE  hiai.site_orig_system_reference = hosr.orig_system_reference
             AND hiai.batch_id = p_batch_id;
    EXCEPTION
      WHEN OTHERS THEN
        ln_max_party_site_id := 0;
    END;
*/

    -- Get Territory Assignment source for Lead Referral
    BEGIN
      SELECT description
      INTO   lc_terr_asgnmnt_source 
      FROM   FND_LOOKUP_VALUES_VL
      WHERE  lookup_type = 'XX_SFA_TERR_ASGNMNT_SOURCE'
        AND  lookup_code = 'RULE_ASGNMNT_LR'
        AND  enabled_flag = 'Y'
        AND  SYSDATE BETWEEN start_date_active AND NVL(end_date_active, SYSDATE+1);
    EXCEPTION
      WHEN OTHERS THEN
        lc_error_message := 'No Lookup Value defined for Territory Assignment Source for Lead Referral.';
        RAISE EX_PARTY_SITE_ERROR;
    END;
    
    FOR lcr_party_site_range IN lcu_party_site_range LOOP
      /* Commented by Kishore Jena on 11/17/2009 -- Will call the API directly instead of submitting
         concurrent program      

      IF ln_party_site_cnt = 0 THEN
        ln_start_party_site_id := lcr_party_site_range.party_site_id;
      END IF;
      
      IF lcr_party_site_range.party_site_id <> ln_start_party_site_id + ln_party_site_cnt THEN
        ln_from_party_site_id := ln_start_party_site_id;
        
        ln_to_party_site_id := ln_prev_party_site_id;
        
        ln_party_site_cnt := 1;
        
        ln_prev_party_site_id := lcr_party_site_range.party_site_id;
        
        ln_start_party_site_id := lcr_party_site_range.party_site_id;
        
        xx_sfa_lead_referral_pkg.submit_party_site_mass_assgn(ln_from_party_site_id,ln_to_party_site_id);
        
      ELSE
        ln_party_site_cnt := ln_party_site_cnt + 1;
        
        ln_prev_party_site_id := lcr_party_site_range.party_site_id;
      END IF;
      
      IF lcr_party_site_range.party_site_id = ln_max_party_site_id THEN
        ln_from_party_site_id := ln_start_party_site_id;
        
        ln_to_party_site_id := lcr_party_site_range.party_site_id;
        
        xx_sfa_lead_referral_pkg.submit_party_site_mass_assgn(ln_from_party_site_id,ln_to_party_site_id);
        
      END IF;
      */

      --Call the common API for getting the resource/role/group based on territory rule 
      XX_TM_TERRITORY_UTIL_PKG.TERR_RULE_BASED_WINNER_LOOKUP
            (
              p_party_site_id              => lcr_party_site_range.party_site_id,
              p_org_type                   => 'PROSPECT',
              p_od_wcw                     => NULL,
              p_sic_code                   => NULL,
              p_postal_code                => NULL,
              p_division                   => 'BSD',
              p_compare_creator_territory  => 'N',
              p_nam_terr_id => ln_nam_terr_id,
              p_resource_id => ln_resource_id,
              p_role_id => ln_role_id,
              p_group_id => ln_group_id,
              p_full_access_flag => lc_full_access_flag,
              x_return_status => lc_return_status,
              x_message_data => lc_message_data
             );

      IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        fnd_file.put_line(fnd_file.LOG, 'Get Winner Error for party site id: ' || 
                          lcr_party_site_range.party_site_id || ' : ' || lc_message_data);
      ELSE
        -- Assign the party site to resource/role/group
        XX_JTF_RS_NAMED_ACC_TERR_PUB.Create_Territory
                (p_api_version_number       => 1.0
                 ,p_named_acct_terr_id      => NULL
                 ,p_named_acct_terr_name    => NULL
                 ,p_named_acct_terr_desc    => NULL
                 ,p_status                  => 'A'
                 ,p_start_date_active       => SYSDATE
                 ,p_end_date_active         => NULL
                 ,p_full_access_flag        => lc_full_access_flag
                 ,p_source_terr_id          => null
                 ,p_resource_id             => ln_resource_id
                 ,p_role_id                 => ln_role_id
                 ,p_group_id                => ln_group_id
                 ,p_entity_type             => 'PARTY_SITE'
                 ,p_entity_id               => lcr_party_site_range.party_site_id
                 ,p_source_entity_id        => NULL
                 ,p_source_system           => NULL
                 ,p_allow_inactive_resource => 'N'
                 ,p_set_extracted_status    => 'N'
                 ,p_terr_asgnmnt_source     => lc_terr_asgnmnt_source 
                 ,p_commit                  => FALSE
                 ,x_error_code              => lc_return_status
                 ,x_error_message           => lc_message_data
               );

        IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          fnd_file.put_line(fnd_file.LOG, 'Create Territory Error for party site id: ' || 
                            lcr_party_site_range.party_site_id || ' : ' || lc_message_data);
        END IF;
      END IF;
    END LOOP;

    -------------------------------------------------------------------------
    -- SUBMIT OD: TM Lead Named Account Mass Assignment Master Program
    ------------------------------------------------------------------------
    BEGIN
      SELECT MAX(sales_lead_id)
      INTO   ln_max_sales_lead_id
      FROM   apps.as_import_interface
      WHERE  batch_id = p_batch_id
        AND  sales_lead_id is NOT NULL;
    EXCEPTION
      WHEN OTHERS THEN
        ln_max_sales_lead_id := 0;
    END;
    
    FOR lcr_sales_lead_range IN lcu_sales_lead_range LOOP
      IF ln_sales_lead_cnt = 0 THEN
        ln_start_sales_lead_id := lcr_sales_lead_range.sales_lead_id;
      END IF;
      
      IF lcr_sales_lead_range.sales_lead_id <> ln_start_sales_lead_id + ln_sales_lead_cnt THEN
        ln_from_sales_lead_id := ln_start_sales_lead_id;
        
        ln_to_sales_lead_id := ln_prev_sales_lead_id;
        
        ln_sales_lead_cnt := 1;
        
        ln_prev_sales_lead_id := lcr_sales_lead_range.sales_lead_id;
        
        ln_start_sales_lead_id := lcr_sales_lead_range.sales_lead_id;
        
        xx_sfa_lead_referral_pkg.submit_lead_mass_assgn(ln_from_sales_lead_id,ln_to_sales_lead_id);
      ELSE
        ln_sales_lead_cnt := ln_sales_lead_cnt + 1;
        
        ln_prev_sales_lead_id := lcr_sales_lead_range.sales_lead_id;
      END IF;
      
      IF lcr_sales_lead_range.sales_lead_id = ln_max_sales_lead_id THEN
        ln_from_sales_lead_id := ln_start_sales_lead_id;
        
        ln_to_sales_lead_id := lcr_sales_lead_range.sales_lead_id;
        
        xx_sfa_lead_referral_pkg.submit_lead_mass_assgn(ln_from_sales_lead_id,ln_to_sales_lead_id);
      END IF;
    END LOOP;

  EXCEPTION
    WHEN le_submit_failed THEN
      fnd_file.put_line(fnd_file.LOG,'Error while submitting request Set - '
                                     ||fnd_message.get);
      
      x_errbuf := 'Error while submitting request Set - '
                  ||fnd_message.get;
      
      x_retcode := 2;
    WHEN EX_PARTY_SITE_ERROR THEN
      fnd_file.put_line(fnd_file.LOG, lc_error_message);      
      x_errbuf := lc_error_message;      
      x_retcode := 2;
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.LOG,'Unexpected Error in proecedure submit_conv_request_set - Error - '
                                     ||SQLERRM);
      
      x_errbuf := 'Unexpected Error in procedure submit_conv_request_set - Error - '
                  ||SQLERRM;
      
      x_retcode := 2;
  END submit_request_set;

  -- +===================================================================+
  -- | Name             : SUBMIT_PARTY_SITE_MASS_ASSGN                   |
  -- | Description      : This procedure submits the Mass Assignments    |
  -- |                    Program.                                       |
  -- |                                                                   |
  -- | Parameters :      p_from_party_site_id                            |
  -- |                   p_to_party_site_id                              |
  -- +===================================================================+
  
  PROCEDURE submit_party_site_mass_assgn
       (p_from_party_site_id  NUMBER
        ,p_to_party_site_id   NUMBER)
  IS
    ln_conc_request_id  NUMBER;
    lv_phase            VARCHAR2(50);
    lv_status           VARCHAR2(50);
    lv_dev_phase        VARCHAR2(15);
    lv_dev_status       VARCHAR2(15);
    lb_wait             BOOLEAN;
    lv_message          VARCHAR2(4000);
  BEGIN
  -------------------------------------------------------------------------
  -- SUBMIT OD: TM Party Site Named Account Mass Assignment Master Program
  -------------------------------------------------------------------------
  
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,'Submitting OD: TM Party Site Named Account Mass Assignment Master Program');
    
    fnd_file.put_line(fnd_file.LOG,'-------------------------------------------------------------------------');
    
    fnd_file.put_line(fnd_file.LOG,'Party Site Range: '
                                   ||p_from_party_site_id
                                   ||' to '
                                   ||p_to_party_site_id);
    
    ln_conc_request_id := fnd_request.submit_request(application => 'XXCRM',program => 'XXJTFBLSLREPPSTCRTNMASTER',
                                                     description => NULL,start_time => NULL,sub_request => false,
                                                     argument1 => p_from_party_site_id,argument2 => p_to_party_site_id,
                                                     argument3 => 'N');
    
    COMMIT;
    
    IF ln_conc_request_id = 0 THEN
      fnd_file.put_line(fnd_file.LOG,'OD: TM Party Site Named Account Mass Assignment Master Program: '
                                     ||SQLERRM);
    ELSE
      fnd_file.put_line(fnd_file.LOG,' ');
      
      fnd_file.put_line(fnd_file.LOG,'OD: TM Party Site Named Account Mass Assignment Master Program: '
                                     ||to_char(ln_conc_request_id));
    END IF;
    
    lv_phase := NULL;
    
    lv_status := NULL;
    
    lv_dev_phase := NULL;
    
    lv_dev_status := NULL;
    
    lv_message := NULL;
    
    lb_wait := fnd_concurrent.wait_for_request(request_id => ln_conc_request_id,INTERVAL => 10,
                                               phase => lv_phase,status => lv_status,dev_phase => lv_dev_phase,
                                               dev_status => lv_dev_status,message => lv_message);
  EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.LOG,'Error while submitting program, OD: TM Party Site Named Account Mass Assignment Master Program: '
                                     ||SQLERRM);
  END submit_party_site_mass_assgn;
  -- +===================================================================+
  -- | Name             : SUBMIT_LEAD_MASS_ASSGN                         |
  -- | Description      : This procedure submits the Mass Assignments    |
  -- |                    Program.                                       |
  -- |                                                                   |
  -- | Parameters :      p_from_sales_lead_id                            |
  -- |                   p_to_sales_lead_id                              |
  -- +===================================================================+
  
  PROCEDURE submit_lead_mass_assgn
       (p_from_sales_lead_id  NUMBER
        ,p_to_sales_lead_id   NUMBER)
  IS
    ln_conc_request_id  NUMBER;
    lv_phase            VARCHAR2(50);
    lv_status           VARCHAR2(50);
    lv_dev_phase        VARCHAR2(15);
    lv_dev_status       VARCHAR2(15);
    lb_wait             BOOLEAN;
    lv_message          VARCHAR2(4000);
  BEGIN
  -------------------------------------------------------------------------
  -- SUBMIT OD: TM Lead Named Account Mass Assignment Master Program
  -------------------------------------------------------------------------
  
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,'Submitting OD: TM Lead Named Account Mass Assignment Master Program');
    
    fnd_file.put_line(fnd_file.LOG,'-------------------------------------------------------------------------');
    
    fnd_file.put_line(fnd_file.LOG,'Sales Leads Range: '
                                   ||p_from_sales_lead_id
                                   ||' to '
                                   ||p_to_sales_lead_id);
    
    ln_conc_request_id := fnd_request.submit_request(application => 'XXCRM',program => 'XXJTFBLSLREPLEADCRTNMASTER',
                                                     description => NULL,start_time => NULL,sub_request => false,
                                                     argument1 => p_from_sales_lead_id,argument2 => p_to_sales_lead_id);
    
    COMMIT;
    
    IF ln_conc_request_id = 0 THEN
      fnd_file.put_line(fnd_file.LOG,'OD: TM Lead Named Account Mass Assignment Master Program: '
                                     ||SQLERRM);
    ELSE
      fnd_file.put_line(fnd_file.LOG,' ');
      
      fnd_file.put_line(fnd_file.LOG,'OD: TM Lead Named Account Mass Assignment Master Program: '
                                     ||to_char(ln_conc_request_id));
    END IF;
    
    lv_phase := NULL;
    
    lv_status := NULL;
    
    lv_dev_phase := NULL;
    
    lv_dev_status := NULL;
    
    lv_message := NULL;
    
    lb_wait := fnd_concurrent.wait_for_request(request_id => ln_conc_request_id,INTERVAL => 10,
                                               phase => lv_phase,status => lv_status,dev_phase => lv_dev_phase,
                                               dev_status => lv_dev_status,message => lv_message);
  EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.LOG,'Error while submitting program, OD: TM Lead Named Account Mass Assignment Master Program:'
                                     ||SQLERRM);
  END submit_lead_mass_assgn;

END xx_sfa_lead_referral_pkg;
/
Show Errors
