create or replace PACKAGE BODY XX_GL_JRNLS_CLD_INTF_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_GL_JRNLS_CLD_INTF_PKG                                                           |
  -- |                                                                                            |
  -- |  Description: This package body is load Oracle Cloud journals file into EBS Staging,Validate 
  -- |					and load into NA_STG Table.                                               |
  -- |  RICE ID   :  INT-046_Oracle Cloud GL Interface                                            |
  -- |  Description:  load Oracle Cloud journals file into EBS Staging,Validate 				  |
  -- |					and load into NA_STG Table.                                               |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         12/02/2020   M K Pramod Kumar     Initial version                              |
  -- | 1.1         19/06/2020   M K Pramod Kumar     Code Changes to trigger Journal Import Parallely
  --                                                 and remove logic to Create PA Batches based on Txn Number|
  -- | 1.2         19/07/2020   M K Pramod Kumar     Code Changes to show errors in output        | 
  -- | 1.3         14/08/2020   M K Pramod Kumar     Code Changes to error Load Program if any load issues|
  -- | 1.4         09/11/2020   Mayur Palsokar       NAIT-161587 fix, added XX_SEND_NOTIFICATION and XX_PURGE_STAGING procedures|
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
  gn_load_request_id			NUMBER;  -- Added for NAIT-161587

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

--/**********************************************************************
--* Procedure to send out mailer when GL import fails
--***********************************************************************/
procedure xx_send_notification(
                     p_request_id in number,
                     x_status out varchar2,
                     x_error out varchar2) is
   conn utl_smtp.connection;

lc_email_from varchar2 (3000):= 'no-reply@officedepot.com';
--lc_email_to varchar2 (3000):= 'mayur.palsokar@officedepot.com';
--lc_email_cc varchar2 (3000) := 'Padmanaban.Sanjeevi@OfficeDepot.com';
--lc_subject varchar2 (3000) := 'Test email';
lc_email_body varchar2 (3000) := '';
lc_database varchar2(50);
ln_request_id number := p_request_id;

ln_cnt NUMBER:=0;

lv_email_to VARCHAR2(3000);
lv_email_cc VARCHAR2(20000);

   
cursor cur_get_det is 
     select file_name,error_description 
	  from xx_gl_jrnls_cld_intf_files
	 where request_id=ln_request_id
	   and record_status ='E';   

CURSOR cur_get_cc_mail IS 
SELECT 
xftv.target_value1 email_id
FROM xx_fin_translatedefinition xftd,
xx_fin_translatevalues xftv
WHERE xftd.translation_name ='GL_INTERFACE_EMAIL'
AND xftv.source_value1     in ('Payables','Projects','Assets','Cash Management','Cost Management')
AND xftd.translate_id       =xftv.translate_id
AND xftd.enabled_flag       ='Y'
AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate)
UNION
SELECT 
xftv.target_value2 email_id
FROM xx_fin_translatedefinition xftd,
xx_fin_translatevalues xftv
WHERE xftd.translation_name ='GL_INTERFACE_EMAIL'
AND xftv.source_value1     in ('Payables','Projects','Assets','Cash Management','Cost Management')
AND xftd.translate_id       =xftv.translate_id
AND xftd.enabled_flag       ='Y'
AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate)
UNION
SELECT 
xftv.target_value3 email_id
FROM xx_fin_translatedefinition xftd,
xx_fin_translatevalues xftv
WHERE xftd.translation_name ='GL_INTERFACE_EMAIL'
AND xftv.source_value1     in ('Payables','Projects','Assets','Cash Management','Cost Management')
AND xftd.translate_id       =xftv.translate_id
AND xftd.enabled_flag       ='Y'
AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate);

CURSOR cur_get_to_mail IS
SELECT DISTINCT
xftv.target_value4 email_id
FROM xx_fin_translatedefinition xftd,
xx_fin_translatevalues xftv
WHERE xftd.translation_name ='GL_INTERFACE_EMAIL'
AND xftv.source_value1     in ('Payables','Projects','Assets','Cash Management','Cost Management')
AND xftd.translate_id       =xftv.translate_id
AND xftd.enabled_flag       ='Y'
AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate);
   
begin
  print_debug_msg(p_message => 'sending email procedure start' , p_force => true);  
  SELECT COUNT(1)
    INTO ln_cnt
  	FROM xx_gl_jrnls_cld_intf_files
   WHERE request_id=ln_request_id
     AND record_status ='E';   
	 
  print_debug_msg(p_message => 'No of files with errors :'||TO_CHAR(ln_cnt) , p_force => true);   	 

  IF ln_cnt<>0 THEN
     lc_email_body := '<p>Hi,</p>'||chr(13)||
     '<p>GL import with Request ID- '||ln_request_id||' is failed.'||' Please find the details below.</p>'||chr(10);
     for i in cur_get_det
     loop 
	  lc_email_body := lc_email_body || '<p><B>File Name: </B>'||i.file_name||'<br>'||  
      '<B>Error Description: </B>'||i.error_description||'</p>';
     end loop;   
	  
     begin
         select name
           into lc_database
           from v$database;
     exception
       when others then
         lc_database := 'GSIDEV02';
     end;
	 /* 
     if lc_database <> 'GSIPRDGB' then -- to chec   
        lc_subject := 'Please ignore this email: '|| lc_subject;
 	 end if; 
	 */
	 FOR j IN cur_get_cc_mail LOOP
	    IF j.email_id IS NOT NULL THEN 
			IF lv_email_cc IS NULL THEN 
				lv_email_cc := j.email_id ;
			ELSE 
				lv_email_cc := lv_email_cc ||','||j.email_id ;
			END IF;
		END IF;
	 END LOOP;
	 
	 FOR k IN cur_get_to_mail LOOP
		IF k.email_id IS NOT NULL THEN 
			IF lv_email_to IS NULL THEN 
				lv_email_to := k.email_id ;
			ELSE 	
				lv_email_to := lv_email_to ||','||k.email_id ;
			END IF;
		END IF;
	 END LOOP;
	 
        
	 conn := xx_pa_pb_mail.begin_mail(sender => lc_email_from,
                                 recipients => lv_email_to,--lc_email_to,
                                 cc_recipients=>lv_email_cc,--lc_email_cc,
                                 subject => 'Oracle Cloud Journal Files Are Not Able To Process Please Check', --lc_subject,
                                 mime_type => xx_pa_pb_mail.multipart_mime_type);
     xx_pa_pb_mail.attach_text( conn => conn,
                                       data => lc_email_body,
                                       mime_type =>'text/html'
                                                );

     xx_pa_pb_mail.end_mail( conn => conn );
     x_status := 's';
   
     commit;
  END IF;   
exception when others then
   x_status:='e';
   x_error := 'error while sending mail '||sqlerrm;
      print_debug_msg(p_message => 'error in xx_send_notification'||sqlerrm , p_force => true);  
end xx_send_notification;

--/**********************************************************************
--* Procedure to automatically purge data in staging tables after 60 days
--***********************************************************************/
procedure xx_purge_staging 
is 
begin 
  delete 
	   from xx_gl_jrnls_cld_intf_stg
	  where file_batch_id in (select file_batch_id
						        from xx_gl_jrnls_cld_intf_files
							   where creation_date < sysdate-60
								);
	 commit;
	 
	 delete 
	   from xx_gl_jrnls_cld_intf_files
      where creation_date < sysdate-60;
	  
     commit;
	 
