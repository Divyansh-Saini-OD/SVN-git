create or replace
PACKAGE BODY xx_hr_ps_full_sync AS
  -- +======================================================================+
  -- | Name        : xx_hr_ps_full_sync                                     |
  -- | Author      : Mohan Kalyanasundaram                                  |
  -- | Description : This package is used for moving complete People Soft   |
  -- |               Data into Oracle HR staging table. This packages reads |
  -- |               a csv file from the directory XXFIN_IN_PSHR, processes |
  -- |               every line from the csv file. For every line in the csv|
  -- |               file, procedure XX_HR_PS_STG_INSERT_PKG.INSERT_PROC is |
  -- |               called to insert data into the HR staging table.       | 
  -- | Date        : June 20, 2012 --> New Version Started by Mohan         |
  -- +====================================================================+
  PROCEDURE main_process
  (
     x_errbuf      OUT NOCOPY      VARCHAR2,
      x_retcode     OUT NOCOPY      NUMBER
  )
  AS

  l_infile_dir                  varchar2(1000) := NULL;
  l_new_line                    varchar2(32767) := null;
  l_msg_data                    varchar2(2000) := NULL;
  l_file_handle                 UTL_FILE.FILE_TYPE;
  l_num_of_lines_processed      number := 0;
  BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'===>>> Program started....');
    BEGIN
      SELECT directory_path into l_infile_dir 
        FROM all_directories
        WHERE directory_name = 'XXFIN_IN_PSHR';
    EXCEPTION
      WHEN OTHERS THEN
        l_msg_data := 'SQLCode: '||SQLCODE||'  Error Message: '||SQLERRM;
        log_exception (
        p_program_name              => 'XX_HR_PS_FULL_SYNC'
        ,p_error_location           => 'main_process'
        ,p_error_status             => 'ERROR'
        ,p_oracle_error_code        => SQLCODE
        ,p_oracle_error_msg         => l_msg_data
        ,p_error_message_severity   => 'MAJOR');
        FND_FILE.PUT_LINE(FND_FILE.LOG,l_msg_data);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_msg_data);
        raise stop_run;
    END;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'===>>> In Directory found: '||l_infile_dir);
    BEGIN
      l_file_handle := UTL_FILE.fopen (LOCATION       => 'XXFIN_IN_PSHR',
                         filename       => G_INFILENAME,
                         open_mode      => 'r',
                  			 MAX_LINESIZE   => 32767
                         );
      FND_FILE.PUT_LINE(FND_FILE.LOG,'===>>> File Opened: '||G_INFILENAME);

    EXCEPTION
    WHEN OTHERS THEN
      l_msg_data := 'Error Opening file: '||G_INFILENAME||', SQLCode: '||SQLCODE||'  Error Message: '||SQLERRM;
      log_exception (
      p_program_name              => 'XX_HR_PS_FULL_SYNC'
      ,p_error_location           => 'main_process'
      ,p_error_status             => 'ERROR'
      ,p_oracle_error_code        => SQLCODE
      ,p_oracle_error_msg         => l_msg_data
      ,p_error_message_severity   => 'MAJOR');
      FND_FILE.PUT_LINE(FND_FILE.LOG,l_msg_data);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_msg_data);
      raise stop_run;
    END;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'===>> Successfully opened the file: '||G_INFILENAME||' Starting to read lines from the file: '||G_INFILENAME);
    LOOP
      BEGIN
        UTL_FILE.GET_LINE(l_file_handle, l_new_line);
        l_num_of_lines_processed := l_num_of_lines_processed + 1;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*** Processing Line '||l_num_of_lines_processed||' ==>> '||l_new_line);
        IF (l_num_of_lines_processed > 1) THEN  -- Skip the header line from processing
          process_line(l_new_line);
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'===>> Total lines processed: '||l_num_of_lines_processed);
          l_msg_data := 'End of file reached. Total Lines Processed: '||l_num_of_lines_processed||' SQLCode: '||SQLCODE||'  Error Message: '||SQLERRM;
          log_exception (
          p_program_name              => 'XX_HR_PS_FULL_SYNC'
          ,p_error_location           => 'main_process'
          ,p_error_status             => 'INFO'
          ,p_oracle_error_code        => SQLCODE
          ,p_oracle_error_msg         => l_msg_data
          ,p_error_message_severity   => 'MAJOR');
          FND_FILE.PUT_LINE(FND_FILE.LOG,l_msg_data);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_msg_data);
          UTL_FILE.FCLOSE(l_file_handle);
          EXIT;
        WHEN OTHERS THEN
          l_msg_data := 'Error in reading line from the file, SQLCode: '||SQLCODE||'  Error Message: '||SQLERRM;
          log_exception (
          p_program_name              => 'XX_HR_PS_FULL_SYNC'
          ,p_error_location           => 'main_process'
          ,p_error_status             => 'ERROR'
          ,p_oracle_error_code        => SQLCODE
          ,p_oracle_error_msg         => l_msg_data
          ,p_error_message_severity   => 'MAJOR');
          FND_FILE.PUT_LINE(FND_FILE.LOG,l_msg_data);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_msg_data);
      END;
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'===>>> Program ended...');
  EXCEPTION
  WHEN stop_run THEN
    UTL_FILE.FCLOSE(l_file_handle);
  WHEN OTHERS THEN
    l_msg_data := 'Program is falling through because of un-handled exception, SQLCode: '||SQLCODE||'  Error Message: '||SQLERRM;
    log_exception (
    p_program_name              => 'XX_HR_PS_FULL_SYNC'
    ,p_error_location           => 'main_process'
    ,p_error_status             => 'ERROR'
    ,p_oracle_error_code        => SQLCODE
    ,p_oracle_error_msg         => l_msg_data
    ,p_error_message_severity   => 'MAJOR');
    FND_FILE.PUT_LINE(FND_FILE.LOG,l_msg_data);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_msg_data);
    UTL_FILE.FCLOSE(l_file_handle);

  END main_process;

