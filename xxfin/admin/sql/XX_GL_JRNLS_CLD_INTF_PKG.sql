create or replace PACKAGE BODY XX_GL_JRNLS_CLD_INTF_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_GL_JRNLS_CLD_INTF_PKG                                                       |
  -- |                                                                                            |
  -- |  Description: This package body is load Oracle Cloud journals file into EBS Staging,Validate 
  -- |					and load into NA_STG Table.                                               |
  -- |  RICE ID   :  INT-046_Oracle Cloud GL Interface                 |
  -- |  Description:  load Oracle Cloud journals file into EBS Staging,Validate 				  |
  -- |					and load into NA_STG Table.                                               |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         12/08/2018   M K Pramod Kumar     Initial version                              |
  -- +============================================================================================+
  gc_package_name      CONSTANT all_objects.object_name%TYPE := 'XX_GL_JRNLS_CLD_INTF_PKG';
  gc_ret_success       CONSTANT VARCHAR2(20)                 := 'SUCCESS';
  gc_max_log_size      CONSTANT NUMBER                       := 2000;
  gc_max_err_buf_size  CONSTANT NUMBER                       := 250;
  gb_debug             BOOLEAN                               := FALSE;
  gn_file_batch_id              number;
  gn_org_id                     NUMBER                       := fnd_profile.VALUE ('ORG_ID');
  gn_set_of_bks_id              NUMBER                       := fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
  gn_chart_of_accounts_id number;


  --=================================================================
  -- Declaring Global variables
  --=================================================================

  gn_request_id               	NUMBER;
  gc_error_status_flag  		VARCHAR2(1);
  gc_debug						VARCHAR2(1):='N';
  gc_errbuf                   	VARCHAR2(2000) :=NULL;
  gn_retcode                  	NUMBER         :=0;
  gc_error_msg 					VARCHAR2(4000);
  g_user_id             		NUMBER                            := fnd_global.user_id;
  G_LOGIN_ID            		NUMBER                            := FND_GLOBAL.LOGIN_ID;


TYPE gt_input_parameters
IS
  TABLE OF VARCHAR2(32000) INDEX BY VARCHAR2(255);
TYPE gt_translation_values
IS
  TABLE OF xx_fin_translatevalues%ROWTYPE INDEX BY VARCHAR2(30);
Type gt_typ_output_DETAILS
IS
  record
  (
    REC_SEQUENCE NUMBER,
    Message1     VARCHAR2(200),
    Message2     VARCHAR2(200),
    Message3     VARCHAR2(200) );
TYPE gt_tbl_output_DETAILS
IS
  TABLE OF gt_typ_output_DETAILS INDEX BY BINARY_INTEGER;
  gt_rec_output_DETAILS gt_tbl_output_DETAILS;
  gt_rec_counter NUMBER:=0;
  lt_translation_info xx_fin_translatevalues%ROWTYPE;

  /*********************************************************************
  * Procedure used to log based on gb_debug value or if p_force is TRUE.
  * Will log to dbms_output if request id is not set,
  * else will log to concurrent program log file.  Will prepend
  * timestamp to each message logged.  This is useful for determining
  * elapse times.
  *********************************************************************/
PROCEDURE print_debug_msg(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT FAlse )
IS
  lc_message VARCHAR2(4000) := NULL;
BEGIN
  IF (gc_debug  = 'Y' OR p_force) THEN
    lc_message :=p_message;
    fnd_file.put_line(fnd_file.log,lc_message);
	 -- DBMS_OUTPUT.put_line(lc_message);
    IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
      DBMS_OUTPUT.PUT_LINE(lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS 
THEN
  fnd_file.put_line(fnd_file.log,'Error occured in Procedure-print_debug_msg. SQLERRM-'||sqlerrm );
END print_debug_msg;

    /*********************************************************************
  * Procedure used to print output based on if p_force is TRUE.
  * Will log to dbms_output if request id is not set,
  * else will log to concurrent program output file.  Will prepend
  *********************************************************************/
  PROCEDURE log_exception(
    p_program_name   IN VARCHAR2 ,
    p_error_location IN VARCHAR2 ,
    p_error_msg      IN VARCHAR2)
IS
  ln_login   NUMBER := FND_GLOBAL.LOGIN_ID;
  ln_user_id NUMBER := FND_GLOBAL.USER_ID;
BEGIN
   IF (fnd_global.conc_request_id > 0) THEN
      fnd_file.put_line(fnd_file.output, 'Program Name-'||p_program_name||'.Error location-'||p_error_location||'.Error Message-'||p_error_msg);
    ELSE
      DBMS_OUTPUT.put_line('Program Name-'||p_program_name||'.Error location-'||p_error_location||'.Error Message-'||p_error_msg);
    END IF;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| SQLERRM);
END log_exception;
  /*********************************************************************
  * Procedure used to print output based on if p_force is TRUE.
  * Will log to dbms_output if request id is not set,
  * else will log to concurrent program output file.  Will prepend
  *********************************************************************/
  PROCEDURE log_com_exception(
    p_program_name   IN VARCHAR2 ,
    p_error_location IN VARCHAR2 ,
    p_error_msg      IN VARCHAR2)
IS
  ln_login   NUMBER := FND_GLOBAL.LOGIN_ID;
  ln_user_id NUMBER := FND_GLOBAL.USER_ID;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error( p_return_code => FND_API.G_RET_STS_ERROR ,p_msg_count => 1 ,p_application_name => 'XXFIN' ,p_program_type => 'Custom Messages' ,p_program_name => p_program_name ,p_attribute15 => p_program_name ,p_program_id => NULL ,p_module_name => 'AR' ,p_error_location => p_error_location ,p_error_message_code => NULL ,p_error_message => p_error_msg ,p_error_message_severity => 'MAJOR' ,p_error_status => 'ACTIVE' ,p_created_by => ln_user_id ,p_last_updated_by => ln_user_id ,p_last_update_login => ln_login );
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| SQLERRM);
END log_com_exception;

  /*********************************************************************
  * Procedure used to print output based on if p_force is TRUE.
  * Will log to dbms_output if request id is not set,
  * else will log to concurrent program output file.  Will prepend
  *********************************************************************/
PROCEDURE print_output(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT True)
IS
  lc_message VARCHAR2(2000) := NULL;
BEGIN
  --if debug is on (defaults to true)
  IF p_force THEN
    lc_message                    := SUBSTR(p_message, 1, gc_max_log_size);
    IF (fnd_global.conc_request_id > 0) THEN
      fnd_file.put_line(fnd_file.output, lc_message);
    ELSE
      DBMS_OUTPUT.put_line(lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_output;
/*********************************************************************
* Procedure used to log based on gb_debug value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program log file.  Will prepend
* timestamp to each message logged.  This is useful for determining
* elapse times.
*********************************************************************/
PROCEDURE logit(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT TRUE)
IS
  lc_message VARCHAR2(2000) := NULL;
BEGIN
  --if debug is on (defaults to true)

  IF (gb_debug OR p_force) THEN
    lc_message := SUBSTR(TO_CHAR(SYSTIMESTAMP, 'MM/DD/YYYY HH24:MI:SS.FF') || ' => ' || p_message, 1, gc_max_log_size);
    -- if in concurrent program, print to log file
    IF (fnd_global.conc_request_id > 0) THEN
      fnd_file.put_line(fnd_file.LOG, lc_message);
      -- else print to DBMS_OUTPUT
    ELSE
      DBMS_OUTPUT.put_line(lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END logit;
/****************************************************************
* Helper procedure to log the exiting of a subprocedure.
* This is useful for debugging and for tracking how long a given
* procedure is taking.
****************************************************************/
PROCEDURE exiting_sub(
    p_procedure_name IN VARCHAR2,
    p_exception_flag IN BOOLEAN DEFAULT FALSE)
AS
BEGIN
  IF gb_debug THEN
    IF p_exception_flag THEN
      logit(p_message => 'Exiting Exception: ' || p_procedure_name);
      logit(p_message => 'Date Time Stamp: '||TO_CHAR(sysdate,'DD-MON-RR HH24:MI:SS'));
    ELSE
      logit(p_message => 'Exiting: ' || p_procedure_name);
      logit(p_message => 'Date Time Stamp: '||TO_CHAR(sysdate,'DD-MON-RR HH24:MI:SS'));
    END IF;
    logit(p_message => '-----------------------------------------------');
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END exiting_sub;
/***********************************************
*  Setter procedure for gb_debug global variable
*  used for controlling debugging
***********************************************/
PROCEDURE set_debug(
    p_debug_flag IN VARCHAR2)
IS
BEGIN
  IF (UPPER(p_debug_flag) IN('Y', 'YES', 'T', 'TRUE')) THEN
    gb_debug := TRUE;
  END IF;
END set_debug;
/**********************************************************************
* Helper procedure to log the sub procedure/function name that has been
* called and logs the input parameters passed to it.
***********************************************************************/
PROCEDURE entering_sub(
    p_procedure_name IN VARCHAR2,
    p_parameters     IN gt_input_parameters)
AS
  ln_counter           NUMBER          := 0;
  lc_current_parameter VARCHAR2(32000) := NULL;
BEGIN
  IF gb_debug THEN
    logit(p_message => '-----------------------------------------------');
    logit(p_message => 'Entering: ' || p_procedure_name);
    logit(p_message => 'Date Time Stamp: '||TO_CHAR(sysdate,'DD-MON-RR HH24:MI:SS'));
    lc_current_parameter := p_parameters.FIRST;
    IF p_parameters.COUNT > 0 THEN
      logit(p_message => 'Input parameters:');
      LOOP
        EXIT
      WHEN lc_current_parameter IS NULL;
        ln_counter              := ln_counter + 1;
        logit(p_message => ln_counter || '. ' || lc_current_parameter || ' => ' || p_parameters(lc_current_parameter));
        lc_current_parameter := p_parameters.NEXT(lc_current_parameter);
      END LOOP;
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END entering_sub;
/******************************************************************
* Helper procedure to log that the main procedure/function has been
* called. Sets the debug flag and calls entering_sub so that
* it logs the procedure name and the input parameters passed in.
******************************************************************/
PROCEDURE entering_main(
    p_procedure_name  IN VARCHAR2,
    p_rice_identifier IN VARCHAR2,
    p_debug_flag      IN VARCHAR2,
    p_parameters      IN gt_input_parameters)
AS
BEGIN
  set_debug(p_debug_flag => p_debug_flag);
  IF gb_debug THEN
    IF p_rice_identifier IS NOT NULL THEN
      logit(p_message => '-----------------------------------------------');
      logit(p_message => '-----------------------------------------------');
      logit(p_message => 'RICE ID: ' || p_rice_identifier);
      logit(p_message => '-----------------------------------------------');
      logit(p_message => '-----------------------------------------------');
    END IF;
    entering_sub(p_procedure_name => p_procedure_name, p_parameters => p_parameters);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END entering_main;


-- +============================================================================================+
-- |  Name  : parse_datafile_line                                                                 |
-- |  Description: Procedure to parse delimited string and load them into table                 |
-- =============================================================================================|
PROCEDURE parse_datafile_line(
    p_delimstring IN VARCHAR2 ,
    p_table OUT varchar2_table ,
    p_nfields OUT INTEGER ,
    p_delim IN VARCHAR2 DEFAULT chr(124) ,
    p_error_msg OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2)
IS
  l_string VARCHAR2(32767) := p_delimstring;
  l_nfields pls_integer    := 1;
  l_table varchar2_table;
  l_delimpos pls_integer := instr(p_delimstring, p_delim);
  l_delimlen pls_integer := LENGTH(p_delim);
BEGIN
  WHILE l_delimpos > 0
  LOOP
    l_table(l_nfields) := replace(SUBSTR(l_string,1,l_delimpos-1),chr(34),'');
    l_string           := SUBSTR(l_string,l_delimpos  +l_delimlen);
    l_nfields          := l_nfields                   +1;
    l_delimpos         := instr(l_string, p_delim);
  END LOOP;
  l_table(l_nfields) := replace(l_string,chr(34),'');
  p_table            := l_table;
  p_nfields          := l_nfields;


EXCEPTION
WHEN OTHERS THEN
  p_retcode   := '2';
  p_error_msg := 'Error in XX_GL_JRNLS_CLD_INTF_PKG.parse_line - record:'||SUBSTR(p_delimstring,150)||SUBSTR(sqlerrm,1,150);
END parse_datafile_line;







-- +============================================================================================+
-- |  Name  : CREATE_JOURNAL_BATCH                                                             |
-- |  Description: This procedure reads data from the Staging table and inserts into        |
-- =============================================================================================|
PROCEDURE CREATE_JOURNAL_BATCH(
    p_process_name VARCHAR2,
    p_debug_flag   VARCHAR2,
	p_errbuf OUT nocopy  VARCHAR2 ,
    p_retcode OUT nocopy NUMBER )
IS
 lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'CREATE_JOURNAL_BATCH';
 lv_filerec_count Number:=0;

  cursor cur_file_batch is   
  select distinct xfile.file_batch_id,stg.EBS_LEDGER_NAME,stg.EBS_JOURNAL_SOURCE
  from  
	XX_GL_JRNLS_CLD_INTF_STG stg,
	XX_GL_JRNLS_CLD_INTF_FILES xfile
  where xfile.record_status='V'
  and xfile.process_name=p_process_name
  and stg.file_batch_id=xfile.file_batch_id
  and stg.RECORD_STATUS in ('V')
  and stg.action in ('VALID')
and stg.ebs_journal_source
not in 
(
SELECT 
      xftv.target_value1
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv
    WHERE xftd.translation_name ='OD_CLD_GL_JRNLS_APP_MAP'
    AND xftv.source_value1      = 'Application_Name'
    AND xftd.translate_id       =xftv.translate_id
    AND xftd.enabled_flag       ='Y'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate))
	group by xfile.file_batch_id,stg.EBS_LEDGER_NAME,stg.EBS_JOURNAL_SOURCE
  ;


    cursor cur_pa_file_batch is   
  select  distinct xfile.file_batch_id,stg.EBS_LEDGER_NAME,stg.EBS_JOURNAL_SOURCE,stg.TRANSACTION_NUMBER
  from  
	XX_GL_JRNLS_CLD_INTF_STG stg,
	XX_GL_JRNLS_CLD_INTF_FILES xfile
  where xfile.record_status in ('V','I') --added I status as AP file can have PA transacitons.
  and xfile.process_name=p_process_name
  and stg.file_batch_id=xfile.file_batch_id
  and stg.RECORD_STATUS in ('V')
  and stg.action in ('VALID')
and stg.ebs_journal_source
 in 
(
SELECT 
      xftv.target_value1
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv
    WHERE xftd.translation_name ='OD_CLD_GL_JRNLS_APP_MAP'
   AND xftv.source_value1      = 'Application_Name'
    AND xftd.translate_id       =xftv.translate_id
    AND xftd.enabled_flag       ='Y'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate))
	group by xfile.file_batch_id,stg.EBS_LEDGER_NAME,stg.EBS_JOURNAL_SOURCE,stg.TRANSACTION_NUMBER
  ;


  cursor cur_gl_journals_batch(p_file_batch_id number,p_ledger_name varchar2,p_journal_source varchar2) is   
  select xfile.* ,rowid
  from  
     XX_GL_JRNLS_CLD_INTF_STG xfile
  where 1=1
  and file_batch_id=p_file_batch_id
  and process_name=p_process_name
  and RECORD_STATUS in ('V')
  and action in ('VALID')
  and ebs_ledger_name=p_ledger_name
  and ebs_journal_source=p_journal_source;


  TYPE lv_gl_journals_batch_tab IS TABLE OF cur_gl_journals_batch%ROWTYPE 
         INDEX BY BINARY_INTEGER;
		 lv_gl_journals_batch_data                  lv_gl_journals_batch_tab;	


		  cursor cur_pa_gl_journals_batch(p_file_batch_id number,p_ledger_name varchar2,p_journal_source varchar2,p_transaction_number varchar2) is   
  select xfile.* ,rowid
  from  
     XX_GL_JRNLS_CLD_INTF_STG xfile
  where 1=1
  and file_batch_id=p_file_batch_id
  and process_name=p_process_name
  and RECORD_STATUS in ('V')
  and action in ('VALID')
  and ebs_ledger_name=p_ledger_name
  and ebs_journal_source=p_journal_source
   and transaction_number=p_transaction_number;

  TYPE lv_pa_gl_journals_batch_tab IS TABLE OF cur_pa_gl_journals_batch%ROWTYPE 
         INDEX BY BINARY_INTEGER;
		 lv_pa_gl_journals_batch_data                  lv_pa_gl_journals_batch_tab;	

  ln_group_id           NUMBER;
  lc_dr_msg varchar2(1000);
  lc_cr_msg varchar2(1000);
  l_resp_id number;
  l_app_id number;

  lc_ap_ccid_acct varchar2(100);
  ln_ap_ccid number;
  ex_recon_batch_exception Exception;
  lc_error_status_flag varchar2(1):='N';