exception
when others then
       print_debug_msg(p_message => 'error in xx_purge_staging procedure '||sqlerrm , p_force => true); 
end xx_purge_staging;

-- +===================================================================+
-- | Name  :FORMAT_TABS                                                |
-- | Description : Format utility procedure. Used in CREATE_OUTPUT_FILE|
-- |                                                                   |
-- |                                                                   |
-- | Parameters :p_message (msg written), p_space (# of spaces)        |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
   FUNCTION FORMAT_TABS (p_tab_total   IN  NUMBER DEFAULT 0 )
    RETURN VARCHAR2

   IS

          ln_tab_cnt     NUMBER := 0;
          lc_tabs        VARCHAR2(1000);
          lc_debug_msg   VARCHAR2(1000);
          lc_debug_prog  VARCHAR2(25) := 'FORMAT_TABS';


   BEGIN
               lc_tabs := ' ';
               LOOP
               EXIT WHEN  ln_tab_cnt = p_tab_total;

                   lc_tabs := lc_tabs || lc_tabs;
                   ln_tab_cnt := ln_tab_cnt + 1;

               END LOOP;

               RETURN lc_tabs;

    EXCEPTION
    WHEN OTHERS THEN
	logit('Error in FORMAT_TABS'||sqlerrm );
	Return lc_tabs;
	
   END FORMAT_TABS;


-- +===================================================================+
-- | Name  :CREATE_OUTPUT_FILE                                         |
-- | Description : This procedure will be used to format data written  |
-- |               to the ouput file for to report Validation Errors   |
-- |                                                                   |
-- | Parameters : p_file_batch_id                                      |
-- |                                                                   |
-- | Returns :   NA                                                    |
-- |                                                                   |
-- +===================================================================+
PROCEDURE  CREATE_OUTPUT_FILE(p_process_name varchar2,
								p_file_name varchar2,
							  p_file_batch_id  IN NUMBER   DEFAULT NULL,
							  p_error_msg OUT VARCHAR2 ,
							  p_retcode OUT VARCHAR2)
is

cursor cr_distinct_source is select distinct user_je_source_name
from XX_GL_JRNLS_CLD_INTF_STG where file_batch_id=p_file_batch_id
and error_description is not null; 

cursor cr_error_rec(p_je_source varchar2) is 
select * from  XX_GL_JRNLS_CLD_INTF_STG
where file_batch_id=p_file_batch_id
and user_je_source_name=p_je_source
and record_status in ('V','E')
and error_description is not null;

TYPE lv_error_rec_tab IS TABLE OF cr_error_rec%ROWTYPE 
         INDEX BY BINARY_INTEGER;
lv_error_rec_data                  lv_error_rec_tab;	
lv_header_flg varchar2(1):='N';
lc_ccid_acct varchar2(100);

lv_errors_count number:=0;
BEGIN
print_output('OFFICE DEPOT, INC'
             ||FORMAT_TABS(4)
             ||'OD GL Journal Interface Error Report'
             ||FORMAT_TABS(4)||'Report Date: '
             ||to_char(sysdate,'DD-MON-YYYY HH24:MI'));
			 
print_output('');
print_output('Parameters');
print_output('Request ID: '|| fnd_global.conc_request_id);
print_output('Process Name: '|| p_process_name);
print_output('File Name: '|| p_file_name);


for rec in cr_distinct_source loop

lv_header_flg:='N';

    OPEN cr_error_rec(rec.user_je_source_name);
			Loop
			FETCH cr_error_rec
				BULK COLLECT INTO lv_error_rec_data LIMIT 5000;
				EXIT WHEN lv_error_rec_data.COUNT = 0;
				FOR idx IN lv_error_rec_data.FIRST .. lv_error_rec_data.LAST
					LOOP
					lv_errors_count:=lv_errors_count+1;
					if lv_header_flg='N' then 
					
					lv_header_flg:='Y';
					print_output('');
					print_output('');
					print_output(SUBSTR(RPAD('FILE_NAME',50),1,50)
                               ||' '|| SUBSTR(RPAD('CLOUD_APP_NAME',25),1,25)
                               ||' '|| SUBSTR(RPAD('PERIOD_NAME',10),1,10)
                               ||' '|| SUBSTR(RPAD('ACCOUNTING_DATE',10),1,10)
                               ||' '|| SUBSTR(RPAD('CLOUD_JE_SOURCE',25),1,25)
							   ||' '|| SUBSTR(RPAD('CLOUD_JE_CATEGORY',25),1,25)
							   ||' '|| SUBSTR(RPAD('CLOUD_ACC_CLASS',25),1,25)
							   ||' '|| SUBSTR(RPAD('EBS_APPLICATION_NAME',25),1,25)
							   ||' '|| SUBSTR(RPAD('EBS_JOURNAL_SOURCE',25),1,25)
							   ||' '|| SUBSTR(RPAD('EBS_JOURNAL_CATEGORY',25),1,25)
							   ||' '|| SUBSTR(RPAD('LINE_DESCRIPTION',50),1,50)
							   ||' '|| SUBSTR(RPAD('EBS_ACCOUNT_STRING',40),1,40)
							   ||' '|| SUBSTR(RPAD('ERROR_DESCRIPTION',200),1,200));
							   
					print_output(SUBSTR(RPAD('---------',50),1,50)
                               ||' '|| SUBSTR(RPAD('-------------',25),1,25)
                               ||' '|| SUBSTR(RPAD('------------',10),1,10)
                               ||' '|| SUBSTR(RPAD('---------------',10),1,10)
                               ||' '|| SUBSTR(RPAD('---------------',25),1,25)
							   ||' '|| SUBSTR(RPAD('----------------',25),1,25)
							   ||' '|| SUBSTR(RPAD('---------------',25),1,25)
							   ||' '|| SUBSTR(RPAD('-------------------',25),1,25)
							   ||' '|| SUBSTR(RPAD('-----------------',25),1,25)
							   ||' '|| SUBSTR(RPAD('-------------------',25),1,25)
							   ||' '|| SUBSTR(RPAD('----------------',50),1,50)
							   ||' '|| SUBSTR(RPAD('------------------',40),1,40)
							   ||' '|| SUBSTR(RPAD('------------------',200),1,200));
							   
					end if;
					
					lc_ccid_acct:=lv_error_rec_data(idx).segment1||'.'||
									       lv_error_rec_data(idx).segment2||'.'||
									       lv_error_rec_data(idx).segment3||'.'||
									       lv_error_rec_data(idx).segment4||'.'||
									       lv_error_rec_data(idx).segment5||'.'||
									       lv_error_rec_data(idx).segment6||'.'||
									       lv_error_rec_data(idx).segment7;
										   
					print_output(SUBSTR(RPAD(lv_error_rec_data(idx).FILE_NAME,50),1,50)
                               ||' '|| SUBSTR(RPAD(lv_error_rec_data(idx).APPLICATION_NAME,25),1,25)
                               ||' '|| SUBSTR(RPAD(lv_error_rec_data(idx).PERIOD_NAME,10),1,10)
                               ||' '|| SUBSTR(RPAD(lv_error_rec_data(idx).ACCOUNTING_DATE,10),1,10)
                               ||' '|| SUBSTR(RPAD(lv_error_rec_data(idx).USER_JE_SOURCE_NAME,25),1,25)
							   ||' '|| SUBSTR(RPAD(lv_error_rec_data(idx).USER_JE_CATEGORY_NAME,25),1,25)
							   ||' '|| SUBSTR(RPAD(lv_error_rec_data(idx).ACCOUNTING_CLASS_CODE,25),1,25)
							   ||' '|| SUBSTR(RPAD(NVL(lv_error_rec_data(idx).EBS_APPLICATION_NAME,' '),25),1,25)
							   ||' '|| SUBSTR(RPAD(NVL(lv_error_rec_data(idx).EBS_JOURNAL_SOURCE,' '),25),1,25)
							   ||' '|| SUBSTR(RPAD(NVL(lv_error_rec_data(idx).EBS_JOURNAL_CATEGORY,' '),25),1,25)
							   ||' '|| SUBSTR(RPAD(NVL(lv_error_rec_data(idx).LINE_DESCRIPTION,' '),50),1,50)
							   ||' '|| SUBSTR(RPAD(lc_ccid_acct,40),1,40)
							   ||' '|| SUBSTR(RPAD(lv_error_rec_data(idx).ERROR_DESCRIPTION,200),1,200));
					
				end loop;
			end loop;
		close cr_error_rec;	
					

end loop;
if lv_errors_count=0 then 
print_output('File Error Count: '|| lv_errors_count);
print_output('');
print_output('==================================');
print_output('');

else
print_output('');
print_output('============================================================================================');
print_output('');
end if;
	
EXCEPTION
WHEN OTHERS THEN
  p_retcode   := '2';
  p_error_msg := 'Error in XX_GL_JRNLS_CLD_INTF_PKG.CREATE_OUTPUT_FILE - record:'||p_file_batch_id||SUBSTR(sqlerrm,1,150);
END CREATE_OUTPUT_FILE;	
	


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
	group by xfile.file_batch_id,stg.EBS_LEDGER_NAME,stg.EBS_JOURNAL_SOURCE
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


  ln_group_id           NUMBER;
  lc_dr_msg varchar2(1000);
  lc_cr_msg varchar2(1000);
  l_resp_id number;
  l_app_id number;

  lc_ap_ccid_acct varchar2(100);
  ln_ap_ccid number;
  ex_recon_batch_exception Exception;
  lc_error_status_flag varchar2(1):='N';
  lv_jrnl_line_desc XX_GL_JRNLS_CLD_INTF_STG.LINE_DESCRIPTION%type;
  
Begin

  p_retcode:=0;
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
						lv_jrnl_line_desc:=null;

					if p_process_name='FIN' then
						if lc_error_status_flag = 'N' then 
						
						if lv_gl_journals_batch_data(idx).transaction_number is not null then 
							lv_jrnl_line_desc:=lv_gl_journals_batch_data(idx).transaction_number||'~'||lv_gl_journals_batch_data(idx).LINE_DESCRIPTION;
						else
							lv_jrnl_line_desc:=lv_gl_journals_batch_data(idx).LINE_DESCRIPTION;
						end if;
						
						
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
                                               , p_je_line_dsc =>lv_jrnl_line_desc
                                               , x_output_msg => lc_cr_msg
                                               );

						end if;	

						if  lc_cr_msg IS NOT NULL THEN
						    Rollback;
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

				print_debug_msg(p_message=> 'Processed Successfully File Batch Id:'||rec.file_batch_id||',EBS Ledger Name:'||rec.EBS_LEDGER_NAME||'Journal Source:'||rec.EBS_JOURNAL_SOURCE,p_force=> true);
				Update XX_GL_JRNLS_CLD_INTF_STG set record_status='I',
				action='INSERT',
				group_id=ln_group_id
				where file_batch_id=rec.file_batch_id	
				and EBS_LEDGER_NAME=rec.EBS_LEDGER_NAME
				and EBS_JOURNAL_SOURCE=rec.EBS_JOURNAL_SOURCE;
				
                if SQL%ROWCOUNT=0 THEN				
				IF rec.EBS_LEDGER_NAME IS NULL OR rec.EBS_JOURNAL_SOURCE IS NULL THEN 
				    print_debug_msg(p_message=> 'Processed Failed File Batch Id:'||rec.file_batch_id||',EBS Ledger Name:'||rec.EBS_LEDGER_NAME||'Journal Source:'||rec.EBS_JOURNAL_SOURCE,p_force=> true);
					print_debug_msg(p_message=>'Updating XX_GL_JRNLS_CLD_INTF_STG with Error Status as EBS Ledger/EBS Journal Source is null.Reprocess Data File after correcting Ledger Name/Journal Source',p_force=> true);
					Update XX_GL_JRNLS_CLD_INTF_STG set record_status='E',
					action='ERROR',
					group_id=ln_group_id
					where file_batch_id=rec.file_batch_id;
								
				END IF;				
				END IF;

				Update XX_GL_JRNLS_CLD_INTF_FILES
				set record_status='I'
				where file_batch_id=rec.file_batch_id;
				commit;

			else
			  Rollback;
			  print_debug_msg(p_message=> 'Processing Failed with errors File Batch Id:'||rec.file_batch_id||',EBS Ledger Name:'||rec.EBS_LEDGER_NAME||'Journal Source:'||rec.EBS_JOURNAL_SOURCE,p_force=> true);
			    Update XX_GL_JRNLS_CLD_INTF_STG set record_status='I',
				action='INSERT',
				group_id=ln_group_id
				where file_batch_id=gn_file_batch_id	
				and EBS_LEDGER_NAME=rec.EBS_LEDGER_NAME
				and EBS_JOURNAL_SOURCE=rec.EBS_JOURNAL_SOURCE;			
				
			    -- Added for NAIT-161587
				Update XX_GL_JRNLS_CLD_INTF_FILES
				set record_status='E',
				error_description=ERROR_DESCRIPTION||'~Error occured in CREATE_JOURNAL_BATCH '
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
  Rollback;
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
  and RECORD_STATUS in ('N')
  and action in ('NEW');

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
  and RECORD_STATUS in ('N')
  and action in ('NEW');

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
  and RECORD_STATUS in ('N')
  and action in ('NEW');

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
  and RECORD_STATUS in ('N')
  and action in ('NEW');

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
  and RECORD_STATUS in ('N')
  and action in ('NEW');

  TYPE lv_user_je_sourcE_name_tab IS TABLE OF cur_user_je_sourcE_name%ROWTYPE  
         INDEX BY BINARY_INTEGER;	

		 lv_user_je_sourcE_name_data                  lv_user_je_sourcE_name_tab;	


 --==========================================================================================
  -- Cursor Declarations for Debits and Credits Balanced
  --==========================================================================================
  cursor cur_jrnls_dr_cr_bal is   
  select ebs_ledger_name,application_name,
		 USER_JE_CATEGORY_NAME,
		 ae_header_id,  
		 sum(NVL(entered_dr,0)) total_dr,
  sum(NVL(entered_cr,0)) total_cr,
  sum(NVL(accounted_dr,0)) total_acc_dr,
   sum(NVL(accounted_cr,0)) total_acc_cr  