-- +====================================================================+
-- | Name        : process_line                                         |
-- | Description : This procedure is used for processing each line from |
-- |               csv file.                                            |
-- | Parameters  : p_line_data                                          |
-- +====================================================================+

  PROCEDURE process_line
    (p_line_data IN VARCHAR2)  
  AS
  l_msg_data                    varchar2(2000) := NULL;
  l_retcode                     varchar2(20) := NULL;
  l_emplid                      VARCHAR2(20):= null;
  l_badge_nbr                   VARCHAR2(20):= null;
  l_first_name	                VARCHAR2(50):= null;
  l_middle_name                 VARCHAR2(50):= null;
  l_last_name                   VARCHAR2(50):= null;
  l_second_last_name	          VARCHAR2(50):= null;
  l_name_prefix                 VARCHAR2(20):= null;
  l_name_suffix                 VARCHAR2(20):= null;
  l_od_addeffdt                 DATE  := null;
  l_sex                         VARCHAR2(20):= null;
  l_address1                    VARCHAR2(100):= null;
  l_address2	                  VARCHAR2(100):= null;
  l_address3	                  VARCHAR2(100):= null;
  l_city	                      VARCHAR2(50):= null;
  l_postal	                    VARCHAR2(50):= null;
  l_county	                    VARCHAR2(50):= null;
  l_state                       VARCHAR2(50):= null;
  l_country                     VARCHAR2(50):= null;
  l_per_org                     VARCHAR2(50):= null;
  l_empl_status                 VARCHAR2(20):= null;
  l_od_jobeffdt                 DATE := null;
  l_hire_dt                     DATE := null;
  l_action	                    VARCHAR2(20):= null;
  l_setid_jobcode               VARCHAR2(50):= null;
  l_jobcode                     VARCHAR2(50):= null;
  l_business_unit               VARCHAR2(50):= null;
  l_setid_location              VARCHAR2(50):= null;
  l_location	                  VARCHAR2(50):= null;
  l_company                     VARCHAR2(50):= null;
  l_setid_dept                  VARCHAR2(50):= null;
  l_deptid                      VARCHAR2(50):= null;
  l_reg_region                  VARCHAR2(50):= null;
  l_last_date_worked            DATE := null;
  l_grade                       VARCHAR2(50):= null;
  l_sal_admin_plan              VARCHAR2(50):= null;
  l_supervisor_id               VARCHAR2(20):= null;
  l_manager_level               VARCHAR2(50):= null;
  l_job_entry_dt                DATE := null;
  l_job_function                VARCHAR2(50):= null;
  l_descr                       VARCHAR2(50):= null;
  l_emailid                     VARCHAR2(50):= null;
  l_vendor_id                   VARCHAR2(50):= null;
  l_od_phone_busn               VARCHAR2(50):= null;
  l_pref_phone_busn_fg	        VARCHAR2(50):= null;
  l_od_phone_fax                VARCHAR2(50):= null;
  l_pref_phone_fax_fg           VARCHAR2(50):= null;
  l_od_phone_faxp               VARCHAR2(50):= null;
  l_pref_phone_faxp_fg	        VARCHAR2(50):= null;
  l_od_phone_main               VARCHAR2(50):= null;
  l_pref_phone_main_fg	        VARCHAR2(50):= null;
  l_od_phone_mobb               VARCHAR2(50):= null;
  l_pref_phone_mobb_fg	        VARCHAR2(50):= null;
  l_od_phone_mobp               VARCHAR2(50):= null;
  l_pref_phone_mobp_fg	        VARCHAR2(50):= null;
  l_od_phone_pgr1               VARCHAR2(50):= null;
  l_pref_phone_pgr1_fg	        VARCHAR2(50):= null;
  l_ins_trig_flag               VARCHAR2(50):= null;
  l_ins_stg_flag     	          VARCHAR2(50):= null;
  BEGIN
        --SELECT  regexp_substr('a,b,c,d,e', '[^,]+', 1, 6) from dual;
    l_msg_data := null;
    l_retcode := null;
    BEGIN
      SELECT  regexp_substr(p_line_data, '[^,]+', 1, 1), regexp_substr(p_line_data, '[^,]+', 1, 2), regexp_substr(p_line_data, '[^,]+', 1, 3),
              regexp_substr(p_line_data, '[^,]+', 1, 4), regexp_substr(p_line_data, '[^,]+', 1, 5), regexp_substr(p_line_data, '[^,]+', 1, 6),
              regexp_substr(p_line_data, '[^,]+', 1, 7), regexp_substr(p_line_data, '[^,]+', 1, 8), regexp_substr(p_line_data, '[^,]+', 1, 9),
              regexp_substr(p_line_data, '[^,]+', 1, 10),regexp_substr(p_line_data, '[^,]+', 1, 11),regexp_substr(p_line_data, '[^,]+', 1, 12),
              regexp_substr(p_line_data, '[^,]+', 1, 13),regexp_substr(p_line_data, '[^,]+', 1, 14),regexp_substr(p_line_data, '[^,]+', 1, 15),
              regexp_substr(p_line_data, '[^,]+', 1, 16),regexp_substr(p_line_data, '[^,]+', 1, 17),regexp_substr(p_line_data, '[^,]+', 1, 18),
              regexp_substr(p_line_data, '[^,]+', 1, 19),
              regexp_substr(p_line_data, '[^,]+', 1, 20),regexp_substr(p_line_data, '[^,]+', 1, 21),regexp_substr(p_line_data, '[^,]+', 1, 22),
              regexp_substr(p_line_data, '[^,]+', 1, 23),regexp_substr(p_line_data, '[^,]+', 1, 24),regexp_substr(p_line_data, '[^,]+', 1, 25),
              regexp_substr(p_line_data, '[^,]+', 1, 26),regexp_substr(p_line_data, '[^,]+', 1, 27),regexp_substr(p_line_data, '[^,]+', 1, 28),
              regexp_substr(p_line_data, '[^,]+', 1, 29),
              regexp_substr(p_line_data, '[^,]+', 1, 30),regexp_substr(p_line_data, '[^,]+', 1, 31),regexp_substr(p_line_data, '[^,]+', 1, 32),
              regexp_substr(p_line_data, '[^,]+', 1, 33),regexp_substr(p_line_data, '[^,]+', 1, 34),regexp_substr(p_line_data, '[^,]+', 1, 35),
              regexp_substr(p_line_data, '[^,]+', 1, 36),regexp_substr(p_line_data, '[^,]+', 1, 37),regexp_substr(p_line_data, '[^,]+', 1, 38),
              regexp_substr(p_line_data, '[^,]+', 1, 39),
              regexp_substr(p_line_data, '[^,]+', 1, 40),regexp_substr(p_line_data, '[^,]+', 1, 41),regexp_substr(p_line_data, '[^,]+', 1, 42),
              regexp_substr(p_line_data, '[^,]+', 1, 43),regexp_substr(p_line_data, '[^,]+', 1, 44),regexp_substr(p_line_data, '[^,]+', 1, 45),
              regexp_substr(p_line_data, '[^,]+', 1, 46),regexp_substr(p_line_data, '[^,]+', 1, 47),regexp_substr(p_line_data, '[^,]+', 1, 48),
              regexp_substr(p_line_data, '[^,]+', 1, 49),
              regexp_substr(p_line_data, '[^,]+', 1, 50),regexp_substr(p_line_data, '[^,]+', 1, 51),regexp_substr(p_line_data, '[^,]+', 1, 52),
              regexp_substr(p_line_data, '[^,]+', 1, 53),regexp_substr(p_line_data, '[^,]+', 1, 54),regexp_substr(p_line_data, '[^,]+', 1, 55),
              regexp_substr(p_line_data, '[^,]+', 1, 56),regexp_substr(p_line_data, '[^,]+', 1, 57),regexp_substr(p_line_data, '[^,]+', 1, 58)             
            INTO
              l_emplid,l_badge_nbr,l_first_name,l_middle_name,l_last_name,
              l_second_last_name,l_name_prefix,l_name_suffix,l_od_addeffdt,
              l_sex,l_address1,l_address2,l_address3,l_city,l_postal,
              l_county,l_state,l_country,l_per_org,l_empl_status,l_od_jobeffdt,
              l_hire_dt,l_action,l_setid_jobcode,l_jobcode,l_business_unit,
              l_setid_location,l_location,l_company,l_setid_dept,
              l_deptid,l_reg_region,l_last_date_worked,l_grade,l_sal_admin_plan,
              l_supervisor_id,l_manager_level,l_job_entry_dt,l_job_function,
              l_descr,l_emailid,l_vendor_id,l_od_phone_busn,l_pref_phone_busn_fg,
              l_od_phone_fax,l_pref_phone_fax_fg,l_od_phone_faxp,l_pref_phone_faxp_fg,
              l_od_phone_main,l_pref_phone_main_fg,l_od_phone_mobb,l_pref_phone_mobb_fg,
              l_od_phone_mobp,l_pref_phone_mobp_fg,l_od_phone_pgr1,l_pref_phone_pgr1_fg,
              l_ins_trig_flag,l_ins_stg_flag
            FROM DUAL;
            XX_HR_PS_STG_INSERT_PKG.INSERT_PROC (
              p_emplid                      => l_emplid,
              p_badge_nbr                   => l_badge_nbr,
              p_first_name	                => l_first_name,
              p_middle_name                 => l_middle_name,
              p_last_name                   => l_last_name ,
              p_second_last_name	          => l_second_last_name,
              p_name_prefix                 => l_name_prefix,
              p_name_suffix                 => l_name_suffix,
              p_od_addeffdt                 => l_od_addeffdt,
              p_sex                         => l_sex,
              p_address1                    => l_address1,
              p_address2	                  => l_address2,
              p_address3	                  => l_address3,
              p_city	                      => l_city,
              p_postal	                    => l_postal,
              p_county	                    => l_county,
              p_state                       => l_state ,
              p_country                     => l_country,
              p_per_org                     => l_per_org,
              p_empl_status                 => l_empl_status,
              p_od_jobeffdt                 => l_od_jobeffdt,
              p_hire_dt                     => l_hire_dt,
              p_action	                    => l_action,
              p_setid_jobcode               => l_setid_jobcode,
              p_jobcode                     => l_jobcode,
              p_business_unit               => l_business_unit,
              p_setid_location              => l_setid_location,
              p_location	                  => l_location,
              p_company                     => l_company,
              p_setid_dept                  => l_setid_dept,
              p_deptid                      => l_deptid,
              p_reg_region                  => l_reg_region,
              p_last_date_worked            => l_last_date_worked,
              p_grade                       => l_grade,
              p_sal_admin_plan              => l_sal_admin_plan,
              p_supervisor_id               => l_supervisor_id,
              p_manager_level               => l_manager_level,
              p_job_entry_dt                => l_job_entry_dt,
              p_job_function                => l_job_function,
              p_descr                       => l_descr,
              p_emailid                     => l_emailid,
              p_vendor_id                   => l_vendor_id,
              p_od_phone_busn               => l_od_phone_busn,
              p_pref_phone_busn_fg	        => l_pref_phone_busn_fg,
              p_od_phone_fax                => l_od_phone_fax,
              p_pref_phone_fax_fg           => l_pref_phone_fax_fg,
              p_od_phone_faxp               => l_od_phone_faxp,
              p_pref_phone_faxp_fg	        => l_pref_phone_faxp_fg,
              p_od_phone_main               => l_od_phone_main,
              p_pref_phone_main_fg	        => l_pref_phone_main_fg,
              p_od_phone_mobb               => l_od_phone_mobb,
              p_pref_phone_mobb_fg	        => l_pref_phone_mobb_fg,
              p_od_phone_mobp               => l_od_phone_mobp,
              p_pref_phone_mobp_fg	        => l_pref_phone_mobp_fg,
              p_od_phone_pgr1               => l_od_phone_pgr1,
              p_pref_phone_pgr1_fg	        => l_pref_phone_pgr1_fg,
              p_ins_trig_flag               => l_ins_trig_flag,
              p_ins_stg_flag     	          => l_ins_stg_flag,
              p_errbuff                     => l_msg_data,
              p_retcode                     => l_retcode      
            );
      IF (length(l_msg_data) > 0) THEN
        log_exception (
        p_program_name              => 'XX_HR_PS_FULL_SYNC'
        ,p_error_location           => 'process_line'
        ,p_error_status             => 'ERROR'
        ,p_oracle_error_code        => l_retcode
        ,p_oracle_error_msg         => l_msg_data
        ,p_error_message_severity   => 'MAJOR');
        FND_FILE.PUT_LINE(FND_FILE.LOG,l_msg_data);
        FND_FILE.PUT_LINE(FND_FILE.LOG,p_line_data);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_msg_data); 
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      l_msg_data := 'Unknown Error, Line skipped... SQLCode: '||SQLCODE||'  Error Message: '||SQLERRM;
      log_exception (
      p_program_name              => 'XX_HR_PS_FULL_SYNC'
      ,p_error_location           => 'process_line'
      ,p_error_status             => 'ERROR'
      ,p_oracle_error_code        => SQLCODE
      ,p_oracle_error_msg         => l_msg_data
      ,p_error_message_severity   => 'MAJOR');
      FND_FILE.PUT_LINE(FND_FILE.LOG,l_msg_data);
      FND_FILE.PUT_LINE(FND_FILE.LOG,p_line_data);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_msg_data);
    END;
  END process_line;
  