Begin


  print_debug_msg(p_message=> 'Begin Creat Cloude GL Interface Batch Procedure for GL Transactions',p_force=> true);
  print_debug_msg(p_message=> 'Assigning Defaults' ,p_force=> false);
  --==========================================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==========================================================================================



  for rec in cur_file_batch loop

   print_debug_msg(p_message=> 'Processing File Batch Id:'||rec.file_batch_id||',EBS Ledger Name:'||rec.EBS_LEDGER_NAME||'Journal Source:'||rec.EBS_JOURNAL_SOURCE,p_force=> true);

  lc_error_status_flag := 'N';

		SELECT gl_interface_control_s.NEXTVAL
		INTO ln_group_id
		FROM DUAL;


    OPEN cur_gl_journals_batch(rec.file_batch_id,rec.EBS_LEDGER_NAME,rec.EBS_JOURNAL_SOURCE);
			Loop
			FETCH cur_gl_journals_batch
				BULK COLLECT INTO lv_gl_journals_batch_data LIMIT 5000;
				EXIT WHEN lv_gl_journals_batch_data.COUNT = 0;

					FOR idx IN lv_gl_journals_batch_data.FIRST .. lv_gl_journals_batch_data.LAST
					LOOP


					if p_process_name='FIN' then
						if lc_error_status_flag = 'N' then 
								xx_gl_interface_pkg.create_stg_jrnl_line(
                                                 p_status => 'NEW'
                                               , p_date_created => SYSDATE
                                               , p_created_by => g_user_id
                                               , p_actual_flag => 'A'
                                               , p_group_id => ln_group_id
                                               , p_batch_name => lv_gl_journals_batch_data(idx).accounting_date
                                               , p_batch_desc => ' '
                                               , p_user_source_name => lv_gl_journals_batch_data(idx).EBS_JOURNAL_SOURCE
                                               , p_user_catgory_name => lv_gl_journals_batch_data(idx).EBS_JOURNAL_CATEGORY
                                               , p_set_of_books_id => gn_set_of_bks_id --cur.set_of_books_id
                                               , p_accounting_date => NVL(lv_gl_journals_batch_data(idx).accounting_date,SYSDATE)
                                               , p_currency_code => lv_gl_journals_batch_data(idx).currency_code
                                               , p_company => lv_gl_journals_batch_data(idx).segment1
                                               , p_cost_center =>lv_gl_journals_batch_data(idx).segment2
                                               , p_account => lv_gl_journals_batch_data(idx).segment3
                                               , p_location => lv_gl_journals_batch_data(idx).segment4
                                               , p_intercompany => lv_gl_journals_batch_data(idx).segment5
                                               , p_channel => lv_gl_journals_batch_data(idx).segment6
                                               , p_future => lv_gl_journals_batch_data(idx).segment7
											   , p_ccid                   => null
                                               , p_entered_dr => lv_gl_journals_batch_data(idx).ENTERED_DR
                                               , p_entered_cr => lv_gl_journals_batch_data(idx).ENTERED_CR
                                               , p_je_name => NULL
                                               , p_je_reference => ln_group_id
                                               , p_je_line_dsc =>lv_gl_journals_batch_data(idx).LINE_DESCRIPTION
                                               , x_output_msg => lc_cr_msg
                                               );

						end if;	

						if  lc_cr_msg IS NOT NULL THEN
							lc_error_status_flag := 'Y'; 
							print_debug_msg(p_message => 'Error while creating Journal line during procedure call xx_gl_interface_pkg.create_stg_jrnl_line:'||lc_cr_msg , p_force => TRUE);

							Update XX_GL_JRNLS_CLD_INTF_STG set record_status='E',
							action='ERROR',
							error_description=ERROR_DESCRIPTION||'~''Error while creating Journal line during procedure call xx_gl_interface_pkg.create_stg_jrnl_line-'||lc_cr_msg
							where file_batch_id=gn_file_batch_id	
							and rowid=lv_gl_journals_batch_data(idx).rowid;

						END IF;                               

					else
					    if lc_error_status_flag = 'N' then 
								xx_gl_interface_pkg.create_stg_jrnl_line(
                                                 p_status => 'NEW'
                                               , p_date_created => SYSDATE
                                               , p_created_by => g_user_id
                                               , p_actual_flag => 'A'
                                               , p_group_id => ln_group_id
                                               , p_batch_name => lv_gl_journals_batch_data(idx).accounting_date
                                               , p_batch_desc => ' '
                                               , p_user_source_name => lv_gl_journals_batch_data(idx).EBS_JOURNAL_SOURCE
                                               , p_user_catgory_name => lv_gl_journals_batch_data(idx).EBS_JOURNAL_CATEGORY
                                               , p_set_of_books_id => gn_set_of_bks_id 
                                               , p_accounting_date => NVL(lv_gl_journals_batch_data(idx).accounting_date,SYSDATE)
                                               , p_currency_code => lv_gl_journals_batch_data(idx).currency_code
                                               , p_company => lv_gl_journals_batch_data(idx).segment1
                                               , p_cost_center =>lv_gl_journals_batch_data(idx).segment2
                                               , p_account => lv_gl_journals_batch_data(idx).segment3
                                               , p_location => lv_gl_journals_batch_data(idx).segment4
                                               , p_intercompany => lv_gl_journals_batch_data(idx).segment5
                                               , p_channel => lv_gl_journals_batch_data(idx).segment6
                                               , p_future => lv_gl_journals_batch_data(idx).segment7
											   , p_ccid                   => null
                                               , p_entered_dr => lv_gl_journals_batch_data(idx).ENTERED_DR
                                               , p_entered_cr => lv_gl_journals_batch_data(idx).ENTERED_CR
                                               , p_je_name => NULL
                                               , p_je_reference => ln_group_id
                                               , p_je_line_dsc => lv_gl_journals_batch_data(idx).reference10
                                               , x_output_msg => lc_cr_msg
                                               );

						end if;	

						if  lc_cr_msg IS NOT NULL THEN
							lc_error_status_flag := 'Y'; 
							print_debug_msg(p_message => 'Error while creating Journal line during procedure call xx_gl_interface_pkg.create_stg_jrnl_line:'||lc_cr_msg , p_force => TRUE);

							Update XX_GL_JRNLS_CLD_INTF_STG set record_status='E',
							action='ERROR',
							error_description=ERROR_DESCRIPTION||'~''Error while creating Journal line during procedure call xx_gl_interface_pkg.create_stg_jrnl_line-'||lc_cr_msg
							where file_batch_id=gn_file_batch_id	
							and rowid=lv_gl_journals_batch_data(idx).rowid;

						END IF;  


					end if;
                    END LOOP; 
		    END LOOP;
			close cur_gl_journals_batch;

			if lc_error_status_flag='N' then

				 print_debug_msg(p_message=> 'Processing File Batch Id:'||rec.file_batch_id||',EBS Ledger Name:'||rec.EBS_LEDGER_NAME||'Journal Source:'||rec.EBS_JOURNAL_SOURCE,p_force=> true);
				Update XX_GL_JRNLS_CLD_INTF_STG set record_status='I',
				action='INSERT'
				where file_batch_id=rec.file_batch_id	
				and EBS_LEDGER_NAME=rec.EBS_LEDGER_NAME
				and EBS_JOURNAL_SOURCE=rec.EBS_JOURNAL_SOURCE;


				Update XX_GL_JRNLS_CLD_INTF_FILES
				set record_status='I'
				where file_batch_id=rec.file_batch_id;
				commit;

			else
			  Rollback;
			    Update XX_GL_JRNLS_CLD_INTF_STG set record_status='I',
				action='INSERT'
				where file_batch_id=gn_file_batch_id	
				and EBS_LEDGER_NAME=rec.EBS_LEDGER_NAME
				and EBS_JOURNAL_SOURCE=rec.EBS_JOURNAL_SOURCE
				;

				Update XX_GL_JRNLS_CLD_INTF_FILES
				set record_status='I',
				error_description=ERROR_DESCRIPTION||'~Error occured while processing the file-There are errors in STG Table'
				where file_batch_id=rec.file_batch_id;
				commit;
			end if;


  END LOOP;



   for rec in cur_pa_file_batch loop

   print_debug_msg(p_message=> 'Processing File Batch Id:'||rec.file_batch_id||',EBS Ledger Name:'||rec.EBS_LEDGER_NAME||'Journal Source:'||rec.EBS_JOURNAL_SOURCE,p_force=> true);

   lc_error_status_flag := 'N';

		SELECT gl_interface_control_s.NEXTVAL
		INTO ln_group_id
		FROM DUAL;

    OPEN cur_pa_gl_journals_batch(rec.file_batch_id,rec.EBS_LEDGER_NAME,rec.EBS_JOURNAL_SOURCE,rec.transaction_number);
			Loop
			FETCH cur_pa_gl_journals_batch
				BULK COLLECT INTO lv_pa_gl_journals_batch_data LIMIT 5000;
				EXIT WHEN lv_pa_gl_journals_batch_data.COUNT = 0;

					FOR idx IN lv_pa_gl_journals_batch_data.FIRST .. lv_pa_gl_journals_batch_data.LAST
					LOOP


						if lc_error_status_flag = 'N' then 
								xx_gl_interface_pkg.create_stg_jrnl_line(
                                                 p_status => 'NEW'
                                               , p_date_created => SYSDATE
                                               , p_created_by => g_user_id
                                               , p_actual_flag => 'A'
                                               , p_group_id => ln_group_id
                                               , p_batch_name => lv_pa_gl_journals_batch_data(idx).accounting_date
                                               , p_batch_desc => ' '
                                               , p_user_source_name => lv_pa_gl_journals_batch_data(idx).EBS_JOURNAL_SOURCE
                                               , p_user_catgory_name => lv_pa_gl_journals_batch_data(idx).EBS_JOURNAL_CATEGORY
                                               , p_set_of_books_id => gn_set_of_bks_id --cur.set_of_books_id
                                               , p_accounting_date => NVL(lv_pa_gl_journals_batch_data(idx).accounting_date,SYSDATE)
                                               , p_currency_code => lv_pa_gl_journals_batch_data(idx).currency_code
                                               , p_company => lv_pa_gl_journals_batch_data(idx).segment1
                                               , p_cost_center =>lv_pa_gl_journals_batch_data(idx).segment2
                                               , p_account => lv_pa_gl_journals_batch_data(idx).segment3
                                               , p_location => lv_pa_gl_journals_batch_data(idx).segment4
                                               , p_intercompany => lv_pa_gl_journals_batch_data(idx).segment5
                                               , p_channel => lv_pa_gl_journals_batch_data(idx).segment6
                                               , p_future => lv_pa_gl_journals_batch_data(idx).segment7
											   , p_ccid                   => null
                                               , p_entered_dr => lv_pa_gl_journals_batch_data(idx).ENTERED_DR
                                               , p_entered_cr => lv_pa_gl_journals_batch_data(idx).ENTERED_CR
                                               , p_je_name => NULL
                                               , p_je_reference => ln_group_id
                                               , p_je_line_dsc =>lv_pa_gl_journals_batch_data(idx).transaction_number||'~'||lv_pa_gl_journals_batch_data(idx).LINE_DESCRIPTION
                                               , x_output_msg => lc_cr_msg
                                               );

						end if;	

						if  lc_cr_msg IS NOT NULL THEN
							lc_error_status_flag := 'Y'; 
							print_debug_msg(p_message => 'Error while creating Journal line during procedure call xx_gl_interface_pkg.create_stg_jrnl_line:'||lc_cr_msg , p_force => TRUE);

							Update XX_GL_JRNLS_CLD_INTF_STG set record_status='E',
							action='ERROR',
							error_description=ERROR_DESCRIPTION||'~''Error while creating Journal line during procedure call xx_gl_interface_pkg.create_stg_jrnl_line-'||lc_cr_msg
							where file_batch_id=gn_file_batch_id	
							and rowid=lv_gl_journals_batch_data(idx).rowid;

						END IF;                               



                    END LOOP; 
		    END LOOP;

		close cur_pa_gl_journals_batch;

			if lc_error_status_flag='N' then

				print_debug_msg(p_message=> 'Processing complete for File Batch Id:'||rec.file_batch_id||',EBS Ledger Name:'||rec.EBS_LEDGER_NAME||'Journal Source:'||rec.EBS_JOURNAL_SOURCE,p_force=> true);			
				Update XX_GL_JRNLS_CLD_INTF_STG set record_status='I',
				action='INSERT'
				where file_batch_id=rec.file_batch_id	
				and EBS_LEDGER_NAME=rec.EBS_LEDGER_NAME
				and EBS_JOURNAL_SOURCE=rec.EBS_JOURNAL_SOURCE				
				and TRANSACTION_NUMBER=rec.transaction_number
				;

				Update XX_GL_JRNLS_CLD_INTF_FILES
				set record_status='I'
				where file_batch_id=rec.file_batch_id;
				commit;

			else
			  Rollback;
			    Update XX_GL_JRNLS_CLD_INTF_STG set record_status='E',
				action='INSERT'
				where file_batch_id=gn_file_batch_id	
				and EBS_LEDGER_NAME=rec.EBS_LEDGER_NAME
				and EBS_JOURNAL_SOURCE=rec.EBS_JOURNAL_SOURCE
				and TRANSACTION_NUMBER=rec.transaction_number;

				Update XX_GL_JRNLS_CLD_INTF_FILES
				set record_status='I',
				error_description=ERROR_DESCRIPTION||'~Error occured while processing the file-There are errors in STG Table'
				where file_batch_id=rec.file_batch_id;
				commit;
			end if;


  END LOOP;



 EXCEPTION
    WHEN ex_recon_batch_exception THEN
	logit(p_message => 'Error occured during xx_gl_interface_pkg.create_stg_jrnl_line-lc_cr_msg'||lc_cr_msg, p_force => TRUE);
    p_retcode := 2;
    p_ERRBUF  := 'Error occured during xx_gl_interface_pkg.create_stg_jrnl_line-lc_cr_msg'||lc_cr_msg;
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);