from  
XX_GL_JRNLS_CLD_INTF_STG 
  where 1=1
  and file_batch_id=gn_file_batch_id
  and RECORD_STATUS in ('N')
  and action in ('NEW')  
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
  and RECORD_STATUS in ('N')
  and action in ('NEW') 
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
  and RECORD_STATUS in ('N')
  and action in ('NEW');

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
  and RECORD_STATUS in ('N')
  and action in ('NEW');

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
	  and process_name=p_process_name;
	  lv_error_loc varchar2(1000) :=null;

  x_err_buf varchar2(1000);
  x_ret_code number:=0;

  lc_jrnl_source_error_flag 	VARCHAR2(1);   -- Added for NAIT-161587
  lc_jrnl_category_error_flag 	VARCHAR2(1);   -- Added for NAIT-161587
  lc_ledger_error_flag			VARCHAR2(1);   -- Added for NAIT-161587
 

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
  
  lc_jrnl_source_error_flag 	:='N';  -- Added for NAIT-161587
  lc_jrnl_category_error_flag 	:='N';  -- Added for NAIT-161587
  lc_ledger_error_flag			:='N';  -- Added for NAIT-161587

  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => False);  
  logit(p_message =>'Processing File Name:'||file_rec.file_name);
  logit(p_message =>'gn_file_batch_id:'||gn_file_batch_id);

   --==========================================================================================
  -- Cursor Declarations for Ledger Name Validation
  --==========================================================================================
  lv_error_loc:='Ledger Name Validation begins';
  print_debug_msg(p_message => 'Ledger Validation Begins' , p_force => False);

  
  
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
							 lc_ledger_error_flag:='Y';   -- Added for NAIT-161587
							 lv_error_message :='Oracle Cloud Ledger '||lv_ledger_name_data(idx).ledger_name||' not found.';
							 logit(lv_error_message);
						  when others then
						    gc_error_status_flag:='Y';
							lc_ledger_error_flag:='Y';		-- Added for NAIT-161587					
							lv_error_message:='Validation error-Oracle Cloud Ledger '||lv_ledger_name_data(idx).ledger_name ||' not found.SQLERRM-'||sqlerrm||'.';  
							logit(lv_error_message);							

						 end;

						 if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=decode(ERROR_DESCRIPTION,null,lv_error_message,ERROR_DESCRIPTION||'~'||lv_error_message)								
								where 1=1
								and file_batch_id=gn_file_batch_id
								and ledger_name=lv_ledger_name_data(idx).ledger_name;
								gc_error_status_flag:='N';
								p_retcode:=1;
						end if;


					end loop;
			end loop;
    print_debug_msg(p_message => 'Ledger Validation Completed' , p_force => False);
	close cur_ledger_name;
	commit;

  if p_process_name='FIN' then

  --==========================================================================================
  -- Cursor Declarations for Application Name Validation
  --==========================================================================================
  gc_error_status_flag:='N';
  lv_error_loc:='Application Name Validation begins for FIN Transactions';
  print_debug_msg(p_message => 'Application Name Validation Begins' , p_force => False);
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
							 lv_error_message :='Application Name '||lv_application_name_data(idx).application_name||' not found';
							 logit(lv_error_message);
						 when others then 
						  lv_error_message:='Validation error-Applicaiton '||lv_application_name_data(idx).application_name||' not found. SQLERRM-'||sqlerrm||'.';						    
						  gc_error_status_flag:='Y';
						  logit(lv_error_message);
						end;				 

						if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=decode(ERROR_DESCRIPTION,null,lv_error_message,ERROR_DESCRIPTION||'~'||lv_error_message)								
								where 1=1
								and file_batch_id=gn_file_batch_id
								and application_name=lv_application_name_data(idx).application_name;
								p_retcode:=1;
								gc_error_status_flag:='N';
						end if;

					end loop;
			end loop;
    print_debug_msg(p_message => 'Application Name Validation Completed' , p_force => False);
     close cur_application_name;
	 commit;

  --==========================================================================================
  -- Cursor Declarations for Joural Sourace Validation
  --==========================================================================================
	 gc_error_status_flag:='N';
	 lv_error_loc:='Journal Source Name Validation begins for FIN Transactions';	 
     print_debug_msg(p_message => 'Journal Source Name Validation Begins' , p_force => False);	 
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
						     lv_error_message :='Journal Source '||lv_user_je_sourcE_name_data(idx).user_je_source_name||' not found';
							 gc_error_status_flag:='Y';
							 lc_jrnl_source_error_flag:='Y';     -- Added for NAIT-161587
							 logit(lv_error_message);
						  when others then
							lv_error_message:='Validation error-Journal Source '||lv_user_je_sourcE_name_data(idx).user_je_source_name||' not found. SQLERRM-'||sqlerrm||'.';
						    gc_error_status_flag:='Y';
							lc_jrnl_source_error_flag:='Y';	    -- Added for NAIT-161587				
							logit(lv_error_message);
						 end;

						  if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=decode(ERROR_DESCRIPTION,null,lv_error_message,ERROR_DESCRIPTION||'~'||lv_error_message)								
								where 1=1
								and file_batch_id=gn_file_batch_id
								and user_je_source_name=lv_user_je_sourcE_name_data(idx).user_je_source_name;
								gc_error_status_flag:='N';
								p_retcode:=1;
						end if;

					end loop;
			end loop;
             print_debug_msg(p_message => 'Journal Source Name Validation Completed' , p_force => False);	
            close cur_user_je_sourcE_name;
			commit;



 --==========================================================================================
  -- Cursor Declarations to check if Debits and Credits Balance
  --==========================================================================================	
	 		gc_error_status_flag:='N';
			lv_error_loc:='Debits and Credits Balance validation begins for FIN Transactions';
			print_debug_msg(p_message => 'Debits and Credits Balance validation begins for FIN Transactions' , p_force => False);	
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
							 lv_error_message :='Debits and Credits do not balance for this transaction.Cloud AE Header ID-'||lv_jrnls_dr_cr_bal_data(idx).ae_header_id;
							 logit(lv_error_message);
							 
						end if;
						
						 if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=decode(ERROR_DESCRIPTION,null,lv_error_message,ERROR_DESCRIPTION||'~'||lv_error_message)								
								where 1=1
								and file_batch_id+0=gn_file_batch_id       -- Added for NAIT-161587
								and ae_header_id=lv_jrnls_dr_cr_bal_data(idx).ae_header_id
								and ebs_ledger_name=lv_jrnls_dr_cr_bal_data(idx).ebs_ledger_name
								and application_name=lv_jrnls_dr_cr_bal_data(idx).application_name
								and NVL(USER_JE_CATEGORY_NAME,'X')=NVL(lv_jrnls_dr_cr_bal_data(idx).USER_JE_CATEGORY_NAME,'X');   -- Added for NAIT-161587

						end if;
						
						lv_error_message:=null;
						
						if  abs(lv_jrnls_dr_cr_bal_data(idx).total_acc_dr)<>abs(lv_jrnls_dr_cr_bal_data(idx).total_acc_cr) then 

							 gc_error_status_flag:='Y';
							 lv_error_message :='Accounted Debits and Credits do not balance for this transaction.Cloud AE Header ID-'||lv_jrnls_dr_cr_bal_data(idx).ae_header_id;
							 logit(lv_error_message);

						end if;

						 if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=decode(ERROR_DESCRIPTION,null,lv_error_message,ERROR_DESCRIPTION||'~'||lv_error_message)								
								where 1=1
								and file_batch_id+0=gn_file_batch_id          -- Added for NAIT-161587
								and ae_header_id=lv_jrnls_dr_cr_bal_data(idx).ae_header_id
								and ebs_ledger_name=lv_jrnls_dr_cr_bal_data(idx).ebs_ledger_name
								and application_name=lv_jrnls_dr_cr_bal_data(idx).application_name
								and NVL(USER_JE_CATEGORY_NAME,'X')=NVL(lv_jrnls_dr_cr_bal_data(idx).USER_JE_CATEGORY_NAME,'X');    -- Added for NAIT-161587

						end if;


					end loop;
			end loop;
			print_debug_msg(p_message => 'Debits and Credits Balance validation completed for FIN Transactions' , p_force => False);	
			close cur_jrnls_dr_cr_bal;
			commit;
	end if;	

	if p_process_name='SCM' then



    --==========================================================================================
  -- Cursor Declarations for Joural Sourace Validation
  --==========================================================================================
	 gc_error_status_flag:='N';
	 lv_error_loc:='Journal Source Name Validation begins for SCM Transactions';	  
	 print_debug_msg(p_message => 'Journal Source Name Validation begins for SCM Transactions' , p_force => False);	
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
						     lv_error_message :='Journal Source '||lv_user_je_sourcE_name_data(idx).user_je_source_name||' not found';
							 gc_error_status_flag:='Y';
							 lc_jrnl_source_error_flag:='Y';       -- Added for NAIT-161587
							 logit(lv_error_message);
						  when others then
							lv_error_message:='Validation error-Journal Source '||lv_user_je_sourcE_name_data(idx).user_je_source_name||' not found. SQLERRM-'||sqlerrm||'.';
						    gc_error_status_flag:='Y';
							lc_jrnl_source_error_flag:='Y';       -- Added for NAIT-161587
							logit(lv_error_message);
						 end;

						  if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=decode(ERROR_DESCRIPTION,null,lv_error_message,ERROR_DESCRIPTION||'~'||lv_error_message)								
								where 1=1
								and file_batch_id=gn_file_batch_id
								and user_je_source_name=lv_user_je_sourcE_name_data(idx).user_je_source_name;
								gc_error_status_flag:='N';
								p_retcode:=1;
						end if;

					end loop;
			end loop;
			print_debug_msg(p_message => 'Journal Source Name Validation completed for SCM Transactions' , p_force => False);	
            close cur_user_je_sourcE_name;
			commit;

  --==========================================================================================
  -- Cursor Declarations to check if Debits and Credits Balance for SCM Transactions
  --==========================================================================================	
	 		gc_error_status_flag:='N';
			lv_error_loc:='Debits and Credits Balance Validation begins for SCM Transactions';
			print_debug_msg(p_message => 'Debits and Credits Balance Validation begins for SCM Transactions' , p_force => False);	
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
							 lv_error_message :='Debits and Credits did not balance for this transaction.TRANSACTION Number-'||lv_jrnls_dr_cr_bal_scm_data(idx).reference10;
							 logit(lv_error_message);
						end if;


						if  abs(lv_jrnls_dr_cr_bal_scm_data(idx).total_acc_dr)<>abs(lv_jrnls_dr_cr_bal_scm_data(idx).total_acc_cr) then 

							 gc_error_status_flag:='Y';
							 lv_error_message :='Accounted Debits and Credits did not balance for this transaction.TRANSACTION Number-'||lv_jrnls_dr_cr_bal_scm_data(idx).reference10;
							 logit(lv_error_message);

						end if;

						 if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=decode(ERROR_DESCRIPTION,null,lv_error_message,ERROR_DESCRIPTION||'~'||lv_error_message)								
								where 1=1
								and file_batch_id=gn_file_batch_id
								and reference10=lv_jrnls_dr_cr_bal_scm_data(idx).reference10;
								gc_error_status_flag:='N';
						end if;


					end loop;
			end loop;
			close cur_jrnls_dr_cr_bal_scm;
			commit;
			print_debug_msg(p_message => 'Debits and Credits Balance Validation completed for SCM Transactions' , p_force => False);	

	end if;


  --==========================================================================================
  -- Cursor Declarations for Currency Code Validation
  --==========================================================================================	
	 	gc_error_status_flag:='N';
		lv_error_loc:='Currency Code Validation begins';
		print_debug_msg(p_message => 'Currency Code Validation begins' , p_force => False);	
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
							 lv_error_message :='Currency Code '||lv_currency_code_data(idx).currency_code ||' not found';	
							 logit(lv_error_message);
						  when others then 
						  lv_error_message:='Validation error-Currency Code '||lv_currency_code_data(idx).currency_code||' not found. SQLERRM-'||sqlerrm||'.'; 						   
						  gc_error_status_flag:='Y';
						  logit(lv_error_message);						  
						 end;

						  if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=decode(ERROR_DESCRIPTION,null,lv_error_message,ERROR_DESCRIPTION||'~'||lv_error_message)								
								where 1=1
								and file_batch_id=gn_file_batch_id
								and currency_code=lv_currency_code_data(idx).currency_code;
								gc_error_status_flag:='N';
						end if;

					end loop;
			end loop;

          print_debug_msg(p_message => 'Currency Code Validation completed' , p_force => False);	  
		close cur_currency_code;
		commit;	
 --==========================================================================================
  -- Cursor Declarations for User JE Category Name Validation
  --==========================================================================================	
	 		gc_error_status_flag:='N';
			lv_error_loc:='Journal Category Name Validation begins';
			print_debug_msg(p_message => 'User Journal Category Name Validation begins' , p_force => False);	
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
									lv_error_message :='User JE Category '||lv_user_catg_name_data(idx).user_je_category_name||' not found';
									gc_error_status_flag:='Y';
									logit(lv_error_message);
								end;
						    
						 when others then
							lv_error_message:='Validation error-User JE Category '||lv_user_catg_name_data(idx).user_je_category_name||' not found. SQLERRM-'||sqlerrm||'.';						   
						    gc_error_status_flag:='Y';
							logit(lv_error_message);
						 end;

						  if gc_error_status_flag='Y' then
							Update XX_GL_JRNLS_CLD_INTF_STG set 				   
								ERROR_DESCRIPTION=decode(ERROR_DESCRIPTION,null,lv_error_message,ERROR_DESCRIPTION||'~'||lv_error_message)								
								where 1=1
								and file_batch_id=gn_file_batch_id
								and user_je_category_name=lv_user_catg_name_data(idx).user_je_category_name;
								p_retcode:=1;
								lc_jrnl_category_error_flag:='Y';       -- Added for NAIT-161587

						end if; 

					end loop;
			end loop;
			print_debug_msg(p_message => 'User Journal Category Name Validation Completed' , p_force => False);	
		close cur_user_category_name;
		commit;	


  --==========================================================================================
  -- Cursor if any segments is missing
  --==========================================================================================	
	 		gc_error_status_flag:='N';
			lv_error_loc:='Code Combination Segments is Null validation begins';
			print_debug_msg(p_message => 'Code Combination Segments is Null validation begins' , p_force => False);	
			OPEN cur_select_segments;
			Loop
			FETCH cur_select_segments 
				BULK COLLECT INTO lv_cur_select_segments_data LIMIT 5000;
				EXIT WHEN lv_cur_select_segments_data.COUNT = 0;

					FOR idx IN lv_cur_select_segments_data.FIRST .. lv_cur_select_segments_data.LAST
					LOOP

					 lv_error_message :='Code Combination Segments is missing-'||lv_cur_select_segments_data(idx).segment1 ||'.'||lv_cur_select_segments_data(idx).segment2 ||'.'||lv_cur_select_segments_data(idx).segment3 ||'.'||lv_cur_select_segments_data(idx).segment4 ||'.'||lv_cur_select_segments_data(idx).segment5 ||'.'||lv_cur_select_segments_data(idx).segment6;

						if (lv_cur_select_segments_data(idx).segment1 is null or 
						lv_cur_select_segments_data(idx).segment2 is null   or
						lv_cur_select_segments_data(idx).segment3 is null   or
						lv_cur_select_segments_data(idx).segment4 is null   or
						lv_cur_select_segments_data(idx).segment5 is null   or
						lv_cur_select_segments_data(idx).segment6 is null) then 

						Update XX_GL_JRNLS_CLD_INTF_STG set 
						     	ERROR_DESCRIPTION=decode(ERROR_DESCRIPTION,null,lv_error_message,ERROR_DESCRIPTION||'~'||lv_error_message)								
							 where rowid=lv_cur_select_segments_data(idx).rowid	;
							 gc_error_status_flag:='Y';
							 logit(lv_error_message);
						end if;



					end loop;
			end loop;
			print_debug_msg(p_message => 'Code Combination Segments is Null validation completed' , p_force => False);	
			close cur_select_segments;

			commit;	

  --==========================================================================================
  -- Cursor to derive CCID validation
  --==========================================================================================	

        gc_error_status_flag:='N';
		lv_error_loc:='CCID derivation begins';
			print_debug_msg(p_message => 'Derive Code Combination ID validation begins' , p_force => False);
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
													logit(lv_error_message);
												
												Update XX_GL_JRNLS_CLD_INTF_STG set 												    
												    error_description=decode(ERROR_DESCRIPTION,null,lv_error_message,ERROR_DESCRIPTION||'~'||lv_error_message)								
												    where rowid=lv_derive_ccid_data(idx).rowid;	
											else
											 Update XX_GL_JRNLS_CLD_INTF_STG set 												    
												    CODE_COMBINATION_ID=lv_derived_ccid
												    where rowid=lv_derive_ccid_data(idx).rowid;												
											end if;
						 Exception 
							when others then
							lv_error_message:='Error to derive Code Combination Id-'||lc_ccid_acct||'. SQLERRM-'||sqlerrm;						   
						    gc_error_status_flag:='Y';
							logit(lv_error_message);
							Update XX_GL_JRNLS_CLD_INTF_STG set 												    
								error_description=decode(ERROR_DESCRIPTION,null,lv_error_message,ERROR_DESCRIPTION||'~'||lv_error_message)								
								where rowid=lv_derive_ccid_data(idx).rowid;	
						 end;

						

					end loop;
			end loop;
	    print_debug_msg(p_message => 'Derive Code Combination ID validation completes' , p_force => False);
		close cur_derive_ccid;
		commit;
		

			if gc_error_status_flag='Y' then
				
				/*update XX_GL_JRNLS_CLD_INTF_FILES set record_status='V'--Update all records to Valid.Update to E when required. 
				where 1=1
				and file_batch_id=gn_file_batch_id;		
				*/              -- Commented for NAIT-161587
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
			/*Start: -- Added for NAIT-161587 */
			IF (    lc_jrnl_source_error_flag='Y' 
			     OR lc_jrnl_category_error_flag='Y'
				 OR lc_ledger_error_flag='Y'
			   ) THEN
			   
			   update xx_gl_jrnls_cld_intf_files 
			      set record_status='E',
					  error_description=error_description||', Setup Error'
				where 1=1
				  and file_batch_id=gn_file_batch_id; 
			
			END IF;

			update xx_gl_jrnls_cld_intf_files stg
			   set stg.record_status='E',
			       stg.error_description=stg.error_description||' ,Debits and Credits did not balance'
		     where 1=1
			   and stg.file_batch_id=gn_file_batch_id
			   and EXISTS (SELECT 'x'
						     FROM xx_gl_jrnls_cld_intf_stg
							WHERE file_batch_id=gn_file_batch_id
							  AND error_description LIKE '%Debits and Credits do not balance%'
				   	      );
			commit;
            /* End: -- Added for NAIT-161587 */
			
  CREATE_OUTPUT_FILE( p_process_name =>p_process_name,p_file_name=>file_rec.file_name,p_file_batch_id => gn_file_batch_id,p_error_msg=>x_err_buf,p_retcode=>x_ret_code) ;
  if x_err_buf is not null then
  print_debug_msg(P_MESSAGE => 'VAL_CLD_GL_INTF_FILE, p_errbuf-' ||x_err_buf ||' ,p_retcode-'||x_ret_code, p_force => TRUE);
  end if;
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => False);		
  end loop;
