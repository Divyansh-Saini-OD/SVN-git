CREATE OR REPLACE PACKAGE BODY XX_HR_PS_FULLSYNC_PKG AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- | Name:  XX_HR_PS_FULLSYNC_PKG                                                               |
-- | Description : This package is used for moving complete People Soft Data into Oracle HR     |
-- |		   staging table. Reads a txt file from the directory XXFIN_IN_PSHR, processes  |		
-- |               every line from the txt file. For every line in the txt file, procedure      | 
-- |               XX_HR_PS_STG_INSERT_PKG.INSERT_PROC is called to insert data into the        |
-- |               HR staging table.       			                                |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         08/14/2012   Paddy Sanjeevi   Initial version                                  |
-- | 2.0         07/06/2013   Divya Sidhaiyan  Defect# 23714 - Unicode character issue          |                         
-- |                                           R12 Upgrade Retrofit                             |
-- +============================================================================================+



-- +============================================================================================+
-- | Name        : log_exception                                                                |
-- | Description : This procedure is used for logging exceptions into conversion common elements| 
-- |               tables                                                                       |
-- |                                                                    		        |
-- | Parameters  : p_program_name,p_procedure_name,p_error_location,p_error_status,             |
-- |               p_oracle_error_code,p_oracle_error_msg                                       |
-- +============================================================================================+

PROCEDURE log_exception  ( p_program_name IN VARCHAR2
		          ,p_error_location IN VARCHAR2
		          ,p_error_status IN VARCHAR2
		          ,p_oracle_error_code IN VARCHAR2
    			  ,p_oracle_error_msg IN VARCHAR2
		          ,p_error_message_severity IN VARCHAR2
			 )

AS

l_return_code 		VARCHAR2(1) := 'E';
l_program_name 		VARCHAR2(50);
l_object_type 		CONSTANT VARCHAR2(35) := 'XX_HR_PS_FULLSYNC_PKG';
l_notify_flag 		CONSTANT VARCHAR2(1) := 'Y';
l_program_type 		VARCHAR2(35) := 'CONCURRENT PROGRAM';

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
    FND_FILE.PUT_LINE(FND_FILE.LOG,   ': Error in logging exception :' || SQLERRM);
END log_exception;

-- +============================================================================================+
-- | Name        : main_process                                                                 |
-- | Description : This procedure is called from the concurrent program to process the data from| 
-- |               the txt file in unix directory XXFIN_IN_PSHR                                 |
-- |                                                                    		        |
-- | Parameters  : x_errbuf, x_retcode							        |
-- +============================================================================================+

PROCEDURE main_process ( x_errbuf      OUT NOCOPY      VARCHAR2
			,x_retcode     OUT NOCOPY      NUMBER
		       )
AS

l_infile_dir                  	VARCHAR2(1000) := NULL;
l_new_line                    	NVARCHAR2(32767) := null;  --Added for Defect# 23714 by Divya Sidhaiyan
l_msg_data                    	VARCHAR2(2000) := NULL;
l_file_handle                 	UTL_FILE.FILE_TYPE;
l_num_of_lines_processed      	NUMBER := 0;