WHEN OTHERS THEN
  logit(p_message => 'ERROR-SQLCODE:'|| SQLCODE || ' SQLERRM: ' || SQLERRM, p_force => TRUE);
    p_retcode := 2;
    p_ERRBUF  := 'Exception in XX_GL_JRNLS_CLD_INTF_PKG.CREATE_FILE_BATCH() - '||SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  logit('Error in CREATE_JOURNAL_BATCH'||sqlerrm );
End CREATE_JOURNAL_BATCH;



--+===============================================================================+
--| Name          : VAL_CLD_GL_INTF_FILE                                   |
--| Description   : This procedure will validate  GL Journal records in staging table|
--|                                                                               |
--| Parameters    : x_ret_code OUT NUMBER ,                                       |
--|                 x_return_status OUT VARCHAR2 ,                                |
--|                 x_err_buf OUT VARCHAR2                                        |
--|                                                                               |
--| Returns       : N/A                                                           |
--|                                                                               |
--+===============================================================================+
PROCEDURE VAL_CLD_GL_INTF_FILE
	(
    p_process_name VARCHAR2,
    p_debug_flag   VARCHAR2,
	p_errbuf  OUT nocopy  VARCHAR2 ,
    p_retcode OUT nocopy NUMBER )

IS
  l_ret_code      NUMBER;
  l_return_status VARCHAR2 (100);
  l_err_buff      VARCHAR2 (4000);
  l_error_message VARCHAR2(4000) := '';
  lc_ccid_acct varchar2(100);
  lv_derived_ccid number;


  --==========================================================================================
  -- Cursor Declarations for Application Name Validation
  --==========================================================================================
  cursor cur_application_name is 

  select distinct application_name from 
  XX_GL_JRNLS_CLD_INTF_STG 
  where 1=1
  and file_batch_id=gn_file_batch_id
  and RECORD_STATUS in ('N','E')
  and action in ('NEW','VALID_ERROR');

  TYPE lv_application_name_tab IS TABLE OF cur_application_name%ROWTYPE 
         INDEX BY BINARY_INTEGER;	

		 lv_application_name_data                  lv_application_name_tab;	

  --==========================================================================================
  -- Cursor Declarations for Ledger Name Validation
  --==========================================================================================
  cursor cur_ledger_name is 

  select distinct ledger_name from 
  XX_GL_JRNLS_CLD_INTF_STG 
  where 1=1
  and file_batch_id=gn_file_batch_id
  and RECORD_STATUS in ('N','E')
  and action in ('NEW','VALID_ERROR');

  TYPE lv_ledger_name_tab IS TABLE OF cur_ledger_name%ROWTYPE 
         INDEX BY BINARY_INTEGER;	

  lv_ledger_name_data                  lv_ledger_name_tab;	


  --==========================================================================================
  -- Cursor Declarations for Currency Code Validation
  --==========================================================================================
  cursor cur_currency_code is 

  select distinct currency_code from 
  XX_GL_JRNLS_CLD_INTF_STG 
  where 1=1
  and file_batch_id=gn_file_batch_id
  and RECORD_STATUS in ('N','E')
  and action in ('NEW','VALID_ERROR');

  TYPE lv_currency_code_tab IS TABLE OF cur_currency_code%ROWTYPE 
         INDEX BY BINARY_INTEGER;	

  lv_currency_code_data                  lv_currency_code_tab;		 


 --==========================================================================================
  -- Cursor Declarations for JE Category Name Validation
  --==========================================================================================
  cursor cur_user_category_name is   
  select distinct USER_JE_CATEGORY_NAME from 
  XX_GL_JRNLS_CLD_INTF_STG 
  where 1=1
  and file_batch_id=gn_file_batch_id
  and RECORD_STATUS in ('N','E')
  and action in ('NEW','VALID_ERROR');

  TYPE lv_user_catg_name_tab IS TABLE OF cur_user_category_name%ROWTYPE 
         INDEX BY BINARY_INTEGER;	

		 lv_user_catg_name_data                  lv_user_catg_name_tab;	


 --==========================================================================================
  -- Cursor Declarations for JE Category Name Validation
  --==========================================================================================
  cursor cur_user_je_sourcE_name is   
  select distinct user_je_source_name from 
  XX_GL_JRNLS_CLD_INTF_STG 
  where 1=1
  and file_batch_id=gn_file_batch_id
  and RECORD_STATUS in ('N','E')
  and action in ('NEW','VALID_ERROR');

  TYPE lv_user_je_sourcE_name_tab IS TABLE OF cur_user_je_sourcE_name%ROWTYPE  
         INDEX BY BINARY_INTEGER;	

		 lv_user_je_sourcE_name_data                  lv_user_je_sourcE_name_tab;	


 --==========================================================================================
  -- Cursor Declarations for Debits and Credits Balanced
  --==========================================================================================
  cursor cur_jrnls_dr_cr_bal is   
  select ebs_ledger_name,application_name,USER_JE_CATEGORY_NAME,ae_header_id,  sum(NVL(entered_dr,0)) total_dr,
  sum(NVL(entered_cr,0)) total_cr,
  sum(NVL(accounted_dr,0)) total_acc_dr,
   sum(NVL(accounted_cr,0)) total_acc_cr  