EXCEPTION
WHEN OTHERS THEN
  l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
  print_debug_msg(p_message => 'ERROR: Exception in VALIDATE_CLD_GL_INTF_AP_FILE() API -Error Loc:'||lv_error_loc||'.Error:'|| l_err_buff , p_force => true);
  logit('Error in VALIDATE_CLD_GL_INTF_AP_FILE'||sqlerrm );
  p_retcode      := 2;
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
	p_error_msg	   VARCHAR2,   -- Added for NAIT-161587
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
      request_id,                
	  error_description    -- Added for NAIT-161587
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
      DECODE(p_error_msg,NULL,'N','E'),     -- Added for NAIT-161587
      p_request_id,
	  p_error_msg         -- Added for NAIT-161587
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
	 lv_datafile_rec_number number:=0;
BEGIN
  gn_file_batch_id:=NULL;  -- Added for NAIT-161587 -- to check 
  lt_parameters('p_process_name') := p_process_name;
  lt_parameters('p_file_name')   := p_file_name;
  lt_parameters('p_debug_flag')   := p_debug_flag;
  lt_parameters('p_file_name')   := p_request_id;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);

   select count(1) into lv_filerec_count from XX_GL_JRNLS_CLD_INTF_FILES
   where FILE_NAME=p_file_name
   and   process_name=p_process_name;
   
   gn_file_batch_id:=XX_GL_JRNLS_CLD_INTF_FILES_S.nextval;      
   
   IF lv_filerec_count =0 THEN
            insert_file_rec( p_process_name => p_process_name, 
						     p_file_name => p_file_name,
							 p_request_id=>p_request_id,
							 p_error_msg =>NULL,
							 p_user_id=>p_user_id) ;            
			print_debug_msg(p_message =>'File Record Created Successfully.', p_force => true);
    ELSE
	/*Start: -- Added for NAIT-161587 */
            insert_file_rec( p_process_name => p_process_name, 
						     p_file_name => p_file_name,
							 p_request_id=>p_request_id,
							 p_error_msg =>'Duplicate File',
							 p_user_id=>p_user_id) ;            
   /*End: -- Added for NAIT-161587 */
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
	  lv_datafile_rec_number:=lv_datafile_rec_number+1;
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
				FROM xx_fin_translatedefinition xftd,
					 xx_fin_translatevalues xftv
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
  p_retcode := 2;
  print_debug_msg(p_message =>'Program Name-XXGLJRNLSCLDINTFLOAD.Error location-XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging.Error Message-'||sqlerrm , p_force => true);