BEGIN

  FND_FILE.PUT_LINE(FND_FILE.LOG,'===>>> Program started....');
  BEGIN
    SELECT directory_path 
      INTO l_infile_dir 
      FROM all_directories
     WHERE directory_name = 'XXFIN_IN_PSHR';
  EXCEPTION
    WHEN OTHERS THEN
      l_msg_data := 'SQLCode: '||SQLCODE||'  Error Message: '||SQLERRM;
      log_exception (
	         	 p_program_name             => 'XX_HR_PS_FULLSYNC_PKG'
	        	,p_error_location           => 'main_process'
        		,p_error_status             => 'ERROR'
		        ,p_oracle_error_code        => SQLCODE
		        ,p_oracle_error_msg         => l_msg_data
		        ,p_error_message_severity   => 'MAJOR'
		    );
       FND_FILE.PUT_LINE(FND_FILE.LOG,l_msg_data);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_msg_data);
       RAISE stop_run;
  END;

  FND_FILE.PUT_LINE(FND_FILE.LOG,'===>>> In Directory found: '||l_infile_dir);

  BEGIN
    l_file_handle := UTL_FILE.fopen_NCHAR (LOCATION       => 'XXFIN_IN_PSHR', --Added for Defect# 23714 by Divya Sidhaiyan
	                             filename       => G_INFILENAME,
            	                     open_mode      => 'r',
                  	  	     MAX_LINESIZE   => 32767
	                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG,'===>>> File Opened: '||G_INFILENAME);

  EXCEPTION
    WHEN OTHERS THEN
      l_msg_data := 'Error Opening file: '||G_INFILENAME||', SQLCode: '||SQLCODE||'  Error Message: '||SQLERRM;
      log_exception (
 		       p_program_name             => 'XX_HR_PS_FULLSYNC_PKG'
		      ,p_error_location           => 'main_process'
		      ,p_error_status             => 'ERROR'
		      ,p_oracle_error_code        => SQLCODE
		      ,p_oracle_error_msg         => l_msg_data
		      ,p_error_message_severity   => 'MAJOR'
		    );
      FND_FILE.PUT_LINE(FND_FILE.LOG,l_msg_data);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_msg_data);
      RAISE stop_run;
  END;

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'===>> Successfully opened the file: '||G_INFILENAME||' Starting to read lines from the file: '||G_INFILENAME);

  LOOP
    BEGIN
      UTL_FILE.GET_LINE_NCHAR(l_file_handle, l_new_line); --Added for Defect# 23714 by Divya Sidhaiyan
      l_num_of_lines_processed := l_num_of_lines_processed + 1;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*** Processing Line '||l_num_of_lines_processed||' ==>> '||l_new_line);
      IF (l_num_of_lines_processed > 1) THEN  -- Skip the header line from processing
          process_line(l_new_line);
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'===>> Total lines processed: '||l_num_of_lines_processed);
	IF l_num_of_lines_processed<2 THEN
           l_msg_data := 'End of file reached. Total Lines Processed: '||l_num_of_lines_processed||' SQLCode: '||SQLCODE||'  Error Message: '||SQLERRM;
           log_exception (
		        p_program_name             => 'XX_HR_PS_FULLSYNC_PKG'	
		       ,p_error_location           => 'main_process'
		       ,p_error_status             => 'INFO'
		       ,p_oracle_error_code        => SQLCODE
	               ,p_oracle_error_msg         => l_msg_data
	               ,p_error_message_severity   => 'MAJOR'
		      );
           FND_FILE.PUT_LINE(FND_FILE.LOG,l_msg_data);
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_msg_data);
	END IF;
        UTL_FILE.FCLOSE(l_file_handle);
        EXIT;
      WHEN OTHERS THEN
        l_msg_data := 'Error in reading line from the file, SQLCode: '||SQLCODE||'  Error Message: '||SQLERRM;
        log_exception (
        	        p_program_name              => 'XX_HR_PS_FULLSYNC_PKG'
		       ,p_error_location           => 'main_process'
	               ,p_error_status             => 'ERROR'
	               ,p_oracle_error_code        => SQLCODE
	               ,p_oracle_error_msg         => l_msg_data
	               ,p_error_message_severity   => 'MAJOR'
                      );
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
    	             p_program_name              => 'XX_HR_PS_FULLSYNC_PKG'
		    ,p_error_location           => 'main_process'
		    ,p_error_status             => 'ERROR'
		    ,p_oracle_error_code        => SQLCODE
		    ,p_oracle_error_msg         => l_msg_data
		    ,p_error_message_severity   => 'MAJOR'
		  );
    FND_FILE.PUT_LINE(FND_FILE.LOG,l_msg_data);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_msg_data);
    UTL_FILE.FCLOSE(l_file_handle);
END main_process;

-- +=================================================================================+
-- | Name        : process_line                                                      |
-- | Description : This procedure is used for processing each line from the txt file |
-- | Parameters  : p_line_data                                                       |
-- +=================================================================================+