from  
XX_GL_JRNLS_CLD_INTF_STG 
  where 1=1
  and file_batch_id=gn_file_batch_id
  and RECORD_STATUS in ('N','E')
  and action in ('NEW','VALID_ERROR')  
  group by ebs_ledger_name,application_name,USER_JE_CATEGORY_NAME,ae_header_id;


  TYPE lv_jrnls_dr_cr_bal_tab IS TABLE OF cur_jrnls_dr_cr_bal%ROWTYPE 
         INDEX BY BINARY_INTEGER;	

		 lv_jrnls_dr_cr_bal_data                  lv_jrnls_dr_cr_bal_tab;

--==========================================================================================
  -- Cursor Declarations for Debits and Credits Balanced for SCM Transactions
  --==========================================================================================
  cursor cur_jrnls_dr_cr_bal_scm is   
  select ebs_ledger_name,reference10,  sum(NVL(entered_dr,0)) total_dr,
  sum(NVL(entered_cr,0)) total_cr,
  sum(NVL(accounted_dr,0)) total_acc_dr,
   sum(NVL(accounted_cr,0)) total_acc_cr  
from  
XX_GL_JRNLS_CLD_INTF_STG 
  where 1=1
  and file_batch_id=gn_file_batch_id
  and RECORD_STATUS in ('N','E')
  and action in ('NEW','VALID_ERROR')  
  group by ebs_ledger_name,reference10;


  TYPE lv_jrnls_dr_cr_bal_scm_tab IS TABLE OF cur_jrnls_dr_cr_bal_scm%ROWTYPE 
         INDEX BY BINARY_INTEGER;	

		 lv_jrnls_dr_cr_bal_scm_data                  lv_jrnls_dr_cr_bal_scm_tab;


  --==========================================================================================
  -- Cursor to check if any CTU Mapping issues
  --==========================================================================================
  cursor cur_select_segments is   
  select segment1,segment2,segment3,segment4,segment5,segment6,rowid from 
  XX_GL_JRNLS_CLD_INTF_STG 
  where 1=1
  and file_batch_id=gn_file_batch_id
  and RECORD_STATUS in ('N','E')
  and action in ('NEW','VALID_ERROR');

   TYPE lv_cur_select_segments_tab IS TABLE OF cur_select_segments%ROWTYPE 
         INDEX BY BINARY_INTEGER;	

		 lv_cur_select_segments_data                  lv_cur_select_segments_tab;	

  --==========================================================================================
  -- Cursor to derive Code Combination Id 
  --==========================================================================================
  cursor cur_derive_ccid is   
  select rowid,stg.* from 
  XX_GL_JRNLS_CLD_INTF_STG stg
  where 1=1
  and file_batch_id=gn_file_batch_id
  and RECORD_STATUS in ('N','E')
  and action in ('NEW','VALID_ERROR');

  TYPE lv_derive_ccid_tab IS TABLE OF cur_derive_ccid%ROWTYPE 
         INDEX BY BINARY_INTEGER;	

		 lv_derive_ccid_data                  lv_derive_ccid_tab;		 

     lv_record number;
	 lv_error_message varchar2(2000);
	 lv_derived_column varchar2(100);
	 lv_je_category varchar2(100);
	 lv_je_source varchar2(100);

	 cursor file_batch is 
	 select * From XX_GL_JRNLS_CLD_INTF_FILES xfile
	 where xfile.record_status='N'	
	  and process_name=p_process_name
	  ;
	  lv_error_loc varchar2(1000) :=null;