WHEN parse_exception THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging-When invalid_operation Exception at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||l_error_msg||'~'||sqlerrm;
  update XX_GL_JRNLS_CLD_INTF_FILES 
     set error_description=l_error_msg,
		 record_status='E'  -- Added for NAIT-161587
   where file_name=p_file_name;
  commit;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  p_errbuf := null;
  p_retcode:= 2;
WHEN utl_file.invalid_operation THEN
   ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging-When invalid_operation Exception at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  update XX_GL_JRNLS_CLD_INTF_FILES 
     set error_description=l_error_msg,
	 record_status='E'  -- Added for NAIT-161587											
   where file_name=p_file_name;
  commit;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  p_errbuf := null;
  p_retcode:= 2;
WHEN utl_file.invalid_filehandle THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging-When invalid_filehandle Exception at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  update XX_GL_JRNLS_CLD_INTF_FILES 
     set error_description=l_error_msg, 
	 record_status='E'  -- Added for NAIT-161587										
   where file_name=p_file_name;
  commit;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  p_errbuf := null;
  p_retcode:= 2;
WHEN utl_file.read_error THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging-When read_error Exception at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  update XX_GL_JRNLS_CLD_INTF_FILES 
     set error_description=l_error_msg,	
	 record_status='E'   -- Added for NAIT-161587										
   where file_name=p_file_name;
  commit;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  p_errbuf := null;
  p_retcode:= 2;