PROCEDURE process_line (p_line_data IN VARCHAR2)  
AS
  l_msg_data                    varchar2(2000);
  l_retcode                     varchar2(20);

  l_emplid                      VARCHAR2(33);
  l_badge_nbr                   VARCHAR2(60);
  l_first_name	                VARCHAR2(90);
  l_middle_name                 VARCHAR2(90);
  l_last_name                   VARCHAR2(136);
  l_second_last_name	        VARCHAR2(90);
  l_name_prefix                 VARCHAR2(20);
  l_name_suffix                 VARCHAR2(45);
  l_od_addeffdt                 DATE;
  l_od_addeffdtc                VARCHAR2(30);
  l_sex                         VARCHAR2(20);
  l_address1                    VARCHAR2(165);
  l_address2	                VARCHAR2(165);
  l_address3	                VARCHAR2(408);
  l_city	                VARCHAR2(90);
  l_postal	                VARCHAR2(50);
  l_county	                VARCHAR2(90);
  l_state                       VARCHAR2(50);
  l_country                     VARCHAR2(50);
  l_per_org                     VARCHAR2(50);
  l_empl_status                 VARCHAR2(20);
  l_od_jobeffdt                 DATE;
  l_od_jobeffdtc                VARCHAR2(30);
  l_hire_dt                     DATE;
  l_hire_dtc                    VARCHAR2(30);
  l_action	                VARCHAR2(20);
  l_setid_jobcode               VARCHAR2(50);
  l_jobcode                     VARCHAR2(50);
  l_business_unit               VARCHAR2(50);
  l_setid_location              VARCHAR2(50);
  l_location	                VARCHAR2(50);
  l_company                     VARCHAR2(50);
  l_setid_dept                  VARCHAR2(50);
  l_deptid                      VARCHAR2(50);
  l_reg_region                  VARCHAR2(50);
  l_last_date_worked            DATE;
  l_last_date_workedc           VARCHAR2(30);
  l_grade                       VARCHAR2(50);
  l_sal_admin_plan              VARCHAR2(50);
  l_supervisor_id               VARCHAR2(33);
  l_manager_level               VARCHAR2(50);
  l_job_entry_dt                DATE;
  l_job_entry_dtc               VARCHAR2(30);
  l_job_function                VARCHAR2(50);
  l_descr                       VARCHAR2(90);
  l_emailid                     VARCHAR2(210);
  l_vendor_id                   VARCHAR2(50);
  l_od_phone_busn               VARCHAR2(72);
  l_pref_phone_busn_fg	        VARCHAR2(3);
  l_od_phone_fax                VARCHAR2(72);
  l_pref_phone_fax_fg           VARCHAR2(3);
  l_od_phone_faxp               VARCHAR2(72);
  l_pref_phone_faxp_fg	        VARCHAR2(3);
  l_od_phone_main               VARCHAR2(72);
  l_pref_phone_main_fg	        VARCHAR2(3);
  l_od_phone_mobb               VARCHAR2(72);
  l_pref_phone_mobb_fg	        VARCHAR2(3);
  l_od_phone_mobp               VARCHAR2(72);
  l_pref_phone_mobp_fg	        VARCHAR2(3);
  l_od_phone_pgr1               VARCHAR2(72);
  l_pref_phone_pgr1_fg	        VARCHAR2(3);
  l_ins_trig_flag               VARCHAR2(50):='Y';
  l_ins_stg_flag     	        VARCHAR2(50):='Y';

  v_curpos 			NUMBER:=0;
  v_pos 			NUMBER:=0;
  v_lpos 			NUMBER:=0;