-- +====================================================================+
-- | Name        : log_exception                                        |
-- | Description : This procedure is used for logging exceptions into   |
-- |               conversion common elements tables.                   |
-- |                                                                    |
-- | Parameters  : p_program_name,p_procedure_name,p_error_location     |
-- |               p_error_status,p_oracle_error_code,p_oracle_error_msg|
-- +====================================================================+
  PROCEDURE log_exception
    (p_program_name IN VARCHAR2,
    p_error_location IN VARCHAR2,
    p_error_status IN VARCHAR2,
    p_oracle_error_code IN VARCHAR2,
    p_oracle_error_msg IN VARCHAR2,
    p_error_message_severity IN VARCHAR2)

 AS

-- ============================================================================
-- Local Variables.
-- ============================================================================
  l_return_code VARCHAR2(1) := 'E';
  l_program_name VARCHAR2(50);
  l_object_type constant VARCHAR2(35) := 'XX_HR_PS_FULL_SYNC';
  l_notify_flag constant VARCHAR2(1) := 'Y';
  l_program_type VARCHAR2(35) := 'CONCURRENT PROGRAM';

  BEGIN
    l_program_name := p_program_name;
    IF l_program_name IS NULL THEN
      l_program_name := 'OD: PSHR Full Sync';
    END IF;
    -- ============================================================================
    -- Call to custom error routine.
    -- ============================================================================
    xx_com_error_log_pub.log_error_crm(
      p_return_code             => l_return_code,
      p_program_type            => l_program_type,
      p_program_name            => l_program_name,
      p_error_location          => p_error_location,
      p_error_message_code      => p_oracle_error_code,
      p_error_message           => p_oracle_error_msg,
      p_error_message_severity  => p_error_message_severity,
      p_error_status            => p_error_status,
      p_notify_flag             => l_notify_flag,
      p_object_type             => l_object_type);
  EXCEPTION
  WHEN others THEN
    fnd_file.PUT_LINE(fnd_file.LOG,   ': Error in logging exception :' || sqlerrm);
  END log_exception;
-- +====================================================================+
END xx_hr_ps_full_sync;
/
Show Errors