WHEN utl_file.invalid_path THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging-When invalid_path Exception at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  update XX_GL_JRNLS_CLD_INTF_FILES 
     set error_description=l_error_msg, 
	 record_status='E'  -- Added for NAIT-161587										
   where file_name=p_file_name;
  commit;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  p_errbuf := null;
  p_retcode:= 2;
WHEN utl_file.invalid_mode THEN
   ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging-When invalid_mode Exception at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  update XX_GL_JRNLS_CLD_INTF_FILES 
     set error_description=l_error_msg, 
	 record_status='E'  -- Added for NAIT-161587										  
   where file_name=p_file_name;
  commit;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  p_errbuf := null;
  p_retcode:= 2;
WHEN utl_file.internal_error THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging-When internal_error at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  update XX_GL_JRNLS_CLD_INTF_FILES 
     set error_description=l_error_msg, 
	 record_status='E'  -- Added for NAIT-161587										
   where file_name=p_file_name;
  commit;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  p_errbuf := null;
  p_retcode:= 2;
WHEN value_error THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging-When Value_Error at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  update XX_GL_JRNLS_CLD_INTF_FILES 
     set error_description=l_error_msg,	
	 record_status='E'  	-- Added for NAIT-161587									  
   where file_name=p_file_name;
  commit;	
  p_retcode:= 2;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
 
 WHEN OTHERS THEN
  ROLLBACK;
  utl_file.fclose(l_filehandle);
  l_error_msg:='XX_GL_JRNLS_CLD_INTF_PKG.load_utl_file_staging-When Others Exception at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
  update XX_GL_JRNLS_CLD_INTF_FILES
     set error_description=l_error_msg, 
	 record_status='E'   -- Added for NAIT-161587										
   where file_name=p_file_name;
  commit;
  print_debug_msg(p_message =>l_error_msg  , p_force => true);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
    p_errbuf := null;
  p_retcode:= 2;