BEGIN
  print_debug_msg(p_message=> 'Begin Validate Cloud GL Interface Financial Transactions',p_force=> true);

  for file_rec in file_batch loop 

    lv_error_loc:='File Batch Loop begins, Setting Defaults';
  --==========================================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==========================================================================================
  gc_error_status_flag := 'N';
  l_error_message      := NULL;
  gc_error_msg         := '';
  l_ret_code           := 0;
  l_return_status      := 'S';
  l_err_buff           := NULL;
  gn_file_batch_id:=file_rec.file_batch_id;

  logit(p_message =>'gn_file_batch_id:'||gn_file_batch_id);
  logit(p_message =>'file_rec.gn_file_batch_id:'||file_rec.file_batch_id);

   --==========================================================================================
  -- Cursor Declarations for Ledger Name Validation
  --==========================================================================================
  lv_error_loc:='Ledger Name Validation begins';

 OPEN cur_ledger_name;
			Loop
			FETCH cur_ledger_name 
				BULK COLLECT INTO lv_ledger_name_data LIMIT 5000;
				EXIT WHEN lv_ledger_name_data.COUNT = 0;

					FOR idx IN lv_ledger_name_data.FIRST .. lv_ledger_name_data.LAST
					LOOP
					
					lv_error_message:=null;
			            Begin
						  select 1 into lv_record from gl_ledgers 
						  where name=decode(lv_ledger_name_data(idx).ledger_name,'OD US Primary USD','US USD Corp GAAP Primary','OD CA Primary CAD','CA CAD Corp GAAP Primary',lv_ledger_name_data(idx).ledger_name);

						  Update XX_GL_JRNLS_CLD_INTF_STG 
						  set EBS_LEDGER_NAME=decode(lv_ledger_name_data(idx).ledger_name,'OD US Primary USD','US USD Corp GAAP Primary','OD CA Primary CAD','CA CAD Corp GAAP Primary',lv_ledger_name_data(idx).ledger_name)
						  where 1=1
						  and file_batch_id=gn_file_batch_id
							 and ledger_name=lv_ledger_name_data(idx).ledger_name;

						 Exception 
						 when no_data_found then

							 gc_error_status_flag:='Y';
							 lv_error_message :=lv_error_message||'~'||'Oracle Cloud Ledger Name not found';
						  when others then
						    gc_error_status_flag:='Y';
							lv_error_message:=lv_error_message||'~'||'Validation error-Ledger not found. SQLERRM-'||sqlerrm;    

						 end;

						 if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=ERROR_DESCRIPTION||'~'||lv_error_message
								where 1=1
								and file_batch_id=gn_file_batch_id
								and application_name=lv_ledger_name_data(idx).ledger_name;
								gc_error_status_flag:='N';
						end if;


					end loop;
			end loop;

	close cur_ledger_name;

  if p_process_name='FIN' then

  --==========================================================================================
  -- Cursor Declarations for Application Name Validation
  --==========================================================================================
  gc_error_status_flag:='N';
  lv_error_loc:='Application Name Validation begins for FIN Transactions';
   OPEN cur_application_name;
			Loop
			FETCH cur_application_name 
				BULK COLLECT INTO lv_application_name_data LIMIT 5000;
				EXIT WHEN lv_application_name_data.COUNT = 0;

					FOR idx IN lv_application_name_data.FIRST .. lv_application_name_data.LAST
					LOOP
					 lv_derived_column:=null;
					 lv_error_message:=null;
			            Begin
						  select application_name into lv_derived_column from fnd_application_vl 
						  where application_name=lv_application_name_data(idx).application_name;

						  Update XX_GL_JRNLS_CLD_INTF_STG set 
						     ebs_application_name=lv_derived_column
							 where 1=1
							 and file_batch_id=gn_file_batch_id
							 and application_name=lv_application_name_data(idx).application_name;

						Exception 
						 when no_data_found then 
							 gc_error_status_flag:='Y';
							 lv_error_message :=lv_error_message||'~'||'Application Name not found';
						 when others then 
						  lv_error_message:=lv_error_message||'~'||'Validation error-Applicaiton not found. SQLERRM-'||sqlerrm;						    
						  gc_error_status_flag:='Y';
						end;				 

						if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=ERROR_DESCRIPTION||'~'||lv_error_message
								where 1=1
								and file_batch_id=gn_file_batch_id
								and application_name=lv_application_name_data(idx).application_name;
								gc_error_status_flag:='N';
						end if;

					end loop;
			end loop;

     close cur_application_name;

  --==========================================================================================
  -- Cursor Declarations for Joural Sourace Validation
  --==========================================================================================
	 gc_error_status_flag:='N';
	 lv_error_loc:='Journal Source Name Validation begins for FIN Transactions';	  
			OPEN cur_user_je_sourcE_name;
			Loop
			FETCH cur_user_je_sourcE_name 
				BULK COLLECT INTO lv_user_je_sourcE_name_data LIMIT 5000;
				EXIT WHEN lv_user_je_sourcE_name_data.COUNT = 0;

					FOR idx IN lv_user_je_sourcE_name_data.FIRST .. lv_user_je_sourcE_name_data.LAST
					LOOP
					
					lv_error_message:=null;
			            Begin
						  select user_je_source_name into lv_je_source from gl_je_sources 
						  where je_source_name=lv_user_je_sourcE_name_data(idx).user_je_source_name;

						  Update XX_GL_JRNLS_CLD_INTF_STG 
						  set EBS_JOURNAL_source=lv_je_source
						  where 1=1
						  and file_batch_id=gn_file_batch_id
							 and user_je_source_name=lv_user_je_sourcE_name_data(idx).user_je_source_name;

						 Exception 
						 when no_data_found then 
						     lv_error_message :=lv_error_message||'~'||'Journal Source Name not found';
							 gc_error_status_flag:='Y';
						  when others then
							lv_error_message:=lv_error_message||'~'||'Validation error-User Journal Source not found. SQLERRM-'||sqlerrm;
						    gc_error_status_flag:='Y';
						 end;

						  if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=ERROR_DESCRIPTION||'~'||lv_error_message
								where 1=1
								and file_batch_id=gn_file_batch_id
								and application_name=lv_user_je_sourcE_name_data(idx).user_je_source_name;
								gc_error_status_flag:='N';
						end if;

					end loop;
			end loop;

            close cur_user_je_sourcE_name;



 --==========================================================================================
  -- Cursor Declarations to check if Debits and Credits Balance
  --==========================================================================================	
	 		gc_error_status_flag:='N';
			lv_error_loc:='Debits and Credits Balance validation begins for FIN Transactions';
			OPEN cur_jrnls_dr_cr_bal;
			Loop
			FETCH cur_jrnls_dr_cr_bal 
				BULK COLLECT INTO lv_jrnls_dr_cr_bal_data LIMIT 5000;
				EXIT WHEN lv_jrnls_dr_cr_bal_data.COUNT = 0;

					FOR idx IN lv_jrnls_dr_cr_bal_data.FIRST .. lv_jrnls_dr_cr_bal_data.LAST
					LOOP
					 lv_error_message:=null;



						if  abs(lv_jrnls_dr_cr_bal_data(idx).total_dr)<>abs(lv_jrnls_dr_cr_bal_data(idx).total_cr) then


							 gc_error_status_flag:='Y';
							 lv_error_message :=lv_error_message||'~'||'Debits and Credits do not balance for this transaction';
						end if;


						if  abs(lv_jrnls_dr_cr_bal_data(idx).total_acc_dr)<>abs(lv_jrnls_dr_cr_bal_data(idx).total_acc_cr) then 

							 gc_error_status_flag:='Y';
							 lv_error_message :=lv_error_message||'~'||'Debits and Credits do not balance for this transaction';

						end if;

						 if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=ERROR_DESCRIPTION||'~'||lv_error_message
								where 1=1
								and file_batch_id=gn_file_batch_id
								and ae_header_id=lv_jrnls_dr_cr_bal_data(idx).ae_header_id
								and ebs_ledger_name=lv_jrnls_dr_cr_bal_data(idx).ebs_ledger_name
								and application_name=lv_jrnls_dr_cr_bal_data(idx).application_name
								and USER_JE_CATEGORY_NAME=lv_jrnls_dr_cr_bal_data(idx).USER_JE_CATEGORY_NAME;

						end if;


					end loop;
			end loop;
			close cur_jrnls_dr_cr_bal;
	end if;	

	if p_process_name='SCM' then



    --==========================================================================================
  -- Cursor Declarations for Joural Sourace Validation
  --==========================================================================================
	 gc_error_status_flag:='N';
	 lv_error_loc:='Journal Source Name Validation begins for SCM Transactions';	  
			OPEN cur_user_je_sourcE_name;
			Loop
			FETCH cur_user_je_sourcE_name 
				BULK COLLECT INTO lv_user_je_sourcE_name_data LIMIT 5000;
				EXIT WHEN lv_user_je_sourcE_name_data.COUNT = 0;

					FOR idx IN lv_user_je_sourcE_name_data.FIRST .. lv_user_je_sourcE_name_data.LAST
					LOOP
					
					lv_error_message:=null;
			            Begin
						  select user_je_source_name into lv_je_source from gl_je_sources 
						  where user_je_source_name=lv_user_je_sourcE_name_data(idx).user_je_source_name;

						  Update XX_GL_JRNLS_CLD_INTF_STG 
						  set EBS_JOURNAL_source=lv_je_source
						  where 1=1
						  and file_batch_id=gn_file_batch_id
						  and user_je_source_name=lv_user_je_sourcE_name_data(idx).user_je_source_name;

						 Exception 
						 when no_data_found then 
						     lv_error_message :=lv_error_message||'~'||'User Journal Source not found';
							 gc_error_status_flag:='Y';
						  when others then
							lv_error_message:=lv_error_message||'~'||'Validation error-User Journal Source not found. SQLERRM-'||sqlerrm;
						    gc_error_status_flag:='Y';
						 end;

						  if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=ERROR_DESCRIPTION||'~'||lv_error_message
								where 1=1
								and file_batch_id=gn_file_batch_id
								and application_name=lv_user_je_sourcE_name_data(idx).user_je_source_name;
								gc_error_status_flag:='N';
						end if;

					end loop;
			end loop;

            close cur_user_je_sourcE_name;

  --==========================================================================================
  -- Cursor Declarations to check if Debits and Credits Balance for SCM Transactions
  --==========================================================================================	
	 		gc_error_status_flag:='N';
			lv_error_loc:='Debits and Credits Balance Validation begins for SCM Transactions';
			OPEN cur_jrnls_dr_cr_bal_scm;
			Loop
			FETCH cur_jrnls_dr_cr_bal_scm 
				BULK COLLECT INTO lv_jrnls_dr_cr_bal_scm_data LIMIT 5000;
				EXIT WHEN lv_jrnls_dr_cr_bal_scm_data.COUNT = 0;

					FOR idx IN lv_jrnls_dr_cr_bal_scm_data.FIRST .. lv_jrnls_dr_cr_bal_scm_data.LAST
					LOOP
						lv_error_message:=null;


						if  abs(lv_jrnls_dr_cr_bal_scm_data(idx).total_dr)<>abs(lv_jrnls_dr_cr_bal_scm_data(idx).total_cr) then


							 gc_error_status_flag:='Y';
							 lv_error_message :=lv_error_message||'~'||'Debits and Credits do not balance for this transaction';
						end if;


						if  abs(lv_jrnls_dr_cr_bal_scm_data(idx).total_acc_dr)<>abs(lv_jrnls_dr_cr_bal_scm_data(idx).total_acc_cr) then 

							 gc_error_status_flag:='Y';
							 lv_error_message :=lv_error_message||'~'||'Debits and Credits do not balance for this transaction';

						end if;

						 if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=ERROR_DESCRIPTION||'~'||lv_error_message
								where 1=1
								and file_batch_id=gn_file_batch_id
								and reference10=lv_jrnls_dr_cr_bal_scm_data(idx).reference10;
								gc_error_status_flag:='N';
						end if;


					end loop;
			end loop;
			close cur_jrnls_dr_cr_bal_scm;

	end if;


  --==========================================================================================
  -- Cursor Declarations for Currency Code Validation
  --==========================================================================================	
	 	gc_error_status_flag:='N';
		lv_error_loc:='Currency Code Validation begins';
			OPEN cur_currency_code;
			Loop
			FETCH cur_currency_code 
				BULK COLLECT INTO lv_currency_code_data LIMIT 5000;
				EXIT WHEN lv_currency_code_data.COUNT = 0;

					FOR idx IN lv_currency_code_data.FIRST .. lv_currency_code_data.LAST
					LOOP
					
					lv_error_message:=null;
			            Begin
						  select 1 into lv_record from fnd_currencies 
						  where currency_code=lv_currency_code_data(idx).currency_code;

						 Exception 
						 when no_data_found then 
							 gc_error_status_flag:='Y';
							 lv_error_message :=lv_error_message||'~'||'Currency Code not found';	
						  when others then 
						  lv_error_message:=lv_error_message||'~'||'Validation error-Currency Code not found. SQLERRM-'||sqlerrm; 						   
						  gc_error_status_flag:='Y';						  
						 end;

						  if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=ERROR_DESCRIPTION||'~'||lv_error_message
								where 1=1
								and file_batch_id=gn_file_batch_id
								and currency_code=lv_currency_code_data(idx).currency_code;
								gc_error_status_flag:='N';
						end if;

					end loop;
			end loop;


		close cur_currency_code;
 --==========================================================================================
  -- Cursor Declarations for User JE Category Name Validation
  --==========================================================================================	
	 		gc_error_status_flag:='N';
			lv_error_loc:='Journal Category Name Validation begins';
		OPEN cur_user_category_name;
			Loop
			FETCH cur_user_category_name 
				BULK COLLECT INTO lv_user_catg_name_data LIMIT 5000;
				EXIT WHEN lv_user_catg_name_data.COUNT = 0;

					FOR idx IN lv_user_catg_name_data.FIRST .. lv_user_catg_name_data.LAST
					LOOP
					
					lv_error_message:=null;
			            Begin
						  select user_Je_category_name into lv_je_category from GL_JE_CATEGORIES 
						  where user_je_category_name=lv_user_catg_name_data(idx).user_je_category_name;

						  Update XX_GL_JRNLS_CLD_INTF_STG 
						  set EBS_JOURNAL_CATEGORY=lv_je_category
						  where 1=1
						  and file_batch_id=gn_file_batch_id
							 and user_je_category_name=lv_user_catg_name_data(idx).user_je_category_name;

						 Exception 
						 when no_data_found then 
								Begin 
								SELECT 
										xftv.target_value1 into lv_je_category
									FROM xx_fin_translatedefinition xftd,
										xx_fin_translatevalues xftv
									WHERE xftd.translation_name ='OD_CLD_GL_JRNLS_APP_MAP'
									AND xftv.source_value1      = 'Journal_Category'
									AND xftv.source_value2      = lv_user_catg_name_data(idx).user_je_category_name
									AND xftd.translate_id       =xftv.translate_id
									AND xftd.enabled_flag       ='Y'
									AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate);
									
								Update XX_GL_JRNLS_CLD_INTF_STG 
								set EBS_JOURNAL_CATEGORY=lv_je_category
								where 1=1
								and file_batch_id=gn_file_batch_id
								and user_je_category_name=lv_user_catg_name_data(idx).user_je_category_name;
									
									
								Exception 
								when others then 
									lv_error_message :=lv_error_message||'~'||'User JE Category Name not found';
									gc_error_status_flag:='Y';
								end;
						    
						 when others then
							lv_error_message:=lv_error_message||'~'||'Validation error-User JE Category not found. SQLERRM-'||sqlerrm;						   
						    gc_error_status_flag:='Y';
						 end;

						  if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=ERROR_DESCRIPTION||'~'||lv_error_message
								where 1=1
								and file_batch_id=gn_file_batch_id
								and user_je_category_name=lv_user_catg_name_data(idx).user_je_category_name;

						end if; 

					end loop;
			end loop;
		close cur_user_category_name;


  --==========================================================================================
  -- Cursor if any segments is missing
  --==========================================================================================	
	 		gc_error_status_flag:='N';
			lv_error_loc:='Code Combination Segments is Null validation begins';
			OPEN cur_select_segments;
			Loop
			FETCH cur_select_segments 
				BULK COLLECT INTO lv_cur_select_segments_data LIMIT 5000;
				EXIT WHEN lv_cur_select_segments_data.COUNT = 0;

					FOR idx IN lv_cur_select_segments_data.FIRST .. lv_cur_select_segments_data.LAST
					LOOP

					 lv_error_message :='Code Combination Segments is missing';

						if (lv_cur_select_segments_data(idx).segment1 is null or 
						lv_cur_select_segments_data(idx).segment2 is null   or
						lv_cur_select_segments_data(idx).segment3 is null   or
						lv_cur_select_segments_data(idx).segment4 is null   or
						lv_cur_select_segments_data(idx).segment5 is null   or
						lv_cur_select_segments_data(idx).segment6 is null) then 

						Update XX_GL_JRNLS_CLD_INTF_STG set 
						     	ERROR_DESCRIPTION=ERROR_DESCRIPTION||'~'||lv_error_message
							 where rowid=lv_cur_select_segments_data(idx).rowid	;
							 gc_error_status_flag:='Y';
						end if;



					end loop;
			end loop;
			close cur_select_segments;

			commit;	

  --==========================================================================================
  -- Cursor to derive CCID validation
  --==========================================================================================	

        gc_error_status_flag:='N';
		lv_error_loc:='CCID derivation begins';
          SELECT gsob.chart_of_accounts_id             	  
			  into gn_chart_of_accounts_id			  
           FROM gl_sets_of_books gsob
          WHERE set_of_books_id = gn_set_of_bks_id;

		OPEN cur_derive_ccid;
			Loop
			FETCH cur_derive_ccid 
				BULK COLLECT INTO lv_derive_ccid_data LIMIT 5000;
				EXIT WHEN lv_derive_ccid_data.COUNT = 0;

					FOR idx IN lv_derive_ccid_data.FIRST .. lv_derive_ccid_data.LAST
					LOOP
					  lv_derived_ccid:=null;
					  lv_error_message:=null;
			            Begin
						  lc_ccid_acct:=lv_derive_ccid_data(idx).segment1||'.'||
									       lv_derive_ccid_data(idx).segment2||'.'||
									       lv_derive_ccid_data(idx).segment3||'.'||
									       lv_derive_ccid_data(idx).segment4||'.'||
									       lv_derive_ccid_data(idx).segment5||'.'||
									       lv_derive_ccid_data(idx).segment6||'.'||
									       lv_derive_ccid_data(idx).segment7;

										   lv_derived_ccid    := fnd_flex_ext.get_ccid (application_short_name      => 'SQLGL'
																						, key_flex_code               => 'GL#'
																						, structure_number            => gn_chart_of_accounts_id
																						, validation_date             => SYSDATE
																						, concatenated_segments       => lc_ccid_acct
																						);
											if lv_derived_ccid=0 then 													

												    gc_error_status_flag:='Y';
													lv_error_message:='Code Combination ID not found for ' || lc_ccid_acct;
												
												Update XX_GL_JRNLS_CLD_INTF_STG set 												    
												    error_description=ERROR_DESCRIPTION||'~'||'Code Combination ID not found for ' || lc_ccid_acct
												    where rowid=lv_derive_ccid_data(idx).rowid;	
											else
											 Update XX_GL_JRNLS_CLD_INTF_STG set 												    
												    CODE_COMBINATION_ID=lv_derived_ccid
												    where rowid=lv_derive_ccid_data(idx).rowid;												
											end if;
						 Exception 
							when others then
							lv_error_message:=lv_error_message||'~'||'Validation error to derive Code Combination Id. SQLERRM-'||sqlerrm;						   
						    gc_error_status_flag:='Y';
							Update XX_GL_JRNLS_CLD_INTF_STG set 												    
								error_description=ERROR_DESCRIPTION||'~'||'Error to derive CCID ' || lc_ccid_acct||'.Error-'||lv_error_message
								where rowid=lv_derive_ccid_data(idx).rowid;	
						 end;

						

					end loop;
			end loop;
		close cur_derive_ccid;
		commit;

			if gc_error_status_flag='Y' then

				update XX_GL_JRNLS_CLD_INTF_FILES set record_status='V'--Update all records to Valid.Update to E when required. 
				where 1=1
				and file_batch_id=gn_file_batch_id;		
				update XX_GL_JRNLS_CLD_INTF_STG set record_status='V' , 
				action='VALID'
				where 1=1
				and file_batch_id=gn_file_batch_id	;			

			else

				update XX_GL_JRNLS_CLD_INTF_STG set record_status='V' , 
				action='VALID'
				where 1=1
				and file_batch_id=gn_file_batch_id;

				update XX_GL_JRNLS_CLD_INTF_FILES set record_status='V' 
				where 1=1
				and file_batch_id=gn_file_batch_id;
			end if;
			commit;

    end loop;