BEGIN

  l_msg_data := NULL;
  l_retcode := NULL;

  v_pos :=INSTR(p_line_data,'|',1,1);
  l_emplid := SUBSTR(p_line_data,1,v_pos-1);

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,2);
  IF v_lpos=v_pos THEN
     l_badge_nbr:=NULL;
  ELSE
     l_badge_nbr:= TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,3);
  IF v_lpos=v_pos THEN
     l_first_name:=NULL;
  ELSE
     l_first_name := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,4);
  IF v_lpos=v_pos THEN
     l_middle_name:=NULL;
  ELSE
     l_middle_name := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,5);
  IF v_lpos=v_pos THEN
     l_last_name:=NULL;
  ELSE
     l_last_name:= TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,6);
  IF v_lpos=v_pos THEN
     l_second_last_name:=NULL;
  ELSE
     l_second_last_name := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,7);
  IF v_lpos=v_pos THEN
     l_name_prefix:=NULL;
  ELSE
     l_name_prefix := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,8);
  IF v_lpos=v_pos THEN
     l_name_suffix:=NULL;
  ELSE
     l_name_suffix := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,9);
  IF v_lpos=v_pos THEN
     l_od_addeffdtc:=NULL;
  ELSE
     l_od_addeffdtc:= TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;
 
  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,10);
  IF v_lpos=v_pos THEN
     l_sex:=NULL;
  ELSE
     l_sex := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;
 
  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,11);
  IF v_lpos=v_pos THEN
     l_address1:=NULL;
  ELSE
     l_address1 := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,12);
  IF v_lpos=v_pos THEN
     l_address2:=NULL;
  ELSE
     l_address2 := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,13);
  IF v_lpos=v_pos THEN
     l_address3:=NULL;
  ELSE
     l_address3 := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,14);
  IF v_lpos=v_pos THEN
     l_city:=NULL;
  ELSE
     l_city  := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;
 
  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,15);
  IF v_lpos=v_pos THEN
     l_postal:=NULL;
  ELSE
     l_postal  := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,16);
  IF v_lpos=v_pos THEN
     l_county:=NULL;
  ELSE
     l_county  := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF; 

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,17);
  IF v_lpos=v_pos THEN
    l_state:=NULL;
  ELSE
    l_state  := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,18);
  IF v_lpos=v_pos THEN
     l_country:=NULL;
  ELSE
     l_country  := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,19);
  IF v_lpos=v_pos THEN
     l_per_org:=NULL;
  ELSE
     l_per_org  := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,20);
  IF v_lpos=v_pos THEN
     l_empl_status:=NULL;
  ELSE
     l_empl_status := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,21);
  IF v_lpos=v_pos THEN
     l_od_jobeffdtc:=NULL;
  ELSE
     l_od_jobeffdtc := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,22);
  IF v_lpos=v_pos THEN
     l_hire_dtc:=NULL;
  ELSE
     l_hire_dtc := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,23);
  IF v_lpos=v_pos THEN
     l_action:=NULL;
  ELSE
     l_action := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,24);
  IF v_lpos=v_pos THEN
     l_setid_jobcode:=NULL;
  ELSE
     l_setid_jobcode := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,25);
  IF v_lpos=v_pos THEN
     l_jobcode:=NULL;
  ELSE
     l_jobcode := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,26);
  IF v_lpos=v_pos THEN
     l_business_unit:=NULL;
  ELSE
     l_business_unit := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,27);
  IF v_lpos=v_pos THEN
     l_setid_location:=NULL;
  ELSE
     l_setid_location := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,28);
  IF v_lpos=v_pos THEN
     l_location:=NULL;
  ELSE
     l_location := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;
 
  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,29);
  IF v_lpos=v_pos THEN
     l_company:=NULL;
  ELSE
     l_company := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;
 
  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,30);
  IF v_lpos=v_pos THEN
     l_setid_dept:=NULL;
  ELSE
     l_setid_dept := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;
 
  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,31);
  IF v_lpos=v_pos THEN
     l_deptid:=NULL;
  ELSE
     l_deptid := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;
 
  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,32);
  IF v_lpos=v_pos THEN
     l_reg_region:=NULL;
  ELSE
     l_reg_region := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,33);
  IF v_lpos=v_pos THEN
     l_last_date_workedc:=NULL;
  ELSE
     l_last_date_workedc := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;
 
  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,34);
  IF v_lpos=v_pos THEN
     l_grade :=NULL;
  ELSE
     l_grade  := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;
  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,35);
  IF v_lpos=v_pos THEN
     l_sal_admin_plan :=NULL;
  ELSE
     l_sal_admin_plan  := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,36);
  IF v_lpos=v_pos THEN
     l_supervisor_id :=NULL;
  ELSE
     l_supervisor_id  := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,37);
  IF v_lpos=v_pos THEN
     l_manager_level :=NULL;
  ELSE
     l_manager_level  := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,38);
  IF v_lpos=v_pos THEN
     l_job_entry_dtc :=NULL;
  ELSE
     l_job_entry_dtc  := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;
 
  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,39);
  IF v_lpos=v_pos THEN
     l_job_function :=NULL;
  ELSE
     l_job_function  := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,40);
  IF v_lpos=v_pos THEN
     l_descr :=NULL;
  ELSE
     l_descr  := SUBSTR(p_line_data,v_lpos,v_pos-v_lpos);
  END IF;
 
  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,41);
  IF v_lpos=v_pos THEN
     l_emailid :=NULL;
  ELSE
     l_emailid  := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,42);
  IF v_lpos=v_pos THEN
     l_vendor_id :=NULL;
  ELSE
     l_vendor_id  := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,43);
  IF v_lpos=v_pos THEN
     l_od_phone_busn :=NULL;
  ELSE
     l_od_phone_busn  := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;
 
  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,44);
  IF v_lpos=v_pos THEN
     l_pref_phone_busn_fg :=NULL;
  ELSE
     l_pref_phone_busn_fg  := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,45);
  IF v_lpos=v_pos THEN
     l_od_phone_fax :=NULL;
  ELSE
     l_od_phone_fax  := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,46);
  IF v_lpos=v_pos THEN
     l_pref_phone_fax_fg :=NULL;
  ELSE
     l_pref_phone_fax_fg  := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,47);
  IF v_lpos=v_pos THEN
     l_od_phone_faxp  :=NULL;
  ELSE
     l_od_phone_faxp   := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,48);
  IF v_lpos=v_pos THEN
     l_pref_phone_faxp_fg :=NULL;
  ELSE
     l_pref_phone_faxp_fg  := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,49);
  IF v_lpos=v_pos THEN
     l_od_phone_main  :=NULL;
  ELSE
     l_od_phone_main   := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,50);
  IF v_lpos=v_pos THEN
     l_pref_phone_main_fg  :=NULL;
  ELSE
     l_pref_phone_main_fg   := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,51);
  IF v_lpos=v_pos THEN
     l_od_phone_mobb   :=NULL;
  ELSE
     l_od_phone_mobb    := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,52);
  IF v_lpos=v_pos THEN
     l_pref_phone_mobb_fg  :=NULL;
  ELSE
     l_pref_phone_mobb_fg   := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,53);
  IF v_lpos=v_pos THEN
     l_od_phone_mobp  :=NULL;
  ELSE
     l_od_phone_mobp   := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,54);
  IF v_lpos=v_pos THEN
     l_pref_phone_mobp_fg  :=NULL;
  ELSE
     l_pref_phone_mobp_fg   := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,55);
  IF v_lpos=v_pos THEN
     l_od_phone_pgr1  :=NULL;
  ELSE
    l_od_phone_pgr1   := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;

  v_lpos:=v_pos+1;
  v_pos :=INSTR(p_line_data,'|',1,56);
  IF v_lpos=v_pos THEN
     l_pref_phone_pgr1_fg  :=NULL;
  ELSE
     l_pref_phone_pgr1_fg   := TRIM(SUBSTR(p_line_data,v_lpos,v_pos-v_lpos));
  END IF;
  v_lpos:=v_pos+1;

  XX_HR_PS_STG_INSERT_PKG.INSERT_PROC (
              p_emplid                      => l_emplid,
              p_badge_nbr                   => l_badge_nbr,
              p_first_name	            => l_first_name,
              p_middle_name                 => l_middle_name,
              p_last_name                   => l_last_name,
              p_second_last_name	    => l_second_last_name,
              p_name_prefix                 => l_name_prefix,
              p_name_suffix                 => l_name_suffix,
              p_od_addeffdt                 => TO_DATE(l_od_addeffdtc,'MM/DD/YYYY'),
              p_sex                         => l_sex,
              p_address1                    => l_address1,
              p_address2	            => l_address2,
              p_address3	            => l_address3,
              p_city	                    => l_city,
              p_postal	                    => l_postal,
              p_county	                    => l_county,
              p_state                       => l_state,
              p_country                     => l_country,
              p_per_org                     => l_per_org,
              p_empl_status                 => l_empl_status,
              p_od_jobeffdt                 => TO_DATE(l_od_jobeffdtc,'MM/DD/YYYY'),
              p_hire_dt                     => TO_DATE(l_hire_dtc,'MM/DD/YYYY'),
              p_action	                    => l_action,
              p_setid_jobcode               => l_setid_jobcode,
              p_jobcode                     => l_jobcode,
              p_business_unit               => l_business_unit,
              p_setid_location              => l_setid_location,
              p_location	            => l_location,
              p_company                     => l_company,
              p_setid_dept                  => l_setid_dept,
              p_deptid                      => l_deptid,
              p_reg_region                  => l_reg_region,
              p_last_date_worked            => TO_DATE(l_last_date_workedc,'MM/DD/YYYY'),
              p_grade                       => l_grade,
              p_sal_admin_plan              => l_sal_admin_plan,
              p_supervisor_id               => l_supervisor_id,
              p_manager_level               => l_manager_level,
              p_job_entry_dt                => TO_DATE(l_job_entry_dtc,'MM/DD/YYYY'),
              p_job_function                => l_job_function,
              p_descr                       => l_descr,
              p_emailid                     => l_emailid,
              p_vendor_id                   => l_vendor_id,
              p_od_phone_busn               => l_od_phone_busn,
              p_pref_phone_busn_fg	    => l_pref_phone_busn_fg,
              p_od_phone_fax                => l_od_phone_fax,
              p_pref_phone_fax_fg           => l_pref_phone_fax_fg,
              p_od_phone_faxp               => l_od_phone_faxp,
              p_pref_phone_faxp_fg	    => l_pref_phone_faxp_fg,
              p_od_phone_main               => l_od_phone_main,
              p_pref_phone_main_fg	    => l_pref_phone_main_fg,
              p_od_phone_mobb               => l_od_phone_mobb,
              p_pref_phone_mobb_fg	    => l_pref_phone_mobb_fg,
              p_od_phone_mobp               => l_od_phone_mobp,
              p_pref_phone_mobp_fg	    => l_pref_phone_mobp_fg,
              p_od_phone_pgr1               => l_od_phone_pgr1,
              p_pref_phone_pgr1_fg	    => l_pref_phone_pgr1_fg,
              p_ins_trig_flag               => l_ins_trig_flag,
              p_ins_stg_flag     	    => l_ins_stg_flag,
              p_errbuff                     => l_msg_data,
              p_retcode                     => l_retcode      
            );

  IF (length(l_msg_data) > 0) THEN

      log_exception (
		      p_program_name             => 'XX_HR_PS_FULLSYNC_PKG'
        	     ,p_error_location           => 'process_line'
   	             ,p_error_status             => 'ERROR'
        	     ,p_oracle_error_code        => l_retcode
 	             ,p_oracle_error_msg         => l_msg_data
        	     ,p_error_message_severity   => 'MAJOR'
		    );
      FND_FILE.PUT_LINE(FND_FILE.LOG,l_msg_data);
      FND_FILE.PUT_LINE(FND_FILE.LOG,p_line_data);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_msg_data); 

  END IF;
EXCEPTION
  WHEN OTHERS THEN
    l_msg_data := 'Unknown Error, Line skipped... SQLCode: '||SQLCODE||'  Error Message: '||SQLERRM;
    log_exception (
		      p_program_name             => 'XX_HR_PS_FULLSYNC_PKG'
		     ,p_error_location           => 'process_line'
		     ,p_error_status             => 'ERROR'
		     ,p_oracle_error_code        => SQLCODE
		     ,p_oracle_error_msg         => l_msg_data
		     ,p_error_message_severity   => 'MAJOR'
		  );
    FND_FILE.PUT_LINE(FND_FILE.LOG,l_msg_data);
    FND_FILE.PUT_LINE(FND_FILE.LOG,p_line_data);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_msg_data);
END process_line;
END XX_HR_PS_FULLSYNC_PKG;
/
Show Errors