END load_utl_file_staging;


--/*********************************************************************
--* Procedure used to Load Data File into Staging Table.
--* This Package procedure is called from Host Program
--* This procedure is called each time for all the files that needs to be processed.
--*********************************************************************/
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
  
EXCEPTION
WHEN OTHERS THEN
  logit(p_message => 'Error Occured:'||lc_action||'~SQLCODE:'|| SQLCODE || '~SQLERRM: ' || SQLERRM, p_force => TRUE);
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
END MAIN_LOAD_PROCESS;


--/**********************************************************************************
--* Procedure to process  Process Journal Batch to Submit OD: GL Interface for Cloud GL Transactions and Journal Import 
--* This procedure is called by MAIN_PROCESS.
--***********************************************************************************/
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


  cursor cur_file_stg_batch is 
  select distinct ebs_journal_source from 
  	XX_GL_JRNLS_CLD_INTF_STG stg
	where 1=1	
	 and stg.process_name=p_process_name
  and stg.RECORD_STATUS in ('I')
  and stg.action in ('INSERT');
  l_err_buff      VARCHAR2 (4000);
  lv_status varchar2(1):='N';
  lv_file_status varchar2(1):='N';

BEGIN
  lt_parameters('p_process_name') := p_process_name;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  lc_action := 'Submitting GL Data File Load Program';
  
   for stg_rec in cur_file_stg_batch loop
   logit(p_message =>'Processing Ebs Journal_Source-'||stg_rec.EBS_JOURNAL_SOURCE);
   lv_status:='N';
  BEGIN
    lc_conc_req_id := fnd_request.submit_request ( application => 'XXFIN' , program => 'XXGLJRNLSCLDGLTRANS' , description => NULL , start_time => sysdate , sub_request => false , argument1=>stg_rec.EBS_JOURNAL_SOURCE,argument2=>p_debug_flag);
    COMMIT;
    IF lc_conc_req_id = 0 THEN
	lv_status:='Y';
	lv_file_status:='Y';
      logit(p_message =>'Conc. Program  failed to submit OD: GL Interface for Cloud GL Transactions Program');
	  	Update XX_GL_JRNLS_CLD_INTF_FILES xx
				set xx.record_status='P',
				ERROR_DESCRIPTION=ERROR_DESCRIPTION||'~'||'Failed to submit OD: GL Interface for Cloud GL Transactions Program'				
				where xx.file_batch_id in 
				(Select distinct file_batch_id from XX_GL_JRNLS_CLD_INTF_STG stg where EBS_JOURNAL_SOURCE=stg_rec.EBS_JOURNAL_SOURCE 
				and stg.RECORD_STATUS in ('I')
				and stg.action in ('INSERT'));
				
	  Update XX_GL_JRNLS_CLD_INTF_STG stg set record_status='P',
				action='PROCESSED',
				ERROR_DESCRIPTION=ERROR_DESCRIPTION||'~'||'Failed to submit OD: GL Interface for Cloud GL Transactions Program'
				where 1=1
				and EBS_JOURNAL_SOURCE=stg_rec.EBS_JOURNAL_SOURCE
				and stg.RECORD_STATUS in ('I')
				and stg.action in ('INSERT');
    ELSE
	lv_status:='N';
	logit(p_message =>'Conc. Program Submitted Successfully OD: GL Interface for Cloud GL Transactions Program.Request Id-'||lc_conc_req_id);
	Update XX_GL_JRNLS_CLD_INTF_FILES xx
				set xx.record_status='P'				
				where xx.file_batch_id in 
				(Select distinct file_batch_id from XX_GL_JRNLS_CLD_INTF_STG stg where EBS_JOURNAL_SOURCE=stg_rec.EBS_JOURNAL_SOURCE 
				and stg.RECORD_STATUS in ('I')
				and stg.action in ('INSERT'));
				
	Update XX_GL_JRNLS_CLD_INTF_STG stg set record_status='P',
				action='PROCESSED',
				attribute10=lc_conc_req_id--assigning Request Id of XXGLJRNLSCLDGLTRANS to STG records for reference
				where 	1=1
				and EBS_JOURNAL_SOURCE=stg_rec.EBS_JOURNAL_SOURCE
				and stg.RECORD_STATUS in ('I')
				and stg.action in ('INSERT');
				

		--Commented code to trigger and forget.		
    /*  lc_action              := 'Waiting for concurrent request OD: GL Interface for Cloud GL Transactions Program to complete';
      lc_wait_flag           := fnd_concurrent.wait_for_request(request_id => lc_conc_req_id, phase => lc_phase, status => lc_status, dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message);
      IF UPPER(lc_dev_status) = 'NORMAL' AND UPPER(lc_dev_phase) = 'COMPLETE' THEN
        logit(p_message =>'OD: GL Interface for Cloud GL Transactions Program successful for the Request Id: ' || lc_conc_req_id );

      ELSE
        logit(p_message =>'OD: GL Interface for Cloud GL Transactions Program did not complete normally. ');
		
      END IF; */
	  
	   
    END IF;
	
	
  END;
  commit;

  end loop;