EXCEPTION
WHEN OTHERS THEN
  l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
  print_debug_msg(p_message => 'ERROR: Exception in VALIDATE_CLD_GL_INTF_AP_FILE() API -Error Loc:'||lv_error_loc||'.Error:'|| l_err_buff , p_force => true);
  logit('Error in VALIDATE_CLD_GL_INTF_AP_FILE'||sqlerrm );
  p_retcode      := '2';
  p_errbuf       := l_err_buff;
END VAL_CLD_GL_INTF_FILE;

/******************************************************************
* file record creation for uplicate Check
* Table : XX_GL_JRNLS_CLD_INTF_FILES
******************************************************************/
PROCEDURE INSERT_FILE_REC(
    p_process_name VARCHAR2,
    p_file_name    VARCHAR2,
    p_request_id    NUMBER,
	p_user_id       NUMBER)
IS
 lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'INSERT_FILE_REC';
BEGIN
  logit(p_message =>'Inside Procedure call INSERT_FILE_REC');
  INSERT
  INTO XX_GL_JRNLS_CLD_INTF_FILES
    (
	FILE_BATCH_ID,
      PROCESS_NAME,
      file_name,
      creation_date,
      created_by,
      last_updated_by,
      last_update_date,
      record_status,
      request_id
    )
    VALUES
    (
	  gn_file_batch_id,
      p_process_name,
      p_file_name,
      sysdate,
      p_user_id,
      p_user_id,
      sysdate,
      'N',
      p_request_id
    );
	commit;
EXCEPTION
WHEN OTHERS THEN

   logit(p_message => 'ERROR-SQLCODE:'|| SQLCODE || ' SQLERRM: ' || SQLERRM, p_force => TRUE);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
END INSERT_FILE_REC;

-- +============================================================================================+
-- |  Name  : LOAD_UTL_FILE_STAGING                                                             |
-- |  Description: This procedure reads data from the file and inserts into staging table       |
-- =============================================================================================|
PROCEDURE LOAD_UTL_FILE_STAGING(
    p_process_name VARCHAR2,
    p_file_name    VARCHAR2,
    p_debug_flag   VARCHAR2,
    p_request_id   NUMBER,
	p_user_id   number,
	p_errbuf  OUT nocopy  VARCHAR2 ,
    p_retcode OUT nocopy NUMBER )
AS
  l_filehandle utl_file.file_type;
  l_filedir VARCHAR2(20) := 'XXFIN_GL_FTP_IN';--'XXFIN_GL_FTP_IN';
  l_dirpath VARCHAR2(500);
  l_newline VARCHAR2(4000); -- Input line
  l_max_linesize binary_integer := 32767;
  l_user_id    NUMBER              := fnd_global.user_id;
  l_login_id   NUMBER              := fnd_global.login_id;
  l_request_id NUMBER              := fnd_global.conc_request_id;
  l_rec_cnt    NUMBER              := 0;
  l_table varchar2_table;
  l_nfields           INTEGER;
  l_error_msg         VARCHAR2(1000) := NULL;
  l_error_loc         VARCHAR2(2000) := 'XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging';
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'LOAD_UTL_FILE_STAGING';
  l_retcode           VARCHAR2(3)    := NULL;
  parse_exception     EXCEPTION;
  dup_file_exception       EXCEPTION;
  l_dup_settlement_id NUMBER;
  /*staging table columns*/
  l_record_id                    NUMBER;

  l_LEDGER_NAME        XX_GL_JRNLS_CLD_INTF_STG.LEDGER_NAME%TYPE;
  l_APPLICATION_NAME   XX_GL_JRNLS_CLD_INTF_STG.APPLICATION_NAME%TYPE;
  l_PERIOD_NAME        XX_GL_JRNLS_CLD_INTF_STG.PERIOD_NAME%TYPE;
  l_ACCOUNTING_DATE    XX_GL_JRNLS_CLD_INTF_STG.ACCOUNTING_DATE%TYPE;
  l_JE_CATG_NAME       XX_GL_JRNLS_CLD_INTF_STG.USER_JE_CATEGORY_NAME%TYPE;
  l_ACC_CLASS_CODE     XX_GL_JRNLS_CLD_INTF_STG.ACCOUNTING_CLASS_CODE%TYPE;

  l_GL_STATUS_CODE     XX_GL_JRNLS_CLD_INTF_STG.GL_STATUS_CODE%TYPE;
  l_CURRENCY_CODE      XX_GL_JRNLS_CLD_INTF_STG.CURRENCY_CODE%TYPE;
  l_AE_HEADER_ID       XX_GL_JRNLS_CLD_INTF_STG.AE_HEADER_ID%TYPE;
  l_AE_LINE_NUM        XX_GL_JRNLS_CLD_INTF_STG.AE_LINE_NUM%TYPE;
  l_GL_SL_LINK_ID      XX_GL_JRNLS_CLD_INTF_STG.GL_SL_LINK_ID%TYPE;
  l_ENTERED_CR         XX_GL_JRNLS_CLD_INTF_STG.ENTERED_CR%TYPE;
  l_ENTERED_DR         XX_GL_JRNLS_CLD_INTF_STG.ENTERED_DR%TYPE;
  l_ACCOUNTED_CR       XX_GL_JRNLS_CLD_INTF_STG.ACCOUNTED_CR%TYPE;
  l_ACCOUNTED_DR       XX_GL_JRNLS_CLD_INTF_STG.ACCOUNTED_DR%TYPE;
  l_hdr_DESCRIPTION        XX_GL_JRNLS_CLD_INTF_STG.HDR_DESCRIPTION%TYPE;
  l_line_DESCRIPTION        XX_GL_JRNLS_CLD_INTF_STG.LINe_DESCRIPTION%TYPE;
  l_SEGMENT1 XX_GL_JRNLS_CLD_INTF_STG.SEGMENT1%TYPE;
  l_SEGMENT2 XX_GL_JRNLS_CLD_INTF_STG.SEGMENT1%TYPE;
  l_SEGMENT3 XX_GL_JRNLS_CLD_INTF_STG.SEGMENT1%TYPE;
  l_SEGMENT4 XX_GL_JRNLS_CLD_INTF_STG.SEGMENT1%TYPE;
  l_SEGMENT5 XX_GL_JRNLS_CLD_INTF_STG.SEGMENT1%TYPE;
  l_SEGMENT6 XX_GL_JRNLS_CLD_INTF_STG.SEGMENT1%TYPE;
  l_SEGMENT7 XX_GL_JRNLS_CLD_INTF_STG.SEGMENT1%TYPE;    
  l_GL_ACCOUNT_STRING  varchar2(250);


   CURSOR cur_gl_process
  IS
    SELECT 
       xftv.target_value1 inbound_path,
      xftv.target_value2 archival_path,
	  xftv.target_value4 dba_directory_name
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv
    WHERE xftd.translation_name ='OD_GL_JRNLS_CLD_INTF'
    AND xftv.source_value1      = p_process_name
    AND xftd.translate_id       =xftv.translate_id
    AND xftd.enabled_flag       ='Y'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate);

	lc_GL_JRNLS_CLD_INTF_STG XX_GL_JRNLS_CLD_INTF_STG%ROWTYPE;
	lv_journal_source_name varchar2(50);
	lv_application_name varchar2(100);
	 lt_parameters gt_input_parameters;
     lv_filerec_count number;
BEGIN

  lt_parameters('p_process_name') := p_process_name;
  lt_parameters('p_file_name')   := p_file_name;
  lt_parameters('p_debug_flag')   := p_debug_flag;
  lt_parameters('p_file_name')   := p_request_id;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);

   select count(1) into lv_filerec_count from XX_GL_JRNLS_CLD_INTF_FILES
   where FILE_NAME=p_file_name
   and   process_name=p_process_name;
  


    IF lv_filerec_count =0 THEN
			gn_file_batch_id:=XX_GL_JRNLS_CLD_INTF_FILES_S.nextval;
            insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name,p_request_id=>p_request_id,p_user_id=>p_user_id) ;            
			print_debug_msg(p_message =>'File Record Created Successfully.', p_force => true);
    ELSE
	        p_errbuf:='Duplicate File-This file is already processed.';
			p_retcode:=2;
            logit(p_message=>'Duplicate File-This file is already processed.'||p_file_name);
			print_debug_msg(p_message =>'Duplicate File-This file is already processed.', p_force => true);
			RAISE dup_file_exception;            
    END IF;





  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Loading File:'||p_file_name , p_force => true);
  for rec in  cur_gl_process loop 
  l_filedir:=NVL(rec.dba_directory_name,'XXFIN_GL_FTP_IN');
  l_filehandle := utl_file.fopen(l_filedir,p_file_name,'r',l_max_linesize);


  LOOP
    BEGIN
      utl_file.get_line(l_filehandle,l_newline);
      IF l_newline IS NULL THEN
        EXIT;
      END IF;
      /*skip parsing the header labels record*/
      CONTINUE	  
    WHEN replace(SUBSTR(l_newline,1,13),chr(34),'') = 'LEDGER_NAME';
      parse_datafile_line(l_newline,l_table,l_nfields,chr(124),l_error_msg,l_retcode);
      IF l_retcode = '2' THEN
        raise parse_exception;
      END IF;


	 /*Initialize Local Variables*/
	  lv_journal_source_name													:=null;
	  SELECT XX_GL_JRNLS_CLD_INTF_STG_S.nextval INTO l_record_id FROM dual;  

	  lc_GL_JRNLS_CLD_INTF_STG                       							:=NULL                                  ;
	  lc_GL_JRNLS_CLD_INTF_STG.RECORD_ID                   						:=l_RECORD_ID                           ;
	  lc_GL_JRNLS_CLD_INTF_STG.LEDGER_NAME                 						:=l_table(1)						    ;	  
	  lc_GL_JRNLS_CLD_INTF_STG.PERIOD_NAME                 						:=l_table(3)						    ;
	  lc_GL_JRNLS_CLD_INTF_STG.ACCOUNTING_DATE             						:=to_date(NVL(l_table(4),sysdate),'DD-MM-YYYY') ;
	  lc_GL_JRNLS_CLD_INTF_STG.USER_JE_CATEGORY_NAME       						:=l_table(5)							;
	  lc_GL_JRNLS_CLD_INTF_STG.ACCOUNTING_CLASS_CODE       						:=l_table(6)							;   
	  lc_GL_JRNLS_CLD_INTF_STG.GL_STATUS_CODE              						:=l_table(7)							;
	  lc_GL_JRNLS_CLD_INTF_STG.CURRENCY_CODE               						:=l_table(8)							;
	  lc_GL_JRNLS_CLD_INTF_STG.AE_HEADER_ID                						:=to_number(l_table(9))                 ;
	  lc_GL_JRNLS_CLD_INTF_STG.AE_LINE_NUM                 						:=to_number(l_table(10))                ;
	  lc_GL_JRNLS_CLD_INTF_STG.GL_SL_LINK_ID               						:=to_number(l_table(11))                ;
	  lc_GL_JRNLS_CLD_INTF_STG.ENTERED_CR                  						:=to_number(l_table(12))                ;
	  lc_GL_JRNLS_CLD_INTF_STG.ENTERED_DR                  						:=to_number(l_table(13))                ;
	  lc_GL_JRNLS_CLD_INTF_STG.ACCOUNTED_CR                						:=to_number(l_table(14))                ;
	  lc_GL_JRNLS_CLD_INTF_STG.ACCOUNTED_DR                						:=to_number(l_table(15))                ;  
	  lc_GL_JRNLS_CLD_INTF_STG.SEGMENT7                     					:='000000'								;
	  lc_GL_JRNLS_CLD_INTF_STG.CREATED_BY             							:=p_user_id                   ;
	  lc_GL_JRNLS_CLD_INTF_STG.CREATION_DATE          							:=sysdate	                            ;
	  lc_GL_JRNLS_CLD_INTF_STG.LAST_UPDATED_BY        							:=p_user_id                   ;
	  lc_GL_JRNLS_CLD_INTF_STG.LAST_UPDATE_DATE       							:=sysdate                               ;
	  lc_GL_JRNLS_CLD_INTF_STG.LAST_UPDATE_LOGIN      							:=p_user_id                  ;
	  lc_GL_JRNLS_CLD_INTF_STG.ACTION                 							:='NEW'                                 ;
	  lc_GL_JRNLS_CLD_INTF_STG.RECORD_STATUS          							:='N'                                   ;
	  lc_GL_JRNLS_CLD_INTF_STG.ERROR_DESCRIPTION      							:=null                                  ;
	  lc_GL_JRNLS_CLD_INTF_STG.REQUEST_ID             							:=p_request_id                          ;
	  lc_GL_JRNLS_CLD_INTF_STG.FILE_NAME              							:=p_file_name                           ;
	  lc_GL_JRNLS_CLD_INTF_STG.process_name      							    :=p_process_name                        ;
	  lc_GL_JRNLS_CLD_INTF_STG.file_batch_id      							    :=gn_file_batch_id                      ;


	if p_process_name in ('SCM') then

	  lc_GL_JRNLS_CLD_INTF_STG.reference10            					        :=l_table(19);
	  lc_GL_JRNLS_CLD_INTF_STG.user_je_source_name            					:=replace(l_table(20),chr(13),'')       ;
	  lc_GL_JRNLS_CLD_INTF_STG.APPLICATION_NAME            						:=l_table(2);
	  lc_GL_JRNLS_CLD_INTF_STG.HDR_DESCRIPTION             				        :=l_table(16)							;
	  lc_GL_JRNLS_CLD_INTF_STG.LINE_DESCRIPTION            						:=l_table(17)							;
	  l_GL_ACCOUNT_STRING                                                       :=l_table(18)							;
	  lc_GL_JRNLS_CLD_INTF_STG.SEGMENT1                    				        :=substr(l_GL_ACCOUNT_STRING,1,instr(l_GL_ACCOUNT_STRING,'.',1,1)-1);
	  lc_GL_JRNLS_CLD_INTF_STG.SEGMENT2                    						:=substr(l_GL_ACCOUNT_STRING,instr(l_GL_ACCOUNT_STRING,'.',1,2)+1,instr(l_GL_ACCOUNT_STRING,'.',1,3)-instr(l_GL_ACCOUNT_STRING,'.',1,2)-1);
	  lc_GL_JRNLS_CLD_INTF_STG.SEGMENT3                    						:=substr(l_GL_ACCOUNT_STRING,instr(l_GL_ACCOUNT_STRING,'.',1,3)+1,instr(l_GL_ACCOUNT_STRING,'.',1,4)-instr(l_GL_ACCOUNT_STRING,'.',1,3)-1);
	  lc_GL_JRNLS_CLD_INTF_STG.SEGMENT4                    						:=substr(l_GL_ACCOUNT_STRING,instr(l_GL_ACCOUNT_STRING,'.',1,4)+1,instr(l_GL_ACCOUNT_STRING,'.',1,5)-instr(l_GL_ACCOUNT_STRING,'.',1,4)-1);
	  lc_GL_JRNLS_CLD_INTF_STG.SEGMENT5                      					:=replace(substr(l_GL_ACCOUNT_STRING,instr(l_GL_ACCOUNT_STRING,'.',1,5)+1,length(l_GL_ACCOUNT_STRING)-instr(l_GL_ACCOUNT_STRING,'.',1,5)) ,chr(13),'');
	  lc_GL_JRNLS_CLD_INTF_STG.SEGMENT6                     					:=substr(l_GL_ACCOUNT_STRING,instr(l_GL_ACCOUNT_STRING,'.',1,1)+1,instr(l_GL_ACCOUNT_STRING,'.',1,2)-instr(l_GL_ACCOUNT_STRING,'.',1,1)-1);
	  lc_GL_JRNLS_CLD_INTF_STG.reference10            						    :=l_table(19)							;
	  --lc_GL_JRNLS_CLD_INTF_STG.EBS_JOURNAL_source            				    :=replace(l_table(20),chr(13),'')       ;



	elsif  p_process_name in ('FIN') then


	  lc_GL_JRNLS_CLD_INTF_STG.LINE_DESCRIPTION            						:=l_table(16)							;
	  lc_GL_JRNLS_CLD_INTF_STG.CLD_REQUEST_ID                                   :=l_table(17)							;
	  lc_GL_JRNLS_CLD_INTF_STG.TRANSACTION_NUMBER                               :=l_table(18)							;	  
	  l_GL_ACCOUNT_STRING                                                       :=l_table(19)							;
	  lc_GL_JRNLS_CLD_INTF_STG.SEGMENT1                    				        :=substr(l_GL_ACCOUNT_STRING,1,instr(l_GL_ACCOUNT_STRING,'.',1,1)-1);
	  lc_GL_JRNLS_CLD_INTF_STG.SEGMENT2                    						:=substr(l_GL_ACCOUNT_STRING,instr(l_GL_ACCOUNT_STRING,'.',1,2)+1,instr(l_GL_ACCOUNT_STRING,'.',1,3)-instr(l_GL_ACCOUNT_STRING,'.',1,2)-1);
	  lc_GL_JRNLS_CLD_INTF_STG.SEGMENT3                    						:=substr(l_GL_ACCOUNT_STRING,instr(l_GL_ACCOUNT_STRING,'.',1,3)+1,instr(l_GL_ACCOUNT_STRING,'.',1,4)-instr(l_GL_ACCOUNT_STRING,'.',1,3)-1);
	  lc_GL_JRNLS_CLD_INTF_STG.SEGMENT4                    						:=substr(l_GL_ACCOUNT_STRING,instr(l_GL_ACCOUNT_STRING,'.',1,4)+1,instr(l_GL_ACCOUNT_STRING,'.',1,5)-instr(l_GL_ACCOUNT_STRING,'.',1,4)-1);
	  lc_GL_JRNLS_CLD_INTF_STG.SEGMENT5                      					:=replace(substr(l_GL_ACCOUNT_STRING,instr(l_GL_ACCOUNT_STRING,'.',1,5)+1,length(l_GL_ACCOUNT_STRING)-instr(l_GL_ACCOUNT_STRING,'.',1,5)) ,chr(13),'');
	  lc_GL_JRNLS_CLD_INTF_STG.SEGMENT6                     					:=substr(l_GL_ACCOUNT_STRING,instr(l_GL_ACCOUNT_STRING,'.',1,1)+1,instr(l_GL_ACCOUNT_STRING,'.',1,2)-instr(l_GL_ACCOUNT_STRING,'.',1,1)-1);


        BEGIN

			select fav.application_name,xas.je_source_name 
			       into lv_application_name,lv_journal_source_name 
		    from xla_subledgers xas , fnd_application_vl fav  
			     where fav.application_id=xas.application_id
			     and fav.application_name=l_table(2);		
		lc_GL_JRNLS_CLD_INTF_STG.user_je_source_name            					:=lv_journal_source_name            ;
		lc_GL_JRNLS_CLD_INTF_STG.APPLICATION_NAME            						:=lv_application_name			    ;
		Exception 
		when no_data_found then 
		  Begin 
		    SELECT 
					xftv.target_value1 into lv_application_name
				FROM apps.xx_fin_translatedefinition xftd,
					 apps.xx_fin_translatevalues xftv
				WHERE xftd.translation_name ='OD_CLD_GL_JRNLS_APP_MAP'
				AND xftv.source_value1      = 'Application_Name'
				AND xftv.source_value2      = l_table(2)
				AND xftd.translate_id       =xftv.translate_id
				AND xftd.enabled_flag       ='Y'
				AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate);
				
				select fav.application_name,xas.je_source_name 
			       into lv_application_name,lv_journal_source_name 
		    from xla_subledgers xas , fnd_application_vl fav  
			     where fav.application_id=xas.application_id
			     and fav.application_name=lv_application_name;	
		lc_GL_JRNLS_CLD_INTF_STG.user_je_source_name            					:=lv_journal_source_name            ;
		lc_GL_JRNLS_CLD_INTF_STG.APPLICATION_NAME            						:=lv_application_name			    ;				 
		  
		  exception 
		  when others then 
		  lc_GL_JRNLS_CLD_INTF_STG.user_je_source_name            					:= l_table(2)                       ;
		  lc_GL_JRNLS_CLD_INTF_STG.APPLICATION_NAME            						:= l_table(2)			            ;	
		  end;
		
		
		when others then
		lc_GL_JRNLS_CLD_INTF_STG.user_je_source_name            					:= l_table(2)                       ;
		lc_GL_JRNLS_CLD_INTF_STG.APPLICATION_NAME            						:= l_table(2)			            ;	
		end;

	end if;

	  INSERT INTO XX_GL_JRNLS_CLD_INTF_STG VALUES lc_GL_JRNLS_CLD_INTF_STG;

      l_rec_cnt := l_rec_cnt + 1;
    EXCEPTION
    WHEN no_data_found THEN
      EXIT;
    END;
  END LOOP;
  utl_file.fclose(l_filehandle);  

  end loop;
  COMMIT;

   print_debug_msg(p_message =>TO_CHAR(l_rec_cnt)||' records successfully loaded into staging', p_force => true);
   print_debug_msg(p_message => 'File Processed Successfully:'||p_file_name , p_force => true);
EXCEPTION
WHEN dup_file_exception THEN
  p_errbuf  := l_error_msg;
  p_retcode := '2';
  log_exception (p_program_name => 'XXGLJRNLSCLDINTFLOAD' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf||sqlerrm);
WHEN parse_exception THEN
  ROLLBACK;
  p_errbuf  := l_error_msg;
  p_retcode := l_retcode;
  log_exception (p_program_name => 'XXGLJRNLSCLDINTFLOAD' ,p_error_location => l_error_loc ,p_error_msg => l_error_msg||sqlerrm);
WHEN utl_file.invalid_operation THEN
  utl_file.fclose(l_filehandle);
  p_errbuf := 'XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging: Invalid Operation-'||sqlerrm;
  p_retcode:= '2';
  log_exception (p_program_name => 'XXGLJRNLSCLDINTFLOAD' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf||sqlerrm);
WHEN utl_file.invalid_filehandle THEN
  utl_file.fclose(l_filehandle);
  p_errbuf := 'XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging: Invalid File Handle-'||sqlerrm;
  p_retcode:= '2';
  log_exception (p_program_name => 'XXGLJRNLSCLDINTFLOAD' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf||sqlerrm);
WHEN utl_file.read_error THEN
  utl_file.fclose(l_filehandle);
  p_errbuf := 'XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging: Read Error-'||sqlerrm;
  p_retcode:= '2';
  log_exception (p_program_name => 'XXGLJRNLSCLDINTFLOAD' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf||sqlerrm);
WHEN utl_file.invalid_path THEN
  utl_file.fclose(l_filehandle);
  p_errbuf := 'XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging: Invalid Path-'||sqlerrm;
  p_retcode:= '2';
  log_exception (p_program_name => 'XXGLJRNLSCLDINTFLOAD' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf||sqlerrm);
WHEN utl_file.invalid_mode THEN
  utl_file.fclose(l_filehandle);
  p_errbuf := 'XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging: Invalid Mode-'||sqlerrm;
  p_retcode:= '2';
  log_exception (p_program_name => 'XXGLJRNLSCLDINTFLOAD' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf||sqlerrm);
WHEN utl_file.internal_error THEN
  utl_file.fclose(l_filehandle);
  p_errbuf := 'XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging: Internal Error-'||sqlerrm;
  p_retcode:= '2';
  log_exception (p_program_name => 'XXGLJRNLSCLDINTFLOAD' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf||sqlerrm);
WHEN value_error THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  p_errbuf := 'XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging-'||sqlerrm;
  p_retcode:= '2';
  log_exception (p_program_name => 'XXGLJRNLSCLDINTFLOAD' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf||sqlerrm); 
 WHEN OTHERS THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  p_retcode:= '2';
  p_errbuf := 'XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging-'||SUBSTR(sqlerrm,1,250);
  log_exception (p_program_name => 'XXGLJRNLSCLDINTFLOAD' ,p_error_location => l_error_loc ,p_error_msg => p_errbuf||sqlerrm);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