EXCEPTION
WHEN OTHERS THEN
  l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
  print_debug_msg(p_message => 'ERROR: Exception in PROCESS_JOURNAL_BATCH() API - '|| l_err_buff , p_force => true);
  logit('Error in PROCESS_JOURNAL_BATCH'||sqlerrm );
  p_retcode      := 2;
  p_errbuf       := l_err_buff;
END PROCESS_JOURNAL_BATCH;

--/**********************************************************************************
--* Procedure to process  MPL at different levels.
--* This procedure is called by MAIN_PROCESS.
--***********************************************************************************/
PROCEDURE PROCESS_LOAD_GL_FILE(
    p_process_name IN VARCHAR2,
    p_debug_flag   IN VARCHAR2,
	p_errbuf  OUT nocopy  VARCHAR2 ,
    p_retcode OUT nocopy NUMBER )
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
  p_retcode:=0;
  BEGIN
    lc_conc_req_id := fnd_request.submit_request ( application => 'XXFIN' , program => 'XXGLJRNLSCLDINTFLOAD' , description => NULL , start_time => sysdate , sub_request => false , argument1=>p_process_name,argument2=>p_debug_flag);
    COMMIT;
    IF lc_conc_req_id = 0 THEN
      logit(p_message =>'Conc. Program  failed to submit OD Cloud to EBS GL Journals Load Program');
	  p_errbuf:='Conc. Program  failed to submit OD Cloud to EBS GL Journals Load Program';
	  p_retcode:=1;
    ELSE
	  gn_load_request_id:=lc_conc_req_id;   -- Added for NAIT-161587
      lc_action              := 'Waiting for concurrent request OD Cloud to EBS GL Journals Load Program to complete';
      lc_wait_flag           := fnd_concurrent.wait_for_request(request_id => lc_conc_req_id, phase => lc_phase, status => lc_status, dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message);
      IF UPPER(lc_dev_status) = 'NORMAL' AND UPPER(lc_dev_phase) = 'COMPLETE' THEN
        logit(p_message =>'OD Cloud to EBS GL Journals Load Program successful for the Request Id: ' || lc_conc_req_id );
      ELSE
        logit(p_message =>'OD Cloud to EBS GL Journals Load Program did not complete normally.');
		p_errbuf:='Child Program OD Cloud to EBS GL Journals Load Program did not complete normally. Please check Loader Program logs';
	    p_retcode:=1;
      END IF;
    END IF;
  END;

EXCEPTION
WHEN OTHERS THEN
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  p_errbuf:='PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM;
  p_retcode:=2;
  RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END PROCESS_LOAD_GL_FILE;


--/**********************************************************************
--* Main Procedure to Load Cloud GL Transactions and Import
--* this procedure calls individual procedures to Load and process them.
--***********************************************************************/
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
  
  lc_email_status varchar2(10);   -- Added for NAIT-161587
  lc_email_err varchar2(300);  -- Added for NAIT-161587
  ln_cnt NUMBER:=0;

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
  print_debug_msg(p_message => 'Calling PROCESS_LOAD_GL_FILE Procedure' , p_force => true);
  PROCESS_LOAD_GL_FILE (p_process_name,p_debug_flag,p_errbuf=>x_err_buf,p_retcode=>x_ret_code) ;
  if x_err_buf is not null or x_ret_code <>0 then
  print_debug_msg(P_MESSAGE => 'VAL_CLD_GL_INTF_FILE, p_errbuf-' ||x_err_buf ||' ,p_retcode-'||x_ret_code, p_force => TRUE);
  retcode:=1;
  end if;
  print_debug_msg(P_MESSAGE => 'Exiting PROCESS_LOAD_GL_FILE Procedure', p_force => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling VAL_CLD_GL_INTF_FILE Procedure' , p_force => true);
  VAL_CLD_GL_INTF_FILE( p_process_name => p_process_name,p_debug_flag => p_debug_flag,p_errbuf=>x_err_buf,p_retcode=>x_ret_code) ;
  if x_err_buf is not null then
  print_debug_msg(P_MESSAGE => 'VAL_CLD_GL_INTF_FILE, p_errbuf-' ||x_err_buf ||' ,p_retcode-'||x_ret_code, p_force => TRUE);
  end if;
  
  if x_ret_code <>0 then 
   print_debug_msg(P_MESSAGE => 'VAL_CLD_GL_INTF_FILE, Validations Errors Ledger Name/Application Name/Journal Source/Journal Category are not valid. Errors that cannot insert into XX_GL_INTERFACE_NA_STGG Table.', p_force => TRUE);
   retcode:=1;  
  end if;
  print_debug_msg(P_MESSAGE => 'Exiting VAL_CLD_GL_INTF_FILE Procedure' , p_force => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);

  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling CREATE_JOURNAL_BATCH Procedure' , p_force => true);
  CREATE_JOURNAL_BATCH( p_process_name => p_process_name,p_debug_flag => p_debug_flag,p_errbuf=>x_err_buf,p_retcode=>x_ret_code) ;
  if x_err_buf is not null or x_ret_code <>0  then
  print_debug_msg(P_MESSAGE => 'CREATE_JOURNAL_BATCH, p_errbuf-' ||x_err_buf ||' ,p_retcode-'||x_ret_code, p_force => TRUE);
  retcode:=1;
  end if;
  print_debug_msg(P_MESSAGE => 'Exiting CREATE_JOURNAL_BATCH Procedure' , p_force => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);  

  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling PROCESS_JOURNAL_BATCH Procedure' , p_force => true);
  PROCESS_JOURNAL_BATCH( p_process_name => p_process_name,p_debug_flag => p_debug_flag,p_errbuf=>x_err_buf,p_retcode=>x_ret_code) ;
  if x_err_buf is not null or x_ret_code <>0 then
  print_debug_msg(P_MESSAGE => 'PROCESS_JOURNAL_BATCH, p_errbuf-' ||x_err_buf ||' ,p_retcode-'||x_ret_code, p_force => TRUE);
  retcode:=1;
  end if;
  print_debug_msg(P_MESSAGE => 'Exiting PROCESS_JOURNAL_BATCH Procedure' , p_force => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);  

/* Start: Added for NAIT-161587 */ 

  xx_send_notification(
                     p_request_id => gn_load_request_id,
                     x_status => lc_email_status,
                     x_error => lc_email_err);
 
  xx_purge_staging;
 
   SELECT COUNT(1)
    INTO ln_cnt
  	FROM xx_gl_jrnls_cld_intf_files
   WHERE request_id=gn_load_request_id
     AND record_status ='E';   

   IF ln_cnt<>0 THEN
      retcode := 2;
	  errbuff :='Error while processing file, please check the logs and email notification';
   END IF;
 
/* End: Added for NAIT-161587 */ 
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