END load_utl_file_staging;



PROCEDURE MAIN_LOAD_PROCESS(
    p_process_name VARCHAR2,
    p_file_name    VARCHAR2,
    p_debug_flag   VARCHAR2,
    p_request_id   NUMBER,
	p_user_id      NUMBER)
IS

 lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'MAIN_LOAD_PROCESS';
 lt_parameters gt_input_parameters;
 x_err_buf varchar2(1000):=null;
 x_ret_code number:=0;
 lc_action VARCHAR2(1000);

 BEGIN

  lt_parameters('p_process_name') := p_process_name;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  lc_action := 'Load GL Load Main Process';


  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling LOAD_UTL_FILE_STAGING Procedure' , p_force => true);
  LOAD_UTL_FILE_STAGING( p_process_name => p_process_name, p_file_name => p_file_name,p_debug_flag => p_debug_flag,p_request_id=>p_request_id,p_user_id=>p_user_id,p_errbuf=>x_err_buf,p_retcode=>x_ret_code) ;
  print_debug_msg(P_MESSAGE => 'Exiting LOAD_UTL_FILE_STAGING Procedure' , p_force => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  if x_err_buf is not null then 
    update XX_GL_JRNLS_CLD_INTF_FILES set error_description=x_err_buf
	where file_name=p_file_name;
	commit;	
  end if;
EXCEPTION
WHEN OTHERS THEN
  logit(p_message => 'Error Occured:'||lc_action||'~SQLCODE:'|| SQLCODE || '~SQLERRM: ' || SQLERRM, p_force => TRUE);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
END MAIN_LOAD_PROCESS;


/**********************************************************************************
* Procedure to process  Process Journal Batch to Submit OD: GL Interface for Cloud GL Transactions and Journal Import 
* This procedure is called by MAIN_PROCESS.
***********************************************************************************/
PROCEDURE PROCESS_JOURNAL_BATCH(	
    p_process_name IN VARCHAR2,
    p_debug_flag   IN VARCHAR2,
	p_errbuf  OUT nocopy  VARCHAR2 ,
    p_retcode OUT nocopy NUMBER )
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'PROCESS_JOURNAL_BATCH';
  lt_parameters gt_input_parameters;
  lc_action      VARCHAR2(1000);
  lc_conc_req_id NUMBER;
  lc_wait_flag   BOOLEAN;
  lc_phase       VARCHAR2(100);
  lc_status      VARCHAR2(100);
  lc_dev_phase   VARCHAR2(100);
  lc_dev_status  VARCHAR2(100);
  lc_message     VARCHAR2(100);
  cursor cur_file_batch is   
  select  distinct xfile.file_batch_id file_batch_id
  from  

	XX_GL_JRNLS_CLD_INTF_FILES xfile
  where xfile.record_status='I'
  and xfile.process_name=p_process_name;


  cursor cur_file_stg_batch(p_file_batch_id number) is 
  select distinct ebs_journal_source from 
  	XX_GL_JRNLS_CLD_INTF_STG stg
	where 1=1	
	 and stg.file_batch_id=p_file_batch_id
  and stg.RECORD_STATUS in ('I')
  and stg.action in ('INSERT');
  l_err_buff      VARCHAR2 (4000);
  lv_status varchar2(1):='N';
  lv_file_status varchar2(1):='N';

BEGIN
  lt_parameters('p_process_name') := p_process_name;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  lc_action := 'Submitting GL Data File Load Program';

  for rec in cur_file_batch loop
  lv_file_status:='N';

   for stg_rec in cur_file_stg_batch(rec.file_batch_id) loop
   lv_status:='N';
  BEGIN
    lc_conc_req_id := fnd_request.submit_request ( application => 'XXFIN' , program => 'XXGLJRNLSCLDGLTRANS' , description => NULL , start_time => sysdate , sub_request => false , argument1=>stg_rec.EBS_JOURNAL_SOURCE,argument2=>p_debug_flag);
    COMMIT;
    IF lc_conc_req_id = 0 THEN
	lv_status:='Y';
	lv_file_status:='Y';
      logit(p_message =>'Conc. Program  failed to submit OD: GL Interface for Cloud GL Transactions Program');
	  Update XX_GL_JRNLS_CLD_INTF_STG set record_status='P',
				action='PROCESSED'
				where file_batch_id=rec.file_batch_id	
				and EBS_JOURNAL_SOURCE=stg_rec.EBS_JOURNAL_SOURCE;
    ELSE
	lv_status:='N';
	Update XX_GL_JRNLS_CLD_INTF_STG set record_status='P',
				action='PROCESSED'
				where file_batch_id=rec.file_batch_id	
				and EBS_JOURNAL_SOURCE=stg_rec.EBS_JOURNAL_SOURCE;
				
      lc_action              := 'Waiting for concurrent request OD: GL Interface for Cloud GL Transactions Program to complete';
      lc_wait_flag           := fnd_concurrent.wait_for_request(request_id => lc_conc_req_id, phase => lc_phase, status => lc_status, dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message);
      IF UPPER(lc_dev_status) = 'NORMAL' AND UPPER(lc_dev_phase) = 'COMPLETE' THEN
        logit(p_message =>'OD: GL Interface for Cloud GL Transactions Program successful for the Request Id: ' || lc_conc_req_id );

      ELSE
        logit(p_message =>'OD: GL Interface for Cloud GL Transactions Program did not complete normally. ');
		
      END IF;
    END IF;
	
	
  END;
  commit;

  end loop;
 if lv_file_status='N' then
  Update XX_GL_JRNLS_CLD_INTF_FILES xx
				set xx.record_status='P'				
				where xx.file_batch_id=rec.file_batch_id;
	commit;
 end if;
  end loop;


EXCEPTION
WHEN OTHERS THEN
  l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
  print_debug_msg(p_message => 'ERROR: Exception in PROCESS_JOURNAL_BATCH() API - '|| l_err_buff , p_force => true);
  logit('Error in PROCESS_JOURNAL_BATCH'||sqlerrm );
  p_retcode      := '2';
  p_errbuf       := l_err_buff;
END PROCESS_JOURNAL_BATCH;

/**********************************************************************************
* Procedure to process  MPL at different levels.
* This procedure is called by MAIN_PROCESS.
***********************************************************************************/
PROCEDURE PROCESS_LOAD_GL_FILE(
    p_process_name IN VARCHAR2,
    p_debug_flag   IN VARCHAR2)
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'PROCESS_LOAD_GL_FILE';
  lt_parameters gt_input_parameters;
  lc_action      VARCHAR2(1000);
  lc_conc_req_id NUMBER;
  lc_wait_flag   BOOLEAN;
  lc_phase       VARCHAR2(100);
  lc_status      VARCHAR2(100);
  lc_dev_phase   VARCHAR2(100);
  lc_dev_status  VARCHAR2(100);
  lc_message     VARCHAR2(100);
BEGIN
  lt_parameters('p_process_name') := p_process_name;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  lc_action := 'Submitting GL Data File Load Program';
  BEGIN
    lc_conc_req_id := fnd_request.submit_request ( application => 'XXFIN' , program => 'XXGLJRNLSCLDINTFLOAD' , description => NULL , start_time => sysdate , sub_request => false , argument1=>p_process_name,argument2=>p_debug_flag);
    COMMIT;
    IF lc_conc_req_id = 0 THEN
      logit(p_message =>'Conc. Program  failed to submit OD Cloud to EBS GL Journals Load Program');
    ELSE
      lc_action              := 'Waiting for concurrent request OD Cloud to EBS GL Journals Load Program to complete';
      lc_wait_flag           := fnd_concurrent.wait_for_request(request_id => lc_conc_req_id, phase => lc_phase, status => lc_status, dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message);
      IF UPPER(lc_dev_status) = 'NORMAL' AND UPPER(lc_dev_phase) = 'COMPLETE' THEN
        logit(p_message =>'OD Cloud to EBS GL Journals Load Program successful for the Request Id: ' || lc_conc_req_id );
      ELSE
        logit(p_message =>'OD Cloud to EBS GL Journals Load Program did not complete normally. ');
      END IF;
    END IF;
  END;

EXCEPTION
WHEN OTHERS THEN
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END PROCESS_LOAD_GL_FILE;


/**********************************************************************
* Main Procedure to Load Cloud GL Transactions and Import
* this procedure calls individual procedures to Load and process them.
***********************************************************************/
PROCEDURE MAIN_PROCESS(
    errbuff OUT VARCHAR2,
    retcode OUT NUMBER,
    p_process_name VARCHAR2,
    p_debug_flag   VARCHAR2)
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'MAIN_PROCESS';
  lt_parameters gt_input_parameters;
  lt_program_setups gt_translation_values;
  lc_action VARCHAR2(1000);
  x_err_buf varchar2(1000);
  x_ret_code number:=0;
BEGIN
  --================================================================
  --Initializing Global variables
  --================================================================
  print_debug_msg(p_message => 'Initializing Global Variables ' , p_force => true);
  /*gn_request_id := p_request_id;
  g_user_id     := fnd_global.user_id;
  g_login_id    := fnd_global.login_id; */
  gc_debug      := p_debug_flag;

  lt_parameters('p_process_name') := p_process_name;
  lt_parameters('p_debug_flag')   := p_debug_flag;

  entering_main(p_procedure_name => lc_procedure_name, p_rice_identifier => 'I046', p_debug_flag => p_debug_flag, p_parameters => lt_parameters);
  --================================================================
  --Adding parameters to the log file
  --================================================================
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Input Parameters' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Process Name:                  '|| p_process_name , p_force => true);
  print_debug_msg(p_message => 'Debug Flag  :                  '|| p_debug_flag , p_force => true);
  print_debug_msg(p_message => 'Request Id  :                  '|| fnd_global.conc_request_id , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);  

  /******************************
  * Call File Load Process.
  ******************************/
  lc_action := 'Invoke Load GL Interface File Process';

  PROCESS_LOAD_GL_FILE (p_process_name,p_debug_flag);



  --MAIN_LOAD_PROCESS(p_process_name,'EBS_GL_OD_INTF_SCM_OP_202002280646351.txt',p_debug_flag,fnd_global.conc_request_id,fnd_global.user_id);

  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling VAL_CLD_GL_INTF_FILE Procedure' , p_force => true);
  VAL_CLD_GL_INTF_FILE( p_process_name => p_process_name,p_debug_flag => p_debug_flag,p_errbuf=>x_err_buf,p_retcode=>x_ret_code) ;
  print_debug_msg(P_MESSAGE => 'Exiting VAL_CLD_GL_INTF_FILE Procedure' , p_force => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);

  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling CREATE_JOURNAL_BATCH Procedure' , p_force => true);
  CREATE_JOURNAL_BATCH( p_process_name => p_process_name,p_debug_flag => p_debug_flag,p_errbuf=>x_err_buf,p_retcode=>x_ret_code) ;
  print_debug_msg(P_MESSAGE => 'Exiting CREATE_JOURNAL_BATCH Procedure' , p_force => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);  

  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling PROCESS_JOURNAL_BATCH Procedure' , p_force => true);
  PROCESS_JOURNAL_BATCH( p_process_name => p_process_name,p_debug_flag => p_debug_flag,p_errbuf=>x_err_buf,p_retcode=>x_ret_code) ;
  print_debug_msg(P_MESSAGE => 'Exiting PROCESS_JOURNAL_BATCH Procedure' , p_force => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);  

EXCEPTION
WHEN OTHERS THEN
  logit(p_message => 'ERROR-SQLCODE:'|| SQLCODE || ' SQLERRM: ' || SQLERRM, p_force => TRUE); 
  logit(p_message => 'ERROR  Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM, p_force => TRUE);
  retcode := 2;
  errbuff := 'Error encountered. Please check logs';
    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
END MAIN_PROCESS;
END XX_GL_JRNLS_CLD_INTF_PKG;
/
show errors;
exit;